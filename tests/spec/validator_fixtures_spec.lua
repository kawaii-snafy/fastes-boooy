-- Validator fixtures: every deliberate error in tests/fixtures/validator/* must be
-- reported with the expected code and severity, and the clean fixture must pass.
-- Fixtures use real Forever data from tools/data/forever_db.lua (Deathknell, Tirisfal).

local DB = require("lib.fbdb")
local Loader = require("lib.route_loader")
local V = require("lib.validator")

local FIXTURES = "tests/fixtures/validator/"

local db, schema

local function validate(name, extra)
    local opts = { db = db, schema = schema }
    for k, v in pairs(extra or {}) do opts[k] = v end
    local res = V.ValidateModule(FIXTURES .. name, opts)
    assert(#res.results >= 1, "no results for " .. name)
    return res.results[1], res
end

-- set of codes with the given severity
local function codes(result, severity)
    local set = {}
    for _, m in ipairs(result.messages) do
        if m.severity == severity then set[m.code] = (set[m.code] or 0) + 1 end
    end
    return set
end

local function messagesWith(result, code)
    local out = {}
    for _, m in ipairs(result.messages) do
        if m.code == code then out[#out + 1] = m end
    end
    return out
end

local function keys(set)
    local out = {}
    for k in pairs(set) do out[#out + 1] = k end
    table.sort(out)
    return out
end

describe("validator fixtures", function()
    setup(function()
        db = DB.Load("tools/data/forever_db.lua")
        schema = Loader.LoadSchema(".")
    end)

    it("clean fixture: zero errors and zero warnings", function()
        local r, res = validate("AdventureAtlas_FxClean")
        assert.are.same({}, res.loadErrors)
        assert.are.equal(0, r.counts.ERROR)
        assert.are.equal(0, r.counts.WARN)
        assert.are.equal("fx-clean", r.route)
        assert.are.same({ race = "Scourge", class = "PALADIN", faction = "Horde" }, r.profile)
        -- no dead (filtered-out) step in a clean route
        assert.is_nil(codes(r, "INFO")["step-skipped"])
        -- XP simulation: all quests turned in, level 5+ at the end
        assert.are.equal(7, r.summary.accepts)
        assert.are.equal(7, r.summary.turnins)
        assert.are.same({}, r.summary.carried)
        assert.is_true(r.summary.endLevel >= 5 and r.summary.endLevel < 6)
        assert.are.equal(0, r.summary.unknownXpQuests)
        assert.are.equal(2, #r.segments)
        assert.is_true(r.segments[1].endLevel > 3 and r.segments[1].endLevel < 4.5)
    end)

    it("wrong quest id -> quest-unknown (accept, complete, turnin)", function()
        local r = validate("AdventureAtlas_FxWrongQuest")
        assert.are.same({ "quest-unknown" }, keys(codes(r, "ERROR")))
        assert.are.equal(3, codes(r, "ERROR")["quest-unknown"])
        assert.matches("999999", messagesWith(r, "quest-unknown")[1].msg)
    end)

    it("wrong race / side / class quests", function()
        local r = validate("AdventureAtlas_FxWrongRace")
        assert.are.same({ "quest-class", "quest-race", "quest-side" }, keys(codes(r, "ERROR")))
        local race = messagesWith(r, "quest-race")[1]
        assert.matches("92598", race.msg)
        assert.matches("SKYBORNE_HORDE", race.msg)
        assert.are.equal("fx-wrong-race-01", race.segment)
        assert.are.equal(5, race.step)
        assert.are.equal("Segments/01.lua", race.file)
        assert.matches("Alliance%-only", messagesWith(r, "quest-side")[1].msg)
        assert.matches("WARRIOR", messagesWith(r, "quest-class")[1].msg)
    end)

    it("Skyborne Horde druid profile may take the Skyborne quest but not the Undead-only one", function()
        local r = validate("AdventureAtlas_FxWrongRace", { profile = { race = "Skyborne", class = "DRUID" } })
        assert.are.equal("Horde", r.profile.faction)
        local race = messagesWith(r, "quest-race")
        assert.are.equal(2, #race)
        assert.matches("363", race[1].msg)  -- 363 Rude Awakening is UNDEAD only
        assert.matches("3095", race[2].msg) -- 3095 Simple Scroll is the Undead warrior scroll
        for _, m in ipairs(race) do assert.not_matches("92598", m.msg) end
    end)

    it("missing prerequisite -> accept-prereq", function()
        local r = validate("AdventureAtlas_FxMissingPrereq")
        assert.are.same({ "accept-prereq" }, keys(codes(r, "ERROR")))
        local m = messagesWith(r, "accept-prereq")
        assert.are.equal(2, #m)
        assert.matches("3901", m[1].msg)
        assert.matches("364", m[1].msg)
        assert.matches("381", m[2].msg)
    end)

    it("NPC far from at / no spawn on the map / unknown map / unknown NPC", function()
        local r = validate("AdventureAtlas_FxNpcFar")
        assert.are.same({ "at-far", "at-map-unknown", "at-no-spawn", "npc-unknown" }, keys(codes(r, "ERROR")))
        assert.are.equal(1, codes(r, "WARN")["at-far"]) -- ~67 yards: warning only
        local far = messagesWith(r, "at-far")
        assert.are.equal("WARN", far[1].severity)
        assert.matches("1568", far[1].msg)
        assert.matches("67 yards", far[1].msg)
        assert.are.equal("ERROR", far[2].severity)
        assert.matches("1569", far[2].msg)
        assert.matches("450 yards", far[2].msg)
        -- Zephras Isle has no known world size: map-unit fallback, marked approximate
        assert.are.equal("ERROR", far[3].severity)
        assert.matches("251362", far[3].msg)
        assert.matches("map units %(approximate", far[3].msg)
    end)

    it("tolerance options move the thresholds", function()
        local r = validate("AdventureAtlas_FxNpcFar", { toleranceYards = 100, hardToleranceYards = 500,
            tolerance = 5, hardTolerance = 12 })
        assert.is_nil(codes(r, "ERROR")["at-far"])
        assert.are.equal(2, codes(r, "WARN")["at-far"]) -- 450 yd and 9.7 map units
    end)

    it("distances are measured in yards: the same map-unit offset means different distances per map", function()
        -- Sergra Darkthorn 3338 stands at 52.23, 31.01 on The Barrens (10133 x 6756 yd)
        local route = assert(schema.NormalizeRoute({ api = 1, id = "mem-yd", title = "yd", faction = "Horde",
            races = { "Tauren" }, classes = { "DRUID" }, levels = { 10, 11 } }))
        schema.AddSegment(route, { id = "b", title = "b", steps = {
            { level = 10 },
            { id = "far800", accept = 844, npc = 3338, at = { 1413, 60.1, 31.0 } }, -- ~797 yd
            { id = "far290", accept = 845, npc = 3338, at = { 1413, 55.1, 31.0 } }, -- ~291 yd
            { id = "near", turnin = 844, npc = 3338, at = { 1413, 52.5, 31.0 } },   -- ~27 yd
        } })
        local r = V.NewRun(db, schema, route, V.Profiles(route)[1], {}):execute()
        local far = messagesWith(r, "at-far")
        assert.are.equal(2, #far)
        assert.are.equal("ERROR", far[1].severity)
        assert.matches("797 yards", far[1].msg)
        assert.are.equal("ERROR", far[2].severity)
        assert.matches("291 yards", far[2].msg)
    end)

    it("thinned spawn lists keep every cluster (no false at-far)", function()
        -- 59.43, 61.95 is a real Flatland Prowler (3566) spawn on Mulgore
        local n = db.npcs[3566]
        assert.is_number(n.spawnsGrid)
        local route = assert(schema.NormalizeRoute({ api = 1, id = "mem-thin", title = "t", faction = "Horde",
            races = { "Tauren" }, classes = { "DRUID" }, levels = { 10, 11 } }))
        schema.AddSegment(route, { id = "m", title = "m", steps = {
            { level = 10 },
            { accept = 861, npc = 3052 },
            { complete = 861, npc = 3566, at = { 1412, 59.43, 61.95 } },
        } })
        local r = V.NewRun(db, schema, route, V.Profiles(route)[1], {}):execute()
        assert.are.same({}, messagesWith(r, "at-far"))
    end)

    it("wrong quest giver / turn-in NPC", function()
        local r = validate("AdventureAtlas_FxWrongNpc")
        assert.are.same({ "accept-wrong-npc", "turnin-wrong-npc" }, keys(codes(r, "ERROR")))
        assert.matches("Shadow Priest Sarvis", messagesWith(r, "turnin-wrong-npc")[1].msg)
    end)

    it("quest log overflow -> questlog-full at the 41st quest", function()
        local r = validate("AdventureAtlas_FxQuestLog")
        assert.are.same({ "questlog-full" }, keys(codes(r, "ERROR")))
        local m = messagesWith(r, "questlog-full")
        assert.are.equal(2, #m)
        assert.matches("41 quests", m[1].msg)
        assert.are.equal(40, db.questLogSize)
        assert.are.equal(42, r.summary.maxQuestLog)
        -- the grind to 13 needs far more than 30 kills
        assert.are.equal(1, codes(r, "WARN")["level-grind"])
        assert.are.equal(42, codes(r, "WARN")["quest-carried"])
    end)

    it("level too low -> level-too-low, segment end level off -> segment-level", function()
        local r = validate("AdventureAtlas_FxLevelLow")
        assert.are.same({ "level-too-low" }, keys(codes(r, "ERROR")))
        assert.matches("requires level 7", messagesWith(r, "level-too-low")[1].msg)
        assert.are.equal(1, codes(r, "WARN")["segment-level"])
    end)

    it("train at the wrong trainer, hostile trainer, wrong service NPCs", function()
        local r = validate("AdventureAtlas_FxWrongTrainer")
        assert.are.same({ "not-flightmaster", "not-innkeeper", "npc-hostile", "train-wrong-trainer" },
            keys(codes(r, "ERROR")))
        assert.are.equal(2, codes(r, "ERROR")["train-wrong-trainer"])
        assert.are.equal(1, codes(r, "WARN")["train-not-class-trainer"])
        assert.are.equal(1, codes(r, "WARN")["not-vendor"])
        -- the real Undead paladin trainer (step 1) is accepted
        for _, m in ipairs(r.messages) do assert.are_not.equal(1, m.step) end
    end)

    it("quest log bookkeeping: exclusive, duplicate, never accepted, twice, not active, carried", function()
        local r = validate("AdventureAtlas_FxChain")
        assert.are.same({ "abandon-not-active", "accept-duplicate", "accept-exclusive", "complete-not-active",
            "turnin-not-accepted", "turnin-twice" }, keys(codes(r, "ERROR")))
        assert.are.same({ "breadcrumb-late", "quest-carried", "turnin-no-complete" }, keys(codes(r, "WARN")))
        assert.matches("8792", messagesWith(r, "quest-carried")[1].msg)
    end)

    it("schema errors are reported with their file", function()
        local r, res = validate("AdventureAtlas_FxSchema")
        assert.is_true(#res.loadErrors >= 7)
        local schemaMsgs = messagesWith(r, "schema")
        assert.are.equal(#res.loadErrors, #schemaMsgs)
        local all = {}
        for _, m in ipairs(schemaMsgs) do
            assert.are.equal("ERROR", m.severity)
            assert.are.equal("Segments/01.lua", m.file)
            all[#all + 1] = m.msg
        end
        local text = table.concat(all, "\n")
        assert.matches("unknown step key 'colour'", text)
        assert.matches("accept must be a quest id", text)
        assert.matches("step has no action", text)
        assert.matches("x/y must be numbers", text)
        assert.matches("not registered yet", text)
        assert.matches("defines global 'FxSchemaLeakedGlobal'", text)
    end)

    it("level checks that depend on estimated (unknown) quest XP are downgraded to WARN", function()
        -- Zephras Isle (Forever-new, quest XP unknown offline): 92460 (level 1) -> 92464/92465 (require 2)
        local route = assert(schema.NormalizeRoute({
            api = 1, id = "mem-sky", title = "mem", faction = "Horde", races = { "Skyborne" },
            classes = { "DRUID" }, levels = { 1, 3 },
        }))
        local _, errs = schema.AddSegment(route, { id = "z", title = "z", steps = {
            { accept = 92460, npc = 251362, at = { 2521, 42.8, 23.4 } },
            { turnin = 92460, npc = 251361, at = { 2521, 42.0, 23.5 } },
            { accept = 92464, npc = 251361, at = { 2521, 42.0, 23.5 } },
            { complete = 92464 },
            { turnin = 92464, accept = 92465, npc = 249363, at = { 2521, 47.2, 22.0 } },
            { abandon = 92465 },
        } })
        assert.are.same({}, errs)
        local profile = V.Profiles(route)[1]
        local r = V.NewRun(db, schema, route, profile, {}):execute()
        assert.are.equal(1, codes(r, "ERROR")["level-too-low"])        -- 2x the estimate is still not enough
        assert.matches("estimated quest XP", messagesWith(r, "level-too-low")[1].msg)
        assert.are.equal(1, codes(r, "WARN")["level-too-low-estimated"]) -- reachable optimistically
        assert.are.equal(2, codes(r, "INFO")["xp-unknown"]) -- an estimate is no warning
        assert.is_nil(codes(r, "WARN")["xp-unknown"])
        assert.is_true(r.summary.endLevelOptimistic > r.summary.endLevel)
        -- a generous optimism factor turns both into warnings
        local r2 = V.NewRun(db, schema, route, profile, { unknownXpOptimism = 12 }):execute()
        assert.is_nil(codes(r2, "ERROR")["level-too-low"])
        assert.are.equal(2, codes(r2, "WARN")["level-too-low-estimated"])
    end)

    it("step filters: unknown race token (ERROR) and a step no profile can see (WARN)", function()
        local r = validate("AdventureAtlas_FxFilters")
        assert.are.same({ "unknown-race-token" }, keys(codes(r, "ERROR")))
        local m = messagesWith(r, "unknown-race-token")[1]
        assert.matches("'Undead'", m.msg)
        assert.matches("Scourge", m.msg)
        assert.are.equal(2, m.step)
        assert.are.equal(1, codes(r, "WARN")["step-no-profile"])
        assert.are.equal(3, messagesWith(r, "step-no-profile")[1].step)
    end)

    local function memRun(routeDef, steps, opts)
        local route = assert(schema.NormalizeRoute(routeDef))
        local _, errs = schema.AddSegment(route, { id = "s", title = "s", steps = steps })
        assert.are.same({}, errs)
        local out = {}
        for _, p in ipairs(V.Profiles(route)) do
            out[#out + 1] = V.NewRun(db, schema, route, p, opts or {}):execute()
        end
        return out[1], out
    end
    local UNDEAD_PALADIN = { api = 1, id = "mem", title = "mem", faction = "Horde", races = { "Scourge" },
        classes = { "PALADIN" }, levels = { 1, 5 } }
    local TAUREN_DRUID = { api = 1, id = "mem-t", title = "mem", faction = "Horde", races = { "Tauren" },
        classes = { "DRUID" }, levels = { 10, 12 } }

    it("several actions on one quest in one step are processed in the player's order", function()
        -- Coming of Age: giver and ender stand side by side -> accept and turn in at one stop
        local r = memRun({ api = 1, id = "mem-sky", title = "s", faction = "Horde", races = { "Skyborne" },
            classes = { "DRUID" }, levels = { 1, 2 } }, {
            { accept = 92460, turnin = 92460, npc = { 251362, 251361 }, at = { 2521, 42.5, 23.45 } },
        }, { ignore = { ["xp-unknown"] = true } })
        assert.is_nil(codes(r, "ERROR")["turnin-not-accepted"])
        assert.is_nil(codes(r, "ERROR")["accept-done"])
        assert.are.equal(0, r.counts.ERROR)
        -- accept + complete + turn-in, and complete + turn-in, in one step each
        local r2 = memRun(UNDEAD_PALADIN, {
            { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
            { turnin = 363, accept = 364, complete = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
            { complete = 364, turnin = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        })
        assert.are.equal(0, r2.counts.ERROR)
        assert.is_nil(codes(r2, "WARN")["turnin-no-complete"])
        assert.are.equal(2, r2.summary.turnins)
    end)

    it("exclusive groups are checked in both directions", function()
        -- 861 lists 844 as exclusive, 844 does not list 861
        local fwd = memRun(TAUREN_DRUID, { { level = 10 }, { accept = 861 }, { accept = 844 } })
        assert.are.equal(1, codes(fwd, "ERROR")["accept-exclusive"])
        local rev = memRun(TAUREN_DRUID, { { level = 10 }, { accept = 844 }, { accept = 861 } })
        assert.are.equal(1, codes(rev, "ERROR")["accept-exclusive"])
    end)

    it("availableUntilCompleted and disabledByQuest", function()
        local r = memRun({ api = 1, id = "mem-av", title = "a", faction = "Horde", races = { "Skyborne" },
            classes = { "DRUID" }, levels = { 1, 20 } }, {
            { level = 3 },
            { accept = 92465 }, { complete = 92465 }, { turnin = 92465 },
            { accept = 92464 },                 -- untilCompleted = 92465 (turned in)
            { abandon = 92464 },
            { level = 19 },
            { accept = 6542 },
            { accept = 6541 },                  -- disabledBy = 6542 (in the log)
            { abandon = 6541 }, { abandon = 6542 },
        }, { ignore = { ["xp-unknown"] = true } })
        assert.are.equal(92465, db.quests[92464].untilCompleted)
        assert.are.equal(1, codes(r, "ERROR")["accept-unavailable"])
        assert.matches("92464", messagesWith(r, "accept-unavailable")[1].msg)
        assert.are.equal(1, codes(r, "ERROR")["accept-disabled"])
        assert.matches("6541", messagesWith(r, "accept-disabled")[1].msg)
    end)

    it("a turn-in after completing only some objectives warns about the rest", function()
        local r = memRun(UNDEAD_PALADIN, {
            { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
            { turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
            { complete = { [364] = { 1 } } },
            { turnin = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        })
        assert.are.equal(1, codes(r, "WARN")["turnin-partial"])
        assert.matches("objective%(s%) 2", messagesWith(r, "turnin-partial")[1].msg)
        local ok = memRun(UNDEAD_PALADIN, {
            { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
            { turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
            { complete = { [364] = { 1 } } },
            { complete = { [364] = { 2 } } },
            { turnin = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        })
        assert.is_nil(codes(ok, "WARN")["turnin-partial"])
    end)

    -- kills simulated by 'complete' steps (sum of the complete-kill-xp INFO messages)
    local function kills(r)
        local n = 0
        for _, m in ipairs(messagesWith(r, "complete-kill-xp")) do n = n + tonumber(m.msg:match("~(%d+) kills")) end
        return n
    end
    local SKY_DRUID = { api = 1, id = "mem-sky", title = "s", faction = "Horde", races = { "Skyborne" },
        classes = { "DRUID" }, levels = { 1, 9 } }
    local NO_XP_WARN = { ignore = { ["xp-unknown"] = true } }

    describe("kill XP of 'complete' objectives", function()
        it("talk objectives (friendly NPCs, innkeeper, trainer) give no kill XP", function()
            -- repro sd01: 92514 "speak with Illaya and Coriella" was simulated as 2 x 8 kills
            local r = memRun(SKY_DRUID, {
                { level = 4 },
                { accept = 92514, npc = 251523, at = { 2521, 45.67, 45.50 } },
                { complete = 92514, npc = 251902, at = { 2521, 43.51, 44.77 } },
                { turnin = 92514, npc = 251523, at = { 2521, 45.67, 45.50 } },
            }, NO_XP_WARN)
            assert.are.equal(0, r.summary.xpKill)
            assert.are.equal(0, kills(r))
            local m = messagesWith(r, "complete-no-kill")
            assert.are.equal(1, #m)
            assert.matches("251902 \"Illaya Amberwind\": talk objective", m[1].msg)
            assert.matches("254089 \"Coriella Calmbreeze\": talk objective", m[1].msg)
            -- repro sd02: 93159 "speak with the Strange Hermit" (friendly trainer) was 8 kills
            local r2 = memRun(SKY_DRUID, {
                { level = 8 },
                { accept = 93159, complete = 93159, turnin = 93159, npc = 251684, at = { 2521, 53.96, 38.90 } },
            }, NO_XP_WARN)
            assert.are.equal(0, r2.summary.xpKill)
            assert.are.equal(1, #messagesWith(r2, "complete-no-kill"))
        end)

        it("heal / free / punish objectives and killCredit events are not kills", function()
            local r = memRun(UNDEAD_PALADIN, {
                { accept = 90902 }, { complete = 90902 },  -- heal 5 Injured Deathguard (interact icon)
                { accept = 98389 }, { complete = 98389 },  -- free 6 Webbed Victims (killCredit, event icon)
                { abandon = 90902 }, { abandon = 98389 },
            }, { ignore = { ["level-too-low"] = true, ["level-too-low-estimated"] = true } })
            assert.are.equal(0, r.summary.xpKill)
            local m = messagesWith(r, "complete-no-kill")
            assert.are.equal(2, #m)
            assert.matches("interact objective", m[1].msg)
            assert.matches("event objective", m[2].msg)
        end)

        it("NPC faction / flags decide when the objective icon does not: friendly, service, quest giver", function()
            -- 91208 "Find the Frightened Paladin": slay icon, but the NPC is friendly to the Horde
            local r = memRun(UNDEAD_PALADIN, { { level = 3 }, { accept = 91208 }, { complete = 91208 },
                { abandon = 91208 } }, NO_XP_WARN)
            assert.are.equal(0, r.summary.xpKill)
            assert.matches("friendly NPC %(faction 'H'%)", messagesWith(r, "complete-no-kill")[1].msg)
            -- the same talk quests with the icons stripped: flags / quest-giver index still decide
            local q92514, q93159 = db.quests[92514], db.quests[93159]
            local function stripped(q)
                local c = {}
                for k, v in pairs(q) do c[k] = v end
                c.objectives = { creatures = {} }
                for i, e in ipairs(q.objectives.creatures) do c.objectives.creatures[i] = { e[1], e[2] } end
                return c
            end
            local fake = setmetatable({ quests = setmetatable({ [92514] = stripped(q92514), [93159] = stripped(q93159) },
                { __index = db.quests }) }, { __index = db })
            local route = assert(schema.NormalizeRoute(SKY_DRUID))
            schema.AddSegment(route, { id = "s", title = "s", steps = {
                { level = 8 },
                { accept = 92514 }, { complete = 92514 }, { turnin = 92514 },
                { accept = 93159 }, { complete = 93159 }, { turnin = 93159 },
            } })
            local rf = V.NewRun(fake, schema, route, V.Profiles(route)[1], NO_XP_WARN):execute()
            assert.are.equal(0, rf.summary.xpKill)
            local text = {}
            for _, m in ipairs(messagesWith(rf, "complete-no-kill")) do text[#text + 1] = m.msg end
            text = table.concat(text, "\n")
            assert.matches("251902 \"Illaya Amberwind\": quest giver", text)  -- gives 92595
            assert.matches("254089 \"Coriella Calmbreeze\": service NPC %(innkeeper, vendor%)", text)
            assert.matches("251684 \"Strange Hermit\": service NPC %(trainer%)", text)
        end)

        it("counted kill objectives of neutral / mis-flagged mobs still give kill XP", function()
            -- 1501/1502 Mindless / Wretched Zombie carry faction "AH" in the DB; 8 + 8 kills (Forever counts)
            local r = memRun(UNDEAD_PALADIN, {
                { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
                { turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
                { complete = 364 },
                { turnin = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
            })
            assert.are.equal(16, kills(r))
            assert.is_true(r.summary.xpKill > 0)
            assert.are.same({}, messagesWith(r, "complete-no-kill"))
        end)

        it("missing counts: 1 kill for a named / unique NPC, a small default otherwise", function()
            -- the snapshot has Forever counts for both quests (Wowhead requirements): a proxy DB drops the
            -- count of 370's Captain Perrine 1662 and of 92462's Pesky Cirrusfly 251169
            local function withoutCount(q, npc)
                local c = {}
                for k, v in pairs(q) do c[k] = v end
                c.objectives = { creatures = {} }
                for i, e in ipairs(q.objectives.creatures) do
                    c.objectives.creatures[i] = (e[1] == npc) and { e[1] } or { e[1], e[2] }
                end
                return c
            end
            local fake = setmetatable({ quests = setmetatable({
                [370] = withoutCount(db.quests[370], 1662), [92462] = withoutCount(db.quests[92462], 251169),
            }, { __index = db.quests }) }, { __index = db })
            local function fakeRun(routeDef, steps, opts)
                local route = assert(schema.NormalizeRoute(routeDef))
                schema.AddSegment(route, { id = "s", title = "s", steps = steps })
                return V.NewRun(fake, schema, route, V.Profiles(route)[1], opts):execute()
            end
            -- 370: Captain Perrine (no count, single spawn) + 3 Scarlet Zealots + 3 Scarlet Missionaries
            local r = fakeRun(UNDEAD_PALADIN, { { level = 4 }, { accept = 370 }, { complete = 370 },
                { abandon = 370 } }, NO_XP_WARN)
            assert.are.equal(7, kills(r))
            assert.matches("objective counts partly assumed", messagesWith(r, "complete-kill-xp")[1].msg)
            -- with the snapshot's count (Perrine x1) nothing is assumed
            local real = memRun(UNDEAD_PALADIN, { { level = 4 }, { accept = 370 }, { complete = 370 },
                { abandon = 370 } }, NO_XP_WARN)
            assert.are.equal(7, kills(real))
            assert.is_nil(messagesWith(real, "complete-kill-xp")[1].msg:find("assumed", 1, true))
            -- 92462: Pesky Cirrusfly (no count, hostile, many spawns) -> defaultKillCount
            local r2 = fakeRun(SKY_DRUID, { { accept = 92462 }, { complete = 92462 }, { abandon = 92462 } },
                NO_XP_WARN)
            assert.are.equal(V.DEFAULTS.defaultKillCount, kills(r2))
            local r3 = fakeRun(SKY_DRUID, { { accept = 92462 }, { complete = 92462 }, { abandon = 92462 } },
                { ignore = NO_XP_WARN.ignore, defaultKillCount = 2 })
            assert.are.equal(2, kills(r3))
        end)

        it("drop items from friendly NPCs give no kill XP", function()
            -- 99141 "Patience": the three items come from Deathguards / Gordo (friendly, quest givers)
            local r = memRun(UNDEAD_PALADIN, { { level = 6 }, { accept = 99141 }, { complete = 99141 },
                { abandon = 99141 } }, NO_XP_WARN)
            assert.are.equal(0, r.summary.xpKill)
        end)
    end)

    it("a Skyborne route without faction is validated for both sides", function()
        local _, all = memRun({ api = 1, id = "mem-nf", title = "n", races = { "Skyborne" }, classes = { "DRUID" } },
            { { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } } })
        assert.are.equal(2, #all)
        local sides = {}
        for _, r in ipairs(all) do
            sides[#sides + 1] = r.profile.faction
            assert.is_nil(codes(r, "ERROR")["profile-race"])
            assert.is_nil(codes(r, "WARN")["profile-faction"])
            assert.are.equal(1, codes(r, "ERROR")["quest-race"] or codes(r, "ERROR")["quest-side"])
        end
        table.sort(sides)
        assert.are.same({ "Alliance", "Horde" }, sides)
    end)

    it("--ignore suppresses codes", function()
        local r = validate("AdventureAtlas_FxChain", { ignore = { ["quest-carried"] = true } })
        assert.is_nil(codes(r, "WARN")["quest-carried"])
        assert.are.equal(1, r.suppressed)
    end)
end)
