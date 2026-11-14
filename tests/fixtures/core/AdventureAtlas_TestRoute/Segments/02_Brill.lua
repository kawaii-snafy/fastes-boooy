AdventureAtlas.AddSegment("test-route", {
    id = "tr-02",
    title = { ru = "4-5 Брилл", en = "4-5 Brill" },
    zone = "Tirisfal Glades",
    levels = { 4, 5 },
    steps = {
        { id = "tr-go-brill", go = true, at = { 1420, 60.5, 52.5 },
          note = { ru = "Бегите в Брилл", en = "Run to Brill" } },
        -- sethearth through the innkeeper's 2nd gossip option ("Make this inn your home")
        { id = "tr-sethearth", sethearth = "Brill", npc = 5688, gossip = 2, at = { 1420, 61.7, 52.0 } },
        { id = "tr-vendor", vendor = true, npc = 5688, at = { 1420, 61.7, 52.0 } },
        { id = "tr-train-2", train = true, class = "PALADIN", npc = 246152, at = { 1420, 60.2, 52.7 } },
    },
})
