-- FastesBoooy_Guides / Segments / Durotar / 02_Durotar.lua
-- Placeholder: segment "dur-02-durotar" (levels 6-12, Orc and Troll) is not written yet.
-- Planned content: Durotar, class-neutral; ends at Rhinag outside the Orgrimmar gate.
-- Written in phase P1 of docs/dev/PLAN.md. Until then this file registers nothing. As the last segment file of
-- the zone it will end with the start-zone announcement that makes Route.lua register the Orc and Troll routes:
--   local _, ns = ...
--   ns.startZones = ns.startZones or {}
--   ns.startZones.Durotar = { "dur-01-valley-of-trials", "dur-02-durotar" }
if not FastesBoooy.AddLibraryInsert then return end
