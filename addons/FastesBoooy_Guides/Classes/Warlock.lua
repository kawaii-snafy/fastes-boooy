-- FastesBoooy_Guides / Classes / Warlock.lua
--
-- Every step that exists because of the class (warlock), for all three warlock races (Orc, Troll, Undead = "Scourge"),
-- as shared inserts with class scope (step ids "wlk-..."; below level 12 one group per start zone: "wlk-dur-..."
-- Durotar for Orc and Troll, "wlk-tir-..." Tirisfal for the Undead). Every insert is anchored on a step with an explicit
-- id of a start-zone or shared segment. Phase C of docs/dev/PLAN.md (D.5); research docs/dev/research/classes.md 5.5,
-- 6.5. Facts (NPC ids and positions, quest ids, chains, race masks, objective spawns): tools/data/forever_db.lua.
-- Spell levels: classes.md 5.5 (the web list for Forever) for the key ones; the other ranks are the trainer lists of
-- the original game and only shown as text (the core never reads `spells`). CONFIRM in game.
--
-- What the class does here, speed first: the letter at level 1 (zero detour), the Imp (Durotar: 1485 > 1499 is part
-- of the start-zone segment; Tirisfal: 1470 at the same skeletons), the Voidwalker at 11-14 (key ability: Orc / Troll
-- 1506 > 1501 > 1504 in Orgrimmar and Skull Rock; Undead 1478 > 1473 > 1471 in Brill, Perrine's Chest and the
-- Undercity), the Incubus at 31 (1472 > 65593 > 65597: the Undercity at 22, the two hearts on the path's own stops at
-- Ambermill and Ratchet, the Binding at the Undercity stop at 31), the Felsteed at 40 (3631 > 4490: Zevrost, then a
-- flight to Strahad in Ratchet; the path's next flight to Camp Taurajo starts there as well), the optional Orb of
-- Orahil chain (36-46, 14,650 XP: Ratchet instead of a direct flight at 36, orb and spirit at the path's Mannoroc
-- Coven grind, Tabetha in Dustwallow, Menara at the path's Ratchet stop at 46) and training at stops the path makes
-- anyway (two optional training flights over the trainer gaps, 16-18 and 24).
--
-- Start zones (level before the first step of the insert: validator --levels of the warlock route, normal / worst):
--   Durotar (Orc, Troll)
--     after dur01-teeth        2.33   the letter 3090 (Orc) / 98575 (Troll) at Gornek > Nartok (nothing to train at 2)
--     after dur01-den-4        4.59   Nartok: training 4 (start-camp trainers teach up to 6)
--     after dur02-garthok      6.39   Dhugru Gorelust in Razor Hill: training 6
--     after dur02-rh-3        10.01   Dhugru: training 8 + 10 (Razor Hill is next on the path only at 9.5-10) and
--                                     1506 at Ophek next to him (the gate dur02-lvl-10 guarantees the level)
--     after h12-borstan       11.30   Gan'rul in the Cleft of Shadow (next to Kor'ghan): 1506 > 1501
--     after h12-cattails      11.33   optional: Staves at Hanashi (the cattails lie in the Valley of Honor)
--     before h12-zeppelin 11.98 / 11.87  after Rhinag: Skull Rock (the stash is 150 yd from the zeppelin tower), back
--                                     to Gan'rul (1501 > 1504), the summoning circle, Gan'rul (1504), training 12
--                                     (12.14 / 12.04), out of the gate again: ~4 min for the Voidwalker at 12
--     after h15-org      14.26 / 14.18  the Cleft of Shadow on the way from the inn to the gate: training 14
--   Tirisfal (Undead)
--     after ud01-364           2.61   the letter 3099 at Sarvis > Maximillion, 1470 at Venya Marthand
--     after ud01-skeletons     3.63   1470: 3 skulls from the Rattlecage Skeletons of Sarvis's 3901
--     after ud01-church-4      4.06   Venya (1470), Maximillion: training 4 (4.16)
--     after ud02-sethearth 6.47 / 6.39  Rupert Boch in the Brill tavern: training 6
--     after ud02-brill-8   8.22 / 8.17  Rupert Boch: training 8
--     after ud02-terrence 10.19 / 10.10 Rupert Boch: training 10; 1478 at Ageron Kargal next to him
--     after ud02-fp-uc        12.10   the Magic Quarter: Carendin (1478 > 1473), training 12
--     after ud02-uc-exit      12.12   Perrine's Chest (1473), 250 yd off the way to the Silverpine road
--     after h13-uc-arrive     13.98   the Magic Quarter: Carendin (1473 > 1471), the circle, Carendin (1471): the
--                                     Voidwalker at 14; training 14 (14.08)
--
-- Shared path (level before the insert, warlock routes; the three races are within 0.1 of each other from 18 on):
--   16+18  after h15-end          optional, 18.11 / 17.73 (Undead 18.18 / 17.92): fly to Orgrimmar, the Cleft of
--                                 Shadow, fly to Camp Taurajo (the next shared flight goes there and completes on
--                                 landing): ~4 min for Searing Pain and the 16 / 18 ranks.
--   20+22  after h22-rol-oran     22.74 / 22.05: the Magic Quarter of the Undercity (~150 yd from Oran): training,
--                                 1472 at Carendin > Godrick Farsan, 65593.
--   65593  after h22-offering-stone-3  23.38 / 22.20: Avelina Lilly at Ambermill (~150 yd).
--   65593  after h-24-ratchet-arrive   25.63 / 24.80: Isaac Pearson in Ratchet (next to the quest giver).
--   24     after h-24-tarrenmill-end  optional, 24.83 / 24.01: fly to the Undercity, training, then the path's hearth to
--                                 Thunder Bluff (~4 min more).
--   26-30  after h-31-uc-arrive   31.16 / 31.05: the Magic Quarter: 65593 > 65597, the circle, the Incubus; training.
--   32+34  after h-34-uc-arrive   34.10: the Magic Quarter.
--   36     after h-37-org-arrive  36.06: the Cleft of Shadow next to the quest giver; optional 4967 at Zevrost.
--   Orb    after h-37-orgrimmar-keldran  optional, 36.07: fly to Ratchet instead of Sun Rock: Menara (4967 > 1799),
--                                 Acolyte Wytula (4962); the shared flight to Sun Rock leaves from Ratchet.
--   Orb    before h39-level-mannoroc   optional, 37.82: the orb (1799) and the felhound spirit (4962) at the Mannoroc
--                                 Coven, where the path grinds to 39.8 anyway.
--   38+40  after h-40-org-arrive  40.06 / 40.01: Zevrost (training, 3631), fly to Ratchet, Strahad (3631 > 4490 >
--                                 Summon Felsteed), optional Menara (4962); the shared flight to Camp Taurajo leaves
--                                 from Ratchet (+~3 min for the free mount).
--   Orb    after h-38-dustwallow-marsh-field  optional, 40.77 / 40.61: Tabetha (1799 > 4961 > 4976), Demon of the Orb
--                                 (elite 40), ~500 yd north of the Wyrmbog.
--   42+44  after h-44-stonard-arrive  44.05 / 44.03: Kartosh in Stonard (the Undercity at 44.02 is a fly-through).
--   Orb    after h46-ratchet-fm   optional, 46.01: Menara (4976 > 4975 Noh'Orahil), next to the flight master.
--   46+48  after h-50-org-arrive  49.41 / 49.37: the Cleft of Shadow on the way from the Valley of Spirits.
--   50+52  after h53-org-hearth   52.73 / 52.70: the Cleft of Shadow between the inn and the gate.
--   54     after h56-sethearth-org 55.07: the Cleft of Shadow between the inn and the flight master.
--   56     after h-58-org-arrive  57.21 / 57.18: the Cleft of Shadow on the way from the inn to the gate.
--   58+60  after h-60-end         optional: hearth to the Undercity (bound there by the path), the Magic Quarter.
-- Not visited: 16-18 when the optional Orgrimmar flight is skipped; 24-28 when the optional Undercity flight is skipped
--   (C.2: the trainer gap 22 -> 31); Orgrimmar at 31.05 (the path only crosses from the flight master to the gate) and
--   at 41.0 (40 was trained at 40.06); the Undercity at 44.02, 49.5, 52.6 and 57.2-58 (Orgrimmar / Stonard are next to
--   the steps); Stonard at 51.8.
-- Skipped class quests: the Orgrimmar Succubus chain 1507-1513 (starts at 20 in Orgrimmar; the path passes Orgrimmar
--   at 14 and 22, the Crossroads / Malaka'jin / Taurajo loop is done by then) and its Incubus twin 1507 > 65601 >
--   65610 > 65604 (exclusive with the Undercity branch that is routed); the Undercity Succubus 1476 / 1474 (Wetlands);
--   Felhunter 2996 / 3001 > 1801 > 1803 > 1805 > 1795 (Purgation Isle, Thousand Needles, Wetlands: off the path after
--   31, the Voidwalker does the job); the robe chain 4737 / 4739 > 1796 ... 4786 (a crafted robe, gold bars, Booty Bay,
--   Desolace, Arathi); Orb of Soran'ruk 1740 (dungeons); 8419 / 8420 > 8421 > 8422 at 50-55 (Felwood: the Felcloth of
--   the first quest is a random drop, the Rotting Wood of the second lies in the Irontree Woods the path passes before
--   the first can be turned in; 8422 is the Sunken Temple); 4785 and 7601-7603 (outside the snapshot).
-- Class reward table: none. The DB snapshot has no reward lists; a wrong index would make the automation take the
--   wrong item. The notes say what to look for (intellect / stamina cloth, staves, off-hand items).
--
-- Automation notes: the trainers that give a quest of this file are Zevrost (4967 and 3631; the 4967 accept comes before
-- the training step, the 3631 accept is merged with it); Gan'rul, Carendin, Godrick, Strahad, Menara, Ophek, Ageron and
-- Venya are not trainers. Every insert follows a step the player has just done (an arrival, a hearth, a turn-in) and
-- leaves the path where it was, or before a shared `go` / `fly` / `hearth` that works from the new place (the zeppelin
-- tower after the Binding at 12, the flights from Ratchet at 36 and 40, the hearth after the Undercity at 24).

if not FastesBoooy.AddLibraryInsert then return end
local insert = FastesBoooy.AddLibraryInsert

-- Durotar
local GORNEK = { 1411, 42.06, 68.33 }
local NARTOK = { 1411, 40.65, 68.52 }          -- 3156, Valley of Trials (teaches up to 6); demon trainer Hraug 12776 next door
local DHUGRU = { 1411, 54.38, 41.20 }          -- 3172, Razor Hill; demon trainer Kitha 6027 next door
local OPHEK = { 1411, 54.37, 41.29 }           -- 3294, 1506
local STASH = { 1411, 51.62, 9.76 }            -- Burning Blade Stash 58595 in Skull Rock (1501)
-- Orgrimmar
local GANRUL = { 1454, 48.25, 45.28 }          -- 5875, Cleft of Shadow
local ZEVROST = { 1454, 48.47, 45.43 }         -- 3326
local ORG_TRAINERS = { 3326, 3324, 3325 }      -- Zevrost, Grol'dar, Mirket (Cleft of Shadow)
local ORG_CIRCLE = { 1454, 49.43, 50.04 }      -- summoning circle of the Binding quests
local HANASHI = { 1454, 81.53, 19.63 }         -- 2704, weapon master (staves)
local ORG_FP = { 1454, 45.12, 63.89 }
-- Tirisfal
local SARVIS = { 1420, 30.84, 66.20 }
local MAXIMILLION = { 1420, 30.91, 66.34 }     -- 2126, Deathknell (teaches up to 6); demon trainer Kayla Smithe 5749
local VENYA = { 1420, 30.98, 66.41 }           -- 5667, 1470
local SKELETONS = { 1420, 33.00, 61.68 }       -- Rattlecage Skeletons 1890 (centroid of the spawns)
local RUPERT = { 1420, 61.59, 52.40 }          -- 2127, Brill (Gallows' End Tavern); demon trainer Gina Lang 5750
local AGERON = { 1420, 61.62, 52.68 }          -- 5724, 1478
local CHEST = { 1420, 51.06, 67.57 }           -- Perrine's Chest 37098 (1473)
-- Undercity (Magic Quarter)
local CARENDIN = { 1458, 85.06, 25.99 }        -- 5675
local GODRICK = { 1458, 84.81, 14.83 }         -- 5693
local KAAL = { 1458, 86.21, 15.93 }            -- 4563
local UC_TRAINERS = { 4563, 4564, 4565 }       -- Kaal Soulreaper, Luther Pickman, Richard Kerwin
local UC_CIRCLE = { 1458, 86.62, 27.05 }
local UC_FP = { 1458, 63.25, 48.56 }
-- Elsewhere
local AVELINA = { 1421, 62.96, 63.88 }         -- 185333, Ambermill (65593)
local ISAAC = { 1413, 61.92, 38.50 }           -- 185334, Ratchet (65593)
local RATCHET_FP = { 1413, 63.08, 37.16 }
local STRAHAD = { 1413, 62.63, 35.50 }         -- 6251 (Felsteed)
local MENARA = { 1413, 62.51, 35.45 }          -- 6266 (Orb of Orahil)
local WYTULA = { 1413, 62.64, 35.30 }          -- 6254 (4962)
local SUMMONERS = { 1443, 52.50, 77.00 }       -- Burning Blade Summoners 4668, Mannoroc Coven (1799)
local MANA_EATERS = { 1443, 52.16, 68.06 }     -- 4678, north edge of Mannoroc Coven (4962)
local TABETHA = { 1445, 46.06, 57.09 }         -- 6546, Dustwallow Marsh
local DEMON = { 1445, 45.79, 56.97 }           -- Demon of the Orb 6549 (L40 elite)
local KARTOSH = { 1435, 48.65, 55.64 }         -- 988, Stonard
local TAURAJO_FP = { 1413, 44.45, 59.15 }

local function spell(ru, en) return { ru = ru, en = en } end
local NEW = { ru = " (новый ранг)", en = " (new rank)" }
local function rank(ru, en) return { ru = ru .. NEW.ru, en = en .. NEW.en } end

local SB = function() return rank("Стрела Тьмы", "Shadow Bolt") end
local IMMO = function() return rank("Жертвенный огонь", "Immolate") end
local CORR = function() return rank("Порча", "Corruption") end
local COA = function() return rank("Проклятие агонии", "Curse of Agony") end
local DL = function() return rank("Похищение жизни", "Drain Life") end
local LT = function() return rank("Жизнеотвод", "Life Tap") end

------------------------------------------------------------------------------------------------------------------
-- Durotar (Orc, Troll) ------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- The letter: Gornek hands it out in the dialog of the shared turn-in of 788; Nartok stands in the west building.
insert({
    after = "dur01-teeth",
    class = "WARLOCK",
    race = "Orc",
    steps = {
        { id = "wlk-dur-letter-orc", accept = 3090, npc = 3143, at = GORNEK,
          note = { ru = "Горнек даёт и письмо чернокнижника: «Осквернённый пергамент».",
                   en = "Gornek also has the warlock's letter: Tainted Parchment." } },
        { id = "wlk-dur-nartok-orc", turnin = 3090, npc = 3156, at = NARTOK,
          note = { ru = "Нарток — тренер чернокнижников, в западном здании (40,6, 68,5). Учить пока нечего "
                       .. "(следующее — на 4-м).",
                   en = "Nartok, the warlock trainer, in the west building (40.6, 68.5). Nothing to train yet (next "
                       .. "at 4)." } },
    },
})
insert({
    after = "dur01-teeth",
    class = "WARLOCK",
    race = "Troll",
    steps = {
        { id = "wlk-dur-letter-troll", accept = 98575, npc = 3143, at = GORNEK,
          note = { ru = "Горнек даёт и письмо чернокнижника: «Осквернённая табличка».",
                   en = "Gornek also has the warlock's letter: Tainted Tablet." } },
        { id = "wlk-dur-nartok-troll", turnin = 98575, npc = 3156, at = NARTOK,
          note = { ru = "Нарток — тренер чернокнижников, в западном здании (40,6, 68,5). Учить пока нечего "
                       .. "(следующее — на 4-м).",
                   en = "Nartok, the warlock trainer, in the west building (40.6, 68.5). Nothing to train yet (next "
                       .. "at 4)." } },
    },
})
-- The Imp chain (1485 > 1499 at Ruzan, the warlock's alternative of 792) is part of the start-zone segment.
insert({
    after = "dur01-den-4",
    class = "WARLOCK",
    race = { "Orc", "Troll" },
    steps = {
        { id = "wlk-dur-train-4", train = true, npc = 3156, at = NARTOK,
          spells = { spell("Порча", "Corruption"), spell("Проклятие слабости", "Curse of Weakness") },
          note = { ru = "Нарток в западном здании: обучение 4-го уровня. «Порча» на каждую цель — основа "
                       .. "чернокнижника.",
                   en = "Nartok in the west building: level 4 training. Corruption on every target is the "
                       .. "warlock's bread and butter." } },
    },
})
insert({
    after = "dur02-garthok",
    class = "WARLOCK",
    race = { "Orc", "Troll" },
    steps = {
        { id = "wlk-dur-train-6", train = true, npc = 3172, at = DHUGRU,
          spells = { spell("Жизнеотвод", "Life Tap"), SB() },
          note = { ru = "Дхугру Кровожад, тренер чернокнижников Колючего Холма (северный край, 54,4, 41,2): "
                       .. "обучение 6-го уровня. «Жизнеотвод» + бинты или еда вместо питья.",
                   en = "Dhugru Gorelust, the Razor Hill warlock trainer (north end, 54.4, 41.2): level 6 training. "
                       .. "Life Tap + bandages or food instead of drinking." } },
    },
})
-- 8 and 10 in one visit: Razor Hill is next on the path only at 9.5-10, after the hearth.
insert({
    after = "dur02-rh-3",
    class = "WARLOCK",
    race = { "Orc", "Troll" },
    steps = {
        { id = "wlk-dur-train-10", train = true, npc = 3172, at = DHUGRU,
          spells = { spell("Страх", "Fear"), spell("Проклятие агонии", "Curse of Agony"),
                     spell("Похищение души", "Drain Soul"), spell("Создание камня здоровья", "Create Healthstone"),
                     IMMO() },
          note = { ru = "Дхугру Кровожад на северном краю Колючего Холма: обучение 8-го и 10-го уровней. Кита рядом "
                       .. "продаёт книги для беса.",
                   en = "Dhugru Gorelust at the north end of Razor Hill: level 8 and 10 training. Kitha next to him "
                       .. "sells the imp's grimoires." } },
        { id = "wlk-dur-1506", accept = 1506, npc = 3294, at = OPHEK,
          note = { ru = "Офек рядом с тренером: «Призыв Ган'рула» — в Оргриммар, по пути (Расселина Теней): там "
                       .. "получите Демона Бездны.",
                   en = "Ophek next to the trainer: Gan'rul's Summons - to Orgrimmar, on the way (the Cleft of "
                       .. "Shadow): the Voidwalker comes from there." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Orgrimmar at 11 (Orc, Troll): the Voidwalker -------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- Gan'rul stands in the Cleft of Shadow next to Kor'ghan (dur02-korghan, same anchor). The tablet lies in Skull Rock
-- right by the zeppelin tower, so it is fetched after Rhinag; then back into the city for the Binding and out again
-- (~4 min in all). Troll: the snapshot masks 1501 / 1504 as Orc only; tools/overrides/warlock.lua adds the Troll.
insert({
    after = "h12-borstan",
    class = "WARLOCK",
    race = { "Orc", "Troll" },
    steps = {
        -- CONFIRM: the Troll can take 1501 (web, classes.md section 7; the DB mask says Orc only)
        { id = "wlk-ganrul", turnin = 1506, accept = 1501, npc = 5875, at = GANRUL,
          ok = "db-override-unverified",
          note = { ru = "В Расселине Теней (рядом с Кор'ганом): Ган'рул Кровавый Глаз — «Создание Бездны»: "
                       .. "скрижаль Верги в Черепе-Скале у башни дирижаблей. Сначала городские задания.",
                   en = "In the Cleft of Shadow (next to Kor'ghan): Gan'rul Bloodeye - Creature of the Void: the Tablet "
                       .. "of Verga in Skull Rock by the zeppelin tower. The city quests first." } },
    },
})
insert({
    after = "h12-cattails",
    class = "WARLOCK",
    race = { "Orc", "Troll" },
    steps = {
        { id = "wlk-staves", train = true, optional = true, npc = 2704, at = HANASHI,
          note = { ru = "Необязательно: Ханаши, мастер оружия в Долине Чести (рядом, 81,5, 19,6) — «Посохи» "
                       .. "(10 серебра): посохи — частая награда за задания для заклинателя.",
                   en = "Optional: Hanashi, the weapon master in the Valley of Honor (close by, 81.5, 19.6) - Staves "
                       .. "(10 silver): staves are a frequent quest reward for a caster." } },
    },
})
insert({
    before = "h12-zeppelin",
    class = "WARLOCK",
    race = { "Orc", "Troll" },
    steps = {
        -- CONFIRM: the Troll can do 1501 / 1504 (see wlk-ganrul)
        { id = "wlk-tablet", complete = 1501, object = 58595, at = STASH,
          note = { ru = "От Ринага на северо-восток к Черепу-Скале (рядом с башней дирижаблей): в пещере тайник "
                       .. "Пылающего Клинка — скрижаль Верги. Культисты 10-12: бес впереди, «Порча» на каждого.",
                   en = "From Rhinag north-east to Skull Rock (next to the zeppelin tower): the Burning Blade Stash in "
                       .. "the cave - the Tablet of Verga. Cultists 10-12: imp in front, Corruption on each." } },
        { id = "wlk-ganrul-2", turnin = 1501, accept = 1504, npc = 5875, at = GANRUL, ok = "db-override-unverified",
          note = { ru = "Обратно в Оргриммар через главные ворота, к Ган'рулу в Расселину Теней: «Связывание».",
                   en = "Back into Orgrimmar through the main gate, to Gan'rul in the Cleft of Shadow: The Binding." } },
        { id = "wlk-binding", complete = 1504, use = 7464, at = ORG_CIRCLE,
          note = { ru = "Круг призыва в глубине Расселины (49,4, 50,0): используйте «Глифы призыва» и одолейте "
                       .. "Демона Бездны (полное здоровье и мана перед боем).",
                   en = "The summoning circle deep in the Cleft (49.4, 50.0): use the Glyphs of Summoning and defeat "
                       .. "the Voidwalker (full health and mana first)." } },
        { id = "wlk-ganrul-3", turnin = 1504, npc = 5875, at = GANRUL,
          note = { ru = "Ган'рул: «Призыв Демона Бездны» выучен. Демон Бездны держит врагов на себе — ваш питомец до "
                       .. "30-х.",
                   en = "Gan'rul: Summon Voidwalker learned. The Voidwalker holds the mobs - your pet into the 30s." } },
        { id = "wlk-train-12", train = true, npc = ORG_TRAINERS, at = ZEVROST,
          spells = { spell("Канал здоровья", "Health Funnel"), SB(), rank("Проклятие слабости", "Curse of Weakness") },
          note = { ru = "Тренеры чернокнижников рядом с Ган'рулом: обучение 12-го уровня. Потом из ворот к башне "
                       .. "дирижаблей.",
                   en = "The warlock trainers next to Gan'rul: level 12 training. Then out of the gate to the zeppelin "
                       .. "tower." } },
    },
})
-- 14: the hearth from the Undercity lands at the Orgrimmar inn, the Cleft is on the way to the gate.
insert({
    after = "h15-org",
    class = "WARLOCK",
    race = { "Orc", "Troll" },
    steps = {
        { id = "wlk-train-14", train = true, npc = ORG_TRAINERS, at = ZEVROST,
          spells = { spell("Похищение жизни", "Drain Life"), CORR(),
                     spell("Проклятие безрассудства", "Curse of Recklessness") },
          note = { ru = "От таверны в Расселину Теней: тренеры чернокнижников — обучение 14-го уровня. Потом к главным "
                       .. "воротам.",
                   en = "From the inn to the Cleft of Shadow: the warlock trainers - level 14 training. Then to the "
                       .. "main gate." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Tirisfal (Undead) ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud01-364",
    class = "WARLOCK",
    race = "Scourge",
    steps = {
        { id = "wlk-tir-letter", accept = 3099, npc = 1569, at = SARVIS,
          note = { ru = "Сарвис даёт и письмо чернокнижника: «Осквернённый свиток».",
                   en = "Sarvis also has the warlock's letter: Tainted Scroll." } },
        { id = "wlk-tir-maximillion", turnin = 3099, npc = 2126, at = MAXIMILLION,
          note = { ru = "Максимилиан — тренер чернокнижников, в той же часовне. Учить пока нечего (следующее — на 4-м).",
                   en = "Maximillion, the warlock trainer, in the same chapel. Nothing to train yet (next at 4)." } },
        { id = "wlk-tir-1470", accept = 1470, npc = 5667, at = VENYA,
          note = { ru = "Веня Мартанд рядом: «Проникнуть за завесу» — 3 черепа гремящих скелетов, тех же, что для "
                       .. "задания Сарвиса.",
                   en = "Venya Marthand next to him: Piercing the Veil - 3 Rattlecage Skulls from the same skeletons "
                       .. "as Sarvis's quest." } },
    },
})
insert({
    after = "ud01-skeletons",
    class = "WARLOCK",
    race = "Scourge",
    steps = {
        { id = "wlk-tir-skulls", complete = 1470, at = SKELETONS,
          note = { ru = "Те же гремящие скелеты: 3 черепа.",
                   en = "The same Rattlecage Skeletons: 3 skulls." } },
    },
})
insert({
    after = "ud01-church-4",
    class = "WARLOCK",
    race = "Scourge",
    steps = {
        { id = "wlk-tir-venya", turnin = 1470, npc = 5667, at = VENYA,
          note = { ru = "Веня Мартанд в часовне: черепа.",
                   en = "Venya Marthand in the chapel: the skulls." } },
        { id = "wlk-tir-train-4", train = true, npc = 2126, at = MAXIMILLION,
          spells = { spell("Порча", "Corruption"), spell("Проклятие слабости", "Curse of Weakness") },
          note = { ru = "Максимилиан рядом: обучение 4-го уровня. «Порча» на каждую цель — основа чернокнижника.",
                   en = "Maximillion close by: level 4 training. Corruption on every target is the warlock's bread "
                       .. "and butter." } },
    },
})
insert({
    after = "ud02-sethearth",
    class = "WARLOCK",
    race = "Scourge",
    steps = {
        { id = "wlk-tir-train-6", train = true, npc = 2127, at = RUPERT,
          spells = { spell("Жизнеотвод", "Life Tap"), SB() },
          note = { ru = "Руперт Бох в таверне Брилла (наверху): обучение 6-го уровня. «Жизнеотвод» + еда вместо "
                       .. "питья.",
                   en = "Rupert Boch in the Brill tavern (upstairs): level 6 training. Life Tap + food instead of "
                       .. "drinking." } },
    },
})
insert({
    after = "ud02-brill-8",
    class = "WARLOCK",
    race = "Scourge",
    steps = {
        { id = "wlk-tir-train-8", train = true, npc = 2127, at = RUPERT,
          spells = { spell("Страх", "Fear"), spell("Проклятие агонии", "Curse of Agony") },
          note = { ru = "Руперт Бох в таверне: обучение 8-го уровня. Джина Ланг рядом продаёт книги для беса.",
                   en = "Rupert Boch in the tavern: level 8 training. Gina Lang next to him sells the imp's "
                       .. "grimoires." } },
    },
})
insert({
    after = "ud02-terrence",
    class = "WARLOCK",
    race = "Scourge",
    steps = {
        { id = "wlk-tir-train-10", train = true, npc = 2127, at = RUPERT,
          spells = { spell("Похищение души", "Drain Soul"), spell("Создание камня здоровья", "Create Healthstone"),
                     IMMO() },
          note = { ru = "Руперт Бох в таверне: обучение 10-го уровня.",
                   en = "Rupert Boch in the tavern: level 10 training." } },
        { id = "wlk-tir-1478", accept = 1478, npc = 5724, at = AGERON,
          note = { ru = "Агерон Каргал рядом: «Призыв Халгара» — в Подгород (там будете на 12-м), начало цепочки "
                       .. "Демона Бездны.",
                   en = "Ageron Kargal next to him: Halgar's Summons - to the Undercity (you get there at 12), the "
                       .. "start of the Voidwalker chain." } },
    },
})
insert({
    after = "ud02-fp-uc",
    class = "WARLOCK",
    race = "Scourge",
    steps = {
        { id = "wlk-tir-carendin", turnin = 1478, accept = 1473, npc = 5675, at = CARENDIN,
          note = { ru = "Квартал Магов Подгорода (на восток от полётов): Карендин Халгар — «Создание Бездны»: "
                       .. "гримуар Эгалина в сундуке Перрина, по пути в Серебряный бор.",
                   en = "The Magic Quarter of the Undercity (east of the flight master): Carendin Halgar - Creature of "
                       .. "the Void: Egalin's Grimoire in Perrine's Chest, on the way to Silverpine." } },
        { id = "wlk-tir-train-12", train = true, npc = UC_TRAINERS, at = KAAL,
          spells = { spell("Канал здоровья", "Health Funnel"), SB() },
          note = { ru = "Тренеры чернокнижников рядом, в Квартале Магов: обучение 12-го уровня. Потом к выходу.",
                   en = "The warlock trainers close by in the Magic Quarter: level 12 training. Then to the exit." } },
    },
})
insert({
    after = "ud02-uc-exit",
    class = "WARLOCK",
    race = "Scourge",
    steps = {
        { id = "wlk-tir-grimoire", complete = 1473, object = 37098, at = CHEST,
          note = { ru = "Из Подгорода на запад к дому у руин (51,1, 67,6): сундук Перрина — гримуар Эгалина. Потом на "
                       .. "юг к дороге в Серебряный бор.",
                   en = "From the Undercity west to the house by the ruins (51.1, 67.6): Perrine's Chest - Egalin's "
                       .. "Grimoire. Then south to the Silverpine road." } },
    },
})
-- 14: the Binding and level 14 training in the Magic Quarter (the path's Undercity visit after Silverpine).
insert({
    after = "h13-uc-arrive",
    class = "WARLOCK",
    race = "Scourge",
    steps = {
        { id = "wlk-tir-carendin-2", turnin = 1473, accept = 1471, npc = 5675, at = CARENDIN,
          note = { ru = "Квартал Магов: Карендин Халгар — «Связывание».",
                   en = "The Magic Quarter: Carendin Halgar - The Binding." } },
        { id = "wlk-tir-binding", complete = 1471, use = 6284, at = UC_CIRCLE,
          note = { ru = "Круг призыва рядом (86,6, 27,1): используйте «Руны призыва» и одолейте Демона Бездны (полное "
                       .. "здоровье и мана перед боем).",
                   en = "The summoning circle close by (86.6, 27.1): use the Runes of Summoning and defeat the "
                       .. "Voidwalker (full health and mana first)." } },
        { id = "wlk-tir-carendin-3", turnin = 1471, npc = 5675, at = CARENDIN,
          note = { ru = "Карендин: «Призыв Демона Бездны» выучен — ваш питомец до 30-х, он держит врагов на себе.",
                   en = "Carendin: Summon Voidwalker learned - your pet into the 30s, it holds the mobs." } },
        { id = "wlk-tir-train-14", train = true, npc = UC_TRAINERS, at = KAAL,
          spells = { spell("Похищение жизни", "Drain Life"), CORR() },
          note = { ru = "Тренеры рядом: обучение 14-го уровня. Потом обратно к полётам и по маршруту.",
                   en = "The trainers close by: level 14 training. Then back to the flight master and on." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 16-22 ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- 16 + 18 (optional): no warlock trainer on the path between 14 and 22 (Thunder Bluff has none). From the
-- Crossroads at the end of h-15 the next shared step flies to Camp Taurajo; the detour flies to Orgrimmar first and
-- from there to Camp Taurajo, so the shared flight completes on the landing.
insert({
    after = "h15-end",
    class = "WARLOCK",
    steps = {
        { id = "wlk-16-fly-org", fly = "Orgrimmar", optional = true, npc = 3310, at = ORG_FP,
          note = { ru = "Необязательно (~4 мин): на Перекрёстке летите в Оргриммар — до 22-го тренеров "
                       .. "чернокнижников на пути нет.",
                   en = "Optional (~4 min): at the Crossroads fly to Orgrimmar - there is no warlock trainer on the way "
                       .. "until 22." } },
        { id = "wlk-train-18", train = true, optional = true, npc = ORG_TRAINERS, at = ZEVROST,
          spells = { spell("Жгучая боль", "Searing Pain"), COA(), LT(), spell("Бесконечное дыхание", "Unending Breath") },
          note = { ru = "Расселина Теней (вход у Долины Силы): обучение 16-го и 18-го уровней.",
                   en = "The Cleft of Shadow (entrance by the Valley of Strength): level 16 and 18 training." } },
        { id = "wlk-16-fly-taurajo", fly = "Camp Taurajo", optional = true, npc = 10378, at = TAURAJO_FP,
          note = { ru = "Обратно к Дорасу: летите сразу в Лагерь Таурахо (следующий полёт маршрута туда же).",
                   en = "Back to Doras: fly straight to Camp Taurajo (where the next flight of the path goes)." } },
    },
})
-- 20 + 22, Incubus (Undercity branch): the path's Undercity visit at 22 passes Oran Snakewrithe at the Magic
-- Quarter's door; Carendin, Godrick Farsan and the trainers are ~150 yd further. The two hearts come from the path's
-- own stops at Ambermill (23.2) and Ratchet (25.6); the Binding waits for the Undercity at 31.
insert({
    after = "h22-rol-oran",
    class = "WARLOCK",
    steps = {
        { id = "wlk-train-22", train = true, npc = UC_TRAINERS, at = KAAL,
          spells = { spell("Огненный ливень", "Rain of Fire"), spell("Демонический доспех", "Demon Armor"), SB(),
                     IMMO(), DL() },
          note = { ru = "От Орана на восток в Квартал Магов: тренеры чернокнижников — обучение 20-го и 22-го уровней.",
                   en = "From Oran east into the Magic Quarter: the warlock trainers - level 20 and 22 training." } },
        { id = "wlk-22-1472", accept = 1472, npc = 5675, at = CARENDIN,
          note = { ru = "Карендин Халгар рядом: «Пожиратель душ» (цепочка инкуба).",
                   en = "Carendin Halgar close by: Devourer of Souls (the Incubus chain)." } },
        { id = "wlk-22-godrick", turnin = 1472, accept = 65593, npc = 5693, at = GODRICK,
          note = { ru = "Годрик Фарсан у тренеров: «Сердца влюблённых» — Авелина Лилли на Янтарной мельнице и Айзек "
                       .. "Пирсон в Кабестане (обе точки на маршруте). Потом обратно к Орану и дальше.",
                   en = "Godrick Farsan by the trainers: Hearts of the Lovers - Avelina Lilly at Ambermill and Isaac "
                       .. "Pearson in Ratchet (both on the path). Then back past Oran and on." } },
    },
})
insert({
    after = "h22-offering-stone-3",
    class = "WARLOCK",
    steps = {
        -- CONFIRM: Avelina Lilly (L22, no faction in the DB) can be attacked and drops the heart; XP of 65593 / 65597 unknown
        { id = "wlk-avelina", complete = { [65593] = { 1 } }, at = AVELINA,
          note = { ru = "Янтарная мельница, к северо-востоку от камня (63,0, 63,9): Авелина Лилли — её сердце.",
                   en = "Ambermill, north-east of the stone (63.0, 63.9): Avelina Lilly - her heart." } },
    },
})
insert({
    after = "h-24-ratchet-arrive",
    class = "WARLOCK",
    steps = {
        -- CONFIRM: Isaac Pearson (faction A in the DB) can be attacked inside Ratchet without the goblin guards joining
        { id = "wlk-isaac", complete = { [65593] = { 2 } }, at = ISAAC,
          note = { ru = "Кабестан, рядом (61,9, 38,5): Айзек Пирсон — его сердце.",
                   en = "Ratchet, close by (61.9, 38.5): Isaac Pearson - his heart." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 24-60 ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- 24 (optional): the trainer gap 22 -> 31 (classes.md 4.3). From Tarren Mill fly to the Undercity, then the path's
-- own hearth to Thunder Bluff works from there.
insert({
    after = "h-24-tarrenmill-end",
    class = "WARLOCK",
    steps = {
        { id = "wlk-24-fly-uc", fly = "Undercity", optional = true, npc = 4551, at = UC_FP,
          note = { ru = "Необязательно (~4 мин): у Зарис летите в Подгород — следующий тренер чернокнижников на пути "
                       .. "будет только на 31-м. Камень возвращения потом сработает и оттуда.",
                   en = "Optional (~4 min): fly from Zarise to the Undercity - the next warlock trainer on the path "
                       .. "comes only at 31. The hearth that follows works from there as well." } },
        { id = "wlk-train-24", train = true, optional = true, npc = UC_TRAINERS, at = KAAL,
          spells = { CORR(), spell("Похищение маны", "Drain Mana"), rank("Похищение души", "Drain Soul") },
          note = { ru = "Квартал Магов: обучение 24-го уровня. Потом камень возвращения (следующий шаг).",
                   en = "The Magic Quarter: level 24 training. Then the hearthstone (the next step)." } },
    },
})
-- 26-30 and the Incubus at the Undercity stop at 31.
insert({
    after = "h-31-uc-arrive",
    class = "WARLOCK",
    steps = {
        { id = "wlk-31-carendin", turnin = 65593, accept = 65597, npc = 5675, at = CARENDIN,
          note = { ru = "Квартал Магов: Карендин Халгар — сердца, «Связывание».",
                   en = "The Magic Quarter: Carendin Halgar - the hearts, The Binding." } },
        { id = "wlk-31-binding", complete = 65597, use = 190181, at = UC_CIRCLE,
          note = { ru = "Круг призыва рядом: используйте «Сердца влюблённых» и одолейте инкуба.",
                   en = "The summoning circle close by: use the Lovers' Hearts and defeat the Incubus." } },
        { id = "wlk-31-incubus", turnin = 65597, npc = 5675, at = CARENDIN,
          note = { ru = "Карендин: «Призыв инкуба». Для прокачки Демон Бездны надёжнее; инкуб бьёт сильнее.",
                   en = "Carendin: Summon Incubus. The Voidwalker is the safer leveling pet; the Incubus hits harder." } },
        { id = "wlk-train-30", train = true, npc = UC_TRAINERS, at = KAAL,
          spells = { spell("Адское пламя", "Hellfire"), SB(), IMMO(), COA(), DL(), LT() },
          note = { ru = "Тренеры рядом: обучение 26-30-го уровней. Потом обратно к полётам.",
                   en = "The trainers close by: level 26-30 training. Then back to the flight master." } },
    },
})
insert({
    after = "h-34-uc-arrive",
    class = "WARLOCK",
    steps = {
        { id = "wlk-train-34", train = true, npc = UC_TRAINERS, at = KAAL,
          spells = { spell("Защита от темной магии", "Shadow Ward"), CORR(), rank("Огненный ливень", "Rain of Fire") },
          note = { ru = "Из Подгорода не выходите сразу: Квартал Магов — обучение 32-го и 34-го уровней.",
                   en = "Do not leave the Undercity yet: the Magic Quarter - level 32 and 34 training." } },
    },
})
-- 36 and the Orb of Orahil (optional chain, 14,650 XP): breadcrumb at Zevrost, Menara in Ratchet (the path flies on to
-- Sun Rock from there as well), orb and spirit at the Mannoroc Coven grind, Tabetha in Dustwallow, Menara at 46.
insert({
    after = "h-37-org-arrive",
    class = "WARLOCK",
    steps = {
        { id = "wlk-36-4967", accept = 4967, optional = true, npc = 3326, at = ZEVROST,
          note = { ru = "Необязательно: Зеврост — «Сведения о Сфере Орахила» (цепочка на ~14 600 опыта до 46-го).",
                   en = "Optional: Zevrost - Knowledge of the Orb of Orahil (a chain worth ~14,600 XP up to 46)." } },
        { id = "wlk-train-36", train = true, npc = ORG_TRAINERS, at = ZEVROST,
          spells = { SB(), LT(), rank("Канал здоровья", "Health Funnel") },
          note = { ru = "Расселина Теней (рядом с поручением): обучение 36-го уровня.",
                   en = "The Cleft of Shadow (next to the quest giver): level 36 training." } },
    },
})
insert({
    after = "h-37-orgrimmar-keldran",
    class = "WARLOCK",
    steps = {
        { id = "wlk-36-fly-ratchet", fly = "Ratchet", optional = true, npc = 16227, at = RATCHET_FP,
          note = { ru = "Необязательно (~3 мин): летите в Кабестан, не в Утес Солнечного Камня.",
                   en = "Optional (~3 min): fly to Ratchet instead of Sun Rock Retreat." } },
        { id = "wlk-36-menara", turnin = 4967, accept = 1799, optional = true, npc = 6266, at = MENARA,
          note = { ru = "Менара Воидрендер у входа в Кабестан: «Осколки Сферы Орахила» — сфера с призывателей "
                       .. "Пылающего Клинка на Поле Маннорок (Пустоши, маршрут там на 38-м).",
                   en = "Menara Voidrender at the entrance of Ratchet: Fragments of the Orb of Orahil - the orb from "
                       .. "the Burning Blade Summoners at the Mannoroc Coven (Desolace, the path is there at 38)." } },
        { id = "wlk-36-wytula", accept = 4962, optional = true, npc = 6254, at = WYTULA,
          note = { ru = "Послушница Витула рядом: «Осколок гончей Скверны» — дух с пожирателей маны там же. Потом "
                       .. "летите в Утес Солнечного Камня (следующий шаг).",
                   en = "Acolyte Wytula next to her: Shard of a Felhound - the spirit from the Mana Eaters there. Then "
                       .. "fly to Sun Rock Retreat (the next step)." } },
    },
})
insert({
    before = "h39-level-mannoroc",
    class = "WARLOCK",
    steps = {
        { id = "wlk-38-orb", complete = 1799, optional = true, at = SUMMONERS,
          note = { ru = "Поле Маннорок: Инфернальная сфера с призывателей Пылающего Клинка.",
                   en = "The Mannoroc Coven: the Infernal Orb from the Burning Blade Summoners." } },
        -- CONFIRM: the Felhas Ruby is used on a slain Mana Eater (original game)
        { id = "wlk-38-spirit", complete = 4962, optional = true, use = 12647, at = MANA_EATERS,
          note = { ru = "Северный край Поля Маннорок: пожиратели маны — дух гончей (рубин Фелхаса на убитого).",
                   en = "The north edge of the Mannoroc Coven: Mana Eaters - the felhound spirit (the Felhas Ruby on "
                       .. "a slain one)." } },
    },
})
-- 38 + 40 and the Felsteed (key ability): Zevrost, then fly to Ratchet for Strahad; the path's next flight to Camp
-- Taurajo works from Ratchet.
insert({
    after = "h-40-org-arrive",
    class = "WARLOCK",
    steps = {
        -- CONFIRM: Incinerate (Forever-new) at 40 (classes.md 5.5); 4490 needs no item (none in the DB)
        { id = "wlk-train-40", train = true, accept = 3631, npc = 3326, at = ZEVROST,
          spells = { spell("Вой ужаса", "Howl of Terror"), spell("Испепеление", "Incinerate"), IMMO(), COA(),
                     rank("Похищение души", "Drain Soul") },
          note = { ru = "Расселина Теней: Зеврост — «Призыв коня Скверны» и обучение 38-го и 40-го уровней "
                       .. "(«Испепеление» — новое в Forever).",
                   en = "The Cleft of Shadow: Zevrost - Summon Felsteed, and level 38 and 40 training (Incinerate is "
                       .. "new in Forever)." } },
        { id = "wlk-40-fly-ratchet", fly = "Ratchet", npc = 16227, at = RATCHET_FP,
          note = { ru = "К Дорасу: летите в Кабестан (не в Лагерь Таурахо).",
                   en = "To Doras: fly to Ratchet (not to Camp Taurajo)." } },
        { id = "wlk-40-strahad", turnin = 3631, accept = 4490, npc = 6251, at = STRAHAD,
          note = { ru = "Страхад Фарсан у входа в Кабестан: «Призыв коня Скверны».",
                   en = "Strahad Farsan at the entrance of Ratchet: Summon Felsteed." } },
        { id = "wlk-40-felsteed", turnin = 4490, npc = 6251, at = STRAHAD,
          note = { ru = "Страхад: «Призыв коня Скверны» выучен — свой конь на 40-м, без 100 золотых за верховую езду.",
                   en = "Strahad: Summon Felsteed learned - your own mount at 40, without 100 gold for riding." } },
        { id = "wlk-40-menara", turnin = 4962, optional = true, npc = 6266, at = MENARA,
          note = { ru = "Необязательно (цепочка Сферы): Менара рядом — дух гончей. Потом летите в Лагерь Таурахо "
                       .. "(следующий шаг).",
                   en = "Optional (the Orb chain): Menara next to him - the felhound spirit. Then fly to Camp Taurajo "
                       .. "(the next step)." } },
    },
})
insert({
    after = "h-38-dustwallow-marsh-field",
    class = "WARLOCK",
    steps = {
        { id = "wlk-41-tabetha", turnin = 1799, accept = 4961, optional = true, npc = 6546, at = TABETHA,
          note = { ru = "Необязательно (цепочка Сферы): от Драконьей топи на север к хижине Табеты (46,1, 57,1): "
                       .. "сфера, «Очищение Сферы Орахила».",
                   en = "Optional (the Orb chain): from the Wyrmbog north to Tabetha's hut (46.1, 57.1): the orb, "
                       .. "Cleansing of the Orb of Orahil." } },
        -- CONFIRM: Tabetha summons the Demon of the Orb when 4961 is accepted (original game)
        { id = "wlk-41-demon", complete = 4961, optional = true, at = DEMON,
          note = { ru = "Демон Сферы (элитный, 40) у хижины: Демон Бездны держит, «Порча» + «Проклятие агонии» + "
                       .. "«Похищение жизни»; «Страх» при нужде.",
                   en = "The Demon of the Orb (elite, 40) by the hut: the Voidwalker tanks; Corruption + Curse of "
                       .. "Agony + Drain Life; Fear when needed." } },
        { id = "wlk-41-tabetha-2", turnin = 4961, accept = 4976, optional = true, npc = 6546, at = TABETHA,
          note = { ru = "Табета: очищенная сфера — отнесите Менаре (Кабестан, маршрут там на 46-м).",
                   en = "Tabetha: the cleansed orb - take it to Menara (Ratchet, the path is there at 46)." } },
    },
})
insert({
    after = "h-44-stonard-arrive",
    class = "WARLOCK",
    steps = {
        { id = "wlk-train-44", train = true, npc = 988, at = KARTOSH,
          spells = { spell("Лик смерти", "Death Coil"), spell("Проклятие тьмы", "Curse of Shadow"), SB(), CORR() },
          note = { ru = "Картош, тренер чернокнижников Каменора (48,7, 55,6, рядом с Грешкой): обучение 42-го и "
                       .. "44-го уровней.",
                   en = "Kartosh, the Stonard warlock trainer (48.7, 55.6, next to Greshka): level 42 and 44 "
                       .. "training." } },
    },
})
insert({
    after = "h46-ratchet-fm",
    class = "WARLOCK",
    steps = {
        { id = "wlk-46-menara", turnin = 4976, accept = 4975, optional = true, npc = 6266, at = MENARA,
          ok = "db-override-unverified", -- CONFIRM: Noh'Orahil follows the felhound spirit (tools/overrides/warlock.lua)
          note = { ru = "Необязательно (цепочка Сферы): Менара у входа в Кабестан — сфера, потом подождите, пока она "
                       .. "её зарядит.",
                   en = "Optional (the Orb chain): Menara at the entrance of Ratchet - the orb, then wait while she "
                       .. "charges it." } },
        { id = "wlk-46-orb", complete = 4975, optional = true, npc = 6266, at = MENARA,
          note = { ru = "Подождите у Менары.", en = "Wait by Menara." } },
        { id = "wlk-46-orb-done", turnin = 4975, optional = true, npc = 6266, at = MENARA,
          note = { ru = "Менара: Сфера Ноз'Орахила — предмет для левой руки. Потом к распорядителю полётов.",
                   en = "Menara: the Orb of Noh'Orahil - an off-hand item. Then to the flight master." } },
    },
})
insert({
    after = "h-50-org-arrive",
    class = "WARLOCK",
    steps = {
        { id = "wlk-train-48", train = true, npc = ORG_TRAINERS, at = ZEVROST,
          spells = { spell("Ожог души", "Soul Fire"), COA(), LT(), DL() },
          note = { ru = "Из Долины Духов в Расселину Теней: обучение 46-го и 48-го уровней.",
                   en = "From the Valley of Spirits to the Cleft of Shadow: level 46 and 48 training." } },
    },
})
insert({
    after = "h53-org-hearth",
    class = "WARLOCK",
    steps = {
        { id = "wlk-train-52", train = true, npc = ORG_TRAINERS, at = ZEVROST,
          spells = { IMMO(), rank("Лик смерти", "Death Coil"), SB() },
          note = { ru = "От таверны в Расселину Теней: обучение 50-го и 52-го уровней.",
                   en = "From the inn to the Cleft of Shadow: level 50 and 52 training." } },
    },
})
insert({
    after = "h56-sethearth-org",
    class = "WARLOCK",
    steps = {
        { id = "wlk-train-54", train = true, npc = ORG_TRAINERS, at = ZEVROST,
          spells = { CORR(), rank("Адское пламя", "Hellfire"), DL() },
          note = { ru = "От таверны в Расселину Теней: обучение 54-го уровня. Потом к Дорасу.",
                   en = "From the inn to the Cleft of Shadow: level 54 training. Then to Doras." } },
    },
})
insert({
    after = "h-58-org-arrive",
    class = "WARLOCK",
    steps = {
        { id = "wlk-train-56", train = true, npc = ORG_TRAINERS, at = ZEVROST,
          spells = { rank("Ожог души", "Soul Fire"), LT(), rank("Страх", "Fear") },
          note = { ru = "От таверны в Расселину Теней: обучение 56-го уровня. Потом из ворот к дирижаблю.",
                   en = "From the inn to the Cleft of Shadow: level 56 training. Then out of the gate to the "
                       .. "zeppelin." } },
    },
})
-- After 60: the last ranks. The stone is bound in the Undercity (h-58-uc-arrive).
insert({
    after = "h-60-end",
    class = "WARLOCK",
    steps = {
        { id = "wlk-60-hearth", hearth = "Undercity", optional = true, at = { 1458, 67.74, 37.89 },
          note = { ru = "После 60-го: камень возвращения в Подгород.",
                   en = "After 60: hearth to the Undercity." } },
        { id = "wlk-train-60", train = true, optional = true, npc = UC_TRAINERS, at = KAAL,
          spells = { COA(), rank("Лик смерти", "Death Coil"), SB(), IMMO(), spell("Проклятие рока", "Curse of Doom") },
          note = { ru = "Квартал Магов: обучение 58-го и 60-го уровней.",
                   en = "The Magic Quarter: level 58 and 60 training." } },
    },
})
