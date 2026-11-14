AdventureAtlas.AddSegment("test-route", {
    id = "tr-01",
    title = { ru = "1-4 Мертвый Звон", en = "1-4 Deathknell" },
    zone = "Tirisfal Glades",
    levels = { 1, 4 },
    steps = {
        -- 1: accept (single quest id), note
        { id = "tr-accept-363", accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 },
          note = { ru = "Поговорите с Гробовщиком Мордо", en = "Talk to Undertaker Mordo" } },
        -- 2: multi-action step: turn in + accept at the same NPC
        { id = "tr-363-364", turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
        -- 3: background goal: objective #1 of 364 only
        { id = "tr-bg-364", complete = { [364] = { 1 } }, bg = true,
          note = { ru = "Бейте безмозглых зомби по пути", en = "Kill Mindless Zombies on the way" } },
        -- 4: class trainer (class filter matches), spells shown
        { id = "tr-train-1", train = true, class = "PALADIN", npc = 244808, at = { 1420, 31.1, 66.4 },
          spells = { { ru = "Печать праведности", en = "Seal of Righteousness" } } },
        -- 5-7: filtered out for Horde / Scourge / PALADIN
        { id = "tr-warrior", train = true, class = "WARRIOR", npc = 2119, at = { 1420, 32.7, 65.6 } },
        { id = "tr-troll", go = true, race = "Troll", at = { 1420, 40.0, 40.0 } },
        { id = "tr-alliance", vendor = true, faction = "Alliance" },
        -- 8: complete the whole quest
        { id = "tr-complete-364", complete = 364, at = { 1420, 32.5, 63.5 } },
        -- 9: turn in with a reward choice + accept the follow-up
        { id = "tr-turnin-364", turnin = 364, accept = 3901, npc = 1569, at = { 1420, 30.8, 66.2 },
          reward = { [364] = 2 } },
        -- 10: level n
        { id = "tr-level-2", level = 2 },
        -- 11: accept with race + faction filters that match
        { id = "tr-accept-376", accept = 376, npc = 1661, at = { 1420, 30.9, 66.0 },
          race = { "Scourge", "Orc" }, faction = "Horde" },
        -- 12: background collect without a quest
        { id = "tr-bg-collect", collect = { [2876] = 5 }, bg = true,
          note = { ru = "Собирайте шкуры сумеречных мышей", en = "Loot Duskbat Pelts" } },
        -- 13: collect (two items) + use item button
        { id = "tr-collect-376", collect = { [3264] = 6, [3265] = 6 }, use = 3264, at = { 1420, 34.0, 62.0 } },
        -- 14: complete a plain quest id
        { id = "tr-complete-3901", complete = { 3901 }, at = { 1420, 32.5, 61.0 } },
        -- 15: turn in two, accept two, several NPCs
        { id = "tr-turnin-3901-376", turnin = { 3901, 376 }, accept = { 380, 3902 },
          npc = { 1569, 1661, 1570, 1740 }, at = { 1420, 31.4, 65.9 },
          note = { ru = "Сдайте и возьмите задания у NPC рядом", en = "Turn in and pick up from the NPCs nearby" } },
        -- 16: optional (forwarded once a later stateful step is done)
        { id = "tr-optional", optional = true, level = { 2, 0.5 },
          note = { ru = "По желанию: добейте половину уровня", en = "Optional: grind half a level" } },
        -- 17: abandon
        { id = "tr-abandon-3902", abandon = 3902,
          note = { ru = "Бросьте задание", en = "Abandon this quest" } },
        -- 18-19
        { id = "tr-complete-380", complete = 380, at = { 1420, 27.0, 59.0 } },
        { id = "tr-turnin-380", turnin = 380, npc = 1570, at = { 1420, 32.2, 66.0 } },
        -- 20: level with a bar fraction
        { id = "tr-level-4", level = { 4, 0.3 } },
    },
})
