-- FastesBoooy_Guides / Classes / Hunter.lua
--
-- Every step that exists because of the class (hunter), for all four hunter races (Orc, Troll, Tauren, Skyborne), as
-- shared inserts with class scope (step ids "hun-..."; below level 12 one group per start zone: "hun-dur-..." Durotar
-- for Orc and Troll, "hun-mul-..." Mulgore for the Tauren, "hun-zep-..." Zephras Isle for the Skyborne). Every insert
-- is anchored on a step with an explicit id of a start-zone or shared segment; the inserted steps belong to the
-- anchor's segment. Phase C of docs/dev/PLAN.md (D.5); research docs/dev/research/classes.md 5.2, 6.3.
-- Facts (NPC ids and positions, quest ids, chains, race masks, taming rods, beast spawns): tools/data/forever_db.lua.
-- Spell levels: classes.md 5.2 (the web list for Forever) for the key ones; the others are the trainer lists of the
-- original game and only shown as text (the core never reads `spells`). CONFIRM in game.
--
-- What the class does here, speed first: the letter at level 1 (zero detour), the pet chain at 10 (key ability,
-- 2,940 XP of class quests on top: three tames next to the trainer and back), training at stops the path makes
-- anyway (every Orgrimmar / Thunder Bluff / Grom'gol / Stonard stop of classes.md 4.2 where two levels or a key spell
-- have come since the last visit), one optional weapon skill and the optional Hunter's Charm at 53.
--
-- Start zones (level before the first step of the insert: validator --levels of the hunter route, normal run; the
-- worst case, no optional step, is the same below 12):
--   Durotar (Orc, Troll)
--     after dur01-teeth        2.33   the letter 3087 (Orc) / 3082 (Troll) at Gornek > Jen'shan (nothing to train at 2)
--     after dur01-den-4        4.68   Jen'shan: training 4 (start-camp trainers teach up to 6)
--     after dur02-garthok      6.45   Thotar in Razor Hill (5 yd from Garthok): training 6
--     after dur02-garthok-3    9.67   Thotar: training 8 (the shared path passes him on the hearth visit)
--     after dur02-rh-3        10.00   Thotar: training 10 + the pet chain 6062 > 6083 > 6082 > 6081 (the gate
--                                     dur02-lvl-10 guarantees the level): boar 90 yd, surf crawler 650 yd (north-east
--                                     coast, the nearest spawn), scorpid 210 yd, each time back to Thotar (~1,900 yd,
--                                     ~5 min with the three tames, for 2,940 XP and the pet)
--   Mulgore (Tauren)
--     after mul01-hunt         3.14   the letter 3092 at Grull Hawkwind > Lanka Farshot
--     after mul01-ravine       4.12   Lanka Farshot: training 4 (the gate mul01-lvl-4 stands in front)
--     after mul02-yaw          6.78   Yaw Sharpmane in Bloodhoof: training 6, after the generic accept of 96130 at
--                                     him (look-ahead rule; the turn-in of 96130 is 9 steps later)
--     after mul02-bh-5        10.56   Yaw: training 8 + 10 + the pet chain 6061 > 6087 > 6088 > 6089: plainstrider,
--                                     prairie stalker, swoop, all 200-260 yd north of Yaw (the path goes north next)
--     after mul03-melor       12.05   Holt Thunderhorn on Hunter Rise (80 yd from Melor): 6089 turned in
--   Zephras Isle (Skyborne)
--     after sd01-rorian        3.02   the letter 92482 at Rorian > Tai'ree Farsight (read the Scribbled Note)
--     after sd01-thendal-4     4.77   Tai'ree: training 4
--     after sd01-raan-2        6.36   Elayaa Easewind in Shen'dar (on the way to Aonda): training 6
--     after sd01-danarii-2     8.91   Elayaa: training 8
--     after sd02-riaani       10.43   Quel'ana Quickgale in Valanaar (50 yd from Riaani): a class-scoped level-10 step,
--                                     training 10 + the pet chain 94978 > 94979 > 94013 > 94050; the three beasts have
--                                     spawns right next to her (and in the meadows around Valanaar), the last turn-in
--                                     is at the pet trainer Quel'dora next to her
--     after sd02-hearth  12.90/12.83   Quel'ana: training 12 (the hearth lands in Valanaar)
--
-- Shared path (level before the insert, hunter routes of the four races, normal / worst case where they differ):
--   12     after h12-whuut        Orc / Troll 11.81: 6081 turned in at Ormak Grimshot (Valley of Honor, ~350 yd off the
--                                 city walk): Tame Beast, Call / Feed / Revive Pet, Beast Training.
--                                 Tauren 12.59: training 12 at Ormak. (Skyborne trained 12 in Valanaar.)
--   12+14  after h15-org          Orc / Troll 14.33 / 14.26: Ormak (~1,000 yd: from the inn to the Valley of Honor and
--                                 out of the main gate), the plan's B.9 visit for hunter and shaman.
--   16+18  after h18-tb-1         18.19-18.78 / 18.05-18.50: Hunter Rise, Thunder Bluff (the gate h18-lvl-18), back to
--                                 the flight master (~600 yd). h18-fp-tb is race-filtered: not an anchor.
--   20     after h18-sethearth-tb 20.45-20.90 / 20.25-20.58: Hunter Rise from the inn on the way to Elder Rise (~250 yd more):
--                                 ASPECT OF THE CHEETAH. Optional before it: Guns / Staves at Ansekhwa next to the inn.
--   22-26  after h-27-hearth-tb   27.30-27.45 / 27.06: Hunter Rise between the inn and Zamah (~400 yd more): Rapid Fire.
--   28+30  after h30-tb-1131      30.96: Hunter Rise, 80 yd from Melor (no detour): Feign Death.
--   32+34  after h34-sethearth-gromgol 34.12: Kragg, Grom'gol (next to the innkeeper).
--   36     after h-37-org-arrive  36.06 (optional): Ormak, ~600 yd more on the way to Keldran.
--   38+40  after h-40-org-arrive  40.06 / 40.01: Ormak (~900 yd: Keldran > Valley of Honor > flight master); the Orc
--                                 riding steps of Races/Orc.lua follow right next to him (Kildar). Mail at 40.
--   42+44  after h44-sethearth-gromgol 44.02 / 44.00: Kragg (no detour).
--   46+48  after h49-org-2976     49.53 / 49.49: Ormak, on the way from the Valley of Honor to the zeppelin.
--   50+52  after h52-stonard-1445 52.57 / 52.53: Ogromm, Stonard (no detour; the first Stonard stop at 51.79 is merged).
--   Hunter's Charm (optional, 5,610 XP): 8151 at Ormak after h-53-org-arrive (52.73), Ogtinc in Azshara before
--                                 h-53-azshara-field-loop, 8153 (2 Perfect Courser Antlers, Mosshoof Coursers south
--                                 of the field loop, drop rate unknown) and the turn-in after h-53-azshara-field-loop:
--                                 ~2.5 min of travel.
--   54     after h-56-org-arrive  55.07: Ormak (~400 yd more on the way to the inn).
--   56     after h-58-org-arrive  57.21 / 57.17: Ormak, then out of the main gate to the zeppelin (~1,000 yd more).
--   58+60  after h-60-end         optional: hearth to Undercity, zeppelin to Durotar, Ormak (the route ends at 60).
-- Not visited: 14 for Tauren / Skyborne (Scare Beast, Eyes of the Beast: not worth the h15-org detour); 22 and 24
--   (Thunder Bluff and Orgrimmar at 22.05, Thunder Bluff at 24.82: one rank each, merged into 26); 28 at h-28 (27.91
--   in the worst case: merged into 30); the Orgrimmar stops at 31.05, 41.01, 52.70, 53.05 and the hunter-less
--   Undercity stops; Stonard at 44.03 and Grom'gol at 44.5-45.3 (46 not reached).
-- Skipped class quests: the breadcrumbs 6065-6070 (85 XP each; their givers are in other cities or Sen'jin, before
--   level 10 on the path), 94007 (Shen'dar at level 10 is not on the path), 8231 / 8232 (Wavethrasher Scales in the
--   bays of Azshara, then the Sunken Temple). Pet trainers (Harruk, Reban Freerunner, Xao'tsu, Hesuwa, Zudd, Grokor):
--   not routed; the notes of the Orgrimmar and Thunder Bluff visits point to them for Growl ranks.
-- Class reward table: none. The DB snapshot has no reward lists; a wrong index would make the automation take the
--   wrong item. The notes of the training steps say what to look for (agility, ranged weapons).
--
-- Automation notes: a training step at an NPC who also hands out a quest of this file is merged with that accept
-- (hun-*-train-10), so the automation cannot take the quest first and fast-forward the visit; the trainers hand out
-- no quest of the shared path except Yaw Sharpmane (96130, accepted before the level-6 visit). Every insert follows a
-- step the player has just done (an arrival, a hearth, a turn-in) and leaves the path where it was or before a
-- shared `fly` / `go` that works from the trainer.

if not FastesBoooy.AddLibraryInsert then return end
local insert = FastesBoooy.AddLibraryInsert

local GORNEK = { 1411, 42.06, 68.33 }
local JENSHAN = { 1411, 42.84, 69.33 }
local THOTAR = { 1411, 51.85, 43.49 }
local GRULL = { 1412, 44.47, 77.50 }
local LANKA = { 1412, 43.96, 76.35 }
local YAW = { 1412, 46.93, 59.65 }
local RORIAN = { 2521, 42.05, 23.49 }
local TAIREE = { 2521, 42.49, 23.79 }
local ELAYAA = { 2521, 45.26, 44.24 }
local QUELANA = { 2521, 59.56, 72.63 }
local QUELDORA = { 2521, 59.92, 72.87 }
local ORMAK = { 1454, 66.05, 18.53 }
local ORG_TRAINERS = { 3352, 3406, 3407 }        -- Ormak Grimshot, Xor'juul, Sian'dur (Valley of Honor)
local HOLT = { 1456, 57.30, 89.79 }
local KARY = { 1456, 58.49, 88.33 }
local TB_TRAINERS = { 3038, 3039, 3040 }         -- Kary Thunderhorn, Holt Thunderhorn, Urek Thunderhorn (Hunter Rise)
local KRAGG = { 1434, 31.23, 28.68 }
local OGROMM = { 1435, 47.26, 53.43 }
local OGTINC = { 1447, 42.40, 42.62 }

local function spell(ru, en) return { ru = ru, en = en } end
local NEW = { ru = " (новый ранг)", en = " (new rank)" }
local function rank(ru, en) return { ru = ru .. NEW.ru, en = en .. NEW.en } end

------------------------------------------------------------------------------------------------------------------
-- Durotar (Orc, Troll) ------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- The letter: Gornek hands it out in the dialog of the shared turn-in of 788; Jen'shan stands in the Den next to him.
insert({
    after = "dur01-teeth",
    class = "HUNTER",
    race = "Orc",
    steps = {
        { id = "hun-dur-letter-orc", accept = 3087, npc = 3143, at = GORNEK,
          note = { ru = "Горнек даёт и письмо охотника: «Гравированный пергамент».",
                   en = "Gornek also has the hunter's letter: Etched Parchment." } },
        { id = "hun-dur-jenshan-orc", turnin = 3087, npc = 3154, at = JENSHAN,
          note = { ru = "Джен'шан — тренер охотников, в Логове рядом с Горнеком. Учить пока нечего (следующее — на 4-м).",
                   en = "Jen'shan, the hunter trainer, in the Den next to Gornek. Nothing to train yet (next at 4)." } },
    },
})
insert({
    after = "dur01-teeth",
    class = "HUNTER",
    race = "Troll",
    steps = {
        { id = "hun-dur-letter-troll", accept = 3082, npc = 3143, at = GORNEK,
          note = { ru = "Горнек даёт и письмо охотника: «Гравированная табличка».",
                   en = "Gornek also has the hunter's letter: Etched Tablet." } },
        { id = "hun-dur-jenshan-troll", turnin = 3082, npc = 3154, at = JENSHAN,
          note = { ru = "Джен'шан — тренер охотников, в Логове рядом с Горнеком. Учить пока нечего (следующее — на 4-м).",
                   en = "Jen'shan, the hunter trainer, in the Den next to Gornek. Nothing to train yet (next at 4)." } },
    },
})
insert({
    after = "dur01-den-4",
    class = "HUNTER",
    race = { "Orc", "Troll" },
    steps = {
        { id = "hun-dur-train-4", train = true, npc = 3154, at = JENSHAN,
          spells = { spell("Укус змеи", "Serpent Sting"), spell("Дух обезьяны", "Aspect of the Monkey") },
          note = { ru = "Джен'шан, в двух шагах от Зуриты. «Укус змеи» — в начало каждого боя. Стреляйте с дистанции, "
                       .. "стрелы — у торговцев (Колючий Холм, Оргриммар).",
                   en = "Jen'shan, two steps from Zureetha. Serpent Sting opens every fight. Shoot from range; buy "
                       .. "arrows from vendors (Razor Hill, Orgrimmar)." } },
    },
})
insert({
    after = "dur02-garthok",
    class = "HUNTER",
    race = { "Orc", "Troll" },
    steps = {
        { id = "hun-dur-train-6", train = true, npc = 3171, at = THOTAR,
          spells = { spell("Чародейский выстрел", "Arcane Shot"), spell("Метка охотника", "Hunter's Mark") },
          note = { ru = "Тотар, тренер охотников Колючего Холма (рядом с Гартоком). Купите стрелы, если мало.",
                   en = "Thotar, the Razor Hill hunter trainer (next to Garthok). Buy arrows if you are low." } },
    },
})
insert({
    after = "dur02-garthok-3",
    class = "HUNTER",
    race = { "Orc", "Troll" },
    steps = {
        { id = "hun-dur-train-8", train = true, npc = 3171, at = THOTAR,
          spells = { spell("Контузящий выстрел", "Concussive Shot"), rank("Удар ящера", "Raptor Strike") },
          note = { ru = "Тотар рядом с Гартоком: обучение 8-го уровня.",
                   en = "Thotar next to Garthok: level 8 training." } },
    },
})
-- The pet chain. All three turn-ins are at Thotar, so the three beasts are tamed at the spawns nearest to him and the
-- path goes on afterwards (dur02-dustrunners, west).
insert({
    after = "dur02-rh-3",
    class = "HUNTER",
    race = { "Orc", "Troll" },
    steps = {
        { id = "hun-dur-train-10", train = true, accept = 6062, npc = 3171, at = THOTAR,
          spells = { spell("Дух ястреба", "Aspect of the Hawk"), rank("Укус змеи", "Serpent Sting") },
          note = { ru = "Тотар: обучение 10-го уровня и «Приручение зверя» (Taming the Beast) — цепочка питомца. "
                       .. "Возьмите задание, потом откройте окно обучения.",
                   en = "Thotar: level 10 training and Taming the Beast, the pet chain. Take the quest, then open the "
                       .. "training window." } },
        { id = "hun-dur-boar", complete = 6062, use = 15917, at = { 1411, 51.7, 46.0 },
          note = { ru = "Жезл приручения (кнопка задания) на Матёрого пятнистого вепря — ближайшие пасутся сразу к югу "
                       .. "от Колючего Холма. Пока идёт приручение, зверь не должен вас бить: начинайте издалека.",
                   en = "Taming Rod (quest item button) on a Dire Mottled Boar, just south of Razor Hill. The beast "
                       .. "must not hit you during the cast: start from range." } },
        { id = "hun-dur-6083", turnin = 6062, accept = 6083, npc = 3171, at = THOTAR,
          note = { ru = "Обратно к Тотару: следующий зверь — прибрежный краб.",
                   en = "Back to Thotar: the next beast is a Surf Crawler." } },
        { id = "hun-dur-crawler", complete = 6083, use = 15919, at = { 1411, 58.9, 28.3 },
          note = { ru = "На северо-восток к берегу (~650 ярдов): Прибрежный краб, ближайшие — у 59,28.",
                   en = "North-east to the coast (~650 yd): a Surf Crawler, the nearest ones around 59,28." } },
        { id = "hun-dur-6082", turnin = 6083, accept = 6082, npc = 3171, at = THOTAR,
          note = { ru = "Обратно к Тотару: последний зверь — бронированный скорпид.",
                   en = "Back to Thotar: the last beast is an Armored Scorpid." } },
        -- CONFIRM: the beast tamed with the Taming Rod stays as the hunter's pet (as in the original game)
        { id = "hun-dur-scorpid", complete = 6082, use = 15920, at = { 1411, 51.0, 37.7 },
          note = { ru = "Бронированный скорпид к северу от Колючего Холма (51,38). Прирученный зверь остаётся вашим "
                       .. "питомцем — скорпид хорошо держит удары.",
                   en = "An Armored Scorpid north of Razor Hill (51,38). The tamed beast stays with you as your pet; "
                       .. "the scorpid takes hits well." } },
        { id = "hun-dur-6081", turnin = 6082, accept = 6081, npc = 3171, at = THOTAR,
          note = { ru = "Тотар: «Обучение зверя» — сдаётся Ормаку в Оргриммаре, путь и так туда идёт.",
                   en = "Thotar: Training the Beast, turned in to Ormak in Orgrimmar, where the path goes anyway." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Mulgore (Tauren) ----------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
insert({
    after = "mul01-hunt",
    class = "HUNTER",
    race = "Tauren",
    steps = {
        { id = "hun-mul-letter", accept = 3092, npc = 2980, at = GRULL,
          note = { ru = "Грулл Ястребиный Ветер даёт и письмо охотника: «Гравированная записка».",
                   en = "Grull Hawkwind also has the hunter's letter: Etched Note." } },
        { id = "hun-mul-lanka", turnin = 3092, npc = 3061, at = LANKA,
          note = { ru = "Ланка Дальний Выстрел — тренер охотников лагеря Нараче, в двух шагах. Учить пока нечего.",
                   en = "Lanka Farshot, the Camp Narache hunter trainer, a few steps away. Nothing to train yet." } },
    },
})
insert({
    after = "mul01-ravine",
    class = "HUNTER",
    race = "Tauren",
    steps = {
        { id = "hun-mul-train-4", train = true, npc = 3061, at = LANKA,
          spells = { spell("Укус змеи", "Serpent Sting"), spell("Дух обезьяны", "Aspect of the Monkey") },
          note = { ru = "Ланка рядом с Груллом. «Укус змеи» — в начало каждого боя; патроны — у торговцев.",
                   en = "Lanka next to Grull. Serpent Sting opens every fight; buy ammunition from vendors." } },
    },
})
insert({
    after = "mul02-yaw",
    class = "HUNTER",
    race = "Tauren",
    steps = {
        { id = "hun-mul-train-6", train = true, npc = 3065, at = YAW,
          spells = { spell("Чародейский выстрел", "Arcane Shot"), spell("Метка охотника", "Hunter's Mark") },
          note = { ru = "Яу Острогривый (у него же «Чакуяк»): обучение 6-го уровня. Патроны — у Кенны Соколиный Глаз "
                       .. "в деревне.",
                   en = "Yaw Sharpmane (who also gave Chakuyak): level 6 training. Ammunition: Kennah Hawkseye in the "
                       .. "village." } },
    },
})
-- The pet chain: the three beasts graze north of Yaw, where the path goes next.
insert({
    after = "mul02-bh-5",
    class = "HUNTER",
    race = "Tauren",
    steps = {
        { id = "hun-mul-train-10", train = true, accept = 6061, npc = 3065, at = YAW,
          spells = { spell("Контузящий выстрел", "Concussive Shot"), rank("Удар ящера", "Raptor Strike"),
                     spell("Дух ястреба", "Aspect of the Hawk"), rank("Укус змеи", "Serpent Sting") },
          note = { ru = "Яу на северном краю деревни: обучение 8-го и 10-го уровней и «Приручение зверя» — цепочка "
                       .. "питомца. Возьмите задание, потом откройте окно обучения.",
                   en = "Yaw at the north edge of the village: level 8 and 10 training and Taming the Beast, the pet "
                       .. "chain. Take the quest, then open the training window." } },
        { id = "hun-mul-plainstrider", complete = 6061, use = 15914, at = { 1412, 43.5, 56.1 },
          note = { ru = "Жезл приручения (кнопка задания) на Взрослого долгонога к северо-западу от Яу. Начинайте "
                       .. "издалека: зверь не должен вас бить, пока идёт приручение.",
                   en = "Taming Rod (quest item button) on an Adult Plainstrider north-west of Yaw. Start from range: "
                       .. "the beast must not hit you during the cast." } },
        { id = "hun-mul-6087", turnin = 6061, accept = 6087, npc = 3065, at = YAW,
          note = { ru = "Обратно к Яу: следующий — степной охотник.", en = "Back to Yaw: next, a Prairie Stalker." } },
        { id = "hun-mul-stalker", complete = 6087, use = 15915, at = { 1412, 46.5, 54.9 },
          note = { ru = "Степной охотник к северу от Яу (46,55).", en = "A Prairie Stalker north of Yaw (46,55)." } },
        { id = "hun-mul-6088", turnin = 6087, accept = 6088, npc = 3065, at = YAW,
          note = { ru = "Обратно к Яу: последний — Налётчик.", en = "Back to Yaw: the last one is a Swoop." } },
        { id = "hun-mul-swoop", complete = 6088, use = 15916, at = { 1412, 45.5, 54.6 },
          note = { ru = "Налётчик к северу от Яу (45,55). Прирученный зверь остаётся вашим питомцем.",
                   en = "A Swoop north of Yaw (45,55). The tamed beast stays with you as your pet." } },
        { id = "hun-mul-6089", turnin = 6088, accept = 6089, npc = 3065, at = YAW,
          note = { ru = "Яу: «Обучение зверя» — сдаётся Холту на Вершине Охотников в Громовом Утёсе, путь туда идёт.",
                   en = "Yaw: Training the Beast, turned in to Holt on Hunter Rise in Thunder Bluff, where the path "
                       .. "goes." } },
    },
})
insert({
    after = "mul03-melor",
    class = "HUNTER",
    race = "Tauren",
    steps = {
        { id = "hun-mul-holt", turnin = 6089, npc = 3039, at = HOLT,
          note = { ru = "Холт Громовой Рог на Вершине Охотников, в двух шагах от Мелора: «Приручение зверя», "
                       .. "«Призыв питомца», «Кормление питомца», «Дрессировка».",
                   en = "Holt Thunderhorn on Hunter Rise, a few steps from Melor: Tame Beast, Call Pet, Feed Pet, "
                       .. "Beast Training." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Zephras Isle (Skyborne) ---------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- Rorian gives the letter in the dialog of the shared step; Tai'ree stands next to him.
insert({
    after = "sd01-rorian",
    class = "HUNTER",
    race = "Skyborne",
    steps = {
        { id = "hun-zep-letter", accept = 92482, npc = 251361, at = RORIAN,
          note = { ru = "Rorian даёт и классовое задание охотника: «Путь охотника» (The Way of the Hunter).",
                   en = "Rorian also gives the hunter class quest: The Way of the Hunter." } },
        { id = "hun-zep-tairee", turnin = 92482, use = 282421, npc = 251376, at = TAIREE,
          note = { ru = "Прочитайте «Нацарапанную записку» (сумка), затем поговорите с Tai'ree Farsight рядом.",
                   en = "Read the Scribbled Note from your bags, then talk to Tai'ree Farsight next to him." } },
    },
})
insert({
    after = "sd01-thendal-4",
    class = "HUNTER",
    race = "Skyborne",
    steps = {
        { id = "hun-zep-train-4", train = true, npc = 251376, at = TAIREE,
          spells = { spell("Укус змеи", "Serpent Sting"), spell("Дух обезьяны", "Aspect of the Monkey") },
          note = { ru = "Tai'ree у Rorian: обучение 4-го уровня (тренеры Thendal учат до 6-го).",
                   en = "Tai'ree by Rorian: level 4 training (the Thendal trainers teach up to 6)." } },
    },
})
insert({
    after = "sd01-raan-2",
    class = "HUNTER",
    race = "Skyborne",
    steps = {
        { id = "hun-zep-train-6", train = true, npc = 254084, at = ELAYAA,
          spells = { spell("Чародейский выстрел", "Arcane Shot"), spell("Метка охотника", "Hunter's Mark") },
          note = { ru = "Elayaa Easewind в Shen'dar, по пути к Aonda: обучение 6-го уровня.",
                   en = "Elayaa Easewind in Shen'dar, on the way to Aonda: level 6 training." } },
    },
})
insert({
    after = "sd01-danarii-2",
    class = "HUNTER",
    race = "Skyborne",
    steps = {
        { id = "hun-zep-train-8", train = true, npc = 254084, at = ELAYAA,
          spells = { spell("Контузящий выстрел", "Concussive Shot"), rank("Удар ящера", "Raptor Strike") },
          note = { ru = "Elayaa рядом с Danarii: обучение 8-го уровня.",
                   en = "Elayaa next to Danarii: level 8 training." } },
    },
})
-- The pet chain at the first Valanaar visit: the beasts roam right around the hunter trainer.
insert({
    after = "sd02-riaani",
    class = "HUNTER",
    race = "Skyborne",
    steps = {
        { id = "hun-zep-level-10", level = 10, at = QUELANA,
          note = { ru = "Цепочке питомца нужен 10-й уровень: если не хватает, добейте пару зверей вокруг Valanaar.",
                   en = "The pet chain needs level 10: if you are short, kill a few beasts around Valanaar." } },
        { id = "hun-zep-train-10", train = true, accept = 94978, npc = 252389, at = QUELANA,
          spells = { spell("Дух ястреба", "Aspect of the Hawk"), rank("Укус змеи", "Serpent Sting") },
          note = { ru = "Quel'ana Quickgale, тренер охотников Valanaar (в двух шагах от Riaani): обучение 10-го уровня "
                       .. "и «Приручение зверя». Возьмите задание, потом откройте окно обучения.",
                   en = "Quel'ana Quickgale, the Valanaar hunter trainer (a few steps from Riaani): level 10 training "
                       .. "and Taming the Beast. Take the quest, then open the training window." } },
        -- CONFIRM: the three Zephras beasts have spawns right at Quel'ana in Valanaar (DB; fallback: south-west of the isle)
        { id = "hun-zep-crawler", complete = 94978, use = 267272, at = { 2521, 59.4, 73.5 },
          note = { ru = "Жезл приручения (кнопка задания) на Windsong Crawler — рядом с Quel'ana и на лугах вокруг "
                       .. "Valanaar. Начинайте издалека: зверь не должен вас бить, пока идёт приручение.",
                   en = "Taming Rod (quest item button) on a Windsong Crawler, next to Quel'ana and in the meadows "
                       .. "around Valanaar. Start from range: the beast must not hit you during the cast." } },
        { id = "hun-zep-94979", turnin = 94978, accept = 94979, npc = 252389, at = QUELANA,
          note = { ru = "Обратно к Quel'ana: следующий — Ornery Galestrider.",
                   en = "Back to Quel'ana: next, an Ornery Galestrider." } },
        { id = "hun-zep-galestrider", complete = 94979, use = 267298, at = { 2521, 59.4, 73.5 },
          note = { ru = "Ornery Galestrider — там же, вокруг Valanaar.",
                   en = "An Ornery Galestrider, around Valanaar as well." } },
        { id = "hun-zep-94013", turnin = 94979, accept = 94013, npc = 252389, at = QUELANA,
          note = { ru = "Обратно к Quel'ana: последний — Vuldren Alpha (10-й уровень).",
                   en = "Back to Quel'ana: the last one is a Vuldren Alpha (level 10)." } },
        { id = "hun-zep-alpha", complete = 94013, use = 264163, at = { 2521, 59.4, 73.5 },
          note = { ru = "Vuldren Alpha вокруг Valanaar. Прирученный зверь остаётся вашим питомцем.",
                   en = "A Vuldren Alpha around Valanaar. The tamed beast stays with you as your pet." } },
        { id = "hun-zep-94050", turnin = 94013, accept = 94050, npc = 252389, at = QUELANA,
          note = { ru = "Quel'ana: «Обучение зверя» — у её сестры рядом.",
                   en = "Quel'ana: Training the Beast, at her sister next to her." } },
        { id = "hun-zep-queldora", turnin = 94050, npc = 254411, at = QUELDORA,
          note = { ru = "Quel'dora Quickgale, тренер питомцев рядом: «Приручение зверя», «Призыв питомца», "
                       .. "«Кормление питомца».",
                   en = "Quel'dora Quickgale, the pet trainer next to her: Tame Beast, Call Pet, Feed Pet." } },
    },
})
insert({
    after = "sd02-hearth",
    class = "HUNTER",
    race = "Skyborne",
    steps = {
        { id = "hun-zep-train-12", train = true, npc = 252389, at = QUELANA,
          spells = { spell("Лечение питомца", "Mend Pet"), spell("Подрезать крылья", "Wing Clip"),
                     rank("Чародейский выстрел", "Arcane Shot"), spell("Отвлекающий выстрел", "Distracting Shot") },
          note = { ru = "От таверны к Quel'ana на запад деревни: обучение 12-го уровня. Следующее обучение — в "
                       .. "Громовом Утёсе на 18-м.",
                   en = "From the inn west to Quel'ana: level 12 training. The next training is in Thunder Bluff "
                       .. "at 18." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 12-22 ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- Orgrimmar at 11-12: Ormak Grimshot in the Valley of Honor, between Whuut and the Valley of Wisdom.
insert({
    after = "h12-whuut",
    class = "HUNTER",
    race = { "Orc", "Troll", "Tauren" },
    steps = {
        { id = "hun-12-ormak", turnin = 6081, npc = 3352, at = ORMAK, race = { "Orc", "Troll" },
          note = { ru = "На северо-восток в Аллею Чести, к Ормаку Мрачный Выстрел: «Обучение зверя» — «Приручение "
                       .. "зверя», «Призыв питомца», «Кормление питомца», «Воскрешение питомца», «Дрессировка». Затем "
                       .. "на запад в Аллею Мудрости.",
                   en = "North-east to the Valley of Honor, Ormak Grimshot: Training the Beast - Tame Beast, Call Pet, "
                       .. "Feed Pet, Revive Pet, Beast Training. Then west to the Valley of Wisdom." } },
        { id = "hun-train-12", train = true, npc = ORG_TRAINERS, at = ORMAK, race = "Tauren",
          spells = { spell("Лечение питомца", "Mend Pet"), spell("Подрезать крылья", "Wing Clip"),
                     rank("Чародейский выстрел", "Arcane Shot"), spell("Отвлекающий выстрел", "Distracting Shot") },
          note = { ru = "На северо-восток в Аллею Чести к тренерам охотников (Ормак): обучение 12-го уровня. Затем на "
                       .. "запад в Аллею Мудрости.",
                   en = "North-east to the Valley of Honor, the hunter trainers (Ormak): level 12 training. Then west "
                       .. "to the Valley of Wisdom." } },
    },
})
insert({
    after = "h15-org",
    class = "HUNTER",
    race = { "Orc", "Troll" },
    steps = {
        { id = "hun-train-14", train = true, npc = ORG_TRAINERS, at = ORMAK,
          spells = { spell("Лечение питомца", "Mend Pet"), spell("Подрезать крылья", "Wing Clip"),
                     rank("Чародейский выстрел", "Arcane Shot"), spell("Отпугивание зверя", "Scare Beast") },
          note = { ru = "Из таверны на северо-восток в Аллею Чести (Ормак): обучение 12-го и 14-го уровней. "
                       .. "Тренер питомцев Сяо'цу стоит рядом (ранги «Рыка»). Потом к главным воротам.",
                   en = "From the inn north-east to the Valley of Honor (Ormak): level 12 and 14 training. The pet "
                       .. "trainer Xao'tsu is next door (Growl ranks). Then to the main gate." } },
    },
})
-- Thunder Bluff at 18: after the shared step at the foot of Spirit Rise (h18-fp-tb is race-filtered).
insert({
    after = "h18-tb-1",
    class = "HUNTER",
    steps = {
        { id = "hun-train-18", train = true, npc = TB_TRAINERS, at = KARY,
          spells = { spell("Залп", "Multi-Shot"), spell("Укус мангуста", "Mongoose Bite"),
                     spell("Обжигающая ловушка", "Immolation Trap"), rank("Укус змеи", "Serpent Sting"),
                     rank("Дух ястреба", "Aspect of the Hawk") },
          note = { ru = "Через мосты на Вершину Охотников (юг города), к тренерам охотников: обучение 16-го и 18-го "
                       .. "уровней — «Залп». Потом обратно к распорядителю полётов в центре.",
                   en = "Over the bridges to Hunter Rise (south of the city), the hunter trainers: level 16 and 18 "
                       .. "training - Multi-Shot. Then back to the flight master in the centre." } },
    },
})
insert({
    after = "h18-sethearth-tb",
    class = "HUNTER",
    steps = {
        { id = "hun-guns", train = true, optional = true, npc = 11869, at = { 1456, 40.93, 62.73 },
          note = { ru = "Необязательно: Ансекхва, мастер оружия у таверны — «Огнестрельное оружие» (если ещё не умеете) "
                       .. "и «Посохи», по 10 серебра: в наградах заданий встречаются и ружья, и луки.",
                   en = "Optional: Ansekhwa, the weapon master by the inn - Guns (if you cannot use them yet) and "
                       .. "Staves, 10 silver each: quest rewards include both guns and bows." } },
        { id = "hun-train-20", train = true, npc = TB_TRAINERS, at = KARY,
          spells = { spell("Дух гепарда", "Aspect of the Cheetah"), spell("Замораживающая ловушка", "Freezing Trap"),
                     rank("Чародейский выстрел", "Arcane Shot"), rank("Лечение питомца", "Mend Pet") },
          note = { ru = "От таверны на юг на Вершину Охотников: обучение 20-го уровня — «Дух гепарда» (+30% к скорости "
                       .. "бега вне боя: держите его на переходах). Потом на Вершину Старейшин.",
                   en = "From the inn south to Hunter Rise: level 20 training - Aspect of the Cheetah (+30% run speed "
                       .. "out of combat: keep it on between fights). Then on to Elder Rise." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 22-60 ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-27-hearth-tb",
    class = "HUNTER",
    steps = {
        { id = "hun-train-26", train = true, npc = TB_TRAINERS, at = KARY,
          spells = { spell("Быстрая стрельба", "Rapid Fire"), spell("Укус скорпида", "Scorpid Sting"),
                     rank("Метка охотника", "Hunter's Mark"), rank("Укус змеи", "Serpent Sting"),
                     rank("Удар ящера", "Raptor Strike") },
          note = { ru = "От таверны на Вершину Охотников: обучение 22-26-го уровней — «Быстрая стрельба». Потом к Замаху "
                       .. "в Пруды Видений.",
                   en = "From the inn to Hunter Rise: level 22-26 training - Rapid Fire. Then to Zamah in the Pools of "
                       .. "Vision." } },
    },
})
insert({
    after = "h30-tb-1131",
    class = "HUNTER",
    steps = {
        { id = "hun-train-30", train = true, npc = TB_TRAINERS, at = HOLT,
          spells = { spell("Притвориться мёртвым", "Feign Death"), rank("Залп", "Multi-Shot"),
                     rank("Укус мангуста", "Mongoose Bite"), rank("Дух ястреба", "Aspect of the Hawk"),
                     spell("Ледяная ловушка", "Frost Trap") },
          note = { ru = "Тренеры охотников — в двух шагах от Мелора: обучение 28-го и 30-го уровней — «Притвориться "
                       .. "мёртвым».",
                   en = "The hunter trainers are a few steps from Melor: level 28 and 30 training - Feign Death." } },
    },
})
insert({
    after = "h34-sethearth-gromgol",
    class = "HUNTER",
    steps = {
        { id = "hun-train-34", train = true, npc = 1404, at = KRAGG,
          spells = { spell("Взрывная ловушка", "Explosive Trap"), spell("Осветительная ракета", "Flare"),
                     rank("Укус змеи", "Serpent Sting"), rank("Укус скорпида", "Scorpid Sting") },
          note = { ru = "Крагг, тренер охотников Гром'гола, рядом с трактирщиком: обучение 32-го и 34-го уровней. "
                       .. "Тренер питомцев Зудд — рядом.",
                   en = "Kragg, the Grom'gol hunter trainer, next to the innkeeper: level 32 and 34 training. The pet "
                       .. "trainer Zudd stands next to him." } },
    },
})
insert({
    after = "h-37-org-arrive",
    class = "HUNTER",
    steps = {
        { id = "hun-train-36", train = true, optional = true, npc = ORG_TRAINERS, at = ORMAK,
          spells = { spell("Укус гадюки", "Viper Sting"), rank("Чародейский выстрел", "Arcane Shot"),
                     rank("Лечение питомца", "Mend Pet") },
          note = { ru = "Необязательно (~1,5 мин): Аллея Чести, обучение 36-го уровня. Иначе — всё на 40-м здесь же.",
                   en = "Optional (~1.5 min): the Valley of Honor, level 36 training. Otherwise everything at 40, "
                       .. "here as well." } },
    },
})
insert({
    after = "h-40-org-arrive",
    class = "HUNTER",
    steps = {
        -- CONFIRM: mail armour and Aspect of the Pack / Volley at 40 (spell levels of the original game)
        { id = "hun-train-40", train = true, npc = ORG_TRAINERS, at = ORMAK,
          spells = { spell("Дух стаи", "Aspect of the Pack"), spell("Град стрел", "Volley"),
                     spell("Кольчужные доспехи", "Mail"), rank("Дух ястреба", "Aspect of the Hawk"),
                     rank("Метка охотника", "Hunter's Mark") },
          note = { ru = "От Келдрана на северо-восток в Аллею Чести (Ормак): обучение 38-го и 40-го уровней — "
                       .. "кольчуга, «Дух стаи», «Град стрел» (если 40-го ещё нет — только ранги 38-го). Потом к "
                       .. "распорядителю полётов.",
                   en = "From Keldran north-east to the Valley of Honor (Ormak): level 38 and 40 training - mail, "
                       .. "Aspect of the Pack, Volley (not 40 yet: the level 38 ranks only). Then to the flight "
                       .. "master." } },
    },
})
insert({
    after = "h44-sethearth-gromgol",
    class = "HUNTER",
    steps = {
        { id = "hun-train-44", train = true, npc = 1404, at = KRAGG,
          spells = { rank("Залп", "Multi-Shot"), rank("Укус змеи", "Serpent Sting"),
                     rank("Чародейский выстрел", "Arcane Shot"), rank("Укус мангуста", "Mongoose Bite"),
                     rank("Лечение питомца", "Mend Pet") },
          note = { ru = "Крагг рядом с трактирщиком Гром'гола: обучение 42-го и 44-го уровней.",
                   en = "Kragg next to the Grom'gol innkeeper: level 42 and 44 training." } },
    },
})
insert({
    after = "h49-org-2976",
    class = "HUNTER",
    steps = {
        { id = "hun-train-48", train = true, npc = ORG_TRAINERS, at = ORMAK,
          spells = { spell("Дух дикой природы", "Aspect of the Wild"), rank("Дух ястреба", "Aspect of the Hawk"),
                     rank("Удар ящера", "Raptor Strike"), rank("Укус гадюки", "Viper Sting") },
          note = { ru = "По пути из Аллеи Чести к воротам — тренеры охотников (Ормак): обучение 46-го и 48-го уровней.",
                   en = "On the way from the Valley of Honor to the gate - the hunter trainers (Ormak): level 46 and "
                       .. "48 training." } },
    },
})
insert({
    after = "h52-stonard-1445",
    class = "HUNTER",
    steps = {
        { id = "hun-train-52", train = true, npc = 987, at = OGROMM,
          spells = { rank("Град стрел", "Volley"), rank("Укус змеи", "Serpent Sting"),
                     rank("Чародейский выстрел", "Arcane Shot"), rank("Лечение питомца", "Mend Pet") },
          note = { ru = "Огромм, тренер охотников Каменора, рядом: обучение 50-го и 52-го уровней.",
                   en = "Ogromm, the Stonard hunter trainer, close by: level 50 and 52 training." } },
    },
})
-- The Hunter's Charm (optional): 8151 at Ormak, Ogtinc in central Azshara on the way to the field loop, the Mosshoof
-- Coursers south of the loop, back to Ogtinc on the way to the next shared step. 8231 / 8232 are not taken.
insert({
    after = "h-53-org-arrive",
    class = "HUNTER",
    steps = {
        { id = "hun-8151-accept", accept = 8151, optional = true, npc = 3352, at = ORMAK,
          note = { ru = "Необязательно (~2,5 мин пути, 5,6 тыс. опыта): Ормак в Аллее Чести — «Амулет охотника» "
                       .. "(к Огтинку в Азшару).",
                   en = "Optional (~2.5 min of travel, 5.6k XP): Ormak in the Valley of Honor - The Hunter's Charm "
                       .. "(to Ogtinc in Azshara)." } },
    },
})
insert({
    before = "h-53-azshara-field-loop",
    class = "HUNTER",
    steps = {
        { id = "hun-8151-ogtinc", turnin = 8151, accept = 8153, optional = true, npc = 8405, at = OGTINC,
          note = { ru = "Огтинк на холме в центре Азшары (42,43), по пути на юго-запад: «Рога скакуна».",
                   en = "Ogtinc on the hill in central Azshara (42,43), on the way south-west: Courser Antlers." } },
    },
})
insert({
    after = "h-53-azshara-field-loop",
    class = "HUNTER",
    steps = {
        -- CONFIRM: drop rate of the Perfect Courser Antler (not in the DB)
        { id = "hun-8153-coursers", complete = 8153, optional = true, at = { 1447, 36.1, 65.8 },
          note = { ru = "Мшистокопытные скакуны к югу (36,66): 2 «Идеальных рога скакуна». Выпадают не с каждого — "
                       .. "если не везёт, бросьте задание.",
                   en = "Mosshoof Coursers to the south (36,66): 2 Perfect Courser Antlers. They do not drop from "
                       .. "every one - abandon the quest if you are unlucky." } },
        { id = "hun-8153-ogtinc", turnin = 8153, optional = true, npc = 8405, at = OGTINC,
          note = { ru = "Обратно к Огтинку. Следующее его задание («Волнорезы») не берите.",
                   en = "Back to Ogtinc. Do not take his next quest (Wavethrashing)." } },
    },
})
insert({
    after = "h-56-org-arrive",
    class = "HUNTER",
    steps = {
        { id = "hun-train-54", train = true, npc = ORG_TRAINERS, at = ORMAK,
          spells = { rank("Залп", "Multi-Shot"), rank("Удар ящера", "Raptor Strike"),
                     rank("Обжигающая ловушка", "Immolation Trap"), rank("Взрывная ловушка", "Explosive Trap") },
          note = { ru = "Аллея Чести (Ормак), по пути к таверне: обучение 54-го уровня.",
                   en = "The Valley of Honor (Ormak), on the way to the inn: level 54 training." } },
    },
})
insert({
    after = "h-58-org-arrive",
    class = "HUNTER",
    steps = {
        { id = "hun-train-56", train = true, npc = ORG_TRAINERS, at = ORMAK,
          spells = { rank("Дух дикой природы", "Aspect of the Wild"), rank("Чародейский выстрел", "Arcane Shot"),
                     rank("Укус гадюки", "Viper Sting") },
          note = { ru = "От таверны в Аллею Чести (Ормак): обучение 56-го уровня. Потом из главных ворот к дирижаблю.",
                   en = "From the inn to the Valley of Honor (Ormak): level 56 training. Then out of the main gate "
                       .. "to the zeppelin." } },
    },
})
-- After 60: the last ranks. The stone is bound in Undercity (h-58-uc-arrive); no hunter trainer there.
insert({
    after = "h-60-end",
    class = "HUNTER",
    steps = {
        { id = "hun-60-hearth", hearth = "Undercity", optional = true, at = { 1458, 67.74, 37.89 },
          note = { ru = "После 60-го: камень возвращения в Подгород (охотников там не учат).",
                   en = "After 60: hearth to Undercity (no hunter trainer there)." } },
        { id = "hun-60-zeppelin", go = true, optional = true, radius = 40, npc = 9566, at = { 1420, 60.74, 58.87 },
          note = { ru = "К башне дирижаблей у Подгорода: дирижабль в Оргриммар.",
                   en = "To the zeppelin tower by Undercity: the zeppelin to Orgrimmar." } },
        { id = "hun-60-durotar", go = true, optional = true, radius = 40, npc = 12136, at = { 1411, 50.69, 12.89 },
          note = { ru = "Прилёт к башне в Дуротаре, дальше в Оргриммар.",
                   en = "Arrival at the Durotar tower, then into Orgrimmar." } },
        { id = "hun-60-train", train = true, optional = true, npc = ORG_TRAINERS, at = ORMAK,
          spells = { rank("Укус змеи", "Serpent Sting"), rank("Залп", "Multi-Shot"),
                     rank("Чародейский выстрел", "Arcane Shot"), rank("Лечение питомца", "Mend Pet") },
          note = { ru = "Аллея Чести (Ормак): обучение 58-го и 60-го уровней.",
                   en = "The Valley of Honor (Ormak): level 58 and 60 training." } },
    },
})
