-- FastesBoooy_Guides / Classes / Shaman.lua
--
-- Every step that exists because of the class (shaman), for all four shaman races (Orc, Troll, Tauren, Skyborne), as
-- shared inserts with class scope (step ids "sha-..."; below level 12 one group per start zone: "sha-dur-..." Durotar
-- for Orc and Troll, "sha-mul-..." Mulgore for the Tauren, "sha-zep-..." Zephras Isle for the Skyborne). Every insert
-- is anchored on a step with an explicit id of a start-zone or shared segment; the inserted steps belong to the
-- anchor's segment. Phase C of docs/dev/PLAN.md (D.5); research docs/dev/research/classes.md 5.4, 6.6.
-- Facts (NPC ids and positions, quest ids, chains, race masks, drop sources): tools/data/forever_db.lua.
-- Spell levels: classes.md 5.4 (the web list for Forever) for the key ones (Flametongue 10, Ghost Wolf 20, Totemic
-- Recall / Call of the Elements 20, Totemic Projection 22, Windfury Weapon 30, Call of the Ancestors 30, Windfury
-- Totem 32, mail 40); the others are the trainer lists of the original game and only shown as text (the core never
-- reads `spells`). CONFIRM in game.
--
-- What the class does here, speed first: the letter at level 1 (zero detour), the Earth Totem at 4 (Skyborne 3-5) and
-- the Fire Totem (Searing Totem) as key abilities with their own travel, training at stops the path makes anyway (the
-- shaman trainers of Thunder Bluff stand on Spirit Rise next to Zamah, whom the path visits at 18, 22, 24 and 27; the
-- Orgrimmar ones in the Valley of Wisdom; Haromm in Stonard), Ghost Wolf at 20 with a short detour (it pays back on
-- the long runs of 20-40), the free accept of Call of Air at 30 and three optional pieces: the first part of Call of
-- Water (2,085 XP of cheap quests), the Air turn-in at 46 and the 58 / 60 ranks after the end of the route.
--
-- Start zones (level before the first step of the insert: validator --levels of the shaman route, normal run; the worst
-- case, no optional step, is the same below 12):
--   Durotar (Orc, Troll)
--     after dur01-teeth        2.33   the letter 3089 (Orc) / 3084 (Troll) at Gornek > Shikrik (nothing to train at 2)
--     after dur01-den-4        4.68   a class-scoped level-4 gate (the simulator, quest XP only, is at 3 here);
--                                     Canaga Earthcaller: 1516 (2 Felstalker Hooves); Shikrik: training 4
--     after dur01-thazzril-2   4.90   the felstalkers by the Burning Blade Coven cave (the path goes there next)
--     after dur01-leave        5.43   1516 > 1517 > the Minor Manifestation of Earth (260 yd south of the Den) > 1518:
--                                     EARTH TOTEM (~530 yd there and back)
--     after dur02-rh-1         6.83   Swart in Razor Hill (25 yd from Turroc): training 6
--     after dur02-garthok-3    9.78   Swart: training 8 (the path passes him on the hearth visit)
--     after dur02-rh-3        10.02   Swart: training 10 + the breadcrumb 2983 (carried to Far Watch Post, PLAN.md C.2)
--   Mulgore (Tauren)
--     after mul01-hunt         3.14   the letter 3093 at Grull Hawkwind > Meela Dawnstrider
--     after mul01-ravine       4.12   Seer Ravenfeather: 1519 (2 Ritual Salves); Meela: training 4
--     after mul01-belts        5.17   the Bristleback Shamans in the ravine (the path is there)
--     after mul01-leave        6.06   1519 > 1520 > the Minor Manifestation of Earth (~490 yd east of the camp) > 1521:
--                                     EARTH TOTEM (~1,000 yd there and back)
--     after mul02-bh-1         6.89   Narm Skychaser in Bloodhoof: training 6
--     after mul02-bh-3         9.04   Narm: training 8
--     after mul02-bh-5        10.67   Narm: training 10 + the breadcrumb 2984
--     after mul03-far-watch   12.09   Call of Fire 1524 > 1527 (see below): FIRE TOTEM at 12.46
--   Zephras Isle (Skyborne)
--     after sd01-rorian        3.02   the letter 92484 at Rorian > Windshaper Boro; a class-scoped level-3 gate; 92466
--     after sd01-agitators     3.79   the Signet of Akir from the Al'Aketh Converts of the agitators' camp
--     after sd01-thendal-4     4.83   Boro: training 4 + 92466 in, 92467 > the Minor Manifestation of Earth (east of
--                                     Thendal) > 92468: EARTH TOTEM
--     after sd01-illaya-2      6.35   Aarnor Galestrike in Shen'dar (next to Illaya): training 6
--     after sd01-shendar-8     9.35   Aarnor: training 8
--     after sd02-endaria      10.45   Sessaria Skystride in Valanaar (next to Endaria): a class-scoped level-10 gate
--                                     (simulator), training 10 + 97243
--     after sd02-riaani       10.55   Olariaan Swiftburn on the south coast (on the way to the farm): 97243 > 97244
--     after sd02-valanaar-10  11.36   Skypriest Faladiel north-east of Valanaar: Faladiel's Heart
--     after sd02-speech  13.36/13.30   Olariaan: 97244 > 97245; Kuramaa (west): the mask; Olariaan: 97245 > 97257; the two
--                                     braziers; Sessaria: 97257 in = FIRE TOTEM, training 12; then the skycutter
--
-- Shared path (level before the insert, shaman routes, normal / worst case where they differ):
--   12     after h12-wisdom       12.99, Tauren only (after the Fire chain): Kardris in the Valley of Wisdom (75 yd).
--   12+14  after h15-razor-hill   Orc / Troll 14.31 / 14.25, Tauren 14.93 / 14.85, Skyborne 15.60 / 15.51: Swart in Razor
--                                 Hill (~190 yd from the anchor's NPC): Orc / Troll 12 + 14, the others 14.
--   Fire   after h15-far-watch    14.34 / 14.28, Orc / Troll: Kranal Fiss (640 yd west) 2983 > 1524; Telf Joolam on the
--                                 mountain above the Valley of Trials 1524 > 1525; Reagent Pouch (Burning Blade
--                                 Cultists, Skull Rock); Fire Tar (Razormane Geomancers / Mystics, 450 yd south-east of
--                                 Kranal); Telf 1525 > 1526; the Minor Manifestation of Fire at the brazier; brazier
--                                 1526 > 1527; Kranal 1527 in: FIRE TOTEM. ~6,500 yd (15 min on foot) for 4,710 XP; the
--                                 Tauren do the same at 12.
--   16+18  after h18-tb-zamah     18.28-18.83 / 18.04-18.54: Spirit Rise, Thunder Bluff: Siln Skychaser stands next to
--                                 Zamah (no detour).
--   20     after h18-tb-2         20.53-20.95 / 20.26-20.62: Elder Rise > Spirit Rise > the flight master (~550 yd
--                                 more): GHOST WOLF. Optional at Xanis next to the trainers: 1529 (Call of Water
--                                 breadcrumb). Optional before (after h18-sethearth-tb): Two-Handed Maces at Ansekhwa
--                                 next to the inn.
--   Water  after h18-fly-ratchet-2 (optional) Islen Waterseer, 570 yd south of the Ratchet flight master: 1529 > 1530.
--          after h-24-gann-stonespire (optional) Brine, 250 yd west of Gann: 1530 > 1535 (the watering hole next to
--                                 her) > turned in. The chain stops there (the rest: Tarren Mill, Ashenvale, Silverpine
--                                 and two more Islen trips at 31+, little XP left): no Water Totem.
--   22     after h18-end          22.04-22.36 / 22.04-22.05: Siln, next to Zamah (no detour).
--   24     after h-24-tb-arrive   24.86-25.10 / 24.05-24.06: Siln, next to Zamah.
--   26     after h-27-tb-arrive   27.39-27.57 / 27.12: Siln, next to Zamah.
--   28     after h-28-skywatcher  28.43-28.59 / 27.97 (optional: the worst case is below 28): Palah Thunderhoof on
--                                 Skywatcher Plateau, next to the quest giver (no detour).
--   30     after h-31-tb-end      31.01: Elder Rise > Spirit Rise > the flight master (~540 yd more): Windfury Weapon,
--                                 Reincarnation; 1532 Call of Air at Xanis (free).
--   Air    after h46-fly-freewind (optional) Prate Cloudseer, ~420 yd north-east of Freewind Post: 1532 in (AIR TOTEM),
--                                 back to the flight master.
--   32-36  after h-37-org-arrive  36.06: Valley of Wisdom on the way to Keldran (~60 yd more): Windfury Totem, Chain
--                                 Lightning (no trainer between 31.05 and 36.06, classes.md 4.3).
--   38+40  after h-40-org-arrive  40.06 / 40.01: Valley of Wisdom on the way from Keldran to the flight master (~210 yd
--                                 more): mail, Chain Heal. The race riding steps follow (Races/*.lua).
--   42+44  after h-44-stonard-arrive 44.05 / 44.03: Haromm, Stonard (next to Kartosh; no detour).
--   46+48  after h-50-org-arrive  49.41 / 49.37: Valley of Wisdom on the way to the centre (~300 yd more).
--   50     after h-51-stonard     51.80 / 51.56: Haromm (no detour).
--   52     after h-53-org-arrive  52.73 / 52.70: Valley of Wisdom on the way to the inn (~350 yd more).
--   54     after h-56-org-arrive  55.07: Valley of Wisdom on the way to the inn (~280 yd more).
--   56     after h-58-org-arrive  57.21 / 57.18: Valley of Wisdom from the inn, then out to the zeppelin (~600 yd more).
--   58+60  after h-60-end         optional: hearth to Undercity, zeppelin to Durotar, Valley of Wisdom.
-- Not visited: 16 (no city at 16 on the shared path, PLAN.md B.9: merged into 18); 12 for Orc / Troll in Orgrimmar at
--   11.5 (below 12: merged into 14); the Orgrimmar stops at 22.05, 31.05, 41.01, 53.05 (one rank or none); Thunder
--   Bluff at 28.34 / 28.74 (Palah on the plateau is between them); the Undercity stops (no shaman trainer).
-- Skipped class quests: the rest of Call of Water (1536, 1534, 220, 63, 100, 96: Tarren Mill, Ashenvale, Silverpine and
--   two Islen trips; when the path is there the quests are 8+ levels below the character), so no Water Totem
--   (Healing Stream, Mana Spring); 2985 / 2986 / 1528 (other Water breadcrumbs, not on the path at 20); 98517 (Skyborne
--   breadcrumb from Swart back to Zephras); the Earth / Fire Sapta repeat quests (1462, 1463, 1464, 972, 1103: only for
--   a lost Sapta); 8410 - 8413 (level 50: Alterac Mountains, Plaguelands vultures, the Sunken Temple); the Forever-new
--   chains outside the snapshot (79358 - 79442, 96136: givers and rewards unknown).
-- Class reward table: none. The DB snapshot has no reward lists; a wrong index would make the automation take the wrong
--   item. The notes say what to look for (two-handed maces and axes, intellect / strength).
--
-- Automation notes: a training step at an NPC who also hands out a quest of this file is merged with that accept
-- (sha-*-train-10: train + breadcrumb at Swart / Narm; sha-zep-train-4: train + turn-in at Boro), so the automation
-- cannot take the quest first and fast-forward the visit. Every insert follows a step the player has just done (an
-- arrival, a hearth, a turn-in) and leaves the path where it was or before a shared `go` / `fly` / quest step that works
-- from the new place.

if not FastesBoooy.AddLibraryInsert then return end
local insert = FastesBoooy.AddLibraryInsert

local GORNEK = { 1411, 42.06, 68.33 }
local SHIKRIK = { 1411, 42.39, 69.00 }
local CANAGA = { 1411, 42.40, 69.17 }
local FELSTALKERS = { 1411, 44.0, 54.0 }
local EARTH_DUR = { 1411, 44.03, 76.20 }
local SWART = { 1411, 54.42, 42.59 }
local GRULL = { 1412, 44.47, 77.50 }
local MEELA = { 1412, 44.58, 76.56 }
local RAVENFEATHER = { 1412, 44.35, 76.77 }
local BRISTLEBACK = { 1412, 59.0, 78.0 }
local EARTH_MUL = { 1412, 51.99, 80.40 }
local NARM = { 1412, 47.40, 62.54 }
local RORIAN = { 2521, 42.05, 23.49 }
local BORO = { 2521, 42.79, 23.58 }
local CONVERTS = { 2521, 47.2, 20.0 }
local EARTH_ZEP = { 2521, 49.67, 23.80 }
local AARNOR = { 2521, 43.45, 44.87 }
local SESSARIA = { 2521, 58.31, 78.51 }
local OLARIAAN = { 2521, 51.24, 86.19 }
local FALADIEL = { 2521, 64.43, 63.71 }
local KURAMAA = { 2521, 42.44, 68.75 }
local BRAZIER_OFFERING = { 2521, 51.20, 85.90 }
local BRAZIER_ETERNAL = { 2521, 58.35, 78.84 }
local KRANAL = { 1413, 56.03, 19.89 }
local TELF = { 1411, 38.55, 58.96 }
local SKULL_ROCK = { 1411, 52.4, 25.5 }
local GEOMANCERS = { 1413, 58.0, 25.2 }
local FIRE_MANIFESTATION = { 1411, 38.72, 58.29 }
local DORMANT_BRAZIER = { 1411, 38.96, 58.22 }
local KARDRIS = { 1454, 38.80, 36.37 }
local ORG_TRAINERS = { 3344, 3403, 13417 }      -- Kardris Dreamseeker, Sian'tsu, Sagorne Creststrider (Valley of Wisdom)
local SILN = { 1456, 22.82, 21.11 }
local TB_TRAINERS = { 3030, 3031, 3032 }        -- Siln Skychaser, Tigor Skychaser, Beram Skychaser (Spirit Rise)
local XANIS = { 1456, 25.16, 20.51 }
local ANSEKHWA = { 1456, 40.93, 62.73 }
local PALAH = { 1412, 33.59, 22.40 }
local ISLEN = { 1413, 65.83, 43.78 }
local BRINE = { 1413, 43.42, 77.41 }
local WATERING_HOLE = { 1413, 44.28, 76.75 }
local PRATE = { 1441, 53.54, 42.65 }
local FREEWIND = { 1441, 45.14, 49.11 }
local HAROMM = { 1435, 48.19, 57.94 }

local function spell(ru, en) return { ru = ru, en = en } end
local NEW = { ru = " (новый ранг)", en = " (new rank)" }
local function rank(ru, en) return { ru = ru .. NEW.ru, en = en .. NEW.en } end

------------------------------------------------------------------------------------------------------------------
-- Durotar (Orc, Troll) ------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- The letter: Gornek hands it out in the dialog of the shared turn-in of 788; Shikrik stands in the Den next to him.
insert({
    after = "dur01-teeth",
    class = "SHAMAN",
    race = "Orc",
    steps = {
        { id = "sha-dur-letter-orc", accept = 3089, npc = 3143, at = GORNEK,
          note = { ru = "Горнек даёт и письмо шамана: «Пергамент с рунами».",
                   en = "Gornek also has the shaman's letter: Rune-Inscribed Parchment." } },
        { id = "sha-dur-shikrik-orc", turnin = 3089, npc = 3157, at = SHIKRIK,
          note = { ru = "Шикрик — тренер шаманов, в Логове рядом с Горнеком. Учить пока нечего (следующее — на 4-м).",
                   en = "Shikrik, the shaman trainer, in the Den next to Gornek. Nothing to train yet (next at 4)." } },
    },
})
insert({
    after = "dur01-teeth",
    class = "SHAMAN",
    race = "Troll",
    steps = {
        { id = "sha-dur-letter-troll", accept = 3084, npc = 3143, at = GORNEK,
          note = { ru = "Горнек даёт и письмо шамана: «Табличка с рунами».",
                   en = "Gornek also has the shaman's letter: Rune-Inscribed Tablet." } },
        { id = "sha-dur-shikrik-troll", turnin = 3084, npc = 3157, at = SHIKRIK,
          note = { ru = "Шикрик — тренер шаманов, в Логове рядом с Горнеком. Учить пока нечего (следующее — на 4-м).",
                   en = "Shikrik, the shaman trainer, in the Den next to Gornek. Nothing to train yet (next at 4)." } },
    },
})
-- Level 4 in the Den: Call of Earth part 1 and the first training.
insert({
    after = "dur01-den-4",
    class = "SHAMAN",
    race = { "Orc", "Troll" },
    steps = {
        { id = "sha-dur-level-4", level = 4, at = CANAGA,
          note = { ru = "«Зов Земли» требует 4-й уровень (обычно он уже есть после бесов).",
                   en = "Call of Earth needs level 4 (usually reached with the familiars)." } },
        { id = "sha-dur-1516", accept = 1516, npc = 5887, at = CANAGA,
          ok = "db-override-unverified", -- CONFIRM: 1516 has no prerequisite (snapshot: itself; tools/overrides/shaman.lua)
          note = { ru = "«Зов Земли»: Канага Зовущая Землю у входа в Логово. Нужны 2 копыта скверноходов — они бродят "
                       .. "у пещеры на севере, куда вы сейчас идёте.",
                   en = "Call of Earth: Canaga Earthcaller at the Den entrance. She wants 2 Felstalker Hooves: the "
                       .. "felstalkers roam by the cave in the north where you are going now." } },
        { id = "sha-dur-train-4", train = true, npc = 3157, at = SHIKRIK,
          spells = { spell("Земной шок", "Earth Shock"), spell("Тотем каменной кожи", "Stoneskin Totem") },
          note = { ru = "Шикрик: обучение 4-го уровня.", en = "Shikrik: level 4 training." } },
    },
})
insert({
    after = "dur01-thazzril-2",
    class = "SHAMAN",
    race = { "Orc", "Troll" },
    steps = {
        { id = "sha-dur-hooves", complete = 1516, at = FELSTALKERS,
          note = { ru = "Север долины, у пещеры Ковена Пылающего Клинка: скверноходы, 2 копыта (вместе с бесами и пещерой).",
                   en = "The north of the valley by the Burning Blade Coven cave: Felstalkers, 2 hooves (together with "
                       .. "the familiars and the cave)." } },
    },
})
-- Back in the Den: the manifestation stands on the slope south of the Den (about 260 yards).
insert({
    after = "dur01-leave",
    class = "SHAMAN",
    race = { "Orc", "Troll" },
    steps = {
        { id = "sha-dur-1517", turnin = 1516, accept = 1517, npc = 5887, at = CANAGA,
          note = { ru = "Канага: сдайте копыта. Она даёт Земляную сапту — выпейте её у камня к югу от Логова, тогда "
                       .. "станет видно воплощение земли.",
                   en = "Canaga: turn in the hooves. She gives you the Earth Sapta: drink it by the stone south of the "
                       .. "Den to see the manifestation." } },
        { id = "sha-dur-manifestation", turnin = 1517, accept = 1518, npc = 5891, at = EARTH_DUR, use = 6635,
          note = { ru = "Около 260 м на юг от Логова: выпейте Земляную сапту и поговорите с малым воплощением земли.",
                   en = "About 260 yards south of the Den: drink the Earth Sapta and talk to the Minor Manifestation "
                       .. "of Earth." } },
        { id = "sha-dur-1518", turnin = 1518, npc = 5887, at = CANAGA,
          note = { ru = "Обратно к Канаге: ТОТЕМ ЗЕМЛИ (предмет в сумке, без него земляные тотемы не ставятся).",
                   en = "Back to Canaga: the EARTH TOTEM (an item in your bags; earth totems need it)." } },
    },
})
insert({
    after = "dur02-rh-1",
    class = "SHAMAN",
    race = { "Orc", "Troll" },
    steps = {
        { id = "sha-dur-train-6", train = true, npc = 3173, at = SWART,
          spells = { spell("Тотем оков земли", "Earthbind Totem"), rank("Волна исцеления", "Healing Wave") },
          note = { ru = "Сварт, тренер шаманов Колючего Холма, в двух шагах от Турока: обучение 6-го уровня.",
                   en = "Swart, the Razor Hill shaman trainer, a few steps from Turroc: level 6 training." } },
    },
})
insert({
    after = "dur02-garthok-3",
    class = "SHAMAN",
    race = { "Orc", "Troll" },
    steps = {
        { id = "sha-dur-train-8", train = true, npc = 3173, at = SWART,
          spells = { spell("Щит молний", "Lightning Shield"), spell("Тотем каменного когтя", "Stoneclaw Totem"),
                     rank("Молния", "Lightning Bolt"), rank("Земной шок", "Earth Shock") },
          note = { ru = "Сварт (восточный край Колючего Холма): обучение 8-го уровня.",
                   en = "Swart (east side of Razor Hill): level 8 training." } },
    },
})
-- Level 10: training and the Fire breadcrumb in one step (look-ahead rule); 2983 is carried to Far Watch Post (C.2).
insert({
    after = "dur02-rh-3",
    class = "SHAMAN",
    race = { "Orc", "Troll" },
    steps = {
        { id = "sha-dur-train-10", train = true, accept = 2983, npc = 3173, at = SWART,
          spells = { spell("Огненный шок", "Flame Shock"), spell("Оружие языка пламени", "Flametongue Weapon"),
                     spell("Тотем силы земли", "Strength of Earth Totem") },
          note = { ru = "Сварт: обучение 10-го уровня и «Зов Огня» (письмо к Краналу Фиссу у Заставы Дальнего Дозора: "
                       .. "носите его с собой, цепочка — когда путь дойдёт до заставы, на 14-м).",
                   en = "Swart: level 10 training and Call of Fire (to Kranal Fiss by Far Watch Post: carry it, the "
                       .. "chain comes when the path reaches the post, at 14)." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Mulgore (Tauren) ----------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
insert({
    after = "mul01-hunt",
    class = "SHAMAN",
    race = "Tauren",
    steps = {
        { id = "sha-mul-letter", accept = 3093, npc = 2980, at = GRULL,
          note = { ru = "Грулл Ястребиный Ветер даёт и письмо шамана: «Записка с рунами».",
                   en = "Grull Hawkwind also has the shaman's letter: Rune-Inscribed Note." } },
        { id = "sha-mul-meela", turnin = 3093, npc = 3062, at = MEELA,
          note = { ru = "Мила Рассветная Странница — тренер шаманов, рядом с вождём. Учить пока нечего (следующее — на 4-м).",
                   en = "Meela Dawnstrider, the shaman trainer, next to the chief. Nothing to train yet (next at 4)." } },
    },
})
insert({
    after = "mul01-ravine",
    class = "SHAMAN",
    race = "Tauren",
    steps = {
        { id = "sha-mul-1519", accept = 1519, npc = 5888, at = RAVENFEATHER,
          ok = "db-override-unverified", -- CONFIRM: 1519 has no prerequisite (snapshot: itself; tools/overrides/shaman.lua)
          note = { ru = "«Зов Земли»: провидец Воронье Перо в лагере. Нужны 2 ритуальные мази с шаманов Иглошкуров — "
                       .. "они в ущелье, куда вы сейчас идёте.",
                   en = "Call of Earth: Seer Ravenfeather in the camp. He wants 2 Ritual Salves from the Bristleback "
                       .. "Shamans: they are in the ravine where you are going now." } },
        { id = "sha-mul-train-4", train = true, npc = 3062, at = MEELA,
          spells = { spell("Земной шок", "Earth Shock"), spell("Тотем каменной кожи", "Stoneskin Totem") },
          note = { ru = "Мила: обучение 4-го уровня.", en = "Meela: level 4 training." } },
    },
})
insert({
    after = "mul01-belts",
    class = "SHAMAN",
    race = "Tauren",
    steps = {
        { id = "sha-mul-salves", complete = 1519, at = BRISTLEBACK,
          note = { ru = "Шаманы Иглошкуров в ущелье (вместе с поясами): 2 ритуальные мази.",
                   en = "The Bristleback Shamans in the ravine (together with the belts): 2 Ritual Salves." } },
    },
})
insert({
    after = "mul01-leave",
    class = "SHAMAN",
    race = "Tauren",
    steps = {
        { id = "sha-mul-1520", turnin = 1519, accept = 1520, npc = 5888, at = RAVENFEATHER,
          note = { ru = "Провидец: сдайте мази. Он даёт Земляную сапту — выпейте её у камня к востоку от лагеря, "
                       .. "тогда станет видно воплощение земли.",
                   en = "The Seer: turn in the salves. He gives you the Earth Sapta: drink it by the stone east of the "
                       .. "camp to see the manifestation." } },
        { id = "sha-mul-manifestation", turnin = 1520, accept = 1521, npc = 5891, at = EARTH_MUL, use = 6635,
          note = { ru = "Около 500 м на восток, у дороги к ущелью: выпейте Земляную сапту и поговорите с малым "
                       .. "воплощением земли.",
                   en = "About 500 yards east, by the way to the ravine: drink the Earth Sapta and talk to the Minor "
                       .. "Manifestation of Earth." } },
        { id = "sha-mul-1521", turnin = 1521, npc = 5888, at = RAVENFEATHER,
          note = { ru = "Обратно к провидцу: ТОТЕМ ЗЕМЛИ (предмет в сумке, без него земляные тотемы не ставятся).",
                   en = "Back to the Seer: the EARTH TOTEM (an item in your bags; earth totems need it)." } },
    },
})
insert({
    after = "mul02-bh-1",
    class = "SHAMAN",
    race = "Tauren",
    steps = {
        { id = "sha-mul-train-6", train = true, npc = 3066, at = NARM,
          spells = { spell("Тотем оков земли", "Earthbind Totem"), rank("Волна исцеления", "Healing Wave") },
          note = { ru = "Нарм Небесный Ловец, тренер шаманов Кровавого Копыта (рядом с Маллом): обучение 6-го уровня.",
                   en = "Narm Skychaser, the Bloodhoof shaman trainer (next to Mull): level 6 training." } },
    },
})
insert({
    after = "mul02-bh-3",
    class = "SHAMAN",
    race = "Tauren",
    steps = {
        { id = "sha-mul-train-8", train = true, npc = 3066, at = NARM,
          spells = { spell("Щит молний", "Lightning Shield"), spell("Тотем каменного когтя", "Stoneclaw Totem"),
                     rank("Молния", "Lightning Bolt"), rank("Земной шок", "Earth Shock") },
          note = { ru = "Нарм: обучение 8-го уровня.", en = "Narm: level 8 training." } },
    },
})
insert({
    after = "mul02-bh-5",
    class = "SHAMAN",
    race = "Tauren",
    steps = {
        { id = "sha-mul-train-10", train = true, accept = 2984, npc = 3066, at = NARM,
          spells = { spell("Огненный шок", "Flame Shock"), spell("Оружие языка пламени", "Flametongue Weapon"),
                     spell("Тотем силы земли", "Strength of Earth Totem") },
          note = { ru = "Нарм: обучение 10-го уровня и «Зов Огня» (к Краналу Фиссу у Заставы Дальнего Дозора: путь "
                       .. "проходит мимо неё на 12-м).",
                   en = "Narm: level 10 training and Call of Fire (to Kranal Fiss by Far Watch Post: the path passes "
                       .. "it at 12)." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Call of Fire, mainland (Orc and Troll at h15-far-watch, the Tauren at mul03-far-watch) ------------------------
------------------------------------------------------------------------------------------------------------------
-- Kranal Fiss stands 640 yd west of Far Watch Post; Telf Joolam on the mountain top above the Valley of Trials,
-- ~1,100 yd south-west of Kranal; the Burning Blade Cultists (Reagent Pouch) at Skull Rock, north Durotar; the
-- Razormane Geomancers and Mystics (Fire Tar; the Water Seekers and Thornweavers a little further west drop it as
-- well) ~450 yd south-east of Kranal. Order Kranal > Telf > Skull Rock > Razormanes > Telf > Kranal (~6,100 yd); the
-- path then walks on from Kranal to the Crossroads (Orc, Troll) or the Orgrimmar gate (Tauren).
local function fireChain(p, breadcrumb, nextStop)
    return {
        { id = p .. "-kranal", turnin = breadcrumb, accept = 1524, npc = 5907, at = KRANAL,
          note = { ru = "«Зов Огня»: Кранал Фисс — 640 м на запад от Заставы Дальнего Дозора, у скал. Он посылает к "
                       .. "Тельфу Джуламу в Дуротар.",
                   en = "Call of Fire: Kranal Fiss, 640 yards west of Far Watch Post by the rocks. He sends you to Telf "
                       .. "Joolam in Durotar." } },
        -- CONFIRM: where the trail up to Telf Joolam starts (the snapshot has only his position)
        { id = p .. "-telf", turnin = 1524, accept = 1525, npc = 5900, at = TELF,
          note = { ru = "Тельф Джулам — у святилища Спящего Пламени на вершине горы над Долиной Испытаний (около "
                       .. "1100 м на юго-восток от Кранала, наверх ведёт тропа). Ему нужны огненная смола (Иглогривые "
                       .. "у Кранала) и мешочек с реагентами (культисты на Скале Черепа).",
                   en = "Telf Joolam at the Shrine of the Dormant Flame on the mountain top above the Valley of Trials "
                       .. "(about 1,100 yards south-east of Kranal, a trail leads up). He wants Fire Tar (Razormanes by "
                       .. "Kranal) and a Reagent Pouch (the cultists of Skull Rock)." } },
        { id = p .. "-pouch", complete = { [1525] = { 2 } }, at = SKULL_ROCK,
          note = { ru = "На север, Скала Черепа у Оргриммара: культисты Пылающего Клинка — мешочек с реагентами.",
                   en = "North to Skull Rock by Orgrimmar: Burning Blade Cultists for the Reagent Pouch." } },
        { id = p .. "-tar", complete = { [1525] = { 1 } }, at = GEOMANCERS,
          note = { ru = "На запад в Степи, к юго-востоку от Кранала: Иглогривые геоманты и мистики (или искатели воды чуть "
                       .. "западнее) — огненная смола.",
                   en = "West into the Barrens, south-east of Kranal: Razormane Geomancers and Mystics (or the Water "
                       .. "Seekers a bit further west) for the Fire Tar." } },
        { id = p .. "-telf-2", turnin = 1525, accept = 1526, npc = 5900, at = TELF,
          note = { ru = "Снова к Тельфу на гору. Он даёт Огненную сапту: выпейте её у жаровни рядом.",
                   en = "Back up to Telf. He gives you the Fire Sapta: drink it by the brazier next to him." } },
        { id = p .. "-ember", complete = 1526, at = FIRE_MANIFESTATION,
          note = { ru = "Выпейте сапту: у жаровни появится малое воплощение огня. Убейте его — Тлеющий уголёк.",
                   en = "Drink the Sapta: a Minor Manifestation of Fire appears at the brazier. Kill it for the "
                       .. "Glowing Ember." } },
        { id = p .. "-brazier", turnin = 1526, accept = 1527, object = 61934, at = DORMANT_BRAZIER,
          note = { ru = "Положите уголёк в жаровню Спящего Пламени и возьмите следующее задание у неё же.",
                   en = "Put the ember into the Brazier of the Dormant Flame and take the next quest from it." } },
        { id = p .. "-kranal-2", turnin = 1527, npc = 5907, at = KRANAL,
          note = { ru = "Обратно к Краналу Фиссу: ТОТЕМ ОГНЯ (Опаляющий тотем). Дальше — " .. nextStop.ru .. ".",
                   en = "Back to Kranal Fiss: the FIRE TOTEM (Searing Totem). Then on to " .. nextStop.en .. "." } },
    }
end

insert({
    after = "mul03-far-watch",
    class = "SHAMAN",
    race = "Tauren",
    steps = fireChain("sha-mul-fire", 2984, { ru = "к воротам Оргриммара", en = "the Orgrimmar gate" }),
})
insert({
    after = "h15-far-watch",
    class = "SHAMAN",
    race = { "Orc", "Troll" },
    steps = fireChain("sha-fire", 2983, { ru = "на Перекрёсток", en = "the Crossroads" }),
})

------------------------------------------------------------------------------------------------------------------
-- Zephras Isle (Skyborne) ---------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- The letter (Rorian gives it after 92461), Call of Earth needs level 3: the turn-ins of the anchor bring it.
insert({
    after = "sd01-rorian",
    class = "SHAMAN",
    race = "Skyborne",
    steps = {
        { id = "sha-zep-letter", accept = 92484, npc = 251361, at = RORIAN,
          note = { ru = "Рориан даёт и письмо шамана: «Объятия стихий» (прочитайте записку в сумке).",
                   en = "Rorian also has the shaman's letter: Embracing the Elements (read the note in your bags)." } },
        { id = "sha-zep-boro", turnin = 92484, npc = 251374, at = BORO,
          note = { ru = "Ветроваятель Боро — тренер шаманов, в двух шагах от Рориана.",
                   en = "Windshaper Boro, the shaman trainer, a few steps from Rorian." } },
        { id = "sha-zep-level-3", level = 3, at = BORO,
          note = { ru = "«Зов Земли» требует 3-й уровень. Не хватает — новообращённые Аль'Акет у деревни.",
                   en = "Call of Earth needs level 3. Short: the Al'Aketh Converts by the village." } },
        { id = "sha-zep-92466", accept = 92466, npc = 251374, at = BORO,
          note = { ru = "Боро: «Зов Земли» — Печатка Акира с культистов Аль'Акет (новообращённые в лагере агитаторов, "
                       .. "куда вы идёте, подходят).",
                   en = "Boro: Call of Earth - the Signet of Akir from the Al'Aketh cultists (the Converts of the "
                       .. "agitators' camp, where you are going, drop it)." } },
    },
})
insert({
    after = "sd01-agitators",
    class = "SHAMAN",
    race = "Skyborne",
    steps = {
        -- CONFIRM: the Converts drop the Signet of Akir (the snapshot lists them among eight drop sources, no rate)
        { id = "sha-zep-signet", complete = 92466, at = CONVERTS,
          note = { ru = "Новообращённые Аль'Акет здесь же: бейте, пока не выпадет Печатка Акира.",
                   en = "The Al'Aketh Converts right here: kill them until the Signet of Akir drops." } },
    },
})
-- Level 4 in Thendal: training merged with the turn-in at Boro (look-ahead rule), the manifestation east of the village.
insert({
    after = "sd01-thendal-4",
    class = "SHAMAN",
    race = "Skyborne",
    steps = {
        { id = "sha-zep-train-4", train = true, turnin = 92466, accept = 92467, npc = 251374, at = BORO,
          spells = { spell("Земной шок", "Earth Shock"), spell("Тотем каменной кожи", "Stoneskin Totem") },
          note = { ru = "Боро: сдайте печатку, обучение 4-го уровня. Он даёт Земляную сапту — выпейте её у камня к "
                       .. "востоку от деревни.",
                   en = "Boro: turn in the signet, level 4 training. He gives you the Earth Sapta: drink it by the "
                       .. "stone east of the village." } },
        { id = "sha-zep-manifestation", turnin = 92467, accept = 92468, npc = 251166, at = EARTH_ZEP, use = 6635,
          note = { ru = "На восток от Тендала: выпейте Земляную сапту и поговорите с малым воплощением земли.",
                   en = "East of Thendal: drink the Earth Sapta and talk to the Minor Manifestation of Earth." } },
        { id = "sha-zep-92468", turnin = 92468, npc = 251374, at = BORO,
          note = { ru = "Обратно к Боро: ТОТЕМ ЗЕМЛИ (предмет в сумке, без него земляные тотемы не ставятся).",
                   en = "Back to Boro: the EARTH TOTEM (an item in your bags; earth totems need it)." } },
    },
})
insert({
    after = "sd01-illaya-2",
    class = "SHAMAN",
    race = "Skyborne",
    steps = {
        { id = "sha-zep-train-6", train = true, npc = 254082, at = AARNOR,
          spells = { spell("Тотем оков земли", "Earthbind Totem"), rank("Волна исцеления", "Healing Wave") },
          note = { ru = "Аарнор Штормовой Удар, тренер шаманов Шен'дара, рядом с Иллаей: обучение 6-го уровня.",
                   en = "Aarnor Galestrike, the Shen'dar shaman trainer, next to Illaya: level 6 training." } },
    },
})
insert({
    after = "sd01-shendar-8",
    class = "SHAMAN",
    race = "Skyborne",
    steps = {
        { id = "sha-zep-train-8", train = true, npc = 254082, at = AARNOR,
          spells = { spell("Щит молний", "Lightning Shield"), spell("Тотем каменного когтя", "Stoneclaw Totem"),
                     rank("Молния", "Lightning Bolt"), rank("Земной шок", "Earth Shock") },
          note = { ru = "Аарнор: обучение 8-го уровня.", en = "Aarnor: level 8 training." } },
    },
})
-- Valanaar at 10: training and Call of Fire in one step (Sessaria gives the quest: look-ahead rule).
insert({
    after = "sd02-endaria",
    class = "SHAMAN",
    race = "Skyborne",
    steps = {
        { id = "sha-zep-level-10", level = 10, at = SESSARIA,
          note = { ru = "«Зов Огня» требует 10-й уровень (обычно он уже есть у причала Валанаара).",
                   en = "Call of Fire needs level 10 (usually reached by the Valanaar docks)." } },
        { id = "sha-zep-train-10", train = true, accept = 97243, npc = 252382, at = SESSARIA,
          spells = { spell("Огненный шок", "Flame Shock"), spell("Оружие языка пламени", "Flametongue Weapon"),
                     spell("Тотем силы земли", "Strength of Earth Totem") },
          note = { ru = "Сессария Небесная Поступь, тренер шаманов Валанаара (рядом с Эндарией): обучение 10-го уровня и "
                       .. "«Зов Огня» к Олариану на южном берегу.",
                   en = "Sessaria Skystride, the Valanaar shaman trainer (next to Endaria): level 10 training and Call "
                       .. "of Fire to Olariaan on the south coast." } },
    },
})
insert({
    after = "sd02-riaani",
    class = "SHAMAN",
    race = "Skyborne",
    steps = {
        { id = "sha-zep-olariaan", turnin = 97243, accept = 97244, npc = 268592, at = OLARIAAN,
          note = { ru = "Оларийн Быстрый Огонь на южном берегу (по пути на ферму Амелии): ему нужно сердце небесного "
                       .. "жреца Фаладиэля (северо-восток острова, позже по пути).",
                   en = "Olariaan Swiftburn on the south coast (on the way to Aamelia's farm): he wants the heart of "
                       .. "Skypriest Faladiel (north-east of the isle, later on the way)." } },
    },
})
insert({
    after = "sd02-valanaar-10",
    class = "SHAMAN",
    race = "Skyborne",
    steps = {
        { id = "sha-zep-faladiel", complete = 97244, at = FALADIEL,
          note = { ru = "К северо-востоку от Валанаара: небесный жрец Фаладиэль — его сердце для Оларийна.",
                   en = "North-east of Valanaar: Skypriest Faladiel - his heart for Olariaan." } },
    },
})
-- Before the skycutter: the rest of the chain (south coast, Kuramaa in the west, the braziers) and Sessaria.
insert({
    after = "sd02-speech",
    class = "SHAMAN",
    race = "Skyborne",
    steps = {
        { id = "sha-zep-olariaan-2", turnin = 97244, accept = 97245, npc = 268592, at = OLARIAAN,
          note = { ru = "Перед отлётом: на южный берег к Оларийну. Следующее — маска Курамаа на западе.",
                   en = "Before you leave: to Olariaan on the south coast. Next: Kuramaa's mask in the west." } },
        { id = "sha-zep-kuramaa", complete = 97245, at = KURAMAA,
          note = { ru = "На запад: Курамаа, дух проказ, — его маска.",
                   en = "West: Kuramaa, the Spirit of Mischief - his mask." } },
        { id = "sha-zep-olariaan-3", turnin = 97245, accept = 97257, npc = 268592, at = OLARIAAN,
          note = { ru = "Обратно к Оларийну: зажгите две жаровни — одну здесь, другую в Валанааре.",
                   en = "Back to Olariaan: light two braziers - one right here, the other in Valanaar." } },
        { id = "sha-zep-brazier-1", complete = { [97257] = { 1 } }, at = BRAZIER_OFFERING,
          note = { ru = "Жаровня подношений рядом с Оларийном.", en = "The Brazier of Offering next to Olariaan." } },
        { id = "sha-zep-brazier-2", complete = { [97257] = { 2 } }, at = BRAZIER_ETERNAL,
          note = { ru = "Жаровня вечного пламени в Валанааре, рядом с Сессарией.",
                   en = "The Brazier of Eternal Flame in Valanaar, next to Sessaria." } },
        { id = "sha-zep-train-12", train = true, turnin = 97257, npc = 252382, at = SESSARIA,
          spells = { spell("Развеивание магии", "Purge"), spell("Тотем кольца огня", "Fire Nova Totem"),
                     spell("Дух предков", "Ancestral Spirit") },
          note = { ru = "Сессария: ТОТЕМ ОГНЯ (Опаляющий тотем) и обучение 12-го уровня. Небесный корабль — рядом.",
                   en = "Sessaria: the FIRE TOTEM (Searing Totem) and level 12 training. The skycutter is next to "
                       .. "her." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 12-22 ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- Tauren: after the Fire chain the first Orgrimmar visit is above 12; Kardris stands 75 yd from the anchor's NPC.
insert({
    after = "h12-wisdom",
    class = "SHAMAN",
    race = "Tauren",
    steps = {
        { id = "sha-12-train", train = true, npc = ORG_TRAINERS, at = KARDRIS,
          spells = { spell("Развеивание магии", "Purge"), spell("Тотем кольца огня", "Fire Nova Totem"),
                     spell("Дух предков", "Ancestral Spirit") },
          note = { ru = "Аллея Мудрости, рядом: Кардрис Ищущая Сны — обучение 12-го уровня.",
                   en = "The Valley of Wisdom, right here: Kardris Dreamseeker - level 12 training." } },
    },
})
insert({
    after = "h15-razor-hill",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-14", train = true, npc = 3173, at = SWART,
          spells = { rank("Молния", "Lightning Bolt"), rank("Земной шок", "Earth Shock"),
                     spell("Развеивание магии", "Purge"), spell("Тотем кольца огня", "Fire Nova Totem") },
          note = { ru = "Сварт на восточном краю Колючего Холма (около 190 м): обучение 14-го уровня (оркам и троллям — "
                       .. "и 12-го: «Развеивание магии», «Тотем кольца огня»).",
                   en = "Swart on the east side of Razor Hill (about 190 yards): level 14 training (Orcs and Trolls "
                       .. "also take 12: Purge, Fire Nova Totem)." } },
    },
})
insert({
    after = "h18-tb-zamah",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-18", train = true, npc = TB_TRAINERS, at = SILN,
          spells = { spell("Тотем трепета", "Tremor Totem"), spell("Излечение от яда", "Cure Poison"),
                     rank("Огненный шок", "Flame Shock"), rank("Щит молний", "Lightning Shield") },
          note = { ru = "Силн Небесный Ловец стоит рядом с Замахом (Вершина Духов): обучение 16-го и 18-го уровней.",
                   en = "Siln Skychaser stands next to Zamah (Spirit Rise): level 16 and 18 training." } },
    },
})
insert({
    after = "h18-sethearth-tb",
    class = "SHAMAN",
    steps = {
        -- CONFIRM: shamans learn two-handed maces / axes from weapon masters in Forever (a talent in the original game)
        { id = "sha-2h-maces", train = true, optional = true, npc = 11869, at = ANSEKHWA,
          note = { ru = "Необязательно: Ансекхва, мастер оружия у таверны — «Двуручное дробящее оружие» и «Посохи» "
                       .. "(по 10 серебра): с двуручным оружием «Оружие неистовства ветра» с 30-го бьёт сильнее.",
                   en = "Optional: Ansekhwa, the weapon master by the inn - Two-Handed Maces and Staves (10 silver "
                       .. "each): Windfury Weapon at 30 hits harder with a two-hander." } },
    },
})
-- Level 20: Ghost Wolf. Elder Rise > Spirit Rise > the flight master (the path flies to Ratchet next).
insert({
    after = "h18-tb-2",
    class = "SHAMAN",
    steps = {
        -- CONFIRM: Ghost Wolf at 20 and the Forever-new Totemic Recall / Call of the Elements at 20 (classes.md 5.4)
        { id = "sha-train-20", train = true, npc = TB_TRAINERS, at = SILN,
          spells = { spell("Призрачный волк", "Ghost Wolf"), spell("Ледяной шок", "Frost Shock"),
                     spell("Малая волна исцеления", "Lesser Healing Wave"),
                     spell("Оружие ледяного клейма", "Frostbrand Weapon"),
                     spell("Возвращение тотемов", "Totemic Recall"), spell("Зов Стихий", "Call of the Elements") },
          note = { ru = "С Вершины Старейшин на Вершину Духов: обучение 20-го уровня — ПРИЗРАЧНЫЙ ВОЛК (быстрее на всех "
                       .. "переходах). Потом к распорядителю полётов.",
                   en = "From Elder Rise to Spirit Rise: level 20 training - GHOST WOLF (faster on every run). Then to "
                       .. "the flight master." } },
        { id = "sha-1529", accept = 1529, optional = true, npc = 5906, at = XANIS,
          note = { ru = "Необязательно: Ксанис Ткач Пламени рядом с тренерами — «Зов Воды» (к Ислен у Кабестана, куда "
                       .. "вы сейчас летите).",
                   en = "Optional: Xanis Flameweaver next to the trainers - Call of Water (to Islen by Ratchet, where you "
                       .. "fly next)." } },
    },
})
-- Call of Water, first part (optional; the chain stops after 1535, see the header).
insert({
    after = "h18-fly-ratchet-2",
    class = "SHAMAN",
    steps = {
        { id = "sha-islen", turnin = 1529, accept = 1530, optional = true, npc = 5901, at = ISLEN,
          note = { ru = "Необязательно: Ислен Видящая Воду на берегу, около 570 м на юг от распорядителя полётов. Её "
                       .. "задание — к Брайн на юге Степей (путь будет там на 24-м). Потом обратно в Кабестан.",
                   en = "Optional: Islen Waterseer on the shore, about 570 yards south of the flight master. Her quest "
                       .. "goes to Brine in the south Barrens (the path is there at 24). Then back to Ratchet." } },
    },
})
insert({
    after = "h18-end",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-22", train = true, npc = TB_TRAINERS, at = SILN,
          spells = { spell("Призыв тотемов", "Totemic Call"), spell("Тотем очищения от яда", "Poison Cleansing Totem"),
                     spell("Излечение болезни", "Cure Disease") },
          note = { ru = "Силн рядом с Замахом: обучение 22-го уровня.", en = "Siln next to Zamah: level 22 training." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 22-60 ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-24-tb-arrive",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-24", train = true, npc = TB_TRAINERS, at = SILN,
          spells = { rank("Земной шок", "Earth Shock"), rank("Тотем силы земли", "Strength of Earth Totem"),
                     rank("Щит молний", "Lightning Shield") },
          note = { ru = "Силн рядом с Замахом: обучение 24-го уровня.", en = "Siln next to Zamah: level 24 training." } },
    },
})
insert({
    after = "h-24-gann-stonespire",
    class = "SHAMAN",
    steps = {
        { id = "sha-brine", turnin = 1530, accept = 1535, optional = true, npc = 5899, at = BRINE,
          note = { ru = "Необязательно: Брайн, около 250 м на запад от Ганна. Наполните бурдюк у водопоя рядом.",
                   en = "Optional: Brine, about 250 yards west of Gann. Fill the waterskin at the watering hole next "
                       .. "to her." } },
        { id = "sha-watering-hole", complete = 1535, optional = true, object = 107046, at = WATERING_HOLE,
          note = { ru = "Водопой Иглогривых рядом с Брайн: наполните бурый бурдюк.",
                   en = "The Quilboar Watering Hole next to Brine: fill the brown waterskin." } },
        { id = "sha-brine-2", turnin = 1535, optional = true, npc = 5899, at = BRINE,
          note = { ru = "Брайн: сдайте бурдюк. Дальше цепочка уводит в Тарренский Брод и Ясеневый лес — её не берём "
                       .. "(мало опыта, когда путь там).",
                   en = "Brine: turn in the waterskin. The rest of the chain goes to Tarren Mill and Ashenvale - not "
                       .. "taken (little XP by the time the path is there)." } },
    },
})
insert({
    after = "h-27-tb-arrive",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-26", train = true, npc = TB_TRAINERS, at = SILN,
          spells = { rank("Молния", "Lightning Bolt"), spell("Тотем магмы", "Magma Totem"),
                     spell("Дальнее зрение", "Far Sight") },
          note = { ru = "Силн рядом с Замахом: обучение 26-го уровня.", en = "Siln next to Zamah: level 26 training." } },
    },
})
insert({
    after = "h-28-skywatcher",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-28", train = true, optional = true, npc = 262558, at = PALAH,
          spells = { spell("Тотем языка пламени", "Flametongue Totem"), rank("Огненный шок", "Flame Shock"),
                     spell("Хождение по воде", "Water Walking") },
          note = { ru = "Пала Громовое Копыто, тренер шаманов на Плато Небесного Дозора, рядом: обучение 28-го уровня "
                       .. "(если 28-й уже есть; иначе — на 30-м в Громовом Утёсе).",
                   en = "Palah Thunderhoof, the shaman trainer of Skywatcher Plateau, right here: level 28 training "
                       .. "(if you are 28 already; otherwise at 30 in Thunder Bluff)." } },
    },
})
-- Level 30: Elder Rise > Spirit Rise > the flight master; the Air quest from Xanis next to the trainers.
insert({
    after = "h-31-tb-end",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-30", train = true, npc = TB_TRAINERS, at = SILN,
          spells = { spell("Оружие неистовства ветра", "Windfury Weapon"), spell("Перерождение", "Reincarnation"),
                     spell("Тотем заземления", "Grounding Totem"), spell("Астральное возвращение", "Astral Recall"),
                     spell("Зов Предков", "Call of the Ancestors") },
          note = { ru = "С Вершины Старейшин на Вершину Духов: обучение 28-го и 30-го уровней — ОРУЖИЕ НЕИСТОВСТВА "
                       .. "ВЕТРА. Для «Перерождения» нужен анх (продают торговцы реагентами).",
                   en = "From Elder Rise to Spirit Rise: level 28 and 30 training - WINDFURY WEAPON. Reincarnation "
                       .. "needs an Ankh (reagent vendors)." } },
        { id = "sha-1532", accept = 1532, npc = 5906, at = XANIS,
          note = { ru = "Ксанис рядом с тренерами: «Зов Воздуха» (к Прейту в Тысяче Игл; путь будет там на 46-м). Потом "
                       .. "к распорядителю полётов.",
                   en = "Xanis next to the trainers: Call of Air (to Prate in Thousand Needles; the path is there at "
                       .. "46). Then to the flight master." } },
    },
})
insert({
    after = "h-37-org-arrive",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-36", train = true, npc = ORG_TRAINERS, at = KARDRIS,
          spells = { spell("Тотем неистовства ветра", "Windfury Totem"), spell("Цепная молния", "Chain Lightning"),
                     spell("Сторожевой тотем", "Sentry Totem"), rank("Ледяной шок", "Frost Shock") },
          note = { ru = "Аллея Мудрости, по пути к Келдрану: обучение 32-го, 34-го и 36-го уровней.",
                   en = "The Valley of Wisdom, on the way to Keldran: level 32, 34 and 36 training." } },
    },
})
insert({
    after = "h-40-org-arrive",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-40", train = true, npc = ORG_TRAINERS, at = KARDRIS,
          spells = { spell("Цепное исцеление", "Chain Heal"), spell("Кольчужные доспехи", "Mail"),
                     rank("Оружие неистовства ветра", "Windfury Weapon"), rank("Молния", "Lightning Bolt") },
          note = { ru = "От Келдрана в Аллею Мудрости: обучение 38-го и 40-го уровней — кольчуга и «Цепное "
                       .. "исцеление». Потом к распорядителю полётов.",
                   en = "From Keldran to the Valley of Wisdom: level 38 and 40 training - mail and Chain Heal. Then to "
                       .. "the flight master." } },
    },
})
insert({
    after = "h-44-stonard-arrive",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-44", train = true, npc = 986, at = HAROMM,
          spells = { rank("Цепная молния", "Chain Lightning"), rank("Тотем неистовства ветра", "Windfury Totem"),
                     rank("Волна исцеления", "Healing Wave") },
          note = { ru = "Харомм, тренер шаманов Каменора, рядом: обучение 42-го и 44-го уровней.",
                   en = "Haromm, the Stonard shaman trainer, right here: level 42 and 44 training." } },
    },
})
insert({
    after = "h46-fly-freewind",
    class = "SHAMAN",
    steps = {
        { id = "sha-prate", turnin = 1532, optional = true, npc = 5905, at = PRATE,
          note = { ru = "Необязательно: Прейт Ясновидец Облаков, около 420 м на северо-восток от Заставы Вольного Ветра "
                       .. "— ТОТЕМ ВОЗДУХА. Потом обратно к распорядителю полётов.",
                   en = "Optional: Prate Cloudseer, about 420 yards north-east of Freewind Post - the AIR TOTEM. Then "
                       .. "back to the flight master." } },
        { id = "sha-prate-back", go = true, optional = true, radius = 30, npc = 4317, at = FREEWIND,
          note = { ru = "Обратно на Заставу Вольного Ветра.", en = "Back to Freewind Post." } },
    },
})
insert({
    after = "h-50-org-arrive",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-48", train = true, npc = ORG_TRAINERS, at = KARDRIS,
          spells = { rank("Цепное исцеление", "Chain Heal"), rank("Молния", "Lightning Bolt"),
                     rank("Земной шок", "Earth Shock") },
          note = { ru = "Из Аллеи Духов на север в Аллею Мудрости: обучение 46-го и 48-го уровней.",
                   en = "From the Valley of Spirits north to the Valley of Wisdom: level 46 and 48 training." } },
    },
})
insert({
    after = "h-51-stonard",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-50", train = true, npc = 986, at = HAROMM,
          spells = { rank("Оружие неистовства ветра", "Windfury Weapon"), rank("Волна исцеления", "Healing Wave") },
          note = { ru = "Харомм, рядом: обучение 50-го уровня.", en = "Haromm, right here: level 50 training." } },
    },
})
insert({
    after = "h-53-org-arrive",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-52", train = true, npc = ORG_TRAINERS, at = KARDRIS,
          spells = { rank("Молния", "Lightning Bolt"), rank("Цепная молния", "Chain Lightning") },
          note = { ru = "Аллея Мудрости по пути к таверне: обучение 52-го уровня.",
                   en = "The Valley of Wisdom on the way to the inn: level 52 training." } },
    },
})
insert({
    after = "h-56-org-arrive",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-54", train = true, npc = ORG_TRAINERS, at = KARDRIS,
          spells = { rank("Земной шок", "Earth Shock"), rank("Цепное исцеление", "Chain Heal") },
          note = { ru = "Аллея Мудрости по пути к таверне: обучение 54-го уровня.",
                   en = "The Valley of Wisdom on the way to the inn: level 54 training." } },
    },
})
insert({
    after = "h-58-org-arrive",
    class = "SHAMAN",
    steps = {
        { id = "sha-train-56", train = true, npc = ORG_TRAINERS, at = KARDRIS,
          spells = { rank("Молния", "Lightning Bolt"), rank("Волна исцеления", "Healing Wave") },
          note = { ru = "От таверны в Аллею Мудрости: обучение 56-го уровня. Потом из ворот к дирижаблю.",
                   en = "From the inn to the Valley of Wisdom: level 56 training. Then out of the gate to the "
                       .. "zeppelin." } },
    },
})
insert({
    after = "h-60-end",
    class = "SHAMAN",
    steps = {
        { id = "sha-60-hearth", hearth = "Undercity", optional = true, at = { 1458, 67.74, 37.89 },
          note = { ru = "После 60-го: камень возвращения в Подгород (шаманов там не учат).",
                   en = "After 60: hearth to Undercity (no shaman trainer there)." } },
        { id = "sha-60-zeppelin", go = true, optional = true, radius = 40, npc = 9566, at = { 1420, 60.74, 58.87 },
          note = { ru = "К башне дирижаблей у Подгорода: дирижабль в Оргриммар.",
                   en = "To the zeppelin tower by Undercity: the zeppelin to Orgrimmar." } },
        { id = "sha-60-durotar", go = true, optional = true, radius = 40, npc = 12136, at = { 1411, 50.69, 12.89 },
          note = { ru = "Прилёт к башне в Дуротаре, дальше в Оргриммар.",
                   en = "Arrival at the Durotar tower, then into Orgrimmar." } },
        { id = "sha-60-train", train = true, optional = true, npc = ORG_TRAINERS, at = KARDRIS,
          spells = { rank("Цепное исцеление", "Chain Heal"), rank("Молния", "Lightning Bolt") },
          note = { ru = "Аллея Мудрости (Кардрис): обучение 58-го и 60-го уровней.",
                   en = "The Valley of Wisdom (Kardris): level 58 and 60 training." } },
    },
})
