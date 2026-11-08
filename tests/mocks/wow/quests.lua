-- tests/mocks/wow/quests.lua
--
-- Quest database of the session, quest log (C_QuestLog + legacy leaderboard
-- globals), quest dialogs (QUEST_DETAIL / QUEST_PROGRESS / QUEST_COMPLETE /
-- QUEST_GREETING and their globals), gossip (C_GossipInfo) and NPC conversations.
--
-- Event order used by the mock (server events first, then the dialog closes):
--   accept : QUEST_ACCEPTED(id), QUEST_LOG_UPDATE, UNIT_QUEST_LOG_CHANGED("player"),
--            QUEST_WATCH_LIST_CHANGED(id, true); QUEST_FINISHED; back to the NPC's
--            gossip / greeting when it still offers something.
--   turn in: QUEST_TURNED_IN(id, xp, money), QUEST_REMOVED(id, false), QUEST_LOG_UPDATE,
--            UNIT_QUEST_LOG_CHANGED("player"), XP / level / bag events; QUEST_FINISHED; back to NPC.
-- With opts.serverDelay > 0 the dialog closes first and the server events follow after
-- the delay (m:Advance).

local ctx = ...
local Mock, M, A, U = ctx.Mock, ctx.M, ctx.A, ctx.U

local PIT = A.enums.PlayerInteractionType or {}

---------------------------------------------------------------------------
-- quest database
---------------------------------------------------------------------------

local function normObjectives(list)
    local out = {}
    for i, o in ipairs(list or {}) do
        if type(o) == "string" then o = { text = o } end
        out[i] = {
            text = o.text or ("Objective " .. i), type = o.type or (o.itemID and "item") or "monster",
            required = o.required or 1, itemID = o.itemID, objectiveType = o.objectiveType,
        }
    end
    return out
end

--- Define a quest for the session:
-- { title, level (quest level), reqLevel, xp (base XP), money, zone (quest log header),
--   objectives = { { text, required, type ("monster"|"item"|"object"|"event"), itemID } },
--   choices = { itemID | { itemID, count } }, rewards = { ... }, moneyRequired,
--   pre = { questIDs } (all needed to be offered), autoAccept, areaTrigger, pvp,
--   repeatable, uncached (title unknown until RequestLoadQuestByID), complete (override),
--   detailText, objectiveText, progressText, rewardText }
function M:DefineQuest(id, def)
    def = U.deepcopy(def or {})
    def.id = id
    def.title = def.title or ("Quest " .. id)
    def.level = def.level or 1
    def.reqLevel = def.reqLevel or 1
    def.xp = def.xp or 0
    def.money = def.money or 0
    def.objectives = normObjectives(def.objectives)
    def.zone = def.zone or "Quests"
    self.questDB[id] = def
    if not def.uncached then self.questCache[id] = true end
    return def
end

function M:_quest(id)
    local def = self.questDB[id]
    if not def then
        local fromDB = self.foreverDB and self:_questFromDB(id)
        def = self:DefineQuest(id, fromDB or { level = self.player.level, generic = true })
    end
    return def
end

--- Base reward XP of a quest for the current player (level penalty applied).
function M:QuestRewardXP(id)
    local def = self:_quest(id)
    return Mock.QuestXP(def.xp, def.level, self.player.level, self.maxLevel)
end

---------------------------------------------------------------------------
-- quest log
---------------------------------------------------------------------------

function M:_logEntry(id)
    for _, e in ipairs(self.questLog) do
        if e.questID == id then return e end
    end
    return nil
end

local function objFinished(o)
    if o.finished ~= nil then return o.finished end
    return o.fulfilled >= o.required
end

function M:_isComplete(e)
    if e.complete ~= nil then return e.complete end
    if e.failed then return false end
    for _, o in ipairs(e.objectives) do
        if not objFinished(o) then return false end
    end
    return true
end

-- entries as shown in the quest log (zone headers + quests)
function M:_entries()
    local out = {}
    if not self.questLogHeaders then
        for _, e in ipairs(self.questLog) do out[#out + 1] = e end
        return out
    end
    local order, groups = {}, {}
    for _, e in ipairs(self.questLog) do
        local h = e.header
        if not groups[h] then groups[h] = {}; order[#order + 1] = h end
        table.insert(groups[h], e)
    end
    for _, h in ipairs(order) do
        out[#out + 1] = { isHeader = true, title = h, questID = 0 }
        for _, e in ipairs(groups[h]) do out[#out + 1] = e end
    end
    return out
end

local function objectiveText(o)
    if o.type == "event" and o.required == 1 then return o.text end
    return string.format("%d/%d %s", o.fulfilled, o.required, o.text)
end

function M:_addToLog(id)
    local def = self:_quest(id)
    local e = { questID = id, header = def.zone, objectives = {}, complete = def.complete, failed = false }
    for i, o in ipairs(def.objectives) do
        e.objectives[i] = { text = o.text, type = o.type, required = o.required, itemID = o.itemID,
            objectiveType = o.objectiveType, fulfilled = 0 }
        if o.itemID then e.objectives[i].fulfilled = math.min(o.required, self.bags[o.itemID] or 0) end
    end
    self.questLog[#self.questLog + 1] = e
    self.questCache[id] = true
    return e
end

function M:_logChanged(id)
    self:_dispatch("QUEST_LOG_UPDATE")
    self:_dispatch("UNIT_QUEST_LOG_CHANGED", "player")
end

--- Server side of accepting a quest (no dialog). Returns false when the log is full.
function M:_serverAccept(id)
    if self:_logEntry(id) then return true end
    if #self.questLog >= self.maxQuests then
        self:_dispatch("UI_ERROR_MESSAGE", 1, "Your quest log is full.")
        return false
    end
    self:_addToLog(id)
    self:_dispatch("QUEST_ACCEPTED", id)
    self:_logChanged(id)
    self:_dispatch("QUEST_WATCH_LIST_CHANGED", id, true)
    return true
end

--- Server side of turning a quest in (no dialog). `choice` = reward choice index (0 = none).
function M:_serverTurnIn(id, choice)
    local e = self:_logEntry(id)
    if not e then return false end
    local def = self:_quest(id)
    local xp = self:QuestRewardXP(id)
    local money = def.money or 0
    for i, x in ipairs(self.questLog) do
        if x == e then table.remove(self.questLog, i); break end
    end
    self.completed[id] = true
    self.turnedIn[#self.turnedIn + 1] = { questID = id, xp = xp, money = money, choice = choice }
    self.player.money = (self.player.money or 0) + money - (def.moneyRequired or 0)
    self:_dispatch("QUEST_TURNED_IN", id, xp, money)
    self:_dispatch("QUEST_REMOVED", id, false)
    self:_logChanged(id)
    -- collected quest items are consumed, rewards are pushed
    for _, o in ipairs(e.objectives) do
        if o.itemID and (self.bags[o.itemID] or 0) > 0 then
            self:_changeItem(o.itemID, -math.min(o.required, self.bags[o.itemID]))
        end
    end
    local function give(r)
        local itemID, count = r, 1
        if type(r) == "table" then itemID, count = r[1] or r.itemID, r[2] or r.count or 1 end
        self:_changeItem(itemID, count)
    end
    if choice and choice > 0 and def.choices and def.choices[choice] then give(def.choices[choice]) end
    for _, r in ipairs(def.rewards or {}) do give(r) end
    if money > 0 then self:_dispatch("PLAYER_MONEY") end
    if xp > 0 then self:_giveXP(xp) end
    return true
end

function M:_serverAbandon(id)
    local e = self:_logEntry(id)
    if not e then return false end
    for i, x in ipairs(self.questLog) do
        if x == e then table.remove(self.questLog, i); break end
    end
    self:_dispatch("QUEST_REMOVED", id, false)
    self:_logChanged(id)
    self:_dispatch("QUEST_WATCH_LIST_CHANGED", id, false)
    return true
end

-- helpers for specs -----------------------------------------------------------

--- Put a quest in the log as if accepted (fires QUEST_ACCEPTED etc.).
function M:AddQuestToLog(id)
    return self:_top(function() return self:_serverAccept(id) end)
end

--- Progress objective `index` of a quest by n (default 1). Item objectives add the item
-- to the bags instead. Fires UI_INFO_MESSAGE, QUEST_WATCH_UPDATE, QUEST_LOG_UPDATE,
-- UNIT_QUEST_LOG_CHANGED.
function M:ProgressObjective(id, index, n)
    n = n or 1
    return self:_top(function()
        local e = self:_logEntry(id)
        if not e then error("mock: ProgressObjective: quest " .. tostring(id) .. " is not in the log", 0) end
        local o = e.objectives[index or 1]
        if not o then error("mock: ProgressObjective: quest " .. id .. " has no objective " .. tostring(index), 0) end
        if o.itemID then
            self:_changeItem(o.itemID, n)
            return
        end
        o.fulfilled = math.max(0, math.min(o.required, o.fulfilled + n))
        self:_dispatch("UI_INFO_MESSAGE", 0, objectiveText(o))
        self:_dispatch("QUEST_WATCH_UPDATE", id)
        self:_logChanged(id)
    end)
end

--- Fulfil every objective of a quest in the log.
function M:CompleteObjectives(id)
    return self:_top(function()
        local e = self:_logEntry(id)
        if not e then error("mock: CompleteObjectives: quest " .. tostring(id) .. " is not in the log", 0) end
        for _, o in ipairs(e.objectives) do
            if o.itemID then
                local need = o.required - (self.bags[o.itemID] or 0)
                if need > 0 then self:_changeItem(o.itemID, need) end
            end
            o.fulfilled = o.required
        end
        if e.complete == false then e.complete = nil end
        self:_dispatch("QUEST_WATCH_UPDATE", id)
        self:_logChanged(id)
    end)
end
M.CompleteQuestObjectives = M.CompleteObjectives

--- Raw objective override: fields { fulfilled, finished } (e.g. 1/1 but unfinished).
function M:SetObjective(id, index, fields)
    return self:_top(function()
        local e = self:_logEntry(id)
        local o = e and e.objectives[index]
        if not o then error("mock: SetObjective: no objective " .. tostring(index) .. " for quest " .. tostring(id), 0) end
        for k, v in pairs(fields) do o[k] = v end
        self:_dispatch("QUEST_WATCH_UPDATE", id)
        self:_logChanged(id)
    end)
end

--- Override the quest-wide completion flag of a quest in the log (nil = derive from objectives).
function M:SetQuestComplete(id, complete)
    return self:_top(function()
        local e = self:_logEntry(id)
        if not e then error("mock: SetQuestComplete: quest " .. tostring(id) .. " is not in the log", 0) end
        e.complete = complete
        self:_logChanged(id)
    end)
end

function M:FailQuest(id)
    return self:_top(function()
        local e = self:_logEntry(id)
        if e then e.failed = true; self:_logChanged(id) end
    end)
end

--- Turn a quest in without a dialog (server side): QUEST_TURNED_IN etc.
function M:TurnInQuest(id, choice)
    return self:_top(function() return self:_serverTurnIn(id, choice or 0) end)
end

--- Abandon a quest without the quest log UI (server side): QUEST_REMOVED etc.
function M:AbandonQuest(id)
    return self:_top(function() return self:_serverAbandon(id) end)
end

--- Mark quests as completed in the account history without events (initial state).
function M:SetCompletedQuests(ids)
    for _, id in ipairs(ids) do self.completed[id] = true end
end
function M:SetQuestCompleted(id, done) self.completed[id] = done and true or nil end
function M:IsQuestCompleted(id) return self.completed[id] == true end
function M:IsOnQuest(id) return self:_logEntry(id) ~= nil end
function M:QuestLogIDs()
    local out = {}
    for _, e in ipairs(self.questLog) do out[#out + 1] = e.questID end
    return out
end

function M:_onItemsChanged(itemID)
    for _, e in ipairs(self.questLog) do
        for _, o in ipairs(e.objectives) do
            if o.itemID == itemID then
                local n = math.min(o.required, self.bags[itemID] or 0)
                if n ~= o.fulfilled then
                    o.fulfilled = n
                    self:_dispatch("UI_INFO_MESSAGE", 0, objectiveText(o))
                    self:_dispatch("QUEST_WATCH_UPDATE", e.questID)
                    self:_logChanged(e.questID)
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- dialogs / NPC conversations
---------------------------------------------------------------------------

local function npcQuestLists(m, spec)
    local avail, active = {}, {}
    local raw = spec.raw
    for _, q in ipairs(spec.available or {}) do
        local id = type(q) == "table" and q.questID or q
        if raw or (not m:_logEntry(id) and not m.completed[id]) then avail[#avail + 1] = id end
    end
    for _, q in ipairs(spec.active or {}) do
        local id = type(q) == "table" and q.questID or q
        if raw or m:_logEntry(id) then active[#active + 1] = id end
    end
    return avail, active
end

local function questUIInfo(m, id, isActive)
    local def = m:_quest(id)
    local e = m:_logEntry(id)
    return {
        title = def.title, questLevel = def.level, isTrivial = m:_isTrivial(def), frequency = 0,
        repeatable = def.repeatable or false, isComplete = isActive and (e and m:_isComplete(e) or false) or nil,
        isLegendary = false, isIgnored = false, questID = id, isImportant = false, isMeta = false,
        questInfoID = id,
    }
end

--- Green range of the player (C_QuestLog.GetTrivialRange / UnitQuestTrivialLevelRange): a quest is
-- gray (trivial) when playerLevel - questLevel > range. Classic gray-level rule (tools/lib/fbdb.lua
-- DB.GreyLevel): range = level - greyLevel - 1.
function M:TrivialRange(level)
    local p = level or self.player.level
    local grey
    if p <= 5 then grey = 0
    elseif p <= 39 then grey = p - math.floor(p / 10) - 5
    elseif p <= 59 then grey = p - math.floor(p / 5) - 1
    else grey = 48 end
    return p - grey - 1
end

function M:_isTrivial(def)
    local p = self.player.level
    local q = def.level or p
    if q <= 0 then return false end -- scaling quests (level -1) are never trivial
    return p - q > self:TrivialRange(p)
end

local function setDialog(m, d)
    m.dialog = d
end

local function showQuestFrame(m)
    if not (m.interaction and m.interaction.questFrame) then
        if m.interaction then m.interaction.questFrame = true end
        m:_panel("QuestFrame", true)
        m:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", PIT.QuestGiver)
    end
end

local function closeGossipFrame(m, continuing)
    if m.interaction and m.interaction.gossipFrame then
        m.interaction.gossipFrame = false
        m:_panel("GossipFrame", false)
        m:_dispatch("GOSSIP_CLOSED", continuing and true or false)
        m:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", PIT.Gossip)
    end
end

-- close the quest frame (QUEST_FINISHED) and optionally return to the parent conversation
local function finishQuestFrame(m, returnToParent)
    local d = m.dialog
    local parent = d and d.parent
    m.dialog = nil
    if m.interaction and m.interaction.questFrame then
        m.interaction.questFrame = false
        m:_panel("QuestFrame", false)
        m:_dispatch("QUEST_FINISHED")
        m:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", PIT.QuestGiver)
    end
    if returnToParent and parent and parent.npc then
        m:_talk(parent.npcID, true)
        return
    end
    if returnToParent and parent then
        local avail, active = npcQuestLists(m, parent.spec)
        if #avail + #active + #(parent.spec.options or {}) > 0 then
            if parent.kind == "gossip" then m:_openGossip(parent.spec, parent.npcID)
            else m:_openGreeting(parent.spec, parent.npcID) end
            return
        end
    end
    m:_endInteraction()
end

function M:_beginQuestInteraction(kind, npcID)
    if not self.interaction or (npcID and self.interaction.npc and self.interaction.npc.id ~= npcID) then
        self:_beginInteraction(kind, npcID)
    else
        self.interaction.kind = kind
    end
end

function M:_openDetail(id, opts)
    opts = opts or {}
    self:_quest(id)
    self:_beginQuestInteraction("quest", opts.npcID or (self.interaction and self.interaction.npc and self.interaction.npc.id))
    closeGossipFrame(self, true)
    setDialog(self, { mode = "detail", questID = id, parent = opts.parent, startItem = opts.startItem })
    showQuestFrame(self)
    self:_dispatch("QUEST_DETAIL", opts.startItem)
end

function M:_openProgressOrComplete(id, opts)
    opts = opts or {}
    local def = self:_quest(id)
    local e = self:_logEntry(id)
    local hasItems = false
    for _, o in ipairs(def.objectives) do if o.itemID then hasItems = true end end
    if def.moneyRequired and def.moneyRequired > 0 then hasItems = true end
    if e and self:_isComplete(e) and not hasItems and not opts.forceProgress then
        self:_openComplete(id, opts)
    else
        self:_openProgress(id, opts)
    end
end

function M:_openProgress(id, opts)
    opts = opts or {}
    self:_quest(id)
    self:_beginQuestInteraction("quest", opts.npcID or (self.interaction and self.interaction.npc and self.interaction.npc.id))
    closeGossipFrame(self, true)
    setDialog(self, { mode = "progress", questID = id, parent = opts.parent })
    showQuestFrame(self)
    self:_dispatch("QUEST_PROGRESS")
end

function M:_openComplete(id, opts)
    opts = opts or {}
    local def = self:_quest(id)
    if opts.numChoices and not def.choices then
        def.choices = {}
        for i = 1, opts.numChoices do
            local itemID = 990000 + id * 10 + i
            if not self.items[itemID] then self:DefineItem(itemID, { name = "Reward " .. i .. " of " .. def.title }) end
            def.choices[i] = itemID
        end
    end
    self:_beginQuestInteraction("quest", opts.npcID or (self.interaction and self.interaction.npc and self.interaction.npc.id))
    closeGossipFrame(self, true)
    local parent = opts.parent or (self.dialog and self.dialog.parent)
    setDialog(self, { mode = "complete", questID = id, parent = parent })
    showQuestFrame(self)
    self:_dispatch("QUEST_COMPLETE")
end

function M:_openGossip(spec, npcID, fromNPC)
    if self.interaction and self.interaction.questFrame then
        self.interaction.questFrame = false
        self:_panel("QuestFrame", false)
        self:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", PIT.QuestGiver)
    end
    self:_beginQuestInteraction("gossip", npcID)
    setDialog(self, { mode = "gossip", spec = spec, npcID = npcID, npc = fromNPC })
    self.interaction.gossipFrame = true
    self:_panel("GossipFrame", true)
    self:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", PIT.Gossip)
    self:_dispatch("GOSSIP_SHOW", spec.textureKit)
end

function M:_openGreeting(spec, npcID, fromNPC)
    self:_beginQuestInteraction("greeting", npcID)
    closeGossipFrame(self, true)
    setDialog(self, { mode = "greeting", spec = spec, npcID = npcID, npc = fromNPC })
    showQuestFrame(self)
    self:_dispatch("QUEST_GREETING")
end

function M:_closeQuestInteraction()
    local d = self.dialog
    if d and d.mode == "gossip" then
        self.dialog = nil
        closeGossipFrame(self, false)
        self:_endInteraction()
    elseif self.interaction and (self.interaction.questFrame or d) then
        finishQuestFrame(self, false)
    end
end

--- Open the quest offer dialog (QUEST_DETAIL). opts: npcID, startItem (questStartItemID).
function M:OpenQuestDetail(id, opts)
    return self:_top(function() self:_openDetail(id, opts) end)
end

--- Open the "turn in" dialog (QUEST_PROGRESS); the addon may CompleteQuest().
function M:OpenQuestProgress(id, opts)
    return self:_top(function() self:_openProgress(id, opts) end)
end

--- Open the reward dialog (QUEST_COMPLETE). numChoices creates generic reward choices
-- when the quest definition has none.
function M:OpenQuestComplete(id, numChoices, opts)
    opts = opts or {}
    opts.numChoices = numChoices
    return self:_top(function() self:_openComplete(id, opts) end)
end

--- Open a gossip window (GOSSIP_SHOW): spec = { available = {questIDs}, active = {questIDs},
-- options = { { name, gossipOptionID, type ("taxi"|"trainer"|"vendor"|"binder"|"close"),
-- onSelect = function(m), status, icon, flags } }, text, raw (no log filtering) }.
function M:OpenGossip(spec, npcID)
    return self:_top(function() self:_openGossip(spec or {}, npcID) end)
end

--- Open a quest greeting (QUEST_GREETING, multi-quest NPC without gossip):
-- spec = { available = {questIDs}, active = {questIDs}, text }.
function M:OpenGreeting(spec, npcID)
    return self:_top(function() self:_openGreeting(spec or {}, npcID) end)
end

function M:_npcSpec(npcID)
    local npc = self.npcs[npcID] or (self.foreverDB and npcID > 0 and self:_npcFromDB(npcID))
    if not npc then return nil end
    local spec = { available = {}, active = U.deepcopy(npc.ends or {}), options = npc.options, text = npc.text }
    for _, id in ipairs(npc.starts or {}) do
        if self:CanTakeQuest(id) then spec.available[#spec.available + 1] = id end
    end
    return spec, npc
end

-- server side of talking to an NPC (also used to return to the NPC after a dialog)
function M:_talk(npcID, returning)
    local spec, npc = self:_npcSpec(npcID)
    if not spec then error("mock: TalkTo: NPC " .. tostring(npcID) .. " is not defined (m:DefineNPC)", 0) end
    local avail, active = npcQuestLists(self, spec)
    local nOptions = #(npc.options or {})
    if returning and #avail + #active + nOptions == 0 then
        self:_endInteraction()
        return
    end
    local kind = npc.greeting and "greeting" or "gossip"
    if not returning then self:_beginInteraction(kind, npcID) end
    local parent = { kind = kind, spec = spec, npcID = npcID, npc = true }
    if nOptions == 0 and #avail + #active == 1 then
        if #avail == 1 then self:_openDetail(avail[1], { npcID = npcID, parent = parent })
        else self:_openProgressOrComplete(active[1], { npcID = npcID, parent = parent }) end
    elseif npc.greeting then
        self:_openGreeting(spec, npcID, true)
    else
        self:_openGossip(spec, npcID, true)
    end
end

--- Talk to an NPC defined with m:DefineNPC (or found in the Forever DB, see
-- m:UseForeverDB): offers are filtered with m:CanTakeQuest; a single quest and no
-- gossip options opens the quest dialog directly, a greeting NPC opens QUEST_GREETING,
-- otherwise GOSSIP_SHOW. After accepting / turning in, the mock returns to the NPC
-- (recomputing its offers) while it still has something to say.
function M:TalkTo(npcID)
    return self:_top(function() self:_talk(npcID, false) end)
end

--- Talk to a game object (quest starter / ender): like TalkTo with a GameObject GUID.
function M:TalkToObject(objectID)
    if not self.npcs[-objectID] and self.foreverDB then self:_npcFromDB(objectID, true) end
    local def = self.npcs[-objectID]
    if not def then error("mock: TalkToObject: object " .. tostring(objectID) .. " is not defined", 2) end
    return self:TalkTo(-objectID)
end

local RACE_BITS = {
    Human = 1, Orc = 2, Dwarf = 4, NightElf = 8, Scourge = 16, Tauren = 32, Gnome = 64, Troll = 128,
    Goblin = 256,
}

--- Race bit of the player for quest race masks (masks exceed 32 bits: arithmetic only).
function M:PlayerRaceBit()
    local p = self.player
    if p.race == "Skyborne" then
        return (p.faction == "Alliance") and 2 ^ 32 or 2 ^ 33
    end
    return RACE_BITS[p.race]
end

local function hasBit(mask, bitValue)
    if not mask or mask == 0 or not bitValue then return true end
    return math.floor(mask / bitValue) % 2 == 1
end

--- Would the server offer this quest to the player now? (level, prerequisites,
-- exclusive groups, race / class masks, not done / not in the log)
function M:CanTakeQuest(id)
    local def = self:_quest(id)
    if self.completed[id] or self:_logEntry(id) then return false end
    if (def.reqLevel or 1) > self.player.level then return false end
    for _, pre in ipairs(def.pre or {}) do
        if not self.completed[pre] then return false end
    end
    if def.preAny and #def.preAny > 0 then
        local any = false
        for _, pre in ipairs(def.preAny) do if self.completed[pre] then any = true end end
        if not any then return false end
    end
    for _, ex in ipairs(def.exclusive or {}) do
        if self.completed[ex] or self:_logEntry(ex) then return false end
    end
    if not hasBit(def.races, self:PlayerRaceBit()) then return false end
    local classID = self.player.classID
    if def.classes and def.classes ~= 0 and classID and classID > 0 and not hasBit(def.classes, 2 ^ (classID - 1)) then
        return false
    end
    return true
end

---------------------------------------------------------------------------
-- tools/data/forever_db.lua integration (for specs / tools/simulate_routes.lua)
---------------------------------------------------------------------------

--- Use a Forever DB snapshot (tools/data/forever_db.lua table) as the fallback for
-- quests, NPCs, objects and items that the spec did not define explicitly.
-- Objective model: creatures / killCredit / objects / items become counted objectives;
-- `objectives.event` (exploration, escort: an area trigger / scripted event) becomes an
-- "event" objective that stays incomplete until it is fulfilled (CompleteObjectives /
-- ProgressObjective, i.e. the route's `complete` step in tools/simulate_routes.lua).
-- opts.routeCompletes = { [questID] = true }: quests a route completes with a `complete`
-- step. Such a quest WITHOUT any objective in the DB (Forever-new quests whose objectives
-- are not known offline, e.g. 95508) gets one placeholder "event" objective, so it is not
-- complete on accept either; other objective-less quests (deliveries) are complete at once.
function M:UseForeverDB(db, opts)
    self.foreverDB = db
    self._dbRouteCompletes = opts and opts.routeCompletes or {}
    local starts, ends, ostarts, oends = {}, {}, {}, {}
    local function add(index, id, qid)
        index[id] = index[id] or {}
        table.insert(index[id], qid)
    end
    for qid, q in pairs(db.quests or {}) do
        for _, n in ipairs(q.start and q.start.npcs or {}) do add(starts, n, qid) end
        for _, o in ipairs(q.start and q.start.objects or {}) do add(ostarts, o, qid) end
        for _, n in ipairs(q.finish and q.finish.npcs or {}) do add(ends, n, qid) end
        for _, o in ipairs(q.finish and q.finish.objects or {}) do add(oends, o, qid) end
    end
    for _, idx in ipairs({ starts, ends, ostarts, oends }) do
        for _, list in pairs(idx) do table.sort(list) end
    end
    self._dbIndex = { starts = starts, ends = ends, ostarts = ostarts, oends = oends }
    return self
end

function M:_questFromDB(id)
    local db = self.foreverDB
    local q = db.quests and db.quests[id]
    if not q then return nil end
    local ov = q.byClass and q.byClass[self.player.class]
    if ov then
        local merged = {}
        for k, v in pairs(q) do merged[k] = v end
        for k, v in pairs(ov) do merged[k] = v end
        q = merged
    end
    local objectives = {}
    local o = q.objectives or {}
    local function npcName(nid)
        local n = db.npcs and db.npcs[nid]
        return n and n.name or ("NPC " .. tostring(nid))
    end
    for _, c in ipairs(o.creatures or {}) do
        objectives[#objectives + 1] = { text = npcName(c[1]) .. " slain", required = c[2] or 1, type = "monster" }
    end
    for _, k in ipairs(o.killCredit or {}) do
        objectives[#objectives + 1] = { text = npcName(k.base) .. " slain", required = k.count or 1, type = "monster" }
    end
    for _, c in ipairs(o.objects or {}) do
        local ob = db.objects and db.objects[c[1]]
        objectives[#objectives + 1] = { text = ob and ob.name or ("Object " .. c[1]), required = c[2] or 1, type = "object" }
    end
    for _, c in ipairs(o.items or {}) do
        local it = db.items and db.items[c[1]]
        if not self.items[c[1]] then self:DefineItem(c[1], { name = it and it.name or nil }) end
        objectives[#objectives + 1] = { text = it and it.name or ("Item " .. c[1]), required = c[2] or 1,
            type = "item", itemID = c[1] }
    end
    if o.event then
        -- exploration / escort: done only when the event happens (never on accept)
        objectives[#objectives + 1] = { text = q.name .. ": event", required = 1, type = "event" }
    elseif #objectives == 0 and self._dbRouteCompletes[id] then
        -- objectives unknown offline (or not modelled: spell / reputation), but the route has a
        -- `complete` step for the quest
        objectives[#objectives + 1] = { text = q.name .. ": objective (not in the DB)", required = 1,
            type = "event" }
    end
    local zoneName = q.uiMap and self.maps[q.uiMap] and self.maps[q.uiMap].name or "Quests"
    return {
        title = q.name, level = q.level or 1, reqLevel = q.reqLevel or 1, xp = q.xp or 0,
        zone = zoneName, objectives = objectives, pre = q.preGroup, preAny = q.preSingle,
        exclusive = q.exclusive, races = q.races, classes = q.classes,
        repeatable = q.special ~= nil and math.floor(q.special) % 2 == 1 or nil, fromDB = true,
    }
end

function M:_npcFromDB(id, isObject)
    local db = self.foreverDB
    local idx = self._dbIndex
    local rec = isObject and (db.objects and db.objects[id]) or (db.npcs and db.npcs[id])
    local starts = isObject and idx.ostarts[id] or idx.starts[id]
    local ends = isObject and idx.oends[id] or idx.ends[id]
    if not rec and not starts and not ends then return nil end
    local def = {
        name = rec and rec.name or ((isObject and "Object " or "NPC ") .. id),
        level = rec and rec.maxLevel or nil, kind = isObject and "GameObject" or "Creature",
        starts = U.deepcopy(starts or {}), ends = U.deepcopy(ends or {}),
        dbID = id,
    }
    if isObject then
        def.id = -id
        self.npcs[-id] = def
        return def
    end
    return self:DefineNPC(id, def)
end

--- Offer a shared / escort quest (QUEST_ACCEPT_CONFIRM); the addon confirms with ConfirmAcceptQuest().
function M:OfferSharedQuest(id, fromName)
    return self:_top(function()
        self.pendingConfirm = id
        self:_dispatch("QUEST_ACCEPT_CONFIRM", fromName or "Someone", self:_quest(id).title, id)
    end)
end

---------------------------------------------------------------------------
-- installer
---------------------------------------------------------------------------

ctx.register(function(m)
    local opts = m.opts
    m.questDB, m.questCache, m.questLog, m.completed, m.turnedIn = {}, {}, {}, {}, {}
    m.maxQuests = opts.maxQuests or 40
    m.questLogHeaders = opts.questLogHeaders ~= false
    m.watches = {}
    m.dialog = nil
    for _, id in ipairs(opts.completedQuests or {}) do m.completed[id] = true end

    local function dialog(mode)
        local d = m.dialog
        if d and (mode == nil or d.mode == mode) then return d end
        return nil
    end
    local function dialogQuestID()
        local d = m.dialog
        if d and d.questID then return d.questID end
        return nil
    end

    -- C_QuestLog -------------------------------------------------------------
    local function info(e, index)
        if e.isHeader then
            return {
                title = e.title, questLogIndex = index, questID = 0, level = 0, difficultyLevel = 0,
                suggestedGroup = 0, frequency = 0, isHeader = true, useMinimalHeader = false,
                sortAsNormalQuest = false, isCollapsed = false, startEvent = false, isTask = false,
                isBounty = false, isStory = false, isScaling = false, isOnMap = false, hasLocalPOI = false,
                isHidden = false, isAutoComplete = false, overridesSortOrder = false,
                readyForTranslation = true, isInternalOnly = false, isAbandonOnDisable = false,
                questClassification = (A.enums.QuestClassification or {}).Normal or 7,
            }
        end
        local def = m:_quest(e.questID)
        return {
            title = def.title, questLogIndex = index, questID = e.questID, campaignID = nil,
            level = def.level, difficultyLevel = def.level, suggestedGroup = def.group or 0,
            frequency = def.frequency or 0, isHeader = false, useMinimalHeader = false,
            sortAsNormalQuest = false, isCollapsed = false, startEvent = false, isTask = false,
            isBounty = false, isStory = false, isScaling = false, isOnMap = true, hasLocalPOI = false,
            isHidden = false, isAutoComplete = def.isAutoComplete or false, overridesSortOrder = false,
            readyForTranslation = true, isInternalOnly = false, isAbandonOnDisable = false,
            headerSortKey = nil, questClassification = (A.enums.QuestClassification or {}).Normal or 7,
        }
    end
    local function objectivesOf(e)
        local out = {}
        for i, o in ipairs(e.objectives) do
            out[i] = { text = objectiveText(o), type = o.type, finished = objFinished(o) and true or false,
                numFulfilled = o.fulfilled, numRequired = o.required, objectiveType = o.objectiveType }
        end
        return out
    end
    local function requestQuest(id)
        if m.questCache[id] or m._questLoads[id] then return end
        m._questLoads[id] = true
        m:_after(0, function()
            m._questLoads[id] = nil
            m.questCache[id] = true
            m:_quest(id)
            m:_dispatch("QUEST_DATA_LOAD_RESULT", id, true)
        end)
    end
    m._questLoads = {}

    m:ProvideNS("C_QuestLog", {
        GetNumQuestLogEntries = function()
            return #m:_entries(), #m.questLog
        end,
        GetInfo = function(index)
            local e = m:_entries()[index]
            if not e then return nil end
            return info(e, index)
        end,
        GetLogIndexForQuestID = function(id)
            for i, e in ipairs(m:_entries()) do
                if not e.isHeader and e.questID == id then return i end
            end
            return nil
        end,
        GetQuestIDForLogIndex = function(index)
            local e = m:_entries()[index]
            if not e then return nil end
            return e.questID
        end,
        GetTitleForLogIndex = function(index)
            local e = m:_entries()[index]
            if not e then return nil end
            return e.isHeader and e.title or m:_quest(e.questID).title
        end,
        IsOnQuest = function(id) return m:_logEntry(id) ~= nil end,
        IsComplete = function(id)
            local e = m:_logEntry(id)
            return e ~= nil and m:_isComplete(e)
        end,
        IsFailed = function(id)
            local e = m:_logEntry(id)
            return e ~= nil and e.failed == true
        end,
        ReadyForTurnIn = function(id)
            local e = m:_logEntry(id)
            return e ~= nil and m:_isComplete(e)
        end,
        IsQuestFlaggedCompleted = function(id) return m.completed[id] == true end,
        GetAllCompletedQuestIDs = function()
            local out = U.sortedKeys(m.completed)
            return out
        end,
        GetQuestObjectives = function(id)
            local e = m:_logEntry(id)
            if not e then return nil end
            return objectivesOf(e)
        end,
        GetNumQuestObjectives = function(id)
            local e = m:_logEntry(id)
            if e then return #e.objectives end
            local def = m.questDB[id]
            return def and #def.objectives or 0
        end,
        GetTitleForQuestID = function(id)
            if not m.questCache[id] then return nil end
            return m:_quest(id).title
        end,
        RequestLoadQuestByID = function(id) requestQuest(id) end,
        GetMaxNumQuestsCanAccept = function() return m.maxQuests end,
        GetMaxNumQuests = function() return m.maxQuests end,
        GetQuestDifficultyLevel = function(id) return m:_quest(id).level end,
        IsQuestTrivial = function(id) return m:_isTrivial(m:_quest(id)) end,
        GetTrivialRange = function() return m:TrivialRange() end,
        IsRepeatableQuest = function(id) return m:_quest(id).repeatable == true end,
        GetRequiredMoney = function(id) return m:_quest(id).moneyRequired or 0 end,
        GetSuggestedGroupSize = function(id) return m:_quest(id).group or 0 end,
        GetQuestTagInfo = function() return nil end,
        GetNextWaypoint = function() return nil end,
        GetSelectedQuest = function() return m.selectedQuest or 0 end,
        SetSelectedQuest = function(id) m.selectedQuest = id end,
        CanAbandonQuest = function(id) return m:_logEntry(id) ~= nil end,
        SetAbandonQuest = function() m.abandonQuest = m.selectedQuest end,
        GetAbandonQuest = function() return m.abandonQuest or 0 end,
        AbandonQuest = function()
            local id = m.abandonQuest
            m.abandonQuest = nil
            m:_action("AbandonQuest", id)
            if id then m:_serverAbandon(id) end
        end,
        AddQuestWatch = function(id)
            if not m:_logEntry(id) or m.watches[id] then return false end
            m.watches[id] = true
            m:_dispatch("QUEST_WATCH_LIST_CHANGED", id, true)
            return true
        end,
        RemoveQuestWatch = function(id)
            if not m.watches[id] then return false end
            m.watches[id] = nil
            m:_dispatch("QUEST_WATCH_LIST_CHANGED", id, false)
            return true
        end,
        GetNumQuestWatches = function() return #U.sortedKeys(m.watches) end,
        GetQuestIDForQuestWatchIndex = function(i) return U.sortedKeys(m.watches)[i] end,
    })

    -- legacy quest log globals -------------------------------------------------
    m:ProvideAPI("GetQuestLogRewardXP", function(id)
        id = id or m.selectedQuest
        if not id or not m:_logEntry(id) then return 0 end
        return m:QuestRewardXP(id)
    end)
    m:ProvideAPI("GetQuestLogRewardMoney", function(id)
        id = id or m.selectedQuest
        if not id or not m:_logEntry(id) then return 0 end
        return m:_quest(id).money or 0
    end)
    m:ProvideAPI("GetNumQuestLeaderBoards", function(index)
        local e = m:_entries()[index or 0]
        if not e or e.isHeader then return 0 end
        return #e.objectives
    end)
    m:ProvideAPI("GetQuestLogLeaderBoard", function(i, index)
        local e = m:_entries()[index or 0]
        local o = e and not e.isHeader and e.objectives[i]
        if not o then return nil end
        return objectiveText(o), o.type, objFinished(o) and true or false
    end)
    m:ProvideAPI("GetQuestObjectiveInfo", function(id, i)
        local e = m:_logEntry(id)
        local o = e and e.objectives[i]
        if not o then return nil end
        return objectiveText(o), o.type, objFinished(o) and true or false, o.fulfilled, o.required
    end)
    m:ProvideAPI("HaveQuestData", function(id) return m.questCache[id] == true end)
    m:ProvideAPI("IsQuestSequenced", function() return false end)

    -- quest dialog globals -------------------------------------------------------
    m:ProvideAPI("GetQuestID", function() return dialogQuestID() or 0 end)
    m:ProvideAPI("GetTitleText", function()
        local id = dialogQuestID()
        return id and m:_quest(id).title or ""
    end)
    m:ProvideAPI("GetQuestText", function()
        local id = dialogQuestID()
        return id and (m:_quest(id).detailText or "") or ""
    end)
    m:ProvideAPI("GetObjectiveText", function()
        local id = dialogQuestID()
        return id and (m:_quest(id).objectiveText or "") or ""
    end)
    m:ProvideAPI("GetProgressText", function()
        local id = dialogQuestID()
        return id and (m:_quest(id).progressText or "") or ""
    end)
    m:ProvideAPI("GetRewardText", function()
        local id = dialogQuestID()
        return id and (m:_quest(id).rewardText or "") or ""
    end)
    m:ProvideAPI("GetGreetingText", function()
        local d = dialog("greeting")
        return d and (d.spec.text or "") or ""
    end)
    m:ProvideAPI("QuestGetAutoAccept", function()
        local id = dialogQuestID()
        return id ~= nil and m:_quest(id).autoAccept == true
    end)
    m:ProvideAPI("QuestIsFromAreaTrigger", function()
        local id = dialogQuestID()
        return id ~= nil and m:_quest(id).areaTrigger == true
    end)
    m:ProvideAPI("QuestFlagsPVP", function()
        local id = dialogQuestID()
        return id ~= nil and m:_quest(id).pvp == true
    end)

    local function accept(apiName)
        local d = dialog("detail")
        m:_action(apiName, d and d.questID)
        if not d then
            m:_warn(apiName .. "() called without an open quest offer (QUEST_DETAIL)")
            return
        end
        local id = d.questID
        if (m.serverDelay or 0) > 0 then
            finishQuestFrame(m, false)
            m:_server(function() m:_serverAccept(id) end)
            return
        end
        local ok = m:_serverAccept(id)
        finishQuestFrame(m, ok)
    end
    m:ProvideAPI("AcceptQuest", function() accept("AcceptQuest") end)
    m:ProvideAPI("AcknowledgeAutoAcceptQuest", function() accept("AcknowledgeAutoAcceptQuest") end)
    m:ProvideAPI("ConfirmAcceptQuest", function()
        local id = m.pendingConfirm
        m:_action("ConfirmAcceptQuest", id)
        m.pendingConfirm = nil
        if id then m:_server(function() m:_serverAccept(id) end) end
    end)
    m:ProvideAPI("DeclineQuest", function()
        local d = dialog("detail")
        m:_action("DeclineQuest", d and d.questID)
        if not d then m:_warn("DeclineQuest() without an open quest offer"); return end
        finishQuestFrame(m, false)
    end)
    m:ProvideAPI("CloseQuest", function()
        m:_action("CloseQuest")
        if m.interaction and (m.interaction.questFrame or (m.dialog and m.dialog.mode ~= "gossip")) then
            finishQuestFrame(m, false)
        end
    end)
    m:ProvideAPI("IsQuestCompletable", function()
        local d = dialog("progress")
        if not d then return false end
        local e = m:_logEntry(d.questID)
        return e ~= nil and m:_isComplete(e)
    end)
    m:ProvideAPI("CompleteQuest", function()
        local d = dialog("progress")
        m:_action("CompleteQuest", d and d.questID)
        if not d then m:_warn("CompleteQuest() without an open QUEST_PROGRESS dialog"); return end
        local e = m:_logEntry(d.questID)
        if not e or not m:_isComplete(e) then
            m:_warn("CompleteQuest(): quest " .. d.questID .. " is not completable")
            return
        end
        m:_openComplete(d.questID, { parent = d.parent })
    end)
    local function rewardList(kind)
        local id = dialogQuestID()
        if not id then return {} end
        local def = m:_quest(id)
        if kind == "choice" then return def.choices or {} end
        if kind == "reward" then return def.rewards or {} end
        if kind == "required" then
            local out = {}
            for _, o in ipairs(def.objectives) do
                if o.itemID then out[#out + 1] = { o.itemID, o.required } end
            end
            return out
        end
        return {}
    end
    m:ProvideAPI("GetNumQuestChoices", function()
        if not dialog("complete") then return 0 end
        return #rewardList("choice")
    end)
    m:ProvideAPI("GetNumQuestRewards", function()
        if not dialog("complete") and not dialog("detail") then return 0 end
        return #rewardList("reward")
    end)
    m:ProvideAPI("GetNumQuestItems", function() return #rewardList("required") end)
    m:ProvideAPI("GetQuestItemInfo", function(kind, i)
        if type(kind) ~= "string" or type(i) ~= "number" then
            m:_violation("GetQuestItemInfo(type, index): bad arguments", 3)
        end
        local r = rewardList(kind)[i]
        if not r then return nil end
        local itemID, count = r, 1
        if type(r) == "table" then itemID, count = r[1] or r.itemID, r[2] or r.count or 1 end
        local def = m.items[itemID] or m:DefineItem(itemID, {})
        return def.name, def.icon, count, def.quality, true, itemID, 0
    end)
    m:ProvideAPI("GetQuestItemLink", function(kind, i)
        local r = rewardList(kind)[i]
        if not r then return nil end
        local itemID = type(r) == "table" and (r[1] or r.itemID) or r
        return m:_itemLink(itemID)
    end)
    m:ProvideAPI("GetRewardXP", function()
        local id = dialogQuestID()
        return id and m:QuestRewardXP(id) or 0
    end)
    m:ProvideAPI("GetRewardMoney", function()
        local id = dialogQuestID()
        return id and (m:_quest(id).money or 0) or 0
    end)
    m:ProvideAPI("GetQuestMoneyToGet", function()
        local id = dialogQuestID()
        return id and (m:_quest(id).moneyRequired or 0) or 0
    end)
    m:ProvideAPI("GetQuestReward", function(choice)
        local d = dialog("complete")
        m:_action("GetQuestReward", d and d.questID, choice)
        if not d then m:_warn("GetQuestReward() without an open QUEST_COMPLETE dialog"); return end
        local n = #rewardList("choice")
        if n > 0 and (type(choice) ~= "number" or choice < 1 or choice > n) then
            m:_warn(("GetQuestReward(%s): a reward choice 1..%d is required"):format(tostring(choice), n))
            return
        end
        local e = m:_logEntry(d.questID)
        if not e or not m:_isComplete(e) then
            m:_warn("GetQuestReward(): quest " .. d.questID .. " is not complete")
            return
        end
        local id = d.questID
        if (m.serverDelay or 0) > 0 then
            finishQuestFrame(m, false)
            m:_server(function() m:_serverTurnIn(id, n > 0 and choice or 0) end)
            return
        end
        m:_serverTurnIn(id, n > 0 and choice or 0)
        finishQuestFrame(m, true)
    end)

    -- quest greeting (index based) -------------------------------------------------
    local function greetingLists()
        local d = dialog("greeting")
        if not d then return {}, {} end
        return npcQuestLists(m, d.spec)
    end
    m:ProvideAPI("GetNumActiveQuests", function() local _, act = greetingLists(); return #act end)
    m:ProvideAPI("GetNumAvailableQuests", function() local av = greetingLists(); return #av end)
    m:ProvideAPI("GetActiveTitle", function(i)
        local _, act = greetingLists()
        local id = act[i]
        if not id then return nil end
        local e = m:_logEntry(id)
        return m:_quest(id).title, e ~= nil and m:_isComplete(e)
    end)
    m:ProvideAPI("GetActiveLevel", function(i)
        local _, act = greetingLists()
        return act[i] and m:_quest(act[i]).level or 0
    end)
    m:ProvideAPI("GetActiveQuestID", function(i)
        local _, act = greetingLists()
        return act[i] or 0
    end)
    m:ProvideAPI("IsActiveQuestTrivial", function(i)
        local _, act = greetingLists()
        return act[i] ~= nil and m:_isTrivial(m:_quest(act[i]))
    end)
    m:ProvideAPI("GetAvailableTitle", function(i)
        local av = greetingLists()
        return av[i] and m:_quest(av[i]).title or nil
    end)
    m:ProvideAPI("GetAvailableLevel", function(i)
        local av = greetingLists()
        return av[i] and m:_quest(av[i]).level or 0
    end)
    m:ProvideAPI("GetAvailableQuestInfo", function(i)
        local av = greetingLists()
        local id = av[i]
        if not id then return nil end
        local def = m:_quest(id)
        return m:_isTrivial(def), def.frequency or 0, def.repeatable or false, false, id, false, false, id
    end)
    m:ProvideAPI("IsAvailableQuestTrivial", function(i)
        local av = greetingLists()
        return av[i] ~= nil and m:_isTrivial(m:_quest(av[i]))
    end)
    m:ProvideAPI("SelectActiveQuest", function(i)
        local d = dialog("greeting")
        local _, act = greetingLists()
        m:_action("SelectActiveQuest", i, act[i])
        if not d or not act[i] then
            m:_warn("SelectActiveQuest(" .. tostring(i) .. "): no such greeting entry (argument is a list INDEX)")
            return
        end
        m:_openProgressOrComplete(act[i], { parent = { kind = "greeting", spec = d.spec, npcID = d.npcID, npc = d.npc } })
    end)
    m:ProvideAPI("SelectAvailableQuest", function(i)
        local d = dialog("greeting")
        local av = greetingLists()
        m:_action("SelectAvailableQuest", i, av[i])
        if not d or not av[i] then
            m:_warn("SelectAvailableQuest(" .. tostring(i) .. "): no such greeting entry (argument is a list INDEX)")
            return
        end
        m:_openDetail(av[i], { parent = { kind = "greeting", spec = d.spec, npcID = d.npcID, npc = d.npc } })
    end)

    -- gossip -------------------------------------------------------------------------
    local function gossipLists()
        local d = dialog("gossip")
        if not d then return {}, {}, nil end
        local av, act = npcQuestLists(m, d.spec)
        return av, act, d
    end
    local function gossipOptions(d)
        local out = {}
        for i, o in ipairs(d and d.spec.options or {}) do
            out[#out + 1] = {
                gossipOptionID = o.gossipOptionID or (1000 + i), name = o.name or ("Option " .. i),
                icon = o.icon or 132053, rewards = {}, status = o.status or 0, spellID = o.spellID,
                flags = o.flags or 0, overrideIconID = nil, selectOptionWhenOnlyOption = o.selectOptionWhenOnlyOption or false,
                orderIndex = o.orderIndex or (i - 1), failureDescription = nil,
            }
        end
        return out
    end
    local function runOption(d, idx)
        local o = d.spec.options[idx]
        local npcID = d.npcID
        local t = o.type
        if type(o.onSelect) == "function" then
            o.onSelect(m, o)
        elseif t == "taxi" then
            closeGossipFrame(m, true)
            m.dialog = nil
            m:_endInteraction()
            m:OpenTaxi(o.nodes, npcID, o.taxiMapID)
        elseif t == "trainer" then
            closeGossipFrame(m, true)
            m.dialog = nil
            m:_endInteraction()
            m:OpenTrainer(o.trainer, npcID)
        elseif t == "vendor" then
            closeGossipFrame(m, true)
            m.dialog = nil
            m:_endInteraction()
            m:OpenMerchant(o.merchant, npcID)
        elseif t == "binder" then
            closeGossipFrame(m, true)
            m.dialog = nil
            m:_endInteraction()
            local b = o.bind or {}
            m:OpenBinder(b.name or "Inn", npcID, b.mapID, b.x, b.y)
        else
            closeGossipFrame(m, false)
            m.dialog = nil
            m:_endInteraction()
        end
    end
    m:ProvideNS("C_GossipInfo", {
        GetAvailableQuests = function()
            local av = gossipLists()
            local out = {}
            for _, id in ipairs(av) do out[#out + 1] = questUIInfo(m, id, false) end
            return out
        end,
        GetActiveQuests = function()
            local _, act = gossipLists()
            local out = {}
            for _, id in ipairs(act) do out[#out + 1] = questUIInfo(m, id, true) end
            return out
        end,
        GetNumAvailableQuests = function() local av = gossipLists(); return #av end,
        GetNumActiveQuests = function() local _, act = gossipLists(); return #act end,
        SelectAvailableQuest = function(questID)
            local av, _, d = gossipLists()
            m:_action("C_GossipInfo.SelectAvailableQuest", questID)
            local found = false
            for _, id in ipairs(av) do if id == questID then found = true end end
            if not found then
                m:_warn("C_GossipInfo.SelectAvailableQuest(" .. tostring(questID) .. "): not offered (argument is a QUEST ID)")
                return
            end
            m:_openDetail(questID, { parent = { kind = "gossip", spec = d.spec, npcID = d.npcID, npc = d.npc } })
        end,
        SelectActiveQuest = function(questID)
            local _, act, d = gossipLists()
            m:_action("C_GossipInfo.SelectActiveQuest", questID)
            local found = false
            for _, id in ipairs(act) do if id == questID then found = true end end
            if not found then
                m:_warn("C_GossipInfo.SelectActiveQuest(" .. tostring(questID) .. "): not listed (argument is a QUEST ID)")
                return
            end
            m:_openProgressOrComplete(questID, { parent = { kind = "gossip", spec = d.spec, npcID = d.npcID, npc = d.npc } })
        end,
        GetOptions = function()
            local _, _, d = gossipLists()
            return gossipOptions(d)
        end,
        SelectOption = function(optionID)
            local _, _, d = gossipLists()
            m:_action("C_GossipInfo.SelectOption", optionID)
            for i, o in ipairs(gossipOptions(d)) do
                if o.gossipOptionID == optionID then runOption(d, i); return end
            end
            m:_warn("C_GossipInfo.SelectOption(" .. tostring(optionID) .. "): unknown gossipOptionID")
        end,
        SelectOptionByIndex = function(orderIndex)
            local _, _, d = gossipLists()
            m:_action("C_GossipInfo.SelectOptionByIndex", orderIndex)
            for i, o in ipairs(gossipOptions(d)) do
                if o.orderIndex == orderIndex then runOption(d, i); return end
            end
            m:_warn("C_GossipInfo.SelectOptionByIndex(" .. tostring(orderIndex) .. "): unknown orderIndex")
        end,
        GetText = function()
            local _, _, d = gossipLists()
            return d and (d.spec.text or "") or ""
        end,
        CloseGossip = function()
            m:_action("C_GossipInfo.CloseGossip")
            if dialog("gossip") then
                m.dialog = nil
                closeGossipFrame(m, false)
                m:_endInteraction()
            end
        end,
        ForceGossip = function() return false end,
    })
end)
