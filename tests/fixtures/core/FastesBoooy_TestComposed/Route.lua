-- Core test fixture: route "test-composed" (Horde / Scourge / PALADIN) = own segments
-- + library segments of FastesBoooy_TestLib (UseSegments) + class inserts (AddInsert).
-- Composed order (see tests/fixtures/core/helpers.lua H.COMPOSED_IDS):
--   tc-intro (own) -> tl-deathknell (library) -> tc-class (own, placed by UseSegments)
--   -> tl-brill (library); inserts after / before library and own steps.
FastesBoooy.RegisterRoute({
    api = 1,
    id = "test-composed",
    title = { ru = "Тестовый составной маршрут", en = "Composed test route" },
    faction = "Horde",
    races = { "Scourge" },
    classes = { "PALADIN" },
    levels = { 1, 5 },
    version = "0.0.1",
    author = "FastesBoooy tests",
    default = true,
})
-- Library segments after the route's own segments, in this order; "tc-class" names an own
-- segment of the route: it is placed here, between the two library segments.
FastesBoooy.UseSegments("test-composed", { "tl-deathknell", "tc-class", "tl-brill" })
