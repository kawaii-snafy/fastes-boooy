-- FastesBoooy / Core / Init.lua
--
-- Namespace, public API table, event dispatcher, internal callbacks,
-- SavedVariables initialization, locale table and chat output.
--
-- Globals created here (the only ones the core defines besides the slash
-- command entries owned by UI/Options.lua):
--   FastesBoooy        = ns.public (route modules use RegisterRoute/AddSegment/AddRouteData)
--   FastesBoooyDB      account SavedVariables  (ns.db)
--   FastesBoooyCharDB  character SavedVariables (ns.cdb)

local ADDON, ns = ...
-- luacheck: ignore 212/self

local type, pairs, select, tostring, pcall, xpcall = type, pairs, select, tostring, pcall, xpcall
local setmetatable, unpack = setmetatable, unpack
local format = string.format

ns.ADDON = ADDON or "FastesBoooy"

---------------------------------------------------------------------------
-- public API table
---------------------------------------------------------------------------

local public = { API_VERSION = 1 }
ns.public = public
FastesBoooy = public

local DEFAULT_VERSION = "0.1.0"

local function readVersion()
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        local ok, v = pcall(C_AddOns.GetAddOnMetadata, ns.ADDON, "Version")
        if ok and type(v) == "string" and v ~= "" and not v:find("@", 1, true) then
            return v
        end
    end
    return DEFAULT_VERSION
end

public.version = readVersion()
ns.VERSION = public.version

-- Registration API (implemented in Core/Registry.lua, which loads later;
-- route modules call these only after the whole core has loaded).
function public.RegisterRoute(def)
    return ns.Registry:RegisterRoute(def)
end

function public.AddSegment(routeId, def)
    return ns.Registry:AddSegment(routeId, def)
end

function public.AddRouteData(routeId, data)
    return ns.Registry:AddRouteData(routeId, data)
end

function public.GetActiveRoute()
    return ns.Engine and ns.Engine:GetRoute() or nil
end

function public.GetCurrentStep()
    return ns.Engine and ns.Engine:GetCurrentStep() or nil
end

---------------------------------------------------------------------------
-- locale
---------------------------------------------------------------------------

ns.locale = (GetLocale and GetLocale()) or "enUS"
ns.Locales = ns.Locales or {}
ns.Locales.enUS = ns.Locales.enUS or {}

-- ns.L[key]: current locale -> enUS -> the key itself. Not cached, so locale
-- tables may still be extended after this file ran.
ns.L = setmetatable({}, {
    __index = function(_, key)
        local cur = ns.Locales[ns.locale]
        local v = cur and cur[key]
        if v == nil then v = ns.Locales.enUS[key] end
        if v == nil then v = key end
        return v
    end,
})

---------------------------------------------------------------------------
-- error reporting / safe calls
---------------------------------------------------------------------------

local function errorHandler(err)
    local h = geterrorhandler and geterrorhandler()
    if h then
        return h(err)
    end
    print(tostring(err))
end
ns.ErrorHandler = errorHandler

--- Call fn(...) and route any error to the WoW error handler (keeps the stack).
-- @return true on success
function ns.SafeCall(fn, ...)
    local n = select("#", ...)
    if n == 0 then
        return (xpcall(fn, errorHandler))
    end
    local args = { ... }
    return (xpcall(function() return fn(unpack(args, 1, n)) end, errorHandler))
end
local safeCall = ns.SafeCall

---------------------------------------------------------------------------
-- event dispatcher: ns:On(event, fn) / ns:Off(event, fn)
-- One hidden frame, any number of handlers per event. Handlers are called as
-- fn(event, ...payload). Handler lists are copy-on-write, so handlers may
-- (un)register during dispatch.
---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:Hide()
ns.eventFrame = eventFrame

local handlers = {}

local function dispatch(event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        safeCall(list[i], event, ...)
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    dispatch(event, ...)
end)

--- Register a handler for a game event.
-- @return true when registered (false when the client does not know the event)
function ns:On(event, fn)
    if type(event) ~= "string" or type(fn) ~= "function" then return false end
    local list = handlers[event]
    if list then
        for i = 1, #list do
            if list[i] == fn then return true end
        end
    else
        local ok, res = pcall(eventFrame.RegisterEvent, eventFrame, event)
        if not ok or res == false then
            ns.Debug("cannot register event", event)
            return false
        end
        list = {}
    end
    local new = {}
    for i = 1, #list do new[i] = list[i] end
    new[#new + 1] = fn
    handlers[event] = new
    return true
end

--- Remove a handler; the event is unregistered when no handler remains.
function ns:Off(event, fn)
    local list = handlers[event]
    if not list then return end
    local new = {}
    for i = 1, #list do
        if list[i] ~= fn then new[#new + 1] = list[i] end
    end
    if #new == 0 then
        handlers[event] = nil
        pcall(eventFrame.UnregisterEvent, eventFrame, event)
    else
        handlers[event] = new
    end
end

--- Test/debug helper: deliver a game event to the registered handlers.
function ns:DispatchEvent(event, ...)
    dispatch(event, ...)
end

---------------------------------------------------------------------------
-- internal callbacks: ns:Listen(msg, fn) / ns:Fire(msg, ...)
-- Listeners are called as fn(msg, ...payload) (same convention as ns:On).
---------------------------------------------------------------------------

local listeners = {}

function ns:Listen(msg, fn)
    if type(msg) ~= "string" or type(fn) ~= "function" then return false end
    local list = listeners[msg] or {}
    for i = 1, #list do
        if list[i] == fn then return true end
    end
    local new = {}
    for i = 1, #list do new[i] = list[i] end
    new[#new + 1] = fn
    listeners[msg] = new
    return true
end

function ns:Unlisten(msg, fn)
    local list = listeners[msg]
    if not list then return end
    local new = {}
    for i = 1, #list do
        if list[i] ~= fn then new[#new + 1] = list[i] end
    end
    listeners[msg] = (#new > 0) and new or nil
end

function ns:Fire(msg, ...)
    local list = listeners[msg]
    if not list then return end
    for i = 1, #list do
        safeCall(list[i], msg, ...)
    end
end

---------------------------------------------------------------------------
-- chat output
---------------------------------------------------------------------------

local PREFIX = "|cff33ff99Fastes|r|cffffd100Boooy|r: "

local function render(fmt, ...)
    if select("#", ...) == 0 then return tostring(fmt) end
    local ok, s = pcall(format, tostring(fmt), ...)
    if ok then return s end
    local parts = { tostring(fmt) }
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
    return table.concat(parts, " ")
end

function ns.Print(fmt, ...)
    local msg = PREFIX .. render(fmt, ...)
    local chat = DEFAULT_CHAT_FRAME
    if chat and chat.AddMessage then
        chat:AddMessage(msg)
    else
        print(msg)
    end
end

function ns.IsDebug()
    local db = ns.db
    if not db then return false end
    return (db.debug or (db.settings and db.settings.debug)) and true or false
end

function ns.Debug(...)
    if not ns.IsDebug() then return end
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
    ns.Print("|cff999999[debug]|r %s", table.concat(parts, " "))
end

---------------------------------------------------------------------------
-- SavedVariables
---------------------------------------------------------------------------

ns.DEFAULTS = {
    db = {
        dbVersion = 1,
        settings = {
            automation = true,      -- master switch for quest automation
            autoAccept = true,
            autoTurnin = true,
            autoGossip = true,
            arrow = true,
            blizzWaypoint = false,  -- also place Blizzard's user waypoint + super-track it
            lookahead = 6,          -- accept route quests in steps [cursor, cursor + lookahead]
            shownNext = 4,          -- upcoming steps shown by the step frame
            frameScale = 1,
            arrowScale = 1,
            locked = false,
            hideInCombat = false,
            debug = false,
        },
        frames = {
            steps = { point = "RIGHT", relativePoint = "RIGHT", x = -80, y = 120 },
            arrow = { point = "TOP", relativePoint = "TOP", x = 0, y = -140 },
            item = { point = "RIGHT", relativePoint = "RIGHT", x = -388, y = 120 }, -- left of the steps window
        },
        xpLog = {},        -- [questID] = xp reward observed in game (max seen)
        xpLogLevel = {},   -- [questID] = player level when xpLog[questID] was recorded
    },
    cdb = {
        -- route = "<route id>" | nil (nil = automatic selection)
        manual = {},       -- [stepId] = true: step marked done with "Next"
        skipped = {},      -- [stepId] = true: step skipped
        bgDone = {},       -- [stepId] = true: background step seen done (collect / transient; optimization)
        -- cursorHint = n, cursorHintId = "<step id>": high-water mark of the cursor
    },
}

local function copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = copy(x) end
    return t
end
ns.CopyTable = copy

-- Fill missing keys of dst from defaults; scalars of the wrong type are reset.
local function fill(dst, defaults)
    for k, dv in pairs(defaults) do
        local cur = dst[k]
        if cur == nil then
            dst[k] = copy(dv)
        elseif type(dv) == "table" then
            if type(cur) ~= "table" then
                dst[k] = copy(dv)
            else
                fill(cur, dv)
            end
        elseif type(cur) ~= type(dv) then
            dst[k] = dv
        end
    end
    return dst
end
ns.FillDefaults = fill

-- Until ADDON_LOADED delivers the saved tables, work on volatile defaults so
-- nothing has to nil-check ns.db / ns.cdb.
ns.db = fill({}, ns.DEFAULTS.db)
ns.cdb = fill({}, ns.DEFAULTS.cdb)
ns.dbReady = false

function ns:InitDB()
    if type(FastesBoooyDB) ~= "table" then FastesBoooyDB = {} end
    if type(FastesBoooyCharDB) ~= "table" then FastesBoooyCharDB = {} end
    fill(FastesBoooyDB, ns.DEFAULTS.db)
    fill(FastesBoooyCharDB, ns.DEFAULTS.cdb)
    local cdb = FastesBoooyCharDB
    if cdb.route ~= nil and type(cdb.route) ~= "string" then cdb.route = nil end
    if cdb.cursorHint ~= nil and type(cdb.cursorHint) ~= "number" then cdb.cursorHint = nil end
    ns.db = FastesBoooyDB
    ns.cdb = FastesBoooyCharDB
    ns.dbReady = true
    ns:Fire("DB_READY")
end

local function onAddonLoaded(event, name)
    if name ~= ns.ADDON then return end
    ns:Off(event, onAddonLoaded)
    ns:InitDB()
end
ns:On("ADDON_LOADED", onAddonLoaded)
