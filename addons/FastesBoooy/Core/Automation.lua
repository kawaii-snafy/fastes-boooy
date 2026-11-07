-- FastesBoooy / Core / Automation.lua
--
-- Quest automation for ROUTE quests only:
--   * accept   (QUEST_DETAIL, gossip / greeting lists): quests of `accept`
--              actions in the steps [cursor, cursor + lookahead] plus the active
--              background steps (ns.Engine:GetAcceptQuests());
--   * turn in  (QUEST_PROGRESS / QUEST_COMPLETE, gossip / greeting lists): any
--              `turnin` quest of the route once it is complete
--              (ns.Engine:GetTurninQuests());
--   * reward   step `reward = { [questID] = index }`, else automatic only with
--              <= 1 choice, else stop + chat hint (+ ns:Fire("REWARD_CHOICE_NEEDED", questID, n));
--   * gossip   turn-ins first, then accepts (by quest id); QUEST_GREETING by list
--              index; then the current step's `gossip` option when the gossip
--              NPC's id is one of step.npc (at most once per step per 10 s);
--   * holding Shift (IsShiftKeyDown) suspends everything; Shift held when a
--     dialog window opens (GOSSIP_SHOW / QUEST_GREETING / QUEST_DETAIL /
--     QUEST_PROGRESS / QUEST_COMPLETE) suspends the automation for the whole
--     dialog with that NPC, even after Shift is released: until GOSSIP_CLOSED
--     (interaction not continuing) or QUEST_FINISHED, and also for the NPC's
--     gossip shown again right after its quest window (REOPEN_GRACE);
--   * the settings flags automation / autoAccept / autoTurnin / autoGossip are
--     honoured; nothing is done during combat lockdown or without an active route.
-- All game calls go through ns.Compat.

local _, ns = ...
-- luacheck: ignore 212/self

local ipairs, type = ipairs, type

local Automation = {
    gossipDone = {},       -- [stepId] = GetTime() of the last automatic gossip option
    suspended = nil,       -- { npc = npcID | false }: Shift was held when the current dialog opened
    lastSuspended = nil,   -- { npc = npcID, at = GetTime() }: a suspended dialog that just closed
}
ns.Automation = Automation

local GOSSIP_REPEAT_DELAY = 10
local REOPEN_GRACE = 3 -- seconds: the same NPC's gossip coming back after its quest window

local function settings()
    return ns.db and ns.db.settings or {}
end

local function L() return ns.L end

local function now()
    return GetTime and GetTime() or 0
end

local function shiftDown()
    return (IsShiftKeyDown and IsShiftKeyDown()) and true or false
end

--- Is automation suspended (disabled in the settings, Shift held, or the
-- current dialog was opened with Shift held)?
function Automation:IsSuspended()
    if not settings().automation then return true end
    if shiftDown() then return true end
    if self.suspended then return true end
    return false
end

--- A dialog window opened (called first by every dialog handler): decides
-- whether the automation stays suspended for this dialog.
function Automation:NoteDialog()
    local npc = ns.Compat.GetNpcIdFromUnit("npc") or false
    local s = self.suspended
    if s and s.npc ~= npc then s = nil end -- another NPC: a new dialog
    if not s then
        local last = self.lastSuspended
        if last and npc and last.npc == npc and (now() - last.at) <= REOPEN_GRACE then
            s = { npc = npc } -- the NPC's gossip came back after its quest window: same dialog
        end
    end
    if not s and shiftDown() then s = { npc = npc } end
    self.suspended = s
    self.lastSuspended = nil
end

--- The dialog window closed (GOSSIP_CLOSED without continuation, QUEST_FINISHED).
function Automation:EndDialog()
    local s = self.suspended
    if not s then return end
    self.suspended = nil
    self.lastSuspended = s.npc and { npc = s.npc, at = now() } or nil
end

-- Common gate for every automatic action.
function Automation:CanAct()
    if self:IsSuspended() then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    local E = ns.Engine
    if not (E and E.started and E:GetRoute()) then return false end
    return true
end

local function questTitle(q)
    return ns.Compat.GetDialogTitle() or ns.Steps:QuestTitle(q)
end

local function contains(list, v)
    if type(list) ~= "table" then return list == v end
    for _, x in ipairs(list) do
        if x == v then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- quest dialog
---------------------------------------------------------------------------

function Automation:OnQuestDetail(questStartItemID)
    if not self:CanAct() or not settings().autoAccept then return end
    local C = ns.Compat
    -- item-started offers and area-trigger auto quests become Blizzard popups
    if not C.IsSecret(questStartItemID) and type(questStartItemID) == "number" and questStartItemID ~= 0 then
        return
    end
    if C.IsDialogAreaTriggerAuto() then return end
    local q = C.GetDialogQuestID()
    if not q or not ns.Engine:GetAcceptQuests()[q] then return end
    if C.IsDialogQuestPvP() then
        ns.Print(L().MSG_PVP_QUEST, questTitle(q))
        return
    end
    local count, maxQuests = C.GetNumQuestsInLog(), C.GetMaxQuests()
    if count >= maxQuests then
        ns.Print(L().MSG_QUEST_LOG_FULL, count, maxQuests, questTitle(q))
        return
    end
    ns.Debug("auto-accept", q)
    C.AcceptDialogQuest()
end

function Automation:OnQuestProgress()
    if not self:CanAct() or not settings().autoTurnin then return end
    local C = ns.Compat
    local q = C.GetDialogQuestID()
    if not q or not ns.Engine:GetTurninQuests()[q] then return end
    if C.IsDialogQuestCompletable() then
        ns.Debug("auto-complete", q)
        C.CompleteDialogQuest()
    end
end

function Automation:OnQuestComplete()
    if not self:CanAct() or not settings().autoTurnin then return end
    local C = ns.Compat
    local q = C.GetDialogQuestID()
    if not q or not ns.Engine:GetTurninQuests()[q] then return end
    if C.GetDialogMoneyRequired() > 0 then
        ns.Print(L().MSG_QUEST_COSTS_MONEY, questTitle(q))
        return
    end
    local n = C.GetNumRewardChoices()
    local choice = ns.Engine:GetRewardChoice(q)
    if type(choice) == "number" and choice >= 1 and choice <= n then
        ns.Debug("auto-reward", q, choice)
        C.ChooseReward(choice)
    elseif n <= 1 then
        ns.Debug("auto-reward", q, n)
        C.ChooseReward(n) -- 1 = the only choice, 0 = no choice
    else
        ns.Print(L().MSG_CHOOSE_REWARD, questTitle(q))
        ns:Fire("REWARD_CHOICE_NEEDED", q, n)
    end
end

function Automation:OnQuestGreeting()
    if not self:CanAct() then return end
    local C = ns.Compat
    local s = settings()
    if s.autoTurnin then
        local turnins = ns.Engine:GetTurninQuests()
        for _, info in ipairs(C.GetGreetingActiveQuests()) do
            local q = info.questID
            if q and turnins[q] and (info.isComplete or C.IsQuestComplete(q)) then
                ns.Debug("greeting turn-in", q)
                C.SelectGreetingActive(info.index)
                return
            end
        end
    end
    if s.autoAccept then
        local accepts = ns.Engine:GetAcceptQuests()
        for _, info in ipairs(C.GetGreetingAvailableQuests()) do
            if info.questID and accepts[info.questID] then
                ns.Debug("greeting accept", info.questID)
                C.SelectGreetingAvailable(info.index)
                return
            end
        end
    end
end

---------------------------------------------------------------------------
-- gossip
---------------------------------------------------------------------------

function Automation:GossipNpcMatches(step)
    if not step.npc then return false end
    local C = ns.Compat
    local id = C.GetNpcIdFromUnit("npc") or C.GetNpcIdFromUnit("target")
    return id ~= nil and contains(step.npc, id)
end

function Automation:OnGossipShow()
    if not self:CanAct() then return end
    local C = ns.Compat
    local s = settings()
    if s.autoTurnin then
        local turnins = ns.Engine:GetTurninQuests()
        for _, info in ipairs(C.GetGossipActiveQuests()) do
            local q = info.questID
            if q and turnins[q] and (info.isComplete or C.IsQuestComplete(q)) then
                ns.Debug("gossip turn-in", q)
                C.SelectGossipActive(q)
                return
            end
        end
    end
    if s.autoAccept then
        local accepts = ns.Engine:GetAcceptQuests()
        for _, info in ipairs(C.GetGossipAvailableQuests()) do
            if info.questID and accepts[info.questID] then
                ns.Debug("gossip accept", info.questID)
                C.SelectGossipAvailable(info.questID)
                return
            end
        end
    end
    if s.autoGossip then
        local step = ns.Engine:GetCurrentStep()
        if step and step.gossip and self:GossipNpcMatches(step) then
            local t = now()
            local last = self.gossipDone[step.id]
            if last and (t - last) < GOSSIP_REPEAT_DELAY then return end
            local option = C.GetGossipOptions()[step.gossip]
            if option then
                self.gossipDone[step.id] = t
                ns.Debug("gossip option", step.gossip, step.id)
                C.SelectGossipOption(option)
            end
        end
    end
end

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------

ns:On("QUEST_DETAIL", function(_, questStartItemID)
    Automation:NoteDialog()
    Automation:OnQuestDetail(questStartItemID)
end)
ns:On("QUEST_PROGRESS", function()
    Automation:NoteDialog()
    Automation:OnQuestProgress()
end)
ns:On("QUEST_COMPLETE", function()
    Automation:NoteDialog()
    Automation:OnQuestComplete()
end)
ns:On("QUEST_GREETING", function()
    Automation:NoteDialog()
    Automation:OnQuestGreeting()
end)
ns:On("GOSSIP_SHOW", function()
    Automation:NoteDialog()
    Automation:OnGossipShow()
end)
ns:On("GOSSIP_CLOSED", function(_, interactionIsContinuing)
    -- true while the NPC interaction moves on to its quest window (same dialog)
    if interactionIsContinuing == true then return end
    Automation:EndDialog()
end)
ns:On("QUEST_FINISHED", function() Automation:EndDialog() end)
