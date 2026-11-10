-- Validator on a MIXED module (shared segments + shared inserts + routes, the shape of
-- FastesBoooy_Guides), docs/dev/PLAN.md A.6.1 / A.6.2:
--   * the checks on the shared TEMPLATES (tools/lib/module_checks.lua): unknown-race-token,
--     insert-anchor-unknown, insert-unapplied, shared-step-unused, insert-scope-wider-than-anchor,
--     shared-unused; which modules get them; step-no-profile only for a route's own steps;
--   * the file filter (--skip / --keep) in the loader, the validator, the simulator (Mock.loadAddon)
--     and gen_route_data --stdout; own files (--own): template checks of files that are not own are
--     notes on a partial load;
--   * --skip / --keep / --own globs that match no file are refused (exit 2);
--   * --route lists with `*` wildcards, repeatable (validator and simulator); with --route only the
--     errors that belong to a route outside the selection are notes (a file that does not load always
--     counts);
--   * --harness on a mixed module (validator and simulator).
-- The modules are written to a temporary directory: real Forever quests of Deathknell and the Valley
-- of Trials, as in tests/fixtures/core/FastesBoooy_TestGuides.

local DB = require("lib.fbdb")
local Loader = require("lib.route_loader")
local V = require("lib.validator")
local Glob = require("lib.glob")
local Harness = require("lib.harness")
local Mock = require("mocks.wow")
local H = require("fixtures.core.helpers")

local db, schema, root

local function run(cmd)
    local p = assert(io.popen(cmd .. " 2>&1; echo \"__EXIT=$?\""))
    local out = p:read("*a")
    p:close()
    local code = tonumber(out:match("__EXIT=(%d+)%s*$"))
    return code, (out:gsub("__EXIT=%d+%s*$", ""))
end

local function write(path, content)
    os.execute(("mkdir -p '%s'"):format((root .. "/" .. path):match("^(.*)/[^/]+$")))
    local fh = assert(io.open(root .. "/" .. path, "wb"))
    fh:write(content)
    fh:close()
    return root .. "/" .. path
end

local VALIDATE = "lua5.1 tools/validate_routes.lua --no-overrides "
local SIMULATE = "lua5.1 tools/simulate_routes.lua --no-overrides "

-- the files of the default module (two start zones, two classes, one race file, two routes)
local FILES = {
    ["Segments/Tirisfal.lua"] = [[
local _, ns = ...
FastesBoooy.AddLibrarySegment({ id = "mx-ud", title = "Deathknell", zone = "Tirisfal Glades", levels = { 1, 2 }, steps = {
    { id = "mx-ud-363", accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
    { id = "mx-ud-364", turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
    { id = "mx-ud-zombies", complete = 364, at = { 1420, 32.5, 63.5 } },
    { id = "mx-ud-364-in", turnin = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
} })
ns.zones = ns.zones or {}
ns.zones.Scourge = { "mx-ud" }
]],
    ["Segments/Durotar.lua"] = [[
local _, ns = ...
FastesBoooy.AddLibrarySegment({ id = "mx-dur", title = "Valley of Trials", zone = "Durotar", levels = { 1, 2 }, steps = {
    { id = "mx-dur-4641", accept = 4641, npc = 10176, at = { 1411, 43.3, 68.5 } },
    { id = "mx-dur-788", turnin = 4641, accept = 788, npc = 3143, at = { 1411, 42.1, 68.3 } },
    { id = "mx-dur-boars", complete = 788, at = { 1411, 45.2, 66.9 } },
    { id = "mx-dur-788-in", turnin = 788, npc = 3143, at = { 1411, 42.1, 68.3 } },
    { id = "mx-dur-orc-only", race = "Orc", go = true, at = { 1411, 42.6, 69.0 }, note = "Back to the Den" },
} })
ns.zones = ns.zones or {}
ns.zones.Orc = { "mx-dur" }
]],
    ["Classes/Paladin.lua"] = [[
FastesBoooy.AddLibraryInsert({ after = "mx-ud-364-in", class = "PALADIN", steps = {
    { id = "mx-pal-train", train = true, npc = 244808, at = { 1420, 31.1, 66.4 } },
} })
]],
    ["Classes/Warrior.lua"] = [[
FastesBoooy.AddLibraryInsert({ after = "mx-dur-788-in", class = "WARRIOR", steps = {
    { id = "mx-war-train", train = true, npc = 3153, at = { 1411, 42.9, 69.4 } },
} })
]],
    ["Races/Orc.lua"] = [[
FastesBoooy.AddLibraryInsert({ after = "mx-dur-orc-only", race = "Orc", steps = {
    { id = "mx-orc-vendor", vendor = true, npc = 3158, at = { 1411, 42.6, 67.3 } },
} })
]],
    ["Route.lua"] = [=[
local _, ns = ...
local ROUTES = { { "mx-undead-paladin", "Scourge", "PALADIN" }, { "mx-orc-warrior", "Orc", "WARRIOR" } }
for i = 1, #ROUTES do
    local r = ROUTES[i]
    local zone = ns.zones and ns.zones[r[2]]
    if zone then
        FastesBoooy.RegisterRoute({ api = 1, id = r[1], title = r[1], faction = "Horde", races = { r[2] },
            classes = { r[3] }, levels = { 1, 2 } })
        FastesBoooy.UseSegments(r[1], zone)
    end
end
]=],
}
local ORDER = { "Segments/Tirisfal.lua", "Segments/Durotar.lua", "Classes/Paladin.lua", "Classes/Warrior.lua",
    "Races/Orc.lua", "Route.lua" }

local counter = 0

-- write a module: the default files, each replaced / extended by `changes[path]`
-- (a string replaces the file, a table { append = "..." } adds to it)
local function module(changes)
    counter = counter + 1
    local name = "FastesBoooy_Mx" .. counter
    local toc = { "## Interface: 16001", "## Dependencies: FastesBoooy" }
    for _, path in ipairs(ORDER) do
        toc[#toc + 1] = (path:gsub("/", "\\"))
        local text = FILES[path]
        local c = changes and changes[path]
        if type(c) == "string" then text = c
        elseif type(c) == "table" then text = text .. c.append end
        write(name .. "/" .. path, text)
    end
    write(name .. "/" .. name .. ".toc", table.concat(toc, "\n") .. "\n")
    return root .. "/" .. name, name
end

local function validate(dir, opts)
    local o = { db = db, schema = schema }
    for k, v in pairs(opts or {}) do o[k] = v end
    return V.ValidateModule(dir, o)
end

-- "CODE file id" of every message of a result with this severity (default ERROR)
local function listed(result, severity)
    local out = {}
    for _, m in ipairs(result.messages) do
        if m.severity == (severity or "ERROR") then
            out[#out + 1] = ("%s %s %s"):format(m.code, tostring(m.file), tostring(m.stepId or m.segment))
        end
    end
    return out
end

local function with(result, code)
    local out = {}
    for _, m in ipairs(result.messages) do
        if m.code == code then out[#out + 1] = m end
    end
    return out
end

local function own(...)
    local globs = { ... }
    return function(file) return Glob.Any(globs, file) end
end

describe("validator on a mixed module", function()
    setup(function()
        db = DB.Load("tools/data/forever_db.lua")
        schema = Loader.LoadSchema(".")
        root = os.tmpname()
        os.remove(root)
        os.execute(("mkdir -p '%s'"):format(root))
    end)
    teardown(function() os.execute(("rm -rf '%s'"):format(root)) end)

    describe("globs (tools/lib/glob.lua)", function()
        it("`*` matches any run of characters, the whole string must match, the rest is literal", function()
            assert.is_true(Glob.Match("Classes/*", "Classes/Warrior.lua"))
            assert.is_true(Glob.Match("Segments/*", "Segments/Durotar/01_Valley.lua"))
            assert.is_true(Glob.Match("*-warrior", "orc-warrior"))
            assert.is_true(Glob.Match("orc-*", "orc-warrior"))
            assert.is_false(Glob.Match("orc-*", "troll-orc-x"))
            assert.is_false(Glob.Match("Classes/Warrior.lua", "Classes/WarriorXlua"), "a dot is a dot")
            assert.is_false(Glob.Match("Classes", "Classes/Warrior.lua"))
            assert.is_true(Glob.Match("Classes\\Warrior.lua", "Classes/Warrior.lua"), "backslashes are slashes")
            assert.is_false(Glob.Any({}, "x"))
            assert.is_false(Glob.Any(nil, "x"))
        end)

        it("a file is skipped when it matches a skip glob and no keep glob", function()
            assert.is_true(Glob.Skipped("Classes/Mage.lua", { "Classes/*" }, { "Classes/Warrior.lua" }))
            assert.is_false(Glob.Skipped("Classes/Warrior.lua", { "Classes/*" }, { "Classes/Warrior.lua" }))
            assert.is_false(Glob.Skipped("Route.lua", { "Classes/*" }, nil))
            assert.is_false(Glob.Skipped("Classes/Mage.lua", nil, { "Classes/*" }), "a keep without a skip does nothing")
        end)

        it("a comma list remembers the entries that matched nothing", function()
            local list = Glob.NewList("orc-*, troll-mage,tauren-*")
            assert.is_true(Glob.ListMatch(list, "orc-warrior"))
            assert.is_true(Glob.ListMatch(list, "troll-mage"))
            assert.is_false(Glob.ListMatch(list, "undead-paladin"))
            assert.same({ "tauren-*" }, Glob.Unmatched(list))
        end)

        it("the globs of a list that match none of the strings", function()
            local files = { { "Classes/Warrior.lua", "Route.lua" }, { "Segments/A.lua" } }
            assert.same({}, Glob.UnmatchedIn({ "Classes/*", "Segments/A.lua", "*" }, files))
            assert.same({ "Clases/*", "classes/warrior.lua" },
                Glob.UnmatchedIn({ "Clases/*", "Route.lua", "classes/warrior.lua" }, files))
            assert.same({}, Glob.UnmatchedIn(nil, files))
            assert.same({ "x" }, Glob.UnmatchedIn({ "x" }, {}))
        end)
    end)

    describe("template checks", function()
        it("the default module and the fixture are clean; the module gets one more entry", function()
            local res = validate((module()))
            assert.equal(3, #res.results)
            local shared = res.results[1]
            assert.equal(res.module, shared.shared)
            assert.equal("(shared " .. res.module .. ")", shared.route)
            assert.equal("shared: 2 segment(s), 3 insert(s), 12 step(s)", shared.profileLabel)
            assert.same({}, shared.messages)
            assert.same({}, res.notes)
            for i = 2, 3 do assert.same({ ERROR = 0, WARN = 0, INFO = res.results[i].counts.INFO }, res.results[i].counts) end
            local fixture = validate(H.GUIDES_DIR)
            assert.equal("shared: 2 segment(s), 6 insert(s), 25 step(s)", fixture.results[1].profileLabel)
            assert.same({}, fixture.results[1].messages)
            assert.equal(4, #fixture.results)
        end)

        it("unknown-race-token: a template step with race = \"Undead\" is composed nowhere and still reported", function()
            local dir = module({ ["Segments/Tirisfal.lua"] = { append = [[
FastesBoooy.AddLibrarySegment({ id = "mx-ud-2", title = "More", steps = {
    { id = "mx-ud-bad-race", race = "Undead", go = true, at = { 1420, 30.2, 71.7 } },
    { id = "mx-ud-ok", go = true, at = { 1420, 30.2, 71.7 } },
} })
ns.zones.Scourge[2] = "mx-ud-2"
]] } })
            local res = validate(dir)
            local shared = res.results[1]
            assert.same({ "unknown-race-token Segments/Tirisfal.lua mx-ud-bad-race" }, listed(shared))
            local m = shared.messages[1]
            assert.matches("step 'mx%-ud%-bad%-race': race filter: unknown raceFile 'Undead' "
                .. "%(the raceFile of the Undead is \"Scourge\"%)", m.msg)
            assert.equal("mx-ud-2", m.segment)
            assert.equal(1, m.step)
            assert.is_true(m.shared)
            assert.equal(res.module, m.library)
            -- invisible in the composed routes (the classic mistake no per-route check can see)
            for i = 2, #res.results do assert.equal(0, res.results[i].counts.ERROR) end
            assert.is_nil(res.mod.routeById["mx-undead-paladin"].stepById["mx-ud-bad-race"])
            assert.equal(1, shared.counts.ERROR)
        end)

        it("unknown-race-token: the scope of an insert once, a step's own race filter per step", function()
            local dir = module({ ["Classes/Warrior.lua"] = { append = [[
FastesBoooy.AddLibraryInsert({ after = "mx-dur-788-in", class = "WARRIOR", race = "Orcs", steps = {
    { id = "mx-war-a", go = true, at = { 1411, 42.6, 69.0 } },
    { id = "mx-war-b", go = true, at = { 1411, 42.6, 69.0 } },
} })
FastesBoooy.AddLibraryInsert({ after = "mx-dur-788-in", class = "WARRIOR", steps = {
    { id = "mx-war-c", race = "Trol", go = true, at = { 1411, 42.6, 69.0 } },
} })
]] } })
            local shared = validate(dir).results[1]
            assert.same({ "unknown-race-token Classes/Warrior.lua mx-war-a", "unknown-race-token Classes/Warrior.lua mx-war-c" },
                listed(shared))
            assert.matches("shared insert after 'mx%-dur%-788%-in': race scope: unknown raceFile 'Orcs' %(known: Dwarf, ",
                shared.messages[1].msg)
            assert.matches("step 'mx%-war%-c' of shared insert after 'mx%-dur%-788%-in': race filter: unknown raceFile 'Trol'",
                shared.messages[2].msg)
            -- a template step has no segment before composition: its id is in the location
            assert.equal("[library " .. shared.module .. "] id=mx-war-a (Classes/Warrior.lua)", V.LocStr(shared.messages[1]))
        end)

        it("insert-anchor-unknown: a misspelled anchor", function()
            local dir = module({ ["Classes/Paladin.lua"] = { append = [[
FastesBoooy.AddLibraryInsert({ after = "mx-ud-364-inn", class = "PALADIN", steps = {
    { id = "mx-pal-x", go = true, at = { 1420, 30.2, 71.7 } },
    { id = "mx-pal-y", go = true, at = { 1420, 30.2, 71.7 } },
} })
]] } })
            local res = validate(dir)
            assert.same({ "insert-anchor-unknown Classes/Paladin.lua mx-pal-x" }, listed(res.results[1]))
            assert.matches("shared insert after 'mx%-ud%-364%-inn' %(2 step%(s%), first 'mx%-pal%-x'%): the anchor is the id "
                .. "of no loaded step$", res.results[1].messages[1].msg)
            assert.same({}, res.mod.errors, "the core and the loader do not treat it as an error")
        end)

        it("insert-anchor-unknown under --skip: an error for own files, a note for the others", function()
            local changes = { ["Classes/Paladin.lua"] = { append = [[
FastesBoooy.AddLibraryInsert({ after = "mx-nowhere", class = "PALADIN", steps = {
    { id = "mx-pal-x", go = true, at = { 1420, 30.2, 71.7 } },
} })
]] } }
            local dir = module(changes)
            local filter = { skipGlobs = { "Races/*" } }
            -- without --own every loaded file is own
            local res = validate(dir, filter)
            assert.is_true(res.mod.filtered)
            assert.same({ "insert-anchor-unknown Classes/Paladin.lua mx-pal-x" }, listed(res.results[1]))
            assert.matches("%(files are skipped: the anchor may live in one of them%)$", res.results[1].messages[1].msg)
            assert.same({}, res.notes)
            -- the file is own: still an error
            filter.isOwn, filter.ownGiven = own("Classes/Paladin.lua"), true
            res = validate(dir, filter)
            assert.same({ "insert-anchor-unknown Classes/Paladin.lua mx-pal-x" }, listed(res.results[1]))
            assert.same({}, res.notes)
            -- another agent's file: a note, the run is clean
            filter.isOwn = own("Classes/Warrior.lua")
            res = validate(dir, filter)
            assert.same({}, listed(res.results[1]))
            assert.equal(0, res.results[1].counts.ERROR)
            assert.equal(1, #res.notes)
            assert.equal("insert-anchor-unknown", res.notes[1].code)
            assert.equal("Classes/Paladin.lua", res.notes[1].file)
            assert.matches("^partial load", res.notes[1].note)
            -- on a full load --own does not turn an error into a note (errors always count)
            res = validate(dir, { isOwn = own("Classes/Warrior.lua"), ownGiven = true })
            assert.same({ "insert-anchor-unknown Classes/Paladin.lua mx-pal-x" }, listed(res.results[1]))

            -- the command line: exit status and the printed note
            local code, out = run(VALIDATE .. "-q --strict --skip 'Races/*' --own Classes/Warrior.lua " .. dir)
            assert.equal(0, code, out)
            assert.matches("  note  %[library FastesBoooy_Mx%d+%] id=mx%-pal%-x %(Classes/Paladin.lua%) %[insert%-anchor%-unknown%] "
                .. "shared insert after 'mx%-nowhere'.- %-%- not counted: partial load", out)
            code, out = run(VALIDATE .. "-q --skip 'Races/*' --own Classes/Paladin.lua " .. dir)
            assert.equal(1, code, out)
            assert.matches("%(shared FastesBoooy_Mx%d+%) %[shared: 2 segment%(s%), 3 insert%(s%), 12 step%(s%)%]: 1 error%(s%)", out)
            code = run(VALIDATE .. "-q --skip 'Races/*' " .. dir)
            assert.equal(1, code)
        end)

        it("insert-unapplied: the anchor exists, routes match the scope, none of them has the anchor", function()
            local dir = module({ ["Races/Orc.lua"] = { append = [[
-- an anchor of the other start zone
FastesBoooy.AddLibraryInsert({ after = "mx-ud-364-in", race = "Orc", steps = {
    { id = "mx-orc-lost", go = true, at = { 1420, 30.2, 71.7 } },
} })
]] } })
            local shared = validate(dir).results[1]
            assert.same({ "insert-unapplied Races/Orc.lua mx-orc-lost" }, listed(shared))
            assert.matches("the anchor exists, and 1 loaded route%(s%) can match the insert's scope %(race=Orc%), but none "
                .. "of them contains the anchor", shared.messages[1].msg)
        end)

        it("shared-step-unused: a template step no loaded route composes", function()
            local dir = module({
                ["Segments/Durotar.lua"] = { append = [[
FastesBoooy.AddLibrarySegment({ id = "mx-dur-2", title = "More", steps = {
    { id = "mx-dur-druid", class = "DRUID", go = true, at = { 1411, 42.6, 69.0 } },
    { id = "mx-dur-all", go = true, at = { 1411, 42.6, 69.0 } },
} })
ns.zones.Orc[2] = "mx-dur-2"
]] },
                ["Classes/Warrior.lua"] = { append = [[
-- one step of the insert is for a race without a warrior route
FastesBoooy.AddLibraryInsert({ after = "mx-dur-788-in", class = "WARRIOR", steps = {
    { id = "mx-war-troll", race = "Troll", go = true, at = { 1411, 42.6, 69.0 } },
    { id = "mx-war-any", go = true, at = { 1411, 42.6, 69.0 } },
} })
-- a whole insert for a class that has no route here
FastesBoooy.AddLibraryInsert({ after = "mx-dur-788-in", class = "MAGE", steps = {
    { id = "mx-mage-1", go = true, at = { 1411, 42.6, 69.0 } },
    { id = "mx-mage-2", go = true, at = { 1411, 42.6, 69.0 } },
} })
]] },
            })
            local res = validate(dir)
            local shared = res.results[1]
            assert.same({
                "shared-step-unused Segments/Durotar.lua mx-dur-druid",
                "shared-step-unused Classes/Warrior.lua mx-war-troll",
                "shared-step-unused Classes/Warrior.lua mx-mage-1",
            }, listed(shared))
            assert.matches("step 'mx%-dur%-druid' %(class=DRUID%) is composed into no loaded route: its filter matches none "
                .. "of the 2 route%(s%)", shared.messages[1].msg)
            assert.matches("step 'mx%-war%-troll' of shared insert after 'mx%-dur%-788%-in' %(class=WARRIOR race=Troll%)",
                shared.messages[2].msg)
            assert.matches("none of its 2 step%(s%) %(first 'mx%-mage%-1', scope class=MAGE%) is composed into a loaded route",
                shared.messages[3].msg)
            -- it replaces the per-route step-no-profile for shared steps: the routes say nothing
            for i = 2, #res.results do assert.same({}, with(res.results[i], "step-no-profile")) end
        end)

        it("insert-scope-wider-than-anchor: an insert on a filtered anchor states the anchor's scope", function()
            local dir = module({ ["Classes/Warrior.lua"] = { append = [[
-- the anchor is race = "Orc": the insert must say so too
FastesBoooy.AddLibraryInsert({ after = "mx-dur-orc-only", class = "WARRIOR", steps = {
    { id = "mx-war-wide", go = true, at = { 1411, 42.6, 69.0 } },
    { id = "mx-war-fine", race = "Orc", go = true, at = { 1411, 42.6, 69.0 } },
} })
]] } })
            local res = validate(dir)
            local shared = res.results[1]
            assert.same({ "insert-scope-wider-than-anchor Classes/Warrior.lua mx-war-wide" }, listed(shared))
            assert.matches("the anchor step is filtered %(race=Orc%), but 1 step%(s%) of the insert %(mx%-war%-wide%) are not "
                .. "limited to it in race", shared.messages[1].msg)
            -- the core composes it all the same (rule 9 keeps it out of the other routes)
            assert.is_truthy(res.mod.routeById["mx-orc-warrior"].stepById["mx-war-wide"])
            -- the default module's race file states race = "Orc" on the same anchor: clean (first test)
        end)

        it("shared-unused: a shared segment no route uses; only on a full load; `ok` on the segment accepts it", function()
            local extra = [[
FastesBoooy.AddLibrarySegment({ id = "mx-spare", title = "Spare", %s steps = {
    { id = "mx-spare-1", go = true, at = { 1420, 30.2, 71.7 } },
} })
]]
            local dir = module({ ["Segments/Tirisfal.lua"] = { append = extra:format("") } })
            local res = validate(dir)
            local shared = res.results[1]
            assert.same({ "shared-unused Segments/Tirisfal.lua mx-spare" }, listed(shared, "WARN"))
            assert.same({}, listed(shared), "its steps are not reported one by one")
            assert.matches("shared segment 'mx%-spare' %(1 step%(s%)%) is used by no route", shared.messages[1].msg)
            assert.equal(1, shared.counts.WARN)
            -- a partial load cannot know
            res = validate(dir, { skipGlobs = { "Races/*" } })
            assert.same({}, res.results[1].messages)
            -- acknowledged on the segment
            dir = module({ ["Segments/Tirisfal.lua"] = { append = extra:format("ok = \"shared-unused\",") } })
            shared = validate(dir).results[1]
            assert.equal(0, shared.counts.WARN)
            assert.equal(1, shared.acceptedWarn)
            assert.is_true(shared.messages[1].accepted)
        end)

        it("ok-needs-ceiling: level-grind in `ok` of a template step without a ceiling", function()
            local dir = module({ ["Segments/Tirisfal.lua"] = { append = [[
FastesBoooy.AddLibrarySegment({ id = "mx-ud-2", title = "More", steps = {
    { id = "mx-ud-gate", level = 2, ok = "level-grind" },
    { id = "mx-ud-gate-2", level = 2, ok = { ["level-grind"] = 50 } },
} })
ns.zones.Scourge[2] = "mx-ud-2"
]] } })
            local res = validate(dir)
            assert.same({ "ok-needs-ceiling Segments/Tirisfal.lua mx-ud-gate" }, listed(res.results[1]))
            -- once, on the template: the routes do not repeat it
            for i = 2, #res.results do assert.same({}, with(res.results[i], "ok-needs-ceiling")) end
        end)

        it("ok-needs-ceiling is an ERROR in any file, also on a partial load: it depends on no other file", function()
            local dir = module({ ["Segments/Durotar.lua"] = { append = [[
FastesBoooy.AddLibrarySegment({ id = "mx-dur-2", title = "More", steps = {
    { id = "mx-dur-gate", level = 2, ok = "level-grind" },
} })
ns.zones.Orc[2] = "mx-dur-2"
]] } })
            -- the class agent's run: the segment file is loaded and is not own
            local filter = { skipGlobs = { "Classes/*" }, keepGlobs = { "Classes/Warrior.lua" },
                isOwn = own("Classes/Warrior.lua"), ownGiven = true }
            local res = validate(dir, filter)
            assert.is_true(res.mod.filtered)
            assert.same({ "ok-needs-ceiling Segments/Durotar.lua mx-dur-gate" }, listed(res.results[1]))
            assert.same({}, res.notes)
            local code, out = run(VALIDATE .. "-q --strict --skip 'Classes/*' --keep Classes/Warrior.lua "
                .. "--own Classes/Warrior.lua " .. dir)
            assert.equal(1, code, out)
            assert.not_matches("  note  ", out)
            -- the five checks that depend on other files stay notes there (see insert-anchor-unknown above)
        end)

        it("ok-needs-ceiling: a plain level-grind in `ok` of a shared segment (it would do nothing there)", function()
            local dir = module({ ["Segments/Tirisfal.lua"] = { append = [[
FastesBoooy.AddLibrarySegment({ id = "mx-ud-2", title = "More", levels = { 1, 2 },
    ok = { "segment-level", "level-grind" }, steps = {
    { id = "mx-ud-more", go = true, at = { 1420, 30.2, 71.7 } },
} })
ns.zones.Scourge[2] = "mx-ud-2"
]] } })
            local res = validate(dir)
            assert.same({ "ok-needs-ceiling Segments/Tirisfal.lua mx-ud-2" }, listed(res.results[1]))
            local m = res.results[1].messages[1]
            assert.matches("^segment 'mx%-ud%-2': ok lists level%-grind without a ceiling", m.msg)
            assert.is_nil(m.stepId)
            for i = 2, #res.results do assert.same({}, with(res.results[i], "ok-needs-ceiling")) end
            -- a route's own segment: reported in the route (V.RouteChecks)
            local mixed = module({ ["Route.lua"] = { append = [[
FastesBoooy.AddSegment("mx-orc-warrior", { id = "mx-own", title = "Own", ok = "level-grind", steps = {
    { id = "mx-own-1", go = true, at = { 1411, 42.6, 69.0 } },
} })
]] } })
            res = validate(mixed)
            assert.same({}, listed(res.results[1]))
            local e = with(res.results[3], "ok-needs-ceiling")
            assert.equal(1, #e)
            assert.equal("ERROR", e[1].severity)
            assert.equal("mx-own", e[1].segment)
            assert.equal("Route.lua", e[1].file)
        end)

        it("run with --route as well, over every route of the module", function()
            local dir = module({ ["Races/Orc.lua"] = { append = [[
FastesBoooy.AddLibraryInsert({ after = "mx-ud-364-in", race = "Orc", steps = {
    { id = "mx-orc-lost", go = true, at = { 1420, 30.2, 71.7 } },
} })
]] } })
            local res = validate(dir, { route = "mx-undead-paladin" })
            assert.equal(2, #res.results)
            assert.equal(1, res.matched)
            assert.same({ "insert-unapplied Races/Orc.lua mx-orc-lost" }, listed(res.results[1]))
            local code, out = run(VALIDATE .. "-q --route mx-undead-paladin " .. dir)
            assert.equal(1, code, out)
            assert.matches("%[insert%-unapplied%]", (select(2, run(VALIDATE .. "--route mx-undead-paladin " .. dir))))
        end)

        it("only a module that registers routes gets them; dependencies and harness runs do not", function()
            -- a pure library module with an unused segment: its entry stays empty
            local lib = validate(H.LIB_DIR)
            assert.equal(1, #lib.results)
            assert.is_truthy(lib.results[1].library)
            assert.same({}, lib.results[1].messages)
            -- a route module that uses it: no "(shared ...)" entry, nothing about the library's templates
            local composed = validate(H.COMPOSED_DIR)
            assert.equal(1, #composed.results)
            assert.is_nil(composed.results[1].shared)
            assert.same({}, with(composed.results[1], "shared-unused"))
            -- harness run on a mixed module with a broken template: not reported there
            local dir = module({ ["Races/Orc.lua"] = { append = [[
FastesBoooy.AddLibraryInsert({ after = "mx-nowhere", race = "Orc", steps = { { id = "mx-orc-lost", manual = true } } })
]] } })
            local hb = Harness.Build(dir, { schema = schema, segments = { "mx-dur" },
                profile = { race = "Orc", class = "WARRIOR", faction = "Horde" } })
            local res = V.ValidateHarness(hb, { db = db, schema = schema })
            assert.equal(1, #res.results)
            assert.equal(0, res.results[1].counts.ERROR)
        end)
    end)

    describe("step-no-profile", function()
        it("is kept for a route's own steps and per-route inserts, never reported for shared steps", function()
            -- per-route insert of the composed fixture: still one WARN
            local composed = validate(H.COMPOSED_DIR)
            assert.equal(1, #with(composed.results[1], "step-no-profile"))
            -- a profile override makes the paladin's shared class step unreachable: no WARN about it
            local res = validate(H.GUIDES_DIR, { route = "tg-undead-paladin", profile = { race = "Orc", class = "WARRIOR" } })
            local r = res.results[2]
            assert.equal("Orc WARRIOR Horde", r.profileLabel)
            assert.is_truthy(res.mod.routeById["tg-undead-paladin"].stepById["tg-pal-train-1"])
            assert.same({}, with(r, "step-no-profile"))
            assert.equal(1, #with(r, "step-skipped"))
        end)
    end)

    describe("file filter (--skip / --keep)", function()
        it("the loader leaves the files out and says which", function()
            local dir = module()
            local mod = Loader.LoadModule(dir, { schema = schema, skipGlobs = { "Classes/*", "Races/*" },
                keepGlobs = { "Classes/Warrior.lua" } })
            assert.same({}, mod.errors)
            assert.same({ "Classes/Paladin.lua", "Races/Orc.lua" }, mod.skipped)
            assert.is_true(mod.filtered)
            assert.same({ ["Classes/Paladin.lua"] = true, ["Races/Orc.lua"] = true }, mod.skipSet)
            assert.same({ "Segments/Tirisfal.lua", "Segments/Durotar.lua", "Classes/Warrior.lua", "Route.lua" }, mod.files)
            assert.is_nil(mod.routeById["mx-undead-paladin"].stepById["mx-pal-train"])
            assert.is_truthy(mod.routeById["mx-orc-warrior"].stepById["mx-war-train"])
            -- a glob that matches nothing: a full load
            mod = Loader.LoadModule(dir, { schema = schema, skipGlobs = { "Nope/*" } })
            assert.is_false(mod.filtered)
            assert.same({}, mod.skipped)
            -- opts.skip (exact paths) is no filter: gen_route_data leaves Data.lua out that way
            mod = Loader.LoadModule(dir, { schema = schema, skip = { ["Races/Orc.lua"] = true } })
            assert.is_false(mod.filtered)
            assert.same({ ["Races/Orc.lua"] = true }, mod.skipSet)
        end)

        it("one author's broken file does not stop the others (validator, simulator, generator)", function()
            local dir = module({ ["Classes/Paladin.lua"] = "this is not Lua\n" })
            local code, out = run(VALIDATE .. "-q " .. dir)
            assert.equal(1, code, out)
            assert.matches("1 error%(s%)", out)
            code, out = run(VALIDATE .. "-q --strict --skip 'Classes/*' --keep Classes/Warrior.lua " .. dir)
            assert.equal(0, code, out)
            assert.matches("validate_routes: 1 module%(s%), 0 error%(s%), 0 warning%(s%)", out)
            -- the simulator loads the same files into the mock client
            code, out = run(SIMULATE .. dir)
            assert.equal(1, code, out)
            assert.matches("FAIL FastesBoooy_Mx%d+: 1 load/schema error%(s%)", out)
            code, out = run(SIMULATE .. "--skip 'Classes/*' --keep Classes/Warrior.lua " .. dir)
            assert.equal(0, code, out)
            assert.matches("OK   mx%-undead%-paladin %(Scourge PALADIN Horde%): 4 steps", out)
            assert.matches("OK   mx%-orc%-warrior %(Orc WARRIOR Horde%): 7 steps", out)
            -- the generator: only to look at
            code, out = run("lua5.1 tools/gen_route_data.lua --no-overrides --stdout --skip 'Classes/*' " .. dir)
            assert.equal(0, code, out)
            assert.matches("%[3143%] = \"Gornek\"", out)
            assert.is_nil(out:find("[3153]", 1, true), "the warrior trainer is in a skipped file")
            code, out = run("lua5.1 tools/gen_route_data.lua --no-overrides --skip 'Classes/*' " .. dir)
            assert.equal(2, code)
            assert.matches("%-%-skip / %-%-keep are only allowed with %-%-stdout", out)
        end)

        it("a --skip / --keep / --own glob that matches no file is refused (exit 2) by the three tools", function()
            local dir, name = module()
            local mod = Loader.LoadModule(dir, { schema = schema, skipGlobs = { "Classes/*" } })
            assert.same(ORDER, mod.tocFiles)
            assert.same({ "Segments/Tirisfal.lua", "Segments/Durotar.lua", "Races/Orc.lua", "Route.lua" }, mod.loadedFiles)
            assert.same({}, V.UnmatchedFileGlobs({ mod }, { skip = { "Classes/*" }, own = { "Races/*", "Route.lua" } }))
            local lines = V.UnmatchedFileGlobs({ mod }, { skip = { "Clases/*" }, keep = { "Classes/warrior.lua" },
                own = { "Classes/Warrior.lua", "Race/*" } })
            assert.equal(4, #lines)
            assert.matches("^%-%-skip 'Clases/%*' matches no TOC file of " .. name, lines[1])
            assert.matches("^%-%-keep 'Classes/warrior%.lua' matches no TOC file of " .. name, lines[2])
            assert.matches("^%-%-own 'Classes/Warrior%.lua' matches no loaded file of " .. name
                .. " %(it only matches files that %-%-skip leaves out: add %-%-keep%)", lines[3])
            assert.matches("^%-%-own 'Race/%*' matches no loaded file of " .. name .. " %(the match is case%-sensitive", lines[4])
            assert.same({}, Loader.UnmatchedFilters({ dir }, nil, nil))
            assert.same({}, Loader.UnmatchedFilters({ dir, root .. "/no-such-module" }, { "Nope/*" }, nil),
                "a module without a TOC: the load reports it")

            -- the validator: a typo in --own would make every warning foreign and --strict pass on anything
            local warn = module({ ["Classes/Warrior.lua"] = { append = [[
FastesBoooy.AddLibraryInsert({ after = "mx-dur-788-in", class = "WARRIOR", steps = { { id = "mx-war-2", train = true } } })
]] } })
            local code, out = run(VALIDATE .. "-q --strict --own Classes/Warrior.lua " .. warn)
            assert.equal(1, code, out)
            for _, typo in ipairs({ "Classes/Warior.lua", "classes/warrior.lua" }) do
                code, out = run(VALIDATE .. "-q --strict --own " .. typo .. " " .. warn)
                assert.equal(2, code, out)
                assert.matches("validate_routes: %-%-own '" .. typo:gsub("%p", "%%%0") .. "' matches no loaded file of "
                    .. "FastesBoooy_Mx%d+ .-: every warning would be foreign", out)
                assert.not_matches("warning%(s%)", out)
            end
            -- the own file is skipped (--keep forgotten)
            code, out = run(VALIDATE .. "-q --strict --skip 'Classes/*' --own Classes/Warrior.lua " .. warn)
            assert.equal(2, code, out)
            assert.matches("add %-%-keep", out)
            code, out = run(VALIDATE .. "-q --skip 'Clases/*' " .. dir)
            assert.equal(2, code, out)
            assert.matches("validate_routes: %-%-skip 'Clases/%*' matches no TOC file", out)
            code, out = run(VALIDATE .. "-q --skip 'Classes/*' --keep Classes/Warior.lua " .. dir)
            assert.equal(2, code, out)
            assert.matches("validate_routes: %-%-keep 'Classes/Warior%.lua' matches no TOC file", out)
            -- a glob has to match in one of the modules of the run, not in each
            code, out = run(VALIDATE .. "-q --skip 'Classes/*' --own Segments/Zone.lua " .. dir .. " "
                .. H.FIXTURE_DIR)
            assert.equal(2, code, out)
            code, out = run(VALIDATE .. "-q --skip 'Classes/*' --own 'Segments/0*' " .. dir .. " " .. H.FIXTURE_DIR)
            assert.equal(0, code, out)
            -- harness runs
            local harness = "--harness " .. dir .. " --segments mx-dur --profile race=Orc,class=WARRIOR "
            code, out = run(VALIDATE .. "-q --skip 'Clases/*' " .. harness)
            assert.equal(2, code, out)
            code, out = run(VALIDATE .. "-q --skip 'Classes/*' --own 'Segments/*' " .. harness)
            assert.equal(0, code, out)
            -- the simulator and the generator
            code, out = run(SIMULATE .. "--skip 'Clases/*' " .. dir)
            assert.equal(2, code, out)
            assert.matches("simulate_routes: %-%-skip 'Clases/%*' matches no TOC file of FastesBoooy_Mx", out)
            assert.not_matches("simulation%(s%)", out)
            code, out = run(SIMULATE .. "--skip 'Clases/*' " .. harness)
            assert.equal(2, code, out)
            code, out = run("lua5.1 tools/gen_route_data.lua --no-overrides --stdout --skip 'Classes/*' --keep 'Classes/X.lua' "
                .. dir)
            assert.equal(2, code, out)
            assert.matches("gen_route_data: %-%-keep 'Classes/X%.lua' matches no TOC file", out)
        end)

        it("Mock.loadAddon skips the files of the skip set", function()
            local dir, name = module()
            local m = Mock.new({ player = { race = "Orc", class = "WARRIOR", faction = "Horde" } })
            Mock.loadAddon(m, H.CORE_TOC)
            Mock.loadAddon(m, dir .. "/" .. name .. ".toc", name, { skip = { ["Classes/Warrior.lua"] = true } })
            assert.same({ "Classes/Warrior.lua" }, m.addons[name].skipped)
            Mock.boot(m, { "FastesBoooy", name })
            local ns = m.addons.FastesBoooy.ns
            local route = ns.Registry:Get("mx-orc-warrior")
            assert.is_truthy(route.stepById["mx-orc-vendor"])
            assert.is_nil(route.stepById["mx-war-train"])
        end)
    end)

    describe("--route", function()
        it("takes a comma list with wildcards; every entry must match a route", function()
            local dir = module()
            local code, out = run(VALIDATE .. "-q --route 'mx-orc-*' " .. dir)
            assert.equal(0, code, out)
            assert.matches("mx%-orc%-warrior %[", out)
            assert.not_matches("mx%-undead%-paladin %[", out)
            code, out = run(VALIDATE .. "-q --route '*-paladin,mx-orc-warrior' " .. dir)
            assert.equal(0, code, out)
            assert.matches("mx%-orc%-warrior %[", out)
            assert.matches("mx%-undead%-paladin %[", out)
            code, out = run(VALIDATE .. "-q --route 'mx-orc-warrior,mx-trol-*' " .. dir)
            assert.equal(2, code, out)
            assert.matches("%-%-route mx%-trol%-%* matched no route", out)
            -- the simulator
            code, out = run(SIMULATE .. "--no-reload --route 'mx-*-warrior' " .. dir)
            assert.equal(0, code, out)
            assert.matches("simulate_routes: 1 simulation%(s%), 1 passed, 0 failed", out)
            code, out = run(SIMULATE .. "--no-reload --route 'mx-orc-warrior,mx-undead-*' " .. dir)
            assert.equal(0, code, out)
            assert.matches("simulate_routes: 2 simulation%(s%), 2 passed, 0 failed", out)
            code, out = run(SIMULATE .. "--no-reload --route 'mx-orc-warrior,nope-*' " .. dir)
            assert.equal(1, code, out)
            assert.matches("%-%-route nope%-%* matched no route", out)
        end)

        it("is repeatable: the lists add up (validator and simulator)", function()
            assert.equal("a,b*,c", V.ParseArgs({ "--route", "a", "--route", "b*,c" }).route)
            local dir = module()
            local code, out = run(VALIDATE .. "-q --route mx-orc-warrior --route 'mx-undead-*' " .. dir)
            assert.equal(0, code, out)
            assert.matches("mx%-orc%-warrior %[", out)
            assert.matches("mx%-undead%-paladin %[", out)
            code, out = run(VALIDATE .. "-q --route mx-orc-warrior --route mx-trol-mage " .. dir)
            assert.equal(2, code, out)
            assert.matches("%-%-route mx%-trol%-mage matched no route", out)
            code, out = run(SIMULATE .. "--no-reload --route mx-orc-warrior --route mx-undead-paladin " .. dir)
            assert.equal(0, code, out)
            assert.matches("simulate_routes: 2 simulation%(s%), 2 passed, 0 failed", out)
            code, out = run(SIMULATE .. "--route")
            assert.equal(2, code, out)
            assert.matches("%-%-route needs an id", out)
        end)

        it("a file that does not load always counts: what it would give the selected routes is unknown", function()
            local dir = module({ ["Classes/Warrior.lua"] = "this is not Lua\n" })
            -- the whole module: an error
            local res = validate(dir)
            assert.equal(1, res.results[1].counts.ERROR)
            assert.equal("schema", res.results[1].messages[1].code)
            assert.is_true(res.mod.errors[1].load)
            assert.same({}, res.notes)
            -- the route of the broken class file: it has lost its class steps, the run must not pass
            res = validate(dir, { route = "mx-orc-warrior" })
            assert.equal(1, res.results[1].counts.ERROR)
            assert.same({}, res.notes)
            assert.is_nil(res.mod.routeById["mx-orc-warrior"].stepById["mx-war-train"])
            -- another route: nobody can tell what the file would have registered, so it counts as well
            res = validate(dir, { route = "mx-undead-paladin" })
            assert.equal(1, res.results[1].counts.ERROR)
            assert.same({}, res.notes)
            -- a runtime error half way through a file is the same case
            local half = module({ ["Classes/Warrior.lua"] = { append = "error('stop')\n" } })
            res = validate(half, { route = "mx-undead-paladin" })
            assert.equal(1, res.results[1].counts.ERROR)
            assert.matches("^runtime error", res.results[1].messages[1].msg)
            assert.same({}, res.notes)
            -- a segment file (the template checks then report the inserts that lost their anchor, too)
            local seg = module({ ["Segments/Durotar.lua"] = "this is not Lua\n" })
            res = validate(seg, { route = "mx-undead-paladin" })
            assert.is_true(res.results[1].counts.ERROR >= 1)
            assert.equal("schema", res.results[1].messages[1].code)
            assert.same({}, res.notes)

            local code, out = run(VALIDATE .. "-q --strict --end-level --route mx-orc-warrior " .. dir)
            assert.equal(1, code, out)
            assert.matches("%(shared FastesBoooy_Mx%d+%) .-: 1 error%(s%)", out)
            code, out = run(VALIDATE .. "-q --route mx-undead-paladin " .. dir)
            assert.equal(1, code, out)
            assert.not_matches("  note  ", out)
            -- the way to leave out another author's broken file is --skip
            code, out = run(VALIDATE .. "-q --strict --route mx-undead-paladin --skip Classes/Warrior.lua " .. dir)
            assert.equal(0, code, out)
        end)

        it("an error about one route is a note when that route is not selected, whatever file reports it", function()
            -- a wrong chain of the undead route; like every route it is registered in Route.lua
            local dir = module({ ["Segments/Tirisfal.lua"] = { append = "ns.zones.Scourge[2] = \"mx-ud-typo\"\n" } })
            local res = validate(dir)
            assert.equal(1, res.results[1].counts.ERROR)
            assert.equal("mx-undead-paladin", res.mod.errors[1].route)
            assert.equal("Route.lua", res.mod.errors[1].file)
            -- the orc route is not concerned
            res = validate(dir, { route = "mx-orc-warrior" })
            assert.equal(0, res.results[1].counts.ERROR)
            assert.equal(0, res.results[2].counts.ERROR)
            assert.equal(1, #res.notes)
            assert.equal("schema", res.notes[1].code)
            assert.equal("Route.lua", res.notes[1].file)
            assert.matches("route mx%-undead%-paladin: UseSegments: unknown shared segment 'mx%-ud%-typo'", res.notes[1].msg)
            assert.equal("--route: an error of route mx-undead-paladin, which is not selected", res.notes[1].note)
            -- the route itself, alone or by a wildcard: an error
            for _, sel in ipairs({ "mx-undead-paladin", "mx-*" }) do
                res = validate(dir, { route = sel })
                assert.equal(1, res.results[1].counts.ERROR, sel)
                assert.same({}, res.notes)
            end
            -- a per-route insert of an unselected route with a schema error, in a file of its own
            local ins = module({ ["Races/Orc.lua"] = { append = [[
FastesBoooy.AddInsert("mx-orc-warrior", { after = "mx-dur-788-in", steps = { { id = "mx-orc-bad", bogus = 1 } } })
]] } })
            assert.equal("mx-orc-warrior", validate(ins).mod.errors[1].route)
            res = validate(ins, { route = "mx-undead-paladin" })
            assert.equal(0, res.results[1].counts.ERROR)
            assert.is_true(#res.notes >= 1)
            res = validate(ins, { route = "mx-orc-warrior" })
            assert.is_true(res.results[1].counts.ERROR >= 1)
            assert.same({}, res.notes)

            local code, out = run(VALIDATE .. "-q --strict --route mx-orc-warrior " .. dir)
            assert.equal(0, code, out)
            assert.matches("  note  %(Route.lua%) %[schema%] route mx%-undead%-paladin: UseSegments.- %-%- not counted: "
                .. "%-%-route: an error of route mx%-undead%-paladin, which is not selected", out)
            code = run(VALIDATE .. "-q --route mx-undead-paladin " .. dir)
            assert.equal(1, code)
        end)

        it("a schema error in a file that loaded is a note only when its content goes to other routes alone", function()
            -- the paladin file: one good insert (it reaches the undead route) and one with a schema error
            local bad = [[
FastesBoooy.AddLibraryInsert({ after = "mx-ud-364-in", class = "PALADIN", steps = { { id = "mx-pal-bad", bogus = 1 } } })
]]
            local dir = module({ ["Classes/Paladin.lua"] = { append = bad } })
            local res = validate(dir)
            assert.is_true(res.results[1].counts.ERROR >= 1)
            assert.is_nil(res.mod.errors[1].route)
            assert.is_nil(res.mod.errors[1].load)
            res = validate(dir, { route = "mx-orc-warrior" })
            assert.equal(0, res.results[1].counts.ERROR)
            assert.is_true(#res.notes >= 1)
            assert.equal("Classes/Paladin.lua", res.notes[1].file)
            assert.equal("--route: the file loaded, and its content goes only to routes that are not selected",
                res.notes[1].note)
            -- ...unless the caller says the file is its own
            res = validate(dir, { route = "mx-orc-warrior", isOwn = own("Classes/Paladin.lua"), ownGiven = true })
            assert.is_true(res.results[1].counts.ERROR >= 1)
            assert.same({}, res.notes)
            -- the route that gets the file's steps: an error
            res = validate(dir, { route = "mx-undead-paladin" })
            assert.is_true(res.results[1].counts.ERROR >= 1)
            assert.same({}, res.notes)
            -- a file that gave nothing to any route (its only registration failed): it may be exactly what
            -- the selected route misses, so it counts
            local nothing = module({ ["Classes/Warrior.lua"] = "FastesBoooy.AddLibraryInsert({ class = \"WARRIOR\" })\n" })
            for _, sel in ipairs({ "mx-orc-warrior", "mx-undead-paladin" }) do
                res = validate(nothing, { route = sel })
                assert.is_true(res.results[1].counts.ERROR >= 1, sel)
                assert.same({}, res.notes)
            end
            -- an error in a file the route does use always counts
            local dir2 = module({ ["Segments/Tirisfal.lua"] = { append = "FastesBoooy.AddLibrarySegment(1)\n" } })
            res = validate(dir2, { route = "mx-undead-paladin" })
            assert.equal(1, res.results[1].counts.ERROR)
            assert.same({}, res.notes)

            local code, out = run(VALIDATE .. "-q --route mx-orc-warrior " .. dir)
            assert.equal(0, code, out)
            assert.matches("  note  %(Classes/Paladin.lua%) %[schema%] .- %-%- not counted: %-%-route: the file loaded", out)
            code = run(VALIDATE .. "-q --route mx-orc-warrior --own Classes/Paladin.lua " .. dir)
            assert.equal(1, code)
        end)

        it("the simulator fails a module with load errors and does not add a false \"matched no route\"", function()
            local dir = module({ ["Classes/Warrior.lua"] = "this is not Lua\n" })
            local code, out = run(SIMULATE .. "--route mx-orc-warrior " .. dir)
            assert.equal(1, code, out)
            assert.matches("FAIL FastesBoooy_Mx%d+: 1 load/schema error%(s%)", out)
            assert.matches("simulate_routes: 1 simulation%(s%), 0 passed, 1 failed", out)
            assert.not_matches("matched no route", out)
        end)
    end)

    describe("--harness on a mixed module", function()
        it("uses the shared part; shared inserts apply, other races' steps are not composed", function()
            local hb = Harness.Build(H.GUIDES_DIR, { schema = schema, segments = { "tg-dur-01-valley-of-trials" },
                profile = { race = "Orc", class = "WARRIOR", faction = "Horde" } })
            assert.is_nil(hb.fatal)
            assert.same({}, hb.errors)
            assert.equal("harness-TestGuides", hb.route.id)
            assert.same(H.GUIDES_IDS["tg-orc-warrior"], H.ids(hb.route.steps))
            assert.same({ "tg-ud-01-deathknell", "tg-dur-01-valley-of-trials" }, hb.available)
            local res = V.ValidateHarness(hb, { db = db, schema = schema })
            assert.same({ ERROR = 0, WARN = 0, INFO = res.results[1].counts.INFO }, res.results[1].counts)
            -- the troll mage on the same segment: its own class and race steps
            hb = Harness.Build(H.GUIDES_DIR, { schema = schema, segments = { "tg-dur-01-valley-of-trials" },
                profile = { race = "Troll", class = "MAGE", faction = "Horde" } })
            assert.same(H.GUIDES_IDS["tg-troll-mage"], H.ids(hb.route.steps))
            -- the file filter reaches the harness
            hb = Harness.Build(H.GUIDES_DIR, { schema = schema, segments = { "tg-dur-01-valley-of-trials" },
                profile = { race = "Orc", class = "WARRIOR", faction = "Horde" }, skipGlobs = { "Classes/*" } })
            assert.is_nil(hb.route.stepById["tg-war-frang"])
            assert.same({ "Classes/Mage.lua", "Classes/Paladin.lua", "Classes/Warrior.lua" }, hb.mod.skipped)
        end)

        it("validates and simulates from the command line", function()
            local args = "--harness " .. H.GUIDES_DIR .. " --segments tg-dur-01-valley-of-trials "
                .. "--profile race=Orc,class=WARRIOR "
            local code, out = run(VALIDATE .. "-q --strict --end-level " .. args)
            assert.equal(0, code, out)
            assert.matches("harness%-TestGuides %[Orc WARRIOR Horde%]: 0 error%(s%), 0 warning%(s%)", out)
            assert.not_matches("%(shared ", out)
            code, out = run(SIMULATE .. args)
            assert.equal(0, code, out)
            assert.matches("OK   harness%-TestGuides %(Orc WARRIOR Horde%): 9 steps", out)
            -- with a file filter: without the class files
            code, out = run(SIMULATE .. "--skip 'Classes/*' " .. args)
            assert.equal(0, code, out)
            assert.matches("OK   harness%-TestGuides %(Orc WARRIOR Horde%): 6 steps", out)
        end)
    end)
end)
