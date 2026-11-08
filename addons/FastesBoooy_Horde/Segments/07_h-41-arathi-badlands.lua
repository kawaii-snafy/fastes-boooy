-- FastesBoooy_Horde / Segments/07_h-41-arathi-badlands.lua
--
-- Library segment "h-41-arathi-badlands": levels 41-44, class-neutral (Undead Paladin and Skyborne Druid, Horde).
-- Brackenwall Village -> hearth Orgrimmar -> zeppelin to Tirisfal -> Undercity (232 > 238 > 243) -> fly Hammerfall ->
-- across Arathi to Faldir's Cove (663, 662, 664, 665 > 666 > 668 > 669) -> Thandol Span -> Wetlands (Dun Modr, Dun
-- Algaz) -> Loch Modan (west of Thelsamar) -> Badlands: Rigglefuzz (703), Lotwil (710 > 711 > 712), Kargath (flight
-- point, hearth, 782, 2258, 1419, 1420), the south-west loop (coyotes, buzzards, Dustbelcher ogres, Greater Rock
-- Elementals, level gate) -> Rigglefuzz -> Lotwil -> Kargath.
-- Plan: research plan60.md section 4.7 / plan60.json segments[7] (anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1454 (Orgrimmar) / 1411 (Durotar) / 1420 (Tirisfal Glades) / 1458 (Undercity) / 1417
-- (Arathi Highlands) / 1437 (Wetlands) / 1432 (Loch Modan) / 1418 (Badlands), map percent, from
-- tools/data/forever_db.lua: NPC / object spawns for npc / object steps, centroids of the objective mob / object
-- spawns of the area used for complete steps (h41 tools: research scratch h41/cen.lua, h41/box.lua). Travel points
-- (not checked in game): Hammerfall south-west exit, the Arathi spirit healer 6491 south of Refuge Pointe, south of
-- the Circle of Inner Binding (Thenan), the path down into Faldir's Cove, the north end of the Thandol Span (next to
-- the Dark Iron camp; the Wetlands saboteurs on the bridge at 50.9,8.2 convert to Arathi 45.2,93.4), the Wetlands
-- spirit healer 6491 (49.3,41.8), Dun Algaz (Dragonmaw scouts 48.9,77.1), the Loch Modan spirit healer 6491 west of
-- Thelsamar and the south road to the Badlands (Loch Modan 46.5,77.5 = Badlands 47.6,4.2 by the QuestieDB world
-- bounds).
-- ruRU names in the notes: Wowhead Forever ruRU tooltips (nether.wowhead.com/forever/ru/tooltip/...).
--
-- Hub plan (Forever DB; every quest is open to Scourge and Skyborne Horde characters of any class):
--   UC   : 232 (Zinge) > Luca 238 > Zinge 243 (carried to Gadgetzan, h-46); fly Hammerfall.
--   AR   : Hammerfall (pass through) -> Faldir's Cove: 663 (Lolo > Shakes), 662 (Nilzlix), 664 (Steelgut), 665
--          (Phizzlethorpe escort) > 666 (Draxlegauge); wrecks (662), Daggerspine naga (664), Elven Gems (666);
--          662, 664, 666 > 668 > 669 (Shakes; carried to Booty Bay, h-44).
--   BL 1 : Rigglefuzz 703; Lotwil 710, Lesser Rock Elementals, Lotwil 710 > 711, Rock Elementals (north-west);
--          Kargath: fp, hearth, 782 (Gorn), 2258 (Jarkal), 1419 + 1420 (Neeka; 1420 carried to Stonard, h-44).
--   BL 2 : Lotwil 711 > 712; south-west loop: Elder Crag Coyotes + Giant Buzzards (1419, 2258 gizzards / fangs, 703),
--          Boss Tho'grun (782), Greater Rock Elementals (712, 2258 shards), level gate; Rigglefuzz 703, Lotwil 712,
--          Kargath 1419, 782, 2258.
-- Deviations from the plan (documented in the handoff):
--   * The Arathi quests of the plan that need elite kills are not taken (Wowhead Forever tooltips: Elite; DB rank 1):
--     639 Sigil of Strom (Syndicate 35-38) and with it 640 / 641 / 643 / 644 / 645 / 646 (Stromgarde guards 37-40,
--     Lieutenant Valorcall 38, Prince Galen Trollbane 44), 673 Foul Magics (Marez Cowl 40), 679 Call to Arms /
--     680 The Real Threat (Boulderfist Shamans / Lords 38-40, Or'Kalar 40). 651 Stones of Binding (left over from
--     h-31) is skipped too: four stones across the whole zone for 2,850 XP, the turn-in stone stands next to the elite
--     Thenan (42), and its follow-up 652 needs the elite Fozruk (42) - so 688 / 687 / 692 (Theldurin) are out.
--     Hammerfall is only the flight point; the plan anchors of these places sit on the nearest route steps
--     (h-41-stone-of-inner, h-41-keystone: travel steps; h-41-trollbane-s-tomb: 663 at Shakes; h-41-hammerfall:
--     the last Arathi turn-in, 668 at Shakes).
--   * Badlands: 713 / 714 / 716 need crafted items (Frost Oil - alchemy, Gyrochronatom - engineering, Patterned
--     Bronze Bracers - blacksmithing) and are not taken; Lotwil gives 710 > 711 > 712 only. Added 703 Barbecued
--     Buzzard Wings (Rigglefuzz, on the road; the wings drop from the Giant Buzzards of 2258). 709 Solution to Doom
--     (Theldurin, far south, chest at the Uldaman excavation in the north) and 2418 Power Stones (elite Shadowforge)
--     are skipped; Theldurin is not visited (h-41-theldurin-the-lost sits on the Rigglefuzz turn-in, the closest
--     route step).
--   * No hearth use in the Badlands: the hearthstone is bound to Kargath and left off cooldown for h-44.
-- XP (validator, Classic quest XP + objective kills with the DB counts): quests ~38 k, objective kills ~19 k:
--   questing alone ends near 41.4 instead of 44 (plan: 42.1 with the elite Arathi quests). The level gate in the
--   south-west (Dustbelcher ogres 40-43 and Greater Rock Elementals 42-44, the best non-elite camp for 42-44 near
--   Kargath) covers the rest (~246 k XP, ~960 same-level kills in the validator's model; fewer in game with the mobs
--   killed on the way and rested XP); the turn-ins after it make 44.0. Group alternative: Uldaman (entrance north
--   Badlands 44.6, 12.1).
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
        { id = "h-41-undercity-flight-master", fly = "Hammerfall", npc = 2851, at = { 1417, 73.02, 32.70 },
          note = { ru = "Майкл Гарретт: летите в Павший Молот.", en = "Michael Garrett: fly to Hammerfall." } },

        ------------------------------------------------------------------
        -- Arathi: Hammerfall -> Faldir's Cove (41)
        ------------------------------------------------------------------
        { id = "h-41-hammerfall-arrive", go = true, radius = 25, at = { 1417, 71.50, 35.50 },
          note = { ru = "Павший Молот: остальные задания здесь (печати Штромгарда, «Зловещая магия», «К оружию!», "
                       .. "«Настоящая угроза») - на элитных мобов, их пропускаем. Выезжайте на юго-запад.",
                   en = "Hammerfall: its remaining quests (the Stromgarde sigils, Foul Magics, Call to Arms, The Real "
                       .. "Threat) need elite kills - skipped. Ride out to the south-west." } },
        { id = "h41-arathi-center", go = true, radius = 60, at = { 1417, 48.84, 55.61 },
          note = { ru = "Через нагорье на юго-запад, южнее Опорного пункта (Альянс, стража).",
                   en = "South-west across the highlands, south of Refuge Pointe (Alliance guards)." } },
        { id = "h-41-stone-of-inner", go = true, radius = 60, at = { 1417, 37.00, 61.00 },
          note = { ru = "Южнее каменного круга: у связующих камней стоит Тенан (элитный великан, 42) - не подходите.",
                   en = "South of the Circle of Inner Binding: Thenan (elite giant, 42) stands at the stones - keep "
                       .. "away." } },
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
          note = { ru = "Попутно: наги Пронзающего Гребня (38-40) вокруг затонувших кораблей к западу.",
                   en = "On the way: Daggerspine naga (38-40) around the wrecks to the west." } },
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
          note = { ru = "Горн: «Разорванные союзы» - Знак Земли с главаря То'груна (огры Гнилобрюхов на юго-западе).",
                   en = "Gorn: Broken Alliances - the Sign of the Earth from Boss Tho'grun (Dustbelcher ogres to the "
                       .. "south-west)." } },
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
        { id = "h-41-badlands-field-loop", complete = { [1419] = { 1 }, [703] = { 1 }, [2258] = { 1, 2 } },
          at = { 1418, 23.88, 63.47 },
          note = { ru = "На юг: старые скальные койоты (38-40) и гигантские канюки (39-41) - 30 челюстей, 10 клыков, "
                       .. "5 желудков и 4 крыла канюка.",
                   en = "South: Elder Crag Coyotes (38-40) and Giant Buzzards (39-41) - 30 jawbones, 10 fangs, 5 "
                       .. "gizzards and 4 buzzard wings." } },
        { complete = 782, at = { 1418, 12.62, 75.49 },
          note = { ru = "На юго-запад в лагерь огров Гнилобрюхов (40-43): главарь То'грун - Знак Земли.",
                   en = "South-west into the Dustbelcher ogre camp (40-43): Boss Tho'grun - the Sign of the Earth." } },
        { complete = { [712] = { 1 }, [2258] = { 3 } }, at = { 1418, 3.98, 79.90 },
          note = { ru = "Западнее: большие каменные элементали (42-44) - 5 наручей Камня и 5 осколков каменного "
                       .. "элементаля.",
                   en = "Further west: Greater Rock Elementals (42-44) - 5 Bracers of Rock Binding and 5 Rock "
                       .. "Elemental Shards." } },
        -- WARN-OK (level-grind, next step): the end-of-segment gate of the plan (south-west Badlands, ogres 40-43 and
        -- Greater Rock Elementals 42-44).
        { id = "h-41-arathi-badlands-level-gate", level = { 43, 0.86 }, at = { 1418, 8.35, 78.85 }, -- WARN-OK: grind
          note = { ru = "Цель: 43 + 86% (сдачи ниже дадут 44 - уровень Болота Печали и Тернистой долины). Не хватает - "
                       .. "огры Гнилобрюхов (40-43) и большие каменные элементали (42-44) здесь же: плотно, быстрый "
                       .. "респаун, лучшее место на 42-44 у Каргата. В группе быстрее: Ульдаман (вход на севере зоны).",
                   en = "Target: 43 + 86% (the turn-ins below make 44, the level for the Swamp of Sorrows and "
                       .. "Stranglethorn). Short: the Dustbelcher ogres (40-43) and Greater Rock Elementals (42-44) "
                       .. "right here - dense, quick respawns, the best 42-44 camp near Kargath. Faster in a group: "
                       .. "Uldaman (entrance in the north of the zone)." } },
        { id = "h-41-theldurin-the-lost", turnin = 703, npc = 2817, at = { 1418, 42.39, 52.93 },
          note = { ru = "На восток к Ригглфаззу.", en = "East to Rigglefuzz." } },
        { turnin = 712, npc = 2921, at = { 1418, 25.95, 44.87 },
          note = { ru = "Лотвиль. «Это будет непросто» не откроется (нужен «Гиро...чего?»).",
                   en = "Lotwil. This Is Going to Be Hard does not open (it needs Gyro... What?)." } },
        { turnin = 1419, npc = 5394, at = { 1418, 6.49, 47.20 },
          note = { ru = "Каргат: Ника.", en = "Kargath: Neeka." } },
        { turnin = 782, npc = 1068, at = { 1418, 2.91, 45.60 },
          note = { ru = "Горн. Следующие «Разорванные союзы» (50, элитные) не берите.",
                   en = "Gorn. Skip the next Broken Alliances (50, elites)." } },
        { id = "h-44-kargath-end", turnin = 2258, npc = 6868, at = { 1418, 2.42, 46.06 },
          note = { ru = "Джаркал. «В Ульдаман за реактивом» - только для группы в Ульдаман.",
                   en = "Jarkal. Uldaman Reagent Run - only for an Uldaman group." } },
    },
})
