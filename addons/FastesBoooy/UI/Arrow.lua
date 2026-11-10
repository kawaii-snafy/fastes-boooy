-- FastesBoooy / UI / Arrow.lua
--
-- Small movable navigation arrow: a texture rotated by the waypoint angle
-- (ns.Waypoint:GetTarget().angle, radians relative to the player facing, the
-- same counter-clockwise convention as Texture:SetRotation), the distance in
-- yards and the target label. Hidden when there is no target or no angle
-- (other continent, instance without position, ...), when the arrow setting is
-- off or when the guide is hidden (/fb hide, hide in combat).
--
-- Texture: atlas "Navigation-Tracked-Arrow" (interface/navigation/ingamenavigationui,
-- present in Forever's AtlasInfo; Blizzard's SuperTrackedFrame rotates the same
-- atlas with SetRotation). It points up at rotation 0.

-- luacheck: ignore 212/self (singleton modules keep the colon method style)

local _, ns = ...

local UI = ns.UI or {}
ns.UI = UI
local L = UI.L or setmetatable({}, { __index = function(_, k) return (ns.L and ns.L[k]) or k end })

local type, tonumber, format, floor = type, tonumber, string.format, math.floor

local Arrow = {}
UI.Arrow = Arrow

local ARROW_ATLAS = "Navigation-Tracked-Arrow" -- 22x18 at 1x
local ARROW_W, ARROW_H = 44, 36
local FRAME_SIZE = 50
local NEAR_YARDS = 15
local STALE_SECONDS = 1 -- re-query the target if WAYPOINT_UPDATED stopped coming

local CLAMP_SIDE, CLAMP_BOTTOM = 65, 40 -- how far the label / the texts reach out of the frame

local frame, tex, distText, labelText
local lastTarget
local bearing -- world bearing of the target (target.angle + facing), nil: no direction

local function settings()
    return UI.Settings and UI.Settings() or {}
end

local function hiddenByUser()
    return UI.ShouldHide and UI.ShouldHide() or false
end

local function currentTarget()
    local W = ns.Waypoint
    if not W or not W.GetTarget then return nil end
    return W:GetTarget()
end

--- Redraw from the current waypoint target (re-queried from ns.Waypoint so the
-- callback payload layout does not matter).
function Arrow:Update()
    if not frame then return end
    frame.elapsed = 0
    local target = currentTarget()
    lastTarget = target
    if settings().arrow == false or hiddenByUser()
        or type(target) ~= "table" or type(target.angle) ~= "number" then
        bearing = nil
        frame:Hide()
        return
    end

    tex:SetRotation(target.angle)
    -- world bearing of the target: OnUpdate turns the arrow with the player between waypoint ticks
    local facing = ns.Compat.Facing()
    bearing = facing and (target.angle + facing) or nil

    local d = tonumber(target.distance)
    if d then
        distText:SetText(format(L.UI_YARDS_FMT, floor(d + 0.5)))
        if d <= NEAR_YARDS then
            distText:SetTextColor(0.3, 1, 0.3)
            tex:SetVertexColor(0.5, 1, 0.5)
        else
            distText:SetTextColor(1, 1, 1)
            tex:SetVertexColor(1, 1, 1)
        end
    else
        distText:SetText("")
        tex:SetVertexColor(1, 1, 1)
    end
    labelText:SetText(target.label or "")

    if not frame:IsShown() then frame:Show() end
end

function Arrow:ApplySettings()
    if not frame then return end
    local s = settings()
    local scale = tonumber(s.arrowScale) or 1
    if scale < 0.3 or scale > 3 then scale = 1 end
    frame:SetScale(scale)
    -- locked: let clicks go through to the world
    frame:EnableMouse(not s.locked)
    UI.RestorePosition(frame, "arrow", "TOP", "TOP", 0, -120)
    self:Update()
end

function Arrow:GetFrame()
    return frame
end

local function onEnter(self)
    local t = lastTarget
    if type(t) ~= "table" then return end
    local lines = {}
    if t.distance then
        lines[#lines + 1] = format(L.UI_YARDS_FMT, floor((tonumber(t.distance) or 0) + 0.5))
    end
    if not settings().locked then
        lines[#lines + 1] = { L.UI_TT_DRAG, 0.6, 0.6, 0.6 }
    end
    UI.ShowTooltip(self, t.label or L.UI_TITLE, lines)
end

function Arrow:Create()
    if frame then return frame end
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(FRAME_SIZE, FRAME_SIZE)
    frame:SetFrameStrata("MEDIUM")
    UI.MakeMovable(frame, "arrow")
    -- the distance and the label hang below / beside the 50x50 frame: keep them on screen too
    frame:SetClampRectInsets(-CLAMP_SIDE, CLAMP_SIDE, 0, -CLAMP_BOTTOM)

    tex = frame:CreateTexture(nil, "ARTWORK")
    tex:SetAtlas(ARROW_ATLAS)
    tex:SetSize(ARROW_W, ARROW_H)
    tex:SetPoint("CENTER", frame, "CENTER", 0, 0)

    distText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    distText:SetPoint("TOP", frame, "BOTTOM", 0, 2)

    labelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelText:SetPoint("TOP", distText, "BOTTOM", 0, -1)
    labelText:SetWidth(180)
    labelText:SetWordWrap(true)
    labelText:SetMaxLines(2)

    frame:SetScript("OnEnter", onEnter)
    frame:SetScript("OnLeave", UI.HideTooltip)
    frame.elapsed = 0
    frame:SetScript("OnUpdate", function(_, elapsed)
        frame.elapsed = (frame.elapsed or 0) + (elapsed or 0)
        if frame.elapsed >= STALE_SECONDS then
            Arrow:Update()
        elseif bearing then
            local facing = ns.Compat.Facing()
            if facing then tex:SetRotation(bearing - facing) end
        end
    end)

    frame:Hide()
    self:ApplySettings()
    return frame
end

---------------------------------------------------------------------------
-- wiring
---------------------------------------------------------------------------

local function update() Arrow:Update() end

ns:Listen("DB_READY", function()
    if frame then Arrow:ApplySettings() else Arrow:Create() end
end)
ns:Listen("WAYPOINT_UPDATED", update)
ns:Listen("STEP_CHANGED", update)
ns:Listen("ROUTE_CHANGED", update)
ns:Listen("UI_VISIBILITY_CHANGED", update)
ns:Listen("SETTINGS_CHANGED", function() Arrow:ApplySettings() end)
-- set the combat flag here too: handler order between UI files is not guaranteed
ns:On("PLAYER_REGEN_DISABLED", function()
    UI.inCombat = true
    update()
end)
ns:On("PLAYER_REGEN_ENABLED", function()
    UI.inCombat = false
    update()
end)
ns:On("PLAYER_ENTERING_WORLD", update)

if ns.dbReady and not frame then Arrow:Create() end
