-- FastesBoooy / UI / Options.lua
--
-- Settings panel (Blizzard Settings canvas category: Settings.RegisterCanvasLayoutCategory
-- + Settings.RegisterAddOnCategory, Blizzard_Settings_Shared/Blizzard_Settings.lua),
-- the quest-XP export window and the slash commands /fb, /fastesboooy.
--
-- Settings are written through ns.UI.SetSetting (fires SETTINGS_CHANGED).

-- luacheck: ignore 212/self (singleton modules keep the colon method style)

local _, ns = ...

local UI = ns.UI or {}
ns.UI = UI
local L = UI.L or setmetatable({}, { __index = function(_, k) return (ns.L and ns.L[k]) or k end })

local type, pairs, ipairs, tostring, tonumber = type, pairs, ipairs, tostring, tonumber
local format, floor, sort, concat = string.format, math.floor, table.sort, table.concat

local Options = {}
UI.Options = Options

local function S() return UI.Settings() end

local function out(msg)
    if ns.Print then
        ns.Print("%s", msg)
    else
        print(msg)
    end
end

local function versionString()
    local pub = ns.public or FastesBoooy
    return tostring((pub and pub.version) or ns.version or "?")
end

---------------------------------------------------------------------------
-- definitions
---------------------------------------------------------------------------

local CHECK_SECTIONS = {
    { title = "UI_OPT_SECTION_AUTOMATION", keys = { "automation", "autoAccept", "autoTurnin", "autoGossip" } },
    { title = "UI_OPT_SECTION_NAVIGATION", keys = { "arrow", "blizzWaypoint" } },
    { title = "UI_OPT_SECTION_WINDOW", keys = { "locked", "hideInCombat", "debug" } },
}
-- shown greyed out while the automation master switch is off
local NEEDS_AUTOMATION = { autoAccept = true, autoTurnin = true, autoGossip = true }

local RANGES = {
    { key = "lookahead", min = 0, max = 15, step = 1 },
    { key = "shownNext", min = 0, max = 10, step = 1 },
    { key = "frameScale", min = 0.5, max = 2, step = 0.05 },
    { key = "arrowScale", min = 0.5, max = 2, step = 0.05 },
}

local MAX_ROUTE_BUTTONS = 8

---------------------------------------------------------------------------
-- popups
---------------------------------------------------------------------------

local function definePopups()
    if not StaticPopupDialogs then return false end
    if not StaticPopupDialogs.FASTESBOOOY_RESET then
        StaticPopupDialogs.FASTESBOOOY_RESET = { -- luacheck: ignore 122 (FrameXML table, addons add dialogs)
            text = L.UI_POPUP_RESET,
            button1 = L.UI_YES,
            button2 = L.UI_NO,
            OnAccept = function()
                if ns.Engine then ns.Engine:Reset() end -- the engine prints the confirmation
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopupDialogs.FASTESBOOOY_XP_CLEAR = { -- luacheck: ignore 122
            text = L.UI_POPUP_XP_CLEAR,
            button1 = L.UI_YES,
            button2 = L.UI_NO,
            OnAccept = function()
                local db = ns.db
                if db and type(db.xpLog) == "table" then
                    for k in pairs(db.xpLog) do db.xpLog[k] = nil end
                    if type(db.xpLogLevel) == "table" then
                        for k in pairs(db.xpLogLevel) do db.xpLogLevel[k] = nil end
                    end
                    out(L.UI_XP_CLEARED)
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    return true
end

--- Ask for confirmation, then reset the character progress (ns.Engine:Reset()).
function Options:ConfirmReset()
    if not ns.Engine then
        out(L.UI_NO_ENGINE)
        return
    end
    if definePopups() and StaticPopup_Show then
        StaticPopup_Show("FASTESBOOOY_RESET")
    else
        ns.Engine:Reset()
    end
end

---------------------------------------------------------------------------
-- XP log export
---------------------------------------------------------------------------

local function isIdent(k)
    return type(k) == "string" and k:match("^[%a_][%w_]*$") ~= nil
end

local function serialize(v, depth)
    local tv = type(v)
    if tv == "number" or tv == "boolean" then return tostring(v) end
    if tv == "string" then return format("%q", v) end
    if tv == "table" and (depth or 0) < 3 then
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        local parts = {}
        for _, k in ipairs(keys) do
            local key = isIdent(k) and k or ("[" .. serialize(k, 3) .. "]")
            parts[#parts + 1] = key .. " = " .. serialize(v[k], (depth or 0) + 1)
        end
        return "{ " .. concat(parts, ", ") .. " }"
    end
    return "nil"
end

local function xpValue(v)
    if type(v) == "number" then return v end
    if type(v) == "table" then return tonumber(v.xp or v.xpReward or v[1]) end
    return nil
end

--- Sorted XP log entries: array of { quest = id, xp = number|nil, level = number|nil, value = raw }.
-- ns.db.xpLog[questID] = xp reward seen in game; ns.db.xpLogLevel[questID] =
-- player level at that turn-in (Core/Init.lua defaults).
local function xpEntries()
    local db = ns.db
    local log = db and db.xpLog
    local levels = db and type(db.xpLogLevel) == "table" and db.xpLogLevel or {}
    local list = {}
    if type(log) ~= "table" then return list end
    for q, v in pairs(log) do
        local id = tonumber(q)
        if id then
            local level = tonumber(levels[q])
            if not level and type(v) == "table" then level = tonumber(v.level) end
            list[#list + 1] = { quest = id, value = v, xp = xpValue(v), level = level }
        end
    end
    sort(list, function(a, b) return a.quest < b.quest end)
    return list
end

local function xpTotal(list)
    local total = 0
    for _, e in ipairs(list) do total = total + (e.xp or 0) end
    return total
end

--- Lua source of the XP log (machine readable: `return { [questID] = { xp = n, level = n } }`).
function Options:BuildXPExport()
    local list = xpEntries()
    local lines = {
        format("-- FastesBoooy %s quest XP log: %d quests, %d XP (%s)",
            versionString(), #list, xpTotal(list), date and date("%Y-%m-%d %H:%M") or ""),
        "-- [questID] = { xp = reward received at turn-in (QUEST_TURNED_IN), level = player level then }",
        "return {",
    }
    for _, e in ipairs(list) do
        local entry
        if e.xp then
            entry = e.level and format("{ xp = %d, level = %d }", e.xp, e.level) or format("{ xp = %d }", e.xp)
        else
            entry = serialize(e.value)
        end
        lines[#lines + 1] = format("    [%d] = %s,", e.quest, entry)
    end
    lines[#lines + 1] = "}"
    return concat(lines, "\n"), #list
end

local exportFrame
local function createExportFrame()
    local f = UI.CreatePanel("Frame", nil, UIParent)
    f:SetSize(440, 340)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetDontSavePosition(true)
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -10)
    title:SetText(L.UI_XP_EXPORT_TITLE)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    hint:SetText(L.UI_XP_EXPORT_HINT)
    hint:SetTextColor(0.7, 0.7, 0.7)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() f:Hide() end)

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -46)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 12)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetWidth(390)
    edit:SetScript("OnEscapePressed", function() f:Hide() end)
    -- read-only: typing restores the export text
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and f.text then
            self:SetText(f.text)
            self:HighlightText()
        end
    end)
    scroll:SetScrollChild(edit)
    f.edit = edit
    f:Hide()
    return f
end

function Options:ShowXPExport()
    local list = xpEntries()
    if #list == 0 then
        out(L.UI_XP_EMPTY)
        return
    end
    out(format(L.UI_XP_SUMMARY_FMT, #list, xpTotal(list)))
    exportFrame = exportFrame or createExportFrame()
    exportFrame.text = self:BuildXPExport()
    exportFrame.edit:SetText(exportFrame.text)
    exportFrame:Show()
    exportFrame.edit:SetFocus()
    exportFrame.edit:HighlightText()
end

function Options:PrintXP()
    local list = xpEntries()
    if #list == 0 then
        out(L.UI_XP_EMPTY)
        return
    end
    out(format(L.UI_XP_SUMMARY_FMT, #list, xpTotal(list)))
    for _, e in ipairs(list) do
        local xp = e.xp and tostring(e.xp) or serialize(e.value)
        if e.level then
            out(format(L.UI_XP_LINE_LEVEL_FMT, e.quest, xp, e.level))
        else
            out(format(L.UI_XP_LINE_FMT, e.quest, xp))
        end
    end
end

function Options:ConfirmClearXP()
    if definePopups() and StaticPopup_Show then
        StaticPopup_Show("FASTESBOOOY_XP_CLEAR")
    end
end

---------------------------------------------------------------------------
-- settings panel
---------------------------------------------------------------------------

local panel, category, holder
local checks = {}
local sliders = {}
local routeButtons = {}
local routesNote, errorsNote, routesAnchor

local function sectionTitle(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

local function createCheck(parent, key, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", cb, "RIGHT", 2, 1)
    label:SetText(L["UI_OPT_" .. key])
    cb.label = label
    cb.key = key
    cb:SetHitRectInsets(0, -220, 0, 0)
    cb:SetScript("OnClick", function(self)
        UI.SetSetting(self.key, self:GetChecked() and true or false)
        Options:Refresh()
    end)
    cb:SetScript("OnEnter", function(self)
        UI.ShowTooltip(self, L["UI_OPT_" .. self.key], { L["UI_OPT_" .. self.key .. "_TT"] })
    end)
    cb:SetScript("OnLeave", UI.HideTooltip)
    checks[key] = cb
    return cb
end

local function roundToStep(value, step)
    local v = floor(value / step + 0.5) * step
    if step < 1 then v = tonumber(format("%.2f", v)) end -- 1.15, not 1.1500000000000001
    return v
end

local function sliderLabel(def, value)
    return format(L["UI_OPT_" .. def.key], value)
end

local function createSlider(parent, def, x, y)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local s = CreateFrame("Slider", nil, parent, "UISliderTemplate")
    s:SetSize(220, 16)
    s:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
    s:SetOrientation("HORIZONTAL")
    s:SetMinMaxValues(def.min, def.max)
    s:SetValueStep(def.step)
    s:SetObeyStepOnDrag(true)
    s.def = def
    s.label = label
    s:SetScript("OnValueChanged", function(self, value)
        value = roundToStep(tonumber(value) or def.min, def.step)
        self.label:SetText(sliderLabel(def, value))
        if not self.updating then
            UI.SetSetting(def.key, value)
        end
    end)
    s:SetScript("OnEnter", function(self)
        UI.ShowTooltip(self, sliderLabel(def, roundToStep(self:GetValue() or def.min, def.step)),
            { L["UI_OPT_" .. def.key .. "_TT"] })
    end)
    s:SetScript("OnLeave", UI.HideTooltip)
    sliders[def.key] = s
    return s
end

local function routeTooltip(self)
    local r = self.route
    if not r then return end
    local lines = {}
    lines[#lines + 1] = { format(L.UI_OPT_ROUTE_ID_FMT, tostring(r.id)), 0.7, 0.7, 0.7 }
    if type(r.levels) == "table" and r.levels[1] and r.levels[2] then
        lines[#lines + 1] = format(L.UI_OPT_ROUTE_LEVELS_FMT, r.levels[1], r.levels[2])
    end
    if r.version then lines[#lines + 1] = format(L.UI_OPT_ROUTE_VERSION_FMT, tostring(r.version)) end
    if type(r.steps) == "table" then lines[#lines + 1] = format(L.UI_OPT_ROUTE_STEPS_FMT, #r.steps) end
    local desc = UI.Text(r.description)
    if desc then lines[#lines + 1] = { desc, 1, 0.82, 0 } end
    lines[#lines + 1] = { L.UI_OPT_ROUTE_CLICK, 0.5, 0.8, 1 }
    UI.ShowTooltip(self, UI.Text(r.title) or tostring(r.id), lines)
end

local function routeButton(i)
    local b = routeButtons[i]
    if b then return b end
    b = UI.CreateButton(panel, "", nil, function(self)
        if self.route and ns.Engine then
            ns.Engine:SetRoute(self.route.id)
            Options:Refresh()
        end
    end, 280, 22)
    b:HookScript("OnEnter", routeTooltip)
    b:HookScript("OnLeave", UI.HideTooltip)
    if i == 1 then
        b:SetPoint("TOPLEFT", routesAnchor, "BOTTOMLEFT", 0, -6)
    else
        b:SetPoint("TOPLEFT", routeButtons[i - 1], "BOTTOMLEFT", 0, -2)
    end
    routeButtons[i] = b
    return b
end

local function listRoutes()
    local R = ns.Registry
    local list = R and R.List and R:List()
    return type(list) == "table" and list or {}
end

local function activeRouteId()
    local route = ns.Engine and ns.Engine:GetRoute()
    return route and route.id
end

local function refreshRoutes()
    local list = listRoutes()
    local active = activeRouteId()
    local shown = 0
    for i, r in ipairs(list) do
        if i > MAX_ROUTE_BUTTONS then break end
        local b = routeButton(i)
        b.route = r
        local title = UI.Text(r.title) or tostring(r.id)
        if r.id == active then
            b:SetText(format("|cff40ff40%s|r (%s)", title, L.UI_OPT_ROUTE_ACTIVE))
        else
            b:SetText(title)
        end
        b:Show()
        shown = i
    end
    for i = shown + 1, #routeButtons do
        routeButtons[i]:Hide()
        routeButtons[i].route = nil
    end

    local last = routeButtons[shown] or routesAnchor
    routesNote:ClearAllPoints()
    routesNote:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -6)
    if #list == 0 then
        routesNote:SetText(L.UI_OPT_NO_ROUTES)
    elseif #list > MAX_ROUTE_BUTTONS then
        routesNote:SetText(format(L.UI_OPT_MORE_ROUTES_FMT, #list - MAX_ROUTE_BUTTONS))
    else
        routesNote:SetText("")
    end
    local errors = ns.Registry and ns.Registry.errors
    if type(errors) == "table" and #errors > 0 then
        errorsNote:SetText(format(L.UI_OPT_ERRORS_FMT, #errors))
    else
        errorsNote:SetText("")
    end
end

--- Sync every control with the saved settings / registry.
function Options:Refresh()
    if not panel then return end
    local s = S()
    for key, cb in pairs(checks) do
        cb:SetChecked(s[key] and true or false)
        local enabled = not (NEEDS_AUTOMATION[key] and not s.automation)
        cb:SetEnabled(enabled)
        if enabled then
            cb.label:SetTextColor(1, 1, 1)
        else
            cb.label:SetTextColor(0.5, 0.5, 0.5)
        end
    end
    for _, def in ipairs(RANGES) do
        local sl = sliders[def.key]
        local v = tonumber(s[def.key]) or def.min
        if v < def.min then v = def.min elseif v > def.max then v = def.max end
        sl.updating = true
        sl:SetValue(v)
        sl.updating = false
        sl.label:SetText(sliderLabel(def, roundToStep(v, def.step)))
    end
    refreshRoutes()
end

--- Apply the core defaults (if the core exposes them) to the settings shown here.
local function applyDefaults()
    local defaults = ns.DEFAULTS -- Core/Init.lua: ns.DEFAULTS.db.settings
    defaults = type(defaults) == "table" and type(defaults.db) == "table" and defaults.db.settings or nil
    if type(defaults) ~= "table" then return end
    for _, sec in ipairs(CHECK_SECTIONS) do
        for _, key in ipairs(sec.keys) do
            if defaults[key] ~= nil then UI.SetSetting(key, defaults[key]) end
        end
    end
    for _, def in ipairs(RANGES) do
        if defaults[def.key] ~= nil then UI.SetSetting(def.key, defaults[def.key]) end
    end
    Options:Refresh()
end

function Options:Build()
    if panel then return panel end
    panel = CreateFrame("Frame")
    panel:Hide()
    panel.name = L.UI_TITLE

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    title:SetText(L.UI_TITLE .. " " .. versionString())

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText(L.UI_OPT_SUBTITLE .. " " .. L.UI_OPT_HINT)

    -- left column: checkboxes
    local x, y = 16, -72
    for _, sec in ipairs(CHECK_SECTIONS) do
        sectionTitle(panel, L[sec.title], x, y)
        y = y - 22
        for _, key in ipairs(sec.keys) do
            createCheck(panel, key, x + (NEEDS_AUTOMATION[key] and 16 or 0), y)
            y = y - 26
        end
        y = y - 10
    end

    -- left column bottom: action buttons
    local resetBtn = UI.CreateButton(panel, L.UI_OPT_RESET, L.UI_OPT_RESET_TT,
        function() Options:ConfirmReset() end, 180, 22)
    resetBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y - 4)
    local toggleBtn = UI.CreateButton(panel, L.UI_OPT_TOGGLE_FRAME, nil, function()
        UI.SetGuideHidden(not UI.IsGuideHidden())
    end, 180, 22)
    toggleBtn:SetPoint("TOPLEFT", resetBtn, "BOTTOMLEFT", 0, -4)
    local xpBtn = UI.CreateButton(panel, L.UI_OPT_EXPORT_XP, L.UI_OPT_EXPORT_XP_TT,
        function() Options:ShowXPExport() end, 180, 22)
    xpBtn:SetPoint("TOPLEFT", toggleBtn, "BOTTOMLEFT", 0, -4)

    -- right column: sliders, then routes
    local rx, ry = 330, -72
    sectionTitle(panel, L.UI_OPT_SECTION_DISPLAY, rx, ry)
    ry = ry - 28
    for _, def in ipairs(RANGES) do
        createSlider(panel, def, rx, ry)
        ry = ry - 50
    end
    routesAnchor = sectionTitle(panel, L.UI_OPT_SECTION_ROUTES, rx, ry - 6)
    routesNote = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    routesNote:SetWidth(280)
    routesNote:SetJustifyH("LEFT")
    errorsNote = panel:CreateFontString(nil, "ARTWORK", "GameFontRed")
    errorsNote:SetPoint("TOPLEFT", routesNote, "BOTTOMLEFT", 0, -4)
    errorsNote:SetWidth(280)
    errorsNote:SetJustifyH("LEFT")

    -- Settings canvas callbacks (Blizzard_SettingsPanel.lua calls these if present)
    panel.OnRefresh = function() Options:Refresh() end
    panel.OnDefault = applyDefaults
    panel.OnCommit = function() end
    panel:SetScript("OnShow", function() Options:Refresh() end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        category = Settings.RegisterCanvasLayoutCategory(panel, L.UI_TITLE)
        if category then Settings.RegisterAddOnCategory(category) end
    end
    return panel
end

-- Fallback when the Settings API is unavailable: the panel in its own window.
local function showStandalone()
    if not holder then
        holder = UI.CreatePanel("Frame", nil, UIParent)
        holder:SetSize(660, 580)
        holder:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        holder:SetFrameStrata("DIALOG")
        holder:SetMovable(true)
        holder:SetClampedToScreen(true)
        holder:EnableMouse(true)
        holder:RegisterForDrag("LeftButton")
        holder:SetDontSavePosition(true)
        holder:SetScript("OnDragStart", function(self) self:StartMoving() end)
        holder:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        local close = CreateFrame("Button", nil, holder, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", holder, "TOPRIGHT", -2, -2)
        close:SetScript("OnClick", function() holder:Hide() end)
        panel:SetParent(holder)
        panel:ClearAllPoints()
        panel:SetAllPoints(holder)
        holder:Hide()
    end
    if holder:IsShown() then
        holder:Hide()
    else
        holder:Show()
        panel:Show()
        Options:Refresh()
    end
end

--- Open the settings (Blizzard Settings panel, AddOns tab).
function Options:Open()
    if InCombatLockdown() then
        out(L.UI_NOT_IN_COMBAT)
        return
    end
    self:Build()
    if category and Settings and Settings.OpenToCategory then
        local id = category.GetID and category:GetID() or category.ID
        Settings.OpenToCategory(id)
        self:Refresh()
        return
    end
    showStandalone()
end

function Options:GetPanel()
    return panel
end

function Options:GetCategory()
    return category
end

--- Standalone options window (only when the Settings API is missing) / XP export window.
function Options:GetWindow()
    return holder
end

function Options:GetExportFrame()
    return exportFrame
end

---------------------------------------------------------------------------
-- slash commands
---------------------------------------------------------------------------

local function needDB()
    if not ns.db or ns.dbReady == false then
        out(L.UI_DB_NOT_READY)
        return false
    end
    return true
end

local function needEngine()
    if not ns.Engine then
        out(L.UI_NO_ENGINE)
        return false
    end
    return true
end

local function printHelp()
    out(L.UI_HELP_HEADER)
    for _, k in ipairs({ "show", "lock", "next", "reset", "routes", "route", "config", "status", "xp", "debug" }) do
        out(L["UI_HELP_" .. k])
    end
end

local function printRoutes()
    local list = listRoutes()
    local active = activeRouteId()
    if #list == 0 then
        out(L.UI_ROUTES_NONE)
    else
        out(L.UI_ROUTES_HEADER)
        for _, r in ipairs(list) do
            out(format(L.UI_ROUTE_LINE_FMT, r.id == active and "*" or "-", tostring(r.id),
                UI.Text(r.title) or ""))
        end
    end
    local errors = ns.Registry and ns.Registry.errors
    if type(errors) == "table" and #errors > 0 then
        out(format(L.UI_REGISTRY_ERRORS_FMT, #errors))
        for i, e in ipairs(errors) do
            if i > 10 then break end
            out("  " .. tostring(e))
        end
    end
end

local function stepLabel(step)
    local St = ns.Steps
    if St and St.Label then
        local label = St:Label(step)
        if label then return label end
    end
    local lines = St and St.Describe and St:Describe(step)
    local l1 = type(lines) == "table" and lines[1]
    return (l1 and l1.text) or tostring(step and step.id)
end

local function printStatus()
    local pub = ns.public or FastesBoooy
    out(format(L.UI_STATUS_VERSION_FMT, versionString(), tostring(pub and pub.API_VERSION or "?")))
    local E = ns.Engine
    local route = E and E:GetRoute()
    if not route then
        out(L.UI_STATUS_NO_ROUTE)
    else
        out(format(L.UI_STATUS_ROUTE_FMT, UI.Text(route.title) or "", tostring(route.id)))
        local steps = E:GetSteps() or {}
        local cursor = E:GetCursor()
        local step = E:GetCurrentStep()
        if cursor and step then
            out(format(L.UI_STATUS_STEP_FMT, cursor, #steps, stepLabel(step)))
        else
            out(L.UI_STATUS_FINISHED)
        end
        local bg = E:GetBackground()
        if type(bg) == "table" and #bg > 0 then out(format(L.UI_STATUS_BG_FMT, #bg)) end
    end
    local auto
    if not S().automation then
        auto = L.UI_OFF
    elseif ns.Automation and ns.Automation.IsSuspended and ns.Automation:IsSuspended() then
        auto = L.UI_PAUSED
    else
        auto = L.UI_ON
    end
    out(format(L.UI_STATUS_AUTOMATION_FMT, auto))
    local t = ns.Waypoint and ns.Waypoint.GetTarget and ns.Waypoint:GetTarget()
    if type(t) == "table" then
        local d = tonumber(t.distance)
        out(format(L.UI_STATUS_WAYPOINT_FMT, tostring(t.label or "?"),
            d and format(L.UI_YARDS_FMT, floor(d + 0.5)) or L.UI_UNKNOWN))
    else
        out(L.UI_STATUS_NO_WAYPOINT)
    end
    out(format(L.UI_STATUS_XP_FMT, #xpEntries()))
end

local COMMANDS = {}

COMMANDS.help = printHelp
COMMANDS["?"] = printHelp
COMMANDS.show = function()
    UI.SetGuideHidden(false)
    out(L.UI_SHOWN)
end
COMMANDS.hide = function()
    UI.SetGuideHidden(true)
    out(L.UI_HIDDEN)
end
COMMANDS.toggle = function()
    if UI.IsGuideHidden() then COMMANDS.show() else COMMANDS.hide() end
end
COMMANDS.lock = function()
    UI.SetSetting("locked", true)
    Options:Refresh()
    out(L.UI_LOCKED)
end
COMMANDS.unlock = function()
    UI.SetSetting("locked", false)
    Options:Refresh()
    out(L.UI_UNLOCKED)
end
COMMANDS.next = function() if needEngine() then ns.Engine:Next() end end
COMMANDS.prev = function() if needEngine() then ns.Engine:Prev() end end
COMMANDS.back = COMMANDS.prev
COMMANDS.skip = function() if needEngine() then ns.Engine:Skip() end end
COMMANDS.reset = function() Options:ConfirmReset() end
COMMANDS.routes = printRoutes
COMMANDS.route = function(arg)
    if not needEngine() then return end
    if not arg or arg == "" then
        out(L.UI_ROUTE_USAGE)
        return
    end
    local R = ns.Registry
    local route = R and R.Get and R:Get(arg)
    if not route then
        out(format(L.UI_ROUTE_UNKNOWN_FMT, arg))
        return
    end
    local before = ns.Engine:GetRoute()
    local ok = ns.Engine:SetRoute(route.id)
    Options:Refresh()
    -- the engine announces a route change itself; confirm only when nothing changed
    if ok ~= false and ns.Engine:GetRoute() == before then
        out(format(L.UI_ROUTE_SET_FMT, UI.Text(route.title) or tostring(route.id)))
    end
end
COMMANDS.config = function() Options:Open() end
COMMANDS.options = COMMANDS.config
COMMANDS.settings = COMMANDS.config
COMMANDS.status = printStatus
COMMANDS.xp = function(arg)
    arg = (arg or ""):lower()
    if arg == "chat" or arg == "print" then
        Options:PrintXP()
    elseif arg == "clear" then
        Options:ConfirmClearXP()
    else
        Options:ShowXPExport()
    end
end
COMMANDS.debug = function()
    local on = not S().debug
    UI.SetSetting("debug", on)
    Options:Refresh()
    out(format(L.UI_DEBUG_FMT, on and L.UI_ON or L.UI_OFF))
end

--- Slash command entry point (also used by tests).
function Options:HandleSlash(msg)
    msg = type(msg) == "string" and msg or ""
    local cmd, arg = msg:match("^%s*(%S*)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()
    if cmd == "" then cmd = "help" end
    local fn = COMMANDS[cmd]
    if not fn then
        out(format(L.UI_UNKNOWN_CMD_FMT, cmd))
        return
    end
    if cmd ~= "help" and cmd ~= "?" and not needDB() then return end
    fn(arg)
end

SLASH_FASTESBOOOY1 = "/fb"
SLASH_FASTESBOOOY2 = "/fastesboooy"
SlashCmdList.FASTESBOOOY = function(msg) Options:HandleSlash(msg) end

---------------------------------------------------------------------------
-- wiring
---------------------------------------------------------------------------

local function refreshIfShown()
    if panel and panel:IsShown() then Options:Refresh() end
end

ns:Listen("DB_READY", function() Options:Build() end)
ns:Listen("ROUTE_CHANGED", refreshIfShown)
ns:Listen("ROUTES_CHANGED", refreshIfShown)
ns:Listen("SETTINGS_CHANGED", refreshIfShown)

if ns.dbReady and not panel then Options:Build() end
