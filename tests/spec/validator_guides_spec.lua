-- Offline tools on a MIXED module: one addon that registers shared segments, shared inserts
-- (AdventureAtlas.AddLibraryInsert) and several routes -- the shape of AdventureAtlas_Guides; fixture
-- tests/fixtures/core/AdventureAtlas_TestGuides. tools/lib/route_loader.lua (the AddLibraryInsert stub,
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

local TOC = "## Interface: 16001\n## Dependencies: AdventureAtlas\n%s\n"
-- the plain fixture route (no shared content): its turn-in of 3901 carries a step-level `reward`
local TEST_ROUTE_DIR = "tests/fixtures/core/AdventureAtlas_TestRoute"

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
if not AdventureAtlas.AddLibraryInsert then return end
local _, ns = ...
AdventureAtlas.AddLibrarySegment({ id = "tg-mul-01", title = "Camp Narache", zone = "Mulgore", levels = { 1, 3 }, steps = {
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
            assert.same({ "AdventureAtlas_TestGuides.toc: replace: Segments/Nope.lua is not a file of the TOC" }, messages(mod))
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
            write("AdventureAtlas_TMix/AdventureAtlas_TMix.toc", TOC:format("Seg.lua\nIns.lua\nRoute.lua"))
            write("AdventureAtlas_TMix/Seg.lua", [[
AdventureAtlas.AddLibrarySegment({ id = "m-seg", title = "M", steps = {
    { accept = 363 },
    { id = "m-2", turnin = 363 },
} })
]])
            write("AdventureAtlas_TMix/Ins.lua", [[
-- a positional anchor, twice: one composition error per route
AdventureAtlas.AddLibraryInsert({ after = "m-seg:1", steps = { { id = "m-x", manual = true } } })
AdventureAtlas.AddLibraryInsert({ after = "m-seg:1", steps = { { id = "m-y", manual = true } } })
-- a step without id: the insert is rejected
AdventureAtlas.AddLibraryInsert({ after = "m-2", steps = { { id = "m-good", manual = true }, { manual = true } } })
-- an anchor no route has: no error of the loader (the validator's module checks see `applied`)
AdventureAtlas.AddLibraryInsert({ after = "nowhere", class = "PALADN", steps = { { id = "m-z", manual = true } } })
-- an empty scope list: rejected as a whole (unscoped it would land in every route)
AdventureAtlas.AddLibraryInsert({ after = "m-2", class = {}, steps = { { id = "m-empty", manual = true } } })
-- the class reward table: shape errors are reported with the file (the data is merged as given)
AdventureAtlas.AddLibraryData({ rewards = { PALADIN = { [363] = 0 }, Paladin = { [363] = 1 } } })
]])
            write("AdventureAtlas_TMix/Route.lua", [[
AdventureAtlas.RegisterRoute({ api = 1, id = "r1", title = "R1", faction = "Horde", races = { "Scourge" },
    classes = { "PALADIN" }, aliases = "r0" })
AdventureAtlas.UseSegments("r1", { "m-seg" })
AdventureAtlas.RegisterRoute({ api = 1, id = "r2", title = "R2", faction = "Horde", races = { "Scourge" },
    classes = { "WARRIOR" }, aliases = { "r1", "r0", "r2-old" } })
AdventureAtlas.UseSegments("r2", { "m-seg" })
AdventureAtlas.RegisterRoute({ api = 1, id = "r2-old", title = "R3", faction = "Horde" })
]])
            local mod = Loader.LoadModule(root .. "/AdventureAtlas_TMix", { schema = Schema })
            local pos = "AddLibraryInsert: anchor 'm-seg:1' is a positional step id: give the anchor step an explicit id"
            assert.same({
                "Ins.lua: library: insert after 'm-2' step 2: an explicit id is required in a shared insert",
                "Ins.lua: library: insert after 'nowhere': unknown class token 'PALADN'",
                "Ins.lua: library: insert after 'm-2': class is an empty list: name at least one class token, or leave "
                    .. "the key out",
                "Ins.lua: library: insert after 'm-2': the insert is rejected: an empty scope list would apply it to "
                    .. "every route",
                "Ins.lua: AddLibraryData: rewards.PALADIN[363]: the choice must be a positive integer (got 0)",
                "Ins.lua: AddLibraryData: rewards.Paladin: unknown class token 'Paladin'",
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
            assert.is_nil(mod.routeById.r1.stepById["m-empty"])
            assert.equal(mod.routeById.r1, mod.aliases.r0)
            assert.is_nil(mod.aliases["r2-old"])
        end)

        it("shared inserts of a dependency apply to the routes of the module that uses it", function()
            write("AdventureAtlas_TShLib/AdventureAtlas_TShLib.toc",
                "## Interface: 16001\n## Dependencies: AdventureAtlas\n## X-AdventureAtlas-Module: library\nLib.lua\n")
            write("AdventureAtlas_TShLib/Lib.lua", [[
AdventureAtlas.AddLibrarySegment({ id = "sl", title = "SL", steps = { { accept = 363 }, { id = "sl-2", turnin = 363 } } })
AdventureAtlas.AddLibraryInsert({ after = "sl:1", steps = { { id = "sl-pos", manual = true } } })
AdventureAtlas.AddLibraryInsert({ before = "sl-2", class = "PALADIN", steps = { { id = "sl-pal", manual = true } } })
]])
            write("AdventureAtlas_TShRoute/AdventureAtlas_TShRoute.toc",
                "## Interface: 16001\n## Dependencies: AdventureAtlas, AdventureAtlas_TShLib\nRoute.lua\n")
            write("AdventureAtlas_TShRoute/Route.lua", [[
AdventureAtlas.RegisterRoute({ api = 1, id = "sh", title = "SH", faction = "Horde", races = { "Scourge" }, classes = { "PALADIN" } })
AdventureAtlas.UseSegments("sh", { "sl" })
]])
            -- the library alone: declared, shared inserts and no route
            local lib = Loader.LoadModule(root .. "/AdventureAtlas_TShLib", { schema = Schema })
            assert.same({}, lib.errors)
            assert.is_true(lib.isLibrary)
            assert.equal(2, #lib.libraryInserts)
            -- the route module: the dependency's inserts are not its own; errors carry the dependency
            local mod = Loader.LoadModule(root .. "/AdventureAtlas_TShRoute", { schema = Schema })
            assert.same({ "sl:1", "sl-pos", "sl-pal", "sl-2" }, H.ids(mod.routes[1].steps))
            assert.equal(0, #mod.libraryInserts)
            assert.equal(2, #mod.lib.inserts)
            assert.equal(1, #mod.errors)
            assert.equal("AdventureAtlas_TShLib/Lib.lua", mod.errors[1].file)
            assert.equal("AdventureAtlas_TShLib", mod.errors[1].library)
            assert.matches("^route sh: AddLibraryInsert: anchor 'sl:1' is a positional step id", mod.errors[1].msg)
            assert.equal("AdventureAtlas_TShLib", mod.routes[1].stepById["sl-pal"].library)
            -- a module that registers nothing but a shared insert is shared content too
            write("AdventureAtlas_TOnlyIns/AdventureAtlas_TOnlyIns.toc", TOC:format("Ins.lua"))
            write("AdventureAtlas_TOnlyIns/Ins.lua",
                "AdventureAtlas.AddLibraryInsert({ after = \"x\", steps = { { id = \"only\", manual = true } } })\n")
            local only = Loader.LoadModule(root .. "/AdventureAtlas_TOnlyIns", { schema = Schema })
            assert.same({}, only.errors)
            assert.is_true(only.isLibrary)
        end)
    end)

    describe("gen_route_data", function()
        it("AddLibraryData covers the shared inserts; a route that owns nothing gets no AddRouteData block", function()
            local code, out = run("lua5.1 tools/gen_route_data.lua --no-overrides --stdout " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.is_nil(out:find("AddRouteData", 1, true), "Data.lua is listed before Route.lua: no route exists yet")
            local chunk = assert(loadstring(out))
            local captured, calls = nil, 0
            setfenv(chunk, { AdventureAtlas = { AddLibraryData = function(d) captured, calls = d, calls + 1 end } })
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
            local code, out = run("lua5.1 tools/gen_route_data.lua --no-overrides --check " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("AdventureAtlas_TestGuides/Data.lua up to date", out)
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
            local code, out = run("lua5.1 tools/validate_routes.lua --no-overrides -q --strict " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("tg%-undead%-paladin %[Scourge PALADIN Horde%]: 0 error%(s%), 0 warning%(s%)", out)
            assert.matches("tg%-orc%-warrior %[Orc WARRIOR Horde%]: 0 error%(s%), 0 warning%(s%)", out)
            assert.matches("tg%-troll%-mage %[Troll MAGE Horde%]: 0 error%(s%), 0 warning%(s%)", out)
            assert.matches("validate_routes: 1 module%(s%), 0 error%(s%), 0 warning%(s%)", out)
        end)

        it("simulate_routes: every route plays to its end in the real engine", function()
            local code, out = run("lua5.1 tools/simulate_routes.lua --no-overrides " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("OK   tg%-undead%-paladin %(Scourge PALADIN Horde%): 11 steps", out)
            assert.matches("OK   tg%-orc%-warrior %(Orc WARRIOR Horde%): 9 steps", out)
            assert.matches("OK   tg%-troll%-mage %(Troll MAGE Horde%): 10 steps", out)
            assert.matches("simulate_routes: 3 simulation%(s%), 3 passed, 0 failed", out)
            code, out = run("lua5.1 tools/simulate_routes.lua --no-overrides --route tg-troll-mage " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.matches("simulate_routes: 1 simulation%(s%), 1 passed, 0 failed", out)
        end)
    end)

    -- docs/dev/PLAN.md A.6.5: the class reward table (AdventureAtlas.AddLibraryData{ rewards = { CLASS =
    -- { [quest] = index } } }) is exercised end to end. The fixture turns 789 (Durotar) and 3901
    -- (Deathknell) in on shared steps without a `reward`; Classes/*.lua name the choice per class.
    describe("simulate_routes: reward choices from the class reward table", function()
        it("resolves the expected choice like the engine and asserts the index the automation took", function()
            local code, out = run("lua5.1 tools/simulate_routes.lua --no-overrides --verbose " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            -- the same quest, another choice per class; the paladin's quest is another one
            assert.matches("\n    reward choice 2 of quest 3901 %(class table PALADIN%)\n", out)
            assert.matches("\n    reward choice 1 of quest 789 %(class table WARRIOR%)\n", out)
            assert.matches("\n    reward choice 2 of quest 789 %(class table MAGE%)\n", out)
            local _, n = out:gsub("\n    reward choice %d+ of quest %d+ %(", "")
            assert.equal(3, n, "one reward choice per route, none for the other turn-ins")
            for _, id in ipairs(H.GUIDES_ROUTES) do
                assert.matches("OK   " .. id:gsub("%-", "%%-") .. " [^\n]*, 1 reward choice%(s%) checked; ", out)
            end
        end)

        it("a step-level `reward` still wins, and is named as the source", function()
            local code, out = run("lua5.1 tools/simulate_routes.lua --no-overrides --verbose " .. TEST_ROUTE_DIR)
            assert.equal(0, code, out)
            assert.matches("\n    reward choice %d+ of quest %d+ %(step [^\n]+%)\n", out)
            assert.is_nil(out:find("class table", 1, true))
        end)

        -- A second repository root with a COPY of the core whose engine ignores the class table (or
        -- reads it wrongly); tools, tests and the fixture are this checkout's. The simulator must fail.
        local function brokenCore(name, from, to)
            local p = assert(io.popen("pwd"))
            local here = p:read("*l")
            p:close()
            local alt = root .. "/" .. name
            os.execute(("mkdir -p '%s/addons'"):format(alt))
            assert.equal(0, (run(("cp -R '%s/addons/AdventureAtlas' '%s/addons/AdventureAtlas'"):format(here, alt))))
            for _, link in ipairs({ "tests", "tools" }) do
                assert.equal(0, (run(("ln -s '%s/%s' '%s/%s'"):format(here, link, alt, link))))
            end
            local path = alt .. "/addons/AdventureAtlas/Core/Engine.lua"
            local fh = assert(io.open(path, "rb"))
            local text = fh:read("*a")
            fh:close()
            local s, e = text:find(from, 1, true)
            assert.is_truthy(s, "Engine:GetRewardChoice reads the class table with this line")
            fh = assert(io.open(path, "wb"))
            fh:write(text:sub(1, s - 1) .. to .. text:sub(e + 1))
            fh:close()
            return function(args)
                return run(("cd '%s' && lua5.1 tools/simulate_routes.lua --no-overrides %s"):format(alt, args))
            end
        end
        local TABLE_LINE = 'local idx = type(mine) == "table" and mine[questID] or nil'

        it("fails when the engine does not read the table (the reward window stays open)", function()
            local sim = brokenCore("no-table", TABLE_LINE, "local idx = mine and nil")
            local code, out = sim("--route tg-troll-mage " .. H.GUIDES_DIR)
            assert.equal(1, code, out)
            assert.matches("FAIL tg%-troll%-mage [^\n]*the automation did not turn in quest 789", out)
            -- the unbroken part still passes there: the copy is otherwise the real core
            code, out = sim(TEST_ROUTE_DIR)
            assert.equal(0, code, out)
        end)

        it("fails when the engine takes another index than the table says", function()
            local sim = brokenCore("wrong-index", TABLE_LINE,
                'local idx = type(mine) == "table" and mine[questID] and 1 or nil')
            local code, out = sim("--route tg-troll-mage " .. H.GUIDES_DIR)
            assert.equal(1, code, out)
            assert.matches("FAIL tg%-troll%-mage [^\n]*quest 789 turned in with reward choice 1, the route wants 2 "
                .. "%(class table MAGE%)", out)
            -- the warrior's entry IS 1: that route passes with the same broken engine
            code, out = sim("--route tg-orc-warrior " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
        end)
    end)

    -- docs/dev/PLAN.md A.6.5 / A.7: `make simulate` builds its job list from this output
    describe("simulate_routes --list-routes", function()
        local LIST = "lua5.1 tools/simulate_routes.lua --no-overrides --list-routes "

        local function onlyStdout(cmd)
            local p = assert(io.popen(cmd .. " 2>/dev/null"))
            local out = p:read("*a")
            p:close()
            return out
        end

        it("prints one route id per line, in registration order, and simulates nothing", function()
            local code, out = run(LIST .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.equal(table.concat(H.GUIDES_ROUTES, "\n") .. "\n", out)
            -- several modules: in the order given; a library module has no route and prints nothing
            code, out = run(LIST .. H.COMPOSED_DIR .. " " .. H.LIB_DIR .. " " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.equal("test-composed\n" .. table.concat(H.GUIDES_ROUTES, "\n") .. "\n", out)
        end)

        it("without directories: the modules under addons, with --fixtures also the core fixtures", function()
            -- what the route modules of this checkout register (a module that does not load cleanly --
            -- another author's half-written file in a parallel phase -- must give exit 1 and no list)
            local expected, clean = {}, true
            for _, dir in ipairs(Loader.DiscoverModules("addons")) do
                local mod = Loader.LoadModule(dir, { schema = Schema })
                if #mod.errors > 0 then clean = false end
                for _, r in ipairs(mod.routes) do expected[#expected + 1] = r.id end
            end
            local code, out = run(LIST)
            if not clean then
                assert.equal(1, code, out)
                assert.equal("", onlyStdout(LIST))
                return
            end
            assert.equal(0, code, out)
            assert.is_true(#expected > 0)
            assert.equal(table.concat(expected, "\n") .. "\n", out)
            assert.is_nil(out:find("OK   ", 1, true))
            code, out = run(LIST .. "--fixtures")
            assert.equal(0, code, out)
            assert.matches("\ntest%-route\n", out)
            assert.matches("\ntg%-troll%-mage\n", out)
        end)

        it("honours --route and the file filter", function()
            local code, out = run(LIST .. "--route 'tg-*-mage,tg-orc-*' " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.equal("tg-orc-warrior\ntg-troll-mage\n", out)
            -- the Durotar zone file announces the Orc and Troll routes: without it only the Undead is left
            code, out = run(LIST .. "--skip 'Segments/Durotar/*' --skip 'Classes/*' --skip 'Races/*' " .. H.GUIDES_DIR)
            assert.equal(0, code, out)
            assert.equal("tg-undead-paladin\n", out)
            code, out = run(LIST .. "--route tg-nobody " .. H.GUIDES_DIR)
            assert.equal(1, code, out)
            assert.matches("%-%-route tg%-nobody matched no route", out)
            code, out = run(LIST .. "--skip 'Nope/*' " .. H.GUIDES_DIR)
            assert.equal(2, code, out)
        end)

        it("a module with load errors: exit 1, a message on stderr and NO id on stdout", function()
            write("AdventureAtlas_LrBroken/AdventureAtlas_LrBroken.toc", TOC:format("Route.lua\nSegments.lua"))
            write("AdventureAtlas_LrBroken/Route.lua", [[
AdventureAtlas.RegisterRoute({ api = 1, id = "lr-broken", title = "t", faction = "Horde", races = { "Scourge" },
    classes = { "PALADIN" } })
]])
            write("AdventureAtlas_LrBroken/Segments.lua", "AdventureAtlas.AddSegment('lr-broken', { id = 's', steps = { {\n")
            local broken = root .. "/AdventureAtlas_LrBroken"
            local code, out = run(LIST .. broken)
            assert.equal(1, code, out)
            assert.matches("%-%-list%-routes: AdventureAtlas_LrBroken: %d+ load/schema error%(s%)", out)
            assert.matches("Segments%.lua: ", out)
            assert.matches("did not load: no route list", out)
            -- a good module next to it does not make the list "partly" valid
            code, out = run(LIST .. H.GUIDES_DIR .. " " .. broken)
            assert.equal(1, code, out)
            assert.equal("", onlyStdout(LIST .. H.GUIDES_DIR .. " " .. broken))
            assert.equal("", onlyStdout(LIST .. broken))
            -- no TOC at all
            os.execute(("mkdir -p '%s/AdventureAtlas_LrEmpty'"):format(root))
            code, out = run(LIST .. root .. "/AdventureAtlas_LrEmpty")
            assert.equal(1, code, out)
            assert.matches("no TOC", out)
        end)

        it("takes no simulation options", function()
            for _, extra in ipairs({ "--ahead 10", "--level-plus 2", "--profile race=Orc,class=WARRIOR",
                "--write-state /dev/null" }) do
                local code, out = run(LIST .. extra .. " " .. H.GUIDES_DIR)
                assert.equal(2, code, extra .. ": " .. out)
                assert.matches("%-%-list%-routes only lists route ids", out)
            end
        end)
    end)
end)
