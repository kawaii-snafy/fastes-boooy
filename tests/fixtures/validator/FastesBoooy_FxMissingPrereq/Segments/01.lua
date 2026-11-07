-- accept-prereq: 3901 requires 364 turned in (preQuestSingle); 381 requires 380.
FastesBoooy.AddSegment("fx-missing-prereq", {
    id = "fx-missing-prereq-01",
    title = "missing prerequisite",
    levels = { 1, 3 },
    steps = {
        { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
        { turnin = 363, accept = { 364, 3901 }, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { complete = { 364, 3901 } },
        { turnin = { 364, 3901 }, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { accept = 381, npc = 1570, at = { 1420, 32.2, 66.0 } },
        { abandon = 381 },
    },
})
