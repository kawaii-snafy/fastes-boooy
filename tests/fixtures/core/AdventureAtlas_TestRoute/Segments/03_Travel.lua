AdventureAtlas.AddSegment("test-route", {
    id = "tr-03",
    title = { ru = "Перелёты", en = "Travel" },
    zone = "Undercity",
    steps = {
        { id = "tr-go-uc", go = true, at = { 1458, 63.0, 48.0 }, radius = 20 },
        { id = "tr-fp-uc", fp = "Undercity", npc = 4551, at = { 1458, 63.25, 48.56 } },
        -- WARN-OK: fly-unknown-fp (engine fixture: the taxi flow is tested, not flight point knowledge)
        { id = "tr-fly", fly = "The Sepulcher", at = { 1421, 45.6, 42.6 } },
        { id = "tr-hearth", hearth = "Brill", at = { 1420, 61.7, 52.0 } },
        { id = "tr-manual", manual = true,
          note = { ru = "Нажмите «Далее», когда будете готовы", en = "Press Next when ready" } },
    },
})
