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
            -- Forever counts: Wowhead Forever "Requirements" (WCLBox goals say 5 + 5, its own text 8 + 8)
            assert.are.same({ { 1501, 8 }, { 1502, 8 } }, q.objectives.creatures)
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

        it("keeps non-slay objective icons (talk / interact / event)", function()
            local ic = db.enums.iconTypes
            assert.are.equal(5, ic.ICON_TYPE_TALK)
            assert.are.equal(3, ic.ICON_TYPE_EVENT)
            assert.are.equal(17, ic.ICON_TYPE_INTERACT)
            local talk = db.quests[92514].objectives.creatures
            assert.are.equal(251902, talk[1][1])
            assert.is_nil(talk[1][2])
            assert.are.equal(ic.ICON_TYPE_TALK, talk[1].icon)
            local heal = db.quests[90902].objectives.creatures[1]
            assert.are.same({ 259377, 5 }, { heal[1], heal[2] })
            assert.are.equal(ic.ICON_TYPE_INTERACT, heal.icon)
            assert.are.equal(ic.ICON_TYPE_EVENT, db.quests[98389].objectives.killCredit[1].icon)
            assert.is_nil(db.quests[364].objectives.creatures[1].icon) -- slay: no icon stored
            assert.is_true(db.quests[870].objectives.event)              -- exploration
            assert.is_true(DB.IsQuestNpc(db, 1569))
            assert.is_false(DB.IsQuestNpc(db, 1501))
        end)

        it("includes transport NPCs (zeppelins, boats, skycutter, landings)", function()
            local function t(id) return db.npcs[id] and db.npcs[id].transport end
            assert.are.equal("zeppelin", t(9566))   -- Zapetta, Tirisfal tower (UC <-> Orgrimmar)
            assert.are.equal("zeppelin", t(9564))   -- Frezza, Durotar tower
            assert.are.same({ { 60.74, 58.87 } }, db.npcs[9566].spawns[1420])
            assert.are.same({ { 50.82, 13.54 } }, db.npcs[9564].spawns[1411])
            assert.are.equal("zeppelin", t(3150))   -- Hin Denburg (UC <-> Grom'gol)
            assert.are.equal("zeppelin", t(3149))   -- Nez'raz, Grom'gol (outside the scope areas)
            assert.are.equal("boat", t(9558))       -- Grimble, Ratchet
            assert.are.equal("skycutter", t(275270)) -- Windshapers Dockmaster, Valanaar
            assert.is_not_nil(db.npcs[275270].spawns[2521])
            assert.are.equal("landing", t(264287))  -- Galestrider Handler, Skywatcher Plateau (Mulgore)
            assert.are.equal("landing", t(259119))  -- Alaana Stormwalker (also a quest giver)
            assert.is_nil(t(1569))
            assert.is_nil(db.npcIndex[9566])
        end)

        it("covers Horde leveling 22-60 (all Eastern Kingdoms / Kalimdor zones, 5-man dungeons)", function()
            local tn = db.quests[4767] -- Wind Rider (Thousand Needles, Freewind Post)
            assert.are.equal("Wind Rider", tn.name)
            assert.are.equal(29, tn.level)
            assert.are.equal("H", tn.side)
            assert.are.equal(1441, tn.uiMap)
            assert.are.same({ 10377 }, tn.start.npcs)
            assert.is_not_nil(db.quests[98070])                 -- Forever-new Thousand Needles quest
            assert.are.equal("new", db.quests[98070].status)
            assert.are.equal(1717, db.quests[1109].zone)         -- Going, Going, Guano! (Razorfen Kraul)
            assert.are.equal("H", db.quests[1048].side)          -- Into The Scarlet Monastery
            assert.are.equal(1417, db.quests[3380].zone)         -- The Sunken Temple (dungeon quest)
            assert.are.equal(50, db.quests[2770].level)          -- Gahz'rilla (Zul'Farrak)
            assert.is_true(db.zones[1441].scope)
            assert.is_true(db.zones[1434].scope)                 -- Stranglethorn Vale
            assert.are.equal("Thousand Needles", db.scopeAreas[400])
            assert.are.equal("Tirisfal Glades", db.coreAreas[85])
            assert.are.equal("Freewind Post", db.areaNames[484])
            -- raid / battleground / holiday content stays in the brief index
            assert.is_nil(db.quests[7848])                       -- Attunement to the Core (Molten Core)
            assert.is_false(DB.QuestBrief(db, 7848).full)
            assert.is_nil(db.quests[8201])                       -- Zul'Gurub
            assert.is_not_nil(DB.QuestBrief(db, 8201))
        end)

        it("includes Horde/neutral service NPCs everywhere, not Alliance ones outside the core", function()
            local function flags(id) return db.npcs[id] and db.npcs[id].flags or {} end
            assert.is_true(flags(4317).flightmaster)              -- Nyse, Freewind Post
            assert.is_true(flags(2851).flightmaster)              -- Urda, Hammerfall
            assert.is_true(flags(8020).flightmaster)              -- Shyn, Camp Mojache
            assert.is_true(flags(1387).flightmaster)              -- Thysta, Grom'gol
            -- Forever-new Riverglades flight master without npcFlags: inferred from the subName
            assert.is_true(flags(255993).flightmaster)
            assert.are.equal("subName", db.npcs[255993].flagsSrc)
            assert.are.same({ { 59.58, 45.13 } }, db.npcs[255993].spawns[2548])
            assert.is_nil(db.npcs[4317].flagsSrc)
            -- Alliance flight master in Arathi (outside the core areas): brief index only
            assert.is_nil(db.npcs[2835])
            assert.is_not_nil(DB.NpcBrief(db, 2835))
        end)

        it("knows the world size of every zone map, Forever-new maps included", function()
            assert.are.same({ 6381.2, 4254.2 }, db.zones[1434].size) -- conversion.json bounds
            assert.is_nil(db.zones[1434].sizeSrc)
            assert.are.same({ 4850, 3233.3 }, db.zones[2548].size)   -- Riverglades: WCLBox map pixels
            assert.are.equal("wclbox-map", db.zones[2548].sizeSrc)
            -- Zephras Isle stays unsized: the validator fixtures use it as the map-percent fallback
            assert.is_nil(db.zones[2521].size)
            for _, um in ipairs({ 1411, 1416, 1417, 1418, 1419, 1422, 1423, 1425, 1427, 1428, 1435, 1441,
                1443, 1444, 1445, 1446, 1447, 1448, 1449, 1451, 1452, 2482, 2524, 2652 }) do
                assert.is_not_nil(db.zones[um].size, "size of uiMap " .. um)
            end
        end)

        it("keeps thinned spawn lists within the documented grid error", function()
            local c = db.meta.counts
            assert.is_true(c["spawnsThinned.maps"] > 0)
            assert.is_true(c["spawnsThinned.worstMapUnits"] <= 2 * math.sqrt(2))
            assert.is_true(c["spawnsThinned.worstYards"] < 300)
        end)

        it("fills the research-input gaps of build_db_snapshot.py SUPPLEMENT_* tables", function()
            local c = db.meta.counts
            assert.are.equal(3, c["supplements.questEnders"])
            assert.are.equal(1, c["supplements.npcFlagsCleared"])
            assert.are.equal(1, c["supplements.npcSpawns"])
            assert.are.equal(1, c["supplements.objects"])
            -- 97539 Silky Sutures: turned in to its giver Doctor Gregory Victor
            assert.are.same({ 12920 }, db.quests[97539].finish.npcs)
            -- 11741 Dredge Crusher is a kill target of 8281, no quest giver
            assert.is_nil(db.npcs[11741].flags)
            assert.is_false(DB.IsQuestNpc(db, 11741))
            -- Sulhasa (98093) spawns in the southern Barrens; the Stolen Freewind Supplies containers
            assert.are.same({ { 47.9, 77.6 } }, db.npcs[14242].spawns[1413])
            assert.are.equal("Stolen Freewind Supplies", db.objects[670338].name)
            assert.are.equal(16, #db.objects[670338].spawns[1441])
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
        local toc = Loader.ParseToc("tests/fixtures/validator/AdventureAtlas_FxClean/AdventureAtlas_FxClean.toc")
        assert.are.equal("16001", toc.meta.Interface)
        assert.are.equal("AdventureAtlas", toc.meta.Dependencies)
        assert.are.same({ "Route.lua", "Data.lua", "Segments/01_Deathknell.lua", "Segments/02_Brill.lua" }, toc.files)
    end)

    it("loads a module in a sandbox and keeps file locations", function()
        local mod = Loader.LoadModule("tests/fixtures/validator/AdventureAtlas_FxClean", { schema = S })
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

    it("parses the file filter, the gates and the report options", function()
        local o = V.ParseArgs({ "--skip", "Classes/*", "--skip", "Races\\*", "--keep", "Classes/Mage.lua", "--own",
            "Classes/Mage.lua", "--route", "orc-*,troll-mage", "--end-level", "--summary", "--levels", "--grind-until",
            "h-18", "--max-grind-until", "h-18-stonetalon-ashenvale=120/200", "--baseline", "b.json", "--write-baseline",
            "w.json", "--no-overrides", "--overrides", "dir" })
        assert.are.same({ "Classes/*", "Races/*" }, o.skip)
        assert.are.same({ "Classes/Mage.lua" }, o.keep)
        assert.are.same({ "Classes/Mage.lua" }, o.own)
        assert.are.equal("orc-*,troll-mage", o.route)
        assert.is_true(o.endLevel and o.summary and o.levels and o.noOverrides)
        assert.are.equal("h-18", o.grindUntil)
        assert.are.same({ segment = "h-18-stonetalon-ashenvale", kills = 120, worst = 200 }, o.maxGrindUntil)
        assert.are.equal("b.json", o.baseline)
        assert.are.equal("w.json", o.writeBaseline)
        assert.are.equal("dir", o.overrides)
        -- nothing given: no filter, every file is own
        o = V.ParseArgs({})
        assert.is_nil(o.skip)
        assert.is_nil(o.own)
        assert.has_error(function() V.ParseArgs({ "--max-grind-until", "seg=5" }) end)
        assert.has_error(function() V.ParseArgs({ "--max-grind-until", "seg" }) end)
        assert.has_error(function() V.ParseArgs({ "--skip" }) end)
        assert.has_error(function() V.ParseArgs({ "--own", "" }) end)
        assert.has_error(function() V.ParseArgs({ "--route", "," }) end)
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
