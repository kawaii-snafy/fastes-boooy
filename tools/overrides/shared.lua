-- tools/overrides/shared.lua -- DB corrections for quests of the shared path and of the start zones
-- (format and rules: tools/overrides/README.md). Only the single-owner phases edit this file.
return {
    quests = {
        -- 844 Plainstrider Menace (Sergra Darkthorn, the Crossroads) is listed as exclusive with the two Tauren
        -- breadcrumbs that lead to the Crossroads: 861 The Hunter's Way (Mulgore; its chain is 861 -> 860 Sergra
        -- Darkthorn -> 844, and 860 has breadcrumbFor = 844) and 854 Journey to the Crossroads (Thunder Bluff ->
        -- Thork). The validator reads exclusivity as symmetric, so every Tauren who turned one of them in would
        -- fail the shared accept of 844 (h15-xr-arrive). In Classic 844 is the normal next quest after either
        -- breadcrumb. CONFIRM in game with a Tauren (docs/dev/PLAN.md B.2, E.21).
        [861] = { exclusive = { remove = { 844 } }, verified = false,
                  source = "the DB chain 861 -> 860 (breadcrumbFor 844) -> 844; Classic quest chain The Hunter's Way" },
        [854] = { exclusive = { remove = { 844 } }, verified = false,
                  source = "Classic: Journey to the Crossroads (Thunder Bluff) is a breadcrumb, 844 stays available" },
    },
}
