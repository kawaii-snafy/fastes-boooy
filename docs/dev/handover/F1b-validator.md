# Hand-over F1b: validator (file filters, `ok`, budgets, overrides)

Phase F1b of `docs/dev/PLAN.md` (A.6.1, A.6.2, A.6.3, D.1 row F1b). Nothing was committed (the orchestrator
commits). `docs/VALIDATION.md` and `tools/README.md` were **not** touched: F1c regenerates the report and writes
the documentation (D.0 rule 2, D.1 row F1c); both are stale by what is listed in section 5.

## 1. What changed

### Tools

| File | Change |
|---|---|
| new `tools/lib/glob.lua` | one `*` syntax for `--skip` / `--keep` / `--own` and `--route`: `Glob.Match`, `Any`, `Skipped`, `NewList` / `ListMatch` / `Unmatched`, `UnmatchedIn` |
| `tools/lib/route_loader.lua` | `opts.skipGlobs` / `opts.keepGlobs` (the module's own TOC files); `mod.skipped`, `mod.filtered`, `mod.skipSet`, `mod.tocFiles`, `mod.loadedFiles`; error fields `route` (the route an error is about) and `load` (the file did not load); `Loader.UnmatchedFilters` |
| `tools/lib/harness.lua` | `Harness.Build` accepts a module that registers routes (it needs shared segments of its own; a route module without any is still refused); `skipGlobs` / `keepGlobs` |
| `tools/lib/fbdb.lua` | the override layer: `DB.ApplyOverrides(db, dir)`, `DB.OverrideFiles`, `DB.OverrideOwns`; `DB.QuestBrief` carries an overridden `xp` for a quest outside the snapshot. `DB.Load` / `DB.Prepare` are unchanged |
| new `tools/lib/module_checks.lua` | the checks on the shared templates (`ModuleChecks.Run`): `unknown-race-token`, `insert-anchor-unknown`, `insert-unapplied`, `shared-step-unused`, `insert-scope-wider-than-anchor`, `ok-needs-ceiling`, `shared-unused` |
| `tools/lib/validator.lua` | `Run:addx` (stable fields, `ok`); `V.OkAccepts`; `xp-unknown` INFO; `V.TrainVerdict` and INFO `train-service`; WARN `db-override-unverified`; worst-case `fp` / `sethearth`; `V.RouteChecks(db, route, profiles, opts)`; entry `(shared <Module>)`; notes; `V.ApplyCriteria`, `V.Baseline`, `V.ReadBaseline`; `V.OverrideChecks`, `V.CheckOkUnused`, `V.MarkForeign`, `V.ForeignLines`, `V.SummaryLines`, `V.LevelLines`, `V.UnmatchedFileGlobs`; new options and usage text |
| `tools/simulate_routes.lua` | `--skip` / `--keep` (offline load and mock client), `--route` lists with wildcards, `--no-overrides` / `--overrides DIR`, harness on a mixed module |
| `tools/gen_route_data.lua` | `--skip` / `--keep` (only with `--stdout`), `--no-overrides` / `--overrides DIR` |
| `tests/mocks/wow/system.lua` | `Mock.loadAddon(m, toc, name, { skip = set })`, `addon.skipped` |
| `.luacheckrc` | `files["tools/overrides/*.lua"] = { std = "none" }` |
| `Makefile` | `NO_OVERRIDES = --no-overrides` on `validate-fixtures`, `simulate-fixtures`, `harness-fixtures` and the fixture part of `routedata-check` |
| new `tools/overrides/README.md` | format and rules of the override files (Russian, like `tools/README.md`). The directory holds no override yet |

### New command-line options of `validate_routes.lua`

`--route ID[,ID...]` with `*`, `--skip GLOB`, `--keep GLOB`, `--own GLOB` (all repeatable); `--end-level`;
`--summary`; `--levels`; `--grind-until SEG`; `--max-grind-until SEG=N/W`; `--baseline FILE`;
`--write-baseline FILE`; `--no-overrides`; `--overrides DIR`. `--help` lists them in groups.

### New and changed message codes

| Code | Severity | Where |
|---|---|---|
| `xp-unknown` | INFO (was WARN) | step |
| `train-service` | INFO | weapon master / riding trainer (any class), pet trainer (HUNTER), portal trainer (MAGE) |
| `unknown-race-token`, `insert-anchor-unknown`, `insert-unapplied`, `shared-step-unused`, `insert-scope-wider-than-anchor` | ERROR | entry `(shared <Module>)`; notes for files that are not own on a partial load |
| `shared-unused` | WARN | entry `(shared <Module>)`, full loads only |
| `ok-needs-ceiling` | ERROR | a step or a segment: template (module entry, never a note) or the route's own |
| `ok-unused` | WARN | full runs only; shared steps once, in the module entry |
| `optional-dependency` | ERROR | now also a required `fly` / `hearth` behind an optional `fp` / `sethearth` |
| `db-override-unverified` | WARN | step that passes a race / class / exclusivity / prerequisite / trainer check only because of an unverified override |
| `override-load`, `override-foreign-quest` | ERROR | entry `(overrides)`; `override-load` is a note with `--skip` |
| `end-level`, `grind-budget`, `grind-baseline` | ERROR | route (no step), only with their options |

Message fields next to the text: `quest`, `npc`, `object`, `kills`, `level`, `file`, `shared`, `accepted`,
`okCeiling`, `foreign`, `override`. Result fields: `acceptedWarn`, `foreign`, `shared`, `overrides`,
`stepLevels`, `summary.xpQuestEstimatedPct`, `summary.grindUntil`. Module result fields: `notes`, `mod`,
`routes`. JSON report: `routes[i].accepted`, `.foreign`, `.shared`, `totals.accepted`, top-level `notes`.

### Specs

| Spec | Cases | What |
|---|---:|---|
| new `validator_module_spec.lua` | 31 | globs; every template check (among them a template step with `race = "Undead"`, a misspelled anchor under `--skip`: own, not own, no `--own`, full load); `ok-needs-ceiling` on steps and segments, never a note; which modules get the checks; `step-no-profile` only for own steps; the file filter in the loader, validator, simulator, generator and `Mock.loadAddon`; globs that match no file (three tools); `--route` lists, repeated `--route`, in both tools; which errors count with `--route` (four cases); harness on a mixed module in both tools |
| new `validator_gates_spec.lua` | 35 | `ok` in three forms, on a segment, never for an ERROR; the ceiling; `ok-needs-ceiling`; `ok-unused` (own and shared step); `--strict` with `--own`; the foreign block; `--end-level` (normal, worst case, harness); `--grind-until` (also an unknown segment), `--max-grind-until`; `--summary`; `--write-baseline` / `--baseline`; `--levels`; worst-case `fly` and `hearth`; trainer kinds; `xp-unknown` INFO; stable fields |
| new `validator_overrides_spec.lua` | 24 | every field; `pcall` on a broken file; format errors; duplicate id; `shared.lua` first; the median stays that of the snapshot; a quest outside the snapshot; owner files; `exclusive = { remove }` with a replay of 861 + 854 before the accept of 844; masks, prerequisites, NPC sub name; `override-load`, `override-foreign-quest`; the three command lines; the specs do not depend on `tools/overrides` (three cases) |
| `validator_lib_spec.lua` | +1 | `V.ParseArgs` for the new options |
| `validator_lint_spec.lua` | +1 | override files: no globals at all |
| `validator_harness_spec.lua` | 1 changed | the harness accepts a mixed module; a route module without shared segments is refused |
| `validator_cli_spec.lua`, `validator_compose_spec.lua`, `validator_guides_spec.lua`, `validator_harness_spec.lua`, `core_simulate_spec.lua`, `core_sync_spec.lua` | 42 command lines | every tool command line passes `--no-overrides` (verification round 1) |
| `validator_fixtures_spec.lua` | 1 line | `xp-unknown` is counted under INFO |

## 2. Acceptance: commands run and results

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 151 files |
| `busted` | 618 successes / 0 failures / 0 errors (526 before F1b), 98 s (77 s before) |
| `busted` in a scratch copy of the tree with three files added to `tools/overrides/` (one that does not parse, one valid `tirisfal.lua`, one `shared.lua` that changes XP and a prerequisite of fixture quests) | 618 successes / 0 failures (the verifier measured 35 failures with a broken file alone before round 1) |
| `make validate` | exit 0. `horde-undead-paladin`: 0 ERROR, **18 WARN**, 458 INFO. `horde-skyborne-druid`: 0 ERROR, **18 WARN**, 513 INFO (see deviation 1) |
| `lua5.1 tools/validate_routes.lua -q --summary --end-level --grind-until h-22-hillsbrad` | exit 0; `horde-skyborne-druid ... 60.00 60.00 4878 6082 0 97`, `horde-undead-paladin ... 60.00 60.00 4972 6179 75 160` |
| segments, gates and summaries of both routes against the JSON report from before F1b | identical; the only differences are `xp-unknown` (WARN to INFO), one `train-service` and the new field `xpQuestEstimatedPct` |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level tests/fixtures/core/FastesBoooy_TestGuides` | exit 0; 4 entries (the module entry and three routes), 0 ERROR, 0 WARN |
| `make validate-fixtures` | exit 0; the same counts as before plus the line `(shared FastesBoooy_TestGuides) [shared: 2 segment(s), 6 insert(s), 25 step(s)]` |
| `make harness-fixtures` | exit 0 (4 runs) |
| `make simulate-fixtures` | 5 simulations, 5 passed |
| `make routedata-check` | exit 0 |
| `make simulate` (not required; the simulator and the mock changed) | 2 simulations, 2 passed, 1,713 / 1,748 steps |
| `git status --short addons/FastesBoooy_*` | prints nothing |

`make simulate-sync` was not run: the core is untouched and the sync code paths of the simulator did not change.

## 3. Deviations from the plan, and why

1. **Old routes: 18 and 18 WARN, not 18 and 19.** D.1 computes 145 - 126 = 19 for the druid. One of the 19 is
   `train-not-class-trainer` at `dru-riding` (Genn Fairweather, "Stablemaster and Riding Trainer"), which the
   trainer kinds of A.6.2 turn into INFO `train-service`. Both numbers of the plan cannot hold at once.
2. **Simulator and generator parts were done here.** A.6.1 / A.6.2 name the three command lines (file filter,
   `--route` lists, `--no-overrides`, harness on a mixed module) and A.6.5 lists the same items for F1c. They
   share the loader, the mock and `DB.ApplyOverrides`, so they are implemented and specified in F1b. F1c keeps
   `--list-routes`, the reward choices, `PLACE_NAMES_RU`, the Makefile and CI.
3. **`Makefile`: the fixture targets already pass `--no-overrides`** (A.7 gives the Makefile to F1c). The
   option exists from this phase on and the fixtures should never have run with overrides.
4. **Module entry.** The template checks are reported in an entry of their own, `(shared <Module>)`, in front
   of the module's routes, not in the first route. It exists for every module that registers routes and
   shared content. `-q` prints one more line for such a module; `--summary` has no line for it.
5. **Notes.** "Printed as notes, no exit code" (A.6.2) is a list of its own per module (`notes`), printed as
   `  note  <where> [code] text -- not counted: <reason>` in both output modes and written to the JSON report.
6. **`--route`: every entry of the list must match a route** (exit 2 in the validator, 1 in the simulator,
   naming the entry). A typo in a list would otherwise validate fewer routes without a word. For the same
   reason `--route` is repeatable (the lists add up), and a `--skip` / `--keep` glob that matches no TOC file
   or an `--own` glob that matches no loaded file is refused with exit 2 in all three tools (verification
   round 1).
7. **Load errors with `--route`: decided by what the error belongs to, not by "the file contributed no
   step"** (corrected in verification round 1; the first version followed the letter of A.6.2 and let a
   route pass that had lost a whole file). With `--route` an error is a note only when it provably belongs
   to a route outside the selection:
   * a file that did not load or did not run to its end (syntax or runtime error) always counts: nobody can
     tell what it would have given the selected routes. Another author's broken file is left out with
     `--skip`, as D.0 rule 3 says, never by `--route`;
   * an error about one route (its registration, `UseSegments`, a per-route insert, its composition) counts
     when that route is selected and is a note otherwise, whatever file reports it (every route of the
     Guides module is registered in `Route.lua`);
   * any other error of a file that loaded (a schema error of a shared segment or insert, a stray global)
     is a note only when the file's content went to routes outside the selection and to none of the
     selected ones. A file that gave nothing to any route counts;
   * the files the caller names with `--own` always count.
8. **`ok`.** A ceiling on a code without a kill count is accepted like a plain entry. "Fired" for `ok-unused`
   means "reported at that step with any severity": a gate with `ok = { ["level-grind"] = 90 }` that needs
   20 kills (INFO) is not stale; a gate that needs none is. `ok-unused` is also skipped with `--profile`,
   `--state`, `--harness` and for an ignored code.
9. **Worst-case `fly` / `hearth`: spec cases on in-memory routes**, not fixture modules (the form the grind
   spec already uses for the worst case). A required `sethearth` after an optional one clears the dependency.
10. **`db-override-unverified` also covers the trainer check** (an NPC `sub` override), the one check an NPC
    override can influence.
11. **Overrides, details the plan leaves open.** `exclusive = { remove = { B } }` on A removes the pair in
    both directions. A quest outside the snapshot takes `xp`, `races`, `classes`. `races = { add = {
    "Skyborne" } }` adds the bit of the side(s) the quest already has. An override on a mask that means
    "everyone" changes nothing. `--overrides DIR` exists for specs. `byClass` overlays are not touched (the
    four in the snapshot only hold `next`). `override-foreign-quest` is checked for quests, not for NPCs.
12. **Counts.** `, A accepted` is printed only when A > 0, so every existing output line keeps its text.
    `--summary`: column 4 is the unaccepted warnings on own files, column 6 the foreign ones; the last two
    columns are `-` without `--grind-until` or when the route has no such segment.
13. **`--max-grind-until` on a route without the segment is ERROR `grind-budget`** (skipped in a harness run,
    which may not contain it). `--baseline` without an entry for the route's race is ERROR `grind-baseline`.
    Both would pass silently otherwise. `--max-grind-until` also sets the segment of `--grind-until` when
    that option is absent. An explicit `--grind-until SEG` that no validated route contains is refused with
    exit 2, and no baseline is written (verification round 1).
14. **`shared-step-unused` is one message for an insert none of whose steps is composed**, and is not repeated
    for an insert already reported with `insert-anchor-unknown` / `insert-unapplied` / `unknown-race-token`,
    nor for the steps of a segment no route uses (`shared-unused`).
15. **The file filter and the template checks cover the module's own files**, not the files of a dependency
    (the plan says "TOC path"; the old two-module layout is the only place with dependencies).
16. **Text of the summary line**: "quest XP N; M quests with estimated XP (P% of quest XP); ..." replaces
    "(N estimated, M quests with unknown XP)". No spec pinned the old wording.
17. **Override files: `shared.lua` is applied first**, then the owner files in alphabetical order (A.6.2
    says "alphabetical"). The later file of a duplicate id is the one in error; with plain alphabetical
    order that was `shared.lua` for every owner file that sorts before it, and one agent's duplicate
    switched off the shared file for everybody (verification round 1).
18. **`ok-needs-ceiling` is never a note and is also reported for a segment's `ok`.** It reads one step or
    segment and depends on no other file, so the "note on a partial load" rule of A.6.2 (which names the
    five template checks) does not apply to it. A segment's `ok` only ever accepts `segment-level`; a plain
    `level-grind` there was silently inert (verification round 1).

## 4. Notes for the next phases

### Commands (they replace the examples of `tools.md` 11.3)

```
# a class agent: own file only, everything else loaded
lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --route '*-warrior' \
    --skip 'Classes/*' --keep Classes/Warrior.lua --own Classes/Warrior.lua
# where did my insert steps land, and at which level
lua5.1 tools/validate_routes.lua -q --levels --route orc-warrior --skip 'Classes/*' --keep Classes/Warrior.lua
# a path agent: its zone from a fresh character, class-neutral (without --skip the class inserts apply)
lua5.1 tools/validate_routes.lua --harness addons/FastesBoooy_Guides --segments <ids> \
    --profile race=Orc,class=WARRIOR --skip 'Classes/*' --end-level --write-state $SCRATCH/orc.json
```

* `--own` globs are matched against the file of a message (`Classes/Warrior.lua`). A message without a file
  (`route-level`) belongs to the file that registered the route (`Route.lua`); the foreign block prints such
  a message once per route, with the route id.
* A `--skip` / `--keep` / `--own` glob must match a file (exit 2 otherwise: `--skip 'Classes/*' --own
  Classes/Warrior.lua` without `--keep` is refused, the own file would not be loaded). The match is
  case-sensitive.
* `--route` does not hide a broken file: a file that fails to load fails every run that loads it. Leave
  another author's broken file out with `--skip` (deviation 7).
* **Specs and override files.** Every tool command line in `tests/spec` passes `--no-overrides` (or
  `--overrides DIR`), and `validator_overrides_spec.lua` fails on a spec line that does not. A new spec
  that runs `validate_routes.lua`, `simulate_routes.lua` or `gen_route_data.lua` must do the same; then
  no file a later phase puts into `tools/overrides/` can move a spec.
* `--profile` is an override, not a filter. Pick routes with `--route`.
* With `--skip`, `ok-unused` and `shared-unused` are not evaluated. The single-owner phases see them.
* A step note for authors: `ok` goes on the step whose location the message prints. `quest-carried` is
  printed at the accept step; `segment-level` needs `ok` on the segment.

### For F1c

* `tools/README.md` is stale in: the options table of the validator, the code list (section 1 above),
  "`xp-unknown` WARN", "the harness refuses route modules", the output format (`accepted`, notes, the module
  entry, the foreign block, the override line, `--summary` / `--levels`), the Makefile fixture targets. The
  override layer is described in `tools/overrides/README.md`; `tools/README.md` only needs a pointer.
* `docs/VALIDATION.md` is stale (240 WARN in the file, 36 now). `V.FormatMarkdown` got the minimum for the
  new data: the module entry, the override entry, accepted warnings in a `<details>` block, the reworded
  simulation line. The layout of A.6.4 is untouched work.
* Data the report of A.6.4 can use: `m.shared`, `m.quest`, `m.kills`, `m.level`, `m.accepted`, `m.okCeiling`,
  `result.shared`, `moduleResult.routes` (route and its results), `summary.gates[i]`, `summary.grindUntil`.
* The simulator still takes reward choices from `step.reward` only, and has no `--list-routes`.
* `busted` grew from 77 s to 98 s (the new specs run the tools as processes). A.7 budgets 1.3 min.

### For the atlas (`docs/dev/ATLAS.md`)

* The override layer is a small store of facts checked in the game, each with a source and a `verified` flag,
  outside the generated snapshot. Atlas data that corrects or extends the snapshot (quest XP, who may take a
  quest) can come from the same files without a second mechanism.
* The template checks work on any shared content of a module, not on routes only: a future module with atlas
  pages next to the guides gets the scope checks as soon as its entries are registered as shared steps.

## 5. Open issues for the orchestrator

* The plan's number "19 WARN" for `horde-skyborne-druid` (D.1 row F1b, and review-log entry ET-10 if it
  repeats the number) should read 18 (deviation 1). Confirmed in verification round 1; no code change.
* A.6.2 says the override files are read in alphabetical order and that load errors of files "that
  contributed no step" are notes with `--route`. Both were changed on purpose (deviations 17 and 7); the
  plan text can be aligned.
* `docs/VALIDATION.md` does not match the validator until F1c regenerates it; the CI freshness step fails on
  this state. It is a checkpoint, not a state to push.
* F1a suggested a module check for a shared insert anchored on a step of a later-registered insert. It was not
  added: the core handles forward references since F1a's verification round, and the plan does not ask for it.
* Nothing blocks F1c.

## 6. Verification round 1

Findings of the independent verification, what was checked and what changed. Every change has a spec; the
acceptance commands of section 2 were run again afterwards (results below).

| # | Finding | Verdict | Change |
|---|---|---|---|
| 1 | (major, reported twice) The override layer is on by default in the three tools, and the older specs ran them on the fixtures without `--no-overrides`: the first file a later phase adds to `tools/overrides/` could turn `busted` red for agents who may not touch `tests/**`. | Real: none of the 42 command lines passed the option (the verifier measured 35 failing specs with a broken file in the directory). | All 42 tool command lines of `validator_cli_spec`, `validator_compose_spec`, `validator_guides_spec`, `validator_harness_spec`, `core_simulate_spec` and `core_sync_spec` pass `--no-overrides`. Three new cases in `validator_overrides_spec.lua`: (a) a scan of every `tests/spec/*_spec.lua`: a tool command line without `--no-overrides` / `--overrides DIR` fails the suite (a line whose command is completed elsewhere carries the comment `-- overrides: explicit`); (b) the fixture recipes of the `Makefile` pass `$(NO_OVERRIDES)`; (c) a second repository root with a format-broken and a value-changing file in its default `tools/overrides`: without the option all three tools move or fail there, with it seven fixture command lines print exactly what they print in this checkout. Check by hand: `busted` in a scratch copy with three override files, 618 / 0. |
| 2 | (minor) `ok-needs-ceiling` in a file that is not own was demoted to a note on a partial load. | Real. | `module_checks.lua`: the check is never a note (it depends on no other file); deviation 18. Spec: the class agent's command line on a module with a plain `level-grind` in a segment file exits 1 and prints no note. |
| 3 | (minor, reported twice) An `--own` glob that matches no loaded file makes `--strict` pass on anything; `--skip` / `--keep` typos are silent too. | Real. | `Glob.UnmatchedIn`, `Loader.UnmatchedFilters`, `V.UnmatchedFileGlobs`: a `--skip` / `--keep` glob that matches no TOC file of the modules of the run, or an `--own` glob that matches no loaded file (also: only files that `--skip` leaves out), is refused before anything runs, exit 2, in the validator (module and harness runs), the simulator and the generator. One existing spec used `--skip 'Nope/*'` to get a "filtered" run; it now skips a real file. |
| 4 | (minor) `--grind-until` with a segment id no validated route has was ignored; `--write-baseline` then wrote a file without the pair. | Real. | Exit 2 with a message naming the segment, and no baseline file, when none of the validated routes has the segment. One route with the segment is enough (the others keep `-`). Deviation 13. |
| 5 | (minor) The foreign block merged the file-less messages (`route-level`) of different routes into one line with the first route's text. | Real. | `V.ForeignLines`: a message without step and segment is one line per route, `route <id> (<file that registered it>)`; a place in a file stays one line for all routes that pass it. Spec on the command line and on `V.ForeignLines`. |
| 6 | (minor) D.1 says 18 and 19 WARN, the old routes report 18 and 18. | Real, and not a code defect: the plan's trainer-kind rule turns the nineteenth message into INFO `train-service` (deviation 1). | None. For the orchestrator: correct D.1 row F1b (and ET-10) to "18 and 18" (section 5). |
| 7 | (major) "Load errors become notes with `--route`" failed in both directions: (a) a file that does not parse contributes no step, so its error was a note even in the run of the route that lost the file (exit 0 under `--strict --end-level`, a regression against HEAD); (b) a composition error of an unselected route still failed the run, because every route is registered in `Route.lua`. | Real, both. | The loader marks each error with `route` (the route it is about) or `load` (the file did not load or run to its end); `V.ValidateModule` decides by that (deviation 7, rewritten). (a) a file that does not load always counts; (b) an error about a route outside the selection is a note, whatever file reports it; a schema error of a loaded file is a note only when the file's content goes to unselected routes alone. Four spec cases, in process and on the command line. This is stricter than the letter of A.6.2: another author's broken file now fails a `--route` run unless it is skipped, which is what D.0 rule 3 states. |
| 8 | (minor) A plain `level-grind` in the `ok` of a segment gave neither `ok-needs-ceiling` nor `ok-unused`. | Real. | `ok-needs-ceiling` is reported for a segment too: in the module entry for a shared segment, in the route for its own segment (`V.RouteChecks`). Spec for both. |
| 9 | (minor) A second `--route` replaced the first; after a load error the simulator added a false "matched no route". | Real, both. | `--route` is repeatable in both tools (the lists add up). The simulator does not print the unmatched line when a module failed to load (it has failed anyway, exit 1). Specs. |
| 10 | (minor) Duplicate id: with alphabetical order the "second" file was `shared.lua` for nine owner names, so an agent's duplicate switched the shared file off for everyone. | Real. | `DB.OverrideFiles`: `shared.lua` first, then alphabetical; the owner file that repeats the id is the one ignored. `tools/overrides/README.md` says so. Spec. Deviation 17. |

Not changed: `tools/README.md` and `docs/VALIDATION.md` (F1c). New for F1c's option table: exit status 2 for
a glob that matches nothing and for an unknown `--grind-until` segment; `--route` is repeatable; the note
texts of `--route`; `ok-needs-ceiling` on segments; the order of the override files.

Acceptance after the round:

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 151 files |
| `busted` | 618 successes / 0 failures / 0 errors, 98 s |
| `make validate` | exit 0; both old routes 0 ERROR, 18 WARN (513 and 458 INFO) |
| `lua5.1 tools/validate_routes.lua -q --summary --end-level --grind-until h-22-hillsbrad` | exit 0; `horde-skyborne-druid ... 60.00 60.00 4878 6082 0 97`, `horde-undead-paladin ... 60.00 60.00 4972 6179 75 160` (unchanged) |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level tests/fixtures/core/FastesBoooy_TestGuides` | exit 0; 0 ERROR, 0 WARN |
| `make validate-fixtures harness-fixtures routedata-check simulate-fixtures` | all exit 0 (7 modules, 0 errors; 5 simulations passed) |
| `make simulate` | 2 simulations, 2 passed (1,713 / 1,748 steps) |
| `git status --short addons/FastesBoooy_*` | prints nothing |
