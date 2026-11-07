-- tools/lib/route_loader.lua -- load route modules offline (Lua 5.1).
--
-- A route module is an addon directory (addons/FastesBoooy_<Name>/) whose TOC lists
-- Route.lua, Data.lua and Segments/*.lua. The files are executed in a SANDBOX whose
-- only global besides the pure Lua libraries is a stub `FastesBoooy` table that
-- captures RegisterRoute / AddSegment / AddRouteData and normalizes them with the
-- real route-format contract (addons/FastesBoooy/Core/Schema.lua), exactly like the
-- addon's Registry does (segments that arrive before their route are queued and an
-- error is recorded).
--
--   local Loader = require("lib.route_loader")
--   local Schema = Loader.LoadSchema(root)
--   local mod = Loader.LoadModule(dir, { schema = Schema, skip = { ["Data.lua"] = true } })
--   mod.routes        -- array of normalized routes (Schema.NormalizeRoute + AddSegment)
--   mod.errors        -- array of { file = "Segments/01.lua", msg = "..." }
--   mod.data[id]      -- merged AddRouteData tables per route id
--   mod.segmentFile[id][segId] -- file that added the segment
--   mod.toc           -- { files = {...}, meta = { Interface = "16001", ... } }

local Loader = {}

local function readFile(path)
    local fh = io.open(path, "r")
    if not fh then return nil end
    local s = fh:read("*a")
    fh:close()
    return s
end
Loader.readFile = readFile

local function fileExists(path)
    local fh = io.open(path, "r")
    if fh then fh:close() return true end
    return false
end
Loader.fileExists = fileExists

--- Pure-Lua globals available to sandboxed route files (no io/os/require/load*).
local function baseEnv()
    local env = {
        assert = assert, error = error, ipairs = ipairs, next = next, pairs = pairs,
        pcall = pcall, select = select, tonumber = tonumber, tostring = tostring,
        type = type, unpack = unpack, xpcall = xpcall, rawget = rawget, rawset = rawset,
        rawequal = rawequal, setmetatable = setmetatable, getmetatable = getmetatable,
        _VERSION = _VERSION,
    }
    local function copy(lib)
        local t = {}
        for k, v in pairs(lib) do t[k] = v end
        return t
    end
    env.string = copy(string)
    env.table = copy(table)
    env.math = copy(math)
    env._G = env
    return env
end
Loader.baseEnv = baseEnv

--- Load the route-format contract.
-- @param root repository root (contains addons/FastesBoooy/Core/Schema.lua)
function Loader.LoadSchema(root)
    local path = (root or ".") .. "/addons/FastesBoooy/Core/Schema.lua"
    local chunk, err = loadfile(path)
    if not chunk then error("cannot load Schema: " .. tostring(err), 0) end
    setfenv(chunk, baseEnv())
    local ns = {}
    local ret = chunk("FastesBoooy", ns)
    local Schema = type(ret) == "table" and ret or ns.Schema
    if type(Schema) ~= "table" or type(Schema.NormalizeRoute) ~= "function" then
        error("Schema.lua did not return the Schema table", 0)
    end
    return Schema
end

--- Parse a TOC file. @return { files = {relpath...}, meta = {key = value} } or nil, err
function Loader.ParseToc(path)
    local text = readFile(path)
    if not text then return nil, "cannot read " .. path end
    local toc = { files = {}, meta = {} }
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        line = line:gsub("\r$", ""):gsub("^%s+", ""):gsub("%s+$", "")
        local key, value = line:match("^##%s*([^:]+):%s*(.-)$")
        if key then
            toc.meta[key:gsub("%s+$", "")] = value
        elseif line ~= "" and not line:match("^#") then
            -- strip load conditions such as [AllowLoadGameType camelot]
            local f = line:gsub("%s*%[[^%]]*%]%s*", ""):gsub("\\", "/")
            if f ~= "" then toc.files[#toc.files + 1] = f end
        end
    end
    return toc
end

local function basename(path)
    return (path:gsub("[/\\]+$", ""):match("([^/\\]+)$")) or path
end
Loader.basename = basename

--- Find the TOC of a module directory (<dir>/<DirName>.toc, else the only *.toc listed).
function Loader.FindToc(dir)
    local name = basename(dir)
    local candidates = { name .. ".toc", name .. "_Camelot.toc", name .. "_Mainline.toc" }
    for _, c in ipairs(candidates) do
        local p = dir .. "/" .. c
        if fileExists(p) then return p end
    end
    return nil
end

--- Execute the module's files in a sandbox and capture its registrations.
-- @param dir module directory
-- @param opts { schema = Schema (required), skip = { [relpath] = true }, files = {override list} }
function Loader.LoadModule(dir, opts)
    opts = opts or {}
    local Schema = assert(opts.schema, "LoadModule: opts.schema required")
    dir = dir:gsub("[/\\]+$", "")
    local mod = {
        dir = dir, name = basename(dir), routes = {}, routeById = {}, errors = {},
        data = {}, segmentFile = {}, files = {}, pending = {},
    }
    local currentFile = "?"

    local function addError(msg, file)
        mod.errors[#mod.errors + 1] = { file = file or currentFile, msg = msg }
    end
    local function addErrors(list, prefix)
        for _, e in ipairs(list or {}) do
            addError(prefix and (prefix .. ": " .. e) or e)
        end
    end

    local api = {}
    local function addSegment(routeId, def)
        local route = mod.routeById[routeId]
        local seg, errs = Schema.AddSegment(route, def)
        addErrors(errs, "route " .. tostring(routeId))
        if seg and seg.id ~= nil then
            mod.segmentFile[routeId] = mod.segmentFile[routeId] or {}
            mod.segmentFile[routeId][seg.id] = currentFile
            seg.file = currentFile
            for _, step in ipairs(seg.steps) do step.file = currentFile end
        end
        return seg
    end
    local function addData(routeId, data)
        local dst = mod.data[routeId] or {}
        mod.data[routeId] = dst
        for kind, t in pairs(data) do
            if type(t) == "table" then
                dst[kind] = dst[kind] or {}
                for k, v in pairs(t) do dst[kind][k] = v end
            else
                dst[kind] = t
            end
        end
    end

    function api.RegisterRoute(def)
        local route, errs = Schema.NormalizeRoute(def)
        addErrors(errs)
        local id = type(def) == "table" and def.id or nil
        if not route or type(id) ~= "string" or id == "" then return nil end
        if mod.routeById[id] then
            addError(("route %s: registered twice (second definition ignored)"):format(id))
            return nil
        end
        route.file = currentFile
        route.module = mod.name
        mod.routeById[id] = route
        mod.routes[#mod.routes + 1] = route
        local pending = mod.pending[id]
        mod.pending[id] = nil
        for _, p in ipairs(pending or {}) do
            local saved = currentFile
            currentFile = p.file
            if p.kind == "segment" then addSegment(id, p.def) else addData(id, p.def) end
            currentFile = saved
        end
        return route
    end

    function api.AddSegment(routeId, def)
        if type(routeId) ~= "string" then
            addError(("AddSegment: invalid route id %s"):format(tostring(routeId)))
            return nil
        end
        if not mod.routeById[routeId] then
            addError(("AddSegment %s: route %s is not registered yet (RegisterRoute must come first)")
                :format(tostring(type(def) == "table" and def.id), routeId))
            local q = mod.pending[routeId] or {}
            q[#q + 1] = { kind = "segment", def = def, file = currentFile }
            mod.pending[routeId] = q
            return nil
        end
        return addSegment(routeId, def)
    end

    function api.AddRouteData(routeId, data)
        if type(data) ~= "table" then
            addError(("AddRouteData %s: data must be a table"):format(tostring(routeId)))
            return false
        end
        if type(routeId) ~= "string" then
            addError(("AddRouteData: invalid route id %s"):format(tostring(routeId)))
            return false
        end
        if not mod.routeById[routeId] then
            addError(("AddRouteData: route %s is not registered yet (RegisterRoute must come first)"):format(routeId))
            local q = mod.pending[routeId] or {}
            q[#q + 1] = { kind = "data", def = data, file = currentFile }
            mod.pending[routeId] = q
            return false
        end
        addData(routeId, data)
        return true
    end

    local files = opts.files
    if not files then
        local tocPath = Loader.FindToc(dir)
        if not tocPath then
            addError("no TOC file found (expected " .. mod.name .. ".toc)", mod.name .. ".toc")
            return mod
        end
        local toc, err = Loader.ParseToc(tocPath)
        if not toc then
            addError(err, basename(tocPath))
            return mod
        end
        mod.toc = toc
        mod.tocFile = basename(tocPath)
        files = toc.files
        local iface = toc.meta.Interface
        if iface and not tostring(iface):match("^16%d%d%d") then
            addError("## Interface must be 16001 (Forever), got " .. tostring(iface), mod.tocFile)
        end
        local deps = toc.meta.Dependencies or toc.meta.RequiredDeps or ""
        if not deps:find("FastesBoooy", 1, true) then
            addError("## Dependencies must include FastesBoooy", mod.tocFile)
        end
    end

    -- one private addon table shared by every file of the module (`local _, ns = ...`),
    -- like the WoW client and Mock.loadAddon
    local private = {}
    for _, rel in ipairs(files) do
        if not (opts.skip and opts.skip[rel]) then
            currentFile = rel
            mod.files[#mod.files + 1] = rel
            local path = dir .. "/" .. rel
            if not rel:match("%.lua$") then
                addError("only .lua files are supported in route modules (got " .. rel .. ")")
            else
                local chunk, err = loadfile(path)
                if not chunk then
                    addError("load error: " .. tostring(err))
                else
                    local env = baseEnv()
                    env.FastesBoooy = api
                    setfenv(chunk, env)
                    local ok, rerr = pcall(chunk, mod.name, private)
                    if not ok then addError("runtime error: " .. tostring(rerr)) end
                    local base = baseEnv()
                    for k in pairs(env) do
                        if k ~= "FastesBoooy" and base[k] == nil then
                            addError(("defines global '%s' (route modules may only call FastesBoooy.*)"):format(tostring(k)))
                        end
                    end
                end
            end
        end
    end
    currentFile = "?"
    for routeId, list in pairs(mod.pending) do
        for _, p in ipairs(list) do
            addError(("%s for route %s was never registered"):format(p.kind, routeId), p.file)
        end
    end
    return mod
end

--- List route module directories under `addonsDir` (FastesBoooy_* with a TOC), sorted.
function Loader.DiscoverModules(addonsDir)
    local out = {}
    local p = io.popen('ls -1 "' .. addonsDir:gsub('"', '\\"') .. '" 2>/dev/null')
    if not p then return out end
    for name in p:lines() do
        if name:match("^FastesBoooy_") then
            local dir = addonsDir .. "/" .. name
            if Loader.FindToc(dir) then out[#out + 1] = dir end
        end
    end
    p:close()
    table.sort(out)
    return out
end

return Loader
