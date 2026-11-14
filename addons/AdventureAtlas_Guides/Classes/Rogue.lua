-- AdventureAtlas_Guides / Classes / Rogue.lua
--
-- Every step that exists because of the class (rogue), for all four rogue races (Orc, Troll, Undead = "Scourge",
-- Skyborne), as shared inserts with class scope (step ids "rog-..."; below level 12 one group per start zone:
-- "rog-dur-..." Durotar for Orc and Troll, "rog-tir-..." Tirisfal for the Undead, "rog-zep-..." Zephras Isle for the
-- Skyborne). Every insert is anchored on a step with an explicit id of a start-zone or shared segment. Phase C of
-- docs/dev/PLAN.md (D.5); research docs/dev/research/classes.md 5.3, 6.4.
-- Facts (NPC ids and positions, quest ids, chains, race masks, objective spawns): tools/data/forever_db.lua.
-- Spell levels: classes.md 5.3 (the web list for Forever) for the key ones; the ranks of Sinister Strike, Backstab and
-- Eviscerate and the other spells are the trainer lists of the original game and only shown as text (the core never
-- reads `spells`). CONFIRM in game.
--
-- What the class does here, speed first: the letter at level 1 (zero detour), training at stops the path makes anyway
-- (the Undercity at 12 and 14, Orgrimmar, Booty Bay), the key ability Poisons at 22 (2460 > 2458 > 2478 from
-- Orgrimmar to the Venture Co. tower in the north of the Barrens and back, 2479 / 2480 at Tarren Mill on the path),
-- the Undead's Deathstalker chain (2,260 XP, all in Brill, the Undercity and on the Silverpine road the path walks)
-- and two optional training detours over the trainer gaps (16-18 from the Crossroads, 24 from Tarren Mill).
--
-- Start zones (level before the first step of the insert: validator --levels of the rogue route, normal / worst):
--   Durotar (Orc, Troll)
--     after dur01-teeth        2.33   the letter 3088 (Orc) / 3083 (Troll) at Gornek > Rwag (nothing to train at 2)
--     after dur01-den-4        4.68   Rwag: training 4 (start-camp trainers teach up to 6)
--     after dur02-garthok      6.45   Kaplak in Razor Hill (next to Garthok): training 6
--     after dur02-garthok-3    9.67   Kaplak: training 8
--     after dur02-rh-3        10.00   Kaplak: training 10 (the gate dur02-lvl-10 guarantees the level)
--   Tirisfal (Undead)
--     after ud01-364           2.61   the letter 3096 at Sarvis > David Trias
--     after ud01-arren-5  4.86 / 4.69 David Trias: training 4
--     after ud02-sethearth 6.41 / 6.33 Marion Call in the Brill inn: training 6
--     after ud02-brill-8   8.18 / 8.13 Marion Call: training 8
--     after ud02-terrence 10.16 / 10.07 Marion Call: training 10 + 1885 (the Deathstalkers, breadcrumb)
--     after ud02-fp-uc    12.09 / 12.10 Rogues' Quarter of the Undercity: 1885 > 1886 at Mennet Carkad, training 12
--     after h13-go-sepulcher  12.24   Astor Hadren on the Silverpine road (the path walks past him): 1886
--     after h13-uc-end        14.22   Mennet (1886 > 1898), training 14, Andron Gant (1898 > 1899, his bookshelf),
--                                     Mennet (1899 > 1978), Varimathras (1978): ~1,200 yd inside the city
--   Zephras Isle (Skyborne)
--     after sd01-rorian        3.02   the letter 92483 at Rorian > Akeri Duskblade (read the note)
--     after sd01-thendal-4     4.77   Akeri: training 4
--     after sd01-innkeeper     6.05   Miriaan Mistblade in Shen'dar (next to the innkeeper): training 6
--     after sd01-illaya-3      8.29   Miriaan: training 8
--     after sd02-valanaar-10  11.21   Eltheen Nightbreeze in Valanaar: training 10
--     after sd02-hearth  12.75 / 12.68 Eltheen: training 12 (the hearth lands in Valanaar)
--
-- Shared path (level before the insert, rogue routes; the four races are within 0.1 of each other from 22 on):
--   12     after h12-fp-uc        Orc / Troll 12.39 / 12.30: Rogues' Quarter of the Undercity (~450 yd more on the way
--                                 to the sewers): Kick.
--   14     after h13-uc-end       Orc / Troll 14.13 / 14.08, Skyborne 15.45 / 15.33 (Undead: the Tirisfal group):
--                                 Rogues' Quarter (~650 yd: from the Apothecarium and back to the lift). Optional:
--                                 Swords at Archibald in the War Quarter.
--   16+18  after h15-end          optional, Orc / Troll 18.03, Undead 18.21, Skyborne 18.68: fly to
--                                 Orgrimmar, the Cleft of Shadow, fly to Camp Taurajo (the next shared flight goes
--                                 there and completes on landing): ~4 min for Pick Lock, Eviscerate 3, Ambush.
--   20+22  after h-22-org-fp      22.04 (Skyborne 22.26): the Cleft of Shadow (Shenthul): training + Poisons part 1: 2460 (salute
--                                 Shenthul), 2458 to Taskmaster Fizzule at the Venture Co. tower (north Barrens, out
--                                 of the main gate and across the river, ~2,500 yd), 2478 at the tower (six kills,
--                                 Gallywix, the tower key, the lockbox), back to Shenthul: 2478 > 2479. ~20 min with the
--                                 quest, 3,255 XP. Mandatory (key ability).
--   Poisons after h22-lydon       23.63 / 22.47: Serge Hinott next to Lydon in Tarren Mill: 2479 > 2480 (no detour,
--                                 1,205 XP): the Poisons skill.
--   24     after h-24-tarrenmill-end  optional, 25.00 / 24.01: fly to the Undercity, poison reagents at Ezekiel Graves,
--                                 the Rogues' Quarter, then the path's hearth to Thunder Bluff (~4 min more).
--   26-30  after h-31-org         31.05: the Cleft of Shadow, next to the flight master (optional: Rekkul's poisons).
--   32+34  after h-34-booty-bay   34.12 / 34.11: Ian Strom in Booty Bay, a few steps from Drizzlik.
--   36     after h-37-bootybay-end 36.06: Ian Strom, before the flight to Grom'gol.
--   38+40  after h41-hearth-org   41.02 / 40.88: the Cleft of Shadow on the way from the inn to the gate (40.04 at
--                                 h-40-org-arrive is 39.98 in the worst case).
--   42+44  after h-44-booty-bay   44.64 / 44.62: Ian Strom (Booty Bay at 45.97 is just short of 46).
--   46+48  after h-50-org-arrive  49.41 / 49.37: the Cleft of Shadow, between the Valley of Spirits and Neeru Fireblade.
--   50+52  after h53-org-hearth   52.73 / 52.69: the Cleft of Shadow between the inn and the flight master.
--   54     after h56-sethearth-org 55.07: the Cleft of Shadow between the inn and the flight master.
--   56     after h-58-org-arrive  57.21 / 57.17: the Cleft of Shadow on the way from the inn to the gate.
--   58+60  after h-60-end         optional: hearth to the Undercity (bound there by the path), the Rogues' Quarter.
-- Not visited: 16-18 when the optional Orgrimmar flight is skipped (the shared path has no rogue trainer between 14
--   and 22: Thunder Bluff only); 24-28 when the optional Undercity flight is skipped (C.2: the trainer gap 22 -> 31);
--   the Undercity at 31.16, 34.05 and 44.02 (Orgrimmar / Booty Bay are next to the steps), 46 at Booty Bay (45.97).
-- Skipped class quests: the Shattered Hand (1859 / 1963 / 1858, Orc and Troll: the Orgrimmar turn-in comes only at
--   22, when the level-13 quests give 10-20 % of their XP); lockpicking practice 2378 / 2380 > 2379 > 2382 > 2381
--   (needs an Orgrimmar visit at 16+, the E.C.A.C. vendor is not in the snapshot; ~1,600 XP); Undead 1998 / 1999 (two
--   Undercity round trips); 6681 (starts from a random pickpocket letter); the Forever-new chains 78676 / 78699 and
--   96779-96786 (outside the snapshot, givers unknown); 8233-8236 (Ravenholdt at 49.6 is below the required 50, the
--   key needs the Sunken Temple).
-- Class reward table: none. The DB snapshot has no reward lists; a wrong index would make the automation take the
--   wrong item. The notes say what to look for (agility, fast weapons for the off hand).
--
-- Automation notes: the only trainer that gives a quest of this file is Shenthul (2460, 2458, 2479) and Marion Call
-- (1885): their training steps are merged with the accept. Every insert follows a step the player has just done (an
-- arrival, a hearth, a turn-in) and leaves the path where it was, or before a shared `fly` / `go` / `hearth` that works
-- from the trainer.

if not AdventureAtlas.AddLibraryInsert then return end
local insert = AdventureAtlas.AddLibraryInsert

local GORNEK = { 1411, 42.06, 68.33 }
local RWAG = { 1411, 41.28, 68.00 }
local KAPLAK = { 1411, 51.98, 43.69 }
local SARVIS = { 1420, 30.84, 66.20 }
local TRIAS = { 1420, 32.53, 65.65 }
local MARION = { 1420, 61.75, 52.00 }
local RORIAN = { 2521, 42.05, 23.49 }
local AKERI = { 2521, 43.74, 24.36 }
local MIRIAAN = { 2521, 43.15, 43.26 }
local ELTHEEN = { 2521, 59.90, 72.48 }
local SHENTHUL = { 1454, 43.05, 53.74 }
local ORG_TRAINERS = { 3327, 3401, 3328 }        -- Gest, Shenthul, Ormok (Cleft of Shadow)
local ORG_FP = { 1454, 45.12, 63.89 }
local ORG_GATE = { 1454, 48.97, 92.84 }
local REKKUL = { 1454, 42.09, 49.48 }
local FIZZULE = { 1413, 55.44, 5.56 }
local TOWER = { 1413, 54.75, 5.65 }
local HINOTT = { 1424, 61.63, 19.19 }
local UC_FP = { 1458, 63.25, 48.56 }
local UC_INN = { 1458, 67.74, 37.89 }
local CAROLYN = { 1458, 83.86, 72.07 }
local UC_TRAINERS = { 4582, 4583, 4584 }         -- Carolyn Ward, Miles Dexter, Gregory Charles (Rogues' Quarter)
local MENNET = { 1458, 83.51, 69.11 }
local ANDRON = { 1458, 54.81, 76.33 }
local VARIMATHRAS = { 1458, 56.25, 92.20 }
local EZEKIEL = { 1458, 75.20, 51.18 }
local ARCHIBALD = { 1458, 57.31, 32.77 }
local ASTOR = { 1421, 49.71, 32.22 }
local IAN = { 1434, 26.82, 77.15 }
local TAURAJO_FP = { 1413, 44.45, 59.15 }

local function spell(ru, en) return { ru = ru, en = en } end
local NEW = { ru = " (новый ранг)", en = " (new rank)" }
local function rank(ru, en) return { ru = ru .. NEW.ru, en = en .. NEW.en } end

local SS = function() return rank("Коварный удар", "Sinister Strike") end
local BS = function() return rank("Удар в спину", "Backstab") end
local EVIS = function() return rank("Потрошение", "Eviscerate") end

------------------------------------------------------------------------------------------------------------------
-- Durotar (Orc, Troll) ------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- The letter: Gornek hands it out in the dialog of the shared turn-in of 788; Rwag stands at the Den, a few steps away.
insert({
    after = "dur01-teeth",
    class = "ROGUE",
    race = "Orc",
    steps = {
        { id = "rog-dur-letter-orc", accept = 3088, npc = 3143, at = GORNEK,
          note = { ru = "Горнек даёт и письмо разбойника: «Зашифрованный пергамент».",
                   en = "Gornek also has the rogue's letter: Encrypted Parchment." } },
        { id = "rog-dur-rwag-orc", turnin = 3088, npc = 3155, at = RWAG,
          note = { ru = "Рваг — тренер разбойников, у Логова рядом с Горнеком. Учить пока нечего (следующее — на 4-м).",
                   en = "Rwag, the rogue trainer, by the Den next to Gornek. Nothing to train yet (next at 4)." } },
    },
})
insert({
    after = "dur01-teeth",
    class = "ROGUE",
    race = "Troll",
    steps = {
        { id = "rog-dur-letter-troll", accept = 3083, npc = 3143, at = GORNEK,
          note = { ru = "Горнек даёт и письмо разбойника: «Зашифрованная табличка».",
                   en = "Gornek also has the rogue's letter: Encrypted Tablet." } },
        { id = "rog-dur-rwag-troll", turnin = 3083, npc = 3155, at = RWAG,
          note = { ru = "Рваг — тренер разбойников, у Логова рядом с Горнеком. Учить пока нечего (следующее — на 4-м).",
                   en = "Rwag, the rogue trainer, by the Den next to Gornek. Nothing to train yet (next at 4)." } },
    },
})
insert({
    after = "dur01-den-4",
    class = "ROGUE",
    race = { "Orc", "Troll" },
    steps = {
        { id = "rog-dur-train-4", train = true, npc = 3155, at = RWAG,
          spells = { spell("Удар в спину", "Backstab"), spell("Обшаривание карманов", "Pick Pocket") },
          note = { ru = "Рваг у Логова: обучение 4-го уровня. «Удар в спину» бьёт только сзади: из незаметности "
                       .. "заходите со спины.",
                   en = "Rwag by the Den: level 4 training. Backstab only works from behind: open from stealth "
                       .. "behind the target." } },
    },
})
insert({
    after = "dur02-garthok",
    class = "ROGUE",
    race = { "Orc", "Troll" },
    steps = {
        { id = "rog-dur-train-6", train = true, npc = 3170, at = KAPLAK,
          spells = { spell("Парализующий удар", "Gouge"), SS() },
          note = { ru = "Каплак, тренер разбойников Колючего Холма (рядом с Гартоком): обучение 6-го уровня.",
                   en = "Kaplak, the Razor Hill rogue trainer (next to Garthok): level 6 training." } },
    },
})
insert({
    after = "dur02-garthok-3",
    class = "ROGUE",
    race = { "Orc", "Troll" },
    steps = {
        { id = "rog-dur-train-8", train = true, npc = 3170, at = KAPLAK,
          spells = { spell("Ускользание", "Evasion"), EVIS() },
          note = { ru = "Каплак рядом с Гартоком: обучение 8-го уровня. «Ускользание» спасает, когда напали двое.",
                   en = "Kaplak next to Garthok: level 8 training. Evasion saves you when two mobs attack." } },
    },
})
insert({
    after = "dur02-rh-3",
    class = "ROGUE",
    race = { "Orc", "Troll" },
    steps = {
        -- CONFIRM: Dual Wield is a trainer spell at 10 (as in the original game)
        { id = "rog-dur-train-10", train = true, npc = 3170, at = KAPLAK,
          spells = { spell("Мясорубка", "Slice and Dice"), spell("Спринт", "Sprint"), spell("Ошеломление", "Sap"),
                     spell("Бой двумя оружиями", "Dual Wield") },
          note = { ru = "Каплак: обучение 10-го уровня. Возьмите второе оружие в левую руку. Его задание «Терзок» "
                       .. "не берите: сдавать его цепочку пришлось бы только на 22-м.",
                   en = "Kaplak: level 10 training. Put a second weapon in the off hand. Skip his quest Therzok: its "
                       .. "chain could only be turned in at 22." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Tirisfal Glades (Undead) --------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud01-364",
    class = "ROGUE",
    race = "Scourge",
    steps = {
        { id = "rog-tir-letter", accept = 3096, npc = 1569, at = SARVIS,
          note = { ru = "Темный жрец Сарвис даёт и письмо разбойника: «Зашифрованный свиток».",
                   en = "Shadow Priest Sarvis also has the rogue's letter: Encrypted Scroll." } },
        { id = "rog-tir-trias", turnin = 3096, npc = 2122, at = TRIAS,
          note = { ru = "Дэвид Триас — тренер разбойников, у входа в церковь Мертвого Звона. Учить пока нечего.",
                   en = "David Trias, the rogue trainer, by the Deathknell church. Nothing to train yet." } },
    },
})
insert({
    after = "ud01-arren-5",
    class = "ROGUE",
    race = "Scourge",
    steps = {
        { id = "rog-tir-train-4", train = true, npc = 2122, at = TRIAS,
          spells = { spell("Удар в спину", "Backstab"), spell("Обшаривание карманов", "Pick Pocket") },
          note = { ru = "Дэвид Триас рядом с Арреном: обучение 4-го уровня (тренеры Мертвого Звона учат до 6-го).",
                   en = "David Trias next to Arren: level 4 training (the Deathknell trainers teach up to 6)." } },
    },
})
insert({
    after = "ud02-sethearth",
    class = "ROGUE",
    race = "Scourge",
    steps = {
        { id = "rog-tir-train-6", train = true, npc = 2130, at = MARION,
          spells = { spell("Парализующий удар", "Gouge"), SS() },
          note = { ru = "Марион Колл, тренер разбойников Брилла, у таверны: обучение 6-го уровня.",
                   en = "Marion Call, the Brill rogue trainer, by the inn: level 6 training." } },
    },
})
insert({
    after = "ud02-brill-8",
    class = "ROGUE",
    race = "Scourge",
    steps = {
        { id = "rog-tir-train-8", train = true, npc = 2130, at = MARION,
          spells = { spell("Ускользание", "Evasion"), EVIS() },
          note = { ru = "Марион Колл у таверны: обучение 8-го уровня.",
                   en = "Marion Call by the inn: level 8 training." } },
    },
})
-- The Deathstalkers (Undead only, 2,260 XP): the breadcrumb 1885 at Marion Call, the rest in the Undercity and on the
-- Silverpine road, all at stops of the path.
insert({
    after = "ud02-terrence",
    class = "ROGUE",
    race = "Scourge",
    steps = {
        -- CONFIRM: Dual Wield is a trainer spell at 10 (as in the original game)
        { id = "rog-tir-train-10", train = true, accept = 1885, npc = 2130, at = MARION,
          spells = { spell("Мясорубка", "Slice and Dice"), spell("Спринт", "Sprint"), spell("Ошеломление", "Sap"),
                     spell("Бой двумя оружиями", "Dual Wield") },
          note = { ru = "Марион Колл: задание «Меннет Каркад» (к нему в Подгород), потом окно обучения 10-го уровня. "
                       .. "Возьмите второе оружие в левую руку.",
                   en = "Marion Call: take Mennet Carkad (to him in the Undercity), then the level 10 training window. "
                       .. "Put a second weapon in the off hand." } },
    },
})
insert({
    after = "ud02-fp-uc",
    class = "ROGUE",
    race = "Scourge",
    steps = {
        { id = "rog-tir-mennet", turnin = 1885, accept = 1886, npc = 6467, at = MENNET,
          note = { ru = "Через Торговый квартал на восток в Квартал Разбойников: Меннет Каркад — «Ловчие смерти» "
                       .. "(Астор Хадрен на дороге в Серебряный бор, путь и так туда идёт).",
                   en = "Through the Trade Quarter east to the Rogues' Quarter: Mennet Carkad - The Deathstalkers "
                       .. "(Astor Hadren on the Silverpine road, where the path goes anyway)." } },
        { id = "rog-tir-train-12", train = true, npc = UC_TRAINERS, at = CAROLYN,
          spells = { spell("Пинок", "Kick"), BS() },
          note = { ru = "Тренеры разбойников рядом: обучение 12-го уровня. «Пинок» прерывает заклинания.",
                   en = "The rogue trainers close by: level 12 training. Kick interrupts spells." } },
    },
})
insert({
    after = "h13-go-sepulcher",
    class = "ROGUE",
    race = "Scourge",
    steps = {
        { id = "rog-tir-astor", complete = 1886, at = ASTOR,
          note = { ru = "Астор Хадрен стоит прямо на дороге: заговорите с ним, он нападёт — заберите «Рекомендательное "
                       .. "письмо Астора».",
                   en = "Astor Hadren stands right on the road: talk to him, he attacks - take Astor's Letter of "
                       .. "Introduction." } },
    },
})
insert({
    after = "h13-uc-end",
    class = "ROGUE",
    race = "Scourge",
    steps = {
        { id = "rog-tir-mennet-2", turnin = 1886, accept = 1898, npc = 6467, at = MENNET,
          note = { ru = "Из Аптекариума на восток в Квартал Разбойников: Меннет Каркад.",
                   en = "From the Apothecarium east to the Rogues' Quarter: Mennet Carkad." } },
        { id = "rog-tir-train-14", train = true, npc = UC_TRAINERS, at = CAROLYN,
          spells = { spell("Ослабление доспеха", "Expose Armor"), spell("Гаррота", "Garrote"), SS() },
          note = { ru = "Тренеры разбойников рядом: обучение 14-го уровня.",
                   en = "The rogue trainers close by: level 14 training." } },
        { id = "rog-tir-andron", turnin = 1898, accept = 1899, npc = 6522, at = ANDRON,
          note = { ru = "Обратно на запад, к Андрону Ганту у Аптекариума.",
                   en = "Back west to Andron Gant by the Apothecarium." } },
        { id = "rog-tir-ledger", complete = 1899, at = { 1458, 55.40, 77.00 },
          note = { ru = "Книжная полка Андрона рядом с ним: «Книга записей Андрона».",
                   en = "Andron's bookshelf next to him: Andron's Ledger." } },
        { id = "rog-tir-mennet-3", turnin = 1899, accept = 1978, npc = 6467, at = MENNET,
          note = { ru = "К Меннету в Квартал Разбойников.",
                   en = "To Mennet in the Rogues' Quarter." } },
        { id = "rog-tir-varimathras", turnin = 1978, npc = 2425, at = VARIMATHRAS,
          note = { ru = "В Королевский квартал (юг города): Вариматрас. Потом к лифту наверх.",
                   en = "To the Royal Quarter (the south of the city): Varimathras. Then to the lift up." } },
        { id = "rog-tir-swords", train = true, optional = true, npc = 11870, at = ARCHIBALD,
          note = { ru = "Необязательно: Арчибальд, мастер оружия в Квартале Воинов (по пути к лифту) — «Мечи», если "
                       .. "ещё не умеете (10 серебра): мечи и булавы — лучшее оружие для правой руки.",
                   en = "Optional: Archibald, the weapon master in the War Quarter (on the way to the lift) - Swords, if "
                       .. "you do not have them yet (10 silver): swords and maces are the best main-hand weapons." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Zephras Isle (Skyborne) ---------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
insert({
    after = "sd01-rorian",
    class = "ROGUE",
    race = "Skyborne",
    steps = {
        { id = "rog-zep-letter", accept = 92483, npc = 251361, at = RORIAN,
          note = { ru = "Rorian даёт и классовое задание разбойника: «Как дома в тени» (At Home in the Shadows).",
                   en = "Rorian also has the rogue's class quest: At Home in the Shadows." } },
        { id = "rog-zep-akeri", turnin = 92483, npc = 251389, at = AKERI,
          note = { ru = "Прочитайте записку (сумка), затем поговорите с Akeri Duskblade рядом. Учить пока нечего.",
                   en = "Read the note (bags), then talk to Akeri Duskblade close by. Nothing to train yet." } },
    },
})
insert({
    after = "sd01-thendal-4",
    class = "ROGUE",
    race = "Skyborne",
    steps = {
        { id = "rog-zep-train-4", train = true, npc = 251389, at = AKERI,
          spells = { spell("Удар в спину", "Backstab"), spell("Обшаривание карманов", "Pick Pocket") },
          note = { ru = "Akeri в Thendal: обучение 4-го уровня (тренеры Thendal учат до 6-го).",
                   en = "Akeri in Thendal: level 4 training (the Thendal trainers teach up to 6)." } },
    },
})
insert({
    after = "sd01-innkeeper",
    class = "ROGUE",
    race = "Skyborne",
    steps = {
        { id = "rog-zep-train-6", train = true, npc = 254087, at = MIRIAAN,
          spells = { spell("Парализующий удар", "Gouge"), SS() },
          note = { ru = "Miriaan Mistblade рядом с трактирщиком Shen'dar: обучение 6-го уровня.",
                   en = "Miriaan Mistblade next to the Shen'dar innkeeper: level 6 training." } },
    },
})
insert({
    after = "sd01-illaya-3",
    class = "ROGUE",
    race = "Skyborne",
    steps = {
        { id = "rog-zep-train-8", train = true, npc = 254087, at = MIRIAAN,
          spells = { spell("Ускользание", "Evasion"), EVIS() },
          note = { ru = "Miriaan у таверны Shen'dar: обучение 8-го уровня.",
                   en = "Miriaan by the Shen'dar inn: level 8 training." } },
    },
})
insert({
    after = "sd02-valanaar-10",
    class = "ROGUE",
    race = "Skyborne",
    steps = {
        -- CONFIRM: Dual Wield is a trainer spell at 10 (as in the original game)
        { id = "rog-zep-train-10", train = true, npc = 252379, at = ELTHEEN,
          spells = { spell("Мясорубка", "Slice and Dice"), spell("Спринт", "Sprint"), spell("Ошеломление", "Sap"),
                     spell("Бой двумя оружиями", "Dual Wield") },
          note = { ru = "Eltheen Nightbreeze, тренер разбойников Валанаара: обучение 10-го уровня. Возьмите второе "
                       .. "оружие в левую руку.",
                   en = "Eltheen Nightbreeze, the Valanaar rogue trainer: level 10 training. Put a second weapon in "
                       .. "the off hand." } },
    },
})
insert({
    after = "sd02-hearth",
    class = "ROGUE",
    race = "Skyborne",
    steps = {
        { id = "rog-zep-train-12", train = true, npc = 252379, at = ELTHEEN,
          spells = { spell("Пинок", "Kick"), BS() },
          note = { ru = "От таверны к Eltheen: обучение 12-го уровня. Следующее — в Подгороде на 14-м.",
                   en = "From the inn to Eltheen: level 12 training. Next: the Undercity at 14." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 12-22 ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h12-fp-uc",
    class = "ROGUE",
    race = { "Orc", "Troll" },
    steps = {
        { id = "rog-train-12", train = true, npc = UC_TRAINERS, at = CAROLYN,
          spells = { spell("Пинок", "Kick"), BS() },
          note = { ru = "Через Торговый квартал на восток в Квартал Разбойников: обучение 12-го уровня. «Пинок» "
                       .. "прерывает заклинания. Потом на запад к стокам.",
                   en = "Through the Trade Quarter east to the Rogues' Quarter: level 12 training. Kick interrupts "
                       .. "spells. Then west to the sewers." } },
    },
})
insert({
    after = "h13-uc-end",
    class = "ROGUE",
    race = { "Orc", "Troll", "Skyborne" },
    steps = {
        { id = "rog-train-14", train = true, npc = UC_TRAINERS, at = CAROLYN,
          spells = { spell("Ослабление доспеха", "Expose Armor"), spell("Гаррота", "Garrote"), SS() },
          note = { ru = "Из Аптекариума на восток в Квартал Разбойников: обучение 14-го уровня (у небожителей — и 12-го).",
                   en = "From the Apothecarium east to the Rogues' Quarter: level 14 training (Skyborne: 12 too)." } },
        { id = "rog-swords", train = true, optional = true, npc = 11870, at = ARCHIBALD,
          note = { ru = "Необязательно: Арчибальд, мастер оружия в Квартале Воинов (по пути к выходу) — «Мечи», если "
                       .. "ещё не умеете (10 серебра): мечи и булавы — лучшее оружие для правой руки.",
                   en = "Optional: Archibald, the weapon master in the War Quarter (on the way out) - Swords, if you "
                       .. "do not have them yet (10 silver): swords and maces are the best main-hand weapons." } },
    },
})
-- 16 and 18 (optional): the path has no rogue trainer between 14 (the Undercity) and 22 (Orgrimmar). From the
-- Crossroads at the end of h-15 the next shared step flies to Camp Taurajo; the detour flies to Orgrimmar first and
-- from there to Camp Taurajo, so the shared flight completes on the landing.
insert({
    after = "h15-end",
    class = "ROGUE",
    steps = {
        { id = "rog-16-fly-org", fly = "Orgrimmar", optional = true, npc = 3310, at = ORG_FP,
          note = { ru = "Необязательно (~4 мин): на Перекрёстке летите в Оргриммар — до 22-го тренеров разбойников "
                       .. "на пути нет, а на 16-м даётся «Вскрытие замка» (понадобится на 22-м).",
                   en = "Optional (~4 min): at the Crossroads fly to Orgrimmar - there is no rogue trainer on the way "
                       .. "until 22, and 16 brings Pick Lock (needed at 22)." } },
        { id = "rog-train-16", train = true, optional = true, npc = ORG_TRAINERS, at = SHENTHUL,
          spells = { spell("Вскрытие замка", "Pick Lock"), spell("Ложный выпад", "Feint"), EVIS(),
                     spell("Внезапный удар", "Ambush"), rank("Парализующий удар", "Gouge") },
          note = { ru = "Расселина Теней (вход у Долины Силы): тренеры разбойников — обучение 16-го уровня (и 18-го, "
                       .. "если он уже есть). Купите «Воровские инструменты» у Реккула рядом и вскрывайте ими "
                       .. "запертые ящики по пути: замку Галливикса на 22-м нужен навык около 80.",
                   en = "The Cleft of Shadow (entrance by the Valley of Strength): the rogue trainers - level 16 "
                       .. "training (and 18 if you have it). Buy Thieves' Tools from Rekkul close by and pick the "
                       .. "locked boxes you meet: Gallywix's lockbox at 22 needs a skill of about 80." } },
        { id = "rog-16-fly-taurajo", fly = "Camp Taurajo", optional = true, npc = 10378, at = TAURAJO_FP,
          note = { ru = "Обратно к Дорасу: летите сразу в Лагерь Таурахо (следующий полёт маршрута туда же).",
                   en = "Back to Doras: fly straight to Camp Taurajo (where the next flight of the path goes)." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- 22: Poisons (key ability) -------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- 2460 > 2458 > 2478 from Shenthul to the Venture Co. tower in the north of the Barrens (the path passed it at 16,
-- too early for the req. level 20) and back; 2479 / 2480 at Serge Hinott in Tarren Mill, where the path arrives at
-- 23.4. Without the return to Shenthul the chain would wait for Orgrimmar at 31.
insert({
    after = "h-22-org-fp",
    class = "ROGUE",
    steps = {
        { id = "rog-train-22", train = true, accept = 2460, npc = 3401, at = SHENTHUL,
          spells = { spell("Рваная рана", "Rupture"), BS(), rank("Гаррота", "Garrote"),
                     spell("Исчезновение", "Vanish"), spell("Отвлечение", "Distract"), SS() },
          note = { ru = "Расселина Теней: Шентул — задание «Салют Расколотой Руки» (начало цепочки ядов), затем окно "
                       .. "обучения 20-го и 22-го уровней.",
                   en = "The Cleft of Shadow: Shenthul - The Shattered Salute (the start of the Poisons chain), then the "
                       .. "level 20 and 22 training window." } },
        { id = "rog-22-salute", complete = 2460, at = SHENTHUL,
          note = { ru = "Выделите Шентула и наберите /salute (/отдать честь).",
                   en = "Target Shenthul and type /salute." } },
        { id = "rog-22-2458", turnin = 2460, accept = 2458, npc = 3401, at = SHENTHUL,
          note = { ru = "Шентул: «Под прикрытием» — к надсмотрщику Физзулу у башни Торговой компании на севере "
                       .. "Степей. Купите «Воровские инструменты» у Реккула рядом, если их нет.",
                   en = "Shenthul: Deep Cover - to Taskmaster Fizzule at the Venture Co. tower in the north of the "
                       .. "Barrens. Buy Thieves' Tools from Rekkul close by if you have none." } },
        { id = "rog-22-gate", go = true, radius = 20, at = ORG_GATE,
          note = { ru = "Из Оргриммара через главные ворота, сразу на запад к реке.",
                   en = "Out of Orgrimmar through the main gate, then straight west to the river." } },
        -- CONFIRM: the Flare Gun summons Fizzule and /salute makes him talk (as in the original game)
        { id = "rog-22-fizzule", turnin = 2458, accept = 2478, npc = 7233, use = 8051, at = FIZZULE,
          note = { ru = "Переплывите реку и идите на северо-запад к башне Торговой компании (55,6; ~6 мин). Выстрелите "
                       .. "из ракетницы (предмет задания) у башни: придёт Физзул — /salute, потом поговорите.",
                   en = "Swim across the river and go north-west to the Venture Co. tower (55,6; ~6 min). Fire the "
                       .. "Flare Gun (quest item) by the tower: Fizzule comes - /salute, then talk to him." } },
        -- CONFIRM: Gallywix's Lockbox needs Pick Lock (about 80 skill, classes.md section 7)
        { id = "rog-22-tower", complete = 2478, at = TOWER,
          note = { ru = "Башня: по 2 мутировавших дрона, дозорных и патрульных; ключ от башни — у бригадира "
                       .. "Силиксиза внизу; Галливикс (элитный, 23) наверху — «Ошеломление» на охрану, бой по "
                       .. "одному; его сундук вскройте «Вскрытием замка».",
                   en = "The tower: 2 each of the Mutated Drones, Lookouts and Patrollers; the tower key from Foreman "
                       .. "Silixiz at the bottom; Gallywix (elite, 23) at the top - Sap the guards, fight one at a "
                       .. "time; pick the lock of his lockbox." } },
        { id = "rog-22-shenthul", turnin = 2478, accept = 2479, npc = 3401, at = SHENTHUL,
          note = { ru = "Обратно в Оргриммар через главные ворота, к Шентулу: «Помощь Хинотта» (Мельница Таррен — путь "
                       .. "туда и идёт). Потом из ворот к дирижаблю.",
                   en = "Back into Orgrimmar through the main gate, to Shenthul: Hinott's Assistance (Tarren Mill, "
                       .. "where the path goes). Then out of the gate to the zeppelin." } },
    },
})
insert({
    after = "h22-lydon",
    class = "ROGUE",
    steps = {
        { id = "rog-22-hinott", turnin = 2479, accept = 2480, npc = 2391, at = HINOTT,
          note = { ru = "Серж Хинотт, алхимик, в двух шагах от Лидона: отдайте образец.",
                   en = "Serge Hinott, the alchemist, two steps from Lydon: hand over the sample." } },
        { id = "rog-22-antidote", complete = 2480, at = HINOTT,
          note = { ru = "Подождите, пока Хинотт сварит противоядие (он снимет отравление).",
                   en = "Wait while Hinott brews the antidote (he cures the poison)." } },
        { id = "rog-22-poisons", turnin = 2480, npc = 2391, at = HINOTT,
          note = { ru = "Хинотт: навык «Яды» — «Быстродействующий яд» на оружие перед каждым боем. Реагенты — у "
                       .. "продавцов ядов (Подгород, Расселина Теней, Гробница).",
                   en = "Hinott: the Poisons skill - Instant Poison on your weapons before every fight. Reagents from "
                       .. "the poison vendors (the Undercity, the Cleft of Shadow, the Sepulcher)." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 24-60 ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- 24 (optional): the trainer gap 22 -> 31 (classes.md 4.3). From Tarren Mill fly to the Undercity, then the path's
-- own hearth to Thunder Bluff works from there.
insert({
    after = "h-24-tarrenmill-end",
    class = "ROGUE",
    steps = {
        { id = "rog-24-fly-uc", fly = "Undercity", optional = true, npc = 4551, at = UC_FP,
          note = { ru = "Необязательно (~4 мин): у Зарис летите в Подгород — следующий тренер разбойников на пути "
                       .. "будет только на 31-м. Камень возвращения потом сработает и оттуда.",
                   en = "Optional (~4 min): fly from Zarise to the Undercity - the next rogue trainer on the path comes "
                       .. "only at 31. The hearth that follows works from there as well." } },
        { id = "rog-24-poisons", vendor = true, optional = true, npc = 4585, at = EZEKIEL,
          note = { ru = "Иезекииль Грейвс, продавец ядов (по пути в Квартал Разбойников): реагенты и флаконы для ядов.",
                   en = "Ezekiel Graves, the poison vendor (on the way to the Rogues' Quarter): poison reagents and "
                       .. "vials." } },
        -- CONFIRM: Shank (Forever-new) is trained at 24
        { id = "rog-train-24", train = true, optional = true, npc = UC_TRAINERS, at = CAROLYN,
          spells = { spell("«Shank» (новый приём)", "Shank"), EVIS(), spell("Поиск ловушек", "Detect Traps") },
          note = { ru = "Квартал Разбойников: обучение 24-го уровня. Потом камень возвращения (следующий шаг).",
                   en = "The Rogues' Quarter: level 24 training. Then the hearthstone (the next step)." } },
    },
})
insert({
    after = "h-31-org",
    class = "ROGUE",
    steps = {
        { id = "rog-train-30", train = true, npc = ORG_TRAINERS, at = SHENTHUL,
          spells = { spell("Удар по почкам", "Kidney Shot"), spell("Подлый трюк", "Cheap Shot"), SS(), BS(),
                     rank("Мясорубка", "Slice and Dice") },
          note = { ru = "От Дораса в Расселину Теней: обучение 24-30-го уровней. Потом из ворот к дирижаблю.",
                   en = "From Doras to the Cleft of Shadow: level 24-30 training. Then out of the gate to the "
                       .. "zeppelin." } },
        { id = "rog-31-poisons", vendor = true, optional = true, npc = 3334, at = REKKUL,
          note = { ru = "Необязательно: Реккул, продавец ядов рядом с тренерами — реагенты для ядов.",
                   en = "Optional: Rekkul, the poison vendor next to the trainers - poison reagents." } },
    },
})
insert({
    after = "h-34-booty-bay",
    class = "ROGUE",
    steps = {
        { id = "rog-train-34", train = true, npc = 1411, at = IAN,
          spells = { spell("Ослепление", "Blind"), EVIS(), rank("Спринт", "Sprint") },
          note = { ru = "Ян Стром, тренер разбойников Пиратской Бухты, в двух шагах: обучение 32-го и 34-го уровней.",
                   en = "Ian Strom, the Booty Bay rogue trainer, a few steps away: level 32 and 34 training." } },
    },
})
insert({
    after = "h-37-bootybay-end",
    class = "ROGUE",
    steps = {
        { id = "rog-train-36", train = true, npc = 1411, at = IAN,
          spells = { BS(), rank("Рваная рана", "Rupture") },
          note = { ru = "Ян Стром рядом: обучение 36-го уровня. Потом к распорядителю полётов.",
                   en = "Ian Strom close by: level 36 training. Then to the flight master." } },
    },
})
insert({
    after = "h41-hearth-org",
    class = "ROGUE",
    steps = {
        { id = "rog-train-40", train = true, npc = ORG_TRAINERS, at = SHENTHUL,
          spells = { SS(), EVIS(), rank("Незаметность", "Stealth"), rank("Ложный выпад", "Feint") },
          note = { ru = "Из таверны в Расселину Теней: обучение 38-го и 40-го уровней. Потом из ворот к дирижаблю.",
                   en = "From the inn to the Cleft of Shadow: level 38 and 40 training. Then out of the gate to the "
                       .. "zeppelin." } },
    },
})
insert({
    after = "h-44-booty-bay",
    class = "ROGUE",
    steps = {
        -- CONFIRM: Shank rank 2 at 44
        { id = "rog-train-44", train = true, npc = 1411, at = IAN,
          spells = { BS(), rank("«Shank»", "Shank"), rank("Рваная рана", "Rupture") },
          note = { ru = "Ян Стром в двух шагах: обучение 42-го и 44-го уровней.",
                   en = "Ian Strom a few steps away: level 42 and 44 training." } },
    },
})
insert({
    after = "h-50-org-arrive",
    class = "ROGUE",
    steps = {
        { id = "rog-train-48", train = true, npc = ORG_TRAINERS, at = SHENTHUL,
          spells = { SS(), EVIS(), rank("Ошеломление", "Sap") },
          note = { ru = "По пути из Долины Духов в Расселину Теней: обучение 46-го и 48-го уровней.",
                   en = "On the way from the Valley of Spirits through the Cleft of Shadow: level 46 and 48 "
                       .. "training." } },
    },
})
insert({
    after = "h53-org-hearth",
    class = "ROGUE",
    steps = {
        { id = "rog-train-52", train = true, npc = ORG_TRAINERS, at = SHENTHUL,
          spells = { BS(), rank("Рваная рана", "Rupture"), rank("Удар по почкам", "Kidney Shot") },
          note = { ru = "От таверны в Расселину Теней: обучение 50-го и 52-го уровней. Потом к Дорасу.",
                   en = "From the inn to the Cleft of Shadow: level 50 and 52 training. Then to Doras." } },
    },
})
insert({
    after = "h56-sethearth-org",
    class = "ROGUE",
    steps = {
        { id = "rog-train-54", train = true, npc = ORG_TRAINERS, at = SHENTHUL,
          spells = { SS(), rank("Гаррота", "Garrote") },
          note = { ru = "От таверны в Расселину Теней: обучение 54-го уровня. Потом к Дорасу.",
                   en = "From the inn to the Cleft of Shadow: level 54 training. Then to Doras." } },
    },
})
insert({
    after = "h-58-org-arrive",
    class = "ROGUE",
    steps = {
        { id = "rog-train-56", train = true, npc = ORG_TRAINERS, at = SHENTHUL,
          spells = { EVIS(), rank("Внезапный удар", "Ambush") },
          note = { ru = "От таверны в Расселину Теней: обучение 56-го уровня. Потом из ворот к дирижаблю.",
                   en = "From the inn to the Cleft of Shadow: level 56 training. Then out of the gate to the "
                       .. "zeppelin." } },
    },
})
-- After 60: the last ranks. The stone is bound in the Undercity (h-58-uc-arrive).
insert({
    after = "h-60-end",
    class = "ROGUE",
    steps = {
        { id = "rog-60-hearth", hearth = "Undercity", optional = true, at = UC_INN,
          note = { ru = "После 60-го: камень возвращения в Подгород.",
                   en = "After 60: hearth to the Undercity." } },
        { id = "rog-train-60", train = true, optional = true, npc = UC_TRAINERS, at = CAROLYN,
          spells = { BS(), rank("Пинок", "Kick"), rank("Рваная рана", "Rupture") },
          note = { ru = "Квартал Разбойников: обучение 58-го и 60-го уровней.",
                   en = "The Rogues' Quarter: level 58 and 60 training." } },
    },
})
