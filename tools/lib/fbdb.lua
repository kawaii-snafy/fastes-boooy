-- tools/lib/fbdb.lua -- access helpers for tools/data/forever_db.lua (Lua 5.1).
--
--   local DB = require("lib.fbdb")
--   local db = DB.Load("tools/data/forever_db.lua")
--   DB.HasBit(mask, bit)                 -- 64-bit-safe (race masks exceed 32 bits)
--   DB.RaceMask(db, "Scourge", "Horde")  -- 16; "Skyborne" resolves by faction
--   DB.Quest(db, id, "PALADIN")          -- full record (byClass overrides applied) or nil
--   DB.QuestBrief(db, id)                -- {name, level, reqLevel, races, classes, zone} for any Forever quest
--   DB.Npc(db, id) / DB.NpcBrief(db, id) / DB.Object(db, id)
--   DB.Nearest(spawns, uiMap, x, y)      -- distance in map percent to the nearest spawn on uiMap
--   DB.ExclusiveOf(db, id)               -- quests listing id in their exclusive group (reverse index)
--   DB.IsQuestNpc(db, id)                -- the NPC starts or ends a quest of the snapshot
--   DB.SpawnCount(npcOrObject)           -- number of spawn points (all maps)
--   DB.QuestXp(db, baseXp, questLevel, playerLevel)
--   DB.MobXp(db, playerLevel, mobLevel, rank)
--   DB.AddXp(db, state, amount)          -- state = {level=, xp=}; returns levels gained
--   DB.ApplyOverrides(db, "tools/overrides")  -- the DB override layer (corrections of single quests /
--                                             NPCs, see below); DB.Load itself applies none

local DB = {}

local floor, sqrt, huge = math.floor, math.sqrt, math.huge

function DB.Load(path)
    local chunk, err = loadfile(path)
    if not chunk then error("cannot load DB snapshot " .. tostring(path) .. ": " .. tostring(err), 0) end
    setfenv(chunk, {})
    local db = chunk()
    if type(db) ~= "table" or type(db.quests) ~= "table" then
        error("DB snapshot " .. tostring(path) .. " has no quests table", 0)
    end
    DB.Prepare(db)
    return db
end

--- Derived indexes (cached on the db table).
function DB.Prepare(db)
    if db._prepared then return db end
    db._prepared = true
    -- median known quest XP by quest level (estimates for quests with unknown XP)
    local byLevel = {}
    for _, q in pairs(db.quests) do
        if q.xp and q.xp > 0 and q.xpSrc ~= "forever-dungeon" and (q.level or 0) > 0 then
            local t = byLevel[q.level] or {}
            byLevel[q.level] = t
            t[#t + 1] = q.xp
        end
    end
    db._xpMedian = {}
    for lvl, t in pairs(byLevel) do
        table.sort(t)
        db._xpMedian[lvl] = t[floor((#t + 1) / 2)]
    end
    -- reverse exclusive index: _exclusiveOf[b] = { a, ... } for every quest a listing b in
    -- a.exclusive (exclusive groups are symmetric in game, often one-sided in the data)
    local rev = {}
    for a, q in pairs(db.quests) do
        for _, b in ipairs(q.exclusive or {}) do
            local t = rev[b] or {}
            rev[b] = t
            t[#t + 1] = a
        end
    end
    for _, t in pairs(rev) do table.sort(t) end
    db._exclusiveOf = rev
    -- NPCs that start / end a quest (class overrides included): quest givers are never kill targets
    local qnpc = {}
    local function addEnds(q)
        for _, k in ipairs({ "start", "finish" }) do
            for _, id in ipairs(q[k] and q[k].npcs or {}) do qnpc[id] = true end
        end
    end
    for _, q in pairs(db.quests) do
        addEnds(q)
        for _, ov in pairs(q.byClass or {}) do addEnds(ov) end
    end
    db._questNpcs = qnpc
    -- cumulative XP at the start of each level
    db._cum = { [1] = 0 }
    local levels = db.xp and db.xp.levels or {}
    for lvl = 1, (db.levelCap or 60) - 1 do
        db._cum[lvl + 1] = db._cum[lvl] + (levels[lvl] or 0)
    end
    return db
end

--- True when the NPC starts or ends any quest of the snapshot.
function DB.IsQuestNpc(db, id)
    DB.Prepare(db)
    return db._questNpcs[id] == true
end

--- Number of spawn points of an NPC / object record on all maps (thinned lists count kept points).
function DB.SpawnCount(ent)
    local c = 0
    for _, list in pairs(ent and ent.spawns or {}) do c = c + #list end
    return c
end

--- Quests that list `id` as exclusive (reverse of quests[x].exclusive; sorted).
function DB.ExclusiveOf(db, id)
    DB.Prepare(db)
    return (db._exclusiveOf and db._exclusiveOf[id]) or {}
end

function DB.HasBit(mask, bit)
    if not mask or not bit or mask <= 0 or bit <= 0 then return false end
    return floor(mask / bit) % 2 == 1
end

--- Bit OR of two masks without bit.bor (exact for doubles up to 2^53).
function DB.MaskOr(a, b)
    local out, bit = 0, 1
    a, b = a or 0, b or 0
    while (a > 0 or b > 0) and bit <= 2 ^ 52 do
        local x, y = a % 2, b % 2
        if x == 1 or y == 1 then out = out + bit end
        a, b = floor(a / 2), floor(b / 2)
        bit = bit * 2
    end
    return out
end

function DB.MaskIntersects(a, b)
    a, b = a or 0, b or 0
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then return true end
        a, b = floor(a / 2), floor(b / 2)
    end
    return false
end

--- Race bit for a UnitRace() raceFile ("Scourge" = Undead; "Skyborne" by faction).
function DB.RaceMask(db, raceFile, faction)
    local v = db.enums.raceFileToBit[raceFile or ""]
    if type(v) == "table" then return v[faction or ""] end
    return v
end

function DB.ClassMask(db, classToken)
    return db.enums.classes[classToken or ""]
end

function DB.FactionMask(db, faction)
    return db.enums.factionMasks[faction or ""]
end

local function shallowCopy(t)
    local c = {}
    for k, v in pairs(t) do c[k] = v end
    return c
end

--- Full quest record with the class-dependent Horde-dynamic overrides of `classToken` applied.
function DB.Quest(db, id, classToken)
    local q = db.quests[id]
    if not q then return nil end
    local ov = q.byClass and classToken and q.byClass[classToken]
    if not ov then return q end
    local r = shallowCopy(q)
    for k, v in pairs(ov) do
        if k ~= "_deleted" then r[k] = v end
    end
    for _, k in ipairs(ov._deleted or {}) do r[k] = nil end
    return r
end

--- Minimal facts for ANY Forever quest: full record, else the out-of-scope index.
-- @return { name, level, reqLevel, races, classes, zone, full = bool } or nil
function DB.QuestBrief(db, id)
    local q = db.quests[id]
    if q then
        return { name = q.name, level = q.level, reqLevel = q.reqLevel, races = q.races,
                 classes = q.classes, zone = q.zone, full = true }
    end
    local b = db.questIndex and db.questIndex[id]
    if b then
        local ov = db._overrides
        return { name = b[1], level = b[2], reqLevel = b[3], races = b[4], classes = b[5],
                 zone = b[6], full = false, xp = ov and ov.indexXp[id] or nil }
    end
    return nil
end

--- Side letters of a race mask: "H", "A", "AH" (0 = all races).
function DB.Side(db, races)
    if not races or races == 0 then return "AH" end
    local h = DB.MaskIntersects(races, db.enums.factionMasks.Horde)
    local a = DB.MaskIntersects(races, db.enums.factionMasks.Alliance)
    return (a and "A" or "") .. (h and "H" or "")
end

function DB.Npc(db, id) return db.npcs[id] end

function DB.NpcBrief(db, id)
    local n = db.npcs[id]
    if n then return { name = n.name, full = true } end
    local b = db.npcIndex and db.npcIndex[id]
    if b then return { name = b[1], zone = b[2], full = false } end
    return nil
end

function DB.Object(db, id) return db.objects[id] end

function DB.ObjectBrief(db, id)
    local o = db.objects[id]
    if o then return { name = o.name, full = true } end
    local b = db.objectIndex and db.objectIndex[id]
    if b then return { name = b, full = false } end
    return nil
end

function DB.ZoneName(db, uiMap)
    local z = db.zones[uiMap]
    return z and z.name or ("uiMap " .. tostring(uiMap))
end

--- "Cooking" for skill line 185 (enums.professions; "skill <id>" when unknown).
function DB.SkillName(db, skillId)
    for k, v in pairs(db.enums and db.enums.professions or {}) do
        if v == skillId then
            local name = (k:sub(1, 1) .. k:sub(2):lower()):gsub("_(%a)", function(c) return " " .. c:upper() end)
            return name
        end
    end
    return "skill " .. tostring(skillId)
end

--- Distance (map percent units) from (x, y) to the nearest spawn on uiMap.
-- @return distance, x, y of the nearest spawn; nil when the entity has no spawn on that map
function DB.Nearest(spawns, uiMap, x, y)
    local list = spawns and spawns[uiMap]
    if not list or #list == 0 then return nil end
    local best, bx, by = huge, nil, nil
    for _, p in ipairs(list) do
        local dx, dy = p[1] - x, p[2] - y
        local d = sqrt(dx * dx + dy * dy)
        if d < best then best, bx, by = d, p[1], p[2] end
    end
    return best, bx, by
end

--- Uimaps an entity has spawns on (sorted).
function DB.SpawnMaps(spawns)
    local out = {}
    for m in pairs(spawns or {}) do out[#out + 1] = m end
    table.sort(out)
    return out
end

---------------------------------------------------------------------------
-- XP rules (research/xp_table.json; Classic rules unchanged in Forever except
-- the green-mob penalty, see db.xp.mobRule)
---------------------------------------------------------------------------

local function roundQuestXp(x)
    if x <= 100 then return 5 * floor((x + 2) / 5) end
    if x <= 500 then return 10 * floor((x + 5) / 10) end
    if x <= 1000 then return 25 * floor((x + 12) / 25) end
    return 50 * floor((x + 25) / 50)
end
DB.RoundQuestXp = roundQuestXp

--- Quest XP after the level-difference penalty.
function DB.QuestXp(db, base, questLevel, playerLevel)
    if not base or base <= 0 then return 0 end
    if playerLevel >= (db.levelCap or 60) then return 0 end
    if not questLevel or questLevel <= 0 then questLevel = playerLevel end
    local m = 2 * (questLevel - playerLevel) + 20
    if m > 10 then m = 10 elseif m < 1 then m = 1 end
    if m == 10 then return base end
    return roundQuestXp(base * m / 10)
end

--- Estimated base XP for a quest with unknown XP: median known XP of quests with the
-- same quest level (nearest level with data otherwise).
function DB.EstimateQuestXp(db, questLevel)
    local med = db._xpMedian or {}
    questLevel = questLevel or 1
    for d = 0, 10 do
        local v = med[questLevel + d] or med[questLevel - d]
        if v then return v end
    end
    return 0
end

function DB.GreyLevel(playerLevel)
    if playerLevel <= 5 then return 0 end
    if playerLevel <= 39 then return playerLevel - floor(playerLevel / 10) - 5 end
    if playerLevel <= 59 then return playerLevel - floor(playerLevel / 5) - 1 end
    return 48
end

--- Estimated kill XP of one mob (Classic formula + Forever green-mob penalty estimate).
-- @param rank 0 normal, 1 elite, 2 rare elite, 3 boss, 4 rare
function DB.MobXp(db, playerLevel, mobLevel, rank)
    if playerLevel >= (db.levelCap or 60) then return 0 end
    if mobLevel <= DB.GreyLevel(playerLevel) then return 0 end
    local base = 5 * playerLevel + 45
    local xp
    if mobLevel >= playerLevel then
        local d = mobLevel - playerLevel
        if d > 4 then d = 4 end
        xp = base * (1 + 0.05 * d)
    else
        local rule = db.xp and db.xp.mobRule or {}
        local zd = (rule.zeroDifference or {})[playerLevel] or 5
        local diff = playerLevel - mobLevel
        xp = base * (1 - diff / zd)
        local maxPen = rule.foreverGreenPenaltyMax or 0.20
        local pen = 0.04 * diff
        if pen > maxPen then pen = maxPen end
        xp = xp * (1 - pen)
    end
    if rank == 1 or rank == 2 or rank == 3 then xp = xp * ((db.xp and db.xp.mobRule and db.xp.mobRule.eliteMult) or 2) end
    if xp < 0 then xp = 0 end
    return floor(xp)
end

function DB.XpToLevel(db, level)
    return (db.xp and db.xp.levels and db.xp.levels[level]) or 0
end

--- Cumulative XP at the start of `level`.
function DB.CumXp(db, level)
    DB.Prepare(db)
    return db._cum[level] or db._cum[#db._cum] or 0
end

--- Add XP to a {level, xp} state. @return number of levels gained
function DB.AddXp(db, state, amount)
    local cap = db.levelCap or 60
    local gained = 0
    if state.level >= cap then return 0 end
    state.xp = state.xp + (amount or 0)
    while state.level < cap do
        local need = DB.XpToLevel(db, state.level)
        if need <= 0 or state.xp < need then break end
        state.xp = state.xp - need
        state.level = state.level + 1
        gained = gained + 1
    end
    if state.level >= cap then state.xp = 0 end
    return gained
end

--- Level as a decimal (5.43 = level 5, 43% to 6).
function DB.LevelValue(db, state)
    local need = DB.XpToLevel(db, state.level)
    if need <= 0 then return state.level end
    return state.level + state.xp / need
end

---------------------------------------------------------------------------
-- DB override layer (tools/overrides/*.lua)
---------------------------------------------------------------------------
-- Corrections of single quests / NPCs of the snapshot, kept outside tools/data so that they survive
-- `make db`. One file per owner (tools/overrides/<name>.lua), each one `return { quests = {...},
-- npcs = {...} }`:
--
--   return {
--       quests = {
--           [861] = { exclusive = { remove = { 844 } }, source = "in game 2026-11-12", verified = false },
--           [4641] = { xp = 85, races = { add = { "Troll" } }, source = "https://...", verified = true },
--       },
--       npcs = { [3153] = { sub = "Warrior Trainer", source = "in game 2026-11-12", verified = true } },
--   }
--
-- Quest fields: xp = <number>; races = { add = { raceFile, ... } }; classes = { add = { CLASS, ... } };
-- exclusive / preSingle / preGroup = { add = { ids }, remove = { ids } }; breadcrumbFor = <id> | false.
-- NPC fields: sub = "<sub name>". Every entry needs `source` (a URL or "in game YYYY-MM-DD");
-- `verified` (default false) says whether the value was confirmed in the Forever client.
-- A quest outside the snapshot (questIndex only) takes xp, races and classes.
--
-- Rules:
--   * DB.Load applies nothing (specs keep their pinned numbers); the command lines call
--     DB.ApplyOverrides (and take --no-overrides).
--   * DB.Prepare runs first: the XP median per quest level is that of the SNAPSHOT, so an XP value for
--     one quest never moves the estimate of another quest.
--   * The files are read in a fixed order (shared.lua first, then the owner files in alphabetical
--     order), each in an empty environment under pcall. A file that does not load or has a format
--     error is ignored as a whole and reported (report.errors: one entry per file).
--   * A quest / NPC id may appear in one file only: the later file is the one in error. shared.lua is
--     read first, so an owner file that repeats one of its ids is the file that is ignored.
--   * `exclusive = { remove = { B } }` on quest A removes the pair in both directions (exclusive groups
--     are symmetric in game but often listed on one side only in the data).
-- db._overrides = { quests = { [id] = rec }, npcs = { [id] = rec }, exclRemoved = { [a] = { [b] = rec } },
--                   indexXp = { [id] = xp }, files = { name... } } with
-- rec = { id, file = "<name>.lua", owner = "<name>", source, verified, fields = { [field] = true },
--         orig = { the values before the override } } -- the validator asks it whether a step passes a
-- check only because of an unverified override (WARN db-override-unverified).

local QUEST_LIST_FIELDS = { exclusive = true, preSingle = true, preGroup = true }
local QUEST_MASK_FIELDS = { races = true, classes = true }
local QUEST_KEYS = { xp = true, races = true, classes = true, exclusive = true, preSingle = true, preGroup = true,
                     breadcrumbFor = true, source = true, verified = true }
local NPC_KEYS = { sub = true, source = true, verified = true }
local INDEX_FIELDS = { xp = true, races = true, classes = true }

local function isId(v)
    return type(v) == "number" and v > 0 and v % 1 == 0
end

local function sortedIds(t)
    local out = {}
    for k in pairs(t) do out[#out + 1] = k end
    table.sort(out, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) == "number"
    end)
    return out
end

local function listOf(v, check)
    if type(v) ~= "table" then return false end
    local n = #v
    for k in pairs(v) do
        if type(k) ~= "number" or k < 1 or k > n or k % 1 ~= 0 then return false end
    end
    for i = 1, n do
        if not check(v[i]) then return false end
    end
    return true
end

local function copyList(t)
    local out = {}
    for i, v in ipairs(t or {}) do out[i] = v end
    return out
end

local function without(list, id)
    local out = {}
    for _, v in ipairs(list or {}) do
        if v ~= id then out[#out + 1] = v end
    end
    return out
end

local function has(list, id)
    for _, v in ipairs(list or {}) do
        if v == id then return true end
    end
    return false
end

--- Does the override file `owner` ("warrior", "durotar", "orc"; "shared" owns everything) own the
-- module file `file` ("Classes/Warrior.lua", "Segments/Durotar/01.lua", "Races/Orc.lua")? A file is
-- owned when its base name (without .lua) or one of its directories equals the name, without
-- regard to case.
function DB.OverrideOwns(owner, file)
    owner = tostring(owner):lower()
    if owner == "shared" then return true end
    for comp in tostring(file or ""):gsub("\\", "/"):gmatch("[^/]+") do
        if comp:gsub("%.lua$", ""):lower() == owner then return true end
    end
    return false
end

-- format errors of one override file (strings); {} when it is well-formed
local function checkOverrideFile(db, data, ov)
    local errs = {}
    local function err(msg, ...) errs[#errs + 1] = msg:format(...) end
    if type(data) ~= "table" then
        err("the file must return a table { quests = {...}, npcs = {...} }")
        return errs
    end
    for k in pairs(data) do
        if k ~= "quests" and k ~= "npcs" then err("unknown key '%s' (quests, npcs)", tostring(k)) end
    end
    local function common(kind, id, e, keys, prev)
        if not isId(id) then
            err("%s: the key %s is not an id", kind, tostring(id))
            return false
        end
        local where = ("%s %d"):format(kind, id)
        if type(e) ~= "table" then
            err("%s: the entry must be a table", where)
            return false
        end
        if prev then
            err("%s is already overridden by %s (an id may appear in one file only)", where, prev.file)
        end
        for k in pairs(e) do
            if not keys[k] then err("%s: unknown key '%s'", where, tostring(k)) end
        end
        if type(e.source) ~= "string" or e.source:match("^%s*$") then
            err("%s: `source` is required (a URL or 'in game YYYY-MM-DD')", where)
        end
        if e.verified ~= nil and type(e.verified) ~= "boolean" then err("%s: `verified` must be true or false", where) end
        return where
    end
    if data.quests ~= nil and type(data.quests) ~= "table" then err("`quests` must be a table { [id] = {...} }") end
    if data.npcs ~= nil and type(data.npcs) ~= "table" then err("`npcs` must be a table { [id] = {...} }") end
    for _, id in ipairs(sortedIds(type(data.quests) == "table" and data.quests or {})) do
        local e = data.quests[id]
        local where = common("quest", id, e, QUEST_KEYS, ov.quests[id])
        if where then
            local full = db.quests[id] ~= nil
            if not full and not (db.questIndex and db.questIndex[id]) then
                err("%s does not exist in the Forever DB", where)
            end
            local n = 0
            for k in pairs(e) do
                if k ~= "source" and k ~= "verified" then
                    n = n + 1
                    if not full and not INDEX_FIELDS[k] then
                        err("%s is outside the DB snapshot: only xp, races and classes can be overridden (not %s)",
                            where, tostring(k))
                    end
                end
            end
            if n == 0 then err("%s: nothing is overridden", where) end
            if e.xp ~= nil and not (type(e.xp) == "number" and e.xp > 0) then err("%s: xp must be a number > 0", where) end
            for field in pairs(QUEST_MASK_FIELDS) do
                local v = e[field]
                if v ~= nil then
                    local known = field == "races" and db.enums.raceFileToBit or db.enums.classes
                    local okShape = type(v) == "table" and v.add ~= nil
                    for k in pairs(type(v) == "table" and v or {}) do
                        if k ~= "add" then okShape = false end
                    end
                    if not okShape or not listOf(v.add, function(t) return type(t) == "string" end) or #v.add == 0 then
                        err("%s: %s must be { add = { \"<token>\", ... } }", where, field)
                    else
                        for _, tok in ipairs(v.add) do
                            if known[tok] == nil then
                                err("%s: %s.add: unknown %s '%s'", where, field,
                                    field == "races" and "raceFile" or "class token", tok)
                            end
                        end
                    end
                end
            end
            for field in pairs(QUEST_LIST_FIELDS) do
                local v = e[field]
                if v ~= nil then
                    local okShape = type(v) == "table" and (v.add ~= nil or v.remove ~= nil)
                    for k in pairs(type(v) == "table" and v or {}) do
                        if k ~= "add" and k ~= "remove" then okShape = false end
                    end
                    if not okShape or (v.add ~= nil and not listOf(v.add, isId))
                        or (v.remove ~= nil and not listOf(v.remove, isId)) then
                        err("%s: %s must be { add = { ids }, remove = { ids } } (one of the two is enough)", where, field)
                    end
                end
            end
            if e.breadcrumbFor ~= nil and e.breadcrumbFor ~= false and not isId(e.breadcrumbFor) then
                err("%s: breadcrumbFor must be a quest id or false", where)
            end
        end
    end
    for _, id in ipairs(sortedIds(type(data.npcs) == "table" and data.npcs or {})) do
        local e = data.npcs[id]
        local where = common("npc", id, e, NPC_KEYS, ov.npcs[id])
        if where then
            if not db.npcs[id] then err("%s is not in the DB snapshot", where) end
            if type(e.sub) ~= "string" then err("%s: `sub` (the sub name, a string) is required", where) end
        end
    end
    return errs
end

-- mask of the tokens added to a race / class mask (0 = "all" stays "all")
local function addMask(db, field, mask, tokens)
    if not mask or mask == 0 then return mask end
    local out = mask
    for _, tok in ipairs(tokens) do
        local bit
        if field == "classes" then
            bit = db.enums.classes[tok]
        else
            bit = db.enums.raceFileToBit[tok]
            if type(bit) == "table" then
                -- a raceFile of both factions (Skyborne): the side(s) the quest already has
                local side = DB.Side(db, mask)
                local both = 0
                if side:find("H", 1, true) then both = DB.MaskOr(both, bit.Horde or 0) end
                if side:find("A", 1, true) then both = DB.MaskOr(both, bit.Alliance or 0) end
                bit = both
            end
        end
        out = DB.MaskOr(out, bit or 0)
    end
    return out
end

local function applyQuestOverride(db, ov, id, e, rec)
    local q = db.quests[id]
    if not q then
        -- a quest outside the snapshot: { name, level, reqLevel, races, classes, zone }
        local b = db.questIndex[id]
        rec.orig = { races = b[4], classes = b[5] }
        if e.xp then ov.indexXp[id] = e.xp end
        if e.races or e.classes then
            local nb = {}
            for i = 1, 6 do nb[i] = b[i] end
            if e.races then nb[4] = addMask(db, "races", b[4], e.races.add) end
            if e.classes then nb[5] = addMask(db, "classes", b[5], e.classes.add) end
            db.questIndex[id] = nb
        end
        return
    end
    rec.orig = { xp = q.xp, xpSrc = q.xpSrc, races = q.races, classes = q.classes, exclusive = copyList(q.exclusive),
                 preSingle = copyList(q.preSingle), preGroup = copyList(q.preGroup), breadcrumbFor = q.breadcrumbFor }
    if e.xp then q.xp, q.xpSrc = e.xp, "override" end
    if e.races then q.races = addMask(db, "races", q.races, e.races.add) end
    if e.classes then q.classes = addMask(db, "classes", q.classes, e.classes.add) end
    for field in pairs(QUEST_LIST_FIELDS) do
        local v = e[field]
        if v then
            local list = copyList(q[field])
            for _, x in ipairs(v.remove or {}) do
                list = without(list, x)
                if field == "exclusive" then
                    -- the pair, both directions
                    local other = db.quests[x]
                    if other and has(other.exclusive, id) then
                        local l = without(other.exclusive, id)
                        other.exclusive = #l > 0 and l or nil
                    end
                    ov.exclRemoved[id] = ov.exclRemoved[id] or {}
                    ov.exclRemoved[id][x] = rec
                    ov.exclRemoved[x] = ov.exclRemoved[x] or {}
                    ov.exclRemoved[x][id] = rec
                end
            end
            for _, x in ipairs(v.add or {}) do
                if not has(list, x) then list[#list + 1] = x end
            end
            q[field] = #list > 0 and list or nil
        end
    end
    if e.breadcrumbFor ~= nil then
        local old, new = q.breadcrumbFor, e.breadcrumbFor or nil
        if old and db.quests[old] then
            local l = without(db.quests[old].breadcrumbs, id)
            db.quests[old].breadcrumbs = #l > 0 and l or nil
        end
        q.breadcrumbFor = new
        if new and db.quests[new] and not has(db.quests[new].breadcrumbs, id) then
            local l = copyList(db.quests[new].breadcrumbs)
            l[#l + 1] = id
            db.quests[new].breadcrumbs = l
        end
    end
end

--- The default override directory of a repository root: "<root>/tools/overrides", without the
-- "tools/.." a tool's own location puts into the root ("tools/../tools/overrides" -> "tools/overrides").
function DB.OverridesDir(root)
    local dir = tostring(root or ".") .. "/tools/overrides"
    dir = dir:gsub("^%./", "")
    local n
    repeat
        dir, n = dir:gsub("[^/%.][^/]*/%.%./", "", 1)
    until n == 0
    return dir
end

--- The *.lua files of an override directory in the order they are applied ({} when the directory
-- does not exist): shared.lua first, then the owner files in alphabetical order. An id may appear in
-- one file only and the later file is the one in error, so an owner file that repeats an id of
-- shared.lua is ignored itself; it never knocks out the file every route depends on.
function DB.OverrideFiles(dir)
    local out = {}
    local p = io.popen('ls -1 "' .. tostring(dir):gsub('"', '\\"') .. '" 2>/dev/null')
    if not p then return out end
    for name in p:lines() do
        if name:match("%.lua$") then out[#out + 1] = name end
    end
    p:close()
    local function isShared(name) return name:lower() == "shared.lua" end
    table.sort(out, function(a, b)
        if isShared(a) ~= isShared(b) then return isShared(a) end
        return a < b
    end)
    return out
end

--- Apply the override files of `dir` to a loaded snapshot (see the section header).
-- @return report { dir, files = { { file, owner, quests = n, npcs = n } } (applied),
--                  errors = { { file = "<dir>/<name>.lua", name = "<name>.lua", msg = "..." } } (ignored files) }
function DB.ApplyOverrides(db, dir)
    DB.Prepare(db) -- the XP medians are those of the snapshot
    local ov = db._overrides or { quests = {}, npcs = {}, exclRemoved = {}, indexXp = {}, files = {} }
    db._overrides = ov
    local report = { dir = dir, files = {}, errors = {} }
    for _, name in ipairs(DB.OverrideFiles(dir)) do
        local path = dir .. "/" .. name
        local function ignore(msg)
            report.errors[#report.errors + 1] = { file = path, name = name, msg = msg }
        end
        local chunk, lerr = loadfile(path)
        if not chunk then
            ignore("load error: " .. tostring(lerr))
        else
            setfenv(chunk, {})
            local ok, data = pcall(chunk)
            if not ok then
                ignore("runtime error: " .. tostring(data))
            else
                local errs = checkOverrideFile(db, data, ov)
                if #errs > 0 then
                    ignore(errs[1] .. (#errs > 1 and (" (and %d more)"):format(#errs - 1) or ""))
                else
                    local owner = name:gsub("%.lua$", ""):lower()
                    local nq, nn = 0, 0
                    for _, id in ipairs(sortedIds(data.quests or {})) do
                        local e = data.quests[id]
                        local rec = { id = id, file = name, owner = owner, source = e.source,
                                      verified = e.verified == true, fields = {} }
                        for k in pairs(e) do
                            if k ~= "source" and k ~= "verified" then rec.fields[k] = true end
                        end
                        applyQuestOverride(db, ov, id, e, rec)
                        ov.quests[id] = rec
                        nq = nq + 1
                    end
                    for _, id in ipairs(sortedIds(data.npcs or {})) do
                        local e = data.npcs[id]
                        local n = db.npcs[id]
                        ov.npcs[id] = { id = id, file = name, owner = owner, source = e.source,
                                        verified = e.verified == true, fields = { sub = true }, orig = { sub = n.sub } }
                        n.sub = e.sub
                        nn = nn + 1
                    end
                    ov.files[#ov.files + 1] = name
                    report.files[#report.files + 1] = { file = name, owner = owner, quests = nq, npcs = nn }
                end
            end
        end
    end
    -- the reverse exclusive index follows the corrected lists
    local rev = {}
    for a, q in pairs(db.quests) do
        for _, b in ipairs(q.exclusive or {}) do
            local t = rev[b] or {}
            rev[b] = t
            t[#t + 1] = a
        end
    end
    for _, t in pairs(rev) do table.sort(t) end
    db._exclusiveOf = rev
    return report
end

return DB
