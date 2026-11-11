-- FastesBoooy_Guides / Segments / Shared / 18_Stonetalon_Ashenvale.lua
--
-- Segment "h-18-stonetalon-ashenvale": levels 18-22, all races. The Crossroads -> Camp Taurajo -> Thunder Bluff
-- (timed 853) -> Ratchet -> Ishamuhale -> Stagnant Oasis -> hearth Camp Taurajo (Jorn / Mangletooth) -> Crossroads
-- -> Lushwater + Regthar -> harpy lieutenants -> Stonetalon Mountains (Camp Aparaje, Malaka'jin, Windshear Crag,
-- Sun Rock) -> fly Thunder Bluff (bind, Elder Rise) -> Ratchet -> Crossroads -> Stonetalon turn-ins -> Ashenvale
-- (Va'xug, Zoram'gar, Thistlefur Village) -> hearth Thunder Bluff. Order of the former Undead segment
-- ud-05-stonetalon-ashenvale with the extras of the Skyborne one (875, optional 884 / 6641, Piznik optional): three
-- Thunder Bluff stops at 18, 20 and 22 give every class with a trainer there a class-neutral training stop.
-- Coordinates: Forever uiMap 1413 (The Barrens) / 1412 (Mulgore) / 1456 (Thunder Bluff) / 1442 (Stonetalon
-- Mountains) / 1440 (Ashenvale), map percent, from tools/data/forever_db.lua (NPC / object spawns; centroids of
-- the objective mob / object spawns of the chosen area for complete steps). Path points: Mulgore gate 1412
-- 64.34,63.53 and the Thunder Bluff lift 1456 31.78,65.92, the Sun Rock ramp, the Stonetalon -> Ashenvale road
-- and the Astranaar bypass are RestedXP reference facts.
--
-- Hub plan:
--   start : 853 Apothecary Zamah is TIMED (45 min) and was accepted at the end of h-15 -> Thunder Bluff first:
--           fly Camp Taurajo, 3261 > 882 (Jorn), gate h18-lvl-18, then Thunder Bluff: by flight (Skyborne,
--           Tauren: they know the point) or on foot (Orc, Scourge, Troll); 853 (Zamah) first, then Tal: the
--           walkers learn the flight point there (h18-fp-tb), everybody flies to Ratchet.
--   east  : Ratchet 865 (Mebok), 888 (Gazlowe); 821 (keg, bg: matriarch tusks + plainstrider kidneys at
--           Ishamuhale); zhevra carcass -> Ishamuhale 882; Stagnant Oasis 880 shells (+ Kolkar bracers 855);
--           hearth.
--   CT    : 882 > 907 (Jorn); main Bristleback camp NE of the camp: 878 + 899 tusks, Stormsnout blood 907 (+ 821
--           horn); 878 > 5052; 907 > 913, a Thunderhawk Cloudscraper for 913 (Owatanka 884, optional, bg); fly
--           to the Crossroads.
--   XR/W  : 899 + 880 > 1489 (Mankrik, Tonga); Lushwater: Hezrul 852 + bracers 855; Regthar; Witchwing Slayers
--           875 on the way to the border.
--   ST 1  : Seereth 1062 + Makaba 6548; Grimtotems; 6548 > 6629; Grundig 6629 + Kaya escort 6523; 6629/6523 >
--           6401; Xen'Zilla 6461; creepers; Ziz 1483 > 1093; Windshear Crag: loggers 1062, operators 1093; gate
--           h18-lvl-20 (still at the Crag); venomspitters 6461 and eggs 1069 on the way back; Ziz 1093 > 1094;
--           Sun Rock: 6562, 6401, flight path; fly Thunder Bluff (bind; Elder Rise 1489 > 1490); fly Ratchet: 821
--           (keg), 1094 > 1095, 1069.
--   ST 2  : fly Crossroads (875); Seereth 1062 > 1063; Xen'Zilla 6461; Windshear Mine: Piznik 1090 > 1092
--           (optional); Ziz 1095 (+ 1092); Talondeep Path north to Ashenvale.
--   Ash   : Va'xug 98251 > 98252; road west past Astranaar; Zoram'gar 6562, 6442, 6462, flight path; optional
--           Vorsha escort 6641; Zoram Strand naga 6442; gate h18-lvl-21 (216 needs 21); Thistlefur Village 216 +
--           troll chests 6462; gate h18-lvl-22; hearth to Thunder Bluff: 1063 > 1064 (Magatha), 1064 (Zamah).
-- End state (what h-22-hillsbrad assumes): in Thunder Bluff at Zamah, hearth Thunder Bluff, level 22, flight
--   points Thunder Bluff, The Crossroads, Camp Taurajo, Ratchet, Sun Rock Retreat, Zoram'gar Outpost, The
--   Sepulcher, Undercity, Orgrimmar; 1064, 5052, 913, 1095, 6562 turned in; 1065 is accepted by the first step of
--   h-22-hillsbrad (the same NPC); 6301 Cycle of Rebirth is done in h-24.
-- Race-filtered alternatives (Thunder Bluff 1; join: h18-tb-zamah): h18-fly-tb-1 (Skyborne, Tauren) /
--   h18-go-mulgore, h18-go-tb-lift (Orc, Scourge, Troll). The third filtered step of the walkers, h18-fp-tb, stands
--   after the join, right before h18-fly-ratchet: they pass Tal once, on the way out (lift > Pools > Zamah > Tal is
--   664 yd of straight legs; lift > Tal > Pools > Zamah > Tal is 840 yd and a second climb of the tower, with the
--   45-minute timer of 853 still running on the first visit). docs/dev/PLAN.md B.6 lists the step before the join.
-- Level gates (class-neutral; docs/dev/PLAN.md B.8):
--   h18-lvl-18  trainer-hub gate at Camp Taurajo, before Thunder Bluff 1.
--   h18-lvl-20  19 + 88 % before leaving Windshear Crag (Ziz 1093 1650 + Tammra 6401 1000 = 2650 >= 12 % of
--               21300: exactly 20 at Thunder Bluff 2). It stands before the venomspitter step, which walks back to
--               Ziz: the Crag has 70 Venture Co. spawns of 18-20 within 300 yd, around Ziz there are only the
--               venomspitters (17-18, 11 spawns). The venomspitter kills that follow are not counted on.
--   h18-lvl-21  requirement gate: 216 needs 21 (with the naga).
--   h18-lvl-22  21 + 85 % at Thistlefur Village (216 + 6462 = 3900 >= 15 % of 25200): 22 at Thunder Bluff 3 and
--               for h-22-hillsbrad.
-- Additions by other files: Races/Skyborne.lua (optional 1061 turn-in before h18-border); class files (training in
--   Thunder Bluff after h18-tb-zamah / h18-tb-1, h18-tb-2, h18-tb-3 / h18-end; the druid's Moonglade visits before
--   h18-hearth-taurajo and h18-hearth-tb and the Cat Form chain after h18-tb-2).
-- Anchors (never renamed): h18-fly-taurajo, h18-lvl-18, h18-fly-tb-1, h18-fp-tb, h18-tb-zamah, h18-tb-1,
--   h18-fly-ratchet, h18-ratchet, h18-hearth-taurajo, h18-taurajo-end, h18-fly-xroads, h18-xr, h18-border,
--   h18-lvl-20, h18-fp-sunrock, h18-fly-tb, h18-sethearth-tb, h18-tb-2, h18-fly-ratchet-2, h18-fly-xroads-2,
--   h18-fp-zoram, h18-lvl-21, h18-lvl-22, h18-hearth-tb, h18-tb-3, h18-end.
-- Skipped: 876 Serena > 1060 (875's follow-up: a second trip to the north-west Barrens), 1068 Shredding Machines
--   (needs 1062 turned in first, then a third Stonetalon border trip), 4021 Counterattack (elite), 1491 Smart
--   Drinks / 959 / 962 (Wailing Caverns), 868 Egg Hunt (silithid swarms south of Camp Taurajo), 822 (third keg
--   quest, 24), 6284 Arachnophobia (Besseleth, elite), 6421 / 6481 (Boulderslide Ravine), 6563 and 95042 (elite
--   naga / satyrs at the Blackfathom Deeps entrance), 97250 (elite pillagers), 264 / 3301 (deliveries to
--   Silverpine), 1096 Gerenzo (27), Splintertree.
-- Hearthstone: bound to Camp Taurajo (h-15) and used from the Stagnant Oasis; re-bound to Thunder Bluff on the
--   second visit and used from Zoram'gar at the end.
-- XP budget: the validator credits 878's 30 kills and 899's 90 tusk kills (1.5 per tusk) separately, although
--   every 878 kill also drops a tusk, and it counts the optional keg quests 819 / 821 as done.
--
-- Automation notes: transient steps (fp, fly, hearth, sethearth) come after the quest steps at the same place; a
-- background goal is only followed by its stateful `complete` with no transient step in between (6461, 1069),
-- otherwise the engine's anchor could fast-forward a flight or the hearth. Bracers 855 only appear in a combined
-- step here ({852, 855} at Lushwater): the h-15 bg goal may already be done. 899 (accepted in h-15, tusks may drop
-- early) is only completed together with 878 and turned in together with 880 (finished at the Stagnant Oasis
-- here), never in a step of its own. 821 (optional keg quest) only has bg steps (never anchors, hidden without
-- the quest). The level gates are plain `level` steps: a gate never anchors on its own (Core/Engine.lua: `level`
-- is no evidence of progress), so an early level-up never forwards the travel steps before it.
if not FastesBoooy.AddLibraryInsert then return end
FastesBoooy.AddLibrarySegment({
    id = "h-18-stonetalon-ashenvale",
    title = { ru = "18-22 Степи, Когтистые горы, Ясеневый лес", en = "18-22 Barrens, Stonetalon, Ashenvale" },
    zone = "Stonetalon Mountains",
    levels = { 18, 22 },
    steps = {

        ------------------------------------------------------------------
        -- The Crossroads -> Camp Taurajo -> Thunder Bluff (853 is timed, level 18)
        ------------------------------------------------------------------
        { id = "h18-fly-taurajo", fly = "Camp Taurajo", at = { 1413, 44.45, 59.15 },
          note = { ru = "Таймер! «Аптекарь Зама» (853) - 45 минут с момента, как Хелбрим его выдал. Сразу к Девраку на вышке и летите "
                       .. "в Лагерь Таурахо.",
                   en = "Timer! Apothecary Zamah (853) has 45 minutes from the moment Helbrim gave it. Go straight to Devrak on the "
                       .. "tower and fly to Camp Taurajo." } },
        { id = "h18-jorn", turnin = 3261, accept = 882, npc = 3387, at = { 1413, 44.86, 59.14 },
          note = { ru = "Йорн Небесный Провидец. Ишамухале (882) - позже, у Кабестана.",
                   en = "Jorn Skyseer. Ishamuhale (882) is for later, near Ratchet." } },
        -- Trainer-hub gate (docs/dev/PLAN.md B.8): Thunder Bluff follows; the 853 timer leaves about 25 minutes here.
        { id = "h18-lvl-18", level = 18, at = { 1413, 46.0, 57.5 },
          note = { ru = "18-й уровень: новые ранги у тренеров в Громовом Утёсе. Не хватает - зебры и грозорылы вокруг лагеря или "
                       .. "Дыбогривы к северо-востоку (их клыки и сами убийства идут в 899 и 878). Таймер 853 идёт: на дорогу до Замы "
                       .. "оставьте 15 минут.",
                   en = "Level 18: new ranks at the trainers in Thunder Bluff. Short of it: zhevras and Stormsnouts around the camp, "
                       .. "or the Bristlebacks to the north-east (their tusks and the kills count for 899 and 878). The 853 timer is "
                       .. "running: keep 15 minutes for the way to Zamah." } },
        -- Alternative pair: races that know the Thunder Bluff flight point fly, the others walk (and learn the point
        -- after Zamah, h18-fp-tb). Join: h18-tb-zamah.
        { id = "h18-fly-tb-1", race = { "Skyborne", "Tauren" }, fly = "Thunder Bluff", npc = 2995, at = { 1456, 47.00, 49.83 },
          note = {
              ru = "Омуса Громовой Рог: летите в Громовой Утёс.",
              en = "Omusa Thunderhorn: fly to Thunder Bluff.",
          } },
        { id = "h18-go-mulgore", race = { "Orc", "Scourge", "Troll" }, go = true, radius = 30, at = { 1412, 64.34, 63.53 },
          note = { ru = "На запад по дороге из лагеря в Мулгор.",
                   en = "West along the road out of the camp into Mulgore." } },
        { id = "h18-go-tb-lift", race = { "Orc", "Scourge", "Troll" }, go = true, radius = 20, at = { 1456, 31.78, 65.92 },
          note = { ru = "Через равнины Мулгора на северо-запад к Громовому Утёсу, наверх на лифте. Сначала к Заме (таймер); "
                       .. "точку полёта у Тала возьмёте на обратном пути.",
                   en = "North-west across the Mulgore plains to Thunder Bluff; take the lift up. Zamah first (the timer); you "
                       .. "learn the flight point at Tal on the way back." } },
        { id = "h18-go-pools", go = true, radius = 15, at = { 1456, 28.5, 29.0 },
          note = { ru = "По мостам на Вершину Духов: вход в пещеру Пруды Видений под ней.",
                   en = "Over the bridges to Spirit Rise: the Pools of Vision cave entrance is below it." } },
        { id = "h18-tb-zamah", turnin = 853, npc = 3419, at = { 1456, 22.81, 20.89 },
          note = { ru = "Аптекарь Зама в пещере. Награда: любое зелье (Зелье стремительности — для бегства). "
                       .. "Таймер истёк — бросьте 853 (гайд сам пропустит шаги).",
                   en = "Apothecary Zamah in the cave. Reward: any potion (Swiftness Potion helps to escape). "
                       .. "Timer ran out: abandon 853 (the guide skips its steps)." } },
        { id = "h18-tb-1", go = true, radius = 15, at = { 1456, 28.5, 29.0 },
          note = { ru = "Обратно наверх из Прудов Видений на Вершину Духов. Тренеры классов Громового Утёса - сейчас; затем к Талу на "
                       .. "центральную вершину.",
                   en = "Back up out of the Pools of Vision to Spirit Rise. Class trainers of Thunder Bluff now; then to Tal on the "
                       .. "central mesa." } },
        -- The walkers learn the flight point here, where they leave (one visit to Tal, see the header).
        { id = "h18-fp-tb", race = { "Orc", "Scourge", "Troll" }, fp = "Thunder Bluff", npc = 2995, at = { 1456, 47.00, 49.83 },
          note = { ru = "На центральной вершине: Тал у вышки - откройте карту полётов, чтобы узнать точку.",
                   en = "On the central mesa: Tal at the tower - open the flight map to learn the point." } },
        { id = "h18-fly-ratchet", fly = "Ratchet", at = { 1413, 63.08, 37.16 },
          note = { ru = "Тал на центральной вершине: летите в Кабестан (через Перекрёсток).",
                   en = "Tal on the central mesa: fly to Ratchet (via the Crossroads)." } },

        ------------------------------------------------------------------
        -- Ratchet, Ishamuhale, the Stagnant Oasis (level 18-19)
        ------------------------------------------------------------------
        { id = "h18-mebok", turnin = 865, npc = 3446, at = { 1413, 62.37, 37.62 },
          note = { ru = "Мебок Миззирикс: рога. «Умные напитки» не берите (Пещеры Стенаний). Бочонок Чэня нашёлся только после "
                       .. "прошлого визита в Кабестан? Начните задание из него и сдайте пивовару Дрону рядом; возьмите и 821.",
                   en = "Mebok Mizzyrix: the horns. Skip Smart Drinks (Wailing Caverns). Found Chen's Empty Keg only after the last "
                       .. "Ratchet visit? Start the quest from it and hand it to Brewmaster Drohn next door; take 821 as well." } },
        { id = "h18-keg-items", complete = 821, bg = true, at = { 1413, 61.4, 33.0 },
          note = { ru = "Если взяли 821 (бочонок Чэня): 5 клыков равнинного льва — с матриархов саванны у сухого "
                       .. "дерева Ишамухале, 5 почек долгонога — с долгоногов там же, рог рокочущей ящерицы — "
                       .. "с грозорылов у Лагеря Таурахо (907).",
                   en = "If you took 821 (Chen's keg): 5 Savannah Lion Tusks from the Savannah Matriarchs around "
                       .. "Ishamuhale's dead tree, 5 Plainstrider Kidneys from the plainstriders there, the "
                       .. "Thunder Lizard Horn from the Stormsnouts near Camp Taurajo (907)." } },
        { id = "h18-ratchet", turnin = 888, npc = 3391, at = { 1413, 62.68, 36.23 },
          note = { ru = "Газлоу. Ещё держите 896 с изумрудом - сдайте Диззивигу на пристани; без изумруда бросьте 896.",
                   en = "Gazlowe. Still have 896 with the emerald? Hand it to Dizzywig on the pier; without the emerald abandon 896." } },
        { id = "h18-carcass", collect = { [10338] = 1 }, at = { 1413, 59.99, 32.18 },
          note = { ru = "К северо-западу от Кабестана: убейте любую зебру — Свежая туша зебры (живёт 30 мин).",
                   en = "North-west of Ratchet: kill any zhevra for a Fresh Zhevra Carcass (lasts 30 min)." } },
        { id = "h18-ishamuhale", complete = 882, use = 10338, npc = 3257, at = { 1413, 59.80, 30.60 },
          note = { ru = "Сухое дерево: используйте тушу у него — придёт Ишамухале (19). Его клык.",
                   en = "The dead tree: use the carcass by it, Ishamuhale (19) comes to the meat. Loot his "
                       .. "fang." } },
        { id = "h18-shells", complete = 880, at = { 1413, 55.0, 42.4 },
          note = { ru = "На юго-запад к Застойному оазису: 8 изменённых панцирей с черепах в воде. Попутно бейте колкаров вокруг "
                       .. "(наручи для 855).",
                   en = "South-west to the Stagnant Oasis: 8 Altered Snapjaw Shells from the snapjaws in the water. Kill the Kolkar "
                       .. "around it on the way (bracers for 855)." } },
        { id = "h18-hearth-taurajo", hearth = "Camp Taurajo", at = { 1413, 45.58, 59.04 },
          note = { ru = "Камень возвращения в Лагерь Таурахо. Ещё на откате — бегите на север к Перекрёстку "
                       .. "и летите.",
                   en = "Hearth to Camp Taurajo. Still on cooldown: run north to the Crossroads and fly." } },

        ------------------------------------------------------------------
        -- Camp Taurajo: Jorn and Mangletooth (level 19)
        ------------------------------------------------------------------
        { id = "h18-jorn-2", turnin = 882, accept = 907, npc = 3387, at = { 1413, 44.86, 59.14 } },
        { id = "h18-bristleback", complete = { 878, 899 }, at = { 1413, 51.5, 55.0 },
          note = { ru = "Главный лагерь Дыбогривов к северо-востоку от Лагеря Таурахо: 6 водоискателей, "
                       .. "12 терноплетов, 12 геомантов (878). С каждого Дыбогрива (иногда и с налётчиков "
                       .. "Иглогривых) падают клыки — бейте всех, пока не наберёте 60 (899). Сохраните один "
                       .. "Осколок крови.",
                   en = "The main Bristleback camp north-east of Camp Taurajo: 6 Water Seekers, 12 Thornweavers, "
                       .. "12 Geomancers (878). Every Bristleback (and maybe the Razormane Raiders) drops "
                       .. "Bristleback Quilboar Tusks: keep killing until you have 60 (899). Keep one Blood "
                       .. "Shard." } },
        { id = "h18-stormsnouts", complete = 907, at = { 1413, 47.40, 52.96 },
          note = { ru = "На обратном пути на запад: грозорылы (громовые ящеры) бродят между лагерями Дыбогривов "
                       .. "— 3 крови (и рог рокочущей ящерицы, если взяли 821). Серый кодо Лакота'мани тоже "
                       .. "ходит тут — его копыто начинает задание для Йорна.",
                   en = "On the way back west: Stormsnouts (thunder lizards) roam between the Bristleback camps "
                       .. "- 3 Thunder Lizard Blood (and the Thunder Lizard Horn if you took 821). The grey kodo "
                       .. "Lakota'mani walks here too: his hoof starts a quest for Jorn." } },
        { id = "h18-mangletooth", turnin = 878, accept = 5052, npc = 3430, at = { 1413, 44.55, 59.26 } },
        { id = "h18-blood-shard", complete = 5052, turnin = 5052, npc = 3430, at = { 1413, 44.55, 59.26 },
          note = { ru = "Сразу отдайте один Осколок крови. Лишние осколки — на усиления у Кривозуба.",
                   en = "Hand over one Blood Shard right away. Spare shards buy buffs from Mangletooth." } },
        { id = "h18-jorn-3", turnin = 907, accept = 913, npc = 3387, at = { 1413, 44.86, 59.14 } },
        { id = "h18-owatanka", accept = 884, bg = true, use = 5102, at = { 1413, 45.4, 62.8 },
          note = {
              ru = "Оватанка (24, громовой ящер) бродит у 44-49, 60-63: его шип начинает задание. "
                  .. "Не встретили - не ищите.",
              en = "Owatanka (24, a thunder lizard) roams at 44-49, 60-63: his tailspike starts a quest. Not seen - "
                  .. "do not search.",
          } },
        { id = "h18-cloudscraper", complete = 913, at = { 1413, 47.33, 62.40 },
          note = { ru = "Громовые ястребы-облакорезы кружат к юго-востоку от лагеря: убейте одного ради крыльев.",
                   en = "Thunderhawk Cloudscrapers circle south-east of the camp: kill one for the wings." } },
        { id = "h18-owatanka-turnin", turnin = 884, optional = true, npc = 3387, at = { 1413, 44.86, 59.14 },
          note = {
              ru = "Только если взяли «Оватанку».",
              en = "Only if you have Owatanka.",
          } },
        { id = "h18-taurajo-end", turnin = 913, npc = 3387, at = { 1413, 44.86, 59.14 },
          note = { ru = "Йорн. Награда: щит или посох. Нашли копыто Лакота'мани - начните задание из предмета и сдайте здесь же.",
                   en = "Jorn. Reward: a shield or a staff. Found Lakota'mani's hoof: start the quest from the item and hand it in "
                       .. "here too." } },
        { id = "h18-fly-xroads", fly = "The Crossroads", at = { 1413, 51.50, 30.34 },
          note = { ru = "Омуса: летите на Перекрёсток.", en = "Omusa: fly to the Crossroads." } },

        ------------------------------------------------------------------
        -- The Crossroads, the Lushwater Oasis, Regthar, harpy lieutenants (level 19)
        ------------------------------------------------------------------
        { id = "h18-xr", turnin = { 899, 880 }, accept = 1489, npc = { 3432, 3448 }, at = { 1413, 52.26, 31.93 },
          note = { ru = "Сначала Манкрик (899, клыки), потом Тонга Рунный Тотем рядом (880). 1489 сдаётся в Громовом Утёсе на 20-м.",
                   en = "Mankrik first (899, the tusks), then Tonga Runetotem next to him (880). 1489 is turned in at Thunder Bluff "
                       .. "at 20." } },
        { id = "h18-lushwater", complete = { 852, 855 }, npc = 3396, at = { 1413, 46.04, 41.14 },
          note = { ru = "На юго-запад к Цветущему оазису: Хезрул Кровавая Метка (19) с охраной ходит вокруг воды. "
                       .. "Доберите 15 наручей с колкаров тут же.",
                   en = "South-west to the Lushwater Oasis: Hezrul Bloodmark (19) with guards walks around the "
                       .. "water. Finish the 15 Centaur Bracers on the Kolkar here." } },
        { id = "h18-regthar", turnin = { 852, 855 }, npc = 3389, at = { 1413, 45.34, 28.41 },
          note = { ru = "На север к Регтару Вратам Смерти. «Контратаку!» (элитный) не берите.",
                   en = "North to Regthar Deathgate. Skip Counterattack! (elite)." } },
        { id = "h18-harpy-lieutenants", complete = 875, at = { 1413, 38.62, 14.69 },
          note = {
              ru = "На северо-запад: 6 колец с истребительниц Ведьмокрылых (16-17) в западной части гнезда гарпий.",
              en = "North-west: 6 rings from Witchwing Slayers (16-17) in the western part of the harpy nest.",
          } },
        { id = "h18-border", accept = { 1062, 6548 }, npc = { 4049, 11857 }, at = { 1413, 35.22, 27.82 },
          note = { ru = "На юго-запад к входу в Когтистые горы: Сирет Камнелом и Макаба Плоское Копыто.",
                   en = "South-west to the Stonetalon border: Seereth Stonebreak and Makaba Flathoof." } },

        ------------------------------------------------------------------
        -- Stonetalon Mountains, first pass: Camp Aparaje, Malaka'jin (level 19-20)
        ------------------------------------------------------------------
        { id = "h18-grimtotem", complete = 6548, at = { 1442, 82.41, 87.18 },
          note = { ru = "Сразу за границей: 8 головорезов и 6 наёмников Зловещего Тотема в лагере.",
                   en = "Just past the border: 8 Grimtotem Ruffians and 6 Mercenaries in the camp." } },
        { id = "h18-makaba", turnin = 6548, accept = 6629, npc = 11857, at = { 1413, 35.19, 27.76 } },
        { id = "h18-grundig", complete = 6629, npc = 11858, at = { 1442, 73.65, 86.12 },
          note = { ru = "На запад: 6 громил Зловещего Тотема по пути и Грундиг Тёмное Облако (18) у "
                       .. "хижины, где держат Каю.",
                   en = "West: 6 Grimtotem Brutes on the way and Grundig Darkcloud (18) at the hut where Kaya "
                       .. "is held." } },
        { id = "h18-kaya", accept = 6523, npc = 11856, at = { 1442, 73.48, 85.59 },
          note = { ru = "Кая Плоское Копыто: сопровождение начнётся сразу.",
                   en = "Kaya Flathoof: the escort starts at once." } },
        { id = "h18-kaya-escort", complete = 6523, at = { 1442, 76.7, 90.9 },
          note = { ru = "Ведите Каю к лагерю Апарадже. По пути выскочат трое из Зловещего Тотема — бейте их, "
                       .. "пока они не убили Каю.",
                   en = "Walk Kaya to Camp Aparaje. Three Grimtotems ambush on the way: kill them before "
                       .. "they kill her." } },
        { id = "h18-makaba-2", turnin = { 6629, 6523 }, accept = 6401, npc = 11857, at = { 1413, 35.19, 27.76 },
          note = { ru = "Макаба. 6401 — в Приют Солнечного Камня.", en = "Makaba. 6401 goes to Sun Rock Retreat." } },
        { id = "h18-xenzilla", accept = 6461, npc = 12816, at = { 1442, 71.25, 95.02 },
          note = { ru = "На юго-запад в Малака'джин: Ксен'Зилла.", en = "South-west to Malaka'jin: Xen'Zilla." } },
        { id = "h18-creepers-bg", complete = 6461, bg = true, at = { 1442, 63.35, 83.86 },
          note = { ru = "Попутно: 10 глубокомшистых ползунов (по пути на северо-запад к Зизу) и 7 плевунов "
                       .. "(у Зиза и Утёса Ветрорезов).",
                   en = "Along the way: 10 Deepmoss Creepers (on the way north-west to Ziz) and 7 Deepmoss "
                       .. "Venomspitters (around Ziz and Windshear Crag)." } },

        ------------------------------------------------------------------
        -- Ziz Fizziks and Windshear Crag (level 20)
        ------------------------------------------------------------------
        { id = "h18-ziz", turnin = 1483, accept = 1093, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = { ru = "На северо-запад к хижине Зиза Физзикса.", en = "North-west to Ziz Fizziks' hut." } },
        { id = "h18-eggs-bg", complete = 1069, bg = true, at = { 1442, 62.07, 60.81 },
          note = { ru = "Попутно: 15 яиц глубокомшистых пауков у корней деревьев (здесь и на Утёсе Ветрорезов). "
                       .. "Из яиц иногда вылезает паук.",
                   en = "Along the way: 15 Deepmoss Eggs at the foot of the trees (here and in Windshear "
                       .. "Crag). A spider sometimes hatches." } },
        { id = "h18-windshear", complete = { 1062, 1093 }, at = { 1442, 67.13, 51.23 },
          note = { ru = "Утёс Ветрорезов (вырубка Торговой компании): 15 лесорубов; операторы — чертежи "
                       .. "Супержнеца 6000. Шредеры XT:4 и XT:9 (23) ходят по вырубке — обходите.",
                   en = "Windshear Crag (Venture Co. logging): 15 Venture Co. Loggers; Operators drop the "
                       .. "Super Reaper 6000 Blueprints. Shredders XT:4 and XT:9 (23) patrol the camp: avoid "
                       .. "them." } },
        -- Trainer-hub gate before Thunder Bluff 2 (see the header). It stands here, while the player is still at the
        -- Crag (the mobs of 18-20), not after the next step, which walks 430 yd back to Ziz.
        { id = "h18-lvl-20", level = { 19, 0.88 }, at = { 1442, 67.13, 51.23 },
          note = { ru = "Проверка перед уходом с вырубки: сдачи у Зиза и в Приюте Солнечного Камня дадут ещё ~12% уровня - это 20-й "
                       .. "и новые ранги у тренеров в Громовом Утёсе. Нет 19-го + 88% - добейте лесорубов и операторов здесь (18-20): "
                       .. "у Зиза только ядоплюи 17-18, в Приюте бить некого.",
                   en = "Check before you leave the logging camp: the Ziz and Sun Rock turn-ins add ~12% of a level, which makes 20 "
                       .. "and new ranks at the trainers in Thunder Bluff. Short of 19 + 88%: kill more loggers and operators here "
                       .. "(18-20): around Ziz there are only venomspitters of 17-18, and nothing to kill at Sun Rock." } },
        -- 6461 objective 1 (Deepmoss Creepers) is not part of this step: no creeper spawns near Ziz (the nearest are
        -- 340 yd south).
        { id = "h18-venomspitters", complete = { [6461] = { 2 }, 1069 }, at = { 1442, 61.63, 61.56 },
          note = { ru = "Доберите моховых ядоплюев и яйца по дороге обратно к Зизу. Ползуны из густого мха (6461) - только к югу от "
                       .. "Зиза (60.8, 71.9) и у Малака'джина: доберите их позже, по дороге к Ксен'Зилле.",
                   en = "Finish the Deepmoss Venomspitters and the eggs on the way back to Ziz. Deepmoss Creepers (6461) are only "
                       .. "south of Ziz (60.8, 71.9) and around Malaka'jin: finish them later on the way back to Xen'Zilla." } },
        { id = "h18-ziz-2", turnin = 1093, accept = 1094, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = { ru = "1094 — в Кабестан (полетите туда из Громового Утёса).",
                   en = "1094 goes to Ratchet (you fly there from Thunder Bluff)." } },

        ------------------------------------------------------------------
        -- Sun Rock Retreat, Thunder Bluff 2, Ratchet (level 20)
        ------------------------------------------------------------------
        { id = "h18-go-sunrock", go = true, radius = 20, at = { 1442, 49.96, 61.04 },
          note = { ru = "На запад к Приюту Солнечного Камня: подъём с восточной стороны.",
                   en = "West to Sun Rock Retreat: the ramp climbs from the east side." } },
        { id = "h18-tsunaman", accept = 6562, npc = 11862, at = { 1442, 47.36, 64.25 },
          note = { ru = "Цунаман (Приют Солнечного Камня). 6562 сдаётся в Ясеневом лесу.",
                   en = "Tsunaman (Sun Rock Retreat). 6562 is turned in in Ashenvale." } },
        { id = "h18-tammra", turnin = 6401, npc = 11864, at = { 1442, 47.46, 58.38 },
          note = { ru = "Таммра Ветряное Поле. «Цикл возрождения» пока не берите: он делается позже, на 25-м.",
                   en = "Tammra Windfield. Leave Cycle of Rebirth for now: it is done later, at 25." } },
        { id = "h18-fp-sunrock", fp = "Sun Rock Retreat", npc = 4312, at = { 1442, 45.12, 59.84 },
          note = { ru = "Тарм: откройте карту полётов.", en = "Tharm: open the flight map." } },
        { id = "h18-fly-tb", fly = "Thunder Bluff", at = { 1456, 47.00, 49.83 },
          note = { ru = "Летите в Громовой Утёс.", en = "Fly to Thunder Bluff." } },
        { id = "h18-sethearth-tb", sethearth = "Thunder Bluff", npc = 6746, at = { 1456, 45.81, 64.71 },
          note = { ru = "Трактирщица Пала: сделайте Громовой Утёс домом (в конце вернётесь сюда камнем).",
                   en = "Innkeeper Pala: make Thunder Bluff your home (you hearth back here at the end)." } },
        { id = "h18-go-elder-rise", go = true, at = { 1456, 68.47, 28.24 }, radius = 15,
          note = {
              ru = "По подвесному мосту с северо-восточного края центральной возвышенности (55.4, 35.6) на "
                  .. "Вершину Старейшин.",
              en = "Over the rope bridge from the north-east edge of the central mesa (55.4, 35.6) to Elder Rise.",
          } },
        { id = "h18-hamuul", turnin = 1489, accept = 1490, npc = 5769, at = { 1456, 78.62, 28.56 },
          note = { ru = "Верховный друид Хамуул Рунический Тотем.", en = "Arch Druid Hamuul Runetotem." } },
        { id = "h18-tb-2", turnin = 1490, npc = 5770, at = { 1456, 75.65, 31.61 },
          note = { ru = "Нара Дикая Грива. «Предводители Клыка» не берите (Пещеры Стенаний).",
                   en = "Nara Wildmane. Skip Leaders of the Fang (Wailing Caverns)." } },
        { id = "h18-fly-ratchet-2", fly = "Ratchet", at = { 1413, 63.08, 37.16 },
          note = { ru = "Обратно по мосту к Талу на центральную вершину: летите в Кабестан.",
                   en = "Back over the bridge to Tal on the central mesa: fly to Ratchet." } },
        { id = "h18-drohn", turnin = 821, bg = true, npc = 3292, at = { 1413, 62.26, 38.39 },
          note = { ru = "Если брали 821: сдайте его пивовару Дрону рядом с Мебоком (следующее, 822, не берите).",
                   en = "If you took 821: turn it in to Brewmaster Drohn next to Mebok (skip the next one, "
                       .. "822)." } },
        { id = "h18-sputtervalve", turnin = 1094, accept = 1095, npc = 3442, at = { 1413, 62.98, 37.22 },
          note = { ru = "Спаттервальв. 1095 — обратно Зизу.", en = "Sputtervalve. 1095 goes back to Ziz." } },
        { id = "h18-mebok-eggs", turnin = 1069, npc = 3446, at = { 1413, 62.37, 37.62 },
          note = { ru = "Мебок Миззирикс.", en = "Mebok Mizzyrix." } },
        { id = "h18-fly-xroads-2", fly = "The Crossroads", at = { 1413, 51.50, 30.34 },
          note = { ru = "Брагок: летите на Перекрёсток.", en = "Bragok: fly to the Crossroads." } },

        ------------------------------------------------------------------
        -- The Crossroads; Stonetalon Mountains, second pass: turn-ins, road to Ashenvale (level 20)
        ------------------------------------------------------------------
        { id = "h18-xr-darsok", turnin = 875, npc = 3449, at = { 1413, 51.62, 30.90 },
          note = {
              ru = "Дарсок Быстрый Кинжал на башне. «Серену Кровавое Перо» не берите.",
              en = "Darsok on the tower. Do not take Serena Bloodfeather.",
          } },
        { id = "h18-seereth", turnin = 1062, accept = 1063, npc = 4049, at = { 1413, 35.26, 27.88 },
          note = { ru = "На запад к Сирет Камнелом (мимо Регтара). «Машины-измельчители» не берите — "
                       .. "пришлось бы возвращаться сюда.",
                   en = "West to Seereth Stonebreak (past Regthar). Skip Shredding Machines: it would need "
                       .. "another trip back here." } },
        { id = "h18-xenzilla-2", turnin = 6461, npc = 12816, at = { 1442, 71.25, 95.02 },
          note = { ru = "Ксен'Зилла в Малака'джине.", en = "Xen'Zilla in Malaka'jin." } },
        -- Piznik (1090 > 1092, 2200 + XP, three kobold waves) is optional: the four steps are skipped together.
        { id = "h18-piznik-go", go = true, optional = true, radius = 15, at = { 1442, 73.78, 59.52 },
          note = { ru = "По желанию (задание Пизника, лучше вдвоём): на север долиной к руднику Ветрорезов (вход на восточном краю "
                       .. "вырубки). Не уверены - «Вперёд» на этом и трёх следующих шагах и сразу к Зизу.",
                   en = "Optional (Piznik's quest, safer as a pair): north up the valley to the Windshear Mine (entrance on the east "
                       .. "side of the logging camp). Not confident: press Forward on this and the next three steps and go straight "
                       .. "to Ziz." } },
        { id = "h18-piznik", accept = 1090, optional = true, npc = 4276, at = { 1442, 71.87, 60.00 },
          note = { ru = "Пизник в руднике (кобольды 20-22 вокруг). Сначала расчистите место рядом с ним.",
                   en = "Piznik inside the mine (kobolds 20-22 around). Clear the area next to him first." } },
        { id = "h18-piznik-defend", complete = 1090, optional = true, at = { 1442, 71.87, 60.00 },
          note = { ru = "Охраняйте Пизника 5 минут: волны кобольдов на 0:15 (3), 2:15 (4, два заклинателя) и 3:20 (4). Провалили - "
                       .. "возьмите задание заново.",
                   en = "Guard Piznik for 5 minutes: kobold waves at 0:15 (3), 2:15 (4, two casters) and 3:20 (4). Failed: take the "
                       .. "quest again." } },
        { id = "h18-piznik-ore", turnin = 1090, accept = 1092, optional = true, npc = 4276, at = { 1442, 71.87, 60.00 },
          note = { ru = "1092 — руду Зизу.", en = "1092: the ore goes to Ziz." } },
        { id = "h18-ziz-ore", turnin = 1092, optional = true, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = {
              ru = "Только если делали задание Пизника: руда - Зизу.",
              en = "Only if you did Piznik: the ore goes to Ziz.",
          } },
        { id = "h18-ziz-3", turnin = 1095, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = { ru = "На запад к Зизу Физзиксу. «Гернезо Гаечносвист» (27) не берите.",
                   en = "West to Ziz Fizziks. Skip Gerenzo Wrenchwhistle (27)." } },
        { id = "h18-talondeep", go = true, radius = 20, at = { 1442, 78.29, 42.51 },
          note = { ru = "На северо-восток через вырубку к тоннелю Talondeep Path — дорога в Ясеневый лес. "
                       .. "Шредеры XT:4 и XT:9 (23) обходите.",
                   en = "North-east across the logging camp to the Talondeep Path, the road into Ashenvale. "
                       .. "Avoid the XT:4 and XT:9 shredders (23)." } },

        ------------------------------------------------------------------
        -- Ashenvale: Va'xug, the road west, Zoram'gar (level 20-21)
        ------------------------------------------------------------------
        { id = "h18-vaxug", accept = 98251, npc = 267214, at = { 1440, 40.46, 61.42 },
          note = { ru = "Ва'кзуг Огненный Мех у дороги.", en = "Va'xug Firefure by the road." } },
        { id = "h18-vaxug-hunt", complete = 98251, at = { 1440, 41.93, 62.64 },
          note = { ru = "Вокруг: 6 чернорогих оленей и 6 ясеневых медведей.",
                   en = "All around: 6 Shadowhorn Stags and 6 Ashenvale Bears." } },
        { id = "h18-vaxug-2", turnin = 98251, accept = 98252, npc = 267214, at = { 1440, 40.46, 61.42 } },
        { id = "h18-eye-walk", complete = 98252, at = { 1440, 38.93, 57.92 },
          note = { ru = "Идите на главную дорогу к северо-западу — Око Килрогга летит за вами.",
                   en = "Walk north-west to the main road; the Eye of Kilrogg follows you." } },
        { id = "h18-eye", turnin = 98252, npc = 271181, at = { 1440, 38.5, 58.2 },
          note = { ru = "Поговорите с Оком Килрогга на дороге.", en = "Talk to the Eye of Kilrogg on the road." } },
        { id = "h18-go-astranaar", go = true, radius = 25, at = { 1440, 34.14, 53.61 },
          note = { ru = "На запад по дороге. До Астранаара сверните с неё — стража ночных эльфов нападает.",
                   en = "West along the road. Leave it before Astranaar: the night elf guards attack." } },
        { id = "h18-go-zoram", go = true, radius = 25, at = { 1440, 18.43, 32.94 },
          note = { ru = "Лесом на северо-запад, Астранаар остаётся восточнее.",
                   en = "Through the forest to the north-west, keeping Astranaar to the east." } },
        { id = "h18-jeneu", turnin = 6562, npc = 12736, at = { 1440, 11.56, 34.29 },
          note = { ru = "Застава Зорам'гар: Дже'ней Санкрея. «Сущность Аку'Май» не берите (вход в Непроглядную "
                       .. "Пучину, элитные).",
                   en = "Zoram'gar Outpost: Je'neu Sancrea. Skip The Essence of Aku'Mai (Blackfathom Deeps "
                       .. "entrance, elites)." } },
        { id = "h18-zoram-quests", accept = { 6442, 6462 }, npc = { 12719, 12721 }, at = { 1440, 11.67, 34.88 },
          note = { ru = "Марукаи и Митсува.",
                   en = "Marukai and Mitsuwa." } },
        { id = "h18-fp-zoram", fp = "Zoram'gar Outpost", npc = 11901, at = { 1440, 12.24, 33.80 },
          note = { ru = "Андрук: откройте карту полётов.", en = "Andruk: open the flight map." } },
        -- Vorsha (2300 XP, Elite / 2 players in WCLBox) is optional: its naga waves also drop heads for 6442.
        -- Skipped: its complete step is forwarded by the 6442 complete, its turn-in by the 6442 turn-in.
        { id = "h18-vorsha", accept = 6641, optional = true, npc = 12717, at = { 1440, 12.06, 34.63 },
          note = { ru = "По желанию: Муглаш рядом - сопровождение к жаровне наг на берегу (2300 опыта, рассчитано на двоих). Волны "
                       .. "наг (их головы идут в задание Марукаи), затем Ворша: бьёт очень больно, пусть Муглаш держит её на себе. "
                       .. "Не уверены - пропустите этот шаг.",
                   en = "Optional: Muglash next to him - an escort to the naga brazier on the shore (2300 XP, meant for two players). "
                       .. "Naga waves (their heads count for Marukai's quest), then Vorsha: she hits very hard, let Muglash keep her "
                       .. "on himself. Not confident - skip this step." } },
        { id = "h18-vorsha-escort", complete = 6641, optional = true, at = { 1440, 9.59, 27.58 },
          note = {
              ru = "Только если взяли: с Муглашем к жаровне наг на берегу - волны наг, затем Ворша. Муглаш погиб - "
                  .. "«Вперёд».",
              en = "Only if you took it: with Muglash to the naga brazier on the shore - naga waves, then Vorsha. "
                  .. "Muglash died - press Forward.",
          } },
        { id = "h18-naga", complete = 6442, at = { 1440, 11.31, 27.08 },
          note = { ru = "На север по Зорамскому взморью: 20 голов наг Гневного Хвоста. Редкая Леди Веспия (22) патрулирует берег.",
                   en = "North along the Zoram Strand: 20 Wrathtail Heads from the naga. The rare Lady Vespia (22) patrols the shore." } },
        -- Requirement gate: 216 Between a Rock and a Thistlefur needs level 21.
        { id = "h18-lvl-21", level = 21, at = { 1440, 11.31, 27.08 },
          note = { ru = "Следующему заданию (деревня Чертополоха) нужен 21-й уровень. Не хватает - бейте наг дальше.",
                   en = "The next quest (Thistlefur Village) needs level 21. Short of it: keep killing naga." } },
        { id = "h18-marukai", turnin = 6442, npc = 12719, at = { 1440, 11.69, 34.91 },
          note = { ru = "Марукаи.", en = "Marukai." } },
        { id = "h18-vorsha-turnin", turnin = 6641, optional = true, npc = 12863, at = { 1440, 12.22, 34.22 },
          note = {
              ru = "Только если сопровождали Муглаша: гонец Песни Войны в Зорам'гаре.",
              en = "Only if you escorted Muglash: the Warsong Runner in Zoram'gar.",
          } },

        ------------------------------------------------------------------
        -- Thistlefur Village, back to Zoram'gar, hearth to Thunder Bluff (level 21-22)
        ------------------------------------------------------------------
        { id = "h18-karang", accept = 216, npc = 12757, at = { 1440, 11.90, 34.54 },
          note = { ru = "Каранг Амаккар.", en = "Karang Amakkar." } },
        { id = "h18-thistlefur", complete = 216, at = { 1440, 32.11, 41.46 },
          note = { ru = "На восток к деревне фурболгов Чертополоха: 8 мстителей и 8 шаманов (23-24). Тяните по "
                       .. "одному, шаманы лечат.",
                   en = "East to Thistlefur Village: 8 Avengers and 8 Shamans (23-24). Pull one at a time, "
                       .. "the shamans heal." } },
        { id = "h18-troll-charms", complete = 6462, object = 178144, at = { 1440, 40.74, 33.58 },
          note = { ru = "Северо-восточный край деревни, у входа в логово: 8 амулетов троллей из сундуков.",
                   en = "The north-east end of the village by the hold: 8 Troll Charms from the Troll "
                       .. "Chests." } },
        -- Hand-over gate to h-22-hillsbrad and trainer-hub gate of Thunder Bluff 3: the quests alone fall short of 22;
        -- the furbolgs (23-24) are the best XP on the path.
        { id = "h18-lvl-22", level = { 21, 0.85 }, at = { 1440, 36.5, 36.0 },
          ok = { ["level-grind"] = 40 }, -- the largest normal run of the 28 base routes, 40 kills (Orc, Troll), PLAN.md D.4 step 4
          note = { ru = "Доберите уровень до 21-го + 85% на фурболгах деревни (23-24 - больше всего опыта): сдача 216 и 6462 в "
                       .. "Зорам'гаре добавит ещё ~15% - это 22-й уровень и новые ранги у тренеров в Громовом Утёсе. Убивали всё по "
                       .. "пути - шаг уже выполнен.",
                   en = "Bring your level to 21 + 85% on the furbolgs of the village (23-24 give the most XP): the 216 and 6462 "
                       .. "turn-ins at Zoram'gar add another ~15%, which makes level 22 and new ranks at the trainers in Thunder "
                       .. "Bluff. Killed everything on the way: the step is already done." } },
        { id = "h18-karang-2", turnin = 216, npc = 12757, at = { 1440, 11.90, 34.54 },
          note = { ru = "Обратно на запад в Зорам'гар. «Король Скверноболья» не берите.",
                   en = "Back west to Zoram'gar. Skip King of the Foulweald." } },
        { id = "h18-mitsuwa", turnin = 6462, npc = 12721, at = { 1440, 11.65, 34.85 },
          note = { ru = "Митсува.",
                   en = "Mitsuwa." } },
        { id = "h18-hearth-tb", hearth = "Thunder Bluff", at = { 1456, 45.81, 64.71 },
          note = { ru = "Камень возвращения в Громовой Утёс. На откате — летите у Андрука.",
                   en = "Hearth to Thunder Bluff. On cooldown: fly from Andruk." } },

        ------------------------------------------------------------------
        -- Thunder Bluff 3 (level 22)
        ------------------------------------------------------------------
        { id = "h18-tb-3", turnin = 1063, accept = 1064, npc = 4046, at = { 1456, 69.85, 30.91 },
          note = { ru = "Вершина Старейшин: Магата Зловещий Тотем.", en = "Elder Rise: Magatha Grimtotem." } },
        { id = "h18-go-pools-3", go = true, radius = 15, at = { 1456, 28.5, 29.0 },
          note = { ru = "Через центральную вершину на Вершину Духов, вниз в Пруды Видений.",
                   en = "Across the central mesa to Spirit Rise, down into the Pools of Vision." } },
        { id = "h18-end", turnin = 1064, npc = 3419, at = { 1456, 22.81, 20.89 },
          note = { ru = "Аптекарь Зама. Её следующее задание ведёт в Мельницу Таррен (Предгорья Хилсбрада): с него начинается "
                       .. "следующий сегмент.",
                   en = "Apothecary Zamah. Her next quest leads to Tarren Mill (Hillsbrad Foothills): the next segment starts with "
                       .. "it." } },
    },
})
