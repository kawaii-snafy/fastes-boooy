-- tools/lib/harness.lua -- start states and harness routes for the offline tools (Lua 5.1).
--
-- Lets a PART of the shared segments of a module (FastesBoooy.AddLibrarySegment: a library module,
-- or a module that also registers routes such as FastesBoooy_Guides) be validated
-- (tools/validate_routes.lua) and simulated (tools/simulate_routes.lua) from an explicit
-- character state, so the segments can be written and checked in parallel:
--
--   lua5.1 tools/validate_routes.lua --harness addons/FastesBoooy_Guides --segments h-a,h-b \
--          --profile race=Scourge,class=PALADIN,faction=Horde --state start.json --write-state end.json
--
-- Harness route: a synthetic route registered for exactly one profile
--   { api = 1, id = "harness-<Library>", faction, races = { race }, classes = { class } }
-- that only uses the listed shared segments (FastesBoooy.UseSegments, composed by the real
-- Core/Compose.lua) -- no own segments, no per-route inserts. The module's SHARED inserts
-- (FastesBoooy.AddLibraryInsert) apply to it like to every route that contains their anchor, and
-- shared steps whose class / race / faction filter cannot match the profile are not composed.
--
-- Start state (JSON; the same format is written by --write-state, so runs can be chained):
--   {
--     "level": 34,                      -- character level (1..60)
--     "xpFrac": 0.2,                    -- fraction of that level already earned (0 <= xpFrac < 1)
--     "done": [1064, 1065],             -- quests turned in before (prerequisites, "already done")
--     "log": [532, 1067],               -- quests in the quest log (count against the 40-quest log);
--                                       -- an entry may also be {"id": 532, "complete": true}
--     "complete": [1067],               -- quests of "log" whose objectives are already done
--     "hearth": "Thunder Bluff",        -- hearthstone bind place (enUS, as in sethearth / hearth)
--     "hearthAt": [1456, 45.8, 64.6],   -- optional: where the bind point is (simulator teleport)
--     "at": [1456, 22.81, 20.89],       -- optional: player position {uiMapID, x, y}
--     "flightPaths": ["Thunder Bluff"], -- known flight points (enUS, as in fp / fly)
--     "meta": { ... }                   -- free-form; --write-state records where the state came from
--   }
-- Every key is optional (default: level 1, nothing done); unknown keys are errors.
--
--   local Harness = require("lib.harness")
--   local state, errs = Harness.ReadState(path)        -- nil + { "msg", ... } on error
--   local text = Harness.EncodeState(state)             -- deterministic, human-readable JSON
--   local hb = Harness.Build(libDir, { schema = Schema, segments = {...} | nil, profile = {...} })
--   hb.route / hb.def / hb.segments / hb.mod / hb.errors / hb.empty / hb.fatal

local Loader = require("lib.route_loader")
local json = require("lib.json")

local Harness = {}

local format, floor = string.format, math.floor

Harness.STATE_KEYS = {
    level = true, xpFrac = true, done = true, log = true, complete = true, hearth = true,
    hearthAt = true, at = true, flightPaths = true, meta = true,
}
-- key order of EncodeState
local KEY_ORDER = { "level", "xpFrac", "done", "log", "complete", "hearth", "hearthAt", "at", "flightPaths", "meta" }

Harness.RACE_FACTION = {
    Human = "Alliance", Dwarf = "Alliance", NightElf = "Alliance", Gnome = "Alliance",
    Orc = "Horde", Scourge = "Horde", Tauren = "Horde", Troll = "Horde", Goblin = "Horde",
}

local function isPosInt(v)
    return type(v) == "number" and v > 0 and floor(v) == v
end

local function isNull(v)
    return v == nil or v == json.null
end

local function sortedNumbers(set)
    local out = {}
    for k in pairs(set) do out[#out + 1] = k end
    table.sort(out)
    return out
end

---------------------------------------------------------------------------
-- state
---------------------------------------------------------------------------

--- An empty state (a fresh level-1 character).
function Harness.EmptyState()
    return { level = 1, xpFrac = 0, done = {}, log = {}, complete = {}, flightPaths = {} }
end

local function normPoint(v, key, errors)
    if isNull(v) then return nil end
    if type(v) ~= "table" or #v ~= 3 or not isPosInt(v[1]) or type(v[2]) ~= "number" or type(v[3]) ~= "number"
        or v[2] < 0 or v[2] > 100 or v[3] < 0 or v[3] > 100 then
        errors[#errors + 1] = format("%s must be [uiMapID, x, y] (map percent 0..100)", key)
        return nil
    end
    return { v[1], v[2], v[3] }
end

local function idList(v, key, errors)
    local out, seen = {}, {}
    if isNull(v) then return out, seen end
    if type(v) ~= "table" then
        errors[#errors + 1] = format("%s must be a list of quest ids", key)
        return out, seen
    end
    for i, id in ipairs(v) do
        if type(id) == "table" and key == "log" then id = id.id end
        if not isPosInt(id) then
            errors[#errors + 1] = format("%s[%d] is not a quest id", key, i)
        elseif seen[id] then
            errors[#errors + 1] = format("%s: quest %d listed twice", key, id)
        else
            seen[id] = true
            out[#out + 1] = id
        end
    end
    return out, seen
end

--- Check and normalize a decoded state table.
-- @return state { level, xpFrac, done = sorted ids, log = sorted ids, complete = sorted ids, hearth,
--         hearthAt, at, flightPaths = sorted names, meta }, errors (list of strings; empty when valid)
function Harness.NormalizeState(t)
    local errors = {}
    local st = Harness.EmptyState()
    if type(t) ~= "table" or t[1] ~= nil then
        return st, { "the state must be a JSON object" }
    end
    for k in pairs(t) do
        if not Harness.STATE_KEYS[k] then
            errors[#errors + 1] = format("unknown key \"%s\" (known: %s)", tostring(k), table.concat(KEY_ORDER, ", "))
        end
    end
    if not isNull(t.level) then
        if not isPosInt(t.level) or t.level > 60 then
            errors[#errors + 1] = "level must be an integer 1..60"
        else
            st.level = t.level
        end
    end
    if not isNull(t.xpFrac) then
        if type(t.xpFrac) ~= "number" or t.xpFrac < 0 or t.xpFrac >= 1 then
            errors[#errors + 1] = "xpFrac must be a number in [0, 1)"
        else
            st.xpFrac = t.xpFrac
        end
    end
    local done, doneSet = idList(t.done, "done", errors)
    local log, logSet = idList(t.log, "log", errors)
    local complete = {}
    local completeSet = {}
    -- {"id": N, "complete": true} entries of "log"
    if type(t.log) == "table" then
        for i, e in ipairs(t.log) do
            if type(e) == "table" then
                for k in pairs(e) do
                    if k ~= "id" and k ~= "complete" then
                        errors[#errors + 1] = format("log[%d]: unknown key \"%s\" (use id, complete)", i, tostring(k))
                    end
                end
                if e.complete == true and isPosInt(e.id) then completeSet[e.id] = true
                elseif not isNull(e.complete) and e.complete ~= false then
                    errors[#errors + 1] = format("log[%d]: complete must be true or false", i)
                end
            end
        end
    end
    local cl = idList(t.complete, "complete", errors)
    for _, id in ipairs(cl) do completeSet[id] = true end
    for _, id in ipairs(sortedNumbers(completeSet)) do
        if not logSet[id] then
            errors[#errors + 1] = format("complete: quest %d is not in \"log\"", id)
        else
            complete[#complete + 1] = id
        end
    end
    for _, id in ipairs(log) do
        if doneSet[id] then errors[#errors + 1] = format("quest %d is both in \"done\" and in \"log\"", id) end
    end
    table.sort(done)
    table.sort(log)
    st.done, st.log, st.complete = done, log, complete
    if not isNull(t.hearth) then
        if type(t.hearth) ~= "string" or t.hearth == "" then
            errors[#errors + 1] = "hearth must be a place name (enUS)"
        else
            st.hearth = t.hearth
        end
    end
    st.hearthAt = normPoint(t.hearthAt, "hearthAt", errors)
    st.at = normPoint(t.at, "at", errors)
    if not isNull(t.flightPaths) then
        if type(t.flightPaths) ~= "table" then
            errors[#errors + 1] = "flightPaths must be a list of place names"
        else
            local seen = {}
            for i, p in ipairs(t.flightPaths) do
                if type(p) ~= "string" or p == "" then
                    errors[#errors + 1] = format("flightPaths[%d] is not a place name", i)
                elseif not seen[p] then
                    seen[p] = true
                    st.flightPaths[#st.flightPaths + 1] = p
                end
            end
            table.sort(st.flightPaths)
        end
    end
    if not isNull(t.meta) then
        if type(t.meta) ~= "table" then
            errors[#errors + 1] = "meta must be an object"
        else
            st.meta = t.meta
        end
    end
    return st, errors
end

--- Decode and normalize state JSON text. @return state | nil, errors
function Harness.ParseState(text, name)
    local t, err = json.decode(text)
    if t == nil then
        return nil, { format("%s: invalid JSON: %s", name or "state", tostring(err)) }
    end
    local st, errors = Harness.NormalizeState(t)
    if #errors > 0 then
        local out = {}
        for i, e in ipairs(errors) do out[i] = format("%s: %s", name or "state", e) end
        return nil, out
    end
    st.file = name
    return st
end

--- Read a state file. @return state | nil, errors (list of strings)
function Harness.ReadState(path)
    local text = Loader.readFile(path)
    if not text then return nil, { "cannot read state file " .. tostring(path) } end
    return Harness.ParseState(text, path)
end

-- JSON of a list of scalars, wrapped at ~100 columns
local function valueList(list, indent)
    if #list == 0 then return "[]" end
    local lines, cur = {}, {}
    local width = 0
    for _, v in ipairs(list) do
        local s = json.encode(v)
        if width + #s + 2 > 96 and #cur > 0 then
            lines[#lines + 1] = table.concat(cur, ", ")
            cur, width = {}, 0
        end
        cur[#cur + 1] = s
        width = width + #s + 2
    end
    lines[#lines + 1] = table.concat(cur, ", ")
    if #lines == 1 then return "[" .. lines[1] .. "]" end
    local pad = "\n" .. indent .. "  "
    return "[" .. pad .. table.concat(lines, "," .. pad) .. "\n" .. indent .. "]"
end

--- Deterministic, human-readable JSON of a state (fixed key order, id lists wrapped).
function Harness.EncodeState(st)
    local parts = {}
    for _, k in ipairs(KEY_ORDER) do
        local v = st[k]
        if v ~= nil then
            local s
            if type(v) == "table" and k ~= "meta" then
                s = valueList(v, "  ")
            elseif k == "meta" then
                s = json.encode(v, "  "):gsub("\n", "\n  ")
            else
                s = json.encode(v)
            end
            parts[#parts + 1] = format("  %s: %s", json.encode(k), s)
        end
    end
    return "{\n" .. table.concat(parts, ",\n") .. "\n}\n"
end

--- Write a state file. @return true | nil, error
function Harness.WriteState(path, st)
    local fh, err = io.open(path, "w")
    if not fh then return nil, "cannot write " .. tostring(path) .. ": " .. tostring(err) end
    fh:write(Harness.EncodeState(st))
    fh:close()
    return true
end

--- XP into the level for a fraction (rounded to whole XP; see Harness.Fraction).
function Harness.XpFromFraction(frac, need)
    if not need or need <= 0 then return 0 end
    local xp = floor((frac or 0) * need + 0.5)
    if xp >= need then xp = need - 1 end
    return xp
end

--- Fraction of a level written to a state: 6 decimals, so XpFromFraction gives back the same XP.
function Harness.Fraction(xp, need)
    if not need or need <= 0 or not xp or xp <= 0 then return 0 end
    local f = floor(xp / need * 1e6 + 0.5) / 1e6
    if f >= 1 then f = 0.999999 end
    return f
end

---------------------------------------------------------------------------
-- profile / segments arguments
---------------------------------------------------------------------------

--- "race=Scourge,class=PALADIN,faction=Horde" -> table (error() on a bad entry)
function Harness.ParseProfile(s)
    local p = {}
    for kv in tostring(s):gmatch("[^,]+") do
        local k, v = kv:match("^%s*(%w+)%s*=%s*(.-)%s*$")
        if not k or (k ~= "race" and k ~= "class" and k ~= "faction") or v == "" then
            error("bad --profile entry '" .. kv .. "' (use race=,class=,faction=)", 0)
        end
        p[k] = v
    end
    return p
end

--- nil for an empty / blank option value (make harness passes every option, possibly empty).
function Harness.NonEmpty(v)
    if v == nil or tostring(v):match("^%s*$") then return nil end
    return v
end

--- "a,b , c" -> { "a", "b", "c" } (empty for an empty value)
function Harness.ParseList(s)
    local out = {}
    for id in tostring(s):gmatch("[^,%s]+") do out[#out + 1] = id end
    return out
end

--- The single profile of a harness run: race and class are required, the faction comes
-- from the race unless given (Skyborne exists on both sides: faction= is required).
-- @return profile | nil, error
function Harness.Profile(p)
    if type(p) ~= "table" or not p.race or not p.class then
        return nil, "the harness needs --profile race=<raceFile>,class=<CLASS>[,faction=Horde|Alliance] "
            .. "(e.g. race=Scourge,class=PALADIN,faction=Horde or race=Skyborne,class=DRUID,faction=Horde)"
    end
    local faction = p.faction or Harness.RACE_FACTION[p.race]
    if not faction then
        return nil, format("--profile race=%s: give the faction too (faction=Horde or faction=Alliance)", p.race)
    end
    if faction ~= "Horde" and faction ~= "Alliance" then
        return nil, format("--profile faction=%s: must be Horde or Alliance", tostring(faction))
    end
    return { race = p.race, class = p.class, faction = faction }
end

---------------------------------------------------------------------------
-- harness route
---------------------------------------------------------------------------

Harness.SOURCE = "<harness>" -- file name of the harness route's registrations in reports

--- Route id of the harness route of a library module: "harness-<Name>" ([A-Za-z0-9-_]).
function Harness.RouteId(libName)
    return "harness-" .. tostring(libName):gsub("^FastesBoooy_", ""):gsub("[^%w%-_]", "-")
end

--- The RegisterRoute definition of a harness route.
function Harness.RouteDef(libName, profile, segments)
    local list = table.concat(segments, ", ")
    return {
        api = 1, id = Harness.RouteId(libName),
        title = { en = format("Harness %s: %s", libName, list), ru = format("Проверка %s: %s", libName, list) },
        faction = profile.faction, races = { profile.race }, classes = { profile.class },
    }
end

--- Load a module with shared segments and compose the harness route (real Core/Schema.lua +
-- Core/Compose.lua). The module may be a library module or a mixed module that also registers routes
-- (FastesBoooy_Guides): the harness route uses the module's shared part. The module's shared inserts
-- (AddLibraryInsert) whose anchors are in the harness route apply to it like to every route, and
-- shared steps that cannot match the harness profile are not composed (Compose.Build).
-- @param libDir module directory (e.g. addons/FastesBoooy_Guides)
-- @param opts { schema = Schema (required), profile = { race, class, faction } (Harness.Profile),
--               segments = { ids } | nil (nil: every shared segment of the module, TOC order),
--               skipGlobs / keepGlobs = the file filter (Loader.LoadModule) }
-- @return hb = { dir, name, mod (Loader.LoadModule result), def (RegisterRoute definition),
--                route (composed, nil when nothing to run), segments (ids used),
--                available (ids the module registers), errors = { { file, msg } } (unknown
--                segments, composition), empty = true when the module registers no segment and none
--                was asked for, fatal = "message" when the directory has nothing for a harness }
function Harness.Build(libDir, opts)
    local Schema = assert(opts.schema, "Harness.Build: opts.schema required")
    local Compose = Schema.Compose
    libDir = tostring(libDir):gsub("[/\\]+$", "")
    local hb = { dir = libDir, name = Loader.basename(libDir), errors = {}, segments = {}, available = {} }
    if not Loader.FindToc(libDir) then
        hb.fatal = format("%s: no TOC file found (expected %s/%s.toc)", libDir, libDir, hb.name)
        return hb
    end
    local mod = Loader.LoadModule(libDir, { schema = Schema, skipGlobs = opts.skipGlobs, keepGlobs = opts.keepGlobs })
    hb.mod = mod
    if #mod.routes > 0 and #mod.librarySegments == 0 then
        hb.fatal = format("%s registers route(s) (%s) but no shared segments: --harness needs a module with shared "
            .. "segments (AddLibrarySegment)", mod.name, mod.routes[1].id)
        return hb
    end
    for _, seg in ipairs(mod.librarySegments) do hb.available[#hb.available + 1] = seg.id end
    local want = opts.segments
    if not want or #want == 0 then
        if #hb.available == 0 then
            hb.empty = true
            return hb
        end
        want = hb.available
    end
    local known = mod.lib.segments
    local listed = #hb.available > 0 and table.concat(hb.available, ", ") or nil
    for _, id in ipairs(want) do
        if known[id] then
            hb.segments[#hb.segments + 1] = id
        else
            hb.errors[#hb.errors + 1] = { file = Harness.SOURCE, msg = format("unknown library segment '%s' (%s)", id,
                listed and (mod.name .. " registers: " .. listed)
                or (mod.name .. " registers no library segments yet: its segment files are placeholders")) }
        end
    end
    hb.def = Harness.RouteDef(mod.name, opts.profile, hb.segments)
    if #hb.segments == 0 then return hb end
    local route, errs = Schema.NormalizeRoute(hb.def)
    for _, e in ipairs(errs or {}) do hb.errors[#hb.errors + 1] = { file = Harness.SOURCE, msg = e } end
    if not route then return hb end
    route.file, route.module, route.data, route.harness = Harness.SOURCE, Harness.SOURCE, {}, true
    local _, uerrs = Compose.AddUses(route, hb.segments, Harness.SOURCE)
    for _, e in ipairs(uerrs or {}) do hb.errors[#hb.errors + 1] = { file = Harness.SOURCE, msg = e } end
    for _, e in ipairs(Compose.Build(route, mod.lib)) do
        local src = e.source
        if type(src) == "table" then src = src.file end -- a shared insert: { module, file }
        hb.errors[#hb.errors + 1] = { file = src or Harness.SOURCE, msg = e.msg }
    end
    hb.route = route
    return hb
end

return Harness
