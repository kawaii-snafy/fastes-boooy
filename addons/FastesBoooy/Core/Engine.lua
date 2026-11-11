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
--       anchor = last non-bg step that has an accept/turnin/complete action
--                and whose stateful actions are all done (or that is marked);
--                `level` is no evidence (a level reached early through rested
--                XP must not forward an earlier sethearth/train/fp), so a lone
--                level step never anchors;
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
--   * a quest the player GAVE UP keeps its earlier `accept` (and its complete/turnin
--     actions up to the given-up point) done while it is neither in the log nor
--     turned in (ctx.givenUp, see Core/Steps.lua): the cursor does not jump back
--     and the quest is not auto-accepted again. givenUp[q] = j comes from
--       - a later non-bg step with its complete/turnin that is marked (Skip / Next)
--         or is `optional` and forwarded (j = that step), and
--       - a quest abandoned BY HAND (cdb.gaveUp, order-independent): QUEST_REMOVED
--         (not a replay) is re-checked GIVE_UP_DELAY later (QUEST_TURNED_IN and
--         QUEST_REMOVED both fire on a turn-in); when the quest is neither turned in
--         nor in the log, the route has an `accept` of it before the cursor (the
--         natural cursor when it was removed, or the high-water mark) and that
--         instance of the quest (up to the next `accept` of it) has no explicit
--         `abandon` step (the route drops it itself), Engine:GiveUpQuest marks the
--         not-done non-bg steps whose actions are all complete/turnin of the quest
--         (cdb.skipped, ids listed in cdb.gaveUp[q].steps) and records the accept
--         (j = the next accept of the quest, so steps mixing it with other quests
--         wait only for their other actions). An abandon before the route's accept
--         was reached (quest taken early by the lookahead) is not given up.
--     Auto marks are no forward evidence (no anchor). Re-accepting the quest by
--     hand (QUEST_ACCEPTED, or finding it in the log; not when it is taken for the
--     route's next accept of it within the accept window -- that instance is new),
--     the quest turned in, Prev right after the give-up or Prev onto one of its
--     marked steps, and Reset drop the record and its marks;
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
--     the window closes, for the steps observed when it opened whose `npc` list
--     contains the window's NPC -- or that have no `npc`), the taxi map
--     (flagged when it opens), HEARTHSTONE_BOUND / bind location change, arrival
--     within step.radius of step.at (a 0.25 s position ticker runs only while an
--     observed step waits for arrival; `fly` also requires not being on a taxi).
--     The client fires both the legacy event (TRAINER_SHOW/CLOSED, MERCHANT_SHOW/
--     CLOSED, TAXIMAP_OPENED/CLOSED) and PLAYER_INTERACTION_MANAGER_FRAME_SHOW/HIDE
--     for one window: each window is counted once (see Engine:WindowOpened);
--   * Prev/SetCursor(i < natural) "pin" the displayed step without changing
--     progress; the pin is dropped when it reaches the natural cursor. Forward() moves
--     a pin forward, else skips the displayed step (the UI's single forward button);
--   * void quest actions (Engine:ComputeVoid, ctx.void; one forward pass per evaluation,
--     memoized): quest actions that count as done although the quest is neither in the log
--     nor turned in -- the player never took it:
--       - gray (settings.skipGray): an `accept` of a quest that is trivial for the player's level
--         (Compat.IsQuestGray: the client's C_QuestLog.IsQuestTrivial, else the FrameXML rule with
--         route data questMeta level), unless the quest is "protected": a prerequisite (questMeta
--         preAll / preAny) of a later route quest that is neither turned in nor in the log, that
--         the route still leads to (not every accept of it is "not taken" for another reason, see
--         below: marked, below the sync floor, `optional` and passed, given up -- a quest the
--         player has passed or declined keeps no chain alive, so a finished route stays finished
--         on a cold start) and that is not gray itself or is protected (chains that unlock good
--         quests are kept);
--       - unreachable: an `accept` whose route-quest prerequisites can no longer be met -- preAll
--         holds a dead route quest, or preAny is non-empty and all of it are dead route quests
--         (prerequisites that are not route quests are assumed met); a route quest p is dead when
--         it is neither turned in nor in the log and every accept of p before the step is "not
--         taken" (at least one);
--       - orphan: a `complete` / `turnin` of a quest that is neither in the log nor turned in when
--         every accept of it before the step is "not taken" (at least one) -- e.g. Skip on an
--         accept step no longer leaves its turn-in blocking the cursor; and a `collect` whose
--         quests (route quests with the item as an objective -- questMeta items --, else the
--         step's complete / turnin quests) are all dead or turned in, at least one dead (decided
--         after the pass: every accept seen);
--       - floor: the other actions of a step below the sync floor that stays an along-the-way goal
--         (see level sync).
--     An accept is "not taken" when the quest is neither in the log nor turned in and the accept is
--     done without the game: its step is marked (Next / Skip), lies below the sync floor or is an
--     `optional` non-bg step behind the forward limit, the quest is given up (ctx.givenUp; not the
--     hold of a pending QUEST_REMOVED check -- it may have been turned in), or the accept is gray /
--     unreachable. Gray accepts are skipped only in a segment the player has outgrown (level >
--     segment.levels[2]; no levels: always), so a quest the route takes on purpose while gray at
--     its planned level stays; a dependent "kept" for protection is one that is not skipped as gray
--     by that rule. Void actions are no forward evidence (the anchor is computed
--     without them) and are not auto-accepted (GetAcceptQuests);
--   * level sync (settings.levelSync "ask" | "auto" | "off", settings.levelSyncMargin): a segment
--     with `levels` is OUTLEVELED when playerLevel >= levels[2] + margin. When the segment of the
--     natural cursor is outleveled, the first later segment that is not (and has a not-done
--     non-bg step) is suggested (GetSyncSuggestion, message SYNC_SUGGESTION) -- "auto" applies it
--     at once -- only when the jump skips new content (SyncSkipsContent: an accept of a quest the
--     player does not have that the route turns in before the target), not quests of the log,
--     bridges, trainer / travel visits or level gates. ApplySync stores a floor per character
--     (cdb.syncFloor = { route, stepId, keep, ... }, validated against the active route): every
--     step before it (bg steps too) counts as done, except the along-the-way goals kept below it
--     (self.floorKeep, listed in GetBackground, their other actions void "floor"): the complete /
--     collect actions of a quest of the log the route turns in at or after the floor, the turn-in
--     of a complete quest of the log, and the skipped service visits still needed (record.keep:
--     last trainer visit, a bind a later hearth needs, flight paths later flights need; dropped
--     when done or passed -- KeepServices / KeepUntil). Other incomplete quests of the log whose
--     turn-ins are all below the floor are dropped (GetDroppedQuests, one chat line). fly / hearth
--     steps get a hint when the flight path is still pending / the bind point differs.
--     Prev beyond the floor only pins the view; UndoSync (the active route's floor only) restores
--     the previous floor and the high-water mark of the moment of the sync. DismissSync (and
--     UndoSync) silence the suggestion for that segment until the next level-up (cdb.syncDismissed).
--
-- Messages: ROUTE_CHANGED(route), STEP_CHANGED(step, index), PROGRESS_UPDATED(),
-- SYNC_SUGGESTION(suggestion | nil) (on every change), SYNC_APPLIED(record), SYNC_UNDONE().

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
    questEnds = {},      -- { { index, questID }, ... } complete/turnin actions of the non-bg steps
    givenUp = {},        -- [questID] = index before which the quest counts as given up (last evaluation)
    acceptAt = {},       -- [questID] = { index, ... } ascending: steps with an accept action of the quest
    turninAt = {},       -- [questID] = { index, ... } ascending: steps with a turnin action of the quest
    autoMarks = {},      -- [stepId] = questID: skip marks made by GiveUpQuest (cdb.gaveUp; last evaluation)
    removed = {},        -- [questID] = step id (or END_ID) of the reach when QUEST_REMOVED arrived (pending check)
    lastGaveUp = nil,    -- { quest, natural }: the latest automatic give-up (Prev right after it undoes it)
    segFirst = {},       -- [index] = index of the first filtered step of the same segment
    windows = {},        -- [actionType] = { open, openedAt, closedAt, ids } trainer/merchant/taxi window state
    void = {},           -- [action] = "gray" | "unreachable" | "orphan" (last evaluation, see the header)
    floor = 0,           -- index of the sync floor step (steps before it are done), 0 = none
    floorKeep = {},      -- [index < floor] = true: kept as an along-the-way goal (last evaluation, see the header)
    segRuns = {},        -- { { seg = <segment table>, id, first, last }, ... } filtered steps by segment
    segRunOf = {},       -- [index] = index into segRuns
    dependents = {},     -- [questID] = { questID, ... } route quests accepted later that need it (questMeta)
    itemQuests = {},     -- [itemID] = { questID, ... } route quests with the item as an objective (questMeta items)
    questMeta = {},      -- route data questMeta (level, reqLevel, preAll, preAny, items)
    grayCache = {},      -- [questID] = bool for grayLevel
    syncSuggestion = nil, -- current level-sync suggestion (GetSyncSuggestion)
    lastSync = nil,      -- { at = GetTime(), record = cdb.syncFloor } of the last ApplySync (UI undo link)
    started = false,
}
ns.Engine = Engine

local EMPTY = {}
local END_ID = "<end>"
local LOG_READY_DELAY = 3 -- seconds after the start: see Engine:Start
local THROTTLE = 0.1
local ARRIVAL_TICK = 0.25
local MAX_PASSES = 6
local DUP_WINDOW = 1 -- seconds: legacy + interaction-manager event of the same window
local GIVE_UP_DELAY = 0.5 -- seconds: QUEST_REMOVED -> "abandoned, not turned in?" check

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

-- marked by the player (not by GiveUpQuest): evidence of progress for the forward anchor
local function isMarkedByPlayer(self, id)
    local cdb = ns.cdb
    if cdb.manual and cdb.manual[id] then return true end
    return (cdb.skipped and cdb.skipped[id] and not self.autoMarks[id]) and true or false
end

-- cdb.gaveUp (created on demand: SavedVariables of older versions lack it)
local function gaveUpRecords()
    local cdb = ns.cdb
    if type(cdb.gaveUp) ~= "table" then cdb.gaveUp = {} end
    return cdb.gaveUp
end

-- Are all actions of the step complete/turnin of quest q (at least one)?
local function endsOnly(step, q)
    local any = false
    for _, a in ipairs(step.actions) do
        if (a.type ~= "complete" and a.type ~= "turnin") or a.quest ~= q then return false end
        any = true
    end
    return any
end

local function hasQuestAction(step, actionType, q)
    for _, a in ipairs(step.actions) do
        if a.type == actionType and a.quest == q then return true end
    end
    return false
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

--- Up to n steps after the displayed step that are NOT done in the last evaluation (bg steps
-- included, check step.bg): steps done in the game, marked, skipped as gray / unreachable /
-- never-taken quests or below the sync floor are left out.
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
    local manual = id and (isMarked(id) or isBgDone(s)) and true or false
    if i and i < (self.floor or 0) then
        -- below the sync floor: done, unless kept as an along-the-way goal (its own actions count)
        if self.floorKeep[i] then forwarded = false else manual = true end
    end
    return {
        level = facts.level, xp = facts.xp, xpMax = facts.xpMax, maxLevel = facts.maxLevel,
        flags = (id and self.flags[id]) or EMPTY,
        forwarded = forwarded,
        manual = manual,
        abandonedLater = i and self.abandonAfter[i] or nil,
        givenUp = self.givenUp, index = i, void = self.void,
        cache = {}, items = {},
    }
end

function Engine:BuildSteps()
    local steps, byId, turnins = {}, {}, {}
    local route = self.route
    if route then
        ns.Registry:Finalize(route) -- a composed route changed since it was read (Core/Compose.lua)
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
    -- questEnds = complete/turnin actions of the non-bg steps (for the given-up set);
    -- acceptAt[q] / turninAt[q] = indices of the steps accepting / turning in q (ascending)
    local questEnds, acceptAt, turninAt = {}, {}, {}
    local function note(map, q, i)
        local list = map[q]
        if not list then
            list = {}
            map[q] = list
        end
        if list[#list] ~= i then list[#list + 1] = i end
    end
    for i, s in ipairs(steps) do
        for _, a in ipairs(s.actions) do
            local t = a.type
            if (t == "complete" or t == "turnin") and not s.bg then
                questEnds[#questEnds + 1] = { i, a.quest }
            end
            if t == "accept" then
                note(acceptAt, a.quest, i)
            elseif t == "turnin" then
                note(turninAt, a.quest, i)
            end
        end
    end
    self.steps, self.indexById, self.turninSet = steps, byId, turnins
    self.abandonAfter, self.questEnds, self.givenUp, self.acceptAt = abandonAfter, questEnds, {}, acceptAt
    self.turninAt = turninAt
    self.done, self.bg = {}, {}
    self:BuildSegments(steps, route)
    self:BuildDependents(route, acceptAt)
    self.void, self.floor, self.floorKeep, self.keepUntil = {}, 0, {}, nil
    clear(self.grayCache)
    -- evaluation buffers (Engine:Evaluate) start empty for the new step list
    self.doneSpare, self.questCache = nil, nil
    self.needRebuild = false
end

-- segRuns / segRunOf: the filtered steps grouped by segment (a segment's steps are contiguous:
-- inserts take the segment of their anchor). seg = the route's segment table (levels, title).
function Engine:BuildSegments(steps, route)
    local runs, runOf = {}, {}
    local byId = route and route.segmentById or EMPTY
    for i, s in ipairs(steps) do
        local run = runs[#runs]
        if not run or run.id ~= s.segment then
            run = { id = s.segment, seg = byId[s.segment] or { id = s.segment }, first = i, last = i }
            runs[#runs + 1] = run
        end
        run.last = i
        runOf[i] = #runs
    end
    self.segRuns, self.segRunOf = runs, runOf
end

-- dependents[p] = route quests r (accepted in the route, first accept after p's first accept) whose
-- questMeta preAll / preAny lists p (p a route quest): the chains the gray skip keeps.
function Engine:BuildDependents(route, acceptAt)
    local meta = route and route.data and route.data.questMeta
    if type(meta) ~= "table" then meta = EMPTY end
    self.questMeta = meta
    local deps = {}
    for r, list in pairs(acceptAt) do
        local m = meta[r]
        if type(m) == "table" then
            for _, key in ipairs({ "preAll", "preAny" }) do
                for _, p in ipairs(type(m[key]) == "table" and m[key] or EMPTY) do
                    local pa = acceptAt[p]
                    if p ~= r and pa and pa[1] < list[1] then
                        local d = deps[p]
                        if not d then
                            d = {}
                            deps[p] = d
                        end
                        local dup = false
                        for _, x in ipairs(d) do if x == r then dup = true end end
                        if not dup then d[#d + 1] = r end
                    end
                end
            end
        end
    end
    for _, d in pairs(deps) do table.sort(d) end
    self.dependents = deps
    -- itemQuests[item] = route quests that need the item (questMeta items: their objective items)
    local items = {}
    for q in pairs(acceptAt) do
        local m = meta[q]
        for _, item in ipairs(type(m) == "table" and type(m.items) == "table" and m.items or EMPTY) do
            local list = items[item]
            if not list then
                list = {}
                items[item] = list
            end
            list[#list + 1] = q
        end
    end
    for _, list in pairs(items) do table.sort(list) end
    self.itemQuests = items
end

--- Route for this character: the saved choice (cdb.route, a route id or a former id of a
-- route: Registry:Get resolves `aliases`) if registered, else ns.Registry:Select(facts).
function Engine:SelectRoute()
    local facts = ns.Compat.PlayerFacts()
    self.facts = facts
    local id = ns.cdb.route
    local route = id and ns.Registry:Get(id) or nil
    if not route then route = ns.Registry:Select(facts) end
    return route
end

-- A route that was renamed keeps its former ids as `aliases` (Core/Registry.lua): the progress
-- saved under a former id (the manual choice, the high-water mark, the level-sync floor and its
-- dismissal) moves to the new id when the route is activated. Marks keyed by step id need nothing.
local function adoptAliases(route)
    local aliases = ns.Registry.aliases
    if not route or not aliases or next(aliases) == nil then return end
    local id = route.id
    local function former(v)
        return type(v) == "string" and v ~= id and aliases[v] == route
    end
    local cdb = ns.cdb
    if former(cdb.route) then cdb.route = id end
    if former(cdb.cursorHintRoute) then cdb.cursorHintRoute = id end
    local f, depth = cdb.syncFloor, 0
    while type(f) == "table" and depth < 8 do -- the floor and its undo record(s)
        if former(f.route) then f.route = id end
        if type(f.hint) == "table" and former(f.hint[3]) then f.hint[3] = id end
        f, depth = f.prev, depth + 1
    end
    local d = cdb.syncDismissed
    if type(d) == "table" and former(d.route) then d.route = id end
end

function Engine:ActivateRoute(route, force)
    if route == self.route and not force then return end
    adoptAliases(route)
    self.route = route
    self.pinned = nil
    self.cursor, self.natural = nil, nil
    self.currentStep = nil
    self.finishedAnnounced = nil
    self.lastGaveUp = nil
    clear(self.flags)
    clear(self.bindBase)
    clear(self.removed)
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
        local chosen = ns.Registry:Get(id)
        if not chosen then
            ns.Print(L().MSG_UNKNOWN_ROUTE, tostring(id))
            return false
        end
        ns.cdb.route = chosen.id -- (`id` may be a former id of the route: an alias)
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
-- level sync floor (cdb.syncFloor)
---------------------------------------------------------------------------

--- The sync floor record of the active route (nil when absent / for another route / its step
-- is not in the filtered route).
function Engine:GetSyncFloor()
    local f = ns.cdb.syncFloor
    local route = self.route
    if type(f) ~= "table" or not route or f.route ~= route.id then return nil end
    if type(f.stepId) ~= "string" or not self.indexById[f.stepId] then return nil end
    return f
end

--- Index of the sync floor step (steps before it count as done), 0 when there is none.
function Engine:FloorIndex()
    local f = self:GetSyncFloor()
    return f and self.indexById[f.stepId] or 0
end

---------------------------------------------------------------------------
-- void quest actions: gray / unreachable / orphan (see the header)
---------------------------------------------------------------------------

--- Is quest q gray for the player (cached per level; questMeta level for the fallback rule)?
function Engine:IsGray(q, level, range)
    local cache = self.grayCache
    if self.grayLevel ~= level then
        clear(cache)
        self.grayLevel = level
    end
    local g = cache[q]
    if g == nil then
        local m = self.questMeta[q]
        g = ns.Compat.IsQuestGray(q, type(m) == "table" and m.level or nil, level, range) and true or false
        cache[q] = g
    end
    return g
end

-- Forward pass over the steps (route order): marks void actions in self.void (cleared first) and
-- the steps below the sync floor kept as along-the-way goals for quests of the log (self.floorKeep;
-- the record's skipped service visits are added later, Engine:KeepServices).
-- An accept's "not taken" state is known when the pass reaches it; dead / orphan look only at
-- accepts BEFORE the step, so one pass is enough (collect actions: after the pass, every accept of
-- their quests seen). Tables are reused between evaluations.
function Engine:ComputeVoid(ctx, limit, floorIndex, givenUp)
    local void = clear(self.void)
    local seen = clear(self.voidSeen or {})
    local allVoid = clear(self.voidAll or {})
    local protMemo = clear(self.protMemo or {})
    local floorKeep = clear(self.floorKeep or {})
    local keepQ = clear(self.keepQ or {})
    self.voidSeen, self.voidAll, self.protMemo, self.floorKeep, self.keepQ = seen, allVoid, protMemo, floorKeep, keepQ
    local steps, n = self.steps, #self.steps
    if n == 0 then return void end
    local Steps = ns.Steps
    local questState, questComplete = Steps.QuestState, Steps.QuestComplete
    local meta, acceptAt, deps = self.questMeta, self.acceptAt, self.dependents
    local turninAt, itemQuests = self.turninAt, self.itemQuests
    local collects, collectAt = self.voidCollects or {}, self.voidCollectAt or {}
    self.voidCollects, self.voidCollectAt = collects, collectAt
    local nc = 0
    local keepBuf = self.keepBuf or {}
    self.keepBuf = keepBuf
    local skipGray = settings().skipGray ~= false
    local level = ctx.level or 1
    local range = skipGray and ns.Compat.TrivialRange(level) or nil
    local pendQ, pendV = self.voidPendQ or {}, self.voidPendV or {}
    self.voidPendQ, self.voidPendV = pendQ, pendV

    local function open(q) -- neither in the log nor turned in
        local qs = questState(ctx, q)
        return not qs.on and not qs.turnedIn
    end
    local function dead(p) -- a route quest the player never took (accepts so far all "not taken")
        return allVoid[p] == true and open(p)
    end
    -- gray quests are skipped only in segments the player has outgrown (level > levels[2]): a
    -- quest the route takes on purpose while gray at its planned level stays (segments without
    -- levels: always)
    local runs, runOf = self.segRuns, self.segRunOf
    local function ahead(i)
        local run = runs[runOf[i]]
        local lv = run and run.seg.levels
        if type(lv) ~= "table" or type(lv[2]) ~= "number" then return true end
        return level > lv[2]
    end
    -- would the accept of route quest q at index i be skipped as gray?
    local function grayAt(q, i)
        return ahead(i) and self:IsGray(q, level, range)
    end
    -- does the route still lead to an accept of route quest d: one whose step is not passed without
    -- the game (marked, below the sync floor, `optional` and behind the forward limit) and that the
    -- player did not give up? A quest the player has passed or declined protects nothing: the chain
    -- in front of it would only lead to an accept that is not offered any more
    local function wanted(d)
        local g = givenUp[d]
        if g and self.removed[d] then g = nil end -- (the pending QUEST_REMOVED hold: maybe turned in)
        for _, j in ipairs(acceptAt[d] or EMPTY) do
            local sj = steps[j]
            if not (j < floorIndex or isMarked(sj.id) or (sj.optional and not sj.bg and j < limit) or (g and g > j)) then
                return true
            end
        end
        return false
    end
    local protected
    protected = function(q)
        local r = protMemo[q]
        if r ~= nil then return r end
        protMemo[q] = false -- the dependency graph is acyclic (first accepts strictly ordered)
        for _, d in ipairs(deps[q] or EMPTY) do
            if open(d) and wanted(d) and (not grayAt(d, acceptAt[d][1]) or protected(d)) then
                -- an alternative (preAny) already turned in does not need q
                local m = meta[d]
                local needed = true
                local inAll = false
                for _, p in ipairs(type(m) == "table" and type(m.preAll) == "table" and m.preAll or EMPTY) do
                    if p == q then inAll = true end
                end
                if not inAll then
                    for _, p in ipairs(type(m) == "table" and type(m.preAny) == "table" and m.preAny or EMPTY) do
                        if p ~= q and questState(ctx, p).turnedIn then needed = false end
                    end
                end
                if needed then
                    protMemo[q] = true
                    return true
                end
            end
        end
        return false
    end
    local function unreachable(q)
        local m = meta[q]
        if type(m) ~= "table" then return false end
        local all, any = m.preAll, m.preAny
        if type(all) == "table" then
            for _, p in ipairs(all) do
                if p ~= q and acceptAt[p] and dead(p) then return true end
            end
        end
        if type(any) == "table" and #any > 0 then
            for _, p in ipairs(any) do
                if p == q or not acceptAt[p] or not dead(p) then return false end
            end
            return true
        end
        return false
    end
    -- below the sync floor, a quest of the log keeps its route actions there when the jump did not
    -- take the reason for them away: its completion (complete / its objective items) while the route
    -- turns it in at or after the floor, its turn-in once it is complete (see the header)
    local function keepQuest(q) -- in the log, not complete, turned in at or after the floor
        local r = keepQ[q]
        if r == nil then
            local list = turninAt[q]
            r = (list ~= nil and list[#list] >= floorIndex and questState(ctx, q).on and not questComplete(ctx, q))
                and true or false
            keepQ[q] = r
        end
        return r
    end
    local function readyTurnin(q)
        return (questState(ctx, q).on and questComplete(ctx, q)) and true or false
    end
    local function keepItem(item)
        for _, q in ipairs(itemQuests[item] or EMPTY) do
            if keepQuest(q) then return true end
        end
        return false
    end

    for i = 1, n do
        local s = steps[i]
        local acts = s.actions
        local stepVoid = i < floorIndex or isMarked(s.id) or (s.optional and not s.bg and i < limit)
        local np = 0
        for k = 1, #acts do
            local a = acts[k]
            local t = a.type
            if t == "accept" then
                local q = a.quest
                local v = false
                local qs = questState(ctx, q)
                if not qs.on and not qs.turnedIn then
                    -- given up (not the pending QUEST_REMOVED hold: maybe turned in)
                    local g = givenUp[q]
                    if stepVoid or (g and g > i and not self.removed[q]) then
                        v = true
                    elseif skipGray and grayAt(q, i) and not protected(q) then
                        void[a] = "gray"
                        v = true
                    elseif unreachable(q) then
                        void[a] = "unreachable"
                        v = true
                    end
                end
                np = np + 1
                pendQ[np], pendV[np] = q, v
            end
        end
        -- the step's own accepts count for its complete / turnin ({ accept = Q, complete = Q,
        -- turnin = Q } at one NPC), not for the prerequisites of its other accepts (dead above)
        for k = 1, np do
            local q = pendQ[k]
            local c = (seen[q] or 0) + 1
            seen[q] = c
            allVoid[q] = (c == 1 or allVoid[q] == true) and pendV[k]
        end
        for k = 1, #acts do
            local a = acts[k]
            local t = a.type
            if (t == "complete" or t == "turnin") and allVoid[a.quest] == true and open(a.quest) then
                void[a] = "orphan" -- (allVoid is set only after an accept was seen)
            elseif t == "collect" and i >= floorIndex then
                nc = nc + 1
                collects[nc], collectAt[nc] = a, i
            end
        end
        -- below the floor: a step with an action kept for a quest of the log stays (its other actions
        -- are void "floor"); every other step there is done (Evaluate)
        if i < floorIndex then
            local sameStep, any = false, false
            for k = 1, #acts do
                local a = acts[k]
                if a.type == "complete" and keepQuest(a.quest) then sameStep = true end
            end
            for k = 1, #acts do
                local a = acts[k]
                local t = a.type
                local stay = false
                if t == "complete" then
                    stay = keepQuest(a.quest)
                elseif t == "turnin" then
                    stay = readyTurnin(a.quest)
                elseif t == "collect" then
                    stay = sameStep or keepItem(a.item)
                end
                keepBuf[k] = stay
                if stay then any = true end
            end
            if any then
                floorKeep[i] = true
                for k = 1, #acts do
                    if not keepBuf[k] and not void[acts[k]] then void[acts[k]] = "floor" end
                end
            end
        end
    end
    -- collect actions of quests the player never took: the items are needed by nobody. The quests are
    -- the route quests with the item as an objective (questMeta items), else the quests the step
    -- completes / turns in; void when none of them is still possible (dead) or wanted (turned in) and at
    -- least one is dead
    for k = 1, nc do
        local a, i = collects[k], collectAt[k]
        collects[k] = nil
        if not void[a] then
            local deadAny, alive = false, false
            local qs = itemQuests[a.item]
            if qs then
                for _, q in ipairs(qs) do
                    local st = questState(ctx, q)
                    if not st.turnedIn then
                        if allVoid[q] == true and not st.on then
                            deadAny = true
                        else
                            alive = true
                            break
                        end
                    end
                end
            else
                for _, b in ipairs(steps[i].actions) do
                    local t = b.type
                    if t == "complete" or t == "turnin" then
                        if void[b] == "orphan" then
                            deadAny = true
                        elseif not questState(ctx, b.quest).turnedIn then
                            alive = true
                            break
                        end
                    end
                end
            end
            if deadAny and not alive then void[a] = "orphan" end
        end
    end
    return void
end

--- Why a quest action counts as done without the game: "gray" | "unreachable" | "orphan" | nil
-- (last evaluation).
function Engine:VoidReason(action)
    return self.void[action]
end

---------------------------------------------------------------------------
-- evaluation
---------------------------------------------------------------------------

-- One pass over all steps: anchor, done flags, natural cursor, background list.
-- Every refresh runs it (up to MAX_PASSES times), so it reuses its tables instead of
-- allocating per call: the context, the quest-state cache (entries are refreshed in place,
-- stamped with the evaluation number ctx.gen: Steps.QuestState), the item counts and the
-- `done` array (double-buffered: self.done stays the last complete evaluation).
function Engine:Evaluate()
    local steps = self.steps
    local n = #steps
    local Steps = ns.Steps
    local facts = ns.Compat.PlayerFacts()
    self.facts = facts

    self.evalGen = (self.evalGen or 0) + 1
    local ctx = self.evalCtx
    if not ctx then
        ctx = {}
        self.evalCtx = ctx
    end
    ctx.level, ctx.xp, ctx.xpMax, ctx.maxLevel = facts.level, facts.xp, facts.xpMax, facts.maxLevel
    ctx.flags, ctx.forwarded, ctx.manual, ctx.index, ctx.abandonedLater, ctx.givenUp = EMPTY, false, false, nil, nil, nil
    ctx.void = nil -- the anchor below is evidence from the game only (no void actions)
    ctx.gen = self.evalGen
    self.questCache = self.questCache or {}
    ctx.cache = self.questCache
    ctx.items = clear(ctx.items or {})

    -- quests given up by hand (cdb.gaveUp): a record whose quest is turned in, or back
    -- in the log (re-accepted, e.g. while the addon was off) and not for the route's next
    -- accept of it, is dropped with its marks
    local records = gaveUpRecords()
    for q, rec in pairs(records) do
        local qs = type(q) == "number" and type(rec) == "table" and Steps.QuestState(ctx, q)
        if not qs or qs.turnedIn or (qs.on and not self:TakenForNextAccept(q)) then
            self:RestoreQuest(q)
        end
    end
    local autoMarks = {}
    for q, rec in pairs(records) do
        for _, id in ipairs(type(rec.steps) == "table" and rec.steps or EMPTY) do autoMarks[id] = q end
    end
    self.autoMarks = autoMarks

    -- anchor: last non-bg step with evidence whose stateful actions are done (or marked
    -- by the player; GiveUpQuest marks are no evidence)
    local anchor = 0
    for i = n, 1, -1 do
        local s = steps[i]
        if s.stateful and Steps:IsAnchorStep(s) and (isMarkedByPlayer(self, s.id) or Steps:IsStatefulDone(s, ctx)) then
            anchor = i
            break
        end
    end
    local hint = self:ValidHint()
    local limit = max(anchor, hint)

    -- given up: quests whose complete/turnin step the player marked (Skip / Next) or
    -- passed as `optional`, and quests abandoned by hand (cdb.gaveUp: up to the next
    -- accept of the quest after the recorded one) -- the accept and complete/turnin
    -- actions of such a quest before that index stay done once the player abandons it
    -- (see Steps:IsActionDone)
    local givenUp = {}
    for _, e in ipairs(self.questEnds) do
        local j, q = e[1], e[2]
        local s = steps[j]
        if (isMarked(s.id) or (s.optional and j < limit)) and (givenUp[q] or 0) < j then
            givenUp[q] = j
        end
    end
    for q, rec in pairs(records) do
        local a = self.indexById[rec.accept]
        if a then
            local j = self:NextAccept(q, a) or (n + 1)
            if (givenUp[q] or 0) < j then givenUp[q] = j end
        end
    end
    -- quests that just left the log (GiveUpQuest check pending): held up to the cursor
    -- of that moment, so the cursor does not flicker back to their accept meanwhile
    for q, at in pairs(self.removed) do
        local j = (at == END_ID) and (n + 1) or self.indexById[at]
        if j and (givenUp[q] or 0) < j then givenUp[q] = j end
    end
    self.givenUp = givenUp
    ctx.givenUp = givenUp

    -- level sync floor: every step before it is done; void quest actions (gray / unreachable /
    -- orphan, see the header)
    local floorIndex = self:FloorIndex()
    self.floor = floorIndex
    ctx.void = self:ComputeVoid(ctx, limit, floorIndex, givenUp)

    -- non-bg steps first (bg steps never influence them), giving the natural cursor
    -- (every index 1..n is written below; entries past n are dropped)
    local done = self.doneSpare or {}
    for i = #done, n + 1, -1 do done[i] = nil end
    local natural
    for i = 1, n do
        local s = steps[i]
        if i < floorIndex then
            done[i] = true -- below the floor (the steps kept as along-the-way goals: below)
        elseif not s.bg then
            ctx.index = i
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

    -- below the floor: the steps kept for quests of the log (ComputeVoid) and the skipped service
    -- visits later steps still need (KeepServices) are along-the-way goals: their own actions count
    -- (nothing forwarded), the other ones are void ("floor")
    local floorKeep = self.floorKeep
    if floorIndex > 1 then
        self:KeepServices(natural, floorIndex)
        for i in pairs(floorKeep) do
            local s = steps[i]
            ctx.index = i
            ctx.flags = self.flags[s.id] or EMPTY
            ctx.forwarded = false
            ctx.manual = (isMarked(s.id) or isBgDone(s)) and true or false
            ctx.abandonedLater = self.abandonAfter[i]
            done[i] = Steps:IsStepDone(s, ctx)
        end
    end

    local bgDone = ns.cdb.bgDone
    for i = floorIndex > 1 and floorIndex or 1, n do
        local s = steps[i]
        if s.bg then
            ctx.index = i
            ctx.flags = self.flags[s.id] or EMPTY
            ctx.forwarded = (self.bgHome[i] or i) < bgLimit
            ctx.manual = (isMarked(s.id) or isBgDone(s)) and true or false
            ctx.abandonedLater = self.abandonAfter[i]
            local d = Steps:IsStepDone(s, ctx)
            done[i] = d
            -- only a goal the player has reached: items that were in the bags once, long before the
            -- step, may be sold or used up by the time the route gets there
            if d and i < reach and not ctx.manual and not ctx.forwarded and type(bgDone) == "table"
                and needsBgMemory(s) then
                bgDone[s.id] = true -- done by its own actions: keep it done (items consumed / flags lost later)
            end
        end
    end
    ctx.flags, ctx.forwarded, ctx.manual, ctx.abandonedLater, ctx.index = EMPTY, false, false, nil, nil
    self.doneSpare, self.done = self.done, done

    local bg = {}
    local bgEnd = (natural or (n + 1)) - 1
    for i = 1, bgEnd do
        local s = steps[i]
        if floorKeep[i] then
            if not done[i] then bg[#bg + 1] = s end
        elseif s.bg and not done[i] then
            ctx.index = i
            ctx.forwarded = (self.bgHome[i] or i) < bgLimit
            if Steps:IsBackgroundRelevant(s, ctx) then bg[#bg + 1] = s end
        end
    end
    ctx.forwarded, ctx.index = false, nil
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

-- Does a bind location name designate the step's place? (enUS name, the client's
-- localized area name of route data `places[place].area`, or the localized text of
-- route data `places`)
function Engine:PlaceMatches(place, bind)
    if type(place) ~= "string" or type(bind) ~= "string" then return false end
    local b = bind:lower()
    if b == place:lower() then return true end
    local area = ns.Compat.AreaName(ns.Registry:PlaceArea(self.route, place))
    if area and area:lower() == b then return true end
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
        if sethearth and self.void[sethearth] then sethearth = nil end -- below the sync floor, not kept
        if sethearth and not flags.sethearth then
            local bind = Compat.BindLocation()
            local base = self.bindBase[s.id]
            if base == nil then
                self.bindBase[s.id] = bind or false
                base = bind or false
            end
            -- a changed bind counts, except for a bind visit kept below the sync floor (only its own
            -- place: KeptVisitMatches)
            local moved = base and bind ~= base and self:KeptVisitMatches(s, "sethearth")
            if bind and (moved or self:PlaceMatches(sethearth.place, bind)) then
                changed = setFlag(self, s, "sethearth") or changed
            end
        end
        if s.at then
            for _, a in ipairs(s.actions) do
                local t = a.type
                if ns.Steps.ARRIVAL_ACTIONS[t] and not flags[t] and not self.void[a] then
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
    if ok then
        ns:Fire("PROGRESS_UPDATED")
        ns.SafeCall(self.UpdateSync, self)
    end
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
    self.lastGaveUp = nil
    if self.pinned then
        advancePin(self)
    else
        ns.cdb.manual[self.steps[c].id] = true
    end
    self:Refresh()
end

--- "Prev": shows the previous non-bg step. A step that
-- is done only because of a manual/skip mark is un-marked (undo) -- not below the level-sync
-- floor (cdb.syncFloor: those steps are done by the floor, Prev only pins); un-marking a step
-- that ends a quest given up by hand drops that give-up (Engine:RestoreQuest), and so
-- does Prev right after an automatic give-up (Engine:GiveUpQuest): the quest is needed
-- again, the cursor goes back to it.
function Engine:Prev()
    local steps = self.steps
    local n = #steps
    if n == 0 then return end
    local p = (self.cursor or (n + 1)) - 1
    while p >= 1 and steps[p].bg do p = p - 1 end
    if p < 1 then return end
    local s = steps[p]
    -- a step below the level-sync floor is done by the floor: Prev only shows it (pin)
    if p >= (self.floor or 0) then
        local cdb = ns.cdb
        local last = self.lastGaveUp
        if not self.pinned and last and last.natural == self.natural then
            self:RestoreQuest(last.quest) -- undo the give-up that just happened
        end
        -- also while the view is pinned: a skip is not always the step right before the cursor
        -- (Forward on step N with N+1 already done moves the cursor past both)
        if cdb.manual[s.id] or cdb.skipped[s.id] then
            local records = gaveUpRecords()
            for _, a in ipairs(s.actions) do
                if (a.type == "complete" or a.type == "turnin") and records[a.quest] then
                    self:RestoreQuest(a.quest)
                end
            end
            cdb.manual[s.id], cdb.skipped[s.id] = nil, nil
            self.flags[s.id] = nil
            if self:ValidHint() > p then self:SaveHint(p) end
        end
    end
    self.lastGaveUp = nil
    self.pinned = p
    self:Refresh() -- the pin is dropped automatically when p became the natural cursor
end

--- "Skip": marks the displayed step skipped (cdb.skipped).
function Engine:Skip()
    local c = self.cursor
    if not c then return end
    self.lastGaveUp = nil
    ns.cdb.skipped[self.steps[c].id] = true
    if self.pinned then advancePin(self) end
    self:Refresh()
end

--- "Forward" (the UI's single forward button): while a previous step is pinned (Prev /
-- SetCursor), moves the view forward (like Next, nothing is marked); otherwise skips the
-- displayed step (Skip).
function Engine:Forward()
    if not self.cursor then return end
    if self.pinned then
        self.lastGaveUp = nil
        advancePin(self)
        self:Refresh()
    else
        self:Skip()
    end
end

--- Jump to step i: i < natural pins the view, i > natural skips the not-done
-- non-bg steps in between.
function Engine:SetCursor(i)
    i = tonumber(i)
    local n = #self.steps
    if not i or n == 0 then return false end
    i = max(1, min(n, floor(i)))
    self.lastGaveUp = nil
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

--- Forget manual marks, skips (also those of quests given up by hand), the
-- high-water mark, the level-sync floor / dismissal and transient observations of this
-- character (progress derived from the game is kept).
function Engine:Reset()
    local cdb = ns.cdb
    clear(cdb.manual)
    clear(cdb.skipped)
    clear(gaveUpRecords())
    if type(cdb.bgDone) == "table" then clear(cdb.bgDone) end
    cdb.syncFloor, cdb.syncDismissed = nil, nil
    self.lastSync = nil
    self:ClearHint()
    clear(self.flags)
    clear(self.bindBase)
    self.pinned = nil
    self.lastGaveUp = nil
    ns.Print(L().MSG_RESET)
    self:Refresh()
end

---------------------------------------------------------------------------
-- quests abandoned by hand (cdb.gaveUp[questID] = { accept = <step id>, steps = { <step id>, ... } })
---------------------------------------------------------------------------

--- Index of the first step after index i accepting quest q (nil when none).
function Engine:NextAccept(q, i)
    for _, j in ipairs(self.acceptAt[q] or EMPTY) do
        if j > i then return j end
    end
    return nil
end

--- Is quest q (given up, back in the log) taken for the route's NEXT accept of it
-- after the given-up one? True when that accept lies before the end of the accept
-- window (the automation takes it there): the given-up instance stays skipped.
function Engine:TakenForNextAccept(q)
    local rec = gaveUpRecords()[q]
    local a = type(rec) == "table" and self.indexById[rec.accept]
    local a2 = a and self:NextAccept(q, a)
    if not a2 then return false end
    local _, to = self:AcceptWindow()
    return (to ~= nil and a2 <= to) and true or false
end

--- Drop the give-up of quest q: its record and the skip marks GiveUpQuest made
-- (marks the player set himself stay). @return true when there was a record
function Engine:RestoreQuest(q)
    local records = gaveUpRecords()
    local rec = records[q]
    if rec == nil then return false end
    records[q] = nil
    local skipped = ns.cdb.skipped
    if type(rec) == "table" and type(rec.steps) == "table" then
        for _, id in ipairs(rec.steps) do
            skipped[id] = nil
            self.autoMarks[id] = nil
        end
    end
    if self.lastGaveUp and self.lastGaveUp.quest == q then self.lastGaveUp = nil end
    return true
end

--- QUEST_REMOVED (not a replay quest): remember where the player was and check
-- GIVE_UP_DELAY later whether the quest was abandoned rather than turned in.
-- Until then the quest is held up to that point (Evaluate), see Engine:GiveUpQuest.
function Engine:NoteQuestRemoved(q)
    if not self.started or not self.route or type(q) ~= "number" then return end
    local n = #self.steps
    if n == 0 or self.removed[q] or not self.acceptAt[q] then return end
    -- the evaluation before the removal (refreshes are throttled)
    local reach = max(self.natural or (n + 1), self.cursor or 0)
    self.removed[q] = (reach > n) and END_ID or self.steps[reach].id
    local function check()
        local at = Engine.removed[q]
        if not at then return end
        Engine.removed[q] = nil
        if not Engine:GiveUpQuest(q, at) then Engine:RequestRefresh() end -- release the hold
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(GIVE_UP_DELAY, check)
    else
        check()
    end
end

--- A route quest left the log: when it was not turned in, is not back in the log,
-- the route accepted it before the cursor (`at` = step id or END_ID of the natural
-- cursor when it was removed; the high-water mark counts too) and that instance of
-- the quest has no explicit `abandon` step, the quest is given up: the not-done
-- non-bg steps whose actions are all complete/turnin of it (between its accept and
-- the next accept of it) are skipped and the give-up is recorded (cdb.gaveUp), so
-- the cursor stays and the quest is not auto-accepted again. Steps mixing it with
-- other actions are not marked: its complete/turnin actions there count as done
-- (ctx.givenUp), the step waits for its other actions.
-- @return true when the quest was given up
function Engine:GiveUpQuest(q, at)
    if not self.started or not self.route or type(q) ~= "number" then return false end
    local C = ns.Compat
    if C.IsQuestTurnedIn(q) or C.IsOnQuest(q) then return false end
    if not self.acceptAt[q] then return false end -- not a route quest
    local steps, n = self.steps, #self.steps
    local ref = self:ValidHint()
    local atIndex = (at == END_ID) and (n + 1) or (at and self.indexById[at]) or 0
    if atIndex > ref then ref = atIndex end
    -- the accept of this instance: the last accept before the cursor (none: taken early
    -- through the lookahead, the route's accept is still ahead -- normal flow)
    local a, a2
    for _, i in ipairs(self.acceptAt[q] or EMPTY) do
        if i < ref then a = i else a2 = i; break end
    end
    if not a then return false end
    a2 = a2 or (n + 1)
    -- the route drops this instance itself: leave that flow alone
    for i = a + 1, a2 - 1 do
        if hasQuestAction(steps[i], "abandon", q) then return false end
    end
    -- steps to mark: not done -- complete/turnin of a quest neither in the log nor turned
    -- in are done only through a mark (or as an optional step behind the forward limit)
    -- steps below the level-sync floor are done by the floor: nothing to give up there (a quest of
    -- a skipped zone abandoned to clean the log)
    local floorIndex = self.floor or 0
    local marks, last = {}, nil
    for i = max(a + 1, floorIndex), a2 - 1 do
        local s = steps[i]
        if not s.bg and (hasQuestAction(s, "complete", q) or hasQuestAction(s, "turnin", q)) then
            last = i
            if endsOnly(s, q) and not isMarked(s.id) and not (s.optional and i < self.forwardLimit) then
                marks[#marks + 1] = s.id
            end
        end
    end
    local records = gaveUpRecords()
    local old = records[q]
    if not last and a < floorIndex and old == nil then return false end
    if old ~= nil and (type(old) ~= "table" or old.accept ~= steps[a].id or type(old.steps) ~= "table") then
        self:RestoreQuest(q) -- a stale record (another accept / route)
        old = nil
    end
    if #marks == 0 and not old and last then
        -- already given up through the player's marks / passed optional steps up to its
        -- last step (Evaluate's questEnds rule): nothing to do
        local j = 0
        for _, e in ipairs(self.questEnds) do
            local s = steps[e[1]]
            if e[2] == q and (isMarked(s.id) or (s.optional and e[1] < self.forwardLimit)) and e[1] > j then
                j = e[1]
            end
        end
        if j >= last then return false end
    end
    local rec = old or { accept = steps[a].id, steps = {} }
    local skipped = ns.cdb.skipped
    for _, id in ipairs(marks) do
        skipped[id] = true
        rec.steps[#rec.steps + 1] = id
    end
    records[q] = rec
    if not old or #marks > 0 then
        ns.Print(L().MSG_QUEST_GIVEN_UP, ns.Steps:QuestTitle(q))
    end
    self:Refresh()
    self.lastGaveUp = { quest = q, natural = self.natural }
    return true
end

---------------------------------------------------------------------------
-- level sync (settings.levelSync / levelSyncMargin, cdb.syncFloor / syncDismissed)
---------------------------------------------------------------------------

local SYNC_MODES = { ask = true, auto = true, off = true }

--- Level-sync mode: "ask" | "auto" | "off" (an unknown value counts as the default "ask").
function Engine:SyncMode()
    local m = settings().levelSync
    if SYNC_MODES[m] then return m end
    return "ask"
end

--- Level-sync margin (settings.levelSyncMargin, a whole number 0..5).
function Engine:SyncMargin()
    local v = tonumber(settings().levelSyncMargin)
    if ns.ClampSetting then return ns.ClampSetting("levelSyncMargin", v) end
    return v or 2
end

--- Is the segment outleveled at `level`? (level >= segment.levels[2] + margin; a segment
-- without `levels` never is)
function Engine:IsOutleveled(seg, level, margin)
    local lv = type(seg) == "table" and seg.levels
    if type(lv) ~= "table" or type(lv[2]) ~= "number" then return false end
    return (level or 1) >= lv[2] + (margin or self:SyncMargin())
end

local function segTitle(seg)
    local t = seg and ns.Schema.Text(seg.title, ns.locale)
    if type(t) == "string" and t ~= "" then return t end
    return tostring(seg and seg.id or "?")
end

-- service visits a level sync keeps as along-the-way goals when it skips them (cdb.syncFloor.keep)
local KEEP_SERVICE = { train = true, sethearth = true, fp = true }

local function hasPlaceAction(step, actionType, place)
    for _, a in ipairs(step.actions) do
        if a.type == actionType and (place == nil or a.place == place) then return true end
    end
    return false
end

--- Up to which step a skipped service visit (step i, action `entry.type`) is still needed after a
-- floor at floorIndex (the natural cursor must not be past it), nil when no later step needs it:
--   train      until the step before the next (not optional) trainer visit at/after the floor (none:
--              the end of the route) -- training later teaches the skipped spells too;
--   sethearth  until the last `hearth` to its place at/after the floor before the next `sethearth`;
--   fp         until the last `fly` to that place at/after the floor before the next `fp` of it.
function Engine:KeepUntil(i, entryType, floorIndex)
    local cache = self.keepUntil
    if not cache or cache.floor ~= floorIndex then
        cache = { floor = floorIndex }
        self.keepUntil = cache
    end
    local key = entryType .. "@" .. i
    local v = cache[key]
    if v ~= nil then return v or nil end
    local steps, n = self.steps, #self.steps
    local s = steps[i]
    local result
    if entryType == "train" then
        result = n
        for j = floorIndex, n do
            local sj = steps[j]
            if not sj.bg and not sj.optional and hasPlaceAction(sj, "train") then
                result = j - 1
                break
            end
        end
        if result < floorIndex then result = nil end
    else
        local place
        for _, a in ipairs(s.actions) do
            if a.type == entryType then place = a.place end
        end
        local need = (entryType == "sethearth") and "hearth" or "fly"
        for j = floorIndex, n do
            local sj = steps[j]
            -- a later bind (anywhere) / flight path visit of the same place makes it moot
            if hasPlaceAction(sj, entryType, entryType == "fp" and place or nil) then break end
            if hasPlaceAction(sj, need, place) then result = j end
        end
    end
    cache[key] = result or false
    return result
end

--- The skipped service visits of the active floor record (cdb.syncFloor.keep = { { id = <step id>,
-- type = "train" | "sethearth" | "fp" }, ... }) that are still pending and needed (KeepUntil): adds
-- their steps to self.floorKeep (their other actions void "floor", the kept action not). A visit
-- done (its transient flag: memory only) or no longer needed leaves the record (persisted).
function Engine:KeepServices(natural, floorIndex)
    local f = self:GetSyncFloor()
    local list = f and f.keep
    if type(list) ~= "table" then return end
    local steps, void, keep = self.steps, self.void, self.floorKeep
    local reach = natural or (#steps + 1)
    local kept -- [index] = { [type] = true }
    local k = 1
    while k <= #list do
        local e = list[k]
        local i = type(e) == "table" and type(e.id) == "string" and self.indexById[e.id]
        local alive = false
        if i and i < floorIndex and KEEP_SERVICE[e.type] and hasPlaceAction(steps[i], e.type) then
            local flags = self.flags[e.id]
            local untilIndex = not (flags and flags[e.type]) and self:KeepUntil(i, e.type, floorIndex)
            alive = untilIndex and reach <= untilIndex or false
        end
        if alive then
            kept = kept or {}
            kept[i] = kept[i] or {}
            kept[i][e.type] = true
            k = k + 1
        else
            table.remove(list, k)
        end
    end
    for i, types in pairs(kept or EMPTY) do
        local questKept = keep[i]
        keep[i] = true
        for _, a in ipairs(steps[i].actions) do
            if types[a.type] then
                if void[a] == "floor" then void[a] = nil end
            elseif not questKept and not void[a] then
                void[a] = "floor"
            end
        end
    end
end

--- The service visits a jump from the natural cursor to toIndex skips (not done, not bg, not optional,
-- plus the still pending ones of the previous floor) that later steps need: the last trainer visit,
-- the last hearthstone bind and, per place, the last flight path. @return array for record.keep
function Engine:SkippedServices(fromIndex, toIndex, prev)
    local steps, done = self.steps, self.done
    local last = {} -- [type or "fp@place"] = { id, type, index }
    local function consider(i, t)
        local s = steps[i]
        local key = t
        if t == "fp" then
            for _, a in ipairs(s.actions) do
                if a.type == "fp" then key = "fp@" .. tostring(a.place) end
            end
        end
        local cur = last[key]
        if not cur or cur.index < i then last[key] = { id = s.id, type = t, index = i } end
    end
    if type(prev) == "table" and type(prev.keep) == "table" then
        for _, e in ipairs(prev.keep) do
            local i = type(e) == "table" and self.indexById[e.id]
            if i and KEEP_SERVICE[e.type] then consider(i, e.type) end
        end
    end
    for i = fromIndex or toIndex, toIndex - 1 do
        local s = steps[i]
        if not s.bg and not s.optional and not done[i] then
            for _, a in ipairs(s.actions) do
                if KEEP_SERVICE[a.type] then consider(i, a.type) end
            end
        end
    end
    local out = {}
    for _, e in pairs(last) do
        if self:KeepUntil(e.index, e.type, toIndex) then out[#out + 1] = e end
    end
    table.sort(out, function(a, b) return a.index < b.index or (a.index == b.index and a.type < b.type) end)
    for k, e in ipairs(out) do out[k] = { id = e.id, type = e.type } end
    return out
end

--- Is the flight path to `place` a skipped visit of the level sync that is still pending (the
-- `fly` steps to it show a hint: travel there yourself)?
function Engine:FlightPathPending(place)
    if type(place) ~= "string" or (self.floor or 0) <= 1 then return false end
    local f = self:GetSyncFloor()
    for _, e in ipairs(f and type(f.keep) == "table" and f.keep or EMPTY) do
        if type(e) == "table" and e.type == "fp" then
            local i = self.indexById[e.id]
            local s = i and self.floorKeep[i] and self.steps[i]
            if s and hasPlaceAction(s, "fp", place) then return true end
        end
    end
    return false
end

--- After a level sync (a floor is active): the hearthstone's bind location when it is known and is
-- not `place` (the `hearth` step shows a hint), else nil.
function Engine:HearthBindMismatch(place)
    if type(place) ~= "string" or (self.floor or 0) <= 1 then return nil end
    local bind = ns.Compat.BindLocation()
    if not bind or self:PlaceMatches(place, bind) then return nil end
    return bind
end

--- Would a jump from the natural cursor to toIndex skip new content of the outleveled part: an
-- accept of a quest the player does not have and that the route turns in before toIndex? The rest
-- is no reason to jump: quests of the log (being done: they are finished or turned in on the way),
-- quests the next segments turn in (bridges), trainer / travel / service visits and level gates.
function Engine:SyncSkipsContent(fromIndex, toIndex)
    local steps, done, void, turninAt = self.steps, self.done, self.void, self.turninAt
    local ctx = self.evalCtx
    local questState = ns.Steps.QuestState
    for i = fromIndex, toIndex - 1 do
        local s = steps[i]
        if not s.bg and not done[i] then
            for _, a in ipairs(s.actions) do
                if a.type == "accept" and not void[a] then
                    local list = turninAt[a.quest]
                    if not (list and list[#list] >= toIndex) then
                        local st = questState(ctx, a.quest)
                        if not st.on and not st.turnedIn then return true end
                    end
                end
            end
        end
    end
    return false
end

--- The level-sync suggestion for the last evaluation (nil when there is none):
-- { level = <player level>, from = <segment of the natural cursor>, fromIndex = <natural cursor>,
--   to = <first later segment that is not outleveled>, toIndex = <its first not-done non-bg step>,
--   toStepId = <id of that step>, margin = <margin> }.
-- @param force ignore the mode ("off") and a dismissal (explicit /fb sync)
function Engine:ComputeSyncSuggestion(force)
    if not force and self:SyncMode() == "off" then return nil end
    local route, nat = self.route, self.natural
    if not route or not nat or not self.started then return nil end
    local runIdx = self.segRunOf[nat]
    local run = runIdx and self.segRuns[runIdx]
    if not run then return nil end
    local facts = self.facts or ns.Compat.PlayerFacts()
    local level = facts.level or 1
    local margin = self:SyncMargin()
    if not self:IsOutleveled(run.seg, level, margin) then return nil end
    local d = ns.cdb.syncDismissed
    if not force and type(d) == "table" and d.route == route.id and d.segment == run.id and d.level == level then
        return nil
    end
    local steps, done = self.steps, self.done
    for r = runIdx + 1, #self.segRuns do
        local cand = self.segRuns[r]
        local lv = cand.seg.levels
        if type(lv) == "table" and not self:IsOutleveled(cand.seg, level, margin) then
            for i = cand.first, cand.last do
                if not steps[i].bg and not done[i] then
                    -- nothing worth skipping (the segment's last turn-ins / visits): no jump
                    if not self:SyncSkipsContent(nat, i) then return nil end
                    return {
                        level = level, from = run.seg, fromIndex = nat, to = cand.seg, toIndex = i,
                        toStepId = steps[i].id, margin = margin,
                    }
                end
            end
        end
    end
    return nil
end

--- Current level-sync suggestion (see ComputeSyncSuggestion) or nil. "auto" applies it at once,
-- so it is nil there (except while a sync is being applied).
function Engine:GetSyncSuggestion()
    return self.syncSuggestion
end

local function suggestionKey(sug)
    if not sug then return nil end
    return ("%s>%s@%d#%d"):format(tostring(sug.from and sug.from.id), tostring(sug.to and sug.to.id),
        sug.toIndex or 0, sug.level or 0)
end

-- store the suggestion; fire SYNC_SUGGESTION when it appeared / changed / disappeared
function Engine:SetSyncSuggestion(sug)
    local key = suggestionKey(sug)
    if key == self.syncKey then
        -- unchanged: keep the table the listeners got (only the natural cursor may have moved)
        if sug and self.syncSuggestion then self.syncSuggestion.fromIndex = sug.fromIndex end
        return
    end
    self.syncKey = key
    self.syncSuggestion = sug
    ns:Fire("SYNC_SUGGESTION", sug)
end

--- Recompute the suggestion after an evaluation (Refresh); "auto" applies it.
function Engine:UpdateSync()
    local sug = self:ComputeSyncSuggestion()
    if sug and not self.applyingSync and self:SyncMode() == "auto" then
        -- not from the first evaluation at login: with the quest log not loaded yet its quests look
        -- "not taken" and a jump would be saved (and report them as dropped)
        if not self.logReady then
            self:SetSyncSuggestion(nil)
            return
        end
        self:ApplySync(true)
        return
    end
    self:SetSyncSuggestion(sug)
end

--- Apply the level sync: the steps before the suggested segment's first not-done step count as
-- done (cdb.syncFloor, per character, for this route). Prints a chat line; the refresh fires
-- STEP_CHANGED / PROGRESS_UPDATED, then SYNC_APPLIED(record).
-- @param auto true when the "auto" mode applies it (other chat line)
-- @return true when a sync was applied (false: no outleveled segment / nothing fits)
function Engine:ApplySync(auto)
    local sug = self:ComputeSyncSuggestion(true)
    if not sug or self.applyingSync then return false end
    local cdb = ns.cdb
    local route = self.route
    local prev = cdb.syncFloor
    if type(prev) == "table" then
        prev.prev = nil -- one level of undo
    else
        prev = nil
    end
    local record = {
        route = route.id, stepId = sug.toStepId, from = sug.from.id, to = sug.to.id, level = sug.level,
        at = self.steps[sug.fromIndex] and self.steps[sug.fromIndex].id or nil,
        hint = { cdb.cursorHint, cdb.cursorHintId, cdb.cursorHintRoute },
        keep = self:SkippedServices(sug.fromIndex, sug.toIndex, prev),
        prev = prev,
    }
    cdb.syncFloor = record
    cdb.syncDismissed = nil
    self.pinned = nil
    self.lastGaveUp = nil
    self.lastSync = { at = now(), record = record }
    local Lc = L()
    ns.Print(auto and Lc.MSG_SYNC_AUTO or Lc.MSG_SYNC_APPLIED, sug.level, segTitle(sug.to), segTitle(sug.from))
    self.applyingSync = true
    self:Refresh()
    self.applyingSync = false
    self:ReportDroppedQuests()
    self:SetSyncSuggestion(self:ComputeSyncSuggestion())
    ns:Fire("SYNC_APPLIED", record)
    return true
end

--- Quests of the log the route no longer leads to because of the sync floor: not complete, every
-- turn-in of them below the floor (sorted ids; empty without a floor).
function Engine:GetDroppedQuests()
    local out = {}
    local floorIndex = self.floor or 0
    if floorIndex <= 1 then return out end
    local C = ns.Compat
    for q, list in pairs(self.turninAt) do
        if list[#list] < floorIndex and C.IsOnQuest(q) and not C.IsQuestComplete(q) then out[#out + 1] = q end
    end
    table.sort(out)
    return out
end

-- After a jump: one chat line naming the quests of the log the route no longer leads to (the player
-- finishes or abandons them).
local MAX_LISTED = 5
function Engine:ReportDroppedQuests()
    local list = self:GetDroppedQuests()
    if #list == 0 then return end
    local shown = {}
    for k = 1, min(#list, MAX_LISTED) do shown[k] = ns.Steps:QuestTitle(list[k]) end
    local text = table.concat(shown, ", ")
    if #list > MAX_LISTED then text = text .. ", ..." end
    ns.Print(L().MSG_SYNC_DROPPED, #list, text)
end

--- No suggestion for the current `from` segment until the next level-up (cdb.syncDismissed).
-- @return true when there was a suggestion
function Engine:DismissSync()
    local sug = self.syncSuggestion or self:ComputeSyncSuggestion()
    if not sug or not self.route then return false end
    ns.cdb.syncDismissed = { route = self.route.id, segment = sug.from.id, level = sug.level }
    self:SetSyncSuggestion(nil)
    return true
end

--- Undo the last level sync: the previous floor (or none) and the high-water mark of the moment
-- of the sync come back; the segment it jumped from is not suggested again until the next
-- level-up ("auto" would jump again at once). Fires SYNC_UNDONE after the refresh.
-- @return true when a floor was removed
function Engine:UndoSync()
    local cdb = ns.cdb
    local f = cdb.syncFloor
    local route = self.route
    -- only the floor of the active route (a floor of another route stays for that route)
    if type(f) ~= "table" or not route or f.route ~= route.id then return false end
    cdb.syncFloor = type(f.prev) == "table" and f.prev or nil
    if type(f.hint) == "table" then
        cdb.cursorHint, cdb.cursorHintId, cdb.cursorHintRoute = f.hint[1], f.hint[2], f.hint[3]
    end
    if type(f.from) == "string" then
        local level = (self.facts or ns.Compat.PlayerFacts()).level
        cdb.syncDismissed = { route = route.id, segment = f.from, level = level }
    end
    self.lastSync = nil
    self.pinned = nil
    self.lastGaveUp = nil
    ns.Print(L().MSG_SYNC_UNDONE)
    self:Refresh()
    ns:Fire("SYNC_UNDONE")
    return true
end

--- The last sync applied in this session ({ at = GetTime(), record = cdb.syncFloor }) while its
-- floor is still active, else nil (the UI's "undo" link).
function Engine:GetLastSync()
    local ls = self.lastSync
    if ls and ns.cdb.syncFloor == ls.record then return ls end
    return nil
end

---------------------------------------------------------------------------
-- queries for Automation
---------------------------------------------------------------------------

local function addAccepts(set, step, void)
    for _, a in ipairs(step.actions) do
        if a.type == "accept" and not void[a] then set[a.quest] = true end
    end
end

--- Accept window [from, to]: from the smaller of displayed/natural cursor to the
-- larger + lookahead (nil when the route is finished).
function Engine:AcceptWindow()
    local a, b = self.cursor, self.natural
    if not (a or b) then return nil end
    local look = tonumber(settings().lookahead) or 6
    return min(a or b, b or a), min(#self.steps, max(a or 0, b or 0) + look)
end

--- Quests that may be auto-accepted: accept actions of the steps in the accept
-- window [cursor, cursor + lookahead] plus the active background steps -- not the void ones
-- (gray / unreachable quests the route skips: the player may still take them by hand).
function Engine:GetAcceptQuests()
    local set = {}
    local steps = self.steps
    local void = self.void
    local from, to = self:AcceptWindow()
    if from then
        for i = from, to do addAccepts(set, steps[i], void) end
    end
    for _, s in ipairs(self.bg) do addAccepts(set, s, void) end
    return set
end

--- Quests that may be auto-turned-in: every turnin action of the filtered route.
function Engine:GetTurninQuests()
    return self.turninSet
end

--- Reward choice index: a step's `reward = { [questID] = index }` wins (steps turning the quest
-- in are preferred over other steps); otherwise the class reward table of the route data,
-- `rewards = { CLASS = { [questID] = index } }` (AddLibraryData / AddRouteData: the choice for a
-- quest turned in on a shared step, which cannot carry a per-class `reward`).
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
    if fallback then return fallback end
    local data = self.route and self.route.data
    local rewards = type(data) == "table" and data.rewards
    local class = (self.facts or ns.Compat.PlayerFacts()).class
    local mine = type(rewards) == "table" and class and rewards[class]
    local idx = type(mine) == "table" and mine[questID] or nil
    -- same validity rule as a step's `reward` (Schema: a positive integer index)
    if type(idx) == "number" and idx >= 1 and idx % 1 == 0 then return idx end
    return nil
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
    -- selecting the route composes only the routes this character can use (the saved choice,
    -- Registry:Matching); the others are composed only when chosen (/fb route <id>), so a paladin
    -- does not pay for the routes of the other races and classes (/fb routes and the settings list
    -- them without composing). Their composition errors are reported then; the ones of the usable
    -- routes are part of this report.
    local route = self:SelectRoute()
    local errors = ns.Registry.errors
    if #errors > 0 then
        ns.Print(L().MSG_ROUTE_ERRORS, #errors, tostring(errors[1]))
    end
    self:ActivateRoute(route, true)
    -- the quest log is trusted from the first QUEST_LOG_UPDATE on (below), or after this delay if
    -- the client sends none
    if C_Timer and C_Timer.After then
        C_Timer.After(LOG_READY_DELAY, function() Engine:SetLogReady() end)
    else
        self.logReady = true
    end
end

--- The quest log can be read: the "auto" level sync may apply from now on.
function Engine:SetLogReady()
    if self.logReady then return end
    self.logReady = true
    if self.started then self:RequestRefresh() end
end

ns:On("QUEST_LOG_UPDATE", function()
    if Engine.started then Engine:SetLogReady() end
end)

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

ns:Listen("QUEST_DATA_LOADED", function(_, questID)
    if questID ~= nil then Engine.grayCache[questID] = nil end -- the client may now answer IsQuestTrivial
    refresh()
end)
ns:Listen("ITEM_DATA_LOADED", refresh)

-- settings that change what is done / suggested (UI.SetSetting fires SETTINGS_CHANGED)
local SYNC_SETTINGS = { levelSync = true, levelSyncMargin = true, skipGray = true }
ns:Listen("SETTINGS_CHANGED", function(_, key)
    if key == nil or SYNC_SETTINGS[key] then refresh() end
end)

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

-- a quest left the log: abandoned by hand (given up) or turned in? (checked later)
ns:On("QUEST_REMOVED", function(_, questID, wasReplayQuest)
    local Compat = ns.Compat
    if Compat.IsSecret(questID) or type(questID) ~= "number" then return end
    if wasReplayQuest and not Compat.IsSecret(wasReplayQuest) then return end
    Engine:NoteQuestRemoved(questID)
end)

-- re-accepting a quest given up by hand: its steps are needed again
ns:On("QUEST_ACCEPTED", function(_, a, b)
    local Compat = ns.Compat
    local questID = a
    if not Compat.IsSecret(b) and type(b) == "number" then questID = b end -- (logIndex, questID) payload
    if Compat.IsSecret(questID) or type(questID) ~= "number" then return end
    if Engine.started and gaveUpRecords()[questID] ~= nil and not Engine:TakenForNextAccept(questID) then
        Engine:RestoreQuest(questID)
        refresh()
    end
end)

-- transient observations ---------------------------------------------------

local KEPT_FP_RADIUS = 100 -- yards: a kept flight-path visit counts at a taxi map opened this close to it

--- Does a window / bind event count for step s? Always, except for a skipped visit kept below the
-- sync floor (several of them can be "along the way" at once, anywhere in the world): its flight
-- path only at a taxi map opened near the step's place (step.at), its bind only when the bind
-- location is its place.
function Engine:KeptVisitMatches(s, actionType)
    local i = self.indexById[s.id]
    if not (i and i < (self.floor or 0) and self.floorKeep[i]) then return true end
    if actionType == "fp" then
        if not s.at then return true end
        local d = ns.Compat.DistanceTo(s.at.map, s.at.x, s.at.y)
        return d ~= nil and d <= max(s.radius or 0, KEPT_FP_RADIUS)
    elseif actionType == "sethearth" then
        local a = ns.Steps:HasAction(s, "sethearth")
        local bind = ns.Compat.BindLocation()
        return (a and bind and self:PlaceMatches(a.place, bind)) and true or false
    end
    return true
end

--- Mark a transient action type done on the observed steps that have it.
-- @return true when a step was flagged
function Engine:ObserveAction(actionType)
    if not self.started then return false end
    local any = false
    for _, s in ipairs(self:ObservedSteps()) do
        if ns.Steps:HasAction(s, actionType) and self:KeptVisitMatches(s, actionType) then
            any = setFlag(self, s, actionType) or any
        end
    end
    if any then self:Refresh() end
    return any
end

-- Is the window of NPC `npc` the one of step s? A step without `npc`, or an NPC id that
-- cannot be read (nil), matches any window.
local function windowNpcMatches(s, npc)
    if not npc or type(s.npc) ~= "table" or #s.npc == 0 then return true end
    for _, id in ipairs(s.npc) do
        if id == npc then return true end
    end
    return false
end

-- A taxi map of another flight master than the step's (the player flies part of the way to a new
-- flight point) does not learn the step's point -- unless it was opened at the step's place (the
-- route may name another NPC than the one standing there).
local function fpWindowMatches(s, npc)
    if windowNpcMatches(s, npc) then return true end
    if not s.at then return false end
    local d = ns.Compat.DistanceTo(s.at.map, s.at.x, s.at.y)
    return d ~= nil and d <= max(s.radius or 0, KEPT_FP_RADIUS)
end

-- ids of the observed steps that have an action of the given type (and, when `npc` is
-- given, whose `npc` list contains it -- or that have no `npc`; a flight path: fpWindowMatches)
function Engine:ObservedIds(actionType, npc)
    local ids = {}
    local matches = (actionType == "fp") and fpWindowMatches or windowNpcMatches
    for _, s in ipairs(self:ObservedSteps()) do
        if ns.Steps:HasAction(s, actionType) and matches(s, npc) and self:KeptVisitMatches(s, actionType) then
            ids[#ids + 1] = s.id
        end
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

-- window kinds whose NPC must be the step's `npc` (a riding trainer next to the class
-- trainer, a vendor next to the quest giver must not complete the step)
local NPC_WINDOWS = { train = true, vendor = true, fp = true }

--- A trainer ("train") / merchant ("vendor") / taxi map ("fp") window opened.
-- The client fires the legacy event AND the interaction-manager event for the
-- same window: the second one (same kind, while open, within DUP_WINDOW) is
-- ignored. The observed steps are taken now (after a fresh evaluation, so a
-- pending throttled refresh -- e.g. after the turn-in that precedes a train
-- step at the same NPC -- is applied); a train/vendor step is flagged when the
-- window closes, an fp step right away (opening the map is the action).
-- Trainer / merchant windows count only for the steps whose `npc` list contains the
-- window's NPC (UnitGUID("npc")); steps without `npc`, or a window whose NPC id cannot
-- be read, keep the old rule (any window of that kind).
function Engine:WindowOpened(actionType)
    if not self.started then return false end
    local w = windowState(self, actionType)
    local t = now()
    if w.open and w.openedAt and (t - w.openedAt) < DUP_WINDOW then return false end
    self:Refresh()
    w.open, w.openedAt = true, t
    w.npc = NPC_WINDOWS[actionType] and ns.Compat.GetNpcIdFromUnit("npc") or nil
    w.ids = self:ObservedIds(actionType, w.npc)
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
    w.open, w.ids, w.npc, w.closedAt = false, nil, nil, t
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
