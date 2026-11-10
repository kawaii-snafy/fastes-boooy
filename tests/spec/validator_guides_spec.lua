-- Offline tools on a MIXED module: one addon that registers shared segments, shared inserts
-- (FastesBoooy.AddLibraryInsert) and several routes -- the shape of FastesBoooy_Guides; fixture
-- tests/fixtures/core/FastesBoooy_TestGuides. tools/lib/route_loader.lua (the AddLibraryInsert stub,
-- mod.libraryInserts, route aliases, opts.replace / opts.skip, error files), gen_route_data
-- (AddLibraryData covers the shared inserts, no block for a route that owns nothing) and the
-- validator / simulator command lines on the fixture.

local Loader = require("lib.route_loader")
local H = require("fixtures.core.helpers")

local Schema = Loader.LoadSchema(".")

local function run(cmd)
    local p = assert(io.popen(cmd .. " 2>&1; echo \"__EXIT=$?\""))
    local out = p:read("*a")
    p:close()
    local code = tonumber(out:match("__EXIT=(%d+)%s*$"))
    return code, (out:gsub("__EXIT=%d+%s*$", ""))
end

local function messages(mod)
    local out = {}
    for i, e in ipairs(mod.errors) do out[i] = tostring(e.file) .. ": " .. e.msg end
    return out
end

local root

local function write(path, content)
    os.execute(("mkdir -p '%s'"):format((root .. "/" .. path):match("^(.*)/[^/]+$")))
    local fh = assert(io.open(root .. "/" .. path, "wb"))
    fh:write(content)
    fh:close()
    return root .. "/" .. path
end

local TOC = "## Interface: 16001\n## Dependencies: FastesBoooy\n%s\n"

describe("a mixed module (shared segments + shared inserts + routes) in the offline tools", function()
    setup(function()
        root = os.tmpname()
        os.remove(root)
        os.execute(("mkdir -p '%s'"):format(root))
    end)
    teardown(function() os.execute(("rm -rf '%s'"):format(root)) end)

    describe("route_loader", function()
        it("loads the fixture: three routes from a table, composed like the addon", function()
            local mod = Loader.LoadModule(H.GUIDES_DIR, { schema = Schema })
            assert.same({}, mod.errors)
            assert.is_nil(mod.declaredLibrary)
            assert.is_false(mod.isLibrary, "a module with routes is not a library module")
            assert.same(H.GUIDES_ROUTES, H.ids(mod.routes), "no Tauren route: its zone file is a placeholder")
            for _, r in ipairs(mod.routes) do
                assert.same(H.GUIDES_IDS[r.id], H.ids(r.steps), r.id)
                assert.equal("Route.lua", r.file)
            end
            assert.same({ "tg-ud-01-deathknell", "tg-dur-01-valley-of-trials" }, H.ids(mod.librarySegments))
            assert.same({ "Data.lua", "Segments/Tirisfal/01_Deathknell.lua", "Segments/Durotar/01_ValleyOfTrials.lua",
                "Segments/Mulgore/01_CampNarache.lua", "Classes/Mage.lua", "Classes/Paladin.lua", "Classes/Warrior.lua",
                "Races/Troll.lua", "Route.lua" }, mod.files)
            -- former route ids
            assert.equal(mod.routeById["tg-undead-paladin"], mod.aliases["tg-old-undead-paladin"])
            assert.same({ "tg-old-undead-paladin" }, mod.routeById["tg-undead-paladin"].aliases)
            -- the class reward table is library data: merged under every route's data
            assert.same({ MAGE = { [789] = 2 }, PALADIN = { [3901] = 2 }, WARRIOR = { [789] = 1 } }, mod.lib.data.rewards)
            assert.equal(1, mod.data["tg-orc-warrior"].rewards.WARRIOR[789])
            assert.equal("Simple Parchment", mod.data["tg-orc-warrior"].quests[2383])
        end)

        it("mod.libraryInserts: the templates with file, scope and the routes they were applied to", function()
            local mod = Loader.LoadModule(H.GUIDES_DIR, { schema = Schema })
            local got = {}
            for i, ins in ipairs(mod.libraryInserts) do
                local applied = {}
                for id in pairs(ins.applied) do applied[#applied + 1] = id end
                table.sort(applied)
                got[i] = { ins.file, ins.side, ins.anchor, table.concat(H.ids(ins.steps), " "), table.concat(applied, " ") }
            end
            assert.same({
                { "Classes/Mage.lua", "after", "tg-dur-788-in", "tg-mag-letter-troll tg-mag-maiah", "tg-troll-mage" },
                { "Classes/Paladin.lua", "after", "tg-ud-364-in", "tg-pal-train-1", "tg-undead-paladin" },
                { "Classes/Warrior.lua", "after", "tg-dur-788-in", "tg-war-letter-orc tg-war-frang", "tg-orc-warrior" },
                { "Classes/Warrior.lua", "after", "tg-war-frang", "tg-war-train-2", "tg-orc-warrior" },
                { "Races/Troll.lua", "after", "tg-dur-788-in", "tg-tro-vendor", "tg-troll-mage" },
                { "Races/Troll.lua", "after", "tg-dur-scorpids-troll", "tg-tro-back", "tg-troll-mage" },
            }, got)
            assert.same({ class = { MAGE = true }, race = { Troll = true } }, mod.libraryInserts[1].scope)
            assert.same({ class = { WARRIOR = true } }, mod.libraryInserts[3].scope)
            assert.same({ race = { Troll = true } }, mod.libraryInserts[5].scope)
            assert.equal(H.GUIDES_NAME, mod.libraryInserts[1].module)
            -- a step narrows the scope with its own key
            assert.same({ class = { WARRIOR = true }, race = { Orc = true } }, mod.libraryInserts[3].steps[1].filters)
            -- the composed copy of a template step: tags, file, and how to find it from the template
            local orc = mod.routeById["tg-orc-warrior"]
            local template = mod.libraryInserts[4].steps[1]
            local copy = orc.stepById["tg-war-train-2"]
            assert.are_not.equal(template, copy)
            assert.equal(copy, orc.libCopies[template])
            assert.is_true(copy.shared)
            assert.is_true(copy.inserted)
            assert.equal(H.GUIDES_NAME, copy.library)
            assert.equal("Classes/Warrior.lua", copy.file)
            assert.equal("tg-war-frang", copy.anchor)
            assert.equal("tg-dur-01-valley-of-trials", copy.segment)
            -- a template that cannot match a route has no copy there; a segment step neither
            local troll = mod.routeById["tg-troll-mage"]
            assert.is_nil(troll.libCopies[template])
            assert.is_nil(troll.stepById["tg-dur-scorpids-orc"])
            assert.equal(H.GUIDES_NAME, troll.stepById["tg-dur-scorpids-troll"].library)
            assert.equal("Segments/Durotar/01_ValleyOfTrials.lua", troll.stepById["tg-dur-scorpids-troll"].file)
        end)

        it("opts.replace reads a TOC file from another path (a placeholder zone gets a fixture file)", function()
            local file = write("replace/Mulgore.lua", [[
if not FastesBoooy.AddLibraryInsert then return end
local _, ns = ...
FastesBoooy.AddLibrarySegment({ id = "tg-mul-01", title = "Camp Narache", zone = "Mulgore", levels = { 1, 3 }, steps = {
    { id = "tg-mul-747", accept = 747, npc = 2980, at = { 1412, 44.9, 77.1 } },
} })
ns.startZones = ns.startZones or {}
ns.startZones.Mulgore = { "tg-mul-01" }
]])
            local mod = Loader.LoadModule(H.GUIDES_DIR, { schema = Schema,
                replace = { ["Segments/Mulgore/01_CampNarache.lua"] = file } })
            assert.same({}, mod.errors)
            assert.same({ "tg-undead-paladin", "tg-orc-warrior", "tg-troll-mage", "tg-tauren-druid" }, H.ids(mod.routes))
            local tauren = mod.routeById["tg-tauren-druid"]
            assert.same({ "tg-mul-747" }, H.ids(tauren.steps))
            assert.same({ Tauren = true }, tauren.races)
            assert.same({ DRUID = true }, tauren.classes)
            assert.equal("Segments/Mulgore/01_CampNarache.lua", tauren.steps[1].file, "reported under the TOC path")
            assert.equal(9, #mod.files)
            -- the other routes are what they were
            assert.same(H.GUIDES_IDS["tg-orc-warrior"], H.ids(mod.routeById["tg-orc-warrior"].steps))

            -- mistakes: a key that is no TOC file, a replacement that does not exist
            mod = Loader.LoadModule(H.GUIDES_DIR, { schema = Schema, replace = { ["Segments/Nope.lua"] = file } })
            assert.same({ "FastesBoooy_TestGuides.toc: replace: Segments/Nope.lua is not a file of the TOC" }, messages(mod))
            mod = Loader.LoadModule(H.GUIDES_DIR, { schema = Schema,
                replace = { ["Races/Troll.lua"] = root .. "/replace/missing.lua" } })
            assert.equal(1, #mod.errors)
            assert.equal("Races/Troll.lua", mod.errors[1].file)
            assert.matches("^load error: cannot open .*missing%.lua", mod.errors[1].msg)
        end)

        it("opts.skip: a skipped class file takes its shared inserts with it", function()
            local mod = Loader.LoadModule(H.GUIDES_DIR, { schema = Schema, skip = { ["Classes/Warrior.lua"] = true } })
            assert.same({}, mod.errors)
            assert.same({ "tg-dur-4641", "tg-dur-788", "tg-dur-boars", "tg-dur-788-in", "tg-dur-scorpids-orc", "tg-dur-789-in" },
                H.ids(mod.routeById["tg-orc-warrior"].steps))
            assert.same(H.GUIDES_IDS["tg-troll-mage"], H.ids(mod.routeById["tg-troll-mage"].steps))
            assert.equal(4, #mod.libraryInserts)
            assert.is_nil(mod.lib.data.rewards.WARRIOR)
        end)

        it("reports shared-insert errors with the file of the insert; composition errors once per route", function()
            write("FastesBoooy_TMix/FastesBoooy_TMix.toc", TOC:format("Seg.lua\nIns.lua\nRoute.lua"))
            write("FastesBoooy_TMix/Seg.lua", [[
FastesBoooy.AddLibrarySegment({ id = "m-seg", title = "M", steps = {
    { accept = 363 },
    { id = "m-2", turnin = 363 },
} })
]])
            write("FastesBoooy_TMix/Ins.lua", [[
-- a positional anchor, twice: one composition error per route
FastesBoooy.AddLibraryInsert({ after = "m-seg:1", steps = { { id = "m-x", manual = true } } })
FastesBoooy.AddLibraryInsert({ after = "m-seg:1", steps = { { id = "m-y", manual = true } } })
-- a step without id: the insert is rejected
FastesBoooy.AddLibraryInsert({ after = "m-2", steps = { { id = "m-good", manual = true }, { manual = true } } })
-- an anchor no route has: no error of the loader (the validator's module checks see `applied`)
FastesBoooy.AddLibraryInsert({ after = "nowhere", class = "PALADN", steps = { { id = "m-z", manual = true } } })
]])
            write("FastesBoooy_TMix/Route.lua", [[
FastesBoooy.RegisterRoute({ api = 1, id = "r1", title = "R1", faction = "Horde", races = { "Scourge" },
    classes = { "PALADIN" }, aliases = "r0" })
FastesBoooy.UseSegments("r1", { "m-seg" })
FastesBoooy.RegisterRoute({ api = 1, id = "r2", title = "R2", faction = "Horde", races = { "Scourge" },
    classes = { "WARRIOR" }, aliases = { "r1", "r0", "r2-old" } })
FastesBoooy.UseSegments("r2", { "m-seg" })
FastesBoooy.RegisterRoute({ api = 1, id = "r2-old", title = "R3", faction = "Horde" })
]])
            local mod = Loader.LoadModule(root .. "/FastesBoooy_TMix", { schema = Schema })
            local pos = "AddLibraryInsert: anchor 'm-seg:1' is a positional step id: give the anchor step an explicit id"
            assert.same({
                "Ins.lua: library: insert after 'm-2' step 2: an explicit id is required in a shared insert",
                "Ins.lua: library: insert after 'nowhere': unknown class token 'PALADN'",
                "Route.lua: route r2: alias 'r1' is the id of a registered route (alias ignored)",
                "Route.lua: route r2: alias 'r0' is already used by route r1 (alias ignored)",
                "Route.lua: route r2-old: its id is an alias of route r2 (alias ignored)",
                "Ins.lua: route r1: " .. pos,
                "Ins.lua: route r2: " .. pos,
            }, messages(mod))
            for _, e in ipairs(mod.errors) do assert.is_nil(e.library, "the module's own errors") end
            assert.same({ "m-seg:1", "m-x", "m-y", "m-2" }, H.ids(mod.routeById.r1.steps))
            assert.equal(3, #mod.libraryInserts)
            assert.same({}, mod.libraryInserts[3].applied)
            assert.same({ r1 = true, r2 = true }, mod.libraryInserts[1].applied)
            assert.is_nil(mod.routeById.r1.stepById["m-good"])
            assert.equal(mod.routeById.r1, mod.aliases.r0)
            assert.is_nil(mod.aliases["r2-old"])
        end)

        it("shared inserts of a dependency apply to the routes of the module that uses it", function()
            write("FastesBoooy_TShLib/FastesBoooy_TShLib.toc",
                "## Interface: 16001\n## Dependencies: FastesBoooy\n## X-FastesBoooy-Module: library\nLib.lua\n")
            write("FastesBoooy_TShLib/Lib.lua", [[
FastesBoooy.AddLibrarySegment({ id = "sl", title = "SL", steps = { { accept = 363 }, { id = "sl-2", turnin = 363 } } })
FastesBoooy.AddLibraryInsert({ after = "sl:1", steps = { { id = "sl-pos", manual = true } } })
FastesBoooy.AddLibraryInsert({ before = "sl-2", class = "PALADIN", steps = { { id = "sl-pal", manual = true } } })
]])
            write("FastesBoooy_TShRoute/FastesBoooy_TShRoute.toc",
                "## Interface: 16001\n## Dependencies: FastesBoooy, FastesBoooy_TShLib\nRoute.lua\n")
            write("FastesBoooy_TShRoute/Route.lua", [[
FastesBoooy.RegisterRoute({ api = 1, id = "sh", title = "SH", faction = "Horde", races = { "Scourge" }, classes = { "PALADIN" } })
FastesBoooy.UseSegments("sh", { "sl" })
]])
            -- the library alone: declared, shared inserts and no route
            local lib = Loader.LoadModule(root .. "/FastesBoooy_TShLib", { schema = Schema })
            assert.same({}, lib.errors)
            assert.is_true(lib.isLibrary)
            assert.equal(2, #lib.libraryInserts)
            -- the route module: the dependency's inserts are not its own; errors carry the dependency
            local mod = Loader.LoadModule(root .. "/FastesBoooy_TShRoute", { schema = Schema })
            assert.same({ "sl:1", "sl-pos", "sl-pal", "sl-2" }, H.ids(mod.routes[1].steps))
            assert.equal(0, #mod.libraryInserts)
            assert.equal(2, #mod.lib.inserts)
            assert.equal(1, #mod.errors)
            assert.equal("FastesBoooy_TShLib/Lib.lua", mod.errors[1].file)
            assert.equal("FastesBoooy_TShLib", mod.errors[1].library)
            assert.matches("^route sh: AddLibraryInsert: anchor 'sl:1' is a positional step id", mod.errors[1].msg)
            assert.equal("FastesBoooy_TShLib", mod.routes[1].stepById["sl-pal"].library)
            -- a module that registers nothing but a shared insert is shared content too
            write("FastesBoooy_TOnlyIns/FastesBoooy_TOnlyIns.toc", TOC:format("Ins.lua"))
            write("FastesBoooy_TOnlyIns/Ins.lua",
                "FastesBoooy.AddLibraryInsert({ after = \"x\", steps = { { id = \"only\", manual = true } } })\n")
            local only = Loader.LoadModule(root .. "/FastesBoooy_TOnlyIns", { schema = Schema })
            assert.same({}, only.errors)
            assert.is_true(only.isLibrary)
        end)
    end)

    describe("gen_route_data", function()
        it("AddLibraryData covers the shared inserts; a route that owns nothing gets no AddRouteData block", function()
            local code, out = run("lua5.1 tools/gen_route_data.lua --stdout " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.is_nil(out:find("AddRouteData", 1, true), "Data.lua is listed before Route.lua: no route exists yet")
            local chunk = assert(loadstring(out))
            local captured, calls = nil, 0
            setfenv(chunk, { FastesBoooy = { AddLibraryData = function(d) captured, calls = d, calls + 1 end } })
            chunk()
            assert.equal(1, calls)
            -- segment steps
            assert.equal("Cutting Teeth", captured.quests[788])
            assert.equal("Kaltunk", captured.npcs[10176])
            -- shared-insert steps of every class and race file
            assert.equal("Simple Parchment", captured.quests[2383])
            assert.equal("Glyphic Tablet", captured.quests[3086])
            assert.equal("Frang", captured.npcs[3153])
            assert.equal("Mai'ah", captured.npcs[5884])
            assert.equal("Duokna", captured.npcs[3158])
            assert.equal("Aramis Hammerhand", captured.npcs[244808])
            assert.same({ level = 1, reqLevel = 1, preAny = { 788 } }, captured.questMeta[2383])
            -- the class reward table is hand-written data of the class files, not generated
            assert.is_nil(captured.rewards)
        end)

        it("the committed Data.lua of the fixture is up to date (--check)", function()
            local code, out = run("lua5.1 tools/gen_route_data.lua --check " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("FastesBoooy_TestGuides/Data.lua up to date", out)
        end)

        it("Gen.OwnsSteps: own segment steps or per-route inserts", function()
            local Gen = require("gen_route_data")
            local guides = Loader.LoadModule(H.GUIDES_DIR, { schema = Schema })
            for _, r in ipairs(guides.routes) do assert.is_false(Gen.OwnsSteps(r), r.id) end
            local composed = Loader.LoadModule(H.COMPOSED_DIR, { schema = Schema })
            assert.is_true(Gen.OwnsSteps(composed.routes[1]))
            local ids = Gen.CollectLibraryIds(guides)
            assert.is_true(ids.quests[2383])
            assert.is_true(ids.npcs[3158])
        end)
    end)

    describe("command lines on the fixture", function()
        it("validate_routes: three routes, 0 errors and 0 warnings with --strict", function()
            local code, out = run("lua5.1 tools/validate_routes.lua -q --strict " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("tg%-undead%-paladin %[Scourge PALADIN Horde%]: 0 error%(s%), 0 warning%(s%)", out)
            assert.matches("tg%-orc%-warrior %[Orc WARRIOR Horde%]: 0 error%(s%), 0 warning%(s%)", out)
            assert.matches("tg%-troll%-mage %[Troll MAGE Horde%]: 0 error%(s%), 0 warning%(s%)", out)
            assert.matches("validate_routes: 1 module%(s%), 0 error%(s%), 0 warning%(s%)", out)
        end)

        it("simulate_routes: every route plays to its end in the real engine", function()
            local code, out = run("lua5.1 tools/simulate_routes.lua " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("OK   tg%-undead%-paladin %(Scourge PALADIN Horde%): 11 steps", out)
            assert.matches("OK   tg%-orc%-warrior %(Orc WARRIOR Horde%): 9 steps", out)
            assert.matches("OK   tg%-troll%-mage %(Troll MAGE Horde%): 10 steps", out)
            assert.matches("simulate_routes: 3 simulation%(s%), 3 passed, 0 failed", out)
            code, out = run("lua5.1 tools/simulate_routes.lua --route tg-troll-mage " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("simulate_routes: 1 simulation%(s%), 1 passed, 0 failed", out)
        end)
    end)
end)
