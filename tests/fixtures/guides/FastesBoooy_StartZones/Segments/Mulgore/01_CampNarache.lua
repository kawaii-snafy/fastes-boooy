-- tests/fixtures/guides/FastesBoooy_StartZones / Segments / Mulgore / 01_CampNarache.lua
-- Fixture start zone for tests/spec/guides_layout_spec.lua: it stands in for the file of the same TOC path of
-- addons/FastesBoooy_Guides (loader option `replace`), so that Route.lua can be checked for all five races before
-- every start zone is written (docs/dev/PLAN.md A.4). A one-step segment.
if not FastesBoooy.AddLibraryInsert then return end

FastesBoooy.AddLibrarySegment({
    id = "mul-01-camp-narache",
    title = { ru = "1-6 Mulgore (фикстура)", en = "1-6 Mulgore (fixture)" },
    zone = "Mulgore",
    levels = { 1, 6 },
    steps = {
        { id = "mul01-fixture", go = true, at = { 1412, 44.9, 77.1 }, note = { ru = "Фикстура.", en = "Fixture." } },
    },
})
