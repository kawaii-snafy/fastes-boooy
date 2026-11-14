-- AdventureAtlas_Guides / Segments / Shared / 53_Azshara_Ungoro_Silithus.lua
--
-- Segment "h-53-azshara-ungoro-silithus": levels 53-56, all races and classes.
-- Kargath (hearth from the Blasted Lands; Stonard after the optional 1445) -> fly Undercity (Oran) ->
-- zeppelin -> Orgrimmar (hearth) -> fly Splintertree Post -> ride east
-- into Azshara (Loh'atu, Valormok, Kim'jael, the blood elf camp, Ruins of Eldarath, Xylem) -> hearth Orgrimmar
-- (turn-ins) -> fly Gadgetzan (hearth) -> ramp down into Un'Goro Crater (Torwa) -> Marshal's Refuge (three loops)
-- -> hearth Gadgetzan (turn-ins) -> fly Marshal's Refuge -> path to Silithus -> Cenarion Hold (three loops).
-- Plan: research plan60.md section 4.11 / plan60.json segments[11] (anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1458 (Undercity) / 1420 (Tirisfal) / 1411 (Durotar) / 1454 (Orgrimmar) / 1440
-- (Ashenvale) / 1447 (Azshara) / 1446 (Tanaris) / 1449 (Un'Goro Crater) / 1451 (Silithus), map percent, from
-- tools/data/forever_db.lua: NPC / object spawns for npc / object steps, centroids of the objective mob / object
-- spawns of the area used for complete steps (h53 tools: research scratch h53/cen.lua, pts.lua). Valor's Rest
-- (Silithus 81.9,18.9 = Layo Starstrike 13220) is the end of the path from Un'Goro (its world position is the
-- north-west corner of the crater, from the Classic UiMapAssignment rectangles).
-- ruRU names in the notes: Wowhead Forever ruRU tooltips (nether.wowhead.com/forever/ru/tooltip/...); places from
-- ruRU quest texts (Укрытие Маршалла, крепость Кенария, Вулкан Огненного Венца, Прибамбасск, Покой Доблестных).
--
-- Hub plan (Forever DB; no quest of the segment is limited to a race or class):
--   UC  : Oran 2995 + 2782 > 8273 > 8273 (carried complete from h-50); Owen Thadd: books 81954 / 81955 / 81953 / 81947 /
--         81956 (the book items looted in h-50: accept + complete + turn in at once). Zeppelin to Orgrimmar.
--   ORG : 81 (Dran Droffers), 4494 (Zilzibin), hearth Orgrimmar, fly Splintertree Post.
--   AZ  : Loh'atu 5535 + 5536 (Highborne, Haldarr satyrs + book 81952 on the way north); Valormok fp, 3504 > 3505, 3517;
--         Kim'jael 3601; blood elf camp (3505 kills, 3601 equipment); Kim'jael 3601 > 5534; Kaldorei Tome 3505 > 3506,
--         Rimtori; Ruins of Eldarath (3517 tablets, 5534 rune, 3568 tide pools); Kim'jael 5534; Valormok 3517 >
--         3561 + 3541 + 3542, 3506 > 3507; Sanath -> Xylem 3561 > 3565; Valormok 3565; Loh'atu 5535 + 5536; hearth.
--   ORG : 3507 (Belgrom), 3541 (Jes'rimon); fly Gadgetzan.
--   GZ  : hearth Gadgetzan; 2641 > 2661 (Sprinkle), 4494 > 4496 (Pestlezugg), 4504 (Tran'rek), 2661 (Marin);
--         optional 3520 (Steamwheedle Port).
--   UG  : Torwa 4289 + 4290 -> carcass (4290), gorilla caves (4289) -> Marshal's Refuge (fp; 4284, 3881, 3883, 3882,
--         4501, 4492, 4145, 4503, 4243).
--   L1  : tar pits (4504), A-Me 01 (4243), young diemetradons / bloodpetals / crate (3881) / fledglings east, Torwa
--         4289 + 4290 > 4291 + 4301, mates (4291), raft 3844 > 3845, ravasaurs (4300), Torwa 4291 > 4292.
--   L2  : Gorishi hive (3883, 4496), research equipment (3881), bone yard (3882), Krakle 974 > hot spot > 974 > 980,
--         trappers / frenzied pterrordax (4145, 4501, 4503), Fire Plume Ridge (crystals, flayers), Ringo 4492 >
--         4491 (escort) -> Marshal's Refuge turn-ins, 4284 > 4285 + 4287 + 4288, 3845 > 3908.
--   L3  : Northern Pylon (4285), U'cha (4301), Eastern Pylon (4287), Lar'korwi (4292), Torwa 4292 + 4301; hearth
--         Gadgetzan 4496, 4504; fly Marshal's Refuge, Western Pylon (4288), J.D. Collie 4285 + 4287 + 4288 > 4321 > 4321;
--         path to Silithus.
--   SI  : level 54 gate on the north-east field (the hold's quests need 54); Cenarion Hold fp, 8280, 8277, 8284;
--         north-east field (8277, 8280) + the Silithus grind (54 + 74%, own-level mobs), tablets in
--         the north-west (8284); hold 8280 > 8281, 8277 > 8278, 8284 > 8285; crushers /
--         pincers (8281, 8278); south (8278); Ortell 8285; hold 8278, 8282, 8281; Noggle's Satchel (8282);
--         level 55 checkpoint on the way back; hold 8282.
-- XP (validator from ~52.6, Classic quest XP + objective kills, optional steps counted): Azshara + Un'Goro reach
--   ~53.9; the level 54 gate before the Cenarion Hold (reqLevel 54) is then almost free. The Silithus grind (~325
--   same-level kills) is on the north-east field right after its quests (h55-silithus-field-grind, 54 + 74%: Stonelash
--   Scorpids 54-55, Sand Skitterers / Dredge Strikers 55-56, ~160 non-elite spawns), not at the end on the +2..+4
--   Pincers 56 / Crushers 57-58 / Hive'Zora Wasps 58-59: the remaining turn-ins then make 55.0 and the end gate
--   (level 55) is a checkpoint (0 kills in the validator, normal and worst case) that sets up Felwood / Winterspring
--   (quests 54-58). Incidental kills and rested XP are not modelled, so the real gates are shorter.
-- Deviations from the plan (documented in the handoff):
--   * Undercity first (2995 + 2782 carried complete from h-50, + 8273 Oran's Gratitude): 2782 is no longer carried.
--   * 3507 Betrayed and 3541 Delivery to Jes'rimon are turned in at once in Orgrimmar (the Azshara hearth goes
--     there); 3518 Delivery to Magatha (Thunder Bluff) is not taken: the route does not pass Thunder Bluff.
--   * 4496 Bungle in the Jungle + 4504 Super Sticky (Gadgetzan, Un'Goro objectives) and 4243 Chasing A-Me 01 added;
--     4507 Pawn Captures Queen (needs a second Gadgetzan trip after 4496) and 4244 / 4245 (Mithril Casing from
--     Searing Gorge / Badlands; escort) skipped.
--   * 3520 Screecher Spirits is optional (750 XP at 53: grey-ish quest, detour to Steamwheedle Port).
--   * Silithus: 8279 The Twilight Lexicon / 8287 skipped (three level 60 keepers inside 57-60 Twilight camps);
--     8307 > 8313 > 8317 skipped (Cooking 285: Calandrath / the Sandy Cookbook do not offer them without it; the plan
--     anchor h-54-sandy-cookbook now sits on the 8281 Dredge Crusher step next to the cookbook's place).
--   * Hearth: Orgrimmar for Azshara (used from Loh'atu), Gadgetzan for Un'Goro (used from Torwa at the end).
--   * Densify pass (r3): the segment starts at ~52.6 (h-50 end gate lowered). Added: the library book turn-ins at Owen
--     Thadd (Undercity, Forever-new, XP unknown), 4494 March of the Silithid accepted in Orgrimmar (moved from h-50;
--     reqLevel 50), the book 81952 (Haldarr camp, turned in in h-56), 4288 The Western Pylon + 4321 Making Sense of It
--     (the Western Pylon on the way back to Marshal's Refuge). h55-silithus-grind (same id) is now the mandatory
--     level 54 step before the hold (it was an optional level 55 step after the first accepts); the end gate went from
--     55 + 97% to 55.
-- Carried out: 980 + 3908 (Donova, Winterspring), 4300 (Jes'rimon, Orgrimmar), 3542 + 3568 + the book item for 81952
--   (Undercity: Owen Thadd offers and takes the quest), 4808
--   (Everlook).
-- Automation notes: transient steps (fp, sethearth, hearth, fly, go) come before the quest steps of their hub; one
--   step per NPC; bg goals have a later non-bg finishing step; optional steps are followed by a mandatory anchor.
if not AdventureAtlas.AddLibraryInsert then return end
AdventureAtlas.AddLibrarySegment({
    id = "h-53-azshara-ungoro-silithus",
    title = { ru = "53-56 Азшара, Танарис, кратер Ун'Горо, Силитус",
              en = "53-56 Azshara, Tanaris, Un'Goro Crater, Silithus" },
    zone = "Azshara",
    levels = { 53, 56 },
    steps = {
        ------------------------------------------------------------------
        -- Undercity -> Orgrimmar (level 53)
        ------------------------------------------------------------------
        { id = "h53-fly-uc", fly = "Undercity", npc = 4551, at = { 1458, 63.25, 48.56 },
          note = { ru = "Горрик (Каргат): летите в Подгород (из Каменора после сдачи 1445 — от Брейка).",
                   en = "Gorrik (Kargath): fly to Undercity (from Stonard after the 1445 turn-in: Breyk)." } },
        { id = "h52-uc-2995", turnin = { 2995, 2782 }, accept = 8273, npc = 7825, at = { 1458, 73.06, 32.85 },
          note = { ru = "Квартал Магов, Оран Змеиные Кольца: «Линии связи» и «Секрет Рин'джи», возьмите «Благодарность "
                       .. "Оран».",
                   en = "Magic Quarter, Oran Snakewrithe: Lines of Communication and Rin'ji's Secret; take Oran's "
                       .. "Gratitude." } },
        { id = "h52-uc-8273", turnin = 8273, npc = 7825, at = { 1458, 73.06, 32.85 },
          note = { ru = "Сразу сдайте «Благодарность Оран» ему же.", en = "Turn in Oran's Gratitude to him at once." } },
        { id = "h52-uc-81954", accept = { 81954, 81955, 81953, 81947, 81956 },
          complete = { 81954, 81955, 81953, 81947, 81956 }, turnin = { 81954, 81955, 81953, 81947, 81956 },
          npc = 211022, at = { 1458, 73.40, 33.00 },
          note = { ru = "Рядом, Оуэн Тэдд: пять книг из Внутренних земель, Тлеющего ущелья, Черной горы, Болота Печали и "
                       .. "Выжженных земель - возьмите задания (книги в сумках) и сразу сдайте. Какой-то книги нет - "
                       .. "сдайте остальные и нажмите «Вперёд».",
                   en = "Next to him, Owen Thadd: the five books from the Hinterlands, the Searing Gorge, Blackrock "
                       .. "Mountain, the Swamp of Sorrows and the Blasted Lands - take the quests (the books are in your "
                       .. "bags) and turn them in at once. A book missing: turn in the rest and press Forward." } },
        { id = "h53-zeppelin-org", go = true, radius = 15, npc = 9566, at = { 1420, 60.74, 58.87 },
          note = { ru = "Из Подгорода к башне дирижаблей (Запетта): дирижабль в Оргриммар.",
                   en = "Out of Undercity to the zeppelin tower (Zapetta): zeppelin to Orgrimmar." } },
        { go = true, radius = 40, npc = 9564, at = { 1411, 50.82, 13.54 },
          note = { ru = "Прибытие в Дуротар (Фрезза), дальше в Оргриммар.",
                   en = "Arrival in Durotar (Frezza), then into Orgrimmar." } },
        { id = "h-53-org-arrive", turnin = 81, npc = 6986, at = { 1454, 59.49, 36.57 },
          note = { ru = "Дран Дрофферс: «Груз медовухи».", en = "Dran Droffers: Ripple Delivery." } },
        { accept = 4494, npc = 7010, at = { 1454, 56.26, 46.68 },
          note = { ru = "Аллея Мудрости, Зилзибин Барабанный Бой: «Нашествие силитидов» (50+; сдача в Прибамбасске, позже).",
                   en = "Valley of Wisdom, Zilzibin Drumlore: March of the Silithid (50+; turned in at Gadgetzan, "
                       .. "later)." } },
        { id = "h53-org-hearth", sethearth = "Orgrimmar", npc = 6929, at = { 1454, 54.10, 68.41 },
          note = { ru = "Аллея Силы, хозяйка таверны Гришка: привяжите камень (вернётесь им из Азшары).",
                   en = "Valley of Strength, Innkeeper Gryshka: bind the hearthstone (you hearth back from Azshara)." } },
        { id = "h53-fly-splintertree", fly = "Splintertree Post", npc = 12616, at = { 1440, 73.18, 61.59 },
          note = { ru = "Дорас: летите на Заставу Расщепленного Дерева (Ясеневый лес).",
                   en = "Doras: fly to Splintertree Post (Ashenvale)." } },

        ------------------------------------------------------------------
        -- Azshara (level 53)
        ------------------------------------------------------------------
        { id = "h-53-loh-atu", accept = { 5535, 5536 }, npc = 11548, at = { 1447, 11.37, 78.17 },
          note = { ru = "По дороге на восток в Азшару: Ло'хату у дороги сразу за границей — «Духовное беспокойство» и "
                       .. "«Земли, полные ненависти».",
                   en = "East along the road into Azshara: Loh'atu by the road just past the border - Spiritual Unrest "
                       .. "and A Land Filled with Hatred." } },
        { complete = 5535, at = { 1447, 16.37, 70.04 },
          note = { ru = "На северо-восток: тени и призраки высокорожденных (45-47) — по 6.",
                   en = "North-east: Highborne Apparitions and Lichlings (45-47) - 6 of each." } },
        { complete = 5536, at = { 1447, 20.09, 61.79 },
          note = { ru = "Дальше на север, лагерь Халдарр: 6 сатиров, 2 плута, 2 скверноподданных.",
                   en = "Further north, the Haldarr camp: 6 Satyrs, 2 Tricksters, 2 Felsworn." } },
        { collect = { [220348] = 1 }, object = 441250, at = { 1447, 20.70, 62.00 },
          note = { ru = "В лагере же (20.7,62.0): книга «Этикет на каждый день» — заберите её (контейнер; задание даст "
                       .. "Оуэн Тэдд в Подгороде, когда книга в сумках, следующий сегмент).",
                   en = "In the same camp (20.7,62.0): the book Everyday Etiquette - loot it (a container; Owen Thadd in "
                       .. "Undercity offers the quest when the book is in your bags, next segment)." } },
        { id = "h-53-azshara-arrive", fp = "Valormok", npc = 8610, at = { 1447, 21.96, 49.62 },
          note = { ru = "Лагерь Орды на севере: Кроум — откройте точку полёта.",
                   en = "The Horde camp to the north (Valormok): Kroum - learn the flight point." } },
        { turnin = 3504, accept = 3505, npc = 8576, at = { 1447, 22.26, 51.48 },
          note = { ru = "Аг'тор Кровопал: «Предательница», возьмите следующую часть.",
                   en = "Ag'tor Bloodfist: Betrayed; take the next part." } },
        { accept = 3517, npc = 8587, at = { 1447, 22.56, 51.42 },
          note = { ru = "Джедига: «Тайненькое знаньице» (4 таблички в руинах Эльдарата).",
                   en = "Jediga: Stealing Knowledge (4 tablets in the Ruins of Eldarath)." } },
        { id = "h-53-kim-jael", accept = 3601, npc = 8420, at = { 1447, 53.45, 21.82 },
          note = { ru = "Далеко на северо-восток по дороге: Ким'джаель на холме — «Оскорбленный Ким'джаель».",
                   en = "Far north-east along the road: Kim'jael on the hill - Kim'jael Indeed!" } },
        { complete = 3601, at = { 1447, 57.33, 28.30 },
          note = { ru = "Юго-восточнее, лагерь эльфов крови: его компас, прицел, плюшевый цыпленок и центробежный "
                       .. "растягиватель лежат по лагерю (оборудование Ким'джаеля).",
                   en = "South-east of him, the blood elf camp: his Compass, Scope, Stuffed Chicken and "
                       .. "Wizzlegoober lie around the camp (Kim'jael's Equipment)." } },
        { complete = { [3505] = { 1, 2 } }, at = { 1447, 57.33, 28.30 },
          note = { ru = "Там же: 10 эльфов крови-землемеров и 10 геодезистов (51-53).",
                   en = "Same camp: 10 Blood Elf Reclaimers and 10 Surveyors (51-53)." } },
        { turnin = 3601, accept = 5534, npc = 8420, at = { 1447, 53.45, 21.82 },
          note = { ru = "Ким'джаель: возьмите «\"Пропавшее\" оборудование Ким'джаеля» (руна у наг).",
                   en = "Kim'jael: take Kim'jael's \"Missing\" Equipment (a rune from the naga)." } },
        { complete = 3505, at = { 1447, 59.51, 31.30 },
          note = { ru = "На юго-восток к лагерю волхва Римтори: найдите его (там лежит фолиант).",
                   en = "South-east to Magus Rimtori's camp: find it (the tome lies there)." } },
        { id = "h-53-kaldorei-tome-of", turnin = 3505, accept = 3506, object = 151286, at = { 1447, 59.51, 31.30 },
          note = { ru = "Кальдорайский фолиант Призыва: сдайте «Предательницу» и возьмите следующую.",
                   en = "Kaldorei Tome of Summoning: turn in Betrayed and take the next part." } },
        { complete = 3506, at = { 1447, 59.51, 31.37 },
          note = { ru = "Разбейте кристалл-фокусатор рядом, затем убейте волхва Римтори (55) — голова.",
                   en = "Destroy the arcane focusing crystal next to her, then kill Magus Rimtori (55) - her head." } },
        { id = "h-53-azshara-field-loop", complete = 3517, at = { 1447, 37.89, 56.47 },
          note = { ru = "На юго-запад к руинам Эльдарата: таблички Бет'Амары, Джин'яэль, Маркри и Саэль'хай лежат "
                       .. "на земле среди руин.",
                   en = "South-west to the Ruins of Eldarath: the tablets of Beth'Amara, Jin'yael, Markri and "
                       .. "Sael'hai lie on the ground among the ruins." } },
        { complete = 5534, at = { 1447, 44.94, 53.67 },
          note = { ru = "Восточнее, у воды: наги из клана Бича Злобы (50-52) — «Некая руна».",
                   en = "East of the ruins by the water: Spitelash naga (50-52) - Some Rune." } },
        { complete = 3568, at = { 1447, 48.00, 51.80 },
          note = { ru = "Откройте коробку с флаконами и наберите воду в 4 приливных прудах на берегу: 48.0,61.0; "
                       .. "47.8,51.4; 48.7,48.5; 47.4,46.2.",
                   en = "Open the Box of Empty Vials and fill the 4 tide pools on the shore: 48.0,61.0; 47.8,51.4; "
                       .. "48.7,48.5; 47.4,46.2." } },
        { turnin = 5534, npc = 8420, at = { 1447, 53.45, 21.82 },
          note = { ru = "На север к Ким'джаелю: руна.", en = "North to Kim'jael: the rune." } },
        { turnin = 3517, accept = { 3561, 3541, 3542 }, npc = 8587, at = { 1447, 22.56, 51.42 },
          note = { ru = "Назад на запад к Джедиге: три доставки (Ксилем здесь, Джес'римон — Оргриммар, Андрон Гант — "
                       .. "Подгород, позже).",
                   en = "Back west to Jediga: three deliveries (Xylem here, Jes'rimon - Orgrimmar, Andron Gant - "
                       .. "Undercity, later)." } },
        { turnin = 3506, accept = 3507, npc = 8576, at = { 1447, 22.26, 51.48 },
          note = { ru = "Аг'тор: голова Римтори; последняя «Предательница» — Белгрому в Оргриммар.",
                   en = "Ag'tor: Rimtori's head; the last Betrayed goes to Belgrom in Orgrimmar." } },
        { go = true, radius = 10, npc = 8395, at = { 1447, 28.11, 50.09 },
          note = { ru = "Восточнее лагеря Санат Лим-Йо: возьмите и сдайте «Встреча с господином» — он телепортирует "
                       .. "в башню.",
                   en = "East of the camp, Sanath Lim-yo: accept and finish Meeting with the Master - he teleports "
                       .. "you up to the tower." } },
        { id = "h-53-archmage-xylem", turnin = 3561, accept = 3565, npc = 8379, at = { 1447, 29.25, 40.21 },
          note = { ru = "Верховный маг Ксилем: табличка; возьмите плату для Джедиги. Вниз — Нирилл, «Возвращение».",
                   en = "Archmage Xylem: the tablet; take his payment for Jediga. Back down: Nyrill, Return Trip." } },
        { id = "h-54-azshara-end", turnin = 3565, npc = 8587, at = { 1447, 22.56, 51.42 },
          note = { ru = "Джедига: «Плата Ксилема Джедиге».", en = "Jediga: Xylem's Payment to Jediga." } },
        { turnin = { 5535, 5536 }, npc = 11548, at = { 1447, 11.37, 78.17 },
          note = { ru = "На юго-запад к Ло'хату.", en = "South-west to Loh'atu." } },
        { id = "h54-hearth-org", hearth = "Orgrimmar", at = { 1454, 54.10, 68.41 },
          note = { ru = "Камень возвращения в Оргриммар.", en = "Hearth to Orgrimmar." } },
        { id = "h53-org-3507", turnin = 3507, npc = 4485, at = { 1454, 75.23, 34.24 },
          note = { ru = "Аллея Чести, Белгром Каменная Булава: «Предательница».",
                   en = "Valley of Honor, Belgrom Rockmaul: Betrayed." } },
        { id = "h53-org-3541", turnin = 3541, npc = 8659, at = { 1454, 55.52, 34.08 },
          note = { ru = "Джес'римон: «Доставка Джес'римону». Его плату для Джедиги не берите.",
                   en = "Jes'rimon: Delivery to Jes'rimon. Do not take his payment for Jediga." } },
        { id = "h-54-gadgetzan", fly = "Gadgetzan", npc = 7824, at = { 1446, 51.60, 25.44 },
          note = { ru = "Дорас: летите в Прибамбасск (Танарис).", en = "Doras: fly to Gadgetzan (Tanaris)." } },

        ------------------------------------------------------------------
        -- Gadgetzan (level 54)
        ------------------------------------------------------------------
        { id = "h54-gadgetzan-hearth", sethearth = "Gadgetzan", npc = 7733, at = { 1446, 52.51, 27.91 },
          note = { ru = "Хозяин таверны Ворчунелло: привяжите камень (вернётесь им из Ун'Горо).",
                   en = "Innkeeper Fizzgrimble: bind the hearthstone (you hearth back from Un'Goro)." } },
        { turnin = 2641, accept = 2661, npc = 7583, at = { 1446, 51.06, 26.87 },
          note = { ru = "Поливалка: «Маленький секрет Поливалки», возьмите «Посылку для Синя».",
                   en = "Sprinkle: Sprinkle's Secret Ingredient; take Delivery for Marin." } },
        { turnin = 4494, accept = 4496, npc = 5594, at = { 1446, 50.89, 26.96 },
          note = { ru = "Алхимик Пестычинс: «Нашествие силитидов», возьмите «Путаница в джунглях» (Ун'Горо).",
                   en = "Alchemist Pestlezugg: March of the Silithid; take Bungle in the Jungle (Un'Goro)." } },
        { accept = 4504, npc = 7876, at = { 1446, 51.57, 26.76 },
          note = { ru = "Тран'рек: «Суперлипучка» (смола в Ун'Горо).", en = "Tran'rek: Super Sticky (tar in Un'Goro)." } },
        { turnin = 2661, npc = 7564, at = { 1446, 51.81, 28.66 },
          note = { ru = "Синь Гогельмогель: посылка. Его эликсир — по желанию.",
                   en = "Marin Noggenfogger: the delivery. His elixir quest is up to you." } },
        { id = "h-53-steamwheedle-port", turnin = 3520, npc = 8579, optional = true, at = { 1446, 66.99, 22.36 },
          note = { ru = "Необязательно (около 750 опыта на 53-м, крюк на восток): Йе'кинья в порту гоблинов — «Духи "
                       .. "крикунов». Не идёте — пропустите шаг и бросьте 3520.",
                   en = "Optional (about 750 XP at 53, detour east): Yeh'kinya at Steamwheedle Port - Screecher "
                       .. "Spirits. Not going - skip the step and abandon 3520." } },

        ------------------------------------------------------------------
        -- Un'Goro Crater: Torwa -> Marshal's Refuge (level 54)
        ------------------------------------------------------------------
        { id = "h-53-torwa-pathfinder", accept = { 4289, 4290 }, npc = 9619, at = { 1449, 71.64, 75.96 },
          note = { ru = "Из Прибамбасска на запад-юго-запад к спуску в кратер Ун'Горо: внизу землепроходец Торва — "
                       .. "«Обезьяны Ун'Горо» и «Добыча Лар'корви».",
                   en = "From Gadgetzan west-south-west to the ramp down into Un'Goro Crater: Torwa Pathfinder at the "
                       .. "bottom - The Apes of Un'Goro and The Fare of Lar'korwi." } },
        { complete = 4300, bg = true, at = { 1449, 67.39, 52.03 },
          note = { ru = "Попутно: 8 белых когтей с любых равазавров (для Джес'римона в Оргриммаре, позже).",
                   en = "On the way: 8 White Ravasaur Claws from any ravasaurs (for Jes'rimon in Orgrimmar, later)." } },
        { complete = 4290, at = { 1449, 68.74, 56.71 },
          note = { ru = "На север: свежий труп жесткозуба (68.7,56.7) — возьмите кусок. Вокруг равазавры-охотники.",
                   en = "North: the fresh threshadon carcass (68.7,56.7) - take a piece. Ravasaur Hunters around." } },
        { complete = 4289, at = { 1449, 66.09, 16.13 },
          note = { ru = "Вдоль восточного края на север к пещерам горилл: по 2 шкуры горилл, топотунов и рокотунов "
                       .. "(50-53). Девизавры (элита) бродят по кратеру — обходите.",
                   en = "North along the east side to the gorilla caves: 2 pelts each from Gorillas, Stompers and "
                       .. "Thunderers (50-53). Devilsaurs (elite) roam the crater - avoid them." } },
        { id = "h-54-marshal-arrive", fp = "Marshal's Refuge", npc = 10583, at = { 1449, 45.23, 5.83 },
          note = { ru = "На запад в Укрытие Маршалла: Грайф — откройте точку полёта.",
                   en = "West to Marshal's Refuge: Gryfe - learn the flight point." } },
        { accept = 4284, npc = 9117, at = { 1449, 41.92, 2.70 },
          note = { ru = "Джей Ди Колли в пещере на севере: «Кристаллы Силы».",
                   en = "J.D. Collie in the cave to the north: Crystals of Power." } },
        { accept = 3881, npc = 9270, at = { 1449, 43.95, 7.14 },
          note = { ru = "Виллиден Маршал: «Спасение экспедиции».", en = "Williden Marshal: Expedition Salvation." } },
        { accept = 3883, npc = 9271, at = { 1449, 43.89, 7.24 },
          note = { ru = "Холания Маршал: «Экология чужих».", en = "Hol'anyee Marshal: Alien Ecology." } },
        { accept = 3882, npc = 9272, at = { 1449, 43.50, 7.42 },
          note = { ru = "Искр Пустокоп: «Игра в кости».", en = "Spark Nilminer: Roll the Bones." } },
        { accept = 4501, object = 174682, at = { 1449, 43.53, 8.44 },
          note = { ru = "Объявление «Осторожно, злой жутедактиль»: 10 жутедактилей и 15 бесноватых жутедактилей.",
                   en = "The sign: Beware of Pterrordax - 10 Pterrordax and 15 Frenzied Pterrordax." } },
        { accept = 4492, npc = 9997, at = { 1449, 43.62, 8.50 },
          note = { ru = "Муча Кусора: «Потерялся!» (Ринго на Вулкане Огненного Венца).",
                   en = "Spraggle Frock: Lost! (Ringo on Fire Plume Ridge)." } },
        { accept = 4145, npc = 9118, at = { 1449, 45.54, 8.72 },
          note = { ru = "Ларион: «Ларион и Майджин» (по 5 кровоцветов четырёх видов).",
                   en = "Larion: Larion and Muigin (5 bloodpetals of each of four kinds)." } },
        { accept = 4503, npc = 9998, at = { 1449, 44.23, 11.59 },
          note = { ru = "Шиззл: «Крылолет Шиззла».", en = "Shizzle: Shizzle's Flyer." } },
        { accept = 4243, npc = 9618, at = { 1449, 46.38, 13.44 },
          note = { ru = "Карна Сомнамбулер: «В поисках Чи-Та 3».", en = "Karna Remtravel: Chasing A-Me 01." } },

        ------------------------------------------------------------------
        -- Un'Goro loop 1: north, east, south-east (level 54)
        ------------------------------------------------------------------
        { complete = 4284, bg = true, at = { 1449, 55.09, 49.27 },
          note = { ru = "Попутно по всему кратеру: кристаллы силы лежат на земле — по 7 каждого цвета.",
                   en = "On the way all over the crater: power crystals lie on the ground - 7 of each colour." } },
        { complete = 4496, bg = true, at = { 1449, 48.36, 81.56 },
          note = { ru = "Попутно: 5 горстей земли из куч земли Ун'Горо (по всему кратеру); железа — в улье Гориши.",
                   en = "On the way: 5 Un'Goro Soil from the dirt piles (all over the crater); the gland comes from "
                       .. "the Gorishi hive." } },
        { complete = { 4503, 3882 }, bg = true, at = { 1449, 65.99, 31.64 },
          note = { ru = "Попутно: чешуя (8 с деметродонов, 8 с жутедактилей) и 8 костей (с деметродонов).",
                   en = "On the way: scales (8 from diemetradons, 8 from pterrordax) and 8 bones (diemetradons)." } },
        { complete = 4501, bg = true, at = { 1449, 55.34, 10.37 },
          note = { ru = "Попутно: 10 жутедактилей (у Укрытия и у улья на юге) и 15 бесноватых жутедактилей (запад).",
                   en = "On the way: 10 Pterrordax (near the Refuge and by the hive in the south) and 15 Frenzied "
                       .. "Pterrordax (west)." } },
        { complete = 4145, bg = true, at = { 1449, 67.35, 33.95 },
          note = { ru = "Попутно: кровоцветы — хлыстуны и крепкозубы на востоке, живодеры в центре, звероловы на западе.",
                   en = "On the way: bloodpetals - Lashers and Threshers east, Flayers in the centre, Trappers west." } },
        { id = "h-53-un-goro-crater", complete = 4504, at = { 1449, 48.16, 21.38 },
          note = { ru = "Южнее Укрытия, смоляные ямы: смоляные скрытни и господины (52-54) — 12 сверхлипкой смолы "
                       .. "(ещё смоляные твари и ползуны восточнее).",
                   en = "South of the Refuge, the tar pits: Tar Lurkers and Tar Lords (52-54) - 12 Super Sticky Tar "
                       .. "(also Tar Beasts and Creepers further east)." } },
        { id = "h-53-a-me-01", turnin = 4243, npc = 9623, at = { 1449, 67.66, 16.76 },
          note = { ru = "На восток к пещерам горилл: робот Чи-Та 3. Продолжение не берите (нужен мифриловый корпус).",
                   en = "East to the gorilla caves: the robot A-Me 01. Skip the follow-up (needs a Mithril Casing)." } },
        { collect = { [11113] = 1 }, at = { 1449, 68.54, 36.54 },
          note = { ru = "На юг: ящик с провизией (68.5,36.5) среди кровоцветов. Молодые деметродоны рядом.",
                   en = "South: the Crate of Foodstuffs (68.5,36.5) among the bloodpetals. Young Diemetradons "
                       .. "nearby." } },
        { complete = { 4503, 3882 }, bg = true, at = { 1449, 79.20, 40.01 },
          note = { ru = "Восточнее: птенцы жутедактилей (48-50) — чешуя.",
                   en = "Further east: Fledgling Pterrordax (48-50) - scales." } },
        { id = "h54-torwa-2", turnin = { 4289, 4290 }, accept = { 4291, 4301 }, npc = 9619, at = { 1449, 71.64, 75.96 },
          note = { ru = "Вдоль восточного края на юг к Торве: возьмите «Запах Лар'корви» и «Могучая Уча».",
                   en = "South along the east side to Torwa: take The Scent of Lar'korwi and The Mighty U'cha." } },
        -- 4300 is finished together with 4291 (accepted at Torwa 2): a separate "complete 4300" step would be done as
        -- soon as the bg claws are in the bags and would forward (skip) the Marshal's Refuge flight point step
        { complete = { 4291, 4300 }, at = { 1449, 64.92, 68.25 },
          note = { ru = "Западнее: самки Лар'корви (49-50) — 2 половые железы. Равазавры и бегуны вокруг (48-50): "
                       .. "добейте когти.",
                   en = "West of him: Lar'korwi Mates (49-50) - 2 Ravasaur Pheromone Glands. Ravasaurs and Runners "
                       .. "around (48-50): finish the claws." } },
        { id = "h-53-wrecked-raft-small", accept = 3844, object = 161505, at = { 1449, 63.02, 68.60 },
          note = { ru = "На берегу озера рядом: разбитый плот — «Тайна, покрытая мраком».",
                   en = "On the lake shore nearby: A Wrecked Raft - It's a Secret to Everybody." } },
        { turnin = 3844, accept = 3845, object = 161504, at = { 1449, 63.11, 69.06 },
          note = { ru = "Небольшая сумка рядом с плотом.", en = "The Small Pack next to the raft." } },
        { complete = 3845, use = 11107, at = { 1449, 63.11, 69.06 },
          note = { ru = "Откройте сумку (компас, карта, ключ) — для Линкена в Укрытии Маршалла.",
                   en = "Open the pack (compass, map, key) - for Linken at Marshal's Refuge." } },
        { id = "h54-torwa-3", turnin = 4291, accept = 4292, npc = 9619, at = { 1449, 71.64, 75.96 },
          note = { ru = "Торва: возьмите «Приманка для Лар'корви» (мешочек — позже, на востоке).",
                   en = "Torwa: take The Bait for Lar'korwi (the pouch - later, in the east)." } },

        ------------------------------------------------------------------
        -- Un'Goro loop 2: south, west, Fire Plume Ridge (level 54-55)
        ------------------------------------------------------------------
        { complete = 3883, use = 11132, at = { 1449, 48.69, 85.32 },
          note = { ru = "На запад к улью Гориши (юг кратера): у инкубатория внутри соскоблите образец стены улья.",
                   en = "West to the Gorishi hive (south of the crater): scrape a Hive Wall Sample near the hatchery "
                       .. "inside." } },
        { complete = 4496, at = { 1449, 48.36, 81.56 },
          note = { ru = "Осы, рабочие и разорители Гориши (51-53) — ароматическая железа. Жутедактили у улья — для 4501.",
                   en = "Gorishi Wasps, Workers and Reavers (51-53) - a Gorishi Scent Gland. Pterrordax by the hive - "
                       .. "for 4501." } },
        { complete = 3881, at = { 1449, 38.45, 66.06 },
          note = { ru = "На северо-запад: исследовательское оборудование (38.5,66.1).",
                   en = "North-west: the Research Equipment (38.5,66.1)." } },
        { complete = 3882, at = { 1449, 33.29, 73.19 },
          note = { ru = "Юго-западнее кости динозавров лежат на земле (около 33,73), ещё — со старых деметродонов. "
                       .. "Стегодоны здесь — элита, не трогайте.",
                   en = "South-west, dinosaur bones lie on the ground (around 33,73); more from Elder Diemetradons. "
                       .. "The Stegodons here are elite - leave them." } },
        { id = "h-53-krakle", accept = 974, npc = 10302, at = { 1449, 30.93, 50.44 },
          note = { ru = "На север к горячим источникам Голакка: Кракл — «Найти источник».",
                   en = "North to Golakka Hot Springs: Krakle - Finding the Source." } },
        { complete = 974, use = 12472, at = { 1449, 49.69, 45.64 },
          note = { ru = "На восток на Вулкан Огненного Венца: термометр у горячих точек; самая горячая — 49.7,45.6.",
                   en = "East up Fire Plume Ridge: use the thermometer at the hot spots; the hottest is at 49.7,45.6." } },
        { turnin = 974, accept = 980, npc = 10302, at = { 1449, 30.93, 50.44 },
          note = { ru = "Назад к Краклу: возьмите «Новые источники» (Донова в Зимних Ключах, позже).",
                   en = "Back to Krakle: take The New Springs (Donova in Winterspring, later)." } },
        { complete = { 4501, 4503 }, at = { 1449, 33.20, 39.07 },
          note = { ru = "К северу от источников: бесноватые жутедактили (51-54, всего 15) и кровоцветы-звероловы — "
                       .. "добейте жутедактилей и чешую.",
                   en = "North of the springs: Frenzied Pterrordax (51-54, 15 in all) and Bloodpetal Trappers - finish "
                       .. "the pterrordax and the scales." } },
        { complete = 4145, at = { 1449, 57.57, 53.76 },
          note = { ru = "На восток через центр: кровоцветы-живодеры у Вулкана Огненного Венца.",
                   en = "East through the centre: Bloodpetal Flayers around Fire Plume Ridge." } },
        { complete = 4284, at = { 1449, 55.09, 49.27 },
          note = { ru = "Добейте кристаллы силы (по 7 каждого цвета) вокруг вулкана.",
                   en = "Finish the power crystals (7 of each colour) around the ridge." } },
        { id = "h-53-ringo", complete = 4492, turnin = 4492, accept = 4491, npc = 9999, at = { 1449, 51.90, 49.85 },
          note = { ru = "Ринго у подножия вулкана: «Дружеская помощь» (сопровождение).",
                   en = "Ringo at the foot of the ridge: A Little Help From My Friends (escort)." } },
        { complete = 4491, use = 11804, at = { 1449, 43.62, 8.50 },
          note = { ru = "Ведите Ринго на север в Укрытие Маршалла; упал без сил — плесните на него из фляги Спрэггл.",
                   en = "Lead Ringo north to Marshal's Refuge; when he faints, use Spraggle's Canteen on him." } },

        ------------------------------------------------------------------
        -- Marshal's Refuge turn-ins (level 55)
        ------------------------------------------------------------------
        { turnin = { 4491, 4501 }, npc = 9997, at = { 1449, 43.62, 8.50 },
          note = { ru = "Муча Кусора: Ринго и жутедактили.", en = "Spraggle Frock: Ringo and the pterrordax." } },
        { accept = 3884, use = 11116, optional = true, at = { 1449, 43.95, 7.14 },
          note = { ru = "Выпал изорванный дневник — возьмите «Дневник Вилидена».",
                   en = "Got A Mangled Journal (random drop) - start Williden's Journal." } },
        { turnin = 3884, npc = 9270, optional = true, at = { 1449, 43.95, 7.14 },
          note = { ru = "Виллиден: дневник.", en = "Williden: the journal." } },
        { turnin = 3881, npc = 9270, at = { 1449, 43.95, 7.14 },
          note = { ru = "Виллиден Маршал: «Спасение экспедиции».", en = "Williden Marshal: Expedition Salvation." } },
        { turnin = 3883, npc = 9271, at = { 1449, 43.89, 7.24 },
          note = { ru = "Холания Маршал: образец стены улья.", en = "Hol'anyee Marshal: the hive wall sample." } },
        { turnin = 3882, npc = 9272, at = { 1449, 43.50, 7.42 },
          note = { ru = "Искр Пустокоп: кости.", en = "Spark Nilminer: the bones." } },
        { turnin = 3845, accept = 3908, npc = 8737, at = { 1449, 44.66, 8.10 },
          note = { ru = "Линкен: вещи из сумки; возьмите продолжение (Донова в Зимних Ключах, позже).",
                   en = "Linken: the pack's contents; take the follow-up (Donova in Winterspring, later)." } },
        { turnin = 4145, npc = 9118, at = { 1449, 45.54, 8.72 },
          note = { ru = "Ларион: кровоцветы. Мастерскую Марвона (Кабестан) не берите.",
                   en = "Larion: the bloodpetals. Skip Marvon's Workshop (Ratchet)." } },
        { turnin = 4503, npc = 9998, at = { 1449, 44.23, 11.59 },
          note = { ru = "Шиззл: чешуя.", en = "Shizzle: the scales." } },
        { turnin = 4284, accept = { 4285, 4287, 4288 }, npc = 9117, at = { 1449, 41.92, 2.70 },
          note = { ru = "Джей Ди Колли: кристаллы; возьмите все три пилона (западный — в конце Ун'Горо, перед тропой в "
                       .. "Силитус).",
                   en = "J.D. Collie: the crystals; take all three pylons (the western one at the end of Un'Goro, before "
                       .. "the path to Silithus)." } },

        ------------------------------------------------------------------
        -- Un'Goro loop 3: north-east, east, Torwa (level 55)
        ------------------------------------------------------------------
        { complete = 4285, at = { 1449, 56.52, 12.54 },
          note = { ru = "На восток: северный хрустальный пилон на уступе (56.5,12.5).",
                   en = "East: the Northern Crystal Pylon on the ledge (56.5,12.5)." } },
        { complete = 4301, at = { 1449, 68.14, 12.56 },
          note = { ru = "Пещеры горилл: У'ча (55) в глубине пещеры — шкура.",
                   en = "Gorilla caves: U'cha (55) at the back of the cave - his pelt." } },
        { complete = 4287, at = { 1449, 77.16, 49.98 },
          note = { ru = "Вдоль восточного края на юг: восточный хрустальный пилон.",
                   en = "South along the east side: the Eastern Crystal Pylon." } },
        { complete = 4292, use = 11569, at = { 1449, 79.65, 49.83 },
          note = { ru = "Логово Лар'корви рядом: откройте мешочек Торвы, положите мясо на плоский камень, полейте его "
                       .. "смесью феромонов; убейте Лар'корви (56) — голова.",
                   en = "Lar'korwi's lair next to it: open Torwa's Pouch, put the meat on the flat rock and apply the "
                       .. "pheromone mixture; kill Lar'korwi (56) - his head." } },
        { id = "h55-torwa-end", turnin = { 4292, 4301 }, npc = 9619, at = { 1449, 71.64, 75.96 },
          note = { ru = "На юг к Торве: Лар'корви и У'ча.", en = "South to Torwa: Lar'korwi and U'cha." } },
        { id = "h55-hearth-gadgetzan", hearth = "Gadgetzan", at = { 1446, 52.51, 27.91 },
          note = { ru = "Камень возвращения в Прибамбасск.", en = "Hearth to Gadgetzan." } },
        { turnin = 4496, npc = 5594, at = { 1446, 50.89, 26.96 },
          note = { ru = "Пестычинс: железа и земля. Продолжение («Пешка берет королеву») не берите.",
                   en = "Pestlezugg: the gland and the soil. Skip the follow-up (Pawn Captures Queen)." } },
        { turnin = 4504, npc = 7876, at = { 1446, 51.57, 26.76 },
          note = { ru = "Тран'рек: смола.", en = "Tran'rek: the tar." } },
        { id = "h53-fly-marshal", fly = "Marshal's Refuge", npc = 10583, at = { 1449, 45.23, 5.83 },
          note = { ru = "Булкрек: летите в Укрытие Маршалла.", en = "Bulkrek: fly to Marshal's Refuge." } },
        { complete = 4288, at = { 1449, 23.86, 59.19 },
          note = { ru = "На юго-запад вдоль западного края: западный хрустальный пилон (23.9,59.2).",
                   en = "South-west along the west side: the Western Crystal Pylon (23.9,59.2)." } },
        { id = "h-55-marshal-end", turnin = { 4285, 4287, 4288, 4321 }, accept = 4321, npc = 9117,
          at = { 1449, 41.92, 2.70 },
          note = { ru = "Назад на север к Джей Ди Колли: три пилона; возьмите и сразу сдайте «Разобраться в этом». "
                       .. "Кристальные задания пилонов не берите.",
                   en = "Back north to J.D. Collie: the three pylons; accept and turn in Making Sense of It at once. Skip "
                       .. "the pylon crystal quests." } },

        ------------------------------------------------------------------
        -- Silithus: Cenarion Hold (level 55)
        ------------------------------------------------------------------
        { id = "h55-silithus-path", go = true, radius = 40, npc = 13220, at = { 1451, 81.90, 18.90 },
          note = { ru = "На запад вдоль северных скал кратера: тропа в Силитус — в северо-западном углу. Выход у "
                       .. "кладбища Покой Доблестных.",
                   en = "West along the northern cliffs of the crater: the path to Silithus is in the north-west "
                       .. "corner. It comes out at Valor's Rest." } },
        { id = "h55-silithus-grind", level = 54, at = { 1451, 58.43, 22.93 }, -- level-grind: worst case only (no `ok`)
          note = { ru = "По пути к крепости — поле к северо-востоку от неё (камнехвостые скорпиды, песчаные пауки, "
                       .. "землечерпы 54-56, самое плотное поле рядом): до 54-го — задания крепости Кенария требуют 54-й. "
                       .. "Основной гринд Силитуса - на этом же поле, когда задания крепости будут взяты.",
                   en = "On the way to the hold - the field north-east of it (Stonelash Scorpids, Sand Skitterers, "
                       .. "Dredge Strikers 54-56, the densest field nearby): up to 54 - the Cenarion Hold quests require "
                       .. "54. The main Silithus grind is on this same field, once the hold's quests are taken." } },
        { id = "h-55-cenarionhold-arrive", fp = "Cenarion Hold", npc = 15178, at = { 1451, 48.68, 36.67 },
          note = { ru = "На запад в крепость Кенария: Рунк Покоритель Ветров — точка полёта.",
                   en = "West to Cenarion Hold: Runk Windtamer - learn the flight point." } },
        { accept = 8280, npc = 15191, at = { 1451, 51.15, 38.29 },
          note = { ru = "Призывательница ветров Гордый Рог: «Надежные поставки».",
                   en = "Windcaller Proudhorn: Securing the Supply Lines." } },
        { accept = 8277, npc = 15189, at = { 1451, 51.61, 38.63 },
          note = { ru = "Битисса Шаткобрус: «Смертельный яд».", en = "Beetix Ficklespragg: Deadly Desert Venom." } },
        { accept = 8284, npc = 15183, at = { 1451, 49.67, 37.46 },
          note = { ru = "Геолог Ехидная: «Сумеречная тайна».", en = "Geologist Larksbane: The Twilight Mystery." } },
        { id = "h-54-silithus-field-loop", complete = { 8277, 8280 }, at = { 1451, 58.43, 22.93 },
          note = { ru = "На северо-восток от крепости: камнехвостые скорпиды (жала), песчаные пауки-быстроноги (клыки) — "
                       .. "по 8, 15 землечерпов (54-56).",
                   en = "North-east of the hold: Stonelash Scorpids (stingers), Sand Skitterers (fangs) - 8 each, "
                       .. "15 Dredge Strikers (54-56)." } },
        -- level-grind of the next step (acknowledged with `ok`): the Silithus grind sits here, on the densest field of mobs at the player's
        -- level (Stonelash Scorpids 54-55, Sand Skitterers and Dredge Strikers 55-56, ~160 non-elite spawns), not at
        -- the end on the 56-59 Pincers / Crushers / Wasps; the end gate below is then a level 55 checkpoint.
        { id = "h55-silithus-field-grind", level = { 54, 0.74 }, at = { 1451, 58.43, 22.93 },
          ok = { ["level-grind"] = 370 }, -- 318 / 362 kills in the normal run (druid / paladin; reason above)
          note = { ru = "Здесь же гриндите до 54 + 74%: скорпиды 54-55, пауки и землечерпы 55-56 - самые плотные мобы "
                       .. "своего уровня в Силитусе. Остальные задания Силитуса (мобы 56-59) с этим уровнем идут легче, "
                       .. "а гейт 55 в конце почти не нужен.",
                   en = "Grind right here up to 54 + 74%: Scorpids 54-55, Skitterers and Strikers 55-56 - the densest "
                       .. "own-level mobs in Silithus. The other Silithus quests (mobs 56-59) go easier at this level, "
                       .. "and the level 55 gate at the end is then nearly free." } },
        { complete = 8284, at = { 1451, 23.29, 12.11 },
          note = { ru = "Вдоль северного края на запад: 8 фрагментов Сумеречной таблички на земле (20-28, 8-22); вокруг "
                       .. "пустынные грохотуны (56-58).",
                   en = "West along the northern edge: 8 Twilight Tablet Fragments on the ground (20-28, 8-22); "
                       .. "Desert Rumblers (56-58) around." } },
        { turnin = 8280, accept = 8281, npc = 15191, at = { 1451, 51.15, 38.29 },
          note = { ru = "Назад в крепость. Гордый Рог: «Обеспечение безопасности».",
                   en = "Back to the hold. Proudhorn: Stepping Up Security." } },
        { turnin = 8277, accept = 8278, npc = 15189, at = { 1451, 51.61, 38.63 },
          note = { ru = "Битисса: «Последняя надежда Ноггла».", en = "Beetix: Noggle's Last Hope." } },
        { turnin = 8284, accept = 8285, npc = 15183, at = { 1451, 49.67, 37.46 },
          note = { ru = "Ехидная: «Дезертир» (табличку — отшельнику Ортеллу).",
                   en = "Larksbane: The Deserter (the tablet goes to Hermit Ortell)." } },
        { complete = 8278, bg = true, at = { 1451, 38.83, 56.89 },
          note = { ru = "Попутно: по 3 жала клешневиков (здесь), живодеров и клыка скальных пауков (юг).",
                   en = "On the way: 3 stingers each from Pincers (here) and Flayers, 3 Rock Stalker fangs (south)." } },
        { id = "h-54-sandy-cookbook", complete = 8281, at = { 1451, 38.50, 56.20 },
          note = { ru = "Южнее: 20 земляных сокрушителей (57-58); камнехвостые клешневики (56) там же.",
                   en = "South: 20 Dredge Crushers (57-58); Stonelash Pincers (56) there too." } },
        { complete = 8278, at = { 1451, 38.93, 78.27 },
          note = { ru = "Дальше на юг: камнехвостые живодеры и скальные пауки-скакуны (57-59).",
                   en = "Further south: Stonelash Flayers and Rock Stalkers (57-59)." } },
        { id = "h-54-hermit-ortell", turnin = 8285, npc = 15194, at = { 1451, 67.19, 69.76 },
          note = { ru = "На восток к отшельнику Ортеллу: табличка. «Сумеречный словарь» не берите (три хранителя 60-го "
                       .. "в лагерях Сумеречного Молота).",
                   en = "East to Hermit Ortell: the tablet. Skip The Twilight Lexicon (three level 60 keepers in "
                       .. "Twilight camps)." } },
        { turnin = 8278, npc = 15189, at = { 1451, 51.61, 38.63 },
          note = { ru = "Назад в крепость, Битисса.", en = "Back to the hold, Beetix." } },
        { accept = 8282, npc = 15190, at = { 1451, 51.63, 38.50 },
          note = { ru = "Ноггл Шаткобрус: «Потерянная сумка Ноггла».", en = "Noggle Ficklespragg: Noggle's Lost Satchel." } },
        { turnin = 8281, npc = 15191, at = { 1451, 51.15, 38.29 },
          note = { ru = "Гордый Рог.", en = "Proudhorn." } },
        { complete = 8282, at = { 1451, 44.56, 91.38 },
          note = { ru = "Далеко на юг: сумка Ноггла на земле (44.6,91.4). Рядом бродит Смертехват (59, элитный "
                       .. "скорпид) — дождитесь, пока отойдёт.",
                   en = "Far south: Noggle's Satchel on the ground (44.6,91.4). Deathclasp (59, elite scorpid) "
                       .. "patrols right there - wait until it moves away." } },
        { id = "h-53-azshara-ungoro-silithus-level-gate", level = 55, at = { 1451, 38.83, 56.89 },
          note = { ru = "Контрольная точка: 55-й (Оскверненный лес и Зимние Ключи — задания 54-58); после гринда на "
                       .. "северо-восточном поле его дают сдачи Силитуса. Не хватает - добейте камнехвостых клешневиков "
                       .. "(56) здесь же на обратном пути; земляных сокрушителей (57-58) и ос Хайв'Зора (58-59) "
                       .. "обходите. В группе вместо гринда — Забытый Город (Фералас, полёт в лагерь Мохаче).",
                   en = "Checkpoint: level 55 (Felwood and Winterspring - quests 54-58); after the grind on the north-east "
                       .. "field the Silithus turn-ins make it. Short: finish on the Stonelash Pincers (56) right here on "
                       .. "the way back; avoid the Dredge Crushers (57-58) and Hive'Zora Wasps (58-59). In a group: Dire "
                       .. "Maul instead of grinding (Feralas, fly to Camp Mojache)." } },
        { id = "h-56-cenarionhold-end", turnin = 8282, npc = 15190, at = { 1451, 51.63, 38.50 },
          note = { ru = "Назад в крепость Кенария, Ноггл: сумка (дальше — следующий сегмент).",
                   en = "Back to Cenarion Hold, Noggle: the satchel (next segment from here)." } },
    },
})
