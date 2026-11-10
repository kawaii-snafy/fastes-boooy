# Hand-over F1c: report, simulator, build, format documentation

Phase F1c of `docs/dev/PLAN.md` (A.6.4, A.6.5, A.7, D.1 row F1c). Nothing was committed (the orchestrator
commits). This is the last part of F1: `docs/VALIDATION.md` is regenerated, `make check`,
`make routedata-check` and the report freshness step pass, so this state can be pushed (D.0 rule 2).

## 1. What changed

### Tools

| File | Change |
|---|---|
| new `tools/lib/report.lua` | the Markdown report in the layout of A.6.4 (`Report.Markdown(V, all, db)`; helpers `Report.MergeTexts`, `Report.RouteSet`, `Report.Range`, `Report.OnSharedPath`) |
| `tools/lib/validator.lua` | `V.FormatMarkdown` delegates to `lib/report.lua` (the old per-route writer and `V.GrindMarkdown` are gone); new stable fields: message `inserted = true` (a step of an insert, `AddInsert` or `AddLibraryInsert`; also on `ok-unused` and the route-level checks), gate `inserted` and `okCeiling` (the number of `ok = { ["level-grind"] = N }` of the gate's step), segment summary `library` (a shared segment). Header comment. No check, count or text of the text / JSON output changed |
| `tools/simulate_routes.lua` | `--list-routes`; the expected reward choice is resolved like `Engine:GetRewardChoice` (a step `reward` of the profile's steps: the step that turns the quest in, else the first that names it; then `route.data.rewards[class][quest]`), the mock quest gets the choices and the chosen index is asserted; `-v` prints `reward choice N of quest Q (class table CLASS \| step ID)`, the `OK` line ends its level part with `, N reward choice(s) checked` when N > 0 |
| `Makefile` | `JOBS`, `SIM`, `RUN_JOBS`, `ROUTE`, `SYNC_ROUTES`; parallel `simulate`, `simulate-sync`; new `simulate-sync-full`, `check-fast`, `route`; comments for `VALIDATE_FLAGS`; `help` range. Round 1 (section 6): `RUN_JOB` (job output in one block under a lock), `REPORT` and a `make report` that fails when no report was written |
| `.github/workflows/ci.yml` | one job, `timeout-minutes: 25`, the stages of `make check` as separate steps, then the two freshness steps and packaging |
| new `.github/workflows/nightly.yml` | `schedule` (03:17 UTC) + `workflow_dispatch`: `make simulate-sync-full`, `timeout-minutes: 60` |
| `tools/gen_route_data.lua` | not touched: the two items of A.6.5 were done in F1a (hand-over F1a, deviation 1); `PLACE_NAMES_RU` needs no entry in F1 (no new place; `make routedata-check` is green) |

### Report layout (`make report`, `docs/VALIDATION.md`)

1. header, totals, "rows without repeats" (how many ERROR / WARN rows are left once the shared path is shown once);
2. "Модули и общие проверки": the entries that are not runs (library module, `(shared <Module>)` template
   checks, `(overrides)`, load errors) and the notes;
3. "Сводка по маршрутам": one row per route x profile (ERROR, WARN, accepted, end level normal / worst, grind
   normal / worst, the same with 15 % incidental kills, estimated-XP quests and their share, max quest log,
   steps, optional steps);
4. "Сравнение путей": the common tail of all routes (longest common suffix of the segment chains), one row per
   start chain (level at the merge point, grind kills up to it, min-max over its routes), then every segment
   with its routes, entry / end level and grind kills normal / worst (min-max);
5. "Общие шаги": every ERROR / WARN on a step of a shared segment once, key `(severity, code, step id or
   segment, quest id)` plus the n-th occurrence in a run, a "routes" column (`все 28`, `все 7 troll-*`, `все 5
   *-warrior`, else up to three ids and a count), the texts of the routes merged number by number into ranges;
   accepted warnings in a collapsed table of the same shape;
6. "Пороги уровня на общих шагах": gate matrix (gate, step, routes, kills min / max, worst case max, `ok` ceiling);
7. "Маршруты": per run its result line (with the part that is on shared steps), the simulation and grind
   sentences, the route's own gates, a compact segment table, its own ERROR / WARN, its own accepted warnings
   (collapsed), INFO as counts per code;
8. "INFO по кодам": counts per code over the run;
9. "Что подтверждается только в игре" + the generated list of accepted `db-override-unverified` warnings.

Size now: 248 lines, 29 KB (before: 1,188 lines, 252 KB) for the two old routes.

### Documentation (Russian, as the files were)

| File | Change |
|---|---|
| `docs/ROUTE_FORMAT.md` | route `aliases` (three errors); segment and step key `ok` (three forms, ceiling, `ok-needs-ceiling`, `ok-unused`, `db-override-unverified` + `-- CONFIRM`); `reward` versus the class reward table; filters in shared steps (rule 9); new sections "Общие вставки: `AddLibraryInsert`" (rules 1-10 with the plan's numbers, the error table, forward references, the quirk), "Таблица наград по классам", "Модуль с общим содержимым и маршрутами" (TOC order, the guard line, `ns`); "Версия ядра" with the version table and the guard line; data and validation paragraphs |
| `docs/ARCHITECTURE.md` | tree (overrides; the Guides module as the target); core table (Compose, Compat, Registry, Engine, Options); shared inserts, pruning by route scope, the non-composing route list, aliases, library data and the reward table; automation; the checks table |
| `tools/README.md` | file table (new libs, overrides); make targets with measured times; lint table; generator on a mixed module; validator options in groups, exit status, commands for parallel work, template checks, overrides, `ok`, numeric criteria; code table (15 new codes, `xp-unknown` INFO, `train-service`); output (notes, foreign block, module entry, JSON fields); new subsection on the report layout; specs; harness on a mixed module; new sections 9 (simulator: `--list-routes`, selection, file filter, rewards) and 10 (CI) |

### Specs (45 new cases; 663 in all; 53 and 671 after verification round 1, section 6)

| Spec | Cases | What |
|---|---:|---|
| new `validator_report_spec.lua` | 20 | helpers; every section on hand-made results (key of the shared rows, two equal keys in one run, accepted apart, a gate accepted in one route and above its ceiling in others, unmergeable texts, gate matrix, own messages, INFO counts only, accepted `db-override-unverified`, two profiles, no common tail, one route, no module); a temporary module of the Guides shape through the real validator and the command line (fields `inserted`, `okCeiling`, `library`; JSON and text stay complete; deterministic); the fixtures |
| new `build_spec.lua` | 16 (24 after round 1) | `make simulate` / `simulate-sync` / `simulate-sync-full` with a fake simulator (`SIM=...`): job list, parallelism (jobs that must overlap pass with `JOBS=2`, fail with `JOBS=1`), failing `--list-routes`, empty list, failing job; `make route`, `make check-fast`; `SYNC_ROUTES` / `SYNC_MID` / `ROUTE` name routes and segments that exist; `make help`; `ci.yml` runs every prerequisite of `check`, has the 25 minute limit and both freshness checks; `nightly.yml` |
| `validator_guides_spec.lua` | +9 | simulator rewards (class table per class; a step `reward` wins; two copies of the core whose engine ignores the table / takes another index make the simulation fail); `--list-routes` (order, several modules, addons and `--fixtures`, `--route`, file filter, a module with load errors: exit 1 and empty stdout, no TOC, no simulation options) |
| `validator_gates_spec.lua` | 1 line | the "no WARN row" assertion looks for a row start (the summary table header contains `\| WARN \|`) |
| `validator_overrides_spec.lua` | 1 condition | the Makefile scan also counts recipes that run the simulator as `$(SIM)` |

## 2. Acceptance: commands run and results

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 154 files |
| `busted` | 663 successes / 0 failures / 0 errors (618 before F1c), 101-105 s |
| `lua5.1 tools/simulate_routes.lua --list-routes` | exit 0; prints `horde-skyborne-druid`, `horde-undead-paladin` |
| `make simulate` | "simulate: 2 route(s), 4 at a time", both `OK` (1,748 and 1,713 steps; the druid: 13 reward choices checked), "simulate: all routes passed"; 29 s wall, 55 s CPU (52 s wall before, one process) |
| `make simulate` with a module that does not load (scratch copy of the tree with a `FastesBoooy_Broken` module) | the load error, "simulate: --list-routes failed: nothing simulated", make exit 2, 0.2 s |
| `make simulate` with a fake simulator (`build_spec.lua`) | list failure, empty list and a failing job each fail the target; `JOBS=1` runs one at a time |
| `make simulate-sync` | 16 runs, 16 passed; 82 s wall, 302 s CPU (5 min 14 s wall before) |
| `make check` | exit 0, run twice: **3 min 41 s** and **3 min 37 s** wall (4 CPUs; 7 min 31-34 s CPU): lint, 663 specs in 103-105 s, 2 + 16 route simulations, 5 fixture simulations, 4 harness runs. About 7 min before F1c (measured in F1a: simulate 52 s + simulate-sync 5 min 14 s + busted 77 s) |
| `make check-fast` | exit 0, 31 s |
| `make route ROUTE=horde-skyborne-druid` | exit 0, 27 s |
| `make routedata-check` | exit 0; the three old `Data.lua` and the five fixture files are up to date |
| `make report`, then `git diff --stat docs/VALIDATION.md` after a second run | regenerated; the second run changes nothing (deterministic) |
| `make validate` | exit 0; `horde-skyborne-druid` 0 ERROR, 18 WARN, 513 INFO; `horde-undead-paladin` 0 ERROR, 18 WARN, 458 INFO (as after F1b) |
| `lua5.1 tools/validate_routes.lua -q --summary --end-level --grind-until h-22-hillsbrad` | exit 0; `horde-skyborne-druid ... 60.00 60.00 4878 6082 0 97`, `horde-undead-paladin ... 60.00 60.00 4972 6179 75 160` (unchanged) |
| `make package` | exit 0 |
| `git status --short addons/` | prints nothing |

## 3. Deviations from the plan, and why

1. **Report: what "shared" means.** Section 5 holds the messages on steps of shared **segments** (and the
   segments themselves): `m.shared and not m.inserted`. Messages on steps of shared **inserts** (class and race
   files) are in the route sections, as A.6.4 item 6 says ("the route's own (class / race) messages"), although
   the validator marks them `shared` too. Consequence: a warning on a class or race step is printed in every route
   of that class or race (three to seven times with 28 routes). The gate matrix (item 5) does include the gates of shared
   inserts, with their routes: a matrix row costs nothing and a class gate is still one template.
2. **Report: additions.** A section for the entries that are not runs (template checks, overrides, load
   errors) and the notes; accepted warnings are listed (collapsed) on the shared path and per route; a
   "rows without repeats" line; `(8)` says "none" when there is no accepted `db-override-unverified`.
3. **Ranges come from the texts**, not from the `kills` / `level` fields: the texts of one key are split at
   their numbers and merged slot by slot (`~84–109 same-level kills`), so every run-dependent number of any
   code becomes a range without a table of codes. Texts that differ in more than numbers are not merged: the
   first one is shown with the number of variants.
4. **New result fields** (JSON grows by them): message `inserted`, gate `inserted` / `okCeiling`, segment
   `library`. The report needs them; nothing else reads them.
5. **Makefile.** `LIB` stays `addons/FastesBoooy_Horde` and there is no `GUIDES` variable: the Guides module
   does not exist in F1, and F2a owns `LIB`. `ROUTE` defaults to the wildcard `*undead-paladin`, which selects
   `horde-undead-paladin` now and `undead-paladin` from F2a on without an edit. The recipes print one count
   line before and one "all passed" line after the jobs. `simulate-sync` builds its lines in the shell as in
   `tools.md` 3.4.
6. **CI runs the stages of `make check` as separate steps** (lint; validate + fixtures + harness fixture;
   busted; simulate; simulate-sync), so the log shows the wall time of each, which the "if the runner is
   slower" levers of A.7 need. `build_spec.lua` fails when a prerequisite of `check` is missing in `ci.yml`.
   The comment in `ci.yml` budgets busted at 1.7 min (measured 101-105 s; the plan's 1.3 min predates the
   F1b and F1c specs).
7. **`--list-routes`.** With a broken module it prints no id at all (stdout empty, errors on stderr, exit 1):
   a partial list would let `make simulate` pass with fewer routes. It honours `--fixtures`, `--route` and
   `--skip` / `--keep`, and refuses simulation options (exit 2). A directory without a TOC is an error.
8. **Reward resolution mirrors the engine's order exactly** (the step that turns the quest in, else the
   first step naming it, then the class table), restricted to the steps the profile sees. The plan says "the
   step's `reward` first"; the old simulator only read the `reward` of the turn-in step.
9. **Documentation describes `FastesBoooy_Guides` as the target** (the module does not exist yet); the three
   old modules stay in the trees and examples. Phase R makes the final pass (D.6 step 5). `tools/README.md`
   got new sections 9 and 10 instead of a renumbering (other files refer to "раздел 7" / "Harness").
10. **Specs that read the real `addons/`** (`--list-routes` without directories, the default `ROUTE`,
    `SYNC_ROUTES`) assert the refusal (exit 1, no list) instead of the list when a module under `addons/` does
    not load cleanly: a half-written file of another agent in a parallel phase must not turn `busted` red for
    everybody. Checked in a scratch copy with a broken module: 36 of 36 pass.

## 4. Notes for the next phases

### F2a (owns `Makefile` `SYNC_*`, `LIB`, `VALIDATE_FLAGS`)

* Switch `SYNC_ROUTES`, `SYNC_MID`, `LIB = addons/FastesBoooy_Guides`, `VALIDATE_FLAGS = --strict --end-level`.
  `build_spec.lua` checks the values against the modules: every `SYNC_ROUTES` entry must be a route, and each
  must have one of the segments of every `SYNC_MID` entry. Renaming routes or segments without the Makefile
  fails `busted` with the entry named. `ROUTE` needs no change.
* `make help` prints the header lines 4-37 of the Makefile; keep the range when the header grows.
* The usage text of `make harness` and the comment over `SYNC_ROUTES` name the old module / routes.
* `make report` does not fail on routes with errors (validator exit 1), but fails when the validator wrote no
  report (verification round 1, finding 1); CI then compares the file. `REPORT=<file>` writes elsewhere.
* `build_spec.lua` does not pin `VALIDATE_FLAGS`: the `check-fast` and `route` cases pass their own value
  (verification round 1, finding 2). Changing the variable in the Makefile needs no spec edit.

### Everyone

* One route: `make route ROUTE=<id>` (validator with `VALIDATE_FLAGS`, then the simulator). Fast loop:
  `make check-fast`. Parallel agents still run at most one simulation at a time (D.0 rule 4): do not run
  `make simulate` there, it takes all CPUs.
* A new spec that runs a tool passes `--no-overrides` right after the script name (also `--list-routes`).
* The class reward table is now checked by every simulation: a quest with an entry gets at least two mock
  choices, so a route whose engine does not find the choice fails with "the automation did not turn in
  quest Q", and a wrong index with "turned in with reward choice X, the route wants Y (class table CLASS)".
* Report: a class or race step's warning is in the sections of its routes; search the report for the step id.
  With `--strict` as the gate the unaccepted tables are empty and the accepted lists are the content.

### For the atlas (`docs/dev/ATLAS.md`)

* The report is built from "entries" and "runs": a module entry (`(shared <Module>)`, `(overrides)`) is how
  checks that are not about one route get their own section. Checks on atlas data (a page that names a quest
  or an NPC the DB does not know) can be one more entry without touching the route sections.
* `--list-routes` and the parallel recipes only care about ids, one per line: a later "list the atlas pages /
  tracks to check" option can feed the same `RUN_JOBS`.
* The reward table is the first per-class fact that lives as data and is verified end to end in the real
  engine. Other per-class facts of the "Classes" section (trainers, class quest chains) can follow the same
  path: data registered once, a tool that resolves it offline, a mock run that asserts what the addon does.
* `docs/ROUTE_FORMAT.md` now says in one place what a data module may contain; the atlas adds kinds to
  `AddLibraryData` (merged per kind and key) or its own registration call next to it.

## 5. Open issues for the orchestrator

* The plan text and the code differ in the points of section 3 (1, 5, 6, 8); none needs a decision, the plan
  can be aligned or left.
* A.7 budgets busted at 1.3 min; it is 1.7 min now. With 28 routes the CI estimate is about 10 min instead of
  9.5 min (limit 25 min).
* `docs/dev/PLAN.md` appendix 2 (command reference) matches what exists: `--list-routes`, `make route`,
  `make check-fast`, `make check`, `make simulate-sync-full`.
* Nothing blocks F2a.

## 6. Verification round 1

Five findings of the independent verification (two of them the same defect). All were reproduced on the tree
before any change; none was rejected. Files touched: `Makefile`, `tests/spec/build_spec.lua`,
`.github/workflows/ci.yml` (a comment), `tools/README.md`, this file. `docs/VALIDATION.md` was regenerated and
is byte-identical (sha256 `9d46cbab...` before and after).

| # | Finding | Verdict | Change |
|---|---|---|---|
| 1, 5 | CI step "Validation report is up to date" cannot see a report generator that crashes: `make report` ignored every exit status (leading `-`), a Lua error is exit 1 like routes with errors, the committed file stayed, `test -f` and `git diff --exit-code` passed | real (the code: `writeFile` runs after `V.FormatMarkdown`; reproduced in a scratch copy with `error("boom")` in `Report.Markdown`) | `Makefile`: `make report` writes to a `mktemp` file, accepts exit status 0 and 1 only, requires a non-empty report, then replaces `$(REPORT)` (new variable, `docs/VALIDATION.md`); otherwise it prints `report: the validator wrote no report (exit status N): ... is unchanged` and fails. The CI step is unchanged (`make report`, `test -f`, `git diff --exit-code`): it now fails at `make report`. Scratch copy with `error("boom")`: `make report` exits 2, the file is untouched. 4 new spec cases (`make report`): a fake validator (`LUA=...`, `REPORT=...`) for report + exit 0 / 1, no report + exit 1 / 0, empty report, exit 2; and the real validator with `lib.report` replaced by one that raises (fails) and without the replacement (writes a report). The CI case also asserts that the step does not hide the exit status |
| 2 (blocker) | The `check-fast` case pinned `VALIDATE_FLAGS` to empty; F2a must set `--strict --end-level` and does not own the spec | real (`VALIDATE_FLAGS = --strict --end-level` in a scratch Makefile: 1 failure at the case) | the case passes `VALIDATE_FLAGS='--strict --end-level'` itself and asserts `lua5.1 tools/validate_routes.lua --strict --end-level`, like the `route` case. Checked: the spec is green with the F2a value in a scratch Makefile, and under `make test VALIDATE_FLAGS=--strict`. Note for F2a added in section 4 |
| 3 | `build_spec.lua` inherited `MAKEFLAGS` / `MAKELEVEL` of an outer make: 2 failures under `make -j4 test`, 1 under `make test ROUTE=horde-skyborne-druid` | real (both reproduced) | every make of the spec runs as `env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u MAKEOVERRIDES -u GNUMAKEFLAGS make`; `makeVar` takes the last output line. 2 new cases with the environment of `make -j4 check ROUTE=leaked` (the helper answers with the Makefile's values, no jobserver warning; the unprotected command does leak). Checked: `make -j4 test`, `make test ROUTE=... SYNC_ROUTES=nope VALIDATE_FLAGS=--strict` and a full `make -j4 check` (2 min 19 s) are green |
| 4 | `RUN_JOBS`: the outputs of jobs that end together interleave once they are larger than one pipe write (the comment promised one piece) | real (fake simulator, 8 x 40 KB: 1 of 5 runs had 2 broken lines and 9 blocks) | `Makefile`: each job writes its output to a file in a `mktemp -d` directory and prints it while it holds a lock (`mkdir` of a lock directory: atomic, no `flock`, which BSD / macOS do not have); the directory is removed at the end and on HUP / INT / TERM; a job whose directory vanished stops waiting. Exit codes as before (xargs fails when a job fails). 10 of 10 runs of the reproduction are clean. 2 new spec cases: six jobs that start together, 330 KB each, the log reader a second late: 6 blocks, every line whole and in order (fails 6 of 6 times with the old recipe, passes 6 of 6 with the new); a failing job prints its whole output and fails the target |

Deviation from the plan: `RUN_JOBS` is no longer the one-liner of A.7 (the job and the wrapper are two variables,
`RUN_JOB` and `RUN_JOBS`); the recipes that use it are unchanged. `make report` no longer has the `-` prefix.

Not changed on purpose: the validator's exit codes (a Lua error stays exit 1; the recipe does not depend on
telling it from "routes with errors").

Acceptance after the fixes:

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 154 files |
| `busted` (inside `make check`) | 671 successes / 0 failures / 0 errors (663 + 8 new cases; `build_spec.lua`: 24), 111 s |
| `lua5.1 tools/simulate_routes.lua --list-routes` | exit 0; `horde-skyborne-druid`, `horde-undead-paladin` |
| `make simulate` (inside `make check`) | "simulate: 2 route(s), 4 at a time", both pass, "simulate: all routes passed"; a failing `--list-routes` fails the target (spec) |
| `make check` | exit 0, **3 min 47 s** wall (7 min 44 s CPU, 4 CPUs); 16 sync runs, 5 fixture simulations, 4 harness runs |
| `make -j4 check` | exit 0, 2 min 19 s wall |
| `make check-fast` | exit 0, 30 s |
| `make report` | exit 0, "report: docs/VALIDATION.md written", the file unchanged (deterministic) |
| `make routedata-check`, `make package` | exit 0 |
| `git status --short addons/` | prints nothing |
