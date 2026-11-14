-- AdventureAtlas_Guides / Races / Tauren.lua
-- The steps that exist because of the race (Tauren) on the shared path, as shared inserts with race scope; step ids
-- "tau-...". The Tauren flight chain 6361 > 6362 > 6363 > 6364 is not here: Segments/Mulgore/03_BarrensCrossing.lua
-- walks it (mandatory) on the way to Orgrimmar at 11-12 (docs/dev/handover/p1-mulgore.md, deviation 1;
-- docs/dev/PLAN.md C.6).
--   Level 40  riding (Kar Stormsinger) and the kodo (Harb Clawhoof) in Bloodhoof Village. At h-40-org-arrive (level
--             40.0) the route is in Orgrimmar and next flies to Camp Taurajo (h-38-orgrimmar-flight-master);
--             Bloodhoof has no flight master, so the trip goes through Thunder Bluff: fly Orgrimmar -> Thunder Bluff,
--             down the lift and south to the village (~1,400 yd on foot), mounted back to Tal, fly to Camp Taurajo
--             (the next shared step is that flight, written for Doras: it completes on the same landing). About
--             10 min, `optional` (100 gold may be missing). docs/dev/PLAN.md C.7, two inserts:
--             * non-druids (HUNTER, SHAMAN, WARRIOR): the self-contained detour tau-40-fly-tb ... tau-40-fly-taurajo;
--             * druids: only the riding steps (tau-40d-...). Classes/Druid.lua flies the druid to Thunder Bluff and
--               trains it there (dru-40-fly-tb, dru-40-train) and flies on (dru-40-fly-taurajo, an insert of its own
--               before the next shared step); the class file is registered first, so the composed druid route reads
--               h-40-org-arrive, dru-40-fly-tb, dru-40-train, tau-40d-..., dru-40-fly-taurajo. The anchor is the
--               shared step, not dru-40-train (a base-profile run skips the class files).
if not AdventureAtlas.AddLibraryInsert then return end

local TAL = { 1456, 47.00, 49.83 }
local KAR = { 1412, 46.79, 61.97 }
local HARB = { 1412, 46.65, 62.08 }

------------------------------------------------------------------------------
-- 40, druids: the riding steps between the druid's training in Thunder Bluff and its flight on
------------------------------------------------------------------------------
AdventureAtlas.AddLibraryInsert({
    after = "h-40-org-arrive",
    race = "Tauren",
    class = "DRUID",
    steps = {
        { id = "tau-40d-bloodhoof", go = true, optional = true, radius = 25, at = KAR,
          note = { ru = "По желанию, на 40-м и со 100 з.: верховая езда (~8 мин; ездовое животное даёт +60% против +40% у "
                       .. "походного облика). На лифте вниз и на юг в деревню Кровавого Копыта (~1400 м). Нет денег или "
                       .. "40-го - пропустите этот и 3 следующих шага, к Талу.",
                   en = "Optional, at 40 with 100 g: riding (~8 min; a mount is +60% against +40% for Travel Form). Take "
                       .. "the lift down and run south to Bloodhoof Village (~1,400 yd). No gold or not 40: skip this and "
                       .. "the next 3 steps, on to Tal." } },
        -- Kar Stormsinger is the Tauren riding trainer (validator: INFO train-service).
        -- CONFIRM: the price of riding and whether the kodo comes with the skill (docs/dev/PLAN.md E.9).
        { id = "tau-40d-riding", train = true, optional = true, npc = 3690, at = KAR,
          spells = { { ru = "Верховая езда (ученик)", en = "Apprentice Riding" } },
          note = { ru = "Кар Буревестник у загона кодо: «Верховая езда (ученик)», около 100 з. По анонсу Forever ездовое "
                       .. "животное выдаётся вместе с навыком.",
                   en = "Kar Stormsinger by the kodo pen: Apprentice Riding, about 100 g. Forever announced that a mount "
                       .. "comes with the skill." } },
        { id = "tau-40d-kodo", vendor = true, optional = true, npc = 3685, at = HARB,
          note = { ru = "Только если с навыком не дали кодо: Харб Когтистое Копыто рядом - любой кодо.",
                   en = "Only if the skill came without a kodo: Harb Clawhoof next to him - any kodo." } },
        { id = "tau-40d-tb", go = true, optional = true, radius = 15, npc = 2995, at = TAL,
          note = { ru = "Верхом обратно к лифту Громового Утёса и наверх к Талу.",
                   en = "Ride back to the Thunder Bluff lift and up to Tal." } },
    },
})

------------------------------------------------------------------------------
-- 40, the other classes: the same riding trip as a detour of its own (docs/dev/PLAN.md C.7)
------------------------------------------------------------------------------
AdventureAtlas.AddLibraryInsert({
    after = "h-40-org-arrive",
    race = "Tauren",
    class = { "HUNTER", "SHAMAN", "WARRIOR" },
    steps = {
        { id = "tau-40-fly-tb", fly = "Thunder Bluff", optional = true, npc = 2995, at = TAL,
          note = { ru = "По желанию, на 40-м и со 100 з.: верховая езда в деревне Кровавого Копыта (~10 мин; ездовое "
                       .. "животное даёт +60% к скорости). Дорас на башне в Долине Силы: летите в Громовой Утёс. Нет денег "
                       .. "или 40-го - пропустите этот и 5 следующих шагов и летите от Дораса сразу в Лагерь Таурахо.",
                   en = "Optional, at 40 with 100 g: riding in Bloodhoof Village (~10 min; a mount is +60% speed). Doras "
                       .. "on the tower in the Valley of Strength: fly to Thunder Bluff. No gold or not 40: skip this and "
                       .. "the next 5 steps and fly from Doras straight to Camp Taurajo." } },
        { id = "tau-40-bloodhoof", go = true, optional = true, radius = 25, at = KAR,
          note = { ru = "На лифте вниз (у 31.8, 65.9 Громового Утёса) и на юг в деревню Кровавого Копыта (~1400 м).",
                   en = "Take the lift down (at 31.8, 65.9 of Thunder Bluff) and run south to Bloodhoof Village "
                       .. "(~1,400 yd)." } },
        -- Kar Stormsinger is the Tauren riding trainer (validator: INFO train-service).
        -- CONFIRM: the price of riding and whether the kodo comes with the skill (docs/dev/PLAN.md E.9).
        { id = "tau-40-riding", train = true, optional = true, npc = 3690, at = KAR,
          spells = { { ru = "Верховая езда (ученик)", en = "Apprentice Riding" } },
          note = { ru = "Кар Буревестник у загона кодо: «Верховая езда (ученик)», около 100 з. По анонсу Forever ездовое "
                       .. "животное выдаётся вместе с навыком.",
                   en = "Kar Stormsinger by the kodo pen: Apprentice Riding, about 100 g. Forever announced that a mount "
                       .. "comes with the skill." } },
        { id = "tau-40-kodo", vendor = true, optional = true, npc = 3685, at = HARB,
          note = { ru = "Только если с навыком не дали кодо: Харб Когтистое Копыто рядом - любой кодо.",
                   en = "Only if the skill came without a kodo: Harb Clawhoof next to him - any kodo." } },
        { id = "tau-40-tb", go = true, optional = true, radius = 15, npc = 2995, at = TAL,
          note = { ru = "Верхом обратно к лифту Громового Утёса и наверх к Талу.",
                   en = "Ride back to the Thunder Bluff lift and up to Tal." } },
        -- The next shared step (h-38-orgrimmar-flight-master) is the same flight, written for Orgrimmar ("Doras"):
        -- it completes on the same landing (fly = arrival at `at`).
        { id = "tau-40-fly-taurajo", fly = "Camp Taurajo", optional = true, npc = 10378, at = { 1413, 44.45, 59.15 },
          note = { ru = "Тал на центральной вершине Громового Утёса (не Дорас: вы не в Оргриммаре): летите в Лагерь "
                       .. "Таурахо.",
                   en = "Tal on the central mesa of Thunder Bluff (not Doras: you are not in Orgrimmar): fly to Camp "
                       .. "Taurajo." } },
    },
})
