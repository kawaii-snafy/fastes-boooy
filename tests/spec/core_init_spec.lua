-- Core/Init.lua (event dispatcher, internal callbacks, error routing, SavedVariables
-- defaults, chat output) and the locale tables (ruRU -> enUS -> key fallback, key and
-- format-specifier parity of the enUS / ruRU files).

local H = require("fixtures.core.helpers")

local m, ns

local LOCALE_DIR = "addons/FastesBoooy/Locales/"

local function loadLocales()
    local fake = { Locales = {} }
    for _, f in ipairs({ "enUS", "ruRU", "UI_enUS", "UI_ruRU" }) do
        local chunk = assert(loadfile(LOCALE_DIR .. f .. ".lua"))
        setfenv(chunk, {})
        chunk("FastesBoooy", fake)
    end
    return fake.Locales
end

local function specifiers(s)
    local out = {}
    for spec in s:gsub("%%%%", ""):gmatch("%%[%-%d%.]*[%a]") do out[#out + 1] = spec end
    return table.concat(out, " ")
end

local function sortedKeys(t)
    local out = {}
    for k in pairs(t) do out[#out + 1] = k end
    table.sort(out)
    return out
end

describe("Init", function()
    after_each(function() if m then m:AssertClean() end end)

    it("dispatches game events to several handlers and routes handler errors to geterrorhandler", function()
        m, ns = H.boot()
        local got = {}
        local function a(event, x) got[#got + 1] = "a:" .. event .. ":" .. tostring(x) end
        local function bad() error("boom in handler") end
        local function b(event, x) got[#got + 1] = "b:" .. event .. ":" .. tostring(x) end
        assert.is_true(ns:On("QUEST_ACCEPTED", a))
        assert.is_true(ns:On("QUEST_ACCEPTED", bad))
        assert.is_true(ns:On("QUEST_ACCEPTED", b))
        assert.is_true(ns:On("QUEST_ACCEPTED", a), "registering twice is a no-op")
        m.raiseErrors = false
        m:Fire("QUEST_ACCEPTED", 363)
        m.raiseErrors = true
        assert.same({ "a:QUEST_ACCEPTED:363", "b:QUEST_ACCEPTED:363" }, got)
        assert.equal(1, #m.errors)
        assert.matches("boom in handler", m.errors[1].message)
        m:ClearDiagnostics()
        ns:Off("QUEST_ACCEPTED", bad)
        ns:Off("QUEST_ACCEPTED", a)
        m:Fire("QUEST_ACCEPTED", 364)
        assert.same({ "a:QUEST_ACCEPTED:363", "b:QUEST_ACCEPTED:363", "b:QUEST_ACCEPTED:364" }, got)
        assert.is_false(ns:On("NOT_A_REAL_EVENT_FOR_SURE", a), "unknown events are refused")
        assert.is_false(ns:On(nil, a))
    end)

    it("fires internal messages to listeners (errors routed, others still called)", function()
        m, ns = H.boot()
        local got = {}
        ns:Listen("TEST_MSG", function(msg, x, y) got[#got + 1] = msg .. x .. y end)
        ns:Listen("TEST_MSG", function() error("listener failure") end)
        ns:Listen("TEST_MSG", function(_, x) got[#got + 1] = "second" .. x end)
        m.raiseErrors = false
        ns:Fire("TEST_MSG", 1, 2)
        m.raiseErrors = true
        assert.same({ "TEST_MSG12", "second1" }, got)
        assert.equal(1, #m.errors)
        m:ClearDiagnostics()
        ns:Fire("NOBODY_LISTENS")
    end)

    it("fills the SavedVariables with defaults on ADDON_LOADED and fires DB_READY", function()
        m, ns = H.new({ savedVariables = {
            FastesBoooyDB = { settings = { lookahead = "seven", arrow = false }, frames = 5 },
            FastesBoooyCharDB = { route = 42, cursorHint = "x", manual = { a = true } },
        } })
        local ready = H.record(ns, "DB_READY")
        assert.is_false(ns.dbReady)
        assert.equal(6, ns.db.settings.lookahead, "volatile defaults before ADDON_LOADED")
        H.Mock.boot(m, { "FastesBoooy", H.FIXTURE_NAME })
        assert.is_true(ns.dbReady)
        assert.equal(1, #ready)
        local db, cdb = m.env.FastesBoooyDB, m.env.FastesBoooyCharDB
        assert.equal(db, ns.db)
        assert.equal(cdb, ns.cdb)
        assert.equal(6, db.settings.lookahead, "wrong type reset")
        assert.is_false(db.settings.arrow, "saved value kept")
        for k, v in pairs(ns.DEFAULTS.db.settings) do
            assert.equal(type(v), type(db.settings[k]), k)
        end
        assert.same(ns.DEFAULTS.db.frames, db.frames)
        assert.same({}, db.xpLog)
        assert.equal(1, db.dbVersion)
        assert.is_nil(cdb.route, "invalid route id dropped")
        assert.is_true(cdb.manual.a)
        assert.same({}, cdb.skipped)
        assert.equal("test-route", ns.Engine:GetRoute().id)
    end)

    it("adds the automation delay settings to older SavedVariables and keeps them in range", function()
        local function bootWith(settings)
            m, ns = H.new({ savedVariables = { FastesBoooyDB = { dbVersion = 1, settings = settings } } })
            H.Mock.boot(m, { "FastesBoooy", H.FIXTURE_NAME })
            return m.env.FastesBoooyDB.settings
        end
        -- saved before the setting existed: the defaults (0.5 s + random 0..0.3 s)
        local s = bootWith({ automation = true, autoAccept = false, lookahead = 4 })
        assert.equal(0.5, s.autoDelay)
        assert.equal(0.3, s.autoDelayJitter)
        assert.is_false(s.autoAccept, "other saved values kept")
        assert.equal(4, s.lookahead)
        assert.equal(0.5, ns.DEFAULTS.db.settings.autoDelay)
        assert.equal(0.3, ns.DEFAULTS.db.settings.autoDelayJitter)
        -- saved values are kept, out-of-range ones clamped (0..3 s, 0..1 s), wrong types reset
        s = bootWith({ autoDelay = 0, autoDelayJitter = 0.25 })
        assert.equal(0, s.autoDelay, "0 = instant, kept")
        assert.equal(0.25, s.autoDelayJitter)
        s = bootWith({ autoDelay = 12, autoDelayJitter = -1 })
        assert.equal(3, s.autoDelay)
        assert.equal(0, s.autoDelayJitter)
        s = bootWith({ autoDelay = "slow", autoDelayJitter = 0 / 0 })
        assert.equal(0.5, s.autoDelay)
        assert.equal(0.3, s.autoDelayJitter, "NaN")
        assert.same({ 0, 3 }, ns.SETTING_RANGES.autoDelay)
        assert.same({ 0, 1 }, ns.SETTING_RANGES.autoDelayJitter)
    end)

    it("prints with the addon prefix and is %-safe; debug output only when enabled", function()
        m, ns = H.boot()
        local mark = #m.chat
        ns.Print("100%% done %d", 5)
        ns.Print("raw % text")
        ns.Print("%d", "not a number")
        ns.Debug("hidden")
        assert.same({ "100% done 5", "raw % text", "%d not a number" }, H.chat(m, mark + 1))
        assert.is_truthy(m.chat[mark + 1]:find("^|cff33ff99Fastes|r|cffffd100Boooy|r: "))
        ns.UI.SetSetting("debug", true)
        ns.Debug("shown", 1)
        assert.is_true(H.chatHas(m, "[debug]|r shown 1", mark + 1))
    end)
end)

describe("locales", function()
    after_each(function() if m then m:AssertClean() end end)

    it("ruRU and enUS define the same keys with the same format specifiers", function()
        local L = loadLocales()
        assert.same(sortedKeys(L.enUS), sortedKeys(L.ruRU))
        assert.is_true(#sortedKeys(L.enUS) > 100)
        for k, en in pairs(L.enUS) do
            assert.equal(specifiers(en), specifiers(L.ruRU[k]), k)
            assert.is_true(L.ruRU[k] ~= "", k)
        end
    end)

    it("every locale key used by the addon exists in enUS", function()
        local L = loadLocales().enUS
        local toc = H.Mock.parseToc(H.CORE_TOC)
        local missing = {}
        for _, f in ipairs(toc.files) do
            local fh = assert(io.open("addons/FastesBoooy/" .. f, "rb"))
            local src = fh:read("*a")
            fh:close()
            if not f:find("^Locales/") then
                for key in src:gmatch("%f[%w_]Lc?%.([A-Z][A-Z0-9_]+)") do
                    if L[key] == nil then missing[#missing + 1] = f .. ": " .. key end
                end
                for key in src:gmatch("L%(%)%.([A-Z][A-Z0-9_]+)") do
                    if L[key] == nil then missing[#missing + 1] = f .. ": " .. key end
                end
                for key in src:gmatch("L%[\"([A-Z][A-Z0-9_]+)\"%]") do
                    if L[key] == nil then missing[#missing + 1] = f .. ": " .. key end
                end
            end
        end
        -- keys built at run time (UI/Options.lua)
        for _, k in ipairs({ "automation", "autoAccept", "autoTurnin", "autoGossip", "arrow", "blizzWaypoint",
            "locked", "hideInCombat", "debug", "lookahead", "shownNext", "frameScale", "arrowScale", "autoDelay",
            "autoDelayJitter" }) do
            for _, key in ipairs({ "UI_OPT_" .. k, "UI_OPT_" .. k .. "_TT" }) do
                if L[key] == nil then missing[#missing + 1] = key end
            end
        end
        for _, k in ipairs({ "show", "lock", "next", "reset", "routes", "route", "config", "delay", "status", "xp",
            "debug" }) do
            if L["UI_HELP_" .. k] == nil then missing[#missing + 1] = "UI_HELP_" .. k end
        end
        assert.same({}, missing)
    end)

    it("falls back ruRU -> enUS -> key at run time", function()
        m, ns = H.boot({ locale = "ruRU" })
        assert.equal("ruRU", ns.locale)
        assert.equal("Взять: %s", ns.L.STEP_ACCEPT)
        ns.Locales.ruRU.STEP_ACCEPT = nil
        assert.equal("Accept: %s", ns.L.STEP_ACCEPT, "missing ruRU key -> enUS")
        assert.equal("NO_SUCH_KEY", ns.L.NO_SUCH_KEY, "missing everywhere -> the key")
        assert.equal("Accept: Rude Awakening", ns.Steps:Label(ns.Engine:GetCurrentStep()))

        m, ns = H.boot({ locale = "deDE" })
        assert.equal("deDE", ns.locale)
        assert.equal("Accept: %s", ns.L.STEP_ACCEPT, "other locales use enUS")
        assert.equal("Back", ns.L.UI_BTN_PREV)
    end)
end)
