-- FastesBoooy_Guides / Segments / Legacy / sd_05_Barrens_Stonetalon_Ashenvale.lua
-- Segment "sd-05-stonetalon-ashenvale": levels 18-22 (last segment of the route).
-- Stonetalon border (6548 + 1062 in the log) -> Camp Aparaje -> Makaba -> Grundig + Kaya -> Malaka'jin
-- (Xen'Zilla) -> Webwinder Path -> Sun Rock Retreat (flight point) -> Ziz Fizziks (Super Reaper, spider eggs,
-- Venture Co. loggers / operators) -> back south -> Xen'Zilla -> border turn-ins -> Teleport: Moonglade
-- (training at 18) -> hearth to Camp Taurajo -> Bristleback / Razormane loop -> Ishamuhale -> Ratchet -> fly to
-- the Crossroads -> fly to Camp Taurajo (Jorn chain) -> fly to Thunder Bluff (bind, Elder Rise, Zamah) ->
-- Teleport: Moonglade, Cat Form chain 98340 -> 98341 -> 98404 -> 98738 -> 98362 -> hearth to Thunder Bluff
-- (Cat Form, training at 20) -> fly to Sun Rock (Gaea seeds) -> optional Piznik -> Ziz -> Talondeep Path ->
-- Ashenvale (Va'xug, Zoram'gar, naga heads + optional Vorsha escort) -> level 22 -> Teleport: Moonglade (training
-- at 22).
-- Why this way: every Stonetalon turn-in that needs the Barrens border (6548, 6629, 6523, 1062) is done at the end
-- of the first Stonetalon loop, so the second loop starts by flight at Sun Rock instead of walking in again from
-- the Crossroads (the reference walks Crossroads -> Serena -> border -> Malaka'jin a second time). Cat Form comes
-- before the long Stonetalon -> Ashenvale run (Feline Swiftness + Cat Form = +30% speed).
-- Coordinates: Forever DB snapshot (tools/data/forever_db.lua): NPC / object spawns and centroids of the objective
-- mob / object spawns. Terrain points cross-checked with the reference: the Webwinder Path, the Sun Rock ramp, the
-- Thunder Bluff bridges, Spirit Rise, the Stormrage Barrow Dens entrance, the Talondeep Path and the Ashenvale
-- road west of Astranaar.
-- Skipped on purpose: 876 Serena -> 1060 Jin'Zil (a second trip to the north-west Barrens and the border, ~11 min
-- for 3.5k XP), 1068 (XT shredders, turn-in back at the border), 6421 / 6481 (Boulderslide Ravine: Broodmother
-- Valraxx, level 30 elite, in the cave; Goggeroc elite), 6284 (Besseleth, elite), 6381 (its Gaea Dirt Mounds
-- are in the Charred Vale), 216 / 6462 (level 24, off the path), 868 (Egg
-- Hunt, turn-in back at the Crossroads), 97250 (elite pillagers), 79007 (ends in Westfall), 4021 / 92706 / 97003
-- (elite or group), 1065 (Hillsbrad), 27 / 28 / 30 / 31 (Aquatic Form chain: Tauren-only in the DB), 264
-- (Silverpine), 3301 (Silverpine), 6382 / 874 (Splintertree, level 27).
if not FastesBoooy.AddLibraryInsert then return end
FastesBoooy.AddLibrarySegment({
    id = "sd-05-stonetalon-ashenvale",
    title = {
        ru = "18-22 Когтистые горы, Степи, облик кошки, Ясеневый лес",
        en = "18-22 Stonetalon, The Barrens, Cat Form, Ashenvale",
    },
    zone = "Stonetalon Mountains",
    levels = { 18, 22 },
    steps = {
        ---------------------------------------------------------------------
        -- Stonetalon south: Camp Aparaje, Grundig, Kaya (18-19)
        ---------------------------------------------------------------------
        { id = "sd05-start", complete = 6548, at = { 1442, 82.1, 87.5 },
          note = {
              ru = "Камень возвращения (Таурахо) понадобится только после Лунной поляны. На запад в Когтистые "
                  .. "горы к лагерю Апараже: 8 Grimtotem Ruffian и 6 Grimtotem Mercenary.",
              en = "The hearthstone (Taurajo) is only needed after Moonglade. West into Stonetalon to Camp Aparaje: "
                  .. "8 Grimtotem Ruffians and 6 Grimtotem Mercenaries.",
          } },
        { turnin = 6548, accept = 6629, npc = 11857, at = { 1413, 35.19, 27.76 },
          note = {
              ru = "Назад к Makaba на границе Степей.",
              en = "Back to Makaba on the Barrens border.",
          } },
        { complete = 6629, npc = 11858, at = { 1442, 73.65, 86.12 },
          note = {
              ru = "На запад к лагерю Grundig Darkcloud (18): 6 Grimtotem Brute вокруг (72.6, 86.3) и сам "
                  .. "Grundig. Убейте всех брутов ДО того, как возьмёте задание Kaya.",
              en = "West to Grundig Darkcloud's camp (18): 6 Grimtotem Brutes around it (72.6, 86.3) and Grundig "
                  .. "himself. Kill every Brute BEFORE you take Kaya's quest.",
          } },
        { accept = 6523, npc = 11856, at = { 1442, 73.48, 85.59 },
          note = {
              ru = "Kaya Flathoof рядом с ним. Сопровождение начнётся сразу.",
              en = "Kaya Flathoof right next to him. The escort starts at once.",
          } },
        { go = true, at = { 1442, 76.73, 90.85 }, radius = 20,
          note = {
              ru = "Идите рядом с Kaya к костру в лагере Апараже: там нападут три Grimtotem. Провал - "
                  .. "возьмите задание у Kaya снова.",
              en = "Stay close to Kaya up to the bonfire in Camp Aparaje: three Grimtotems ambush you there. Failed - "
                  .. "take the quest from Kaya again.",
          } },
        ---------------------------------------------------------------------
        -- Malaka'jin -> Webwinder Path -> Sun Rock Retreat (19)
        ---------------------------------------------------------------------
        { accept = 6461, npc = 12816, at = { 1442, 71.25, 95.02 },
          note = {
              ru = "Xen'Zilla в деревне троллей Малака'джин к юго-западу.",
              en = "Xen'Zilla in the troll village of Malaka'jin to the south-west.",
          } },
        { complete = { [6461] = { 1 } }, bg = true,
          note = {
              ru = "Попутно: 10 Deepmoss Creeper (16-17) на Тропе Паутинщика - сейчас и на обратном пути.",
              en = "On the way: 10 Deepmoss Creepers (16-17) along the Webwinder Path - now and on the way back.",
          } },
        { go = true, at = { 1442, 58.44, 75.90 }, radius = 40,
          note = {
              ru = "На северо-запад по Тропе Паутинщика.",
              en = "North-west along the Webwinder Path.",
          } },
        { go = true, at = { 1442, 51.40, 61.14 }, radius = 30,
          note = {
              ru = "На север к подъёму в Приют Солнечного Камня (вход с востока).",
              en = "North to the ramp up to Sun Rock Retreat (the way in is on the east side).",
          } },
        { id = "sd05-fp-sunrock", fp = "Sun Rock Retreat", npc = 4312, at = { 1442, 45.12, 59.84 },
          note = {
              ru = "Tharm: откройте карту полётов (точка изучится, она нужна позже). Продайте хлам и "
                  .. "почините снаряжение у Jayka в таверне.",
              en = "Tharm: open the flight map (learns the point, needed later). Sell junk and repair at Jayka in "
                  .. "the inn.",
          } },
        ---------------------------------------------------------------------
        -- Windshear Crag: Ziz Fizziks, eggs, loggers (19)
        ---------------------------------------------------------------------
        { turnin = 1483, accept = 1093, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = {
              ru = "На восток к лагерю гоблина Ziz Fizziks.",
              en = "East to Ziz Fizziks' camp.",
          } },
        { complete = { 1069, [6461] = { 2 } }, object = 19541, at = { 1442, 62.0, 61.0 },
          note = {
              ru = "Восточнее Ziz: 15 яиц Deepmoss у корней деревьев и 7 Deepmoss Venomspitter. Из "
                  .. "детёнышей может вылезти Deepmoss Matriarch (22). XT:9 (23) ходит у 64, 56.",
              en = "East of Ziz: 15 Deepmoss Eggs at the tree roots and 7 Deepmoss Venomspitters. Hatchlings can call "
                  .. "a Deepmoss Matriarch (22). XT:9 (23) patrols near 64, 56.",
          } },
        { complete = { 1062, 1093 }, at = { 1442, 67.8, 51.5 },
          note = {
              ru = "Утёс Ветрорезов на северо-востоке: 15 Venture Co. Logger и Venture Co. Operator "
                  .. "(19-20), пока не выпадут чертежи. XT:4 (23) - у 67, 47.",
              en = "Windshear Crag to the north-east: 15 Venture Co. Loggers and Venture Co. Operators (19-20) until "
                  .. "the blueprints drop. XT:4 (23) is near 67, 47.",
          } },
        { turnin = 1093, accept = 1094, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = {
              ru = "«Дальнейшие указания» сдадите в Кабестане.",
              en = "Further Instructions is handed in in Ratchet.",
          } },
        ---------------------------------------------------------------------
        -- Back south: Xen'Zilla, the border turn-ins (19)
        ---------------------------------------------------------------------
        { go = true, at = { 1442, 61.47, 81.51 }, radius = 40,
          note = {
              ru = "На юг вниз по Тропе Паутинщика (через 60.8, 71.8). Добейте Deepmoss Creeper.",
              en = "South down the Webwinder Path (via 60.8, 71.8). Finish the Deepmoss Creepers.",
          } },
        { turnin = 6461, npc = 12816, at = { 1442, 71.25, 95.02 },
          note = {
              ru = "Нет 10 Creeper - они есть у 64.9, 83.5 и 67.3, 87.7 по пути.",
              en = "Short of 10 Creepers - there are some at 64.9, 83.5 and 67.3, 87.7 on the way.",
          } },
        { complete = 6523, turnin = { 6629, 6523 }, accept = 6401, npc = 11857, at = { 1413, 35.19, 27.76 },
          note = {
              ru = "На восток к границе Степей: Makaba. «Kaya жива» сдадите в Приюте Солнечного Камня.",
              en = "East to the Barrens border: Makaba. Kaya's Alive is handed in at Sun Rock Retreat.",
          } },
        { turnin = 1062, accept = 1063, npc = 4049, at = { 1413, 35.26, 27.88 },
          note = {
              ru = "Seereth рядом. После сдачи подождите пару секунд - появится «Старая карга» (в Громовой "
                  .. "Утёс). «Машины-измельчители» не берите.",
              en = "Seereth next to him. Wait a few seconds after the turn-in for The Elder Crone (to Thunder Bluff). "
                  .. "Do not take Shredding Machines.",
          } },
        ---------------------------------------------------------------------
        -- Moonglade: training at 18, hearth to Camp Taurajo (19)
        ---------------------------------------------------------------------
        { id = "sd05-train-18", train = true, npc = 12042, at = { 1450, 52.53, 40.57 },
          spells = {
              { ru = "Трепка (ранг 2)", en = "Maul (Rank 2)" },
              { ru = "Волшебный огонь", en = "Faerie Fire" },
              { ru = "Гнев деревьев (ранг 2)", en = "Entangling Roots (Rank 2)" },
              { ru = "Хватка природы (ранг 2)", en = "Nature's Grasp (Rank 2)" },
              { ru = "Восстановление (ранг 2)", en = "Regrowth (Rank 2)" },
              { ru = "Спячка", en = "Hibernate" },
          },
          note = {
              ru = "«Телепортация: Лунная поляна» прямо у границы. Loganaar: обучение 18-го уровня "
                  .. "(главное - «Трепка» и «Волшебный огонь»). Таланты: Кошачья стремительность "
                  .. "(Feline Swiftness).",
              en = "Cast Teleport: Moonglade right at the border. Loganaar: level 18 training (Maul and Faerie Fire "
                  .. "matter most). Talents: Feline Swiftness.",
          } },
        { id = "sd05-hearth-taurajo", hearth = "Camp Taurajo", at = { 1413, 45.58, 59.04 },
          note = {
              ru = "Камень возвращения в лагерь Таурахо. Камень не готов - летите от Bunthen Plainswind в "
                  .. "Громовой Утёс, оттуда в Таурахо.",
              en = "Hearth to Camp Taurajo. Hearthstone not ready - fly from Bunthen Plainswind to Thunder Bluff, then "
                  .. "on to Taurajo.",
          } },
        ---------------------------------------------------------------------
        -- Camp Taurajo -> Bristleback / Razormane loop -> Ishamuhale (19-20)
        ---------------------------------------------------------------------
        { turnin = 3261, accept = 882, npc = 3387, at = { 1413, 44.86, 59.14 },
          note = {
              ru = "Jorn Skyseer. Есть копыто Лакота'мани - сдайте и его.",
              en = "Jorn Skyseer. Got the Hoof of Lakota'mani - hand it in too.",
          } },
        { complete = 821, bg = true,
          note = {
              ru = "Только с «Пустым бочонком Чена»: рог громового ящера с Stormsnout (47, 52).",
              en = "Only with Chen's Empty Keg: a Thunder Lizard Horn from a Stormsnout (47, 52).",
          } },
        { complete = { 878, 95774, 899 }, at = { 1413, 48.6, 52.7 },
          note = {
              ru = "На север к лагерям Bristleback: 6 Water Seeker, 12 Thornweaver, 12 Geomancer и "
                  .. "Razormane Raider (украшения Ольгры). Бивни (60) падают со всех кабанов и рейдеров. "
                  .. "Сохраните 1 Кровавый осколок. Лакота'мани (22, серый кодо) у 45-50, 49-53 - если "
                  .. "встретите, копыто начинает задание.",
              en = "North to the Bristleback camps: 6 Water Seekers, 12 Thornweavers, 12 Geomancers and the Razormane "
                  .. "Raiders (Olgra's Adornments). The 60 tusks drop from every quilboar and Raider. Keep 1 Blood "
                  .. "Shard. Lakota'mani (22, grey kodo) roams at 45-50, 49-53 - if you see him, his hoof starts a "
                  .. "quest.",
          } },
        { go = true, optional = true, at = { 1413, 55.6, 42.6 }, radius = 30,
          note = {
              ru = "Не хватает панцирей (8) - Застойный оазис: Oasis Snapjaw. Все есть - пропустите шаг.",
              en = "Short of the 8 shells - the Stagnant Oasis: Oasis Snapjaws. All done - skip the step.",
          } },
        { complete = 882, use = 10338, npc = 3257, at = { 1413, 59.80, 30.60 },
          note = {
              ru = "На северо-восток к сухому дереву. Убейте рядом Zhevra Charger (туша, 30 минут), "
                  .. "положите тушу у дерева - появится Ishamuhale (19).",
              en = "North-east to the dead tree. Kill a Zhevra Charger nearby (the carcass lasts 30 minutes), use the "
                  .. "carcass at the tree - Ishamuhale (19) appears.",
          } },
        ---------------------------------------------------------------------
        -- Ratchet (20)
        ---------------------------------------------------------------------
        { turnin = 888, npc = 3391, at = { 1413, 62.68, 36.23 },
          note = {
              ru = "На юго-восток в Кабестан: Gazlowe.",
              en = "South-east to Ratchet: Gazlowe.",
          } },
        { turnin = 1094, accept = 1095, npc = 3442, at = { 1413, 62.98, 37.22 },
          note = {
              ru = "Sputtervalve: новое письмо отнесёте Ziz во втором заходе в Когтистые горы.",
              en = "Sputtervalve: the new orders go back to Ziz on the second Stonetalon trip.",
          } },
        { turnin = { 865, 1069 }, npc = 3446, at = { 1413, 62.37, 37.62 },
          note = {
              ru = "Mebok. Есть «Пустой бочонок Чена» - сдайте его Drohn рядом.",
              en = "Mebok. Got Chen's Empty Keg - hand it to Drohn next door.",
          } },
        { turnin = 821, optional = true, npc = 3292, at = { 1413, 62.26, 38.39 },
          note = {
              ru = "Только если бочонок был - иначе пропустите шаг.",
              en = "Only if you had the keg - otherwise skip the step.",
          } },
        { id = "sd05-fly-xroads", fly = "The Crossroads", npc = 3615, at = { 1413, 51.50, 30.34 },
          note = {
              ru = "Bragok: летите на Перекрёсток.",
              en = "Bragok: fly to the Crossroads.",
          } },
        ---------------------------------------------------------------------
        -- The Crossroads (20-21)
        ---------------------------------------------------------------------
        { turnin = 875, npc = 3449, at = { 1413, 51.62, 30.90 },
          note = {
              ru = "Darsok на башне. «Серену Кровавое Перо» не берите.",
              en = "Darsok on the tower. Do not take Serena Bloodfeather.",
          } },
        { turnin = { 899, 95774 }, npc = 3432, at = { 1413, 51.95, 31.58 } },
        { turnin = 880, accept = 1489, npc = 3448, at = { 1413, 52.26, 31.93 },
          note = {
              ru = "Tonga. «Хамуул Рунический Тотем» - в Громовой Утёс; «Муру» не берите.",
              en = "Tonga. Hamuul Runetotem goes to Thunder Bluff; do not take Mura Runetotem.",
          } },
        { accept = 853, npc = 3390, at = { 1413, 51.44, 30.15 },
          note = {
              ru = "Helbrim: задание на время (45 мин) - сдадите в Громовом Утёсе минут через 25.",
              en = "Helbrim: a timed quest (45 min) - handed in in Thunder Bluff about 25 minutes from now.",
          } },
        { id = "sd05-fly-taurajo", fly = "Camp Taurajo", npc = 10378, at = { 1413, 44.45, 59.15 },
          note = {
              ru = "Devrak: летите в лагерь Таурахо.",
              en = "Devrak: fly to Camp Taurajo.",
          } },
        ---------------------------------------------------------------------
        -- Camp Taurajo: Mangletooth, Jorn's chain (20-21)
        ---------------------------------------------------------------------
        { turnin = 878, accept = 5052, npc = 3430, at = { 1413, 44.55, 59.26 },
          note = {
              ru = "Mangletooth в клетке.",
              en = "Mangletooth in the cage.",
          } },
        { complete = 5052, turnin = 5052, npc = 3430, at = { 1413, 44.55, 59.26 },
          note = {
              ru = "Отдайте Кровавый осколок. Лишние осколки - на усиления у него же.",
              en = "Hand over the Blood Shard. Spend spare shards on his buffs.",
          } },
        { turnin = 882, accept = 907, npc = 3387, at = { 1413, 44.86, 59.14 } },
        { accept = 884, bg = true, use = 5102, at = { 1413, 45.4, 62.8 },
          note = {
              ru = "Owatanka (24, громовой ящер) бродит у 44-49, 60-63: его шип начинает задание. "
                  .. "Не встретили - не ищите.",
              en = "Owatanka (24, a thunder lizard) roams at 44-49, 60-63: his tailspike starts a quest. Not seen - "
                  .. "do not search.",
          } },
        { complete = 907, at = { 1413, 46.9, 63.1 },
          note = {
              ru = "К юго-востоку от лагеря: Thunderhead (20-21) - 3 крови громового ящера.",
              en = "South-east of the camp: Thunderheads (20-21) for 3 Thunder Lizard Blood.",
          } },
        { turnin = 907, accept = 913, npc = 3387, at = { 1413, 44.86, 59.14 } },
        { complete = 913, at = { 1413, 47.33, 62.40 },
          note = {
              ru = "Там же: Thunderhawk Cloudscraper (20-22) - крылья.",
              en = "Same area: a Thunderhawk Cloudscraper (20-22) for its wings.",
          } },
        { turnin = 884, optional = true, npc = 3387, at = { 1413, 44.86, 59.14 },
          note = {
              ru = "Только если взяли «Оватанку».",
              en = "Only if you have Owatanka.",
          } },
        -- The level 20 gate (reqLevel of 98340) is merged into this turn-in, the last stop with mobs before Thunder
        -- Bluff; it anchors only once 913 is handed in and the player is 20. The validator reaches ~21.1 here.
        { id = "sd05-level-20", turnin = 913, level = 20, npc = 3387, at = { 1413, 44.86, 59.14 },
          note = {
              ru = "Следующие задания Jorn не берите. Облик кошки выдаётся только с 20-го уровня: не хватает - "
                  .. "добейте Thunderhead и Zhevra Courser вокруг лагеря (в Громовом Утёсе бить некого).",
              en = "Do not take Jorn's next quests. The Cat Form quest needs level 20: short - kill Thunderheads and "
                  .. "Zhevra Coursers around the camp (there is nothing to kill in Thunder Bluff).",
          } },
        { id = "sd05-fly-tb", fly = "Thunder Bluff", npc = 2995, at = { 1456, 47.00, 49.83 },
          note = {
              ru = "Omusa Thunderhorn: летите в Громовой Утёс.",
              en = "Omusa Thunderhorn: fly to Thunder Bluff.",
          } },
        ---------------------------------------------------------------------
        -- Thunder Bluff (21)
        ---------------------------------------------------------------------
        { id = "sd05-sethearth-tb", sethearth = "Thunder Bluff", npc = 6746, at = { 1456, 45.81, 64.71 },
          note = {
              ru = "Трактирщица Pala: камень возвращения - Громовой Утёс (вернётесь сюда из Лунной поляны).",
              en = "Innkeeper Pala: bind your hearthstone to Thunder Bluff (you hearth back here from Moonglade).",
          } },
        { go = true, at = { 1456, 68.47, 28.24 }, radius = 15,
          note = {
              ru = "По подвесному мосту с северо-восточного края центральной возвышенности (55.4, 35.6) на "
                  .. "Вершину Старейшин.",
              en = "Over the rope bridge from the north-east edge of the central mesa (55.4, 35.6) to Elder Rise.",
          } },
        { turnin = 1063, accept = 1064, npc = 4046, at = { 1456, 69.85, 30.91 },
          note = {
              ru = "Magatha Grimtotem сразу за мостом.",
              en = "Magatha Grimtotem right past the bridge.",
          } },
        { turnin = 1489, accept = 1490, npc = 5769, at = { 1456, 78.62, 28.56 } },
        { id = "sd05-cat-start", accept = 98340, npc = 3033, at = { 1456, 76.48, 27.22 },
          note = {
              ru = "Turak Runetotem: «Великий дух кошки». Учиться пока не нужно - после облика кошки. "
                  .. "Предложит ещё и «Урок» (A Lesson to Learn, водный облик; по базе только для тауренов) - "
                  .. "возьмите вручную: сдача у Dendrite, «Испытание озера» там же (~1000 опыта).",
              en = "Turak Runetotem: The Great Cat Spirit. No training yet - after Cat Form. If he also offers A Lesson "
                  .. "to Learn (Aquatic Form; Tauren-only in the DB), take it by hand: it ends at Dendrite and Trial of "
                  .. "the Lake is in Moonglade too (~1000 XP).",
          } },
        { turnin = 1490, npc = 5770, at = { 1456, 75.65, 31.61 },
          note = {
              ru = "Nara Wildmane. Следующее её задание не берите.",
              en = "Nara Wildmane. Do not take her next quest.",
          } },
        { go = true, at = { 1456, 28.51, 28.95 }, radius = 15,
          note = {
              ru = "Обратно по мостам через центр на Вершину Духов, к спуску в Пещеру Видений.",
              en = "Back over the bridges through the centre to Spirit Rise, to the way down into the Pools of "
                  .. "Vision.",
          } },
        { turnin = { 853, 1064 }, npc = 3419, at = { 1456, 22.81, 20.89 },
          note = {
              ru = "Zamah внизу в Пещере Видений. «Путь в Тарренову Мельницу» не берите.",
              en = "Zamah down in the Pools of Vision. Do not take Journey to Tarren Mill.",
          } },
        ---------------------------------------------------------------------
        -- Moonglade: the Cat Form chain (21)
        ---------------------------------------------------------------------
        { id = "sd05-cat-dendrite", turnin = 98340, accept = 98341, npc = 11802, at = { 1450, 56.21, 30.64 },
          note = {
              ru = "«Телепортация: Лунная поляна». Dendrite Starblaze на севере Ночной Гавани.",
              en = "Cast Teleport: Moonglade. Dendrite Starblaze in the north of Nighthaven.",
          } },
        { turnin = 98341, accept = 98404, npc = 272054, at = { 1450, 43.92, 73.44 },
          note = {
              ru = "На юг: Аватар Саэйлинан (дух кошки) у южного края поляны.",
              en = "South: the Avatar of Saeyleenan (the cat spirit) at the south end of the glade.",
          } },
        { go = true, at = { 1450, 72.15, 62.18 }, radius = 15,
          note = {
              ru = "На восток ко входу в Курганы Стражей Бури (Stormrage Barrow Dens).",
              en = "East to the entrance of the Stormrage Barrow Dens.",
          } },
        { complete = 98404, object = { 672821, 673094, 673093 }, at = { 1450, 74.0, 66.2 },
          note = {
              ru = "Вглубь пещеры и через мост: три реликвии у статуй кошек - Клык (72.4, 66.0), Безмолвная "
                  .. "тень (шар у статуи, 74.4, 65.4) и Коготь (ниша, 75.2, 67.2).",
              en = "Deep into the cave and over the bridge: three relics at the cat statues - the Fang (72.4, 66.0), "
                  .. "the Silent Shadow (the orb next to a statue, 74.4, 65.4) and the Claw (an alcove, 75.2, 67.2).",
          } },
        { turnin = 98404, accept = 98738, npc = 272054, at = { 1450, 43.92, 73.44 },
          note = {
              ru = "Обратно к Аватару.",
              en = "Back to the Avatar.",
          } },
        { turnin = 98738, accept = 98362, npc = 11802, at = { 1450, 56.21, 30.64 },
          note = {
              ru = "Снова «Телепортация: Лунная поляна» - быстрее, чем пешком. Dendrite.",
              en = "Cast Teleport: Moonglade again - faster than walking. Dendrite.",
          } },
        { id = "sd05-hearth-tb", hearth = "Thunder Bluff", at = { 1456, 45.81, 64.71 },
          note = {
              ru = "Камень возвращения в Громовой Утёс. Камень не готов - Bunthen Plainswind (44.3, 45.9) "
                  .. "летит в Громовой Утёс.",
              en = "Hearth to Thunder Bluff. Hearthstone not ready - Bunthen Plainswind (44.3, 45.9) flies to Thunder "
                  .. "Bluff.",
          } },
        { id = "sd05-catform", turnin = 98362, npc = 3033, at = { 1456, 76.48, 27.22 },
          note = {
              ru = "Через мост на Вершину Старейшин: Turak. Награда - облик кошки, «Цапнуть», «Разорвать» "
                  .. "и «Крадущийся зверь».",
              en = "Over the bridge to Elder Rise: Turak. The reward is Cat Form plus Claw, Rip and Prowl.",
          } },
        { id = "sd05-train-20", train = true, npc = 3033, at = { 1456, 76.48, 27.22 },
          spells = {
              { ru = "Полоснуть", en = "Shred" },
              { ru = "Знамение ясности", en = "Omen of Clarity" },
              { ru = "Звёздный огонь", en = "Starfire" },
              { ru = "Деморализующий рёв (ранг 2)", en = "Demoralizing Roar (Rank 2)" },
              { ru = "Целительное прикосновение (ранг 4)", en = "Healing Touch (Rank 4)" },
              { ru = "Знак дикой природы (ранг 3)", en = "Mark of the Wild (Rank 3)" },
              { ru = "Возрождение", en = "Rebirth" },
          },
          note = {
              ru = "Обучение 20-го уровня. «Цапнуть», «Разорвать» и «Крадущегося зверя» уже дал облик кошки "
                  .. "(98362); у тренера главное - «Полоснуть» и «Знамение ясности». Таланты: Звериная атака "
                  .. "(Feral Charge). Дальше бегайте в облике кошки.",
              en = "Level 20 training. Claw, Rip and Prowl come with Cat Form (98362); at the trainer Shred and Omen of "
                  .. "Clarity matter most. Talents: Feral Charge. Travel in Cat Form from now on.",
          } },
        { id = "sd05-fly-sunrock", fly = "Sun Rock Retreat", npc = 4312, at = { 1442, 45.12, 59.84 },
          note = {
              ru = "Обратно к Tal на башню: летите в Приют Солнечного Камня.",
              en = "Back to Tal on the tower: fly to Sun Rock Retreat.",
          } },
        ---------------------------------------------------------------------
        -- Stonetalon, second trip: Sun Rock, Piznik, Ziz, Talondeep Path (21)
        ---------------------------------------------------------------------
        { turnin = 6401, accept = 6301, npc = 11864, at = { 1442, 47.46, 58.38 },
          note = {
              ru = "Tammra Windfield на северном краю приюта.",
              en = "Tammra Windfield at the north end of the retreat.",
          } },
        { complete = 6301, at = { 1442, 48.8, 40.7 },
          note = {
              ru = "На север из приюта: 10 семян Геи (Gaea Seed) на земле у 46-52, 36-45. Бейте Pridewing "
                  .. "(21-24) по пути. Редкий Sorrow Wing (27, элита) - обходите.",
              en = "North out of the retreat: 10 Gaea Seeds on the ground at 46-52, 36-45. Kill the Pridewings "
                  .. "(21-24) on the way. Avoid the rare Sorrow Wing (27, elite).",
          } },
        { turnin = 6301, npc = 11864, at = { 1442, 47.46, 58.38 },
          note = {
              ru = "Назад к Tammra. «Новую жизнь» не берите.",
              en = "Back to Tammra. Do not take New Life.",
          } },
        { accept = 6562, npc = 11862, at = { 1442, 47.36, 64.25 },
          note = {
              ru = "Tsunaman (южная часть приюта): письмо в Зорамгар.",
              en = "Tsunaman (south end of the retreat): a message for Zoram'gar.",
          } },
        { accept = 1090, optional = true, npc = 4276, at = { 1442, 71.87, 60.00 },
          note = {
              ru = "По желанию (лучше вдвоём): мимо лагеря Ziz на восток в рудник Ветрорезов (вход у 73.8, "
                  .. "59.5), Piznik внутри. Сначала зачистите Windshear Overlord (21-22) вокруг него, потом 5 "
                  .. "минут защищайте его от трёх волн кобольдов - в облике медведя с «Размахом». Не уверены - "
                  .. "пропустите этот и два следующих шага.",
              en = "Optional (a pair is safer): east past Ziz's camp into the Windshear Mine (entrance at 73.8, 59.5), "
                  .. "Piznik is inside. Clear the Windshear Overlords (21-22) around him first, then protect him for "
                  .. "5 minutes from three waves of kobolds - in Bear Form with Swipe. Not confident - skip this step "
                  .. "and the next two.",
          } },
        { complete = 1090, turnin = 1090, accept = 1092, optional = true, npc = 4276, at = { 1442, 71.87, 60.00 },
          note = {
              ru = "После третьей волны Piznik отдаёт руду.",
              en = "After the third wave Piznik hands over the ore.",
          } },
        { turnin = 1092, optional = true, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = {
              ru = "Только если делали Piznik: руда - Ziz.",
              en = "Only if you did Piznik: the ore goes to Ziz.",
          } },
        { turnin = 1095, npc = 4201, at = { 1442, 58.99, 62.60 },
          note = {
              ru = "Ziz Fizziks. «Геренцо Гаечный Ключ» не берите.",
              en = "Ziz Fizziks. Do not take Gerenzo Wrenchwhistle.",
          } },
        { go = true, at = { 1442, 78.29, 42.51 }, radius = 30,
          note = {
              ru = "На северо-восток через Утёс Ветрорезов к Тропе Талондип (туннель в Ясеневый лес).",
              en = "North-east through Windshear Crag to the Talondeep Path (the tunnel to Ashenvale).",
          } },
        ---------------------------------------------------------------------
        -- Ashenvale: Va'xug Firefure (21)
        ---------------------------------------------------------------------
        { accept = 98251, npc = 267214, at = { 1440, 40.46, 61.42 },
          note = {
              ru = "Из туннеля на север: Va'xug Firefure.",
              en = "North out of the tunnel: Va'xug Firefure.",
          } },
        { complete = 98251, at = { 1440, 41.3, 64.9 },
          note = {
              ru = "Вокруг: 6 Shadowhorn Stag и 6 Ashenvale Bear (21-23). Осторожно: медведь Ursangous "
                  .. "(25) бродит рядом.",
              en = "Around him: 6 Shadowhorn Stags and 6 Ashenvale Bears (21-23). Careful: the bear Ursangous (25) "
                  .. "roams nearby.",
          } },
        { turnin = 98251, accept = 98252, npc = 267214, at = { 1440, 40.46, 61.42 } },
        { turnin = 98252, npc = 271181, at = { 1440, 38.27, 58.41 },
          note = {
              ru = "Око Килрогга летит за вами: идите на северо-запад к главной дороге и поговорите с ним там.",
              en = "The Eye of Kilrogg follows you: walk north-west to the main road and talk to it there.",
          } },
        ---------------------------------------------------------------------
        -- Zoram'gar Outpost, the Zoram Strand (21-22)
        ---------------------------------------------------------------------
        { go = true, at = { 1440, 34.14, 53.61 }, radius = 40,
          note = {
              ru = "На запад: обходите Астранаар с юга (стражи Альянса).",
              en = "West: pass Astranaar on its south side (Alliance guards).",
          } },
        { go = true, at = { 1440, 18.43, 32.94 }, radius = 40,
          note = {
              ru = "Через лес на северо-запад к побережью.",
              en = "North-west through the forest to the coast.",
          } },
        { id = "sd05-fp-zoramgar", fp = "Zoram'gar Outpost", npc = 11901, at = { 1440, 12.24, 33.80 },
          note = {
              ru = "Застава Зорамгар. Andruk: откройте карту полётов (точка изучится).",
              en = "Zoram'gar Outpost. Andruk: open the flight map (learns the point).",
          } },
        { turnin = 6562, npc = 12736, at = { 1440, 11.56, 34.29 },
          note = {
              ru = "Je'neu Sancrea. Задание в Непроглядную Пучину не берите.",
              en = "Je'neu Sancrea. Do not take the Blackfathom Deeps quest.",
          } },
        { accept = 6442, npc = 12719, at = { 1440, 11.69, 34.91 },
          note = {
              ru = "Marukai: головы наг.",
              en = "Marukai: the naga heads.",
          } },
        -- Vorsha (2300 XP, Elite / 2 players in WCLBox) is optional: the reference takes it solo for every class, its
        -- naga waves also drop heads for 6442, and the route ends with a naga grind anyway. Skipped -> its complete
        -- step (at the brazier, the quest's area trigger) is forwarded by the 6442 complete, its turn-in by the 6442
        -- turn-in.
        { accept = 6641, optional = true, npc = 12717, at = { 1440, 12.06, 34.63 },
          note = {
              ru = "По желанию: Muglash рядом - сопровождение к жаровне наг на берегу. Волны наг (их головы "
                  .. "идут в задание Marukai), затем Vorsha (бьёт очень больно - пусть Muglash возьмёт "
                  .. "её на себя, лечите его и себя). Не уверены - пропустите этот шаг.",
              en = "Optional: Muglash next to him - an escort to the naga brazier on the shore. Naga waves (their heads "
                  .. "count for Marukai's quest), then Vorsha (hits very hard - let Muglash take aggro, heal him and "
                  .. "yourself). Not confident - skip this step.",
          } },
        { complete = 6641, optional = true, at = { 1440, 9.59, 27.58 },
          note = {
              ru = "Только если взяли: с Muglash к жаровне наг на берегу - волны наг, затем Vorsha. Muglash погиб - "
                  .. "«Вперёд».",
              en = "Only if you took it: with Muglash to the naga brazier on the shore - naga waves, then Vorsha. "
                  .. "Muglash died - press Forward.",
          } },
        { complete = 6442, at = { 1440, 12.2, 24.3 },
          note = {
              ru = "На север вдоль Берега Зорам: 20 голов с наг Wrathtail (18-21). Севернее (у 7, 15) - "
                  .. "Myrmidon и Priestess посильнее. Редкая Lady Vespia (22).",
              en = "North along the Zoram Strand: 20 heads from the Wrathtail nagas (18-21). Further north (near 7, 15) "
                  .. "the Myrmidons and Priestesses hit harder. Rare: Lady Vespia (22).",
          } },
        { turnin = 6641, optional = true, npc = 12863, at = { 1440, 12.22, 34.22 },
          note = {
              ru = "Только если сопровождали Muglash: Warsong Runner в Зорамгаре.",
              en = "Only if you escorted Muglash: the Warsong Runner in Zoram'gar.",
          } },
        -- The level 22 gate is merged into the last turn-in, next to the naga grind. The validator reaches ~22.1 here
        -- with every optional step done; with none of them (Vorsha, Piznik, the random 883 / 884 / 821 drops,
        -- 93165, 97326, 1061) it needs ~9.5k XP of grind (~63 kills) at this step.
        { id = "sd05-level-22", turnin = 6442, level = 22, npc = 12719, at = { 1440, 11.69, 34.91 },
          note = {
              ru = "Цель маршрута - 22-й уровень (и обучение 22-го уровня). Не хватает - добивайте наг на "
                  .. "Берегу Зорам (больше всего опыта - Myrmidon и Priestess на севере). Сытость от "
                  .. "приготовленной еды даёт +5% опыта за убийства.",
              en = "The route's goal is level 22 (and the level 22 training). Short - keep killing nagas on the Zoram "
                  .. "Strand (the Myrmidons and Priestesses in the north give the most). Well Fed from cooked food "
                  .. "gives +5% kill XP.",
          } },
        { id = "sd05-train-22", train = true, npc = 12042, at = { 1450, 52.53, 40.57 },
          spells = {
              { ru = "Гнев (ранг 4)", en = "Wrath (Rank 4)" },
              { ru = "Лунный огонь (ранг 4)", en = "Moonfire (Rank 4)" },
              { ru = "Омоложение (ранг 4)", en = "Rejuvenation (Rank 4)" },
              { ru = "Умиротворение животного", en = "Soothe Animal" },
          },
          note = {
              ru = "«Телепортация: Лунная поляна». Loganaar: обучение 22-го уровня. Таланты: Дикая ярость "
                  .. "(Savage Fury). Конец маршрута 1-22.",
              en = "Cast Teleport: Moonglade. Loganaar: level 22 training. Talents: Savage Fury. End of the 1-22 "
                  .. "route.",
          } },
    },
})
