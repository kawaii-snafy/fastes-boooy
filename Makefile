# FastesBoooy -- offline checks and packaging (POSIX make; the parallel targets need xargs with
# -P and -r: GNU findutils or BSD).
#
#   make check        lint + test + validate + simulate (+ simulate-sync), each also on the fixture routes,
#                     + the start-state harness on the fixture library (what CI runs)
#   make check-fast   lint + validate + the fixture stages + simulate of ROUTE: about half a minute
#   make route ROUTE=<id>   validate (VALIDATE_FLAGS) and simulate one route (ROUTE takes what --route
#                     takes: a comma list, `*` wildcards)
#   make lint         luacheck with the generated 'forever' std (.luacheckrc)
#   make test         busted specs (tests/spec)
#   make validate     route validator against tools/data/forever_db.lua (addons/FastesBoooy_*: route
#                     modules, composed with their library dependencies, and library modules)
#   make simulate     run every route through the real engine on the WoW mock, JOBS simulations at a
#                     time (the route list comes from tools/simulate_routes.lua --list-routes; a module
#                     that does not load fails the target)
#   make simulate-sync  "player ahead of the route", JOBS runs at a time: every route of SYNC_ROUTES
#                     from a fresh character at the levels SYNC_LEVELS (10 23 35 48), the level-sync
#                     suggestions applied (--ahead L); a jump in the middle of a segment with its
#                     quests in the log (SYNC_MID: --ahead L --ahead-at SEG); the whole route SYNC_PLUS
#                     levels above its plan in levelSync "auto" (--level-plus N)
#   make simulate-sync-full   the same for every route (nightly CI, .github/workflows/nightly.yml)
#   make validate-fixtures / simulate-fixtures   the same on the known-good fixture routes
#   make harness-fixtures  validator (--strict) + simulator harness of the fixture library from its start state
#   make harness PROFILE=race=Scourge,class=PALADIN,faction=Horde [LIB=addons/FastesBoooy_Horde]
#                [SEGMENTS=h-a,h-b] [STATE=start.json] [OUT=end.json]
#                     validate, then simulate a part of a library module from a start state (OUT: end state)
#   make report       write docs/VALIDATION.md (validator Markdown report; fails when no report was written)
#   make routedata    regenerate Data.lua of every route / library module
#   make api BIR=... WOWUI=...          regenerate tools/data/forever_api.lua
#   make db RESEARCH=... CONVERSION=... regenerate tools/data/forever_db.lua (objective counts:
#                     tools/data/wowhead_requirements.json)
#   make requirements re-fetch tools/data/wowhead_requirements.json (network; then make db)
#   make package      dist/<Addon>-<Version>.zip for every addons/* directory
#
#   JOBS=N            parallel simulations of simulate / simulate-sync (default: the number of CPUs)
#
# See tools/README.md for details.

LUA = lua5.1
LUACHECK = luacheck
BUSTED = busted
PYTHON = python3
# The gate of `make validate` / `make route`. Phase F1 (the old modules; their -- WARN-OK comments are
# not converted to the `ok` key yet): none. From F2a on: --strict --end-level; later the grind budget
# and the baseline (docs/dev/PLAN.md A.6.3).
VALIDATE_FLAGS =
# Parallel simulations: one simulator process per line of arguments, JOBS at a time. A failing job
# makes xargs (and the target) fail. Each job collects its output in a file of a temporary directory
# and prints it when it ends, while it holds a lock (a directory: mkdir is atomic and needs no extra
# tool): the output of one job is one block in the log, whatever its size, also when several jobs
# end together.
# -r: no run on empty input (GNU xargs would otherwise start one simulator without --route = every
# route in one process).
JOBS ?= $(shell nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)
SIM = $(LUA) tools/simulate_routes.lua
RUN_JOB = out="$$JOBS_DIR/$$$$.out"; $(SIM) "$$@" > "$$out" 2>&1; rc=$$?; \
	until mkdir "$$JOBS_DIR/lock" 2>/dev/null; do \
		[ -d "$$JOBS_DIR" ] || exit 1; sleep 0.1 2>/dev/null || sleep 1; \
	done; \
	cat "$$out"; rm -f "$$out"; rmdir "$$JOBS_DIR/lock"; exit $$rc
RUN_JOBS = ( dir=`mktemp -d` || exit 1; trap 'rm -rf "$$dir"; exit 130' HUP INT TERM; \
	JOBS_DIR="$$dir" xargs -r -P $(JOBS) -L 1 sh -c '$(RUN_JOB)' sim; rc=$$?; rm -rf "$$dir"; exit $$rc )
# make route / make check-fast: the route(s) to validate and simulate (what --route takes). The
# wildcard matches horde-undead-paladin of the old modules and undead-paladin of FastesBoooy_Guides.
ROUTE = *undead-paladin
# The fixtures use real quest ids: they must not move when a DB override file (tools/overrides/*.lua)
# changes, so every fixture target runs on the plain snapshot.
NO_OVERRIDES = --no-overrides
# Known-good fixture routes: must validate with 0 errors and simulate cleanly, so the
# validate / simulate stages check something even before the first route module exists.
# FastesBoooy_TestComposed = own segments + library segments of FastesBoooy_TestLib (UseSegments)
# + class inserts (AddInsert); the library module itself is validated / regenerated, not simulated.
# FastesBoooy_TestGuides = one module with shared segments per start zone, shared class / race inserts
# (AddLibraryInsert), a class reward table and three routes registered from a table (the shape of
# FastesBoooy_Guides).
FIXTURE_VALIDATE = tests/fixtures/validator/FastesBoooy_FxClean tests/fixtures/validator/FastesBoooy_FxNs \
	tests/fixtures/core/FastesBoooy_TestRoute tests/fixtures/core/FastesBoooy_TestLib \
	tests/fixtures/core/FastesBoooy_TestComposed tests/fixtures/validator/FastesBoooy_FxHarnessLib \
	tests/fixtures/core/FastesBoooy_TestGuides
FIXTURE_SIMULATE = tests/fixtures/core/FastesBoooy_TestRoute tests/fixtures/core/FastesBoooy_TestComposed \
	tests/fixtures/core/FastesBoooy_TestGuides
# make simulate-sync: the routes of the "player ahead of the route" runs. With FastesBoooy_Guides this
# becomes one route per race with five different classes (docs/dev/PLAN.md A.7); every route:
# make simulate-sync-full.
SYNC_ROUTES = horde-undead-paladin horde-skyborne-druid
# start levels of the runs (tools/simulate_routes.lua --ahead)
SYNC_LEVELS = 10 23 35 48
# mid-route jumps with a quest log (--ahead L --ahead-at SEG,...: the first listed segment the route has;
# both routes have a 15-18 Barrens segment and the shared library segments): LEVEL/SEGMENTS
SYNC_MID = 21/ud-04-barrens,sd-04-barrens 29/h-24-barrens-stonetalon
# levels above the route's plan during normal play, levelSync "auto" (--level-plus N)
SYNC_PLUS = 2 4
FIXTURE_ROUTEDATA = tests/fixtures/validator/FastesBoooy_FxClean tests/fixtures/core/FastesBoooy_TestLib \
	tests/fixtures/core/FastesBoooy_TestComposed tests/fixtures/validator/FastesBoooy_FxHarnessLib \
	tests/fixtures/core/FastesBoooy_TestGuides
# Start-state harness fixture (tools/lib/harness.lua): a library module that validates /
# simulates cleanly only from its start state, for both 22-60 profiles.
FIXTURE_HARNESS_LIB = tests/fixtures/validator/FastesBoooy_FxHarnessLib
FIXTURE_HARNESS_STATE = tests/fixtures/validator/harness_state_6.json
PROFILE_UD = race=Scourge,class=PALADIN,faction=Horde
PROFILE_SD = race=Skyborne,class=DRUID,faction=Horde
# make harness: library module, segments (empty: all), profile (required), start state, end state
# (the tools treat an empty --segments / --state / --write-state value as "not given")
LIB = addons/FastesBoooy_Horde
SEGMENTS =
PROFILE =
STATE =
OUT =
# make report: the file it writes
REPORT = docs/VALIDATION.md
# make api BIR=/path/to/BlizzardInterfaceResources/Resources WOWUI=/path/to/Interface/AddOns|none
BIR =
WOWUI =
# make db RESEARCH=/path/to/research (db/*.json + xp_table.json)
#         CONVERSION=/path/to/QuestieDB/data/Forever/conversion.json|none (zone sizes in yards)
RESEARCH =
CONVERSION =

.PHONY: all check check-fast route lint test validate validate-fixtures simulate simulate-sync simulate-sync-full \
	simulate-fixtures harness-fixtures harness report routedata routedata-check api db requirements package clean help

all: check

help:
	@sed -n '4,37p' Makefile

check: lint test validate validate-fixtures simulate simulate-sync simulate-fixtures harness-fixtures

check-fast: lint validate validate-fixtures simulate-fixtures harness-fixtures
	$(SIM) --route '$(ROUTE)'

route:
	$(LUA) tools/validate_routes.lua $(VALIDATE_FLAGS) --route '$(ROUTE)'
	$(SIM) --route '$(ROUTE)'

lint:
	$(LUACHECK) --config .luacheckrc addons tools tests

test:
	$(BUSTED)

validate:
	$(LUA) tools/validate_routes.lua $(VALIDATE_FLAGS)

validate-fixtures:
	$(LUA) tools/validate_routes.lua -q $(NO_OVERRIDES) $(FIXTURE_VALIDATE)

# The job list is built first: a failing --list-routes (a module that does not load) or an empty list
# fails the target instead of simulating nothing.
simulate:
	@routes=`$(SIM) --list-routes` || { echo "simulate: --list-routes failed: nothing simulated"; exit 1; }; \
	[ -n "$$routes" ] || { echo "simulate: no routes"; exit 1; }; \
	echo "simulate:" `printf '%s\n' $$routes | wc -l` "route(s), $(JOBS) at a time"; \
	printf '%s\n' $$routes | sed 's/^/--route /' | $(RUN_JOBS) && echo "simulate: all routes passed"

# SYNC_ROUTES x (SYNC_LEVELS + SYNC_MID + SYNC_PLUS) runs. The same guard: the list of argument
# lines is built first, an empty list is an error.
simulate-sync:
	@jobs=`for r in $(SYNC_ROUTES); do \
		for level in $(SYNC_LEVELS); do echo "--route $$r --ahead $$level"; done; \
		for spec in $(SYNC_MID); do echo "--route $$r --ahead $${spec%%/*} --ahead-at $${spec#*/}"; done; \
		for plus in $(SYNC_PLUS); do echo "--route $$r --level-plus $$plus"; done; \
	done`; \
	[ -n "$$jobs" ] || { echo "simulate-sync: no runs (SYNC_ROUTES is empty)"; exit 1; }; \
	echo "simulate-sync:" `printf '%s\n' "$$jobs" | wc -l` "run(s), $(JOBS) at a time"; \
	printf '%s\n' "$$jobs" | $(RUN_JOBS) && echo "simulate-sync: all runs passed"

simulate-sync-full:
	@routes=`$(SIM) --list-routes` || { echo "simulate-sync-full: --list-routes failed: nothing simulated"; exit 1; }; \
	[ -n "$$routes" ] || { echo "simulate-sync-full: no routes"; exit 1; }; \
	$(MAKE) simulate-sync SYNC_ROUTES="`echo $$routes`"

simulate-fixtures:
	$(SIM) $(NO_OVERRIDES) $(FIXTURE_SIMULATE)

harness-fixtures:
	$(LUA) tools/validate_routes.lua -q --strict $(NO_OVERRIDES) --harness $(FIXTURE_HARNESS_LIB) \
		--profile $(PROFILE_UD) --state $(FIXTURE_HARNESS_STATE)
	$(LUA) tools/validate_routes.lua -q --strict $(NO_OVERRIDES) --harness $(FIXTURE_HARNESS_LIB) \
		--profile $(PROFILE_SD) --state $(FIXTURE_HARNESS_STATE)
	$(SIM) $(NO_OVERRIDES) --harness $(FIXTURE_HARNESS_LIB) --profile $(PROFILE_UD) \
		--state $(FIXTURE_HARNESS_STATE)
	$(SIM) $(NO_OVERRIDES) --harness $(FIXTURE_HARNESS_LIB) --profile $(PROFILE_SD) \
		--state $(FIXTURE_HARNESS_STATE)

harness:
	@if [ -z "$(PROFILE)" ]; then \
		echo "usage: make harness PROFILE=race=Scourge,class=PALADIN,faction=Horde [LIB=addons/FastesBoooy_Horde]"; \
		echo "       [SEGMENTS=h-a,h-b] [STATE=start.json] [OUT=end.json]   (tools/README.md, section Harness)"; \
		exit 2; \
	fi
	$(LUA) tools/validate_routes.lua --harness "$(LIB)" --profile "$(PROFILE)" --segments "$(SEGMENTS)" \
		--state "$(STATE)" --write-state "$(OUT)"
	$(SIM) --harness "$(LIB)" --profile "$(PROFILE)" --segments "$(SEGMENTS)" \
		--state "$(STATE)"

# Routes with errors do not fail the target (the validator then exits 1 and the report shows them),
# a validator that wrote no report does: it crashed (a Lua error is exit status 1 as well) or refused
# its arguments. The report is written to a temporary file first, so $(REPORT) is either the new
# report or untouched, and CI cannot take a stale file for a fresh one.
report:
	@tmp=`mktemp` || exit 1; \
	$(LUA) tools/validate_routes.lua -q --markdown "$$tmp"; rc=$$?; \
	if [ $$rc -gt 1 ] || [ ! -s "$$tmp" ]; then \
		rm -f "$$tmp"; \
		echo "report: the validator wrote no report (exit status $$rc): $(REPORT) is unchanged"; \
		exit 1; \
	fi; \
	cat "$$tmp" > '$(REPORT)'; rc=$$?; rm -f "$$tmp"; [ $$rc -eq 0 ] || exit 1; \
	echo "report: $(REPORT) written"

routedata:
	$(LUA) tools/gen_route_data.lua --all

routedata-check:
	$(LUA) tools/gen_route_data.lua --all --check
	$(LUA) tools/gen_route_data.lua --check $(NO_OVERRIDES) $(FIXTURE_ROUTEDATA)

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

requirements:
	$(PYTHON) -I tools/fetch_wowhead_requirements.py

package:
	$(PYTHON) -I tools/package_addons.py

clean:
	rm -rf dist
