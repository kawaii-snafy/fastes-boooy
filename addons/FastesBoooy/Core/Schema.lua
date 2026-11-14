-- FastesBoooy / Core / Schema.lua
--
-- Route format contract (see docs/ROUTE_FORMAT.md).
-- PURE Lua 5.1: no WoW API calls here. This file is loaded both by the addon
-- (through the TOC, receiving the addon namespace as the 2nd vararg) and by the
-- offline tools (tools/validate_routes.lua, tests) which inject their own `ns`.

local _, ns = ...
ns = ns or {}

local Schema = {}
ns.Schema = Schema

Schema.API_VERSION = 1

local type, pairs, ipairs, tostring, floor = type, pairs, ipairs, tostring, math.floor
local format = string.format

-- Action keys a step may carry. Order here = evaluation/display order.
Schema.ACTION_ORDER = {
    "abandon", "turnin", "accept", "complete", "collect", "level",
    "go", "train", "fp", "fly", "sethearth", "hearth", "vendor", "manual",
}

-- Actions whose completion can be read from game state at any time
-- (quest log, level, bags). All others are "transient": they are only
-- observable while the step is current (arrival, window opened, ...).
Schema.STATEFUL = {
    abandon = true, turnin = true, accept = true, complete = true,
    collect = true, level = true,
}

Schema.ACTIONS = {}
for _, a in ipairs(Schema.ACTION_ORDER) do Schema.ACTIONS[a] = true end

-- Non-action keys allowed on a step.
Schema.STEP_FIELDS = {
    id = "string", at = "table", radius = "number", npc = "id-list",
    object = "id-list", note = "text", reward = "table", gossip = "number",
    use = "number", bg = "boolean", class = "token-list", race = "token-list",
    faction = "string", spells = "text-list", optional = "boolean",
    ok = "code-list", -- acknowledged validator warnings (offline tools only; the engine ignores it)
}

Schema.CLASSES = {
    WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true,
    SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true,
}

Schema.FACTIONS = { Horde = true, Alliance = true }

Schema.ROUTE_FIELDS = {
    api = "number", id = "string", title = "text", faction = "string",
    races = "token-list", classes = "token-list", levels = "table",
    author = "string", version = "string", default = "boolean",
    description = "text",
    aliases = "token-list", -- former ids of the route (saved progress follows the rename, Core/Registry.lua)
}

Schema.SEGMENT_FIELDS = {
    id = "string", title = "text", levels = "table", steps = "table",
    zone = "string", order = "number",
    ok = "code-list", -- acknowledged validator warnings about the segment (offline tools only)
}

-- Default arrival radius in yards for movement-type actions.
Schema.DEFAULT_RADIUS = { go = 12, fly = 60, hearth = 80 }

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------

local function isPosInt(v)
    return type(v) == "number" and v > 0 and floor(v) == v
end

local function isText(v)
    if type(v) == "string" then return v ~= "" end
    if type(v) == "table" then
        local any = false
        for k, s in pairs(v) do
            if type(k) ~= "string" or type(s) ~= "string" then return false end
            any = true
        end
        return any
    end
    return false
end

--- Pick a localized string from a text value ("str" or {ru=..., en=...}).
-- @param t text value
-- @param locale WoW locale code (e.g. "ruRU", "enUS"); optional
function Schema.Text(t, locale)
    if t == nil then return nil end
    if type(t) == "string" then return t end
    if type(t) ~= "table" then return tostring(t) end
    local short = locale and locale:sub(1, 2) or "en"
    return t[locale or ""] or t[short] or t.en or t.ru or (function()
        for _, v in pairs(t) do return v end -- luacheck: ignore 512 (first value)
    end)()
end

local function toList(v)
    if v == nil then return nil end
    if type(v) == "table" then return v end
    return { v }
end

local function tokenSet(v)
    local list = toList(v)
    if not list then return nil end
    local set, n = {}, 0
    for _, tok in ipairs(list) do
        set[tok] = true
        n = n + 1
    end
    if n == 0 then return nil end
    return set
end

local function addErr(errors, where, msg, ...)
    errors[#errors + 1] = where .. ": " .. format(msg, ...)
end

---------------------------------------------------------------------------
-- step normalization
---------------------------------------------------------------------------

-- Normalizes the quest-id payload of accept/turnin/abandon/complete.
-- accept = 1 | {1, 2}
-- complete = 1 | {1, 2} | { [1] = {1, 2} } (objective indexes) | {1, [2] = {3}}
local function normQuestAction(kind, value, where, errors, out)
    if isPosInt(value) then
        out[#out + 1] = { type = kind, quest = value }
        return
    end
    if type(value) ~= "table" then
        addErr(errors, where, "%s must be a quest id or a list of quest ids", kind)
        return
    end
    local seen = false
    -- array part first, preserving author order
    local n = #value
    for i = 1, n do
        local q = value[i]
        if isPosInt(q) then
            out[#out + 1] = { type = kind, quest = q }
            seen = true
        else
            addErr(errors, where, "%s[%d] is not a valid quest id", kind, i)
        end
    end
    -- hash part: { [questId] = {objective indexes} } (complete only)
    local extra = {}
    for k in pairs(value) do
        if not (type(k) == "number" and k >= 1 and k <= n and floor(k) == k) then
            extra[#extra + 1] = k
        end
    end
    table.sort(extra, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(extra) do
        local v = value[k]
        if kind ~= "complete" then
            addErr(errors, where, "%s has unexpected key %s", kind, tostring(k))
        elseif not isPosInt(k) then
            addErr(errors, where, "complete has invalid quest id key %s", tostring(k))
        elseif type(v) ~= "table" or #v == 0 then
            addErr(errors, where, "complete[%d] must be a non-empty list of objective indexes", k)
        else
            local objs = {}
            for i, o in ipairs(v) do
                if isPosInt(o) then objs[#objs + 1] = o
                else addErr(errors, where, "complete[%d][%d] invalid objective index", k, i) end
            end
            out[#out + 1] = { type = "complete", quest = k, objectives = objs }
            seen = true
        end
    end
    if not seen then
        addErr(errors, where, "%s is empty", kind)
    end
end

local function normAt(v, where, errors)
    if type(v) ~= "table" then
        addErr(errors, where, "at must be {uiMapID, x, y}")
        return nil
    end
    local m, x, y = v[1] or v.map, v[2] or v.x, v[3] or v.y
    if not isPosInt(m) then
        addErr(errors, where, "at: uiMapID must be a positive integer")
        return nil
    end
    if type(x) ~= "number" or type(y) ~= "number" or x < 0 or x > 100 or y < 0 or y > 100 then
        addErr(errors, where, "at: x/y must be numbers in 0..100 (map percent)")
        return nil
    end
    return { map = m, x = x, y = y }
end

local function normIdList(v, key, where, errors)
    local list = toList(v)
    local out = {}
    for i, id in ipairs(list or {}) do
        if isPosInt(id) then out[#out + 1] = id
        else addErr(errors, where, "%s[%d] is not a valid id", key, i) end
    end
    if #out == 0 then
        addErr(errors, where, "%s must be an id or list of ids", key)
        return nil
    end
    return out
end

--- Normalize the class / race / faction keys of a definition (a step, or the scope of a shared
-- insert: Core/Compose.lua) into filters = { class = set, race = set, faction = "Horde" }.
-- Class tokens and the faction are checked; race tokens only for their type (the raceFile
-- names are client data: the offline tools check them against the DB snapshot).
-- An empty list (`class = {}`) is an error: it would read as "no filter" (every class), the
-- opposite of what an empty list says; the dimension is then left unfiltered (the caller may
-- reject the definition: a shared insert does, Compose.AddLibraryInsert).
-- @return filters, or nil when `def` has none of the three keys
function Schema.NormalizeFilters(def, where, errors)
    local filters
    if def.class ~= nil then
        local set = tokenSet(def.class)
        if not set then
            addErr(errors, where, "class is an empty list: name at least one class token, or leave the key out")
        end
        for tok in pairs(set or {}) do
            if not Schema.CLASSES[tok] then addErr(errors, where, "unknown class token '%s'", tostring(tok)) end
        end
        filters = {}
        filters.class = set
    end
    if def.race ~= nil then
        local set = tokenSet(def.race)
        if not set then
            addErr(errors, where, "race is an empty list: name at least one race token, or leave the key out")
        end
        for tok in pairs(set or {}) do
            if type(tok) ~= "string" then addErr(errors, where, "race tokens must be strings (UnitRace raceFile)") end
        end
        filters = filters or {}
        filters.race = set
    end
    if def.faction ~= nil then
        if not Schema.FACTIONS[def.faction] then addErr(errors, where, "faction must be Horde or Alliance") end
        filters = filters or {}
        filters.faction = def.faction
    end
    return filters
end

local function isCode(v)
    return type(v) == "string" and v ~= "" and not v:find("[^a-z%-]")
end

--- Normalize the `ok` key of a step / segment: the validator warnings the author has
-- acknowledged (tools/lib/validator.lua gives them their meaning; the engine ignores them).
--   ok = "at-far-from-giver"                              one message code
--   ok = { "at-far-from-giver", "quest-out-of-scope" }    several codes
--   ok = { ["level-grind"] = 700 }                        a code with a ceiling (a number >= 0)
--   ok = { "skip-ahead", ["level-grind"] = 90 }           both
-- Only the shape is checked here (codes are [a-z-]+).
-- @return { [code] = true | ceiling }, or nil when nothing valid was given
function Schema.NormalizeOk(v, where, errors)
    local out, any = {}, false
    if isCode(v) then
        out[v] = true
        return out
    end
    if type(v) ~= "table" then
        addErr(errors, where, "ok must be a message code ([a-z-]), a list of codes or { [code] = ceiling }")
        return nil
    end
    local n = #v
    for i = 1, n do
        if isCode(v[i]) then
            if out[v[i]] == nil then out[v[i]] = true end
            any = true
        else
            addErr(errors, where, "ok[%d] is not a message code ([a-z-])", i)
        end
    end
    local extra = {}
    for k in pairs(v) do
        if not (type(k) == "number" and k >= 1 and k <= n and floor(k) == k) then extra[#extra + 1] = k end
    end
    table.sort(extra, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(extra) do
        local ceiling = v[k]
        if not isCode(k) then
            addErr(errors, where, "ok has an invalid key %s (a message code is expected)", tostring(k))
        elseif type(ceiling) ~= "number" or ceiling < 0 or ceiling ~= ceiling then
            addErr(errors, where, "ok['%s'] must be a number >= 0 (the ceiling of the acknowledgement)", k)
        else
            out[k] = ceiling
            any = true
        end
    end
    if not any then
        if n == 0 and #extra == 0 then addErr(errors, where, "ok is empty") end
        return nil
    end
    return out
end

--- Normalize one step definition.
-- @return normalized step (never nil; may be partial when errors were added)
function Schema.NormalizeStep(def, where, errors)
    local step = { actions = {}, def = def }
    if type(def) ~= "table" then
        addErr(errors, where, "step must be a table")
        return step
    end

    for k in pairs(def) do
        if not Schema.ACTIONS[k] and not Schema.STEP_FIELDS[k] then
            addErr(errors, where, "unknown step key '%s'", tostring(k))
        end
    end

    local actions = step.actions
    for _, kind in ipairs(Schema.ACTION_ORDER) do
        local v = def[kind]
        if v ~= nil then
            if kind == "accept" or kind == "turnin" or kind == "abandon" or kind == "complete" then
                normQuestAction(kind, v, where, errors, actions)
            elseif kind == "collect" then
                if type(v) ~= "table" then
                    addErr(errors, where, "collect must be { [itemId] = count }")
                else
                    local keys = {}
                    for item in pairs(v) do keys[#keys + 1] = item end
                    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
                    for _, item in ipairs(keys) do
                        local count = v[item]
                        if not isPosInt(item) or not isPosInt(count) then
                            addErr(errors, where, "collect entry [%s]=%s invalid", tostring(item), tostring(count))
                        else
                            actions[#actions + 1] = { type = "collect", item = item, count = count }
                        end
                    end
                end
            elseif kind == "level" then
                local lvl, frac
                if type(v) == "table" then lvl, frac = v[1], v[2] else lvl = v end
                if not isPosInt(lvl) or lvl > 100 then
                    addErr(errors, where, "level must be a level number or {level, fraction}")
                elseif frac ~= nil and (type(frac) ~= "number" or frac < 0 or frac >= 1) then
                    addErr(errors, where, "level fraction must be in [0, 1)")
                else
                    actions[#actions + 1] = { type = "level", level = lvl, frac = frac or 0 }
                end
            elseif kind == "fp" or kind == "fly" or kind == "sethearth" or kind == "hearth" then
                if type(v) ~= "string" or v == "" then
                    addErr(errors, where, "%s must be a non-empty place name (enUS)", kind)
                else
                    actions[#actions + 1] = { type = kind, place = v }
                end
            else -- go, train, vendor, manual
                if v ~= true then
                    addErr(errors, where, "%s must be true", kind)
                else
                    actions[#actions + 1] = { type = kind }
                end
            end
        end
    end

    if #actions == 0 then
        addErr(errors, where, "step has no action "
            .. "(accept/turnin/complete/level/go/train/fp/fly/sethearth/hearth/collect/vendor/abandon/manual)")
    end

    -- fields
    if def.id ~= nil then
        if type(def.id) ~= "string" or def.id == "" or def.id:find("[^%w%-_%.:]") then
            addErr(errors, where, "id must be a string of [A-Za-z0-9-_.:]")
        else
            step.id = def.id
        end
    end
    if def.at ~= nil then step.at = normAt(def.at, where, errors) end
    if def.radius ~= nil then
        if type(def.radius) ~= "number" or def.radius <= 0 then
            addErr(errors, where, "radius must be a positive number (yards)")
        else
            step.radius = def.radius
        end
    end
    if def.npc ~= nil then step.npc = normIdList(def.npc, "npc", where, errors) end
    if def.object ~= nil then step.object = normIdList(def.object, "object", where, errors) end
    if def.note ~= nil then
        if not isText(def.note) then addErr(errors, where, "note must be a string or {ru=..., en=...}")
        else step.note = def.note end
    end
    if def.reward ~= nil then
        if type(def.reward) ~= "table" then
            addErr(errors, where, "reward must be { [questId] = choiceIndex }")
        else
            -- only valid entries are kept (an invalid one is an error already and
            -- must not reach the reward automation, e.g. a string index)
            local reward = {}
            for q, idx in pairs(def.reward) do
                if not isPosInt(q) or not isPosInt(idx) then
                    addErr(errors, where, "reward entry [%s]=%s invalid", tostring(q), tostring(idx))
                else
                    reward[q] = idx
                end
            end
            step.reward = reward
        end
    end
    if def.gossip ~= nil then
        if not isPosInt(def.gossip) then addErr(errors, where, "gossip must be a positive option index")
        else step.gossip = def.gossip end
    end
    if def.use ~= nil then
        if not isPosInt(def.use) then addErr(errors, where, "use must be an item id")
        else step.use = def.use end
    end
    if def.bg ~= nil then
        if type(def.bg) ~= "boolean" then addErr(errors, where, "bg must be boolean")
        else step.bg = def.bg end
    end
    if def.optional ~= nil then
        if type(def.optional) ~= "boolean" then addErr(errors, where, "optional must be boolean")
        else step.optional = def.optional end
    end
    if def.spells ~= nil then
        local list = toList(def.spells)
        for i, s in ipairs(list) do
            if not isText(s) then addErr(errors, where, "spells[%d] must be text", i) end
        end
        step.spells = list
    end
    if def.ok ~= nil then step.ok = Schema.NormalizeOk(def.ok, where, errors) end
    step.filters = Schema.NormalizeFilters(def, where, errors)

    -- derived properties
    local stateful, needsAt = false, false
    for _, a in ipairs(actions) do
        if Schema.STATEFUL[a.type] then stateful = true end
        if a.type == "go" or a.type == "fly" or a.type == "hearth" then needsAt = true end
    end
    step.stateful = stateful
    step.transient = not stateful
    if needsAt and not step.at then
        addErr(errors, where, "go/fly/hearth steps require 'at'")
    end
    if not step.radius then
        local r
        for _, a in ipairs(actions) do
            local d = Schema.DEFAULT_RADIUS[a.type]
            if d and (not r or d > r) then r = d end
        end
        step.radius = r or Schema.DEFAULT_RADIUS.go
    end
    return step
end

---------------------------------------------------------------------------
-- route / segment normalization
---------------------------------------------------------------------------

local function checkFields(def, allowed, where, errors)
    for k in pairs(def) do
        if not allowed[k] then addErr(errors, where, "unknown key '%s'", tostring(k)) end
    end
end

local function checkLevels(v, where, errors)
    if v == nil then return nil end
    if type(v) ~= "table" or not isPosInt(v[1]) or not isPosInt(v[2]) or v[1] > v[2] then
        addErr(errors, where, "levels must be {from, to}")
        return nil
    end
    return { v[1], v[2] }
end

--- Normalize a route definition (metadata only; segments are added separately).
-- @return route table, errors list
function Schema.NormalizeRoute(def)
    local errors = {}
    local where = "route"
    if type(def) ~= "table" then
        addErr(errors, where, "route definition must be a table")
        return nil, errors
    end
    where = "route " .. tostring(def.id)
    checkFields(def, Schema.ROUTE_FIELDS, where, errors)
    if def.api ~= Schema.API_VERSION then
        addErr(errors, where, "api must be %d (got %s)", Schema.API_VERSION, tostring(def.api))
    end
    if type(def.id) ~= "string" or def.id == "" or def.id:find("[^%w%-_]") then
        addErr(errors, where, "id must be a string of [A-Za-z0-9-_]")
    end
    if not isText(def.title) then addErr(errors, where, "title is required (string or {ru=, en=})") end
    if def.faction ~= nil and not Schema.FACTIONS[def.faction] then
        addErr(errors, where, "faction must be Horde or Alliance")
    end
    local classes = tokenSet(def.classes)
    for tok in pairs(classes or {}) do
        if not Schema.CLASSES[tok] then addErr(errors, where, "unknown class token '%s'", tostring(tok)) end
    end
    -- former ids (a string or a list): same charset as the id; the route's own id is not an alias
    local aliases
    for i, a in ipairs(toList(def.aliases) or {}) do
        if type(a) ~= "string" or a == "" or a:find("[^%w%-_]") then
            addErr(errors, where, "aliases[%d] must be a route id ([A-Za-z0-9-_])", i)
        elseif a == def.id then
            addErr(errors, where, "alias '%s' is the id of the route itself", a)
        else
            aliases = aliases or {}
            local dup = false
            for _, b in ipairs(aliases) do
                if b == a then dup = true end
            end
            if not dup then aliases[#aliases + 1] = a end
        end
    end
    local route = {
        id = def.id, title = def.title, description = def.description, aliases = aliases,
        faction = def.faction, races = tokenSet(def.races), classes = classes,
        levels = checkLevels(def.levels, where, errors),
        author = def.author, version = def.version, default = def.default and true or false,
        segments = {}, steps = {}, stepById = {}, segmentById = {},
    }
    return route, errors
end

--- Normalize a segment and append its steps to `route`.
-- @return segment table, errors list
function Schema.AddSegment(route, def)
    local errors = {}
    local where = "segment"
    if type(def) ~= "table" then
        addErr(errors, where, "segment definition must be a table")
        return nil, errors
    end
    where = "segment " .. tostring(def.id)
    checkFields(def, Schema.SEGMENT_FIELDS, where, errors)
    if type(def.id) ~= "string" or def.id == "" or def.id:find("[^%w%-_]") then
        addErr(errors, where, "id must be a string of [A-Za-z0-9-_]")
    end
    if route.segmentById[def.id] then
        addErr(errors, where, "duplicate segment id")
    end
    if not isText(def.title) then addErr(errors, where, "title is required") end
    if type(def.steps) ~= "table" or #def.steps == 0 then
        addErr(errors, where, "steps must be a non-empty list")
    end
    local seg = {
        id = def.id, title = def.title, zone = def.zone, order = def.order,
        levels = checkLevels(def.levels, where, errors),
        first = #route.steps + 1, steps = {},
    }
    if def.ok ~= nil then seg.ok = Schema.NormalizeOk(def.ok, where, errors) end
    for i, sdef in ipairs(type(def.steps) == "table" and def.steps or {}) do
        local swhere = format("%s step %d", where, i)
        local step = Schema.NormalizeStep(sdef, swhere, errors)
        step.segment = def.id
        step.segIndex = i
        if not step.id then
            step.id = format("%s:%d", tostring(def.id), i)
            step.autoId = true -- positional id: shifts when a step is added, never an insert anchor (Core/Compose.lua)
        end
        if route.stepById[step.id] then
            addErr(errors, swhere, "duplicate step id '%s'", step.id)
        else
            route.stepById[step.id] = step
        end
        route.steps[#route.steps + 1] = step
        step.index = #route.steps
        seg.steps[#seg.steps + 1] = step
    end
    seg.last = #route.steps
    route.segments[#route.segments + 1] = seg
    if def.id ~= nil then route.segmentById[def.id] = seg end
    return seg, errors
end

--- Does a step / route filter match the given player facts?
-- @param filters normalized filters (step.filters) or nil
-- @param player { class = "PALADIN", race = "Scourge", faction = "Horde" }
function Schema.FiltersMatch(filters, player)
    if not filters then return true end
    if filters.class and not filters.class[player.class or ""] then return false end
    if filters.race and not filters.race[player.race or ""] then return false end
    if filters.faction and filters.faction ~= player.faction then return false end
    return true
end

--- Can a step filter match ANY player of the route (route.classes / races / faction)?
-- false = the step can never be shown on that route: Core/Compose.lua does not compose such a
-- shared step (segment step or shared-insert step) into the route. A route dimension that is
-- not restricted (no `classes`, no `races`, no `faction`) can match anything.
-- @param filters normalized filters (step.filters) or nil
function Schema.FiltersCanMatchRoute(filters, route)
    if not filters then return true end
    local function meets(set, allowed)
        if not set or not allowed then return true end
        for tok in pairs(set) do
            if allowed[tok] then return true end
        end
        return false
    end
    if not meets(filters.class, route.classes) then return false end
    if not meets(filters.race, route.races) then return false end
    if filters.faction and route.faction and filters.faction ~= route.faction then return false end
    return true
end

-- the keys of t: numbers ascending, then the rest by name (stable messages)
local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        local na, nb = type(a) == "number", type(b) == "number"
        if na ~= nb then return na end
        if na then return a < b end
        return tostring(a) < tostring(b)
    end)
    return keys
end

--- Shape check of the data kinds the engine reads beyond names (AddLibraryData / AddRouteData).
-- Today one kind: the class reward table `rewards = { CLASS = { [questID] = index } }` (class
-- token of Schema.CLASSES, quest id and choice index positive integers). The data is merged as
-- given; the engine ignores an invalid entry (Engine:GetRewardChoice), so a wrong entry costs a
-- reward window the player has to answer, and this check makes it visible (the offline tools
-- report it as an error of the file).
-- @return the number of errors added
function Schema.CheckData(data, where, errors)
    local n0 = #errors
    if type(data) ~= "table" then return 0 end
    local rewards = data.rewards
    if rewards ~= nil then
        if type(rewards) ~= "table" then
            addErr(errors, where, "rewards must be a table { CLASS = { [questID] = index } }")
        else
            for _, class in ipairs(sortedKeys(rewards)) do
                local t = rewards[class]
                local cw = format("rewards.%s", tostring(class))
                if not Schema.CLASSES[class] then
                    addErr(errors, where, "%s: unknown class token '%s'", cw, tostring(class))
                end
                if type(t) ~= "table" then
                    addErr(errors, where, "%s must be a table { [questID] = index }", cw)
                else
                    for _, q in ipairs(sortedKeys(t)) do
                        local idx = t[q]
                        if not isPosInt(q) then
                            addErr(errors, where, "%s: the key %s is not a quest id", cw, tostring(q))
                        elseif not isPosInt(idx) then
                            addErr(errors, where, "%s[%d]: the choice must be a positive integer (got %s)", cw, q,
                                tostring(idx))
                        end
                    end
                end
            end
        end
    end
    return #errors - n0
end

--- Does a route apply to the given player?
function Schema.RouteMatches(route, player)
    if route.faction and route.faction ~= player.faction then return false end
    if route.classes and not route.classes[player.class or ""] then return false end
    if route.races and not route.races[player.race or ""] then return false end
    return true
end

return Schema
