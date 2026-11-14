-- AdventureAtlas_Guides / Classes / Mage.lua
--
-- Every step that exists because of the class (mage), for all three mage races (Orc, Troll, Undead = "Scourge"), as
-- shared inserts with class scope (step ids "mag-..."; below level 12 one group per start zone: "mag-dur-..." Durotar
-- for Orc and Troll, "mag-tir-..." Tirisfal for the Undead). Every insert is anchored on a step with an explicit id of
-- a start-zone or shared segment. Phase C of docs/dev/PLAN.md (D.5); research docs/dev/research/classes.md 5.6, 6.6.
-- Facts (NPC ids and positions, quest ids, chains, race masks, objective spawns): tools/data/forever_db.lua.
-- Spell levels: classes.md 5.6 (the web list for Forever) for the key ones (4 Frostbolt, 6 Fire Blast, 8 Arcane
-- Missiles, 10 Frost Nova / Polymorph, 14 Arcane Explosion, 20 Blizzard + Blink, 30 Ice Armor, 34 Mage Armor); the
-- other ranks are the trainer lists of the original game and only shown as text (the core never reads `spells`).
-- CONFIRM in game.
--
-- What the class does here, speed first: the mage has no key-ability quest (classes.md 5.10), so the file is the
-- letter at level 1, training at stops the path makes anyway (the three capitals all have mage trainers, the Pools of
-- Vision of Thunder Bluff are next to Zamah, whom the path visits four times), and the one class quest chain with a
-- good return: the Undead's 1881 > 1882 at 10-12 (925 XP and a caster item for ~3 minutes).
--
-- Start zones (level before the first step of the insert: validator --levels of the mage route, normal / worst):
--   Durotar (Orc, Troll)
--     after dur01-teeth        2.14   the letter 98576 (Orc) / 3086 (Troll) at Gornek > Mai'ah (nothing to train at 2)
--     after dur01-den-4        4.66   Mai'ah in the Den: training 4 (start-camp trainers teach up to 6)
--     after dur02-xarti        8.17   Un'Thuwa in Sen'jin (Razor Hill has no mage trainer): training 6 + 8 (the path is
--                                     in Sen'jin at 5.4 and at 8.1-9.3 only)
--     after h12-fp-org        11.10   the Valley of Spirits, from the flight master on the way to the inn (~50 s):
--                                     training 10
--     after h12-fp-uc    12.40 / 12.31  optional: the Magic Quarter of the Undercity (~80 s): training 12 (else at 14)
--   Tirisfal (Undead)
--     after ud01-364           2.42   the letter 3098 at Sarvis > Isabella (same chapel)
--     after ud01-arren-4       4.03   Isabella: training 4 (ud01-church-4 is at 3.74)
--     after ud02-sethearth 6.38 / 6.30  Cain Firesong in the Brill inn: training 6
--     after ud02-brill-8   8.18 / 8.13  Cain Firesong: training 8
--     after ud02-terrence 10.16 / 10.07 Cain Firesong: training 10 + 1881; the Undercity (Anastasia: 1881 > 1882) and
--                                     out again on the way to the Rear Guard camp (~3 min)
--     after ud02-balnir   10.97 / 10.88 the Balnir Snapdragons (1882), 50 yd from the path's step
--     after ud02-fp-uc   12.10 / 12.09  the Magic Quarter: Anastasia (1882, she is a mage trainer): training 12
--
-- Shared path (level before the insert; the three races are within 0.5 of each other from 14 on, from 22 on equal):
--   14     after h15-org          14.13 / 14.08 (Undead 14.62 / 14.54): the Valley of Spirits on the way from the inn to
--                                 the gate (~20 s).
--   16+18  after h18-tb-zamah     18.04 / 18.01: Thunder Bluff, Pools of Vision, next to Zamah.
--   20     after h18-sethearth-tb optional, 20.37 / 20.25: from the inn to the Pools of Vision, then to Elder Rise
--                                 (~90 s): Frostbolt 4, Blink, Blizzard 1.6 levels earlier.
--   20+22  after h-22-tb-start    22.05: the Pools of Vision, next to Zamah.
--   24     after h-24-tb-arrive   24.82 / 24.01: the Pools of Vision, next to Zamah.
--   26     after h-27-tb-arrive   27.31 / 27.06: the Pools of Vision, next to Zamah.
--   28+30  after h-31-org         31.05: the Valley of Spirits on the way from the flight master to the gate (~15 s).
--                                 (Thunder Bluff at 28.3-28.7 is ~90 s off the flight master; 28 is a weak set.)
--   32+34  after h-34-uc-arrive   34.05: the Magic Quarter (~90 s; the Undercity at 31.16 is before 32).
--   36     after h-37-orgrimmar   36.06: the Valley of Spirits between the gate and the city (~20 s).
--   38+40  after h-40-org-arrive  40.06 / 40.01: the Valley of Spirits on the way to the flight master (~40 s).
--   42+44  after h-44-uc-arrive   44.02 / 44.00: the Magic Quarter (~90 s; Orgrimmar at 41.0 is before 42).
--   46+48  after h-50-org-arrive  49.40 / 49.36: Uthel'nay, the trainer right next to the step.
--   97286  after h50-owen-thadd   optional, 49.54: Research Access at Owen Thadd (the same NPC).
--   50+52  after h52-uc-81954     52.63 / 52.59: the Magic Quarter, 170 yd from Owen Thadd (~50 s).
--   54     after h56-sethearth-org 55.07: the Valley of Spirits between the inn and the flight master (~50 s).
--   56     after h-58-org-arrive  57.21 / 57.17: the Valley of Spirits between the inn and the gate (~30 s).
--   58+60  after h-60-end         optional: hearth to the Undercity (bound there by the path), the Magic Quarter.
-- Not visited: Orgrimmar at 22.05 (Thunder Bluff the same hour), Thunder Bluff at 28.3-28.7 and 30.9, the Undercity at
--   22.7, 31.2, 41.0, 49.5 and 57.2-58, Orgrimmar at 41.0, 52.7 and 53.05 (the level was just trained or is not
--   reached yet; the stop chosen instead is named above).
--
-- Skipped class quests (classes.md 5.6; XP at the level the path reaches the quest, DB.QuestXp):
--   1959 > 1960 > 1961 > 1962 (Undead / Troll; the Orc is masked out of 1959 / 1960 / 1962): level 15, but the path is
--     in the Undercity at 15+ only at 22.7: 1960 gives 925 XP there, 1961 160 at Ambermill (24), 1962 110 at 31; the
--     Rift Spawns of 1960 sit in the Apothecarium at the far side of the city (~5 min with the fights) and 1961 needs
--     10 Linen Cloth and 6 Dalaran Mana Gems: ~1,260 XP for 6+ minutes, the robe is not worth that.
--   1883 > 1884 (Sen'jin, Echo Isles): needs level 10, the path leaves Sen'jin at 9.3.
--   1881 > 1882 for the Troll: the path passes Brill and the Undercity at 12 in the wrong order (Brill, the Argent camp
--     east of it, then the Undercity); a second trip east to the farm costs ~4 min for 925 XP: not taken.
--   1943-1946 (26, Orgrimmar - Ashenvale - Orgrimmar - the Crossroads), 1947 > 1948-1952 (wand chain, index only, a
--     dungeon book), 1953-1958 (Dustwallow before Desolace in the wrong order, an elite, Uldaman), 8250 Magecraft
--     (510 XP for ~700 yd to Sanath Lim-yo and back at 53, the follow-ups 8251-8253 are index only and end in the
--     Sunken Temple), 7500 (Dire Maul).
-- Not routed: weapon skills (staves are known from level 1, the wand needs no skill; daggers and swords at the weapon
--   masters bring nothing to a caster); the teleports (portal trainers Thuul in the Valley of Spirits, Lexington Mortaim
--   in the Magic Quarter: Teleport: Orgrimmar / Undercity at 20; the route uses the hearthstone and flights, the notes
--   of the training steps at 22 and 34 name them as a spare way back).
-- Class reward table: none. The DB snapshot has no reward lists; a wrong index would make the automation take the
--   wrong item. The notes say what to look for (intellect / spirit cloth, a staff, a wand).
--
-- Automation notes: the trainers that give a quest of this file are Cain Firesong (1881: merged with the training step)
-- and Anastasia Hartwell (1882 is turned in on the training step at 12); Owen Thadd is not a trainer. Every insert
-- follows a step the player has just done (an arrival, a hearth, a turn-in) and leaves the path where it was, or before
-- a shared `go` / `fly` / `hearth` that works from the new place.

if not AdventureAtlas.AddLibraryInsert then return end
local insert = AdventureAtlas.AddLibraryInsert

-- Durotar
local GORNEK = { 1411, 42.06, 68.33 }
local MAIAH = { 1411, 42.51, 69.04 }            -- 5884, Valley of Trials (teaches up to 6)
local UNTHUWA = { 1411, 56.31, 75.11 }          -- 5880, Sen'jin Village
-- Tirisfal
local SARVIS = { 1420, 30.84, 66.20 }
local ISABELLA = { 1420, 30.93, 66.06 }         -- 2124, Deathknell (teaches up to 6)
local CAIN = { 1420, 61.97, 52.47 }             -- 2128, Brill (Gallows' End Tavern)
local UC_GATE = { 1420, 61.92, 64.85 }          -- the lift down from the Ruins of Lordaeron
local SNAPDRAGONS = { 1420, 77.50, 61.88 }      -- Balnir Snapdragons 102985 (6 spawns)
-- Orgrimmar (Valley of Spirits)
local UTHELNAY = { 1454, 39.16, 86.27 }         -- 7311
local ORG_TRAINERS = { 7311, 5882, 5883, 5885 } -- Uthel'nay, Pephredo, Enyo, Deino
-- Thunder Bluff (Pools of Vision under Spirit Rise, next to Zamah)
local XANE = { 1456, 24.40, 17.40 }             -- the middle of the three (each ~26 yd away)
local TB_TRAINERS = { 3049, 3047, 3048 }        -- Thurston Xane, Archmage Shymm, Ursyn Ghull
-- Undercity (Magic Quarter)
local ANASTASIA = { 1458, 85.14, 10.03 }        -- 4568
local PIERCE = { 1458, 85.45, 13.51 }           -- 4567
local UC_TRAINERS = { 4567, 4566, 4568 }        -- Pierce Shackleton, Kaelystia Hatebringer, Anastasia Hartwell
local OWEN = { 1458, 73.40, 33.00 }             -- 211022 Owen Thadd, librarian

local function spell(ru, en) return { ru = ru, en = en } end
local NEW = { ru = " (новый ранг)", en = " (new rank)" }
local function rank(ru, en) return { ru = ru .. NEW.ru, en = en .. NEW.en } end

local FROSTBOLT = function() return rank("Ледяная стрела", "Frostbolt") end
local FIREBALL = function() return rank("Огненный шар", "Fireball") end
local MISSILES = function() return rank("Чародейские стрелы", "Arcane Missiles") end

------------------------------------------------------------------------------------------------------------------
-- Durotar (Orc, Troll) ------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- The letter: Gornek hands it out in the dialog of the shared turn-in of 788; Mai'ah stands in the Den next to him.
insert({
    after = "dur01-teeth",
    class = "MAGE",
    race = "Orc",
    steps = {
        { id = "mag-dur-letter-orc", accept = 98576, npc = 3143, at = GORNEK,
          note = { ru = "Горнек даёт и письмо мага: «Пергамент с глифами».",
                   en = "Gornek also has the mage's letter: Glyphic Parchment." } },
        { id = "mag-dur-maiah-orc", turnin = 98576, npc = 5884, at = MAIAH,
          note = { ru = "Май'а — тренер магов, рядом в Логове (42,5, 69,0). Учить пока нечего (следующее — на 4-м).",
                   en = "Mai'ah, the mage trainer, close by in the Den (42.5, 69.0). Nothing to train yet (next at "
                       .. "4)." } },
    },
})
insert({
    after = "dur01-teeth",
    class = "MAGE",
    race = "Troll",
    steps = {
        { id = "mag-dur-letter-troll", accept = 3086, npc = 3143, at = GORNEK,
          note = { ru = "Горнек даёт и письмо мага: «Табличка с глифами».",
                   en = "Gornek also has the mage's letter: Glyphic Tablet." } },
        { id = "mag-dur-maiah-troll", turnin = 3086, npc = 5884, at = MAIAH,
          note = { ru = "Май'а — тренер магов, рядом в Логове (42,5, 69,0). Учить пока нечего (следующее — на 4-м).",
                   en = "Mai'ah, the mage trainer, close by in the Den (42.5, 69.0). Nothing to train yet (next at "
                       .. "4)." } },
    },
})
insert({
    after = "dur01-den-4",
    class = "MAGE",
    race = { "Orc", "Troll" },
    steps = {
        { id = "mag-dur-train-4", train = true, npc = 5884, at = MAIAH,
          spells = { spell("Ледяная стрела", "Frostbolt"), spell("Сотворение воды", "Conjure Water") },
          note = { ru = "Май'а в Логове: обучение 4-го уровня. «Ледяная стрела» — основное заклинание до конца пути: "
                       .. "враг замедлен и часто не добегает. Пейте сотворённую воду, а не покупайте.",
                   en = "Mai'ah in the Den: level 4 training. Frostbolt is your main spell to the end: the target is "
                       .. "slowed and often never reaches you. Drink conjured water instead of buying it." } },
    },
})
-- 6 and 8 in one visit: Razor Hill has no mage trainer, the path is in Sen'jin at 5.4 and again at 8.1.
insert({
    after = "dur02-xarti",
    class = "MAGE",
    race = { "Orc", "Troll" },
    steps = {
        { id = "mag-dur-train-8", train = true, npc = 5880, at = UNTHUWA,
          spells = { spell("Огненный взрыв", "Fire Blast"), FIREBALL(), spell("Сотворение пищи", "Conjure Food"),
                     spell("Чародейские стрелы", "Arcane Missiles"), FROSTBOLT() },
          note = { ru = "Ун'Тува, тренер магов Сен'джина, рядом с Ксар'Ти: обучение 6-го и 8-го уровней (в Колючем "
                       .. "Холме тренера магов нет). «Огненный взрыв» — добивание без каста.",
                   en = "Un'Thuwa, the Sen'jin mage trainer, next to Xar'Ti: level 6 and 8 training (Razor Hill has "
                       .. "no mage trainer). Fire Blast finishes a target without a cast." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Orgrimmar at 11 and the Undercity at 12 (Orc, Troll) -----------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- The Valley of Spirits lies south-west of the flight master; from there to the inn (the next shared step) is
-- ~50 s more than the direct way.
insert({
    after = "h12-fp-org",
    class = "MAGE",
    race = { "Orc", "Troll" },
    steps = {
        { id = "mag-train-10", train = true, npc = ORG_TRAINERS, at = UTHELNAY,
          spells = { spell("Кольцо льда", "Frost Nova"), spell("Превращение", "Polymorph"),
                     rank("Морозный доспех", "Frost Armor"), rank("Сотворение воды", "Conjure Water") },
          note = { ru = "От распорядителя полётов на юго-запад, в Аллею Духов: тренеры магов (Утел'най и другие) — "
                       .. "обучение 10-го уровня. «Кольцо льда» + шаг назад + «Ледяная стрела» — так маг не получает "
                       .. "урона. Потом в таверну.",
                   en = "From the flight master south-west into the Valley of Spirits: the mage trainers (Uthel'nay "
                       .. "and others) - level 10 training. Frost Nova, step back, Frostbolt: that is how a mage takes "
                       .. "no damage. Then to the inn." } },
    },
})
-- 12 (optional): the Magic Quarter is ~300 yd from the flight master; the next shared step leads out through the
-- sewers and works from there. Skipped: 12 is trained at 14 in Orgrimmar.
insert({
    after = "h12-fp-uc",
    class = "MAGE",
    race = { "Orc", "Troll" },
    steps = {
        { id = "mag-train-12", train = true, optional = true, npc = UC_TRAINERS, at = PIERCE,
          spells = { FIREBALL(), spell("Замедленное падение", "Slow Fall"), rank("Сотворение пищи", "Conjure Food") },
          note = { ru = "Необязательно: Квартал Магов Подгорода (на восток от полётов, ~80 с крюка) — обучение 12-го "
                       .. "уровня. Пропустили — выучите на 14-м в Оргриммаре.",
                   en = "Optional: the Magic Quarter of the Undercity (east of the flight master, ~80 s detour) - level "
                       .. "12 training. Skipped - learn it at 14 in Orgrimmar." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Tirisfal (Undead) ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud01-364",
    class = "MAGE",
    race = "Scourge",
    steps = {
        { id = "mag-tir-letter", accept = 3098, npc = 1569, at = SARVIS,
          note = { ru = "Сарвис даёт и письмо мага: «Свиток с глифами».",
                   en = "Sarvis also has the mage's letter: Glyphic Scroll." } },
        { id = "mag-tir-isabella", turnin = 3098, npc = 2124, at = ISABELLA,
          note = { ru = "Изабелла — тренер магов, в той же часовне. Учить пока нечего (следующее — на 4-м).",
                   en = "Isabella, the mage trainer, in the same chapel. Nothing to train yet (next at 4)." } },
    },
})
-- ud01-church-4 is at 3.74; the next generic step in the chapel (Arren, 4.03) is past 4.
insert({
    after = "ud01-arren-4",
    class = "MAGE",
    race = "Scourge",
    steps = {
        { id = "mag-tir-train-4", train = true, npc = 2124, at = ISABELLA,
          spells = { spell("Ледяная стрела", "Frostbolt"), spell("Сотворение воды", "Conjure Water") },
          note = { ru = "Изабелла в часовне: обучение 4-го уровня. «Ледяная стрела» — основное заклинание до конца "
                       .. "пути: враг замедлен и часто не добегает. Пейте сотворённую воду, а не покупайте.",
                   en = "Isabella in the chapel: level 4 training. Frostbolt is your main spell to the end: the target "
                       .. "is slowed and often never reaches you. Drink conjured water instead of buying it." } },
    },
})
insert({
    after = "ud02-sethearth",
    class = "MAGE",
    race = "Scourge",
    steps = {
        { id = "mag-tir-train-6", train = true, npc = 2128, at = CAIN,
          spells = { spell("Огненный взрыв", "Fire Blast"), FIREBALL(), spell("Сотворение пищи", "Conjure Food") },
          note = { ru = "Каин Огненная Песнь в таверне Брилла: обучение 6-го уровня. «Огненный взрыв» — добивание без "
                       .. "каста.",
                   en = "Cain Firesong in the Brill inn: level 6 training. Fire Blast finishes a target without a "
                       .. "cast." } },
    },
})
insert({
    after = "ud02-brill-8",
    class = "MAGE",
    race = "Scourge",
    steps = {
        { id = "mag-tir-train-8", train = true, npc = 2128, at = CAIN,
          spells = { spell("Чародейские стрелы", "Arcane Missiles"), FROSTBOLT() },
          note = { ru = "Каин Огненная Песнь в таверне: обучение 8-го уровня.",
                   en = "Cain Firesong in the inn: level 8 training." } },
    },
})
-- 10: training and 1881 at Cain (one step: the accept would fast-forward a separate training step), then the
-- Undercity for 1882 before the path turns east to the farm. The lift is on the way from Brill to the Rear Guard camp;
-- the Magic Quarter is the first quarter after the lift (~3 min in all).
insert({
    after = "ud02-terrence",
    class = "MAGE",
    race = "Scourge",
    steps = {
        { id = "mag-tir-train-10", train = true, accept = 1881, npc = 2128, at = CAIN,
          spells = { spell("Кольцо льда", "Frost Nova"), spell("Превращение", "Polymorph"),
                     rank("Морозный доспех", "Frost Armor"), rank("Сотворение воды", "Conjure Water") },
          note = { ru = "Каин Огненная Песнь в таверне: обучение 10-го уровня и задание «Поговорите с Анастасией» — "
                       .. "в Подгород, сейчас (~3 мин): за ним — «Усадьба Бальнира» с предметом для мага.",
                   en = "Cain Firesong in the inn: level 10 training and Speak with Anastasia - to the Undercity, now "
                       .. "(~3 min): it leads to The Balnir Farmstead with a caster item." } },
        { id = "mag-tir-uc-go", go = true, at = UC_GATE,
          note = { ru = "На юг к Руинам Лордерона, на лифте вниз в Подгород.",
                   en = "South to the Ruins of Lordaeron, down the lift into the Undercity." } },
        { id = "mag-tir-anastasia", turnin = 1881, accept = 1882, npc = 4568, at = ANASTASIA,
          note = { ru = "Квартал Магов (сразу от лифта направо, на восток): Анастасия Хартвелл — «Усадьба Бальнира»: "
                       .. "львиный зев на ферме Бальнира, куда путь идёт дальше.",
                   en = "The Magic Quarter (right of the lift, to the east): Anastasia Hartwell - The Balnir "
                       .. "Farmstead: the snapdragons at the Balnir Farmstead, where the path goes next." } },
        { id = "mag-tir-uc-exit", go = true, at = UC_GATE,
          note = { ru = "Лифтом наверх и на восток к лагерю Арьергарда.",
                   en = "Up the lift and east to the Rear Guard camp." } },
    },
})
insert({
    after = "ud02-balnir",
    class = "MAGE",
    race = "Scourge",
    steps = {
        { id = "mag-tir-snapdragons", complete = 1882, object = 102985, at = SNAPDRAGONS,
          note = { ru = "Львиный зев Бальнира — цветы у дома фермы (77,4, 61,9).",
                   en = "Balnir Snapdragons - the flowers by the farmhouse (77.4, 61.9)." } },
    },
})
-- 12: Anastasia is a mage trainer herself: the turn-in and the training are one step.
insert({
    after = "ud02-fp-uc",
    class = "MAGE",
    race = "Scourge",
    steps = {
        { id = "mag-tir-train-12", train = true, turnin = 1882, npc = 4568, at = ANASTASIA,
          spells = { FIREBALL(), spell("Замедленное падение", "Slow Fall"), rank("Сотворение пищи", "Conjure Food") },
          note = { ru = "Квартал Магов (на восток от полётов): Анастасия Хартвелл — сдайте «Усадьбу Бальнира» "
                       .. "(возьмите посох или вещь с интеллектом) и обучение 12-го уровня у неё же. Потом к лифту.",
                   en = "The Magic Quarter (east of the flight master): Anastasia Hartwell - turn in The Balnir "
                       .. "Farmstead (take the staff or the intellect item) and level 12 training from her. Then to "
                       .. "the lift." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 14-22 ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- 14: from the inn to the main gate the Valley of Spirits is ~20 s off the way (all three races pass here).
insert({
    after = "h15-org",
    class = "MAGE",
    steps = {
        { id = "mag-train-14", train = true, npc = ORG_TRAINERS, at = UTHELNAY,
          spells = { spell("Чародейский взрыв", "Arcane Explosion"), FROSTBOLT(),
                     rank("Чародейский интеллект", "Arcane Intellect"), rank("Огненный взрыв", "Fire Blast") },
          note = { ru = "По пути к главным воротам — Аллея Духов (юго-запад города): обучение 14-го уровня (и 12-го, "
                       .. "если пропустили). «Чародейский взрыв» — для групп в «Кольце льда».",
                   en = "On the way to the main gate - the Valley of Spirits (south-west of the city): level 14 "
                       .. "training (and 12 if you skipped it). Arcane Explosion is for packs inside Frost Nova." } },
    },
})
-- 16 + 18: Zamah's cave is the Pools of Vision; the mage trainers stand around the pools.
insert({
    after = "h18-tb-zamah",
    class = "MAGE",
    steps = {
        { id = "mag-train-18", train = true, npc = TB_TRAINERS, at = XANE,
          spells = { spell("Огненный столп", "Flamestrike"), MISSILES(), FIREBALL(),
                     spell("Снятие малого проклятия", "Remove Lesser Curse") },
          note = { ru = "Пруды Видений: тренеры магов рядом с Замой (Тёрстон Ксейн, Архимаг Шимм) — обучение 16-го "
                       .. "и 18-го уровней.",
                   en = "The Pools of Vision: the mage trainers next to Zamah (Thurston Xane, Archmage Shymm) - level "
                       .. "16 and 18 training." } },
    },
})
-- 20 (optional): from the inn the Pools of Vision are on the west mesa, Elder Rise (the next shared step) on the east
-- one: ~90 s more. Skipped: 20 is trained at 22, at the same pools.
insert({
    after = "h18-sethearth-tb",
    class = "MAGE",
    steps = {
        { id = "mag-train-20", train = true, optional = true, npc = TB_TRAINERS, at = XANE,
          spells = { FROSTBOLT(), spell("Скачок", "Blink"), spell("Снежная буря", "Blizzard"),
                     spell("Прилив сил", "Evocation"), spell("Щит маны", "Mana Shield") },
          note = { ru = "Необязательно (~90 с): от таверны по мосту на Вершину Духов, вниз в Пруды Видений — обучение "
                       .. "20-го уровня; потом на Вершину Старейшин. Пропустили — выучите на 22-м там же.",
                   en = "Optional (~90 s): from the inn over the bridge to Spirit Rise, down into the Pools of Vision - "
                       .. "level 20 training; then to Elder Rise. Skipped - learn it at 22 at the same place." } },
    },
})
insert({
    after = "h-22-tb-start",
    class = "MAGE",
    steps = {
        { id = "mag-train-22", train = true, npc = TB_TRAINERS, at = XANE,
          spells = { spell("Ожог", "Scorch"), spell("Скачок", "Blink"), spell("Снежная буря", "Blizzard"),
                     spell("Прилив сил", "Evocation"), rank("Чародейский взрыв", "Arcane Explosion") },
          note = { ru = "Тренеры магов рядом с Замой: обучение 22-го уровня (и 20-го, если пропустили). Телепорты в "
                       .. "Оргриммар и Подгород (с 20-го) продают учителя порталов в этих городах — запасной путь, "
                       .. "когда камень возвращения на перезарядке; маршрут их не требует.",
                   en = "The mage trainers next to Zamah: level 22 training (and 20 if you skipped it). Teleports to "
                       .. "Orgrimmar and the Undercity (from 20) are sold by the portal trainers of those cities - a "
                       .. "spare way back when the hearthstone is on cooldown; the route does not need them." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 24-60 ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-24-tb-arrive",
    class = "MAGE",
    steps = {
        { id = "mag-train-24", train = true, npc = TB_TRAINERS, at = XANE,
          spells = { FIREBALL(), MISSILES(), spell("Антимагия", "Counterspell") },
          note = { ru = "Пруды Видений, рядом с Замой: обучение 24-го уровня.",
                   en = "The Pools of Vision, next to Zamah: level 24 training." } },
    },
})
insert({
    after = "h-27-tb-arrive",
    class = "MAGE",
    steps = {
        { id = "mag-train-26", train = true, npc = TB_TRAINERS, at = XANE,
          spells = { FROSTBOLT(), spell("Конус холода", "Cone of Cold"), rank("Кольцо льда", "Frost Nova") },
          note = { ru = "Пруды Видений, рядом с Замой: обучение 26-го уровня.",
                   en = "The Pools of Vision, next to Zamah: level 26 training." } },
    },
})
-- 28 + 30: the path flies into Orgrimmar and walks out of the main gate to the zeppelin; the Valley of Spirits is
-- ~15 s off that way.
insert({
    after = "h-31-org",
    class = "MAGE",
    steps = {
        { id = "mag-train-30", train = true, npc = ORG_TRAINERS, at = UTHELNAY,
          spells = { spell("Ледяной доспех", "Ice Armor"), FIREBALL(), rank("Снежная буря", "Blizzard"),
                     rank("Щит маны", "Mana Shield"), rank("Ожог", "Scorch") },
          note = { ru = "От полётов к главным воротам через Аллею Духов: обучение 28-го и 30-го уровней. «Ледяной "
                       .. "доспех» вместо «Морозного».",
                   en = "From the flight master to the main gate through the Valley of Spirits: level 28 and 30 "
                       .. "training. Ice Armor replaces Frost Armor." } },
    },
})
-- 32 + 34: the Magic Quarter, east of the flight master; the next shared step is Faranell in the Apothecarium.
insert({
    after = "h-34-uc-arrive",
    class = "MAGE",
    steps = {
        { id = "mag-train-34", train = true, npc = UC_TRAINERS, at = PIERCE,
          spells = { FROSTBOLT(), spell("Магический доспех", "Mage Armor"), MISSILES(),
                     rank("Конус холода", "Cone of Cold") },
          note = { ru = "Квартал Магов (на восток от полётов): обучение 32-го и 34-го уровней. Потом в Чумной квартал "
                       .. "к Фаранеллу.",
                   en = "The Magic Quarter (east of the flight master): level 32 and 34 training. Then to Faranell in "
                       .. "the Apothecarium." } },
    },
})
-- 36: the Valley of Spirits lies between the main gate and the city centre.
insert({
    after = "h-37-orgrimmar",
    class = "MAGE",
    steps = {
        { id = "mag-train-36", train = true, npc = ORG_TRAINERS, at = UTHELNAY,
          spells = { FIREBALL(), rank("Снежная буря", "Blizzard"), rank("Щит маны", "Mana Shield") },
          note = { ru = "От главных ворот — Аллея Духов (по пути): обучение 36-го уровня.",
                   en = "From the main gate - the Valley of Spirits (on the way): level 36 training." } },
    },
})
-- 38 + 40: from Keldran to the flight master (the next shared step) through the Valley of Spirits (~40 s).
insert({
    after = "h-40-org-arrive",
    class = "MAGE",
    steps = {
        { id = "mag-train-40", train = true, npc = ORG_TRAINERS, at = UTHELNAY,
          spells = { FROSTBOLT(), rank("Ледяной доспех", "Ice Armor"), rank("Кольцо льда", "Frost Nova"),
                     rank("Чародейский взрыв", "Arcane Explosion") },
          note = { ru = "Аллея Духов по пути к распорядителю полётов: обучение 38-го и 40-го уровней. Порталы (с "
                       .. "40-го) для прокачки не нужны.",
                   en = "The Valley of Spirits on the way to the flight master: level 38 and 40 training. Portals "
                       .. "(from 40) are not needed for leveling." } },
    },
})
-- 42 + 44: the path flies into the Undercity and leaves it by the lift to the zeppelin for Grom'gol.
insert({
    after = "h-44-uc-arrive",
    class = "MAGE",
    steps = {
        { id = "mag-train-44", train = true, npc = UC_TRAINERS, at = PIERCE,
          spells = { FROSTBOLT(), FIREBALL(), rank("Снежная буря", "Blizzard"), rank("Конус холода", "Cone of Cold") },
          note = { ru = "Квартал Магов (на восток от полётов): обучение 42-го и 44-го уровней. Потом к лифту и к "
                       .. "дирижаблю в Громгол.",
                   en = "The Magic Quarter (east of the flight master): level 42 and 44 training. Then to the lift "
                       .. "and the zeppelin to Grom'gol." } },
    },
})
-- 46 + 48: the shared turn-in of 3002 is in the Valley of Spirits, next to Uthel'nay.
insert({
    after = "h-50-org-arrive",
    class = "MAGE",
    steps = {
        { id = "mag-train-48", train = true, npc = ORG_TRAINERS, at = UTHELNAY,
          spells = { FIREBALL(), MISSILES(), rank("Ожог", "Scorch"), rank("Магический доспех", "Mage Armor") },
          note = { ru = "Тренеры магов прямо здесь, в Аллее Духов: обучение 46-го и 48-го уровней.",
                   en = "The mage trainers right here in the Valley of Spirits: level 46 and 48 training." } },
    },
})
-- Research Access (Forever-new, mage only): Owen Thadd offers it once a library book quest has been turned in to him
-- (the shared step before). XP and reward unknown; the quest is level 20, so it is grey at 49.
insert({
    after = "h50-owen-thadd",
    class = "MAGE",
    steps = {
        -- CONFIRM: 97286 has no objective (accept and turn in at once) and what it gives a mage
        { id = "mag-research", accept = 97286, turnin = 97286, optional = true, npc = 211022, at = OWEN,
          note = { ru = "Необязательно: Оуэн Тадд предлагает магу «Доступ к исследованиям» — возьмите и сразу сдайте "
                       .. "(опыта почти нет, награда неизвестна).",
                   en = "Optional: Owen Thadd offers a mage Research Access - accept and turn it in at once (almost no "
                       .. "XP, the reward is unknown)." } },
    },
})
-- 50 + 52: the Magic Quarter is 170 yd from Owen Thadd; the next shared step leads to the zeppelin.
insert({
    after = "h52-uc-81954",
    class = "MAGE",
    steps = {
        { id = "mag-train-52", train = true, npc = UC_TRAINERS, at = PIERCE,
          spells = { FROSTBOLT(), rank("Ледяной доспех", "Ice Armor"), MISSILES(), rank("Кольцо льда", "Frost Nova") },
          note = { ru = "Квартал Магов рядом с библиотекой: обучение 50-го и 52-го уровней. Потом к лифту и дирижаблю.",
                   en = "The Magic Quarter next to the library: level 50 and 52 training. Then to the lift and the "
                       .. "zeppelin." } },
    },
})
-- 54: from the inn through the Valley of Spirits to the flight master (the next shared step flies to Splintertree).
insert({
    after = "h56-sethearth-org",
    class = "MAGE",
    steps = {
        { id = "mag-train-54", train = true, npc = ORG_TRAINERS, at = UTHELNAY,
          spells = { FIREBALL(), rank("Снежная буря", "Blizzard"), rank("Магический доспех", "Mage Armor") },
          note = { ru = "От таверны через Аллею Духов к распорядителю полётов: обучение 54-го уровня.",
                   en = "From the inn through the Valley of Spirits to the flight master: level 54 training." } },
    },
})
-- 56: the hearth lands at the inn, the path walks out of the main gate to the zeppelin past the Valley of Spirits.
insert({
    after = "h-58-org-arrive",
    class = "MAGE",
    steps = {
        { id = "mag-train-56", train = true, npc = ORG_TRAINERS, at = UTHELNAY,
          spells = { FROSTBOLT(), MISSILES(), rank("Конус холода", "Cone of Cold") },
          note = { ru = "От таверны к главным воротам через Аллею Духов: обучение 56-го уровня.",
                   en = "From the inn to the main gate through the Valley of Spirits: level 56 training." } },
    },
})
-- 58 + 60 (optional): the route ends at Light's Hope; the path bound the stone in the Undercity at 57.
insert({
    after = "h-60-end",
    class = "MAGE",
    steps = {
        { id = "mag-60-hearth", hearth = "Undercity", optional = true, at = { 1458, 67.74, 37.89 },
          note = { ru = "Необязательно: камень возвращения в Подгород (он там привязан).",
                   en = "Optional: hearth to the Undercity (the stone is bound there)." } },
        { id = "mag-train-60", train = true, optional = true, npc = UC_TRAINERS, at = PIERCE,
          spells = { FIREBALL(), rank("Ледяной доспех", "Ice Armor"), rank("Снежная буря", "Blizzard") },
          note = { ru = "Квартал Магов: обучение 58-го и 60-го уровней.",
                   en = "The Magic Quarter: level 58 and 60 training." } },
    },
})
