-- FastesBoooy_SkyborneDruid / Segments / 03_Mulgore_Silverpine.lua
-- Segment "sd-03-mulgore-silverpine": levels 13-15.
-- Skywatcher Plateau (Mulgore) -> deathskip into Thunder Bluff (94911 -> 94913) -> fly to Orgrimmar
-- (hearth, five Forever-new city quests, Thrall 95350 -> 98024) -> zeppelin to Tirisfal (Brill: 96895
-- + 445; Argent Dawn camp 96897/96898) -> Undercity flight path -> Silverpine Forest 14-15 (Ivar Patch,
-- the Sepulcher: Arugal, Dead Fields, Wild Eyes, Border Crossings) -> fly to the Undercity (turn-ins,
-- 97891, 1359 -> 1358) -> Teleport: Moonglade (94913, training at 14) -> hearth to Orgrimmar.
-- Why this way and not straight into the Barrens: the Barrens/Stonetalon/Ashenvale quests are used by
-- the 14-22 segments; without Silverpine the route is ~18k XP short at 22. Silverpine gives ~12k known
-- quest XP + ~10 Forever-new quests + ~100 kills in one loop, and the way back costs nothing
-- (Teleport: Moonglade + hearthstone bound in Orgrimmar). Mulgore/Thunder Bluff have no worthwhile
-- quests at 12 on the path (Forever-new 99079 chain / 97485 / 76156 are far or shopping errands).
-- Coordinates: Forever DB snapshot (tools/data/forever_db.lua): NPC / object spawns and centroids of
-- the objective mob / object spawns. The cliff edge, the Thunder Bluff bridge, the zeppelin towers and
-- the Undercity sewer exit are terrain points cross-checked with the reference.
-- Skipped on purpose: 93739 (capital tour, Cairne/Sylvanas far off the path), 356/97558 (Tirisfal, low
-- XP per minute), 440 (ends in Brill), 443/479 (17+), 99 (Pyrewood elites), 98298/98299/95981
-- (Forever-new, 16-20, south Silverpine), 450 (back to Silverpine), 5726 (dungeon).
-- 1061 is taken (optional, needs level 13, like the reference) from Zor Lonetree on the way out of the
-- Valley of Wisdom and handed in at Seereth on the Stonetalon border at the end of sd-04.
FastesBoooy.AddSegment("horde-skyborne-druid", {
    id = "sd-03-mulgore-silverpine",
    title = {
        ru = "13-15 Громовой Утёс, Оргриммар, Серебряный бор",
        en = "13-15 Thunder Bluff, Orgrimmar, Silverpine Forest",
    },
    zone = "Silverpine Forest",
    -- the validator runs this segment from ~12.9 to ~15.3; what is left of the uncertainty is the unknown XP of
    -- the Forever-new quests (estimated by the validator), so the plan follows the estimate
    levels = { 13, 15 },
    steps = {
        ---------------------------------------------------------------------
        -- Skywatcher Plateau -> Thunder Bluff (12-13)
        ---------------------------------------------------------------------
        { id = "sd03-cliff", go = true, at = { 1412, 35.03, 24.33 }, radius = 20,
          note = {
              ru = "Срезка через смерть: к восточному краю плато и прыгайте вниз БЕЗ "
                  .. "«Шага по воздуху». Вы разобьётесь, дух появится у целителя в Громовом Утёсе.",
              en = "Deathskip: go to the east edge of the plateau and jump down WITHOUT Walk on Air. You die and "
                  .. "your spirit appears at the Spirit Healer in Thunder Bluff.",
          } },
        { id = "sd03-spirit", go = true, optional = true, npc = 6491, at = { 1456, 56.69, 19.11 }, radius = 20,
          note = {
              ru = "Отпустите дух и воскресните у Духа-целителя (слабость ~2-3 мин на 12-13 - пройдёт в "
                  .. "полёте). Не хотите умирать - спланируйте вниз и идите к подъёмникам (дольше).",
              en = "Release, then resurrect at the Spirit Healer (~2-3 min of sickness at 12-13 - it runs out during "
                  .. "the flight). Rather not die - glide down and walk to the lifts (slower).",
          } },
        { go = true, at = { 1456, 55.36, 35.55 }, radius = 15,
          note = {
              ru = "Вниз по тропе через 54,27 и 50,34 на центральную возвышенность, к "
                  .. "подвесному мосту на её северо-восточном краю.",
              en = "Down the path via 54,27 and 50,34 onto the central mesa, to the rope bridge at its north-east "
                  .. "edge.",
          } },
        { go = true, at = { 1456, 68.47, 28.24 }, radius = 15,
          note = {
              ru = "По мосту на восток, на Вершину Старейшин.",
              en = "Cross the bridge east to Elder Rise.",
          } },
        { id = "sd03-train-tb", train = true, optional = true, npc = 3033, at = { 1456, 76.48, 27.22 },
          spells = {
              { ru = "Телепортация: Лунная поляна (если нет)", en = "Teleport: Moonglade (if missing)" },
              { ru = "Восстановление, Исступление (если нет)", en = "Regrowth, Enrage (if missing)" },
          },
          note = {
              ru = "Turak Runetotem. Нет «Телепортации: Лунная поляна» (нужна в конце сегмента) - "
                  .. "заговорите с ним с зажатым Shift и сначала откройте обучение. Всё есть - пропустите.",
              en = "Turak Runetotem. No Teleport: Moonglade yet (needed at the end of the segment) - talk to him "
                  .. "holding Shift and open the training first. Everything known - skip.",
          } },
        { id = "sd03-child", turnin = 94911, accept = 94913, npc = 3033, at = { 1456, 76.48, 27.22 }, -- WARN-OK: xp-unknown
          note = {
              ru = "Классовое задание: сдайте и возьмите «Лунную поляну» (сдадите в конце сегмента). "
                  .. "Нет «Телепортации: Лунная поляна» - выучите у него же.",
              en = "Druid class quest: turn in and take Moonglade (handed in at the end of the segment). No "
                  .. "Teleport: Moonglade yet - learn it from him.",
          } },
        { go = true, at = { 1456, 55.36, 35.55 }, radius = 15,
          note = {
              ru = "Обратно по мосту на центральную возвышенность.",
              en = "Back over the bridge to the central mesa.",
          } },
        { id = "sd03-fp-tb", fp = "Thunder Bluff", npc = 2995, at = { 1456, 47.00, 49.83 },
          note = {
              ru = "Tal на башне ветрокрылов: откройте карту полётов (точка изучится).",
              en = "Tal on the wind rider tower: open the flight map (learns the point).",
          } },
        { id = "sd03-fly-org", fly = "Orgrimmar", npc = 3310, at = { 1454, 45.12, 63.89 },
          note = {
              ru = "Летите в Оргриммар. Его нет на карте полётов - бегите через Перекрёсток (долго).",
              en = "Fly to Orgrimmar. Not on the flight map - run there via the Crossroads (long).",
          } },
        ---------------------------------------------------------------------
        -- Orgrimmar (13)
        ---------------------------------------------------------------------
        { id = "sd03-sethearth", sethearth = "Orgrimmar", npc = 6929, at = { 1454, 54.10, 68.41 },
          note = {
              ru = "Трактирщица Gryshka: камень возвращения - Оргриммар (вернётесь сюда из Лунной поляны). "
                  .. "Починитесь у любого торговца.",
              en = "Innkeeper Gryshka: bind your hearthstone to Orgrimmar (you hearth back here from Moonglade). "
                  .. "Repair at any vendor.",
          } },
        { accept = 97246, npc = 268701, at = { 1454, 55.67, 72.15 },
          note = {
              ru = "Thatog рядом, на втором этаже (лестница у 55.6, 73.7).",
              en = "Thatog close by, upstairs (the stairs at 55.6, 73.7).",
          } },
        { turnin = 97246, accept = 97249, npc = 3368, at = { 1454, 57.20, 53.32 } }, -- WARN-OK: xp-unknown (Forever-new)
        { accept = 97242, npc = 3348, at = { 1454, 56.05, 34.12 },
          note = {
              ru = "Kor'geld в лавке алхимика Yelmak на Волоке.",
              en = "Kor'geld in Yelmak's alchemy shop in the Drag.",
          } },
        { complete = 97242, object = { 661093, 661092 }, at = { 1454, 69.4, 30.7 },
          note = {
              ru = "Аллея Чести: 2 пучка рогоза и 4 побега острой травы у ручьёв.",
              en = "Valley of Honor: 2 Handfuls of Cattails and 4 Speargrass Cuttings along the streams.",
          } },
        { turnin = 97242, npc = 3348, at = { 1454, 56.05, 34.12 } }, -- WARN-OK: xp-unknown (Forever-new)
        { accept = 97275, npc = 3347, at = { 1454, 56.84, 33.03 },
          note = {
              ru = "Yelmak рядом (задание появляется через ~10 с после сдачи).",
              en = "Yelmak next to him (the quest shows up ~10 s after the turn-in).",
          } },
        { turnin = 97275, npc = 11046, at = { 1454, 55.79, 32.90 } }, -- WARN-OK: xp-unknown (Forever-new)
        { turnin = 97249, npc = 268682, at = { 1454, 36.53, 29.06 }, -- WARN-OK: xp-unknown (Forever-new)
          note = {
              ru = "Migi за крепостью Громмаш.",
              en = "Migi behind Grommash Hold.",
          } },
        { accept = 97326, npc = 268684, at = { 1454, 36.82, 29.06 } },
        { complete = 97326, optional = true, object = { 661446, 661448, 661449 }, at = { 1454, 43.2, 33.6 },
          note = {
              ru = "8 гладких валунов (оранжевые камни на земле) к юго-востоку. Камней мало и много "
                  .. "конкурентов - бросьте задание (гайд сам пропустит этот и следующий шаг).",
              en = "8 Smooth Boulders (orange rocks on the ground) to the south-east. Few rocks and lots of "
                  .. "competition - abandon the quest (the guide skips this and the next step).",
          } },
        { turnin = 97326, optional = true, npc = 268684, at = { 1454, 36.82, 29.06 } }, -- WARN-OK: xp-unknown
        { turnin = 95350, accept = 98024, npc = 4949, at = { 1454, 31.73, 37.82 }, -- WARN-OK: xp-unknown; 98024 -> sd-04
          note = {
              ru = "Thrall в Аллее Мудрости. «Путь на Перекрёсток» - на следующий сегмент.",
              en = "Thrall in the Valley of Wisdom. Journey to the Crossroads is for the next segment.",
          } },
        { accept = 1061, optional = true, npc = 4047, at = { 1454, 38.93, 38.40 }, -- carried: 1061 -> sd-04 (Seereth)
          note = {
              ru = "Zor Lonetree по пути из Аллеи Мудрости к воротам: «Духи Когтистых гор» (сдадите у "
                  .. "Seereth на границе в конце Степей). Нужен 13-й уровень: ниже 13-го Zor задание не "
                  .. "предлагает - пропустите шаг.",
              en = "Zor Lonetree on the way out of the Valley of Wisdom: The Spirits of Stonetalon (handed in at "
                  .. "Seereth on the Stonetalon border at the end of the Barrens). Needs level 13: below 13 Zor "
                  .. "does not offer it - skip the step.",
          } },
        { id = "sd03-zeppelin", go = true, npc = 9564, at = { 1411, 50.80, 13.80 }, radius = 15,
          note = {
              ru = "Из Оргриммара через главные ворота (юг), затем на восток к башне дирижаблей: "
                  .. "площадка до Тирисфаля (Подгород), Frezza.",
              en = "Leave Orgrimmar through the main gate (south), then east to the zeppelin tower: the platform "
                  .. "for Tirisfal (Undercity), Frezza.",
          } },
        ---------------------------------------------------------------------
        -- Tirisfal Glades: Brill, the Argent Dawn camp, Undercity (13-14)
        ---------------------------------------------------------------------
        { go = true, npc = 9566, at = { 1420, 60.74, 58.87 }, radius = 40,
          note = {
              ru = "Дирижабль до Тирисфальских лесов (на прибытии - Zapetta).",
              en = "Ride the zeppelin to Tirisfal Glades (Zapetta at the arrival tower).",
          } },
        { accept = 96895, npc = 1738, at = { 1420, 61.50, 53.50 },
          note = {
              ru = "На север в Брилл: Deathguard Terrence.",
              en = "North to Brill: Deathguard Terrence.",
          } },
        { accept = 445, npc = 1518, at = { 1420, 59.45, 52.40 },
          note = {
              ru = "Apothecary Johaan: посылка в Гробницу.",
              en = "Apothecary Johaan: a delivery to the Sepulcher.",
          } },
        { turnin = 96895, accept = { 96897, 96898 }, npc = 267009, at = { 1420, 65.93, 61.13 }, -- WARN-OK: xp-unknown
          note = {
              ru = "Hadric Harlson у входа в Подгород (к юго-востоку от Брилла).",
              en = "Hadric Harlson near the Undercity entrance (south-east of Brill).",
          } },
        { complete = { 96897, 96898 }, object = 656366, at = { 1420, 68.0, 63.6 },
          note = {
              ru = "Лагерь культа восточнее: по 8 Dark Neophyte и Dark Enforcer, 12 осколков "
                  .. "(с них и кристаллы на земле). Enforcer бьёт мгновенно на 50-70.",
              en = "Cult camp to the east: 8 Dark Neophytes and 8 Dark Enforcers, 12 fragments (drops and "
                  .. "crystals on the ground). Enforcers have an instant 50-70 damage hit.",
          } },
        { turnin = { 96897, 96898 }, npc = 267009, at = { 1420, 65.93, 61.13 } }, -- WARN-OK: xp-unknown (Forever-new)
        { id = "sd03-fp-uc", fp = "Undercity", npc = 4551, at = { 1458, 63.25, 48.56 },
          note = {
              ru = "В Руины Лордерона (юго-западнее), на лифте вниз. Michael Garrett: точка полёта.",
              en = "Into the Ruins of Lordaeron (south-west), take a lift down. Michael Garrett: the flight point.",
          } },
        { go = true, at = { 1458, 21.89, 43.35 }, radius = 15,
          note = {
              ru = "Через город на запад к выходу через канализацию.",
              en = "West through the city to the Sewers exit.",
          } },
        { go = true, at = { 1420, 53.20, 75.82 }, radius = 30,
          note = {
              ru = "Из канализации на юг к дороге в Серебряный бор.",
              en = "Out of the Sewers, south to the road into Silverpine Forest.",
          } },
        ---------------------------------------------------------------------
        -- Silverpine Forest: Ivar Patch (13)
        ---------------------------------------------------------------------
        { accept = 435, npc = 1978, at = { 1421, 56.18, 9.18 },
          note = {
              ru = "Deathstalker Erland у дороги.",
              en = "Deathstalker Erland by the road.",
          } },
        { complete = 435, turnin = 435, accept = { 429, 449 }, npc = 1950, at = { 1421, 53.46, 13.43 },
          note = {
              ru = "Сопроводите Erland к Rane Yorick, отбивая воргов. Провал - возьмите заново у Erland.",
              en = "Escort Erland to Rane Yorick, killing the worgs on the way. Failed - take it again from Erland.",
          } },
        { complete = 429, collect = { [730] = 3 }, at = { 1421, 59.5, 13.5 },
          note = {
              ru = "Восточнее: 3 сердца с воргов (Mottled Worg) и 3 глаза мурлока с Vile Fin Shredder "
                  .. "на берегу (60-65, 12-17). Глаза оставьте - для задания позже.",
              en = "To the east: 3 hearts from worgs (Mottled Worgs) and 3 Murloc Eyes from Vile Fin Shredders on "
                  .. "the shore (60-65, 12-17). Keep the eyes - they are for a later quest.",
          } },
        ---------------------------------------------------------------------
        -- The Sepulcher (14)
        ---------------------------------------------------------------------
        { accept = 421, npc = 1938, at = { 1421, 44.20, 39.81 },
          note = {
              ru = "На юг по дороге в Гробницу: Dalar Dawnweaver.",
              en = "South along the road to the Sepulcher: Dalar Dawnweaver.",
          } },
        { accept = 477, npc = 2121, at = { 1421, 43.98, 40.93 } },
        { turnin = 449, accept = { 3221, 437 }, npc = 1952, at = { 1421, 43.42, 40.86 } },
        { turnin = { 429, 445, 3221 }, accept = { 1359, 447, 430 }, npc = 1937, at = { 1421, 42.80, 40.86 } },
        { complete = 447, bg = true,
          note = {
              ru = "Сердца с медведей (Grizzled Bear) по всему лесу; кровь - с Moss Stalker на северо-западе.",
              en = "Hearts from Grizzled Bears all over the forest; the blood from Moss Stalkers in the north-west.",
          } },
        { complete = 421, at = { 1421, 51.0, 40.5 },
          note = {
              ru = "Восточнее Гробницы: 5 Moonrage Whitescalp. Медведей по пути тоже бейте.",
              en = "East of the Sepulcher: 5 Moonrage Whitescalps. Kill the bears on the way too.",
          } },
        { turnin = 421, accept = 422, npc = 1938, at = { 1421, 44.20, 39.81 } },
        ---------------------------------------------------------------------
        -- North loop: spellbooks, Quinn, Dead Field, Moss Stalkers (14)
        ---------------------------------------------------------------------
        { complete = 422, object = 1571, at = { 1421, 52.83, 28.58 },
          note = {
              ru = "На северо-восток: Dusty Spellbooks в развалинах дома.",
              en = "North-east: the Dusty Spellbooks in the ruined house.",
          } },
        { turnin = 430, accept = 91920, complete = 91920, npc = 1951, at = { 1421, 53.43, 12.59 },
          note = {
              ru = "Quinn Yorick: сдайте зелье и возьмите «Дикие глаза» - глаза уже в сумке. "
                  .. "Нет 3 глаз - добейте мурлоков на берегу к востоку.",
              en = "Quinn Yorick: hand in the potion and take Wild Eyes - the eyes are in your bags already. Short "
                  .. "of 3 eyes - kill murlocs on the shore to the east.",
          } },
        { complete = 437, at = { 1421, 45.0, 21.8 },
          note = {
              ru = "Мёртвое поле: бейте Rot Hide Gladerunner/Mystic, пока не появится Nightlash; "
                  .. "убейте её ради Сущности.",
              en = "The Dead Field: kill Rot Hide Gladerunners / Mystics until Nightlash appears; kill her for the "
                  .. "Essence.",
          } },
        { complete = 447, at = { 1421, 35.5, 14.5 },
          note = {
              ru = "На запад: медведи (Giant Grizzled Bear) по пути и 6 крови с Moss Stalker "
                  .. "(севернее - Mist Creeper, тоже дают).",
              en = "West: the Giant Grizzled Bears on the way and 6 blood from Moss Stalkers (Mist Creepers just to "
                  .. "the north drop it too).",
          } },
        { turnin = 422, accept = 423, npc = 1938, at = { 1421, 44.20, 39.81 },
          note = {
              ru = "Назад в Гробницу.",
              en = "Back to the Sepulcher.",
          } },
        { turnin = 437, accept = 438, npc = 1952, at = { 1421, 43.42, 40.86 } },
        { turnin = 91920, accept = 91921, npc = 1937, at = { 1421, 42.80, 40.86 } }, -- WARN-OK: xp-unknown (Forever-new)
        ---------------------------------------------------------------------
        -- Shackles, Ivar the Foul, the ferry (14)
        ---------------------------------------------------------------------
        { complete = 423, at = { 1421, 41.5, 28.0 },
          note = {
              ru = "Севернее и северо-западнее Гробницы: оковы с Moonrage Glutton (6) и Darksoul (3).",
              en = "North and north-west of the Sepulcher: shackles from Moonrage Gluttons (6) and Darksouls (3).",
          } },
        { turnin = 423, accept = 424, npc = 1938, at = { 1421, 44.20, 39.81 },
          note = {
              ru = "Сразу назад к Dalar в Гробницу: тогда от парома можно идти прямо к Grimson.",
              en = "Straight back to Dalar at the Sepulcher: then you can go from the ferry straight to Grimson.",
          } },
        { turnin = 91921, npc = 1951, at = { 1421, 53.43, 12.59 }, -- WARN-OK: xp-unknown (Forever-new)
          note = {
              ru = "На северо-восток к Quinn Yorick.",
              en = "North-east to Quinn Yorick.",
          } },
        { accept = 425, npc = 1950, at = { 1421, 53.46, 13.43 } },
        { complete = 425, npc = 1971, at = { 1421, 51.52, 13.90 },
          note = {
              ru = "Ivar the Foul (13) в сарае рядом, с ним рабы Ravenclaw.",
              en = "Ivar the Foul (13) in the barn next to them, with Ravenclaw Slaves.",
          } },
        { turnin = 425, npc = 1950, at = { 1421, 53.46, 13.43 } },
        { turnin = 438, accept = 439, object = 1593, at = { 1421, 58.44, 34.90 },
          note = {
              ru = "На юг вдоль озера к старому парому: лодка с трупами (Corpse Laden Boat).",
              en = "South along the lake to the Decrepit Ferry: the Corpse Laden Boat.",
          } },
        ---------------------------------------------------------------------
        -- Grimson, Border Crossings, final turn-ins (15)
        ---------------------------------------------------------------------
        { complete = 424, npc = 1972, at = { 1421, 58.58, 44.86 },
          note = {
              ru = "От парома на юг: Grimson the Pale (15) среди Darksoul - голова.",
              en = "South from the ferry: Grimson the Pale (15) among the Darksouls - his head.",
          } },
        { turnin = 477, accept = 478, object = 1627, at = { 1421, 49.89, 60.33 },
          note = {
              ru = "На юго-запад к лагерю Dalaran Apprentice (13-14): ящик Даларана.",
              en = "South-west to the Dalaran Apprentice camp (13-14): the Dalaran Crate.",
          } },
        { turnin = 478, accept = 481, npc = 2121, at = { 1421, 43.98, 40.93 },
          note = {
              ru = "Назад в Гробницу (или умрите у лагеря - дух-целитель в Гробнице).",
              en = "Back to the Sepulcher (or die at the camp - the Spirit Healer is at the Sepulcher).",
          } },
        { turnin = { 424, 481 }, accept = 482, npc = 1938, at = { 1421, 44.20, 39.81 },
          note = {
              ru = "Следующее задание Dalar (Pyrewood, элиты) не берите.",
              en = "Do not take Dalar's next quest (Pyrewood elites).",
          } },
        { turnin = 482, npc = 2121, at = { 1421, 43.98, 40.93 } },
        { turnin = 439, npc = 1952, at = { 1421, 43.42, 40.86 },
          note = {
              ru = "Hadrec рядом. Следующие задания Hadrec не берите.",
              en = "Hadrec next door. Do not take Hadrec's follow-up quests.",
          } },
        { id = "sd03-fp-sepulcher", fp = "The Sepulcher", npc = 2226, at = { 1421, 45.62, 42.60 } },
        { id = "sd03-fly-uc", fly = "Undercity", npc = 4551, at = { 1458, 63.25, 48.56 },
          note = {
              ru = "Летите в Подгород.",
              en = "Fly to the Undercity.",
          } },
        ---------------------------------------------------------------------
        -- Undercity (15)
        ---------------------------------------------------------------------
        { accept = 97891, npc = 7683, at = { 1458, 58.61, 54.68 },
          note = {
              ru = "Alessandro Luca: зелье на время.",
              en = "Alessandro Luca: a timed potion delivery.",
          } },
        { turnin = 97891, npc = 11044, at = { 1458, 46.61, 74.09 }, -- WARN-OK: xp-unknown (Forever-new)
          note = {
              ru = "Без остановок к аптекарям на юго-западе города: Doctor Martin Felben.",
              en = "Straight to the Apothecarium (south-west): Doctor Martin Felben.",
          } },
        { turnin = 447, npc = 2055, at = { 1458, 48.82, 69.28 },
          note = {
              ru = "Следующее задание Faranell не берите.",
              en = "Do not take Faranell's next quest.",
          } },
        { turnin = 1359, accept = 1358, npc = 5204, at = { 1458, 50.14, 67.97 }, -- 1358 is turned in in sd-04
          note = {
              ru = "«Образец для Хельбрима» сдадите на Перекрёстке.",
              en = "Sample for Helbrim is handed in at the Crossroads.",
          } },
        ---------------------------------------------------------------------
        -- Moonglade, hearth to Orgrimmar (15)
        ---------------------------------------------------------------------
        { id = "sd03-moonglade", turnin = 94913, npc = 11802, at = { 1450, 56.21, 30.64 }, -- WARN-OK: xp-unknown
          note = {
              ru = "Из Подгорода - «Телепортация: Лунная поляна» (это и есть цель задания). "
                  .. "Dendrite Starblaze на севере Ночной Гавани.",
              en = "From the Undercity cast Teleport: Moonglade (that is the quest objective). Dendrite Starblaze "
                  .. "in the north of Nighthaven.",
          } },
        { id = "sd03-train-14", train = true, optional = true, npc = 12042, at = { 1450, 52.53, 40.57 },
          spells = {
              { ru = "Оглушить", en = "Bash" },
              { ru = "Гнев (ранг 3)", en = "Wrath (Rank 3)" },
              { ru = "Шипы (ранг 2)", en = "Thorns (Rank 2)" },
              { ru = "Целительное прикосновение (ранг 3)", en = "Healing Touch (Rank 3)" },
          },
          note = {
              ru = "Loganaar: обучение 14-го уровня (главное - «Оглушить»). Ещё не 14 - "
                  .. "пропустите шаг кнопкой.",
              en = "Loganaar: level 14 training (Bash matters most). Not 14 yet - skip the step with the button.",
          } },
        { id = "sd03-hearth", hearth = "Orgrimmar", at = { 1454, 54.10, 68.41 },
          note = {
              ru = "Камень возвращения в Оргриммар.",
              en = "Hearth to Orgrimmar.",
          } },
    },
})
