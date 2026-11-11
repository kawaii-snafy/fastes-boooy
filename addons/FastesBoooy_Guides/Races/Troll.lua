-- FastesBoooy_Guides / Races / Troll.lua
-- The steps that exist because of the race (Troll) on the shared path, as shared inserts with race scope; step ids
-- "tro-...". The Durotar start zone (Segments/Durotar) is shared with the Orc and holds the Troll's way to level 11
-- and the three city inserts of h-12 (Kor'ghan, Nazgrel, Rhinag). The Orc file has the same flight chain with
-- "orc-" ids (one quest list in two files, docs/dev/PLAN.md C.6).
--   The Crossroads  the flight chain 6365 > 6384 > 6385 > 6386 (Orc and Troll only in the DB; quest level 10, full
--                   XP up to 15, 1,890 XP known) after h15-sethearth-xroads (level 14.5): Zargh > Devrak > flight
--                   to Orgrimmar > Gryshka > Doras > flight back > Zargh. About 6 min against ~13 kills (6.5 min) at
--                   the level-22 gate. `optional` (C.6): the worst case of every gate is computed without it.
--   Level 40        riding (Xar'Ti) and the raptor (Zjolnir) in Sen'jin Village, after h-40-org-arrive (level 40.0,
--                   guaranteed by the gate h39-level-mannoroc): Orgrimmar gate -> Sen'jin 2,280 yd on foot, then
--                   mounted back to Doras, about 9 min, `optional` (100 gold may be missing). One level later
--                   (h41-hearth-org) the detour costs about the same, but the 42 steps between the two anchors are
--                   the whole Dustwallow part, 41 min on foot against 26 min mounted (C.7). Every Troll class but
--                   the warlock (the Felsteed comes from the class file).
if not FastesBoooy.AddLibraryInsert then return end

local ZARGH = { 1413, 52.62, 29.84 }
local DEVRAK = { 1413, 51.50, 30.34 }
local GRYSHKA = { 1454, 54.10, 68.41 }
local DORAS = { 1454, 45.12, 63.89 }

------------------------------------------------------------------------------
-- The Crossroads at 14: the flight chain (optional)
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h15-sethearth-xroads",
    race = "Troll",
    steps = {
        { id = "tro-6365-zargh", accept = 6365, optional = true, npc = 3489, at = ZARGH,
          note = { ru = "По желанию (~6 мин, опыт как за ~13 убийств на 21-м): мясник Заргх у таверны - «Мясо для Оргриммара». "
                       .. "Не хотите - пропустите этот и 6 следующих шагов.",
                   en = "Optional (~6 min, the XP of ~13 kills at 21): Zargh the butcher by the inn - Meats to Orgrimmar. Not "
                       .. "interested: skip this and the next 6 steps." } },
        { id = "tro-6365-devrak", turnin = 6365, accept = 6384, optional = true, npc = 3615, at = DEVRAK,
          note = { ru = "Деврак на башне: сдайте мясо, возьмите «Полёт в Оргриммар».",
                   en = "Devrak on the tower: hand in the meat, take Ride to Orgrimmar." } },
        { id = "tro-6384-fly-org", fly = "Orgrimmar", optional = true, npc = 3310, at = DORAS,
          note = { ru = "Летите в Оргриммар (камень не используйте: он только что привязан к Перекрёстку).",
                   en = "Fly to Orgrimmar (do not hearth: the stone was just bound to the Crossroads)." } },
        { id = "tro-6384-gryshka", turnin = 6384, accept = 6385, optional = true, npc = 6929, at = GRYSHKA,
          note = { ru = "Трактирщица Гришка в Долине Силы.", en = "Innkeeper Gryshka in the Valley of Strength." } },
        { id = "tro-6385-doras", turnin = 6385, accept = 6386, optional = true, npc = 3310, at = DORAS,
          note = { ru = "Дорас на башне рядом.", en = "Doras on the tower next to it." } },
        { id = "tro-6386-fly-xroads", fly = "The Crossroads", optional = true, npc = 3615, at = DEVRAK,
          note = { ru = "Летите обратно на Перекрёсток.", en = "Fly back to the Crossroads." } },
        { id = "tro-6386-zargh", turnin = 6386, optional = true, npc = 3489, at = ZARGH,
          note = { ru = "Заргх: «Возвращение на Перекрёсток».", en = "Zargh: Return to the Crossroads." } },
    },
})

------------------------------------------------------------------------------
-- Level 40: riding in Sen'jin Village (optional; not for the warlock)
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h-40-org-arrive",
    race = "Troll",
    class = { "HUNTER", "MAGE", "PRIEST", "ROGUE", "SHAMAN", "WARRIOR" },
    steps = {
        { id = "tro-40-senjin", go = true, optional = true, radius = 25, at = { 1411, 55.28, 75.49 },
          note = { ru = "По желанию, со 100 з.: верховая езда (~9 мин). Из главных ворот Оргриммара по дороге на юг через "
                       .. "Колючий Холм в деревню Сен'джин (~2300 м пешком). Нет денег - пропустите этот и 3 следующих шага, "
                       .. "к Дорасу.",
                   en = "Optional, with 100 g: riding (~9 min). Out of the Orgrimmar main gate and south along the road "
                       .. "through Razor Hill to Sen'jin Village (~2,300 yd on foot). No gold: skip this and the next 3 "
                       .. "steps, on to Doras." } },
        -- Xar'Ti is the Troll riding trainer (validator: INFO train-service).
        -- CONFIRM: the price of riding and whether the raptor comes with the skill (docs/dev/PLAN.md E.9).
        { id = "tro-40-riding", train = true, optional = true, npc = 7953, at = { 1411, 55.28, 75.49 },
          spells = { { ru = "Верховая езда (ученик)", en = "Apprentice Riding" } },
          note = { ru = "Зар'Ти: «Верховая езда (ученик)», около 100 з. По анонсу Forever ездовое животное выдаётся вместе "
                       .. "с навыком.",
                   en = "Xar'Ti: Apprentice Riding, about 100 g. Forever announced that a mount comes with the skill." } },
        { id = "tro-40-raptor", vendor = true, optional = true, npc = 7952, at = { 1411, 55.23, 75.65 },
          note = { ru = "Только если с навыком не дали ящера: Зьолнир рядом - любой ящер.",
                   en = "Only if the skill came without a raptor: Zjolnir next to him - any raptor." } },
        { id = "tro-40-back", go = true, optional = true, radius = 15, npc = 3310, at = DORAS,
          note = { ru = "Верхом обратно в Оргриммар, к Дорасу на башне в Долине Силы.",
                   en = "Ride back to Orgrimmar, to Doras on the tower in the Valley of Strength." } },
    },
})
