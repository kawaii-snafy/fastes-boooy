-- FastesBoooy_TestGuides / Segments / Durotar / 01_ValleyOfTrials.lua
-- Core test fixture: start zone "Durotar" (Orc, Troll), class-neutral, real Forever quests.
-- Holds a race-filtered ALTERNATIVE PAIR (tg-dur-scorpids-orc / tg-dur-scorpids-troll): each
-- route composes only the step of its race (Core/Compose.lua), so each is an anchor only there.
if not FastesBoooy.AddLibraryInsert then return end
local _, ns = ...

FastesBoooy.AddLibrarySegment({
    id = "tg-dur-01-valley-of-trials",
    title = { ru = "1-3 Долина Испытаний", en = "1-3 Valley of Trials" },
    zone = "Durotar",
    levels = { 1, 3 },
    steps = {
        { id = "tg-dur-4641", accept = 4641, npc = 10176, at = { 1411, 43.3, 68.5 } },
        { id = "tg-dur-788", turnin = 4641, accept = 788, npc = 3143, at = { 1411, 42.1, 68.3 } },
        { id = "tg-dur-boars", complete = 788, at = { 1411, 45.2, 66.9 } },
        -- anchor of the class files: class letter, first training
        { id = "tg-dur-788-in", turnin = 788, accept = 789, npc = 3143, at = { 1411, 42.1, 68.3 } },
        -- the same objective at two places, one per race
        { id = "tg-dur-scorpids-orc", race = "Orc", complete = 789, at = { 1411, 45.2, 59.4 },
          note = { ru = "Скорпиды к северу от Логова", en = "Scorpids north of the Den" } },
        { id = "tg-dur-scorpids-troll", race = "Troll", complete = 789, at = { 1411, 45.1, 71.4 },
          note = { ru = "Скорпиды к югу от Логова", en = "Scorpids south of the Den" } },
        -- the reward of 789 differs per class: Classes/*.lua, AddLibraryData{ rewards = ... }
        { id = "tg-dur-789-in", turnin = 789, npc = 3143, at = { 1411, 42.1, 68.3 } },
    },
})

ns.startZones = ns.startZones or {}
ns.startZones.Durotar = { "tg-dur-01-valley-of-trials" }
