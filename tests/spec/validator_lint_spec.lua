-- The luacheck 'forever' std (.luacheckrc, built from tools/data/forever_api.lua) must
-- report API names that do not exist in the World of Warcraft: Forever client and
-- accept the ones that do. Runs luacheck on probe sources passed through stdin with a
-- virtual file name inside the core addon (so the core addon's std applies).

local function luacheck(source, filename)
    local tmp = os.tmpname()
    local fh = assert(io.open(tmp, "w"))
    fh:write(source)
    fh:close()
    local p = assert(io.popen(("luacheck --no-color --codes --config .luacheckrc --filename %s - < %s 2>&1; echo \"__EXIT=$?\"")
        :format(filename, tmp)))
    local out = p:read("*a")
    p:close()
    os.remove(tmp)
    return tonumber(out:match("__EXIT=(%d+)")), out
end

local function available()
    local p = io.popen("luacheck --version 2>/dev/null")
    local out = p and p:read("*a") or ""
    if p then p:close() end
    return out:find("Luacheck") ~= nil
end

describe("luacheck forever std", function()
    if not available() then
        pending("luacheck is not installed")
        return
    end

    local CORE = "addons/AdventureAtlas/Core/LintProbe.lua"
    local ROUTE = "addons/AdventureAtlas_Probe/Segments/01.lua"

    it("accepts real Forever APIs, widgets, enums and the addon globals", function()
        local code, out = luacheck([[
local _, ns = ...
local info = C_QuestLog.GetInfo(1)
local n = C_QuestLog.GetNumQuestLogEntries()
local done = C_QuestLog.IsQuestFlaggedCompleted(363)
local count = C_Item.GetItemCount(6948)
local mapID = C_Map.GetBestMapForUnit("player")
local f = CreateFrame("Frame", nil, UIParent)
f:RegisterEvent("QUEST_TURNED_IN")
local font = GameFontNormal
local level = UnitLevel("player")
local _, raceFile = UnitRace("player")
local proj = WOW_PROJECT_ID
local secret = issecretvalue
local s = strsplit(",", "a,b")
local t = Enum.QuestTagType
SLASH_ADVENTUREATLAS1 = "/aa"
SlashCmdList.ADVENTUREATLAS = function() end
AdventureAtlas = ns
AdventureAtlasDB = AdventureAtlasDB or {}
AdventureAtlasCharDB = AdventureAtlasCharDB or {}
return info, n, done, count, mapID, font, level, raceFile, proj, secret, s, t
]], CORE)
        assert.are.equal(0, code, out)
    end)

    it("reports APIs that do not exist in Forever", function()
        local code, out = luacheck([[
local a = GetQuestLogTitle(1)
local b = C_QuestLog.GetQuestLogTitle(1)
local c = IsQuestComplete(1)
local d = GetItemCount(6948)
local e = GetSpellInfo(1)
local f = C_QuestLog.IsQuestFlaggedCompletedTypo(1)
local g = InterfaceOptions_AddCategory
local h = io.open("x")
return a, b, c, d, e, f, g, h
]], CORE)
        assert.are.equal(1, code)
        assert.matches("W113.-GetQuestLogTitle", out)
        assert.matches("W143.-GetQuestLogTitle.-C_QuestLog", out)
        assert.matches("W113.-IsQuestComplete", out)
        assert.matches("W113.-GetItemCount", out)
        assert.matches("W113.-GetSpellInfo", out)
        assert.matches("W143.-IsQuestFlaggedCompletedTypo", out)
        assert.matches("W113.-InterfaceOptions_AddCategory", out)
        assert.matches("W113.-io", out)
    end)

    it("route modules may only read AdventureAtlas", function()
        local code = luacheck('AdventureAtlas.AddSegment("r", { id = "s", title = "t", steps = {} })\n', ROUTE)
        assert.are.equal(0, code)
        local bad, out = luacheck('local x = C_QuestLog.GetInfo(1)\nAdventureAtlasDB = {}\nreturn x\n', ROUTE)
        assert.are.equal(1, bad)
        assert.matches("C_QuestLog", out)
        assert.matches("AdventureAtlasDB", out)
    end)

    it("route modules: the shared-insert API and the pure Lua base are known; writes and other globals are not", function()
        -- the shape of a Route.lua that registers its routes from a table, and of a class file
        local code, out = luacheck([[
if not AdventureAtlas.AddLibraryInsert then return end
local _, ns = ...
local list = { "a", "b" }
for i, id in ipairs(list) do
    AdventureAtlas.RegisterRoute({ api = 1, id = id .. tostring(i), title = string.format("%s %d", id, math.floor(i)) })
end
for k, v in pairs(ns) do
    if type(v) == "table" and next(v) ~= nil then
        AdventureAtlas.AddLibraryInsert({ after = k, steps = { unpack(v) } })
    end
end
AdventureAtlas.AddLibraryData({ rewards = { DRUID = { [tonumber("92461")] = select(1, 1) } } })
return table.concat(list, ",")
]], "addons/AdventureAtlas_Probe/Classes/Druid.lua")
        assert.are.equal(0, code, out)
        -- still errors: writes to the base, WoW API, SavedVariables, a global of the module's own, io / os / print,
        -- a function AdventureAtlas does not have
        local bad
        bad, out = luacheck([[
ipairs = nil
string.extra = 1
local t = C_Timer.After
AdventureAtlasCharDB = {}
MyGlobal = 1
print(os.time(), io.open("x"), t)
AdventureAtlas.AddLibraryInsrt({})
AdventureAtlas.AddLibraryInsert = nil
]], "tests/fixtures/core/AdventureAtlas_Probe/Route.lua")
        assert.are.equal(1, bad)
        assert.matches("W121.-ipairs", out)
        assert.matches("W122.-extra", out)
        assert.matches("W113.-C_Timer", out)
        assert.matches("W111.-AdventureAtlasCharDB", out)
        assert.matches("W111.-MyGlobal", out)
        assert.matches("W113.-print", out)
        assert.matches("W113.-'os'", out)
        assert.matches("W113.-'io'", out)
        assert.matches("W143.-AddLibraryInsrt", out)
        assert.matches("W122.-AddLibraryInsert", out)
    end)

    it("DB override files (tools/overrides/*.lua): one return, no globals at all", function()
        local code, out = luacheck([[
return {
    quests = {
        [861] = { exclusive = { remove = { 844 } }, source = "in game 2026-11-10", verified = false },
        [92461] = { xp = 85, source = "in game 2026-11-10", verified = true },
    },
    npcs = { [3153] = { sub = "Warrior Trainer", source = "in game 2026-11-10", verified = true } },
}
]], "tools/overrides/shared.lua")
        assert.are.equal(0, code, out)
        -- the file is loaded in an empty environment: not even the Lua base, no AdventureAtlas, no global of its own
        local bad
        bad, out = luacheck([[
local ids = { 1, 2 }
for _, id in ipairs(ids) do Count = (Count or 0) + id end
return { quests = { [tonumber("363")] = { xp = math.floor(85.5), source = tostring(AdventureAtlas) } } }
]], "tools/overrides/warrior.lua")
        assert.are.equal(1, bad)
        assert.matches("W113.-ipairs", out)
        assert.matches("W111.-Count", out)
        assert.matches("W113.-tonumber", out)
        assert.matches("W113.-math", out)
        assert.matches("W113.-AdventureAtlas", out)
        -- the other tools keep plain Lua 5.1
        code, out = luacheck("local t = {}\nfor _, v in ipairs(t) do print(tostring(v)) end\n", "tools/lib/probe.lua")
        assert.are.equal(0, code, out)
    end)
end)
