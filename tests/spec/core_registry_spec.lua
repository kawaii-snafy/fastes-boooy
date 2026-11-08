-- Route registration (public API), registry errors, route selection and the route
-- the engine activates at login. Real addon + test route module on the strict mock.

local H = require("fixtures.core.helpers")
local Mock = H.Mock

local m, ns

local function addRoute(id, over, nsteps)
    local FastesBoooy = m.env.FastesBoooy
    local def = { api = 1, id = id, title = { en = "Route " .. id, ru = "Маршрут " .. id }, faction = "Horde",
        races = { "Scourge" }, classes = { "PALADIN" }, levels = { 1, 10 } }
    for k, v in pairs(over or {}) do def[k] = v end
    local r = FastesBoooy.RegisterRoute(def)
    if (nsteps or 1) > 0 then
        FastesBoooy.AddSegment(id, { id = id .. "-s", title = "S", steps = { { accept = 363 }, { accept = 364 } } })
    end
    return r
end

describe("core registry", function()
    after_each(function()
        if m then m:AssertClean() end
        m, ns = nil, nil
    end)

    it("registers the test route module with its data and no errors", function()
        m, ns = H.boot({ locale = "ruRU" })
        local R = ns.Registry
        assert.same({}, R.errors)
        local route = R:Get("test-route")
        assert.is_table(route)
        assert.same({ "test-route" }, H.ids(R:List()))
        assert.equal(3, #route.segments)
        assert.equal(29, #route.steps)
        assert.equal(3, route.revision)
        assert.equal("Брилл", R:Lookup(route, "places", "Brill"))
        assert.equal("Грубое пробуждение", R:Lookup(route, "quests", 363))
        assert.equal("Крыло сумеречной мыши", R:Lookup(route, "items", 3264))
        assert.is_nil(R:Lookup(route, "places", "Nowhere"))
        assert.is_nil(R:Get(nil))
        assert.is_nil(R:Get("nope"))
    end)

    it("exposes the public API table as the only core global", function()
        m, ns = H.boot()
        local pub = m.env.FastesBoooy
        assert.equal(ns.public, pub)
        assert.equal(1, pub.API_VERSION)
        assert.equal(1, pub.API_MINOR) -- library segments / UseSegments / AddInsert (core 0.2.0)
        assert.equal("0.2.0", pub.version)
        assert.equal("test-route", pub.GetActiveRoute().id)
        assert.equal("tr-accept-363", pub.GetCurrentStep().id)
        assert.same({ "FastesBoooy", "FastesBoooyCharDB", "FastesBoooyDB", "SLASH_FASTESBOOOY1", "SLASH_FASTESBOOOY2" },
            m:AddonGlobals())
        assert.is_function(m.env.SlashCmdList.FASTESBOOOY)
    end)

    it("selects the matching route at login and announces it", function()
        m, ns = H.boot()
        assert.equal("test-route", ns.Engine:GetRoute().id)
        assert.is_true(H.chatHas(m, "Route: Test route"))
        local R = ns.Registry
        assert.equal("test-route", R:Select({ race = "Scourge", class = "PALADIN", faction = "Horde", level = 1 }).id)
        assert.is_nil(R:Select({ race = "Orc", class = "WARRIOR", faction = "Horde", level = 1 }))
        assert.is_nil(R:Select({ race = "Scourge", class = "PALADIN", faction = "Alliance", level = 1 }))
    end)

    it("activates no route for a character no route matches", function()
        m, ns = H.boot({ player = { race = "Orc", class = "WARRIOR" } })
        assert.is_nil(ns.Engine:GetRoute())
        assert.is_nil(ns.Engine:GetCursor())
        assert.same({}, ns.Engine:GetSteps())
        assert.is_true(H.chatHas(m, "No route matches this character."))
    end)

    it("prefers default routes, then a level range containing the level, then registration order", function()
        m, ns = H.boot({ fixture = false })
        addRoute("plain-low", { levels = { 1, 10 } })
        addRoute("plain-high", { levels = { 20, 30 } })
        local R = ns.Registry
        local facts = { race = "Scourge", class = "PALADIN", faction = "Horde", level = 5 }
        assert.equal("plain-low", R:Select(facts).id)
        facts.level = 25
        assert.equal("plain-high", R:Select(facts).id)
        facts.level = 40 -- past both: registration order
        assert.equal("plain-low", R:Select(facts).id)
        addRoute("default-high", { levels = { 20, 30 }, default = true })
        facts.level = 5
        assert.equal("default-high", R:Select(facts).id)
        addRoute("empty", { default = true, levels = { 1, 10 } }, 0)
        assert.equal("default-high", R:Select(facts).id, "routes without steps are never selected")
        assert.same({ "plain-low", "plain-high", "default-high" }, H.ids(R:Matching(facts)))
    end)

    it("activates a route module registered after login", function()
        m, ns = H.boot({ fixture = false })
        assert.is_nil(ns.Engine:GetRoute())
        local changed = H.record(ns, "ROUTE_CHANGED")
        Mock.loadAddon(m, H.FIXTURE_TOC, H.FIXTURE_NAME)
        m:Fire("ADDON_LOADED", H.FIXTURE_NAME, false)
        H.settle(m)
        assert.equal("test-route", ns.Engine:GetRoute().id)
        assert.equal("tr-accept-363", H.cur(ns))
        assert.is_true(#changed >= 1)
    end)

    it("records format errors instead of raising and queues segments added too early", function()
        m, ns = H.boot({ fixture = false })
        local R = ns.Registry
        local FastesBoooy = m.env.FastesBoooy
        -- segment and data before the route
        assert.is_nil(FastesBoooy.AddSegment("late", { id = "late-s", title = "S", steps = { { accept = 1 } } }))
        assert.is_false(FastesBoooy.AddRouteData("late", { quests = { [1] = "One" } }))
        assert.equal(2, #R.errors)
        assert.matches("RegisterRoute must come first", R.errors[1])
        local r = addRoute("late", nil, 0)
        assert.is_table(r)
        assert.equal(1, #r.steps, "the queued segment was applied")
        assert.equal("One", R:Lookup(r, "quests", 1))
        -- duplicate route, invalid definitions
        assert.is_nil(FastesBoooy.RegisterRoute({ api = 1, id = "late", title = "again" }))
        assert.matches("registered twice", R.errors[#R.errors])
        local n = #R.errors
        assert.is_nil(FastesBoooy.RegisterRoute({ api = 2, title = "broken" }))
        assert.is_true(#R.errors > n)
        assert.is_false(FastesBoooy.AddRouteData("late", "nope"))
        assert.matches("data must be a table", R.errors[#R.errors])
        n = #R.errors
        FastesBoooy.AddSegment("late", { id = "bad", title = "Bad", steps = { { foo = 1 } } })
        assert.is_true(#R.errors > n)
        assert.matches("^route late: segment bad step 1", R.errors[#R.errors])
        m:Advance(1)
    end)

    it("keeps the chosen route per character across a reload", function()
        m, ns = H.boot()
        addRoute("other")
        H.settle(m)
        assert.is_true(ns.Engine:SetRoute("other"))
        assert.equal("other", ns.Engine:GetRoute().id)
        assert.equal("other", m.env.FastesBoooyCharDB.route)
        assert.is_false(ns.Engine:SetRoute("does-not-exist"))
        assert.is_true(H.chatHas(m, "Unknown route: does-not-exist"))
        assert.equal("other", ns.Engine:GetRoute().id)
        -- the route module "other" is registered by the spec, not by a TOC: re-register after reload
        local sv = m:ExportSavedVariables()
        assert.equal("other", sv.FastesBoooyCharDB.route)
        assert.is_true(ns.Engine:SetRoute(nil))
        assert.equal("test-route", ns.Engine:GetRoute().id)
        assert.is_nil(m.env.FastesBoooyCharDB.route)
    end)
end)
