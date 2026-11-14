AdventureAtlas.AddSegment("fx-clean", {
    id = "fx-clean-01",
    title = { ru = "Мертвый Звон", en = "Deathknell" },
    zone = "Tirisfal Glades",
    levels = { 1, 4 },
    steps = {
        { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
        { turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { complete = 364, at = { 1420, 32.5, 63.5 } },
        { turnin = 364, accept = 3901, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { accept = 376, npc = 1661, at = { 1420, 30.9, 66.0 } },
        { train = true, npc = 244808, at = { 1420, 31.1, 66.4 }, spells = { "Seal of Righteousness" } },
        { complete = 3901, at = { 1420, 32.5, 61.0 } },
        { complete = 376, at = { 1420, 33.5, 64.0 } },
        { turnin = 3901, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { turnin = 376, accept = { 380, 3902 }, npc = { 1661, 1570, 1740 }, at = { 1420, 31.4, 65.9 },
          note = { ru = "Сдать и взять квесты у NPC рядом", en = "Turn in and pick up from the NPCs nearby" } },
    },
})
