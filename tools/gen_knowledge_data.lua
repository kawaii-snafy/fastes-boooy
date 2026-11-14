#!/usr/bin/env lua5.1
-- tools/gen_knowledge_data.lua -- (re)generate the quest data of the knowledge base.
--
--   lua5.1 tools/gen_knowledge_data.lua [--db FILE] [--no-overrides] [--overrides DIR] [--check] [--stdout]
--                                       [--out FILE]
--
-- Reads tools/data/forever_db.lua with the DB overrides of tools/overrides applied (as the route tools
-- do; --no-overrides: the bare snapshot) and writes addons/AdventureAtlas_Knowledge/Quests.lua: the
-- quests a Horde character can take (the snapshot is Horde-focused, docs/dev/ATLAS.md) -- the full
-- records of the snapshot plus the brief out-of-scope index (name, levels, masks, zone only) -- as one call
--
--   AdventureAtlas.AddKnowledge({
--       faction = "Horde",
--       zones = { [k] = { map = uiMapID | area = AreaTable id | class = "PALADIN", en = "...", ru = "..." } },
--       npcs = { [id] = { "enUS name", uiMapID, x, y } },   -- position: the first spawn on the map of a quest
--       objects = { [id] = { "enUS name", uiMapID, x, y } }, --   that uses it, else on the map with the
--                                                            --   most spawns; no spawn: { "name" }
--       items = { [id] = "enUS name" },
--       quests = { [id] = {
--           n = "enUS name", l = level (0 = none in the snapshot, -1 = scales; both pass every level range),
--           r = required level (>= 1), z = zone key,
--           ra = race mask (only when narrower than the faction), cl = class mask (only when set),
--           s = { n = { npc ids }, o = { object ids }, i = { item ids } },   -- who / what starts it
--           e = { n = { npc ids }, o = { object ids } },                     -- where it is turned in
--           pa = { quest ids: all needed }, py = { quest ids: one of them needed }, nx = next quest id,
--           x = XP reward at the quest level (when known), new = true (new in Forever)
--       } },
--   })
--
-- NPCs of the Alliance (npc faction "A") are left out of s / e; chains (pa / py / nx) only name quests of
-- this file. Internal flag quests (auto-rewarded, nobody starts or ends them, e.g. "DND FLAG ...") are left
-- out. Zone keys: the quest's uiMapID (C_Map gives the localized name in game), else its AreaTable id
-- (dungeons, cities and other areas without a quest map; C_Map.GetAreaInfo), else the quest sort of the
-- snapshot (zone < 0): a class (the client's class name) or one of CATEGORIES below (en + ru). The output
-- is deterministic (sorted); --check exits 1 when the file would change (CI), --stdout prints instead.

local here = (arg and arg[0] or ""):match("^(.*)[/\\][^/\\]*$") or "."
package.path = here .. "/?.lua;" .. package.path
local root = here .. "/.."

local DB = require("lib.fbdb")

local OUT = root .. "/addons/AdventureAtlas_Knowledge/Quests.lua"
local FACTION = "Horde"

-- Quest sorts of the snapshot that are not a class (QuestieDB zone sort keys; each checked
-- against the quest names under it). Unknown sorts fall back to OTHER and are reported.
local CATEGORIES = {
    [-22] = { en = "Seasonal", ru = "Сезонные события" },
    [-24] = { en = "Herbalism", ru = "Травничество" },
    [-101] = { en = "Fishing", ru = "Рыбная ловля" },
    [-121] = { en = "Blacksmithing", ru = "Кузнечное дело" },
    [-182] = { en = "Leatherworking", ru = "Кожевничество" },
    [-201] = { en = "Engineering", ru = "Инженерное дело" },
    [-264] = { en = "Tailoring", ru = "Портняжное дело" },
    [-284] = { en = "Children's Week", ru = "Детская неделя" },
    [-304] = { en = "Cooking", ru = "Кулинария" },
    [-324] = { en = "First Aid", ru = "Первая помощь" },
    [-344] = { en = "Legendary", ru = "Легендарные" },
    [-364] = { en = "Darkmoon Faire", ru = "Ярмарка Новолуния" },
    [-365] = { en = "Ahn'Qiraj War", ru = "Война в Ан'Кираже" },
    [-366] = { en = "Lunar Festival", ru = "Лунный фестиваль" },
    [-367] = { en = "Reputation", ru = "Репутация" },
    [-368] = { en = "Invasion", ru = "Вторжение" },
    [-369] = { en = "Midsummer", ru = "Огненный солнцеворот" },
    [-666] = { en = "New in Forever", ru = "Новое в Forever" }, -- every quest under it is status "new"
}
local OTHER = { en = "Other", ru = "Другое" }

-- Areas the snapshot has no name for: our label (the game shows the client's area name when it has one).
local AREA_LABELS = {
    [16941] = { en = "Craftsman's Writs", ru = "Заказы ремесленников" }, -- every quest under it is a Craftsman's Writ
}

local USAGE = "usage: lua5.1 tools/gen_knowledge_data.lua [--db FILE] [--no-overrides] [--overrides DIR] [--check]"
    .. " [--stdout] [--out FILE]"

local function luaString(s)
    return (string.format("%q", s):gsub("\\\n", "\\n"))
end

local function sortedKeys(t)
    local out = {}
    for k in pairs(t) do out[#out + 1] = k end
    table.sort(out)
    return out
end

local function idList(list)
    local copy = {}
    for i, v in ipairs(list) do copy[i] = v end
    table.sort(copy)
    for i, v in ipairs(copy) do copy[i] = tostring(v) end
    return "{ " .. table.concat(copy, ", ") .. " }"
end

--- Position of an entity: the first spawn on the preferred map (the map of a quest that uses it), else on
-- the map with the most spawns (ties: lowest uiMapID). @return map, x, y or nil
local function position(spawns, prefer)
    spawns = spawns or {}
    if prefer and spawns[prefer] and #spawns[prefer] > 0 then
        local p = spawns[prefer][1]
        return prefer, p[1], p[2]
    end
    local best, count
    for _, map in ipairs(sortedKeys(spawns)) do
        local n = #spawns[map]
        if n > 0 and (not count or n > count) then best, count = map, n end
    end
    if not best then return nil end
    local p = spawns[best][1]
    return best, p[1], p[2]
end

local function zoneOf(db, q, classSorts, unknown)
    if q.uiMap then return "m" .. q.uiMap, { map = q.uiMap, en = DB.ZoneName(db, q.uiMap) } end
    local z = q.zone or 0
    if z > 0 then
        if not db._zoneNameByArea then
            db._zoneNameByArea = {}
            for _, zone in pairs(db.zones or {}) do
                if zone.areaId then db._zoneNameByArea[zone.areaId] = zone.name end
            end
        end
        local name = (db.areaNames and db.areaNames[z]) or db._zoneNameByArea[z]
        local label = AREA_LABELS[z]
        if not name and not label then unknown[z] = (unknown[z] or 0) + 1 end
        return "a" .. z, { area = z, en = name or (label and label.en) or ("area " .. z),
            ru = not name and label and label.ru or nil }
    end
    if classSorts[z] then return "c" .. classSorts[z], { class = classSorts[z] } end
    local cat = CATEGORIES[z]
    if cat then return "s" .. (-z), { en = cat.en, ru = cat.ru } end
    unknown[z] = (unknown[z] or 0) + 1
    return "other", { en = OTHER.en, ru = OTHER.ru }
end

--- The quests of the file: full records of db.quests, then the brief out-of-scope index entries.
-- @return array of { id, q } sorted by id
local function collectQuests(db)
    local hordeOK = function(races) return DB.Side(db, races):find("H", 1, true) ~= nil end
    local autoRewarded = db.enums.questFlags.AUTO_REWARDED
    local list = {}
    for id, q in pairs(db.quests) do
        local flagQuest = q.flags and DB.HasBit(q.flags, autoRewarded) and not q.start and not q.finish
        if hordeOK(q.races) and not flagQuest then list[#list + 1] = { id = id, q = q } end
    end
    for id, b in pairs(db.questIndex or {}) do
        if not db.quests[id] and hordeOK(b[4]) then
            list[#list + 1] = { id = id, q = { name = b[1], level = b[2], reqLevel = b[3], races = b[4],
                classes = b[5], zone = b[6] } }
        end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

--- Build the file text. @return text, notes (lines for stderr)
local function render(db)
    local hordeMask = db.enums.factionMasks[FACTION]
    local classSorts = {}
    for class, sort in pairs(db.enums.classSorts) do classSorts[sort] = class end

    local quests = collectQuests(db)
    local included = {}
    for _, e in ipairs(quests) do included[e.id] = true end
    local function usableNpc(id)
        local n = db.npcs[id]
        return n ~= nil and n.faction ~= "A"
    end
    local function npcIds(list)
        local out = {}
        for _, id in ipairs(list or {}) do
            if usableNpc(id) then out[#out + 1] = id end
        end
        return out
    end
    local function known(list, source)
        local out = {}
        for _, id in ipairs(list or {}) do
            if source[id] then out[#out + 1] = id end
        end
        return out
    end
    local function chainIds(list, self)
        local out = {}
        for _, id in ipairs(list or {}) do
            if included[id] and id ~= self then out[#out + 1] = id end
        end
        return out
    end

    local zoneByKey, zoneKeys, unknown = {}, {}, {}
    local npcs, objects, items, prefer = {}, {}, {}, { npcs = {}, objects = {} }
    for _, e in ipairs(quests) do
        local q = e.q
        local key, zone = zoneOf(db, q, classSorts, unknown)
        if not zoneByKey[key] then
            zoneByKey[key] = zone
            zoneKeys[#zoneKeys + 1] = key
        end
        e.zoneKey = key
        local s, f = q.start or {}, q.finish or {}
        e.sn, e.en = npcIds(s.npcs), npcIds(f.npcs)
        e.so, e.eo = known(s.objects, db.objects), known(f.objects, db.objects)
        e.si = known(s.items, db.items)
        for _, list in ipairs({ e.sn, e.en }) do
            for _, id in ipairs(list) do
                npcs[id] = true
                prefer.npcs[id] = prefer.npcs[id] or q.uiMap
            end
        end
        for _, list in ipairs({ e.so, e.eo }) do
            for _, id in ipairs(list) do
                objects[id] = true
                prefer.objects[id] = prefer.objects[id] or q.uiMap
            end
        end
        for _, id in ipairs(e.si) do items[id] = true end
    end
    table.sort(zoneKeys)
    local zoneIndex = {}
    for i, key in ipairs(zoneKeys) do zoneIndex[key] = i end

    local meta = db.meta or {}
    local out = {
        "-- AdventureAtlas_Knowledge/Quests.lua -- GENERATED by tools/gen_knowledge_data.lua. DO NOT EDIT BY HAND.",
        string.format("-- enUS names from tools/data/forever_db.lua (World of Warcraft: Forever %s.%s, snapshot %s).",
            tostring(meta.build and meta.build[1]), tostring(meta.build and meta.build[2]), tostring(meta.generated)),
        "-- Quests a " .. FACTION .. " character can take. Regenerate: make knowledge",
        "",
        "if not (AdventureAtlas and AdventureAtlas.AddKnowledge) then return end",
        "",
        "AdventureAtlas.AddKnowledge({",
        "    faction = " .. luaString(FACTION) .. ",",
        "    zones = {",
    }
    for i, key in ipairs(zoneKeys) do
        local z = zoneByKey[key]
        local parts = {}
        if z.map then parts[#parts + 1] = "map = " .. z.map end
        if z.area then parts[#parts + 1] = "area = " .. z.area end
        if z.class then parts[#parts + 1] = "class = " .. luaString(z.class) end
        if z.en then parts[#parts + 1] = "en = " .. luaString(z.en) end
        if z.ru then parts[#parts + 1] = "ru = " .. luaString(z.ru) end
        out[#out + 1] = string.format("        [%d] = { %s },", i, table.concat(parts, ", "))
    end
    out[#out + 1] = "    },"

    local function entities(name, set, source, pref)
        out[#out + 1] = "    " .. name .. " = {"
        for _, id in ipairs(sortedKeys(set)) do
            local ent = source[id]
            local map, x, y = position(ent.spawns, pref[id])
            if map then
                out[#out + 1] = string.format("        [%d] = { %s, %d, %s, %s },", id, luaString(ent.name), map,
                    tostring(x), tostring(y))
            else
                out[#out + 1] = string.format("        [%d] = { %s },", id, luaString(ent.name))
            end
        end
        out[#out + 1] = "    },"
    end
    entities("npcs", npcs, db.npcs, prefer.npcs)
    entities("objects", objects, db.objects, prefer.objects)
    out[#out + 1] = "    items = {"
    for _, id in ipairs(sortedKeys(items)) do
        out[#out + 1] = string.format("        [%d] = %s,", id, luaString(db.items[id].name))
    end
    out[#out + 1] = "    },"

    out[#out + 1] = "    quests = {"
    for _, e in ipairs(quests) do
        local q = e.q
        local f = {
            "n = " .. luaString(q.name),
            "l = " .. tostring(q.level or 0),
            "r = " .. tostring(math.max(q.reqLevel or 1, 1)),
            "z = " .. zoneIndex[e.zoneKey],
        }
        local races = q.races or 0
        if races ~= 0 and races ~= hordeMask then f[#f + 1] = "ra = " .. string.format("%.0f", races) end
        if (q.classes or 0) ~= 0 then f[#f + 1] = "cl = " .. tostring(q.classes) end
        local sp = {}
        if #e.sn > 0 then sp[#sp + 1] = "n = " .. idList(e.sn) end
        if #e.so > 0 then sp[#sp + 1] = "o = " .. idList(e.so) end
        if #e.si > 0 then sp[#sp + 1] = "i = " .. idList(e.si) end
        if #sp > 0 then f[#f + 1] = "s = { " .. table.concat(sp, ", ") .. " }" end
        local ep = {}
        if #e.en > 0 then ep[#ep + 1] = "n = " .. idList(e.en) end
        if #e.eo > 0 then ep[#ep + 1] = "o = " .. idList(e.eo) end
        if #ep > 0 then f[#f + 1] = "e = { " .. table.concat(ep, ", ") .. " }" end
        local pa, py = chainIds(q.preGroup, e.id), chainIds(q.preSingle, e.id)
        if #pa > 0 then f[#f + 1] = "pa = " .. idList(pa) end
        if #py > 0 then f[#f + 1] = "py = " .. idList(py) end
        if q.next and included[q.next] and q.next ~= e.id then f[#f + 1] = "nx = " .. tostring(q.next) end
        if q.xp and q.xp > 0 then f[#f + 1] = "x = " .. tostring(q.xp) end
        if q.status == "new" then f[#f + 1] = "new = true" end
        out[#out + 1] = string.format("        [%d] = { %s },", e.id, table.concat(f, ", "))
    end
    out[#out + 1] = "    },"
    out[#out + 1] = "})"
    out[#out + 1] = ""

    local notes = {}
    for _, z in ipairs(sortedKeys(unknown)) do
        notes[#notes + 1] = string.format("quest zone %d (%d quests) has no name in the snapshot nor here", z, unknown[z])
    end
    notes[#notes + 1] = string.format("%d quests, %d zones, %d npcs, %d objects", #quests, #zoneKeys,
        #sortedKeys(npcs), #sortedKeys(objects))
    return table.concat(out, "\n"), notes
end

local function main(argv)
    local opts = {}
    local i = 1
    while i <= #argv do
        local a = argv[i]
        if a == "--db" then i = i + 1; opts.db = argv[i]
        elseif a == "--overrides" then i = i + 1; opts.overrides = argv[i]
        elseif a == "--no-overrides" then opts.noOverrides = true
        elseif a == "--out" then i = i + 1; opts.out = argv[i]
        elseif a == "--check" then opts.check = true
        elseif a == "--stdout" then opts.stdout = true
        else
            io.stderr:write(USAGE .. "\n")
            return 2
        end
        i = i + 1
    end
    local db = DB.Load(opts.db or (root .. "/tools/data/forever_db.lua"))
    if not opts.noOverrides then
        local rep = DB.ApplyOverrides(db, opts.overrides or DB.OverridesDir(root))
        for _, e in ipairs(rep.errors) do
            io.stderr:write(("gen_knowledge_data: ERROR override-load %s: %s\n"):format(tostring(e.file), tostring(e.msg)))
        end
        if #rep.errors > 0 then return 1 end
    end
    local text, notes = render(db)
    for _, n in ipairs(notes) do io.stderr:write("gen_knowledge_data: " .. n .. "\n") end
    if opts.stdout then
        io.write(text)
        return 0
    end
    local path = opts.out or OUT
    local fh = io.open(path, "rb")
    local old = fh and fh:read("*a")
    if fh then fh:close() end
    if opts.check then
        if old ~= text then
            io.stderr:write("gen_knowledge_data: " .. path .. " is out of date: run `make knowledge`\n")
            return 1
        end
        return 0
    end
    if old ~= text then
        local w = assert(io.open(path, "wb"))
        w:write(text)
        w:close()
        io.stderr:write("gen_knowledge_data: wrote " .. path .. "\n")
    end
    return 0
end

os.exit(main(arg or {}))
