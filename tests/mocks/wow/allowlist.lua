-- tests/mocks/wow/allowlist.lua
--
-- Loads tools/data/forever_api.lua (the generated API surface of the WoW: Forever
-- client) once per Lua state and derives the lookup structures the strict mock
-- needs: name sets, closed namespace field sets, resolved widget method / script
-- handler sets per widget type, template types, events and argument signatures.
--
-- Pure data; no mock state. Loaded by tests/mocks/wow.lua through loadfile.

local DIR = ...                     -- directory of tests/mocks/ (with trailing slash)

local A = {}

local function set(list)
    local s = {}
    for _, v in ipairs(list or {}) do s[v] = true end
    return s
end

local function loadData(path)
    local fn, err = loadfile(path)
    if not fn then
        error("mock: cannot load the Forever API list " .. path .. ": " .. tostring(err)
            .. " (run `make api` / tools/gen_forever_api.py)", 0)
    end
    setfenv(fn, {})                 -- generated data file: plain table constructor only
    local ok, data = pcall(fn)
    if not ok or type(data) ~= "table" then
        error("mock: invalid Forever API list " .. path .. ": " .. tostring(data), 0)
    end
    return data
end

function A.load(apiPath)
    local api = loadData(apiPath)
    A.api = api
    A.path = apiPath

    -- every list whose entries are plain global names that exist in the client
    A.globalLists = {
        "globals", "luaGlobals", "frameXMLGlobals", "frameXMLExtraGlobals", "frames", "fonts",
        "mixins", "uiColorGlobals", "leGlobals",
    }
    local globals = {}
    for _, list in ipairs(A.globalLists) do
        for _, name in ipairs(api[list] or {}) do
            if globals[name] == nil then globals[name] = list end
        end
    end
    -- globals the dump misses but that were confirmed in game (tools/data/forever_api_confirmed.lua)
    local confirmedPath = apiPath:gsub("forever_api%.lua$", "forever_api_confirmed.lua")
    if confirmedPath ~= apiPath then
        A.confirmed = loadData(confirmedPath)
        for _, name in ipairs(A.confirmed.globals or {}) do
            if globals[name] == nil then globals[name] = "confirmed" end
        end
    end
    for ns in pairs(api.namespaces or {}) do globals[ns] = globals[ns] or "namespaces" end
    for lib in pairs(api.luaNamespaces or {}) do globals[lib] = globals[lib] or "luaNamespaces" end
    for t in pairs(api.frameXMLTables or {}) do globals[t] = globals[t] or "frameXMLTables" end
    globals.Enum = globals.Enum or "enums"
    globals.Constants = globals.Constants or "constants"
    globals._G = globals._G or "lua"
    globals._VERSION = globals._VERSION or "lua"
    A.globals = globals             -- name -> list it comes from

    A.namespaces = {}               -- C_X -> set of function names
    for ns, names in pairs(api.namespaces or {}) do A.namespaces[ns] = set(names) end
    A.luaNamespaces = {}            -- string/table/math/bit/coroutine -> set
    for lib, names in pairs(api.luaNamespaces or {}) do A.luaNamespaces[lib] = set(names) end
    A.frameXMLTables = {}           -- SomeUtil -> set
    for t, names in pairs(api.frameXMLTables or {}) do A.frameXMLTables[t] = set(names) end

    A.events = set(api.events)
    A.templates = set(api.templates)
    A.templateTypes = api.templateTypes or {}
    A.fonts = set(api.fonts)
    A.frames = set(api.frames)
    A.mixins = set(api.mixins)
    A.uiColors = set(api.uiColorGlobals)
    A.leValues = api.leValues or {}
    A.enums = api.enums or {}
    A.constants = api.constants or {}
    A.build = api.build or {}
    A.meta = api.meta or {}

    -- widget types ------------------------------------------------------
    -- Known quirk of the KethoDoc dump: "Region" lists itself as its parent
    -- (inherits = {"Region"}); in the client Region (SimpleRegionAPI) derives
    -- from ScriptRegion. tools/gen_forever_api.py already writes ScriptRegion;
    -- self references are still replaced here as a safety net (older data files).
    local inherits = {}
    for wtype, parents in pairs(api.widgetInherits or {}) do
        local fixed = {}
        for _, p in ipairs(parents) do
            if p == wtype then p = "ScriptRegion" end
            fixed[#fixed + 1] = p
        end
        inherits[wtype] = fixed
    end
    A.widgetInherits = inherits

    local ancestry = {}             -- type -> ordered list (self first) of all ancestors
    local function resolve(wtype, seen)
        if ancestry[wtype] then return ancestry[wtype] end
        seen = seen or {}
        if seen[wtype] then error("mock: widget inheritance cycle at " .. wtype, 0) end
        seen[wtype] = true
        local out, have = { wtype }, { [wtype] = true }
        for _, p in ipairs(inherits[wtype] or {}) do
            for _, anc in ipairs(resolve(p, seen)) do
                if not have[anc] then have[anc] = true; out[#out + 1] = anc end
            end
        end
        ancestry[wtype] = out
        return out
    end
    A.widgetMethods, A.widgetHandlers, A.widgetAncestry, A.widgetIsA = {}, {}, {}, {}
    for wtype in pairs(api.widgetMethods or {}) do
        local anc = resolve(wtype)
        local methods, handlers, isa = {}, {}, {}
        for _, t in ipairs(anc) do
            isa[t] = true
            for _, m in ipairs(api.widgetMethods[t] or {}) do methods[m] = true end
            for _, h in ipairs(api.widgetHandlers[t] or {}) do handlers[h] = true end
        end
        A.widgetMethods[wtype] = methods
        A.widgetHandlers[wtype] = handlers
        A.widgetAncestry[wtype] = anc
        A.widgetIsA[wtype] = isa
    end

    -- Frame-derived types that CreateFrame accepts (case-insensitive lookup)
    A.frameTypes = {}
    for wtype, isa in pairs(A.widgetIsA) do
        if isa.Frame then A.frameTypes[wtype:lower()] = wtype end
    end

    -- argument signatures (generated from the API documentation) -----------
    local sigPath = DIR .. "wow/signatures.lua"
    local sigs = loadData(sigPath)
    A.signatures = sigs.functions or {}
    A.eventPayloads = sigs.events or {}
    local parsed = {}
    for name, args in pairs(A.signatures) do
        local p = {}
        for i, a in ipairs(args) do
            local argName, code, opt = a:match("^([^:]+):(%a)(%??)$")
            p[i] = { name = argName, code = code, optional = opt == "?" }
        end
        parsed[name] = p
    end
    A.parsedSignatures = parsed
    local parsedEvents = {}
    for name, args in pairs(A.eventPayloads) do
        local p = {}
        for i, a in ipairs(args) do
            local argName, code, opt = a:match("^([^:]+):(%a)(%??)$")
            p[i] = { name = argName, code = code, optional = opt == "?" }
        end
        parsedEvents[name] = p
    end
    A.parsedEvents = parsedEvents
    return A
end

--- Does `name` exist as a global in the Forever client?
function A.isGlobal(name)
    return A.globals[name] ~= nil
end

--- Is `fn` a member of namespace / library / FrameXML table `owner`?
function A.isMember(owner, fn)
    local s = A.namespaces[owner] or A.luaNamespaces[owner] or A.frameXMLTables[owner]
    return s ~= nil and s[fn] == true
end

local CODE_NAMES = {
    n = "number", s = "string", u = "unit token", g = "GUID string", t = "table",
    f = "function", x = "number or string",
}

--- Check a value against an argument code; returns nil or an error description.
function A.checkValue(code, v)
    local tv = type(v)
    if code == "n" then
        if tv ~= "number" then return CODE_NAMES.n end
    elseif code == "s" then
        if tv ~= "string" and tv ~= "number" then return CODE_NAMES.s end
    elseif code == "u" or code == "g" then
        if tv ~= "string" then return CODE_NAMES[code] end
    elseif code == "t" then
        if tv ~= "table" then return CODE_NAMES.t end
    elseif code == "f" then
        if tv ~= "function" then return CODE_NAMES.f end
    elseif code == "x" then
        if tv ~= "number" and tv ~= "string" then return CODE_NAMES.x end
    end
    return nil
end

return A
