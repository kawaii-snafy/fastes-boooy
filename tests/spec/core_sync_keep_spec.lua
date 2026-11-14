-- luacheck: std lua51+busted
-- Level sync with a quest log (Core/Engine.lua): what a jump keeps as along-the-way goals below the
-- floor, when a jump is worth suggesting, the hints of fly / hearth steps after a jump, collect
-- actions of quests the player never took, and UndoSync of another route's floor.
--
-- The route "keep-route" (registered through the public API) has three segments:
--   k1 1-5    k1-a1 accept 93001 (turned in in k2) + 93002 (turned in in k1), fp / sethearth Brill,
--             k1-col collect 93901 x3 (the objective item of 93001, questMeta items), k1-c1 complete
--             93001, k1-c2 complete 93002 + collect 93902 x2 (no questMeta items: same-step rule),
--             k1-a3 / k1-t3 a k1-only quest 93003, k1-train, k1-t2 turnin 93002
--   k2 5-10   go, k2-t1 turnin 93001, k2-fly fly Brill, k2-hearth hearth Brill, 93004
--   k3 10-15  k3-train, 93005

local H = require("fixtures.core.helpers")
local Mock = H.Mock

local ROUTE = "keep-route"
local BRILL = { 1420, 61, 52 }

local QUESTS = {
    [93001] = { title = "Straddling Quest", level = 3,
        objectives = { { text = "Snout collected", required = 3, type = "item", itemID = 93901 } } },
    [93002] = { title = "Local Quest", level = 3,
        objectives = { { text = "Boar slain", required = 2, type = "monster" } } },
    [93003] = { title = "New In K1", level = 4 },
    [93004] = { title = "K2 Quest", level = 7 },
    [93005] = { title = "K3 Quest", level = 12 },
}

local function defineQuests(m)
    for id, q in pairs(QUESTS) do m:DefineQuest(id, q) end
    m:DefineItem(93901, { name = "Boar Snout" })
    m:DefineItem(93902, { name = "Boar Tusk" })
end

local function register(api)
    api.RegisterRoute({ api = 1, id = ROUTE, title = { en = "Keep route", ru = "Маршрут с журналом" },
        faction = "Horde", races = { "Scourge" }, classes = { "PALADIN" }, levels = { 1, 15 }, default = true })
    api.AddSegment(ROUTE, { id = "k1", title = { en = "1-5 First", ru = "1-5 Первый" }, levels = { 1, 5 },
        steps = {
            { id = "k1-a1", accept = { 93001, 93002 } },
            { id = "k1-fp", fp = "Brill", at = BRILL },
            { id = "k1-bind", sethearth = "Brill", at = BRILL },
            { id = "k1-col", collect = { [93901] = 3 } },
            { id = "k1-c1", complete = { 93001, 93002 } },
            { id = "k1-c2", complete = 93002, collect = { [93902] = 2 } },
            { id = "k1-a3", accept = 93003 },
            { id = "k1-t3", turnin = 93003 },
            { id = "k1-train", train = true },
            { id = "k1-t2", turnin = 93002 },
        } })
    api.AddSegment(ROUTE, { id = "k2", title = { en = "5-10 Second", ru = "5-10 Второй" }, levels = { 5, 10 },
        steps = {
            { id = "k2-go", go = true, at = { 1420, 40, 40 } },
            { id = "k2-t1", turnin = 93001 },
            { id = "k2-fly", fly = "Brill", at = BRILL },
            { id = "k2-hearth", hearth = "Brill", at = BRILL },
            { id = "k2-a4", accept = 93004 },
            { id = "k2-t4", turnin = 93004 },
        } })
    api.AddSegment(ROUTE, { id = "k3", title = { en = "10-15 Third", ru = "10-15 Третий" }, levels = { 10, 15 },
        steps = {
            { id = "k3-train", train = true },
            { id = "k3-a5", accept = 93005 },
            { id = "k3-t5", turnin = 93005 },
        } })
    api.AddRouteData(ROUTE, { questMeta = {
        [93001] = { level = 3, reqLevel = 1, items = { 93901 } },
        [93002] = { level = 3, reqLevel = 1 },
        [93003] = { level = 4, reqLevel = 1 },
        [93004] = { level = 7, reqLevel = 1 },
        [93005] = { level = 12, reqLevel = 1 },
    } })
end

local function boot(level, opts)
    opts = opts or {}
    local m, ns = H.new({ fixture = false, quests = false, setup = defineQuests, register = register,
        player = { level = level }, savedVariables = opts.savedVariables })
    Mock.boot(m, { "AdventureAtlas" })
    H.settle(m)
    return m, ns
end

local function reload(m)
    return H.reload(m, { fixture = false, register = register })
end

local function E(ns) return ns.Engine end
local function idx(ns, id) return assert(E(ns):IndexOf(id), id) end
local function done(ns, id) return E(ns):IsDone(idx(ns, id)) end
local function bgIds(ns) return H.ids(E(ns):GetBackground()) end

-- both k1 quests taken, cursor on k1-fp; then the player is level `level`
local function takeBoth(level)
    local m, ns = boot(1)
    m:AddQuestToLog(93001)
    m:AddQuestToLog(93002)
    H.settle(m)
    assert.equal("k1-fp", H.cur(ns))
    m:SetLevel(level)
    H.settle(m)
    return m, ns
end

-- the Describe lines of a step that are hints (Engine:FlightPathPending / HearthBindMismatch)
local function hints(ns, id)
    local out = {}
    for _, l in ipairs(ns.Steps:Describe(E(ns):GetSteps()[idx(ns, id)])) do
        if l.hint then out[#out + 1] = l.text end
    end
    return out
end

describe("level sync with quests in the log", function()
    it("keeps the completion of a quest the route turns in after the floor (finding: stuck turn-in)", function()
        local m, ns = takeBoth(7)
        local sug = E(ns):GetSyncSuggestion()
        assert.equal("k2", sug.to.id)
        assert.equal("k2-go", sug.toStepId)
        local mark = #m.chat
        assert.is_true(E(ns):ApplySync())
        assert.equal("k2-go", H.cur(ns))
        -- 93001: in the log, turned in at k2-t1 (after the floor): its collect + complete stay along the way
        local bg = bgIds(ns)
        assert.is_truthy(table.concat(bg, ","):find("k1-col,k1-c1", 1, true), table.concat(bg, ","))
        assert.is_false(done(ns, "k1-col"))
        assert.is_false(done(ns, "k1-c1"))
        -- 93002: turned in at k1-t2 (below the floor): dropped, named in chat
        assert.is_true(done(ns, "k1-c2"))
        assert.is_true(done(ns, "k1-t2"))
        assert.same({ 93002 }, E(ns):GetDroppedQuests())
        assert.is_true(H.chatHas(m, "1 quest(s) of the skipped part stay in your log (Local Quest)", mark + 1),
            table.concat(H.chat(m, mark + 1), " | "))
        -- finishing it on the way: the goals leave the list, the turn-in after the floor works
        m:CompleteObjectives(93001)
        H.settle(m)
        assert.is_true(done(ns, "k1-c1"))
        assert.is_falsy(table.concat(bgIds(ns), ","):find("k1-c1", 1, true))
        m:MoveTo(1420, 40, 40)
        H.settle(m)
        assert.equal("k2-t1", H.cur(ns))
        m:TurnInQuest(93001)
        H.settle(m)
        assert.equal("k2-fly", H.cur(ns))
        m:AssertClean()
    end)

    it("keeps the turn-in of a complete quest whose turn-in lies below the floor", function()
        local m, ns = takeBoth(7)
        m:CompleteObjectives(93002)
        H.settle(m)
        assert.is_true(E(ns):ApplySync())
        assert.is_false(done(ns, "k1-t2"))
        assert.is_truthy(table.concat(bgIds(ns), ","):find("k1-t2", 1, true))
        assert.same({}, E(ns):GetDroppedQuests())
        m:TurnInQuest(93002)
        H.settle(m)
        assert.is_true(done(ns, "k1-t2"))
        assert.is_falsy(table.concat(bgIds(ns), ","):find("k1-t2", 1, true))
    end)

    it("an abandoned kept quest leaves the list (its later turn-in: never taken any more)", function()
        local m, ns = takeBoth(7)
        E(ns):ApplySync()
        m:AbandonQuest(93001)
        H.settle(m, 1)
        assert.is_falsy(table.concat(bgIds(ns), ","):find("k1-c", 1, true))
        assert.is_true(done(ns, "k1-c1"))
    end)

    it("keeps the last skipped trainer visit until it is done, also across /reload", function()
        local m, ns = takeBoth(7)
        E(ns):ApplySync()
        local keep = {}
        for _, e in ipairs(ns.cdb.syncFloor.keep) do keep[#keep + 1] = e.type .. "@" .. e.id end
        assert.same({ "fp@k1-fp", "sethearth@k1-bind", "train@k1-train" }, keep)
        assert.is_truthy(table.concat(bgIds(ns), ","):find("k1-train", 1, true))
        local m2, ns2 = reload(m)
        assert.is_truthy(table.concat(bgIds(ns2), ","):find("k1-train", 1, true), "kept after /reload")
        m2:OpenTrainer({}, nil)
        m2:CloseTrainer()
        H.settle(m2)
        assert.is_falsy(table.concat(bgIds(ns2), ","):find("k1-train", 1, true))
        for _, e in ipairs(ns2.cdb.syncFloor.keep) do assert.not_equal("train", e.type) end
        local _, ns3 = reload(m2)
        assert.is_falsy(table.concat(bgIds(ns3), ","):find("k1-train", 1, true), "done: not back after /reload")
    end)

    it("a kept trainer visit is moot once the route's next trainer visit is reached", function()
        local m, ns = takeBoth(7)
        E(ns):ApplySync()
        E(ns):SetCursor(idx(ns, "k3-train"))
        H.settle(m)
        assert.equal("k3-train", H.cur(ns))
        assert.is_falsy(table.concat(bgIds(ns), ","):find("k1-train", 1, true))
        for _, e in ipairs(ns.cdb.syncFloor.keep) do assert.not_equal("train", e.type) end
    end)

    it("fly / hearth steps after the jump say that the flight path / bind point was skipped", function()
        local m, ns = takeBoth(7)
        assert.same({}, hints(ns, "k2-fly"), "no hint without a sync")
        assert.same({}, hints(ns, "k2-hearth"))
        E(ns):ApplySync()
        assert.is_true(E(ns):FlightPathPending("Brill"))
        assert.equal(1, #hints(ns, "k2-fly"))
        assert.is_truthy(hints(ns, "k2-fly")[1]:find("skipped by the level sync", 1, true))
        local h = hints(ns, "k2-hearth")
        assert.equal(1, #h)
        assert.is_truthy(h[1]:find("Your hearthstone is set to Deathknell, not Brill", 1, true), h[1])
        -- a taxi map / bind somewhere else does not count for these kept visits (several kept visits can
        -- be along the way at once: each only at its own place)
        m:OpenTaxi({ { name = "Deathknell", state = "CURRENT" } })
        m:CloseTaxi()
        m:SetBindLocation("Gallows' End", 1420, 60, 52)
        H.settle(m)
        assert.is_true(E(ns):FlightPathPending("Brill"))
        assert.is_truthy(table.concat(bgIds(ns), ","):find("k1-fp,k1-bind", 1, true))
        -- the kept visits done along the way, at Brill: no more hints
        m:MoveTo(1420, 61, 52)
        H.settle(m)
        m:OpenTaxi({ { name = "Brill", state = "CURRENT" } })
        m:CloseTaxi()
        m:SetBindLocation("Brill", 1420, 61, 52)
        H.settle(m)
        assert.is_false(E(ns):FlightPathPending("Brill"))
        assert.same({}, hints(ns, "k2-fly"))
        assert.same({}, hints(ns, "k2-hearth"))
        assert.is_falsy(table.concat(bgIds(ns), ","):find("k1-fp", 1, true))
        assert.is_falsy(table.concat(bgIds(ns), ","):find("k1-bind", 1, true))
        m:AssertClean()
    end)

    it("a kept step marks its other actions void (\"floor\"): the along-the-way list hides them", function()
        local _, ns = takeBoth(7)
        E(ns):ApplySync()
        local lines = ns.Steps:Describe(E(ns):GetSteps()[idx(ns, "k1-c1")])
        local kept, floored = {}, {}
        for _, l in ipairs(lines) do
            if l.kind == "complete" then
                if l.void == "floor" then floored[#floored + 1] = l.questID else kept[#kept + 1] = l.questID end
            end
        end
        assert.same({ 93001 }, kept)
        assert.same({ 93002 }, floored, "93002 is dropped: its completion is floored")
        assert.is_false(done(ns, "k1-c1"))
    end)
end)

describe("the step window after a jump with quests in the log", function()
    it("lists the kept goals along the way without their floored actions", function()
        local m, ns = takeBoth(7)
        E(ns):ApplySync()
        m:Advance(0)
        local shown = table.concat(m:VisibleTexts(ns.UI.StepFrame:GetFrame()), " | ")
        assert.is_truthy(shown:find("Complete: Straddling Quest", 1, true), shown)
        assert.is_truthy(shown:find("Visit your class trainer", 1, true), shown)
        assert.is_truthy(shown:find("Get the flight path: Brill", 1, true), shown)
        assert.is_falsy(shown:find("Local Quest", 1, true), "dropped: not shown: " .. shown)
        m:AssertClean()
    end)
end)

describe("when a jump is worth suggesting", function()
    it("not while the rest of the segment is quests of the log, a trainer visit and turn-ins", function()
        local m, ns = boot(1)
        m:AddQuestToLog(93001)
        m:AddQuestToLog(93002)
        m:AddQuestToLog(93003)
        H.settle(m)
        m:SetLevel(7)
        H.settle(m)
        assert.is_nil(E(ns):GetSyncSuggestion(), "93003 is taken: nothing new to skip in k1")
        assert.is_false(E(ns):ApplySync(), "an explicit sync does not jump over nothing either")
        assert.is_nil(ns.cdb.syncFloor)
        m:AbandonQuest(93003)
        m:SetLevel(8)
        H.settle(m, 1)
        assert.is_table(E(ns):GetSyncSuggestion(), "93003 can be taken again: k1 has new content")
    end)

    it("auto mode does not jump at the end of a segment it is ahead of", function()
        local m, ns = boot(1, { savedVariables = { AdventureAtlasDB = { settings = { levelSync = "auto" } } } })
        m:AddQuestToLog(93001)
        m:AddQuestToLog(93002)
        m:AddQuestToLog(93003)
        H.settle(m)
        m:SetLevel(9)
        H.settle(m)
        assert.is_nil(ns.cdb.syncFloor)
        assert.equal("k1", E(ns):GetCurrentStep().segment, "still in k1 (93003 taken early: k1-a3 anchors)")
    end)
end)

describe("collect actions of quests the player never took", function()
    it("are void with the objective items of questMeta, or the step's quests", function()
        local m, ns = boot(1, { savedVariables = { AdventureAtlasDB = { settings = { levelSync = "off" } } } })
        assert.equal("k1-a1", H.cur(ns))
        E(ns):Forward() -- skip the accept step: neither quest is taken
        H.settle(m)
        local function voidOf(id, item)
            for _, a in ipairs(E(ns):GetSteps()[idx(ns, id)].actions) do
                if a.type == "collect" and a.item == item then return E(ns):VoidReason(a) end
            end
        end
        assert.equal("orphan", voidOf("k1-col", 93901), "93901 is the objective item of 93001 (questMeta)")
        assert.equal("orphan", voidOf("k1-c2", 93902), "same step as the never-taken 93002")
        assert.is_true(done(ns, "k1-col"))
        assert.is_true(done(ns, "k1-c2"))
        assert.equal("k1-fp", H.cur(ns))
        -- taken by hand after all: the items are needed again
        m:AddQuestToLog(93001)
        H.settle(m)
        assert.is_nil(voidOf("k1-col", 93901))
        assert.is_false(done(ns, "k1-col"))
    end)
end)

describe("UndoSync", function()
    it("refuses the floor of another route", function()
        local floorRec = { route = "other-route", stepId = "k2-go" }
        local _, ns = boot(1, { savedVariables = { AdventureAtlasCharDB = { syncFloor = floorRec } } })
        assert.is_false(E(ns):UndoSync())
        assert.equal("other-route", ns.cdb.syncFloor.route, "kept for its route")
    end)
end)
