-- tools/lib/json.lua -- minimal deterministic JSON encoder + strict decoder (Lua 5.1).
--
-- Arrays (tables with keys 1..n and nothing else) are encoded as JSON arrays;
-- every other table is an object whose keys are sorted (numbers before strings),
-- so the output is byte-stable for the same input. Empty tables encode as `[]`
-- unless marked with json.object(t).
--
-- json.decode(text) -> value | nil, "line L col C: message": RFC 8259 JSON (objects ->
-- tables with string keys, arrays -> sequences, null -> json.null); trailing garbage,
-- comments, trailing commas, duplicate keys and non-string keys are errors.

local json = {}

local OBJECT_MARK = setmetatable({}, { __mode = "k" })

--- Mark a (possibly empty) table to be encoded as a JSON object.
function json.object(t)
    t = t or {}
    OBJECT_MARK[t] = true
    return t
end

local escapes = {
    ['"'] = '\\"', ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
    ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t",
}

local function encodeString(s)
    return '"' .. s:gsub('[%c"\\]', function(c)
        return escapes[c] or string.format("\\u%04x", c:byte())
    end) .. '"'
end

local function isArray(t)
    if OBJECT_MARK[t] then return false end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    for i = 1, n do
        if t[i] == nil then return false end
    end
    return true
end

local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b)
        if ta ~= tb then return ta == "number" end
        return a < b
    end)
    return keys
end

local function encodeNumber(v)
    if v ~= v or v == math.huge or v == -math.huge then return "null" end
    if v == math.floor(v) and math.abs(v) < 2 ^ 53 then
        return string.format("%d", v)
    end
    return string.format("%.14g", v)
end

local function encode(v, indent, depth, out)
    local tv = type(v)
    if tv == "nil" or v == json.null then
        out[#out + 1] = "null"
    elseif tv == "boolean" then
        out[#out + 1] = v and "true" or "false"
    elseif tv == "number" then
        out[#out + 1] = encodeNumber(v)
    elseif tv == "string" then
        out[#out + 1] = encodeString(v)
    elseif tv == "table" then
        local pad = indent and ("\n" .. string.rep(indent, depth + 1)) or ""
        local close = indent and ("\n" .. string.rep(indent, depth)) or ""
        local sep = indent and ": " or ":"
        if isArray(v) then
            if #v == 0 then out[#out + 1] = "[]" return end
            out[#out + 1] = "["
            for i = 1, #v do
                if i > 1 then out[#out + 1] = "," end
                out[#out + 1] = pad
                encode(v[i], indent, depth + 1, out)
            end
            out[#out + 1] = close .. "]"
        else
            local keys = sortedKeys(v)
            if #keys == 0 then out[#out + 1] = "{}" return end
            out[#out + 1] = "{"
            for i, k in ipairs(keys) do
                if i > 1 then out[#out + 1] = "," end
                out[#out + 1] = pad .. encodeString(tostring(k)) .. sep
                encode(v[k], indent, depth + 1, out)
            end
            out[#out + 1] = close .. "}"
        end
    else
        error("json: cannot encode " .. tv)
    end
end

--- Encode a Lua value. @param indent optional indent string (pretty print)
function json.encode(v, indent)
    local out = {}
    encode(v, indent, 0, out)
    return table.concat(out)
end

---------------------------------------------------------------------------
-- decoder
---------------------------------------------------------------------------

--- Sentinel for JSON null inside arrays / objects (a Lua nil would leave holes).
json.null = setmetatable({}, { __tostring = function() return "json.null" end })

local DECODE_ESCAPES = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }

local function utf8(cp)
    if cp < 0x80 then return string.char(cp) end
    if cp < 0x800 then
        return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
    end
    if cp < 0x10000 then
        return string.char(0xE0 + math.floor(cp / 0x1000), 0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
    end
    return string.char(0xF0 + math.floor(cp / 0x40000), 0x80 + math.floor(cp / 0x1000) % 0x40,
        0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
end

local function decodeError(text, pos, msg)
    local line, col = 1, 1
    for i = 1, math.min(pos - 1, #text) do
        if text:sub(i, i) == "\n" then line, col = line + 1, 1 else col = col + 1 end
    end
    error({ json = string.format("line %d col %d: %s", line, col, msg) }, 0)
end

local decodeValue

local function skipWs(text, pos)
    return text:find("[^ \t\r\n]", pos) or #text + 1
end

local function decodeString(text, pos)
    -- pos is at the opening quote
    local out, i = {}, pos + 1
    while true do
        local c = text:sub(i, i)
        if c == "" then decodeError(text, pos, "unterminated string") end
        if c == '"' then return table.concat(out), i + 1 end
        if c == "\\" then
            local e = text:sub(i + 1, i + 1)
            if e == "u" then
                local hex = text:sub(i + 2, i + 5)
                if not hex:match("^%x%x%x%x$") then decodeError(text, i, "bad \\u escape") end
                local cp = tonumber(hex, 16)
                i = i + 6
                if cp >= 0xD800 and cp <= 0xDBFF and text:sub(i, i + 1) == "\\u" then
                    local lo = tonumber(text:sub(i + 2, i + 5), 16)
                    if lo and lo >= 0xDC00 and lo <= 0xDFFF then
                        cp = 0x10000 + (cp - 0xD800) * 0x400 + (lo - 0xDC00)
                        i = i + 6
                    end
                end
                out[#out + 1] = utf8(cp)
            elseif DECODE_ESCAPES[e] then
                out[#out + 1] = DECODE_ESCAPES[e]
                i = i + 2
            else
                decodeError(text, i, "bad escape \\" .. e)
            end
        elseif c:byte() < 32 then
            decodeError(text, i, "control character in string")
        else
            local j = text:find('["\\%c]', i) or #text + 1
            out[#out + 1] = text:sub(i, j - 1)
            i = j
        end
    end
end

-- -?(0|[1-9][0-9]*)(.[0-9]+)?([eE][+-]?[0-9]+)?
local function decodeNumber(text, pos)
    local i = pos
    if text:sub(i, i) == "-" then i = i + 1 end
    local int = text:match("^%d+", i)
    if not int or (#int > 1 and int:sub(1, 1) == "0") then decodeError(text, pos, "bad number") end
    i = i + #int
    if text:sub(i, i) == "." then
        local frac = text:match("^%d+", i + 1)
        if not frac then decodeError(text, pos, "bad number") end
        i = i + 1 + #frac
    end
    if text:sub(i, i):match("[eE]") then
        local exp = text:match("^[-+]?%d+", i + 1)
        if not exp then decodeError(text, pos, "bad number") end
        i = i + 1 + #exp
    end
    return tonumber(text:sub(pos, i - 1)), i
end

decodeValue = function(text, pos, depth)
    if depth > 200 then decodeError(text, pos, "nesting too deep") end
    pos = skipWs(text, pos)
    local c = text:sub(pos, pos)
    if c == "{" then
        local obj = {}
        pos = skipWs(text, pos + 1)
        if text:sub(pos, pos) == "}" then return json.object(obj), pos + 1 end
        while true do
            if text:sub(pos, pos) ~= '"' then decodeError(text, pos, "object key must be a string") end
            local key
            key, pos = decodeString(text, pos)
            if obj[key] ~= nil then decodeError(text, pos, "duplicate key \"" .. key .. "\"") end
            pos = skipWs(text, pos)
            if text:sub(pos, pos) ~= ":" then decodeError(text, pos, "':' expected") end
            obj[key], pos = decodeValue(text, pos + 1, depth + 1)
            pos = skipWs(text, pos)
            local d = text:sub(pos, pos)
            if d == "}" then return json.object(obj), pos + 1 end
            if d ~= "," then decodeError(text, pos, "',' or '}' expected") end
            pos = skipWs(text, pos + 1)
        end
    elseif c == "[" then
        local arr = {}
        pos = skipWs(text, pos + 1)
        if text:sub(pos, pos) == "]" then return arr, pos + 1 end
        while true do
            arr[#arr + 1], pos = decodeValue(text, pos, depth + 1)
            pos = skipWs(text, pos)
            local d = text:sub(pos, pos)
            if d == "]" then return arr, pos + 1 end
            if d ~= "," then decodeError(text, pos, "',' or ']' expected") end
            pos = pos + 1
        end
    elseif c == '"' then
        return decodeString(text, pos)
    elseif c == "-" or c:match("%d") then
        return decodeNumber(text, pos)
    elseif text:sub(pos, pos + 3) == "true" then
        return true, pos + 4
    elseif text:sub(pos, pos + 4) == "false" then
        return false, pos + 5
    elseif text:sub(pos, pos + 3) == "null" then
        return json.null, pos + 4
    end
    decodeError(text, pos, c == "" and "unexpected end of input" or ("unexpected character '" .. c .. "'"))
end

--- Decode JSON text. @return value, or nil and an error "line L col C: message"
-- (decoded objects are marked json.object, so they re-encode as objects)
function json.decode(text)
    if type(text) ~= "string" then return nil, "line 1 col 1: text expected" end
    text = text:gsub("^\239\187\191", "") -- UTF-8 BOM
    local ok, v, pos = pcall(decodeValue, text, 1, 0)
    if not ok then
        if type(v) == "table" and v.json then return nil, v.json end
        error(v, 0)
    end
    pos = skipWs(text, pos)
    if pos <= #text then
        local _, err = pcall(decodeError, text, pos, "trailing characters after the JSON value")
        return nil, err.json
    end
    return v
end

return json
