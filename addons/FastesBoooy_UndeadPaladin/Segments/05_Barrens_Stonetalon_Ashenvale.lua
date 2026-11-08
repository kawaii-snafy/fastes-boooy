-- FastesBoooy_UndeadPaladin / Segments / 05_Barrens_Stonetalon_Ashenvale.lua
--
-- Segment ud-05-stonetalon-ashenvale: The Crossroads -> Camp Taurajo -> Thunder Bluff (timed 853) ->
-- Ratchet -> Ishamuhale -> Stagnant Oasis -> hearth Camp Taurajo (Jorn / Mangletooth) -> Crossroads ->
-- Regthar + Lushwater -> Stonetalon Mountains (Camp Aparaje, Malaka'jin, Windshear Crag, Sun Rock) ->
-- fly Thunder Bluff (training 20) -> Ratchet -> Crossroads -> Stonetalon turn-ins -> Ashenvale
-- (Va'xug, Zoram'gar, Thistlefur Village) -> hearth Thunder Bluff (training 22), levels 18-22.
-- Coordinates: Forever uiMap 1413 (The Barrens) / 1412 (Mulgore) / 1456 (Thunder Bluff) / 1442
-- (Stonetalon Mountains) / 1440 (Ashenvale), map percent, from tools/data/forever_db.lua (NPC/object
-- spawns; centroids of the objective mob/object spawns of the chosen area for complete steps).
-- Path points: Mulgore gate 1412 64.34,63.53 and the Thunder Bluff lift 1456 31.78,65.92, the Sun Rock
-- ramp, the Stonetalon -> Ashenvale road and the Astranaar bypass are RestedXP reference facts.
--
-- Hub plan (Forever DB):
--   start : 853 Apothecary Zamah is TIMED (45 min) and was accepted at the end of ud-04 -> Thunder
--           Bluff first: fly Camp Taurajo, 3261 > 882 (Jorn), walk to Thunder Bluff,
--           853, level-18 training (Seal of Righteousness R3), flight path, fly to Ratchet.
--   east  : Ratchet 1483 (Sputtervalve), 865 > 1069 (Mebok), 888 (Gazlowe); 821 (keg, bg: matriarch
--           tusks + plainstrider kidneys at Ishamuhale); zhevra carcass -> Ishamuhale 882; Stagnant Oasis
--           880 shells + Verog 851 (+ Kolkar bracers 855); hearth.
--   CT    : 882 > 907 (Jorn), 878 (Mangletooth); main Bristleback camp NE of the camp: 878 + 899 tusks,
--           Stormsnout blood 907 (+ 821 horn); 878 > 5052; 907 > 913, a Thunderhawk Cloudscraper for 913;
--           fly to the Crossroads.
--   XR/W  : 899 + 880 > 1489 (Mankrik, Tonga); 851 > 852 (Regthar); Lushwater: Hezrul 852 + bracers 855;
--           Regthar.
--   ST 1  : Seereth 1062 + Makaba 6548; Grimtotems; 6548 > 6629; Grundig 6629 + Kaya escort 6523;
--           6629/6523 > 6401; Xen'Zilla 6461; creepers; Ziz 1483 > 1093; Windshear Crag: loggers 1062,
--           operators 1093, venomspitters 6461, eggs 1069; Ziz 1093 > 1094; Sun Rock: 6562, 6401,
--           flight path; fly Thunder Bluff (training 20, hearth); fly Ratchet: 821 (keg), 1094 > 1095,
--           1069.
--   ST 2  : fly Crossroads; Seereth 1062 > 1063; Xen'Zilla 6461; Windshear Mine: Piznik 1090 > 1092;
--           Ziz 1095 + 1092; Talondeep Path north to Ashenvale.
--   Ash   : Va'xug 98251 > 98252; road west past Astranaar; Zoram'gar 6562, 6442, 6462, flight
--           path; Zoram Strand naga 6442; 216 (req 21); Thistlefur Village 216 + troll chests 6462;
--           hearth to Thunder Bluff: 1063 > 1064, 1489 > 1490, 1490, 1064 > 1065, training 22.
-- Skipped: 875 > 876 > 1060 (harpies and Serena need two extra Crossroads round trips; ud-04 does not
--   take 875), 1068 Shredding Machines (needs 1062 turned in first, then a third Stonetalon border
--   trip), 4021 Counterattack (elite), 1491 Smart Drinks / 959 / 962 (Wailing Caverns), 868 Egg Hunt
--   (silithid swarms south of Camp Taurajo), 822 (third keg quest, 24), 6284 Arachnophobia (Besseleth, elite),
--   6421/6481 (Boulderslide Ravine, two Sun Rock round trips), 6301 (seeds north of Sun Rock), 6563 and
--   95042 (elite naga/satyrs at the Blackfathom Deeps entrance), 6641 Vorsha (group escort), 97250
--   (elite pillagers), 264 / 3301 (deliveries to Silverpine), 1096 Gerenzo (27), Splintertree.
-- Carried into the shared Horde 22-60 route (FastesBoooy_Horde, h-22-hillsbrad): 1065 Journey to Tarren Mill,
--   turned in at Tarren Mill (the library accepts 1065 itself only for Skyborne).
-- Hearthstone: bound to Camp Taurajo (ud-04) and used from the Stagnant Oasis; re-bound to Thunder
--   Bluff on the training-20 visit and used from Zoram'gar at the end.
-- Training: 18 (Seal of Righteousness R3) on the forced first Thunder Bluff visit (the validator arrives
--   at ~18.0 with no margin, with the optional keg quest 819 counted, so the note falls back to 20),
--   20 (Consecration, Holy Strike R3, Blessing of Kings, Devotion Aura R3, + SoR R3 if missed) from Sun
--   Rock, 22 (Blessing of Might R3, Holy Light R4) at the end. Alodan the Hopeful (ruRU Алодан
--   Жизнерадостный) wanders inside the Pools of Vision.
-- Level gates (real requirements, re-checked against the Classic XP table): 19 + 88% before leaving
--   Windshear (Ziz 1093 1650 + Tammra 6401 1000 = 2650 >= 12% of 21300: exactly 20 for training), 20 at
--   Tammra, 21 for 216 (with the naga), 21 + 85% at Thistlefur (216 + 6462 = 3900 >= 15% of 25200) and
--   22 at the last Zoram'gar turn-in (training 22).
-- XP budget: the validator credits 878's 30 kills and 899's 90 tusk kills (1.5 per tusk) separately,
--   although every 878 kill also drops a tusk, and it counts the optional keg quests 819/821 as done.
--   Re-run with 899 = 45-60 kills beyond 878 and without 821 (scratch copies, see the route doc): the
--   pre-20 gate is met (the former Windshear grind of ~47 kills is gone), the level-21 gate may need up
--   to ~13 naga kills, and the solo quest content (899 included, taken in ud-04 like RestedXP does) ends
--   near 21.15 at Thistlefur: a real grind of ~115 furbolg kills (~100 with 821, ~123 without any keg).
--
-- Automation notes: transient steps (fp, fly, hearth, sethearth, train) come after the quest steps at
-- the same place; a background goal is only followed by its stateful `complete` with no transient step
-- in between (6461, 1069), otherwise the engine's anchor could fast-forward a flight or the hearth.
-- Bracers 855 and the Verog head 851 only appear in combined steps here ({880, 851} at the Stagnant Oasis,
-- {852, 855} at Lushwater): the ud-04 bg goals for 851/855 may already be done, and a lone `complete 851`
-- would then be done at once and fast-forward the Thunder Bluff steps (flight path, training, flights).
-- The same goes for 899 (accepted in ud-04, tusks may drop early): it is only completed together with 878
-- (accepted at Camp Taurajo here) and turned in together with 880 (finished at the Stagnant Oasis here),
-- never in a step of its own. 821 (optional keg quest) only has bg steps (never anchors, hidden without
-- the quest): its items from Ratchet on, its turn-in at Drohn on the Ratchet visit after training 20.
-- A level gate never anchors on its own (Core/Engine.lua: `level` is no evidence of progress); next to a
-- quest action it anchors only once both are done, and every gate here shares its step with a quest action
-- that cannot be done early, so an early level-up never forwards the training / hearth steps before it.
FastesBoooy.AddSegment("horde-undead-paladin", {
    id = "ud-05-stonetalon-ashenvale",
    title = { ru = "18-22 Степи, Когтистые горы, Ясеневый лес", en = "18-22 Barrens, Stonetalon, Ashenvale" },
    zone = "Stonetalon Mountains",
    levels = { 18, 22 },
    steps = {
        ------------------------------------------------------------------
        -- The Crossroads -> Camp Taurajo -> Thunder Bluff (853 is timed, level 18)
        ------------------------------------------------------------------
        { id = "ud05-fly-taurajo", fly = "Camp Taurajo", at = { 1413, 44.45, 59.15 },
          note = { ru = "Таймер! «Аптекарь Зама» (853) — 45 минут с момента, как Хелбрим его выдал. Сразу к "
                       .. "Девраку на вышке и летите в Лагерь Таурахо, оттуда пешком в Громовой Утёс.",
                   en = "Timer! Apothecary Zamah (853) has 45 minutes from the moment Helbrim gave it. Go "
                       .. "straight to Devrak on the tower and fly to Camp Taurajo; walk on to Thunder "
                       .. "Bluff from there." } },
        { turnin = 3261, accept = 882, npc = 3387, at = { 1413, 44.86, 59.14 },
          note = { ru = "Йорн Небесный Провидец. Ишамухале (882) — позже, у Кабестана. Кривозуб в клетке "
                       .. "рядом — его задание возьмёте, когда вернётесь сюда.",
                   en = "Jorn Skyseer. Ishamuhale (882) is for later, near Ratchet. Mangletooth in the cage "
                       .. "next to him: take his quest when you come back here." } },
        { go = true, radius = 30, at = { 1412, 64.34, 63.53 },
          note = { ru = "На запад по дороге из лагеря в Мулгор.",
                   en = "West along the road out of the camp into Mulgore." } },
        { go = true, radius = 20, at = { 1456, 31.78, 65.92 },
          note = { ru = "Через равнины Мулгора на северо-запад к Громовому Утёсу, наверх на лифте.",
                   en = "North-west across the Mulgore plains to Thunder Bluff; take the lift up." } },
        { go = true, radius = 15, at = { 1456, 28.5, 29.0 },
          note = { ru = "По мостам на Вершину Духов: вход в пещеру Пруды Видений под ней.",
                   en = "Over the bridges to Spirit Rise: the Pools of Vision cave entrance is below it." } },
        { turnin = 853, npc = 3419, at = { 1456, 22.81, 20.89 },
          note = { ru = "Аптекарь Зама в пещере. Награда: любое зелье (Зелье стремительности — для бегства). "
                       .. "Таймер истёк — бросьте 853 (гайд сам пропустит шаги).",
                   en = "Apothecary Zamah in the cave. Reward: any potion (Swiftness Potion helps to escape). "
                       .. "Timer ran out: abandon 853 (the guide skips its steps)." } },
        { id = "ud05-train-18", train = true, npc = 246344, at = { 1456, 25.81, 19.03 },
          spells = { { ru = "Печать праведности (ранг 3)", en = "Seal of Righteousness (Rank 3)" } },
          note = { ru = "Тренер паладинов Алодан Жизнерадостный бродит по этой же пещере. Нужен 18-й уровень "
                       .. "(Печать праведности 3 — главный ранг урона); не хватает — выучите на 20-м вместе с "
                       .. "остальным. Пропустили Свет небес 3 на 14-м — возьмите здесь. Освящение и "
                       .. "Благословение королей будут на 20-м.",
                   en = "Alodan the Hopeful wanders in the same cave. Needs level 18 (Seal of Righteousness R3, "
                       .. "the main damage rank); not there yet: train it at 20 with the rest. Missed Holy "
                       .. "Light R3 at 14: train it here. Consecration and Blessing of Kings come at 20." } },
        { id = "ud05-fp-tb", fp = "Thunder Bluff", npc = 2995, at = { 1456, 47.00, 49.83 },
          note = { ru = "На центральную вершину: Тал у вышки — откройте карту полётов.",
                   en = "Up to the central mesa: Tal at the tower, open the flight map." } },
        { id = "ud05-fly-ratchet", fly = "Ratchet", at = { 1413, 63.08, 37.16 },
          note = { ru = "Летите в Кабестан (через Перекрёсток).", en = "Fly to Ratchet (via the Crossroads)." } },

        ------------------------------------------------------------------
        -- Ratchet, Ishamuhale, the Stagnant Oasis (level 18-19)
        ------------------------------------------------------------------
        { accept = 1483, npc = 3442, at = { 1413, 62.98, 37.22 },
          note = { ru = "Спаттервальв у полётов.", en = "Sputtervalve by the flight master." } },
        { turnin = 865, accept = 1069, npc = 3446, at = { 1413, 62.37, 37.62 },
          note = { ru = "Мебок Миззирикс. «Умные напитки» не берите (Пещеры Стенаний). Яйца пауков (1069) — в "
                       .. "Когтистых горах. Бочонок Чэня нашёлся только после прошлого визита в Кабестан? "
                       .. "Начните задание из него и сдайте пивовару Дрону рядом; возьмите и 821.",
                   en = "Mebok Mizzyrix. Skip Smart Drinks (Wailing Caverns). The spider eggs (1069) are in "
                       .. "Stonetalon. Found Chen's Empty Keg only after the last Ratchet visit? Start the quest "
                       .. "from it and hand it to Brewmaster Drohn next door; take 821 as well." } },
        { complete = 821, bg = true, at = { 1413, 61.4, 33.0 },
          note = { ru = "Если взяли 821 (бочонок Чэня): 5 клыков равнинного льва — с матриархов саванны у сухого "
                       .. "дерева Ишамухале, 5 почек долгонога — с долгоногов там же, рог рокочущей ящерицы — "
                       .. "с грозорылов у Лагеря Таурахо (907).",
                   en = "If you took 821 (Chen's keg): 5 Savannah Lion Tusks from the Savannah Matriarchs around "
                       .. "Ishamuhale's dead tree, 5 Plainstrider Kidneys from the plainstriders there, the "
                       .. "Thunder Lizard Horn from the Stormsnouts near Camp Taurajo (907)." } },
        { turnin = 888, npc = 3391, at = { 1413, 62.68, 36.23 },
          note = { ru = "Газлоу. Награда: Сапоги из пластин (кольчуга). Ещё держите 896 с изумрудом — сдайте "
                       .. "Диззивигу на пристани; без изумруда бросьте 896.",
                   en = "Gazlowe. Reward: Padded Lamellar Boots (mail). Still have 896 with the emerald? Hand "
                       .. "it to Dizzywig on the pier; without the emerald abandon 896." } },
        { collect = { [10338] = 1 }, at = { 1413, 59.99, 32.18 },
          note = { ru = "К северо-западу от Кабестана: убейте любую зебру — Свежая туша зебры (живёт 30 мин).",
                   en = "North-west of Ratchet: kill any zhevra for a Fresh Zhevra Carcass (lasts 30 min)." } },
        { complete = 882, use = 10338, npc = 3257, at = { 1413, 59.80, 30.60 },
          note = { ru = "Сухое дерево: используйте тушу у него — придёт Ишамухале (19). Его клык.",
                   en = "The dead tree: use the carcass by it, Ishamuhale (19) comes to the meat. Loot his "
                       .. "fang." } },
        { complete = { 880, 851 }, at = { 1413, 55.0, 42.4 },
          note = { ru = "На юго-запад к Застойному оазису: 8 изменённых панцирей с черепах в воде. Бейте и "
                       .. "колкаров вокруг (наручи для 855): с каждого есть шанс, что выйдет Верог Дервиш (18), "
                       .. "его голова для 851. Голова уже есть — ищите только панцири.",
                   en = "South-west to the Stagnant Oasis: 8 Altered Snapjaw Shells from the snapjaws in the "
                       .. "water. Kill the Kolkar around it too (bracers for 855): every kill may bring out "
                       .. "Verog the Dervish (18), his head is for 851. Head already looted: just the shells." } },
        { id = "ud05-hearth-taurajo", hearth = "Camp Taurajo", at = { 1413, 45.58, 59.04 },
          note = { ru = "Камень возвращения в Лагерь Таурахо. Ещё на откате — бегите на север к Перекрёстку "
                       .. "и летите.",
                   en = "Hearth to Camp Taurajo. Still on cooldown: run north to the Crossroads and fly." } },

        ------------------------------------------------------------------
        -- Camp Taurajo: Jorn and Mangletooth (level 19)
        ------------------------------------------------------------------
        { turnin = 882, accept = 907, npc = 3387, at = { 1413, 44.86, 59.14 } },
        { accept = 878, npc = 3430, at = { 1413, 44.55, 59.26 },
          note = { ru = "Свинобраз Кривозуб в клетке рядом.", en = "Mangletooth in the cage next to him." } },
        { complete = { 878, 899 }, at = { 1413, 51.5, 55.0 },
          note = { ru = "Главный лагерь Дыбогривов к северо-востоку от Лагеря Таурахо: 6 водоискателей, "
                       .. "12 терноплетов, 12 геомантов (878). С каждого Дыбогрива (иногда и с налётчиков "
                       .. "Иглогривых) падают клыки — бейте всех, пока не наберёте 60 (899). Сохраните один "
                       .. "Осколок крови.",
                   en = "The main Bristleback camp north-east of Camp Taurajo: 6 Water Seekers, 12 Thornweavers, "
                       .. "12 Geomancers (878). Every Bristleback (and maybe the Razormane Raiders) drops "
                       .. "Bristleback Quilboar Tusks: keep killing until you have 60 (899). Keep one Blood "
                       .. "Shard." } },
        { complete = 907, at = { 1413, 47.40, 52.96 },
          note = { ru = "На обратном пути на запад: грозорылы (громовые ящеры) бродят между лагерями Дыбогривов "
                       .. "— 3 крови (и рог рокочущей ящерицы, если взяли 821). Серый кодо Лакота'мани тоже "
                       .. "ходит тут — его копыто начинает задание для Йорна.",
                   en = "On the way back west: Stormsnouts (thunder lizards) roam between the Bristleback camps "
                       .. "- 3 Thunder Lizard Blood (and the Thunder Lizard Horn if you took 821). The grey kodo "
                       .. "Lakota'mani walks here too: his hoof starts a quest for Jorn." } },
        { turnin = 878, accept = 5052, npc = 3430, at = { 1413, 44.55, 59.26 } },
        { complete = 5052, turnin = 5052, npc = 3430, at = { 1413, 44.55, 59.26 },
          note = { ru = "Сразу отдайте один Осколок крови. Лишние осколки — на усиления у Кривозуба.",
                   en = "Hand over one Blood Shard right away. Spare shards buy buffs from Mangletooth." } },
        { turnin = 907, accept = 913, npc = 3387, at = { 1413, 44.86, 59.14 } },
        { complete = 913, at = { 1413, 47.33, 62.40 },
          note = { ru = "Громовые ястребы-облакорезы кружат к юго-востоку от лагеря: убейте одного ради крыльев. "
                       .. "Редкий Оватанка (синий ястреб) — его шип тоже начинает задание для Йорна.",
                   en = "Thunderhawk Cloudscrapers circle south-east of the camp: kill one for the wings. The "
                       .. "rare Owatanka (blue thunderhawk) drops a spike that starts a quest for Jorn too." } },
        { turnin = 913, npc = 3387, at = { 1413, 44.86, 59.14 },
          note = { ru = "Награда: щит или посох — оба не для двуручного паладина, берите что дороже продаётся. "
                       .. "Нашли копыто/шип — начните задание из предмета и сдайте Йорну.",
                   en = "Reward: a shield or a staff, neither is for a 2H paladin: take the one that sells "
                       .. "for more. Found the hoof or the spike: start the quest from the item and hand it to "
                       .. "Jorn." } },
        { id = "ud05-fly-xr", fly = "The Crossroads", at = { 1413, 51.50, 30.34 },
          note = { ru = "Омуса: летите на Перекрёсток.", en = "Omusa: fly to the Crossroads." } },

        ------------------------------------------------------------------
        -- The Crossroads, Regthar, the Lushwater Oasis (level 19)
        ------------------------------------------------------------------
        { turnin = { 899, 880 }, accept = 1489, npc = { 3432, 3448 }, at = { 1413, 52.26, 31.93 },
          note = { ru = "Сначала Манкрик (899, клыки), потом Тонга Рунный Тотем рядом (880). 1489 сдаётся в "
                       .. "Громовом Утёсе в конце сегмента.",
                   en = "Mankrik first (899, the tusks), then Tonga Runetotem next to him (880). 1489 is turned "
                       .. "in at Thunder Bluff at the end of the segment." } },
        { turnin = 851, accept = 852, npc = 3389, at = { 1413, 45.34, 28.41 },
          note = { ru = "На запад к Регтару Вратам Смерти.", en = "West to Regthar Deathgate." } },
        { complete = { 852, 855 }, npc = 3396, at = { 1413, 46.04, 41.14 },
          note = { ru = "На юг к оазису Lushwater: Хезрул Кровавая Метка (19) с охраной ходит вокруг воды. "
                       .. "Доберите 15 наручей с колкаров тут же.",
                   en = "South to the Lushwater Oasis: Hezrul Bloodmark (19) with guards walks around the "
                       .. "water. Finish the 15 Centaur Bracers on the Kolkar here." } },
        { turnin = { 852, 855 }, npc = 3389, at = { 1413, 45.34, 28.41 },
          note = { ru = "Регтар. Награда за 855: Молот Каменного леса (двуручная булава, лучше Плавникового "
                       .. "крушителя). «Контратаку!» (элитный) не берите.",
                   en = "Regthar. Reward for 855: Stonewood Hammer (2H mace, better than the Driftwood "
                       .. "Smasher). Skip Counterattack! (elite)." } },

        ------------------------------------------------------------------
        -- Stonetalon Mountains, first pass: Camp Aparaje, Malaka'jin (level 19-20)
        ------------------------------------------------------------------
        { accept = { 1062, 6548 }, npc = { 4049, 11857 }, at = { 1413, 35.22, 27.82 },
          note = { ru = "На запад к входу в Когтистые горы: Сирет Камнелом и Макаба Плоское Копыто.",
                   en = "West to the Stonetalon border: Seereth Stonebreak and Makaba Flathoof." } },
        { complete = 6548, at = { 1442, 82.41, 87.18 },
          note = { ru = "Сразу за границей: 8 головорезов и 6 наёмников Зловещего Тотема в лагере.",
                   en = "Just past the border: 8 Grimtotem Ruffians and 6 Mercenaries in the camp." } },
        { turnin = 6548, accept = 6629, npc = 11857, at = { 1413, 35.19, 27.76 } },
        { complete = 6629, npc = 11858, at = { 1442, 73.65, 86.12 },
          note = { ru = "На запад: 6 громил Зловещего Тотема по пути и Грундиг Тёмное Облако (18) у "
                       .. "хижины, где держат Каю.",
                   en = "West: 6 Grimtotem Brutes on the way and Grundig Darkcloud (18) at the hut where Kaya "
                       .. "is held." } },
        { accept = 6523, npc = 11856, at = { 1442, 73.48, 85.59 },
          note = { ru = "Кая Плоское Копыто: сопровождение начнётся сразу.",
                   en = "Kaya Flathoof: the escort starts at once." } },
        { complete = 6523, at = { 1442, 76.7, 90.9 },
          note = { ru = "Ведите Каю к лагерю Апарадже. По пути выскочат трое из Зловещего Тотема — бейте их, "
                       .. "пока они не убили Каю.",
                   en = "Walk Kaya to Camp Aparaje. Three Grimtotems ambush on the way: kill them before "
                       .. "they kill her." } },
        { turnin = { 6629, 6523 }, accept = 6401, npc = 11857, at = { 1413, 35.19, 27.76 },
          note = { ru = "Макаба. 6401 — в Приют Солнечного Камня.", en = "Makaba. 6401 goes to Sun Rock Retreat." } },
        { accept = 6461, npc = 12816, at = { 1442, 71.25, 95.02 },
          note = { ru = "На юго-запад в Малака'джин: Ксен'Зилла.", en = "South-west to Malaka'jin: Xen'Zilla." } },
        { complete = 6461, bg = true, at = { 1442, 63.35, 83.86 },
          note = { ru = "Попутно: 10 глубокомшистых ползунов (по пути на северо-запад к Зизу) и 7 плевунов "
                       .. "(у Зиза и Windshear Crag).",
                   en = "Along the way: 10 Deepmoss Creepers (on the way north-west to Ziz) and 7 Deepmoss "
                       .. "Venomspitters (around Ziz and Windshear Crag)." } },

        ------------------------------------------------------------------
        -- Ziz Fizziks and Windshear Crag (level 20)
        ------------------------------------------------------------------
        { turnin = 1483, accept = 1093, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = { ru = "На северо-запад к хижине Зиза Физзикса.", en = "North-west to Ziz Fizziks' hut." } },
        { complete = 1069, bg = true, at = { 1442, 62.07, 60.81 },
          note = { ru = "Попутно: 15 яиц глубокомшистых пауков у корней деревьев (здесь и в Windshear Crag). "
                       .. "Из яиц иногда вылезает паук.",
                   en = "Along the way: 15 Deepmoss Eggs at the foot of the trees (here and in Windshear "
                       .. "Crag). A spider sometimes hatches." } },
        { complete = { 1062, 1093 }, at = { 1442, 67.13, 51.23 },
          note = { ru = "Windshear Crag (вырубка Торговой компании): 15 лесорубов; операторы — чертежи "
                       .. "Супержнеца 6000. Шредеры XT:4 и XT:9 (23) ходят по вырубке — обходите.",
                   en = "Windshear Crag (Venture Co. logging): 15 Venture Co. Loggers; Operators drop the "
                       .. "Super Reaper 6000 Blueprints. Shredders XT:4 and XT:9 (23) patrol the camp: avoid "
                       .. "them." } },
        -- Safety gate: normally already met after the Camp Taurajo quilboar block (899); 6461 objective 1
        -- (Deepmoss Creepers) is not part of it: no creeper spawns near Ziz (the nearest are 340 yd south).
        { id = "ud05-lvl-pre20", complete = { [6461] = { 2 }, 1069 }, level = { 19, 0.88 }, at = { 1442, 61.63, 61.56 },
          note = { ru = "Доберите моховых ядоплюев и коконы по дороге обратно к Зизу. Проверка перед тренировкой: "
                       .. "сдачи у Зиза и в Приюте дадут ~12% уровня, а тренеру нужен 20-й. Обычно уже есть "
                       .. "19-й + 88%; не хватает — добейте ядоплюев, лесорубов и операторов здесь, в Приюте "
                       .. "бить некого. Ползуны из густого мха (6461) — только к югу от Зиза (60.8, 71.9) и у "
                       .. "Малака'джина: доберите их по дороге к Ксен'Зилле.",
                   en = "Finish the Deepmoss Venomspitters and the eggs on the way back to Ziz. Pre-training "
                       .. "check: the Ziz and Sun Rock turn-ins add ~12% of a level and the trainer needs 20. "
                       .. "Normally you already have 19 + 88%; if short, kill more venomspitters, loggers and "
                       .. "operators here, there is nothing to kill at Sun Rock. Deepmoss Creepers (6461) are "
                       .. "only south of Ziz (60.8, 71.9) and around Malaka'jin: finish them on the way back "
                       .. "to Xen'Zilla." } },
        { turnin = 1093, accept = 1094, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = { ru = "1094 — в Кабестан (полетите туда из Громового Утёса).",
                   en = "1094 goes to Ratchet (you fly there from Thunder Bluff)." } },

        ------------------------------------------------------------------
        -- Sun Rock Retreat, Thunder Bluff training 20, Ratchet (level 20)
        ------------------------------------------------------------------
        { go = true, radius = 20, at = { 1442, 49.96, 61.04 },
          note = { ru = "На запад к Приюту Солнечного Камня: подъём с восточной стороны.",
                   en = "West to Sun Rock Retreat: the ramp climbs from the east side." } },
        { accept = 6562, npc = 11862, at = { 1442, 47.36, 64.25 },
          note = { ru = "Цунаман (Приют Солнечного Камня). 6562 сдаётся в Ясеневом лесу.",
                   en = "Tsunaman (Sun Rock Retreat). 6562 is turned in in Ashenvale." } },
        { id = "ud05-lvl-20", turnin = 6401, level = 20, npc = 11864, at = { 1442, 47.46, 58.38 },
          note = { ru = "Таммра Ветряное Поле. «Цикл возрождения» не берите. Для тренировки нужен 20-й — должен "
                       .. "быть после этой сдачи.",
                   en = "Tammra Windfield. Skip Cycle of Rebirth. Training needs level 20: you should have it "
                       .. "after this turn-in." } },
        { id = "ud05-fp-sunrock", fp = "Sun Rock Retreat", npc = 4312, at = { 1442, 45.12, 59.84 },
          note = { ru = "Тарм: откройте карту полётов.", en = "Tharm: open the flight map." } },
        { id = "ud05-fly-tb", fly = "Thunder Bluff", at = { 1456, 47.00, 49.83 },
          note = { ru = "Летите в Громовой Утёс.", en = "Fly to Thunder Bluff." } },
        { go = true, radius = 15, at = { 1456, 28.5, 29.0 },
          note = { ru = "Пруды Видений под Вершиной Духов.", en = "The Pools of Vision under Spirit Rise." } },
        { id = "ud05-train-20", train = true, npc = 246344, at = { 1456, 25.81, 19.03 },
          spells = { { ru = "Освящение", en = "Consecration" },
                     { ru = "Священный удар (ранг 3)", en = "Holy Strike (Rank 3)" },
                     { ru = "Благословение королей", en = "Blessing of Kings" },
                     { ru = "Аура благочестия (ранг 3)", en = "Devotion Aura (Rank 3)" },
                     { ru = "Печать праведности (ранг 3)", en = "Seal of Righteousness (Rank 3)" } },
          note = { ru = "Тренер паладинов Алодан Жизнерадостный: обучение 20-го уровня (и Печать праведности 3, "
                       .. "если не выучили на 18-м). Талант — Стремление к справедливости.",
                   en = "Alodan the Hopeful: level-20 training (plus Seal of Righteousness R3 if you missed it "
                       .. "at 18). Talent: Pursuit of Justice." } },
        { id = "ud05-sethearth-tb", sethearth = "Thunder Bluff", npc = 6746, at = { 1456, 45.81, 64.71 },
          note = { ru = "Трактирщица Пала: сделайте Громовой Утёс домом (в конце вернётесь сюда камнем).",
                   en = "Innkeeper Pala: make Thunder Bluff your home (you hearth back here at the end)." } },
        { id = "ud05-fly-ratchet-2", fly = "Ratchet", at = { 1413, 63.08, 37.16 },
          note = { ru = "Тал: летите в Кабестан.", en = "Tal: fly to Ratchet." } },
        { turnin = 821, bg = true, npc = 3292, at = { 1413, 62.26, 38.39 },
          note = { ru = "Если брали 821: сдайте его пивовару Дрону рядом с Мебоком (следующее, 822, не берите).",
                   en = "If you took 821: turn it in to Brewmaster Drohn next to Mebok (skip the next one, "
                       .. "822)." } },
        { turnin = 1094, accept = 1095, npc = 3442, at = { 1413, 62.98, 37.22 },
          note = { ru = "Спаттервальв. 1095 — обратно Зизу.", en = "Sputtervalve. 1095 goes back to Ziz." } },
        { turnin = 1069, npc = 3446, at = { 1413, 62.37, 37.62 },
          note = { ru = "Мебок Миззирикс.", en = "Mebok Mizzyrix." } },
        { id = "ud05-fly-xr-2", fly = "The Crossroads", at = { 1413, 51.50, 30.34 },
          note = { ru = "Брагок: летите на Перекрёсток.", en = "Bragok: fly to the Crossroads." } },

        ------------------------------------------------------------------
        -- Stonetalon Mountains, second pass: turn-ins, road to Ashenvale (level 20)
        ------------------------------------------------------------------
        { turnin = 1062, accept = 1063, npc = 4049, at = { 1413, 35.26, 27.88 },
          note = { ru = "На запад к Сирет Камнелом (мимо Регтара). «Машины-измельчители» не берите — "
                       .. "пришлось бы возвращаться сюда.",
                   en = "West to Seereth Stonebreak (past Regthar). Skip Shredding Machines: it would need "
                       .. "another trip back here." } },
        { turnin = 6461, npc = 12816, at = { 1442, 71.25, 95.02 },
          note = { ru = "Ксен'Зилла в Малака'джине.", en = "Xen'Zilla in Malaka'jin." } },
        { go = true, radius = 15, at = { 1442, 73.78, 59.52 },
          note = { ru = "На север долиной к руднику Windshear (вход на восточном краю вырубки).",
                   en = "North up the valley to the Windshear Mine (entrance on the east side of the logging "
                       .. "camp)." } },
        { accept = 1090, npc = 4276, at = { 1442, 71.87, 60.00 },
          note = { ru = "Пизник в руднике (кобольды 20-22 вокруг). Сначала расчистите место рядом с ним.",
                   en = "Piznik inside the mine (kobolds 20-22 around). Clear the area next to him first." } },
        { complete = 1090, at = { 1442, 71.87, 60.00 },
          note = { ru = "Охраняйте Пизника 5 минут: волны кобольдов на 0:15 (3), 2:15 (4, два заклинателя) и "
                       .. "3:20 (4). Освящение под ногами, Возложение рук на крайний случай. Провалили — "
                       .. "возьмите задание заново.",
                   en = "Guard Piznik for 5 minutes: kobold waves at 0:15 (3), 2:15 (4, two casters) and 3:20 "
                       .. "(4). Consecration under your feet, Lay on Hands for emergencies. Failed: take the "
                       .. "quest again." } },
        { turnin = 1090, accept = 1092, npc = 4276, at = { 1442, 71.87, 60.00 },
          note = { ru = "1092 — руду Зизу.", en = "1092: the ore goes to Ziz." } },
        { turnin = { 1095, 1092 }, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = { ru = "На запад к Зизу Физзиксу. «Гернезо Гаечносвист» (27) не берите.",
                   en = "West to Ziz Fizziks. Skip Gerenzo Wrenchwhistle (27)." } },
        { go = true, radius = 20, at = { 1442, 78.29, 42.51 },
          note = { ru = "На северо-восток через вырубку к тоннелю Talondeep Path — дорога в Ясеневый лес. "
                       .. "Шредеры XT:4 и XT:9 (23) обходите.",
                   en = "North-east across the logging camp to the Talondeep Path, the road into Ashenvale. "
                       .. "Avoid the XT:4 and XT:9 shredders (23)." } },

        ------------------------------------------------------------------
        -- Ashenvale: Va'xug, the road west, Zoram'gar (level 20-21)
        ------------------------------------------------------------------
        { accept = 98251, npc = 267214, at = { 1440, 40.46, 61.42 },
          note = { ru = "Ва'кзуг Огненный Мех у дороги.", en = "Va'xug Firefure by the road." } },
        { complete = 98251, at = { 1440, 41.93, 62.64 },
          note = { ru = "Вокруг: 6 чернорогих оленей и 6 ясеневых медведей.",
                   en = "All around: 6 Shadowhorn Stags and 6 Ashenvale Bears." } },
        { turnin = 98251, accept = 98252, npc = 267214, at = { 1440, 40.46, 61.42 } }, -- WARN-OK: xp-unknown, Forever-new
        { complete = 98252, at = { 1440, 38.93, 57.92 },
          note = { ru = "Идите на главную дорогу к северо-западу — Око Килрогга летит за вами.",
                   en = "Walk north-west to the main road; the Eye of Kilrogg follows you." } },
        { turnin = 98252, npc = 271181, at = { 1440, 38.5, 58.2 }, -- WARN-OK: xp-unknown, Forever-new
          note = { ru = "Поговорите с Оком Килрогга на дороге.", en = "Talk to the Eye of Kilrogg on the road." } },
        { go = true, radius = 25, at = { 1440, 34.14, 53.61 },
          note = { ru = "На запад по дороге. До Астранаара сверните с неё — стража ночных эльфов нападает.",
                   en = "West along the road. Leave it before Astranaar: the night elf guards attack." } },
        { go = true, radius = 25, at = { 1440, 18.43, 32.94 },
          note = { ru = "Лесом на северо-запад, Астранаар остаётся восточнее.",
                   en = "Through the forest to the north-west, keeping Astranaar to the east." } },
        { turnin = 6562, npc = 12736, at = { 1440, 11.56, 34.29 },
          note = { ru = "Застава Зорам'гар: Дже'ней Санкрея. «Сущность Аку'Май» не берите (вход в Непроглядную "
                       .. "Пучину, элитные).",
                   en = "Zoram'gar Outpost: Je'neu Sancrea. Skip The Essence of Aku'Mai (Blackfathom Deeps "
                       .. "entrance, elites)." } },
        { accept = { 6442, 6462 }, npc = { 12719, 12721 }, at = { 1440, 11.67, 34.88 },
          note = { ru = "Марукаи и Митсува. «Ворша Хлестатель» не берите (групповое сопровождение).",
                   en = "Marukai and Mitsuwa. Skip Vorsha the Lasher (group escort)." } },
        { id = "ud05-fp-zoram", fp = "Zoram'gar Outpost", npc = 11901, at = { 1440, 12.24, 33.80 },
          note = { ru = "Андрук: откройте карту полётов.", en = "Andruk: open the flight map." } },
        { id = "ud05-lvl-21", complete = 6442, level = 21, at = { 1440, 11.31, 27.08 },
          note = { ru = "На север по Зорамскому взморью: 20 голов наг Wrathtail. Редкая Леди Веспия (22) "
                       .. "патрулирует берег. Следующему заданию (Чертополох) нужен 21-й: не хватает — бейте наг "
                       .. "дальше.",
                   en = "North along the Zoram Strand: 20 Wrathtail Heads from the naga. The rare Lady "
                       .. "Vespia (22) patrols the shore. The next quest (Thistlefur) needs level 21: short of it, "
                       .. "keep killing naga." } },
        { turnin = 6442, npc = 12719, at = { 1440, 11.69, 34.91 },
          note = { ru = "Марукаи.", en = "Marukai." } },

        ------------------------------------------------------------------
        -- Thistlefur Village, back to Zoram'gar, hearth to Thunder Bluff (level 21-22)
        ------------------------------------------------------------------
        { accept = 216, npc = 12757, at = { 1440, 11.90, 34.54 },
          note = { ru = "Каранг Амаккар.", en = "Karang Amakkar." } },
        { complete = 216, at = { 1440, 32.11, 41.46 },
          note = { ru = "На восток к деревне фурболгов Thistlefur: 8 мстителей и 8 шаманов (23-24). Тяните по "
                       .. "одному, шаманы лечат.",
                   en = "East to Thistlefur Village: 8 Avengers and 8 Shamans (23-24). Pull one at a time, "
                       .. "the shamans heal." } },
        { complete = 6462, object = 178144, at = { 1440, 40.74, 33.58 },
          note = { ru = "Северо-восточный край деревни, у входа в логово: 8 амулетов троллей из сундуков.",
                   en = "The north-east end of the village by the hold: 8 Troll Charms from the Troll "
                       .. "Chests." } },
        -- Grind gate: the solo quest content (899 included) ends near 21.15 here; RXP grinds to the same point
        -- (21 + ~87%). The validator's ~85 kills are low (878 kills counted twice, keg quest 821 counted).
        { id = "ud05-lvl-grind", complete = 216, level = { 21, 0.85 }, at = { 1440, 36.5, 36.0 }, -- WARN-OK: level-grind, ~115 kills
          note = { ru = "До 22-го квестов не хватает: добивайте фурболгов в деревне (23-24 — больше всего опыта; "
                       .. "по 2 с Освящением) до 21-го + 85%. Сдача 216 и 6462 в Зорам'гаре добавит ещё ~15% — "
                       .. "это и есть 22-й. Убивали всё по пути — шаг уже выполнен.",
                   en = "The quests alone fall short of 22: keep killing furbolgs in the village (23-24 give the "
                       .. "most XP; two at a time with Consecration) up to level 21 + 85%. The 216 and 6462 "
                       .. "turn-ins at Zoram'gar add another ~15%, which makes 22. Killed everything on the way: "
                       .. "the step is already done." } },
        { turnin = 216, npc = 12757, at = { 1440, 11.90, 34.54 },
          note = { ru = "Обратно на запад в Зорам'гар. «Король Скверноболья» не берите.",
                   en = "Back west to Zoram'gar. Skip King of the Foulweald." } },
        { id = "ud05-lvl-22", turnin = 6462, level = 22, npc = 12721, at = { 1440, 11.65, 34.85 },
          note = { ru = "Митсува. Для тренировки нужен 22-й. Чуть не хватает — наги на взморье к северу.",
                   en = "Mitsuwa. Training needs level 22. A little short: the naga on the strand to the north." } },
        { id = "ud05-hearth-tb", hearth = "Thunder Bluff", at = { 1456, 45.81, 64.71 },
          note = { ru = "Камень возвращения в Громовой Утёс. На откате — летите у Андрука.",
                   en = "Hearth to Thunder Bluff. On cooldown: fly from Andruk." } },

        ------------------------------------------------------------------
        -- Thunder Bluff: turn-ins and level-22 training (level 22)
        ------------------------------------------------------------------
        { turnin = 1063, accept = 1064, npc = 4046, at = { 1456, 69.85, 30.91 },
          note = { ru = "Вершина Старейшин: Магата Зловещий Тотем.", en = "Elder Rise: Magatha Grimtotem." } },
        { turnin = 1489, accept = 1490, npc = 5769, at = { 1456, 78.62, 28.56 },
          note = { ru = "Верховный друид Хамуул Рунический Тотем.", en = "Arch Druid Hamuul Runetotem." } },
        { turnin = 1490, npc = 5770, at = { 1456, 75.65, 31.61 },
          note = { ru = "Нара Дикая Грива. «Предводители Клыка» не берите (Пещеры Стенаний).",
                   en = "Nara Wildmane. Skip Leaders of the Fang (Wailing Caverns)." } },
        { go = true, radius = 15, at = { 1456, 28.5, 29.0 },
          note = { ru = "Через центральную вершину на Вершину Духов, вниз в Пруды Видений.",
                   en = "Across the central mesa to Spirit Rise, down into the Pools of Vision." } },
        { turnin = 1064, accept = 1065, npc = 3419, at = { 1456, 22.81, 20.89 }, -- 1065: turned in at Tarren Mill (h-22)
          note = { ru = "Аптекарь Зама. 1065 ведёт в Мельницу Таррен (Предгорья Хилсбрада) — следующая зона "
                       .. "после 22-го.",
                   en = "Apothecary Zamah. 1065 leads to Tarren Mill (Hillsbrad Foothills), the next zone after "
                       .. "level 22." } },
        { id = "ud05-end", train = true, npc = 246344, at = { 1456, 25.81, 19.03 },
          spells = { { ru = "Благословение могущества (ранг 3)", en = "Blessing of Might (Rank 3)" },
                     { ru = "Свет небес (ранг 4)", en = "Holy Light (Rank 4)" } },
          note = { ru = "Тренер паладинов Алодан Жизнерадостный: обучение 22-го уровня. Талант 22 — Печать "
                       .. "повиновения. Дальше общий маршрут Орды: Оргриммар, Подгород, Хилсбрад.",
                   en = "Alodan the Hopeful: level-22 training. Talent at 22: Seal of Command. Next: the shared Horde "
                       .. "route - Orgrimmar, Undercity, Hillsbrad." } },
    },
})
