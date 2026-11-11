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
        assert.equal(2, pub.API_MINOR) -- AddLibraryInsert, route aliases, class reward table (core 0.4.0)
        assert.is_function(pub.AddLibraryInsert)
        assert.equal("0.4.0", pub.version)
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

    it("reports a bad reward entry of queued route data once (not again when RegisterRoute merges it)", function()
        m, ns = H.boot({ fixture = false })
        local R = ns.Registry
        local FastesBoooy = m.env.FastesBoooy
        assert.is_false(FastesBoooy.AddRouteData("rw", { quests = { [380] = "Q" },
            rewards = { PALADIN = { [380] = 0, [381] = 2 } } }))
        assert.same({
            "AddRouteData rw: rewards.PALADIN[380]: the choice must be a positive integer (got 0)",
            "AddRouteData: route rw is not registered yet (RegisterRoute must come first)",
        }, R.errors)
        local r = addRoute("rw", nil, 0)
        assert.is_table(r)
        assert.equal(2, #R.errors, "the flush of the queue reports nothing new")
        -- the queued data was merged as given (the engine ignores the bad entry)
        assert.equal("Q", R:Lookup(r, "quests", 380))
        assert.same({ [380] = 0, [381] = 2 }, r.data.rewards.PALADIN)
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

    it("route aliases: Registry:Get resolves a former id; conflicts are errors and the alias is ignored", function()
        m, ns = H.boot({ fixture = false })
        local R = ns.Registry
        local a = addRoute("new-a", { aliases = "old-a" })
        local b = addRoute("new-b", { aliases = { "old-b", "older-b", "old-b" } })
        assert.same({}, R.errors)
        assert.same({ "old-a" }, a.aliases)
        assert.same({ "old-b", "older-b" }, b.aliases)
        assert.equal(a, R:Get("old-a"))
        assert.equal(b, R:Get("old-b"))
        assert.equal(b, R:Get("older-b"))
        assert.equal(a, R:Get("new-a"))
        assert.same({ "new-a", "new-b" }, H.ids(R:List()), "an alias is not a route of its own")
        -- an alias that is a registered route id, an alias already taken
        local c = addRoute("new-c", { aliases = { "new-a", "old-b", "old-c" } })
        assert.same({
            "route new-c: alias 'new-a' is the id of a registered route (alias ignored)",
            "route new-c: alias 'old-b' is already used by route new-b (alias ignored)",
        }, R.errors)
        assert.equal(a, R:Get("new-a"))
        assert.equal(b, R:Get("old-b"))
        assert.equal(c, R:Get("old-c"))
        -- a route registered later under a former id of another route: the route id wins
        local d = addRoute("old-a")
        assert.equal("route old-a: its id is an alias of route new-a (alias ignored)", R.errors[3])
        assert.equal(d, R:Get("old-a"))
        -- format errors (Schema.NormalizeRoute)
        addRoute("new-e", { aliases = { "bad id", 5, "new-e" } })
        assert.matches("^route new%-e: aliases%[1%] must be a route id", R.errors[4])
        assert.matches("^route new%-e: aliases%[2%] must be a route id", R.errors[5])
        assert.equal("route new-e: alias 'new-e' is the id of the route itself", R.errors[6])
        assert.equal(6, #R.errors)
        m:Advance(1)
    end)

    it("saved progress follows a renamed route: manual choice, high-water mark, sync floor, dismissal", function()
        local function register(api)
            api.RegisterRoute({ api = 1, id = "new-id", title = "Renamed", faction = "Horde", races = { "Scourge" },
                classes = { "PALADIN" }, levels = { 1, 10 }, aliases = "old-id" })
            api.AddSegment("new-id", { id = "seg", title = "S", steps = {
                { id = "a-1", manual = true }, { id = "a-2", manual = true }, { id = "a-3", manual = true },
                { id = "a-4", manual = true },
            } })
        end
        local function saved()
            return { FastesBoooyCharDB = {
                route = "old-id", cursorHint = 3, cursorHintId = "a-3", cursorHintRoute = "old-id",
                syncFloor = { route = "old-id", stepId = "a-2", from = "seg", to = "seg", level = 1,
                    hint = { 1, "a-1", "old-id" },
                    prev = { route = "old-id", stepId = "a-1", hint = { 1, "a-1", "old-id" } } },
                syncDismissed = { route = "old-id", segment = "seg", level = 1 },
            } }
        end
        m, ns = H.boot({ fixture = false, register = register, savedVariables = saved() })
        local cdb = m.env.FastesBoooyCharDB
        assert.equal("new-id", ns.Engine:GetRoute().id)
        assert.equal("new-id", cdb.route)
        assert.equal("new-id", cdb.cursorHintRoute)
        assert.equal("a-3", H.cur(ns), "the high-water mark of the old id is kept")
        assert.equal("new-id", cdb.syncFloor.route)
        assert.equal("new-id", cdb.syncFloor.hint[3])
        assert.equal("new-id", cdb.syncFloor.prev.route)
        assert.equal("new-id", cdb.syncFloor.prev.hint[3])
        assert.equal(cdb.syncFloor, ns.Engine:GetSyncFloor(), "the floor is the active route's again")
        assert.equal("new-id", cdb.syncDismissed.route)
        assert.same({}, ns.Registry.errors)
        m:AssertClean()

        -- without the alias the old records are ignored (and left alone): the route starts over
        local m2, ns2 = H.boot({ fixture = false, savedVariables = saved(), register = function(api)
            api.RegisterRoute({ api = 1, id = "new-id", title = "Renamed", faction = "Horde", races = { "Scourge" },
                classes = { "PALADIN" }, levels = { 1, 10 } })
            api.AddSegment("new-id", { id = "seg", title = "S", steps = {
                { id = "a-1", manual = true }, { id = "a-2", manual = true }, { id = "a-3", manual = true },
            } })
        end })
        assert.equal("new-id", ns2.Engine:GetRoute().id)
        assert.equal("a-1", H.cur(ns2))
        assert.equal("old-id", m2.env.FastesBoooyCharDB.route)
        assert.equal("old-id", m2.env.FastesBoooyCharDB.syncFloor.route)
        assert.is_nil(ns2.Engine:GetSyncFloor())
        m2:AssertClean()

        -- choosing a route by its former id saves the current id
        assert.is_true(ns.Engine:SetRoute(nil))
        assert.is_nil(cdb.route)
        assert.is_true(ns.Engine:SetRoute("old-id"))
        assert.equal("new-id", cdb.route)
        assert.equal("new-id", ns.Engine:GetRoute().id)
    end)

    it("Registry:List(true) lists every route without composing; List() composes them", function()
        m, ns = H.boot({ fixture = false })
        local FastesBoooy = m.env.FastesBoooy
        local R = ns.Registry
        FastesBoooy.AddLibrarySegment({ id = "lib", title = "L", steps = { { id = "l-1", accept = 363 } } })
        for _, class in ipairs({ "PALADIN", "WARRIOR", "MAGE" }) do
            addRoute("r-" .. class, { classes = { class } }, 0)
            FastesBoooy.UseSegments("r-" .. class, { "lib" })
        end
        addRoute("plain") -- not composed at all (no UseSegments / AddInsert)
        H.settle(m)
        assert.equal("r-PALADIN", ns.Engine:GetRoute().id)
        local list = R:List(true)
        assert.same({ "r-PALADIN", "r-WARRIOR", "r-MAGE", "plain" }, H.ids(list))
        assert.is_true(R.routes["r-WARRIOR"].dirty)
        assert.is_true(R.routes["r-MAGE"].dirty)
        assert.equal(0, #R.routes["r-MAGE"].steps)
        assert.is_true(R:IsComposed(R.routes["r-PALADIN"]))
        assert.is_false(R:IsComposed(R.routes["r-WARRIOR"]))
        assert.is_true(R:IsComposed(R.routes.plain))
        list[1] = nil -- a copy: the registry's own order is not the returned table
        assert.equal(4, #R.order)
        assert.same({ "r-PALADIN", "r-WARRIOR", "r-MAGE", "plain" }, H.ids(R:List()))
        assert.is_falsy(R.routes["r-WARRIOR"].dirty)
        assert.equal(1, #R.routes["r-MAGE"].steps)
        assert.is_true(R:IsComposed(R.routes["r-MAGE"]))
    end)
end)
