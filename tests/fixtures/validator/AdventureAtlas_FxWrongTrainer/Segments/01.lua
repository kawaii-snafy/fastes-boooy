-- train-wrong-trainer: Dannal Stern 2119 is a Warrior Trainer; Shadow Priest Sarvis 1569 is no trainer;
-- npc-hostile: Brother Sammuel 925 (Northshire) is an Alliance Paladin Trainer;
-- train-not-class-trainer (WARN): Florence Nightshade 267326 is a herbalism trainer;
-- not-flightmaster / not-innkeeper (ERROR), not-vendor (WARN): Sarvis 1569.
AdventureAtlas.AddSegment("fx-wrong-trainer", {
    id = "fx-wrong-trainer-01",
    title = "wrong trainer",
    levels = { 1, 2 },
    steps = {
        { train = true, npc = 244808, at = { 1420, 31.1, 66.4 } },
        { train = true, npc = 2119, at = { 1420, 32.7, 65.6 } },
        { train = true, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { train = true, npc = 925, at = { 1429, 50.4, 42.1 } },
        { train = true, npc = 267326, at = { 1420, 32.5, 65.1 } },
        { fp = "Deathknell", npc = 1569, at = { 1420, 30.8, 66.2 } },
        { sethearth = "Deathknell", npc = 1569, at = { 1420, 30.8, 66.2 } },
        { vendor = true, npc = 1569, at = { 1420, 30.8, 66.2 } },
    },
})
