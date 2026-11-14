-- AdventureAtlas_Guides / Segments / Mulgore / 03_BarrensCrossing.lua
-- Segment "mul-03-barrens-crossing" (level 12, Tauren): Bloodhoof Village -> the road east out of Mulgore ->
-- Camp Taurajo (flight point, 854) -> the Crossroads (flight point; 854 in; the flight chain 6361 > 6364: a flight
-- to Thunder Bluff and back, with the turn-ins of 776, 98435 and 861 > 860 there) -> 860, 886 in -> Far Watch
-- Post -> over the Southfury bridge into Durotar -> the main gate of Orgrimmar. It is the bridge of the Tauren from their start
-- zone to the shared path: the next segment is h-12-orgrimmar-tirisfal, which starts at Doras inside the gate.
-- Why on foot (docs/dev/PLAN.md B.1, E.1): Thunder Bluff has no zeppelin and a Tauren does not know the Orgrimmar
-- flight point at 12. 840 (Razor Hill) is not taken on the way north: its turn-in at Far Watch Post lies behind;
-- the shared path takes it at 14. The walk does not go through Razor Hill: from the bridge the way to the gate
-- is shorter along the river, past Thunder Ridge (no quest of Razor Hill is open to a Tauren at 12 on this path).
-- Class-neutral: class steps are shared inserts of the class files on the anchors below.
--
-- Hand-over (docs/dev/PLAN.md B.2): at the Orgrimmar gate, level 11.8 or more (base profile), flight points
-- Thunder Bluff, Camp Taurajo, The Crossroads; 854 / 860 / 886 turned in at the Crossroads (861 before them in
-- Thunder Bluff); hearthstone bound in Bloodhoof Village (used once in mul-02, at Red Rocks).
-- Why the flight chain is not optional: it carries the turn-ins of 776, 98435 and 861 in Thunder Bluff and the
-- Crossroads flight point is merged into its Devrak step (look-ahead rule); about 3,600 XP for two flights and
-- three short walks in the city, well under the cost of the same XP as kills (docs/dev/PLAN.md B.8).
-- Anchors (docs/dev/PLAN.md C.2): mul03-taurajo (the Camp Taurajo flight point: druid 6002), mul03-cairne (the
-- second Thunder Bluff visit: trainers at 12), mul03-xroads (the last Crossroads turn-ins), mul03-far-watch
-- (passing Far Watch Post: warrior 1498 at Uzzek, shaman Kranal Fiss 640 yd west), mul03-org-gate (the last
-- step). Every step has an explicit id (prefix "mul03-").
-- Coordinates: Forever DB snapshot (tools/data/forever_db.lua); the Mulgore road exit and the Orgrimmar gate are
-- the terrain points the shared path uses.
--
-- This is the last segment file of the zone, so it holds the start-zone announcement (read by Route.lua): the
-- segments every Tauren route starts with. The zone is class-neutral, so the announcement carries no `only`: all
-- four Tauren routes are registered.
if not AdventureAtlas.AddLibraryInsert then return end
local _, ns = ...

AdventureAtlas.AddLibrarySegment({
    id = "mul-03-barrens-crossing",
    title = {
        ru = "12 Через Степи в Оргриммар",
        en = "12 Through the Barrens to Orgrimmar",
    },
    zone = "The Barrens",
    levels = { 12, 12 },
    steps = {
        { id = "mul03-exit", go = true, radius = 30, at = { 1412, 64.34, 63.53 },
          note = {
              ru = "Из деревни на восток по дороге из Мулгора в Степи.",
              en = "East from the village along the road out of Mulgore into the Barrens.",
          } },
        -- Anchor: druid 6002 (Lunaclaw) starts here.
        { id = "mul03-taurajo", fp = "Camp Taurajo", npc = 10378, at = { 1413, 44.45, 59.15 },
          note = {
              ru = "Лагерь Таурахо: Омуса Громовой Рог - откройте карту полётов (точка изучится).",
              en = "Camp Taurajo: Omusa Thunderhorn - open the flight map (learns the point).",
          } },
        { id = "mul03-kirge", accept = 854, npc = 3418, at = { 1413, 44.90, 58.60 },
          note = {
              ru = "Kirge Sternhorn в лагере: путешествие в Перекрёсток.",
              en = "Kirge Sternhorn in the camp: the journey to the Crossroads.",
          } },
        { id = "mul03-thork", turnin = 854, npc = 3429, at = { 1413, 51.50, 30.87 },
          note = {
              ru = "По дороге на север в Перекрёсток (около 2000 ярдов): Торк у западного дома.",
              en = "North along the road to the Crossroads (about 2000 yd): Thork at the west building.",
          } },
        -- The flight chain of the Tauren (6361 > 6362 > 6363 > 6364): about 1,900 XP for two flights, and the visit
        -- in Thunder Bluff also takes the turn-ins of 776, 98435 and 861 (docs/dev/PLAN.md B.2, B.8 cost rule).
        { id = "mul03-jahan", accept = 6361, npc = 3483, at = { 1413, 51.20, 29.10 },
          note = {
              ru = "Jahan Hawkwing у северного дома: тюк шкур для Деврака.",
              en = "Jahan Hawkwing at the north building: a bundle of hides for Devrak.",
          } },
        { id = "mul03-fp-xroads", fp = "The Crossroads", turnin = 6361, accept = 6362, npc = 3615,
          at = { 1413, 51.50, 30.34 },
          note = {
              ru = "Деврак на башне: откройте карту полётов (точка изучится), сдайте тюк и возьмите следующее.",
              en = "Devrak on the tower: open the flight map (learns the point), hand in the bundle, take the next "
                  .. "quest.",
          } },
        { id = "mul03-fly-tb", fly = "Thunder Bluff", npc = 2995, at = { 1456, 47.00, 49.83 },
          note = {
              ru = "Летите в Громовой Утёс.",
              en = "Fly to Thunder Bluff.",
          } },
        { id = "mul03-ahanu", turnin = 6362, accept = 6363, npc = 8359, at = { 1456, 45.80, 55.80 },
          note = {
              ru = "Ahanu в палатке к югу от башни ветрокрылов.",
              en = "Ahanu in the tent south of the wind rider tower.",
          } },
        -- Anchor: Thunder Bluff trainers at level 12.
        { id = "mul03-cairne", turnin = 776, npc = 3057, at = { 1456, 60.30, 51.70 },
          note = {
              ru = "Cairne Bloodhoof: рог Arra'chea.",
              en = "Cairne Bloodhoof: the horn of Arra'chea.",
          } },
        { id = "mul03-melor", turnin = 861, accept = 860, npc = 3441, at = { 1456, 61.50, 80.90 },
          note = {
              ru = "На юг по мосту на Вершину Охотников: Melor Stonehoof.",
              en = "South over the bridge to Hunter Rise: Melor Stonehoof.",
          } },
        { id = "mul03-hamuul", turnin = 98435, accept = 886, npc = 5769, at = { 1456, 78.60, 28.60 },
          note = {
              ru = "Через центральную вершину на Вершину Старейшин: Arch Druid Hamuul Runetotem.",
              en = "Across the central mesa to Elder Rise: Arch Druid Hamuul Runetotem.",
          } },
        { id = "mul03-tal", turnin = 6363, accept = 6364, npc = 2995, at = { 1456, 47.00, 49.83 },
          note = {
              ru = "Обратно к Tal у башни ветрокрылов.",
              en = "Back to Tal at the wind rider tower.",
          } },
        { id = "mul03-fly-xroads", fly = "The Crossroads", npc = 3615, at = { 1413, 51.50, 30.34 },
          note = {
              ru = "Летите обратно в Перекрёсток.",
              en = "Fly back to the Crossroads.",
          } },
        { id = "mul03-jahan-2", turnin = 6364, npc = 3483, at = { 1413, 51.20, 29.10 } },
        -- Anchor: the Crossroads turn-ins.
        { id = "mul03-xroads", turnin = { 860, 886 }, npc = { 3338, 3448 }, at = { 1413, 52.25, 31.45 },
          note = {
              ru = "Южный край Перекрёстка: Сергра Тёмный Шип и Тонга Тотем Руны. Их новые задания не берите: путь "
                  .. "вернётся сюда на 14-м уровне.",
              en = "The south edge of the Crossroads: Sergra Darkthorn and Tonga Runetotem. Do not take their new "
                  .. "quests: the path comes back here at level 14.",
          } },
        -- Anchor: passing Far Watch Post (warrior: Uzzek; shaman: Kranal Fiss 640 yd to the west).
        { id = "mul03-far-watch", go = true, radius = 30, at = { 1413, 62.26, 19.38 },
          note = {
              ru = "По дороге на северо-восток к Дальнему Дозору. Лагеря Иглогривых у дороги - не задерживайтесь.",
              en = "North-east along the road to Far Watch Post. Razormane camps line the road: do not stop.",
          } },
        -- CONFIRM: the way from the Southfury bridge north along the river past Thunder Ridge (terrain).
        { id = "mul03-org-gate", go = true, radius = 20, at = { 1454, 48.97, 92.84 },
          note = {
              ru = "По мосту над рекой Строптивой в Дуротар и вдоль реки на север, мимо Громового Хребта, к главным "
                  .. "воротам Оргриммара.",
              en = "Over the Southfury bridge into Durotar and north along the river, past Thunder Ridge, to the "
                  .. "main gate of Orgrimmar.",
          } },
    },
})

ns.startZones = ns.startZones or {}
ns.startZones.Mulgore = { "mul-01-camp-narache", "mul-02-mulgore", "mul-03-barrens-crossing" }
