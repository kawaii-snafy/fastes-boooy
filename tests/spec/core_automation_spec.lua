-- Quest automation (Core/Automation.lua) through the quest dialogs, gossip and greeting
-- of the strict mock (with the default automation delay: every action waits for the mock
-- clock, H.waitAuto), the delay itself, and the quest XP log written on QUEST_TURNED_IN.

local H = require("fixtures.core.helpers")

local m, ns

local function settings() return ns.db.settings end
local function since(mark, name) return H.actionsSince(m, mark, name) end
local function wait() return H.waitAuto(m, ns) end

local function accepted(q, mark)
    for _, a in ipairs(since(mark)) do
        if (a[1] == "AcceptQuest" or a[1] == "AcknowledgeAutoAcceptQuest") and a[2] == q then return true end
    end
    return false
end

local function offer(q, opts)
    local mark = #m.actions
    m:OpenQuestDetail(q, opts)
    wait()
    local ok = accepted(q, mark)
    m:CloseInteraction()
    return ok
end

local function complete(q)
    if not m:IsOnQuest(q) then m:AddQuestToLog(q) end
    m:CompleteObjectives(q)
end

describe("automation", function()
    before_each(function() m, ns = H.boot() end)
    after_each(function() m:AssertClean() end)

    it("accepts the quests of the current step", function()
        assert.is_true(offer(363, { npcID = 1568 }))
        assert.is_true(m:IsOnQuest(363))
        H.settle(m)
        assert.equal("tr-363-364", H.cur(ns))
    end)

    it("accepts only route quests inside the lookahead window", function()
        assert.is_false(offer(9999), "not a route quest")
        assert.is_false(offer(376), "step 8 is beyond cursor 1 + lookahead 6")
        assert.is_true(offer(3901), "step 6 is inside the window")
        settings().lookahead = 0
        assert.is_false(offer(364), "lookahead 0: current step only")
        settings().lookahead = 10
        assert.is_true(offer(376))
    end)

    it("turns in route quests anywhere and takes the only / no reward", function()
        complete(380) -- turnin step 16, far ahead of the cursor
        local mark = #m.actions
        m:OpenQuestProgress(380, { npcID = 1570 })
        wait()
        assert.equal(1, #since(mark, "CompleteQuest"))
        local r = since(mark, "GetQuestReward")
        assert.equal(1, #r)
        assert.equal(0, r[1][3])
        assert.is_true(m:IsQuestCompleted(380))

        complete(9999)
        mark = #m.actions
        m:OpenQuestProgress(9999)
        wait()
        assert.equal(0, #since(mark, "CompleteQuest"), "not a route quest")
        m:CloseInteraction()

        m:DefineQuest(363, { title = "Rude Awakening", level = 1, xp = 40, choices = { 5001 } })
        complete(363)
        mark = #m.actions
        m:OpenQuestComplete(363)
        wait()
        assert.equal(1, since(mark, "GetQuestReward")[1][3], "a single choice is taken")
    end)

    it("picks the step reward, stops with several choices and no rule, refuses quests costing money", function()
        complete(364)
        local mark = #m.actions
        m:OpenQuestComplete(364, 3)
        wait()
        local r = since(mark, "GetQuestReward")
        assert.equal(1, #r)
        assert.equal(2, r[1][3], "reward = { [364] = 2 }")

        complete(380)
        local needed = H.record(ns, "REWARD_CHOICE_NEEDED")
        local chatMark = #m.chat
        mark = #m.actions
        m:OpenQuestComplete(380, 2)
        wait()
        assert.equal(0, #since(mark, "GetQuestReward"))
        assert.is_true(H.chatHas(m, "Choose a reward for \"Night Web's Hollow\" yourself.", chatMark + 1))
        assert.same({ 380, 2 }, { needed[1][1], needed[1][2] })
        m:CloseInteraction()

        m:DefineQuest(3901, { title = "Rattling the Rattlecages", level = 3, moneyRequired = 100 })
        complete(3901)
        chatMark = #m.chat
        mark = #m.actions
        m:OpenQuestComplete(3901)
        wait()
        assert.equal(0, #since(mark, "GetQuestReward"))
        assert.is_true(H.chatHas(m, "requires money", chatMark + 1))
        m:CloseInteraction()
    end)

    it("falls back to the automatic rule when the configured reward index does not exist", function()
        m:DefineQuest(364, { title = "The Mindless Ones", level = 2, choices = { 5001 } })
        complete(364)
        local mark = #m.actions
        m:OpenQuestComplete(364)
        wait()
        assert.equal(1, since(mark, "GetQuestReward")[1][3])
    end)

    it("is suspended while Shift is held", function()
        m:SetShift(true)
        assert.is_true(ns.Automation:IsSuspended())
        assert.is_false(offer(363))
        complete(380)
        local mark = #m.actions
        m:OpenQuestProgress(380)
        wait()
        assert.equal(0, #since(mark, "CompleteQuest"))
        m:CloseInteraction()
        m:SetShift(false)
        assert.is_false(ns.Automation:IsSuspended())
        assert.is_true(offer(363))
    end)

    it("honours the settings toggles", function()
        settings().automation = false
        assert.is_true(ns.Automation:IsSuspended())
        assert.is_false(offer(363))
        settings().automation = true
        settings().autoAccept = false
        assert.is_false(offer(363))
        complete(380)
        settings().autoTurnin = false
        local mark = #m.actions
        m:OpenQuestProgress(380)
        wait()
        assert.equal(0, #since(mark, "CompleteQuest"))
        m:CloseInteraction()
        settings().autoTurnin = true
        m:OpenQuestProgress(380)
        wait()
        assert.is_true(m:IsQuestCompleted(380))
        settings().autoAccept = true
        assert.is_true(offer(363))
    end)

    it("does nothing in combat lockdown", function()
        m:EnterCombat()
        assert.is_false(offer(363))
        m:LeaveCombat()
        assert.is_true(offer(363))
    end)

    it("leaves item-started, area-trigger and PvP offers and a full log to the player", function()
        assert.is_false(offer(363, { startItem = 1307 }), "item-started offer")
        m:DefineQuest(363, { title = "Rude Awakening", autoAccept = true, areaTrigger = true })
        assert.is_false(offer(363), "area-trigger auto quest")
        m:DefineQuest(363, { title = "Rude Awakening", autoAccept = true })
        local mark = #m.actions
        assert.is_true(offer(363))
        assert.equal(1, #since(mark, "AcknowledgeAutoAcceptQuest"))
        m:DefineQuest(364, { title = "The Mindless Ones", pvp = true })
        local chatMark = #m.chat
        assert.is_false(offer(364))
        assert.is_true(H.chatHas(m, "flags you for PvP", chatMark + 1))
    end)

    it("does not accept into a full quest log", function()
        m, ns = H.boot({ mock = { maxQuests = 1 } })
        m:AddQuestToLog(9999)
        local chatMark = #m.chat
        assert.is_false(offer(363))
        assert.is_true(H.chatHas(m, "Quest log is full (1/1)", chatMark + 1))
    end)

    it("gossip: turns in first, then accepts, selecting by quest id", function()
        m:AddQuestToLog(363)
        local mark = #m.actions
        m:OpenGossip({ active = { 363 }, available = { 9999, 364 } }, 1569)
        wait()
        local sel = {}
        for _, a in ipairs(since(mark)) do
            if a[1]:find("^C_GossipInfo%.Select") then sel[#sel + 1] = a[1] .. "(" .. tostring(a[2]) .. ")" end
        end
        assert.same({ "C_GossipInfo.SelectActiveQuest(363)", "C_GossipInfo.SelectAvailableQuest(364)" }, sel)
        assert.is_true(m:IsQuestCompleted(363))
        assert.is_true(m:IsOnQuest(364))
        assert.is_false(m:IsOnQuest(9999))
        m:CloseInteraction()
    end)

    it("greeting: selects by list index", function()
        m:AddQuestToLog(9998)  -- not a route quest, listed first
        m:AddQuestToLog(363)
        local mark = #m.actions
        m:OpenGreeting({ active = { 9998, 363 }, available = { 9999, 364 } }, 1569)
        wait()
        local active = since(mark, "SelectActiveQuest")
        local avail = since(mark, "SelectAvailableQuest")
        assert.equal(1, #active)
        assert.equal(2, active[1][2], "index 2 = quest 363")
        assert.equal(363, active[1][3])
        assert.equal(1, #avail)
        assert.equal(2, avail[1][2], "index 2 = quest 364")
        assert.equal(364, avail[1][3])
        assert.is_true(m:IsQuestCompleted(363))
        assert.is_true(m:IsOnQuest(364))
        m:CloseInteraction()
    end)

    it("selects the current step's gossip option for its NPC only, once per 10 seconds", function()
        H.playTo(m, ns, "tr-sethearth")
        local spec = { options = {
            { name = "Let me browse your goods.", type = "vendor" },
            { name = "Make this inn your home.", type = "binder", bind = { name = "Brill", mapID = 1420, x = 61.7, y = 52 } },
        } }
        local mark = #m.actions
        m:OpenGossip(spec, 1234) -- another NPC
        wait()
        assert.equal(0, #since(mark, "C_GossipInfo.SelectOptionByIndex"))
        m:CloseInteraction()
        m:SetSecretUnits(true)
        m:OpenGossip(spec, 5688) -- secret GUID: unknown NPC
        wait()
        assert.equal(0, #since(mark, "C_GossipInfo.SelectOptionByIndex"))
        m:CloseInteraction()
        m:SetSecretUnits(false)
        m:OpenGossip(spec, 5688)
        wait()
        local sel = since(mark, "C_GossipInfo.SelectOptionByIndex")
        assert.equal(1, #sel)
        assert.equal(1, sel[1][2], "option #2 = orderIndex 1")
        assert.equal("binder", m.interaction and m.interaction.kind)
        m:CloseInteraction()
        m:OpenGossip(spec, 5688)
        wait()
        assert.equal(1, #since(mark, "C_GossipInfo.SelectOptionByIndex"), "not again within 10 s")
        m:CloseInteraction()
        m:Advance(10.5)
        settings().autoGossip = false
        m:OpenGossip(spec, 5688)
        wait()
        assert.equal(1, #since(mark, "C_GossipInfo.SelectOptionByIndex"), "autoGossip off")
        m:CloseInteraction()
        settings().autoGossip = true
        m:OpenGossip(spec, 5688)
        wait()
        assert.equal(2, #since(mark, "C_GossipInfo.SelectOptionByIndex"))
        m:ConfirmBinder()
        H.settle(m)
        assert.equal("tr-vendor", H.cur(ns))
    end)
end)

describe("automation delay", function()
    before_each(function() m, ns = H.boot() end)
    after_each(function() m:AssertClean() end)

    local function count(mark, name, q)
        local n = 0
        for _, a in ipairs(since(mark, name)) do
            if q == nil or a[2] == q then n = n + 1 end
        end
        return n
    end

    it("acts only after autoDelay + random 0..jitter (defaults 0.5 s + 0..0.3 s)", function()
        assert.equal(0.5, settings().autoDelay)
        assert.equal(0.3, settings().autoDelayJitter)
        local mark = #m.actions
        local t0 = m.env.GetTime()
        m:OpenQuestDetail(363, { npcID = 1568 })
        assert.is_false(accepted(363, mark), "not in the event handler")
        local p = ns.Automation:GetPending()
        assert.equal("accept 363", p.key)
        assert.is_true(p.due - t0 >= 0.5 - 1e-9 and p.due - t0 <= 0.8 + 1e-9, tostring(p.due - t0))
        m:Advance(0.45)
        assert.is_false(accepted(363, mark), "nothing before autoDelay")
        assert.is_false(m:IsOnQuest(363))
        m:Advance(0.4) -- 0.85 s > 0.5 + 0.3
        assert.is_true(accepted(363, mark))
        assert.is_true(m:IsOnQuest(363))
        assert.is_nil(ns.Automation:GetPending())
        m:CloseInteraction()
    end)

    it("draws each delay from autoDelay + random 0..jitter; autoDelay 0 ignores the jitter", function()
        local A = ns.Automation
        local seen, distinct = {}, 0
        for _ = 1, 200 do
            local d = A:GetDelay()
            assert.is_true(d >= 0.5 and d <= 0.8, tostring(d))
            if not seen[d] then distinct = distinct + 1 end
            seen[d] = true
        end
        assert.is_true(distinct > 1, "the random extra varies")
        settings().autoDelayJitter = 0
        assert.equal(0.5, A:GetDelay(), "jitter 0: always autoDelay")
        settings().autoDelay = 0
        settings().autoDelayJitter = 1
        assert.equal(0, A:GetDelay(), "autoDelay 0: at once")
        settings().autoDelay = 99 -- hand-edited SavedVariables: clamped
        settings().autoDelayJitter = -5
        assert.equal(3, A:GetDelay())
    end)

    it("drops the action when the dialog closes before the timer", function()
        local mark = #m.actions
        m:OpenQuestDetail(363, { npcID = 1568 })
        m:Advance(0.2)
        m:CloseInteraction()
        assert.is_nil(ns.Automation:GetPending())
        m:Advance(2)
        assert.is_false(accepted(363, mark))
        assert.is_false(m:IsOnQuest(363))
    end)

    it("Shift pressed during the wait cancels the action and suspends the rest of the dialog", function()
        local mark = #m.actions
        m:OpenQuestDetail(363, { npcID = 1568 })
        m:Advance(0.2)
        m:SetShift(true)
        m:SetShift(false) -- a tap is enough
        assert.is_nil(ns.Automation:GetPending())
        assert.is_true(ns.Automation:IsSuspended(), "suspended for this dialog")
        m:Advance(2)
        assert.is_false(accepted(363, mark))
        m:CloseInteraction()
        assert.is_false(ns.Automation:IsSuspended())
        m:Advance(5) -- past the reopen grace of the suspended NPC
        assert.is_true(offer(363, { npcID = 1568 }), "the next dialog is automated again")
    end)

    it("Shift held when the timer fires drops the action", function()
        local mark = #m.actions
        m:OpenQuestDetail(363, { npcID = 1568 })
        m.player.shift = true -- held without a key event (e.g. pressed while the game had no focus)
        m:Advance(1)
        assert.is_false(accepted(363, mark))
        m.player.shift = false
        m:CloseInteraction()
    end)

    it("a different dialog opened during the wait drops the old action", function()
        local mark = #m.actions
        m:OpenQuestDetail(363, { npcID = 1568 })
        m:Advance(0.2)
        m:OpenQuestDetail(3901, { npcID = 1568 }) -- step 6, inside the lookahead window
        assert.equal("accept 3901", ns.Automation:GetPending().key)
        wait()
        assert.is_false(accepted(363, mark), "the first offer was replaced")
        assert.is_true(accepted(3901, mark))
        m:CloseInteraction()
        -- the window shows another quest without an event: the quest id is checked again
        mark = #m.actions
        m:OpenQuestDetail(363, { npcID = 1568 })
        m.dialog.questID = 364
        m:Advance(1)
        assert.equal(0, count(mark, "AcceptQuest"))
        m:CloseInteraction()
    end)

    it("re-checks the settings, combat and the route window when the timer fires", function()
        local mark = #m.actions
        m:OpenQuestDetail(363, { npcID = 1568 })
        settings().autoAccept = false
        m:Advance(1)
        assert.is_false(accepted(363, mark), "auto-accept switched off meanwhile")
        m:CloseInteraction()
        settings().autoAccept = true
        m:OpenQuestDetail(363, { npcID = 1568 })
        m:EnterCombat()
        m:Advance(1)
        assert.is_false(accepted(363, mark), "combat lockdown")
        m:LeaveCombat()
        m:CloseInteraction()
        m:OpenQuestDetail(3901, { npcID = 1568 })
        settings().lookahead = 0
        m:Advance(1)
        assert.is_false(accepted(3901, mark), "no longer inside the route window")
        m:CloseInteraction()
        settings().lookahead = 6
        complete(380)
        m:OpenQuestProgress(380, { npcID = 1570 })
        m:AbandonQuest(380) -- no longer completable
        m:Advance(1)
        assert.equal(0, count(mark, "CompleteQuest"))
        m:CloseInteraction()
        assert.is_true(offer(363))
    end)

    it("duplicate dialog events give one action", function()
        local mark = #m.actions
        m:OpenQuestDetail(363, { npcID = 1568 })
        local p = ns.Automation.pending
        ns.Automation:OnQuestDetail() -- the same window planned again: same token, nothing new
        assert.equal(p, ns.Automation.pending)
        m:Fire("QUEST_DETAIL") -- the client fires the event again for the same window
        m:Fire("QUEST_DETAIL")
        wait()
        assert.equal(1, count(mark, "AcceptQuest", 363))
        m:CloseInteraction()
        mark = #m.actions
        m:OpenGossip({ available = { 364 } }, 1569)
        m:Fire("GOSSIP_SHOW")
        wait()
        assert.equal(1, count(mark, "C_GossipInfo.SelectAvailableQuest", 364))
        assert.equal(1, count(mark, "AcceptQuest", 364))
        m:CloseInteraction()
    end)

    it("plays a gossip -> quest window -> reward -> gossip chain one delayed action at a time", function()
        m:AddQuestToLog(363)
        local mark = #m.actions
        m:OpenGossip({ active = { 363 }, available = { 364 } }, 1569)
        assert.equal(0, #since(mark), "nothing in the event handler")
        assert.equal(4, wait(), "select 363, reward, select 364, accept: one per delay")
        assert.same({ "C_GossipInfo.SelectActiveQuest", "GetQuestReward", "C_GossipInfo.SelectAvailableQuest",
            "AcceptQuest" }, (function()
            local names = {}
            for _, a in ipairs(since(mark)) do names[#names + 1] = a[1] end
            return names
        end)())
        assert.is_true(m:IsQuestCompleted(363))
        assert.is_true(m:IsOnQuest(364))
        m:CloseInteraction()
    end)

    it("keeps a quest window action when the continuing GOSSIP_CLOSED comes after its event", function()
        local mark = #m.actions
        m:OpenQuestDetail(363, { npcID = 1568 })
        m:Fire("GOSSIP_CLOSED", true) -- the gossip frame closes after the quest window opened
        assert.equal("accept 363", ns.Automation:GetPending().key)
        wait()
        assert.is_true(accepted(363, mark))
        m:CloseInteraction()
        -- a gossip action does not survive its own window closing
        m:OpenGossip({ available = { 364 } }, 1569)
        m:Fire("GOSSIP_CLOSED", true)
        assert.is_nil(ns.Automation:GetPending())
        m:Advance(1)
        assert.is_false(m:IsOnQuest(364))
        m:CloseInteraction()
    end)

    it("autoDelay 0 acts at once in the event handler, as before", function()
        settings().autoDelay = 0
        settings().autoDelayJitter = 0.3 -- ignored without a delay
        local mark = #m.actions
        m:OpenQuestDetail(363, { npcID = 1568 })
        assert.is_true(accepted(363, mark), "synchronous")
        assert.is_nil(ns.Automation:GetPending())
        m:CloseInteraction()
        -- the whole gossip chain within the one call
        m:OpenGossip({ active = { 363 }, available = { 364 } }, 1569)
        assert.is_true(m:IsQuestCompleted(363))
        assert.is_true(m:IsOnQuest(364))
        assert.is_nil(ns.Automation:GetPending())
        m:CloseInteraction()
    end)
end)

describe("quest XP log", function()
    before_each(function() m, ns = H.boot() end)
    after_each(function() m:AssertClean() end)

    it("records the XP of QUEST_TURNED_IN with the player level", function()
        m:AddQuestToLog(363)
        m:OpenQuestComplete(363) -- automation turns it in
        wait()
        assert.is_true(m:IsQuestCompleted(363))
        assert.equal(40, ns.db.xpLog[363])
        assert.equal(1, ns.db.xpLogLevel[363])
        assert.equal(40, m.env.AdventureAtlasDB.xpLog[363], "saved account-wide")
        assert.equal(40, m:ExportSavedVariables().AdventureAtlasDB.xpLog[363])
    end)

    it("uses the dialog reward XP when the event reports none, and keeps the maximum", function()
        settings().autoTurnin = false
        m:AddQuestToLog(364)
        m:CompleteObjectives(364)
        m:OpenQuestComplete(364)       -- GetRewardXP() = 170 captured
        m:CloseInteraction()
        m:Fire("QUEST_TURNED_IN", 364, 0, 0)
        assert.equal(170, ns.db.xpLog[364])
        m:Fire("QUEST_TURNED_IN", 364, 85, 0) -- e.g. grey later: lower value ignored
        assert.equal(170, ns.db.xpLog[364])
        m:Fire("QUEST_TURNED_IN", 364, 200, 0)
        assert.equal(200, ns.db.xpLog[364])
        m:Fire("QUEST_TURNED_IN", 4242, 1234, 0) -- any quest, not only route quests
        assert.equal(1234, ns.db.xpLog[4242])
    end)

    it("records server-side turn-ins (no dialog) from the event payload", function()
        m:SetLevel(3)
        m:AddQuestToLog(3901)
        m:CompleteObjectives(3901)
        m:TurnInQuest(3901)
        assert.equal(250, ns.db.xpLog[3901])
        assert.equal(3, ns.db.xpLogLevel[3901])
    end)
end)

-- Reward choices of quests turned in on SHARED steps differ per class; a shared step carries no
-- `reward`, so each class file gives its choices as route data:
-- AdventureAtlas.AddLibraryData({ rewards = { CLASS = { [questID] = index } } }) (Engine:GetRewardChoice).
describe("automation: class reward table (route data `rewards`)", function()
    local gm, gns

    after_each(function()
        if gm then gm:AssertClean() end
        gm, gns = nil, nil
    end)

    -- complete quest q, open its reward window with n choices, let the automation act
    -- @return the chosen index (nil when the automation did not turn in)
    local function turnIn(q, n)
        if not gm:IsOnQuest(q) then gm:AddQuestToLog(q) end
        gm:CompleteObjectives(q)
        local mark = #gm.actions
        gm:OpenQuestComplete(q, n)
        H.waitAuto(gm, gns)
        local r = H.actionsSince(gm, mark, "GetQuestReward")
        if #r == 0 then gm:CloseInteraction() end
        return r[1] and r[1][3] or nil
    end

    it("takes the choice of the character's class for a quest turned in on a shared step", function()
        -- the fixture: Classes/Warrior.lua says [789] = 1, Classes/Mage.lua [789] = 2 (both routes turn 789
        -- in on the shared step tg-dur-789-in, which has no `reward`)
        for id, want in pairs({ ["tg-orc-warrior"] = 1, ["tg-troll-mage"] = 2 }) do
            gm, gns = H.boot({ guides = true, db = true, player = H.GUIDES_PLAYER[id] })
            assert.equal(id, gns.Engine:GetRoute().id)
            assert.is_nil(gns.Engine:GetRoute().stepById["tg-dur-789-in"].reward)
            assert.equal(want, gns.Engine:GetRewardChoice(789), id)
            assert.is_nil(gns.Engine:GetRewardChoice(3901), "the paladin's entry is another class's")
            assert.equal(want, turnIn(789, 3), id)
            assert.is_true(gm:IsQuestCompleted(789))
            gm:AssertClean()
        end
    end)

    it("no entry for the class: several choices are left to the player", function()
        gm, gns = H.boot({ guides = true, db = true, player = H.GUIDES_PLAYER["tg-orc-warrior"] })
        assert.is_nil(gns.Engine:GetRewardChoice(788))
        local chatMark = #gm.chat
        assert.is_nil(turnIn(788, 2))
        assert.is_true(H.chatHas(gm, "Choose a reward for \"Cutting Teeth\" yourself.", chatMark + 1))
    end)

    it("one table per class: a second AddLibraryData call with the same class key replaces the first", function()
        gm, gns = H.boot({ fixture = false, register = function(api)
            api.AddLibrarySegment({ id = "rw-lib", title = "Shared", steps = {
                { id = "rw-363", accept = 363 },
                { id = "rw-364", turnin = 363, accept = 364 },
                { id = "rw-364-in", turnin = 364 },
            } })
            api.AddLibraryData({ rewards = { PALADIN = { [363] = 1, [364] = 2 }, WARRIOR = { [363] = 2 } } })
            api.AddLibraryData({ rewards = { PALADIN = { [363] = 3 } } })
            api.RegisterRoute({ api = 1, id = "rw", title = "Rewards", faction = "Horde", races = { "Scourge" },
                classes = { "PALADIN" }, levels = { 1, 5 } })
            api.UseSegments("rw", { "rw-lib" })
        end })
        local E = gns.Engine
        assert.equal("rw", E:GetRoute().id)
        assert.equal(3, E:GetRewardChoice(363), "the second table")
        assert.is_nil(E:GetRewardChoice(364), "a key of the first table only is gone: replaced, not merged")
        assert.same({ PALADIN = { [363] = 3 }, WARRIOR = { [363] = 2 } }, gns.Registry.library.data.rewards,
            "the other class keeps its table")
        assert.equal(3, turnIn(363, 3))
        assert.same({}, gns.Registry.errors)
        -- That holds while the route is not composed (every file of a module is loaded before login).
        -- Library data that arrives later only fills what the composed route does not have yet, as
        -- for every data kind: the class table already in use stays.
        gm.env.AdventureAtlas.AddLibraryData({ rewards = { PALADIN = { [363] = 2, [364] = 1 }, MAGE = { [363] = 1 } } })
        local route = gns.Registry:Get("rw") -- (recomposed: the library changed)
        assert.equal(route, E:GetRoute())
        assert.same({ [363] = 1 }, route.data.rewards.MAGE, "a new class key is merged")
        assert.same({ [363] = 3 }, route.data.rewards.PALADIN)
        assert.equal(3, E:GetRewardChoice(363))
        assert.is_nil(E:GetRewardChoice(364))
    end)

    it("a step-level reward wins over the class table; invalid table entries are reported and ignored", function()
        gm, gns = H.boot({ fixture = false, register = function(api)
            api.RegisterRoute({ api = 1, id = "rw", title = "Rewards", faction = "Horde", races = { "Scourge" },
                classes = { "PALADIN", "WARRIOR" }, levels = { 1, 5 } })
            api.AddSegment("rw", { id = "rw-s", title = "S", steps = {
                { id = "rw-363", accept = 363 },
                { id = "rw-364", turnin = 363, accept = 364 },
                { id = "rw-364-in", turnin = 364, reward = { [364] = 3 } },
                { id = "rw-376", accept = 376 },
                { id = "rw-376-in", turnin = 376 },
            } })
            -- (a plain route: AddRouteData; a route with shared segments gets the table from AddLibraryData)
            api.AddRouteData("rw", { rewards = {
                PALADIN = { [363] = 2, [364] = 1, [376] = 2, [380] = "two", [3901] = 0, [3902] = 1.5 },
                WARRIOR = { [363] = 3 },
            } })
        end })
        local E = gns.Engine
        assert.equal("rw", E:GetRoute().id)
        -- the shape check reports the invalid entries (Schema.CheckData); the table is merged as given
        local errs = {}
        for _, e in ipairs(gns.Registry.errors) do errs[#errs + 1] = e end
        table.sort(errs)
        assert.same({
            "AddRouteData rw: rewards.PALADIN[380]: the choice must be a positive integer (got two)",
            "AddRouteData rw: rewards.PALADIN[3901]: the choice must be a positive integer (got 0)",
            "AddRouteData rw: rewards.PALADIN[3902]: the choice must be a positive integer (got 1.5)",
        }, errs)
        assert.equal(2, E:GetRewardChoice(363), "class table (PALADIN)")
        assert.equal(3, E:GetRewardChoice(364), "the step's `reward` wins")
        assert.equal(2, E:GetRewardChoice(376))
        assert.is_nil(E:GetRewardChoice(380), "not a positive integer")
        assert.is_nil(E:GetRewardChoice(3901))
        assert.is_nil(E:GetRewardChoice(3902))
        assert.is_nil(E:GetRewardChoice(9999))
        assert.equal(2, turnIn(363, 3))
        assert.equal(3, turnIn(364, 3))
        -- a table index that the reward window does not have: the automatic rule (as for a step's `reward`)
        gm:DefineQuest(376, { title = "The Damned", level = 2, xp = 170, choices = { 5001 } })
        gm:AddQuestToLog(376)
        gm:CompleteObjectives(376)
        local mark = #gm.actions
        gm:OpenQuestComplete(376)
        H.waitAuto(gm, gns)
        assert.equal(1, H.actionsSince(gm, mark, "GetQuestReward")[1][3])
    end)
end)
