-- tests/fixtures/guides/AdventureAtlas_StartZones / Segments / Mulgore / 03_BarrensCrossing.lua
-- Fixture start zone for tests/spec/guides_layout_spec.lua: it stands in for the file of the same TOC path of
-- addons/AdventureAtlas_Guides (loader option `replace`), so that Route.lua can be checked for all five races before
-- every start zone is written (docs/dev/PLAN.md A.4). A one-step segment and the
-- start-zone announcement of the zone (without `only`: every class of its races is registered).
if not AdventureAtlas.AddLibraryInsert then return end
local _, ns = ...

AdventureAtlas.AddLibrarySegment({
    id = "mul-03-barrens-crossing",
    title = { ru = "12 The Barrens (фикстура)", en = "12 The Barrens (fixture)" },
    zone = "The Barrens",
    levels = { 12, 12 },
    steps = {
        { id = "mul03-org-gate", go = true, at = { 1454, 48.97, 92.84 }, note = { ru = "Фикстура.", en = "Fixture." } },
    },
})

ns.startZones = ns.startZones or {}
ns.startZones.Mulgore = { "mul-01-camp-narache", "mul-02-mulgore", "mul-03-barrens-crossing" }
