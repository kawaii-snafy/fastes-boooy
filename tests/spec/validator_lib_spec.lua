-- Unit tests for the offline tooling libraries: tools/lib/fbdb.lua (masks, XP rules),
-- tools/lib/route_loader.lua (TOC, sandbox), tools/lib/json.lua, validator profiles,
-- and the structure of the generated DB snapshot.

local DB = require("lib.fbdb")
local Loader = require("lib.route_loader")
local V = require("lib.validator")
local json = require("lib.json")

local db

describe("fbdb", function()
    setup(function()
        db = DB.Load("tools/data/forever_db.lua")
    end)

    describe("masks", function()
        it("tests bits above 32 without bit.band", function()
            local SKY_H, SKY_A = 2 ^ 33, 2 ^ 32
            assert.is_true(DB.HasBit(8589934770, SKY_H))      -- ALL_HORDE
            assert.is_false(DB.HasBit(8589934770, SKY_A))
            assert.is_true(DB.HasBit(4294967373, SKY_A))      -- ALL_ALLIANCE
            assert.is_true(DB.HasBit(8589934770, 16))         -- Undead
            assert.is_false(DB.HasBit(4294967373, 16))
            assert.is_false(DB.HasBit(0, 16))
            assert.is_true(DB.MaskIntersects(8589934592, 8589934770))
            assert.is_false(DB.MaskIntersects(8589934592, 4294967373))
            assert.are.equal(8589934592 + 16, DB.MaskOr(8589934592, 16))
        end)

        it("maps raceFile to race bits (Undead = Scourge, Skyborne by faction)", function()
            assert.are.equal(16, DB.RaceMask(db, "Scourge", "Horde"))
            assert.are.equal(2 ^ 33, DB.RaceMask(db, "Skyborne", "Horde"))
            assert.are.equal(2 ^ 32, DB.RaceMask(db, "Skyborne", "Alliance"))
            assert.is_nil(DB.RaceMask(db, "Undead", "Horde"))
            assert.are.equal(2, DB.ClassMask(db, "PALADIN"))
            assert.are.equal(1024, DB.ClassMask(db, "DRUID"))
            assert.are.equal("H", DB.Side(db, 16))
            assert.are.equal("A", DB.Side(db, 4294967373))
            assert.are.equal("AH", DB.Side(db, 0))
        end)
    end)

    describe("XP rules", function()
        it("uses the Classic-identical level table", function()
            assert.are.equal(400, DB.XpToLevel(db, 1))
            assert.are.equal(209800, DB.XpToLevel(db, 59))
            assert.are.equal(215600, DB.CumXp(db, 22))
            assert.are.equal(4084700, DB.CumXp(db, 60))
        end)

        it("applies the quest level-difference penalty and rounding", function()
            assert.are.equal(1000, DB.QuestXp(db, 1000, 10, 15))   -- +5: full
            assert.are.equal(800, DB.QuestXp(db, 1000, 10, 16))    -- +6: 80%
            assert.are.equal(600, DB.QuestXp(db, 1000, 10, 17))
            assert.are.equal(400, DB.QuestXp(db, 1000, 10, 18))
            assert.are.equal(200, DB.QuestXp(db, 1000, 10, 19))
            assert.are.equal(100, DB.QuestXp(db, 1000, 10, 25))    -- >= +10: 10%
            assert.are.equal(15, DB.QuestXp(db, 170, 2, 12))       -- 17 -> rounded to 5
            assert.are.equal(0, DB.QuestXp(db, 1000, 60, 60))      -- max level
            assert.are.equal(1050, DB.RoundQuestXp(1037))
            assert.are.equal(675, DB.RoundQuestXp(680))
        end)

        it("estimates mob XP (Classic formula, grey mobs, elites, Forever green penalty)", function()
            assert.are.equal(50, DB.MobXp(db, 1, 1, 0))
            assert.are.equal(55, DB.MobXp(db, 2, 2, 0))
            assert.are.equal(57, DB.MobXp(db, 2, 3, 0))            -- +1 level: +5% (57.75)
            assert.are.equal(110, DB.MobXp(db, 2, 2, 1))           -- elite x2
            assert.are.equal(0, DB.MobXp(db, 20, 13, 0))           -- grey (20 - 2 - 5 = 13)
            local classic = (5 * 10 + 45) * (1 - 2 / 7)
            local forever = DB.MobXp(db, 10, 8, 0)
            assert.is_true(forever < classic and forever >= math.floor(classic * 0.8))
        end)

        it("levels up a state", function()
            local st = { level = 1, xp = 0 }
            assert.are.equal(1, DB.AddXp(db, st, 450))
            assert.are.same({ level = 2, xp = 50 }, st)
            assert.are.equal(2, DB.AddXp(db, st, 850 + 1400 + 10))
            assert.are.same({ level = 4, xp = 10 }, st)
            assert.is_true(math.abs(DB.LevelValue(db, st) - (4 + 10 / 2100)) < 1e-9)
        end)

        it("estimates unknown quest XP from quests of the same level", function()
            local est = DB.EstimateQuestXp(db, 10)
            assert.is_true(est > 100 and est < 2000)
        end)
    end)

    describe("snapshot", function()
        it("has provenance and Forever facts", function()
            assert.are.same({ "1.60.1", "70862" }, db.meta.build)
            assert.are.equal(16001, db.meta.interface)
            assert.are.equal("2026-11-07", db.meta.generated)
            assert.are.equal(40, db.questLogSize)
            assert.are.equal(60, db.levelCap)
            assert.are.equal("Zephras Isle", db.zones[2521].name)
            assert.are.equal(1420, db.areaToUiMap[154])            -- Deathknell -> Tirisfal Glades
            assert.are.equal(1412, db.areaToUiMap[215])            -- Mulgore
        end)

        it("stores quests with chains, objectives and XP", function()
            local q = db.quests[364]
            assert.are.equal("The Mindless Ones", q.name)
            assert.are.same({ 1569 }, q.start.npcs)
            assert.are.same({ 363 }, q.breadcrumbs)
            assert.are.same({ { 1501, 5 }, { 1502, 5 } }, q.objectives.creatures) -- Forever counts (WCLBox)
            assert.are.equal(170, q.xp)
            assert.are.equal(364, db.quests[363].breadcrumbFor)
            assert.are.same({ 364 }, db.quests[3901].preSingle)
            -- Forever-new Undead paladin quest: XP unknown offline
            assert.is_nil(db.quests[98601].xp)
            assert.are.equal("H", db.quests[98601].side)
            -- class-dependent Horde dynamic override
            assert.are.equal(8376, DB.Quest(db, 8315, "PALADIN").next)
            assert.are.equal(8382, DB.Quest(db, 8315, "DRUID").next)
        end)

        it("stores NPC spawns in uiMap space and service flags", function()
            local n = db.npcs[1569]
            assert.are.same({ { 30.84, 66.2 } }, n.spawns[1420])
            assert.are.equal("H", n.faction)
            assert.is_true(db.npcs[244808].flags.trainer)
            assert.are.equal("Paladin Trainer", db.npcs[244808].sub)
            assert.is_true(db.npcs[5688].flags.innkeeper)
            assert.is_true(db.npcs[2226].flags.flightmaster)
            local d = DB.Nearest(n.spawns, 1420, 30.84, 69.2)
            assert.is_true(math.abs(d - 3) < 1e-9)
            assert.is_nil(DB.Nearest(n.spawns, 1458, 50, 50))
        end)

        it("indexes quests and NPCs outside the scope", function()
            local b = DB.QuestBrief(db, 1097) -- Elmore's Task (Stormwind)
            assert.is_not_nil(b)
            assert.is_false(b.full)
            assert.are.equal("A", DB.Side(db, b.races))
            assert.is_nil(DB.QuestBrief(db, 999999))
            assert.is_not_nil(DB.NpcBrief(db, 1))
        end)
    end)
end)

describe("route_loader", function()
    local S = Loader.LoadSchema(".")

    it("loads the real Schema contract", function()
        assert.are.equal(1, S.API_VERSION)
        assert.is_function(S.NormalizeStep)
    end)

    it("parses TOC files (meta, backslashes, comments)", function()
        local toc = Loader.ParseToc("tests/fixtures/validator/FastesBoooy_FxClean/FastesBoooy_FxClean.toc")
        assert.are.equal("16001", toc.meta.Interface)
        assert.are.equal("FastesBoooy", toc.meta.Dependencies)
        assert.are.same({ "Route.lua", "Data.lua", "Segments/01_Deathknell.lua", "Segments/02_Brill.lua" }, toc.files)
    end)

    it("loads a module in a sandbox and keeps file locations", function()
        local mod = Loader.LoadModule("tests/fixtures/validator/FastesBoooy_FxClean", { schema = S })
        assert.are.same({}, mod.errors)
        assert.are.equal(1, #mod.routes)
        local route = mod.routes[1]
        assert.are.equal("fx-clean", route.id)
        assert.are.equal("Route.lua", route.file)
        assert.are.equal(2, #route.segments)
        assert.are.equal("Segments/02_Brill.lua", route.segments[2].file)
        assert.are.equal("Segments/01_Deathknell.lua", route.steps[1].file)
        assert.are.equal("Rude Awakening", mod.data["fx-clean"].quests[363])
    end)

    it("sandboxed files cannot reach io/os/require", function()
        local env = Loader.baseEnv()
        assert.is_nil(env.io)
        assert.is_nil(env.os)
        assert.is_nil(env.require)
        assert.is_nil(env.loadstring)
        assert.is_nil(env.dofile)
    end)
end)

describe("validator profiles", function()
    it("expands race x class and derives the faction", function()
        local route = { races = { Scourge = true }, classes = { PALADIN = true }, faction = "Horde" }
        assert.are.same({ { race = "Scourge", class = "PALADIN", faction = "Horde" } }, V.Profiles(route))
        local multi = { races = { Tauren = true, Scourge = true }, classes = { DRUID = true } }
        local p = V.Profiles(multi)
        assert.are.equal(2, #p)
        assert.are.equal("Scourge", p[1].race)
        assert.are.equal("Horde", p[1].faction)
        local o = V.Profiles(route, { race = "Skyborne", class = "DRUID" })
        assert.are.same({ { race = "Skyborne", class = "DRUID", faction = "Horde" } }, o)
    end)

    it("parses CLI arguments", function()
        local o = V.ParseArgs({ "--route", "x", "--profile", "race=Scourge,class=PALADIN", "--strict",
            "--ignore", "xp-unknown,quest-carried", "-v", "dir1" })
        assert.are.equal("x", o.route)
        assert.are.same({ race = "Scourge", class = "PALADIN" }, o.profile)
        assert.is_true(o.strict)
        assert.is_true(o.ignore["xp-unknown"] and o.ignore["quest-carried"])
        assert.are.same({ "dir1" }, o.dirs)
        assert.has_error(function() V.ParseArgs({ "--profile", "foo=bar" }) end)
        assert.has_error(function() V.ParseArgs({ "--nope" }) end)
    end)
end)

describe("json", function()
    it("encodes deterministically with sorted keys", function()
        assert.are.equal('{"a":[1,2],"b":{"c":"x\\"y"},"e":[],"o":{}}',
            json.encode({ b = { c = 'x"y' }, a = { 1, 2 }, e = {}, o = json.object({}) }))
        assert.are.equal("8589934770", json.encode(8589934770))
        assert.are.equal("0.5", json.encode(0.5))
    end)
end)
