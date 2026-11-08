-- FastesBoooy / Core / Compose.lua
--
-- Shared library segments and class inserts (route format API v1, see
-- docs/ROUTE_FORMAT.md "Общие сегменты и вставки").
-- PURE Lua 5.1: no WoW API calls. Loaded by the addon (TOC, after Core/Schema.lua,
-- receiving the addon namespace) and by the offline tools (tools/lib/route_loader.lua
-- runs it with the same `ns` as Schema.lua), so a route is composed identically in
-- game, in the validator, the simulator and gen_route_data.
--
--   library module:  FastesBoooy.AddLibrarySegment({ id = "h-...", title, zone, levels, steps })
--                    FastesBoooy.AddLibraryData({ quests = {...}, npcs = {...}, places = {...} })
--   route module:    FastesBoooy.UseSegments("<routeId>", { "h-...", "h-...", ... })
--                    FastesBoooy.AddInsert("<routeId>", { after = "<stepId>" | before = "<stepId>",
--                                                         steps = { ... } })
--
-- Model. A route that calls UseSegments / AddInsert becomes "composed": its own
-- segments (AddSegment) are kept in route.own (same shape as a route: segments /
-- steps / stepById / segmentById, filled by Schema.AddSegment), and Compose.Build
-- rewrites route.segments / steps / stepById / segmentById from
--   1. the own segments in AddSegment order (except those named in a UseSegments list),
--   2. then the UseSegments entries in call order: a library segment (per-route copies
--      of its normalized steps), or one of the route's own segments (moved there),
--   3. then the inserts, in call order: the steps of an insert go right after
--      (`after`) / before (`before`) the anchor step -- after the steps of earlier
--      inserts at the same anchor, so several inserts at one anchor keep call order.
--      Inserted steps belong to the anchor's segment; an anchor may be an own step, a
--      library step or a step of another insert; default id "<anchorId>+<n>".
-- Build is deterministic and idempotent (callers re-run it when an input changes).
-- Errors are reported where they arise and only once: step format errors of library
-- segments by AddLibrarySegment, of inserts by AddInsert; composition errors (unknown
-- library segment, unknown anchor, step / segment ids that collide only after
-- composition) by Build. A route without UseSegments / AddInsert is never touched.

local _, ns = ...
ns = ns or {}

local Compose = {}
ns.Compose = Compose

local type, pairs, ipairs, tostring, next = type, pairs, ipairs, tostring, next
local format, tinsert = string.format, table.insert

local INSERT_KEYS = { after = true, before = true, steps = true }

local function addErr(errors, where, msg, ...)
    errors[#errors + 1] = where .. ": " .. format(msg, ...)
end

local function shallowCopy(t)
    local c = {}
    for k, v in pairs(t) do c[k] = v end
    return c
end

local function validId(v)
    return type(v) == "string" and v ~= "" and not v:find("[^%w%-_]")
end

--- Merge data tables key by key (route data / library data:
-- { quests = { [id] = name }, npcs = {...}, places = {...}, ... }).
-- @param fillOnly keep values already present in dst (library data under route data)
function Compose.MergeData(dst, data, fillOnly)
    for kind, t in pairs(data or {}) do
        if type(t) == "table" then
            local d = dst[kind]
            if type(d) ~= "table" then
                d = {}
                dst[kind] = d
            end
            for k, v in pairs(t) do
                if not fillOnly or d[k] == nil then d[k] = v end
            end
        elseif not fillOnly or dst[kind] == nil then
            dst[kind] = t
        end
    end
    return dst
end

---------------------------------------------------------------------------
-- library
---------------------------------------------------------------------------

--- A new, empty library store (one per client / per offline load).
-- lib.segments[id] = normalized segment, lib.order = segments in registration order,
-- lib.data = merged AddLibraryData tables. lib.scratch is a route-shaped accumulator:
-- every library step id is unique across all library segments (they get combined).
function Compose.NewLibrary()
    return {
        segments = {}, order = {}, data = {}, revision = 0,
        scratch = { segments = {}, steps = {}, stepById = {}, segmentById = {} },
    }
end

--- Register a library segment (same definition as Schema.AddSegment).
-- @param source optional { module = "<addon>", file = "<path>" } (offline tools); the
--        segment and its steps get `library = source.module` (true without a source)
--        and `file = source.file`
-- @return segment or nil, errors (strings "segment <id>...: message")
function Compose.AddLibrarySegment(lib, def, source)
    local Schema = ns.Schema
    if type(def) ~= "table" then
        return nil, { "segment: segment definition must be a table" }
    end
    if validId(def.id) and lib.segments[def.id] then
        return nil, { format("segment %s: registered twice (second definition ignored)", def.id) }
    end
    local seg, errors = Schema.AddSegment(lib.scratch, def)
    if not seg or not validId(def.id) then
        return nil, errors -- an unreferencable segment (Schema already reported the id)
    end
    local tag = (source and source.module) or true
    seg.library = tag
    seg.file = source and source.file or nil
    for _, step in ipairs(seg.steps) do
        step.library = tag
        step.file = seg.file
    end
    lib.segments[seg.id] = seg
    lib.order[#lib.order + 1] = seg
    lib.revision = lib.revision + 1
    return seg, errors
end

--- Merge library data (Data.lua of a library module: enUS names, places).
-- @return true, or false + error string
function Compose.AddLibraryData(lib, data)
    if type(data) ~= "table" then return false, "data must be a table" end
    Compose.MergeData(lib.data, data)
    lib.revision = lib.revision + 1
    return true
end

---------------------------------------------------------------------------
-- route side
---------------------------------------------------------------------------

--- Is the route composed (UseSegments / AddInsert were called for it)?
function Compose.IsComposed(route)
    return route ~= nil and route.own ~= nil
end

--- Make a route composable (idempotent): its current segments / steps become the own
-- part (route.own); route.segments & co. are rebuilt by Compose.Build.
function Compose.Enable(route)
    if route.own then return route end
    route.own = {
        segments = route.segments, steps = route.steps,
        stepById = route.stepById, segmentById = route.segmentById,
    }
    route.uses, route.inserts = {}, {}
    route.dirty = true
    return route
end

--- Where Schema.AddSegment appends an own segment of the route.
function Compose.OwnTarget(route)
    return route.own or route
end

--- Record a UseSegments list.
-- @param ids list of segment ids (a single id string is accepted)
-- @param source opaque value returned with composition errors (file name offline)
-- @return number of ids recorded, errors (strings)
function Compose.AddUses(route, ids, source)
    local errors = {}
    if type(ids) == "string" then ids = { ids } end
    if type(ids) ~= "table" or ids[1] == nil then
        addErr(errors, "UseSegments", "segment ids must be a non-empty list of strings")
        return 0, errors
    end
    for k in pairs(ids) do
        if type(k) ~= "number" or k < 1 or k > #ids or k % 1 ~= 0 then
            addErr(errors, "UseSegments", "unexpected key %s (a list of segment ids is expected)", tostring(k))
        end
    end
    Compose.Enable(route)
    local n = 0
    for i, id in ipairs(ids) do
        if not validId(id) then
            addErr(errors, "UseSegments", "entry %d is not a segment id ([A-Za-z0-9-_]): %s", i, tostring(id))
        else
            route.uses[#route.uses + 1] = { id = id, source = source }
            n = n + 1
        end
    end
    route.dirty = true
    return n, errors
end

--- Record an insert: { after = "<stepId>" | before = "<stepId>", steps = { ... } }.
-- The steps are normalized now (format errors are reported here, once).
-- @return insert record or nil, errors (strings "insert after 'x' step 2: ...")
function Compose.AddInsert(route, def, source)
    local Schema = ns.Schema
    local errors = {}
    if type(def) ~= "table" then
        addErr(errors, "insert", "insert definition must be a table")
        return nil, errors
    end
    local side, anchor
    if def.after ~= nil and def.before ~= nil then
        addErr(errors, "insert", "give either `after` or `before`, not both")
        return nil, errors
    elseif def.after ~= nil then
        side, anchor = "after", def.after
    elseif def.before ~= nil then
        side, anchor = "before", def.before
    else
        addErr(errors, "insert", "`after = \"<stepId>\"` or `before = \"<stepId>\"` is required")
        return nil, errors
    end
    local where = format("insert %s '%s'", side, tostring(anchor))
    if type(anchor) ~= "string" or anchor == "" then
        addErr(errors, where, "the anchor must be a step id (string)")
        return nil, errors
    end
    for k in pairs(def) do
        if not INSERT_KEYS[k] then addErr(errors, where, "unknown key '%s'", tostring(k)) end
    end
    if type(def.steps) ~= "table" or #def.steps == 0 then
        addErr(errors, where, "steps must be a non-empty list")
        return nil, errors
    end
    local steps = {}
    for i, sdef in ipairs(def.steps) do
        local step = Schema.NormalizeStep(sdef, format("%s step %d", where, i), errors)
        step.explicitId = step.id
        step.inserted = true
        step.anchor = anchor
        step.insertSource = source
        steps[#steps + 1] = step
    end
    Compose.Enable(route)
    local ins = { side = side, anchor = anchor, steps = steps, n = #route.inserts + 1, source = source }
    route.inserts[#route.inserts + 1] = ins
    route.dirty = true
    return ins, errors
end

---------------------------------------------------------------------------
-- composition
---------------------------------------------------------------------------

local function indexOf(list, v)
    for i = 1, #list do
        if list[i] == v then return i end
    end
    return nil
end

local function kindOf(step)
    if step.inserted then return format("insert %s '%s'", tostring(step.insertSide), tostring(step.anchor)) end
    if step.library then return format("library segment %s", tostring(step.segment)) end
    return format("segment %s", tostring(step.segment))
end

-- the per-route copy of a library segment entry (copies cached per route: stable identity)
local function libraryEntry(route, libSeg, source)
    local cache = route.libCopies
    if not cache then
        cache = {}
        route.libCopies = cache
    end
    local steps = {}
    for i, t in ipairs(libSeg.steps) do
        local c = cache[t]
        if not c then
            c = shallowCopy(t)
            cache[t] = c
        end
        steps[i] = c
    end
    return { seg = libSeg, steps = steps, source = source, library = true }
end

--- Compose a route (see the header). Rewrites route.segments / steps / stepById /
-- segmentById (step.index = position), merges the library data into route.data
-- (route values win) when the route uses library segments.
-- @param lib library store (Compose.NewLibrary) or nil
-- @return errors: array of { msg = "...", source = <source given to AddUses / AddInsert> }
function Compose.Build(route, lib)
    local errors = {}
    local own = route.own
    if not own then return errors end
    local function err(source, msg, ...)
        errors[#errors + 1] = { msg = format(msg, ...), source = source }
    end
    local libSegs = lib and lib.segments or {}

    -- 1. segment order: own segments not named by UseSegments, then the UseSegments entries
    local moved = {}
    for _, u in ipairs(route.uses) do
        if own.segmentById[u.id] then moved[u.id] = true end
    end
    local entries = {}
    for _, seg in ipairs(own.segments) do
        if seg.id == nil or not moved[seg.id] then
            local steps = {}
            for i, s in ipairs(seg.steps) do steps[i] = s end
            entries[#entries + 1] = { seg = seg, steps = steps }
        end
    end
    local listed = {}
    for _, u in ipairs(route.uses) do
        if listed[u.id] then
            err(u.source, "UseSegments: segment '%s' is listed twice (second entry ignored)", u.id)
        else
            listed[u.id] = true
            local o, l = own.segmentById[u.id], libSegs[u.id]
            if o then
                if l then
                    err(u.source, "UseSegments: '%s' is both a segment of the route and a library segment "
                        .. "(the route's own segment is used)", u.id)
                end
                local steps = {}
                for i, s in ipairs(o.steps) do steps[i] = s end
                entries[#entries + 1] = { seg = o, steps = steps }
            elseif l then
                entries[#entries + 1] = libraryEntry(route, l, u.source)
            else
                err(u.source, "UseSegments: unknown library segment '%s' (is the library module loaded first? "
                    .. "list it in the TOC: ## Dependencies: FastesBoooy, <library module>)", u.id)
            end
        end
    end

    -- 2. inserts (call order; an anchor may be a step of an insert resolved earlier)
    local home = {} -- [stepId] = entry of the first step with this id
    for _, e in ipairs(entries) do
        for _, s in ipairs(e.steps) do
            if s.id ~= nil and home[s.id] == nil then home[s.id] = e end
        end
    end
    local pending = {}
    for i, ins in ipairs(route.inserts) do pending[i] = ins end
    local tail, count = {}, {}
    local progress = true
    while progress and #pending > 0 do
        progress = false
        local rest = {}
        for _, ins in ipairs(pending) do
            local e = home[ins.anchor]
            if not e then
                rest[#rest + 1] = ins
            else
                progress = true
                local anchorStep
                for _, s in ipairs(e.steps) do
                    if s.id == ins.anchor then anchorStep = s break end
                end
                local pos = indexOf(e.steps, anchorStep)
                if ins.side == "after" then
                    pos = indexOf(e.steps, tail[ins.anchor] or anchorStep) + 1
                end
                for _, s in ipairs(ins.steps) do
                    count[ins.anchor] = (count[ins.anchor] or 0) + 1
                    s.id = s.explicitId or format("%s+%d", ins.anchor, count[ins.anchor])
                    s.segment = anchorStep.segment
                    s.segIndex = anchorStep.segIndex
                    s.insertSide = ins.side
                    tinsert(e.steps, pos, s)
                    pos = pos + 1
                    if home[s.id] == nil then home[s.id] = e end
                end
                if ins.side == "after" then tail[ins.anchor] = e.steps[pos - 1] end
            end
        end
        pending = rest
    end
    for _, ins in ipairs(pending) do
        err(ins.source, "AddInsert: unknown anchor step '%s' (insert %s '%s' ignored)", ins.anchor, ins.side,
            ins.anchor)
    end

    -- 3. flatten, index, ids
    local segments, steps, byId, segById = {}, {}, {}, {}
    for _, e in ipairs(entries) do
        local seg = shallowCopy(e.seg)
        seg.steps = e.steps
        seg.first = #steps + 1
        for _, s in ipairs(e.steps) do
            steps[#steps + 1] = s
            s.index = #steps
            if s.id ~= nil then
                local prev = byId[s.id]
                if not prev then
                    byId[s.id] = s
                elseif prev.inserted or s.inserted
                    or (prev.library and true or false) ~= (s.library and true or false) then
                    -- own/own and library/library duplicates were reported by AddSegment / AddLibrarySegment
                    err(s.insertSource or e.source or prev.insertSource, "duplicate step id '%s' after composition "
                        .. "(%s and %s): step ids must be unique per route", s.id, kindOf(prev), kindOf(s))
                end
            end
        end
        seg.last = #steps
        segments[#segments + 1] = seg
        if seg.id ~= nil then
            if segById[seg.id] == nil then
                segById[seg.id] = seg
            elseif e.library then
                err(e.source, "duplicate segment id '%s' after composition", tostring(seg.id))
            end
        end
    end
    route.segments, route.steps, route.stepById, route.segmentById = segments, steps, byId, segById

    -- 4. library data under the route's own data
    if lib and #route.uses > 0 and next(lib.data) ~= nil then
        route.data = route.data or {}
        Compose.MergeData(route.data, lib.data, true)
    end
    route.dirty = false
    return errors
end

return Compose
