-- Validator fixture: wrong quest id (deliberate errors, see tests/spec/validator_fixtures_spec.lua).
AdventureAtlas.RegisterRoute({
    api = 1,
    id = "fx-wrong-quest",
    title = { ru = "Тест: wrong quest id", en = "Fixture: wrong quest id" },
    faction = "Horde",
    races = { "Scourge" },
    classes = { "PALADIN" },
    levels = { 1, 3 },
})
