-- tools/overrides/warlock.lua -- DB corrections for the quests of Classes/Warlock.lua (format and rules:
-- tools/overrides/README.md). Phase C (docs/dev/PLAN.md C.5).
return {
    quests = {
        -- The Troll warlock takes the Orgrimmar Voidwalker chain (Gan'rul's Summons -> Creature of the Void -> The
        -- Binding) like the Orc; the snapshot masks 1501 / 1504 as Orc only (1506 is "all Horde").
        [1501] = { races = { add = { "Troll" } },
                   source = "https://www.warcrafttavern.com/forever/guides/warlock-leveling/", verified = false },
        [1504] = { races = { add = { "Troll" } },
                   source = "https://www.warcrafttavern.com/forever/guides/warlock-leveling/", verified = false },
        -- The two final quests of the Orb of Orahil chain: the snapshot pairs each with the shard quest that leads to
        -- it (4975 Noh'Orahil "exclusive" with 4962 Shard of a Felhound, 4964 Dar'Orahil with 4963 Shard of an
        -- Infernal); in the original game the felhound spirit leads to Noh'Orahil and the infernal spirit to
        -- Dar'Orahil, so the pairs are swapped.
        [4975] = { exclusive = { remove = { 4962 }, add = { 4963 } },
                   source = "original game (classes.md 5.5): Shard of a Felhound -> Orb of Noh'Orahil",
                   verified = false },
        [4964] = { exclusive = { remove = { 4963 }, add = { 4962 } },
                   source = "original game (classes.md 5.5): Shard of an Infernal -> Orb of Dar'Orahil",
                   verified = false },
    },
}
