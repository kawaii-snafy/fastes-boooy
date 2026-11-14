-- Class inserts: route-specific steps next to library and own steps (they belong to the
-- anchor's segment). Registered after UseSegments here, but the order does not matter:
-- the route is composed when it is first read.

-- after a library step; two inserts at the same anchor keep their call order
AdventureAtlas.AddInsert("test-composed", {
    after = "tl-363-364",
    steps = {
        { id = "tc-train-1", train = true, class = "PALADIN", npc = 244808, at = { 1420, 31.1, 66.4 },
          spells = { "Seal of Righteousness" } },
    },
})
AdventureAtlas.AddInsert("test-composed", {
    after = "tl-363-364",
    steps = {
        { id = "tc-vendor-1", vendor = true, npc = 2115, at = { 1420, 32.29, 65.44 },
          note = { ru = "Продайте хлам", en = "Sell junk" } },
    },
})
-- before a library step (quest 376 needs level 2)
AdventureAtlas.AddInsert("test-composed", {
    before = "tl-accept-376",
    steps = {
        { id = "tc-level-2", level = 2 },
    },
})
-- before a library step, without an explicit id: "tl-turnin-3901+1"
AdventureAtlas.AddInsert("test-composed", {
    before = "tl-turnin-3901",
    steps = {
        { go = true, at = { 1420, 31.0, 65.0 }, note = { ru = "Вернитесь в Мертвый Звон", en = "Back to Deathknell" } },
    },
})
-- after an own step (of the own segment placed between library segments)
AdventureAtlas.AddInsert("test-composed", {
    after = "tc-train-4",
    steps = {
        { id = "tc-vendor-4", vendor = true, npc = 2116, at = { 1420, 32.38, 66.23 } },
    },
})
-- before an own step (the very first step of the route)
AdventureAtlas.AddInsert("test-composed", {
    before = "tc-intro-go",
    steps = {
        { id = "tc-welcome", manual = true,
          note = { ru = "Составной маршрут: нажмите «Далее»", en = "Composed route: press Next" } },
    },
})
-- a class-filtered insert (filtered out for the route's profile) at a library step
AdventureAtlas.AddInsert("test-composed", {
    after = "tl-sethearth",
    steps = {
        { id = "tc-warrior-only", train = true, class = "WARRIOR", npc = 2119, at = { 1420, 32.7, 65.6 } },
    },
})
