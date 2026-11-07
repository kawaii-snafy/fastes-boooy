-- Navigation math (ns.Compat.DistanceTo) with known mock geometry, the waypoint target of
-- the current step (ns.Waypoint), its ticker and the optional Blizzard user waypoint.
--
-- Mock geometry: Tirisfal Glades (1420) is 1000 x 1000 yards with its top-left corner at
-- world (0, 0); world X points north, world Y west; facing 0 = north, counter-clockwise.

local H = require("fixtures.core.helpers")

local m, ns
local pi = math.pi

local function near(want, got, eps, msg)
    assert.is_number(got, msg)
    assert.is_true(math.abs(want - got) < (eps or 1e-6), ("%s: want %s, got %s"):format(msg or "", want, got))
end

describe("waypoint math", function()
    before_each(function() m, ns = H.boot({ player = { mapID = 1420, x = 50, y = 50, facing = 0 } }) end)
    after_each(function() m:AssertClean() end)

    it("computes distance and angle relative to the facing (counter-clockwise, left > 0)", function()
        local C = ns.Compat
        local cases = {
            { 50, 40, 100, 0, "north" },
            { 60, 50, 100, -pi / 2, "east = right" },
            { 40, 50, 100, pi / 2, "west = left" },
            { 50, 60, 100, pi, "south" },
            { 60, 40, math.sqrt(2) * 100, -pi / 4, "north-east" },
            { 40, 60, math.sqrt(2) * 100, 3 * pi / 4, "south-west" },
        }
        for _, c in ipairs(cases) do
            local d, a, same, approx = C.DistanceTo(1420, c[1], c[2])
            near(c[3], d, 1e-6, c[5] .. " distance")
            near(c[4], a, 1e-9, c[5] .. " angle")
            assert.is_true(same)
            assert.is_false(approx)
        end
        m:SetFacing(pi / 2) -- facing west
        local _, a = C.DistanceTo(1420, 50, 40)
        near(-pi / 2, a, 1e-9, "north is to the right when facing west")
        m:SetFacing(pi)
        _, a = C.DistanceTo(1420, 50, 40)
        near(pi, a, 1e-9, "north is behind when facing south")
        _, a = C.DistanceTo(1420, 50, 60)
        near(0, a, 1e-9, "south is ahead when facing south")
        assert.equal(0, (C.DistanceTo(1420, 50, 50)))
    end)

    it("uses world coordinates across maps of the same continent", function()
        m:MoveTo(1458, 50, 50) -- Undercity: inside Tirisfal at 62 / 70
        local d, a, same = ns.Compat.DistanceTo(1420, 62, 60)
        near(100, d, 1e-6, "Undercity -> Tirisfal")
        near(0, a, 1e-9, "north")
        assert.is_true(same)
    end)

    it("has no distance to another continent", function()
        m:MoveTo(1411, 50, 50) -- Durotar (Kalimdor)
        local d, a, same = ns.Compat.DistanceTo(1420, 50, 40)
        assert.is_nil(d)
        assert.is_nil(a)
        assert.is_false(same)
    end)

    it("estimates distances on maps without a world transform (Zephras Isle)", function()
        m:MoveTo(2521, 50, 50)
        local d, a, same, approx = ns.Compat.DistanceTo(2521, 60, 50)
        near(200, d, 1e-6, "nominal 2000-yard map width")
        near(-pi / 2, a, 1e-9, "east")
        assert.is_true(same)
        assert.is_true(approx)
        assert.is_nil(ns.Compat.WorldPosFromMap(2521, 50, 50))
        assert.is_nil((ns.Compat.DistanceTo(1420, 50, 50)), "Tirisfal from the island")
    end)

    it("has no distance inside instances (no position)", function()
        m:EnterInstance("Ragefire Chasm", "party", 2437)
        assert.is_nil((ns.Compat.DistanceTo(1420, 50, 40)))
        assert.is_nil(ns.Compat.PlayerWorldPos())
        m:LeaveInstance(1420, 50, 50)
        near(100, (ns.Compat.DistanceTo(1420, 50, 40)), 1e-6, "after leaving")
    end)
end)

describe("waypoint target", function()
    after_each(function() m:AssertClean() end)

    it("targets the current step and updates on a ticker", function()
        m, ns = H.boot({ player = { mapID = 1420, x = 30.2, y = 81.7, facing = 0 } })
        local updates = H.record(ns, "WAYPOINT_UPDATED")
        local t = ns.Waypoint:GetTarget()
        assert.is_table(t)
        assert.equal(1420, t.map)
        assert.equal(30.2, t.x)
        assert.equal(71.7, t.y)
        near(100, t.distance, 1e-6, "10 % of the map south of the NPC")
        near(0, t.angle, 1e-9, "ahead")
        assert.is_true(t.sameContinent)
        assert.equal(12, t.radius)
        assert.equal("Accept: Rude Awakening", t.label)
        assert.equal("tr-accept-363", t.step.id)
        m:Advance(0.5)
        assert.is_true(#updates >= 4, "0.1 s ticker")
        m:MoveTo(1420, 30.2, 76.7)
        m:Advance(0.15)
        near(50, ns.Waypoint:GetTarget().distance, 1e-6, "recomputed")
        near(50, updates[#updates][1].distance, 1e-6, "payload")
    end)

    it("has no target for steps without a location", function()
        m, ns = H.boot()
        H.playTo(m, ns, "tr-level-2")
        local updates = H.record(ns, "WAYPOINT_UPDATED")
        assert.is_nil(ns.Waypoint:GetTarget())
        m:Advance(0.5)
        assert.equal(0, #updates, "no ticker without a target")
        m:SetLevel(2)
        H.settle(m)
        assert.is_table(ns.Waypoint:GetTarget(), "next step (accept 376) has a location")
        assert.equal("tr-accept-376", ns.Waypoint:GetTarget().step.id)
    end)

    it("places, moves and clears Blizzard's user waypoint when enabled", function()
        m, ns = H.boot()
        assert.is_nil(m.userWaypoint)
        ns.UI.SetSetting("blizzWaypoint", true)
        assert.equal(1420, m.userWaypoint.uiMapID)
        near(0.302, m.userWaypoint.x, 1e-9, "0..1 map fraction")
        near(0.717, m.userWaypoint.y, 1e-9, "0..1 map fraction")
        assert.equal(1, #m:Actions("SetUserWaypoint"))
        assert.is_true(m.superTrack.waypoint)
        m:AddQuestToLog(363)
        H.settle(m)
        near(0.308, m.userWaypoint.x, 1e-9, "moved to the next step")
        ns.UI.SetSetting("blizzWaypoint", false)
        assert.is_nil(m.userWaypoint)
        assert.is_false(m.superTrack.waypoint)
        -- a waypoint the user placed is never cleared
        ns.UI.SetSetting("blizzWaypoint", true)
        m.env.C_Map.SetUserWaypoint(m.env.UiMapPoint.CreateFromCoordinates(1420, 0.9, 0.9))
        ns.UI.SetSetting("blizzWaypoint", false)
        assert.is_table(m.userWaypoint)
        assert.equal(0.9, m.userWaypoint.x)
    end)
end)
