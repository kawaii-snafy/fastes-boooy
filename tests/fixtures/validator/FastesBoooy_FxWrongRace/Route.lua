-- Validator fixture: quest not available to race/class/faction (deliberate errors, see tests/spec/validator_fixtures_spec.lua).
FastesBoooy.RegisterRoute({
    api = 1,
    id = "fx-wrong-race",
    title = { ru = "Тест: quest not available to race/class/faction", en = "Fixture: quest not available to race/class/faction" },
    faction = "Horde",
    races = { "Scourge" },
    classes = { "PALADIN" },
    levels = { 1, 3 },
})
