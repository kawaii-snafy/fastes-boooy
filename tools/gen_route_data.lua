#!/usr/bin/env lua5.1
-- tools/gen_route_data.lua -- (re)generate <module>/Data.lua for route modules.
--
--   lua5.1 tools/gen_route_data.lua [--db FILE] [--check] [--stdout] <module-dir> [...]
--   lua5.1 tools/gen_route_data.lua --all            (every addons/FastesBoooy_*/ module)
--
-- Loads the module's Route.lua + Segments (TOC order, Data.lua skipped; its FastesBoooy_*
-- dependencies first, like the client) in the validator's sandbox, collects every quest /
-- NPC / object / item id the steps reference and writes, per route:
--
--   FastesBoooy.AddRouteData("<routeId>", {
--       quests = { [id] = "enUS name", ... },
--       npcs = { [id] = "enUS name", ... },
--       objects = {...}, items = {...},   -- only when referenced
--       places = { ["Brill"] = { area = 159, en = "Brill", ru = "Брилл" }, ... },
--   })
--
-- A route that uses library segments (UseSegments) lists only what its own segments and
-- its inserts reference: the library steps' names come from the library module's
-- Data.lua. A library module (FastesBoooy.AddLibrarySegment, no route) gets
--
--   FastesBoooy.AddLibraryData({ quests = {...}, npcs = {...}, ..., places = {...} })
--
-- with everything its own library segments reference (also written, with empty tables, for a
-- library module whose TOC says "## X-FastesBoooy-Module: library" and that registers no
-- segment yet, e.g. a skeleton with placeholder segment files).
--
-- Names come from tools/data/forever_db.lua (enUS). `places` covers the place names of
-- the fp / fly / sethearth / hearth actions: `area` = the AreaTable id of that enUS
-- name in the DB snapshot (areaNames) -- the addon asks the client for the localized
-- name (C_Map.GetAreaInfo), which also matches GetBindLocation() in any locale -- and
-- `ru` from PLACE_NAMES_RU below (fallback when the client has no name). A place with
-- neither is left out (shown in enUS) and reported on stderr. The output is
-- deterministic (sorted ids / names). --check exits 1 if a Data.lua would change (CI),
-- --stdout prints instead of writing.

local here = (arg and arg[0] or ""):match("^(.*)[/\\][^/\\]*$") or "."
package.path = here .. "/?.lua;" .. package.path
local root = here .. "/.."

local DB = require("lib.fbdb")
local Loader = require("lib.route_loader")

local M = {}

-- ruRU names of the places used by the routes (official client names; verified against
-- Wowhead ruRU quest titles / texts where marked). Add a place here when a route starts
-- using it; Forever-new places whose ruRU name is unknown stay out (the client's
-- C_Map.GetAreaInfo name is used in game anyway).
M.PLACE_NAMES_RU = {
    ["Brill"] = "Брилл",
    ["Camp Taurajo"] = "Лагерь Таурахо",
    ["Orgrimmar"] = "Оргриммар",                 -- quest 2380 "В Оргриммар!"
    ["Ratchet"] = "Кабестан",                    -- quest 2382 "Реникс из Кабестана"
    ["Sun Rock Retreat"] = "Приют Солнечного Камня",
    ["The Crossroads"] = "Перекресток",          -- quest 854 "Путешествие в Перекресток"
    ["The Sepulcher"] = "Гробница",
    ["Thunder Bluff"] = "Громовой Утес",         -- quest 775 "Путешествие в Громовой Утес"
    ["Undercity"] = "Подгород",                  -- quest 441 "Роли, который живет в Подгороде"
    ["Valanaar"] = "Валанаар",                   -- quest 92579 "В Валанаар" (Forever)
    ["Zoram'gar Outpost"] = "Застава Зорам'гар",
}

-- action types whose `place` names a location
M.PLACE_ACTIONS = { fp = true, fly = true, sethearth = true, hearth = true }

local function sortedIds(set)
    local out = {}
    for id in pairs(set) do out[#out + 1] = id end
    table.sort(out)
    return out
end

local function luaString(s)
    return string.format("%q", s):gsub("\\\n", "\\n")
end

--- Collect referenced ids of a list of normalized steps.
-- @param steps array of normalized steps (a route: its steps without the library steps)
function M.CollectStepIds(steps)
    local ids = { quests = {}, npcs = {}, objects = {}, items = {}, places = {} }
    for _, step in ipairs(steps) do
        for _, a in ipairs(step.actions) do
            if a.quest then ids.quests[a.quest] = true end
            if a.item then ids.items[a.item] = true end
            if M.PLACE_ACTIONS[a.type] and type(a.place) == "string" then ids.places[a.place] = true end
        end
        for _, n in ipairs(step.npc or {}) do ids.npcs[n] = true end
        for _, o in ipairs(step.object or {}) do ids.objects[o] = true end
        if step.use then ids.items[step.use] = true end
        for q in pairs(step.reward or {}) do
            if type(q) == "number" then ids.quests[q] = true end
        end
    end
    return ids
end

--- Collect referenced ids of a normalized route: its own steps and inserts (library
-- steps are covered by the library module's Data.lua).
function M.CollectIds(route)
    local own = {}
    for _, step in ipairs(route.steps) do
        if not step.library then own[#own + 1] = step end
    end
    return M.CollectStepIds(own)
end

--- Collect referenced ids of the library segments registered by a library module.
function M.CollectLibraryIds(mod)
    local steps = {}
    for _, seg in ipairs(mod.librarySegments or {}) do
        for _, step in ipairs(seg.steps) do steps[#steps + 1] = step end
    end
    return M.CollectStepIds(steps)
end

--- AreaTable id per enUS area name of the DB snapshot (the smallest id when a name repeats).
function M.AreaIds(db)
    local out = {}
    for id, name in pairs(db.areaNames or {}) do
        if type(name) == "string" and (out[name] == nil or id < out[name]) then out[name] = id end
    end
    return out
end

--- `places` entries of a route: { { name, area, ru }, ... } sorted by name, plus the names
-- that have neither an area id nor a ruRU name.
function M.Places(ids, areaIds)
    local list, unknown = {}, {}
    local names = {}
    for name in pairs(ids.places or {}) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do
        local area, ru = areaIds[name], M.PLACE_NAMES_RU[name]
        if area or ru then
            list[#list + 1] = { name = name, area = area, ru = ru }
        else
            unknown[#unknown + 1] = name
        end
    end
    return list, unknown
end

-- lines of one data table body: quests / npcs / objects / items / places
local function renderBody(out, ids, db, label, missing, notes, areaIds)
    local lookups = {
        { "quests", function(id) local b = DB.QuestBrief(db, id) return b and b.name end },
        { "npcs", function(id) local b = DB.NpcBrief(db, id) return b and b.name end },
        { "objects", function(id) local b = DB.ObjectBrief(db, id) return b and b.name end },
        { "items", function(id) local it = db.items[id] return it and it.name end },
    }
    for _, l in ipairs(lookups) do
        local kind, fn = l[1], l[2]
        local list = sortedIds(ids[kind])
        local lines = {}
        for _, id in ipairs(list) do
            local name = fn(id)
            if name and name ~= "" then
                lines[#lines + 1] = string.format("        [%d] = %s,", id, luaString(name))
            elseif kind ~= "items" then
                missing[#missing + 1] = kind .. " " .. id
            end
        end
        if #lines > 0 or kind == "quests" or kind == "npcs" then
            if #lines == 0 then
                out[#out + 1] = string.format("    %s = {},", kind)
            else
                out[#out + 1] = string.format("    %s = {", kind)
                for _, ln in ipairs(lines) do out[#out + 1] = ln end
                out[#out + 1] = "    },"
            end
        end
    end
    local places, unknown = M.Places(ids, areaIds)
    if #places > 0 then
        out[#out + 1] = "    places = {"
        for _, p in ipairs(places) do
            local parts = {}
            if p.area then parts[#parts + 1] = string.format("area = %d", p.area) end
            parts[#parts + 1] = "en = " .. luaString(p.name)
            if p.ru then parts[#parts + 1] = "ru = " .. luaString(p.ru) end
            out[#out + 1] = string.format("        [%s] = { %s },", luaString(p.name), table.concat(parts, ", "))
        end
        out[#out + 1] = "    },"
    end
    for _, name in ipairs(unknown) do
        notes[#notes + 1] = string.format("%s: place %q has no area id in the DB snapshot and no "
            .. "ruRU name in PLACE_NAMES_RU (shown in enUS)", label, name)
    end
end

--- Render the Data.lua text of a loaded module: AddLibraryData for the library segments it
-- registers (a library module), then AddRouteData per route it registers.
-- @return text, missing (array of "kind id" not found in the DB), notes (array of strings)
function M.Render(mod, db)
    local meta = db.meta or {}
    local out = {
        "-- " .. mod.name .. "/Data.lua -- GENERATED by tools/gen_route_data.lua. DO NOT EDIT BY HAND.",
        string.format("-- enUS names from tools/data/forever_db.lua (World of Warcraft: Forever %s.%s, snapshot %s).",
            tostring(meta.build and meta.build[1]), tostring(meta.build and meta.build[2]), tostring(meta.generated)),
        "-- Regenerate: make routedata",
        "",
    }
    local missing, notes = {}, {}
    local areaIds = M.AreaIds(db)
    if #(mod.librarySegments or {}) > 0 or mod.isLibrary then
        -- (a library module declared in its TOC may have no segment yet: empty data)
        out[#out + 1] = "FastesBoooy.AddLibraryData({"
        renderBody(out, M.CollectLibraryIds(mod), db, "library " .. mod.name, missing, notes, areaIds)
        out[#out + 1] = "})"
        out[#out + 1] = ""
    end
    local routes = {}
    for _, r in ipairs(mod.routes) do routes[#routes + 1] = r end
    table.sort(routes, function(a, b) return a.id < b.id end)
    for _, route in ipairs(routes) do
        out[#out + 1] = string.format("FastesBoooy.AddRouteData(%s, {", luaString(route.id))
        renderBody(out, M.CollectIds(route), db, "route " .. route.id, missing, notes, areaIds)
        out[#out + 1] = "})"
        out[#out + 1] = ""
    end
    return table.concat(out, "\n"), missing, notes
end

--- Data.lua path of a module: the TOC entry named Data.lua (default <dir>/Data.lua).
function M.DataPath(mod)
    for _, f in ipairs(mod.toc and mod.toc.files or {}) do
        if f:match("^Data%.lua$") or f:match("/Data%.lua$") then return mod.dir .. "/" .. f, f end
    end
    return mod.dir .. "/Data.lua", "Data.lua"
end

local USAGE = [[
usage: lua5.1 tools/gen_route_data.lua [--db FILE] [--check] [--stdout] (--all | <module-dir> ...)

  --all       every addons/FastesBoooy_*/ module (route and library modules)
  --check     do not write; exit 1 if any Data.lua is out of date
  --stdout    print the generated text instead of writing it
  --db FILE   DB snapshot (default tools/data/forever_db.lua)]]

function M.Main(argv)
    local dirs, opts = {}, {}
    local i = 1
    while i <= #argv do
        local a = argv[i]
        if a == "--db" then i = i + 1 opts.db = argv[i]
        elseif a == "--check" then opts.check = true
        elseif a == "--stdout" then opts.stdout = true
        elseif a == "--all" then opts.all = true
        elseif a == "-h" or a == "--help" then print(USAGE) return 0
        elseif a:sub(1, 1) == "-" then io.stderr:write("unknown option " .. a .. "\n" .. USAGE .. "\n") return 2
        else dirs[#dirs + 1] = a end
        i = i + 1
    end
    if opts.all then
        for _, d in ipairs(Loader.DiscoverModules(root .. "/addons")) do dirs[#dirs + 1] = d end
    end
    if #dirs == 0 then
        if opts.all then print("gen_route_data: no route modules found") return 0 end
        io.stderr:write(USAGE .. "\n")
        return 2
    end
    local okDb, db = pcall(DB.Load, opts.db or (root .. "/tools/data/forever_db.lua"))
    if not okDb then io.stderr:write("gen_route_data: " .. tostring(db) .. "\n") return 2 end
    local schema = Loader.LoadSchema(root)
    local status = 0
    for _, dir in ipairs(dirs) do
        dir = dir:gsub("[/\\]+$", "")
        local tocPath = Loader.FindToc(dir)
        local toc = tocPath and Loader.ParseToc(tocPath)
        local skip = {}
        for _, f in ipairs(toc and toc.files or {}) do
            if f:match("^Data%.lua$") or f:match("/Data%.lua$") then skip[f] = true end
        end
        local mod = Loader.LoadModule(dir, { schema = schema, skip = skip })
        for _, e in ipairs(mod.errors) do
            io.stderr:write(string.format("gen_route_data: %s/%s: %s\n", mod.name, tostring(e.file), e.msg))
        end
        if #mod.errors > 0 then
            -- a module that does not load cleanly would produce incomplete data: write nothing
            io.stderr:write(string.format("gen_route_data: %s: %d load/schema error(s); Data.lua not %s\n",
                mod.name, #mod.errors, (opts.check or opts.stdout) and "generated" or "written"))
            status = 1
        elseif #mod.routes == 0 and not mod.isLibrary then
            io.stderr:write("gen_route_data: " .. mod.name .. ": no routes (and no library segments) registered\n")
            status = 1
        else
            local text, missing, notes = M.Render(mod, db)
            for _, m in ipairs(missing) do
                io.stderr:write(string.format("gen_route_data: %s: %s not found in the DB snapshot\n", mod.name, m))
            end
            for _, n in ipairs(notes) do
                io.stderr:write(string.format("gen_route_data: %s: note: %s\n", mod.name, n))
            end
            local path, rel = M.DataPath(mod)
            if opts.stdout then
                io.write(text)
            elseif opts.check then
                if Loader.readFile(path) ~= text then
                    print(string.format("gen_route_data: %s/%s is out of date (run make routedata)", mod.name, rel))
                    status = 1
                else
                    print(string.format("gen_route_data: %s/%s up to date", mod.name, rel))
                end
            else
                local fh, err = io.open(path, "w")
                if not fh then
                    io.stderr:write("gen_route_data: cannot write " .. path .. ": " .. tostring(err) .. "\n")
                    status = 2
                else
                    fh:write(text)
                    fh:close()
                    print(string.format("gen_route_data: wrote %s/%s", mod.name, rel))
                end
            end
        end
    end
    return status
end

-- run as a script, or return the module when required (tests)
if arg and arg[0] and arg[0]:match("gen_route_data%.lua$") and not package.loaded["gen_route_data"] then
    os.exit(M.Main(arg))
end
return M
