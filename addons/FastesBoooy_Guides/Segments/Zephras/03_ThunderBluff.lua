-- FastesBoooy_Guides / Segments / Zephras / 03_ThunderBluff.lua
-- Segment "sd-03-thunder-bluff" (level 13, Skyborne): Skywatcher Plateau (Mulgore) -> deathskip into Thunder
-- Bluff -> flight point -> flight to Orgrimmar. It is the bridge of the Skyborne from their start zone to the
-- shared path: the next segment is h-12-orgrimmar-tirisfal, whose first step stands at Doras in Orgrimmar.
-- Class-neutral: the druid's detour to Elder Rise (training, 94911 -> 94913) is a class insert after sd03-spirit
-- (Classes/Druid.lua).
-- Hand-over (docs/dev/PLAN.md B.2): in Orgrimmar at Doras, level 13+, 95350 in the log, flight point Thunder Bluff.
-- Coordinates: Forever DB snapshot (tools/data/forever_db.lua); the cliff edge is a terrain point cross-checked
-- with the reference.
-- Open game fact (docs/dev/PLAN.md E.2): the flight Thunder Bluff -> Orgrimmar at 13 assumes that the Skyborne know
-- the Orgrimmar flight point from the start. If they do not, the fall-back is the walk through the Barrens.
--
-- This is the last segment file of the zone, so it holds the start-zone announcement (read by Route.lua): the
-- segments every Skyborne route starts with. `only`: while the Zephras segments still hold the druid's class
-- steps, only the druid route of the zone's race is registered.
if not FastesBoooy.AddLibraryInsert then return end
local _, ns = ...

FastesBoooy.AddLibrarySegment({
    id = "sd-03-thunder-bluff",
    title = { ru = "13 Громовой Утёс, перелёт в Оргриммар", en = "13 Thunder Bluff, the flight to Orgrimmar" },
    zone = "Thunder Bluff",
    levels = { 13, 13 },
    steps = {
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
        { id = "sd03-fp-tb", fp = "Thunder Bluff", npc = 2995, at = { 1456, 47.00, 49.83 },
          note = { ru = "От целителя душ вниз по тропе через 54,27 и 50,34 на центральную возвышенность: Tal на башне ветрокрылов - "
                       .. "откройте карту полётов (точка изучится).",
                   en = "From the Spirit Healer down the path via 54,27 and 50,34 onto the central mesa: Tal on the wind rider tower "
                       .. "- open the flight map (learns the point)." } },
        -- CONFIRM (docs/dev/PLAN.md E.2): the RestedXP Skyborne guide flies Thunder Bluff -> Orgrimmar right here
        -- (Skyborne start flight points are not in the DB). The first step of h-12-orgrimmar-tirisfal learns
        -- Orgrimmar either way.
        { id = "sd03-fly-org", fly = "Orgrimmar", npc = 3310, at = { 1454, 45.12, 63.89 },
          ok = "fly-unknown-fp", -- see above: the Skyborne start flight points are not in the DB
          note = {
              ru = "Летите в Оргриммар. Его нет на карте полётов - бегите через Перекрёсток (долго).",
              en = "Fly to Orgrimmar. Not on the flight map - run there via the Crossroads (long).",
          } },
    },
})

ns.startZones = ns.startZones or {}
ns.startZones.Zephras = { "sd-01-zephras", "sd-02-zephras", "sd-03-thunder-bluff", only = { "DRUID" } }
