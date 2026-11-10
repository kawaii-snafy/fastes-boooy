-- tools/lib/route_loader.lua -- load route modules offline (Lua 5.1).
--
-- A route module is an addon directory (addons/FastesBoooy_<Name>/) whose TOC lists
-- Route.lua, Data.lua and Segments/*.lua. The files are executed in a SANDBOX whose
-- only global besides the pure Lua libraries is a stub `FastesBoooy` table that
-- captures RegisterRoute / AddSegment / AddRouteData / AddLibrarySegment /
-- AddLibraryData / AddLibraryInsert / UseSegments / AddInsert and normalizes them with the real
-- route-format contract (addons/FastesBoooy/Core/Schema.lua) and composes the routes
-- with the real composition code (addons/FastesBoooy/Core/Compose.lua), exactly like
-- the addon's Registry does (registrations that arrive before their route are queued
-- and an error is recorded).
--
-- Dependencies: the FastesBoooy_* addons named by "## Dependencies" / "## RequiredDeps"
-- of the module's TOC (e.g. the shared library FastesBoooy_Horde) are loaded first,
-- recursively, from the same addons directory, each with its own private addon table
-- -- the load order of the client. Their file names are reported as
-- "<Dependency>/<file>" and their registrations carry `library = "<Dependency>"`.
--
--   local Loader = require("lib.route_loader")
--   local Schema = Loader.LoadSchema(root)          -- Schema.Compose = Core/Compose.lua
--   local mod = Loader.LoadModule(dir, { schema = Schema, skip = { ["Data.lua"] = true } })
--   Loader.LoadModule(dir, { schema = Schema, replace = { ["Segments/A.lua"] = "/other/file.lua" } })
--                     -- the TOC entry Segments/A.lua is read from the other file
--   mod.routes        -- array of normalized, composed routes registered by the module itself
--   mod.errors        -- array of { file = "Segments/01.lua", msg = "...", library = "<Dep>"|nil }
--   mod.data[id]      -- merged AddRouteData tables per route id (+ library data under it)
--   mod.segmentFile[id][segId] -- file that added the segment
--   mod.toc           -- { files = {...}, meta = { Interface = "16001", ... } }
--   mod.deps          -- { { name, dir, toc }, ... } dependency modules in load order
--   mod.lib           -- library store (Compose.NewLibrary) of the whole load
--   mod.librarySegments -- library segments registered by the module's own files
--   mod.libraryInserts  -- shared inserts (AddLibraryInsert) registered by the module's own files: the
--                          TEMPLATES { side, anchor, steps, scope = filters | nil, file, applied = { [routeId] =
--                          true } } (Compose.AddLibraryInsert). A route's copy of a template step t (of a
--                          shared insert or of a library segment) is route.libCopies[t]: it exists when t was
--                          composed into the route (and is then route.stepById[t.id])
--   mod.aliases       -- [former route id] = route (RegisterRoute{ aliases = ... })
--   mod.declaredLibrary -- the TOC says "## X-FastesBoooy-Module: library"
--   mod.isLibrary     -- no route, and library segments / inserts / data registered or declared in the TOC
--                        (a declared library may still be empty: placeholder segment files)
-- A module without the TOC line "## X-FastesBoooy-Module: library" may register shared content AND
-- routes (FastesBoooy_Guides); a declared library may not register routes.

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

--- Load the route-format contract (Core/Schema.lua) and the composition code
-- (Core/Compose.lua) with one shared `ns`, like the addon's TOC does.
-- @param root repository root (contains addons/FastesBoooy/Core/Schema.lua)
-- @return Schema (Schema.Compose = the Compose table), Compose
function Loader.LoadSchema(root)
    local core = (root or ".") .. "/addons/FastesBoooy/Core/"
    local ns = {}
    local function run(file)
        local chunk, err = loadfile(core .. file)
        if not chunk then error("cannot load " .. file .. ": " .. tostring(err), 0) end
        setfenv(chunk, baseEnv())
        return chunk("FastesBoooy", ns)
    end
    local ret = run("Schema.lua")
    local Schema = type(ret) == "table" and ret or ns.Schema
    if type(Schema) ~= "table" or type(Schema.NormalizeRoute) ~= "function" then
        error("Schema.lua did not return the Schema table", 0)
    end
    ns.Schema = Schema
    local cret = run("Compose.lua")
    local Compose = type(cret) == "table" and cret or ns.Compose
    if type(Compose) ~= "table" or type(Compose.Build) ~= "function" then
        error("Compose.lua did not return the Compose table", 0)
    end
    Schema.Compose = Compose
    return Schema, Compose
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

--- FastesBoooy_* dependencies named by a parsed TOC (## Dependencies, ## RequiredDeps).
function Loader.Dependencies(toc)
    local out, seen = {}, {}
    for _, key in ipairs({ "Dependencies", "RequiredDeps" }) do
        for name in tostring(toc and toc.meta[key] or ""):gmatch("[^,%s]+") do
            if name:match("^FastesBoooy_") and not seen[name] then
                seen[name] = true
                out[#out + 1] = name
            end
        end
    end
    return out
end

local function dirname(path)
    return path:match("^(.*)[/\\][^/\\]+$") or "."
end

--- Execute the module's files (after its FastesBoooy_* dependencies) in a sandbox,
-- capture the registrations and compose the module's routes.
-- @param dir module directory
-- @param opts { schema = Schema (required), skip = { [relpath] = true } (module's own files),
--               replace = { [relpath] = "<path of another file>" } (module's own files: the TOC entry
--               is read from that path; the file name reported stays the TOC path),
--               files = {override list}, compose = Compose (default schema.Compose),
--               addons = directory of the dependencies (default: the parent of dir),
--               deps = false (do not load dependencies) }
function Loader.LoadModule(dir, opts)
    opts = opts or {}
    local Schema = assert(opts.schema, "LoadModule: opts.schema required")
    local Compose = opts.compose or Schema.Compose
    if not Compose then
        local root = (debug.getinfo(1, "S").source:match("^@(.*)/tools/lib/route_loader%.lua$")) or "."
        Compose = select(2, Loader.LoadSchema(root))
    end
    dir = dir:gsub("[/\\]+$", "")
    local mod = {
        dir = dir, name = basename(dir), routes = {}, routeById = {}, errors = {},
        data = {}, segmentFile = {}, files = {}, pending = {}, deps = {},
        lib = Compose.NewLibrary(), librarySegments = {}, librarySegmentFile = {}, libraryData = false,
        libraryInserts = {}, aliases = {},
    }
    local lib = mod.lib
    local currentFile, currentModule = "?", mod.name

    local function addError(msg, file)
        local e = { file = file or currentFile, msg = msg }
        if currentModule ~= mod.name then e.library = currentModule end
        mod.errors[#mod.errors + 1] = e
    end
    local function addErrors(list, prefix)
        for _, e in ipairs(list or {}) do
            addError(prefix and (prefix .. ": " .. e) or e)
        end
    end

    local api = {}
    local function addSegment(routeId, def)
        local route = mod.routeById[routeId]
        local seg, errs = Schema.AddSegment(Compose.OwnTarget(route), def)
        addErrors(errs, "route " .. tostring(routeId))
        if seg then
            if route.own then route.dirty = true end
            seg.file = currentFile
            for _, step in ipairs(seg.steps) do step.file = currentFile end
            if seg.id ~= nil then
                mod.segmentFile[routeId] = mod.segmentFile[routeId] or {}
                mod.segmentFile[routeId][seg.id] = currentFile
            end
        end
        return seg
    end
    local function addData(routeId, data)
        Compose.MergeData(mod.routeById[routeId].data, data)
    end
    local function useSegments(routeId, ids)
        local n, errs = Compose.AddUses(mod.routeById[routeId], ids, currentFile)
        addErrors(errs, "route " .. tostring(routeId))
        return n > 0
    end
    local function addInsert(routeId, def)
        local ins, errs = Compose.AddInsert(mod.routeById[routeId], def, currentFile)
        addErrors(errs, "route " .. tostring(routeId))
        if ins then
            for _, step in ipairs(ins.steps) do step.file = currentFile end
        end
        return ins
    end
    local APPLY = { segment = addSegment, data = addData, uses = useSegments, insert = addInsert }

    -- registration before RegisterRoute: error + queue (applied when the route arrives)
    local function queue(routeId, kind, def, what)
        if type(routeId) ~= "string" then
            addError(("%s: invalid route id %s"):format(what, tostring(routeId)))
            return
        end
        addError(("%s: route %s is not registered yet (RegisterRoute must come first)"):format(what, routeId))
        local q = mod.pending[routeId] or {}
        q[#q + 1] = { kind = kind, def = def, file = currentFile, module = currentModule }
        mod.pending[routeId] = q
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
        if mod.aliases[id] then
            addError(("route %s: its id is an alias of route %s (alias ignored)"):format(id, tostring(mod.aliases[id].id)))
            mod.aliases[id] = nil
        end
        route.file = currentFile
        route.module = currentModule
        route.data = {}
        mod.routeById[id] = route
        -- former ids, like Registry:RegisterRoute (a route id always wins over an alias)
        for _, alias in ipairs(route.aliases or {}) do
            if mod.routeById[alias] then
                addError(("route %s: alias '%s' is the id of a registered route (alias ignored)"):format(id, alias))
            elseif mod.aliases[alias] then
                addError(("route %s: alias '%s' is already used by route %s (alias ignored)"):format(id, alias,
                    tostring(mod.aliases[alias].id)))
            else
                mod.aliases[alias] = route
            end
        end
        if currentModule == mod.name then
            mod.routes[#mod.routes + 1] = route
            mod.data[id] = route.data
        end
        local pending = mod.pending[id]
        mod.pending[id] = nil
        for _, p in ipairs(pending or {}) do
            local savedFile, savedModule = currentFile, currentModule
            currentFile, currentModule = p.file, p.module
            APPLY[p.kind](id, p.def)
            currentFile, currentModule = savedFile, savedModule
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
            q[#q + 1] = { kind = "segment", def = def, file = currentFile, module = currentModule }
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
        if not mod.routeById[routeId] then
            queue(routeId, "data", data, "AddRouteData")
            return false
        end
        addData(routeId, data)
        return true
    end

    function api.UseSegments(routeId, ids)
        if not mod.routeById[routeId] then
            queue(routeId, "uses", ids, "UseSegments")
            return false
        end
        return useSegments(routeId, ids)
    end

    function api.AddInsert(routeId, def)
        if not mod.routeById[routeId] then
            queue(routeId, "insert", def, "AddInsert")
            return nil
        end
        return addInsert(routeId, def)
    end

    function api.AddLibrarySegment(def)
        local seg, errs = Compose.AddLibrarySegment(lib, def, { module = currentModule, file = currentFile })
        addErrors(errs, "library")
        if seg then
            mod.librarySegmentFile[seg.id] = currentFile
            if currentModule == mod.name then mod.librarySegments[#mod.librarySegments + 1] = seg end
        end
        return seg
    end

    function api.AddLibraryInsert(def)
        local ins, errs = Compose.AddLibraryInsert(lib, def, { module = currentModule, file = currentFile })
        addErrors(errs, "library")
        if ins then
            ins.file, ins.module = currentFile, currentModule
            if currentModule == mod.name then mod.libraryInserts[#mod.libraryInserts + 1] = ins end
        end
        return ins
    end

    function api.AddLibraryData(data)
        local ok, err = Compose.AddLibraryData(lib, data)
        if not ok then
            addError("AddLibraryData: " .. tostring(err))
            return false
        end
        if currentModule == mod.name then mod.libraryData = true end
        return true
    end

    -- run the files of one module (`prefix` qualifies the file names of dependencies)
    local function runFiles(mdir, mname, files, skip, prefix, replace)
        -- one private addon table shared by every file of the module (`local _, ns = ...`),
        -- like the WoW client and Mock.loadAddon
        local private = {}
        for _, rel in ipairs(files) do
            if not (skip and skip[rel]) then
                currentFile, currentModule = prefix .. rel, mname
                if mname == mod.name then mod.files[#mod.files + 1] = rel end
                local path = (replace and replace[rel]) or (mdir .. "/" .. rel)
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
                        local ok, rerr = pcall(chunk, mname, private)
                        if not ok then addError("runtime error: " .. tostring(rerr)) end
                        local base = baseEnv()
                        for k in pairs(env) do
                            if k ~= "FastesBoooy" and base[k] == nil then
                                addError(("defines global '%s' (route modules may only call FastesBoooy.*)")
                                    :format(tostring(k)))
                            end
                        end
                    end
                end
            end
        end
        currentFile, currentModule = "?", mod.name
    end

    -- TOC of a module directory; checks Interface and the core dependency
    local function readToc(mdir, mname, label)
        local saved = currentModule
        currentModule = mname
        local tocPath = Loader.FindToc(mdir)
        if not tocPath then
            addError("no TOC file found (expected " .. mname .. ".toc)", label .. mname .. ".toc")
            currentModule = saved
            return nil
        end
        local toc, err = Loader.ParseToc(tocPath)
        local tocFile = label .. basename(tocPath)
        if not toc then
            addError(err, tocFile)
            currentModule = saved
            return nil
        end
        local iface = toc.meta.Interface
        if iface and not tostring(iface):match("^16%d%d%d") then
            addError("## Interface must be 16001 (Forever), got " .. tostring(iface), tocFile)
        end
        local deps = (toc.meta.Dependencies or "") .. "," .. (toc.meta.RequiredDeps or "")
        local hasCore = false
        for name in deps:gmatch("[^,%s]+") do
            if name == "FastesBoooy" then hasCore = true end
        end
        if not hasCore then
            addError("## Dependencies must include FastesBoooy", tocFile)
        end
        currentModule = saved
        return toc, tocFile, tocPath
    end

    local files = opts.files
    local toc
    if not files then
        local tocFile
        toc, tocFile = readToc(dir, mod.name, "")
        if not toc then return mod end
        mod.toc = toc
        mod.tocFile = tocFile
        files = toc.files
        local kind = toc.meta["X-FastesBoooy-Module"]
        if kind ~= nil then
            if kind == "library" then
                mod.declaredLibrary = true
            else
                addError("## X-FastesBoooy-Module must be \"library\" (got \"" .. tostring(kind) .. "\")", tocFile)
            end
        end
    end

    -- dependencies first (depth first, in TOC order), like the client
    if opts.deps ~= false and toc then
        local addonsDir = opts.addons or dirname(dir)
        local state = { [mod.name] = "loading" }
        local function loadDeps(names, from)
            for _, name in ipairs(names) do
                if state[name] == "loading" then
                    addError(("dependency cycle: %s -> %s"):format(from, name), mod.tocFile)
                elseif state[name] == nil then
                    state[name] = "loading"
                    local ddir = addonsDir .. "/" .. name
                    if not Loader.FindToc(ddir) then
                        addError(("dependency %s (## Dependencies of %s) not found in %s"):format(name, from, addonsDir),
                            mod.tocFile)
                    else
                        local dtoc, _, dtocPath = readToc(ddir, name, name .. "/")
                        if dtoc then
                            loadDeps(Loader.Dependencies(dtoc), name)
                            mod.deps[#mod.deps + 1] = { name = name, dir = ddir, toc = dtocPath }
                            runFiles(ddir, name, dtoc.files, nil, name .. "/")
                        end
                    end
                    state[name] = "done"
                end
            end
        end
        loadDeps(Loader.Dependencies(toc), mod.name)
    end

    if opts.replace then
        local listed = {}
        for _, rel in ipairs(files) do listed[rel] = true end
        local unknown = {}
        for rel in pairs(opts.replace) do
            if not listed[rel] then unknown[#unknown + 1] = tostring(rel) end
        end
        table.sort(unknown)
        for _, rel in ipairs(unknown) do
            addError("replace: " .. rel .. " is not a file of the TOC", mod.tocFile or rel)
        end
    end
    runFiles(dir, mod.name, files, opts.skip, "", opts.replace)

    for routeId, list in pairs(mod.pending) do
        for _, p in ipairs(list) do
            currentModule = p.module
            addError(("%s for route %s was never registered"):format(p.kind, routeId), p.file)
        end
    end
    currentModule = mod.name

    -- compose the routes (UseSegments / AddInsert / the shared inserts), exactly like the addon's
    -- Registry; each composition error once per route, like Registry:Finalize
    for _, route in ipairs(mod.routes) do
        if route.own then
            local seen = {}
            for _, e in ipairs(Compose.Build(route, lib)) do
                local msg = "route " .. tostring(route.id) .. ": " .. e.msg
                local src, srcModule = e.source, mod.name
                if type(src) == "table" then
                    -- a shared insert: { module, file } (Compose.AddLibraryInsert)
                    src, srcModule = src.file, src.module or mod.name
                end
                local file = src or route.file
                local key = msg .. "\0" .. tostring(file)
                if not seen[key] then
                    seen[key] = true
                    currentModule = srcModule
                    addError(msg, file)
                    currentModule = mod.name
                end
            end
        end
    end
    mod.isLibrary = #mod.routes == 0 and (#mod.librarySegments > 0 or #mod.libraryInserts > 0 or mod.libraryData
        or mod.declaredLibrary or false)
    if mod.declaredLibrary and #mod.routes > 0 then
        addError("## X-FastesBoooy-Module: library, but the module registers route(s): a library module only "
            .. "registers library segments / data", mod.tocFile)
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
