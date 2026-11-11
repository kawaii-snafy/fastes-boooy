-- The DB override layer (docs/dev/PLAN.md A.6.2): tools/overrides/<owner>.lua corrects single quests /
-- NPCs of the snapshot. tools/lib/fbdb.lua DB.ApplyOverrides (file format, pcall per file, one id in
-- one file, the XP median stays that of the snapshot), the validator (WARN db-override-unverified,
-- ERROR override-load / override-foreign-quest) and the three command lines (--no-overrides,
-- --overrides DIR). DB.Load itself applies nothing, and every spec that runs a tool on the fixtures
-- passes --no-overrides, so every other spec keeps its pinned numbers whatever tools/overrides holds
-- (the last block checks both).

local DB = require("lib.fbdb")
local Loader = require("lib.route_loader")
local V = require("lib.validator")
local H = require("fixtures.core.helpers")

local schema, root

local function run(cmd)
    local p = assert(io.popen(cmd .. " 2>&1; echo \"__EXIT=$?\""))
    local out = p:read("*a")
    p:close()
    local code = tonumber(out:match("__EXIT=(%d+)%s*$"))
    return code, (out:gsub("__EXIT=%d+%s*$", ""))
end

local counter = 0

-- a fresh override directory with these files ({ ["name.lua"] = "text" })
local function overrides(files)
    counter = counter + 1
    local dir = ("%s/ov%d"):format(root, counter)
    os.execute(("mkdir -p '%s'"):format(dir))
    for name, text in pairs(files) do
        local fh = assert(io.open(dir .. "/" .. name, "wb"))
        fh:write(text)
        fh:close()
    end
    return dir
end

-- a snapshot of its own (overrides change the tables in place) with the overrides applied
local function load(files)
    local db = DB.Load("tools/data/forever_db.lua")
    local report = DB.ApplyOverrides(db, overrides(files))
    return db, report
end

local function with(result, code)
    local out = {}
    for _, m in ipairs(result.messages) do
        if m.code == code then out[#out + 1] = m end
    end
    return out
end

local function profile(race, class)
    return { api = 1, id = "mem", title = "mem", faction = "Horde", races = { race }, classes = { class } }
end

local function full(db, steps, def, opts)
    local r = assert(schema.NormalizeRoute(def or profile("Scourge", "PALADIN")))
    local _, errs = schema.AddSegment(r, { id = "s", title = "s", steps = steps })
    assert.are.same({}, errs)
    local o = { db = db, schema = schema }
    for k, v in pairs(opts or {}) do o[k] = v end
    return V.RunProfile(db, schema, r, V.Profiles(r)[1], o)
end

local SRC = 'source = "in game 2026-11-10"'

describe("DB overrides", function()
    setup(function()
        schema = Loader.LoadSchema(".")
        root = os.tmpname()
        os.remove(root)
        os.execute(("mkdir -p '%s'"):format(root))
    end)
    teardown(function() os.execute(("rm -rf '%s'"):format(root)) end)

    describe("DB.ApplyOverrides", function()
        it("DB.Load applies none; a missing or empty directory is fine", function()
            local db = DB.Load("tools/data/forever_db.lua")
            assert.is_nil(db._overrides)
            local report = DB.ApplyOverrides(db, root .. "/does-not-exist")
            assert.same({}, report.files)
            assert.same({}, report.errors)
            report = DB.ApplyOverrides(db, overrides({ ["README.md"] = "not an override file" }))
            assert.same({}, report.files)
            -- the repository's own directory holds a README only (overrides are added by the route phases)
            for _, name in ipairs(DB.OverrideFiles("tools/overrides")) do assert.matches("%.lua$", name) end
        end)

        it("applies every field of the format and keeps the original values", function()
            local db, report = load({ ["shared.lua"] = ([[
return {
    quests = {
        [92460] = { xp = 85, %s, verified = true },
        [2383] = { races = { add = { "Troll" } }, classes = { add = { "MAGE", "WARRIOR" } }, %s },
        [861] = { exclusive = { remove = { 844 }, add = { 870 } }, %s },
        [3901] = { preSingle = { remove = { 364 }, add = { 376 } }, preGroup = { add = { 363 } }, %s },
        [860] = { breadcrumbFor = false, %s },
        [854] = { breadcrumbFor = 871, %s },
    },
    npcs = { [3620] = { sub = "Hunter Trainer", %s, verified = true } },
}
]]):format(SRC, SRC, SRC, SRC, SRC, SRC, SRC) })
            assert.same({}, report.errors)
            assert.same({ { file = "shared.lua", owner = "shared", quests = 6, npcs = 1 } }, report.files)
            local q = db.quests
            assert.equal(85, q[92460].xp)
            assert.equal("override", q[92460].xpSrc)
            -- masks: Orc (2) + Troll (128); WARRIOR (1) + MAGE (128)
            assert.equal(130, q[2383].races)
            assert.equal(129, q[2383].classes)
            -- lists
            assert.same({ 870 }, q[861].exclusive)
            assert.same({ 376 }, q[3901].preSingle)
            assert.same({ 363 }, q[3901].preGroup)
            -- the reverse exclusive index follows: 861 no longer excludes 844, 854 still does
            assert.same({ 854 }, DB.ExclusiveOf(db, 844))
            assert.same({ 861 }, DB.ExclusiveOf(db, 870))
            -- breadcrumbs, both ends
            assert.is_nil(q[860].breadcrumbFor)
            assert.is_nil(q[844].breadcrumbs)
            assert.equal(871, q[854].breadcrumbFor)
            assert.same({ 854 }, q[871].breadcrumbs)
            assert.equal("Hunter Trainer", db.npcs[3620].sub)
            -- the record of an override: owner file, source, verified, fields, original values
            local rec = db._overrides.quests[2383]
            assert.equal("shared.lua", rec.file)
            assert.equal("shared", rec.owner)
            assert.equal("in game 2026-11-10", rec.source)
            assert.is_false(rec.verified)
            assert.same({ races = true, classes = true }, rec.fields)
            assert.equal(2, rec.orig.races)
            assert.equal(1, rec.orig.classes)
            assert.is_true(db._overrides.quests[92460].verified)
            assert.same({ 844 }, db._overrides.quests[861].orig.exclusive)
            assert.equal("Pet Trainer", db._overrides.npcs[3620].orig.sub)
            assert.equal(db._overrides.quests[861], db._overrides.exclRemoved[844][861])
        end)

        it("a mask that means \"everyone\" stays; Skyborne gets the side the quest already has", function()
            local db = load({ ["shared.lua"] = ([[
return { quests = {
    [92460] = { races = { add = { "Orc" } }, %s },
    [363] = { races = { add = { "Skyborne" } }, %s },
} }
]]):format(SRC, SRC) })
            assert.equal(0, db.quests[92460].races)
            assert.equal(16 + 8589934592, db.quests[363].races, "a Horde quest: the Horde Skyborne bit only")
        end)

        it("the XP median per level is that of the snapshot: one quest's XP never moves another estimate", function()
            local plain = DB.Load("tools/data/forever_db.lua")
            local before = DB.EstimateQuestXp(plain, 1)
            assert.equal(40, before)
            -- every level-1 quest with known XP gets 5000 XP: a recomputed median would be 5000
            local entries = {}
            for id, q in pairs(plain.quests) do
                if q.level == 1 and q.xp and q.xp > 0 then
                    entries[#entries + 1] = ("[%d] = { xp = 5000, %s },"):format(id, SRC)
                end
            end
            assert.is_true(#entries > 20)
            local db = load({ ["shared.lua"] = "return { quests = {\n" .. table.concat(entries, "\n") .. "\n} }\n" })
            assert.equal(5000, db.quests[363].xp)
            assert.equal(before, DB.EstimateQuestXp(db, 1))
            -- 92460 (level 1, XP unknown) is still estimated with the snapshot's median, 363 gives its new XP
            local r = full(db, {
                { accept = 363, npc = 1568 }, { turnin = 363, npc = 1569 },
                { accept = 92460, npc = 251362 }, { turnin = 92460, npc = 251361 },
            })
            assert.equal(0, r.counts.ERROR)
            assert.matches("estimated 40 %(median of level%-1 quests%)", with(r, "xp-unknown")[1].msg)
            assert.equal(5000 + 40, r.summary.xpQuest)
            assert.equal(40, r.summary.xpQuestEstimated)
        end)

        it("an XP override is used silently, also for a quest outside the snapshot", function()
            local db = load({ ["shared.lua"] = ([[
return { quests = { [92460] = { xp = 85, %s }, [96779] = { xp = 3300, %s } } }
]]):format(SRC, SRC) })
            local r = full(db, { { accept = 92460, npc = 251362 }, { turnin = 92460, npc = 251361 } })
            assert.same({}, with(r, "xp-unknown"))
            assert.same({}, with(r, "db-override-unverified"), "no warning for an XP value")
            assert.equal(85, r.summary.xpQuest)
            assert.equal(0, r.summary.unknownXpQuests)
            -- 96779 is index-only (quest-out-of-scope): the brief record carries the XP
            assert.is_nil(db.quests[96779])
            assert.equal(3300, DB.QuestBrief(db, 96779).xp)
            r = full(db, { { accept = 96779 }, { turnin = 96779 } }, profile("Orc", "ROGUE"),
                { startState = { level = 24, file = "inline" } })
            assert.same({}, with(r, "xp-unknown"))
            assert.equal(3300, r.summary.xpQuest)
        end)

        it("pcall per file: a file that does not load or run is ignored and reported, the others apply", function()
            local db, report = load({
                ["a_syntax.lua"] = "return { quests = {\n",
                ["b_runtime.lua"] = "return { quests = { [363] = { xp = tonumber('5'), " .. SRC .. " } } }\n",
                ["c_shape.lua"] = "return 5\n",
                ["d_good.lua"] = "return { quests = { [363] = { xp = 77, " .. SRC .. " } } }\n",
            })
            assert.equal(3, #report.errors)
            assert.equal("a_syntax.lua", report.errors[1].name)
            assert.matches("/a_syntax%.lua$", report.errors[1].file)
            assert.matches("^load error: ", report.errors[1].msg)
            -- an override file runs in an empty environment: no globals, not even tonumber
            assert.equal("b_runtime.lua", report.errors[2].name)
            assert.matches("^runtime error: .*attempt to call global 'tonumber'", report.errors[2].msg)
            assert.equal("c_shape.lua", report.errors[3].name)
            assert.matches("the file must return a table", report.errors[3].msg)
            assert.same({ { file = "d_good.lua", owner = "d_good", quests = 1, npcs = 0 } }, report.files)
            assert.equal(77, db.quests[363].xp)
        end)

        it("format errors: the whole file is ignored, one line names the file and the first error", function()
            local cases = {
                { "[363] = { xp = 50 }", "quest 363: `source` is required" },
                { "[363] = { xp = 50, source = ' ' }", "`source` is required" },
                { "[363] = { xp = 50, " .. SRC .. ", verified = 'yes' }", "`verified` must be true or false" },
                { "[363] = { xp = 50, reqLevel = 2, " .. SRC .. " }", "quest 363: unknown key 'reqLevel'" },
                { "[363] = { " .. SRC .. " }", "quest 363: nothing is overridden" },
                { "[363] = { xp = 0, " .. SRC .. " }", "xp must be a number > 0" },
                { "[99999999] = { xp = 50, " .. SRC .. " }", "quest 99999999 does not exist in the Forever DB" },
                { "[363] = { races = { add = { 'Undead' } }, " .. SRC .. " }", "races.add: unknown raceFile 'Undead'" },
                { "[363] = { races = { remove = { 'Orc' } }, " .. SRC .. " }", "races must be { add = " },
                { "[363] = { classes = { add = { 'Paladin' } }, " .. SRC .. " }", "classes.add: unknown class token 'Paladin'" },
                { "[363] = { exclusive = { 364 }, " .. SRC .. " }", "exclusive must be { add = { ids }, remove = { ids } }" },
                { "[363] = { preSingle = { add = { 'x' } }, " .. SRC .. " }", "preSingle must be" },
                { "[363] = { breadcrumbFor = true, " .. SRC .. " }", "breadcrumbFor must be a quest id or false" },
                { "[96779] = { preSingle = { add = { 1 } }, " .. SRC .. " }",
                  "quest 96779 is outside the DB snapshot: only xp, races and classes can be overridden" },
                { "abc = { xp = 50, " .. SRC .. " }", "quest: the key abc is not an id" },
            }
            for _, case in ipairs(cases) do
                local db, report = load({ ["shared.lua"] = "return { quests = { [364] = { xp = 999, " .. SRC .. " },\n"
                    .. case[1] .. " } }\n" })
                assert.equal(1, #report.errors, case[1])
                assert.is_truthy(report.errors[1].msg:find(case[2], 1, true), case[1] .. " -> " .. report.errors[1].msg)
                assert.same({}, report.files)
                assert.equal(170, db.quests[364].xp, "the good entry of the same file is not applied either")
            end
            local _, report = load({ ["shared.lua"] = "return { quest = {}, npcs = { [1] = { sub = 'x', " .. SRC .. " }, "
                .. "[3620] = { " .. SRC .. " } } }\n" })
            assert.matches("unknown key 'quest' %(quests, npcs%) %(and 2 more%)", report.errors[1].msg)
        end)

        it("an id may appear in one file only: the second file is the one in error", function()
            local db, report = load({
                ["orc.lua"] = "return { quests = { [363] = { xp = 111, " .. SRC .. " } } }\n",
                ["warrior.lua"] = "return { quests = { [363] = { xp = 222, " .. SRC .. " }, [364] = { xp = 333, " .. SRC .. " } },\n"
                    .. "npcs = { [3620] = { sub = 'x', " .. SRC .. " } } }\n",
                ["zz.lua"] = "return { npcs = { [3620] = { sub = 'Stable Master', " .. SRC .. " } } }\n",
            })
            assert.equal(1, #report.errors)
            assert.equal("warrior.lua", report.errors[1].name)
            assert.matches("quest 363 is already overridden by orc%.lua %(an id may appear in one file only%)", report.errors[1].msg)
            assert.equal(111, db.quests[363].xp)
            assert.equal(170, db.quests[364].xp)
            -- the ignored file holds nothing: the NPC is free for the third file
            assert.equal("Stable Master", db.npcs[3620].sub)
            assert.equal(2, #report.files)
        end)

        it("shared.lua is read first: an owner file that repeats one of its ids is the one ignored", function()
            local dir = overrides({ ["zz.lua"] = "return {}\n", ["Shared.lua"] = "return {}\n", ["durotar.lua"] = "return {}\n",
                ["shared.lua"] = "return {}\n", ["a.lua"] = "return {}\n", ["notes.txt"] = "x" })
            assert.same({ "Shared.lua", "shared.lua", "a.lua", "durotar.lua", "zz.lua" }, DB.OverrideFiles(dir))
            -- durotar.lua sorts before shared.lua; its duplicate must not knock out the file of the shared path
            local db, report = load({
                ["durotar.lua"] = "return { quests = { [788] = { xp = 111, " .. SRC .. " }, [789] = { xp = 222, " .. SRC .. " } } }\n",
                ["shared.lua"] = "return { quests = { [788] = { xp = 333, " .. SRC .. " }, [363] = { xp = 444, " .. SRC .. " } } }\n",
            })
            assert.same({ { file = "shared.lua", owner = "shared", quests = 2, npcs = 0 } }, report.files)
            assert.equal(1, #report.errors)
            assert.equal("durotar.lua", report.errors[1].name)
            assert.matches("quest 788 is already overridden by shared%.lua", report.errors[1].msg)
            assert.equal(333, db.quests[788].xp)
            assert.equal(444, db.quests[363].xp)
            assert.are_not.equal(222, db.quests[789].xp)
        end)

        it("owner files: base name or directory, without regard to case; shared owns everything", function()
            assert.is_true(DB.OverrideOwns("warrior", "Classes/Warrior.lua"))
            assert.is_true(DB.OverrideOwns("durotar", "Segments/Durotar/01_ValleyOfTrials.lua"))
            assert.is_true(DB.OverrideOwns("orc", "Races/Orc.lua"))
            assert.is_true(DB.OverrideOwns("shared", "Segments/Durotar/01_ValleyOfTrials.lua"))
            assert.is_false(DB.OverrideOwns("warrior", "Classes/Warlock.lua"))
            assert.is_false(DB.OverrideOwns("orc", "Races/Troll.lua"))
            assert.is_false(DB.OverrideOwns("classes", "Route.lua"))
            assert.is_false(DB.OverrideOwns("warrior", nil))
        end)

        it("the default directory of a repository root has no detour through tools/..", function()
            assert.equal("tools/overrides", DB.OverridesDir("."))
            assert.equal("tools/overrides", DB.OverridesDir("tools/.."))
            assert.equal("/repo/tools/overrides", DB.OverridesDir("/repo/tools/.."))
            assert.equal("../x/tools/overrides", DB.OverridesDir("../x"))
        end)
    end)

    describe("validator: WARN db-override-unverified", function()
        -- 861 "The Hunter's Way" and 854 "Journey to the Crossroads" (Mulgore) list 844 "Plainstrider Menace"
        -- (the Crossroads) as exclusive in the snapshot
        local TAUREN = profile("Tauren", "WARRIOR")
        local REPLAY = {
            { accept = 861, npc = 3052 },
            { complete = 861 },
            { turnin = 861, npc = 3441 },
            { accept = 854, npc = 3418 },
            { turnin = 854, npc = 3429 },
            { id = "take-844", accept = 844, npc = 3338 },
        }
        local STATE = { startState = { level = 12, file = "inline" } }

        it("exclusive = { remove }: 861 and 854 done, then 844 is accepted", function()
            -- the snapshot: two errors
            local plain = DB.Load("tools/data/forever_db.lua")
            local r = full(plain, REPLAY, TAUREN, STATE)
            assert.equal(2, #with(r, "accept-exclusive"))
            assert.equal(2, r.counts.ERROR)

            local file = [[
return { quests = {
    [861] = { exclusive = { remove = { 844 } }, source = "in game 2026-11-10", verified = %s },
    [854] = { exclusive = { remove = { 844 } }, source = "in game 2026-11-10", verified = %s },
} }
]]
            -- unverified: the step passes, with one WARN per override it leans on
            local db = load({ ["shared.lua"] = file:format("false", "false") })
            r = full(db, REPLAY, TAUREN, STATE)
            assert.equal(0, r.counts.ERROR)
            local w = with(r, "db-override-unverified")
            assert.equal(2, #w)
            assert.equal("WARN", w[1].severity)
            assert.equal("take-844", w[1].stepId)
            assert.equal(844, w[1].quest)
            assert.equal("shared.lua", w[1].override)
            assert.matches("accept 844 \"Plainstrider Menace\" %(exclusive with 854 \"Journey to the Crossroads\" in the "
                .. "snapshot%): the exclusivity check passes only because of the unverified DB override in "
                .. "tools/overrides/shared%.lua %(source: in game 2026%-11%-10%)", w[1].msg)
            assert.matches("exclusive with 861", w[2].msg)
            -- verified in game: no warning; one of the two still warns
            db = load({ ["shared.lua"] = file:format("true", "true") })
            r = full(db, REPLAY, TAUREN, STATE)
            assert.equal(0, r.counts.ERROR)
            assert.same({}, with(r, "db-override-unverified"))
            db = load({ ["shared.lua"] = file:format("true", "false") })
            assert.equal(1, #with(full(db, REPLAY, TAUREN, STATE), "db-override-unverified"))
        end)

        it("the pair is removed in both directions: an override on 844 does the same", function()
            local db = load({ ["shared.lua"] = "return { quests = { [844] = { exclusive = { remove = { 861, 854 } }, " .. SRC
                .. " } } }\n" })
            assert.is_nil(db.quests[861].exclusive)
            assert.is_nil(db.quests[854].exclusive)
            local r = full(db, REPLAY, TAUREN, STATE)
            assert.equal(0, r.counts.ERROR)
            assert.equal(2, #with(r, "db-override-unverified"))
            -- nothing to lean on when the other quests were never taken
            r = full(db, { { accept = 844, npc = 3338 } }, TAUREN, STATE)
            assert.same({}, with(r, "db-override-unverified"))
        end)

        it("is acknowledged with ok = \"db-override-unverified\" on the step", function()
            local db = load({ ["shared.lua"] = "return { quests = { [844] = { exclusive = { remove = { 861, 854 } }, " .. SRC
                .. " } } }\n" })
            local steps = {}
            for i, s in ipairs(REPLAY) do steps[i] = s end
            -- CONFIRM: 844 is offered after 861 / 854 (the quest stays in the log: the end of this test route)
            steps[6] = { id = "take-844", accept = 844, npc = 3338, ok = { "db-override-unverified", "quest-carried" } }
            local r = full(db, steps, TAUREN, STATE)
            assert.equal(0, r.counts.WARN)
            assert.equal(3, r.acceptedWarn)
            for _, m in ipairs(with(r, "db-override-unverified")) do assert.is_true(m.accepted) end
        end)

        it("race and class masks: the step passes only because of the override", function()
            -- 2383 "Simple Parchment": Orc WARRIOR in the snapshot
            local steps = { { accept = 4641, npc = 10176 }, { turnin = 4641, accept = 788, npc = 3143 }, { complete = 788 },
                { turnin = 788, npc = 3143 }, { id = "letter", accept = 2383, npc = 3143 } }
            local plain = DB.Load("tools/data/forever_db.lua")
            assert.equal(1, #with(full(plain, steps, profile("Troll", "WARRIOR")), "quest-race"))
            assert.equal(1, #with(full(plain, steps, profile("Orc", "MAGE")), "quest-class"))
            local db = load({ ["shared.lua"] = "return { quests = { [2383] = { races = { add = { \"Troll\" } }, "
                .. "classes = { add = { \"MAGE\" } }, " .. SRC .. " } } }\n" })
            local r = full(db, steps, profile("Troll", "WARRIOR"))
            assert.equal(0, r.counts.ERROR)
            assert.matches("accept 2383 \"Simple Parchment\": the race check passes only because of the unverified DB "
                .. "override", with(r, "db-override-unverified")[1].msg)
            r = full(db, steps, profile("Orc", "MAGE"))
            assert.equal(0, r.counts.ERROR)
            assert.matches("the class check passes only", with(r, "db-override-unverified")[1].msg)
            -- the profile the snapshot already allows does not lean on the override
            r = full(db, steps, profile("Orc", "WARRIOR"))
            assert.same({}, with(r, "db-override-unverified"))
            -- a race the override does not add is still an error
            assert.equal(1, #with(full(db, steps, profile("Tauren", "WARRIOR")), "quest-race"))
        end)

        it("prerequisites: preSingle / preGroup", function()
            -- 3901 needs 364 in the snapshot
            local steps = { { id = "early", accept = 3901, npc = 1569 } }
            local plain = DB.Load("tools/data/forever_db.lua")
            assert.equal(1, #with(full(plain, steps), "accept-prereq"))
            local db = load({ ["shared.lua"] = "return { quests = { [3901] = { preSingle = { remove = { 364 } }, " .. SRC
                .. " } } }\n" })
            local r = full(db, steps)
            assert.equal(0, r.counts.ERROR)
            assert.matches("accept 3901 \"Rattling the Rattlecages\": the prerequisite check passes only because",
                with(r, "db-override-unverified")[1].msg)
            -- an added prerequisite is checked like the snapshot's own
            db = load({ ["shared.lua"] = "return { quests = { [363] = { preGroup = { add = { 364 } }, " .. SRC .. " } } }\n" })
            r = full(db, { { accept = 363, npc = 1568 } })
            assert.equal(1, #with(r, "accept-prereq"))
            assert.same({}, with(r, "db-override-unverified"))
        end)

        it("an NPC's sub name: the trainer check", function()
            local step = { { id = "t", train = true, npc = 3620 } }
            local plain = DB.Load("tools/data/forever_db.lua")
            assert.equal(1, #with(full(plain, step, profile("Orc", "WARRIOR")), "train-not-class-trainer"))
            local file = "return { npcs = { [3620] = { sub = \"Warrior Trainer\", " .. SRC .. ", verified = %s } } }\n"
            local db = load({ ["shared.lua"] = file:format("false") })
            local r = full(db, step, profile("Orc", "WARRIOR"))
            assert.same({}, with(r, "train-not-class-trainer"))
            assert.matches("NPC 3620 \"Harruk\": the train check passes only because of the unverified DB override",
                with(r, "db-override-unverified")[1].msg)
            db = load({ ["shared.lua"] = file:format("true") })
            assert.same({ ERROR = 0, WARN = 0, INFO = 0 }, full(db, step, profile("Orc", "WARRIOR")).counts)
        end)
    end)

    describe("command lines", function()
        local VALIDATE = "lua5.1 tools/validate_routes.lua " -- overrides: explicit (every use passes --overrides DIR)

        it("validate: applied by default from --overrides DIR, not with --no-overrides", function()
            local dir = overrides({ ["shared.lua"] = "return { quests = { [363] = { xp = 4000, " .. SRC .. " } } }\n" })
            local code, out = run(VALIDATE .. "--overrides " .. dir .. " --route tg-undead-paladin " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("validate_routes: DB overrides from " .. dir:gsub("%p", "%%%0") .. ": 1 file%(s%) %(shared%.lua%), "
                .. "1 quest%(s%), 0 npc%(s%)", out)
            assert.matches("quest XP 4%d%d%d;", out)
            code, out = run(VALIDATE .. "--no-overrides --overrides " .. dir .. " --route tg-undead-paladin " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("quest XP 630;", out)
            assert.is_nil(out:find("DB overrides", 1, true))
        end)

        it("ERROR override-load on a full run, a note when a file filter is active", function()
            local dir = overrides({
                ["mage.lua"] = "return { quests = { [3086] = { xp = 41 } } }\n",
                ["shared.lua"] = "return { quests = { [363] = { xp = 41, " .. SRC .. " } } }\n",
            })
            local code, out = run(VALIDATE .. "--overrides " .. dir .. " " .. H.GUIDES_DIR)
            assert.equal(1, code, out)
            assert.matches("== DB overrides .-\n  ERROR %(" .. dir:gsub("%p", "%%%0") .. "/mage%.lua%) %[override%-load%] the override "
                .. "file is ignored in this run: quest 3086: `source` is required", out)
            assert.matches("1 file%(s%) %(shared%.lua%), 1 quest%(s%), 0 npc%(s%); 1 file%(s%) ignored", out)
            -- another agent's half-written file does not stop this run
            code, out = run(VALIDATE .. "-q --strict --overrides " .. dir .. " --skip 'Classes/*' --keep Classes/Warrior.lua "
                .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("  note  %(.-/mage%.lua%) %[override%-load%] .- %-%- not counted: a file filter", out)
        end)

        it("ERROR override-foreign-quest: an owner's file may not correct a quest other files use", function()
            -- 788 is a quest of the shared Durotar segment; 2383 only of Classes/Warrior.lua
            local own = "return { quests = { [2383] = { xp = 45, " .. SRC .. " } } }\n"
            local zone = "return { quests = { [788] = { xp = 180, " .. SRC .. " } } }\n"
            local foreign = "return { quests = { [788] = { xp = 180, " .. SRC .. " }, [2383] = { xp = 45, " .. SRC .. " } } }\n"
            local code, out = run(VALIDATE .. "-q --overrides " .. overrides({ ["warrior.lua"] = own }) .. " " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            code, out = run(VALIDATE .. "--overrides " .. overrides({ ["warrior.lua"] = foreign }) .. " " .. H.GUIDES_DIR)
            assert.equal(1, code, out)
            assert.matches("ERROR %(.-/warrior%.lua%) %[override%-foreign%-quest%] warrior%.lua overrides quest 788 \"Cutting "
                .. "Teeth\", but 3 loaded step%(s%) outside its owner files use the quest %(first: step 'tg%-dur%-788' in "
                .. "Segments/Durotar/01_ValleyOfTrials%.lua%): a value for a quest of another file belongs to shared%.lua", out)
            local _, n = out:gsub("%[override%-foreign%-quest%]", "")
            assert.equal(1, n, "2383 is the warrior file's own")
            -- the directory name owns the zone's files; shared owns everything
            code, out = run(VALIDATE .. "-q --overrides " .. overrides({ ["durotar.lua"] = zone }) .. " " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            -- ...but not the class file's quest
            code, out = run(VALIDATE .. "-q --overrides " .. overrides({ ["durotar.lua"] = foreign }) .. " " .. H.GUIDES_DIR)
            assert.equal(1, code, out)
            code, out = run(VALIDATE .. "-q --overrides " .. overrides({ ["shared.lua"] = foreign }) .. " " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            -- errors always count, also with --own
            code = run(VALIDATE .. "-q --own Route.lua --overrides " .. overrides({ ["warrior.lua"] = foreign }) .. " "
                .. H.GUIDES_DIR)
            assert.equal(1, code)
        end)

        it("the simulator and the generator apply them too, and report a broken file", function()
            local good = overrides({ ["shared.lua"] = "return { quests = { [3901] = { preSingle = { add = { 376 } }, " .. SRC
                .. " } } }\n" })
            local bad = overrides({ ["shared.lua"] = "return {\n" })
            -- the generator: the corrected prerequisites end up in questMeta
            local code, out = run("lua5.1 tools/gen_route_data.lua --stdout --overrides " .. good .. " " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("%[3901%] = { level = 3, reqLevel = 1, preAny = { 364, 376 } }", out)
            code, out = run("lua5.1 tools/gen_route_data.lua --stdout --no-overrides --overrides " .. good .. " " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("%[3901%] = { level = 3, reqLevel = 1, preAny = { 364 } }", out)
            code, out = run("lua5.1 tools/gen_route_data.lua --check --overrides " .. bad .. " " .. H.GUIDES_DIR)
            assert.equal(1, code, out)
            assert.matches("gen_route_data: ERROR override%-load .-/shared%.lua: the override file is ignored", out)
            assert.matches("nothing generated", out)
            -- the simulator: a broken file fails a full run and is a note with a file filter
            local sim = "lua5.1 tools/simulate_routes.lua --no-reload " -- overrides: explicit (--overrides DIR below)
                .. "--route tg-orc-warrior "
            code, out = run(sim .. "--overrides " .. bad .. " " .. H.GUIDES_DIR)
            assert.equal(1, code, out)
            assert.matches("simulate_routes: ERROR override%-load .-/shared%.lua", out)
            assert.matches("1 simulation%(s%), 1 passed, 0 failed", out)
            code, out = run(sim .. "--overrides " .. bad .. " --skip 'Races/*' " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("simulate_routes: note override%-load", out)
            code, out = run(sim .. "--overrides " .. good .. " " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
        end)
    end)

    -- Later phases add files to tools/overrides (zones, classes, shared.lua) and may not touch tests/**:
    -- no spec may depend on what that directory holds by default. One exception, named explicitly with
    -- `--overrides tools/overrides`: the harness proofs of tests/spec/guides_layout_spec.lua (the Tauren runs
    -- prove the path WITH tools/overrides/shared.lua, docs/dev/PLAN.md D.2 F2b step 6; a class override file
    -- that moves their numbers fails them, and P2 may retire them before phase C).
    describe("the specs do not depend on tools/overrides", function()
        local TOOLS = { "validate_routes", "simulate_routes", "gen_route_data" }

        local function readFile(path)
            local fh = assert(io.open(path, "r"))
            local text = fh:read("*a")
            fh:close()
            return text
        end

        it("every tool command line of a spec says --no-overrides or --overrides DIR", function()
            local p = assert(io.popen("ls tests/spec/*_spec.lua"))
            local files = {}
            for f in p:lines() do files[#files + 1] = f end
            p:close()
            assert.is_true(#files > 30)
            local bad, seen = {}, 0
            for _, f in ipairs(files) do
                local n = 0
                for line in (readFile(f) .. "\n"):gmatch("([^\n]*)\n") do
                    n = n + 1
                    for _, tool in ipairs(TOOLS) do
                        local _, e = line:find("lua5%.1 tools/" .. tool .. "%.lua", 1)
                        if e then
                            seen = seen + 1
                            local flagged = line:sub(e + 1, e + 15) == " --no-overrides"
                                or line:find("--overrides ", 1, true) ~= nil
                                -- the command is completed elsewhere with --overrides DIR (say so on the line)
                                or line:find("-- overrides: explicit", 1, true) ~= nil
                            if not flagged then bad[#bad + 1] = ("%s:%d: %s"):format(f, n, line) end
                        end
                    end
                end
            end
            assert.is_true(seen > 50, "the scan found the command lines")
            assert.same({}, bad)
        end)

        it("the fixture targets of the Makefile pass $(NO_OVERRIDES)", function()
            local bad, seen = {}, 0
            for line in (readFile("Makefile") .. "\n"):gmatch("([^\n]*)\n") do
                -- (a recipe runs a tool as `$(LUA) tools/<tool>.lua` or, the simulator, as `$(SIM)`)
                local tool = line:find("tools/", 1, true) or line:find("$(SIM)", 1, true)
                if line:find("^\t") and tool and line:find("$(FIXTURE_", 1, true) then
                    seen = seen + 1
                    if not line:find("$(NO_OVERRIDES)", 1, true) then bad[#bad + 1] = line end
                end
            end
            assert.is_true(seen >= 7, "the scan found the fixture recipes")
            assert.same({}, bad)
            assert.matches("\nNO_OVERRIDES = %-%-no%-overrides\n", readFile("Makefile"))
        end)

        it("a broken and a value-changing file in the default directory do not move the fixture commands", function()
            -- a second repository root: the tools and the fixtures of this checkout, and a tools/overrides
            -- of its own (the tools find the directory from their own location / the working directory)
            local p = assert(io.popen("pwd"))
            local here = p:read("*l")
            p:close()
            local alt = root .. "/alt"
            os.execute(("mkdir -p '%s/tools/overrides'"):format(alt))
            for _, name in ipairs({ "addons", "tests", "tools/lib", "tools/data", "tools/validate_routes.lua",
                "tools/simulate_routes.lua", "tools/gen_route_data.lua" }) do
                assert.equal(0, (run(("ln -s '%s/%s' '%s/%s'"):format(here, name, alt, name))))
            end
            local function put(name, text)
                local fh = assert(io.open(alt .. "/tools/overrides/" .. name, "wb"))
                fh:write(text)
                fh:close()
            end
            -- passes luacheck, breaks the format (no `source`): the kind of file another agent may leave
            put("durotar.lua", "return { quests = { [788] = { xp = 5 } } }\n")
            -- valid: more XP for a Deathknell quest, one more prerequisite for a Valley of Trials quest
            put("shared.lua", "return { quests = { [364] = { xp = 4000, " .. SRC .. ", verified = true },\n"
                .. "    [789] = { preSingle = { add = { 4641 } }, " .. SRC .. ", verified = true } } }\n")
            local function inAlt(cmd) return run(("cd '%s' && %s"):format(alt, cmd)) end
            local FX = "tests/fixtures/"
            local G, TR = H.GUIDES_DIR, H.FIXTURE_DIR

            -- the files are in effect there: without the option every tool moves or fails
            local code, out = inAlt("lua5.1 tools/validate_routes.lua --summary " .. G) -- overrides: explicit (the default)
            assert.equal(1, code, out)
            assert.matches("%[override%-load%]", out)
            assert.matches("validate_routes: DB overrides from tools/overrides: 1 file%(s%) %(shared%.lua%), 2 quest%(s%), "
                .. "0 npc%(s%); 1 file%(s%) ignored", out)
            assert.matches("\ntg%-undead%-paladin\tScourge PALADIN Horde\t0\t%d+\t0\t0\t[4-9]%.%d%d\t", out)
            code, out = inAlt("lua5.1 tools/gen_route_data.lua --check " .. G) -- overrides: explicit (the default)
            assert.equal(1, code, out)
            assert.matches("gen_route_data: ERROR override%-load tools/overrides/durotar%.lua", out)
            code, out = inAlt("lua5.1 tools/simulate_routes.lua --no-reload --route tg-orc-warrior " .. G) -- overrides: explicit
            assert.equal(1, code, out)
            assert.matches("simulate_routes: ERROR override%-load tools/overrides/durotar%.lua", out)

            -- the command lines the specs and the fixture targets use: the same output as in this checkout
            local commands = {
                "lua5.1 tools/validate_routes.lua --no-overrides -q --strict --end-level --summary " .. G,
                "lua5.1 tools/validate_routes.lua --no-overrides " .. G .. " " .. TR,
                "lua5.1 tools/validate_routes.lua --no-overrides -q " .. H.LIB_DIR .. " " .. H.COMPOSED_DIR .. " " .. FX
                    .. "validator/FastesBoooy_FxClean",
                "lua5.1 tools/validate_routes.lua --no-overrides -q --strict --harness " .. FX
                    .. "validator/FastesBoooy_FxHarnessLib --profile race=Scourge,class=PALADIN,faction=Horde --state " .. FX
                    .. "validator/harness_state_6.json",
                "lua5.1 tools/gen_route_data.lua --no-overrides --check " .. G .. " " .. H.LIB_DIR .. " " .. H.COMPOSED_DIR
                    .. " " .. FX .. "validator/FastesBoooy_FxClean",
                "lua5.1 tools/gen_route_data.lua --no-overrides --stdout " .. G,
                "lua5.1 tools/simulate_routes.lua --no-overrides --no-reload --route tg-orc-warrior " .. G,
            }
            for _, cmd in ipairs(commands) do
                local codeHere, outHere = run(cmd)
                local codeAlt, outAlt = inAlt(cmd)
                assert.equal(0, codeHere, cmd .. "\n" .. outHere)
                assert.equal(codeHere, codeAlt, cmd .. "\n" .. outAlt)
                assert.equal(outHere, outAlt, cmd)
            end
            -- and the pinned numbers themselves
            code, out = inAlt(commands[1])
            assert.equal(0, code, out)
            assert.matches("\ntg%-undead%-paladin\tScourge PALADIN Horde\t0\t0\t0\t0\t3%.92\t3%.92\t0\t0\t%-\t%-\n", out)
            assert.is_nil(out:find("DB overrides", 1, true))
        end)
    end)
end)
