-- Quest automation (Core/Automation.lua) through the quest dialogs, gossip and greeting
-- of the strict mock, and the quest XP log written on QUEST_TURNED_IN.

local H = require("fixtures.core.helpers")

local m, ns

local function settings() return ns.db.settings end
local function since(mark, name) return H.actionsSince(m, mark, name) end

local function accepted(q, mark)
    for _, a in ipairs(since(mark)) do
        if (a[1] == "AcceptQuest" or a[1] == "AcknowledgeAutoAcceptQuest") and a[2] == q then return true end
    end
    return false
end

local function offer(q, opts)
    local mark = #m.actions
    m:OpenQuestDetail(q, opts)
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
        assert.equal(1, #since(mark, "CompleteQuest"))
        local r = since(mark, "GetQuestReward")
        assert.equal(1, #r)
        assert.equal(0, r[1][3])
        assert.is_true(m:IsQuestCompleted(380))

        complete(9999)
        mark = #m.actions
        m:OpenQuestProgress(9999)
        assert.equal(0, #since(mark, "CompleteQuest"), "not a route quest")
        m:CloseInteraction()

        m:DefineQuest(363, { title = "Rude Awakening", level = 1, xp = 40, choices = { 5001 } })
        complete(363)
        mark = #m.actions
        m:OpenQuestComplete(363)
        assert.equal(1, since(mark, "GetQuestReward")[1][3], "a single choice is taken")
    end)

    it("picks the step reward, stops with several choices and no rule, refuses quests costing money", function()
        complete(364)
        local mark = #m.actions
        m:OpenQuestComplete(364, 3)
        local r = since(mark, "GetQuestReward")
        assert.equal(1, #r)
        assert.equal(2, r[1][3], "reward = { [364] = 2 }")

        complete(380)
        local needed = H.record(ns, "REWARD_CHOICE_NEEDED")
        local chatMark = #m.chat
        mark = #m.actions
        m:OpenQuestComplete(380, 2)
        assert.equal(0, #since(mark, "GetQuestReward"))
        assert.is_true(H.chatHas(m, "Choose a reward for \"Night Web's Hollow\" yourself.", chatMark + 1))
        assert.same({ 380, 2 }, { needed[1][1], needed[1][2] })
        m:CloseInteraction()

        m:DefineQuest(3901, { title = "Rattling the Rattlecages", level = 3, moneyRequired = 100 })
        complete(3901)
        chatMark = #m.chat
        mark = #m.actions
        m:OpenQuestComplete(3901)
        assert.equal(0, #since(mark, "GetQuestReward"))
        assert.is_true(H.chatHas(m, "requires money", chatMark + 1))
        m:CloseInteraction()
    end)

    it("falls back to the automatic rule when the configured reward index does not exist", function()
        m:DefineQuest(364, { title = "The Mindless Ones", level = 2, choices = { 5001 } })
        complete(364)
        local mark = #m.actions
        m:OpenQuestComplete(364)
        assert.equal(1, since(mark, "GetQuestReward")[1][3])
    end)

    it("is suspended while Shift is held", function()
        m:SetShift(true)
        assert.is_true(ns.Automation:IsSuspended())
        assert.is_false(offer(363))
        complete(380)
        local mark = #m.actions
        m:OpenQuestProgress(380)
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
        assert.equal(0, #since(mark, "CompleteQuest"))
        m:CloseInteraction()
        settings().autoTurnin = true
        m:OpenQuestProgress(380)
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
        assert.equal(0, #since(mark, "C_GossipInfo.SelectOptionByIndex"))
        m:CloseInteraction()
        m:SetSecretUnits(true)
        m:OpenGossip(spec, 5688) -- secret GUID: unknown NPC
        assert.equal(0, #since(mark, "C_GossipInfo.SelectOptionByIndex"))
        m:CloseInteraction()
        m:SetSecretUnits(false)
        m:OpenGossip(spec, 5688)
        local sel = since(mark, "C_GossipInfo.SelectOptionByIndex")
        assert.equal(1, #sel)
        assert.equal(1, sel[1][2], "option #2 = orderIndex 1")
        assert.equal("binder", m.interaction and m.interaction.kind)
        m:CloseInteraction()
        m:OpenGossip(spec, 5688)
        assert.equal(1, #since(mark, "C_GossipInfo.SelectOptionByIndex"), "not again within 10 s")
        m:CloseInteraction()
        m:Advance(10.5)
        settings().autoGossip = false
        m:OpenGossip(spec, 5688)
        assert.equal(1, #since(mark, "C_GossipInfo.SelectOptionByIndex"), "autoGossip off")
        m:CloseInteraction()
        settings().autoGossip = true
        m:OpenGossip(spec, 5688)
        assert.equal(2, #since(mark, "C_GossipInfo.SelectOptionByIndex"))
        m:ConfirmBinder()
        H.settle(m)
        assert.equal("tr-vendor", H.cur(ns))
    end)
end)

describe("quest XP log", function()
    before_each(function() m, ns = H.boot() end)
    after_each(function() m:AssertClean() end)

    it("records the XP of QUEST_TURNED_IN with the player level", function()
        m:AddQuestToLog(363)
        m:OpenQuestComplete(363) -- automation turns it in
        assert.is_true(m:IsQuestCompleted(363))
        assert.equal(40, ns.db.xpLog[363])
        assert.equal(1, ns.db.xpLogLevel[363])
        assert.equal(40, m.env.FastesBoooyDB.xpLog[363], "saved account-wide")
        assert.equal(40, m:ExportSavedVariables().FastesBoooyDB.xpLog[363])
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
