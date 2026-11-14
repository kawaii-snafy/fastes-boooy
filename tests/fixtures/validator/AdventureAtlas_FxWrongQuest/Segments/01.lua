-- quest-unknown: 999999 does not exist in Forever (accept, complete and turnin are all reported).
AdventureAtlas.AddSegment("fx-wrong-quest", {
    id = "fx-wrong-quest-01",
    title = "wrong quest id",
    levels = { 1, 2 },
    steps = {
        { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
        { accept = 999999 },
        { turnin = 363, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { complete = 999999 },
        { turnin = 999999 },
    },
})
