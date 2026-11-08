-- Core test fixture: library segments "tl-brill" (used) and "tl-unused" (registered,
-- never used: a library may hold segments no route picks).
FastesBoooy.AddLibrarySegment({
    id = "tl-brill",
    title = { ru = "4-5 Паутина и Брилл", en = "4-5 Night Web's Hollow and Brill" },
    zone = "Tirisfal Glades",
    levels = { 4, 5 },
    steps = {
        { id = "tl-complete-3902", complete = 3902, at = { 1420, 35.0, 60.0 } },
        { id = "tl-complete-380", complete = 380, at = { 1420, 27.0, 59.0 } },
        { id = "tl-turnin-3902", turnin = 3902, npc = 1740, at = { 1420, 31.6, 65.6 } },
        { id = "tl-turnin-380", turnin = 380, accept = 381, npc = 1570, at = { 1420, 32.2, 66.0 } },
        { id = "tl-complete-381", complete = 381, at = { 1420, 36.0, 68.0 } },
        { id = "tl-turnin-381", turnin = 381, npc = 1570, at = { 1420, 32.2, 66.0 } },
        -- optional step inside a library segment
        { id = "tl-optional", optional = true, level = { 5, 0.1 },
          note = { ru = "По желанию: добейте 10% уровня", en = "Optional: grind 10% of a level" } },
        { id = "tl-go-brill", go = true, at = { 1420, 60.5, 52.5 },
          note = { ru = "Бегите в Брилл", en = "Run to Brill" } },
        { id = "tl-sethearth", sethearth = "Brill", npc = 5688, at = { 1420, 61.7, 52.0 } },
    },
})
FastesBoooy.AddLibrarySegment({
    id = "tl-unused",
    title = { ru = "Не используется", en = "Unused" },
    zone = "Tirisfal Glades",
    levels = { 5, 6 },
    steps = {
        { id = "tl-unused-go", go = true, at = { 1420, 61.0, 52.0 } },
    },
})
