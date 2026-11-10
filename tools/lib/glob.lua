-- tools/lib/glob.lua -- `*` wildcards for file filters and route lists (Lua 5.1).
--
-- One syntax for --skip / --keep / --own (TOC paths with forward slashes) and for --route
-- (route ids): the pattern must match the WHOLE string, `*` matches any run of characters
-- (also "/": "Segments/*" covers "Segments/Durotar/01.lua"), everything else is literal.
-- Matching is case-sensitive.
--
--   local Glob = require("lib.glob")
--   Glob.Match("Classes/*", "Classes/Warrior.lua")             -- true
--   Glob.Any({ "Classes/*", "Races/*" }, "Route.lua")          -- false
--   Glob.Skipped(path, skipGlobs, keepGlobs)                   -- matches a skip glob and no keep glob
--   local list = Glob.NewList("orc-*,troll-*")                 -- a comma list (--route)
--   Glob.ListMatch(list, "orc-warrior")                        -- true; list.hits[1] = 1
--   Glob.Unmatched(list)                                       -- { "troll-*" }: entries that matched nothing
--   Glob.UnmatchedIn({ "Clases/*" }, { tocFiles })             -- { "Clases/*" }: globs that match no string

local Glob = {}

--- The Lua pattern of a glob (anchored).
function Glob.Pattern(glob)
    local p = tostring(glob):gsub("\\", "/"):gsub("[%^%$%(%)%%%.%[%]%+%-%?]", "%%%0"):gsub("%*", ".*")
    return "^" .. p .. "$"
end

function Glob.Match(glob, s)
    return tostring(s):find(Glob.Pattern(glob)) ~= nil
end

--- Does any glob of the list match? (false for an empty / missing list)
function Glob.Any(globs, s)
    for _, g in ipairs(globs or {}) do
        if Glob.Match(g, s) then return true end
    end
    return false
end

--- The file-filter rule: a path is skipped when it matches a skip glob and no keep glob.
function Glob.Skipped(path, skip, keep)
    return Glob.Any(skip, path) and not Glob.Any(keep, path)
end

--- "a, b*" -> { "a", "b*" }
function Glob.Split(s)
    local out = {}
    for g in tostring(s or ""):gmatch("[^,%s]+") do out[#out + 1] = g end
    return out
end

--- A comma list of globs that remembers which entries matched something.
-- @param spec "orc-*,troll-mage", or a list of globs
-- @return { patterns = { ... }, hits = { [i] = count } }
function Glob.NewList(spec)
    local patterns = type(spec) == "table" and spec or Glob.Split(spec)
    local list = { patterns = {}, hits = {} }
    for i, g in ipairs(patterns) do
        list.patterns[i] = g
        list.hits[i] = 0
    end
    return list
end

--- Does any entry match `s`? Every matching entry counts the hit.
function Glob.ListMatch(list, s)
    local any = false
    for i, g in ipairs(list.patterns) do
        if Glob.Match(g, s) then
            list.hits[i] = list.hits[i] + 1
            any = true
        end
    end
    return any
end

--- The entries of a list that matched nothing so far.
function Glob.Unmatched(list)
    local out = {}
    for i, g in ipairs(list.patterns) do
        if list.hits[i] == 0 then out[#out + 1] = g end
    end
    return out
end

--- The globs that match none of the strings (a typo in a file filter).
-- @param globs list of globs (nil: none); @param lists array of string lists
function Glob.UnmatchedIn(globs, lists)
    local out = {}
    for _, g in ipairs(globs or {}) do
        local pattern, hit = Glob.Pattern(g), false
        for _, list in ipairs(lists) do
            for _, s in ipairs(list) do
                if tostring(s):find(pattern) then hit = true break end
            end
            if hit then break end
        end
        if not hit then out[#out + 1] = g end
    end
    return out
end

return Glob
