-- Shared library segments and class inserts in the real addon (Core/Compose.lua through
-- Core/Registry.lua and the public API) on the strict mock: composition order, registration
-- errors (reported once), lazy composition, data merge, and the engine on a composed route
-- (filters, bg, optional, forward limit, given-up quests, cursorHint by id, cold start).

local H = require("fixtures.core.helpers")
local Mock = H.Mock

local m, ns

local function E() return ns.Engine end

local function boot(opts)
    opts = opts or {}
    opts.composed = opts.composed ~= false and opts.fixture ~= false
    if opts.db == nil then opts.db = true end
    return H.boot(opts)
end

local function errorsMatching(pattern)
    local out = {}
    for _, e in ipairs(ns.Registry.errors) do
        if e:find(pattern) then out[#out + 1] = e end
    end
    return out
end

-- a library segment + a plain route, registered through the public API (fixture = false)
local function libSeg(id, steps, over)
    local def = { id = id, title = { en = id, ru = id }, zone = "Tirisfal Glades", levels = { 1, 5 }, steps = steps }
    for k, v in pairs(over or {}) do def[k] = v end
    return m.env.AdventureAtlas.AddLibrarySegment(def)
end

local function route(id, segSteps)
    local FB = m.env.AdventureAtlas
    local r = FB.RegisterRoute({ api = 1, id = id, title = "Route " .. id, faction = "Horde", races = { "Scourge" },
        classes = { "PALADIN" }, levels = { 1, 60 } })
    if segSteps then FB.AddSegment(id, { id = id .. "-own", title = "Own", steps = segSteps }) end
    return r
end

describe("core composition (library segments, UseSegments, AddInsert)", function()
    after_each(function()
        if m then m:AssertClean() end
        m, ns = nil, nil
    end)

    it("composes the fixture route: own segments, library segments, inserts, data", function()
        m, ns = boot()
        local R = ns.Registry
        assert.same({}, R.errors)
        local r = R:Get(H.COMPOSED_ID)
        assert.is_table(r.own, "composed")
        local ids, segs = {}, {}
        for i, s in ipairs(r.steps) do
            ids[i] = s.id
            segs[i] = s.segment
            assert.equal(i, s.index)
            assert.equal(s, r.stepById[s.id])
        end
        local wantIds, wantSegs = {}, {}
        for i, e in ipairs(H.COMPOSED_ALL) do wantIds[i], wantSegs[i] = e[1], e[2] end
        assert.same(wantIds, ids)
        assert.same(wantSegs, segs, "inserted steps belong to the anchor's segment")
        assert.same({ "tc-intro", "tl-deathknell", "tc-class", "tl-brill" }, H.ids(r.segments))
        local dk = r.segmentById["tl-deathknell"]
        assert.equal(3, dk.first)
        assert.equal(15, dk.last)
        assert.is_true(dk.library)
        assert.is_true(r.stepById["tl-363-364"].library)
        assert.is_nil(r.stepById["tc-train-1"].library)
        assert.is_true(r.stepById["tc-train-1"].inserted)
        assert.equal("tl-363-364", r.stepById["tc-train-1"].anchor)
        -- the route's own segment list is untouched by the composition
        assert.same({ "tc-intro", "tc-class" }, H.ids(r.own.segments))
        assert.same({ "tc-intro-go", "tc-train-4" }, H.ids(r.own.steps))
        -- library data under the route's data (Data.lua of both modules)
        assert.equal("Rude Awakening", R:Lookup(r, "quests", 363))
        assert.equal("Joshua Kien", R:Lookup(r, "npcs", 2115))
        assert.equal("Undertaker Mordo", R:Lookup(r, "npcs", 1568))
        assert.equal(159, R:PlaceArea(r, "Brill"))
        -- the library is not a route
        assert.same({ H.COMPOSED_ID }, H.ids(R:List()))
        assert.equal(3, #R.library.order)
    end)

    it("plays across own, library and inserted steps with the engine filters", function()
        m, ns = boot()
        assert.equal(H.COMPOSED_ID, E():GetRoute().id)
        assert.same(H.COMPOSED_IDS, H.ids(E():GetSteps()))
        assert.is_nil(E():IndexOf("tc-warrior-only"), "class filter of an insert")
        assert.equal("tc-welcome", H.cur(ns))
        E():Next()
        H.settle(m)
        assert.equal("tc-intro-go", H.cur(ns))
        H.playTo(m, ns, "tc-vendor-1")
        assert.equal("tc-vendor-1", H.cur(ns), "inserts at one anchor keep call order")
        H.playTo(m, ns, "tl-complete-3901")
        assert.same({ "tl-bg-376" }, H.ids(E():GetBackground()), "bg step of a library segment")
        H.playTo(m, ns, "tc-train-4")
        assert.equal("tc-train-4", H.cur(ns), "own segment placed between library segments")
        H.playTo(m, ns, "tl-go-brill")
        assert.is_true(E():IsDone("tl-optional"), "optional library step forwarded by a later anchor")
        H.playTo(m, ns, "tl-sethearth")
        H.perform(m, ns, E():GetCurrentStep())
        H.settle(m)
        assert.is_nil(E():GetCursor(), "route finished")
    end)

    it("restores the cursor by step id after /reload and rebuilds it on a cold start", function()
        m, ns = boot()
        H.playTo(m, ns, "tl-turnin-376")
        local cdb = m.env.AdventureAtlasCharDB
        assert.equal("tl-turnin-376", cdb.cursorHintId)
        assert.equal(H.COMPOSED_ID, cdb.cursorHintRoute)
        local m2, ns2 = H.reload(m, { composed = true })
        assert.equal("tl-turnin-376", H.cur(ns2), "/reload: cursorHint by id")
        m2:AssertClean()
        -- empty SavedVariables: the quest log decides; the transient inserts before the last done
        -- library anchor (tc-train-1, tc-vendor-1, the go insert) are forwarded
        local m3, ns3 = H.reload(m, { composed = true, coldStart = true })
        assert.equal("tl-turnin-376", H.cur(ns3))
        assert.is_true(ns3.Engine:IsDone("tc-train-1"))
        assert.is_true(ns3.Engine:IsDone("tl-turnin-3901+1"))
        m3:AssertClean()
    end)

    it("gives up a quest of a library segment that the player abandons", function()
        m, ns = boot()
        local cdb = m.env.AdventureAtlasCharDB
        H.playTo(m, ns, "tl-complete-3901")
        m:AbandonQuest(3901)
        H.settle(m, 1)
        -- its complete / turn-in steps are skipped; the transient insert between them still waits
        assert.equal("tl-turnin-3901+1", H.cur(ns))
        assert.is_true(cdb.skipped["tl-complete-3901"])
        assert.is_true(cdb.skipped["tl-turnin-3901"])
        assert.same({ accept = "tl-turnin-364", steps = { "tl-complete-3901", "tl-turnin-3901" } }, cdb.gaveUp[3901])
        assert.is_nil(E():GetAcceptQuests()[3901], "a given-up quest is not auto-accepted again")
        H.perform(m, ns, E():GetCurrentStep())
        H.settle(m)
        assert.equal("tl-turnin-376", H.cur(ns))
    end)

    it("reports a missing library segment and an unknown anchor once", function()
        m, ns = boot({ fixture = false })
        local FB = m.env.AdventureAtlas
        libSeg("lib-a", { { id = "lib-a-1", accept = 363 }, { id = "lib-a-2", turnin = 363 } })
        route("r1", { { id = "r1-go", go = true, at = { 1420, 30, 70 } } })
        assert.is_true(FB.UseSegments("r1", { "lib-a", "lib-missing" }))
        assert.is_table(FB.AddInsert("r1", { after = "nope", steps = { { id = "r1-x", manual = true } } }))
        assert.same({}, ns.Registry.errors, "composition is lazy")
        local r = ns.Registry:Get("r1")
        assert.same({ "r1-go", "lib-a-1", "lib-a-2" }, H.ids(r.steps))
        assert.equal(1, #errorsMatching("unknown shared segment 'lib%-missing'"))
        assert.equal(1, #errorsMatching("unknown anchor step 'nope'"))
        assert.matches("^route r1: UseSegments: unknown shared segment 'lib%-missing' %(is its file listed in the TOC before "
            .. "Route%.lua%?%)", ns.Registry.errors[1])
        -- another change recomposes the route; the same errors are not recorded again
        FB.AddInsert("r1", { before = "lib-a-2", steps = { { id = "r1-y", manual = true } } })
        r = ns.Registry:Get("r1")
        assert.same({ "r1-go", "lib-a-1", "r1-y", "lib-a-2" }, H.ids(r.steps))
        assert.equal(2, #ns.Registry.errors)
        m:Advance(1)
    end)

    it("composes only the routes the character can use; the others when listed or chosen", function()
        m, ns = boot({ fixture = false })
        local FB = m.env.AdventureAtlas
        libSeg("lib-a", { { id = "lib-a-1", accept = 363 }, { id = "lib-a-2", turnin = 363 } })
        route("rp")
        FB.UseSegments("rp", { "lib-a" })
        FB.RegisterRoute({ api = 1, id = "rd", title = "Route rd", faction = "Horde", races = { "Skyborne" },
            classes = { "DRUID" }, levels = { 1, 60 } })
        FB.UseSegments("rd", { "lib-a" })
        local R = ns.Registry
        H.settle(m)
        assert.equal("rp", E():GetRoute().id, "the paladin route is selected (and composed)")
        assert.is_falsy(R.routes.rp.dirty)
        assert.is_true(R.routes.rd.dirty, "the druid route is not composed for a paladin")
        assert.equal(0, #R.routes.rd.steps)
        -- listed (/aa routes, settings) or chosen: composed then
        assert.same({ "lib-a-1", "lib-a-2" }, H.ids(R:Get("rd").steps))
        assert.is_falsy(R.routes.rd.dirty)
        assert.same({}, R.errors)
    end)

    it("reports duplicate step ids after composition, duplicate library segments and bad definitions", function()
        m, ns = boot({ fixture = false })
        local FB = m.env.AdventureAtlas
        local R = ns.Registry
        libSeg("lib-a", { { id = "lib-a-1", accept = 363 } })
        assert.is_nil(libSeg("lib-a", { { id = "other", accept = 364 } }))
        assert.equal(1, #errorsMatching("^library: segment lib%-a: registered twice"))
        libSeg("lib-b", { { id = "lib-a-1", accept = 364 } })
        assert.equal(1, #errorsMatching("^library: segment lib%-b step 1: duplicate step id 'lib%-a%-1'"))
        libSeg("lib-c", { { bogus = true } })
        assert.equal(1, #errorsMatching("^library: segment lib%-c step 1: unknown step key 'bogus'"))
        -- own step id = library step id; insert id = own step id
        route("r2", { { id = "lib-a-1", go = true, at = { 1420, 30, 70 } }, { id = "r2-2", manual = true } })
        FB.UseSegments("r2", { "lib-a" })
        FB.AddInsert("r2", { after = "r2-2", steps = { { id = "r2-2", manual = true } } })
        R:Get("r2")
        assert.equal(1, #errorsMatching("^route r2: duplicate step id 'lib%-a%-1' after composition"))
        assert.equal(1, #errorsMatching("^route r2: duplicate step id 'r2%-2' after composition"))
        -- invalid UseSegments / AddInsert definitions
        local n = #R.errors
        assert.is_false(FB.UseSegments("r2", {}))
        assert.is_false(FB.UseSegments("r2", { 42 }))
        assert.is_nil(FB.AddInsert("r2", { after = "r2-2", before = "r2-2", steps = { { manual = true } } }))
        assert.is_nil(FB.AddInsert("r2", { steps = { { manual = true } } }))
        assert.is_nil(FB.AddInsert("r2", { after = "r2-2", steps = {} }))
        assert.is_nil(FB.AddInsert("r2", "nope"))
        FB.AddInsert("r2", { after = "r2-2", foo = 1, steps = { { bad = 1, manual = true } } })
        local list = {}
        for i = n + 1, #R.errors do list[#list + 1] = R.errors[i] end
        local all = table.concat(list, "\n")
        assert.matches("UseSegments: segment ids must be a non%-empty list", all)
        assert.matches("UseSegments: entry 1 is not a segment id", all)
        assert.matches("give either `after` or `before`, not both", all)
        assert.matches("`after = \"<stepId>\"` or `before = \"<stepId>\"` is required", all)
        assert.matches("insert after 'r2%-2': steps must be a non%-empty list", all)
        assert.matches("insert: insert definition must be a table", all)
        assert.matches("insert after 'r2%-2': unknown key 'foo'", all)
        assert.matches("insert after 'r2%-2' step 1: unknown step key 'bad'", all)
        assert.is_false(FB.AddLibraryData("nope"))
        assert.matches("AddLibraryData: data must be a table", R.errors[#R.errors])
        m:Advance(1)
    end)

    it("queues UseSegments / AddInsert called before RegisterRoute (with an error)", function()
        m, ns = boot({ fixture = false })
        local FB = m.env.AdventureAtlas
        local R = ns.Registry
        libSeg("lib-q", { { id = "lib-q-1", accept = 363 }, { id = "lib-q-2", turnin = 363 } })
        assert.is_false(FB.UseSegments("late", { "lib-q" }))
        assert.is_nil(FB.AddInsert("late", { after = "lib-q-1", steps = { { id = "late-x", manual = true } } }))
        assert.is_false(FB.UseSegments(42, { "lib-q" }))
        assert.equal(3, #R.errors)
        assert.matches("^UseSegments: route late is not registered yet %(RegisterRoute must come first%)", R.errors[1])
        assert.matches("^AddInsert: route late is not registered yet", R.errors[2])
        assert.matches("^UseSegments: invalid route id 42", R.errors[3])
        route("late")
        local r = R:Get("late")
        assert.same({ "lib-q-1", "late-x", "lib-q-2" }, H.ids(r.steps), "the queued calls were applied")
        assert.equal(3, #R.errors)
        m:Advance(1)
    end)

    it("resolves inserts lazily: before UseSegments, at steps of other inserts, call order per anchor", function()
        m, ns = boot({ fixture = false })
        local FB = m.env.AdventureAtlas
        libSeg("lib-o", { { id = "o1", accept = 363 }, { id = "o2", turnin = 363 } })
        route("r3", { { id = "own1", go = true, at = { 1420, 30, 70 } } })
        -- registered before UseSegments, anchored at a library step
        FB.AddInsert("r3", { after = "o1", steps = { { id = "a1", manual = true }, { manual = true } } })
        -- anchored at a step of an insert registered later
        FB.AddInsert("r3", { after = "c1", steps = { { id = "d1", manual = true } } })
        FB.AddInsert("r3", { before = "o2", steps = { { id = "c1", manual = true } } })
        FB.AddInsert("r3", { before = "o2", steps = { { manual = true } } })
        FB.AddInsert("r3", { after = "o1", steps = { { id = "b1", manual = true } } })
        FB.AddInsert("r3", { before = "own1", steps = { { manual = true } } })
        FB.UseSegments("r3", { "lib-o" })
        local r = ns.Registry:Get("r3")
        assert.same({}, ns.Registry.errors)
        assert.same({ "own1+1", "own1", "o1", "a1", "o1+2", "b1", "c1", "d1", "o2+2", "o2" }, H.ids(r.steps))
        assert.equal("lib-o", r.stepById["c1"].segment)
        assert.equal("r3-own", r.stepById["own1+1"].segment)
        m:Advance(1)
    end)

    it("keeps routes without UseSegments / AddInsert as they were and shares library segments between routes", function()
        m, ns = boot({ fixture = false })
        local FB = m.env.AdventureAtlas
        local plain = route("plain", { { id = "p1", accept = 363 } })
        assert.is_nil(plain.own)
        local steps = plain.steps
        assert.equal(steps, ns.Registry:Get("plain").steps, "no recomposition")
        libSeg("lib-s", { { id = "s1", accept = 364 }, { id = "s2", turnin = 364 } })
        FB.AddLibraryData({ quests = { [364] = "Library name", [365] = "Only in the library" } })
        route("ra", { { id = "ra1", accept = 363 } })
        route("rb", { { id = "rb1", accept = 363 }, { id = "rb2", turnin = 363 } })
        FB.AddRouteData("ra", { quests = { [364] = "Route name" } })
        FB.UseSegments("ra", { "lib-s" })
        FB.UseSegments("rb", { "lib-s" })
        local ra, rb = ns.Registry:Get("ra"), ns.Registry:Get("rb")
        assert.equal(2, ra.stepById.s1.index)
        assert.equal(3, rb.stepById.s1.index)
        assert.are_not.equal(ra.stepById.s1, rb.stepById.s1, "per-route step copies")
        assert.equal(ra.stepById.s1.actions, rb.stepById.s1.actions, "normalized once")
        assert.equal("Route name", ns.Registry:Lookup(ra, "quests", 364), "the route's own data wins")
        assert.equal("Only in the library", ns.Registry:Lookup(ra, "quests", 365))
        assert.equal("Library name", ns.Registry:Lookup(rb, "quests", 364))
        assert.is_nil(ns.Registry:Lookup(plain, "quests", 365), "a plain route gets no library data")
        assert.same({}, ns.Registry.errors)
        -- a library segment added later recomposes the routes that use it
        local rev = rb.revision
        libSeg("lib-later", { { id = "l1", accept = 365 } })
        FB.UseSegments("rb", { "lib-later" })
        assert.same({ "rb1", "rb2", "s1", "s2", "l1" }, H.ids(ns.Registry:Get("rb").steps))
        assert.is_true(rb.revision > rev)
    end)

    it("activates a composed route module loaded after login", function()
        m, ns = boot({ fixture = false })
        assert.is_nil(E():GetRoute())
        Mock.loadAddon(m, H.LIB_TOC, H.LIB_NAME)
        m:Fire("ADDON_LOADED", H.LIB_NAME, false)
        Mock.loadAddon(m, H.COMPOSED_TOC, H.COMPOSED_NAME)
        m:Fire("ADDON_LOADED", H.COMPOSED_NAME, false)
        H.settle(m)
        assert.equal(H.COMPOSED_ID, E():GetRoute().id)
        assert.same(H.COMPOSED_IDS, H.ids(E():GetSteps()))
        assert.equal("tc-welcome", H.cur(ns))
        assert.same({}, ns.Registry.errors)
    end)

    it("treats a bar fraction of the level cap as reached (no XP at 60)", function()
        m, ns = boot({ fixture = false, player = { level = 60, xp = 0 } })
        route("cap", { { id = "cap-1", level = { 60, 0.5 } }, { id = "cap-2", manual = true } })
        E():SetRoute("cap")
        H.settle(m)
        assert.is_true(E():IsDone("cap-1"))
        assert.equal("cap-2", H.cur(ns))
    end)
end)
