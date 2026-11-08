-- Own segment placed between library segments by the UseSegments list (Route.lua).
FastesBoooy.AddSegment("test-composed", {
    id = "tc-class",
    title = { ru = "Паладин: тренер", en = "Paladin: trainer" },
    zone = "Tirisfal Glades",
    levels = { 4, 4 },
    steps = {
        { id = "tc-train-4", train = true, class = "PALADIN", npc = 244808, at = { 1420, 31.1, 66.4 },
          spells = { "Devotion Aura" } },
    },
})
