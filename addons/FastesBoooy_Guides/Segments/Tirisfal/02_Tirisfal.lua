-- FastesBoooy_Guides / Segments / Tirisfal / 02_Tirisfal.lua
--
-- Segment ud-02-tirisfal: Deathknell exit road -> Brill hub -> rest of Tirisfal Glades ->
-- Bandarion Keep -> Undercity (Lady Sylvanas), levels 6-13.
-- Coordinates: Forever uiMap 1420 (Tirisfal Glades) / 1458 (Undercity), map percent, from
-- tools/data/forever_db.lua (NPC/object spawns; centroids of the objective mob/object spawns
-- for complete steps; the murloc camp east of Bandarion Keep from the raw spawn list).
--
-- Hub plan (Forever DB):
--   road  : 365 Simmer, 5481 Gordo (gloom weed on the road).
--   Brill1: 86784, 404, 96656 > 96607 > 96658 (camping), 383 > 427/99141/99134, 91209 (Holy Strike),
--           8 + hearth, 367, Dillinger's report; Kristof's report + 97558 at the Rear Guard camp.
--   west  : 404, 367, 5481, Gordo's report, 365 pumpkins, 427 Scarlet Warriors, 97558 murloc skins,
--           99144 escort; hearth back.
--   Brill2: 367/365 > 368/407, 427/99141/99134 > 370, 398, 99144 (train 8), 374, 358,
--           354/362/375, 407, 404 > 426, 5481 > 5482.
--   north : 358 gnolls, 5482, 398 Maggot Eye, 368 coast murlocs, Agamand Mills 426/362/354/361, 375.
--   Brill3: 5482 > 99142, 426, 368 > 369, 398, 361, 354/362 > 355, 375, 358/355 > 359.
--   south : 370 Captain Perrine, 374 rings. Brill4: 370 > 371, 91282 (train 10), 96895.
--   east  : 97558, 359 > 360/356, 96895 > 96897/96898 > 96899, 356 + 99142 (Balnir), 371 + 374,
--           369 spiders, 356. Brill5: 369 > 492/445, 95314, 371, 374, 360, 492, 99142.
--   BK    : 91282 > 91285 > 91294 > 91316/91317 > 95803; 96899 > 96896 > 98545; 99152, 99153, 95314.
--   UC    : hearth to Brill, 95314 (train 12), Undercity: 94427 > 94434 (optional), flight path,
--           98545 Glix, 95803 Sylvanas.
-- Skipped: 405/357/366 (Undercity <-> Gunther back-and-forth), 408 (needs a second Agamand trip),
--   372 (far north-east), 99156 Riptear and 95328 Whispering Horror (elites), the rest of the Lesson
--   in Divinity chain 94435+ (crosses Tirisfal twice for Redemption), other Camping 101 quests.
-- Carried into the next segment: 445 (Delivery to Silverpine Forest).
-- Hearthstone: set in Brill on the first visit; used after the west loop and from Bandarion Keep.
--
-- Automation note: every train step comes right AFTER the quest steps at that trainer, and no later
-- step of the same visit accepts anything from her (turn-ins fire as soon as the gossip opens).
if not FastesBoooy.AddLibraryInsert then return end
local _, ns = ...
FastesBoooy.AddLibrarySegment({
    id = "ud-02-tirisfal",
    title = { ru = "6-13 Тирисфальские леса", en = "6-13 Tirisfal Glades" },
    zone = "Tirisfal Glades",
    levels = { 6, 13 },
    steps = {
        ------------------------------------------------------------------
        -- Road to Brill (level 6)
        ------------------------------------------------------------------
        { id = "ud02-365", accept = 365, npc = 1519, at = { 1420, 40.91, 54.17 },
          note = { ru = "Стражник смерти Симмер на дороге в Брилл.",
                   en = "Deathguard Simmer on the road to Brill." } },
        { accept = 5481, npc = 10666, at = { 1420, 43.06, 54.69 },
          note = { ru = "Гордо ходит по дороге между Мертвым Звоном и Бриллом — ищите его рядом.",
                   en = "Gordo walks the road between Deathknell and Brill - look for him nearby." } },
        { complete = 5481, bg = true, at = { 1420, 47.2, 53.3 },
          note = { ru = "Попутно собирайте Мрачную траву (3) вдоль дороги до Брилла.",
                   en = "Pick 3 Gloom Weed along the road to Brill." } },
        { accept = { 86784, 404 }, npc = { 1742, 1496 }, at = { 1420, 58.35, 51.42 },
          note = { ru = "Вход в Брилл: стражники смерти Бартоломью и Диллинджер.",
                   en = "Brill entrance: Deathguards Bartholomew and Dillinger." } },
        { complete = 86784, at = { 1420, 56.9, 52.0 },
          note = { ru = "6 Сухих веток на земле у входа в Брилл.",
                   en = "6 Dry Branches on the ground around the Brill entrance." } },
        { turnin = { 86784, 96656 }, accept = 96607, npc = 265812, at = { 1420, 57.28, 55.49 },
          note = { ru = "Элинор Шеклтон в лагере к югу от дороги.",
                   en = "Eleanor Shackleton at the camp south of the road." } },
        { complete = 96607, object = 460003, at = { 1420, 57.17, 55.55 },
          note = { ru = "Сядьте у костра (/sit) и ждите около минуты, пока не появится бафф отдыха.",
                   en = "Sit at the campfire (/sit) and wait about a minute for the rest buff." } },
        { turnin = 96607, accept = 96658, npc = 265812, at = { 1420, 57.28, 55.49 } },

        ------------------------------------------------------------------
        -- Brill, first visit (level 6)
        ------------------------------------------------------------------
        { id = "ud02-zygand-1", turnin = 383, accept = { 427, 99141, 99134 }, npc = 1515,
          at = { 1420, 60.59, 51.76 },
          note = { ru = "Палач Зиганд в центре Брилла.", en = "Executor Zygand in the middle of Brill." } },
        { complete = 99134, bg = true, use = 286176, at = { 1420, 60.6, 52.2 },
          note = { ru = "Используйте Мотиватор палача на 5 стражниках смерти в Брилле и вокруг него.",
                   en = "Use the Executor's Motivator on 5 Deathguards in and around Brill." } },
        { accept = 367, npc = 1518, at = { 1420, 59.45, 52.40 },
          note = { ru = "Аптекарь Йохан (нужен 6-й уровень).", en = "Apothecary Johaan (needs level 6)." } },
        { complete = { [99141] = { 1 } }, npc = 1496, at = { 1420, 58.2, 51.45 },
          note = { ru = "Диллинджер у входа: попросите отчёт для палача Зиганда (вариант диалога).",
                   en = "Dillinger at the entrance: ask for the report for Executor Zygand (gossip option)." } },
        { id = "ud02-91209", complete = 91209, turnin = 91209, npc = 246152, at = { 1420, 60.22, 52.66 },
          note = { ru = "Шари Стилвелл — тренер паладинов. Поговорите с ней и сдайте задание.",
                   en = "Shari Stilwell, the paladin trainer: talk to her and turn in." } },
        { id = "ud02-train-6", train = true, npc = 246152, at = { 1420, 60.22, 52.66 },
          spells = { { ru = "Священный удар", en = "Holy Strike" },
                     { ru = "Свет небес (ранг 2)", en = "Holy Light (Rank 2)" } },
          note = { ru = "Нужен 6-й уровень. Священный удар — главная кнопка: жмите по откату вместе "
                       .. "с Правосудием.",
                   en = "Needs level 6. Holy Strike is your key button: use it on cooldown together "
                       .. "with Judgement." } },
        { id = "ud02-mallet", vendor = true, npc = 2136, optional = true, at = { 1420, 60.12, 53.39 },
          note = { ru = "Деревянная киянка у Оливера Двора (двуручная булава, 5 ед. урона в секунду, 6 с 66 м): "
                       .. "купите, если она лучше вашего оружия и хватает денег. Продайте серый хлам.",
                   en = "Wooden Mallet from Oliver Dwor (two-handed mace, 5 DPS, 6s 66c): buy it if it beats "
                       .. "your weapon and you can afford it. Sell grey loot." } },
        { id = "ud02-sethearth", turnin = 8, sethearth = "Brill", npc = 5688, at = { 1420, 61.72, 52.05 },
          note = { ru = "Трактирщица Рене: сдайте письмо и сделайте таверну домом. "
                       .. "Не продавайте льняную ткань — 10 штук понадобятся в Подгороде.",
                   en = "Innkeeper Renee: turn in the letter and make this inn your home. "
                       .. "Keep Linen Cloth: you need 10 in the Undercity." } },
        { complete = 96658, turnin = 96658, npc = 265944, at = { 1420, 61.75, 51.44 },
          note = { ru = "Уильям Пикман у таверны: выучите кулинарию и сдайте задание.",
                   en = "William Pickman by the inn: learn Cooking and turn in." } },

        ------------------------------------------------------------------
        -- Rear Guard camp (Kristof, Shelene)
        ------------------------------------------------------------------
        { complete = { [99141] = { 2 } }, accept = 97558, npc = { 251001, 3549 }, at = { 1420, 65.34, 60.16 },
          note = { ru = "Лагерь к юго-востоку от Брилла: отчёт у Кристофа (вариант диалога), "
                       .. "задание у Шелены Робарт.",
                   en = "Camp south-east of Brill: report from Deathguard Kristof (gossip option), "
                       .. "quest from Shelene Rhobart." } },
        { complete = 97558, bg = true, at = { 1420, 45.0, 52.0 },
          note = { ru = "Попутно: перепонки с ночных мышей (8), шкуры гончих (6), шкуры мурлоков (3).",
                   en = "Along the way: Duskbat Wing Membranes (8), Darkhound Hides (6), "
                       .. "Vile Fin Murloc Skins (3)." } },
        { complete = 367, bg = true, at = { 1420, 45.0, 54.0 },
          note = { ru = "Попутно: кровь гончих (5) с дряхлых и проклятых гончих.",
                   en = "Along the way: Darkhound Blood (5) from Decrepit and Cursed Darkhounds." } },

        ------------------------------------------------------------------
        -- West loop: fields west of Brill, Solliden Farmstead (level 6-8)
        ------------------------------------------------------------------
        { complete = 404, at = { 1420, 53.2, 55.0 },
          note = { ru = "Гниющие мертвецы и Растерзанные трупы к западу от Брилла: 7 гнилых когтей.",
                   en = "Rotting Dead and Ravaged Corpses west of Brill: 7 Putrid Claws." } },
        { complete = { [99141] = { 3 } }, npc = 10666, at = { 1420, 43.06, 54.69 },
          note = { ru = "Гордо на дороге: отчёт для Зиганда (вариант диалога).",
                   en = "Gordo on the road: the report for Zygand (gossip option)." } },
        { complete = 427, bg = true, at = { 1420, 32.2, 47.3 },
          note = { ru = "Алые воины (10) на ферме Соллиден.", en = "Scarlet Warriors (10) at Solliden Farmstead." } },
        { complete = 365, at = { 1420, 36.4, 50.4 },
          note = { ru = "Тыквы (10) на полях фермы Соллиден, между алыми воинами.",
                   en = "10 Tirisfal Pumpkins in the Solliden Farmstead fields, among the Scarlet Warriors." } },
        { complete = { [97558] = { 3 } }, at = { 1420, 32.7, 43.2 },
          note = { ru = "Мурлоки Гиблого Плавника на берегу озера к северу от фермы: 3 шкуры.",
                   en = "Vile Fin murlocs on the lake shore north of the farm: 3 skins." } },
        { complete = 427, at = { 1420, 32.2, 47.3 },
          note = { ru = "Добейте алых воинов у башни. Каннибализм на их трупах восстанавливает здоровье и ману.",
                   en = "Finish the Scarlet Warriors by the tower. Cannibalize on their corpses restores "
                       .. "health and mana." } },
        { accept = 99144, npc = 275954, at = { 1420, 31.96, 46.34 },
          note = { ru = "Барет Рассветный Камень на вершине башни Алого ордена. Наверху легко сагрить "
                       .. "трёх воинов сразу.",
                   en = "Bareth Dawnstone at the top of the Scarlet tower. It is easy to pull three "
                       .. "warriors at once up there." } },
        { complete = 99144, at = { 1420, 39.1, 48.8 },
          note = { ru = "Сопровождение: идите с Баретом на восток с фермы и защищайте его. "
                       .. "Задание сдаётся в Брилле.",
                   en = "Escort: follow Bareth east out of the farmstead and protect him. "
                       .. "The quest is turned in at Brill." } },
        { complete = 367, at = { 1420, 41.0, 42.6 },
          note = { ru = "Добейте гончих (и мышей для 97558) к северо-востоку от фермы.",
                   en = "Finish the darkhounds (and duskbats for 97558) north-east of the farm." } },
        { id = "ud02-hearth-1", hearth = "Brill", at = { 1420, 61.72, 52.05 },
          note = { ru = "Камень возвращения в Брилл.", en = "Hearth to Brill." } },

        ------------------------------------------------------------------
        -- Brill, second visit (level 8)
        ------------------------------------------------------------------
        { turnin = { 367, 365 }, accept = { 368, 407 }, npc = 1518, at = { 1420, 59.45, 52.40 },
          note = { ru = "Аптекарь Йохан.", en = "Apothecary Johaan." } },
        { turnin = { 427, 99141, 99134 }, accept = 370, npc = 1515, at = { 1420, 60.59, 51.76 },
          note = { ru = "Палач Зиганд.", en = "Executor Zygand." } },
        { accept = 398, object = 711, at = { 1420, 60.74, 51.50 },
          note = { ru = "Плакат «Разыскивается» рядом с Зигандом: Глаз Личинки.",
                   en = "The Wanted poster next to Zygand: Maggot Eye." } },
        { turnin = 99144, npc = 246152, at = { 1420, 60.22, 52.66 } },
        { id = "ud02-train-8", train = true, npc = 246152, at = { 1420, 60.22, 52.66 },
          spells = { { ru = "Молот правосудия", en = "Hammer of Justice" } },
          note = { ru = "Нужен 8-й уровень (если нет — выучите на 10-м вместе с остальным).",
                   en = "Needs level 8 (if not yet, train it at level 10 with the rest)." } },
        { accept = 374, npc = 1652, at = { 1420, 60.93, 52.01 },
          note = { ru = "Стражник смерти Берджесс.", en = "Deathguard Burgess." } },
        { collect = { [2320] = 1 }, npc = 2118, at = { 1420, 61.03, 52.37 },
          note = { ru = "Купите Грубую нить у Эбигейл Шил (для 375).",
                   en = "Buy Coarse Thread from Abigail Shiel (for 375)." } },
        { accept = 358, npc = 1499, at = { 1420, 61.26, 50.84 },
          note = { ru = "Мировой судья Севрен.", en = "Magistrate Sevren." } },
        { accept = { 354, 362, 375 }, npc = { 1500, 1521 }, at = { 1420, 61.8, 52.5 },
          note = { ru = "Коулман Фартинг и Гретхен Дедмар в таверне (нужен 7-й уровень).",
                   en = "Coleman Farthing and Gretchen Dedmar in the inn (need level 7)." } },
        { turnin = 407, npc = 1931, at = { 1420, 61.97, 51.29 },
          note = { ru = "Пленный алый фанатик за таверной.", en = "Captured Scarlet Zealot behind the inn." } },
        { turnin = 404, accept = 426, npc = 1496, at = { 1420, 58.2, 51.45 } },
        { turnin = 5481, accept = 5482, npc = 10665, at = { 1420, 57.44, 48.85 },
          note = { ru = "Младший аптекарь Холланд на северо-западной окраине Брилла.",
                   en = "Junior Apothecary Holland on the north-west edge of Brill." } },

        ------------------------------------------------------------------
        -- North loop: gnolls, Garren's Haunt, coast, Agamand Mills (level 8-10)
        ------------------------------------------------------------------
        { complete = 375, bg = true, at = { 1420, 62.8, 42.4 },
          note = { ru = "Попутно: шкуры ночных мышей (5).", en = "Along the way: Duskbat Pelts (5)." } },
        { complete = 5482, bg = true, at = { 1420, 57.3, 38.5 },
          note = { ru = "Попутно: Роковая трава (10) на полях к северу от Брилла.",
                   en = "Along the way: Doom Weed (10) in the fields north of Brill." } },
        { complete = 358, at = { 1420, 57.6, 38.0 },
          note = { ru = "Гноллы Гнилошкуры к северу от Брилла: 8 грабителей могил, 5 дворняг и 8 бальзамирующих "
                       .. "жидкостей.",
                   en = "Rot Hide gnolls north of Brill: 8 Graverobbers, 5 Mongrels and 8 Embalming Ichor." } },
        { complete = 398, npc = 1753, at = { 1420, 58.66, 30.77 },
          note = { ru = "Глаз Личинки (11 ур.) в Гарренской Тени. Подтяните его по одному, держите Молот "
                       .. "правосудия на случай беды.",
                   en = "Maggot Eye (level 11) at Garren's Haunt. Pull him alone and keep Hammer of Justice "
                       .. "for emergencies." } },
        { complete = 368, at = { 1420, 60.3, 27.9 },
          note = { ru = "Мурлоки Гиблого Плавника на северном берегу: 5 чешуек (и шкуры для 97558).",
                   en = "Vile Fin murlocs on the north coast: 5 scales (and skins for 97558)." } },
        { complete = 5482, at = { 1420, 57.3, 36.0 },
          note = { ru = "Доберите Роковую траву на обратном пути на юг.", en = "Finish the Doom Weed heading back south." } },
        { complete = 426, bg = true, at = { 1420, 47.3, 36.0 },
          note = { ru = "Скелеты Мельниц Агамандов: 5 зазубренных рёбер и 3 почерневших черепа. С них может "
                       .. "выпасть Письмо Иветте — сохраните его.",
                   en = "Agamand Mills skeletons: 5 Notched Ribs and 3 Blackened Skulls. They may drop "
                       .. "A Letter to Yvette: keep it." } },
        { complete = 362, npc = 1657, at = { 1420, 47.23, 40.02 },
          note = { ru = "Девлин Агаманд (9) у южных мельниц.", en = "Devlin Agamand (9) by the southern mills." } },
        { complete = { [354] = { 2 } }, npc = 1655, at = { 1420, 49.74, 36.34 },
          note = { ru = "Нисса Агаманд (10) — восточная часть деревни.", en = "Nissa Agamand (10) in the east of the village." } },
        { complete = { [354] = { 1 } }, npc = 1654, at = { 1420, 45.79, 29.39 },
          note = { ru = "Грегор Агаманд (10) на севере деревни.", en = "Gregor Agamand (10) in the north of the village." } },
        { complete = { [354] = { 3 } }, npc = 1656, at = { 1420, 42.84, 32.54 },
          note = { ru = "Турман Агаманд (10) на западе.", en = "Thurman Agamand (10) in the west." } },
        { complete = 426, at = { 1420, 47.6, 40.5 },
          note = { ru = "Добейте рёбра и черепа, затем идите обратно в Брилл, убивая ночных мышей по пути.",
                   en = "Finish the ribs and skulls, then head back to Brill killing duskbats on the way." } },
        { complete = 375, at = { 1420, 48.2, 47.1 },
          note = { ru = "Доберите шкуры ночных мышей по дороге в Брилл.", en = "Finish the Duskbat Pelts on the way to Brill." } },

        ------------------------------------------------------------------
        -- Brill, third visit (level 9-10)
        ------------------------------------------------------------------
        { turnin = 5482, accept = 99142, npc = 10665, at = { 1420, 57.44, 48.85 } },
        { turnin = 426, npc = 1496, at = { 1420, 58.2, 51.45 },
          note = { ru = "Награда: Сапоги склепохода (кольчуга).", en = "Reward: Cryptwalker Boots." } },
        { turnin = 368, accept = 369, npc = 1518, at = { 1420, 59.45, 52.40 } },
        { turnin = 398, npc = 1515, at = { 1420, 60.59, 51.76 },
          note = { ru = "Награда: Латунные чешуйчатые штаны (кольчуга).", en = "Reward: Brass Scale Pants (mail)." } },
        { accept = 361, use = 2839, optional = true, at = { 1420, 61.58, 52.60 },
          note = { ru = "Если со скелетов Мельниц Агамандов выпало Письмо Иветте — используйте его. "
                       .. "Нет письма — пропустите этот и следующий шаг.",
                   en = "If A Letter to Yvette dropped from the Agamand Mills skeletons, use it. "
                       .. "No letter: skip this and the next step." } },
        { turnin = 361, npc = 1560, optional = true, at = { 1420, 61.58, 52.60 },
          note = { ru = "Иветта Фартинг в таверне.", en = "Yvette Farthing in the inn." } },
        { turnin = { 354, 362 }, accept = 355, npc = 1500, at = { 1420, 61.72, 52.29 } },
        { turnin = 375, npc = 1521, at = { 1420, 61.89, 52.73 } },
        { turnin = { 358, 355 }, accept = 359, npc = 1499, at = { 1420, 61.26, 50.84 },
          note = { ru = "Награда за 358: Перчатки из холодной стали (кольчуга).",
                   en = "358 reward: Cold Steel Gauntlets (mail)." } },

        ------------------------------------------------------------------
        -- South: Captain Perrine's camp, then Brill fourth visit (level 10)
        ------------------------------------------------------------------
        { complete = 374, bg = true, at = { 1420, 51.6, 68.0 },
          note = { ru = "Попутно: Алые кольца с печатью (10) со всех бойцов Алого ордена.",
                   en = "Along the way: Scarlet Insignia Rings (10) from all Scarlet Crusade mobs." } },
        { complete = 370, at = { 1420, 51.6, 68.0 },
          note = { ru = "Лагерь Алого ордена к юго-западу от Подгорода: капитан Перрин, 3 фанатика и "
                       .. "3 миссионера.",
                   en = "Scarlet camp south-west of the Undercity: Captain Perrine, 3 Zealots and "
                       .. "3 Missionaries." } },
        { turnin = 370, accept = 371, npc = 1515, at = { 1420, 60.59, 51.76 },
          note = { ru = "Вернитесь к Зиганду в Брилл.", en = "Back to Zygand in Brill." } },
        { id = "ud02-91282", accept = 91282, npc = 246152, at = { 1420, 60.22, 52.66 },
          note = { ru = "Шари Стилвелл: задание паладина в крепость Бандарион.",
                   en = "Shari Stilwell: the paladin quest to Bandarion Keep." } },
        -- level 10: the training and the 96895 chain (reqLevel 10) need it; validator: ~10.3 here.
        { id = "ud02-train-10", train = true, level = 10, npc = 246152, at = { 1420, 60.22, 52.66 },
          spells = { { ru = "Печать праведности (ранг 2)", en = "Seal of Righteousness (Rank 2)" },
                     { ru = "Аура благочестия (ранг 2)", en = "Devotion Aura (Rank 2)" },
                     { ru = "Возложение рук", en = "Lay on Hands" } },
          note = { ru = "Нужен 10-й уровень (не хватает — добейте мобов у Брилла). Выучите и Молот правосудия, "
                       .. "если пропустили. Таланты: первое очко — в Воздаяние.",
                   en = "Needs level 10 (if short, kill a few mobs near Brill). Also train Hammer of Justice if "
                       .. "you missed it. Talents: first point in Retribution." } },
        { accept = 96895, npc = 1738, at = { 1420, 61.50, 53.50 },
          note = { ru = "Стражник смерти Терренс на южной окраине (нужен 10-й уровень).",
                   en = "Deathguard Terrence at the south edge of Brill (needs level 10)." } },

        ------------------------------------------------------------------
        -- East loop: Rear Guard, Argent emissary, Balnir Farmstead, Venomweb Vale (level 10-12)
        ------------------------------------------------------------------
        { turnin = { 97558, 359 }, accept = { 360, 356 }, npc = { 3549, 1495 },
          at = { 1420, 65.46, 60.18 },
          note = { ru = "Шелена Робарт и Линнея. Награда за 97558: Подошвы из плавников (+1 к силе).",
                   en = "Shelene Rhobart and Linnea. 97558 reward: Finscale Soles (+1 Str)." } },
        { turnin = 96895, accept = { 96897, 96898 }, npc = 267009, at = { 1420, 65.93, 61.13 },
          note = { ru = "Хадрик Харлсон из Серебряного Рассвета рядом с лагерем.",
                   en = "Hadric Harlson of the Argent Dawn next to the camp." } },
        { complete = { 96897, 96898 }, at = { 1420, 67.5, 63.2 },
          note = { ru = "Тёмные неофиты и силовики (по 8) к юго-востоку. Осколки кристаллов падают с них "
                       .. "и лежат на земле (12). Силовики бьют сильно — по одному.",
                   en = "Dark Neophytes and Dark Enforcers (8 each) to the south-east. Crystal fragments "
                       .. "drop from them and lie on the ground (12). Enforcers hit hard: one at a time." } },
        { turnin = { 96897, 96898 }, accept = 96899, npc = 267009, at = { 1420, 65.93, 61.13 } },
        { complete = { 356, 99142 }, at = { 1420, 76.4, 60.6 },
          note = { ru = "Ферма Бальнира: кровоточащие ужасы и блуждающие духи (по 8), Могильная трава (5).",
                   en = "Balnir Farmstead: Bleeding Horrors and Wandering Spirits (8 each), 5 Tomb Weed." } },
        { complete = 371, at = { 1420, 79.2, 56.1 },
          note = { ru = "Лагерь Алого ордена к северо-востоку от фермы: капитан Вашон (11) и 5 монахов.",
                   en = "Scarlet camp north-east of the farm: Captain Vachon (11) and 5 Scarlet Friars." } },
        { complete = 369, at = { 1420, 86.6, 52.0 },
          note = { ru = "Долина Ядовитой Паутины: 4 яда свирепых пауков.",
                   en = "Venomweb Vale: 4 Vicious Night Web Spider Venoms." } },
        { complete = 374, at = { 1420, 86.9, 43.2 },
          note = { ru = "Если колец меньше 10 — монахи и фанатики к северу от пауков.",
                   en = "Short on rings: Friars and Zealots just north of the spiders." } },
        { turnin = 356, npc = 1495, at = { 1420, 65.49, 60.25 },
          note = { ru = "Линнея (продолжение про Рваноклыка — элитное, пропустите).",
                   en = "Linnea (skip the Riptear follow-up: elite)." } },

        ------------------------------------------------------------------
        -- Brill, fifth visit (level 11-12)
        ------------------------------------------------------------------
        { turnin = 369, accept = { 492, 445 }, npc = 1518, at = { 1420, 59.45, 52.40 }, -- 445 is carried: Renferrel, Silverpine (ud-03)
          note = { ru = "445 ведёт в Серебряный бор — держите его.", en = "445 leads to Silverpine Forest: keep it." } },
        { accept = 95314, npc = 2132, at = { 1420, 59.43, 52.19 },
          note = { ru = "Каролай Аниз рядом с Йоханом: задание для Тенистой долины.",
                   en = "Carolai Anise next to Johaan: a quest for Shadowvale." } },
        { turnin = 371, npc = 1515, at = { 1420, 60.59, 51.76 } },
        { turnin = 374, npc = 1652, at = { 1420, 60.93, 52.01 },
          note = { ru = "Награда: Пояс с застёжками (кольчуга).", en = "Reward: Clasped Belt (mail)." } },
        { turnin = 360, npc = 1499, at = { 1420, 61.26, 50.84 } },
        { turnin = 492, npc = 2211, at = { 1420, 61.94, 51.40 },
          note = { ru = "Пленный горец за таверной.", en = "Captured Mountaineer behind the inn." } },
        { turnin = 99142, npc = 10665, at = { 1420, 57.44, 48.85 } },

        ------------------------------------------------------------------
        -- Bandarion Keep (level 12)
        ------------------------------------------------------------------
        { go = true, at = { 1420, 40.8, 54.4 },
          note = { ru = "На запад по дороге мимо Симмера.", en = "West along the road past Simmer." } },
        { go = true, at = { 1420, 28.8, 46.5 },
          note = { ru = "Через ферму Соллиден к крепости Бандарион.", en = "Through Solliden Farmstead toward Bandarion Keep." } },
        { id = "ud02-91285", turnin = 91282, accept = 91285, npc = 246349, at = { 1420, 21.85, 45.23 },
          note = { ru = "Бретон Сэмюэлс у крепости Бандарион.", en = "Breton Samuels at Bandarion Keep." } },
        { turnin = 96899, accept = 96896, npc = 267008, at = { 1420, 22.03, 44.73 },
          note = { ru = "Леонид Варфоломей наверху в крепости.", en = "Leonid Barthalomew upstairs in the keep." } },
        { complete = 96896, at = { 1420, 22.03, 44.73 },
          note = { ru = "Послушайте разговор Даниты и Леонида.", en = "Listen to the conversation between Danitha and Leonid." } },
        { turnin = 96896, accept = 98545, npc = 267008, at = { 1420, 22.03, 44.73 },
          note = { ru = "Письмо Леонида — для Подгорода.", en = "Leonid's Letter is for the Undercity." } },
        { complete = 91285, at = { 1420, 26.8, 45.0 },
          note = { ru = "Лагерь мурлоков на берегу озера сразу к востоку от крепости: 8 налётчиков и 8 провидцев.",
                   en = "Murloc camp on the lake shore just east of the keep: 8 Vile Fin Attackers and 8 Seers." } },
        { id = "ud02-smasher", turnin = 91285, accept = 91294, npc = 246349, at = { 1420, 21.85, 45.23 },
          note = { ru = "Награда: Плавниковый крушитель (двуручная булава; не Головолом) — главное оружие до "
                       .. "Молота Каменного леса (855, ~19 ур.).",
                   en = "Reward: Driftwood Smasher (two-handed mace; not Skullthumper) - your main weapon until "
                       .. "the Stonewood Hammer from 855 (~level 19)." } },
        { id = "ud02-91294", complete = { [91294] = { 1 } }, accept = 99152, npc = 246389, at = { 1420, 21.96, 47.25 },
          note = { ru = "Хильда Сокрушительница у южной стены крепости: поговорите с ней и возьмите задание.",
                   en = "Hilda the Breaker by the south wall of the keep: talk to her and take her quest." } },
        { complete = { [91294] = { 3 } }, npc = 246394, at = { 1420, 25.41, 50.41 },
          note = { ru = "Андер Соллиден патрулирует дорогу к юго-востоку от крепости.",
                   en = "Ander Solliden patrols the road south-east of the keep." } },
        { complete = { [91294] = { 2 } }, npc = 246393, at = { 1420, 22.69, 44.70 },
          note = { ru = "Джорин Кроге внутри крепости.", en = "Jorin Croge inside the keep." } },
        { id = "ud02-91317",
          complete = { [91294] = { 4 } }, turnin = 91294, accept = 91317, npc = 246378, at = { 1420, 22.09, 44.66 },
          note = { ru = "Данита Морр наверху.", en = "Danitha Morr upstairs." } },
        { id = "ud02-91316", accept = 91316, npc = 246393, at = { 1420, 22.69, 44.70 } },
        { accept = 99153, npc = 259190, at = { 1420, 20.17, 46.49 },
          note = { ru = "Эфрам Барбаро к юго-западу от крепости, по пути в Тенистую долину.",
                   en = "Ephram Barbaro south-west of the keep, on the way to Shadowvale." } },

        ------------------------------------------------------------------
        -- Shadowvale (level 12)
        ------------------------------------------------------------------
        { complete = 91317, bg = true, at = { 1420, 14.8, 63.1 },
          note = { ru = "Потускневшие работяги (8) и фанатики (6) по всей Тенистой долине.",
                   en = "Tarnished Drudges (8) and Zealots (6) all over Shadowvale." } },
        { complete = 99152, bg = true, at = { 1420, 11.5, 65.5 },
          note = { ru = "Слабо светящиеся кости (6) с бродяг и мистиков Тенистой долины.",
                   en = "Faintly Glowing Bones (6) from Shadowvale Lurchers and Mystics." } },
        { complete = { 91316, 95314 }, bg = true, at = { 1420, 10.2, 65.5 },
          note = { ru = "Кучи досок (12 досок) и бутылки с эликсиром (8) на земле и на стенах.",
                   en = "Lumber Piles (12 Sturdy Lumber) and Bottles of Whispering Elixir (8) on the ground "
                       .. "and on the walls." } },
        { collect = { [270435] = 1 }, npc = 259431, at = { 1420, 11.51, 64.18 },
          note = { ru = "Рудольф Гельхардт (12) наверху: заберите его голову. Шепчущие ужасы — элита, обходите.",
                   en = "Rudolph Gelhardt (12) upstairs: loot his head. Whispering Horrors are elite: avoid them." } },
        { complete = 99153, object = 694895, at = { 1420, 9.74, 69.43 },
          note = { ru = "Светящийся осколок кристалла лежит внизу, на юге Тенистой долины.",
                   en = "The Glowing Crystal Fragment lies down below in the south of Shadowvale." } },
        { complete = { 91317, 99152, 91316, 95314 }, at = { 1420, 11.5, 65.5 },
          note = { ru = "Добейте всё в Тенистой долине и возвращайтесь в крепость.",
                   en = "Finish everything in Shadowvale and head back to the keep." } },
        { turnin = 99153, npc = 259190, at = { 1420, 20.17, 46.49 } },
        { turnin = 99152, npc = 246389, at = { 1420, 21.96, 47.25 } },
        { turnin = 91316, npc = 246393, at = { 1420, 22.69, 44.70 },
          note = { ru = "Награда: башенный щит — пригодится только для игры со щитом.",
                   en = "Reward: Salvaged Wooden Tower Shield - only useful for shield play." } },
        { id = "ud02-95803", turnin = 91317, accept = 95803, npc = 246378, at = { 1420, 22.09, 44.66 },
          note = { ru = "Данита: голову Рудольфа нужно отнести леди Сильване в Подгород.",
                   en = "Danitha: Rudolph's head goes to Lady Sylvanas in the Undercity." } },
        -- 94427 needs level 12 (validator: ~12.6 here); only its first two steps are on the path. A lone
        -- level step never anchors (Core/Engine.lua), so reaching 12 early forwards nothing. Merging it into
        -- the accept makes the simulator mock refuse the quest (it applies `level` after the dialogs), so the
        -- gate stays separate.
        { id = "ud02-xp-12", level = 12, optional = true, at = { 1420, 22.09, 44.66 },
          note = { ru = "12-й уровень для «Урока божественности». Не хватает — пропустите два шага.",
                   en = "Level 12 for A Lesson in Divinity. Not there yet: skip these two steps." } },
        { id = "ud02-94427", accept = 94427, npc = 246378, optional = true, at = { 1420, 22.09, 44.66 },
          note = { ru = "Если уже 12-й уровень: «Урок божественности» (сдаётся в Подгороде). Нет — пропустите.",
                   en = "If you are level 12: A Lesson in Divinity (turned in at the Undercity). If not, skip it." } },

        ------------------------------------------------------------------
        -- Brill and the Undercity (level 12-13)
        ------------------------------------------------------------------
        { id = "ud02-hearth-2", hearth = "Brill", at = { 1420, 61.72, 52.05 },
          note = { ru = "Камень возвращения в Брилл.", en = "Hearth to Brill." } },
        { turnin = 95314, npc = 2132, at = { 1420, 59.43, 52.19 } },
        { id = "ud02-train-12", train = true, npc = 246152, at = { 1420, 60.22, 52.66 },
          spells = { { ru = "Священный удар (ранг 2)", en = "Holy Strike (Rank 2)" },
                     { ru = "Благословение могущества (ранг 2)", en = "Blessing of Might (Rank 2)" } },
          note = { ru = "Нужен 12-й уровень. Не хватает — выучите эти ранги у Гарена Ларго в Подгороде вместе "
                       .. "с 14-м (конец Серебряного бора).",
                   en = "Needs level 12. Not there yet: train these ranks from Garen Largo in the Undercity "
                       .. "together with level 14 (end of Silverpine)." } },
        { go = true, at = { 1420, 61.92, 64.85 },
          note = { ru = "Вход в Подгород через Руины Лордерона к югу от Брилла, лифт вниз.",
                   en = "Undercity entrance through the Ruins of Lordaeron south of Brill, take the lift down." } },
        { turnin = 94427, accept = 94434, npc = 257648, optional = true, at = { 1458, 65.48, 37.49 },
          note = { ru = "Танис Алдервуд в Торговом квартале (если брали «Урок божественности»).",
                   en = "Tanis Alderwood in the Trade Quarter (if you took A Lesson in Divinity)." } },
        { complete = 94434, turnin = 94434, npc = 257648, optional = true, at = { 1458, 65.48, 37.49 },
          note = { ru = "Отдайте 10 льняной ткани. Следующее задание (обратно в крепость) не берите.",
                   en = "Hand in 10 Linen Cloth. Do not take the next one (back to the keep)." } },
        { id = "ud02-fp-uc", fp = "Undercity", npc = 4551, at = { 1458, 63.25, 48.56 },
          note = { ru = "Майкл Гаррет — точка полёта Подгорода.", en = "Michael Garrett: Undercity flight path." } },
        { turnin = 98545, npc = 272526, at = { 1458, 70.03, 47.31 },
          note = { ru = "Гликс Ксиззикс в Торговом квартале.", en = "Glix Xizzix in the Trade Quarter." } },
        { id = "ud02-end", turnin = 95803, npc = 10181, at = { 1458, 58.05, 91.79 },
          note = { ru = "Леди Сильвана в Королевском квартале.", en = "Lady Sylvanas in the Royal Quarter." } },
    },
})

-- Start-zone announcement (read by Route.lua): the segments every Undead route starts with. `only`: while the
-- two segments still hold the paladin's class steps, only the paladin route of the zone's race is registered.
ns.startZones = ns.startZones or {}
ns.startZones.Tirisfal = { "ud-01-deathknell", "ud-02-tirisfal", only = { "PALADIN" } }
