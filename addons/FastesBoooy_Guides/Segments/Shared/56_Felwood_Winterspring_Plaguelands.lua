-- FastesBoooy_Guides / Segments / Shared / 56_Felwood_Winterspring_Plaguelands.lua
--
-- Library segment "h-56-felwood-winterspring-plaguelands": levels 56-60, class-neutral (Undead Paladin and Skyborne
-- Druid, Horde). Cenarion Hold -> hearth Gadgetzan -> fly Orgrimmar (4300, hearth) -> fly Splintertree Post -> north
-- into Felwood (Emerald Sanctuary, Bloodvenom Post, Jaedenar / Shadow Hold, Ruins of Constellas, Shatter Scar Vale)
-- -> Timbermaw Hold (Nafien) -> Winterspring (Salfa, Donova Snowden, Deadwood Cauldron and Toxic Horrors back in
-- Felwood, Everlook, Winterfall Village, Ice Thistle Hills, Darkwhisper Gorge) -> back through Timbermaw Hold to
-- Bloodvenom Post -> Emerald Sanctuary (Maybess) -> hearth Orgrimmar -> zeppelin -> Undercity (hearth) -> The Bulwark
-- and five Western Plaguelands loops (cauldron chain, Kirsta, Andorhal / Chromie, Mulgris, an excursion to Pamela in
-- Darrowshire) -> hearth Undercity -> Bulwark -> Eastern Plaguelands (Tirion, Nathanos, Light's Hope, north field,
-- Augustus / Egan, Undercroft) -> Light's Hope Chapel at 60.
-- Plan: research plan60.md section 4.12 / plan60.json segments[12] (all 38 anchors used with the plan's ids).
-- Coordinates: Forever uiMap 1451 (Silithus) / 1446 (Tanaris) / 1454 (Orgrimmar) / 1440 (Ashenvale) / 1448
-- (Felwood) / 1452 (Winterspring) / 1411 (Durotar) / 1420 (Tirisfal) / 1458 (Undercity) / 1422 (Western
-- Plaguelands) / 1423 (Eastern Plaguelands, Forever frame), map percent, from tools/data/forever_db.lua: NPC / object
-- spawns for npc / object steps, centroids of the objective mob / object spawns of the area used for complete steps
-- (h56 tools: research scratch h56/cen.lua, pts.lua, qd.lua); event points from the QuestieDB triggerEnd data.
-- ruRU names in the notes: Wowhead Forever ruRU tooltips (nether.wowhead.com/forever/ru/tooltip/...); places from
-- ruRU quest texts (Застава Отравленной Крови, Оплот Теней, долина Рваных Ран, крепость Древобрюхов, Круговзор,
-- Теснина Зловещего Шепота, Бастион, поле Джанис, Слезы Далсона, Призрачная ферма, пустошь Гаррона, Андорал,
-- Дольный Очаг, Часовня Последней Надежды, Перекресток Корина, Крипта, Сторожка Кель'Литиен).
--
-- Hub plan (Forever DB; every quest is open to Scourge and Skyborne Horde characters of any class):
--   ORG : 4300 (Jes'rimon), hearth Orgrimmar (used from Bloodvenom Post at the end of Kalimdor).
--   FEL : Grazle 8460; ES 5155 + 5156; Maybess 4102; Bloodvenom fp, 4505, 4521, 6162; Shadow Hold key 5202 > 5203
--         (escort); Jaedenar 5155; Constellas 4505 > 4506 (kitten); Shatter Scar 5156; ES 5155 > 5157, 5156, 5203 >
--         5204; Jaedenar well 5157; Rakaiah + Trey 5204 > 5385; ES 5157, 5385; Deadwood Village 8460 + Ror 6162;
--         Grazle 8460 > 8462; Bloodvenom 6162.
--   TIM : Nafien 8462, 8461 > 8465 (Deadwood in Felpaw Village); through Timbermaw Hold.
--   WSW : Salfa 8465 > 8464; Donova 980 + 3908 > 4842 + 5082; west Winterfall camps (5082, firewater flask 5083);
--         Donova 5083 > 5084; Deadwood Cauldron 5084 > 5085; Donova 5085 > 5086; Toxic Horrors (Felwood) 5086, Irontree
--         Warpwoods 4102;
--         Donova 5086 > 5087; runners 5087; Donova 5087.
--   WSE : Everlook fp, 4808 > 4809, 3783, (5054), 6029 + 6030; loop A: Raging Owlbeasts, (Ursius), yetis,
--         chimaeras, Winterfall Village (5082, 8464); Everlook 3783 > 977, 4809, (5054 > 5055); loop B: Ice
--         Thistle matriarchs (977), (Brumeran), Everlook 977, Darkwhisper Gorge 4842; Donova 4842 + 5082; Salfa 8464;
--         through Timbermaw Hold, Bloodvenom 4521; Maybess 4102; hearth Orgrimmar.
--   UC  : zeppelin; hearth Undercity; 81952 (Owen Thadd); 5094 (Balthazad); 3542; 3568 > 3569 > 3570; 5961 (Sylvanas).
--   WPL : Bulwark 6029 + 5405, 5094 > 5096, flame; L1 Scarlet camp 5096; Bulwark 5096 > 5098 + 5228, 5228 > 5229;
--         L2 Felstone (5021 > 5023, cauldron 5229 > 5230), Andorhal towers 5098; Bulwark 5230 > 5231, 5098 > 838 > 964;
--         L3 Dalson's Tears 5231 > 5232, Dalson's farm 5060, Kirsta 6004 > 6023 > 6025 (Northridge Scarlet, Radley,
--         Durgen, Hearthglen overlook), Chromie 4971 > 4972, Andorhal skeletons 964; Bulwark 5232 > 5233, 964;
--         L4 Mulgris 4984 > 4985, Writhing Haunt 5233 > 5234, Marlene 5142; Darrowshire (EPL) Pamela 5142 > 5149 >
--         5241 + 5152; Marlene 5152 > 5153 (monument), Chromie 5153 > 5154 (Andorhal tome) > 5210; Bulwark 5234 > 5235; L5 Gahrron's
--         Withering 5235 > 5236; hearth Undercity 5023 > 5049 > 5050; Bulwark 5236, 5238; Felstone 5050 > 5051.
--   EPL : Tirion 5542 + 5543 + 5544; south-west runts / bats / grubs; Nathanos 5961 > 6022 + 6042 + 6133; Corin's
--         Crossing 6022, central hounds / bats; Light's Hope fp, 5241 + 5210 > 5211 + 5181, 6030, (optional
--         Stratholme: 5251, 5212, 5243, 5214), 6021 + 5281; north field 6042 + frenzied hounds, lodge 6133, spirits 5211;
--         Augustus 6164, Egan 5281 (optional 5282 + Stratholme); Tirion 5542-5544 > 5742 > 5781; Nathanos 6022 + 6042 +
--         6133; Undercroft 5781 + 6021; Tirion 5781; Horgus' Skull + Marduk's Sword (5181); Light's Hope 5211 + 5181
--         (optional Stratholme turn-ins); level gate at the Diseased Flayers north of the chapel; Alen 6021 (end, 60).
-- XP (validator from ~55.0, Classic quest XP + objective kills, optional steps counted): Felwood + Winterspring
--   questing reaches ~56.3; h57-winterspring-grind (now mandatory, level 57 at the Ice Thistle matriarchs / patriarchs
--   / yetis 55-58, ~590 same-level kills) sets up the Plaguelands (quests 55-60); the rest is the end gate (59 + 98% at
--   the Diseased Flayers 57-59 right north of Light's Hope Chapel, after the chapel turn-ins; Alen's turn-in makes 60;
--   ~725 kills, ~860 without the optional steps). Incidental kills and rested XP are not modelled, so the real gates
--   are shorter.
-- Deviations from the plan (documented in the handoff):
--   * 3541 / 3507 were turned in by h-53, so Orgrimmar only takes 4300; the start uses the Gadgetzan hearth.
--   * 5163 (Umi 3) needs Sprinkle (Gadgetzan) and Quixxil (Un'Goro): skipped. 6603 (breadcrumb to 5082) skipped:
--     Donova comes before Everlook. 5121 / 5123 / 5128 (High Chief Winterfall, elite 59 with guards) not taken.
--   * 5086 (Toxic Horrors) are in Felwood, not in Winterspring: one extra trip back through Timbermaw Hold.
--   * 8470 / 8471 (ritual totems) need Neutral with Timbermaw Hold (start: Unfriendly): not routed; h-56-kernda is the
--     go step through the hold. 4741 / 5056 / 6135 / 6136 / 105 (elites or follow-ups that are never finished)
--     not taken; 5054 / 5055 (elite Ursius / Brumeran) optional.
--   * 6026 / 6041 (Smokey LaRue) need crafted items (thorium bars, bombs, triggers): skipped. 5901 (termites in the
--     Eastern Plaguelands, turned in at the Bulwark) skipped. 5845 (Symbol of Lost Honor, far north-east and back to
--     Tirion) skipped.
--   * Added: 8464 (Salfa), 5235 > 5236 > 5238 (end of the cauldron chain), 5021 > 5023 > 5049 > 5050 > 5051 (Janice /
--     Undercity, the UC hearth), 6021 (Zaeldarr, next to Mercutio), 5281 (a delivery to Egan; only its follow-up is
--     Stratholme), 5405 (Argent Dawn Commission, accept + turn in), 8465 turned in at Salfa (plan carried it).
--   * 5228 needs 5096 turned in first: the Bulwark gets one more visit (Scarlet camp loop first).
--   * Not taken (densify scan): 5901 / 5902 / 6390 termites (mounds in the north-west of the Eastern Plaguelands,
--     turned in at the Bulwark - no Bulwark visit after it), 4741 Wild Guardians 2 (a second Winterspring trip), 6603 /
--     6605 / 5601 (breadcrumbs of quests already taken), 8470 / 8471 (Neutral with Timbermaw), Scholomance quests.
--   * Hearth: Orgrimmar (Felwood / Winterspring, used from Maybess south of Bloodvenom), Undercity (Plaguelands), not
--     Everlook.
--   * Densify pass (r3): added 8460 Timbermaw Ally > 8462 Speak to Nafien (Grazle; Deadwood Village next to Ror),
--     4102 Cleansing Felwood (Maybess; Blood Amber from the Irontree Warpwoods next to the Toxic Horrors), 81952
--     (library book looted in Azshara; Owen Thadd offers and takes the quest at once, XP unknown), 5094 (moved here
--     from the Undercity of h-50), the Redpath chain 5152 >
--     5153 > 5154 > 5210 > 5181 (the Pamela visit, same id h-58-pamela-redpath, moved into the Western Plaguelands loop
--     4 as an excursion to Darrowshire; Marlene, Joseph's monument, Chromie and the Andorhal tome on the way back;
--     Carlin's villains on the way from Tirion to the chapel), an optional Stratholme block (5251, 5212, 5243, 5214 at
--     the chapel, 5282 at Egan; the main gate is next to Terrordale). h57-winterspring-grind is mandatory now (57, no
--     longer 57 + 86%); the end gate moved after the chapel turn-ins (Diseased Flayers north of the chapel) so that
--     the optional Stratholme turn-ins count before it.
-- Automation notes: transient steps (fp, sethearth, hearth, fly, go) come before the quest steps of their hub; one
--   step per NPC; bg goals have a later non-bg finishing step; optional steps are followed by a mandatory anchor.
--   Class anchors: h-58-org-arrive / h-58-uc-arrive are at ~57.2 since the densify pass; the last Undercity stop
--   (after h59-hearth-uc) ends at ~57.99 and 58 comes at the Bulwark (h-59-wpl-end, ~58.05): the 58 ranks are best
--   trained with the 60 set after h-60-end (docs/routes/horde-22-60.md section 10).
if not FastesBoooy.AddLibraryInsert then return end
FastesBoooy.AddLibrarySegment({
    id = "h-56-felwood-winterspring-plaguelands",
    title = { ru = "56-60 Оскверненный лес, Зимние Ключи, Чумные земли",
              en = "56-60 Felwood, Winterspring, the Plaguelands" },
    zone = "Felwood",
    levels = { 56, 60 },
    steps = {
        ------------------------------------------------------------------
        -- Cenarion Hold -> Orgrimmar -> Felwood (level 56)
        ------------------------------------------------------------------
        { id = "h56-hearth-gadgetzan", hearth = "Gadgetzan", at = { 1446, 52.51, 27.91 },
          note = { ru = "Камень возвращения в Прибамбасск (на перезарядке — летите от Рунка прямо в Оргриммар).",
                   en = "Hearth to Gadgetzan (on cooldown - fly from Runk straight to Orgrimmar)." } },
        { id = "h56-fly-org", fly = "Orgrimmar", npc = 3310, at = { 1454, 45.12, 63.89 },
          note = { ru = "Булкрек Десница Гнева: летите в Оргриммар.", en = "Bulkrek Ragefist: fly to Orgrimmar." } },
        { id = "h-56-org-arrive", turnin = 4300, npc = 8659, at = { 1454, 55.52, 34.08 },
          note = { ru = "Джес'римон: «Костяные клинки».", en = "Jes'rimon: Bone-Bladed Weapons." } },
        { id = "h56-sethearth-org", sethearth = "Orgrimmar", npc = 6929, at = { 1454, 54.10, 68.41 },
          note = { ru = "Хозяйка таверны Гришка: привяжите камень (вернётесь им с Заставы Отравленной Крови).",
                   en = "Innkeeper Gryshka: bind the hearthstone (you hearth back from Bloodvenom Post)." } },
        { id = "h56-fly-splintertree", fly = "Splintertree Post", npc = 12616, at = { 1440, 73.18, 61.59 },
          note = { ru = "Дорас: летите на Заставу Расщепленного Дерева (Ясеневый лес).",
                   en = "Doras: fly to Splintertree Post (Ashenvale)." } },
        { id = "h56-felwood-road", go = true, radius = 60, at = { 1448, 52.00, 89.00 },
          note = { ru = "На запад по главной дороге, затем по дороге на север в Оскверненный лес. Деревня Мертвого "
                       .. "Леса (48-50) — западнее дороги.",
                   en = "West along the main road, then the road north into Felwood. Deadwood Village (48-50) is "
                       .. "west of the road." } },

        ------------------------------------------------------------------
        -- Felwood: Emerald Sanctuary, Bloodvenom Post, Jaedenar (level 56)
        ------------------------------------------------------------------
        { accept = 8460, npc = 11554, at = { 1448, 50.93, 85.01 },
          note = { ru = "У дороги перед Изумрудным святилищем, Гразл (Древобрюхи): «Союзник Древобрюхов» (фурболги "
                       .. "деревни Мертвого Леса чуть южнее — позже, вместе с властителем Рором).",
                   en = "By the road before the Emerald Sanctuary, Grazle (Timbermaw): Timbermaw Ally (the Deadwood "
                       .. "furbolgs just south - later, together with Overlord Ror)." } },
        { id = "h-56-emerald-sanctuary", accept = 5155, npc = 10922, at = { 1448, 51.21, 82.11 },
          note = { ru = "Изумрудное святилище, Грета Замшелое Копыто: «Силы Джеденара».",
                   en = "Emerald Sanctuary, Greta Mosshoof: Forces of Jaedenar." } },
        { accept = 5156, npc = 10921, at = { 1448, 50.89, 81.62 },
          note = { ru = "Тарун Красное Перо: «Проверка на порчу» (долина Рваных Ран, позже).",
                   en = "Taronn Redfeather: Verifying the Corruption (Shatter Scar Vale, later)." } },
        { accept = 4102, npc = 9529, at = { 1448, 46.75, 83.13 },
          note = { ru = "Западнее святилища, Мэйбесс Речной Ветер: «Очищение Оскверненного леса» (15 кровавых янтарей — с "
                       .. "древесных живодеров и кромсателей на севере, позже).",
                   en = "West of the sanctuary, Maybess Riverbreeze: Cleansing Felwood (15 Blood Amber - from the Warpwood "
                       .. "Moss Flayers and Shredders in the north, later)." } },
        { id = "h-56-bloodvenom-arrive", fp = "Bloodvenom Post", npc = 11900, at = { 1448, 34.44, 53.96 },
          note = { ru = "На северо-запад по дороге: Застава Отравленной Крови, Браккар — точка полёта.",
                   en = "North-west along the road: Bloodvenom Post, Brakkar - learn the flight point." } },
        { accept = 4505, npc = 9996, at = { 1448, 34.21, 52.34 },
          note = { ru = "Винна Хеззард: «Источник порчи» (флакон).", en = "Winna Hazzard: Well of Corruption (a flask)." } },
        { accept = 4521, npc = 10306, at = { 1448, 34.73, 52.79 },
          note = { ru = "Трулл Баловень Судьбы: «Одичавшие стражи» (совухи в Зимних Ключах, позже).",
                   en = "Trull Failbane: Wild Guardians (owlbeasts in Winterspring, later)." } },
        { accept = 6162, npc = 9620, at = { 1448, 34.80, 52.73 },
          note = { ru = "Дрека'Сур: «Последняя битва супруга» (властитель Рор на юге, позже).",
                   en = "Dreka'Sur: A Husband's Last Battle (Overlord Ror in the south, later)." } },
        { id = "h56-shadowhold-entrance", go = true, radius = 15, at = { 1448, 35.45, 59.06 },
          note = { ru = "Южнее заставы, Джеденар: вход в пещеру Оплот Теней (35.5,59.1).",
                   en = "South of the post, Jaedenar: the entrance of the Shadow Hold cave (35.5,59.1)." } },
        { complete = 5155, bg = true, at = { 1448, 37.34, 60.76 },
          note = { ru = "Попутно в Джеденаре: 4 гончих, 4 стража, 6 адептов, 6 сектантов (50-52).",
                   en = "On the way in Jaedenar: 4 Hounds, 4 Guardians, 6 Adepts, 6 Cultists (50-52)." } },
        { accept = 5202, use = 13140, at = { 1448, 37.89, 50.66 },
          note = { ru = "В пещере: головорезы, темноплеты, чернокнижники и легионеры Джеденара (52-55) — с них странный "
                       .. "красный ключ, нажмите его.",
                   en = "In the cave: Jaedenar Enforcers, Darkweavers, Warlocks and Legionnaires (52-55) drop the Blood "
                       .. "Red Key - click it." } },
        { id = "h-56-captured-arko-narin", turnin = 5202, accept = 5203, npc = 11016, at = { 1448, 36.21, 55.47 },
          note = { ru = "Пленная Арко'нарина в пещере: ключ; возьмите «Спасение из Джеденара» (сопровождение).",
                   en = "Captured Arko'narin in the cave: the key; take Rescue From Jaedenar (escort)." } },
        { complete = 5203, at = { 1448, 35.45, 59.06 },
          note = { ru = "Она идёт за снаряжением вглубь, затем к выходу (35.5,59.1); по пути нападают — защищайте её.",
                   en = "She goes deeper for her gear, then to the exit (35.5,59.1); mobs attack on the way - protect "
                       .. "her." } },
        { id = "h-56-felwood-field-loop", complete = 5155, at = { 1448, 37.34, 60.76 },
          note = { ru = "Джеденар снаружи: добейте гончих, стражей, адептов и сектантов.",
                   en = "Jaedenar outside: finish the Hounds, Guardians, Adepts and Cultists." } },
        { complete = 4505, use = 12566, at = { 1448, 32.32, 66.56 },
          note = { ru = "На юго-запад, руины с сатирами Нефритового Пламени (50-52): наполните флакон у оскверненного "
                       .. "лунного колодца.",
                   en = "South-west, the ruins with Jadefire satyrs (50-52): fill the flask at the corrupted moonwell." } },
        { turnin = 4505, accept = 4506, npc = 9996, at = { 1448, 34.21, 52.34 },
          note = { ru = "Назад к Винне: возьмите «Зараженные саблезубы» (переноска с котенком).",
                   en = "Back to Winna: take Corrupted Sabers (the kitten carrier)." } },
        { go = true, radius = 20, use = 12565, at = { 1448, 32.32, 66.56 },
          note = { ru = "Снова к лунному колодцу: выпустите котенка у колодца (переноска).",
                   en = "Back to the moonwell: release the kitten next to it (the carrier)." } },
        { complete = 4506, at = { 1448, 34.26, 52.32 },
          note = { ru = "Оскверненная кошка идёт за вами: приведите её к Винне и щелкните по ней.",
                   en = "The corrupted cat follows you: lead it to Winna and click it." } },
        { turnin = 4506, npc = 9996, at = { 1448, 34.21, 52.34 },
          note = { ru = "Винна: «Зараженные саблезубы».", en = "Winna: Corrupted Sabers." } },
        { complete = 5156, at = { 1448, 42.53, 40.31 },
          note = { ru = "На север по дороге: долина Рваных Ран — 2 энтропических зверя, 2 ужаса и осмотрите кратер "
                       .. "(41.0,42.0).",
                   en = "North along the road: Shatter Scar Vale - 2 Entropic Beasts, 2 Horrors and look at the crater "
                       .. "(41.0,42.0)." } },
        { turnin = 5155, accept = 5157, npc = 10922, at = { 1448, 51.21, 82.11 },
          note = { ru = "Назад в Изумрудное святилище. Грета: возьмите «Собрать оскверненную воду».",
                   en = "Back to the Emerald Sanctuary. Greta: take Collection of the Corrupt Water." } },
        { turnin = 5156, npc = 10921, at = { 1448, 50.89, 81.62 },
          note = { ru = "Тарун: проверка.", en = "Taronn: the verification." } },
        { turnin = 5203, accept = 5204, npc = 11019, at = { 1448, 51.35, 82.01 },
          note = { ru = "Джессира Лунная Радуга: возьмите «Воздаяние Света».",
                   en = "Jessir Moonbow: take Retribution of the Light." } },
        { complete = 5157, use = 12922, at = { 1448, 35.17, 59.79 },
          note = { ru = "Джеденар: лунный колодец в центре — наберите воды во флягу.",
                   en = "Jaedenar: the moonwell in the middle - fill the canteen." } },
        { complete = 5204, at = { 1448, 38.30, 50.51 },
          note = { ru = "Снова в Оплот Теней, в глубину: суккуб Ракайа (56).",
                   en = "Back into Shadow Hold, at the back: the succubus Rakaiah (56)." } },
        { id = "h-56-remains-of-trey", turnin = 5204, accept = 5385, npc = 11020, at = { 1448, 38.50, 50.41 },
          note = { ru = "Останки Трея Светогорна рядом: возьмите продолжение (останки — Джессире).",
                   en = "The Remains of Trey Lightforge next to her: take the follow-up (the remains go to Jessir)." } },
        { turnin = 5157, npc = 10922, at = { 1448, 51.21, 82.11 },
          note = { ru = "Изумрудное святилище, Грета: вода. «Духовную помощь» (Степи) не берите.",
                   en = "Emerald Sanctuary, Greta: the water. Skip Seeking Spiritual Aid (the Barrens)." } },
        { turnin = 5385, npc = 11019, at = { 1448, 51.35, 82.01 },
          note = { ru = "Джессира: останки Трея.", en = "Jessir: Trey's remains." } },
        { complete = 8460, at = { 1448, 47.93, 90.80 },
          note = { ru = "На юг, деревня Мертвого Леса у дороги: по 6 воинов, следопытов и садовников Мертвого Леса (48-50).",
                   en = "South, Deadwood Village by the road: 6 Deadwood Warriors, Pathfinders and Gardeners (48-50)." } },
        { complete = 6162, at = { 1448, 48.23, 94.28 },
          note = { ru = "На юг, деревня Мертвого Леса у дороги: властитель Рор (51) — коготь.",
                   en = "South, Deadwood Village by the road: Overlord Ror (51) - his claw." } },
        { turnin = 8460, accept = 8462, npc = 11554, at = { 1448, 50.93, 85.01 },
          note = { ru = "Назад к Гразлу: фурболги; возьмите «Поговорите с Нафиэном» (у крепости Древобрюхов, позже).",
                   en = "Back to Grazle: the furbolgs; take Speak to Nafien (at Timbermaw Hold, later)." } },
        { id = "h-57-bloodvenom-end", turnin = 6162, npc = 9620, at = { 1448, 34.80, 52.73 },
          note = { ru = "Назад на Заставу Отравленной Крови: Дрека'Сур.", en = "Back to Bloodvenom Post: Dreka'Sur." } },

        ------------------------------------------------------------------
        -- Timbermaw Hold -> Winterspring west: Salfa, Donova (level 57)
        ------------------------------------------------------------------
        { id = "h-56-timbermaw-hold", turnin = 8462, accept = 8461, npc = 15395, at = { 1448, 64.77, 8.13 },
          note = { ru = "На север по дороге до конца леса: Нафиэн у входа в крепость Древобрюхов — сдайте «Поговорите с "
                       .. "Нафиэном», возьмите «Северные фурболги Мертвого Леса».",
                   en = "North along the road to the end of the forest: Nafien at the Timbermaw Hold entrance - turn in "
                       .. "Speak to Nafien, take Deadwood of the North." } },
        { complete = 8461, at = { 1448, 62.11, 8.88 },
          note = { ru = "Деревня фурболгов рядом (западнее и южнее): по 6 дозорных, мстителей и шаманов Мертвого Леса "
                       .. "(53-55). Котел в деревне (60.2,5.8) — позже.",
                   en = "The furbolg village next to it (west and south): 6 Deadwood Den Watchers, Avengers and Shamans "
                       .. "(53-55). The cauldron in the village (60.2,5.8) comes later." } },
        { turnin = 8461, accept = 8465, npc = 15395, at = { 1448, 64.77, 8.13 },
          note = { ru = "Нафиэн: возьмите «Разговор с Сальфой».", en = "Nafien: take Speak to Salfa." } },
        { id = "h-56-kernda", go = true, radius = 30, at = { 1448, 65.50, 3.52 },
          note = { ru = "Через крепость Древобрюхов (при «Неприязни» фурболги не нападают — не трогайте их). Кернда "
                       .. "берёт ритуальные тотемы только при «Равнодушии»: их пропускаем.",
                   en = "Through Timbermaw Hold (at Unfriendly the furbolgs do not attack - leave them alone). Kernda "
                       .. "takes the ritual totems only at Neutral: we skip them." } },
        { turnin = 8465, accept = 8464, npc = 11556, at = { 1452, 27.73, 34.50 },
          note = { ru = "Выход в Зимние Ключи: Сальфа — возьмите «Боевые действия в деревне Зимней Спячки».",
                   en = "Exit into Winterspring: Salfa - take Winterfall Activity." } },
        { id = "h-56-donova-snowden", turnin = { 980, 3908 }, accept = { 4842, 5082 }, npc = 9298,
          at = { 1452, 31.27, 45.16 },
          note = { ru = "На юг к горячим источникам: Донова Снегонора — «Новые источники» и «Тайна, покрытая мраком»; "
                       .. "возьмите «Выяснение причин» и «Угроза со стороны Зимней Спячки». «Эликсир Видере» не берите.",
                   en = "South to the hot springs: Donova Snowden - The New Springs and It's a Secret to Everybody; take "
                       .. "Strange Sources and Threat of the Winterfall. Skip The Videre Elixir." } },
        { complete = { [4521] = { 2 } }, bg = true, at = { 1452, 44.07, 38.79 },
          note = { ru = "Попутно на западе: 15 лохматых совухов (53-55).",
                   en = "On the way in the west: 15 Ragged Owlbeasts (53-55)." } },
        { id = "h-56-winterspring-field-loop", complete = { [5082] = { 1, 3 } }, at = { 1452, 36.38, 39.95 },
          note = { ru = "Лагеря Зимней Спячки (30-35,36 и 39-43,44): по 8 землепроходцев и тотемистов; дозорных — "
                       .. "сколько встретите. Ждите пустую флягу для огненной воды.",
                   en = "The Winterfall camps (30-35,36 and 39-43,44): 8 Pathfinders and 8 Totemics; Den Watchers as you "
                       .. "meet them. Watch for an Empty Firewater Flask." } },
        { accept = 5083, use = 12771, at = { 1452, 36.38, 39.95 },
          note = { ru = "Пустая фляга для огненной воды (с любого фурболга Зимней Спячки) — нажмите её.",
                   en = "Empty Firewater Flask (from any Winterfall furbolg) - click it." } },
        { turnin = 5083, accept = 5084, npc = 9298, at = { 1452, 31.27, 45.16 },
          note = { ru = "Донова: фляга; возьмите «Поддавшиеся порче» (котел в Оскверненном лесу).",
                   en = "Donova: the flask; take Falling to Corruption (the cauldron in Felwood)." } },
        { id = "h-56-deadwood-cauldron", turnin = 5084, accept = 5085, object = 176091, at = { 1448, 60.20, 5.84 },
          note = { ru = "Назад через крепость Древобрюхов: котел Мертвого Леса в деревне фурболгов (60.2,5.8); "
                       .. "возьмите «Таинственная слизь».",
                   en = "Back through Timbermaw Hold: the Deadwood Cauldron in the furbolg village (60.2,5.8); take "
                       .. "Mystery Goo." } },
        { turnin = 5085, accept = 5086, npc = 9298, at = { 1452, 31.27, 45.16 },
          note = { ru = "Через крепость к Донове: слизь; возьмите «Ядовитый Ужас».",
                   en = "Through the hold to Donova: the goo; take Toxic Horrors." } },
        { complete = 5086, at = { 1448, 49.72, 25.03 },
          note = { ru = "Снова через крепость в Оскверненный лес и на юго-запад (49.7,25.0): ядовитые ужасы (53-54) — "
                       .. "3 капли.",
                   en = "Through the hold into Felwood again, south-west (49.7,25.0): Toxic Horrors (53-54) - 3 "
                       .. "droplets." } },
        { complete = 4102, at = { 1448, 57.30, 19.30 },
          note = { ru = "Восточнее, лес Железного Дерева (57,19): древесные живодеры и кромсатели (52-54) — 15 кровавых "
                       .. "янтарей; дальше на северо-восток по дороге к крепости.",
                   en = "East of them, Irontree Woods (57,19): Warpwood Moss Flayers and Shredders (52-54) - 15 Blood "
                       .. "Amber; then north-east along the road to the hold." } },
        { turnin = 5086, accept = 5087, npc = 9298, at = { 1452, 31.27, 45.16 },
          note = { ru = "Назад к Донове: капли; возьмите «Гонцы Зимней Спячки».",
                   en = "Back to Donova: the droplets; take Winterfall Runners." } },
        { complete = 5087, at = { 1452, 27.94, 34.47 },
          note = { ru = "Гонцы Зимней Спячки (57) идут от выхода из крепости на восток: убейте гонца — ящик.",
                   en = "The Winterfall Runners (57) walk east from the hold exit: kill one - the crate." } },
        { turnin = 5087, npc = 9298, at = { 1452, 31.27, 45.16 },
          note = { ru = "Донова: ящик. «Верховный вождь племени Зимней Спячки» (элита 59 с охраной) не берите.",
                   en = "Donova: the crate. Skip High Chief Winterfall (elite 59 with guards)." } },

        ------------------------------------------------------------------
        -- Winterspring east: Everlook and two loops (level 57)
        ------------------------------------------------------------------
        { id = "h-57-everlook-arrive", fp = "Everlook", npc = 11139, at = { 1452, 60.47, 36.30 },
          note = { ru = "На восток в Круговзор (совухи по дороге): Югрек — точка полёта.",
                   en = "East to Everlook (owlbeasts on the way): Yugrek - learn the flight point." } },
        { turnin = 4808, accept = 4809, npc = 10468, at = { 1452, 61.63, 38.61 },
          note = { ru = "Фелнок Сталлист: письмо; возьмите «Рога стылодыхов».",
                   en = "Felnok Steelspring: the letter; take Chillwind Horns." } },
        { accept = 3783, npc = 10305, at = { 1452, 60.88, 37.62 },
          note = { ru = "Юми Румпельшникер: «Йети где-то рядом…» (10 шкур).",
                   en = "Umi Rumplesnicker: Are We There, Yeti? (10 furs)." } },
        { accept = 5054, npc = 10303, optional = true, at = { 1452, 61.93, 38.38 },
          note = { ru = "Необязательно: Шторм Призрачное Копыто — «Урсиус из щербозубов» (элитный медведь 56; берите, "
                       .. "если справитесь в одиночку).",
                   en = "Optional: Storm Shadowhoof - Ursius of the Shardtooth (elite bear 56; take it if you can solo "
                       .. "it)." } },
        { accept = { 6029, 6030 }, npc = 10431, at = { 1452, 61.35, 38.97 },
          note = { ru = "Грегор Грейстоун: два донесения (Бастион и Часовня Последней Надежды).",
                   en = "Gregor Greystone: two reports (the Bulwark and Light's Hope Chapel)." } },
        { complete = 4521, at = { 1452, 55.62, 33.76 },
          note = { ru = "К северо-западу от Круговзора: 15 бешеных совухов (51-62,28-37); лохматых добейте западнее "
                       .. "(47-55,35-43). Йети и химеры тут же — попутно.",
                   en = "North-west of Everlook: 15 Raging Owlbeasts (51-62,28-37); finish the Ragged ones just west "
                       .. "(47-55,35-43). Yetis and chimaeras there too - on the way." } },
        { complete = 5054, optional = true, at = { 1452, 60.92, 32.90 },
          note = { ru = "Необязательно: Урсиус (элита 56) на склоне к северо-западу от Круговзора.",
                   en = "Optional: Ursius (elite 56) on the slope north-west of Everlook." } },
        { complete = 3783, bg = true, at = { 1452, 67.36, 42.31 },
          note = { ru = "Попутно: йети с Холмов ледополоха (55-56) — 10 толстых шкур.",
                   en = "On the way: Ice Thistle Yetis (55-56) - 10 Thick Yeti Furs." } },
        { complete = 4809, bg = true, at = { 1452, 57.69, 43.48 },
          note = { ru = "Попутно: хладноветрые химеры (55-57) — 8 целых рогов.",
                   en = "On the way: Chillwind Chimaeras (55-57) - 8 Uncracked Chillwind Horns." } },
        { complete = { 5082, 8464 }, at = { 1452, 67.19, 36.78 },
          note = { ru = "На восток, деревня Зимней Спячки: 8 дозорных, 8 ведмедей, 8 шаманов (55-58).",
                   en = "East, Winterfall Village: 8 Den Watchers, 8 Ursa, 8 Shamans (55-58)." } },
        { complete = 3783, at = { 1452, 67.36, 42.31 },
          note = { ru = "Южнее, Холмы ледополоха: добейте шкуры йети.", en = "South, Ice Thistle Hills: finish the furs." } },
        { complete = 4809, at = { 1452, 66.47, 50.49 },
          note = { ru = "Дальше на юг: химеры — добейте рога.", en = "Further south: chimaeras - finish the horns." } },
        { turnin = 3783, accept = 977, npc = 10305, at = { 1452, 60.88, 37.62 },
          note = { ru = "Круговзор, Юми: шкуры; возьмите следующую часть (рога матриархов и патриархов).",
                   en = "Everlook, Umi: the furs; take the next part (horns from matriarchs and patriarchs)." } },
        { turnin = 4809, npc = 10468, at = { 1452, 61.63, 38.61 },
          note = { ru = "Фелнок: рога. «Назад к Тинки» не берите.", en = "Felnok: the horns. Skip Return to Tinkee." } },
        { turnin = 5054, accept = 5055, npc = 10303, optional = true, at = { 1452, 61.93, 38.38 },
          note = { ru = "Необязательно: Шторм — Урсиус; «Убить Брумеран» (элитная химера 58 на юге).",
                   en = "Optional: Storm - Ursius; Brumeran of the Chillwind (elite chimaera 58 in the south)." } },
        { complete = 977, at = { 1452, 69.20, 40.74 },
          note = { ru = "На восток, Холмы ледополоха: матриархи и патриархи ледополохов (56-58) — 2 рога.",
                   en = "East, Ice Thistle Hills: Ice Thistle Matriarchs and Patriarchs (56-58) - 2 horns." } },
        { id = "h57-winterspring-grind", level = 57, at = { 1452, 69.20, 40.74 },
          ok = { ["level-grind"] = 590 }, -- 584 kills in the normal run
          note = { ru = "Здесь же (матриархи, патриархи и йети 55-58 — самое плотное поле зоны) до 57-го: задания Чумных "
                       .. "земель — 55-60 (Дольный Очаг, пустошь Гаррона, Сторожка Кель'Литиен).",
                   en = "Right here (matriarchs, patriarchs and yetis 55-58 - the densest field of the zone) up to 57: the "
                       .. "Plaguelands quests are 55-60 (Hearthglen, Gahrron's Withering, Quel'Lithien Lodge)." } },
        { complete = 5055, optional = true, at = { 1452, 62.54, 57.90 },
          note = { ru = "Необязательно: Брумеран (элита 58) среди химер на юге.",
                   en = "Optional: Brumeran (elite 58) among the chimaeras in the south." } },
        { id = "h-58-everlook-end", turnin = 977, npc = 10305, at = { 1452, 60.88, 37.62 },
          note = { ru = "Круговзор, Юми: рога. Третью часть (механический йети в Прибамбасске и Ун'Горо) не берите.",
                   en = "Everlook, Umi: the horns. Skip the third part (the mechanical yeti for Gadgetzan and Un'Goro)." } },
        { turnin = 5055, npc = 10303, optional = true, at = { 1452, 61.93, 38.38 },
          note = { ru = "Необязательно: Шторм — Брумеран. «Ши-Ротам» (элита 60, призыв) не берите.",
                   en = "Optional: Storm - Brumeran. Skip Shy-Rotam (elite 60, summoned)." } },
        { complete = 4842, at = { 1452, 59.82, 74.25 },
          note = { ru = "Далеко на юг: дойдите до Теснины Зловещего Шепота (59.8,74.3).",
                   en = "Far south: walk to Darkwhisper Gorge (59.8,74.3)." } },
        { turnin = { 4842, 5082 }, npc = 9298, at = { 1452, 31.27, 45.16 },
          note = { ru = "На северо-запад через всю зону к Донове: источник и фурболги.",
                   en = "North-west across the zone to Donova: the source and the furbolgs." } },
        { turnin = 8464, npc = 11556, at = { 1452, 27.73, 34.50 },
          note = { ru = "Сальфа у входа в крепость.", en = "Salfa at the hold entrance." } },
        { id = "h58-timbermaw-back", go = true, radius = 30, at = { 1448, 64.77, 8.13 },
          note = { ru = "Через крепость Древобрюхов в Оскверненный лес.", en = "Through Timbermaw Hold into Felwood." } },
        { id = "h-58-bloodvenom-return", turnin = 4521, npc = 10306, at = { 1448, 34.73, 52.79 },
          note = { ru = "По дороге на юг на Заставу Отравленной Крови: Трулл — совухи. Продолжение не берите.",
                   en = "South along the road to Bloodvenom Post: Trull - the owlbeasts. Skip the follow-up." } },

        ------------------------------------------------------------------
        -- Orgrimmar -> Undercity (level 58)
        ------------------------------------------------------------------
        { turnin = 4102, npc = 9529, at = { 1448, 46.75, 83.13 },
          note = { ru = "По дороге на юг к Изумрудному святилищу, Мэйбесс: янтарь. Продолжения («Мазь ...») не берите.",
                   en = "South along the road to the Emerald Sanctuary, Maybess: the amber. Skip the follow-ups (Salve via "
                       .. "...)." } },
        { id = "h-58-org-arrive", hearth = "Orgrimmar", at = { 1454, 54.10, 68.41 },
          note = { ru = "Камень возвращения в Оргриммар.", en = "Hearth to Orgrimmar." } },
        { id = "h58-zeppelin-uc", go = true, radius = 15, npc = 9564, at = { 1411, 50.82, 13.54 },
          note = { ru = "Из главных ворот на восток к башне дирижаблей: Фрезза — дирижабль в Подгород.",
                   en = "Out through the main gate, east to the zeppelin tower: Frezza - the zeppelin to Undercity." } },
        { go = true, radius = 40, npc = 9566, at = { 1420, 60.74, 58.87 },
          note = { ru = "Прибытие в Тирисфальские леса (Запота), вниз в Подгород.",
                   en = "Arrival in Tirisfal Glades (Zapetta), down into Undercity." } },
        { id = "h-58-uc-arrive", sethearth = "Undercity", npc = 6741, at = { 1458, 67.74, 37.89 },
          note = { ru = "Хозяин таверны Норман: привяжите камень (вернётесь им из Западных Чумных "
                       .. "земель).",
                   en = "Innkeeper Norman: bind the hearthstone (you hearth back from the Western "
                       .. "Plaguelands)." } },
        { accept = 81952, complete = 81952, turnin = 81952, npc = 211022, at = { 1458, 73.40, 33.00 },
          note = { ru = "Квартал Магов, Оуэн Тэдд: книга «Этикет на каждый день» из Азшары - возьмите задание (книга в "
                       .. "сумках) и сразу сдайте.",
                   en = "Magic Quarter, Owen Thadd: the book Everyday Etiquette from Azshara - take the quest (the book "
                       .. "is in your bags) and turn it in at once." } },
        { accept = 5094, npc = 10879, at = { 1458, 63.90, 44.08 },
          note = { ru = "Предвестник Балтазад: «Призыв к оружию: Чумные земли!» (сдача в Бастионе).",
                   en = "Harbinger Balthazad: A Call to Arms: The Plaguelands! (turned in at the Bulwark)." } },
        { turnin = 3542, npc = 6522, at = { 1458, 54.81, 76.33 },
          note = { ru = "Андрон Гант (54.8,76.3): доставка. Его плату для Джедиги не берите.",
                   en = "Andron Gant (54.8,76.3): the delivery. Skip his payment for Jediga." } },
        { turnin = 3568, accept = 3569, npc = 8390, at = { 1458, 48.71, 71.39 },
          note = { ru = "Химик Карабос (48.7,71.4): пробы; отнесите их Терсе.",
                   en = "Chemist Cuely (48.7,71.4): the samples; take them to Thersa." } },
        { turnin = 3569, npc = 8393, at = { 1458, 49.04, 70.80 },
          note = { ru = "Терса Песня Ветра рядом.", en = "Thersa Windsong next to him." } },
        { accept = 3570, npc = 8390, at = { 1458, 48.71, 71.39 },
          note = { ru = "Химик Карабос: последняя часть «Разносчика порчи».",
                   en = "Chemist Cuely: the last part of Seeping Corruption." } },
        { turnin = 3570, npc = 8390, at = { 1458, 48.71, 71.39 },
          note = { ru = "Сдайте её ему же.", en = "Turn it in to him." } },
        { accept = 5961, npc = 10181, at = { 1458, 58.05, 91.79 },
          note = { ru = "Королевский квартал, леди Сильвана Ветрокрылая: «Защитник королевы банши» (Натанос в "
                       .. "Восточных Чумных землях).",
                   en = "Royal Quarter, Lady Sylvanas Windrunner: The Champion of the Banshee Queen (Nathanos in the "
                       .. "Eastern Plaguelands)." } },

        ------------------------------------------------------------------
        -- The Bulwark, Western Plaguelands loops 1-2: Scarlet camp, Felstone Field, Andorhal towers (level 58)
        ------------------------------------------------------------------
        { id = "h-58-bulwark-arrive", turnin = 6029, accept = 5405, npc = 10839, at = { 1420, 83.19, 68.45 },
          note = { ru = "Из Подгорода на восток по дороге в Бастион: офицер Гаруш — донесение из Круговзора; возьмите "
                       .. "«Жетон Серебряного Рассвета».",
                   en = "Out of Undercity, east along the road to the Bulwark: Argent Officer Garush - the Everlook "
                       .. "report; take Argent Dawn Commission." } },
        { turnin = 5405, npc = 10839, at = { 1420, 83.19, 68.45 },
          note = { ru = "Сразу сдайте его ему же (жетон — тринкет для камней Плети).",
                   en = "Turn it in to him at once (the commission is a trinket for Scourgestones)." } },
        { turnin = 5094, accept = 5096, npc = 10837, at = { 1420, 83.13, 68.94 },
          note = { ru = "Верховный палач Деррингтон: «Вылазка в стан Алого Марша».",
                   en = "High Executor Derrington: Scarlet Diversions." } },
        { collect = { [12814] = 1 }, object = 176092, at = { 1420, 83.17, 69.09 },
          note = { ru = "Ящик с зажигательной смесью рядом: возьмите пламя в бутылке. Термитов Мики не берите.",
                   en = "The Box of Incendiaries next to him: take a Flame in a Bottle. Skip Mickey's termites." } },
        { id = "h-57-western-plaguelands-field", complete = 5096, use = 12807, at = { 1422, 40.72, 52.04 },
          note = { ru = "На восток, лагерь Алого ордена (52-55): щелкните по командному шатру (пламя в бутылке его "
                       .. "подожжет) и поставьте знамя Плети (кнопка).",
                   en = "East, the Scarlet camp (52-55): click the command tent (the Flame in a Bottle burns it) and plant "
                       .. "the Scourge banner (the button)." } },
        { turnin = 5096, accept = { 5098, 5228 }, npc = 10837, at = { 1420, 83.13, 68.94 },
          note = { ru = "Назад в Бастион, Деррингтон: «Сторожевые башни» (сигнальный факел) и «Котлы Плети».",
                   en = "Back to the Bulwark, Derrington: All Along the Watchtowers (the Beacon Torch) and The Scourge "
                       .. "Cauldrons." } },
        { turnin = 5228, accept = 5229, npc = 11055, at = { 1420, 83.04, 71.91 },
          note = { ru = "Жрица Тьмы Вандис: «Цель: поле Джанис».", en = "Shadow Priestess Vandis: Target: Felstone Field." } },
        { accept = 5021, npc = 10778, at = { 1422, 38.40, 54.05 },
          note = { ru = "На восток, поле Джанис: Джанис Фелстоун — «Лучше поздно, чем никогда».",
                   en = "East, Felstone Field: Janice Felstone - Better Late Than Never." } },
        { turnin = 5021, accept = 5023, object = 175894, at = { 1422, 38.73, 55.24 },
          note = { ru = "Посылка Джанис рядом: возьмите продолжение (Подгород, позже).",
                   en = "Janice's Parcel next to her: take the follow-up (Undercity, later)." } },
        { complete = 5229, at = { 1422, 36.93, 57.41 },
          note = { ru = "Хранитель котла Желчень (53) у котла — ключ.",
                   en = "Cauldron Lord Bilemaw (53) by the cauldron - the key." } },
        { id = "h-57-felstone-field-cauldron", turnin = 5229, accept = 5230, object = 176361,
          at = { 1422, 37.25, 56.78 },
          note = { ru = "Котел Плети: откройте ключом, возьмите «Возвращение в Бастион».",
                   en = "The Scourge Cauldron: open it with the key, take Return to the Bulwark." } },
        { complete = 5098, use = 12815, at = { 1422, 43.32, 68.03 },
          note = { ru = "На юго-восток, Андорал: отметьте 4 башни факелом в дверях — 40.1,71.6; 42.3,66.2; 44.3,63.3; "
                       .. "46.6,71.1. Скелеты 53-56.",
                   en = "South-east, Andorhal: mark the 4 towers with the torch in their doorways - 40.1,71.6; 42.3,66.2; "
                       .. "44.3,63.3; 46.6,71.1. Skeletons 53-56." } },
        { turnin = 5230, accept = 5231, npc = 11055, at = { 1420, 83.04, 71.91 },
          note = { ru = "Назад в Бастион, Вандис: «Цель: Слезы Далсона».",
                   en = "Back to the Bulwark, Vandis: Target: Dalson's Tears." } },
        { turnin = 5098, accept = 838, npc = 10837, at = { 1420, 83.13, 68.94 },
          note = { ru = "Деррингтон: башни; «Некроситет» — к Дитерсу рядом.",
                   en = "Derrington: the towers; Scholomance - to Dithers next to him." } },
        { turnin = 838, accept = 964, npc = 11057, at = { 1420, 83.28, 69.23 },
          note = { ru = "Аптекарь Дитерс: «Фрагменты скелетов».", en = "Apothecary Dithers: Skeletal Fragments." } },

        ------------------------------------------------------------------
        -- Western Plaguelands loop 3: Dalson's Tears, Kirsta, Andorhal (level 58)
        ------------------------------------------------------------------
        { complete = 5231, at = { 1422, 46.11, 52.61 },
          note = { ru = "На восток, Слезы Далсона: хранитель котла Злобиус (55) — ключ.",
                   en = "East, Dalson's Tears: Cauldron Lord Malvinious (55) - the key." } },
        { id = "h-57-dalson-s-tears", turnin = 5231, accept = 5232, object = 177289, at = { 1422, 46.18, 51.90 },
          note = { ru = "Котел: откройте ключом, возьмите возвращение.", en = "The cauldron: open it, take the return." } },
        { id = "h-57-dalson-s-farm", accept = 5060, object = 175924, at = { 1422, 47.35, 49.63 },
          note = { ru = "Ферма Далсона рядом: запертый шкаф в доме — «Под замком».",
                   en = "Dalson's farm next to it: the Locked Cabinet in the house - Locked Away." } },
        { complete = 5060, at = { 1422, 48.23, 49.67 },
          note = { ru = "Фермер Далсон (56) в сарае — ключ от шкафа.",
                   en = "Farmer Dalson (56) in the barn - the cabinet key." } },
        { turnin = 5060, object = 175924, at = { 1422, 47.35, 49.63 },
          note = { ru = "Откройте шкаф.", en = "Open the cabinet." } },
        { id = "h-57-kirsta-deepshadow", accept = 6004, npc = 11610, at = { 1422, 51.92, 28.06 },
          note = { ru = "На север: Криста Чернотень у пещеры — «Неоконченное дело».",
                   en = "North: Kirsta Deepshadow by the cave - Unfinished Business." } },
        { id = "h-57-termite-barrel", complete = 6004, at = { 1422, 51.65, 39.41 },
          note = { ru = "Южнее, у лесопилки и лагеря Алого ордена (47-58,32-45): по 2 медика, охотника, мага и рыцаря.",
                   en = "South, by the lumber camp and the Scarlet camp (47-58,32-45): 2 Medics, Hunters, Mages and "
                       .. "Knights." } },
        { turnin = 6004, accept = 6023, npc = 11610, at = { 1422, 51.92, 28.06 },
          note = { ru = "Криста: продолжение (Охотник Радли и Кавалерист Дарген).",
                   en = "Kirsta: the follow-up (Huntsman Radley and Cavalier Durgen)." } },
        { complete = { [6023] = { 1 } }, at = { 1422, 57.83, 36.10 },
          note = { ru = "На юго-восток: Охотник Радли (56) у лесопилки.",
                   en = "South-east: Huntsman Radley (56) at the lumber camp." } },
        { complete = 6023, at = { 1422, 55.15, 23.62 },
          note = { ru = "На север: Кавалерист Дарген (57) на дороге к Дольному Очагу.",
                   en = "North: Cavalier Durgen (57) on the road to Hearthglen." } },
        { turnin = 6023, accept = 6025, npc = 11610, at = { 1422, 51.92, 28.06 },
          note = { ru = "Криста: последняя часть.", en = "Kirsta: the last part." } },
        { complete = 6025, at = { 1422, 45.81, 18.25 },
          note = { ru = "Дольный Очаг: поднимитесь на возвышенность (45.8,18.3) и осмотрите город. Алый орден 57-60 — "
                       .. "по одному.",
                   en = "Hearthglen: go up to the high point (45.8,18.3) and overlook the town. Scarlet 57-60 - one at a "
                       .. "time." } },
        { turnin = 6025, npc = 11610, at = { 1422, 51.92, 28.06 },
          note = { ru = "Криста: дело закрыто.", en = "Kirsta: business finished." } },
        { id = "h-57-chromie", accept = 4971, npc = 10667, at = { 1422, 39.46, 66.76 },
          note = { ru = "На юг в Андорал, таверна: Хроми — «Вопрос времени» (она даёт темпоральный смещатель).",
                   en = "South to Andorhal, the inn: Chromie - A Matter of Time (she gives you the Temporal "
                       .. "Displacer)." } },
        { complete = 964, bg = true, at = { 1422, 44.58, 68.47 },
          note = { ru = "Попутно в Андорале: скелеты-палачи и послушники (53-56) — 15 фрагментов.",
                   en = "On the way in Andorhal: Skeletal Executioners and Acolytes (53-56) - 15 fragments." } },
        { complete = 4971, use = 12627, at = { 1422, 48.14, 65.18 },
          note = { ru = "Восток Андорала: используйте темпоральный смещатель рядом с силосной башней, затем убейте "
                       .. "появившихся временных паразитов (55-57) - 15 по Wowhead Forever (в БД и WCLBox 10; верен "
                       .. "счётчик в журнале). Паразиты сами не стоят - без смещателя их нет.",
                   en = "East Andorhal: use the Temporal Displacer next to a silo, then kill the Temporal Parasites "
                       .. "(55-57) that appear - 15 per Wowhead Forever (the DB and WCLBox say 10; trust the quest log "
                       .. "counter). They do not stand around - no displacer, no parasites." } },
        { turnin = 4971, accept = 4972, npc = 10667, at = { 1422, 39.46, 66.76 },
          note = { ru = "Хроми: «Отсчет времени».", en = "Chromie: Counting Out Time." } },
        { complete = 4972, at = { 1422, 42.98, 70.07 },
          note = { ru = "Небольшие сундучки среди руин Андорала: 5 часов.",
                   en = "Small Lockboxes in the Andorhal rubble: 5 watches." } },
        { turnin = 4972, npc = 10667, at = { 1422, 39.46, 66.76 },
          note = { ru = "Хроми: часы.", en = "Chromie: the watches." } },
        { complete = 964, at = { 1422, 44.58, 68.47 },
          note = { ru = "Андорал: добейте фрагменты скелетов.", en = "Andorhal: finish the skeletal fragments." } },
        { turnin = 5232, accept = 5233, npc = 11055, at = { 1420, 83.04, 71.91 },
          note = { ru = "Назад в Бастион, Вандис: «Цель: Призрачная ферма».",
                   en = "Back to the Bulwark, Vandis: Target: Writhing Haunt." } },
        { turnin = 964, npc = 11057, at = { 1420, 83.28, 69.23 },
          note = { ru = "Дитерс: фрагменты. Продолжение (Некроситет) не берите.",
                   en = "Dithers: the fragments. Skip the follow-up (Scholomance)." } },

        ------------------------------------------------------------------
        -- Western Plaguelands loop 4: Writhing Haunt, Mulgris, Marlene (level 58)
        ------------------------------------------------------------------
        { id = "h-57-mulgris-deepriver", accept = 4984, npc = 10739, at = { 1422, 53.73, 64.66 },
          note = { ru = "На восток, Призрачная ферма: Мулгрис Глубокая Река — «Страдания природы».",
                   en = "East, Writhing Haunt: Mulgris Deepriver - The Wildlife Suffers Too." } },
        { complete = 5233, at = { 1422, 52.88, 66.08 },
          note = { ru = "Хранитель котла Разарх (56) — ключ.", en = "Cauldron Lord Razarch (56) - the key." } },
        { id = "h-57-writhing-haunt-cauldron", turnin = 5233, accept = 5234, object = 176393,
          at = { 1422, 53.02, 65.61 },
          note = { ru = "Котел: откройте ключом, возьмите возвращение.", en = "The cauldron: open it, take the return." } },
        { complete = 4984, at = { 1422, 49.34, 62.28 },
          note = { ru = "Вокруг фермы и к северу: 8 больных волков (53-54).",
                   en = "Around the farm and to the north: 8 Diseased Wolves (53-54)." } },
        { turnin = 4984, accept = 4985, npc = 10739, at = { 1422, 53.73, 64.66 },
          note = { ru = "Мулгрис: продолжение (гризли).", en = "Mulgris: the follow-up (grizzlies)." } },
        { complete = 4985, at = { 1422, 56.59, 55.03 },
          note = { ru = "На северо-восток: 8 болезненных гризли (55-56).", en = "North-east: 8 Diseased Grizzlies (55-56)." } },
        { turnin = 4985, npc = 10739, at = { 1422, 53.73, 64.66 },
          note = { ru = "Мулгрис: гризли. «Резную дубовую ветвь» (Громовой Утес) не берите.",
                   en = "Mulgris: the grizzlies. Skip Glyphed Oaken Branch (Thunder Bluff)." } },
        { id = "h-57-marlene-redpath", accept = 5142, npc = 10927, at = { 1422, 49.17, 78.57 },
          note = { ru = "На юг (49.2,78.6): Марлен Редпат у дома — «Малышка Памела».",
                   en = "South (49.2,78.6): Marlene Redpath at her house - Little Pamela." } },
        -- Darrowshire excursion (the Pamela visit moved here from the Eastern Plaguelands part): the Redpath chain needs
        -- Marlene (Western Plaguelands) between two Pamela steps; Chromie and the Musty Tome are in Andorhal on the way
        -- back to the Bulwark.
        { id = "h-58-pamela-redpath", turnin = 5142, accept = 5149, npc = 10926, at = { 1423, 31.15, 77.98 },
          note = { ru = "На восток через реку в Восточные Чумные земли, Дарроушир: Памела Редпат — «Кукла Памелы».",
                   en = "East across the river into the Eastern Plaguelands, Darrowshire: Pamela Redpath - Pamela's "
                       .. "Doll." } },
        { complete = 5149, use = 12886, at = { 1423, 33.39, 78.77 },
          note = { ru = "Голова и две половинки куклы лежат в домах Дарроушира (32.6-34.1, 77-80); соедините их.",
                   en = "The head and the two halves lie in the Darrowshire houses (32.6-34.1, 77-80); combine them." } },
        { turnin = 5149, accept = { 5241, 5152 }, npc = 10926, at = { 1423, 31.15, 77.98 },
          note = { ru = "Памела: кукла; возьмите «Дядюшка Карлин» (Часовня Последней Надежды, позже) и «Тетушка Марлен».",
                   en = "Pamela: the doll; take Uncle Carlin (Light's Hope Chapel, later) and Auntie Marlene." } },
        { turnin = 5152, accept = 5153, npc = 10927, at = { 1422, 49.17, 78.57 },
          note = { ru = "Назад на запад к Марлен Редпат: возьмите «Странный историк».",
                   en = "Back west to Marlene Redpath: take A Strange Historian." } },
        { complete = 5153, object = 176145, at = { 1422, 49.70, 76.80 },
          note = { ru = "Памятник Джозефу Редпату рядом с домом (49.7,76.8): обручальное кольцо Джозефа.",
                   en = "Joseph Redpath's Monument next to the house (49.7,76.8): Joseph's Wedding Ring." } },
        { turnin = 5153, accept = 5154, npc = 10667, at = { 1422, 39.46, 66.76 },
          note = { ru = "На северо-запад в Андорал, таверна: Хроми — «Летопись Дарроушира».",
                   en = "North-west to Andorhal, the inn: Chromie - The Annals of Darrowshire." } },
        { complete = 5154, object = 176150, at = { 1422, 43.45, 69.45 },
          note = { ru = "Ратуша Андорала (43.4,69.5): среди заплесневелых фолиантов найдите летопись.",
                   en = "Andorhal town hall (43.4,69.5): find the Annals among the Musty Tomes." } },
        { turnin = 5154, accept = 5210, npc = 10667, at = { 1422, 39.46, 66.76 },
          note = { ru = "Хроми: возьмите «Брат Карлин» (Часовня Последней Надежды, позже).",
                   en = "Chromie: take Brother Carlin (Light's Hope Chapel, later)." } },
        { turnin = 5234, accept = 5235, npc = 11055, at = { 1420, 83.04, 71.91 },
          note = { ru = "Назад в Бастион, Вандис: «Цель: пустошь Гаррона».",
                   en = "Back to the Bulwark, Vandis: Target: Gahrron's Withering." } },

        ------------------------------------------------------------------
        -- Western Plaguelands loop 5: Gahrron's Withering, Undercity, Bulwark (level 59)
        ------------------------------------------------------------------
        { complete = 5235, at = { 1422, 62.18, 59.06 },
          note = { ru = "Далеко на восток: пустошь Гаррона, хранитель котла Душегнев (58) — ключ.",
                   en = "Far east: Gahrron's Withering, Cauldron Lord Soulwrath (58) - the key." } },
        { id = "h-57-gahrron-s-withering", turnin = 5235, accept = 5236, object = 176392, at = { 1422, 62.54, 58.47 },
          note = { ru = "Котел: откройте ключом, возьмите возвращение.", en = "The cauldron: open it, take the return." } },
        { id = "h59-hearth-uc", hearth = "Undercity", at = { 1458, 67.74, 37.89 },
          note = { ru = "Камень возвращения в Подгород.", en = "Hearth to Undercity." } },
        { turnin = 5023, accept = 5049, npc = 10781, at = { 1458, 69.79, 43.16 },
          note = { ru = "Королевский инспектор Баухас: посылка; возьмите «Грусть Иеремии».",
                   en = "Royal Overseer Bauhaus: the parcel; take The Jeremiah Blues." } },
        { turnin = 5049, accept = 5050, npc = 8403, at = { 1458, 67.60, 44.16 },
          note = { ru = "Иеремия Пэйсон рядом: возьмите «Оберег удачи» (Джанис).",
                   en = "Jeremiah Payson next to him: take Good Luck Charm (for Janice)." } },
        { turnin = 5236, npc = 11055, at = { 1420, 83.04, 71.91 },
          note = { ru = "Из Подгорода в Бастион, Вандис: последний котел.",
                   en = "From Undercity to the Bulwark, Vandis: the last cauldron." } },
        { accept = 5238, npc = 10837, at = { 1420, 83.13, 68.94 },
          note = { ru = "Деррингтон: «Задание выполнено!».", en = "Derrington: Mission Accomplished!" } },
        { id = "h-59-wpl-end", turnin = 5238, npc = 10837, at = { 1420, 83.13, 68.94 },
          note = { ru = "Сдайте его ему же.", en = "Turn it in to him." } },
        { turnin = 5050, accept = 5051, npc = 10778, at = { 1422, 38.40, 54.05 },
          note = { ru = "Поле Джанис: Джанис — оберег; возьмите «Вторая половина».",
                   en = "Felstone Field: Janice - the charm; take Two Halves Become One." } },
        { complete = 5051, use = 12722, at = { 1422, 37.62, 56.35 },
          note = { ru = "Болтливый вурдалак (54) на поле — вторая половина; соедините половинки.",
                   en = "The Jabbering Ghoul (54) in the field - the other half; combine the halves." } },
        { turnin = 5051, npc = 10778, at = { 1422, 38.40, 54.05 },
          note = { ru = "Джанис: оберег.", en = "Janice: the charm." } },

        ------------------------------------------------------------------
        -- Eastern Plaguelands: Tirion, the south-west, Nathanos, Pamela (level 59)
        ------------------------------------------------------------------
        { id = "h-58-tirion-fordring", accept = { 5542, 5543, 5544 }, npc = 1855, at = { 1423, 5.16, 35.57 },
          note = { ru = "На северо-восток мимо пещеры Кристы и за реку: хижина Тириона Фордринга — «Псы-демоны», "
                       .. "«Окровавленные небеса», «Мясо личинок-трупоедов».",
                   en = "North-east past Kirsta's cave and across the river: Tirion Fordring's hut - Demon Dogs, Blood "
                       .. "Tinged Skies, Carrion Grubbage." } },
        { complete = { [5542] = { 1 } }, bg = true, at = { 1423, 16.27, 59.44 },
          note = { ru = "Попутно на юго-западе: 20 карликовых чумных псов (53-54).",
                   en = "On the way in the south-west: 20 Plaguehound Runts (53-54)." } },
        { complete = 5543, bg = true, at = { 1423, 21.56, 63.75 },
          note = { ru = "Попутно: 30 чумных нетопырей (53-55).", en = "On the way: 30 Plaguebats (53-55)." } },
        { complete = 5544, bg = true, at = { 1423, 24.53, 61.54 },
          note = { ru = "Попутно: 15 кусков мяса с личинок-падальщиков (54-55) и падальщиков-пожирателей.",
                   en = "On the way: 15 slabs of meat from Carrion Grubs (54-55) and Carrion Devourers." } },
        { id = "h-58-nathanos-blightcaller", turnin = 5961, accept = { 6022, 6042, 6133 }, npc = 11878,
          at = { 1423, 22.23, 63.51 },
          note = { ru = "На юг вдоль западного края, имение Марриса: Натанос Гнилостень — «Защитник королевы банши»; "
                       .. "возьмите «Преднамеренное убийство» (ступка), «Мелочи нежизни» и «Охота на следопытов».",
                   en = "South along the west edge, Marris Stead: Nathanos Blightcaller - The Champion of the Banshee "
                       .. "Queen; take To Kill With Purpose (the mortar), Un-Life's Little Annoyances and The Ranger "
                       .. "Lord's Behest." } },
        { id = "h-58-eastern-plaguelands-field", complete = 5543, at = { 1423, 21.56, 63.75 },
          note = { ru = "Юго-запад: добейте чумных нетопырей.", en = "South-west: finish the Plaguebats." } },
        { complete = 5544, at = { 1423, 24.53, 61.54 },
          note = { ru = "Там же: добейте мясо личинок.", en = "Same area: finish the grub meat." } },
        { complete = { [5542] = { 1 } }, at = { 1423, 16.27, 59.44 },
          note = { ru = "Добейте карликовых чумных псов.", en = "Finish the Plaguehound Runts." } },

        ------------------------------------------------------------------
        -- Eastern Plaguelands: centre and Light's Hope Chapel (level 59)
        ------------------------------------------------------------------
        { complete = { [6042] = { 1 } }, bg = true, at = { 1423, 44.65, 49.98 },
          note = { ru = "Попутно в центре: 20 пагубных нетопырей (54-56).",
                   en = "On the way in the centre: 20 Noxious Plaguebats (54-56)." } },
        { complete = 6022, use = 15454, at = { 1423, 52.57, 58.01 },
          note = { ru = "На восток, Перекресток Корина: нежить Плети (55-57) — 7 кусков живой гнили за 10 минут, затем "
                       .. "разотрите их ступкой.",
                   en = "East, Corin's Crossing: the Scourge (55-57) - 7 Living Rot within 10 minutes, then grind them "
                       .. "with the mortar." } },
        { complete = { [5542] = { 2 } }, at = { 1423, 46.19, 49.51 },
          note = { ru = "Северо-западнее: 5 чумных псов (55-56).", en = "North-west of it: 5 Plaguehounds (55-56)." } },
        { complete = { [6042] = { 1 } }, at = { 1423, 44.65, 49.98 },
          note = { ru = "Там же: добейте пагубных нетопырей.", en = "Same area: finish the Noxious Plaguebats." } },
        { id = "h-59-lightshope-arrive", fp = "Light's Hope Chapel", npc = 12636, at = { 1423, 70.53, 47.55 },
          note = { ru = "На восток к Часовне Последней Надежды: Георгия — точка полёта.",
                   en = "East to Light's Hope Chapel: Georgia - learn the flight point." } },
        { turnin = { 5241, 5210 }, accept = { 5211, 5181 }, npc = 11063, at = { 1423, 71.70, 50.04 },
          note = { ru = "Карлин Редпат: «Дядюшка Карлин» и «Брат Карлин»; возьмите «Защитники Дарроушира» и «Злодеи "
                       .. "Дарроушира».",
                   en = "Carlin Redpath: Uncle Carlin and Brother Carlin; take Defenders of Darrowshire and Villains of "
                       .. "Darrowshire." } },
        { turnin = 6030, npc = 11039, at = { 1423, 71.63, 50.09 },
          note = { ru = "Герцог Николас Зверенхофф: донесение.", en = "Duke Nicholas Zverenhoff: the report." } },
        -- Optional group content: Stratholme (58-60, main gate in the north-west next to Terrordale); turned in at the
        -- chapel before the last level gate.
        { accept = 5251, npc = 11039, optional = true, at = { 1423, 71.63, 50.09 },
          note = { ru = "По желанию, если собрали группу в Стратхольм: герцог — «Архивариус».",
                   en = "Optional, if you have a group for Stratholme: the Duke - The Archivist." } },
        { accept = 5212, npc = 11035, optional = true, at = { 1423, 71.66, 49.94 },
          note = { ru = "По желанию (Стратхольм): Бетина Бигглцинк — «Плоть не лжет».",
                   en = "Optional (Stratholme): Betina Bigglezink - The Flesh Does Not Lie." } },
        { accept = 5243, npc = 11036, optional = true, at = { 1423, 71.89, 48.29 },
          note = { ru = "По желанию (Стратхольм): Леонид Бартоломей Почтенный — «Дома Света».",
                   en = "Optional (Stratholme): Leonid Barthalomew the Revered - Houses of the Holy." } },
        { accept = 5214, npc = 11033, optional = true, at = { 1423, 70.88, 48.43 },
          note = { ru = "По желанию (Стратхольм): Смоки ЛаРю — «Великий Эзра Грим».",
                   en = "Optional (Stratholme): Smokey LaRue - The Great Ezra Grimm." } },
        { accept = { 6021, 5281 }, npc = 11038, at = { 1423, 69.93, 53.72 },
          note = { ru = "Управляющий Ален: «Зельдарр Изгой» (Крипта на юге) и «Мятущиеся души» (только поговорить с "
                       .. "Эганом на северо-западе; продолжение — Стратхольм).",
                   en = "Caretaker Alen: Zaeldarr the Outcast (the Undercroft in the south) and The Restless Souls (just "
                       .. "talk to Egan in the north-west; the follow-up is Stratholme)." } },

        ------------------------------------------------------------------
        -- Eastern Plaguelands: north field, Terrordale, Tirion, the Undercroft, Nathanos (level 59)
        ------------------------------------------------------------------
        { complete = 5211, bg = true, at = { 1423, 70.85, 37.95 },
          note = { ru = "Попутно: убивайте нежить Плети (свежеватели у часовни, вурдалаки на северо-западе) — на трупах "
                       .. "появляются духи Дарроушира, поговорите с 15.",
                   en = "On the way: kill the Scourge (flayers by the chapel, ghouls in the north-west) - Darrowshire "
                       .. "Spirits appear on the corpses, talk to 15." } },
        { complete = { [5542] = { 3 } }, bg = true, at = { 1423, 51.69, 28.28 },
          note = { ru = "Попутно на севере: 5 бесноватых чумных псов (57-58).",
                   en = "On the way in the north: 5 Frenzied Plaguehounds (57-58)." } },
        { complete = { [6042] = { 2 } }, at = { 1423, 49.12, 26.64 },
          note = { ru = "На северо-запад: 10 чудовищных чумных нетопырей (56-58); бесноватые псы и пожиратели рядом.",
                   en = "North-west: 10 Monstrous Plaguebats (56-58); Frenzied Plaguehounds and Devourers next to them." } },
        { complete = 6133, at = { 1423, 45.58, 12.80 },
          note = { ru = "На север, Сторожка Кель'Литиен: по 8 разведчиц дорог, следопытов и лесников (57-60), реестр "
                       .. "(45.3,12.7) в доме. Тяните по одному.",
                   en = "North, Quel'Lithien Lodge: 8 Pathstriders, Rangers and Woodsmen (57-60), the registry "
                       .. "(45.3,12.7) in the lodge. Pull one at a time." } },
        { complete = 5542, at = { 1423, 51.69, 28.28 },
          note = { ru = "Назад на юг: добейте бесноватых чумных псов.", en = "Back south: finish the Frenzied Plaguehounds." } },
        { complete = 5211, at = { 1423, 25.86, 23.04 },
          note = { ru = "На запад вдоль северной окраины: вурдалаки-каннибалы (56-57) — добейте духов.",
                   en = "West along the north: Cannibal Ghouls (56-57) - finish the spirits." } },
        { id = "h-58-augustus-the-touched", accept = 6164, npc = 12384, at = { 1423, 11.36, 26.37 },
          note = { ru = "Дальше на запад, Долина Ужаса: Август Помешанный — «Книга рецептов Августа».",
                   en = "Further west, Terrordale: Augustus the Touched - Augustus' Receipt Book." } },
        { complete = 6164, at = { 1423, 14.04, 24.22 },
          note = { ru = "Книга в хижине рядом (14.0,24.2).", en = "The book in the hut nearby (14.0,24.2)." } },
        { turnin = 6164, npc = 12384, at = { 1423, 11.36, 26.37 },
          note = { ru = "Август: книга.", en = "Augustus: the book." } },
        { turnin = 5281, npc = 11140, at = { 1423, 11.36, 26.60 },
          note = { ru = "Эган рядом: «Мятущиеся души». Продолжение (Стратхольм) — только в группе.",
                   en = "Egan next to him: The Restless Souls. The follow-up (Stratholme) - group only." } },
        { accept = 5282, npc = 11140, optional = true, at = { 1423, 11.36, 26.60 },
          note = { ru = "По желанию, если собрали группу: Эган — «Мятущиеся души» (вторая часть, бластер Эгана).",
                   en = "Optional, if you have a group: Egan - The Restless Souls (part 2, Egan's Blaster)." } },
        { complete = { 5251, 5212, 5243, 5214, 5282 }, optional = true, at = { 1423, 26.52, 10.36 },
          note = { ru = "По желанию: Стратхольм (главные ворота к северо-востоку, 26.5,10.4) — архивариус Гальфорд и "
                       .. "архив, 10 образцов чумной плоти, 5 ящиков со святой водой, табак Эзры Грима, 15 мятущихся "
                       .. "душ.",
                   en = "Optional: Stratholme (main gate to the north-east, 26.5,10.4) - Archivist Galford and the "
                       .. "archive, 10 Plagued Flesh Samples, 5 supply crates of holy water, Ezra Grimm's tobacco, 15 "
                       .. "restless souls." } },
        { turnin = 5282, npc = 11140, optional = true, at = { 1423, 11.36, 26.60 },
          note = { ru = "По желанию: Эган — души.", en = "Optional: Egan - the souls." } },
        { turnin = { 5542, 5543, 5544 }, accept = 5742, npc = 1855, at = { 1423, 5.16, 35.57 },
          note = { ru = "На юг к хижине Тириона: три задания; возьмите «Спасение».",
                   en = "South to Tirion's hut: the three quests; take Redemption." } },
        { complete = 5742, npc = 1855, at = { 1423, 5.16, 35.57 },
          note = { ru = "Выслушайте рассказ Тириона.", en = "Listen to Tirion's story." } },
        { turnin = 5742, accept = 5781, npc = 1855, at = { 1423, 5.16, 35.57 },
          note = { ru = "Тирион: возьмите «Символ ушедших дней» (молот в Крипте).",
                   en = "Tirion: take Of Forgotten Memories (the hammer in the Undercroft)." } },
        { turnin = { 6022, 6042, 6133 }, npc = 11878, at = { 1423, 22.23, 63.51 },
          note = { ru = "На юг к Натаносу: три задания. «Проклятый Тенекрыл» и «Огромный червь» (элита) не берите.",
                   en = "South to Nathanos: the three quests. Skip Duskwing and The Corpulent One (elites)." } },
        { complete = 5781, at = { 1423, 23.85, 74.22 },
          note = { ru = "Дальше на юг, Крипта: у могилы появится Меркуцио Грязежор (57) с помощниками — молот Таэлана.",
                   en = "Further south, the Undercroft: Mercutio Filthgorger (57) appears at the grave with helpers - "
                       .. "Taelan's Hammer." } },
        { complete = 6021, at = { 1423, 23.07, 72.63 },
          note = { ru = "Рядом: Зельдарр Изгой (55) — голова.", en = "Next to it: Zaeldarr the Outcast (55) - his head." } },
        { turnin = 5781, npc = 1855, at = { 1423, 5.16, 35.57 },
          note = { ru = "Назад к Тириону: молот. «Символ утраченной чести» (северо-восток и обратно) не берите.",
                   en = "Back to Tirion: the hammer. Skip Of Lost Honor (north-east and back)." } },
        { complete = { [5181] = { 1 } }, object = 176208, at = { 1423, 44.34, 41.18 },
          note = { ru = "На восток через центр: череп Хоргуса лежит у дороги (44.3,41.2).",
                   en = "East through the centre: Horgus' Skull lies by the road (44.3,41.2)." } },
        { complete = 5181, object = 176209, at = { 1423, 46.86, 55.43 },
          note = { ru = "Южнее (46.9,55.4): сломанный меч Мардука.", en = "South of it (46.9,55.4): the Shattered Sword of Marduk." } },
        { turnin = { 5211, 5181 }, npc = 11063, at = { 1423, 71.70, 50.04 },
          note = { ru = "Часовня Последней Надежды, Карлин: духи и злодеи Дарроушира.",
                   en = "Light's Hope Chapel, Carlin: the spirits and the villains of Darrowshire." } },
        { turnin = 5251, npc = 11039, optional = true, at = { 1423, 71.63, 50.09 },
          note = { ru = "По желанию (после Стратхольма): герцог — архив.", en = "Optional (after Stratholme): the Duke - the archive." } },
        { turnin = 5212, npc = 11035, optional = true, at = { 1423, 71.66, 49.94 },
          note = { ru = "По желанию: Бетина — образцы плоти.", en = "Optional: Betina - the flesh samples." } },
        { turnin = 5243, npc = 11036, optional = true, at = { 1423, 71.89, 48.29 },
          note = { ru = "По желанию: Леонид — святая вода.", en = "Optional: Leonid - the holy water." } },
        { turnin = 5214, npc = 11033, optional = true, at = { 1423, 70.88, 48.43 },
          note = { ru = "По желанию: Смоки — табак.", en = "Optional: Smokey - the tobacco." } },
        { id = "h-56-felwood-winterspring-plaguelands-level-gate", level = { 59, 0.98 },
          ok = { ["level-grind"] = 720 }, -- end gate of the route: 720 kills in the normal run
          at = { 1423, 70.85, 37.95 },
          note = { ru = "Сразу к северу от часовни: зараженные свежеватели (57-59, плотно, лучший лагерь рядом с "
                       .. "часовней). До 59-го + 98%: сдача Алену даёт 60-й. В группе — Стратхольм (выше).",
                   en = "Just north of the chapel: Diseased Flayers (57-59, dense - the best camp next to the chapel). Up "
                       .. "to 59 + 98%: the turn-in to Alen makes 60. In a group: Stratholme (above)." } },
        { id = "h-60-end", turnin = 6021, npc = 11038, at = { 1423, 69.93, 53.72 },
          note = { ru = "Ален: голова Зельдарра. 60-й уровень!", en = "Alen: Zaeldarr's head. Level 60!" } },
    },
})
