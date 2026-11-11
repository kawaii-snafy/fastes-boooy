-- FastesBoooy_Guides / Classes / Druid.lua
-- Every step that exists because of the class (druid), as shared inserts with class scope (step ids "dru-..."):
-- the Skyborne group of Zephras Isle 1-13 (ids "dru-zep-...": the letter, training, the Bear Form chain, class gear)
-- with the Thunder Bluff visit at 13, the Moonglade visits of 14-22, the Cat Form chain at 20, class training 24-60
-- (Travel Form at 30, Dire Bear Form at 40) and the Torwa Pathfinder chain in Un'Goro (9063 -> 9052 -> 9051); and
-- the druid's reward choices for quests of the shared steps (the class reward table).
-- The Tauren group below level 12 (Mulgore) does not exist yet: phase C writes it.
-- Sources: research druid60.md / druid60.json (trainers, spells by level, training plan, talents, class quests),
-- plan60.json classInserts.DRUID; NPCs / objects / quests: tools/data/forever_db.lua; ruRU names: Wowhead Forever
-- ru tooltips.
--
-- Race scope (docs/dev/PLAN.md D.2, F2b step 2): the training inserts and the Torwa chain are
--   unscoped: the Tauren druid harness run (tests/spec/guides_layout_spec.lua) passes with them.
--   Always Skyborne-only: 94911 / 94913 (Thunder Bluff, Moonglade) and the Cat Form chain 98340 > 98341 > 98404 >
--   98738 > 98362 (its middle is Skyborne-only in the DB; the Tauren druid needs other quests: phase C).
--
-- Zephras Isle, Skyborne (validator level before the step, normal / worst case where they differ). All quest XP of
-- the isle is estimated, so `optional` marks the two visits that sit right after an even level:
--   2       after  sd01-rorian            3.02         the letter 92485 (Rorian > Xyton Silverwind), training 1.
--   4       after  sd01-rorian-4          4.60         Xyton again (optional; the gate sd01-level-4 stands in front).
--   6       after  sd01-raan-2            6.36         Naeluna Swiftmend in Shen'dar, between the campfire and Aonda.
--   8       after  sd01-danarii-2         8.91         Naeluna (optional), the Walking Stick at Tephri (optional).
--   9       after  sd02-endaria          10.33         the Zephrali Greatstaff at Falfaan (optional).
--   10      after  sd02-valanaar-10      11.21         Lotheluum Starbreeze: 94006 and training 10 (the shared gate
--                                                      sd02-level-10 guarantees the level), Urs'endris in the falls
--                                                      basin (94006 > 94638), Ur'endra next to the shared Construct
--                                                      Parts.
--           after  sd02-fendaal-2        11.42         back to Urs'endris: Bear Form; out of the basin, north to the
--                                                      lake.
--   12      after  sd02-lotheluum-2      13.00/12.94   Lotheluum, after the shared turn-in of 94491 at him.
--           after  sd02-plateau          13.32/13.26   Hana Lighthoof (optional), 94911 at Muln Earthfury.
-- Not routed for a Skyborne: Cure Poison 6126-6130 and Aquatic Form 27-31 (Tauren-only in the DB; the note of
-- dru-cat-start tells the player to take 27 by hand if Turak offers it).
--
-- Where the visits go on 12-22 (the druid trains in Moonglade: Teleport: Moonglade right before a shared hearth
-- step costs nothing):
--   13      after  sd03-spirit            Skyborne: over the rope bridge to Elder Rise, Turak (optional training,
--                                         94911 > 94913), back to the central mesa.
--   14      before h13-hearth-org         from the Undercity: Dendrite (94913, Skyborne), Loganaar (the gate
--                                         h13-lvl-14 guarantees 14 at the end of the Undercity visit).
--   16      before h15-hearth-xroads      from the harpies: Loganaar (Swipe).
--   18      before h18-hearth-taurajo     from the Stagnant Oasis: Loganaar.
--   20      after  h18-tb-2               Skyborne: Turak 98340, Teleport: Moonglade, the chain in Nighthaven and
--                                         the Stormrage Barrow Dens, hearth to Thunder Bluff (bound there one step
--                                         earlier; the shared path uses it again more than an hour later, from
--                                         Zoram'gar), Cat Form at Turak. Then training 20 at Turak for both races.
--   22      before h18-hearth-tb          from Zoram'gar: Loganaar.
-- The hearth of the Cat Form chain is the one class use of the hearthstone that is not right in front of a shared
-- hearth step (docs/dev/PLAN.md C.3 rule 3): the stone is bound to Thunder Bluff by the shared step before it, and
-- Bunthen Plainswind (druid-only flight Nighthaven -> Thunder Bluff) is the fallback named in the note.
--
-- Where the visits go on 22-60 (validator level at the insert, normal / worst case = no optional step done):
--   24      after  h-24-tb-arrive         25.16/24.06  Turak (Elder Rise); next library step is Tah (other NPC).
--   26+28   before h-28-thunder-bluff     28.94/28.23  Turak, on the way back from Skywatcher Plateau (the plan's
--                                                      anchor h-28-tb-arrive is below 28 in the worst case).
--   30      after  h-31-tb-end            31.01        Turak next to Magatha: TRAVEL FORM. 30 comes in the
--                                                      Shimmering Flats (h-27 #115), but the hearthstone is
--                                                      reserved for the Flats -> Thunder Bluff hearth there.
--   32      after  h-33-tarrenmill-end    32.06/31.85  Teleport: Moonglade + hearth to Tarren Mill (the library
--                                                      binds it there and keeps it for this visit).
--   34+36   before h38-hearth-shadowprey  37.70        Moonglade right before the library's own hearth (no extra
--                                                      hearth use: Teleport, train, then the library hearth).
--   38+40   after  h-40-org-arrive        40.06/40.01  dru-40-fly-tb, dru-40-train (Turak: DIRE BEAR FORM; not
--                                                      40 yet: the 38 set only), dru-40-fly-taurajo (own fly step:
--                                                      the shared next step names Doras, it completes on the same
--                                                      landing). These three ids are a contract with the race files
--                                                      (docs/dev/PLAN.md C.7): the riding steps of a Skyborne or
--                                                      Tauren druid are inserted after dru-40-train.
--   42+44   before h44-hearth-gromgol     44.52/44.50  Moonglade before the library hearth (instead of the plan's
--                                                      Kargath hearth at 44.02: that would put the h44-hearth-gromgol
--                                                      hearth half a level later on cooldown).
--   46+48   after  h-50-mojache-end       49.40/49.36  Jannos Lighthoof in Camp Mojache (h-48-mojache-arrive is
--                                                      only 47.19).
--   50+52   before h54-hearth-org         53.05/53.03  Moonglade before the library hearth (Azshara -> Orgrimmar):
--                                                      also accept 9063 Torwa Pathfinder there (optional: a
--                                                      breadcrumb of 9052, not its prerequisite).
--   Torwa   after  h-53-torwa-pathfinder  53.15        9063 > 9052 (Bloodcaps on the loop, Gorishi Stings at the
--                                                      edge of the hive before h54-torwa-3), 9052 > 9051 at
--                                                      h54-torwa-3, Devilsaur stab in loop 2 (bg), 9051 at
--                                                      h55-torwa-end. 9053 (Sunken Temple) is not taken: the route's
--                                                      optional Sunken Temple run is in h-50, before 9051.
--   54      before h56-hearth-gadgetzan   55.05/55.04  Moonglade before the library hearth (the plan's slot before
--                                                      h-55-cenarionhold-arrive would need a second Gadgetzan hearth
--                                                      0.1 level after h55-hearth-gadgetzan).
--   56      before h-58-org-arrive        57.21/57.17  Moonglade before the library hearth (Felwood -> Orgrimmar).
--   58+60   after  h-60-end               60.00        Moonglade: the route ends there.
-- Not visited: 26, 34, 38, 42, 46, 50, 58 on their own (merged into the next visit: medium-priority sets).
-- Automation: no inserted transient step (train, fly, go, hearth) is followed by an accept at the same NPC within
-- 6 steps (the 9063 accept comes before the level 52 training, not after it); the Torwa steps are stateful.
-- Hearthstone: only the level 32 visit uses it beyond the library (Tarren Mill, bound at h-31-tarrenmill-arrive,
-- otherwise unused); every other Moonglade visit of 22-60 sits right before a shared hearth step, and the
-- level 40 trip uses flights.

if not FastesBoooy.AddLibraryInsert then return end

local TURAK = { 1456, 76.48, 27.22 }
local LOGANAAR = { 1450, 52.53, 40.57 }

-- Class reward table (one call per class file): the druid's choices for quests that are turned in on shared steps
-- of Zephras Isle (the segments carry no `reward`).
FastesBoooy.AddLibraryData({ rewards = { DRUID = {
    [92461] = 1, [92463] = 3, [92469] = 1, [92470] = 2, [92473] = 1, [92517] = 3, [92528] = 1, [93318] = 1,
    [92550] = 3, -- sd-01-zephras
    [92579] = 3, [92684] = 3, [93165] = 1, [93172] = 1, -- sd-02-zephras
} } })

------------------------------------------------------------------------------
-- Zephras Isle 1-9 (Skyborne): the letter, training at Thendal (1, 4) and Shen'dar (6, 8), the first staff
------------------------------------------------------------------------------
-- Rorian gives the letter in the dialog of the shared step; Xyton stands next to him.
FastesBoooy.AddLibraryInsert({
    after = "sd01-rorian",
    class = "DRUID",
    race = "Skyborne",
    steps = {
        { id = "dru-zep-letter", accept = 92485, npc = 251361, at = { 2521, 42.05, 23.49 },
          note = {
              ru = "Rorian даёт и классовое задание друида: «Ученик природы» (A Student of Nature).",
              en = "Rorian also gives the druid class quest: A Student of Nature.",
          } },
        { id = "dru-zep-xyton", turnin = 92485, use = 282420, npc = 251373, at = { 2521, 41.66, 23.33 },
          note = {
              ru = "Классовое задание: прочитайте «Сложенный пергамент» (сумка), "
                  .. "затем поговорите с Xyton.",
              en = "Druid class quest: read the Folded Parchment from your bags, then talk to Xyton.",
          } },
        { id = "dru-zep-train-1", train = true, npc = 251373, at = { 2521, 41.66, 23.33 },
          spells = { { ru = "Знак дикой природы", en = "Mark of the Wild" } },
          note = {
              ru = "Выучите «Знак дикой природы» и держите его на себе. Первые уровни: «Гнев», добивайте посохом.",
              en = "Learn Mark of the Wild and keep it up. The first levels: Wrath, then melee.",
          } },
    },
})
FastesBoooy.AddLibraryInsert({
    after = "sd01-rorian-4",
    class = "DRUID",
    race = "Skyborne",
    steps = {
        { id = "dru-zep-train-4", train = true, optional = true, npc = 251373, at = { 2521, 41.66, 23.33 },
          spells = { { ru = "Лунный огонь", en = "Moonfire" }, { ru = "Омоложение", en = "Rejuvenation" } },
          note = {
              ru = "Xyton рядом с Rorian. Уровень 4: «Лунный огонь» и «Омоложение».",
              en = "Xyton next to Rorian. Level 4: Moonfire and Rejuvenation.",
          } },
    },
})
-- Naeluna stands between Raan's campfire and Constable Aonda: after the last step at the campfire.
FastesBoooy.AddLibraryInsert({
    after = "sd01-raan-2",
    class = "DRUID",
    race = "Skyborne",
    steps = {
        { id = "dru-zep-train-6", train = true, npc = 254081, at = { 2521, 45.16, 44.22 },
          spells = { { ru = "Гнев (ранг 2)", en = "Wrath (Rank 2)" }, { ru = "Шипы", en = "Thorns" } },
          note = {
              ru = "Naeluna Swiftmend на востоке деревни. Уровень 6: «Гнев» 2 и «Шипы» "
                  .. "(+ «Лунный огонь»/«Омоложение», если не взяли на 4). Дальше: с магами High Order "
                  .. "Apprentice деритесь вплотную; элиту Vulgara (задание с доски) бейте с «Шипами» и "
                  .. "«Омоложением», держа дистанцию.",
              en = "Naeluna Swiftmend on the east side of the village. Level 6: Wrath 2 and Thorns (+ Moonfire / "
                  .. "Rejuvenation if you skipped them at 4). Ahead: fight the High Order Apprentices (casters) "
                  .. "up close; fight the elite Vulgara (the wanted poster) with Thorns and Rejuvenation up, at "
                  .. "a distance.",
          } },
    },
})
FastesBoooy.AddLibraryInsert({
    after = "sd01-danarii-2",
    class = "DRUID",
    race = "Skyborne",
    steps = {
        { id = "dru-zep-train-8", train = true, optional = true, npc = 254081, at = { 2521, 45.16, 44.22 },
          spells = {
              { ru = "Гнев деревьев", en = "Entangling Roots" },
              { ru = "Целительное прикосновение (ранг 2)", en = "Healing Touch (Rank 2)" },
          },
          note = {
              ru = "Naeluna Swiftmend рядом. Уровень 8: «Гнев деревьев» и «Целительное прикосновение» 2 "
                  .. "(не 8 - пропустите).",
              en = "Naeluna Swiftmend next to him. Level 8: Entangling Roots and Healing Touch 2 (not 8 yet - skip).",
          } },
        { id = "dru-zep-staff-1", vendor = true, optional = true, npc = 257421, at = { 2521, 44.79, 44.17 },
          note = {
              ru = "Tephri Thriceforged: Walking Stick (посох, 4.2 DPS, ур. 3, ~5 с), если ваше "
                  .. "оружие слабее. Иначе пропустите.",
              en = "Tephri Thriceforged: buy the Walking Stick (staff, 4.2 DPS, level 3, ~5s) if your weapon is "
                  .. "weaker. Otherwise skip.",
          } },
    },
})

------------------------------------------------------------------------------
-- Zephras Isle 9-13 (Skyborne): a staff, training at 10 and the Bear Form chain 94006 > 94638, training at 12,
-- 94911 on Skywatcher Plateau
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "sd02-endaria",
    class = "DRUID",
    race = "Skyborne",
    steps = {
        { id = "dru-zep-staff-2", vendor = true, optional = true, npc = 271465, at = { 2521, 59.40, 75.73 },
          note = {
              ru = "По пути на север к Riaani: Falfaan Halfwind - Zephrali Greatstaff (8.48 DPS, ур. 9, ~22 с), "
                  .. "если оружие слабее 8.5 DPS и хватает денег. Иначе пропустите.",
              en = "On the way north to Riaani: Falfaan Halfwind - Zephrali Greatstaff (8.48 DPS, level 9, ~22s) if "
                  .. "your weapon is below 8.5 DPS and you can afford it. Otherwise skip.",
          } },
    },
})
-- Bear Form, first half: the shared gate sd02-level-10 guarantees level 10 (reqLevel of 94006). From Lotheluum to
-- Urs'endris in the falls basin, then to Ur'endra, who wanders next to the Construct Parts of the shared path
-- (sd02-parts-lightning is the next shared step).
FastesBoooy.AddLibraryInsert({
    after = "sd02-valanaar-10",
    class = "DRUID",
    race = "Skyborne",
    steps = {
        -- The accept comes before the training at the same NPC: with the accept right after the train step, the
        -- automation takes 94006 from the trainer's gossip and the accept (an anchor) forwards the training before
        -- the trainer window is ever opened.
        { id = "dru-zep-bear-accept", accept = 94006, npc = 252359, at = { 2521, 63.99, 75.08 },
          note = {
              ru = "Lotheluum Starbreeze на востоке Валанаара: классовое задание (облик "
                  .. "медведя). Обучение - следующим шагом, у него же.",
              en = "Lotheluum Starbreeze in the east of Valanaar: the druid class quest (Bear Form). "
                  .. "The training is the next step, from him too.",
          } },
        { id = "dru-zep-train-10", train = true, npc = 252359, at = { 2521, 63.99, 75.08 },
          spells = {
              { ru = "Хватка природы", en = "Nature's Grasp" },
              { ru = "Омоложение (ранг 2)", en = "Rejuvenation (Rank 2)" },
              { ru = "Знак дикой природы (ранг 2)", en = "Mark of the Wild (Rank 2)" },
              { ru = "Лунный огонь (ранг 2)", en = "Moonfire (Rank 2)" },
              { ru = "Телепортация: Лунная поляна (если есть)", en = "Teleport: Moonglade (if offered)" },
          },
          note = {
              ru = "Lotheluum ещё раз (обучение в его меню). Уровень 10: всё из списка (+ Трепка/Рык, "
                  .. "если уже доступны). Таланты: Свирепость (Ferocity) 5/5 с 10 по 14.",
              en = "Lotheluum again (training in his menu). Level 10: everything listed (+ Maul / Growl "
                  .. "if offered already). Talents: Ferocity 5/5 from 10 to 14.",
          } },
        { id = "dru-zep-bear-north", go = true, at = { 2521, 65.42, 71.47 }, radius = 20,
          note = {
              ru = "Из Валанаара на север.",
              en = "North out of Valanaar.",
          } },
        { id = "dru-zep-bear-cliff", go = true, at = { 2521, 69.01, 65.86 }, radius = 20,
          note = {
              ru = "На северо-восток к обрыву над водопадами, оттуда спланируйте "
                  .. "«Шагом по воздуху» вниз к Urs'endris.",
              en = "North-east to the cliff above the falls, then glide down to Urs'endris with Walk on Air.",
          } },
        { id = "dru-zep-bear-spirit", turnin = 94006, accept = 94638, npc = 255853,
          at = { 2521, 69.81, 61.71 },
          note = {
              ru = "Urs'endris, Великий дух медведя.",
              en = "Urs'endris, the Great Windborne Bear Spirit.",
          } },
        { id = "dru-zep-bear-exit", go = true, at = { 2521, 59.59, 66.70 }, radius = 25,
          note = {
              ru = "Из котловины водопадов выход на запад.",
              en = "The way out of the falls basin is to the west.",
          } },
        { id = "dru-zep-bear-kill", complete = 94638, npc = 258443, at = { 2521, 54.35, 65.53 },
          note = {
              ru = "Убейте Ur'endra (10 ур., медведица), бродит у 54,65. Construct Parts (следующий шаг) - чуть "
                  .. "западнее.",
              en = "Kill Ur'endra (level 10 bear), she wanders around 54,65. The Construct Parts (the next step) "
                  .. "are just to the west.",
          } },
    },
})
-- Bear Form, second half: back to Urs'endris from Fendaal (the last shared step before the path turns north), then
-- out of the basin and north to the lake, where the shared path goes on (sd02-parts-gyrozephyr).
FastesBoooy.AddLibraryInsert({
    after = "sd02-fendaal-2",
    class = "DRUID",
    race = "Skyborne",
    steps = {
        { id = "dru-zep-bear-ridge", go = true, at = { 2521, 60.25, 62.74 }, radius = 25,
          note = {
              ru = "На восток; с гребня спланируйте «Шагом по воздуху» к Urs'endris.",
              en = "East; glide from the ridge down to Urs'endris with Walk on Air.",
          } },
        { id = "dru-zep-bear-form", turnin = 94638, npc = 255853, at = { 2521, 69.81, 61.71 },
          note = {
              ru = "Награда - облик медведя. Дальше деритесь в нём (Трепку выучите "
                  .. "у тренера при возвращении).",
              en = "The reward is Bear Form. Fight in it from now on (learn Maul at the trainer when you are back).",
          } },
        { id = "dru-zep-bear-exit-2", go = true, at = { 2521, 59.41, 66.95 }, radius = 25,
          note = {
              ru = "Снова выход из котловины на запад.",
              en = "Leave the basin to the west again.",
          } },
        { id = "dru-zep-bear-lake", go = true, at = { 2521, 58.92, 55.01 }, radius = 25,
          note = {
              ru = "На север (лагерь Al'Aketh восточнее - не заходите).",
              en = "North (the Al'Aketh camp is to the east - stay out of it).",
          } },
    },
})
-- After the shared turn-in of 94491 at Lotheluum (a train step in front of it would be fast-forwarded).
FastesBoooy.AddLibraryInsert({
    after = "sd02-lotheluum-2",
    class = "DRUID",
    race = "Skyborne",
    steps = {
        { id = "dru-zep-train-12", train = true, npc = 252359, at = { 2521, 63.99, 75.08 },
          spells = {
              { ru = "Трепка", en = "Maul" },
              { ru = "Рык", en = "Growl" },
              { ru = "Деморализующий рёв", en = "Demoralizing Roar" },
              { ru = "Восстановление (12)", en = "Regrowth (12)" },
              { ru = "Исступление (12)", en = "Enrage (12)" },
          },
          note = {
              ru = "Lotheluum: медвежьи умения, если ещё нет; на 12 - «Восстановление» и "
                  .. "«Исступление» (не 12 - их выучите на плато в Мулгоре).",
              en = "Lotheluum: bear abilities if you lack them; at 12 also Regrowth and Enrage (not 12 yet - learn "
                  .. "them on the plateau in Mulgore).",
          } },
    },
})
FastesBoooy.AddLibraryInsert({
    after = "sd02-plateau",
    class = "DRUID",
    race = "Skyborne",
    steps = {
        { id = "dru-zep-train-12-plateau", train = true, optional = true, npc = 262560, at = { 1412, 33.42, 22.13 },
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
        { id = "dru-zep-child-accept", accept = 94911, npc = 259118, at = { 1412, 33.41, 22.58 },
          note = {
              ru = "Классовое задание: Muln Earthfury - «Дитя природы» (к Тюраку в Громовой Утёс).",
              en = "Druid class quest: Muln Earthfury - Child of Nature (to Turak in Thunder Bluff).",
          } },
    },
})

------------------------------------------------------------------------------
-- 13, Skyborne: Thunder Bluff, Elder Rise (Turak): optional training, 94911 > 94913
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "sd03-spirit",
    class = "DRUID",
    race = "Skyborne",
    steps = {
        { id = "dru-zep-tb-bridge", go = true, at = { 1456, 55.36, 35.55 }, radius = 15,
          note = {
              ru = "Вниз по тропе через 54,27 и 50,34 на центральную возвышенность, к "
                  .. "подвесному мосту на её северо-восточном краю.",
              en = "Down the path via 54,27 and 50,34 onto the central mesa, to the rope bridge at its north-east "
                  .. "edge.",
          } },
        { id = "dru-zep-tb-elder-rise", go = true, at = { 1456, 68.47, 28.24 }, radius = 15,
          note = {
              ru = "По мосту на восток, на Вершину Старейшин.",
              en = "Cross the bridge east to Elder Rise.",
          } },
        { id = "dru-zep-tb-train", train = true, optional = true, npc = 3033, at = { 1456, 76.48, 27.22 },
          spells = {
              { ru = "Телепортация: Лунная поляна (если нет)", en = "Teleport: Moonglade (if missing)" },
              { ru = "Восстановление, Исступление (если нет)", en = "Regrowth, Enrage (if missing)" },
          },
          note = { ru = "Тюрак Рунический Тотем. Нет «Телепортации: Лунная поляна» (нужна на 14-м) - заговорите с ним с зажатым Shift и "
                       .. "сначала откройте обучение. Всё есть - пропустите.",
                   en = "Turak Runetotem. No Teleport: Moonglade yet (needed at 14) - talk to him holding Shift and open the training "
                       .. "first. Everything known - skip." } },
        { id = "dru-zep-child", turnin = 94911, accept = 94913, npc = 3033, at = { 1456, 76.48, 27.22 },
          note = { ru = "Классовое задание: сдайте и возьмите «Лунную поляну» (сдадите на 14-м, из Подгорода). Нет «Телепортации: "
                       .. "Лунная поляна» - выучите у него же.",
                   en = "Druid class quest: turn in and take Moonglade (handed in at 14, from the Undercity). No Teleport: Moonglade "
                       .. "yet - learn it from him." } },
        { id = "dru-zep-tb-back", go = true, at = { 1456, 55.36, 35.55 }, radius = 15,
          note = {
              ru = "Обратно по мосту на центральную возвышенность.",
              en = "Back over the bridge to the central mesa.",
          } },
    },
})

------------------------------------------------------------------------------
-- 14: Teleport: Moonglade from the Undercity, right before the shared hearth to Orgrimmar
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h13-hearth-org",
    class = "DRUID",
    race = "Skyborne",
    steps = {
        { id = "dru-moonglade-94913", turnin = 94913, npc = 11802, at = { 1450, 56.21, 30.64 },
          note = {
              ru = "Из Подгорода - «Телепортация: Лунная поляна» (это и есть цель задания). "
                  .. "Dendrite Starblaze на севере Ночной Гавани.",
              en = "From the Undercity cast Teleport: Moonglade (that is the quest objective). Dendrite Starblaze "
                  .. "in the north of Nighthaven.",
          } },
    },
})
-- h13-hearth-org exists only in the routes of the four races that are bound in Orgrimmar (never an Undead druid).
FastesBoooy.AddLibraryInsert({
    before = "h13-hearth-org",
    class = "DRUID",
    race = { "Skyborne", "Tauren" },
    steps = {
        { id = "dru-train-14", train = true, npc = 12042, at = { 1450, 52.53, 40.57 },
          spells = {
              { ru = "Оглушить", en = "Bash" },
              { ru = "Гнев (ранг 3)", en = "Wrath (Rank 3)" },
              { ru = "Шипы (ранг 2)", en = "Thorns (Rank 2)" },
              { ru = "Целительное прикосновение (ранг 3)", en = "Healing Touch (Rank 3)" },
          },
          note = { ru = "Лунная поляна (из Подгорода - «Телепортация: Лунная поляна»; следующий шаг - камень). Логанаар: обучение "
                       .. "14-го уровня (главное - «Оглушить»).",
                   en = "Moonglade (from the Undercity cast Teleport: Moonglade; the next step is the hearthstone). Loganaar: level "
                       .. "14 training (Bash matters most)." } },
    },
})

------------------------------------------------------------------------------
-- 16: Teleport: Moonglade from the Witchwing harpies, right before the shared hearth to the Crossroads
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h15-hearth-xroads",
    class = "DRUID",
    steps = {
        { id = "dru-train-16", train = true, npc = 12042, at = { 1450, 52.53, 40.57 },
          spells = {
              { ru = "Размах", en = "Swipe" },
              { ru = "Лунный огонь (ранг 3)", en = "Moonfire (Rank 3)" },
              { ru = "Омоложение (ранг 3)", en = "Rejuvenation (Rank 3)" },
              { ru = "Заклинания 14-го уровня, если нет", en = "Level 14 spells if missing" },
          },
          note = { ru = "Следующий шаг - камень. «Телепортация: Лунная поляна» прямо от гарпий, Логанаар: обучение 16-го уровня "
                       .. "(главное - «Размах»). Таланты: Звериный инстинкт (Feral Instinct).",
                   en = "The next step is the hearthstone. Cast Teleport: Moonglade right at the harpies, Loganaar: level 16 training "
                       .. "(Swipe matters most). Talents: Feral Instinct." } },
    },
})

------------------------------------------------------------------------------
-- 18: Teleport: Moonglade from the Stagnant Oasis, right before the shared hearth to Camp Taurajo
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h18-hearth-taurajo",
    class = "DRUID",
    steps = {
        { id = "dru-train-18", train = true, npc = 12042, at = { 1450, 52.53, 40.57 },
          spells = {
              { ru = "Трепка (ранг 2)", en = "Maul (Rank 2)" },
              { ru = "Волшебный огонь", en = "Faerie Fire" },
              { ru = "Гнев деревьев (ранг 2)", en = "Entangling Roots (Rank 2)" },
              { ru = "Хватка природы (ранг 2)", en = "Nature's Grasp (Rank 2)" },
              { ru = "Восстановление (ранг 2)", en = "Regrowth (Rank 2)" },
              { ru = "Спячка", en = "Hibernate" },
          },
          note = { ru = "Следующий шаг - камень. «Телепортация: Лунная поляна» прямо у оазиса, Логанаар: обучение 18-го уровня "
                       .. "(главное - «Трепка» и «Волшебный огонь»). Таланты: Кошачья стремительность (Feline Swiftness).",
                   en = "The next step is the hearthstone. Cast Teleport: Moonglade right at the oasis, Loganaar: level 18 training "
                       .. "(Maul and Faerie Fire matter most). Talents: Feline Swiftness." } },
    },
})

------------------------------------------------------------------------------
-- 20, Skyborne: the Cat Form chain 98340 > 98341 > 98404 > 98738 > 98362 (Thunder Bluff 2)
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h18-tb-2",
    class = "DRUID",
    race = "Skyborne",
    steps = {
        { id = "dru-cat-start", accept = 98340, npc = 3033, at = { 1456, 76.48, 27.22 },
          note = { ru = "Тюрак Рунический Тотем на этой же вершине: «Великий дух кошки». Учиться пока не нужно - после облика кошки. "
                       .. "Предложит ещё и «Урок» (A Lesson to Learn, водный облик; по базе только для тауренов) - возьмите вручную: "
                       .. "сдача у Dendrite, «Испытание озера» там же (~1000 опыта).",
                   en = "Turak Runetotem on the same rise: The Great Cat Spirit. No training yet - after Cat Form. If he also offers "
                       .. "A Lesson to Learn (Aquatic Form; Tauren-only in the DB), take it by hand: it ends at Dendrite and Trial of "
                       .. "the Lake is in Moonglade too (~1000 XP)." } },
        { id = "dru-cat-dendrite", turnin = 98340, accept = 98341, npc = 11802, at = { 1450, 56.21, 30.64 },
          note = {
              ru = "«Телепортация: Лунная поляна». Dendrite Starblaze на севере Ночной Гавани.",
              en = "Cast Teleport: Moonglade. Dendrite Starblaze in the north of Nighthaven.",
          } },
        { id = "dru-cat-avatar", turnin = 98341, accept = 98404, npc = 272054, at = { 1450, 43.92, 73.44 },
          note = {
              ru = "На юг: Аватар Саэйлинан (дух кошки) у южного края поляны.",
              en = "South: the Avatar of Saeyleenan (the cat spirit) at the south end of the glade.",
          } },
        { id = "dru-cat-dens", go = true, at = { 1450, 72.15, 62.18 }, radius = 15,
          note = {
              ru = "На восток ко входу в Курганы Стражей Бури (Stormrage Barrow Dens).",
              en = "East to the entrance of the Stormrage Barrow Dens.",
          } },
        { id = "dru-cat-relics", complete = 98404, object = { 672821, 673094, 673093 }, at = { 1450, 74.0, 66.2 },
          note = {
              ru = "Вглубь пещеры и через мост: три реликвии у статуй кошек - Клык (72.4, 66.0), Безмолвная "
                  .. "тень (шар у статуи, 74.4, 65.4) и Коготь (ниша, 75.2, 67.2).",
              en = "Deep into the cave and over the bridge: three relics at the cat statues - the Fang (72.4, 66.0), "
                  .. "the Silent Shadow (the orb next to a statue, 74.4, 65.4) and the Claw (an alcove, 75.2, 67.2).",
          } },
        { id = "dru-cat-avatar-2", turnin = 98404, accept = 98738, npc = 272054, at = { 1450, 43.92, 73.44 },
          note = {
              ru = "Обратно к Аватару.",
              en = "Back to the Avatar.",
          } },
        { id = "dru-cat-dendrite-2", turnin = 98738, accept = 98362, npc = 11802, at = { 1450, 56.21, 30.64 },
          note = {
              ru = "Снова «Телепортация: Лунная поляна» - быстрее, чем пешком. Dendrite.",
              en = "Cast Teleport: Moonglade again - faster than walking. Dendrite.",
          } },
        { id = "dru-cat-hearth-tb", hearth = "Thunder Bluff", at = { 1456, 45.81, 64.71 },
          note = { ru = "Камень возвращения в Громовой Утёс (привязан шагом раньше; гайд использует его снова только из "
                       .. "Зорам'гара). Камень не готов - Бунтен Ветер Равнин (44.3, 45.9) летит в Громовой Утёс.",
                   en = "Hearth to Thunder Bluff (bound one step earlier; the guide uses it again only from Zoram'gar). "
                       .. "Hearthstone not ready - Bunthen Plainswind (44.3, 45.9) flies to Thunder Bluff." } },
        { id = "dru-cat-form", turnin = 98362, npc = 3033, at = { 1456, 76.48, 27.22 },
          note = {
              ru = "Через мост на Вершину Старейшин: Тюрак. Награда - облик кошки, «Цапнуть», «Разорвать» "
                  .. "и «Крадущийся зверь».",
              en = "Over the bridge to Elder Rise: Turak. The reward is Cat Form plus Claw, Rip and Prowl.",
          } },
    },
})
-- Registered after the chain: for a Skyborne the training follows the Cat Form turn-in at the same NPC.
FastesBoooy.AddLibraryInsert({
    after = "h18-tb-2",
    class = "DRUID",
    steps = {
        { id = "dru-train-20", train = true, npc = 3033, at = { 1456, 76.48, 27.22 },
          spells = {
              { ru = "Полоснуть", en = "Shred" },
              { ru = "Знамение ясности", en = "Omen of Clarity" },
              { ru = "Звёздный огонь", en = "Starfire" },
              { ru = "Деморализующий рёв (ранг 2)", en = "Demoralizing Roar (Rank 2)" },
              { ru = "Целительное прикосновение (ранг 4)", en = "Healing Touch (Rank 4)" },
              { ru = "Знак дикой природы (ранг 3)", en = "Mark of the Wild (Rank 3)" },
              { ru = "Возрождение", en = "Rebirth" },
          },
          note = { ru = "Тюрак Рунический Тотем на Вершине Старейшин: обучение 20-го уровня. «Цапнуть», «Разорвать» и «Крадущегося зверя» "
                       .. "даёт облик кошки (задание); у тренера главное - «Полоснуть» и «Знамение ясности». Таланты: Звериная атака "
                       .. "(Feral Charge). Дальше бегайте в облике кошки.",
                   en = "Turak Runetotem on Elder Rise: level 20 training. Claw, Rip and Prowl come with Cat Form (the quest); at the "
                       .. "trainer Shred and Omen of Clarity matter most. Talents: Feral Charge. Travel in Cat Form from now on." } },
    },
})

------------------------------------------------------------------------------
-- 22: Teleport: Moonglade from Zoram'gar, right before the shared hearth to Thunder Bluff
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h18-hearth-tb",
    class = "DRUID",
    steps = {
        { id = "dru-train-22", train = true, npc = 12042, at = { 1450, 52.53, 40.57 },
          spells = {
              { ru = "Гнев (ранг 4)", en = "Wrath (Rank 4)" },
              { ru = "Лунный огонь (ранг 4)", en = "Moonfire (Rank 4)" },
              { ru = "Омоложение (ранг 4)", en = "Rejuvenation (Rank 4)" },
              { ru = "Умиротворение животного", en = "Soothe Animal" },
          },
          note = { ru = "Следующий шаг - камень. «Телепортация: Лунная поляна» прямо из Зорам'гара, Логанаар: обучение 22-го уровня. "
                       .. "Таланты: Дикая ярость (Savage Fury).",
                   en = "The next step is the hearthstone. Cast Teleport: Moonglade right at Zoram'gar, Loganaar: level 22 training. "
                       .. "Talents: Savage Fury." } },
    },
})

------------------------------------------------------------------------------
-- 24: Thunder Bluff (Turak)
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h-24-tb-arrive",
    class = "DRUID",
    steps = {
        { id = "dru-train-24", train = true, npc = 3033, at = TURAK,
          spells = {
              { ru = "Свирепый укус", en = "Ferocious Bite" },
              { ru = "Глубокая рана", en = "Rake" },
              { ru = "Размах (2), Восстановление (3), Шипы (3) - по желанию", en = "Swipe (2), Regrowth (3), Thorns (3) - optional" },
          },
          note = {
              ru = "Через мосты на Вершину Старейшин: Тюрак Рунический Тотем - обучение 24-го уровня (главное - "
                  .. "«Свирепый укус» и «Глубокая рана»). Таланты 23-24: Острые когти (Sharpened Claws) 2/2.",
              en = "Over the bridges to Elder Rise: Turak Runetotem - level 24 training (Ferocious Bite and Rake matter "
                  .. "most). Talents 23-24: Sharpened Claws 2/2.",
          } },
    },
})

------------------------------------------------------------------------------
-- 26 + 28: Thunder Bluff (Turak), back from Skywatcher Plateau
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h-28-thunder-bluff",
    class = "DRUID",
    steps = {
        { id = "dru-train-28", train = true, npc = 3033, at = TURAK,
          spells = {
              { ru = "Когти (2)", en = "Claw (Rank 2)" },
              { ru = "Разорвать (2)", en = "Rip (Rank 2)" },
              { ru = "Порыв", en = "Dash" },
              { ru = "Трепка (3)", en = "Maul (Rank 3)" },
              { ru = "Омоложение (5)", en = "Rejuvenation (Rank 5)" },
          },
          note = {
              ru = "Наверху - сначала на Вершину Старейшин: Тюрак, обучение 26-го и 28-го уровней (главное - «Когти» "
                  .. "и «Разорвать»). Ещё нет 28-го - выучите 26-й, остальное на 30-м. Таланты 25-28: Удары хищника "
                  .. "(Predatory Strikes) 3/3, Blood Frenzy 1/2.",
              en = "At the top go to Elder Rise first: Turak, level 26 and 28 training (Claw and Rip matter most). Not "
                  .. "28 yet: learn the 26 spells, the rest at 30. Talents 25-28: Predatory Strikes 3/3, Blood Frenzy "
                  .. "1/2.",
          } },
    },
})

------------------------------------------------------------------------------
-- 30: Thunder Bluff (Turak, next to Magatha): Travel Form
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h-31-tb-end",
    class = "DRUID",
    steps = {
        { id = "dru-train-30", train = true, npc = 3033, at = TURAK,
          spells = {
              { ru = "Походный облик", en = "Travel Form" },
              { ru = "Полоснуть (2)", en = "Shred (Rank 2)" },
              { ru = "Знак дикой природы (4)", en = "Mark of the Wild (Rank 4)" },
              { ru = "Восстановление (4)", en = "Regrowth (Rank 4)" },
              { ru = "Оглушить (2), Волшебный огонь (2) - по желанию", en = "Bash (2), Faerie Fire (2) - optional" },
          },
          note = {
              ru = "Рядом с Магатой: Тюрак - обучение 30-го уровня, ПОХОДНЫЙ ОБЛИК (+40% к скорости на открытой "
                  .. "местности: дальше передвигайтесь в нём). Таланты 29-31: Blood Frenzy 2/2, Вожак стаи (Leader of "
                  .. "the Pack), Natural Instinct 1/2.",
              en = "Next to Magatha: Turak - level 30 training, TRAVEL FORM (+40% speed outdoors: travel in it from now "
                  .. "on). Talents 29-31: Blood Frenzy 2/2, Leader of the Pack, Natural Instinct 1/2.",
          } },
    },
})

------------------------------------------------------------------------------
-- 32: Teleport: Moonglade from Tarren Mill, hearth back
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h-33-tarrenmill-end",
    class = "DRUID",
    steps = {
        { id = "dru-train-32", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Свирепый укус (2)", en = "Ferocious Bite (Rank 2)" },
              { ru = "Собранность", en = "Poised" },
              { ru = "Накинуться, Деморализующий рёв (3) - по желанию", en = "Ravage, Demoralizing Roar (3) - optional" },
          },
          note = {
              ru = "«Телепортация: Лунная поляна» прямо в Мельнице Таррен. Логанаар: обучение 32-го уровня (главное - "
                  .. "«Свирепый укус» 2 и «Собранность»). Ещё нет 32-го - выучите, что есть, остальное на 36-м. "
                  .. "Таланты 32: Natural Instinct 2/2.",
              en = "Cast Teleport: Moonglade right in Tarren Mill. Loganaar: level 32 training (Ferocious Bite 2 and "
                  .. "Poised matter most). Not 32 yet: learn what is offered, the rest at 36. Talents 32: Natural "
                  .. "Instinct 2/2.",
          } },
        { id = "dru-hearth-32", hearth = "Tarren Mill", at = { 1424, 62.78, 19.03 },
          note = {
              ru = "Камень возвращения в Мельницу Таррен (привязан на 31-м и с тех пор не использовался). Дальше - на "
                  .. "юго-восток к Стене Торадина.",
              en = "Hearth to Tarren Mill (bound at 31 and unused since). Then south-east to Thoradin's Wall.",
          } },
    },
})

------------------------------------------------------------------------------
-- 34 + 36: Moonglade right before the library hearth to Shadowprey Village
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h38-hearth-shadowprey",
    class = "DRUID",
    steps = {
        { id = "dru-train-36", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Разорвать (3)", en = "Rip (Rank 3)" },
              { ru = "Глубокая рана (2)", en = "Rake (Rank 2)" },
              { ru = "Неистовое восстановление", en = "Frenzied Regeneration" },
              { ru = "Трепка (4), Размах (3)", en = "Maul (Rank 4), Swipe (Rank 3)" },
              { ru = "Восстановление (5), Омоложение (6)", en = "Regrowth (Rank 5), Rejuvenation (Rank 6)" },
          },
          note = {
              ru = "Следующий шаг - камень. Камень готов: «Телепортация: Лунная поляна», Логанаар - обучение 34-го и "
                  .. "36-го уровней (главное - «Разорвать» 3 и «Глубокая рана» 2; пропущенное на 32-м - тоже). Камень "
                  .. "на откате - пропустите (выучите на 40-м). Таланты 33-37: Predatory Discipline, Гнев (Furor) 1/5, "
                  .. "Rend and Tear 3/5.",
              en = "The next step is the hearthstone. If it is ready: cast Teleport: Moonglade, Loganaar - level 34 and "
                  .. "36 training (Rip 3 and Rake 2 matter most; anything missed at 32 too). Hearthstone on cooldown: "
                  .. "skip (learn it at 40). Talents 33-37: Predatory Discipline, Furor 1/5, Rend and Tear 3/5.",
          } },
    },
})

------------------------------------------------------------------------------
-- 38 + 40: fly Thunder Bluff (Turak): Dire Bear Form (contract ids of docs/dev/PLAN.md C.7)
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h-40-org-arrive",
    class = "DRUID",
    steps = {
        { id = "dru-40-fly-tb", fly = "Thunder Bluff", npc = 2995, at = { 1456, 47.00, 49.83 },
          note = {
              ru = "Дорас на башне в Долине Силы: летите в Громовой Утёс (обучение 40-го). В Лагерь Таурахо "
                  .. "полетите уже оттуда.",
              en = "Doras on the tower in the Valley of Strength: fly to Thunder Bluff (level 40 training). You fly on "
                  .. "to Camp Taurajo from there.",
          } },
        { id = "dru-40-train", train = true, npc = 3033, at = TURAK,
          spells = {
              { ru = "Облик лютого медведя", en = "Dire Bear Form" },
              { ru = "Свирепый укус (3)", en = "Ferocious Bite (Rank 3)" },
              { ru = "Когти (3), Полоснуть (3)", en = "Claw (Rank 3), Shred (Rank 3)" },
              { ru = "Крадущийся зверь (2), Кошачья грация", en = "Prowl (Rank 2), Feline Grace" },
              { ru = "Знак дикой природы (5), Озарение", en = "Mark of the Wild (Rank 5), Innervate" },
          },
          note = {
              ru = "Через мосты на Вершину Старейшин: Тюрак - обучение 38-го и 40-го уровней: ОБЛИК ЛЮТОГО МЕДВЕДЯ, "
                  .. "«Свирепый укус» 3, «Когти» 3, «Полоснуть» 3. Ещё нет 40-го - выучите 38-й («Когти» 3, "
                  .. "«Полоснуть» 3): облик лютого медведя и остальное - на следующем визите к Логанаару. Таланты "
                  .. "38-40: Rend and Tear 5/5, Переходящая сила (Shifting Power).",
              en = "Over the bridges to Elder Rise: Turak - level 38 and 40 training: DIRE BEAR FORM, Ferocious Bite 3, "
                  .. "Claw 3, Shred 3. Not 40 yet: learn the 38 set (Claw 3, Shred 3): Dire Bear Form and the rest at "
                  .. "the next Loganaar visit. Talents 38-40: Rend and Tear 5/5, Shifting Power.",
          } },
        -- The next library step (h-38-orgrimmar-flight-master) is the same flight, written for Orgrimmar ("Doras"):
        -- this step says it from Tal, and the library step completes on the same landing (fly = arrival at `at`).
        { id = "dru-40-fly-taurajo", fly = "Camp Taurajo", npc = 10378, at = { 1413, 44.45, 59.15 },
          note = {
              ru = "Тал на центральной вершине Громового Утёса (не Дорас: вы не в Оргриммаре): летите в Лагерь "
                  .. "Таурахо.",
              en = "Tal on the central mesa of Thunder Bluff (not Doras: you are not in Orgrimmar): fly to Camp "
                  .. "Taurajo.",
          } },
    },
})

------------------------------------------------------------------------------
-- 42 + 44: Moonglade right before the library hearth to Grom'gol (Swamp of Sorrows)
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h44-hearth-gromgol",
    class = "DRUID",
    steps = {
        { id = "dru-train-44", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Глубокая рана (3)", en = "Rake (Rank 3)" },
              { ru = "Разорвать (4)", en = "Rip (Rank 4)" },
              { ru = "Дубовая кожа", en = "Barkskin" },
              { ru = "Трепка (5), Размах (4)", en = "Maul (Rank 5), Swipe (Rank 4)" },
              { ru = "Восстановление (6)", en = "Regrowth (Rank 6)" },
          },
          note = {
              ru = "Следующий шаг - камень. Камень готов: «Телепортация: Лунная поляна», Логанаар - обучение 42-го и "
                  .. "44-го уровней (главное - «Глубокая рана» 3 и «Разорвать» 4). Камень на откате - пропустите "
                  .. "(выучите на 48-м). Таланты 41-44: Сердце дикой природы (Heart of the Wild) 4/5.",
              en = "The next step is the hearthstone. If it is ready: cast Teleport: Moonglade, Loganaar - level 42 and "
                  .. "44 training (Rake 3 and Rip 4 matter most). Hearthstone on cooldown: skip (learn it at 48). "
                  .. "Talents 41-44: Heart of the Wild 4/5.",
          } },
    },
})

------------------------------------------------------------------------------
-- 46 + 48: Camp Mojache (Jannos Lighthoof)
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h-50-mojache-end",
    class = "DRUID",
    steps = {
        { id = "dru-train-48", train = true, npc = 8142, at = { 1444, 75.99, 42.28 },
          spells = {
              { ru = "Когти (4)", en = "Claw (Rank 4)" },
              { ru = "Свирепый укус (4)", en = "Ferocious Bite (Rank 4)" },
              { ru = "Полоснуть (4), Порыв (2)", en = "Shred (Rank 4), Dash (Rank 2)" },
              { ru = "Оглушить (3)", en = "Bash (Rank 3)" },
              { ru = "Восстановление (7), Омоложение (8)", en = "Regrowth (Rank 7), Rejuvenation (Rank 8)" },
          },
          note = {
              ru = "В лагере: Джаннос Легкое Копыто - обучение 46-го и 48-го уровней (главное - «Когти» 4 и "
                  .. "«Свирепый укус» 4). Таланты 45-49: Сердце дикой природы (Heart of the Wild) 5/5, Натуралист "
                  .. "(Naturalist) 4/5.",
              en = "In the camp: Jannos Lighthoof - level 46 and 48 training (Claw 4 and Ferocious Bite 4 matter most). "
                  .. "Talents 45-49: Heart of the Wild 5/5, Naturalist 4/5.",
          } },
    },
})

------------------------------------------------------------------------------
-- 50 + 52: Moonglade right before the library hearth to Orgrimmar (Azshara); accept 9063
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h54-hearth-org",
    class = "DRUID",
    steps = {
        -- 9063 is only a breadcrumb of 9052 (DB: breadcrumbFor = 9052, 9052 has no prerequisite): optional here and
        -- at Torwa, so a skipped visit does not block the chain. The accept comes before the training step: an accept
        -- after it at the same NPC would make the engine forward the training before the trainer window opens.
        { id = "dru-accept-9063", accept = 9063, optional = true, npc = 12042, at = LOGANAAR,
          note = {
              ru = "Следующие шаги - обучение и камень. Камень готов: «Телепортация: Лунная поляна», Логанаар - задание "
                  .. "друидов «Землепроходец Торва» (к нему в кратер Ун'Горо). Камень на откате - пропустите этот и "
                  .. "следующий шаг (обучение на 54-м; Торва даст своё задание и без этого).",
              en = "Next: the training and the hearthstone. If it is ready: cast Teleport: Moonglade, Loganaar - the "
                  .. "druid quest Torwa Pathfinder (to him in Un'Goro Crater). Hearthstone on cooldown: skip this and the "
                  .. "next step (train at 54; Torwa gives his quest without it too).",
          } },
        { id = "dru-train-52", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Разорвать (5)", en = "Rip (Rank 5)" },
              { ru = "Трепка (6)", en = "Maul (Rank 6)" },
              { ru = "Знак дикой природы (6)", en = "Mark of the Wild (Rank 6)" },
              { ru = "Омоложение (9)", en = "Rejuvenation (Rank 9)" },
          },
          note = {
              ru = "Логанаар: обучение 50-го и 52-го уровней (главное - «Разорвать» 5). Таланты 50-53: Натуралист "
                  .. "(Naturalist) 5/5, Genesis 3/5.",
              en = "Loganaar: level 50 and 52 training (Rip 5 matters most). Talents 50-53: Naturalist 5/5, Genesis "
                  .. "3/5.",
          } },
    },
})

------------------------------------------------------------------------------
-- Torwa Pathfinder (Un'Goro): 9063 > 9052 Bloodpetal Poison > 9051 Toxic Test
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h-53-torwa-pathfinder",
    class = "DRUID",
    steps = {
        { id = "dru-torwa-9063", turnin = 9063, optional = true, npc = 9619, at = { 1449, 71.64, 75.96 },
          note = {
              ru = "Если брали в Лунной поляне: сдайте ему «Землепроходца Торву».",
              en = "If you took it in Moonglade: turn in Torwa Pathfinder to him.",
          } },
        { id = "dru-torwa-9052", accept = 9052, npc = 9619, at = { 1449, 71.64, 75.96 },
          note = {
              ru = "У него же задание друидов «Яд кровоцвета»: 8 кровошляпочников и 8 жал Гориши.",
              en = "From him too, the druid quest Bloodpetal Poison: 8 Bloodcaps and 8 Gorishi Stings.",
          } },
        { id = "dru-bloodcap", complete = { [9052] = { 2 } }, bg = true, object = 164958, at = { 1449, 66.43, 32.87 },
          note = {
              ru = "Попутно по всему кратеру: 8 кровошляпочников с побегов кровоцвета (маленькие красные растения).",
              en = "On the way all over the crater: 8 Bloodcaps from Bloodpetal Sprouts (small red plants).",
          } },
    },
})
FastesBoooy.AddLibraryInsert({
    before = "h54-torwa-3",
    class = "DRUID",
    steps = {
        { id = "dru-gorishi-stings", complete = 9052, at = { 1449, 53.68, 76.31 },
          note = {
              ru = "От плота на запад к краю улья Гориши: осы и рабочие из улья (51-52) - 8 жал Гориши. Доберите "
                  .. "кровошляпочники, затем на восток к Торве.",
              en = "From the raft west to the edge of the Gorishi hive: Gorishi Wasps and Workers (51-52) - 8 Gorishi "
                  .. "Stings. Finish the Bloodcaps, then east to Torwa.",
          } },
    },
})
FastesBoooy.AddLibraryInsert({
    after = "h54-torwa-3",
    class = "DRUID",
    steps = {
        { id = "dru-torwa-9051", turnin = 9052, accept = 9051, npc = 9619, at = { 1449, 71.64, 75.96 },
          note = {
              ru = "Торва: «Яд кровоцвета», возьмите «Испытание яда» (шип девизавра - в сумке).",
              en = "Torwa: Bloodpetal Poison; take Toxic Test (the Devilsaur Barb goes into your bags).",
          } },
        { id = "dru-devilsaur", complete = 9051, bg = true, use = 22432, at = { 1449, 31.19, 36.42 },
          note = {
              ru = "Попутно во 2-й петле: девизавры (элита 54-56) бродят на западе (31, 36; к северу от горячих "
                  .. "источников) и в центре (50, 61). Подкрадитесь, уколите шипом девизавра и уходите (Порыв, "
                  .. "походный облик) - убивать не нужно.",
              en = "On the way in loop 2: Devilsaurs (elite 54-56) roam the west (31, 36; north of the hot springs) and "
                  .. "the centre (50, 61). Sneak up, stab one with the Devilsaur Barb and get away (Dash, Travel Form) - "
                  .. "no kill needed.",
          } },
    },
})
FastesBoooy.AddLibraryInsert({
    after = "h55-torwa-end",
    class = "DRUID",
    steps = {
        { id = "dru-torwa-end", turnin = 9051, npc = 9619, at = { 1449, 71.64, 75.96 },
          note = {
              ru = "Торва: «Испытание яда». «Лучший ингредиент» (Затонувший храм) не берите.",
              en = "Torwa: Toxic Test. Skip A Better Ingredient (Sunken Temple).",
          } },
    },
})

------------------------------------------------------------------------------
-- 54: Moonglade right before the library hearth to Gadgetzan (start of h-56)
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h56-hearth-gadgetzan",
    class = "DRUID",
    steps = {
        { id = "dru-train-54", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Глубокая рана (4)", en = "Rake (Rank 4)" },
              { ru = "Полоснуть (5)", en = "Shred (Rank 5)" },
              { ru = "Восстановление (8)", en = "Regrowth (Rank 8)" },
              { ru = "Размах (5)", en = "Swipe (Rank 5)" },
          },
          note = {
              ru = "Следующий шаг - камень. Камень готов: «Телепортация: Лунная поляна», Логанаар - обучение 54-го "
                  .. "уровня (и 50-52-го, если пропустили). Камень на откате - пропустите (выучите на 56-м). Таланты "
                  .. "54-55: Genesis 5/5.",
              en = "The next step is the hearthstone. If it is ready: cast Teleport: Moonglade, Loganaar - level 54 "
                  .. "training (and 50-52 if you missed it). Hearthstone on cooldown: skip (learn it at 56). Talents "
                  .. "54-55: Genesis 5/5.",
          } },
    },
})

------------------------------------------------------------------------------
-- 56: Moonglade right before the library hearth to Orgrimmar (Felwood)
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h-58-org-arrive",
    class = "DRUID",
    steps = {
        { id = "dru-train-56", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Свирепый укус (5)", en = "Ferocious Bite (Rank 5)" },
              { ru = "Наскок (3), Целительное прикосновение (10) - по желанию",
                en = "Pounce (3), Healing Touch (10) - optional" },
          },
          note = {
              ru = "Следующий шаг - камень. Камень готов: «Телепортация: Лунная поляна», Логанаар - обучение 56-го "
                  .. "уровня («Свирепый укус» 5; и 54-го, если пропустили). Камень на откате - пропустите (выучите на "
                  .. "60-м). Таланты 56-57: Прирожденный оборотень (Natural Shapeshifter) 2/3.",
              en = "The next step is the hearthstone. If it is ready: cast Teleport: Moonglade, Loganaar - level 56 "
                  .. "training (Ferocious Bite 5; and 54 if you missed it). Hearthstone on cooldown: skip (learn it at "
                  .. "60). Talents 56-57: Natural Shapeshifter 2/3.",
          } },
    },
})

------------------------------------------------------------------------------
-- 58 + 60: Moonglade at the end of the route
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h-60-end",
    class = "DRUID",
    steps = {
        { id = "dru-train-60", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Когти (5), Трепка (7)", en = "Claw (Rank 5), Maul (Rank 7)" },
              { ru = "Разорвать (6), Свирепый укус (6)", en = "Rip (Rank 6), Ferocious Bite (Rank 6)" },
              { ru = "Крадущийся зверь (3)", en = "Prowl (Rank 3)" },
              { ru = "Знак дикой природы (7), Восстановление (9)", en = "Mark of the Wild (Rank 7), Regrowth (Rank 9)" },
          },
          note = {
              ru = "«Телепортация: Лунная поляна», Логанаар: обучение 58-го и 60-го уровней. Таланты 58-60: "
                  .. "Прирожденный оборотень (Natural Shapeshifter) 3/3, Nature's Majesty 2/2. Конец маршрута 1-60.",
              en = "Cast Teleport: Moonglade, Loganaar: level 58 and 60 training. Talents 58-60: Natural Shapeshifter "
                  .. "3/3, Nature's Majesty 2/2. End of the 1-60 route.",
          } },
    },
})
