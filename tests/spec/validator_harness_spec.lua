-- Start-state harness of the offline tools (tools/lib/harness.lua): the state file format
-- (JSON decode, normalization, deterministic encoding), the harness route over library
-- segments (Harness.Build), the validator from a start state (prerequisites from "done",
-- the quest log from "log" / "complete", the level from "level" / "xpFrac", flight paths,
-- end state and chaining) and the --harness / --state / --write-state CLI of
-- tools/validate_routes.lua and tools/simulate_routes.lua.
-- Fixture: the tiny library tests/fixtures/validator/AdventureAtlas_FxHarnessLib (real Forever
-- quests in Deathknell / Brill) and its start state tests/fixtures/validator/harness_state_6.json.

local DB = require("lib.fbdb")
local Loader = require("lib.route_loader")
local V = require("lib.validator")
local Harness = require("lib.harness")
local json = require("lib.json")

local LIB = "tests/fixtures/validator/AdventureAtlas_FxHarnessLib"
local STATE = "tests/fixtures/validator/harness_state_6.json"
local PALADIN = { race = "Scourge", class = "PALADIN", faction = "Horde" }
local DRUID = { race = "Skyborne", class = "DRUID", faction = "Horde" }
local CLI_PALADIN = "--profile race=Scourge,class=PALADIN,faction=Horde"

local db, schema

local function run(cmd)
    local p = assert(io.popen(cmd .. " 2>&1; echo \"__EXIT=$?\""))
    local out = p:read("*a")
    p:close()
    local code = tonumber(out:match("__EXIT=(%d+)%s*$"))
    return code, (out:gsub("__EXIT=%d+%s*$", ""))
end

local function tmpname()
    local n = os.tmpname()
    os.remove(n)
    return n
end

local function writeFile(path, text)
    local fh = assert(io.open(path, "w"))
    fh:write(text)
    fh:close()
end

local function codes(result, severity)
    local set = {}
    for _, m in ipairs(result.messages) do
        if not severity or m.severity == severity then set[m.code] = (set[m.code] or 0) + 1 end
    end
    return set
end

local function messagesWith(result, code)
    local out = {}
    for _, m in ipairs(result.messages) do
        if m.code == code then out[#out + 1] = m end
    end
    return out
end

local function state(t)
    local st, errs = Harness.NormalizeState(t)
    assert.are.same({}, errs)
    st.file = "inline"
    return st
end

local function harness(segments, opts)
    opts = opts or {}
    local profile = opts.profile or PALADIN
    local hb = Harness.Build(opts.lib or LIB, { schema = schema, segments = segments, profile = profile })
    assert.is_nil(hb.fatal)
    local res = V.ValidateHarness(hb, { db = db, schema = schema, profile = profile, startState = opts.state })
    return res.results[1], hb
end

local function fixtureState()
    local st, errs = Harness.ReadState(STATE)
    assert.is_nil(errs)
    return st
end

-- end states without meta (source / segment list differ between equivalent runs)
local function core(st)
    local c = {}
    for k, v in pairs(st) do
        if k ~= "meta" and k ~= "file" then c[k] = v end
    end
    return c
end

describe("start-state harness", function()
    setup(function()
        db = DB.Load("tools/data/forever_db.lua")
        schema = Loader.LoadSchema(".")
    end)

    describe("lib/json decode", function()
        it("decodes RFC 8259 JSON and rejects what is not", function()
            local v = json.decode('{"a": [1, -2.5e1, 0], "s": "x\\u00e9\\n", "t": true, "n": null, "o": {}}')
            assert.are.same({ 1, -25, 0 }, v.a)
            assert.are.equal("xé\n", v.s)
            assert.is_true(v.t)
            assert.are.equal(json.null, v.n)
            assert.are.equal("{}", json.encode(v.o))
            for _, bad in ipairs({ "[1,]", '{"a":1,"a":2}', "01", "1.", "[1] x", "", "{a:1}", "// c\n1" }) do
                local r, err = json.decode(bad)
                assert.is_nil(r, bad)
                assert.matches("^line %d+ col %d+: ", err, nil, false, bad)
            end
        end)
    end)

    describe("state files", function()
        it("reads the fixture state (log entries may be objects; lists are sorted)", function()
            local st = fixtureState()
            assert.are.equal(6, st.level)
            assert.are.equal(0.25, st.xpFrac)
            assert.are.same({ 363, 364, 376, 380, 427, 3901, 3902 }, st.done)
            assert.are.same({ 381 }, st.log)
            assert.are.same({ 381 }, st.complete)
            assert.are.same({ 1420, 32.0, 66.0 }, st.at)
            assert.are.same({ "Undercity" }, st.flightPaths)
            assert.is_nil(st.hearth)
            assert.are.equal(STATE, st.file)
        end)

        it("rejects malformed states with every problem listed", function()
            local st, errs = Harness.ParseState(json.encode({
                level = 61, xpFrac = 1, done = { 5, 5, "x" }, log = { 7, 5 }, complete = { 9 }, bogus = true,
                at = { 1420, 50 }, flightPaths = { "" },
            }), "bad.json")
            assert.is_nil(st)
            local all = table.concat(errs, "\n")
            for _, want in ipairs({ "bad.json: level must be an integer 1..60", "xpFrac must be a number in %[0, 1%)",
                "done: quest 5 listed twice", "done%[3%] is not a quest id", "complete: quest 9 is not in \"log\"",
                "quest 5 is both in \"done\" and in \"log\"", "unknown key \"bogus\"", "at must be %[uiMapID, x, y%]",
                "flightPaths%[1%] is not a place name" }) do
                assert.matches(want, all)
            end
            local _, jerr = Harness.ParseState('{"level": 3,}', "j.json")
            assert.matches("^j.json: invalid JSON: line 1 col 13", jerr[1])
            local _, rerr = Harness.ReadState("tests/fixtures/validator/no-such-state.json")
            assert.matches("cannot read state file", rerr[1])
        end)

        it("encodes deterministically and round-trips", function()
            local st = fixtureState()
            st.hearth, st.hearthAt = "Brill", { 1420, 61.72, 52.05 }
            st.meta = json.object({ source = "spec" })
            local text = Harness.EncodeState(st)
            assert.matches('^{\n  "level": 6,\n  "xpFrac": 0.25,\n  "done": %[363, 364, 376, 380, 427, 3901, 3902%],', text)
            assert.matches('"hearthAt": %[1420, 61.72, 52.05%]', text)
            local back = assert(Harness.ParseState(text, "x"))
            assert.are.same(core(st), core(back))
            assert.are.equal(text, Harness.EncodeState(back))
        end)

        it("xpFrac <-> XP is exact for every level of the XP table", function()
            for level = 1, 59 do
                local need = DB.XpToLevel(db, level)
                for _, xp in ipairs({ 0, 1, math.floor(need / 3), need - 1 }) do
                    assert.are.equal(xp, Harness.XpFromFraction(Harness.Fraction(xp, need), need), level .. "/" .. xp)
                end
            end
        end)
    end)

    describe("Harness.Build", function()
        it("composes a one-profile route of the listed library segments, in that order", function()
            local hb = Harness.Build(LIB, { schema = schema, segments = { "fh-brill", "fh-deathknell" }, profile = DRUID })
            assert.are.same({}, hb.errors)
            assert.are.equal("harness-FxHarnessLib", hb.route.id)
            assert.are.same({ "fh-brill", "fh-deathknell" }, hb.segments)
            assert.are.equal("fh-brill", hb.route.segments[1].id)
            assert.are.equal("fh-johaan", hb.route.steps[1].id)
            assert.are.equal("AdventureAtlas_FxHarnessLib", hb.route.steps[1].library)
            assert.are.same({ { race = "Skyborne", class = "DRUID", faction = "Horde" } }, V.Profiles(hb.route))
            assert.is_true(hb.route.harness)
        end)

        it("defaults to every library segment of the module (TOC order)", function()
            local hb = Harness.Build(LIB, { schema = schema, profile = PALADIN })
            assert.are.same({ "fh-deathknell", "fh-brill" }, hb.segments)
            assert.are.same({ "fh-deathknell", "fh-brill" }, hb.available)
        end)

        it("reports unknown segments with the list of known ones", function()
            local hb = Harness.Build(LIB, { schema = schema, segments = { "fh-brill", "fh-nope" }, profile = PALADIN })
            assert.are.equal(1, #hb.errors)
            assert.matches("unknown library segment 'fh%-nope' %(AdventureAtlas_FxHarnessLib registers: fh%-deathknell, "
                .. "fh%-brill%)", hb.errors[1].msg)
            assert.are.same({ "fh-brill" }, hb.segments)
        end)

        it("accepts a module that registers routes when it has shared segments; refuses the others", function()
            -- a mixed module (the shape of AdventureAtlas_Guides): the harness uses its shared part
            local hb = Harness.Build("tests/fixtures/core/AdventureAtlas_TestGuides", { schema = schema, profile = PALADIN,
                segments = { "tg-ud-01-deathknell" } })
            assert.is_nil(hb.fatal)
            assert.are.same({}, hb.errors)
            assert.are.equal("harness-TestGuides", hb.route.id)
            assert.are.same({ "tg-ud-01-deathknell" }, hb.segments)
            assert.are.equal(3, #hb.mod.routes, "the module's own routes are loaded next to the harness route")
            -- the shared insert of the paladin's class file applies to the harness route
            assert.is_truthy(hb.route.stepById["tg-pal-train-1"])
            -- a route module without shared segments has nothing for a harness
            hb = Harness.Build("tests/fixtures/validator/AdventureAtlas_FxClean", { schema = schema, profile = PALADIN })
            assert.matches("registers route%(s%) %(fx%-clean%) but no shared segments", hb.fatal)
            hb = Harness.Build("tests/fixtures/validator/AdventureAtlas_Nope", { schema = schema, profile = PALADIN })
            assert.matches("no TOC file found", hb.fatal)
        end)

        it("needs race and class; the faction comes from the race (Skyborne: both sides)", function()
            assert.are.same(PALADIN, (Harness.Profile({ race = "Scourge", class = "PALADIN" })))
            assert.matches("needs %-%-profile", select(2, Harness.Profile(nil)))
            assert.matches("give the faction too", select(2, Harness.Profile({ race = "Skyborne", class = "DRUID" })))
            assert.matches("must be Horde or Alliance",
                select(2, Harness.Profile({ race = "Scourge", class = "PALADIN", faction = "Scourge" })))
        end)
    end)

    describe("validator from a start state", function()
        it("the fixture library is clean from its start state (both profiles)", function()
            for _, p in ipairs({ PALADIN, DRUID }) do
                local r = harness(nil, { state = fixtureState(), profile = p })
                assert.are.equal(0, r.counts.ERROR)
                assert.are.equal(0, r.counts.WARN)
                assert.are.equal(6.25, r.segments[1].startLevel)
                -- 382 is carried into the next segments: INFO, not WARN, in a harness run
                local carried = messagesWith(r, "quest-carried")
                assert.are.equal(1, #carried)
                assert.are.equal("INFO", carried[1].severity)
                assert.matches("382", carried[1].msg)
            end
        end)

        it("without the state the same steps fail: done, log, complete, level and flight paths matter", function()
            local r = harness(nil)
            local e = codes(r, "ERROR")
            assert.are.equal(1, e["turnin-not-accepted"])  -- 381 not in the log
            assert.is_truthy(e["level-too-low"])           -- 367 needs level 6
            assert.are.equal(1, e["accept-prereq"])         -- 370 needs 427 done
            assert.are.equal(1, codes(r, "WARN")["fly-unknown-fp"]) -- Undercity not known
        end)

        it("a log quest without 'complete' needs its complete step", function()
            local st = fixtureState()
            st.complete = {}
            local r = harness(nil, { state = st })
            assert.are.equal(0, r.counts.ERROR)
            assert.are.equal(1, codes(r, "WARN")["turnin-no-complete"])
        end)

        it("quests done before cannot be taken again", function()
            local st = fixtureState()
            st.done[#st.done + 1] = 367
            local r = harness(nil, { state = st })
            local m = messagesWith(r, "accept-done")
            assert.are.equal(1, #m)
            assert.matches("367 .* already turned in at the start state", m[1].msg)
        end)

        it("the quest log capacity counts the log of the state", function()
            -- 39 more quests in the log (any existing quests the fixture does not use)
            local used = { [381] = true, [382] = true, [367] = true, [370] = true }
            local ids = {}
            for id in pairs(db.quests) do
                if not used[id] then ids[#ids + 1] = id end
            end
            table.sort(ids)
            local st = fixtureState()
            local log = { 381 }
            for i = 1, 39 do log[#log + 1] = ids[i] end
            st = state({ level = 6, done = st.done, log = log, complete = { 381 }, flightPaths = { "Undercity" } })
            local r = harness(nil, { state = st })
            local full = messagesWith(r, "questlog-full")
            assert.are.equal(2, #full) -- 40 - 381 + 382 = 40, + 367 = 41, + 370 = 42
            assert.are.equal("fh-johaan", full[1].stepId)
            assert.matches("would hold 41 quests", full[1].msg)
            assert.matches("would hold 42 quests", full[2].msg)
            -- an over-full state is an error at the start
            log[#log + 1] = ids[40]
            log[#log + 1] = ids[41]
            r = harness(nil, { state = state({ level = 6, log = log }) })
            local m = messagesWith(r, "questlog-full")
            assert.are.equal("start-state", m[1].stepId)
            assert.matches("start state: the quest log holds 42 quests", m[1].msg)
        end)

        it("unknown quests in the state are errors", function()
            local r = harness(nil, { state = state({ level = 6, done = { 99999999 } }) })
            local m = messagesWith(r, "quest-unknown")
            assert.are.equal(1, #m)
            assert.matches("start state done: quest 99999999", m[1].msg)
        end)

        it("writes the end state: XP, done, log, complete, hearth, position, flight paths", function()
            local r = harness(nil, { state = fixtureState() })
            local es = r.endState
            assert.are.equal(7, es.level)
            assert.are.same({ 363, 364, 367, 370, 376, 380, 381, 427, 3901, 3902 }, es.done)
            assert.are.same({ 382 }, es.log)
            assert.are.same({}, es.complete)
            assert.are.equal("Brill", es.hearth)
            assert.are.same({ 1420, 61.72, 52.05 }, es.hearthAt)
            assert.are.same({ 1458, 63.25, 48.56 }, es.at)
            assert.are.same({ "Undercity" }, es.flightPaths)
            assert.are.equal("harness-FxHarnessLib", es.meta.route)
            assert.are.same({ "fh-deathknell", "fh-brill" }, es.meta.segments)
            assert.are.equal("tools/validate_routes.lua", es.meta.source)
            assert.are.equal(STATE, es.meta.startState)
            -- the end state is a valid start state
            assert.is_truthy(Harness.ParseState(Harness.EncodeState(es), "end"))
        end)

        it("chained runs end where one run over both segments ends", function()
            local first = harness({ "fh-deathknell" }, { state = fixtureState() })
            assert.are.same({ 382 }, first.endState.log)
            assert.are.same({}, first.endState.complete)
            local mid = assert(Harness.ParseState(Harness.EncodeState(first.endState), "mid"))
            local second = harness({ "fh-brill" }, { state = mid })
            local whole = harness(nil, { state = fixtureState() })
            assert.are.equal(0, second.counts.ERROR + second.counts.WARN)
            assert.are.same(core(whole.endState), core(second.endState))
        end)

        it("a full route also has an end state (from level 1, or from --state)", function()
            local res = V.ValidateModule("tests/fixtures/validator/AdventureAtlas_FxClean", { db = db, schema = schema })
            local es = res.results[1].endState
            assert.is_true(es.level >= 5)
            assert.is_true(#es.done > 5)
            assert.are.equal("fx-clean", es.meta.route)
            assert.is_nil(es.meta.startState)
        end)

        it("a shared step of another class is not composed into the harness route (no step-no-profile)", function()
            local root = tmpname()
            os.execute(("mkdir -p '%s/AdventureAtlas_HxLib'"):format(root))
            writeFile(root .. "/AdventureAtlas_HxLib/AdventureAtlas_HxLib.toc",
                "## Interface: 16001\n## Dependencies: AdventureAtlas\n## X-AdventureAtlas-Module: library\nLib.lua\n")
            writeFile(root .. "/AdventureAtlas_HxLib/Lib.lua", [[
AdventureAtlas.AddLibrarySegment({ id = "hx", title = "X", levels = { 1, 2 }, steps = {
    { id = "hx-1", accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
    { id = "hx-druid", manual = true, class = "DRUID" },
    { id = "hx-2", turnin = 363, npc = 1569, at = { 1420, 30.8, 66.2 } },
} })
]])
            local r, hb = harness(nil, { lib = root .. "/AdventureAtlas_HxLib" })
            os.execute(("rm -rf '%s'"):format(root))
            assert.are.equal(0, r.counts.ERROR + r.counts.WARN)
            assert.is_nil(codes(r)["step-no-profile"])
            -- the harness route has one race and one class: Core/Compose.lua leaves the DRUID step out
            -- (before core 0.4.0 it was composed and skipped by the profile: INFO step-skipped)
            local ids = {}
            for i, s in ipairs(hb.route.steps) do ids[i] = s.id end
            assert.are.same({ "hx-1", "hx-2" }, ids)
            assert.is_nil(codes(r, "INFO")["step-skipped"])
        end)
    end)

    describe("command line", function()
        local VAL = "lua5.1 tools/validate_routes.lua --no-overrides "
        local SIM = "lua5.1 tools/simulate_routes.lua --no-overrides "

        it("validate: harness from the fixture state, end state written; chaining via files", function()
            local out1, out2 = tmpname(), tmpname()
            local code, out = run(VAL .. "--strict --harness " .. LIB .. " --segments fh-deathknell " .. CLI_PALADIN
                .. " --state " .. STATE .. " --write-state " .. out1)
            assert.are.equal(0, code, out)
            assert.matches("== route harness%-FxHarnessLib %[Scourge PALADIN Horde%] module AdventureAtlas_FxHarnessLib", out)
            assert.matches("end state of harness%-FxHarnessLib %[Scourge PALADIN Horde%] written to ", out)
            local mid = assert(Harness.ReadState(out1))
            assert.are.same({ 382 }, mid.log)
            code, out = run(VAL .. "--strict --harness " .. LIB .. " --segments fh-brill " .. CLI_PALADIN
                .. " --state " .. out1 .. " --write-state " .. out2)
            assert.are.equal(0, code, out)
            local fin = assert(Harness.ReadState(out2))
            assert.are.equal("Brill", fin.hearth)
            assert.are.same(out1, fin.meta.startState)
            os.remove(out1)
            os.remove(out2)
        end)

        it("validate: errors without the state, unknown segments, usage errors", function()
            local code, out = run(VAL .. "-q --harness " .. LIB .. " " .. CLI_PALADIN)
            assert.are.equal(1, code)
            assert.matches("harness%-FxHarnessLib %[Scourge PALADIN Horde%]: 5 error%(s%)", out)
            code, out = run(VAL .. "--harness " .. LIB .. " --segments fh-nope " .. CLI_PALADIN)
            assert.are.equal(1, code)
            assert.matches("%[schema%] unknown library segment 'fh%-nope'", out)
            code, out = run(VAL .. "--harness " .. LIB)
            assert.are.equal(2, code)
            assert.matches("needs %-%-profile race=", out)
            code, out = run(VAL .. "--harness " .. LIB .. " --profile race=Skyborne,class=DRUID")
            assert.are.equal(2, code)
            assert.matches("give the faction too", out)
            code = run(VAL .. "--harness " .. LIB .. " " .. CLI_PALADIN .. " tests/fixtures/validator/AdventureAtlas_FxClean")
            assert.are.equal(2, code)
            code = run(VAL .. "--segments fh-brill tests/fixtures/validator/AdventureAtlas_FxClean")
            assert.are.equal(2, code)
            local bad = tmpname()
            writeFile(bad, '{"level": 70}')
            code, out = run(VAL .. "--harness " .. LIB .. " " .. CLI_PALADIN .. " --state " .. bad)
            os.remove(bad)
            assert.are.equal(2, code)
            assert.matches("level must be an integer 1%.%.60", out)
        end)

        it("validate: --write-state of a full route needs exactly one route x profile", function()
            local f = tmpname()
            local code, out = run(VAL .. "-q --route fx-clean --write-state " .. f
                .. " tests/fixtures/validator/AdventureAtlas_FxClean")
            assert.are.equal(0, code, out)
            local st = assert(Harness.ReadState(f))
            assert.are.equal("fx-clean", st.meta.route)
            code, out = run(VAL .. "-q --write-state " .. f .. " tests/fixtures/validator/AdventureAtlas_FxClean "
                .. "tests/fixtures/validator/AdventureAtlas_FxNs")
            assert.are.equal(2, code)
            assert.matches("needs exactly one route x profile, this run has 2", out)
            os.remove(f)
        end)

        it("validate: --until writes the state before a step / the first step of a segment", function()
            local f, g = tmpname(), tmpname()
            -- the composed fixture: own tc-intro, then the library segment tl-deathknell
            local code, out = run(VAL .. "-q --route test-composed --write-state " .. f .. " --until tl-deathknell "
                .. "tests/fixtures/core/AdventureAtlas_TestComposed")
            assert.are.equal(0, code, out)
            assert.matches("state before tl%-deathknell of test%-composed", out)
            local before = assert(Harness.ReadState(f))
            assert.are.equal("tl-accept-363", before.meta.untilStep)
            assert.are.same({}, before.done)
            code, out = run(VAL .. "-q --route test-composed --write-state " .. g .. " --until tl-363-364 "
                .. "tests/fixtures/core/AdventureAtlas_TestComposed")
            assert.are.equal(0, code, out)
            local mid = assert(Harness.ReadState(g))
            assert.are.same({ 363 }, mid.log)
            local full = tmpname()
            code = run(VAL .. "-q --route test-composed --write-state " .. full .. " tests/fixtures/core/AdventureAtlas_TestComposed")
            assert.are.equal(0, code)
            assert.is_true(#assert(Harness.ReadState(full)).done > #mid.done)
            -- unknown id / without --write-state: usage errors
            code, out = run(VAL .. "-q --route test-composed --write-state " .. g .. " --until nope "
                .. "tests/fixtures/core/AdventureAtlas_TestComposed")
            assert.are.equal(2, code)
            assert.matches("%-%-until nope matched no step id and no segment id of test%-composed", out)
            code, out = run(VAL .. "-q --until tl-deathknell tests/fixtures/core/AdventureAtlas_TestComposed")
            assert.are.equal(2, code)
            assert.matches("%-%-until is only used with %-%-write%-state", out)
            os.remove(f) os.remove(g) os.remove(full)
        end)

        it("a declared library without segments: a clear message, nothing to do", function()
            local root = tmpname()
            os.execute(("mkdir -p '%s/AdventureAtlas_HxEmpty/Segments'"):format(root))
            local dir = root .. "/AdventureAtlas_HxEmpty"
            writeFile(dir .. "/AdventureAtlas_HxEmpty.toc", "## Interface: 16001\n## Dependencies: AdventureAtlas\n"
                .. "## X-AdventureAtlas-Module: library\nData.lua\nSegments\\01_a.lua\n")
            writeFile(dir .. "/Segments/01_a.lua", "-- placeholder: no registration yet\n")
            -- gen_route_data writes empty library data for it
            local code, out = run("lua5.1 tools/gen_route_data.lua --no-overrides --stdout '" .. dir .. "'")
            assert.are.equal(0, code, out)
            assert.matches("AdventureAtlas.AddLibraryData%({\n    quests = {},\n    npcs = {},\n}%)", out)
            run("lua5.1 tools/gen_route_data.lua --no-overrides '" .. dir .. "'")
            local mod = Loader.LoadModule(dir, { schema = schema })
            assert.is_true(mod.isLibrary)
            assert.are.same({}, mod.errors)
            code, out = run(VAL .. "--harness '" .. dir .. "' " .. CLI_PALADIN .. " --state " .. STATE)
            assert.are.equal(0, code, out)
            assert.matches("library module AdventureAtlas_HxEmpty registers no library segments yet", out)
            code, out = run(SIM .. "--harness '" .. dir .. "' " .. CLI_PALADIN)
            assert.are.equal(0, code, out)
            assert.matches("nothing to simulate", out)
            code, out = run(VAL .. "--harness '" .. dir .. "' --segments h-a " .. CLI_PALADIN)
            assert.are.equal(1, code, out)
            assert.matches("registers no library segments yet: its segment files are placeholders", out)
            os.execute(("rm -rf '%s'"):format(root))
        end)

        it("simulate: the harness route plays through the real addon from the state", function()
            local f = tmpname()
            local code, out = run(SIM .. "--harness " .. LIB .. " " .. CLI_PALADIN .. " --state " .. STATE
                .. " --write-state " .. f)
            assert.are.equal(0, code, out)
            assert.matches("OK   harness%-FxHarnessLib %(Scourge PALADIN Horde%)", out)
            local st = assert(Harness.ReadState(f))
            assert.are.same({ 382 }, st.log)
            assert.are.equal("Brill", st.hearth)
            assert.are.same({ 1458, 63.25, 48.56 }, st.at)
            assert.are.same({ "Undercity" }, st.flightPaths)
            for _, id in ipairs({ 367, 370, 381, 427 }) do
                local found = false
                for _, d in ipairs(st.done) do found = found or d == id end
                assert.is_true(found, "done " .. id)
            end
            os.remove(f)
            -- the druid too; without the state 381 is not in the log
            code, out = run(SIM .. "--no-reload --harness " .. LIB .. " --profile race=Skyborne,class=DRUID,faction=Horde"
                .. " --state " .. STATE)
            assert.are.equal(0, code, out)
            code, out = run(SIM .. "--harness " .. LIB .. " " .. CLI_PALADIN)
            assert.are.equal(1, code, out)
            assert.matches("FAIL harness%-FxHarnessLib", out)
            code, out = run(SIM .. "--harness " .. LIB .. " --segments fh-nope " .. CLI_PALADIN)
            assert.are.equal(1, code, out)
            assert.matches("unknown library segment 'fh%-nope'", out)
        end)

        it("simulate: --write-state of a full route; several simulations are refused", function()
            local f = tmpname()
            local code, out = run(SIM .. "--no-reload --write-state " .. f .. " tests/fixtures/core/AdventureAtlas_TestRoute")
            assert.are.equal(0, code, out)
            local st = assert(Harness.ReadState(f))
            assert.are.equal("test-route", st.meta.route)
            code, out = run(SIM .. "--no-reload --write-state " .. f .. " tests/fixtures/core/AdventureAtlas_TestRoute "
                .. "tests/fixtures/core/AdventureAtlas_TestComposed")
            assert.are.equal(2, code, out)
            assert.matches("needs exactly one simulation", out)
            os.remove(f)
        end)
    end)

    describe("route_loader: ## X-AdventureAtlas-Module", function()
        it("declares a library; a bad value or routes in a declared library are errors", function()
            local root = tmpname()
            os.execute(("mkdir -p '%s/AdventureAtlas_HxBad' '%s/AdventureAtlas_HxRoute'"):format(root, root))
            writeFile(root .. "/AdventureAtlas_HxBad/AdventureAtlas_HxBad.toc",
                "## Interface: 16001\n## Dependencies: AdventureAtlas\n## X-AdventureAtlas-Module: libary\n")
            writeFile(root .. "/AdventureAtlas_HxRoute/AdventureAtlas_HxRoute.toc",
                "## Interface: 16001\n## Dependencies: AdventureAtlas\n## X-AdventureAtlas-Module: library\nRoute.lua\n")
            writeFile(root .. "/AdventureAtlas_HxRoute/Route.lua",
                "AdventureAtlas.RegisterRoute({ api = 1, id = \"hx-route\", title = \"R\", faction = \"Horde\" })\n")
            local bad = Loader.LoadModule(root .. "/AdventureAtlas_HxBad", { schema = schema })
            local route = Loader.LoadModule(root .. "/AdventureAtlas_HxRoute", { schema = schema })
            os.execute(("rm -rf '%s'"):format(root))
            assert.matches("X%-AdventureAtlas%-Module must be \"library\" %(got \"libary\"%)", bad.errors[1].msg)
            assert.is_false(bad.isLibrary)
            assert.matches("but the module registers route%(s%)", route.errors[1].msg)
            assert.is_false(route.isLibrary)
        end)
    end)
end)
