#!/usr/bin/env lua5.1
-- tools/gen_knowledge_data.lua -- (re)generate the quest data of the knowledge base.
--
--   lua5.1 tools/gen_knowledge_data.lua [--db FILE] [--check] [--stdout] [--out FILE]
--
-- Reads tools/data/forever_db.lua (no DB overrides: the knowledge base shows the snapshot) and
-- writes addons/AdventureAtlas_Knowledge/Quests.lua: every quest a Horde character can take (the
-- snapshot is Horde-focused, docs/dev/ATLAS.md), as one call
--
--   AdventureAtlas.AddKnowledge({
--       faction = "Horde",
--       zones = { [k] = { map = uiMapID | area = AreaTable id | class = "PALADIN", en = "...", ru = "..." } },
--       npcs = { [id] = { "enUS name", uiMapID, x, y } },   -- position: the first spawn on the map
--       objects = { [id] = { "enUS name", uiMapID, x, y } }, --   with the most spawns; none: { "name" }
--       items = { [id] = "enUS name" },
--       quests = { [id] = {
--           n = "enUS name", l = level (-1 = scales), r = required level, z = zone key,
--           ra = race mask (only when narrower than the faction), cl = class mask (only when set),
--           s = { n = { npc ids }, o = { object ids }, i = { item ids } },   -- who / what starts it
--           e = { n = { npc ids }, o = { object ids } },                     -- where it is turned in
--           pa = { quest ids: all needed }, py = { quest ids: one of them needed }, nx = next quest id,
--           x = XP reward at the quest level (when known), new = true (new in Forever)
--       } },
--   })
--
-- Zone keys: the quest's uiMapID (C_Map gives the localized name in game), else its AreaTable id
-- (dungeons; C_Map.GetAreaInfo), else the quest sort of the snapshot (zone < 0): a class (the
-- client's class name) or one of CATEGORIES below (en + ru). The output is deterministic (sorted);
-- --check exits 1 when the file would change (CI), --stdout prints instead of writing.

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

local USAGE = "usage: lua5.1 tools/gen_knowledge_data.lua [--db FILE] [--check] [--stdout] [--out FILE]"

local function luaString(s)
    return (string.format("%q", s):gsub("\\\n", "\\n"))
end

local function sortedKeys(t)
    local out = {}
    for k in pairs(t) do out[#out + 1] = k end
    table.sort(out)
    return out
end

local function sortedCopy(list)
    local out = {}
    for i, v in ipairs(list or {}) do out[i] = v end
    table.sort(out)
    return out
end

local function idList(list)
    local parts = {}
    for i, v in ipairs(sortedCopy(list)) do parts[i] = tostring(v) end
    return "{ " .. table.concat(parts, ", ") .. " }"
end

--- Position of an entity: the first spawn on the map with the most spawns (ties: lowest uiMapID).
local function position(spawns)
    local best, count
    for _, map in ipairs(sortedKeys(spawns or {})) do
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
        local name, label = db.areaNames and db.areaNames[z], AREA_LABELS[z]
        if not name and not label then unknown[z] = (unknown[z] or 0) + 1 end
        return "a" .. z, { area = z, en = name or (label and label.en) or ("area " .. z), ru = not name and label and label.ru or nil }
    end
    if classSorts[z] then return "c" .. classSorts[z], { class = classSorts[z] } end
    local cat = CATEGORIES[z]
    if cat then return "s" .. (-z), { en = cat.en, ru = cat.ru } end
    unknown[z] = (unknown[z] or 0) + 1
    return "other", { en = OTHER.en, ru = OTHER.ru }
end

--- Build the file text. @return text, notes (lines for stderr)
local function render(db)
    local hordeMask = db.enums.factionMasks[FACTION]
    local classSorts = {}
    for class, sort in pairs(db.enums.classSorts) do classSorts[sort] = class end

    local quests, zoneByKey, zoneKeys, npcs, objects, items, unknown = {}, {}, {}, {}, {}, {}, {}
    for _, id in ipairs(sortedKeys(db.quests)) do
        local q = db.quests[id]
        if DB.Side(db, q.races):find("H", 1, true) then
            local key, zone = zoneOf(db, q, classSorts, unknown)
            if not zoneByKey[key] then
                zoneByKey[key] = zone
                zoneKeys[#zoneKeys + 1] = key
            end
            quests[#quests + 1] = { id = id, q = q, zoneKey = key }
            local s, e = q.start or {}, q.finish or {}
            for _, n in ipairs(s.npcs or {}) do npcs[n] = true end
            for _, n in ipairs(e.npcs or {}) do npcs[n] = true end
            for _, o in ipairs(s.objects or {}) do objects[o] = true end
            for _, o in ipairs(e.objects or {}) do objects[o] = true end
            for _, i in ipairs(s.items or {}) do items[i] = true end
        end
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

    local notes = {}
    local function entities(name, set, source)
        out[#out + 1] = "    " .. name .. " = {"
        for _, id in ipairs(sortedKeys(set)) do
            local ent = source[id]
            if ent then
                local map, x, y = position(ent.spawns)
                if map then
                    out[#out + 1] = string.format("        [%d] = { %s, %d, %s, %s },", id, luaString(ent.name), map,
                        tostring(x), tostring(y))
                else
                    out[#out + 1] = string.format("        [%d] = { %s },", id, luaString(ent.name))
                end
            end
        end
        out[#out + 1] = "    },"
    end
    entities("npcs", npcs, db.npcs)
    entities("objects", objects, db.objects)
    out[#out + 1] = "    items = {"
    for _, id in ipairs(sortedKeys(items)) do
        local it = db.items[id]
        if it then out[#out + 1] = string.format("        [%d] = %s,", id, luaString(it.name)) end
    end
    out[#out + 1] = "    },"

    out[#out + 1] = "    quests = {"
    for _, e in ipairs(quests) do
        local q = e.q
        local f = {
            "n = " .. luaString(q.name),
            "l = " .. tostring(q.level or 0),
            "r = " .. tostring(q.reqLevel or 1),
            "z = " .. zoneIndex[e.zoneKey],
        }
        local races = q.races or 0
        if races ~= 0 and races ~= hordeMask and DB.MaskIntersects(races, hordeMask) then
            f[#f + 1] = "ra = " .. string.format("%.0f", races)
        end
        if (q.classes or 0) ~= 0 then f[#f + 1] = "cl = " .. tostring(q.classes) end
        local s, fin = q.start or {}, q.finish or {}
        local sp = {}
        if s.npcs and #s.npcs > 0 then sp[#sp + 1] = "n = " .. idList(s.npcs) end
        if s.objects and #s.objects > 0 then sp[#sp + 1] = "o = " .. idList(s.objects) end
        if s.items and #s.items > 0 then sp[#sp + 1] = "i = " .. idList(s.items) end
        if #sp > 0 then f[#f + 1] = "s = { " .. table.concat(sp, ", ") .. " }" end
        local ep = {}
        if fin.npcs and #fin.npcs > 0 then ep[#ep + 1] = "n = " .. idList(fin.npcs) end
        if fin.objects and #fin.objects > 0 then ep[#ep + 1] = "o = " .. idList(fin.objects) end
        if #ep > 0 then f[#f + 1] = "e = { " .. table.concat(ep, ", ") .. " }" end
        if q.preGroup and #q.preGroup > 0 then f[#f + 1] = "pa = " .. idList(q.preGroup) end
        if q.preSingle and #q.preSingle > 0 then f[#f + 1] = "py = " .. idList(q.preSingle) end
        if q.next then f[#f + 1] = "nx = " .. tostring(q.next) end
        if q.xp and q.xp > 0 then f[#f + 1] = "x = " .. tostring(q.xp) end
        if q.status == "new" then f[#f + 1] = "new = true" end
        out[#out + 1] = string.format("        [%d] = { %s },", e.id, table.concat(f, ", "))
    end
    out[#out + 1] = "    },"
    out[#out + 1] = "})"
    out[#out + 1] = ""

    for _, z in ipairs(sortedKeys(unknown)) do
        notes[#notes + 1] = string.format("quest zone %d (%d quests) has no name in the snapshot nor here", z, unknown[z])
    end
    notes[#notes + 1] = string.format("%d quests, %d zones, %d npcs", #quests, #zoneKeys, #sortedKeys(npcs))
    return table.concat(out, "\n"), notes
end

local function main(argv)
    local opts = {}
    local i = 1
    while i <= #argv do
        local a = argv[i]
        if a == "--db" then i = i + 1; opts.db = argv[i]
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
