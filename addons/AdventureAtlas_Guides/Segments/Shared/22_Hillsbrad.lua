-- AdventureAtlas_Guides / Segments / Shared / 22_Hillsbrad.lua
--
-- Segment "h-22-hillsbrad": levels 22-24, all races and classes.
-- Thunder Bluff (1065) -> fly Orgrimmar -> zeppelin -> Undercity -> fly The Sepulcher
-- (493; optional Ruins of Lordaeron / Shadowfang Keep with a group) -> south through Silverpine (Offering Stone
-- pair at Beren's Peril) -> Deathstalker Lesh (494) -> Tarren Mill -> four Hillsbrad loops -> hearth to Thunder Bluff.
-- Plan: research plan60.md section 4.1 / plan60.json segments[1] (anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1456 (Thunder Bluff) / 1413 (The Barrens) / 1454 (Orgrimmar) / 1411 (Durotar) /
-- 1420 (Tirisfal Glades) / 1458 (Undercity) / 1421 (Silverpine Forest) / 1424 (Hillsbrad Foothills), map percent,
-- from tools/data/forever_db.lua (NPC / object spawns; centroids of the objective mob spawns of the area used for
-- complete steps). Silverpine path points and the Orgrimmar gate / Far Watch Post are reference / route facts.
--
-- Start state (end of h-18-stonetalon-ashenvale, the same for every race): in Thunder Bluff at Zamah, 1064 turned
--   in, hearth Thunder Bluff, flight points Thunder Bluff, Orgrimmar, Undercity, The Sepulcher and the Barrens /
--   Stonetalon / Ashenvale ones.
-- Hub plan (Forever DB; no quest of the segment is limited to a race or class):
--   TB  : 1065 Zamah (h-22-tb-start, right after the turn-in of 1064 at her).
--   Org : fly Thunder Bluff -> Orgrimmar (every race knows the point since level 12-14; h-22-org-fp is kept as a
--         click on Doras). Zeppelin to Tirisfal (h-22-uc-arrive), fly to The Sepulcher.
--   RoL : optional, group: Ruins of Lordaeron (Forever-new dungeon 15-22, entrance Undercity 72.48,11.33, quests
--         ~2.2x Classic XP): 92421 (Morbin Lightbane), 95216 (Theodore Griffs), item-started 95204 (Crest of
--         Lordaeron) + 97288 (Abominable Head, from the Baron); turn-ins at Faranell / Theodore / Morbin / Oran
--         Snakewrithe; optional 1013 The Book of Ur (Bel'dugur) for Shadowfang Keep. Skipped: 92422 (Kristof, XP
--         unknown, a Tirisfal detour after the run), 92401 (giver at the Sepulcher, reached only after the run),
--         97289-97292 (Faranell's follow-ups: order and items unclear in the data).
--   SP  : 493 (Renferrel); optional, group: Shadowfang Keep (20-30, entrance 44.8,67.8, ~2.7x Classic XP): 1098
--         (Hadrec; Vincent inside) + 1014 (Dalar: back to the Sepulcher) + 1013 (Book of Ur, turned in at the
--         Undercity in h-31); Forever-new 95883 -> 95885 at the Offering Stone of Beren's Peril (XP unknown, 150 yd
--         off the road: on the path, so not optional any more); 494 (Lesh, Hillsbrad west).
--   TM1 : fp; 1065 + 493 > 496, 501, 1066 (Lydon); 494 > 527 (Darthalia); 549 + 567 (posters); 498
--         (Krusk).
--   F1  : Hillsbrad Fields: 527 (farmers, farmhands, Ray, Getz). bg all the time: 496 (bears + 1 creeper ichor),
--         501 (Starving Mountain Lions), 567 Wilkes + Kalaba.
--   TM2 : 527 > 528 (Darthalia); 546 (Samsa).
--   D   : Durnholde Keep: 549 + 1066 (Syndicate), 498 (jailor keys, Drull, Tog'thar); the Syndicate also drop
--         546 skulls (that is why Durnholde comes after TM2, not before F1: same distance, ~20 fewer skull kills).
--   F2  : 528 (15 peasants) + skulls.
--   TM3 : 496 > 499 (> Umpi), 501 > 502, 1066 > 1067 (Lydon); 528 + 549 > 529 + 98094 (Darthalia, 98094
--         needs 528); 498 (Krusk).
--   F3  : 502 Stanley (kill Enraged Stanley), 529 (smithy), rest of the skulls, level gate;
--         then east to Deathstalker Masoj (98094, optional) and north to Tarren Mill.
--   TM4 : 546 (Samsa); 529 > 532 (Darthalia); hearth Thunder Bluff.
-- Carried out: 1067 (h-24, Zamah), 532 (h-31, Magistrate Burnside L30), 567 with objectives 2+4 done
--   (h-31: Clerk Horrace stands next to Burnside in the town hall, Miner Hackett L29 is in Azurelode Mine next
--   to the 539 miners; both are too dangerous at 23-24).
-- Skipped: 98095 Valuable Vantages (Masoj: three vials on Hillsbrad peaks - the peak positions are not in any
--   offline data, XP unknown), 509 (needs 24, done in h-31), 516 Beren's Peril and Forever-new 95981 / 98299
--   (Silverpine: turn-ins back at the Sepulcher, a second trip north), 541 / 547 (Dun Garok: every mob is elite),
--   7321 (needs Cooking), the Owen Thadd library books (78127, 79096, ...: WCLBox 0 XP).
-- Optional dungeon blocks: nothing later depends on them (the 1013 turn-in in h-31 is optional as well). The
--   validator counts optional steps as done; its worst case (tools/README.md section 5) leaves them out.
-- Automation notes: accepts at one NPC sit in one step; transient steps (fp, fly, go) come before the quest steps
--   of the same place. 496 / 501 (bears, lions) and 567 (Wilkes, Kalaba) are bg-only until their turn-in steps:
--   they can finish on any loop, and a non-bg `complete` that is done early would make the engine fast-forward
--   the transient steps behind it. The 546 skulls are a bg goal until the level gate, which shares its step
--   with them (an anchor only when both are done).
-- Hearthstone: Thunder Bluff (bound in h-18), used from Tarren Mill at the end.
-- Every step has an explicit id (docs/dev/PLAN.md B.7): no step of this segment may be an anchor by position.
if not AdventureAtlas.AddLibraryInsert then return end
AdventureAtlas.AddLibrarySegment({
    id = "h-22-hillsbrad",
    title = { ru = "22-24 Предгорья Хилсбрада (Мельница Таррен)", en = "22-24 Hillsbrad Foothills (Tarren Mill)" },
    zone = "Hillsbrad Foothills",
    -- segment-level: the planned end is 24 (the gate h-22-hillsbrad-level-gate makes 24.0 for Thunder Bluff in
    -- the worst case); with every optional step counted the two class routes end just above 25: undead-paladin
    -- 25.10 (the optional paladin chain pal-22-*, estimated XP), skyborne-druid 25.12 (it enters at 22.44). A base
    -- profile (no class steps) ends at 24.82, inside the tolerance.
    -- Scope: the key has no ceiling and no route filter, so it accepts a segment-level WARN of this segment on
    -- every route that contains it, in either direction. When the base routes exist (phases F2c, P1), read the
    -- end level of every route in the report and keep, drop or replace the key (docs/dev/handover/F2a, F2b).
    ok = "segment-level",
    levels = { 22, 24 },
    steps = {
        ------------------------------------------------------------------
        -- Thunder Bluff -> Orgrimmar (level 22)
        ------------------------------------------------------------------
        { id = "h-22-tb-start", accept = 1065, npc = 3419, at = { 1456, 22.81, 20.89 },
          note = { ru = "Аптекарь Зама в Прудах Видений (под Вершиной Духов): «Путешествие к Мельнице Таррен».",
                   en = "Apothecary Zamah in the Pools of Vision (below Spirit Rise): Journey to Tarren Mill." } },
        { id = "h-22-tb-fly", go = true, radius = 10, npc = 2995, at = { 1456, 47.00, 49.83 },
          note = { ru = "Наверх на Вершину Духов, по мосту на центральную вершину: распорядитель ветрокрылов Тал.",
                   en = "Up to Spirit Rise and over the bridge to the central mesa: wind rider master Tal." } },
        { id = "h-22-tb-fly-org", fly = "Orgrimmar", npc = 3310, at = { 1454, 45.12, 63.89 },
          note = { ru = "Летите в Оргриммар. Нет его на карте полётов — летите на Перекрёсток и бегите на северо-восток "
                       .. "через Заставу Дальнего Дозора (+5 мин).",
                   en = "Fly to Orgrimmar. Not on your flight map: fly to The Crossroads and run north-east via Far "
                       .. "Watch Post (+5 min)." } },
        { id = "h-22-org-fp", fp = "Orgrimmar", npc = 3310, at = { 1454, 45.12, 63.89 },
          note = { ru = "Дорас на башне в Долине Силы: откройте карту полётов (точка понадобится дальше). Уже есть — "
                       .. "просто кликните его после посадки.",
                   en = "Doras on the tower in the Valley of Strength: open the flight map (the point is used later). "
                       .. "Already known: just click him after landing." } },
        { id = "h-22-zeppelin-uc", go = true, radius = 15, npc = 9564, at = { 1411, 50.82, 13.54 },
          note = { ru = "Через главные ворота наружу и на восток к башне дирижаблей: площадка Фреззы, дирижабль до "
                       .. "Тирисфальских лесов (Подгород).",
                   en = "Out through the main gate and east to the zeppelin tower: Frezza's platform, the zeppelin to "
                       .. "Tirisfal Glades (Undercity)." } },

        ------------------------------------------------------------------
        -- Undercity -> The Sepulcher -> Hillsbrad (level 22)
        ------------------------------------------------------------------
        { id = "h-22-uc-arrive", go = true, radius = 40, npc = 9566, at = { 1420, 60.74, 58.87 },
          note = { ru = "Прибытие к башне в Тирисфальских лесах (Запетта).",
                   en = "Arrival at the Tirisfal Glades tower (Zapetta)." } },
        -- Optional, group: Ruins of Lordaeron (Forever-new dungeon 15-22 above the Undercity; quests ~2.2x Classic XP).
        { id = "h22-rol-morbin", accept = 92421, npc = 266484, at = { 1458, 58.08, 89.51 }, optional = true,
          note = { ru = "Если собрали группу: Руины Лордерона (новое подземелье 15-22, ~19 тыс. опыта за 4 задания, ~40 мин). "
                       .. "Морбин Погибель Света в Королевском квартале: «Правосудие Света». Без группы — «Вперёд» на этих "
                       .. "семи шагах.",
                   en = "If you have a group: Ruins of Lordaeron (new dungeon 15-22, ~19k XP for 4 quests, ~40 min). Morbin "
                       .. "Lightbane in the Royal Quarter: Light's Justice. No group: press Forward on these seven steps." } },
        { id = "h22-rol-griffs", accept = 95216, npc = 11835, at = { 1458, 46.31, 71.91 }, optional = true,
          note = { ru = "Квартал аптекарей: Теодор Гриффс — «Новая чума».",
                   en = "The Apothecarium: Theodore Griffs - The New Plague." } },
        { id = "h22-rol-dungeon", complete = { 92421, 95216 }, at = { 1458, 72.48, 11.33 }, optional = true,
          note = { ru = "Наверх, в руины над городом: вход в подземелье. Внутри — 25 сохранившихся конечностей и штамм с "
                       .. "Сухожвала. Подберите герб Лордерона и чудовищную голову с Барона — они начинают задания.",
                   en = "Up to the ruins above the city: the dungeon entrance. Inside: 25 Intact Limbs and the strain from "
                       .. "Witherfang. Loot the Crest of Lordaeron and the Abominable Head from the Baron: they start "
                       .. "quests." } },
        { id = "h22-rol-items", accept = { 95204, 97288 }, use = 275521, at = { 1458, 72.48, 11.33 }, optional = true,
          note = { ru = "Щёлкните герб Лордерона и чудовищную голову: «Герб Лордерона» и «Неизбывные мучения».",
                   en = "Click the Crest of Lordaeron and the Abominable Head: Crest of Lordaeron and Unending Torment." } },
        { id = "h22-rol-apothecarium", turnin = { 97288, 95216 }, npc = { 2055, 11835 }, at = { 1458, 47.57, 70.60 }, optional = true,
          note = { ru = "Квартал аптекарей: голова — мастеру аптекарю Фаранеллу, штамм — Теодору.",
                   en = "The Apothecarium: the head to Master Apothecary Faranell, the strain to Theodore." } },
        { id = "h22-rol-morbin-2", turnin = 92421, npc = 266484, at = { 1458, 58.08, 89.51 }, optional = true,
          note = { ru = "Морбин в Королевском квартале.", en = "Morbin in the Royal Quarter." } },
        { id = "h22-rol-oran", turnin = 95204, npc = 7825, at = { 1458, 73.06, 32.85 }, optional = true,
          note = { ru = "Оран Змеиные Кольца: герб.", en = "Oran Snakewrithe: the crest." } },
        { id = "h22-book-of-ur", accept = 1013, npc = 2934, at = { 1458, 53.74, 54.46 }, optional = true,
          note = { ru = "Если идёте в Крепость Темного Клыка (ниже, в Серебряном бору): хранитель Бел'дугур — «Книга Ура» "
                       .. "(сдадите здесь же на 31-м).",
                   en = "If you go to Shadowfang Keep (below, in Silverpine): Keeper Bel'dugur - The Book of Ur (handed in "
                       .. "here at 31)." } },
        { id = "h22-uc-garrett", go = true, radius = 12, npc = 4551, at = { 1458, 63.25, 48.56 },
          note = { ru = "На юг в Руины Лордерона, на лифте вниз: распорядитель полётов Майкл Гаррет.",
                   en = "South into the Ruins of Lordaeron, take a lift down: flight master Michael Garrett." } },
        { id = "h-22-uc-fly", fly = "The Sepulcher", npc = 2226, at = { 1421, 45.62, 42.60 },
          note = { ru = "Летите в Гробницу (Серебряный бор).", en = "Fly to The Sepulcher (Silverpine Forest)." } },
        { id = "h-22-the-sepulcher-apothecary", accept = 493, npc = 1937, at = { 1421, 42.80, 40.86 },
          note = { ru = "Аптекарь Ренферрел в склепе: «Путешествие в Предгорья Хилсбрада». Задания Серебряного бора не "
                       .. "берите (сдавать их здесь же).",
                   en = "Apothecary Renferrel in the crypt: Journey to Hillsbrad Foothills. Skip the Silverpine quests "
                       .. "(their turn-ins are back here)." } },
        -- Optional, group: Shadowfang Keep (20-30; quests ~2.7x Classic XP). 1014 brings you back to the Sepulcher.
        { id = "h22-sfk-accept", accept = { 1098, 1014 }, npc = { 1952, 1938 }, at = { 1421, 43.81, 40.34 }, optional = true,
          note = { ru = "Если собрали группу: Крепость Темного Клыка (~14 тыс. опыта, ~50 мин; с «Книгой Ура» ~20 тыс.). "
                       .. "Верховный палач Хадрик — «Пропавшие стражи смерти», Далар Ткач Рассвета — «Смерть Аругалу!». "
                       .. "Без группы — «Вперёд» на этих пяти шагах.",
                   en = "If you have a group: Shadowfang Keep (~14k XP, ~50 min; ~20k with The Book of Ur). High Executor "
                       .. "Hadrec - Deathstalkers in Shadowfang, Dalar Dawnweaver - Arugal Must Die. No group: press Forward on these "
                       .. "five steps." } },
        { id = "h22-sfk-vincent", turnin = 1098, at = { 1421, 44.80, 67.80 }, optional = true,
          ok = "at-far-from-giver", -- Vincent is inside the dungeon
          note = { ru = "На юг к крепости на холме (вход 44.8, 67.8). Внутри, за двором: поговорите со стражем смерти "
                       .. "Винсентом.",
                   en = "South to the keep on the hill (entrance 44.8, 67.8). Inside, past the courtyard: talk to "
                       .. "Deathstalker Vincent." } },
        { id = "h22-sfk-book", complete = 1013, at = { 1421, 44.80, 67.80 }, optional = true,
          note = { ru = "Если брали «Книгу Ура»: книга лежит в библиотеке перед Аругалом.",
                   en = "If you took The Book of Ur: the book lies in the library before Arugal." } },
        { id = "h22-sfk-arugal", complete = 1014, at = { 1421, 44.80, 67.80 }, optional = true,
          note = { ru = "Архимаг Аругал (последний босс): его голова.", en = "Archmage Arugal (last boss): his head." } },
        { id = "h22-sfk-dalar", turnin = 1014, npc = 1938, at = { 1421, 44.20, 39.81 }, optional = true,
          note = { ru = "Обратно в Гробницу: Далар. «Книгу Ура» держите до Подгорода (31-й).",
                   en = "Back to the Sepulcher: Dalar. Keep The Book of Ur for the Undercity (31)." } },
        { id = "h22-go-ambermill", go = true, radius = 40, at = { 1421, 61.47, 67.47 },
          note = { ru = "По дороге на юго-восток мимо Янтарной мельницы.",
                   en = "South-east along the road past Ambermill." } },
        -- Forever-new pair at the Offering Stone, 150 yd west of the road (XP unknown).
        { id = "h-22-offering-stone", accept = 95883, object = 645153, at = { 1421, 58.12, 69.77 },
          note = { ru = "Новое в Forever (опыт неизвестен, ~3 мин): Камень подношений у Погибели Берена чуть западнее "
                       .. "дороги.",
                   en = "New in Forever (XP unknown, ~3 min): the Offering Stone at Beren's Peril just west of the "
                       .. "road." } },
        { id = "h22-tortured-soul", complete = 95883, at = { 1421, 58.70, 71.15 },
          note = { ru = "Нежить Когтя Ворона (19-21) у пещеры: Терзаемая душа.",
                   en = "Ravenclaw undead (19-21) by the cave: a Tortured Soul." } },
        { id = "h22-offering-stone-2", turnin = 95883, accept = 95885, object = 645153, at = { 1421, 58.12, 69.77 },
          note = { ru = "Сдайте душу у камня и возьмите «Подношение крови».",
                   en = "Hand in the soul at the stone and take The Offering of Blood." } },
        { id = "h22-offering-stone-3", turnin = 95885, object = 645153, at = { 1421, 58.12, 69.77 },
          note = { ru = "Используйте Терзаемую душу у камня и сдайте задание.",
                   en = "Use the Tortured Soul at the stone and hand the quest in." } },
        { id = "h22-go-hillsbrad", go = true, radius = 40, at = { 1421, 67.14, 79.06 },
          note = { ru = "Дальше по дороге на юго-восток к границе Хилсбрада.",
                   en = "On along the road south-east to the Hillsbrad border." } },
        { id = "h-22-hillsbrad-west-deathstalker", accept = 494, npc = 2214, at = { 1424, 20.79, 47.40 },
          note = { ru = "Следопыт Леш у дороги: «Время нанести удар».",
                   en = "Deathstalker Lesh by the road: Time To Strike." } },

        ------------------------------------------------------------------
        -- Tarren Mill, first visit (level 22)
        ------------------------------------------------------------------
        { id = "h-22-tarrenmill-arrive", fp = "Tarren Mill", npc = 2389, at = { 1424, 60.14, 18.62 },
          note = { ru = "На северо-восток в Мельницу Таррен (фермеров на полях пока не трогайте — задания на них там). "
                       .. "Распорядитель ветрокрылов Зариса: откройте карту полётов.",
                   en = "North-east to Tarren Mill (leave the farmers in the fields for now: their quests are there). "
                       .. "Wind rider master Zarise: open the flight map." } },
        { id = "h22-lydon", turnin = { 1065, 493 }, accept = { 496, 501, 1066 }, npc = 2216, at = { 1424, 61.44, 19.06 },
          note = { ru = "Аптекарь Лидон.", en = "Apothecary Lydon." } },
        { id = "h22-darthalia", turnin = 494, accept = 527, npc = 2215, at = { 1424, 62.33, 20.45 },
          note = { ru = "Верховный палач Дарталия.", en = "High Executor Darthalia." } },
        { id = "h22-posters", accept = { 549, 567 }, object = { 1763, 556670, 2008, 556669 }, at = { 1424, 62.56, 20.20 },
          note = { ru = "Две доски объявлений у дороги: «Разыскиваются: члены Синдиката» и «Опасно!».",
                   en = "The two posters by the road: WANTED: Syndicate Personnel and Dangerous!" } },
        { id = "h22-krusk", accept = 498, npc = 2229, at = { 1424, 63.24, 20.66 },
          note = { ru = "Круск: «Спасение».", en = "Krusk: The Rescue." } },
        { id = "h22-bears-bg", complete = 496, bg = true, at = { 1424, 52.78, 36.73 },
          note = { ru = "Попутно: 10 языков серых медведей (обычные и свирепые, 21-23; старых 25-26 не бейте) и 1 "
                       .. "слизь мохового ползуна.",
                   en = "On the way: 10 Gray Bear Tongues (Gray and Vicious Gray Bears 21-23; skip the Elder ones "
                       .. "25-26) and 1 Creeper Ichor from any Moss Creeper." } },
        { id = "h22-lions-bg", complete = 501, bg = true, at = { 1424, 49.18, 38.19 },
          note = { ru = "Попутно: 10 крови голодных горных львов (23-24) — между Мельницей и полями.",
                   en = "On the way: 10 Mountain Lion Blood from Starving Mountain Lions (23-24) between Tarren Mill "
                       .. "and the fields." } },
        { id = "h22-dangerous-bg", complete = { [567] = { 2, 4 } }, bg = true, at = { 1424, 35.88, 46.57 },
          note = { ru = "Попутно на полях: фермер Калаба (25, у южных грядок) и горожанин Уилкс (25, ходит по дорогам "
                       .. "городка). Писаря Хораса (рядом с судьёй 30-го) и шахтёра Хэкетта (29, рудник) — позже, на 31+.",
                   en = "In the fields: Farmer Kalaba (25, southern plots) and Citizen Wilkes (25, walks the town roads). "
                       .. "Clerk Horrace (next to the level-30 Magistrate) and Miner Hackett (29, mine) wait for 31+." } },

        ------------------------------------------------------------------
        -- Hillsbrad Fields, loop 1 (level 22-23)
        ------------------------------------------------------------------
        { id = "h-22-hillsbrad-foothills-field", complete = 527, at = { 1424, 33.67, 39.03 },
          note = { ru = "Поля Хилсбрада: по 6 фермеров и батраков, фермер Рэй (дом и виноградник на севере) и фермер "
                       .. "Гетц (дом, поле или амбар).",
                   en = "Hillsbrad Fields: 6 Farmers and 6 Farmhands, Farmer Ray (house and vineyard to the north) and "
                       .. "Farmer Getz (house, field or barn)." } },

        ------------------------------------------------------------------
        -- Tarren Mill, second visit -> Durnholde Keep (level 23)
        ------------------------------------------------------------------
        { id = "h22-darthalia-2", turnin = 527, accept = 528, npc = 2215, at = { 1424, 62.33, 20.45 },
          note = { ru = "Обратно в Мельницу: Дарталия.", en = "Back to Tarren Mill: Darthalia." } },
        { id = "h22-samsa", accept = 546, npc = 2418, at = { 1424, 62.11, 19.70 },
          note = { ru = "Стражник смерти Самса: «Сувениры смерти» — 30 черепов с любых людей Хилсбрада и Синдиката.",
                   en = "Deathguard Samsa: Souvenirs of Death - 30 skulls from any Hillsbrad human or Syndicate member." } },
        { id = "h22-skulls-bg", complete = 546, bg = true, at = { 1424, 33.20, 41.51 },
          note = { ru = "Попутно: черепа падают с Синдиката в Дарнхольде и с людей на полях.",
                   en = "On the way: skulls drop from the Syndicate in Durnholde and the humans in the fields." } },
        { id = "h22-durnholde", complete = { 549, 1066 }, at = { 1424, 76.68, 43.81 },
          note = { ru = "На юго-восток в крепость Дарнхольд: по 10 разбойников и дозорных Синдиката (20-22), 5 флаконов "
                       .. "крови с магов тени.",
                   en = "South-east to Durnholde Keep: 10 Syndicate Rogues and 10 Watchmen (20-22), 5 Vials of "
                       .. "Innocent Blood from the Shadow Mages." } },
        { id = "h22-togthar", complete = { [498] = { 2 } }, object = 1722, at = { 1424, 79.79, 39.65 },
          note = { ru = "Восточный двор: тюремщики Эстон и Марлген (24) ходят у бараков — ключи с обоих. Освободите "
                       .. "Тог'тара (кликните цепь).",
                   en = "East yard: Jailor Eston and Jailor Marlgen (24) walk by the barracks - a key from each. Free "
                       .. "Tog'thar (click the ball and chain)." } },
        { id = "h22-drull", complete = { [498] = { 1 } }, object = 1721, at = { 1424, 75.33, 41.50 },
          note = { ru = "Друлл у западной стены: вторым ключом.",
                   en = "Drull by the west wall: use the other key." } },
        { id = "h22-go-fields", go = true, radius = 40, at = { 1424, 54.00, 44.00 },
          note = { ru = "На запад к полям севернее Южнобережья (стражники Альянса).",
                   en = "West to the fields, north of Southshore (Alliance guards)." } },

        ------------------------------------------------------------------
        -- Hillsbrad Fields, loop 2 (level 23)
        ------------------------------------------------------------------
        { id = "h22-peasants", complete = 528, at = { 1424, 33.43, 44.53 },
          note = { ru = "15 крестьян (24-25) в южной части полей. Осторожно: пехотинцы Хилсбрада (25-26) патрулируют "
                       .. "городок.",
                   en = "15 Hillsbrad Peasants (24-25) in the southern fields. Careful: Hillsbrad Footmen (25-26) patrol "
                       .. "the town." } },

        ------------------------------------------------------------------
        -- Tarren Mill, third visit (level 23)
        ------------------------------------------------------------------
        { id = "h22-lydon-2", turnin = { 496, 501, 1066 }, accept = { 499, 502, 1067 }, npc = 2216, at = { 1424, 61.44, 19.06 },
          note = { ru = "Лидон. Не хватает языков или крови — добейте медведей и львов по пути назад.",
                   en = "Lydon. Short of tongues or blood: finish the bears and lions on the way back." } },
        { id = "h22-umpi", turnin = 499, npc = 2230, at = { 1424, 61.55, 19.14 },
          note = { ru = "Умпи рядом с Лидоном.", en = "Umpi next to Lydon." } },
        { id = "h22-darthalia-3", turnin = { 528, 549 }, accept = 529, npc = 2215, at = { 1424, 62.33, 20.45 },
          note = { ru = "Дарталия.", en = "Darthalia." } },
        -- 98094 is offered only after 528 (Wowhead Forever comments + live report); optional: XP unknown, small detour.
        { id = "h22-scout-support", accept = 98094, npc = 2215, at = { 1424, 62.33, 20.45 }, optional = true,
          note = { ru = "Дарталия теперь даёт «Помощь разведчикам» (новое в Forever, открывается после второй "
                       .. "«Битвы за Хилсбрад»): приказ для Масоджа, отнесёте по пути с полей.",
                   en = "Darthalia now offers Scout Support (new in Forever, unlocked by Battle of Hillsbrad "
                       .. "part II): orders for Masoj, delivered on the way back from the fields." } },
        { id = "h22-krusk-2", turnin = 498, npc = 2229, at = { 1424, 63.24, 20.66 },
          note = { ru = "Круск. Его «Проникновение» (34) не берите.", en = "Krusk. Skip his Infiltration (34)." } },

        ------------------------------------------------------------------
        -- Hillsbrad Fields, loop 3 (level 23-24)
        ------------------------------------------------------------------
        { id = "h-22-stanley", turnin = 502, npc = 2274, at = { 1424, 32.66, 35.32 },
          note = { ru = "Стэнли на севере полей: после сценки он становится Разъярённым Стэнли — убейте (опыта как за "
                       .. "задание).",
                   en = "Stanley at the north end of the fields: after the scene he turns into Enraged Stanley - kill "
                       .. "him (about a quest's worth of XP)." } },
        { id = "h22-smithy", complete = 529, object = 1736, at = { 1424, 31.79, 45.32 },
          note = { ru = "Кузница: кузнец Веррингтан (26), 4 подмастерья (24-25) и ящик «Партия железа» внутри.",
                   en = "The smithy: Blacksmith Verringtan (26), 4 Apprentice Blacksmiths (24-25) and the Shipment of "
                       .. "Iron crate inside." } },
        -- 529 is listed again so this step cannot become a forward anchor before Tarren Mill 3 (the 546 skulls can
        -- be finished early; with the level reached, the travel steps before it would be skipped)
        { id = "h-22-hillsbrad-level-gate", complete = { 529, 546 }, level = { 23, 0.85 }, -- level-grind: worst case only (no `ok`)
          at = { 1424, 33.20, 41.51 },
          note = { ru = "Добейте черепа на полях (крестьяне, фермеры, батраки 22-25 — лучший опыт рядом) до 23-го + 85%: "
                       .. "сдача 546 и 529 даст ещё ~16% — это 24-й к Громовому Утёсу.",
                   en = "Finish the skulls in the fields (peasants, farmers, farmhands 22-25: the best XP nearby) up to "
                       .. "level 23 + 85%: the 546 and 529 turn-ins add ~16%, which makes 24 for Thunder Bluff." } },

        { id = "h-22-deathstalker-masoj", turnin = 98094, npc = 270438,
          at = { 1424, 63.58, 53.11 }, optional = true,
          note = { ru = "С полей на восток к Следопыту Масоджу у Дун Гарока (крюк ~2 мин), потом на север в Мельницу. "
                       .. "Его «Ценные высоты» (пузырьки на вершинах) не берите. Не брали приказ — «Вперёд».",
                   en = "From the fields east to Deathstalker Masoj outside Dun Garok (~2 min detour), then north to "
                       .. "Tarren Mill. Skip his Valuable Vantages (vials on peaks). No orders taken: press Forward." } },

        ------------------------------------------------------------------
        -- Tarren Mill, last visit -> hearth (level 24)
        ------------------------------------------------------------------
        { id = "h22-samsa-2", turnin = 546, npc = 2418, at = { 1424, 62.11, 19.70 },
          note = { ru = "Обратно в Мельницу: Самса.", en = "Back to Tarren Mill: Samsa." } },
        { id = "h-24-tarrenmill-end", turnin = 529, accept = 532, npc = 2215, at = { 1424, 62.33, 20.45 },
          note = { ru = "Дарталия. 532 (судья Бернсайд, 30) держите на 31-й — вернётесь сюда позже.",
                   en = "Darthalia. Keep 532 (Magistrate Burnside, 30) for level 31: you come back here later." } },
        { id = "h-24-tb-hearth", hearth = "Thunder Bluff", at = { 1456, 45.81, 64.71 },
          note = { ru = "Камень возвращения в Громовой Утёс. На откате — летите от Зарисы через Подгород/Оргриммар.",
                   en = "Hearth to Thunder Bluff. On cooldown: fly from Zarise via the Undercity / Orgrimmar." } },
    },
})
