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
        local code, out = run("lua5.1 tools/validate_routes.lua --no-overrides " .. FX .. "AdventureAtlas_FxClean")
        assert.are.equal(0, code)
        assert.matches("0 error%(s%), 0 warning%(s%)", out)
        code = run("lua5.1 tools/validate_routes.lua --no-overrides --strict -q " .. FX .. "AdventureAtlas_FxClean")
        assert.are.equal(0, code)
    end)

    it("exits 1 when a route has errors and prints them", function()
        local code, out = run("lua5.1 tools/validate_routes.lua --no-overrides " .. FX .. "AdventureAtlas_FxWrongNpc")
        assert.are.equal(1, code)
        assert.matches("ERROR fx%-wrong%-npc%-01#2 %(Segments/01.lua%) %[turnin%-wrong%-npc%]", out)
    end)

    it("--strict turns warnings into failures", function()
        local code = run("lua5.1 tools/validate_routes.lua --no-overrides -q --ignore level-too-low " .. FX .. "AdventureAtlas_FxLevelLow")
        assert.are.equal(0, code)
        code = run("lua5.1 tools/validate_routes.lua --no-overrides -q --strict --ignore level-too-low "
            .. FX .. "AdventureAtlas_FxLevelLow")
        assert.are.equal(1, code)
    end)

    it("--route filters routes; --route matching nothing and unknown options exit 2", function()
        local code, out = run("lua5.1 tools/validate_routes.lua --no-overrides -q --route nope " .. FX .. "AdventureAtlas_FxWrongNpc")
        assert.are.equal(2, code)
        assert.not_matches("fx%-wrong%-npc %[", out)
        code, out = run("lua5.1 tools/validate_routes.lua --no-overrides -q --route fx-clean " .. FX .. "AdventureAtlas_FxClean")
        assert.are.equal(0, code)
        assert.matches("fx%-clean %[", out)
        code = run("lua5.1 tools/validate_routes.lua --no-overrides --definitely-not-an-option")
        assert.are.equal(2, code)
    end)

    it("writes JSON and Markdown reports", function()
        local j, md = tmpname(), tmpname()
        local code = run(("lua5.1 tools/validate_routes.lua --no-overrides -q --json %s --markdown %s %sAdventureAtlas_FxClean "
            .. "%sAdventureAtlas_FxChain"):format(j, md, FX, FX))
        assert.are.equal(1, code)
        local js = readAll(j)
        assert.matches('"route": "fx%-clean"', js)
        assert.matches('"code": "accept%-exclusive"', js)
        assert.matches('"totals"', js)
        local m = readAll(md)
        assert.matches("^# Отчёт валидатора маршрутов", m)
        assert.matches("## fx%-clean", m)
        assert.matches("| ERROR | fx%-chain%-01#2", m)
        -- the static checklist README.md points to
        assert.matches("## Что подтверждается только в игре", m)
        assert.matches("Автоматизация без аппаратного события", m)
        os.remove(j)
        os.remove(md)
    end)

    it("prints the grind report; --incidental-pct takes a percent 0..100", function()
        local code, out = run("lua5.1 tools/validate_routes.lua --no-overrides " .. FX .. "AdventureAtlas_FxClean")
        assert.are.equal(0, code, out)
        assert.matches("\n  grind kills: %d+ %(worst case %d+%); worst case = 0 optional step%(s%) not done", out)
        assert.matches("\n  grind kills band: incidental kills 0%% %-> %d+ %(worst case %d+%), 15%% of quest XP %-> %d+", out)
        assert.matches("\n  grind kills per segment ", out)
        assert.matches("\n  gate +kills +worst +%+15%% +worst%+15%% +step\n", out)
        code, out = run("lua5.1 tools/validate_routes.lua --no-overrides --incidental-pct 15 " .. FX .. "AdventureAtlas_FxClean")
        assert.are.equal(0, code, out)
        assert.matches("with incidental kills 15%% of quest XP %(%+%d+ XP%)", out)
        -- -q stays the per-route result lines only
        code, out = run("lua5.1 tools/validate_routes.lua --no-overrides -q " .. FX .. "AdventureAtlas_FxClean")
        assert.are.equal(0, code, out)
        assert.not_matches("grind kills", out)
        for _, bad in ipairs({ "abc", "-1", "101" }) do
            code, out = run("lua5.1 tools/validate_routes.lua --no-overrides --incidental-pct " .. bad .. " " .. FX
                .. "AdventureAtlas_FxClean")
            assert.are.equal(2, code, out)
            assert.matches("bad %-%-incidental%-pct", out)
        end
    end)

    it("produces byte-identical reports on repeated runs", function()
        local a, b = tmpname(), tmpname()
        run(("lua5.1 tools/validate_routes.lua --no-overrides -q --markdown %s %sAdventureAtlas_FxClean"):format(a, FX))
        run(("lua5.1 tools/validate_routes.lua --no-overrides -q --markdown %s %sAdventureAtlas_FxClean"):format(b, FX))
        assert.are.equal(readAll(a), readAll(b))
        os.remove(a)
        os.remove(b)
    end)
end)

describe("tools/gen_route_data.lua", function()
    it("the committed fixture Data.lua is up to date (--check)", function()
        local code, out = run("lua5.1 tools/gen_route_data.lua --no-overrides --check " .. FX .. "AdventureAtlas_FxClean")
        assert.are.equal(0, code, out)
        assert.matches("up to date", out)
    end)

    it("loads every file of a module with one shared addon table", function()
        local code, out = run("lua5.1 tools/gen_route_data.lua --no-overrides --stdout " .. FX .. "AdventureAtlas_FxNs")
        assert.are.equal(0, code, out)
        assert.matches('AdventureAtlas.AddRouteData%("fx%-ns", {', out)
        assert.matches('%[363%] = "Rude Awakening",', out)
        code, out = run("lua5.1 tools/validate_routes.lua --no-overrides -q " .. FX .. "AdventureAtlas_FxNs")
        assert.are.equal(0, code, out)
        assert.matches("0 error%(s%), 0 warning%(s%)", out)
    end)

    it("fails without writing anything when the module has load / schema errors", function()
        local code, out = run("lua5.1 tools/gen_route_data.lua --no-overrides --stdout " .. FX .. "AdventureAtlas_FxSchema")
        assert.are.equal(1, code)
        assert.not_matches("AddRouteData", out)
        assert.matches("Data.lua not generated", out)
    end)

    it("renders enUS names for every referenced quest and NPC", function()
        local code, out = run("lua5.1 tools/gen_route_data.lua --no-overrides --stdout " .. FX .. "AdventureAtlas_FxClean")
        assert.are.equal(0, code)
        assert.matches('AdventureAtlas.AddRouteData%("fx%-clean", {', out)
        assert.matches('%[363%] = "Rude Awakening",', out)
        assert.matches('%[244808%] = "Aramis Hammerhand",', out)
        -- the generated file is a valid route-module chunk
        local chunk = assert(loadstring(out))
        local captured
        setfenv(chunk, { AdventureAtlas = { AddRouteData = function(id, d) captured = { id = id, data = d } end } })
        chunk()
        assert.are.equal("fx-clean", captured.id)
        assert.are.equal("Shadow Priest Sarvis", captured.data.npcs[1569])
        -- places of fp / fly / sethearth / hearth: AreaTable id (client-localized in game) + ruRU name
        assert.are.same({ area = 159, en = "Brill", ru = "Брилл" }, captured.data.places.Brill)
    end)

    it("reports places with neither an area id nor a ruRU name and leaves them out", function()
        local Gen = require("gen_route_data")
        local list, unknown = Gen.Places({ places = { ["Brill"] = true, ["Nowhere Town"] = true, ["Valanaar"] = true } },
            { Brill = 159 })
        assert.are.same({ { name = "Brill", area = 159, ru = "Брилл" }, { name = "Valanaar", ru = "Валанаар" } }, list)
        assert.are.same({ "Nowhere Town" }, unknown)
    end)
end)
