-- schema: unknown step key, invalid accept payload, step without action, bad 'at',
-- segment for an unregistered route, and a global definition (route modules may only call AdventureAtlas.*).
AdventureAtlas.AddSegment("fx-schema", {
    id = "fx-schema-01",
    title = "schema",
    levels = { 1, 2 },
    steps = {
        { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 }, colour = "red" },
        { accept = "363" },
        { note = "no action" },
        { go = true, at = { 1420, 130, 20 } },
        { turnin = 363, npc = 1569, at = { 1420, 30.8, 66.2 } },
    },
})

AdventureAtlas.AddSegment("no-such-route", {
    id = "orphan",
    title = "orphan",
    steps = { { manual = true } },
})

FxSchemaLeakedGlobal = true -- luacheck: ignore 111 131 (deliberate: the validator must report it)
