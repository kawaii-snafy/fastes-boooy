-- FastesBoooy_TestGuides / Races / Troll.lua
-- Core test fixture: shared inserts with race scope. The TOC lists race files after the class
-- files, so at a common anchor the race steps come after the class steps.
if not FastesBoooy.AddLibraryInsert then return end

-- race scope at an unfiltered anchor (shared with the class files: registered after them)
FastesBoooy.AddLibraryInsert({
    after = "tg-dur-788-in",
    race = "Troll",
    steps = {
        { id = "tg-tro-vendor", vendor = true, npc = 3158, at = { 1411, 42.6, 67.3 },
          note = { ru = "Продайте хлам", en = "Sell junk" } },
    },
})
-- an insert on a FILTERED anchor: its scope may not be wider than the anchor's filter
FastesBoooy.AddLibraryInsert({
    after = "tg-dur-scorpids-troll",
    race = "Troll",
    steps = {
        { id = "tg-tro-back", go = true, at = { 1411, 42.6, 69.0 },
          note = { ru = "Обратно в Логово", en = "Back to the Den" } },
    },
})
