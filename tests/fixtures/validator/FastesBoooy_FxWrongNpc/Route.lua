-- Validator fixture: wrong quest giver / turn-in NPC (deliberate errors, see tests/spec/validator_fixtures_spec.lua).
FastesBoooy.RegisterRoute({
    api = 1,
    id = "fx-wrong-npc",
    title = { ru = "Тест: wrong quest giver / turn-in NPC", en = "Fixture: wrong quest giver / turn-in NPC" },
    faction = "Horde",
    races = { "Scourge" },
    classes = { "PALADIN" },
    levels = { 1, 3 },
})
