-- AdventureAtlas_Guides / Segments / Durotar / 01_ValleyOfTrials.lua
--
-- Segment dur-01-valley-of-trials: character creation (the Den, Valley of Trials) -> leaving the valley,
-- levels 1-5, Orc and Troll. Class-neutral: every Orc and Troll class walks these steps. What exists because of
-- a class (the letter of the class at level 1, class quests, training) is a shared insert of
-- Classes/<Class>.lua on the anchors below. The one exception is the game's own class branch: 792 Vile Familiars
-- is offered to every class but the warlock, who gets 1485 -> 1499 from Ruzan instead (both lead to 794): a pair
-- of class-filtered base steps (docs/dev/PLAN.md R4).
-- Coordinates: Forever uiMap 1411 (Durotar), map percent, from tools/data/forever_db.lua (NPC / object spawns;
-- centroids of the objective mob / object spawns for complete steps).
--
-- Hub plan (Forever DB):
--   camp 1 : 4641 Kaltunk > Gornek (788, 97279).
--   boars  : 788 boars + 97279 training weapons, east of the camp.
--   camp 2 : 788 > 789 (letter of the class here), 97279 Kzan, 4402 Galgar, 792 Zureetha (warlock: 1485 Ruzan).
--   west   : 790 Hana'zua, scorpid tails 789, cactus apples 4402, Sarkoth 790 > 804.
--   camp 3 : 789 + 804 Gornek, 4402 Galgar, 5441 Thazz'ril (needs level 3).
--   north 1: lazy peons 5441, 12 Vile Familiars 792 (warlock: 6 heads for 1485).
--   camp 4 : 792 > 794 (warlock: 1485 > 1499 > 794), 5441 > 6394.
--   north 2: the Burning Blade Coven: Yarrog 794, Thazz'ril's Pick 6394.
--   camp 5 : 6394, 794 > 805, the Lost Journal 96652.
-- Skipped: 5843 Welcome! (gift voucher of a special edition, not in every bag), 787 (Orgrimmar-side breadcrumb).
-- Carried into the next segment: 805 (Master Gadrin, Sen'jin Village), 96652 (Brakk, south of Razor Hill).
-- Hearthstone: not touched (starting bind).
--
-- Anchors for class files (docs/dev/PLAN.md C.2; level of the base profile before the step: tools/validate_routes.lua
-- --levels; the hand-over docs/dev/handover/p1-durotar.md has the measured list):
--   dur01-teeth         turn in 788 at Gornek: the letter of the class (Gornek gives it after 788), first training
--   dur01-familiars     accept 792 at Zureetha (class = every class but WARLOCK)
--   dur01-warlock-1485  accept 1485 at Ruzan (class = "WARLOCK"; the alternative of dur01-familiars)
--   dur01-den-4         accept 794 at Zureetha (join step of the class branch, in the Den): training at 4
--   dur01-leave         turn in 794, accept 805 at Zureetha, in the Den: last visit of the valley trainers
--                       (start-camp trainers teach up to level 6); dur01-journal (96652, the Lost Journal on the
--                       ground next to her) is the last step of the segment
-- Trainers (all in or next to the Den, 42-43, 68-69): warrior Frang, hunter Jen'shan, mage Mai'ah, priest Ken'jai,
-- shaman Shikrik; rogue Rwag and warlock Nartok (demon trainer Hraug) in the west building (40.6-41.3, 68).
if not AdventureAtlas.AddLibraryInsert then return end

-- every Orc / Troll class but the warlock (792 Vile Familiars has the class mask "all but WARLOCK")
local NOT_WARLOCK = { "HUNTER", "MAGE", "PRIEST", "ROGUE", "SHAMAN", "WARRIOR" }

AdventureAtlas.AddLibrarySegment({
    id = "dur-01-valley-of-trials",
    title = { ru = "1-5 Долина Испытаний", en = "1-5 Valley of Trials" },
    zone = "Durotar",
    levels = { 1, 5 },
    steps = {
        ------------------------------------------------------------------
        -- The Den (level 1)
        ------------------------------------------------------------------
        { id = "dur01-start", accept = 4641, npc = 10176, at = { 1411, 43.29, 68.53 },
          note = { ru = "Калтунк стоит прямо перед вами у Логова.",
                   en = "Kaltunk stands right in front of you by the Den." } },
        { id = "dur01-gornek", turnin = 4641, accept = { 788, 97279 }, npc = 3143, at = { 1411, 42.06, 68.33 },
          note = { ru = "Горнек в Логове за вашей спиной.",
                   en = "Gornek in the Den behind you." } },
        -- level 2: 792 (accepted three steps later) requires it; the 10 boars give it.
        { id = "dur01-boars", complete = { 788, 97279 }, level = 2, at = { 1411, 44.2, 66.2 },
          note = { ru = "К востоку и северу от Логова: 10 пестрых вепрей и 6 брошенных учебных клинков на земле "
                       .. "(этого хватает на 2-й уровень).",
                   en = "East and north of the Den: 10 Mottled Boars and 6 Abandoned Training Weapons on the "
                       .. "ground (enough for level 2)." } },
        { id = "dur01-teeth", turnin = 788, accept = 789, npc = 3143, at = { 1411, 42.06, 68.33 },
          note = { ru = "Горнек: сдайте вепрей и возьмите следующее задание.",
                   en = "Gornek: turn in the boars and take his next quest." } },
        { id = "dur01-kzan", turnin = 97279, npc = 3159, at = { 1411, 40.47, 68.00 },
          note = { ru = "Кзан Терновый Клинок, оружейник у западного дома.",
                   en = "Kzan Thornslash, the weaponsmith by the west building." } },
        { id = "dur01-galgar", accept = 4402, npc = 9796, at = { 1411, 42.73, 67.23 },
          note = { ru = "Галгар у костра перед Логовом.", en = "Galgar by the fire in front of the Den." } },
        -- The game's class branch (docs/dev/PLAN.md R4): 792 for every class but the warlock, 1485 for the warlock.
        { id = "dur01-familiars", accept = 792, class = NOT_WARLOCK, npc = 3145, at = { 1411, 42.85, 69.15 },
          note = { ru = "Зуреета Дальновидная у входа в Логово.",
                   en = "Zureetha Fargaze at the Den entrance." } },
        { id = "dur01-warlock-1485", accept = 1485, class = "WARLOCK", npc = 5765, at = { 1411, 42.59, 69.00 },
          note = { ru = "Рузан у входа в Логово (задание только для чернокнижников).",
                   en = "Ruzan at the Den entrance (a warlock-only quest)." } },

        ------------------------------------------------------------------
        -- West of the Den: scorpids, cactus apples, Sarkoth (level 2-3)
        ------------------------------------------------------------------
        { id = "dur01-hanazua", accept = 790, npc = 3287, at = { 1411, 40.60, 62.58 },
          note = { ru = "Хана'зуа к северо-западу от Логова.",
                   en = "Hana'zua north-west of the Den." } },
        { id = "dur01-tails-bg", complete = { 789, 4402 }, bg = true, at = { 1411, 43.0, 63.7 },
          note = { ru = "Попутно: скорпиды-рабочие (хвосты) и кактусовые яблоки по всей долине.",
                   en = "On the way: Scorpid Workers (tails) and Cactus Apples all over the valley." } },
        { id = "dur01-sarkoth", complete = 790, at = { 1411, 40.5, 66.8 },
          note = { ru = "Саркот - большой скорпид к югу от Хана'зуа.",
                   en = "Sarkoth, the big scorpid south of Hana'zua." } },
        { id = "dur01-tails", complete = { 789, 4402 }, at = { 1411, 42.0, 60.5 },
          note = { ru = "Добейте 10 хвостов скорпидов-рабочих и соберите 10 кактусовых яблок.",
                   en = "Finish 10 Scorpid Worker Tails and 10 Cactus Apples." } },
        { id = "dur01-hanazua-2", turnin = 790, accept = 804, npc = 3287, at = { 1411, 40.60, 62.58 },
          note = { ru = "Хана'зуа: следующее задание сдаётся Горнеку.",
                   en = "Hana'zua: her next quest goes to Gornek." } },

        ------------------------------------------------------------------
        -- Camp, then north: Vile Familiars and the lazy peons (level 3-4)
        ------------------------------------------------------------------
        { id = "dur01-camp-3", turnin = { 789, 804 }, npc = 3143, at = { 1411, 42.06, 68.33 },
          note = { ru = "Горнек в Логове.", en = "Gornek in the Den." } },
        { id = "dur01-galgar-2", turnin = 4402, npc = 9796, at = { 1411, 42.73, 67.23 } },
        { id = "dur01-thazzril", accept = 5441, npc = 11378, at = { 1411, 44.63, 68.65 },
          note = { ru = "Бригадир Тазз'рил к востоку от Логова (нужен 3-й уровень).",
                   en = "Foreman Thazz'ril east of the Den (needs level 3)." } },
        { id = "dur01-peons-bg", complete = 5441, bg = true, at = { 1411, 43.9, 64.5 },
          note = { ru = "Попутно: дубинкой из задания будите спящих ленивых батраков.",
                   en = "On the way: use the blackjack from the quest on the sleeping Lazy Peons." } },
        { id = "dur01-vile-familiars", complete = 792, class = NOT_WARLOCK, at = { 1411, 44.4, 55.5 },
          note = { ru = "На севере долины у пещеры: 12 злобных бесов-фамилиаров.",
                   en = "In the north of the valley by the cave: 12 Vile Familiars." } },
        { id = "dur01-warlock-heads", complete = 1485, class = "WARLOCK", at = { 1411, 44.4, 55.5 },
          note = { ru = "На севере долины у пещеры: 6 голов злобных бесов-фамилиаров.",
                   en = "In the north of the valley by the cave: 6 Vile Familiar Heads." } },
        { id = "dur01-peons", complete = 5441, at = { 1411, 43.9, 64.5 },
          note = { ru = "Добудите ленивых батраков на обратном пути.",
                   en = "Finish the Lazy Peons on the way back." } },
        { id = "dur01-familiars-done", turnin = 792, class = NOT_WARLOCK, npc = 3145, at = { 1411, 42.85, 69.15 } },
        { id = "dur01-warlock-1499", turnin = 1485, accept = 1499, class = "WARLOCK", npc = 5765,
          at = { 1411, 42.59, 69.00 } },
        { id = "dur01-warlock-zureetha", turnin = 1499, class = "WARLOCK", npc = 3145, at = { 1411, 42.85, 69.15 } },
        { id = "dur01-den-4", accept = 794, npc = 3145, at = { 1411, 42.85, 69.15 },
          note = { ru = "Зуреета: медальон Пылающего Клинка у Яррога в пещере на севере.",
                   en = "Zureetha: the Burning Blade Medallion is on Yarrog in the cave to the north." } },
        { id = "dur01-thazzril-2", turnin = 5441, accept = 6394, npc = 11378, at = { 1411, 44.63, 68.65 } },

        ------------------------------------------------------------------
        -- The Burning Blade Coven (level 4-5)
        ------------------------------------------------------------------
        { id = "dur01-cave", complete = { 794, 6394 }, at = { 1411, 43.2, 53.4 },
          note = { ru = "Пещера Ковена Пылающего Клинка на севере: кирка Тазз'рила на земле и Яррог Темная Погибель "
                       .. "внутри.",
                   en = "The Burning Blade Coven cave in the north: Thazz'ril's Pick on the ground and Yarrog "
                       .. "Baneshadow inside." } },
        { id = "dur01-thazzril-3", turnin = 6394, npc = 11378, at = { 1411, 44.63, 68.65 } },
        { id = "dur01-leave", turnin = 794, accept = 805, npc = 3145, at = { 1411, 42.85, 69.15 },
          note = { ru = "Зуреета: сдайте медальон, возьмите отчёт в деревню Сен'джин.",
                   en = "Zureetha: turn in the medallion and take the report to Sen'jin Village." } },
        { id = "dur01-journal", accept = 96652, object = 654925, at = { 1411, 42.80, 69.10 },
          note = { ru = "Рядом на земле - Потерянный дневник: из него задание для лагеря к югу от Колючего Холма.",
                   en = "The Lost Journal on the ground next to her: it starts a quest for the camp south of Razor "
                       .. "Hill." } },
        -- Requirement gate (docs/dev/PLAN.md B.8): 818 and 786 in Sen'jin need level 5. The base profile is at
        -- 5.36 here (0 kills); the gate is the guarantee against lower real XP.
        { id = "dur01-lvl-5", level = 5, at = { 1411, 44.4, 55.5 },
          note = { ru = "5-й уровень перед уходом из долины: он нужен для заданий в Сен'джине. Не хватает - "
                       .. "злобные бесы у пещеры на севере.",
                   en = "Level 5 before leaving the valley: the quests in Sen'jin need it. Short: the Vile "
                       .. "Familiars by the cave to the north." } },
    },
})
