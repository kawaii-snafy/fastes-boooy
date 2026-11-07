-- Distances in yards (Tirisfal Glades 1420 is 4518.7 x 3012.5 yd):
-- at-far (WARN): Undertaker Mordo (30.22, 71.65) is ~67 yards from at (WARN > 40 yd);
-- at-far (ERROR): Shadow Priest Sarvis (30.84, 66.2) is ~450 yards from at (ERROR > 120 yd);
-- at-no-spawn: Sarvis has no spawn on Undercity (1458);
-- at-map-unknown: uiMap 9999; npc-unknown: NPC 99999999;
-- at-far (ERROR, approximate): Zephras Isle 2521 has no known world size, so the distance
-- to Ailee Farheart (251362, 42.82, 23.39) is measured in map units (~9.7 > 8).
FastesBoooy.AddSegment("fx-npc-far", {
    id = "fx-npc-far-01",
    title = "NPC far from at",
    levels = { 1, 2 },
    steps = {
        { accept = 363, npc = 1568, at = { 1420, 31.7, 71.7 } },
        { turnin = 363, accept = 364, npc = 1569, at = { 1420, 40.8, 66.2 } },
        { go = true, npc = 1569, at = { 1458, 50.0, 50.0 } },
        { go = true, at = { 9999, 50.0, 50.0 } },
        { manual = true, npc = 99999999 },
        { go = true, npc = 251362, at = { 2521, 52.5, 23.4 } },
        { abandon = 364 },
    },
})
