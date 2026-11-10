-- FastesBoooy_Guides / Segments / Mulgore / 03_BarrensCrossing.lua
-- Placeholder: segment "mul-03-barrens-crossing" (level 12, Tauren) is not written yet.
-- Planned content: Thunder Bluff -> Orgrimmar on foot through the Barrens.
-- Written in phase P1 of docs/dev/PLAN.md. Until then this file registers nothing. As the last segment file of
-- the zone it will end with the start-zone announcement that makes Route.lua register the Tauren routes:
--   local _, ns = ...
--   ns.startZones = ns.startZones or {}
--   ns.startZones.Mulgore = { "mul-01-camp-narache", "mul-02-mulgore", "mul-03-barrens-crossing" }
if not FastesBoooy.AddLibraryInsert then return end
