-- tests/mocks/wow/luaenv.lua
--
-- The Lua 5.1 environment of the WoW: Forever client: the base library, the
-- string/table/math/bit/coroutine libraries restricted to the members that exist
-- in the client (tools/data/forever_api.lua luaGlobals / luaNamespaces) plus the
-- WoW Lua extensions (strsplit, wipe, tContains, string.split, math.round, bit.*...).
-- There is no io / os / debug / require / dofile / loadfile / package.
--
-- Usage (from tests/mocks/wow.lua): install(m, A) where m:Provide(name, value)
-- asserts that every installed name exists in the client.

local hostG = _G
local floor, ceil, huge = math.floor, math.ceil, math.huge
local select, type, pairs, ipairs, tostring, tonumber = select, type, pairs, ipairs, tostring, tonumber
local sfind, ssub, sgsub, sformat, sbyte = string.find, string.sub, string.gsub, string.format, string.byte

local W = {}                     -- WoW Lua extensions (implemented here)

---------------------------------------------------------------------------
-- strings
---------------------------------------------------------------------------

-- strsplit(delimiters, str [, pieces]): every character of `delimiters` is a separator.
function W.strsplit(delim, str, pieces)
    if type(delim) ~= "string" or type(str) ~= "string" and type(str) ~= "number" then
        error("Usage: strsplit(delimiter, subject [, pieces])", 2)
    end
    str = tostring(str)
    local out, n, pos = {}, 0, 1
    local class = "[" .. delim:gsub("[%]%^%-%%]", "%%%0") .. "]"
    pieces = tonumber(pieces)
    while true do
        if pieces and n >= pieces - 1 then break end
        local s, e = sfind(str, class, pos)
        if not s then break end
        n = n + 1
        out[n] = ssub(str, pos, s - 1)
        pos = e + 1
    end
    n = n + 1
    out[n] = ssub(str, pos)
    return unpack(out, 1, n)
end

function W.strsplittable(delim, str, pieces)
    return { W.strsplit(delim, str, pieces) }
end

function W.strtrim(str, chars)
    if type(str) ~= "string" then str = tostring(str) end
    local class = chars and ("[" .. chars:gsub("[%]%^%-%%]", "%%%0") .. "]") or "%s"
    str = sgsub(str, "^" .. class .. "+", "")
    str = sgsub(str, class .. "+$", "")
    return str
end

function W.strjoin(sep, ...)
    local n = select("#", ...)
    local parts = {}
    for i = 1, n do parts[i] = tostring((select(i, ...))) end
    return table.concat(parts, sep or "")
end

function W.strconcat(...)
    return W.strjoin("", ...)
end

function W.strlenutf8(s)
    local _, n = sgsub(s, "[^\128-\191]", "")
    return n
end

function W.strcmputf8i(a, b)
    a, b = tostring(a):lower(), tostring(b):lower()
    if a == b then return 0 elseif a < b then return -1 else return 1 end
end

local function startswith(s, prefix) return ssub(s, 1, #prefix) == prefix end
local function endswith(s, suffix) return suffix == "" or ssub(s, -#suffix) == suffix end
local function contains(s, sub) return sfind(s, sub, 1, true) ~= nil end
local function ltrim(s, chars)
    local class = chars and ("[" .. chars:gsub("[%]%^%-%%]", "%%%0") .. "]") or "%s"
    return (sgsub(s, "^" .. class .. "+", ""))
end
local function rtrim(s, chars)
    local class = chars and ("[" .. chars:gsub("[%]%^%-%%]", "%%%0") .. "]") or "%s"
    return (sgsub(s, class .. "+$", ""))
end

---------------------------------------------------------------------------
-- tables
---------------------------------------------------------------------------

function W.wipe(t)
    for k in pairs(t) do t[k] = nil end
    return t
end

function W.tContains(t, v)
    for _, x in pairs(t) do if x == v then return true end end
    return false
end

function W.tIndexOf(t, v)
    for i = 1, #t do if t[i] == v then return i end end
    return nil
end

function W.tDeleteItem(t, v)
    local removed = 0
    local i = 1
    while t[i] ~= nil do
        if t[i] == v then table.remove(t, i); removed = removed + 1 else i = i + 1 end
    end
    return removed
end

function W.tUnorderedRemove(t, i)
    local n = #t
    t[i] = t[n]
    t[n] = nil
end

function W.CountTable(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function W.GetKeysArray(t)
    local out = {}
    for k in pairs(t) do out[#out + 1] = k end
    return out
end

function W.GetValuesArray(t)
    local out = {}
    for _, v in pairs(t) do out[#out + 1] = v end
    return out
end

function W.TableIsEmpty(t)
    return next(t) == nil
end

---------------------------------------------------------------------------
-- math
---------------------------------------------------------------------------

function W.Clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi end
    return v
end
function W.Saturate(v) return W.Clamp(v, 0, 1) end
function W.Lerp(a, b, t) return a + (b - a) * t end
function W.Round(v) return floor(v + 0.5) end
function W.Sign(v) if v > 0 then return 1 elseif v < 0 then return -1 end return 0 end
function W.RoundToSignificantDigits(v, digits)
    local m = 10 ^ (digits or 0)
    return floor(v * m + 0.5) / m
end

---------------------------------------------------------------------------
-- bit (32-bit, unsigned results like the client's bit library)
---------------------------------------------------------------------------

local MOD = 2 ^ 32
local function u32(x)
    x = tonumber(x) or 0
    x = x % MOD
    if x < 0 then x = x + MOD end
    return floor(x)
end
local function bitop(a, b, fn)
    a, b = u32(a), u32(b)
    local r, p = 0, 1
    for _ = 1, 32 do
        local x, y = a % 2, b % 2
        if fn(x, y) then r = r + p end
        a, b, p = (a - x) / 2, (b - y) / 2, p * 2
    end
    return r
end
local bit = {}
function bit.band(a, b, ...)
    local r = bitop(a, b == nil and MOD - 1 or b, function(x, y) return x == 1 and y == 1 end)
    if select("#", ...) > 0 then return bit.band(r, ...) end
    return r
end
function bit.bor(a, b, ...)
    local r = bitop(a, b or 0, function(x, y) return x == 1 or y == 1 end)
    if select("#", ...) > 0 then return bit.bor(r, ...) end
    return r
end
function bit.bxor(a, b, ...)
    local r = bitop(a, b or 0, function(x, y) return x ~= y end)
    if select("#", ...) > 0 then return bit.bxor(r, ...) end
    return r
end
function bit.bnot(a) return MOD - 1 - u32(a) end
function bit.lshift(a, n) return u32(u32(a) * 2 ^ n) end
function bit.rshift(a, n) return floor(u32(a) / 2 ^ n) end
function bit.arshift(a, n)
    a = u32(a)
    local r = floor(a / 2 ^ n)
    if a >= 2 ^ 31 then r = r + (MOD - 2 ^ (32 - n)) end
    return u32(r)
end
function bit.mod(a, b) return u32(a) % u32(b) end

---------------------------------------------------------------------------
-- installer
---------------------------------------------------------------------------

local STRING_EXTRA = {
    split = function(s, delim, pieces) return W.strsplit(delim, s, pieces) end,
    trim = function(s, chars) return W.strtrim(s, chars) end,
    ltrim = ltrim, rtrim = rtrim, startswith = startswith, endswith = endswith,
    contains = contains,
    join = function(sep, ...) return W.strjoin(sep, ...) end,
    concat = function(...) return W.strconcat(...) end,
}

local TABLE_EXTRA = {
    wipe = W.wipe,
    contains = W.tContains,
    indexof = W.tIndexOf,
    count = W.CountTable,
    isempty = W.TableIsEmpty,
    keys = W.GetKeysArray,
    values = W.GetValuesArray,
    removevalue = W.tDeleteItem,
    removeunordered = W.tUnorderedRemove,
    removemulti = function(t, i, n)
        for _ = 1, n or 1 do table.remove(t, i) end
    end,
    create = function() return {} end,
    freeze = function(t) return t end,
    isfrozen = function() return false end,
    getcountinfo = function(t)
        local arr, hash = #t, 0
        for _ in pairs(t) do hash = hash + 1 end
        return arr, hash - arr
    end,
}

local MATH_EXTRA = {
    clamp = W.Clamp, lerp = W.Lerp, round = W.Round, saturate = W.Saturate, sign = W.Sign,
    wrap = function(v, lo, hi)
        local range = hi - lo
        return lo + ((v - lo) % range)
    end,
    remap = function(v, a1, b1, a2, b2) return a2 + (v - a1) * (b2 - a2) / (b1 - a1) end,
    normalize = function(v, lo, hi) return (v - lo) / (hi - lo) end,
    isnan = function(v) return v ~= v end,
    isinf = function(v) return v == huge or v == -huge end,
    isfinite = function(v) return v == v and v ~= huge and v ~= -huge end,
}

--- Build a library table that contains exactly the client's members.
local function buildLib(A, libName, host, extra)
    local allowed = A.luaNamespaces[libName]
    if not allowed then return nil end
    local lib = {}
    for name in pairs(allowed) do
        local v = extra and extra[name]
        if v == nil and host then v = host[name] end
        if v ~= nil then lib[name] = v end
    end
    for name, v in pairs(extra or {}) do
        if not allowed[name] then
            error(("mock: luaenv provides %s.%s which does not exist in the Forever client"):format(libName, name), 0)
        end
        lib[name] = lib[name] or v
    end
    return lib
end

return function(m, A)
    local env = m.env

    -- base library (only names that exist in the client)
    local base = {
        "assert", "collectgarbage", "error", "gcinfo", "getmetatable", "ipairs", "newproxy", "next",
        "pairs", "pcall", "rawequal", "rawget", "rawset", "select", "setmetatable", "tonumber",
        "tostring", "type", "unpack", "xpcall", "getfenv", "setfenv",
    }
    for _, name in ipairs(base) do
        local v = hostG[name]
        if v ~= nil then m:Provide(name, v) end
    end
    -- getfenv must never leak the host globals
    m:Provide("getfenv", function(f)
        local ok, e = pcall(hostG.getfenv, type(f) == "number" and f + 1 or f or 2)
        if not ok then error(e, 2) end
        if e == hostG then return env end
        return e
    end)
    -- loadstring compiles into the client environment
    m:Provide("loadstring", function(s, chunkname)
        local fn, err = hostG.loadstring(s, chunkname)
        if fn then setfenv(fn, env) end
        return fn, err
    end)
    m:Provide("_G", env)
    m:Provide("_VERSION", hostG._VERSION)

    -- libraries
    local strlib = buildLib(A, "string", string, STRING_EXTRA)
    local tablib = buildLib(A, "table", table, TABLE_EXTRA)
    local mathlib = buildLib(A, "math", math, MATH_EXTRA)
    mathlib.huge, mathlib.pi = math.huge, math.pi   -- constants (not listed as functions)
    local bitlib = buildLib(A, "bit", nil, bit)
    local colib = buildLib(A, "coroutine", coroutine, nil)
    m:Provide("string", strlib)
    m:Provide("table", tablib)
    m:Provide("math", mathlib)
    m:Provide("bit", bitlib)
    m:Provide("coroutine", colib)

    -- global aliases of library functions (WoW keeps the Lua 5.0 style names)
    local aliases = {
        abs = math.abs, acos = math.acos, asin = math.asin, atan = math.atan, atan2 = math.atan2,
        ceil = ceil, cos = math.cos, deg = math.deg, exp = math.exp, floor = floor,
        frexp = math.frexp, ldexp = math.ldexp, log = math.log, log10 = math.log10,
        max = math.max, min = math.min, mod = math.fmod, rad = math.rad, random = math.random,
        sin = math.sin, sqrt = math.sqrt, tan = math.tan, fastrandom = math.random,
        format = sformat, gsub = sgsub, gmatch = string.gmatch, strbyte = sbyte,
        strchar = string.char, strfind = sfind, strlen = string.len, strlower = string.lower,
        strmatch = string.match, strrep = string.rep, strrev = string.reverse, strsub = ssub,
        strupper = string.upper,
        tinsert = table.insert, tremove = table.remove, sort = table.sort, getn = table.getn,
        foreach = table.foreach, foreachi = table.foreachi,
    }
    for name, fn in pairs(aliases) do m:Provide(name, fn) end
    for name, fn in pairs(W) do m:Provide(name, fn) end

    -- date / time / difftime are globals in WoW (there is no os library); the
    -- clock is deterministic: m.epoch + elapsed mock time.
    m:Provide("time", function(t)
        if t ~= nil then return os.time(t) end
        return m:ServerTime()
    end)
    m:Provide("date", function(fmt, t)
        return os.date(fmt, t or m:ServerTime())
    end)
    m:Provide("difftime", os.difftime)
end
