-- FastesBoooy_TestGuides / Classes / Mage.lua
-- Core test fixture: a shared insert with class AND race scope (the letter quest 3086 is the
-- troll mage's). The trainer visit is merged into the turn-in step (same NPC).
if not FastesBoooy.AddLibraryInsert then return end

FastesBoooy.AddLibraryData({ rewards = { MAGE = { [789] = 2 } } })

FastesBoooy.AddLibraryInsert({
    after = "tg-dur-788-in",
    class = "MAGE",
    race = "Troll",
    steps = {
        { id = "tg-mag-letter-troll", accept = 3086, npc = 3143, at = { 1411, 42.1, 68.3 } },
        { id = "tg-mag-maiah", turnin = 3086, train = true, npc = 5884, at = { 1411, 42.5, 69.0 } },
    },
})
