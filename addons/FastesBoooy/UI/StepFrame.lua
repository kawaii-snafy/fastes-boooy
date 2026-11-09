-- FastesBoooy / UI / StepFrame.lua
--
-- The guide window, top to bottom:
--   header      route title, player level / XP; segment title, step n/total
--   button row  Back / Forward / Settings -- FIXED offsets from the window's top edge
--   sync banner optional: "you outleveled this segment, jump?" [Jump] [Stay]
--               (ns.Engine:GetSyncSuggestion), or "jumped to X" + an Undo link for
--               UNDO_SECONDS after a level sync (until the next step change)
--   content     the current step (lines from ns.Steps:Describe), the "along the way"
--               background steps, the next N not-done steps (dimmed)
-- The window is anchored by its TOP edge (restore, drag, saved position) and only its
-- height follows the content, so it grows / shrinks downward and the buttons never move;
-- nothing in the button row is anchored to a content region.
--
-- Also defines the small shared UI toolkit (ns.UI) used by UI/Arrow.lua,
-- UI/ItemButton.lua and UI/Options.lua: locale proxy, settings setter (fires
-- SETTINGS_CHANGED), frame position save/restore, guide visibility / combat state,
-- engine actions shared with the slash commands (UI.Forward, UI.ApplySync...).
--
-- Consumes only the internal core contract: ns.Engine, ns.Steps, ns.Schema,
-- ns.Compat (player level/XP), ns.db, ns.cdb, ns:Listen, ns:On. Frames are created
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

--- The same position expressed by the frame's TOP edge: point "TOPLEFT" / "TOP" /
-- "TOPRIGHT" with the same horizontal side and relative point; `height` (frame units,
-- like the offsets) moves y from a middle (LEFT / CENTER / RIGHT) or BOTTOM* point to
-- the top edge. A frame anchored this way keeps its top edge when its height changes.
function UI.TopAnchor(point, x, y, height)
    point = tostring(point or "TOPLEFT"):upper()
    local v, side = 0.5, point
    if point:sub(1, 3) == "TOP" then
        v, side = 0, point:sub(4)
    elseif point:sub(1, 6) == "BOTTOM" then
        v, side = 1, point:sub(7)
    end
    if side == "CENTER" then side = "" end
    return "TOP" .. side, x or 0, (y or 0) + v * (tonumber(height) or 0)
end

local function isTopPoint(point)
    return type(point) == "string" and point:upper():sub(1, 3) == "TOP"
end

local function setTopPoint(frame, point, relPoint, x, y)
    local p, px, py = UI.TopAnchor(point, x, y, frame:GetHeight())
    frame:ClearAllPoints()
    frame:SetPoint(p, UIParent, relPoint or point, floor(px + 0.5), floor(py + 0.5))
    return p, floor(px + 0.5), floor(py + 0.5)
end

--- Restore a frame position from ns.db.frames[key]. Accepts the named form
-- { point=, relativePoint=, x=, y= } (what SavePosition writes) and the array
-- form { point, relativePoint, x, y } (core defaults may use it).
-- topAnchored: anchor the frame by its top edge (UI.TopAnchor with the current height);
-- a saved position of another point is converted and written back, so it does not drift with
-- the height on the next restore -- only when `final` (the frame has its real height: e.g. the
-- step window once the engine has started), else it is converted for display only and the
-- next restore converts it again.
function UI.RestorePosition(frame, key, defPoint, defRelPoint, defX, defY, topAnchored, final)
    local t = framesDB(key) or EMPTY
    local point = t.point or t[1]
    local relPoint = t.relativePoint or t.relPoint or t[2]
    local x = tonumber(t.x or t[3])
    local y = tonumber(t.y or t[4])
    if type(point) ~= "string" or type(relPoint) ~= "string" or not x or not y then
        point, relPoint, x, y = defPoint, defRelPoint, defX, defY
    end
    if topAnchored then
        local converted = not isTopPoint(point)
        local p, px, py = setTopPoint(frame, point, relPoint, x, y)
        if converted and t ~= EMPTY and final ~= false then
            t.point, t.relativePoint, t.x, t.y = p, relPoint, px, py
            t[1], t[2], t[3], t[4] = nil, nil, nil, nil
        end
        return
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
-- is saved to ns.db.frames[key] when the drag stops. topAnchored: the client re-anchors
-- a moved frame to the point nearest to it (often BOTTOM*): turn that back into a
-- top-edge anchor before saving (see UI.TopAnchor).
function UI.MakeMovable(frame, key, topAnchored)
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
    local function stopDrag(self)
        if not self.isMoving then return end
        self.isMoving = false
        self:StopMovingOrSizing()
        if topAnchored then
            local point, _, relPoint, x, y = self:GetPoint(1)
            if point then setTopPoint(self, point, relPoint, x, y) end
        end
        UI.SavePosition(self, key)
    end
    frame:SetScript("OnDragStop", stopDrag)
    -- hidden while being dragged (combat with "hide in combat", the arrow losing its target): a hidden
    -- frame gets no OnDragStop, so finish the drag here and keep the position the player chose
    frame:SetScript("OnHide", stopDrag)
end

--- Put the guide window, the arrow and the item button back to their default positions
-- (the "hidden" flag of the guide is kept). Listeners of SETTINGS_CHANGED re-apply the positions;
-- the item button does it after combat.
function UI.ResetPositions()
    local frames = ns.db and ns.db.frames
    local defaults = ns.DEFAULTS and ns.DEFAULTS.db and ns.DEFAULTS.db.frames
    if type(frames) ~= "table" or type(defaults) ~= "table" then return false end
    for key, def in pairs(defaults) do
        local t = frames[key]
        if type(t) ~= "table" then
            t = {}
            frames[key] = t
        end
        t.point, t.relativePoint, t.x, t.y = def.point, def.relativePoint, def.x, def.y
        t[1], t[2], t[3], t[4] = nil, nil, nil, nil
    end
    if ns.Fire then ns:Fire("SETTINGS_CHANGED", "frames") end
    return true
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

local function richTooltip(self)
    UI.ShowTooltip(self, self.tooltipTitle, self.tooltipLines)
end

--- UIPanelButtonTemplate button with small font and a tooltip: a string (one line,
-- shown by the template's UIPanelButtonMixin:OnEnter) or { title, { line, ... } }
-- (title + explanation lines, our own OnEnter).
function UI.CreateButton(parent, text, tooltip, onClick, width, height)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 80, height or 20)
    b:SetNormalFontObject("GameFontNormalSmall")
    b:SetHighlightFontObject("GameFontHighlightSmall")
    b:SetDisabledFontObject("GameFontDisableSmall")
    b:SetText(text or "")
    b:SetScript("OnClick", onClick)
    if type(tooltip) == "table" then
        b.tooltipTitle, b.tooltipLines = tooltip[1], tooltip[2]
        b:SetScript("OnEnter", richTooltip)
        b:SetScript("OnLeave", UI.HideTooltip)
    elseif tooltip then
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
-- engine actions shared by the buttons, the banner and the slash commands
---------------------------------------------------------------------------

--- "Forward": the step is done or not wanted -> the next one; while an earlier step is
-- shown (after Back) -> the view moves forward. ns.Engine:Forward does exactly this; the
-- fallback (an older engine) does the same with Next (moves a pinned view) / Skip.
function UI.Forward()
    local E = ns.Engine
    if not E then return false end
    if E.Forward then
        E:Forward()
    elseif E.IsPinned and E:IsPinned() then
        E:Next()
    else
        E:Skip()
    end
    return true
end

function UI.Back()
    local E = ns.Engine
    if not E then return false end
    E:Prev()
    return true
end

--- Current level-sync suggestion of the engine (nil: none, or an engine without level sync).
function UI.SyncSuggestion()
    local E = ns.Engine
    if not (E and E.GetSyncSuggestion) then return nil end
    local s = E:GetSyncSuggestion()
    return type(s) == "table" and s or nil
end

--- true when the engine supports level sync (GetSyncSuggestion / ApplySync / ...).
function UI.HasSync()
    local E = ns.Engine
    return E and E.GetSyncSuggestion and E.ApplySync and true or false
end

--- The level-sync floor of the active route (cdb.syncFloor), nil when none.
function UI.SyncFloor()
    local f = ns.cdb and ns.cdb.syncFloor
    if type(f) ~= "table" or f.stepId == nil then return nil end
    local route = ns.Engine and ns.Engine:GetRoute()
    if f.route ~= nil and route and f.route ~= route.id then return nil end
    return f
end

--- Title of a segment: a segment table, or a segment id of the active route.
function UI.SegmentTitle(seg)
    if type(seg) == "string" then
        local route = ns.Engine and ns.Engine:GetRoute()
        local s = route and route.segmentById and route.segmentById[seg]
        return s and UI.Text(s.title) or seg
    end
    if type(seg) == "table" then
        return UI.Text(seg.title) or (seg.id and tostring(seg.id)) or "?"
    end
    return "?"
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

--- Player level (nil when unknown).
function UI.PlayerLevel()
    return (playerLevelXP())
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
local BUTTON_H = 22
local BUTTON_GAP = 4
local BUTTON_Y = HEADER_H + 2            -- top of the button row, from the window's top edge
local TOP_BLOCK = BUTTON_Y + BUTTON_H + 6 -- header + buttons: what never moves
local BANNER_PAD = 5
local BANNER_BUTTON_H = 20
local REFRESH_INTERVAL = 1
local UNDO_SECONDS = 30

SF.TOP_BLOCK = TOP_BLOCK
SF.UNDO_SECONDS = UNDO_SECONDS

local COLORS = {
    current = { 1, 1, 1 },
    done = { 0.45, 0.9, 0.45 },
    objective = { 0.85, 0.85, 0.85 },
    note = { 1, 0.82, 0 },
    bg = { 0.95, 0.9, 0.65 },
    upcoming = { 0.6, 0.6, 0.6 },
    section = { 1, 0.82, 0 },
    message = { 0.9, 0.9, 0.9 },
    banner = { 1, 0.92, 0.6 },
    link = { 0.4, 0.75, 1 },
    linkHover = { 0.7, 0.9, 1 },
}

local DONE_ATLAS = "UI-QuestTracker-Tracker-Check"

local frame -- created on DB_READY
local rows = {}
local rowsUsed = 0

local function now()
    return GetTime and GetTime() or 0
end

local function stepTooltip(row)
    local step = row.step
    if not step then return end
    local title, lines = nil, {}
    local described = ns.Steps and ns.Steps.Describe and ns.Steps:Describe(step) or EMPTY
    for _, line in ipairs(described) do
        if line.text and line.kind ~= "note" and line.void ~= "floor" then
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

-- Describe() lines of one step to show in `mode` ("current" | "bg" | "upcoming").
-- Upcoming steps are a compact preview: the first line plus quest lines, no objective /
-- note / spell lines (they are in the tooltip) and nothing already done (a partly done
-- step shows only what is left).
local function stepLines(step, mode)
    local lines = ns.Steps and ns.Steps.Describe and ns.Steps:Describe(step)
    if type(lines) ~= "table" or #lines == 0 then
        lines = { { text = format(L.UI_STEP_FALLBACK_FMT, tostring(step.id)), kind = "note" } }
    end
    if mode == "bg" then
        -- a step below the level-sync floor kept as an along-the-way goal: only what is left of it
        -- (its other actions are floored -- line.void "floor", Core/Steps.lua)
        local out = {}
        for _, line in ipairs(lines) do
            if line.void ~= "floor" then out[#out + 1] = line end
        end
        return out
    end
    if mode ~= "upcoming" then return lines end
    local out = {}
    for _, line in ipairs(lines) do
        local kind = line.kind
        local detail = #out > 0 and (kind == "objective" or kind == "note" or kind == "spells")
        if line.text and not line.done and not detail then out[#out + 1] = line end
    end
    return out
end

-- Adds the lines of one step (see stepLines).
local function addStep(y, step, mode, lines)
    lines = lines or stepLines(step, mode)
    local upcoming = mode == "upcoming"
    for _, line in ipairs(lines) do
        local kind = line.kind
        if line.text then
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
                -- the current step shows its whole note: it is the instruction to follow
                maxLines = upcoming and 2 or ((kind == "note" and mode ~= "current") and 6 or 0),
            })
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
    frame.forwardButton:SetEnabled(hasSteps and cursor ~= nil and true or false)
end

-- level-sync undo window -------------------------------------------------------

-- Opened by SYNC_APPLIED (ns.Engine:ApplySync: the Jump button, /fb sync, or the engine itself
-- in "auto" mode) for the step shown right after the jump; closed after UNDO_SECONDS, when the
-- displayed step changes, by SYNC_UNDONE, or when the jump's floor is gone (ns.Engine:GetLastSync).
SF.pendingUndo = nil -- record of the last SYNC_APPLIED until the next refresh
SF.undo = nil

-- title of the segment a sync jumped to (record = cdb.syncFloor: { to = <segment id>, stepId })
local function syncTitle(record)
    if type(record) ~= "table" then return nil end
    if type(record.to) == "string" then return UI.SegmentTitle(record.to) end
    local E = ns.Engine
    local i = E and E.IndexOf and record.stepId and E:IndexOf(record.stepId)
    local step = i and E:GetSteps()[i]
    return step and step.segment and UI.SegmentTitle(step.segment) or nil
end

local function syncStillActive(u)
    local E = ns.Engine
    if E and E.GetLastSync then
        local ls = E:GetLastSync()
        return ls ~= nil and (type(u.record) ~= "table" or ls.record == u.record)
    end
    return UI.SyncFloor() ~= nil
end

function SF:CheckUndo(current)
    local record = self.pendingUndo
    if record then
        self.pendingUndo = nil
        self.undo = { record = record, stepId = current and current.id, untilTime = now() + UNDO_SECONDS,
            title = syncTitle(record) }
    end
    local u = self.undo
    if u and (now() >= u.untilTime or (current and current.id) ~= u.stepId or not syncStillActive(u)) then
        self.undo = nil
    end
    return self.undo
end

--- Undo window state ({ title, untilTime, ... }) after a level sync, nil when closed.
function SF:GetUndo()
    return self.undo
end

-- sync banner -----------------------------------------------------------------------

local function bannerTooltip(self)
    UI.ShowTooltip(self, self.tooltipTitle, self.tooltipLines)
end

local function createBanner()
    local b = CreateFrame("Frame", nil, frame)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(b)
    bg:SetColorTexture(0.35, 0.27, 0.05, 0.55)
    b.bg = bg

    local text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", b, "TOPLEFT", BANNER_PAD, -BANNER_PAD)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(true)
    text:SetTextColor(COLORS.banner[1], COLORS.banner[2], COLORS.banner[3])
    b.text = text

    local bw = 96
    b.goButton = UI.CreateButton(b, L.UI_SYNC_GO, { L.UI_SYNC_GO, { L.UI_SYNC_GO_TT } }, function()
        UI.ApplySync()
    end, bw, BANNER_BUTTON_H)
    b.goButton:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -4)
    b.stayButton = UI.CreateButton(b, L.UI_SYNC_STAY, { L.UI_SYNC_STAY, { L.UI_SYNC_STAY_TT } }, function()
        UI.DismissSync()
    end, bw, BANNER_BUTTON_H)
    b.stayButton:SetPoint("LEFT", b.goButton, "RIGHT", BUTTON_GAP, 0)

    -- "Undo" link: a plain button with its own font string (no template art)
    local link = CreateFrame("Button", nil, b)
    local fs = link:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPRIGHT", link, "TOPRIGHT", 0, 0)
    fs:SetJustifyH("RIGHT")
    link:SetFontString(fs)
    link:SetText(L.UI_SYNC_UNDO)
    fs:SetTextColor(COLORS.link[1], COLORS.link[2], COLORS.link[3])
    link:SetSize(max(40, (fs:GetStringWidth() or 40) + 4), 14)
    link:SetPoint("TOPRIGHT", b, "TOPRIGHT", -BANNER_PAD, -BANNER_PAD + 1)
    link.tooltipTitle, link.tooltipLines = L.UI_SYNC_UNDO, { L.UI_SYNC_UNDO_TT }
    link:SetScript("OnEnter", function(self)
        fs:SetTextColor(COLORS.linkHover[1], COLORS.linkHover[2], COLORS.linkHover[3])
        bannerTooltip(self)
    end)
    link:SetScript("OnLeave", function()
        fs:SetTextColor(COLORS.link[1], COLORS.link[2], COLORS.link[3])
        UI.HideTooltip()
    end)
    link:SetScript("OnClick", function() UI.UndoSync() end)
    b.undoButton = link

    b:Hide()
    return b
end

-- Lays out the banner at vertical offset y. @return new y
local function layoutBanner(y, current)
    local b = frame.banner
    local width = WIDTH - 2 * PAD
    local undo = SF:CheckUndo(current)
    local sug = UI.SyncSuggestion() -- a new suggestion wins over the undo link
    if sug then
        b.text:SetWidth(width - 2 * BANNER_PAD)
        b.text:SetText(format(L.UI_SYNC_BANNER_FMT, tonumber(sug.level) or 0, UI.SegmentTitle(sug.from),
            UI.SegmentTitle(sug.to)))
        b.goButton:Show()
        b.stayButton:Show()
        b.undoButton:Hide()
        b.kind = "suggest"
        b.suggestion = sug
        local h = (b.text:GetStringHeight() or 12) + 4 + BANNER_BUTTON_H + 2 * BANNER_PAD
        b:SetSize(width, h)
    elseif undo then
        b.text:SetWidth(width - 2 * BANNER_PAD - b.undoButton:GetWidth() - 6)
        b.text:SetText(undo.title and format(L.UI_SYNC_DONE_FMT, undo.title) or L.UI_SYNC_DONE)
        b.goButton:Hide()
        b.stayButton:Hide()
        b.undoButton:Show()
        b.kind = "undo"
        b.suggestion = nil
        local h = max(b.text:GetStringHeight() or 12, 14) + 2 * BANNER_PAD
        b:SetSize(width, h)
    else
        b.kind, b.suggestion = nil, nil
        b:Hide()
        return y
    end
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -y)
    b:Show()
    return y + b:GetHeight() + SECTION_GAP
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
    local current = route and E:GetCurrentStep() or nil

    updateHeader(route, steps, cursor)
    updateButtons(route, steps, cursor)

    local y = layoutBanner(TOP_BLOCK + 2, current)
    if not route then
        y = addRow(y, L.UI_NO_ROUTE, { color = COLORS.message })
    else
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
            -- not-done steps only (ns.Engine:GetUpcoming); a step done meanwhile is dropped too
            local upcoming = E:GetUpcoming(min(n, 20))
            local titled = false
            for _, s in ipairs(type(upcoming) == "table" and upcoming or EMPTY) do
                if not (E.IsDone and E:IsDone(s)) then
                    local lines = stepLines(s, "upcoming")
                    if #lines > 0 then
                        if not titled then
                            y = addSection(y, L.UI_UPCOMING)
                            titled = true
                        end
                        y = addStep(y, s, "upcoming", lines)
                    end
                end
            end
        end
    end

    for i = rowsUsed + 1, #rows do
        rows[i]:Hide()
        rows[i].step = nil
    end

    -- only the height follows the content: the window is anchored by its top edge
    local h = floor(y + PAD + 0.5)
    frame:SetHeight(h)
    -- keep the header + buttons on screen; the content may hang below the screen edge
    -- instead of pushing the window (and its buttons) up
    frame:SetClampRectInsets(0, 0, 0, max(0, h - TOP_BLOCK))
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
    -- a saved middle / bottom anchor (older versions) is converted to the top edge with the real
    -- height: written back only once the engine has started (before PLAYER_LOGIN the window shows
    -- the "no route" line only)
    local E = ns.Engine
    UI.RestorePosition(frame, "steps", "TOPRIGHT", "RIGHT", -80, 180, true, (E and E.started) and true or false)
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
    UI.MakeMovable(frame, "steps", true)

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

    -- button row: fixed offsets from the top edge, chained only to each other
    local bw = floor((WIDTH - 2 * PAD - 2 * BUTTON_GAP) / 3)
    frame.prevButton = UI.CreateButton(frame, L.UI_BTN_PREV,
        { L.UI_BTN_PREV, { L.UI_TT_BACK } }, function() UI.Back() end, bw, BUTTON_H)
    frame.forwardButton = UI.CreateButton(frame, L.UI_BTN_FORWARD,
        { L.UI_BTN_FORWARD, { L.UI_TT_FORWARD, { L.UI_TT_FORWARD_BACK, 0.75, 0.75, 0.75 },
            { L.UI_TT_FORWARD_AUTO, 0.6, 0.6, 0.6 } } }, function() UI.Forward() end, bw, BUTTON_H)
    frame.nextButton = frame.forwardButton -- older name (tools/simulate_routes.lua clicks it)
    frame.settingsButton = UI.CreateButton(frame, L.UI_BTN_SETTINGS, { L.UI_BTN_SETTINGS, { L.UI_TT_SETTINGS } },
        function()
            if UI.Options and UI.Options.Open then UI.Options:Open() end
        end, bw, BUTTON_H)
    frame.buttons = { frame.prevButton, frame.forwardButton, frame.settingsButton }
    for i, b in ipairs(frame.buttons) do
        if i == 1 then
            b:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -BUTTON_Y)
        else
            b:SetPoint("LEFT", frame.buttons[i - 1], "RIGHT", BUTTON_GAP, 0)
        end
    end

    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(1, 1, 1, 0.15)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -(TOP_BLOCK - 2))
    sep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -(TOP_BLOCK - 2))

    frame.banner = createBanner()

    frame.elapsed = 0
    frame:SetScript("OnUpdate", function(_, elapsed)
        frame.elapsed = (frame.elapsed or 0) + (elapsed or 0)
        if SF.dirty or frame.elapsed >= REFRESH_INTERVAL then
            SF:Refresh()
        end
    end)
    frame:SetScript("OnShow", function() SF:Refresh() end)

    self:Refresh()       -- the current height first (ApplySettings converts an old anchor with it; the
    self:ApplySettings() -- conversion is saved only once the engine has started: PLAYER_LOGIN below)
    self:Refresh()
    return frame
end

---------------------------------------------------------------------------
-- level sync actions (banner buttons, /fb sync)
---------------------------------------------------------------------------

--- Jump to the first segment that fits the player's level (ns.Engine:ApplySync: also without a
-- banner -- "off" mode, a dismissed offer -- when the current segment is outleveled; it prints
-- the chat line and fires SYNC_APPLIED, which opens the Undo link).
-- @return true when a sync was applied
function UI.ApplySync()
    local E = ns.Engine
    if not UI.HasSync() then return false end
    local ok = E:ApplySync()
    SF:MarkDirty()
    return ok ~= false
end

--- Keep the current segment: no suggestion for it until the next level-up.
function UI.DismissSync()
    local E = ns.Engine
    if not (E and E.DismissSync) then return false end
    E:DismissSync()
    SF:MarkDirty()
    return true
end

--- Undo the last level sync (ns.Engine:UndoSync restores the previous floor; prints the chat line).
-- @return true when there was a sync to undo
function UI.UndoSync()
    local E = ns.Engine
    -- only the floor of the active route (UI.SyncFloor): another route's floor stays for that route
    if not (E and E.UndoSync) or not UI.SyncFloor() then return false end
    local ok = E:UndoSync()
    SF.undo, SF.pendingUndo = nil, nil
    SF:MarkDirty()
    return ok ~= false
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
ns:Listen("SYNC_SUGGESTION", markDirty)
ns:Listen("SYNC_APPLIED", function(_, record)
    SF.pendingUndo = record or true
    SF:MarkDirty()
end)
ns:Listen("SYNC_UNDONE", function()
    SF.undo, SF.pendingUndo = nil, nil
    SF:MarkDirty()
end)
ns:Listen("UI_VISIBILITY_CHANGED", function() SF:UpdateVisibility() end)
-- scale / hide-in-combat / shownNext / debug: re-applying everything is cheap
ns:Listen("SETTINGS_CHANGED", function() SF:ApplySettings() end)

-- after Engine:Start (Core/Engine.lua registers its PLAYER_LOGIN handler first): lay out the route's
-- step so the position is restored -- and an old middle / bottom anchor converted -- with the real height
ns:On("PLAYER_LOGIN", function()
    if frame then
        SF:Refresh()
        SF:ApplySettings()
    end
    -- "/fb hide" is account-wide and survives a relog: say why there is no guide on this character
    if UI.IsGuideHidden() and ns.Print then ns.Print("%s", L.UI_HIDDEN) end
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
