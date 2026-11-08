# FastesBoooy -- offline checks and packaging (POSIX make).
#
#   make check        lint + test + validate + simulate, each also on the fixture routes (what CI runs)
#   make lint         luacheck with the generated 'forever' std (.luacheckrc)
#   make test         busted specs (tests/spec)
#   make validate     route validator against tools/data/forever_db.lua (addons/FastesBoooy_*: route
#                     modules, composed with their library dependencies, and library modules)
#   make simulate     run every route through the real engine on the WoW mock (addons/FastesBoooy_*
#                     route modules; library modules are played inside the routes that use them)
#   make validate-fixtures / simulate-fixtures   the same on the known-good fixture routes
#   make report       write docs/VALIDATION.md (validator Markdown report)
#   make routedata    regenerate Data.lua of every route / library module
#   make api BIR=... WOWUI=...          regenerate tools/data/forever_api.lua
#   make db RESEARCH=... CONVERSION=... regenerate tools/data/forever_db.lua
#   make package      dist/<Addon>-<Version>.zip for every addons/* directory
#
# See tools/README.md for details.

LUA = lua5.1
LUACHECK = luacheck
BUSTED = busted
PYTHON = python3
VALIDATE_FLAGS =
# Known-good fixture routes: must validate with 0 errors and simulate cleanly, so the
# validate / simulate stages check something even before the first route module exists.
# FastesBoooy_TestComposed = own segments + library segments of FastesBoooy_TestLib (UseSegments)
# + class inserts (AddInsert); the library module itself is validated / regenerated, not simulated.
FIXTURE_VALIDATE = tests/fixtures/validator/FastesBoooy_FxClean tests/fixtures/validator/FastesBoooy_FxNs \
	tests/fixtures/core/FastesBoooy_TestRoute tests/fixtures/core/FastesBoooy_TestLib \
	tests/fixtures/core/FastesBoooy_TestComposed
FIXTURE_SIMULATE = tests/fixtures/core/FastesBoooy_TestRoute tests/fixtures/core/FastesBoooy_TestComposed
FIXTURE_ROUTEDATA = tests/fixtures/validator/FastesBoooy_FxClean tests/fixtures/core/FastesBoooy_TestLib \
	tests/fixtures/core/FastesBoooy_TestComposed
# make api BIR=/path/to/BlizzardInterfaceResources/Resources WOWUI=/path/to/Interface/AddOns|none
BIR =
WOWUI =
# make db RESEARCH=/path/to/research (db/*.json + xp_table.json)
#         CONVERSION=/path/to/QuestieDB/data/Forever/conversion.json|none (zone sizes in yards)
RESEARCH =
CONVERSION =

.PHONY: all check lint test validate validate-fixtures simulate simulate-fixtures report routedata \
	routedata-check api db package clean help

all: check

help:
	@sed -n '3,17p' Makefile

check: lint test validate validate-fixtures simulate simulate-fixtures

lint:
	$(LUACHECK) --config .luacheckrc addons tools tests

test:
	$(BUSTED)

validate:
	$(LUA) tools/validate_routes.lua $(VALIDATE_FLAGS)

validate-fixtures:
	$(LUA) tools/validate_routes.lua -q $(FIXTURE_VALIDATE)

simulate:
	$(LUA) tools/simulate_routes.lua

simulate-fixtures:
	$(LUA) tools/simulate_routes.lua $(FIXTURE_SIMULATE)

report:
	-$(LUA) tools/validate_routes.lua -q --markdown docs/VALIDATION.md

routedata:
	$(LUA) tools/gen_route_data.lua --all

routedata-check:
	$(LUA) tools/gen_route_data.lua --all --check
	$(LUA) tools/gen_route_data.lua --check $(FIXTURE_ROUTEDATA)

api:
	@if [ -z "$(BIR)" ] || [ -z "$(WOWUI)" ]; then \
		echo "usage: make api BIR=/path/to/BlizzardInterfaceResources/Resources WOWUI=/path/to/Interface/AddOns"; \
		echo "       (WOWUI=none skips the FrameXML globals: luacheck would then reject Settings, SlashCmdList...)"; \
		exit 2; \
	fi
	$(PYTHON) -I tools/gen_forever_api.py --bir "$(BIR)" --wowui "$(WOWUI)"

db:
	@if [ -z "$(RESEARCH)" ] || [ -z "$(CONVERSION)" ]; then \
		echo "usage: make db RESEARCH=/path/to/research CONVERSION=/path/to/QuestieDB/data/Forever/conversion.json"; \
		echo "       (CONVERSION=none: no zone sizes, the validator then measures distances in map percent)"; \
		exit 2; \
	fi
	$(PYTHON) -I tools/build_db_snapshot.py --research "$(RESEARCH)" --conversion "$(CONVERSION)"

package:
	$(PYTHON) -I tools/package_addons.py

clean:
	rm -rf dist
