-- tests/fixtures/guides/FastesBoooy_StartZones / Segments / Tirisfal / 02_Tirisfal.lua
-- Fixture start zone for tests/spec/guides_layout_spec.lua: it stands in for the file of the same TOC path of
-- addons/FastesBoooy_Guides (loader option `replace`), so that Route.lua can be checked for all five races before
-- every start zone is written (docs/dev/PLAN.md A.4). A one-step segment and the
-- start-zone announcement of the zone (without `only`: every class of its races is registered).
if not FastesBoooy.AddLibraryInsert then return end
local _, ns = ...

FastesBoooy.AddLibrarySegment({
    id = "ud-02-tirisfal",
    title = { ru = "6-13 Tirisfal Glades (фикстура)", en = "6-13 Tirisfal Glades (fixture)" },
    zone = "Tirisfal Glades",
    levels = { 6, 13 },
    steps = {
        { id = "ud02-fixture", go = true, at = { 1420, 61.0, 52.0 }, note = { ru = "Фикстура.", en = "Fixture." } },
    },
})

ns.startZones = ns.startZones or {}
ns.startZones.Tirisfal = { "ud-01-deathknell", "ud-02-tirisfal" }
