-- FastesBoooy_Guides / Segments / Zephras / 03_ThunderBluff.lua
-- Segment "sd-03-thunder-bluff" (level 13, Skyborne: Skywatcher Plateau -> Thunder Bluff -> Orgrimmar) is not
-- written yet: its steps are still the first steps of the legacy segment "sd-03-mulgore-silverpine"
-- (Segments/Legacy/sd_03_Mulgore_Silverpine.lua). Phase F2b of docs/dev/PLAN.md moves them here and adds the
-- segment id to the announcement below.
--
-- This is the last segment file of the zone, so it holds the start-zone announcement (read by Route.lua): the
-- segments every Skyborne route starts with. `only`: while the Zephras segments still hold the druid's class
-- steps, only the druid route of the zone's race is registered.
if not FastesBoooy.AddLibraryInsert then return end
local _, ns = ...

ns.startZones = ns.startZones or {}
ns.startZones.Zephras = { "sd-01-zephras", "sd-02-zephras", only = { "DRUID" } }
