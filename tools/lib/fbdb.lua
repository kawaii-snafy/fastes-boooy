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
        return { name = b[1], level = b[2], reqLevel = b[3], races = b[4], classes = b[5],
                 zone = b[6], full = false }
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

return DB
