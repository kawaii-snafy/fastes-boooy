-- Validator grind report (V.RunProfile) and the skip-ahead check, on in-memory routes over real
-- Forever data (Deathknell, Tirisfal) and the clean fixture:
--   * worst case: steps marked optional (and their quests) are not done -> more grind at the level
--     gates; a required step that needs an optional quest -> ERROR optional-dependency;
--   * --incidental-pct: kill XP on the way as a share of the quest XP; the 0% / 15% band;
--   * the text / Markdown / JSON report only gain lines and fields;
--   * WARN skip-ahead: transient / optional steps that a later complete step, finished early by a
--     bg goal (an earlier step, the start state), would fast-forward.

local DB = require("lib.fbdb")
local Loader = require("lib.route_loader")
local V = require("lib.validator")
local json = require("lib.json")

local db, schema

local function messagesWith(result, code)
    local out = {}
    for _, m in ipairs(result.messages) do
        if m.code == code then out[#out + 1] = m end
    end
    return out
end

local UNDEAD_PALADIN = { api = 1, id = "mem", title = "mem", faction = "Horde", races = { "Scourge" },
    classes = { "PALADIN" }, levels = { 1, 5 } }

local function route(steps, def)
    local r = assert(schema.NormalizeRoute(def or UNDEAD_PALADIN))
    local _, errs = schema.AddSegment(r, { id = "s", title = "s", levels = { 1, 5 }, steps = steps })
    assert.are.same({}, errs)
    return r
end

-- the full validation of one profile (main run + shadow runs)
local function full(steps, opts, def)
    local r = route(steps, def)
    local o = { db = db, schema = schema }
    for k, v in pairs(opts or {}) do o[k] = v end
    return V.RunProfile(db, schema, r, V.Profiles(r)[1], o)
end

-- the main run alone (what V.RunProfile reports on top of)
local function plain(steps, opts, def)
    local r = route(steps, def)
    return V.NewRun(db, schema, r, V.Profiles(r)[1], opts or {}):execute()
end

-- Deathknell: 363 -> 364 (zombies) -> 3901 (preSingle 364); 376 (Novice Elreth)
local AT_MORDO, AT_SARVIS = { 1420, 30.2, 71.7 }, { 1420, 30.8, 66.2 }
local AT_ELRETH, AT_ZOMBIES = { 1420, 30.9, 66.0 }, { 1420, 32.5, 63.5 }

describe("validator grind report and skip-ahead", function()
    setup(function()
        db = DB.Load("tools/data/forever_db.lua")
        schema = Loader.LoadSchema(".")
    end)

    describe("worst case (optional steps not done)", function()
        local OPTIONAL_CHAIN = {
            { accept = 363, npc = 1568, at = AT_MORDO, optional = true },
            { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS, optional = true },
            { complete = 364, at = AT_ZOMBIES, optional = true },
            { turnin = 364, npc = 1569, at = AT_SARVIS, optional = true },
            { accept = 376, npc = 1661, at = AT_ELRETH },
            { id = "gate-3", level = 3 },
        }

        it("skips the optional steps and their XP: more grind at the level gates, no error", function()
            local r = full(OPTIONAL_CHAIN)
            assert.are.equal(0, r.counts.ERROR)
            local sm = r.summary
            assert.are.equal(4, sm.optionalSkipped)
            assert.are.equal(2, sm.optionalAccepts) -- 363 and 364
            assert.is_true(sm.grindKillsWorst > sm.grindKills)
            assert.are.equal(1, #sm.gates)
            local g = sm.gates[1]
            assert.are.equal("gate-3", g.stepId)
            assert.are.equal(3, g.level)
            assert.are.equal(sm.grindKills, g.kills)
            assert.are.equal(sm.grindKillsWorst, g.killsWorst)
            -- per segment and the band
            assert.are.equal(sm.grindKills, r.segments[1].grindKills)
            assert.are.equal(sm.grindKillsWorst, r.segments[1].grindKillsWorst)
            assert.are.equal(4, r.segments[1].optionalSkipped)
            assert.are.equal(sm.grindKills, sm.band["0"].grindKills)
            assert.are.equal(sm.grindKillsWorst, sm.band["0"].grindKillsWorst)
            assert.are.equal(15, sm.band["15"].incidentalPct)
            assert.is_true(sm.band["15"].grindKills <= sm.band["0"].grindKills)
            assert.is_true(sm.band["15"].grindKillsWorst <= sm.band["0"].grindKillsWorst)
            assert.are.equal(g.kills, g.band["0"].kills)
            assert.are.equal(g.killsWorst, g.band["0"].worst)
            -- the main run is unchanged by the shadow runs
            local p = plain(OPTIONAL_CHAIN)
            assert.are.equal(p.summary.endLevel, sm.endLevel)
            assert.are.equal(p.summary.grindKills, sm.grindKills)
            assert.are.equal(p.counts.WARN, r.counts.WARN)
        end)

        it("a route without optional steps: worst case = normal case", function()
            local r = full({
                { accept = 363, npc = 1568, at = AT_MORDO },
                { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS },
                { level = 3 },
            })
            assert.are.equal(r.summary.grindKills, r.summary.grindKillsWorst)
            assert.are.equal(0, r.summary.optionalSkipped)
        end)

        it("required complete / turnin of a quest accepted only on an optional step -> optional-dependency", function()
            local r = full({
                { accept = 363, npc = 1568, at = AT_MORDO },
                { turnin = 363, npc = 1569, at = AT_SARVIS },
                { accept = 364, npc = 1569, at = AT_SARVIS, optional = true },
                { complete = 364, at = AT_ZOMBIES, bg = true }, -- bg: never blocks, no error
                { complete = 364, at = AT_ZOMBIES },            -- required: ERROR
                { turnin = 364, npc = 1569, at = AT_SARVIS },   -- required: ERROR
            })
            local deps = messagesWith(r, "optional-dependency")
            assert.are.equal(2, #deps)
            for _, m in ipairs(deps) do
                assert.are.equal("ERROR", m.severity)
                assert.matches("required step depends on optional quest 364", m.msg, 1, true)
                assert.matches("s#3", m.msg, 1, true)
            end
            assert.are.equal(5, deps[1].step)
            assert.are.equal(6, deps[2].step)
            assert.are.equal(2, r.counts.ERROR)
            -- reported in step order among the main run's messages
            local idx = {}
            for i, m in ipairs(r.messages) do idx[m] = i end
            assert.is_true(idx[deps[1]] < idx[deps[2]])
        end)

        it("required accept whose prerequisite is turned in only on an optional step -> optional-dependency", function()
            local r = full({
                { accept = 363, npc = 1568, at = AT_MORDO },
                { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS },
                { complete = 364, at = AT_ZOMBIES },
                { turnin = 364, npc = 1569, at = AT_SARVIS, optional = true },
                { accept = 3901, npc = 1569, at = AT_SARVIS }, -- preSingle 364
            })
            local deps = messagesWith(r, "optional-dependency")
            assert.are.equal(1, #deps)
            assert.are.equal(5, deps[1].step)
            assert.matches("accept 3901", deps[1].msg, 1, true)
            assert.matches("optional step s#4", deps[1].msg, 1, true)
        end)

        it("a fully optional chain depends on nothing; --ignore suppresses the code", function()
            local steps = {
                { accept = 363, npc = 1568, at = AT_MORDO },
                { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS, optional = true },
                { complete = 364, at = AT_ZOMBIES, optional = true },
                { turnin = 364, accept = 3901, npc = 1569, at = AT_SARVIS, optional = true },
                { complete = 3901, at = { 1420, 32.5, 61.0 }, optional = true },
                { turnin = 3901, npc = 1569, at = AT_SARVIS, optional = true },
            }
            assert.are.equal(0, #messagesWith(full(steps), "optional-dependency"))
            local bad = {
                { accept = 363, npc = 1568, at = AT_MORDO },
                { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS, optional = true },
                { complete = 364, at = AT_ZOMBIES },
            }
            assert.are.equal(1, #messagesWith(full(bad), "optional-dependency"))
            local r = full(bad, { ignore = { ["optional-dependency"] = true } })
            assert.are.equal(0, #messagesWith(r, "optional-dependency"))
            assert.are.equal(0, r.counts.ERROR)
            assert.is_true(r.suppressed >= 1)
        end)
    end)

    describe("incidental kills (--incidental-pct)", function()
        -- level 5: enough grind left after the 8 + 8 zombies for 15 % incidental XP to show in the kill count
        local STEPS = {
            { accept = 363, npc = 1568, at = AT_MORDO },
            { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS },
            { complete = 364, at = AT_ZOMBIES },
            { turnin = 364, npc = 1569, at = AT_SARVIS },
            { level = 5 },
        }

        it("default 0: no incidental XP, the simulation as before", function()
            local r = full(STEPS)
            assert.are.equal(0, r.summary.incidentalPct)
            assert.are.equal(0, r.summary.xpIncidental)
            assert.are.equal(plain(STEPS).summary.xpGrind, r.summary.xpGrind)
        end)

        it("P% of each turned-in quest XP counts as kill XP and lowers the grind", function()
            local base = full(STEPS)
            local r = full(STEPS, { incidentalPct = 15 })
            assert.are.equal(15, r.summary.incidentalPct)
            -- 363: 40 XP, 364: 170 XP at level 1-2 (no level penalty): 15% each, rounded
            assert.are.equal(math.floor(40 * 0.15 + 0.5) + math.floor(170 * 0.15 + 0.5), r.summary.xpIncidental)
            assert.is_true(r.summary.grindKills < base.summary.grindKills)
            assert.are.equal(r.summary.grindKills, r.summary.band["15"].grindKills)
            assert.are.equal(base.summary.grindKills, r.summary.band["0"].grindKills)
            -- the band does not depend on the chosen percent
            assert.are.same(base.summary.band, r.summary.band)
        end)
    end)

    describe("report output", function()
        local STEPS = {
            { accept = 363, npc = 1568, at = AT_MORDO },
            { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS },
            { accept = 376, npc = 1661, at = AT_ELRETH, optional = true },
            { complete = 364, at = AT_ZOMBIES },
            { turnin = 364, npc = 1569, at = AT_SARVIS },
            { id = "gate", level = { 3, 0.5 } },
        }

        it("text: existing lines unchanged, grind lines added before the result line", function()
            local r = full(STEPS)
            local p = plain(STEPS)
            local withGrind = V.FormatText({ { module = "m", results = { r } } })
            local before = V.FormatText({ { module = "m", results = { p } } })
            local grind = V.GrindLines(r)
            assert.are.same({}, V.GrindLines(p))
            assert.is_true(#grind >= 5)
            assert.are.equal(#before + #grind, #withGrind)
            -- remove the grind block: the rest is the old report, line for line
            local rest, inBlock = {}, false
            local first = grind[1]
            local k = 0
            for _, line in ipairs(withGrind) do
                if line == first then inBlock = true end
                if inBlock and k < #grind then
                    k = k + 1
                    assert.are.equal(grind[k], line)
                else
                    rest[#rest + 1] = line
                end
            end
            assert.are.same(before, rest)
            local text = table.concat(withGrind, "\n")
            assert.matches(("grind kills: %d %%(worst case %d%%)"):format(r.summary.grindKills,
                r.summary.grindKillsWorst), text)
            assert.matches("grind kills band: incidental kills 0%% %-> %d+ %(worst case %d+%), 15%% of quest XP", text)
            assert.matches("3 %+50%%%s+%d+%s+%d+%s+%d+%s+%d+%s+s#6 id=gate", text)
            assert.matches("grind kills per segment", text, 1, true)
            -- the summary line comes right before the result line
            for i, line in ipairs(withGrind) do
                if line:match("^  result:") then
                    assert.matches("^  grind kills band:", withGrind[i - 1])
                end
            end
        end)

        it("an optional level step: '-' in the worst-case columns", function()
            local r = full({
                { accept = 363, npc = 1568, at = AT_MORDO },
                { turnin = 363, npc = 1569, at = AT_SARVIS },
                { id = "opt-gate", level = 2, optional = true },
            })
            assert.is_true(r.summary.gates[1].optional)
            local text = table.concat(V.GrindLines(r), "\n")
            assert.matches("%-%s+%d+%s+%-%s+s#3 id=opt%-gate %(optional%)", text)
        end)

        it("Markdown and JSON carry the grind report", function()
            local r = full(STEPS)
            local md = table.concat(V.FormatMarkdown({ { module = "m", results = { r } } }, db), "\n")
            assert.matches("Гринд до порогов уровня", md, 1, true)
            assert.matches("| порог уровня | шаг |", md, 1, true)
            local rep = json.decode(json.encode(V.ReportTable({ { module = "m", results = { r } } }, db)))
            local sm = rep.routes[1].summary
            assert.are.equal(r.summary.grindKillsWorst, sm.grindKillsWorst)
            assert.are.equal(r.summary.band["15"].grindKills, sm.band["15"].grindKills)
            assert.are.equal("gate", sm.gates[1].stepId)
            assert.is_not_nil(rep.routes[1].segments[1].band["0"].kills)
        end)

        it("the clean fixture: grind report present, still 0 errors and 0 warnings", function()
            local res = V.ValidateModule("tests/fixtures/validator/FastesBoooy_FxClean", { db = db, schema = schema })
            local r = res.results[1]
            assert.are.equal(0, r.counts.ERROR)
            assert.are.equal(0, r.counts.WARN)
            assert.are.equal(1, #r.summary.gates)
            assert.are.equal(r.summary.grindKills, r.summary.grindKillsWorst)
            assert.is_not_nil(r.summary.band["15"])
        end)
    end)

    describe("skip-ahead", function()
        local function skipAhead(r)
            local out = {}
            for _, m in ipairs(messagesWith(r, "skip-ahead")) do
                assert.are.equal("WARN", m.severity)
                out[#out + 1] = m.step
            end
            return out
        end

        local function zombies(later, extra)
            local steps = {
                { accept = 363, npc = 1568, at = AT_MORDO },
                { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS },
                { go = true, at = { 1420, 31.5, 65.0 } },                     -- 3: before the bg goal
                { complete = 364, bg = true, at = AT_ZOMBIES },               -- 4: bg goal
                { go = true, at = { 1420, 33.0, 62.0 } },                     -- 5: travel
                { accept = 376, npc = 1661, at = AT_ELRETH, optional = true }, -- 6: optional
                { train = true, npc = 244808, at = { 1420, 31.1, 66.4 } },   -- 7: transient
                { complete = 376, at = { 1420, 33.5, 64.0 }, bg = true },     -- 8: bg (never forwarded)
                later,                                                        -- 9
            }
            for _, s in ipairs(extra or {}) do steps[#steps + 1] = s end
            return steps
        end

        it("a later complete finished early by a bg goal: travel / transient / optional steps between", function()
            local r = plain(zombies({ complete = 364, at = AT_ZOMBIES },
                { { turnin = 364, npc = 1569, at = AT_SARVIS } }))
            assert.are.same({ 5, 6, 7 }, skipAhead(r))
            local m = messagesWith(r, "skip-ahead")[1]
            assert.matches("transient step [go] can be fast-forwarded", m.msg, 1, true)
            assert.matches("later step s#9 [complete 364]", m.msg, 1, true)
            assert.matches("as soon as bg step s#4 [complete 364] is done", m.msg, 1, true)
            assert.matches("optional step [accept 376]", messagesWith(r, "skip-ahead")[2].msg, 1, true)
            -- messages are in step order (sorted in among the other step messages; quest-carried comes last)
            local last = 0
            for _, msg in ipairs(r.messages) do
                if msg.step and msg.code ~= "quest-carried" then
                    assert.is_true(msg.step >= last)
                    last = msg.step
                end
            end
        end)

        it("no warning when the later step also turns in, or needs objectives the bg goal does not cover", function()
            assert.are.same({}, skipAhead(plain(zombies({ complete = 364, turnin = 364, npc = 1569, at = AT_SARVIS }))))
            local partial = zombies({ complete = 364, at = AT_ZOMBIES })
            partial[4] = { complete = { [364] = { 1 } }, bg = true, at = AT_ZOMBIES }
            assert.are.same({}, skipAhead(plain(partial)))
            local same = zombies({ complete = { [364] = { 1 } }, at = AT_ZOMBIES })
            same[4] = { complete = { [364] = { 1 } }, bg = true, at = AT_ZOMBIES }
            assert.are.same({ 5, 6, 7 }, skipAhead(plain(same)))
        end)

        it("an earlier step completing the same objectives works like a bg goal", function()
            local r = plain({
                { accept = 363, npc = 1568, at = AT_MORDO },
                { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS },
                { complete = 364, at = AT_ZOMBIES },
                { go = true, at = { 1420, 31.0, 66.0 } },
                { complete = 364, at = AT_ZOMBIES },
            })
            assert.are.same({ 4 }, skipAhead(r))
            assert.matches("as soon as earlier step s#3", messagesWith(r, "skip-ahead")[1].msg, 1, true)
        end)

        it("the start state: a quest complete there makes its later complete step done from the start", function()
            local state = { level = 2, xpFrac = 0, done = { 363 }, log = { 364 }, complete = { 364 }, flightPaths = {} }
            local r = plain({
                { go = true, at = { 1420, 31.5, 65.0 } },
                { complete = 364, at = AT_ZOMBIES },
                { turnin = 364, npc = 1569, at = AT_SARVIS },
            }, { startState = state })
            assert.are.same({ 1 }, skipAhead(r))
            assert.matches("from the start (quest 364", messagesWith(r, "skip-ahead")[1].msg, 1, true)
        end)

        it("steps of other classes are not walked; reported once with the shadow runs", function()
            local steps = zombies({ complete = 364, at = AT_ZOMBIES })
            steps[7] = { train = true, npc = 244808, at = { 1420, 31.1, 66.4 }, class = "DRUID" }
            local r = full(steps)
            assert.are.same({ 5, 6 }, skipAhead(r))
        end)
    end)
end)
