-- AdventureAtlas_TestGuides / Classes / Warrior.lua
-- Core test fixture: shared inserts with class scope; a step may narrow the scope with its own
-- key (race = "Orc": the letter quest of the orc warrior).
if not AdventureAtlas.AddLibraryInsert then return end

AdventureAtlas.AddLibraryData({ rewards = { WARRIOR = { [789] = 1 } } })

AdventureAtlas.AddLibraryInsert({
    after = "tg-dur-788-in",
    class = "WARRIOR",
    steps = {
        { id = "tg-war-letter-orc", race = "Orc", accept = 2383, npc = 3143, at = { 1411, 42.1, 68.3 } },
        { id = "tg-war-frang", turnin = 2383, npc = 3153, at = { 1411, 42.9, 69.4 } },
    },
})
-- nested anchor: a step of the insert above. (An insert anchored on the LAST step of an earlier
-- insert at anchor X lands behind later inserts at X; no other insert of an orc warrior's route
-- is anchored on tg-dur-788-in, so the order here is letter, turn-in, training.)
AdventureAtlas.AddLibraryInsert({
    after = "tg-war-frang",
    class = "WARRIOR",
    steps = {
        { id = "tg-war-train-2", train = true, npc = 3153, at = { 1411, 42.9, 69.4 } },
    },
})
