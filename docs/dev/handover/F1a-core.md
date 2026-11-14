# Hand-over F1a: core (shared inserts, aliases, mixed module, pruning)

Phase F1a of `docs/dev/PLAN.md` (A.5, A.6.1 loader stub, D.1 row F1a). Core `0.4.0`, `API_MINOR = 2`, route
format still `api = 1`. Nothing was committed (the orchestrator commits). `docs/VALIDATION.md` was **not**
regenerated (F1c does it, D.0 rule 2): it is stale by the numbers below.

## 1. What changed

### Core (`addons/FastesBoooy`)

| File | Change |
|---|---|
| `Core/Schema.lua` | `Schema.NormalizeFilters(def, where, errors)` (factored out of `NormalizeStep`, also used for the scope of a shared insert); `Schema.FiltersCanMatchRoute(filters, route)`; `step.autoId = true` on positional ids; `STEP_FIELDS.ok`, `SEGMENT_FIELDS.ok` with `Schema.NormalizeOk` (shape only); `ROUTE_FIELDS.aliases` (`route.aliases` = list of former ids) |
| `Core/Compose.lua` | `NewLibrary().inserts`; local `parseInsert`; `Compose.AddLibraryInsert(lib, def, source)`; `libraryEntry` leaves out steps that cannot match the route (rule 9); `Build`: shared inserts first (registration order), then the route's own, also when an insert is registered before the insert that supplies its anchor (verification round 1); positional-anchor error; shared steps do not advance `<anchor>+<n>`; `kindOf` says "shared insert"; "unknown shared segment '%s' (is its file listed in the TOC before Route.lua?)"; header comment (scope, order, the quirk) |
| `Core/Registry.lua` | `Registry:AddLibraryInsert`; `Registry.aliases`, `Registry:Get` resolves an alias; `Registry:List(noCompose)`; `Registry:IsComposed(route)` |
| `Core/Init.lua` | `public.AddLibraryInsert`; `API_MINOR = 2` with the comment line of A.5; `DEFAULT_VERSION = "0.4.0"` |
| `FastesBoooy.toc` | `## Version: 0.4.0` |
| `Core/Engine.lua` | `ActivateRoute` moves `cdb.route`, `cdb.cursorHintRoute`, `cdb.syncFloor.route` (also its saved `hint[3]` and the `prev` undo record) and `cdb.syncDismissed.route` from an alias to the route id; `SetRoute` saves the resolved id; `GetRewardChoice`: step `reward` first, then `route.data.rewards[class][quest]` |
| `Core/Compat.lua` | `Compat.IsAddOnLoaded(name)` |
| `UI/Options.lua` | route buttons = `Registry:Matching(facts)` (plus the active route first when it was chosen by hand for another race / class); note "...and N more. Type /fb routes."; `/fb routes` = the character's routes + "Other routes (other races and classes): N. Type /fb routes all."; `/fb routes all` = every id and title from `List(true)`; tooltip "Steps: N" only for a composed route; obsolete-modules chat line at `PLAYER_LOGIN`, once per session, only when `FastesBoooy_Guides` is loaded too (`Options:ObsoleteModules()`) |
| `Locales/UI_enUS.lua`, `UI_ruRU.lua` | `UI_OPT_NO_ROUTES` names `FastesBoooy_Guides`; new `UI_OPT_NO_MATCHING_FMT`, `UI_ROUTES_NO_MATCH`, `UI_ROUTES_OTHERS_FMT`, `UI_OBSOLETE_MODULES_FMT`; `UI_HELP_routes` mentions `all` |

### Tools, lint, build

| File | Change |
|---|---|
| `tools/lib/route_loader.lua` | stub `api.AddLibraryInsert` (source `{ module, file }`); `mod.libraryInserts` (templates, with `file`, `module`, `scope`, `applied`); `mod.aliases` and the same alias errors as the registry; `opts.replace = { [TOC path] = other file }`; composition errors of shared inserts get the insert's file (and `library` for a dependency); each composition error once per route and file (as `Registry:Finalize`); `isLibrary` also true for a module that only registers shared inserts |
| `tools/lib/harness.lua` | one line: a composition error whose source is a shared insert (`{ module, file }`) is reported with its file |
| `tools/gen_route_data.lua` | `CollectLibraryIds` also walks `mod.libraryInserts`; no `AddRouteData` block for a route that owns no step (`Gen.OwnsSteps`). See deviation 1 |
| `.luacheckrc` | std `fastesboooy_route`: field `AddLibraryInsert`, read-only `ipairs pairs next select type tostring tonumber unpack string table math` |
| `Makefile` | `FastesBoooy_TestGuides` in `FIXTURE_VALIDATE`, `FIXTURE_SIMULATE`, `FIXTURE_ROUTEDATA` |

### Fixture `tests/fixtures/core/FastesBoooy_TestGuides`

The shape of `FastesBoooy_Guides` (A.1, A.2, A.4) in small, real Forever quests, every file but `Data.lua` with
the guard line, TOC without the library declaration:

```
Data.lua                               generated, one AddLibraryData call
Segments/Tirisfal/01_Deathknell.lua    tg-ud-01-deathknell (Scourge);  ns.startZones.Tirisfal = { ..., only = { "PALADIN" } }
Segments/Durotar/01_ValleyOfTrials.lua tg-dur-01-valley-of-trials (Orc, Troll); race-filtered alternative pair
                                       tg-dur-scorpids-orc / tg-dur-scorpids-troll; ns.startZones.Durotar
Segments/Mulgore/01_CampNarache.lua    placeholder (header + guard line): no announcement, no Tauren route
Classes/Mage.lua                       class + race scope (letter 3086, turn-in merged with training); rewards.MAGE[789] = 2
Classes/Paladin.lua                    class scope (first training); rewards.PALADIN[3901] = 2
Classes/Warrior.lua                    class scope, a step with race = "Orc", nested anchor (tg-war-frang -> tg-war-train-2); rewards.WARRIOR[789] = 1
Races/Troll.lua                        race scope at an unfiltered anchor; an insert on the filtered anchor tg-dur-scorpids-troll
Route.lua                              table + numeric for; routes tg-undead-paladin (alias tg-old-undead-paladin), tg-orc-warrior, tg-troll-mage
```

Composed steps: 11 / 9 / 10 (`H.GUIDES_IDS` in `tests/fixtures/core/helpers.lua`). The reward quests 789 and
3901 are turned in on shared steps (`tg-dur-789-in`, `tg-ud-3901-in`) that carry no `reward`.

### Specs

| Spec | What |
|---|---|
| new `core_shared_insert_spec.lua` (17 cases) | the ten cases of `core.md` 5.5 (1 where it applies; 2 scope; 3 order; 4 chains and the quirk; 5 registration errors; 6 positional anchor; 7 copies; 8 late registration; 9 engine play, `/reload`, cold start; 10 login composes one route of the mixed fixture), three cases of verification round 1 (forward references keep the order; an own-step anchor in a route with `UseSegments`; an id collision with a route's own / per-route insert step) and rule 9 (alternative pair, class-only inserts behind both, positional ids, a route without `races`, per-route insert on a pruned step, an all-pruned segment, `FiltersCanMatchRoute`) |
| new `validator_guides_spec.lua` (11 cases) | loader on the fixture (`libraryInserts`, aliases, reward table as library data), `opts.replace`, `opts.skip`, error files, a dependency's shared inserts, generator, validator and simulator command lines |
| `core_registry_spec.lua` (+3) | aliases and their errors; saved progress follows a rename (and is ignored without the alias); `List(true)` / `IsComposed`; `API_MINOR = 2`, version |
| `core_ui_spec.lua` (+8) | panel and `/fb routes` do not compose; tooltip; no matching route; no module; ruRU; obsolete modules (with and without `FastesBoooy_Guides`); "route API 1.2" |
| `core_automation_spec.lua` (+4) | reward from the class table through the real reward window; step `reward` wins; invalid entries; a second `AddLibraryData` call with the same class key replaces the first (and late data is fill-only) |
| `core_schema_spec.lua` (+6) | `ok` in its three forms and its errors, on a segment; `aliases`; `autoId`; `NormalizeFilters`; pure `Compose.AddLibraryInsert` with a source |
| `validator_lint_spec.lua` (+1) | `AddLibraryInsert` and the Lua base are known to route modules; writes, `C_*`, SavedVariables, `io` / `os` / `print` stay errors |
| changed | `core_compose_spec.lua`, `validator_compose_spec.lua` (new wording "unknown shared segment"); `validator_harness_spec.lua:325` (see deviation 6) |

## 2. Acceptance: commands run and results

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 146 files |
| `busted` | 526 successes / 0 failures / 0 errors (476 before F1a; 521 before verification round 1), 76.8 s |
| `make validate` | exit 0. `horde-undead-paladin`: 0 ERROR, **95 WARN**, 381 INFO, grind **4,972 / 6,179**, end level 60.00. `horde-skyborne-druid`: 0 ERROR, **145 WARN**, 386 INFO, grind **4,878 / 6,082**, end level 60.00. No `step-no-profile` left (8 before). Everything else in the output is byte-identical to the baseline |
| composed steps (scratch script on the loader) | **1,713** and **1,748** (1,296 library steps each instead of 1,300) |
| `make validate-fixtures` | exit 0; `FastesBoooy_TestGuides`: 3 routes, 0 ERROR, 0 WARN (also with `--strict`); end levels 3.92 / 3.40 / 3.40 with `levels = { 1, 3 }` |
| `make simulate-fixtures` | 5 simulations, 5 passed (`tg-undead-paladin` 11 steps, `tg-orc-warrior` 9, `tg-troll-mage` 10) |
| `make harness-fixtures` | exit 0 (4 runs, as before) |
| `make routedata-check` | exit 0; the three old `Data.lua` and the fixture files are up to date (the generator change does not move them) |
| `make simulate` (not required for F1a, run because the core changed) | 2 simulations, 2 passed, 1,713 / 1,748 steps, 52 s |
| `make simulate-sync` (same reason) | exit 0: 8 runs x 2 routes = 16 simulations, 16 passed (5 min 14 s wall, one process at a time) |
| `git status --short addons/FastesBoooy_*` | prints nothing |

## 3. Deviations from the plan, and why

1. **`tools/gen_route_data.lua` was changed in F1a** (two items of A.6.5, which D.1 gives to F1c). Without them
   the fixture cannot be in `FIXTURE_ROUTEDATA` as A.5.7 demands: the generated `Data.lua` would miss the names
   of the shared-insert steps and would hold three empty `AddRouteData` blocks, which are load errors when
   `Data.lua` is listed before `Route.lua` (A.2). F1c only has to keep them (and add `PLACE_NAMES_RU` entries).
2. **`.luacheckrc`: the read-only Lua base was added now**, together with the field. A.6.1 names both in one
   sentence and D.1 does not say who adds the base; F1b still owes the `tools/overrides/*.lua` rule.
3. **`tools/lib/harness.lua`**: one line (the table source of a shared insert). The harness still refuses a
   module that registers routes: that is F1b (A.6.1).
4. **The obsolete-modules line is printed by `UI/Options.lua`** (the plan puts the strings into the UI locale
   files, so the code is next to the other chat output of the UI), **and only when `FastesBoooy_Guides` is
   loaded as well** (A.5.6 names the three old modules only; changed in verification round 1). Without the new
   module the old ones are the guides of the installation (all of F1, and later a core updated on its own),
   and "delete the old folders" would be wrong.
5. **Small additions the plan does not name**: `Registry:IsComposed`; a third alias error ("route X: its id is
   an alias of route Y (alias ignored)": a route id always wins, the case of an old module left installed);
   `UI_OPT_NO_MATCHING_FMT` / `UI_ROUTES_NO_MATCH` for a character no route matches; the active route is shown
   in the panel even when it does not match the character; a shared segment none of whose steps can match the
   route leaves no empty segment in it; copies of shared-insert steps are made when the anchor is found (so
   `route.libCopies[template] ~= nil` means "composed into this route"); `H.reload` keeps race / class /
   faction.
6. **`validator_harness_spec.lua:325`** asserted INFO `step-skipped` for a `class = "DRUID"` step of a library
   segment in a PALADIN harness. With rule 9 that step is not composed into the harness route at all; the case
   now asserts that (A.6.1 expects this spec file to change in F1b for the mixed-module part; this one is a
   direct consequence of the core change).
7. **A positional anchor**: the insert is applied and the error is reported (once per composed route), as in
   the prototype of `core.md`. The plan only fixes the message.
8. `ok` ceilings: any number >= 0 is accepted (the plan says "a number").

## 4. Notes for F1b (validator)

* Template data: `mod.libraryInserts[i] = { side, anchor, steps, scope, file, module, n, applied = { [routeId]
  = true } }`; `scope` and `step.filters` are `{ class = set, race = set, faction = string }`; a step's filters
  already include the scope defaults. Shared segments: `mod.librarySegments[i].steps`.
* "Composed into route R": `R.libCopies[template] ~= nil` for insert steps; for segment steps the copy exists
  when the step can match R and the segment is used by R. `R.stepById[t.id]` is that copy.
* Composed-step tags: `shared = true` (shared-insert step), `inserted`, `anchor`, `insertSide`, `library =
  "<module name>"`, `file`, `autoId` (positional id).
* `step.ok` / `seg.ok` are normalized to `{ [code] = true | ceiling }` (nil when absent or wholly invalid).
* `step-no-profile` can no longer fire for a shared step (it is not composed). It still fires for per-route
  inserts: `FastesBoooy_TestComposed` keeps its one WARN (`tc-warrior-only`).
* The fixture is clean for the module checks of A.6.2 as designed: every template step is composed into a
  route, every insert is applied, the insert on the filtered anchor has the anchor's race scope, all race
  tokens exist in `db.enums.raceFileToBit`, both segments are used.
* The loader mirrors the registry's alias errors; `opts.replace` reports a key that is not a TOC file.
* Still open from A.6.1: `--skip` / `--keep` / `--own` on the command lines, the skip set of `Mock.loadAddon`,
  the harness on a mixed module, the lint rule for `tools/overrides/*.lua`.

## 5. Notes for F1c (report, simulator, build, documentation)

* Simulator (A.6.5): reward choices still come from `step.reward` only (`simulate_routes.lua:413`, `:452`), so
  the fixture's class reward table is exercised by `core_automation_spec` but not yet by the simulator.
* `docs/VALIDATION.md` is stale (95 / 145 WARN, 1,713 / 1,748 steps).
* `simulate_routes.lua --fixtures` now also finds `FastesBoooy_TestGuides` (three more simulations).
* To document (`docs/ROUTE_FORMAT.md`, `docs/ARCHITECTURE.md`, `tools/README.md`): `AddLibraryInsert` with
  rules 1-10 and its error table; the quirk; forward references (an insert listed before the insert that
  supplies its anchor is applied as soon as the anchor exists, before every later insert: the order at one
  anchor is always "shared in registration order, then the route's own in call order", and the existing
  sentences of `ROUTE_FORMAT.md` about the call order and `<anchor>+<n>` now hold in that case too); the
  obsolete-modules line needs `FastesBoooy_Guides`; `ok`; `aliases` (three errors); the class reward table (a second
  `AddLibraryData` call with the same class key replaces the first **before** a route is composed; data merged
  into an already composed route is fill-only, as for every data kind); the guard line; `API_MINOR = 2`;
  `/fb routes all`; `Registry:List(true)` / `IsComposed`; loader `opts.replace`, `mod.libraryInserts`,
  `mod.aliases`; an empty all-pruned segment is left out.

## 6. Facts for later phases and for the atlas (docs/dev/ATLAS.md)

* Routes are not assumed to be the only content of a data module: the loader and the core accept a module that
  registers shared content only, routes only, or both; `AddLibraryData` merges any kind per kind and key, and
  the class reward table is the first kind the engine reads besides names and quest meta. Atlas data can use
  the same merge or its own registration call next to it.
* `Registry:List(true)` gives id, title, description, races, classes and levels of all guides without composing
  one: enough for a "guides" tab that lists the 28 guides.
* The settings panel has room for three route buttons; with one matching guide per character that is enough,
  and the full list lives in `/fb routes all` until the atlas window exists.
* Class files carry structured per-class facts (trainer ids and places, class quest chains, reward choices):
  the reward table is data, not step text, and can be shown by a "Classes" section later.

## 7. Open issues for the orchestrator

* None that blocks F1b. The stale `docs/VALIDATION.md` and the simulator's reward check are F1c work as planned.

## 8. Verification round 1

Six findings of the independent verification (two of them the same). All were real; none was rejected.

| # | Finding | Verdict | Change |
|---|---|---|---|
| 1, 6 | No spec for the composition-time id collision between a shared-insert step and a route's own step / per-route insert step (A.5.1 error table), nor for the wording "shared insert ..." of `kindOf` | real (the behaviour was correct, the spec was missing) | new case in `core_shared_insert_spec.lua` ("an id that a route's own step or per-route insert step also has"): two routes with an own step `dup-own` and a per-route insert step `dup-ins`, a shared insert with both ids; asserts the two exact messages ("segment <id>-own and shared insert after 'd-1'", "shared insert after 'd-1' and insert after 'd-1'"), that the insert is accepted at registration, that all steps stay in the route and `stepById` is the first, once per route, not repeated on recomposition, and no error in a route without those ids |
| 2 | No spec for "a second call with the same class key replaces the first" (A.5.4) | real (spec missing) | new case in `core_automation_spec.lua`: two `AddLibraryData{ rewards = { PALADIN = ... } }` calls before composition: `GetRewardChoice` reads the second table, a key of the first only is gone, the other class key stays, the reward window takes the choice. The same case pins what section 5 documents: data that arrives after the route was composed is fill-only (the class table in use stays, a new class key is merged) |
| 3 | The own-step anchor of a shared insert in a route **with** `UseSegments` (A.5.1 rule 5) was not exercised | real (spec missing) | new case in `core_shared_insert_spec.lua`: an own segment before the shared one, and one moved behind it by `UseSegments`, both with an own step `own-1`; shared inserts `after` / `before` it land in both routes in the anchor's own segment, not in a route without that id; a positional own anchor (`own:2`) is applied and reports the positional-anchor error once |
| 4 | Rule 4 order was broken by a forward reference: a shared insert registered before the insert that supplies its anchor landed behind later-registered shared inserts at that anchor and behind the route's own `AddInsert` steps | real, a defect in `Compose.Build` | fixed in `Core/Compose.lua`: the multi-pass loop is replaced by one ordered scan (shared inserts in registration order, then the route's own). An insert whose anchor does not exist yet waits; when a step with that id is placed the scan restarts at the top, so the waiting insert is applied before every later one. Consequences: at one anchor the order is always the list order (also for the route's own inserts and their `<anchor>+<n>` ids, and a shared insert anchored on a step of a per-route insert goes before the route's own inserts at that step); without a forward reference nothing changes. The quirk of rule 8 is unchanged. Header comment updated. New case in `core_shared_insert_spec.lua` ("a forward reference keeps the order at the anchor"), `after` and `before`. Evidence: the composed step ids and segments of the two old routes and of four fixtures are byte-identical before and after; a scratch fuzz (4,000 random sets of shared and own inserts, 2,697 with forward references) matches an independent model "always apply the first insert of the list whose anchor exists" in every case, and the old multi-pass algorithm in all 1,303 cases without a forward reference |
| 5 | The obsolete-modules chat line fired whenever an old module was loaded, also without `FastesBoooy_Guides` (all of F1; later a core updated on its own) | real | `UI/Options.lua`: `Options:ObsoleteModules()` returns the old modules only when `Compat.IsAddOnLoaded("FastesBoooy_Guides")`; the line is printed under the same condition. `core_ui_spec.lua`: the two cases register `FastesBoooy_Guides`, a third asserts silence with the old modules alone and with a disabled `FastesBoooy_Guides` folder. Deviation 4 above is rewritten |

Not changed: the plan (`docs/dev/PLAN.md` is not owned by this phase). Two of its sentences are now narrower or
wider than the code: A.5.6 (the line also needs `FastesBoooy_Guides`) and A.5.1 rule 4 (now also true with
forward references). F1b may still add a module check for a shared insert anchored on a step of a
later-registered insert if the authors should avoid it; the core no longer needs it.

Acceptance after the round:

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 146 files |
| `busted` | 526 successes / 0 failures / 0 errors, 76.8 s |
| `make validate` | exit 0; `horde-undead-paladin` 0 ERROR, 95 WARN, 381 INFO, grind 4,972 / 6,179, end level 60.00; `horde-skyborne-druid` 0 ERROR, 145 WARN, 386 INFO, grind 4,878 / 6,082, end level 60.00; no `step-no-profile` |
| composed steps | 1,713 and 1,748 |
| `make validate-fixtures`, `simulate-fixtures`, `harness-fixtures`, `routedata-check` | each exit 0 (fixture simulations 5 of 5; all `Data.lua` up to date) |
| `make simulate` (not required) | 2 of 2 passed, 1,713 / 1,748 steps, 51 s |
| `git status --short addons/FastesBoooy_*` | prints nothing |

`make simulate-sync` was not repeated: the composed routes are byte-identical and the only other change is the
condition of one chat line.
