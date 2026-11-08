-- Offline tools on composed routes (library segments + UseSegments + AddInsert):
-- tools/lib/route_loader.lua (dependency modules, composition through Core/Compose.lua),
-- the validator (library tag, once per route, library modules), gen_route_data
-- (AddLibraryData for library modules, own + insert data for route modules) and
-- simulate_routes (dependencies loaded in the mock, library modules not simulated).

local Loader = require("lib.route_loader")
local V = require("lib.validator")
local H = require("fixtures.core.helpers")

local Schema = Loader.LoadSchema(".")

local function run(cmd)
    local p = assert(io.popen(cmd .. " 2>&1; echo \"__EXIT=$?\""))
    local out = p:read("*a")
    p:close()
    local code = tonumber(out:match("__EXIT=(%d+)%s*$"))
    return code, (out:gsub("__EXIT=%d+%s*$", ""))
end

local function count(s, plain)
    local n, i = 0, 1
    while true do
        local a, b = s:find(plain, i, true)
        if not a then return n end
        n, i = n + 1, b + 1
    end
end

local TOC = "## Interface: 16001\n## Dependencies: %s\n%s\n"

-- temporary addons directory: library + route modules that depend on it
local MODULES = {
    ["FastesBoooy_TLib/FastesBoooy_TLib.toc"] = TOC:format("FastesBoooy", "Lib.lua"),
    ["FastesBoooy_TLib/Lib.lua"] = [[
FastesBoooy.AddLibrarySegment({ id = "x-lib", title = "X", zone = "Tirisfal Glades", levels = { 1, 3 }, steps = {
    { id = "x-1", accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
    -- `at` far from Shadow Priest Sarvis: a library-step WARN (at-far) in every route using it
    { id = "x-2", turnin = 363, accept = 364, npc = 1569, at = { 1420, 32.5, 66.2 } },
    { id = "x-3", complete = 364, at = { 1420, 32.5, 63.5 } },
    { id = "x-4", turnin = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
} })
]],
    -- two profiles (Scourge PALADIN, Scourge WARRIOR) + a class insert
    ["FastesBoooy_TMulti/FastesBoooy_TMulti.toc"] = TOC:format("FastesBoooy, FastesBoooy_TLib", "Route.lua"),
    ["FastesBoooy_TMulti/Route.lua"] = [[
FastesBoooy.RegisterRoute({ api = 1, id = "multi", title = "Multi", faction = "Horde", races = { "Scourge" },
    classes = { "PALADIN", "WARRIOR" }, levels = { 1, 3 } })
FastesBoooy.UseSegments("multi", { "x-lib" })
FastesBoooy.AddInsert("multi", { after = "x-2", steps = {
    { id = "m-train", train = true, class = "PALADIN", npc = 244808, at = { 1420, 31.1, 66.4 } },
} })
]],
    ["FastesBoooy_TMissing/FastesBoooy_TMissing.toc"] = TOC:format("FastesBoooy, FastesBoooy_TLib", "Route.lua"),
    ["FastesBoooy_TMissing/Route.lua"] = [[
FastesBoooy.RegisterRoute({ api = 1, id = "missing", title = "Missing", faction = "Horde", races = { "Scourge" },
    classes = { "PALADIN" }, levels = { 1, 3 } })
FastesBoooy.UseSegments("missing", { "x-lib", "x-nope" })
FastesBoooy.AddInsert("missing", { before = "x-zzz", steps = { { manual = true } } })
]],
    ["FastesBoooy_TBadLib/FastesBoooy_TBadLib.toc"] = TOC:format("FastesBoooy", "Seg.lua"),
    ["FastesBoooy_TBadLib/Seg.lua"] = [[
FastesBoooy.AddLibrarySegment({ id = "bad-lib", title = "Bad", steps = {
    { id = "b-1", accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
    { id = "b-2", turnin = 363, npc = 1569, at = { 1420, 30.8, 66.2 }, bogus = 1 },
} })
]],
    ["FastesBoooy_TBadRoute/FastesBoooy_TBadRoute.toc"] = TOC:format("FastesBoooy, FastesBoooy_TBadLib", "Route.lua"),
    ["FastesBoooy_TBadRoute/Route.lua"] = [[
FastesBoooy.RegisterRoute({ api = 1, id = "bad-route", title = "Bad route", faction = "Horde",
    races = { "Scourge" }, classes = { "PALADIN" }, levels = { 1, 2 } })
FastesBoooy.UseSegments("bad-route", { "bad-lib" })
]],
    ["FastesBoooy_TNoDep/FastesBoooy_TNoDep.toc"] = TOC:format("FastesBoooy, FastesBoooy_Nope", "Route.lua"),
    ["FastesBoooy_TNoDep/Route.lua"] = [[
FastesBoooy.RegisterRoute({ api = 1, id = "nodep", title = "No dep", faction = "Horde" })
FastesBoooy.UseSegments("nodep", { "x-lib" })
]],
    ["FastesBoooy_TCycA/FastesBoooy_TCycA.toc"] = TOC:format("FastesBoooy, FastesBoooy_TCycB", "A.lua"),
    ["FastesBoooy_TCycA/A.lua"] = "FastesBoooy.AddLibraryData({ quests = { [363] = \"A\" } })\n",
    ["FastesBoooy_TCycB/FastesBoooy_TCycB.toc"] = TOC:format("FastesBoooy, FastesBoooy_TCycA", "B.lua"),
    ["FastesBoooy_TCycB/B.lua"] = "FastesBoooy.AddLibraryData({ quests = { [364] = \"B\" } })\n",
}

local root

local function dir(name) return root .. "/" .. name end

local db
local function DB()
    db = db or H.db()
    return db
end

describe("composed routes in the offline tools", function()
    setup(function()
        root = os.tmpname()
        os.remove(root)
        for path, content in pairs(MODULES) do
            os.execute(("mkdir -p '%s'"):format((root .. "/" .. path):match("^(.*)/[^/]+$")))
            local fh = assert(io.open(root .. "/" .. path, "wb"))
            fh:write(content)
            fh:close()
        end
    end)
    teardown(function() os.execute(("rm -rf '%s'"):format(root)) end)

    describe("route_loader", function()
        it("loads the FastesBoooy_* dependencies first and composes like the addon", function()
            local mod = Loader.LoadModule(H.COMPOSED_DIR, { schema = Schema })
            assert.same({}, mod.errors)
            assert.equal(1, #mod.deps)
            assert.equal(H.LIB_NAME, mod.deps[1].name)
            assert.equal(H.LIB_TOC, mod.deps[1].toc)
            assert.is_false(mod.isLibrary)
            local r = mod.routes[1]
            local ids = {}
            for i, e in ipairs(H.COMPOSED_ALL) do ids[i] = e[1] end
            assert.same(ids, H.ids(r.steps))
            assert.same({ "tc-intro", "tl-deathknell", "tc-class", "tl-brill" }, H.ids(r.segments))
            -- library steps: qualified file name + library tag; inserts: the route module's file
            local s = r.stepById["tl-363-364"]
            assert.equal(H.LIB_NAME, s.library)
            assert.equal(H.LIB_NAME .. "/Segments/01_Deathknell.lua", s.file)
            assert.equal("Inserts.lua", r.stepById["tc-train-1"].file)
            assert.is_nil(r.stepById["tc-train-1"].library)
            assert.equal("Segments/02_Class.lua", r.segmentById["tc-class"].file)
            -- library data merged under the route data (route values win)
            assert.equal("Rude Awakening", mod.data[H.COMPOSED_ID].quests[363])
            assert.equal("Joshua Kien", mod.data[H.COMPOSED_ID].npcs[2115])
            -- Loader.Dependencies reads both TOC keys
            assert.same({ "FastesBoooy_A", "FastesBoooy_B" },
                Loader.Dependencies({ meta = { Dependencies = "FastesBoooy, FastesBoooy_A", RequiredDeps = "FastesBoooy_B" } }))
        end)

        it("recognizes a library module", function()
            local lib = Loader.LoadModule(H.LIB_DIR, { schema = Schema })
            assert.same({}, lib.errors)
            assert.is_true(lib.isLibrary)
            assert.equal(0, #lib.routes)
            assert.same({ "tl-deathknell", "tl-brill", "tl-unused" }, H.ids(lib.librarySegments))
            assert.equal("Segments/02_Brill.lua", lib.librarySegments[2].file, "own files unqualified")
        end)

        it("reports a missing dependency, a dependency cycle and composition errors with their file", function()
            local nodep = Loader.LoadModule(dir("FastesBoooy_TNoDep"), { schema = Schema })
            local msgs = {}
            for _, e in ipairs(nodep.errors) do msgs[#msgs + 1] = (e.file or "?") .. ": " .. e.msg end
            local all = table.concat(msgs, "\n")
            assert.matches("FastesBoooy_TNoDep.toc: dependency FastesBoooy_Nope %(## Dependencies of FastesBoooy_TNoDep%) "
                .. "not found", all)
            assert.matches("Route.lua: route nodep: UseSegments: unknown library segment 'x%-lib'", all)

            local cyc = Loader.LoadModule(dir("FastesBoooy_TCycA"), { schema = Schema })
            assert.equal(1, #cyc.errors)
            assert.matches("dependency cycle: FastesBoooy_TCycB %-> FastesBoooy_TCycA", cyc.errors[1].msg)
            assert.is_true(cyc.isLibrary)

            local missing = Loader.LoadModule(dir("FastesBoooy_TMissing"), { schema = Schema })
            assert.equal(2, #missing.errors)
            assert.equal("Route.lua", missing.errors[1].file)
            assert.matches("unknown library segment 'x%-nope'", missing.errors[1].msg)
            assert.matches("unknown anchor step 'x%-zzz'", missing.errors[2].msg)

            local bad = Loader.LoadModule(dir("FastesBoooy_TBadRoute"), { schema = Schema })
            assert.equal(1, #bad.errors)
            assert.equal("FastesBoooy_TBadLib/Seg.lua", bad.errors[1].file)
            assert.equal("FastesBoooy_TBadLib", bad.errors[1].library)
            assert.matches("^library: segment bad%-lib step 2: unknown step key 'bogus'", bad.errors[1].msg)
        end)

        it("loads only the module itself with deps = false", function()
            local mod = Loader.LoadModule(H.COMPOSED_DIR, { schema = Schema, deps = false })
            assert.equal(0, #mod.deps)
            local all = {}
            for _, e in ipairs(mod.errors) do all[#all + 1] = e.msg end
            assert.matches("unknown library segment 'tl%-deathknell'", table.concat(all, "\n"))
        end)
    end)

    describe("validator", function()
        it("validates the composed fixture with 0 errors and tags library-step messages", function()
            local res = V.ValidateModule(H.COMPOSED_DIR, { db = DB(), schema = Schema })
            assert.equal(1, #res.results)
            local r = res.results[1]
            assert.equal(0, r.counts.ERROR)
            local lib, own = 0, 0
            for _, m in ipairs(r.messages) do
                if m.library then
                    lib = lib + 1
                    assert.equal(H.LIB_NAME, m.library)
                    assert.matches("^" .. H.LIB_NAME .. "/Segments/", m.file)
                else
                    own = own + 1
                end
            end
            assert.is_true(lib > 0)
            assert.is_true(own > 0, "step-no-profile of the WARRIOR insert")
            assert.same({ "tc-intro", "tl-deathknell", "tc-class", "tl-brill" }, (function()
                local out = {}
                for i, s in ipairs(r.segments) do out[i] = s.id end
                return out
            end)())
            assert.matches("^%[library FastesBoooy_TestLib%] tl%-deathknell#3 id=tl%-complete%-364 "
                .. "%(FastesBoooy_TestLib/Segments/01_Deathknell.lua%)$", V.LocStr((function()
                    for _, m in ipairs(r.messages) do
                        if m.stepId == "tl-complete-364" then return m end
                    end
                end)()))
        end)

        it("reports a library-step message once per route (not once per profile)", function()
            local res = V.ValidateModule(dir("FastesBoooy_TMulti"), { db = DB(), schema = Schema })
            assert.equal(2, #res.results)
            local function farMsgs(r)
                local n = 0
                for _, m in ipairs(r.messages) do
                    if m.code == "at-far" and m.stepId == "x-2" then
                        n = n + 1
                        assert.equal("FastesBoooy_TLib", m.library)
                    end
                end
                return n
            end
            assert.equal(1, farMsgs(res.results[1]))
            assert.equal(0, farMsgs(res.results[2]))
            assert.is_true((res.results[2].libraryRepeats or 0) >= 1)
            -- the class insert is filtered for the WARRIOR profile only
            local skipped = 0
            for _, m in ipairs(res.results[2].messages) do
                if m.code == "step-skipped" and m.stepId == "m-train" then skipped = skipped + 1 end
            end
            assert.equal(1, skipped)
        end)

        it("reports the load errors of a library once per run, in the library's own entry", function()
            local code, out = run("lua5.1 tools/validate_routes.lua '" .. dir("FastesBoooy_TBadRoute") .. "'")
            assert.equal(1, code, out)
            assert.equal(1, count(out, "unknown step key 'bogus'"), out)
            assert.matches("ERROR %[library FastesBoooy_TBadLib%] %(FastesBoooy_TBadLib/Seg.lua%) %[schema%]", out)

            code, out = run("lua5.1 tools/validate_routes.lua '" .. dir("FastesBoooy_TBadLib") .. "' '"
                .. dir("FastesBoooy_TBadRoute") .. "'")
            assert.equal(1, code, out)
            assert.equal(1, count(out, "unknown step key 'bogus'"), out)
            assert.matches("== library module FastesBoooy_TBadLib %[library: 1 segment%(s%), 2 step%(s%)%]", out)
            assert.matches("ERROR %[library FastesBoooy_TBadLib%] %(Seg.lua%) %[schema%]", out)

            code, out = run("lua5.1 tools/validate_routes.lua -q " .. H.LIB_DIR .. " " .. H.COMPOSED_DIR)
            assert.equal(0, code, out)
            assert.matches("%(library FastesBoooy_TestLib%) %[library: 3 segment%(s%), 19 step%(s%)%]: 0 error", out)
            assert.matches("test%-composed %[Scourge PALADIN Horde%]: 0 error%(s%)", out)
        end)

        it("fails a route whose library segment or anchor does not exist", function()
            local code, out = run("lua5.1 tools/validate_routes.lua -q '" .. dir("FastesBoooy_TMissing") .. "'")
            assert.equal(1, code, out)
            assert.matches("missing %[Scourge PALADIN Horde%]: 2 error", out)
        end)
    end)

    describe("gen_route_data", function()
        it("writes AddLibraryData for a library module with what its segments reference", function()
            local code, out = run("lua5.1 tools/gen_route_data.lua --stdout " .. H.LIB_DIR)
            assert.equal(0, code, out)
            assert.not_matches("AddRouteData", out)
            local chunk = assert(loadstring(out))
            local captured
            setfenv(chunk, { FastesBoooy = { AddLibraryData = function(d) captured = d end } })
            chunk()
            assert.equal("Rude Awakening", captured.quests[363])
            assert.equal("The Scarlet Crusade", captured.quests[381])
            assert.equal("Innkeeper Renee", captured.npcs[5688])
            assert.same({ area = 159, en = "Brill", ru = "Брилл" }, captured.places.Brill)
            assert.is_nil(captured.npcs[244808], "the route's inserts are not library data")
        end)

        it("lists only the route's own segments and inserts in a route module's Data.lua", function()
            local code, out = run("lua5.1 tools/gen_route_data.lua --stdout " .. H.COMPOSED_DIR)
            assert.equal(0, code, out)
            local chunk = assert(loadstring(out))
            local captured
            setfenv(chunk, { FastesBoooy = { AddRouteData = function(id, d) captured = { id = id, data = d } end } })
            chunk()
            assert.equal(H.COMPOSED_ID, captured.id)
            assert.same({}, captured.data.quests)
            assert.same({ [2115] = "Joshua Kien", [2116] = "Blacksmith Rand", [2119] = "Dannal Stern",
                [244808] = "Aramis Hammerhand" }, captured.data.npcs)
            assert.is_nil(captured.data.places)
        end)

        it("the committed fixture Data.lua files are up to date (--check)", function()
            local code, out = run("lua5.1 tools/gen_route_data.lua --check " .. H.LIB_DIR .. " " .. H.COMPOSED_DIR)
            assert.equal(0, code, out)
            assert.equal(2, count(out, "up to date"), out)
        end)

        it("writes nothing when a dependency has errors", function()
            local code, out = run("lua5.1 tools/gen_route_data.lua --stdout '" .. dir("FastesBoooy_TBadRoute") .. "'")
            assert.equal(1, code, out)
            assert.matches("FastesBoooy_TBadLib/Seg.lua: library: segment bad%-lib step 2", out)
            assert.matches("Data.lua not generated", out)
        end)
    end)

    describe("simulate_routes", function()
        it("plays the composed route with its library loaded first and skips the library module", function()
            local code, out = run("lua5.1 tools/simulate_routes.lua " .. H.LIB_DIR .. " " .. H.COMPOSED_DIR)
            assert.equal(0, code, out)
            assert.is_truthy(out:find("skip FastesBoooy_TestLib: library module", 1, true), out)
            assert.is_truthy(out:find("OK   test-composed (Scourge PALADIN Horde): 26 steps", 1, true), out)
            assert.is_truthy(out:find("1 simulation(s), 1 passed, 0 failed", 1, true), out)
        end)

        it("plays a route of two profiles with a class insert", function()
            local code, out = run("lua5.1 tools/simulate_routes.lua '" .. dir("FastesBoooy_TMulti") .. "'")
            assert.equal(0, code, out)
            assert.is_truthy(out:find("OK   multi (Scourge PALADIN Horde): 5 steps", 1, true), out)
            assert.is_truthy(out:find("OK   multi (Scourge WARRIOR Horde): 4 steps", 1, true), out)
        end)

        it("fails a route whose library segment does not exist", function()
            local code, out = run("lua5.1 tools/simulate_routes.lua '" .. dir("FastesBoooy_TMissing") .. "'")
            assert.equal(1, code, out)
            assert.is_truthy(out:find("FAIL FastesBoooy_TMissing: 2 load/schema error(s)", 1, true), out)
            assert.is_truthy(out:find("unknown library segment 'x-nope'", 1, true), out)
        end)
    end)
end)
