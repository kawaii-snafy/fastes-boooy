-- FastesBoooy / Core / Engine.lua
--
-- Active route, filtered step list, cursor, background goals, manual marks,
-- fast-forward, transient-action observation, reactions to game events.
--
-- Cursor rules (see docs/ARCHITECTURE.md "Движок"):
--   * steps = route steps whose class/race/faction filters match the player
--     (steps without any valid action are dropped);
--   * natural cursor = first step that is neither done nor `bg`
--     (nil when every step is done => route finished);
--   * a step is done when it is marked (cdb.manual / cdb.skipped), or it is
--     `optional` and forwarded, or ALL of its actions are done (ns.Steps);
--   * forwarded = the step lies before the "forward limit":
--       anchor = last non-bg step that has an accept/turnin/complete/level action
--                and whose stateful actions are all done (or that is marked);
--       hint   = saved high-water mark of the natural cursor (cdb.cursorHint,
--                validated through cdb.cursorHintId / cdb.cursorHintRoute);
--       limit  = max(anchor, hint); transient actions and optional steps before
--                it count as done, and so do the non-monotonic stateful actions
--                `collect` (items consumed by a later turn-in) and `accept` of a
--                quest abandoned by a later step (ctx.abandonedLater, see
--                Core/Steps.lua). Everything else stateful is re-derived from the
--                game, so a cold start with empty SavedVariables still lands on
--                the right step (only transient steps after the last done
--                stateful step are unknown and shown again);
--   * background (`bg`) steps are NOT forwarded by that limit: a bg step passed
--     by the cursor stays in the "along the way" list until its actions are really
--     done or its quests are turned in / left the log (ns.Steps:IsBackgroundRelevant).
--     Only once the forward limit (or the natural cursor) lies in a LATER SEGMENT
--     than the bg goal's segment -- the segment of the first non-bg step after it,
--     so a bg step closing a segment belongs to the next one -- does it count as
--     forwarded (its collect/transient actions and `optional` count as
--     done, a quest not taken yet no longer keeps it) -- so a cold start on a
--     levelled character does not resurrect the bg goals of zones left long ago.
--     A bg step with collect/transient actions that was seen done is remembered in
--     cdb.bgDone (items consumed later / flags lost on /reload; optimization only);
--   * transient actions (go/fly/hearth/train/fp/sethearth/vendor) are observed
--     only for the "observed" steps = the displayed step + the natural cursor
--     step + the active background steps: trainer / merchant windows (flagged when
--     the window closes, for the steps observed when it opened), the taxi map
--     (flagged when it opens), HEARTHSTONE_BOUND / bind location change, arrival
--     within step.radius of step.at (a 0.25 s position ticker runs only while an
--     observed step waits for arrival; `fly` also requires not being on a taxi).
--     The client fires both the legacy event (TRAINER_SHOW/CLOSED, MERCHANT_SHOW/
--     CLOSED, TAXIMAP_OPENED/CLOSED) and PLAYER_INTERACTION_MANAGER_FRAME_SHOW/HIDE
--     for one window: each window is counted once (see Engine:WindowOpened);
--   * Prev/SetCursor(i < natural) "pin" the displayed step without changing
--     progress; the pin is dropped when it reaches the natural cursor.
--
-- Messages: ROUTE_CHANGED(route), STEP_CHANGED(step, index), PROGRESS_UPDATED().

local _, ns = ...
-- luacheck: ignore 212/self

local type, ipairs, pairs, tonumber, tostring = type, ipairs, pairs, tonumber, tostring
local floor, max, min = math.floor, math.max, math.min

local Engine = {
    route = nil,
    steps = {},          -- filtered, ordered normalized steps
    indexById = {},      -- [stepId] = index into steps
    done = {},           -- [index] = bool (last evaluation)
    bg = {},             -- active background steps (last evaluation)
    cursor = nil,        -- displayed step index (pinned or natural)
    natural = nil,       -- first not-done non-bg step
    pinned = nil,
    anchor = 0,
    hint = 0,
    forwardLimit = 0,
    bgLimit = 0,         -- bg step i counts as forwarded when bgHome[i] < bgLimit (first step of the reached segment)
    bgHome = {},         -- [index of a bg step] = index of the first non-bg step after it (n + 1 when none)
    flags = {},          -- [stepId] = { [actionType] = true } transient observations (memory only)
    bindBase = {},       -- [stepId] = bind location when the step became observed (false = unknown)
    turninSet = {},      -- [questID] = true for every turnin action of the filtered steps
    abandonAfter = {},   -- [index] = { [questID] = true } quests abandoned by a later step
    segFirst = {},       -- [index] = index of the first filtered step of the same segment
    windows = {},        -- [actionType] = { open, openedAt, closedAt, ids } trainer/merchant/taxi window state
    started = false,
}
ns.Engine = Engine

local EMPTY = {}
local END_ID = "<end>"
local THROTTLE = 0.1
local ARRIVAL_TICK = 0.25
local MAX_PASSES = 6
local DUP_WINDOW = 1 -- seconds: legacy + interaction-manager event of the same window

local function L() return ns.L end

local function settings()
    return ns.db and ns.db.settings or EMPTY
end

local function clear(t)
    for k in pairs(t) do t[k] = nil end
    return t
end

local function isMarked(id)
    local cdb = ns.cdb
    return (cdb.manual and cdb.manual[id]) or (cdb.skipped and cdb.skipped[id]) or false
end

-- bg step remembered as done (cdb.bgDone)
local function isBgDone(step)
    local t = step.bg and ns.cdb.bgDone
    return (t and t[step.id]) and true or false
end

-- Can the completion of a bg step NOT be re-derived from the game later?
-- (collect: the items get consumed; transient: observed once, memory only)
local function needsBgMemory(step)
    local STATEFUL = ns.Schema.STATEFUL
    for _, a in ipairs(step.actions or EMPTY) do
        if a.type == "collect" or not STATEFUL[a.type] then return true end
    end
    return false
end

local function now()
    return GetTime and GetTime() or 0
end

---------------------------------------------------------------------------
-- route / steps
---------------------------------------------------------------------------

function Engine:GetRoute()
    return self.route
end

--- Filtered, ordered array of normalized steps (do not modify).
function Engine:GetSteps()
    return self.steps
end

--- Index into GetSteps() of the displayed step, nil when the route is finished.
function Engine:GetCursor()
    return self.cursor
end

--- Index of the first not-done non-bg step (progress), nil when finished.
function Engine:GetNaturalCursor()
    return self.natural
end

function Engine:IsPinned()
    return self.pinned ~= nil
end

function Engine:GetCurrentStep()
    return self.cursor and self.steps[self.cursor] or nil
end

--- Active background steps (passed by the cursor, not done, still relevant).
function Engine:GetBackground()
    return self.bg
end

--- Up to n not-done steps after the cursor (bg steps included; check step.bg).
function Engine:GetUpcoming(n)
    local out = {}
    n = tonumber(n) or settings().shownNext or 4
    local c = self.cursor
    if not c or n <= 0 then return out end
    local steps = self.steps
    for i = c + 1, #steps do
        if not self.done[i] then
            out[#out + 1] = steps[i]
            if #out >= n then break end
        end
    end
    return out
end

--- Index into GetSteps() of a step (object or id), nil when filtered out.
function Engine:IndexOf(step)
    if type(step) == "table" then step = step.id end
    if step == nil then return nil end
    return self.indexById[step]
end

--- Done state of a step (object, id or index) from the last evaluation.
function Engine:IsDone(step)
    local i
    if type(step) == "number" then i = step else i = self:IndexOf(step) end
    if i and self.done[i] ~= nil then return self.done[i] end
    if type(step) == "table" then
        return ns.Steps:IsStepDone(step, self:GetContext(step))
    end
    return false
end

--- Evaluation context for one step (used by ns.Steps:Describe).
function Engine:GetContext(step)
    local facts = self.facts or ns.Compat.PlayerFacts()
    local s = type(step) == "table" and step or nil
    local id = s and s.id or nil
    local i = id and self.indexById[id]
    local forwarded
    if s and s.bg then
        forwarded = (i ~= nil and (self.bgHome[i] or i) < self.bgLimit) and true or false
    else
        forwarded = (i ~= nil and i < self.forwardLimit) and true or false
    end
    return {
        level = facts.level, xp = facts.xp, xpMax = facts.xpMax,
        flags = (id and self.flags[id]) or EMPTY,
        forwarded = forwarded,
        manual = id and (isMarked(id) or isBgDone(s)) and true or false,
        abandonedLater = i and self.abandonAfter[i] or nil,
        cache = {}, items = {},
    }
end

function Engine:BuildSteps()
    local steps, byId, turnins = {}, {}, {}
    local route = self.route
    if route then
        local facts = self.facts or ns.Compat.PlayerFacts()
        local Schema = ns.Schema
        for _, s in ipairs(route.steps) do
            if s.actions and #s.actions > 0 and Schema.FiltersMatch(s.filters, facts) then
                steps[#steps + 1] = s
                byId[s.id] = #steps
                for _, a in ipairs(s.actions) do
                    if a.type == "turnin" then turnins[a.quest] = true end
                end
            end
        end
        self.builtRevision = route.revision
    end
    -- segFirst[i] = index of the first filtered step of step i's segment
    local segFirst = {}
    for i, s in ipairs(steps) do
        local prev = steps[i - 1]
        segFirst[i] = (prev and prev.segment == s.segment) and segFirst[i - 1] or i
    end
    self.segFirst = segFirst
    -- bgHome[i] = first non-bg step after bg step i: the step during which the bg goal
    -- becomes "along the way" (its segment is the bg goal's segment, so a bg step at the
    -- end of a segment belongs to the next one)
    local bgHome, nextNonBg = {}, #steps + 1
    for i = #steps, 1, -1 do
        if steps[i].bg then bgHome[i] = nextNonBg else nextNonBg = i end
    end
    self.bgHome = bgHome
    -- abandonAfter[i] = { [questID] = true } for quests abandoned by a step after i
    -- (shared copy-on-write sets; nil when no later step abandons anything)
    local abandonAfter, acc = {}, nil
    for i = #steps, 1, -1 do
        abandonAfter[i] = acc
        for _, a in ipairs(steps[i].actions) do
            if a.type == "abandon" then
                local nacc = {}
                for q in pairs(acc or EMPTY) do nacc[q] = true end
                nacc[a.quest] = true
                acc = nacc
            end
        end
    end
    self.steps, self.indexById, self.turninSet = steps, byId, turnins
    self.abandonAfter = abandonAfter
    self.done, self.bg = {}, {}
    self.needRebuild = false
end

--- Route for this character: the saved choice (cdb.route) if registered, else
-- ns.Registry:Select(facts).
function Engine:SelectRoute()
    local facts = ns.Compat.PlayerFacts()
    self.facts = facts
    local id = ns.cdb.route
    local route = id and ns.Registry:Get(id) or nil
    if not route then route = ns.Registry:Select(facts) end
    return route
end

function Engine:ActivateRoute(route, force)
    if route == self.route and not force then return end
    self.route = route
    self.pinned = nil
    self.cursor, self.natural = nil, nil
    self.currentStep = nil
    self.finishedAnnounced = nil
    clear(self.flags)
    clear(self.bindBase)
    self:BuildSteps()
    ns:Fire("ROUTE_CHANGED", route)
    if self.started then
        if route then
            ns.Print(L().MSG_ROUTE_SELECTED, ns.Schema.Text(route.title, ns.locale) or tostring(route.id))
        elseif #ns.Registry.order > 0 then
            ns.Print(L().MSG_NO_ROUTE)
        end
    end
    self:Refresh()
end

--- Choose a route by id (nil = automatic selection). Saved per character.
-- @return true on success
function Engine:SetRoute(id)
    if id ~= nil then
        if not ns.Registry:Get(id) then
            ns.Print(L().MSG_UNKNOWN_ROUTE, tostring(id))
            return false
        end
        ns.cdb.route = id
    else
        ns.cdb.route = nil
    end
    if self.started then
        local route = self:SelectRoute()
        if route ~= self.route then
            self:ClearHint()
        end
        self:ActivateRoute(route)
    end
    return true
end

---------------------------------------------------------------------------
-- high-water mark (cdb.cursorHint / cursorHintId / cursorHintRoute)
---------------------------------------------------------------------------

function Engine:ClearHint()
    local cdb = ns.cdb
    cdb.cursorHint, cdb.cursorHintId, cdb.cursorHintRoute = nil, nil, nil
end

--- Validated high-water index (0 when absent / stale).
function Engine:ValidHint()
    local cdb = ns.cdb
    local h, hid, hroute = cdb.cursorHint, cdb.cursorHintId, cdb.cursorHintRoute
    if type(h) ~= "number" then return 0 end
    local route = self.route
    if hroute ~= nil and (not route or hroute ~= route.id) then return 0 end
    local n = #self.steps
    if hid == END_ID then
        return (h == n + 1) and h or 0
    elseif type(hid) == "string" then
        return self.indexById[hid] or 0
    end
    -- bare index (e.g. written by an older version / tests): trust it when in range
    h = floor(h)
    if h >= 1 and h <= n + 1 then return h end
    return 0
end

function Engine:SaveHint(index)
    local cdb = ns.cdb
    local n = #self.steps
    if n == 0 or not self.route then return end
    cdb.cursorHint = index
    cdb.cursorHintId = (index > n) and END_ID or self.steps[index].id
    cdb.cursorHintRoute = self.route.id
    self.hint = index
end

---------------------------------------------------------------------------
-- evaluation
---------------------------------------------------------------------------

-- One pass over all steps: anchor, done flags, natural cursor, background list.
function Engine:Evaluate()
    local steps = self.steps
    local n = #steps
    local Steps = ns.Steps
    local facts = ns.Compat.PlayerFacts()
    self.facts = facts

    local ctx = {
        level = facts.level, xp = facts.xp, xpMax = facts.xpMax,
        flags = EMPTY, forwarded = false, manual = false,
        cache = {}, items = {},
    }
    self.lastCtx = ctx

    -- anchor: last non-bg step with evidence whose stateful actions are done (or marked)
    local anchor = 0
    for i = n, 1, -1 do
        local s = steps[i]
        if s.stateful and Steps:IsAnchorStep(s) and (isMarked(s.id) or Steps:IsStatefulDone(s, ctx)) then
            anchor = i
            break
        end
    end
    local hint = self:ValidHint()
    local limit = max(anchor, hint)

    -- non-bg steps first (bg steps never influence them), giving the natural cursor
    local done = {}
    local natural
    for i = 1, n do
        local s = steps[i]
        if not s.bg then
            ctx.flags = self.flags[s.id] or EMPTY
            ctx.forwarded = i < limit
            ctx.manual = isMarked(s.id) and true or false
            ctx.abandonedLater = self.abandonAfter[i]
            local d = Steps:IsStepDone(s, ctx)
            done[i] = d
            if not d and not natural then natural = i end
        end
    end

    -- bg steps are forwarded only once the player is in a later segment than the
    -- bg goal's (forward limit or natural cursor, whichever is further; a finished
    -- route forwards all of them)
    local reach = max(limit, natural or (n + 1))
    local bgLimit = 0
    if reach > n then
        bgLimit = n + 2
    elseif reach >= 1 then
        bgLimit = self.segFirst[reach] or 0
    end
    self.anchor, self.hint, self.forwardLimit, self.bgLimit = anchor, hint, limit, bgLimit

    local bgDone = ns.cdb.bgDone
    for i = 1, n do
        local s = steps[i]
        if s.bg then
            ctx.flags = self.flags[s.id] or EMPTY
            ctx.forwarded = (self.bgHome[i] or i) < bgLimit
            ctx.manual = (isMarked(s.id) or isBgDone(s)) and true or false
            ctx.abandonedLater = self.abandonAfter[i]
            local d = Steps:IsStepDone(s, ctx)
            done[i] = d
            if d and not ctx.manual and not ctx.forwarded and type(bgDone) == "table" and needsBgMemory(s) then
                bgDone[s.id] = true -- done by its own actions: keep it done (items consumed / flags lost later)
            end
        end
    end
    ctx.flags, ctx.forwarded, ctx.manual, ctx.abandonedLater = EMPTY, false, false, nil
    self.done = done

    local bg = {}
    local bgEnd = (natural or (n + 1)) - 1
    for i = 1, bgEnd do
        local s = steps[i]
        if s.bg and not done[i] then
            ctx.forwarded = (self.bgHome[i] or i) < bgLimit
            if Steps:IsBackgroundRelevant(s, ctx) then bg[#bg + 1] = s end
        end
    end
    ctx.forwarded = false
    self.bg = bg

    -- pin
    local pinned = self.pinned
    if pinned and (pinned < 1 or pinned >= (natural or (n + 1))) then
        pinned = nil
    end
    self.pinned = pinned
    self.natural = natural

    -- high-water mark
    if n > 0 then
        local reached = natural or (n + 1)
        if reached > hint then self:SaveHint(reached) end
    end
    return pinned or natural
end

-- Steps whose transient actions are observed: displayed + natural cursor +
-- the active background steps.
function Engine:ObservedSteps()
    local out, seen = {}, {}
    local function add(s)
        if s and not seen[s] then
            seen[s] = true
            out[#out + 1] = s
        end
    end
    local a, b = self.cursor, self.natural
    if a then add(self.steps[a]) end
    if b then add(self.steps[b]) end
    for _, s in ipairs(self.bg) do add(s) end
    return out
end

local function setFlag(self, step, actionType)
    local f = self.flags[step.id]
    if not f then
        f = {}
        self.flags[step.id] = f
    end
    if f[actionType] then return false end
    f[actionType] = true
    ns.Debug("transient", actionType, "done on", step.id)
    return true
end

-- Does a bind location name designate the step's place? (enUS name, or the
-- localized name from route data `places`)
function Engine:PlaceMatches(place, bind)
    if type(place) ~= "string" or type(bind) ~= "string" then return false end
    local b = bind:lower()
    if b == place:lower() then return true end
    local loc = ns.Registry:Lookup(self.route, "places", place)
    return loc ~= nil and loc:lower() == b
end

-- Check bind-location and arrival conditions of the observed steps.
-- @return true when a new transient flag was set
function Engine:CheckObserved()
    local changed = false
    local needTicker = false
    local Compat = ns.Compat
    for _, s in ipairs(self:ObservedSteps()) do
        local flags = self.flags[s.id] or EMPTY
        local sethearth = ns.Steps:HasAction(s, "sethearth")
        if sethearth and not flags.sethearth then
            local bind = Compat.BindLocation()
            local base = self.bindBase[s.id]
            if base == nil then
                self.bindBase[s.id] = bind or false
                base = bind or false
            end
            if bind and ((base and bind ~= base) or self:PlaceMatches(sethearth.place, bind)) then
                changed = setFlag(self, s, "sethearth") or changed
            end
        end
        if s.at then
            for _, a in ipairs(s.actions) do
                local t = a.type
                if ns.Steps.ARRIVAL_ACTIONS[t] and not flags[t] then
                    local dist = Compat.DistanceTo(s.at.map, s.at.x, s.at.y)
                    local radius = s.radius or ns.Schema.DEFAULT_RADIUS[t] or 12
                    if dist and dist <= radius and (t ~= "fly" or not Compat.OnTaxi()) then
                        changed = setFlag(self, s, t) or changed
                    else
                        needTicker = true
                    end
                end
            end
        end
    end
    self:SetArrivalTicker(needTicker)
    return changed
end

function Engine:SetArrivalTicker(on)
    if on then
        if self.ticker or not (C_Timer and C_Timer.NewTicker) then return end
        self.ticker = C_Timer.NewTicker(ARRIVAL_TICK, function()
            if Engine:CheckObserved() then Engine:Refresh() end
        end)
    elseif self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
end

--- Immediate re-evaluation; fires STEP_CHANGED when the displayed step changed
-- and PROGRESS_UPDATED always.
function Engine:Refresh()
    if not self.started then return end
    if self.refreshing then
        self.refreshAgain = true
        return
    end
    if self.needRebuild and not self.route then
        -- a route module registered after login: try the automatic selection again
        local route = self:SelectRoute()
        if route then
            self:ActivateRoute(route) -- rebuilds and calls Refresh
            return
        end
    end
    self.refreshing = true
    local ok = ns.SafeCall(function()
        if self.needRebuild then self:BuildSteps() end
        local passes = 0
        repeat
            passes = passes + 1
            self.refreshAgain = false
            local cursor = self:Evaluate()
            local step = cursor and self.steps[cursor] or nil
            local stepChanged = (step ~= self.currentStep) or (cursor ~= self.cursor)
            self.cursor = cursor
            self.currentStep = step
            local flagged = self:CheckObserved()
            if stepChanged then
                ns:Fire("STEP_CHANGED", step, cursor)
            end
        until (not flagged and not self.refreshAgain) or passes >= MAX_PASSES
        if not self.natural and #self.steps > 0 then
            if not self.finishedAnnounced then
                self.finishedAnnounced = true
                if self.wasRunning then ns.Print(L().MSG_ROUTE_FINISHED) end
            end
        else
            self.finishedAnnounced = nil
            self.wasRunning = #self.steps > 0
        end
    end)
    self.refreshing = false
    if ok then ns:Fire("PROGRESS_UPDATED") end
end

--- Throttled refresh (~0.1 s); `rebuild` also re-filters the route's steps.
function Engine:RequestRefresh(rebuild)
    if rebuild then self.needRebuild = true end
    if not self.started or self.pending then return end
    if C_Timer and C_Timer.After then
        self.pending = true
        C_Timer.After(THROTTLE, function()
            Engine.pending = false
            Engine:Refresh()
        end)
    else
        self:Refresh()
    end
end

---------------------------------------------------------------------------
-- navigation (user actions)
---------------------------------------------------------------------------

local function nextNonBg(steps, from, limit)
    local i = from
    while i < limit and steps[i] and steps[i].bg do i = i + 1 end
    return i
end

local function advancePin(self)
    local n = #self.steps
    local nat = self.natural or (n + 1)
    local p = nextNonBg(self.steps, self.pinned + 1, nat)
    self.pinned = (p < nat) and p or nil
end

--- "Next": on the natural cursor marks the step done (cdb.manual); while a
-- previous step is pinned, moves the pin forward.
function Engine:Next()
    local c = self.cursor
    if not c then return end
    if self.pinned then
        advancePin(self)
    else
        ns.cdb.manual[self.steps[c].id] = true
    end
    self:Refresh()
end

--- "Prev": shows the previous non-bg step. From the natural cursor, a step that
-- is done only because of a manual/skip mark is un-marked (undo).
function Engine:Prev()
    local steps = self.steps
    local n = #steps
    if n == 0 then return end
    local p = (self.cursor or (n + 1)) - 1
    while p >= 1 and steps[p].bg do p = p - 1 end
    if p < 1 then return end
    local s = steps[p]
    if not self.pinned then
        local cdb = ns.cdb
        if cdb.manual[s.id] or cdb.skipped[s.id] then
            cdb.manual[s.id], cdb.skipped[s.id] = nil, nil
            self.flags[s.id] = nil
            if self:ValidHint() > p then self:SaveHint(p) end
        end
    end
    self.pinned = p
    self:Refresh() -- the pin is dropped automatically when p became the natural cursor
end

--- "Skip": marks the displayed step skipped (cdb.skipped).
function Engine:Skip()
    local c = self.cursor
    if not c then return end
    ns.cdb.skipped[self.steps[c].id] = true
    if self.pinned then advancePin(self) end
    self:Refresh()
end

--- Jump to step i: i < natural pins the view, i > natural skips the not-done
-- non-bg steps in between.
function Engine:SetCursor(i)
    i = tonumber(i)
    local n = #self.steps
    if not i or n == 0 then return false end
    i = max(1, min(n, floor(i)))
    local nat = self.natural or (n + 1)
    if i < nat then
        self.pinned = i
    else
        self.pinned = nil
        local skipped = ns.cdb.skipped
        for j = nat, i - 1 do
            local s = self.steps[j]
            if not s.bg and not self.done[j] then skipped[s.id] = true end
        end
    end
    self:Refresh()
    return true
end

--- Forget manual marks, skips, the high-water mark and transient observations
-- of this character (progress derived from the game is kept).
function Engine:Reset()
    local cdb = ns.cdb
    clear(cdb.manual)
    clear(cdb.skipped)
    if type(cdb.bgDone) == "table" then clear(cdb.bgDone) end
    self:ClearHint()
    clear(self.flags)
    clear(self.bindBase)
    self.pinned = nil
    ns.Print(L().MSG_RESET)
    self:Refresh()
end

---------------------------------------------------------------------------
-- queries for Automation
---------------------------------------------------------------------------

local function addAccepts(set, step)
    for _, a in ipairs(step.actions) do
        if a.type == "accept" then set[a.quest] = true end
    end
end

--- Quests that may be auto-accepted: accept actions of the steps
-- [cursor, cursor + lookahead] (from the smaller of displayed/natural cursor to
-- the larger + lookahead) plus the active background steps.
function Engine:GetAcceptQuests()
    local set = {}
    local steps = self.steps
    local n = #steps
    local look = tonumber(settings().lookahead) or 6
    local a, b = self.cursor, self.natural
    if a or b then
        local from = min(a or b, b or a)
        local to = min(n, max(a or 0, b or 0) + look)
        for i = from, to do addAccepts(set, steps[i]) end
    end
    for _, s in ipairs(self.bg) do addAccepts(set, s) end
    return set
end

--- Quests that may be auto-turned-in: every turnin action of the filtered route.
function Engine:GetTurninQuests()
    return self.turninSet
end

--- Reward choice index configured with `reward = { [questID] = index }`.
-- Steps turning the quest in are preferred over other steps.
function Engine:GetRewardChoice(questID)
    local fallback
    for _, s in ipairs(self.steps) do
        local r = s.reward and s.reward[questID]
        if r then
            for _, a in ipairs(s.actions) do
                if a.type == "turnin" and a.quest == questID then return r end
            end
            fallback = fallback or r
        end
    end
    return fallback
end

---------------------------------------------------------------------------
-- quest XP log (ns.db.xpLog[questID] = max XP reward observed)
---------------------------------------------------------------------------

Engine.pendingXP = {} -- [questID] = { xp = n, level = n } captured at QUEST_COMPLETE

function Engine:RecordXP(questID, xp, level)
    if type(questID) ~= "number" or type(xp) ~= "number" or xp < 0 then return end
    local db = ns.db
    db.xpLog = db.xpLog or {}
    db.xpLogLevel = db.xpLogLevel or {}
    local old = db.xpLog[questID]
    if old == nil or xp > old then
        db.xpLog[questID] = xp
        db.xpLogLevel[questID] = level or (self.facts and self.facts.level) or nil
        ns.Debug(L().MSG_XP_RECORDED:format(questID, xp))
    end
end

---------------------------------------------------------------------------
-- lifecycle & events
---------------------------------------------------------------------------

function Engine:Start()
    if self.started then return end
    self.started = true
    local errors = ns.Registry.errors
    if #errors > 0 then
        ns.Print(L().MSG_ROUTE_ERRORS, #errors, tostring(errors[1]))
    end
    self:ActivateRoute(self:SelectRoute(), true)
end

ns:On("PLAYER_LOGIN", function()
    Engine:Start()
end)

-- DB_READY after login (e.g. the core was loaded on demand)
ns:Listen("DB_READY", function()
    if not Engine.started and IsLoggedIn and IsLoggedIn() then
        Engine:Start()
    end
end)

ns:Listen("ROUTES_CHANGED", function(_, routeId)
    if not Engine.started then return end
    if not Engine.route or (routeId and Engine.route.id == routeId) then
        Engine:RequestRefresh(true)
    end
end)

local function refresh()
    Engine:RequestRefresh()
end

for _, event in ipairs({
    "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_LOG_UPDATE", "BAG_UPDATE_DELAYED",
    "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS", "PLAYER_LEVEL_UP",
    "PLAYER_ENTERING_WORLD", "PLAYER_CONTROL_GAINED",
}) do
    ns:On(event, refresh)
end

ns:On("UNIT_QUEST_LOG_CHANGED", function(_, unit)
    if unit == "player" then refresh() end
end)

ns:On("PLAYER_XP_UPDATE", function(_, unit)
    if unit == nil or unit == "player" then refresh() end
end)

ns:Listen("QUEST_DATA_LOADED", refresh)
ns:Listen("ITEM_DATA_LOADED", refresh)

ns:On("QUEST_COMPLETE", function()
    local q = ns.Compat.GetDialogQuestID()
    local xp = ns.Compat.GetDialogRewardXP()
    if q and xp then
        local facts = ns.Compat.PlayerFacts()
        Engine.pendingXP[q] = { xp = xp, level = facts.level }
    end
end)

ns:On("QUEST_TURNED_IN", function(_, questID, xpReward)
    if ns.Compat.IsSecret(questID) or type(questID) ~= "number" then return end
    local pending = Engine.pendingXP[questID]
    Engine.pendingXP[questID] = nil
    local xp = (not ns.Compat.IsSecret(xpReward)) and xpReward or nil
    local level = pending and pending.level or ns.Compat.PlayerFacts().level
    if type(xp) ~= "number" or (xp == 0 and pending and pending.xp > 0) then
        xp = pending and pending.xp or xp
    end
    Engine:RecordXP(questID, xp, level)
    refresh()
end)

-- transient observations ---------------------------------------------------

--- Mark a transient action type done on the observed steps that have it.
-- @return true when a step was flagged
function Engine:ObserveAction(actionType)
    if not self.started then return false end
    local any = false
    for _, s in ipairs(self:ObservedSteps()) do
        if ns.Steps:HasAction(s, actionType) then
            any = setFlag(self, s, actionType) or any
        end
    end
    if any then self:Refresh() end
    return any
end

-- ids of the observed steps that have an action of the given type
function Engine:ObservedIds(actionType)
    local ids = {}
    for _, s in ipairs(self:ObservedSteps()) do
        if ns.Steps:HasAction(s, actionType) then ids[#ids + 1] = s.id end
    end
    return ids
end

-- Flag actionType on the listed steps (by id). @return true when a step was flagged
function Engine:FlagSteps(actionType, ids)
    local any = false
    for _, id in ipairs(ids or EMPTY) do
        local i = self.indexById[id]
        local s = i and self.steps[i]
        if s and ns.Steps:HasAction(s, actionType) then
            any = setFlag(self, s, actionType) or any
        end
    end
    if any then self:Refresh() end
    return any
end

local function windowState(self, actionType)
    local w = self.windows[actionType]
    if not w then
        w = {}
        self.windows[actionType] = w
    end
    return w
end

--- A trainer ("train") / merchant ("vendor") / taxi map ("fp") window opened.
-- The client fires the legacy event AND the interaction-manager event for the
-- same window: the second one (same kind, while open, within DUP_WINDOW) is
-- ignored. The observed steps are taken now (after a fresh evaluation, so a
-- pending throttled refresh -- e.g. after the turn-in that precedes a train
-- step at the same NPC -- is applied); a train/vendor step is flagged when the
-- window closes, an fp step right away (opening the map is the action).
function Engine:WindowOpened(actionType)
    if not self.started then return false end
    local w = windowState(self, actionType)
    local t = now()
    if w.open and w.openedAt and (t - w.openedAt) < DUP_WINDOW then return false end
    self:Refresh()
    w.open, w.openedAt = true, t
    w.ids = self:ObservedIds(actionType)
    if actionType == "fp" then
        return self:FlagSteps(actionType, w.ids)
    end
    return false
end

--- The window closed: flags the steps observed when it opened (only once per
-- window, so the refresh triggered by the first close event cannot let the second
-- one complete the NEXT step of the same kind). A close without a seen open
-- (window opened before the engine started) flags the steps observed now.
function Engine:WindowClosed(actionType)
    if not self.started then return false end
    local w = windowState(self, actionType)
    local t = now()
    local ids
    if w.open then
        ids = (actionType ~= "fp") and w.ids or nil -- fp: flagged when the map opened
    elseif w.closedAt and (t - w.closedAt) < DUP_WINDOW then
        return false -- second close event of the same window
    else
        self:Refresh()
        ids = self:ObservedIds(actionType)
    end
    w.open, w.ids, w.closedAt = false, nil, t
    return self:FlagSteps(actionType, ids)
end

ns:On("TRAINER_SHOW", function() Engine:WindowOpened("train") end)
ns:On("TRAINER_CLOSED", function() Engine:WindowClosed("train") end)
ns:On("MERCHANT_SHOW", function() Engine:WindowOpened("vendor") end)
ns:On("MERCHANT_CLOSED", function() Engine:WindowClosed("vendor") end)
ns:On("TAXIMAP_OPENED", function() Engine:WindowOpened("fp") end)
ns:On("TAXIMAP_CLOSED", function() Engine:WindowClosed("fp") end)
ns:On("HEARTHSTONE_BOUND", function() Engine:ObserveAction("sethearth") end)

local function interactionType(name)
    return Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType[name]
end

-- PLAYER_INTERACTION_MANAGER_FRAME_* type -> transient action type
local function windowAction(kind)
    if ns.Compat.IsSecret(kind) or kind == nil then return nil end
    if kind == interactionType("Trainer") then return "train" end
    if kind == interactionType("Merchant") then return "vendor" end
    if kind == interactionType("TaxiNode") then return "fp" end
    return nil
end

ns:On("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind)
    local action = windowAction(kind)
    if action then Engine:WindowOpened(action) end
end)

ns:On("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind)
    local action = windowAction(kind)
    if action then Engine:WindowClosed(action) end
end)
