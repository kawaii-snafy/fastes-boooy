-- Validator fixture: quest log overflow (deliberate errors, see tests/spec/validator_fixtures_spec.lua).
FastesBoooy.RegisterRoute({
    api = 1,
    id = "fx-questlog",
    title = { ru = "Тест: quest log overflow", en = "Fixture: quest log overflow" },
    faction = "Horde",
    races = { "Scourge" },
    classes = { "PALADIN" },
    levels = { 1, 13 },
})
