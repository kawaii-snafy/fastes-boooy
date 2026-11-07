-- level-too-low: 354 "Deaths in the Family" requires level 7 (simulated level ~2);
-- segment-level (WARN): the segment plans to end at level 6.
FastesBoooy.AddSegment("fx-level-low", {
    id = "fx-level-low-01",
    title = "level too low",
    levels = { 1, 6 },
    steps = {
        { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
        { turnin = 363, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { accept = 354 },
        { abandon = 354 },
    },
})
