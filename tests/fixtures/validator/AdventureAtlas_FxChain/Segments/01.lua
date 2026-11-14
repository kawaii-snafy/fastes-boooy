-- accept-exclusive: 8792 and 8793 "The Horde Needs Your Help!" exclude each other;
-- breadcrumb-late (WARN): 363 is a breadcrumb for 364, accepted after 364;
-- accept-duplicate, turnin-not-accepted, turnin-twice, complete-not-active, abandon-not-active;
-- turnin-no-complete (WARN): 364 has kill objectives but no complete step;
-- quest-carried (WARN): 8792 is never turned in.
AdventureAtlas.AddSegment("fx-chain", {
    id = "fx-chain-01",
    title = "bookkeeping",
    levels = { 1, 2 },
    steps = {
        { accept = 8792 },
        { accept = 8793 },
        { abandon = 8793 },
        { accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
        { accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { turnin = 363, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { turnin = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { turnin = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { turnin = 3901, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { complete = 376 },
        { abandon = 376 },
    },
})
