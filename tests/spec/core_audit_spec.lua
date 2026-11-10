-- Regression tests for the core audit findings: undo of a skip that is not right before the cursor,
-- a flight-path step and the taxi map of another flight master, the "auto" level sync before the
-- quest log is loaded, bgDone of a background step ahead of the cursor, the waypoint label of a
-- collect step.

local H = require("fixtures.core.helpers")
local Mock = H.Mock

local m, ns

local function route(api, segments)
    api.RegisterRoute({ api = 1, id = "rg", title = "R", faction = "Horde", races = { "Scourge" },
        classes = { "PALADIN" }, levels = { 1, 20 }, default = true })
    for _, seg in ipairs(segments) do api.AddSegment("rg", seg) end
end

local function boot(segments, opts)
    opts = opts or {}
    opts.fixture = false
    m, ns = H.new(opts)
    route(m.env.FastesBoooy, segments)
    if opts.before then opts.before() end
    Mock.boot(m, { "FastesBoooy" })
    if opts.after then opts.after() end
    H.settle(m)
end

describe("core audit", function()
    after_each(function() m:AssertClean() end)

    it("Back takes back a skip when the step after it was already done", function()
        boot({ { id = "s", title = "S", steps = {
            { id = "a363", accept = 363, npc = 1568 },
            { id = "a364", accept = 364, npc = 1569 },
            { id = "c363", complete = 363 },
            { id = "m1", manual = true },
        } } })
        m:AddQuestToLog(364) -- taken one step early
        H.settle(m)
        assert.equal("a363", H.cur(ns))
        ns.Engine:Forward() -- skips a363: the cursor passes the done a364 and the now void c363 too
        H.settle(m)
        assert.equal("m1", H.cur(ns))
        ns.Engine:Prev()
        H.settle(m)
        assert.equal("c363", H.cur(ns))
        ns.Engine:Prev()
        H.settle(m)
        assert.equal("a364", H.cur(ns))
        assert.is_true(ns.cdb.skipped.a363, "showing a364 does not touch the skip before it")
        ns.Engine:Prev()
        H.settle(m)
        assert.equal("a363", H.cur(ns))
        assert.is_nil(ns.cdb.skipped.a363)
        assert.is_false(ns.Engine:IsPinned(), "a363 is the natural cursor again")
    end)

    it("a flight-path step is not completed by the taxi map of another flight master", function()
        boot({ { id = "s", title = "S", steps = {
            { id = "fp-sep", fp = "The Sepulcher", npc = 2226, at = { 1421, 45.62, 42.60 } },
            { id = "m1", manual = true },
        } } }, { player = { mapID = 1458, x = 63.2, y = 48.5 } }) -- in the Undercity
        assert.equal("fp-sep", H.cur(ns))
        m:OpenTaxi({ { name = "Undercity", state = "CURRENT" }, { name = "Brill", state = "REACHABLE" } }, 4551)
        m:CloseTaxi()
        H.settle(m)
        assert.equal("fp-sep", H.cur(ns))
        -- at the step's place another NPC id still counts (the route may name a different one)
        m:MoveTo(1421, 45.62, 42.60)
        m:OpenTaxi({ { name = "The Sepulcher", state = "CURRENT" } }, 4551)
        m:CloseTaxi()
        H.settle(m)
        assert.equal("m1", H.cur(ns))
    end)

    it("the flight master of the step completes it from anywhere", function()
        boot({ { id = "s", title = "S", steps = {
            { id = "fp-sep", fp = "The Sepulcher", npc = 2226, at = { 1421, 45.62, 42.60 } },
            { id = "m1", manual = true },
        } } }, { player = { mapID = 1458, x = 63.2, y = 48.5 } })
        m:OpenTaxi({ { name = "The Sepulcher", state = "CURRENT" } }, 2226)
        m:CloseTaxi()
        H.settle(m)
        assert.equal("m1", H.cur(ns))
    end)

    it("auto level sync waits for the quest log: no jump from an empty log at login", function()
        local segments = {
            { id = "s1", title = "S1", levels = { 1, 4 }, steps = {
                { id = "a364", accept = 364 }, { id = "a3901", accept = 3901 },
                { id = "c364", complete = 364 }, { id = "t364", turnin = 364 },
                { id = "c3901", complete = 3901 }, { id = "t3901", turnin = 3901 },
            } },
            { id = "s2", title = "S2", levels = { 8, 12 }, steps = {
                { id = "a380", accept = 380 }, { id = "t380", turnin = 380 }, { id = "m1", manual = true },
            } },
        }
        local log
        boot(segments, {
            player = { level = 8 },
            savedVariables = { FastesBoooyDB = { settings = { levelSync = "auto", skipGray = false } } },
            before = function()
                m:_addToLog(364)
                m:_addToLog(3901)
                log, m.questLog = m.questLog, {} -- fresh login: the log is not readable yet
            end,
            after = function()
                assert.is_nil(m.env.FastesBoooyCharDB.syncFloor, "nothing saved from the empty log")
                m.questLog = log
                m:Fire("QUEST_LOG_UPDATE")
            end,
        })
        assert.is_nil(m.env.FastesBoooyCharDB.syncFloor)
        assert.equal("c364", H.cur(ns))
        assert.same({}, ns.Engine:GetDroppedQuests())
    end)

    it("auto level sync still applies once the log is there, or after the delay without an event", function()
        local segments = {
            { id = "s1", title = "S1", levels = { 1, 4 }, steps = {
                { id = "a364", accept = 364 }, { id = "t364", turnin = 364 },
            } },
            { id = "s2", title = "S2", levels = { 8, 12 }, steps = {
                { id = "a380", accept = 380 }, { id = "t380", turnin = 380 }, { id = "m1", manual = true },
            } },
        }
        boot(segments, {
            player = { level = 8 },
            savedVariables = { FastesBoooyDB = { settings = { levelSync = "auto", skipGray = false } } },
        })
        m:Advance(4)
        H.settle(m)
        assert.is_table(m.env.FastesBoooyCharDB.syncFloor)
        assert.equal("a380", H.cur(ns))
    end)

    it("remembers a background collect step as done only once the route reached it", function()
        boot({ { id = "s", title = "S", steps = {
            { id = "a363", accept = 363 },
            { id = "t363", turnin = 363 },
            { id = "a364", accept = 364 },
            { id = "bgc", collect = { [2876] = 2 }, bg = true },
            { id = "c364", complete = 364 },
            { id = "m1", manual = true },
        } } })
        m:AddItem(2876, 2) -- dropped long before the step, then sold
        H.settle(m)
        assert.is_nil(ns.cdb.bgDone.bgc)
        m:RemoveItem(2876, 2)
        H.settle(m)
        m:AddQuestToLog(363)
        m:CompleteObjectives(363)
        m:TurnInQuest(363)
        H.settle(m)
        m:AddQuestToLog(364)
        H.settle(m)
        assert.equal("c364", H.cur(ns))
        assert.same({ "bgc" }, H.ids(ns.Engine:GetBackground()))
        -- collected after the route reached it: remembered, also when the items are used up
        m:AddItem(2876, 2)
        H.settle(m)
        assert.is_true(ns.cdb.bgDone.bgc)
        m:RemoveItem(2876, 2)
        H.settle(m)
        assert.same({}, H.ids(ns.Engine:GetBackground()))
    end)

    it("the waypoint label follows the progress of a collect step", function()
        m, ns = H.boot()
        H.playTo(m, ns, "tr-collect-376")
        H.settle(m)
        assert.equal("Collect Duskbat Wing: 0/6", ns.Waypoint:GetTarget().label)
        m:AddItem(3264, 4)
        H.settle(m, 2)
        assert.equal("Collect Duskbat Wing: 4/6", ns.Waypoint:GetTarget().label)
    end)
end)
