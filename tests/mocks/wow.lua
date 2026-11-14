-- tests/mocks/wow.lua -- strict mock of the World of Warcraft: Forever client
-- (1.60.1.70862, "## Interface: 16001", game type "camelot") for busted specs and
-- tools/simulate_routes.lua.
--
--   local Mock = require("mocks.wow")          -- busted: lpath has ./tests/?.lua
--   local m = Mock.new({ locale = "ruRU", player = { race = "Scourge", class = "PALADIN" } })
--   local ns = Mock.loadAddon(m, "addons/AdventureAtlas/AdventureAtlas.toc")
--   Mock.boot(m, { "AdventureAtlas" })
--   m:DefineQuest(363, { title = "Rude Awakening", level = 1 })
--   m:OpenQuestDetail(363)                      -- fires QUEST_DETAIL; the addon may AcceptQuest()
--
-- Strictness (see tests/mocks/README.md):
--   * m.env holds ONLY names that exist in the Forever client (tools/data/forever_api.lua);
--     providing anything else is an error at build time.
--   * a global that does not exist in Forever reads as nil (recorded in m.absent);
--     a global that exists but is not implemented by the mock raises (opts.unmocked = "nil"
--     to read nil instead; always recorded in m.unmocked).
--   * documented API functions check their arguments against the API documentation
--     (tests/mocks/wow/signatures.lua); misuse raises and is recorded in m.violations.
--   * widgets only have the methods / script handlers of their widget type; unknown
--     templates, frame types, events, anchor points, strata and draw layers raise.
--   * errors reaching geterrorhandler() are recorded in m.errors and re-raised by the
--     outermost mock call (m:Fire, m:Advance, helpers) so the spec fails.
--
-- Third-party addon code is never loaded here; only files listed by a TOC passed to
-- Mock.loadAddon, each run with setfenv(m.env).

local Mock = {}
local M = {}                    -- methods of mock instances
M.__index = M
Mock.methods = M

---------------------------------------------------------------------------
-- locations
---------------------------------------------------------------------------

local function thisDir()
    local src = debug.getinfo(1, "S").source
    if src:sub(1, 1) == "@" then
        local dir = src:sub(2):match("^(.*[/\\])")
        if dir then return dir end
    end
    return "./tests/mocks/"
end

local DIR = thisDir()                                   -- .../tests/mocks/
Mock.DIR = DIR
Mock.ROOT = DIR .. "../../"                             -- repository root
Mock.API_FILE = Mock.ROOT .. "tools/data/forever_api.lua"

local function loadPart(name, ...)
    local fn, err = loadfile(DIR .. "wow/" .. name .. ".lua")
    if not fn then error("mock: cannot load part " .. name .. ": " .. tostring(err), 0) end
    return fn(...)
end

local A = loadPart("allowlist", DIR)
A.load(Mock.API_FILE)
Mock.allowlist = A

---------------------------------------------------------------------------
-- utilities shared by the parts
---------------------------------------------------------------------------

local U = {}
Mock.util = U

function U.pack(...) return { n = select("#", ...), ... } end

function U.deepcopy(v, seen)
    if type(v) ~= "table" then return v end
    seen = seen or {}
    if seen[v] then return seen[v] end
    local out = {}
    seen[v] = out
    for k, x in pairs(v) do out[U.deepcopy(k, seen)] = U.deepcopy(x, seen) end
    return out
end

function U.merge(dst, src)
    for k, v in pairs(src or {}) do dst[k] = v end
    return dst
end

function U.sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) < type(b)
    end)
    return keys
end

function U.describe(v)
    local tv = type(v)
    if tv == "string" then return string.format("%q", v) end
    return tostring(v)
end

---------------------------------------------------------------------------
-- construction
---------------------------------------------------------------------------

local installers = {}           -- per-mock installers registered by the parts

local DEFAULT_PLAYER = {
    name = "Mockplayer", realm = "MockRealm", race = "Scourge", raceID = 5, class = "PALADIN",
    classID = 2, faction = "Horde", sex = 2, level = 1, xp = 0, rested = 0, money = 0,
    mapID = 1420, x = 50, y = 50, facing = 0, onTaxi = false, inCombat = false,
    shift = false, ctrl = false, alt = false, dead = false, instance = nil,
    guid = "Player-5000-0A1B2C3D",
}
Mock.DEFAULT_PLAYER = DEFAULT_PLAYER

--- Create a fresh mock client.
-- opts: locale ("enUS"), player = {...} (see DEFAULT_PLAYER), unmocked ("error"|"nil"),
--       raiseErrors (true), frameTime (seconds per simulated frame, 0.05), time (GetTime() at
--       start, 1000), epoch (time() at start), projectID (WOW_PROJECT_ID, 18),
--       build ({version, build, date, interface}), maxQuests (40), questLogHeaders (true),
--       maps ({[uiMapID] = def}), savedVariables ({[name] = value}), serverDelay (0),
--       levelLag (true: UnitLevel lags during PLAYER_LEVEL_UP), maxLevel (60)
function Mock.new(opts)
    opts = opts or {}
    local m = setmetatable({}, M)
    m.opts = opts
    m.A = A
    m.env = {}
    m.provided = {}             -- name -> true for names installed by the mock
    m.errors = {}               -- { message, traceback } delivered to the error handler
    m.violations = {}           -- strict-mock contract violations (also raised)
    m.warnings = {}             -- soft issues (e.g. registering an unknown event)
    m.unmocked = {}             -- name -> count: exists in Forever, not implemented by the mock
    m.absent = {}               -- name -> count: read of a global that does not exist in Forever
    m.addonGlobals = {}         -- name -> true: globals created by loaded code
    m.actions = {}              -- log of player-intent API calls: { name, arg1, ... }
    m.chat = {}                 -- DEFAULT_CHAT_FRAME / print output (strings)
    m.chatColors = {}           -- parallel { r, g, b }
    m.unmockedMode = opts.unmocked or "error"
    m.raiseErrors = opts.raiseErrors ~= false
    m._depth = 0
    m._errorMark, m._violationMark = 0, 0

    m.player = U.merge(U.deepcopy(DEFAULT_PLAYER), opts.player or {})
    local po = opts.player or {}
    if po.race and not po.faction then
        m.player.faction = Mock.RACE_FACTION[po.race] or "Horde"
    end
    if po.race and not po.raceID then
        if po.race == "Skyborne" then
            -- Skyborne: one raceFile for both factions; raceID 95 = Alliance, 96 = Horde (Windshaper)
            m.player.raceID = (m.player.faction == "Alliance") and 95 or 96
        else
            m.player.raceID = Mock.RACE_IDS[po.race] or 0
        end
    end
    if po.class and not po.classID then
        m.player.classID = Mock.CLASS_IDS[po.class] or 0
    end

    local env = m.env
    setmetatable(env, {
        __index = function(_, k) return m:_resolveGlobal(k) end,
        __newindex = function(t, k, v)
            if not m.provided[k] then m.addonGlobals[k] = true end
            rawset(t, k, v)
        end,
    })

    for _, inst in ipairs(installers) do inst(m) end
    return m
end

Mock.CLASS_IDS = {
    WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5, SHAMAN = 7, MAGE = 8,
    WARLOCK = 9, DRUID = 11,
}
Mock.RACE_IDS = {
    Human = 1, Orc = 2, Dwarf = 3, NightElf = 4, Scourge = 5, Tauren = 6, Gnome = 7, Troll = 8,
}
Mock.RACE_FACTION = {
    Human = "Alliance", Dwarf = "Alliance", NightElf = "Alliance", Gnome = "Alliance",
    Orc = "Horde", Scourge = "Horde", Tauren = "Horde", Troll = "Horde",
}

---------------------------------------------------------------------------
-- diagnostics
---------------------------------------------------------------------------

function M:_violation(msg, level)
    msg = "mock: " .. msg
    self.violations[#self.violations + 1] = msg
    error(msg, (level or 1) + 1)
end

function M:_warn(msg)
    self.warnings[#self.warnings + 1] = msg
end

function M:_action(name, ...)
    self.actions[#self.actions + 1] = { name, ... }
end

--- Actions (player-intent API calls such as AcceptQuest) whose name matches.
function M:Actions(name)
    local out = {}
    for _, a in ipairs(self.actions) do
        if name == nil or a[1] == name then out[#out + 1] = a end
    end
    return out
end

function M:ClearDiagnostics()
    self.errors, self.violations, self.warnings = {}, {}, {}
    self.unmocked, self.absent = {}, {}
    self._errorMark, self._violationMark = 0, 0
end

--- Human-readable summary of everything the mock recorded (for debugging specs).
function M:Diagnostics()
    local out = {}
    local function section(title, list)
        if #list > 0 then out[#out + 1] = title .. ": " .. table.concat(list, ", ") end
    end
    local errs = {}
    for _, e in ipairs(self.errors) do errs[#errs + 1] = tostring(e.message) end
    section("errors", errs)
    section("violations", self.violations)
    section("warnings", self.warnings)
    section("unmocked", U.sortedKeys(self.unmocked))
    section("absent", U.sortedKeys(self.absent))
    section("missing widget methods", U.sortedKeys(self.widgetMisses or {}))
    section("unmodeled templates", U.sortedKeys(self.unmodeledTemplates or {}))
    return table.concat(out, "\n")
end

--- Raise if any error / violation was recorded (use in after_each).
function M:AssertClean()
    local lines = {}
    for _, e in ipairs(self.errors) do lines[#lines + 1] = "error: " .. tostring(e.message) end
    for _, v in ipairs(self.violations) do lines[#lines + 1] = "violation: " .. v end
    if #lines > 0 then error(table.concat(lines, "\n"), 2) end
end

--- Run fn as an outermost mock entry point: new errors / violations raise at the end.
function M:_top(fn, ...)
    self._depth = self._depth + 1
    local res = U.pack(pcall(fn, ...))
    self._depth = self._depth - 1
    if not res[1] then
        if self._depth == 0 then
            self._errorMark, self._violationMark = #self.errors, #self.violations
        end
        error(res[2], 0)
    end
    if self._depth == 0 and self.raiseErrors then
        local lines = {}
        for i = self._errorMark + 1, #self.errors do
            lines[#lines + 1] = tostring(self.errors[i].message) .. "\n" .. tostring(self.errors[i].traceback or "")
        end
        for i = self._violationMark + 1, #self.violations do
            lines[#lines + 1] = self.violations[i]
        end
        self._errorMark, self._violationMark = #self.errors, #self.violations
        if #lines > 0 then
            error("mock: errors during the call:\n" .. table.concat(lines, "\n"), 0)
        end
    end
    return unpack(res, 2, res.n)
end

---------------------------------------------------------------------------
-- global environment
---------------------------------------------------------------------------

--- Install a global; it must exist in the Forever client.
function M:Provide(name, value)
    if not A.isGlobal(name) then
        error(("mock: provides global %q which does not exist in the Forever client "
            .. "(tools/data/forever_api.lua)"):format(tostring(name)), 2)
    end
    self.provided[name] = true
    rawset(self.env, name, value)
    return value
end

--- Wrap an API function with the documented argument checks (if documented).
function M:_wrapAPI(fullName, fn)
    local sig = A.parsedSignatures[fullName] or {}
    local m = self
    return function(...)
        for i, a in ipairs(sig) do
            local v = select(i, ...)
            if v == nil then
                if not a.optional then
                    m:_violation(("bad argument #%d (%s) to '%s': value expected, got nil"):format(i, a.name, fullName), 2)
                end
            else
                local want = A.checkValue(a.code, v)
                if want then
                    m:_violation(("bad argument #%d (%s) to '%s': %s expected, got %s"):format(
                        i, a.name, fullName, want, type(v)), 2)
                end
            end
        end
        return fn(...)
    end
end

--- Install a global API function (argument-checked when documented).
function M:ProvideAPI(name, fn)
    return self:Provide(name, self:_wrapAPI(name, fn))
end

--- Install (or extend) a namespace / FrameXML table with functions; every member
-- must exist in the client. Functions are argument-checked when documented.
function M:ProvideNS(owner, members)
    if not A.isGlobal(owner) then
        error(("mock: provides namespace %q which does not exist in the Forever client"):format(owner), 2)
    end
    local t = rawget(self.env, owner)
    if t == nil then
        t = {}
        local m = self
        setmetatable(t, {
            __index = function(_, k)
                local full = owner .. "." .. tostring(k)
                if A.isMember(owner, k) then
                    m.unmocked[full] = (m.unmocked[full] or 0) + 1
                    if m.unmockedMode == "error" then
                        m:_violation(full .. " exists in the Forever client but is not implemented by the mock "
                            .. "(extend tests/mocks or use m:ProvideNS)", 2)
                    end
                else
                    m.absent[full] = (m.absent[full] or 0) + 1
                end
                return nil
            end,
        })
        self:Provide(owner, t)
    end
    for k, v in pairs(members) do
        if not A.isMember(owner, k) then
            error(("mock: provides %s.%s which does not exist in the Forever client"):format(owner, k), 2)
        end
        if type(v) == "function" then v = self:_wrapAPI(owner .. "." .. k, v) end
        rawset(t, k, v)
    end
    return t
end

local COLORS = {
    NORMAL_FONT_COLOR = { 1, 0.82, 0 }, HIGHLIGHT_FONT_COLOR = { 1, 1, 1 },
    GREEN_FONT_COLOR = { 0.1, 1, 0.1 }, RED_FONT_COLOR = { 1, 0.1, 0.1 },
    GRAY_FONT_COLOR = { 0.5, 0.5, 0.5 }, DISABLED_FONT_COLOR = { 0.5, 0.5, 0.5 },
    YELLOW_FONT_COLOR = { 1, 1, 0 }, WHITE_FONT_COLOR = { 1, 1, 1 },
    ORANGE_FONT_COLOR = { 1, 0.5, 0.25 }, LIGHTBLUE_FONT_COLOR = { 0.53, 0.67, 1 },
}

function Mock.CreateColor(r, g, b, a)
    local c = { r = r, g = g, b = b, a = a or 1 }
    function c.GetRGB(self) return self.r, self.g, self.b end
    function c.GetRGBA(self) return self.r, self.g, self.b, self.a end
    function c.GetRGBAsBytes(self)
        return math.floor(self.r * 255 + 0.5), math.floor(self.g * 255 + 0.5), math.floor(self.b * 255 + 0.5)
    end
    function c.GenerateHexColor(self)
        local R, G, B = self:GetRGBAsBytes()
        return string.format("ff%02x%02x%02x", R, G, B)
    end
    function c.GenerateHexColorMarkup(self) return "|c" .. self:GenerateHexColor() end
    function c.WrapTextInColorCode(self, text) return "|c" .. self:GenerateHexColor() .. tostring(text) .. "|r" end
    function c.SetRGB(self, R, G, B) self.r, self.g, self.b = R, G, B end
    function c.SetRGBA(self, R, G, B, Al) self.r, self.g, self.b, self.a = R, G, B, Al or 1 end
    function c.IsEqualTo(self, o) return self.r == o.r and self.g == o.g and self.b == o.b and self.a == o.a end
    return c
end

--- Lazily resolved globals + strict handling of unknown names.
function M:_resolveGlobal(k)
    local env = self.env
    if type(k) ~= "string" then return nil end
    -- font objects declared in FrameXML (GameFontNormal, ...)
    if A.fonts[k] and self._createFontObject then
        return self:Provide(k, self:_createFontObject(k))
    end
    -- LE_* constants
    if A.leValues[k] ~= nil then
        return self:Provide(k, A.leValues[k])
    end
    -- *_COLOR objects / *_COLOR_CODE strings
    if A.uiColors[k] then
        local c = COLORS[k] or COLORS[(k:gsub("_CODE$", ""))] or { 1, 1, 1 }
        if k:match("_CODE$") then
            return self:Provide(k, "|c" .. Mock.CreateColor(c[1], c[2], c[3]):GenerateHexColor())
        end
        return self:Provide(k, Mock.CreateColor(c[1], c[2], c[3]))
    end
    if self._svNames and self._svNames[k] then return nil end   -- SavedVariables not set (yet)
    if A.isGlobal(k) then
        self.unmocked[k] = (self.unmocked[k] or 0) + 1
        if self.unmockedMode == "error" then
            self:_violation(("global %q exists in the Forever client but is not implemented by the mock "
                .. "(extend tests/mocks or call m:Provide)"):format(k), 3)
        end
        return nil
    end
    self.absent[k] = (self.absent[k] or 0) + 1
    return rawget(env, k)
end

--- Absent names (do not exist in Forever) read by the loaded code, sorted.
function M:AbsentGlobals()
    return U.sortedKeys(self.absent)
end

--- Globals written by loaded code (addon globals, named frames are excluded).
function M:AddonGlobals()
    local out = {}
    for k in pairs(self.addonGlobals) do
        if not (self._namedFrames and self._namedFrames[k]) then out[#out + 1] = k end
    end
    table.sort(out)
    return out
end

---------------------------------------------------------------------------
-- parts
---------------------------------------------------------------------------

local function registerInstaller(fn) installers[#installers + 1] = fn end

local ctx = { Mock = Mock, M = M, A = A, U = U, register = registerInstaller }
loadPart("system", ctx)         -- clock, timers, events, errors, addons/TOC, slash, popups, settings
loadPart("widgets", ctx)        -- CreateFrame and widget objects, templates, UIParent, tooltip, fonts
loadPart("world", ctx)          -- player, units, maps, waypoints, bags, xp, taxi, trainer, merchant
loadPart("quests", ctx)         -- quest db, quest log, quest dialogs, gossip, greeting
-- luaenv first in the per-mock order (installed before the other parts' APIs)
table.insert(installers, 1, function(m) loadPart("luaenv")(m, A) end)

return Mock
