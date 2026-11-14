-- AdventureAtlas_Guides / Classes / Priest.lua
--
-- Every step that exists because of the class (priest), for both priest races (Troll, Undead = "Scourge"), as shared
-- inserts with class scope (step ids "pri-..."; below level 12 one group per start zone: "pri-dur-..." Durotar for the
-- Troll, "pri-tir-..." Tirisfal for the Undead). Every insert is anchored on a step with an explicit id of a start-zone
-- or shared segment. Phase C of docs/dev/PLAN.md (D.5); research docs/dev/research/classes.md 5.7, 6.1, 6.6.
-- Facts (NPC ids and positions, quest ids, chains, race masks, objective NPCs): tools/data/forever_db.lua.
-- Spell levels: classes.md 5.7 (the web list for Forever) for the key ones (4 Shadow Word: Pain, 10 Mind Blast, 20
-- Devouring Plague from the trainer, 32 Shadow Word: Death); the other ranks are the trainer lists of the original game
-- and only shown as text (the core never reads `spells`). CONFIRM in game.
--
-- What the class does here, speed first: the priest has the least class travel of all nine (classes.md 5.7). The file
-- is the letter at level 1, training at stops the path makes anyway (the three capitals all have priest trainers; the
-- Thunder Bluff ones stand in the Pools of Vision next to Zamah, whom the path visits four times), and the short class
-- quests that cost no or little travel: the robe at 6-10 (270 XP), the racial spell at 10 (Troll 210 XP, Undead
-- unknown) and at 20 (390 XP), each turned in where the path passes anyway.
--
-- Start zones (level before the step: validator --levels of the priest route, normal / worst):
--   Durotar (Troll)
--     after dur01-teeth        2.33   the letter 3085 at Gornek > Ken'jai (the Den, nothing to train at 2)
--     after dur01-den-4        4.68   Ken'jai in the Den: training 4 (start-camp trainers teach up to 6)
--     after dur02-rh-1         6.54   Tai'jin in Razor Hill (next to Turroc): training 6 + 5648; Grunt Kor'ja at the
--                                     south edge of Razor Hill, on the way to the quilboar south-west of it
--     after dur02-rh-2         7.88   Tai'jin: 5648 turned in (the robe; 8 is not reached yet)
--     after dur02-rh-3        10.01   Tai'jin: training 8 + 10, 5654 (the breadcrumb to Ur'kyo); the Razor Hill stop at
--                                     9.45 is merged into this one (8 is 0.6 level later, one visit less)
--     after h12-fp-uc    12.40 / 12.31  optional: the War Quarter of the Undercity (~70 s): training 12 (else at 14)
--   Tirisfal (Undead)
--     after ud01-364           2.61   the letter 3097 at Sarvis > Dark Cleric Duesten (same chapel)
--     after ud01-arren-4       4.01   Duesten: training 4 (ud01-church-4 is at 3.74)
--     after ud02-sethearth 6.41 / 6.33  Dark Cleric Beryl in the Brill inn: training 6 + 5650
--     after ud02-brill-8   8.18 / 8.13  Beryl: training 8
--     after ud02-holland-2 8.29 / 8.24  Deathguard Kel, 120 yd north of Holland (5650)
--     after ud02-terrence 10.16 / 10.07 Beryl: training 10, 5650 turned in (the robe)
--     after ud02-fp-uc   12.10 / 12.10  the War Quarter (Aelthalyste): training 12 + 5658 Touch of Weakness (accept and
--                                     turn in at once)
--   The breadcrumbs 5649 (Ken'jai > Tai'jin) and 5651 (Duesten > Beryl), 90 XP each, need level 5: the simulator
--   reaches the last start-camp stop (dur01-leave, ud01-381) at level 4, and a class level gate there would grind in
--   the wrong place. Not taken: 5648 / 5650 are offered without them.
--
-- Shared path (level before the insert; the two races are within 0.5 of each other from 14 on, from 22 on equal):
--   14     after h15-org          14.13 / 14.08 (Undead 14.62 / 14.55): the Valley of Spirits on the way from the inn to
--                                 the gate (~20 s); the Troll turns in 5654 (Hex of Weakness) on the same step.
--   16+18  after h18-tb-zamah     18.09 / 18.04 (Undead 18.19 / 18.05): Thunder Bluff, Pools of Vision, next to Zamah.
--   staves after h18-sethearth-tb optional: Ansekhwa, the weapon master by the inn (~15 s).
--   20     after h18-sethearth-tb optional, 20.38 / 20.25: from the inn to the Pools of Vision, then to Elder Rise
--                                 (~90 s): Flash Heal and Devouring Plague 1.7 levels earlier.
--   20+22  after h-22-tb-start    22.05: the Pools of Vision, next to Zamah; Miles Welsh also gives the level-20
--                                 racial quest: 5642 Shadowguard (Troll, to Ur'kyo) / 5644 Devouring Plague (Undead, to
--                                 Aelthalyste).
--   5642   after h-22-org-fp      22.05 (Troll): Ur'kyo, the Valley of Spirits between the flight master and the gate
--                                 (~25 s).
--   5644   after h22-uc-garrett   22.74 / 22.05 (Undead): Aelthalyste, the War Quarter, and back to the flight master
--                                 (~70 s).
--   24     after h-24-tb-arrive   24.88 / 24.05: the Pools of Vision, next to Zamah.
--   26     after h-27-tb-arrive   27.37 / 27.12: the Pools of Vision, next to Zamah.
--   28+30  after h-31-org         31.06 / 31.05: the Valley of Spirits on the way from the flight master to the gate
--                                 (~25 s).
--   32+34  after h-34-uc-arrive   34.10: the War Quarter (~70 s; the Undercity at 31.16 is before 32).
--   36     after h-37-orgrimmar   36.06: the Valley of Spirits between the gate and the city (~20 s).
--   38+40  after h-40-org-arrive  40.06 / 40.01: the Valley of Spirits on the way to the flight master (~40 s).
--   42+44  after h-44-uc-arrive   44.02 / 44.00: the War Quarter (~70 s; Orgrimmar at 41.0 is before 42).
--   46+48  after h-50-org-arrive  49.41 / 49.37: Ur'kyo, 50 yd from the step (Uthel'nay).
--   50+52  after h52-uc-81954     52.70 / 52.67: the War Quarter, ~250 yd from Owen Thadd (~60 s).
--   8254   after h-53-org-arrive  optional, 52.73: Cenarion Aid at Ur'kyo, Ogtinc in Azshara, 8255 (4 Healthy Courser
--                                 Glands from the Mosshoof Coursers south of the field loop): 5,610 XP for ~2.5 min.
--   54     after h56-sethearth-org 55.07: the Valley of Spirits between the inn and the flight master (~50 s).
--   56     after h-58-org-arrive  57.21 / 57.17: the Valley of Spirits between the inn and the gate (~30 s).
--   58+60  after h-60-end         optional: hearth to the Undercity (bound there by the path), the War Quarter.
-- Not visited: Orgrimmar at 11.1 (10 was trained at 10.0 in Razor Hill), Orgrimmar at 22.05 for training (Thunder Bluff
--   the same hour), Thunder Bluff at 28.3-28.7 and 30.9, the Undercity at 31.2, 41.0, 49.5 and 57.2-58, Orgrimmar at
--   41.0, 52.7 (training) and 53.05 (the level was just trained or is not reached yet; the stop chosen instead is named
--   above).
--
-- Skipped class quests (classes.md 5.7, Appendix A.PRIEST):
--   8256 > 8257 (the Ichor of Undeath from the Zanzil trolls of Stranglethorn at 43-44, behind the path by 52; then
--     Morphaz in the Sunken Temple): a dungeon chain; only 8254 + 8255 are routed (optional).
--   The breadcrumb variants 5655-5657, 5660-5663, 5643, 5646 and the direct ones 5652, 5680, 5679: one of each
--     exclusive group is routed (the one on the way); the others start at NPCs the path does not pass at that level.
--   5691-5693, 5704-5706 (index only, `<NYI>`), 7504 (Dire Maul book): not in scope.
-- Not routed: wands (the vendors Katis in Orgrimmar and Zane Bradford in the Undercity have no item list in the DB; the
--   best leveling wands are crafted or drop: the note of the training step at 14 says so); daggers (the Undercity
--   weapon master, nothing a caster needs). Staves: optional at Ansekhwa (Thunder Bluff), see above.
-- Class reward table: none. The DB snapshot has no reward lists; a wrong index would make the automation take the
--   wrong item. The notes say what to look for (the robe of 5648 / 5650 has one item; cloth with intellect / spirit).
--
-- Automation notes: every trainer that gives a quest of this file is visited on one merged step (train + accept /
-- turn-in): Tai'jin (5648, 5654; the 5648 turn-in at 7.88 is a visit of its own, no level to train), Beryl (5650),
-- Aelthalyste (5658), Miles Welsh (5642 / 5644), Ur'kyo (5654 turned in on the training step at 14). Every insert
-- follows a step the player has just done (an arrival, a hearth, a turn-in) and leaves the path where it was, or stands
-- before a shared `go` / `fly` / `hearth` that works from the new place.

if not AdventureAtlas.AddLibraryInsert then return end
local insert = AdventureAtlas.AddLibraryInsert

-- Durotar
local GORNEK = { 1411, 42.06, 68.33 }
local KENJAI = { 1411, 42.36, 68.81 }           -- 3707, Valley of Trials (teaches up to 6)
local TAIJIN = { 1411, 54.26, 42.93 }           -- 3706, Razor Hill
local KORJA = { 1411, 53.10, 46.46 }            -- 12430 Grunt Kor'ja (5648)
-- Tirisfal
local SARVIS = { 1420, 30.84, 66.20 }
local DUESTEN = { 1420, 31.11, 66.03 }          -- 2123, Deathknell (teaches up to 6)
local BERYL = { 1420, 61.57, 52.19 }            -- 2129, Brill (Gallows' End Tavern)
local KEL = { 1420, 59.18, 46.50 }              -- 12428 Deathguard Kel (5650)
-- Orgrimmar (Valley of Spirits)
local URKYO = { 1454, 35.59, 87.82 }            -- 6018
local ORG_TRAINERS = { 6018, 6014 }             -- Ur'kyo, X'yera
-- Thunder Bluff (Pools of Vision under Spirit Rise, next to Zamah)
local MILES = { 1456, 25.32, 15.27 }            -- 3044 Miles Welsh (5642 / 5644)
local COBB = { 1456, 25.64, 20.70 }             -- 3046 Father Cobb, the closest to Zamah
local TB_TRAINERS = { 3046, 3044, 3045 }        -- Father Cobb, Miles Welsh, Malakai Cross
local ANSEKHWA = { 1456, 40.93, 62.73 }         -- 11869, weapon master (Staves), by the inn
-- Undercity (War Quarter)
local AELTHALYSTE = { 1458, 49.26, 17.12 }      -- 4606
local UC_TRAINERS = { 4606, 4607, 4608 }        -- Aelthalyste, Father Lankester, Father Lazarus
-- Azshara
local OGTINC = { 1447, 42.40, 42.62 }           -- 8405

local function spell(ru, en) return { ru = ru, en = en } end
local NEW = { ru = " (новый ранг)", en = " (new rank)" }
local function rank(ru, en) return { ru = ru .. NEW.ru, en = en .. NEW.en } end

local function PAIN() return rank("Слово Тьмы: Боль", "Shadow Word: Pain") end
local function SHIELD() return rank("Слово силы: Щит", "Power Word: Shield") end
local function BLAST() return rank("Взрыв разума", "Mind Blast") end
local function RENEW() return rank("Обновление", "Renew") end
local function FLASH() return rank("Быстрое исцеление", "Flash Heal") end

------------------------------------------------------------------------------------------------------------------
-- Durotar (Troll) -----------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- The letter: Gornek hands it out in the dialog of the shared turn-in of 788; Ken'jai stands in the Den next to him.
insert({
    after = "dur01-teeth",
    class = "PRIEST",
    race = "Troll",
    steps = {
        { id = "pri-dur-letter", accept = 3085, npc = 3143, at = GORNEK,
          note = { ru = "Горнек даёт и письмо жреца: «Освящённая табличка».",
                   en = "Gornek also has the priest's letter: Hallowed Tablet." } },
        { id = "pri-dur-kenjai", turnin = 3085, npc = 3707, at = KENJAI,
          note = { ru = "Кен'джай — тренер жрецов, рядом в Логове (42,4, 68,8). Учить пока нечего (следующее — на 4-м).",
                   en = "Ken'jai, the priest trainer, close by in the Den (42.4, 68.8). Nothing to train yet (next at "
                       .. "4)." } },
    },
})
-- 4: Zureetha (the anchor) stands 30 yd from Ken'jai. The breadcrumb 5649 (Ken'jai > Tai'jin, 90 XP) needs level 5,
-- which the path reaches only at the gate north of the Den (dur01-lvl-5): not taken, Tai'jin gives 5648 without it.
insert({
    after = "dur01-den-4",
    class = "PRIEST",
    race = "Troll",
    steps = {
        { id = "pri-dur-train-4", train = true, npc = 3707, at = KENJAI,
          spells = { spell("Слово Тьмы: Боль", "Shadow Word: Pain"), rank("Малое исцеление", "Lesser Heal") },
          note = { ru = "Кен'джай в Логове: обучение 4-го уровня. «Слово Тьмы: Боль» первым, потом «Кара».",
                   en = "Ken'jai in the Den: level 4 training. Shadow Word: Pain first, then Smite." } },
    },
})
-- 6: Turroc (the anchor) stands next to the trainers; Grunt Kor'ja is at the south edge of Razor Hill, on the way to
-- the quilboar south-west of it.
insert({
    after = "dur02-rh-1",
    class = "PRIEST",
    race = "Troll",
    steps = {
        { id = "pri-dur-train-6", train = true, accept = 5648, npc = 3706, at = TAIJIN,
          spells = { spell("Слово силы: Щит", "Power Word: Shield"), rank("Кара", "Smite") },
          note = { ru = "Тай'джин, тренер жрецов Колючего Холма (рядом с Турроком): обучение 6-го уровня и «Одеяния "
                       .. "духовности» — вылечите и благословите рубаку Кор'джу на южной окраине.",
                   en = "Tai'jin, the Razor Hill priest trainer (next to Turroc): level 6 training and Garments of "
                       .. "Spirituality - heal and buff Grunt Kor'ja at the south edge." } },
        { id = "pri-dur-korja", complete = 5648, npc = 12430, at = KORJA,
          note = { ru = "Рубака Кор'джа (53,1, 46,5): «Малое исцеление», затем «Слово силы: Стойкость» на него. Потом "
                       .. "на юго-запад, по пути.",
                   en = "Grunt Kor'ja (53.1, 46.5): Lesser Heal, then Power Word: Fortitude on him. Then south-west, "
                       .. "on the way." } },
    },
})
insert({
    after = "dur02-rh-2",
    class = "PRIEST",
    race = "Troll",
    steps = {
        { id = "pri-dur-5648", turnin = 5648, npc = 3706, at = TAIJIN,
          note = { ru = "Тай'джин рядом с Турроком: сдайте «Одеяния духовности» и наденьте робу. Учить пока нечего "
                       .. "(8-й — на следующем заходе).",
                   en = "Tai'jin next to Turroc: turn in Garments of Spirituality and wear the robe. Nothing to train "
                       .. "yet (8 on the next visit)." } },
    },
})
-- 8 + 10 and the breadcrumb 5654 to Ur'kyo (turned in at 14 on the Orgrimmar training step).
insert({
    after = "dur02-rh-3",
    class = "PRIEST",
    race = "Troll",
    steps = {
        { id = "pri-dur-train-10", train = true, accept = 5654, npc = 3706, at = TAIJIN,
          spells = { spell("Взрыв разума", "Mind Blast"), spell("Обновление", "Renew"), spell("Уход в тень", "Fade"),
                     PAIN(), spell("Воскрешение", "Resurrection") },
          note = { ru = "Тай'джин: обучение 8-го и 10-го уровней и «Сглаз слабости» — к Ур'кьо в Оргриммар (сдаётся "
                       .. "на 14-м, по пути). «Взрыв разума» открывает бой, «Слово Тьмы: Боль» и «Щит» — дальше.",
                   en = "Tai'jin: level 8 and 10 training and Hex of Weakness - to Ur'kyo in Orgrimmar (turned in at "
                       .. "14, on the way). Open with Mind Blast, then Shadow Word: Pain and the Shield." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- The Undercity at 12 (Troll) -----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- 12 (optional): the War Quarter is ~240 yd from the flight master; the next shared step leads out through the
-- sewers and works from there. Skipped: 12 is trained at 14 in Orgrimmar.
insert({
    after = "h12-fp-uc",
    class = "PRIEST",
    race = "Troll",
    steps = {
        { id = "pri-train-12", train = true, optional = true, npc = UC_TRAINERS, at = AELTHALYSTE,
          spells = { spell("Внутренний огонь", "Inner Fire"), SHIELD(), rank("Слово силы: Стойкость",
                     "Power Word: Fortitude") },
          note = { ru = "Необязательно: Военный квартал Подгорода (на северо-запад от полётов, ~70 с крюка) — обучение "
                       .. "12-го уровня. Пропустили — выучите на 14-м в Оргриммаре.",
                   en = "Optional: the War Quarter of the Undercity (north-west of the flight master, ~70 s detour) - "
                       .. "level 12 training. Skipped - learn it at 14 in Orgrimmar." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Tirisfal (Undead) ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
insert({
    after = "ud01-364",
    class = "PRIEST",
    race = "Scourge",
    steps = {
        { id = "pri-tir-letter", accept = 3097, npc = 1569, at = SARVIS,
          note = { ru = "Сарвис даёт и письмо жреца: «Освящённый свиток».",
                   en = "Sarvis also has the priest's letter: Hallowed Scroll." } },
        { id = "pri-tir-duesten", turnin = 3097, npc = 2123, at = DUESTEN,
          note = { ru = "Тёмный клирик Дуэстен — тренер жрецов, в той же часовне. Учить пока нечего (следующее — на "
                       .. "4-м).",
                   en = "Dark Cleric Duesten, the priest trainer, in the same chapel. Nothing to train yet (next at "
                       .. "4)." } },
    },
})
-- ud01-church-4 is at 3.74; the next generic step in the chapel (Arren, 4.03) is past 4.
insert({
    after = "ud01-arren-4",
    class = "PRIEST",
    race = "Scourge",
    steps = {
        { id = "pri-tir-train-4", train = true, npc = 2123, at = DUESTEN,
          spells = { spell("Слово Тьмы: Боль", "Shadow Word: Pain"), rank("Малое исцеление", "Lesser Heal") },
          note = { ru = "Дуэстен в часовне: обучение 4-го уровня. «Слово Тьмы: Боль» первым, потом «Кара».",
                   en = "Duesten in the chapel: level 4 training. Shadow Word: Pain first, then Smite." } },
    },
})
insert({
    after = "ud02-sethearth",
    class = "PRIEST",
    race = "Scourge",
    steps = {
        -- The breadcrumb 5651 (Duesten > Beryl, 90 XP) needs level 5, which the path may not have at its last
        -- Deathknell stop (ud01-381): not taken, Beryl gives 5650 without it.
        { id = "pri-tir-train-6", train = true, accept = 5650, npc = 2129, at = BERYL,
          spells = { spell("Слово силы: Щит", "Power Word: Shield"), rank("Кара", "Smite") },
          note = { ru = "Тёмный клирик Берил в таверне Брилла: обучение 6-го уровня и «Одеяния тьмы» — вылечите и "
                       .. "благословите стражника смерти Кела к северу от Брилла (по пути, на 8-м).",
                   en = "Dark Cleric Beryl in the Brill inn: level 6 training and Garments of Darkness - heal and buff "
                       .. "Deathguard Kel north of Brill (on the way, at 8)." } },
    },
})
insert({
    after = "ud02-brill-8",
    class = "PRIEST",
    race = "Scourge",
    steps = {
        { id = "pri-tir-train-8", train = true, npc = 2129, at = BERYL,
          spells = { spell("Обновление", "Renew"), spell("Уход в тень", "Fade") },
          note = { ru = "Берил в таверне: обучение 8-го уровня.",
                   en = "Beryl in the inn: level 8 training." } },
    },
})
-- Holland (the anchor) is on the north-west edge of Brill; Kel stands 120 yd north of him by the road.
insert({
    after = "ud02-holland-2",
    class = "PRIEST",
    race = "Scourge",
    steps = {
        { id = "pri-tir-kel", complete = 5650, npc = 12428, at = KEL,
          note = { ru = "Стражник смерти Кел у дороги к северу (59,2, 46,5): «Малое исцеление», затем «Слово силы: "
                       .. "Стойкость» на него.",
                   en = "Deathguard Kel by the road to the north (59.2, 46.5): Lesser Heal, then Power Word: Fortitude "
                       .. "on him." } },
    },
})
-- 10: Terrence (the anchor) stands at the south edge, 30 yd from the inn.
insert({
    after = "ud02-terrence",
    class = "PRIEST",
    race = "Scourge",
    steps = {
        { id = "pri-tir-train-10", train = true, turnin = 5650, npc = 2129, at = BERYL,
          spells = { spell("Взрыв разума", "Mind Blast"), PAIN(), spell("Воскрешение", "Resurrection") },
          note = { ru = "Берил в таверне: сдайте «Одеяния тьмы» (наденьте робу) и обучение 10-го уровня. «Взрыв разума» "
                       .. "открывает бой, «Слово Тьмы: Боль» и «Щит» — дальше.",
                   en = "Beryl in the inn: turn in Garments of Darkness (wear the robe) and level 10 training. Open with "
                       .. "Mind Blast, then Shadow Word: Pain and the Shield." } },
    },
})
-- 12: Aelthalyste is a priest trainer and gives the racial quest 5658 (no objective: accept and turn in at once).
insert({
    after = "ud02-fp-uc",
    class = "PRIEST",
    race = "Scourge",
    steps = {
        -- CONFIRM: what 5658 teaches in Forever (classes.md 7: the Undead racial pair is Touch of Weakness + Dark
        -- Sacrifice)
        { id = "pri-tir-train-12", train = true, accept = 5658, turnin = 5658, npc = 4606, at = AELTHALYSTE,
          spells = { spell("Внутренний огонь", "Inner Fire"), SHIELD(), rank("Слово силы: Стойкость",
                     "Power Word: Fortitude") },
          note = { ru = "Военный квартал (на северо-запад от полётов): Аэлталиста — «Касание слабости» (возьмите и сразу "
                       .. "сдайте: расовое заклинание) и обучение 12-го уровня у неё же. Потом к лифту.",
                   en = "The War Quarter (north-west of the flight master): Aelthalyste - Touch of Weakness (accept and "
                       .. "turn in at once: the racial spell) and level 12 training from her. Then to the lift." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 14-22 ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- 14: from the inn to the main gate the Valley of Spirits is ~20 s off the way (both races pass here). The Troll's
-- 5654 is turned in to Ur'kyo on the same step (he is a trainer: one merged visit).
insert({
    after = "h15-org",
    class = "PRIEST",
    race = "Troll",
    steps = {
        { id = "pri-train-14-troll", train = true, turnin = 5654, npc = 6018, at = URKYO,
          spells = { spell("Ментальный крик", "Psychic Scream"), RENEW(), rank("Кара", "Smite"),
                     spell("Излечение болезни", "Cure Disease") },
          note = { ru = "По пути к главным воротам — Аллея Духов (юго-запад города): Ур'кьо — сдайте «Сглаз слабости» "
                       .. "(расовое заклинание) и обучение 14-го уровня (и 12-го, если пропустили). Жезл — лучшее "
                       .. "оружие жреца на прокачке: добивайте им, чтобы копилась мана.",
                   en = "On the way to the main gate - the Valley of Spirits (south-west of the city): Ur'kyo - turn in "
                       .. "Hex of Weakness (the racial spell) and level 14 training (and 12 if you skipped it). A wand "
                       .. "is the priest's best leveling weapon: finish targets with it to save mana." } },
    },
})
insert({
    after = "h15-org",
    class = "PRIEST",
    race = "Scourge",
    steps = {
        { id = "pri-train-14-undead", train = true, npc = ORG_TRAINERS, at = URKYO,
          spells = { spell("Ментальный крик", "Psychic Scream"), RENEW(), rank("Кара", "Smite"),
                     spell("Излечение болезни", "Cure Disease") },
          note = { ru = "По пути к главным воротам — Аллея Духов (юго-запад города): тренеры жрецов (Ур'кьо, Кс'йера) — "
                       .. "обучение 14-го уровня. Жезл — лучшее оружие жреца на прокачке: добивайте им, чтобы копилась "
                       .. "мана.",
                   en = "On the way to the main gate - the Valley of Spirits (south-west of the city): the priest "
                       .. "trainers (Ur'kyo, X'yera) - level 14 training. A wand is the priest's best leveling weapon: "
                       .. "finish targets with it to save mana." } },
    },
})
-- 16 + 18: Zamah's cave is the Pools of Vision; the priest trainers stand around the pools.
insert({
    after = "h18-tb-zamah",
    class = "PRIEST",
    steps = {
        { id = "pri-train-18", train = true, npc = TB_TRAINERS, at = COBB,
          spells = { spell("Исцеление", "Heal"), BLAST(), spell("Рассеивание заклинаний", "Dispel Magic"), SHIELD(),
                     PAIN() },
          note = { ru = "Пруды Видений: тренеры жрецов рядом с Замой (Отец Кобб, Майлз Уэлш) — обучение 16-го и 18-го "
                       .. "уровней.",
                   en = "The Pools of Vision: the priest trainers next to Zamah (Father Cobb, Miles Welsh) - level 16 "
                       .. "and 18 training." } },
    },
})
-- Staves (optional) and 20 (optional): Ansekhwa stands by the inn; from the inn the Pools of Vision are on the west
-- mesa, Elder Rise (the next shared step) on the east one: ~90 s more. Skipped: 20 is trained at 22, at the same pools.
insert({
    after = "h18-sethearth-tb",
    class = "PRIEST",
    steps = {
        -- CONFIRM: whether a Forever priest already knows Staves (classes.md 6.1: maces, daggers, staves can be learned)
        { id = "pri-staves", manual = true, optional = true, npc = 11869, at = ANSEKHWA,
          spells = { spell("Посохи", "Staves") },
          note = { ru = "Необязательно (~15 с): Ансехва, мастер оружия рядом с таверной, — навык «Посохи» (10 серебра), "
                       .. "если его нет в окне навыков. Посох с интеллектом — лучшее оружие заклинателя до жезла. "
                       .. "Готово — «Вперёд».",
                   en = "Optional (~15 s): Ansekhwa, the weapon master next to the inn - Staves (10 silver), if the "
                       .. "skill window does not list it. A staff with intellect is the best caster weapon besides the "
                       .. "wand. Done - press Next." } },
        { id = "pri-train-20", train = true, optional = true, npc = TB_TRAINERS, at = COBB,
          spells = { spell("Быстрое исцеление", "Flash Heal"), spell("Всепожирающая чума", "Devouring Plague"),
                     rank("Внутренний огонь", "Inner Fire"), RENEW() },
          note = { ru = "Необязательно (~90 с): от таверны по мосту на Вершину Духов, вниз в Пруды Видений — обучение "
                       .. "20-го уровня; потом на Вершину Старейшин. Пропустили — выучите на 22-м там же. С 20-го "
                       .. "возьмите талант «Пытка разума».",
                   en = "Optional (~90 s): from the inn over the bridge to Spirit Rise, down into the Pools of Vision - "
                       .. "level 20 training; then to Elder Rise. Skipped - learn it at 22 at the same place. From 20 "
                       .. "take the Mind Flay talent." } },
    },
})
-- 20 + 22 and the level-20 racial quest: Miles Welsh gives it and trains; Zamah (the anchor) stands next to him.
insert({
    after = "h-22-tb-start",
    class = "PRIEST",
    race = "Troll",
    steps = {
        { id = "pri-train-22-troll", train = true, accept = 5642, npc = 3044, at = MILES,
          spells = { spell("Быстрое исцеление", "Flash Heal"), spell("Всепожирающая чума", "Devouring Plague"),
                     BLAST(), rank("Исцеление", "Heal") },
          note = { ru = "Майлз Уэлш, тренер жрецов рядом с Замой: обучение 22-го уровня (и 20-го, если пропустили) и "
                       .. "«Страж тьмы» — к Ур'кьо в Оргриммар, куда путь летит сейчас.",
                   en = "Miles Welsh, the priest trainer next to Zamah: level 22 training (and 20 if you skipped it) and "
                       .. "Shadowguard - to Ur'kyo in Orgrimmar, where the path flies now." } },
    },
})
insert({
    after = "h-22-tb-start",
    class = "PRIEST",
    race = "Scourge",
    steps = {
        { id = "pri-train-22-undead", train = true, accept = 5644, npc = 3044, at = MILES,
          spells = { spell("Быстрое исцеление", "Flash Heal"), spell("Всепожирающая чума", "Devouring Plague"),
                     BLAST(), rank("Исцеление", "Heal") },
          note = { ru = "Майлз Уэлш, тренер жрецов рядом с Замой: обучение 22-го уровня (и 20-го, если пропустили) и "
                       .. "«Всепожирающая чума» — к Аэлталисте в Подгород, куда путь идёт через Оргриммар.",
                   en = "Miles Welsh, the priest trainer next to Zamah: level 22 training (and 20 if you skipped it) and "
                       .. "Devouring Plague - to Aelthalyste in the Undercity, where the path goes via Orgrimmar." } },
    },
})
-- Troll: the Valley of Spirits lies between the flight master and the main gate (the next shared step is the zeppelin
-- outside the gate).
insert({
    after = "h-22-org-fp",
    class = "PRIEST",
    race = "Troll",
    steps = {
        -- CONFIRM: what 5642 teaches in Forever (classes.md 7: the Troll racial pair is Hex of Weakness + Shadowguard)
        { id = "pri-5642", turnin = 5642, npc = 6018, at = URKYO,
          note = { ru = "От полётов к главным воротам через Аллею Духов (~25 с): Ур'кьо — сдайте «Страж тьмы» "
                       .. "(расовое заклинание).",
                   en = "From the flight master to the main gate through the Valley of Spirits (~25 s): Ur'kyo - turn "
                       .. "in Shadowguard (the racial spell)." } },
    },
})
-- Undead: from the flight master to the War Quarter and back (the next shared step flies from Michael Garrett).
insert({
    after = "h22-uc-garrett",
    class = "PRIEST",
    race = "Scourge",
    steps = {
        -- CONFIRM: what 5644 teaches in Forever (classes.md 7: Devouring Plague is a trainer spell there)
        { id = "pri-5644", turnin = 5644, npc = 4606, at = AELTHALYSTE,
          note = { ru = "Военный квартал (на северо-запад от полётов, ~70 с туда и обратно): Аэлталиста — сдайте "
                       .. "«Всепожирающую чуму». Потом обратно к Майклу Гаррету.",
                   en = "The War Quarter (north-west of the flight master, ~70 s there and back): Aelthalyste - turn in "
                       .. "Devouring Plague. Then back to Michael Garrett." } },
    },
})

------------------------------------------------------------------------------------------------------------------
-- Shared path 24-60 ---------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
insert({
    after = "h-24-tb-arrive",
    class = "PRIEST",
    steps = {
        { id = "pri-train-24", train = true, npc = TB_TRAINERS, at = COBB,
          spells = { SHIELD(), rank("Слово силы: Стойкость", "Power Word: Fortitude"),
                     spell("Сожжение маны", "Mana Burn") },
          note = { ru = "Пруды Видений, рядом с Замой: обучение 24-го уровня.",
                   en = "The Pools of Vision, next to Zamah: level 24 training." } },
    },
})
insert({
    after = "h-27-tb-arrive",
    class = "PRIEST",
    steps = {
        { id = "pri-train-26", train = true, npc = TB_TRAINERS, at = COBB,
          spells = { PAIN(), RENEW(), FLASH() },
          note = { ru = "Пруды Видений, рядом с Замой: обучение 26-го уровня.",
                   en = "The Pools of Vision, next to Zamah: level 26 training." } },
    },
})
-- 28 + 30: the path flies into Orgrimmar and walks out of the main gate to the zeppelin; the Valley of Spirits is
-- ~25 s off that way.
insert({
    after = "h-31-org",
    class = "PRIEST",
    steps = {
        { id = "pri-train-30", train = true, npc = ORG_TRAINERS, at = URKYO,
          spells = { BLAST(), SHIELD(), rank("Внутренний огонь", "Inner Fire"),
                     spell("Защита от тёмной магии", "Shadow Protection"), rank("Пытка разума", "Mind Flay") },
          note = { ru = "От полётов к главным воротам через Аллею Духов: обучение 28-го и 30-го уровней (ранг «Пытки "
                       .. "разума» — если талант взят).",
                   en = "From the flight master to the main gate through the Valley of Spirits: level 28 and 30 "
                       .. "training (the Mind Flay rank if you have the talent)." } },
    },
})
-- 32 + 34: the War Quarter, north-west of the flight master; the next shared step is Faranell in the Apothecarium.
insert({
    after = "h-34-uc-arrive",
    class = "PRIEST",
    steps = {
        { id = "pri-train-34", train = true, npc = UC_TRAINERS, at = AELTHALYSTE,
          spells = { spell("Слово Тьмы: Смерть", "Shadow Word: Death"), BLAST(), PAIN(), FLASH() },
          note = { ru = "Военный квартал (на северо-запад от полётов): обучение 32-го и 34-го уровней. «Слово Тьмы: "
                       .. "Смерть» — добивание мгновенно.",
                   en = "The War Quarter (north-west of the flight master): level 32 and 34 training. Shadow Word: "
                       .. "Death is an instant finisher." } },
    },
})
-- 36: the Valley of Spirits lies between the main gate and the city centre.
insert({
    after = "h-37-orgrimmar",
    class = "PRIEST",
    steps = {
        { id = "pri-train-36", train = true, npc = ORG_TRAINERS, at = URKYO,
          spells = { SHIELD(), rank("Слово силы: Стойкость", "Power Word: Fortitude"),
                     rank("Пытка разума", "Mind Flay") },
          note = { ru = "От главных ворот — Аллея Духов (по пути): обучение 36-го уровня.",
                   en = "From the main gate - the Valley of Spirits (on the way): level 36 training." } },
    },
})
-- 38 + 40: from Keldran to the flight master (the next shared step) through the Valley of Spirits (~40 s).
insert({
    after = "h-40-org-arrive",
    class = "PRIEST",
    steps = {
        { id = "pri-train-40", train = true, npc = ORG_TRAINERS, at = URKYO,
          spells = { BLAST(), spell("Великое исцеление", "Greater Heal"), rank("Внутренний огонь", "Inner Fire"),
                     RENEW() },
          note = { ru = "Аллея Духов по пути к распорядителю полётов: обучение 38-го и 40-го уровней. На 40-м — талант "
                       .. "«Облик Тьмы»: в нём жрец бьёт сильнее и получает меньше урона.",
                   en = "The Valley of Spirits on the way to the flight master: level 38 and 40 training. At 40 take "
                       .. "the Shadowform talent: more damage dealt, less taken." } },
    },
})
-- 42 + 44: the path flies into the Undercity and leaves it by the lift to the zeppelin for Grom'gol.
insert({
    after = "h-44-uc-arrive",
    class = "PRIEST",
    steps = {
        { id = "pri-train-44", train = true, npc = UC_TRAINERS, at = AELTHALYSTE,
          spells = { PAIN(), SHIELD(), FLASH(), rank("Пытка разума", "Mind Flay") },
          note = { ru = "Военный квартал (на северо-запад от полётов): обучение 42-го и 44-го уровней. Потом к лифту и к "
                       .. "дирижаблю в Громгол.",
                   en = "The War Quarter (north-west of the flight master): level 42 and 44 training. Then to the lift "
                       .. "and the zeppelin to Grom'gol." } },
    },
})
-- 46 + 48: the shared turn-in of 3002 is in the Valley of Spirits, 50 yd from Ur'kyo.
insert({
    after = "h-50-org-arrive",
    class = "PRIEST",
    steps = {
        { id = "pri-train-48", train = true, npc = ORG_TRAINERS, at = URKYO,
          spells = { BLAST(), SHIELD(), rank("Слово силы: Стойкость", "Power Word: Fortitude"),
                     rank("Великое исцеление", "Greater Heal") },
          note = { ru = "Тренеры жрецов здесь же, в Аллее Духов (Ур'кьо): обучение 46-го и 48-го уровней.",
                   en = "The priest trainers right here in the Valley of Spirits (Ur'kyo): level 46 and 48 "
                       .. "training." } },
    },
})
-- 50 + 52: the War Quarter is ~250 yd from Owen Thadd; the next shared step leads to the zeppelin.
insert({
    after = "h52-uc-81954",
    class = "PRIEST",
    steps = {
        { id = "pri-train-52", train = true, npc = UC_TRAINERS, at = AELTHALYSTE,
          spells = { BLAST(), PAIN(), RENEW(), FLASH(), rank("Пытка разума", "Mind Flay") },
          note = { ru = "Военный квартал (от библиотеки на запад): обучение 50-го и 52-го уровней. Потом к лифту и "
                       .. "дирижаблю.",
                   en = "The War Quarter (west of the library): level 50 and 52 training. Then to the lift and the "
                       .. "zeppelin." } },
    },
})
-- Cenarion Aid (optional): 8254 at Ur'kyo, Ogtinc in central Azshara on the way to the field loop, the Mosshoof
-- Coursers south of the loop, back to Ogtinc on the way to the next shared step. 8256 / 8257 are not taken.
insert({
    after = "h-53-org-arrive",
    class = "PRIEST",
    steps = {
        { id = "pri-8254-accept", accept = 8254, optional = true, npc = 6018, at = URKYO,
          note = { ru = "Необязательно (~2,5 мин пути, 5,6 тыс. опыта): Ур'кьо в Аллее Духов — «Помощь Кенарию» (к "
                       .. "Огтинку в Азшару).",
                   en = "Optional (~2.5 min of travel, 5.6k XP): Ur'kyo in the Valley of Spirits - Cenarion Aid (to "
                       .. "Ogtinc in Azshara)." } },
    },
})
insert({
    before = "h-53-azshara-field-loop",
    class = "PRIEST",
    steps = {
        { id = "pri-8254-ogtinc", turnin = 8254, accept = 8255, optional = true, npc = 8405, at = OGTINC,
          note = { ru = "Огтинк на холме в центре Азшары (42,43), по пути на юго-запад: «Железы скакунов».",
                   en = "Ogtinc on the hill in central Azshara (42,43), on the way south-west: Of Coursers We "
                       .. "Know." } },
    },
})
insert({
    after = "h-53-azshara-field-loop",
    class = "PRIEST",
    steps = {
        -- CONFIRM: drop rate of the Healthy Courser Gland (not in the DB)
        { id = "pri-8255-coursers", complete = 8255, optional = true, at = { 1447, 36.1, 65.8 },
          note = { ru = "Мшистокопытные скакуны к югу (36,66): 4 «Здоровые железы скакуна». Выпадают не с каждого — "
                       .. "если не везёт, бросьте задание.",
                   en = "Mosshoof Coursers to the south (36,66): 4 Healthy Courser Glands. They do not drop from every "
                       .. "one - abandon the quest if you are unlucky." } },
        { id = "pri-8255-ogtinc", turnin = 8255, optional = true, npc = 8405, at = OGTINC,
          note = { ru = "Обратно к Огтинку. Следующее его задание (Ихор нежити из Тернистой долины) не берите.",
                   en = "Back to Ogtinc. Do not take his next quest (the Ichor of Undeath from Stranglethorn)." } },
    },
})
-- 54: from the inn through the Valley of Spirits to the flight master (the next shared step flies to Splintertree).
insert({
    after = "h56-sethearth-org",
    class = "PRIEST",
    steps = {
        { id = "pri-train-54", train = true, npc = ORG_TRAINERS, at = URKYO,
          spells = { SHIELD(), rank("Кара", "Smite"), rank("Великое исцеление", "Greater Heal") },
          note = { ru = "От таверны через Аллею Духов к распорядителю полётов: обучение 54-го уровня.",
                   en = "From the inn through the Valley of Spirits to the flight master: level 54 training." } },
    },
})
-- 56: the hearth lands at the inn, the path walks out of the main gate to the zeppelin past the Valley of Spirits.
insert({
    after = "h-58-org-arrive",
    class = "PRIEST",
    steps = {
        { id = "pri-train-56", train = true, npc = ORG_TRAINERS, at = URKYO,
          spells = { FLASH(), RENEW(), spell("Ментальный крик", "Psychic Scream") },
          note = { ru = "От таверны к главным воротам через Аллею Духов: обучение 56-го уровня.",
                   en = "From the inn to the main gate through the Valley of Spirits: level 56 training." } },
    },
})
-- 58 + 60 (optional): the route ends at Light's Hope; the path bound the stone in the Undercity at 57.
insert({
    after = "h-60-end",
    class = "PRIEST",
    steps = {
        { id = "pri-60-hearth", hearth = "Undercity", optional = true, at = { 1458, 67.74, 37.89 },
          note = { ru = "Необязательно: камень возвращения в Подгород (он там привязан).",
                   en = "Optional: hearth to the Undercity (the stone is bound there)." } },
        { id = "pri-train-60", train = true, optional = true, npc = UC_TRAINERS, at = AELTHALYSTE,
          spells = { BLAST(), PAIN(), rank("Великое исцеление", "Greater Heal"), SHIELD() },
          note = { ru = "Военный квартал: обучение 58-го и 60-го уровней.",
                   en = "The War Quarter: level 58 and 60 training." } },
    },
})
