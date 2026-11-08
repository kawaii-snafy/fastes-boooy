#!/usr/bin/env lua5.1
-- tools/simulate_routes.lua -- play every route through the REAL addon on the WoW mock.
--
--   lua5.1 tools/simulate_routes.lua [--fixtures] [--route ID] [--verbose] [--locale ruRU]
--                                    [--db FILE | --no-db] [--no-reload] [module-dir ...]
--   lua5.1 tools/simulate_routes.lua --harness <library-dir> [--segments ID,...]
--                                    --profile race=,class=[,faction=] [--state FILE] [--write-state FILE]
--
-- Run from the repository root. For every route module (addons/FastesBoooy_*/ with a
-- TOC; plus tests/fixtures/core/FastesBoooy_*/ with --fixtures; or the directories given)
-- and every race x class profile of each route, a fresh strict mock client
-- (tests/mocks/wow.lua) is built with a matching player (Skyborne: raceID 96 Horde /
-- 95 Alliance), the core addon (addons/FastesBoooy), the module's FastesBoooy_*
-- dependencies (## Dependencies, e.g. the shared library FastesBoooy_Horde: loaded first,
-- like the client) and the module are loaded and booted, and the (composed) route is
-- played step by step doing exactly what the current step asks for through the client API
-- of the mock. Library modules (AddLibrarySegment, no route) are not simulated on their
-- own: their segments are played inside the routes that use them.
--
--   accept    quest dialog (QUEST_DETAIL), gossip (by quest id) or greeting (by index);
--             the addon's automation must accept (AcceptQuest is asserted). Every
--             automatic action must wait for the automation delay (default settings
--             autoDelay 0.5 s + random 0..autoDelayJitter 0.3 s): nothing may happen in
--             the dialog event, the mock clock is advanced by the longest delay while an
--             action is scheduled (the summary counts these "delayed actions")
--   turnin    QUEST_PROGRESS / QUEST_COMPLETE / gossip / greeting; the automation must
--             complete and take the reward (the step `reward` choice is asserted); quest XP
--             comes from tools/data/forever_db.lua (unknown XP: median of the quest level)
--   complete  quest objectives are progressed (only the listed ones when given); exploration /
--             escort objectives (DB objectives.event) and quests the route completes but whose
--             objectives the DB does not list stay incomplete until this step (mock event objective)
--   abandon   the quest is removed from the log
--   collect   items are added to the bags
--   level     level / XP are set
--   go        the player is moved to step.at (arrival ticker)
--   fly       taxi map opened, TakeTaxiNode, landing at step.at
--   hearth    hearthstone used (teleport to step.at if the bind point is elsewhere)
--   sethearth innkeeper binder (through the step's gossip option when `gossip` is set)
--   train     trainer window opened / closed (gossip option when `gossip` is set)
--   fp        taxi map opened / closed
--   vendor    merchant window opened / closed
--   manual    the step window's "Next" button is clicked
--
-- Within one step: objectives/items of quests already in the log, abandon, turn-ins and
-- accepts at the NPC, then objectives of the quests accepted by that step and their
-- turn-in. Background (`bg`) steps are done "on the way" as soon as they show up in the
-- engine's background list; a bg step must leave that list only because its actions are
-- done or its quests were turned in / left the log (never just because the cursor passed
-- it), and a bg step never listed is reported. After every action the step must be done
-- and the cursor must move
-- forward (never backwards, never stuck, bounded number of iterations); errors reported
-- by the client error handler, strict-mock violations and unmocked API accesses fail
-- the route. At the end the route must be finished; a /reload with the exported
-- SavedVariables must keep it finished and a cold start with EMPTY SavedVariables must
-- not put the cursor before the last done stateful step.
--
-- Start state / harness (tools/lib/harness.lua): --state FILE starts the character from a state
-- (level / XP, quests turned in, quest log with done objectives, hearthstone bind point, position,
-- flight paths) instead of a fresh character; --harness DIR plays a synthetic route of one
-- --profile that only uses the --segments of the library module DIR (FastesBoooy.RegisterRoute +
-- FastesBoooy.UseSegments through the addon's public API, like a route module would);
-- --write-state FILE writes the game state at the end (exactly one simulation). The mock gives
-- quest XP only (no kill XP): levels of a simulator end state lag behind the validator's.
--
-- Player ahead of the route (level sync, Core/Engine.lua): --ahead L starts a FRESH character at
-- level L at the route start (default settings: levelSync "ask", skipGray on). When the engine
-- suggests a level sync (GetSyncSuggestion) -- at the start or later -- the simulator "clicks"
-- the banner's jump button (Engine:ApplySync) and plays on to the end. With --ahead-at SEG[,SEG...]
-- the character instead plays the route normally up to the middle of the first of those segments
-- the route has (quests of that part in the log), is then raised to level L and the suggestions
-- are applied from there (a jump with a quest log). --level-plus N plays the whole route with the
-- player N levels above the plan (linear within each segment's `levels`) in levelSync "auto":
-- the engine jumps by itself when it finds a jump worth it.
-- In these "sync" runs the simulator also
--   * refuses an accept whose route-quest prerequisites (DB preQuestGroup: all, preQuestSingle: one;
--     quests the route does not accept count as met) are not turned in: "unreachable accept" (the
--     engine should have skipped it);
--   * refuses a `collect` whose items only quests need that the player does not have and can no
--     longer take (questMeta items; the engine should have made it void);
--   * abandons, after every jump, the quests the engine names as dropped (Engine:GetDroppedQuests:
--     what the chat line asks the player to do);
--   * after a jump: a `fly` to a flight path whose `fp` step the jump skipped must show the engine's
--     hint (Engine:FlightPathPending) -- the player then travels there instead of flying; a `hearth`
--     with the hearthstone bound elsewhere must show the bind hint (Steps:Describe) -- the player
--     travels there instead; without the hint the run fails (counted in the summary);
--   * fails when the route ends with a COMPLETE quest still in the log (a turn-in the jump lost).
-- Without these options nothing of this happens (normal runs are unchanged).
--
-- Exit status: 0 = every simulation passed (or nothing to simulate), 1 = a failure,
-- 2 = usage error.

package.path = "./tests/?.lua;./tools/?.lua;" .. package.path

local Mock = require("mocks.wow")
local Loader = require("lib.route_loader")
local FBDB = require("lib.fbdb")
local Harness = require("lib.harness")

local format = string.format
local floor, ceil, max = math.floor, math.ceil, math.max

local CORE_TOC = "addons/FastesBoooy/FastesBoooy.toc"
local DB_FILE = "tools/data/forever_db.lua"
local FLIGHT_TIME = 30
local SETTLE = 0.5           -- seconds of mock time after every action (throttle 0.1 s, ticker 0.25 s)
local MAX_BG_TRIES = 3

local RACE_FACTION = {
    Human = "Alliance", Dwarf = "Alliance", NightElf = "Alliance", Gnome = "Alliance",
    Orc = "Horde", Scourge = "Horde", Tauren = "Horde", Troll = "Horde",
}
local DEFAULT_RACE = { Horde = "Scourge", Alliance = "Human" }

---------------------------------------------------------------------------
-- command line
---------------------------------------------------------------------------

local USAGE = [[
usage: lua5.1 tools/simulate_routes.lua [options] [module-dir ...]
  --fixtures       also simulate tests/fixtures/core/FastesBoooy_*/ modules
  --route ID       only this route id
  --verbose, -v    print every step and action
  --locale CODE    client locale (default enUS)
  --db FILE        Forever DB snapshot (default tools/data/forever_db.lua)
  --no-db          do not use the DB snapshot (generic quests)
  --no-reload      skip the /reload and cold-start checks
  --state FILE     start from a character state (JSON, see tools/README.md "Harness")
  --write-state FILE  write the game state at the end (needs exactly one simulation)
  --ahead L        player ahead of the route: a fresh character at level L at the route start;
                   level-sync suggestions are applied, unreachable accepts fail the run
  --ahead-at SEG[,SEG...]  with --ahead L: play normally to the middle of the first of these
                   segments the route has, then level L and the suggestions (a jump with quests in the log)
  --level-plus N   play the route N (1..10) levels above its plan, levelSync "auto"
  --harness DIR    simulate a synthetic route that only uses library segments of the
                   library module DIR, for one --profile (race and class required)
  --segments ID,...   library segments of the harness route (default: all, TOC order)
  --profile k=v,...   race=Scourge,class=PALADIN[,faction=Horde] (harness, or a filter
                   of the route profiles otherwise)
  -h, --help       this text]]

local function parseArgs(argv)
    local o = { dirs = {}, locale = "enUS", db = DB_FILE, reload = true }
    local i = 1
    while i <= #argv do
        local a = argv[i]
        if a == "--fixtures" then o.fixtures = true
        elseif a == "--route" then i = i + 1; o.route = argv[i]
        elseif a == "--verbose" or a == "-v" then o.verbose = true
        elseif a == "--locale" then i = i + 1; o.locale = argv[i]
        elseif a == "--db" then i = i + 1; o.db = argv[i]
        elseif a == "--no-db" then o.db = false
        elseif a == "--no-reload" then o.reload = false
        elseif a == "--ahead" then
            i = i + 1
            local v = tonumber(argv[i])
            if not v or v < 1 or v > 60 or v % 1 ~= 0 then return nil, "--ahead needs a level 1..60" end
            o.ahead = v
        elseif a == "--ahead-at" then
            i = i + 1
            local v = argv[i]
            if v == nil or v == "" then return nil, "--ahead-at needs segment ids" end
            o.aheadAt = {}
            for id in v:gmatch("[^,%s]+") do o.aheadAt[#o.aheadAt + 1] = id end
        elseif a == "--level-plus" then
            i = i + 1
            local v = tonumber(argv[i])
            if not v or v < 1 or v > 10 or v % 1 ~= 0 then return nil, "--level-plus needs a number 1..10" end
            o.levelPlus = v
        elseif a == "--state" or a == "--write-state" or a == "--harness" or a == "--segments"
            or a == "--profile" then
            i = i + 1
            local v = argv[i]
            if v == nil then return nil, a .. " needs a value" end
            -- an empty --state / --write-state / --segments value = not given (make harness passes them all)
            if a == "--state" then o.state = Harness.NonEmpty(v)
            elseif a == "--write-state" then o.writeState = Harness.NonEmpty(v)
            elseif a == "--harness" then o.harness = v
            elseif a == "--segments" then
                o.segments = Harness.ParseList(v)
                if #o.segments == 0 then o.segments = nil end
            else
                local ok, p = pcall(Harness.ParseProfile, v)
                if not ok then return nil, p end
                o.profile = p
            end
        elseif a == "-h" or a == "--help" then o.help = true
        elseif a:sub(1, 1) == "-" then return nil, "unknown option " .. a
        else o.dirs[#o.dirs + 1] = a end
        i = i + 1
    end
    if o.route == nil and argv[#argv] == "--route" then return nil, "--route needs an id" end
    if not o.locale then return nil, "--locale needs a code" end
    if o.aheadAt and not o.ahead then return nil, "--ahead-at needs --ahead L" end
    if o.levelPlus and o.ahead then return nil, "--level-plus and --ahead are exclusive" end
    o.sync = (o.ahead or o.levelPlus) and true or nil -- a "sync" run (see the header)
    return o
end

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------

local function sortedKeys(t)
    local out = {}
    for k in pairs(t or {}) do out[#out + 1] = k end
    table.sort(out, function(a, b) return tostring(a) < tostring(b) end)
    return out
end

local function actionTypes(step)
    local t = {}
    for _, a in ipairs(step.actions or {}) do
        t[#t + 1] = a.quest and (a.type .. " " .. a.quest) or a.place and (a.type .. " " .. a.place)
            or a.item and (a.type .. " " .. a.item) or a.level and (a.type .. " " .. a.level) or a.type
    end
    return table.concat(t, ", ")
end

local function stepName(step)
    if not step then return "<end>" end
    return format("%s [%s]", tostring(step.id), actionTypes(step))
end

local FAIL = {}

-- abort the current simulation (S: the simulation, kept for symmetry with warn / vlog)
local function fail(_, fmt, ...)
    error(setmetatable({ msg = format(fmt, ...) }, FAIL), 0)
end

local function warn(S, fmt, ...)
    local msg = format(fmt, ...)
    S.warnings[#S.warnings + 1] = msg
    if S.opts.verbose then print("    warning: " .. msg) end
end

local checkBgLeft -- defined below (needs engine())
local checkReachable -- defined below (sync runs)
local checkCollect -- defined below (sync runs)

local function vlog(S, fmt, ...)
    if S.opts.verbose then print(format(fmt, ...)) end
end

local function firstNpc(step)
    return step.npc and step.npc[1] or nil
end

local function textEn(t)
    if type(t) == "table" then return t.en or t.enUS or t.ru end
    return t
end

---------------------------------------------------------------------------
-- engine state
---------------------------------------------------------------------------

local function engine(S) return S.ns.Engine end

local function actionDone(S, step, a)
    local E = engine(S)
    return S.ns.Steps:IsActionDone(a, step, E:GetContext(step))
end

local function settle(S, seconds)
    S.m:Advance(seconds or SETTLE)
end

local function newActions(S, mark)
    local out = {}
    for i = mark + 1, #S.m.actions do out[#out + 1] = S.m.actions[i] end
    return out
end

local function findAction(list, name, arg1)
    for _, a in ipairs(list) do
        if a[1] == name and (arg1 == nil or a[2] == arg1) then return a end
    end
    return nil
end

-- client calls of the quest automation (Core/Automation.lua)
local AUTO_CALLS = {
    AcceptQuest = true, AcknowledgeAutoAcceptQuest = true, CompleteQuest = true, GetQuestReward = true,
    SelectActiveQuest = true, SelectAvailableQuest = true,
    ["C_GossipInfo.SelectActiveQuest"] = true, ["C_GossipInfo.SelectAvailableQuest"] = true,
    ["C_GossipInfo.SelectOptionByIndex"] = true, ["C_GossipInfo.SelectOption"] = true,
}

-- After a dialog window opened: the automation acts after its delay (settings autoDelay +
-- random 0..autoDelayJitter; a simulated character has the defaults), never in the dialog
-- event itself. Advance the mock clock by the longest delay while an action is scheduled
-- (one dialog may chain several: gossip -> quest window -> reward -> the gossip again).
local function awaitAutomation(S, step, mark)
    local m, A = S.m, S.ns.Automation
    local s = S.ns.db.settings
    local delay = tonumber(s.autoDelay) or 0
    if delay <= 0 then return end -- autoDelay 0: the automation acted at once
    for _, a in ipairs(newActions(S, mark)) do
        if AUTO_CALLS[a[1]] then
            fail(S, "step %s: the automation called %s without waiting for its delay", stepName(step), a[1])
        end
    end
    local wait = delay + (tonumber(s.autoDelayJitter) or 0) + 0.05
    local n = 0
    while A:GetPending() do
        n = n + 1
        if n > 20 then fail(S, "step %s: the automation keeps scheduling actions", stepName(step)) end
        m:Advance(wait)
    end
    S.stats.delayed = S.stats.delayed + n
end

---------------------------------------------------------------------------
-- quests
---------------------------------------------------------------------------

-- Why would the server not offer quest q now? (nil = it would)
local function whyNotOffered(S, q)
    local m = S.m
    if m:CanTakeQuest(q) then return nil end
    local def = m:_quest(q)
    local why = {}
    if (def.reqLevel or 1) > m.player.level then
        why[#why + 1] = format("requires level %d (player is %d)", def.reqLevel, m.player.level)
    end
    local missing = {}
    for _, pre in ipairs(def.pre or {}) do
        if not m.completed[pre] then missing[#missing + 1] = tostring(pre) end
    end
    if #missing > 0 then why[#why + 1] = "prerequisites not done: " .. table.concat(missing, ", ") end
    if def.preAny and #def.preAny > 0 then
        local any = false
        for _, pre in ipairs(def.preAny) do if m.completed[pre] then any = true end end
        if not any then
            local l = {}
            for _, pre in ipairs(def.preAny) do l[#l + 1] = tostring(pre) end
            why[#why + 1] = "none of the prerequisites done: " .. table.concat(l, ", ")
        end
    end
    for _, ex in ipairs(def.exclusive or {}) do
        if m.completed[ex] or m:IsOnQuest(ex) then why[#why + 1] = "exclusive with " .. ex end
    end
    if #why == 0 then why[1] = "race / class mask" end
    return table.concat(why, "; ")
end

local routeQuestSets -- defined below (needs engine())

-- --ahead: an accept whose ROUTE-quest prerequisites (DB preQuestGroup = all, preQuestSingle = one of;
-- a prerequisite the route never accepts counts as met, like the engine's rule) are not turned in
-- cannot be taken in game: the engine should have skipped it (unreachable accept)
checkReachable = function(S, step, q)
    local m = S.m
    local def = m:_quest(q)
    local routeAccepts = routeQuestSets(S).accept
    local missing = {}
    for _, p in ipairs(def.pre or {}) do
        if p ~= q and routeAccepts[p] and not m.completed[p] then missing[#missing + 1] = tostring(p) end
    end
    if def.preAny and #def.preAny > 0 then
        local met = false
        local l = {}
        for _, p in ipairs(def.preAny) do
            if p == q or not routeAccepts[p] or m.completed[p] then met = true end
            l[#l + 1] = tostring(p)
        end
        if not met then missing[#missing + 1] = "one of " .. table.concat(l, "/") end
    end
    if #missing > 0 then
        fail(S, "unreachable accept: step %s accepts %d but its route prerequisite(s) %s are not turned in "
            .. "(the engine should have skipped it)", stepName(step), q, table.concat(missing, ", "))
    end
end

-- sync runs: a `collect` whose items (questMeta items: the route quests with the item as an
-- objective) only quests need that are not in the log, not turned in and that the route no longer
-- accepts (every accept of them before the natural cursor) -- items for quests the player does not
-- have (the engine should have made the action void)
checkCollect = function(S, step, a)
    local E = engine(S)
    local quests = E.itemQuests and E.itemQuests[a.item]
    if not quests or #quests == 0 then return end
    local m, nat = S.m, E:GetNaturalCursor() or (#E:GetSteps() + 1)
    for _, q in ipairs(quests) do
        if m:IsOnQuest(q) or m.completed[q] then return end
        for _, i in ipairs(E.acceptAt[q] or {}) do
            if i >= nat then return end
        end
    end
    local l = {}
    for _, q in ipairs(quests) do l[#l + 1] = tostring(q) end
    fail(S, "step %s: collect %d x%d for quest(s) %s the player does not have and can no longer take", stepName(step),
        a.item, a.count, table.concat(l, ", "))
end

local function prepareTurnin(S, step, q)
    local m = S.m
    if m:IsQuestCompleted(q) then return end
    if not m:IsOnQuest(q) then
        fail(S, "step %s: turnin %d but the quest is not in the quest log (no accept before?)", stepName(step), q)
    end
    local e = m:_logEntry(q)
    if not m:_isComplete(e) then
        fail(S, "step %s: turnin %d but its objectives are not complete (no complete step before?)",
            stepName(step), q)
    end
    local def = m:_quest(q)
    if (def.xp or 0) <= 0 and S.db then
        def.xp = FBDB.EstimateQuestXp(S.db, def.level)
        S.stats.estimatedXP = S.stats.estimatedXP + 1
    end
    local idx = step.reward and step.reward[q]
    if idx then
        def.choices = def.choices or {}
        for i = #def.choices + 1, max(idx, 2) do
            local itemID = 900000 + q * 10 + i
            if not m.items[itemID] then m:DefineItem(itemID, { name = format("Reward %d of quest %d", i, q) }) end
            def.choices[i] = itemID
        end
    end
end

local function hasItemObjectives(S, q)
    local def = S.m:_quest(q)
    for _, o in ipairs(def.objectives or {}) do
        if o.itemID then return true end
    end
    return (def.moneyRequired or 0) > 0
end

-- Is the `accept` of quest q in this step done for the engine although the quest is
-- neither in the log nor turned in (forwarded: abandoned by a later step that is passed)?
local function forwardedAccept(S, step, q)
    local m = S.m
    if m:IsOnQuest(q) or m:IsQuestCompleted(q) then return false end
    for _, a in ipairs(step.actions or {}) do
        if a.type == "accept" and a.quest == q then return actionDone(S, step, a) and true or false end
    end
    return false
end

local function checkQuestResults(S, step, turnins, accepts, mark)
    local m = S.m
    local acts = newActions(S, mark)
    for _, q in ipairs(turnins) do
        local r = findAction(acts, "GetQuestReward", q)
        if not r or not m:IsQuestCompleted(q) then
            fail(S, "step %s: the automation did not turn in quest %d (chat: %s)", stepName(step), q,
                tostring(m.chat[#m.chat]))
        end
        local want = step.reward and step.reward[q]
        if want and r[3] ~= want then
            fail(S, "step %s: quest %d turned in with reward choice %s, step wants %d", stepName(step), q,
                tostring(r[3]), want)
        end
        S.stats.turnedIn = S.stats.turnedIn + 1
    end
    for _, q in ipairs(accepts) do
        local ok = findAction(acts, "AcceptQuest", q) or findAction(acts, "AcknowledgeAutoAcceptQuest", q)
        if ok and (m:IsOnQuest(q) or m:IsQuestCompleted(q)) then
            S.stats.accepted = S.stats.accepted + 1
        elseif forwardedAccept(S, step, q) then
            -- the automation re-checks the route window when its delay ends: the engine
            -- forwarded this accept meanwhile (a later step is done and the route abandons
            -- the quest later), so dropping it is right
            warn(S, "step %s: quest %d not accepted: the engine forwarded its accept during the dialog",
                stepName(step), q)
        else
            fail(S, "step %s: the automation did not accept quest %d (chat: %s)", stepName(step), q,
                tostring(m.chat[#m.chat]))
        end
    end
end

-- turn-ins and accepts of one step through the quest dialogs
local function doQuests(S, step, turnins, accepts)
    local m = S.m
    local n = #turnins + #accepts
    if n == 0 then return end
    for _, q in ipairs(turnins) do prepareTurnin(S, step, q) end
    -- offers are checked as if the turn-ins of this step were already done
    local saved = {}
    for _, q in ipairs(turnins) do saved[q] = m.completed[q]; m.completed[q] = true end
    local entries = m.questLog
    m.questLog = {}
    for _, e in ipairs(entries) do
        if not saved[e.questID] and m.completed[e.questID] == nil then m.questLog[#m.questLog + 1] = e end
    end
    for _, q in ipairs(accepts) do
        if S.opts.sync then checkReachable(S, step, q) end
        local why = whyNotOffered(S, q)
        if why then warn(S, "step %s: quest %d would not be offered yet: %s", stepName(step), q, why) end
    end
    m.questLog = entries
    for _, q in ipairs(turnins) do m.completed[q] = saved[q] end
    local npc = firstNpc(step)
    local mark = #m.actions
    if n == 1 and #accepts == 1 then
        vlog(S, "    QUEST_DETAIL %d", accepts[1])
        m:OpenQuestDetail(accepts[1], { npcID = npc })
    elseif n == 1 then
        local q = turnins[1]
        if hasItemObjectives(S, q) then
            vlog(S, "    QUEST_PROGRESS %d", q)
            m:OpenQuestProgress(q, { npcID = npc })
        else
            vlog(S, "    QUEST_COMPLETE %d", q)
            m:OpenQuestComplete(q, nil, { npcID = npc })
        end
    elseif step.npc and #step.npc > 1 then
        vlog(S, "    QUEST_GREETING active={%s} available={%s}", table.concat(turnins, ","), table.concat(accepts, ","))
        m:OpenGreeting({ active = turnins, available = accepts }, npc)
    else
        vlog(S, "    GOSSIP_SHOW active={%s} available={%s}", table.concat(turnins, ","), table.concat(accepts, ","))
        m:OpenGossip({ active = turnins, available = accepts }, npc)
    end
    awaitAutomation(S, step, mark)
    m:CloseInteraction()
    checkQuestResults(S, step, turnins, accepts, mark)
end

local function doComplete(S, step, a)
    local m, q = S.m, a.quest
    if m:IsQuestCompleted(q) then return end
    if not m:IsOnQuest(q) then
        fail(S, "step %s: complete %d but the quest is not in the quest log", stepName(step), q)
    end
    local e = m:_logEntry(q)
    if a.objectives and #a.objectives > 0 then
        for _, idx in ipairs(a.objectives) do
            local o = e.objectives[idx]
            if not o then
                if #e.objectives > 0 then
                    fail(S, "step %s: quest %d has no objective #%d", stepName(step), q, idx)
                end
            elseif o.itemID then
                local need = o.required - m:GetItemCount(o.itemID)
                if need > 0 then m:AddItem(o.itemID, need) end
            elseif o.fulfilled < o.required then
                m:ProgressObjective(q, idx, o.required - o.fulfilled)
            end
        end
    else
        m:CompleteObjectives(q)
    end
    vlog(S, "    objectives of %d done", q)
end

---------------------------------------------------------------------------
-- services (trainer / taxi / binder / vendor), optionally through gossip
---------------------------------------------------------------------------

local SERVICE_ACTIONS = { sethearth = true, train = true, fp = true, vendor = true }

local function trainerSpec(step)
    local services = {}
    for i, s in ipairs(step.spells or {}) do
        services[i] = { name = textEn(s) or ("Spell " .. i), category = "available", cost = 0 }
    end
    return { services = services }
end

local function binderOf(step, place)
    local at = step.at
    return { name = place, mapID = at and at.map, x = at and at.x, y = at and at.y }
end

local function finishService(S, kind)
    local m = S.m
    if kind == "sethearth" then
        if not m:ConfirmBinder() then fail(S, "binder confirmation failed") end
    elseif kind == "train" then m:CloseTrainer()
    elseif kind == "fp" then m:CloseTaxi()
    elseif kind == "vendor" then m:CloseMerchant()
    end
end

local function openService(S, step, a)
    local m, npc = S.m, firstNpc(step)
    local t = a.type
    if t == "sethearth" then
        local b = binderOf(step, a.place)
        m:OpenBinder(b.name, npc, b.mapID, b.x, b.y)
    elseif t == "train" then
        m:OpenTrainer(trainerSpec(step), npc)
    elseif t == "fp" then
        local at = step.at
        m:OpenTaxi({ { name = a.place, state = "CURRENT", mapID = at and at.map, destX = at and at.x,
            destY = at and at.y } }, npc)
    elseif t == "vendor" then
        m:OpenMerchant({ items = {} }, npc)
    end
end

-- the service behind gossip option #step.gossip, chosen by the automation
local function serviceViaGossip(S, step, a)
    local m, npc = S.m, firstNpc(step)
    local idx = step.gossip
    local wrong = {}
    local options = {}
    for i = 1, idx do
        options[i] = { name = "Option " .. i, onSelect = function() wrong[#wrong + 1] = i end }
    end
    local t = a and a.type
    if t == "sethearth" then
        options[idx] = { name = "Make this inn your home.", type = "binder", bind = binderOf(step, a.place) }
    elseif t == "train" then
        options[idx] = { name = "Train me.", type = "trainer", trainer = trainerSpec(step) }
    elseif t == "fp" then
        local at = step.at
        options[idx] = { name = "Show me where I can fly.", type = "taxi", nodes = {
            { name = a.place, state = "CURRENT", mapID = at and at.map, destX = at and at.x, destY = at and at.y } } }
    elseif t == "vendor" then
        options[idx] = { name = "Let me browse your goods.", type = "vendor", merchant = { items = {} } }
    else
        options[idx] = { name = "Continue.", type = "close" }
    end
    local mark = #m.actions
    vlog(S, "    GOSSIP_SHOW with %d option(s), npc %s", idx, tostring(npc))
    m:OpenGossip({ options = options }, npc)
    awaitAutomation(S, step, mark)
    local acts = newActions(S, mark)
    local picked = findAction(acts, "C_GossipInfo.SelectOptionByIndex", idx - 1)
        or findAction(acts, "C_GossipInfo.SelectOption", 1000 + idx)
    if #wrong > 0 or not picked then
        fail(S, "step %s: the automation did not select gossip option %d (wrong: %s)", stepName(step), idx,
            table.concat(wrong, ","))
    end
    S.stats.gossip = S.stats.gossip + 1
    if t then finishService(S, t) end
    m:CloseInteraction()
end

-- quests the (filtered) route accepts / turns in: { accept = {[q] = true}, turnin = {[q] = true} }
routeQuestSets = function(S)
    if not S.routeQuests then
        local sets = { accept = {}, turnin = {} }
        for _, s in ipairs(engine(S):GetSteps()) do
            for _, a in ipairs(s.actions) do
                if sets[a.type] then sets[a.type][a.quest] = true end
            end
        end
        S.routeQuests = sets
    end
    return S.routeQuests
end

-- Talking to an NPC opens its gossip first. When the service NPC also offers a route quest (or takes
-- a complete route quest), the automation accepts the quests of the lookahead window / turns in there
-- BEFORE the trainer / merchant / taxi / binder window opens. A later step finished that way becomes
-- the forward anchor and fast-forwards this visit (validator: lookahead-skip): reported as a warning.
-- @return true when the visit was fast-forwarded (the service is then not opened for this step)
local function gossipFirst(S, step, a)
    local m, npc = S.m, firstNpc(step)
    if not npc or step.gossip then return false end
    local spec = m:_npcSpec(npc)
    if not spec then return false end
    local sets = routeQuestSets(S)
    local relevant = false
    for _, q in ipairs(spec.available or {}) do
        if sets.accept[q] then relevant = true end
    end
    for _, q in ipairs(spec.active or {}) do
        local e = m:_logEntry(q)
        if e and sets.turnin[q] and m:_isComplete(e) then relevant = true end
    end
    if not relevant then return false end
    local E = engine(S)
    vlog(S, "    TALK %d (gossip before the %s window)", npc, a.type)
    local mark = #m.actions
    m:TalkTo(npc)
    awaitAutomation(S, step, mark)
    m:CloseInteraction()
    settle(S)
    for _, act in ipairs(newActions(S, mark)) do
        if act[1] == "AcceptQuest" then S.stats.accepted = S.stats.accepted + 1 end
    end
    if E:IsDone(step) then
        if step.optional then
            -- an optional visit may be fast-forwarded (the validator does not report it either)
            vlog(S, "    optional step fast-forwarded by the gossip of NPC %d", npc)
        else
            warn(S, "step %s: fast-forwarded before its %s window opened: talking to NPC %d let the automation "
                .. "accept / turn in a later step's quest first (validator lookahead-skip; merge the steps)",
                stepName(step), a.type, npc)
        end
        return true
    end
    return false
end

local function doService(S, step, a)
    if a.type == "fp" then S.flightPaths[a.place] = true end
    if step.gossip and not S.gossipUsed[step.id] then
        if firstNpc(step) then
            S.gossipUsed[step.id] = true
            return serviceViaGossip(S, step, a)
        end
        warn(S, "step %s: `gossip` without `npc` is never selected by the automation", stepName(step))
    end
    if gossipFirst(S, step, a) then return end
    openService(S, step, a)
    finishService(S, a.type)
    S.m:CloseInteraction()
end

---------------------------------------------------------------------------
-- movement
---------------------------------------------------------------------------

local function moveTo(S, at)
    S.m:MoveTo(at.map, at.x, at.y)
end

-- After a level sync (sync runs): the route's `fp` step of `place` below the sync floor that this
-- run never performed -- the flight path is not known.
local function skippedFlightPath(S, place)
    local E = engine(S)
    local floorIndex = E.floor or 0
    if #S.syncs == 0 or floorIndex <= 1 or S.flightPaths[place] then return false end
    local steps = E:GetSteps()
    for i = 1, floorIndex - 1 do
        for _, a in ipairs(steps[i].actions) do
            if a.type == "fp" and a.place == place then return true end
        end
    end
    return false
end

-- the hint lines Steps:Describe adds to a step (Engine:FlightPathPending / HearthBindMismatch)
local function hasHint(S, step)
    for _, l in ipairs(S.ns.Steps:Describe(step)) do
        if l.hint then return true end
    end
    return false
end

local function doFly(S, step, a)
    local m, at = S.m, step.at
    if skippedFlightPath(S, a.place) then
        -- the jump skipped the flight path: the step must say so; the player travels there
        if not (engine(S):FlightPathPending(a.place) and hasHint(S, step)) then
            fail(S, "step %s: fly to %s, but its flight path was skipped by the level sync and the step does not "
                .. "say so", stepName(step), tostring(a.place))
        end
        S.stats.travelled = S.stats.travelled + 1
        vlog(S, "    flight path %s skipped by the level sync: travelling there", tostring(a.place))
        moveTo(S, at)
        return
    end
    m:OpenTaxi({
        { name = "Here", state = "CURRENT" },
        { name = a.place, state = "REACHABLE", mapID = at.map, destX = at.x, destY = at.y, flightTime = FLIGHT_TIME },
    }, firstNpc(step))
    m:_top(function() m.env.TakeTaxiNode(2) end)
    if not m.player.onTaxi then fail(S, "step %s: TakeTaxiNode did not start the flight", stepName(step)) end
    settle(S, 1)
    if actionDone(S, step, a) then fail(S, "step %s: fly counted as done while still on the taxi", stepName(step)) end
    settle(S, FLIGHT_TIME)
    if m.player.onTaxi then m:Land(at.map, at.x, at.y) end
end

local function doHearth(S, step)
    local m, at = S.m, step.at
    local hinted = #S.syncs > 0 and hasHint(S, step) -- before the hearthstone moves the player
    m:UseHearthstone()
    local d = m:Distance(m.player.mapID, m.player.x, m.player.y, at.map, at.x, at.y)
    local a = S.ns.Steps:HasAction(step, "hearth")
    local bindName = m.bind and m.bind.name
    local otherPlace = bindName ~= nil and a ~= nil and not engine(S):PlaceMatches(a.place, bindName)
    if not d or d > (step.radius or 80) then
        if #S.syncs > 0 and otherPlace then
            -- after a level sync the bind of the skipped part may be missing: the step must say so
            if not hinted then
                fail(S, "step %s: the hearthstone is bound to %s, not the step's place, after the level sync and "
                    .. "the step does not say so", stepName(step), tostring(m.bind and m.bind.name))
            end
            S.stats.travelled = S.stats.travelled + 1
            vlog(S, "    hearthstone bound to %s: travelling there", tostring(m.bind and m.bind.name))
        else
            warn(S, "step %s: the hearthstone bind point (%s) is not at the step location; teleporting",
                stepName(step), tostring(m.bind and m.bind.name))
        end
        moveTo(S, at)
    end
end

local function doLevel(S, a)
    local m = S.m
    local p = m.player
    local want = ceil((a.frac or 0) * m:XPMax(a.level))
    if p.level < a.level then
        m:SetLevel(a.level, want)
    elseif p.level == a.level and p.xp < want then
        m:GiveXP(want - p.xp)
    end
end

local function clickNext(S)
    local UI = S.ns.UI
    local f = UI and UI.StepFrame and UI.StepFrame:GetFrame()
    if f and f.nextButton and f.nextButton:IsEnabled() then
        S.m:Click(f.nextButton)
    else
        warn(S, "step frame Next button unavailable: calling Engine:Next()")
        engine(S):Next()
    end
end

---------------------------------------------------------------------------
-- one step
---------------------------------------------------------------------------

local function performStep(S, step)
    local m = S.m
    local hasTravel = false
    for _, a in ipairs(step.actions) do
        if a.type == "fly" or a.type == "hearth" then hasTravel = true end
    end
    -- walk to the step location first (fly / hearth steps travel by themselves)
    if step.at and not hasTravel then moveTo(S, step.at) end

    local pending = {}
    for _, a in ipairs(step.actions) do
        if not actionDone(S, step, a) then pending[#pending + 1] = a end
    end
    local function each(types, fn)
        for _, a in ipairs(pending) do
            if types[a.type] then fn(a) end
        end
    end

    -- Order: objectives / items of quests already in the log, abandon, turn-ins +
    -- accepts at the NPC; then the objectives of quests accepted by this very step
    -- and finally their turn-in ({accept=Q, complete=Q}, {accept=Q, turnin=Q},
    -- {turnin=A, accept=B, complete=B} are all legal steps).
    local acceptedHere = {}
    each({ accept = true }, function(a) acceptedHere[a.quest] = true end)
    each({ complete = true }, function(a)
        if not acceptedHere[a.quest] then doComplete(S, step, a) end
    end)
    each({ collect = true }, function(a)
        if S.opts.sync then checkCollect(S, step, a) end
        local need = a.count - m:GetItemCount(a.item)
        if need > 0 then m:AddItem(a.item, need) end
        vlog(S, "    +%d item %d", need, a.item)
    end)
    each({ abandon = true }, function(a)
        if m:IsOnQuest(a.quest) then m:AbandonQuest(a.quest) end
        vlog(S, "    abandoned %d", a.quest)
    end)
    local turnins, accepts, lateTurnins = {}, {}, {}
    each({ turnin = true }, function(a)
        if acceptedHere[a.quest] then lateTurnins[#lateTurnins + 1] = a.quest
        else turnins[#turnins + 1] = a.quest end
    end)
    each({ accept = true }, function(a) accepts[#accepts + 1] = a.quest end)
    doQuests(S, step, turnins, accepts)
    each({ complete = true }, function(a)
        if acceptedHere[a.quest] then doComplete(S, step, a) end
    end)
    doQuests(S, step, lateTurnins, {})
    each({ level = true }, function(a) doLevel(S, a) end)
    each({ fly = true }, function(a) doFly(S, step, a) end)
    each({ hearth = true }, function() doHearth(S, step) end)
    local serviced = false
    each(SERVICE_ACTIONS, function(a)
        serviced = true
        doService(S, step, a)
    end)
    -- a gossip option on a step without service action (e.g. "start the escort")
    if step.gossip and not serviced and firstNpc(step) and not S.gossipUsed[step.id] then
        S.gossipUsed[step.id] = true
        serviceViaGossip(S, step, nil)
    end
    settle(S)
    each({ manual = true }, function() clickNext(S) end)
    settle(S)
end

---------------------------------------------------------------------------
-- one route x profile
---------------------------------------------------------------------------

local function profiles(route)
    local races = sortedKeys(route.races)
    local classes = sortedKeys(route.classes)
    local out = {}
    if #races == 0 then races = { DEFAULT_RACE[route.faction or "Horde"] } end
    if #classes == 0 then classes = { "WARRIOR" } end
    for _, race in ipairs(races) do
        for _, cls in ipairs(classes) do
            out[#out + 1] = { race = race, class = cls, faction = route.faction or RACE_FACTION[race] or "Horde" }
        end
    end
    return out
end

local function startPosition(route)
    for _, s in ipairs(route.steps) do
        if s.at then
            for _, a in ipairs(s.actions) do
                if a.type == "go" or a.type == "fly" or a.type == "hearth" then
                    return s.at.map, 50, 50
                end
            end
            return s.at.map, s.at.x, s.at.y
        end
    end
    return 1420, 50, 50
end

-- quests the route completes with a `complete` step: the mock keeps such a quest incomplete on
-- accept even when the DB lists no objective for it (event objectives always stay incomplete)
local function routeCompletes(route)
    local out = {}
    for _, s in ipairs(route.steps or {}) do
        for _, a in ipairs(s.actions or {}) do
            if a.type == "complete" and a.quest then out[a.quest] = true end
        end
    end
    return out
end

-- the start state (--state) in a fresh mock, before the addons are loaded (no events)
local function applyState(m, st)
    local p = m.player
    p.xp = Harness.XpFromFraction(st.xpFrac, m:XPMax(p.level))
    for _, id in ipairs(st.done or {}) do m.completed[id] = true end
    for _, id in ipairs(st.log or {}) do m:_addToLog(id) end
    for _, id in ipairs(st.complete or {}) do
        local e = m:_logEntry(id)
        for _, o in ipairs(e and e.objectives or {}) do
            if o.itemID then
                local need = o.required - m:GetItemCount(o.itemID)
                if need > 0 then m:AddItem(o.itemID, need) end
            end
            o.fulfilled = o.required
        end
        if e and e.complete == false then e.complete = nil end
    end
    if st.hearth then
        local at = st.hearthAt
        m.bind = { name = st.hearth, mapID = at and at[1], x = at and at[2], y = at and at[3] }
    end
end

-- World sizes for the zones of the DB snapshot that the mock does not know (its built-in maps are the
-- 1-22 zones): without them the engine falls back to a nominal map size there, so arrival radii and the
-- hearth landing check are not real. Each such zone gets its own coordinate frame (continent = uiMapID):
-- distances inside a zone are real yards, distances between such zones stay unknown (as before).
local dbMapsCache = setmetatable({}, { __mode = "k" })
local function dbMaps(db)
    if not db or type(db.zones) ~= "table" then return nil end
    if dbMapsCache[db] then return dbMapsCache[db] end
    local maps = {}
    for id, z in pairs(db.zones) do
        local size = type(z) == "table" and z.size
        if type(id) == "number" and not Mock.BUILTIN_MAPS[id] and type(size) == "table"
            and (size[1] or 0) > 0 and (size[2] or 0) > 0 then
            maps[id] = { name = z.name, mapType = 3, continent = id, width = size[1], height = size[2],
                         top = 0, left = 0 }
        end
    end
    dbMapsCache[db] = maps
    return maps
end


-- @param fresh apply the start state (first boot of a simulation; restarts copy the game state)
local function newMock(S, extra, fresh)
    local route, p, st = S.route, S.profile, S.state
    local mapID, x, y = startPosition(route)
    if st and st.at then mapID, x, y = st.at[1], st.at[2], st.at[3] end
    local opts = {
        locale = S.opts.locale,
        player = {
            race = p.race, class = p.class, faction = p.faction,
            -- --ahead L: a fresh character at L (--ahead-at: raised to L mid-route instead)
            level = (not S.opts.aheadAt and S.opts.ahead) or (st and st.level) or (route.levels and route.levels[1]) or 1,
            mapID = mapID, x = x, y = y,
        },
    }
    opts.maps = dbMaps(S.db)
    for k, v in pairs(extra or {}) do opts[k] = v end
    local m = Mock.new(opts)
    if S.db then m:UseForeverDB(S.db, { routeCompletes = routeCompletes(route) }) end
    if fresh and st then applyState(m, st) end
    return m
end

local function bootMock(S, m)
    local ns = Mock.loadAddon(m, CORE_TOC)
    local name = Loader.basename(S.module.dir)
    local boot = { "FastesBoooy" }
    for _, dep in ipairs(S.module.deps or {}) do -- dependencies first (Loader order)
        Mock.loadAddon(m, dep.toc, dep.name)
        boot[#boot + 1] = dep.name
    end
    Mock.loadAddon(m, S.toc, name)
    boot[#boot + 1] = name
    local h = S.harness
    if h then
        -- the harness route: registered through the public API right after the library, like a
        -- route module whose TOC depends on it
        m:_top(function()
            local api = rawget(m.env, "FastesBoooy")
            api.RegisterRoute(h.def)
            api.UseSegments(h.def.id, h.segments)
        end)
    end
    Mock.boot(m, boot)
    m:Advance(SETTLE)
    if ns.Engine:GetRoute() ~= ns.Registry:Get(S.route.id) then
        ns.Engine:SetRoute(S.route.id)
        m:Advance(SETTLE)
    end
    return ns
end

local function checkClean(S, m, when)
    local issues = {}
    for _, e in ipairs(m.errors) do issues[#issues + 1] = "error: " .. tostring(e.message) end
    for _, v in ipairs(m.violations) do issues[#issues + 1] = "violation: " .. v end
    for _, k in ipairs(sortedKeys(m.unmocked)) do issues[#issues + 1] = "unmocked API: " .. k end
    if #issues > 0 then fail(S, "%s: %s", when, table.concat(issues, "; ")) end
end

-- copy the game state of mock `src` into the fresh mock `dst` (before boot)
local function copyGameState(src, dst)
    local U = Mock.util
    dst.questDB = U.deepcopy(src.questDB)
    dst.questCache = U.deepcopy(src.questCache)
    dst.questLog = U.deepcopy(src.questLog)
    dst.completed = U.deepcopy(src.completed)
    dst.items = U.deepcopy(src.items)
    dst.bags = U.deepcopy(src.bags)
    dst._bagOrder = U.deepcopy(src._bagOrder)
    dst._bagSeq = src._bagSeq
    dst.bind = U.deepcopy(src.bind)
    for _, k in ipairs({ "level", "xp", "mapID", "x", "y", "facing", "money" }) do
        dst.player[k] = src.player[k]
    end
end

local function restartChecks(S)
    local E = engine(S)
    -- last done stateful anchor step (the cold-start cursor may not be before it)
    local anchorId
    for i = #E:GetSteps(), 1, -1 do
        local s = E:GetSteps()[i]
        if E:IsDone(i) and S.ns.Steps:IsAnchorStep(s) and S.ns.Steps:IsStatefulDone(s, E:GetContext(s)) then
            anchorId = s.id
            break
        end
    end

    -- /reload: SavedVariables restored
    local sv = S.m:ExportSavedVariables()
    local m2 = newMock(S, { savedVariables = sv })
    copyGameState(S.m, m2)
    local ns2 = bootMock(S, m2)
    checkClean(S, m2, "after /reload")
    if ns2.Engine:GetCursor() ~= nil then
        fail(S, "after /reload with SavedVariables the route is not finished (cursor on %s)",
            stepName(ns2.Engine:GetCurrentStep()))
    end

    -- cold start: EMPTY SavedVariables, progress rebuilt from the game state
    local m3 = newMock(S)
    copyGameState(S.m, m3)
    local ns3 = bootMock(S, m3)
    checkClean(S, m3, "after a cold start")
    if S.opts.sync then
        -- the sync floor was in the lost SavedVariables: the engine suggests the jump again (the
        -- player clicks it, like at the start)
        local n = 0
        while ns3.Engine:GetSyncSuggestion() do
            n = n + 1
            if n > 10 or not ns3.Engine:ApplySync() then fail(S, "cold start: the level sync does not settle") end
            m3:Advance(SETTLE)
        end
        checkClean(S, m3, "after a cold start + level sync")
    end
    local cur = ns3.Engine:GetCursor()
    local anchorIndex = anchorId and ns3.Engine:IndexOf(anchorId)
    if cur and anchorIndex and cur <= anchorIndex then
        fail(S, "cold start with empty SavedVariables: cursor on step %d %s, but step %d %s is already done",
            cur, stepName(ns3.Engine:GetCurrentStep()), anchorIndex, tostring(anchorId))
    end
    S.coldStart = cur and format("cold start resumes at step %d/%d", cur, #ns3.Engine:GetSteps())
        or "cold start: finished"
end

-- A background step may leave the "along the way" list only because its actions are
-- done (or remembered done) or its quests were turned in / left the log -- never just
-- because the cursor passed it (forwarding). Also records which bg steps were listed.
checkBgLeft = function(S)
    local E = engine(S)
    local Steps = S.ns.Steps
    local listed = {}
    for _, bg in ipairs(E:GetBackground()) do
        listed[bg.id] = true
        S.bgOpen[bg.id] = bg
    end
    for id, bg in pairs(S.bgOpen) do
        if not listed[id] then
            S.bgOpen[id] = nil
            local ctx = E:GetContext(bg)
            ctx.forwarded = false
            if not Steps:IsStepDone(bg, ctx) and Steps:IsBackgroundRelevant(bg, ctx) then
                fail(S, "background step %s left the along-the-way list without being done", stepName(bg))
            end
        end
    end
end

local function segText(seg)
    local t = seg and seg.title
    return format("%s (%s)", tostring(textEn(t) or (seg and seg.id)), tostring(seg and seg.id))
end

-- sync runs: every applied level sync (the banner's button or the engine itself in "auto"), from
-- the engine's SYNC_APPLIED message
local function listenSyncs(S)
    S.ns:Listen("SYNC_APPLIED", function(_, record)
        if type(record) ~= "table" then return end
        S.syncs[#S.syncs + 1] = format("level %s: %s -> %s", tostring(record.level), tostring(record.from),
            tostring(record.to))
        S.dropCheck = true
        vlog(S, "  [sync] level %s: %s -> %s (step %s)", tostring(record.level), tostring(record.from),
            tostring(record.to), tostring(record.stepId))
    end)
end

-- after a jump: the player abandons the quests the engine's chat line names (Engine:GetDroppedQuests)
local function abandonDropped(S)
    if not S.dropCheck then return end
    S.dropCheck = false
    local E, m = engine(S), S.m
    local list = E:GetDroppedQuests()
    for _, q in ipairs(list) do
        if m:IsOnQuest(q) then
            m:AbandonQuest(q)
            S.stats.dropped = S.stats.dropped + 1
        end
    end
    if #list > 0 then
        vlog(S, "    abandoned %d quest(s) the jump dropped: %s", #list, table.concat(list, ", "))
        settle(S, 1)
    end
end

-- sync runs: apply a level-sync suggestion like a click on the banner's jump button
local function applySuggestedSync(S)
    local E = engine(S)
    local sug = E:GetSyncSuggestion()
    if not sug then return false end
    local from, to, toId = sug.from, sug.to, sug.toStepId
    if not E:ApplySync() then fail(S, "ApplySync refused the suggestion %s -> %s", segText(from), segText(to)) end
    settle(S)
    local cur = E:GetCurrentStep()
    if not cur or E:GetCursor() < E:IndexOf(toId) then
        fail(S, "after the level sync to %s the cursor is on %s", tostring(toId), stepName(cur))
    end
    abandonDropped(S)
    return true
end

-- --ahead-at: index of the middle of the first listed segment the route has (filtered steps)
local function aheadAtIndex(S)
    local E = engine(S)
    for _, id in ipairs(S.opts.aheadAt) do
        for _, run in ipairs(E.segRuns or {}) do
            if run.id == id then return run.first + floor((run.last - run.first) / 2), id end
        end
    end
    fail(S, "--ahead-at: none of the segments %s is in this route", table.concat(S.opts.aheadAt, ","))
end

-- --level-plus N: the player's level N above the plan at the cursor (linear within the segment levels)
local function planLevel(S, cursor)
    local E = engine(S)
    local run = E.segRuns[E.segRunOf[cursor]]
    local lv = run and run.seg.levels
    if type(lv) ~= "table" then return nil end
    local frac = (run.last > run.first) and (cursor - run.first) / (run.last - run.first) or 0
    return math.min(S.m.maxLevel or 60, floor(lv[1] + (lv[2] - lv[1]) * frac) + S.opts.levelPlus)
end

local function simulate(S)
    local m = newMock(S, nil, true)
    S.m = m
    local ns = bootMock(S, m)
    S.ns = ns
    checkClean(S, m, "boot")
    if #ns.Registry.errors > 0 then
        fail(S, "%d registry error(s): %s", #ns.Registry.errors, tostring(ns.Registry.errors[1]))
    end
    local E = ns.Engine
    local route = E:GetRoute()
    if not route or route.id ~= S.route.id then
        fail(S, "the engine did not activate route %s (active: %s)", S.route.id, tostring(route and route.id))
    end
    local steps = E:GetSteps()
    if #steps == 0 then fail(S, "no step matches profile %s/%s", S.profile.race, S.profile.class) end
    S.stats.steps = #steps
    if S.opts.sync then listenSyncs(S) end
    if S.opts.levelPlus then
        ns.db.settings.levelSync = "auto"
        ns:Fire("SETTINGS_CHANGED", "levelSync", "auto")
        settle(S)
    end
    local midAt, midSeg
    if S.opts.aheadAt then
        midAt, midSeg = aheadAtIndex(S)
    elseif S.opts.ahead then
        applySuggestedSync(S)
    end

    local maxIter = #steps * 3 + 20
    local last = 0
    local bgTries = {}
    local iter = 0
    while true do
        local cursor = E:GetCursor()
        if cursor == nil then break end
        iter = iter + 1
        if iter > maxIter then fail(S, "no end after %d iterations (cursor %d)", maxIter, cursor) end
        if cursor < last then
            fail(S, "cursor moved backwards: %d -> %d (%s)", last, cursor, stepName(E:GetCurrentStep()))
        end
        last = cursor
        if midAt and cursor >= midAt then
            -- --ahead-at: the player outlevels the route here, with the quests of this part in the log
            midAt = nil
            vlog(S, "  [ahead] at step %d (%s): level %d -> %d, %d quest(s) in the log", cursor, midSeg,
                m.player.level, S.opts.ahead, #m.questLog)
            S.mid = format("at step %d (%s) with %d quest(s) in the log", cursor, midSeg, #m.questLog)
            m:SetLevel(math.max(m.player.level, S.opts.ahead), 0)
            settle(S)
            if not applySuggestedSync(S) then
                fail(S, "--ahead-at: no level-sync suggestion at step %d %s at level %d", cursor,
                    stepName(E:GetCurrentStep()), m.player.level)
            end
            cursor = E:GetCursor()
            if cursor == nil then break end
            last = cursor
        elseif S.opts.levelPlus then
            local want = planLevel(S, cursor)
            if want and m.player.level < want then
                m:SetLevel(want, 0)
                settle(S)
                abandonDropped(S) -- "auto": the engine may have jumped
                cursor = E:GetCursor()
                if cursor == nil then break end
                last = cursor
            end
        end
        local step = E:GetCurrentStep()
        vlog(S, "  [%d/%d] %s", cursor, #steps, stepName(step))
        performStep(S, step)
        checkClean(S, m, "step " .. stepName(step))
        local now = E:GetCursor()
        if now ~= nil and now <= cursor then
            local lines = {}
            for _, l in ipairs(ns.Steps:Describe(step)) do
                lines[#lines + 1] = (l.done and "[x] " or "[ ] ") .. tostring(l.text)
            end
            fail(S, "step %d %s is not done after performing it (cursor %s): %s", cursor, stepName(step),
                tostring(now), table.concat(lines, " | "))
        end
        if now and now > cursor + 1 then
            vlog(S, "    cursor %d -> %d", cursor, now)
        end
        -- background goals "on the way"
        checkBgLeft(S)
        for _, bg in ipairs({ unpack(E:GetBackground()) }) do
            if not S.bgSeen[bg.id] then
                S.bgSeen[bg.id] = true
                S.stats.bg = S.stats.bg + 1
            end
            bgTries[bg.id] = (bgTries[bg.id] or 0) + 1
            if bgTries[bg.id] > MAX_BG_TRIES then
                fail(S, "background step %s never completes", stepName(bg))
            end
            vlog(S, "  [bg] %s", stepName(bg))
            performStep(S, bg)
            checkClean(S, m, "bg step " .. stepName(bg))
        end
        checkBgLeft(S)
        local after = E:GetCursor()
        if after ~= nil and now ~= nil and after < now then
            fail(S, "cursor moved backwards after the background steps: %d -> %d (%s)", now, after,
                stepName(E:GetCurrentStep()))
        end
        if S.opts.ahead and not midAt and applySuggestedSync(S) then checkBgLeft(S) end
        abandonDropped(S)
    end
    S.stats.iterations = iter
    checkBgLeft(S)
    if S.opts.sync then
        -- a complete quest left in the log: a turn-in the level sync lost
        local complete, open = {}, 0
        for _, e in ipairs(m.questLog) do
            if m:_isComplete(e) then complete[#complete + 1] = tostring(e.questID) else open = open + 1 end
        end
        if #complete > 0 then
            fail(S, "route finished with complete quest(s) in the log (turn-ins lost): %s", table.concat(complete, ", "))
        end
        S.stats.leftInLog = open
    end
    for i, s in ipairs(steps) do
        if s.bg and not S.bgSeen[s.id] and not E:IsDone(i) then
            warn(S, "background step %s was never listed 'along the way'", stepName(s))
        end
    end
    if #E:GetBackground() > 0 then
        fail(S, "route finished with %d background step(s) still open", #E:GetBackground())
    end
    local absent = m:AbsentGlobals()
    if #absent > 0 then warn(S, "globals absent from Forever were read: %s", table.concat(absent, ", ")) end
    if S.opts.reload then restartChecks(S) end
end

-- the game state at the end of a simulation (tools/lib/harness.lua format, --write-state)
local function endState(S)
    local m, p = S.m, S.m.player
    local done, log, complete = {}, {}, {}
    for id, v in pairs(m.completed) do
        if v == true then done[#done + 1] = id end
    end
    table.sort(done)
    for _, e in ipairs(m.questLog) do log[#log + 1] = e.questID end
    table.sort(log)
    for _, id in ipairs(log) do
        if m:_isComplete(m:_logEntry(id)) then complete[#complete + 1] = id end
    end
    local fps = sortedKeys(S.flightPaths)
    local function r2(v) return floor(v * 100 + 0.5) / 100 end
    local b = m.bind
    return {
        level = p.level, xpFrac = Harness.Fraction(p.xp, m:XPMax(p.level)),
        done = done, log = log, complete = complete,
        hearth = b and b.name or nil, hearthAt = b and b.mapID and { b.mapID, r2(b.x or 50), r2(b.y or 50) } or nil,
        at = { p.mapID, r2(p.x), r2(p.y) }, flightPaths = fps,
        meta = {
            source = "tools/simulate_routes.lua", route = S.route.id,
            profile = format("%s %s %s", p.race, p.class, p.faction),
            note = "mock XP = quest XP only (no kill XP): the level is lower than the validator's end state",
            startState = S.state and S.state.file or nil,
        },
    }
end

local function runOne(opts, module, toc, route, profile, db, extra)
    local S = {
        opts = opts, module = module, toc = toc, route = route, profile = profile, db = db,
        warnings = {}, bgSeen = {}, bgOpen = {}, gossipUsed = {},
        stats = { steps = 0, iterations = 0, accepted = 0, turnedIn = 0, bg = 0, gossip = 0, delayed = 0,
            estimatedXP = 0, dropped = 0, travelled = 0, leftInLog = 0 },
        state = opts.startState, harness = extra and extra.harness, flightPaths = {}, syncs = {},
    }
    for _, fp in ipairs(S.state and S.state.flightPaths or {}) do S.flightPaths[fp] = true end
    local label = format("%s (%s %s %s)", route.id, profile.race, profile.class, profile.faction)
    if opts.ahead then
        label = label .. format(" ahead: level %d", opts.ahead)
        if opts.aheadAt then label = label .. " at " .. table.concat(opts.aheadAt, ",") end
    elseif opts.levelPlus then
        label = label .. format(" level plan +%d (auto)", opts.levelPlus)
    end
    if opts.verbose then print("== " .. label) end
    local ok, err = pcall(simulate, S)
    if opts.verbose and S.m then
        local p = S.m.player
        print(format("   player: race %s (raceID %s), class %s (classID %s), faction %s", tostring(p.race),
            tostring(p.raceID), tostring(p.class), tostring(p.classID), tostring(p.faction)))
    end
    local st = S.stats
    if ok then
        local p = S.m.player
        local xpMax = S.m:XPMax(p.level)
        print(format("OK   %s: %d steps, %d iterations, %d accepted, %d turned in, %d bg, %d gossip, "
            .. "%d delayed actions; level %d (%d%%)%s; %s%s",
            label, st.steps, st.iterations, st.accepted, st.turnedIn, st.bg, st.gossip, st.delayed, p.level,
            xpMax > 0 and floor(p.xp / xpMax * 100) or 0,
            st.estimatedXP > 0 and format(", %d quest XP estimated", st.estimatedXP) or "",
            S.coldStart or "no restart checks",
            #S.warnings > 0 and format(", %d warning(s)", #S.warnings) or ""))
        if opts.sync then
            local E = S.ns.Engine
            local void = { gray = 0, unreachable = 0, orphan = 0 }
            for _, why in pairs(E.void or {}) do void[why] = (void[why] or 0) + 1 end
            print(format("     sync: %s%s; at the end %d gray / %d unreachable accept(s) and %d never-taken "
                .. "complete/turnin/collect action(s) skipped; %d dropped quest(s) abandoned, %d incomplete left in "
                .. "the log; %d fly/hearth step(s) travelled (flight path / bind skipped by the jump)",
                S.mid and (S.mid .. ": ") or "", #S.syncs > 0 and table.concat(S.syncs, "; ") or "none suggested",
                void.gray, void.unreachable, void.orphan, st.dropped, st.leftInLog, st.travelled))
        end
        if not opts.verbose then
            for _, w in ipairs(S.warnings) do print("     warning: " .. w) end
        end
        return true, endState(S)
    end
    local msg = getmetatable(err) == FAIL and err.msg or tostring(err)
    print(format("FAIL %s: %s", label, msg))
    for _, w in ipairs(S.warnings) do print("     warning: " .. w) end
    if S.m and opts.verbose then
        local diag = S.m:Diagnostics()
        if diag ~= "" then print("     mock: " .. diag:gsub("\n", "\n     mock: ")) end
    end
    return false
end

---------------------------------------------------------------------------
-- main
---------------------------------------------------------------------------

local function writeEndState(opts, results)
    if #results ~= 1 then
        io.stderr:write(format("simulate_routes: --write-state needs exactly one simulation, this run has %d "
            .. "(select one with --route ID and --profile race=,class=,faction=, or use --harness)\n", #results))
        return 2
    end
    if not results[1] then
        io.stderr:write("simulate_routes: the simulation failed: no end state written\n")
        return 1
    end
    local ok, err = Harness.WriteState(opts.writeState, results[1])
    if not ok then
        io.stderr:write("simulate_routes: " .. tostring(err) .. "\n")
        return 2
    end
    local es = results[1]
    print(format("simulate_routes: end state written to %s: level %d + %.2f, %d done, %d in the log (%d complete), "
        .. "hearth %s", opts.writeState, es.level, es.xpFrac, #es.done, #es.log, #es.complete, tostring(es.hearth or "-")))
    return 0
end

local function profileMatches(filter, p)
    if not filter then return true end
    return (not filter.race or filter.race == p.race) and (not filter.class or filter.class == p.class)
        and (not filter.faction or filter.faction == p.faction)
end

-- --harness: one synthetic route over library segments, one profile
local function mainHarness(opts, schema, db)
    local profile, perr = Harness.Profile(opts.profile)
    if not profile then
        io.stderr:write("simulate_routes: " .. perr .. "\n")
        return 2
    end
    local hb = Harness.Build(opts.harness, { schema = schema, segments = opts.segments, profile = profile })
    if hb.fatal then
        io.stderr:write("simulate_routes: harness: " .. hb.fatal .. "\n")
        return 2
    end
    if hb.empty then
        print(format("simulate_routes: harness: library module %s registers no library segments yet (its segment "
            .. "files are placeholders); nothing to simulate", hb.mod.name))
        return #hb.mod.errors > 0 and 1 or 0
    end
    local errors = {}
    for _, e in ipairs(hb.mod.errors) do errors[#errors + 1] = e end
    for _, e in ipairs(hb.errors) do errors[#errors + 1] = e end
    if #errors > 0 or not hb.route then
        print(format("FAIL %s (harness %s): %d load/schema error(s)", Harness.RouteId(hb.mod.name), hb.mod.name,
            #errors))
        for i, e in ipairs(errors) do
            if i > 10 then break end
            print(format("     %s: %s", tostring(e.file), tostring(e.msg)))
        end
        print("simulate_routes: 1 simulation(s), 0 passed, 1 failed")
        return 1
    end
    local module = { dir = hb.dir, deps = hb.mod.deps, name = hb.mod.name }
    local harness = { def = hb.def, segments = hb.segments }
    local ok, es = runOne(opts, module, Loader.FindToc(hb.dir), hb.route, profile, db, { harness = harness })
    print(format("simulate_routes: 1 simulation(s), %d passed, %d failed", ok and 1 or 0, ok and 0 or 1))
    if opts.writeState then
        local code = writeEndState(opts, { ok and es or false })
        if code ~= 0 then return code end
    end
    return ok and 0 or 1
end

local function main(argv)
    local opts, err = parseArgs(argv)
    if not opts then
        io.stderr:write(err .. "\n" .. USAGE .. "\n")
        return 2
    end
    if opts.help then
        print(USAGE)
        return 0
    end
    if not Loader.fileExists(CORE_TOC) then
        io.stderr:write("run from the repository root (" .. CORE_TOC .. " not found)\n")
        return 2
    end
    if opts.harness and (#opts.dirs > 0 or opts.fixtures or opts.route) then
        io.stderr:write("simulate_routes: --harness takes no module directories, --fixtures or --route\n")
        return 2
    end
    if opts.segments and not opts.harness then
        io.stderr:write("simulate_routes: --segments is only used with --harness\n")
        return 2
    end
    if opts.state then
        local st, errs = Harness.ReadState(opts.state)
        if not st then
            io.stderr:write("simulate_routes: " .. table.concat(errs, "\nsimulate_routes: ") .. "\n")
            return 2
        end
        opts.startState = st
    end

    local db
    if opts.db then
        if Loader.fileExists(opts.db) then
            db = FBDB.Load(opts.db)
        else
            print("simulate_routes: " .. opts.db .. " not found: quests without DB data")
        end
    end
    local schema = Loader.LoadSchema(".")
    if opts.harness then return mainHarness(opts, schema, db) end

    local dirs = {}
    if #opts.dirs > 0 then
        for _, d in ipairs(opts.dirs) do dirs[#dirs + 1] = (d:gsub("[/\\]+$", "")) end
    else
        for _, d in ipairs(Loader.DiscoverModules("addons")) do dirs[#dirs + 1] = d end
        if opts.fixtures then
            for _, d in ipairs(Loader.DiscoverModules("tests/fixtures/core")) do dirs[#dirs + 1] = d end
        end
    end
    if #dirs == 0 then
        print("simulate_routes: no route modules to simulate")
        return 0
    end

    local total, failed = 0, 0
    local results = {}
    for _, dir in ipairs(dirs) do
        local toc = Loader.FindToc(dir)
        if not toc then
            print(format("FAIL %s: no TOC", dir))
            failed, total = failed + 1, total + 1
            results[#results + 1] = false
        else
            local mod = Loader.LoadModule(dir, { schema = schema })
            if mod.isLibrary and #mod.errors == 0 then
                print(format("skip %s: library module (its segments are simulated in the routes that use them; "
                    .. "a part of it: --harness)", mod.name))
            elseif #mod.errors > 0 then
                total, failed = total + 1, failed + 1
                results[#results + 1] = false
                print(format("FAIL %s: %d load/schema error(s)", mod.name, #mod.errors))
                for i, e in ipairs(mod.errors) do
                    if i > 10 then break end
                    print(format("     %s: %s", tostring(e.file), tostring(e.msg)))
                end
            else
                for _, route in ipairs(mod.routes) do
                    if not opts.route or opts.route == route.id then
                        for _, profile in ipairs(profiles(route)) do
                            if profileMatches(opts.profile, profile) then
                                total = total + 1
                                local ok, es = runOne(opts, mod, toc, route, profile, db)
                                if not ok then failed = failed + 1 end
                                results[#results + 1] = ok and es or false
                            end
                        end
                    end
                end
            end
        end
    end
    if total == 0 then
        print("simulate_routes: no route matched" .. (opts.route and (" --route " .. opts.route) or ""))
        return (opts.route or opts.profile) and 1 or 0
    end
    print(format("simulate_routes: %d simulation(s), %d passed, %d failed", total, total - failed, failed))
    if opts.writeState then
        local code = writeEndState(opts, results)
        if code ~= 0 then return code end
    end
    return failed > 0 and 1 or 0
end

os.exit(main(arg))
