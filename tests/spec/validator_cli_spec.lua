-- Command-line behaviour of the offline tools (run as real processes):
-- tools/validate_routes.lua exit codes and report files, tools/gen_route_data.lua.

local json = require("lib.json") -- luacheck: ignore 211 (kept for symmetry with other specs)

local FX = "tests/fixtures/validator/"

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

local function readAll(path)
    local fh = assert(io.open(path, "r"))
    local s = fh:read("*a")
    fh:close()
    return s
end

describe("tools/validate_routes.lua", function()
    it("exits 0 for the clean fixture (also with --strict)", function()
        local code, out = run("lua5.1 tools/validate_routes.lua " .. FX .. "FastesBoooy_FxClean")
        assert.are.equal(0, code)
        assert.matches("0 error%(s%), 0 warning%(s%)", out)
        code = run("lua5.1 tools/validate_routes.lua --strict -q " .. FX .. "FastesBoooy_FxClean")
        assert.are.equal(0, code)
    end)

    it("exits 1 when a route has errors and prints them", function()
        local code, out = run("lua5.1 tools/validate_routes.lua " .. FX .. "FastesBoooy_FxWrongNpc")
        assert.are.equal(1, code)
        assert.matches("ERROR fx%-wrong%-npc%-01#2 %(Segments/01.lua%) %[turnin%-wrong%-npc%]", out)
    end)

    it("--strict turns warnings into failures", function()
        local code = run("lua5.1 tools/validate_routes.lua -q --ignore level-too-low " .. FX .. "FastesBoooy_FxLevelLow")
        assert.are.equal(0, code)
        code = run("lua5.1 tools/validate_routes.lua -q --strict --ignore level-too-low " .. FX .. "FastesBoooy_FxLevelLow")
        assert.are.equal(1, code)
    end)

    it("--route filters routes; --route matching nothing and unknown options exit 2", function()
        local code, out = run("lua5.1 tools/validate_routes.lua -q --route nope " .. FX .. "FastesBoooy_FxWrongNpc")
        assert.are.equal(2, code)
        assert.not_matches("fx%-wrong%-npc %[", out)
        code, out = run("lua5.1 tools/validate_routes.lua -q --route fx-clean " .. FX .. "FastesBoooy_FxClean")
        assert.are.equal(0, code)
        assert.matches("fx%-clean %[", out)
        code = run("lua5.1 tools/validate_routes.lua --definitely-not-an-option")
        assert.are.equal(2, code)
    end)

    it("writes JSON and Markdown reports", function()
        local j, md = tmpname(), tmpname()
        local code = run(("lua5.1 tools/validate_routes.lua -q --json %s --markdown %s %sFastesBoooy_FxClean %sFastesBoooy_FxChain")
            :format(j, md, FX, FX))
        assert.are.equal(1, code)
        local js = readAll(j)
        assert.matches('"route": "fx%-clean"', js)
        assert.matches('"code": "accept%-exclusive"', js)
        assert.matches('"totals"', js)
        local m = readAll(md)
        assert.matches("^# Отчёт валидатора маршрутов", m)
        assert.matches("## fx%-clean", m)
        assert.matches("| ERROR | fx%-chain%-01#2", m)
        os.remove(j)
        os.remove(md)
    end)

    it("produces byte-identical reports on repeated runs", function()
        local a, b = tmpname(), tmpname()
        run(("lua5.1 tools/validate_routes.lua -q --markdown %s %sFastesBoooy_FxClean"):format(a, FX))
        run(("lua5.1 tools/validate_routes.lua -q --markdown %s %sFastesBoooy_FxClean"):format(b, FX))
        assert.are.equal(readAll(a), readAll(b))
        os.remove(a)
        os.remove(b)
    end)
end)

describe("tools/gen_route_data.lua", function()
    it("the committed fixture Data.lua is up to date (--check)", function()
        local code, out = run("lua5.1 tools/gen_route_data.lua --check " .. FX .. "FastesBoooy_FxClean")
        assert.are.equal(0, code, out)
        assert.matches("up to date", out)
    end)

    it("loads every file of a module with one shared addon table", function()
        local code, out = run("lua5.1 tools/gen_route_data.lua --stdout " .. FX .. "FastesBoooy_FxNs")
        assert.are.equal(0, code, out)
        assert.matches('FastesBoooy.AddRouteData%("fx%-ns", {', out)
        assert.matches('%[363%] = "Rude Awakening",', out)
        code, out = run("lua5.1 tools/validate_routes.lua -q " .. FX .. "FastesBoooy_FxNs")
        assert.are.equal(0, code, out)
        assert.matches("0 error%(s%), 0 warning%(s%)", out)
    end)

    it("fails without writing anything when the module has load / schema errors", function()
        local code, out = run("lua5.1 tools/gen_route_data.lua --stdout " .. FX .. "FastesBoooy_FxSchema")
        assert.are.equal(1, code)
        assert.not_matches("AddRouteData", out)
        assert.matches("Data.lua not generated", out)
    end)

    it("renders enUS names for every referenced quest and NPC", function()
        local code, out = run("lua5.1 tools/gen_route_data.lua --stdout " .. FX .. "FastesBoooy_FxClean")
        assert.are.equal(0, code)
        assert.matches('FastesBoooy.AddRouteData%("fx%-clean", {', out)
        assert.matches('%[363%] = "Rude Awakening",', out)
        assert.matches('%[244808%] = "Aramis Hammerhand",', out)
        -- the generated file is a valid route-module chunk
        local chunk = assert(loadstring(out))
        local captured
        setfenv(chunk, { FastesBoooy = { AddRouteData = function(id, d) captured = { id = id, data = d } end } })
        chunk()
        assert.are.equal("fx-clean", captured.id)
        assert.are.equal("Shadow Priest Sarvis", captured.data.npcs[1569])
    end)
end)
