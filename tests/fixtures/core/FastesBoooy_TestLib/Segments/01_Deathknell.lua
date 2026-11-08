-- Core test fixture: library segment "tl-deathknell" (class-neutral Deathknell 1-4, real
-- Forever quests). Used by FastesBoooy_TestComposed through FastesBoooy.UseSegments.
FastesBoooy.AddLibrarySegment({
    id = "tl-deathknell",
    title = { ru = "1-4 Мертвый Звон", en = "1-4 Deathknell" },
    zone = "Tirisfal Glades",
    levels = { 1, 4 },
    steps = {
        { id = "tl-accept-363", accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
        { id = "tl-363-364", turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { id = "tl-complete-364", complete = 364, at = { 1420, 32.5, 63.5 } },
        { id = "tl-turnin-364", turnin = 364, accept = 3901, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { id = "tl-accept-376", accept = 376, npc = 1661, at = { 1420, 30.9, 66.0 } },
        -- background goal inside a library segment
        { id = "tl-bg-376", complete = 376, bg = true,
          note = { ru = "Собирайте лапы и крылья по пути", en = "Loot paws and wings on the way" } },
        { id = "tl-complete-3901", complete = 3901, at = { 1420, 32.5, 61.0 } },
        { id = "tl-turnin-3901", turnin = 3901, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { id = "tl-turnin-376", turnin = 376, accept = { 380, 3902 }, npc = { 1661, 1570, 1740 },
          at = { 1420, 31.4, 65.9 },
          note = { ru = "Сдать и взять квесты у NPC рядом", en = "Turn in and pick up from the NPCs nearby" } },
    },
})
