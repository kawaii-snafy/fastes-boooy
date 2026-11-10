-- tests/fixtures/guides/FastesBoooy_StartZones / Segments / Zephras / 03_ThunderBluff.lua
-- Fixture start zone for tests/spec/guides_layout_spec.lua: it stands in for the file of the same TOC path of
-- addons/FastesBoooy_Guides (loader option `replace`), so that Route.lua can be checked for all five races before
-- every start zone is written (docs/dev/PLAN.md A.4). A one-step segment and the
-- start-zone announcement of the zone (without `only`: every class of its races is registered).
if not FastesBoooy.AddLibraryInsert then return end
local _, ns = ...

FastesBoooy.AddLibrarySegment({
    id = "sd-03-thunder-bluff",
    title = { ru = "13 Thunder Bluff (фикстура)", en = "13 Thunder Bluff (fixture)" },
    zone = "Thunder Bluff",
    levels = { 13, 13 },
    steps = {
        { id = "sd03-fixture", go = true, at = { 1456, 47.0, 49.83 }, note = { ru = "Фикстура.", en = "Fixture." } },
    },
})

ns.startZones = ns.startZones or {}
ns.startZones.Zephras = { "sd-01-zephras", "sd-02-zephras", "sd-03-thunder-bluff" }
