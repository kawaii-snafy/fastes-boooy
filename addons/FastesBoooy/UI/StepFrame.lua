-- FastesBoooy / UI / StepFrame.lua
--
-- The guide window: route + segment title, player level / XP, the current step
-- (lines from ns.Steps:Describe), the "along the way" background steps and the
-- next N steps (dimmed), footer buttons Back / Next / Skip / Settings.
--
-- Also defines the small shared UI toolkit (ns.UI) used by UI/Arrow.lua and
-- UI/Options.lua: locale proxy, settings setter (fires SETTINGS_CHANGED), frame
-- position save/restore, guide visibility / combat state.
--
-- Consumes only the internal core contract: ns.Engine, ns.Steps, ns.Schema,
-- ns.Compat (player level/XP), ns.db, ns:Listen, ns:On. Frames are created
-- lazily on DB_READY; no frame is created per refresh (rows are pooled).

-- luacheck: ignore 212/self (singleton modules keep the colon method style)

local _, ns = ...

local UI = ns.UI or {}
ns.UI = UI

local type, ipairs, tostring, tonumber = type, ipairs, tostring, tonumber
local format, floor, max, min = string.format, math.floor, math.max, math.min

---------------------------------------------------------------------------
-- shared UI toolkit
---------------------------------------------------------------------------

-- Locale proxy: resolved lazily so it works whatever the moment Init builds ns.L.
local L = setmetatable({}, {
    __index = function(_, key)
        local t = ns.L
        local v = t and t[key]
        if v == nil then return key end
        return v
    end,
})
UI.L = L

local EMPTY = {}

--- Account settings table (never nil).
function UI.Settings()
    local db = ns.db
    return (db and db.settings) or EMPTY
end

--- Change one account setting and notify every module:
-- fires ns:Fire("SETTINGS_CHANGED", key, value) (UI frames re-apply scale/lock/
-- visibility, Core/Waypoint.lua syncs the Blizzard waypoint; the engine and the
-- automation read ns.db.settings at use time).
function UI.SetSetting(key, value)
    local db = ns.db
    if not db then return false end
    db.settings = db.settings or {}
    if db.settings[key] == value then return false end
    db.settings[key] = value
    if key == "debug" then
        db.debug = value -- ns.IsDebug() reads ns.db.debug or ns.db.settings.debug
    end
    if ns.Fire then ns:Fire("SETTINGS_CHANGED", key, value) end
    return true
end

--- Localized text from a route text value ("str" or {ru=, en=}).
function UI.Text(t)
    if t == nil then return nil end
    local Schema = ns.Schema
    if Schema and Schema.Text then return Schema.Text(t, ns.locale) end
    if type(t) == "string" then return t end
    return tostring(t)
end

local function framesDB(key)
    local db = ns.db
    if not db then return nil end
    db.frames = db.frames or {}
    local t = db.frames[key]
    if type(t) ~= "table" then
        t = {}
        db.frames[key] = t
    end
    return t
end
UI.FramesDB = framesDB

--- Restore a frame position from ns.db.frames[key]. Accepts the named form
-- { point=, relativePoint=, x=, y= } (what SavePosition writes) and the array
-- form { point, relativePoint, x, y } (core defaults may use it).
function UI.RestorePosition(frame, key, defPoint, defRelPoint, defX, defY)
    local t = framesDB(key) or EMPTY
    local point = t.point or t[1]
    local relPoint = t.relativePoint or t.relPoint or t[2]
    local x = tonumber(t.x or t[3])
    local y = tonumber(t.y or t[4])
    if type(point) ~= "string" or type(relPoint) ~= "string" or not x or not y then
        point, relPoint, x, y = defPoint, defRelPoint, defX, defY
    end
    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, relPoint, x, y)
end

function UI.SavePosition(frame, key)
    local t = framesDB(key)
    if not t then return end
    local point, _, relPoint, x, y = frame:GetPoint(1)
    if not point then return end
    t.point, t.relativePoint = point, relPoint or point
    t.x, t.y = floor((x or 0) + 0.5), floor((y or 0) + 0.5)
    t[1], t[2], t[3], t[4] = nil, nil, nil, nil
end

--- Make a frame draggable (left button) unless settings.locked; the position
-- is saved to ns.db.frames[key] when the drag stops.
function UI.MakeMovable(frame, key)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetDontSavePosition(true) -- our SavedVariables keep the position, not layout-local.txt
    frame:SetScript("OnDragStart", function(self)
        if UI.Settings().locked then return end
        self.isMoving = true
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        if not self.isMoving then return end
        self.isMoving = false
        self:StopMovingOrSizing()
        UI.SavePosition(self, key)
    end)
end

-- guide visibility (/fb show | hide) and combat state ---------------------------

UI.inCombat = false

function UI.IsGuideHidden()
    local t = framesDB("steps")
    return t and t.hidden == true or false
end

function UI.SetGuideHidden(hidden)
    local t = framesDB("steps")
    if not t then return end
    t.hidden = hidden and true or nil
    if ns.Fire then ns:Fire("UI_VISIBILITY_CHANGED", not hidden) end
end

--- true when the guide frames must be hidden right now (user hid them, or
-- "hide in combat" while in combat).
function UI.ShouldHide()
    if UI.IsGuideHidden() then return true end
    if UI.Settings().hideInCombat and UI.inCombat then return true end
    return false
end

function UI.ShowTooltip(owner, title, lines, anchor)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
    GameTooltip:SetText(title or "", 1, 0.82, 0, 1, true)
    for _, line in ipairs(lines or EMPTY) do
        if type(line) == "table" then
            GameTooltip:AddLine(line[1], line[2] or 1, line[3] or 1, line[4] or 1, true)
        elseif line then
            GameTooltip:AddLine(line, 1, 1, 1, true)
        end
    end
    GameTooltip:Show()
end

function UI.HideTooltip()
    if GameTooltip then GameTooltip:Hide() end
end

local BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
UI.BACKDROP = BACKDROP

--- Create a frame with a dark tooltip-like backdrop (BackdropTemplate exists in
-- Forever: Blizzard_SharedXML/Backdrop.xml). Falls back to a color texture.
function UI.CreatePanel(frameType, name, parent)
    local f = CreateFrame(frameType or "Frame", name, parent or UIParent, "BackdropTemplate")
    if f.SetBackdrop then
        f:SetBackdrop(BACKDROP)
        f:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
        f:SetBackdropBorderColor(0.45, 0.45, 0.5, 0.9)
    else
        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(f)
        bg:SetColorTexture(0.05, 0.05, 0.08, 0.85)
    end
    return f
end

--- UIPanelButtonTemplate button with small font and a tooltip.
function UI.CreateButton(parent, text, tooltip, onClick, width, height)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 80, height or 20)
    b:SetNormalFontObject("GameFontNormalSmall")
    b:SetHighlightFontObject("GameFontHighlightSmall")
    b:SetDisabledFontObject("GameFontDisableSmall")
    b:SetText(text or "")
    b:SetScript("OnClick", onClick)
    if tooltip then
        -- UIPanelButtonMixin:OnEnter shows self.tooltipText; add our own handler
        -- only when the template did not install one.
        b.tooltipText = tooltip
        if not b:GetScript("OnEnter") then
            b:SetScript("OnEnter", function(self) UI.ShowTooltip(self, self.tooltipText) end)
            b:SetScript("OnLeave", UI.HideTooltip)
        end
    end
    return b
end

---------------------------------------------------------------------------
-- player level / XP (through ns.Compat: the only module calling unit APIs)
---------------------------------------------------------------------------

--- @return level, xp, xpMax (xp/xpMax nil when unknown or at the level cap)
local function playerLevelXP()
    local C = ns.Compat
    if not (C and C.PlayerFacts) then return nil end
    local facts = C.PlayerFacts() -- Core/Compat.lua: { level, xp, xpMax, maxLevel, ... }
    if type(facts) ~= "table" then return nil end
    local level, xp, xpMax = tonumber(facts.level), tonumber(facts.xp), tonumber(facts.xpMax)
    local cap = tonumber(facts.maxLevel)
    if level and cap and level >= cap then xp, xpMax = nil, nil end
    return level, xp, xpMax
end

---------------------------------------------------------------------------
-- step frame
---------------------------------------------------------------------------

local SF = {}
UI.StepFrame = SF

local WIDTH = 300
local PAD = 8
local ICON = 14
local INDENT = 14
local ROW_GAP = 2
local SECTION_GAP = 6
local HEADER_H = 34
local FOOTER_H = 22
local REFRESH_INTERVAL = 1

local COLORS = {
    current = { 1, 1, 1 },
    done = { 0.45, 0.9, 0.45 },
    objective = { 0.85, 0.85, 0.85 },
    note = { 1, 0.82, 0 },
    bg = { 0.95, 0.9, 0.65 },
    upcoming = { 0.6, 0.6, 0.6 },
    section = { 1, 0.82, 0 },
    message = { 0.9, 0.9, 0.9 },
}

local DONE_ATLAS = "UI-QuestTracker-Tracker-Check"

local frame -- created on DB_READY
local rows = {}
local rowsUsed = 0

local function stepTooltip(row)
    local step = row.step
    if not step then return end
    local title, lines = nil, {}
    local described = ns.Steps and ns.Steps.Describe and ns.Steps:Describe(step) or EMPTY
    for _, line in ipairs(described) do
        if line.text and line.kind ~= "note" then
            if not title then
                title = line.text
            else
                local c = line.done and COLORS.done or COLORS.objective
                lines[#lines + 1] = { line.text, c[1], c[2], c[3] }
            end
        end
    end
    local note = UI.Text(step.note)
    if note and note ~= "" then
        lines[#lines + 1] = { note, COLORS.note[1], COLORS.note[2], COLORS.note[3] }
    end
    local route = ns.Engine and ns.Engine:GetRoute()
    local seg = route and route.segmentById and step.segment and route.segmentById[step.segment]
    if seg and seg.title then
        lines[#lines + 1] = { format(L.UI_TT_SEGMENT_FMT, UI.Text(seg.title) or ""), 0.6, 0.6, 0.6 }
    end
    if UI.Settings().debug and step.id then
        lines[#lines + 1] = { format(L.UI_TT_STEP_ID_FMT, tostring(step.id)), 0.5, 0.5, 0.5 }
    end
    UI.ShowTooltip(row, title or format(L.UI_STEP_FALLBACK_FMT, tostring(step.id)), lines, "ANCHOR_LEFT")
end

local function acquireRow()
    rowsUsed = rowsUsed + 1
    local row = rows[rowsUsed]
    if not row then
        row = CreateFrame("Frame", nil, frame)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(ICON, ICON)
        row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("TOPLEFT", row, "TOPLEFT", ICON + 4, -1)
        row.text:SetJustifyH("LEFT")
        row.text:SetJustifyV("TOP")
        row.text:SetWordWrap(true)
        -- motion only: OnEnter/OnLeave for the tooltip, clicks/drags go to the window
        row:EnableMouseMotion(true)
        row:SetScript("OnEnter", stepTooltip)
        row:SetScript("OnLeave", UI.HideTooltip)
        rows[rowsUsed] = row
    end
    return row
end

-- Lays out one row at vertical offset y (positive, from the top of the frame).
-- @return new y
local function addRow(y, text, opts)
    local row = acquireRow()
    local indent = opts.indent or 0
    local width = WIDTH - 2 * PAD - indent
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + indent, -y)
    row.step = opts.step

    local icon = row.icon
    local hasIcon = opts.icon ~= nil
    if hasIcon then
        -- Pooled rows switch between atlases and plain textures: both SetAtlas and
        -- SetTexture keep the previous tex coords, so reset them explicitly (as
        -- Forever's ItemButtonTemplate does) or item icons draw an atlas crop.
        if opts.isAtlas then
            icon:SetAtlas(opts.icon, false, nil, true) -- useAtlasSize, filterMode, resetTexCoords
        else
            icon:SetTexture(opts.icon)
            icon:SetTexCoord(0, 1, 0, 1)
        end
        icon:SetDesaturated(opts.desaturate and true or false)
        icon:SetAlpha(opts.alpha or 1)
        icon:Show()
    else
        icon:Hide()
    end

    local fs = row.text
    fs:ClearAllPoints()
    local textX = (hasIcon or opts.iconSpace) and (ICON + 4) or 0
    fs:SetPoint("TOPLEFT", row, "TOPLEFT", textX, -1)
    fs:SetFontObject(opts.font or "GameFontHighlightSmall")
    fs:SetWidth(width - textX)
    fs:SetMaxLines(opts.maxLines or 0)
    fs:SetText(text or "")
    local c = opts.color or COLORS.current
    fs:SetTextColor(c[1], c[2], c[3], opts.alpha or 1)

    local h = max(hasIcon and ICON or 0, (fs:GetStringHeight() or 12) + 2)
    row:SetSize(width, h)
    row:Show()
    return y + h + ROW_GAP
end

-- Adds the Describe() lines of one step.
-- mode: "current" | "bg" | "upcoming"
local function addStep(y, step, mode)
    local lines = ns.Steps and ns.Steps.Describe and ns.Steps:Describe(step)
    if type(lines) ~= "table" or #lines == 0 then
        lines = { { text = format(L.UI_STEP_FALLBACK_FMT, tostring(step.id)), kind = "note" } }
    end
    local upcoming = mode == "upcoming"
    local shown = 0
    for _, line in ipairs(lines) do
        local kind = line.kind
        -- upcoming steps are a compact preview: no objective/note lines (they are in the tooltip)
        local skip = upcoming and shown > 0 and (kind == "objective" or kind == "note" or kind == "spells")
        if not skip and line.text then
            local color
            if line.done then
                color = COLORS.done
            elseif upcoming then
                color = COLORS.upcoming
            elseif kind == "note" then
                color = COLORS.note
            elseif kind == "objective" then
                color = COLORS.objective
            elseif mode == "bg" then
                color = COLORS.bg
            else
                color = COLORS.current
            end
            local icon, isAtlas = line.icon, line.isAtlas
            if line.done and kind ~= "note" then
                icon, isAtlas = DONE_ATLAS, true
            end
            y = addRow(y, line.text, {
                step = step,
                icon = icon,
                isAtlas = isAtlas,
                iconSpace = true,
                indent = (kind == "objective") and INDENT or 0,
                color = color,
                alpha = upcoming and 0.85 or 1,
                desaturate = upcoming,
                font = (mode == "current" and kind ~= "objective" and kind ~= "note")
                    and "GameFontHighlight" or "GameFontHighlightSmall",
                maxLines = upcoming and 2 or ((kind == "note") and 6 or 0),
            })
            shown = shown + 1
        end
    end
    return y
end

local function addSection(y, text)
    return addRow(y + SECTION_GAP - ROW_GAP, text, { color = COLORS.section, font = "GameFontNormalSmall" })
end

local function updateHeader(route, steps, cursor)
    local title = route and UI.Text(route.title) or L.UI_TITLE
    frame.title:SetText(title or "")

    local segText = ""
    local step = cursor and steps and steps[cursor]
    if route and step and route.segmentById and step.segment then
        local seg = route.segmentById[step.segment]
        segText = seg and UI.Text(seg.title) or ""
    end
    frame.segment:SetText(segText)

    local total = steps and #steps or 0
    if route and total > 0 then
        frame.progress:SetText(format(L.UI_PROGRESS_FMT, cursor or total, total))
    else
        frame.progress:SetText("")
    end

    local level, xp, xpMax = playerLevelXP()
    if level and xp and xpMax and xpMax > 0 then
        frame.level:SetText(format(L.UI_LEVEL_FMT, level, floor(xp / xpMax * 100)))
    elseif level then
        frame.level:SetText(format(L.UI_LEVEL_MAX_FMT, level))
    else
        frame.level:SetText("")
    end
end

local function updateButtons(route, steps, cursor)
    local hasSteps = route and steps and #steps > 0
    frame.prevButton:SetEnabled(hasSteps and (cursor == nil or cursor > 1) and true or false)
    frame.nextButton:SetEnabled(hasSteps and cursor ~= nil and true or false)
    frame.skipButton:SetEnabled(hasSteps and cursor ~= nil and true or false)
end

--- Rebuild the window contents from the engine state.
function SF:Refresh()
    if not frame then return end
    self.dirty = false
    frame.elapsed = 0
    rowsUsed = 0

    local E = ns.Engine
    local route = E and E:GetRoute()
    local steps = route and E:GetSteps() or nil
    local cursor = route and E:GetCursor() or nil

    updateHeader(route, steps, cursor)
    updateButtons(route, steps, cursor)

    local y = HEADER_H + PAD
    if not route then
        y = addRow(y, L.UI_NO_ROUTE, { color = COLORS.message })
    else
        local current = E:GetCurrentStep()
        if current then
            y = addStep(y, current, "current")
        else
            y = addRow(y, L.UI_ROUTE_COMPLETE, { color = COLORS.done, font = "GameFontHighlight" })
        end

        local bg = E:GetBackground()
        if type(bg) == "table" and #bg > 0 then
            y = addSection(y, L.UI_ALONG_THE_WAY)
            for _, s in ipairs(bg) do
                if s ~= current then y = addStep(y, s, "bg") end
            end
        end

        local n = tonumber(UI.Settings().shownNext) or 0
        if n > 0 and current then
            local upcoming = E:GetUpcoming(min(n, 20))
            if type(upcoming) == "table" and #upcoming > 0 then
                y = addSection(y, L.UI_UPCOMING)
                for _, s in ipairs(upcoming) do
                    y = addStep(y, s, "upcoming")
                end
            end
        end
    end

    for i = rowsUsed + 1, #rows do
        rows[i]:Hide()
        rows[i].step = nil
    end

    frame:SetHeight(floor(y + SECTION_GAP + FOOTER_H + PAD + 0.5))
end

--- Request a refresh on the next frame (coalesces bursts of events; a hidden
-- frame gets no OnUpdate and refreshes in OnShow instead).
function SF:MarkDirty()
    self.dirty = true
end

function SF:UpdateVisibility()
    if not frame then return end
    local hide = UI.ShouldHide()
    if hide then
        frame:Hide()
    else
        if not frame:IsShown() then frame:Show() end
    end
end

function SF:ApplySettings()
    if not frame then return end
    local s = UI.Settings()
    local scale = tonumber(s.frameScale) or 1
    if scale < 0.3 or scale > 3 then scale = 1 end
    frame:SetScale(scale)
    UI.RestorePosition(frame, "steps", "RIGHT", "RIGHT", -80, 60)
    self:UpdateVisibility()
    self:MarkDirty()
end

function SF:GetFrame()
    return frame
end

function SF:Create()
    if frame then return frame end
    frame = UI.CreatePanel("Frame", nil, UIParent)
    frame:SetSize(WIDTH, 120)
    frame:SetFrameStrata("MEDIUM")
    UI.MakeMovable(frame, "steps")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)
    title:SetPoint("RIGHT", frame, "RIGHT", -(PAD + 84), 0)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    frame.title = title

    local level = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    level:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -PAD - 1)
    level:SetJustifyH("RIGHT")
    frame.level = level

    local segment = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    segment:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD - 16)
    segment:SetPoint("RIGHT", frame, "RIGHT", -(PAD + 60), 0)
    segment:SetJustifyH("LEFT")
    segment:SetWordWrap(false)
    segment:SetTextColor(0.75, 0.75, 0.75)
    frame.segment = segment

    local progress = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    progress:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -PAD - 16)
    progress:SetJustifyH("RIGHT")
    progress:SetTextColor(0.75, 0.75, 0.75)
    frame.progress = progress

    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(1, 1, 1, 0.15)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -(HEADER_H + 2))
    sep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -(HEADER_H + 2))

    -- footer buttons
    local gap = 4
    local bw = floor((WIDTH - 2 * PAD - 3 * gap) / 4)
    local E = function() return ns.Engine end
    frame.prevButton = UI.CreateButton(frame, L.UI_BTN_PREV, L.UI_TT_PREV, function()
        local eng = E()
        if eng then eng:Prev() end
    end, bw, FOOTER_H)
    frame.nextButton = UI.CreateButton(frame, L.UI_BTN_NEXT, L.UI_TT_NEXT, function()
        local eng = E()
        if eng then eng:Next() end
    end, bw, FOOTER_H)
    frame.skipButton = UI.CreateButton(frame, L.UI_BTN_SKIP, L.UI_TT_SKIP, function()
        local eng = E()
        if eng then eng:Skip() end
    end, bw, FOOTER_H)
    frame.settingsButton = UI.CreateButton(frame, L.UI_BTN_SETTINGS, L.UI_TT_SETTINGS, function()
        if UI.Options and UI.Options.Open then UI.Options:Open() end
    end, bw, FOOTER_H)
    local prev
    for _, b in ipairs({ frame.prevButton, frame.nextButton, frame.skipButton, frame.settingsButton }) do
        if prev then
            b:SetPoint("LEFT", prev, "RIGHT", gap, 0)
        else
            b:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD)
        end
        prev = b
    end

    frame.elapsed = 0
    frame:SetScript("OnUpdate", function(_, elapsed)
        frame.elapsed = (frame.elapsed or 0) + (elapsed or 0)
        if SF.dirty or frame.elapsed >= REFRESH_INTERVAL then
            SF:Refresh()
        end
    end)
    frame:SetScript("OnShow", function() SF:Refresh() end)

    self:ApplySettings()
    self:Refresh()
    return frame
end

---------------------------------------------------------------------------
-- wiring
---------------------------------------------------------------------------

local function markDirty() SF:MarkDirty() end

local function onDBReady()
    UI.inCombat = InCombatLockdown() and true or false
    if frame then
        SF:ApplySettings() -- saved tables replaced the volatile defaults
    else
        SF:Create()
    end
end

ns:Listen("DB_READY", onDBReady)
ns:Listen("ROUTE_CHANGED", markDirty)
ns:Listen("STEP_CHANGED", markDirty)
ns:Listen("PROGRESS_UPDATED", markDirty)
ns:Listen("UI_VISIBILITY_CHANGED", function() SF:UpdateVisibility() end)
-- scale / hide-in-combat / shownNext / debug: re-applying everything is cheap
ns:Listen("SETTINGS_CHANGED", function() SF:ApplySettings() end)

ns:On("PLAYER_LOGIN", function()
    if frame then SF:ApplySettings() end
end)
ns:On("PLAYER_XP_UPDATE", markDirty)
ns:On("PLAYER_LEVEL_UP", markDirty)
ns:On("PLAYER_REGEN_DISABLED", function()
    UI.inCombat = true
    SF:UpdateVisibility()
end)
ns:On("PLAYER_REGEN_ENABLED", function()
    UI.inCombat = false
    SF:UpdateVisibility()
end)

-- SavedVariables already loaded (e.g. this file loaded late in tests). Before
-- ADDON_LOADED ns.db only holds volatile defaults: wait for DB_READY then.
if ns.dbReady and not frame then onDBReady() end
