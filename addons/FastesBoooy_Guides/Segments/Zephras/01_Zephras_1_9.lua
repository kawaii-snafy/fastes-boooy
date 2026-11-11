-- FastesBoooy_Guides / Segments / Zephras / 01_Zephras_1_9.lua
-- Segment "sd-01-zephras": Zephras Isle (uiMap 2521), levels 1-9, the start zone of the Skyborne (Windshaper
-- side). Class-neutral: every Skyborne class walks it; what exists because of a class (the level-1 letter, the
-- training visits, class gear, reward choices) is in Classes/<Class>.lua as shared inserts on the anchors below.
-- Thendal Grove (start; hearth back to the camp at 3) -> ursera den -> Al'Aketh camp -> Shen'dar Village (loops:
-- NE highlands, SW hippogryph vale + Vulgara, then straight down to Falaath and back up for one combined Shen'dar
-- visit, western watchtower + Falaath) -> ends at Constable Aonda with 92579 + 93948 (both lead to Valanaar) in
-- the quest log.
--
-- Anchors for the class files (docs/dev/PLAN.md C.2; level = validator level of the base profile before the step):
--   sd01-rorian      2.8  Rorian: 92461 + 92474 in, 92464 out. The class letter (92482 hunter, 92483 rogue,
--                         92484 shaman, 92485 druid, 92532 warrior) is given by Rorian after 92461; the start-camp
--                         trainers stand around him (they teach to level 6 only).
--   sd01-thendal-4   4.7  the last generic step of the level-4 visit of the camp (Valreaa, accept 92473);
--                         sd01-rorian-4 is the Rorian step of that visit.
--   sd01-innkeeper   6.0  Shen'dar inn (talk objective of 92514); sd01-raan-2 (6.2) is the last step west of the
--                         trainers, sd01-aonda-2 the first east of them.
--   sd01-shendar-8   9.1  the last generic step of the level-8 visit of Shen'dar (Teeri, turn-in of 92516);
--                         sd01-danarii-2 (8.9) is the step next to the trainers.
-- Every step has an explicit id (prefix "sd01-"). No `reward` here: reward choices differ per class and live in
-- the class reward table of the class file (FastesBoooy.AddLibraryData{ rewards = ... }).
--
-- Coordinates: Forever DB snapshot (tools/data/forever_db.lua): NPC / object spawns and centroids of the
-- objective mob / object spawns. Glide points (Walk on Air) are terrain points cross-checked with the reference.
-- Every Zephras quest is Forever-new, so its XP is unknown offline: the xp-unknown INFO on each turn-in is
-- expected (estimated XP is used).
-- Hearthstone: used once at level 3 from Yala back to the camp (default bind Thendal Village, as the reference
-- does), then left alone: it is not bound to Shen'dar, the run back up from Falaath (~12 map units) goes through
-- the Prideclaws for 92515, and the stone is ready again (>1 h later) for the Valanaar hearth at the end of sd-02
-- (sd02-hearth is ~45-60 min after Falaath).
if not FastesBoooy.AddLibraryInsert then return end
FastesBoooy.AddLibrarySegment({
    id = "sd-01-zephras",
    title = {
        ru = "1-9 Остров Зефрас: Тендальская роща и Шен'дар",
        en = "1-9 Zephras Isle: Thendal Grove and Shen'dar",
    },
    zone = "Zephras Isle",
    levels = { 1, 9 },
    steps = {
        ---------------------------------------------------------------------
        -- Thendal Grove: first kills (1-2)
        ---------------------------------------------------------------------
        { id = "sd01-start", accept = 92460, npc = 251362, at = { 2521, 42.82, 23.39 },
          note = {
              ru = "Старт. Возьмите задание у Ailee Farheart прямо перед собой.",
              en = "Start. Take the quest from Ailee Farheart right in front of you.",
          } },
        { id = "sd01-rorian-1", turnin = 92460, accept = 92461, npc = 251361, at = { 2521, 42.05, 23.49 },
          note = {
              ru = "Rorian the Dayseeker в центре лагеря.",
              en = "Rorian the Dayseeker in the middle of the camp.",
          } },
        { id = "sd01-elatrell", accept = 92462, npc = 251368, at = { 2521, 43.44, 24.79 } },
        { id = "sd01-first-kills", complete = { 92461, 92462 }, at = { 2521, 45.2, 25.8 },
          note = {
              ru = "К юго-востоку от лагеря: 8 Juvenile Vuldren и 8 Pesky Cirrusfly.",
              en = "South-east of the camp: 8 Juvenile Vuldren and 8 Pesky Cirrusflies.",
          } },
        { id = "sd01-level-2", level = 2,
          note = {
              ru = "Нужен 2-й уровень: следующие задания раньше не выдаются. "
                  .. "Добейте мобов рядом.",
              en = "Level 2 is required: the next quests are not offered earlier. Kill a few more mobs.",
          } },
        { id = "sd01-elatrell-2", turnin = 92462, accept = 92463, npc = 251368, at = { 2521, 43.44, 24.79 } },
        { id = "sd01-halaan", accept = 94414, complete = 94414, turnin = 94414, npc = 257554, at = { 2521, 43.76, 24.06 },
          note = {
              ru = "Наверх сторожевой башни: Halaan даст взглянуть на якорный пилон - "
                  .. "и сразу сдайте.",
              en = "Climb the watchtower: Halaan lets you look at the anchor pylon - turn it in right away.",
          } },
        { id = "sd01-myriaal", accept = 92474, npc = 263113, at = { 2521, 43.68, 24.09 },
          note = {
              ru = "Myriaal Mistwake там же, на вершине башни.",
              en = "Myriaal Mistwake is on the tower top as well.",
          } },
        { id = "sd01-glide", complete = 92474, at = { 2521, 43.7, 24.1 },
          note = {
              ru = "Прыгните с башни на запад, к Rorian, и в падении нажмите расовую "
                  .. "«Шаг по воздуху» (Walk on Air).",
              en = "Jump off the tower westwards towards Rorian and press the Walk on Air racial while falling.",
          } },
        -- Anchor of the class letters: Rorian gives the letter of the class in the same dialog (class files).
        { id = "sd01-rorian", turnin = { 92461, 92474 }, accept = 92464, npc = 251361, at = { 2521, 42.05, 23.49 },
          note = {
              ru = "Rorian: сдайте оба задания и возьмите следующее. Тренеры классов стоят вокруг него.",
              en = "Rorian: hand in both quests and take the next one. The class trainers stand around him.",
          } },
        ---------------------------------------------------------------------
        -- Thendal Grove: windstones, Cirrusfly Queen, Agitators, Skysight (2-4)
        ---------------------------------------------------------------------
        { id = "sd01-skysight-accept", accept = 92598, npc = 251487, at = { 2521, 42.61, 24.38 },
          note = {
              ru = "Расовое задание: «Небесное зрение» (Skysight).",
              en = "Racial quest: Skysight.",
          } },
        { id = "sd01-dalia", accept = 93552, npc = 251363, at = { 2521, 43.37, 23.98 } },
        { id = "sd01-windstones-bg", complete = 93552, bg = true,
          note = {
              ru = "Собирайте Raw Windstone (15 сгустков) по пути - они по всей роще.",
              en = "Loot Raw Windstones (15 clusters) on the way - they are all over the grove.",
          } },
        { id = "sd01-queen", complete = 92463, at = { 2521, 48.41, 28.53 },
          note = {
              ru = "Cirrusfly Queen (3 ур.) на юго-востоке рощи. По пути бейте мобов и "
                  .. "собирайте камни.",
              en = "Cirrusfly Queen (level 3) in the south-east of the grove. Kill mobs and loot stones on the way.",
          } },
        { id = "sd01-yala", turnin = 92464, accept = 92465, npc = 249363, at = { 2521, 47.25, 21.98 },
          note = {
              ru = "Yala Windwatcher к северу от королевы.",
              en = "Yala Windwatcher north of the queen.",
          } },
        { id = "sd01-skysight", complete = 92598, object = 460001, at = { 2521, 48.28, 20.62 },
          note = {
              ru = "У Elemental Convergence примените «Небесное зрение». Заряд у средоточия "
                  .. "на 1 ч удваивает его бонус к скорости - кастуйте его на бегу "
                  .. "весь остров.",
              en = "At the Elemental Convergence cast Skysight. Being Charged there doubles its speed bonus "
                  .. "for 1 h - cast it while running all over the island.",
          } },
        { id = "sd01-agitators", complete = { 92465, 93552 }, at = { 2521, 47.0, 20.3 },
          note = {
              ru = "Вокруг Yala: 7 Al'Aketh Convert и 6 Roiling Winds; доберите камни.",
              en = "Around Yala: 7 Al'Aketh Converts and 6 Roiling Winds; finish the windstones.",
          } },
        { id = "sd01-level-3", level = 3,
          note = {
              ru = "Нужен 3-й уровень для следующего задания Yala. "
                  .. "Добейте мобов вокруг.",
              en = "Level 3 is required for Yala's next quest. Keep killing around here.",
          } },
        { id = "sd01-yala-2", turnin = 92465, accept = 92469, npc = 249363, at = { 2521, 47.25, 21.98 } },
        ---------------------------------------------------------------------
        -- Back in the camp: turn-ins (level 4)
        ---------------------------------------------------------------------
        -- no earlier sethearth: the stone is still on the character's default bind (Thendal Village);
        -- the validator only reports an INFO (hearth-unbound) for it
        { id = "sd01-hearth-3", hearth = "Thendal Village", at = { 2521, 43.0, 23.5 }, radius = 120,
          note = {
              ru = "Камень возвращения в лагерь (деревня Тендал). Следующий раз он нужен только на 12-м уровне "
                  .. "(возврат в Валанаар) - больше чем через час, откат успеет пройти.",
              en = "Hearth back to the camp (Thendal Village). The stone is next needed at level 12 (the way back "
                  .. "to Valanaar), more than an hour from now, so the cooldown is over by then.",
          } },
        { id = "sd01-dalia-2", turnin = 93552, npc = 251363, at = { 2521, 43.37, 23.98 },
          note = {
              ru = "Dalia the Collector в лагере.",
              en = "Dalia the Collector in the camp.",
          } },
        { id = "sd01-elatrell-3", turnin = 92463, npc = 251368, at = { 2521, 43.44, 24.79 } },
        { id = "sd01-skysight-turnin", turnin = 92598, npc = 251487, at = { 2521, 42.61, 24.38 } },
        { id = "sd01-level-4", level = 4,
          note = {
              ru = "Нужен 4-й уровень: Rorian выдаёт «Aetheen of the Gales» только с 4-го.",
              en = "Level 4 is required: Rorian offers Aetheen of the Gales only from level 4.",
          } },
        { id = "sd01-rorian-4", turnin = 92469, accept = 92471, npc = 251361, at = { 2521, 42.05, 23.49 } },
        { id = "sd01-aetheen", turnin = 92471, accept = 92470, npc = 251366, at = { 2521, 42.76, 23.66 } },
        { id = "sd01-thendal-4", accept = 92473, npc = 257551, at = { 2521, 42.41, 25.17 } },
        ---------------------------------------------------------------------
        -- Ursera den west of the camp (4-5)
        ---------------------------------------------------------------------
        { id = "sd01-claws-bg", complete = 92473, bg = true,
          note = {
              ru = "Scrawny Ursera по всему западу рощи: 6 когтей.",
              en = "Scrawny Ursera all over the west of the grove: 6 claws.",
          } },
        { id = "sd01-den", complete = 92470, at = { 2521, 35.65, 26.07 },
          note = {
              ru = "Логово на западе: 8 Ursera Scavenger по пути, мать логова Urs'anah (5 ур.) "
                  .. "в глубине - её голова.",
              en = "Den to the west: 8 Ursera Scavengers on the way and the den mother Urs'anah (level 5) "
                  .. "at the back - her head.",
          } },
        { id = "sd01-claws", complete = 92473, at = { 2521, 39.6, 27.9 },
          note = {
              ru = "Доберите когти Scrawny Ursera на обратном пути.",
              en = "Finish the Scrawny Ursera claws on the way back.",
          } },
        { id = "sd01-aetheen-2", turnin = 92470, accept = { 92472, 96638 }, npc = 251366, at = { 2521, 42.76, 23.66 } },
        { id = "sd01-valreaa-2", turnin = 92473, npc = 257551, at = { 2521, 42.41, 25.17 } },
        ---------------------------------------------------------------------
        -- Al'Aketh camp (5)
        ---------------------------------------------------------------------
        { id = "sd01-hanaa", accept = 92544, npc = 252095, at = { 2521, 38.31, 30.18 },
          note = {
              ru = "Hanaa Nightwind к юго-западу от лагеря.",
              en = "Hanaa Nightwind south-west of the camp.",
          } },
        { id = "sd01-thugs", complete = 92544, at = { 2521, 37.3, 32.8 },
          note = {
              ru = "Лагерь Al'Aketh южнее: 6 Brute, 4 Neophyte и Malduko Cloudcrush (5 ур.) "
                  .. "на юго-западном краю лагеря.",
              en = "Al'Aketh camp to the south: 6 Brutes, 4 Neophytes and Malduko Cloudcrush (level 5) "
                  .. "at the south-west edge.",
          } },
        { id = "sd01-hanaa-2", turnin = 92544, npc = 252095, at = { 2521, 38.31, 30.18 } },
        ---------------------------------------------------------------------
        -- To Shen'dar Village (5-6)
        ---------------------------------------------------------------------
        { id = "sd01-larder-bg", collect = { [5469] = 8, [6889] = 3 }, bg = true,
          note = {
              ru = "По дороге на юг бейте Galestrider: 8 Strider Meat и 3 Small Egg - для задания "
                  .. "в Шен'даре, не продавайте. Смерч даёт +40% скорости (урон снимает), "
                  .. "кристаллы ветрокамня восполняют здоровье и ману.",
              en = "On the way south kill Galestriders: 8 Strider Meat and 3 Small Eggs for a Shen'dar quest, "
                  .. "do not sell them. A Tornado gives +40% speed (damage removes it), windstone crystals "
                  .. "restore health and mana.",
          } },
        { id = "sd01-aonda", turnin = 92472, accept = 92514, npc = 251523, at = { 2521, 45.67, 45.50 },
          note = {
              ru = "Шен'дар: Constable Aonda на востоке деревни. Хлам и вода - Veena Vericloud рядом.",
              en = "Shen'dar: Constable Aonda on the east side. Junk / water: Veena Vericloud nearby.",
          } },
        { id = "sd01-illaya", complete = { 92595, [92514] = { 1 } }, accept = 92595, turnin = 92595, npc = 251902,
          at = { 2521, 43.51, 44.77 },
          note = {
              ru = "Поговорите с Illaya Amberwind и выслушайте её.",
              en = "Talk to Illaya Amberwind and listen to her.",
          } },
        { id = "sd01-illaya-2", accept = 94411, npc = 251902, at = { 2521, 43.51, 44.77 } },
        { id = "sd01-innkeeper", complete = { [92514] = { 2 } }, npc = 254089, at = { 2521, 43.01, 43.23 },
          note = {
              ru = "Трактирщица Coriella Calmbreeze: поговорите с ней (цель задания). Камень к Шен'дару "
                  .. "не привязывайте - он на откате, следующая привязка в Валанааре.",
              en = "Innkeeper Coriella Calmbreeze: talk to her (quest objective). No need to bind the hearthstone "
                  .. "here - it is on cooldown and is next bound in Valanaar.",
          } },
        { id = "sd01-raan", turnin = 96638, accept = 96101, npc = 263664, at = { 2521, 41.66, 44.80 } },
        { id = "sd01-campfire", complete = 96101, object = 460003, at = { 2521, 41.73, 44.78 },
          note = {
              ru = "Сядьте (/sit) у костра Raan и ждите бафа «Усиленный отдых» (~1 мин).",
              en = "Sit (/sit) at Raan's campfire until you get the Boosted Rest buff (~1 min).",
          } },
        { id = "sd01-raan-2", turnin = 96101, accept = 96646, npc = 263664, at = { 2521, 41.66, 44.80 } },
        { id = "sd01-aonda-2", turnin = 92514, accept = 92517, npc = 251523, at = { 2521, 45.67, 45.50 } },
        { id = "sd01-teeri", accept = { 93319, 92516 }, npc = 251906, at = { 2521, 44.46, 44.96 } },
        { id = "sd01-indari", accept = 92515, npc = 251993, at = { 2521, 44.68, 44.52 } },
        { id = "sd01-taleen", accept = 93951, npc = 251991, at = { 2521, 44.88, 44.18 } },
        { id = "sd01-zerril", complete = 96646, turnin = 96646, accept = 92553, npc = 251905, at = { 2521, 43.85, 43.84 },
          note = {
              ru = "Повар Zerril: выучите кулинарию (это цель задания), затем "
                  .. "возьмите задание на мясо и яйца (собрали по дороге - "
                  .. "уже выполнено).",
              en = "Cook Zerril: learn Cooking (that is the quest objective), then take the meat and eggs quest "
                  .. "(collected on the way - already done).",
          } },
        { id = "sd01-pelts-bg", complete = 92515, bg = true,
          note = {
              ru = "Prideclaw по всему нагорью: 10 шкур.",
              en = "Prideclaws all over the highlands: 10 pelts.",
          } },
        { id = "sd01-larder-bg-2", complete = 92553, bg = true,
          note = {
              ru = "Galestrider: 8 Strider Meat и 3 Small Egg (если не собрали по дороге).",
              en = "Galestriders: 8 Strider Meat and 3 Small Eggs (if not done on the way).",
          } },
        ---------------------------------------------------------------------
        -- Loop 1: north-east highlands (6-7)
        ---------------------------------------------------------------------
        { id = "sd01-apprentices", complete = 94411, at = { 2521, 46.6, 38.9 },
          note = {
              ru = "Северо-восток от деревни: 6 High Order Apprentice (маги).",
              en = "North-east of the village: 6 High Order Apprentices (casters).",
          } },
        { id = "sd01-pilfered-bg", complete = 93319, bg = true,
          note = {
              ru = "Pilfered Windstone падают с Highlands Bandit (10).",
              en = "Pilfered Windstones drop from Highlands Bandits (10).",
          } },
        { id = "sd01-bennic", complete = { [92517] = { 2 } }, at = { 2521, 50.62, 34.27 },
          note = {
              ru = "«Badwind» Bennic (7 ур.) в пещере бандитов на северо-востоке.",
              en = "\"Badwind\" Bennic (level 7) in the bandit cave to the north-east.",
          } },
        { id = "sd01-bandits", complete = { 92517, 93319 }, at = { 2521, 48.9, 37.9 },
          note = {
              ru = "Добейте 10 Highlands Bandit и камни на выходе из пещеры.",
              en = "Finish 10 Highlands Bandits and the windstones on the way out.",
          } },
        ---------------------------------------------------------------------
        -- Shen'dar, second visit (8)
        ---------------------------------------------------------------------
        { id = "sd01-aonda-3", turnin = 92517, accept = 93036, npc = 251523, at = { 2521, 45.67, 45.50 },
          note = {
              ru = "Назад в деревню, к Constable Aonda.",
              en = "Back to the village, to Constable Aonda.",
          } },
        { id = "sd01-sania", turnin = 93036, accept = 92529, npc = 251904, at = { 2521, 44.88, 45.53 } },
        { id = "sd01-mark", manual = true, optional = true, npc = 251904, at = { 2521, 44.88, 45.53 },
          note = {
              ru = "Sania дала «Знак Акира» (маскировка культиста) - он нужен в Фалаате, куда вы пойдёте "
                  .. "прямо из долины, без захода в деревню. Не умирайте в долине и у Vulgara; потеряли "
                  .. "баф - перед Фалаатом вернитесь к Sania. Прочитали - жмите «Вперёд».",
              en = "Sania gave you the Mark of Akir (cultist disguise) - you need it in Falaath, where you go "
                  .. "straight from the vale without coming back to the village. Do not die in the vale or at "
                  .. "Vulgara; lost the buff - see Sania again before Falaath. Read it - press Forward.",
          } },
        { id = "sd01-teeri-2", turnin = 93319, npc = 251906, at = { 2521, 44.46, 44.96 } },
        { id = "sd01-illaya-3", turnin = 94411, npc = 251902, at = { 2521, 43.51, 44.77 } },
        { id = "sd01-wanted", accept = 93318, object = 610954, at = { 2521, 43.38, 45.84 },
          note = {
              ru = "Доска объявлений: «Разыскивается: Vulgara».",
              en = "Bounty board: WANTED: Vulgara.",
          } },
        ---------------------------------------------------------------------
        -- Loop 2: south-west hippogryph vale, Vulgara (8)
        ---------------------------------------------------------------------
        { id = "sd01-vale-cliff", go = true, at = { 2521, 36.4, 50.9 }, radius = 25,
          note = {
              ru = "На запад к обрыву. Спрыгните и планируйте «Шагом по воздуху».",
              en = "West to the cliff edge. Jump down and glide with Walk on Air.",
          } },
        { id = "sd01-down-bg", complete = 93951, bg = true,
          note = {
              ru = "Hippogryph Down лежит на земле в долине (8).",
              en = "Hippogryph Down lies on the ground in the vale (8).",
          } },
        { id = "sd01-hippogryphs", complete = 92516, at = { 2521, 36.3, 53.6 },
          note = {
              ru = "8 Hippogryph Youth, 6 Hippogryph Protector и Hippogryph Matriarch (7 ур.) "
                  .. "у западного края долины (33,54 / 35,54).",
              en = "8 Hippogryph Youths, 6 Protectors and the Matriarch (level 7) at the west edge "
                  .. "of the vale (33,54 / 35,54).",
          } },
        { id = "sd01-down", complete = 93951, at = { 2521, 36.0, 53.7 } },
        { id = "sd01-vulgara", complete = 93318, at = { 2521, 42.66, 52.80 },
          note = {
              ru = "ЭЛИТА: Vulgara the Insatiable (8 ур.). Начинайте с полным здоровьем, используйте все "
                  .. "защитные умения и зелья; слишком тяжело - бросьте задание (гайд сам пропустит его шаги).",
              en = "ELITE: Vulgara the Insatiable (level 8). Start at full health, use every defensive "
                  .. "ability and potion; too hard - abandon the quest (the guide skips its steps).",
          } },
        ---------------------------------------------------------------------
        -- Falaath Village straight from Vulgara (8)
        ---------------------------------------------------------------------
        { id = "sd01-falaath-cliff", go = true, at = { 2521, 45.4, 53.5 }, radius = 25,
          note = {
              ru = "Из логова Vulgara на восток к краю плато (не в деревню); спрыгните к Jasaan, "
                  .. "планируя «Шагом по воздуху». Нет «Знака Акира» - сначала к Sania в Шен'дар (44.9, 45.5).",
              en = "From Vulgara's lair east to the plateau edge (not back to the village); jump down to Jasaan "
                  .. "gliding with Walk on Air. No Mark of Akir - go to Sania in Shen'dar (44.9, 45.5) first.",
          } },
        { id = "sd01-jasaan", turnin = 92529, accept = 92528, npc = 257065, at = { 2521, 46.89, 56.23 } },
        { id = "sd01-wardrobe", complete = 92528, at = { 2521, 48.84, 53.93 },
          note = {
              ru = "Осмотрите деревню Фалаат: шкаф в доме на севере деревни (48.8, 53.9).",
              en = "Look around Falaath Village: the wardrobe in a house in the north of the village (48.8, 53.9).",
          } },
        { id = "sd01-ramp-1", go = true, at = { 2521, 46.4, 51.3 }, radius = 25,
          note = {
              ru = "Подъём обратно на плато - здесь, затем на север в Шен'дар.",
              en = "The way back up to the plateau is here, then north to Shen'dar.",
          } },
        ---------------------------------------------------------------------
        -- Shen'dar, third visit: all turn-ins (8-9)
        ---------------------------------------------------------------------
        { id = "sd01-aonda-4", turnin = 92528, accept = { 92550, 93926 }, npc = 251523, at = { 2521, 45.67, 45.50 },
          note = {
              ru = "Constable Aonda.",
              en = "Constable Aonda.",
          } },
        { id = "sd01-danarii", turnin = 93318, npc = 252172, at = { 2521, 45.24, 45.18 },
          note = {
              ru = "Danarii Bellowveil. Пропустили Vulgara - пропустите и этот шаг.",
              en = "Danarii Bellowveil. Skipped Vulgara - skip this step too.",
          } },
        { id = "sd01-danarii-2", accept = 92551, npc = 252172, at = { 2521, 45.24, 45.18 } },
        { id = "sd01-taleen-2", turnin = 93951, npc = 251991, at = { 2521, 44.88, 44.18 } },
        { id = "sd01-zerril-2", turnin = 92553, npc = 251905, at = { 2521, 43.85, 43.84 } },
        { id = "sd01-shendar-8", turnin = 92516, npc = 251906, at = { 2521, 44.46, 44.96 } },
        ---------------------------------------------------------------------
        -- Loop 3: western watchtower + Falaath (9)
        ---------------------------------------------------------------------
        { id = "sd01-south-cliff", go = true, at = { 2521, 44.0, 50.0 }, radius = 25,
          note = {
              ru = "На юг к обрыву, вниз «Шагом по воздуху» и дальше к западной "
                  .. "сторожевой башне.",
              en = "South to the cliff, glide down with Walk on Air, then on to the western watchtower.",
          } },
        { id = "sd01-vaaniel", complete = 93926, turnin = 93926, accept = 93927, npc = 252155, at = { 2521, 42.34, 62.02 },
          note = {
              ru = "Peacekeeper Vaaniel у западной башни.",
              en = "Peacekeeper Vaaniel at the western watchtower.",
          } },
        { id = "sd01-last-request", complete = 93927, use = 254871, at = { 2521, 41.2, 63.8 },
          note = {
              ru = "Записка рядом (прочитайте её), перо и перстень - на телах к "
                  .. "юго-западу, "
                  .. "убейте Skypriest Aanders (8 ур.).",
              en = "Note next to him (read it), feather and signet on the bodies to the south-west, "
                  .. "kill Skypriest Aanders (level 8).",
          } },
        { id = "sd01-caches-bg", complete = 92551, bg = true,
          note = {
              ru = "Supply Cache (тайники) в деревне Фалаат.",
              en = "Supply Caches in Falaath Village.",
          } },
        { id = "sd01-falaath", complete = 92550, at = { 2521, 49.0, 56.5 },
          note = {
              ru = "Фалаат: 6 Al'Aketh Stormcaller, 4 Living Lightning и голова Commander Cyclas "
                  .. "(8 ур., восток деревни, 50,57).",
              en = "Falaath: 6 Al'Aketh Stormcallers, 4 Living Lightning and the head of Commander Cyclas "
                  .. "(level 8, east side, 50,57).",
          } },
        { id = "sd01-caches", complete = 92551, at = { 2521, 49.35, 55.77 } },
        -- no separate "complete 92515" step here: the pelts are a bg goal since the first Shen'dar visit, so a
        -- finish step done early would become the forward anchor and silently skip the glide / ramp hints; the
        -- finish is merged into the turn-in below (Prideclaws on the ramp and around Shen'dar)
        { id = "sd01-ramp", go = true, at = { 2521, 46.4, 51.3 }, radius = 25,
          note = {
              ru = "Пешком обратно на плато по подъёму (камень возвращения бережём для Валанаара), по пути "
                  .. "бейте Prideclaw ради шкур (92515).",
              en = "Walk back up the ramp to the plateau (the hearthstone is saved for Valanaar), killing "
                  .. "Prideclaws for the pelts (92515) on the way.",
          } },
        ---------------------------------------------------------------------
        -- Shen'dar, final turn-ins (9)
        ---------------------------------------------------------------------
        { id = "sd01-indari-2", complete = 92515, turnin = 92515, npc = 251993, at = { 2521, 44.68, 44.52 },
          note = {
              ru = "Нет 10 шкур - добейте Prideclaw у самой деревни (их полно в 2-6 единицах карты), затем сдайте.",
              en = "Short of 10 pelts - kill Prideclaws right around the village (plenty within 2-6 map units), then "
                  .. "turn in.",
          } },
        { id = "sd01-danarii-3", turnin = 92551, npc = 252172, at = { 2521, 45.24, 45.18 } },
        { id = "sd01-end", turnin = { 92550, 93927 }, accept = { 92579, 93948 }, -- both continue in sd-02
          npc = 251523, at = { 2521, 45.67, 45.50 },
          note = {
              ru = "Сдайте и возьмите оба задания в Валанаар (отчёт и перстень).",
              en = "Turn in and take both quests to Valanaar (the report and the signet).",
          } },
    },
})
