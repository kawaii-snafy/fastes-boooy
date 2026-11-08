-- tools/simulate_routes.lua: the CLI plays the core test route to the end, and a route
-- that cannot be followed fails with a clear message and exit status 1.

local function run(args)
    local p = assert(io.popen("lua5.1 tools/simulate_routes.lua " .. args .. " 2>&1; echo \"EXIT=$?\""))
    local out = p:read("*a")
    p:close()
    local code = tonumber(out:match("EXIT=(%d+)%s*$"))
    return code, out
end

local root

local BROKEN = {
    ["FastesBoooy_Broken/FastesBoooy_Broken.toc"] = "## Interface: 16001\n## Dependencies: FastesBoooy\nRoute.lua\n",
    ["FastesBoooy_Broken/Route.lua"] = [[
FastesBoooy.RegisterRoute({ api = 1, id = "broken", title = "Broken", faction = "Horde",
    races = { "Scourge" }, classes = { "PALADIN" }, levels = { 1, 5 } })
FastesBoooy.AddSegment("broken", { id = "b1", title = "B1", steps = {
    { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
    { turnin = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
} })
]],
    ["FastesBoooy_Sky/FastesBoooy_Sky.toc"] = "## Interface: 16001\n## Dependencies: FastesBoooy\nRoute.lua\n",
    ["FastesBoooy_Sky/Route.lua"] = [[
FastesBoooy.RegisterRoute({ api = 1, id = "sky", title = "Sky", faction = "Horde",
    races = { "Skyborne" }, classes = { "DRUID" }, levels = { 1, 5 } })
FastesBoooy.AddSegment("sky", { id = "s1", title = "S1", steps = {
    { accept = 90001, npc = 100, at = { 2521, 40, 40 } },
    { turnin = 90001, accept = 90002, npc = 100, at = { 2521, 40, 40 } },
    { go = true, at = { 2521, 60, 60 } },
    { turnin = 90002, npc = 101, at = { 2521, 60, 61 } },
} })
]],
    -- 870 "The Forgotten Pools": exploration only (DB objectives.event) -- must not be complete on accept
    ["FastesBoooy_Event/FastesBoooy_Event.toc"] = "## Interface: 16001\n## Dependencies: FastesBoooy\nRoute.lua\n",
    ["FastesBoooy_Event/Route.lua"] = [[
FastesBoooy.RegisterRoute({ api = 1, id = "event", title = "Event", faction = "Horde",
    races = { "Orc" }, classes = { "WARRIOR" }, levels = { 10, 12 } })
FastesBoooy.AddSegment("event", { id = "e1", title = "E1", steps = {
    { accept = 870, npc = 3448, at = { 1413, 52.26, 31.93 } },
    { fp = "The Crossroads", npc = 3615, at = { 1413, 51.50, 30.34 } },
    { go = true, at = { 1413, 48.0, 26.0 } },
    { complete = 870, at = { 1413, 44.97, 22.56 } },
    { turnin = 870, npc = 3448, at = { 1413, 52.26, 31.93 } },
} })
]],
    -- Stranglethorn Vale (uiMap 1434) is no built-in mock map: its world size comes from the DB snapshot,
    -- so the hearth landing is checked against the step location (bb: lands there; gg: does not, its `at` is
    -- the Nesingwary camp)
    ["FastesBoooy_Hearth/FastesBoooy_Hearth.toc"] = "## Interface: 16001\n## Dependencies: FastesBoooy\nRoute.lua\n",
    ["FastesBoooy_Hearth/Route.lua"] = [[
FastesBoooy.RegisterRoute({ api = 1, id = "hearth", title = "Hearth", faction = "Horde",
    races = { "Orc" }, classes = { "WARRIOR" }, levels = { 44, 45 } })
FastesBoooy.AddSegment("hearth", { id = "h1", title = "H1", steps = {
    { id = "bind", sethearth = "Booty Bay", npc = 6807, at = { 1434, 27.04, 77.31 } },
    { go = true, at = { 1434, 32.0, 29.0 } },
    { id = "bb", hearth = "Booty Bay", at = { 1434, 27.04, 77.31 } },
    { go = true, at = { 1434, 32.0, 29.0 } },
    { id = "gg", hearth = "Booty Bay", at = { 1434, 35.6, 10.6 } },
} })
]],
    -- the paladin trainer Aramis Hammerhand 244808 also offers 90902: talking to him opens the gossip first,
    -- the automation accepts 90902 (next step, within the lookahead) and the visit is fast-forwarded
    ["FastesBoooy_Gossip/FastesBoooy_Gossip.toc"] = "## Interface: 16001\n## Dependencies: FastesBoooy\nRoute.lua\n",
    ["FastesBoooy_Gossip/Route.lua"] = [[
FastesBoooy.RegisterRoute({ api = 1, id = "gossip", title = "Gossip", faction = "Horde",
    races = { "Scourge" }, classes = { "PALADIN" }, levels = { 1, 3 } })
FastesBoooy.AddSegment("gossip", { id = "g1", title = "G1", steps = {
    { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
    { turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
    { complete = 364, at = { 1420, 32.5, 63.5 } },
    { turnin = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
    { level = 2 },
    { id = "visit", train = true, npc = 244808, at = { 1420, 31.1, 66.4 } },
    { accept = 90902, npc = 244808, at = { 1420, 31.1, 66.4 } },
} })
]],
    ["FastesBoooy_Schema/FastesBoooy_Schema.toc"] = "## Interface: 16001\nRoute.lua\n",
    ["FastesBoooy_Schema/Route.lua"] = [[
FastesBoooy.RegisterRoute({ api = 1, id = "schema", title = "S" })
FastesBoooy.AddSegment("schema", { id = "s", title = "S", steps = { { bogus = true } } })
]],
}

describe("tools/simulate_routes.lua", function()
    setup(function()
        root = os.tmpname()
        os.remove(root)
        for path, content in pairs(BROKEN) do
            os.execute(("mkdir -p '%s'"):format((root .. "/" .. path):match("^(.*)/[^/]+$")))
            local fh = assert(io.open(root .. "/" .. path, "wb"))
            fh:write(content)
            fh:close()
        end
    end)
    teardown(function() os.execute(("rm -rf '%s'"):format(root)) end)

    it("plays the core test route to the end (exit 0)", function()
        local code, out = run("--fixtures")
        assert.equal(0, code, out)
        assert.is_truthy(out:find("OK   test-route (Scourge PALADIN Horde): 26 steps", 1, true), out)
        -- the composed fixture (library segments + inserts); its library module is not simulated alone
        assert.is_truthy(out:find("OK   test-composed (Scourge PALADIN Horde): 26 steps", 1, true), out)
        assert.is_truthy(out:find("skip FastesBoooy_TestLib: library module", 1, true), out)
        assert.is_truthy(out:find("0 failed", 1, true), out)
    end)

    it("plays it in ruRU and without the DB snapshot", function()
        local code, out = run("--fixtures --route test-route --locale ruRU --no-db")
        assert.equal(0, code, out)
        assert.is_truthy(out:find("OK   test-route", 1, true), out)
    end)

    it("builds a Skyborne Horde player (raceID 96) for a Skyborne route on Zephras Isle", function()
        local code, out = run("--no-db --verbose '" .. root .. "/FastesBoooy_Sky'")
        assert.equal(0, code, out)
        assert.is_truthy(out:find("OK   sky (Skyborne DRUID Horde)", 1, true), out)
        assert.is_truthy(out:find("race Skyborne (raceID 96), class DRUID (classID 11), faction Horde", 1, true), out)
    end)

    it("keeps exploration / escort quests incomplete until the route's complete step", function()
        local code, out = run("--verbose '" .. root .. "/FastesBoooy_Event'")
        assert.equal(0, code, out)
        assert.is_truthy(out:find("OK   event (Orc WARRIOR Horde): 5 steps, 5 iterations", 1, true), out)
        assert.is_truthy(out:find("[2/5] e1:2 [fp The Crossroads]", 1, true), out)
        assert.is_truthy(out:find("[4/5] e1:4 [complete 870]", 1, true), out)
        assert.is_falsy(out:find("cursor 1 -> 5", 1, true), out)
    end)

    it("checks the hearth landing on 22-60 maps with the world size from the DB snapshot", function()
        local code, out = run("'" .. root .. "/FastesBoooy_Hearth'")
        assert.equal(0, code, out)
        assert.is_truthy(out:find("OK   hearth (Orc WARRIOR Horde): 5 steps", 1, true), out)
        assert.is_falsy(out:find("step bb [hearth Booty Bay]: the hearthstone bind point", 1, true), out)
        assert.is_truthy(out:find("step gg [hearth Booty Bay]: the hearthstone bind point (Booty Bay) is not at the "
            .. "step location", 1, true), out)
        -- without the DB snapshot the map has no world size: the landing cannot be checked
        code, out = run("--no-db '" .. root .. "/FastesBoooy_Hearth'")
        assert.equal(0, code, out)
        assert.is_truthy(out:find("step bb [hearth Booty Bay]: the hearthstone bind point", 1, true), out)
    end)

    it("talks to a service NPC that offers route quests first: a fast-forwarded visit is a warning", function()
        local code, out = run("'" .. root .. "/FastesBoooy_Gossip'")
        assert.equal(0, code, out)
        assert.is_truthy(out:find("OK   gossip (Scourge PALADIN Horde)", 1, true), out)
        assert.is_truthy(out:find("step visit [train]: fast-forwarded before its train window opened: talking to NPC "
            .. "244808", 1, true), out)
    end)

    it("fails a route that cannot be followed", function()
        local code, out = run("'" .. root .. "/FastesBoooy_Broken'")
        assert.equal(1, code, out)
        assert.is_truthy(out:find("FAIL broken (Scourge PALADIN Horde)", 1, true), out)
        assert.is_truthy(out:find("turnin 364 but the quest is not in the quest log", 1, true), out)
    end)

    it("fails a module with schema errors", function()
        local code, out = run("'" .. root .. "/FastesBoooy_Schema'")
        assert.equal(1, code, out)
        assert.is_truthy(out:find("FAIL FastesBoooy_Schema: ", 1, true), out)
        assert.is_truthy(out:find("unknown step key 'bogus'", 1, true), out)
    end)

    it("handles its options", function()
        local code, out = run("--help")
        assert.equal(0, code)
        assert.is_truthy(out:find("usage:", 1, true))
        code = run("--fixtures --route does-not-exist")
        assert.equal(1, code)
        code = run("--no-such-option")
        assert.equal(2, code)
    end)
end)
