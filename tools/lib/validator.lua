-- tools/lib/validator.lua -- offline route validator (Lua 5.1).
--
-- Loads route modules with lib.route_loader (sandbox + Core/Schema.lua normalization)
-- and checks every route against the Forever DB snapshot (tools/data/forever_db.lua)
-- for each player profile (faction / raceFile / classFile) the route targets, while
-- simulating the quest log and the character's XP/level step by step.
--
--   local V = require("lib.validator")
--   local res = V.ValidateModule(dir, { db = db, schema = Schema })
--   res.results[i] = { route = id, profile = {...}, messages = {...}, counts = {ERROR=,WARN=,INFO=},
--                      segments = {...}, summary = {...} }
--   os.exit(V.Main(arg))           -- CLI (tools/validate_routes.lua)
--
-- Every message has a severity (ERROR / WARN / INFO) and a stable `code`
-- (see tools/README.md for the list); `--ignore code,code` suppresses codes.
-- Next to the text a message carries stable fields where they apply: `quest` (the quest of the
-- action), `npc` / `object`, `kills`, `level` (the simulated level in the text), `file`, and
-- `shared = true` on a shared step / segment (a library segment step or a shared-insert step),
-- `inserted = true` on a step of an insert (AddInsert / AddLibraryInsert: a class or race step).
--
-- Reports: V.FormatText (the complete view of every route), V.ReportTable (--json, complete) and
-- V.FormatMarkdown = lib/report.lua (docs/VALIDATION.md: aggregated over the routes -- the messages
-- on steps of shared segments once for all routes, a gate matrix, INFO as counts).
--
-- Acknowledged warnings: a WARN whose code is listed in `ok` of its step (of its segment for a
-- message about the segment) is ACCEPTED: m.accepted = true, counted in result.acceptedWarn instead of
-- counts.WARN, printed only with -v, not counted by --strict. `ok = { ["level-grind"] = N }` accepts
-- only while the gate needs at most N kills (V.OkAccepts).
--
-- Library segments (FastesBoooy.UseSegments, Core/Compose.lua): a route module is loaded
-- with its FastesBoooy_* dependencies and validated as the composed route. Messages about
-- library steps / segments carry `library = "<library module>"` ("[library X]" in the text
-- and Markdown reports) and are reported once per route (identical ones of further
-- profiles are dropped). A library module is not a route: its own load / schema errors
-- are reported once per run (in its own entry when it is part of the run, else with the
-- first route module that depends on it).
--
-- Mixed modules (routes AND shared content in one addon, FastesBoooy_Guides): the module gets one
-- more entry in front of its routes, "(shared <Module>)" (result.shared = module name), with the
-- checks on its shared TEMPLATES (tools/lib/module_checks.lua: a template step with a mistyped race
-- or an insert with a wrong anchor is composed into no route and would be invisible otherwise).
-- Messages that must not change the exit status are NOTES (moduleResult.notes): template checks of
-- files that are not the caller's own on a partial load (--skip / --keep with --own), with --route
-- the errors that belong to a route outside the selection (never a file that did not load: see
-- V.ValidateModule), a broken override file on a partial load.
--
-- Whole-run checks (V.Main): WARN ok-unused (V.CheckOkUnused, full runs only), the DB override layer
-- (tools/lib/fbdb.lua DB.ApplyOverrides; V.OverrideChecks: ERROR override-load / override-foreign-quest
-- in the entry "(overrides)"), own / foreign warnings (--own, V.MarkForeign), the numeric criteria
-- (V.ApplyCriteria: ERROR end-level / grind-budget / grind-baseline).
--
-- Start states and harness runs (tools/lib/harness.lua): opts.startState starts the simulation
-- from a character state instead of a fresh level-1 character (level / XP, quests turned in,
-- quest log, hearthstone, flight paths); V.ValidateHarness validates a synthetic one-profile
-- route that only uses some library segments (validate_routes.lua --harness). Run:EndState()
-- is the state at the end of the run (--write-state), in the same format.

local DB = require("lib.fbdb")
local Loader = require("lib.route_loader")
local json = require("lib.json")
local Harness = require("lib.harness")
local Glob = require("lib.glob")
local ModuleChecks = require("lib.module_checks")
local Report = require("lib.report")

local V = {}

V.DEFAULTS = {
    -- distance from `at` to an NPC / object spawn (or the nearest quest giver / ender):
    toleranceYards = 40,      -- yards: WARN above
    hardToleranceYards = 120, -- yards: ERROR above
    -- fallback for maps without known world size (zones[uiMap].size, e.g. Zephras Isle 2521):
    tolerance = 3.0,          -- map percent (approximate): WARN above
    hardTolerance = 8.0,      -- map percent (approximate): ERROR above
    grindWarnKills = 30,    -- level step: WARN when more estimated kills are needed
    defaultKillCount = 4,   -- hostile creature objective without a known count (conservative)
    uniqueSpawnMax = 5,     -- ...but 1 kill for a named/unique NPC: rank > 0 or at most this many spawn points
    dropKillFactor = 1.5,   -- kills per required drop item (drop rates are not in the DB)
    -- optimistic parallel simulation: a level requirement is an ERROR only when even the
    -- optimistic level is too low, otherwise a WARN (the shortfall may be an estimation artifact)
    unknownXpOptimism = 2.0,  -- unknown (estimated) quest XP x2
    guessedKillOptimism = 1.5, -- objective kills whose count was assumed x1.5
    -- incidental kills while travelling (--incidental-pct): every turn-in also gives this percent
    -- of its quest XP as kill XP (0 = off: only objective kills and level-step grinding count)
    incidentalPct = 0,
    -- grind band printed for every run (V.RunProfile): incidental kills 0% and this percent
    incidentalBandPct = 15,
    -- the core's auto-accept window (settings.lookahead, Core/Init.lua): quests of the steps
    -- [cursor, cursor + lookahead] are accepted at the NPC (lookahead-skip check)
    lookahead = 6,
}

V.SEVERITIES = { "ERROR", "WARN", "INFO" }

local CLASS_NAMES = {
    WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
    SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid",
}
V.CLASS_NAMES = CLASS_NAMES

local RACE_FACTION = {
    Human = "Alliance", Dwarf = "Alliance", NightElf = "Alliance", Gnome = "Alliance",
    Orc = "Horde", Scourge = "Horde", Tauren = "Horde", Troll = "Horde", Goblin = "Horde",
}
-- raceFiles playable on both sides (one UnitRace() raceFile, faction-specific race bits)
local BOTH_SIDES = { Skyborne = { "Horde", "Alliance" } }

local format, floor = string.format, math.floor

local function sortedKeys(t)
    local out = {}
    for k in pairs(t or {}) do out[#out + 1] = k end
    table.sort(out, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) == "number"
    end)
    return out
end

local function contains(list, v)
    for _, x in ipairs(list or {}) do
        if x == v then return true end
    end
    return false
end

local function anyIn(ids, list)
    for _, id in ipairs(ids or {}) do
        if contains(list, id) then return true end
    end
    return false
end

-- does the step have an action of this type for quest q?
local function hasQuestActionV(step, actionType, q)
    for _, a in ipairs(step.actions or {}) do
        if a.type == actionType and a.quest == q then return true end
    end
    return false
end

local function round2(v)
    return floor(v * 100 + 0.5) / 100
end

---------------------------------------------------------------------------
-- acknowledged warnings (step / segment key `ok`, Schema.NormalizeOk: { [code] = true | ceiling })
---------------------------------------------------------------------------

-- codes that can only be acknowledged with a ceiling (ERROR ok-needs-ceiling otherwise): a shared
-- gate acknowledged once must not pass any number of kills for every route that contains it
local NEEDS_CEILING = { ["level-grind"] = true }
V.NEEDS_CEILING = NEEDS_CEILING

--- Does an `ok` table accept message m? Only a WARN can be accepted. A ceiling applies to a message
-- with a kill count (m.kills, level-grind): accepted while m.kills <= ceiling.
-- @return accepted, ceiling (the number, when the code has one)
function V.OkAccepts(okT, m)
    local v = okT and okT[m.code]
    if v == nil or m.severity ~= "WARN" then return false end
    if type(v) == "number" then
        if m.kills and m.kills > v then return false, v end
        return true, v
    end
    if NEEDS_CEILING[m.code] then return false end
    return true
end

-- apply the `ok` of the message's step / segment to a new message
local function acknowledge(okT, m)
    local accepted, ceiling = V.OkAccepts(okT, m)
    if accepted then
        m.accepted = true
        m.okCeiling = ceiling
    elseif ceiling then
        m.okCeiling = ceiling
        m.msg = m.msg .. format(" (above the acknowledged ceiling of %s kills: the `ok` of this step no longer "
            .. "applies)", tostring(ceiling))
    end
    return m
end
V.Acknowledge = acknowledge

-- count a message in a run / result (an accepted WARN is counted apart, in holder.acceptedWarn)
local function countMessage(holder, m, d)
    if m.accepted then
        holder.acceptedWarn = (holder.acceptedWarn or 0) + d
    else
        holder.counts[m.severity] = holder.counts[m.severity] + d
    end
end
V.CountMessage = countMessage

---------------------------------------------------------------------------
-- profiles
---------------------------------------------------------------------------

--- Player profiles a route is validated for: every (race x class) of the route
-- metadata, with optional overrides { race=, class=, faction= }.
function V.Profiles(route, override)
    override = override or {}
    local races = override.race and { override.race } or sortedKeys(route.races)
    local classes = override.class and { override.class } or sortedKeys(route.classes)
    if #races == 0 then races = { false } end
    if #classes == 0 then classes = { false } end
    local out = {}
    for _, race in ipairs(races) do
        for _, cls in ipairs(classes) do
            local faction = override.faction or route.faction or (race and RACE_FACTION[race]) or nil
            if not faction and race and BOTH_SIDES[race] then
                -- e.g. Skyborne without route.faction: validate both sides
                for _, f in ipairs(BOTH_SIDES[race]) do
                    out[#out + 1] = { race = race, class = cls or nil, faction = f }
                end
            else
                out[#out + 1] = { race = race or nil, class = cls or nil, faction = faction }
            end
        end
    end
    return out
end

local function profileLabel(p)
    return format("%s %s %s", tostring(p.race or "any-race"), tostring(p.class or "any-class"),
        tostring(p.faction or "any-faction"))
end
V.ProfileLabel = profileLabel

---------------------------------------------------------------------------
-- one validation run (route x profile)
---------------------------------------------------------------------------

local Run = {}
Run.__index = Run

function V.NewRun(db, schema, route, profile, opts)
    opts = opts or {}
    local r = setmetatable({
        db = db, schema = schema, route = route, profile = profile, opts = opts,
        tol = opts.tolerance or V.DEFAULTS.tolerance,
        hardTol = opts.hardTolerance or V.DEFAULTS.hardTolerance,
        tolYd = opts.toleranceYards or V.DEFAULTS.toleranceYards,
        hardTolYd = opts.hardToleranceYards or V.DEFAULTS.hardToleranceYards,
        messages = {}, counts = { ERROR = 0, WARN = 0, INFO = 0 }, suppressed = 0, acceptedWarn = 0,
        st = { level = 1, xp = 0 },
        opt = { level = 1, xp = 0 }, -- optimistic simulation (see V.DEFAULTS.unknownXpOptimism)
        active = {}, activeCount = 0, maxLog = 0,
        accepted = {}, turnedIn = {}, abandoned = {}, completed = {}, credited = {},
        collected = {}, hearth = nil, hearthAt = nil, lastAt = nil, flightPaths = {},
        xp = { quest = 0, questEstimated = 0, kill = 0, grind = 0, grindKills = 0, incidental = 0,
               unknownXpQuests = 0, turnins = 0, accepts = 0 },
        segments = {}, seg = nil,
        gates = {}, gateSteps = {}, gateByStep = {}, -- level steps (H.level): grind per gate
        walked = {}, walkedOrd = {}, -- steps processed for this profile, in order (skip-ahead check)
        ordinal = 0, msgOrd = {}, -- step ordinal of every message (merging shadow-run messages)
        -- worst case (opts.worstCase, V.RunProfile): optional steps are not done
        worst = opts.worstCase and true or false,
        optQuest = {}, optTurnin = {}, optSkipped = 0, optAccepts = 0,
        optFp = {}, optHearth = {}, -- fp / sethearth of skipped optional steps: [place] = step
        levelBefore = {}, -- [step] = simulated level value before the step (--levels)
    }, Run)
    r.letter = profile.faction == "Horde" and "H" or (profile.faction == "Alliance" and "A" or nil)
    r.facts = { race = profile.race, class = profile.class, faction = profile.faction }
    if profile.race then
        r.raceMask = DB.RaceMask(db, profile.race, profile.faction)
        if not r.raceMask then
            if type(db.enums.raceFileToBit[profile.race]) == "table" and not profile.faction then
                r:add("ERROR", "profile-race", nil, "raceFile '%s' exists on both factions: the route needs "
                    .. "`faction`", tostring(profile.race))
            else
                r:add("ERROR", "profile-race", nil, "unknown raceFile '%s' for faction %s (expected e.g. Scourge, "
                    .. "Orc, Tauren, Troll, Skyborne)", tostring(profile.race), tostring(profile.faction))
            end
        end
    end
    if profile.class then
        r.classMask = DB.ClassMask(db, profile.class)
        if not r.classMask then
            r:add("ERROR", "profile-class", nil, "unknown class token '%s'", tostring(profile.class))
        end
    end
    if not r.letter then
        r:add("WARN", "profile-faction", nil, "route has no faction; side checks are skipped")
    end
    if opts.startState then r:applyState(opts.startState) end
    return r
end

--- Start the simulation from a character state (tools/lib/harness.lua format): level and XP,
-- quests turned in ("done"), quests in the log ("log", objectives done for "complete"), hearthstone
-- bind place, position and known flight paths.
function Run:applyState(state)
    local db = self.db
    -- pseudo step of everything the start state says was done before the run
    local STATE_STEP = { segment = "start-state", segIndex = 0, id = "start-state", actions = {}, file = state.file,
                         isState = true }
    self.stateStep = STATE_STEP
    local level = math.min(state.level or 1, db.levelCap or 60)
    self.st.level = level
    self.st.xp = Harness.XpFromFraction(state.xpFrac, DB.XpToLevel(db, level))
    self.opt.level, self.opt.xp = self.st.level, self.st.xp
    local function known(id, what)
        if DB.Quest(db, id, self.profile.class) or DB.QuestBrief(db, id) then return true end
        self:add("ERROR", "quest-unknown", STATE_STEP, "start state %s: quest %d does not exist in the Forever DB",
            what, id)
        return false
    end
    for _, id in ipairs(state.done or {}) do
        known(id, "done")
        self.turnedIn[id] = STATE_STEP
    end
    for _, id in ipairs(state.log or {}) do
        known(id, "log")
        self.active[id] = { step = STATE_STEP }
        self.accepted[id] = STATE_STEP
        self.activeCount = self.activeCount + 1
    end
    local cap = db.questLogSize or 40
    if self.activeCount > cap then
        self:add("ERROR", "questlog-full", STATE_STEP, "start state: the quest log holds %d quests (Forever maximum %d)",
            self.activeCount, cap)
    end
    self.maxLog = self.activeCount
    for _, id in ipairs(state.complete or {}) do
        self.completed[id] = STATE_STEP
        local q = DB.Quest(db, id, self.profile.class)
        local credited = {}
        for idx in ipairs(q and V.ObjectiveList(q) or {}) do credited[idx] = true end
        self.credited[id] = credited
    end
    self.hearth = state.hearth
    if state.hearthAt then
        self.hearthAt = { map = state.hearthAt[1], x = state.hearthAt[2], y = state.hearthAt[3] }
    end
    if state.at then self.lastAt = { map = state.at[1], x = state.at[2], y = state.at[3] } end
    for _, p in ipairs(state.flightPaths or {}) do self.flightPaths[p] = true end
end

local function point(at)
    if not at then return nil end
    return { at.map, round2(at.x), round2(at.y) }
end

--- Has every objective of an active quest been completed (complete steps / start state)?
function Run:objectivesDone(id)
    if not self.completed[id] then return false end
    local q = DB.Quest(self.db, id, self.profile.class)
    if not q then return true end
    local credited = self.credited[id] or {}
    for idx, e in ipairs(V.ObjectiveList(q)) do
        if not credited[idx] and not (e.kind == "item" and self.collected[e.id]) then return false end
    end
    return true
end

--- The character state at the end of the run (tools/lib/harness.lua format; --write-state).
function Run:EndState()
    local db = self.db
    local done, log, complete = {}, {}, {}
    for id in pairs(self.turnedIn) do done[#done + 1] = id end
    for id in pairs(self.active) do log[#log + 1] = id end
    table.sort(done)
    table.sort(log)
    for _, id in ipairs(log) do
        if self:objectivesDone(id) then complete[#complete + 1] = id end
    end
    local fps = sortedKeys(self.flightPaths)
    local segIds = {}
    for i, seg in ipairs(self.route.segments or {}) do segIds[i] = tostring(seg.id) end
    return {
        level = self.st.level,
        xpFrac = Harness.Fraction(self.st.xp, DB.XpToLevel(db, self.st.level)),
        done = done, log = log, complete = complete,
        hearth = self.hearth, hearthAt = point(self.hearthAt), at = point(self.lastAt), flightPaths = fps,
        meta = json.object({
            source = "tools/validate_routes.lua", route = tostring(self.route.id), profile = profileLabel(self.profile),
            levelValue = round2(DB.LevelValue(db, self.st)),
            levelOptimistic = round2(math.max(DB.LevelValue(db, self.opt), DB.LevelValue(db, self.st))),
            segments = segIds,
            startState = self.opts.startState and self.opts.startState.file or nil,
        }),
    }
end

function Run:add(sev, code, step, msg, ...)
    return self:addx(sev, code, step, nil, msg, ...)
end

--- Run:add with stable fields: `fields` ({ npc = id, kills = n, level = 12.3, quest = id, ... }) is
-- copied into the message before its step's `ok` is applied (a ceiling reads m.kills).
function Run:addx(sev, code, step, fields, msg, ...)
    -- shadow runs (V.RunProfile) keep only the codes they report into the main run
    if self.opts.keepCodes and not self.opts.keepCodes[code] then return end
    if self.opts.ignore and self.opts.ignore[code] then
        self.suppressed = self.suppressed + 1
        return
    end
    local m = {
        severity = sev, code = code, msg = select("#", ...) > 0 and format(msg, ...) or msg,
    }
    local okT
    if step then
        m.segment = step.segment
        m.step = step.segIndex
        m.stepId = step.id
        m.file = step.file
        if type(step.library) == "string" then m.library = step.library end
        -- a step of an insert (AddInsert / AddLibraryInsert): a class or race step, not the base path
        if step.inserted then m.inserted = true end
        okT = step.ok
    elseif self.seg then
        m.segment = self.seg.id
        m.file = self.seg.file
        if type(self.seg.library) == "string" then m.library = self.seg.library end
        okT = self.seg.ok
    end
    if m.library then m.shared = true end
    if self.curQuest then m.quest = self.curQuest end -- the quest of the action being processed
    for k, v in pairs(fields or {}) do m[k] = v end
    if okT and sev == "WARN" then acknowledge(okT, m) end
    self.messages[#self.messages + 1] = m
    countMessage(self, m, 1)
    self.msgOrd[m] = self.ordinal
    return m
end

--- The simulated level as a message field (two decimals).
function Run:levelField()
    return round2(DB.LevelValue(self.db, self.st))
end

-- "363 \"Rude Awakening\""
function Run:qn(id)
    local b = DB.QuestBrief(self.db, id)
    return format('%d "%s"', id, b and b.name or "?")
end

function Run:nn(id)
    local b = DB.NpcBrief(self.db, id)
    return format('%d "%s"', id, b and b.name or "?")
end

function Run:on(id)
    local b = DB.ObjectBrief(self.db, id)
    return format('%d "%s"', id, b and b.name or "?")
end

function Run:names(ids, fn)
    local out = {}
    for i, id in ipairs(ids or {}) do
        if i > 6 then out[#out + 1] = format("... (+%d)", #ids - 6) break end
        out[#out + 1] = fn(self, id)
    end
    return table.concat(out, ", ")
end

function Run:stepRef(step) -- luacheck: ignore 212/self
    if not step then return "?" end
    if step.isState then return "the start state" end
    return format("%s#%d", tostring(step.segment), step.segIndex or 0)
end

function Run:levelStr()
    return format("%.2f", DB.LevelValue(self.db, self.st))
end

function Run:raceNames(mask)
    if not mask or mask == 0 then return "all" end
    local out = {}
    for _, k in ipairs(sortedKeys(self.db.enums.races)) do
        if DB.HasBit(mask, self.db.enums.races[k]) then out[#out + 1] = k end
    end
    return table.concat(out, ",")
end

function Run:classNames(mask)
    if not mask or mask == 0 then return "all" end
    local out = {}
    for _, k in ipairs(sortedKeys(self.db.enums.classes)) do
        if DB.HasBit(mask, self.db.enums.classes[k]) then out[#out + 1] = k end
    end
    return table.concat(out, ",")
end

--- Quest lookup with existence check.
-- @return record, isFull  (record is the full DB record or a brief one; nil when unknown)
function Run:quest(id, step, verb)
    local q = DB.Quest(self.db, id, self.profile.class)
    if q then return q, true end
    local b = DB.QuestBrief(self.db, id)
    if b then
        self:add("WARN", "quest-out-of-scope", step, "%s %s: quest exists in Forever but is outside the DB "
            .. "snapshot scope (zone %s); NPC/prerequisite checks skipped (extend tools/build_db_snapshot.py)",
            verb, self:qn(id), tostring(b.zone))
        return b, false
    end
    self:add("ERROR", "quest-unknown", step, "%s %d: quest does not exist in the Forever DB", verb, id)
    return nil
end

local function hasObjectives(q)
    local o = q.objectives
    if not o then return false end
    return (o.creatures and #o.creatures > 0) or (o.killCredit and #o.killCredit > 0)
        or (o.objects and #o.objects > 0) or (o.items and #o.items > 0)
        or (o.spells and #o.spells > 0) or o.event or o.reputation ~= nil
end

-- Flat objective list in a fixed order (creatures, killCredit, objects, items).
local function objectiveList(q)
    local out = {}
    local o = q.objectives or {}
    for _, e in ipairs(o.creatures or {}) do
        out[#out + 1] = { kind = "creature", id = e[1], count = e[2], icon = e.icon }
    end
    for _, e in ipairs(o.killCredit or {}) do
        out[#out + 1] = { kind = "killCredit", id = e.base or (e.ids and e.ids[1]), ids = e.ids, count = e.count,
                          icon = e.icon }
    end
    for _, e in ipairs(o.objects or {}) do out[#out + 1] = { kind = "object", id = e[1], count = e[2] } end
    for _, e in ipairs(o.items or {}) do out[#out + 1] = { kind = "item", id = e[1], count = e[2] } end
    return out
end
V.ObjectiveList = objectiveList

function Run:friendly(npc)
    if not self.letter then return true end
    return (npc.faction or ""):find(self.letter, 1, true) ~= nil
end

---------------------------------------------------------------------------
-- objective targets: which creature objectives are kills
---------------------------------------------------------------------------

-- QuestieDB objective icons (db.enums.iconTypes) that are not kills: talk, interact (heal,
-- use an item on, free...), event (killCredit "events": a dummy credit NPC), loot, object.
local NON_KILL_ICON = { [2] = "loot", [3] = "event", [4] = "object", [5] = "talk", [17] = "interact" }

--- Why killing `npcId` for objective `e` gives no XP; nil when it is a hostile creature.
-- Signals: the objective icon (talk / interact / event), the NPC record (unknown NPC, any NPC
-- flag such as questgiver / trainer / vendor / innkeeper / gossip, quest giver or ender of a DB
-- quest), and the NPC faction: friendly to the route side (the DB letter "H"/"A"/"AH") gives no XP,
-- unless the objective has a known count >= 2: several Forever mob families carry a wrong or
-- "neutral" friendlyToFaction in the DB (e.g. 1501 Mindless Zombie "AH", 259434 Tarnished Drudge
-- "H"), and a counted multi-target objective with the slay icon is a kill objective.
function Run:nonKillReason(e, npcId)
    if e.icon and e.icon ~= 0 and e.icon ~= 1 then
        return NON_KILL_ICON[e.icon] and (NON_KILL_ICON[e.icon] .. " objective") or ("objective icon " .. e.icon)
    end
    local n = self.db.npcs[npcId or 0]
    if not n then return "NPC not in the DB snapshot" end
    if n.flags and next(n.flags) then
        local f = {}
        for k in pairs(n.flags) do f[#f + 1] = k end
        table.sort(f)
        return "service NPC (" .. table.concat(f, ", ") .. ")"
    end
    if DB.IsQuestNpc(self.db, npcId) then return "quest giver" end
    local fac = n.faction or ""
    local friendly
    if self.letter then
        friendly = fac:find(self.letter, 1, true) ~= nil
    else
        friendly = fac == "AH"
    end
    if friendly and not (e.count and e.count >= 2) then
        return format("friendly NPC (faction '%s')", fac)
    end
    return nil
end

--- The NPC killed for a creature / killCredit objective, or nil and the reason it is no kill.
-- killCredit: the first of base, ids... that is a hostile creature with spawns (credit dummies
-- without spawns never count).
function Run:killTarget(e)
    if e.kind == "creature" then
        local why = self:nonKillReason(e, e.id)
        if why then return nil, why end
        return e.id
    end
    local firstWhy
    local cands = { e.id }
    for _, id in ipairs(e.ids or {}) do cands[#cands + 1] = id end
    for _, id in ipairs(cands) do
        local why = self:nonKillReason(e, id)
        if not why and not self.db.npcs[id].spawns then why = "credit NPC without spawns" end
        if not why then return id end
        firstWhy = firstWhy or why
    end
    return nil, firstWhy or "no credited NPC"
end

--- Kill count for an objective without a known count: 1 for a named / unique NPC (rank > 0,
-- or at most uniqueSpawnMax spawn points of an unthinned list), else defaultKillCount.
-- @return count, optimisticCount, unique
function Run:assumedKills(npcId)
    local opts = self.opts
    local n = self.db.npcs[npcId]
    local spawnMax = opts.uniqueSpawnMax or V.DEFAULTS.uniqueSpawnMax
    if n and ((n.rank or 0) > 0 or (not n.spawnsGrid and DB.SpawnCount(n) <= spawnMax)) then
        return 1, 1, true
    end
    local k = opts.defaultKillCount or V.DEFAULTS.defaultKillCount
    return k, math.ceil(k * (opts.guessedKillOptimism or V.DEFAULTS.guessedKillOptimism)), false
end

--- First drop source of an item that is a killable creature with spawns: not a service NPC or
-- quest giver, and not friendly to the route side only (an "AH" neutral beast is attackable).
function Run:dropSource(it)
    for _, m in ipairs(it and it.npcDrops or {}) do
        local n = self.db.npcs[m]
        if n and n.spawns and not (n.flags and next(n.flags)) and not DB.IsQuestNpc(self.db, m)
            and not (self.letter and n.faction == self.letter) then
            return m
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- position checks
---------------------------------------------------------------------------

--- Distance between two points of one uiMap: yards when the map's world size is known
-- (zones[uiMap].size), else map percent units.
-- @return distance, isYards
function Run:mapDistance(map, x1, y1, x2, y2)
    local z = self.db.zones[map]
    local size = z and z.size
    local dx, dy = x2 - x1, y2 - y1
    if size and size[1] and size[2] then
        dx, dy = dx * size[1] / 100, dy * size[2] / 100
        return math.sqrt(dx * dx + dy * dy), true
    end
    return math.sqrt(dx * dx + dy * dy), false
end

--- Nearest spawn on at.map measured with Run:mapDistance.
-- @return distance, isYards, x, y (nil when no spawn on that map)
function Run:nearestSpawn(spawns, at)
    local list = spawns and spawns[at.map]
    if not list or #list == 0 then return nil end
    local best, yards, bx, by
    for _, p in ipairs(list) do
        local d, isYd = self:mapDistance(at.map, at.x, at.y, p[1], p[2])
        if not best or d < best then best, yards, bx, by = d, isYd, p[1], p[2] end
    end
    return best, yards, bx, by
end

--- Severity of a distance: "ERROR" / "WARN" / nil, with its formatted text.
-- `slack` (map units) is subtracted for thinned spawn lists (spawnsGrid).
function Run:distanceSeverity(map, d, isYards, slackUnits)
    local slack = 0
    if slackUnits and slackUnits > 0 then
        if isYards then
            local size = self.db.zones[map].size
            slack = slackUnits * math.max(size[1], size[2]) / 100
        else
            slack = slackUnits
        end
    end
    local eff = math.max(0, d - slack)
    local text
    if isYards then
        text = format("%.0f yards", d)
    else
        text = format("%.1f map units (approximate: no world size known for uiMap %d)", d, map)
    end
    local warnAt = isYards and self.tolYd or self.tol
    local errAt = isYards and self.hardTolYd or self.hardTol
    if eff > errAt then return "ERROR", text end
    if eff > warnAt then return "WARN", text end
    return nil, text
end

-- @param fields the stable field of the entity: { npc = id } / { object = id }
function Run:checkDistance(step, ent, at, label, fields)
    local d, isYards, nx, ny = self:nearestSpawn(ent.spawns, at)
    if not d then
        local zone = self.db.zones[at.map]
        if ent.instance and #ent.instance > 0 and zone and zone.dungeon then
            self:addx("INFO", "at-instance", step, fields, "%s is inside an instance; position on uiMap %d not checkable",
                label, at.map)
            return
        end
        local maps = {}
        for _, m in ipairs(DB.SpawnMaps(ent.spawns)) do
            maps[#maps + 1] = format("%d %s", m, DB.ZoneName(self.db, m))
        end
        self:addx("ERROR", "at-no-spawn", step, fields, "%s has no spawn on uiMap %d (%s); spawns on: %s", label, at.map,
            DB.ZoneName(self.db, at.map), #maps > 0 and table.concat(maps, "; ") or "none known")
        return
    end
    local slack = ent.spawnsGrid and ent.spawnsGrid * math.sqrt(2) or nil
    local sev, text = self:distanceSeverity(at.map, d, isYards, slack)
    if sev then
        self:addx(sev, "at-far", step, fields, "%s is %s from at {%d, %.1f, %.1f} (nearest spawn %.2f, %.2f%s)",
            label, text, at.map, at.x, at.y, nx, ny, slack and "; spawn list thinned in the snapshot" or "")
    end
end

function Run:checkEntities(step)
    local db, at = self.db, step.at
    local mapOk = false
    if at then
        if db.zones[at.map] then
            mapOk = true
        else
            self:add("ERROR", "at-map-unknown", step, "uiMapID %d is not a known Forever map", at.map)
        end
    end
    for _, id in ipairs(step.npc or {}) do
        local n = db.npcs[id]
        if not n then
            local b = DB.NpcBrief(db, id)
            if b then
                self:addx("WARN", "npc-out-of-scope", step, { npc = id }, "NPC %s exists but is outside the DB snapshot scope "
                    .. "(zone area %s); position/flags not checked", self:nn(id), tostring(b.zone))
            else
                self:addx("ERROR", "npc-unknown", step, { npc = id }, "NPC %d does not exist in the Forever DB", id)
            end
        elseif mapOk then
            self:checkDistance(step, n, at, "NPC " .. self:nn(id), { npc = id })
        end
    end
    for _, id in ipairs(step.object or {}) do
        local o = db.objects[id]
        if not o then
            local b = DB.ObjectBrief(db, id)
            if b then
                self:addx("WARN", "object-out-of-scope", step, { object = id }, "object %s exists but is outside the DB snapshot scope; "
                    .. "position not checked", self:on(id))
            else
                self:addx("ERROR", "object-unknown", step, { object = id }, "object %d does not exist in the Forever DB", id)
            end
        elseif mapOk then
            self:checkDistance(step, o, at, "object " .. self:on(id), { object = id })
        end
    end
    -- accept / turnin without npc/object: 'at' should be near a quest giver/ender
    if mapOk and not step.npc and not step.object then
        for _, a in ipairs(step.actions) do
            if a.type == "accept" or a.type == "turnin" then
                local q = DB.Quest(db, a.quest, self.profile.class)
                local ends = q and (a.type == "accept" and q.start or q.finish)
                if ends and ((ends.npcs and #ends.npcs > 0) or (ends.objects and #ends.objects > 0)) then
                    local best, bestYd
                    for _, id in ipairs(ends.npcs or {}) do
                        local n = db.npcs[id]
                        local d, isYd = self:nearestSpawn(n and n.spawns, at)
                        if d and (not best or d < best) then best, bestYd = d, isYd end
                    end
                    for _, id in ipairs(ends.objects or {}) do
                        local o = db.objects[id]
                        local d, isYd = self:nearestSpawn(o and o.spawns, at)
                        if d and (not best or d < best) then best, bestYd = d, isYd end
                    end
                    local who = a.type == "accept" and "quest giver" or "quest ender"
                    if not best then
                        self:addx("WARN", "at-far-from-giver", step, { quest = a.quest }, "%s %s: no %s spawns on uiMap %d", a.type,
                            self:qn(a.quest), who, at.map)
                    else
                        local sev, text = self:distanceSeverity(at.map, best, bestYd)
                        if sev then
                            -- no npc/object on the step: the giver is a guess, never more than a WARN
                            self:addx("WARN", "at-far-from-giver", step, { quest = a.quest },
                                "%s %s: nearest %s is %s from at", a.type, self:qn(a.quest), who, text)
                        end
                    end
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- XP simulation
---------------------------------------------------------------------------

-- @param optAmount XP for the optimistic simulation (default = amount)
function Run:gainXp(amount, kind, optAmount)
    optAmount = optAmount or amount
    if optAmount > 0 then DB.AddXp(self.db, self.opt, optAmount) end
    if amount <= 0 then return end
    DB.AddXp(self.db, self.st, amount)
    self.xp[kind] = self.xp[kind] + amount
    if self.seg then
        local s = self.segments[#self.segments]
        s["xp" .. kind:sub(1, 1):upper() .. kind:sub(2)] = (s["xp" .. kind:sub(1, 1):upper() .. kind:sub(2)] or 0) + amount
    end
end

function Run:giveQuestXp(id, q, step)
    local base, estimated = q.xp, false
    if not base or base <= 0 then
        base = DB.EstimateQuestXp(self.db, q.level)
        estimated = true
        self.xp.unknownXpQuests = self.xp.unknownXpQuests + 1
        self:add("INFO", "xp-unknown", step, "turnin %s: quest XP unknown in the DB (Forever-new quest?); estimated "
            .. "%d (median of level-%d quests). Record the real value in game with /fb xp", self:qn(id), base,
            q.level or 0)
    end
    local gained = DB.QuestXp(self.db, base, q.level, self.st.level)
    local optBase = estimated and base * (self.opts.unknownXpOptimism or V.DEFAULTS.unknownXpOptimism) or base
    local optGained = DB.QuestXp(self.db, optBase, q.level, self.opt.level)
    if estimated then self.xp.questEstimated = self.xp.questEstimated + gained end
    self:gainXp(gained, "quest", optGained)
    -- --incidental-pct: kills on the way between the steps, as a share of the quest XP
    local pct = self.opts.incidentalPct or V.DEFAULTS.incidentalPct
    if pct > 0 then
        self:gainXp(floor(gained * pct / 100 + 0.5), "incidental", floor(optGained * pct / 100 + 0.5))
    end
end

-- @param optKills kills for the optimistic simulation (default = kills)
function Run:killXp(mobId, kills, optKills)
    local mob = self.db.npcs[mobId]
    if not mob then return 0, 0 end
    local lvl = floor(((mob.minLevel or 1) + (mob.maxLevel or mob.minLevel or 1)) / 2)
    if lvl < 1 then lvl = 1 end
    local total = 0
    optKills = optKills or kills
    for i = 1, math.max(kills, optKills) do
        local x = i <= kills and DB.MobXp(self.db, self.st.level, lvl, mob.rank or 0) or 0
        local xo = i <= optKills and DB.MobXp(self.db, self.opt.level, lvl, mob.rank or 0) or 0
        total = total + x
        self:gainXp(x, "kill", xo)
    end
    return total, lvl
end

--- Optimistic level (never below the nominal one).
function Run:optLevel()
    return math.max(self.opt.level, self.st.level)
end

---------------------------------------------------------------------------
-- action handlers
---------------------------------------------------------------------------

local H = {}

function H.abandon(self, a, step)
    local id = a.quest
    if not self.active[id] then
        self:add("ERROR", "abandon-not-active", step, "abandon %s: quest is not in the simulated quest log", self:qn(id))
        return
    end
    self.active[id] = nil
    self.activeCount = self.activeCount - 1
    self.abandoned[id] = step
end

function H.turnin(self, a, step)
    local id = a.quest
    local q, full = self:quest(id, step, "turnin")
    if not q then return end
    if full then self:checkProfession("turnin", id, q, step) end
    if self.turnedIn[id] then
        self:add("ERROR", "turnin-twice", step, "turnin %s: already turned in at %s", self:qn(id),
            self:stepRef(self.turnedIn[id]))
        return
    elseif not self.active[id] then
        if self.abandoned[id] then
            self:add("ERROR", "turnin-abandoned", step, "turnin %s: quest was abandoned at %s", self:qn(id),
                self:stepRef(self.abandoned[id]))
        else
            self:add("ERROR", "turnin-not-accepted", step, "turnin %s: quest was never accepted", self:qn(id))
        end
    elseif full and hasObjectives(q) and not self.completed[id] then
        self:add("WARN", "turnin-no-complete", step, "turnin %s: quest has objectives but no earlier 'complete' step",
            self:qn(id))
    elseif full and self.completed[id] then
        -- only some objectives completed ({ [id] = {1} }): which ones were never covered?
        local credited = self.credited[id] or {}
        local missing = {}
        for idx, e in ipairs(objectiveList(q)) do
            if not credited[idx] and not (e.kind == "item" and self.collected[e.id]) then
                missing[#missing + 1] = tostring(idx)
            end
        end
        if #missing > 0 then
            local done = {}
            for _, k in ipairs(sortedKeys(credited)) do done[#done + 1] = tostring(k) end
            self:add("WARN", "turnin-partial", step, "turnin %s: objective(s) %s never covered by a 'complete' step "
                .. "(only objectives %s were completed)", self:qn(id), table.concat(missing, ", "),
                #done > 0 and table.concat(done, ", ") or "none")
        end
    end
    if full then
        -- objective items: is there a complete/collect step that covers them?
        local credited = self.credited[id] or {}
        for idx, e in ipairs(objectiveList(q)) do
            if e.kind == "item" and not credited[idx] and not self.collected[e.id] then
                local it = self.db.items[e.id]
                self:add("INFO", "turnin-items", step, "turnin %s: objective item %d \"%s\" x%s was not collected "
                    .. "by an earlier complete/collect step", self:qn(id), e.id, it and it.name or "?",
                    tostring(e.count or "?"))
            end
        end
        local fin = q.finish or {}
        if step.npc then
            if fin.npcs and #fin.npcs > 0 then
                if not anyIn(step.npc, fin.npcs) then
                    self:add("ERROR", "turnin-wrong-npc", step, "turnin %s: step NPC %s does not accept this quest; "
                        .. "turned in to %s", self:qn(id), self:names(step.npc, Run.nn), self:names(fin.npcs, Run.nn))
                end
            elseif fin.objects and #fin.objects > 0 then
                self:add("ERROR", "turnin-wrong-npc", step, "turnin %s: quest is turned in at object %s, not NPC %s",
                    self:qn(id), self:names(fin.objects, Run.on), self:names(step.npc, Run.nn))
            else
                self:add("INFO", "turnin-no-ender-data", step, "turnin %s: the DB has no quest ender", self:qn(id))
            end
        end
        if step.object then
            if fin.objects and #fin.objects > 0 then
                if not anyIn(step.object, fin.objects) then
                    self:add("ERROR", "turnin-wrong-object", step, "turnin %s: object %s does not accept this quest; "
                        .. "turned in at %s", self:qn(id), self:names(step.object, Run.on), self:names(fin.objects, Run.on))
                end
            elseif fin.npcs and #fin.npcs > 0 and not step.npc then
                self:add("ERROR", "turnin-wrong-object", step, "turnin %s: quest is turned in to NPC %s, not object %s",
                    self:qn(id), self:names(fin.npcs, Run.nn), self:names(step.object, Run.on))
            end
        end
    end
    if self.active[id] then
        self.active[id] = nil
        self.activeCount = self.activeCount - 1
    end
    self.turnedIn[id] = step
    self.xp.turnins = self.xp.turnins + 1
    if self.seg then
        local s = self.segments[#self.segments]
        s.turnins = s.turnins + 1
    end
    self:giveQuestXp(id, q, step)
end

--- WARN db-override-unverified: a step passes a check only because of a DB override (tools/overrides)
-- that is not verified in game yet.
function Run:overrideWarn(step, ov, check, what)
    return self:addx("WARN", "db-override-unverified", step, { override = ov.file }, "%s: the %s check passes only "
        .. "because of the unverified DB override in tools/overrides/%s (source: %s): confirm it in game and set "
        .. "verified = true, or acknowledge it (ok = \"db-override-unverified\" with a -- CONFIRM: comment)", what, check,
        ov.file, tostring(ov.source))
end

-- side / race / class availability of a quest with these masks: nil when available, else the code
function Run:availabilityProblem(races, classes)
    if self.letter and not DB.Side(self.db, races):find(self.letter, 1, true) then return "quest-side" end
    if self.raceMask and races and races ~= 0 and not DB.HasBit(races, self.raceMask) then return "quest-race" end
    if self.classMask and classes and classes ~= 0 and not DB.HasBit(classes, self.classMask) then
        return "quest-class"
    end
    return nil
end

function Run:checkAvailability(id, q, step)
    local db = self.db
    if self.letter then
        local side = DB.Side(db, q.races)
        if not side:find(self.letter, 1, true) then
            self:add("ERROR", "quest-side", step, "accept %s: quest is %s-only (races %s); route faction is %s",
                self:qn(id), side == "A" and "Alliance" or (side == "H" and "Horde" or "nobody"),
                self:raceNames(q.races), self.profile.faction)
            return
        end
    end
    if self.raceMask and q.races and q.races ~= 0 and not DB.HasBit(q.races, self.raceMask) then
        self:add("ERROR", "quest-race", step, "accept %s: not available to race %s (requiredRaces: %s)", self:qn(id),
            self.profile.race, self:raceNames(q.races))
    end
    if self.classMask and q.classes and q.classes ~= 0 and not DB.HasBit(q.classes, self.classMask) then
        self:add("ERROR", "quest-class", step, "accept %s: not available to class %s (requiredClasses: %s)",
            self:qn(id), self.profile.class, self:classNames(q.classes))
    end
    -- available only because of an unverified override of the race / class mask?
    local ov = db._overrides and db._overrides.quests[id]
    if ov and not ov.verified and (ov.fields.races or ov.fields.classes)
        and not self:availabilityProblem(q.races, q.classes) then
        local before = self:availabilityProblem(ov.orig.races, ov.orig.classes)
        if before then
            self:overrideWarn(step, ov, before == "quest-class" and "class" or "race", "accept " .. self:qn(id))
        end
    end
end

--- quest-profession: a quest that needs a profession skill (DB reqSkill = {skillLine, value}) cannot
-- be taken by a character without it; its accept step must be `optional` (and so must its
-- complete / turnin steps), or the route stops there for most characters.
function Run:checkProfession(verb, id, q, step)
    local rs = q.reqSkill
    if type(rs) ~= "table" or not rs[1] then return end
    local skill = format("%s %d", DB.SkillName(self.db, rs[1]), rs[2] or 1)
    if verb == "accept" then
        if step.optional then
            self:add("INFO", "quest-profession", step, "accept %s: requires %s (profession); optional step",
                self:qn(id), skill)
        else
            self:add("WARN", "quest-profession", step, "accept %s: requires %s (profession): a character without it "
                .. "cannot take the quest and the guide stops at this step -- make it `optional` (with the quest's "
                .. "complete / turnin steps), filter it or drop the quest", self:qn(id), skill)
        end
    elseif not step.optional and not step.bg then
        local acc = self.accepted[id]
        if acc and not acc.isState and acc.optional then
            self:add("WARN", "quest-profession", step, "%s %s: the quest requires %s and its accept step %s is "
                .. "optional, this step is not: a character without the profession is stuck here (make it optional)",
                verb, self:qn(id), skill, self:stepRef(acc))
        end
    end
end

function H.accept(self, a, step)
    local id = a.quest
    local q, full = self:quest(id, step, "accept")
    if not q then return end
    self:checkAvailability(id, q, step)
    if full then self:checkProfession("accept", id, q, step) end
    if (q.reqLevel or 0) > self.st.level then
        if q.reqLevel > self:optLevel() then
            local hint = ""
            if self.xp.unknownXpQuests > 0 then
                hint = format(" (the simulation includes %d estimated quest XP values; if the real XP is higher, add "
                    .. "a 'level' step here - it completes instantly in game when reached)", self.xp.unknownXpQuests)
            end
            self:addx("ERROR", "level-too-low", step, { level = self:levelField() },
                "accept %s: requires level %d, simulated level is %s%s", self:qn(id), q.reqLevel, self:levelStr(), hint)
        else
            self:addx("WARN", "level-too-low-estimated", step, { level = self:levelField() },
                "accept %s: requires level %d, simulated level is %s (level %d is reachable only if the estimated XP "
                .. "is too low: unknown quest XP / assumed kill counts; consider a 'level' step)", self:qn(id),
                q.reqLevel, self:levelStr(), self:optLevel())
        end
    end
    if full and q.maxLevel and q.maxLevel > 0 and self.st.level > q.maxLevel then
        self:addx("ERROR", "level-too-high", step, { level = self:levelField() },
            "accept %s: maximum level %d, simulated level is %s", self:qn(id), q.maxLevel, self:levelStr())
    end
    if self.active[id] then
        self:add("ERROR", "accept-duplicate", step, "accept %s: already in the quest log (accepted at %s)", self:qn(id),
            self:stepRef(self.active[id].step))
        return
    end
    local repeatable = full and q.special and DB.HasBit(q.special, 1)
    if self.turnedIn[id] and not repeatable then
        self:add("ERROR", "accept-done", step, "accept %s: already turned in at %s", self:qn(id),
            self:stepRef(self.turnedIn[id]))
        return
    end
    if full then
        local missing = {}
        for _, p in ipairs(q.preGroup or {}) do
            if not self.turnedIn[p] then missing[#missing + 1] = p end
        end
        local prereqOk = #missing == 0
        if #missing > 0 then
            self:add("ERROR", "accept-prereq", step, "accept %s: requires ALL of these quests turned in first, missing: %s",
                self:qn(id), self:names(missing, Run.qn))
        end
        if q.preSingle and #q.preSingle > 0 then
            local ok = false
            for _, p in ipairs(q.preSingle) do
                if self.turnedIn[p] then ok = true break end
            end
            if not ok then
                prereqOk = false
                self:add("ERROR", "accept-prereq", step, "accept %s: requires ONE of these quests turned in first: %s",
                    self:qn(id), self:names(q.preSingle, Run.qn))
            end
        end
        -- DB overrides (tools/overrides): does the step pass only because of an unverified one?
        local ovs = self.db._overrides
        local ov = ovs and ovs.quests[id]
        if ov and not ov.verified and prereqOk and (ov.fields.preGroup or ov.fields.preSingle) then
            local before = true
            for _, p in ipairs(ov.orig.preGroup or {}) do
                if not self.turnedIn[p] then before = false end
            end
            if #(ov.orig.preSingle or {}) > 0 then
                local one = false
                for _, p in ipairs(ov.orig.preSingle) do
                    if self.turnedIn[p] then one = true end
                end
                if not one then before = false end
            end
            if not before then self:overrideWarn(step, ov, "prerequisite", "accept " .. self:qn(id)) end
        end
        for _, x in ipairs(sortedKeys(ovs and ovs.exclRemoved[id])) do
            local xov = ovs.exclRemoved[id][x]
            if not xov.verified and (self.active[x] or self.turnedIn[x]) then
                self:overrideWarn(step, xov, "exclusivity", format("accept %s (exclusive with %s in the snapshot)",
                    self:qn(id), self:qn(x)))
            end
        end
        -- exclusive groups are symmetric in game but often listed on one side only in the DB
        local excl, seenX = {}, {}
        for _, x in ipairs(q.exclusive or {}) do
            if not seenX[x] then seenX[x] = true; excl[#excl + 1] = x end
        end
        for _, x in ipairs(DB.ExclusiveOf(self.db, id)) do
            if not seenX[x] then seenX[x] = true; excl[#excl + 1] = x end
        end
        for _, x in ipairs(excl) do
            if self.active[x] or self.turnedIn[x] then
                self:add("ERROR", "accept-exclusive", step, "accept %s: exclusive with %s which was already %s",
                    self:qn(id), self:qn(x), self.active[x] and "accepted" or "turned in")
            end
        end
        -- availableUntilCompleted / disabledByQuest
        for _, u in ipairs(type(q.untilCompleted) == "table" and q.untilCompleted or { q.untilCompleted }) do
            if self.turnedIn[u] then
                self:add("ERROR", "accept-unavailable", step, "accept %s: no longer offered once %s is turned in "
                    .. "(turned in at %s)", self:qn(id), self:qn(u), self:stepRef(self.turnedIn[u]))
            end
        end
        for _, d in ipairs(type(q.disabledBy) == "table" and q.disabledBy or { q.disabledBy }) do
            if self.active[d] then
                self:add("ERROR", "accept-disabled", step, "accept %s: not offered while %s is in the quest log "
                    .. "(accepted at %s)", self:qn(id), self:qn(d), self:stepRef(self.active[d].step))
            end
        end
        if q.parent and not self.active[q.parent] then
            self:add("ERROR", "accept-parent", step, "accept %s: parent quest %s must be in the quest log", self:qn(id),
                self:qn(q.parent))
        end
        if q.breadcrumbFor and (self.active[q.breadcrumbFor] or self.turnedIn[q.breadcrumbFor]) then
            self:add("WARN", "breadcrumb-late", step, "accept %s: it is a breadcrumb for %s, which was already %s "
                .. "(the breadcrumb is usually no longer offered)", self:qn(id), self:qn(q.breadcrumbFor),
                self.active[q.breadcrumbFor] and "accepted" or "turned in")
        end
        for _, b in ipairs(q.breadcrumbs or {}) do
            if self.active[b] then
                self:add("WARN", "breadcrumb-open", step, "accept %s while its breadcrumb %s is still in the quest log "
                    .. "(turn the breadcrumb in first or it may become unavailable)", self:qn(id), self:qn(b))
            end
        end
        local st = q.start or {}
        if step.npc then
            if st.npcs and #st.npcs > 0 then
                if not anyIn(step.npc, st.npcs) then
                    self:add("ERROR", "accept-wrong-npc", step, "accept %s: step NPC %s does not offer this quest; "
                        .. "offered by %s", self:qn(id), self:names(step.npc, Run.nn), self:names(st.npcs, Run.nn))
                end
            elseif (st.objects and #st.objects > 0) or (st.items and #st.items > 0) then
                self:add("ERROR", "accept-wrong-npc", step, "accept %s: quest is started by %s, not by NPC %s", self:qn(id),
                    st.objects and ("object " .. self:names(st.objects, Run.on)) or ("item " .. table.concat(st.items, ",")),
                    self:names(step.npc, Run.nn))
            else
                self:add("INFO", "accept-no-starter-data", step, "accept %s: the DB has no quest starter", self:qn(id))
            end
        end
        if step.object then
            if st.objects and #st.objects > 0 then
                if not anyIn(step.object, st.objects) then
                    self:add("ERROR", "accept-wrong-object", step, "accept %s: object %s does not start this quest; "
                        .. "started at %s", self:qn(id), self:names(step.object, Run.on), self:names(st.objects, Run.on))
                end
            elseif st.npcs and #st.npcs > 0 and not step.npc then
                self:add("ERROR", "accept-wrong-object", step, "accept %s: quest is offered by NPC %s, not object %s",
                    self:qn(id), self:names(st.npcs, Run.nn), self:names(step.object, Run.on))
            end
        end
    end
    self.active[id] = { step = step }
    self.activeCount = self.activeCount + 1
    self.accepted[id] = step
    self.xp.accepts = self.xp.accepts + 1
    if self.seg then
        local s = self.segments[#self.segments]
        s.accepts = s.accepts + 1
    end
    local cap = self.db.questLogSize or 40
    if self.activeCount > cap then
        self:add("ERROR", "questlog-full", step, "accept %s: quest log would hold %d quests (Forever maximum %d)",
            self:qn(id), self.activeCount, cap)
    end
    if self.activeCount > self.maxLog then self.maxLog = self.activeCount end
end

--- complete-far-from-trigger: a quest completed by an area trigger (DB objectives.trigger: exploration,
-- "leap from the planks") is done only there; the `complete` step's `at` (where the arrow leads)
-- should be that place -- or an earlier step since the quest's accept leads there (a `go` step to the
-- trigger, then { complete = Q, turnin = Q } at the quest ender). WARN beyond the hard distance
-- tolerance (trigger areas have a radius). Escorts (DB objectives.escort) are skipped: they start at
-- the quest giver and end at the trigger on their own.
function Run:checkTrigger(id, q, step)
    local o = q.objectives or {}
    local trig = o.trigger
    local at = step.at
    if type(trig) ~= "table" or o.escort or not at or not self.db.zones[at.map] then return end
    local function near(p)
        if not p or not self.db.zones[p.map] then return false end
        local d, isYd = self:nearestSpawn(trig, p)
        return d ~= nil and d <= (isYd and self.hardTolYd or self.hardTol)
    end
    -- an earlier step since the accept (this profile's walk) already leads to the trigger
    local acc = self.accepted[id]
    for k = #self.walked, 1, -1 do
        local w = self.walked[k]
        if w ~= step and near(w.at) then return end
        if w == acc then break end
    end
    local d, isYards, tx, ty = self:nearestSpawn(trig, at)
    if not d then
        local maps = {}
        for _, m in ipairs(DB.SpawnMaps(trig)) do maps[#maps + 1] = format("%d %s", m, DB.ZoneName(self.db, m)) end
        self:add("WARN", "complete-far-from-trigger", step, "complete %s: the quest completes at an area trigger on %s, "
            .. "not on uiMap %d (%s)", self:qn(id), table.concat(maps, "; "), at.map, DB.ZoneName(self.db, at.map))
        return
    end
    local limit = isYards and self.hardTolYd or self.hardTol
    if d > limit then
        self:add("WARN", "complete-far-from-trigger", step, "complete %s: the quest completes at its area trigger "
            .. "{%d, %.2f, %.2f}, %s from at {%d, %.1f, %.1f} (the arrow leads to `at`: put it at the trigger)",
            self:qn(id), at.map, tx, ty, isYards and format("%.0f yards", d) or format("%.1f map units", d),
            at.map, at.x, at.y)
    end
end

function H.complete(self, a, step)
    local id = a.quest
    local q, full = self:quest(id, step, "complete")
    if not q then return end
    if not self.active[id] then
        if self.turnedIn[id] then
            self:add("ERROR", "complete-not-active", step, "complete %s: quest was already turned in at %s", self:qn(id),
                self:stepRef(self.turnedIn[id]))
        else
            self:add("ERROR", "complete-not-active", step, "complete %s: quest is not in the simulated quest log",
                self:qn(id))
        end
        return
    end
    self.completed[id] = self.completed[id] or step
    if not full then return end
    self:checkProfession("complete", id, q, step)
    if not a.objectives then self:checkTrigger(id, q, step) end
    local list = objectiveList(q)
    local selected = {}
    if a.objectives then
        for _, idx in ipairs(a.objectives) do
            if list[idx] then
                selected[#selected + 1] = idx
            else
                self:add("WARN", "complete-bad-index", step, "complete %s: objective index %d does not exist "
                    .. "(the DB lists %d objectives)", self:qn(id), idx, #list)
            end
        end
    else
        for i = 1, #list do selected[i] = i end
        if #list == 0 and not hasObjectives(q) then
            self:add("INFO", "complete-no-objectives", step, "complete %s: the DB lists no objectives", self:qn(id))
        end
    end
    local credited = self.credited[id] or {}
    self.credited[id] = credited
    local opts = self.opts
    local killsTotal, xpTotal, guessed = 0, 0, false
    local nonKill = {}
    for _, idx in ipairs(selected) do
        local e = list[idx]
        if not credited[idx] then
            credited[idx] = true
            if e.kind == "creature" or e.kind == "killCredit" then
                local mob, why = self:killTarget(e)
                if mob then
                    local n, nOpt = e.count, e.count
                    if not n then
                        n, nOpt = self:assumedKills(mob)
                        guessed = true
                    end
                    local x = self:killXp(mob, n, nOpt)
                    killsTotal, xpTotal = killsTotal + n, xpTotal + x
                else
                    nonKill[#nonKill + 1] = format("%d %s: %s", idx, self:nn(e.id or 0), why)
                end
            elseif e.kind == "item" then
                self.collected[e.id] = true
                local it = self.db.items[e.id]
                local mob = self:dropSource(it)
                if mob then
                    local n = e.count or 1
                    if not e.count then guessed = true end
                    local kills = math.ceil(n * (opts.dropKillFactor or V.DEFAULTS.dropKillFactor))
                    local killsOpt = e.count and kills
                        or math.ceil(kills * (opts.guessedKillOptimism or V.DEFAULTS.guessedKillOptimism))
                    local x = self:killXp(mob, kills, killsOpt)
                    killsTotal, xpTotal = killsTotal + kills, xpTotal + x
                end
            end
        end
    end
    if #nonKill > 0 then
        self:add("INFO", "complete-no-kill", step, "complete %s: no kill XP for objective %s", self:qn(id),
            table.concat(nonKill, "; "))
    end
    if killsTotal > 0 then
        self:addx("INFO", "complete-kill-xp", step, { kills = killsTotal, level = self:levelField() },
            "complete %s: ~%d kills, +%d kill XP (estimate%s); level now %s",
            self:qn(id), killsTotal, xpTotal, guessed and ", objective counts partly assumed" or "", self:levelStr())
    end
end

function H.collect(self, a, step)
    if not self.db.items[a.item] then
        self:add("INFO", "collect-unknown-item", step, "collect: item %d is not in the DB snapshot (only quest-related "
            .. "items are included)", a.item)
    end
    self.collected[a.item] = true
end

function H.level(self, a, step)
    local db = self.db
    local target = DB.CumXp(db, a.level) + floor((a.frac or 0) * DB.XpToLevel(db, a.level))
    local optCur = DB.CumXp(db, self.opt.level) + self.opt.xp
    if optCur < target then DB.AddXp(db, self.opt, target - optCur) end
    local cur = DB.CumXp(db, self.st.level) + self.st.xp
    -- every level step is a gate of the grind report (V.RunProfile compares the runs per gate)
    local gate = { segment = step.segment, step = step.segIndex, stepId = step.id, level = a.level, frac = a.frac or 0,
                   from = round2(DB.LevelValue(db, self.st)), kills = 0, xp = 0 }
    if type(step.library) == "string" then gate.library = step.library end
    if step.inserted then gate.inserted = true end
    -- the kill ceiling of the step's acknowledgement (ok = { ["level-grind"] = N }), for the gate matrix
    if step.ok and type(step.ok["level-grind"]) == "number" then gate.okCeiling = step.ok["level-grind"] end
    if step.optional then gate.optional = true end -- not done in the worst case
    self.gates[#self.gates + 1] = gate
    self.gateSteps[#self.gates] = step
    self.gateByStep[step] = gate
    if cur >= target then return end
    local before, beforeValue = self:levelStr(), self:levelField()
    local kills, gained = 0, 0
    while cur < target and kills < 100000 do
        local x = DB.MobXp(db, self.st.level, self.st.level, 0)
        if x <= 0 then break end
        DB.AddXp(db, self.st, x)
        self.xp.grind = self.xp.grind + x
        gained = gained + x
        kills = kills + 1
        cur = DB.CumXp(db, self.st.level) + self.st.xp
    end
    self.xp.grindKills = self.xp.grindKills + kills
    gate.kills, gate.xp = kills, gained
    if self.seg then
        local s = self.segments[#self.segments]
        s.xpGrind = (s.xpGrind or 0) + gained
        s.grindKills = (s.grindKills or 0) + kills
    end
    local warnAt = self.opts.grindWarnKills or V.DEFAULTS.grindWarnKills
    self:addx(kills > warnAt and "WARN" or "INFO", "level-grind", step, { kills = kills, level = beforeValue },
        "level %d%s: simulated level %s is short by %d XP; ~%d same-level kills needed (estimate)", a.level,
        (a.frac or 0) > 0 and format(" +%d%%", floor(a.frac * 100 + 0.5)) or "", before, gained, kills)
end

function Run:serviceNpcs(step, what)
    local out = {}
    for _, id in ipairs(step.npc or {}) do
        local n = self.db.npcs[id]
        if n then
            if not self:friendly(n) then
                self:addx("ERROR", "npc-hostile", step, { npc = id }, "%s NPC %s is not friendly to the %s (faction '%s')",
                    what, self:nn(id), self.profile.faction or "?", n.faction or "")
            end
            out[#out + 1] = { id = id, npc = n }
        end
    end
    return out
end

-- Trainers that are not class trainers but are a legitimate `train` stop: sub-name fragment, the
-- class that may use it (true: any class) and what it is. Demon trainers are vendors (`vendor`).
local SERVICE_TRAINERS = {
    { "weapon master", true, "weapon master" },
    { "riding", true, "riding trainer" },
    { "pet trainer", "HUNTER", "pet trainer" },
    { "portal trainer", "MAGE", "portal trainer" },
}

--- The verdict of a `train` step at an NPC with this sub name and these flags for a class token
-- (nil: a route without classes): "ok" (class trainer), "service" + kind (weapon master / riding /
-- pet trainer of a HUNTER / portal trainer of a MAGE: accepted, INFO train-service), "warn" (a trainer,
-- but of no class: profession...), "error" (not a trainer of the class).
function V.TrainVerdict(classToken, subName, flags)
    local sub = (subName or ""):lower()
    flags = flags or {}
    local cls = classToken and CLASS_NAMES[classToken]
    if not cls then return flags.trainer and "ok" or "error" end
    local c = cls:lower()
    if sub:find(c .. " trainer", 1, true) or (flags.trainer and sub:find(c, 1, true)) then return "ok" end
    if flags.trainer then
        for _, k in ipairs(SERVICE_TRAINERS) do
            if sub:find(k[1], 1, true) and (k[2] == true or k[2] == classToken) then return "service", k[3] end
        end
    end
    local otherClass = false
    for _, name in pairs(CLASS_NAMES) do
        if sub:find(name:lower(), 1, true) then otherClass = true end
    end
    if flags.trainer and sub:find("trainer", 1, true) and not otherClass then return "warn" end
    return "error"
end

function H.train(self, _, step)
    if not step.npc then
        self:add("WARN", "train-no-npc", step, "train step without npc (trainer cannot be checked)")
        return
    end
    local token = self.profile.class
    local cls = token and CLASS_NAMES[token]
    for _, e in ipairs(self:serviceNpcs(step, "trainer")) do
        local n = e.npc
        local verdict, kind = V.TrainVerdict(cls and token or nil, n.sub, n.flags)
        local fields = { npc = e.id }
        if verdict == "service" then
            self:addx("INFO", "train-service", step, fields, "train: NPC %s (\"%s\") is a %s, not a %s trainer: accepted "
                .. "(what it teaches is not checked)", self:nn(e.id), n.sub or "", kind, cls)
        elseif verdict == "warn" then
            self:addx("WARN", "train-not-class-trainer", step, fields, "train: NPC %s is a trainer (\"%s\") but not a "
                .. "%s trainer (profession/riding trainer?)", self:nn(e.id), n.sub or "", cls)
        elseif verdict == "error" and cls then
            self:addx("ERROR", "train-wrong-trainer", step, fields, "train: NPC %s (\"%s\") is not a %s trainer",
                self:nn(e.id), n.sub or "", cls)
        elseif verdict == "error" then
            self:addx("ERROR", "train-wrong-trainer", step, fields, "train: NPC %s is not a trainer", self:nn(e.id))
        end
        -- accepted only because of an unverified DB override of the NPC's sub name?
        local ov = self.db._overrides and self.db._overrides.npcs[e.id]
        if ov and not ov.verified and (verdict == "ok" or verdict == "service") then
            local before = V.TrainVerdict(cls and token or nil, ov.orig.sub, n.flags)
            if before ~= "ok" and before ~= "service" then self:overrideWarn(step, ov, "train", "NPC " .. self:nn(e.id)) end
        end
    end
end

local function flightCheck(self, a, step)
    if a.type == "fp" then
        self.flightPaths[a.place] = true
    elseif not self.flightPaths[a.place] then
        if self.worst and self.optFp[a.place] and not step.bg then
            self:add("ERROR", "optional-dependency", step, "required step depends on an optional step: fly %s needs "
                .. "the flight point, but it is learned only at optional step %s (worst case: optional steps not "
                .. "done; make the fp step required or this step optional)", a.place, self:stepRef(self.optFp[a.place]))
        end
        self:add("WARN", "fly-unknown-fp", step, "fly %s: flight point %s was not learned before (no earlier fp "
            .. "step%s): a flight there is not offered", a.place, a.place,
            self.opts.startState and ", not in the start state's flightPaths" or "")
    end
    if not step.npc then
        if a.type == "fp" then
            self:add("INFO", "fp-no-npc", step, "fp %s: no flight master npc on the step", a.place)
        end
        return
    end
    for _, e in ipairs(self:serviceNpcs(step, "flight master")) do
        if not (e.npc.flags and e.npc.flags.flightmaster) then
            self:addx("ERROR", "not-flightmaster", step, { npc = e.id }, "%s %s: NPC %s is not a flight master", a.type,
                a.place, self:nn(e.id))
        end
    end
end
H.fp = flightCheck
H.fly = flightCheck

function H.sethearth(self, a, step)
    if not step.npc then
        self:add("WARN", "sethearth-no-npc", step, "sethearth %s: no innkeeper npc on the step", a.place)
    end
    for _, e in ipairs(self:serviceNpcs(step, "innkeeper")) do
        if not (e.npc.flags and e.npc.flags.innkeeper) then
            self:addx("ERROR", "not-innkeeper", step, { npc = e.id }, "sethearth %s: NPC %s is not an innkeeper", a.place,
                self:nn(e.id))
        end
    end
    self.hearth = a.place
    self.hearthAt = step.at
    self.optHearth = {} -- a required bind: earlier optional binds no longer matter
end

function H.hearth(self, a, step)
    if self.worst and self.hearth ~= a.place and self.optHearth[a.place] and not step.bg then
        self:add("ERROR", "optional-dependency", step, "required step depends on an optional step: hearth %s needs "
            .. "the hearthstone bound there, but only optional step %s binds it (worst case: optional steps not "
            .. "done; the hearthstone is bound to %s then; make the sethearth step required or this step optional)",
            a.place, self:stepRef(self.optHearth[a.place]), tostring(self.hearth or "the default bind point"))
    end
    if not self.hearth then
        self:add("INFO", "hearth-unbound", step, "hearth %s: no earlier sethearth step (default bind point assumed)",
            a.place)
    elseif self.hearth ~= a.place then
        self:add("WARN", "hearth-mismatch", step, "hearth %s: hearthstone is bound to %s (last sethearth)", a.place,
            self.hearth)
    end
end

function H.vendor(self, _, step)
    for _, e in ipairs(self:serviceNpcs(step, "vendor")) do
        local f = e.npc.flags or {}
        if not (f.vendor or f.repair) then
            self:addx("WARN", "not-vendor", step, { npc = e.id }, "vendor: NPC %s is not a vendor", self:nn(e.id))
        end
    end
end

---------------------------------------------------------------------------
-- route walk
---------------------------------------------------------------------------

function Run:beginSegment(seg)
    self.seg = seg
    self.segments[#self.segments + 1] = {
        id = seg.id, title = seg.title, file = seg.file, levels = seg.levels,
        startLevel = round2(DB.LevelValue(self.db, self.st)), accepts = 0, turnins = 0,
        xpQuest = 0, xpKill = 0, xpGrind = 0, grindKills = 0, skipped = 0, steps = #seg.steps,
        library = type(seg.library) == "string" and seg.library or nil, -- a shared segment
    }
end

function Run:endSegment(seg)
    local s = self.segments[#self.segments]
    local lv = DB.LevelValue(self.db, self.st)
    s.endLevel = round2(lv)
    s.questLog = self.activeCount
    if seg.levels then
        local planned = seg.levels[2]
        if math.abs(lv - planned) > 1 then
            self:addx("WARN", "segment-level", nil, { level = round2(lv) },
                "segment %s ends at simulated level %.2f; planned end level %d", tostring(seg.id), lv, planned)
        end
    end
    self.seg = nil
end

local QUEST_PHASE = { abandon = 1, complete = 2, collect = 2, turnin = 3, accept = 4 }

--- The actions of a step in the order the player does them at one stop:
-- abandon; objectives / items of quests already in the log; turn-ins; accepts; then the
-- objectives and the turn-in of quests accepted by this very step; then the rest in
-- Schema.ACTION_ORDER. So {accept=Q, turnin=Q}, {accept=Q, complete=Q} and
-- {complete=Q, turnin=Q} are all handled like in game.
function V.OrderedActions(step)
    local acceptedHere = {}
    for _, a in ipairs(step.actions) do
        if a.type == "accept" then acceptedHere[a.quest] = true end
    end
    local keyed = {}
    for i, a in ipairs(step.actions) do
        local phase = QUEST_PHASE[a.type] or 7
        if acceptedHere[a.quest] and (a.type == "complete" or a.type == "collect") then phase = 5 end
        if acceptedHere[a.quest] and a.type == "turnin" then phase = 6 end
        keyed[i] = { phase = phase, index = i, action = a }
    end
    table.sort(keyed, function(x, y)
        if x.phase ~= y.phase then return x.phase < y.phase end
        return x.index < y.index
    end)
    local out = {}
    for i, k in ipairs(keyed) do out[i] = k.action end
    return out
end

---------------------------------------------------------------------------
-- worst case (opts.worstCase, a shadow run of V.RunProfile): optional steps are not done
---------------------------------------------------------------------------

--- An optional step skipped in the worst case: its quests are not taken / not turned in.
function Run:skipOptional(step)
    self.optSkipped = self.optSkipped + 1
    if self.seg then
        local s = self.segments[#self.segments]
        s.optionalSkipped = (s.optionalSkipped or 0) + 1
    end
    for _, a in ipairs(step.actions) do
        local q = a.quest
        if a.type == "accept" and not self.active[q] and not self.turnedIn[q] and not self.optQuest[q] then
            self.optQuest[q] = step
            self.optAccepts = self.optAccepts + 1
        elseif a.type == "turnin" and not self.turnedIn[q] and not self.optTurnin[q] then
            self.optTurnin[q] = step
        elseif a.type == "fp" and not self.flightPaths[a.place] and not self.optFp[a.place] then
            self.optFp[a.place] = step -- the flight point is learned only here so far
        elseif a.type == "sethearth" then
            self.optHearth[a.place] = step -- the hearthstone is bound there only here so far
        end
    end
end

--- Worst case, a required step: does it need a quest that only optional steps take or turn in?
-- complete / turnin / abandon of a quest accepted only on a skipped optional step are not done (no XP);
-- on a non-bg step (the cursor would wait there for a quest the player does not have) and for an
-- accept whose prerequisite is turned in only on an optional step: ERROR optional-dependency.
-- @return true when the action is skipped
function Run:worstSkip(a, step)
    local q, t = a.quest, a.type
    if not q then return false end
    if (t == "complete" or t == "turnin" or t == "abandon") and not self.active[q] and self.optQuest[q] then
        if t ~= "abandon" and not step.bg then
            self:add("ERROR", "optional-dependency", step, "required step depends on optional quest %s: %s needs it "
                .. "in the quest log, but it is accepted only at optional step %s (worst case: optional steps not "
                .. "done; make this step optional too, or the accept required)", self:qn(q), t,
                self:stepRef(self.optQuest[q]))
        end
        return true
    end
    if t == "accept" and not step.bg then
        local rec = DB.Quest(self.db, q, self.profile.class)
        if not rec then return false end
        local function optionalSource(p)
            if self.turnedIn[p] then return nil end
            return self.optTurnin[p] or self.optQuest[p]
        end
        local reported = false
        for _, p in ipairs(rec.preGroup or {}) do
            local src = optionalSource(p)
            if src then
                reported = true
                self:add("ERROR", "optional-dependency", step, "required step depends on optional quest %s: accept "
                    .. "%s needs it turned in, but only optional step %s does that (worst case: optional steps not "
                    .. "done)", self:qn(p), self:qn(q), self:stepRef(src))
            end
        end
        if not reported and rec.preSingle and #rec.preSingle > 0 then
            local any, src, srcQ = false, nil, nil
            for _, p in ipairs(rec.preSingle) do
                if self.turnedIn[p] then any = true break end
                if not src then src, srcQ = optionalSource(p), p end
            end
            if not any and src then
                self:add("ERROR", "optional-dependency", step, "required step depends on optional quest %s: accept "
                    .. "%s needs one of %s turned in, but only optional step %s does that (worst case: optional steps "
                    .. "not done)", self:qn(srcQ), self:qn(q), self:names(rec.preSingle, Run.qn), self:stepRef(src))
            end
        end
    end
    return false
end

--- Stable sort of the messages by step ordinal (messages added after the walk about a step).
function Run:sortMessages()
    local keyed = {}
    for i, m in ipairs(self.messages) do keyed[i] = { m = m, i = i, o = self.msgOrd[m] or self.ordinal } end
    table.sort(keyed, function(x, y)
        if x.o ~= y.o then return x.o < y.o end
        return x.i < y.i
    end)
    for i, k in ipairs(keyed) do self.messages[i] = k.m end
end

function Run:processStep(step)
    self.ordinal = self.ordinal + 1
    self.levelBefore[step] = DB.LevelValue(self.db, self.st)
    -- --until: the state BEFORE this step / the first step of this segment (also when filtered out)
    local u = self.opts.untilId
    if u and not self.untilState and (step.id == u or step.segment == u) then
        self.untilState = self:EndState()
        self.untilState.meta.untilStep = tostring(step.id)
    end
    if not self.schema.FiltersMatch(step.filters, self.facts) then
        self:add("INFO", "step-skipped", step, "step filtered out for %s (class/race/faction filter)",
            profileLabel(self.profile))
        if self.seg then
            local s = self.segments[#self.segments]
            s.skipped = s.skipped + 1
        end
        return
    end
    if self.worst and step.optional then
        self:skipOptional(step)
        return
    end
    self.walked[#self.walked + 1] = step
    self.walkedOrd[#self.walked] = self.ordinal
    -- shadow runs only simulate (their position messages would be dropped anyway)
    if not self.opts.shadow then self:checkEntities(step) end
    for _, a in ipairs(V.OrderedActions(step)) do
        local h = H[a.type]
        self.curQuest = a.quest
        if h and not (self.worst and self:worstSkip(a, step)) then h(self, a, step) end
    end
    self.curQuest = nil
    if step.at then self.lastAt = step.at end
end

---------------------------------------------------------------------------
-- skip-ahead: steps the engine's fast-forward can pass over (Core/Engine.lua)
---------------------------------------------------------------------------

-- "h-22-hillsbrad#45 id=h-22-gate" (the id only when it is not the default "<segment>:<n>")
local function stepLabel(step)
    local ref = format("%s#%d", tostring(step.segment), step.segIndex or 0)
    if step.id and step.id ~= format("%s:%d", tostring(step.segment), step.segIndex or 0) then
        ref = ref .. " id=" .. tostring(step.id)
    end
    return ref
end

-- "fly Orgrimmar, train" (short action list of a step for messages)
local function stepActions(step)
    local out = {}
    for _, a in ipairs(step.actions or {}) do
        local v = a.quest or a.place or a.item or (a.type == "level" and a.level) or nil
        out[#out + 1] = v and format("%s %s", a.type, tostring(v)) or a.type
    end
    return table.concat(out, ", ")
end
V.StepActions = stepActions

--- WARN skip-ahead. The engine's forward anchor is the last non-bg step with accept/turnin/complete
-- whose stateful actions are all done; every transient action and every `optional` step before it
-- then counts as done. A non-bg step whose accept / complete can be finished EARLY -- by an earlier
-- bg step (a bg `complete` covering its objectives, a bg `accept` / `turnin` of its quest), by an
-- earlier step completing the same objectives, or by the start state (quest in "complete") --
-- becomes that anchor as soon as the earlier goal is done, and the travel / transient / optional
-- non-bg steps between the two are fast-forwarded although the player never did them (its
-- turnin / abandon actions, read from the game, keep a step from being early). Reported once per
-- such step, at that step (`-- WARN-OK: reason` goes there).
function Run:checkSkipAhead()
    local steps = self.walked
    local cover = {}     -- quest -> { [objective index] = { index, step } } (first early source)
    local acceptSrc = {} -- quest -> { index, step }: bg accept / turnin
    local acceptAt = {}  -- quest -> index of its last accept so far (0: in the start state's log)
    local nObj = {}
    local function objectiveCount(q)
        if nObj[q] == nil then
            local rec = DB.Quest(self.db, q, self.profile.class)
            nObj[q] = rec and #objectiveList(rec) or 0
        end
        return nObj[q]
    end
    local function wanted(a)
        if a.objectives and #a.objectives > 0 then return a.objectives end
        local out = {}
        for k = 1, math.max(objectiveCount(a.quest), 1) do out[k] = k end
        return out
    end
    local function coverAll(q, src)
        cover[q] = cover[q] or {}
        for k = 1, math.max(objectiveCount(q), 1) do
            if not cover[q][k] then cover[q][k] = src end
        end
    end
    local state = self.opts.startState
    for _, q in ipairs(state and state.log or {}) do acceptAt[q] = 0 end
    for _, q in ipairs(state and state.complete or {}) do coverAll(q, { index = 0 }) end
    local reported = {}
    for i, s in ipairs(steps) do
        if not s.bg then
            local early, src, quest = -1, nil, nil
            local anchor, ok = false, true
            for _, a in ipairs(s.actions) do
                local t = a.type
                if t == "complete" then
                    anchor = true
                    local cov = cover[a.quest]
                    for _, k in ipairs(wanted(a)) do
                        local c = cov and cov[k]
                        if not c then ok = false break end
                        if c.index > early then early, src, quest = c.index, c, a.quest end
                    end
                    -- the bg goal counts only once the quest is in the log
                    local acc = acceptAt[a.quest]
                    if ok and acc and acc > early then early = acc end
                elseif t == "accept" then
                    anchor = true
                    local c = acceptSrc[a.quest]
                    if not c then ok = false
                    elseif c.index > early then early, src, quest = c.index, c, a.quest end
                elseif t == "turnin" or t == "abandon" then
                    ok = false -- read from the game, not finished by a bg goal
                end
                -- collect / level may be done early anyway; transient actions are no anchor evidence
                if not ok then break end
            end
            if ok and anchor and src then
                for j = early + 1, i - 1 do
                    local v = steps[j]
                    if not v.bg and (v.transient or v.optional) and not reported[v] then
                        reported[v] = true
                        local how
                        if src.step then
                            how = format("as soon as %sstep %s [%s] is done", src.step.bg and "bg " or "earlier ",
                                stepLabel(src.step), stepActions(src.step))
                        else
                            how = format("from the start (quest %s is complete in the start state)", self:qn(quest))
                        end
                        local m = self:add("WARN", "skip-ahead", v, "%s step [%s] can be fast-forwarded: the later step %s [%s] "
                            .. "is done %s, becomes the forward anchor, and the guide then counts the travel / "
                            .. "transient / optional steps before it as done (move this step before the bg goal or "
                            .. "after the later step, or drop the overlap)", v.optional and "optional" or "transient",
                            stepActions(v), stepLabel(s), stepActions(s), how)
                        if m then self.msgOrd[m] = self.walkedOrd[j] end
                    end
                end
            end
        end
        -- this step as an early source for the later ones
        for _, a in ipairs(s.actions) do
            local q = a.quest
            if a.type == "accept" then
                acceptAt[q] = i
                if s.bg and not acceptSrc[q] then acceptSrc[q] = { index = i, step = s } end
            elseif a.type == "complete" then
                -- a bg goal -- or an earlier step completing the same objectives (the later one is then
                -- done the moment the earlier one is: same effect)
                cover[q] = cover[q] or {}
                for _, k in ipairs(wanted(a)) do
                    if not cover[q][k] then cover[q][k] = { index = i, step = s } end
                end
            elseif s.bg and a.type == "turnin" then
                coverAll(q, { index = i, step = s })
                if not acceptSrc[q] then acceptSrc[q] = { index = i, step = s } end
            end
        end
    end
end

--- WARN lookahead-skip. Talking to an NPC opens its gossip first: the core's automation accepts the
-- route quests of the steps [cursor, cursor + lookahead] the NPC offers and turns in the route quests
-- it takes (Core/Automation.lua). When the current step is a trainer / merchant / taxi / innkeeper
-- visit (train / vendor / fp / sethearth) at that NPC and a later step within the lookahead is
-- nothing but accepts / turn-ins at the same NPC, that later step is done before the window opens,
-- becomes the forward anchor, and the visit counts as done (fast-forwarded): the cursor jumps past
-- the training / purchase. Merge the visit into the quest step (one step, all actions) or put it
-- after. A turn-in counts only when the quest is complete by then (no `complete` step in between).
-- Reported at the visit step (`-- WARN-OK: reason` goes there).
local WINDOW_ACTIONS = { train = "trainer", vendor = "merchant", fp = "flight master", sethearth = "innkeeper" }

function Run:checkLookaheadSkip()
    local steps = self.walked
    local look = self.opts.lookahead or V.DEFAULTS.lookahead
    for j, v in ipairs(steps) do
        local kinds = {}
        local stateful = false
        for _, a in ipairs(v.actions) do
            if WINDOW_ACTIONS[a.type] then kinds[#kinds + 1] = a.type
            elseif self.schema.STATEFUL[a.type] and a.type ~= "level" then stateful = true end
        end
        if #kinds > 0 and not stateful and not v.bg and not v.optional and v.npc and #v.npc > 0 then
            for i = j + 1, math.min(#steps, j + look) do
                local s = steps[i]
                if not s.bg then
                    local hit, other = nil, false
                    for _, a in ipairs(s.actions) do
                        local t = a.type
                        if t == "accept" or t == "turnin" then
                            local q = DB.Quest(self.db, a.quest, self.profile.class)
                            local who = q and (t == "accept" and q.start or q.finish)
                            local same = who and who.npcs and anyIn(v.npc, who.npcs)
                            if same and t == "turnin" then
                                -- not in the log or not complete yet when the visit happens: no auto turn-in then
                                for k = j + 1, i - 1 do
                                    if hasQuestActionV(steps[k], "complete", a.quest)
                                        or hasQuestActionV(steps[k], "accept", a.quest) then same = false break end
                                end
                            elseif same then
                                -- not offered yet at the visit: a prerequisite is turned in between
                                local pre = {}
                                for _, p in ipairs(q.preGroup or {}) do pre[p] = true end
                                for _, p in ipairs(q.preSingle or {}) do pre[p] = true end
                                for k = j + 1, i - 1 do
                                    for _, b in ipairs(steps[k].actions) do
                                        if b.type == "turnin" and pre[b.quest] then same = false end
                                    end
                                end
                            end
                            if same then hit = hit or a else other = true end
                        elseif self.schema.STATEFUL[t] and t ~= "level" then
                            other = true
                        end
                    end
                    if hit and not other then
                        local m = self:add("WARN", "lookahead-skip", v, "%s step [%s] at NPC %s can be fast-forwarded: "
                            .. "talking to the NPC opens its gossip first, the automation %s %s there (step %s [%s], "
                            .. "%d step(s) later, within the lookahead of %d), that step becomes the forward anchor "
                            .. "and the guide counts this %s visit as done before the window opens (merge the actions "
                            .. "into one step or put this step after it)", table.concat(kinds, ", "), stepActions(v),
                            self:names(v.npc, Run.nn), hit.type == "accept" and "accepts" or "turns in",
                            self:qn(hit.quest), stepLabel(s), stepActions(s), i - j, look,
                            WINDOW_ACTIONS[kinds[1]])
                        if m then self.msgOrd[m] = self.walkedOrd[j] end
                        break
                    end
                end
            end
        end
    end
end

function Run:execute()
    local route = self.route
    if #route.steps == 0 then
        self:add("ERROR", "route-empty", nil, "route %s has no steps", tostring(route.id))
    end
    for _, seg in ipairs(route.segments) do
        self:beginSegment(seg)
        for _, step in ipairs(seg.steps) do
            self:processStep(step)
        end
        self:endSegment(seg)
    end
    self.ordinal = self.ordinal + 1 -- messages about the whole run come after every step message
    if not self.opts.shadow then
        local before = #self.messages
        self:checkSkipAhead()
        self:checkLookaheadSkip()
        if #self.messages > before then self:sortMessages() end
    end
    for _, id in ipairs(sortedKeys(self.active)) do
        if route.harness then
            -- a part of a library: quests carried into the next segments are expected (end state "log")
            self:addx("INFO", "quest-carried", self.active[id].step, { quest = id }, "quest %s is carried out of the harness run "
                .. "(still in the quest log: --write-state keeps it in \"log\")", self:qn(id))
        else
            self:addx("WARN", "quest-carried", self.active[id].step, { quest = id }, "quest %s is still in the quest log at the end of "
                .. "the route (never turned in or abandoned)", self:qn(id))
        end
    end
    local lv = DB.LevelValue(self.db, self.st)
    if route.levels and math.abs(lv - route.levels[2]) > 1 then
        self:addx("WARN", "route-level", nil, { level = round2(lv) },
            "route ends at simulated level %.2f; planned end level %d", lv, route.levels[2])
    end
    return self:result()
end

function Run:result()
    local carried = sortedKeys(self.active)
    return {
        route = self.route.id,
        title = self.route.title,
        file = self.route.file,
        module = self.route.module,
        profile = self.profile,
        profileLabel = profileLabel(self.profile),
        messages = self.messages,
        counts = self.counts,
        suppressed = self.suppressed,
        acceptedWarn = self.acceptedWarn,
        segments = self.segments,
        summary = {
            endLevel = round2(DB.LevelValue(self.db, self.st)),
            endLevelOptimistic = round2(math.max(DB.LevelValue(self.db, self.opt), DB.LevelValue(self.db, self.st))),
            level = self.st.level, xpIntoLevel = self.st.xp,
            plannedLevels = self.route.levels,
            xpQuest = self.xp.quest, xpQuestEstimated = self.xp.questEstimated,
            xpKill = self.xp.kill, xpGrind = self.xp.grind, grindKills = self.xp.grindKills,
            unknownXpQuests = self.xp.unknownXpQuests, accepts = self.xp.accepts, turnins = self.xp.turnins,
            -- share of the quest XP that is an estimate (quests whose XP is unknown in the DB), percent
            xpQuestEstimatedPct = self.xp.quest > 0 and round2(100 * self.xp.questEstimated / self.xp.quest) or 0,
            maxQuestLog = self.maxLog, carried = carried, steps = #self.route.steps,
            incidentalPct = self.opts.incidentalPct or V.DEFAULTS.incidentalPct, xpIncidental = self.xp.incidental,
            gates = self.gates,
        },
        -- --write-state (not part of the JSON report); with --until: the state before that step / segment
        endState = (self.opts.untilId and self.untilState) or self:EndState(),
        untilMatched = self.untilState ~= nil,
    }
end

---------------------------------------------------------------------------
-- one profile: the main run + the shadow runs of the grind report
---------------------------------------------------------------------------

local KEEP_WORST = { ["optional-dependency"] = true }

local function hasOptionalStep(route)
    for _, s in ipairs(route.steps or {}) do
        if s.optional then return true end
    end
    return false
end

-- insert the messages of a shadow run into the main run's list after the main messages of the same step
local function mergeShadowMessages(main, shadow)
    main.suppressed = main.suppressed + shadow.suppressed
    if #shadow.messages == 0 then return end
    local out, j = {}, 1
    local extra = shadow.messages
    for _, m in ipairs(main.messages) do
        local o = main.msgOrd[m] or main.ordinal
        while j <= #extra and (shadow.msgOrd[extra[j]] or shadow.ordinal) < o do
            out[#out + 1] = extra[j]
            j = j + 1
        end
        out[#out + 1] = m
    end
    for k = j, #extra do out[#out + 1] = extra[k] end
    for _, m in ipairs(extra) do
        countMessage(main, m, 1)
        main.msgOrd[m] = shadow.msgOrd[m]
    end
    main.messages = out
end

-- "explicit id": not positional (Schema.AddSegment autoId) and not the default "<anchor>+<n>" of a
-- per-route insert step
local function hasExplicitId(step)
    if step.id == nil or step.autoId then return false end
    if step.inserted and not step.explicitId then return false end
    return true
end
V.HasExplicitId = hasExplicitId

--- Validate one route x profile: the main run (opts as given; its messages, levels and end state are
-- the report) and the shadow runs of the grind report, which only simulate:
--   * worst case (opts.worstCase): steps marked `optional = true` are not done -- their XP is not
--     counted, quests they accept are not taken (later complete / turnin of them are skipped too) and
--     quests they turn in stay open; a required step that needs such a quest is an ERROR
--     `optional-dependency` (reported into the main run);
--   * the incidental band: incidental kills 0% and V.DEFAULTS.incidentalBandPct (15%) of the quest
--     XP, each in the normal and the worst case (runs equal to an existing one are reused).
-- Adds to the result: summary.grindKillsWorst / xpGrindWorst / endLevelWorst / optionalSkipped /
-- optionalAccepts / band (["0"], ["15"]: grindKills, grindKillsWorst, endLevel, endLevelWorst),
-- segments[i].grindKillsWorst / optionalSkipped / band, summary.gates[i].killsWorst / band.
-- @return the result table of the main run (Run:result)
function V.RunProfile(db, schema, route, profile, opts)
    opts = opts or {}
    local mainPct = opts.incidentalPct or V.DEFAULTS.incidentalPct
    local main = V.NewRun(db, schema, route, profile, opts)
    local res = main:execute()
    local optional = hasOptionalStep(route)
    local runs = { [tostring(mainPct) .. ":normal"] = main }
    local function get(pct, worst)
        if worst and not optional then worst = false end -- nothing optional: the worst case is the normal run
        local key = tostring(pct) .. (worst and ":worst" or ":normal")
        if not runs[key] then
            local o = {}
            for k, v in pairs(opts) do o[k] = v end
            o.incidentalPct, o.worstCase, o.shadow = pct, worst, true
            o.keepCodes = (worst and pct == mainPct) and KEEP_WORST or {}
            local r = V.NewRun(db, schema, route, profile, o)
            r:execute()
            runs[key] = r
        end
        return runs[key]
    end
    local worst = get(mainPct, true)
    if worst ~= main then mergeShadowMessages(main, worst) end
    res.messages, res.suppressed, res.acceptedWarn = main.messages, main.suppressed, main.acceptedWarn
    local function lv(r) return round2(DB.LevelValue(db, r.st)) end
    -- unrounded end levels (--end-level compares them with the plan)
    res.endLevelExact = { normal = DB.LevelValue(db, main.st), worst = DB.LevelValue(db, worst.st) }
    if opts.levels then
        -- --levels: the level before every step with an explicit id, in the normal and the worst case
        local list = {}
        for _, step in ipairs(route.steps) do
            if hasExplicitId(step) then
                list[#list + 1] = {
                    id = step.id, segment = step.segment, level = main.levelBefore[step],
                    levelWorst = worst.levelBefore[step], anchor = step.inserted and step.anchor or nil,
                    file = step.file, actions = stepActions(step),
                }
            end
        end
        res.stepLevels = list
    end
    local sm = res.summary
    sm.grindKillsWorst, sm.xpGrindWorst, sm.endLevelWorst = worst.xp.grindKills, worst.xp.grind, lv(worst)
    sm.optionalSkipped, sm.optionalAccepts = worst.optSkipped, worst.optAccepts
    local pcts = { 0, V.DEFAULTS.incidentalBandPct }
    local band = json.object({})
    for _, p in ipairs(pcts) do
        local n, w = get(p, false), get(p, true)
        band[tostring(p)] = json.object({ incidentalPct = p, grindKills = n.xp.grindKills, grindKillsWorst = w.xp.grindKills,
                                          endLevel = lv(n), endLevelWorst = lv(w) })
    end
    sm.band = band
    for i, s in ipairs(res.segments) do
        local ws = worst.segments[i]
        s.grindKillsWorst = ws and ws.grindKills or 0
        s.optionalSkipped = ws and ws.optionalSkipped or 0
        local b = json.object({})
        for _, p in ipairs(pcts) do
            local n, w = get(p, false).segments[i], get(p, true).segments[i]
            b[tostring(p)] = json.object({ kills = n and n.grindKills or 0, worst = w and w.grindKills or 0 })
        end
        s.band = b
    end
    for i, g in ipairs(main.gates) do
        local step = main.gateSteps[i]
        local wg = worst.gateByStep[step]
        g.killsWorst = wg and wg.kills or 0 -- an optional level step is not done in the worst case
        local b = json.object({})
        for _, p in ipairs(pcts) do
            local ng, wgp = get(p, false).gateByStep[step], get(p, true).gateByStep[step]
            b[tostring(p)] = json.object({ kills = ng and ng.kills or 0, worst = wgp and wgp.kills or 0 })
        end
        g.band = b
    end
    return res
end

---------------------------------------------------------------------------
-- module / CLI
---------------------------------------------------------------------------

--- Route-level checks (once per route, not per profile): race tokens of the route and of
-- the step filters must be UnitRace() raceFiles known to the DB ("Scourge", not "Undead");
-- every filtered step of the route itself (own steps, per-route inserts) should match at least one
-- of the route's profiles; `ok` may list level-grind only with a ceiling.
-- Shared steps: step-no-profile is never reported for them (a shared step that cannot match the
-- route is not composed into it; the templates are checked by lib.module_checks: shared-step-unused),
-- and the steps of opts.moduleChecked (the module whose templates lib.module_checks covers) are left
-- out altogether.
-- @param opts { moduleChecked = "<module name>" | nil }
-- @return array of messages { severity, code, msg, segment, step, stepId, file }
function V.RouteChecks(db, route, profiles, opts)
    opts = opts or {}
    local out = {}
    local known = db.enums and db.enums.raceFileToBit or {}
    local function add(sev, code, step, msg, ...)
        local m = { severity = sev, code = code, msg = format(msg, ...) }
        if step then
            m.segment, m.step, m.stepId, m.file = step.segment, step.segIndex, step.id, step.file
            if type(step.library) == "string" then m.library, m.shared = step.library, true end
            if step.inserted then m.inserted = true end
            if sev == "WARN" and step.ok then acknowledge(step.ok, m) end
        end
        out[#out + 1] = m
        return m
    end
    local CEILING = "ok lists level-grind without a ceiling: write ok = { [\"level-grind\"] = N } (accepted only "
        .. "while the gate needs at most N kills)"
    -- a segment's `ok` (it only ever accepts segment-level): a plain level-grind there is the same mistake
    for _, seg in ipairs(route.segments or {}) do
        local lib = type(seg.library) == "string" and seg.library or nil
        if seg.ok and seg.ok["level-grind"] == true and not (opts.moduleChecked and lib == opts.moduleChecked) then
            local m = add("ERROR", "ok-needs-ceiling", nil, "segment '%s': %s; a level gate is acknowledged on its step",
                tostring(seg.id), CEILING)
            m.segment, m.file = seg.id, seg.file
            if lib then m.library, m.shared = lib, true end
        end
    end
    local names = sortedKeys(known)
    local function hint(tok)
        if tok == "Undead" then return " (the raceFile of the Undead is \"Scourge\")" end
        return format(" (known: %s)", table.concat(names, ", "))
    end
    for _, tok in ipairs(sortedKeys(route.races)) do
        if known[tok] == nil then
            add("ERROR", "unknown-race-token", nil, "route races: unknown raceFile '%s'%s", tostring(tok), hint(tok))
        end
    end
    for _, step in ipairs(route.steps or {}) do
        if not (opts.moduleChecked and step.library == opts.moduleChecked) then
            local f = step.filters
            local bad = false
            for _, tok in ipairs(sortedKeys(f and f.race)) do
                if known[tok] == nil then
                    bad = true
                    add("ERROR", "unknown-race-token", step, "step race filter: unknown raceFile '%s'%s", tostring(tok),
                        hint(tok))
                end
            end
            if step.ok and step.ok["level-grind"] == true then
                add("ERROR", "ok-needs-ceiling", step, "%s", CEILING)
            end
            -- (a harness route has a single profile on purpose)
            if f and not bad and not route.harness and not step.library then
                local any = false
                for _, p in ipairs(profiles) do
                    if (not f.class or not p.class or f.class[p.class])
                        and (not f.race or not p.race or f.race[p.race])
                        and (not f.faction or not p.faction or f.faction == p.faction) then
                        any = true
                        break
                    end
                end
                if not any then
                    local labels = {}
                    for i, p in ipairs(profiles) do labels[i] = profileLabel(p) end
                    add("WARN", "step-no-profile", step, "step matches none of the route's profiles (%s): it is never "
                        .. "shown", table.concat(labels, "; "))
                end
            end
        end
    end
    return out
end

-- Drop the library-step messages of later profiles that repeat one of an earlier profile
-- of the same route (library messages are reported once per route).
local function dedupeLibraryMessages(results)
    local seen = {}
    for i, res in ipairs(results) do
        local kept = {}
        for _, m in ipairs(res.messages) do
            local key = m.library and table.concat({ m.severity, m.code, tostring(m.stepId or m.segment), m.msg }, "\0")
            if key and seen[key] and i > 1 then
                countMessage(res, m, -1)
                res.libraryRepeats = (res.libraryRepeats or 0) + 1
            else
                if key then seen[key] = true end
                kept[#kept + 1] = m
            end
        end
        res.messages = kept
    end
end

local function emptyResult(label, modName, plabel)
    return { route = label, module = modName, profileLabel = plabel or "-", messages = {},
             counts = { ERROR = 0, WARN = 0, INFO = 0 }, suppressed = 0, acceptedWarn = 0, segments = {}, summary = {} }
end

-- put messages in front of a result's list and count them (opts.ignore suppresses codes)
local function prependMessages(res, list, ignore)
    local extra = {}
    for _, m in ipairs(list) do
        if ignore and ignore[m.code] then
            res.suppressed = (res.suppressed or 0) + 1
        else
            extra[#extra + 1] = m
            countMessage(res, m, 1)
        end
    end
    for _, m in ipairs(res.messages) do extra[#extra + 1] = m end
    res.messages = extra
end

---------------------------------------------------------------------------
-- numeric criteria (--end-level, --grind-until, --max-grind-until, --baseline)
---------------------------------------------------------------------------

-- grind kills (normal, worst case) from the route start up to the end of a segment; nil when the
-- route does not contain the segment
local function grindUntil(res, segId)
    local n, w = 0, 0
    for _, s in ipairs(res.segments or {}) do
        n, w = n + (s.grindKills or 0), w + (s.grindKillsWorst or 0)
        if s.id == segId then return n, w end
    end
    return nil
end

--- Apply the numeric criteria of the run to one result of V.RunProfile (ERRORs are added at the end
-- of its messages; summary.grindUntil is set):
--   opts.endLevel            ERROR end-level: the normal or the worst-case run ends below the planned end
--                            level (route.levels[2]; a harness route: levels[2] of its last segment)
--   opts.grindUntil = SEG    summary.grindUntil = { segment, kills, killsWorst } (kills up to the end of SEG)
--   opts.maxGrindUntil = { segment, kills, worst }   ERROR grind-budget above either budget
--   opts.baseline = { races = { [raceFile] = { grindKills, grindKillsWorst } } }   ERROR grind-baseline
--                            when the route needs more total grind kills than its race's entry
function V.ApplyCriteria(res, route, opts)
    local sm = res.summary or {}
    if not sm.endLevel then return res end
    local function add(code, fields, msg, ...)
        if opts.ignore and opts.ignore[code] then
            res.suppressed = (res.suppressed or 0) + 1
            return
        end
        local m = { severity = "ERROR", code = code, msg = format(msg, ...) }
        for k, v in pairs(fields or {}) do m[k] = v end
        res.messages[#res.messages + 1] = m
        countMessage(res, m, 1)
    end
    if opts.endLevel then
        local planned = route.levels and route.levels[2]
        if route.harness then
            local last = route.segments[#route.segments]
            planned = last and last.levels and last.levels[2]
        end
        local exact = res.endLevelExact or { normal = sm.endLevel, worst = sm.endLevelWorst or sm.endLevel }
        if planned and (exact.normal < planned or exact.worst < planned) then
            add("end-level", { level = sm.endLevel }, "the %s ends at simulated level %.2f (worst case %.2f); the planned "
                .. "end level is %d (--end-level: both runs must reach it)", route.harness and "harness run" or "route",
                exact.normal, exact.worst, planned)
        end
    end
    local budget = opts.maxGrindUntil
    local untilSeg = opts.grindUntil or (budget and budget.segment)
    if untilSeg then
        local n, w = grindUntil(res, untilSeg)
        if n then sm.grindUntil = json.object({ segment = untilSeg, kills = n, killsWorst = w }) end
    end
    if budget then
        local n, w = grindUntil(res, budget.segment)
        if not n then
            if not route.harness then
                add("grind-budget", nil, "--max-grind-until: the route has no segment '%s'", budget.segment)
            end
        elseif n > budget.kills or w > budget.worst then
            add("grind-budget", { kills = n }, "grind kills up to the end of %s: %d (worst case %d); the budget is %d "
                .. "(worst case %d)", budget.segment, n, w, budget.kills, budget.worst)
        end
    end
    if opts.baseline then
        local race = tostring(res.profile and res.profile.race or "any-race")
        local e = (opts.baseline.races or {})[race]
        if type(e) ~= "table" or type(e.grindKills) ~= "number" or type(e.grindKillsWorst) ~= "number" then
            add("grind-baseline", nil, "--baseline: no entry for race %s in %s", race, tostring(opts.baseline.file))
        elseif (sm.grindKills or 0) > e.grindKills or (sm.grindKillsWorst or 0) > e.grindKillsWorst then
            add("grind-baseline", { kills = sm.grindKills }, "the route needs %d grind kills (worst case %d); the baseline "
                .. "of race %s is %d (worst case %d): a route may not need more kills than the base route of its race",
                sm.grindKills or 0, sm.grindKillsWorst or 0, race, e.grindKills, e.grindKillsWorst)
        end
    end
    return res
end

--- The baseline of a run (--write-baseline): per raceFile the maximum over its validated routes of the
-- total grind kills (normal / worst case) and of the kills up to --grind-until.
function V.Baseline(all, opts)
    opts = opts or {}
    local races = {}
    local count = 0
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            local sm = r.summary or {}
            if r.endState and sm.endLevel then
                count = count + 1
                local race = tostring(r.profile and r.profile.race or "any-race")
                local e = races[race]
                if not e then
                    e = { grindKills = 0, grindKillsWorst = 0, routes = {} }
                    races[race] = e
                end
                e.grindKills = math.max(e.grindKills, sm.grindKills or 0)
                e.grindKillsWorst = math.max(e.grindKillsWorst, sm.grindKillsWorst or 0)
                if sm.grindUntil then
                    e.grindKillsUntil = math.max(e.grindKillsUntil or 0, sm.grindUntil.kills)
                    e.grindKillsUntilWorst = math.max(e.grindKillsUntilWorst or 0, sm.grindUntil.killsWorst)
                end
                e.routes[#e.routes + 1] = tostring(r.route)
            end
        end
    end
    for _, e in pairs(races) do table.sort(e.routes) end
    return {
        meta = json.object({ source = "tools/validate_routes.lua --write-baseline", routes = count,
                             grindUntil = opts.grindUntil }),
        races = json.object(races),
    }
end

--- Read a baseline file (--baseline). @return table | nil, error
function V.ReadBaseline(path)
    local text = Loader.readFile(path)
    if not text then return nil, "cannot read " .. tostring(path) end
    local ok, data = pcall(json.decode, text)
    if not ok or type(data) ~= "table" or type(data.races) ~= "table" then
        return nil, tostring(path) .. ": not a baseline file (expected { \"races\": { \"<raceFile>\": { "
            .. "\"grindKills\": N, \"grindKillsWorst\": W } } })" .. (ok and "" or (": " .. tostring(data)))
    end
    data.file = path
    return data
end

---------------------------------------------------------------------------
-- one module
---------------------------------------------------------------------------

-- files that contributed to a route: its registration, its segments and its composed steps
local function routeFiles(route, set)
    if route.file then set[route.file] = true end
    for _, seg in ipairs(route.segments or {}) do
        if seg.file then set[seg.file] = true end
    end
    for _, step in ipairs(route.steps or {}) do
        if step.file then set[step.file] = true end
    end
    return set
end

--- Validate every route of a module directory.
-- @param opts { db, schema, route = id / comma list with `*` wildcards, routeList = Glob.NewList (shared
--               by the modules of a run; default: built from opts.route), profile = override, tolerance,
--               hardTolerance, ignore = set, module = already loaded module (Loader.LoadModule),
--               libraryReported = { [libName] = true } (libraries whose own load / schema errors are
--               reported elsewhere in this run), isOwn = function(file) (--own; nil: every file is own),
--               ownGiven = true when --own was given, skipGlobs / keepGlobs (the file filter, when the
--               module is loaded here), endLevel / grindUntil / maxGrindUntil / baseline (V.ApplyCriteria),
--               levels = true (result.stepLevels) }
-- @return { module, dir, loadErrors, results = { ... }, matched, notes = { messages that do not count },
--           mod = the loaded module, routes = { { route = <route>, results = { ... } } } }
-- A module that registers routes AND shared content of its own gets one more entry in front of its
-- routes: "(shared <Module>)" with the messages of the template checks (lib.module_checks).
function V.ValidateModule(dir, opts)
    local mod = opts.module or Loader.LoadModule(dir, { schema = opts.schema, skipGlobs = opts.skipGlobs,
        keepGlobs = opts.keepGlobs })
    local out = { module = mod.name, dir = dir, loadErrors = mod.errors, results = {}, notes = {}, mod = mod, routes = {} }
    out.matched = 0
    local moduleChecked
    if mod.isLibrary then
        -- a library module: no route of its own; its steps are validated in the routes that use them
        out.library = true
        local n = 0
        for _, seg in ipairs(mod.librarySegments) do n = n + #seg.steps end
        local res = emptyResult("(library " .. mod.name .. ")", mod.name,
            format("library: %d segment(s), %d step(s)", #mod.librarySegments, n))
        res.library = mod.name
        out.results[1] = res
    elseif #mod.routes > 0 and (#mod.librarySegments > 0 or #mod.libraryInserts > 0) then
        -- a mixed module: the checks on its templates, once, whatever --route selects
        local n = 0
        for _, seg in ipairs(mod.librarySegments) do n = n + #seg.steps end
        for _, ins in ipairs(mod.libraryInserts) do n = n + #ins.steps end
        local res = emptyResult("(shared " .. mod.name .. ")", mod.name,
            format("shared: %d segment(s), %d insert(s), %d step(s)", #mod.librarySegments, #mod.libraryInserts, n))
        res.shared = mod.name
        out.results[1] = res
        local msgs, notes = ModuleChecks.Run(opts.db, opts.schema, mod, { isOwn = opts.isOwn, acknowledge = acknowledge })
        prependMessages(res, msgs, opts.ignore)
        for _, m in ipairs(notes) do
            m.note = "partial load (--skip / --keep): the file is not own, the anchor or the route may live in a "
                .. "skipped file"
            out.notes[#out.notes + 1] = m
        end
        moduleChecked = mod.name
    end
    local list = opts.routeList or (opts.route and Glob.NewList(opts.route)) or nil
    -- files that contributed to the selected routes / to the routes --route leaves out
    local contributed, elsewhere = {}, {}
    for _, route in ipairs(mod.routes) do
        if list and not Glob.Any(list.patterns, route.id) then routeFiles(route, elsewhere) end
        if not list or Glob.ListMatch(list, route.id) then
            out.matched = out.matched + 1
            routeFiles(route, contributed)
            local profiles = V.Profiles(route, opts.profile)
            local first
            local routeResults = {}
            for _, profile in ipairs(profiles) do
                local res = V.RunProfile(opts.db, opts.schema, route, profile, opts)
                first = first or res
                out.results[#out.results + 1] = res
                routeResults[#routeResults + 1] = res
            end
            out.routes[#out.routes + 1] = { route = route, results = routeResults }
            dedupeLibraryMessages(routeResults)
            -- route-level messages are reported once per route (first profile)
            if first then
                prependMessages(first, V.RouteChecks(opts.db, route, profiles, { moduleChecked = moduleChecked }), opts.ignore)
            end
            for _, res in ipairs(routeResults) do V.ApplyCriteria(res, route, opts) end
        end
    end
    -- With --route an error that provably belongs to a route outside the selection is a note and does
    -- not fail the run. Everything else counts, as in a full run:
    --   * a file that did not load or run to its end (e.load): what it would have given the selected
    --     routes is unknown (another author's broken file is left out with --skip, never by --route);
    --   * an error about one route (e.route: its registration, its composition) counts when that route
    --     is selected, whatever file reports it;
    --   * any other error (a schema error of a shared segment / insert, a stray global) counts unless
    --     the file loaded and its content went only to routes outside the selection. A file that gave
    --     nothing to any route counts: its content may be exactly what the selected routes miss;
    --   * the caller's own files (--own) always count.
    local function noteReason(e)
        if not list or e.load then return nil end
        if opts.ownGiven and opts.isOwn and opts.isOwn(e.file) then return nil end
        if e.route then
            if Glob.Any(list.patterns, e.route) then return nil end
            return format("--route: an error of route %s, which is not selected", tostring(e.route))
        end
        if elsewhere[e.file] and not contributed[e.file] then
            return "--route: the file loaded, and its content goes only to routes that are not selected"
        end
        return nil
    end
    local loadErrors = {}
    for _, e in ipairs(mod.errors) do
        if not (e.library and opts.libraryReported and opts.libraryReported[e.library]) then
            local reason = noteReason(e)
            if reason then
                out.notes[#out.notes + 1] = { severity = "ERROR", code = "schema", file = e.file, msg = e.msg,
                    library = e.library, note = reason }
            else
                loadErrors[#loadErrors + 1] = e
            end
        end
    end
    if #loadErrors > 0 then
        -- attach load/schema errors to the first result (or a synthetic one)
        local target = out.results[1]
        if not target then
            target = emptyResult("(module " .. mod.name .. ")", mod.name)
            out.results[1] = target
        end
        local schemaMsgs = {}
        for _, e in ipairs(loadErrors) do
            schemaMsgs[#schemaMsgs + 1] = { severity = "ERROR", code = "schema", file = e.file, msg = e.msg,
                library = e.library or (mod.isLibrary and mod.name or nil) }
        end
        for _, m in ipairs(target.messages) do schemaMsgs[#schemaMsgs + 1] = m end
        target.messages = schemaMsgs
        target.counts.ERROR = target.counts.ERROR + #loadErrors
    end
    return out
end

--- Validate a harness route (tools/lib/harness.lua: Harness.Build) -- some segments of a library
-- module for one profile, usually from a start state (opts.startState).
-- @return a module result like V.ValidateModule (module = library module name, harness = true)
function V.ValidateHarness(hb, opts)
    local mod = hb.mod
    local out = { module = mod.name, dir = hb.dir, loadErrors = mod.errors, results = {}, matched = 1, harness = true,
                  notes = {}, mod = mod, routes = {} }
    local res
    if hb.route then
        local profile = V.Profiles(hb.route)[1]
        res = V.RunProfile(opts.db, opts.schema, hb.route, profile, opts)
        prependMessages(res, V.RouteChecks(opts.db, hb.route, { profile }), opts.ignore)
        V.ApplyCriteria(res, hb.route, opts)
        out.routes[1] = { route = hb.route, results = { res } }
    else
        res = emptyResult(hb.def and hb.def.id or Harness.RouteId(mod.name), mod.name,
            opts.profile and profileLabel(opts.profile) or "-")
    end
    res.harness = true
    res.segmentsUsed = hb.segments
    local schemaMsgs = {}
    for _, e in ipairs(mod.errors) do
        schemaMsgs[#schemaMsgs + 1] = { severity = "ERROR", code = "schema", file = e.file, msg = e.msg,
            library = e.library or mod.name }
    end
    for _, e in ipairs(hb.errors) do
        schemaMsgs[#schemaMsgs + 1] = { severity = "ERROR", code = "schema", file = e.file, msg = e.msg }
    end
    for _, m in ipairs(res.messages) do schemaMsgs[#schemaMsgs + 1] = m end
    res.counts.ERROR = res.counts.ERROR + #mod.errors + #hb.errors
    res.messages = schemaMsgs
    out.results[1] = res
    return out
end

local function locStr(m)
    local parts = {}
    if m.segment then
        parts[#parts + 1] = m.step and format("%s#%d", tostring(m.segment), m.step) or tostring(m.segment)
    end
    if m.stepId and m.segment and m.stepId ~= format("%s:%d", tostring(m.segment), m.step or 0) then
        parts[#parts + 1] = "id=" .. m.stepId
    elseif m.stepId and not m.segment then
        parts[#parts + 1] = "id=" .. m.stepId -- a template step of a shared insert (no segment before composition)
    end
    if m.file then parts[#parts + 1] = "(" .. m.file .. ")" end
    if #parts == 0 then parts[1] = "route" end
    if m.library then table.insert(parts, 1, "[library " .. tostring(m.library) .. "]") end
    return table.concat(parts, " ")
end
V.LocStr = locStr

local function gateLevel(g)
    return format("%d%s", g.level, (g.frac or 0) > 0 and format(" +%d%%", floor(g.frac * 100 + 0.5)) or "")
end
V.GateLevel = gateLevel

--- Grind report lines of one result (V.RunProfile): the level gates and the segments with the
-- same-level kills needed in the normal / worst case, each without and with incidental kills, and the
-- summary lines "grind kills: N (worst case M)" + the incidental band. {} for results without it.
function V.GrindLines(r)
    local out = {}
    local sm = r.summary or {}
    if not (sm.endLevel and sm.band) then return out end
    local bp = V.DEFAULTS.incidentalBandPct
    local b0, bh = tostring(0), tostring(bp)
    local function band(b, key, field) return (b and b[key] and b[key][field]) or 0 end
    if sm.gates and #sm.gates > 0 then
        out[#out + 1] = format("  level gates: same-level kills to reach the level of each level step; worst = steps "
            .. "marked optional (and their quests) not done; +%d%% = incidental kills worth %d%% of the quest XP", bp, bp)
        out[#out + 1] = format("  %-9s %6s %6s %6s %9s  %s", "gate", "kills", "worst", "+" .. bp .. "%",
            "worst+" .. bp .. "%", "step")
        for _, g in ipairs(sm.gates) do
            -- an optional level step is not done in the worst case: "-" (its grind moves to the next gate)
            local function worst(key) return g.optional and "-" or tostring(band(g.band, key, "worst")) end
            out[#out + 1] = format("  %-9s %6d %6s %6d %9s  %s%s", gateLevel(g), band(g.band, b0, "kills"), worst(b0),
                band(g.band, bh, "kills"), worst(bh), locStr({ segment = g.segment, step = g.step, stepId = g.stepId }),
                g.optional and " (optional)" or "")
        end
    end
    if #(r.segments or {}) > 0 then
        out[#out + 1] = format("  %-28s %6s %6s %6s %9s %8s", "grind kills per segment", "kills", "worst",
            "+" .. bp .. "%", "worst+" .. bp .. "%", "optional")
        for _, s in ipairs(r.segments) do
            out[#out + 1] = format("  %-28s %6d %6d %6d %9d %8d", tostring(s.id):sub(1, 28), band(s.band, b0, "kills"),
                band(s.band, b0, "worst"), band(s.band, bh, "kills"), band(s.band, bh, "worst"), s.optionalSkipped or 0)
        end
    end
    local pct = sm.incidentalPct or 0
    out[#out + 1] = format("  grind kills: %d (worst case %d)%s; worst case = %d optional step(s) not done (%d quest "
        .. "accept(s)), end level %.2f", sm.grindKills or 0, sm.grindKillsWorst or 0,
        pct > 0 and format(" with incidental kills %g%% of quest XP (+%d XP)", pct, sm.xpIncidental or 0) or "",
        sm.optionalSkipped or 0, sm.optionalAccepts or 0, sm.endLevelWorst or 0)
    out[#out + 1] = format("  grind kills band: incidental kills 0%% -> %d (worst case %d), %d%% of quest XP -> %d "
        .. "(worst case %d)", band(sm.band, b0, "grindKills"), band(sm.band, b0, "grindKillsWorst"), bp,
        band(sm.band, bh, "grindKills"), band(sm.band, bh, "grindKillsWorst"))
    return out
end

-- "3 error(s), 2 warning(s), 1 accepted, 5 info" (the accepted part only when there is one)
local function countsText(r)
    local acc = r.acceptedWarn or 0
    return format("%d error(s), %d warning(s)%s, %d info", r.counts.ERROR, r.counts.WARN,
        acc > 0 and format(", %d accepted", acc) or "", r.counts.INFO)
end
V.CountsText = countsText

--- The note lines of a module result (messages that do not count: partial loads, --route).
function V.NoteLines(mres)
    local out = {}
    for _, m in ipairs(mres.notes or {}) do
        out[#out + 1] = format("  note  %s [%s] %s -- not counted: %s", locStr(m), m.code, m.msg, tostring(m.note or ""))
    end
    return out
end

--- Human-readable report lines.
function V.FormatText(all, opts)
    opts = opts or {}
    local lines = {}
    local function w(s) lines[#lines + 1] = s end
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            if r.library then
                w(format("== library module %s [%s]: its steps are checked in the routes that use them",
                    tostring(mres.module), r.profileLabel))
            elseif r.shared then
                w(format("== shared content of module %s [%s]: checks on the templates (shared segments and "
                    .. "inserts), once for all routes", tostring(mres.module), r.profileLabel))
            elseif r.overrides then
                w(format("== DB overrides %s", tostring(mres.dir)))
            else
                w(format("== route %s [%s] module %s", tostring(r.route), r.profileLabel, tostring(mres.module)))
            end
            for _, m in ipairs(r.messages) do
                if m.accepted then
                    -- acknowledged with `ok` on its step / segment: shown only with -v
                    if opts.verbose then w(format("  %-5s %s [%s] %s", "ok", locStr(m), m.code, m.msg)) end
                elseif m.severity ~= "INFO" or opts.verbose then
                    w(format("  %-5s %s [%s] %s", m.severity, locStr(m), m.code, m.msg))
                end
            end
            if #r.segments > 0 then
                w(format("  %-28s %7s %15s %8s %8s %8s %6s %4s", "segment", "planned", "simulated", "questXP",
                    "killXP", "grindXP", "kills", "log"))
                for _, s in ipairs(r.segments) do
                    w(format("  %-28s %7s %6.2f -> %5.2f %8d %8d %8d %6d %4d", tostring(s.id):sub(1, 28),
                        s.levels and format("%d-%d", s.levels[1], s.levels[2]) or "-", s.startLevel, s.endLevel or 0,
                        s.xpQuest or 0, s.xpKill or 0, s.xpGrind or 0, s.grindKills or 0, s.questLog or 0))
                end
            end
            local sm = r.summary or {}
            if sm.endLevel then
                w(format("  end level %.2f (optimistic %.2f, planned %s); quest XP %d; %d quests with estimated XP "
                    .. "(%.1f%% of quest XP); kill XP %d (estimate), grind XP %d (~%d kills); max quest log %d; carried %d",
                    sm.endLevel, sm.endLevelOptimistic or sm.endLevel,
                    sm.plannedLevels and tostring(sm.plannedLevels[2]) or "-", sm.xpQuest,
                    sm.unknownXpQuests, sm.xpQuestEstimatedPct or 0, sm.xpKill, sm.xpGrind, sm.grindKills,
                    sm.maxQuestLog, #(sm.carried or {})))
            end
            for _, line in ipairs(V.GrindLines(r)) do w(line) end
            if sm.grindUntil then
                w(format("  grind kills up to the end of %s: %d (worst case %d)", tostring(sm.grindUntil.segment),
                    sm.grindUntil.kills, sm.grindUntil.killsWorst))
            end
            w(format("  result: %s%s", countsText(r),
                (r.suppressed or 0) > 0 and format(", %d suppressed", r.suppressed) or ""))
            w("")
        end
        local notes = V.NoteLines(mres)
        if #notes > 0 then
            w(format("== notes for module %s (they do not change the exit status)", tostring(mres.module)))
            for _, line in ipairs(notes) do w(line) end
            w("")
        end
    end
    return lines
end

-- What no offline check (luacheck std, strict mock, validator, simulator) can confirm: the
-- static "only in game" section of docs/VALIDATION.md (README.md links here).
V.IN_GAME_ONLY = {
    "**Автоматизация без аппаратного события.** `AcceptQuest`, `CompleteQuest`, `GetQuestReward`, "
        .. "`AcknowledgeAutoAcceptQuest`, "
        .. "`C_GossipInfo.SelectAvailableQuest/SelectActiveQuest/SelectOption`, "
        .. "`SelectAvailableQuest/SelectActiveQuest` (окно приветствия) "
        .. "вызываются из обработчиков событий (`QUEST_DETAIL`, `QUEST_PROGRESS`, `QUEST_COMPLETE`, "
        .. "`GOSSIP_SHOW`, `QUEST_GREETING`). В моке они разрешены; что Forever не требует для них "
        .. "аппаратного события, проверяется только в клиенте.",
    "**Остров Зефрас (uiMap 2521) и прочие карты без мирового преобразования.** Стрелка и "
        .. "расстояние там приблизительные (номинальный размер карты, `approx`); пересчёт координат "
        .. "Зефраса и переход на Мулгор (высадка с небесного корабля / лодки) — только в игре.",
    "**Мулгор с изменённой геометрией.** Координаты БД уже в системе Forever; совпадение точек `at` "
        .. "с реальными NPC проверено валидатором по снимку, но не на месте.",
    "**Опыт новых квестов Forever** офлайн неизвестен (в отчёте — оценка медианой по уровню). "
        .. "Реальные значения записываются при сдаче (`/fb xp`).",
    "**Имена мест на языке клиента.** `sethearth` узнаёт точку привязки по имени: `GetBindLocation()` "
        .. "сравнивается с локализованным именем зоны (`C_Map.GetAreaInfo` по `places[...].area` из "
        .. "`Data.lua`) — что эти имена совпадают в ruRU, проверяется в клиенте.",
    "**События окон и цели-события.** Порядок `TRAINER_*`/`MERCHANT_*`/`TAXIMAP_*` и "
        .. "`PLAYER_INTERACTION_MANAGER_FRAME_*` (одно окно засчитывается один раз); что `UnitGUID(\"npc\")` "
        .. "в момент `TRAINER_SHOW`/`MERCHANT_SHOW` отдаёт NPC окна (по нему окно засчитывается только шагу "
        .. "с этим `npc`); выполнение целей исследования и сопровождения (в моке — только по явному событию).",
    "**Количество целей квестов** — из подсказок Wowhead Forever (`tools/data/wowhead_requirements.json`): "
        .. "местами они расходятся с WCLBox и текстом Classic (например 364: 8 + 8, WCLBox — 5 + 5); "
        .. "в игре не сверялись. От них зависят только оценки опыта за убийства.",
    "**Метка Blizzard** (`C_Map.SetUserWaypoint` + `C_SuperTrack`) на картах Forever, где метки "
        .. "запрещены или карта не поддерживает их.",
    "**SavedVariables после холодного перезапуска** ранних билдов Forever: прогресс восстанавливается "
        .. "по игре (журнал, сданные квесты, уровень), неизвестны только transient-шаги после последнего "
        .. "опорного шага.",
    "**Секретные значения** (`issecretvalue` и т. п.) в ограниченных контекстах (подземелья, бой): "
        .. "аддон их не читает, но реальный набор ограничений Forever виден только в клиенте.",
}

--- Markdown report (docs/VALIDATION.md): the aggregated layout of lib/report.lua -- totals, module
-- entries, route summary, path comparison, the shared path once for all routes, the gate matrix, one
-- section per route with its own messages, INFO as counts, the "only in game" list.
function V.FormatMarkdown(all, db)
    return Report.Markdown(V, all, db)
end

--- JSON-friendly report table.
function V.ReportTable(all, db)
    local routes, notes = {}, {}
    local totals = { ERROR = 0, WARN = 0, INFO = 0, accepted = 0 }
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            routes[#routes + 1] = {
                route = r.route, module = mres.module, dir = mres.dir, profile = json.object(r.profile or {}),
                counts = r.counts, suppressed = r.suppressed, summary = json.object(r.summary or {}),
                segments = r.segments, messages = r.messages,
                accepted = r.acceptedWarn or 0, -- WARNs acknowledged with `ok` (messages with accepted = true)
                foreign = r.foreign, -- with --own: unaccepted WARNs on files that are not own
                library = r.library, libraryRepeats = r.libraryRepeats, -- library module entry / repeats dropped
                shared = r.shared, -- the entry of a module's template checks
            }
            for k, v in pairs(r.counts) do totals[k] = totals[k] + v end
            totals.accepted = totals.accepted + (r.acceptedWarn or 0)
        end
        for _, m in ipairs(mres.notes or {}) do
            notes[#notes + 1] = { module = mres.module, code = m.code, file = m.file, stepId = m.stepId, msg = m.msg,
                                  note = m.note }
        end
    end
    return { db = { build = db.meta and db.meta.build, generated = db.meta and db.meta.generated },
             totals = totals, routes = routes, notes = notes }
end

local USAGE = [[
usage: lua5.1 tools/validate_routes.lua [options] [module-dir ...]

Validates FastesBoooy route modules against the Forever DB snapshot.
Without module dirs, every addons/FastesBoooy_*/ module (with a TOC) is checked.

selection:
  --route ID[,ID...]    validate only these routes; `*` is a wildcard ('orc-*,troll-*', '*-warrior').
                        Repeatable (the lists add up). Every entry must match a route. This is how to
                        pick a race / class. Errors that belong to a route outside the selection are
                        notes; a file that does not load always counts (leave it out with --skip).
  --profile k=v,...     OVERRIDE the player profile of every selected route (not a filter; use
                        --route to select): race=Scourge,class=PALADIN,faction=Horde
  --skip GLOB           do not load the TOC files matching GLOB (repeatable; `*` wildcard, matched
                        against the TOC path with forward slashes, e.g. 'Classes/*')
  --keep GLOB           ...except the files matching GLOB (repeatable): a file is skipped when it
                        matches a --skip and no --keep
  --own GLOB            the files the caller is responsible for (repeatable, same matching; default:
                        every loaded file). With --strict only warnings on own files fail the run, the
                        others are listed as "foreign warnings"; on a partial load (--skip) the template
                        checks of files that are not own are notes. Errors always count, in any file.
                        A --skip / --keep / --own glob that matches no file is an error (exit 2).
gates:
  --strict              unaccepted warnings also fail (exit 1). A WARN is accepted when its code is
                        listed in `ok` of its step (of its segment for segment-level):
                        ok = "code" | { "code", ... } | { ["level-grind"] = N } (a kill ceiling)
  --end-level           ERROR end-level when the normal or the worst-case run ends below the planned
                        end level of the route (harness: of its last segment)
  --grind-until SEG     count the grind kills from the route start to the end of segment SEG
                        (--summary, --write-baseline); SEG must be a segment of a validated route
  --max-grind-until SEG=N/W   ERROR grind-budget when those kills exceed N (normal) or W (worst case)
  --baseline FILE       ERROR grind-baseline when a route needs more total grind kills (normal or
                        worst case) than the entry of its race in FILE
  --write-baseline FILE write per raceFile the maximum over the validated routes of that race of the
                        total grind kills (normal / worst case) and of the --grind-until pair (JSON)
output:
  --summary             after the normal output, one TSV line per route: route, profile, errors,
                        warnings (unaccepted, own), accepted, foreign, end level, worst-case end level,
                        grind kills, worst-case grind kills, grind kills up to --grind-until, the same
                        in the worst case ("-" without --grind-until)
  --levels              with exactly one route x profile: after the normal output, one TSV line per
                        step with an explicit id: id, segment, level before the step, the same in the
                        worst case, anchor of the insert or "-", file, actions
  --json FILE           write the full report (incl. INFO) as JSON
  --markdown FILE       write a Markdown report (docs/VALIDATION.md)
  -v, --verbose         also print INFO messages and accepted warnings
  -q, --quiet           print only the per-route result lines
data:
  --db FILE             DB snapshot (default tools/data/forever_db.lua)
  --no-overrides        do not apply the DB overrides of tools/overrides/*.lua
  --overrides DIR       read the DB overrides from DIR instead
  --addons DIR          where to discover modules (default addons)
checks:
  --tolerance-yards N   'at' distance WARN threshold in yards (default 40)
  --hard-tolerance-yards N  'at' distance ERROR threshold in yards (default 120)
  --tolerance N         WARN threshold in map units, for maps without known world size (default 3.0)
  --hard-tolerance N    ERROR threshold in map units, for maps without known world size (default 8.0)
  --ignore CODE,...     suppress message codes (e.g. quest-carried)
  --xp-optimism N       optimistic factor for estimated quest XP (default 2.0): a level
                        requirement is an ERROR only if even the optimistic level is too low
  --incidental-pct P    incidental kills while travelling: every turn-in also gives P% of its
                        quest XP as kill XP (default 0 = off). The grind report always shows
                        the band 0% / 15%, each also for the worst case (optional steps not done)
states and harness:
  --state FILE          start the simulation from a character state (JSON, see tools/README.md):
                        level / xpFrac, done, log / complete, hearth, at, flightPaths
  --write-state FILE    write the character state at the END of the run (same format; needs
                        exactly one route x profile: use --route)
  --until ID            with --write-state: write the state BEFORE step ID / the first step of
                        segment ID instead (e.g. --until h-22-hillsbrad = the end of a route's own
                        1-22 part, the start state of the first library segment)
  --harness DIR         validate a part of the shared segments of module DIR (a library module or a
                        module that also registers routes): a synthetic route of the --profile (race
                        and class required) that only uses the --segments of DIR; the module's shared
                        inserts apply to it, steps of other races / classes are not composed
  --segments ID,...     shared segments of the harness route, in this order (default: every
                        shared segment of the module, TOC order)
  -h, --help            this help

harness example (Undead Paladin, from the end of the 1-22 route):
  lua5.1 tools/validate_routes.lua --route undead-paladin --write-state state_ud_22.json --until h-22-hillsbrad
  lua5.1 tools/validate_routes.lua --harness addons/FastesBoooy_Guides --segments h-22-hillsbrad \
      --profile race=Scourge,class=PALADIN,faction=Horde --state state_ud_22.json --write-state out.json

exit status: 0 ok (also: a harness on a module without shared segments yet - nothing to do), 1 errors
(or unaccepted warnings with --strict), 2 usage/load failure, a --route entry matching no route, a
--skip / --keep / --own glob matching no file, a --grind-until segment no validated route has, or a
--write-state / --levels run that is not exactly one route x profile]]

function V.ParseArgs(argv)
    local o = { dirs = {}, ignore = {} }
    local i = 1
    local function val()
        i = i + 1
        local v = argv[i]
        if v == nil then error("missing value for " .. tostring(argv[i - 1]), 0) end
        return v
    end
    local function glob(key, opt)
        local v = val()
        if v == "" then error("empty value for " .. opt, 0) end
        o[key] = o[key] or {}
        o[key][#o[key] + 1] = (v:gsub("\\", "/"))
    end
    while i <= #argv do
        local a = argv[i]
        if a == "-h" or a == "--help" then o.help = true
        elseif a == "--route" then
            -- repeatable: the lists add up (like --skip / --keep / --own)
            local v = val()
            o.route = o.route and (o.route .. "," .. v) or v
        elseif a == "--profile" then
            o.profile = Harness.ParseProfile(val())
        -- an empty --state / --write-state / --segments value = not given (make harness passes them all)
        elseif a == "--state" then o.state = Harness.NonEmpty(val())
        elseif a == "--write-state" then o.writeState = Harness.NonEmpty(val())
        elseif a == "--until" then o.untilId = Harness.NonEmpty(val())
        elseif a == "--harness" then o.harness = val()
        elseif a == "--segments" then
            o.segments = Harness.ParseList(val())
            if #o.segments == 0 then o.segments = nil end
        elseif a == "--strict" then o.strict = true
        elseif a == "--skip" then glob("skip", a)
        elseif a == "--keep" then glob("keep", a)
        elseif a == "--own" then glob("own", a)
        elseif a == "--end-level" then o.endLevel = true
        elseif a == "--summary" then o.summary = true
        elseif a == "--levels" then o.levels = true
        elseif a == "--grind-until" then o.grindUntil = val()
        elseif a == "--max-grind-until" then
            local v = val()
            local seg, n, w = v:match("^([^=]+)=(%d+)/(%d+)$")
            if not seg then error("bad --max-grind-until (SEGMENT=N/W: kills in the normal / the worst case)", 0) end
            o.maxGrindUntil = { segment = seg, kills = tonumber(n), worst = tonumber(w) }
        elseif a == "--baseline" then o.baseline = val()
        elseif a == "--write-baseline" then o.writeBaseline = val()
        elseif a == "--no-overrides" then o.noOverrides = true
        elseif a == "--overrides" then o.overrides = val()
        elseif a == "--json" then o.json = val()
        elseif a == "--markdown" then o.markdown = val()
        elseif a == "--db" then o.db = val()
        elseif a == "--addons" then o.addons = val()
        elseif a == "--tolerance-yards" then
            o.toleranceYards = tonumber(val()) or error("bad --tolerance-yards", 0)
        elseif a == "--hard-tolerance-yards" then
            o.hardToleranceYards = tonumber(val()) or error("bad --hard-tolerance-yards", 0)
        elseif a == "--tolerance" then o.tolerance = tonumber(val()) or error("bad --tolerance", 0)
        elseif a == "--hard-tolerance" then o.hardTolerance = tonumber(val()) or error("bad --hard-tolerance", 0)
        elseif a == "--xp-optimism" then o.unknownXpOptimism = tonumber(val()) or error("bad --xp-optimism", 0)
        elseif a == "--incidental-pct" then
            local v = tonumber(val())
            if not v or v < 0 or v > 100 then error("bad --incidental-pct (a percent 0..100)", 0) end
            o.incidentalPct = v
        elseif a == "--ignore" then
            for c in val():gmatch("[^,%s]+") do o.ignore[c] = true end
        elseif a == "-v" or a == "--verbose" then o.verbose = true
        elseif a == "-q" or a == "--quiet" then o.quiet = true
        elseif a:sub(1, 1) == "-" then error("unknown option " .. a, 0)
        else o.dirs[#o.dirs + 1] = a end
        i = i + 1
    end
    if o.route and #Glob.Split(o.route) == 0 then error("--route needs a route id", 0) end
    return o
end

local function writeFile(path, text)
    local fh, err = io.open(path, "w")
    if not fh then error("cannot write " .. path .. ": " .. tostring(err), 0) end
    fh:write(text)
    fh:close()
end

-- results of real runs (no library-module entries)
local function runResults(all)
    local out = {}
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            if r.endState then out[#out + 1] = r end
        end
    end
    return out
end

---------------------------------------------------------------------------
-- checks on the whole run: DB overrides, ok-unused, own / foreign warnings
---------------------------------------------------------------------------

--- The "(overrides)" entry of a run: ERROR override-load for every override file that was ignored
-- (a note instead when a file filter is active: one agent's half-written file never stops another
-- agent) and ERROR override-foreign-quest when the override file of one owner names a quest that a
-- loaded step outside its owner files uses (DB.OverrideOwns; such a value belongs to shared.lua).
-- @param report DB.ApplyOverrides result; @param filtered true when --skip is given
-- @return a module result { module = "(overrides)", results = { res }, notes = {...} } or nil when
--         there is nothing to say
function V.OverrideChecks(db, all, report, filtered)
    local res = emptyResult("(overrides)", "(overrides)", tostring(report and report.dir or "-"))
    res.overrides = true
    local out = { module = "(overrides)", dir = report and report.dir, results = { res }, notes = {}, matched = 0 }
    for _, e in ipairs(report and report.errors or {}) do
        local m = { severity = "ERROR", code = "override-load", file = e.file,
                    msg = "the override file is ignored in this run: " .. tostring(e.msg) }
        if filtered then
            m.note = "a file filter (--skip) is active"
            out.notes[#out.notes + 1] = m
        else
            res.messages[#res.messages + 1] = m
            countMessage(res, m, 1)
        end
    end
    local ov = db._overrides
    if ov and next(ov.quests) ~= nil then
        local foreign, seen = {}, {} -- [quest] = { first = step, n = count }
        local function visit(step)
            for _, a in ipairs(step.actions or {}) do
                local rec = a.quest and ov.quests[a.quest]
                if rec and rec.owner ~= "shared" and not DB.OverrideOwns(rec.owner, step.file) then
                    local key = tostring(a.quest) .. "\0" .. tostring(step.file) .. "\0" .. tostring(step.id)
                    if not seen[key] then
                        seen[key] = true
                        local f = foreign[a.quest] or { first = step, n = 0 }
                        foreign[a.quest] = f
                        f.n = f.n + 1
                    end
                end
            end
        end
        for _, mres in ipairs(all) do
            local mod = mres.mod
            if mod then
                for _, seg in ipairs(mod.lib and mod.lib.order or {}) do
                    for _, step in ipairs(seg.steps) do visit(step) end
                end
                for _, ins in ipairs(mod.lib and mod.lib.inserts or {}) do
                    for _, step in ipairs(ins.steps) do visit(step) end
                end
                for _, route in ipairs(mod.routes) do
                    for _, step in ipairs(route.steps or {}) do
                        if not step.library then visit(step) end
                    end
                end
            end
        end
        for _, q in ipairs(sortedKeys(foreign)) do
            local f, rec = foreign[q], ov.quests[q]
            local b = DB.QuestBrief(db, q)
            local m = { severity = "ERROR", code = "override-foreign-quest", quest = q,
                file = tostring(report and report.dir or "tools/overrides") .. "/" .. rec.file,
                msg = format("%s overrides quest %d \"%s\", but %d loaded step(s) outside its owner files use the quest "
                    .. "(first: step '%s' in %s): a value for a quest of another file belongs to shared.lua (report it "
                    .. "in the hand-over)", rec.file, q, b and b.name or "?", f.n, tostring(f.first.id),
                    tostring(f.first.file)) }
            res.messages[#res.messages + 1] = m
            countMessage(res, m, 1)
        end
    end
    if #res.messages == 0 and #out.notes == 0 then return nil end
    return out
end

--- WARN ok-unused: a code listed in `ok` of a step / segment that was reported at that step in none of
-- the validated routes that contain it (a stale acknowledgement). Only meaningful on a full run (the
-- caller decides). The message goes to the entry of the module that owns a shared step (else to the
-- first route that contains the step).
-- @param all module results of V.ValidateModule; @param ignore set of ignored codes
function V.CheckOkUnused(all, ignore)
    local fired = {}
    local function key(modName, routeId, library, id)
        return (library and ("L\0" .. tostring(library)) or ("R\0" .. tostring(modName) .. "\0" .. tostring(routeId)))
            .. "\0" .. tostring(id)
    end
    local entry = {} -- [library module name] = its "(shared X)" / "(library X)" result
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            if r.shared or r.library then entry[r.shared or r.library] = entry[r.shared or r.library] or r end
            for _, m in ipairs(r.messages) do
                local id = m.stepId or (m.segment and ("segment " .. tostring(m.segment)))
                if id then
                    local k = key(mres.module, r.route, m.library, id)
                    fired[k] = fired[k] or {}
                    fired[k][m.code] = true
                end
            end
        end
    end
    local unused, order = {}, {}
    local function check(mres, rr, okT, library, id, where)
        local k = key(mres.module, rr.route.id, library, id)
        for _, code in ipairs(sortedKeys(okT)) do
            local plain = okT[code] == true and NEEDS_CEILING[code]
            if not plain and not (ignore and ignore[code]) and not (fired[k] and fired[k][code]) then
                local uk = k .. "\0" .. code
                local u = unused[uk]
                if not u then
                    u = { code = code, where = where, library = library, result = rr.results[1], routes = 0 }
                    unused[uk] = u
                    order[#order + 1] = u
                end
                u.routes = u.routes + 1
            end
        end
    end
    for _, mres in ipairs(all) do
        for _, rr in ipairs(mres.routes or {}) do
            for _, seg in ipairs(rr.route.segments or {}) do
                local lib = type(seg.library) == "string" and seg.library or nil
                if seg.ok then check(mres, rr, seg.ok, lib, "segment " .. tostring(seg.id), { segment = seg }) end
                for _, step in ipairs(seg.steps) do
                    if step.ok then
                        check(mres, rr, step.ok, type(step.library) == "string" and step.library or nil, step.id,
                            { step = step })
                    end
                end
            end
        end
    end
    local n = 0
    for _, u in ipairs(order) do
        local m = { severity = "WARN", code = "ok-unused" }
        local what
        if u.where.step then
            local step = u.where.step
            m.segment, m.step, m.stepId, m.file = step.segment, step.segIndex, step.id, step.file
            if step.inserted then m.inserted = true end
            what = "this step"
        else
            m.segment, m.file = u.where.segment.id, u.where.segment.file
            what = "this segment"
        end
        if u.library then m.library, m.shared = u.library, true end
        m.msg = format("ok lists '%s', but none of the %d validated route(s) containing %s reports it there: remove "
            .. "the acknowledgement", u.code, u.routes, what)
        local target = (u.library and entry[u.library]) or u.result
        if target then
            target.messages[#target.messages + 1] = m
            countMessage(target, m, 1)
            n = n + 1
        end
    end
    return n
end

--- --own: mark the unaccepted WARNs whose file is not own (m.foreign = true, r.foreign = count).
-- A message without a file belongs to the file that registered the route (Route.lua).
-- @return the number of foreign warnings
function V.MarkForeign(all, isOwn)
    local total = 0
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            r.foreign = 0
            for _, m in ipairs(r.messages) do
                if m.severity == "WARN" and not m.accepted and isOwn and not isOwn(m.file or r.file or "") then
                    m.foreign = true
                    r.foreign = r.foreign + 1
                end
            end
            total = total + r.foreign
        end
    end
    return total
end

--- The block "foreign warnings: N (report them in the hand-over)": one line per place and code.
function V.ForeignLines(all)
    local lines, seen, order, total = {}, {}, {}, 0
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            for _, m in ipairs(r.messages) do
                if m.foreign then
                    total = total + 1
                    -- a message of the route itself (no step, no segment: route-level) is one line per
                    -- route, named; a place in a file is one line for all the routes that pass it
                    local loc = locStr(m)
                    if not m.segment and not m.stepId then
                        local file = m.file or r.file
                        loc = format("route %s%s", tostring(r.route), file and (" (" .. file .. ")") or "")
                    end
                    local k = loc .. "\0" .. m.code
                    if not seen[k] then
                        seen[k] = { m = m, n = 0, loc = loc }
                        order[#order + 1] = seen[k]
                    end
                    seen[k].n = seen[k].n + 1
                end
            end
        end
    end
    if total == 0 then return lines end
    lines[1] = format("foreign warnings: %d (report them in the hand-over)", total)
    for _, e in ipairs(order) do
        lines[#lines + 1] = format("  WARN  %s [%s] %s%s", e.loc, e.m.code, e.m.msg,
            e.n > 1 and format(" (%d route(s) / profile(s))", e.n) or "")
    end
    return lines
end

--- --summary: one TSV line per run result (route, profile, errors, warnings, accepted, foreign, end
-- level, worst-case end level, grind kills, worst-case grind kills, grind kills up to --grind-until,
-- the same in the worst case).
function V.SummaryLines(all)
    local lines = {}
    for _, r in ipairs(runResults(all)) do
        local sm = r.summary or {}
        local gu = sm.grindUntil
        lines[#lines + 1] = table.concat({
            tostring(r.route), r.profileLabel, tostring(r.counts.ERROR), tostring(r.counts.WARN - (r.foreign or 0)),
            tostring(r.acceptedWarn or 0), tostring(r.foreign or 0), format("%.2f", sm.endLevel or 0),
            format("%.2f", sm.endLevelWorst or sm.endLevel or 0), tostring(sm.grindKills or 0),
            tostring(sm.grindKillsWorst or 0), gu and tostring(gu.kills) or "-", gu and tostring(gu.killsWorst) or "-",
        }, "\t")
    end
    return lines
end

--- --levels: one TSV line per step with an explicit id of a result (V.RunProfile with opts.levels).
function V.LevelLines(r)
    local lines = {}
    for _, e in ipairs(r.stepLevels or {}) do
        lines[#lines + 1] = table.concat({
            tostring(e.id), tostring(e.segment), format("%.2f", e.level or 0),
            format("%.2f", e.levelWorst or e.level or 0), e.anchor and tostring(e.anchor) or "-",
            tostring(e.file or "-"), e.actions or "",
        }, "\t")
    end
    return lines
end

--- The --skip / --keep / --own globs of a run that match no file (a typo or a wrong case would
-- otherwise pass without a word: the file filter leaves out nothing or the wrong files, and with an
-- --own that matches nothing every warning is foreign, so --strict passes on anything).
-- --skip / --keep are matched against the TOC files of the modules, --own against the files that
-- were loaded (dependencies included: the file names messages carry).
-- @param mods loaded modules (Loader.LoadModule); @param o { skip, keep, own } (lists of globs)
-- @return array of lines ("--own 'Classes/Warior.lua' matches no loaded file ..."), {} when all match
function V.UnmatchedFileGlobs(mods, o)
    local dirs, loaded, skipped, names = {}, {}, {}, {}
    for _, mod in ipairs(mods) do
        if not mod.toc then return {} end -- no TOC: the load error says so, there is nothing to match
        dirs[#dirs + 1] = mod.dir
        names[#names + 1] = tostring(mod.name)
        loaded[#loaded + 1] = mod.loadedFiles
        skipped[#skipped + 1] = mod.skipped
    end
    if #mods == 0 then return {} end
    local out = Loader.UnmatchedFilters(dirs, o.skip, o.keep)
    for _, g in ipairs(Glob.UnmatchedIn(o.own, loaded)) do
        local onlySkipped = #Glob.UnmatchedIn({ g }, skipped) == 0
        out[#out + 1] = format("--own '%s' matches no loaded file of %s%s: every warning would be foreign", g,
            table.concat(names, ", "), onlySkipped and " (it only matches files that --skip leaves out: add --keep)"
            or " (the match is case-sensitive, `*` is the only wildcard)")
    end
    return out
end

--- CLI entry. @param argv array of arguments; @param root repository root
-- @return exit code
function V.Main(argv, root)
    root = root or "."
    local ok, o = pcall(V.ParseArgs, argv or {})
    if not ok then
        io.stderr:write("validate_routes: " .. tostring(o) .. "\n" .. USAGE .. "\n")
        return 2
    end
    if o.help then print(USAGE) return 0 end
    if o.harness and (#o.dirs > 0 or o.route) then
        io.stderr:write("validate_routes: --harness takes no module directories and no --route (the module "
            .. "is its value, the route is synthetic)\n")
        return 2
    end
    if o.segments and not o.harness then
        io.stderr:write("validate_routes: --segments is only used with --harness\n")
        return 2
    end
    if o.untilId and not o.writeState then
        io.stderr:write("validate_routes: --until is only used with --write-state\n")
        return 2
    end
    local harnessProfile
    if o.harness then
        local perr
        harnessProfile, perr = Harness.Profile(o.profile)
        if not harnessProfile then
            io.stderr:write("validate_routes: " .. perr .. "\n")
            return 2
        end
    end
    local startState
    if o.state then
        local errs
        startState, errs = Harness.ReadState(o.state)
        if not startState then
            io.stderr:write("validate_routes: " .. table.concat(errs, "\nvalidate_routes: ") .. "\n")
            return 2
        end
    end
    local baseline
    if o.baseline then
        local berr
        baseline, berr = V.ReadBaseline(o.baseline)
        if not baseline then
            io.stderr:write("validate_routes: --baseline: " .. tostring(berr) .. "\n")
            return 2
        end
    end
    local okDb, db = pcall(DB.Load, o.db or (root .. "/tools/data/forever_db.lua"))
    if not okDb then io.stderr:write("validate_routes: " .. tostring(db) .. "\n") return 2 end
    -- DB overrides (corrections of single quests / NPCs; never for specs: DB.Load applies none)
    local overrides
    if not o.noOverrides then overrides = DB.ApplyOverrides(db, o.overrides or DB.OverridesDir(root)) end
    local okS, schema = pcall(Loader.LoadSchema, root)
    if not okS then io.stderr:write("validate_routes: " .. tostring(schema) .. "\n") return 2 end
    local routeList = o.route and Glob.NewList(o.route) or nil
    local isOwn
    if o.own then
        isOwn = function(file) return Glob.Any(o.own, tostring(file or "")) end
    end
    local function runOpts(extra)
        local opts = {
            db = db, schema = schema, route = o.route, routeList = routeList, profile = o.profile,
            tolerance = o.tolerance,
            hardTolerance = o.hardTolerance, toleranceYards = o.toleranceYards,
            hardToleranceYards = o.hardToleranceYards, ignore = o.ignore, unknownXpOptimism = o.unknownXpOptimism,
            startState = startState, incidentalPct = o.incidentalPct, untilId = o.untilId,
            isOwn = isOwn, ownGiven = o.own ~= nil, endLevel = o.endLevel, grindUntil = o.grindUntil,
            maxGrindUntil = o.maxGrindUntil, baseline = baseline, levels = o.levels,
        }
        for k, v in pairs(extra or {}) do opts[k] = v end
        return opts
    end
    local all, dirs = {}, o.dirs
    -- a --skip / --keep / --own glob that matches nothing is a typo: the caller's file would be left
    -- out, or every warning would be foreign and --strict would pass on anything
    local function globsMatch(mods)
        local bad = V.UnmatchedFileGlobs(mods, o)
        for _, line in ipairs(bad) do io.stderr:write("validate_routes: " .. line .. "\n") end
        return #bad == 0
    end
    if o.harness then
        local hb = Harness.Build(o.harness, { schema = schema, segments = o.segments, profile = harnessProfile,
            skipGlobs = o.skip, keepGlobs = o.keep })
        if hb.fatal then
            io.stderr:write("validate_routes: harness: " .. hb.fatal .. "\n")
            return 2
        end
        if not globsMatch({ hb.mod }) then return 2 end
        if hb.empty then
            print(("validate_routes: harness: library module %s registers no library segments yet (its segment "
                .. "files are placeholders); nothing to validate"):format(hb.mod.name))
            for _, e in ipairs(hb.mod.errors) do print(("  ERROR %s: %s"):format(tostring(e.file), tostring(e.msg))) end
            return #hb.mod.errors > 0 and 1 or 0
        end
        all[1] = V.ValidateHarness(hb, runOpts({ profile = harnessProfile }))
        dirs = { o.harness }
    else
        if #dirs == 0 then dirs = Loader.DiscoverModules(o.addons or (root .. "/addons")) end
        -- load every module first: library modules of the run report their own load / schema
        -- errors once (in their entry); route modules depending on them do not repeat them
        local loaded, libraryReported = {}, {}
        for i, dir in ipairs(dirs) do
            loaded[i] = Loader.LoadModule(dir, { schema = schema, skipGlobs = o.skip, keepGlobs = o.keep })
            if loaded[i].isLibrary and not o.route then libraryReported[loaded[i].name] = true end
        end
        if not globsMatch(loaded) then return 2 end
        for i, dir in ipairs(dirs) do
            if not (o.route and loaded[i].isLibrary) then
                all[#all + 1] = V.ValidateModule(dir, runOpts({ module = loaded[i], libraryReported = libraryReported }))
            end
        end
    end
    -- checks on the whole run
    local fullRun = not (o.harness or o.route or o.skip or o.profile or startState)
    if fullRun then V.CheckOkUnused(all, o.ignore) end
    if overrides then
        local entry = V.OverrideChecks(db, all, overrides, o.skip ~= nil)
        if entry then all[#all + 1] = entry end
    end
    local foreign = V.MarkForeign(all, isOwn)
    local te, tw, ta = 0, 0, 0
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            te, tw, ta = te + r.counts.ERROR, tw + r.counts.WARN, ta + (r.acceptedWarn or 0)
        end
    end
    if o.quiet then
        for _, mres in ipairs(all) do
            for _, r in ipairs(mres.results) do
                print(format("%s [%s]: %s%s", tostring(r.route), r.profileLabel, countsText(r),
                    (r.foreign or 0) > 0 and format(" (%d of the warnings foreign)", r.foreign) or ""))
            end
            for _, line in ipairs(V.NoteLines(mres)) do print(line) end
        end
    else
        for _, line in ipairs(V.FormatText(all, { verbose = o.verbose })) do print(line) end
    end
    for _, line in ipairs(V.ForeignLines(all)) do print(line) end
    if #dirs == 0 then print("no route modules found") end
    if overrides and (#overrides.files > 0 or #overrides.errors > 0) then
        local names, nq, nn = {}, 0, 0
        for i, f in ipairs(overrides.files) do
            names[i] = f.file
            nq, nn = nq + f.quests, nn + f.npcs
        end
        print(format("validate_routes: DB overrides from %s: %d file(s)%s, %d quest(s), %d npc(s)%s",
            tostring(overrides.dir), #overrides.files, #names > 0 and (" (" .. table.concat(names, ", ") .. ")") or "",
            nq, nn, #overrides.errors > 0 and format("; %d file(s) ignored", #overrides.errors) or ""))
    end
    print(format("validate_routes: %d module(s), %d error(s), %d warning(s)%s%s%s%s", #dirs, te, tw,
        ta > 0 and format(", %d accepted", ta) or "",
        foreign > 0 and format(" (%d of them foreign)", foreign) or "",
        o.strict and " (strict)" or "", startState and (" (start state " .. o.state .. ")") or ""))
    if o.json then writeFile(o.json, json.encode(V.ReportTable(all, db), "  ") .. "\n") end
    if o.markdown then writeFile(o.markdown, table.concat(V.FormatMarkdown(all, db), "\n") .. "\n") end
    if routeList then
        local unmatched = Glob.Unmatched(routeList)
        if #unmatched > 0 then
            io.stderr:write("validate_routes: --route " .. table.concat(unmatched, ",") .. " matched no route\n")
            return 2
        end
    end
    if o.grindUntil then
        -- a segment id no validated route contains (a typo, a renamed segment): the columns and the
        -- baseline pair would silently be missing
        local runs, found = runResults(all), false
        for _, r in ipairs(runs) do
            if r.summary and r.summary.grindUntil then found = true break end
        end
        if #runs > 0 and not found then
            io.stderr:write(format("validate_routes: --grind-until %s: none of the %d validated route(s) has a segment "
                .. "with this id\n", o.grindUntil, #runs))
            return 2
        end
    end
    if o.writeBaseline then
        writeFile(o.writeBaseline, json.encode(V.Baseline(all, { grindUntil = o.grindUntil
            or (o.maxGrindUntil and o.maxGrindUntil.segment) }), "  ") .. "\n")
    end
    if o.writeState then
        local runs = runResults(all)
        if o.harness and #runs == 0 then
            io.stderr:write("validate_routes: no end state written: the harness route has no segment to run\n")
            return te > 0 and 1 or 2
        end
        if #runs ~= 1 then
            io.stderr:write(format("validate_routes: --write-state needs exactly one route x profile, this run has %d "
                .. "(select one with --route ID and --profile race=,class=,faction=)\n", #runs))
            return 2
        end
        if o.untilId and not runs[1].untilMatched then
            io.stderr:write(format("validate_routes: --until %s matched no step id and no segment id of %s\n",
                o.untilId, tostring(runs[1].route)))
            return 2
        end
        local wok, werr = Harness.WriteState(o.writeState, runs[1].endState)
        if not wok then io.stderr:write("validate_routes: " .. tostring(werr) .. "\n") return 2 end
        local es = runs[1].endState
        print(format("validate_routes: %s of %s [%s] written to %s: level %d + %.2f, %d done, %d in the log "
            .. "(%d complete), hearth %s", o.untilId and ("state before " .. o.untilId) or "end state",
            tostring(runs[1].route), runs[1].profileLabel, o.writeState, es.level,
            es.xpFrac, #es.done, #es.log, #es.complete, tostring(es.hearth or "-")))
    end
    if o.levels then
        local runs = runResults(all)
        if #runs ~= 1 then
            io.stderr:write(format("validate_routes: --levels needs exactly one route x profile, this run has %d "
                .. "(select one with --route ID)\n", #runs))
            return 2
        end
        for _, line in ipairs(V.LevelLines(runs[1])) do print(line) end
    end
    if o.summary then
        for _, line in ipairs(V.SummaryLines(all)) do print(line) end
    end
    if te > 0 or (o.strict and tw - foreign > 0) then return 1 end
    return 0
end

return V
