-- AdventureAtlas / UI / MinimapButton.lua
--
-- Round button on the minimap rim, in the look of the minimap buttons of other addons (own code:
-- no LibDBIcon). Left click toggles the atlas window (UI/Atlas.lua), right click opens the
-- settings; drag moves it along the rim. The angle is saved in ns.db.minimap.angle (degrees,
-- counter-clockwise from the right, like math.atan2), the setting `minimapButton` shows / hides it
-- ("/aa minimap", the settings panel). Dragging follows the `locked` setting of the other windows.
--
-- Exposes ns.MinimapButton.

-- luacheck: ignore 212/self (singleton module keeps the colon method style)

local _, ns = ...

local UI = ns.UI
local L = UI.L

local cos, sin, rad, deg, atan2 = math.cos, math.sin, math.rad, math.deg, math.atan2

local MB = {}
ns.MinimapButton = MB

local RIM_OFFSET = 5      -- distance of the button center outside the minimap edge
local DEFAULT_RADIUS = 70 -- half the width of the default minimap (140), until it has a size

local button

local function minimapDB()
    local db = ns.db
    if not db then return nil end
    if type(db.minimap) ~= "table" then db.minimap = {} end
    return db.minimap
end

--- Saved angle in degrees [0, 360).
function MB:GetAngle()
    local t = minimapDB()
    local a = t and tonumber(t.angle)
    if not a then a = ns.DEFAULTS.db.minimap.angle end
    return a % 360
end

--- Offset of the button center from the minimap center for an angle (degrees).
function MB.Offset(angle)
    local w = Minimap:GetWidth()
    local r = ((w and w > 0) and w / 2 or DEFAULT_RADIUS) + RIM_OFFSET
    return cos(rad(angle)) * r, sin(rad(angle)) * r
end

--- Angle (degrees) of the cursor around the minimap center, nil while the minimap has no position.
function MB.CursorAngle()
    local mx, my = Minimap:GetCenter()
    if not mx then return nil end
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    return deg(atan2(cy / scale - my, cx / scale - mx)) % 360
end

function MB:SetAngle(angle)
    local t = minimapDB()
    if t then t.angle = angle % 360 end
    self:UpdatePosition()
end

function MB:UpdatePosition()
    if not button then return end
    local x, y = MB.Offset(self:GetAngle())
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function onUpdateDrag()
    local a = MB.CursorAngle()
    if a then MB:SetAngle(a) end
end

local function showTooltip(self)
    local lines = { L.UI_MINIMAP_TT_LEFT, L.UI_MINIMAP_TT_RIGHT }
    if not UI.Settings().locked then lines[#lines + 1] = L.UI_MINIMAP_TT_DRAG end
    UI.ShowTooltip(self, L.UI_TITLE, lines, "ANCHOR_LEFT")
end

function MB:Create()
    if button then return button end
    button = CreateFrame("Button", nil, Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -6)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button.icon = icon

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            if UI.Options then UI.Options:Open() end
        elseif ns.Atlas then
            ns.Atlas:Toggle()
        end
    end)
    button:SetScript("OnDragStart", function(b)
        if UI.Settings().locked then return end
        b:SetScript("OnUpdate", onUpdateDrag)
        UI.HideTooltip()
    end)
    local function stopDrag(b) b:SetScript("OnUpdate", nil) end
    button:SetScript("OnDragStop", stopDrag)
    -- a hidden frame gets no OnDragStop (Alt+Z, a cinematic in the middle of a drag): end it here
    button:SetScript("OnHide", stopDrag)
    button:SetScript("OnEnter", showTooltip)
    button:SetScript("OnLeave", UI.HideTooltip)

    self:UpdatePosition()
    self:ApplySettings()
    return button
end

function MB:GetButton() return button end

--- Show or hide the button by the `minimapButton` setting.
function MB:ApplySettings()
    if not button then return end
    button:SetShown(UI.Settings().minimapButton ~= false)
    self:UpdatePosition()
end

ns:Listen("DB_READY", function() MB:Create() end)
ns:Listen("SETTINGS_CHANGED", function() MB:ApplySettings() end)

if ns.dbReady and not button then MB:Create() end
