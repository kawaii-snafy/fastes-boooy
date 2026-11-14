-- FastesBoooy_Guides / Segments / Shared / 13_Silverpine.lua
--
-- Segment "h-13-silverpine": levels 13-15, all races. Silverpine road -> the Ivar Patch -> The Sepulcher (five
-- visits) -> back to the Undercity (turn-ins) -> Durotar / Orgrimmar. Order of the former Undead segment
-- ud-03-silverpine (it saves the third trip north); 23 quests: 435, 429, 449, 421, 477, 437, 3221, 445 (turn-in),
-- 430, 447, 1359, 422, 91920, 425, 423, 438, 424, 439, 478, 481, 482, 97891, 1358 (accept).
-- Coordinates: Forever uiMap 1421 (Silverpine Forest) / 1420 (Tirisfal Glades) / 1458 (Undercity) / 1411
-- (Durotar), map percent, from tools/data/forever_db.lua (NPC / object spawns; centroids of the objective mob
-- spawns of the chosen area for complete steps). Zeppelin masters: Zapetta 9566 (Tirisfal 60.74,58.87), Frezza
-- 9564 (Durotar 50.82,13.54).
-- 429 Wild Hearts needs 3 hearts in Forever (Wowhead Forever tooltip; the DB snapshot still says 6 from the
-- Classic text, so the validator's kill XP for it is a little high).
--
-- Start state: on the Silverpine road (the Undead on foot from the Undercity; the others from h-12-orgrimmar-
-- tirisfal through the Sewers); 445 in the log; hearth Brill (Undead) or Orgrimmar (the others); flight point
-- Undercity.
-- Hub plan (Sepulcher NPCs all within ~60 yd of 44,41):
--   T1 Ivar Patch: 435 escort > 449 + 429 (Rane Yorick), worg hearts, 3 Murloc Eyes in advance for 91920.
--      Gate h13-lvl-12 (421 needs 12).
--   V1 Sepulcher: 421 (Dalar), 477 (Allister), 449 > 3221 + 437 (Hadrec), 445/3221/429 > 1359/447/430
--      (Renferrel), flight point.
--   L1 whitescalps (421) east of the Sepulcher, bears (447) all segment. V2: 421 > 422.
--   T2 north: Dusty Spellbooks (422) > Quinn 430 > 91920 > Rane 425 > Ivar the Foul > Rane > Dead Field (437
--      Nightlash) > spiders (447 blood) > bears > back. V3: 422 > 423, 437 > 438, 91920.
--   T3 west: Moonrage Glutton / Darksoul shackles (423). V4: 423 > 424.
--   L4 east / south: ferry boat (438 > 439), Grimson the Pale (424), Dalaran Crate (477 > 478), back.
--   V5: 478 > 481 > 482, 424, 439. Gate h13-lvl-14 (13 + 92 %: level 14 after the Undercity turn-ins, for the
--      trainers in the Undercity and Orgrimmar; the next trainer city is at 18). It points at the gluttons and
--      darksouls of T3 (12-14, same level), not at the whitescalps of L1 (10-11: 60-75 XP a kill at 13 against 110).
--   Way back: the Undead hearth to Brill (439 > 440 > 441, Sevren) and walk into the Undercity; the others fly
--      from the Sepulcher. Join: h13-uc-arrive.
--   UC: 97891 (timed), 447, 1359 > 1358. Exit: the Undead take the lift and the zeppelin to Durotar, the others
--      hearth to Orgrimmar. Join: h15-org (first unfiltered step of h-15-barrens).
-- Race-filtered alternatives (each exists only in the routes of its races; class and race inserts anchor on the
-- unfiltered join steps): h13-hadrec-440, h13-hearth-brill, h13-sevren, h13-raleigh, h13-uc-lift, h13-zeppelin,
--   h13-durotar (Scourge) / h13-fly-uc, h13-hearth-org (Orc, Skyborne, Tauren, Troll).
-- Additions by other files: Races/Scourge.lua (6321 > 6323 > 6322, race-locked in the DB; until the Tirisfal
--   segments end on the Silverpine road also the walk out of the Undercity); class files (training in the
--   Undercity after h13-uc-end; the druid's Moonglade visit before h13-hearth-org).
-- Anchors (never renamed): h13-erland, h13-lvl-12, h13-fp-sepulcher, h13-sepulcher-5, h13-lvl-14,
--   h13-hearth-brill, h13-fly-uc, h13-uc-arrive, h13-uc-end, h13-zeppelin, h13-hearth-org.
-- Skipped: 91921 (a third trip north for one Forever-new delivery), 428 (breadcrumb for 429, Rane is met
--   first), 6324 (back to the Sepulcher), 99 / 450 / 452 / 98298 (south Silverpine: Pyrewood, Ambermill), 479
--   (Ambermill, 16), 443 (Rot Hide gnolls 16-19), 92401 / 5725 (dungeons), 530 (Raleigh follow-up).
-- Carried into the next segment: 1358 Sample for Helbrim (Apothecary Helbrim, Crossroads).
--
-- Automation note: every trainer / flight-master transient step comes AFTER the quest steps at that NPC; no step
-- accepts a quest from an NPC on both sides of a transient step.
if not FastesBoooy.AddLibraryInsert then return end
FastesBoooy.AddLibrarySegment({
    id = "h-13-silverpine",
    title = { ru = "13-15 Серебряный бор", en = "13-15 Silverpine Forest" },
    zone = "Silverpine Forest",
    levels = { 13, 15 },
    steps = {

        ------------------------------------------------------------------
        -- The Ivar Patch, first visit (level 12-13)
        ------------------------------------------------------------------
        { id = "h13-erland", accept = 435, npc = 1978, at = { 1421, 56.18, 9.18 },
          note = { ru = "Следопыт Эрланд в доме у дороги. Нет на месте (его уже ведёт другой игрок) — подождите "
                       .. "1-2 минуты, убивая воргов рядом.",
                   en = "Deathstalker Erland in the house by the road. Not there (another player is escorting "
                       .. "him): wait 1-2 minutes killing worgs nearby." } },
        { id = "h13-escort", complete = 435, at = { 1421, 53.6, 13.2 },
          note = { ru = "Сопровождение: идите с Эрландом к Рейну Йорику на ферму Ивара. По пути нападают ворги.",
                   en = "Escort: walk Erland to Rane Yorick at the Ivar Patch. Worgs attack on the way." } },
        { id = "h13-rane", turnin = 435, accept = { 429, 449 }, npc = 1950, at = { 1421, 53.46, 13.43 },
          note = { ru = "Рейн Йорик.",
                   en = "Rane Yorick." } },
        { id = "h13-murloc-eyes", collect = { [730] = 3 }, bg = true, at = { 1421, 60.0, 15.5 },
          note = { ru = "Попутно: 3 глаза мурлока с мурлоков Гиблого Плавника к востоку от фермы. Они нужны "
                       .. "для задания Куинна позже — не продавайте.",
                   en = "Along the way: 3 Murloc Eyes from the Vile Fin murlocs east of the farm. Quinn's later "
                       .. "quest needs them: do not sell." } },
        { id = "h13-worg-hearts", complete = 429, at = { 1421, 58.0, 11.5 },
          note = { ru = "Пятнистые ворги и ворги вокруг фермы: 3 бесцветных сердца. Редкий Кровавый Клык "
                       .. "бродит к северо-востоку.",
                   en = "Mottled Worgs and Worgs around the farm: 3 Discolored Worg Hearts. Gorefang (rare) "
                       .. "roams to the north-east." } },
        -- Requirement gate: 421 Prove Your Worth (Dalar, the next quest hub) needs level 12.
        { id = "h13-lvl-12", level = 12, at = { 1421, 58.0, 11.5 },
          note = { ru = "Заданию Далара в Гробнице нужен 12-й уровень. Не хватает - добейте воргов у фермы и по дороге на юг.",
                   en = "Dalar's quest at the Sepulcher needs level 12. Short of it: kill more worgs around the farm and along the "
                       .. "road south." } },
        { id = "h13-go-sepulcher", go = true, at = { 1421, 49.8, 31.0 },
          note = { ru = "По дороге на юг к Гробнице, убивая воргов по пути.",
                   en = "South along the road to the Sepulcher, killing worgs on the way." } },

        ------------------------------------------------------------------
        -- The Sepulcher, first visit (level 13)
        ------------------------------------------------------------------
        { id = "h13-dalar", accept = 421, npc = 1938, at = { 1421, 44.20, 39.81 },
          note = { ru = "Далар Ткач Зари у входа в Гробницу (нужен 12-й уровень).",
                   en = "Dalar Dawnweaver at the Sepulcher entrance (needs level 12)." } },
        { id = "h13-vendor", vendor = true, npc = 2140, optional = true, at = { 1421, 43.98, 39.90 },
          note = { ru = "Эдвин Харли рядом: продайте серый хлам, купите воду.",
                   en = "Edwin Harly next to him: sell grey loot, buy water." } },
        { id = "h13-allister", accept = 477, npc = 2121, at = { 1421, 43.98, 40.93 },
          note = { ru = "Тёмный жрец Аллистер.", en = "Shadow Priest Allister." } },
        { id = "h13-hadrec", turnin = 449, accept = { 3221, 437 }, npc = 1952, at = { 1421, 43.42, 40.86 },
          note = { ru = "Верховный палач Хадрек внизу, в склепе.", en = "High Executor Hadrec down in the crypt." } },
        { id = "h13-renferrel", turnin = { 445, 3221, 429 }, accept = { 1359, 447, 430 }, npc = 1937, at = { 1421, 42.80, 40.86 },
          note = { ru = "Аптекарь Ренферрел в склепе.", en = "Apothecary Renferrel in the crypt." } },
        { id = "h13-fp-sepulcher", fp = "The Sepulcher", npc = 2226, at = { 1421, 45.62, 42.60 },
          note = { ru = "Карос Разок, распорядитель летучих мышей: откройте карту полётов, чтобы узнать точку.",
                   en = "Karos Razok, the bat handler: open the flight map to learn the path." } },

        ------------------------------------------------------------------
        -- East of the Sepulcher: whitescalps (level 13)
        ------------------------------------------------------------------
        { id = "h13-bear-hearts", complete = 447, bg = true, at = { 1421, 49.2, 33.0 },
          note = { ru = "Весь сегмент попутно: сердца серых медведей (6) — медведи повсюду вдоль дороги.",
                   en = "All segment along the way: Grizzled Bear Hearts (6) - bears are all along the road." } },
        { id = "h13-whitescalps", complete = 421, at = { 1421, 50.5, 39.0 },
          note = { ru = "Белогривые воргены Лунной Ярости (5) к востоку от Гробницы. Сын Аругала (элита, 24) "
                       .. "иногда бродит здесь — уходите от него.",
                   en = "Moonrage Whitescalps (5) east of the Sepulcher. Son of Arugal (elite, 24) sometimes "
                       .. "roams here: stay away." } },
        { id = "h13-dalar-2", turnin = 421, accept = 422, npc = 1938, at = { 1421, 44.20, 39.81 } },

        ------------------------------------------------------------------
        -- North loop: spellbooks, Ivar Patch, Dead Field, spiders (level 13-14)
        ------------------------------------------------------------------
        { id = "h13-spellbooks", complete = 422, object = 1571, at = { 1421, 52.83, 28.58 },
          note = { ru = "Дом у дороги на север: на втором этаже Пыльные книги заклинаний (Снадобье Аругала).",
                   en = "House by the north road: the Dusty Spellbooks on the second floor (Remedy of Arugal)." } },
        { id = "h13-quinn", turnin = 430, accept = 91920, npc = 1951, at = { 1421, 53.43, 12.59 },
          note = { ru = "Куинн Йорик на втором этаже дома на ферме Ивара. Глаза мурлока уже в сумке — задание "
                       .. "сразу выполнено.",
                   en = "Quinn Yorick upstairs in the Ivar Patch house. The Murloc Eyes are already in your bags: "
                       .. "the quest is done at once." } },
        { id = "h13-rane-425", accept = 425, npc = 1950, at = { 1421, 53.46, 13.43 } },
        { id = "h13-ivar", complete = 425, npc = 1971, at = { 1421, 51.52, 13.90 },
          note = { ru = "Ивар Мерзкий (13) в сарае к западу, с ним два раба Когтя Ворона. Выманивайте по одному.",
                   en = "Ivar the Foul (13) in the barn to the west with two Ravenclaw Slaves. Pull them one "
                       .. "at a time." } },
        { id = "h13-rane-425-done", turnin = 425, npc = 1950, at = { 1421, 53.46, 13.43 },
          note = { ru = "Награда: Потёртый пояс (кожа).", en = "Reward: Weathered Belt (leather)." } },
        { id = "h13-wild-eyes", complete = 91920, at = { 1421, 60.0, 15.5 },
          note = { ru = "Меньше 3 глаз мурлока? Мурлоки Гиблого Плавника к востоку от фермы.",
                   en = "Fewer than 3 Murloc Eyes? Vile Fin murlocs east of the farm." } },
        { id = "h13-dead-field", complete = 437, npc = 1983, at = { 1421, 44.67, 20.67 },
          note = { ru = "Мёртвое поле: убивайте гноллов Гнилошкуры, пока не появится Ночная Плеть (14). Убейте "
                       .. "её и заберите сущность. Медведи рядом — для сердец.",
                   en = "The Dead Field: kill Rot Hide gnolls until Nightlash (14) appears. Kill her and loot "
                       .. "her essence. Bears nearby for the hearts." } },
        { id = "h13-spiders", complete = { [447] = { 2 } }, at = { 1421, 35.3, 12.5 },
          note = { ru = "Пауки на северо-западе (мшистые охотники и туманные ползуны): 6 проб крови. Редкая "
                       .. "Кретис Тенепряд (15) ставит щит — обходите её.",
                   en = "Spiders to the north-west (Moss Stalkers and Mist Creepers): 6 Skittering Blood. "
                       .. "Krethis Shadowspinner (rare, 15) shields herself: avoid her." } },
        { id = "h13-bears", complete = 447, at = { 1421, 40.4, 17.4 },
          note = { ru = "Доберите сердца с гигантских серых медведей и возвращайтесь в Гробницу на юг.",
                   en = "Finish the hearts on Giant Grizzled Bears, then head south back to the Sepulcher." } },

        ------------------------------------------------------------------
        -- The Sepulcher, third visit (level 14)
        ------------------------------------------------------------------
        { id = "h13-dalar-3", turnin = 422, accept = 423, npc = 1938, at = { 1421, 44.20, 39.81 } },
        { id = "h13-vendor-2", vendor = true, npc = 2140, optional = true, at = { 1421, 43.98, 39.90 },
          note = { ru = "Продайте хлам у Эдвина Харли, купите воду.", en = "Sell junk to Edwin Harly, buy water." } },
        { id = "h13-hadrec-2", turnin = 437, accept = 438, npc = 1952, at = { 1421, 43.42, 40.86 },
          note = { ru = "Награда: Сапоги разведчика.", en = "Reward: Reconnaissance Boots." } },
        { id = "h13-renferrel-2", turnin = 91920, npc = 1937, at = { 1421, 42.80, 40.86 },
          note = { ru = "Следующее задание (снова к Куинну на север) не берите.",
                   en = "Do not take the follow-up (back north to Quinn)." } },

        ------------------------------------------------------------------
        -- West of the road: shackles (level 14)
        ------------------------------------------------------------------
        { id = "h13-shackles", complete = 423, at = { 1421, 41.5, 28.0 },
          note = { ru = "К северо-западу от Гробницы: обжоры Лунной Ярости (6 кандалов) и темнодушные (3). "
                       .. "Темнодушные впадают в ярость ниже 25% здоровья — добивайте быстро.",
                   en = "North-west of the Sepulcher: Moonrage Gluttons (6 shackles) and Darksouls (3). "
                       .. "Darksouls enrage below 25% health: finish them fast." } },
        { id = "h13-dalar-4", turnin = 423, accept = 424, npc = 1938, at = { 1421, 44.20, 39.81 } },

        ------------------------------------------------------------------
        -- East and south loop: ferry, Grimson, Dalaran camp (level 14-15)
        ------------------------------------------------------------------
        { id = "h13-ferry", turnin = 438, accept = 439, object = 1593, at = { 1421, 58.44, 34.90 },
          note = { ru = "Старая переправа на восток: щёлкните по лодке у причала. Рядом ходят Руки Когтя "
                       .. "Ворона (15-16).",
                   en = "The old ferry to the east: click the boat at the dock. Hands of Ravenclaw (15-16) "
                       .. "walk nearby." } },
        { id = "h13-grimson", complete = 424, npc = 1972, at = { 1421, 58.58, 44.86 },
          note = { ru = "Гримсон Бледный (15) к югу от переправы: убейте и заберите голову.",
                   en = "Grimson the Pale (15) south of the ferry: kill him and loot his head." } },
        { id = "h13-dalaran-crate", turnin = 477, accept = 478, object = 1627, at = { 1421, 49.89, 60.33 },
          note = { ru = "Лагерь Даларана на юго-западе: откройте Даларанский ящик. Ученики кастуют ледяную "
                       .. "стрелу и убегают при малом здоровье. Назад в Гробницу по дороге на северо-запад "
                       .. "(или умрите и воскресните у целителя душ Гробницы).",
                   en = "Dalaran camp to the south-west: open the Dalaran Crate. Apprentices cast Frostbolt and "
                       .. "flee at low health. Back to the Sepulcher along the road north-west (or die and "
                       .. "resurrect at the Sepulcher spirit healer)." } },

        ------------------------------------------------------------------
        -- The Sepulcher, last visit (level 14-15)
        ------------------------------------------------------------------
        { id = "h13-allister-2", turnin = 478, accept = 481, npc = 2121, at = { 1421, 43.98, 40.93 } },
        { id = "h13-dalar-5", turnin = { 424, 481 }, accept = 482, npc = 1938, at = { 1421, 44.20, 39.81 },
          note = { ru = "Следующее задание Далара (Пирвуд) не берите.",
                   en = "Do not take Dalar's next quest (Pyrewood)." } },
        { id = "h13-allister-3", turnin = 482, npc = 2121, at = { 1421, 43.98, 40.93 },
          note = { ru = "Расследование в Янтарной мельнице не берите.", en = "Skip Ambermill Investigations." } },
        { id = "h13-sepulcher-5", turnin = 439, npc = 1952, at = { 1421, 43.42, 40.86 },
          note = { ru = "Верховный палач Хадрек.",
                   en = "High Executor Hadrec." } },
        -- 440 > 441 ends in Brill and the Undercity: only for the race whose hearthstone is bound in Brill.
        { id = "h13-hadrec-440", race = "Scourge", accept = 440, npc = 1952, at = { 1421, 43.42, 40.86 },
          note = { ru = "Хадрек: «Кольцо с гравировкой» - кольцо Делии везите в Брилл (камень возвращения привязан там).",
                   en = "Hadrec: The Engraved Ring - Deliah's Ring goes to Brill (your hearthstone is bound there)." } },
        -- Trainer-hub gate (docs/dev/PLAN.md B.8): the Undercity and Orgrimmar follow, the next trainer city after
        -- them is Thunder Bluff at 18. 13 + 92 %: the Undercity turn-ins of every race (447 900 + 1359 110 XP, both
        -- known values) are 8.9 % of the 11400 XP of level 13, so the level is 14.0 at h13-uc-end, the training
        -- anchor. The estimated 97891 and the race-only quests are not counted.
        -- `at`: the centroid of the 8 Moonrage Glutton (12-13) and 7 Moonrage Darksoul (13-14) spawns within 350 yd of
        -- Dalar, 255 yd north-west of him: the nearest mobs of the player's level (the validator counts same-level
        -- kills). The Moonrage Whitescalps east of the Sepulcher are as close but 10-11: 60-75 XP a kill at 13 against
        -- 92-115, so the count would be 1.5-1.8 times higher on them.
        { id = "h13-lvl-14", level = { 13, 0.92 }, at = { 1421, 43.3, 30.8 },
          note = { ru = "Проверка перед Подгородом: сдачи там дадут ещё ~9% уровня - это 14-й и новые ранги у тренеров в Подгороде и "
                       .. "Оргриммаре (следующий город с тренерами - только на 18-м). Нет 13-го + 92% - обжоры и темнодушные Лунной "
                       .. "Ярости (12-14) к северо-западу от Гробницы, там же, где собирали кандалы. Белогривых (10-11) не бейте: "
                       .. "опыта с них почти вдвое меньше.",
                   en = "Check before the Undercity: the turn-ins there add ~9% of a level, which makes 14 and new ranks at the "
                       .. "trainers in the Undercity and Orgrimmar (the next city with trainers comes at 18). Short of 13 + 92%: the "
                       .. "Moonrage Gluttons and Darksouls (12-14) north-west of the Sepulcher, where you collected the shackles. "
                       .. "Leave the Whitescalps (10-11) alone: they give about half the XP." } },

        ------------------------------------------------------------------
        -- Back to the Undercity (level 14-15)
        ------------------------------------------------------------------
        -- Alternative pair: the Undead hearth to Brill and walk in, the others fly. Join: h13-uc-arrive.
        { id = "h13-hearth-brill", race = "Scourge", hearth = "Brill", at = { 1420, 61.72, 52.05 },
          note = { ru = "Камень возвращения в Брилл. Если он ещё на откате — летите в Подгород у Кароса, а "
                       .. "Севрена посетите по пути к дирижаблю (задание 441 тогда пропустите).",
                   en = "Hearth to Brill. If it is still on cooldown, fly to the Undercity from Karos and visit "
                       .. "Sevren on the way to the zeppelin (then skip 441)." } },
        { id = "h13-sevren", race = "Scourge", turnin = 440, accept = 441, npc = 1499, at = { 1420, 61.26, 50.84 },
          note = { ru = "Мировой судья Севрен.", en = "Magistrate Sevren." } },
        { id = "h13-fly-uc", race = { "Orc", "Skyborne", "Tauren", "Troll" }, fly = "Undercity", npc = 4551, at = { 1458, 63.25, 48.56 },
          note = { ru = "Карос Разок: летите в Подгород.",
                   en = "Karos Razok: fly to the Undercity." } },
        { id = "h13-uc-arrive", go = true, radius = 30, at = { 1458, 63.25, 48.56 },
          note = { ru = "Подгород, Торговый квартал (кольцо у распорядителя полётов Майкла Гаррета). Из Брилла - через Руины "
                       .. "Лордерона к югу и на лифте вниз.",
                   en = "The Undercity, Trade Quarter (the ring around flight master Michael Garrett). From Brill: through the Ruins "
                       .. "of Lordaeron to the south and down the lift." } },
        { id = "h13-raleigh", race = "Scourge", turnin = 441, npc = 2050, at = { 1458, 62.01, 42.75 },
          note = { ru = "Рэли Андреан в Торговом квартале. Продолжение не берите.",
                   en = "Raleigh Andrean in the Trade Quarter. Skip the follow-up." } },
        { id = "h13-luca", accept = 97891, npc = 7683, at = { 1458, 58.61, 54.68 },
          note = { ru = "Алессандро Лука: зелье на время — сразу бегите в Аптекарскую.",
                   en = "Alessandro Luca: a timed potion - run straight to the Apothecarium." } },
        { id = "h13-felben", turnin = 97891, npc = 11044, at = { 1458, 46.61, 74.09 },
          note = { ru = "Доктор Мартин Фелбен в Аптекарской.", en = "Doctor Martin Felben in the Apothecarium." } },
        { id = "h13-faranell", turnin = 447, npc = 2055, at = { 1458, 48.82, 69.28 },
          note = { ru = "Главный аптекарь Фаранелл. Продолжение (в Пирвуд) не берите.",
                   en = "Master Apothecary Faranell. Skip the follow-up (Pyrewood)." } },
        -- 1358 is carried: Helbrim, Crossroads (h-15-barrens)
        { id = "h13-uc-end", turnin = 1359, accept = 1358, npc = 5204, at = { 1458, 50.14, 67.97 },
          note = { ru = "Аптекарь Зинг. 1358 сдаётся в Перекрёстке — держите его.",
                   en = "Apothecary Zinge. 1358 is turned in at the Crossroads: keep it." } },

        ------------------------------------------------------------------
        -- To Durotar / Orgrimmar
        ------------------------------------------------------------------
        -- Alternative pair: the Undead (hearthstone in Brill) take the zeppelin, the others hearth to Orgrimmar.
        -- Join: h15-org, the first unfiltered step of h-15-barrens.
        { id = "h13-uc-lift", race = "Scourge", go = true, at = { 1420, 61.92, 64.85 },
          note = { ru = "Выйдите из Подгорода на лифте.", en = "Leave the Undercity by the lift." } },
        { id = "h13-zeppelin", race = "Scourge", go = true, radius = 15, npc = 9566, at = { 1420, 60.74, 58.87 },
          note = { ru = "Башня дирижаблей к северу от Руин. Садитесь на дирижабль до Оргриммара (у Запетты), "
                       .. "а не до Гром'гола.",
                   en = "Zeppelin tower north of the Ruins. Board the zeppelin to Orgrimmar (Zapetta's side), "
                       .. "not the one to Grom'gol." } },
        { id = "h13-durotar", race = "Scourge", go = true, radius = 40, npc = 9564, at = { 1411, 50.82, 13.54 },
          note = { ru = "Прибытие к башне дирижаблей в Дуротаре, у Оргриммара (Фрезза).",
                   en = "Arrival at the Durotar zeppelin tower outside Orgrimmar (Frezza)." } },
        { id = "h13-hearth-org", race = { "Orc", "Skyborne", "Tauren", "Troll" }, hearth = "Orgrimmar", at = { 1454, 54.10, 68.41 },
          note = { ru = "Камень возвращения в Оргриммар (привязан там перед дирижаблем).",
                   en = "Hearth to Orgrimmar (bound there before the zeppelin)." } },
    },
})
