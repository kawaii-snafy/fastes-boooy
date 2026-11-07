-- FastesBoooy_UndeadPaladin / Segments / 03_Silverpine.lua
--
-- Segment ud-03-silverpine: Undercity -> Silverpine Forest (Ivar Patch, The Sepulcher) -> hearth to
-- Brill -> Undercity (turn-ins, level-14 training) -> zeppelin to Durotar, levels 13-15.
-- Coordinates: Forever uiMap 1421 (Silverpine Forest) / 1420 (Tirisfal Glades) / 1458 (Undercity) /
-- 1411 (Durotar), map percent, from tools/data/forever_db.lua (NPC/object spawns; centroids of the
-- objective mob spawns of the chosen area for complete steps). Zeppelin masters: tools/data/forever_db.lua
-- (transport NPCs: Zapetta 9566 Tirisfal 60.74,58.87; Frezza 9564 Durotar 50.82,13.54).
-- 429 Wild Hearts needs 3 hearts in Forever (Wowhead Forever tooltip; the DB snapshot still says 6 from
-- the Classic text, so the validator's kill XP for it is a little high).
--
-- Hub plan (Forever DB; Sepulcher NPCs all within ~60 yd of 44,41):
--   T1 Ivar Patch (arrival from the Tirisfal road): 435 escort > 449 + 429 (Rane Yorick), worg hearts,
--      3 Murloc Eyes in advance for 91920 (they drop without the quest).
--   V1 Sepulcher: 421 (Dalar, req 12), 477 (Allister), 449 > 3221 + 437 (Hadrec),
--      445/3221/429 > 1359/447/430 (Renferrel), 6321 > 6323 (Podrig > Karos Razok), flight path.
--   L1 whitescalps (421) east of the Sepulcher, bears (447) all segment. V2: 421 > 422.
--   T2 north: Dusty Spellbooks (422) > Quinn 430 > 91920 > Rane 425 > Ivar the Foul > Rane >
--      Dead Field (437 Nightlash) > spiders (447 blood) > bears > back. V3: 422 > 423, 437 > 438, 91920.
--   T3 west: Moonrage Glutton/Darksoul shackles (423). V4: 423 > 424.
--   L4 east/south: ferry boat (438 > 439), Grimson the Pale (424), Dalaran Crate (477 > 478), back.
--   V5: 478 > 481 > 482, 424, 439 > 440. Hearth to Brill: 440 > 441 (Sevren).
--   UC: 6323 > 6322, 441, 6322, 97891 (timed), 447, 1359 > 1358, Garen Largo (14), zeppelin.
-- Skipped: 91921 (a third trip north for one Forever-new delivery), 428 (breadcrumb for 429, Rane is
--   met first), 6324 (back to the Sepulcher), 99/450/452/98298 (south Silverpine: Pyrewood, Ambermill),
--   479 (Ambermill, 16), 443 (Rot Hide gnolls 16-19), 92401/5725 (dungeons), 530 (Raleigh follow-up).
-- Carried into the next segment: 1358 Sample for Helbrim (Apothecary Helbrim, Crossroads).
-- Hearthstone: still bound to Brill (seg 2); used once from the Sepulcher at the end of the zone.
--
-- Automation note: every trainer/flight-master transient step comes AFTER the quest steps at that NPC;
-- no step accepts a quest from an NPC on both sides of a transient step.
FastesBoooy.AddSegment("horde-undead-paladin", {
    id = "ud-03-silverpine",
    title = { ru = "13-15 Серебряный бор", en = "13-15 Silverpine Forest" },
    zone = "Silverpine Forest",
    levels = { 13, 15 },
    steps = {
        ------------------------------------------------------------------
        -- Undercity -> Silverpine Forest (level 13)
        ------------------------------------------------------------------
        { id = "ud03-exit-uc", go = true, at = { 1420, 61.92, 64.85 },
          note = { ru = "Выйдите из Подгорода на лифте к Руинам Лордерона.",
                   en = "Leave the Undercity by the lift up to the Ruins of Lordaeron." } },
        { go = true, at = { 1420, 53.2, 75.8 },
          note = { ru = "На юго-запад к дороге в Серебряный бор, восточнее лагеря Алого ордена.",
                   en = "South-west to the Silverpine Forest road, east of the Scarlet camp." } },

        ------------------------------------------------------------------
        -- The Ivar Patch, first visit (level 13)
        ------------------------------------------------------------------
        { id = "ud03-435", accept = 435, npc = 1978, at = { 1421, 56.18, 9.18 },
          note = { ru = "Следопыт Эрланд в доме у дороги. Нет на месте (его уже ведёт другой игрок) — подождите "
                       .. "1-2 минуты, убивая воргов рядом.",
                   en = "Deathstalker Erland in the house by the road. Not there (another player is escorting "
                       .. "him): wait 1-2 minutes killing worgs nearby." } },
        { complete = 435, at = { 1421, 53.6, 13.2 },
          note = { ru = "Сопровождение: идите с Эрландом к Рейну Йорику на ферму Ивара. По пути нападают ворги.",
                   en = "Escort: walk Erland to Rane Yorick at the Ivar Patch. Worgs attack on the way." } },
        { turnin = 435, accept = { 429, 449 }, npc = 1950, at = { 1421, 53.46, 13.43 },
          note = { ru = "Рейн Йорик. Награда — Короткий меч стража смерти: оставьте Плавниковый крушитель.",
                   en = "Rane Yorick. Reward: Deathstalker Shortsword - keep the Driftwood Smasher." } },
        { collect = { [730] = 3 }, bg = true, at = { 1421, 60.0, 15.5 },
          note = { ru = "Попутно: 3 глаза мурлока с мурлоков Гиблого Плавника к востоку от фермы. Они нужны "
                       .. "для задания Куинна позже — не продавайте.",
                   en = "Along the way: 3 Murloc Eyes from the Vile Fin murlocs east of the farm. Quinn's later "
                       .. "quest needs them: do not sell." } },
        { complete = 429, at = { 1421, 58.0, 11.5 },
          note = { ru = "Пятнистые ворги и ворги вокруг фермы: 3 бесцветных сердца. Редкий Кровавый Клык "
                       .. "бродит к северо-востоку.",
                   en = "Mottled Worgs and Worgs around the farm: 3 Discolored Worg Hearts. Gorefang (rare) "
                       .. "roams to the north-east." } },
        { go = true, at = { 1421, 49.8, 31.0 },
          note = { ru = "По дороге на юг к Гробнице, убивая воргов по пути.",
                   en = "South along the road to the Sepulcher, killing worgs on the way." } },

        ------------------------------------------------------------------
        -- The Sepulcher, first visit (level 13)
        ------------------------------------------------------------------
        { accept = 421, npc = 1938, at = { 1421, 44.20, 39.81 },
          note = { ru = "Далар Ткач Зари у входа в Гробницу (нужен 12-й уровень).",
                   en = "Dalar Dawnweaver at the Sepulcher entrance (needs level 12)." } },
        { vendor = true, npc = 2140, optional = true, at = { 1421, 43.98, 39.90 },
          note = { ru = "Эдвин Харли рядом: продайте серый хлам, купите воду.",
                   en = "Edwin Harly next to him: sell grey loot, buy water." } },
        { accept = 477, npc = 2121, at = { 1421, 43.98, 40.93 },
          note = { ru = "Тёмный жрец Аллистер.", en = "Shadow Priest Allister." } },
        { turnin = 449, accept = { 3221, 437 }, npc = 1952, at = { 1421, 43.42, 40.86 },
          note = { ru = "Верховный палач Хадрек внизу, в склепе.", en = "High Executor Hadrec down in the crypt." } },
        { turnin = { 445, 3221, 429 }, accept = { 1359, 447, 430 }, npc = 1937, at = { 1421, 42.80, 40.86 },
          note = { ru = "Аптекарь Ренферрел в склепе.", en = "Apothecary Renferrel in the crypt." } },
        { accept = 6321, npc = 6389, at = { 1421, 43.42, 41.68 },
          note = { ru = "Стражник смерти Подриг.", en = "Deathguard Podrig." } },
        { turnin = 6321, accept = 6323, npc = 2226, at = { 1421, 45.62, 42.60 },
          note = { ru = "Карос Разок, распорядитель летучих мышей. 6323 сдаётся в Подгороде — лететь не нужно.",
                   en = "Karos Razok, the bat handler. 6323 is turned in at the Undercity: no need to fly now." } },
        { id = "ud03-fp-sepulcher", fp = "The Sepulcher", npc = 2226, at = { 1421, 45.62, 42.60 },
          note = { ru = "Откройте карту полётов, чтобы узнать точку.", en = "Open the flight map to learn the path." } },

        ------------------------------------------------------------------
        -- East of the Sepulcher: whitescalps (level 13)
        ------------------------------------------------------------------
        { complete = 447, bg = true, at = { 1421, 49.2, 33.0 },
          note = { ru = "Весь сегмент попутно: сердца серых медведей (6) — медведи повсюду вдоль дороги.",
                   en = "All segment along the way: Grizzled Bear Hearts (6) - bears are all along the road." } },
        { complete = 421, at = { 1421, 50.5, 39.0 },
          note = { ru = "Белогривые воргены Лунной Ярости (5) к востоку от Гробницы. Сын Аругала (элита, 24) "
                       .. "иногда бродит здесь — уходите от него.",
                   en = "Moonrage Whitescalps (5) east of the Sepulcher. Son of Arugal (elite, 24) sometimes "
                       .. "roams here: stay away." } },
        { turnin = 421, accept = 422, npc = 1938, at = { 1421, 44.20, 39.81 } },

        ------------------------------------------------------------------
        -- North loop: spellbooks, Ivar Patch, Dead Field, spiders (level 13-14)
        ------------------------------------------------------------------
        { complete = 422, object = 1571, at = { 1421, 52.83, 28.58 },
          note = { ru = "Дом у дороги на север: на втором этаже Пыльные книги заклинаний (Снадобье Аругала).",
                   en = "House by the north road: the Dusty Spellbooks on the second floor (Remedy of Arugal)." } },
        { turnin = 430, accept = 91920, npc = 1951, at = { 1421, 53.43, 12.59 },
          note = { ru = "Куинн Йорик на втором этаже дома на ферме Ивара. Глаза мурлока уже в сумке — задание "
                       .. "сразу выполнено.",
                   en = "Quinn Yorick upstairs in the Ivar Patch house. The Murloc Eyes are already in your bags: "
                       .. "the quest is done at once." } },
        { accept = 425, npc = 1950, at = { 1421, 53.46, 13.43 } },
        { complete = 425, npc = 1971, at = { 1421, 51.52, 13.90 },
          note = { ru = "Ивар Мерзкий (13) в сарае к западу, с ним два раба Когтя Ворона. Выманивайте по одному.",
                   en = "Ivar the Foul (13) in the barn to the west with two Ravenclaw Slaves. Pull them one "
                       .. "at a time." } },
        { turnin = 425, npc = 1950, at = { 1421, 53.46, 13.43 },
          note = { ru = "Награда: Потёртый пояс (кожа).", en = "Reward: Weathered Belt (leather)." } },
        { complete = 91920, at = { 1421, 60.0, 15.5 },
          note = { ru = "Меньше 3 глаз мурлока? Мурлоки Гиблого Плавника к востоку от фермы.",
                   en = "Fewer than 3 Murloc Eyes? Vile Fin murlocs east of the farm." } },
        { complete = 437, npc = 1983, at = { 1421, 44.67, 20.67 },
          note = { ru = "Мёртвое поле: убивайте гноллов Гнилошкуры, пока не появится Ночная Плеть (14). Убейте "
                       .. "её и заберите сущность. Медведи рядом — для сердец.",
                   en = "The Dead Field: kill Rot Hide gnolls until Nightlash (14) appears. Kill her and loot "
                       .. "her essence. Bears nearby for the hearts." } },
        { complete = { [447] = { 2 } }, at = { 1421, 35.3, 12.5 },
          note = { ru = "Пауки на северо-западе (мшистые охотники и туманные ползуны): 6 проб крови. Редкая "
                       .. "Кретис Тенепряд (15) ставит щит — обходите её.",
                   en = "Spiders to the north-west (Moss Stalkers and Mist Creepers): 6 Skittering Blood. "
                       .. "Krethis Shadowspinner (rare, 15) shields herself: avoid her." } },
        { complete = 447, at = { 1421, 40.4, 17.4 },
          note = { ru = "Доберите сердца с гигантских серых медведей и возвращайтесь в Гробницу на юг.",
                   en = "Finish the hearts on Giant Grizzled Bears, then head south back to the Sepulcher." } },

        ------------------------------------------------------------------
        -- The Sepulcher, third visit (level 14)
        ------------------------------------------------------------------
        { turnin = 422, accept = 423, npc = 1938, at = { 1421, 44.20, 39.81 } },
        { vendor = true, npc = 2140, optional = true, at = { 1421, 43.98, 39.90 },
          note = { ru = "Продайте хлам у Эдвина Харли, купите воду.", en = "Sell junk to Edwin Harly, buy water." } },
        { turnin = 437, accept = 438, npc = 1952, at = { 1421, 43.42, 40.86 },
          note = { ru = "Награда: Сапоги разведчика.", en = "Reward: Reconnaissance Boots." } },
        { turnin = 91920, npc = 1937, at = { 1421, 42.80, 40.86 }, -- WARN-OK: xp-unknown, Forever-new
          note = { ru = "Следующее задание (снова к Куинну на север) не берите.",
                   en = "Do not take the follow-up (back north to Quinn)." } },

        ------------------------------------------------------------------
        -- West of the road: shackles (level 14)
        ------------------------------------------------------------------
        { complete = 423, at = { 1421, 41.5, 28.0 },
          note = { ru = "К северо-западу от Гробницы: обжоры Лунной Ярости (6 кандалов) и темнодушные (3). "
                       .. "Темнодушные впадают в ярость ниже 25% здоровья — добивайте быстро.",
                   en = "North-west of the Sepulcher: Moonrage Gluttons (6 shackles) and Darksouls (3). "
                       .. "Darksouls enrage below 25% health: finish them fast." } },
        { turnin = 423, accept = 424, npc = 1938, at = { 1421, 44.20, 39.81 } },

        ------------------------------------------------------------------
        -- East and south loop: ferry, Grimson, Dalaran camp (level 14-15)
        ------------------------------------------------------------------
        { turnin = 438, accept = 439, object = 1593, at = { 1421, 58.44, 34.90 },
          note = { ru = "Старая переправа на восток: щёлкните по лодке у причала. Рядом ходят Руки Когтя "
                       .. "Ворона (15-16).",
                   en = "The old ferry to the east: click the boat at the dock. Hands of Ravenclaw (15-16) "
                       .. "walk nearby." } },
        { complete = 424, npc = 1972, at = { 1421, 58.58, 44.86 },
          note = { ru = "Гримсон Бледный (15) к югу от переправы: убейте и заберите голову.",
                   en = "Grimson the Pale (15) south of the ferry: kill him and loot his head." } },
        { turnin = 477, accept = 478, object = 1627, at = { 1421, 49.89, 60.33 },
          note = { ru = "Лагерь Даларана на юго-западе: откройте Даларанский ящик. Ученики кастуют ледяную "
                       .. "стрелу и убегают при малом здоровье. Назад в Гробницу по дороге на северо-запад "
                       .. "(или умрите и воскресните у целителя душ Гробницы).",
                   en = "Dalaran camp to the south-west: open the Dalaran Crate. Apprentices cast Frostbolt and "
                       .. "flee at low health. Back to the Sepulcher along the road north-west (or die and "
                       .. "resurrect at the Sepulcher spirit healer)." } },

        ------------------------------------------------------------------
        -- The Sepulcher, last visit (level 15)
        ------------------------------------------------------------------
        { turnin = 478, accept = 481, npc = 2121, at = { 1421, 43.98, 40.93 } },
        { turnin = { 424, 481 }, accept = 482, npc = 1938, at = { 1421, 44.20, 39.81 },
          note = { ru = "Следующее задание Далара (Пирвуд) не берите.",
                   en = "Do not take Dalar's next quest (Pyrewood)." } },
        { turnin = 482, npc = 2121, at = { 1421, 43.98, 40.93 },
          note = { ru = "Расследование в Янтарной мельнице не берите.", en = "Skip Ambermill Investigations." } },
        { turnin = 439, accept = 440, npc = 1952, at = { 1421, 43.42, 40.86 },
          note = { ru = "Кольцо Делии везите в Брилл.", en = "Deliah's Ring goes to Brill." } },

        ------------------------------------------------------------------
        -- Brill and the Undercity (level 15)
        ------------------------------------------------------------------
        { id = "ud03-hearth", hearth = "Brill", at = { 1420, 61.72, 52.05 },
          note = { ru = "Камень возвращения в Брилл. Если он ещё на откате — летите в Подгород у Кароса, а "
                       .. "Севрена посетите по пути к дирижаблю (задание 441 тогда пропустите).",
                   en = "Hearth to Brill. If it is still on cooldown, fly to the Undercity from Karos and visit "
                       .. "Sevren on the way to the zeppelin (then skip 441)." } },
        { turnin = 440, accept = 441, npc = 1499, at = { 1420, 61.26, 50.84 },
          note = { ru = "Мировой судья Севрен.", en = "Magistrate Sevren." } },
        { go = true, at = { 1420, 61.92, 64.85 },
          note = { ru = "Вход в Подгород через Руины Лордерона к югу от Брилла, лифт вниз.",
                   en = "Undercity entrance through the Ruins of Lordaeron south of Brill, take the lift down." } },
        { turnin = 6323, accept = 6322, npc = 4556, at = { 1458, 61.49, 41.79 },
          note = { ru = "Гордон Вендхэм в Торговом квартале.", en = "Gordon Wendham in the Trade Quarter." } },
        { turnin = 441, npc = 2050, at = { 1458, 62.01, 42.75 },
          note = { ru = "Рэли Андреан рядом. Продолжение не берите.", en = "Raleigh Andrean next to him. Skip the follow-up." } },
        { turnin = 6322, npc = 4551, at = { 1458, 63.25, 48.56 },
          note = { ru = "Майкл Гаррет. Задание обратно к Подригу не берите.",
                   en = "Michael Garrett. Do not take the one back to Podrig." } },
        { accept = 97891, npc = 7683, at = { 1458, 58.61, 54.68 },
          note = { ru = "Алессандро Лука: зелье на время — сразу бегите в Аптекарскую.",
                   en = "Alessandro Luca: a timed potion - run straight to the Apothecarium." } },
        { turnin = 97891, npc = 11044, at = { 1458, 46.61, 74.09 }, -- WARN-OK: xp-unknown, Forever-new
          note = { ru = "Доктор Мартин Фелбен в Аптекарской.", en = "Doctor Martin Felben in the Apothecarium." } },
        { turnin = 447, npc = 2055, at = { 1458, 48.82, 69.28 },
          note = { ru = "Главный аптекарь Фаранелл. Продолжение (в Пирвуд) не берите.",
                   en = "Master Apothecary Faranell. Skip the follow-up (Pyrewood)." } },
        { turnin = 1359, accept = 1358, npc = 5204, at = { 1458, 50.14, 67.97 }, -- 1358 is carried: Helbrim, Crossroads (ud-04)
          note = { ru = "Аптекарь Зинг. 1358 сдаётся в Перекрёстке — держите его.",
                   en = "Apothecary Zinge. 1358 is turned in at the Crossroads: keep it." } },
        { id = "ud03-train-14", train = true, npc = 260093, at = { 1458, 47.5, 15.0 },
          spells = { { ru = "Свет небес (ранг 3)", en = "Holy Light (Rank 3)" } },
          note = { ru = "Гарен Ларго в Квартале Воинов (нужен 14-й уровень; следующий тренер — только в "
                       .. "Громовом Утёсе на 18-м). Не выучили ранги 12-го в Брилле — возьмите их здесь же. "
                       .. "Нет 14-го — пропустите.",
                   en = "Garen Largo in the War Quarter (needs level 14; the next trainer is Thunder Bluff "
                       .. "at 18). Missed the level-12 ranks in Brill: train them here too. Not 14 yet: skip." } },

        ------------------------------------------------------------------
        -- Zeppelin to Durotar
        ------------------------------------------------------------------
        { go = true, at = { 1420, 61.92, 64.85 },
          note = { ru = "Выйдите из Подгорода на лифте.", en = "Leave the Undercity by the lift." } },
        { id = "ud03-zeppelin", go = true, radius = 15, npc = 9566, at = { 1420, 60.74, 58.87 },
          note = { ru = "Башня дирижаблей к северу от Руин. Садитесь на дирижабль до Оргриммара (у Запоты), "
                       .. "а не до Гром'гола.",
                   en = "Zeppelin tower north of the Ruins. Board the zeppelin to Orgrimmar (Zapetta's side), "
                       .. "not the one to Grom'gol." } },
        { id = "ud03-end", go = true, radius = 40, npc = 9564, at = { 1411, 50.82, 13.54 },
          note = { ru = "Прибытие к башне дирижаблей в Дуротаре, у Оргриммара (Фрезза).",
                   en = "Arrival at the Durotar zeppelin tower outside Orgrimmar (Frezza)." } },
    },
})
