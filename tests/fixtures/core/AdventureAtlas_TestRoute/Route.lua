-- Core test fixture: route "test-route" (Horde / Scourge / PALADIN).
-- Covers every action type, the class/race/faction filters, bg, optional,
-- reward, gossip, use, spells, notes and multi-action steps. Quest ids are real
-- Deathknell quests so tools/simulate_routes.lua can use tools/data/forever_db.lua.
AdventureAtlas.RegisterRoute({
    api = 1,
    id = "test-route",
    title = { ru = "Тестовый маршрут", en = "Test route" },
    description = { ru = "Фикстура тестов ядра", en = "Core test fixture" },
    faction = "Horde",
    races = { "Scourge" },
    classes = { "PALADIN" },
    levels = { 1, 10 },
    version = "0.0.1",
    author = "AdventureAtlas tests",
    default = true,
})
