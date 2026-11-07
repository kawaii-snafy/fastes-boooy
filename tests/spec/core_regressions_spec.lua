-- Regression tests for review findings on the core addon (ad-hoc routes on the strict
-- mock): background goals, one window = one transient step, item data that never
-- loads, Shift per dialog, Blizzard waypoint on maps without user waypoints, route
-- format version, invalid reward choices.

local H = require("fixtures.core.helpers")
local Mock = H.Mock

local m, ns

local function E() return ns.Engine end

-- boot the core with one ad-hoc route (Scourge paladin, Horde)
local function boot(steps, opts)
    opts = opts or {}
    m, ns = H.new({ fixture = false, setup = opts.setup, savedVariables = opts.savedVariables })
    local FB = m.env.FastesBoooy
    FB.RegisterRoute({ api = 1, id = "rg", title = "Regression", faction = "Horde",
        races = { "Scourge" }, classes = { "PALADIN" }, levels = { 1, 10 }, default = true })
    if opts.segments then
        for _, seg in ipairs(opts.segments) do FB.AddSegment("rg", seg) end
    else
        FB.AddSegment("rg", { id = "s", title = "S", steps = steps })
    end
    Mock.boot(m, { "FastesBoooy" })
    for k, v in pairs(opts.settings or {}) do ns.db.settings[k] = v end
    H.settle(m)
    return m, ns
end

local function accepted(mark, q)
    for _, a in ipairs(H.actionsSince(m, mark, "AcceptQuest")) do
        if a[2] == q then return true end
    end
    return false
end

describe("regressions", function()
    after_each(function()
        if m then m:AssertClean() end
        m, ns = nil, nil
    end)

    describe("forward anchors", function()
        local function steps()
            return {
                { id = "a363", accept = 363 },
                { id = "sh", sethearth = "Brill", npc = 5688 },
                { id = "tr", train = true, npc = 244808 },
                { id = "lv", level = 3 },
                { id = "a364", accept = 364 },
                { id = "lva", level = 4, accept = 3901 },
                { id = "m1", manual = true },
            }
        end

        it("a level reached early (rested XP) does not forward earlier transient steps", function()
            boot(steps())
            m:AddQuestToLog(363)
            H.settle(m)
            assert.equal("sh", H.cur(ns))
            m:SetLevel(3)
            H.settle(m)
            assert.equal(3, m.player.level)
            assert.is_true(E():IsDone("lv"), "the level step itself is done")
            assert.equal(1, E().anchor, "a lone level step is no anchor")
            assert.equal("sh", H.cur(ns), "sethearth not skipped")
            assert.is_false(E():IsDone("tr"), "train not skipped")
            m:SetLevel(5)
            H.settle(m)
            assert.equal("sh", H.cur(ns))
            -- a later accept is evidence: everything transient before it is forwarded
            m:AddQuestToLog(364)
            H.settle(m)
            assert.equal(5, E().anchor)
            assert.is_true(E():IsDone("sh"))
            assert.is_true(E():IsDone("tr"))
            assert.equal("lva", H.cur(ns))
        end)

        it("a level next to an accept anchors only when both are done", function()
            boot(steps())
            m:AddQuestToLog(363)
            m:AddQuestToLog(3901)
            H.settle(m)
            assert.equal(1, E().anchor, "level 4 not reached: the accept alone does not anchor that step")
            assert.equal("sh", H.cur(ns))
            m:SetLevel(4)
            H.settle(m)
            assert.equal(6, E().anchor)
            assert.is_true(E():IsDone("sh"))
            assert.is_true(E():IsDone("tr"))
            -- stateful actions are always re-derived from the game: 364 was never accepted
            assert.equal("a364", H.cur(ns))
        end)
    end)

    describe("place names", function()
        it("uses the client's localized area name of the generated `places` area id", function()
            m, ns = H.new({ fixture = false, locale = "ruRU",
                mock = { areaNames = { [159] = "Брилл" }, bind = { name = "Брилл" } } })
            local FB = m.env.FastesBoooy
            FB.RegisterRoute({ api = 1, id = "rg", title = "Regression", faction = "Horde", default = true })
            FB.AddSegment("rg", { id = "s", title = "S", steps = {
                { id = "go", go = true, at = { 1420, 60.5, 52.6 } },
                { id = "sh", sethearth = "Brill", npc = 5688 },
                { id = "fp", fp = "Undercity" },
            } })
            -- what tools/gen_route_data.lua writes (no ruRU text for Brill here: the client name wins)
            FB.AddRouteData("rg", { places = { ["Brill"] = { area = 159, en = "Brill" },
                ["Undercity"] = { area = 1497, en = "Undercity", ru = "Подгород" } } })
            Mock.boot(m, { "FastesBoooy" })
            H.settle(m)
            local step = E():GetSteps()[2]
            assert.equal("Брилл", ns.Steps:PlaceName("Brill"))
            assert.equal("Подгород", ns.Steps:PlaceName("Undercity"), "no client name: the route text")
            assert.equal("Unknown", ns.Steps:PlaceName("Unknown"))
            assert.is_true(E():PlaceMatches("Brill", "Брилл"))
            assert.is_true(E():PlaceMatches("Brill", "Brill"))
            assert.is_false(E():PlaceMatches("Brill", "Подгород"))
            -- already bound to Brill when the step comes up: done by name
            m:MoveTo(1420, 60.5, 52.6)
            H.settle(m)
            assert.equal("fp", H.cur(ns))
            assert.is_true(E():IsDone(step))
        end)
    end)

    describe("quests the player gave up", function()
        it("an optional complete/turnin passed by the forward limit counts as given up", function()
            boot({
                { id = "a363", accept = 363 },
                { id = "t363a364", turnin = 363, accept = 364 },
                { id = "c364", complete = 364, optional = true },
                { id = "t364", turnin = 364, optional = true },
                { id = "a376", accept = 376 },
                { id = "t376", turnin = 376 },
            })
            m:AddQuestToLog(363)
            H.settle(m)
            m:CompleteObjectives(363)
            m:TurnInQuest(363)
            m:AddQuestToLog(364)
            m:AddQuestToLog(376)
            H.settle(m)
            assert.equal("t376", H.cur(ns), "the optional 364 steps are forwarded")
            -- "without the item, abandon 364": the accept of 364 must not come back
            m:AbandonQuest(364)
            H.settle(m)
            assert.equal("t376", H.cur(ns))
            assert.is_true(E():IsDone("t363a364"))
            assert.is_nil(E():GetAcceptQuests()[364])
        end)

        it("abandon before skipping still goes back; a later accept of the same quest is not given up", function()
            boot({
                { id = "a364", accept = 364 },
                { id = "c364", complete = 364 },
                { id = "a376", accept = 376 },
                { id = "r364", accept = 364 },
                { id = "m1", manual = true },
            })
            m:AddQuestToLog(364)
            H.settle(m)
            assert.equal("c364", H.cur(ns))
            m:AbandonQuest(364)
            H.settle(m)
            assert.equal("a364", H.cur(ns), "no mark on c364 yet: the route quest must be taken again")
            m:AddQuestToLog(364)
            H.settle(m)
            E():Skip() -- skip c364 first ...
            H.settle(m)
            assert.equal("a376", H.cur(ns))
            m:AbandonQuest(364) -- ... then abandon
            H.settle(m)
            assert.equal("a376", H.cur(ns))
            assert.is_true(E():IsDone("a364"))
            assert.is_false(E():IsDone("r364"), "the accept after the given-up step is still needed")
            m:AddQuestToLog(376)
            H.settle(m)
            assert.equal("r364", H.cur(ns))
            assert.is_true(E():GetAcceptQuests()[364])
            m:AddQuestToLog(364)
            H.settle(m)
            assert.equal("m1", H.cur(ns))
        end)
    end)

    describe("background goals", function()
        it("a bg collect step stays 'along the way' until collected, then stays done", function()
            boot({
                { id = "a363", accept = 363 },
                { id = "bgc", collect = { [2876] = 2 }, bg = true },
                { id = "a364", accept = 364 },
                { id = "m1", manual = true },
            })
            m:AddQuestToLog(363)
            H.settle(m)
            assert.equal("a364", H.cur(ns))
            for _ = 1, 3 do
                m:Fire("QUEST_LOG_UPDATE")
                H.settle(m)
                assert.same({ "bgc" }, H.ids(E():GetBackground()), "not forwarded by the cursor")
                assert.is_false(E():IsDone("bgc"))
            end
            m:AddQuestToLog(364) -- a later anchor step is done: still not forwarded
            H.settle(m)
            assert.same({ "bgc" }, H.ids(E():GetBackground()))
            m:AddItem(2876, 2)
            H.settle(m)
            assert.is_true(E():IsDone("bgc"))
            assert.same({}, H.ids(E():GetBackground()))
            assert.is_true(m.env.FastesBoooyCharDB.bgDone.bgc, "remembered")
            m:RemoveItem(2876, 2) -- consumed / sold later
            H.settle(m)
            assert.is_true(E():IsDone("bgc"))
            assert.same({}, H.ids(E():GetBackground()))
        end)

        it("a bg transient step is observed while it is in the list", function()
            boot({
                { id = "a363", accept = 363 },
                { id = "bgv", vendor = true, bg = true },
                { id = "a364", accept = 364 },
                { id = "m1", manual = true },
            })
            m:AddQuestToLog(363)
            H.settle(m)
            m:Fire("QUEST_LOG_UPDATE")
            H.settle(m)
            assert.same({ "bgv" }, H.ids(E():GetBackground()))
            assert.is_false(E():IsDone("bgv"))
            m:OpenMerchant({}, 1)
            m:CloseMerchant()
            H.settle(m)
            assert.is_true(E():IsDone("bgv"))
            assert.same({}, H.ids(E():GetBackground()))
            assert.equal("a364", H.cur(ns), "the vendor visit did not complete a non-vendor step")
        end)

        it("a bg step accepting and completing a quest is listed and auto-accepted", function()
            local steps = { { id = "a363", accept = 363 },
                { id = "bg364", accept = 364, complete = 364, bg = true, npc = 1569 } }
            for i = 1, 8 do steps[#steps + 1] = { id = "m" .. i, manual = true } end
            boot(steps)
            m:AddQuestToLog(363)
            H.settle(m)
            assert.equal("m1", H.cur(ns))
            assert.same({ "bg364" }, H.ids(E():GetBackground()))
            local mark = #m.actions
            m:OpenQuestDetail(364, { npcID = 1569 })
            m:CloseInteraction()
            assert.is_true(accepted(mark, 364))
            H.settle(m)
            assert.same({ "bg364" }, H.ids(E():GetBackground()), "still listed until completed")
            m:CompleteObjectives(364)
            H.settle(m)
            assert.same({}, H.ids(E():GetBackground()))
        end)

        it("the bg goals of a segment the player has left are forwarded", function()
            boot(nil, { segments = {
                { id = "s1", title = "S1", steps = {
                    { id = "a363", accept = 363 },
                    { id = "bgc", collect = { [2876] = 2 }, bg = true },
                    { id = "t363", turnin = 363 },
                } },
                { id = "s2", title = "S2", steps = {
                    { id = "a364", accept = 364 },
                    { id = "m1", manual = true },
                } },
            } })
            m:AddQuestToLog(363)
            H.settle(m)
            assert.same({ "bgc" }, H.ids(E():GetBackground()))
            m:CompleteObjectives(363)
            m:TurnInQuest(363)
            H.settle(m)
            assert.equal("a364", H.cur(ns))
            assert.same({}, H.ids(E():GetBackground()))
            assert.is_true(E():IsDone("bgc"))
        end)

        it("a bg step at the end of a segment belongs to the next segment", function()
            boot(nil, { segments = {
                { id = "s1", title = "S1", steps = {
                    { id = "a363", accept = 363 },
                    { id = "bgc", collect = { [2876] = 2 }, bg = true },
                } },
                { id = "s2", title = "S2", steps = {
                    { id = "a364", accept = 364 },
                    { id = "m1", manual = true },
                } },
            } })
            m:AddQuestToLog(363)
            H.settle(m)
            assert.equal("a364", H.cur(ns))
            assert.same({ "bgc" }, H.ids(E():GetBackground()))
            m:AddQuestToLog(364)
            H.settle(m)
            assert.same({ "bgc" }, H.ids(E():GetBackground()))
            assert.is_false(E():IsDone("bgc"))
        end)
    end)

    describe("one window completes one transient step", function()
        local function twoSteps(kind, a, b)
            local s1, s2 = { id = "x1" }, { id = "x2" }
            s1[kind], s2[kind] = a, b
            return { s1, s2, { id = "m", manual = true } }
        end

        it("trainer", function()
            boot(twoSteps("train", true, true))
            m:OpenTrainer({}, 1)
            m:CloseTrainer()
            H.settle(m)
            assert.equal("x2", H.cur(ns))
            m:OpenTrainer({}, 2)
            m:CloseTrainer()
            H.settle(m)
            assert.equal("m", H.cur(ns))
        end)

        it("merchant", function()
            boot(twoSteps("vendor", true, true))
            m:OpenMerchant({}, 1)
            m:CloseMerchant()
            H.settle(m)
            assert.equal("x2", H.cur(ns))
        end)

        it("taxi map", function()
            boot(twoSteps("fp", "Brill", "Undercity"))
            m:OpenTaxi({ { name = "Brill", state = "CURRENT" } }, 1)
            m:CloseTaxi()
            H.settle(m)
            assert.equal("x2", H.cur(ns))
        end)

        it("a train step right after a turn-in at the same NPC, before the throttled refresh", function()
            boot({ { id = "a363", accept = 363 }, { id = "t363", turnin = 363, npc = 1 },
                { id = "tr", train = true, npc = 1 }, { id = "m", manual = true } })
            m:AddQuestToLog(363)
            m:CompleteObjectives(363)
            H.settle(m)
            assert.equal("t363", H.cur(ns))
            m:TurnInQuest(363) -- no settle: the engine refresh is still pending
            m:OpenTrainer({}, 1)
            m:CloseTrainer()
            H.settle(m)
            assert.equal("m", H.cur(ns))
        end)
    end)

    it("an item whose data never loads is requested at most once a minute", function()
        local requests = 0
        boot({ { id = "c", collect = { [987654] = 1 } }, { id = "m1", manual = true } }, {
            setup = function(mm)
                mm:ProvideNS("C_Item", {
                    GetItemNameByID = function() return nil end,
                    RequestLoadItemDataByID = function(id)
                        requests = requests + 1
                        mm:_after(0.05, function() mm:_dispatch("ITEM_DATA_LOAD_RESULT", id, false) end)
                    end,
                })
            end,
        })
        local refreshes = H.record(ns, "PROGRESS_UPDATED")
        local before = requests
        m:Advance(30)
        assert.is_true(requests - before <= 1, (requests - before) .. " requests in 30 s")
        assert.is_true(#refreshes <= 2, #refreshes .. " refreshes in 30 s")
    end)

    describe("Shift", function()
        it("held when the dialog opens suspends the automation for the whole dialog", function()
            boot({ { id = "a364", accept = 364, npc = 1569 }, { id = "m1", manual = true } })
            m:SetShift(true)
            local mark = #m.actions
            m:OpenGossip({ available = { 364 } }, 1569)
            assert.equal(0, #H.actionsSince(m, mark, "C_GossipInfo.SelectAvailableQuest"))
            m:SetShift(false)
            assert.is_true(ns.Automation:IsSuspended(), "suspended for this dialog")
            m:_top(function() m.env.C_GossipInfo.SelectAvailableQuest(364) end)
            assert.is_false(accepted(mark, 364), "not accepted in the dialog opened with Shift")
            m:CloseInteraction()
            assert.is_false(ns.Automation:IsSuspended())
            -- a later dialog (after the grace period) is automated again
            m:Advance(5)
            mark = #m.actions
            m:OpenQuestDetail(364, { npcID = 1569 })
            assert.is_true(accepted(mark, 364))
            m:CloseInteraction()
        end)
    end)

    it("removes its Blizzard waypoint when the next one cannot be placed", function()
        boot({
            { id = "g1", go = true, at = { 1420, 40, 40 } },
            { id = "g2", go = true, at = { 2521, 50, 50 } },
            { id = "m", manual = true },
        }, {
            settings = { blizzWaypoint = true },
            setup = function(mm) mm:DefineMap(2521, { name = "Isle", mapType = 3, canWaypoint = false, noWorld = true }) end,
        })
        ns:Fire("SETTINGS_CHANGED", "blizzWaypoint", true)
        H.settle(m)
        assert.is_table(m.userWaypoint)
        m:MoveTo(1420, 40, 40)
        H.settle(m)
        assert.equal("g2", H.cur(ns))
        assert.is_nil(m.userWaypoint)
        assert.is_false(m.superTrack.waypoint)
    end)

    it("refuses a route written for another format version", function()
        m, ns = H.new({ fixture = false })
        local FB = m.env.FastesBoooy
        assert.is_nil(FB.RegisterRoute({ api = 2, id = "future", title = "Future", faction = "Horde", default = true }))
        FB.AddSegment("future", { id = "f1", title = "S", steps = { { accept = 363 } } })
        Mock.boot(m, { "FastesBoooy" })
        H.settle(m)
        assert.is_nil(ns.Engine:GetRoute())
        assert.is_nil(ns.Registry:Get("future"))
        m.errors = {} -- the chat report of the registry errors is expected
    end)

    it("ignores an invalid reward choice instead of crashing at QUEST_COMPLETE", function()
        boot({
            { id = "a364", accept = 364, npc = 1569 },
            { id = "t364", turnin = 364, npc = 1569, reward = { [364] = "2" } },
        })
        assert.is_true(#ns.Registry.errors >= 1)
        m:AddQuestToLog(364)
        m:CompleteObjectives(364)
        H.settle(m)
        m:DefineQuest(364, { title = "The Mindless Ones", level = 2, xp = 170, choices = { 2876, 3264 },
            objectives = { { text = "Mindless Zombie slain", required = 5 }, { text = "Wretched Zombie slain", required = 5 } } })
        local mark = #m.actions
        m:OpenQuestComplete(364, 2, { npcID = 1569 })
        assert.equal(0, #H.actionsSince(m, mark, "GetQuestReward"), "two choices, none configured: player picks")
        m:CloseInteraction()
    end)
end)
