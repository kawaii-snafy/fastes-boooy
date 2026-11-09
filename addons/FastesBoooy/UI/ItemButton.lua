-- FastesBoooy / UI / ItemButton.lua
--
-- "Use item" button for the step field `use = itemId` (docs/ROUTE_FORMAT.md): shows the
-- item of the displayed step -- or, when it has none, of the first active background
-- step with one -- while that item is in the bags; a left click uses it.
--
-- A secure button (SecureActionButtonTemplate, attributes type1 = "item", item1 =
-- "item:<id>") created as a TOP-LEVEL frame: parent UIParent, anchored to UIParent only,
-- with its own saved position (ns.db.frames.item). It must not be parented or anchored to
-- the step window: a frame with a protected child, or with a protected frame anchored to
-- it, becomes protected itself, and the step window hides (hide in combat), resizes
-- (every refresh) and moves (drag) during combat.
--
-- Combat lockdown: attribute changes, Show / Hide and moving a protected frame are
-- blocked while InCombatLockdown() is true. Every change goes through Update(), which
-- then only remembers that an update is pending and runs it on PLAYER_REGEN_ENABLED
-- (the icon / count regions may change any time). PLAYER_REGEN_DISABLED fires before
-- the lockdown starts: a drag in progress is finished then. "Hide in combat" does not hide the
-- button (quest items are used in fights); only /fb hide does.
--
-- Global name FastesBoooyItemButton: a macro `/click FastesBoooyItemButton` (key
-- binding) uses the item too. Right button: drag to move (unless the frames are locked).

-- luacheck: ignore 212/self (singleton modules keep the colon method style)

local _, ns = ...

local UI = ns.UI or {}
ns.UI = UI
local L = UI.L or setmetatable({}, { __index = function(_, k) return (ns.L and ns.L[k]) or k end })

local type, ipairs, tonumber, tostring = type, ipairs, tonumber, tostring

local IB = {}
UI.ItemButton = IB

local NAME = "FastesBoooyItemButton"
local SIZE = 36
local EMPTY = {}

local button, icon, countText
local shownItem   -- item id the secure attributes hold (nil: none, button hidden)
local pending = false

local function settings()
    return UI.Settings and UI.Settings() or EMPTY
end

local function lockdown()
    return InCombatLockdown() and true or false
end

local function usableItem(step)
    local id = type(step) == "table" and step.use or nil
    if type(id) == "number" and ns.Compat.ItemCount(id) > 0 then return id end
    return nil
end

--- Item the button offers now: `use` of the displayed step, else of the first active
-- background step, when the item is in the bags (nil: none).
function IB:PickItem()
    local E = ns.Engine
    if not (E and E.GetRoute and E:GetRoute()) then return nil end
    local id = usableItem(E:GetCurrentStep())
    if id then return id end
    for _, s in ipairs(E:GetBackground() or EMPTY) do
        id = usableItem(s)
        if id then return id end
    end
    return nil
end

--- Item id the button currently offers (nil when hidden).
function IB:GetItem()
    return shownItem
end

function IB:GetFrame()
    return button
end

--- true while a change waits for the end of combat lockdown.
function IB:IsPending()
    return pending
end

-- icon + stack count (plain regions: allowed during combat)
local function updateFace(id)
    icon:SetTexture(ns.Compat.ItemIcon(id) or ns.Steps.ITEM_FALLBACK_ICON)
    local n = ns.Compat.ItemCount(id)
    countText:SetText(n > 1 and tostring(n) or "")
end

--- Apply the current state (item, visibility). Deferred during combat lockdown.
function IB:Update()
    if lockdown() then
        pending = true
        if button and shownItem then updateFace(shownItem) end
        return
    end
    pending = false
    if not button then
        if ns.dbReady then self:Create() end -- Create applies the settings and updates
        return
    end
    local id = nil
    -- only "/fb hide" hides the button: "hide in combat" keeps it, quest items are used in fights
    -- (and a hidden button would make the /click macro do nothing)
    if not (UI.IsGuideHidden and UI.IsGuideHidden()) then id = self:PickItem() end
    if id then
        if id ~= shownItem then
            button:SetAttribute("type1", "item")
            button:SetAttribute("item1", "item:" .. id)
            shownItem = id
        end
        updateFace(id)
        if not button:IsShown() then button:Show() end
    else
        if shownItem then
            button:SetAttribute("type1", nil)
            button:SetAttribute("item1", nil)
            shownItem = nil
        end
        if button:IsShown() then button:Hide() end
    end
end

--- Scale + saved position, then Update(). Deferred during combat lockdown.
function IB:ApplySettings()
    if lockdown() then
        pending = true
        return
    end
    if button then
        local scale = tonumber(settings().frameScale) or 1
        if scale < 0.3 or scale > 3 then scale = 1 end
        button:SetScale(scale)
        UI.RestorePosition(button, "item", "RIGHT", "RIGHT", -388, 120)
    end
    self:Update()
end

local function onEnter(self)
    local id = shownItem
    if not id then return end
    local lines = { L.UI_TT_ITEM_USE }
    if not settings().locked then
        lines[#lines + 1] = { L.UI_TT_ITEM_DRAG, 0.6, 0.6, 0.6 }
    end
    UI.ShowTooltip(self, ns.Steps:ItemName(id), lines)
end

-- Finish a right-button drag and save the position. Also called when the button is hidden and on
-- PLAYER_REGEN_DISABLED (before the lockdown: a protected frame cannot be stopped during it).
local function stopDrag(f)
    if not (f and f.isMoving) then return end
    f.isMoving = false
    f:StopMovingOrSizing()
    UI.SavePosition(f, "item")
end

--- Create the button (out of combat only: deferred to the end of combat otherwise).
function IB:Create()
    if button then return button end
    if lockdown() then
        pending = true
        return nil
    end
    local b = CreateFrame("Button", NAME, UIParent, "SecureActionButtonTemplate")
    b:SetSize(SIZE, SIZE)
    b:SetFrameStrata("MEDIUM")
    -- the action runs on the press or the release depending on ActionButtonUseKeyDown
    b:RegisterForClicks("AnyUp", "AnyDown")

    icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(b)
    icon:SetTexture(ns.Steps.ITEM_FALLBACK_ICON)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

    countText = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    countText:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    countText:SetJustifyH("RIGHT")

    -- right button drag (the left button uses the item); never during combat lockdown
    b:SetMovable(true)
    b:SetClampedToScreen(true)
    b:SetDontSavePosition(true)
    b:RegisterForDrag("RightButton")
    b:SetScript("OnDragStart", function(f)
        if settings().locked or lockdown() then return end
        f.isMoving = true
        f:StartMoving()
    end)
    b:SetScript("OnDragStop", stopDrag)
    b:SetScript("OnHide", stopDrag) -- hidden while being dragged: no OnDragStop comes
    b:SetScript("OnEnter", onEnter)
    b:SetScript("OnLeave", UI.HideTooltip)
    b:Hide()

    button = b
    self:ApplySettings()
    return button
end

---------------------------------------------------------------------------
-- wiring
---------------------------------------------------------------------------

local function update() IB:Update() end

ns:Listen("DB_READY", function()
    if button then IB:ApplySettings() else IB:Create() end
end)
ns:Listen("ROUTE_CHANGED", update)
ns:Listen("STEP_CHANGED", update)
ns:Listen("PROGRESS_UPDATED", update)
ns:Listen("UI_VISIBILITY_CHANGED", update)
ns:Listen("ITEM_DATA_LOADED", update)
ns:Listen("SETTINGS_CHANGED", function() IB:ApplySettings() end)
ns:On("BAG_UPDATE_DELAYED", update)
-- set the combat flag here too: handler order between UI files is not guaranteed
ns:On("PLAYER_REGEN_DISABLED", function()
    UI.inCombat = true
    stopDrag(button) -- the lockdown starts after this event: a drag can still be finished
    update()
end)
ns:On("PLAYER_REGEN_ENABLED", function()
    UI.inCombat = false
    if pending then IB:ApplySettings() else update() end
end)

if ns.dbReady and not button then IB:Create() end
