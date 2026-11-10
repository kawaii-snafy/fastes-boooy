-- FastesBoooy_Guides / Races / Scourge.lua
-- The steps that exist because of the race (Undead, raceFile "Scourge") on the shared path, as shared inserts with
-- race scope; step ids "und-...".
--   Silverpine    6321 > 6323 > 6322 "Supplying the Sepulcher" (race-locked in the DB): Podrig and Karos Razok at
--                 the Sepulcher (before h13-fp-sepulcher: Karos is the flight master), Gordon Wendham and Michael
--                 Garrett in the Undercity (after h13-uc-arrive).
--   Orgrimmar     the four fixed city quests 97246 > 97249 and 97242 > 97275 (Forever-new, XP estimated; reqLevel
--                 5 / 9, quest level 15) after h15-org-fp: the other races do them at 12 in h-12-orgrimmar-tirisfal,
--                 the Undead walk to Doras at 14 anyway. The loop adds about 1,530 yd (3.6 min at 420 yd per
--                 minute, straight legs gate - Doras - Thatog - Borstan - Kor'geld - Valley of Honor - Kor'geld -
--                 Migi - gate against gate - Doras - gate) plus the dialogs for about 4,200 XP: 28 kills (14 min)
--                 at the level-22 gate otherwise (docs/dev/PLAN.md B.8). 97326 is optional as in h-12.
--   Until the Tirisfal segments end on the Silverpine road (phase F2c, docs/dev/PLAN.md B.2), the walk out of the
--   Undercity to that road (und-uc-exit, und-silverpine-road) stands here, before the first step of
--   h-13-silverpine. The F2c agent moves it into ud-02-tirisfal (ud02-silverpine-road) and deletes it here.
-- Not written yet: riding and the mount at 40 for the classes other than the paladin (Velma Warnam and Zachariah
--   Post in Brill, after h-41-uc-arrive): their routes do not exist before phase F2c removes `only`.
if not FastesBoooy.AddLibraryInsert then return end

------------------------------------------------------------------------------
-- Undercity -> the Silverpine road (interim: belongs to ud-02-tirisfal, see the header)
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h13-erland",
    race = "Scourge",
    steps = {
        { id = "und-uc-exit", go = true, at = { 1420, 61.92, 64.85 },
          note = { ru = "Выйдите из Подгорода на лифте к Руинам Лордерона.",
                   en = "Leave the Undercity by the lift up to the Ruins of Lordaeron." } },
        { id = "und-silverpine-road", go = true, at = { 1420, 53.2, 75.8 },
          note = { ru = "На юго-запад к дороге в Серебряный бор, восточнее лагеря Алого ордена.",
                   en = "South-west to the Silverpine Forest road, east of the Scarlet camp." } },
    },
})

------------------------------------------------------------------------------
-- The Sepulcher: 6321 > 6323 (Karos Razok is the flight master: quest steps before the fp step)
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h13-fp-sepulcher",
    race = "Scourge",
    steps = {
        { id = "und-6321-podrig", accept = 6321, npc = 6389, at = { 1421, 43.42, 41.68 },
          note = { ru = "Стражник смерти Подриг.", en = "Deathguard Podrig." } },
        { id = "und-6321-karos", turnin = 6321, accept = 6323, npc = 2226, at = { 1421, 45.62, 42.60 },
          note = { ru = "Карос Разок, распорядитель летучих мышей. 6323 сдаётся в Подгороде — лететь не нужно.",
                   en = "Karos Razok, the bat handler. 6323 is turned in at the Undercity: no need to fly now." } },
    },
})

------------------------------------------------------------------------------
-- Undercity: 6323 > 6322
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h13-uc-arrive",
    race = "Scourge",
    steps = {
        { id = "und-6323-wendham", turnin = 6323, accept = 6322, npc = 4556, at = { 1458, 61.49, 41.79 },
          note = { ru = "Гордон Вендхэм в Торговом квартале.", en = "Gordon Wendham in the Trade Quarter." } },
        { id = "und-6322-garrett", turnin = 6322, npc = 4551, at = { 1458, 63.25, 48.56 },
          note = { ru = "Майкл Гаррет. Задание обратно к Подригу не берите.",
                   en = "Michael Garrett. Do not take the one back to Podrig." } },
    },
})

------------------------------------------------------------------------------
-- Orgrimmar at 14: the city quests
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h15-org-fp",
    race = "Scourge",
    steps = {
        { id = "und-org-thatog", accept = 97246, npc = 268701, at = { 1454, 55.67, 72.15 },
          note = { ru = "Городские задания Оргриммара (четыре задания, ~4 мин бега по городу, опыт как за ~28 убийств): Татог у "
                       .. "таверны в Долине Силы, на втором этаже (лестница у 55.6, 73.7).",
                   en = "The Orgrimmar city quests (four quests, ~4 min of running through the city, the XP of ~28 kills): Thatog by "
                       .. "the inn in the Valley of Strength, upstairs (the stairs at 55.6, 73.7)." } },
        { id = "und-org-borstan", turnin = 97246, accept = 97249, npc = 3368, at = { 1454, 57.20, 53.32 },
          note = { ru = "Борстан, торговец мясом на Волоке.",
                   en = "Borstan, the meat vendor in the Drag." } },
        { id = "und-org-korgeld", accept = 97242, npc = 3348, at = { 1454, 56.05, 34.12 },
          note = {
              ru = "Кор'гелд в лавке алхимика Йелмака на Волоке.",
              en = "Kor'geld in Yelmak's alchemy shop in the Drag.",
          } },
        { id = "und-org-cattails", complete = 97242, object = { 661093, 661092 }, at = { 1454, 69.4, 30.7 },
          note = {
              ru = "Аллея Чести: 2 пучка рогоза и 4 побега острой травы у ручьёв.",
              en = "Valley of Honor: 2 Handfuls of Cattails and 4 Speargrass Cuttings along the streams.",
          } },
        { id = "und-org-korgeld-2", turnin = 97242, npc = 3348, at = { 1454, 56.05, 34.12 } },
        { id = "und-org-yelmak", accept = 97275, npc = 3347, at = { 1454, 56.84, 33.03 },
          note = {
              ru = "Йелмак рядом (задание появляется через ~10 с после сдачи).",
              en = "Yelmak next to him (the quest shows up ~10 s after the turn-in).",
          } },
        { id = "und-org-whuut", turnin = 97275, npc = 11046, at = { 1454, 55.79, 32.90 },
          note = { ru = "Вхуут в той же лавке.",
                   en = "Whuut in the same shop." } },
        { id = "und-org-migi", turnin = 97249, npc = 268682, at = { 1454, 36.53, 29.06 },
          note = { ru = "Аллея Мудрости: Миги за крепостью Громмаш.",
                   en = "The Valley of Wisdom: Migi behind Grommash Hold." } },
        { id = "und-org-boulders-accept", accept = 97326, optional = true, npc = 268684, at = { 1454, 36.82, 29.06 },
          note = { ru = "По желанию: Тра рядом - 8 гладких валунов. Камней мало и много конкурентов: не хотите - «Вперёд» на этом и "
                       .. "двух следующих шагах.",
                   en = "Optional: Thra next to her - 8 Smooth Boulders. Few rocks and lots of competition: not interested - press "
                       .. "Forward on this and the next two steps." } },
        { id = "und-org-boulders", complete = 97326, optional = true, object = { 661446, 661448, 661449 }, at = { 1454, 43.2, 33.6 },
          note = {
              ru = "8 гладких валунов (оранжевые камни на земле) к юго-востоку. Камней мало и много "
                  .. "конкурентов - бросьте задание (гайд сам пропустит этот и следующий шаг).",
              en = "8 Smooth Boulders (orange rocks on the ground) to the south-east. Few rocks and lots of "
                  .. "competition - abandon the quest (the guide skips this and the next step).",
          } },
        { id = "und-org-boulders-turnin", turnin = 97326, optional = true, npc = 268684, at = { 1454, 36.82, 29.06 } },
    },
})
