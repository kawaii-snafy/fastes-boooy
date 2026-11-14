-- Validator fixture: level too low (deliberate errors, see tests/spec/validator_fixtures_spec.lua).
AdventureAtlas.RegisterRoute({
    api = 1,
    id = "fx-level-low",
    title = { ru = "Тест: level too low", en = "Fixture: level too low" },
    faction = "Horde",
    races = { "Scourge" },
    classes = { "PALADIN" },
    levels = { 1, 3 },
})
