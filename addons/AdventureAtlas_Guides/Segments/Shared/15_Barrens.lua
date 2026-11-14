-- AdventureAtlas_Guides / Segments / Shared / 15_Barrens.lua
--
-- Segment "h-15-barrens": levels 15-18, all races. Orgrimmar -> Razor Hill -> Far Watch Post -> The Crossroads
-- hub -> east (Razormane) -> Ratchet + pirate coast -> west (Regthar, Forgotten Pools) -> north-east and north
-- (Echeyakee, Boulder Lode Mine, Sludge Fen, Samophlange, Vrang Wildgore, Witchwing harpies) -> hearth -> Ratchet
-- -> south (Stagnant Oasis, Verog, raptor nests, Mankrik's wife) -> Camp Taurajo -> fly back to the Crossroads ->
-- Regthar -> the timed 853. Order of the former Undead segment ud-04-barrens with the extras of the Skyborne one
-- (875, optional 883, Verog as a step of its own, 1483 / 1069 / 878 accepted on the way).
-- Coordinates: Forever uiMap 1411 (Durotar) / 1454 (Orgrimmar) / 1413 (The Barrens), map percent, from
-- tools/data/forever_db.lua (NPC / object spawns; centroids of the objective mob / object spawns of the chosen
-- area for complete steps). The 870 dive spot and the 95621 Corporal Adamore camp are WCLBox points.
--
-- Start state: the Undead stand at the Durotar zeppelin tower and do not know Orgrimmar (h15-org-gate,
-- h15-org-fp: only in their routes; Races/Scourge.lua adds the four city quests there); the other races arrive
-- by hearthstone at the Orgrimmar inn, 130 yd from Doras. h15-org is the join step for all races and the
-- training anchor "Orgrimmar at 14": class steps go after h15-org, never after h15-start.
-- Hub plan (all Crossroads NPCs within ~60 yd of 51.9,30.9):
--   arrival : 840 Takrin (Razor Hill) > 842 Kargal (Far Watch Post).
--   XR1     : 842 > 844 (Sergra), 870 (Tonga), 871 + 5041 + 867 (Thork, Darsok), 1358 > 1492 + 848 (Helbrim),
--             869 (Gazrog), flight path, hearth.
--   east 1  : 871 camp (54.8,26), plainstrider beaks 844, raptor heads 869 (all segment).
--   XR2     : 844 > 845, 871 > 872.
--   east 2  : Chen's Empty Keg spot (55.7,27.3, optional), 872 + 5041 + Kreenig (58.5,25.5), zhevra 845 on the
--             way to Ratchet.
--   RA1     : 97253, 887, 895 (poster), 894, 1492 (896 optional), flight path.
--   pirates : 97253 parts, 887 Southsea, 895 Baron Longshore. RA2: 887/895 > 890 > 892 > 888, 97253.
--   XR3     : fly; 872/5041, 845 > 903.  west: Regthar 850/855, Barak 850, Forgotten Pools 870 + 848 spores,
--             prowlers 903; Regthar 850 > 851.  XR3b: 870 > 877, 903 > 881.
--   north   : Echeyakee 881, Boulder Lode Mine 896 (optional), Sludge Fen 858 > 863 escort, Samophlange
--             894 > 900 > 901 > 902, Vrang 95494/95507 > 95495 > Walton 95621 > 95508, harpies 867.
--   XR4     : hearth; 869 > 3281, 867 > 875, 881 > 905, 4921 + 95774 + 899 (Mankrik).
--   RA3     : fly; 902 + 863 > 1483, 865 + 1069 (Mebok), 896 (optional), 819 > 821 if the keg was found.
--   south   : 888 crates, 3281 silver, Stagnant Oasis 877 + 848, Verog 851, nests 905 (+ 865 horns), Lakota'mani
--             883 (optional, bg), Razormane Raiders 95774, Beaten Corpse 4921, Camp Taurajo: flight path, hearth,
--             878.
--   XR5     : fly; 4921 + 95774, 877 > 880, 905 > 3261, 3281; Regthar 851 > 852; 848 > 853 (timed, accepted
--             last).
-- Race-filtered steps: h15-org-gate, h15-org-fp (Scourge); h15-fp-xroads and h15-fp-taurajo (every race but the
--   Tauren: the walk variant of mul-03-barrens-crossing learns both points, docs/dev/PLAN.md B.5, E.1). An insert
--   on one of these two needs the same race scope.
-- Additions by other files: Races/Scourge.lua (city quests after h15-org-fp), Races/Skyborne.lua (98024 at Thork),
--   Segments/Durotar (postponed turn-ins after h15-razor-hill), Races/Orc.lua, Troll.lua, Tauren.lua (flight
--   chains after h15-sethearth-xroads), class files (h15-org; h15-far-watch; the druid before h15-hearth-xroads).
-- Anchors (never renamed): h15-org-gate, h15-org-fp, h15-org, h15-start, h15-razor-hill, h15-far-watch,
--   h15-xr-arrive, h15-xr-thork, h15-fp-xroads, h15-sethearth-xroads, h15-xr-2, h15-fp-ratchet, h15-ratchet-2,
--   h15-fly-xroads, h15-xr-3, h15-hearth-xroads, h15-xr-4, h15-fly-ratchet, h15-ratchet-3, h15-fp-taurajo,
--   h15-sethearth-taurajo, h15-fly-xroads-2, h15-xr-5, h15-end.
-- Skipped: 97003 Chol'aruk (elite, group), 4021 (elite), 822 (third keg quest, level 24), 3921 > 3922 (Wenikee,
--   back north), 876 Serena (875's follow-up: two extra Crossroads trips), dungeon quests.
-- Chen's Empty Keg (object 3238, 9 spawn points in the DB; item 4926 starts 819): checked on the leg to the 872
--   camp (55.7,27.3) and mentioned in the notes where the route passes the other spots (Echeyakee 55.8,20.0;
--   Sludge Fen 57.2,9.0; Vrang 43.8,12.2; Stagnant Oasis 56.5,43.7). 819 is turned in and 821 taken at RA3 (one
--   place only: a second 819 step would be a duplicate accept); 821's items are all on the next segment's path
--   and it is turned in at the Ratchet visit after Thunder Bluff 2.
-- Carried into the next segment: 852 Hezrul, 855 Centaur Bracers, 865 Raptor Horns (Mebok, Ratchet), 888 Stolen
--   Booty (Gazlowe, Ratchet), 880 Altered Beings, 3261 Jorn Skyseer (Camp Taurajo), 853 Apothecary Zamah
--   (Thunder Bluff, TIMED 45 min), 899 Consumed by Hatred and 878 Tribes at War (Bristlebacks at Camp Taurajo),
--   875 Harpy Lieutenants, 1483 Ziz Fizziks, 1069 Deepmoss Spider Eggs, 821 Chen's Empty Keg (if the keg was
--   found; Drohn, Ratchet).
-- Hearthstone: bound to The Crossroads on the first visit, used once from the harpies back to the Crossroads,
--   re-bound to Camp Taurajo at the end for the next segment.
-- Trainers: none in the Barrens. Orgrimmar at the start (h15-org, level 14); the next trainer city is Thunder
--   Bluff at the start of h-18 (level 18, forced trip for the timed 853).
--
-- Automation notes: transient steps (fp, sethearth, fly) come after the quest steps of that hub; no step accepts
-- a quest from an NPC on both sides of a transient step. A background goal is never repeated as a stateful
-- `complete` step far behind it (869 raptor heads only has its bg step): once such a step is done early, the
-- engine's anchor jumps to it and fast-forwards every transient / optional step before it (flight paths, flights,
-- hearth). For the same reason the event-only 870 dive shares a step with 903.
if not AdventureAtlas.AddLibraryInsert then return end
AdventureAtlas.AddLibrarySegment({
    id = "h-15-barrens",
    title = { ru = "15-18 Степи", en = "15-18 The Barrens" },
    zone = "The Barrens",
    levels = { 15, 18 },
    steps = {

        ------------------------------------------------------------------
        -- Orgrimmar, Razor Hill, Far Watch Post (level 14-15)
        ------------------------------------------------------------------
        -- Only the Undead: they arrive by zeppelin and have never been in Orgrimmar (the flight point is needed
        -- from 22 on). The other races hearth to the inn.
        { id = "h15-org-gate", race = "Scourge", go = true, at = { 1454, 48.97, 92.84 },
          note = { ru = "От башни дирижаблей к главным воротам Оргриммара (300 ярдов): точка полёта и городские задания.",
                   en = "From the zeppelin tower to the main gate of Orgrimmar (300 yd): the flight point and the city quests." } },
        { id = "h15-org-fp", race = "Scourge", fp = "Orgrimmar", npc = 3310, at = { 1454, 45.12, 63.89 },
          note = { ru = "Дорас на башне в Долине Силы: откройте карту полётов (точка нужна с 22-го уровня).",
                   en = "Doras on the tower in the Valley of Strength: open the flight map (the point is used from 22 on)." } },
        -- Join step of all races (the radius covers the inn and Doras) and the training anchor "Orgrimmar at 14".
        { id = "h15-org", go = true, radius = 80, at = { 1454, 49.6, 66.15 },
          note = { ru = "Оргриммар, Долина Силы (таверна и башня ветрокрылов). Тренеры классов в городе - сейчас: дальше до 18-го "
                       .. "уровня их не будет.",
                   en = "Orgrimmar, the Valley of Strength (the inn and the wind rider tower). Class trainers in the city now: there "
                       .. "are none on the way until level 18." } },
        { id = "h15-start", go = true, at = { 1454, 48.97, 92.84 }, radius = 20,
          note = { ru = "Из Оргриммара через главные ворота на юг и дальше по дороге в Колючий Холм.",
                   en = "Leave Orgrimmar through the main gate (south) and follow the road to Razor Hill." } },
        { id = "h15-razor-hill", accept = 840, npc = 3336, at = { 1411, 50.84, 43.59 },
          note = { ru = "Колючий Холм: Такрин Следопыт у входа в казарму. По дороге на юг от Оргриммара.",
                   en = "Razor Hill: Takrin Pathseeker by the barracks. South along the road from Orgrimmar." } },
        { id = "h15-far-watch", turnin = 840, accept = 842, npc = 3337, at = { 1413, 62.26, 19.38 },
          note = { ru = "Дорога на запад через мост над рекой Строптивой к Дальнему Дозору: Каргал Боевой Шрам "
                       .. "на башне.",
                   en = "Road west over the Southfury bridge to Far Watch Post: Kargal Battlescar on the "
                       .. "tower." } },

        ------------------------------------------------------------------
        -- The Crossroads, first visit (level 15)
        ------------------------------------------------------------------
        -- CONFIRM (docs/dev/PLAN.md E.21): the DB lists 844 as exclusive with the Tauren breadcrumbs 861 and 854;
        -- tools/overrides/shared.lua removes that (unverified). The `ok` acknowledges the resulting WARN
        -- db-override-unverified of the Tauren routes (tests/spec/guides_layout_spec.lua demands it while a Tauren
        -- route exists). If 844 is refused after 854 in the game, the Tauren skip 854 (230 XP; Segments/Mulgore).
        { id = "h15-xr-arrive", turnin = 842, accept = 844, npc = 3338, at = { 1413, 52.23, 31.01 },
          ok = "db-override-unverified", -- the Tauren: 844 after their breadcrumbs 861 / 854 (E.21, -- CONFIRM above)
          note = { ru = "Дорога на юго-запад к Перекрёстку идёт мимо лагерей Иглогривых — не задерживайтесь. "
                       .. "Сергра Тёмный Шип у южного края Перекрёстка.",
                   en = "The road south-west to the Crossroads passes the Razormane camps: do not stop. Sergra "
                       .. "Darkthorn on the south edge of the Crossroads." } },
        { id = "h15-tonga", accept = 870, npc = 3448, at = { 1413, 52.26, 31.93 },
          note = { ru = "Тонга Рунный Тотем рядом.", en = "Tonga Runetotem next to her." } },
        { id = "h15-xr-thork", accept = { 871, 5041, 867 }, npc = { 3429, 3449 }, at = { 1413, 51.56, 30.88 },
          note = { ru = "Торк и Дарсок Быстрый Кинжал у западного дома (Дарсок наверху башни).",
                   en = "Thork and Darsok Swiftdagger at the west building (Darsok on top of the tower)." } },
        { id = "h15-helbrim", turnin = 1358, accept = { 1492, 848 }, npc = 3390, at = { 1413, 51.44, 30.15 },
          note = { ru = "Аптекарь Хелбрим. Награда за 1358: Длинный ниспадающий плащ.",
                   en = "Apothecary Helbrim. Reward for 1358: Long Draping Cape." } },
        { id = "h15-gazrog", accept = 869, npc = 3464, at = { 1413, 51.93, 30.32 },
          note = { ru = "Газрог у таверны.", en = "Gazrog by the inn." } },
        -- Race filter (docs/dev/PLAN.md B.5, E.1): the Tauren learned this point in mul-03-barrens-crossing (the walk
        -- variant of the Mulgore bridge is in force).
        { id = "h15-fp-xroads", race = { "Orc", "Scourge", "Skyborne", "Troll" }, fp = "The Crossroads", npc = 3615,
          at = { 1413, 51.50, 30.34 },
          note = { ru = "Деврак на башне: откройте карту полётов.",
                   en = "Devrak on the tower: open the flight map." } },
        { id = "h15-sethearth-xroads", sethearth = "The Crossroads", npc = 3934, at = { 1413, 51.99, 29.89 },
          note = { ru = "Трактирщик Буранд: сделайте таверну домом, продайте хлам, купите воду. Тренеров классов в Степях нет.",
                   en = "Innkeeper Boorand: make this inn your home, sell junk, buy water. There are no class trainers in the "
                       .. "Barrens." } },

        ------------------------------------------------------------------
        -- East 1: Razormane camp next to the Crossroads (level 15)
        ------------------------------------------------------------------
        { id = "h15-raptor-heads", complete = 869, bg = true, at = { 1413, 52.9, 28.8 },
          note = { ru = "Весь сегмент попутно: 12 голов ящеров с любых Солнечночешуйчатых ящеров.",
                   en = "All segment along the way: 12 Raptor Heads from any Sunscale raptor." } },
        { id = "h15-beaks-bg", complete = 844, bg = true, at = { 1413, 53.5, 28.5 },
          note = { ru = "Попутно: 7 клювов с долгоногов вокруг Перекрёстка.",
                   en = "Along the way: 7 Plainstrider Beaks from plainstriders around the Crossroads." } },
        { id = "h15-thorn-hill", complete = 871, at = { 1413, 54.8, 26.0 },
          note = { ru = "Лагерь Иглогривых к северо-востоку: 8 искателей воды, 8 колючников, 3 охотника.",
                   en = "Razormane camp to the north-east: 8 Water Seekers, 8 Thornweavers, 3 Hunters." } },
        { id = "h15-beaks", complete = 844, at = { 1413, 53.5, 29.5 },
          note = { ru = "Доберите клювы долгоногов по дороге назад.",
                   en = "Finish the plainstrider beaks on the way back." } },

        ------------------------------------------------------------------
        -- The Crossroads, second visit (level 15)
        ------------------------------------------------------------------
        { id = "h15-xr-2-sergra", turnin = 844, accept = 845, npc = 3338, at = { 1413, 52.23, 31.01 } },
        { id = "h15-xr-2", turnin = 871, accept = 872, npc = 3429, at = { 1413, 51.50, 30.87 } },

        ------------------------------------------------------------------
        -- East 2: Razormane camp, then to Ratchet (level 15-16)
        ------------------------------------------------------------------
        { id = "h15-hooves-bg", complete = 845, bg = true, at = { 1413, 59.5, 21.0 },
          note = { ru = "Попутно: 4 копыта зебр (бегуны-зебры повсюду к востоку).",
                   en = "Along the way: 4 Zhevra Hooves (Zhevra Runners all over the east)." } },
        { id = "h15-keg", collect = { [4926] = 1 }, object = 3238, optional = true, at = { 1413, 55.70, 27.30 },
          note = { ru = "По пути на северо-восток: здесь может лежать Пустой бочонок Чэня (задание пивовару Дрону в "
                       .. "Кабестане, 1050 + 1350 опыта). Есть — подберите. Нет — «Вперёд»: бочонок бывает и в "
                       .. "других местах маршрута (подсказки в заметках).",
                   en = "On the way north-east: Chen's Empty Keg may lie here (a quest for Brewmaster Drohn in "
                       .. "Ratchet, 1050 + 1350 XP). There: loot it. Not there: press Forward, the keg can also lie "
                       .. "at other spots on the route (see the notes)." } },
        { id = "h15-far-camp", complete = { 872, 5041 }, at = { 1413, 58.6, 25.4 },
          note = { ru = "Дальний лагерь Иглогривых: 8 геомантов, 8 защитников, Кринег Злобное Рыло (15) на юге "
                       .. "лагеря (58.5, 27.0) — его клык. Ящики снабжения Перекрёстка — по краям лагеря.",
                   en = "The far Razormane camp: 8 Geomancers, 8 Defenders, Kreenig Snarlsnout (15) on the south "
                       .. "side (58.5, 27.0) for his tusk. The Crossroads' Supply Crates are around the camp." } },
        -- 872 again (already credited, no extra XP): with 845 alone this step would be done as soon as the bg
        -- hooves are, become the forward anchor and fast-forward the optional keg check before it.
        { id = "h15-hooves", complete = { 845, 872 }, at = { 1413, 60.5, 21.5 },
          note = { ru = "Не хватает копыт — зебры сразу к северо-востоку от лагеря. Потом на юго-восток в Кабестан.",
                   en = "Missing hooves? Zhevra right north-east of the camp. Then south-east to Ratchet." } },

        ------------------------------------------------------------------
        -- Ratchet, first visit (level 16)
        ------------------------------------------------------------------
        { id = "h15-wrenix", accept = 97253, npc = 7161, at = { 1413, 63.07, 36.32 },
          note = { ru = "Кабестан: Реникс Жалкий у входа.", en = "Ratchet: Wrenix the Wretched at the entrance." } },
        { id = "h15-gazlowe", accept = 887, npc = 3391, at = { 1413, 62.68, 36.23 },
          note = { ru = "Газлоу в доме у ворот.", en = "Gazlowe in the house by the gate." } },
        { id = "h15-wanted", accept = 895, object = 3972, at = { 1413, 62.59, 37.47 },
          note = { ru = "Плакат «Разыскивается» на стене.", en = "The WANTED poster on the wall." } },
        { id = "h15-sputtervalve", accept = 894, npc = 3442, at = { 1413, 62.98, 37.22 },
          note = { ru = "Спаттервальв.", en = "Sputtervalve." } },
        { id = "h15-dizzywig", turnin = 1492, npc = 3453, at = { 1413, 63.35, 38.45 },
          note = { ru = "Начальник порта Диззивиг на пристани.", en = "Wharfmaster Dizzywig on the dock." } },
        { id = "h15-dizzywig-896", accept = 896, optional = true, npc = 3453, at = { 1413, 63.35, 38.45 },
          note = { ru = "По желанию: его же «Шахтёрская удача» - изумруд «Кошачий глаз» из рудника Валунов на севере (редкая добыча). "
                       .. "Не хотите - «Вперёд».",
                   en = "Optional: his Miner's Fortune - a Cats Eye Emerald from the Boulder Lode Mine in the north (a rare drop). "
                       .. "Not interested: press Forward." } },
        { id = "h15-fp-ratchet", fp = "Ratchet", npc = 16227, at = { 1413, 63.08, 37.16 },
          note = { ru = "Брагок: откройте карту полётов.", en = "Bragok: open the flight map." } },

        ------------------------------------------------------------------
        -- Southsea pirate camps south of Ratchet (level 16)
        ------------------------------------------------------------------
        { id = "h15-pirates-bg", complete = 887, bg = true, at = { 1413, 63.7, 46.9 },
          note = { ru = "Попутно: 12 разбойников и 6 канониров Южноморских пиратов.",
                   en = "Along the way: 12 Southsea Brigands and 6 Southsea Cannoneers." } },
        { id = "h15-parts", complete = 97253, object = 660930, at = { 1413, 61.9, 46.3 },
          note = { ru = "Верхний пиратский лагерь (дальше от берега): 5 горстей сложных деталей на земле.",
                   en = "The upper pirate camp (away from the shore): 5 Handfuls of Complicated Parts on the "
                       .. "ground." } },
        { id = "h15-longshore", complete = 895, npc = 3467, at = { 1413, 63.3, 49.0 },
          note = { ru = "Барон Лонгшор (16) стоит в одном из лагерей у берега. Не трогайте ящики пока — они для "
                       .. "следующего задания Газлоу, заберёте их позже.",
                   en = "Baron Longshore (16) stands in one of the shore camps. Leave the crates for now: they "
                       .. "are for Gazlowe's later quest, you pick them up later." } },
        { id = "h15-pirates", complete = 887, at = { 1413, 63.8, 45.5 },
          note = { ru = "Доберите пиратов в лагерях у берега и возвращайтесь на север в Кабестан.",
                   en = "Finish the pirates in the shore camps and go back north to Ratchet." } },

        ------------------------------------------------------------------
        -- Ratchet, second visit (level 16)
        ------------------------------------------------------------------
        { id = "h15-wrenix-2", turnin = 97253, npc = 7161, at = { 1413, 63.07, 36.32 } },
        { id = "h15-gazlowe-2", turnin = { 887, 895 }, accept = 890, npc = 3391, at = { 1413, 62.68, 36.23 } },
        { id = "h15-dizzywig-2", turnin = 890, accept = 892, npc = 3453, at = { 1413, 63.35, 38.45 } },
        -- 888 is carried: Gazlowe, h-18
        { id = "h15-ratchet-2", turnin = 892, accept = 888, npc = 3391, at = { 1413, 62.68, 36.23 },
          note = { ru = "888 (ящики в пиратском лагере) выполните позже, по дороге на юг.",
                   en = "888 (crates in the pirate camp) is done later, on the way south." } },
        { id = "h15-fly-xroads", fly = "The Crossroads", at = { 1413, 51.50, 30.34 },
          note = { ru = "Летите на Перекрёсток у Брагока.", en = "Fly to the Crossroads from Bragok." } },

        ------------------------------------------------------------------
        -- The Crossroads, third visit (level 16)
        ------------------------------------------------------------------
        { id = "h15-xr-3-thork", turnin = { 872, 5041 }, npc = 3429, at = { 1413, 51.50, 30.87 },
          note = { ru = "Торк.",
                   en = "Thork." } },
        { id = "h15-xr-3", turnin = 845, accept = 903, npc = 3338, at = { 1413, 52.23, 31.01 } },

        ------------------------------------------------------------------
        -- West: Regthar, the Forgotten Pools, Barak Kodobane (level 16)
        ------------------------------------------------------------------
        -- 855 is carried: Regthar, h-18
        { id = "h15-regthar", accept = { 850, 855 }, npc = 3389, at = { 1413, 45.34, 28.41 },
          note = { ru = "Регтар Врата Смерти в форте на западе. 855 (15 наручей) - попутно; сдаётся в следующем сегменте.",
                   en = "Regthar Deathgate at the fort to the west. 855 (15 bracers) runs along the way; it is turned in next "
                       .. "segment." } },
        { id = "h15-claws-bg", complete = 903, bg = true, at = { 1413, 42.5, 26.0 },
          note = { ru = "Попутно: 7 когтей с саванных хищников.", en = "Along the way: 7 Prowler Claws." } },
        { id = "h15-bracers-bg", complete = 855, bg = true, at = { 1413, 44.5, 23.5 },
          note = { ru = "Попутно, до конца следующего сегмента: 15 наручей с любых колкаров.",
                   en = "Along the way, until the end of the next segment: 15 Centaur Bracers from any Kolkar." } },
        { id = "h15-spores-bg", complete = 848, bg = true, object = 3640, at = { 1413, 44.6, 23.8 },
          note = { ru = "Попутно: споры с налитых грибов у Забытых прудов (4 шт.).",
                   en = "Along the way: spores from the Laden Mushrooms around the Forgotten Pools (4)." } },
        { id = "h15-barak", complete = 850, npc = 3394, at = { 1413, 42.80, 23.52 },
          note = { ru = "Барак Гроза Кодо (16) в лагере колкаров к северо-западу: сильно бьёт — начинайте с полным "
                       .. "здоровьем, рядом колкары-заклинатели.",
                   en = "Barak Kodobane (16) in the Kolkar camp to the north-west: he hits hard, start at full "
                       .. "health; Kolkar casters nearby." } },
        { id = "h15-forgotten-pools", complete = { 870, 903 }, at = { 1413, 45.06, 22.54 },
          note = { ru = "Забытые пруды к востоку: нырните к бурлящей расщелине на дне пруда. Когти доберите с "
                       .. "хищников между прудом и лагерем Барака.",
                   en = "The Forgotten Pools to the east: dive to the Bubbling Fissure at the bottom of the pool. "
                       .. "Finish the claws on the prowlers between the pool and Barak's camp." } },
        { id = "h15-regthar-2", turnin = 850, accept = 851, npc = 3389, at = { 1413, 45.34, 28.41 },
          note = { ru = "851 (Верог) — позже, в Застойном оазисе.", en = "851 (Verog) is for later, at the Stagnant Oasis." } },

        ------------------------------------------------------------------
        -- The Crossroads, quick stop (level 16)
        ------------------------------------------------------------------
        { id = "h15-xr-tonga-877", turnin = 870, accept = 877, npc = 3448, at = { 1413, 52.26, 31.93 } },
        { id = "h15-xr-sergra-881", turnin = 903, accept = 881, npc = 3338, at = { 1413, 52.23, 31.01 },
          note = { ru = "Получите Рог Эчеяки.", en = "You get the Horn of Echeyakee." } },

        ------------------------------------------------------------------
        -- North-east: Echeyakee, Boulder Lode Mine, the Sludge Fen (level 16-17)
        ------------------------------------------------------------------
        { id = "h15-echeyakee", complete = 881, use = 10327, npc = 3475, at = { 1413, 55.86, 17.19 },
          note = { ru = "Протрубите в Рог Эчеяки на этом месте: появится белый лев Эчеяки (16), заберите шкуру. "
                       .. "Нет ещё бочонка Чэня — гляньте к югу (55.8, 20.0).",
                   en = "Blow the Horn of Echeyakee at this spot: the white lion Echeyakee (16) appears; loot "
                       .. "his hide. No Chen's Empty Keg yet: look just south (55.8, 20.0)." } },
        { id = "h15-mine", complete = 896, optional = true, at = { 1413, 60.8, 4.0 },
          note = { ru = "Только если взяли 896: рудник Валунов - громилы и надсмотрщики Торговой компании до изумруда «Кошачий глаз» "
                       .. "(редкая добыча). Босса Копперплага (19) обходите. Нет камня после ~20 убийств - идите дальше, шаг "
                       .. "пропустится сам.",
                   en = "Only if you took 896: Boulder Lode Mine - Venture Co. Enforcers and Overseers until the Cats Eye Emerald "
                       .. "drops (rare drop). Avoid Boss Copperplug (19). No emerald after ~20 kills: move on, the step is skipped by "
                       .. "itself." } },
        { id = "h15-sludge-fen", accept = 858, npc = 3439, at = { 1413, 56.52, 7.45 },
          note = { ru = "Илистая топь: крошшер Виззлкранка у вышки. Осторожно: Бригадир Гриллс (19, редкий). "
                       .. "Бочонок Чэня бывает к юго-востоку (57.2, 9.0).",
                   en = "The Sludge Fen: Wizzlecrank's Shredder by the derrick. Beware Foreman Grills (19, "
                       .. "rare). Chen's Empty Keg can lie to the south-east (57.2, 9.0)." } },
        { id = "h15-lugwizzle", complete = 858, npc = 3445, at = { 1413, 56.27, 8.58 },
          note = { ru = "Надсмотрщик Лагвиззл (18) ходит по платформе — заберите ключ зажигания.",
                   en = "Supervisor Lugwizzle (18) patrols the platform: loot the Ignition Key." } },
        { id = "h15-shredder", turnin = 858, accept = 863, npc = 3439, at = { 1413, 56.52, 7.45 },
          note = { ru = "Сопровождение начнётся сразу — нужно полное здоровье.",
                   en = "The escort starts at once: be at full health." } },
        { id = "h15-escape", complete = 863, at = { 1413, 55.51, 7.13 },
          note = { ru = "Идите рядом с крошшером. В конце нападут два наёмника Торговой компании.",
                   en = "Stay with the shredder. Two Venture Co. Mercenaries attack at the end." } },

        ------------------------------------------------------------------
        -- North: Samophlange console (level 17)
        ------------------------------------------------------------------
        { id = "h15-console", turnin = 894, accept = 900, object = 4141, at = { 1413, 52.40, 11.65 },
          note = { ru = "Пульт управления к западу от топи.", en = "The Control Console west of the fen." } },
        { id = "h15-valves", complete = 900, object = { 4072, 61936, 61935 }, at = { 1413, 52.35, 11.48 },
          note = { ru = "Закройте три вентиля. После топливного появятся два моба, после регулятора — один.",
                   en = "Close the three valves. The fuel valve spawns two mobs, the regulator valve one." } },
        { id = "h15-console-2", turnin = 900, accept = 901, object = 4141, at = { 1413, 52.40, 11.65 } },
        { id = "h15-sniggles", complete = 901, npc = 3471, at = { 1413, 52.84, 10.39 },
          note = { ru = "Механик Снигглс (16) в домике: ключ от пульта.",
                   en = "Tinkerer Sniggles (16) in the hut: the Console Key." } },
        { id = "h15-console-3", turnin = 901, accept = 902, object = 4141, at = { 1413, 52.40, 11.65 },
          note = { ru = "Самофланж везите в Кабестан позже.", en = "The Samophlange goes to Ratchet later." } },

        ------------------------------------------------------------------
        -- North-west: Vrang Wildgore and Walton (level 17)
        ------------------------------------------------------------------
        { id = "h15-vrang", accept = { 95494, 95507 }, npc = 3682, at = { 1413, 43.80, 12.21 },
          note = { ru = "Вранг Дикозлоб (торговец оружием) на холме: продайте хлам, почините снаряжение. Бочонок "
                       .. "Чэня бывает прямо здесь.",
                   en = "Vrang Wildgore (weaponsmith) on the hill: sell junk and repair. Chen's Empty Keg can lie "
                       .. "right here." } },
        { id = "h15-vrang-hunt", complete = { 95494, 95507 }, at = { 1413, 44.6, 14.6 },
          note = { ru = "К югу: 6 шкур с саванных патриархов и 8 добычи из сработавших капканов на земле. "
                       .. "Серпокоготные ящеры (16-18) бьют по нескольку раз подряд.",
                   en = "To the south: 6 Savannah Lion Hides from Savannah Patriarchs and 8 Trapped Game from "
                       .. "Sprung Traps on the ground. Sunscale Scytheclaws (16-18) hit several times in a "
                       .. "row." } },
        { id = "h15-vrang-2", turnin = { 95494, 95507 }, accept = 95495, npc = 3682, at = { 1413, 43.80, 12.21 },
          note = { ru = "Отнесите связку шкур отшельнику на гребне к западу.",
                   en = "Take the Bundle of Hides to the hermit on the ridge to the west." } },
        { id = "h15-walton", turnin = 95495, accept = 95621, npc = 261366, at = { 1413, 42.02, 11.45 },
          note = { ru = "Уолтон-кожевник в хижине на гребне.", en = "Walton the tanner in the hut on the ridge." } },
        { id = "h15-adamore", complete = 95621, at = { 1413, 41.7, 15.6 },
          note = { ru = "Разбитый караван к югу: капрал Адамор (17-18) — его приказы. Мобы стоят группами по "
                       .. "2-3, выманивайте по одному.",
                   en = "The wrecked caravan to the south: Corporal Adamore (17-18) for his orders. Mobs stand "
                       .. "in groups of 2-3: pull them one at a time." } },
        { id = "h15-walton-2", turnin = 95621, accept = 95508, npc = 261366, at = { 1413, 42.02, 11.45 } },
        { id = "h15-walton-scene", complete = 95508, at = { 1413, 41.96, 11.50 },
          note = { ru = "Сценка около минуты: встаньте за домом и ждите, Уолтон справится сам.",
                   en = "About a one-minute scene: stand behind the house and wait, Walton handles it." } },
        { id = "h15-walton-3", turnin = 95508, npc = 261366, at = { 1413, 42.02, 11.45 },
          note = { ru = "Награда: Большой меч Дикозлоба, если умеете двуручные мечи, иначе продайте.",
                   en = "Reward: Wildgore Greatsword if you can use two-handed swords, otherwise sell it." } },

        ------------------------------------------------------------------
        -- Witchwing harpies, then hearth (level 17)
        ------------------------------------------------------------------
        { id = "h15-harpies", complete = 867, at = { 1413, 40.8, 17.0 },
          note = { ru = "Гарпии Ведьмокрылые к юго-западу: 8 когтей. Заклинательницы ветра (17-18) западнее — "
                       .. "туда не ходите.",
                   en = "Witchwing harpies to the south-west: 8 Witchwing Talons. Windcallers (17-18) are "
                       .. "further west: stay out." } },
        { id = "h15-hearth-xroads", hearth = "The Crossroads", at = { 1413, 51.99, 29.89 },
          note = { ru = "Камень возвращения на Перекрёсток.", en = "Hearth to the Crossroads." } },

        ------------------------------------------------------------------
        -- The Crossroads, fourth visit (level 17)
        ------------------------------------------------------------------
        { id = "h15-xr-4-gazrog", turnin = 869, accept = 3281, npc = 3464, at = { 1413, 51.93, 30.32 },
          note = { ru = "Меньше 12 голов? Визгуны бегают прямо вокруг Перекрёстка.",
                   en = "Fewer than 12 heads? Screechers roam right around the Crossroads." } },
        -- 875 is carried: the Witchwing Slayers are killed on the way to Stonetalon (h-18)
        { id = "h15-xr-4-darsok", turnin = 867, accept = 875, npc = 3449, at = { 1413, 51.62, 30.90 },
          note = { ru = "Дарсок Быстрый Кинжал: сдайте когти и возьмите «Гарпий-лейтенантов» (6 колец с истребительниц Ведьмокрылых - "
                       .. "в следующем сегменте, по пути в Когтистые горы).",
                   en = "Darsok Swiftdagger: hand in the talons and take Harpy Lieutenants (6 rings from Witchwing Slayers - next "
                       .. "segment, on the way to Stonetalon)." } },
        { id = "h15-xr-4-sergra", turnin = 881, accept = 905, npc = 3338, at = { 1413, 52.23, 31.01 } },
        -- 899 is carried: tusks with 878, h-18
        { id = "h15-xr-4", accept = { 4921, 95774, 899 }, npc = 3432, at = { 1413, 51.95, 31.58 },
          note = { ru = "Манкрик: возьмите все три. 899 (60 клыков дыбогривых свинобразов) — с любых Дыбогривов; "
                       .. "основной сбор — в следующем сегменте вместе с 878 у Лагеря Таурахо. Клыки начинайте "
                       .. "собирать уже сейчас.",
                   en = "Mankrik: take all three. 899 (60 Bristleback Quilboar Tusks) drops from any Bristleback; "
                       .. "most are collected next segment together with 878 near Camp Taurajo. Start looting "
                       .. "tusks right away." } },
        { id = "h15-fly-ratchet", fly = "Ratchet", at = { 1413, 63.08, 37.16 },
          note = { ru = "Летите в Кабестан у Деврака.", en = "Fly to Ratchet from Devrak." } },

        ------------------------------------------------------------------
        -- Ratchet, third visit (level 17)
        ------------------------------------------------------------------
        -- 1483, 865 and 1069 are carried into h-18 (Ziz Fizziks in Stonetalon; Mebok)
        { id = "h15-ratchet-3-sputtervalve", turnin = { 902, 863 }, accept = 1483, npc = 3442, at = { 1413, 62.98, 37.22 },
          note = { ru = "Спаттервальв: сдайте оба и возьмите «Зиз Физзикс» (в Когтистые горы, следующий сегмент). Ветку Уэники не "
                       .. "берите.",
                   en = "Sputtervalve: turn in both and take Ziz Fizziks (Stonetalon, next segment). Skip the Wenikee follow-up." } },
        { id = "h15-ratchet-3", accept = { 865, 1069 }, npc = 3446, at = { 1413, 62.37, 37.62 },
          note = { ru = "Мебок Миззирикс: 5 рогов серпокоготных ящеров - на юге, у гнёзд; яйца пауков (1069) - в Когтистых горах, "
                       .. "следующий сегмент.",
                   en = "Mebok Mizzyrix: 5 horns from Sunscale Scytheclaws, in the south by the nests; the spider eggs (1069) are in "
                       .. "Stonetalon, next segment." } },
        { id = "h15-dizzywig-896-turnin", turnin = 896, npc = 3453, optional = true, at = { 1413, 63.35, 38.45 },
          note = { ru = "Есть изумруд — сдайте Диззивигу. Нет — пропустите шаг (896 можно бросить в любой момент; "
                       .. "в Кабестане будет ещё шанс его сдать).",
                   en = "Have the emerald: turn it in to Dizzywig. If not, skip the step (abandon 896 whenever you "
                       .. "like; you get one more chance to hand it in at Ratchet)." } },
        { id = "h15-keg-start", accept = 819, use = 4926, optional = true, at = { 1413, 62.26, 38.39 },
          note = { ru = "Нашли Пустой бочонок Чэня? Начните задание из бочонка. Нет бочонка — «Вперёд» на "
                       .. "этом и следующем шаге.",
                   en = "Found Chen's Empty Keg? Start the quest from the keg. No keg: press Forward on this and "
                       .. "the next step." } },
        -- 821 is carried: Drohn, h-18
        { id = "h15-drohn", turnin = 819, accept = 821, npc = 3292, optional = true, at = { 1413, 62.26, 38.39 },
          note = { ru = "Пивовар Дрон: сдайте и возьмите 821 - 5 клыков равнинного льва, 5 почек долгонога и рог рокочущей ящерицы. "
                       .. "Всё это по пути в следующем сегменте (Ишамухале, Лагерь Таурахо), сдача здесь же, когда вернётесь в "
                       .. "Кабестан на 20-м.",
                   en = "Brewmaster Drohn: turn in and take 821 - 5 Savannah Lion Tusks, 5 Plainstrider Kidneys and a Thunder Lizard "
                       .. "Horn. All of it is on the next segment's path (Ishamuhale, Camp Taurajo); turned in here when you are back "
                       .. "in Ratchet at 20." } },

        ------------------------------------------------------------------
        -- South: pirate crates, Stolen Silver, Stagnant Oasis, Verog, nests (level 17-18)
        ------------------------------------------------------------------
        { id = "h15-crate-1", complete = { [888] = { 1 } }, object = 3767, at = { 1413, 62.63, 49.63 },
          note = { ru = "Пиратский лагерь у берега: ящик «Торговый дом Дриззлика».",
                   en = "The shore pirate camp: the Drizzlik's Emporium crate." } },
        { id = "h15-crate-2", complete = { [888] = { 2 } }, object = 3768, at = { 1413, 63.58, 49.25 },
          note = { ru = "Второй ящик «Хрупкое - не ронять» рядом. 888 сдаётся в следующем сегменте.",
                   en = "The second crate, \"Fragile - Do Not Drop\", nearby. 888 is turned in next segment." } },
        { id = "h15-silver", complete = 3281, object = 147557, at = { 1413, 58.04, 53.87 },
          note = { ru = "Украденное серебро лежит на земле к юго-западу.",
                   en = "The Stolen Silver lies on the ground to the south-west." } },
        { id = "h15-horns-bg", complete = 865, bg = true, at = { 1413, 53.5, 49.5 },
          note = { ru = "Попутно: 5 целых рогов с серпокоготных ящеров.",
                   en = "Along the way: 5 Intact Raptor Horns from Sunscale Scytheclaws." } },
        { id = "h15-stagnant-oasis", complete = { 877, 848 }, object = 3737, at = { 1413, 55.61, 42.75 },
          note = { ru = "Застойный оазис: нырните к бурлящей расщелине (сухие семена). Доберите споры с грибов "
                       .. "вокруг оазиса. Колкары — для наручей. Бочонок Чэня бывает к востоку (56.5, 43.7) — "
                       .. "его возьмёт Дрон в начале следующего сегмента.",
                   en = "The Stagnant Oasis: dive to the Bubbling Fissure (Dried Seeds). Finish the spores from "
                       .. "the mushrooms around the oasis. Kolkar for the bracers. Chen's Empty Keg can lie to the "
                       .. "east (56.5, 43.7): Drohn takes it early next segment." } },
        { id = "h15-verog", complete = 851, npc = 3395, at = { 1413, 53.06, 41.74 },
          note = {
              ru = "Верог Дервиш (18) в лагере колкаров западнее оазиса: бейте кентавров, пока он "
                  .. "не появится.",
              en = "Verog the Dervish (18) in the Kolkar camp west of the oasis: kill centaurs until he shows up.",
          } },
        { id = "h15-nests", complete = 905, object = { 6907, 6908, 6906 }, at = { 1413, 52.36, 46.38 },
          note = { ru = "Убивайте серпокоготных ящеров ради 3 перьев и положите их в синее, жёлтое и красное "
                       .. "гнёзда.",
                   en = "Kill Sunscale Scytheclaws for 3 feathers and put them into the blue, yellow and red "
                       .. "nests." } },
        { id = "h15-horns", complete = 865, at = { 1413, 51.5, 48.5 },
          note = { ru = "Доберите рога серпокоготных ящеров вокруг гнёзд.",
                   en = "Finish the scytheclaw horns around the nests." } },

        ------------------------------------------------------------------
        -- Mankrik's wife, Razormane raiders, Camp Taurajo (level 18)
        ------------------------------------------------------------------
        -- 883 (optional): the hoof of the grey kodo Lakota'mani starts it; turned in at Jorn in Camp Taurajo below.
        { id = "h15-lakota", accept = 883, bg = true, use = 5099, at = { 1413, 47.19, 51.63 },
          note = {
              ru = "Только на 18+: Лакота'мани (22, серый кодо) бродит у 45-50, 49-53 - копыто начинает "
                  .. "задание. Не встретили - не ищите.",
              en = "Only at 18+: Lakota'mani (22, grey kodo) roams at 45-50, 49-53 - his hoof starts a quest. Not "
                  .. "seen - do not search.",
          } },
        { id = "h15-raiders", complete = 95774, at = { 1413, 49.6, 51.3 },
          note = { ru = "Налётчики Иглогривых к юго-западу: украшения Ольгры. С налётчиков могут падать и клыки "
                       .. "дыбогривых свинобразов для 899 — подбирайте.",
                   en = "Razormane Raiders to the south-west: Olgra's Adornments. The Raiders may also drop "
                       .. "Bristleback Quilboar Tusks for 899: loot them." } },
        { id = "h15-corpse", complete = 4921, npc = 10668, at = { 1413, 49.33, 50.32 },
          note = { ru = "Избитый труп в траве: поговорите с ним. Грозорылы (18-19) западнее — обходите.",
                   en = "The Beaten Corpse in the grass: talk to it. Stormsnouts (18-19) to the west: go "
                       .. "around." } },
        -- Race filter (B.5, E.1): the Tauren learned this point at mul03-taurajo.
        { id = "h15-fp-taurajo", race = { "Orc", "Scourge", "Skyborne", "Troll" }, fp = "Camp Taurajo", npc = 10378,
          at = { 1413, 44.45, 59.15 },
          note = { ru = "Лагерь Таурахо: Омуса Громовой Рог — откройте карту полётов.",
                   en = "Camp Taurajo: Omusa Thunderhorn - open the flight map." } },
        { id = "h15-sethearth-taurajo", sethearth = "Camp Taurajo", npc = 7714, at = { 1413, 45.58, 59.04 },
          note = { ru = "Трактирщица Бьюла: сделайте таверну домом (следующий сегмент возвращается сюда).",
                   en = "Innkeeper Byula: make this inn your home (the next segment comes back here)." } },
        { id = "h15-lakota-turnin", turnin = 883, optional = true, npc = 3387, at = { 1413, 44.86, 59.14 },
          note = { ru = "Только если нашли копыто Лакота'мани: Йорн Небесный Провидец. Иначе пропустите шаг.",
                   en = "Only if you found Lakota'mani's hoof: Jorn Skyseer. Otherwise skip the step." } },
        -- 878 is carried: the Bristlebacks are killed with 899 in h-18
        { id = "h15-mangletooth", accept = 878, npc = 3430, at = { 1413, 44.55, 59.26 },
          note = { ru = "Свинобраз Кривозуб в клетке рядом с Йорном: «Войны племён» (Дыбогривы - в следующем сегменте).",
                   en = "Mangletooth in the cage next to Jorn: Tribes at War (the Bristlebacks are for the next segment)." } },
        { id = "h15-fly-xroads-2", fly = "The Crossroads", at = { 1413, 51.50, 30.34 },
          note = { ru = "Летите на Перекрёсток у Омусы.", en = "Fly to the Crossroads from Omusa." } },

        ------------------------------------------------------------------
        -- The Crossroads, last visit; Regthar (level 18)
        ------------------------------------------------------------------
        -- Loop from the flight tower: Mankrik -> Tonga -> Sergra -> Gazrog, then west to Regthar and back to Helbrim
        -- (next to the flight master), so the timed 853 is accepted last and the next segment starts with the
        -- flight to Camp Taurajo.
        { id = "h15-xr-5-mankrik", turnin = { 4921, 95774 }, npc = 3432, at = { 1413, 51.95, 31.58 },
          note = { ru = "Манкрик. 899 (клыки) сдаётся в следующем сегменте, после Дыбогривов у Лагеря Таурахо.",
                   en = "Mankrik. 899 (tusks) is turned in next segment, after the quilboars near Camp "
                       .. "Taurajo." } },
        -- 880 and 3261 are carried: Tonga and Jorn, h-18
        { id = "h15-xr-5-tonga", turnin = 877, accept = 880, npc = 3448, at = { 1413, 52.26, 31.93 },
          note = { ru = "Тонга Рунный Тотем. 880 (панцири в Застойном оазисе) — в следующем сегменте.",
                   en = "Tonga Runetotem. 880 (shells at the Stagnant Oasis) is done in the next segment." } },
        { id = "h15-xr-5-sergra", turnin = 905, accept = 3261, npc = 3338, at = { 1413, 52.23, 31.01 },
          note = { ru = "Сергра. 3261 ведёт в Лагерь Таурахо к Йорну Небесному Провидцу — следующий сегмент.",
                   en = "Sergra. 3261 leads to Jorn Skyseer in Camp Taurajo: next segment." } },
        { id = "h15-xr-5", turnin = 3281, npc = 3464, at = { 1413, 51.93, 30.32 },
          note = { ru = "Газрог.",
                   en = "Gazrog." } },
        -- 852 is carried: Hezrul at the Lushwater Oasis, h-18
        { id = "h15-regthar-3", turnin = 851, accept = 852, npc = 3389, at = { 1413, 45.34, 28.41 },
          note = { ru = "На запад к Регтару Вратам Смерти: голова Верога. 852 (Хезрул) - в следующем сегменте. Потом обратно на "
                       .. "Перекрёсток.",
                   en = "West to Regthar Deathgate: Verog's head. 852 (Hezrul) is for the next segment. Then back to the Crossroads." } },
        -- 853 is carried: Zamah, Thunder Bluff (h-18), timed
        { id = "h15-end", turnin = 848, accept = 853, npc = 3390, at = { 1413, 51.44, 30.15 },
          note = { ru = "Хелбрим рядом с вышкой. ТАЙМЕР: на «Аптекаря Заму» (853) 45 минут - следующий сегмент начинается с полёта в "
                       .. "Лагерь Таурахо и дороги в Громовой Утёс.",
                   en = "Helbrim next to the flight tower. TIMER: Apothecary Zamah (853) has 45 minutes - the next segment starts "
                       .. "with the flight to Camp Taurajo and the way to Thunder Bluff." } },
    },
})
