-- Shared inserts (FastesBoooy.AddLibraryInsert) and the pruning of shared steps by route scope
-- in the real addon (Core/Compose.lua through Core/Registry.lua and the public API) on the strict
-- mock: where an insert applies, scope, order, chains, registration and composition errors,
-- per-route copies, late registration, the engine on shared-insert steps, and the mixed fixture
-- module FastesBoooy_TestGuides (shared segments + shared inserts + several routes).

local H = require("fixtures.core.helpers")

local m, ns

local format = string.format

local function E() return ns.Engine end
local function FB() return m.env.FastesBoooy end

-- default: no route module (the routes are registered through the public API after login)
local function boot(opts)
    opts = opts or {}
    if not opts.guides and opts.fixture == nil then opts.fixture = false end
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

local function libSeg(id, steps)
    return FB().AddLibrarySegment({ id = id, title = { en = id, ru = id }, zone = "Tirisfal Glades", levels = { 1, 5 },
        steps = steps })
end

-- RegisterRoute + UseSegments; scope = { races = , classes = , faction = } (default Scourge PALADIN Horde;
-- `false` leaves a dimension out)
local function route(id, uses, scope)
    scope = scope or {}
    local def = { api = 1, id = id, title = "Route " .. id, levels = { 1, 60 } }
    if scope.faction ~= false then def.faction = scope.faction or "Horde" end
    if scope.races ~= false then def.races = scope.races or { "Scourge" } end
    if scope.classes ~= false then def.classes = scope.classes or { "PALADIN" } end
    local r = FB().RegisterRoute(def)
    if uses then FB().UseSegments(id, uses) end
    return r
end

local function ids(routeId)
    return H.ids(ns.Registry:Get(routeId).steps)
end

local function manual(id, over)
    local s = { id = id, manual = true }
    for k, v in pairs(over or {}) do s[k] = v end
    return s
end

describe("shared inserts (AddLibraryInsert)", function()
    after_each(function()
        if m then m:AssertClean() end
        m, ns = nil, nil
    end)

    it("apply to every route that contains the anchor; other routes and plain routes are untouched", function()
        m, ns = boot()
        libSeg("tf", { { id = "tf-1", accept = 363 }, { id = "tf-2", turnin = 363 } })
        libSeg("du", { { id = "du-1", accept = 4641 }, { id = "du-2", turnin = 4641 } })
        route("ud-pal", { "tf" })
        route("ud-pal-2", { "tf" })
        route("orc-war", { "du" }, { races = { "Orc" }, classes = { "WARRIOR" } })
        -- a plain route, and a composed route that uses no shared segment: both hold an own step "tf-1"
        local plain = route("plain")
        FB().AddSegment("plain", { id = "plain-own", title = "Own", steps = { { id = "tf-1", accept = 364 } } })
        route("own-only")
        FB().AddSegment("own-only", { id = "oo", title = "Own", steps = { { id = "tf-1", accept = 364 } } })
        FB().AddInsert("own-only", { after = "tf-1", steps = { { manual = true } } })
        local plainSteps = plain.steps

        local ins = FB().AddLibraryInsert({ after = "tf-1", steps = { manual("x-1") } })
        assert.is_table(ins)
        assert.same({ "tf-1", "x-1", "tf-2" }, ids("ud-pal"))
        assert.same({ "tf-1", "x-1", "tf-2" }, ids("ud-pal-2"))
        assert.same({ "du-1", "du-2" }, ids("orc-war"), "no anchor: nothing, and no error")
        assert.is_nil(plain.own)
        assert.equal(plainSteps, ns.Registry:Get("plain").steps, "a plain route is never touched")
        assert.same({ "tf-1" }, ids("plain"))
        assert.same({ "tf-1", "tf-1+1" }, ids("own-only"), "no UseSegments: shared inserts do not apply")
        assert.equal("tf", ns.Registry:Get("ud-pal").stepById["x-1"].segment, "the anchor's segment")
        assert.same({ ["ud-pal"] = true, ["ud-pal-2"] = true }, ins.applied)
        -- a route's copy of the template exists exactly where the insert was applied
        assert.is_table(ns.Registry.routes["ud-pal"].libCopies[ins.steps[1]])
        assert.is_nil(ns.Registry.routes["orc-war"].libCopies[ins.steps[1]])
        assert.same({}, ns.Registry.errors)
    end)

    it("scope: default filters of the steps, pruned per route, kept and filtered by player without classes", function()
        m, ns = boot()
        libSeg("sh", { { id = "sh-1", accept = 363 }, { id = "sh-org", go = true, at = { 1454, 50, 50 } },
            { id = "sh-2", turnin = 363 } })
        route("ud-pal", { "sh" })
        route("ud-war", { "sh" }, { classes = { "WARRIOR" } })
        route("orc-war", { "sh" }, { races = { "Orc" }, classes = { "WARRIOR" } })
        route("any", { "sh" }, { races = false, classes = false })
        route("ally", { "sh" }, { faction = "Alliance", races = false, classes = false })
        FB().AddLibraryInsert({ after = "sh-org", class = "WARRIOR", steps = {
            { id = "war-train", train = true },
            manual("war-orc", { race = "Orc" }),          -- narrower: one more dimension on the step
            manual("pal-here", { class = "PALADIN" }),    -- the step's own key replaces the insert's key
        } })
        FB().AddLibraryInsert({ before = "sh-2", race = { "Scourge" }, faction = "Horde", steps = { manual("ud-riding") } })
        assert.same({}, ns.Registry.errors)

        assert.same({ "sh-1", "sh-org", "pal-here", "ud-riding", "sh-2" }, ids("ud-pal"))
        assert.same({ "sh-1", "sh-org", "war-train", "ud-riding", "sh-2" }, ids("ud-war"))
        assert.same({ "sh-1", "sh-org", "war-train", "war-orc", "sh-2" }, ids("orc-war"))
        -- no classes / races on the route: every step is composed ...
        assert.same({ "sh-1", "sh-org", "war-train", "war-orc", "pal-here", "ud-riding", "sh-2" }, ids("any"))
        -- ... except what the route's faction excludes
        assert.same({ "sh-1", "sh-org", "war-train", "war-orc", "pal-here", "sh-2" }, ids("ally"))

        local any = ns.Registry:Get("any")
        assert.same({ class = { WARRIOR = true } }, any.stepById["war-train"].filters)
        assert.same({ class = { WARRIOR = true }, race = { Orc = true } }, any.stepById["war-orc"].filters)
        assert.same({ class = { PALADIN = true } }, any.stepById["pal-here"].filters)
        assert.same({ race = { Scourge = true }, faction = "Horde" }, any.stepById["ud-riding"].filters)
        -- ... and the engine filters them for the player (Scourge PALADIN Horde), as for any step
        assert.is_true(E():SetRoute("any"))
        H.settle(m)
        assert.same({ "sh-1", "sh-org", "pal-here", "ud-riding", "sh-2" }, H.ids(E():GetSteps()))
    end)

    it("order at one anchor: shared inserts (registration order) before the route's own; '<anchor>+<n>' unchanged",
        function()
            m, ns = boot()
            libSeg("o", { { id = "o-1", accept = 363 }, { id = "o-2", turnin = 363 } })
            route("r", { "o" })
            FB().AddInsert("r", { after = "o-1", steps = { { manual = true } } })
            FB().AddLibraryInsert({ after = "o-1", steps = { manual("s-a") } })
            FB().AddInsert("r", { before = "o-2", steps = { { manual = true }, manual("own-b") } })
            FB().AddLibraryInsert({ after = "o-1", steps = { manual("s-b") } })
            FB().AddLibraryInsert({ before = "o-2", steps = { manual("s-c") } })
            FB().AddLibraryInsert({ before = "o-2", steps = { manual("s-d") } })
            FB().AddInsert("r", { after = "o-1", steps = { manual("own-a"), { manual = true } } })
            assert.same({ "o-1", "s-a", "s-b", "o-1+1", "own-a", "o-1+3", "s-c", "s-d", "o-2+1", "own-b", "o-2" }, ids("r"))
            assert.same({}, ns.Registry.errors)
        end)

    it("chains: a shared insert at a step of another shared insert, a per-route insert at a shared step; the quirk",
        function()
            m, ns = boot()
            libSeg("c", { { id = "c-1", accept = 363 }, { id = "c-2", turnin = 363 } })
            route("r", { "c" })
            FB().AddInsert("r", { after = "s-2", steps = { manual("own-x") } })
            -- registered before the insert that holds its anchor
            FB().AddLibraryInsert({ after = "s-1", steps = { manual("s-2"), manual("s-3") } })
            FB().AddLibraryInsert({ after = "c-1", steps = { manual("s-1") } })
            assert.same({ "c-1", "s-1", "s-2", "own-x", "s-3", "c-2" }, ids("r"))
            assert.equal("c", ns.Registry:Get("r").stepById["s-3"].segment)
            assert.equal("c", ns.Registry:Get("r").stepById["own-x"].segment)

            -- known ordering quirk: an insert anchored on the LAST step of an earlier insert at anchor X
            -- lands behind the later inserts at X
            libSeg("q", { { id = "q-0", accept = 364 }, { id = "q-9", turnin = 364 } })
            route("rq", { "q" })
            FB().AddLibraryInsert({ after = "q-0", steps = { manual("q-1"), manual("q-2") } })
            FB().AddLibraryInsert({ after = "q-2", steps = { manual("q-3") } })
            FB().AddLibraryInsert({ after = "q-0", steps = { manual("q-4") } })
            assert.same({ "q-0", "q-1", "q-2", "q-4", "q-3", "q-9" }, ids("rq"))
            assert.same({}, ns.Registry.errors)
        end)

    it("registration errors are reported once; an insert with a missing or duplicate id is rejected as a whole",
        function()
            m, ns = boot()
            local R = ns.Registry
            libSeg("e", { { id = "e-1", accept = 363 }, { id = "e-2", turnin = 363 } })
            assert.is_table(FB().AddLibraryInsert({ after = "e-1", steps = { manual("ok-1") } }))
            assert.same({}, R.errors)

            -- malformed definitions: nothing is recorded
            assert.is_nil(FB().AddLibraryInsert("nope"))
            assert.is_nil(FB().AddLibraryInsert({ after = "e-1", before = "e-2", steps = { manual("a") } }))
            assert.is_nil(FB().AddLibraryInsert({ steps = { manual("a") } }))
            assert.is_nil(FB().AddLibraryInsert({ after = 42, steps = { manual("a") } }))
            assert.is_nil(FB().AddLibraryInsert({ after = "", steps = { manual("a") } }))
            assert.is_nil(FB().AddLibraryInsert({ after = "e-1", steps = {} }))
            assert.equal(1, #errorsMatching("^library: insert: insert definition must be a table$"))
            assert.equal(1, #errorsMatching("^library: insert: give either `after` or `before`, not both$"))
            assert.equal(1, #errorsMatching("^library: insert: `after = \"<stepId>\"` or `before = \"<stepId>\"` is required$"))
            assert.equal(1, #errorsMatching("^library: insert after '42': the anchor must be a step id %(string%)$"))
            assert.equal(1, #errorsMatching("^library: insert after '': the anchor must be a step id %(string%)$"))
            assert.equal(1, #errorsMatching("^library: insert after 'e%-1': steps must be a non%-empty list$"))

            -- id errors: the whole insert is rejected (its good steps too)
            assert.is_nil(FB().AddLibraryInsert({ after = "e-1", steps = { manual("good-1"), { manual = true } } }))
            assert.equal(1, #errorsMatching(
                "^library: insert after 'e%-1' step 2: an explicit id is required in a shared insert$"))
            assert.is_nil(FB().AddLibraryInsert({ after = "e-1", steps = { manual("good-2"), manual("e-2") } }))
            assert.equal(1, #errorsMatching("^library: insert after 'e%-1' step 2: duplicate step id 'e%-2'$"))
            assert.is_nil(FB().AddLibraryInsert({ before = "e-2", steps = { manual("ok-1") } }))
            assert.equal(1, #errorsMatching("^library: insert before 'e%-2' step 1: duplicate step id 'ok%-1'$"))
            assert.is_nil(FB().AddLibraryInsert({ after = "e-1", steps = { manual("twice"), manual("twice") } }))
            assert.equal(1, #errorsMatching("^library: insert after 'e%-1' step 2: duplicate step id 'twice'$"))
            -- the ids of a rejected insert stay free
            assert.is_table(FB().AddLibraryInsert({ after = "ok-1", steps = { manual("good-1"), manual("twice") } }))

            -- other format errors: reported, the insert is kept (like AddInsert)
            local n = #R.errors
            assert.is_table(FB().AddLibraryInsert({ after = "e-1", foo = 1, steps = { manual("k-key") } }))
            assert.is_table(FB().AddLibraryInsert({ after = "e-1", class = "PALADN", steps = { manual("k-class") } }))
            assert.is_table(FB().AddLibraryInsert({ after = "e-1", faction = "Neutral", steps = { manual("k-faction") } }))
            assert.is_table(FB().AddLibraryInsert({ after = "e-1", race = { 5 }, steps = { manual("k-race") } }))
            assert.is_table(FB().AddLibraryInsert({ after = "e-1", steps = { manual("k-step", { bogus = true }) } }))
            assert.equal(n + 5, #R.errors)
            assert.equal(1, #errorsMatching("^library: insert after 'e%-1': unknown key 'foo'$"))
            assert.equal(1, #errorsMatching("^library: insert after 'e%-1': unknown class token 'PALADN'$"))
            assert.equal(1, #errorsMatching("^library: insert after 'e%-1': faction must be Horde or Alliance$"))
            assert.equal(1, #errorsMatching("^library: insert after 'e%-1': race tokens must be strings"))
            assert.equal(1, #errorsMatching("^library: insert after 'e%-1' step 1: unknown step key 'bogus'$"))

            -- a shared segment registered later may not reuse a shared-insert step id
            libSeg("late", { { id = "ok-1", accept = 364 } })
            assert.equal(1, #errorsMatching("^library: segment late step 1: duplicate step id 'ok%-1'$"))

            -- composing a route adds nothing: every error above was recorded at the call
            n = #R.errors
            route("r", { "e" })
            -- (k-class / k-faction / k-race cannot match the route; good-1 / twice are anchored on the last
            -- step of the first insert at e-1 and so land behind the later inserts at e-1: the quirk)
            assert.same({ "e-1", "ok-1", "k-key", "k-step", "good-1", "twice", "e-2" }, ids("r"))
            assert.equal(n, #R.errors)
        end)

    it("a positional anchor is a composition error, once per composed route", function()
        m, ns = boot()
        local R = ns.Registry
        libSeg("p", { { accept = 363 }, { id = "p-2", turnin = 363 } })
        assert.is_true(R.library.segments.p.steps[1].autoId)
        assert.is_nil(R.library.segments.p.steps[2].autoId)
        route("r1", { "p" })
        route("r2", { "p" }, { classes = { "WARRIOR" } })
        FB().AddLibraryInsert({ after = "p:1", steps = { manual("x-pos") } })
        FB().AddLibraryInsert({ after = "p-2", steps = { manual("x-ok") } })
        assert.same({}, R.errors, "composition is lazy")
        assert.same({ "p:1", "x-pos", "p-2", "x-ok" }, ids("r1"))
        local msg = "AddLibraryInsert: anchor 'p:1' is a positional step id: give the anchor step an explicit id"
        assert.same({ "route r1: " .. msg }, R.errors)
        -- recomposition does not repeat it
        FB().AddInsert("r1", { before = "p-2", steps = { manual("own") } })
        assert.same({ "p:1", "x-pos", "own", "p-2", "x-ok" }, ids("r1"))
        assert.equal(1, #R.errors)
        ids("r2")
        assert.same({ "route r1: " .. msg, "route r2: " .. msg }, R.errors)
    end)

    it("each route composes its own copies (shared sub-tables, stable identity); templates are never touched",
        function()
            m, ns = boot()
            local R = ns.Registry
            libSeg("k", { { id = "k-1", accept = 363 }, { id = "k-2", turnin = 363 } })
            route("r1", { "k" })
            route("r2")
            FB().AddSegment("r2", { id = "r2-own", title = "Own", steps = { { id = "r2-1", accept = 364 } } })
            FB().UseSegments("r2", { "k" })
            local ins = FB().AddLibraryInsert({ after = "k-1", class = "PALADIN", steps = {
                { id = "kx", train = true, npc = 244808, at = { 1420, 31.1, 66.4 }, note = { en = "Train", ru = "Тренер" } },
            } })
            local template = ins.steps[1]
            local a, b = R:Get("r1").stepById.kx, R:Get("r2").stepById.kx
            assert.are_not.equal(a, b)
            assert.are_not.equal(a, template)
            assert.equal(a, R.routes.r1.libCopies[template])
            for _, key in ipairs({ "actions", "at", "npc", "note", "filters", "def" }) do
                assert.is_table(a[key], key)
                assert.equal(a[key], b[key], key .. " is shared")
                assert.equal(a[key], template[key], key .. " is the template's")
            end
            assert.equal(2, a.index)
            assert.equal(3, b.index)
            -- tags
            for _, s in ipairs({ a, b }) do
                assert.is_true(s.inserted)
                assert.is_true(s.shared)
                assert.is_true(s.library) -- (the offline loader tags the module name)
                assert.equal("k-1", s.anchor)
                assert.equal("after", s.insertSide)
                assert.equal("k", s.segment)
                assert.equal("kx", s.id)
            end
            -- the template is not part of any route
            assert.is_nil(template.index)
            assert.is_nil(template.segment)
            assert.same({ r1 = true, r2 = true }, ins.applied)
            -- recomposition keeps the identity of the copies (segment steps and insert steps)
            local k1 = R.routes.r1.stepById["k-1"]
            FB().AddLibraryInsert({ before = "k-2", steps = { manual("ky") } })
            assert.is_true(R.routes.r1.dirty)
            assert.same({ "k-1", "kx", "ky", "k-2" }, ids("r1"))
            assert.equal(a, R.routes.r1.stepById.kx)
            assert.equal(k1, R.routes.r1.stepById["k-1"])
            assert.same({}, R.errors)
        end)

    it("a forward reference keeps the order at the anchor: shared in registration order, then the route's own",
        function()
            m, ns = boot()
            libSeg("f", { { id = "f-1", accept = 363 }, { id = "f-2", turnin = 363 } })
            route("r", { "f" })
            FB().AddInsert("r", { after = "race-x", steps = { manual("own-1") } })
            FB().AddInsert("r", { before = "race-x", steps = { manual("own-0") } })
            -- a "class file" is loaded before the "race file" whose insert holds its anchor
            FB().AddLibraryInsert({ after = "race-x", steps = { manual("class-1") } })
            FB().AddLibraryInsert({ before = "race-x", steps = { manual("class-0") } })
            FB().AddLibraryInsert({ after = "f-1", steps = { manual("race-x") } })
            FB().AddLibraryInsert({ after = "race-x", steps = { manual("race-2") } })
            FB().AddLibraryInsert({ before = "race-x", steps = { manual("race-0") } })
            assert.same({ "f-1", "class-0", "race-0", "own-0", "race-x", "class-1", "race-2", "own-1", "f-2" }, ids("r"))

            -- the same among the route's own inserts: call order, and "<anchor>+<n>" counts in that order
            libSeg("g", { { id = "g-1", accept = 364 }, { id = "g-2", turnin = 364 } })
            route("p", { "g" })
            FB().AddInsert("p", { after = "p-x", steps = { { manual = true }, manual("p-a") } })
            FB().AddInsert("p", { after = "g-1", steps = { manual("p-x") } })
            FB().AddInsert("p", { after = "p-x", steps = { manual("p-b"), { manual = true } } })
            assert.same({ "g-1", "p-x", "p-x+1", "p-a", "p-b", "p-x+4", "g-2" }, ids("p"))

            -- a shared insert anchored on a step of a per-route insert still goes before the route's own
            -- inserts at that step
            libSeg("h", { { id = "h-1", accept = 376 }, { id = "h-2", turnin = 376 } })
            route("q", { "h" })
            FB().AddInsert("q", { after = "h-1", steps = { manual("q-x") } })
            FB().AddInsert("q", { after = "q-x", steps = { manual("q-own") } })
            FB().AddLibraryInsert({ after = "q-x", steps = { manual("q-shared") } })
            assert.same({ "h-1", "q-x", "q-shared", "q-own", "h-2" }, ids("q"))
            assert.same({}, ns.Registry.errors)
        end)

    it("the anchor may be an own step of a route that uses shared segments (per route); a positional one is reported",
        function()
            m, ns = boot()
            local R = ns.Registry
            libSeg("sg", { { id = "sg-1", accept = 363 }, { id = "sg-2", turnin = 363 } })
            -- r: an own segment before the shared one; r2: its own segment moved behind it by UseSegments
            route("r")
            FB().AddSegment("r", { id = "own", title = "Own", steps = { manual("own-1"), { manual = true } } })
            FB().UseSegments("r", { "sg" })
            route("r2")
            FB().AddSegment("r2", { id = "mine", title = "Mine", steps = { manual("own-1") } })
            FB().UseSegments("r2", { "sg", "mine" })
            route("none", { "sg" }, { classes = { "WARRIOR" } })
            local ins = FB().AddLibraryInsert({ after = "own-1", steps = { manual("sh-own") } })
            FB().AddLibraryInsert({ before = "own-1", class = "PALADIN", steps = { manual("sh-before") } })
            FB().AddLibraryInsert({ after = "own:2", steps = { manual("sh-pos") } })
            assert.same({}, R.errors, "composition is lazy")

            assert.same({ "sh-before", "own-1", "sh-own", "own:2", "sh-pos", "sg-1", "sg-2" }, ids("r"))
            assert.same({ "sg-1", "sg-2", "sh-before", "own-1", "sh-own" }, ids("r2"))
            assert.same({ "sg-1", "sg-2" }, ids("none"), "no step with the anchor id: nothing")
            assert.same({ r = true, r2 = true }, ins.applied)
            local sh = R:Get("r").stepById["sh-own"]
            assert.equal("own", sh.segment, "the anchor's (own) segment")
            assert.is_true(sh.shared)
            assert.equal("mine", R:Get("r2").stepById["sh-own"].segment)
            assert.is_true(R:Get("r").stepById["own:2"].autoId)
            assert.same({ "route r: AddLibraryInsert: anchor 'own:2' is a positional step id: give the anchor step an "
                .. "explicit id" }, R.errors)
        end)

    it("an id that a route's own step or per-route insert step also has: composition error, once per route",
        function()
            m, ns = boot()
            local R = ns.Registry
            libSeg("d", { { id = "d-1", accept = 363 }, { id = "d-2", turnin = 363 } })
            for _, id in ipairs({ "r1", "r2" }) do
                route(id, nil, id == "r2" and { classes = { "WARRIOR" } } or nil)
                FB().AddSegment(id, { id = id .. "-own", title = "Own", steps = { manual("dup-own") } })
                FB().UseSegments(id, { "d" })
                FB().AddInsert(id, { after = "d-1", steps = { manual("dup-ins") } })
            end
            route("clean", { "d" })
            -- registration cannot know the routes' own ids: the insert is accepted
            assert.is_table(FB().AddLibraryInsert({ after = "d-1", steps = { manual("dup-own"), manual("dup-ins") } }))
            assert.same({}, R.errors, "composition is lazy")

            local function messages(id)
                return {
                    format("route %s: duplicate step id 'dup-own' after composition (segment %s-own and shared insert "
                        .. "after 'd-1'): step ids must be unique per route", id, id),
                    format("route %s: duplicate step id 'dup-ins' after composition (shared insert after 'd-1' and "
                        .. "insert after 'd-1'): step ids must be unique per route", id),
                }
            end
            -- every step stays in the route; stepById is the first one with the id
            assert.same({ "dup-own", "d-1", "dup-own", "dup-ins", "dup-ins", "d-2" }, ids("r1"))
            local r1 = R:Get("r1")
            assert.equal(r1.steps[1], r1.stepById["dup-own"])
            assert.equal(r1.steps[4], r1.stepById["dup-ins"])
            assert.is_true(r1.steps[4].shared)
            assert.is_nil(r1.steps[5].shared)
            assert.same(messages("r1"), R.errors)
            -- recomposition does not repeat them
            FB().AddInsert("r1", { before = "d-2", steps = { manual("r1-more") } })
            assert.same({ "dup-own", "d-1", "dup-own", "dup-ins", "dup-ins", "r1-more", "d-2" }, ids("r1"))
            assert.same(messages("r1"), R.errors)
            -- once per route
            ids("r2")
            local want = messages("r1")
            for _, msg in ipairs(messages("r2")) do want[#want + 1] = msg end
            assert.same(want, R.errors)
            -- a route without those ids composes the insert without an error
            assert.same({ "d-1", "dup-own", "dup-ins", "d-2" }, ids("clean"))
            assert.same(want, R.errors)
        end)

    describe("on the mixed fixture module (FastesBoooy_TestGuides)", function()
        it("login composes exactly one route: the one of the character", function()
            for _, id in ipairs(H.GUIDES_ROUTES) do
                local gm, gns = boot({ guides = true, player = H.GUIDES_PLAYER[id] })
                local R = gns.Registry
                assert.same({}, R.errors)
                assert.same(H.GUIDES_ROUTES, H.ids(R.order), "no Tauren route (placeholder zone), `only` = PALADIN")
                assert.equal(id, gns.Engine:GetRoute().id)
                assert.same(H.GUIDES_IDS[id], H.ids(gns.Engine:GetRoute().steps))
                assert.same(H.GUIDES_IDS[id], H.ids(gns.Engine:GetSteps()), "every composed step is the player's")
                for _, other in ipairs(H.GUIDES_ROUTES) do
                    local r = R.routes[other]
                    assert.equal(other ~= id, r.dirty, other)
                    if other ~= id then assert.equal(0, #r.steps, other .. " is not composed") end
                end
                gm:AssertClean()
            end
        end)

        it("a shared insert registered after login recomposes the active route; the cursor stays by id", function()
            m, ns = boot({ guides = true, player = H.GUIDES_PLAYER["tg-orc-warrior"] })
            H.playTo(m, ns, "tg-dur-boars")
            local index = E():GetCursor()
            local changed = H.record(ns, "ROUTES_CHANGED")
            assert.is_table(FB().AddLibraryInsert({ after = "tg-dur-4641", class = "WARRIOR", steps = {
                manual("tg-late-war") } }))
            assert.is_table(FB().AddLibraryInsert({ after = "tg-dur-4641", class = "MAGE", steps = {
                manual("tg-late-mag") } }))
            local seen = {}
            for _, c in ipairs(changed) do seen[c[1]] = true end
            assert.is_true(seen["tg-orc-warrior"])
            H.settle(m)
            assert.same({ "tg-dur-4641", "tg-late-war", "tg-dur-788", "tg-dur-boars" },
                { unpack(H.ids(E():GetSteps()), 1, 4) })
            assert.equal("tg-dur-boars", H.cur(ns))
            assert.equal(index + 1, E():GetCursor())
            assert.is_true(E():IsDone("tg-late-war"), "a transient step before a done quest step is forwarded")
            assert.is_true(ns.Registry.routes["tg-troll-mage"].dirty, "the other routes stay uncomposed")
            assert.same({}, ns.Registry.errors)
        end)

        it("the engine plays across shared-insert steps; /reload and a cold start find the cursor", function()
            m, ns = boot({ guides = true, player = H.GUIDES_PLAYER["tg-orc-warrior"] })
            local cdb = m.env.FastesBoooyCharDB
            H.playTo(m, ns, "tg-war-letter-orc")
            assert.equal("tg-war-letter-orc", H.cur(ns), "the class insert right after its anchor")
            H.playTo(m, ns, "tg-war-train-2")
            assert.is_true(m:IsQuestCompleted(2383))
            assert.equal("tg-war-train-2", H.cur(ns), "nested anchor: training after the letter turn-in")
            assert.equal("tg-war-train-2", cdb.cursorHintId)
            assert.equal("tg-orc-warrior", cdb.cursorHintRoute)
            -- /reload on a transient shared-insert step: restored by id
            local m2, ns2 = H.reload(m, { guides = true })
            assert.equal("tg-war-train-2", H.cur(ns2))
            m2:AssertClean()
            -- cold start: the step after the last done quest step is shown again
            local m3, ns3 = H.reload(m, { guides = true, coldStart = true })
            assert.equal("tg-war-train-2", H.cur(ns3))
            m3:AssertClean()
            -- ... and forwarded once a later quest step is done
            H.playTo(m, ns, "tg-dur-789-in")
            local m4, ns4 = H.reload(m, { guides = true, coldStart = true })
            assert.equal("tg-dur-789-in", H.cur(ns4))
            assert.is_true(ns4.Engine:IsDone("tg-war-train-2"))
            m4:AssertClean()
            H.perform(m, ns, E():GetCurrentStep())
            H.settle(m)
            assert.is_nil(E():GetCursor(), "route finished")
        end)

        it("race scope and an insert on a race-filtered anchor (troll), former route id (undead)", function()
            m, ns = boot({ guides = true, player = H.GUIDES_PLAYER["tg-troll-mage"] })
            local r = E():GetRoute()
            assert.is_nil(r.stepById["tg-dur-scorpids-orc"], "the other race's alternative is not composed")
            assert.is_nil(r.stepById["tg-war-train-2"], "nor another class's insert")
            assert.equal("tg-dur-scorpids-troll", r.stepById["tg-tro-back"].anchor)
            assert.same({ race = { Troll = true } }, r.stepById["tg-tro-back"].filters)
            assert.same({ class = { MAGE = true }, race = { Troll = true } }, r.stepById["tg-mag-maiah"].filters)
            H.playTo(m, ns, "tg-dur-789-in")
            assert.is_true(m:IsQuestCompleted(3086))
            -- the alias of the fixture's undead route resolves without composing a second route
            local undead = ns.Registry:Get("tg-old-undead-paladin")
            assert.equal("tg-undead-paladin", undead.id)
            assert.same(H.GUIDES_IDS["tg-undead-paladin"], H.ids(undead.steps))
            assert.is_true(ns.Registry.routes["tg-orc-warrior"].dirty)
        end)
    end)
end)

describe("shared steps are composed by route scope (Core/Compose.lua)", function()
    after_each(function()
        if m then m:AssertClean() end
        m, ns = nil, nil
    end)

    it("a race-filtered alternative pair: each route holds its own alternative and the insert behind it", function()
        m, ns = boot()
        local R = ns.Registry
        libSeg("z", {
            { accept = 363 },                          -- z:1
            manual("z-orc", { race = "Orc" }),
            manual("z-troll", { race = "Troll" }),
            { turnin = 363 },                          -- z:4
            manual("z-ally", { faction = "Alliance" }),
            manual("z-pal", { class = "PALADIN" }),
        })
        route("orc-war", { "z" }, { races = { "Orc" }, classes = { "WARRIOR" } })
        route("troll-war", { "z" }, { races = { "Troll" }, classes = { "WARRIOR" } })
        route("loose", { "z" }, { races = false, classes = false })
        -- class-only inserts after both alternatives
        FB().AddLibraryInsert({ after = "z-orc", class = "WARRIOR", steps = { manual("w-orc") } })
        FB().AddLibraryInsert({ after = "z-troll", class = "WARRIOR", steps = { manual("w-troll") } })

        assert.same({ "z:1", "z-orc", "w-orc", "z:4" }, ids("orc-war"))
        assert.same({ "z:1", "z-troll", "w-troll", "z:4" }, ids("troll-war"))
        -- a route without `races` / `classes` keeps both alternatives (the engine filters by player)
        assert.same({ "z:1", "z-orc", "w-orc", "z-troll", "w-troll", "z:4", "z-pal" }, ids("loose"))
        assert.same({}, R.errors)
        -- the positional ids (and positions in the definition) of the unfiltered steps do not depend on the route
        for _, id in ipairs({ "orc-war", "troll-war", "loose" }) do
            local r = R:Get(id)
            assert.equal(1, r.stepById["z:1"].segIndex, id)
            assert.equal(4, r.stepById["z:4"].segIndex, id)
            assert.equal(1, r.segmentById.z.first, id)
            assert.equal(#r.steps, r.segmentById.z.last, id)
            assert.equal(#r.steps, #r.segmentById.z.steps, id)
        end
        assert.equal(6, #R.library.segments.z.steps, "the shared segment itself is complete")
        -- a per-route insert anchored on a step that is not composed into the route: the existing error
        FB().AddInsert("orc-war", { after = "z-troll", steps = { manual("own") } })
        assert.same({ "z:1", "z-orc", "w-orc", "z:4" }, ids("orc-war"))
        assert.same({ "route orc-war: AddInsert: unknown anchor step 'z-troll' (insert after 'z-troll' ignored)" },
            R.errors)
    end)

    it("a shared segment none of whose steps can match the route leaves no empty segment in it", function()
        m, ns = boot()
        libSeg("all", { { id = "all-1", accept = 363 } })
        libSeg("orcs", { manual("orcs-1", { race = "Orc" }), manual("orcs-2", { race = "Orc" }) })
        route("r", { "orcs", "all" })
        -- an insert at a step of the pruned segment has no anchor in this route (no error)
        FB().AddLibraryInsert({ after = "orcs-1", steps = { manual("orcs-x") } })
        local r = ns.Registry:Get("r")
        assert.same({ "all-1" }, H.ids(r.steps))
        assert.same({ "all" }, H.ids(r.segments))
        assert.is_nil(r.segmentById.orcs)
        assert.equal(1, r.segmentById.all.first)
        assert.same({}, ns.Registry.errors)
        route("o", { "orcs", "all" }, { races = { "Orc" } })
        assert.same({ "orcs-1", "orcs-x", "orcs-2", "all-1" }, ids("o"))
        assert.same({ "orcs", "all" }, H.ids(ns.Registry:Get("o").segments))
    end)

    it("Schema.FiltersCanMatchRoute: disjoint with the route's classes, races or faction", function()
        m, ns = boot()
        local can = ns.Schema.FiltersCanMatchRoute
        local r = { classes = { PALADIN = true, WARRIOR = true }, races = { Scourge = true }, faction = "Horde" }
        assert.is_true(can(nil, r))
        assert.is_true(can({}, r))
        assert.is_true(can({ class = { PALADIN = true } }, r))
        assert.is_true(can({ class = { MAGE = true, WARRIOR = true } }, r))
        assert.is_false(can({ class = { MAGE = true } }, r))
        assert.is_true(can({ race = { Scourge = true, Orc = true } }, r))
        assert.is_false(can({ race = { Orc = true } }, r))
        assert.is_false(can({ class = { PALADIN = true }, race = { Orc = true } }, r))
        assert.is_true(can({ faction = "Horde" }, r))
        assert.is_false(can({ faction = "Alliance" }, r))
        -- a dimension the route does not restrict can match anything
        assert.is_true(can({ class = { MAGE = true }, race = { Orc = true }, faction = "Alliance" }, {}))
        assert.is_true(can({ race = { Orc = true } }, { classes = { MAGE = true } }))
        assert.is_false(can({ race = { Orc = true }, class = { PALADIN = true } }, { classes = { MAGE = true } }))
    end)
end)
