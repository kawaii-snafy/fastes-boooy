-- Validator fixture: the files of a module share the addon's private table (`local _, ns = ...`),
-- as in the WoW client: the route id is defined once and used by the segment files.
local _, ns = ...
ns.ROUTE = "fx-ns"
FastesBoooy.RegisterRoute({
    api = 1,
    id = ns.ROUTE,
    title = { ru = "Тест: общая таблица аддона", en = "Fixture: shared addon table" },
    faction = "Horde",
    races = { "Scourge" },
    classes = { "PALADIN" },
    levels = { 1, 2 },
})
