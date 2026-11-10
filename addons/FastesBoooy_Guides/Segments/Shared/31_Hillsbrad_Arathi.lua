-- FastesBoooy_Guides / Segments / Shared / 31_Hillsbrad_Arathi.lua
--
-- Library segment "h-31-hillsbrad-arathi": levels 31-34, class-neutral (Undead Paladin and Skyborne Druid, Horde).
-- Thunder Bluff -> fly Camp Taurajo (1153) -> fly Orgrimmar -> zeppelin -> Undercity (1164) -> fly Tarren Mill (hearth
-- bound there) -> two
-- Hillsbrad / Alterac loops (Syndicate camp, Growless Cave, Dalaran camp, Hillsbrad town hall; Alterac yeti cave,
-- Dalaran dome, Azurelode Mine, Growless Cave, Helcular's Grave, Mudsnout gnolls) -> optional Strahnbrad (Gol'dir) ->
-- through Thoradin's Wall into Arathi (Boulderfist Hall, Dabyrie's Farmstead, Shards of Myzrael) -> Hammerfall
-- (flight point, hearth) -> Witherbark Village (level gate) + Drywhisker kobolds -> Hammerfall -> Fleshstalkers +
-- Boulderfist Brutes -> Northfold Manor -> hearth Hammerfall.
-- Plan: research plan60.md section 4.4 / plan60.json segments[4] (anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1456 (Thunder Bluff) / 1454 (Orgrimmar) / 1411 (Durotar) / 1420 (Tirisfal Glades) /
-- 1458 (Undercity) / 1424 (Hillsbrad Foothills) / 1416 (Alterac Mountains) / 1417 (Arathi Highlands), map percent,
-- from tools/data/forever_db.lua: NPC / object spawns for npc / object steps, centroids of the objective mob /
-- object spawns of the area used for complete steps (h31 tools: research scratch h31/cen.lua). Route facts (check in
-- game): the way Tarren Mill -> Thoradin's Wall gate (Hillsbrad 81.5,52.2 is an Elder Gray Bear spawn south-west of
-- Durnholde; the gate Arathi 20.5,30.5 is estimated from the zone geometry (QuestieDB conversion.json world bounds):
-- Hillsbrad spawns reach Arathi 20,26 and Arathi spawns start at 19.5,34) and the Hillsbrad Fields -> Tarren Mill road
-- point 49.0,38.0 (Starving Mountain Lions, as in h-22).
-- ruRU names in the notes: Wowhead Forever ruRU tooltips (nether.wowhead.com/forever/ru/tooltip/...).
--
-- Hub plan (Forever DB; every quest is open to Scourge and Skyborne Horde characters of any class):
--   TB/UC: fly Camp Taurajo: 1153 (Tatternack, from h-27; Taurajo is a short hop off the Thunder Bluff -> Orgrimmar
--          flight); fly Orgrimmar, zeppelin to Tirisfal, optional 1013 (Bel'dugur: The Book of Ur from the optional
--          Shadowfang Keep run of h-22, quest level 26 = full XP at 31), 1164 (Genavie Callow, next to the Undercity
--          flight master), fly Tarren Mill.
--   TM1  : hearth (Innkeeper Shay); 552 (Thaivand), 533 (Krusk), 544 (Voidglare), 556 (Bel'varil), 676 (Tallow),
--          509 (Lydon). 532 and 567 come in from h-22.
--   L1   : south Alterac Syndicate camp (533 missive) -> Growless Cave yetis (552 rod) -> Dalaran internment camp
--          (544 traitors + 556 tokens) -> Hillsbrad town hall (532; 567 Clerk Horrace) -> Tarren Mill.
--   TM2  : 556 > 557 (Bel'varil), 544 > 545 (Voidglare), 532 > 539 (Darthalia), 533 > 503 (Krusk), 552 > 553
--          (Thaivand).
--   L2   : Alterac yeti cave (553 Flame of Uzel) -> Dalaran dome, south side (545 summoners + slaves, 557 bracers)
--          -> Azurelode Mine (539; 567 Miner Hackett) -> Growless Cave (553 Flames of Azel and Veraz) -> Helcular's
--          Grave (553) -> Mudsnout gnolls (509 blossoms) -> Tarren Mill.
--   TM3  : 557 (Bel'varil), 545 (Voidglare), 509 > 513 (Lydon); optional Strahnbrad out-and-back (Jailor Borhuin
--          37 key, free Gol'dir: 503 > 506; 506 at Krusk); 539 + 567 (Darthalia) = h-33-tarrenmill-end.
--   AR   : Thoradin's Wall gate -> Boulderfist Hall (676) -> Dabyrie's Farmstead (1164) -> Shards of Myzrael (642).
--   HF1  : fp, hearth; 655 (Gor'mul); 676 > 677 (Drum Fel); 655 > 671 + 672 (Tor'gan); 97539 (Victor, Forever-new).
--   A    : Witherbark Village (677, level gate), Drywhisker kobolds (642 motes) -> Iridescent Shards (642); raptor
--          eyes (672) and spidersilk (97539) all the time.
--   HF2  : 672 > 674 (Tor'gan) > 675 (Gor'mul); 677 > 678 (Drum Fel); 675 > 701 (Tor'gan).
--   B    : Highland Fleshstalkers (701) + Boulderfist Brutes / Magi (678) -> Boulderfist Hall -> Northfold Manor
--          (671) -> hearth.
--   HF3  : 678 (Drum Fel); 701 + 671 > 702 (Tor'gan) > 847 (Gor'mul); 97539 (Victor); 847 (Tor'gan) =
--          h-34-hammerfall-end.
-- Deviations from the plan:
--   * 639 Sigil of Strom is not taken: the Sigil drops only from the Stromgarde Syndicate (Prowler 36-37, Conjuror
--     35-36, Magus 37-38), which are ELITE (DB rank 1, Wowhead Forever tooltip "Elite"). h-41 (level 41) has to
--     accept it itself before 640.
--   * 651 Stones of Binding is not taken after 642: every binding circle holds 12-16 Exiles of level 38-39 (Burning /
--     Cresting / Thundering / Rumbling Exile) and the Inner and East circles an elite 42 (Thenan, Fozruk). At 33 that
--     is not soloable; h-41 does 651 before 652 / 688 / 687. The plan anchor h-31-stone-of-inner (a travel step) is
--     a go step at Boulderfist Hall in loop B, the closest safe point to the Stone of Inner Binding.
--   * Added 678 Call to Arms (plan: h-41): its Boulderfist Brutes / Magi (35-37) stand next to the 701 Fleshstalkers,
--     and 677 is turned in before loop B. h-41 continues with 679 / 680.
--   * Strahnbrad (503 / 506) is optional and an out-and-back trip from Tarren Mill before h-33-tarrenmill-end: Gol'dir
--     stands in a 34-37 town (Syndicate Spies, Argus Shadow Mages, Jailor Borhuin 37) with Baron Vardus (40) next
--     to him, at ~31.6 in the validator's model; the direct line Strahnbrad -> Alterac yeti cave would cross
--     Crushridge Hold (ogres 34-36, elites 38-40). 503 is still accepted at TM2 (abandon it when skipping).
--   * 567 Dangerous!: Horrace (town hall, loop 1) and Hackett (Azurelode Mine, loop 2). Objectives 2 + 4 (Wilkes,
--     Kalaba) were killed in h-22, but the state format cannot record partial objectives, so the town-hall step also
--     lists them (leftovers are in the fields next to it; ~250 kill XP counted twice).
--   * Added Forever-new 97539 Silky Sutures (Doctor Gregory Victor, Hammerfall; Surgical Spidersilk from the Plains
--     Creepers that are everywhere on the Arathi loops; XP unknown; ender Victor: DB supplement from the Wowhead
--     Forever tooltip "Return ... to Doctor Gregory Victor in Hammerfall"). On the path, so not optional.
--   * Hearthstone: bound in Tarren Mill on arrival and not used in Hillsbrad (the druid's level-32 insert after
--     h-33-tarrenmill-end uses it to come back from Moonglade), bound in Hammerfall on arrival there and used from
--     Northfold Manor at the end of loop B.
--   * Level gate in Witherbark Village (loop A), not at the end of the segment: the player meets the 35-38 kobolds,
--     Fleshstalkers and Brutes of the last loops at 33.4+ instead of ~32.4.
-- Skipped: 541 / 547 (Dun Garok, elites), 518 Crown of Will (Crushridge elites, 34+), 7321 (cooking), 1361
--   (breadcrumb to Desolace), 535 Valik (270 XP), 515 (back from Faranell), 566 (40), 93680 / 92434 / 97287 / 96984 /
--   96986 (Forever City of Dalaran dungeon chain: object 670427 / Modera image positions and Horde access unknown),
--   95663 (Excavation Site dungeon), 673 / 679 / 680 (40, h-41), 1051 (SM Graveyard + elite Nancy Vishas), 92519 /
--   92707 / 92867 (no giver in the data), 79976 / 79949 (SoD-era ids).
-- Carried out: 513 (Faranell, Undercity), 1164 (Genavie Callow, Undercity) -> h-34; 5762 (Hemet, Stranglethorn);
--   1106 (from h-27, Martek in the Badlands, h-41).
-- XP (validator, Classic quest XP + objective kills, optional steps counted): quests ~67 k (1153 and the optional
--   1013 included) + objective kills ~44 k from 31.01. The gate h-31-hillsbrad-arathi-level-gate (33 + 43%: ~269
--   same-level kills in the validator's model, ~323 without the optional steps, fewer with the mobs killed on the
--   way) covers the rest; the turn-ins and objective kills after it make 34.05 in both cases.
-- Automation notes: accepts at one NPC sit in one step; transient steps (fp, sethearth, fly, go, hearth) come before
--   the quest steps of the same place. The class insert anchors h-31-uc-arrive (next: fly), h-31-tarrenmill-arrive
--   (sethearth; next: Thaivand) and h-33-tarrenmill-end (Darthalia, last Tarren Mill step; next: the go step east)
--   are not followed by a same-NPC accept. The optional Strahnbrad steps sit before the mandatory Darthalia turn-in:
--   a player who skips them just turns in at Darthalia and the engine fast-forwards them.
if not FastesBoooy.AddLibraryInsert then return end
FastesBoooy.AddLibrarySegment({
    id = "h-31-hillsbrad-arathi",
    title = { ru = "31-34 Хилсбрад, Альтеракские горы, Нагорье Арати",
              en = "31-34 Hillsbrad, Alterac Mountains, Arathi Highlands" },
    zone = "Arathi Highlands",
    levels = { 31, 34 },
    steps = {
        ------------------------------------------------------------------
        -- Thunder Bluff -> Orgrimmar -> Undercity (level 31)
        ------------------------------------------------------------------
        { id = "h-31-tb-fly", go = true, radius = 10, npc = 2995, at = { 1456, 47.00, 49.83 },
          note = { ru = "С Вершины Старейшин по мостам на центральную вершину: распорядитель ветрокрылов Тал.",
                   en = "From Elder Rise over the bridges to the central mesa: wind rider master Tal." } },
        { fly = "Camp Taurajo", npc = 10378, at = { 1413, 44.45, 59.15 },
          note = { ru = "Сначала летите в Лагерь Таурахо (почти по пути в Оргриммар).",
                   en = "First fly to Camp Taurajo (almost on the way to Orgrimmar)." } },
        { turnin = 1153, npc = 3433, at = { 1413, 45.10, 57.68 },
          note = { ru = "Таттернак Стальной Горн рядом с распорядителем полётов: образец руды. Руда не выпала — бросьте 1153 "
                       .. "и летите сразу в Оргриммар.",
                   en = "Tatternack Steelforge next to the flight master: the ore sample. No ore dropped: abandon 1153 and "
                       .. "fly straight to Orgrimmar." } },
        { id = "h-31-org", fly = "Orgrimmar", npc = 3310, at = { 1454, 45.12, 63.89 },
          note = { ru = "Омуса: летите в Оргриммар.", en = "Omusa: fly to Orgrimmar." } },
        { go = true, radius = 15, npc = 9564, at = { 1411, 50.82, 13.54 },
          note = { ru = "Через главные ворота на восток к башне дирижаблей: площадка Фреззы, дирижабль в Тирисфальские "
                       .. "леса (Подгород).",
                   en = "Out through the main gate, east to the zeppelin tower: Frezza's platform, the zeppelin to "
                       .. "Tirisfal Glades (Undercity)." } },
        { go = true, radius = 40, npc = 9566, at = { 1420, 60.74, 58.87 },
          note = { ru = "Прибытие к башне в Тирисфальских лесах (Запетта).",
                   en = "Arrival at the Tirisfal Glades tower (Zapetta)." } },
        { turnin = 1013, npc = 2934, at = { 1458, 53.74, 54.46 }, optional = true,
          note = { ru = "Если брали «Книгу Ура» в Крепости Темного Клыка: в Подгород, хранитель Бел'дугур (5600 опыта).",
                   en = "If you got The Book of Ur in Shadowfang Keep: into the Undercity, Keeper Bel'dugur (5600 XP)." } },
        { id = "h-31-uc-arrive", accept = 1164, npc = 4486, at = { 1458, 63.83, 49.45 },
          note = { ru = "В Руины Лордерона, на лифте вниз: Генави Кэллоу рядом с распорядителем полётов — «Ограбить "
                       .. "воров» (братья Дабири, Нагорье Арати).",
                   en = "Into the Ruins of Lordaeron, take a lift down: Genavie Callow next to the flight master - To "
                       .. "Steal From Thieves (the Dabyrie brothers, Arathi Highlands)." } },
        { id = "h-31-undercity-flight-master", fly = "Tarren Mill", npc = 2389, at = { 1424, 60.14, 18.62 },
          note = { ru = "Майкл Гаррет: летите на Мельницу Таррен.", en = "Michael Garrett: fly to Tarren Mill." } },

        ------------------------------------------------------------------
        -- Tarren Mill, first visit (level 31)
        ------------------------------------------------------------------
        { id = "h-31-tarrenmill-arrive", sethearth = "Tarren Mill", npc = 2388, at = { 1424, 62.78, 19.03 },
          note = { ru = "Хозяин таверны Шай: привяжите камень к Мельнице Таррен.",
                   en = "Innkeeper Shay: bind your hearthstone to Tarren Mill." } },
        { accept = 552, npc = 2429, at = { 1424, 63.88, 19.66 },
          note = { ru = "Новобранец Тайлванд: «Месть Гелькулара» — жезл с йети.",
                   en = "Novice Thaivand: Helcular's Revenge - the rod from the yetis." } },
        { accept = 533, npc = 2229, at = { 1424, 63.24, 20.66 },
          note = { ru = "Круск: «Шпионская работа» — послание Синдиката.", en = "Krusk: Infiltration - a Syndicate Missive." } },
        { accept = 544, npc = 2410, at = { 1424, 61.60, 20.85 },
          note = { ru = "Волхв Вурден Сиянье Бездны: «Взлом тюрьмы» (4 предателя у Даларана). Его новые задания про "
                       .. "Город Даларан (подземелье) не берите.",
                   en = "Magus Wordeen Voidglare: Prison Break In (4 traitors at Dalaran). Skip his new City of "
                       .. "Dalaran (dungeon) quests." } },
        { accept = 556, npc = 2437, at = { 1424, 61.50, 20.93 },
          note = { ru = "Хранитель Бел'варил: «Каменные талисманы» (10, с даларанцев).",
                   en = "Keeper Bel'varil: Stone Tokens (10, from the Dalaran humans)." } },
        { accept = 676, npc = 2770, at = { 1424, 61.87, 19.57 },
          note = { ru = "Сальный: «Да падет молот» — огры Тяжелого Кулака в Нагорье Арати (позже).",
                   en = "Tallow: The Hammer May Fall - Boulderfist ogres in the Arathi Highlands (later)." } },
        { accept = 509, npc = 2216, at = { 1424, 61.44, 19.06 },
          note = { ru = "Аптекарь Лидон: «Эликсир агонии» — 6 цветков Грязного Рыла (позже, на юго-востоке).",
                   en = "Apothecary Lydon: Elixir of Agony - 6 Mudsnout Blossoms (later, in the south-east)." } },

        ------------------------------------------------------------------
        -- Loop 1: south Alterac -> Growless Cave -> Dalaran camp -> Hillsbrad town hall (level 31-32)
        ------------------------------------------------------------------
        { id = "h-31-hillsbrad-alterac-field", complete = 533, at = { 1416, 58.30, 67.98 },
          note = { ru = "На север в Альтеракские горы: лагерь Синдиката (преступники и воры 32-34) — послание.",
                   en = "North into the Alterac Mountains: the Syndicate camp (Footpads and Thieves 32-34) - the "
                       .. "Missive." } },
        { complete = 552, at = { 1424, 44.33, 29.78 },
          note = { ru = "На юго-запад в пещеру йети в Хилсбраде (пещерные и лютые йети 30-32): Жезл Гелькулара.",
                   en = "South-west to the Hillsbrad yeti cave (Cave and Ferocious Yetis 30-32): Helcular's Rod." } },
        { complete = { 544, 556 }, at = { 1416, 19.20, 84.30 },
          note = { ru = "На запад к лагерю у Даларана: Дермот, Рихтер, Алина и Кеган Мракмар (33-35) — 4 камня. "
                       .. "Талисманы — со стражников со щитом и чудотворцев (31-33).",
                   en = "West to the camp by Dalaran: Dermot, Ricter, Alina and Kegan Darkmar (33-35) - 4 bloodstones. "
                       .. "Tokens from the Shield Guards and Theurgists (31-33)." } },
        { complete = 532, object = { 1761, 1759 }, at = { 1424, 29.80, 41.90 },
          note = { ru = "На юг в ратушу Хилсбрада: судья Бернсайд (30), 5 членов совета, сожгите объявление и "
                       .. "заберите регистрационную книгу.",
                   en = "South to the Hillsbrad town hall: Magistrate Burnside (30), 5 Councilmen, burn the "
                       .. "Proclamation and take the Town Registry." } },
        { complete = { [567] = { 1, 2, 4 } }, at = { 1424, 29.51, 42.41 },
          note = { ru = "Там же клерк Гораций (26). Уилкс (25) и фермер Калаба (25) убиты на 22-24; если нет — они "
                       .. "рядом на полях.",
                   en = "Clerk Horrace (26) in the same hall. Wilkes (25) and Farmer Kalaba (25) died at 22-24; if "
                       .. "not, they are in the fields next to it." } },
        { go = true, radius = 40, at = { 1424, 49.00, 38.00 },
          note = { ru = "Обратно на северо-восток к Мельнице Таррен (мимо горных львов).",
                   en = "Back north-east to Tarren Mill (past the mountain lions)." } },

        ------------------------------------------------------------------
        -- Tarren Mill, second visit (level 32)
        ------------------------------------------------------------------
        { turnin = 556, accept = 557, npc = 2437, at = { 1424, 61.50, 20.93 },
          note = { ru = "Бел'варил: «Сковывающие браслеты» (наручи с порабощенных элементалей).",
                   en = "Bel'varil: Bracers of Binding (from the Elemental Slaves)." } },
        { turnin = 544, accept = 545, npc = 2410, at = { 1424, 61.60, 20.85 },
          note = { ru = "Вурден: «Даларанские патрули» (6 призывателей, 8 элементалей).",
                   en = "Voidglare: Dalaran Patrols (6 Summoners, 8 Elemental Slaves)." } },
        { turnin = 532, accept = 539, npc = 2215, at = { 1424, 62.33, 20.45 },
          note = { ru = "Дарталия: следующая «Битва за Хилсбрад» — Лазурный рудник.",
                   en = "Darthalia: the next Battle of Hillsbrad - the Azurelode Mine." } },
        { turnin = 533, accept = 503, npc = 2229, at = { 1424, 63.24, 20.66 },
          note = { ru = "Круск: «Гол'дир» (Странбрад, по желанию, в конце Хилсбрада).",
                   en = "Krusk: Gol'dir (Strahnbrad, optional, at the end of Hillsbrad)." } },
        { turnin = 552, accept = 553, npc = 2429, at = { 1424, 63.88, 19.66 },
          note = { ru = "Тайлванд: зарядите жезл у трёх огней и сдайте у могилы Гелькулара.",
                   en = "Thaivand: charge the rod at three flames and hand it in at Helcular's Grave." } },

        ------------------------------------------------------------------
        -- Loop 2: Alterac yeti cave -> Dalaran dome -> Azurelode Mine -> Growless Cave -> Helcular's Grave ->
        -- Mudsnout (level 32)
        ------------------------------------------------------------------
        { complete = { [553] = { 3 } }, object = 1770, use = 3710, at = { 1416, 37.55, 66.24 },
          note = { ru = "На северо-запад в пещеру йети Альтерака (33-34): Пламя Узеля — используйте жезл. Внутри "
                       .. "бродит Ледочрев (37); к северу у пещеры — элитные огры Раздробленного Хребта (38-40).",
                   en = "North-west to the Alterac yeti cave (33-34): the Flame of Uzel - use the rod. Frostmaw (37) "
                       .. "walks inside; elite Crushridge ogres (38-40) stand north of the cave." } },
        { complete = { 545, 557 }, at = { 1416, 15.78, 76.36 },
          note = { ru = "На запад к куполу Даларана (южная сторона): 6 призывателей, 8 порабощенных элементалей "
                       .. "(32-35) — с элементалей и 4 наручей (может понадобиться ещё несколько элементалей ради "
                       .. "наручей).",
                   en = "West to the Dalaran dome (south side): 6 Summoners, 8 Elemental Slaves (32-35) - the slaves "
                       .. "also drop the 4 bracers (a few extra slave kills may be needed for them)." } },
        { complete = 539, at = { 1424, 29.98, 55.48 },
          note = { ru = "На юг к Лазурному руднику: штейгер Бондс (30) и 10 шахтеров (26-27).",
                   en = "South to the Azurelode Mine: Foreman Bonds (30) and 10 Hillsbrad Miners (26-27)." } },
        { complete = { [567] = { 3 } }, at = { 1424, 31.80, 52.70 },
          note = { ru = "Шахтер Хакетт (29) у входа в рудник.", en = "Miner Hackett (29) by the mine entrance." } },
        { complete = { [553] = { 1, 2 } }, object = { 1768, 1769 }, use = 3710, at = { 1424, 43.97, 27.30 },
          note = { ru = "На северо-восток в пещеру йети Хилсбрада: Пламя Азеля и Пламя Вераза в глубине — жезл.",
                   en = "North-east to the Hillsbrad yeti cave: the Flames of Azel and Veraz deep inside - the rod." } },
        { id = "h-31-helcular-s-grave", turnin = 553, object = 1767, at = { 1424, 52.75, 53.37 },
          note = { ru = "На юг: могила Гелькулара на кладбище к северо-востоку от Южнобережья. В город не заходите "
                       .. "(стража Альянса).",
                   en = "South: Helcular's Grave in the graveyard north-east of Southshore. Stay out of the town "
                       .. "(Alliance guards)." } },
        { complete = 509, object = 1723, at = { 1424, 64.39, 61.33 },
          note = { ru = "На юго-восток к гноллам Грязнорылов (26-28): 6 цветков на земле.",
                   en = "South-east to the Mudsnout gnolls (26-28): 6 blossoms on the ground." } },

        ------------------------------------------------------------------
        -- Tarren Mill, third visit (level 32) -> optional Strahnbrad
        ------------------------------------------------------------------
        { turnin = 557, npc = 2437, at = { 1424, 61.50, 20.93 },
          note = { ru = "На север в Мельницу Таррен: Бел'варил.", en = "North to Tarren Mill: Bel'varil." } },
        { turnin = 545, npc = 2410, at = { 1424, 61.60, 20.85 },
          note = { ru = "Вурден.", en = "Voidglare." } },
        { turnin = 509, accept = 513, npc = 2216, at = { 1424, 61.44, 19.06 },
          note = { ru = "Лидон: следующий «Эликсир агонии» отнесёте Фаранеллу в Подгород (позже).",
                   en = "Lydon: the next Elixir of Agony goes to Faranell in the Undercity (later)." } },
        -- Strahnbrad is a 34-37 town (Baron Vardus 40 patrols next to Gol'dir): optional, 4900 quest XP.
        { complete = 503, at = { 1416, 61.90, 42.38 }, optional = true,
          note = { ru = "По желанию (с 33-го или вдвоём): на север по дороге в Странбрад (Синдикат 34-36, барон Вардус "
                       .. "40 ходит рядом). Тюремный надзиратель Борхин (37) — ключ, откройте оковы Гол'дира. Не идёте — "
                       .. "сразу к Дарталии (шаги пропустятся) и бросьте 503.",
                   en = "Optional (at 33+ or with a friend): north along the road to Strahnbrad (Syndicate 34-36, Baron "
                       .. "Vardus 40 walks nearby). Jailor Borhuin (37) - the key, open Gol'dir's shackles. Not going: "
                       .. "go straight to Darthalia (the steps are skipped) and abandon 503." } },
        { id = "h-31-gol-dir", turnin = 503, accept = 506, npc = 2316, at = { 1416, 59.96, 43.74 }, optional = true,
          note = { ru = "Гол'дир: «Наследие Блэкмура».", en = "Gol'dir: Blackmoore's Legacy." } },
        { turnin = 506, npc = 2229, at = { 1424, 63.24, 20.66 }, optional = true,
          note = { ru = "Обратно в Мельницу Таррен: Круск.", en = "Back to Tarren Mill: Krusk." } },
        { id = "h-33-tarrenmill-end", turnin = { 539, 567 }, npc = 2215, at = { 1424, 62.33, 20.45 },
          note = { ru = "Дарталия. Следующую «Битву за Хилсбрад» (Дун Гарок, элита) не берите.",
                   en = "Darthalia. Skip the next Battle of Hillsbrad (Dun Garok, elites)." } },

        ------------------------------------------------------------------
        -- Tarren Mill -> Thoradin's Wall -> Hammerfall (level 33)
        ------------------------------------------------------------------
        { id = "h-31-tarren-mill", go = true, radius = 40, at = { 1424, 81.50, 52.20 },
          note = { ru = "Из Мельницы Таррен на юго-восток, мимо крепости Дарнхольд (слева), к Стене Торадина.",
                   en = "From Tarren Mill south-east past Durnholde Keep (on your left) to Thoradin's Wall." } },
        { go = true, radius = 40, at = { 1417, 20.50, 30.50 },
          note = { ru = "Ворота в Стене Торадина: Нагорье Арати. Восточнее ворот — круг с огненными элементалями 38-39: "
                       .. "держитесь юго-востока.",
                   en = "The gate in Thoradin's Wall: Arathi Highlands. East of the gate is a circle of 38-39 fire "
                       .. "elementals: keep south-east." } },
        { complete = 676, at = { 1417, 33.64, 44.89 },
          note = { ru = "На юго-восток к огрскому лагерю Тяжелого Кулака: 8 огров (32-33) и 10 головорезов (33-34).",
                   en = "South-east to the Boulderfist camp: 8 Boulderfist Ogres (32-33) and 10 Enforcers (33-34)." } },
        { complete = 1164, at = { 1417, 55.48, 37.77 },
          note = { ru = "На восток к ферме Дабири: головы Фардела (33), Марселя (34) и Кенаты (35).",
                   en = "East to Dabyrie's Farmstead: the heads of Fardel (33), Marcel (34) and Kenata (35)." } },
        { id = "h-31-shards-of-myzrael", accept = 642, object = 138492, at = { 1417, 62.50, 33.73 },
          note = { ru = "Дальше на восток у дороги: Кристаллы Мизраэли — «Пойманная принцесса».",
                   en = "On east by the road: the Shards of Myzrael - The Princess Trapped." } },

        ------------------------------------------------------------------
        -- Hammerfall, first visit (level 33)
        ------------------------------------------------------------------
        { id = "h-33-hammerfall-arrive", fp = "Hammerfall", npc = 2851, at = { 1417, 73.02, 32.70 },
          note = { ru = "Павший Молот: Урда — точка полёта.", en = "Hammerfall: Urda - flight point." } },
        { sethearth = "Hammerfall", npc = 9501, at = { 1417, 73.84, 32.46 },
          note = { ru = "Хозяин таверны Адегва: камень в Павший Молот.",
                   en = "Innkeeper Adegwa: bind your hearthstone to Hammerfall." } },
        { accept = 655, npc = 2792, at = { 1417, 72.64, 33.93 },
          note = { ru = "Гор'муль: «Павший Молот» (к Тор'гану).", en = "Gor'mul: Hammerfall (to Tor'gan)." } },
        { turnin = 676, accept = 677, npc = 2771, at = { 1417, 74.24, 33.92 },
          note = { ru = "Драм Желчный: «К оружию!» — деревня Сухокожих.",
                   en = "Drum Fel: Call to Arms - Witherbark Village." } },
        { turnin = 655, accept = { 671, 672 }, npc = 2706, at = { 1417, 74.72, 36.29 },
          note = { ru = "Тор'ган: «Зловещая магия» (Синдикат на северо-западе) и «Вызов духов» (10 глаз ящеров).",
                   en = "Tor'gan: Foul Magics (the Syndicate in the north-west) and Raising Spirits (10 raptor eyes)." } },
        { accept = 97539, npc = 12920, at = { 1417, 73.41, 36.89 },
          note = { ru = "Новое в Forever (опыт неизвестен): доктор Грегори Виктор — 12 хирургических паучьих шелков с "
                       .. "равнинных ползунов, они повсюду.",
                   en = "New in Forever (XP unknown): Doctor Gregory Victor - 12 Surgical Spidersilk from the Plains "
                       .. "Creepers, they are everywhere." } },

        ------------------------------------------------------------------
        -- Arathi loop A: Witherbark Village (level gate) -> Drywhisker kobolds -> Iridescent Shards (level 33)
        ------------------------------------------------------------------
        { complete = 672, bg = true, at = { 1417, 69.06, 46.43 },
          note = { ru = "Попутно: глаза с долгоногов (30-31) и твердозубов (33-34) — 10 штук.",
                   en = "On the way: eyes from Highland Striders (30-31) and Thrashers (33-34) - 10 of them." } },
        { complete = 97539, bg = true, at = { 1417, 65.23, 51.99 },
          note = { ru = "Попутно: шёлк с равнинных ползунов (32-36).",
                   en = "On the way: spidersilk from the Plains Creepers (32-36)." } },
        { id = "h-31-arathi-highlands-field", complete = 677, at = { 1417, 67.54, 67.88 },
          note = { ru = "На юг к деревне Сухокожих: по 10 метателей топоров и охотников за головами, 8 знахарей (32-35). "
                       .. "Нимар Душегуб (37) бродит по деревне.",
                   en = "South to Witherbark Village: 10 Axe Throwers, 10 Headhunters, 8 Witch Doctors (32-35). Nimar "
                       .. "the Slayer (37) walks the village." } },
        { id = "h-31-hillsbrad-arathi-level-gate", level = { 33, 0.43 }, at = { 1417, 67.54, 67.88 },
          ok = { ["level-grind"] = 280 }, -- end-of-segment gate: 273 / 274 kills in the normal run (druid / paladin)
          note = { ru = "Бейте троллей деревни (32-35, плотно, лучший опыт рядом) до 33-го + 43%: оставшиеся задания "
                       .. "Арати дают ~0,5 уровня — 34-й к Тернистой долине. Сытная еда даёт +5% за убийства.",
                   en = "Keep killing the village trolls (32-35: dense, the best XP nearby) up to level 33 + 43%: the "
                       .. "rest of the Arathi quests give ~0.5 level - 34 for Stranglethorn. Well Fed food: +5% kill "
                       .. "XP." } },
        { complete = 672, at = { 1417, 69.06, 46.43 },
          note = { ru = "На север: не хватает глаз — долгоноги южнее Павшего Молота.",
                   en = "North: eyes missing - Highland Striders south of Hammerfall." } },
        { complete = 642, at = { 1417, 78.94, 38.32 },
          note = { ru = "Восточнее Павшего Молота: кобольды Сухоусов (35-36) — 12 частиц Мизраэли.",
                   en = "East of Hammerfall: Drywhisker Kobolds (35-36) - 12 Motes of Myzrael." } },
        { id = "h-31-iridescent-shards", turnin = 642, object = 2701, at = { 1417, 84.31, 30.95 },
          note = { ru = "Ущелье Сухоусов: Радужные осколки (землекопы и геодезисты 36-38 рядом). «Связывающие камни» не "
                       .. "берите: у камней элементали 38-39.",
                   en = "Drywhisker Gorge: the Iridescent Shards (Diggers and Surveyors 36-38 around). Skip Stones of "
                       .. "Binding: 38-39 elementals guard the stones." } },

        ------------------------------------------------------------------
        -- Hammerfall, second visit (level 33-34)
        ------------------------------------------------------------------
        { turnin = 672, accept = 674, npc = 2706, at = { 1417, 74.72, 36.29 },
          note = { ru = "Тор'ган: амулет — к Гор'мулю.", en = "Tor'gan: the amulet goes to Gor'mul." } },
        { turnin = 674, accept = 675, npc = 2792, at = { 1417, 72.64, 33.93 },
          note = { ru = "Гор'муль.", en = "Gor'mul." } },
        { turnin = 677, accept = 678, npc = 2771, at = { 1417, 74.24, 33.92 },
          note = { ru = "Драм Желчный: следующее «К оружию!» — громилы и волхвы Тяжелого Кулака у ящеров на юге.",
                   en = "Drum Fel: the next Call to Arms - Boulderfist Brutes and Magi next to the raptors in the south." } },
        { turnin = 675, accept = 701, npc = 2706, at = { 1417, 74.72, 36.29 },
          note = { ru = "Тор'ган: «Коварство ящера» — 12 сердец плотоглотов.",
                   en = "Tor'gan: Guile of the Raptor - 12 Fleshstalker hearts." } },

        ------------------------------------------------------------------
        -- Arathi loop B: Fleshstalkers + Boulderfist Brutes -> Northfold Manor -> hearth (level 34)
        ------------------------------------------------------------------
        { complete = { 701, 678 }, at = { 1417, 52.18, 74.14 },
          note = { ru = "На юго-запад: плотоглоты нагорья (36-37) — 12 сердец; рядом 10 громил (35-36) и 4 волхва "
                       .. "(36-37) Тяжелого Кулака.",
                   en = "South-west: Highland Fleshstalkers (36-37) - 12 hearts; next to them 10 Boulderfist Brutes "
                       .. "(35-36) and 4 Boulderfist Magi (36-37)." } },
        { id = "h-31-stone-of-inner", go = true, radius = 40, at = { 1417, 33.64, 44.89 },
          note = { ru = "На северо-запад мимо огрского лагеря. К Внутреннему связывающему камню (южнее) не подходите: "
                       .. "элементали 38-39.",
                   en = "North-west past the Boulderfist camp. Keep away from the Stone of Inner Binding (to the "
                       .. "south): 38-39 elementals." } },
        { complete = 671, at = { 1417, 32.27, 28.66 },
          note = { ru = "Поместье на северо-западе: Синдикат (30-33) — 10 амулетов кровавого камня.",
                   en = "The manor in the north-west: the Syndicate (30-33) - 10 Bloodstone Amulets." } },
        { hearth = "Hammerfall", at = { 1417, 73.84, 32.46 },
          note = { ru = "Камень в Павший Молот. На откате — по дороге на восток (~6 мин).",
                   en = "Hearth to Hammerfall. On cooldown: east along the road (~6 min)." } },

        ------------------------------------------------------------------
        -- Hammerfall, last visit (level 34)
        ------------------------------------------------------------------
        { turnin = 678, npc = 2771, at = { 1417, 74.24, 33.92 },
          note = { ru = "Драм Желчный. Следующее «К оружию!» (40) не берите.", en = "Drum Fel. Skip the next Call to Arms (40)." } },
        { turnin = { 701, 671 }, accept = 702, npc = 2706, at = { 1417, 74.72, 36.29 },
          note = { ru = "Тор'ган. «Зловещая магия» (40, элита) не берите.", en = "Tor'gan. Skip the next Foul Magics (40, elite)." } },
        { turnin = 702, accept = 847, npc = 2792, at = { 1417, 72.64, 33.93 },
          note = { ru = "Гор'муль.", en = "Gor'mul." } },
        { turnin = 97539, npc = 12920, at = { 1417, 73.41, 36.89 },
          note = { ru = "Доктор Виктор: паучий шёлк.", en = "Doctor Victor: the spidersilk." } },
        { id = "h-34-hammerfall-end", turnin = 847, npc = 2706, at = { 1417, 74.72, 36.29 },
          note = { ru = "Тор'ган. Эликсир 513 и головы 1164 сдадите в Подгороде.",
                   en = "Tor'gan. 513 and the 1164 heads are handed in at the Undercity." } },
    },
})
