-- AdventureAtlas / Core / Waypoint.lua
--
-- Navigation target of the current step (step.at):
--   ns.Waypoint:GetTarget() -> nil | {
--       map, x, y          uiMapID + percent (0..100), from step.at
--       distance           yards, nil when not computable (other continent, no position)
--       angle              radians relative to the player's facing, counter-clockwise,
--                          in (-pi, pi]: 0 = ahead, > 0 = left; nil when unknown.
--                          Use directly with Texture:SetRotation(angle).
--       sameContinent      false when player and target share no coordinate frame
--       approx             distance estimated with a nominal map size (map without
--                          world transform, e.g. instanced starting islands)
--       radius             arrival radius of the step (yards)
--       label              short localized description of the step
--       step               the step itself
--   }
-- While a target exists a 0.1 s ticker recomputes it and fires
-- ns:Fire("WAYPOINT_UPDATED", target); WAYPOINT_UPDATED(nil) is fired once
-- when the target disappears.
--
-- Math: world X points north, world Y points west (UnitPosition /
-- C_Map.GetWorldPosFromMapPos); GetPlayerFacing() is 0 at north and grows
-- counter-clockwise; bearing = atan2(dWest, dNorth); angle = bearing - facing
-- (ns.Compat.DistanceTo). Same convention as HereBeDragons/TomTom.
--
-- settings.blizzWaypoint: also place Blizzard's user waypoint on the target
-- (+ super-track => Blizzard's own on-screen arrow); only a waypoint placed by
-- the addon is ever cleared.
--
-- A target chosen by the player (Waypoint:SetCustom: "lead me" in the knowledge base) takes the
-- place of the route step until the player arrives (CUSTOM_RADIUS yards; a chat line says so) or
-- Waypoint:ClearCustom; ns:Fire("WAYPOINT_CUSTOM", custom|nil) follows each change.

local _, ns = ...
-- luacheck: ignore 212/self

local abs = math.abs

local Waypoint = {
    target = nil,
    step = nil,
    label = nil,
    placed = nil,   -- { map, x, y } of the Blizzard waypoint we placed
    failed = nil,   -- step whose Blizzard waypoint could not be placed
    ticker = nil,
}
ns.Waypoint = Waypoint

local TICK = 0.1
local CUSTOM_RADIUS = 10 -- yards: arrival at a custom target

local function settings()
    return ns.db and ns.db.settings or {}
end

function Waypoint:GetTarget()
    return self.target
end

local function currentStep()
    if Waypoint.custom then return Waypoint.custom end
    local E = ns.Engine
    if not (E and E.started) then return nil end
    local step = E:GetCurrentStep()
    if step and step.at then return step end
    return nil
end

function Waypoint:Compute(step)
    local at = step.at
    local dist, angle, same, approx = ns.Compat.DistanceTo(at.map, at.x, at.y)
    return {
        map = at.map, x = at.x, y = at.y,
        distance = dist, angle = angle,
        sameContinent = same and true or false,
        approx = approx and true or false,
        radius = step.radius,
        label = self.label or "",
        step = step,
    }
end

function Waypoint:RefreshLabel()
    local step = self.step
    if step and step.custom then
        self.label = step.label
    elseif step then
        local ok, label = pcall(ns.Steps.Label, ns.Steps, step)
        self.label = ok and label or tostring(step.id)
    else
        self.label = nil
    end
end

-- Remove the Blizzard user waypoint this addon placed (one the player set
-- elsewhere in the meantime is left alone).
function Waypoint:ClearPlaced()
    local C = ns.Compat
    local p = self.placed
    if not p then return end
    self.placed = nil
    local m, x, y = C.GetBlizzWaypoint()
    if m == p.map and x and abs(x - p.x) < 0.05 and abs(y - p.y) < 0.05 then
        C.ClearBlizzWaypoint()
    end
end

-- Place / clear the Blizzard user waypoint according to settings.blizzWaypoint.
function Waypoint:SyncBlizz(target)
    local C = ns.Compat
    if settings().blizzWaypoint and target then
        local p = self.placed
        if p and p.map == target.map and p.x == target.x and p.y == target.y then return end
        if self.failed == target.step then return end
        if C.SetBlizzWaypoint(target.map, target.x, target.y) then
            self.placed = { map = target.map, x = target.x, y = target.y }
            self.failed = nil
        else
            -- e.g. CanSetUserWaypointOnMap is false (instances, Zephras Isle): do not
            -- leave the previous step's waypoint placed and super-tracked
            self:ClearPlaced()
            self.failed = target.step
        end
    else
        self.failed = nil
        self:ClearPlaced()
    end
end

function Waypoint:StartTicker()
    if self.ticker or not (C_Timer and C_Timer.NewTicker) then return end
    self.ticker = C_Timer.NewTicker(TICK, function() Waypoint:Tick() end)
end

function Waypoint:StopTicker()
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
end

function Waypoint:Tick()
    local step = currentStep()
    if not step or step ~= self.step then
        return self:Update()
    end
    self.target = self:Compute(step)
    if step.custom and self.target.distance and self.target.distance <= CUSTOM_RADIUS then
        ns.Print(ns.L.WAYPOINT_ARRIVED_FMT, step.label or "")
        return self:ClearCustom()
    end
    self:SyncBlizz(self.target)
    ns:Fire("WAYPOINT_UPDATED", self.target)
end

--- Re-read the current step and recompute the target immediately.
function Waypoint:Update()
    local step = currentStep()
    if step ~= self.step then
        self.step = step
        self.failed = nil
        self:RefreshLabel()
    end
    if not step then
        self:StopTicker()
        self:SyncBlizz(nil)
        if self.target then
            self.target = nil
            ns:Fire("WAYPOINT_UPDATED", nil)
        end
        return
    end
    self.target = self:Compute(step)
    self:SyncBlizz(self.target)
    self:StartTicker()
    ns:Fire("WAYPOINT_UPDATED", self.target)
end

--- Lead the arrow to a place of the player's choice (uiMapID, x / y in percent, label shown with it;
-- ref: what the caller leads to, e.g. a quest id, kept in GetCustom().ref).
function Waypoint:SetCustom(map, x, y, label, ref)
    self.custom = { id = "atlas-target", custom = true, at = { map = map, x = x, y = y },
        radius = CUSTOM_RADIUS, label = label, ref = ref }
    self:Update()
    ns:Fire("WAYPOINT_CUSTOM", self.custom)
end

--- Back to the route step.
function Waypoint:ClearCustom()
    if not self.custom then return end
    self.custom = nil
    self:Update()
    ns:Fire("WAYPOINT_CUSTOM", nil)
end

function Waypoint:GetCustom() return self.custom end

local function update() Waypoint:Update() end
local function relabel()
    Waypoint:RefreshLabel()
    if Waypoint.target then Waypoint.target.label = Waypoint.label or "" end
end

ns:Listen("STEP_CHANGED", update)
ns:Listen("ROUTE_CHANGED", update)
ns:Listen("SETTINGS_CHANGED", update)
ns:Listen("QUEST_DATA_LOADED", relabel)
ns:Listen("ITEM_DATA_LOADED", relabel)
ns:Listen("PROGRESS_UPDATED", relabel) -- the label carries counts ("Collect ...: 4/6")
ns:On("PLAYER_ENTERING_WORLD", update)
