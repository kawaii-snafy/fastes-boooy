-- tests/fixtures/guides/AdventureAtlas_StartZones / Segments / Durotar / 01_ValleyOfTrials.lua
-- Fixture start zone for tests/spec/guides_layout_spec.lua: it stands in for the file of the same TOC path of
-- addons/AdventureAtlas_Guides (loader option `replace`), so that Route.lua can be checked for all five races before
-- every start zone is written (docs/dev/PLAN.md A.4). A one-step segment.
if not AdventureAtlas.AddLibraryInsert then return end

AdventureAtlas.AddLibrarySegment({
    id = "dur-01-valley-of-trials",
    title = { ru = "1-6 Durotar (фикстура)", en = "1-6 Durotar (fixture)" },
    zone = "Durotar",
    levels = { 1, 6 },
    steps = {
        { id = "dur01-fixture", go = true, at = { 1411, 43.3, 68.6 }, note = { ru = "Фикстура.", en = "Fixture." } },
    },
})
