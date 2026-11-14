-- quest-race: 92598 "The Gift of Skysight" is Skyborne (Horde) only (race bit 2^33);
-- quest-side: 783 "A Threat Within" is an Alliance quest;
-- quest-class: 3095 "Simple Scroll" is the Undead WARRIOR scroll.
AdventureAtlas.AddSegment("fx-wrong-race", {
    id = "fx-wrong-race-01",
    title = "wrong race",
    levels = { 1, 3 },
    steps = {
        { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
        { turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { complete = 364 },
        { turnin = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { accept = 92598 },
        { accept = 783 },
        { accept = 3095, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { abandon = { 92598, 783, 3095 } },
    },
})
