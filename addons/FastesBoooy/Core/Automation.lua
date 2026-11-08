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
--   * delay    every automatic action is scheduled (C_Timer.After) settings.autoDelay
--              seconds + a random 0..settings.autoDelayJitter after its dialog event,
--              like a player reading the window (autoDelay 0 = at once, in the event
--              handler, jitter ignored). When the timer fires, the action is planned
--              again from the open window and runs only if it is still the same action
--              of the same window: the dialog token (+1 on every dialog window open /
--              close event) is unchanged, the window shows the same quest / list entry /
--              option, the automation is not suspended (Shift, settings), no combat
--              lockdown, the quest still qualifies (route window, completable, reward
--              rule). Otherwise it is dropped silently. At most one action waits: a new
--              dialog event replaces it (a duplicate event re-plans the same action);
--   * holding Shift (IsShiftKeyDown) suspends everything; Shift held when a
--     dialog window opens (GOSSIP_SHOW / QUEST_GREETING / QUEST_DETAIL /
--     QUEST_PROGRESS / QUEST_COMPLETE) suspends the automation for the whole
--     dialog with that NPC, even after Shift is released: until GOSSIP_CLOSED
--     (interaction not continuing) or QUEST_FINISHED, and also for the NPC's
--     gossip shown again right after its quest window (REOPEN_GRACE); Shift
--     pressed while an action waits for its delay cancels it and suspends the
--     rest of the dialog the same way;
--   * the settings flags automation / autoAccept / autoTurnin / autoGossip are
--     honoured; nothing is done during combat lockdown or without an active route.
-- All game calls go through ns.Compat.

local _, ns = ...
-- luacheck: ignore 212/self

local ipairs, type, tostring = ipairs, type, tostring
local format = string.format
local random = math.random

local Automation = {
    gossipDone = {},       -- [stepId] = GetTime() of the last automatic gossip option
    suspended = nil,       -- { npc = npcID | false }: Shift was held when the current dialog opened
    lastSuspended = nil,   -- { npc = npcID, at = GetTime() }: a suspended dialog that just closed
    serial = 0,            -- dialog token: +1 on every dialog window open / close event
    pending = nil,         -- the scheduled action: { serial, key, frame, planner, arg, due }
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
-- delay / scheduling
---------------------------------------------------------------------------

--- Seconds to wait before an automatic action: autoDelay + random 0..autoDelayJitter
-- (ranges: ns.SETTING_RANGES). 0 = act at once (autoDelay 0 ignores the jitter).
function Automation:GetDelay()
    local s = settings()
    local delay = ns.ClampSetting("autoDelay", s.autoDelay)
    if delay <= 0 then return 0 end
    local jitter = ns.ClampSetting("autoDelayJitter", s.autoDelayJitter)
    if jitter > 0 then delay = delay + jitter * random() end
    return delay
end

--- A dialog window opened or closed: the dialog token moves on and the scheduled
-- action is dropped. keep = "quest": an action of the quest window survives (a
-- continuing GOSSIP_CLOSED may come after the quest window's own event).
function Automation:NextDialogToken(keep)
    self.serial = self.serial + 1
    local p = self.pending
    if p and keep and p.frame == keep then
        p.serial = self.serial
    else
        self.pending = nil
    end
end

--- Do the action `planner` finds in the open window: at once when there is no
-- delay, else after GetDelay() seconds if planning again then yields the same action.
-- planner(self, quiet, arg) -> { key = "<what> <id>", run = fn } | nil; quiet = the
-- re-check of a scheduled action (no chat hints). frame = "quest" | "gossip".
function Automation:Act(frame, planner, arg)
    local action = planner(self, false, arg)
    if not action then return end
    local delay = self:GetDelay()
    if delay <= 0 or not (C_Timer and C_Timer.After) then
        action.run()
        return
    end
    local p = self.pending
    if p and p.serial == self.serial and p.key == action.key then return end -- already scheduled
    p = { serial = self.serial, key = action.key, frame = frame, planner = planner, arg = arg,
        due = now() + delay }
    self.pending = p
    ns.Debug("auto: in", format("%.2f s:", delay), action.key)
    C_Timer.After(delay, function() self:RunPending(p) end)
end

--- Timer of a scheduled action: re-validate everything, then act or drop it silently.
function Automation:RunPending(p)
    if self.pending ~= p then return end -- replaced / cancelled (dialog event, Shift)
    self.pending = nil
    if p.serial ~= self.serial then return end
    local action = p.planner(self, true, p.arg)
    if action and action.key == p.key then
        action.run()
    else
        ns.Debug("auto: dropped", p.key)
    end
end

--- Shift pressed: an action waiting for its delay is cancelled and the automation
-- stays suspended for the rest of this dialog (as if Shift was held when it opened).
function Automation:OnShiftDown()
    if not self.pending then return end
    self.pending = nil
    self.suspended = self.suspended or { npc = ns.Compat.GetNpcIdFromUnit("npc") or false }
    ns.Debug("auto: cancelled (Shift)")
end

--- The action waiting for its delay: { key = "<what> <id>", due = GetTime() it fires } or nil.
function Automation:GetPending()
    local p = self.pending
    if not p then return nil end
    return { key = p.key, due = p.due }
end

local function action(key, run)
    return { key = key, run = run }
end

---------------------------------------------------------------------------
-- quest dialog
---------------------------------------------------------------------------

function Automation:PlanQuestDetail(quiet, questStartItemID)
    if not self:CanAct() or not settings().autoAccept then return nil end
    local C = ns.Compat
    -- item-started offers and area-trigger auto quests become Blizzard popups
    if not C.IsSecret(questStartItemID) and type(questStartItemID) == "number" and questStartItemID ~= 0 then
        return nil
    end
    if C.IsDialogAreaTriggerAuto() then return nil end
    local q = C.GetDialogQuestID()
    if not q or not ns.Engine:GetAcceptQuests()[q] then return nil end
    if C.IsDialogQuestPvP() then
        if not quiet then ns.Print(L().MSG_PVP_QUEST, questTitle(q)) end
        return nil
    end
    local count, maxQuests = C.GetNumQuestsInLog(), C.GetMaxQuests()
    if count >= maxQuests then
        if not quiet then ns.Print(L().MSG_QUEST_LOG_FULL, count, maxQuests, questTitle(q)) end
        return nil
    end
    return action("accept " .. q, function()
        ns.Debug("auto-accept", q)
        C.AcceptDialogQuest()
    end)
end

function Automation:PlanQuestProgress()
    if not self:CanAct() or not settings().autoTurnin then return nil end
    local C = ns.Compat
    local q = C.GetDialogQuestID()
    if not q or not ns.Engine:GetTurninQuests()[q] then return nil end
    if not C.IsDialogQuestCompletable() then return nil end
    return action("complete " .. q, function()
        ns.Debug("auto-complete", q)
        C.CompleteDialogQuest()
    end)
end

function Automation:PlanQuestComplete(quiet)
    if not self:CanAct() or not settings().autoTurnin then return nil end
    local C = ns.Compat
    local q = C.GetDialogQuestID()
    if not q or not ns.Engine:GetTurninQuests()[q] then return nil end
    if C.GetDialogMoneyRequired() > 0 then
        if not quiet then ns.Print(L().MSG_QUEST_COSTS_MONEY, questTitle(q)) end
        return nil
    end
    local n = C.GetNumRewardChoices()
    local choice = ns.Engine:GetRewardChoice(q)
    if not (type(choice) == "number" and choice >= 1 and choice <= n) then
        if n > 1 then
            if not quiet then
                ns.Print(L().MSG_CHOOSE_REWARD, questTitle(q))
                ns:Fire("REWARD_CHOICE_NEEDED", q, n)
            end
            return nil
        end
        choice = n -- 1 = the only choice, 0 = no choice
    end
    return action("reward " .. q .. " " .. choice, function()
        ns.Debug("auto-reward", q, choice)
        C.ChooseReward(choice)
    end)
end

function Automation:PlanQuestGreeting()
    if not self:CanAct() then return nil end
    local C = ns.Compat
    local s = settings()
    if s.autoTurnin then
        local turnins = ns.Engine:GetTurninQuests()
        for _, info in ipairs(C.GetGreetingActiveQuests()) do
            local q, index = info.questID, info.index
            if q and turnins[q] and (info.isComplete or C.IsQuestComplete(q)) then
                return action("greeting turn-in " .. q .. " " .. index, function()
                    ns.Debug("greeting turn-in", q)
                    C.SelectGreetingActive(index)
                end)
            end
        end
    end
    if s.autoAccept then
        local accepts = ns.Engine:GetAcceptQuests()
        for _, info in ipairs(C.GetGreetingAvailableQuests()) do
            local q, index = info.questID, info.index
            if q and accepts[q] then
                return action("greeting accept " .. q .. " " .. index, function()
                    ns.Debug("greeting accept", q)
                    C.SelectGreetingAvailable(index)
                end)
            end
        end
    end
    return nil
end

function Automation:OnQuestDetail(questStartItemID)
    self:Act("quest", self.PlanQuestDetail, questStartItemID)
end

function Automation:OnQuestProgress()
    self:Act("quest", self.PlanQuestProgress)
end

function Automation:OnQuestComplete()
    self:Act("quest", self.PlanQuestComplete)
end

function Automation:OnQuestGreeting()
    self:Act("quest", self.PlanQuestGreeting)
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

function Automation:PlanGossip()
    if not self:CanAct() then return nil end
    local C = ns.Compat
    local s = settings()
    if s.autoTurnin then
        local turnins = ns.Engine:GetTurninQuests()
        for _, info in ipairs(C.GetGossipActiveQuests()) do
            local q = info.questID
            if q and turnins[q] and (info.isComplete or C.IsQuestComplete(q)) then
                return action("gossip turn-in " .. q, function()
                    ns.Debug("gossip turn-in", q)
                    C.SelectGossipActive(q)
                end)
            end
        end
    end
    if s.autoAccept then
        local accepts = ns.Engine:GetAcceptQuests()
        for _, info in ipairs(C.GetGossipAvailableQuests()) do
            local q = info.questID
            if q and accepts[q] then
                return action("gossip accept " .. q, function()
                    ns.Debug("gossip accept", q)
                    C.SelectGossipAvailable(q)
                end)
            end
        end
    end
    if s.autoGossip then
        local step = ns.Engine:GetCurrentStep()
        if step and step.gossip and self:GossipNpcMatches(step) then
            local last = self.gossipDone[step.id]
            if last and (now() - last) < GOSSIP_REPEAT_DELAY then return nil end
            local option = C.GetGossipOptions()[step.gossip]
            if option then
                local id = step.id
                return action(format("gossip option %s %s %s", tostring(id), tostring(step.gossip),
                    tostring(option.gossipOptionID or option.name)), function()
                    self.gossipDone[id] = now()
                    ns.Debug("gossip option", step.gossip, id)
                    C.SelectGossipOption(option)
                end)
            end
        end
    end
    return nil
end

function Automation:OnGossipShow()
    self:Act("gossip", self.PlanGossip)
end

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------

ns:On("QUEST_DETAIL", function(_, questStartItemID)
    Automation:NextDialogToken()
    Automation:NoteDialog()
    Automation:OnQuestDetail(questStartItemID)
end)
ns:On("QUEST_PROGRESS", function()
    Automation:NextDialogToken()
    Automation:NoteDialog()
    Automation:OnQuestProgress()
end)
ns:On("QUEST_COMPLETE", function()
    Automation:NextDialogToken()
    Automation:NoteDialog()
    Automation:OnQuestComplete()
end)
ns:On("QUEST_GREETING", function()
    Automation:NextDialogToken()
    Automation:NoteDialog()
    Automation:OnQuestGreeting()
end)
ns:On("GOSSIP_SHOW", function()
    Automation:NextDialogToken()
    Automation:NoteDialog()
    Automation:OnGossipShow()
end)
ns:On("GOSSIP_CLOSED", function(_, interactionIsContinuing)
    -- true while the NPC interaction moves on to its quest window (same dialog)
    if interactionIsContinuing == true then
        Automation:NextDialogToken("quest")
        return
    end
    Automation:NextDialogToken()
    Automation:EndDialog()
end)
ns:On("QUEST_FINISHED", function()
    Automation:NextDialogToken()
    Automation:EndDialog()
end)
ns:On("MODIFIER_STATE_CHANGED", function(_, key, down)
    if (key == "LSHIFT" or key == "RSHIFT") and down == 1 then Automation:OnShiftDown() end
end)
