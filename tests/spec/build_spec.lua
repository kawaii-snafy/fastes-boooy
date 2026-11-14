-- The build: Makefile targets that run the simulator in parallel, and the CI workflows
-- (docs/dev/PLAN.md A.7).
--   * `make simulate` builds its job list from `simulate_routes.lua --list-routes` and runs one
--     simulator per route, JOBS at a time; a failing --list-routes, an empty list or a failing job
--     fails the target (never "nothing simulated, exit 0");
--   * `make simulate-sync` = SYNC_ROUTES x (SYNC_LEVELS + SYNC_MID + SYNC_PLUS), same guards;
--     `make simulate-sync-full` = every route;
--   * the output of a parallel job is one block of the log, whatever its size;
--   * `make route`, `make check-fast`;
--   * `make report` replaces the report only by a new one and fails when the validator wrote none;
--   * the values of the Makefile name routes and segments that exist;
--   * .github/workflows: ci.yml runs every stage of `make check` within 25 minutes and the two
--     freshness checks; nightly.yml runs simulate-sync-full on a schedule.
-- The recipes are run with a FAKE simulator (SIM=...): a shell script that answers --list-routes
-- from a file and records every other call, so no route is simulated here.
--
-- busted itself may run under make (`make test`, `make -j4 check`, `make check ROUTE=...`): the make
-- processes started here must not inherit the flags, the jobserver or the command-line variables of
-- that outer make (MAKEFLAGS and friends), or they would print "jobserver unavailable" warnings and
-- answer with the caller's values instead of the Makefile's. MAKE is `make` with a clean environment.

local root

local MAKE = "env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u MAKEOVERRIDES -u GNUMAKEFLAGS make"

local function run(cmd)
    local p = assert(io.popen(cmd .. " 2>&1; echo \"__EXIT=$?\""))
    local out = p:read("*a")
    p:close()
    local code = tonumber(out:match("__EXIT=(%d+)%s*$"))
    return code, (out:gsub("__EXIT=%d+%s*$", ""))
end

local function readFile(path)
    local fh = io.open(path, "r")
    if not fh then return nil end
    local text = fh:read("*a")
    fh:close()
    return text
end

local function writeFile(path, text)
    local fh = assert(io.open(path, "wb"))
    fh:write(text)
    fh:close()
end

-- The fake simulator. Files in its directory steer it:
--   routes      the --list-routes answer (missing: --list-routes fails with exit 1)
--   fail        an argument line that fails (exit 1) when it is run
--   together    N: every job waits (2 s at most) until N jobs have started -- proves they run at once
--   big         N: every job prints N numbered lines (about 110 bytes each) before its result line
-- Every job appends its argument line to `calls`.
local FAKE = [[
#!/bin/sh
dir=`dirname "$0"`
if [ "$1" = "--list-routes" ]; then
    [ -f "$dir/routes" ] || { echo "fake: module does not load" >&2; exit 1; }
    cat "$dir/routes"
    exit 0
fi
echo "$*" >> "$dir/calls"
touch "$dir/started.$$"
if [ -f "$dir/together" ]; then
    want=`cat "$dir/together"`
    i=0
    while [ `ls "$dir" | grep -c '^started\.'` -lt "$want" ]; do
        i=`expr $i + 1`
        [ $i -gt 20 ] && { echo "FAIL $*: ran alone"; exit 1; }
        sleep 0.1
    done
fi
if [ -f "$dir/big" ]; then
    awk -v n="`cat "$dir/big"`" -v tag="$*" 'BEGIN {
        pad = sprintf("%090d", 0)
        for (i = 1; i <= n; i++) print "BIG " tag " " i " " pad " END"
    }'
fi
if [ -f "$dir/fail" ] && [ "$*" = "`cat "$dir/fail"`" ]; then
    echo "FAIL $*"
    exit 1
fi
echo "OK   $*"
exit 0
]]

-- a fresh fake simulator; files = { routes = "a\nb\n", fail = "...", together = "2" }
local n = 0
local function fake(files)
    n = n + 1
    local dir = ("%s/fake%d"):format(root, n)
    os.execute(("mkdir -p '%s'"):format(dir))
    writeFile(dir .. "/sim.sh", FAKE)
    os.execute(("chmod +x '%s/sim.sh'"):format(dir))
    for name, text in pairs(files or {}) do writeFile(dir .. "/" .. name, text) end
    return {
        dir = dir,
        make = function(args)
            return run(("%s -s --no-print-directory SIM='%s/sim.sh' %s"):format(MAKE, dir, args))
        end,
        calls = function()
            local list = {}
            for line in (readFile(dir .. "/calls") or ""):gmatch("[^\n]+") do list[#list + 1] = line end
            table.sort(list)
            return list
        end,
    }
end

-- the command that prints the value of a Makefile variable (GNU make --eval)
local function makeVarCommand(name)
    return ("%s -s --no-print-directory --eval='print-var: ; @echo \"$(%s)\"' print-var"):format(MAKE, name)
end

-- the value of a Makefile variable: the last line of the output (a warning of make would be above it)
local function makeVar(name)
    local code, out = run(makeVarCommand(name))
    assert.equal(0, code, out)
    out = out:gsub("%s+$", "")
    return (out:match("([^\n]*)$"))
end

-- The routes the modules under addons register, by id; clean = every module loads without errors.
-- (In a parallel phase another author's file may be broken for a while: the cases that need the
-- real route list then only check that --list-routes refuses to print one.)
local function addonRoutes()
    local Loader = require("lib.route_loader")
    local schema = Loader.LoadSchema(".")
    local routes, clean = {}, true
    for _, dir in ipairs(Loader.DiscoverModules("addons")) do
        local mod = Loader.LoadModule(dir, { schema = schema })
        if #mod.errors > 0 then clean = false end
        for _, r in ipairs(mod.routes) do routes[r.id] = r end
    end
    return routes, clean
end

describe("the build (Makefile, CI workflows)", function()
    setup(function()
        root = os.tmpname()
        os.remove(root)
        os.execute(("mkdir -p '%s'"):format(root))
    end)
    teardown(function() os.execute(("rm -rf '%s'"):format(root)) end)

    describe("make simulate", function()
        it("one simulator per route of --list-routes, JOBS at a time", function()
            local f = fake({ routes = "r-one\nr-two\nr-three\n", together = "3" })
            local code, out = f.make("simulate JOBS=3")
            assert.equal(0, code, out)
            assert.same({ "--route r-one", "--route r-three", "--route r-two" }, f.calls())
            assert.matches("simulate: 3 route%(s%), 3 at a time\n", out)
            assert.matches("OK   %-%-route r%-two\n", out)
            assert.matches("simulate: all routes passed\n", out)
        end)

        it("JOBS=1 runs them one after the other", function()
            -- the same fake that needs two jobs at once fails when make runs one at a time
            local f = fake({ routes = "r-one\nr-two\n", together = "2" })
            local code, out = f.make("simulate JOBS=1")
            assert.is_true(code ~= 0, out)
            assert.matches("ran alone", out)
            assert.is_nil(out:find("all routes passed", 1, true))
            f = fake({ routes = "r-one\nr-two\n", together = "2" })
            code, out = f.make("simulate JOBS=2")
            assert.equal(0, code, out)
        end)

        it("fails when --list-routes fails (a module that does not load): nothing is simulated", function()
            local f = fake({})
            local code, out = f.make("simulate")
            assert.is_true(code ~= 0, out)
            assert.matches("fake: module does not load", out)
            assert.matches("simulate: %-%-list%-routes failed: nothing simulated", out)
            assert.same({}, f.calls())
        end)

        it("fails on an empty route list instead of starting one simulator for everything", function()
            local f = fake({ routes = "" })
            local code, out = f.make("simulate")
            assert.is_true(code ~= 0, out)
            assert.matches("simulate: no routes", out)
            assert.same({}, f.calls())
        end)

        it("fails when one simulation fails; the others still run", function()
            local f = fake({ routes = "r-one\nr-two\nr-three\n", fail = "--route r-two" })
            local code, out = f.make("simulate JOBS=2")
            assert.is_true(code ~= 0, out)
            assert.matches("FAIL %-%-route r%-two", out)
            assert.equal(3, #f.calls())
            assert.is_nil(out:find("all routes passed", 1, true))
        end)

        it("the output of a job is one block of the log, also when large jobs end together", function()
            -- Six jobs start together and print about 330 KB each, far more than a pipe takes in one
            -- write, and the reader of the log starts a second late: by then every job has its output
            -- ready. Jobs that write on their own would all be writing at once and mix their lines.
            local ids, list = { "r-1", "r-2", "r-3", "r-4", "r-5", "r-6" }, {}
            for i, id in ipairs(ids) do list[i] = id .. "\n" end
            local f = fake({ routes = table.concat(list), together = "6", big = "3000" })
            local code, out = run(("{ %s -s --no-print-directory SIM='%s/sim.sh' simulate JOBS=6; "
                .. "echo $? > '%s/status'; } | { sleep 1; cat; }"):format(MAKE, f.dir, f.dir))
            assert.equal(0, code, out:sub(1, 2000))
            assert.equal("0\n", readFile(f.dir .. "/status"), out:sub(1, 2000))
            local blocks, count, last, current = 0, {}, {}, nil
            for line in out:gmatch("[^\n]+") do
                if not line:find("^simulate: ") then
                    local id, i = line:match("^BIG %-%-route (r%-%d) (%d+) 0+ END$")
                    if not id then id = line:match("^OK   %-%-route (r%-%d)$") end
                    assert.is_truthy(id, "a broken line: " .. line:sub(1, 200))
                    if id ~= current then
                        blocks, current = blocks + 1, id
                    end
                    if i then
                        -- the lines of a job in their order, none lost
                        assert.equal((last[id] or 0) + 1, tonumber(i))
                        last[id] = tonumber(i)
                    end
                    count[id] = (count[id] or 0) + 1
                end
            end
            assert.equal(6, blocks)
            for _, id in ipairs(ids) do assert.equal(3001, count[id], id) end
            assert.equal(6, #f.calls())
        end)

        it("a failing job prints its whole output and fails the target", function()
            local f = fake({ routes = "r-1\nr-2\n", fail = "--route r-2", big = "50" })
            local code, out = f.make("simulate JOBS=2")
            assert.is_true(code ~= 0, out)
            assert.matches("BIG %-%-route r%-2 50 0+ END\nFAIL %-%-route r%-2\n", out)
            assert.matches("BIG %-%-route r%-1 50 0+ END\nOK   %-%-route r%-1\n", out)
        end)

        it("the real --list-routes output is what the recipe expects: one id per line", function()
            local routes, clean = addonRoutes()
            local code, out = run("lua5.1 tools/simulate_routes.lua --no-overrides --list-routes")
            if not clean then
                assert.equal(1, code, out)
                return
            end
            assert.equal(0, code, out)
            local lines = 0
            for line in out:gmatch("[^\n]+") do
                lines = lines + 1
                assert.matches("^[A-Za-z0-9_-]+$", line)
                assert.is_truthy(routes[line], "not a route id: " .. line)
            end
            assert.is_true(lines > 0)
        end)
    end)

    describe("make simulate-sync", function()
        local VARS = "SYNC_ROUTES='ra rb' SYNC_LEVELS='10 23' SYNC_MID='21/seg-a,seg-b 29/seg-c' SYNC_PLUS='2'"

        it("SYNC_ROUTES x (SYNC_LEVELS + SYNC_MID + SYNC_PLUS) runs, in parallel", function()
            local f = fake({ together = "4" })
            local code, out = f.make("simulate-sync JOBS=4 " .. VARS)
            assert.equal(0, code, out)
            local expected = {}
            for _, r in ipairs({ "ra", "rb" }) do
                expected[#expected + 1] = ("--route %s --ahead 10"):format(r)
                expected[#expected + 1] = ("--route %s --ahead 23"):format(r)
                expected[#expected + 1] = ("--route %s --ahead 21 --ahead-at seg-a,seg-b"):format(r)
                expected[#expected + 1] = ("--route %s --ahead 29 --ahead-at seg-c"):format(r)
                expected[#expected + 1] = ("--route %s --level-plus 2"):format(r)
            end
            table.sort(expected)
            assert.same(expected, f.calls())
            assert.matches("simulate%-sync: 10 run%(s%), 4 at a time\n", out)
            assert.matches("simulate%-sync: all runs passed\n", out)
        end)

        it("fails on an empty SYNC_ROUTES and when a run fails", function()
            local f = fake({})
            local code, out = f.make("simulate-sync SYNC_ROUTES=")
            assert.is_true(code ~= 0, out)
            assert.matches("simulate%-sync: no runs", out)
            assert.same({}, f.calls())
            f = fake({ fail = "--route rb --level-plus 2" })
            code, out = f.make("simulate-sync JOBS=2 " .. VARS)
            assert.is_true(code ~= 0, out)
            assert.matches("FAIL %-%-route rb %-%-level%-plus 2", out)
            assert.equal(10, #f.calls())
        end)

        it("simulate-sync-full: every route of --list-routes; a failing list fails the target", function()
            local f = fake({ routes = "r-one\nr-two\nr-three\n" })
            local code, out = f.make("simulate-sync-full JOBS=2 SYNC_LEVELS=35 SYNC_MID= SYNC_PLUS=")
            assert.equal(0, code, out)
            assert.same({ "--route r-one --ahead 35", "--route r-three --ahead 35", "--route r-two --ahead 35" }, f.calls())
            f = fake({})
            code, out = f.make("simulate-sync-full")
            assert.is_true(code ~= 0, out)
            assert.matches("simulate%-sync%-full: %-%-list%-routes failed", out)
            assert.same({}, f.calls())
        end)
    end)

    describe("make route / make check-fast", function()
        it("route: the validator with VALIDATE_FLAGS, then the simulator, both for ROUTE", function()
            local code, out = run(MAKE
                .. " -n --no-print-directory route ROUTE=some-route VALIDATE_FLAGS='--strict --end-level'")
            assert.equal(0, code, out)
            assert.matches("lua5%.1 tools/validate_routes%.lua %-%-strict %-%-end%-level %-%-route 'some%-route'\n", out)
            assert.matches("\nlua5%.1 tools/simulate_routes%.lua %-%-route 'some%-route'\n", out)
        end)

        it("check-fast: lint, validate, the fixture stages and one simulation; no busted, no sync runs", function()
            -- VALIDATE_FLAGS is given here: its value in the Makefile changes with the phases (nothing,
            -- then --strict --end-level, then the budgets), and this case is about the stages
            local code, out = run(MAKE
                .. " -n --no-print-directory check-fast ROUTE=some-route VALIDATE_FLAGS='--strict --end-level'")
            assert.equal(0, code, out)
            assert.matches("luacheck ", out)
            assert.matches("\nlua5%.1 tools/validate_routes%.lua %-%-strict %-%-end%-level\n", out)
            assert.matches("AdventureAtlas_TestGuides", out)
            assert.matches("%-%-harness ", out)
            assert.matches("\nlua5%.1 tools/simulate_routes%.lua %-%-route 'some%-route'\n", out)
            assert.is_nil(out:find("busted", 1, true))
            assert.is_nil(out:find("--ahead", 1, true))
            assert.is_nil(out:find("--list-routes", 1, true))
        end)

        it("the default ROUTE selects a route that exists", function()
            local routes, clean = addonRoutes()
            local Glob = require("lib.glob")
            local list = Glob.NewList(makeVar("ROUTE"))
            local matched = 0
            for id in pairs(routes) do
                if Glob.ListMatch(list, id) then matched = matched + 1 end
            end
            assert.is_true(matched >= 1, "ROUTE = " .. makeVar("ROUTE") .. " matches no route")
            assert.same({}, Glob.Unmatched(list))
            if clean then
                local code, out = run(("lua5.1 tools/simulate_routes.lua --no-overrides --list-routes --route '%s'")
                    :format(makeVar("ROUTE")))
                assert.equal(0, code, out)
                assert.matches("undead%-paladin\n", out)
            end
        end)
    end)

    describe("make report", function()
        -- A fake validator (LUA=...): it writes the file named after --markdown when `text` exists and
        -- exits with the status in `status`. REPORT=... keeps the recipe away from docs/VALIDATION.md.
        local VALIDATOR = [[
#!/bin/sh
dir=`dirname "$0"`
echo "$*" >> "$dir/calls"
file=
while [ $# -gt 0 ]; do
    [ "$1" = "--markdown" ] && file=$2
    shift
done
[ -f "$dir/text" ] && cat "$dir/text" > "$file"
[ -f "$dir/status" ] && exit "`cat "$dir/status"`"
exit 0
]]
        local m = 0
        local function report(files)
            m = m + 1
            local dir = ("%s/report%d"):format(root, m)
            os.execute(("mkdir -p '%s'"):format(dir))
            writeFile(dir .. "/lua.sh", VALIDATOR)
            os.execute(("chmod +x '%s/lua.sh'"):format(dir))
            for name, text in pairs(files) do writeFile(dir .. "/" .. name, text) end
            writeFile(dir .. "/VALIDATION.md", "the committed report\n")
            local code, out = run(("%s --no-print-directory report LUA='%s/lua.sh' REPORT='%s/VALIDATION.md'")
                :format(MAKE, dir, dir))
            return code, out, readFile(dir .. "/VALIDATION.md"), readFile(dir .. "/calls")
        end

        it("writes the report of the validator; routes with errors (exit 1) do not fail it", function()
            local code, out, text, calls = report({ text = "a new report\n" })
            assert.equal(0, code, out)
            assert.equal("a new report\n", text)
            assert.matches("^tools/validate_routes%.lua %-q %-%-markdown %S+\n$", calls)
            assert.matches("report: %S+/VALIDATION%.md written\n", out)
            code, out, text = report({ text = "a report with errors\n", status = "1" })
            assert.equal(0, code, out)
            assert.equal("a report with errors\n", text)
        end)

        it("fails and keeps the old report when the validator wrote none (a crash is exit 1 too)", function()
            local code, out, text = report({ status = "1" })
            assert.is_true(code ~= 0, out)
            assert.equal("the committed report\n", text)
            assert.matches("report: the validator wrote no report %(exit status 1%): %S+/VALIDATION%.md is unchanged", out)
            -- no report and exit 0 is no success either
            code, out, text = report({})
            assert.is_true(code ~= 0, out)
            assert.equal("the committed report\n", text)
            -- an empty report is none
            code, out, text = report({ text = "" })
            assert.is_true(code ~= 0, out)
            assert.equal("the committed report\n", text)
        end)

        it("fails on any other exit status of the validator (usage error, signal)", function()
            local code, out, text = report({ text = "half a report\n", status = "2" })
            assert.is_true(code ~= 0, out)
            assert.equal("the committed report\n", text)
            assert.matches("exit status 2", out)
        end)

        it("the real validator: a report generator that raises an error fails the target", function()
            -- lib.report is replaced by a module whose Markdown() raises; the validator then ends
            -- with a Lua error (exit status 1, like routes with errors) and writes nothing
            local dir = root .. "/report-crash"
            os.execute(("mkdir -p '%s'"):format(dir))
            writeFile(dir .. "/lua.sh", [[
#!/bin/sh
exec lua5.1 -e 'package.preload["lib.report"] = function()
    return { Markdown = function() error("report generator: boom") end }
end' "$@" --no-overrides tests/fixtures/validator/AdventureAtlas_FxClean
]])
            os.execute(("chmod +x '%s/lua.sh'"):format(dir))
            writeFile(dir .. "/VALIDATION.md", "the committed report\n")
            local code, out = run(("%s --no-print-directory report LUA='%s/lua.sh' REPORT='%s/VALIDATION.md'")
                :format(MAKE, dir, dir))
            assert.is_true(code ~= 0, out)
            assert.matches("report generator: boom", out)
            assert.matches("report: the validator wrote no report %(exit status 1%)", out)
            assert.equal("the committed report\n", readFile(dir .. "/VALIDATION.md"))
            -- the same wrapper without the broken module writes a report
            writeFile(dir .. "/lua.sh", "#!/bin/sh\nexec lua5.1 \"$@\" --no-overrides "
                .. "tests/fixtures/validator/AdventureAtlas_FxClean\n")
            code, out = run(("%s --no-print-directory report LUA='%s/lua.sh' REPORT='%s/VALIDATION.md'")
                :format(MAKE, dir, dir))
            assert.equal(0, code, out)
            local text = readFile(dir .. "/VALIDATION.md")
            assert.is_truthy(text:find("<!-- GENERATED by tools/validate_routes.lua", 1, true), text:sub(1, 300))
            assert.is_truthy(text:find("fx-clean", 1, true))
        end)
    end)

    describe("under an outer make (make -jN test, make check ROUTE=...)", function()
        -- what `make -j4 check ROUTE=leaked` exports to the busted it starts
        local OUTER = "MAKEFLAGS=' -j4 --jobserver-auth=3,4 -- ROUTE=leaked SYNC_ROUTES=leaked' "
            .. "MFLAGS='-j4 --jobserver-auth=3,4' MAKELEVEL=1 "

        it("the make of these cases does not inherit its flags, jobserver and variables", function()
            local code, out = run(OUTER .. makeVarCommand("ROUTE"))
            assert.equal(0, code, out)
            assert.equal(makeVar("ROUTE") .. "\n", out)
            assert.is_nil(out:find("leaked", 1, true))
            assert.is_nil(out:find("jobserver", 1, true))
            -- the default of the Makefile, as its text has it
            local default = assert(readFile("Makefile")):match("\nROUTE = ([^\n]+)\n")
            assert.equal(default, makeVar("ROUTE"))
            code, out = run(OUTER .. makeVarCommand("SYNC_ROUTES"))
            assert.equal(0, code, out)
            assert.equal(makeVar("SYNC_ROUTES") .. "\n", out)
        end)

        it("makeVar reads the last line: a warning of make above the value is not the value", function()
            -- the unprotected make does print the warning and the leaked value (what the helper avoids)
            local code, out = run(OUTER .. makeVarCommand("ROUTE"):gsub("^env .- make ", "make "))
            assert.equal(0, code, out)
            assert.matches("leaked\n$", out)
        end)
    end)

    describe("the values of the Makefile", function()
        it("SYNC_ROUTES are routes; every SYNC_MID entry names a segment each of them has", function()
            local routes = addonRoutes()
            local sync = makeVar("SYNC_ROUTES")
            assert.is_true(#sync > 0)
            for id in sync:gmatch("%S+") do
                local r = routes[id]
                assert.is_truthy(r, "SYNC_ROUTES: no route " .. id)
                for spec in makeVar("SYNC_MID"):gmatch("%S+") do
                    local level, segs = spec:match("^(%d+)/(.+)$")
                    assert.is_truthy(level, "SYNC_MID entry " .. spec)
                    local found = false
                    for seg in segs:gmatch("[^,]+") do
                        if r.segmentById[seg] then found = true end
                    end
                    assert.is_true(found, ("SYNC_MID %s: route %s has none of these segments"):format(spec, id))
                end
            end
            assert.matches("^[%d ]+$", makeVar("SYNC_LEVELS"))
            assert.matches("^[%d ]+$", makeVar("SYNC_PLUS"))
            assert.matches("^%d+$", makeVar("JOBS"))
        end)

        it("`make help` prints the target list", function()
            local code, out = run(MAKE .. " -s --no-print-directory help")
            assert.equal(0, code, out)
            for _, target in ipairs({ "make check ", "make check%-fast", "make route ROUTE=", "make simulate ",
                "make simulate%-sync ", "make simulate%-sync%-full", "make report", "make package", "JOBS=N" }) do
                assert.matches(target, out)
            end
        end)
    end)

    describe("CI workflows", function()
        it("ci.yml: one job with a 25 minute limit that runs every stage of `make check`", function()
            local ci = assert(readFile(".github/workflows/ci.yml"))
            assert.matches("\n    timeout%-minutes: 25\n", ci)
            local _, jobs = ci:gsub("\n    runs%-on: ", "")
            assert.equal(1, jobs)
            -- the prerequisites of `check`, each run by a `make ...` line of the workflow
            local prereq = assert(readFile("Makefile")):match("\ncheck: ([^\n]+)\n")
            local ran = {}
            for line in ci:gmatch("run: make ([^\n]+)") do
                for target in line:gmatch("%S+") do ran[target] = true end
            end
            local count = 0
            for target in prereq:gmatch("%S+") do
                count = count + 1
                assert.is_true(ran[target], "ci.yml does not run the `make check` stage " .. target)
            end
            assert.is_true(count >= 8)
            -- generated files are checked for freshness, the addons are packaged
            assert.is_true(ran["routedata-check"])
            assert.is_true(ran["knowledge-check"])
            assert.is_true(ran["package"])
            -- `make report` fails when the validator wrote no report (the cases above), so the step
            -- must not hide its exit status; then the committed file is compared
            assert.matches("\n          make report\n", ci)
            assert.is_nil(ci:find("make report ||", 1, true))
            assert.is_nil(ci:find("-make report", 1, true))
            assert.matches("git diff %-%-exit%-code %-%- docs/VALIDATION%.md", ci)
            assert.matches("\nREPORT = docs/VALIDATION%.md\n", assert(readFile("Makefile")))
        end)

        it("nightly.yml: simulate-sync-full on a schedule and on demand", function()
            local nightly = assert(readFile(".github/workflows/nightly.yml"))
            assert.matches("\n  schedule:\n    %- cron: ", nightly)
            assert.matches("\n  workflow_dispatch:\n", nightly)
            assert.matches("run: make simulate%-sync%-full\n", nightly)
            assert.matches("timeout%-minutes: %d+", nightly)
            -- the target exists
            assert.matches("\nsimulate%-sync%-full:\n", assert(readFile("Makefile")))
        end)
    end)
end)
