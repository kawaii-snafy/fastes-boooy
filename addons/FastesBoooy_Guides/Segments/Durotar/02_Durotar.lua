-- FastesBoooy_Guides / Segments / Durotar / 02_Durotar.lua
--
-- Segment dur-02-durotar: Valley of Trials exit -> Sen'jin Village -> Razor Hill -> Tiragarde Keep -> the east
-- coast and Kolkar Crag -> Sen'jin -> the Echo Isles -> hearth to Razor Hill -> the north (Rezlak, the Dustwind
-- harpies, the Spitelash naga, Thunder Ridge) -> Rhinag outside the Orgrimmar gate, levels 5-11, Orc and Troll.
-- Class-neutral: what exists because of a class is a shared insert of Classes/<Class>.lua on the anchors below.
-- Coordinates: Forever uiMap 1411 (Durotar) / 1454 (Orgrimmar), map percent, from tools/data/forever_db.lua
-- (NPC / object spawns; centroids of the objective mob / object spawns of the chosen area for complete steps).
--
-- Hub plan (Forever DB; docs/dev/research/startzones.md 5.1 steps 2-9, docs/dev/PLAN.md B.2):
--   Sen'jin 1 : 2161 Ukor on the way; 805 > 823 (Gadrin), 818 (Vornal), 96821 (Vel'rin Fang), 786 (Lar).
--   road      : 96821 spiders. Brakk's camp: 96652 > 96604 (campfire) > 96655.
--   Razor H. 1: 2161 + bind (Grosk), 96655 > 96825 + 815 (Torka), 791 (Furl), 96821 > 784 + 837 (Gar'Thok),
--               823 (Orgnil), 96822 (Turroc).
--   west/TK   : 96825 pears + 837 quilboar and scouts; Tiragarde Keep: 784, 791 scraps, 96822, chest 830.
--   Razor H. 2: 784 > 825, 830 > 831, 791, 96822, 96825.
--   coast     : 825 toolboxes and 818 makrura / crawlers along the east coast, south to Sen'jin.
--   Sen'jin 2 : 818; accept 808, 826 (Gadrin), 97225 (Vornal), 817 (Vel'rin Fang), 97223 (Xar'Ti).
--   Kolkar    : 786 attack plans, 99123 escort (Pal'juh). Sen'jin 3: 786, 99123.
--   Echo Isles: 808, 826 + Zalazane, 97225 idols, 817 tigers, 815 eggs, 97223 Bloodtalon Matriarch.
--   Sen'jin 4 : 808, 826, 97225, 817, 97223; hearth.
--   Razor H. 3: 815, 825, 99048 (Orgnil) > Heglan Shadeeye > 99049 (three objects) > 99051 + 806; level 10.
--   north     : 837 dustrunners and battleguards, 816 (Misha), Rezlak 834 > 835 + orb 97281 > 97282, 99051 naga,
--               crocolisks 816, Thunder Ridge 97282 + Fizzle 806, Misha 816, Rezlak 97282.
--   Orgrimmar : Rhinag 812, Kor'ghan 813 in the Cleft of Shadow, venomtail scorpids for 813 outside the gate.
-- Skipped: 96876 Ukor's Lost Pack (Ukorsbane, elite), 99052 (Aggor the Young, elite), 828 > 827 > 829 Skull Rock
--   (a second trip north and a second Orgrimmar visit), 5726 Hidden Enemies (Skull Rock), profession quests
--   96873 / 96874 / 96875, 96877 (Halikor, elite), 9263.
-- Postponed turn-ins (docs/dev/PLAN.md B.2), registered at the end of this file as race-scoped shared inserts:
--   after h12-borstan     dur02-korghan   turn in 813 at Kor'ghan (the sacs collected at dur02-end)
--   after h12-wisdom      dur02-nazgrel   turn in 831 at Nazgrel
--   before h12-zeppelin   dur02-rhinag    turn in 812 at Rhinag (timed: 45 minutes from the accept)
--   after h15-razor-hill  dur02-rh-return turn in 837 (Gar'Thok), 806 and 99051 (Orgnil) at level 14
-- 812 / 813 (deviation from docs/dev/PLAN.md B.2, see docs/dev/handover/p1-durotar.md): Kor'ghan offers 813 only
-- while 812 runs, and its Venomtail Poison Sacs are quest items, so they are looted with 813 in the log. The
-- segment therefore takes 812, walks in to Kor'ghan for 813, kills the scorpids between the gate and Rhinag, and
-- the city loop of h-12 hands both in. CONFIRM: the timer of 812 (45 minutes in Classic) and whether the sacs drop
-- without 813 (then the Kor'ghan trip could be dropped).
-- Hearthstone: bound in Razor Hill on the first visit; used from Sen'jin after the Echo Isles. Free from then on.
--
-- Hand-over to h-12-orgrimmar-tirisfal (docs/dev/PLAN.md B.2): outside the Orgrimmar gate between the gate and
-- Rhinag; 812 and 813 in the log, 813 complete; 831, 837, 806 and 99051 in the log (the last three complete);
-- hearthstone Razor Hill; no flight point (h-12 starts at Doras).
--
-- Anchors for class files (docs/dev/PLAN.md C.2; levels: tools/validate_routes.lua --levels and the hand-over
-- docs/dev/handover/p1-durotar.md):
--   dur02-senjin-1       last step of the first Sen'jin visit (Lar Prowltusk): mage trainer Un'Thuwa (56.3, 75.1)
--   dur02-rh-1           last step of the first Razor Hill visit (Turroc, next to the warrior, shaman, priest
--                        and warlock trainers): training at 6
--   dur02-rh-2           last step of the second Razor Hill visit (Turroc): training
--   dur02-senjin-3       last step of the Sen'jin visit after the Echo Isles (Xar'Ti), before the hearth: mage
--                        training at 8
--   dur02-lvl-10         generic trainer-hub gate level 10 in Razor Hill, after the 99049 turn-in
--   dur02-rh-3           Orgnil after the gate (accept 99051, 806): training at 10, level-10 class quests and breadcrumbs (hunter
--                        6062, warrior 1505, shaman 2983, rogue 1859, warlock 1506, priest 5654 / 5660)
--   dur02-thunder-ridge  Thunder Ridge kills (97282 lizards, Fizzle for 806): for a warrior who holds 1498
--   dur02-end            last step: the venomtail scorpids between the Orgrimmar gate and Rhinag
-- Razor Hill trainers: warrior Tarshaw 54.2,42.5, shaman Swart 54.4,42.6, priest Tai'jin 54.3,42.9, warlock
-- Dhugru 54.4,41.2 (demon trainer Kitha 54.7,41.5), hunter Thotar 51.9,43.5 (pet trainer Harruk 52.0,43.5), rogue
-- Kaplak 52.0,43.7. No mage trainer: Un'Thuwa in Sen'jin.
if not FastesBoooy.AddLibraryInsert then return end
local _, ns = ...

FastesBoooy.AddLibrarySegment({
    id = "dur-02-durotar",
    title = { ru = "5-11 Дуротар", en = "5-11 Durotar" },
    zone = "Durotar",
    levels = { 5, 11 },
    steps = {
        ------------------------------------------------------------------
        -- To Sen'jin Village (level 5)
        ------------------------------------------------------------------
        { id = "dur02-ukor", accept = 2161, npc = 6786, at = { 1411, 52.06, 68.31 },
          note = { ru = "Из долины по дороге на восток: Укор у дороги.",
                   en = "Out of the valley along the road east: Ukor by the road." } },
        { id = "dur02-gadrin", turnin = 805, accept = 823, npc = 3188, at = { 1411, 55.95, 74.72 },
          note = { ru = "Деревня Сен'джин на юго-востоке: Мастер Гадрин.",
                   en = "Sen'jin Village to the south-east: Master Gadrin." } },
        { id = "dur02-vornal", accept = 818, npc = 3304, at = { 1411, 55.94, 74.39 },
          note = { ru = "Мастер Ворнал рядом.", en = "Master Vornal next to him." } },
        { id = "dur02-velrin", accept = 96821, npc = 3194, at = { 1411, 55.96, 73.93 },
          note = { ru = "Вел'рин Клык рядом.", en = "Vel'rin Fang next to them." } },
        { id = "dur02-senjin-1", accept = 786, npc = 3140, at = { 1411, 54.44, 74.35 },
          note = { ru = "Лар Клык Бродяги у западного края деревни.",
                   en = "Lar Prowltusk on the west side of the village." } },

        ------------------------------------------------------------------
        -- North to Razor Hill (level 5-6)
        ------------------------------------------------------------------
        { id = "dur02-spiders", complete = 96821, at = { 1411, 52.3, 57.2 },
          note = { ru = "По дороге на север: по 6 тенистых ползунов и тенистых затаившихся (пауки у дороги).",
                   en = "North along the road: 6 Ridgeshade Creepers and 6 Ridgeshade Lurkers (spiders by the "
                       .. "road)." } },
        { id = "dur02-brakk", turnin = 96652, accept = 96604, npc = 265809, at = { 1411, 51.98, 47.27 },
          note = { ru = "Лагерь Бракка у дороги к югу от Колючего Холма.",
                   en = "Brakk's camp by the road south of Razor Hill." } },
        { id = "dur02-campfire", complete = 96604, object = 460003, at = { 1411, 52.09, 47.39 },
          note = { ru = "Сядьте у костра (/sit) и ждите около минуты, пока не появится бафф отдыха.",
                   en = "Sit at the campfire (/sit) and wait about a minute for the rest buff." } },
        { id = "dur02-brakk-2", turnin = 96604, accept = 96655, npc = 265809, at = { 1411, 51.98, 47.27 },
          note = { ru = "Бракк: следующее задание сдаётся повару в Колючем Холме.",
                   en = "Brakk: his next quest is turned in to the cook in Razor Hill." } },

        ------------------------------------------------------------------
        -- Razor Hill, first visit (level 6)
        ------------------------------------------------------------------
        -- Requirement and trainer-hub gate (docs/dev/PLAN.md B.8): 815 (Torka) and 837 (Gar'Thok) need level 6,
        -- and every class trains at 6 in Razor Hill. The base profile is at 6.10 here (0 kills), but about 1,900
        -- XP of the way are the estimated XP of 96821 and the camp quests: the gate is the guarantee.
        { id = "dur02-lvl-6", level = 6, at = { 1411, 52.3, 57.2 },
          note = { ru = "6-й уровень перед Колючим Холмом: он нужен для заданий Торки и Гар'Тока, и у тренеров новые "
                       .. "умения. Не хватает - пауки у дороги к югу.",
                   en = "Level 6 before Razor Hill: Torka's and Gar'Thok's quests need it, and the trainers have new "
                       .. "ranks. Short: the spiders by the road to the south." } },
        { id = "dur02-sethearth", turnin = 2161, sethearth = "Razor Hill", npc = 6928, at = { 1411, 51.51, 41.64 },
          note = { ru = "Трактирщик Гроск: сдайте посылку и сделайте таверну домом.",
                   en = "Innkeeper Grosk: turn in the package and make this inn your home." } },
        { id = "dur02-torka", complete = 96655, turnin = 96655, accept = { 96825, 815 }, npc = 3191,
          at = { 1411, 51.11, 42.45 },
          note = { ru = "Повар Торка у таверны: выучите кулинарию, сдайте задание и возьмите два новых "
                       .. "(яйца нужны с 6-го уровня).",
                   en = "Cook Torka by the inn: learn Cooking, turn in and take two new quests (the eggs need "
                       .. "level 6)." } },
        { id = "dur02-furl", accept = 791, npc = 3147, at = { 1411, 49.88, 40.39 },
          note = { ru = "Фурл Надменный в северо-западной части Колючего Холма.",
                   en = "Furl Scornbrow in the north-west part of Razor Hill." } },
        { id = "dur02-garthok", turnin = 96821, accept = { 784, 837 }, npc = 3139, at = { 1411, 51.95, 43.50 },
          note = { ru = "Гар'Ток у казармы (837 нужен 6-й уровень).",
                   en = "Gar'Thok by the barracks (837 needs level 6)." } },
        { id = "dur02-orgnil", turnin = 823, npc = 3142, at = { 1411, 52.24, 43.15 },
          note = { ru = "Огрнил Шрам Души рядом.", en = "Orgnil Soulscar next to him." } },
        { id = "dur02-rh-1", accept = 96822, npc = 266940, at = { 1411, 53.95, 42.59 },
          note = { ru = "Туррок у восточного края, рядом с тренерами.",
                   en = "Turroc on the east side, next to the trainers." } },

        ------------------------------------------------------------------
        -- West field and Tiragarde Keep (level 6-8)
        ------------------------------------------------------------------
        { id = "dur02-quilboar", complete = { 96825, [837] = { 1, 2 } }, at = { 1411, 47.3, 49.0 },
          note = { ru = "К юго-западу от Колючего Холма: 8 колючих груш на кустах и по 4 свинобраза Иглогривых и "
                       .. "разведчика Иглогривых.",
                   en = "South-west of Razor Hill: 8 Prickly Pear Fruits on the bushes and 4 Razormane Quilboar and "
                       .. "4 Razormane Scouts." } },
        { id = "dur02-tiragarde-bg", complete = 791, bg = true, at = { 1411, 57.7, 56.1 },
          note = { ru = "Попутно: обрывки парусины с матросов Кул-Тираса.",
                   en = "On the way: Canvas Scraps from the Kul Tiras Sailors." } },
        { id = "dur02-tiragarde", complete = { 784, 96822 }, at = { 1411, 58.6, 56.3 },
          note = { ru = "Крепость Тирагард: 10 матросов, 8 морпехов и лейтенант Бенедикт. Лук, топор и щит "
                       .. "налётчиков лежат на земле в крепости.",
                   en = "Tiragarde Keep: 10 sailors, 8 marines and Lieutenant Benedict. The Raider's Bow, Battleaxe "
                       .. "and Shield lie on the ground in the keep." } },
        { id = "dur02-chest", accept = 830, use = 4881, object = 3239, at = { 1411, 59.3, 57.6 },
          note = { ru = "Сундук Бенедикта в крепости: в нём старый конверт - начните задание.",
                   en = "Benedict's Chest in the keep: the Aged Envelope inside starts a quest." } },
        { id = "dur02-scraps", complete = 791, at = { 1411, 57.7, 56.1 },
          note = { ru = "Добейте 8 обрывков парусины.", en = "Finish the 8 Canvas Scraps." } },

        ------------------------------------------------------------------
        -- Razor Hill, second visit (level 8)
        ------------------------------------------------------------------
        { id = "dur02-garthok-2", turnin = { 784, 830 }, accept = { 825, 831 }, npc = 3139,
          at = { 1411, 51.95, 43.50 },
          note = { ru = "Гар'Ток: 831 сдаётся в Оргриммаре - держите его.",
                   en = "Gar'Thok: 831 is turned in in Orgrimmar - keep it." } },
        { id = "dur02-torka-2", turnin = 96825, npc = 3191, at = { 1411, 51.11, 42.45 } },
        { id = "dur02-furl-2", turnin = 791, npc = 3147, at = { 1411, 49.88, 40.39 } },
        { id = "dur02-rh-2", turnin = 96822, npc = 266940, at = { 1411, 53.95, 42.59 },
          note = { ru = "Туррок у тренеров.", en = "Turroc by the trainers." } },

        ------------------------------------------------------------------
        -- The east coast south to Sen'jin (level 8)
        ------------------------------------------------------------------
        { id = "dur02-coast-bg", complete = 818, bg = true, at = { 1411, 63.0, 52.0 },
          note = { ru = "Попутно вдоль берега: глаза макруры и слизь крабов.",
                   en = "On the way along the coast: Intact Makrura Eyes and Crawler Mucus." } },
        { id = "dur02-toolboxes", complete = 825, at = { 1411, 63.0, 52.0 },
          note = { ru = "Восточный берег за Тирагардом: 3 ящика с гномьими инструментами у воды.",
                   en = "The east coast past Tiragarde: 3 Gnomish Toolboxes by the water." } },
        { id = "dur02-coast", complete = 818, at = { 1411, 62.0, 66.0 },
          note = { ru = "Дальше на юг вдоль берега: 4 глаза макруры и 8 слизи крабов.",
                   en = "On south along the coast: 4 Intact Makrura Eyes and 8 Crawler Mucus." } },

        ------------------------------------------------------------------
        -- Sen'jin, Kolkar Crag (level 8-9)
        ------------------------------------------------------------------
        { id = "dur02-vornal-2", turnin = 818, accept = 97225, npc = 3304, at = { 1411, 55.94, 74.39 },
          note = { ru = "Сен'джин: Мастер Ворнал.", en = "Sen'jin: Master Vornal." } },
        { id = "dur02-gadrin-2", accept = { 808, 826 }, npc = 3188, at = { 1411, 55.95, 74.72 } },
        { id = "dur02-velrin-2", accept = 817, npc = 3194, at = { 1411, 55.96, 73.93 } },
        { id = "dur02-xarti", accept = 97223, npc = 7953, at = { 1411, 55.28, 75.49 },
          note = { ru = "Ксар'Ти, учитель верховой езды на ящерах.", en = "Xar'Ti, the raptor riding trainer." } },
        { id = "dur02-paljuh", accept = 99123, npc = 275811, at = { 1411, 46.30, 78.64 },
          note = { ru = "На запад к Утёсу Колкаров: Пал'джух у скал. Сопровождение начинается сразу.",
                   en = "West to Kolkar Crag: Pal'juh by the rocks. The escort starts right away." } },
        { id = "dur02-kolkar", complete = { 786, 99123 }, at = { 1411, 48.0, 79.2 },
          note = { ru = "Сопроводите Пал'джуха и заберите три плана атаки в лагере колкаров. Колкары стоят "
                       .. "группами - подтягивайте по одному.",
                   en = "Escort Pal'juh and take the three attack plans in the Kolkar camp. The Kolkar stand in "
                       .. "groups - pull them one by one." } },
        { id = "dur02-vornal-3", turnin = 99123, npc = 3304, at = { 1411, 55.94, 74.39 },
          note = { ru = "Обратно в Сен'джин: Мастер Ворнал.", en = "Back to Sen'jin: Master Vornal." } },
        { id = "dur02-lar", turnin = 786, npc = 3140, at = { 1411, 54.44, 74.35 } },

        ------------------------------------------------------------------
        -- The Echo Isles (level 9)
        ------------------------------------------------------------------
        { id = "dur02-isles-bg", complete = { 817, 815 }, bg = true, at = { 1411, 65.1, 80.0 },
          note = { ru = "Попутно на островах: шкуры дуротарских тигров и яйца хлестохвостов (кладки на земле).",
                   en = "On the way on the isles: Durotar Tiger Furs and Taillasher Eggs (clutches on the "
                       .. "ground)." } },
        { id = "dur02-matriarch", complete = 97223, at = { 1411, 68.8, 71.8 },
          note = { ru = "Северный остров: матриарх кровавых когтей.",
                   en = "The northern isle: the Bloodtalon Matriarch." } },
        { id = "dur02-isles", complete = { 808, 826, 97225 }, at = { 1411, 67.2, 85.2 },
          note = { ru = "Главный остров Эха: по 8 околдованных троллей и троллей-вудуистов, 8 забытых идолов лоа, "
                       .. "череп Миншины (у пленника) и голова Залазана (рядом с ним).",
                   en = "The main Echo Isle: 8 Hexed Trolls, 8 Voodoo Trolls, 8 Forgotten Loa Idols, Minshina's "
                       .. "Skull (at the prisoner) and Zalazane's Head (next to it)." } },
        { id = "dur02-isles-2", complete = { 817, 815 }, at = { 1411, 64.5, 84.0 },
          note = { ru = "Добейте 4 шкуры тигров и 3 яйца хлестохвостов.",
                   en = "Finish 4 Durotar Tiger Furs and 3 Taillasher Eggs." } },

        ------------------------------------------------------------------
        -- Sen'jin, then hearth (level 9-10)
        ------------------------------------------------------------------
        { id = "dur02-gadrin-3", turnin = { 808, 826, 97225 }, npc = 3188, at = { 1411, 55.95, 74.72 },
          note = { ru = "Сен'джин: Мастер Гадрин.", en = "Sen'jin: Master Gadrin." } },
        { id = "dur02-velrin-3", turnin = 817, npc = 3194, at = { 1411, 55.96, 73.93 } },
        { id = "dur02-senjin-3", turnin = 97223, npc = 7953, at = { 1411, 55.28, 75.49 },
          note = { ru = "Ксар'Ти. Здесь же тренер магов Ун'Тува.",
                   en = "Xar'Ti. The mage trainer Un'Thuwa is here too." } },
        { id = "dur02-hearth", hearth = "Razor Hill", at = { 1411, 51.51, 41.64 },
          note = { ru = "Камень возвращения в Колючий Холм.", en = "Hearth to Razor Hill." } },

        ------------------------------------------------------------------
        -- Razor Hill, third visit; Heglan Shadeeye (level 9-10)
        ------------------------------------------------------------------
        { id = "dur02-torka-3", turnin = 815, npc = 3191, at = { 1411, 51.11, 42.45 } },
        { id = "dur02-garthok-3", turnin = 825, npc = 3139, at = { 1411, 51.95, 43.50 } },
        -- Requirement gate (docs/dev/PLAN.md B.8): 99048 needs level 9 (base profile 9.66 here, 0 kills).
        { id = "dur02-lvl-9", level = 9, at = { 1411, 47.3, 49.0 },
          note = { ru = "9-й уровень: он нужен для задания Огрнила. Не хватает - Иглогривые к юго-западу от Колючего "
                       .. "Холма.",
                   en = "Level 9: Orgnil's quest needs it. Short: the Razormane south-west of Razor Hill." } },
        { id = "dur02-orgnil-2", accept = 99048, npc = 3142, at = { 1411, 52.24, 43.15 },
          note = { ru = "Огрнил: задание нужно 9-й уровень.", en = "Orgnil: the quest needs level 9." } },
        { id = "dur02-heglan", turnin = 99048, accept = 99049, npc = 275657, at = { 1411, 58.60, 45.60 },
          note = { ru = "Хеглан Мрачный Глаз на востоке у берега.",
                   en = "Heglan Shadeeye to the east by the coast." } },
        { id = "dur02-dagger", complete = { [99049] = { 1 } }, object = 693674, at = { 1411, 58.85, 44.35 },
          note = { ru = "Рядом на берегу: брошенный кинжал, странный мусор и обломок оружия.",
                   en = "Close by on the shore: the Abandoned Dagger, the Strange Debris and the Weapon Piece." } },
        { id = "dur02-debris", complete = { [99049] = { 2 } }, object = 693670, at = { 1411, 60.08, 42.45 } },
        { id = "dur02-weapon-piece", complete = { [99049] = { 3 } }, object = 693669, at = { 1411, 60.10, 44.80 } },
        { id = "dur02-orgnil-3", turnin = 99049, npc = 3142, at = { 1411, 52.24, 43.15 },
          note = { ru = "Обратно к Огрнилу в Колючий Холм.", en = "Back to Orgnil in Razor Hill." } },
        -- Trainer-hub gate (docs/dev/PLAN.md B.8): every class trains at 10 in Razor Hill, and the level-10 class
        -- quests start there; this is the only Razor Hill visit before level 14. It stands after the 99049
        -- turn-in, so only the XP still missing after it is ground. The quests of dur02-rh-3 (same NPC) are taken
        -- by the automation at the turn-in; the gate still holds the guide until level 10.
        { id = "dur02-lvl-10", level = 10, at = { 1411, 52.24, 43.15 },
          note = { ru = "10-й уровень в Колючем Холме: у тренеров новые умения и классовые задания. Не хватает - "
                       .. "лагерь Иглогривых к западу (бегуны пыли, по пути на север), потом обратно к тренерам.",
                   en = "Level 10 in Razor Hill: new ranks and class quests at the trainers. Short: the Razormane "
                       .. "camp to the west (Dustrunners, on the way north), then back to the trainers." } },
        { id = "dur02-rh-3", accept = { 99051, 806 }, npc = 3142, at = { 1411, 52.24, 43.15 },
          note = { ru = "Огрнил: два задания на север. Тренеры классов - сейчас: следующий раз Колючий Холм будет "
                       .. "только на 14-м уровне.",
                   en = "Orgnil: two quests to the north. Class trainers now: the next time you pass Razor Hill "
                       .. "is at level 14." } },

        ------------------------------------------------------------------
        -- The north (level 10-11)
        ------------------------------------------------------------------
        { id = "dur02-dustrunners", complete = 837, at = { 1411, 42.6, 39.6 },
          note = { ru = "На северо-запад к лагерю Иглогривых: по 4 бегуна пыли и боевых стража.",
                   en = "North-west to the Razormane camp: 4 Razormane Dustrunners and 4 Battleguards." } },
        { id = "dur02-misha", accept = 816, npc = 3193, at = { 1411, 43.10, 30.24 },
          note = { ru = "Миша Тор'крен на север по дороге.",
                   en = "Misha Tor'kren, north along the road." } },
        { id = "dur02-rezlak", accept = 834, npc = 3293, at = { 1411, 46.37, 22.94 },
          note = { ru = "Резлак на северо-востоке.",
                   en = "Rezlak to the north-east." } },
        { id = "dur02-sacks", complete = 834, object = 3290, at = { 1411, 49.8, 24.5 },
          note = { ru = "5 украденных мешков с припасами к востоку от Резлака.",
                   en = "5 Stolen Supply Sacks east of Rezlak." } },
        { id = "dur02-rezlak-2", turnin = 834, accept = 835, npc = 3293, at = { 1411, 46.37, 22.94 } },
        { id = "dur02-harpies", complete = 835, at = { 1411, 52.4, 22.4 },
          note = { ru = "Гарпии дальше на восток: 12 дикарок и 8 ведьм бури Пыльного Ветра. С ведьм падает "
                       .. "Тусклая сфера бури - начните задание из неё.",
                   en = "The harpies further east: 12 Dustwind Savages and 8 Dustwind Storm Witches. The witches "
                       .. "drop a Dull Storm Orb - start the quest from it." } },
        { id = "dur02-orb", accept = 97281, use = 277661, at = { 1411, 52.4, 22.4 },
          note = { ru = "Тусклая сфера бури в сумке: начните задание.",
                   en = "The Dull Storm Orb in your bags: start the quest." } },
        { id = "dur02-naga", complete = 99051, at = { 1411, 58.2, 25.6 },
          note = { ru = "Берег на востоке: 9 плавников с наг Плетёного Хлыста.",
                   en = "The coast to the east: 9 Naga Spinefins from the Spitelash naga." } },
        { id = "dur02-rezlak-3", turnin = { 835, 97281 }, accept = 97282, npc = 3293, at = { 1411, 46.37, 22.94 },
          note = { ru = "Обратно к Резлаку.", en = "Back to Rezlak." } },
        { id = "dur02-crocs", complete = 816, at = { 1411, 35.7, 25.6 },
          note = { ru = "На запад к реке: жуткочелюстные кроколиски, амулет Крона падает не сразу.",
                   en = "West to the river: Dreadmaw Crocolisks; Kron's Amulet takes a few kills." } },
        { id = "dur02-thunder-ridge", complete = { 97282, 806 }, at = { 1411, 41.0, 26.6 },
          note = { ru = "Громовой хребет: 5 органов громовых ящеров (ящеры и громошкуры) и Физл Темный Шторм в "
                       .. "лагере Пылающего Клинка (коготь). Халикор - элитный: обходите.",
                   en = "Thunder Ridge: 5 Charged Thunder Lizard Organs (Thunder Lizards and Lightning Hides) and "
                       .. "Fizzle Darkstorm in the Burning Blade camp (his claw). Halikor is elite: stay clear." } },
        { id = "dur02-misha-2", turnin = 816, npc = 3193, at = { 1411, 43.10, 30.24 } },
        { id = "dur02-rezlak-4", turnin = 97282, npc = 3293, at = { 1411, 46.37, 22.94 } },

        ------------------------------------------------------------------
        -- Rhinag, Kor'ghan, the venomtail scorpids (level 11)
        ------------------------------------------------------------------
        -- CONFIRM (docs/dev/PLAN.md E.20): the timer of 812 (45 minutes in Classic) against the city loop of h-12.
        { id = "dur02-rhinag-accept", accept = 812, npc = 3190, at = { 1411, 41.54, 18.60 },
          note = { ru = "Ринаг у дороги к воротам Оргриммара. Задание на время (в классике 45 минут): лекарство "
                       .. "готовит Кор'ган в Оргриммаре, вы вернётесь сюда после городских дел.",
                   en = "Rhinag by the road to the Orgrimmar gate. A timed quest (45 minutes in Classic): Kor'ghan "
                       .. "in Orgrimmar makes the antidote, you come back here after the city errands." } },
        { id = "dur02-korghan-accept", accept = 813, npc = 3189, at = { 1454, 47.24, 53.58 },
          note = { ru = "В Оргриммар через ворота, в Расселину Тьмы: Кор'ган. Ему нужны 4 ядовитых мешочка "
                       .. "скорпидов.",
                   en = "Through the gate into Orgrimmar, the Cleft of Shadow: Kor'ghan. He needs 4 Venomtail "
                       .. "Poison Sacs." } },
        { id = "dur02-end", complete = 813, at = { 1411, 42.6, 18.7 },
          note = { ru = "Обратно за ворота: скорпиды-ядохвосты между воротами и Ринагом, 4 мешочка. Потом снова в "
                       .. "город - мешочки сдаются Кор'гану по пути.",
                   en = "Back out of the gate: the Venomtail Scorpids between the gate and Rhinag, 4 sacs. Then "
                       .. "into the city again - the sacs go to Kor'ghan on the way." } },
    },
})

------------------------------------------------------------------
-- Postponed turn-ins on the shared path (docs/dev/PLAN.md B.2), Orc and Troll only
------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h12-borstan",
    race = { "Orc", "Troll" },
    steps = {
        { id = "dur02-korghan", turnin = 813, complete = 812, npc = 3189, at = { 1454, 47.24, 53.58 },
          note = { ru = "Расселина Тьмы рядом: Кор'ган - сдайте 4 мешочка, получите противоядие для Ринага.",
                   en = "The Cleft of Shadow close by: Kor'ghan - hand in the 4 sacs and get the antidote for "
                       .. "Rhinag." } },
    },
})

FastesBoooy.AddLibraryInsert({
    after = "h12-wisdom",
    race = { "Orc", "Troll" },
    steps = {
        { id = "dur02-nazgrel", turnin = 831, npc = 3230, at = { 1454, 32.30, 35.75 },
          note = { ru = "Назгрел у крепости Громмаш: приказ адмирала.",
                   en = "Nazgrel by Grommash Hold: the admiral's orders." } },
    },
})

FastesBoooy.AddLibraryInsert({
    before = "h12-zeppelin",
    race = { "Orc", "Troll" },
    steps = {
        -- CONFIRM (docs/dev/PLAN.md E.20): the 812 timer. If it runs short, hand the antidote in right after
        -- Kor'ghan and come back for the city quests.
        { id = "dur02-rhinag", turnin = 812, npc = 3190, at = { 1411, 41.54, 18.60 },
          note = { ru = "За воротами к юго-западу: Ринаг - отдайте противоядие (задание на время; если таймер кончается, "
                       .. "отнесите его сразу после Кор'гана).",
                   en = "Out of the gate to the south-west: Rhinag - give him the antidote (timed; if the timer runs "
                       .. "short, bring it right after Kor'ghan)." } },
    },
})

FastesBoooy.AddLibraryInsert({
    after = "h15-razor-hill",
    race = { "Orc", "Troll" },
    steps = {
        { id = "dur02-rh-return", turnin = { 837, 806, 99051 }, npc = { 3139, 3142 }, at = { 1411, 52.10, 43.30 },
          note = { ru = "Колючий Холм: сдайте Гар'Току и Огрнилу задания, взятые на 10-м уровне.",
                   en = "Razor Hill: turn in to Gar'Thok and Orgnil the quests you took at level 10." } },
    },
})

-- The start-zone announcement: Route.lua registers the Orc and Troll routes once this line has run.
ns.startZones = ns.startZones or {}
ns.startZones.Durotar = { "dur-01-valley-of-trials", "dur-02-durotar" }
