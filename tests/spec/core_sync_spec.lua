-- luacheck: std lua51+busted
-- Level sync, gray-quest skip, unreachable / never-taken quest rules, Forward() and GetUpcoming()
-- (Core/Engine.lua, Core/Compat.lua gray quests, route data questMeta from tools/gen_route_data.lua).
--
-- The route "sync-route" is registered through the public API (helpers `register`): four segments
-- with level ranges and synthetic quests whose prerequisites are mirrored in its questMeta:
--   s1 1-5    91001 (2) -> 91002 (3, needs 91001)                       + bg complete 91002, go
--   s2 5-10   91003 (6), 91004 (7), 91005 (8, needs 91003)               + train
--   s3 10-15  91006 (11), 91007 (12, needs 91005 OR 91006), 91008 (9, needs 91002)
--   s4 15-20  91009 (16)

local H = require("fixtures.core.helpers")
local Mock = H.Mock

local ROUTE = "sync-route"

local QUESTS = {
    [91001] = { title = "Start Here", level = 2 },
    [91002] = { title = "Follow Up", level = 3, pre = { 91001 },
        objectives = { { text = "Thing collected", required = 3 } } },
    [91003] = { title = "Middle One", level = 6 },
    [91004] = { title = "Middle Two", level = 7 },
    [91005] = { title = "Unlocked By One", level = 8, pre = { 91003 } },
    [91006] = { title = "Late One", level = 11 },
    [91007] = { title = "Either Way", level = 12, preAny = { 91005, 91006 } },
    [91008] = { title = "Needs Follow Up", level = 9, pre = { 91002 } },
    [91009] = { title = "The End", level = 16 },
}

local function questMeta()
    local meta = {}
    for id, q in pairs(QUESTS) do
        meta[id] = { level = q.level, reqLevel = 1, preAll = q.pre, preAny = q.preAny }
    end
    return meta
end

local function defineQuests(m)
    for id, q in pairs(QUESTS) do m:DefineQuest(id, q) end
end

local function register(withMeta)
    return function(api)
        api.RegisterRoute({ api = 1, id = ROUTE, title = { en = "Sync route", ru = "Маршрут синхронизации" },
            faction = "Horde", races = { "Scourge" }, classes = { "PALADIN" }, levels = { 1, 20 }, default = true })
        api.AddSegment(ROUTE, { id = "s1", title = { en = "1-5 Start", ru = "1-5 Начало" }, levels = { 1, 5 },
            steps = {
                { id = "s1-a1", accept = 91001 },
                { id = "s1-t1", turnin = 91001, accept = 91002 },
                { id = "s1-bg", complete = 91002, bg = true },
                { id = "s1-go", go = true, at = { 1420, 40, 40 } },
                { id = "s1-c2", complete = 91002 },
                { id = "s1-t2", turnin = 91002 },
            } })
        api.AddSegment(ROUTE, { id = "s2", title = { en = "5-10 Middle", ru = "5-10 Середина" }, levels = { 5, 10 },
            steps = {
                { id = "s2-a3", accept = { 91003, 91004 } },
                { id = "s2-train", train = true },
                { id = "s2-t3", turnin = 91003 },
                { id = "s2-a5", accept = 91005 },
                { id = "s2-t4", turnin = 91004 },
                { id = "s2-t5", turnin = 91005 },
            } })
        api.AddSegment(ROUTE, { id = "s3", title = { en = "10-15 Late", ru = "10-15 Позже" }, levels = { 10, 15 },
            steps = {
                { id = "s3-a6", accept = 91006 },
                { id = "s3-a7", accept = 91007 },
                { id = "s3-t6", turnin = 91006 },
                { id = "s3-t7", turnin = 91007 },
                { id = "s3-a8", accept = 91008 },
                { id = "s3-t8", turnin = 91008 },
            } })
        api.AddSegment(ROUTE, { id = "s4", title = { en = "15-20 End", ru = "15-20 Конец" }, levels = { 15, 20 },
            steps = {
                { id = "s4-a9", accept = 91009 },
                { id = "s4-t9", turnin = 91009 },
            } })
        if withMeta ~= false then api.AddRouteData(ROUTE, { questMeta = questMeta() }) end
    end
end

-- boot the sync route at `level`; opts.settings = account settings; opts.listen = messages recorded
-- from before the login; opts.meta = false: no questMeta
local function boot(level, opts)
    opts = opts or {}
    local sv
    if opts.settings then sv = { FastesBoooyDB = { settings = opts.settings } } end
    local m, ns = H.new({ fixture = false, quests = false, setup = defineQuests, register = register(opts.meta),
        player = { level = level }, savedVariables = opts.savedVariables or sv })
    local rec = {}
    for _, msg in ipairs(opts.listen or { "SYNC_SUGGESTION" }) do rec[msg] = H.record(ns, msg) end
    Mock.boot(m, { "FastesBoooy" })
    H.settle(m)
    return m, ns, rec
end

local function reload(m, opts)
    opts = opts or {}
    return H.reload(m, { fixture = false, register = register(opts.meta), coldStart = opts.coldStart })
end

local function E(ns) return ns.Engine end

local function idx(ns, id) return assert(E(ns):IndexOf(id), id) end

local function done(ns, id) return E(ns):IsDone(idx(ns, id)) end

-- the void reason of the action of `type` / `quest` in step `id`
local function why(ns, id, actionType, quest)
    local s = E(ns):GetSteps()[idx(ns, id)]
    for _, a in ipairs(s.actions) do
        if a.type == actionType and a.quest == quest then return E(ns):VoidReason(a) end
    end
    error("no " .. actionType .. " " .. quest .. " in " .. id)
end

local function setSetting(ns, m, key, value)
    ns.db.settings[key] = value
    ns:Fire("SETTINGS_CHANGED", key, value)
    H.settle(m)
end

describe("level sync", function()
    describe("outleveled segments", function()
        it("a segment is outleveled at level >= levels[2] + margin", function()
            local _, ns = boot(1)
            local e = E(ns)
            local seg = { levels = { 1, 5 } }
            assert.is_false(e:IsOutleveled(seg, 6, 2))
            assert.is_true(e:IsOutleveled(seg, 7, 2))
            assert.is_true(e:IsOutleveled(seg, 5, 0))
            assert.is_false(e:IsOutleveled(seg, 9, 5))
            assert.is_true(e:IsOutleveled(seg, 10, 5))
            assert.is_false(e:IsOutleveled({ id = "no-levels" }, 60, 0), "a segment without levels never is")
            assert.equal(2, e:SyncMargin(), "default margin")
        end)

        it("no suggestion while the cursor segment is not outleveled (margin)", function()
            local _, ns, rec = boot(6)
            assert.equal("s1-a1", H.cur(ns))
            assert.is_nil(E(ns):GetSyncSuggestion())
            for _, r in ipairs(rec.SYNC_SUGGESTION) do assert.is_nil(r[1]) end
        end)

        it("follows the margin setting", function()
            local m, ns = boot(7, { settings = { levelSyncMargin = 5 } })
            assert.is_nil(E(ns):GetSyncSuggestion(), "7 < 5 + 5")
            setSetting(ns, m, "levelSyncMargin", 0)
            assert.is_table(E(ns):GetSyncSuggestion())
            assert.equal("s2", E(ns):GetSyncSuggestion().to.id, "s2 (5-10) fits at 7 + margin 0")
        end)
    end)

    describe("suggestion", function()
        it("offers the first later segment that is not outleveled (SYNC_SUGGESTION at login)", function()
            local _, ns, rec = boot(7)
            local sug = E(ns):GetSyncSuggestion()
            assert.is_table(sug)
            assert.equal(7, sug.level)
            assert.equal("s1", sug.from.id)
            assert.equal("1-5 Start", ns.Schema.Text(sug.from.title, "enUS"))
            assert.equal("s2", sug.to.id)
            assert.equal("s2-a3", sug.toStepId)
            assert.equal(idx(ns, "s2-a3"), sug.toIndex)
            assert.equal(1, #rec.SYNC_SUGGESTION, "fired once")
            assert.equal(sug, rec.SYNC_SUGGESTION[1][1])
            assert.equal("s1-a1", H.cur(ns), "nothing applied in ask mode")
            assert.is_nil(ns.cdb.syncFloor)
        end)

        it("skips segments that are outleveled too", function()
            local _, ns = boot(13)
            local sug = E(ns):GetSyncSuggestion()
            assert.equal("s1", sug.from.id)
            assert.equal("s3", sug.to.id, "s2 (5-10) is outleveled at 13 as well")
            assert.equal("s3-a6", sug.toStepId)
        end)

        it("never suggests when no later segment fits", function()
            local _, ns = boot(25)
            assert.is_nil(E(ns):GetSyncSuggestion(), "every segment is below level 25")
        end)

        it("appears on level-up and changes with the level", function()
            local m, ns, rec = boot(5)
            assert.is_nil(E(ns):GetSyncSuggestion())
            m:SetLevel(7)
            H.settle(m)
            assert.equal("s2", E(ns):GetSyncSuggestion().to.id)
            m:SetLevel(12)
            H.settle(m)
            assert.equal("s3", E(ns):GetSyncSuggestion().to.id)
            local n = #rec.SYNC_SUGGESTION
            assert.is_true(n >= 2)
            assert.equal("s3", rec.SYNC_SUGGESTION[n][1].to.id)
            E(ns):Refresh()
            assert.equal(n, #rec.SYNC_SUGGESTION, "not fired again while unchanged")
        end)

        it("off: never suggests; an explicit ApplySync still jumps", function()
            local _, ns, rec = boot(7, { settings = { levelSync = "off" } })
            assert.is_nil(E(ns):GetSyncSuggestion())
            for _, r in ipairs(rec.SYNC_SUGGESTION) do assert.is_nil(r[1]) end
            assert.is_true(E(ns):ApplySync())
            assert.equal("s2-a3", H.cur(ns))
        end)

        it("an invalid mode counts as ask", function()
            local _, ns = boot(7, { settings = { levelSync = "sometimes" } })
            assert.equal("ask", ns.db.settings.levelSync, "reset on load")
            assert.is_table(E(ns):GetSyncSuggestion())
        end)
    end)

    describe("apply / dismiss / undo", function()
        it("ApplySync: the steps before the target are done, chat line, events, floor saved", function()
            local m, ns, rec = boot(7, { listen = { "SYNC_SUGGESTION", "STEP_CHANGED", "PROGRESS_UPDATED", "SYNC_APPLIED" } })
            local mark = #m.chat
            local steps0, progress0 = #rec.STEP_CHANGED, #rec.PROGRESS_UPDATED
            assert.is_true(E(ns):ApplySync())
            assert.equal("s2-a3", H.cur(ns))
            for i = 1, idx(ns, "s2-a3") - 1 do assert.is_true(E(ns):IsDone(i), "step " .. i) end
            assert.is_false(done(ns, "s2-a3"))
            assert.is_true(H.chatHas(m, "Level sync: you are level 7 -- continuing at \"5-10 Middle\"", mark + 1),
                table.concat(H.chat(m, mark + 1), " | "))
            assert.is_true(#rec.STEP_CHANGED > steps0)
            assert.equal("s2-a3", rec.STEP_CHANGED[#rec.STEP_CHANGED][1].id)
            assert.is_true(#rec.PROGRESS_UPDATED > progress0)
            local f = ns.cdb.syncFloor
            assert.equal(ROUTE, f.route)
            assert.equal("s2-a3", f.stepId)
            assert.equal("s1", f.from)
            assert.equal(7, f.level)
            assert.equal(f, rec.SYNC_APPLIED[1][1])
            assert.equal(f, E(ns):GetSyncFloor())
            assert.equal(f, E(ns):GetLastSync().record)
            assert.is_nil(E(ns):GetSyncSuggestion())
            assert.is_nil(rec.SYNC_SUGGESTION[#rec.SYNC_SUGGESTION][1], "the suggestion disappeared")
            assert.is_false(E(ns):ApplySync(), "nothing left to sync")
        end)

        it("drops the bg goals before the floor", function()
            -- level 13: s1 and s2 are outleveled; s2's quests are what the jump to s3 skips (in s1 only
            -- 91002 of the log is left: no reason to jump on its own -- tests/spec/core_sync_keep_spec.lua)
            local m, ns = boot(13)
            m:AddQuestToLog(91001)
            H.settle(m)
            assert.equal("s1-t1", H.cur(ns))
            m:TurnInQuest(91001)
            m:AddQuestToLog(91002)
            H.settle(m)
            assert.equal("s1-go", H.cur(ns))
            assert.same({ "s1-bg" }, H.ids(E(ns):GetBackground()))
            assert.is_true(E(ns):ApplySync())
            assert.equal("s3-a6", H.cur(ns))
            assert.same({ "s2-train" }, H.ids(E(ns):GetBackground()), "only the skipped trainer visit stays")
            assert.is_true(done(ns, "s1-bg"))
            assert.is_true(done(ns, "s1-t2"), "below the floor although 91002 is still in the log")
            assert.same({ 91002 }, E(ns):GetDroppedQuests(), "turned in below the floor only")
            -- abandoning it to clean the log: its steps are all below the floor, nothing is given up
            local mark = #m.chat
            m:AbandonQuest(91002)
            H.settle(m, 1)
            assert.is_nil(ns.cdb.gaveUp[91002])
            assert.same({}, H.chat(m, mark + 1))
            assert.equal("s3-a6", H.cur(ns))
        end)

        it("Prev beyond the floor only pins the view; Forward moves it back", function()
            local m, ns = boot(7)
            E(ns):ApplySync()
            E(ns):Prev()
            H.settle(m)
            assert.equal("s1-t2", H.cur(ns))
            assert.is_true(E(ns):IsPinned())
            assert.is_true(done(ns, "s1-t2"), "still done: the floor is not undone by Prev")
            assert.equal("s2-a3", ns.cdb.syncFloor.stepId)
            assert.same({}, ns.cdb.skipped)
            assert.same({}, ns.cdb.manual)
            E(ns):Forward()
            assert.equal("s2-a3", H.cur(ns))
            assert.is_false(E(ns):IsPinned())
            assert.same({}, ns.cdb.skipped, "Forward on a pin marks nothing")
        end)

        it("DismissSync: silent for that segment until the next level-up (kept across /reload)", function()
            local m, ns, rec = boot(7)
            assert.is_true(E(ns):DismissSync())
            assert.is_nil(E(ns):GetSyncSuggestion())
            assert.is_nil(rec.SYNC_SUGGESTION[#rec.SYNC_SUGGESTION][1])
            assert.equal("s1-a1", H.cur(ns))
            assert.same({ route = ROUTE, segment = "s1", level = 7 }, ns.cdb.syncDismissed)
            E(ns):Refresh()
            assert.is_nil(E(ns):GetSyncSuggestion())
            local m2, ns2 = reload(m)
            assert.is_nil(E(ns2):GetSyncSuggestion(), "after /reload")
            m2:SetLevel(8)
            H.settle(m2)
            assert.equal("s2", E(ns2):GetSyncSuggestion().to.id, "back after the level-up")
            assert.is_false(E(ns2):DismissSync() and false)
        end)

        it("UndoSync: the floor and the high-water mark of that moment come back", function()
            local m, ns, rec = boot(7, { listen = { "SYNC_SUGGESTION", "SYNC_UNDONE" } })
            local hint = ns.cdb.cursorHintId
            E(ns):ApplySync()
            assert.equal("s2-a3", ns.cdb.cursorHintId)
            local mark = #m.chat
            assert.is_true(E(ns):UndoSync())
            assert.is_nil(ns.cdb.syncFloor)
            assert.equal(hint, ns.cdb.cursorHintId)
            assert.equal("s1-a1", H.cur(ns))
            assert.is_false(done(ns, "s1-go"), "transient steps are not forwarded by the undone sync")
            assert.is_true(H.chatHas(m, "Level sync undone", mark + 1))
            assert.equal(1, #rec.SYNC_UNDONE)
            assert.is_nil(E(ns):GetSyncSuggestion(), "not suggested again until the next level-up")
            assert.is_nil(E(ns):GetLastSync())
            assert.is_false(E(ns):UndoSync(), "nothing to undo")
        end)

        it("UndoSync restores the previous floor (one level)", function()
            local m, ns = boot(7)
            E(ns):ApplySync()
            m:SetLevel(13)
            H.settle(m)
            assert.equal("s3", E(ns):GetSyncSuggestion().to.id, "s2 is outleveled now")
            E(ns):ApplySync()
            assert.equal("s3-a6", H.cur(ns))
            assert.equal("s2-a3", ns.cdb.syncFloor.prev.stepId)
            E(ns):UndoSync()
            assert.equal("s2-a3", ns.cdb.syncFloor.stepId)
            assert.equal("s2-a3", H.cur(ns))
        end)

        it("auto: applies at login (chat line), Undo is not re-applied before the next level-up", function()
            local m, ns, rec = boot(7, { settings = { levelSync = "auto" }, listen = { "SYNC_SUGGESTION", "SYNC_APPLIED" } })
            assert.equal("s2-a3", H.cur(ns))
            assert.equal("s2-a3", ns.cdb.syncFloor.stepId)
            assert.is_true(H.chatHas(m, "Level sync (automatic): level 7"))
            assert.is_nil(E(ns):GetSyncSuggestion())
            assert.equal(1, #rec.SYNC_APPLIED)
            for _, r in ipairs(rec.SYNC_SUGGESTION) do assert.is_nil(r[1], "auto never shows a suggestion") end
            E(ns):UndoSync()
            H.settle(m)
            assert.equal("s1-a1", H.cur(ns))
            assert.is_nil(ns.cdb.syncFloor)
            m:SetLevel(8)
            H.settle(m)
            assert.equal("s2-a3", H.cur(ns), "applied again after the level-up")
            assert.equal(2, #rec.SYNC_APPLIED)
        end)

        it("switching to auto applies a pending suggestion", function()
            local m, ns = boot(7)
            assert.is_table(E(ns):GetSyncSuggestion())
            setSetting(ns, m, "levelSync", "auto")
            assert.equal("s2-a3", H.cur(ns))
        end)

        it("Reset forgets the floor and the dismissal", function()
            local m, ns = boot(7)
            E(ns):ApplySync()
            E(ns):Reset()
            H.settle(m)
            assert.is_nil(ns.cdb.syncFloor)
            assert.is_nil(ns.cdb.syncDismissed)
            assert.equal("s1-a1", H.cur(ns))
            assert.is_table(E(ns):GetSyncSuggestion())
        end)
    end)

    describe("persistence", function()
        it("the floor survives /reload", function()
            local m, ns = boot(7)
            E(ns):ApplySync()
            local m2, ns2 = reload(m)
            assert.equal("s2-a3", H.cur(ns2))
            assert.equal("s2-a3", E(ns2):GetSyncFloor().stepId)
            assert.is_nil(E(ns2):GetSyncSuggestion())
            assert.is_true(E(ns2):IsDone(1))
            m2:AssertClean()
        end)

        it("a cold start (SavedVariables lost) suggests the same jump again", function()
            local m, ns = boot(7)
            E(ns):ApplySync()
            local _, ns2 = reload(m, { coldStart = true })
            assert.is_nil(ns2.cdb.syncFloor)
            assert.equal("s1-a1", H.cur(ns2))
            local sug = E(ns2):GetSyncSuggestion()
            assert.equal("s2-a3", sug.toStepId)
        end)

        it("a floor of another route or of an unknown step is ignored", function()
            local _, ns = boot(7, { savedVariables = { FastesBoooyCharDB = {
                syncFloor = { route = "other-route", stepId = "s2-a3" } } } })
            assert.is_nil(E(ns):GetSyncFloor())
            assert.equal("s1-a1", H.cur(ns))
            local _, ns2 = boot(7, { savedVariables = { FastesBoooyCharDB = {
                syncFloor = { route = ROUTE, stepId = "gone" } } } })
            assert.is_nil(E(ns2):GetSyncFloor())
            assert.equal("s1-a1", H.cur(ns2))
            local _, ns3 = boot(7, { savedVariables = { FastesBoooyCharDB = { syncFloor = "junk", syncDismissed = 4 } } })
            assert.is_nil(ns3.cdb.syncFloor)
            assert.is_nil(ns3.cdb.syncDismissed)
        end)
    end)
end)

describe("gray quests (settings.skipGray)", function()
    it("skips gray accepts in outgrown segments, keeps prerequisites of good quests", function()
        local _, ns = boot(13, { settings = { levelSync = "off" } })
        -- level 13: green range 5. 91004 (7) gray, no later quest needs it
        assert.equal("gray", why(ns, "s2-a3", "accept", 91004))
        assert.is_true(done(ns, "s2-t4"), "its turn-in: never taken")
        assert.equal("orphan", why(ns, "s2-t4", "turnin", 91004))
        -- 91003 (6) gray, but 91005 (8: not gray at 13) needs it
        assert.is_nil(why(ns, "s2-a3", "accept", 91003))
        assert.is_false(done(ns, "s2-a3"))
        -- 91001 (2) and 91002 (3) gray, kept for 91008 (9, not gray at 13): a chain
        assert.is_nil(why(ns, "s1-a1", "accept", 91001))
        assert.equal("s1-a1", H.cur(ns))
        assert.is_nil(E(ns):GetAcceptQuests()[91004], "a gray accept is not auto-accepted")
    end)

    it("protection follows preAny: an alternative already turned in does not need the quest", function()
        local m, ns = boot(15, { settings = { levelSync = "off" } })
        -- 91005 (8) is gray at 15, 91007 (12) is not and needs 91005 or 91006
        assert.is_nil(why(ns, "s2-a5", "accept", 91005))
        assert.is_nil(why(ns, "s2-a3", "accept", 91003), "transitively protected")
        m.completed[91006] = true
        E(ns):Refresh()
        assert.equal("gray", why(ns, "s2-a5", "accept", 91005))
        assert.equal("gray", why(ns, "s2-a3", "accept", 91003), "nothing needs it any more")
    end)

    it("does not skip gray quests the route takes inside a segment the player has not outgrown", function()
        -- 91008 (9) in s3 (10-15) is gray at 15 (15 - 9 > 5) and nothing needs it: the route takes it
        -- there on purpose while the player is inside 10-15; once past 15 it is skipped
        local _, ns = boot(15, { settings = { levelSync = "off" } })
        assert.is_true(ns.Compat.IsQuestGray(91008, 9, 15))
        assert.is_nil(why(ns, "s3-a8", "accept", 91008))
        -- ... and it still protects its gray prerequisites 91002 <- 91001 in the outgrown s1
        assert.is_nil(why(ns, "s1-a1", "accept", 91001))
        assert.equal("s1-a1", H.cur(ns))
        local _, ns2 = boot(16, { settings = { levelSync = "off" } })
        assert.equal("gray", why(ns2, "s3-a8", "accept", 91008))
        assert.is_true(done(ns2, "s3-t8"))
        assert.equal("gray", why(ns2, "s1-a1", "accept", 91001), "nothing kept needs the chain any more")
    end)

    it("skipGray = false keeps every accept; a quest in the log is never skipped", function()
        local m, ns = boot(13, { settings = { levelSync = "off", skipGray = false } })
        assert.is_nil(why(ns, "s2-a3", "accept", 91004))
        assert.is_false(done(ns, "s2-t4"))
        setSetting(ns, m, "skipGray", true)
        assert.equal("gray", why(ns, "s2-a3", "accept", 91004))
        m:AddQuestToLog(91004)
        H.settle(m)
        assert.is_nil(why(ns, "s2-a3", "accept", 91004))
        assert.is_false(done(ns, "s2-t4"), "taken: its turn-in is needed")
    end)

    -- A quest the player has passed or declined keeps no gray chain alive. The shape of the real
    -- routes: 1424 > 1429 > 1444 (gray at 60) lead to the optional dungeon quest 1445 (level 50, not
    -- gray at 60). A character that finished the route without that chain (a level sync at 48 jumps
    -- over it) and lost its SavedVariables must still see the route as finished.
    describe("protection ends with the quest the chain leads to", function()
        local FIN = "fin-route"
        local FQ = {
            [93001] = { title = "Chain One", level = 2 },
            [93002] = { title = "Chain Two", level = 3, pre = { 93001 } },
            [93003] = { title = "Optional Dungeon", level = 14, pre = { 93002 } },
            [93004] = { title = "The Last One", level = 12 },
        }
        local function registerFin(api)
            api.RegisterRoute({ api = 1, id = FIN, title = { en = "Finished route", ru = "Пройденный маршрут" },
                faction = "Horde", races = { "Scourge" }, classes = { "PALADIN" }, levels = { 1, 10 }, default = true })
            api.AddSegment(FIN, { id = "f1", title = { en = "1-5", ru = "1-5" }, levels = { 1, 5 }, steps = {
                { id = "f-a1", accept = 93001 },
                { id = "f-t1", turnin = 93001, accept = 93002 },
                { id = "f-t2", turnin = 93002 },
            } })
            api.AddSegment(FIN, { id = "f2", title = { en = "5-10", ru = "5-10" }, levels = { 5, 10 }, steps = {
                { id = "f-opt", accept = 93003, optional = true },
                { id = "f-opt-t", turnin = 93003, optional = true },
                { id = "f-a4", accept = 93004 },
                { id = "f-end", turnin = 93004 },
            } })
            local meta = {}
            for id, q in pairs(FQ) do meta[id] = { level = q.level, reqLevel = 1, preAll = q.pre } end
            api.AddRouteData(FIN, { questMeta = meta })
        end
        local function bootFin(opts)
            opts = opts or {}
            local m, ns = H.new({ fixture = false, quests = false, register = registerFin,
                setup = function(m)
                    for id, q in pairs(FQ) do m:DefineQuest(id, q) end
                    for _, q in ipairs(opts.completed or {}) do m.completed[q] = true end
                end,
                player = { level = 15 },
                savedVariables = { FastesBoooyDB = { settings = { levelSync = opts.levelSync or "off" } } } })
            Mock.boot(m, { "FastesBoooy" })
            H.settle(m)
            return m, ns
        end

        it("a finished route is finished on a cold start: the passed optional quest protects nothing", function()
            -- level 15: 93001 (2) and 93002 (3) are gray, 93003 (14) is not; the last step is done, so
            -- the optional accept of 93003 lies behind the forward limit ("not taken")
            for _, mode in ipairs({ "off", "ask", "auto" }) do
                local m, ns = bootFin({ completed = { 93004 }, levelSync = mode })
                assert.is_false(ns.Compat.IsQuestGray(93003, 14, 15))
                assert.equal(idx(ns, "f-end"), E(ns).anchor, mode)
                assert.equal("gray", why(ns, "f-a1", "accept", 93001), mode)
                assert.equal("orphan", why(ns, "f-t1", "turnin", 93001), mode)
                assert.equal("gray", why(ns, "f-t1", "accept", 93002), mode)
                assert.equal("orphan", why(ns, "f-t2", "turnin", 93002), mode)
                assert.equal("<end>", H.cur(ns), mode .. ": the route is finished")
                assert.is_nil(E(ns):GetNaturalCursor(), mode)
                assert.is_nil(E(ns):GetSyncSuggestion(), mode)
                assert.is_nil(E(ns):GetAcceptQuests()[93001], mode)
                m:AssertClean()
            end
        end)

        it("the chain stays while the route still leads to the quest", function()
            -- nothing done: the optional accept is ahead of the forward limit and may still be taken
            local m, ns = bootFin()
            assert.is_true(E(ns).forwardLimit < idx(ns, "f-opt"))
            assert.is_nil(why(ns, "f-a1", "accept", 93001))
            assert.equal("f-a1", H.cur(ns))
            -- the player declines the optional quest (Skip on its accept step): nothing needs the chain
            ns.cdb.skipped["f-opt"] = true
            E(ns):Refresh()
            assert.equal("gray", why(ns, "f-a1", "accept", 93001))
            assert.equal("gray", why(ns, "f-t1", "accept", 93002))
            assert.equal("f-a4", H.cur(ns))
            -- (the high-water mark is now behind the optional step: taking the mark away does not
            -- bring the chain back, the step stays passed)
            ns.cdb.skipped["f-opt"] = nil
            E(ns):Refresh()
            assert.equal("gray", why(ns, "f-a1", "accept", 93001))
            assert.equal("f-a4", H.cur(ns))
            -- Reset forgets the mark and the high-water mark: the chain is back
            E(ns):Reset()
            H.settle(m)
            assert.is_nil(why(ns, "f-a1", "accept", 93001))
            assert.equal("f-a1", H.cur(ns))
            m:AssertClean()
        end)

        it("a quest of the chain in the log, or the optional quest itself, is never skipped", function()
            local m, ns = bootFin({ completed = { 93004 } })
            assert.equal("<end>", H.cur(ns))
            -- the player takes the first quest of the chain by hand: its turn-in is wanted again, the
            -- next accept stays gray (nothing kept needs it)
            m:AddQuestToLog(93001)
            H.settle(m)
            assert.is_nil(why(ns, "f-a1", "accept", 93001))
            assert.is_nil(why(ns, "f-t1", "turnin", 93001))
            assert.equal("gray", why(ns, "f-t1", "accept", 93002))
            assert.equal("f-t1", H.cur(ns))
            m:AssertClean()
        end)
    end)

    it("Compat.IsQuestGray: the client's IsQuestTrivial when cached, else the rule with the route level", function()
        local m, ns = boot(10)
        local C = ns.Compat
        m:DefineQuest(92001, { title = "Cached", level = 4 })
        m:DefineQuest(92002, { title = "Uncached", level = 4, uncached = true })
        assert.is_true(C.IsQuestGray(92001, nil, 10), "cached: C_QuestLog.IsQuestTrivial")
        assert.is_false(C.IsQuestGray(92002, nil, 10), "uncached, no level: not gray")
        assert.is_true(C.IsQuestGray(92002, 4, 10), "uncached: 10 - 4 > 5")
        assert.is_false(C.IsQuestGray(92002, 5, 10), "10 - 5 = 5: green")
        assert.is_false(C.IsQuestGray(92002, -1, 60), "scaling quest")
        assert.equal(5, C.TrivialRange(10), "C_QuestLog.GetTrivialRange")
        local ranges = { [1] = 0, [5] = 4, [6] = 4, [10] = 5, [23] = 6, [39] = 7, [40] = 8, [48] = 9, [59] = 11, [60] = 11 }
        for level, r in pairs(ranges) do assert.equal(r, C.FallbackTrivialRange(level), "level " .. level) end
        m:AssertClean()
    end)
end)

describe("never-taken and unreachable quests", function()
    it("Skip on an accept step no longer leaves its turn-in (and its chain) blocking", function()
        local m, ns = boot(1, { settings = { levelSync = "off" } })
        assert.equal("s1-a1", H.cur(ns))
        E(ns):Skip()
        H.settle(m)
        -- s1-t1: turn-in of the never-taken 91001 + accept of 91002, which needs it
        assert.equal("orphan", why(ns, "s1-t1", "turnin", 91001))
        assert.equal("unreachable", why(ns, "s1-t1", "accept", 91002))
        assert.equal("s1-go", H.cur(ns))
        assert.is_true(done(ns, "s1-c2"))
        assert.is_true(done(ns, "s1-t2"))
        assert.is_true(done(ns, "s1-bg"))
        -- the chain goes on in s3: 91008 needs 91002
        assert.equal("unreachable", why(ns, "s3-a8", "accept", 91008))
        assert.is_true(done(ns, "s3-t8"))
        -- taken by hand after all: its steps are needed again
        m:AddQuestToLog(91001)
        H.settle(m)
        assert.equal("s1-t1", H.cur(ns))
        assert.is_nil(why(ns, "s3-a8", "accept", 91008))
    end)

    it("preAny: unreachable only when every alternative is dead", function()
        local m, ns = boot(1, { settings = { levelSync = "off" } })
        ns.cdb.skipped["s3-a6"] = true
        E(ns):Refresh()
        assert.is_nil(why(ns, "s3-a7", "accept", 91007), "91005 can still be taken")
        ns.cdb.skipped["s2-a5"] = true
        E(ns):Refresh()
        assert.equal("unreachable", why(ns, "s3-a7", "accept", 91007))
        assert.is_true(done(ns, "s3-t7"))
        m.completed[91005] = true
        E(ns):Refresh()
        assert.is_nil(why(ns, "s3-a7", "accept", 91007), "an alternative turned in")
    end)

    it("prerequisites below the sync floor that were never taken make later quests unreachable", function()
        local _, ns = boot(7)
        E(ns):ApplySync()
        assert.equal("unreachable", why(ns, "s3-a8", "accept", 91008), "91002 was below the floor")
        assert.is_nil(why(ns, "s2-a5", "accept", 91005), "91003 is ahead of the floor")
    end)

    it("without questMeta (older route data) only the never-taken rule applies", function()
        local m, ns = boot(1, { settings = { levelSync = "off" }, meta = false })
        E(ns):Skip()
        H.settle(m)
        assert.equal("orphan", why(ns, "s1-t1", "turnin", 91001))
        assert.is_nil(why(ns, "s1-t1", "accept", 91002), "prerequisites unknown: assumed met")
        assert.equal("s1-t1", H.cur(ns))
        m:AssertClean()
    end)
end)

describe("Forward() and GetUpcoming()", function()
    it("Forward skips the displayed step; on a pin it only moves the view", function()
        local m, ns = boot(1, { settings = { levelSync = "off" } })
        m:AddQuestToLog(91001)
        H.settle(m)
        assert.equal("s1-t1", H.cur(ns))
        E(ns):Forward()
        H.settle(m)
        assert.is_true(ns.cdb.skipped["s1-t1"])
        assert.equal("s1-go", H.cur(ns))
        E(ns):Prev() -- un-marks s1-t1 (undo) and shows it
        H.settle(m)
        assert.equal("s1-t1", H.cur(ns))
        E(ns):Prev()
        H.settle(m)
        assert.equal("s1-a1", H.cur(ns))
        assert.is_true(E(ns):IsPinned())
        E(ns):Forward()
        H.settle(m)
        assert.equal("s1-t1", H.cur(ns))
        assert.is_false(E(ns):IsPinned(), "the pin reached the natural cursor")
        assert.same({}, ns.cdb.skipped)
    end)

    it("GetUpcoming lists only steps that are not done", function()
        local m, ns = boot(1, { settings = { levelSync = "off" } })
        E(ns):Skip()
        H.settle(m)
        local up = H.ids(E(ns):GetUpcoming(20))
        assert.same({ "s2-a3", "s2-train", "s2-t3", "s2-a5", "s2-t4", "s2-t5", "s3-a6", "s3-a7", "s3-t6", "s3-t7",
            "s4-a9", "s4-t9" }, up)
        for _, s in ipairs(E(ns):GetUpcoming(20)) do assert.is_false(E(ns):IsDone(s)) end
        m.completed[91006] = true -- done out of order in the game: s3-a6 becomes the forward anchor
        E(ns):Refresh()
        assert.equal("s2-a3", H.cur(ns), "s1-go forwarded")
        up = H.ids(E(ns):GetUpcoming(3))
        assert.same({ "s2-t3", "s2-a5", "s2-t4" }, up, "s2-train forwarded too")
        assert.is_falsy(table.concat(H.ids(E(ns):GetUpcoming(20)), ","):find("s3-a6", 1, true))
    end)
end)

describe("route data questMeta", function()
    local function run(cmd)
        local p = assert(io.popen(cmd .. " 2>&1; echo \"EXIT=$?\""))
        local out = p:read("*a")
        p:close()
        return tonumber(out:match("EXIT=(%d+)%s*$")), out
    end

    it("gen_route_data writes level / reqLevel / preAll / preAny / items from the DB snapshot", function()
        local code, out = run("lua5.1 tools/gen_route_data.lua --no-overrides --stdout " .. H.LIB_DIR)
        assert.equal(0, code, out)
        local chunk = assert(loadstring(out))
        local captured
        setfenv(chunk, { FastesBoooy = { AddLibraryData = function(d) captured = d end } })
        chunk()
        assert.same({ level = 1, reqLevel = 1 }, captured.questMeta[363])
        assert.same({ level = 4, reqLevel = 2, preAny = { 376 } }, captured.questMeta[380])
        assert.same({ level = 3, reqLevel = 1, preAny = { 364 } }, captured.questMeta[3901])
        local Gen = require("gen_route_data")
        assert.equal("[1] = { level = 5, reqLevel = 3, preAll = { 7, 9 }, preAny = { 2 } }",
            Gen.RenderQuestMeta({ id = 1, level = 5, reqLevel = 3, preAll = { 7, 9 }, preAny = { 2 } }))
        assert.equal("[2] = { level = 5, items = { 8391, 8392 } }",
            Gen.RenderQuestMeta({ id = 2, level = 5, items = { 8391, 8392 } }))
        -- the objective items of the DB record (objectives.items)
        local meta = Gen.QuestMeta({ quests = { [2581] = true } }, H.db())
        assert.same({ 8391, 8392, 8393 }, meta[1].items)
    end)

    it("a composed route gets the library questMeta under its own data", function()
        local _, ns = H.boot({ composed = true })
        local meta = ns.Engine:GetRoute().data.questMeta
        assert.same({ level = 4, reqLevel = 2, preAny = { 376 } }, meta[380])
        assert.equal(meta, ns.Engine.questMeta)
        assert.same({ 380, 3902 }, ns.Engine.dependents[376])
    end)
end)

describe("settings", function()
    it("defaults and load-time migration", function()
        local m, ns = H.new({ savedVariables = { FastesBoooyDB = { settings = {
            levelSync = "maybe", levelSyncMargin = 7.6, skipGray = "yes" } } } })
        assert.equal("ask", ns.DEFAULTS.db.settings.levelSync)
        assert.equal(2, ns.DEFAULTS.db.settings.levelSyncMargin)
        assert.is_true(ns.DEFAULTS.db.settings.skipGray)
        Mock.boot(m, { "FastesBoooy", H.FIXTURE_NAME })
        local s = ns.db.settings
        assert.equal("ask", s.levelSync)
        assert.equal(5, s.levelSyncMargin)
        assert.is_true(s.skipGray)
        assert.equal(3, ns.ClampSetting("levelSyncMargin", 2.6))
        assert.equal(0, ns.ClampSetting("levelSyncMargin", -1))
        assert.equal("auto", ns.ValidChoice("levelSync", "auto"))
        assert.same({ "ask", "auto", "off" }, ns.SETTING_CHOICES.levelSync)
    end)
end)

describe("the guides module", function()
    local MODULES = { { "addons/FastesBoooy_Guides/FastesBoooy_Guides.toc", "FastesBoooy_Guides" } }

    -- 0.4.0 renamed the two routes of 0.3 (three modules -> FastesBoooy_Guides). Their former ids are `aliases`
    -- in Route.lua; without them a character silently loses the manual route choice, the high-water mark and
    -- the level-sync floor, and no tool notices.
    it("keeps the former route ids as aliases: progress saved by 0.3 is adopted", function()
        local FLOOR = "h-27-ashenvale-needles-level-gate" -- a step of the shared path, in both routes
        local function bootSaved(old)
            return H.boot({ fixture = false, db = true, modules = MODULES, player = { level = 30 },
                savedVariables = { FastesBoooyCharDB = {
                    route = old, cursorHint = 1, cursorHintId = FLOOR, cursorHintRoute = old,
                    syncFloor = { route = old, stepId = FLOOR, from = "h-27-ashenvale-needles",
                        to = "h-27-ashenvale-needles", level = 30, hint = { 1, FLOOR, old } },
                    syncDismissed = { route = old, segment = "h-27-ashenvale-needles", level = 30 },
                } } })
        end
        -- the second case is a manual choice of a route for another race and class: without the alias the
        -- automatic selection would give this Undead paladin "undead-paladin"
        for _, case in ipairs({
            { old = "horde-undead-paladin", id = "undead-paladin" },
            { old = "horde-skyborne-druid", id = "skyborne-druid" },
        }) do
            local m, ns = bootSaved(case.old)
            local R, e, cdb = ns.Registry, E(ns), m.env.FastesBoooyCharDB
            assert.same({}, R.errors)
            assert.equal("undead-paladin", (R:Get("horde-undead-paladin") or {}).id, "alias lost in Route.lua")
            assert.equal("skyborne-druid", (R:Get("horde-skyborne-druid") or {}).id, "alias lost in Route.lua")
            assert.is_nil(R.routes["horde-undead-paladin"])
            assert.is_nil(R.routes["horde-skyborne-druid"])
            assert.equal(case.id, e:GetRoute().id, case.old)
            assert.equal(case.id, cdb.route, case.old)
            assert.equal(case.id, cdb.cursorHintRoute, case.old)
            assert.equal(case.id, cdb.syncFloor.route, case.old)
            assert.equal(case.id, cdb.syncFloor.hint[3], case.old)
            assert.equal(case.id, cdb.syncDismissed.route, case.old)
            assert.equal(cdb.syncFloor, e:GetSyncFloor(), "the saved floor is the active route's again")
            assert.is_true(e:FloorIndex() > 100, "the floor step is deep in the route")
            m:AssertClean()
        end
    end)
end)

describe("performance", function()
    it("a refresh of a 1700-step route with the void pass stays cheap", function()
        local m, ns = H.new({ fixture = false, db = true, player = { level = 23 }, modules = {
            { "addons/FastesBoooy_Guides/FastesBoooy_Guides.toc", "FastesBoooy_Guides" } } })
        Mock.boot(m, { "FastesBoooy", "FastesBoooy_Guides" })
        H.settle(m)
        local e = E(ns)
        assert.equal("undead-paladin", e:GetRoute().id)
        assert.is_true(#e:GetSteps() > 1500)
        assert.equal("ud-01-deathknell", e:GetSyncSuggestion().from.id)
        e:ApplySync()
        local n = 20
        local t0 = os.clock()
        for _ = 1, n do e:Refresh() end
        local ms = (os.clock() - t0) / n * 1000
        assert.is_true(ms < 60, ("Refresh %.1f ms"):format(ms))
        m:AssertClean()
    end)
end)
