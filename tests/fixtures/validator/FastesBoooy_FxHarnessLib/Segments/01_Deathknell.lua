-- Validator test fixture: library segment "fh-deathknell". It only works from a start state
-- (tests/fixtures/validator/harness_state_6.json): 381 must be in the quest log with its
-- objectives done, and the character must be level 6 for the Brill quests of "fh-brill".
FastesBoooy.AddLibrarySegment({
    id = "fh-deathknell",
    title = { ru = "5-6 Мертвый Звон (из состояния)", en = "5-6 Deathknell (from a start state)" },
    zone = "Tirisfal Glades",
    levels = { 6, 6 },
    steps = {
        { id = "fh-381", turnin = 381, accept = 382, npc = 1570, at = { 1420, 32.15, 66.01 },
          note = { ru = "Сдайте 381 и возьмите 382", en = "Turn in 381, take 382" } },
        { id = "fh-go-brill", go = true, at = { 1420, 58.5, 53.0 },
          note = { ru = "Бегите в Брилл", en = "Run to Brill" } },
    },
})
