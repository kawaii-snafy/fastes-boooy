-- Validator test fixture: library segment "fh-brill": a level-6 quest (367), a quest whose
-- prerequisite (427) is done before the run, a hearthstone bind and a flight to a flight point
-- known from the start state (Undercity). 382 (from "fh-deathknell") is carried out of the run.
FastesBoooy.AddLibrarySegment({
    id = "fh-brill",
    title = { ru = "6-8 Брилл (из состояния)", en = "6-8 Brill (from a start state)" },
    zone = "Tirisfal Glades",
    levels = { 6, 8 },
    steps = {
        { id = "fh-johaan", accept = 367, npc = 1518, at = { 1420, 59.45, 52.40 } },
        { id = "fh-zygand", accept = 370, npc = 1515, at = { 1420, 60.59, 51.76 } },
        { id = "fh-367", complete = 367, at = { 1420, 54.0, 50.5 },
          note = { ru = "Кровь гончих: гончие вокруг Брилла", en = "Darkhound Blood: darkhounds around Brill" } },
        { id = "fh-370", complete = 370, at = { 1420, 49.0, 66.8 },
          note = { ru = "Алый орден к югу от Брилла", en = "Scarlet Crusade south of Brill" } },
        { id = "fh-turnin-367", turnin = 367, npc = 1518, at = { 1420, 59.45, 52.40 } },
        { id = "fh-turnin-370", turnin = 370, npc = 1515, at = { 1420, 60.59, 51.76 } },
        { id = "fh-sethearth", sethearth = "Brill", npc = 5688, at = { 1420, 61.72, 52.05 } },
        { id = "fh-fly-uc", fly = "Undercity", npc = 4551, at = { 1458, 63.25, 48.56 },
          note = { ru = "Летите в Подгород", en = "Fly to the Undercity" } },
    },
})
