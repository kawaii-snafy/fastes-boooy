-- AdventureAtlas_Guides / Races / Orc.lua
-- The steps that exist because of the race (Orc) on the shared path, as shared inserts with race scope; step ids
-- "orc-...". The Durotar start zone (Segments/Durotar) is shared with the Troll and holds the Orc's way to
-- level 11 and the three city inserts of h-12 (Kor'ghan, Nazgrel, Rhinag).
--   The Crossroads  the flight chain 6365 > 6384 > 6385 > 6386 (Orc and Troll only in the DB; quest level 10, full
--                   XP up to 15, 1,890 XP known) after h15-sethearth-xroads (level 14.5): Zargh > Devrak > flight
--                   to Orgrimmar > Gryshka > Doras > flight back > Zargh. Two flights of about 2 min and two short
--                   walks: about 6 min against ~13 kills (6.5 min) at the level-22 gate. `optional`
--                   (docs/dev/PLAN.md C.6): the worst case of every gate is computed without it.
--   Level 40        riding (Kildar) and the wolf (Ogunaro Wolfrunner) in the Valley of Honor, after h-40-org-arrive
--                   (level 40.0; the route is in Orgrimmar and flies on from Doras). Optional (100 gold may be
--                   missing), about 3 min of walking inside the city. Every Orc class but the warlock (the Felsteed
--                   comes from the class file).
if not AdventureAtlas.AddLibraryInsert then return end

local ZARGH = { 1413, 52.62, 29.84 }
local DEVRAK = { 1413, 51.50, 30.34 }
local GRYSHKA = { 1454, 54.10, 68.41 }
local DORAS = { 1454, 45.12, 63.89 }

------------------------------------------------------------------------------
-- The Crossroads at 14: the flight chain (optional)
------------------------------------------------------------------------------
AdventureAtlas.AddLibraryInsert({
    after = "h15-sethearth-xroads",
    race = "Orc",
    steps = {
        { id = "orc-6365-zargh", accept = 6365, optional = true, npc = 3489, at = ZARGH,
          note = { ru = "По желанию (~6 мин, опыт как за ~13 убийств на 21-м): мясник Заргх у таверны - «Мясо для Оргриммара». "
                       .. "Не хотите - пропустите этот и 6 следующих шагов.",
                   en = "Optional (~6 min, the XP of ~13 kills at 21): Zargh the butcher by the inn - Meats to Orgrimmar. Not "
                       .. "interested: skip this and the next 6 steps." } },
        { id = "orc-6365-devrak", turnin = 6365, accept = 6384, optional = true, npc = 3615, at = DEVRAK,
          note = { ru = "Деврак на башне: сдайте мясо, возьмите «Полёт в Оргриммар».",
                   en = "Devrak on the tower: hand in the meat, take Ride to Orgrimmar." } },
        { id = "orc-6384-fly-org", fly = "Orgrimmar", optional = true, npc = 3310, at = DORAS,
          note = { ru = "Летите в Оргриммар (камень не используйте: он только что привязан к Перекрёстку).",
                   en = "Fly to Orgrimmar (do not hearth: the stone was just bound to the Crossroads)." } },
        { id = "orc-6384-gryshka", turnin = 6384, accept = 6385, optional = true, npc = 6929, at = GRYSHKA,
          note = { ru = "Трактирщица Гришка в Долине Силы.", en = "Innkeeper Gryshka in the Valley of Strength." } },
        { id = "orc-6385-doras", turnin = 6385, accept = 6386, optional = true, npc = 3310, at = DORAS,
          note = { ru = "Дорас на башне рядом.", en = "Doras on the tower next to it." } },
        { id = "orc-6386-fly-xroads", fly = "The Crossroads", optional = true, npc = 3615, at = DEVRAK,
          note = { ru = "Летите обратно на Перекрёсток.", en = "Fly back to the Crossroads." } },
        { id = "orc-6386-zargh", turnin = 6386, optional = true, npc = 3489, at = ZARGH,
          note = { ru = "Заргх: «Возвращение на Перекрёсток».", en = "Zargh: Return to the Crossroads." } },
    },
})

------------------------------------------------------------------------------
-- Level 40: riding in the Valley of Honor (optional; not for the warlock)
------------------------------------------------------------------------------
AdventureAtlas.AddLibraryInsert({
    after = "h-40-org-arrive",
    race = "Orc",
    class = { "HUNTER", "MAGE", "ROGUE", "SHAMAN", "WARRIOR" },
    steps = {
        -- Kildar is the Orc riding trainer (validator: INFO train-service).
        -- CONFIRM: the price of riding and whether the wolf comes with the skill (docs/dev/PLAN.md E.9).
        { id = "orc-40-riding", train = true, optional = true, npc = 4752, at = { 1454, 69.41, 13.10 },
          spells = { { ru = "Верховая езда (ученик)", en = "Apprentice Riding" } },
          note = { ru = "По желанию, со 100 з.: верховая езда. Аллея Чести, псарня на севере: Килдар - «Верховая езда "
                       .. "(ученик)», около 100 з. По анонсу Forever ездовое животное выдаётся вместе с навыком. Нет денег - "
                       .. "пропустите этот и следующий шаг, к Дорасу.",
                   en = "Optional, with 100 g: riding. The Valley of Honor, the kennels in the north: Kildar - Apprentice "
                       .. "Riding, about 100 g. Forever announced that a mount comes with the skill. No gold: skip this and "
                       .. "the next step, on to Doras." } },
        { id = "orc-40-wolf", vendor = true, optional = true, npc = 3362, at = { 1454, 69.38, 12.24 },
          note = { ru = "Только если с навыком не дали волка: Огунаро Волчий Бег рядом - любой волк. Затем к Дорасу.",
                   en = "Only if the skill came without a wolf: Ogunaro Wolfrunner next to him - any wolf. Then on to "
                       .. "Doras." } },
    },
})
