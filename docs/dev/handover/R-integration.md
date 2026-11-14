# Hand-over R: integration (28 guides with class steps)

Phase R of `docs/dev/PLAN.md` (D.6). FAST MODE (decided with the user): targeted checks during the phase, `make check`
once at the end, `make simulate-sync-full` once. Nothing committed; no git command that changes state was run (the
orchestrator commits; three files were deleted with `rm`, so stage with `git add -A`). `G` = `addons/FastesBoooy_Guides`.

## 1. What changed

| File | Change | Why (hand-over) |
|---|---|---|
| `G/Classes/Warlock.lua` | `ok = "db-override-unverified"` removed from `wlk-tablet`, `wlk-binding`, `wlk-ganrul-3`, `wlk-46-orb`, `wlk-46-orb-done` (the `-- CONFIRM` comments stay) | the full run (no `--route`) reported 5 WARN `ok-unused` in the library checks: the validator reports `db-override-unverified` on the **accept** steps only (`wlk-ganrul`, `wlk-ganrul-2`, `wlk-46-menara`); phase C ran with `--route "*-warlock"`, which skips that library check, so the warlock hand-over's claim "not reported as unused" did not hold |
| `G/Segments/Zephras/01_Zephras_1_9.lua` | `ok = "segment-level"` on `sd-01-zephras` with a comment; `levels = { 1, 9 }` kept | c-shaman foreign WARN: `skyborne-shaman` ends `sd-01` at 10.08 (shaman letter and Earth chain, estimated XP); the base profile 9.95. The planned range stays (title, level sync); the key is used by that route, so not `ok-unused` |
| `G/Segments/Shared/24_Barrens_Stonetalon.lua` | the Chol'aruk step (`complete = 97003`, formerly positional `h-24-barrens-stonetalon:44`) got `id = "h-26-cholaruk"` | c-warrior anchor wish 1 |
| `G/Classes/Warrior.lua` | `war-1825` moved from `before = "h-25-the-crossroads-flight"` to `after = "h-26-cholaruk"`, no longer `optional`; note and header comment rewritten | c-warrior anchor wish 1 (780 XP for ~300 yd; worst-case grind of the warrior routes -5 kills) |
| `G/Segments/Durotar/02_Durotar.lua` | `dur02-korghan` note: "Расселина Тьмы" -> "Расселина Теней" (the class files' name; the ruRU client name of the Cleft of Shadow) | c-warlock minor |
| `.luacheckrc` | `files["addons/FastesBoooy_*/Data.lua"]`: `max_line_length = false` | `make lint` failed on the tree as committed after C: `Data.lua:3070` (questMeta of mage quest 97286, `preAny` with 40 ids) is 340 characters; generated data, cannot be shorter |
| `tests/spec/guides_layout_spec.lua` | new case "has no placeholder class or race file: every route gets steps of its class file and of its race file" (D.6 step 1); `h-26-cholaruk` added to the 22-60 `ANCHORS`; a history comment notes the deleted state fixtures | D.6 |
| `tests/fixtures/validator/guides_state_orc_11.json`, `guides_state_tauren_11.json`, `guides_state_tauren_11_fly.json` | deleted | P2 open issue 4: read by no spec since P2 retired the harness proofs. `tests/fixtures/guides/FastesBoooy_StartZones` is **kept**: the spec case "Route.lua builds all 28 routes once every start zone has announced itself (fixture zones)" still loads it (now it replaces nothing, but it keeps the announce mechanism tested if a zone file is ever skipped) |
| `tools/simulate_routes.lua` | the background loop skips a step of the iteration's snapshot that the engine no longer lists (`-v`: "no longer a background goal") | the first `make simulate-sync-full` failed 1 of 60 runs before it was stopped: `orc-rogue --ahead 35` (and `troll-rogue`, reproduced): `FAIL step rog-train-22 [accept 2460, train]: the automation did not accept quest 2460`. Cause (traced with temporary prints, removed): the jump to `h-31` keeps the skipped trainer visit `rog-train-22` as a background goal (its accept void "floor"); the current step `h-31-tb-fly` moves the cursor to the route's own next trainer visit, so the engine drops the kept visit (correct: `KeepUntil`) and the step, below the floor and no longer kept, is done as a whole - but the simulator still performed it from its stale snapshot and expected the (no longer void) accept. A simulator defect, not an engine or route one; the engine and `Classes/Rogue.lua` are unchanged |
| `tools/gen_confirm_list.py` | new: the "confirm in game" list from the `-- CONFIRM` comments | D.6 step 5 ("the generated list") |
| `docs/routes/confirm-in-game.md` | new, generated (77 items) | D.6 step 5 |
| `README.md` | the 28 guides as a table with route ids, what class and race steps do, overall grind range; the sentence "class steps only for paladin and druid" removed; links to all class documents and the confirm list; new section "Что ещё не проверено в игре". Install and the update note from 0.3 were already right (checked, unchanged) | D.6 step 5 |
| `docs/routes/shared-path.md` | header links (all race / class documents), overview table (Durotar / Mulgore no longer "в работе", entry levels from P2), "11 guides" -> 28, the full-route table replaced by the 28 routes of this phase (`--summary`), the base profiles of the freeze, the race-filtered flight points of `h-15` (§3.5, P2 open issue 2), §12 commands (`--baseline`, base profiles of all races, harness from a written state instead of the deleted fixtures, the commands verified), §11 history | D.6 step 5, P2 open issue 2 |
| `docs/routes/class-warrior.md` | `war-1825` row, rule text and deviation 4; the grind table (new numbers) | anchor wish |
| `tools/README.md` | `VALIDATE_FLAGS` with `--baseline`, `SYNC_ROUTES` with the five routes, the F1 sync table marked as history, the new tool, the simulator rule for stale background steps (section 8) | P2 open issue 3 |
| `docs/ARCHITECTURE.md` | module paragraph: all zones written, the layout (`Segments/<Zone>`, `Classes`, `Races`, `Route.lua`) | D.6 step 5 |
| `docs/ROUTE_FORMAT.md` | conventions of section C of the plan for the guides module (class / race files, prefixes, anchors, CONFIRM) | D.6 step 5 |
| `docs/dev/PLAN.md` | status line | - |
| `docs/VALIDATION.md`, `G/Data.lua` | `make report` (changed), `make routedata` (unchanged: no quest set changed) | D.6 step 4 |

Not changed: `tools/overrides/shared.lua` (no XP value or mask correction for a shared quest in any hand-over),
`PLACE_NAMES_RU` (no new place name in any hand-over), `baseline.json` (written again from the base routes: identical,
see section 2), `Route.lua`, the TOC, the core, every other class / race file.

## 2. Acceptance: commands and results (4 CPUs)

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 180 files (before the `.luacheckrc` fix: 1 warning, `Data.lua:3070` W631) |
| `busted tests/spec/guides_layout_spec.lua` (no variables) | 31 successes / 0 failures / 0 errors (7.1 s) |
| `lua5.1 tools/validate_routes.lua -q $(VALIDATE_FLAGS) --summary $G` (all 28 routes, all class files) | **exit 0**: 0 error, 0 warning, 488 accepted (strict); library block 0 / 0; every route 60.00 / 60.00; table below. Before the fixes: exit 1, 6 WARN (5 `ok-unused` warlock, 1 `segment-level` `sd-01-zephras`) |
| `... --skip 'Classes/*' --grind-until h-18-stonetalon-ashenvale --write-baseline $SCRATCH/baseline.json` | 0 error, 0 warning, 479 accepted; the file is byte-identical to `docs/dev/handover/baseline.json` |
| `lua5.1 tools/simulate_routes.lua --route orc-warrior` (the route changed most) | `OK`, 1,720 steps, level 60, 25.8 s |
| `make package` | exactly two zips: `FastesBoooy-0.4.0.zip` (17 entries, folder `FastesBoooy`), `FastesBoooy_Guides-0.4.0.zip` (43 entries, folder `FastesBoooy_Guides`); then `make clean` |
| `make check` | run twice: before the simulator fix exit 0, 8 min 13 s wall; **on the final tree exit 0, 8 min 18 s wall** (27 min 26 s user): lint 0 / 0 in 180 files; busted **715** successes / 0 / 0 (76.7 s); `make validate` 0 ERROR, 0 WARN, 488 accepted (strict); `validate-fixtures` 0 errors (7 known fixture WARN); `make simulate` **28 of 28 routes passed**; `make simulate-sync` **40 of 40 runs passed**; fixture simulations 5 / 5; harness fixture runs pass. Simulator warnings: only the three known ones (`sd02-hearth` bind point x 9, optional `sky-1061` at 12 x 7, `h-53-azshara-ungoro-silithus:41` 4496 x 4 in `--level-plus` runs) |
| `make routedata-check` | exit 0 (`Data.lua` of the guides and of the fixtures up to date) |
| `make report` then compare | `docs/VALIDATION.md` fresh (a second report is byte-identical) |
| `make simulate-sync-full` | first run stopped after 60 of 224 runs with 1 FAIL (`orc-rogue --ahead 35`, section 1, `tools/simulate_routes.lua`); after the simulator fix, run once more in full: **exit 0, 224 of 224 runs passed, 18 min 31 s wall** (72 min user). Warnings: the three known ones (`h-53-azshara-ungoro-silithus:41` 4496 x 22, `sd02-hearth` x 20, `sky-1061` x 10) and one new: `tauren-warrior --level-plus 2` (jump `mul-02` -> `h-12` at 14): `war-uzzek [turnin 1498, accept 1502]: quest 1502 would not be offered yet: none of the prerequisites done: 1498, 1819` (a warning, the run passes; see Minor) |

### `--summary` of the 28 routes as shipped (`$(VALIDATE_FLAGS)`)

Columns: route, profile, errors, warnings, accepted, foreign, end level, worst, grind, worst, grind to the end of
`h-18`, worst.

```
orc-hunter	Orc HUNTER Horde	0	0	16	0	60.00	60.00	4944	6207	30	137
orc-mage	Orc MAGE Horde	0	0	17	0	60.00	60.00	4978	6225	43	155
orc-rogue	Orc ROGUE Horde	0	0	18	0	60.00	60.00	4954	6187	43	155
orc-shaman	Orc SHAMAN Horde	0	0	17	0	60.00	60.00	4937	6183	8	113
orc-warlock	Orc WARLOCK Horde	0	0	17	0	60.00	60.00	4897	6199	35	145
orc-warrior	Orc WARRIOR Horde	0	0	16	0	60.00	60.00	4914	6155	31	140
troll-hunter	Troll HUNTER Horde	0	0	16	0	60.00	60.00	4944	6207	30	137
troll-mage	Troll MAGE Horde	0	0	17	0	60.00	60.00	4978	6225	43	155
troll-priest	Troll PRIEST Horde	0	0	17	0	60.00	60.00	4950	6219	40	151
troll-rogue	Troll ROGUE Horde	0	0	18	0	60.00	60.00	4954	6187	43	155
troll-shaman	Troll SHAMAN Horde	0	0	17	0	60.00	60.00	4937	6183	8	113
troll-warlock	Troll WARLOCK Horde	0	0	19	0	60.00	60.00	4897	6199	35	145
troll-warrior	Troll WARRIOR Horde	0	0	16	0	60.00	60.00	4914	6155	31	140
tauren-druid	Tauren DRUID Horde	0	0	18	0	60.00	60.00	4890	6118	0	90
tauren-hunter	Tauren HUNTER Horde	0	0	18	0	60.00	60.00	4933	6180	19	110
tauren-shaman	Tauren SHAMAN Horde	0	0	19	0	60.00	60.00	4930	6167	1	97
tauren-warrior	Tauren WARRIOR Horde	0	0	18	0	60.00	60.00	4905	6128	22	113
undead-mage	Scourge MAGE Horde	0	0	16	0	60.00	60.00	4973	6208	38	138
undead-paladin	Scourge PALADIN Horde	0	0	17	0	60.00	60.00	4902	6173	5	103
undead-priest	Scourge PRIEST Horde	0	0	16	0	60.00	60.00	4951	6209	41	141
undead-rogue	Scourge ROGUE Horde	0	0	17	0	60.00	60.00	4948	6165	37	134
undead-warlock	Scourge WARLOCK Horde	0	0	17	0	60.00	60.00	4898	6187	36	133
undead-warrior	Scourge WARRIOR Horde	0	0	16	0	60.00	60.00	4904	6144	21	129
skyborne-druid	Skyborne DRUID Horde	0	0	19	0	60.00	60.00	4852	6052	0	24
skyborne-hunter	Skyborne HUNTER Horde	0	0	19	0	60.00	60.00	4888	6121	0	51
skyborne-rogue	Skyborne ROGUE Horde	0	0	19	0	60.00	60.00	4889	6090	0	58
skyborne-shaman	Skyborne SHAMAN Horde	0	0	20	0	60.00	60.00	4896	6118	0	48
skyborne-warrior	Skyborne WARRIOR Horde	0	0	18	0	60.00	60.00	4862	6070	0	55
```

Every route is at or under the baseline of its race (Orc / Troll 4,980 / 6,227; Tauren 4,965 / 6,197; Scourge
4,982 / 6,217; Skyborne 4,914 / 6,129) and under the `h-18` budget 120 / 200 (largest: Orc / Troll mage and rogue
43 / 155).

## 3. Hand-over items resolved

| Item | Source | Resolution |
|---|---|---|
| foreign WARN `segment-level` `sd-01-zephras` | c-shaman 3 | `ok` on the segment (section 1) |
| anchor wish `h-24-barrens-stonetalon:44` | c-warrior 6 | id `h-26-cholaruk`, `war-1825` moved and mandatory |
| `ok-unused` (not in any hand-over) | full run | warlock keys removed (section 1) |
| "Расселина Тьмы" vs "Расселина Теней" | c-warlock minor | unified to "Расселина Теней" |
| self-referencing `preSingle` of the snapshot builder | c-shaman 8 / minor | scanned the whole snapshot (`preSingle` / `preGroup` containing the quest's own id): only 1516 and 1519, both already overridden in `tools/overrides/shaman.lua`. No other chain is affected; the builder itself was not changed (no `make db` inputs in the repository) |
| full module check with all nine class files | c-hunter minor | done (section 2) |
| P2 open issue 2 (`shared-path.md` rows "в работе", unfiltered flight points) | p2 11 | done |
| P2 open issue 3 (`tools/README.md` values) | p2 11 | done |
| P2 open issue 4 (unused fixtures) | p2 11 | the three state files deleted; the StartZones fixture kept (still read) |
| P2 open issue 5 (`simulate-sync-full`) | p2 11 | run once (section 2) |
| XP values / masks for `shared.lua`, `PLACE_NAMES_RU` | all hand-overs | none listed by any phase-C hand-over: nothing to add |

## 4. Deviations from the plan

1. **`docs/routes/confirm-in-game.md` keeps the comment text in English** (the frame is Russian). The list is
   generated from the source comments (`tools/gen_confirm_list.py`); a translation would go stale with every edit of a
   comment. The README section "Что ещё не проверено в игре" is the Russian summary for players. CI does not check the
   freshness of the list (no Makefile target; regenerate by hand after CONFIRM edits).
2. **The route documents `docs/routes/race-*.md` and `class-*.md` keep their phase snapshot numbers** (P2 and C, each
   says so); only `class-warrior.md` (changed route) and the summary tables of `shared-path.md` were refreshed. The
   segment table (§2) and the anchor table (§10) of `shared-path.md` still show the F2 numbers of the Undead and
   Skyborne base profiles (levels and kills of the shared segments did not change by more than ~0.1 level / a few
   kills; per-race levels at every id: `docs/dev/handover/levels-<race>.tsv`).
3. **`sd-01-zephras` acknowledged instead of re-planned** (c-shaman offered both): changing `levels` would move the
   segment title and the level-sync threshold of all five Skyborne routes for one route's 0.08 level.
4. **The warrior's optional final visit after `h-60-end`** (`war-60-hearth`, `war-train-60`) is kept (c-warrior
   minor: it leaves the cold start "resumes at step 1719/1720"; harmless, and the training at 60 is useful).

5. **A tool fix in the integration phase**: `tools/simulate_routes.lua` (background-goal snapshot, section 1). The
   full sync matrix had never run over the 28 routes with class files before; the fix is in the tool, not in the
   engine or a route, and it is documented in `tools/README.md` section 8.

## 5. Open issues for the orchestrator

1. P2 open issue 1 (the gate `h12-lvl-12` in Orgrimmar) was not reopened: decided before phase C; adding it now would
   break the freeze (levels files, baseline).
2. `make simulate-sync-full` takes 18 min 31 s on 4 CPUs (224 runs); the nightly job has `timeout-minutes: 60`.
3. The simulator fix (section 1) changes `tools/simulate_routes.lua` after the first `make check`; `make check` was
   therefore run a second time on the final tree (section 2).
4. Nothing blocking.

## Minor, left open (for the atlas phase or later)

* Russian NPC / place / quest names in the notes of the class and race files are partly own transcriptions (every
  phase-C hand-over and P2 list them): check against the ruRU client.
* `--levels` worst-case column of an optional step shows the level of the worst run at that point (cosmetic, all
  class files).
* `Classes/Hunter.lua` header comment line over 120 characters (cosmetic).
* Talent tables of the class documents are the original game's (Forever may differ).
* Tauren druid: the Mulgore reward choices are not in a reward table (no class file has reward tables: the DB has no
  reward lists); Aquatic Form 27 is not mentioned in the Tauren notes (deliberately skipped).
* Priest: Zayus (5994, "High Priest", Valley of Spirits) has the trainer flag in the DB but is not in the `npc` lists of
  the Orgrimmar training steps; Thunder Bluff priest trainers' location ("Pools of Vision" vs "Spirit Rise").
* Shaman: `sha-train-14` after `h15-razor-hill` for every race; the Skyborne might rather train 14 + 16 at
  `h18-tb-zamah`. The Orc / Troll Fire chain could move to 10.8.
* Warrior: the Whirlwind weapon chain (c-warrior deviation 2) is a candidate for the atlas (bg goals on the path).
* Paladin / druid: `tools/overrides/paladin.lua` and `druid.lua` do not exist (the D.5 luacheck line names them).
* `docs/routes/confirm-in-game.md` line numbers move with every edit; regenerate after CONFIRM changes.
* `tauren-warrior --level-plus 2`: after the automatic jump from `mul-02` to `h-12` at level 14 the simulator warns that
  1502 (accept at `war-uzzek`, Defensive Stance chain) would not be offered (its prerequisites 1498 / 1819 not done).
  The engine does not treat the accept as unreachable because 1502 has two alternative prerequisites; the run passes.
  A player in that situation gets the step and can skip it; a cleaner engine rule (an accept whose every
  prerequisite is a never-taken quest below the floor is void) is a core change left for later.
