-- FastesBoooy_Horde / Segments/07_h-41-arathi-badlands.lua
--
-- Library segment "h-41-arathi-badlands": levels 41-44, class-neutral (Undead Paladin and Skyborne Druid, Horde).
-- Brackenwall Village -> hearth Orgrimmar -> zeppelin to Tirisfal -> Undercity (232 > 238 > 243, 495) -> fly Tarren
-- Mill -> Alterac Mountains (Baron Vardus 566, Lord Aliden Perenolde 507 > 508) -> Tarren Mill -> fly Hammerfall ->
-- the Arathi binding stones (651) -> Faldir's Cove (663, 662, 664, 665 > 666 > 668 > 669) -> Thandol Span -> Wetlands
-- (Dun Modr, Dun Algaz) -> Loch Modan (west of Thelsamar) -> Badlands: Rigglefuzz (703), Lotwil (710 > 711 > 712),
-- Kargath (flight point, hearth, 782, 2258, 1419, 1420), the south-west loop (coyotes, buzzards, Dustbelcher ogres,
-- Greater Rock Elementals, level gate) -> Rigglefuzz -> Lotwil -> Kargath -> Searing Gorge next door (4449) ->
-- Kargath.
-- Plan: research plan60.md section 4.7 / plan60.json segments[7] (anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1454 (Orgrimmar) / 1411 (Durotar) / 1420 (Tirisfal Glades) / 1458 (Undercity) / 1424
-- (Hillsbrad Foothills) / 1416 (Alterac Mountains) / 1417 (Arathi Highlands) / 1437 (Wetlands) / 1432 (Loch Modan) /
-- 1418 (Badlands) / 1427 (Searing Gorge), map percent, from
-- tools/data/forever_db.lua: NPC / object spawns for npc / object steps, centroids of the objective mob / object
-- spawns of the area used for complete steps (h41 tools: research scratch h41/cen.lua, h41/box.lua). Travel points
-- (not checked in game): Hammerfall, the path down into Faldir's Cove, the north end of the Thandol Span (next to
-- the Dark Iron camp; the Wetlands saboteurs on the bridge at 50.9,8.2 convert to Arathi 45.2,93.4), the Wetlands
-- spirit healer 6491 (49.3,41.8), Dun Algaz (Dragonmaw scouts 48.9,77.1), the Loch Modan spirit healer 6491 west of
-- Thelsamar and the south road to the Badlands (Loch Modan 46.5,77.5 = Badlands 47.6,4.2 by the QuestieDB world
-- bounds).
-- ruRU names in the notes: Wowhead Forever ruRU tooltips (nether.wowhead.com/forever/ru/tooltip/...).
--
-- Hub plan (Forever DB; every quest is open to Scourge and Skyborne Horde characters of any class):
--   UC   : 232 (Zinge) > Luca 238 > Zinge 243 (carried to Gadgetzan, h-46); 495 (Sharlindra); optional Scarlet
--          Monastery block (1048, Varimathras); fly Tarren Mill.
--   TM   : 495 > optional 518 (Melisara), optional 507 (Krusk, needs 506 from h-31), 566 (WANTED poster); Alterac:
--          Baron Vardus on the road north of Strahnbrad (566), Lord Aliden Perenolde (507) > Elysa 508, optional
--          Crushridge Maulers (518, elite); Tarren Mill: 566, optional 508 / 518; fly Hammerfall.
--   AR   : Hammerfall (pass through) -> Iridescent Shards 651, the East / Outer / West binding stones (keys), the Stone
--          of Inner Binding (651) -> Faldir's Cove: 663 (Lolo > Shakes), 662 (Nilzlix), 664 (Steelgut), 665
--          (Phizzlethorpe escort) > 666 (Draxlegauge); wrecks (662), Daggerspine naga (664), Elven Gems (666);
--          662, 664, 666 > 668 > 669 (Shakes; carried to Booty Bay, h-44).
--   BL 1 : Rigglefuzz 703 (+ optional 2418 and an Uldaman run); Martek 1106 > 1108 (Stonevault troggs 300 yards
--          south-east) > 1137 (carried to Fizzle, h-46); Lotwil 710, Lesser Rock Elementals, Lotwil 710 > 711,
--          Rock Elementals (north-west);
--          Kargath: fp, hearth, 782 (Gorn), 2258 (Jarkal), 1419 + 1420 (Neeka; 1420 carried to Stonard, h-44).
--   BL 2 : Lotwil 711 > 712; south-west loop: Elder Crag Coyotes + Giant Buzzards (1419, 2258 gizzards / fangs, 703),
--          Greater Rock Elementals (712, 2258 shards), Boss Tho'grun (782: patrols a ~3,000-yard loop through the
--          southern Badlands - a bg reminder after Lotwil, the blocking step next to the gate camp), level gate; Rigglefuzz 703 (+ optional
--          2418), Lotwil 712, Kargath 1419, 782; Searing Gorge (550 yards west through the canyon): 4449 Caught! (8 Dark
--          Iron Geologists + 15 Silk Cloth); Kargath 2258.
-- Deviations from the plan (documented in the handoff):
--   * The Arathi quests of the plan that need elite kills are not taken (Wowhead Forever tooltips: Elite; DB rank 1):
--     639 Sigil of Strom (Syndicate 35-38) and with it 640 / 641 / 643 / 644 / 645 / 646 (Stromgarde guards 37-40,
--     Lieutenant Valorcall 38, Prince Galen Trollbane 44), 673 Foul Magics (Marez Cowl 40), 679 Call to Arms /
--     680 The Real Threat (Boulderfist Shamans / Lords 38-40, Or'Kalar 40). 651 Stones of Binding (left over from
--     h-31) IS taken now (densification pass): Iridescent Shards -> the East / Outer / West stones (Exiles 38-39,
--     non-elite; mind the elite Fozruk, whose patrol passes all four stones, and Thenan at the Inner circle) -> the
--     Stone of Inner Binding,
--     +2 350 yards on the mount for 2 850 XP; its follow-up 652 needs the elite Fozruk (42) - so 688 / 687 / 692
--     (Theldurin) are out. Hammerfall is only the flight point; the plan anchors of these places sit on the nearest
--     route steps (h-41-stone-of-inner: the 651 turn-in at the Stone of Inner Binding; h-41-keystone: travel step;
--     h-41-trollbane-s-tomb: 663 at Shakes; h-41-hammerfall: the last Arathi turn-in, 668 at Shakes).
--   * Densification pass (34-46), Tarren Mill / Alterac: the Undercity -> Hammerfall flight goes through Tarren Mill
--     anyway, so h-41-undercity-flight-master now flies to Tarren Mill and h41-fly-hammerfall continues later: 495
--     The Crown of Will (Sharlindra, Royal Quarter) > Melisara and 566 WANTED: Baron Vardus (normal 40, Wowhead
--     Forever) - ~1 300 / 1 400 yards each way on the mount; optional: 507 Lord Aliden Perenolde > 508 Taretha's Gift
--     (needs 506 Blackmoore's Legacy, which h-31 turns in only on its optional Strahnbrad trip: required here it would
--     be an optional-dependency ERROR) and the next Crown of Will 518 (14 elite Crushridge Maulers 36-37); 519-521
--     (elite ogre chiefs 39-43) are not taken.
--   * Badlands: 713 / 714 / 716 need crafted items (Frost Oil - alchemy, Gyrochronatom - engineering, Patterned
--     Bronze Bracers - blacksmithing) and are not taken; Lotwil gives 710 > 711 > 712 only. Added 703 Barbecued
--     Buzzard Wings (Rigglefuzz, on the road; the wings drop from the Giant Buzzards of 2258). 709 Solution to Doom
--     (Theldurin, far south, chest at the Uldaman excavation in the north) is skipped and 2418 Power Stones (elite
--     Shadowforge) is an optional Uldaman group block (entrance 680 yards north of Rigglefuzz); Theldurin is not
--     visited (h-41-theldurin-the-lost sits on the Rigglefuzz turn-in, the closest route step). 2342 Reclaimed
--     Treasures (Uldaman, Undercity) is not offered: its turn-in would sit right after h-44-uc-arrive, where the
--     paladin's training insert would be fast-forwarded by it.
--   * Added 4449 Caught! (Searing Gorge, rl 43, after the level gate): the Wooden Outhouse is 550 yards west of Kargath
--     through the canyon (the way h-50 takes into the Searing Gorge); 4450 Ledger from Tanaris is not taken (items in
--     three zones, turn-in in Gadgetzan).
--   * No hearth use in the Badlands: the hearthstone is bound to Kargath and left off cooldown for h-44.
-- XP (validator, Classic quest XP + objective kills with the DB counts; Undead paladin from 40.85): required quests
--   ~56 k (was ~38 k; + ~11 k optional), objective kills ~31 k. The level gate in the south-west (Dustbelcher ogres
--   40-43 and Greater Rock Elementals 42-44, the best non-elite camp for 42-44 near Kargath) covers the rest: 43 + 80%
--   (~855 same-level kills normal, ~970 worst case; was ~965 from 41.00), set so the required turn-ins after it
--   (Caught! needs 43) make 44.0 at h-44-uc-arrive (paladin and druid training at 44) even with every optional step
--   skipped. Group alternatives: the Scarlet Monastery and Uldaman blocks.
-- Automation notes: accepts at one NPC sit in one step; transient steps (fp, sethearth) come before the quest steps of
--   Kargath. The class insert anchor h-41-uc-arrive (paladin: Brill, training and riding at 40) is the arrival at the
--   Tirisfal zeppelin tower, before the Undercity quest steps.
FastesBoooy.AddLibrarySegment({
    id = "h-41-arathi-badlands",
    title = { ru = "41-44 Нагорье Арати и Бесплодные земли", en = "41-44 Arathi Highlands and Badlands" },
    zone = "Badlands",
    levels = { 41, 44 },
    steps = {
        ------------------------------------------------------------------
        -- Brackenwall -> Orgrimmar -> zeppelin -> Undercity (41)
        ------------------------------------------------------------------
        { id = "h41-hearth-org", hearth = "Orgrimmar", at = { 1454, 54.10, 68.41 },
          note = { ru = "Камень возвращения в Оргриммар (привязан в прошлом сегменте). Камень на откате - Щербушка: "
                       .. "полёт в Оргриммар.",
                   en = "Hearthstone to Orgrimmar (bound in the previous segment). Hearthstone on cooldown: Shardi, "
                       .. "fly to Orgrimmar." } },
        { id = "h41-zeppelin-uc", go = true, radius = 15, npc = 9564, at = { 1411, 50.82, 13.54 },
          note = { ru = "Через главные ворота к башне дирижаблей: платформа Фреззы - дирижабль в Тирисфальские леса "
                       .. "(Подгород).",
                   en = "Out through the main gate to the zeppelin tower: Frezza's platform - the zeppelin to Tirisfal "
                       .. "Glades (Undercity)." } },
        { id = "h-41-uc-arrive", go = true, radius = 40, npc = 9566, at = { 1420, 60.74, 58.87 },
          note = { ru = "Прибытие к башне в Тирисфальских лесах. Дальше в Руины Лордерона и на лифте вниз в Подгород.",
                   en = "Arrival at the Tirisfal Glades tower. Then into the Ruins of Lordaeron and down a lift into "
                       .. "Undercity." } },
        { accept = 232, npc = 5204, at = { 1458, 50.14, 67.97 },
          note = { ru = "Квартал аптекарей: аптекарь Зинг - «Посылка для аптекаря Зинг» (заказ Алессандро Луке).",
                   en = "The Apothecarium: Apothecary Zinge - Errand for Apothecary Zinge (the order goes to "
                       .. "Alessandro Luca)." } },
        { turnin = 232, accept = 238, npc = 7683, at = { 1458, 58.61, 54.68 },
          note = { ru = "Алессандро Лука (лавка «Синяя луна»): отдайте заказ, возьмите набор для полевых исследований.",
                   en = "Alessandro Luca (Blue Moon Odds and Ends): hand over the order, take the Field Testing Kit." } },
        { turnin = 238, accept = 243, npc = 5204, at = { 1458, 50.14, 67.97 },
          note = { ru = "Обратно к Зинг: «Поход в пустыню» - в Прибамбасск (Танарис), позже.",
                   en = "Back to Zinge: Into the Field - to Gadgetzan (Tanaris), later." } },
        { id = "h41-sharlindra", accept = 495, npc = 2227, at = { 1458, 57.63, 93.80 },
          note = { ru = "Рядом, в Королевском квартале: Шарлиндра - «Корона Воли» (письмо Мелизаре на Мельницу "
                       .. "Таррен).",
                   en = "Next door, in the Royal Quarter: Sharlindra - The Crown of Will (a letter for Melisara in "
                       .. "Tarren Mill)." } },
        -- Optional group content: Scarlet Monastery (Library, Armory, Cathedral; Tirisfal 82.6,33.8 - Brill is on the
        -- way, where the paladin trains and buys the riding skill at 40).
        { id = "h41-sm-accept", accept = 1048, npc = 2425, optional = true, at = { 1458, 56.25, 92.20 },
          note = { ru = "По желанию, если собрали группу в Монастырь Алого ордена: Вариматрас там же - «В монастырь "
                       .. "Алого ордена». Без группы - дальше (шаги пропустятся сами).",
                   en = "Optional, if you have a group for the Scarlet Monastery: Varimathras right there - Into The "
                       .. "Scarlet Monastery. No group: go on (these steps skip themselves)." } },
        { complete = 1048, optional = true, at = { 1420, 82.60, 33.80 },
          note = { ru = "Монастырь Алого ордена (Тирисфаль, 82.6, 33.8): псарь Локси (Библиотека), воитель Герод "
                       .. "(Оружейная), командир Могрейн и инквизитор Вайтмейн (Собор).",
                   en = "Scarlet Monastery (Tirisfal 82.6, 33.8): Houndmaster Loksey (Library), Herod (Armory), "
                       .. "Commander Mograine and High Inquisitor Whitemane (Cathedral)." } },
        { turnin = 1048, npc = 2425, optional = true, at = { 1458, 56.25, 92.20 },
          note = { ru = "Обратно к Вариматрасу.", en = "Back to Varimathras." } },
        { id = "h-41-undercity-flight-master", fly = "Tarren Mill", npc = 2389, at = { 1424, 60.14, 18.62 },
          note = { ru = "Майкл Гарретт: летите на Мельницу Таррен (Предгорья Хилсбрада).",
                   en = "Michael Garrett: fly to Tarren Mill (Hillsbrad Foothills)." } },

        ------------------------------------------------------------------
        -- Tarren Mill -> Alterac Mountains (Baron Vardus, Lord Aliden Perenolde) -> Tarren Mill (41)
        ------------------------------------------------------------------
        { turnin = 495, npc = 2278, at = { 1424, 62.63, 20.65 },
          note = { ru = "Мелизара в Мельнице Таррен.", en = "Melisara in Tarren Mill." } },
        { accept = 518, npc = 2278, optional = true, at = { 1424, 62.63, 20.65 },
          note = { ru = "По желанию: следующая «Корона Воли» - 14 извергов из клана Раздробленного Хребта (элита 36-37, "
                       .. "на 41 медленно в одиночку). Дальше по цепочке - элитные вожди огров, её не берите.",
                   en = "Optional: the next Crown of Will - 14 Crushridge Maulers (elites 36-37, slow solo at 41). The "
                       .. "rest of the chain is elite ogre chiefs - do not take it." } },
        { accept = 507, npc = 2229, optional = true, at = { 1424, 63.24, 20.66 },
          note = { ru = "Если в прошлый раз освободили Гол'дира («Наследие Блэкмура» сдано): Круск - «Лорд Алиден "
                       .. "Перенольд». Иначе Круск его не даст - эти шаги пропустятся сами.",
                   en = "If you freed Gol'dir last time (Blackmoore's Legacy turned in): Krusk - Lord Aliden Perenolde. "
                       .. "Otherwise Krusk does not offer it - these steps skip themselves." } },
        { accept = 566, object = 1763, at = { 1424, 62.60, 20.80 },
          note = { ru = "Объявление рядом: «РАЗЫСКИВАЕТСЯ: Барон Вардус».", en = "The poster next to him: WANTED: Baron Vardus." } },
        { complete = 566, at = { 1416, 56.28, 26.70 },
          note = { ru = "На север в Альтеракские горы: барон Вардус (40) ходит по дороге на север от Странбрада - "
                       .. "голова.",
                   en = "North into the Alterac Mountains: Baron Vardus (40) walks the road north of Strahnbrad - his "
                       .. "head." } },
        { complete = 507, optional = true, at = { 1416, 39.32, 14.58 },
          note = { ru = "Дальше на северо-запад зоны: лорд Алиден Перенольд (41), рядом с ним стоит Элиза.",
                   en = "On to the north-west of the zone: Lord Aliden Perenolde (41), Elysa stands next to him." } },
        { turnin = 507, accept = 508, npc = 2317, optional = true, at = { 1416, 39.30, 14.31 },
          note = { ru = "Элиза рядом: «Подарок Тареты» (ожерелье).", en = "Elysa next to him: Taretha's Gift (the necklace)." } },
        { complete = 518, optional = true, at = { 1416, 39.40, 42.00 },
          note = { ru = "По желанию, на обратном пути: лагерь огров Раздробленного Хребта (на юг) - 14 извергов (элита).",
                   en = "Optional, on the way back: Crushridge Hold (to the south) - 14 Crushridge Maulers (elite)." } },
        { turnin = 566, npc = 2215, at = { 1424, 62.33, 20.45 },
          note = { ru = "Мельница Таррен: верховный палач Дарталия.", en = "Tarren Mill: High Executor Darthalia." } },
        { turnin = 508, npc = 2229, optional = true, at = { 1424, 63.24, 20.66 },
          note = { ru = "На юго-восток в Мельницу Таррен: Круск (ожерелье Тареты).",
                   en = "South-east to Tarren Mill: Krusk (Taretha's necklace)." } },
        { turnin = 518, npc = 2278, optional = true, at = { 1424, 62.63, 20.65 },
          note = { ru = "Мелизара. Продолжение (элитные вожди) не берите.",
                   en = "Melisara. Skip the follow-up (elite chiefs)." } },
        { id = "h41-fly-hammerfall", fly = "Hammerfall", npc = 2851, at = { 1417, 73.02, 32.70 },
          note = { ru = "Зарисса: летите в Павший Молот.", en = "Zarise: fly to Hammerfall." } },

        ------------------------------------------------------------------
        -- Arathi: Hammerfall -> Faldir's Cove (41)
        ------------------------------------------------------------------
        { id = "h-41-hammerfall-arrive", go = true, radius = 25, at = { 1417, 71.50, 35.50 },
          note = { ru = "Павший Молот: остальные задания здесь (печати Штромгарда, «Зловещая магия», «К оружию!», "
                       .. "«Настоящая угроза») - на элитных мобов, их пропускаем. Выезжайте на восток.",
                   en = "Hammerfall: its remaining quests (the Stromgarde sigils, Foul Magics, Call to Arms, The Real "
                       .. "Threat) need elite kills - skipped. Ride out to the east." } },
        { id = "h41-iridescent-shards", accept = 651, object = 2701, at = { 1417, 84.31, 30.95 },
          note = { ru = "Радужные осколки к востоку (там же сдавали «Пойманную принцессу»): «Связывающие камни» - ключи с "
                       .. "трёх связывающих камней, сдача у внутреннего связывающего камня по пути на юг.",
                   en = "The Iridescent Shards to the east (where The Princess Trapped was turned in): Stones of Binding "
                       .. "- the keys from three binding stones, turned in at the Stone of Inner Binding on the way "
                       .. "south." } },
        { complete = { [651] = { 2 } }, object = 2691, at = { 1417, 66.70, 29.70 },
          note = { ru = "Восточный связывающий камень (к западу от Павшего Молота): резной ключ. Вокруг изгои 38-39. "
                       .. "Элитный Фозрук (42) ходит между всеми связывающими камнями - осмотритесь, прежде чем брать.",
                   en = "The Stone of East Binding (west of Hammerfall): the Cresting Key. Exiles 38-39 around. The "
                       .. "elite Fozruk (42) patrols between all the binding stones - check before you loot." } },
        { id = "h41-arathi-center", complete = { [651] = { 3 } }, object = 2690, at = { 1417, 52.00, 50.70 },
          note = { ru = "На юго-запад к внешнему связывающему камню (восточнее Опорного пункта Альянса - к стражникам не "
                       .. "подходите): громовой ключ. Фозрук (элита 42) проходит рядом - осмотритесь, прежде чем брать.",
                   en = "South-west to the Stone of Outer Binding (east of the Alliance Refuge Pointe - keep away from "
                       .. "its guards): the Thundering Key. Fozruk (elite 42) patrols past it - check before you "
                       .. "loot." } },
        { complete = { [651] = { 1 } }, object = 2689, at = { 1417, 25.50, 30.10 },
          note = { ru = "На северо-запад к западному связывающему камню: огненный ключ (вокруг изгои 38-39). Фозрук "
                       .. "(элита 42) проходит вплотную к камню - осмотритесь, прежде чем брать.",
                   en = "North-west to the Stone of West Binding: the Burning Key (Exiles 38-39 around). Fozruk (elite "
                       .. "42) patrols right past the stone - check before you loot." } },
        { id = "h-41-stone-of-inner", turnin = 651, object = 2702, at = { 1417, 36.23, 57.38 },
          note = { ru = "На юг к внутреннему связывающему камню: сдайте ключи. Тенан (элитный великан, 42) бродит у "
                       .. "камней, и Фозрук (элита 42) тоже проходит рядом - подходите, когда оба далеко. «Разбить "
                       .. "ключ-камень» (элитный Фозрук) не берите.",
                   en = "South to the Circle of Inner Binding: hand in the keys at the stone. Thenan (elite giant, 42) "
                       .. "roams the stones and Fozruk (elite 42) patrols past too - go in when both are away. Skip "
                       .. "Breaking the Keystone (elite Fozruk)." } },
        { id = "h-41-keystone", go = true, radius = 60, at = { 1417, 34.00, 73.00 },
          note = { ru = "На юг по тропе вниз в Бухту Фалдира. Западнее - Штромгард (элитные мобы), туда не нужно.",
                   en = "South down the path into Faldir's Cove. Stromgarde to the west is full of elites - no need "
                       .. "to go there." } },
        { id = "h-41-faldir-s-cove", accept = 663, npc = 2766, at = { 1417, 31.78, 82.68 },
          note = { ru = "Бухта Фалдира, лагерь гоблинов: дозорный Лоло - «Эй, там!».",
                   en = "Faldir's Cove, the goblin camp: Lolo the Lookout - Land Ho!" } },
        { id = "h-41-trollbane-s-tomb", turnin = 663, npc = 2610, at = { 1417, 32.28, 81.38 },
          note = { ru = "Мураш О'Брин.", en = "Shakes O'Breen." } },
        { accept = 662, npc = 2767, at = { 1417, 32.80, 81.48 },
          note = { ru = "Первый помощник Нилзликс: «Поиски на глубине» - карты и журналы с двух затонувших кораблей.",
                   en = "First Mate Nilzlix: Deep Sea Salvage - the charts and logs of the two wrecks." } },
        { accept = 664, npc = 2769, at = { 1417, 34.00, 80.80 },
          note = { ru = "Капитан Стальные Нервы: «Затонувшие печали» - 10 налетчиков и 3 колдуньи Пронзающего Гребня.",
                   en = "Captain Steelgut: Drowned Sorrows - 10 Daggerspine Raiders and 3 Daggerspine Sorceresses." } },
        { accept = 665, complete = 665, npc = 2768, at = { 1417, 33.87, 80.55 },
          note = { ru = "Профессор Физзлторп: «Утонувшее сокровище» - проводите его к пещере и обратно (нападут "
                       .. "мстительные волноплески, 40).",
                   en = "Professor Phizzlethorpe: Sunken Treasure - escort him to the cave and back (Vengeful Surges, "
                       .. "40, attack)." } },
        { turnin = 665, accept = 666, npc = 2774, at = { 1417, 33.86, 80.45 },
          note = { ru = "Доктор Драксельмер: следующее «Утонувшее сокровище» - очки Ловца сокровищ.",
                   en = "Doctor Draxlegauge: the next Sunken Treasure - the Goggles of Gem Hunting." } },
        { complete = 664, bg = true, at = { 1417, 21.67, 87.05 },
          note = { ru = "Попутно: наги Пронзающего Гребня (38-40) вокруг затонувших кораблей к западу. Нет ещё 15 "
                       .. "отрезов шелка для «Попался!» (Тлеющее ущелье, 43) - собирайте с этих наг.",
                   en = "On the way: Daggerspine naga (38-40) around the wrecks to the west. Still short of 15 Silk "
                       .. "Cloth for Caught! (Searing Gorge, 43): loot it from these naga." } },
        { id = "h-41-arathi-highlands-field", complete = { [662] = { 1, 2 } }, object = { 2707, 2709 },
          at = { 1417, 23.22, 84.80 },
          note = { ru = "На запад, под воду: восточный корабль («Девичья Блажь») - карты и судовой журнал.",
                   en = "West, underwater: the eastern wreck (Maiden's Folly) - the charts and the log." } },
        { complete = { [662] = { 3, 4 } }, object = { 2708, 2710 }, at = { 1417, 20.56, 85.36 },
          note = { ru = "Западный корабль («Дух Серебряного бора») - карты и судовой журнал.",
                   en = "The western wreck (Spirit of Silverpine) - the charts and the log." } },
        { complete = 666, object = 2712, use = 4491, at = { 1417, 22.78, 88.17 },
          note = { ru = "Наденьте очки Ловца сокровищ (кнопка): окаменевшие эльфийские самоцветы видны на миникарте - "
                       .. "10 самоцветов на дне. Потом снова наденьте свой шлем.",
                   en = "Put on the Goggles of Gem Hunting (button): the Calcified Elven Gems show on the minimap - 10 "
                       .. "gems on the sea floor. Put your own helm back on afterwards." } },
        { turnin = 662, npc = 2767, at = { 1417, 32.80, 81.48 },
          note = { ru = "Обратно в бухту: Нилзликс.", en = "Back to the cove: Nilzlix." } },
        { turnin = 664, npc = 2769, at = { 1417, 34.00, 80.80 },
          note = { ru = "Капитан Стальные Нервы.", en = "Captain Steelgut." } },
        { turnin = 666, accept = 668, npc = 2774, at = { 1417, 33.86, 80.45 },
          note = { ru = "Драксельмер: сдайте самоцветы и очки.", en = "Draxlegauge: hand in the gems and the goggles." } },
        { id = "h-41-hammerfall", turnin = 668, accept = 669, npc = 2610, at = { 1417, 32.28, 81.38 },
          note = { ru = "Мураш О'Брин: «Утонувшее сокровище» - образец самоцвета командиру флота Морскому Рогу в "
                       .. "Пиратскую Бухту (позже, в Тернистой долине).",
                   en = "Shakes O'Breen: Sunken Treasure - the sample gem to Fleet Master Seahorn in Booty Bay (later, "
                       .. "in Stranglethorn)." } },

        ------------------------------------------------------------------
        -- Thandol Span -> Wetlands -> Loch Modan -> Badlands (41)
        ------------------------------------------------------------------
        { id = "h-42-arathi-end", go = true, radius = 60, at = { 1417, 45.50, 88.00 },
          note = { ru = "Обратно по тропе наверх и на юго-восток к мосту Тандола; по мосту на юг в Болотину (дворфы "
                       .. "Черного Железа у моста - серые).",
                   en = "Back up the path, then south-east to the Thandol Span; cross it south into the Wetlands (the "
                       .. "Dark Iron dwarves at the bridge are grey)." } },
        { id = "h41-wetlands", go = true, radius = 60, at = { 1437, 49.34, 41.76 },
          note = { ru = "Болотина: по дороге на юг мимо Дун Модра до кладбища в середине зоны.",
                   en = "Wetlands: south along the road past Dun Modr to the graveyard in the middle of the zone." } },
        { id = "h41-dun-algaz", go = true, radius = 60, at = { 1437, 48.85, 77.09 },
          note = { ru = "Дальше на юг в Дун Альгаз - проход в Лок Модан.",
                   en = "On south to Dun Algaz - the pass into Loch Modan." } },
        { id = "h41-loch-modan", go = true, radius = 60, at = { 1432, 32.56, 46.99 },
          note = { ru = "Лок Модан: по дороге на юг мимо заставы Альгаз; Телсамар (стража Альянса) объезжайте с "
                       .. "запада, у кладбища.",
                   en = "Loch Modan: south along the road past Algaz Station; go around Thelsamar (Alliance guards) "
                       .. "on its west side, by the graveyard." } },
        { id = "h41-badlands-pass", go = true, radius = 60, at = { 1432, 46.50, 77.50 },
          note = { ru = "На юго-восток к перевалу в Бесплодные земли.",
                   en = "South-east to the pass into the Badlands." } },

        ------------------------------------------------------------------
        -- Badlands 1: Rigglefuzz, Lotwil, Kargath (41-42)
        ------------------------------------------------------------------
        { id = "h-41-rigglefuzz-martek", accept = 703, npc = 2817, at = { 1418, 42.39, 52.93 },
          note = { ru = "Бесплодные земли: по дороге на юг мимо раскопок (элитные дворфы Тёмного Горна у Ульдамана - "
                       .. "держитесь дороги) до лагеря гоблинов на развилке: Ригглфазз - «Жареные крылышки канюка».",
                   en = "Badlands: south along the road past the dig sites (elite Shadowforge dwarves around Uldaman - "
                       .. "stay on the road) to the goblin camp at the crossroads: Rigglefuzz - Barbecued Buzzard "
                       .. "Wings." } },
        -- Optional group content: Uldaman (41-51), entrance 680 yards north of Rigglefuzz, by the road the route came
        -- down.
        { accept = 2418, npc = 2817, optional = true, at = { 1418, 42.39, 52.93 },
          note = { ru = "По желанию, если собрали группу в Ульдаман: у Ригглфазза же - «Камни Силы». Без группы - дальше "
                       .. "(шаги пропустятся сами).",
                   en = "Optional, if you have a group for Uldaman: Rigglefuzz again - Power Stones. No group: go on "
                       .. "(these steps skip themselves)." } },
        { id = "h41-uldaman", complete = 2418, optional = true, at = { 1418, 44.60, 12.10 },
          note = { ru = "Ульдаман (на север по дороге, вход 44.6, 12.1): камни Силы - с дворфов Тёмного Горна "
                       .. "(элита) у входа и внутри.",
                   en = "Uldaman (north along the road, entrance 44.6, 12.1): the Power Stones drop from the Shadowforge "
                       .. "dwarves (elite) at the entrance and inside." } },
        { turnin = 1106, accept = 1108, npc = 4618, at = { 1418, 42.22, 52.69 },
          note = { ru = "Мартек Изгнанник в 5 ярдах от Ригглфазза: письмо Физзла (из Тысячи Игл); возьмите «Индурий» - "
                       .. "10 чешуек индурия.",
                   en = "Martek the Exiled, 5 yards from Rigglefuzz: Fizzle's letter (from Thousand Needles); take "
                       .. "Indurium - 10 Indurium Flakes." } },
        { complete = 1108, at = { 1418, 50.08, 68.32 },
          note = { ru = "На юго-восток (~300 ярдов): костоломы (39-40) и шаманы (40-41) Каменного Свода у скал - 10 "
                       .. "чешуек индурия.",
                   en = "South-east (~300 yards): Stonevault Bonesnappers (39-40) and Shamans (40-41) by the rocks - 10 "
                       .. "Indurium Flakes." } },
        { turnin = 1108, accept = 1137, npc = 4618, at = { 1418, 42.22, 52.69 },
          note = { ru = "Обратно к Мартеку: возьмите «Новости для Физзла» (Мерцающая равнина, по пути в Танарис, h-46).",
                   en = "Back to Martek: take News for Fizzle (Shimmering Flats, on the way to Tanaris, h-46)." } },
        { id = "h-41-lotwil-veriatus-lucien", accept = 710, npc = 2921, at = { 1418, 25.95, 44.87 },
          note = { ru = "На запад по дороге: Лотвиль Вериатус - «Изучение стихий: Камень». «Охлаждение горячих голов», "
                       .. "«Гиро...чего?» и «Камень – лучшая одежка!» не берите (нужны изделия алхимика, инженера и "
                       .. "кузнеца).",
                   en = "West along the road: Lotwil Veriatus - Study of the Elements: Rock. Skip Coolant Heads "
                       .. "Prevail, Gyro... What? and Stone Is Better than Cloth (they need alchemy, engineering and "
                       .. "blacksmithing items)." } },
        { complete = 710, at = { 1418, 21.13, 45.46 },
          note = { ru = "Сразу западнее лагеря: младшие каменные элементали (37-39) - 10 маленьких осколков камня.",
                   en = "Just west of the camp: Lesser Rock Elementals (37-39) - 10 Small Stone Shards." } },
        { turnin = 710, accept = 711, npc = 2921, at = { 1418, 25.95, 44.87 },
          note = { ru = "Лотвиль.", en = "Lotwil." } },
        { complete = 711, at = { 1418, 14.46, 34.50 },
          note = { ru = "На северо-запад: каменные элементали (39-40) - 3 больших куска камня.",
                   en = "North-west: Rock Elementals (39-40) - 3 Large Stone Slabs." } },
        { id = "h-42-kargath-arrive", fp = "Kargath", npc = 2861, at = { 1418, 3.99, 44.78 },
          note = { ru = "На юго-запад в Каргат: Горрик - откройте карту полётов.",
                   en = "South-west to Kargath: Gorrik - open the flight map." } },
        { id = "h42-sethearth-kargath", sethearth = "Kargath", npc = 9356, at = { 1418, 2.82, 45.86 },
          note = { ru = "Хозяин таверны Шул'кар: камень возвращения - в Каргат.",
                   en = "Innkeeper Shul'kar: bind your hearthstone to Kargath." } },
        { accept = 782, npc = 1068, at = { 1418, 2.91, 45.60 },
          note = { ru = "Горн: «Разорванные союзы» - Знак Земли с главаря То'груна (огры Гнилобрюхов на юго-западе; "
                       .. "То'грун патрулирует юг зоны - бейте, где встретите).",
                   en = "Gorn: Broken Alliances - the Sign of the Earth from Boss Tho'grun (Dustbelcher ogres to the "
                       .. "south-west; he patrols the southern Badlands - kill him wherever you meet him)." } },
        { accept = 2258, npc = 6868, at = { 1418, 2.42, 46.06 },
          note = { ru = "Джаркал Замшелый Клык: «Пробежка по Бесплодным землям» - 5 вторых желудков канюка, 10 клыков "
                       .. "скального койота, 5 осколков каменного элементаля.",
                   en = "Jarkal Mossmeld: Badlands Reagent Run - 5 Buzzard Gizzards, 10 Crag Coyote Fangs, 5 Rock "
                       .. "Elemental Shards." } },
        { accept = { 1419, 1420 }, npc = 5394, at = { 1418, 6.49, 47.20 },
          note = { ru = "Ника Алый Шрам: «Койоты-воры» (30 челюстей) и «Донесение Хелгруму» (в Каменор, Болото Печали "
                       .. "- следующий сегмент).",
                   en = "Neeka Bloodscar: Coyote Thieves (30 jawbones) and Report to Helgrum (Stonard, Swamp of "
                       .. "Sorrows - next segment)." } },

        ------------------------------------------------------------------
        -- Badlands 2: Lotwil, the south-west loop, level gate (42-44)
        ------------------------------------------------------------------
        { turnin = 711, accept = 712, npc = 2921, at = { 1418, 25.95, 44.87 },
          note = { ru = "Обратно на восток к Лотвилю.", en = "Back east to Lotwil." } },
        { complete = 782, bg = true, at = { 1418, 12.62, 75.49 },
          note = { ru = "Попутно: главарь То'грун (41-42) ходит по югу зоны (лагерь огров, южная дорога до ~61,70, "
                       .. "мимо Ригглфазза, назад по y≈57) - встретили, убейте: Знак Земли.",
                   en = "On the way: Boss Tho'grun (41-42) walks the southern Badlands (the ogre camp, the south road "
                       .. "to ~61,70, past Rigglefuzz, back along y≈57) - met him, kill him: the Sign of the Earth." } },
        { id = "h-41-badlands-field-loop", complete = { [1419] = { 1 }, [703] = { 1 }, [2258] = { 1, 2 } },
          at = { 1418, 23.88, 63.47 },
          note = { ru = "На юг: старые скальные койоты (38-40) и гигантские канюки (39-41) - 30 челюстей, 10 клыков, "
                       .. "5 желудков и 4 крыла канюка.",
                   en = "South: Elder Crag Coyotes (38-40) and Giant Buzzards (39-41) - 30 jawbones, 10 fangs, 5 "
                       .. "gizzards and 4 buzzard wings." } },
        { complete = { [712] = { 1 }, [2258] = { 3 } }, at = { 1418, 3.98, 79.90 },
          note = { ru = "На юго-запад мимо лагеря огров Гнилобрюхов к западному краю: большие каменные элементали "
                       .. "(42-44) - 5 наручей Камня и 5 осколков каменного элементаля.",
                   en = "South-west past the Dustbelcher ogre camp to the west edge: Greater Rock Elementals (42-44) - "
                       .. "5 Bracers of Rock Binding and 5 Rock Elemental Shards." } },
        { complete = 782, at = { 1418, 12.62, 75.49 },
          note = { ru = "Лагерь огров Гнилобрюхов (40-43): главарь То'грун - Знак Земли. Он не стоит на месте: ходит по "
                       .. "кругу (~3000 ярдов, ~20 мин) - из лагеря на восток вдоль южной дороги (y 72-78) до ~61,70, на "
                       .. "северо-запад мимо Ригглфазза (42,53), на запад по y≈57 и обратно в лагерь с севера (11.5,69). "
                       .. "Нет в лагере - не ждите на месте: бейте огров и элементалей для гейта ниже, он вернётся.",
                   en = "The Dustbelcher ogre camp (40-43): Boss Tho'grun - the Sign of the Earth. He does not stand "
                       .. "still: he walks a ~3,000-yard loop (~20 min) - from the camp east along the southern road (y "
                       .. "72-78) to ~61,70, north-west past Rigglefuzz (42,53), west along y≈57 and back into the camp "
                       .. "from the north (11.5,69). Not in the camp: do not stand and wait - grind the ogres and "
                       .. "elementals for the gate below, he comes back." } },
        -- WARN-OK (level-grind, next step): the end-of-segment gate (south-west Badlands, ogres 40-43 and Greater Rock
        -- Elementals 42-44): 43 for Caught!, and the required turn-ins below make 44.0 at h-44-uc-arrive (training).
        { id = "h-41-arathi-badlands-level-gate", level = { 43, 0.80 }, at = { 1418, 8.35, 78.85 }, -- WARN-OK: level-grind
          note = { ru = "Цель: 43 + 80% (сдачи ниже и «Попался!» дадут 44 - обучение, Болото Печали и Тернистая "
                       .. "долина). Не хватает - огры Гнилобрюхов (40-43) и большие каменные элементали (42-44) здесь же: "
                       .. "плотно, быстрый респаун, лучшее место на 42-44 у Каргата. В группе быстрее: Ульдаман (вход на "
                       .. "севере зоны).",
                   en = "Target: 43 + 80% (the turn-ins below and Caught! make 44 - training, the Swamp of Sorrows and "
                       .. "Stranglethorn). Short: the Dustbelcher ogres (40-43) and Greater Rock Elementals (42-44) "
                       .. "right here - dense, quick respawns, the best 42-44 camp near Kargath. Faster in a group: "
                       .. "Uldaman (entrance in the north of the zone)." } },
        { id = "h-41-theldurin-the-lost", turnin = 703, npc = 2817, at = { 1418, 42.39, 52.93 },
          note = { ru = "На восток к Ригглфаззу.", en = "East to Rigglefuzz." } },
        { turnin = 2418, npc = 2817, optional = true, at = { 1418, 42.39, 52.93 },
          note = { ru = "Если были в Ульдамане: камни Силы.", en = "If you ran Uldaman: the Power Stones." } },
        { turnin = 712, npc = 2921, at = { 1418, 25.95, 44.87 },
          note = { ru = "Лотвиль. «Это будет непросто» не откроется (нужен «Гиро...чего?»).",
                   en = "Lotwil. This Is Going to Be Hard does not open (it needs Gyro... What?)." } },
        { turnin = 1419, npc = 5394, at = { 1418, 6.49, 47.20 },
          note = { ru = "Каргат: Ника.", en = "Kargath: Neeka." } },
        { turnin = 782, npc = 1068, at = { 1418, 2.91, 45.60 },
          note = { ru = "Горн. Следующие «Разорванные союзы» (50, элитные) не берите.",
                   en = "Gorn. Skip the next Broken Alliances (50, elites)." } },

        ------------------------------------------------------------------
        -- Searing Gorge next door: Caught! (43-44)
        ------------------------------------------------------------------
        { id = "h43-caught", accept = 4449, object = 173265, at = { 1427, 65.59, 62.17 },
          note = { ru = "Из Каргата на запад по каньону в Тлеющее ущелье (550 ярдов): деревянная уборная у раскопок - "
                       .. "«Попался!». Нужно 15 отрезов шелка: не продавайте шелк, собранный с гуманоидов.",
                   en = "From Kargath west through the canyon into the Searing Gorge (550 yards): the Wooden Outhouse by "
                       .. "the dig site - Caught! It needs 15 Silk Cloth: keep the silk looted from humanoids." } },
        { complete = 4449, at = { 1427, 63.30, 60.60 },
          note = { ru = "Вокруг раскопок: 8 геологов из клана Черного Железа (43-44).",
                   en = "Around the dig site: 8 Dark Iron Geologists (43-44)." } },
        { turnin = 4449, object = 173265, at = { 1427, 65.59, 62.17 },
          note = { ru = "Уборная: сдайте шелк. «Учетную книгу из Танариса» не берите (её вещи в трёх зонах). Обратно "
                       .. "по каньону в Каргат.",
                   en = "The outhouse: hand in the silk. Skip Ledger from Tanaris (its items are spread over three "
                       .. "zones). Back through the canyon to Kargath." } },
        { id = "h-44-kargath-end", turnin = 2258, npc = 6868, at = { 1418, 2.42, 46.06 },
          note = { ru = "Джаркал. «В Ульдаман за реактивом» - только для группы в Ульдаман.",
                   en = "Jarkal. Uldaman Reagent Run - only for an Uldaman group." } },
    },
})
