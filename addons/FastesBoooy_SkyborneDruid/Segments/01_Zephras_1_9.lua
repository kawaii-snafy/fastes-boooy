-- FastesBoooy_SkyborneDruid / Segments / 01_Zephras_1_9.lua
-- Segment "sd-01-zephras": Zephras Isle (uiMap 2521), levels 1-9, Horde (Windshaper) side.
-- Thendal Grove (start, druid class quest 92485, training at 1 and 4) -> ursera den ->
-- Al'Aketh camp -> Shen'dar Village (hearth, training at 6 and 8; loops: NE highlands,
-- SW hippogryph vale, Falaath + western watchtower) -> ends at Constable Aonda with
-- 92579 + 93948 (both lead to Valanaar) in the quest log.
-- Coordinates: Forever DB snapshot (tools/data/forever_db.lua): NPC / object spawns and
-- centroids of the objective mob / object spawns. Glide points (Walk on Air) are terrain
-- points cross-checked with the reference. Every Zephras quest is Forever-new, so its XP is
-- unknown offline: the xp-unknown WARN on each turn-in is expected (estimated XP is used).
-- The hearthstone is NOT used before the end: bound to Shen'dar at ~6, it saves the run back
-- from Falaath at ~9.
FastesBoooy.AddSegment("horde-skyborne-druid", {
    id = "sd-01-zephras",
    title = {
        ru = "1-9 Остров Зефрас: Тендальская роща и Шен'дар",
        en = "1-9 Zephras Isle: Thendal Grove and Shen'dar",
    },
    zone = "Zephras Isle",
    -- WARN-OK (levels): segment-level -- the validator overestimates (unknown Forever quest XP, talk
    -- objectives simulated as 8 kills); the reference run ends this part at ~9.
    levels = { 1, 9 }, -- WARN-OK: segment-level (estimate artifact, see above)
    steps = {
        ---------------------------------------------------------------------
        -- Thendal Grove: first kills (1-2)
        ---------------------------------------------------------------------
        { id = "sd01-start", accept = 92460, npc = 251362, at = { 2521, 42.82, 23.39 },
          note = {
              ru = "Старт. Возьмите задание у Ailee Farheart прямо перед собой.",
              en = "Start. Take the quest from Ailee Farheart right in front of you.",
          } },
        { turnin = 92460, accept = 92461, npc = 251361, at = { 2521, 42.05, 23.49 }, -- WARN-OK: xp-unknown (Forever-new)
          note = {
              ru = "Rorian the Dayseeker в центре лагеря.",
              en = "Rorian the Dayseeker in the middle of the camp.",
          } },
        { accept = 92462, npc = 251368, at = { 2521, 43.44, 24.79 } },
        { complete = { 92461, 92462 }, at = { 2521, 45.2, 25.8 },
          note = {
              ru = "К юго-востоку от лагеря: 8 Juvenile Vuldren и 8 Pesky Cirrusfly. "
                  .. "Гнев, добивайте посохом.",
              en = "South-east of the camp: 8 Juvenile Vuldren and 8 Pesky Cirrusflies. Wrath, then melee.",
          } },
        { id = "sd01-level-2", level = 2,
          note = {
              ru = "Нужен 2-й уровень: следующие задания раньше не выдаются. "
                  .. "Добейте мобов рядом.",
              en = "Level 2 is required: the next quests are not offered earlier. Kill a few more mobs.",
          } },
        { turnin = 92462, accept = 92463, npc = 251368, at = { 2521, 43.44, 24.79 } }, -- WARN-OK: xp-unknown (Forever-new)
        { accept = 94414, complete = 94414, turnin = 94414, npc = 257554, at = { 2521, 43.76, 24.06 }, -- WARN-OK: xp-unknown
          note = {
              ru = "Наверх сторожевой башни: Halaan даст взглянуть на якорный пилон - "
                  .. "и сразу сдайте.",
              en = "Climb the watchtower: Halaan lets you look at the anchor pylon - turn it in right away.",
          } },
        { accept = 92474, npc = 263113, at = { 2521, 43.68, 24.09 },
          note = {
              ru = "Myriaal Mistwake там же, на вершине башни.",
              en = "Myriaal Mistwake is on the tower top as well.",
          } },
        { complete = 92474, at = { 2521, 43.7, 24.1 },
          note = {
              ru = "Прыгните с башни на запад, к Rorian, и в падении нажмите расовую "
                  .. "«Шаг по воздуху» (Walk on Air).",
              en = "Jump off the tower westwards towards Rorian and press the Walk on Air racial while falling.",
          } },
        { turnin = { 92461, 92474 }, accept = { 92464, 92485 }, npc = 251361, at = { 2521, 42.05, 23.49 } }, -- WARN-OK: xp-unknown
        { id = "sd01-92485", turnin = 92485, use = 282420, npc = 251373, at = { 2521, 41.66, 23.33 }, -- WARN-OK: xp-unknown
          note = {
              ru = "Классовое задание: прочитайте «Сложенный пергамент» (сумка), "
                  .. "затем поговорите с Xyton.",
              en = "Druid class quest: read the Folded Parchment from your bags, then talk to Xyton.",
          } },
        { id = "sd01-train-1", train = true, npc = 251373, at = { 2521, 41.66, 23.33 },
          spells = { { ru = "Знак дикой природы", en = "Mark of the Wild" } },
          note = {
              ru = "Выучите «Знак дикой природы» и держите его на себе.",
              en = "Learn Mark of the Wild and keep it up.",
          } },
        ---------------------------------------------------------------------
        -- Thendal Grove: windstones, Cirrusfly Queen, Agitators, Skysight (2-4)
        ---------------------------------------------------------------------
        { accept = 92598, npc = 251487, at = { 2521, 42.61, 24.38 },
          note = {
              ru = "Расовое задание Орды: «Небесное зрение» (Skysight).",
              en = "Horde racial quest: Skysight.",
          } },
        { accept = 93552, npc = 251363, at = { 2521, 43.37, 23.98 } },
        { complete = 93552, bg = true,
          note = {
              ru = "Собирайте Raw Windstone (15 сгустков) по пути - они по всей роще.",
              en = "Loot Raw Windstones (15 clusters) on the way - they are all over the grove.",
          } },
        { complete = 92463, at = { 2521, 48.41, 28.53 },
          note = {
              ru = "Cirrusfly Queen (3 ур.) на юго-востоке рощи. По пути бейте мобов и "
                  .. "собирайте камни.",
              en = "Cirrusfly Queen (level 3) in the south-east of the grove. Kill mobs and loot stones on the way.",
          } },
        { turnin = 92464, accept = 92465, npc = 249363, at = { 2521, 47.25, 21.98 }, -- WARN-OK: xp-unknown (Forever-new)
          note = {
              ru = "Yala Windwatcher к северу от королевы.",
              en = "Yala Windwatcher north of the queen.",
          } },
        { complete = 92598, object = 460001, at = { 2521, 48.28, 20.62 },
          note = {
              ru = "У Elemental Convergence примените «Небесное зрение». Заряд у средоточия "
                  .. "на 1 ч удваивает его бонус к скорости - кастуйте его на бегу "
                  .. "весь остров.",
              en = "At the Elemental Convergence cast Skysight. Being Charged there doubles its speed bonus "
                  .. "for 1 h - cast it while running all over the island.",
          } },
        { complete = { 92465, 93552 }, at = { 2521, 47.0, 20.3 },
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
        { turnin = 92465, accept = 92469, npc = 249363, at = { 2521, 47.25, 21.98 } }, -- WARN-OK: xp-unknown (Forever-new)
        ---------------------------------------------------------------------
        -- Back in the camp: turn-ins, training at 4
        ---------------------------------------------------------------------
        { turnin = 93552, npc = 251363, at = { 2521, 43.37, 23.98 }, -- WARN-OK: xp-unknown (Forever-new)
          note = {
              ru = "Бегом обратно в лагерь. Камень возвращения не трогайте - "
                  .. "он нужен в конце.",
              en = "Run back to the camp. Keep the hearthstone - it is used at the end of the segment.",
          } },
        { turnin = 92463, npc = 251368, at = { 2521, 43.44, 24.79 } }, -- WARN-OK: xp-unknown (Forever-new)
        { turnin = 92598, npc = 251487, at = { 2521, 42.61, 24.38 } }, -- WARN-OK: xp-unknown (Forever-new)
        { id = "sd01-level-4", level = 4,
          note = {
              ru = "Нужен 4-й уровень: Rorian выдаёт «Aetheen of the Gales» только с 4-го.",
              en = "Level 4 is required: Rorian offers Aetheen of the Gales only from level 4.",
          } },
        { turnin = 92469, accept = 92471, npc = 251361, at = { 2521, 42.05, 23.49 } }, -- WARN-OK: xp-unknown (Forever-new)
        { id = "sd01-train-4", train = true, optional = true, npc = 251373, at = { 2521, 41.66, 23.33 },
          spells = { { ru = "Лунный огонь", en = "Moonfire" }, { ru = "Омоложение", en = "Rejuvenation" } },
          note = {
              ru = "Уровень 4: «Лунный огонь» и «Омоложение».",
              en = "Level 4: Moonfire and Rejuvenation.",
          } },
        { turnin = 92471, accept = 92470, npc = 251366, at = { 2521, 42.76, 23.66 } }, -- WARN-OK: xp-unknown (Forever-new)
        { accept = 92473, npc = 257551, at = { 2521, 42.41, 25.17 } },
        ---------------------------------------------------------------------
        -- Ursera den west of the camp (4-5)
        ---------------------------------------------------------------------
        { complete = 92473, bg = true,
          note = {
              ru = "Scrawny Ursera по всему западу рощи: 6 когтей.",
              en = "Scrawny Ursera all over the west of the grove: 6 claws.",
          } },
        { complete = 92470, at = { 2521, 35.65, 26.07 },
          note = {
              ru = "Логово на западе: 8 Ursera Scavenger по пути, мать логова Urs'anah (5 ур.) "
                  .. "в глубине - её голова.",
              en = "Den to the west: 8 Ursera Scavengers on the way and the den mother Urs'anah (level 5) "
                  .. "at the back - her head.",
          } },
        { complete = 92473, at = { 2521, 39.6, 27.9 },
          note = {
              ru = "Доберите когти Scrawny Ursera на обратном пути.",
              en = "Finish the Scrawny Ursera claws on the way back.",
          } },
        { turnin = 92470, accept = { 92472, 96638 }, npc = 251366, at = { 2521, 42.76, 23.66 }, -- WARN-OK: xp-unknown
          reward = { [92470] = 2 },
          note = {
              ru = "Награда выбирается автоматически: 2-й предмет.",
              en = "The reward is picked automatically: item 2.",
          } },
        { turnin = 92473, npc = 257551, at = { 2521, 42.41, 25.17 } }, -- WARN-OK: xp-unknown (Forever-new)
        ---------------------------------------------------------------------
        -- Al'Aketh camp (5)
        ---------------------------------------------------------------------
        { accept = 92544, npc = 252095, at = { 2521, 38.31, 30.18 },
          note = {
              ru = "Hanaa Nightwind к юго-западу от лагеря.",
              en = "Hanaa Nightwind south-west of the camp.",
          } },
        { complete = 92544, at = { 2521, 37.3, 32.8 },
          note = {
              ru = "Лагерь Al'Aketh южнее: 6 Brute, 4 Neophyte и Malduko Cloudcrush (5 ур.) "
                  .. "на юго-западном краю лагеря.",
              en = "Al'Aketh camp to the south: 6 Brutes, 4 Neophytes and Malduko Cloudcrush (level 5) "
                  .. "at the south-west edge.",
          } },
        { turnin = 92544, npc = 252095, at = { 2521, 38.31, 30.18 } }, -- WARN-OK: xp-unknown (Forever-new)
        ---------------------------------------------------------------------
        -- To Shen'dar Village (5-6)
        ---------------------------------------------------------------------
        { collect = { [5469] = 8, [6889] = 3 }, bg = true,
          note = {
              ru = "По дороге на юг бейте Galestrider: 8 Strider Meat и 3 Small Egg - для задания "
                  .. "в Шен'даре, не продавайте. Смерч даёт +40% скорости (урон снимает), "
                  .. "кристаллы ветрокамня восполняют здоровье и ману.",
              en = "On the way south kill Galestriders: 8 Strider Meat and 3 Small Eggs for a Shen'dar quest, "
                  .. "do not sell them. A Tornado gives +40% speed (damage removes it), windstone crystals "
                  .. "restore health and mana.",
          } },
        { turnin = 92472, accept = 92514, npc = 251523, at = { 2521, 45.67, 45.50 }, -- WARN-OK: xp-unknown (Forever-new)
          note = {
              ru = "Шен'дар: Constable Aonda на востоке деревни. Хлам и вода - Veena Vericloud рядом.",
              en = "Shen'dar: Constable Aonda on the east side. Junk / water: Veena Vericloud nearby.",
          } },
        { complete = { 92595, [92514] = { 1 } }, accept = 92595, turnin = 92595, npc = 251902, -- WARN-OK: xp-unknown
          at = { 2521, 43.51, 44.77 },
          note = {
              ru = "Поговорите с Illaya Amberwind и выслушайте её.",
              en = "Talk to Illaya Amberwind and listen to her.",
          } },
        { accept = 94411, npc = 251902, at = { 2521, 43.51, 44.77 } },
        { id = "sd01-sethearth", complete = { [92514] = { 2 } }, sethearth = "Shen'dar Village", npc = 254089,
          at = { 2521, 43.01, 43.23 },
          note = {
              ru = "Трактирщица Coriella Calmbreeze: поговорите и привяжите "
                  .. "камень к Шен'дару.",
              en = "Innkeeper Coriella Calmbreeze: talk to her and bind your hearthstone to Shen'dar.",
          } },
        { turnin = 96638, accept = 96101, npc = 263664, at = { 2521, 41.66, 44.80 } }, -- WARN-OK: xp-unknown (Forever-new)
        { complete = 96101, object = 460003, at = { 2521, 41.73, 44.78 },
          note = {
              ru = "Сядьте (/sit) у костра Raan и ждите бафа «Усиленный отдых» (~1 мин).",
              en = "Sit (/sit) at Raan's campfire until you get the Boosted Rest buff (~1 min).",
          } },
        { turnin = 96101, accept = 96646, npc = 263664, at = { 2521, 41.66, 44.80 } }, -- WARN-OK: xp-unknown (Forever-new)
        { id = "sd01-train-6", train = true, npc = 254081, at = { 2521, 45.16, 44.22 },
          spells = { { ru = "Гнев (ранг 2)", en = "Wrath (Rank 2)" }, { ru = "Шипы", en = "Thorns" } },
          note = {
              ru = "Уровень 6: «Гнев» 2 и «Шипы» "
                  .. "(+ «Лунный огонь»/«Омоложение», если не взяли на 4).",
              en = "Level 6: Wrath 2 and Thorns (+ Moonfire / Rejuvenation if you skipped them at 4).",
          } },
        { turnin = 92514, accept = 92517, npc = 251523, at = { 2521, 45.67, 45.50 } }, -- WARN-OK: xp-unknown (Forever-new)
        { accept = { 93319, 92516 }, npc = 251906, at = { 2521, 44.46, 44.96 } },
        { accept = 92515, npc = 251993, at = { 2521, 44.68, 44.52 } },
        { accept = 93951, npc = 251991, at = { 2521, 44.88, 44.18 } },
        { complete = 96646, turnin = 96646, accept = 92553, npc = 251905, at = { 2521, 43.85, 43.84 }, -- WARN-OK: xp-unknown
          note = {
              ru = "Повар Zerril: выучите кулинарию (это цель задания), затем "
                  .. "возьмите задание на мясо и яйца (собрали по дороге - "
                  .. "уже выполнено).",
              en = "Cook Zerril: learn Cooking (that is the quest objective), then take the meat and eggs quest "
                  .. "(collected on the way - already done).",
          } },
        { complete = 92515, bg = true,
          note = {
              ru = "Prideclaw по всему нагорью: 10 шкур.",
              en = "Prideclaws all over the highlands: 10 pelts.",
          } },
        { complete = 92553, bg = true,
          note = {
              ru = "Galestrider: 8 Strider Meat и 3 Small Egg (если не собрали по дороге).",
              en = "Galestriders: 8 Strider Meat and 3 Small Eggs (if not done on the way).",
          } },
        ---------------------------------------------------------------------
        -- Loop 1: north-east highlands (6-7)
        ---------------------------------------------------------------------
        { complete = 94411, at = { 2521, 46.6, 38.9 },
          note = {
              ru = "Северо-восток от деревни: 6 High Order Apprentice (маги - деритесь вплотную).",
              en = "North-east of the village: 6 High Order Apprentices (casters - fight them up close).",
          } },
        { complete = 93319, bg = true,
          note = {
              ru = "Pilfered Windstone падают с Highlands Bandit (10).",
              en = "Pilfered Windstones drop from Highlands Bandits (10).",
          } },
        { complete = { [92517] = { 2 } }, at = { 2521, 50.62, 34.27 },
          note = {
              ru = "«Badwind» Bennic (7 ур.) в пещере бандитов на северо-востоке.",
              en = "\"Badwind\" Bennic (level 7) in the bandit cave to the north-east.",
          } },
        { complete = { 92517, 93319 }, at = { 2521, 48.9, 37.9 },
          note = {
              ru = "Добейте 10 Highlands Bandit и камни на выходе из пещеры.",
              en = "Finish 10 Highlands Bandits and the windstones on the way out.",
          } },
        ---------------------------------------------------------------------
        -- Shen'dar, second visit (7)
        ---------------------------------------------------------------------
        { turnin = 92517, accept = 93036, npc = 251523, at = { 2521, 45.67, 45.50 }, -- WARN-OK: xp-unknown (Forever-new)
          note = {
              ru = "Назад в деревню.",
              en = "Back to the village.",
          } },
        { turnin = 93036, accept = 92529, npc = 251904, at = { 2521, 44.88, 45.53 } }, -- WARN-OK: xp-unknown (Forever-new)
        { turnin = 93319, npc = 251906, at = { 2521, 44.46, 44.96 } }, -- WARN-OK: xp-unknown (Forever-new)
        { turnin = 94411, npc = 251902, at = { 2521, 43.51, 44.77 } }, -- WARN-OK: xp-unknown (Forever-new)
        { accept = 93318, object = 610954, at = { 2521, 43.38, 45.84 },
          note = {
              ru = "Доска объявлений: «Разыскивается: Vulgara».",
              en = "Bounty board: WANTED: Vulgara.",
          } },
        ---------------------------------------------------------------------
        -- Loop 2: south-west hippogryph vale (7-8)
        ---------------------------------------------------------------------
        { go = true, at = { 2521, 36.4, 50.9 }, radius = 25,
          note = {
              ru = "На запад к обрыву. Спрыгните и планируйте «Шагом по воздуху».",
              en = "West to the cliff edge. Jump down and glide with Walk on Air.",
          } },
        { complete = 93951, bg = true,
          note = {
              ru = "Hippogryph Down лежит на земле в долине (8).",
              en = "Hippogryph Down lies on the ground in the vale (8).",
          } },
        { complete = 92516, at = { 2521, 36.3, 53.6 },
          note = {
              ru = "8 Hippogryph Youth, 6 Hippogryph Protector и Hippogryph Matriarch (7 ур.) "
                  .. "у западного края долины (33,54 / 35,54).",
              en = "8 Hippogryph Youths, 6 Protectors and the Matriarch (level 7) at the west edge "
                  .. "of the vale (33,54 / 35,54).",
          } },
        { complete = 93951, at = { 2521, 36.0, 53.7 } },
        { complete = 93318, at = { 2521, 42.66, 52.80 },
          note = {
              ru = "ЭЛИТА: Vulgara the Insatiable (8 ур.). Шипы + Омоложение, держите дистанцию; "
                  .. "слишком тяжело - пропустите шаг и бросьте задание.",
              en = "ELITE: Vulgara the Insatiable (level 8). Thorns + Rejuvenation, keep your distance; "
                  .. "too hard - skip the step and abandon the quest.",
          } },
        ---------------------------------------------------------------------
        -- Shen'dar, third visit (8)
        ---------------------------------------------------------------------
        { turnin = 92516, npc = 251906, at = { 2521, 44.46, 44.96 }, -- WARN-OK: xp-unknown (Forever-new)
          note = {
              ru = "Обратно в деревню (на север).",
              en = "Back north to the village.",
          } },
        { turnin = 92553, npc = 251905, at = { 2521, 43.85, 43.84 } }, -- WARN-OK: xp-unknown (Forever-new)
        { turnin = 93951, npc = 251991, at = { 2521, 44.88, 44.18 } }, -- WARN-OK: xp-unknown (Forever-new)
        { id = "sd01-train-8", train = true, optional = true, npc = 254081, at = { 2521, 45.16, 44.22 },
          spells = {
              { ru = "Гнев деревьев", en = "Entangling Roots" },
              { ru = "Целительное прикосновение (ранг 2)", en = "Healing Touch (Rank 2)" },
          },
          note = {
              ru = "Уровень 8: «Гнев деревьев» и «Целительное прикосновение» 2 "
                  .. "(не 8 - пропустите).",
              en = "Level 8: Entangling Roots and Healing Touch 2 (not 8 yet - skip).",
          } },
        { turnin = 93318, npc = 252172, at = { 2521, 45.24, 45.18 }, -- WARN-OK: xp-unknown (Forever-new)
          note = {
              ru = "Пропустили Vulgara - пропустите и этот шаг.",
              en = "Skipped Vulgara - skip this step too.",
          } },
        { id = "sd01-mark", manual = true, optional = true, npc = 251904, at = { 2521, 44.88, 45.53 },
          note = {
              ru = "Нет бафа «Знак Акира» (маскировка культиста)? Поговорите с Sania "
                  .. "и получите его снова - он нужен в Фалаате. "
                  .. "Баф есть - жмите «Дальше».",
              en = "No Mark of Akir buff (cultist disguise)? Talk to Sania to get it again - you need it "
                  .. "in Falaath. Have it - press Next.",
          } },
        ---------------------------------------------------------------------
        -- Falaath Village (8)
        ---------------------------------------------------------------------
        { go = true, at = { 2521, 45.4, 53.5 }, radius = 25,
          note = {
              ru = "На юг к краю плато; спрыгните к Jasaan, планируя «Шагом по воздуху».",
              en = "South to the plateau edge; jump down to Jasaan gliding with Walk on Air.",
          } },
        { turnin = 92529, accept = 92528, npc = 257065, at = { 2521, 46.89, 56.23 } }, -- WARN-OK: xp-unknown (Forever-new)
        { complete = 92528, at = { 2521, 48.84, 53.93 },
          note = {
              ru = "Осмотрите деревню Фалаат: шкаф в доме на севере деревни (48.8, 53.9).",
              en = "Look around Falaath Village: the wardrobe in a house in the north of the village (48.8, 53.9).",
          } },
        { go = true, at = { 2521, 46.4, 51.3 }, radius = 25,
          note = {
              ru = "Подъём обратно на плато - здесь, затем на север к Aonda.",
              en = "The way back up to the plateau is here, then north to Aonda.",
          } },
        { turnin = 92528, accept = { 92550, 93926 }, npc = 251523, at = { 2521, 45.67, 45.50 }, -- WARN-OK: xp-unknown
          reward = { [92528] = 1 },
          note = {
              ru = "Награда выбирается автоматически: 1-й предмет.",
              en = "The reward is picked automatically: item 1.",
          } },
        { accept = 92551, npc = 252172, at = { 2521, 45.24, 45.18 } },
        ---------------------------------------------------------------------
        -- Loop 3: western watchtower + Falaath (8-9)
        ---------------------------------------------------------------------
        { go = true, at = { 2521, 44.0, 50.0 }, radius = 25,
          note = {
              ru = "На юг к обрыву, вниз «Шагом по воздуху» и дальше к западной "
                  .. "сторожевой башне.",
              en = "South to the cliff, glide down with Walk on Air, then on to the western watchtower.",
          } },
        { complete = 93926, turnin = 93926, accept = 93927, npc = 252155, at = { 2521, 42.34, 62.02 }, -- WARN-OK: xp-unknown
          note = {
              ru = "Peacekeeper Vaaniel у западной башни.",
              en = "Peacekeeper Vaaniel at the western watchtower.",
          } },
        { complete = 93927, use = 254871, at = { 2521, 41.2, 63.8 },
          note = {
              ru = "Записка рядом (прочитайте её), перо и перстень - на телах к "
                  .. "юго-западу, "
                  .. "убейте Skypriest Aanders (8 ур.).",
              en = "Note next to him (read it), feather and signet on the bodies to the south-west, "
                  .. "kill Skypriest Aanders (level 8).",
          } },
        { complete = 92551, bg = true,
          note = {
              ru = "Supply Cache (тайники) в деревне Фалаат.",
              en = "Supply Caches in Falaath Village.",
          } },
        { complete = 92550, at = { 2521, 49.0, 56.5 },
          note = {
              ru = "Фалаат: 6 Al'Aketh Stormcaller, 4 Living Lightning и голова Commander Cyclas "
                  .. "(8 ур., восток деревни, 50,57).",
              en = "Falaath: 6 Al'Aketh Stormcallers, 4 Living Lightning and the head of Commander Cyclas "
                  .. "(level 8, east side, 50,57).",
          } },
        { complete = 92551, at = { 2521, 49.35, 55.77 } },
        -- no separate "complete 92515" step here: the pelts are a bg goal since the first Shen'dar visit, so a
        -- finish step done early would become the forward anchor and silently skip sd01-train-8, sd01-mark and the
        -- glide hints; the finish is merged into the turn-in below (Prideclaws surround Shen'dar)
        { id = "sd01-hearth", hearth = "Shen'dar Village", at = { 2521, 43.01, 43.23 }, radius = 120,
          note = {
              ru = "Камень возвращения в Шен'дар (он ещё ни разу не использовался - готов). "
                  .. "Не хватает шкур Prideclaw - не страшно, они водятся вокруг деревни.",
              en = "Hearth to Shen'dar (not used yet - it is ready). Short of Prideclaw pelts - fine, Prideclaws "
                  .. "roam all around the village.",
          } },
        ---------------------------------------------------------------------
        -- Shen'dar, final turn-ins (9)
        ---------------------------------------------------------------------
        { complete = 92515, turnin = 92515, npc = 251993, at = { 2521, 44.68, 44.52 }, -- WARN-OK: xp-unknown (Forever-new)
          note = {
              ru = "Нет 10 шкур - добейте Prideclaw у самой деревни (их полно в 2-6 единицах карты), затем сдайте.",
              en = "Short of 10 pelts - kill Prideclaws right around the village (plenty within 2-6 map units), then "
                  .. "turn in.",
          } },
        { turnin = 92551, npc = 252172, at = { 2521, 45.24, 45.18 } }, -- WARN-OK: xp-unknown (Forever-new)
        { id = "sd01-end", turnin = { 92550, 93927 }, accept = { 92579, 93948 }, -- WARN-OK: xp-unknown; both continue in sd-02
          npc = 251523, at = { 2521, 45.67, 45.50 },
          note = {
              ru = "Сдайте и возьмите оба задания в Валанаар (отчёт и перстень).",
              en = "Turn in and take both quests to Valanaar (the report and the signet).",
          } },
    },
})
