-- AdventureAtlas_Guides / Segments / Shared / 46_Tanaris_Feralas.lua
--
-- Segment "h-46-tanaris-feralas": levels 46-50, all races and classes.
-- Booty Bay -> boat -> Ratchet -> fly Freewind Post -> Shimmering Flats -> Gadgetzan (Tanaris: Sandsorrow Watch,
-- Wastewander camps, Steamwheedle Port, Lost Rigger Cove, then one big loop Waterspring Field -> Gahz'ridian ->
-- Dunemaul -> Thistleshrub Valley -> Noxious Lair, hearth, Hazzali hive) -> fly Freewind Post -> ride west into
-- Feralas -> Camp Mojache (five loops around the camp, the last one to the Forgotten Coast and the Northspring
-- harpies, hearth back).
-- Plan: research plan60.md section 4.9 / plan60.json segments[9] (anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1413 (The Barrens) / 1441 (Thousand Needles) / 1446 (Tanaris) / 1444 (Feralas), map
-- percent, from tools/data/forever_db.lua: NPC / object spawns for npc / object steps, centroids of the objective
-- mob / object spawns of the area used for complete steps (h46 tools: research scratch h46/cen.lua). Travel points:
-- Mirage Raceway and Whitereach Post are NPC spawns there (Wizzle Brassbolts 4453, Motega Firemane 10428); the
-- Feralas entry 88.9,41.2 is the road north of Thalanaar.
-- ruRU names in the notes: Wowhead Forever ruRU tooltips (nether.wowhead.com/forever/ru/tooltip/...).
--
-- Hub plan (Forever DB; no quest of the segment is limited to a race or class):
--   G1  : fp, hearth; 5863 (Andi Lynn); 243 > 379 + 1690 (Bilgewhizzle); 1707 (Luglunket); 2605 (Noggenfogger);
--         2781 + 2875 (Wanted Poster); 3362 (Tran'rek); 992 (Fizzledowser).
--   W   : Sandsorrow Watch water hole (992) > Fizzledowser 992 > 82.
--   E   : Wastewander north camp (1690, pouches 379/1707); Steamwheedle Port: 2872 > 2873 (Stoley), 8366, 3520,
--         8365; Lost Rigger Cove (8366, 8365, 2873, 2875; the book 81949; optional 2876 from a Pirate's Footlocker); Waterspring
--         Field (2781 Caliph, rest of the pouches); Steamwheedle Port turn-ins.
--   G2  : 1690 + 379 + 2781 > 1691; 1707; 654 from the power source (379 reward, 2 h timer).
--   S   : Waterspring Field (1691) -> Marvon (3161) -> Gahz'ridian -> Dunemaul (5863) -> Thistleshrub Valley (2605,
--         3362) -> Noxious Lair (82); 654 samples on the way; hearth.
--   G3  : 1691 + 654 > 864; 5863; 2605 > 2606; 3362; 2606 > 2641 (Sprinkle); 82 (Pestlezugg); 10 (Fizzledowser).
--   SE  : Marvon 3161; Hazzali hive (10; optional level 47 top-up); optional OOX-17/TN (351, beacon drop).
--   G4  : 10 > 110 > 113, optional Zul'Farrak block (2768, 3042, 2865; skipped by the next turn-in), 113 > 32.
--         Fly Freewind Post.
--   M1  : fp, hearth; 2987, 2975, 2973, 2862, 2822.
--   F1  : sprite darters (2973), Woodpaw north camp (2862), Gordunni Outpost (scroll 2978, 2975, 2987).
--   M2  : 2987; 2975 + 2978 > 2980 + 2979; 2973 > 2974; 2862 > 2863 (1 h timer).
--   F2  : Grimtotem Compound (2974), Woodpaw south camp (2863).
--   M3  : 2863 > 2902; 2974 > 2976.  F3: battle map 2902 > 2903.  M4: 2903 > 7730 + 7731.
--   F4  : Zukk'ash hive (7730, 7731), Gordunni south camp (2980, 2979), screecher spirits (3520), optional
--         OOX-22/FE (2766), Feral Scar Vale (2822).
--   M5  : 7730 + 7731 > 7732; 2822 > 7734; 2980 + 2979 > 3002; 3063 (+ optional 3062, elite).
--   F5  : Rage Scar Hold (7734), Zorbin (7003, 7721 on the Forgotten Coast), Northspring harpies (3063, level gate;
--         optional Edana 3062), hearth.  M6: 7734, (3062), 3121 (Uzer'i, for Orgrimmar), 3063.
-- Deviations from the plan (documented in the handoff):
--   * 654 Tanaris Field Sampling is a 2-hour timed quest: the plan carried it for the rest of the route (it would
--     fail); here it is done during the Tanaris loop S and turned in (+ 864 Return to Apothecary Zinge, carried to
--     the Undercity of h-50: Apothecary Zinge 5204 @1458 50.14,67.97).
--   * 7730 / 7731 were accepted and carried to the end of the route by the plan (never done); here they are done
--     (Zukk'ash hive, next to the Woodpaw camps) and turned in; 7732 Zukk'ash Report is carried to Orgrimmar (h-50:
--     Zilzibin Drumlore 7010, the same NPC as 32).
--   * 351 / 2766 / 2876 start from random drops: optional steps. 3062 Dark Heart (Edana Hatetalon is a level 50
--     ELITE): optional. Optional Zul'Farrak block (plan section 6) at the end of Tanaris.
--   * Order: Sandsorrow Watch (992 > 82) is done right after the first Gadgetzan visit so that the Noxious Lair can
--     close the big western loop; the hearthstone is bound in Gadgetzan and used from the Noxious Lair, then bound
--     in Camp Mojache and used from the Northspring harpies.
--   * 10 The Scrimshank Redemption is offered by Fizzledowser (not Pestlezugg, who takes 82).
--   * Densify pass (r3): added 81949 Legends of the Tidesages (Forever-new library book in Lost Rigger Cove, XP
--     unknown; turned in to Owen Thadd in the Undercity of h-50) and 3121 A Strange Request (Uzer'i, delivery to Neeru
--     Fireblade in the Orgrimmar of h-50; 3122+ not taken). Level gates lowered to what the next hubs need: the
--     optional Hazzali gate 48 -> 47 (top-up only), the end gate 49 + 96% -> 49 + 30% (the segment ends at ~49.4: the
--     Hinterlands quests are 47-51 and their elites come at the end of the zone; 4494 March of the Silithid, reqLevel
--     50, moved to the Orgrimmar visit of h-53).
-- Skipped: 2874 Deliver to MacKinley (Booty Bay), 648 / 2767 / 1560 escorts, 3122-3129 Uzer'i chain (needs a second
--   Feralas visit and the Hinterlands owlbeasts), 4120 (Felwood), 3380 (Sunken Temple chain), 2981 (breadcrumb from
--   Orgrimmar), 2770 Gahz'rilla (turned in at the Mirage Raceway, not passed again), 1878 / 7738 (repeatable), 81951
--   (library book at Jademir Lake among level 60-62 elites).
-- Library books (Forever-new, here 81949; h-50 / h-53 have the others): the book objects are loot containers, not
--   quest starters (Wowhead Forever object tooltips: "Container"; QuestieDB Forever traces: the book items looted from
--   them, the quests finished at Owen Thadd, never started at a book). The route loots the book here (collect step)
--   and Owen Thadd (211022, Undercity) offers and takes the quest when the book is in the bags (one step: accept +
--   complete + turnin).
-- Carried out: 32, 864 (Undercity), 2976, 3002, 3121, 7732 (Orgrimmar), item 220346 for 81949 (Undercity), 2641 (Hinterlands, Violet
--   Tragan), 3520 (back to Yeh'kinya, Steamwheedle Port, h-53), 1429 (from h-44, untouched: the Atal'ai Exile in
--   h-50). (592 is no longer carried: h-44 skips 591 / 592, Mai'Zoth is elite.)
-- XP (validator, from 46.01; Classic quest XP + objective kills; optional steps counted): Tanaris questing ends at
--   ~46.9, Feralas questing adds ~1.2 levels. The rest comes from the end gate at the Northspring harpies (to 49 +
--   30%, ~590 same-level kills; ~730 without the optional steps, without incidental kills / rested XP). The optional
--   Zul'Farrak block replaces part of the grind for grouped players.
-- Automation notes: transient steps (fp, sethearth) come before the quest steps of their hub; accepts at one NPC are
--   merged into one step; optional steps never sit before a non-bg step that a bg goal can finish early (the forward
--   limit would skip them). Water pouches (379 / 1707 count the same 10 pouches: collect 10), the 654 samples and the
--   screecher spirits are bg goals; pouches and spirits get a later non-bg finishing step, 654 only its turn-in (a
--   finishing step after the hearth would let the bg goal skip the hearth step).
if not AdventureAtlas.AddLibraryInsert then return end
AdventureAtlas.AddLibrarySegment({
    id = "h-46-tanaris-feralas",
    title = { ru = "46-50 Танарис и Фералас", en = "46-50 Tanaris and Feralas" },
    zone = "Tanaris",
    levels = { 46, 50 },
    steps = {
        ------------------------------------------------------------------
        -- Booty Bay -> Ratchet -> Freewind Post -> Gadgetzan (level 46)
        ------------------------------------------------------------------
        { id = "h46-ratchet-fm", go = true, radius = 15, npc = 16227, at = { 1413, 63.08, 37.16 },
          note = { ru = "Корабль из Пиратской Бухты (Гриззлоу на пристани) в Кабестан. Распорядитель полётов Брагок у "
                       .. "пристани.",
                   en = "Boat from Booty Bay (Grizzlowe on the pier) to Ratchet. Flight master Bragok by the docks." } },
        { id = "h46-fly-freewind", fly = "Freewind Post", npc = 4317, at = { 1441, 45.14, 49.11 },
          note = { ru = "Летите на Заставу Вольного Ветра (Тысяча Игл).",
                   en = "Fly to Freewind Post (Thousand Needles)." } },
        { id = "h46-shimmering-flats", go = true, radius = 60, at = { 1441, 78.14, 77.12 },
          note = { ru = "На лифте вниз и на юго-восток через Мерцающую равнину к гоночной трассе.",
                   en = "Take the lift down and ride south-east across the Shimmering Flats to the Mirage Raceway." } },
        { turnin = 1137, npc = 4454, at = { 1441, 78.06, 77.13 },
          note = { ru = "Физзл: «Новости для Физзла» (от Мартека).", en = "Fizzle: News for Fizzle (from Martek)." } },
        { accept = 1190, npc = 4630, at = { 1441, 80.18, 75.88 },
          note = { ru = "Поззик: «Держать темп» - Замек отвлечёт Риззла, а вы украдёте его чертежи.",
                   en = "Pozzik: Keeping Pace - Zamek distracts Rizzle while you steal his plans." } },
        { turnin = 1190, accept = 1194, object = 20805, at = { 1441, 77.21, 77.39 },
          note = { ru = "Сначала поговорите с Замеком (79.8,77.0): примите и сдайте «Отвлекающий маневр Замека» - он "
                       .. "убегает устраивать взрыв, Риззл бежит за ним. Пока его нет - чертежи Риззла (77.2,77.4): "
                       .. "сдайте «Держать темп», возьмите «Чертежи Риззла».",
                   en = "Talk to Zamek first (79.8,77.0): accept and complete Zamek's Distraction - he runs off to set "
                       .. "off a blast and Rizzle chases him. While Rizzle is away - Rizzle's Unguarded Plans "
                       .. "(77.2,77.4): turn in Keeping Pace, take Rizzle's Schematics." } },
        { turnin = 1194, npc = 4630, at = { 1441, 80.18, 75.88 },
          note = { ru = "Поззик: образец индуриевой руды. Продолжение не берите.",
                   en = "Pozzik: the Sample of Indurium Ore. Skip the follow-up." } },
        { id = "h-46-gadgetzan-arrive", fp = "Gadgetzan", npc = 7824, at = { 1446, 51.60, 25.44 },
          note = { ru = "По дороге на юг в Танарис, до Прибамбасска. Булкрек Десница Гнева у северных ворот: откройте "
                       .. "точку полёта.",
                   en = "South along the road into Tanaris to Gadgetzan. Bulkrek Ragefist by the north gate: learn the "
                       .. "flight point." } },
        { id = "h46-gadgetzan-hearth", sethearth = "Gadgetzan", npc = 7733, at = { 1446, 52.51, 27.91 },
          note = { ru = "Хозяин таверны Ворчунелло: привяжите камень (вернётесь им с запада Танариса).",
                   en = "Innkeeper Fizzgrimble: bind the hearthstone (you hearth back from western Tanaris)." } },
        { accept = 5863, npc = 11758, at = { 1446, 52.82, 27.40 },
          note = { ru = "Анди Линн: «Поселение Песчаного Молота».", en = "Andi Lynn: The Dunemaul Compound." } },
        { turnin = 243, accept = { 379, 1690 }, npc = 7407, at = { 1446, 52.46, 28.51 },
          note = { ru = "Главный инженер Чепухастер у водокачки: «Поход в пустыню»; «Утолить жажду» и «Расправа над "
                       .. "Скитальцами Пустыни».",
                   en = "Chief Engineer Bilgewhizzle at the water tower: Into the Field; Slake That Thirst and Wastewander "
                       .. "Justice." } },
        { accept = 1707, npc = 7408, at = { 1446, 52.49, 28.45 },
          note = { ru = "Оператор крана Тормозиллер рядом: «Награда за воду».",
                   en = "Spigot Operator Luglunket next to him: Water Pouch Bounty." } },
        { accept = 2605, npc = 7564, at = { 1446, 51.81, 28.66 },
          note = { ru = "Синь Гогельмогель: «Жаждущий гоблин».", en = "Marin Noggenfogger: The Thirsty Goblin." } },
        { accept = { 2781, 2875 }, object = 150075, at = { 1446, 51.83, 27.04 },
          note = { ru = "Плакат «Разыскивается»: Калиф Жало Скорпида и Андре Огнебородый.",
                   en = "Wanted Poster: Caliph Scorpidsting and Andre Firebeard." } },
        { accept = 3362, npc = 7876, at = { 1446, 51.57, 26.76 },
          note = { ru = "Тран'рек: «Долина Кактусов».", en = "Tran'rek: Thistleshrub Valley." } },
        { accept = 992, npc = 7724, at = { 1446, 50.21, 27.48 },
          note = { ru = "Старший геодезист Рудознатец у западных ворот: «Исследование воды».",
                   en = "Senior Surveyor Fizzledowser by the west gate: Gadgetzan Water Survey." } },

        ------------------------------------------------------------------
        -- Sandsorrow Watch and back (level 46)
        ------------------------------------------------------------------
        { complete = 992, use = 8584, at = { 1446, 39.00, 29.00 },
          note = { ru = "На запад к Заставе Скорбных Песков: используйте нетронутое устройство у пруда. Тролли "
                       .. "Песчаной Бури к северу (Зул'Фаррак) — элита, к ним не подходите.",
                   en = "West to Sandsorrow Watch: use the Untapped Dowsing Widget at the pond. The Sandfury trolls to "
                       .. "the north (Zul'Farrak) are elite: keep away." } },
        { turnin = 992, accept = 82, npc = 7724, at = { 1446, 50.21, 27.48 },
          note = { ru = "Рудознатец: «Исследование Ядовитого улья» (улей — в конце большой западной петли).",
                   en = "Fizzledowser: Noxious Lair Investigation (the lair ends the big western loop)." } },

        ------------------------------------------------------------------
        -- Wastewander camps, Steamwheedle Port, Lost Rigger Cove (level 46)
        ------------------------------------------------------------------
        { complete = { 379, 1707 }, collect = { [8483] = 10 }, bg = true, at = { 1446, 62.49, 28.35 },
          note = { ru = "Попутно: 10 бурдюков с водой с любых Скитальцев Пустыни (оба задания считают одни и те же "
                       .. "бурдюки: нужно 5 + 5).",
                   en = "On the way: 10 Wastewander Water Pouches from any Wastewander (both quests count the same "
                       .. "pouches: you need 5 + 5)." } },
        { id = "h-46-tanaris-field-loop", complete = 1690, at = { 1446, 62.49, 28.35 },
          note = { ru = "Лагерь Скитальцев Пустыни к востоку от города: по 10 бандитов и воров (40-42).",
                   en = "Wastewander camp east of town: 10 Bandits and 10 Thieves (40-42)." } },
        { id = "h-46-steamwheedle-port", turnin = 2872, accept = 2873, npc = 7881, at = { 1446, 67.11, 23.98 },
          note = { ru = "На северо-восток в Порт Картеля: Столи — «Долг Столи», «Посылка Столи».",
                   en = "North-east to Steamwheedle Port: Stoley - Stoley's Debt, Stoley's Shipment." } },
        { accept = 8366, npc = 7882, at = { 1446, 67.06, 23.89 },
          note = { ru = "Начальник отдела безопасности Чепухастер: «Покажи этим пиратам».",
                   en = "Security Chief Bilgewhizzle: Southsea Shakedown." } },
        { accept = 3520, npc = 8579, at = { 1446, 66.99, 22.36 },
          note = { ru = "Йе'кинья: «Духи крикунов» — это в Фераласе, сдача при следующем визите в Танарис.",
                   en = "Yeh'kinya: Screecher Spirits - done in Feralas, turned in on the next Tanaris visit." } },
        { accept = 8365, npc = 15165, at = { 1446, 66.56, 22.27 },
          note = { ru = "Отти Кутюри: «Пиратские шляпы».", en = "Haughty Modiste: Pirate Hats Ahoy!" } },
        { complete = { 8366, 8365, 2873, 2875 }, at = { 1446, 73.70, 46.40 },
          note = { ru = "Вдоль берега на юг в бухту пиратов Южных морей: по 10 пиратов, флибустьеров, "
                       .. "рабочих, висельников (44-45) и 20 шляп; краденый груз — ящики на земле (72,47); Андре "
                       .. "Огнебородый — в бухте (73,47).",
                   en = "South along the coast to Lost Rigger Cove: 10 of each Southsea Pirate, Freebooter, Dock Worker, "
                       .. "Swashbuckler (44-45) and 20 hats; the Stolen Cargo crates lie on the ground (72,47); Andre "
                       .. "Firebeard is in the cove (73,47)." } },
        { collect = { [220346] = 1 }, object = 441248, at = { 1446, 72.60, 47.80 },
          note = { ru = "В бухте же (72.6,47.8) лежит книга «Легенды о волнопевах» — заберите её (это контейнер: задание "
                       .. "у книги не берётся). Задание даст и сразу примет Оуэн Тэдд в Подгороде, когда книга в сумках "
                       .. "(следующий сегмент; новое задание Forever, опыт неизвестен).",
                   en = "In the cove (72.6,47.8) lies the book Legends of the Tidesages - loot it (a container: the quest "
                       .. "is not offered at the book). Owen Thadd in Undercity offers and takes the quest when the book "
                       .. "is in your bags (next segment; a Forever-new quest, XP unknown)." } },
        { complete = 2781, at = { 1446, 61.77, 38.17 },
          note = { ru = "На запад в южный лагерь Скитальцев: Калиф Жало Скорпида (46) в центре лагеря.",
                   en = "West to the southern Wastewander camp: Caliph Scorpidsting (46) in its middle." } },
        { complete = { 379, 1707 }, collect = { [8483] = 10 }, at = { 1446, 62.09, 37.89 },
          note = { ru = "Добейте 10 бурдюков здесь (разбойники, тёмные маги, убийцы). Сюда же вернётесь с «Ещё одной "
                       .. "расправой».",
                   en = "Finish the 10 pouches here (rogues, shadow mages, assassins). You return to this camp for More "
                       .. "Wastewander Justice." } },
        { turnin = 2873, npc = 7881, at = { 1446, 67.11, 23.98 },
          note = { ru = "Обратно в Порт Картеля: Столи. «Доставку МакКинли» не берите (ведёт в Пиратскую Бухту).",
                   en = "Back to Steamwheedle Port: Stoley. Skip Deliver to MacKinley (it leads to Booty Bay)." } },
        { accept = 2876, use = 9250, optional = true, at = { 1446, 67.06, 23.89 },
          note = { ru = "По желанию: с пиратов выпал «Пиратский сундучок» с «Корабельным расписанием» — кликните "
                       .. "расписание.",
                   en = "Optional: a pirate dropped a Pirate's Footlocker with a Ship Schedule - right-click the "
                       .. "schedule." } },
        { turnin = 2876, npc = 7882, optional = true, at = { 1446, 67.06, 23.89 },
          note = { ru = "По желанию: «Корабельное расписание» — начальнику Чепухастеру.",
                   en = "Optional: Ship Schedules - to Security Chief Bilgewhizzle." } },
        { turnin = { 2875, 8366 }, npc = 7882, at = { 1446, 67.06, 23.89 },
          note = { ru = "Начальник Чепухастер.", en = "Security Chief Bilgewhizzle." } },
        { turnin = 8365, npc = 15165, at = { 1446, 66.56, 22.27 },
          note = { ru = "Отти Кутюри.", en = "Haughty Modiste." } },

        ------------------------------------------------------------------
        -- Gadgetzan, second visit (level 47)
        ------------------------------------------------------------------
        { turnin = { 1690, 379, 2781 }, accept = 1691, npc = 7407, at = { 1446, 52.46, 28.51 },
          note = { ru = "Прибамбасск, Чепухастер: «Ещё одна расправа над Скитальцами Пустыни».",
                   en = "Gadgetzan, Bilgewhizzle: More Wastewander Justice." } },
        { turnin = 1707, npc = 7408, at = { 1446, 52.49, 28.45 },
          note = { ru = "Тормозиллер.", en = "Luglunket." } },
        { accept = 654, use = 8524, at = { 1446, 52.46, 28.51 },
          note = { ru = "Кликните «Источник питания, модель 4711-ФТЗ» (награда «Утолить жажду»): «Полевые испытания в "
                       .. "Танарисе». Таймер 2 ч — хватит на западную петлю.",
                   en = "Right-click the Model 4711-FTZ Power Source (Slake That Thirst reward): Tanaris Field Sampling. "
                       .. "2 h timer - enough for the western loop." } },

        ------------------------------------------------------------------
        -- Big loop: Waterspring Field -> Gahz'ridian -> Dunemaul -> Thistleshrub -> Noxious Lair (level 47)
        ------------------------------------------------------------------
        { complete = 654, bg = true, at = { 1446, 50.35, 47.79 },
          note = { ru = "Попутно: василиски, гиены и скорпиды роняют непроверенные препараты — кликайте их (нужно по 8 "
                       .. "приемлемых). Не хватит к возвращению — голодные гиены и скорпиды-охотники сразу за воротами "
                       .. "Прибамбасска.",
                   en = "On the way: basilisks, hyenas and scorpids drop Untested samples - right-click each one (8 "
                       .. "acceptable of each kind). Still short back in town: Starving Blisterpaws and Scorpid Hunters "
                       .. "are right outside the Gadgetzan gates." } },
        { complete = 1691, at = { 1446, 62.09, 37.89 },
          note = { ru = "Южный лагерь Скитальцев: 8 разбойников, 6 убийц, 10 тёмных магов (41-45).",
                   en = "Southern Wastewander camp: 8 Rogues, 6 Assassins, 10 Shadow Mages (41-45)." } },
        { id = "h-46-marvon-rivetseeker", accept = 3161, npc = 7771, at = { 1446, 52.71, 45.92 },
          note = { ru = "На юго-запад к Марвону Клепальщику: «Газ'ридианские украшения». Наденьте выданный шлем "
                       .. "«Обнаружитель газ'риллия».",
                   en = "South-west to Marvon Rivetseeker: Gahz'ridian. Put on the Gahz'ridian Detector helmet he gives "
                       .. "you." } },
        { complete = 3161, at = { 1446, 46.75, 54.10 },
          note = { ru = "Газ'ридиан к юго-западу: 30 украшений (шлем показывает их на мини-карте); гиен и василисков "
                       .. "здесь же бейте на препараты.",
                   en = "Gahz'ridian to the south-west: 30 ornaments (the helmet shows them on the minimap); the hyenas "
                       .. "and basilisks here give samples." } },
        { complete = 5863, at = { 1446, 39.98, 55.63 },
          note = { ru = "Поселение Песчаного Молота: 10 громил и 10 головорезов (46-48) и Гор'марок Опустошитель (49, "
                       .. "41.5,57.8).",
                   en = "Dunemaul Compound: 10 Brutes and 10 Enforcers (46-48) and Gor'marok the Ravager (49, "
                       .. "41.5,57.8)." } },
        { complete = { 2605, 3362 }, at = { 1446, 29.29, 65.70 },
          note = { ru = "Далеко на юго-запад, долина Кактусов: 8 бугристых шипошкуров и 8 корнеплетов (48-50); "
                       .. "насыщенная влагой железа — с собирателей росы (47-48).",
                   en = "Far south-west, Thistleshrub Valley: 8 Gnarled Thistleshrubs and 8 Rootshapers (48-50); the "
                       .. "Laden Dew Gland drops from the Dew Collectors (47-48)." } },
        { complete = 82, at = { 1446, 33.58, 44.23 },
          note = { ru = "На север к Ядовитому улью: 5 частей тел насекомых с силитидов Сентипаар у входа (47-50).",
                   en = "North to the Noxious Lair: 5 Centipaar Insect Parts from the silithids outside the hive "
                       .. "(47-50)." } },
        { id = "h47-tanaris-hearth", hearth = "Gadgetzan", at = { 1446, 52.51, 27.91 },
          note = { ru = "Камень возвращения в Прибамбасск.", en = "Hearth to Gadgetzan." } },

        ------------------------------------------------------------------
        -- Gadgetzan, third visit (level 47-48)
        ------------------------------------------------------------------
        { turnin = { 1691, 654 }, accept = 864, npc = 7407, at = { 1446, 52.46, 28.51 },
          note = { ru = "Чепухастер: «Возвращение к аптекарю Зинг» (Подгород, следующий сегмент).",
                   en = "Bilgewhizzle: Return to Apothecary Zinge (Undercity, next segment)." } },
        { turnin = 5863, npc = 11758, at = { 1446, 52.82, 27.40 },
          note = { ru = "Анди Линн.", en = "Andi Lynn." } },
        { turnin = 2605, accept = 2606, npc = 7564, at = { 1446, 51.81, 28.66 },
          note = { ru = "Гогельмогель: «Хороший вкус».", en = "Noggenfogger: In Good Taste." } },
        { turnin = 3362, npc = 7876, at = { 1446, 51.57, 26.76 },
          note = { ru = "Тран'рек.", en = "Tran'rek." } },
        { turnin = 2606, accept = 2641, npc = 7583, at = { 1446, 51.06, 26.87 },
          note = { ru = "Поливалка: «Маленький секрет Поливалки» (фиалковый траган — во Внутренних землях, следующий "
                       .. "сегмент).",
                   en = "Sprinkle: Sprinkle's Secret Ingredient (the Violet Tragan grows in the Hinterlands, next "
                       .. "segment)." } },
        { turnin = 82, npc = 5594, at = { 1446, 50.89, 26.96 },
          note = { ru = "Алхимик Пестычинс: части насекомых.", en = "Alchemist Pestlezugg: the insect parts." } },
        { accept = 10, npc = 7724, at = { 1446, 50.21, 27.48 },
          note = { ru = "Рудознатец: «Спасение Холстомера».",
                   en = "Fizzledowser: The Scrimshank Redemption." } },

        ------------------------------------------------------------------
        -- South: Marvon, Hazzali hive, OOX-17/TN (level 48)
        ------------------------------------------------------------------
        { turnin = 3161, npc = 7771, at = { 1446, 52.71, 45.92 },
          note = { ru = "На юг к Марвону: 30 украшений.", en = "South to Marvon: the 30 ornaments." } },
        { complete = 10, object = 144053, at = { 1446, 55.96, 71.17 },
          note = { ru = "Дальше на юг в улей Хаззали: обозревательное устройство Холстомера (56,71) среди ос (47-50).",
                   en = "On south into the Hazzali hive: Scrimshank's Surveying Gear (56,71) among the wasps (47-50)." } },
        -- level-grind: 29 / 28 kills in the normal run (druid / paladin), INFO up to 30 kills (no `ok`: a route that
        -- needs more here gets the WARN and a ceiling above 30 together with its reason)
        { id = "h48-tanaris-level-gate", level = 47, optional = true, at = { 1446, 54.95, 70.24 },
          note = { ru = "По желанию (без Зул'Фаррака): если до 47-го не хватает — добейте ос Хаззали (47-50, самый плотный "
                       .. "лагерь рядом). Больше здесь не гриндите: основной гринд — у гарпий Фераласа в конце сегмента.",
                   en = "Optional (no Zul'Farrak): if you are short of 47, top up on the Hazzali wasps (47-50, the densest "
                       .. "camp nearby). Do not grind more here: the main grind is at the Feralas harpies at the end of the "
                       .. "segment." } },
        { accept = 351, use = 8623, optional = true, at = { 1446, 60.23, 64.72 },
          note = { ru = "По желанию: с мобов Танариса выпал аварийный маяк КПХ-17/TN — кликните его.",
                   en = "Optional: an OOX-17/TN Distress Beacon dropped from a Tanaris mob - right-click it." } },
        { id = "h-46-homing-robot-oox", turnin = 351, npc = 7784, optional = true, at = { 1446, 60.23, 64.72 },
          note = { ru = "Робот КПХ-17/TN к северо-востоку от улья. Сопровождение «Спаси КПХ-17/TN!» не берите.",
                   en = "Homing Robot OOX-17/TN north-east of the hive. Skip its escort Rescue OOX-17/TN!" } },

        ------------------------------------------------------------------
        -- Gadgetzan, last visit (level 48)
        ------------------------------------------------------------------
        { turnin = 10, accept = 110, npc = 7724, at = { 1446, 50.21, 27.48 },
          note = { ru = "Обратно в Прибамбасск: Рудознатец.", en = "Back to Gadgetzan: Fizzledowser." } },
        { turnin = 110, accept = 113, npc = 5594, at = { 1446, 50.89, 26.96 },
          note = { ru = "Пестычинс.", en = "Pestlezugg." } },
        -- Optional group content: Zul'Farrak (44-54), quests of Gadgetzan.
        { id = "h48-zf-divino", accept = 2768, npc = 7407, optional = true, at = { 1446, 52.46, 28.51 },
          note = { ru = "По желанию, с группой — Зул'Фаррак (вход 38.7,20.1): Чепухастер — «Изыскательский стержень». "
                       .. "Без группы — сразу к Рудознатцу (эти шаги пропустятся сами).",
                   en = "Optional, with a group - Zul'Farrak (entrance 38.7,20.1): Bilgewhizzle - Divino-matic Rod. No "
                       .. "group: go straight on to Fizzledowser (these steps skip themselves)." } },
        { accept = 3042, npc = 7804, optional = true, at = { 1446, 51.41, 28.75 },
          note = { ru = "Трентон Молот Света: «Троллье месиво».", en = "Trenton Lighthammer: Troll Temper." } },
        { accept = 2865, npc = 7876, optional = true, at = { 1446, 51.57, 26.76 },
          note = { ru = "Тран'рек: «Панцири скарабеев».", en = "Tran'rek: Scarab Shells." } },
        { complete = { 2768, 3042, 2865 }, optional = true, at = { 1446, 38.70, 20.10 },
          note = { ru = "Зул'Фаррак: стержень у сержанта Блая (после боя на лестнице), 20 «Тролльего месива» с троллей, 5 "
                       .. "нерасколотых панцирей со скарабеев.",
                   en = "Zul'Farrak: the rod from Sergeant Bly (after the stairs event), 20 Troll Temper from the "
                       .. "trolls, 5 Uncracked Scarab Shells from the scarabs." } },
        { turnin = 2768, npc = 7407, optional = true, at = { 1446, 52.46, 28.51 },
          note = { ru = "Чепухастер.", en = "Bilgewhizzle." } },
        { turnin = 3042, npc = 7804, optional = true, at = { 1446, 51.41, 28.75 },
          note = { ru = "Трентон Молот Света.", en = "Trenton Lighthammer." } },
        { turnin = 2865, npc = 7876, optional = true, at = { 1446, 51.57, 26.76 },
          note = { ru = "Тран'рек.", en = "Tran'rek." } },
        { id = "h-48-gadgetzan-end", turnin = 113, accept = 32, npc = 7724, at = { 1446, 50.21, 27.48 },
          note = { ru = "Рудознатец: «Восхождение силитидов» (Оргриммар, следующий сегмент).",
                   en = "Fizzledowser: Rise of the Silithid (Orgrimmar, next segment)." } },

        ------------------------------------------------------------------
        -- Gadgetzan -> Freewind Post -> Camp Mojache (level 48)
        ------------------------------------------------------------------
        { id = "h-46-gadgetzan-flight-master", fly = "Freewind Post", npc = 4317, at = { 1441, 45.14, 49.11 },
          note = { ru = "Булкрек у северных ворот: летите на Заставу Вольного Ветра.",
                   en = "Bulkrek by the north gate: fly to Freewind Post." } },
        { id = "h48-whitereach", go = true, radius = 60, at = { 1441, 21.54, 32.35 },
          note = { ru = "На лифте вниз и на северо-запад через каньон к заставе Белого Плеса.",
                   en = "Take the lift down and ride north-west across the canyon to Whitereach Post (Horde)." } },
        { id = "h48-feralas-entry", go = true, radius = 60, at = { 1444, 88.90, 41.20 },
          note = { ru = "По дороге на запад в Фералас; Таланаар (часовые Альянса) объезжайте с севера.",
                   en = "West along the road into Feralas; pass north of Thalanaar (Alliance sentinels)." } },
        { id = "h-48-mojache-arrive", fp = "Camp Mojache", npc = 8020, at = { 1444, 75.45, 44.36 },
          note = { ru = "Лагерь Мохаче: Шин — откройте точку полёта.",
                   en = "Camp Mojache: Shyn - learn the flight point." } },
        { id = "h48-mojache-hearth", sethearth = "Camp Mojache", npc = 7737, at = { 1444, 74.80, 45.18 },
          note = { ru = "Хозяйка таверны Греула: привяжите камень.", en = "Innkeeper Greul: bind the hearthstone." } },
        { accept = 2987, npc = 8021, at = { 1444, 75.70, 44.31 },
          note = { ru = "Орвин Гиззмик: «Кобальт Гордунни».", en = "Orwin Gizzmick: Gordunni Cobalt." } },
        { accept = 2975, npc = 7777, at = { 1444, 75.80, 43.58 },
          note = { ru = "Рока Орхан: «Огры Фераласа».", en = "Rok Orhan: The Ogres of Feralas." } },
        { accept = 2973, npc = 4544, at = { 1444, 75.94, 42.74 },
          note = { ru = "Криг Головоруб: «Новый сверкающий плащ».", en = "Krueg Skullsplitter: A New Cloak's Sheen." } },
        { accept = 2862, npc = 7875, at = { 1444, 74.91, 42.46 },
          note = { ru = "Хадокен Быстрый Странник: «Война с племенем Древолапов».",
                   en = "Hadoken Swiftstrider: War on the Woodpaw." } },
        { accept = 2822, npc = 7854, at = { 1444, 74.43, 42.91 },
          note = { ru = "Джангор Быстрый Странник: «Знак качества» (шкуры — позже, в Долине Свирепого Утеса).",
                   en = "Jangdor Swiftstrider: The Mark of Quality (the hides come later, Feral Scar Vale)." } },

        ------------------------------------------------------------------
        -- Feralas loop 1: sprite darters, Woodpaw north, Gordunni Outpost (level 48)
        ------------------------------------------------------------------
        { id = "h-47-feralas-field-loop", complete = 2973, at = { 1444, 67.49, 47.28 },
          note = { ru = "К западу от лагеря: 10 радужных крыльев с летучих хамелеонов (43-45).",
                   en = "West of the camp: 10 Iridescent Sprite Darter Wings (43-45)." } },
        { complete = 2862, at = { 1444, 72.55, 37.72 },
          note = { ru = "На север, лагерь Древолапов: 10 грив (40-42).",
                   en = "North to the Woodpaw camp: 10 Woodpaw Gnoll Manes (40-42)." } },
        { accept = 2978, use = 9370, at = { 1444, 75.13, 29.73 },
          note = { ru = "Лагерь Гордунни на северо-востоке: поднимите свиток Гордунни с земли и кликните его.",
                   en = "Gordunni Outpost to the north-east: pick up a Gordunni Scroll from the ground and right-click "
                       .. "it." } },
        { complete = { 2975, 2987 }, at = { 1444, 76.39, 31.20 },
          note = { ru = "10 огров, 10 огров-магов, 5 громил (40-43); 12 кобальта из куч земли (77,33).",
                   en = "10 Ogres, 10 Ogre Mages, 5 Brutes (40-43); 12 Gordunni Cobalt from the dirt mounds (77,33)." } },

        ------------------------------------------------------------------
        -- Camp Mojache, second visit (level 48)
        ------------------------------------------------------------------
        { id = "h47-mojache-2987", turnin = 2987, npc = 8021, at = { 1444, 75.70, 44.31 },
          note = { ru = "Орвин.", en = "Orwin." } },
        { id = "h47-mojache-2975", turnin = { 2975, 2978 }, accept = { 2980, 2979 }, npc = 7777, at = { 1444, 75.80, 43.58 },
          note = { ru = "Рока Орхан: вторые «Огры Фераласа» и «Тёмный обряд».",
                   en = "Rok Orhan: The Ogres of Feralas (part 2) and Dark Ceremony." } },
        { id = "h47-mojache-2973", turnin = 2973, accept = 2974, npc = 4544, at = { 1444, 75.94, 42.74 },
          note = { ru = "Криг: «Зловещее открытие».", en = "Krueg: A Grim Discovery." } },
        { id = "h47-mojache-2862", turnin = 2862, accept = 2863, npc = 7875, at = { 1444, 74.91, 42.46 },
          note = { ru = "Хадокен: «Истребление вожаков» — таймер 1 ч.",
                   en = "Hadoken: Alpha Strike - 1 h timer." } },

        ------------------------------------------------------------------
        -- Feralas loop 2: Grimtotem Compound, Woodpaw south camp (level 48)
        ------------------------------------------------------------------
        { complete = 2974, at = { 1444, 67.85, 42.42 },
          note = { ru = "Лагерь Зловещего Тотема к западу: 20 рогов (41-44).",
                   en = "Grimtotem Compound to the west: 20 Grimtotem Horns (41-44)." } },
        { complete = 2863, at = { 1444, 69.74, 54.54 },
          note = { ru = "На юг к лагерям Древолапов: 5 вожаков стаи (43-44).",
                   en = "South to the Woodpaw camps: 5 Woodpaw Alphas (43-44)." } },
        { id = "h47-mojache-2863", turnin = 2863, accept = 2902, npc = 7875, at = { 1444, 74.91, 42.46 },
          note = { ru = "Хадокен: «Разведка планов Древолапов».", en = "Hadoken: Woodpaw Investigation." } },
        { id = "h47-mojache-2974", turnin = 2974, accept = 2976, npc = 4544, at = { 1444, 75.94, 42.74 },
          note = { ru = "Криг: второе «Зловещее открытие» (Оргриммар, следующий сегмент).",
                   en = "Krueg: A Grim Discovery, part 2 (Orgrimmar, next segment)." } },

        ------------------------------------------------------------------
        -- Feralas loop 3: battle map, Zukk'ash hive, Gordunni south, Feral Scar Vale (level 48-49)
        ------------------------------------------------------------------
        { id = "h-47-woodpaw-battle-map", turnin = 2902, accept = 2903, object = 142195, at = { 1444, 71.63, 55.92 },
          note = { ru = "Тактическая карта Древолапов в южном лагере: «Планы битвы».",
                   en = "Woodpaw Battle Map in the southern camp: The Battle Plans." } },
        { id = "h47-mojache-2903", turnin = 2903, accept = { 7730, 7731 }, npc = 7875, at = { 1444, 74.91, 42.46 },
          note = { ru = "Хадокен: «Вторжение улья Цуккаш» и «Жалохвост».",
                   en = "Hadoken: Zukk'ash Infestation and Stinglasher." } },
        { complete = { 7730, 7731 }, at = { 1444, 75.44, 63.15 },
          note = { ru = "На юг в Гудящую Бездну: 20 панцирей Цуккаш (44-46); Жалохвост (47) — у северного входа "
                       .. "(75.6,60.9).",
                   en = "South to the Zukk'ash hive: 20 Zukk'ash Carapaces (44-46); Stinglasher (47) is by the north "
                       .. "entrance (75.6,60.9)." } },
        { complete = 3520, bg = true, use = 10699, at = { 1444, 56.74, 51.54 },
          note = { ru = "Попутно: убейте дольного крикуна, используйте колючку Йе'кинья на трупе и кликните духа — 3 "
                       .. "раза.",
                   en = "On the way: kill a Vale Screecher, use Yeh'kinya's Bramble on the corpse and click the spirit - "
                       .. "3 times." } },
        { complete = { 2980, 2979 }, at = { 1444, 60.32, 65.51 },
          note = { ru = "На запад к лагерю Гордунни: 10 шаманов и 10 чернокнижников (юг лагеря), 5 извергов (север); "
                       .. "сфера — с магов-лордов (45-46, юг).",
                   en = "West to the Gordunni camp: 10 Shamans and 10 Warlocks (south end), 5 Maulers (north end); the "
                       .. "Gordunni Orb drops from the Mage-Lords (45-46, south)." } },
        { complete = 3520, use = 10699, at = { 1444, 57.50, 57.00 },
          note = { ru = "Духов крикунов меньше трёх? Дольные крикуны летают между лагерем Гордунни и Долиной Свирепого "
                       .. "Утеса (57,55 - 60,62).",
                   en = "Fewer than 3 spirits? Vale Screechers fly between the Gordunni camp and Feral Scar Vale (57,55 - "
                       .. "60,62)." } },
        { accept = 2766, use = 8705, optional = true, at = { 1444, 53.35, 55.70 },
          note = { ru = "По желанию: выпал аварийный маяк OOX-22/FE — кликните его.",
                   en = "Optional: an OOX-22/FE Distress Beacon dropped - right-click it." } },
        { turnin = 2766, npc = 7807, optional = true, at = { 1444, 53.35, 55.70 },
          note = { ru = "Робот OOX-22/FE в пещере у Долины Свирепого Утеса. Сопровождение не берите.",
                   en = "Homing Robot OOX-22/FE in the cave by Feral Scar Vale. Skip the escort." } },
        { complete = 2822, at = { 1444, 52.96, 58.04 },
          note = { ru = "Долина Свирепого Утеса: 10 толстых шкур йети (43-46).",
                   en = "Feral Scar Vale: 10 Thick Yeti Hides (43-46)." } },

        ------------------------------------------------------------------
        -- Camp Mojache, fifth visit (level 49)
        ------------------------------------------------------------------
        { id = "h47-mojache-7730", turnin = { 7730, 7731 }, accept = 7732, npc = 7875, at = { 1444, 74.91, 42.46 },
          note = { ru = "Обратно в лагерь, Хадокен: «Донесение об улье Цуккаш» (Оргриммар).",
                   en = "Back to camp, Hadoken: Zukk'ash Report (Orgrimmar)." } },
        { id = "h47-mojache-2822", turnin = 2822, accept = 7734, npc = 7854, at = { 1444, 74.43, 42.91 },
          note = { ru = "Джангор: «Борьба за качество».", en = "Jangdor: Improved Quality." } },
        { id = "h47-mojache-2980", turnin = { 2980, 2979 }, accept = 3002, npc = 7777, at = { 1444, 75.80, 43.58 },
          note = { ru = "Рока Орхан: «Сфера Гордунни» (Оргриммар).", en = "Rok Orhan: The Gordunni Orb (Orgrimmar)." } },
        { accept = 3063, npc = 7776, at = { 1444, 76.18, 43.83 },
          note = { ru = "Тало Терновое Копыто: «Месть стае Студеных Ключей».",
                   en = "Talo Thornhoof: Vengeance on the Northspring." } },
        { accept = 3062, npc = 7776, optional = true, at = { 1444, 76.18, 43.83 },
          note = { ru = "По желанию: «Тёмное сердце» — Эдана Коготь Ненависти элитная (50), соло только уверенно.",
                   en = "Optional: Dark Heart - Edana Hatetalon is an ELITE 50: solo only if you are confident." } },

        ------------------------------------------------------------------
        -- Feralas loop 5: Rage Scar Hold, Zorbin, Northspring harpies (level 49-50)
        ------------------------------------------------------------------
        { complete = 7734, at = { 1444, 53.95, 32.11 },
          note = { ru = "На северо-запад к пещере Бешеного оврага: 10 шкур йети (46-49).",
                   en = "North-west to Rage Scar Hold: 10 Rage Scar Yeti Hides (46-49)." } },
        { id = "h-47-zorbin-fandazzle", accept = { 7003, 7721 }, npc = 14637, at = { 1444, 44.81, 43.42 },
          note = { ru = "На юго-запад к причалу Забытого берега: Зорбин Дребезгун — «Ликвидация великанов» и «Энергия "
                       .. "для уменьшения».",
                   en = "South-west to the Forgotten Coast pier: Zorbin Fandazzle - Zapped Giants and Fuel for the "
                       .. "Zapping." } },
        { complete = { 7003, 7721 }, use = 18904, at = { 1444, 46.38, 52.18 },
          note = { ru = "Берег к югу: элитных странников (47-49) сначала уменьшите ультрасжимателем, потом бейте — 15 "
                       .. "остатков; 10 ядер с морских элементалей и валов (47-49).",
                   en = "The shore to the south: zap the elite striders (47-49) with the Ultra-Shrinker first, then kill "
                       .. "them - 15 residues; 10 cores from the Sea Elementals and Sea Sprays (47-49)." } },
        { turnin = { 7003, 7721 }, npc = 14637, at = { 1444, 44.81, 43.42 },
          note = { ru = "Зорбин.", en = "Zorbin." } },
        { complete = 3062, use = 9530, optional = true, at = { 1444, 40.55, 8.60 },
          note = { ru = "По желанию: рог Когтя Ненависти падает с гарпий; Эдана (элита 50) — на севере руин (40.5,8.6).",
                   en = "Optional: the Horn of Hatetalon drops from the harpies; Edana (elite 50) is at the north end of "
                       .. "the ruins (40.5,8.6)." } },
        { id = "h-46-tanaris-feralas-level-gate", complete = 3063, level = { 49, 0.30 },
          ok = { ["level-grind"] = 590 }, -- end-of-segment gate: 589 kills in the normal run
          at = { 1444, 39.31, 13.46 },
          note = { ru = "На север к руинам гарпий (элитных великанов на равнине объезжайте): по 4 гарпии Студеных Ключей "
                       .. "каждого вида. Бейте гарпий (48-50, стоят плотно — лучший опыт рядом) до 49-го + 30%: сдачи в "
                       .. "лагере дадут ~49.4 — хватит для Внутренних земель (элитные тролли Джинта'Алора 50-51 — к концу "
                       .. "зоны вы будете 50-го).",
                   en = "North to the harpy ruins (ride around the elite giants on the plain): 4 Northspring harpies of "
                       .. "each kind. Keep killing the harpies (48-50, dense: the best XP nearby) up to 49 + 30%: the camp "
                       .. "turn-ins make ~49.4 - enough for the Hinterlands (the Jintha'Alor elite trolls 50-51 come at the "
                       .. "end of the zone, you will be 50 by then)." } },
        { id = "h50-mojache-hearth", hearth = "Camp Mojache", at = { 1444, 74.80, 45.18 },
          note = { ru = "Камень возвращения в Лагерь Мохаче.", en = "Hearth to Camp Mojache." } },

        ------------------------------------------------------------------
        -- Camp Mojache, last visit (level 50)
        ------------------------------------------------------------------
        { id = "h49-mojache-7734", turnin = 7734, npc = 7854, at = { 1444, 74.43, 42.91 },
          note = { ru = "Джангор.", en = "Jangdor." } },
        { id = "h49-mojache-3062", turnin = 3062, npc = 7776, optional = true, at = { 1444, 76.18, 43.83 },
          note = { ru = "По желанию: «Тёмное сердце».", en = "Optional: Dark Heart." } },
        { accept = 3121, npc = 8115, at = { 1444, 74.42, 43.36 },
          note = { ru = "Рядом, знахарь Узер'и: «Странная просьба» (сушеная голова — Нииру Огненному Клинку в Оргриммаре, "
                       .. "следующий сегмент). Продолжение у Нииру не берите.",
                   en = "Next to him, Witch Doctor Uzer'i: A Strange Request (the shrunken head goes to Neeru Fireblade in "
                       .. "Orgrimmar, next segment). Do not take Neeru's follow-up." } },
        { id = "h-50-mojache-end", turnin = 3063, npc = 7776, at = { 1444, 76.18, 43.83 },
          note = { ru = "Тало. Дальше — полёт в Оргриммар (следующий сегмент).",
                   en = "Talo. Next: fly to Orgrimmar (next segment)." } },
    },
})
