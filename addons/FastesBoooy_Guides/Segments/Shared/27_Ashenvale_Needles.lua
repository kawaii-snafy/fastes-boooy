-- FastesBoooy_Guides / Segments / Shared / 27_Ashenvale_Needles.lua
--
-- Library segment "h-27-ashenvale-needles": levels 27-31, class-neutral (Undead Paladin and Skyborne Druid, Horde).
-- Sun Rock Retreat -> hearth Thunder Bluff -> fly The Crossroads -> north via Mor'shan Rampart into Ashenvale (Torek,
-- Silverwing Outpost, Splintertree Post, Felmusk, Raynewood Retreat, Mystral Lake, the Ashenvale Hunt) -> fly Sun
-- Rock (Ordanus) -> hearth Thunder Bluff -> Skywatcher Plateau (Mulgore, Forever-new Gloomrise chain) -> fly
-- Camp Taurajo -> optional Razorfen Kraul -> the Great Lift ->
-- Thousand Needles (Freewind Post, Galak Hold, Dorn, the harpy cave, Highperch, Whitereach Post, Darkcloud Pinnacle)
-- -> Shimmering Flats (Mirage Raceway) -> hearth Thunder Bluff.
-- Plan: research plan60.md section 4.3 / plan60.json segments[3] (anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1456 (Thunder Bluff) / 1413 (The Barrens) / 1440 (Ashenvale) / 1412 (Mulgore, Forever
-- frame) / 1441 (Thousand Needles), map percent, from tools/data/forever_db.lua (NPC / object spawns; centroids of
-- the objective mob / object spawns for complete steps). Exceptions (route facts, check in game): Silverwing Outpost
-- assault point and the Lakota escort end (RXP Forever / Classic geometry), the Skywatcher Plateau mountain path
-- (Mulgore 40.3,17.6: web guide snippet), the Dorn / Highperch / Darkcloud path points (RXP Classic). Stolen
-- Freewind Supplies (object 670338, 16 spawns 25.9-28.0 / 47.2-56.2) is a DB supplement from the Wowhead Forever
-- tooltip; the Gravelsnout kobold camp by Dorn (51.8-54.4, 43-48.6) is the Wowhead Forever NPC tooltip map of 4113.
--
-- Hub plan (Forever DB; every quest is available to Scourge and Skyborne Horde characters of any class):
--   TB1 : hearth from Sun Rock; 1086 (Zamah); 97538 (Tah Winterhoof, Forever-new); 1195 (Zangen); optional 6561
--         (Bashana, from the optional Blackfathom Deeps run of h-24); fly The Crossroads.
--   AV1 : Mor'shan Rampart -> Torek 6544 (assault on Silverwing Outpost with Torek's raiders); Kuray'bin 6503
--         (Outrunners on the road); Splintertree: fp, 6544 (Ertog), 6441 (Pixel), 742 > 6383 (Senani: the Ashenvale
--         Hunt, 0 XP talk quest that unlocks 23 / 24 / 2), 25 (Mastok).
--   AV2 : Felmusk satyrs 6441; Keeper Ordanus (29, top of Raynewood Retreat) 1088 (from h-24); Shadumbra (28) ->
--         24; Mystral Lake elementals 25 + Tideress (27) -> optional 1918; Ursangous (25) -> 23; Ashenvale Moonwell
--         1195; Sharptalon (31) -> 2; Splintertree: 6441, 25 + 1918, 23 / 24 / 2 > 247 (Senani) =
--         h-28-splintertree-end; fly Sun Rock: 1088 (Braelyn, 2350 XP for one flight: the hearthstone is still used
--         from there); hearth Thunder Bluff.
--   TB2 : 1131 (Melor Stonehoof); 1195 > 1196 (Zangen) = h-28-tb-arrive (druid training insert after it).
--   SW  : Forever-new (XP unknown, ~20 min next to Thunder Bluff: ~20 quest mobs 27-29 plus three turn-ins beat
--         grinding the same time): Skywatcher Plateau 96259 (Muln), 96241 (Mazu'kon), 96260 (Yorn); Gloomrise:
--         spinners, toxin samples, hatchlings + soldiers; optional 96261 Broodmother Valraxx (elite 30) ->
--         item-started 96294; turn-ins; back to Thunder Bluff; fly Camp Taurajo: 1153 (Tatternack, next to the flight
--         master; the ore drops from the Gravelsnout kobolds by Dorn; turned in at the start of h-31).
--   RFK : optional, group: Razorfen Kraul (29-38; entrance on the road south): 1144 Willix the Importer (escort
--         inside, 7250 XP). 1102 needs level 29 at Thunder Bluff before the run (the simulation is at ~28.4) and
--         1109 / 1221 are turned in at the Undercity / Ratchet much later: not used.
--   GL  : south past Razorfen Kraul to the Great Lift: 5881 (Grish), 4542 (Brave Moonhorn).
--   FW1 : fp; 4767 (Elu), 4821 (Hagar), 4542 > 4841 (Longhorn), 5147 (poster), 1196 > 1197 (Rau), 98069 + 98070
--         (Jandia, Forever-new, need 27).
--   GH  : Galak Hold: 4841 centaurs + 1197 brazier (end of the cave); optional 4881 from the Galak Messenger.
--   DO  : Gravelsnout kobolds 1153 (bg); Dorn 1149 (RP teleport to a platform at 26.4,32.9, leap) > 1150; Alien Egg
--         4821 (three spawn points).
--   FW2 : 4841 > 5064 (Longhorn), 1197 (Rau), 4821 > 4865 (Hagar).
--   HC  : harpy cave: 98069 + 98070 in the bg, Grenka 1150.
--   HP  : Highperch: Pao'ka 4770 escort + 4767 wyvern eggs; Steelsnap 1131.
--   WR  : Whitereach: 4770 + 4865 > 5062 (Motega); optional 4881 > 4966 (Kanati, centaur attack); optional 5151
--         (Wizlo; the Enraged Panther is elite 30).
--   DC  : Darkcloud Pinnacle: 5062 agave (bg), 5064 notes, 5147 Arnak, Lakota 4904 escort.
--   FW3 : 4904 (Thalia), 5064 + 5147 (Longhorn), 4767 (Elu), 98069 + 98070 (Jandia); Dorn 1150.
--   SF  : Mirage Raceway: 1110 + 5762 (Kravel), 1104 (Fizzle), 1105 (Wizzle), 1176 (Pozzik), 1175 (Zherin); north
--         Flats loop (tortoises, reavers, basilisks, scavengers, rocket car rubble); crystalhides + gazers; level
--         gate; turn-ins; hearth Thunder Bluff.
--   TB3 : 1131 (Melor), 5062 (Magatha) = end.
-- Carried out: 1106 (Martek, Badlands, h-41), 532 + 567 (from h-22, for h-31), 5762 (Hemet Nesingwary, Stranglethorn,
--   h-34), 1153 (Tatternack,
--   start of h-31), optional 1013 (Book of Ur, Undercity in h-31).
-- Not used (reasons): 6571 Warsong Supplies (its Warsong Axe Shipment, object 178204, is in Booty Bay: Stranglethorn
--   1434 26.4,73.3); 6581 (part of 6571); 6482 Freedom to Ruul (Thistlefur, ~1.5k yd off the loop each way + escort:
--   ~2400 XP for ~8 min, slower than killing at the Flats); 6504 (pages from the Zoram Strand murlocs, far west);
--   6621 / 216 / 6462 / 6641 (Zoram'gar, done by one 1-22 route only); 824 (from 1918, delivery to Zoram'gar);
--   98823 Earthen Echo (Bashana: the follow-up of 95664, whose Titan Relic comes from the Excavation Site dungeon
--   in the Wetlands - not offered without it); 1151 / 1152 (Rok'Alim, elite 30 in the far west after a second Dorn
--   visit; Test of Lore ends in Stonetalon); 5088 Arikara (needs 5062 turned in at Magatha first: a second
--   Needles trip); 1102 / 1109 / 1221 (RFK, see above); 1107 (35; its fins drop in Stranglethorn). 1106 Martek the
--   Exiled IS taken (reqLevel 26, after 1104 + 1105): carried to Martek in the Badlands (h-41: 1106 > 1108 > 1137),
--   whose 1137 > 1190 > 1194 end back at the Mirage Raceway on the way to Tanaris (h-46);
--   1145-1147 The Swarm Grows (1145 needs 29 at the Crossroads, ~27 here); 1089 The Den (Talon Den keys).
-- Automation notes: accepts at one NPC sit in one step; transient steps (fp, fly, go, hearth) come before the
--   quest steps of the same place. The class inserts of the plan go after h-27-tb-arrive (Zamah; next step is Tah
--   on the central mesa), h-28-tb-arrive (Zangen; next step is the Mulgore path) and h-31-tb-hearth (next step is
--   Melor on Hunter Rise): no same-NPC accept follows any of them.
-- Hearthstone: Thunder Bluff all segment (bound by the 1-22 routes). Used three times: Sun Rock -> TB at the start,
--   Sun Rock -> TB again after the Ashenvale loop (or fly, if the hour is not up yet), Shimmering Flats -> TB at the
--   end.
if not FastesBoooy.AddLibraryInsert then return end
FastesBoooy.AddLibrarySegment({
    id = "h-27-ashenvale-needles",
    title = { ru = "27-31 Ясеневый лес, Небесное плато, Тысяча Игл",
              en = "27-31 Ashenvale, Skywatcher Plateau, Thousand Needles" },
    zone = "Thousand Needles",
    levels = { 27, 31 },
    steps = {
        ------------------------------------------------------------------
        -- Thunder Bluff, first visit (level 27)
        ------------------------------------------------------------------
        { id = "h-27-hearth-tb", hearth = "Thunder Bluff", at = { 1456, 45.81, 64.71 },
          note = { ru = "Камень возвращения в Громовой Утёс (снова готов). На откате — летите у Тарма.",
                   en = "Hearth to Thunder Bluff (ready again). On cooldown: fly from Tharm." } },
        { id = "h-27-tb-arrive", turnin = 1086, npc = 3419, at = { 1456, 22.81, 20.89 },
          note = { ru = "Через Вершину Духов вниз в Пруды Видений: аптекарь Зама.",
                   en = "Over Spirit Rise down to the Pools of Vision: Apothecary Zamah." } },
        { turnin = 97538, npc = 3024, at = { 1456, 54.14, 47.05 },
          note = { ru = "Центральная вершина: Тах Заиндевевшее Копыто — стручки лихолиста.",
                   en = "Central mesa: Tah Winterhoof - the Mirkweed Pods." } },
        { accept = 1195, npc = 4721, at = { 1456, 54.97, 51.41 },
          note = { ru = "Занген Каменное Копыто рядом: «Священное пламя» (лунный колодец в Ясеневом лесу).",
                   en = "Zangen Stonehoof next to her: The Sacred Flame (a moonwell in Ashenvale)." } },
        { turnin = 6561, npc = 9087, at = { 1456, 71.06, 34.19 }, optional = true,
          note = { ru = "Если были в Непроглядной Пучине: по мосту на Вершину Старейшин — Башана Рунический Тотем, голова "
                       .. "Келриса (7850 опыта). Нет головы — «Вперёд».",
                   en = "If you did Blackfathom Deeps: over the bridge to Elder Rise - Bashana Runetotem, the head of "
                       .. "Kelris (7850 XP). No head: press Forward." } },
        { id = "h-27-thunder-bluff-flight", fly = "The Crossroads", npc = 3615, at = { 1413, 51.50, 30.34 },
          note = { ru = "Тал на центральной вершине: летите на Перекрёсток.",
                   en = "Tal on the central mesa: fly to the Crossroads." } },

        ------------------------------------------------------------------
        -- The Barrens north -> Ashenvale south road (level 27)
        ------------------------------------------------------------------
        { go = true, radius = 40, at = { 1413, 48.12, 5.42 },
          note = { ru = "По дороге на север до Вала Мор'шан (Кадрак), дальше по дороге в Ясеневый лес.",
                   en = "North along the road to Mor'shan Rampart (Kadrak), then on along the road into Ashenvale." } },
        { id = "h-27-torek", accept = 6544, npc = 12858, at = { 1440, 68.34, 75.30 },
          note = { ru = "Торек у дороги: «Атака Торека». Нет его — он возрождается до 5 мин.",
                   en = "Torek by the road: Torek's Assault. Not there: he respawns within 5 min." } },
        { complete = 6544, at = { 1440, 64.63, 75.34 },
          note = { ru = "Идите за Тореком к Аванпосту Среброкрылых (22-24). Пусть его рейдеры держат врагов; в конце "
                       .. "на балконе — Дуриэль Лунный Огонь.",
                   en = "Follow Torek to Silverwing Outpost (22-24). Let his raiders tank; Duriel Moonfire comes last, on "
                       .. "the balcony." } },
        { accept = 6503, npc = 12867, at = { 1440, 71.11, 68.12 },
          note = { ru = "На северо-восток по дороге: Курай'бин — «Ясеневые разведчики».",
                   en = "North-east along the road: Kuray'bin - Ashenvale Outrunners." } },
        { complete = 6503, at = { 1440, 73.48, 72.25 },
          note = { ru = "9 разведчиков (23-24, в незаметности) вдоль дороги к югу. Шарптэлона (31) пока не трогайте.",
                   en = "9 Outrunners (23-24, stealthed) along the road to the south. Leave Sharptalon (31) for later." } },
        { turnin = 6503, npc = 12867, at = { 1440, 71.11, 68.12 },
          note = { ru = "Курай'бин.", en = "Kuray'bin." } },

        ------------------------------------------------------------------
        -- Splintertree Post, first visit (level 27)
        ------------------------------------------------------------------
        { id = "h-27-splintertree-arrive", fp = "Splintertree Post", npc = 12616, at = { 1440, 73.18, 61.59 },
          note = { ru = "Застава Расщепленного Дерева: Вульгра — точка полёта.",
                   en = "Splintertree Post: Vhulgra - flight point." } },
        { turnin = 6544, npc = 12877, at = { 1440, 73.03, 62.47 },
          note = { ru = "Эртог Гневный Клык.", en = "Ertog Ragetusk." } },
        { accept = 6441, npc = 12724, at = { 1440, 73.06, 61.48 },
          note = { ru = "Пиксель: «Рога сатиров» (16 штук).", en = "Pixel: Satyr Horns (16 of them)." } },
        { turnin = 742, accept = 6383, npc = 12696, at = { 1440, 73.78, 61.46 },
          note = { ru = "Сенани Громосердая: «Большая охота» сдать и взять следующую — она открывает три трофея.",
                   en = "Senani Thunderheart: turn in The Ashenvale Hunt and take the next one - it unlocks the three "
                       .. "trophies." } },
        { turnin = 6383, npc = 12696, at = { 1440, 73.78, 61.46 }, -- WCLBox: a talk quest with 0 XP
          note = { ru = "Сразу сдайте её (0 опыта): Шадумбра, Урсангус и Шарптэлон теперь дают задания.",
                   en = "Turn it in right away (0 XP): Shadumbra, Ursangous and Sharptalon now start quests." } },
        { accept = 25, npc = 12737, at = { 1440, 73.67, 60.00 },
          note = { ru = "Масток: «Остановка в Когтистых горах» — 12 осквернённых элементалей (Мистральское озеро) и "
                       .. "разведать беседку на озере (48.9, 69.6).",
                   en = "Mastok Wrilehiss: Stonetalon Standstill - 12 Befouled Water Elementals (Mystral Lake) and scout "
                       .. "the gazebo on the lake (48.9, 69.6)." } },

        ------------------------------------------------------------------
        -- Ashenvale loop: Felmusk, Shadumbra, Mystral Lake, Ursangous, moonwell, Sharptalon (level 27-28)
        ------------------------------------------------------------------
        { id = "h-27-ashenvale-field-loop", complete = 6441, at = { 1440, 67.10, 54.52 },
          note = { ru = "На северо-запад: сатиры лагеря Фелмуск (25-27) — 16 рогов.",
                   en = "North-west: the Felmusk satyrs (25-27) - 16 horns." } },
        { complete = 1088, at = { 1440, 62.05, 51.37 },
          note = { ru = "По пути на запад — Приют Рейнвуда: по спирали на вершину дерева, хранитель Гордан (29) — голова.",
                   en = "On the way west - Raynewood Retreat: up the spiral to the top of the tree, Keeper Ordanus (29) - "
                       .. "his head." } },
        { accept = 24, use = 16304, at = { 1440, 57.50, 56.00 },
          note = { ru = "Дальше на запад: Шадумбра (28, ночной саблезуб) — голова, щёлкните её.",
                   en = "On west: Shadumbra (28, nightsaber) - her Head, click it." } },
        { complete = 25, at = { 1440, 48.92, 69.56 },
          note = { ru = "На юго-запад к Мистральскому озеру: 12 осквернённых элементалей воды (23-25) по берегам и "
                       .. "разведка беседки на озере (48.9, 69.6) — зайдите в неё, иначе задание не сдать.",
                   en = "South-west to Mystral Lake: 12 Befouled Water Elementals (23-25) along the shores, and scout "
                       .. "the gazebo on the lake (48.9, 69.6) - step into it, or the quest cannot be turned in." } },
        { accept = 1918, use = 16408, at = { 1440, 46.00, 70.00 }, optional = true,
          note = { ru = "Тидресс (27) на западе озера — шар осквернённой воды, щёлкните его (550 опыта у Мастока). "
                       .. "Следующее задание (Зорам'гар) не берите.",
                   en = "Tideress (27) in the west of the lake - Befouled Water Globe, click it (550 XP at Mastok). "
                       .. "Skip the follow-up (Zoram'gar)." } },
        { accept = 23, use = 16303, at = { 1440, 39.80, 65.20 },
          note = { ru = "Ещё на запад: Урсангус (25, медведь) — лапа, щёлкните её.",
                   en = "Further west: Ursangous (25, bear) - his Paw, click it." } },
        { complete = 1195, object = 20806, at = { 1440, 60.20, 72.91 },
          note = { ru = "Назад на восток к лунному колодцу (западнее Аванпоста Среброкрылых): наполните флакон.",
                   en = "Back east to the Ashenvale moonwell (west of Silverwing Outpost): fill the phial." } },
        { accept = 2, use = 16305, at = { 1440, 75.00, 70.10 },
          note = { ru = "Шарптэлон (31, гиппогриф) кружит южнее Заставы — коготь, щёлкните его. +3 уровня: зелья наготове.",
                   en = "Sharptalon (31, hippogryph) circles south of the post - his Claw, click it. 3 levels up: have "
                       .. "potions ready." } },

        ------------------------------------------------------------------
        -- Splintertree Post, last visit -> Sun Rock Retreat -> Thunder Bluff (level 28)
        ------------------------------------------------------------------
        { turnin = 6441, npc = 12724, at = { 1440, 73.06, 61.48 },
          note = { ru = "Пиксель.", en = "Pixel." } },
        { turnin = 25, npc = 12737, at = { 1440, 73.67, 60.00 },
          note = { ru = "Масток.", en = "Mastok." } },
        { turnin = 1918, npc = 12737, at = { 1440, 73.67, 60.00 }, optional = true,
          note = { ru = "Масток: шар воды. «Дже'неу из Служителей Земли» не берите.",
                   en = "Mastok: the water globe. Skip Je'neu of the Earthen Ring." } },
        { turnin = { 24, 23, 2 }, accept = 247, npc = 12696, at = { 1440, 73.78, 61.46 },
          note = { ru = "Сенани: три трофея, затем «Охота завершена».",
                   en = "Senani: the three trophies, then The Hunt Completed." } },
        { id = "h-28-splintertree-end", turnin = 247, npc = 12696, at = { 1440, 73.78, 61.46 },
          note = { ru = "Сразу сдайте «Охота завершена» (плащ).", en = "Turn in The Hunt Completed right away (cloak)." } },
        { fly = "Sun Rock Retreat", npc = 4312, at = { 1442, 45.12, 59.84 },
          note = { ru = "Вульгра: летите в Приют Солнечного Камня (камень не тратьте).",
                   en = "Vhulgra: fly to Sun Rock Retreat (keep the hearthstone)." } },
        { turnin = 1088, npc = 4198, at = { 1442, 45.94, 60.42 },
          note = { ru = "Брайлин: голова Гордана. «Логово» не берите.", en = "Braelyn: Ordanus' head. Skip The Den." } },
        { id = "h-28-hearth-tb", hearth = "Thunder Bluff", at = { 1456, 45.81, 64.71 },
          note = { ru = "Камень в Громовой Утёс. Не прошёл час — летите у Тарма в Громовой Утёс.",
                   en = "Hearth to Thunder Bluff. Less than an hour since the last one: fly from Tharm instead." } },

        ------------------------------------------------------------------
        -- Thunder Bluff, second visit (level 28)
        ------------------------------------------------------------------
        { accept = 1131, npc = 3441, at = { 1456, 61.54, 80.92 },
          note = { ru = "Вершина Охотников (рядом с таверной): Мелор Каменное Копыто — «Стальная Пасть» (Тысяча Игл).",
                   en = "Hunter Rise (next to the inn): Melor Stonehoof - Steelsnap (Thousand Needles)." } },
        { id = "h-28-tb-arrive", turnin = 1195, accept = 1196, npc = 4721, at = { 1456, 54.97, 51.41 },
          note = { ru = "Центральная вершина: Занген — следующее «Священное пламя» (Застава Вольного Ветра).",
                   en = "Central mesa: Zangen - the next Sacred Flame (Freewind Post)." } },

        ------------------------------------------------------------------
        -- Skywatcher Plateau, Gloomrise (Forever-new, level 28; Broodmother Valraxx parts optional)
        ------------------------------------------------------------------
        { go = true, radius = 25, at = { 1412, 40.30, 17.60 },
          note = { ru = "Новое в Forever (опыт неизвестен, ~20 мин, ~20 мобов 27-29 по заданиям): на лифте вниз, на север "
                       .. "вдоль утёса к горной тропе и по ней наверх на Небесное плато.",
                   en = "New in Forever (XP unknown, ~20 min, ~20 quest mobs 27-29): take the lift down, run north along "
                       .. "the bluff to the mountain path and up to Skywatcher Plateau." } },
        { id = "h-28-skywatcher", accept = 96259, npc = 259118, at = { 1412, 33.41, 22.58 },
          note = { ru = "Мулн Ярость Земли в большом шатре: «Защита мёртвых».",
                   en = "Muln Earthfury in the big tent: Defending the Dead." } },
        { accept = 96261, npc = 259118, at = { 1412, 33.41, 22.58 }, optional = true,
          note = { ru = "По желанию: у него же «Матриарх выводка» — элитная 30-го (с группой или с зельями).",
                   en = "Optional: from him too, The Broodmother - an elite 30 (with a group or potions)." } },
        { accept = 96241, npc = 264074, at = { 1412, 32.50, 20.66 },
          note = { ru = "Мазу'кон: пробы яда (экстрактор дадут с заданием).",
                   en = "Mazu'kon: toxin samples (the extractor comes with the quest)." } },
        { accept = 96260, npc = 264072, at = { 1412, 32.47, 19.98 },
          note = { ru = "Йорн Зловещий Тотем: 3 кристаллических шёлка.", en = "Yorn Grimtotem: 3 Crystalline Silk." } },
        { complete = 96260, bg = true, at = { 1412, 33.41, 10.26 },
          note = { ru = "Попутно: ткачи с Мрачной вершины (28) — шёлк.", en = "On the way: Gloomrise Spinners (28) - silk." } },
        { complete = 96241, bg = true, use = 273015, at = { 1412, 33.79, 10.22 },
          note = { ru = "Попутно: экстрактор на обглоданные трупы — 5 проб.",
                   en = "On the way: use the extractor on Gnawed Corpses - 5 samples." } },
        { id = "h-28-mulgore-skywatcher-plateau", complete = 96259, at = { 1412, 33.59, 11.71 },
          note = { ru = "К северу от лагеря: 10 паучков (27-28) и 5 солдат (28-29) с Мрачной вершины.",
                   en = "Gloomrise north of the camp: 10 Hatchlings (27-28) and 5 Soldiers (28-29)." } },
        { complete = 96261, at = { 1412, 33.23, 8.78 }, optional = true,
          note = { ru = "Если брали: в глубине матриарх Валракс — ЭЛИТНАЯ 30-го. Соло рискованно: зелья или помощь; иначе "
                       .. "пропустите (и два следующих её шага).",
                   en = "If taken: Broodmother Valraxx at the back - ELITE 30. Risky solo: potions or help; otherwise skip "
                       .. "(and her next two steps)." } },
        { accept = 96294, use = 273658, at = { 1412, 33.23, 8.78 }, optional = true,
          note = { ru = "С неё — окровавленный пергамент: щёлкните его.",
                   en = "She drops the Bloody Parchment: click it." } },
        { turnin = 96260, npc = 264072, at = { 1412, 32.47, 19.98 },
          note = { ru = "Йорн.", en = "Yorn." } },
        { turnin = 96241, npc = 264074, at = { 1412, 32.50, 20.66 },
          note = { ru = "Мазу'кон.", en = "Mazu'kon." } },
        { turnin = 96259, npc = 259118, at = { 1412, 33.41, 22.58 },
          note = { ru = "Мулн. Задание про идол (Затонувший город, 40) не берите.",
                   en = "Muln. Skip the idol quest (Drowned City, 40)." } },
        { turnin = { 96261, 96294 }, npc = 259118, at = { 1412, 33.41, 22.58 }, optional = true,
          note = { ru = "Если убили Валракс: Мулну — оба её задания.", en = "If you killed Valraxx: both her quests to Muln." } },
        { go = true, radius = 25, at = { 1412, 40.30, 17.60 },
          note = { ru = "Тропой вниз и на юг к лифту Громового Утёса.",
                   en = "Down the path and south to the Thunder Bluff lift." } },

        ------------------------------------------------------------------
        -- Thunder Bluff -> Camp Taurajo -> the Great Lift (level 28)
        ------------------------------------------------------------------
        { id = "h-28-thunder-bluff", go = true, radius = 15, npc = 2995, at = { 1456, 47.00, 49.83 },
          note = { ru = "На лифте наверх и на центральную вершину: распорядитель ветрокрылов Тал.",
                   en = "Up the lift to the central mesa: wind rider master Tal." } },
        { id = "h-28-thunder-bluff-flight", fly = "Camp Taurajo", npc = 10378, at = { 1413, 44.45, 59.15 },
          note = { ru = "Тал: летите в Лагерь Таурахо.", en = "Tal: fly to Camp Taurajo." } },
        { accept = 1153, npc = 3433, at = { 1413, 45.10, 57.68 },
          note = { ru = "Рядом с распорядителем полётов: Таттернак Стальной Горн — «Образец новой руды» (кобольды-Камнерылы "
                       .. "у пещеры Дорна в Тысяче Игл; сдадите на 31-м по дороге в Оргриммар).",
                   en = "Next to the flight master: Tatternack Steelforge - A New Ore Sample (Gravelsnout kobolds by Dorn's "
                       .. "cave in Thousand Needles; handed in at 31 on the way to Orgrimmar)." } },
        -- Optional, group: Razorfen Kraul (29-38; quests ~2.4x Classic XP), entrance on the way south.
        { accept = 1144, at = { 1413, 42.90, 90.20 }, optional = true, ok = "at-far-from-giver", -- Willix is inside the dungeon
          note = { ru = "Если собрали группу: Лабиринты Иглошкурых (7250 опыта за Вилликса и много за мобов, ~50 мин). Вход "
                       .. "к западу от дороги (42.9, 90.2); внутри Импортер Вилликс — «Импортер Вилликс». Без группы — "
                       .. "«Вперёд» на этих трёх шагах.",
                   en = "If you have a group: Razorfen Kraul (7250 XP for Willix plus lots of mob XP, ~50 min). The "
                       .. "entrance is west of the road (42.9, 90.2); inside, Willix the Importer - Willix the Importer. "
                       .. "No group: press Forward on these three steps." } },
        { complete = 1144, at = { 1413, 42.90, 90.20 }, optional = true,
          note = { ru = "Проводите Вилликса к выходу.", en = "Escort Willix to the exit." } },
        { turnin = 1144, at = { 1413, 42.90, 90.20 }, optional = true, ok = "at-far-from-giver", -- Willix, inside the dungeon
          note = { ru = "Вилликс у выхода.", en = "Willix at the exit." } },
        { go = true, radius = 40, at = { 1413, 44.00, 91.00 },
          note = { ru = "По дороге на юг мимо Лабиринтов Иглошкурых к Великому Подъёмнику.",
                   en = "South along the road past Razorfen Kraul to the Great Lift." } },
        { id = "h-29-greatlift-arrive", turnin = 5881, npc = 12576, at = { 1441, 31.86, 21.66 },
          note = { ru = "Гриш Долгий Бег у подъёмника: письмо Магграна.",
                   en = "Grish Longrunner at the lift: Maggran's letter." } },
        { accept = 4542, npc = 10079, at = { 1441, 32.24, 22.17 },
          note = { ru = "Храбрый Лунный Рог рядом: «Послание на Заставу Вольного Ветра».",
                   en = "Brave Moonhorn next to him: Message to Freewind Post." } },
        { go = true, radius = 40, at = { 1441, 47.10, 48.30 },
          note = { ru = "На подъёмнике вниз и на юго-восток к Заставе Вольного Ветра (кентавров пока не трогайте).",
                   en = "Take the lift down and run south-east to Freewind Post (leave the centaurs for now)." } },

        ------------------------------------------------------------------
        -- Freewind Post, first visit (level 28)
        ------------------------------------------------------------------
        { id = "h-28-freewind-post", fp = "Freewind Post", npc = 4317, at = { 1441, 45.14, 49.11 },
          note = { ru = "Застава Вольного Ветра: Найса — точка полёта.", en = "Freewind Post: Nyse - flight point." } },
        { accept = 4767, npc = 10377, at = { 1441, 44.93, 48.92 },
          note = { ru = "Элу: «Всадник на ветрокрыле» — 10 яиц виверны (Скальное гнездовье, запад).",
                   en = "Elu: Wind Rider - 10 Highperch Wyvern Eggs (Highperch, west)." } },
        { accept = 4821, npc = 10539, at = { 1441, 44.64, 50.29 },
          note = { ru = "Хагар Громовое Копыто: «Странное яйцо».", en = "Hagar Lightninghoof: Alien Egg." } },
        { turnin = 4542, accept = 4841, npc = 10537, at = { 1441, 45.67, 50.74 },
          note = { ru = "Утёсный дозорный Длиннорог: «Усмирение кентавров» (12 разведчиков, 10 укротителей, 6 "
                       .. "ветрогонов).",
                   en = "Cliffwatcher Longhorn: Pacify the Centaur (12 Scouts, 10 Wranglers, 6 Windchasers)." } },
        { accept = 5147, object = 176115, at = { 1441, 46.00, 50.86 },
          note = { ru = "Плакат рядом: «Разыскивается: Арнак Зловещий Тотем».",
                   en = "The poster next to him: WANTED: Arnak Grimtotem." } },
        { turnin = 1196, accept = 1197, npc = 4722, at = { 1441, 46.14, 51.71 },
          note = { ru = "Рау Скалобег: «Священное пламя» — раздвоенное копыто из жаровни в пещере Галак.",
                   en = "Rau Cliffrunner: The Sacred Flame - the Cloven Hoof from the brazier in the Galak cave." } },
        { accept = { 98069, 98070 }, npc = 4877, at = { 1441, 46.21, 51.51 },
          note = { ru = "Новое в Forever (опыт неизвестен): Джандия — 8 ящиков припасов и по 5 гарпий в пещере гарпий "
                       .. "(туда всё равно идёте).",
                   en = "New in Forever (XP unknown): Jandia - 8 supply crates and 5 of each harpy in the harpy cave (you "
                       .. "go there anyway)." } },

        ------------------------------------------------------------------
        -- Galak Hold, Dorn, Alien Egg (level 28)
        ------------------------------------------------------------------
        { id = "h-28-thousand-needles-field", complete = 4841, at = { 1441, 43.49, 38.88 },
          note = { ru = "Вниз и на север к крепости Галак: кентавры (24-28) у шатров и в пещере (вход 44.0, 37.4).",
                   en = "Down and north to Galak Hold: centaurs (24-28) by the tents and in the cave (entrance 44.0, "
                       .. "37.4)." } },
        { complete = 1197, object = 20807, at = { 1441, 42.00, 31.50 },
          note = { ru = "В пещере на развилке налево: древняя жаровня в конце — раздвоенное копыто.",
                   en = "In the cave keep left at the fork: the Ancient Brazier at the end - the Cloven Hoof." } },
        { accept = 4881, use = 12564, at = { 1441, 39.43, 33.10 }, optional = true,
          note = { ru = "Гонец Галак (26) ходит между лагерями по дороге: записка — щёлкните её. Не нашли за пару минут "
                       .. "— пропустите (и шаги 4881/4966 тоже).",
                   en = "The Galak Messenger (26) walks the road between the camps: the Assassination Note - click it. "
                       .. "Not found in a few minutes: skip it (and the 4881/4966 steps)." } },
        { go = true, radius = 25, at = { 1441, 54.60, 44.30 },
          note = { ru = "На восток: тропа наверх к пещере Дорна.", en = "East: the path up to Dorn's cave." } },
        { complete = 1153, bg = true, at = { 1441, 53.10, 45.60 },
          note = { ru = "Попутно: землекопы и геодезисты-Камнерылы (28-30) у тропы к Дорну — неочищенный образец руды.",
                   en = "On the way: Gravelsnout Diggers and Surveyors (28-30) by the path to Dorn - an Unrefined Ore "
                       .. "Sample." } },
        { id = "h-28-dorn-plainstalker", accept = 1149, npc = 2986, at = { 1441, 53.95, 41.49 },
          note = { ru = "Дорн Странник Равнин: «Испытание веры».", en = "Dorn Plainstalker: Test of Faith." } },
        { complete = 1149, at = { 1441, 26.43, 32.93 },
          note = { ru = "После взятия подождите короткую сценку Дорна (~7 с): он телепортирует вас на деревянный помост "
                       .. "на игле далеко на западе (26.4, 32.9). Прыгайте с его края — духи вернут вас к Дорну, вы не "
                       .. "разобьётесь. Не прыгайте с уступа у самого Дорна.",
                   en = "After accepting, wait out Dorn's short RP (~7 s): he teleports you onto a wooden platform on a "
                       .. "needle far to the west (26.4, 32.9). Jump off its end; the spirits teleport you back to Dorn, "
                       .. "you do not die. Do not jump off Dorn's own ledge." } },
        { turnin = 1149, accept = 1150, npc = 2986, at = { 1441, 53.95, 41.49 },
          note = { ru = "Дорн: «Испытание стойкости» — коготь Гренки (пещера гарпий).",
                   en = "Dorn: Test of Endurance - Grenka's Claw (the harpy cave)." } },
        { complete = 4821, object = 175565, at = { 1441, 56.40, 50.40 },
          note = { ru = "Странное яйцо — в одном из трёх мест: 56.4, 50.4 → 52.3, 55.2 → 37.6, 56.1.",
                   en = "The Alien Egg is at one of three spots: 56.4, 50.4 -> 52.3, 55.2 -> 37.6, 56.1." } },

        ------------------------------------------------------------------
        -- Freewind Post, second visit (level 28-29)
        ------------------------------------------------------------------
        { turnin = 4841, accept = 5064, npc = 10537, at = { 1441, 45.67, 50.74 },
          note = { ru = "Длиннорог: «Шпионаж Зловещего Тотема» (3 записки на Вершине Темной Тучи).",
                   en = "Longhorn: Grimtotem Spying (3 notes on Darkcloud Pinnacle)." } },
        { turnin = 1197, npc = 4722, at = { 1441, 46.14, 51.71 },
          note = { ru = "Рау.", en = "Rau." } },
        { turnin = 4821, accept = 4865, npc = 10539, at = { 1441, 44.64, 50.29 },
          note = { ru = "Хагар: «Змеиная дикость» — отнесёте Мотеге на заставу Белого Плеса.",
                   en = "Hagar: Serpent Wild - deliver it to Motega at Whitereach." } },

        ------------------------------------------------------------------
        -- Harpy cave (level 29)
        ------------------------------------------------------------------
        { complete = { 98069, 98070 }, bg = true, at = { 1441, 27.03, 52.04 },
          note = { ru = "Попутно: визгливые гарпии (28-30) и ящики украденных припасов у пещеры и внутри.",
                   en = "On the way: Screeching harpies (28-30) and Stolen Freewind Supplies around and inside the "
                       .. "cave." } },
        { complete = 1150, at = { 1441, 26.35, 55.55 },
          note = { ru = "Вниз, на запад, тропой наверх (27.7, 50.0) в пещеру (27.3, 51.2): в конце откройте ящик — "
                       .. "Гренка (31). Гарпии накладывают безмолвие.",
                   en = "Down, west, up the path (27.7, 50.0) into the cave (27.3, 51.2): open the crate at the end - "
                       .. "Grenka (31). The harpies silence." } },

        ------------------------------------------------------------------
        -- Highperch, Steelsnap, Whitereach Post (level 29)
        ------------------------------------------------------------------
        { go = true, radius = 25, at = { 1441, 13.20, 39.70 },
          note = { ru = "На запад к Скальному гнездовью: тропа наверх.", en = "West to Highperch: the path up." } },
        { id = "h-28-pao-ka-swiftmountain", accept = 4770, npc = 10427, at = { 1441, 17.89, 40.57 },
          note = { ru = "Пао'ка Быстрая Гора: «Домой» — сопровождение.",
                   en = "Pao'ka Swiftmountain: Homeward Bound - an escort." } },
        { complete = 4767, bg = true, object = 175384, at = { 1441, 13.39, 37.31 },
          note = { ru = "Попутно: 10 яиц виверны в гнёздах Скального гнездовья.",
                   en = "On the way: 10 Highperch Wyvern Eggs in the nests." } },
        { complete = 4770, at = { 1441, 14.60, 32.70 },
          note = { ru = "Ведите Пао'ку на север через гнёзда — нападают виверны.",
                   en = "Lead Pao'ka north through the nests - wyverns attack." } },
        { complete = 4767, object = 175384, at = { 1441, 11.40, 35.00 },
          note = { ru = "Доберите яйца в западных гнёздах.", en = "Finish the eggs in the western nests." } },
        { complete = 1131, at = { 1441, 17.79, 19.79 },
          note = { ru = "Вниз и на север: Стальная Пасть (30, гиена) ходит по каньону — ребро.",
                   en = "Down and north: Steelsnap (30, hyena) roams the canyon - his Rib." } },
        { id = "h-28-whitereach-post", turnin = { 4770, 4865 }, accept = 5062, npc = 10428, at = { 1441, 21.54, 32.35 },
          note = { ru = "Застава Белого Плеса: Мотега Огненная Грива — «Священный огонь» (агава на Вершине Темной Тучи).",
                   en = "Whitereach Post: Motega Firemane - Sacred Fire (agave on Darkcloud Pinnacle)." } },
        { turnin = 4881, accept = 4966, npc = 10638, at = { 1441, 21.25, 32.06 }, optional = true,
          note = { ru = "Если есть записка: Канати Седое Облако — «Защитить Канати».",
                   en = "If you have the note: Kanati Greycloud - Protect Kanati Greycloud." } },
        { complete = 4966, at = { 1441, 21.18, 31.68 }, optional = true,
          note = { ru = "Нападают убийцы Галак (27-28) — убейте их у Канати.",
                   en = "Galak Assassins (27-28) attack - kill them next to Kanati." } },
        { turnin = 4966, npc = 10638, at = { 1441, 21.25, 32.06 }, optional = true,
          note = { ru = "Канати.", en = "Kanati." } },
        { accept = 5151, npc = 10941, at = { 1441, 21.43, 32.55 }, optional = true,
          note = { ru = "По желанию: Визло — «Гиперконденсаторная штуковина». В клетке ЭЛИТНАЯ пантера 30-го.",
                   en = "Optional: Wizlo Bearingshiner - Hypercapacitor Gizmo. The panther in the cage is ELITE 30." } },
        { complete = 5151, at = { 1441, 22.76, 24.62 }, optional = true,
          note = { ru = "Клетка к северу: откройте — разъярённая пантера; штуковина с неё.",
                   en = "The cage to the north: open it - the Enraged Panther; the Gizmo drops from her." } },
        { turnin = 5151, npc = 10941, at = { 1441, 21.43, 32.55 }, optional = true,
          note = { ru = "Визло.", en = "Wizlo." } },

        ------------------------------------------------------------------
        -- Darkcloud Pinnacle (level 29)
        ------------------------------------------------------------------
        { go = true, radius = 20, at = { 1441, 31.20, 36.90 },
          note = { ru = "На восток: тропа наверх на Вершину Темной Тучи (Зловещий Тотем 27-30).",
                   en = "East: the path up to Darkcloud Pinnacle (Grimtotem 27-30)." } },
        { complete = 5062, bg = true, object = 175928, at = { 1441, 35.45, 35.45 },
          note = { ru = "Попутно: 10 листов огненной агавы по всей вершине.",
                   en = "On the way: 10 Incendia Agave all over the pinnacle." } },
        { complete = { [5064] = { 1 } }, object = 176344, at = { 1441, 31.79, 32.58 },
          note = { ru = "Сундук с документами №1 на северном уступе — записка 1.",
                   en = "Document Chest #1 on the northern ledge - Secret Note #1." } },
        { complete = { [5064] = { 2 } }, object = 190483, at = { 1441, 33.76, 39.99 },
          note = { ru = "По мостикам на юг: сундук №2 — записка 2.",
                   en = "Over the rope bridges south: chest #2 - Secret Note #2." } },
        { complete = 5064, object = 190484, at = { 1441, 39.34, 41.53 },
          note = { ru = "На восток: сундук №3 — записка 3.", en = "East: chest #3 - Secret Note #3." } },
        { complete = 5147, at = { 1441, 38.11, 26.87 },
          note = { ru = "На север: Арнак Зловещий Тотем (29) — копыто.",
                   en = "North: Arnak Grimtotem (29) - his Hoof." } },
        { id = "h-28-lakota-windsong", accept = 4904, npc = 10646, at = { 1441, 37.95, 26.45 },
          note = { ru = "Лакота Песнь Ветра рядом: «Свобода» — сопровождение.",
                   en = "Lakota Windsong next to him: Free at Last - an escort." } },
        { complete = 4904, at = { 1441, 30.70, 37.10 },
          note = { ru = "Ведите её к спуску на западе: на площадках появляются Зловещие Тотемы.",
                   en = "Lead her to the way down in the west: Grimtotems spawn on the platforms." } },

        ------------------------------------------------------------------
        -- Freewind Post, last visit, Dorn (level 29)
        ------------------------------------------------------------------
        { turnin = 4904, npc = 10645, at = { 1441, 45.97, 51.61 },
          note = { ru = "На восток в Заставу: Талия Янтарная Шкура.", en = "East to Freewind: Thalia Amberhide." } },
        { turnin = { 5064, 5147 }, npc = 10537, at = { 1441, 45.67, 50.74 },
          note = { ru = "Длиннорог. «Родословная» (35) не берите.", en = "Longhorn. Skip Family Tree (35)." } },
        { turnin = 4767, npc = 10377, at = { 1441, 44.93, 48.92 },
          note = { ru = "Элу.", en = "Elu." } },
        { turnin = { 98069, 98070 }, npc = 4877, at = { 1441, 46.21, 51.51 },
          note = { ru = "Джандия.", en = "Jandia." } },
        { go = true, radius = 25, at = { 1441, 54.60, 44.30 },
          note = { ru = "Тропа к пещере Дорна.", en = "The path to Dorn's cave." } },
        { turnin = 1150, npc = 2986, at = { 1441, 53.95, 41.49 },
          note = { ru = "Дорн. «Испытание силы» (Рок'Алим, элитный 30-й на дальнем западе) не берите.",
                   en = "Dorn. Skip Test of Strength (Rok'Alim, elite 30 in the far west)." } },

        ------------------------------------------------------------------
        -- Shimmering Flats (level 29-31)
        ------------------------------------------------------------------
        { accept = { 1110, 5762 }, npc = 4452, at = { 1441, 77.79, 77.27 },
          note = { ru = "На юго-восток на Мерцающую равнину, гоночная трасса: Кравел Угледум — запчасти ракетомобиля и "
                       .. "письмо для Хемета (Тернистая долина, позже).",
                   en = "South-east into the Shimmering Flats, Mirage Raceway: Kravel Koalbeard - Rocket Car Parts and "
                       .. "the letter for Hemet (Stranglethorn, later)." } },
        { accept = 1104, npc = 4454, at = { 1441, 78.06, 77.13 },
          note = { ru = "Физзл Латуньболт: яд скорпидов.", en = "Fizzle Brassbolts: Salt Flat Venom." } },
        { accept = 1105, npc = 4453, at = { 1441, 78.14, 77.12 },
          note = { ru = "Виззл Латуньболт: панцири черепах.", en = "Wizzle Brassbolts: Hardened Shells." } },
        { accept = 1175, npc = 4629, at = { 1441, 81.63, 77.95 },
          note = { ru = "Распорядитель Жерин: «Кочка на дороге» — 10 василисков, 10 кристаллошкурых, 6 созерцателей. "
                       .. "Поззика (кости, нужен 29-й) возьмёте на обратном пути.",
                   en = "Trackmaster Zherin: A Bump in the Road - 10 Basilisks, 10 Crystalhides, 6 Gazers. Pozzik "
                       .. "(bones, needs 29) comes on the way back." } },
        { complete = 1110, bg = true, object = { 19868, 19869, 19870, 19871, 19872, 19873 }, at = { 1441, 74.00, 61.20 },
          note = { ru = "Всё время: обломки ракетомобиля вдоль трассы — 30 запчастей.",
                   en = "All the time: Rocket Car Rubble along the track - 30 parts." } },
        { complete = 1175, bg = true, at = { 1441, 74.74, 60.18 },
          note = { ru = "Попутно: василиски Соляного Камня (30-31) на севере и кристаллошкурые (32-33) повсюду.",
                   en = "On the way: Saltstone Basilisks (30-31) in the north and Crystalhides (32-33) everywhere." } },
        { complete = 1105, at = { 1441, 76.45, 58.20 },
          note = { ru = "Север равнины: черепахи Искристого Панциря (30-31) — 9 панцирей.",
                   en = "North of the Flats: Sparkleshell Tortoises (30-31) - 9 shells." } },
        { complete = 1104, level = 29, at = { 1441, 76.60, 62.16 },
          note = { ru = "Там же: скорпиды-разорители (31-32) — 6 ядов. Задание Поззика требует 29-й: не дотянули — "
                       .. "ещё пара мобов здесь.",
                   en = "Same area: Scorpid Reavers (31-32) - 6 venoms. Pozzik's quest needs level 29: not there yet - "
                       .. "a few more mobs here." } },
        { accept = 1176, npc = 4630, at = { 1441, 80.18, 75.88 },
          note = { ru = "Обратно к трассе: Поззик — 10 полых костей стервятников.",
                   en = "Back to the raceway: Pozzik - Load Lightening, 10 Hollow Vulture Bones." } },
        { complete = 1176, at = { 1441, 77.78, 79.17 },
          note = { ru = "Стервятники (32-34) кружат южнее трассы; падальщики (30-32) — на севере.",
                   en = "Salt Flats Vultures (32-34) circle south of the raceway; Scavengers (30-32) are in the north." } },
        { id = "h-27-ashenvale-needles-level-gate", complete = 1175, level = { 30, 0.67 },
          ok = { ["level-grind"] = 110 }, -- end-of-segment gate: 109 / 84 kills in the normal run (druid / paladin)
          at = { 1441, 77.76, 87.73 },
          note = { ru = "Юг: 6 созерцателей (34-35), доберите кристаллошкурых. Затем бейте мобов севера (черепахи, "
                       .. "скорпиды, василиски 30-32 — плотно, лучший опыт рядом) до 30-го + 67%: сдачи на трассе и в "
                       .. "Громовом Утёсе дадут 31-й. Без подземелий (Пучина, Лабиринты) и Валракс это до ~300 убийств: "
                       .. "еда с «Сытостью» (+5%).",
                   en = "South: 6 Gazers (34-35), finish the Crystalhides. Then kill the north Flats mobs (tortoises, "
                       .. "scorpids, basilisks 30-32: dense, the best XP nearby) up to level 30 + 67%: the raceway and "
                       .. "Thunder Bluff turn-ins make 31. Without the dungeons (Blackfathom, Razorfen Kraul) and Valraxx "
                       .. "this is up to ~300 kills: Well Fed food (+5%)." } },
        { turnin = 1110, npc = 4452, at = { 1441, 77.79, 77.27 },
          note = { ru = "Кравел. «Начальник порта Диззивиг» (36) не берите.", en = "Kravel. Skip Wharfmaster Dizzywig (36)." } },
        { turnin = 1105, npc = 4453, at = { 1441, 78.14, 77.12 },
          note = { ru = "Виззл. «Плавники» (35) не берите.", en = "Wizzle. Skip Encrusted Tail Fins (35)." } },
        { turnin = 1104, accept = 1106, npc = 4454, at = { 1441, 78.06, 77.13 },
          note = { ru = "Физзл (после сдачи обоих братьев): возьмите «Мартек Изгнанник» - письмо Мартеку в Бесплодные "
                       .. "земли (h-41, рядом с Ригглфаззом; держите его до тех пор).",
                   en = "Fizzle (after both brothers' turn-ins): take Martek the Exiled - the letter to Martek in the "
                       .. "Badlands (h-41, next to Rigglefuzz; keep it until then)." } },
        { turnin = 1176, npc = 4630, at = { 1441, 80.18, 75.88 },
          note = { ru = "Поззик. Следующее не берите.", en = "Pozzik. Skip the follow-up." } },
        { id = "h-31-flats-end", turnin = 1175, npc = 4629, at = { 1441, 81.63, 77.95 },
          note = { ru = "Жерин. Письмо Хемету (5762) держите до Тернистой долины.",
                   en = "Zherin. Keep the letter to Hemet (5762) for Stranglethorn." } },

        ------------------------------------------------------------------
        -- Thunder Bluff, last visit (level 31)
        ------------------------------------------------------------------
        { id = "h-31-tb-hearth", hearth = "Thunder Bluff", at = { 1456, 45.81, 64.71 },
          note = { ru = "Камень в Громовой Утёс.", en = "Hearth to Thunder Bluff." } },
        { turnin = 1131, npc = 3441, at = { 1456, 61.54, 80.92 },
          note = { ru = "Мелор на Вершине Охотников. «Ледяная Пасть» (37) не берите.",
                   en = "Melor on Hunter Rise. Skip Frostmaw (37)." } },
        { id = "h-31-tb-end", turnin = 5062, npc = 4046, at = { 1456, 69.85, 30.91 },
          note = { ru = "Вершина Старейшин: Магата Зловещий Тотем. «Арикара» не берите (Тысяча Игл позади).",
                   en = "Elder Rise: Magatha Grimtotem. Skip Arikara (Thousand Needles is behind you)." } },
    },
})
