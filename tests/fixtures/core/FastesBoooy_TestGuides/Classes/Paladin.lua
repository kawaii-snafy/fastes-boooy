-- FastesBoooy_TestGuides / Classes / Paladin.lua
-- Core test fixture: shared inserts of one class (scope `class`), valid for every race of the
-- class; a route of another class never composes them.
if not FastesBoooy.AddLibraryInsert then return end

-- class reward table: choices for quests turned in on shared steps (one call per class file)
FastesBoooy.AddLibraryData({ rewards = { PALADIN = { [3901] = 2 } } })

FastesBoooy.AddLibraryInsert({
    after = "tg-ud-364-in",
    class = "PALADIN",
    steps = {
        { id = "tg-pal-train-1", train = true, npc = 244808, at = { 1420, 31.1, 66.4 },
          spells = { "Seal of Righteousness" } },
    },
})
