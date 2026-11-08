-- FastesBoooy_Horde / Segments/08_h-44-swamp-stranglethorn.lua
--
-- Library segment "h-44-swamp-stranglethorn": levels 44-46, class-neutral (Undead Paladin and Skyborne Druid, Horde).
-- Kargath -> fly Undercity -> zeppelin to Grom'gol (hearth, 572 / 584 / 598) -> Bloodscalp chiefs (584) -> Nesingwary
-- (196, 193) -> north through Duskwood and Deadwind Pass -> Swamp of Sorrows: Stonard (flight point, 1420, 1424, 698,
-- 1430) -> Pool of Tears -> east coast -> Tok'Kar (698 > 699) -> north-east coast (699, 1430) -> Galen's escort (1393)
-- -> Stonard (1424 > 1429, 1430) -> Misty Reed Strand (699 > 1422 > 1426 > 1427 > 1428) -> hearth Grom'gol ->
-- Stranglethorn: Grom'gol (584 > 585 / 586), Jungle Stalkers (572, 196), Grom'gol (572 > 571) -> fly Booty Bay (hearth,
-- every Booty Bay quest) -> Bloodsail Correspondence -> Mistvale Valley (571, 606, 349 > Mokk 348) -> Shaky -> Booty
-- Bay (607 > 609, 348, 597 > 599 > 604, 576, 587) -> Ruins of Aboraz (621, 609) -> Venture Co. mine (600) ->
-- Skullsplitter ruins (585, 586, 598, 209) -> Bhag'thera (193) -> Nesingwary -> Grom'gol (585 / 586 > 588 > 589, 598,
-- 571 > 573) -> basilisks (589) -> naga (573, 617) -> Grom'gol -> hearth Booty Bay -> pirates south of Booty Bay (604,
-- 576, 587; level gate) -> Bloodsail ships (608) -> Booty Bay -> boat dock (to Ratchet, next segment).
-- Plan: research plan60.md section 4.8 / plan60.json segments[8] (anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1418 (Badlands) / 1458 (Undercity) / 1420 (Tirisfal Glades) / 1434 (Stranglethorn Vale) /
-- 1431 (Duskwood) / 1435 (Swamp of Sorrows), map percent, from tools/data/forever_db.lua: NPC / object spawns for
-- npc / object steps, centroids of the objective mob / object spawns of the area used for complete steps (h44 tools:
-- research scratch h44/cen.lua, h44/obj.lua). Travel points (not checked in game): the spirit healer 6491 south of
-- Darkshire (Duskwood 75.09,59.02), the Horde camp of Apothecary Faustin 5414 at the Deadwind Pass road (Duskwood
-- 87.5,35.2 = Deadwind Pass 27.8,29.0 by the QuestieDB world bounds), the west end of the Swamp road (Stonard Scout
-- 861 patrol spawn 14.8,52.2).
-- ruRU names in the notes: Wowhead Forever ruRU tooltips (nether.wowhead.com/forever/ru/tooltip/...).
--
-- Hub plan (Forever DB; every quest is open to Scourge and Skyborne Horde characters of any class):
--   GG 0 : sethearth Grom'gol; 572 (Mok'thardin), 584 (Nimboya), 598 (Kin'weelay); Bloodscalp chiefs (584) and
--          Nesingwary 196 + 193 on the way north (the camp is on the road to Duskwood).
--   SW 1 : Stonard: fp, 1420 (Helgrum), 1424 (Fel'zerul), 698 + 1430 (Dar); crocolisks (698), Pool of Tears (1424),
--          east coast crawlers (1430); Tok'Kar 698 > 699; north-east snappers (699) + crawlers; Galen 1393 (escort) >
--          strongbox; Stonard 1424 > 1429 (carried to the Hinterlands, h-50), 1430.
--   SW 2 : Tok'Kar 699 > 1422 > Katar 1426 (murlocs, inkspewers, flesheaters) > 1427 > Tok'Kar > Katar 1428
--          (inkspewers, flesheaters, oracles) > Katar; hearth Grom'gol.
--   GG 1 : cauldron 584 > 585 + 586; Jungle Stalkers (572, 196); Mok'thardin 572 > 571; fly Booty Bay.
--   BB 1 : sethearth; 669 (Seahorn), 209 (Kebok), 600 + 621 (Crank), 348 (Fin), 606 + 2872 (MacKinley; 2872 is carried
--          to Steamwheedle Port, h-46), 617 (Bloads), 595 (Crazz); Bloodsail Correspondence 595 > 597.
--   M 1  : Unbagwa 349; Elder Mistvale Gorillas (571, 606, 349 fang); Unbagwa 349 > Mokk (348); Shaky 606 > 607.
--   BB 2 : MacKinley 607 > 609; Fin 348; Crazz 597 > 599 + Dizzy 576 + Deeg 587; Seahorn 599 > 604.
--   E    : Ruins of Aboraz (621, 609), Venture Co. mine (600), Zul'Mamwe (586, 585 #3), Ziata'jai (585 #2), Balia'mah
--          (585 #1), necklaces (598) and tusks (209) from every Skullsplitter, Bhag'thera (193); Nesingwary 196, 193.
--   GG 2 : 585 + 586 > 588 > 589, 598; 571 > 573; basilisks (589), naga explorers + Holy Spring (573, 617);
--          GG 3: 573, 589; hearth Booty Bay.
--   BB 3 : 209, 600 + 621, 617, 609; pirates south of Booty Bay (604, 576, 587), level gate; 576, 587, 604 > 608;
--          Bloodsail ships (608); 608; boat dock.
-- Deviations from the plan (documented in the handoff):
--   * 591 The Mind's Eye (Mai'Zoth, level 47 ELITE - Wowhead Forever) and with it 592 Saving Yenniku are not taken;
--     592 is therefore not carried out. 613 Cracking Maury's Foot (Maury's Key drops only from the Mosh'Ogg ELITE
--     ogres) is not taken. 197 Raptor Mastery (Tethis, level 43 ELITE, turn-in back at Nesingwary) is not taken.
--     193 (Bhag'thera, level 40 ELITE) is kept: by then the player is 45, the cat is 5 levels lower (note says so).
--   * Added the Misty Reed Strand chain 1422 > 1426 > 1427 > 1428 (Tok'Kar / Katar; 12 k quest XP + 60 kills of 41-45
--     murlocs) - the plan notes list it, its hub table did not.
--   * 572 / 584 / 598 are accepted on the zeppelin arrival and the Bloodscalp chiefs (584) + Nesingwary accepts (196,
--     193) are done on the way north to Duskwood: one trip to the north fewer (Nesingwary is passed twice, not three
--     times).
--   * The hearthstone is bound in Grom'gol (zeppelin arrival) and used from Katar (Misty Reed Strand) back to
--     Grom'gol instead of flying from Stonard; it is bound in Booty Bay at the first Booty Bay visit and used from
--     Grom'gol at the end. Stonard is passed twice (h-45-stonard-end = the second pass, before the Misty Reed Strand).
--   * h-44-magtoor sits on the west end of the Swamp road (the route does not go to Magtoor / the Harborage: 1389 is
--     level 35, 20% XP at 44). h-44-uc-arrive is the flight Kargath -> Undercity itself (completes on landing).
--     h-44-stonard-flight-master is the flight point step on arrival (no flight out of Stonard, hearth instead).
--     h-46-bootybay-end is the last step: the Booty Bay dock (Grizzlowe 9559, boat to Ratchet).
--   * Mid-way Booty Bay visit (after Mistvale) so that 609 Voodoo Dues (Ruins of Aboraz, on the way north) can be
--     done; 576 / 587 / 604 are taken then and done at the end south of Booty Bay with 608.
-- Skipped: 1389 / 93663 / 93176 (level 35), 1392 / 624 (random drops), 2932 (Hinterlands and back), 208 (King
--   Bangalash ELITE), 577 (level 36), 580 (level 50), 8551 (Gorlash ELITE), 670 (back to Arathi), 2760-2765 (Galvan,
--   blacksmithing), 1115-1122 (Dream Dust / Goblin Sponsorship chains, other zones).
-- XP (validator, 44.02 -> 46.01): quests 120 k (Classic values; 7.8 k of it estimated for 1422 / 349, which have no XP
--   in the data and are before the end gate), objective kills ~60 k, the rest ~48 k (~180 same-level kills) from the
--   end gate h-44-swamp-stranglethorn-level-gate (Bloodsail pirates 43-45 south of Booty Bay, 45 + 90%); the turn-ins
--   after it (576, 587, 604, 608) make 46.0. Densification pass (34-46): the optional gate h44-level-swamp (Monstrous
--   Crawlers 43-44 east of Katar, 44 + 75%) is gone - it only moved part of the grind to a lower level; added 1372
--   Nothing But The Truth (two NPCs side by side in the Deadwind road camp; its follow-up 1383 needs a Desolace drop,
--   so the rest of the chain stays out). Every other Swamp / Stranglethorn quest of 40-46 is taken or needs an elite,
--   a dungeon, a profession or another zone (list above). Group alternative: Zul'Farrak (Tanaris, next segment).
-- Automation notes: transient steps (fp, sethearth) come before the quest steps of their hub; accepts at one NPC are
--   merged into one step; the class insert anchor h-44-uc-arrive is the flight to Undercity (paladin: training in
--   Undercity after it; druid: a Moonglade insert fits BEFORE it, at Kargath, where the hearthstone is still bound).
FastesBoooy.AddLibrarySegment({
    id = "h-44-swamp-stranglethorn",
    title = { ru = "44-46 Болото Печали и Тернистая долина", en = "44-46 Swamp of Sorrows and Stranglethorn Vale" },
    zone = "Stranglethorn Vale",
    levels = { 44, 46 },
    steps = {
        ------------------------------------------------------------------
        -- Kargath -> Undercity -> zeppelin -> Grom'gol (44)
        ------------------------------------------------------------------
        { id = "h-44-uc-arrive", fly = "Undercity", npc = 4551, at = { 1458, 63.25, 48.56 },
          note = { ru = "Горрик (Каргат): полёт в Подгород.", en = "Gorrik (Kargath): fly to Undercity." } },
        { id = "h44-uc-exit", go = true, at = { 1420, 61.92, 64.85 },
          note = { ru = "Наверх на лифте и из Руин Лордерона к башне дирижаблей.",
                   en = "Up the lift and out of the Ruins of Lordaeron to the zeppelin tower." } },
        { id = "h44-zeppelin-gromgol", go = true, radius = 15, npc = 3150, at = { 1420, 61.78, 59.18 },
          note = { ru = "Гин Денбург: дирижабль в Лагерь Гром'гол (Тернистая долина), не в Оргриммар.",
                   en = "Hin Denburg: the zeppelin to Grom'gol Base Camp (Stranglethorn Vale), not to Orgrimmar." } },
        { id = "h-44-gromgol-arrive", go = true, radius = 40, npc = 3149, at = { 1434, 31.43, 29.91 },
          note = { ru = "Прилёт в Лагерь Гром'гол.", en = "Arrival at Grom'gol Base Camp." } },
        { id = "h44-sethearth-gromgol", sethearth = "Grom'gol Base Camp", npc = 5814, at = { 1434, 31.49, 29.75 },
          note = { ru = "Хозяин таверны Тулбек: камень - в Гром'гол (из Болота Печали вернётесь камнем).",
                   en = "Innkeeper Thulbek: bind your hearthstone to Grom'gol (you hearth back from the Swamp)." } },
        { accept = 572, npc = 2465, at = { 1434, 32.12, 29.24 },
          note = { ru = "Провозвестник Мок'тардин: 10 перьев тропических ловцов (ящеры к югу, позже).",
                   en = "Far Seer Mok'thardin: 10 Jungle Stalker Feathers (raptors to the south, later)." } },
        { accept = 584, npc = 2497, at = { 1434, 32.16, 27.72 },
          note = { ru = "Нимбойя: головы вождей Кровавого Скальпа - сейчас, по пути на север.",
                   en = "Nimboya: the Bloodscalp chiefs' heads - now, on the way north." } },
        { accept = 598, npc = 2519, at = { 1434, 32.27, 27.71 },
          note = { ru = "Кин'вилай: 25 ожерелий с Дробителей Черепов (восток, позже). Нет 629 (Коварный риф, h-34) - "
                       .. "задания не будет: пропустите (Skip) этот шаг и шаги 598.",
                   en = "Kin'weelay: 25 necklaces from the Skullsplitter trolls (east, later). No Vile Reef (629, h-34): "
                       .. "it is not offered - Skip this and the later 598 steps." } },
        { complete = 584, at = { 1434, 23.48, 8.83 },
          note = { ru = "На северо-запад во внутреннюю деревню Кровавого Скальпа: Ган'зулах (41) и Неззилок Зловещий "
                       .. "(40) рядом друг с другом. Тролли вокруг 36-37 - быстро.",
                   en = "North-west into the inner Bloodscalp village: Gan'zulah (41) and Nezzliok the Dire (40) stand "
                       .. "close together. The trolls around are 36-37 - quick." } },
        { id = "h-44-nesingwary-s-expedition", accept = 196, npc = 715, at = { 1434, 35.66, 10.81 },
          note = { ru = "На восток в лагерь Хеминга Эрнестуэя: 10 тропических ловцов (вместе с перьями 572).",
                   en = "East to Nesingwary's camp: 10 Jungle Stalkers (together with the 572 feathers)." } },
        { accept = 193, npc = 718, at = { 1434, 35.55, 10.55 },
          note = { ru = "Сэр С. Дж. Эрлгедин: клык Баг'тиры (элитная пантера 40, позже на северо-востоке).",
                   en = "Sir S. J. Erlgadin: the Fang of Bhag'thera (elite panther 40, later in the north-east)." } },

        ------------------------------------------------------------------
        -- Duskwood -> Deadwind Pass -> Swamp of Sorrows
        ------------------------------------------------------------------
        { id = "h44-duskwood-darkshire", go = true, radius = 60, at = { 1431, 75.09, 59.02 },
          note = { ru = "На север по дороге мимо Лагеря повстанцев (Альянс) в Сумеречный лес, по главной дороге на "
                       .. "восток. Темнолесье (стража Альянса) объезжайте с юга.",
                   en = "North on the road past the Rebel Camp (Alliance) into Duskwood, then east on the main road. "
                       .. "Go round Darkshire (Alliance guards) on its south side." } },
        { id = "h44-deadwind-road", go = true, radius = 60, npc = 5414, at = { 1431, 87.50, 35.20 },
          note = { ru = "На северо-восток к лагерю Орды у дороги на Перевал Мертвого Ветра (аптекарь Фаустин).",
                   en = "North-east to the Horde camp at the Deadwind Pass road (Apothecary Faustin)." } },
        { accept = 1372, npc = 5418, at = { 1431, 87.81, 35.63 },
          note = { ru = "В лагере: страж смерти Зредус - «Правда и только правда» (поговорить с Фаустином рядом).",
                   en = "In the camp: Deathstalker Zraedus - Nothing But The Truth (talk to Faustin next to him)." } },
        { turnin = 1372, npc = 5414, at = { 1431, 87.45, 35.25 },
          note = { ru = "Аптекарь Фаустин. Продолжение не берите: опухоль глубинного бродяги падает только в Пустошах.",
                   en = "Apothecary Faustin. Skip the follow-up: the Deepstrider Tumor drops only in Desolace." } },
        { id = "h-44-magtoor", go = true, radius = 60, at = { 1435, 14.80, 52.20 },
          note = { ru = "Через перевал на юго-восток, не сходя с дороги: вокруг Каражана мобы 55-60. Въезд в Болото "
                       .. "Печали; дальше дорога на восток в Каменор (Гавань Магтура на севере не нужна).",
                   en = "South-east through the pass, stay on the road: the mobs around Karazhan are 55-60. Into the "
                       .. "Swamp of Sorrows; then the road east to Stonard (Magtoor's Harborage to the north is not "
                       .. "needed)." } },

        ------------------------------------------------------------------
        -- Swamp of Sorrows 1: Stonard, Pool of Tears, east coast, Galen (44)
        ------------------------------------------------------------------
        { id = "h-44-stonard-flight-master", fp = "Stonard", npc = 6026, at = { 1435, 46.07, 54.83 },
          note = { ru = "Каменор: Брейк - откройте карту полётов.", en = "Stonard: Breyk - open the flight map." } },
        { id = "h-44-stonard-arrive", turnin = 1420, npc = 1442, at = { 1435, 47.74, 55.20 },
          note = { ru = "Хелгрум Быстроногий в большом зале: «Донесение Хелгруму».",
                   en = "Helgrum the Swift in the great hall: Report to Helgrum." } },
        { accept = 1424, npc = 1443, at = { 1435, 47.93, 54.78 },
          note = { ru = "Фел'зерул рядом: 10 артефактов Атал'ай у Озера Слез.",
                   en = "Fel'zerul next to him: 10 Atal'ai Artifacts at the Pool of Tears." } },
        { accept = { 698, 1430 }, npc = 5591, at = { 1435, 44.70, 57.21 },
          note = { ru = "Дар у западного входа: 8 боков острозубых кроколисков (кроколиски и крепкохваты) и 10 ножек "
                       .. "чудовищных крабов (восточный берег).",
                   en = "Dar by the west entrance: 8 Sawtooth Flanks (crocolisks and snappers) and 10 Monstrous "
                       .. "Crawler Legs (east coast)." } },
        { complete = 698, bg = true, at = { 1435, 55.33, 44.98 },
          note = { ru = "Попутно: острозубые кроколиски (38-39, между Каменором и озером) и крепкохваты (41-42, "
                       .. "восток) - бока.",
                   en = "On the way: Sawtooth Crocolisks (38-39, between Stonard and the lake) and Snappers (41-42, "
                       .. "east) - flanks." } },
        { id = "h-44-swamp-of-sorrows", complete = 1424, object = { 30854, 30855, 30856 }, at = { 1435, 70.42, 53.20 },
          note = { ru = "Озеро Слез у Храма Атал'Хаккара: 10 артефактов на берегах и мелководье. Драконоиды 41-45 "
                       .. "вокруг - по одному.",
                   en = "The Pool of Tears by the Temple of Atal'Hakkar: 10 artifacts on the shores and in the "
                       .. "shallows. The dragonkin around are 41-45 - one at a time." } },
        { complete = 1430, bg = true, at = { 1435, 96.53, 61.30 },
          note = { ru = "Попутно: чудовищные крабы (43-44) по всему восточному берегу - ножки.",
                   en = "On the way: Monstrous Crawlers (43-44) all along the east coast - legs." } },
        { id = "h-44-tok-kar-katar", turnin = 698, accept = 699, npc = 5592, at = { 1435, 81.32, 80.97 },
          note = { ru = "По берегу на юг к Ток'Кару (Берег Туманного Тростника): 6 когтей острозубых крепкохватов.",
                   en = "South along the coast to Tok'Kar (Misty Reed Strand): 6 Sawtooth Snapper Claws." } },
        { complete = { 699, 1430 }, at = { 1435, 87.52, 20.53 },
          note = { ru = "По восточному берегу на север: крепкохваты (когти) и крабы (ножки) до северо-востока.",
                   en = "North along the east coast: snappers (claws) and crawlers (legs) up to the north-east." } },
        { id = "h-44-galen-goodward", accept = 1393, complete = 1393, npc = 5391, at = { 1435, 65.47, 18.16 },
          note = { ru = "На запад: Гален Добростраж в клетке в лагере Заблудших. Сопроводите его (Заблудшие 36-39 "
                       .. "нападают по пути).",
                   en = "West: Galen Goodward in a cage in the Lost Ones' camp. Escort him (Lost Ones 36-39 attack on "
                       .. "the way)." } },
        { id = "h-44-galen-s-strongbox", turnin = 1393, object = 32569, at = { 1435, 47.81, 39.76 },
          note = { ru = "На юго-запад: сейф Галена в его лагере.",
                   en = "South-west: Galen's Strongbox at his camp." } },
        { turnin = 1424, accept = 1429, npc = 1443, at = { 1435, 47.93, 54.78 },
          note = { ru = "На юг в Каменор: Фел'зерул. «Изгнанник Атал'ай» - во Внутренние земли (позже).",
                   en = "South to Stonard: Fel'zerul. The Atal'ai Exile goes to the Hinterlands (later)." } },
        { id = "h-45-stonard-end", turnin = 1430, npc = 5591, at = { 1435, 44.70, 57.21 },
          note = { ru = "Дар.", en = "Dar." } },

        ------------------------------------------------------------------
        -- Swamp of Sorrows 2: Misty Reed Strand (44-45)
        ------------------------------------------------------------------
        { id = "h44-tok-kar-2", turnin = 699, accept = 1422, npc = 5592, at = { 1435, 81.32, 80.97 },
          note = { ru = "На юго-восток к Ток'Кару.", en = "South-east to Tok'Kar." } },
        -- WARN-OK (xp-unknown): 1422 is a talk quest without an XP value in the data (WCLBox 0); the estimate only
        -- moves the level before the end gate.
        { turnin = 1422, accept = 1426, npc = 5593, at = { 1435, 83.76, 80.41 }, -- WARN-OK: xp-unknown
          note = { ru = "Катор рядом: по 10 болотных мурлоков, чернильщиков и трупоедов.",
                   en = "Katar next to him: 10 Marsh Murlocs, Inkspewers and Flesheaters each." } },
        { complete = { [1426] = { 1, 2 } }, at = { 1435, 85.38, 86.31 },
          note = { ru = "Мурлоки и чернильщики на берегу к югу и востоку от Ток'Кара.",
                   en = "Murlocs and inkspewers on the shore south and east of Tok'Kar." } },
        { complete = { [1426] = { 3 } }, at = { 1435, 63.35, 84.87 },
          note = { ru = "На запад вдоль южного берега: трупоеды (43-44).",
                   en = "West along the south coast: flesheaters (43-44)." } },
        { turnin = 1426, accept = 1427, npc = 5593, at = { 1435, 83.76, 80.41 },
          note = { ru = "Катор.", en = "Katar." } },
        { turnin = 1427, npc = 5592, at = { 1435, 81.32, 80.97 },
          note = { ru = "Ток'Кар.", en = "Tok'Kar." } },
        { accept = 1428, npc = 5593, at = { 1435, 83.76, 80.41 },
          note = { ru = "Снова Катор: по 10 чернильщиков, трупоедов и оракулов.",
                   en = "Katar again: 10 inkspewers, flesheaters and oracles each." } },
        { complete = 1428, at = { 1435, 63.39, 84.56 },
          note = { ru = "Снова на южный берег: оракулы (44-45), трупоеды и чернильщики в одном месте.",
                   en = "Back to the south coast: oracles (44-45), flesheaters and inkspewers in one spot." } },
        { turnin = 1428, npc = 5593, at = { 1435, 83.76, 80.41 },
          note = { ru = "Катор.", en = "Katar." } },
        { id = "h44-hearth-gromgol", hearth = "Grom'gol Base Camp", at = { 1434, 31.49, 29.75 },
          note = { ru = "Камень возвращения в Гром'гол. На откате - в Каменор и полёт у Брейка в Гром'гол.",
                   en = "Hearth to Grom'gol. On cooldown: ride to Stonard and fly from Breyk to Grom'gol." } },

        ------------------------------------------------------------------
        -- Stranglethorn: Grom'gol, Jungle Stalkers (45)
        ------------------------------------------------------------------
        { id = "h-45-gromgol", turnin = 584, accept = { 585, 586 }, object = 2076, at = { 1434, 32.22, 27.60 },
          note = { ru = "Бурлящий котел у Нимбойи: сдайте головы, возьмите оба «Разговора».",
                   en = "The Bubbling Cauldron by Nimboya: hand in the heads, take both Speaking quests." } },
        { id = "h-44-stranglethorn-vale-field", complete = { 572, 196 }, at = { 1434, 29.16, 44.70 },
          note = { ru = "На юг: тропические ловцы (40-41) - 10 убийств и 10 перьев. Тетис (элита 43) ходит здесь же - "
                       .. "обходите.",
                   en = "South: Jungle Stalkers (40-41) - 10 kills and 10 feathers. Tethis (elite 43) roams here too - "
                       .. "avoid him." } },
        { turnin = 572, accept = 571, npc = 2465, at = { 1434, 32.12, 29.24 },
          note = { ru = "Мок'тардин: сухожилие старой гориллы (Мглистая долина, позже).",
                   en = "Mok'thardin: an Aged Gorilla Sinew (Mistvale Valley, later)." } },
        { id = "h44-fly-bootybay", fly = "Booty Bay", npc = 2858, at = { 1434, 26.87, 77.10 },
          note = { ru = "Тиста: летите в Пиратскую Бухту.", en = "Thysta: fly to Booty Bay." } },

        ------------------------------------------------------------------
        -- Booty Bay 1, Bloodsail Correspondence, Mistvale Valley (45)
        ------------------------------------------------------------------
        { id = "h44-sethearth-bootybay", sethearth = "Booty Bay", npc = 6807, at = { 1434, 27.04, 77.31 },
          note = { ru = "Хозяин таверны Втридорог: камень - в Пиратскую Бухту.",
                   en = "Innkeeper Skindle: bind your hearthstone to Booty Bay." } },
        { id = "h-44-booty-bay", turnin = 669, npc = 2487, at = { 1434, 27.17, 77.01 },
          note = { ru = "Командир флота Морской Рог (верх таверны): «Утонувшее сокровище». Продолжение (670) - обратно "
                       .. "в Арати, не берите.",
                   en = "Fleet Master Seahorn (top of the inn): Sunken Treasure. Skip the follow-up (670, back to "
                       .. "Arathi)." } },
        { accept = 209, npc = 737, at = { 1434, 27.00, 77.13 },
          note = { ru = "Кебок: 18 клыков Дробителей Черепов.", en = "Kebok: 18 Skullsplitter Tusks." } },
        { accept = { 600, 621 }, npc = 2498, at = { 1434, 27.12, 77.21 },
          note = { ru = "Шиззи Пуззырикс (низ таверны): 10 синих кристаллов (рудник Торговой компании) и 12 смесей "
                       .. "Занзила (руины Абораза).",
                   en = "Crank Fizzlebub (inn, bottom floor): 10 Singing Blue Crystals (Venture Co. mine) and 12 "
                       .. "Zanzil's Mixtures (Ruins of Aboraz)." } },
        { accept = 348, npc = 2486, at = { 1434, 27.61, 76.74 },
          note = { ru = "Фин Горемык: сердце Мокка (Мглистая долина).",
                   en = "Fin Fizracket: the Heart of Mokk (Mistvale Valley)." } },
        { accept = { 606, 2872 }, npc = 2501, at = { 1434, 27.78, 77.07 },
          note = { ru = "«Морской волк» Маккинли: потроха горилл для Трусишки и «Долг Столи» (в Танарис, следующий "
                       .. "сегмент).",
                   en = "\"Sea Wolf\" MacKinley: gorilla giblets for Shaky and Stoley's Debt (Tanaris, next segment)." } },
        { accept = 617, npc = 2494, at = { 1434, 26.76, 76.38 },
          note = { ru = "Капер Блоудс: 10 стеблей акириса (наги-исследователи).",
                   en = "Privateer Bloads: 10 Akiris Reeds (Naga Explorers)." } },
        { accept = 595, npc = 2490, at = { 1434, 28.10, 76.22 },
          note = { ru = "Первый помощник Кразз: переписка пиратов в лагере к северу.",
                   en = "First Mate Crazz: the pirates' correspondence in the camp to the north." } },
        { id = "h-44-bloodsail-correspondence", turnin = 595, accept = 597, object = 2083, at = { 1434, 27.28, 69.52 },
          note = { ru = "Из Бухты через туннель на север-запад к лагерю пиратов на берегу: письмо на ящике.",
                   en = "Out of Booty Bay through the tunnel, north-west to the pirate camp on the shore: the letter "
                       .. "on a crate." } },
        { id = "h45-mistvale", accept = 349, npc = 1449, at = { 1434, 35.27, 60.41 },
          note = { ru = "На северо-восток в Мглистую долину: знахарь Унбагва у входа - нужно 10 клыков горилл.",
                   en = "North-east into Mistvale Valley: Witch Doctor Unbagwa at the entrance - he needs 10 Gorilla "
                       .. "Fangs." } },
        { complete = { 571, 606, 349 }, at = { 1434, 32.89, 64.63 },
          note = { ru = "Старые гориллы из Мглистой долины (40-41): сухожилие, 5 потрохов и 10 клыков горилл "
                       .. "(~15-20 горилл).",
                   en = "Elder Mistvale Gorillas (40-41): the sinew, 5 giblets and 10 Gorilla Fangs (~15-20 "
                       .. "gorillas)." } },
        -- WARN-OK (xp-unknown, next step): 349 gives no XP (WCLBox 0); the estimate only moves the level before the gate.
        { turnin = 349, npc = 1449, at = { 1434, 35.27, 60.41 }, -- WARN-OK: xp-unknown
          note = { ru = "Унбагва вызывает три волны горилл, последняя - Мокк Дикарь (44).",
                   en = "Unbagwa summons three waves of gorillas, the last one is Mokk the Savage (44)." } },
        { complete = 348, at = { 1434, 35.05, 60.88 },
          note = { ru = "Убейте Мокка - сердце.", en = "Kill Mokk - the heart." } },
        { turnin = 606, accept = 607, npc = 2502, at = { 1434, 26.90, 73.59 },
          note = { ru = "На юг к Филиппу «Трусишке» у причала к северу от Бухты.",
                   en = "South to \"Shaky\" Phillipe at the dock north of Booty Bay." } },

        ------------------------------------------------------------------
        -- Booty Bay 2 (45)
        ------------------------------------------------------------------
        { id = "h45-bootybay-2", turnin = 607, accept = 609, npc = 2501, at = { 1434, 27.78, 77.07 },
          note = { ru = "Маккинли: Моури, Джон-Джон и Чаки у руин Абораза (север).",
                   en = "MacKinley: Maury, Jon-Jon and Chucky at the Ruins of Aboraz (north)." } },
        { turnin = 348, npc = 2486, at = { 1434, 27.61, 76.74 },
          note = { ru = "Фин Горемык.", en = "Fin Fizracket." } },
        { turnin = 597, accept = 599, npc = 2490, at = { 1434, 28.10, 76.22 },
          note = { ru = "Первый помощник Кразз.", en = "First Mate Crazz." } },
        { accept = 576, npc = 2493, at = { 1434, 28.59, 75.90 },
          note = { ru = "Одноглазый Диззи: его глаз у одного из пиратов Кровавого Паруса.",
                   en = "Dizzy One-Eye: his eye is on one of the Bloodsail pirates." } },
        { accept = 587, npc = 2488, at = { 1434, 26.92, 77.35 },
          note = { ru = "Диг: 15 понюшек с пиратов Кровавого Паруса.", en = "Deeg: 15 Snuff from Bloodsail pirates." } },
        { turnin = 599, accept = 604, npc = 2487, at = { 1434, 27.17, 77.01 },
          note = { ru = "Морской Рог: 10 висельников, карты и приказы - в конце, к югу от Бухты.",
                   en = "Seahorn: 10 Swashbucklers, the charts and the orders - at the end, south of Booty Bay." } },
        { complete = { 576, 587 }, bg = true, at = { 1434, 29.01, 70.27 },
          note = { ru = "Попутно: пираты Кровавого Паруса на берегу - понюшка и глаз Диззи.",
                   en = "On the way: Bloodsail pirates on the coast - snuff and Dizzy's eye." } },

        ------------------------------------------------------------------
        -- Ruins of Aboraz, Venture Co. mine, Skullsplitter ruins, Nesingwary (45)
        ------------------------------------------------------------------
        { id = "h-44-yenniku", complete = { 621, 609 }, at = { 1434, 38.06, 55.92 },
          note = { ru = "На север к руинам Абораза (у Йеннику): смесь Занзила со всех его троллей и наг; Моури и "
                       .. "Джон-Джон на западе руин, Чаки у Йеннику.",
                   en = "North to the Ruins of Aboraz (by Yenniku): Zanzil's Mixture from all his trolls and naga; "
                       .. "Maury and Jon-Jon on the west side, Chucky by Yenniku." } },
        { id = "h45-venture-mine", complete = 600, at = { 1434, 41.66, 43.70 },
          note = { ru = "На север к руднику Торговой компании: горнорабочие - 10 синих кристаллов.",
                   en = "North to the Venture Co. mine: Strip Miners - 10 Singing Blue Crystals." } },
        { complete = { 598, 209 }, bg = true, at = { 1434, 45.22, 36.19 },
          note = { ru = "Попутно: все Дробители Черепов - ожерелья (25) и клыки (18).",
                   en = "On the way: every Skullsplitter troll - necklaces (25) and tusks (18)." } },
        { complete = 586, at = { 1434, 46.38, 43.20 },
          note = { ru = "Руины Зул'Мамве на востоке: 8 охотников, 6 охотников за головами, 4 берсерка; Анатек Жестокий "
                       .. "(45) - доспех.",
                   en = "The Ruins of Zul'Mamwe to the east: 8 Hunters, 6 Headhunters, 4 Berserkers; Ana'thek the "
                       .. "Cruel (45) - the armor." } },
        { complete = { [585] = { 3 } }, object = 2893, at = { 1434, 47.65, 39.54 },
          note = { ru = "Трофейные черепа в северной части Зул'Мамве.",
                   en = "The trophy skulls in the north part of Zul'Mamwe." } },
        { complete = { [585] = { 2 } }, object = 2892, at = { 1434, 42.21, 36.11 },
          note = { ru = "На северо-запад: черепа в руинах Зиата'джай.",
                   en = "North-west: the skulls in the Ziata'jai Ruins." } },
        { complete = { [585] = { 1 } }, object = 2891, at = { 1434, 46.13, 32.33 },
          note = { ru = "На северо-восток: черепа в руинах Балиа'ма.",
                   en = "North-east: the skulls in the Balia'mah Ruins." } },
        { complete = { 598, 209 }, at = { 1434, 45.22, 36.19 },
          note = { ru = "Доберите ожерелья и клыки в руинах.", en = "Finish the necklaces and tusks in the ruins." } },
        { complete = 193, at = { 1434, 48.67, 24.16 },
          note = { ru = "Севернее: Баг'тира (элитная пантера 40, в незаметности) бродит у холмов - клык. Вы на 5 "
                       .. "уровней выше; не по силам - бросьте 193.",
                   en = "Further north: Bhag'thera (elite panther 40, stealthed) prowls the hills - her fang. You are 5 "
                       .. "levels higher; too hard - abandon 193." } },
        { id = "h45-nesingwary-2", turnin = 196, npc = 715, at = { 1434, 35.66, 10.81 },
          note = { ru = "На северо-запад к Эрнестуэю. Тетиса (197, элита) не берите.",
                   en = "North-west to Nesingwary. Skip Tethis (197, elite)." } },
        { turnin = 193, npc = 718, at = { 1434, 35.55, 10.55 },
          note = { ru = "Сэр С. Дж. Эрлгедин.", en = "Sir S. J. Erlgadin." } },

        ------------------------------------------------------------------
        -- Grom'gol, basilisks, naga (45-46)
        ------------------------------------------------------------------
        { id = "h45-gromgol-2", turnin = { 585, 586 }, accept = 588, object = 2076, at = { 1434, 32.22, 27.60 },
          note = { ru = "На юг в Гром'гол: котел.", en = "South to Grom'gol: the cauldron." } },
        { turnin = { 588, 598 }, accept = 589, npc = 2519, at = { 1434, 32.27, 27.71 },
          note = { ru = "Кин'вилай: 3 пульсирующих осколка с железозубых василисков. Без 598 - сдайте 588, возьмите "
                       .. "589 и нажмите Skip.",
                   en = "Kin'weelay: 3 Pulsing Blue Shards from Ironjaw Basilisks. Without 598: hand in 588, take 589, "
                       .. "then Skip." } },
        { turnin = 571, accept = 573, npc = 2465, at = { 1434, 32.12, 29.24 },
          note = { ru = "Мок'тардин: 10 наг-исследователей и вода Святого источника.",
                   en = "Mok'thardin: 10 Naga Explorers and Holy Spring Water." } },
        { complete = 589, at = { 1434, 43.13, 47.78 },
          note = { ru = "На юго-восток: железозубые василиски (43-44) у рудника.",
                   en = "South-east: Ironjaw Basilisks (43-44) by the mine." } },
        { complete = { 573, 617 }, at = { 1434, 26.23, 62.02 },
          note = { ru = "На юго-запад к берегу: наги-исследователи (43-44) - 10 убийств и стебли акириса; воду "
                       .. "наберите в Святом источнике (29,62).",
                   en = "South-west to the coast: Naga Explorers (43-44) - 10 kills and the Akiris Reeds; fill the "
                       .. "water at the Holy Spring (29,62)." } },
        { turnin = 573, npc = 2465, at = { 1434, 32.12, 29.24 },
          note = { ru = "На север в Гром'гол: Мок'тардин.", en = "North to Grom'gol: Mok'thardin." } },
        { turnin = 589, npc = 2519, at = { 1434, 32.27, 27.71 },
          note = { ru = "Кин'вилай. «Око Разума» (591) не берите: Май'Зот - элита 47.",
                   en = "Kin'weelay. Skip The Mind's Eye (591): Mai'Zoth is an elite 47." } },
        { id = "h44-hearth-bootybay", hearth = "Booty Bay", at = { 1434, 27.04, 77.31 },
          note = { ru = "Камень возвращения в Пиратскую Бухту. На откате - Тиста: полёт в Бухту.",
                   en = "Hearth to Booty Bay. On cooldown: Thysta, fly to Booty Bay." } },

        ------------------------------------------------------------------
        -- Booty Bay 3, pirates, Bloodsail ships (46)
        ------------------------------------------------------------------
        { id = "h46-bootybay-3", turnin = 209, npc = 737, at = { 1434, 27.00, 77.13 },
          note = { ru = "Кебок.", en = "Kebok." } },
        { turnin = { 600, 621 }, npc = 2498, at = { 1434, 27.12, 77.21 },
          note = { ru = "Шиззи Пуззырикс.", en = "Crank Fizzlebub." } },
        { turnin = 617, npc = 2494, at = { 1434, 26.76, 76.38 },
          note = { ru = "Капер Блоудс.", en = "Privateer Bloads." } },
        { turnin = 609, npc = 2501, at = { 1434, 27.78, 77.07 },
          note = { ru = "Маккинли. «Вскрыть ногу Моури» (613) не берите: ключ падает с элитных огров Мош'Огг.",
                   en = "MacKinley. Skip Cracking Maury's Foot (613): the key drops from the elite Mosh'Ogg ogres." } },
        { id = "h46-pirate-camp", complete = { 604, 576, 587 }, at = { 1434, 28.20, 82.21 },
          note = { ru = "Лагерь пиратов к югу от Бухты: карты и приказы на столах, висельники, понюшка, глаз Диззи.",
                   en = "The pirate camp south of Booty Bay: the charts and orders on the tables, Swashbucklers, "
                       .. "snuff, Dizzy's eye." } },
        -- WARN-OK (level-grind, next step): end-of-segment gate of the plan, the only grind of the segment; the
        -- turn-ins after it make 46.0 (the hand-off level of h-46).
        { id = "h-44-swamp-stranglethorn-level-gate", level = { 45, 0.90 }, at = { 1434, 28.20, 82.21 }, -- WARN-OK: level-grind
          note = { ru = "Цель: 45 + 90% (сдачи ниже дадут 46 - уровень Танариса). Не хватает - пираты Кровавого Паруса "
                       .. "здесь и вдоль берега (морские волки и волхвы 43-45). В группе быстрее: Зул'Фаррак (Танарис).",
                   en = "Target: 45 + 90% (the turn-ins below make 46, the level for Tanaris). Short: the Bloodsail "
                       .. "pirates here and along the coast (Sea Dogs and Elder Magi 43-45). Faster in a group: "
                       .. "Zul'Farrak (Tanaris)." } },
        { turnin = 576, npc = 2493, at = { 1434, 28.59, 75.90 },
          note = { ru = "Одноглазый Диззи.", en = "Dizzy One-Eye." } },
        { turnin = 587, npc = 2488, at = { 1434, 26.92, 77.35 },
          note = { ru = "Диг.", en = "Deeg." } },
        { turnin = 604, accept = 608, npc = 2487, at = { 1434, 27.17, 77.01 },
          note = { ru = "Морской Рог: капитаны трёх кораблей к югу.",
                   en = "Seahorn: the captains of the three ships to the south." } },
        { id = "h46-bloodsail-ships", complete = 608, at = { 1434, 30.92, 89.04 },
          note = { ru = "Корабли у Дикого Берега: капитан Штиллец (46), капитан Кильватель (47), командир флота "
                       .. "Фираллон (48), у каждого телохранитель и матросы 42-44. Тяните по одному.",
                   en = "The ships off the Wild Shore: Captain Stillwater (46), Captain Keelhaul (47), Fleet Master "
                       .. "Firallon (48), each with a bodyguard and 42-44 deckhands. Pull one at a time." } },
        { turnin = 608, npc = 2487, at = { 1434, 27.17, 77.01 },
          note = { ru = "Командир флота Морской Рог.", en = "Fleet Master Seahorn." } },
        { id = "h-46-bootybay-end", go = true, radius = 15, npc = 9559, at = { 1434, 26.08, 73.35 },
          note = { ru = "Причал: Гриззлоу - корабль в Кабестан (следующий сегмент).",
                   en = "The dock: Grizzlowe - the boat to Ratchet (next segment)." } },
    },
})
