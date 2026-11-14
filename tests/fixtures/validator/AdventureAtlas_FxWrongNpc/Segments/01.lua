-- turnin-wrong-npc: 363 is turned in to Shadow Priest Sarvis 1569, not Undertaker Mordo 1568;
-- accept-wrong-npc: 364 is offered by Sarvis 1569, not Mordo 1568.
AdventureAtlas.AddSegment("fx-wrong-npc", {
    id = "fx-wrong-npc-01",
    title = "wrong NPC",
    levels = { 1, 2 },
    steps = {
        { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
        { turnin = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
        { accept = 364, npc = 1568, at = { 1420, 30.2, 71.7 } },
        { abandon = 364 },
    },
})
