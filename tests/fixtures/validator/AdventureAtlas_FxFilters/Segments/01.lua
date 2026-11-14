-- unknown-race-token (ERROR): "Undead" is not a UnitRace() raceFile (it is "Scourge"), so the
--   step would silently disappear for every character;
-- step-no-profile (WARN): a WARRIOR-only step in a paladin-only route is never shown
--   (step-skipped INFO for the paladin profile).
AdventureAtlas.AddSegment("fx-filters", {
    id = "fx-filters-01",
    title = "filters",
    levels = { 1, 2 },
    steps = {
        { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
        { train = true, race = "Undead", npc = 244808, at = { 1420, 31.1, 66.4 } },
        { train = true, class = "WARRIOR", npc = 2119, at = { 1420, 32.7, 65.6 } },
        { turnin = 363, npc = 1569, at = { 1420, 30.8, 66.2 } },
    },
})
