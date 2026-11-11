# Hand-over F2e: orchestrator fixes after F1 / F2

Phase F2e (added during execution, `docs/dev/PLAN.md` D.2 "F2e"): resolve what the hand-overs F1a .. F2d passed to
the orchestrator, so that P1 (Durotar, Mulgore), P2 and phase C start from a clean base. Nothing was committed and
no git command that changes state was run (the orchestrator commits; `git add -A addons docs tests tools README.md`
takes everything of this phase, including the two deleted fixture files). The orchestrator's checkpoint commit
`6097d2d` ("WIP: level-sync fix ...") holds the first part of item 1 and item 3 from the interrupted first attempt;
this phase reviewed that work and builds on it.

`G` = `addons/FastesBoooy_Guides`.

## 1. The items, what was found, what changed

### 1. `--ahead 48` fails for every base route (F2c hand-overs, F2d open issue 2)

**Cause (core, not the simulator).** `simulate_routes.lua --route undead-warrior --ahead 48` jumps from `ud-01` to
`h-46-tanaris-feralas` at level 48 and plays to 60. 1424 "Pool of Tears" (level 43, `h-44`) is never taken. On the
cold start at 60 the natural cursor stopped on the accept of 1424 although `h-60-end` was done: the gray accept was
"protected" (`Engine:ComputeVoid`, `protected`), because the chain 1424 > 1429 > 1444 leads to 1445 "The Temple of
Atal'Hakkar" (level 50, **not** gray at 60), whose accept in `h-50` is `optional`. The finished route lies behind
the forward limit, so that optional accept is "not taken" -- the player passed it -- yet it still kept the whole
chain alive. The class routes passed only by accident: `Engine:ComputeSyncSuggestion` found class steps behind
`h-60-end` (`pal-60-hearth`, `dru-train-60`) and the simulator applied the jump. The simulator's check ("a cold
start must not put the cursor before the last done stateful step") is right and was not changed.

**Fix** (`addons/FastesBoooy/Core/Engine.lua`, from the first attempt, reviewed and kept): a dependent protects its
prerequisite only while the route still leads to it (`wanted(d)`): at least one accept of the dependent is not passed
without the game (not marked, not below the sync floor, not an `optional` non-bg step before the forward limit, not
given up; the pending `QUEST_REMOVED` hold counts as not given up, as in the main loop). A quest the player passed or
declined keeps no chain alive. During normal play nothing changes: the optional accept of 1445 lies ahead of the
forward limit and keeps protecting the chain. Header comment of the engine and `docs/ARCHITECTURE.md` ("Синхронизация
по уровню, серые и недоступные квесты") describe the rule.

Review of the first attempt: the logic mirrors the `stepVoid` condition of the main loop exactly (same `limit`,
`floorIndex`, `isMarked`, `givenUp` / `removed` rule), costs one loop over the accepts of a dependent per memoized
`protected` call, and the dependency graph stays acyclic. Nothing to rewrite.

**Specs.** `tests/spec/core_sync_spec.lua`, describe "protection ends with the quest the chain leads to" (3 cases, the
shape of the real chain on a synthetic route): a finished route is finished on a cold start in `levelSync`
"off" / "ask" / "auto"; the chain stays while the optional quest is ahead, goes when the player skips the optional
accept, and comes back after `Reset`; a chain quest taken by hand is never skipped. Mutation check: with the engine
of `b6f7927` the three cases fail (3 failures), with the fix they pass.

**Result.** `lua5.1 tools/simulate_routes.lua --route undead-warrior,skyborne-shaman --ahead 48 $G`: 2 of 2 `OK`,
"cold start: finished" (17 s). The full matrix: section 2.

### 2. PLAN.md C.7 and the level-40 anchor (F2d deviation 1, open issue 1)

`docs/dev/PLAN.md` now says what the code and the layout spec require:

* **C.7**: the druid file has two level-40 inserts (`dru-40-fly-tb`, `dru-40-train` after `h-40-org-arrive`;
  `dru-40-fly-taurajo` alone `before = "h-38-orgrimmar-flight-master"`, and no other druid insert may stand in front
  of it there); the druid riding insert of a race file is `after = "h-40-org-arrive"`, `class = "DRUID"`; the
  composed order; why not `dru-40-train` (the base-profile command fails with `insert-anchor-unknown`).
* **C.3 rule 6**: no insert anchors on a step of another file's insert (C.7 needs none any more).
* **C.2**: for Tirisfal and Zephras the binding anchor lists are the F2c hand-overs and the `ANCHORS` table of the
  layout spec (five Tirisfal rows of the plan differ from the tree: F2c-Tirisfal open issue 3).
* **D.4 step 3** (P2): the Tauren druid riding insert `after = "h-40-org-arrive"`, `class = "DRUID"`, ids
  `tau-40d-...`; `h15-xr-arrive` gets `ok = "db-override-unverified"` with the first Tauren route (F2b open issue 2).
* **D.5** (druid row): keep the two level-40 inserts apart. **D.6 step 2**: the cross-file check no longer names
  `dru-40-train`.
* Hand-over instructions for phase C: `f2c-zephras.md` section 6 (riding note for phase C) carries the correction.
  The F2d hand-over already had the new wording; the F2b mentions are history (records of what F2b did) and stay.

Further "as executed" notes for points the hand-overs said "can be aligned": status line; A.5.1 rule 4 (forward
references, F1a), A.5.1 error table (empty scope list, item 8), A.5.4 (shape check, item 8), A.5.6 (the obsolete
line needs `FastesBoooy_Guides`, F1a), A.6.2 (override order `shared.lua` first; load errors with `--route`, F1b
deviations 7 and 17), D.1 row F1b ("18 and 18 WARN", F1b open issue 1), D.2 F2a step 5 (13 of 17 ceilings, F2a open
issue 3), E.6 (the engine spec), and a new subsection D.2 "F2e" for this phase.

### 3. 98389, the engine / simulator scenario (F2c-Tirisfal, F2d deviation 6)

`tests/spec/guides_engine_spec.lua` (new in the first attempt, kept and changed): the real guides module in the mock
client, loaded with the file filter of the tools (`Mock.loadAddon` `skip`: the other start zones, the race files but
`Races/Scourge.lua` and the class files but `Classes/Paladin.lua` are left out, so a half-written file of a parallel
phase does not turn it red). Six cases: the three steps are optional and name only 98389; **not offered** (warrior):
the accept is shown once, then never one of its steps, nothing is marked (no Skip, no Next), also after `/reload` and
after a cold start with empty SavedVariables, also with a cold start in the middle of the zone; **offered**: a class
without class steps walks all three; the paladin walks all three; not offered to a paladin either.

Changed against the first attempt: the two paladin cases no longer pin the layout of `Classes/Paladin.lua` (which
`pal-tir-*` steps stand between the accept and Saltain): the paladin agent of phase C owns that file and may not edit
`tests/**`. They assert only the three generic steps and their order. Mutation checks on a scratch copy: `ud01-cocoons`
mandatory -> 1 failure; `ud01-aramis` mandatory -> 4 failures.

The simulator cannot play "not offered": it takes every quest a step names (that is its contract), and the validator
does not model offers. Nothing to change there; the spec is the scenario.

### 4. Faction-word matcher of the layout spec

Found: the matcher of the step notes was already case-insensitive in `b6f7927` (`lowerRu`, Cyrillic case forms,
"ордын-" adjectives, a pinning case for any letter case). What was still case-sensitive: the route title /
description check of `assertRoutes` (plain `find` of "Horde" / "Орд" / "library" / "shared") and `moduleWord` (the
"shared" / "общий путь" check of notes and segment titles). Changed in `tests/spec/guides_layout_spec.lua`:

* `moduleWord` works on `lowerRu(text)`, with every case form of "общий путь" / "общий маршрут" (+ dative and
  instrumental). "library" / "библиотек" stay a title-only check: a note may name a game place ("в библиотеке
  перед Аругалом", `h22-sfk-book`) -- found by the first run of the widened matcher.
* `assertRoutes` uses `factionWord` and `moduleWord` (any case) plus a case-insensitive "library" / "библиотек".
* The pinning case got ten more forms (mixed case "оРдА", «ОрДы», a digit or hyphen in front, "Ордынская",
  "Horde's", "pro-hOrDe"; negatives "Ёорда", "шорды", "хорды", "Мордор", "Гордеев", "Кордон"); a new case pins
  `moduleWord`.

### 5. Unused fixture files (F2d deviation 4, open issue 3)

Deleted: `tests/fixtures/guides/FastesBoooy_StartZones/Segments/Tirisfal/02_Tirisfal.lua` and
`.../Zephras/03_ThunderBluff.lua` (and their now empty directories). Checked with grep over `tests`, `tools`,
`Makefile`, `.github`: nothing names them; the 28-route case replaces only Durotar and Mulgore files.

### 6. Stale documentation and usage texts (F2a open issues 2 and 5, F2b open issue 4, F2d open issue 4)

* `docs/ARCHITECTURE.md`: the tree shows `FastesBoooy_Guides` (Data, start zones, `Segments/Shared`, `Classes`,
  `Races`, `Route.lua`); the old modules are named once, as what it replaced; the shared-content paragraph describes
  both forms (the module registers its own shared content, or a library module as dependency: the fixtures); the
  gray-quest rule has the new "the route still leads to it" condition.
* `docs/ROUTE_FORMAT.md`: route example `id = "undead-paladin"`, `aliases = { "horde-undead-paladin" }`; the alias
  example names both renames; the `AddSegment` example uses a generic `my-route` and says that Guides routes own no
  segment; the library-module section uses `FastesBoooy_MyLib` and says when a separate library module is still
  useful; id conventions (`h…` for the shared path, zone prefixes); `[library <модуль>]`; the error table and the
  reward-table rules of item 8.
* `tools/README.md`: `VALIDATE_FLAGS`, `SYNC_ROUTES`, `SYNC_MID`, `LIB` as in the Makefile; the timing paragraph is
  marked as the F1 measurement; the harness section, the `--write-state` example (`--route undead-paladin`, no
  `--profile`; current numbers: 22 + 0.04 / 179 done and 22 + 0.44 / 190 done, hearth Thunder Bluff), `harness-Guides`,
  `--ahead-at h-15-barrens`, the sync line example (`ud-01-deathknell -> h-18-stonetalon-ashenvale`, measured), and a
  sentence on "cold start: finished".
* Usage texts and comments: `tools/lib/validator.lua` (`--help` harness example: `--route undead-paladin`,
  `--harness addons/FastesBoooy_Guides`; run as printed: exit 0, end state of `harness-Guides` at 25 + 0.10),
  `tools/lib/harness.lua`, `tools/lib/route_loader.lua`, `tools/simulate_routes.lua` (comments).
* Kept on purpose: `addons/FastesBoooy/UI/Options.lua` and `tests/spec/core_ui_spec.lua` (the obsolete-modules
  warning), the aliases in `core_sync_spec.lua` / the layout spec, the history in `docs/routes/shared-path.md` §11.

### 7. `docs/routes` and README

* `class-druid.md`: sub-headings "4.1. 10–22", "4.2. 23–60" (en dash like 2.1 / 2.2) and "5.1. Торва Следопыт" (the
  one unnumbered sub-heading); the Torwa paragraph had the numbers of the old route (gate 289 vs 332, whole route
  5,180 / 6,370 vs 5,223 / 6,413): now the gate `h55-silithus-field-grind` 319 / 349 against 362 / 369 of the base
  Skyborne profile, the segment 319 / 349 against 362 / 392, and "whole route: table §1"; the 12-row of the training
  table also gives the plateau step's level (13.32 / 13.26).
* `class-paladin.md`: the 24-row of the 22-60 training table had a level (24.89) that matches no step: now "in
  `h-22` (22.04 → 25.10)"; "с ~12 уровня" -> "примерно с 12-го уровня".
* Every other number in the narrative of both class documents was compared with `--levels` of `skyborne-druid` /
  `undead-paladin` (and of `skyborne-shaman` / `undead-warrior` for the base columns) by a scratch script: no other
  contradiction (the remaining hits are coordinates, DPS values and table cells that name two steps).
* Plural forms after numerals (scratch checker over the three documents and README): `shared-path.md` "21 явных id"
  -> "21 явный id", "31 явных id" -> "31 явный id"; the rest ("из 24 шагов", "2 сильнейших лечебных зелья", "51 очко",
  "1 754 шага", ...) is correct.
* `README.md`, "Обновление с 0.3": a table old id -> new id (`horde-undead-paladin` -> `undead-paladin`,
  `horde-skyborne-druid` -> `skyborne-druid`, from `Route.lua`), what moves to the new id (manual choice, high-water
  mark, sync floor), that the other nine guides are new, and -- F2a open issue 6 -- that the move happens only once
  the old folders are deleted (while they are installed the old module holds the old id and the alias is ignored).

### 8. Core checks left open by F1a

* **Empty scope list.** `class = {}` / `race = {}` was read as "no filter" (a shared insert with `class = {}` landed
  in every route). Now `Schema.NormalizeFilters` reports "class is an empty list: ..." (also for a step's own key,
  also `{ [2] = "MAGE" }`), and `Compose.AddLibraryInsert` rejects such an insert as a whole ("the insert is
  rejected: an empty scope list would apply it to every route"; its ids stay free).
* **Shape of the class reward table.** New `Schema.CheckData(data, where, errors)`: `rewards` must be a table, each
  key a class token of `Schema.CLASSES`, each value a table, each key a quest id, each index a positive integer.
  Called by `Registry:AddLibraryData`, `Registry:AddRouteData` (once, before the queue; `RegisterRoute` merges
  queued data directly) and by the loader's `api.AddLibraryData` / `api.AddRouteData` (an ERROR of the file in the
  tools). Messages are in a fixed key order.
  The data is still merged as given; the engine ignores a bad entry as before.
* Specs: `core_schema_spec.lua` (+2 cases: empty lists on a step and on a shared insert, rejection, ids stay free;
  `CheckData` with every error kind), `core_automation_spec.lua` (the invalid-entries case asserts the three
  registry errors), `validator_guides_spec.lua` (the loader reports both with the file `Ins.lua`; the rejected
  insert is in no route). The real module and all fixtures report nothing new (validator: 0 ERROR as before).

### 9. busted took 6 minutes (found while running the acceptance)

`tests/spec/core_simulate_spec.lua`: see section 2, "busted wall time". Also `tests/spec/validator_overrides_spec.lua`:
its comment "no spec may depend on tools/overrides" now names the one explicit exception (the harness proofs of the
layout spec, F2b open issue 3).

### Other open issues of the hand-overs, checked

| Hand-over item | State |
|---|---|
| F1b: plan text 19 -> 18 WARN, override order, `--route` load errors | aligned (item 2): D.1 row F1b and review-log entry ET-10 (verification round 1) |
| F1b: module check for an insert anchored on a later-registered insert | not needed (core handles forward references); unchanged |
| F1c: plan differs in report / Makefile / CI details (deviations 1, 5, 6, 8) | descriptive only, no later phase depends on them; left |
| F1c: busted budget 1.3 min in A.7 | measured now: section 2 (busted is the longest stage) |
| F2a 1 (TOC edit by F2b), 4 | done in F2b |
| F2a 2, 5 (stale comments, usage texts) | item 6 |
| F2a 6 (old folders left in place) | README (item 7); the core rule "a route id wins over an alias" stays |
| F2b 1 (staged deletions) | committed long ago |
| F2b 2 (`h15-xr-arrive` `ok` with the first Tauren route) | PLAN.md D.4 step 3; the layout spec enforces it |
| F2b 3 (the layout spec reads `tools/overrides`) | the comment of `validator_overrides_spec.lua` names the exception and the P2 option |
| F2b 5 (base-profile `insert-anchor-unknown`) | solved by F2d; plan aligned (item 2) |
| F2c-Tirisfal 3 (C.2 table) | C.2 note (item 2) |
| F2c 98389 in game, 94489, Zephras trainer-hub gates | in-game / P2 questions, unchanged (`-- CONFIRM`) |
| F2d 5 (README per phase) | for P1 / P2 / C, unchanged |

## 2. Acceptance: commands run and results

All on the final tree (4 CPUs; nothing else running unless said).

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 175 files |
| `busted` | **718 successes** / 0 failures / 0 errors, 70.5 s (inside the second `make check`). 704 in the F2d hand-over, 706 at `b6f7927` (the layout spec has 34 cases there, not 32); + 3 `core_sync_spec`, + 6 `guides_engine_spec`, + 2 `core_schema_spec`, + 1 layout spec (module words) |
| `make check` | **exit 0, 246 s wall** (second run, after the busted fix below; the first run, before it, also exit 0 in 516 s): lint 0 / 0; busted 718 / 0 / 0; `make validate` 0 ERROR, 0 WARN, 188 accepted (strict); `validate-fixtures` 7 modules 0 errors; `make simulate` 11 of 11 routes passed; `make simulate-sync` 16 of 16 runs passed; fixture simulations 5 of 5; harness fixture 4 runs pass. Simulator warnings: only the three known ones (`sd02-hearth` bind point, optional `sky-1061` at 12, `h-53-azshara-ungoro-silithus:41` in the `--level-plus 4` runs) |
| `make routedata-check` | exit 0 (`G/Data.lua` and the five fixture files up to date) |
| `make report`, then `git status docs/VALIDATION.md` | "report: docs/VALIDATION.md written"; **no diff** (run twice: after the first and after the second `make check`) |
| `make simulate-sync-full` | **exit 0: 88 runs (11 routes x 8), all passed, 413 s wall** (6 min 53 s, 4 at a time). `--ahead 48`: the nine base routes "cold start: finished", `undead-paladin` and `skyborne-druid` "cold start resumes at step 1753/1754" / "1784/1784" (their transient class steps behind `h-60-end`). Warnings: only the three known ones (11 x `h-53-...:41`, 20 x `sd02-hearth`, 10 x `sky-1061`) |
| the validator commands of F2d: `validate_routes.lua -q --strict --end-level --max-grind-until h-18-stonetalon-ashenvale=120/200 $G`; the base-profile command `--route 'undead-*,skyborne-*' --skip 'Classes/*'` | exit 0 / exit 0: 0 ERROR, 0 WARN, 188 / 186 accepted; numbers unchanged (the core changes move no level and no kill) |
| layout spec with the P1 / phase C environment lines (`GUIDES_SKIP` / `GUIDES_KEEP` / `GUIDES_OWN` of D.3, D.5) | 22 successes each |

**busted wall time.** The first `make check` showed busted at 350 s (1.7 min in F1c). One case made up 288 s of it:
`core_simulate_spec.lua` "plays the core test route to the end" ran `simulate_routes.lua --fixtures`, and
`--fixtures` also loads the real modules of `addons/`: it simulated all 11 Guides routes one after the other (26 s
each; with 28 routes it would have been 12 min). The case now passes `--route 'test-*'` (the routes it asserts;
`make simulate` plays the real routes): the file takes 5 s, busted 70 s.

## 3. Deviations from the plan, and why

1. **A phase that is not in revision 2.** F2e was added by the orchestrator between F2d and P1; D.2 now describes it.
2. **The core changes outside phase F1** (`Engine.lua`, `Schema.lua`, `Compose.lua`, `Registry.lua`, the loader):
   the plan has no core phase after F1; the defects were the core's (D.0 rule 6: the orchestrator fixes them).
3. **`guides_engine_spec.lua` is a new spec file**, not a case of `core_sync_spec.lua`: it needs the file filter
   and its own client builder; the core_sync cases stay synthetic.
4. **"library" is not a forbidden word in step notes** (item 4): the widened matcher found an in-world use.
5. **Hand-over files of earlier phases**: only `f2c-zephras.md` got a correction (an instruction for phase C);
   the other hand-overs are records and stay as written.

## 4. Notes for the next phases

* P1 / P2 / C: the engine now keeps a finished route finished on a cold start; `make simulate-sync-full` runs every
  route, so a new route that fails it is a real defect (report it, D.0 rule 6).
* P2: C.7 / D.4 step 3 for `Races/Tauren.lua`; `SYNC_ROUTES` of A.7 (the nightly run covers the rest).
* Phase C (paladin): `tests/spec/guides_engine_spec.lua` loads `Classes/Paladin.lua`; it asserts only the three
  generic 98389 steps, not the paladin's own steps, but a paladin file that does not load fails it.
* Phase C (every class): `AddLibraryData({ rewards = ... })` with a bad shape and an insert with `class = {}` are
  now load errors (ERROR in the validator).
* Phase R: the numbers in `docs/routes/*.md` are still a snapshot of F2d (only the contradictions above were fixed).

## 5. Open issues for the orchestrator

1. **Commit.** Everything of this phase is uncommitted on top of the checkpoint `6097d2d` (which holds item 1's
   engine change and the first version of `guides_engine_spec.lua`); the two fixture deletions are working-tree
   deletions. The tree passes `make check`, `make routedata-check` and the report freshness check: it can be pushed.
2. **CI budget.** With the busted fix the CI estimate of A.7 holds again (busted 70 s); `make check` 4.1 min on 4
   CPUs. `make simulate-sync-full` 6.9 min for 11 routes (nightly); with 28 routes about 18 min as A.7 says.
3. **In-game questions, unchanged** (`-- CONFIRM`): 98389 offered to every class? (`ud01-aramis`), 94489 for
   non-healers (`sd02-wounded`), paladin trainers in the Undercity / Thunder Bluff, the riding questions. The
   engine handles every answer (item 3), so none of them blocks a phase.
4. **Decisions left to P2 by earlier hand-overs, unchanged**: the two Zephras trainer-hub gates, `h13-lvl-14` for
   the Undead, `ok = "segment-level"` on `h-22-hillsbrad` (review with all five races), `SYNC_ROUTES` final list.
5. Nothing blocks P1.
