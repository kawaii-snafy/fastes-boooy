-- Validator gates of docs/dev/PLAN.md A.6.2 / A.6.3:
--   * acknowledged warnings: the step / segment key `ok` in its three forms, the kill ceiling of
--     level-grind, ERROR ok-needs-ceiling, WARN ok-unused; "W warning(s), A accepted";
--   * --strict (no unaccepted WARN) and --own (foreign warnings do not fail the run);
--   * the numeric criteria as ERRORs: --end-level, --max-grind-until, --baseline; --summary,
--     --grind-until, --write-baseline, --levels;
--   * worst case: a required `fly` / `hearth` that needs an optional `fp` / `sethearth`;
--   * trainer kinds (INFO train-service); xp-unknown is INFO; stable message fields.
-- In-memory routes over real Forever data (Deathknell) and the fixtures; the command lines on
-- temporary modules.

local DB = require("lib.fbdb")
local Loader = require("lib.route_loader")
local V = require("lib.validator")
local json = require("lib.json")

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

local function readAll(path)
    local fh = assert(io.open(path, "r"))
    local s = fh:read("*a")
    fh:close()
    return s
end

local VALIDATE = "lua5.1 tools/validate_routes.lua --no-overrides "
local FX = "tests/fixtures/"

local function with(result, code)
    local out = {}
    for _, m in ipairs(result.messages) do
        if m.code == code then out[#out + 1] = m end
    end
    return out
end

local UNDEAD_PALADIN = { api = 1, id = "mem", title = "mem", faction = "Horde", races = { "Scourge" },
    classes = { "PALADIN" } }

-- an in-memory route with one segment; `seg` adds segment keys (levels, ok), `def` replaces the route
local function route(steps, def, seg)
    local r = assert(schema.NormalizeRoute(def or UNDEAD_PALADIN))
    local sdef = { id = "s", title = "s", steps = steps }
    for k, v in pairs(seg or {}) do sdef[k] = v end
    local _, errs = schema.AddSegment(r, sdef)
    assert.are.same({}, errs)
    return r
end

-- the full validation of one profile, with the route-level checks and the criteria of the run
local function full(steps, opts, def, seg)
    local r = route(steps, def, seg)
    local o = { db = db, schema = schema }
    for k, v in pairs(opts or {}) do o[k] = v end
    local profiles = V.Profiles(r)
    local res = V.RunProfile(db, schema, r, profiles[1], o)
    local checks = V.RouteChecks(db, r, profiles)
    for _, m in ipairs(checks) do
        res.messages[#res.messages + 1] = m
        V.CountMessage(res, m, 1)
    end
    V.ApplyCriteria(res, r, o)
    return res, r
end

local function class(token, race)
    return { api = 1, id = "mem", title = "mem", faction = "Horde", races = { race or "Orc" }, classes = { token } }
end

-- Deathknell: 363 -> 364 (zombies); 376 (Novice Elreth)
local AT_MORDO, AT_SARVIS = { 1420, 30.2, 71.7 }, { 1420, 30.8, 66.2 }
local AT_ELRETH, AT_ZOMBIES = { 1420, 30.9, 66.0 }, { 1420, 32.5, 63.5 }

-- 363 turned in, 364 taken and turned in WITHOUT a complete step: WARN turnin-no-complete at the last step
local function noComplete(last)
    last.turnin, last.npc, last.at = 364, 1569, AT_SARVIS
    last.id = last.id or "in-364"
    return {
        { accept = 363, npc = 1568, at = AT_MORDO },
        { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS },
        last,
    }
end

describe("validator gates", function()
    setup(function()
        db = DB.Load("tools/data/forever_db.lua")
        schema = Loader.LoadSchema(".")
        root = os.tmpname()
        os.remove(root)
        os.execute(("mkdir -p '%s'"):format(root))
    end)
    teardown(function() os.execute(("rm -rf '%s'"):format(root)) end)

    describe("acknowledged warnings (`ok`)", function()
        it("without `ok` the WARN counts", function()
            local r = full(noComplete({}))
            assert.equal(1, r.counts.WARN)
            assert.equal(0, r.acceptedWarn)
            assert.is_nil(with(r, "turnin-no-complete")[1].accepted)
        end)

        it("form 1, a code: the WARN of that step is accepted, counted apart and hidden without -v", function()
            local r = full(noComplete({ ok = "turnin-no-complete" }))
            assert.equal(0, r.counts.WARN)
            assert.equal(1, r.acceptedWarn)
            local m = with(r, "turnin-no-complete")[1]
            assert.equal("WARN", m.severity)
            assert.is_true(m.accepted)
            local text = table.concat(V.FormatText({ { module = "m", results = { r } } }), "\n")
            assert.is_nil(text:find("turnin-no-complete", 1, true))
            assert.matches("result: 0 error%(s%), 0 warning%(s%), 1 accepted, %d+ info", text)
            text = table.concat(V.FormatText({ { module = "m", results = { r } } }, { verbose = true }), "\n")
            assert.matches("\n  ok    s#3 id=in%-364 %[turnin%-no%-complete%] turnin 364", text)
            -- the JSON report keeps the message and the count
            local rep = json.decode(json.encode(V.ReportTable({ { module = "m", results = { r } } }, db)))
            assert.equal(1, rep.routes[1].accepted)
            assert.equal(1, rep.totals.accepted)
            assert.equal(0, rep.totals.WARN)
            -- the Markdown report lists it apart from the warnings
            local md = table.concat(V.FormatMarkdown({ { module = "m", results = { r } } }, db), "\n")
            assert.matches("Принятые предупреждения, `ok` %(1%)", md)
            assert.is_nil(md:find("\n| WARN |", 1, true), "no WARN row in the route's table")
        end)

        it("form 2, a list of codes; a code that is not listed still counts", function()
            local r = full(noComplete({ train = true, ok = { "turnin-no-complete", "train-no-npc" } }))
            -- (the step has an npc: the quest ender; train-no-npc does not fire, see ok-unused)
            assert.equal(0, r.counts.WARN)
            assert.equal(1, r.acceptedWarn)
            r = full({
                { accept = 363, npc = 1568, at = AT_MORDO },
                { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS },
                { id = "two", turnin = 364, train = true, ok = { "turnin-no-complete", "train-no-npc" } },
            })
            assert.equal(0, r.counts.WARN)
            assert.equal(2, r.acceptedWarn)
            r = full({
                { accept = 363, npc = 1568, at = AT_MORDO },
                { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS },
                { id = "two", turnin = 364, train = true, ok = { "train-no-npc" } },
            })
            assert.equal(1, r.counts.WARN)
            assert.equal(1, r.acceptedWarn)
            assert.is_nil(with(r, "turnin-no-complete")[1].accepted)
        end)

        it("an ERROR is never accepted, and `ok` of another step does not help", function()
            local r = full({
                { accept = 363, npc = 1568, at = AT_MORDO, ok = "turnin-no-complete" },
                { id = "bad", turnin = 364, ok = "turnin-not-accepted" },
            })
            assert.equal(1, r.counts.ERROR)
            assert.equal(0, r.acceptedWarn)
            assert.equal("ERROR", with(r, "turnin-not-accepted")[1].severity)
            r = full(noComplete({}))
            assert.equal(1, r.counts.WARN)
        end)

        it("a WARN about a segment is accepted by `ok` of the segment", function()
            local steps = { { accept = 363, npc = 1568, at = AT_MORDO }, { turnin = 363, npc = 1569, at = AT_SARVIS } }
            local r = full(steps, nil, nil, { levels = { 1, 5 } })
            assert.equal(1, #with(r, "segment-level"))
            assert.equal(1, r.counts.WARN)
            r = full(steps, nil, nil, { levels = { 1, 5 }, ok = "segment-level" })
            assert.equal(0, r.counts.WARN)
            assert.equal(1, r.acceptedWarn)
            assert.is_true(with(r, "segment-level")[1].accepted)
            -- a step's `ok` does not reach the segment message
            steps[2].ok = "segment-level"
            r = full(steps, nil, nil, { levels = { 1, 5 } })
            assert.equal(1, r.counts.WARN)
        end)

        describe("level-grind", function()
            local function gate(ok)
                return { { id = "gate", level = 5, ok = ok } }
            end

            it("form 3, a ceiling: accepted while the gate needs at most N kills, a WARN again above", function()
                local plain = full(gate(nil))
                local kills = plain.summary.gates[1].kills
                assert.is_true(kills > 30, "the gate grinds: " .. kills)
                assert.equal("WARN", with(plain, "level-grind")[1].severity)
                assert.equal(kills, with(plain, "level-grind")[1].kills)

                local r = full(gate({ ["level-grind"] = kills }))
                local m = with(r, "level-grind")[1]
                assert.is_true(m.accepted)
                assert.equal(kills, m.okCeiling)
                assert.equal(0, r.counts.WARN)
                assert.equal(1, r.acceptedWarn)

                r = full(gate({ ["level-grind"] = kills - 1 }))
                m = with(r, "level-grind")[1]
                assert.is_nil(m.accepted)
                assert.equal(1, r.counts.WARN)
                assert.equal(0, r.acceptedWarn)
                assert.matches("%(above the acknowledged ceiling of " .. (kills - 1) .. " kills: the `ok` of this step no "
                    .. "longer applies%)$", m.msg)
            end)

            it("a list and a ceiling in one table", function()
                local r = full({
                    { accept = 363, npc = 1568, at = AT_MORDO },
                    { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS },
                    { id = "both", turnin = 364, level = 5, npc = 1569, at = AT_SARVIS,
                      ok = { "turnin-no-complete", ["level-grind"] = 500 } },
                })
                assert.equal(0, r.counts.WARN)
                assert.equal(2, r.acceptedWarn)
            end)

            it("ERROR ok-needs-ceiling: a plain acknowledgement would pass any number of kills", function()
                local r = full(gate("level-grind"))
                assert.equal(1, r.counts.ERROR)
                local e = with(r, "ok-needs-ceiling")[1]
                assert.equal("ERROR", e.severity)
                assert.equal("gate", e.stepId)
                assert.matches("ok lists level%-grind without a ceiling: write ok = { %[\"level%-grind\"%] = N }", e.msg)
                -- and the WARN is not accepted
                assert.equal(1, r.counts.WARN)
                assert.is_nil(with(r, "level-grind")[1].accepted)
                r = full(gate({ "level-grind", "skip-ahead" }))
                assert.equal(1, #with(r, "ok-needs-ceiling"))
            end)

            it("the ceiling is that of the normal run; a small gate is INFO and needs no `ok`", function()
                local r = full({ { id = "gate", level = 2 } })
                assert.equal("INFO", with(r, "level-grind")[1].severity)
                assert.equal(0, r.counts.WARN)
                assert.is_true(V.OkAccepts({ ["level-grind"] = 10 }, { severity = "WARN", code = "level-grind", kills = 10 }))
                assert.is_false((V.OkAccepts({ ["level-grind"] = 10 }, { severity = "WARN", code = "level-grind", kills = 11 })))
                assert.is_false((V.OkAccepts({ ["level-grind"] = true }, { severity = "WARN", code = "level-grind", kills = 1 })))
                assert.is_false((V.OkAccepts({ ["at-far"] = true }, { severity = "ERROR", code = "at-far" })))
                assert.is_true(V.OkAccepts({ ["at-far"] = 3 }, { severity = "WARN", code = "at-far" }), "no kill count: accepted")
            end)
        end)

        describe("ok-unused", function()
            local TOC = "## Interface: 16001\n## Dependencies: FastesBoooy\n%s\n"

            it("a listed code that fires in none of the validated routes; only on a full run", function()
                write("FastesBoooy_OkOwn/FastesBoooy_OkOwn.toc", TOC:format("Extra.lua\nRoute.lua"))
                write("FastesBoooy_OkOwn/Extra.lua", "-- registers nothing\n")
                write("FastesBoooy_OkOwn/Route.lua", [[
FastesBoooy.RegisterRoute({ api = 1, id = "ok-own", title = "R", faction = "Horde", races = { "Scourge" },
    classes = { "PALADIN" } })
FastesBoooy.AddSegment("ok-own", { id = "ok-seg", title = "S", ok = "segment-level", steps = {
    { id = "ok-a", accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 }, ok = { "at-far", "quest-carried" } },
} })
]])
                local dir = root .. "/FastesBoooy_OkOwn"
                local code, out = run(VALIDATE .. dir)
                assert.equal(0, code, out)
                -- quest-carried fires (accepted); at-far and segment-level do not
                assert.matches("WARN  ok%-seg#1 id=ok%-a %(Route.lua%) %[ok%-unused%] ok lists 'at%-far', but none of the 1 "
                    .. "validated route%(s%) containing this step reports it there: remove the acknowledgement", out)
                assert.matches("WARN  ok%-seg %(Route.lua%) %[ok%-unused%] ok lists 'segment%-level', but none of the 1 "
                    .. "validated route%(s%) containing this segment reports it there", out)
                assert.is_nil(out:find("ok lists 'quest-carried'", 1, true))
                assert.matches("result: 0 error%(s%), 2 warning%(s%), 1 accepted, %d+ info", out)
                assert.matches("validate_routes: 1 module%(s%), 0 error%(s%), 2 warning%(s%), 1 accepted", out)
                code = run(VALIDATE .. "-q --strict " .. dir)
                assert.equal(1, code)
                -- not evaluated on a partial run
                code, out = run(VALIDATE .. "--strict --route ok-own " .. dir)
                assert.equal(0, code, out)
                assert.is_nil(out:find("ok-unused", 1, true))
                code, out = run(VALIDATE .. "--strict --skip Extra.lua " .. dir)
                assert.equal(0, code, out)
                assert.is_nil(out:find("ok-unused", 1, true))
                -- an ignored code is not "unused"
                code, out = run(VALIDATE .. "--strict --ignore at-far,segment-level " .. dir)
                assert.equal(0, code, out)
            end)

            it("a shared step is unused only when no route containing it reports the code", function()
                write("FastesBoooy_OkShared/FastesBoooy_OkShared.toc", TOC:format("Seg.lua\nRoute.lua"))
                write("FastesBoooy_OkShared/Seg.lua", [[
FastesBoooy.AddLibrarySegment({ id = "os-seg", title = "S", steps = {
    -- a pet trainer: fine for the hunter (INFO train-service), a WARN for the warrior
    { id = "os-pet", train = true, npc = 3620, ok = "train-not-class-trainer" },
    { id = "os-stale", manual = true, note = "x", ok = "at-far" },
} })
]])
                write("FastesBoooy_OkShared/Route.lua", [[
FastesBoooy.RegisterRoute({ api = 1, id = "os-hunter", title = "H", faction = "Horde", races = { "Orc" }, classes = { "HUNTER" } })
FastesBoooy.UseSegments("os-hunter", { "os-seg" })
FastesBoooy.RegisterRoute({ api = 1, id = "os-warrior", title = "W", faction = "Horde", races = { "Orc" }, classes = { "WARRIOR" } })
FastesBoooy.UseSegments("os-warrior", { "os-seg" })
]])
                local dir = root .. "/FastesBoooy_OkShared"
                local code, out = run(VALIDATE .. "-v " .. dir)
                assert.equal(0, code, out)
                -- reported once, in the module's entry
                local _, n = out:gsub("%[ok%-unused%]", "")
                assert.equal(1, n)
                assert.matches("== shared content of module FastesBoooy_OkShared.-\n  WARN  %[library FastesBoooy_OkShared%] "
                    .. "os%-seg#2 id=os%-stale %(Seg.lua%) %[ok%-unused%] ok lists 'at%-far', but none of the 2 validated "
                    .. "route%(s%)", out)
                assert.is_nil(out:find("ok lists 'train-not-class-trainer'", 1, true))
                assert.matches("\n  ok    %[library FastesBoooy_OkShared%] os%-seg#1 id=os%-pet %(Seg.lua%) "
                    .. "%[train%-not%-class%-trainer%]", out)
                assert.matches("validate_routes: 1 module%(s%), 0 error%(s%), 1 warning%(s%), 1 accepted", out)
            end)
        end)
    end)

    describe("--strict and --own", function()
        local TOC = "## Interface: 16001\n## Dependencies: FastesBoooy\nSegments\\Zone.lua\nClasses\\Paladin.lua\n"
            .. "Classes\\Warrior.lua\nRoute.lua\n"
        local dir

        setup(function()
            dir = root .. "/FastesBoooy_Own"
            write("FastesBoooy_Own/FastesBoooy_Own.toc", TOC)
            write("FastesBoooy_Own/Segments/Zone.lua", [[
FastesBoooy.AddLibrarySegment({ id = "own-seg", title = "S", steps = {
    { id = "own-363", accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
    { id = "own-363-in", turnin = 363, npc = 1569, at = { 1420, 30.8, 66.2 } },
} })
]])
            -- one WARN in each class file: a train step without npc
            write("FastesBoooy_Own/Classes/Paladin.lua", [[
FastesBoooy.AddLibraryInsert({ after = "own-363", class = "PALADIN", steps = { { id = "own-pal", train = true } } })
]])
            write("FastesBoooy_Own/Classes/Warrior.lua", [[
FastesBoooy.AddLibraryInsert({ after = "own-363", class = "WARRIOR", steps = { { id = "own-war", train = true } } })
]])
            write("FastesBoooy_Own/Route.lua", [[
FastesBoooy.RegisterRoute({ api = 1, id = "own-paladin", title = "P", faction = "Horde", races = { "Scourge" }, classes = { "PALADIN" } })
FastesBoooy.UseSegments("own-paladin", { "own-seg" })
FastesBoooy.RegisterRoute({ api = 1, id = "own-warrior", title = "W", faction = "Horde", races = { "Scourge" }, classes = { "WARRIOR" } })
FastesBoooy.UseSegments("own-warrior", { "own-seg" })
]])
        end)

        it("--strict fails on an unaccepted WARN in any file", function()
            local code, out = run(VALIDATE .. "-q " .. dir)
            assert.equal(0, code, out)
            assert.matches("validate_routes: 1 module%(s%), 0 error%(s%), 2 warning%(s%)\n", out)
            code, out = run(VALIDATE .. "-q --strict " .. dir)
            assert.equal(1, code, out)
            assert.matches("2 warning%(s%) %(strict%)", out)
        end)

        it("with --own only the warnings of own files fail the run; the others are listed as foreign", function()
            local code, out = run(VALIDATE .. "-q --strict --own Classes/Warrior.lua " .. dir)
            assert.equal(1, code, out)
            assert.matches("own%-paladin %[Scourge PALADIN Horde%]: 0 error%(s%), 1 warning%(s%), %d+ info %(1 of the "
                .. "warnings foreign%)", out)
            assert.matches("own%-warrior %[Scourge WARRIOR Horde%]: 0 error%(s%), 1 warning%(s%), %d+ info\n", out)
            assert.matches("\nforeign warnings: 1 %(report them in the hand%-over%)\n  WARN  %[library FastesBoooy_Own%] "
                .. "own%-seg#1 id=own%-pal %(Classes/Paladin.lua%) %[train%-no%-npc%]", out)
            assert.matches("2 warning%(s%) %(1 of them foreign%) %(strict%)", out)
            -- a file without warnings of its own: the run passes, both are foreign
            code, out = run(VALIDATE .. "-q --strict --own 'Segments/*' --own Route.lua " .. dir)
            assert.equal(0, code, out)
            assert.matches("foreign warnings: 2 %(report them in the hand%-over%)", out)
            -- several globs
            code = run(VALIDATE .. "-q --strict --own 'Classes/P*' --own 'Classes/W*' " .. dir)
            assert.equal(1, code)
        end)

        it("the foreign block names the route of a message that has no step: one line per route", function()
            -- both routes plan level 9 and end far below: WARN route-level, a message of Route.lua
            write("FastesBoooy_OwnLv/FastesBoooy_OwnLv.toc", TOC)
            for _, f in ipairs({ "Segments/Zone.lua", "Classes/Paladin.lua", "Classes/Warrior.lua" }) do
                write("FastesBoooy_OwnLv/" .. f, readAll(dir .. "/" .. f))
            end
            write("FastesBoooy_OwnLv/Route.lua", (readAll(dir .. "/Route.lua"):gsub("classes = ", "levels = { 1, 9 }, classes = ")))
            local code, out = run(VALIDATE .. "-q --strict --own 'Segments/*' " .. root .. "/FastesBoooy_OwnLv")
            assert.equal(0, code, out)
            assert.matches("\nforeign warnings: 4 %(report them in the hand%-over%)\n", out)
            assert.matches("\n  WARN  route own%-paladin %(Route.lua%) %[route%-level%] route ends at simulated level [%d.]+; "
                .. "planned end level 9\n", out)
            assert.matches("\n  WARN  route own%-warrior %(Route.lua%) %[route%-level%] route ends at", out)
            -- a place in a file stays one line for all the routes that pass it
            local lines = V.ForeignLines({ { results = {
                { route = "a", file = "Route.lua", messages = {
                    { severity = "WARN", code = "route-level", msg = "ends at 3.92", foreign = true },
                    { severity = "WARN", code = "x", msg = "m", segment = "s", step = 1, stepId = "s1", file = "S.lua", foreign = true },
                } },
                { route = "b", file = "Route.lua", messages = {
                    { severity = "WARN", code = "route-level", msg = "ends at 3.40", foreign = true },
                    { severity = "WARN", code = "x", msg = "m", segment = "s", step = 1, stepId = "s1", file = "S.lua", foreign = true },
                } },
            } } })
            assert.same({
                "foreign warnings: 4 (report them in the hand-over)",
                "  WARN  route a (Route.lua) [route-level] ends at 3.92",
                "  WARN  s#1 id=s1 (S.lua) [x] m (2 route(s) / profile(s))",
                "  WARN  route b (Route.lua) [route-level] ends at 3.40",
            }, lines)
        end)

        it("errors always count, in any file", function()
            write("FastesBoooy_OwnErr/FastesBoooy_OwnErr.toc", "## Interface: 16001\n## Dependencies: FastesBoooy\nA.lua\nRoute.lua\n")
            write("FastesBoooy_OwnErr/A.lua", [[
FastesBoooy.AddLibrarySegment({ id = "oe-seg", title = "S", steps = { { id = "oe-1", turnin = 363 } } })
]])
            write("FastesBoooy_OwnErr/Route.lua", [[
FastesBoooy.RegisterRoute({ api = 1, id = "oe", title = "P", faction = "Horde", races = { "Scourge" }, classes = { "PALADIN" } })
FastesBoooy.UseSegments("oe", { "oe-seg" })
]])
            local code, out = run(VALIDATE .. "-q --strict --own Route.lua " .. root .. "/FastesBoooy_OwnErr")
            assert.equal(1, code, out)
            assert.matches("oe %[Scourge PALADIN Horde%]: 1 error%(s%)", out)
        end)

        it("accepted warnings do not fail --strict", function()
            write("FastesBoooy_Acc/FastesBoooy_Acc.toc", "## Interface: 16001\n## Dependencies: FastesBoooy\nRoute.lua\n")
            write("FastesBoooy_Acc/Route.lua", [[
FastesBoooy.RegisterRoute({ api = 1, id = "acc", title = "P", faction = "Horde", races = { "Scourge" }, classes = { "PALADIN" } })
FastesBoooy.AddSegment("acc", { id = "acc-seg", title = "S", steps = {
    { id = "acc-1", train = true, ok = "train-no-npc" }, -- CONFIRM: trainer id unknown
} })
]])
            local code, out = run(VALIDATE .. "-q --strict " .. root .. "/FastesBoooy_Acc")
            assert.equal(0, code, out)
            assert.matches("acc %[Scourge PALADIN Horde%]: 0 error%(s%), 0 warning%(s%), 1 accepted, 0 info", out)
            assert.matches("validate_routes: 1 module%(s%), 0 error%(s%), 0 warning%(s%), 1 accepted %(strict%)", out)
        end)
    end)

    describe("numeric criteria", function()
        local LEVELS_2 = { api = 1, id = "mem", title = "mem", faction = "Horde", races = { "Scourge" },
            classes = { "PALADIN" }, levels = { 1, 2 } }

        it("--end-level: ERROR when the normal run ends below the planned end level", function()
            local steps = { { accept = 363, npc = 1568, at = AT_MORDO }, { turnin = 363, npc = 1569, at = AT_SARVIS } }
            local r = full(steps, nil, LEVELS_2)
            assert.equal(0, r.counts.ERROR, "the tolerance of route-level is one level: nothing without the option")
            r = full(steps, { endLevel = true }, LEVELS_2)
            assert.equal(1, r.counts.ERROR)
            local e = with(r, "end-level")[1]
            assert.matches("^the route ends at simulated level 1%.%d%d %(worst case 1%.%d%d%); the planned end level is 2", e.msg)
            assert.equal(r.summary.endLevel, e.level)
            -- a level step reaches the plan
            steps[3] = { level = 2 }
            r = full(steps, { endLevel = true }, LEVELS_2)
            assert.equal(0, r.counts.ERROR)
        end)

        it("--end-level: the worst-case run must reach it too", function()
            -- the optional chain gives the XP for level 2; without it the route ends at level 1
            local steps = {
                { accept = 363, npc = 1568, at = AT_MORDO, optional = true },
                { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS, optional = true },
                { complete = 364, at = AT_ZOMBIES, optional = true },
                { turnin = 364, npc = 1569, at = AT_SARVIS, optional = true },
                { accept = 376, npc = 1661, at = AT_ELRETH },
            }
            local r = full(steps, { endLevel = true }, LEVELS_2)
            assert.is_true(r.summary.endLevel >= 2)
            assert.is_true(r.summary.endLevelWorst < 2)
            assert.equal(1, #with(r, "end-level"))
            assert.matches("worst case 1%.%d%d", with(r, "end-level")[1].msg)
        end)

        it("--end-level in a harness run: the planned end level of the last segment", function()
            local LIB = FX .. "validator/FastesBoooy_FxHarnessLib"
            local args = "-q --harness " .. LIB .. " --profile race=Scourge,class=PALADIN "
                .. "--state " .. FX .. "validator/harness_state_6.json "
            local code, out = run(VALIDATE .. args .. "--end-level --segments fh-deathknell")
            assert.equal(0, code, out)
            -- from a fresh character the same segments end far below their plan
            code, out = run(VALIDATE .. "--harness " .. LIB .. " --profile race=Scourge,class=PALADIN --end-level")
            assert.equal(1, code, out)
            assert.matches("%[end%-level%] the harness run ends at simulated level", out)
        end)

        it("--grind-until / --max-grind-until: the kills up to the end of a segment against a budget", function()
            local TR = FX .. "core/FastesBoooy_TestRoute"
            local res = V.ValidateModule(TR, { db = db, schema = schema, grindUntil = "tr-01" })
            assert.same({ segment = "tr-01", kills = 2, killsWorst = 2 }, res.results[1].summary.grindUntil)
            res = V.ValidateModule(TR, { db = db, schema = schema, maxGrindUntil = { segment = "tr-02", kills = 2, worst = 2 } })
            assert.equal(0, res.results[1].counts.ERROR)
            assert.equal("tr-02", res.results[1].summary.grindUntil.segment, "the budget's segment is the default")
            res = V.ValidateModule(TR, { db = db, schema = schema, maxGrindUntil = { segment = "tr-01", kills = 1, worst = 5 } })
            local e = with(res.results[1], "grind-budget")[1]
            assert.equal("ERROR", e.severity)
            assert.matches("grind kills up to the end of tr%-01: 2 %(worst case 2%); the budget is 1 %(worst case 5%)", e.msg)
            res = V.ValidateModule(TR, { db = db, schema = schema, maxGrindUntil = { segment = "tr-01", kills = 5, worst = 1 } })
            assert.equal(1, #with(res.results[1], "grind-budget"))
            -- a route without the segment cannot pass the budget silently
            res = V.ValidateModule(TR, { db = db, schema = schema, maxGrindUntil = { segment = "nope", kills = 5, worst = 5 } })
            assert.matches("the route has no segment 'nope'", with(res.results[1], "grind-budget")[1].msg)

            local code, out = run(VALIDATE .. "-q --max-grind-until tr-01=2/2 " .. TR)
            assert.equal(0, code, out)
            code, out = run(VALIDATE .. "--max-grind-until tr-01=1/2 " .. TR)
            assert.equal(1, code, out)
            assert.matches("ERROR route %[grind%-budget%]", out)
            code, out = run(VALIDATE .. "-q --max-grind-until tr-01 " .. TR)
            assert.equal(2, code)
            assert.matches("bad %-%-max%-grind%-until", out)
        end)

        it("--grind-until with a segment id no validated route has is refused (exit 2), nothing is written", function()
            local TR, TG = FX .. "core/FastesBoooy_TestRoute", FX .. "core/FastesBoooy_TestGuides"
            local file = root .. "/baseline_typo.json"
            local code, out = run(VALIDATE .. "-q --summary --grind-until tr-1 --write-baseline " .. file .. " " .. TR)
            assert.equal(2, code, out)
            assert.matches("validate_routes: %-%-grind%-until tr%-1: none of the 1 validated route%(s%) has a segment with "
                .. "this id", out)
            assert.is_nil(io.open(file, "r"), "no baseline without the pair")
            assert.not_matches("\t%-\t%-\n", out)
            -- one route with the segment is enough: the others have no pair ("-")
            code, out = run(VALIDATE .. "-q --summary --grind-until tr-01 " .. TR .. " " .. TG)
            assert.equal(0, code, out)
            assert.matches("tg%-orc%-warrior\t.-\t%-\t%-\n", out)
            -- the selection decides: the routes that are validated do not have it
            code, out = run(VALIDATE .. "-q --grind-until tr-01 --route 'tg-*' " .. TR .. " " .. TG)
            assert.equal(2, code, out)
            assert.matches("none of the 3 validated route%(s%)", out)
        end)

        it("--summary: one TSV line per route after the normal output", function()
            local code, out = run(VALIDATE .. "-q --summary --grind-until tr-01 " .. FX .. "core/FastesBoooy_TestRoute "
                .. FX .. "core/FastesBoooy_TestGuides")
            assert.equal(0, code, out)
            local lines = {}
            for line in out:gmatch("[^\n]+") do
                if line:find("\t", 1, true) then lines[#lines + 1] = line end
            end
            assert.same({
                "test-route\tScourge PALADIN Horde\t0\t6\t0\t0\t4.32\t4.32\t2\t2\t2\t2",
                "tg-undead-paladin\tScourge PALADIN Horde\t0\t0\t0\t0\t3.92\t3.92\t0\t0\t-\t-",
                "tg-orc-warrior\tOrc WARRIOR Horde\t0\t0\t0\t0\t3.40\t3.40\t0\t0\t-\t-",
                "tg-troll-mage\tTroll MAGE Horde\t0\t0\t0\t0\t3.40\t3.40\t0\t0\t-\t-",
            }, lines)
            -- they come after the last normal line; the module entry has no line
            assert.matches("validate_routes: 2 module%(s%).-\ntest%-route\t", out)
            -- columns 4-6: own unaccepted warnings, accepted, foreign
            code, out = run(VALIDATE .. "-q --summary --own Route.lua " .. FX .. "core/FastesBoooy_TestRoute")
            assert.equal(0, code, out)
            assert.matches("\ntest%-route\tScourge PALADIN Horde\t0\t1\t0\t5\t", out)
        end)

        it("--write-baseline / --baseline: per race the maximum of its routes; more kills are an ERROR", function()
            local file = root .. "/baseline.json"
            local TR, TG = FX .. "core/FastesBoooy_TestRoute", FX .. "core/FastesBoooy_TestGuides"
            local code, out = run(VALIDATE .. "-q --grind-until tr-01 --write-baseline " .. file .. " " .. TR .. " " .. TG)
            assert.equal(0, code, out)
            local data = json.decode(readAll(file))
            assert.same({
                grindKills = 2, grindKillsWorst = 2, grindKillsUntil = 2, grindKillsUntilWorst = 2,
                routes = { "test-route", "tg-undead-paladin" },
            }, data.races.Scourge)
            assert.same({ grindKills = 0, grindKillsWorst = 0, routes = { "tg-orc-warrior" } }, data.races.Orc)
            assert.equal("tr-01", data.meta.grindUntil)
            assert.equal(4, data.meta.routes)
            -- the same routes against their own baseline
            code, out = run(VALIDATE .. "-q --baseline " .. file .. " " .. TR .. " " .. TG)
            assert.equal(0, code, out)
            -- a lower baseline: the route needs more kills than its race's entry
            data.races.Scourge.grindKills = 1
            write("baseline_low.json", json.encode(data))
            code, out = run(VALIDATE .. "--baseline " .. root .. "/baseline_low.json " .. TR)
            assert.equal(1, code, out)
            assert.matches("ERROR route %[grind%-baseline%] the route needs 2 grind kills %(worst case 2%); the baseline of "
                .. "race Scourge is 1 %(worst case 2%)", out)
            -- a race without an entry does not pass silently
            data.races.Scourge = nil
            write("baseline_none.json", json.encode(data))
            code, out = run(VALIDATE .. "--baseline " .. root .. "/baseline_none.json " .. TR)
            assert.equal(1, code, out)
            assert.matches("%[grind%-baseline%] %-%-baseline: no entry for race Scourge", out)
            -- not a baseline file
            write("not_baseline.json", "[1, 2]")
            code, out = run(VALIDATE .. "-q --baseline " .. root .. "/not_baseline.json " .. TR)
            assert.equal(2, code)
            assert.matches("not a baseline file", out)
        end)

        it("the criteria work in a harness run too", function()
            local file = root .. "/harness_baseline.json"
            local args = "-q --harness " .. FX .. "validator/FastesBoooy_FxHarnessLib --profile race=Scourge,class=PALADIN "
                .. "--state " .. FX .. "validator/harness_state_6.json "
            local code, out = run(VALIDATE .. args .. "--summary --grind-until fh-deathknell --write-baseline " .. file)
            assert.equal(0, code, out)
            local kills = tonumber(out:match("\nharness%-FxHarnessLib\tScourge PALADIN Horde\t%d+\t%d+\t%d+\t%d+\t[%d.]+\t"
                .. "[%d.]+\t(%d+)\t"))
            assert.is_truthy(kills)
            assert.equal(kills, json.decode(readAll(file)).races.Scourge.grindKills)
            code, out = run(VALIDATE .. args .. "--baseline " .. file .. " --max-grind-until fh-deathknell=9999/9999")
            assert.equal(0, code, out)
        end)
    end)

    describe("--levels", function()
        it("prints the level before every step with an explicit id, normal and worst case", function()
            local code, out = run(VALIDATE .. "-q --levels --route tg-orc-warrior " .. FX .. "core/FastesBoooy_TestGuides")
            assert.equal(0, code, out)
            local lines = {}
            for line in out:gmatch("[^\n]+") do
                if line:find("\t", 1, true) then lines[#lines + 1] = line end
            end
            assert.equal(9, #lines)
            assert.equal("tg-dur-4641\ttg-dur-01-valley-of-trials\t1.00\t1.00\t-\tSegments/Durotar/01_ValleyOfTrials.lua\t"
                .. "accept 4641", lines[1])
            -- an insert step names its anchor and its own file
            assert.equal("tg-war-letter-orc\ttg-dur-01-valley-of-trials\t2.33\t2.33\ttg-dur-788-in\tClasses/Warrior.lua\t"
                .. "accept 2383", lines[5])
            assert.equal("tg-war-train-2\ttg-dur-01-valley-of-trials\t2.37\t2.37\ttg-war-frang\tClasses/Warrior.lua\ttrain",
                lines[7])
            assert.matches("^tg%-dur%-789%-in\t", lines[9])
        end)

        it("needs exactly one route; steps with positional ids are left out; the worst case differs", function()
            local code, out = run(VALIDATE .. "-q --levels " .. FX .. "core/FastesBoooy_TestGuides")
            assert.equal(2, code)
            assert.matches("%-%-levels needs exactly one route x profile, this run has 3", out)
            local r = full({
                { id = "a", accept = 363, npc = 1568, at = AT_MORDO, optional = true },
                { turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS, optional = true },
                { id = "c", complete = 364, at = AT_ZOMBIES, optional = true },
                { id = "d", turnin = 364, npc = 1569, at = AT_SARVIS, optional = true },
                { id = "e", accept = 376, npc = 1661, at = AT_ELRETH },
            }, { levels = true })
            local ids = {}
            for i, e in ipairs(r.stepLevels) do ids[i] = e.id end
            assert.same({ "a", "c", "d", "e" }, ids)
            local last = r.stepLevels[4]
            assert.is_true(last.level > 2)
            assert.equal(1, last.levelWorst)
            assert.equal("s", last.segment)
            assert.equal("accept 376", last.actions)
            assert.same({ "a\ts\t1.00\t1.00\t-\t-\taccept 363" }, { V.LevelLines(r)[1] })
            -- without the option nothing is collected
            assert.is_nil(full({ { id = "a", accept = 363, npc = 1568, at = AT_MORDO } }).stepLevels)
        end)
    end)

    describe("worst case: fly and hearth", function()
        local AT_UC, AT_BRILL = { 1458, 63.3, 48.6 }, { 1420, 61.7, 52.1 }

        it("ERROR optional-dependency: a required fly whose flight point only an optional step learns", function()
            local r = full({
                { id = "fp", fp = "Undercity", npc = 4551, at = AT_UC, optional = true },
                { id = "fly", fly = "Undercity", npc = 4551, at = AT_UC },
            })
            local e = with(r, "optional-dependency")
            assert.equal(1, #e)
            assert.equal("fly", e[1].stepId)
            assert.matches("fly Undercity needs the flight point, but it is learned only at optional step s#1", e[1].msg)
            assert.equal(1, r.counts.ERROR)
            assert.same({}, with(r, "fly-unknown-fp"), "the normal run knows the flight point")
        end)

        it("no error when the fp step is required, the fly step is optional too, or the start state knows it", function()
            local r = full({
                { fp = "Undercity", npc = 4551, at = AT_UC },
                { fly = "Undercity", npc = 4551, at = AT_UC },
                { fp = "Undercity", npc = 4551, at = AT_UC, optional = true },
                { fly = "Undercity", npc = 4551, at = AT_UC },
            })
            assert.equal(0, r.counts.ERROR)
            r = full({
                { fp = "Undercity", npc = 4551, at = AT_UC, optional = true },
                { fly = "Undercity", npc = 4551, at = AT_UC, optional = true },
            })
            assert.equal(0, r.counts.ERROR)
            r = full({
                { fp = "Undercity", npc = 4551, at = AT_UC, optional = true },
                { fly = "Undercity", npc = 4551, at = AT_UC },
            }, { startState = { level = 1, flightPaths = { "Undercity" }, file = "inline" } })
            assert.equal(0, r.counts.ERROR)
        end)

        it("ERROR optional-dependency: a required hearth whose only binding is an optional sethearth", function()
            local r = full({
                { id = "bind", sethearth = "Brill", npc = 5688, at = AT_BRILL, optional = true },
                { id = "home", hearth = "Brill", at = AT_BRILL },
            })
            local e = with(r, "optional-dependency")
            assert.equal(1, #e)
            assert.equal("home", e[1].stepId)
            assert.matches("hearth Brill needs the hearthstone bound there, but only optional step s#1 binds it", e[1].msg)
            assert.matches("the hearthstone is bound to the default bind point then", e[1].msg)
            -- bound elsewhere by a required step before: the worst case goes there
            r = full({
                { sethearth = "Undercity", npc = 5688, at = AT_BRILL },
                { sethearth = "Brill", npc = 5688, at = AT_BRILL, optional = true },
                { id = "home", hearth = "Brill", at = AT_BRILL },
            })
            assert.matches("the hearthstone is bound to Undercity then", with(r, "optional-dependency")[1].msg)
        end)

        it("no error when a required step binds there, before or after the optional one", function()
            local r = full({
                { sethearth = "Brill", npc = 5688, at = AT_BRILL },
                { sethearth = "Brill", npc = 5688, at = AT_BRILL, optional = true },
                { hearth = "Brill", at = AT_BRILL },
            })
            assert.equal(0, r.counts.ERROR)
            -- a required bind after the optional one decides: a plain mismatch of the normal run, no error
            r = full({
                { sethearth = "Brill", npc = 5688, at = AT_BRILL, optional = true },
                { sethearth = "Undercity", npc = 5688, at = AT_BRILL },
                { hearth = "Brill", at = AT_BRILL },
            })
            assert.equal(0, r.counts.ERROR)
            assert.equal(1, #with(r, "hearth-mismatch"))
            -- an optional hearth is skipped with its bind
            r = full({
                { sethearth = "Brill", npc = 5688, at = AT_BRILL, optional = true },
                { hearth = "Brill", at = AT_BRILL, optional = true },
            })
            assert.equal(0, r.counts.ERROR)
        end)
    end)

    describe("trainer kinds", function()
        local function train(npc, token, race)
            return full({ { id = "t", train = true, npc = npc } }, nil, class(token, race))
        end

        it("a weapon master and a riding trainer are accepted for any class (INFO train-service)", function()
            for _, case in ipairs({ { 2704, "weapon master" }, { 4752, "riding trainer" }, { 7953, "riding trainer" } }) do
                for _, token in ipairs({ "WARRIOR", "MAGE" }) do
                    local r = train(case[1], token)
                    assert.equal(0, r.counts.ERROR, case[1] .. " " .. token)
                    assert.equal(0, r.counts.WARN, case[1] .. " " .. token)
                    local m = with(r, "train-service")[1]
                    assert.equal("INFO", m.severity)
                    assert.equal(case[1], m.npc)
                    assert.matches("is a " .. case[2] .. ", not a %a+ trainer: accepted", m.msg)
                end
            end
        end)

        it("a pet trainer only for a HUNTER, a portal trainer only for a MAGE", function()
            assert.equal(1, #with(train(3620, "HUNTER"), "train-service"))
            assert.equal(1, #with(train(5958, "MAGE", "Troll"), "train-service"))
            -- the others as before: a trainer of no class
            local r = train(3620, "WARRIOR")
            assert.equal(1, #with(r, "train-not-class-trainer"))
            assert.equal(1, r.counts.WARN)
            assert.equal(1, #with(train(5958, "WARRIOR"), "train-not-class-trainer"))
        end)

        it("other cases as before: the class trainer, another class's trainer, no trainer", function()
            local r = train(3153, "WARRIOR")
            assert.same({ ERROR = 0, WARN = 0, INFO = 0 }, r.counts)
            assert.equal(1, #with(train(3153, "MAGE"), "train-wrong-trainer"))
            assert.equal(1, #with(train(6928, "WARRIOR"), "train-wrong-trainer"), "an innkeeper")
            -- a demon trainer is a vendor in Forever: `train` is wrong there, `vendor` is right
            assert.equal(1, #with(train(12776, "WARLOCK"), "train-wrong-trainer"))
            local v = full({ { vendor = true, npc = 12776 } }, nil, class("WARLOCK"))
            assert.same({ ERROR = 0, WARN = 0, INFO = 0 }, v.counts)
            assert.same({ "ok" }, { V.TrainVerdict("WARRIOR", "Warrior Trainer", { trainer = true }) })
            assert.same({ "service", "weapon master" }, { V.TrainVerdict("PRIEST", "Weapon Master", { trainer = true }) })
            assert.same({ "error" }, { V.TrainVerdict("PRIEST", "Weapon Master", {}) })
            assert.same({ "ok" }, { V.TrainVerdict(nil, "Expert Blacksmith", { trainer = true }) })
        end)
    end)

    describe("messages", function()
        it("xp-unknown is INFO; the summary counts the quests with estimated XP and their share", function()
            -- 92460 "Coming of Age" (Zephras): XP unknown in the snapshot
            local r = full({
                { accept = 92460, npc = 251362 },
                { turnin = 92460, npc = 251361 },
            }, nil, { api = 1, id = "mem", title = "mem", faction = "Horde", races = { "Skyborne" }, classes = { "DRUID" } })
            assert.equal(0, r.counts.ERROR)
            assert.equal(0, r.counts.WARN)
            local m = with(r, "xp-unknown")[1]
            assert.equal("INFO", m.severity)
            assert.equal(92460, m.quest)
            assert.equal(1, r.summary.unknownXpQuests)
            assert.equal(100, r.summary.xpQuestEstimatedPct)
            local text = table.concat(V.FormatText({ { module = "m", results = { r } } }), "\n")
            assert.matches("; 1 quests with estimated XP %(100%.0%% of quest XP%); ", text)
            -- a route with known XP only
            r = full({ { accept = 363, npc = 1568, at = AT_MORDO }, { turnin = 363, npc = 1569, at = AT_SARVIS } })
            assert.equal(0, r.summary.xpQuestEstimatedPct)
        end)

        it("carry stable fields next to the text: quest, npc, kills, level, file, shared", function()
            local r = full({
                { id = "a", accept = 363, npc = 1568, at = AT_MORDO },
                { id = "b", turnin = 363, accept = 364, npc = 1569, at = AT_SARVIS },
                { id = "c", complete = 364, at = AT_ZOMBIES },
                { id = "far", turnin = 364, npc = 1569, at = { 1420, 32.4, 66.2 } },
                { id = "gate", level = 5 },
                { id = "carried", accept = 376, npc = 1661, at = AT_ELRETH },
            })
            local kill = with(r, "complete-kill-xp")[1]
            assert.equal(364, kill.quest)
            assert.is_true(kill.kills > 0)
            assert.equal("number", type(kill.level))
            local far = with(r, "at-far")[1]
            assert.equal(1569, far.npc)
            assert.is_nil(far.quest, "a position message is about the NPC")
            local grind = with(r, "level-grind")[1]
            assert.equal(r.summary.gates[1].kills, grind.kills)
            assert.equal(r.summary.gates[1].from, grind.level)
            assert.equal(376, with(r, "quest-carried")[1].quest)
            assert.is_nil(kill.shared)
            -- a shared step: m.shared next to m.library, and the file of the template
            local res = V.ValidateModule(FX .. "core/FastesBoooy_TestGuides", { db = db, schema = schema,
                route = "tg-orc-warrior" })
            local found
            for _, m in ipairs(res.results[2].messages) do
                if m.stepId == "tg-dur-boars" then found = m end
            end
            assert.is_true(found.shared)
            assert.equal("FastesBoooy_TestGuides", found.library)
            assert.equal("Segments/Durotar/01_ValleyOfTrials.lua", found.file)
            assert.equal(788, found.quest)
        end)
    end)
end)
