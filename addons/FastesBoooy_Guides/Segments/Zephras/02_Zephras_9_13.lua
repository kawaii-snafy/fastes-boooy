-- FastesBoooy_Guides / Segments / Zephras / 02_Zephras_9_13.lua
-- Segment "sd-02-zephras": Zephras Isle (uiMap 2521), levels 9-13, the start zone of the Skyborne (Windshaper
-- side). Class-neutral: what exists because of a class (training, the level-10 class quests, class gear, reward
-- choices) is in Classes/<Class>.lua as shared inserts on the anchors below.
-- Shen'dar -> glide down to the lowlands -> Valanaar (hearth, turn in 92579 + 93948, story to the Skydocks) ->
-- Windfield orchard (Aamelia chain) and the bandit hill -> gate: level 10 -> Valanaar again (class trainers,
-- level-10 class quests) -> Construct Parts, Fendaal's assassins and crabs -> north past Windsong Lake into
-- Shadowwind Forest (Strange Hermit, refugees, Nightclaw druids) -> hearth to Valanaar, turn-ins -> skycutter to
-- Skywatcher Plateau (Mulgore) and the arrival quest 95350 (Thrall, Orgrimmar).
--
-- Anchors for the class files (docs/dev/PLAN.md C.2; level = validator level of the base profile before the step):
--   sd02-level-10      11.2  generic trainer-hub gate `level = 10` after the last orchard turn-in (the estimate is
--                            a level above it; the gate is the guarantee, every Zephras quest XP is estimated).
--   sd02-valanaar-10   11.2  arrival in Valanaar after the gate: training at 10 and the level-10 class quests
--                            (hunter, rogue and warrior trainers at the west entrance, shaman at the Skydocks,
--                            druid in the east of the village). The path leaves north-west, towards Ur'endra.
--   sd02-fendaal-2     11.3  Fendaal, turn-in of 98512: the last step before the path turns north (the falls
--                            basin of Urs'endris is 13 map units east of here).
--   sd02-hearth        12.7  the hearth to Valanaar; sd02-lotheluum-2 (12.9) is the turn-in at the druid trainer
--                            (a `train` step at him must come after it), sd02-nyalah-2 the last step in the
--                            village before the Skydocks.
--   sd02-plateau       13.2  arrival on Skywatcher Plateau (druid and shaman trainers of the plateau).
--   sd02-end           13.2  accept 95350 at Alaana Stormwalker: the last step of the segment.
-- Every step has an explicit id (prefix "sd02-"). No `reward` here (class reward table of the class file).
--
-- Coordinates: Forever DB snapshot (tools/data/forever_db.lua): NPC / object spawns and centroids of the objective
-- mob / object spawns. Glide points (Walk on Air), the tower ramp and the skycutter berth are terrain points
-- cross-checked with the reference.
-- Every Zephras quest is Forever-new, so its XP is unknown offline: the xp-unknown INFO on each turn-in is
-- expected (the validator estimates it).
-- Skipped on purpose: 93949 (Bugged), 92693 / 92703 (long follow role-play), the 11-13 story chain from 93746,
-- 93746 itself, all Camping 101 profession quests.
if not FastesBoooy.AddLibraryInsert then return end
FastesBoooy.AddLibrarySegment({
    id = "sd-02-zephras",
    title = {
        ru = "9-13 Остров Зефрас: Валанаар, сад Виндфилдов, Лес Теневетра",
        en = "9-13 Zephras Isle: Valanaar, the Windfield orchard, Shadowwind Forest",
    },
    zone = "Zephras Isle",
    -- the validator ends this segment at 13.2 (the druid at 13.3; the reference calls its part "9-13" too)
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
        { id = "sd02-nyalah", accept = 93317, npc = 257006, at = { 2521, 60.64, 72.66 },
          note = {
              ru = "Бегите на восток в Валанаар (медведицу Ur'endra, 10 ур., у 54,65 обойдите). "
                  .. "Nyalah Brightfire на западном краю деревни.",
              en = "Run east to Valanaar (go around the level-10 bear Ur'endra at 54,65). "
                  .. "Nyalah Brightfire on the west side of the village.",
          } },
        { id = "sd02-crabs-bg", complete = 93317, bg = true,
          note = {
              ru = "Windsong Crawler (крабы) по всем низинам: мясо краба.",
              en = "Windsong Crawlers (crabs) all over the lowlands: crawler meat.",
          } },
        { id = "sd02-sethearth", sethearth = "Valanaar", npc = 255940, at = { 2521, 62.19, 72.61 },
          note = {
              ru = "Трактирщик Donaal Downbreeze: привяжите камень к Валанаару.",
              en = "Innkeeper Donaal Downbreeze: bind your hearthstone to Valanaar.",
          } },
        { id = "sd02-alvarion", accept = 92679, npc = 252448, at = { 2521, 62.08, 73.17 },
          note = {
              ru = "Alvarion Windfield на втором этаже таверны. Выслушайте его.",
              en = "Alvarion Windfield on the inn's upper floor. Listen to him.",
          } },
        { id = "sd02-lotheluum", accept = 94484, npc = 252359, at = { 2521, 63.99, 75.08 } },
        { id = "sd02-ealaane", accept = { 94896, 94897 }, npc = 259012, at = { 2521, 66.04, 74.41 } },
        { id = "sd02-talaanis", turnin = 93948, npc = 252476, at = { 2521, 66.17, 76.51 },
          note = {
              ru = "Talaanis Shadowsong наверху башни - поднимайтесь по спиральному пандусу.",
              en = "Talaanis Shadowsong is at the top of the tower - take the spiral ramp up.",
          } },
        { id = "sd02-valennia", turnin = 92579, accept = 92700, npc = 252383, at = { 2521, 66.14, 76.67 },
          note = {
              ru = "Valennia Stormfist рядом.",
              en = "Valennia Stormfist next to her.",
          } },
        { id = "sd02-tower-glide", go = true, at = { 2521, 61.49, 76.89 }, radius = 25,
          note = {
              ru = "Прыгайте с башни на запад и планируйте «Шагом по воздуху» к Небесным докам.",
              en = "Jump off the tower westwards and glide with Walk on Air towards the Skydocks.",
          } },
        { id = "sd02-ayessa", turnin = 92700, accept = 93735, npc = 251968, at = { 2521, 59.15, 79.78 } },
        { id = "sd02-endaria", accept = 93736, npc = 254344, at = { 2521, 58.13, 78.32 },
          note = {
              ru = "Endaria Mistgaze рядом с Ayessa.",
              en = "Endaria Mistgaze next to Ayessa.",
          } },
        { id = "sd02-riaani", turnin = 93735, accept = 93737, complete = { [93737] = { 1 } }, npc = 256083,
          at = { 2521, 59.06, 72.98 },
          note = {
              ru = "Riaani Nightwind на севере доков: сдайте, возьмите и поговорите с ней.",
              en = "Riaani Nightwind north of the docks: turn in, accept and talk to her.",
          } },
        ---------------------------------------------------------------------
        -- Windfield orchard (10-11)
        ---------------------------------------------------------------------
        { id = "sd02-aamelia", complete = 92679, turnin = 92679, accept = { 92682, 92684, 92683 }, npc = 252800,
          at = { 2521, 46.70, 81.95 },
          note = {
              ru = "Прямо на юго-запад в сад Виндфилдов: Aamelia Windfield.",
              en = "Straight south-west to the Windfield orchard: Aamelia Windfield.",
          } },
        { id = "sd02-tenderloins-bg", complete = 92684, bg = true,
          note = {
              ru = "Ornery Galestrider повсюду в низинах: 7 вырезок.",
              en = "Ornery Galestriders all over the lowlands: 7 tenderloins.",
          } },
        { id = "sd02-dust-bg", complete = 92683, bg = true, use = 253666,
          note = {
              ru = "Прихлопните Flutterfly «Мухобойкой» (сумка) и подберите пыльцу.",
              en = "Swat Flutterflies with the Flutterfly Swatter (bags) and pick up the dust.",
          } },
        { id = "sd02-orchard", complete = 92682, at = { 2521, 47.3, 81.0 },
          note = {
              ru = "Вокруг Aamelia: 5 Hungry Bandit и 10 Ripe Stormapple под деревьями.",
              en = "Around Aamelia: 5 Hungry Bandits and 10 Ripe Stormapples under the trees.",
          } },
        { id = "sd02-construct", accept = 92698, npc = 250929, at = { 2521, 48.87, 78.25 },
          note = {
              ru = "Malfunctioning Cyclone Construct к северо-востоку от сада.",
              en = "Malfunctioning Cyclone Construct north-east of the orchard.",
          } },
        { id = "sd02-dust", complete = { 92683, 92684 }, at = { 2521, 50.3, 78.7 },
          note = {
              ru = "Доберите пыльцу и вырезки к востоку от сада.",
              en = "Finish the dust and tenderloins east of the orchard.",
          } },
        { id = "sd02-aamelia-2", turnin = { 92682, 92684, 92698, 92683 }, accept = 92685, npc = 252800,
          at = { 2521, 46.70, 81.95 } },
        { id = "sd02-bandit-hill", complete = { 92685, [93737] = { 4 } }, object = 616467, at = { 2521, 44.5, 74.5 },
          note = {
              ru = "Холм бандитов к северо-западу: маски с Bandit Highwayman (7, есть "
                  .. "невидимые) и Construct Parts на холме (ядро конструкта).",
              en = "Bandit hill to the north-west: masks from Bandit Highwaymen (7, some are stealthed) and "
                  .. "the Construct Parts on the hill (construct core).",
          } },
        { id = "sd02-aamelia-3", turnin = 92685, npc = 252800, at = { 2521, 46.70, 81.95 },
          note = {
              ru = "С юго-восточного края холма (44.1, 76.2) спланируйте «Шагом по воздуху» "
                  .. "к саду. Следующее задание Aamelia (долгая сценка) не берите.",
              en = "From the south-east edge of the hill (44.1, 76.2) glide with Walk on Air down to the orchard. "
                  .. "Do not take Aamelia's next quest (a long role-play).",
          } },
        -- Trainer-hub gate (docs/dev/PLAN.md B.8): every class trains at 10 and the level-10 class quests start
        -- in Valanaar, the next stop. The validator is at ~11.1 here; every quest XP of the isle is an estimate,
        -- so the gate stays as the guarantee. `at`: Ornery Galestriders (8-9) and Vuldren Alphas (10) between the
        -- orchard and Valanaar.
        { id = "sd02-level-10", level = 10, at = { 2521, 52.5, 78.0 },
          note = {
              ru = "Нужен 10-й уровень: в Валанааре - новые ранги у тренеров и классовые задания 10-го уровня. "
                  .. "Не хватает - бейте галестрайдеров, вулдренов и крабов по пути на восток.",
              en = "Level 10 is needed: Valanaar has the new ranks at the class trainers and the level-10 class "
                  .. "quests. Short of it - kill galestriders, vuldren and crabs on the way east.",
          } },
        ---------------------------------------------------------------------
        -- Valanaar again (class trainers at 10), then the lowlands north-west of it (11)
        ---------------------------------------------------------------------
        -- Anchor of the level-10 class steps (training, class quests): the class files insert after this step.
        { id = "sd02-valanaar-10", go = true, at = { 2521, 60.64, 72.66 }, radius = 40,
          note = {
              ru = "Обратно на восток в Валанаар: тренеры классов (10-й уровень - новые ранги и классовые "
                  .. "задания). Охотник, разбойник и воин - у западного входа, шаман - на Небесных доках, друид - "
                  .. "на востоке деревни.",
              en = "Back east to Valanaar: the class trainers (level 10: new ranks and class quests). Hunter, "
                  .. "rogue and warrior at the west entrance, shaman at the Skydocks, druid in the east of the "
                  .. "village.",
          } },
        { id = "sd02-parts-lightning", complete = { [93737] = { 2 } }, object = 616468, at = { 2521, 52.07, 66.45 },
          note = {
              ru = "Из Валанаара на северо-запад, тем же путём, что пришли: Construct Parts (кристаллизованная "
                  .. "молния) у 52,66. Медведица Ur'endra (10 ур.) бродит рядом, у 54,65.",
              en = "North-west out of Valanaar, the way you came in: Construct Parts (Crystallized Lightning) at "
                  .. "52,66. The bear Ur'endra (level 10) wanders next to them, around 54,65.",
          } },
        { id = "sd02-fendaal", accept = 98512, npc = 273017, at = { 2521, 56.81, 61.11 },
          note = {
              ru = "Peacekeeper Fendaal Windstone к северо-востоку.",
              en = "Peacekeeper Fendaal Windstone to the north-east.",
          } },
        { id = "sd02-assassins", complete = { 98512, 93317 }, at = { 2521, 55.5, 59.5 },
          note = {
              ru = "10 Al'Aketh Assassin вокруг (могут быть в невидимости) и крабы "
                  .. "на берегу к западу.",
              en = "10 Al'Aketh Assassins around (they can be stealthed) and the crabs on the shore to the west.",
          } },
        { id = "sd02-fendaal-2", turnin = 98512, npc = 273017, at = { 2521, 56.81, 61.11 } },
        ---------------------------------------------------------------------
        -- North: Windsong Lake, Shadowwind Forest (11-12)
        ---------------------------------------------------------------------
        { id = "sd02-parts-gyrozephyr", complete = { [93737] = { 3 } }, object = 616466, at = { 2521, 53.2, 50.2 },
          note = {
              ru = "На север, к восточному берегу озера Виндсонг (лагерь Al'Aketh восточнее - не заходите): "
                  .. "Construct Parts (зачарованный гирозефир).",
              en = "North to the east shore of Windsong Lake (the Al'Aketh camp is to the east - stay out of it): "
                  .. "Construct Parts (Enchanted Gyrozephyr).",
          } },
        { id = "sd02-hermit", accept = 93159, complete = 93159, turnin = 93159, npc = 251684,
          at = { 2521, 53.96, 38.90 },
          note = {
              ru = "Strange Hermit на севере: пройдите все варианты его диалога.",
              en = "Strange Hermit to the north: go through all of his dialogue options.",
          } },
        { id = "sd02-hermit-2", accept = { 93160, 93172 }, npc = 251684, at = { 2521, 53.96, 38.90 } },
        { id = "sd02-cones-bg", complete = 93160, bg = true,
          note = {
              ru = "Zephyrseed Cone (шишки) на земле между отшельником и Elegael.",
              en = "Zephyrseed Cones on the ground between the Hermit and Elegael.",
          } },
        { id = "sd02-hollows-bg", complete = { 93172, 93736, 94896 }, bg = true,
          note = {
              ru = "На севере: 10 Wind Hollow (их эссенции) и 8 Abandoned Belongings на земле.",
              en = "To the north: 10 Wind Hollows (and their essences) and 8 Abandoned Belongings on the ground.",
          } },
        { id = "sd02-resaan", complete = 94897, npc = 259013, at = { 2521, 57.05, 29.35 },
          note = {
              ru = "Resaan Nimbuswalker на северном краю: поговорите с ним (реликвия).",
              en = "Resaan Nimbuswalker at the north end: talk to him (the heirloom).",
          } },
        { id = "sd02-hollows", complete = { 93172, 93736, 94896 }, at = { 2521, 58.2, 32.1 },
          note = {
              ru = "Доберите Wind Hollow, эссенции (не хватает - бейте ещё) и вещи беженцев.",
              en = "Finish the Wind Hollows, the essences (kill more if short) and the refugees' belongings.",
          } },
        { id = "sd02-elegael", turnin = 94484, accept = { 94485, 94486, 94487 }, npc = 257944,
          at = { 2521, 61.70, 39.22 },
          note = {
              ru = "Elegael Thornpaw к юго-востоку.",
              en = "Elegael Thornpaw to the south-east.",
          } },
        { id = "sd02-vayn", accept = 93165, npc = 254151, at = { 2521, 63.81, 36.01 } },
        { id = "sd02-ears-bg", complete = 93165, bg = true,
          note = {
              ru = "Уши с Al'Aketh Footsoldier и Stormchaser (5).",
              en = "Ears from Al'Aketh Footsoldiers and Stormchasers (5).",
          } },
        { id = "sd02-den-items", complete = { 94485, 94486, 94487 }, at = { 2521, 62.2, 37.8 },
          note = {
              ru = "Вокруг Elegael: 8 Lady's Tear Moss на земле, 20 перьев с Shadowgale "
                  .. "Shriekling, 10 Bloody Heirloom с Footsoldier/Stormchaser.",
              en = "Around Elegael: 8 Lady's Tear Moss on the ground, 20 feathers from Shadowgale Shrieklings, "
                  .. "10 Bloody Heirlooms from Footsoldiers / Stormchasers.",
          } },
        { id = "sd02-elegael-2", turnin = { 94485, 94486, 94487 }, accept = { 94488, 94489 }, npc = 257944,
          at = { 2521, 61.70, 39.22 } },
        { id = "sd02-haalien", complete = 94488, npc = 253622, at = { 2521, 65.53, 36.32 },
          note = {
              ru = "Commander Haalien (10 ур.) на востоке: его голова. С него же падает "
                  .. "Ripped Missive.",
              en = "Commander Haalien (level 10) to the east: his head. He also drops the Ripped Missive.",
          } },
        { id = "sd02-missive", accept = 94490, use = 265476, at = { 2521, 65.53, 36.32 },
          note = {
              ru = "Прочитайте Ripped Missive (сумка) и возьмите задание.",
              en = "Read the Ripped Missive from your bags and accept the quest.",
          } },
        -- CONFIRM: how a class without a healing spell completes "Injured Druids healed" (an interact objective in
        -- the DB; the reference guide is a druid's and heals them). The way out is in the note: 94491 needs 94490
        -- only, and the turn-in step sd02-elegael-3 treats an abandoned 94489 as done.
        { id = "sd02-wounded", complete = 94489, at = { 2521, 64.9, 33.6 },
          note = {
              ru = "Логово Nightclaw к северу: помогите 7 раненым друидам (подойдите и взаимодействуйте с каждым; "
                  .. "есть лечащее заклинание - вылечите им) и найдите Jorel Windsinger (64.5, 34.7). Вашим классом "
                  .. "помочь не выходит - бросьте задание (гайд сам пропустит этот шаг).",
              en = "Nightclaw den to the north: tend 7 injured druids (walk up and interact with each; with a "
                  .. "healing spell, heal them) and find Jorel Windsinger (64.5, 34.7). Your class cannot help "
                  .. "them - abandon the quest (the guide skips this step).",
          } },
        { id = "sd02-ears", complete = 93165, optional = true, at = { 2521, 63.6, 37.2 },
          note = {
              ru = "Доберите уши. Падают медленно - бросьте задание (гайд сам пропустит "
                  .. "этот и следующий шаг).",
              en = "Finish the ears. Dropping slowly - abandon the quest (the guide skips this and the next step).",
          } },
        { id = "sd02-vayn-2", turnin = 93165, optional = true, npc = 254151, at = { 2521, 63.81, 36.01 } },
        { id = "sd02-elegael-3", turnin = { 94489, 94490, 94488 }, accept = 94491, npc = 257944,
          at = { 2521, 61.70, 39.22 } },
        -- the cone finish is merged into the turn-in: a separate "complete 93160" step (usually done
        -- early by the bg step) would become the forward anchor and skip the optional 93165 steps
        { id = "sd02-hermit-3", complete = 93160, turnin = { 93160, 93172 }, npc = 251684, at = { 2521, 53.96, 38.90 },
          note = {
              ru = "На запад к отшельнику, по пути доберите шишки.",
              en = "West to the Hermit, finish the cones on the way.",
          } },
        { id = "sd02-hearth", hearth = "Valanaar", at = { 2521, 62.19, 72.61 }, radius = 100,
          note = {
              ru = "Камень возвращения в Валанаар (последний раз он использовался на 3-м уровне - готов).",
              en = "Hearth to Valanaar (last used at level 3 - it is ready).",
          } },
        ---------------------------------------------------------------------
        -- Valanaar: turn-ins, skycutter (12-13)
        ---------------------------------------------------------------------
        { id = "sd02-ealaane-2", turnin = { 94896, 94897 }, npc = 259012, at = { 2521, 66.04, 74.41 } },
        { id = "sd02-lotheluum-2", turnin = 94491, npc = 252359, at = { 2521, 63.99, 75.08 } },
        { id = "sd02-nyalah-2", turnin = 93317, npc = 257006, at = { 2521, 60.64, 72.66 } },
        { id = "sd02-riaani-2", turnin = 93737, accept = 93738, npc = 256083, at = { 2521, 59.06, 72.98 } },
        { id = "sd02-endaria-2", turnin = 93736, npc = 254344, at = { 2521, 58.13, 78.32 } },
        { id = "sd02-ayessa-2", turnin = 93738, accept = 92708, npc = 251968, at = { 2521, 59.15, 79.78 } },
        { id = "sd02-speech", complete = 92708, turnin = 92708, npc = 251968, at = { 2521, 59.15, 79.78 },
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
        -- Mulgore: Skywatcher Plateau (13)
        ---------------------------------------------------------------------
        { id = "sd02-plateau", go = true, npc = 259119, at = { 1412, 33.40, 22.55 }, radius = 40,
          note = {
              ru = "Корабль прилетает на плато Skywatcher в Мулгоре.",
              en = "The skycutter lands on Skywatcher Plateau in Mulgore.",
          } },
        -- 95350 is carried to Orgrimmar: Thrall takes it in Races/Skyborne.lua (sky-thrall)
        { id = "sd02-end", accept = 95350, npc = 259119, at = { 1412, 33.39, 22.51 },
          note = {
              ru = "Alaana Stormwalker у причала: «Добро пожаловать в Азерот» - к Траллу в Оргриммар.",
              en = "Alaana Stormwalker at the dock: Welcome to Azeroth leads to Thrall in Orgrimmar.",
          } },
    },
})
