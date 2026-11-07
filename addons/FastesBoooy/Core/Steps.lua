-- FastesBoooy / Core / Steps.lua
--
-- Action handlers (is an action / step done?) and step descriptions for the UI.
-- Pure functions of (step, ctx): game state is read through ns.Compat, the
-- transient observations (window opened, arrival...) come from the engine via
-- ctx.flags.
--
-- ctx (built by ns.Engine; every field optional):
--   level, xp, xpMax  player facts (read from ns.Compat when absent)
--   flags             { [actionType] = true } transient actions observed while the step was current
--   forwarded         true when a later stateful step is done (or the step lies below the saved
--                     high-water mark): transient actions count as done, optional steps are done
--   manual            true when the step is marked done ("Next") or skipped
--   abandonedLater    { [questID] = true } quests abandoned by a LATER step of the route
--   givenUp           { [questID] = j } quests the player gave up, counted for the steps before
--                     index j: j = last index of a non-bg step with its complete/turnin that is
--                     marked or `optional` and forwarded, or -- quest abandoned by hand
--                     (cdb.gaveUp, see Core/Engine.lua) -- the next accept of it after the
--                     recorded one (#steps + 1 when none)
--   index             index of the step in the engine's filtered list (compared with givenUp)
--   cache             per-evaluation memo table for quest state (shared between steps)
--   items             per-evaluation memo table for item counts
--
-- Non-monotonic stateful actions behind the forward limit (ctx.forwarded) stay done:
-- `collect` (the items are normally consumed by a later turn-in) and `accept` of a
-- quest that a later step abandons -- otherwise the cursor would jump back to them.
-- A quest the player gave up (a later complete/turnin step of it skipped, marked done
-- or passed as optional, or the quest abandoned by hand -- Engine:GiveUpQuest; ctx.givenUp)
-- counts while it is neither in the log nor turned in: its `accept` and, on non-bg steps,
-- its `complete`/`turnin` before the given-up index stay done, so the cursor does not go
-- back to them and a step that mixes it with other quests waits only for the others
-- (the order "abandon, then skip" or "skip, then abandon" does not matter).
-- `complete` is not forwarded (its state is readable while the quest is in the log and
-- turned-in quests count as complete); neither is `abandon` (a route that takes the
-- same quest again later would make that second accept an anchor and skip the abandon).

local _, ns = ...
-- luacheck: ignore 212/self 212/step

local type, ipairs, pairs, tostring, floor, min = type, ipairs, pairs, tostring, math.floor, math.min
local concat = table.concat

local Steps = {}
ns.Steps = Steps

local EMPTY = {}

-- action types whose completion counts as evidence that the player progressed
-- to a step (used for fast-forwarding transient/optional steps). `abandon` is
-- excluded (vacuously true for never-accepted quests), so is `collect` (items may
-- be in the bags by accident) and so is `level` (a level can be reached early --
-- rested XP, grinding, a group -- without having done the earlier steps: a lone
-- level step must not forward an earlier sethearth / train / fp).
Steps.ANCHOR_ACTIONS = { accept = true, turnin = true, complete = true }

-- actions completed by arriving at step.at
Steps.ARRIVAL_ACTIONS = { go = true, fly = true, hearth = true }

-- icons per action type (atlases verified in the Forever AtlasInfo dump)
Steps.ICONS = {
    accept = "QuestNormal",
    turnin = "QuestTurnin",
    complete = "SmallQuestBang",
    abandon = "common-icon-redx",
    level = "GreenCross",
    go = "Navigation-Tracked-Icon",
    train = "Class",
    fp = "FlightMaster",
    fly = "FlightMaster",
    sethearth = "Innkeeper",
    hearth = "Innkeeper",
    vendor = "Food",
    manual = "common-icon-checkmark",
}
Steps.ITEM_FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

---------------------------------------------------------------------------
-- state helpers (memoized per evaluation through ctx.cache / ctx.items)
---------------------------------------------------------------------------

local function questState(ctx, q)
    local cache = ctx and ctx.cache
    local s = cache and cache[q]
    if s then return s end
    local C = ns.Compat
    s = { turnedIn = C.IsQuestTurnedIn(q) }
    s.on = (not s.turnedIn) and C.IsOnQuest(q) or false
    if cache then cache[q] = s end
    return s
end
Steps.QuestState = questState

local function questComplete(ctx, q)
    local s = questState(ctx, q)
    if s.complete == nil then
        s.complete = s.on and ns.Compat.IsQuestComplete(q) or false
    end
    return s.complete
end

local function questObjectives(ctx, q)
    local s = questState(ctx, q)
    if s.objectives == nil then
        s.objectives = s.on and ns.Compat.GetObjectives(q) or EMPTY
    end
    return s.objectives
end

local function itemCount(ctx, item)
    local items = ctx and ctx.items
    local n = items and items[item]
    if n == nil then
        n = ns.Compat.ItemCount(item)
        if items then items[item] = n end
    end
    return n
end

-- Is quest q given up for the step being evaluated? (ctx.givenUp[q] beyond ctx.index)
local function givenUp(ctx, q)
    local j = ctx and ctx.givenUp and ctx.givenUp[q]
    return (j and ctx.index and j > ctx.index) and true or false
end

local function playerLevel(ctx)
    local level, xp, xpMax = ctx and ctx.level, ctx and ctx.xp, ctx and ctx.xpMax
    if level == nil then
        local f = ns.Compat.PlayerFacts()
        level, xp, xpMax = f.level, f.xp, f.xpMax
        if ctx then ctx.level, ctx.xp, ctx.xpMax = level, xp, xpMax end
    end
    return level or 1, xp or 0, xpMax or 0
end

---------------------------------------------------------------------------
-- completion
---------------------------------------------------------------------------

--- Is one normalized action done?
-- accept:   quest in the log or turned in (or forwarded and abandoned by a later step,
--           or given up: ctx.givenUp, see the header)
-- turnin:   quest turned in (or, on a non-bg step, given up and not in the log)
-- complete: quest turned in, or in the log with the listed objectives (all when
--           none listed) finished (or, on a non-bg step, given up and not in the log)
-- abandon:  quest not in the log
-- collect:  bags hold >= count (or forwarded)
-- level:    level > n, or level == n and xp/xpMax >= fraction
-- go/fly/hearth/train/fp/sethearth/vendor/manual (transient): ctx.flags[type] or ctx.forwarded
function Steps:IsActionDone(action, step, ctx)
    local t = action.type
    if t == "accept" then
        local q = action.quest
        local s = questState(ctx, q)
        if s.on or s.turnedIn then return true end
        if not ctx then return false end
        -- accepted, then abandoned by a later step the player already passed
        local later = ctx.forwarded and ctx.abandonedLater
        if later and later[q] then return true end
        -- given up: a later complete/turnin step of the quest was skipped / marked
        -- (or passed as optional), or the quest was abandoned by hand
        return givenUp(ctx, q)
    elseif t == "turnin" then
        local s = questState(ctx, action.quest)
        if s.turnedIn then return true end
        return (not s.on and not (step and step.bg) and givenUp(ctx, action.quest)) and true or false
    elseif t == "complete" then
        local q = action.quest
        local s = questState(ctx, q)
        if s.turnedIn then return true end
        if not s.on then return (not (step and step.bg) and givenUp(ctx, q)) and true or false end
        local wanted = action.objectives
        if wanted and #wanted > 0 then
            local objs = questObjectives(ctx, q)
            if #objs == 0 then return questComplete(ctx, q) end
            for _, idx in ipairs(wanted) do
                local o = objs[idx]
                if o then
                    if not o.finished then return false end
                elseif not questComplete(ctx, q) then
                    return false
                end
            end
            return true
        end
        return questComplete(ctx, q)
    elseif t == "abandon" then
        return not questState(ctx, action.quest).on
    elseif t == "collect" then
        if itemCount(ctx, action.item) >= action.count then return true end
        -- behind the forward limit: the items were most likely consumed by a turn-in
        return (ctx and ctx.forwarded) and true or false
    elseif t == "level" then
        local level, xp, xpMax = playerLevel(ctx)
        if level > action.level then return true end
        if level < action.level then return false end
        local frac = action.frac or 0
        if frac <= 0 then return true end
        return xpMax > 0 and (xp / xpMax) >= frac
    end
    -- transient actions
    local flags = ctx and ctx.flags
    if flags and flags[t] then return true end
    return (ctx and ctx.forwarded) and true or false
end

--- Is the step done? (manual/skip mark, forwarded optional step, or AND of all actions)
function Steps:IsStepDone(step, ctx)
    if ctx and ctx.manual then return true end
    if step.optional and ctx and ctx.forwarded then return true end
    local actions = step.actions or EMPTY
    for i = 1, #actions do
        if not self:IsActionDone(actions[i], step, ctx) then return false end
    end
    return true
end

--- Are all stateful actions of the step done? (true when it has none)
function Steps:IsStatefulDone(step, ctx)
    local Schema = ns.Schema
    for _, a in ipairs(step.actions or EMPTY) do
        if Schema.STATEFUL[a.type] and not self:IsActionDone(a, step, ctx) then
            return false
        end
    end
    return true
end

--- Can the step anchor fast-forwarding? (non-bg, with accept/turnin/complete; a level
-- action alone never anchors, a level next to an accept/turnin/complete must be done too)
function Steps:IsAnchorStep(step)
    if step.bg then return false end
    for _, a in ipairs(step.actions or EMPTY) do
        if self.ANCHOR_ACTIONS[a.type] then return true end
    end
    return false
end

--- Does the step contain an action of the given type?
function Steps:HasAction(step, actionType)
    for _, a in ipairs(step.actions or EMPTY) do
        if a.type == actionType then return a end
    end
    return nil
end

--- Is a (not done) background step still relevant? A bg step that refers to
-- quests (accept/complete/turnin) stays while one of them is in the log or an
-- `accept` quest is still to be taken (neither in the log nor turned in); it is
-- dropped once its quests are turned in, or have left the log and none is left
-- to accept (a given-up quest -- ctx.givenUp -- is not left to accept). With
-- ctx.forwarded (the bg step lies in a segment the player has left, see
-- Core/Engine.lua) a quest not taken yet no longer keeps it.
function Steps:IsBackgroundRelevant(step, ctx)
    local hasQuest = false
    local forwarded = ctx and ctx.forwarded
    for _, a in ipairs(step.actions or EMPTY) do
        local t = a.type
        if t == "accept" or t == "complete" or t == "turnin" then
            hasQuest = true
            local s = questState(ctx, a.quest)
            if s.on then return true end
            if t == "accept" and not s.turnedIn and not forwarded and not givenUp(ctx, a.quest) then
                return true
            end
        end
    end
    return not hasQuest
end

---------------------------------------------------------------------------
-- names
---------------------------------------------------------------------------

local function L() return ns.L end

local function activeRoute()
    return ns.Engine and ns.Engine:GetRoute() or nil
end

--- Localized quest title: client cache -> route data -> "Quest #id".
function Steps:QuestTitle(q)
    local t = ns.Compat.GetQuestTitle(q)
    if t then return t end
    t = ns.Registry:Lookup(activeRoute(), "quests", q)
    if t then return t end
    return L().QUEST_FALLBACK:format(q)
end

--- Localized item name: client cache -> route data -> "Item #id".
function Steps:ItemName(item)
    local t = ns.Compat.ItemName(item)
    if t then return t end
    t = ns.Registry:Lookup(activeRoute(), "items", item)
    if t then return t end
    return L().ITEM_FALLBACK:format(item)
end

--- Localized place name (fp/fly/sethearth/hearth): the client's area name (route data
-- `places[place].area`) -> route data `places` text -> the enUS name.
function Steps:PlaceName(place)
    if type(place) ~= "string" then return L().UNKNOWN_PLACE end
    local route = activeRoute()
    local n = ns.Compat.AreaName(ns.Registry:PlaceArea(route, place))
    if n then return n end
    return ns.Registry:Lookup(route, "places", place) or place
end

---------------------------------------------------------------------------
-- description
---------------------------------------------------------------------------

local function line(lines, icon, text, done, kind, extra)
    local l = {
        icon = icon,
        isAtlas = type(icon) == "string" and not icon:find("\\", 1, true) or false,
        text = text,
        done = done and true or false,
        kind = kind,
    }
    if extra then
        for k, v in pairs(extra) do l[k] = v end
    end
    lines[#lines + 1] = l
    return l
end

local function fmtObjectives(list)
    local parts = {}
    for i, v in ipairs(list) do parts[i] = tostring(v) end
    return concat(parts, ", ")
end

--- Describe a step for the UI.
-- @param step normalized step
-- @param ctx optional (default: ns.Engine:GetContext(step))
-- @return array of { icon = atlas | texture path | fileID | nil, isAtlas = bool, text = string,
--   done = bool, kind = action type | "objective" | "note" | "spells",
--   questID? (quest lines/objectives), itemID? (collect), index? (objective index) }
function Steps:Describe(step, ctx)
    local lines = {}
    if type(step) ~= "table" then return lines end
    ctx = ctx or (ns.Engine and ns.Engine:GetContext(step)) or { cache = {}, items = {} }
    local Lc = L()
    local stepDone = self:IsStepDone(step, ctx)
    local icons = self.ICONS

    for _, a in ipairs(step.actions or EMPTY) do
        local t = a.type
        local done = stepDone or self:IsActionDone(a, step, ctx)
        if t == "accept" then
            line(lines, icons.accept, Lc.STEP_ACCEPT:format(self:QuestTitle(a.quest)), done, t, { questID = a.quest })
        elseif t == "turnin" then
            line(lines, icons.turnin, Lc.STEP_TURNIN:format(self:QuestTitle(a.quest)), done, t, { questID = a.quest })
        elseif t == "complete" then
            local title = self:QuestTitle(a.quest)
            local text
            if a.objectives and #a.objectives > 0 then
                text = Lc.STEP_COMPLETE_OBJECTIVES:format(title, fmtObjectives(a.objectives))
            else
                text = Lc.STEP_COMPLETE:format(title)
            end
            line(lines, icons.complete, text, done, t, { questID = a.quest })
            local s = questState(ctx, a.quest)
            if s.on and not s.turnedIn then
                local objs = questObjectives(ctx, a.quest)
                local wanted
                if a.objectives and #a.objectives > 0 then
                    wanted = {}
                    for _, i in ipairs(a.objectives) do wanted[i] = true end
                end
                for i, o in ipairs(objs) do
                    if not wanted or wanted[i] then
                        local otext = (o.text ~= "" and o.text) or Lc.STEP_OBJECTIVE_PENDING:format(i)
                        line(lines, nil, Lc.STEP_OBJECTIVE:format(otext), o.finished or stepDone, "objective",
                            { questID = a.quest, index = i })
                    end
                end
            end
        elseif t == "abandon" then
            line(lines, icons.abandon, Lc.STEP_ABANDON:format(self:QuestTitle(a.quest)), done, t, { questID = a.quest })
        elseif t == "collect" then
            local have = itemCount(ctx, a.item)
            local icon = ns.Compat.ItemIcon(a.item) or self.ITEM_FALLBACK_ICON
            local l = line(lines, icon,
                Lc.STEP_COLLECT:format(self:ItemName(a.item), min(have, a.count), a.count), done, t, { itemID = a.item })
            l.isAtlas = false
        elseif t == "level" then
            local text
            if a.frac and a.frac > 0 then
                text = Lc.STEP_LEVEL_FRAC:format(a.level, floor(a.frac * 100 + 0.5))
            else
                text = Lc.STEP_LEVEL:format(a.level)
            end
            line(lines, icons.level, text, done, t)
        elseif t == "go" then
            local at = step.at
            local text
            if at then
                local zone = ns.Compat.GetMapName(at.map)
                if zone then
                    text = Lc.STEP_GO:format(zone, at.x, at.y)
                else
                    text = Lc.STEP_GO_NOZONE:format(at.x, at.y)
                end
            else
                text = Lc.STEP_GO_NOZONE:format(0, 0)
            end
            line(lines, icons.go, text, done, t)
        elseif t == "train" then
            line(lines, icons.train, Lc.STEP_TRAIN, done, t)
        elseif t == "fp" then
            line(lines, icons.fp, Lc.STEP_FP:format(self:PlaceName(a.place)), done, t)
        elseif t == "fly" then
            line(lines, icons.fly, Lc.STEP_FLY:format(self:PlaceName(a.place)), done, t)
        elseif t == "sethearth" then
            line(lines, icons.sethearth, Lc.STEP_SETHEARTH:format(self:PlaceName(a.place)), done, t)
        elseif t == "hearth" then
            line(lines, icons.hearth, Lc.STEP_HEARTH:format(self:PlaceName(a.place)), done, t)
        elseif t == "vendor" then
            line(lines, icons.vendor, Lc.STEP_VENDOR, done, t)
        elseif t == "manual" then
            line(lines, icons.manual, Lc.STEP_MANUAL, done, t)
        end
    end

    if step.spells and #step.spells > 0 then
        local names = {}
        for _, s in ipairs(step.spells) do
            local n = ns.Schema.Text(s, ns.locale)
            if n then names[#names + 1] = n end
        end
        if #names > 0 then
            line(lines, nil, Lc.STEP_SPELLS:format(concat(names, ", ")), stepDone, "spells")
        end
    end

    if step.note then
        local note = ns.Schema.Text(step.note, ns.locale)
        if note and note ~= "" then
            line(lines, nil, note, false, "note")
        end
    end
    return lines
end

--- Short label for a step (first action line, else the note).
function Steps:Label(step, ctx)
    local lines = self:Describe(step, ctx)
    for _, l in ipairs(lines) do
        if l.kind ~= "objective" and l.kind ~= "spells" and l.kind ~= "note" then return l.text end
    end
    return lines[1] and lines[1].text or (step and tostring(step.id)) or ""
end
