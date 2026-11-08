-- FastesBoooy_Horde / Segments/02_h-24-barrens-stonetalon.lua
--
-- Library segment "h-24-barrens-stonetalon": levels 24-27, class-neutral (Undead Paladin and Skyborne Druid, Horde).
-- Thunder Bluff (hearth from Tarren Mill) -> fly The Crossroads -> fly Camp Taurajo -> Bael Modan / Razorfen Kraul
-- loop -> fly Ratchet (Isha Awak, Northwatch Hold, Gilthares) -> run back to The Crossroads via Thorn Hill -> fly Sun
-- Rock Retreat -> Windshear Crag -> Mirkfallon Lake -> Stonetalon Peak -> Charred Vale (twice) -> Sun Rock Retreat.
-- Plan: research plan60.md section 4.2 / plan60.json segments[2] (anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1456 (Thunder Bluff) / 1413 (The Barrens) / 1442 (Stonetalon Mountains), map percent,
-- from tools/data/forever_db.lua (NPC / object spawns; centroids of the objective mob/object spawns for complete
-- steps). Sulhasa 14242 (Forever-new giver of 98093): DB supplement from the Wowhead Forever tooltip (zone 17,
-- 47.9,77.6); the Sun Rock east ramp is the 1-22 route's point (ud05), the west entrance and the Windshear Crag
-- road are route facts.
--
-- Hub plan (Forever DB; every quest is available to Scourge and Skyborne Horde characters of any class):
--   TB  : 742 (Windstrider, kept for Splintertree), 1067 > 1086 (Zamah), 97538 (Tah Winterhoof, Forever-new).
--   XR1 : 868 (Korran), 97003 (Gur'ak, Forever-new; Chol'aruk is an elite 20, killed at ~26), 862 (Grub); fly Camp
--         Taurajo.
--   CT1 : 879 (Mangletooth), optional 97250 (Logmar), 874 (Jorn, for Mahren at Ratchet), 893 (Tatternack).
--   BM  : Field of Giants eggs (868) on the way; Gann 843; 98093 (Sulhasa, Forever-new); 97250 soldiers (bg); dig site
--         843 + dig rats 862; Feegly 857; Gann 843 > 846; Bael'dun Keep 846 + 857; Feegly 857; Gann 846 > 849;
--         flying machine 849; Razorfen Kraul entrance 879 + 893; Gann 849; Sulhasa 98093.
--   CT2 : 879 > 906 (Mangletooth), 97250, 893; fly Ratchet.
--   RA  : optional 92706 (WANTED poster, Bruuz elite 20 in the bay), 891 (Brightsun); Mahren 874 > 873, Isha Awak,
--         873; Northwatch Hold 891; escort 898 (Gilthares) back to Ratchet; 891 + 898; 92706 (Gazlowe).
--   XR2 : run north-west via Thorn Hill (Chol'aruk); 862, 97003, 868, 906; fly Sun Rock.
--   SR1 : 1087 (Braelyn), 6301 (Tammra; not for Skyborne: the druid route did it), 6282 + 86576 (Maggran,
--         Forever-new), 6393 (Tsunaman).
--   WC  : 1096 (Ziz); optional 6284 (poster on the Webwinder Path, Besseleth elite 21 in Sishir Canyon); Windshear
--         Crag 1086 (copter pad) + 1096 (Gerenzo); 1096 (Ziz).
--   ML  : Mirkfallon Lake 6301 + 97538 (Mirkweed); Stonetalon Peak 1087.
--   CV1 : Charred Vale from the north: 6282 (28 harpies) + 86576 sunstones; 6393 incendrites in the bg.
--   SR2 : (west entrance) 6284 + 6282 > 6283 + 5881 (Maggran), 1087 > 1088 (Braelyn: Keeper
--         Ordanus is in Raynewood Retreat on the h-27 Ashenvale loop; h-27 flies back here from Splintertree),
--         6301 > 6381.
--   BFD : optional, group (plan: optional dungeon of this segment): fly Zoram'gar, 6563 + 6921 (Je'neu), Blackfathom
--         Deeps (sapphires in the entrance tunnel, Fathom Core, item-started 6922 + 6564, 6561 from Argent Guard
--         Thaelrid inside: turned in at Bashana in Thunder Bluff at the start of h-27, optional there too), Je'neu,
--         fly Sun Rock.
--   CV2 : 6381 (Gaea Dirt Mounds), 6393, 6283 (Bloodfury Ripper, elite 26) + level gate 26 + 84% (the three
--         turn-ins after it make 27.0; 27 keeps Sharptalon (31) and the Freewind quests 98069 / 98070 (need 27)
--         at most 4 levels up). Without the optional dungeons (Ruins of Lordaeron, Shadowfang Keep, BFD) this gate
--         is the long grind of the segment (validator worst case); with them it is already reached.
--   SR3 : 6393 (Tsunaman), 86576 (Mor'rogal: the sunstones drop on both valley loops), 6381 (Tammra), 6283 (Maggran)
--         = end; the next segment flies / hearths to Thunder Bluff.
-- Carried out: 532 + 567 (from h-22, for h-31), 742 (Senani, Splintertree), 1086 + 97538 (Zamah / Tah, Thunder
--   Bluff, objectives done), 5881 (Grish Longrunner, Thousand Needles), 1088 (Ordanus, h-27), optional 1013 (from
--   h-22, Undercity in h-31) and 6561 (Bashana, h-27).
-- Not used: 822 (Ratchet keg; 975 XP, Ratchet is not revisited after the Barrens loop), 1153 (taken at Camp Taurajo
--   in h-27: the ore drops in Thousand Needles), 1089 (Talon Den keys, far north-west), 1058 / 6421 / 6481
--   (Malaka'jin / Boulderslide, far south), 6565 (Lorgus Jett: needs a second Blackfathom run), 4021 (Kolkar wave
--   event at Regthar, off the path), 1068 (XT shredders: giver and turn-in at the Barrens border, two detours),
--   1221 (Razorfen Kraul tubers: turn-in at Ratchet, not revisited).
-- Automation notes: accepts at one NPC sit in consecutive steps with no transient step between them; fly / go steps
--   come before the quest steps of the next place. The anchor h-24-tb-arrive (Zamah) is followed by Tah Winterhoof,
--   so a class training insert after it is not fast-forwarded by a same-NPC accept.
-- Hearthstone: Thunder Bluff (unchanged; used at the end of h-22, ready again when this segment ends).
FastesBoooy.AddLibrarySegment({
    id = "h-24-barrens-stonetalon",
    title = { ru = "24-27 Кабестан, Южные Степи, Когтистые горы", en = "24-27 Ratchet, Southern Barrens, Stonetalon" },
    zone = "The Barrens",
    levels = { 24, 27 },
    steps = {
        ------------------------------------------------------------------
        -- Thunder Bluff (level 24)
        ------------------------------------------------------------------
        { accept = 742, npc = 10881, at = { 1456, 44.33, 58.76 },
          note = { ru = "Вестник Утеса Быстрое Копыто у таверны: «Большая охота» (сдадите в Ясеневом лесу на 27+).",
                   en = "Bluff Runner Windstrider by the inn: The Ashenvale Hunt (turned in in Ashenvale at 27+)." } },
        { id = "h-24-tb-arrive", turnin = 1067, accept = 1086, npc = 3419, at = { 1456, 22.81, 20.89 },
          note = { ru = "По мосту на Вершину Духов и вниз в Пруды Видений: аптекарь Зама. Распылитель ядовитого тумана держите "
                       .. "в сумке — он для Когтистых гор.",
                   en = "Over the bridge to Spirit Rise and down to the Pools of Vision: Apothecary Zamah. Keep the Toxic "
                       .. "Fogger: it is for Stonetalon." } },
        { accept = 97538, npc = 3024, at = { 1456, 54.14, 47.05 },
          note = { ru = "Новое в Forever (опыт неизвестен): Тах Заиндевевшее Копыто на центральной вершине, недалеко от "
                       .. "Тала — «Пигменты для красок», 30 стручков лихолиста с озера в Когтистых горах (по пути).",
                   en = "New in Forever (XP unknown): Tah Winterhoof on the central mesa near Tal - Pigments for Paints, "
                       .. "30 Mirkweed Pods from the lake in Stonetalon (on the way)." } },
        { id = "h-24-tb-fly", fly = "The Crossroads", npc = 3615, at = { 1413, 51.50, 30.34 },
          note = { ru = "Тал на центральной вершине: летите на Перекрёсток.",
                   en = "Tal on the central mesa: fly to the Crossroads." } },

        ------------------------------------------------------------------
        -- The Crossroads, first visit (level 24)
        ------------------------------------------------------------------
        { id = "h-24-the-crossroads", accept = 868, npc = 3428, at = { 1413, 51.07, 29.63 },
          note = { ru = "Корран: «Охота за яйцами» (курганы силитидов к югу от Лагеря Таурахо).",
                   en = "Korran: Egg Hunt (silithid mounds south of Camp Taurajo)." } },
        { accept = 97003, npc = 267310, at = { 1413, 52.65, 29.06 },
          note = { ru = "Новое в Forever (опыт неизвестен): Гур'ак — Чол'арук (элитный 20-й, к тому времени на 5-6 уровней "
                       .. "ниже вас) на холме к северо-востоку; убьёте на обратном пути из Кабестана.",
                   en = "New in Forever (XP unknown): Gur'ak - Chol'aruk (elite 20, 5-6 levels below you by then) on the "
                       .. "hill to the north-east; you kill him on the way back from Ratchet." } },
        { accept = 862, npc = 3443, at = { 1413, 55.31, 31.79 },
          note = { ru = "Грязнуля на восточном краю Перекрёстка: «Крысиная похлебка» (пещерные крысы в Бейл Модане).",
                   en = "Grub at the east edge of the Crossroads: Dig Rat Stew (dig rats at Bael Modan)." } },
        { id = "h-24-fly-taurajo", fly = "Camp Taurajo", npc = 10378, at = { 1413, 44.45, 59.15 },
          note = { ru = "Обратно к Девраку: летите в Лагерь Таурахо.", en = "Back to Devrak: fly to Camp Taurajo." } },

        ------------------------------------------------------------------
        -- Camp Taurajo, first visit (level 24)
        ------------------------------------------------------------------
        { id = "h-24-camp-taurajo", accept = 879, npc = 3430, at = { 1413, 44.55, 59.26 },
          note = { ru = "Кривозуб: «Предан своими» — черепа Каза, Нака и Лока Оркобоя у входа в Лабиринты Иглошкурых.",
                   en = "Mangletooth: Betrayal from Within - the skulls of Kuz, Nak and Lok Orcbane at the Razorfen "
                       .. "Kraul entrance." } },
        { accept = 97250, npc = 5911, at = { 1413, 44.62, 59.27 }, optional = true,
          note = { ru = "По желанию (новое в Forever, опыт неизвестен): рубака Логмар — солдаты Альянса к востоку от "
                       .. "Ганна. Разъярённые погромщики — элитные 23-го.",
                   en = "Optional (new in Forever, XP unknown): Grunt Logmar - Alliance soldiers east of Gann. The "
                       .. "Outraged Pillagers are elite (23)." } },
        { accept = 874, npc = 3387, at = { 1413, 44.86, 59.14 },
          note = { ru = "Джорн Заклинатель Небес: «Марен Небесная Провидица» (отнесёте в Кабестан).",
                   en = "Jorn Skyseer: Mahren Skyseer (you deliver it at Ratchet)." } },
        { accept = 893, npc = 3433, at = { 1413, 45.10, 57.68 },
          note = { ru = "Таттернак Стальной Горн: «Предпочитаемое оружие» (Иглогривые у Лабиринтов).",
                   en = "Tatternack Steelforge: Weapons of Choice (Razormane at the Kraul)." } },

        ------------------------------------------------------------------
        -- Southern Barrens: Bael Modan and the Razorfen Kraul entrance (level 24-25)
        ------------------------------------------------------------------
        { complete = 868, bg = true, object = 3685, at = { 1413, 45.10, 72.18 },
          note = { ru = "Попутно на юг: курганы силитидов на Поле Великанов — 12 яиц (силитиды 21-25 вылезают).",
                   en = "On the way south: Silithid Mounds in the Field of Giants - 12 Silithid Eggs (silithids 21-25 "
                       .. "come out)." } },
        { id = "h-24-gann-stonespire", accept = 843, npc = 3341, at = { 1413, 45.89, 77.00 },
          note = { ru = "Ганн Каменное Копье на холме севернее Бейл Модана: «Ответный удар Ганна».",
                   en = "Gann Stonespire on the hill north of Bael Modan: Gann's Reclamation." } },
        { accept = 98093, npc = 14242, at = { 1413, 47.90, 77.60 },
          note = { ru = "Новое в Forever (опыт неизвестен): Сулхаса на дереве в 200 м восточнее Ганна — «Полевая "
                       .. "зачистка», по 7 многозубых ловцов и грозовых ящеров вокруг.",
                   en = "New in Forever (XP unknown): Sulhasa in the tree 200 yd east of Gann - Field to Clear, 7 "
                       .. "Hecklefang Stalkers and 7 Stormhides around here." } },
        { complete = 98093, bg = true, at = { 1413, 46.88, 77.18 },
          note = { ru = "Попутно: гиены и грозошкуры (22-23) бродят между Ганном и раскопками.",
                   en = "On the way: the hyenas and Stormhides (22-23) roam between Gann and the dig site." } },
        { complete = 97250, bg = true, optional = true, at = { 1413, 48.73, 77.00 },
          note = { ru = "Попутно: вторгшиеся солдаты (22-23) и погромщики (элитные 23) восточнее Ганна — бейте по одному.",
                   en = "On the way: Encroaching Soldiers (22-23) and Outraged Pillagers (elite 23) east of Gann - pull "
                       .. "one at a time." } },
        { complete = 862, bg = true, at = { 1413, 48.84, 84.66 },
          note = { ru = "Попутно: пещерные крысы (зверьки 1-го) по всем раскопкам — 8 штук.",
                   en = "On the way: Dig Rats (level-1 critters) all over the dig site - 8 of them." } },
        { id = "h-24-the-barrens-field", complete = 843, at = { 1413, 47.61, 85.22 },
          note = { ru = "Раскопки Бейл Модана: 15 землечерпов, 5 старшин (21-23); дневник Хазгорма — с геолога Хазгорма "
                       .. "(26, ходит по яме).",
                   en = "Bael Modan dig site: 15 Excavators and 5 Foremen (21-23); Khazgorm's Journal from Prospector "
                       .. "Khazgorm (26, walks the pit)." } },
        { id = "h-24-feegly-the-exiled", accept = 857, npc = 3421, at = { 1413, 48.97, 86.31 },
          note = { ru = "Фиглай Изгнанник к юго-востоку от ямы: «Слеза Лун» (сейф в крепости Бейл'дан).",
                   en = "Feegly the Exiled south-east of the pit: The Tear of the Moons (strongbox in Bael'dun Keep)." } },
        { turnin = 843, accept = 846, npc = 3341, at = { 1413, 45.89, 77.00 },
          note = { ru = "Обратно к Ганну: «Месть Ганна».", en = "Back to Gann: Revenge of Gann." } },
        { complete = { 846, 857 }, at = { 1413, 49.12, 84.21 },
          note = { ru = "Крепость Бейл'дан: по 6 нитроглицерина, древесной массы и нитрата натрия с солдат, ружейников и "
                       .. "офицеров (23-26). Сейф генерала Двукоссы в крепости — Слеза Лун.",
                   en = "Bael'dun Keep: 6 Nitroglycerin, 6 Wood Pulp and 6 Sodium Nitrate from Soldiers, Riflemen and "
                       .. "Officers (23-26). General Twinbraid's Strongbox in the keep: the Tear of the Moons." } },
        { turnin = 857, npc = 3421, at = { 1413, 48.97, 86.31 },
          note = { ru = "Фиглай.", en = "Feegly." } },
        { turnin = 846, accept = 849, npc = 3341, at = { 1413, 45.89, 77.00 },
          note = { ru = "Ганн: вторая «Месть Ганна» — взорвать ветролет.",
                   en = "Gann: the second Revenge of Gann - blow up the flying machine." } },
        { complete = 849, object = 3644, use = 5021, at = { 1413, 46.97, 85.63 },
          note = { ru = "Западный край раскопок: используйте взрывающуюся шашку Ганна у ветролета.",
                   en = "West end of the dig site: use the Explosive Stick of Gann at the flying machine." } },
        { complete = { 879, 893 }, at = { 1413, 42.76, 81.32 },
          note = { ru = "На запад к Лабиринтам Иглошкурых: Каз (45.1, 80.1), Нак (43.8, 83.3), Лок Оркобой (40.2, 80.5); "
                       .. "кинжал — с землепроходцев и ловчих, жезл — с ясновидцев, щит — с бешенеров (20-25).",
                   en = "West to Razorfen Kraul: Kuz (45.1, 80.1), Nak (43.8, 83.3), Lok Orcbane (40.2, 80.5); the "
                       .. "Backstabber from Pathfinders and Stalkers, the Wand from Seers, the Shield from Warfrenzies "
                       .. "(20-25)." } },
        { turnin = 849, npc = 3341, at = { 1413, 45.89, 77.00 },
          note = { ru = "Ганн. Добейте солдат Альянса восточнее, если брали 97250.",
                   en = "Gann. Finish the Alliance soldiers to the east if you took 97250." } },
        { turnin = 98093, npc = 14242, at = { 1413, 47.90, 77.60 }, -- WARN-OK: xp-unknown (Forever-new)
          note = { ru = "Сулхаса. Не хватает зверей — они бродят вокруг.", en = "Sulhasa. Beasts missing: they roam around." } },

        ------------------------------------------------------------------
        -- Camp Taurajo, second visit -> Ratchet (level 25)
        ------------------------------------------------------------------
        { turnin = 879, accept = 906, npc = 3430, at = { 1413, 44.55, 59.26 },
          note = { ru = "Кривозуб: «Предатель в наших рядах» — отнесёте Торку на Перекрёсток.",
                   en = "Mangletooth: the second Betrayal from Within goes to Thork at the Crossroads." } },
        { turnin = 97250, npc = 5911, at = { 1413, 44.62, 59.27 }, optional = true, -- WARN-OK: xp-unknown
          note = { ru = "Рубака Логмар.", en = "Grunt Logmar." } },
        { turnin = 893, npc = 3433, at = { 1413, 45.10, 57.68 },
          note = { ru = "Таттернак. «Новый образец руды» не берите.", en = "Tatternack. Skip A New Ore Sample." } },
        { id = "h-25-fly-ratchet", fly = "Ratchet", npc = 16227, at = { 1413, 63.08, 37.16 },
          note = { ru = "Омуса: летите в Кабестан.", en = "Omusa: fly to Ratchet." } },

        ------------------------------------------------------------------
        -- Ratchet, Isha Awak, Northwatch Hold (level 25)
        ------------------------------------------------------------------
        { accept = 92706, object = 3972, at = { 1413, 62.59, 37.47 }, optional = true,
          note = { ru = "По желанию (новое в Forever, опыт неизвестен): плакат «РАЗЫСКИВАЕТСЯ» — Брууз, элитная акула "
                       .. "20-го в бухте восточнее причалов.",
                   en = "Optional (new in Forever, XP unknown): the WANTED poster - Bruuz, an elite level-20 shark in "
                       .. "the bay east of the docks." } },
        { id = "h-24-ratchet-arrive", accept = 891, npc = 3339, at = { 1413, 62.29, 39.03 },
          note = { ru = "Капитан Тало'тас Сияющий: «Пушки крепости Северной Стражи».",
                   en = "Captain Thalo'thas Brightsun: The Guns of Northwatch." } },
        { complete = 92706, optional = true, at = { 1413, 64.62, 39.60 },
          note = { ru = "Брууз плавает в бухте восточнее причалов: плавник.",
                   en = "Bruuz swims in the bay east of the docks: his Dorsal Fin." } },
        { turnin = 874, accept = 873, npc = 3388, at = { 1413, 65.84, 43.86 },
          note = { ru = "На юго-восток по берегу: Марен Небесная Провидица — «Иша Авак».",
                   en = "South-east along the shore: Mahren Skyseer - Isha Awak." } },
        { complete = 873, at = { 1413, 64.27, 50.63 },
          note = { ru = "Иша Авак (27, не элитный) плавает вдоль берега южнее, до крепости Северной Стражи: сердце.",
                   en = "Isha Awak (27, not elite) swims along the shore to the south, down to Northwatch: its Heart." } },
        { turnin = 873, npc = 3388, at = { 1413, 65.84, 43.86 },
          note = { ru = "Обратно к Марен.", en = "Back to Mahren." } },
        { complete = 891, at = { 1413, 61.73, 54.82 },
          note = { ru = "Крепость Северной Стражи: капитан Гордостанная (20), канониры Вессан и Смайт (19, на стенах), "
                       .. "10 тераморских медалей со стражей и оберегательниц (серые — опыта нет, бейте быстро).",
                   en = "Northwatch Hold: Captain Fairmount (20), Cannoneers Whessan and Smythe (19, on the walls), 10 "
                       .. "Theramore Medals from the marines and preservers (grey: no XP, kill them fast)." } },
        { accept = 898, npc = 3465, at = { 1413, 61.96, 54.96 },
          note = { ru = "Гилтарес Огненный Цветок в камере: «Свобода!» — проводите его.",
                   en = "Gilthares Firebough in the cell: Free From the Hold - escort him." } },
        { complete = 898, at = { 1413, 62.40, 39.40 },
          note = { ru = "Сопровождение на север вдоль берега до Кабестана: на пути нападают кроколиски и стражи.",
                   en = "Escort him north along the shore to Ratchet: crocolisks and marines attack on the way." } },
        { turnin = { 891, 898 }, npc = 3339, at = { 1413, 62.29, 39.03 },
          note = { ru = "Капитан Тало'тас.", en = "Captain Thalo'thas." } },
        { turnin = 92706, npc = 3391, at = { 1413, 62.68, 36.23 }, optional = true, -- WARN-OK: xp-unknown
          note = { ru = "Газлоу.", en = "Gazlowe." } },

        ------------------------------------------------------------------
        -- Back to the Crossroads on foot (level 26)
        ------------------------------------------------------------------
        { complete = 97003, at = { 1413, 57.95, 26.80 },
          note = { ru = "Бегом на северо-запад (~4 мин вместо полёта): Чол'арук (элитный 20-й) на холме кентавров — голова.",
                   en = "Run north-west (~4 min instead of the flight): Chol'aruk (elite 20) on the centaur hill - his "
                       .. "Head." } },
        { turnin = 862, npc = 3443, at = { 1413, 55.31, 31.79 },
          note = { ru = "Грязнуля.", en = "Grub." } },
        { turnin = 97003, npc = 267310, at = { 1413, 52.65, 29.06 }, -- WARN-OK: xp-unknown (Forever-new)
          note = { ru = "Гур'ак.", en = "Gur'ak." } },
        { turnin = 868, npc = 3428, at = { 1413, 51.07, 29.63 },
          note = { ru = "Корран.", en = "Korran." } },
        { turnin = 906, npc = 3429, at = { 1413, 51.50, 30.87 },
          note = { ru = "Торк.", en = "Thork." } },
        { id = "h-25-the-crossroads-flight", fly = "Sun Rock Retreat", npc = 4312, at = { 1442, 45.12, 59.84 },
          note = { ru = "Деврак: летите в Приют Солнечного Камня.", en = "Devrak: fly to Sun Rock Retreat." } },

        ------------------------------------------------------------------
        -- Sun Rock Retreat, first visit (level 26)
        ------------------------------------------------------------------
        { id = "h-26-sunrock-arrive", accept = 1087, npc = 4198, at = { 1442, 45.94, 60.42 },
          note = { ru = "Брайлин Огненная Длань: «Наследие Кенария» (пик Каменного Когтя на севере).",
                   en = "Braelyn Firehand: Cenarius' Legacy (Stonetalon Peak in the north)." } },
        { id = "h-25-sun-rock-retreat", accept = 6301, npc = 11864, at = { 1442, 47.46, 58.38 },
          race = { "Orc", "Scourge", "Tauren", "Troll" },
          note = { ru = "Таммра Поле Ветров: «Цикл возрождения» (семена Геи у озера на севере).",
                   en = "Tammra Windfield: Cycle of Rebirth (Gaea Seeds by the lake to the north)." } },
        { accept = 6282, npc = 11860, at = { 1442, 47.20, 61.16 },
          note = { ru = "Землепряд Маггран: «Угроза со стороны гарпий».", en = "Maggran Earthbinder: Harpies Threaten." } },
        { accept = 86576, npc = 11860, at = { 1442, 47.20, 61.16 },
          note = { ru = "Новое в Forever (опыт неизвестен): «Безделушки Кровавой Ярости» — 15 камней с тех же гарпий, "
                       .. "сдать Мор'рогалу.",
                   en = "New in Forever (XP unknown): Bloodfury Trinkets - 15 Glittering Sunstones from the same "
                       .. "harpies, for Mor'rogal." } },
        { accept = 6393, npc = 11862, at = { 1442, 47.36, 64.25 },
          note = { ru = "Цунаман: «Война элементалей» (инсендриты с огненных элементалей в долине гарпий).",
                   en = "Tsunaman: Elemental War (Incendrites from the fire elementals in the harpy valley)." } },
        { go = true, radius = 20, at = { 1442, 49.96, 61.04 },
          note = { ru = "Вниз по восточному спуску.", en = "Down the east ramp." } },
        { id = "h-25-windshear-crag-ziz", accept = 1096, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = { ru = "На восток по дороге: Зиз Физзикс — «Геренцо Терминатрикс».",
                   en = "East along the road: Ziz Fizziks - Gerenzo Wrenchwhistle." } },

        ------------------------------------------------------------------
        -- Besseleth (optional), Windshear Crag (level 26)
        ------------------------------------------------------------------
        { accept = 6284, object = 177904, at = { 1442, 59.06, 75.71 }, optional = true,
          note = { ru = "По желанию: на юг по дороге к Малака'джину — плакат «Розыск»: Бесселет (элитный паук 21-го).",
                   en = "Optional: south along the Webwinder Path - Wanted Poster: Besseleth (elite spider, 21)." } },
        { complete = 6284, optional = true, at = { 1442, 53.25, 72.55 },
          note = { ru = "Вверх по тропе в каньон (57.5, 76.2): Бесселет ходит по каньону — клык.",
                   en = "Up the path into the canyon (57.5, 76.2): Besseleth walks the canyon - his Fang." } },
        { go = true, radius = 30, at = { 1442, 62.80, 53.70 },
          note = { ru = "На север мимо Зиза на Утёс Ветрорезов.", en = "North past Ziz into Windshear Crag." } },
        { complete = 1086, object = 19594, use = 5638, at = { 1442, 66.51, 45.47 },
          note = { ru = "Посадочная площадка торговой компании: установите распылитель ядовитого тумана.",
                   en = "The Venture Co. copter pad: place the Toxic Fogger." } },
        { id = "h-25-stonetalon-mountains-field", complete = 1096, at = { 1442, 64.49, 40.25 },
          note = { ru = "Вверх по склону на север: Геренцо (27) на площадке, гоблины вокруг (24-27) — рука.",
                   en = "Climb north: Gerenzo (27) on the platform with goblins (24-27) around him - his Mechanical "
                       .. "Arm." } },
        { turnin = 1096, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = { ru = "Обратно на юг к Зизу.", en = "Back south to Ziz." } },

        ------------------------------------------------------------------
        -- Mirkfallon Lake, Stonetalon Peak (level 26)
        ------------------------------------------------------------------
        { go = true, radius = 30, at = { 1442, 49.96, 61.04 },
          note = { ru = "На запад к подножию Приюта и дальше на север по дороге к озеру.",
                   en = "West to the foot of Sun Rock, then north along the road to the lake." } },
        { complete = 6301, at = { 1442, 48.77, 40.66 }, race = { "Orc", "Scourge", "Tauren", "Troll" },
          note = { ru = "Озеро: 10 семян Геи на берегу и на мелководье.",
                   en = "The lake: 10 Gaea Seeds on the shore and in the shallows." } },
        { complete = 97538, bg = true, at = { 1442, 48.09, 40.45 },
          note = { ru = "Попутно у воды: 30 стручков с лихолиста и сухих куч.",
                   en = "On the way by the water: 30 Mirkweed Pods from Mirkweed and Dried Mirkweed Piles." } },
        { complete = 1087, at = { 1442, 36.34, 12.96 },
          note = { ru = "По дороге на северо-запад к пику: по 4 сына и дочери Кенария и кенарийских ботаника (23-25).",
                   en = "North-west along the road to the peak: 4 Sons and 4 Daughters of Cenarius, 4 Cenarion "
                       .. "Botanists (23-25)." } },

        ------------------------------------------------------------------
        -- Charred Vale, first loop (level 26)
        ------------------------------------------------------------------
        { go = true, radius = 40, at = { 1442, 37.60, 47.00 },
          note = { ru = "Назад на юг вдоль западного берега озера и на юго-запад в долину гарпий.",
                   en = "Back south along the west shore of the lake and south-west into the harpy valley." } },
        { complete = 6393, bg = true, at = { 1442, 33.97, 63.42 },
          note = { ru = "Попутно: 10 инсендритов с духов огня (север долины), опустошителей и разрушителей (юг).",
                   en = "On the way: 10 Incendrites from Rogue Flame Spirits (north of the valley), Burning Ravagers "
                       .. "and Destroyers (south)." } },
        { complete = 86576, bg = true, at = { 1442, 32.00, 65.01 },
          note = { ru = "Попутно: 15 сверкающих камней с любых гарпий Кровавой Ярости.",
                   en = "On the way: 15 Glittering Sunstones from any Bloodfury harpy." } },
        { complete = 6282, at = { 1442, 32.68, 65.05 },
          note = { ru = "По 7: гарпии и душительницы (23-24, север и середина), душегубки и бродяжницы (25-26, юг). "
                       .. "Душегубки добивают ниже 20% здоровья.",
                   en = "7 each: Bloodfury Harpies and Ambushers (23-24, north and middle), Slayers and Roguefeathers "
                       .. "(25-26, south). Slayers execute below 20% health." } },
        { go = true, radius = 30, at = { 1442, 38.70, 68.60 },
          note = { ru = "На восток к западному входу в Приют Солнечного Камня.",
                   en = "East to the west entrance of Sun Rock Retreat." } },

        ------------------------------------------------------------------
        -- Sun Rock Retreat, second visit (level 26)
        ------------------------------------------------------------------
        { turnin = 6284, npc = 11860, at = { 1442, 47.20, 61.16 }, optional = true,
          note = { ru = "Маггран: клык Бесселета.", en = "Maggran: Besseleth's Fang." } },
        { turnin = 6282, accept = 6283, npc = 11860, at = { 1442, 47.20, 61.16 },
          note = { ru = "Маггран: «Предводительница клана Кровавой Ярости».", en = "Maggran: Bloodfury Bloodline." } },
        { id = "h-25-sun-rock-retreat-2", accept = 5881, npc = 11860, at = { 1442, 47.20, 61.16 },
          note = { ru = "Маггран: «Смена караула» — письмо для Тысячи Игл (следующий сегмент).",
                   en = "Maggran: Calling in the Reserves - a letter for Thousand Needles (next segment)." } },
        { turnin = 1087, accept = 1088, npc = 4198, at = { 1442, 45.94, 60.42 },
          note = { ru = "Брайлин: «Гордан» — хранитель Гордан сидит на вершине Приюта Рейнвуда в Ясеневом лесу (по пути, "
                       .. "следующий сегмент); сдадите здесь же.",
                   en = "Braelyn: Ordanus - Keeper Ordanus sits on top of Raynewood Retreat in Ashenvale (on the way, next "
                       .. "segment); you hand it in back here." } },
        { turnin = 6301, npc = 11864, at = { 1442, 47.46, 58.38 }, race = { "Orc", "Scourge", "Tauren", "Troll" },
          note = { ru = "Таммра.", en = "Tammra." } },
        { accept = 6381, npc = 11864, at = { 1442, 47.46, 58.38 },
          note = { ru = "Таммра: «Новая жизнь» — зачарованные семена Геи для долины гарпий.",
                   en = "Tammra: New Life - Enchanted Gaea Seeds for the harpy valley." } },

        ------------------------------------------------------------------
        -- Optional, group: Blackfathom Deeps from Zoram'gar (level 26)
        ------------------------------------------------------------------
        { id = "h-26-bfd-fly", fly = "Zoram'gar Outpost", npc = 11901, at = { 1440, 12.24, 33.80 }, optional = true,
          note = { ru = "Если собрали группу: Непроглядная Пучина (~60 мин, ~17 тыс. опыта за задания здесь и ещё 7850 "
                       .. "в Громовом Утёсе — вместо гринда у гарпий). Тарм: летите в Зорам'гар. Без группы — «Пропуск» "
                       .. "на этих 10 шагах.",
                   en = "If you have a group: Blackfathom Deeps (~60 min, ~17k quest XP here and 7850 more in Thunder "
                       .. "Bluff - instead of grinding harpies). Tharm: fly to Zoram'gar. No group: Skip these 10 "
                       .. "steps." } },
        { accept = { 6563, 6921 }, npc = 12736, at = { 1440, 11.56, 34.29 }, optional = true,
          note = { ru = "Дже'неу Санкри: «Сущность Аку'май» и «Среди руин».",
                   en = "Je'neu Sancrea: The Essence of Aku'Mai and Amongst the Ruins." } },
        { complete = 6563, object = { 178184, 178185, 178186 }, at = { 1440, 13.39, 12.88 }, optional = true,
          note = { ru = "На север по берегу к руинам у входа: 20 сапфиров Аку'май на стенах туннеля (и внутри).",
                   en = "North along the shore to the ruins at the entrance: 20 Sapphires of Aku'Mai on the tunnel "
                       .. "walls (and inside)." } },
        { complete = 6921, at = { 1440, 14.50, 14.20 }, optional = true,
          note = { ru = "Внутри: Глубинный сердечник из Глубинного Камня — появится Барон Акванис.",
                   en = "Inside: the Fathom Core from the Fathom Stone - Baron Aquanis appears." } },
        { accept = 6922, use = 16782, at = { 1440, 14.50, 14.20 }, optional = true,
          note = { ru = "Странная водяная сфера с Барона Акваниса: используйте — «Барон Акванис».",
                   en = "Strange Water Globe from Baron Aquanis: use it - Baron Aquanis." } },
        { accept = 6564, use = 16790, at = { 1440, 14.50, 14.20 }, optional = true,
          note = { ru = "Отсыревшая записка (с жриц прилива): используйте — «Верность Древним богам».",
                   en = "Damp Note (from the Tide Priestesses): use it - Allegiance to the Old Gods." } },
        { accept = 6561, at = { 1440, 14.50, 14.20 }, optional = true, -- WARN-OK: at-far-from-giver (Thaelrid is inside the dungeon)
          note = { ru = "Страж Талрид из ордена Серебряного Рассвета (в глубине, у алтаря): «Жестокость Черных Глубин» — "
                       .. "голова Келриса (босс). Сдадите Башане в Громовом Утёсе (7850 опыта).",
                   en = "Argent Guard Thaelrid (deep inside, by the altar): Blackfathom Villainy - the head of Kelris "
                       .. "(boss). Hand it in to Bashana in Thunder Bluff (7850 XP)." } },
        { complete = 6561, at = { 1440, 14.50, 14.20 }, optional = true,
          note = { ru = "Повелитель сумрака Келрис: голова.", en = "Twilight Lord Kelris: his head." } },
        { turnin = { 6563, 6921, 6922, 6564 }, npc = 12736, at = { 1440, 11.56, 34.29 }, optional = true,
          note = { ru = "Обратно к Дже'неу. Второе «Верность Древним богам» (Лоргус Джетт) — только со второй группой. "
                       .. "Голову Келриса держите до Громового Утёса.",
                   en = "Back to Je'neu. The second Allegiance to the Old Gods (Lorgus Jett) only with another run. Keep "
                       .. "the head of Kelris for Thunder Bluff." } },
        { id = "h-26-bfd-fly-back", fly = "Sun Rock Retreat", npc = 4312, at = { 1442, 45.12, 59.84 }, optional = true,
          note = { ru = "Андрук: обратно в Приют Солнечного Камня.", en = "Andruk: back to Sun Rock Retreat." } },

        ------------------------------------------------------------------
        -- Charred Vale, second loop + level gate (level 26-27)
        ------------------------------------------------------------------
        { go = true, radius = 30, at = { 1442, 38.70, 68.60 },
          note = { ru = "Через западный вход обратно в долину.", en = "Back into the valley through the west entrance." } },
        -- 6393 is finished in the same step as 6381 (accepted at Sun Rock 2): a separate "complete 6393" step would be
        -- done as soon as the bg goal of loop 1 finishes the incendrites and would forward (skip) the optional Sun
        -- Rock 2 turn-ins and the optional Blackfathom block before it
        { complete = { 6381, 6393 }, object = 177929, use = 16208, at = { 1442, 32.89, 68.06 },
          note = { ru = "Посадите 10 заколдованных семян Геи в земляные курганы Геи (юг долины). Доберите инсендриты: "
                       .. "опустошители (24-25) и разрушители (26-27) у курганов.",
                   en = "Plant 10 seeds in the Gaea Dirt Mounds (south of the valley). Finish the Incendrites: Burning "
                       .. "Ravagers (24-25) and Destroyers (26-27) by the mounds." } },
        { id = "h-24-barrens-stonetalon-level-gate", complete = 6283, level = { 26, 0.84 }, -- WARN-OK: level-grind (worst case)
          at = { 1442, 30.75, 61.91 },
          note = { ru = "Потрошительница (элитная 26-я) в западной части долины (30.8, 61.9) — останки. Затем бейте гарпий и "
                       .. "элементалей долины (24-27, плотные лагеря — лучший опыт рядом) до 26-го + 84%: три сдачи в "
                       .. "Приюте дадут 27-й. Без подземелий это долго (до ~210 убийств): ешьте еду с «Сытостью» (+5%).",
                   en = "The Bloodfury Ripper (elite 26) in the west of the valley (30.8, 61.9): her Remains. Then kill the valley "
                       .. "harpies and elementals (24-27, dense camps: the best XP nearby) up to level 26 + 84%: the "
                       .. "three Sun Rock turn-ins make 27. Without the dungeons this is long (up to ~210 kills): eat "
                       .. "Well Fed food (+5%)." } },
        { go = true, radius = 30, at = { 1442, 38.70, 68.60 },
          note = { ru = "К западному входу в Приют.", en = "To the west entrance of Sun Rock Retreat." } },

        ------------------------------------------------------------------
        -- Sun Rock Retreat, last visit (level 27)
        ------------------------------------------------------------------
        { turnin = 6393, npc = 11862, at = { 1442, 47.36, 64.25 },
          note = { ru = "Цунаман.", en = "Tsunaman." } },
        { turnin = 86576, npc = 11861, at = { 1442, 47.22, 64.04 }, -- WARN-OK: xp-unknown (Forever-new)
          note = { ru = "Рядом Мор'рогал: 15 сверкающих камней.", en = "Mor'rogal next to him: the 15 sunstones." } },
        { turnin = 6381, npc = 11864, at = { 1442, 47.46, 58.38 },
          note = { ru = "Таммра.", en = "Tammra." } },
        { id = "h-27-sunrock-end", turnin = 6283, npc = 11860, at = { 1442, 47.20, 61.16 },
          note = { ru = "Маггран. Камень возвращения (Громовой Утёс) снова готов.",
                   en = "Maggran. Your hearthstone (Thunder Bluff) is ready again." } },
    },
})
