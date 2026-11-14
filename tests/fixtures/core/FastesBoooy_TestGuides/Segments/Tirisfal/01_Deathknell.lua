-- FastesBoooy_TestGuides / Segments / Tirisfal / 01_Deathknell.lua
-- Core test fixture: start zone "Tirisfal" (Scourge), class-neutral, real Forever quests.
-- Every step has an explicit id (anchors of the class files); the `level` step is a
-- class-neutral gate (quest 376 needs level 2).
if not FastesBoooy.AddLibraryInsert then return end
local _, ns = ...

FastesBoooy.AddLibrarySegment({
    id = "tg-ud-01-deathknell",
    title = { ru = "1-3 Мертвый Звон", en = "1-3 Deathknell" },
    zone = "Tirisfal Glades",
    levels = { 1, 3 },
    steps = {
        { id = "tg-ud-363", accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
        { id = "tg-ud-364", turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { id = "tg-ud-zombies", complete = 364, at = { 1420, 32.5, 63.5 } },
        -- anchor of the class files: first training
        { id = "tg-ud-364-in", turnin = 364, accept = 3901, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { id = "tg-ud-lvl-2", level = 2 },
        { id = "tg-ud-376", accept = 376, npc = 1661, at = { 1420, 30.9, 66.0 } },
        { id = "tg-ud-bg-376", complete = 376, bg = true,
          note = { ru = "Собирайте лапы и крылья по пути", en = "Loot paws and wings on the way" } },
        { id = "tg-ud-rattlecages", complete = 3901, at = { 1420, 32.5, 61.0 } },
        -- the reward of 3901 differs per class: Classes/*.lua, AddLibraryData{ rewards = ... }
        { id = "tg-ud-3901-in", turnin = 3901, npc = 1569, at = { 1420, 30.8, 66.2 } },
        { id = "tg-ud-376-in", turnin = 376, npc = 1661, at = { 1420, 30.9, 66.0 } },
    },
})

-- start-zone announcement (read by Route.lua): the zone's segments in route order. `only`:
-- while the zone is not class-neutral yet, register only these classes of its races.
ns.startZones = ns.startZones or {}
ns.startZones.Tirisfal = { "tg-ud-01-deathknell", only = { "PALADIN" } }
