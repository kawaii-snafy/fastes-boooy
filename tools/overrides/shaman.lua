-- tools/overrides/shaman.lua -- DB corrections for the quests of Classes/Shaman.lua (format and rules:
-- tools/overrides/README.md).
-- 1516 / 1519 (Call of Earth, the first quest of the Durotar / Mulgore chain): the snapshot gives both the pre-quest
-- list "one of 1516, 1519, 92466" - the exclusive group of the three Earth chains written as a prerequisite, so the
-- quest would need itself turned in first and could never be accepted. The original game has no prerequisite (the
-- exclusive list stays). Not verified in the Forever client yet (CONFIRM on the accept steps).
-- XP of the Forever-new Skyborne chains (92484, 92466 - 92468, 97243 - 97245, 97257) is unknown and stays estimated
-- until someone records it in game (/aa xp), with source "in game YYYY-MM-DD".
return {
    quests = {
        [1516] = { preSingle = { remove = { 1516, 1519, 92466 } },
                   source = "https://www.wowhead.com/classic/quest=1516", verified = false },
        [1519] = { preSingle = { remove = { 1516, 1519, 92466 } },
                   source = "https://www.wowhead.com/classic/quest=1519", verified = false },
    },
}
