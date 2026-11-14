-- luacheck: std lua51+busted
-- Engine scenarios on the real guides module (addons/FastesBoooy_Guides) in the mock client: what the
-- validator and the simulator cannot show, because both take every quest a step names.
--
--   * 98389 "A Light in the Darkness" (docs/dev/PLAN.md E.6): the quest starts and ends at the paladin
--     trainer of Deathknell and has no class limit in the DB. Its three steps are generic and `optional`
--     (tests/spec/guides_layout_spec.lua pins that shape). Here the real engine plays ud-01 for a
--     character the quest is NOT offered to (it never enters the log, nobody presses Skip): the cursor
--     shows the accept once and then never one of its steps again, also after a /reload and after a
--     cold start with empty SavedVariables; with the quest taken every class walks all three steps.
--
-- The module is loaded without the other start zones, the other race files and every class file but the
-- paladin's (the file filter of the tools, Mock.loadAddon opts.skip): the scenario is about the generic
-- steps of Tirisfal, and a half-written file of another zone or class in a parallel phase must not turn
-- this spec red. A route whose class file is skipped is the base route of its race.

local H = require("fixtures.core.helpers")
local Mock = H.Mock
local Glob = require("lib.glob")

local NAME = "FastesBoooy_Guides"
local TOC = "addons/" .. NAME .. "/" .. NAME .. ".toc"
local SKIP_GLOBS = { "Segments/Durotar/*", "Segments/Mulgore/*", "Segments/Zephras/*", "Classes/*", "Races/*" }
local KEEP_GLOBS = { "Classes/Paladin.lua", "Races/Scourge.lua" }

local Q = 98389
local ACCEPT, COMPLETE, TURNIN = "ud01-aramis", "ud01-cocoons", "ud01-98389"
local NEXT_AFTER_ACCEPT = "ud01-arren-4" -- Saltain and Arren: the next quest step when Aramis offers nothing
local STOP = "ud01-end"                  -- the last step of ud-01

local skipSet
local function skipped()
    if not skipSet then
        skipSet = {}
        for _, file in ipairs(Mock.parseToc(TOC).files) do
            local path = file:gsub("\\", "/")
            if Glob.Skipped(path, SKIP_GLOBS, KEEP_GLOBS) then
                skipSet[file] = true
                skipSet[path] = true
            end
        end
    end
    return skipSet
end

-- a client with the core and the guides module; opts.class; opts.from = the mock whose game state
-- (and, unless opts.coldStart, SavedVariables) the new client starts with
local function client(opts)
    local from = opts.from
    local player = { race = "Scourge", class = opts.class, faction = "Horde", level = 1 }
    local sv
    if from then
        for _, k in ipairs({ "class", "level", "xp", "mapID", "x", "y" }) do player[k] = from.player[k] end
        sv = opts.coldStart and {} or from:ExportSavedVariables()
    end
    local m, ns = H.new({ fixture = false, db = true, quests = false, player = player, savedVariables = sv,
        setup = from and function(n)
            local U = Mock.util
            n.questLog = U.deepcopy(from.questLog)
            n.completed = U.deepcopy(from.completed)
            n.items = U.deepcopy(from.items)
            n.bags = U.deepcopy(from.bags)
            n._bagOrder = U.deepcopy(from._bagOrder)
            n._bagSeq = from._bagSeq
            n.bind = U.deepcopy(from.bind)
        end or nil })
    Mock.loadAddon(m, TOC, NAME, { skip = skipped() })
    Mock.boot(m, { "FastesBoooy", NAME }, { reload = from ~= nil and not opts.coldStart })
    H.settle(m)
    return m, ns
end

local function stepById(ns, id)
    local e = ns.Engine
    return e:GetSteps()[assert(e:IndexOf(id), "the route has no step " .. id)]
end

-- Play from the cursor to the step `stop` like a player who does what the window shows. `offered` =
-- false: the NPC does not offer the quest of ACCEPT; the player then goes on to the next quest giver.
-- @return the ids of the steps the cursor showed, in order
local function play(m, ns, stop, offered)
    local e = ns.Engine
    local shown = {}
    for _ = 1, 200 do
        local step = e:GetCurrentStep()
        assert(step, "the route ended before " .. stop)
        shown[#shown + 1] = step.id
        if step.id == stop then return shown end
        if step.id == ACCEPT and not offered then
            H.perform(m, ns, stepById(ns, NEXT_AFTER_ACCEPT))
        else
            H.perform(m, ns, step)
        end
        H.settle(m)
        assert(e:GetCurrentStep() ~= step, "the cursor is stuck on " .. step.id)
    end
    error("play: " .. stop .. " not reached; last steps: " .. table.concat(shown, " ", math.max(1, #shown - 5)))
end

local function count(list, id)
    local n = 0
    for _, v in ipairs(list) do
        if v == id then n = n + 1 end
    end
    return n
end

local function position(list, id)
    for i, v in ipairs(list) do
        if v == id then return i end
    end
    return nil
end

describe("the guides module in the engine: 98389, a quest that may not be offered (E.6)", function()
    it("loads the Undead routes without the other zones and classes", function()
        local m, ns = client({ class = "WARRIOR" })
        assert.same({}, ns.Registry.errors)
        assert.equal("undead-warrior", ns.Engine:GetRoute().id)
        assert.is_true(#m.addons[NAME].skipped >= 15, "the file filter was applied")
        for _, id in ipairs({ ACCEPT, COMPLETE, TURNIN }) do
            local step = stepById(ns, id)
            assert.is_true(step.optional, id .. " must be optional")
            for _, a in ipairs(step.actions) do assert.equal(Q, a.quest, id .. ": an action of another quest") end
        end
        -- the scenario below relies on the order: accept, the next quest giver, ..., complete, turn-in
        local e = ns.Engine
        assert.equal(e:IndexOf(ACCEPT) + 1, e:IndexOf(NEXT_AFTER_ACCEPT))
        assert.is_true(e:IndexOf(NEXT_AFTER_ACCEPT) < e:IndexOf(COMPLETE))
        assert.is_true(e:IndexOf(COMPLETE) < e:IndexOf(TURNIN))
        assert.is_true(e:IndexOf(TURNIN) < e:IndexOf(STOP))
        m:AssertClean()
    end)

    it("not offered: the accept is shown once, the later steps never, nothing is marked", function()
        local m, ns = client({ class = "WARRIOR" })
        local e = ns.Engine
        local shown = play(m, ns, ACCEPT, false)
        assert.equal(ACCEPT, shown[#shown])
        assert.is_true(e:GetAcceptQuests()[Q] == true, "the automation would take the quest if it were offered")
        -- the player takes the quests of Saltain and Arren instead: the cursor passes the optional accept
        H.perform(m, ns, stepById(ns, NEXT_AFTER_ACCEPT))
        H.settle(m)
        assert.equal("ud01-boxes", H.cur(ns))
        assert.is_true(e:IsDone(ACCEPT))
        assert.is_nil(e:GetAcceptQuests()[Q], "a passed optional accept is not auto-accepted")

        local rest = play(m, ns, STOP, false)
        assert.equal(0, count(rest, ACCEPT))
        assert.equal(0, count(rest, COMPLETE), "the complete step of a quest that was never taken")
        assert.equal(0, count(rest, TURNIN), "the turn-in step of a quest that was never taken")
        assert.is_true(position(rest, "ud01-cave") < position(rest, "ud01-arren-5"))
        assert.is_true(e:IsDone(COMPLETE))
        assert.is_true(e:IsDone(TURNIN))
        for _, s in ipairs(e:GetBackground()) do
            assert.is_true(s.id ~= COMPLETE and s.id ~= TURNIN, s.id .. " is listed along the way")
        end
        assert.is_false(m:IsOnQuest(Q))
        assert.is_false(m:IsQuestCompleted(Q))
        assert.same({}, m.env.FastesBoooyCharDB.skipped or {}, "nobody pressed Skip")
        assert.same({}, m.env.FastesBoooyCharDB.manual or {}, "nobody pressed Next")
        m:AssertClean()

        -- /reload and a cold start (SavedVariables lost) land on the same step
        for _, cold in ipairs({ false, true }) do
            local m2, ns2 = client({ class = "WARRIOR", from = m, coldStart = cold })
            assert.same({}, ns2.Registry.errors)
            assert.equal(STOP, H.cur(ns2), cold and "cold start" or "/reload")
            assert.is_true(ns2.Engine:IsDone(ACCEPT))
            assert.is_true(ns2.Engine:IsDone(COMPLETE))
            assert.is_true(ns2.Engine:IsDone(TURNIN))
            m2:AssertClean()
        end
    end)

    it("not offered, cold start in the middle: the cursor does not go back to the accept", function()
        local m, ns = client({ class = "WARRIOR" })
        play(m, ns, "ud01-cave", false)
        local _, ns2 = client({ class = "WARRIOR", from = m, coldStart = true })
        assert.equal("ud01-cave", H.cur(ns2))
        assert.is_true(ns2.Engine:IsDone(ACCEPT))
    end)

    it("offered: a class without class steps walks all three steps", function()
        local m, ns = client({ class = "WARRIOR" })
        local shown = play(m, ns, STOP, true)
        local a, c, t = position(shown, ACCEPT), position(shown, COMPLETE), position(shown, TURNIN)
        assert.is_truthy(a and c and t, "one of the three steps was not shown")
        assert.is_true(a < c and c < t)
        assert.equal(1, count(shown, ACCEPT))
        assert.equal(1, count(shown, COMPLETE))
        assert.equal(1, count(shown, TURNIN))
        assert.equal(position(shown, "ud01-cave") + 1, c, "the cocoons follow the spiders of the same cave")
        assert.is_true(m:IsQuestCompleted(Q))
        m:AssertClean()
    end)

    it("offered: the paladin (a class with its own steps around the accept) walks all three steps", function()
        -- (what the paladin file puts between the steps is that file's business, phase C may move it: only the
        -- three generic steps and their order are asserted)
        local m, ns = client({ class = "PALADIN" })
        assert.equal("undead-paladin", ns.Engine:GetRoute().id)
        local shown = play(m, ns, STOP, true)
        local a, c, t = position(shown, ACCEPT), position(shown, COMPLETE), position(shown, TURNIN)
        assert.is_truthy(a and c and t, "one of the three steps was not shown")
        assert.is_true(a < c and c < t)
        assert.equal(1, count(shown, ACCEPT))
        assert.equal(1, count(shown, TURNIN))
        assert.is_true(m:IsQuestCompleted(Q))
        m:AssertClean()
    end)

    it("not offered to a paladin either: whatever stands behind the accept comes, the later steps never", function()
        -- (the paladin trainer gives the quest, so this is the unlikely direction; the engine must not
        -- depend on which class is refused)
        local m, ns = client({ class = "PALADIN" })
        local shown = play(m, ns, ACCEPT, false)
        assert.equal(ACCEPT, shown[#shown])
        local e = ns.Engine
        local after = e:GetSteps()[e:IndexOf(ACCEPT) + 1]
        H.perform(m, ns, after) -- the next thing the player can do (a class step of the church, or Saltain)
        H.settle(m)
        assert.is_true(e:IsDone(ACCEPT))
        local rest = play(m, ns, STOP, false)
        assert.equal(0, count(rest, ACCEPT))
        assert.equal(0, count(rest, COMPLETE))
        assert.equal(0, count(rest, TURNIN))
        assert.is_false(m:IsOnQuest(Q))
        m:AssertClean()
    end)
end)
