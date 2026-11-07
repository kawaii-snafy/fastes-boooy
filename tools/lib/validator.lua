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

local DB = require("lib.fbdb")
local Loader = require("lib.route_loader")
local json = require("lib.json")

local V = {}

V.DEFAULTS = {
    -- distance from `at` to an NPC / object spawn (or the nearest quest giver / ender):
    toleranceYards = 40,      -- yards: WARN above
    hardToleranceYards = 120, -- yards: ERROR above
    -- fallback for maps without known world size (zones[uiMap].size, e.g. Zephras Isle 2521):
    tolerance = 3.0,          -- map percent (approximate): WARN above
    hardTolerance = 8.0,      -- map percent (approximate): ERROR above
    grindWarnKills = 30,    -- level step: WARN when more estimated kills are needed
    defaultKillCount = 8,   -- creature objective without a known count
    dropKillFactor = 1.5,   -- kills per required drop item (drop rates are not in the DB)
    -- optimistic parallel simulation: a level requirement is an ERROR only when even the
    -- optimistic level is too low, otherwise a WARN (the shortfall may be an estimation artifact)
    unknownXpOptimism = 2.0,  -- unknown (estimated) quest XP x2
    guessedKillOptimism = 1.5, -- objective kills whose count was assumed x1.5
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

local function round2(v)
    return floor(v * 100 + 0.5) / 100
end

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
        messages = {}, counts = { ERROR = 0, WARN = 0, INFO = 0 }, suppressed = 0,
        st = { level = 1, xp = 0 },
        opt = { level = 1, xp = 0 }, -- optimistic simulation (see V.DEFAULTS.unknownXpOptimism)
        active = {}, activeCount = 0, maxLog = 0,
        accepted = {}, turnedIn = {}, abandoned = {}, completed = {}, credited = {},
        collected = {}, hearth = nil,
        xp = { quest = 0, questEstimated = 0, kill = 0, grind = 0, grindKills = 0,
               unknownXpQuests = 0, turnins = 0, accepts = 0 },
        segments = {}, seg = nil,
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
    return r
end

function Run:add(sev, code, step, msg, ...)
    if self.opts.ignore and self.opts.ignore[code] then
        self.suppressed = self.suppressed + 1
        return
    end
    local m = {
        severity = sev, code = code, msg = select("#", ...) > 0 and format(msg, ...) or msg,
    }
    if step then
        m.segment = step.segment
        m.step = step.segIndex
        m.stepId = step.id
        m.file = step.file
    elseif self.seg then
        m.segment = self.seg.id
        m.file = self.seg.file
    end
    self.messages[#self.messages + 1] = m
    self.counts[sev] = self.counts[sev] + 1
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
    for _, e in ipairs(o.creatures or {}) do out[#out + 1] = { kind = "creature", id = e[1], count = e[2] } end
    for _, e in ipairs(o.killCredit or {}) do
        out[#out + 1] = { kind = "killCredit", id = e.base or (e.ids and e.ids[1]), ids = e.ids, count = e.count }
    end
    for _, e in ipairs(o.objects or {}) do out[#out + 1] = { kind = "object", id = e[1], count = e[2] } end
    for _, e in ipairs(o.items or {}) do out[#out + 1] = { kind = "item", id = e[1], count = e[2] } end
    return out
end

function Run:friendly(npc)
    if not self.letter then return true end
    return (npc.faction or ""):find(self.letter, 1, true) ~= nil
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

function Run:checkDistance(step, ent, at, label)
    local d, isYards, nx, ny = self:nearestSpawn(ent.spawns, at)
    if not d then
        local zone = self.db.zones[at.map]
        if ent.instance and #ent.instance > 0 and zone and zone.dungeon then
            self:add("INFO", "at-instance", step, "%s is inside an instance; position on uiMap %d not checkable",
                label, at.map)
            return
        end
        local maps = {}
        for _, m in ipairs(DB.SpawnMaps(ent.spawns)) do
            maps[#maps + 1] = format("%d %s", m, DB.ZoneName(self.db, m))
        end
        self:add("ERROR", "at-no-spawn", step, "%s has no spawn on uiMap %d (%s); spawns on: %s", label, at.map,
            DB.ZoneName(self.db, at.map), #maps > 0 and table.concat(maps, "; ") or "none known")
        return
    end
    local slack = ent.spawnsGrid and ent.spawnsGrid * math.sqrt(2) or nil
    local sev, text = self:distanceSeverity(at.map, d, isYards, slack)
    if sev then
        self:add(sev, "at-far", step, "%s is %s from at {%d, %.1f, %.1f} (nearest spawn %.2f, %.2f%s)",
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
                self:add("WARN", "npc-out-of-scope", step, "NPC %s exists but is outside the DB snapshot scope "
                    .. "(zone area %s); position/flags not checked", self:nn(id), tostring(b.zone))
            else
                self:add("ERROR", "npc-unknown", step, "NPC %d does not exist in the Forever DB", id)
            end
        elseif mapOk then
            self:checkDistance(step, n, at, "NPC " .. self:nn(id))
        end
    end
    for _, id in ipairs(step.object or {}) do
        local o = db.objects[id]
        if not o then
            local b = DB.ObjectBrief(db, id)
            if b then
                self:add("WARN", "object-out-of-scope", step, "object %s exists but is outside the DB snapshot scope; "
                    .. "position not checked", self:on(id))
            else
                self:add("ERROR", "object-unknown", step, "object %d does not exist in the Forever DB", id)
            end
        elseif mapOk then
            self:checkDistance(step, o, at, "object " .. self:on(id))
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
                        self:add("WARN", "at-far-from-giver", step, "%s %s: no %s spawns on uiMap %d", a.type,
                            self:qn(a.quest), who, at.map)
                    else
                        local sev, text = self:distanceSeverity(at.map, best, bestYd)
                        if sev then
                            -- no npc/object on the step: the giver is a guess, never more than a WARN
                            self:add("WARN", "at-far-from-giver", step, "%s %s: nearest %s is %s from at",
                                a.type, self:qn(a.quest), who, text)
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
        self:add("WARN", "xp-unknown", step, "turnin %s: quest XP unknown in the DB (Forever-new quest?); estimated "
            .. "%d (median of level-%d quests). Record the real value in game with /fb xp", self:qn(id), base,
            q.level or 0)
    end
    local gained = DB.QuestXp(self.db, base, q.level, self.st.level)
    local optBase = estimated and base * (self.opts.unknownXpOptimism or V.DEFAULTS.unknownXpOptimism) or base
    local optGained = DB.QuestXp(self.db, optBase, q.level, self.opt.level)
    if estimated then self.xp.questEstimated = self.xp.questEstimated + gained end
    self:gainXp(gained, "quest", optGained)
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
end

function H.accept(self, a, step)
    local id = a.quest
    local q, full = self:quest(id, step, "accept")
    if not q then return end
    self:checkAvailability(id, q, step)
    if (q.reqLevel or 0) > self.st.level then
        if q.reqLevel > self:optLevel() then
            local hint = ""
            if self.xp.unknownXpQuests > 0 then
                hint = format(" (the simulation includes %d estimated quest XP values; if the real XP is higher, add "
                    .. "a 'level' step here - it completes instantly in game when reached)", self.xp.unknownXpQuests)
            end
            self:add("ERROR", "level-too-low", step, "accept %s: requires level %d, simulated level is %s%s", self:qn(id),
                q.reqLevel, self:levelStr(), hint)
        else
            self:add("WARN", "level-too-low-estimated", step, "accept %s: requires level %d, simulated level is %s "
                .. "(level %d is reachable only if the estimated XP is too low: unknown quest XP / assumed kill counts; "
                .. "consider a 'level' step)", self:qn(id), q.reqLevel, self:levelStr(), self:optLevel())
        end
    end
    if full and q.maxLevel and q.maxLevel > 0 and self.st.level > q.maxLevel then
        self:add("ERROR", "level-too-high", step, "accept %s: maximum level %d, simulated level is %s", self:qn(id),
            q.maxLevel, self:levelStr())
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
                self:add("ERROR", "accept-prereq", step, "accept %s: requires ONE of these quests turned in first: %s",
                    self:qn(id), self:names(q.preSingle, Run.qn))
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
    for _, idx in ipairs(selected) do
        local e = list[idx]
        if not credited[idx] then
            credited[idx] = true
            if e.kind == "creature" or e.kind == "killCredit" then
                local n, nOpt = e.count, e.count
                if not n then
                    n = opts.defaultKillCount or V.DEFAULTS.defaultKillCount
                    nOpt = math.ceil(n * (opts.guessedKillOptimism or V.DEFAULTS.guessedKillOptimism))
                    guessed = true
                end
                local x = self:killXp(e.id, n, nOpt)
                killsTotal, xpTotal = killsTotal + n, xpTotal + x
            elseif e.kind == "item" then
                self.collected[e.id] = true
                local it = self.db.items[e.id]
                local mob
                for _, m in ipairs(it and it.npcDrops or {}) do
                    if self.db.npcs[m] and self.db.npcs[m].spawns then mob = m break end
                end
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
    if killsTotal > 0 then
        self:add("INFO", "complete-kill-xp", step, "complete %s: ~%d kills, +%d kill XP (estimate%s); level now %s",
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
    if cur >= target then return end
    local before = self:levelStr()
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
    if self.seg then
        local s = self.segments[#self.segments]
        s.xpGrind = (s.xpGrind or 0) + gained
        s.grindKills = (s.grindKills or 0) + kills
    end
    local warnAt = self.opts.grindWarnKills or V.DEFAULTS.grindWarnKills
    self:add(kills > warnAt and "WARN" or "INFO", "level-grind", step,
        "level %d%s: simulated level %s is short by %d XP; ~%d same-level kills needed (estimate)", a.level,
        (a.frac or 0) > 0 and format(" +%d%%", floor(a.frac * 100 + 0.5)) or "", before, gained, kills)
end

function Run:serviceNpcs(step, what)
    local out = {}
    for _, id in ipairs(step.npc or {}) do
        local n = self.db.npcs[id]
        if n then
            if not self:friendly(n) then
                self:add("ERROR", "npc-hostile", step, "%s NPC %s is not friendly to the %s (faction '%s')", what,
                    self:nn(id), self.profile.faction or "?", n.faction or "")
            end
            out[#out + 1] = { id = id, npc = n }
        end
    end
    return out
end

function H.train(self, _, step)
    if not step.npc then
        self:add("WARN", "train-no-npc", step, "train step without npc (trainer cannot be checked)")
        return
    end
    local cls = self.profile.class and CLASS_NAMES[self.profile.class]
    for _, e in ipairs(self:serviceNpcs(step, "trainer")) do
        local n = e.npc
        local sub = (n.sub or ""):lower()
        local flags = n.flags or {}
        if cls then
            local c = cls:lower()
            local ok = sub:find(c .. " trainer", 1, true) or (flags.trainer and sub:find(c, 1, true))
            if not ok then
                local otherClass = false
                for _, name in pairs(CLASS_NAMES) do
                    if sub:find(name:lower(), 1, true) then otherClass = true end
                end
                if flags.trainer and sub:find("trainer", 1, true) and not otherClass then
                    self:add("WARN", "train-not-class-trainer", step, "train: NPC %s is a trainer (\"%s\") but not a "
                        .. "%s trainer (profession/riding trainer?)", self:nn(e.id), n.sub or "", cls)
                else
                    self:add("ERROR", "train-wrong-trainer", step, "train: NPC %s (\"%s\") is not a %s trainer",
                        self:nn(e.id), n.sub or "", cls)
                end
            end
        elseif not flags.trainer then
            self:add("ERROR", "train-wrong-trainer", step, "train: NPC %s is not a trainer", self:nn(e.id))
        end
    end
end

local function flightCheck(self, a, step)
    if not step.npc then
        if a.type == "fp" then
            self:add("INFO", "fp-no-npc", step, "fp %s: no flight master npc on the step", a.place)
        end
        return
    end
    for _, e in ipairs(self:serviceNpcs(step, "flight master")) do
        if not (e.npc.flags and e.npc.flags.flightmaster) then
            self:add("ERROR", "not-flightmaster", step, "%s %s: NPC %s is not a flight master", a.type, a.place,
                self:nn(e.id))
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
            self:add("ERROR", "not-innkeeper", step, "sethearth %s: NPC %s is not an innkeeper", a.place, self:nn(e.id))
        end
    end
    self.hearth = a.place
end

function H.hearth(self, a, step)
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
            self:add("WARN", "not-vendor", step, "vendor: NPC %s is not a vendor", self:nn(e.id))
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
            self:add("WARN", "segment-level", nil, "segment %s ends at simulated level %.2f; planned end level %d",
                tostring(seg.id), lv, planned)
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

function Run:processStep(step)
    if not self.schema.FiltersMatch(step.filters, self.facts) then
        self:add("INFO", "step-skipped", step, "step filtered out for %s (class/race/faction filter)",
            profileLabel(self.profile))
        if self.seg then
            local s = self.segments[#self.segments]
            s.skipped = s.skipped + 1
        end
        return
    end
    self:checkEntities(step)
    for _, a in ipairs(V.OrderedActions(step)) do
        local h = H[a.type]
        if h then h(self, a, step) end
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
    for _, id in ipairs(sortedKeys(self.active)) do
        self:add("WARN", "quest-carried", self.active[id].step, "quest %s is still in the quest log at the end of the "
            .. "route (never turned in or abandoned)", self:qn(id))
    end
    local lv = DB.LevelValue(self.db, self.st)
    if route.levels and math.abs(lv - route.levels[2]) > 1 then
        self:add("WARN", "route-level", nil, "route ends at simulated level %.2f; planned end level %d", lv,
            route.levels[2])
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
        segments = self.segments,
        summary = {
            endLevel = round2(DB.LevelValue(self.db, self.st)),
            endLevelOptimistic = round2(math.max(DB.LevelValue(self.db, self.opt), DB.LevelValue(self.db, self.st))),
            level = self.st.level, xpIntoLevel = self.st.xp,
            plannedLevels = self.route.levels,
            xpQuest = self.xp.quest, xpQuestEstimated = self.xp.questEstimated,
            xpKill = self.xp.kill, xpGrind = self.xp.grind, grindKills = self.xp.grindKills,
            unknownXpQuests = self.xp.unknownXpQuests, accepts = self.xp.accepts, turnins = self.xp.turnins,
            maxQuestLog = self.maxLog, carried = carried, steps = #self.route.steps,
        },
    }
end

---------------------------------------------------------------------------
-- module / CLI
---------------------------------------------------------------------------

--- Route-level checks (once per route, not per profile): race tokens of the route and of
-- the step filters must be UnitRace() raceFiles known to the DB ("Scourge", not "Undead"),
-- and every filtered step should match at least one of the route's profiles.
-- @return array of messages { severity, code, msg, segment, step, stepId, file }
function V.RouteChecks(db, route, profiles)
    local out = {}
    local known = db.enums and db.enums.raceFileToBit or {}
    local function add(sev, code, step, msg, ...)
        local m = { severity = sev, code = code, msg = format(msg, ...) }
        if step then
            m.segment, m.step, m.stepId, m.file = step.segment, step.segIndex, step.id, step.file
        end
        out[#out + 1] = m
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
        local f = step.filters
        local bad = false
        for _, tok in ipairs(sortedKeys(f and f.race)) do
            if known[tok] == nil then
                bad = true
                add("ERROR", "unknown-race-token", step, "step race filter: unknown raceFile '%s'%s", tostring(tok),
                    hint(tok))
            end
        end
        if f and not bad then
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
                add("WARN", "step-no-profile", step, "step matches none of the route's profiles (%s): it is never shown",
                    table.concat(labels, "; "))
            end
        end
    end
    return out
end

--- Validate every route of a module directory.
-- @param opts { db, schema, route = id filter, profile = override, tolerance, hardTolerance, ignore = set }
function V.ValidateModule(dir, opts)
    local mod = Loader.LoadModule(dir, { schema = opts.schema })
    local out = { module = mod.name, dir = dir, loadErrors = mod.errors, results = {} }
    out.matched = 0
    for _, route in ipairs(mod.routes) do
        if not opts.route or opts.route == route.id then
            out.matched = out.matched + 1
            local profiles = V.Profiles(route, opts.profile)
            local first
            for _, profile in ipairs(profiles) do
                local run = V.NewRun(opts.db, opts.schema, route, profile, opts)
                local res = run:execute()
                first = first or res
                out.results[#out.results + 1] = res
            end
            -- route-level messages are reported once per route (first profile)
            if first then
                local extra = {}
                for _, m in ipairs(V.RouteChecks(opts.db, route, profiles)) do
                    if opts.ignore and opts.ignore[m.code] then
                        first.suppressed = (first.suppressed or 0) + 1
                    else
                        extra[#extra + 1] = m
                        first.counts[m.severity] = first.counts[m.severity] + 1
                    end
                end
                for _, m in ipairs(first.messages) do extra[#extra + 1] = m end
                first.messages = extra
            end
        end
    end
    if #mod.errors > 0 then
        -- attach load/schema errors to the first result (or a synthetic one)
        local target = out.results[1]
        if not target then
            target = { route = "(module " .. mod.name .. ")", module = mod.name, profileLabel = "-", messages = {},
                       counts = { ERROR = 0, WARN = 0, INFO = 0 }, suppressed = 0, segments = {}, summary = {} }
            out.results[1] = target
        end
        local schemaMsgs = {}
        for _, e in ipairs(mod.errors) do
            schemaMsgs[#schemaMsgs + 1] = { severity = "ERROR", code = "schema", file = e.file, msg = e.msg }
        end
        for _, m in ipairs(target.messages) do schemaMsgs[#schemaMsgs + 1] = m end
        target.messages = schemaMsgs
        target.counts.ERROR = target.counts.ERROR + #mod.errors
    end
    return out
end

local function locStr(m)
    local parts = {}
    if m.segment then
        parts[#parts + 1] = m.step and format("%s#%d", tostring(m.segment), m.step) or tostring(m.segment)
    end
    if m.stepId and m.segment and m.stepId ~= format("%s:%d", tostring(m.segment), m.step or 0) then
        parts[#parts + 1] = "id=" .. m.stepId
    end
    if m.file then parts[#parts + 1] = "(" .. m.file .. ")" end
    if #parts == 0 then return "route" end
    return table.concat(parts, " ")
end
V.LocStr = locStr

local function textOf(t)
    if type(t) == "table" then return t.en or t.ru or "" end
    return t and tostring(t) or ""
end

--- Human-readable report lines.
function V.FormatText(all, opts)
    opts = opts or {}
    local lines = {}
    local function w(s) lines[#lines + 1] = s end
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            w(format("== route %s [%s] module %s", tostring(r.route), r.profileLabel, tostring(mres.module)))
            for _, m in ipairs(r.messages) do
                if m.severity ~= "INFO" or opts.verbose then
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
                w(format("  end level %.2f (optimistic %.2f, planned %s); quest XP %d (%d estimated, %d quests with "
                    .. "unknown XP), kill XP %d (estimate), grind XP %d (~%d kills); max quest log %d; carried %d",
                    sm.endLevel, sm.endLevelOptimistic or sm.endLevel,
                    sm.plannedLevels and tostring(sm.plannedLevels[2]) or "-", sm.xpQuest,
                    sm.xpQuestEstimated, sm.unknownXpQuests, sm.xpKill, sm.xpGrind, sm.grindKills, sm.maxQuestLog,
                    #(sm.carried or {})))
            end
            w(format("  result: %d error(s), %d warning(s), %d info%s", r.counts.ERROR, r.counts.WARN, r.counts.INFO,
                (r.suppressed or 0) > 0 and format(", %d suppressed", r.suppressed) or ""))
            w("")
        end
    end
    return lines
end

local function mdEscape(s)
    return (tostring(s):gsub("|", "\\|"):gsub("\n", " "))
end

--- Markdown report (docs/VALIDATION.md).
function V.FormatMarkdown(all, db)
    local L = {}
    local function w(s) L[#L + 1] = s end
    local meta = db.meta or {}
    w("# Отчёт валидатора маршрутов")
    w("")
    w("<!-- GENERATED by tools/validate_routes.lua --markdown docs/VALIDATION.md (make report). DO NOT EDIT. -->")
    w("")
    w(format("Снимок БД: World of Warcraft: Forever %s.%s (Interface %s), дата снимка %s, `%s`.",
        tostring(meta.build and meta.build[1]), tostring(meta.build and meta.build[2]), tostring(meta.interface),
        tostring(meta.generated), "tools/data/forever_db.lua"))
    w("")
    w("Как читать: **ERROR** — маршрут сломан (квест недоступен, не тот NPC, нарушена цепочка, переполнен журнал, "
        .. "уровень ниже требуемого); **WARN** — вероятная проблема (NPC далеко от точки `at`, опыт квеста неизвестен "
        .. "и оценён, квест не сдан к концу маршрута); **INFO** — справка (пропущенные по фильтру шаги, оценки "
        .. "опыта за убийства). Симуляция опыта — оценка: опыт квестов из БД (для новых квестов Forever — медиана "
        .. "по уровню), опыт за мобов — формула Classic со штрафом Forever за «зелёных» мобов, без rested-бонуса.")
    w("")
    w("Перегенерировать: `make report` (или `lua5.1 tools/validate_routes.lua --markdown docs/VALIDATION.md`).")
    w("")
    local te, tw, ti = 0, 0, 0
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            te, tw, ti = te + r.counts.ERROR, tw + r.counts.WARN, ti + r.counts.INFO
        end
    end
    w(format("**Итого: %d ERROR, %d WARN, %d INFO.**", te, tw, ti))
    w("")
    if #all == 0 then
        w("_Модули маршрутов не найдены._")
    end
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            w(format("## %s — %s", mdEscape(r.route), mdEscape(textOf(r.title))))
            w("")
            w(format("Модуль `%s`, профиль: %s. Результат: **%d ERROR, %d WARN, %d INFO**.", tostring(mres.module),
                r.profileLabel, r.counts.ERROR, r.counts.WARN, r.counts.INFO))
            w("")
            local sm = r.summary or {}
            if sm.endLevel then
                w(format("Симуляция: конец маршрута на уровне **%.2f** (оптимистично %.2f; план %s); опыт квестов %d "
                    .. "(из них оценено %d; "
                    .. "квестов с неизвестным опытом: %d), за убийства по целям %d, гринд %d (~%d убийств); "
                    .. "максимум квестов в журнале %d из %d; принято %d, сдано %d, не сдано к концу %d.",
                    sm.endLevel, sm.endLevelOptimistic or sm.endLevel,
                    sm.plannedLevels and tostring(sm.plannedLevels[2]) or "—", sm.xpQuest,
                    sm.xpQuestEstimated, sm.unknownXpQuests, sm.xpKill, sm.xpGrind, sm.grindKills, sm.maxQuestLog,
                    db.questLogSize or 40, sm.accepts, sm.turnins, #(sm.carried or {})))
                w("")
            end
            if #r.segments > 0 then
                w("| сегмент | план | уровень (симуляция) | опыт квестов | опыт мобов | гринд (убийств) | журнал |")
                w("|---|---|---|---:|---:|---:|---:|")
                for _, s in ipairs(r.segments) do
                    w(format("| `%s` %s | %s | %.2f → %.2f | %d | %d | %d (%d) | %d |", mdEscape(s.id),
                        mdEscape(textOf(s.title)), s.levels and format("%d–%d", s.levels[1], s.levels[2]) or "—",
                        s.startLevel, s.endLevel or 0, s.xpQuest or 0, s.xpKill or 0, s.xpGrind or 0,
                        s.grindKills or 0, s.questLog or 0))
                end
                w("")
            end
            local shown = 0
            for _, m in ipairs(r.messages) do
                if m.severity ~= "INFO" then
                    if shown == 0 then
                        w("| уровень | где | код | сообщение |")
                        w("|---|---|---|---|")
                    end
                    shown = shown + 1
                    w(format("| %s | %s | `%s` | %s |", m.severity, mdEscape(locStr(m)), m.code, mdEscape(m.msg)))
                end
            end
            if shown == 0 then w("Ошибок и предупреждений нет.") end
            w("")
            if r.counts.INFO > 0 then
                w(format("<details><summary>INFO (%d)</summary>", r.counts.INFO))
                w("")
                for _, m in ipairs(r.messages) do
                    if m.severity == "INFO" then
                        w(format("- %s `%s` %s", mdEscape(locStr(m)), m.code, mdEscape(m.msg)))
                    end
                end
                w("")
                w("</details>")
                w("")
            end
        end
    end
    return L
end

--- JSON-friendly report table.
function V.ReportTable(all, db)
    local routes = {}
    local totals = { ERROR = 0, WARN = 0, INFO = 0 }
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            routes[#routes + 1] = {
                route = r.route, module = mres.module, dir = mres.dir, profile = json.object(r.profile or {}),
                counts = r.counts, suppressed = r.suppressed, summary = json.object(r.summary or {}),
                segments = r.segments, messages = r.messages,
            }
            for k, v in pairs(r.counts) do totals[k] = totals[k] + v end
        end
    end
    return { db = { build = db.meta and db.meta.build, generated = db.meta and db.meta.generated },
             totals = totals, routes = routes }
end

local USAGE = [[
usage: lua5.1 tools/validate_routes.lua [options] [module-dir ...]

Validates FastesBoooy route modules against the Forever DB snapshot.
Without module dirs, every addons/FastesBoooy_*/ module (with a TOC) is checked.

options:
  --route ID            validate only this route id
  --profile k=v,...     override the player profile: race=Scourge,class=PALADIN,faction=Horde
  --strict              warnings also fail (exit 1)
  --json FILE           write the full report (incl. INFO) as JSON
  --markdown FILE       write a Markdown report (docs/VALIDATION.md)
  --db FILE             DB snapshot (default tools/data/forever_db.lua)
  --addons DIR          where to discover modules (default addons)
  --tolerance-yards N   'at' distance WARN threshold in yards (default 40)
  --hard-tolerance-yards N  'at' distance ERROR threshold in yards (default 120)
  --tolerance N         WARN threshold in map units, for maps without known world size (default 3.0)
  --hard-tolerance N    ERROR threshold in map units, for maps without known world size (default 8.0)
  --ignore CODE,...     suppress message codes (e.g. xp-unknown)
  --xp-optimism N       optimistic factor for estimated quest XP (default 2.0): a level
                        requirement is an ERROR only if even the optimistic level is too low
  -v, --verbose         also print INFO messages
  -q, --quiet           print only the per-route result lines
  -h, --help            this help

exit status: 0 ok, 1 errors (or warnings with --strict), 2 usage/load failure or
--route matching no route]]

function V.ParseArgs(argv)
    local o = { dirs = {}, ignore = {} }
    local i = 1
    local function val()
        i = i + 1
        local v = argv[i]
        if v == nil then error("missing value for " .. tostring(argv[i - 1]), 0) end
        return v
    end
    while i <= #argv do
        local a = argv[i]
        if a == "-h" or a == "--help" then o.help = true
        elseif a == "--route" then o.route = val()
        elseif a == "--profile" then
            o.profile = {}
            for kv in val():gmatch("[^,]+") do
                local k, v = kv:match("^%s*(%w+)%s*=%s*(.-)%s*$")
                if not k or (k ~= "race" and k ~= "class" and k ~= "faction") then
                    error("bad --profile entry '" .. kv .. "' (use race=,class=,faction=)", 0)
                end
                o.profile[k] = v
            end
        elseif a == "--strict" then o.strict = true
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
        elseif a == "--ignore" then
            for c in val():gmatch("[^,%s]+") do o.ignore[c] = true end
        elseif a == "-v" or a == "--verbose" then o.verbose = true
        elseif a == "-q" or a == "--quiet" then o.quiet = true
        elseif a:sub(1, 1) == "-" then error("unknown option " .. a, 0)
        else o.dirs[#o.dirs + 1] = a end
        i = i + 1
    end
    return o
end

local function writeFile(path, text)
    local fh, err = io.open(path, "w")
    if not fh then error("cannot write " .. path .. ": " .. tostring(err), 0) end
    fh:write(text)
    fh:close()
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
    local okDb, db = pcall(DB.Load, o.db or (root .. "/tools/data/forever_db.lua"))
    if not okDb then io.stderr:write("validate_routes: " .. tostring(db) .. "\n") return 2 end
    local okS, schema = pcall(Loader.LoadSchema, root)
    if not okS then io.stderr:write("validate_routes: " .. tostring(schema) .. "\n") return 2 end
    local dirs = o.dirs
    if #dirs == 0 then dirs = Loader.DiscoverModules(o.addons or (root .. "/addons")) end
    local opts = {
        db = db, schema = schema, route = o.route, profile = o.profile, tolerance = o.tolerance,
        hardTolerance = o.hardTolerance, toleranceYards = o.toleranceYards,
        hardToleranceYards = o.hardToleranceYards, ignore = o.ignore, unknownXpOptimism = o.unknownXpOptimism,
    }
    local all = {}
    for _, dir in ipairs(dirs) do
        all[#all + 1] = V.ValidateModule(dir, opts)
    end
    local te, tw = 0, 0
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results) do
            te, tw = te + r.counts.ERROR, tw + r.counts.WARN
        end
    end
    if o.quiet then
        for _, mres in ipairs(all) do
            for _, r in ipairs(mres.results) do
                print(format("%s [%s]: %d error(s), %d warning(s), %d info", tostring(r.route), r.profileLabel,
                    r.counts.ERROR, r.counts.WARN, r.counts.INFO))
            end
        end
    else
        for _, line in ipairs(V.FormatText(all, { verbose = o.verbose })) do print(line) end
    end
    if #dirs == 0 then print("no route modules found") end
    print(format("validate_routes: %d module(s), %d error(s), %d warning(s)%s", #dirs, te, tw,
        o.strict and " (strict)" or ""))
    if o.json then writeFile(o.json, json.encode(V.ReportTable(all, db), "  ") .. "\n") end
    if o.markdown then writeFile(o.markdown, table.concat(V.FormatMarkdown(all, db), "\n") .. "\n") end
    if o.route then
        local matched = 0
        for _, mres in ipairs(all) do matched = matched + (mres.matched or 0) end
        if matched == 0 then
            io.stderr:write("validate_routes: --route " .. o.route .. " matched no route\n")
            return 2
        end
    end
    if te > 0 or (o.strict and tw > 0) then return 1 end
    return 0
end

return V
