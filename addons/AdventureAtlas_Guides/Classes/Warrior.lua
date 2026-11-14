-- AdventureAtlas_Guides / Classes / Warrior.lua
--
-- Every step that exists because of the class (warrior), for all five races of the class (orc-, troll-, tauren-,
-- undead-, skyborne-warrior), as shared inserts with class = "WARRIOR" (step ids "war-<zone>-..." below level 12
-- with the zone tags dur / mul / tir / zep, "war-..." on the shared path). Every insert is anchored on a generic
-- step with an explicit id; the inserted steps belong to the anchor's segment.
-- Sources: docs/dev/research/classes.md (3, 4, 5.1, 5.10, 6.1, appendix A.WARRIOR); trainer NPCs, quest ids,
-- chains, race masks, objects and coordinates: tools/data/forever_db.lua; levels: docs/dev/handover/levels-<race>.tsv
-- and `validate_routes.lua --levels` (validator level before the step, normal / worst case where they differ;
-- the numbers below are those of this file's routes).
--
-- Start zones (one group per zone, race-scoped):
--   Durotar (Orc, Troll)
--     after dur01-teeth          2.1   letter 2383 (Orc) / 3065 (Troll): Gornek > Frang; training 1 (Battle Shout)
--     after dur01-den-4          4.7   Frang (Valley of Trials): training 4 (Charge, Rend)
--     after dur02-rh-1           6.5   Tarshaw Jaggedscar (Razor Hill): training 6
--     after dur02-rh-3          10.0   Tarshaw: 1505 Veteran Uzzek + training 8 and 10 (7.7 at dur02-rh-2: no 8 yet)
--     after dur02-crocs         10.8   Path of Defense, variant of PLAN C.2: from the river (the crocolisks) over to
--                                      Far Watch Post: 1505 > 1498 at Uzzek, back to Thunder Ridge (~1,350 yd, ~3 min)
--     after dur02-thunder-ridge 10.8   the 5 Singed Scales drop from the same lizards the shared step kills
--                                      (97282); 1498 is turned in at h15-far-watch (14.3). The default of C.2 (the
--                                      whole chain from h15-far-watch) costs ~1,750 yd plus dedicated kills at 14.
--   Mulgore (Tauren)
--     after mul01-hunt           3.0   letter 3091: Grull Hawkwind > Harutt Thunderhorn; training 1
--     after mul01-ravine         4.0   Harutt: training 4
--     after mul02-krang          6.5   Krang Stonehoof (Bloodhoof): training 6, right after his 99108
--     after mul02-bh-3           8.8   Krang: training 8
--     after mul02-bh-4          10.1   Krang: 1505 + training 10
--     after mul03-far-watch     12.0   Uzzek: 1505 > 1498; the scales at Thunder Ridge, which is ~75 yd off the
--                                      line Far Watch Post > Orgrimmar gate the Tauren walk anyway; turned in at
--                                      h15-far-watch (14.5)
--   Tirisfal (Undead)
--     after ud01-364             2.4   letter 3095: Sarvis > Dannal Stern (house across the road); training 1
--     after ud01-aramis          4.0   Dannal: training 4
--     after ud02-sethearth       6.4   Austil de Mon (in the Brill inn): training 6
--     after ud02-brill-8         8.2   Austil: training 8
--     after ud02-level-10       10.2   Austil: 1818 + training 10; Dillinger 1818 > 1819 (Ulag the Cleaver in the
--                                      mausoleum north of Brill) > 1820 > Coleman: DEFENSIVE STANCE (1819) and
--                                      1820 mandatory (all inside Brill); 1821 > 1822 (Agamand weapon racks,
--                                      ~880 yd north, 1,540 XP and a weapon) optional: a detour over 3 minutes
--     after ud02-hearth-2       12.0   Austil: training 12 (the hearth lands in the inn)
--   Zephras Isle (Skyborne)
--     after sd01-rorian          2.8   letter 92532: Rorian > Blademaster Ren; training 1
--     after sd01-thendal-4       4.7   Ren: training 4
--     after sd01-raan-2          6.2   Corsan Earthrazer (Shen'dar): training 6
--     after sd01-danarii-2       8.9   Corsan (next to Danarii): training 8
--     after sd02-valanaar-10    11.2   Seena Skybreaker (Valanaar): 94003 + training 10
--     after sd02-parts-gyrozephyr 11.4 Zaal Stormshield (L10, east of the shared Construct Parts): the Bulwark
--     after sd02-nyalah-2       12.9   Seena: 94003 turned in (DEFENSIVE STANCE, classes.md 7) + training 12
--     The Skyborne do not take 1498 (their stance comes from 94003) and so cannot take 1502 / 1503 either.
--
-- Shared path, training (warrior trainers in all three capitals and in Stonard: no gap, classes.md 4.3). One visit
-- per two levels where the path is in a city anyway; level before the visit (normal / worst):
--   12      after h12-fp-uc          Orc/Troll/Tauren 12.4 / 12.3, 13.0 / 12.9  Undercity War Quarter (between the
--                                    flight master and the sewers exit: ~180 yd extra)
--   14      after h13-uc-end         14.1-15.4   Undercity War Quarter, before the shared hearth
--   16      -                        no city at 16 (B.9): merged into 18
--   18      after h18-tb-1           18.1-18.7   Thunder Bluff, Hunter Rise (Torm Ragetotem), ~1.3 min
--   20      after h18-sethearth-tb   20.4 / 20.3 Torm, 200 yd from the inn: 1823 (breadcrumb to Ruga) + training
--   22+24   after h-24-tb-hearth     24.8 / 24.0 Torm (the 22 ranks alone are not worth the h18-hearth-tb visit);
--                                    Two-Handed Maces at Ansekhwa next to the inn (optional, for 893)
--   26+28   after h-28-hearth-tb     28.3 / 27.9 Torm: Hunter Rise is the next shared stop (Melor), no detour
--   30      after h30-tb-1131        30.9        Torm (Melor's turn-in is next to him): 1718 + training 30
--   32+34   after h-34-uc-arrive     34.1        Undercity War Quarter, ~1 min
--   36      after h-37-org-arrive    36.1        Orgrimmar, Valley of Honor: WHIRLWIND, ~2 min
--   38+40   after h-40-org-arrive    40.0 / 40.0 Valley of Honor (40 normally reached; in the worst case the 40 ranks
--                                    wait for 42); Two-Handed Axes at Hanashi next door (optional)
--   42+44   after h-44-stonard-arrive 44.0       Malosh in Stonard, by the west entrance (Dar): no detour
--   46+48   after h49-org-2976       49.5        Valley of Honor, next to Belgrom: no detour
--   50      after h51-stonard-2622   51.8 / 51.6 Malosh next to Bengor: no detour
--   52      after h53-org-3507       53.1 / 53.0 Valley of Honor, next to Belgrom: no detour
--   54+56   after h-58-uc-arrive     57.2        Undercity War Quarter, ~1 min
--   58+60   after h-60-end           60          optional: hearth to the Undercity (bound at h-58-uc-arrive), train
-- Skipped visits: 16 (no city), 22 (Battle Shout / Intimidating Shout only), 38, 46, 54 on their own.
--
-- Shared path, class quests:
--   after h15-far-watch      14.3-14.6   Uzzek: 1498 turned in (Orc, Troll, Tauren; Undead come with 1819), 1502 >
--                                        Thun'grim Firegaze > 1503 Stolen Iron Chest > Thun'grim (1,050 XP, a
--                                        weapon), ~800 yd on the way to the Crossroads (mandatory, under 3 min)
--   after h-24-camp-taurajo  24.9 / 24.1 Ruga Ragetotem: 1823 > 1824 (Twitching Antennae from the silithids of the
--                                        Field of Giants, which the shared path crosses for 868 anyway)
--   before h-25-fly-ratchet  25.6 / 24.8 Ruga: 1824 > 1825 (2,330 XP for the two)
--   after h-26-cholaruk      26.0        1825 at Thun'grim: he stands by the road ~300 yd below Chol'aruk's hill
--                                        (780 XP for ~1 minute; the anchor id was added in phase R)
--   before h-31-org          31.0        BERSERKER STANCE: fly Camp Taurajo > Ratchet, swim to Fray Island, 1718 >
--                                        1719 The Affray (waves, then Big Will L33), back to Ratchet; the shared
--                                        next step flies to Orgrimmar from there (~8 min, 3,060 XP)
--   after h-51-swamp-of-sorrows-3 51.9   Fallen Hero: 8423 Warrior Kinship (no breadcrumb needed): 7 Helboars,
--                                        which the Blasted Lands gate kills anyway
--   after h-53-blastedlands-end 52.5     8423 turned in (5,100 XP): the Fallen Hero stands ~120 yd from the
--                                        Bloodmages; the shared next steps (optional Stonard, hearth) work from there
-- Not routed: the Brutal armour chain 1838+ (Razorfen Kraul drop), the Whirlwind weapon chain 1791 > 1712 / 1714 >
--   1713 > 1792 (24 charms through the repeatable cauldron child quest 1714, 8 Liferoot without Herbalism, 30
--   Bloodscalp Tusks, an elite L40, two Alterac detours: see the hand-over c-warrior.md), 8417 (no capital stop at
--   50+ before the Fallen Hero), 8424 / 8425 (50 Shadowsworn, Sunken Temple), 1498 for the Skyborne (detour for
--   1,050 XP at 15), the level-58+ quests.
-- Class reward table: none. The DB has no reward lists, so the index of a warrior's choice is unknown; the notes of
--   the class steps name the items instead (CONFIRM the indexes in game, then AdventureAtlas.AddLibraryData).
-- Automation: every `train` step follows the quest steps at the same trainer (look-ahead rule); no inserted
--   transient step stands before a quest step that can already be complete; the hearthstone is used only after
--   h-60-end (optional).

if not AdventureAtlas.AddLibraryInsert then return end
local insert = AdventureAtlas.AddLibraryInsert

-- Trainers (DB spawns)
local FRANG = { 1411, 42.89, 69.44 }      -- 3153, Valley of Trials (teaches up to 6)
local TARSHAW = { 1411, 54.19, 42.47 }    -- 3169, Razor Hill
local HARUTT = { 1412, 43.75, 76.72 }     -- 3059, Camp Narache (teaches up to 6)
local KRANG = { 1412, 48.35, 63.74 }      -- 3063, Bloodhoof Village
local DANNAL = { 1420, 32.69, 65.56 }     -- 2119, Deathknell (teaches up to 6)
local AUSTIL = { 1420, 61.85, 52.54 }     -- 2131, Brill (in the inn)
local REN = { 2521, 43.65, 24.11 }        -- 251964, Thendal (teaches up to 6)
local CORSAN = { 2521, 44.95, 45.10 }     -- 254088, Shen'dar
local SEENA = { 2521, 59.89, 72.87 }      -- 252377, Valanaar
local TORM = { 1456, 57.24, 87.37 }       -- 3041, Thunder Bluff, Hunter Rise
local GREZZ = { 1454, 79.79, 31.42 }      -- 3353, Orgrimmar, Valley of Honor
local CHRISTOPH = { 1458, 46.93, 15.23 }  -- 4593, Undercity, War Quarter
local MALOSH = { 1435, 44.89, 57.62 }     -- 985, Stonard
-- Quest NPCs
local UZZEK = { 1413, 61.38, 21.12 }      -- 5810, Far Watch Post
local THUNGRIM = { 1413, 57.23, 30.34 }   -- 5878
local RUGA = { 1413, 44.67, 59.42 }       -- 6394, Camp Taurajo
local KLANNOC = { 1413, 68.62, 49.16 }    -- 6236, Fray Island
local THUNDER_RIDGE = { 1411, 41.0, 26.6 } -- Thunder Lizard 3130 / Lightning Hide 3131
local FALLEN_HERO = { 1435, 34.29, 66.14 } -- 7572

------------------------------------------------------------------------------------------------------------------
-- Durotar (Orc, Troll)
------------------------------------------------------------------------------------------------------------------
insert({
    after = "dur01-teeth",
    class = "WARRIOR",
    race = { "Orc", "Troll" },
    steps = {
        { id = "war-dur-letter-orc", race = "Orc", accept = 2383, npc = 3143, at = { 1411, 42.06, 68.33 },
          note = { ru = "Горнек даёт и письмо воина: «Simple Parchment». Тренер воинов Frang стоит у входа в Логово.",
                   en = "Gornek also gives the warrior's letter: Simple Parchment. The warrior trainer Frang stands "
                       .. "at the Den entrance." } },
        { id = "war-dur-letter-troll", race = "Troll", accept = 3065, npc = 3143, at = { 1411, 42.06, 68.33 },
          note = { ru = "Горнек даёт и письмо воина: «Simple Tablet». Тренер воинов Frang стоит у входа в Логово.",
                   en = "Gornek also gives the warrior's letter: Simple Tablet. The warrior trainer Frang stands "
                       .. "at the Den entrance." } },
        { id = "war-dur-frang-orc", race = "Orc", turnin = 2383, npc = 3153, at = FRANG,
          note = { ru = "Frang у входа в Логово: сдайте письмо.",
                   en = "Frang at the Den entrance: turn in the letter." } },
        { id = "war-dur-frang-troll", race = "Troll", turnin = 3065, npc = 3153, at = FRANG,
          note = { ru = "Frang у входа в Логово: сдайте письмо.",
                   en = "Frang at the Den entrance: turn in the letter." } },
        { id = "war-dur-train-1", train = true, npc = 3153, at = FRANG,
          spells = { { ru = "Боевой крик", en = "Battle Shout" } },
          note = { ru = "Выучите «Боевой крик» (10 меди) и держите его на себе. Ярость копится от ударов: "
                       .. "«Удар героя» жмите, когда ярости больше 15-20.",
                   en = "Learn Battle Shout (10 copper) and keep it up. Rage comes from hitting: press Heroic Strike "
                       .. "when you have more than 15-20 rage." } },
    },
})
insert({
    after = "dur01-den-4",
    class = "WARRIOR",
    race = { "Orc", "Troll" },
    steps = {
        { id = "war-dur-train-4", train = true, npc = 3153, at = FRANG,
          spells = { { ru = "Рывок", en = "Charge" }, { ru = "Кровопускание", en = "Rend" } },
          note = { ru = "Frang рядом с Зуриттой. Уровень 4: «Рывок» (бой начинайте с него: ярость сразу) и "
                       .. "«Кровопускание».",
                   en = "Frang next to Zureetha. Level 4: Charge (open every fight with it: instant rage) and Rend." } },
    },
})
insert({
    after = "dur02-rh-1",
    class = "WARRIOR",
    race = { "Orc", "Troll" },
    steps = {
        { id = "war-dur-train-6", train = true, npc = 3169, at = TARSHAW,
          spells = { { ru = "Удар грома", en = "Thunder Clap" } },
          note = { ru = "Таршо Зубчатый Шрам — тренер воинов рядом с Турроком. Уровень 6: «Удар грома».",
                   en = "Tarshaw Jaggedscar, the warrior trainer next to Turroc. Level 6: Thunder Clap." } },
    },
})
-- Tarshaw gives 1505: the accept comes before the training at the same NPC (look-ahead rule).
insert({
    after = "dur02-rh-3",
    class = "WARRIOR",
    race = { "Orc", "Troll" },
    steps = {
        { id = "war-dur-1505", accept = 1505, npc = 3169, at = TARSHAW,
          note = { ru = "Таршо: задание «Veteran Uzzek» — путь к Оборонительной стойке. Уззек стоит на заставе "
                       .. "Дальнего Дозора, за рекой от Громового хребта: туда — по пути на север.",
                   en = "Tarshaw: Veteran Uzzek, the way to Defensive Stance. Uzzek is at Far Watch Post, across the "
                       .. "river from Thunder Ridge: you go there on the northern loop." } },
        { id = "war-dur-train-10", train = true, npc = 3169, at = TARSHAW,
          spells = { { ru = "Подрезать сухожилия", en = "Hamstring" },
                     { ru = "Кровавая ярость", en = "Bloodrage" },
                     { ru = "Новые ранги (Удар героя, Кровопускание)", en = "New ranks (Heroic Strike, Rend)" } },
          note = { ru = "Таршо: обучение 8 и 10 вместе (на 8-м вы были в поле). Таланты с 10-го: Оружие — "
                       .. "«Улучшенный удар героя», потом «Отражение» (проверьте дерево Forever в игре).",
                   en = "Tarshaw: training 8 and 10 together (you were in the field at 8). Talents from 10: Arms - "
                       .. "Improved Heroic Strike, then Deflection (check the Forever tree in game)." } },
    },
})
-- PLAN C.2 variant: the crocolisks of 816 are at the river, right across from Far Watch Post; Uzzek, then back to
-- Thunder Ridge, where the shared step kills the same lizards that drop the Singed Scales.
insert({
    after = "dur02-crocs",
    class = "WARRIOR",
    race = { "Orc", "Troll" },
    steps = {
        -- CONFIRM: the river crossing from the crocolisks to Far Watch Post (swim or bridge) and ~3 min there and back
        { id = "war-dur-uzzek", turnin = 1505, accept = 1498, npc = 5810, at = UZZEK,
          note = { ru = "Через реку на запад (вплавь или по мосту севернее) и вверх к заставе Дальнего Дозора: Уззек. "
                       .. "Возьмите «Path of Defense» (5 опалённых чешуек) и возвращайтесь на Громовой хребет "
                       .. "(~3 мин в обе стороны).",
                   en = "West over the river (swim, or the bridge further north) and up to Far Watch Post: Uzzek. Take "
                       .. "Path of Defense (5 Singed Scales) and go back to Thunder Ridge (~3 min there and back)." } },
    },
})
insert({
    after = "dur02-thunder-ridge",
    class = "WARRIOR",
    race = { "Orc", "Troll" },
    steps = {
        { id = "war-dur-scales", complete = 1498, at = THUNDER_RIDGE,
          note = { ru = "Опалённые чешуйки падают с тех же громовых ящеров и громошкуров: добейте до 5. Сдаёте Уззеку "
                       .. "позже, когда путь пройдёт заставу Дальнего Дозора (~14-й уровень).",
                   en = "The Singed Scales drop from the same Thunder Lizards and Lightning Hides: get 5. You hand them "
                       .. "to Uzzek later, when the path passes Far Watch Post (about level 14)." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Mulgore (Tauren)
------------------------------------------------------------------------------------------------------------------
insert({
    after = "mul01-hunt",
    class = "WARRIOR",
    race = "Tauren",
    steps = {
        { id = "war-mul-letter", accept = 3091, npc = 2980, at = { 1412, 44.47, 77.50 },
          note = { ru = "Грулл даёт и письмо воина: «Simple Note».",
                   en = "Grull also gives the warrior's letter: Simple Note." } },
        { id = "war-mul-harutt", turnin = 3091, npc = 3059, at = HARUTT,
          note = { ru = "Harutt Thunderhorn — тренер воинов у вождя: сдайте письмо.",
                   en = "Harutt Thunderhorn, the warrior trainer by the chief: turn in the letter." } },
        { id = "war-mul-train-1", train = true, npc = 3059, at = HARUTT,
          spells = { { ru = "Боевой крик", en = "Battle Shout" } },
          note = { ru = "Выучите «Боевой крик» и держите его на себе. «Удар героя» — когда ярости больше 15-20.",
                   en = "Learn Battle Shout and keep it up. Heroic Strike when you have more than 15-20 rage." } },
    },
})
insert({
    after = "mul01-ravine",
    class = "WARRIOR",
    race = "Tauren",
    steps = {
        { id = "war-mul-train-4", train = true, npc = 3059, at = HARUTT,
          spells = { { ru = "Рывок", en = "Charge" }, { ru = "Кровопускание", en = "Rend" } },
          note = { ru = "Harutt у вождя. Уровень 4: «Рывок» (бой начинайте с него) и «Кровопускание».",
                   en = "Harutt by the chief. Level 4: Charge (open every fight with it) and Rend." } },
    },
})
insert({
    after = "mul02-krang",
    class = "WARRIOR",
    race = "Tauren",
    steps = {
        { id = "war-mul-train-6", train = true, npc = 3063, at = KRANG,
          spells = { { ru = "Удар грома", en = "Thunder Clap" } },
          note = { ru = "Krang Stonehoof — и тренер воинов: уровень 6, «Удар грома».",
                   en = "Krang Stonehoof is also the warrior trainer: level 6, Thunder Clap." } },
    },
})
insert({
    after = "mul02-bh-3",
    class = "WARRIOR",
    race = "Tauren",
    steps = {
        { id = "war-mul-train-8", train = true, npc = 3063, at = KRANG,
          spells = { { ru = "Подрезать сухожилия", en = "Hamstring" },
                     { ru = "Удар героя (ранг 2)", en = "Heroic Strike (Rank 2)" } },
          note = { ru = "Krang рядом с Маллом. Уровень 8: «Подрезать сухожилия» и «Удар героя» 2.",
                   en = "Krang next to Mull. Level 8: Hamstring and Heroic Strike 2." } },
    },
})
insert({
    after = "mul02-bh-4",
    class = "WARRIOR",
    race = "Tauren",
    steps = {
        { id = "war-mul-1505", accept = 1505, npc = 3063, at = KRANG,
          note = { ru = "Krang: задание «Veteran Uzzek» — путь к Оборонительной стойке. Уззека вы пройдёте на 12-м, "
                       .. "на заставе Дальнего Дозора в Степях.",
                   en = "Krang: Veteran Uzzek, the way to Defensive Stance. You pass Uzzek at level 12, at Far Watch "
                       .. "Post in the Barrens." } },
        { id = "war-mul-train-10", train = true, npc = 3063, at = KRANG,
          spells = { { ru = "Кровавая ярость", en = "Bloodrage" },
                     { ru = "Кровопускание (ранг 2)", en = "Rend (Rank 2)" } },
          note = { ru = "Krang: уровень 10. Таланты с 10-го: Оружие — «Улучшенный удар героя», потом «Отражение» "
                       .. "(проверьте дерево Forever в игре).",
                   en = "Krang: level 10. Talents from 10: Arms - Improved Heroic Strike, then Deflection (check the "
                       .. "Forever tree in game)." } },
    },
})
-- Far Watch Post: Thunder Ridge lies ~75 yd off the line Far Watch Post > Orgrimmar gate (mul03-org-gate).
insert({
    after = "mul03-far-watch",
    class = "WARRIOR",
    race = "Tauren",
    steps = {
        { id = "war-mul-uzzek", turnin = 1505, accept = 1498, npc = 5810, at = UZZEK,
          note = { ru = "Уззек на заставе Дальнего Дозора: сдайте «Veteran Uzzek», возьмите «Path of Defense» "
                       .. "(5 опалённых чешуек с громовых ящеров).",
                   en = "Uzzek at Far Watch Post: turn in Veteran Uzzek, take Path of Defense (5 Singed Scales from "
                       .. "thunder lizards)." } },
        { id = "war-mul-scales", complete = 1498, at = THUNDER_RIDGE,
          note = { ru = "За мостом в Дуротар и на север вдоль реки: Громовой хребет лежит прямо на пути к воротам "
                       .. "Оргриммара. Громовые ящеры и громошкуры — 5 опалённых чешуек. Сдаёте Уззеку на 14-м.",
                   en = "Over the bridge into Durotar and north along the river: Thunder Ridge is right on the way to "
                       .. "the Orgrimmar gate. Thunder Lizards and Lightning Hides - 5 Singed Scales. You turn them in "
                       .. "to Uzzek at 14." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Tirisfal (Undead)
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud01-364",
    class = "WARRIOR",
    race = "Scourge",
    steps = {
        { id = "war-tir-letter", accept = 3095, npc = 1569, at = { 1420, 30.84, 66.20 },
          note = { ru = "Сарвис даёт и письмо воина: «Simple Scroll».",
                   en = "Sarvis also gives the warrior's letter: Simple Scroll." } },
        { id = "war-tir-dannal", turnin = 3095, npc = 2119, at = DANNAL,
          note = { ru = "Dannal Stern — тренер воинов в доме через дорогу от церкви: сдайте письмо.",
                   en = "Dannal Stern, the warrior trainer in the house across the road from the church: turn in "
                       .. "the letter." } },
        { id = "war-tir-train-1", train = true, npc = 2119, at = DANNAL,
          spells = { { ru = "Боевой крик", en = "Battle Shout" } },
          note = { ru = "Выучите «Боевой крик» и держите его на себе. «Удар героя» — когда ярости больше 15-20.",
                   en = "Learn Battle Shout and keep it up. Heroic Strike when you have more than 15-20 rage." } },
    },
})
insert({
    after = "ud01-aramis",
    class = "WARRIOR",
    race = "Scourge",
    steps = {
        { id = "war-tir-train-4", train = true, npc = 2119, at = DANNAL,
          spells = { { ru = "Рывок", en = "Charge" }, { ru = "Кровопускание", en = "Rend" } },
          note = { ru = "Dannal через дорогу от церкви. Уровень 4: «Рывок» (бой начинайте с него) и «Кровопускание».",
                   en = "Dannal across the road from the church. Level 4: Charge (open every fight with it) and "
                       .. "Rend." } },
    },
})
insert({
    after = "ud02-sethearth",
    class = "WARRIOR",
    race = "Scourge",
    steps = {
        { id = "war-tir-train-6", train = true, npc = 2131, at = AUSTIL,
          spells = { { ru = "Удар грома", en = "Thunder Clap" } },
          note = { ru = "Austil de Mon — тренер воинов в таверне. Уровень 6: «Удар грома».",
                   en = "Austil de Mon, the warrior trainer in the inn. Level 6: Thunder Clap." } },
    },
})
insert({
    after = "ud02-brill-8",
    class = "WARRIOR",
    race = "Scourge",
    steps = {
        { id = "war-tir-train-8", train = true, npc = 2131, at = AUSTIL,
          spells = { { ru = "Подрезать сухожилия", en = "Hamstring" },
                     { ru = "Удар героя (ранг 2)", en = "Heroic Strike (Rank 2)" } },
          note = { ru = "Austil в таверне. Уровень 8: «Подрезать сухожилия» и «Удар героя» 2.",
                   en = "Austil in the inn. Level 8: Hamstring and Heroic Strike 2." } },
    },
})
-- Level 10 in Brill: the Brill variant of Defensive Stance (1818 > 1819 > 1820 > 1821 > 1822). The shared gate
-- ud02-level-10 guarantees the level; the next shared step (Terrence, south edge of Brill) starts from the village.
insert({
    after = "ud02-level-10",
    class = "WARRIOR",
    race = "Scourge",
    steps = {
        { id = "war-tir-1818", accept = 1818, npc = 2131, at = AUSTIL,
          note = { ru = "В таверну к Austil de Mon: задание «Speak with Dillinger» — путь к Оборонительной стойке.",
                   en = "Into the inn to Austil de Mon: Speak with Dillinger, the way to Defensive Stance." } },
        { id = "war-tir-train-10", train = true, npc = 2131, at = AUSTIL,
          spells = { { ru = "Кровавая ярость", en = "Bloodrage" },
                     { ru = "Кровопускание (ранг 2)", en = "Rend (Rank 2)" } },
          note = { ru = "Austil: уровень 10. Таланты с 10-го: Оружие — «Улучшенный удар героя», потом «Отражение» "
                       .. "(проверьте дерево Forever в игре).",
                   en = "Austil: level 10. Talents from 10: Arms - Improved Heroic Strike, then Deflection (check the "
                       .. "Forever tree in game)." } },
        { id = "war-tir-dillinger", turnin = 1818, accept = 1819, npc = 1496, at = { 1420, 58.20, 51.45 },
          note = { ru = "Стражник смерти Диллинджер у входа в Брилл: «Ulag the Cleaver».",
                   en = "Deathguard Dillinger at the Brill entrance: Ulag the Cleaver." } },
        -- CONFIRM: Ulag appears when the mausoleum trigger (object index 706178, outside the snapshot) is used
        { id = "war-tir-ulag", complete = 1819, at = { 1420, 59.47, 48.28 },
          note = { ru = "Склеп на кладбище к северу от Брилла: откройте дверь (рычаг у входа) — выходит Улаг "
                       .. "Тесак (11). Бой с полной яростью: «Рывок», «Кровопускание», «Подрезать сухожилия».",
                   en = "The mausoleum in the graveyard north of Brill: open the door (the trigger by the entrance) - "
                       .. "Ulag the Cleaver (11) comes out. Fight with full rage: Charge, Rend, Hamstring." } },
        { id = "war-tir-dillinger-2", turnin = 1819, accept = 1820, npc = 1496, at = { 1420, 58.20, 51.45 },
          note = { ru = "Диллинджер: награда — ОБОРОННАЯ СТОЙКА (с «Раскол брони» и «Провокацией»). Следующее "
                       .. "задание — к Коулману в таверне.",
                   en = "Dillinger: the reward is DEFENSIVE STANCE (with Sunder Armor and Taunt). The next quest goes "
                       .. "to Coleman in the inn." } },
        { id = "war-tir-coleman", turnin = 1820, npc = 1500, at = { 1420, 61.72, 52.29 },
          note = { ru = "Коулман Фартинг в таверне.",
                   en = "Coleman Farthing in the inn." } },
        { id = "war-tir-1821", accept = 1821, npc = 1500, optional = true, at = { 1420, 61.72, 52.29 },
          note = { ru = "Необязательно (~5 мин, 1540 опыта и оружие): «Agamand Heirlooms» — четыре стойки с оружием "
                       .. "на севере Мельниц Агамондов (~880 м). Не хотите — «Пропуск» здесь и в двух следующих "
                       .. "шагах.",
                   en = "Optional (~5 min, 1,540 XP and a weapon): Agamand Heirlooms - four weapon racks in the north "
                       .. "of Agamand Mills (~880 yd). Not wanted: skip this and the next two steps." } },
        { id = "war-tir-racks", complete = 1821, optional = true, at = { 1420, 52.2, 26.4 },
          note = { ru = "Север Мельниц Агамондов: топор, кинжал, булава и меч на четырёх стойках (51.7, 25.7; "
                       .. "51.9, 27.1; 52.7, 27.0; 52.7, 25.9). Скелеты вокруг — по одному.",
                   en = "North of Agamand Mills: the axe, dagger, mace and sword on four racks (51.7, 25.7; 51.9, 27.1; "
                       .. "52.7, 27.0; 52.7, 25.9). Skeletons around - one at a time." } },
        { id = "war-tir-heirloom", turnin = 1821, accept = 1822, npc = 1500, optional = true,
          at = { 1420, 61.72, 52.29 },
          note = { ru = "Назад к Коулману в таверну: сдайте реликвии и возьмите «Heirloom Weapon».",
                   en = "Back to Coleman in the inn: turn in the heirlooms and take Heirloom Weapon." } },
        { id = "war-tir-heirloom-2", turnin = 1822, npc = 1500, optional = true, at = { 1420, 61.72, 52.29 },
          note = { ru = "Сразу сдайте его: выберите оружие своего навыка (двуручное, если такое есть в выборе).",
                   en = "Turn it in right away: pick a weapon of a skill you have (a two-hander if one is "
                       .. "offered)." } },
    },
})
insert({
    after = "ud02-hearth-2",
    class = "WARRIOR",
    race = "Scourge",
    steps = {
        { id = "war-tir-train-12", train = true, npc = 2131, at = AUSTIL,
          spells = { { ru = "Превосходство", en = "Overpower" }, { ru = "Удар щитом", en = "Shield Bash" },
                     { ru = "Боевой крик (ранг 2)", en = "Battle Shout (Rank 2)" } },
          note = { ru = "Austil в таверне. Уровень 12: «Превосходство» (после уклонения цели — сильный удар).",
                   en = "Austil in the inn. Level 12: Overpower (a strong hit after the target dodges)." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Zephras Isle (Skyborne)
------------------------------------------------------------------------------------------------------------------
insert({
    after = "sd01-rorian",
    class = "WARRIOR",
    race = "Skyborne",
    steps = {
        { id = "war-zep-letter", accept = 92532, npc = 251361, at = { 2521, 42.05, 23.49 },
          note = { ru = "Rorian даёт и классовое задание воина: «Путь воина» (The Warrior's Path).",
                   en = "Rorian also gives the warrior class quest: The Warrior's Path." } },
        { id = "war-zep-ren", turnin = 92532, use = 282419, npc = 251964, at = REN,
          note = { ru = "Прочитайте письмо из сумки (кнопка предмета), затем поговорите с Blademaster Ren — тренером "
                       .. "воинов рядом с Rorian.",
                   en = "Read the letter from your bags (item button), then talk to Blademaster Ren, the warrior "
                       .. "trainer next to Rorian." } },
        { id = "war-zep-train-1", train = true, npc = 251964, at = REN,
          spells = { { ru = "Боевой крик", en = "Battle Shout" } },
          note = { ru = "Выучите «Боевой крик» и держите его на себе. «Удар героя» — когда ярости больше 15-20.",
                   en = "Learn Battle Shout and keep it up. Heroic Strike when you have more than 15-20 rage." } },
    },
})
insert({
    after = "sd01-thendal-4",
    class = "WARRIOR",
    race = "Skyborne",
    steps = {
        { id = "war-zep-train-4", train = true, npc = 251964, at = REN,
          spells = { { ru = "Рывок", en = "Charge" }, { ru = "Кровопускание", en = "Rend" } },
          note = { ru = "Blademaster Ren рядом. Уровень 4: «Рывок» (бой начинайте с него) и «Кровопускание».",
                   en = "Blademaster Ren close by. Level 4: Charge (open every fight with it) and Rend." } },
    },
})
insert({
    after = "sd01-raan-2",
    class = "WARRIOR",
    race = "Skyborne",
    steps = {
        { id = "war-zep-train-6", train = true, npc = 254088, at = CORSAN,
          spells = { { ru = "Удар грома", en = "Thunder Clap" } },
          note = { ru = "Corsan Earthrazer — тренер воинов в Шен'даре, к востоку от костра. Уровень 6: «Удар грома».",
                   en = "Corsan Earthrazer, the warrior trainer of Shen'dar, east of the campfire. Level 6: Thunder "
                       .. "Clap." } },
    },
})
insert({
    after = "sd01-danarii-2",
    class = "WARRIOR",
    race = "Skyborne",
    steps = {
        { id = "war-zep-train-8", train = true, npc = 254088, at = CORSAN,
          spells = { { ru = "Подрезать сухожилия", en = "Hamstring" },
                     { ru = "Удар героя (ранг 2)", en = "Heroic Strike (Rank 2)" } },
          note = { ru = "Corsan рядом с Danarii. Уровень 8: «Подрезать сухожилия» и «Удар героя» 2.",
                   en = "Corsan next to Danarii. Level 8: Hamstring and Heroic Strike 2." } },
    },
})
-- Seena gives 94003: the accept comes before the training at the same NPC.
insert({
    after = "sd02-valanaar-10",
    class = "WARRIOR",
    race = "Skyborne",
    steps = {
        { id = "war-zep-94003", accept = 94003, npc = 252377, at = SEENA,
          note = { ru = "Seena Skybreaker у западного входа в Валанаар: «The Skybreaker Bulwark» — Оборонительная "
                       .. "стойка. Щит у Zaal Stormshield (10), его лагерь — по пути на север.",
                   en = "Seena Skybreaker by the west entrance of Valanaar: The Skybreaker Bulwark - Defensive Stance. "
                       .. "Zaal Stormshield (10) has the shield; his camp is on the way north." } },
        { id = "war-zep-train-10", train = true, npc = 252377, at = SEENA,
          spells = { { ru = "Кровавая ярость", en = "Bloodrage" },
                     { ru = "Кровопускание (ранг 2)", en = "Rend (Rank 2)" } },
          note = { ru = "Seena: уровень 10. Таланты с 10-го: Оружие — «Улучшенный удар героя», потом «Отражение» "
                       .. "(проверьте дерево Forever в игре).",
                   en = "Seena: level 10. Talents from 10: Arms - Improved Heroic Strike, then Deflection (check the "
                       .. "Forever tree in game)." } },
    },
})
insert({
    after = "sd02-parts-gyrozephyr",
    class = "WARRIOR",
    race = "Skyborne",
    steps = {
        { id = "war-zep-zaal", complete = 94003, at = { 2521, 56.63, 50.37 },
          note = { ru = "Zaal Stormshield (10) чуть восточнее, у лагеря Al'Aketh: убейте его и заберите Skybreaker "
                       .. "Bulwark. Его стражу тяните по одному.",
                   en = "Zaal Stormshield (10) a little further east, by the Al'Aketh camp: kill him and loot the "
                       .. "Skybreaker Bulwark. Pull his guards one at a time." } },
    },
})
insert({
    after = "sd02-nyalah-2",
    class = "WARRIOR",
    race = "Skyborne",
    steps = {
        -- CONFIRM: 94003 teaches Defensive Stance (Warcraft Tavern; the DB has no rewards), classes.md 8.4 item 6
        { id = "war-zep-94003-turnin", turnin = 94003, npc = 252377, at = SEENA,
          note = { ru = "Seena Skybreaker у западного входа: сдайте щит — ОБОРОННАЯ СТОЙКА.",
                   en = "Seena Skybreaker by the west entrance: hand in the shield - DEFENSIVE STANCE." } },
        { id = "war-zep-train-12", train = true, npc = 252377, at = SEENA,
          spells = { { ru = "Превосходство", en = "Overpower" }, { ru = "Удар щитом", en = "Shield Bash" },
                     { ru = "Боевой крик (ранг 2)", en = "Battle Shout (Rank 2)" } },
          note = { ru = "Seena: уровень 12. «Превосходство» — сильный удар после уклонения цели. Следующее "
                       .. "обучение — в Подгороде на 14-м.",
                   en = "Seena: level 12. Overpower - a strong hit after the target dodges. Next training: the "
                       .. "Undercity at 14." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 12-22
------------------------------------------------------------------------------------------------------------------
-- Undercity at 12: the War Quarter lies between the flight master and the sewers exit (h12-sewers).
insert({
    after = "h12-fp-uc",
    class = "WARRIOR",
    race = { "Orc", "Troll", "Tauren" },
    steps = {
        { id = "war-train-12", train = true, npc = 4593, at = CHRISTOPH,
          spells = { { ru = "Превосходство", en = "Overpower" }, { ru = "Удар щитом", en = "Shield Bash" },
                     { ru = "Боевой крик (ранг 2)", en = "Battle Shout (Rank 2)" } },
          note = { ru = "Квартал Воинов на северо-западе Подгорода — по пути к выходу через сточные каналы: тренер "
                       .. "Christoph Walker. Уровень 12: «Превосходство» (сильный удар после уклонения цели).",
                   en = "The War Quarter in the north-west of the Undercity, on the way to the sewers exit: trainer "
                       .. "Christoph Walker. Level 12: Overpower (a strong hit after the target dodges)." } },
    },
})
insert({
    after = "h13-uc-end",
    class = "WARRIOR",
    steps = {
        { id = "war-train-14", train = true, npc = 4593, at = CHRISTOPH,
          spells = { { ru = "Реванш", en = "Revenge" }, { ru = "Деморализующий крик", en = "Demoralizing Shout" } },
          note = { ru = "Из Чумного квартала на север в Квартал Воинов: Christoph Walker. Уровень 14 (и 12, если ещё "
                       .. "нет). Потом — камень возвращения, как дальше по маршруту.",
                   en = "From the Apothecarium north to the War Quarter: Christoph Walker. Level 14 (and 12 if you "
                       .. "still need it). Then the hearthstone, as the route goes on." } },
    },
})
insert({
    after = "h15-far-watch",
    class = "WARRIOR",
    race = { "Orc", "Troll", "Tauren", "Scourge" },
    steps = {
        { id = "war-uzzek", race = { "Orc", "Troll", "Tauren" }, turnin = 1498, accept = 1502, npc = 5810, at = UZZEK,
          note = { ru = "Уззек рядом с Каргалом: сдайте чешуйки — ОБОРОННАЯ СТОЙКА (с «Раскол брони» и "
                       .. "«Провокацией»). Следующее задание — к Тун'гриму, по пути на Перекрёсток.",
                   en = "Uzzek next to Kargal: hand in the scales - DEFENSIVE STANCE (with Sunder Armor and Taunt). "
                       .. "The next quest goes to Thun'grim, on the way to the Crossroads." } },
        { id = "war-uzzek-ud", race = "Scourge", accept = 1502, npc = 5810, at = UZZEK,
          note = { ru = "Уззек рядом с Каргалом: после Улага он даёт и «Thun'grim Firegaze» — по пути на Перекрёсток.",
                   en = "Uzzek next to Kargal: after Ulag he also gives Thun'grim Firegaze - on the way to the "
                       .. "Crossroads." } },
        { id = "war-thungrim", turnin = 1502, accept = 1503, npc = 5878, at = THUNGRIM,
          note = { ru = "Тун'грим Огнегляд стоит у дороги на юго-запад: «Forged Steel» — украденный железный сундук.",
                   en = "Thun'grim Firegaze stands by the road to the south-west: Forged Steel - the Stolen Iron "
                       .. "Chest." } },
        { id = "war-1503-chest", complete = 1503, object = 58369, at = { 1413, 55.05, 26.65 },
          note = { ru = "Сундук на северо-западе от Тун'грима (~350 м): заберите стальные слитки.",
                   en = "The chest north-west of Thun'grim (~350 yd): loot the Forged Steel Bars." } },
        -- CONFIRM: the reward list of 1503 (and of 1822): then the class reward table can name the indexes
        { id = "war-1503", turnin = 1503, npc = 5878, at = THUNGRIM,
          note = { ru = "Назад к Тун'гриму: награда — оружие (берите двуручное своего навыка). Дальше — на "
                       .. "Перекрёсток.",
                   en = "Back to Thun'grim: the reward is a weapon (take a two-hander of a skill you have). Then on "
                       .. "to the Crossroads." } },
    },
})
-- Thunder Bluff at 18: from Spirit Rise over Hunter Rise to Tal (~550 yd more than the straight way).
insert({
    after = "h18-tb-1",
    class = "WARRIOR",
    steps = {
        { id = "war-train-18", train = true, npc = 3041, at = TORM,
          spells = { { ru = "Удар грома (ранг 2)", en = "Thunder Clap (Rank 2)" }, { ru = "Разоружение", en = "Disarm" },
                     { ru = "Удар героя (ранг 3), Блок щитом (16)", en = "Heroic Strike (Rank 3), Shield Block (16)" } },
          note = { ru = "Через центральную гору на юг к Вершине Охотников: Torm Ragetotem. Обучение 16 и 18. Потом "
                       .. "назад к Талу.",
                   en = "Across the central mesa south to Hunter Rise: Torm Ragetotem. Training 16 and 18. Then back "
                       .. "to Tal." } },
    },
})
-- Torm gives 1823: the accept comes before the training.
insert({
    after = "h18-sethearth-tb",
    class = "WARRIOR",
    steps = {
        { id = "war-1823", accept = 1823, npc = 3041, at = TORM,
          note = { ru = "От таверны на юг к Вершине Охотников: Torm Ragetotem — «Speak with Ruga» (Лагерь Таурахо, "
                       .. "сдаёте на 25-м).",
                   en = "From the inn south to Hunter Rise: Torm Ragetotem - Speak with Ruga (Camp Taurajo, handed in "
                       .. "at 25)." } },
        { id = "war-train-20", train = true, npc = 3041, at = TORM,
          spells = { { ru = "Рассекающий удар", en = "Cleave" }, { ru = "Возмездие", en = "Retaliation" },
                     { ru = "Мощный удар, Победный раж (если есть)", en = "Slam, Victory Rush (if offered)" } },
          note = { ru = "Torm: уровень 20. «Рассекающий удар» — на две цели. Таланты к 20: Оружие — «Отражение», "
                       .. "«Тактическое мастерство», «Улучшенное кровопускание».",
                   en = "Torm: level 20. Cleave for two targets. Talents by 20: Arms - Deflection, Tactical Mastery, "
                       .. "Improved Rend." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 22-31: Thunder Bluff, the Field of Giants, Fray Island
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-24-tb-hearth",
    class = "WARRIOR",
    steps = {
        { id = "war-train-24", train = true, npc = 3041, at = TORM,
          spells = { { ru = "Казнь", en = "Execute" }, { ru = "Удар героя (ранг 4)", en = "Heroic Strike (Rank 4)" },
                     { ru = "Устрашающий крик (22)", en = "Intimidating Shout (22)" } },
          note = { ru = "От таверны на юг к Вершине Охотников: Torm Ragetotem — обучение 22 и 24. «Казнь» — "
                       .. "добивание (цель ниже 20 % здоровья): главная кнопка до 60-го.",
                   en = "From the inn south to Hunter Rise: Torm Ragetotem - training 22 and 24. Execute finishes a "
                       .. "target below 20% health: your main button up to 60." } },
        { id = "war-2h-maces", manual = true, npc = 11869, optional = true, at = { 1456, 40.93, 62.73 },
          spells = { { ru = "Двуручное дробящее оружие", en = "Two-Handed Maces" } },
          note = { ru = "Если в «Навыках» нет двуручного дробящего: мастер оружия Ансекхва у таверны (~10 серебра). "
                       .. "Тогда за 893 (Таттернак, Лагерь Таурахо, ~25-й) берите Молот Уничтожения — двуручную "
                       .. "булаву (17.6 DPS, +9 к силе) до 40-х. Навык есть — «Вперёд».",
                   en = "If Two-Handed Maces is not in your skills: weapon master Ansekhwa by the inn (~10 silver). "
                       .. "Then take the Demolition Hammer for 893 (Tatternack, Camp Taurajo, ~25): a two-handed mace "
                       .. "(17.6 dps, +9 Str) into the 40s. Skill known: press Next." } },
    },
})
-- Camp Taurajo: Ruga stands next to Mangletooth; the silithids of the Field of Giants are on the way south (868).
insert({
    after = "h-24-camp-taurajo",
    class = "WARRIOR",
    steps = {
        { id = "war-ruga", turnin = 1823, accept = 1824, npc = 6394, at = RUGA,
          note = { ru = "Руга Рваный Тотем рядом с Манглзубом: «Trial at the Field of Giants» — 5 дёргающихся усиков.",
                   en = "Ruga Ragetotem next to Mangletooth: Trial at the Field of Giants - 5 Twitching Antennae." } },
        { id = "war-antennae-bg", complete = 1824, bg = true, at = { 1413, 42.1, 69.4 },
          note = { ru = "Попутно: силитиды на Поле Гигантов (по пути на юг, у холмиков для 868) — 5 усиков.",
                   en = "On the way: the silithids of the Field of Giants (on the way south, by the mounds of 868) - "
                       .. "5 antennae." } },
    },
})
insert({
    before = "h-25-fly-ratchet",
    class = "WARRIOR",
    steps = {
        { id = "war-ruga-2", turnin = 1824, accept = 1825, npc = 6394, at = RUGA,
          note = { ru = "Руга: сдайте усики и возьмите «Speak with Thun'grim» — Тун'грим стоит у дороги восточнее "
                       .. "Перекрёстка, под холмом Чол'арука (вы будете там после Кабестана).",
                   en = "Ruga: hand in the antennae and take Speak with Thun'grim - Thun'grim stands by the road east "
                       .. "of the Crossroads, below Chol'aruk's hill (you are there after Ratchet)." } },
    },
})
-- 1825 right after Chol'aruk's hill (h-26-cholaruk, ~300 yd from Thun'grim), before the Crossroads turn-ins.
insert({
    after = "h-26-cholaruk",
    class = "WARRIOR",
    steps = {
        { id = "war-1825", turnin = 1825, npc = 5878, at = THUNGRIM,
          note = { ru = "С холма Чол'арука ~300 м на юго-запад к дороге: Тун'грим Огнегляд — сдайте «Speak with "
                       .. "Thun'grim» (780 опыта). Его следующее задание (Brutal Armor) не берите.",
                   en = "From Chol'aruk's hill ~300 yd south-west to the road: Thun'grim Firegaze - turn in Speak with "
                       .. "Thun'grim (780 XP). Do not take his next quest (Brutal Armor)." } },
    },
})
insert({
    after = "h-28-hearth-tb",
    class = "WARRIOR",
    steps = {
        { id = "war-train-28", train = true, npc = 3041, at = TORM,
          spells = { { ru = "Вызывающий крик, Рывок (ранг 2)", en = "Challenging Shout, Charge (Rank 2)" },
                     { ru = "Превосходство (ранг 2), Глухая оборона (28)", en = "Overpower (Rank 2), Shield Wall (28)" } },
          note = { ru = "Вершина Охотников рядом с таверной: Torm Ragetotem — обучение 26 и, если уже 28-й, 28.",
                   en = "Hunter Rise next to the inn: Torm Ragetotem - training 26 and, if you are 28 already, 28." } },
    },
})
-- Melor's turn-in (h30-tb-1131) is on Hunter Rise, next to Torm; Torm gives 1718 before the training.
insert({
    after = "h30-tb-1131",
    class = "WARRIOR",
    steps = {
        { id = "war-1718", accept = 1718, npc = 3041, at = TORM,
          note = { ru = "Torm Ragetotem рядом с Мелором: «The Islander» — путь к Стойке берсерка (остров у Кабестана, "
                       .. "по пути в Оргриммар).",
                   en = "Torm Ragetotem next to Melor: The Islander - the way to Berserker Stance (an island off "
                       .. "Ratchet, on the way to Orgrimmar)." } },
        { id = "war-train-30", train = true, npc = 3041, at = TORM,
          spells = { { ru = "Мощный удар, Рассекающий удар (ранг 2)", en = "Slam, Cleave (Rank 2)" },
                     { ru = "Ярость берсерка (после стойки)", en = "Berserker Rage (after the stance)" },
                     { ru = "Ранги 28, если пропустили", en = "The rank 28 set if you skipped it" } },
          note = { ru = "Torm: уровень 30. «Ярость берсерка» требует Стойку берсерка: если её нет в списке — выучите "
                       .. "в Подгороде на 34-м. Таланты: к 30-му — «Специализация на двуручном оружии», дальше к "
                       .. "«Смертельному удару» (40).",
                   en = "Torm: level 30. Berserker Rage needs Berserker Stance: not offered yet - learn it in the "
                       .. "Undercity at 34. Talents: by 30 Two-Handed Weapon Specialization, then on to Mortal Strike "
                       .. "(40)." } },
    },
})
-- Berserker Stance: the path flies Thunder Bluff > Camp Taurajo (1153 at Tatternack) > Orgrimmar. The insert goes
-- from Camp Taurajo to Ratchet instead; the shared next step (fly Orgrimmar) works from Ratchet.
insert({
    before = "h-31-org",
    class = "WARRIOR",
    steps = {
        { id = "war-30-fly-ratchet", fly = "Ratchet", npc = 16227, at = { 1413, 63.08, 37.16 },
          note = { ru = "Омуса: летите в Кабестан (не в Оргриммар).",
                   en = "Omusa: fly to Ratchet (not to Orgrimmar)." } },
        { id = "war-30-islander", turnin = 1718, accept = 1719, npc = 6236, at = KLANNOC,
          note = { ru = "Из Кабестана на юг по берегу до ~66, 46, оттуда вплавь на юго-восток к острову (~350 м): "
                       .. "Кланнок Маклауд. Возьмите «The Affray».",
                   en = "From Ratchet south along the shore to about 66, 46, then swim south-east to the island "
                       .. "(~350 yd): Klannoc Macleod. Take The Affray." } },
        -- CONFIRM: the event (two waves, then Big Will) and the Intercept reward of 1719 in Forever
        { id = "war-30-affray", complete = 1719, at = { 1413, 68.61, 48.72 },
          note = { ru = "Встаньте на решётку арены рядом с ним: две волны по двое, потом Большой Уилл (33). Полная "
                       .. "ярость, «Удар грома» и «Возмездие» на волнах; не уходите с арены.",
                   en = "Step onto the grate of the arena next to him: two waves of two, then Big Will (33). Full rage, "
                       .. "Thunder Clap and Retaliation on the waves; stay on the arena." } },
        { id = "war-30-stance", turnin = 1719, npc = 6236, at = KLANNOC,
          note = { ru = "Кланнок: награда — СТОЙКА БЕРСЕРКА (и «Перехват»). Его следующее задание («The "
                       .. "Windwatcher») гайд не ведёт. Вплавь назад в Кабестан к Брагоку: дальше — полёт в "
                       .. "Оргриммар.",
                   en = "Klannoc: the reward is BERSERKER STANCE (and Intercept). The guide does not follow his next "
                       .. "quest (The Windwatcher). Swim back to Ratchet, to Bragok: next is the flight to "
                       .. "Orgrimmar." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 31-60: training in the Undercity, Orgrimmar and Stonard; Warrior Kinship
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-34-uc-arrive",
    class = "WARRIOR",
    steps = {
        { id = "war-train-34", train = true, npc = 4593, at = CHRISTOPH,
          spells = { { ru = "Казнь (ранг 2), Удар героя (ранг 5)", en = "Execute (Rank 2), Heroic Strike (Rank 5)" },
                     { ru = "Реванш (ранг 3), Деморализующий крик (ранг 3)",
                       en = "Revenge (Rank 3), Demoralizing Shout (Rank 3)" },
                     { ru = "Ярость берсерка, если не взяли на 30-м", en = "Berserker Rage if you skipped it at 30" } },
          note = { ru = "От распорядителя полётов на север в Квартал Воинов: Christoph Walker — обучение 32 и 34. "
                       .. "Потом в Чумной квартал к Фаранеллу.",
                   en = "From the flight master north to the War Quarter: Christoph Walker - training 32 and 34. Then "
                       .. "to Faranell in the Apothecarium." } },
    },
})
insert({
    after = "h-37-org-arrive",
    class = "WARRIOR",
    steps = {
        { id = "war-train-36", train = true, npc = 3353, at = GREZZ,
          spells = { { ru = "Вихрь", en = "Whirlwind" }, { ru = "Дразнящий удар (ранг 3)", en = "Mocking Blow (Rank 3)" } },
          note = { ru = "На восток в Аллею Чести: Грезз Яростный Кулак. Уровень 36 — «ВИХРЬ» (нужна Стойка "
                       .. "берсерка): жмите по откату на 1-4 цели. Потом на запад к Келдрану.",
                   en = "East to the Valley of Honor: Grezz Ragefist. Level 36 - WHIRLWIND (needs Berserker Stance): "
                       .. "use it on cooldown on 1-4 targets. Then west to Keldran." } },
    },
})
insert({
    after = "h-40-org-arrive",
    class = "WARRIOR",
    steps = {
        { id = "war-train-40", train = true, npc = 3353, at = GREZZ,
          spells = { { ru = "Латные доспехи (40)", en = "Plate Mail (40)" },
                     { ru = "Казнь (ранг 3), Удар героя (ранг 6)", en = "Execute (Rank 3), Heroic Strike (Rank 6)" },
                     { ru = "Мощный удар (ранг 2), Удар грома (ранг 4) (38)", en = "Slam (Rank 2), Thunder Clap (Rank 4) (38)" } },
          note = { ru = "От Келдрана на восток в Аллею Чести: Грезз Яростный Кулак — обучение 38 и 40 (латы). Нет "
                       .. "ещё 40-го — ранги 40 возьмёте в Каменоре на 44-м. Талант 40 — «Смертельный удар».",
                   en = "From Keldran east to the Valley of Honor: Grezz Ragefist - training 38 and 40 (plate). Not 40 "
                       .. "yet: the 40 ranks wait for Stonard at 44. Talent at 40: Mortal Strike." } },
        { id = "war-2h-axes", manual = true, npc = 2704, optional = true, at = { 1454, 81.53, 19.63 },
          spells = { { ru = "Двуручные топоры", en = "Two-Handed Axes" } },
          note = { ru = "Рекомендуется, если в «Навыках» их нет: мастер оружия Ханаши рядом — Двуручные топоры "
                       .. "(~10 серебра). За 1427 на 44-м берите Колун мурлоков Ток'Кара (32.5 DPS, +15 к силе), на "
                       .. "54-м Зверобой (4301): к ним навык уже вырастет. Навык есть — «Вперёд».",
                   en = "Recommended if your skills lack it: weapon master Hanashi next door - Two-Handed Axes (~10 "
                       .. "silver). Take Tok'kar's Murloc Chopper for 1427 at 44 (32.5 dps, +15 Str) and Beastslayer "
                       .. "(4301) at 54: the skill has grown by then. Skill known: press Next." } },
    },
})
insert({
    after = "h-44-stonard-arrive",
    class = "WARRIOR",
    steps = {
        { id = "war-train-44", train = true, npc = 985, at = MALOSH,
          spells = { { ru = "Превосходство (ранг 3), Реванш (ранг 4)", en = "Overpower (Rank 3), Revenge (Rank 4)" },
                     { ru = "Перехват (ранг 2), Боевой крик (ранг 5) (42)", en = "Intercept (Rank 2), Battle Shout (Rank 5) (42)" },
                     { ru = "Ранги 40, если пропустили", en = "The rank 40 set if you skipped it" } },
          note = { ru = "Малош — тренер воинов у западного входа в Каменор (рядом с Даром): обучение 42 и 44.",
                   en = "Malosh, the warrior trainer by the west entrance of Stonard (next to Dar): training 42 and "
                       .. "44." } },
    },
})
insert({
    after = "h49-org-2976",
    class = "WARRIOR",
    steps = {
        { id = "war-train-48", train = true, npc = 3353, at = GREZZ,
          spells = { { ru = "Казнь (ранг 4), Удар героя (ранг 7)", en = "Execute (Rank 4), Heroic Strike (Rank 7)" },
                     { ru = "Мощный удар (ранг 3), Удар грома (ранг 5)", en = "Slam (Rank 3), Thunder Clap (Rank 5)" } },
          note = { ru = "Рядом с Белгромом в Аллее Чести: Грезз Яростный Кулак — обучение 46 и 48.",
                   en = "Next to Belgrom in the Valley of Honor: Grezz Ragefist - training 46 and 48." } },
    },
})
insert({
    after = "h51-stonard-2622",
    class = "WARRIOR",
    steps = {
        { id = "war-train-50", train = true, npc = 985, at = MALOSH,
          spells = { { ru = "Безрассудство", en = "Recklessness" },
                     { ru = "Рассекающий удар (ранг 4), Кровопускание (ранг 6)", en = "Cleave (Rank 4), Rend (Rank 6)" } },
          note = { ru = "Малош рядом с Бенгором: обучение 50.",
                   en = "Malosh next to Bengor: training 50." } },
    },
})
-- Warrior Kinship: the Fallen Hero gives 8423 without the breadcrumb 8417; the Helboars are the Blasted Lands gate.
insert({
    after = "h-51-swamp-of-sorrows-3",
    class = "WARRIOR",
    steps = {
        -- CONFIRM: the Fallen Hero offers 8423 without the breadcrumb 8417 (DB: 8417 is only its breadcrumb)
        { id = "war-8423", accept = 8423, npc = 7572, at = FALLEN_HERO,
          note = { ru = "Павший герой даёт и задание воинов «Warrior Kinship»: 7 адских кабанов в Выжженных землях "
                       .. "(5100 опыта). Его следующие задания (50 Темных Клятвенников, Затонувший храм) не берите.",
                   en = "The Fallen Hero of the Horde also gives the warrior quest Warrior Kinship: 7 Helboars in "
                       .. "the Blasted Lands (5,100 XP). Do not take his follow-ups (50 Shadowsworn, the Sunken "
                       .. "Temple)." } },
        { id = "war-helboars-bg", complete = 8423, bg = true, at = { 1419, 44.6, 33.4 },
          note = { ru = "Попутно: адские кабаны (52-53) в центре Выжженных земель — 7 штук.",
                   en = "On the way: Helboars (52-53) in the centre of the Blasted Lands - 7 of them." } },
    },
})
insert({
    after = "h-53-blastedlands-end",
    class = "WARRIOR",
    steps = {
        { id = "war-8423-turnin", turnin = 8423, npc = 7572, at = FALLEN_HERO,
          note = { ru = "От кровавых магов ~120 м на север по дороге к развилке: Павший герой — сдайте кабанов.",
                   en = "From the Bloodmages ~120 yd north along the road to the fork: the Fallen Hero of the Horde - "
                       .. "hand in the Helboars." } },
    },
})
insert({
    after = "h53-org-3507",
    class = "WARRIOR",
    steps = {
        { id = "war-train-52", train = true, npc = 3353, at = GREZZ,
          spells = { { ru = "Перехват (ранг 3), Боевой крик (ранг 6)", en = "Intercept (Rank 3), Battle Shout (Rank 6)" } },
          note = { ru = "Рядом с Белгромом: Грезз Яростный Кулак — обучение 52 (и 50, если пропустили).",
                   en = "Next to Belgrom: Grezz Ragefist - training 52 (and 50 if you skipped it)." } },
    },
})
insert({
    after = "h-58-uc-arrive",
    class = "WARRIOR",
    steps = {
        { id = "war-train-56", train = true, npc = 4593, at = CHRISTOPH,
          spells = { { ru = "Казнь (ранг 5), Удар героя (ранг 8)", en = "Execute (Rank 5), Heroic Strike (Rank 8)" },
                     { ru = "Мощный удар (ранг 4), Реванш (ранг 5) (54)", en = "Slam (Rank 4), Revenge (Rank 5) (54)" } },
          note = { ru = "От таверны на северо-запад в Квартал Воинов: Christoph Walker — обучение 54 и 56.",
                   en = "From the inn north-west to the War Quarter: Christoph Walker - training 54 and 56." } },
    },
})
insert({
    after = "h-60-end",
    class = "WARRIOR",
    steps = {
        { id = "war-60-hearth", hearth = "Undercity", optional = true, at = { 1458, 67.74, 37.89 },
          note = { ru = "Маршрут пройден. По желанию: камень в Подгород (привязан перед Чумными землями) и обучение.",
                   en = "The route is done. If you like: hearth to the Undercity (bound before the Plaguelands) and "
                       .. "train." } },
        { id = "war-train-60", train = true, npc = 4593, optional = true, at = CHRISTOPH,
          spells = { { ru = "Ранги 58 и 60", en = "The rank 58 and 60 sets" } },
          note = { ru = "Квартал Воинов: Christoph Walker — обучение 58 и 60.",
                   en = "The War Quarter: Christoph Walker - training 58 and 60." } },
    },
})
