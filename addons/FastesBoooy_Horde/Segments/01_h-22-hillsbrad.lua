-- FastesBoooy_Horde / Segments/01_h-22-hillsbrad.lua
--
-- Library segment "h-22-hillsbrad": levels 22-24, class-neutral (Undead Paladin and Skyborne Druid, Horde).
-- Thunder Bluff (1065) -> Orgrimmar (flight point for everybody) -> zeppelin -> Undercity -> fly The Sepulcher
-- (493) -> south through Silverpine (optional Offering Stone pair at Beren's Peril) -> Deathstalker Lesh (494)
-- -> Tarren Mill -> four Hillsbrad loops -> hearth to Thunder Bluff.
-- Plan: research plan60.md section 4.1 / plan60.json segments[1] (anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1456 (Thunder Bluff) / 1413 (The Barrens) / 1454 (Orgrimmar) / 1411 (Durotar) /
-- 1420 (Tirisfal Glades) / 1458 (Undercity) / 1421 (Silverpine Forest) / 1424 (Hillsbrad Foothills), map percent,
-- from tools/data/forever_db.lua (NPC / object spawns; centroids of the objective mob spawns of the area used for
-- complete steps). Silverpine path points and the Orgrimmar gate / Far Watch Post are reference / route facts.
--
-- Hub plan (Forever DB; every quest is available to Scourge and Skyborne Horde characters of any class):
--   TB  : 1065 Zamah (Skyborne only: the UD 1-22 route already carries 1065).
--   Org : everybody learns the Orgrimmar flight point here (later segments fly there; the druid route never
--         learned it): Undead/Orc/Tauren/Troll fly Thunder Bluff -> Orgrimmar and click Doras on landing,
--         Skyborne fly The Crossroads and run via Far Watch Post. Zeppelin to Tirisfal, fly to The Sepulcher.
--   SP  : 493 (Renferrel); Forever-new 95883 -> 95885 at the Offering Stone of Beren's Peril (optional, XP
--         unknown, 150 yd off the road); 494 (Lesh, Hillsbrad west).
--   TM1 : fp; 1065 + 493 > 496, 501, 1066 (Lydon); 494 > 527 (+ optional 98094) (Darthalia); 549 + 567
--         (posters); 498 (Krusk).
--   F1  : Hillsbrad Fields: 527 (farmers, farmhands, Ray, Getz). bg all the time: 496 (bears + 1 creeper ichor),
--         501 (Starving Mountain Lions), 567 Wilkes + Kalaba.
--   TM2 : 527 > 528 (Darthalia); 546 (Samsa).
--   D   : Durnholde Keep: 549 + 1066 (Syndicate), 498 (jailor keys, Drull, Tog'thar); the Syndicate also drop
--         546 skulls (that is why Durnholde comes after TM2, not before F1: same distance, ~20 fewer skull kills).
--   M   : Deathstalker Masoj: 98094 (optional delivery, 200 yd south of the Durnholde -> fields line).
--   F2  : 528 (15 peasants) + skulls.
--   TM3 : 496 > 499 (> Umpi), 501 > 502, 1066 > 1067 (Lydon); 528 + 549 > 529 (Darthalia); 498 (Krusk).
--   F3  : 502 Stanley (kill Enraged Stanley), 529 (smithy), rest of the skulls, level gate.
--   TM4 : 546 (Samsa); 529 > 532 (Darthalia); hearth Thunder Bluff.
-- Carried out: 1067 (h-24, Zamah), 532 (h-31, Magistrate Burnside L30), 567 with objectives 2+4 done
--   (h-31: Clerk Horrace stands next to Burnside in the town hall, Miner Hackett L29 is in Azurelode Mine next
--   to the 539 miners; both are too dangerous at 23-24).
-- Skipped: 98095 Valuable Vantages (Masoj: three vials on Hillsbrad peaks - the peak positions are not in any
--   offline data, XP unknown), 509 (needs 24, done in h-31), 547 (26+), 95981 / 516 (Silverpine, turn-ins back
--   at the Sepulcher), Shadowfang Keep quests (group; 1098 / 1014 / 92401 could be an optional class/dungeon
--   insert before h-22-uc-fly).
-- Automation notes: accepts at one NPC sit in one step; transient steps (fp, fly, go) come before the quest steps
--   of the same place. 496 / 501 (bears, lions) and 567 (Wilkes, Kalaba) are bg-only until their turn-in steps:
--   they can finish on any loop, and a non-bg `complete` that is done early would make the engine fast-forward
--   the optional Masoj step behind it. The 546 skulls are a bg goal until the level gate, which shares its step
--   with them (an anchor only when both are done).
-- Hearthstone: Thunder Bluff (bound by both 1-22 routes), used from Tarren Mill at the end.
FastesBoooy.AddLibrarySegment({
    id = "h-22-hillsbrad",
    title = { ru = "22-24 Предгорья Хилсбрада (Мельница Таррен)", en = "22-24 Hillsbrad Foothills (Tarren Mill)" },
    zone = "Hillsbrad Foothills",
    levels = { 22, 24 },
    steps = {
        ------------------------------------------------------------------
        -- Thunder Bluff -> Orgrimmar (level 22)
        ------------------------------------------------------------------
        { id = "h-22-tb-start", accept = 1065, npc = 3419, at = { 1456, 22.81, 20.89 }, race = "Skyborne",
          note = { ru = "Аптекарь Зама в Прудах Видений (под Вершиной Духов): «Путешествие к Мельнице Таррен».",
                   en = "Apothecary Zamah in the Pools of Vision (below Spirit Rise): Journey to Tarren Mill." } },
        { id = "h-22-tb-fly", go = true, radius = 10, npc = 2995, at = { 1456, 47.00, 49.83 },
          note = { ru = "Наверх на Вершину Духов, по мосту на центральную вершину: распорядитель ветрокрылов Тал.",
                   en = "Up to Spirit Rise and over the bridge to the central mesa: wind rider master Tal." } },
        { id = "h-22-tb-fly-org", fly = "Orgrimmar", npc = 3310, at = { 1454, 45.12, 63.89 },
          race = { "Orc", "Scourge", "Tauren", "Troll" },
          note = { ru = "Летите в Оргриммар. Нет его на карте полётов — летите на Перекрёсток и бегите на северо-восток "
                       .. "через Заставу Дальнего Дозора (+5 мин).",
                   en = "Fly to Orgrimmar. Not on your flight map: fly to The Crossroads and run north-east via Far "
                       .. "Watch Post (+5 min)." } },
        { id = "h-22-tb-fly-xroads", fly = "The Crossroads", npc = 3615, at = { 1413, 51.50, 30.34 }, race = "Skyborne",
          note = { ru = "Оргриммара ещё нет на карте полётов: летите на Перекрёсток.",
                   en = "Orgrimmar is not on your flight map yet: fly to The Crossroads." } },
        { go = true, radius = 30, at = { 1413, 62.26, 19.38 }, race = "Skyborne",
          note = { ru = "По дороге на северо-восток к Заставе Дальнего Дозора и через мост в Дуротар.",
                   en = "North-east along the road to Far Watch Post and over the bridge into Durotar." } },
        { go = true, radius = 20, at = { 1454, 48.97, 92.84 }, race = "Skyborne",
          note = { ru = "Дальше на север по дороге к главным воротам Оргриммара.",
                   en = "Then north along the road to the main gate of Orgrimmar." } },
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
        { go = true, radius = 40, npc = 9566, at = { 1420, 60.74, 58.87 },
          note = { ru = "Прибытие к башне в Тирисфальских лесах (Запетта).",
                   en = "Arrival at the Tirisfal Glades tower (Zapetta)." } },
        { go = true, radius = 12, npc = 4551, at = { 1458, 63.25, 48.56 },
          note = { ru = "На юг в Руины Лордерона, на лифте вниз: распорядитель полётов Майкл Гаррет.",
                   en = "South into the Ruins of Lordaeron, take a lift down: flight master Michael Garrett." } },
        { id = "h-22-uc-fly", fly = "The Sepulcher", npc = 2226, at = { 1421, 45.62, 42.60 },
          note = { ru = "Летите в Гробницу (Серебряный бор).", en = "Fly to The Sepulcher (Silverpine Forest)." } },
        { id = "h-22-the-sepulcher-apothecary", accept = 493, npc = 1937, at = { 1421, 42.80, 40.86 },
          note = { ru = "Аптекарь Ренферрел в склепе: «Путешествие в Предгорья Хилсбрада». Больше здесь ничего не берите.",
                   en = "Apothecary Renferrel in the crypt: Journey to Hillsbrad Foothills. Take nothing else here." } },
        { go = true, radius = 40, at = { 1421, 61.47, 67.47 },
          note = { ru = "По дороге на юго-восток мимо Янтарной мельницы.",
                   en = "South-east along the road past Ambermill." } },
        -- Forever-new pair at the Offering Stone, 150 yd west of the road (XP unknown, optional).
        { id = "h-22-offering-stone", accept = 95883, object = 645153, at = { 1421, 58.12, 69.77 }, optional = true,
          note = { ru = "По желанию (новое в Forever, опыт неизвестен, ~3 мин): Камень подношений у Погибели Берена "
                       .. "чуть западнее дороги. Не нужно — «Пропуск» на этих четырёх шагах.",
                   en = "Optional (new in Forever, XP unknown, ~3 min): the Offering Stone at Beren's Peril just west "
                       .. "of the road. Not wanted: Skip these four steps." } },
        { complete = 95883, at = { 1421, 58.70, 71.15 }, optional = true,
          note = { ru = "Нежить Когтя Ворона (19-21) у пещеры: Терзаемая душа.",
                   en = "Ravenclaw undead (19-21) by the cave: a Tortured Soul." } },
        { turnin = 95883, accept = 95885, object = 645153, at = { 1421, 58.12, 69.77 }, optional = true, -- WARN-OK: xp-unknown
          note = { ru = "Сдайте душу у камня и возьмите «Подношение крови».",
                   en = "Hand in the soul at the stone and take The Offering of Blood." } },
        { turnin = 95885, object = 645153, at = { 1421, 58.12, 69.77 }, optional = true, -- WARN-OK: xp-unknown
          note = { ru = "Используйте Терзаемую душу у камня и сдайте задание.",
                   en = "Use the Tortured Soul at the stone and hand the quest in." } },
        { go = true, radius = 40, at = { 1421, 67.14, 79.06 },
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
        { turnin = { 1065, 493 }, accept = { 496, 501, 1066 }, npc = 2216, at = { 1424, 61.44, 19.06 },
          note = { ru = "Аптекарь Лидон.", en = "Apothecary Lydon." } },
        { turnin = 494, accept = 527, npc = 2215, at = { 1424, 62.33, 20.45 },
          note = { ru = "Верховный палач Дарталия.", en = "High Executor Darthalia." } },
        { accept = 98094, npc = 2215, at = { 1424, 62.33, 20.45 }, optional = true,
          note = { ru = "По желанию (новое в Forever, опыт неизвестен): приказ для Масоджа — он почти по пути.",
                   en = "Optional (new in Forever, XP unknown): orders for Masoj - he is almost on the way." } },
        { accept = { 549, 567 }, object = { 1763, 556670, 2008, 556669 }, at = { 1424, 62.56, 20.20 },
          note = { ru = "Две доски объявлений у дороги: «Разыскиваются: члены Синдиката» и «Опасно!».",
                   en = "The two posters by the road: WANTED: Syndicate Personnel and Dangerous!" } },
        { accept = 498, npc = 2229, at = { 1424, 63.24, 20.66 },
          note = { ru = "Круск: «Спасение».", en = "Krusk: The Rescue." } },
        { complete = 496, bg = true, at = { 1424, 52.78, 36.73 },
          note = { ru = "Попутно: 10 языков серых медведей (обычные и свирепые, 21-23; старых 25-26 не бейте) и 1 "
                       .. "слизь мохового ползуна.",
                   en = "On the way: 10 Gray Bear Tongues (Gray and Vicious Gray Bears 21-23; skip the Elder ones "
                       .. "25-26) and 1 Creeper Ichor from any Moss Creeper." } },
        { complete = 501, bg = true, at = { 1424, 49.18, 38.19 },
          note = { ru = "Попутно: 10 крови голодных горных львов (23-24) — между Мельницей и полями.",
                   en = "On the way: 10 Mountain Lion Blood from Starving Mountain Lions (23-24) between Tarren Mill "
                       .. "and the fields." } },
        { complete = { [567] = { 2, 4 } }, bg = true, at = { 1424, 35.88, 46.57 },
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
        { turnin = 527, accept = 528, npc = 2215, at = { 1424, 62.33, 20.45 },
          note = { ru = "Обратно в Мельницу: Дарталия.", en = "Back to Tarren Mill: Darthalia." } },
        { accept = 546, npc = 2418, at = { 1424, 62.11, 19.70 },
          note = { ru = "Стражник смерти Самса: «Сувениры смерти» — 30 черепов с любых людей Хилсбрада и Синдиката.",
                   en = "Deathguard Samsa: Souvenirs of Death - 30 skulls from any Hillsbrad human or Syndicate member." } },
        { complete = 546, bg = true, at = { 1424, 33.20, 41.51 },
          note = { ru = "Попутно: черепа падают с Синдиката в Дарнхольде и с людей на полях.",
                   en = "On the way: skulls drop from the Syndicate in Durnholde and the humans in the fields." } },
        { complete = { 549, 1066 }, at = { 1424, 76.68, 43.81 },
          note = { ru = "На юго-восток в крепость Дарнхольд: по 10 разбойников и дозорных Синдиката (20-22), 5 флаконов "
                       .. "крови с магов тени.",
                   en = "South-east to Durnholde Keep: 10 Syndicate Rogues and 10 Watchmen (20-22), 5 Vials of "
                       .. "Innocent Blood from the Shadow Mages." } },
        { complete = { [498] = { 2 } }, object = 1722, at = { 1424, 79.79, 39.65 },
          note = { ru = "Восточный двор: тюремщики Эстон и Марлген (24) ходят у бараков — ключи с обоих. Освободите "
                       .. "Тог'тара (кликните цепь).",
                   en = "East yard: Jailor Eston and Jailor Marlgen (24) walk by the barracks - a key from each. Free "
                       .. "Tog'thar (click the ball and chain)." } },
        { complete = { [498] = { 1 } }, object = 1721, at = { 1424, 75.33, 41.50 },
          note = { ru = "Друлл у западной стены: вторым ключом.",
                   en = "Drull by the west wall: use the other key." } },
        { id = "h-22-deathstalker-masoj", turnin = 98094, npc = 270438, at = { 1424, 63.58, 53.11 }, optional = true, -- WARN-OK: xp-unknown
          note = { ru = "Следопыт Масодж к юго-западу от крепости. Его «Ценные высоты» (пузырьки на вершинах) не "
                       .. "берите: где вершины — неизвестно.",
                   en = "Deathstalker Masoj south-west of the keep. Skip his Valuable Vantages (vials on peaks): the "
                       .. "peaks are not mapped." } },
        { go = true, radius = 40, at = { 1424, 54.00, 44.00 },
          note = { ru = "На запад к полям севернее Южнобережья (стражники Альянса).",
                   en = "West to the fields, north of Southshore (Alliance guards)." } },

        ------------------------------------------------------------------
        -- Hillsbrad Fields, loop 2 (level 23)
        ------------------------------------------------------------------
        { complete = 528, at = { 1424, 33.43, 44.53 },
          note = { ru = "15 крестьян (24-25) в южной части полей. Осторожно: пехотинцы Хилсбрада (25-26) патрулируют "
                       .. "городок.",
                   en = "15 Hillsbrad Peasants (24-25) in the southern fields. Careful: Hillsbrad Footmen (25-26) patrol "
                       .. "the town." } },

        ------------------------------------------------------------------
        -- Tarren Mill, third visit (level 23)
        ------------------------------------------------------------------
        { turnin = { 496, 501, 1066 }, accept = { 499, 502, 1067 }, npc = 2216, at = { 1424, 61.44, 19.06 },
          note = { ru = "Лидон. Не хватает языков или крови — добейте медведей и львов по пути назад.",
                   en = "Lydon. Short of tongues or blood: finish the bears and lions on the way back." } },
        { turnin = 499, npc = 2230, at = { 1424, 61.55, 19.14 },
          note = { ru = "Умпи рядом с Лидоном.", en = "Umpi next to Lydon." } },
        { turnin = { 528, 549 }, accept = 529, npc = 2215, at = { 1424, 62.33, 20.45 },
          note = { ru = "Дарталия.", en = "Darthalia." } },
        { turnin = 498, npc = 2229, at = { 1424, 63.24, 20.66 },
          note = { ru = "Круск. Его «Проникновение» (34) не берите.", en = "Krusk. Skip his Infiltration (34)." } },

        ------------------------------------------------------------------
        -- Hillsbrad Fields, loop 3 (level 23-24)
        ------------------------------------------------------------------
        { id = "h-22-stanley", turnin = 502, npc = 2274, at = { 1424, 32.66, 35.32 },
          note = { ru = "Стэнли на севере полей: после сценки он становится Разъярённым Стэнли — убейте (опыта как за "
                       .. "задание).",
                   en = "Stanley at the north end of the fields: after the scene he turns into Enraged Stanley - kill "
                       .. "him (about a quest's worth of XP)." } },
        { complete = 529, object = 1736, at = { 1424, 31.79, 45.32 },
          note = { ru = "Кузница: кузнец Веррингтан (26), 4 подмастерья (24-25) и ящик «Партия железа» внутри.",
                   en = "The smithy: Blacksmith Verringtan (26), 4 Apprentice Blacksmiths (24-25) and the Shipment of "
                       .. "Iron crate inside." } },
        -- 529 is listed again so this step cannot become a forward anchor before Tarren Mill 3 (the 546 skulls can
        -- be finished early; with the level reached, the optional Masoj turn-in would be skipped)
        { id = "h-22-hillsbrad-level-gate", complete = { 529, 546 }, level = { 23, 0.85 }, -- WARN-OK: level-grind
          at = { 1424, 33.20, 41.51 },
          note = { ru = "Добейте черепа на полях (крестьяне, фермеры, батраки 22-25 — лучший опыт рядом) до 23-го + 85%: "
                       .. "сдача 546 и 529 даст ещё ~16% — это 24-й к Громовому Утёсу.",
                   en = "Finish the skulls in the fields (peasants, farmers, farmhands 22-25: the best XP nearby) up to "
                       .. "level 23 + 85%: the 546 and 529 turn-ins add ~16%, which makes 24 for Thunder Bluff." } },

        ------------------------------------------------------------------
        -- Tarren Mill, last visit -> hearth (level 24)
        ------------------------------------------------------------------
        { turnin = 546, npc = 2418, at = { 1424, 62.11, 19.70 },
          note = { ru = "Обратно в Мельницу: Самса.", en = "Back to Tarren Mill: Samsa." } },
        { id = "h-24-tarrenmill-end", turnin = 529, accept = 532, npc = 2215, at = { 1424, 62.33, 20.45 },
          note = { ru = "Дарталия. 532 (судья Бернсайд, 30) держите на 31-й — вернётесь сюда позже.",
                   en = "Darthalia. Keep 532 (Magistrate Burnside, 30) for level 31: you come back here later." } },
        { id = "h-24-tb-hearth", hearth = "Thunder Bluff", at = { 1456, 45.81, 64.71 },
          note = { ru = "Камень возвращения в Громовой Утёс. На откате — летите от Зарисы через Подгород/Оргриммар.",
                   en = "Hearth to Thunder Bluff. On cooldown: fly from Zarise via the Undercity / Orgrimmar." } },
    },
})
