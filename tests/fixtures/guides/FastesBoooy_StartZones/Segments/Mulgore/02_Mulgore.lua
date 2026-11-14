-- tests/fixtures/guides/FastesBoooy_StartZones / Segments / Mulgore / 02_Mulgore.lua
-- Fixture start zone for tests/spec/guides_layout_spec.lua: it stands in for the file of the same TOC path of
-- addons/FastesBoooy_Guides (loader option `replace`), so that Route.lua can be checked for all five races before
-- every start zone is written (docs/dev/PLAN.md A.4). A one-step segment.
if not FastesBoooy.AddLibraryInsert then return end

FastesBoooy.AddLibrarySegment({
    id = "mul-02-mulgore",
    title = { ru = "6-12 Mulgore (фикстура)", en = "6-12 Mulgore (fixture)" },
    zone = "Mulgore",
    levels = { 6, 12 },
    steps = {
        { id = "mul02-end", go = true, at = { 1456, 47.0, 49.83 }, note = { ru = "Фикстура.", en = "Fixture." } },
    },
})
