#!/usr/bin/env lua5.1
-- tools/validate_routes.lua -- offline validator for AdventureAtlas route modules.
--
--   lua5.1 tools/validate_routes.lua [options] [module-dir ...]
--   lua5.1 tools/validate_routes.lua --help
--
-- Checks every route against the Forever DB snapshot (tools/data/forever_db.lua):
-- schema, quest availability (race/class/side/level), chains, quest log size, NPC
-- ownership and positions, trainers/flight masters/innkeepers, and simulates XP.
-- Implementation: tools/lib/validator.lua. Documentation: tools/README.md.

local here = (arg and arg[0] or ""):match("^(.*)[/\\][^/\\]*$") or "."
package.path = here .. "/?.lua;" .. package.path
local root = here .. "/.."

local V = require("lib.validator")
os.exit(V.Main(arg, root))
