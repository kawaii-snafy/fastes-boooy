-- AdventureAtlas / UI / Atlas.lua
--
-- The atlas window: one window with tabs, opened by the minimap button (UI/MinimapButton.lua),
-- `/aa atlas` or the settings. Tabs (TABS below, in display order):
--   adventure   "Your adventure": the character's path -- for now the active leveling route: title,
--               level, progress, and its chapters (segments) with the current one marked
--   knowledge   "Knowledge base": a placeholder until the quest list exists (docs/dev/ATLAS.md)
-- A tab's page is built the first time it is shown and refreshed while visible. The window and
-- its selected tab live in ns.db.frames.atlas (position: UI.MakeMovable / UI.RestorePosition).
--
-- Consumes ns.Engine (GetRoute / GetNaturalCursor / GetChapters) and ns.UI (toolkit of
-- UI/StepFrame.lua, incl. UI.PlayerLevel). Exposes ns.Atlas.

-- luacheck: ignore 212/self (singleton module keeps the colon method style)

local _, ns = ...

local UI = ns.UI
local L = UI.L

local ipairs, pairs, format, floor, max, min = ipairs, pairs, string.format, math.floor, math.max, math.min

local Atlas = {}
ns.Atlas = Atlas

local WIDTH, HEIGHT = 560, 480
local PAD = 14
local ROW_HEIGHT = 20
local DEFAULT_TAB = "adventure"

local frame -- the window, created on first use

local function atlasDB() return UI.FramesDB("atlas") end

---------------------------------------------------------------------------
-- "Your adventure" tab
---------------------------------------------------------------------------

local PAGE_WIDTH = WIDTH - 2 * PAD
local TOGGLE_WIDTH = 150
local SCROLLBAR = 22   -- room right of the chapter list for the template's scroll bar
local COUNT_WIDTH = 50

-- Fixed widths instead of a second (middle-edge) anchor: a RIGHT point would also pin the vertical
-- center of the region.
local function buildAdventure(page)
    local toggle = UI.CreateButton(page, "", nil, function()
        UI.SetGuideHidden(not UI.IsGuideHidden())
    end, TOGGLE_WIDTH, 22)
    toggle:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 2)
    page.toggle = toggle

    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    title:SetWidth(PAGE_WIDTH - TOGGLE_WIDTH - 8)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    page.title = title

    local info = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    info:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    info:SetWidth(PAGE_WIDTH)
    info:SetJustifyH("LEFT")
    page.info = info

    local bar = CreateFrame("StatusBar", nil, page)
    bar:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -8)
    bar:SetSize(PAGE_WIDTH, 12)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.2, 0.7, 0.3)
    bar:SetMinMaxValues(0, 1)
    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints(bar)
    barBg:SetColorTexture(0, 0, 0, 0.5)
    page.bar = bar

    local header = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -14)
    header:SetText(L.UI_ATLAS_CHAPTERS)
    page.header = header

    -- chapter list: pooled rows in a scroll child
    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -SCROLLBAR, 0)
    local list = CreateFrame("Frame", nil, scroll)
    list:SetSize(PAGE_WIDTH - SCROLLBAR - 8, ROW_HEIGHT)
    scroll:SetScrollChild(list)
    page.scroll, page.list, page.rows = scroll, list, {}

    local empty = page:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
    empty:SetWidth(PAGE_WIDTH)
    empty:SetJustifyH("LEFT")
    page.empty = empty
end

local function showRowTooltip(row)
    UI.ShowTooltip(row, row.name:GetText(), { row.count:GetText() })
end

-- Row: mark | title (it starts with the level range, e.g. "13-15 Silverpine Forest") | done/total.
-- The tooltip shows the whole title when the column cuts it off.
local function chapterRow(page, i)
    local row = page.rows[i]
    if row then return row end
    local width = page.list:GetWidth()
    row = CreateFrame("Frame", nil, page.list)
    row:SetSize(width, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", page.list, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    local mark = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mark:SetPoint("LEFT", row, "LEFT", 0, 0)
    mark:SetWidth(18)
    local count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    count:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    count:SetWidth(COUNT_WIDTH)
    count:SetJustifyH("RIGHT")
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("LEFT", row, "LEFT", 20, 0)
    name:SetWidth(width - 20 - COUNT_WIDTH - 6)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    row.mark, row.name, row.count = mark, name, count
    row:EnableMouse(true)
    row:SetScript("OnEnter", showRowTooltip)
    row:SetScript("OnLeave", UI.HideTooltip)
    page.rows[i] = row
    return row
end

-- colors: done chapters dimmed, the current one gold, the rest white
local function paintRow(row, ch)
    local r, g, b = 1, 1, 1
    local mark = ""
    if ch.current then
        r, g, b, mark = 1, 0.82, 0, ">"
    elseif ch.total > 0 and ch.done >= ch.total then
        r, g, b, mark = 0.5, 0.5, 0.5, "+"
    end
    row.mark:SetText(mark)
    row.mark:SetTextColor(r, g, b)
    row.name:SetTextColor(r, g, b)
    row.count:SetTextColor(r, g, b)
end

local function refreshAdventure(page)
    local E = ns.Engine
    local route = E and E:GetRoute()
    page.toggle:SetText(UI.IsGuideHidden() and L.UI_ATLAS_SHOW_GUIDE or L.UI_ATLAS_HIDE_GUIDE)
    local level = UI.PlayerLevel() or 0
    local chapters = route and E:GetChapters() or {}
    if not route then
        page.title:SetText(L.UI_ATLAS_NO_ROUTE)
        page.info:SetText(format(L.UI_ATLAS_LEVEL_FMT, level))
        page.bar:Hide()
        page.empty:SetText(L.UI_NO_ROUTE)
        page.empty:Show()
    else
        local total, done = 0, 0
        for _, ch in ipairs(chapters) do
            total, done = total + ch.total, done + ch.done
        end
        local pct = total > 0 and floor(done / total * 100) or 100
        page.title:SetText(UI.Text(route.title) or tostring(route.id))
        if E:GetNaturalCursor() then
            page.info:SetText(format(L.UI_ATLAS_PROGRESS_FMT, level, done, total, pct))
        else
            page.info:SetText(format(L.UI_ATLAS_FINISHED_FMT, level))
        end
        page.bar:SetValue(total > 0 and done / total or 1)
        page.bar:Show()
        page.empty:Hide()
    end
    local current
    for i, ch in ipairs(chapters) do
        local row = chapterRow(page, i)
        row.name:SetText(UI.Text(ch.seg and ch.seg.title) or tostring(ch.id))
        row.count:SetText(format("%d/%d", ch.done, ch.total))
        paintRow(row, ch)
        row:Show()
        if ch.current then current = i end
    end
    for i = #chapters + 1, #page.rows do page.rows[i]:Hide() end
    page.list:SetHeight(max(ROW_HEIGHT, #chapters * ROW_HEIGHT))
    -- bring the current chapter into view when it changes (first show, next chapter, another
    -- route); later refreshes keep the player's own scrolling
    if current ~= page.current then
        page.current = current
        if current then
            local range = max(0, #chapters * ROW_HEIGHT - page.scroll:GetHeight())
            page.scroll:SetVerticalScroll(min(range, max(0, (current - 2) * ROW_HEIGHT)))
        end
    end
end

---------------------------------------------------------------------------
-- "Knowledge base" tab
---------------------------------------------------------------------------

local function buildKnowledge(page)
    local text = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    text:SetWidth(PAGE_WIDTH)
    text:SetJustifyH("LEFT")
    text:SetText(L.UI_ATLAS_KNOWLEDGE_SOON)
    page.text = text
end

---------------------------------------------------------------------------
-- window
---------------------------------------------------------------------------

local TABS = {
    { key = "adventure", label = "UI_ATLAS_TAB_ADVENTURE", build = buildAdventure, refresh = refreshAdventure },
    { key = "knowledge", label = "UI_ATLAS_TAB_KNOWLEDGE", build = buildKnowledge },
}
local TAB_BY_KEY = {}
for _, t in ipairs(TABS) do TAB_BY_KEY[t.key] = t end

function Atlas:Create()
    if frame then return frame end
    frame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame.TitleText:SetText(L.UI_TITLE)
    UI.MakeMovable(frame, "atlas")
    UI.RestorePosition(frame, "atlas", "CENTER", "CENTER", 0, 40) -- default: ns.DEFAULTS.db.frames.atlas

    frame.tabs, frame.pages = {}, {}
    local prev
    for _, t in ipairs(TABS) do
        local key = t.key
        local b = UI.CreateButton(frame, L[t.label], nil, function() Atlas:SelectTab(key) end, 160, 24)
        b:SetNormalFontObject("GameFontNormal")
        b:SetHighlightFontObject("GameFontHighlight")
        if prev then
            b:SetPoint("LEFT", prev, "RIGHT", 6, 0)
        else
            b:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -32)
        end
        frame.tabs[key], prev = b, b
    end

    frame:SetScript("OnShow", function() Atlas:Refresh() end)
    frame:Hide()
    return frame
end

--- The page frame of a tab (built on first use).
local function page(key)
    local p = frame.pages[key]
    if p then return p end
    p = CreateFrame("Frame", nil, frame)
    p:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -68)
    p:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, PAD)
    TAB_BY_KEY[key].build(p)
    frame.pages[key] = p
    return p
end

function Atlas:GetFrame() return frame end

--- Key of the selected tab (saved per account, the first tab by default).
function Atlas:SelectedTab()
    local key = (atlasDB() or {}).tab
    return TAB_BY_KEY[key] and key or DEFAULT_TAB
end

--- Show a tab's page, hide the others, remember the choice.
function Atlas:SelectTab(key)
    if not TAB_BY_KEY[key] then key = DEFAULT_TAB end
    local db = atlasDB()
    if db then db.tab = key end
    if not frame then return end
    for k, b in pairs(frame.tabs) do
        if k == key then b:LockHighlight() else b:UnlockHighlight() end
        local p = frame.pages[k]
        if p and k ~= key then p:Hide() end
    end
    page(key):Show()
    self:Refresh()
end

--- Re-read the engine for the selected tab (only while the window is shown).
function Atlas:Refresh()
    if not (frame and frame:IsShown()) then return end
    local key = self:SelectedTab()
    local p = frame.pages[key]
    if not p then
        self:SelectTab(key) -- builds the page, then comes back here
        return
    end
    local refresh = TAB_BY_KEY[key].refresh
    if refresh then refresh(p) end
end

--- Open the atlas (optionally on a tab).
function Atlas:Open(key)
    self:Create()
    frame:Show()
    frame:Raise() -- in front also when it was open already (e.g. under the settings panel)
    self:SelectTab(key or self:SelectedTab())
end

function Atlas:Close()
    if frame then frame:Hide() end
end

function Atlas:Toggle()
    if frame and frame:IsShown() then self:Close() else self:Open() end
end

function Atlas:IsShown()
    return frame and frame:IsShown() or false
end

---------------------------------------------------------------------------
-- wiring
---------------------------------------------------------------------------

local function refresh() Atlas:Refresh() end

ns:Listen("ROUTE_CHANGED", refresh)
ns:Listen("STEP_CHANGED", refresh)
ns:Listen("PROGRESS_UPDATED", refresh)
ns:Listen("UI_VISIBILITY_CHANGED", refresh)
ns:Listen("SETTINGS_CHANGED", function(_, key)
    -- /aa resetpos: back to the default place
    if key == "frames" and frame then UI.RestorePosition(frame, "atlas", "CENTER", "CENTER", 0, 40) end
end)
ns:On("PLAYER_LEVEL_UP", refresh)
