-- FastesBoooy_SkyborneDruid / Segments / 04_Barrens.lua
-- Segment "sd-04-barrens": The Barrens, levels 15-18.
-- Orgrimmar (hearthstone on cooldown) -> Razor Hill (840) -> Far Watch Post (842) -> the Crossroads
-- (bind, flight point, the hub quests) -> Thorn Hill (871) -> Crossroads -> the second Razormane camp
-- (872 + 5041) -> Ratchet (flight point, pirates, the Missing Shipment chain) -> walk back west through
-- the zhevra herds -> Crossroads -> Regthar Deathgate, the Forgotten Pools, Barak -> Witchwing harpies ->
-- Vrang Wildgore and Walton (Forever-new 955xx chain) -> the Samophlange chain -> Ignition / The Escape
-- -> the Boulder Lode Mine -> Teleport: Moonglade (training at 16) -> hearth to the Crossroads ->
-- Echeyakee -> fly to Ratchet -> south sweep (Stolen Booty, Stolen Silver, Stagnant Oasis, Verog, the
-- raptor nests, Mankrik's wife) -> Camp Taurajo (bind, flight point) -> fly to the Crossroads -> Regthar,
-- Hezrul at the Lushwater Oasis -> harpy lieutenants -> the Stonetalon border (1062 + 6548).
-- Coordinates: Forever DB snapshot (tools/data/forever_db.lua): NPC / object spawns and centroids of the
-- objective mob / object spawns. The Orgrimmar gate and the coast point north of Ratchet are terrain
-- points cross-checked with the reference; the Forgotten Pools point is the midpoint of the two Laden
-- Mushroom spawns at the pools (870 is an exploration objective without a DB position).
-- 1061 (optional, taken from Zor Lonetree in Orgrimmar in sd-03 at level 13+) is handed in at Seereth right
-- before 1062. Skipped on purpose: 3921/3922 (back north for 490 + 1050 XP), 97003 / 92706 / 4021 (group or
-- elite fights), 866 (herbalism), 959 / 1491 / 1486 / 1487 (Wailing Caverns), 868 (17+ escort-like egg run,
-- next segment), 6541 / 6543 (Mor'shan, off the path), 924 (needs the Durotar 809 chain).
FastesBoooy.AddSegment("horde-skyborne-druid", {
    id = "sd-04-barrens",
    title = {
        ru = "15-18 Степи: Перекрёсток, Кабестан, лагерь Таурахо",
        en = "15-18 The Barrens: the Crossroads, Ratchet, Camp Taurajo",
    },
    zone = "The Barrens",
    -- WARN-OK: segment-level (the validator ends this segment at ~19.0, 0.02 over its 1-level tolerance, only with
    -- its estimates for the 7 Forever-new quests here (~8k XP of 44k) and every optional step of sd-01..sd-04
    -- counted; the Barrens part stays 15-18 like ud-04-barrens, sd-05 absorbs the difference)
    levels = { 15, 18 },
    steps = {
        ---------------------------------------------------------------------
        -- Orgrimmar -> Razor Hill -> Far Watch Post (15)
        ---------------------------------------------------------------------
        { id = "sd04-start", go = true, at = { 1454, 48.97, 92.84 }, radius = 20,
          note = {
              ru = "Камень возвращения на перезарядке. Из Оргриммара через главные ворота на юг, "
                  .. "дальше по дороге в Колючий Холм. На бегу - «Небесное зрение».",
              en = "The hearthstone is on cooldown. Leave Orgrimmar through the main gate (south) and follow the "
                  .. "road to Razor Hill. Cast Skysight while running.",
          } },
        { accept = 840, npc = 3336, at = { 1411, 50.84, 43.59 },
          note = {
              ru = "Takrin Pathseeker у дороги в Колючем Холме.",
              en = "Takrin Pathseeker by the road in Razor Hill.",
          } },
        { turnin = 840, accept = 842, npc = 3337, at = { 1413, 62.26, 19.38 },
          note = {
              ru = "На запад по дороге, через мост в Степи: Kargal Battlescar на Заставе Дальнего Дозора.",
              en = "West along the road and over the bridge into the Barrens: Kargal Battlescar at Far Watch Post.",
          } },
        ---------------------------------------------------------------------
        -- The Crossroads, first visit (15)
        ---------------------------------------------------------------------
        { id = "sd04-sethearth-xroads", sethearth = "The Crossroads", npc = 3934, at = { 1413, 51.99, 29.89 },
          note = {
              ru = "По дороге на юго-запад до Перекрёстка. Трактирщик Boorand: камень возвращения - "
                  .. "Перекрёсток (вернётесь сюда из Лунной поляны). Купите воды.",
              en = "South-west along the road to the Crossroads. Innkeeper Boorand: bind your hearthstone here (you "
                  .. "hearth back from Moonglade later). Buy water.",
          } },
        { id = "sd04-fp-xroads", fp = "The Crossroads", npc = 3615, at = { 1413, 51.50, 30.34 },
          note = {
              ru = "Devrak на башне: откройте карту полётов (точка изучится).",
              en = "Devrak on the tower: open the flight map (learns the point).",
          } },
        { turnin = 1358, accept = { 1492, 848 }, npc = 3390, at = { 1413, 51.44, 30.15 } },
        { accept = 869, npc = 3464, at = { 1413, 51.93, 30.32 } },
        { turnin = 98024, accept = { 871, 5041 }, npc = 3429, at = { 1413, 51.50, 30.87 } }, -- WARN-OK: xp-unknown
        { turnin = 842, accept = 844, npc = 3338, at = { 1413, 52.23, 31.01 } },
        { accept = 870, npc = 3448, at = { 1413, 52.26, 31.93 } },
        ---------------------------------------------------------------------
        -- Thorn Hill (15)
        ---------------------------------------------------------------------
        { complete = { 869, 844 }, bg = true,
          note = {
              ru = "Попутно: головы ящеров (Sunscale Lashtail / Screecher) и клювы долгоногов "
                  .. "(Plainstrider) - их полно вокруг Перекрёстка и по всему пути.",
              en = "On the way: raptor heads (Sunscale Lashtails / Screechers) and plainstrider beaks - they are all "
                  .. "around the Crossroads and along the whole route.",
          } },
        { accept = 819, bg = true, use = 4926, at = { 1413, 55.70, 27.30 },
          note = {
              ru = "Пустой бочонок Чена на земле: обычно в Терновом холме (55.7, 27.3), иначе у 55.8, 20.0; "
                  .. "позже по пути: 54.7, 37.2, 43.8, 12.2 (у Vrang), 57.2, 9.0. Подберите и начните задание.",
              en = "Chen's Empty Keg on the ground: usually in Thorn Hill (55.7, 27.3), otherwise at 55.8, 20.0; later "
                  .. "on the route: 54.7, 37.2, 43.8, 12.2 (at Vrang), 57.2, 9.0. Loot it and start the quest.",
          } },
        { complete = 871, at = { 1413, 55.3, 25.9 },
          note = {
              ru = "Терновый холм к северо-востоку: 8 Water Seeker, 8 Thornweaver, 3 Hunter (охотники "
                  .. "на восточном краю, стреляют).",
              en = "Thorn Hill to the north-east: 8 Water Seekers, 8 Thornweavers, 3 Hunters (the Hunters are on the "
                  .. "east side and shoot).",
          } },
        ---------------------------------------------------------------------
        -- The Crossroads, second visit (15)
        ---------------------------------------------------------------------
        { turnin = 844, accept = 845, npc = 3338, at = { 1413, 52.23, 31.01 },
          note = {
              ru = "Нет 7 клювов - добейте долгоногов вокруг городка.",
              en = "Short of 7 beaks - kill plainstriders around the town first.",
          } },
        { complete = 845, bg = true,
          note = {
              ru = "Попутно: копыта зебр (Zhevra Runner) - восточнее Тернового холма, у побережья "
                  .. "севернее Кабестана и на обратном пути на запад.",
              en = "On the way: zhevra hooves (Zhevra Runners) - east of Thorn Hill, along the coast north of Ratchet "
                  .. "and on the way back west.",
          } },
        { accept = 867, npc = 3449, at = { 1413, 51.62, 30.90 } },
        { turnin = 871, accept = 872, npc = 3429, at = { 1413, 51.50, 30.87 } },
        ---------------------------------------------------------------------
        -- The second Razormane camp -> Ratchet (16)
        ---------------------------------------------------------------------
        { complete = { 872, 5041 }, object = 175708, at = { 1413, 58.6, 25.6 },
          note = {
              ru = "На восток за Терновый холм ко второму лагерю: 8 Geomancer, 8 Defender, Kreenig "
                  .. "Snarlsnout (15) у 58.5, 27.0 - клык; ящик припасов в лагере. Бочонка ещё нет - "
                  .. "по пути загляните к 55.8, 20.0.",
              en = "East past Thorn Hill to the second camp: 8 Geomancers, 8 Defenders, Kreenig Snarlsnout (15) at "
                  .. "58.5, 27.0 for the tusk; the supply crate is in the camp. No keg yet - check 55.8, 20.0 on the "
                  .. "way.",
          } },
        { go = true, at = { 1413, 63.6, 31.5 }, radius = 30,
          note = {
              ru = "На юго-восток к побережью: прайд Savannah Matriarch (17-18) у 60-63, 32-35 обходите "
                  .. "с востока. Здесь же зебры.",
              en = "South-east to the coast: pass the Savannah Matriarch pride (17-18) at 60-63, 32-35 on its east "
                  .. "side. Zhevras here too.",
          } },
        ---------------------------------------------------------------------
        -- Ratchet (16)
        ---------------------------------------------------------------------
        { id = "sd04-fp-ratchet", fp = "Ratchet", npc = 16227, at = { 1413, 63.08, 37.16 },
          note = {
              ru = "Кабестан. Сначала Bragok: откройте карту полётов (точка изучится).",
              en = "Ratchet. Bragok first: open the flight map (learns the point).",
          } },
        { accept = 97253, npc = 7161, at = { 1413, 63.07, 36.32 } },
        { accept = 887, npc = 3391, at = { 1413, 62.68, 36.23 } },
        { accept = 894, npc = 3442, at = { 1413, 62.98, 37.22 } },
        { accept = 895, object = 3972, at = { 1413, 62.59, 37.47 },
          note = {
              ru = "Плакат «Разыскивается» у дома.",
              en = "The WANTED poster by the house.",
          } },
        { turnin = 819, accept = 821, optional = true, npc = 3292, at = { 1413, 62.26, 38.39 }, -- carried: 821 -> sd-05
          note = {
              ru = "Нет бочонка - пропустите шаг. Найдёте позже - сдайте Drohn при следующем визите.",
              en = "No keg - skip the step. Found it later - hand it to Drohn on the next visit.",
          } },
        { complete = 821, bg = true,
          note = {
              ru = "Попутно: клыки львов (Savannah Prowler и др.), почки долгоногов, позже на юге - "
                  .. "рог громового ящера (Stormsnout у 47, 52).",
              en = "On the way: lion tusks (Savannah Prowlers and other lions), plainstrider kidneys, later in the "
                  .. "south one thunder lizard horn (Stormsnouts near 47, 52).",
          } },
        { turnin = 1492, npc = 3453, at = { 1413, 63.35, 38.45 } },
        ---------------------------------------------------------------------
        -- Southsea pirates (16)
        ---------------------------------------------------------------------
        { complete = 97253, object = 660930, at = { 1413, 61.86, 46.27 },
          note = {
              ru = "На юг вдоль берега: верхний (западный) лагерь пиратов - 5 куч деталей.",
              en = "South along the shore: the upper (western) pirate camp - 5 piles of parts.",
          } },
        { complete = { 887, 895 }, at = { 1413, 63.7, 46.9 },
          note = {
              ru = "Лагерь на пляже: 12 Brigand, 6 Cannoneer. Baron Longshore (16) в одном из трёх "
                  .. "мест около 63.4, 48.6.",
              en = "The beach camp: 12 Brigands, 6 Cannoneers. Baron Longshore (16) stands at one of three spots "
                  .. "near 63.4, 48.6.",
          } },
        ---------------------------------------------------------------------
        -- Ratchet, the Missing Shipment (16)
        ---------------------------------------------------------------------
        { turnin = { 887, 895 }, accept = 890, npc = 3391, at = { 1413, 62.68, 36.23 } },
        { turnin = 97253, npc = 7161, at = { 1413, 63.07, 36.32 } }, -- WARN-OK: xp-unknown (Forever-new)
        { turnin = 890, accept = { 892, 896 }, npc = 3453, at = { 1413, 63.35, 38.45 } },
        { turnin = 892, accept = 888, npc = 3391, at = { 1413, 62.68, 36.23 } }, -- carried: 888 -> sd-05
        { go = true, at = { 1413, 55.3, 35.5 }, radius = 40,
          note = {
              ru = "Не летите: идите на запад к Перекрёстку через стада зебр (копыта) и ящеров (головы).",
              en = "Do not fly: walk west to the Crossroads through the zhevra herds (hooves) and the raptors "
                  .. "(heads).",
          } },
        ---------------------------------------------------------------------
        -- The Crossroads, third visit (16)
        ---------------------------------------------------------------------
        { turnin = 845, accept = 903, npc = 3338, at = { 1413, 52.23, 31.01 },
          note = {
              ru = "Нет 4 копыт - добейте зебр к юго-востоку от городка.",
              en = "Short of 4 hooves - kill zhevras south-east of the town first.",
          } },
        { turnin = { 5041, 872 }, npc = 3429, at = { 1413, 51.50, 30.87 } },
        ---------------------------------------------------------------------
        -- West: Regthar, the Forgotten Pools, Barak (16-17)
        ---------------------------------------------------------------------
        { accept = { 850, 855 }, npc = 3389, at = { 1413, 45.34, 28.41 },
          note = {
              ru = "На запад по дороге к Regthar Deathgate.",
              en = "West along the road to Regthar Deathgate.",
          } },
        { complete = { 855, 848, 903 }, bg = true,
          note = {
              ru = "Попутно: наручи с кентавров Kolkar (12-16), споры с грибов Laden Mushroom (у Забытых "
                  .. "прудов и в оазисах), когти Savannah Prowler (здесь и на севере).",
              en = "On the way: bracers from Kolkar centaurs (12-16), spores from Laden Mushrooms (at the Forgotten "
                  .. "Pools and in the oases), claws from Savannah Prowlers (here and in the north).",
          } },
        -- 870 is an exploration objective: a 'go' step here, its 'complete' sits in the turn-in step (a separate
        -- complete step would be done at once on the simulator mock, which has no event objectives, and would
        -- fast-forward the Ratchet flight point and the other transient steps before it).
        { go = true, at = { 1413, 44.97, 22.56 }, radius = 25,
          note = {
              ru = "На север к Забытым прудам: зайдите в воду (цель задания). Рядом 4 гриба для спор.",
              en = "North to the Forgotten Pools: step into the water (the quest objective). Four spore mushrooms "
                  .. "around.",
          } },
        { complete = 850, npc = 3394, at = { 1413, 42.80, 23.52 },
          note = {
              ru = "Barak Kodobane (16) в лагере Kolkar западнее.",
              en = "Barak Kodobane (16) in the Kolkar camp to the west.",
          } },
        { turnin = 850, accept = 851, npc = 3389, at = { 1413, 45.34, 28.41 },
          note = {
              ru = "Обратно к Regthar. Наручи пока не сдавайте (сдадите в конце сегмента).",
              en = "Back to Regthar. Keep the bracers (handed in at the end of the segment).",
          } },
        ---------------------------------------------------------------------
        -- North-west: harpies, Vrang Wildgore, Walton (17)
        ---------------------------------------------------------------------
        { complete = 867, at = { 1413, 40.8, 17.2 },
          note = {
              ru = "На северо-запад: Witchwing Harpy / Roguefeather - 8 когтей. Западнее (Windcaller, "
                  .. "Slayer) - 16-18.",
              en = "North-west: Witchwing Harpies / Roguefeathers for 8 talons. Further west (Windcallers, Slayers) "
                  .. "they are 16-18.",
          } },
        { accept = { 95494, 95507 }, npc = 3682, at = { 1413, 43.80, 12.21 },
          note = {
              ru = "Vrang Wildgore: заодно продайте хлам и почините снаряжение.",
              en = "Vrang Wildgore: sell junk and repair here too.",
          } },
        { complete = { 95494, 95507 }, object = 640104, at = { 1413, 45.33, 14.33 },
          note = {
              ru = "8 сработавших капканов (Sprung Trap) на земле и 6 шкур с Savannah Patriarch (15-16) "
                  .. "вокруг Vrang: львов здесь всего ~6, бейте каждого. Scytheclaw (16-18) бьют больно.",
              en = "8 Sprung Traps on the ground and 6 hides from the Savannah Patriarchs (15-16) around Vrang: there "
                  .. "are only ~6 of them, kill every one. Scytheclaws (16-18) hit hard.",
          } },
        { turnin = { 95494, 95507 }, accept = 95495, npc = 3682, at = { 1413, 43.80, 12.21 } }, -- WARN-OK: xp-unknown
        { turnin = 95495, accept = 95621, npc = 261366, at = { 1413, 42.02, 11.45 }, -- WARN-OK: xp-unknown
          note = {
              ru = "Walton на гребне рядом.",
              en = "Walton on the ridge next to Vrang.",
          } },
        { complete = 95621, npc = 262119, at = { 1413, 41.85, 15.45 },
          note = {
              ru = "На юг к разбитому каравану: Corporal Adamore и морпехи Кул-Тираса - приказы Бенедикта.",
              en = "South to the wrecked caravan: Corporal Adamore and the Kul Tiras marines - Benedict's Orders.",
          } },
        { turnin = 95621, accept = 95508, npc = 261366, at = { 1413, 42.02, 11.45 } }, -- WARN-OK: xp-unknown
        { complete = 95508, at = { 1413, 42.02, 11.45 },
          note = {
              ru = "Стойте у Walton (~1 мин разговора), затем убейте Terry Longdrink и морпехов.",
              en = "Stay with Walton (~1 min of talk), then kill Terry Longdrink and the marines.",
          } },
        { turnin = 95508, npc = 261366, at = { 1413, 42.02, 11.45 } }, -- WARN-OK: xp-unknown (Forever-new)
        ---------------------------------------------------------------------
        -- Samophlange, prowlers, Ignition, the Boulder Lode Mine (17)
        ---------------------------------------------------------------------
        { turnin = 894, accept = 900, object = 4141, at = { 1413, 52.40, 11.65 },
          note = {
              ru = "На восток к гоблинской хижине: пульт управления (Control Console).",
              en = "East to the goblin hut: the Control Console.",
          } },
        { complete = 900, object = { 4072, 61936, 61935 }, at = { 1413, 52.34, 11.46 },
          note = {
              ru = "Поверните три вентиля рядом с пультом.",
              en = "Turn the three valves next to the console.",
          } },
        { turnin = 900, accept = 901, object = 4141, at = { 1413, 52.40, 11.65 } },
        { complete = 901, npc = 3471, at = { 1413, 52.84, 10.39 },
          note = {
              ru = "Tinkerer Sniggles в хижине к северо-востоку - ключ от пульта.",
              en = "Tinkerer Sniggles in the hut to the north-east - the Console Key.",
          } },
        { turnin = 901, accept = 902, object = 4141, at = { 1413, 52.40, 11.65 } },
        { go = true, at = { 1413, 54.15, 14.95 }, radius = 30,
          note = {
              ru = "Логово львов к юго-востоку: добейте когти (903) и головы ящеров (869). Всё есть - "
                  .. "пропустите шаг.",
              en = "The lion den to the south-east: finish the claws (903) and the raptor heads (869). All done - "
                  .. "skip the step.",
          } },
        { accept = 858, npc = 3439, at = { 1413, 56.52, 7.45 },
          note = {
              ru = "Шреддер Wizzlecrank у лагеря Венчурной компании на севере.",
              en = "Wizzlecrank's Shredder by the Venture Co. camp to the north.",
          } },
        { complete = 858, npc = 3445, at = { 1413, 56.27, 8.58 },
          note = {
              ru = "Supervisor Lugwizzle (18) ходит по лагерю - ключ зажигания. Осторожно: редкий "
                  .. "Foreman Grills (19).",
              en = "Supervisor Lugwizzle (18) walks around the camp - the Ignition Key. Careful: the rare Foreman "
                  .. "Grills (19).",
          } },
        { turnin = 858, accept = 863, npc = 3439, at = { 1413, 56.52, 7.45 } },
        { complete = 863, at = { 1413, 55.79, 7.12 },
          note = {
              ru = "Сопроводите шреддер из лагеря: нападут наёмники и Overseer Glibby. Провал - "
                  .. "возьмите заново у шреддера.",
              en = "Escort the shredder out of the camp: mercenaries and Overseer Glibby attack. Failed - take it again "
                  .. "from the shredder.",
          } },
        -- level 16 = the Moonglade training right after (Swipe); merged with the mine objective so the grind hint
        -- sits where the Venture Co. mobs are (the validator reaches ~17.6 here)
        { complete = 896, level = 16, at = { 1413, 60.84, 3.99 },
          note = {
              ru = "На северо-восток к руднику: Venture Co. Enforcer / Overseer, пока не выпадет "
                  .. "изумруд «Кошачий глаз». Внутри Boss Copperplug (19). До телепорта нужен 16-й "
                  .. "уровень (обучение): не хватает - добейте Venture Co. здесь.",
              en = "North-east to the Boulder Lode Mine: Venture Co. Enforcers / Overseers until a Cats Eye Emerald "
                  .. "drops. Boss Copperplug (19) is inside. Level 16 is needed before the teleport (training): short "
                  .. "- kill more Venture Co. here.",
          } },
        ---------------------------------------------------------------------
        -- Moonglade: training at 16, hearth to the Crossroads (17-18)
        ---------------------------------------------------------------------
        { id = "sd04-train-16", train = true, npc = 12042, at = { 1450, 52.53, 40.57 },
          spells = {
              { ru = "Размах", en = "Swipe" },
              { ru = "Лунный огонь (ранг 3)", en = "Moonfire (Rank 3)" },
              { ru = "Омоложение (ранг 3)", en = "Rejuvenation (Rank 3)" },
              { ru = "Заклинания 14-го уровня, если нет", en = "Level 14 spells if missing" },
          },
          note = {
              ru = "«Телепортация: Лунная поляна» прямо у рудника. Loganaar: обучение 16-го уровня "
                  .. "(главное - «Размах»). Таланты: Звериный инстинкт (Feral Instinct).",
              en = "Cast Teleport: Moonglade right at the mine. Loganaar: level 16 training (Swipe matters most). Talents: "
                  .. "Feral Instinct.",
          } },
        { id = "sd04-hearth", hearth = "The Crossroads", at = { 1413, 51.99, 29.89 },
          note = {
              ru = "Камень возвращения на Перекрёсток. Камень ещё не готов - летите из Ночной Гавани "
                  .. "(Bunthen Plainswind) в Громовой Утёс, оттуда на Перекрёсток.",
              en = "Hearth to the Crossroads. Hearthstone not ready - fly from Nighthaven (Bunthen Plainswind) to "
                  .. "Thunder Bluff, then on to the Crossroads.",
          } },
        ---------------------------------------------------------------------
        -- The Crossroads, fourth visit; Echeyakee (17)
        ---------------------------------------------------------------------
        { turnin = 869, accept = 3281, npc = 3464, at = { 1413, 51.93, 30.32 },
          note = {
              ru = "Нет 12 голов - добейте ящеров вокруг городка.",
              en = "Short of 12 heads - kill raptors around the town first.",
          } },
        { turnin = 867, accept = 875, npc = 3449, at = { 1413, 51.62, 30.90 } }, -- carried: 875 -> sd-05
        { accept = { 4921, 899 }, npc = 3432, at = { 1413, 51.95, 31.58 }, -- carried: 899 -> sd-05
          note = {
              ru = "Mankrik. «Одержимые ненавистью» (60 бивней) - в основном в следующем сегменте.",
              en = "Mankrik. Consumed by Hatred (60 tusks) is done mostly in the next segment.",
          } },
        { complete = 870, turnin = 870, accept = 877, npc = 3448, at = { 1413, 52.26, 31.93 } },
        { turnin = 903, accept = 881, npc = 3338, at = { 1413, 52.23, 31.01 },
          note = {
              ru = "Нет 7 когтей - добейте Savannah Prowler к северу от городка.",
              en = "Short of 7 claws - kill Savannah Prowlers north of the town first.",
          } },
        { complete = 881, npc = 3475, use = 10327, at = { 1413, 55.86, 17.19 },
          note = {
              ru = "На северо-восток к логову: протрубите в Рог Эчеяки - появится белый лев (16).",
              en = "North-east to the lair: blow the Horn of Echeyakee - the white lion (16) appears.",
          } },
        { turnin = 881, accept = 905, npc = 3338, at = { 1413, 52.23, 31.01 } },
        { id = "sd04-fly-ratchet", fly = "Ratchet", npc = 16227, at = { 1413, 63.08, 37.16 },
          note = {
              ru = "Летите в Кабестан.",
              en = "Fly to Ratchet.",
          } },
        ---------------------------------------------------------------------
        -- Ratchet, second visit (18)
        ---------------------------------------------------------------------
        { turnin = { 902, 863 }, accept = 1483, npc = 3442, at = { 1413, 62.98, 37.22 }, -- carried: 1483 -> sd-05
          note = {
              ru = "«Зиз Физзикс» сдадите в Когтистых горах (следующий сегмент). Подобрали бочонок "
                  .. "Чена позже - сдайте его Drohn рядом.",
              en = "Ziz Fizziks is handed in in Stonetalon (next segment). Picked up Chen's keg later - hand it to "
                  .. "Drohn next door.",
          } },
        { accept = { 865, 1069 }, npc = 3446, at = { 1413, 62.37, 37.62 } }, -- carried: 865, 1069 -> sd-05
        { turnin = 896, npc = 3453, at = { 1413, 63.35, 38.45 } },
        ---------------------------------------------------------------------
        -- South sweep: booty, silver, the Stagnant Oasis, Verog, nests (18)
        ---------------------------------------------------------------------
        { complete = 865, bg = true,
          note = {
              ru = "Попутно: рога с Sunscale Scytheclaw (16-18) на юге, особенно у гнёзд.",
              en = "On the way: horns from Sunscale Scytheclaws (16-18) in the south, mostly around the nests.",
          } },
        { complete = { [888] = { 1 } }, object = 3767, at = { 1413, 62.63, 49.63 },
          note = {
              ru = "На юг к пиратскому пляжу: «Лавка Дриззлика» - ящик с обувью.",
              en = "South to the pirate beach: Drizzlik's Emporium - the shipment of boots.",
          } },
        { complete = { [888] = { 2 } }, object = 3768, at = { 1413, 63.58, 49.25 },
          note = {
              ru = "Ящик «Хрупкое» рядом - линза.",
              en = "The Fragile crate next to it - the lens.",
          } },
        { complete = 3281, object = 147557, at = { 1413, 58.04, 53.87 },
          note = {
              ru = "На юго-запад: украденное серебро на земле среди ящеров.",
              en = "South-west: the Stolen Silver on the ground among the raptors.",
          } },
        { complete = 877, object = 3737, at = { 1413, 55.61, 42.75 },
          note = {
              ru = "На север к Застойному оазису: бурлящая расселина в воде. Грибы для спор - "
                  .. "по берегам.",
              en = "North to the Stagnant Oasis: the Bubbling Fissure in the water. Spore mushrooms along the "
                  .. "shores.",
          } },
        { complete = 851, npc = 3395, at = { 1413, 53.06, 41.74 },
          note = {
              ru = "Verog the Dervish (18) в лагере Kolkar западнее оазиса: бейте кентавров, пока он "
                  .. "не появится.",
              en = "Verog the Dervish (18) in the Kolkar camp west of the oasis: kill centaurs until he shows up.",
          } },
        { complete = 905, object = { 6907, 6908, 6906 }, at = { 1413, 52.36, 46.38 },
          note = {
              ru = "На юг к гнёздам: соберите 3 пера с Scytheclaw и кликните синее, жёлтое и красное гнёзда.",
              en = "South to the nests: loot 3 Sunscale Feathers from the Scytheclaws, then click the blue, yellow "
                  .. "and red nests.",
          } },
        { accept = 883, bg = true, use = 5099, at = { 1413, 47.19, 51.63 },
          note = {
              ru = "Только на 18+: Lakota'mani (22, серый кодо) бродит у 45-50, 49-53 - копыто начинает "
                  .. "задание. Не встретили - не ищите.",
              en = "Only at 18+: Lakota'mani (22, grey kodo) roams at 45-50, 49-53 - his hoof starts a quest. Not "
                  .. "seen - do not search.",
          } },
        { complete = 4921, npc = 10668, at = { 1413, 49.33, 50.32 },
          note = {
              ru = "Жена Манкрика: избитое тело среди кабанов Bristleback - поговорите с ним. Бивни "
                  .. "кабанов - для Mankrik.",
              en = "Mankrik's wife: the Beaten Corpse among the Bristleback quilboars - talk to it. Quilboar tusks "
                  .. "count for Mankrik.",
          } },
        ---------------------------------------------------------------------
        -- Camp Taurajo (18)
        ---------------------------------------------------------------------
        { id = "sd04-sethearth-taurajo", sethearth = "Camp Taurajo", npc = 7714, at = { 1413, 45.58, 59.04 },
          note = {
              ru = "На юго-запад в лагерь Таурахо. Трактирщица Byula: камень возвращения - Таурахо "
                  .. "(для следующего сегмента).",
              en = "South-west to Camp Taurajo. Innkeeper Byula: bind your hearthstone to Taurajo (for the next "
                  .. "segment).",
          } },
        { turnin = 883, optional = true, npc = 3387, at = { 1413, 44.86, 59.14 },
          note = {
              ru = "Только если взяли «Лакота'мани» - иначе пропустите шаг.",
              en = "Only if you have Lakota'mani - otherwise skip the step.",
          } },
        { accept = 878, npc = 3430, at = { 1413, 44.55, 59.26 } }, -- carried: 878 -> sd-05
        { id = "sd04-fp-taurajo", fp = "Camp Taurajo", npc = 10378, at = { 1413, 44.45, 59.15 },
          note = {
              ru = "Omusa Thunderhorn: откройте карту полётов (точка изучится).",
              en = "Omusa Thunderhorn: open the flight map (learns the point).",
          } },
        { id = "sd04-fly-xroads", fly = "The Crossroads", npc = 3615, at = { 1413, 51.50, 30.34 },
          note = {
              ru = "Летите на Перекрёсток.",
              en = "Fly to the Crossroads.",
          } },
        ---------------------------------------------------------------------
        -- The Crossroads, fifth visit (18)
        ---------------------------------------------------------------------
        { turnin = 848, npc = 3390, at = { 1413, 51.44, 30.15 },
          note = {
              ru = "Нет 4 спор - грибы есть у Забытых прудов и в оазисе Lushwater (по пути дальше).",
              en = "Short of 4 spores - mushrooms grow at the Forgotten Pools and the Lushwater Oasis (on the way on).",
          } },
        { turnin = 3281, npc = 3464, at = { 1413, 51.93, 30.32 } },
        { turnin = 905, accept = 3261, npc = 3338, at = { 1413, 52.23, 31.01 } }, -- carried: 3261 -> sd-05
        { turnin = 877, accept = 880, npc = 3448, at = { 1413, 52.26, 31.93 } }, -- carried: 880 -> sd-05
        { turnin = 4921, accept = 95774, npc = 3432, at = { 1413, 51.95, 31.58 } }, -- carried: 95774 -> sd-05
        ---------------------------------------------------------------------
        -- Regthar, Hezrul, the harpy lieutenants -> Stonetalon border (18)
        ---------------------------------------------------------------------
        { turnin = 851, accept = 852, npc = 3389, at = { 1413, 45.34, 28.41 } },
        { complete = 880, bg = true,
          note = {
              ru = "Попутно: панцири с Oasis Snapjaw (черепахи) в оазисе Lushwater.",
              en = "On the way: shells from Oasis Snapjaws (turtles) in the Lushwater Oasis.",
          } },
        { complete = 852, npc = 3396, at = { 1413, 46.04, 41.14 },
          note = {
              ru = "На юг к оазису Lushwater: Hezrul Bloodmark (19) с охраной ходит вокруг оазиса.",
              en = "South to the Lushwater Oasis: Hezrul Bloodmark (19) walks around the oasis with guards.",
          } },
        { turnin = { 852, 855 }, npc = 3389, at = { 1413, 45.34, 28.41 },
          note = {
              ru = "Нет 15 наручей - добейте кентавров у Regthar. «Контратаку!» (элитный вождь) "
                  .. "без группы не берите.",
              en = "Short of 15 bracers - kill centaurs around Regthar first. Do not take Counterattack! (elite "
                  .. "warlord) without a group.",
          } },
        { complete = 875, at = { 1413, 38.62, 14.69 },
          note = {
              ru = "На северо-запад: 6 колец с Witchwing Slayer (16-17) в западной части гнезда гарпий.",
              en = "North-west: 6 rings from Witchwing Slayers (16-17) in the western part of the harpy nest.",
          } },
        { turnin = 1061, optional = true, npc = 4049, at = { 1413, 35.26, 27.88 },
          note = {
              ru = "На юго-запад к входу в Когтистые горы: Seereth Stonebreak. Сдайте «Духов Когтистых гор», "
                  .. "если взяли их в Оргриммаре; нет - пропустите шаг.",
              en = "South-west to the entrance of Stonetalon Mountains: Seereth Stonebreak. Hand in The Spirits of "
                  .. "Stonetalon if you took it in Orgrimmar; otherwise skip the step.",
          } },
        { accept = 1062, npc = 4049, at = { 1413, 35.26, 27.88 }, -- carried: 1062 -> sd-05
          note = {
              ru = "Seereth Stonebreak: «Гоблины-захватчики».",
              en = "Seereth Stonebreak: Goblin Invaders.",
          } },
        { id = "sd04-end", accept = 6548, npc = 11857, at = { 1413, 35.19, 27.76 }, -- carried: 6548 -> sd-05
          note = {
              ru = "Makaba Flathoof рядом. Дальше - Когтистые горы (следующий сегмент).",
              en = "Makaba Flathoof next to him. Stonetalon Mountains follow (next segment).",
          } },
    },
})
