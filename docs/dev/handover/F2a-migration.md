# Hand-over F2a: mechanical migration into `addons/FastesBoooy_Guides`

Phase F2a of `docs/dev/PLAN.md` (D.2, step F2a; A.1-A.4, A.8). Nothing was committed (the orchestrator
commits). The three old module folders are gone; `addons/` holds exactly `FastesBoooy` and `FastesBoooy_Guides`.
The two routes are `undead-paladin` and `skyborne-druid` (aliases `horde-undead-paladin`,
`horde-skyborne-druid`); their composed steps, levels, messages and numbers are those of the baseline.

**For the commit:** the moves and deletions were made with `git mv` / `git rm` (staged). The files written
afterwards are not staged: the 21 new files listed in section 1 are untracked and every moved file has unstaged
edits. `git add -A addons docs Makefile tests` takes everything of this phase.

## 1. What changed

### Module layout (`G` = `addons/FastesBoooy_Guides`)

| Old file | New file | Segment / content |
|---|---|---|
| `FastesBoooy_Horde/Segments/01_h-22-hillsbrad.lua` .. `12_h-56-felwood-winterspring-plaguelands.lua` | `G/Segments/Shared/22_Hillsbrad.lua`, `24_Barrens_Stonetalon.lua`, `27_Ashenvale_Needles.lua`, `31_Hillsbrad_Arathi.lua`, `34_Stranglethorn.lua`, `37_Desolace_Dustwallow.lua`, `41_Arathi_Badlands.lua`, `44_Swamp_Stranglethorn.lua`, `46_Tanaris_Feralas.lua`, `50_Hinterlands_Searing_Steppes.lua`, `53_Azshara_Ungoro_Silithus.lua`, `56_Felwood_Winterspring_Plaguelands.lua` | `h-22-hillsbrad` .. `h-56-felwood-winterspring-plaguelands`, ids unchanged |
| `FastesBoooy_UndeadPaladin/Segments/01_Deathknell.lua`, `02_Tirisfal.lua` | `G/Segments/Tirisfal/01_Deathknell.lua`, `02_Tirisfal.lua` | `ud-01-deathknell`, `ud-02-tirisfal` |
| `FastesBoooy_UndeadPaladin/Segments/03_Silverpine.lua`, `04_Barrens.lua`, `05_Barrens_Stonetalon_Ashenvale.lua` | `G/Segments/Legacy/ud_03_Silverpine.lua`, `ud_04_Barrens.lua`, `ud_05_Barrens_Stonetalon_Ashenvale.lua` | `ud-03-silverpine`, `ud-04-barrens`, `ud-05-stonetalon-ashenvale` (temporary) |
| `FastesBoooy_SkyborneDruid/Segments/01_Zephras_1_9.lua`, `02_Zephras_9_12.lua` | `G/Segments/Zephras/01_Zephras_1_9.lua`, `02_Zephras_9_13.lua` | `sd-01-zephras`, `sd-02-zephras` |
| `FastesBoooy_SkyborneDruid/Segments/03_Mulgore_Silverpine.lua`, `04_Barrens.lua`, `05_Barrens_Stonetalon_Ashenvale.lua` | `G/Segments/Legacy/sd_03_Mulgore_Silverpine.lua`, `sd_04_Barrens.lua`, `sd_05_Barrens_Stonetalon_Ashenvale.lua` | `sd-03-mulgore-silverpine`, `sd-04-barrens`, `sd-05-stonetalon-ashenvale` (temporary) |
| `FastesBoooy_UndeadPaladin/Inserts.lua` | `G/Classes/Paladin.lua` | 11 shared inserts, `class = "PALADIN"`, 23 steps, ids unchanged |
| `FastesBoooy_SkyborneDruid/Inserts.lua` | `G/Classes/Druid.lua` | 17 shared inserts, `class = "DRUID"`, 29 steps, ids unchanged |
| `FastesBoooy_UndeadPaladin/Route.lua` (+ the druid's, deleted) | `G/Route.lua` | rewritten: the route table of A.4 |
| `FastesBoooy_Horde/FastesBoooy_Horde.toc` (+ the two others, deleted) | `G/FastesBoooy_Guides.toc` | rewritten: the TOC of A.2 |
| `FastesBoooy_Horde/Data.lua` (+ the two others, deleted) | `G/Data.lua` | regenerated: one `AddLibraryData` call, 2,413 lines |

New files (untracked), 21:

* `G/Segments/Zephras/03_ThunderBluff.lua`: no segment yet, but the **Zephras announcement** (deviation 4);
* placeholders (header comment + guard line, register nothing): `G/Segments/Durotar/01_ValleyOfTrials.lua`,
  `02_Durotar.lua`, `G/Segments/Mulgore/01_CampNarache.lua`, `02_Mulgore.lua`, `03_BarrensCrossing.lua`,
  `G/Segments/Shared/12_Orgrimmar_Tirisfal.lua`, `13_Silverpine.lua`, `15_Barrens.lua`,
  `18_Stonetalon_Ashenvale.lua`, `G/Classes/Hunter.lua`, `Mage.lua`, `Priest.lua`, `Rogue.lua`, `Shaman.lua`,
  `Warlock.lua`, `Warrior.lua`, `G/Races/Orc.lua`, `Scourge.lua`, `Skyborne.lua`, `Tauren.lua`, `Troll.lua`.
  The headers of `Durotar/02_Durotar.lua` and `Mulgore/03_BarrensCrossing.lua` show the announcement lines the
  P1 agents have to end these files with.

TOC order: `Data.lua`; `Segments\Tirisfal` (2), `Zephras` (3), `Durotar` (2), `Mulgore` (3), `Legacy` (6: `ud_03`,
`ud_04`, `ud_05`, `sd_03`, `sd_04`, `sd_05`), `Shared` (16, level order); `Classes` (9, alphabetical); `Races`
(5, alphabetical); `Route.lua`. 48 Lua files.

### What was done inside the moved files

* Line 1 of every file names its new path; the guard line `if not FastesBoooy.AddLibraryInsert then return end`
  stands in front of the first statement of every file but `Data.lua`.
* `FastesBoooy.AddSegment("<route>", {` -> `FastesBoooy.AddLibrarySegment({` (10 files).
* `FastesBoooy.AddInsert(<route>, {` -> `FastesBoooy.AddLibraryInsert({` with `class = "PALADIN"` / `"DRUID"` as
  the insert's scope line (28 inserts). Every insert step already had an explicit id, so none was added.
* `Segments/Tirisfal/02_Tirisfal.lua` ends with
  `ns.startZones.Tirisfal = { "ud-01-deathknell", "ud-02-tirisfal", only = { "PALADIN" } }`;
  `Segments/Zephras/03_ThunderBluff.lua` holds
  `ns.startZones.Zephras = { "sd-01-zephras", "sd-02-zephras", only = { "DRUID" } }`.
* The `-- WARN-OK` comments (no comment with that marker is left in the repository):

  | Code | Comments | Result |
  |---|---:|---|
  | `xp-unknown` | 151 on a step line, 4 lines of their own | dropped (INFO now). Kept as plain comments where they said more than the code: `6383` and `1422` / `349` (talk quests with 0 XP), `sd01-end` ("both continue in sd-02"), 95350 ("98024 -> sd-04") |
  | `step-no-profile` | 8 on a step line, 2 block comments | dropped (the steps are not composed into the other race's route); the two block comments now say why the steps are race-filtered |
  | `level-grind` | 17 gates | 13 gates: `ok = { ["level-grind"] = N }` (table below); 4 gates: no `ok` (deviation 1) |
  | `at-far-from-giver` | 4 | `ok = "at-far-from-giver"` on `h-22-hillsbrad:22`, `h-24-barrens-stonetalon:84`, `h-27-ashenvale-needles:55`, `:57`; the reason is the comment on the line |
  | `fly-unknown-fp` | 1 | `ok = "fly-unknown-fp"` on `sd03-fly-org` |
  | `segment-level` | 2 | `ok = "segment-level"` on the segments `sd-04-barrens` and `h-22-hillsbrad` (the paladin's acknowledgement moved from the insert step `pal-22-danitha` onto the segment; the reason is the comment above the key) |
  | `train-not-class-trainer` | 1 (`dru-riding`) | dropped: INFO `train-service` since F1b, an `ok` would be `ok-unused` |

  Ceilings: the larger of the two routes' normal-run kills at the gate, rounded up to a multiple of 10.

  | Gate | Kills paladin / druid | `ok` ceiling |
  |---|---:|---:|
  | `ud05-lvl-grind` | 74 / - | 80 |
  | `h-27-ashenvale-needles-level-gate` | 84 / 109 | 110 |
  | `h-31-hillsbrad-arathi-level-gate` | 274 / 273 | 280 |
  | `h-34-stranglethorn-level-gate` | 151 / 152 | 160 |
  | `h38-level-maraudine` | 325 / 325 | 330 |
  | `h39-level-mannoroc` | 684 / 683 | 690 |
  | `h-41-arathi-badlands-level-gate` | 764 / 765 | 770 |
  | `h-44-swamp-stranglethorn-level-gate` | 178 / 177 | 180 |
  | `h48-tanaris-level-gate` (optional) | 28 / 29 (INFO: at most 30) | none (deviation 1) |
  | `h-46-tanaris-feralas-level-gate` | 589 / 589 | 590 |
  | `h-50-hinterlands-searing-steppes-level-gate` | 154 / 154 | 160 |
  | `h55-silithus-field-grind` | 362 / 318 | 370 |
  | `h57-winterspring-grind` | 584 / 584 | 590 |
  | `h-56-felwood-winterspring-plaguelands-level-gate` | 720 / 720 | 720 |

### `Route.lua`

The complete five-race table of A.4 (`CLASSES`, `RACES` with `zone`, `visit`, `classes`, `aliases`), the
announcement with `only`, numeric `for` loops, `RegisterRoute` + `UseSegments` per route. Titles
`<Race>-<class> 1-60` / `<Race> <Class> 1-60` ("Нежить-паладин 1-60", "Undead Paladin 1-60"); the description
names the start zone of the race (`start` in the race row) and the zones of the path, without the faction word
and without "shared" / "library". `version = "0.4.0"`, `faction = "Horde"`, `default = true`.

The only F2a-specific part is marked `LEGACY CHAINS`: the table `LEGACY` (Scourge: `ud-03-silverpine`,
`ud-04-barrens`, `ud-05-stonetalon-ashenvale`; Skyborne: `sd-03-mulgore-silverpine`, `sd-04-barrens`,
`sd-05-stonetalon-ashenvale`), `LEGACY_REPLACES = 3` and one branch in the local function `chain`. For a race
with a legacy entry the chain is start segments + legacy segments + `SILVERPINE_ON` from its fourth entry
(`h-22-hillsbrad`) on; for the others it is already the final chain (start, `VISIT` when `visit`, all of
`SILVERPINE_ON`).

Checked in a scratch run with the loader option `replace` (one-step fixture files for the Durotar, Mulgore and
`h-12` .. `h-18` placeholders, copies of the two announcement files without `only`): 0 load errors, **28 routes**
with the ids, titles, `races` / `classes` of A.4; Orc and Troll `dur-01`, `dur-02`, `h-12`, `h-13` .. `h-56`;
Tauren `mul-01`, `mul-02`, `mul-03`, `h-12`, `h-13` .. `h-56`; aliases `horde-undead-paladin` ->
`undead-paladin`, `horde-skyborne-druid` -> `skyborne-druid`. This is not a spec (the layout spec is F2b's).

### Build and tests

| File | Change |
|---|---|
| `Makefile` | `VALIDATE_FLAGS = --strict --end-level`; `SYNC_ROUTES = undead-paladin skyborne-druid`; `SYNC_MID` unchanged in value (`21/ud-04-barrens,sd-04-barrens 29/h-24-barrens-stonetalon`); new `GUIDES = addons/FastesBoooy_Guides`, `LIB = $(GUIDES)`; the usage text of `make harness`; comments and six header lines (the header keeps its length, so the line range of `make help` still fits). `ROUTE = *undead-paladin` is unchanged |
| `tests/spec/core_sync_spec.lua` | the performance case loads `addons/FastesBoooy_Guides/FastesBoooy_Guides.toc` (one module instead of two) and asserts that the active route is `undead-paladin`; the other assertions are unchanged. New case "the guides module / keeps the former route ids as aliases" (verification round 1) |
| `.github/workflows/ci.yml` | not changed (it names no module, route or segment) |
| `docs/VALIDATION.md` | regenerated (`make report`) |

## 2. Acceptance: commands run and results

| Command | Result |
|---|---|
| `ls addons` | `FastesBoooy`, `FastesBoooy_Guides` |
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 173 files |
| `lua5.1 tools/validate_routes.lua --strict --end-level --summary --grind-until h-22-hillsbrad` | exit 0; `(shared FastesBoooy_Guides) [shared: 22 segment(s), 28 insert(s), 2169 step(s)]`: 0 / 0 / 0; "1 module(s), 0 error(s), 0 warning(s), 36 accepted (strict)" |
| `--summary` lines | `undead-paladin	Scourge PALADIN Horde	0	0	18	0	60.00	60.00	4972	6179	75	160` and `skyborne-druid	Skyborne DRUID Horde	0	0	18	0	60.00	60.00	4878	6082	0	97` |
| composed steps (loader) | **1,713** and **1,748** |
| `make validate` (`--strict --end-level`) | exit 0; both routes 0 ERROR, 0 WARN, 18 accepted; 458 and 513 INFO |
| `lua5.1 tools/simulate_routes.lua --list-routes` | `undead-paladin`, `skyborne-druid` |
| `make simulate` | both `OK` (1,713 / 1,748 steps, level 60; the druid: 13 reward choices checked); 26 s wall |
| `make check` | exit 0, run twice (3 min 34 s and 3 min 37 s wall, 4 CPUs): luacheck 0 / 0; busted **671 successes / 0 failures / 0 errors** (672 since verification round 1); simulate 2 of 2; simulate-sync 16 of 16; fixture simulations 5 of 5; harness fixture 4 runs |
| `make routedata-check` | exit 0 |
| `make report` twice | the second run changes nothing |
| `make package` | exit 0 |

**Identity with the baseline** (taken at HEAD before any change, same tools):

* composed steps: for both routes every step has the same id at the same position, and the normalized step
  tables are equal once three expected differences are removed (the new `ok` keys; `filters = { class = ... }`
  that the insert scope adds to the 52 insert steps, plus `race` on `sd-bridge-fly-tb`; the insert source
  `Inserts.lua` -> `Classes/<Class>.lua`): 0 differing steps of 1,713 and 0 of 1,748;
* validator JSON report: `summary` (end levels, grind normal / worst / bands, gates, quest log, XP sums) and
  `segments` are equal for both routes; the messages are the same multiset (476 and 531; severity, code, step,
  text), 18 WARNs per route are now `accepted`;
* `--levels`: identical lines for both routes (id, segment, level normal / worst, anchor, actions).

The simulator warnings are the known ones of the baseline, unchanged (`sd02-hearth` bind point,
`sd-03-mulgore-silverpine:24` 1061 at level 12, and in the `--level-plus 4` runs
`h-53-azshara-ungoro-silithus:41` 4496).

### Per-segment table (level at the start -> at the end, grind kills normal / worst)

| Segment | File | `undead-paladin` | `skyborne-druid` |
|---|---|---|---|
| `ud-01-deathknell` | `Segments/Tirisfal/01_Deathknell.lua` | 1.00 -> 5.88, 1 / 1 | - |
| `ud-02-tirisfal` | `Segments/Tirisfal/02_Tirisfal.lua` | 5.88 -> 12.78, 0 / 0 | - |
| `ud-03-silverpine` | `Segments/Legacy/ud_03_Silverpine.lua` | 12.78 -> 14.56, 0 / 0 | - |
| `ud-04-barrens` | `Segments/Legacy/ud_04_Barrens.lua` | 14.56 -> 17.99, 0 / 0 | - |
| `ud-05-stonetalon-ashenvale` | `Segments/Legacy/ud_05_Barrens_Stonetalon_Ashenvale.lua` | 17.99 -> 22.06, 74 / 110 | - |
| `sd-01-zephras` | `Segments/Zephras/01_Zephras_1_9.lua` | - | 1.00 -> 9.95, 0 / 0 |
| `sd-02-zephras` | `Segments/Zephras/02_Zephras_9_13.lua` | - | 9.95 -> 13.32, 0 / 0 |
| `sd-03-mulgore-silverpine` | `Segments/Legacy/sd_03_Mulgore_Silverpine.lua` | - | 13.32 -> 15.59, 0 / 0 |
| `sd-04-barrens` | `Segments/Legacy/sd_04_Barrens.lua` | - | 15.59 -> 19.02, 0 / 0 |
| `sd-05-stonetalon-ashenvale` | `Segments/Legacy/sd_05_Barrens_Stonetalon_Ashenvale.lua` | - | 19.02 -> 22.24, 0 / 40 |
| `h-22-hillsbrad` | `Segments/Shared/22_Hillsbrad.lua` | 22.06 -> 25.11, 0 / 49 | 22.24 -> 24.97, 0 / 57 |
| `h-24-barrens-stonetalon` | `Segments/Shared/24_Barrens_Stonetalon.lua` | 25.11 -> 27.51, 0 / 221 | 24.97 -> 27.38, 0 / 229 |
| `h-27-ashenvale-needles` | `Segments/Shared/27_Ashenvale_Needles.lua` | 27.51 -> 31.01, 84 / 313 | 27.38 -> 31.01, 109 / 313 |
| `h-31-hillsbrad-arathi` | `Segments/Shared/31_Hillsbrad_Arathi.lua` | 31.01 -> 34.06, 274 / 326 | 31.01 -> 34.05, 273 / 326 |
| `h-34-stranglethorn` | `Segments/Shared/34_Stranglethorn.lua` | 34.06 -> 36.06, 151 / 152 | 34.05 -> 36.06, 152 / 152 |
| `h-37-desolace-dustwallow` | `Segments/Shared/37_Desolace_Dustwallow.lua` | 36.06 -> 41.02, 1,009 / 1,029 | 36.06 -> 41.01, 1,008 / 1,029 |
| `h-41-arathi-badlands` | `Segments/Shared/41_Arathi_Badlands.lua` | 41.02 -> 44.02, 764 / 918 | 41.01 -> 44.02, 765 / 918 |
| `h-44-swamp-stranglethorn` | `Segments/Shared/44_Swamp_Stranglethorn.lua` | 44.02 -> 46.01, 178 / 185 | 44.02 -> 46.01, 177 / 185 |
| `h-46-tanaris-feralas` | `Segments/Shared/46_Tanaris_Feralas.lua` | 46.01 -> 49.40, 617 / 715 | 46.01 -> 49.40, 618 / 715 |
| `h-50-hinterlands-searing-steppes` | `Segments/Shared/50_Hinterlands_Searing_Steppes.lua` | 49.40 -> 52.57, 154 / 308 | 49.40 -> 52.57, 154 / 308 |
| `h-53-azshara-ungoro-silithus` | `Segments/Shared/53_Azshara_Ungoro_Silithus.lua` | 52.57 -> 55.04, 362 / 391 | 52.57 -> 55.04, 318 / 349 |
| `h-56-felwood-winterspring-plaguelands` | `Segments/Shared/56_Felwood_Winterspring_Plaguelands.lua` | 55.04 -> 60.00, 1,304 / 1,461 | 55.04 -> 60.00, 1,304 / 1,461 |
| total | | 4,972 / 6,179 | 4,878 / 6,082 |

Foreign warnings: none. New step ids: none. New segment ids: none. Renamed: the two route ids (with aliases).
DB overrides: none (`tools/overrides/` holds only its README). New place names: none (`make routedata` prints
no note about a place). `-- CONFIRM` list: empty.

## 3. Deviations from the plan, and why

1. **Four of the 17 `level-grind` gates carry no `ok`**. Three are worst-case only: `h-22-hillsbrad-level-gate`,
   `h-24-barrens-stonetalon-level-gate`, `h55-silithus-grind`. Their old comment was "level-grind (worst
   case)": in the normal run of both routes they need 0 kills, so the validator reports nothing at the step,
   and an `ok` there is WARN `ok-unused`, which fails `--strict`. Each has the comment
   `-- level-grind: worst case only (no `ok`)`. Worst-case kills today: 49 / 57, 221 / 229, 23 / 0.
   A fourth gate, the optional `h48-tanaris-level-gate`, has no `ok` either (verification round 1): it needs
   28 / 29 kills, `level-grind` is a WARN only above 30 kills, and the ceiling the rule gives (30) can accept
   nothing. `ok-unused` does not catch such a key, because the INFO of the same code counts as reported. The
   step has a plain comment instead.
2. **Ceiling rounding.** "Rounded up to the next 10" is implemented as "up to a multiple of 10", so the last gate
   (720 kills in both routes) has the ceiling 720, not 730. One more kill there is an unaccepted WARN.
3. **`dru-riding`: the acknowledgement of `train-not-class-trainer` was dropped**, not converted (it is INFO
   `train-service` since F1b; the plan's list of codes predates that).
4. **The Zephras announcement is in `Segments/Zephras/03_ThunderBluff.lua`**, which is therefore not a pure
   placeholder (header, guard line, `local _, ns = ...`, the announcement; no segment). Reason: A.4 puts the
   announcement into the last segment file of the zone, the Skyborne list has to get `sd-03-thunder-bluff` in
   F2b, and F2b owns `03_ThunderBluff.lua` but may not touch `02_Zephras_9_13.lua`.
5. **`sd-bridge-fly-tb` (the druid's insert before `h-22-tb-start`) has `race = "Skyborne"` next to the class
   scope.** The anchor is a Skyborne-only step, and a class-only insert there is ERROR
   `insert-scope-wider-than-anchor` (A.5.1 rule 10). The step id keeps its old form without the `dru-` prefix
   ("explicit ids stay"); the layout spec of F2b wants the class prefix on every step of a class file, so F2b
   (which owns `Classes/Druid.lua` and rewrites this bridge anyway) has to rename or drop it.
6. **Legacy files are named `ud_03_...` / `sd_03_...`** (two files of the old modules are both called
   `04_Barrens.lua` and `05_Barrens_Stonetalon_Ashenvale.lua`) and stand in the TOC between the start zones and
   `Segments\Shared`.
7. **`Makefile`**: a variable `GUIDES` was added (A.7 has it) and `LIB` is `$(GUIDES)`. Comments that named the
   old modules were reworded; no recipe changed.
8. **Comments.** Only what the move made wrong was touched: line 1 of each file, the two class-file headers
   (first sentence), the two notes "xp-unknown WARN" -> "INFO" in the Zephras headers, one line in `ud_05`. The
   long header comments still say "library", "Inserts.lua" in places and describe the old two-route world; the
   files are rewritten in F2b / F2c.

## 4. Notes for the next phases

### F2b

* **TOC.** F2b deletes `Segments/Legacy/` but its ownership list in D.2 does not name the TOC. The six
  `Segments\Legacy\...` lines of `FastesBoooy_Guides.toc` have to go in the same step (see section 5).
* `Route.lua`: delete the block `LEGACY CHAINS` (`LEGACY`, `LEGACY_REPLACES`) and the `legacy` branch of
  `chain`; what remains is `if r.visit then list[#list + 1] = VISIT end` and the loop over `SILVERPINE_ON`
  from 1. Nothing else in the file depends on the legacy segments.
* `Segments/Zephras/03_ThunderBluff.lua`: add the segment and put `"sd-03-thunder-bluff"` into the
  announcement.
* `Makefile`: `SYNC_MID = 21/h-15-barrens 29/h-24-barrens-stonetalon` (the comment above it names the legacy
  segments). `tests/spec/build_spec.lua` fails with the entry named when `SYNC_MID` names a segment a
  `SYNC_ROUTES` route does not have.
* `tests/spec/core_sync_spec.lua:634-650` now needs only the module path; it asserts
  `GetSyncSuggestion().from.id == "ud-01-deathknell"` for a level-23 Undead paladin.
* The `segment-level` acknowledgement of `h-22-hillsbrad` exists because of the paladin's optional chain
  (`pal-22-*`, estimated XP): 25.11 at the end of the segment on the paladin route, 24.97 on the druid route.
  If the paladin no longer ends above 25, the key becomes `ok-unused`.
  **The key is wider than the comment it replaces.** The old `WARN-OK` stood in the paladin module and covered
  one route. `ok = "segment-level"` on the shared segment has no ceiling and no route filter: it accepts a
  `segment-level` WARN of `h-22-hillsbrad` on every route that contains the segment (all 28 in the end), above
  or below the planned level, by any amount. Today only `undead-paladin` uses it. When F2b reworks the segment
  and when the base routes exist (F2d, P2), read the end level of `h-22-hillsbrad` for every route (the
  per-segment table of each route in the report, section "Маршруты", or the JSON report) and drop the key or
  change the segment's `levels`; do not leave it as a blanket acknowledgement. The same holds for `ok = "segment-level"` on the legacy segment `sd-04-barrens`, which F2b
  deletes.
* The ceilings are tight by construction (table in section 1). The shared 12-22 path changes the level at 22
  and with it the kills at every gate behind it; adjust the ceilings in the same edit.
* Harness on the real module works: from the paladin's state before `h-22-hillsbrad`
  (`--route undead-paladin --write-state F --until h-22-hillsbrad`: level 22.06, 170 quests done) the twelve
  22-60 segments give Scourge PALADIN 4,897 / 6,068 (0 WARN, 17 accepted) and Scourge WARRIOR, the base
  profile, 4,934 / 6,068 with **one unaccepted WARN** (next point).

### F2c, F2d

* **Base profiles exceed one ceiling.** Without class steps the gate `h-27-ashenvale-needles-level-gate` needs
  121 kills (ceiling 110: paladin 84, druid 109). As soon as `only` is removed, every base route of the race
  reports it as an unaccepted WARN on a shared file (foreign for the F2c agents). F2b or F2d should set the
  ceiling to 130 once the numbers of the new 12-22 path are known. All other gates of the base profile are at or
  under the ceilings above (273, 152, 325, 683, 765, 178, 28, 589, 154, 362, 584, 720).
* The four gates without `ok` (deviation 1) need one as soon as a route grinds there in its normal run (more
  than 30 kills is a WARN). `h48-tanaris-level-gate` is the nearest: 28 / 29 kills today.
* The faction word is still in `Segments/Zephras/01_Zephras_1_9.lua` (the Skysight note), in the last step of
  `ud-05` and in header comments; route titles, descriptions and the TOC are clean. F2d owns the check.

### Everyone

* Stale documentation, by owner: `README.md`, `docs/routes/horde-*.md` (F2d); `docs/ARCHITECTURE.md`,
  `docs/ROUTE_FORMAT.md`, `tools/README.md` (phase R, D.6): they still name the three old modules and the old
  route ids in examples and in the sync-results table.
* `make harness` defaults to the guides module: `make harness PROFILE=race=..,class=..,faction=Horde
  SEGMENTS=a,b STATE=f.json`.

### For the atlas (`docs/dev/ATLAS.md`)

* The module now has the shape the atlas can grow in: content registered once (`Segments/`, `Classes/`,
  `Races/`), one generated `Data.lua` for all of it, and `Route.lua` as a table of race rows and class rows
  with localized names. A "guides" list (28 entries with race, class, start zone and zones on the way) can be
  read from that table through `Registry:List(true)` without composing a route.
* The start-zone announcement (`ns.startZones`) is a small "what content is complete" switch inside the
  module; atlas pages that are not ready can use the same idea instead of half-registered content.

## 5. Open issues for the orchestrator

1. **F2b must edit `FastesBoooy_Guides.toc`** (remove the six `Segments\Legacy\...` lines when it deletes the
   directory). D.2 does not list the TOC among the files F2b owns.
2. **Comments in forbidden files still name the old modules / route ids** (no behaviour): the usage text of
   `tools/lib/validator.lua` (the harness example with `--route horde-undead-paladin` and
   `addons/FastesBoooy_Horde`), comments in `tools/lib/harness.lua`, `tools/lib/route_loader.lua`,
   `tools/simulate_routes.lua`. `addons/FastesBoooy/UI/Options.lua` and `tests/spec/core_ui_spec.lua` name
   the old folders on purpose (the obsolete-modules warning).
3. The plan's F2a text says "the 17 `level-grind` gates get a ceiling"; 13 did (deviation 1). The plan can be
   aligned or left.
4. Nothing blocks F2b.

## 6. Verification round 1

Five findings of the independent verification, all minor. Two led to a change in the F2a files, one to a
comment and a note, two are real but lie in files F2a may not edit (they are open issues 5 and 6 below).

| # | Finding | Verdict | Change |
|---|---|---|---|
| 1 | Stale tool documentation: `tools/README.md:45` says `VALIDATE_FLAGS` is "сейчас пусто", `:47` says `SYNC_ROUTES` is "сейчас `horde-undead-paladin horde-skyborne-druid`"; the harness example of `lua5.1 tools/validate_routes.lua --help` (`tools/lib/validator.lua:2820-2821`) uses `--route horde-undead-paladin` and `--harness addons/FastesBoooy_Horde` | **Real**, checked in the files. Not an F2a file (`tools/**` is forbidden in F2, `tools/README.md` belongs to phase R) | None in code. Listed with the exact lines as open issue 5 |
| 2 | With the old three folders still installed next to the new release, the aliases do not work: the old module registers the real id `horde-undead-paladin` / `horde-skyborne-druid` after `FastesBoooy_Guides` (alphabetical load order), and `Registry:RegisterRoute` drops the alias (`addons/FastesBoooy/Core/Registry.lua:85-88`, "a route id always wins over an alias"). An auto-selected character restarts at the top of the new route; a character with a manual choice stays on the old route, which also receives the shared inserts of `Classes/Paladin.lua` (duplicate step ids, registry errors). No Lua error; correct again once the folders are deleted | **Real**, by the code of the registry (the rule is written there on purpose) and `Engine.adoptAliases`, which only adopts ids that are still aliases. A property of the core, not of the F2a files: `Route.lua` declares the aliases as A.4 says | None in code. Open issue 6: a decision for the orchestrator |
| 3 | `ok = "segment-level"` on the shared segment `h-22-hillsbrad` is wider than the paladin-only `WARN-OK` it replaces (any route, either direction, no ceiling; `tools/lib/validator.lua:1524-1530`, `V.OkAccepts`) | **Real**. The move is ordered by D.2 F2a step 5 and the key has no narrower form, so the key stays | Comment above the key in `Segments/Shared/22_Hillsbrad.lua` now states the scope and what to check; section 4 (F2b) of this file says the same |
| 4 | `ok = { ["level-grind"] = 30 }` on `h48-tanaris-level-gate` can accept nothing (WARN only above 30 kills, ceiling 30; INFO today with 28 / 29 kills) | **Real** (`validator.lua:75`, `:1352`, `V.OkAccepts`; the step was not among the 18 accepted messages of either route) | Key removed, plain comment instead (`Segments/Shared/46_Tanaris_Feralas.lua`); the gate matrix of `docs/VALIDATION.md` shows "—" in the ceiling column for this gate (the only line of the report that changed). Sections 1, 3 and 4 of this file updated: 13 gates with a ceiling, 4 without |
| 5 | No spec pins the two aliases of the real module | **Real** (`grep` in `tests/`: the old ids occur only in `core_ui_spec.lua`) | New case in `tests/spec/core_sync_spec.lua`, describe "the guides module": boots the core with `FastesBoooy_Guides` and character data saved under the old id (manual route, cursor hint, sync floor, dismissal), once for `horde-undead-paladin` and once for `horde-skyborne-druid` as a manual choice of an Undead paladin. Asserts no registry error, `Registry:Get(<old id>).id`, the active route, and that `cdb.route`, `cursorHintRoute`, `syncFloor.route`, `syncFloor.hint[3]`, `syncDismissed.route` hold the new id and the floor is valid again. Checked by mutation: with either `aliases` line removed from `Route.lua` the case fails. It uses the step `h-27-ashenvale-needles-level-gate`, an explicit id of the shared path that later phases may not rename |

Open issues added (continuing the list of section 5):

5. **Stale tool documentation** (owner: orchestrator or phase R). `tools/README.md:45`: `VALIDATE_FLAGS` is now
   `--strict --end-level`; `:47`: `SYNC_ROUTES` is now `undead-paladin skyborne-druid`.
   `tools/lib/validator.lua:2820-2821` (the `--help` text): the example should read `--route undead-paladin`
   and `--harness addons/FastesBoooy_Guides`; as printed it fails, the folder does not exist.
6. **Updating with the old folders left in place** (owner: orchestrator; core or README). Either an alias that
   exists wins over a later `RegisterRoute` of the same id (the obsolete module's route is ignored, the alias
   stays), or the README paragraph "Updating from 0.3" (F2d) says that the three old folders must be deleted
   before the first login with 0.4. A.8 describes this state only as "duplicate segment errors, the first
   default route wins".

Acceptance after the changes:

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 173 files |
| `lua5.1 tools/validate_routes.lua --strict --end-level --summary --grind-until h-22-hillsbrad` | exit 0; the output is byte-identical to the one before the round: "1 module(s), 0 error(s), 0 warning(s), 36 accepted (strict)"; `undead-paladin ... 0 0 18 0 60.00 60.00 4972 6179 75 160`, `skyborne-druid ... 0 0 18 0 60.00 60.00 4878 6082 0 97` |
| `make check` | exit 0, 3 min 46 s: luacheck 0 / 0; busted 672 successes / 0 failures / 0 errors; `make validate` 0 ERROR, 0 WARN, 18 accepted per route; simulate 2 of 2 `OK` (1,713 and 1,748 steps, level 60); simulate-sync 16 of 16; fixture simulations 5 of 5; harness fixture 4 runs |
| `make routedata-check` | exit 0 (`Data.lua` unchanged) |
| `make report`, twice | one line of `docs/VALIDATION.md` changed (the ceiling of `h48-tanaris-level-gate`); the second run changes nothing |
| `make package` | exit 0 |
| `ls addons` | `FastesBoooy`, `FastesBoooy_Guides` |
