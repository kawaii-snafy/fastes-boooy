-- tests/mocks/wow/system.lua
--
-- Clock, C_Timer, frames' OnUpdate, event dispatch, error handler, addon loading
-- (TOC parsing, SavedVariables), slash commands, static popups, Settings API, and
-- assorted client globals (GetTime, GetBuildInfo, GetLocale, print, hooksecurefunc...).

local ctx = ...
local Mock, M, A, U = ctx.Mock, ctx.M, ctx.A, ctx.U

local floor = math.floor
local EPS = 1e-9

---------------------------------------------------------------------------
-- errors
---------------------------------------------------------------------------

--- Call fn(...) the way the client calls scripts: errors go to the current error
-- handler (recorded in m.errors) and do not propagate. Returns ok, results...
function M:_safecall(fn, ...)
    local m = self
    local handler = function(err)
        local tb = debug.traceback(tostring(err), 2)
        local h = m._errorHandler
        if h then
            local ok, herr = pcall(h, err)
            if not ok then
                m.errors[#m.errors + 1] = { message = "error in error handler: " .. tostring(herr), traceback = tb }
            end
        end
        if h ~= m._defaultErrorHandler then
            -- custom handlers set by loaded code: still record so specs fail
            m.errors[#m.errors + 1] = { message = tostring(err), traceback = tb }
        else
            m.errors[#m.errors].traceback = tb
        end
        return err
    end
    local n = select("#", ...)
    if n == 0 then return xpcall(fn, handler) end
    local args = { ... }
    return xpcall(function() return fn(unpack(args, 1, n)) end, handler)
end

---------------------------------------------------------------------------
-- clock & timers
---------------------------------------------------------------------------

function M:Now() return self.clock end

function M:ServerTime() return self.epoch + floor(self.clock - self.clockStart) end

local function newTimerHandle(m, rec)
    local h = {}
    function h.Cancel() rec.cancelled = true end
    function h.IsCancelled() return rec.cancelled == true end
    function h.Invoke(_, ...) return rec.cb(...) end
    rec.handle = h
    return h
end

function M:_addTimer(seconds, cb, kind, iterations)
    self._timerSeq = self._timerSeq + 1
    local rec = {
        due = self.clock + math.max(seconds, 0), interval = seconds, cb = cb, kind = kind,
        iterations = iterations, seq = self._timerSeq, cancelled = false,
        bornFrame = self.frameCount,
    }
    self._timers[#self._timers + 1] = rec
    return rec
end

--- Schedule a mock-internal callback (not visible to the addon) after `seconds`.
function M:_after(seconds, fn)
    return self:_addTimer(seconds, fn, "internal")
end

--- Server-side effects: immediate, or after opts.serverDelay seconds of mock time.
function M:_server(fn)
    if (self.serverDelay or 0) > 0 then
        self:_after(self.serverDelay, fn)
    else
        fn()
    end
end

local function runTimers(m)
    -- each due timer fires at most once per frame, in (due, seq) order
    local due = {}
    for _, t in ipairs(m._timers) do
        if not t.cancelled and t.due <= m.clock + EPS and t.bornFrame < m.frameCount then
            due[#due + 1] = t
        end
    end
    table.sort(due, function(a, b)
        if a.due ~= b.due then return a.due < b.due end
        return a.seq < b.seq
    end)
    for _, t in ipairs(due) do
        if not t.cancelled then
            if t.kind == "after" then
                t.cancelled = true
                m:_safecall(t.cb)
            elseif t.kind == "timer" then
                t.cancelled = true
                m:_safecall(t.cb, t.handle)
            elseif t.kind == "ticker" then
                if t.iterations then
                    t.iterations = t.iterations - 1
                    if t.iterations <= 0 then t.cancelled = true end
                end
                if not t.cancelled then t.due = m.clock + t.interval end
                m:_safecall(t.cb, t.handle)
            else -- internal
                t.cancelled = true
                t.cb()
            end
        end
    end
    local keep = {}
    for _, t in ipairs(m._timers) do
        if not t.cancelled then keep[#keep + 1] = t end
    end
    m._timers = keep
end

--- Simulate one client frame of `dt` seconds: timers, then OnUpdate scripts.
function M:_frame(dt)
    self.frameCount = self.frameCount + 1
    self.clock = self.clock + dt
    runTimers(self)
    if self._updateWidgets then self:_updateWidgets(dt) end
end

--- Advance the mock clock by `seconds` (in frames of opts.frameTime, default 0.05s):
-- runs due C_Timer callbacks / tickers and the OnUpdate scripts of visible frames.
-- Advance(0) runs a single zero-length frame (C_Timer.After(0, ...) callbacks).
function M:Advance(seconds)
    seconds = seconds or 0
    return self:_top(function()
        if seconds <= 0 then
            self:_frame(0)
            return
        end
        local target = self.clock + seconds
        while self.clock < target - EPS do
            local dt = math.min(self.frameTime, target - self.clock)
            self:_frame(dt)
        end
    end)
end

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------

function M:_registerEvent(frame, event, units)
    local list = self._eventRegs[event]
    if not list then list = {}; self._eventRegs[event] = list end
    for _, f in ipairs(list) do
        if f == frame then
            self._eventUnits[frame] = self._eventUnits[frame] or {}
            self._eventUnits[frame][event] = units
            return
        end
    end
    list[#list + 1] = frame
    self._eventUnits[frame] = self._eventUnits[frame] or {}
    self._eventUnits[frame][event] = units
end

function M:_unregisterEvent(frame, event)
    local list = self._eventRegs[event]
    if not list then return end
    for i, f in ipairs(list) do
        if f == frame then table.remove(list, i); break end
    end
    if self._eventUnits[frame] then self._eventUnits[frame][event] = nil end
end

function M:_isEventRegistered(frame, event)
    for _, f in ipairs(self._eventRegs[event] or {}) do
        if f == frame then return true end
    end
    return self._allEvents[frame] == true
end

function M:_unregisterAll(frame)
    for event in pairs(self._eventRegs) do self:_unregisterEvent(frame, event) end
    self._allEvents[frame] = nil
end

local function checkPayload(m, event, ...)
    local spec = A.parsedEvents[event]
    if not spec then return end
    for i, a in ipairs(spec) do
        local v = select(i, ...)
        if v ~= nil then
            local want = A.checkValue(a.code, v)
            if want then
                m:_violation(("event %s payload #%d (%s): %s expected, got %s"):format(event, i, a.name, want, type(v)), 3)
            end
        end
    end
end

function M:_dispatch(event, ...)
    if not A.events[event] then
        self:_violation(("fires unknown event %q (not in the Forever client)"):format(tostring(event)), 2)
    end
    checkPayload(self, event, ...)
    self.eventLog[#self.eventLog + 1] = { event, ... }
    local targets = {}
    for _, f in ipairs(self._eventRegs[event] or {}) do targets[#targets + 1] = f end
    for _, f in ipairs(self._allEventsOrder) do
        if self._allEvents[f] then targets[#targets + 1] = f end
    end
    local unit = ...
    for _, frame in ipairs(targets) do
        if self:_isEventRegistered(frame, event) then
            local units = self._eventUnits[frame] and self._eventUnits[frame][event]
            local pass = true
            if units and #units > 0 then
                pass = false
                for _, u in ipairs(units) do if u == unit then pass = true end end
            end
            if pass and self._runScript then self:_runScript(frame, "OnEvent", event, ...) end
        end
    end
end

--- Fire a game event to every frame registered for it (validated against the
-- Forever event list and, when documented, the payload types).
function M:Fire(event, ...)
    local n, args = select("#", ...), { ... }
    return self:_top(function() self:_dispatch(event, unpack(args, 1, n)) end)
end

--- Events fired so far (array of { event, payload... }); optional name filter.
function M:Events(name)
    local out = {}
    for _, e in ipairs(self.eventLog) do
        if name == nil or e[1] == name then out[#out + 1] = e end
    end
    return out
end

---------------------------------------------------------------------------
-- TOC / addon loading
---------------------------------------------------------------------------

--- Parse a TOC file. Returns { dir, meta = {Key = value}, metaLower = {key = value}, files = {...} }.
function Mock.parseToc(path)
    local fh = io.open(path, "rb")
    if not fh then error("mock: cannot open TOC " .. tostring(path), 2) end
    local text = fh:read("*a")
    fh:close()
    text = text:gsub("^\239\187\191", "")                     -- UTF-8 BOM
    local toc = { path = path, dir = path:match("^(.*[/\\])") or "./", meta = {}, metaLower = {}, files = {} }
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        line = line:gsub("\r$", "")
        local key, value = line:match("^##%s*([^:]+):%s*(.-)%s*$")
        local skip = line:match("^%s*#") or line:match("^%s*$")      -- comment / blank line
        if key then
            key = key:gsub("%s+$", "")
            toc.meta[key] = value
            toc.metaLower[key:lower()] = value
        elseif not skip then
            local file = line:gsub("^%s+", ""):gsub("%s+$", "")
            local include = true
            -- per-line load conditions: "file.lua [AllowLoadGameType camelot]"
            for cond, args in file:gmatch("%[(%a+)%s+([^%]]*)%]") do
                local types = {}
                for t in args:gmatch("[^,%s]+") do types[t:lower()] = true end
                if cond == "AllowLoadGameType" then
                    include = include and (types.camelot or types.mainline) and true or false
                elseif cond == "ExcludeLoadGameType" then
                    include = include and not (types.camelot or types.mainline)
                end
            end
            file = file:gsub("%s*%[[^%]]*%]", "")
            file = file:gsub("%[Family%]", "Mainline"):gsub("%[Game%]", "Camelot")
            file = file:gsub("\\", "/")
            if include and file ~= "" then toc.files[#toc.files + 1] = file end
        end
    end
    return toc
end

local function splitList(s)
    local out = {}
    for name in tostring(s or ""):gmatch("[^,%s]+") do out[#out + 1] = name end
    return out
end

function M:_applySavedVariables(addon)
    for _, name in ipairs(addon.savedVariables) do
        self._svNames[name] = true
        local v = self.savedVariables[name]
        rawset(self.env, name, U.deepcopy(v))
    end
end

--- Run one file of an addon with the client environment and (addonName, ns) varargs.
function M:_runFile(path, addonName, ns)
    local fn, err = loadfile(path)
    if not fn then
        error("mock: cannot load " .. path .. ": " .. tostring(err), 0)
    end
    setfenv(fn, self.env)
    local ok, res = self:_safecall(fn, addonName, ns)
    if not ok then
        error("mock: error while loading " .. path .. ": " .. tostring(res), 0)
    end
end

--- Load an addon from its TOC (files only; ADDON_LOADED is fired by Mock.boot).
-- Returns the addon's private namespace table (the 2nd vararg of every file).
-- @param opts { skip = { [TOC path with forward slashes] = true } }: files that are not run (the file
--        filter of the offline tools, --skip / --keep: tools/lib/route_loader.lua mod.skipSet);
--        addon.skipped lists them
function Mock.loadAddon(m, tocPath, addonName, opts)
    local skip = opts and opts.skip or nil
    local toc = Mock.parseToc(tocPath)
    addonName = addonName or tocPath:match("([^/\\]+)%.toc$"):gsub("[_%-]Camelot$", ""):gsub("[_%-]Forever$", "")
    local iface = tonumber((toc.metaLower.interface or ""):match("(%d+)"))
    local ifaceOK = false
    for v in tostring(toc.metaLower.interface or ""):gmatch("%d+") do
        if tonumber(v) == A.build[4] then ifaceOK = true end
    end
    if not ifaceOK then
        m:_warn(("addon %s: ## Interface %s does not list %s"):format(addonName, tostring(toc.metaLower.interface), tostring(A.build[4])))
    end
    local addon = {
        name = addonName, toc = toc, meta = toc.meta, metaLower = toc.metaLower, interface = iface,
        ns = {}, loaded = false,
        savedVariables = {}, skipped = {},
    }
    for _, n in ipairs(splitList(toc.metaLower.savedvariables)) do addon.savedVariables[#addon.savedVariables + 1] = n end
    for _, n in ipairs(splitList(toc.metaLower.savedvariablespercharacter)) do
        addon.savedVariables[#addon.savedVariables + 1] = n
    end
    for _, n in ipairs(addon.savedVariables) do m._svNames[n] = true end
    m.addons[addonName] = addon
    m.addonOrder[#m.addonOrder + 1] = addonName
    m:_top(function()
        if toc.metaLower.loadsavedvariablesfirst == "1" then m:_applySavedVariables(addon); addon.svApplied = true end
        for _, file in ipairs(toc.files) do
            if file:match("%.xml$") then
                error("mock: " .. addonName .. ": XML files are not supported by the mock (" .. file .. ")", 0)
            end
            if skip and skip[file] then
                addon.skipped[#addon.skipped + 1] = file
            else
                m:_runFile(toc.dir .. file, addonName, addon.ns)
            end
        end
    end)
    addon.loaded = true
    return addon.ns
end

--- Boot the client: for each addon (name of an addon already loaded with
-- Mock.loadAddon, or { toc = path [, name = addonName] } to load it now) apply its
-- SavedVariables and fire ADDON_LOADED; then PLAYER_LOGIN and PLAYER_ENTERING_WORLD
-- (isInitialLogin = not opts.reload, isReloadingUi = opts.reload), followed by the
-- QUEST_LOG_UPDATE / BAG_UPDATE_DELAYED the client sends after entering the world.
function Mock.boot(m, addons, opts)
    opts = opts or {}
    return m:_top(function()
        for _, entry in ipairs(addons or {}) do
            local name = entry
            if type(entry) == "table" then
                Mock.loadAddon(m, entry.toc, entry.name)
                name = entry.name or m.addonOrder[#m.addonOrder]
            end
            local addon = m.addons[name]
            if not addon then error("mock: boot: addon " .. tostring(name) .. " was not loaded", 0) end
            if not addon.svApplied then m:_applySavedVariables(addon); addon.svApplied = true end
            m:_dispatch("ADDON_LOADED", name, false)
        end
        m.loggedIn = true
        m:_dispatch("PLAYER_LOGIN")
        m:_dispatch("PLAYER_ENTERING_WORLD", not opts.reload, opts.reload and true or false)
        m:_dispatch("QUEST_LOG_UPDATE")
        m:_dispatch("BAG_UPDATE_DELAYED")
    end)
end

--- SavedVariables of the loaded addons (deep copies), for Mock.new{ savedVariables = ... }
-- to simulate /reload. A cold client restart on Forever may lose them (see README).
function M:ExportSavedVariables()
    local out = {}
    for _, name in ipairs(self.addonOrder) do
        for _, sv in ipairs(self.addons[name].savedVariables) do
            out[sv] = U.deepcopy(rawget(self.env, sv))
        end
    end
    return out
end

--- Register metadata for an addon that is not loaded from a TOC (C_AddOns queries).
function M:RegisterAddOn(name, meta, loaded)
    local lower = {}
    for k, v in pairs(meta or {}) do lower[k:lower()] = v end
    self.addons[name] = { name = name, meta = meta or {}, metaLower = lower, ns = {}, loaded = loaded ~= false,
        savedVariables = {} }
    self.addonOrder[#self.addonOrder + 1] = name
end

---------------------------------------------------------------------------
-- slash commands
---------------------------------------------------------------------------

--- Run a chat slash command ("/aa xp"). Returns true when a handler ran.
function M:RunSlash(text)
    local cmd, rest = tostring(text):match("^(/%S+)%s*(.-)%s*$")
    if not cmd then return false end
    cmd = cmd:lower()
    local env = self.env
    local handlerKey
    for k, v in pairs(env) do
        if type(k) == "string" and type(v) == "string" then
            local key = k:match("^SLASH_(.-)%d+$")
            if key and v:lower() == cmd then handlerKey = key; break end
        end
    end
    local list = rawget(env, "SlashCmdList")
    local fn = handlerKey and list and rawget(list, handlerKey)
    if not fn then return false end
    self:_action("Slash", text)
    self:_top(function() self:_safecall(fn, rest, nil) end)
    return true
end

---------------------------------------------------------------------------
-- static popups
---------------------------------------------------------------------------

--- Click a button of a visible static popup: "button1" (OnAccept), "button2" (OnCancel),
-- "button3" (OnAlt). Returns true when the popup was visible.
function M:PopupClick(which, button)
    button = button or "button1"
    for i, p in ipairs(self.popups) do
        if p.which == which then
            table.remove(self.popups, i)
            local info = p.info
            self:_top(function()
                local cb = (button == "button1" and info.OnAccept) or (button == "button2" and info.OnCancel)
                    or (button == "button3" and info.OnAlt)
                if cb then self:_safecall(cb, p.dialog, p.data, p.data2) end
                if info.OnHide then self:_safecall(info.OnHide, p.dialog, p.data) end
            end)
            return true
        end
    end
    return false
end

function M:PopupVisible(which)
    for _, p in ipairs(self.popups) do
        if p.which == which then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- installer
---------------------------------------------------------------------------

ctx.register(function(m)
    local opts = m.opts
    m.frameTime = opts.frameTime or 0.05
    m.clock = opts.time or 1000
    m.clockStart = m.clock
    m.epoch = opts.epoch or 1793318400          -- 2026-10-30 00:00 UTC
    m.frameCount = 0
    m.serverDelay = opts.serverDelay or 0
    m._timers, m._timerSeq = {}, 0
    m._eventRegs, m._eventUnits = {}, setmetatable({}, { __mode = "k" })
    m._allEvents, m._allEventsOrder = setmetatable({}, { __mode = "k" }), {}
    m.eventLog = {}
    m.addons, m.addonOrder = {}, {}
    m._svNames = {}
    m.savedVariables = U.deepcopy(opts.savedVariables or {})
    m.loggedIn = false
    m.popups = {}
    m.settingsCategories = {}
    m.settingsOpened = nil

    -- error handler
    m._defaultErrorHandler = function(err)
        m.errors[#m.errors + 1] = { message = tostring(err) }
        return err
    end
    m._errorHandler = m._defaultErrorHandler
    m:ProvideAPI("geterrorhandler", function() return m._errorHandler end)
    m:ProvideAPI("seterrorhandler", function(fn)
        if type(fn) ~= "function" then error("Usage: seterrorhandler(errfunc)", 2) end
        m._errorHandler = fn
    end)

    -- time
    m:ProvideAPI("GetTime", function() return m.clock end)
    m:ProvideAPI("GetServerTime", function() return m:ServerTime() end)
    m:ProvideAPI("GetTimePreciseSec", function() return m.clock end)
    m:ProvideAPI("debugprofilestop", function() return (m.clock - m.clockStart) * 1000 end)
    m:ProvideAPI("GetFramerate", function() return 1 / m.frameTime end)

    m:ProvideNS("C_Timer", {
        After = function(seconds, callback)
            m:_addTimer(seconds, callback, "after")
        end,
        NewTimer = function(seconds, callback)
            local rec = m:_addTimer(seconds, callback, "timer")
            return newTimerHandle(m, rec)
        end,
        NewTicker = function(seconds, callback, iterations)
            local rec = m:_addTimer(seconds, callback, "ticker", iterations)
            return newTimerHandle(m, rec)
        end,
    })

    -- client / build
    local build = opts.build or { A.build[1] or "1.60.1", "70862", A.build[3] or "", A.build[4] or 16001 }
    m:ProvideAPI("GetBuildInfo", function()
        return build[1], build[2], build[3], build[4], build[1], "Release"
    end)
    m:ProvideAPI("GetLocale", function() return opts.locale or "enUS" end)
    m:ProvideAPI("GetRealmName", function() return m.player.realm end)
    m:ProvideAPI("GetNormalizedRealmName", function() return (m.player.realm:gsub("[%s%-]", "")) end)
    m:ProvideAPI("IsLoggedIn", function() return m.loggedIn end)
    m:ProvideAPI("GetCurrentRegion", function() return 3 end)
    m:Provide("WOW_PROJECT_MAINLINE", 1)
    m:Provide("WOW_PROJECT_CLASSIC", 2)
    m:Provide("WOW_PROJECT_CAMELOT", 18)
    m:Provide("WOW_PROJECT_ID", opts.projectID or 18)
    m:Provide("LE_EXPANSION_LEVEL_CURRENT", A.leValues.LE_EXPANSION_LEVEL_CURRENT or 0)

    -- enums / constants (closed tables built from the dump)
    local enum = {}
    for name, values in pairs(A.enums) do enum[name] = U.deepcopy(values) end
    m:Provide("Enum", enum)
    local constants = {}
    for name, values in pairs(A.constants) do constants[name] = U.deepcopy(values) end
    m:Provide("Constants", constants)

    -- secret values (Midnight-style restriction system)
    m:ProvideAPI("issecretvalue", function(v) return m:IsSecret(v) end)
    m:ProvideAPI("issecrettable", function(t) return m:IsSecret(t) end)
    m:ProvideAPI("canaccessvalue", function(v) return not m:IsSecret(v) end)
    m:ProvideAPI("canaccesssecrets", function() return true end)
    m:ProvideAPI("canaccesstable", function(t) return not m:IsSecret(t) end)
    m:ProvideAPI("hasanysecretvalues", function(...)
        for i = 1, select("#", ...) do if m:IsSecret((select(i, ...))) then return true end end
        return false
    end)

    -- FrameXML helpers
    m:Provide("print", function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
        local chat = rawget(m.env, "DEFAULT_CHAT_FRAME")
        if chat then chat:AddMessage(table.concat(parts, " ")) else m.chat[#m.chat + 1] = table.concat(parts, " ") end
    end)
    m:Provide("tostringall", function(...)
        local n = select("#", ...)
        local out = {}
        for i = 1, n do out[i] = tostring((select(i, ...))) end
        return unpack(out, 1, n)
    end)
    m:Provide("nop", function() end)
    m:ProvideAPI("hooksecurefunc", function(a, b, c)
        local tbl, name, hook
        if type(a) == "table" then tbl, name, hook = a, b, c else tbl, name, hook = m.env, a, b end
        if type(name) ~= "string" or type(hook) ~= "function" then
            error("Usage: hooksecurefunc([table,] \"functionName\", hookfunc)", 2)
        end
        local orig = tbl[name]
        if type(orig) ~= "function" then error("hooksecurefunc(): " .. name .. " is not a function", 2) end
        tbl[name] = function(...)
            local res = U.pack(orig(...))
            m:_safecall(hook, ...)
            return unpack(res, 1, res.n)
        end
    end)
    local function mixin(object, ...)
        for i = 1, select("#", ...) do
            local mx = select(i, ...)
            for k, v in pairs(mx) do object[k] = v end
        end
        return object
    end
    m:Provide("Mixin", mixin)
    m:Provide("CreateFromMixins", function(...) return mixin({}, ...) end)
    m:Provide("CreateAndInitFromMixin", function(mx, ...)
        local o = mixin({}, mx)
        if o.Init then o:Init(...) end
        return o
    end)
    m:Provide("CopyTable", function(t, shallow)
        if shallow then local o = {}; for k, v in pairs(t) do o[k] = v end; return o end
        return U.deepcopy(t)
    end)
    m:Provide("CreateColor", Mock.CreateColor)
    m:Provide("CreateCounter", function(initial)
        local count = initial or 0
        return function() count = count + 1; return count end
    end)

    -- addons (metadata of TOCs loaded with Mock.loadAddon / m:RegisterAddOn)
    local function addonOf(nameOrIndex)
        if type(nameOrIndex) == "number" then nameOrIndex = m.addonOrder[nameOrIndex] end
        return nameOrIndex and m.addons[nameOrIndex] or nil
    end
    m:ProvideNS("C_AddOns", {
        GetAddOnMetadata = function(name, variable)
            local a = addonOf(name)
            if not a then return nil end
            return a.metaLower[tostring(variable):lower()]
        end,
        IsAddOnLoaded = function(name)
            local a = addonOf(name)
            local loaded = a ~= nil and a.loaded == true
            return loaded, loaded
        end,
        GetNumAddOns = function() return #m.addonOrder end,
        GetAddOnInfo = function(name)
            local a = addonOf(name)
            if not a then return nil, nil, nil, false, "MISSING", "INSECURE" end
            return a.name, a.metaLower.title or a.name, a.metaLower.notes or "", true, nil, "INSECURE"
        end,
        IsAddOnLoadOnDemand = function(name)
            local a = addonOf(name)
            return a ~= nil and a.metaLower.loadondemand == "1"
        end,
        GetAddOnEnableState = function(name)
            return addonOf(name) and 2 or 0
        end,
        LoadAddOn = function(name)
            local a = addonOf(name)
            if not a then return false, "MISSING" end
            return true, nil
        end,
    })

    -- slash commands
    m:Provide("SlashCmdList", {})
    m:Provide("hash_SlashCmdList", {})

    -- static popups
    m:Provide("StaticPopupDialogs", {})
    m:Provide("StaticPopup_Show", function(which, text1, text2, data, insertedFrame)
        local info = rawget(m.env, "StaticPopupDialogs")[which]
        if not info then return nil end
        for _, p in ipairs(m.popups) do
            if p.which == which then return p.dialog end
        end
        local dialog = m.env.CreateFrame("Frame", nil, m.env.UIParent)
        dialog.which, dialog.data = which, data
        local p = { which = which, info = info, dialog = dialog, data = data, text1 = text1, text2 = text2,
            insertedFrame = insertedFrame }
        m.popups[#m.popups + 1] = p
        m:_action("StaticPopup_Show", which)
        if info.OnShow then m:_safecall(info.OnShow, dialog, data) end
        return dialog
    end)
    m:Provide("StaticPopup_Hide", function(which, data)
        for i = #m.popups, 1, -1 do
            local p = m.popups[i]
            if p.which == which and (data == nil or p.data == data) then
                table.remove(m.popups, i)
                if p.info.OnHide then m:_safecall(p.info.OnHide, p.dialog, p.data) end
            end
        end
    end)
    m:Provide("StaticPopup_Visible", function(which)
        for i, p in ipairs(m.popups) do
            if p.which == which then return "StaticPopup" .. i, p.dialog end
        end
        return nil
    end)

    -- Settings (Blizzard_Settings_Shared/Blizzard_Settings.lua; canvas + vertical layouts)
    local idCounter = 0
    local function newCategory(name, frame, parent)
        idCounter = idCounter + 1
        local cat = { ID = idCounter, name = name, frame = frame, parent = parent, subcategories = {} }
        function cat.GetID(self) return self.ID end
        function cat.GetName(self) return self.name end
        function cat.SetName(self, n) self.name = n end
        function cat.GetParentCategory(self) return self.parent end
        function cat.GetOrder(self) return self.ID end
        m.settingsCategories[cat.ID] = cat
        if parent then parent.subcategories[#parent.subcategories + 1] = cat end
        return cat
    end
    m:Provide("Settings", {
        RegisterCanvasLayoutCategory = function(frame, name)
            if type(frame) ~= "table" or type(name) ~= "string" then
                m:_violation("Settings.RegisterCanvasLayoutCategory(frame, name): bad arguments", 2)
            end
            return newCategory(name, frame), {}
        end,
        RegisterCanvasLayoutSubcategory = function(parent, frame, name)
            if type(parent) ~= "table" or type(frame) ~= "table" or type(name) ~= "string" then
                m:_violation("Settings.RegisterCanvasLayoutSubcategory(parent, frame, name): bad arguments", 2)
            end
            return newCategory(name, frame, parent), {}
        end,
        RegisterVerticalLayoutCategory = function(name)
            return newCategory(name), {}
        end,
        RegisterVerticalLayoutSubcategory = function(parent, name)
            return newCategory(name, nil, parent), {}
        end,
        RegisterAddOnCategory = function(category)
            if type(category) ~= "table" or not m.settingsCategories[category.ID] then
                m:_violation("Settings.RegisterAddOnCategory: not a category created by Settings.Register*Category", 2)
            end
            category.registered = true
        end,
        GetCategory = function(id) return m.settingsCategories[id] end,
        OpenToCategory = function(categoryID)
            local cat = m.settingsCategories[categoryID]
            if type(categoryID) ~= "number" then
                m:_warn("Settings.OpenToCategory expects a category ID (number), got " .. type(categoryID))
            end
            m:_action("Settings.OpenToCategory", categoryID)
            m.settingsOpened = categoryID
            if cat and cat.frame and cat.frame.Show then
                local ok = pcall(cat.frame.Show, cat.frame)
                if not ok then m:_warn("Settings.OpenToCategory: cannot show the category frame") end
            end
            return cat ~= nil
        end,
    })

    -- modifier keys / combat
    m:ProvideAPI("IsShiftKeyDown", function() return m.player.shift == true end)
    m:ProvideAPI("IsControlKeyDown", function() return m.player.ctrl == true end)
    m:ProvideAPI("IsAltKeyDown", function() return m.player.alt == true end)
    m:ProvideAPI("IsModifierKeyDown", function()
        return m.player.shift == true or m.player.ctrl == true or m.player.alt == true
    end)
    m:ProvideAPI("InCombatLockdown", function() return m.player.inCombat == true end)

    -- sound (no-op)
    m:ProvideAPI("PlaySound", function() return true, 1 end)
    m:Provide("SOUNDKIT", setmetatable({}, { __index = function() return 1 end }))
end)

---------------------------------------------------------------------------
-- secret values
---------------------------------------------------------------------------

local secretMeta = {}
local function secretOp() error("attempt to perform an operation on a secret value", 2) end
for _, k in ipairs({ "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm", "__concat",
    "__lt", "__le", "__len", "__call", "__index", "__newindex" }) do
    secretMeta[k] = secretOp
end
secretMeta.__tostring = function() return "<secret>" end

--- A value that behaves like a client secret value: issecretvalue() is true and
-- any arithmetic / concatenation / comparison / indexing raises.
function M:MakeSecret()
    local p = newproxy(true)
    local mt = getmetatable(p)
    for k, v in pairs(secretMeta) do mt[k] = v end
    self._secrets = self._secrets or setmetatable({}, { __mode = "k" })
    self._secrets[p] = true
    return p
end

function M:IsSecret(v)
    return self._secrets ~= nil and self._secrets[v] == true
end
