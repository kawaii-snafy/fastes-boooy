-- tools/lib/json.lua -- minimal deterministic JSON encoder (Lua 5.1).
--
-- Arrays (tables with keys 1..n and nothing else) are encoded as JSON arrays;
-- every other table is an object whose keys are sorted (numbers before strings),
-- so the output is byte-stable for the same input. Empty tables encode as `[]`
-- unless marked with json.object(t).

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
    if tv == "nil" then
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

return json
