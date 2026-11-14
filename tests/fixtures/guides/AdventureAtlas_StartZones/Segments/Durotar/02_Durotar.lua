-- tests/fixtures/guides/AdventureAtlas_StartZones / Segments / Durotar / 02_Durotar.lua
-- Fixture start zone for tests/spec/guides_layout_spec.lua: it stands in for the file of the same TOC path of
-- addons/AdventureAtlas_Guides (loader option `replace`), so that Route.lua can be checked for all five races before
-- every start zone is written (docs/dev/PLAN.md A.4). A one-step segment and the
-- start-zone announcement of the zone (without `only`: every class of its races is registered).
if not AdventureAtlas.AddLibraryInsert then return end
local _, ns = ...

AdventureAtlas.AddLibrarySegment({
    id = "dur-02-durotar",
    title = { ru = "6-12 Durotar (фикстура)", en = "6-12 Durotar (fixture)" },
    zone = "Durotar",
    levels = { 6, 12 },
    steps = {
        { id = "dur02-end", go = true, at = { 1411, 41.54, 18.6 }, note = { ru = "Фикстура.", en = "Fixture." } },
    },
})

ns.startZones = ns.startZones or {}
ns.startZones.Durotar = { "dur-01-valley-of-trials", "dur-02-durotar" }
