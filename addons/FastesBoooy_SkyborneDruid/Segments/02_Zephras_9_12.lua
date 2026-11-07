-- FastesBoooy_SkyborneDruid / Segments / 02_Zephras_9_12.lua
-- Segment "sd-02-zephras": Zephras Isle (uiMap 2521), levels 9-13, Horde (Windshaper) side.
-- Shen'dar -> glide down to the lowlands -> Valanaar (hearth, turn in 92579 + 93948, story to the
-- Skydocks) -> Windfield orchard (Aamelia chain) and the bandit hill -> Valanaar: training at 10 +
-- Bear Form chain (94006 Urs'endris -> 94638 Ur'endra) with Construct Parts, Fendaal's assassins
-- and crabs on the same loop -> north past Windsong Lake into Shadowwind Forest (Strange Hermit,
-- refugees, Nightclaw druids) -> hearth to Valanaar, turn-ins, training at 12 -> skycutter to
-- Skywatcher Plateau (Mulgore) and the two arrival quests.
-- Coordinates: Forever DB snapshot (tools/data/forever_db.lua): NPC / object spawns and centroids of
-- the objective mob / object spawns. Glide points (Walk on Air), the tower ramp, the basin exits of
-- Urs'endris and the skycutter berth are terrain points cross-checked with the reference.
-- Every Zephras quest is Forever-new, so its XP is unknown offline: the xp-unknown WARN on each
-- turn-in is expected (the validator estimates it).
-- Skipped on purpose: 93949 (Bugged), 92693 / 92703 (long follow role-play), the 11-13 Horde story
-- chain from 93746, 93746 itself, all Camping 101 profession quests.
FastesBoooy.AddSegment("horde-skyborne-druid", {
    id = "sd-02-zephras",
    title = {
        ru = "9-13 Остров Зефрас: Валанаар, облик медведя, Лес Теневетра",
        en = "9-13 Zephras Isle: Valanaar, Bear Form, Shadowwind Forest",
    },
    zone = "Zephras Isle",
    -- the validator ends this segment at ~12.9 (the reference calls its part "9-13" too)
    levels = { 9, 13 },
    steps = {
        ---------------------------------------------------------------------
        -- Shen'dar -> Valanaar (9-10)
        ---------------------------------------------------------------------
        { id = "sd02-start", go = true, at = { 2521, 49.40, 58.76 }, radius = 25,
          note = {
              ru = "Из Шен'дара на юго-восток к краю плато (~46.5, 52). Прыгайте и "
                  .. "планируйте «Шагом по воздуху» в низину к этой точке. На бегу "
                  .. "используйте «Небесное зрение».",
              en = "From Shen'dar go south-east to the plateau edge (~46.5, 52). Jump and glide with Walk on Air "
                  .. "down into the lowlands towards this point. Cast Skysight while running.",
          } },
        { accept = 93317, npc = 257006, at = { 2521, 60.64, 72.66 },
          note = {
              ru = "Бегите на восток в Валанаар (медведица Ur'endra у 54,65 нужна позже - "
                  .. "обойдите). Nyalah Brightfire на западном краю деревни.",
              en = "Run east to Valanaar (the bear Ur'endra around 54,65 is for later - go around her). "
                  .. "Nyalah Brightfire on the west side of the village.",
          } },
        { complete = 93317, bg = true,
          note = {
              ru = "Windsong Crawler (крабы) по всем низинам: мясо краба.",
              en = "Windsong Crawlers (crabs) all over the lowlands: crawler meat.",
          } },
        { id = "sd02-sethearth", sethearth = "Valanaar", npc = 255940, at = { 2521, 62.19, 72.61 },
          note = {
              ru = "Трактирщик Donaal Downbreeze: привяжите камень к Валанаару.",
              en = "Innkeeper Donaal Downbreeze: bind your hearthstone to Valanaar.",
          } },
        { accept = 92679, npc = 252448, at = { 2521, 62.08, 73.17 },
          note = {
              ru = "Alvarion Windfield на втором этаже таверны. Выслушайте его.",
              en = "Alvarion Windfield on the inn's upper floor. Listen to him.",
          } },
        { accept = 94484, npc = 252359, at = { 2521, 63.99, 75.08 } },
        { accept = { 94896, 94897 }, npc = 259012, at = { 2521, 66.04, 74.41 } },
        { turnin = 93948, npc = 252476, at = { 2521, 66.17, 76.51 }, -- WARN-OK: xp-unknown (Forever-new)
          note = {
              ru = "Talaanis Shadowsong наверху башни - поднимайтесь по спиральному пандусу.",
              en = "Talaanis Shadowsong is at the top of the tower - take the spiral ramp up.",
          } },
        { turnin = 92579, accept = 92700, npc = 252383, at = { 2521, 66.14, 76.67 }, -- WARN-OK: xp-unknown
          reward = { [92579] = 3 },
          note = {
              ru = "Valennia Stormfist рядом. Награда выбирается автоматически: 3-й предмет.",
              en = "Valennia Stormfist next to her. The reward is picked automatically: item 3.",
          } },
        { go = true, at = { 2521, 61.49, 76.89 }, radius = 25,
          note = {
              ru = "Прыгайте с башни на запад и планируйте «Шагом по воздуху» к Небесным докам.",
              en = "Jump off the tower westwards and glide with Walk on Air towards the Skydocks.",
          } },
        { turnin = 92700, accept = 93735, npc = 251968, at = { 2521, 59.15, 79.78 } }, -- WARN-OK: xp-unknown
        { accept = 93736, npc = 254344, at = { 2521, 58.13, 78.32 },
          note = {
              ru = "Endaria Mistgaze рядом с Ayessa.",
              en = "Endaria Mistgaze next to Ayessa.",
          } },
        { vendor = true, optional = true, npc = 271465, at = { 2521, 59.40, 75.73 },
          note = {
              ru = "По пути на север к Riaani: Falfaan Halfwind - Zephrali Greatstaff (8.48 DPS, ур. 9, ~22 с), "
                  .. "если оружие слабее 8.5 DPS и хватает денег. Иначе пропустите.",
              en = "On the way north to Riaani: Falfaan Halfwind - Zephrali Greatstaff (8.48 DPS, level 9, ~22s) if "
                  .. "your weapon is below 8.5 DPS and you can afford it. Otherwise skip.",
          } },
        { turnin = 93735, accept = 93737, complete = { [93737] = { 1 } }, npc = 256083, -- WARN-OK: xp-unknown
          at = { 2521, 59.06, 72.98 },
          note = {
              ru = "Riaani Nightwind на севере доков: сдайте, возьмите и поговорите с ней.",
              en = "Riaani Nightwind north of the docks: turn in, accept and talk to her.",
          } },
        ---------------------------------------------------------------------
        -- Windfield orchard (10-11)
        ---------------------------------------------------------------------
        { complete = 92679, turnin = 92679, accept = { 92682, 92684, 92683 }, npc = 252800, -- WARN-OK: xp-unknown
          at = { 2521, 46.70, 81.95 },
          note = {
              ru = "Прямо на юго-запад в сад Виндфилдов: Aamelia Windfield.",
              en = "Straight south-west to the Windfield orchard: Aamelia Windfield.",
          } },
        { complete = 92684, bg = true,
          note = {
              ru = "Ornery Galestrider повсюду в низинах: 7 вырезок.",
              en = "Ornery Galestriders all over the lowlands: 7 tenderloins.",
          } },
        { complete = 92683, bg = true, use = 253666,
          note = {
              ru = "Прихлопните Flutterfly «Мухобойкой» (сумка) и подберите пыльцу.",
              en = "Swat Flutterflies with the Flutterfly Swatter (bags) and pick up the dust.",
          } },
        { complete = 92682, at = { 2521, 47.3, 81.0 },
          note = {
              ru = "Вокруг Aamelia: 5 Hungry Bandit и 10 Ripe Stormapple под деревьями.",
              en = "Around Aamelia: 5 Hungry Bandits and 10 Ripe Stormapples under the trees.",
          } },
        { accept = 92698, npc = 250929, at = { 2521, 48.87, 78.25 },
          note = {
              ru = "Malfunctioning Cyclone Construct к северо-востоку от сада.",
              en = "Malfunctioning Cyclone Construct north-east of the orchard.",
          } },
        { complete = { 92683, 92684 }, at = { 2521, 50.3, 78.7 },
          note = {
              ru = "Доберите пыльцу и вырезки к востоку от сада.",
              en = "Finish the dust and tenderloins east of the orchard.",
          } },
        { turnin = { 92682, 92684, 92698, 92683 }, accept = 92685, npc = 252800, -- WARN-OK: xp-unknown
          at = { 2521, 46.70, 81.95 }, reward = { [92684] = 3 },
          note = {
              ru = "Награда за вырезки выбирается автоматически: 3-й предмет.",
              en = "The tenderloin reward is picked automatically: item 3.",
          } },
        { complete = { 92685, [93737] = { 4 } }, object = 616467, at = { 2521, 44.5, 74.5 },
          note = {
              ru = "Холм бандитов к северо-западу: маски с Bandit Highwayman (7, есть "
                  .. "невидимые) и Construct Parts на холме (ядро конструкта).",
              en = "Bandit hill to the north-west: masks from Bandit Highwaymen (7, some are stealthed) and "
                  .. "the Construct Parts on the hill (construct core).",
          } },
        -- The level 10 gate (reqLevel of 94006 and the level 10 training) is merged into this turn-in: the step
        -- anchors only once 92685 is handed in AND the player is 10 (the engine never anchors on a lone level
        -- step either), and the grind hint sits where the grinding happens. The validator reaches ~11 here.
        { id = "sd02-level-10", turnin = 92685, level = 10, npc = 252800, at = { 2521, 46.70, 81.95 }, -- WARN-OK: xp-unknown
          note = {
              ru = "С юго-восточного края холма (44.1, 76.2) спланируйте «Шагом по воздуху» "
                  .. "к саду. Следующее задание Aamelia (долгая сценка) не берите. Дальше нужен 10-й "
                  .. "уровень (облик медведя и обучение): не хватает - бейте галестрайдеров и крабов "
                  .. "по пути на восток.",
              en = "From the south-east edge of the hill (44.1, 76.2) glide with Walk on Air down to the orchard. "
                  .. "Do not take Aamelia's next quest (a long role-play). Level 10 is needed next (Bear Form quest "
                  .. "and training): not there yet - kill galestriders and crabs on the way east.",
          } },
        ---------------------------------------------------------------------
        -- Valanaar: training at 10, Bear Form chain (11)
        ---------------------------------------------------------------------
        { id = "sd02-train-10", train = true, npc = 252359, at = { 2521, 63.99, 75.08 },
          spells = {
              { ru = "Хватка природы", en = "Nature's Grasp" },
              { ru = "Омоложение (ранг 2)", en = "Rejuvenation (Rank 2)" },
              { ru = "Знак дикой природы (ранг 2)", en = "Mark of the Wild (Rank 2)" },
              { ru = "Лунный огонь (ранг 2)", en = "Moonfire (Rank 2)" },
              { ru = "Телепортация: Лунная поляна (если есть)", en = "Teleport: Moonglade (if offered)" },
          },
          note = {
              ru = "Обратно на восток в Валанаар к Lotheluum Starbreeze. Уровень 10: "
                  .. "всё из списка (+ Трепка/Рык, если уже доступны). Таланты: Свирепость "
                  .. "(Ferocity) 5/5 с 10 по 14.",
              en = "Back east to Valanaar, Lotheluum Starbreeze. Level 10: everything listed "
                  .. "(+ Maul / Growl if offered already). Talents: Ferocity 5/5 from 10 to 14.",
          } },
        { id = "sd02-bear-accept", accept = 94006, npc = 252359, at = { 2521, 63.99, 75.08 },
          note = {
              ru = "Классовое задание: облик медведя.",
              en = "Druid class quest: Bear Form.",
          } },
        { go = true, at = { 2521, 65.42, 71.47 }, radius = 20,
          note = {
              ru = "Из Валанаара на север.",
              en = "North out of Valanaar.",
          } },
        { go = true, at = { 2521, 69.01, 65.86 }, radius = 20,
          note = {
              ru = "На северо-восток к обрыву над водопадами, оттуда спланируйте "
                  .. "«Шагом по воздуху» вниз к Urs'endris.",
              en = "North-east to the cliff above the falls, then glide down to Urs'endris with Walk on Air.",
          } },
        { id = "sd02-bear-quest", turnin = 94006, accept = 94638, npc = 255853, -- WARN-OK: xp-unknown
          at = { 2521, 69.81, 61.71 },
          note = {
              ru = "Urs'endris, Великий дух медведя.",
              en = "Urs'endris, the Great Windborne Bear Spirit.",
          } },
        { go = true, at = { 2521, 59.59, 66.70 }, radius = 25,
          note = {
              ru = "Из котловины водопадов выход на запад.",
              en = "The way out of the falls basin is to the west.",
          } },
        { complete = 94638, npc = 258443, at = { 2521, 54.35, 65.53 },
          note = {
              ru = "Убейте Ur'endra (10 ур., медведица), бродит у 54,65.",
              en = "Kill Ur'endra (level 10 bear), she wanders around 54,65.",
          } },
        { complete = { [93737] = { 2 } }, object = 616468, at = { 2521, 52.07, 66.45 },
          note = {
              ru = "Construct Parts чуть западнее: кристаллизованная молния.",
              en = "Construct Parts just to the west: Crystallized Lightning.",
          } },
        { accept = 98512, npc = 273017, at = { 2521, 56.81, 61.11 },
          note = {
              ru = "Peacekeeper Fendaal Windstone к северо-востоку.",
              en = "Peacekeeper Fendaal Windstone to the north-east.",
          } },
        { complete = { 98512, 93317 }, at = { 2521, 55.5, 59.5 },
          note = {
              ru = "10 Al'Aketh Assassin вокруг (могут быть в невидимости) и крабы "
                  .. "на берегу к западу.",
              en = "10 Al'Aketh Assassins around (they can be stealthed) and the crabs on the shore to the west.",
          } },
        { turnin = 98512, npc = 273017, at = { 2521, 56.81, 61.11 } }, -- WARN-OK: xp-unknown (Forever-new)
        { go = true, at = { 2521, 60.25, 62.74 }, radius = 25,
          note = {
              ru = "На восток; с гребня спланируйте «Шагом по воздуху» к Urs'endris.",
              en = "East; glide from the ridge down to Urs'endris with Walk on Air.",
          } },
        { id = "sd02-bearform", turnin = 94638, npc = 255853, at = { 2521, 69.81, 61.71 }, -- WARN-OK: xp-unknown
          note = {
              ru = "Награда - облик медведя. Дальше деритесь в нём (Трепку выучите "
                  .. "у тренера при возвращении).",
              en = "The reward is Bear Form. Fight in it from now on (learn Maul at the trainer when you are back).",
          } },
        ---------------------------------------------------------------------
        -- North: Windsong Lake, Shadowwind Forest (11-12)
        ---------------------------------------------------------------------
        { go = true, at = { 2521, 59.41, 66.95 }, radius = 25,
          note = {
              ru = "Снова выход из котловины на запад.",
              en = "Leave the basin to the west again.",
          } },
        { go = true, at = { 2521, 58.92, 55.01 }, radius = 25,
          note = {
              ru = "На север (лагерь Al'Aketh восточнее - не заходите).",
              en = "North (the Al'Aketh camp is to the east - stay out of it).",
          } },
        { complete = { [93737] = { 3 } }, object = 616466, at = { 2521, 53.2, 50.2 },
          note = {
              ru = "Восточный берег озера: Construct Parts (зачарованный гирозефир).",
              en = "East shore of the lake: Construct Parts (Enchanted Gyrozephyr).",
          } },
        { accept = 93159, complete = 93159, turnin = 93159, npc = 251684, -- WARN-OK: xp-unknown
          at = { 2521, 53.96, 38.90 },
          note = {
              ru = "Strange Hermit на севере: пройдите все варианты его диалога.",
              en = "Strange Hermit to the north: go through all of his dialogue options.",
          } },
        { accept = { 93160, 93172 }, npc = 251684, at = { 2521, 53.96, 38.90 } },
        { complete = 93160, bg = true,
          note = {
              ru = "Zephyrseed Cone (шишки) на земле между отшельником и Elegael.",
              en = "Zephyrseed Cones on the ground between the Hermit and Elegael.",
          } },
        { complete = { 93172, 93736, 94896 }, bg = true,
          note = {
              ru = "На севере: 10 Wind Hollow (их эссенции) и 8 Abandoned Belongings на земле.",
              en = "To the north: 10 Wind Hollows (and their essences) and 8 Abandoned Belongings on the ground.",
          } },
        { complete = 94897, npc = 259013, at = { 2521, 57.05, 29.35 },
          note = {
              ru = "Resaan Nimbuswalker на северном краю: поговорите с ним (реликвия).",
              en = "Resaan Nimbuswalker at the north end: talk to him (the heirloom).",
          } },
        { complete = { 93172, 93736, 94896 }, at = { 2521, 58.2, 32.1 },
          note = {
              ru = "Доберите Wind Hollow, эссенции (не хватает - бейте ещё) и вещи беженцев.",
              en = "Finish the Wind Hollows, the essences (kill more if short) and the refugees' belongings.",
          } },
        { turnin = 94484, accept = { 94485, 94486, 94487 }, npc = 257944, -- WARN-OK: xp-unknown
          at = { 2521, 61.70, 39.22 },
          note = {
              ru = "Elegael Thornpaw к юго-востоку.",
              en = "Elegael Thornpaw to the south-east.",
          } },
        { accept = 93165, npc = 254151, at = { 2521, 63.81, 36.01 } },
        { complete = 93165, bg = true,
          note = {
              ru = "Уши с Al'Aketh Footsoldier и Stormchaser (5).",
              en = "Ears from Al'Aketh Footsoldiers and Stormchasers (5).",
          } },
        { complete = { 94485, 94486, 94487 }, at = { 2521, 62.2, 37.8 },
          note = {
              ru = "Вокруг Elegael: 8 Lady's Tear Moss на земле, 20 перьев с Shadowgale "
                  .. "Shriekling, 10 Bloody Heirloom с Footsoldier/Stormchaser.",
              en = "Around Elegael: 8 Lady's Tear Moss on the ground, 20 feathers from Shadowgale Shrieklings, "
                  .. "10 Bloody Heirlooms from Footsoldiers / Stormchasers.",
          } },
        { turnin = { 94485, 94486, 94487 }, accept = { 94488, 94489 }, npc = 257944, -- WARN-OK: xp-unknown
          at = { 2521, 61.70, 39.22 } },
        { complete = 94488, npc = 253622, at = { 2521, 65.53, 36.32 },
          note = {
              ru = "Commander Haalien (10 ур.) на востоке: его голова. С него же падает "
                  .. "Ripped Missive.",
              en = "Commander Haalien (level 10) to the east: his head. He also drops the Ripped Missive.",
          } },
        { accept = 94490, use = 265476, at = { 2521, 65.53, 36.32 },
          note = {
              ru = "Прочитайте Ripped Missive (сумка) и возьмите задание.",
              en = "Read the Ripped Missive from your bags and accept the quest.",
          } },
        { complete = 94489, at = { 2521, 64.9, 33.6 },
          note = {
              ru = "Логово Nightclaw к северу: вылечите 7 раненых друидов "
                  .. "(Омоложение / Целительное прикосновение) и найдите Jorel Windsinger (64.5, 34.7).",
              en = "Nightclaw den to the north: heal 7 wounded druids (Rejuvenation / Healing Touch) and find "
                  .. "Jorel Windsinger (64.5, 34.7).",
          } },
        { complete = 93165, optional = true, at = { 2521, 63.6, 37.2 },
          note = {
              ru = "Доберите уши. Падают медленно - бросьте задание (гайд сам пропустит "
                  .. "этот и следующий шаг).",
              en = "Finish the ears. Dropping slowly - abandon the quest (the guide skips this and the next step).",
          } },
        { turnin = 93165, optional = true, npc = 254151, at = { 2521, 63.81, 36.01 }, -- WARN-OK: xp-unknown
          reward = { [93165] = 1 },
          note = {
              ru = "Награда выбирается автоматически: 1-й предмет.",
              en = "The reward is picked automatically: item 1.",
          } },
        { turnin = { 94489, 94490, 94488 }, accept = 94491, npc = 257944, -- WARN-OK: xp-unknown
          at = { 2521, 61.70, 39.22 } },
        -- the cone finish is merged into the turn-in: a separate "complete 93160" step (usually done
        -- early by the bg step) would become the forward anchor and skip the optional 93165 steps
        { complete = 93160, turnin = { 93160, 93172 }, npc = 251684, at = { 2521, 53.96, 38.90 }, -- WARN-OK: xp-unknown
          reward = { [93172] = 1 },
          note = {
              ru = "На запад к отшельнику, по пути доберите шишки. Награда выбирается "
                  .. "автоматически: 1-й предмет.",
              en = "West to the Hermit, finish the cones on the way. The reward is picked automatically: item 1.",
          } },
        { id = "sd02-hearth", hearth = "Valanaar", at = { 2521, 62.19, 72.61 }, radius = 100,
          note = {
              ru = "Камень возвращения в Валанаар (последний раз он использовался на 3-м уровне - готов).",
              en = "Hearth to Valanaar (last used at level 3 - it is ready).",
          } },
        ---------------------------------------------------------------------
        -- Valanaar: turn-ins, training at 12, skycutter (12)
        ---------------------------------------------------------------------
        { turnin = { 94896, 94897 }, npc = 259012, at = { 2521, 66.04, 74.41 } }, -- WARN-OK: xp-unknown
        { turnin = 94491, npc = 252359, at = { 2521, 63.99, 75.08 } }, -- WARN-OK: xp-unknown (Forever-new)
        { id = "sd02-train-12", train = true, npc = 252359, at = { 2521, 63.99, 75.08 },
          spells = {
              { ru = "Трепка", en = "Maul" },
              { ru = "Рык", en = "Growl" },
              { ru = "Деморализующий рёв", en = "Demoralizing Roar" },
              { ru = "Восстановление (12)", en = "Regrowth (12)" },
              { ru = "Исступление (12)", en = "Enrage (12)" },
          },
          note = {
              ru = "Медвежьи умения, если ещё нет; на 12 - «Восстановление» и "
                  .. "«Исступление» (не 12 - их выучите на плато в Мулгоре).",
              en = "Bear abilities if you lack them; at 12 also Regrowth and Enrage (not 12 yet - learn them "
                  .. "on the plateau in Mulgore).",
          } },
        { turnin = 93317, npc = 257006, at = { 2521, 60.64, 72.66 } }, -- WARN-OK: xp-unknown (Forever-new)
        { turnin = 93737, accept = 93738, npc = 256083, at = { 2521, 59.06, 72.98 } }, -- WARN-OK: xp-unknown
        { turnin = 93736, npc = 254344, at = { 2521, 58.13, 78.32 } }, -- WARN-OK: xp-unknown (Forever-new)
        { turnin = 93738, accept = 92708, npc = 251968, at = { 2521, 59.15, 79.78 } }, -- WARN-OK: xp-unknown
        { complete = 92708, turnin = 92708, npc = 251968, at = { 2521, 59.15, 79.78 }, -- WARN-OK: xp-unknown
          note = {
              ru = "Выслушайте речь Ayessa (~75 с; не началась - заговорите с ней) и "
                  .. "сдайте, пока ждёте корабль. Не выходит - бросьте задание (гайд сам пропустит шаг).",
              en = "Listen to Ayessa's speech (~75 s; if it does not start, talk to her) and turn it in while "
                  .. "you wait for the skycutter. Not working - abandon the quest (the guide skips the step).",
          } },
        { id = "sd02-skycutter", go = true, npc = 275270, at = { 2521, 57.92, 80.78 }, radius = 15,
          note = {
              ru = "Причал рядом (Windshapers Dockmaster): садитесь на небесный "
                  .. "корабль до Мулгора.",
              en = "The berth next to her (Windshapers Dockmaster): board the skycutter to Mulgore.",
          } },
        ---------------------------------------------------------------------
        -- Mulgore: Skywatcher Plateau (12)
        ---------------------------------------------------------------------
        { id = "sd02-plateau", go = true, npc = 259119, at = { 1412, 33.40, 22.55 }, radius = 40,
          note = {
              ru = "Корабль прилетает на плато Skywatcher в Мулгоре.",
              en = "The skycutter lands on Skywatcher Plateau in Mulgore.",
          } },
        { id = "sd02-train-12-plateau", train = true, optional = true, npc = 262560, at = { 1412, 33.42, 22.13 },
          spells = {
              { ru = "Восстановление", en = "Regrowth" },
              { ru = "Исступление", en = "Enrage" },
          },
          note = {
              ru = "Если не выучили 12-й в Валанааре: тренер Hana Lighthoof тут же. "
                  .. "Уже выучили - пропустите.",
              en = "Skipped the level 12 training in Valanaar: trainer Hana Lighthoof is right here. "
                  .. "Done already - skip.",
          } },
        { accept = 94911, npc = 259118, at = { 1412, 33.41, 22.58 }, -- carried into sd-03 (Turak)
          note = {
              ru = "Классовое задание: Muln Earthfury.",
              en = "Druid class quest: Muln Earthfury.",
          } },
        { id = "sd02-end", accept = 95350, npc = 259119, at = { 1412, 33.39, 22.51 }, -- carried into sd-03 (Thrall)
          note = {
              ru = "Alaana Stormwalker рядом. Оба задания ведут дальше (Громовой Утёс и Оргриммар).",
              en = "Alaana Stormwalker next to him. Both quests lead on (Thunder Bluff and Orgrimmar).",
          } },
    },
})
