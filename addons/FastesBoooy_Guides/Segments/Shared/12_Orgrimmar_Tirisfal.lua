-- FastesBoooy_Guides / Segments / Shared / 12_Orgrimmar_Tirisfal.lua
--
-- Segment "h-12-orgrimmar-tirisfal": levels 12-13, every race but the Undead (they do the same Tirisfal quests
-- inside their start zone and join at h-13-silverpine).
-- Orgrimmar (flight point, bind, the Forever-new city quests) -> main gate -> zeppelin to Tirisfal -> Brill
-- (96895, 445) -> Hadric Harlson and the cult camp (96897 + 96898) -> Undercity flight point -> through the
-- Sewers to the Silverpine road. Source: steps 10-34 of the former Skyborne segment sd-03-mulgore-silverpine.
-- Why everybody goes to Silverpine: docs/dev/PLAN.md B.1 (without it the route is ~18k XP short at 22).
--
-- Start state (hand-over contracts of the start zones, docs/dev/PLAN.md B.2): the Skyborne land at Doras by
-- flight; Orc and Troll come from Rhinag outside the gate (812 just accepted); the Tauren walk in through the gate.
-- Additions by other files (shared inserts):
--   Races/Skyborne.lua          before h12-org-end: Thrall 95350 -> 98024, optional 1061 (Zor Lonetree)
--   Segments/Durotar (Orc, Troll, phase P1)  after h12-borstan: Kor'ghan 813; after h12-wisdom: Nazgrel 831;
--                               before h12-zeppelin: Rhinag 812
--   class files                 training and class quests: h12-fp-org, h12-borstan, h12-wisdom, h12-org-end
--                               (Orgrimmar), h12-fp-uc (Undercity)
-- Anchors (never renamed): h12-fp-org, h12-sethearth-org, h12-borstan, h12-wisdom, h12-org-end, h12-zeppelin,
--   h12-brill, h12-fp-uc, h12-end.
-- City quests: 97246 -> 97249 and 97242 -> 97275 are fixed (XP estimated by the validator); 97326 (8 boulders,
--   few spawns, much competition) is optional: its three steps are skipped together.
-- Coordinates: Forever DB snapshot (tools/data/forever_db.lua): NPC / object spawns and centroids of the
-- objective mob / object spawns. The zeppelin towers and the Undercity sewer exit are terrain points.
-- Hearthstone: bound in Orgrimmar here; used from the Undercity at the end of h-13-silverpine.
--
-- Automation notes: transient steps (fp, sethearth) are followed by quest steps of other NPCs only.
if not FastesBoooy.AddLibraryInsert then return end
FastesBoooy.AddLibrarySegment({
    id = "h-12-orgrimmar-tirisfal",
    title = { ru = "12-13 Оргриммар, Тирисфальские леса", en = "12-13 Orgrimmar, Tirisfal Glades" },
    zone = "Orgrimmar",
    -- segment-level: the four races enter this segment between 11.2 (Orc, Troll) and 13.3 (Skyborne) and leave it
    -- between 12.3 and 14.2; no planned end level is within one level of all of them. The plan follows the three
    -- races that come from Durotar and Mulgore; the Skyborne (14.17 on the druid route) are acknowledged here.
    ok = "segment-level",
    levels = { 12, 13 },
    steps = {

        ------------------------------------------------------------------
        -- Orgrimmar (level 11-13)
        ------------------------------------------------------------------
        { id = "h12-fp-org", fp = "Orgrimmar", npc = 3310, at = { 1454, 45.12, 63.89 },
          note = { ru = "Дорас на башне в Долине Силы: откройте карту полётов (пришли пешком - точка изучится; прилетели - просто "
                       .. "кликните его).",
                   en = "Doras on the tower in the Valley of Strength: open the flight map (came on foot: this learns the point; flew "
                       .. "in: just click him)." } },
        { id = "h12-sethearth-org", sethearth = "Orgrimmar", npc = 6929, at = { 1454, 54.10, 68.41 },
          note = { ru = "Трактирщица Гришка: камень возвращения - Оргриммар (вернётесь сюда из Подгорода после Серебряного бора). "
                       .. "Починитесь у любого торговца.",
                   en = "Innkeeper Gryshka: bind your hearthstone to Orgrimmar (you hearth back here from the Undercity after "
                       .. "Silverpine). Repair at any vendor." } },
        { id = "h12-thatog", accept = 97246, npc = 268701, at = { 1454, 55.67, 72.15 },
          note = {
              ru = "Татог рядом, на втором этаже (лестница у 55.6, 73.7).",
              en = "Thatog close by, upstairs (the stairs at 55.6, 73.7).",
          } },
        { id = "h12-borstan", turnin = 97246, accept = 97249, npc = 3368, at = { 1454, 57.20, 53.32 },
          note = { ru = "Борстан, торговец мясом на Волоке.",
                   en = "Borstan, the meat vendor in the Drag." } },
        { id = "h12-korgeld", accept = 97242, npc = 3348, at = { 1454, 56.05, 34.12 },
          note = {
              ru = "Кор'гелд в лавке алхимика Йелмака на Волоке.",
              en = "Kor'geld in Yelmak's alchemy shop in the Drag.",
          } },
        { id = "h12-cattails", complete = 97242, object = { 661093, 661092 }, at = { 1454, 69.4, 30.7 },
          note = {
              ru = "Аллея Чести: 2 пучка рогоза и 4 побега острой травы у ручьёв.",
              en = "Valley of Honor: 2 Handfuls of Cattails and 4 Speargrass Cuttings along the streams.",
          } },
        { id = "h12-korgeld-2", turnin = 97242, npc = 3348, at = { 1454, 56.05, 34.12 } },
        { id = "h12-yelmak", accept = 97275, npc = 3347, at = { 1454, 56.84, 33.03 },
          note = {
              ru = "Йелмак рядом (задание появляется через ~10 с после сдачи).",
              en = "Yelmak next to him (the quest shows up ~10 s after the turn-in).",
          } },
        { id = "h12-whuut", turnin = 97275, npc = 11046, at = { 1454, 55.79, 32.90 },
          note = { ru = "Вхуут в той же лавке.",
                   en = "Whuut in the same shop." } },
        { id = "h12-wisdom", turnin = 97249, npc = 268682, at = { 1454, 36.53, 29.06 },
          note = { ru = "Аллея Мудрости: Миги за крепостью Громмаш.",
                   en = "The Valley of Wisdom: Migi behind Grommash Hold." } },
        { id = "h12-boulders-accept", accept = 97326, optional = true, npc = 268684, at = { 1454, 36.82, 29.06 },
          note = { ru = "По желанию: Тра рядом - 8 гладких валунов. Камней мало и много конкурентов: не хотите - «Вперёд» на этом и "
                       .. "двух следующих шагах.",
                   en = "Optional: Thra next to her - 8 Smooth Boulders. Few rocks and lots of competition: not interested - press "
                       .. "Forward on this and the next two steps." } },
        { id = "h12-boulders", complete = 97326, optional = true, object = { 661446, 661448, 661449 }, at = { 1454, 43.2, 33.6 },
          note = {
              ru = "8 гладких валунов (оранжевые камни на земле) к юго-востоку. Камней мало и много "
                  .. "конкурентов - бросьте задание (гайд сам пропустит этот и следующий шаг).",
              en = "8 Smooth Boulders (orange rocks on the ground) to the south-east. Few rocks and lots of "
                  .. "competition - abandon the quest (the guide skips this and the next step).",
          } },
        { id = "h12-boulders-turnin", turnin = 97326, optional = true, npc = 268684, at = { 1454, 36.82, 29.06 } },
        { id = "h12-org-end", go = true, radius = 25, at = { 1454, 38.93, 38.40 },
          note = { ru = "Выход из Аллеи Мудрости (здесь стоит Зор Одинокое Древо). Городские задания сделаны: тренеры классов в Оргриммаре "
                       .. "- сейчас, затем к главным воротам.",
                   en = "The way out of the Valley of Wisdom (Zor Lonetree stands here). The city quests are done: class trainers in "
                       .. "Orgrimmar now, then on to the main gate." } },

        ------------------------------------------------------------------
        -- Zeppelin to Tirisfal Glades: Brill, the cult camp, Undercity (level 12-13)
        ------------------------------------------------------------------
        { id = "h12-zeppelin", go = true, npc = 9564, at = { 1411, 50.80, 13.80 }, radius = 15,
          note = {
              ru = "Из Оргриммара через главные ворота (юг), затем на восток к башне дирижаблей: "
                  .. "площадка до Тирисфаля (Подгород), Фрезза.",
              en = "Leave Orgrimmar through the main gate (south), then east to the zeppelin tower: the platform "
                  .. "for Tirisfal (Undercity), Frezza.",
          } },
        { id = "h12-tirisfal", go = true, npc = 9566, at = { 1420, 60.74, 58.87 }, radius = 40,
          note = {
              ru = "Дирижабль до Тирисфальских лесов (на прибытии - Запетта).",
              en = "Ride the zeppelin to Tirisfal Glades (Zapetta at the arrival tower).",
          } },
        { id = "h12-brill", accept = 96895, npc = 1738, at = { 1420, 61.50, 53.50 },
          note = {
              ru = "На север в Брилл: стражник смерти Терренс.",
              en = "North to Brill: Deathguard Terrence.",
          } },
        { id = "h12-johaan", accept = 445, npc = 1518, at = { 1420, 59.45, 52.40 },
          note = {
              ru = "Аптекарь Йохан: посылка в Гробницу.",
              en = "Apothecary Johaan: a delivery to the Sepulcher.",
          } },
        { id = "h12-hadric", turnin = 96895, accept = { 96897, 96898 }, npc = 267009, at = { 1420, 65.93, 61.13 },
          note = {
              ru = "Хадрик Харлсон у входа в Подгород (к юго-востоку от Брилла).",
              en = "Hadric Harlson near the Undercity entrance (south-east of Brill).",
          } },
        { id = "h12-cult-camp", complete = { 96897, 96898 }, object = 656366, at = { 1420, 68.0, 63.6 },
          note = {
              ru = "Лагерь культа восточнее: по 8 тёмных неофитов и тёмных силовиков, 12 осколков "
                  .. "(с них и кристаллы на земле). Силовик бьёт мгновенно на 50-70.",
              en = "Cult camp to the east: 8 Dark Neophytes and 8 Dark Enforcers, 12 fragments (drops and "
                  .. "crystals on the ground). Enforcers have an instant 50-70 damage hit.",
          } },
        { id = "h12-hadric-2", turnin = { 96897, 96898 }, npc = 267009, at = { 1420, 65.93, 61.13 } },
        { id = "h12-fp-uc", fp = "Undercity", npc = 4551, at = { 1458, 63.25, 48.56 },
          note = {
              ru = "В Руины Лордерона (юго-западнее), на лифте вниз. Майкл Гаррет: точка полёта.",
              en = "Into the Ruins of Lordaeron (south-west), take a lift down. Michael Garrett: the flight point.",
          } },
        { id = "h12-sewers", go = true, at = { 1458, 21.89, 43.35 }, radius = 15,
          note = {
              ru = "Через город на запад к выходу через канализацию.",
              en = "West through the city to the Sewers exit.",
          } },
        { id = "h12-end", go = true, at = { 1420, 53.20, 75.82 }, radius = 30,
          note = {
              ru = "Из канализации на юг к дороге в Серебряный бор.",
              en = "Out of the Sewers, south to the road into Silverpine Forest.",
          } },
    },
})
