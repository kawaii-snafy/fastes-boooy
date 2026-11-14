AdventureAtlas.AddSegment("fx-clean", {
    id = "fx-clean-02",
    title = { ru = "Паутина и Брилл", en = "Night Web's Hollow and Brill" },
    zone = "Tirisfal Glades",
    levels = { 4, 5 },
    steps = {
        { complete = 3902, at = { 1420, 35.0, 60.0 } },
        { complete = 380, at = { 1420, 27.0, 59.0 } },
        { turnin = 3902, npc = 1740, at = { 1420, 31.6, 65.6 } },
        { turnin = 380, accept = 381, npc = 1570, at = { 1420, 32.2, 66.0 } },
        { complete = 381, at = { 1420, 36.0, 68.0 } },
        { turnin = 381, npc = 1570, at = { 1420, 32.2, 66.0 } },
        { level = { 5, 0.1 } },
        { go = true, at = { 1420, 60.5, 52.5 }, note = { ru = "Бегите в Брилл", en = "Run to Brill" } },
        { sethearth = "Brill", npc = 5688, at = { 1420, 61.7, 52.0 } },
        { vendor = true, npc = 5688, at = { 1420, 61.7, 52.0 } },
    },
})
