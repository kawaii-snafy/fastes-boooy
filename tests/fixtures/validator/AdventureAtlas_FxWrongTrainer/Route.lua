-- Validator fixture: wrong trainer / service NPC (deliberate errors, see tests/spec/validator_fixtures_spec.lua).
AdventureAtlas.RegisterRoute({
    api = 1,
    id = "fx-wrong-trainer",
    title = { ru = "Тест: wrong trainer / service NPC", en = "Fixture: wrong trainer / service NPC" },
    faction = "Horde",
    races = { "Scourge" },
    classes = { "PALADIN" },
    levels = { 1, 3 },
})
