-- Quest log / quest dialog / gossip semantics of the WoW: Forever mock.

local Mock = require("mocks.wow")

-- names of the events fired since index `from` (exclusive)
local function eventsSince(m, from)
    local out = {}
    for i = from + 1, #m.eventLog do out[#out + 1] = m.eventLog[i][1] end
    return out
end

local function contains(list, v)
    for _, x in ipairs(list) do if x == v then return true end end
    return false
end

describe("mock quest log", function()
    local m, env, QL

    before_each(function()
        m = Mock.new({ player = { race = "Scourge", class = "PALADIN", level = 1 } })
        env, QL = m.env, m.env.C_QuestLog
        m:DefineQuest(363, { title = "Rude Awakening", level = 1, xp = 80, zone = "Tirisfal Glades" })
        m:DefineQuest(364, { title = "The Mindless Ones", level = 2, xp = 250, money = 50, zone = "Tirisfal Glades",
            objectives = { { text = "Mindless Zombie slain", required = 8 }, { text = "Wretched Zombie slain", required = 8 } },
            choices = { 2000, 2001 } })
        m:DefineQuest(376, { title = "The Damned", level = 3, xp = 300, zone = "Tirisfal Glades",
            objectives = { { text = "Scavenger Paw", type = "item", itemID = 2672, required = 6 } } })
    end)

    after_each(function() m:AssertClean() end)

    it("accepts a quest through the QUEST_DETAIL dialog", function()
        local mark = #m.eventLog
        m:OpenQuestDetail(363, { npcID = 1568 })
        assert.are.equal(363, env.GetQuestID())
        assert.are.equal("Rude Awakening", env.GetTitleText())
        assert.matches("^Creature%-0%-%d+%-%d+%-%d+%-1568%-", env.UnitGUID("npc"))
        assert.is_true(m:IsWidgetVisible(env.QuestFrame))
        env.AcceptQuest()
        assert.are.same({ "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "QUEST_DETAIL", "QUEST_ACCEPTED", "QUEST_LOG_UPDATE",
            "UNIT_QUEST_LOG_CHANGED", "QUEST_WATCH_LIST_CHANGED", "QUEST_FINISHED",
            "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" }, eventsSince(m, mark))
        assert.are.same({ "QUEST_ACCEPTED", 363 }, m:Events("QUEST_ACCEPTED")[1])
        assert.is_true(QL.IsOnQuest(363))
        assert.are.equal(0, env.GetQuestID())
        assert.is_false(m:IsWidgetVisible(env.QuestFrame))
        assert.are.equal(1, #m:Actions("AcceptQuest"))
    end)

    it("lists zone headers and quests like the client quest log", function()
        m:AddQuestToLog(363)
        m:AddQuestToLog(364)
        local shown, quests = QL.GetNumQuestLogEntries()
        assert.are.equal(3, shown)
        assert.are.equal(2, quests)
        local h = QL.GetInfo(1)
        assert.is_true(h.isHeader)
        assert.are.equal("Tirisfal Glades", h.title)
        assert.are.equal(0, QL.GetQuestIDForLogIndex(1))
        local q = QL.GetInfo(3)
        assert.are.equal(364, q.questID)
        assert.are.equal(3, q.questLogIndex)
        assert.is_false(q.isHeader)
        assert.is_nil(q.isComplete)                  -- GetInfo has no completion field in Forever
        assert.are.equal(3, QL.GetLogIndexForQuestID(364))
        assert.is_nil(QL.GetLogIndexForQuestID(999))
        assert.is_nil(QL.GetInfo(4))
        assert.are.equal(40, QL.GetMaxNumQuestsCanAccept())
        local flat = Mock.new({ questLogHeaders = false })
        flat:AddQuestToLog(363)
        assert.are.equal(1, (flat.env.C_QuestLog.GetNumQuestLogEntries()))
    end)

    it("tracks objectives and quest-wide completion", function()
        m:AddQuestToLog(364)
        local objs = QL.GetQuestObjectives(364)
        assert.are.equal(2, #objs)
        assert.are.same({ text = "0/8 Mindless Zombie slain", type = "monster", finished = false,
            numFulfilled = 0, numRequired = 8 }, objs[1])
        assert.is_false(QL.IsComplete(364))
        m:ProgressObjective(364, 1, 3)
        assert.are.equal("3/8 Mindless Zombie slain", QL.GetQuestObjectives(364)[1].text)
        assert.are.equal("UI_INFO_MESSAGE", m:Events("UI_INFO_MESSAGE")[1][1])
        m:ProgressObjective(364, 1, 99)
        assert.is_true(QL.GetQuestObjectives(364)[1].finished)
        assert.is_false(QL.IsComplete(364))
        m:CompleteObjectives(364)
        assert.is_true(QL.IsComplete(364))
        assert.is_true(QL.ReadyForTurnIn(364))
        -- legacy leaderboard globals by log index (index 2: after the zone header)
        assert.are.equal(2, env.GetNumQuestLeaderBoards(2))
        assert.are.equal("8/8 Wretched Zombie slain", (env.GetQuestLogLeaderBoard(2, 2)))
        -- raw override: 1/1 but unfinished (seen on Forever criteria-tree objectives)
        m:SetObjective(364, 2, { fulfilled = 8, finished = false })
        assert.is_false(QL.IsComplete(364))
        assert.is_nil(QL.GetQuestObjectives(999))
        assert.is_false(QL.IsComplete(999))
    end)

    it("derives item objectives from the bags and consumes the items on turn-in", function()
        m:AddItem(2672, 2)
        m:AddQuestToLog(376)
        assert.are.equal(2, QL.GetQuestObjectives(376)[1].numFulfilled)
        m:ProgressObjective(376, 1, 4)              -- loot 4 more paws
        assert.are.equal(6, env.C_Item.GetItemCount(2672))
        assert.is_true(QL.IsComplete(376))
        m:TurnInQuest(376)
        assert.are.equal(0, env.C_Item.GetItemCount(2672))
        assert.is_true(QL.IsQuestFlaggedCompleted(376))
    end)

    it("turns a quest in through QUEST_PROGRESS -> QUEST_COMPLETE with a reward choice", function()
        m:AddQuestToLog(364)
        m:CompleteObjectives(364)
        m:OpenQuestProgress(364)
        assert.is_true(env.IsQuestCompletable())
        env.CompleteQuest()
        assert.are.equal(1, #m:Events("QUEST_COMPLETE"))
        assert.are.equal(2, env.GetNumQuestChoices())
        local name, _, count, _, _, itemID = env.GetQuestItemInfo("choice", 2)
        assert.are.equal("Item 2001", name)
        assert.are.equal(1, count)
        assert.are.equal(2001, itemID)
        assert.are.equal(250, env.GetRewardXP())
        env.GetQuestReward(0)                       -- a choice is required: ignored by the server
        assert.is_true(QL.IsOnQuest(364))
        assert.are.equal(1, #m.warnings)
        env.GetQuestReward(2)
        assert.is_false(QL.IsOnQuest(364))
        assert.is_true(QL.IsQuestFlaggedCompleted(364))
        assert.are.same({ "QUEST_TURNED_IN", 364, 250, 50 }, m:Events("QUEST_TURNED_IN")[1])
        assert.are.same({ "QUEST_REMOVED", 364, false }, m:Events("QUEST_REMOVED")[1])
        assert.are.equal(1, env.C_Item.GetItemCount(2001))
        assert.are.equal(250, env.UnitXP("player"))
        assert.are.equal(50, env.GetMoney())
        assert.are.same({ 364 }, QL.GetAllCompletedQuestIDs())
        m.warnings = {}
    end)

    it("levels up on turn-in with the client's UnitLevel lag during PLAYER_LEVEL_UP", function()
        m:DefineQuest(500, { title = "Big", level = 5, xp = 1400 })
        local seen = {}
        local f = env.CreateFrame("Frame")
        f:RegisterEvent("PLAYER_LEVEL_UP")
        f:SetScript("OnEvent", function(_, _, newLevel) seen[#seen + 1] = { newLevel, env.UnitLevel("player") } end)
        m:AddQuestToLog(500)
        m:TurnInQuest(500)
        assert.are.same({ { 2, 1 }, { 3, 2 } }, seen)  -- 1400 XP = 400 (1->2) + 900 (2->3) + 100
        assert.are.equal(3, env.UnitLevel("player"))
        assert.are.equal(100, env.UnitXP("player"))
        assert.are.equal(1400, env.UnitXPMax("player"))
    end)

    it("applies the Classic grey-quest XP penalty", function()
        assert.are.equal(80, Mock.QuestXP(80, 1, 6, 60))
        assert.are.equal(65, Mock.QuestXP(80, 1, 7, 60))   -- 80% -> 64 -> rounded to 65
        assert.are.equal(10, Mock.QuestXP(80, 1, 11, 60))  -- 10% -> 8 -> 10
        assert.are.equal(0, Mock.QuestXP(80, 1, 60, 60))
    end)

    it("refuses quests beyond the 40-quest log capacity", function()
        for id = 1, 40 do m:AddQuestToLog(10000 + id) end
        assert.is_false(m:AddQuestToLog(363))
        assert.is_false(QL.IsOnQuest(363))
        assert.are.equal("UI_ERROR_MESSAGE", m:Events("UI_ERROR_MESSAGE")[1][1])
    end)

    it("abandons through SetSelectedQuest / SetAbandonQuest / AbandonQuest", function()
        m:AddQuestToLog(363)
        QL.SetSelectedQuest(363)
        QL.SetAbandonQuest()
        assert.are.equal(363, QL.GetAbandonQuest())
        QL.AbandonQuest()
        assert.is_false(QL.IsOnQuest(363))
        assert.is_false(QL.IsQuestFlaggedCompleted(363))
        assert.are.same({ "QUEST_REMOVED", 363, false }, m:Events("QUEST_REMOVED")[1])
    end)

    it("loads uncached quest data asynchronously", function()
        m:DefineQuest(9001, { title = "Forever-only quest", uncached = true })
        assert.is_nil(QL.GetTitleForQuestID(9001))
        assert.is_false(env.HaveQuestData(9001))
        QL.RequestLoadQuestByID(9001)
        assert.are.equal(0, #m:Events("QUEST_DATA_LOAD_RESULT"))
        m:Advance(0)
        assert.are.same({ "QUEST_DATA_LOAD_RESULT", 9001, true }, m:Events("QUEST_DATA_LOAD_RESULT")[1])
        assert.are.equal("Forever-only quest", QL.GetTitleForQuestID(9001))
    end)

    it("gives unknown quests generic data", function()
        m:OpenQuestDetail(424242)
        assert.are.equal("Quest 424242", env.GetTitleText())
        env.AcceptQuest()
        assert.is_true(QL.IsOnQuest(424242))
        assert.is_true(QL.IsComplete(424242))       -- no objectives
    end)

    it("delays server events with opts.serverDelay", function()
        local slow = Mock.new({ serverDelay = 0.3 })
        slow:OpenQuestDetail(363)
        slow.env.AcceptQuest()
        assert.are.equal(1, #slow:Events("QUEST_FINISHED"))
        assert.is_false(slow.env.C_QuestLog.IsOnQuest(363))
        slow:Advance(0.5)
        assert.is_true(slow.env.C_QuestLog.IsOnQuest(363))
    end)
end)

describe("mock gossip and greeting", function()
    local m, env, G

    before_each(function()
        m = Mock.new()
        env, G = m.env, m.env.C_GossipInfo
        m:DefineQuest(100, { title = "Old" })
        m:DefineQuest(101, { title = "First" })
        m:DefineQuest(102, { title = "Second", level = 2 })
        m:AddQuestToLog(100)
    end)

    it("selects gossip quests by QUEST ID and returns to the gossip after accepting", function()
        m:OpenGossip({ available = { 101, 102 }, active = { 100 } }, 1569)
        assert.are.equal(1, #m:Events("GOSSIP_SHOW"))
        local avail = G.GetAvailableQuests()
        assert.are.equal(2, #avail)
        assert.are.equal(101, avail[1].questID)
        assert.are.equal("First", avail[1].title)
        assert.are.equal(2, avail[2].questLevel)
        assert.are.equal(100, G.GetActiveQuests()[1].questID)
        assert.is_true(G.GetActiveQuests()[1].isComplete)   -- no objectives
        assert.are.equal(0, env.GetNumAvailableQuests())    -- greeting API is empty during gossip

        G.SelectAvailableQuest(1)                            -- a list index is not a quest id
        assert.are.equal(0, #m:Events("QUEST_DETAIL"))
        assert.matches("QUEST ID", m.warnings[1])

        G.SelectAvailableQuest(102)
        assert.are.same({ "GOSSIP_CLOSED", true }, m:Events("GOSSIP_CLOSED")[1])
        assert.are.equal(102, env.GetQuestID())
        env.AcceptQuest()
        assert.are.equal(2, #m:Events("GOSSIP_SHOW"))        -- back to the NPC
        assert.are.equal(1, #G.GetAvailableQuests())
        assert.are.equal(101, G.GetAvailableQuests()[1].questID)
        G.CloseGossip()
        assert.are.same({ "GOSSIP_CLOSED", false }, m:Events("GOSSIP_CLOSED")[2])
        assert.is_nil(env.UnitGUID("npc"))
        m.warnings = {}
    end)

    it("turns in an active gossip quest (complete, no items -> QUEST_COMPLETE directly)", function()
        m:OpenGossip({ active = { 100 } }, 1569)
        G.SelectActiveQuest(100)
        assert.are.equal(1, #m:Events("QUEST_COMPLETE"))
        assert.are.equal(0, #m:Events("QUEST_PROGRESS"))
        env.GetQuestReward(0)
        assert.is_true(env.C_QuestLog.IsQuestFlaggedCompleted(100))
    end)

    it("runs gossip options (vendor / taxi) by id and by order index", function()
        m:OpenGossip({ options = { { name = "Browse your goods", type = "vendor" },
            { name = "I need a ride", type = "taxi", nodes = { { name = "Undercity", state = "CURRENT" } } } } }, 4556)
        local opts = G.GetOptions()
        assert.are.equal(2, #opts)
        assert.are.equal(0, opts[1].orderIndex)
        G.SelectOptionByIndex(1)
        assert.are.equal(1, #m:Events("TAXIMAP_OPENED"))
        assert.are.equal(1, env.NumTaxiNodes())
    end)

    it("uses list INDEXES in the quest greeting", function()
        m:OpenGreeting({ available = { 101, 102 }, active = { 100 } }, 1570)
        assert.are.equal(1, #m:Events("QUEST_GREETING"))
        assert.are.equal(2, env.GetNumAvailableQuests())
        assert.are.equal(1, env.GetNumActiveQuests())
        assert.are.equal(102, select(5, env.GetAvailableQuestInfo(2)))
        assert.are.equal("Second", env.GetAvailableTitle(2))
        local title, complete = env.GetActiveTitle(1)
        assert.are.equal("Old", title)
        assert.is_true(complete)
        assert.are.equal(100, env.GetActiveQuestID(1))
        env.SelectAvailableQuest(2)
        assert.are.equal(102, env.GetQuestID())
        env.AcceptQuest()
        assert.are.equal(2, #m:Events("QUEST_GREETING"))     -- back to the greeting
        assert.are.equal(1, env.GetNumAvailableQuests())
        assert.are.same({ 100, 102 }, m:QuestLogIDs())
    end)

    it("talks to a defined NPC: a single offer opens QUEST_DETAIL directly", function()
        m:DefineNPC(1568, { name = "Undertaker Mordo", starts = { 101 }, ends = {} })
        m:TalkTo(1568)
        assert.are.equal(0, #m:Events("GOSSIP_SHOW"))
        assert.are.equal(101, env.GetQuestID())
        assert.are.equal("Undertaker Mordo", env.UnitName("npc"))
        env.DeclineQuest()
        assert.are.equal(1, #m:Events("QUEST_FINISHED"))
        assert.is_false(env.C_QuestLog.IsOnQuest(101))
    end)

    it("filters NPC offers by prerequisites and level", function()
        m:DefineQuest(103, { title = "Later", pre = { 101 } })
        m:DefineQuest(104, { title = "Too high", reqLevel = 10 })
        m:DefineNPC(1, { starts = { 101, 103, 104 } })
        m:TalkTo(1)
        assert.are.equal(101, env.GetQuestID())          -- only 101 is offered -> direct dialog
        assert.is_true(contains({ 101 }, env.GetQuestID()))
    end)
end)

describe("mock Forever DB fallback", function()
    -- synthetic snapshot in the tools/data/forever_db.lua layout
    local db = {
        quests = {
            [363] = { name = "Rude Awakening", level = 1, reqLevel = 1, xp = 80, uiMap = 1420, races = 16,
                start = { npcs = { 1568 } }, finish = { npcs = { 1569 } } },
            [364] = { name = "The Mindless Ones", level = 2, reqLevel = 1, xp = 170, uiMap = 1420, races = 16,
                preGroup = { 363 }, start = { npcs = { 1569 } }, finish = { npcs = { 1569 } },
                objectives = { creatures = { { 1501, 5 } }, items = { { 2672, 3 } } } },
            [92460] = { name = "Coming of Age", level = 1, reqLevel = 1, races = 2 ^ 33 + 2 ^ 32,
                start = { npcs = { 251362 } }, finish = { npcs = { 251362 } } },
            [500] = { name = "Druid only", level = 1, classes = 1024, start = { objects = { 711 } } },
        },
        npcs = { [1568] = { name = "Undertaker Mordo", maxLevel = 5 }, [1569] = { name = "Shadow Priest Sarvis" },
            [1501] = { name = "Mindless Zombie" } },
        objects = { [711] = { name = "Dusty Tome" } },
        items = { [2672] = { name = "Stringy Wolf Meat" } },
    }

    it("defines quests, NPCs and items from the snapshot on demand", function()
        local m = Mock.new({ player = { race = "Scourge", class = "PALADIN" } }):UseForeverDB(db)
        local env = m.env
        assert.is_false(m:CanTakeQuest(364))                 -- needs 363
        assert.is_false(m:CanTakeQuest(92460))               -- Skyborne only
        assert.is_false(m:CanTakeQuest(500))                 -- druids only
        m:TalkTo(1568)
        assert.are.equal("Rude Awakening", env.GetTitleText())
        assert.are.equal("Undertaker Mordo", env.UnitName("npc"))
        env.AcceptQuest()
        m:TalkTo(1569)                                       -- turn-in only: direct reward dialog
        env.GetQuestReward(0)
        assert.are.equal(80, env.UnitXP("player"))
        assert.is_true(m:CanTakeQuest(364))
        -- back to the NPC: its only offer now is 364, so the server opens its QUEST_DETAIL directly
        assert.are.equal(364, env.GetQuestID())
        env.AcceptQuest()
        local objs = env.C_QuestLog.GetQuestObjectives(364)
        assert.are.equal("0/5 Mindless Zombie slain", objs[1].text)
        assert.are.equal("0/3 Stringy Wolf Meat", objs[2].text)
        assert.are.equal("item", objs[2].type)
        local sky = Mock.new({ player = { race = "Skyborne", faction = "Horde", class = "DRUID" } }):UseForeverDB(db)
        assert.is_true(sky:CanTakeQuest(92460))
        assert.is_false(sky:CanTakeQuest(363))
        sky:TalkToObject(711)
        assert.are.equal(500, sky.env.GetQuestID())
        assert.matches("^GameObject%-0%-%d+%-%d+%-%d+%-711%-", sky.env.UnitGUID("npc"))
        m:AssertClean()
    end)
end)
