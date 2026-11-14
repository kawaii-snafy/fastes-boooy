# Hand-over F2d: the migration is finished (11 routes, layout spec, README and route documents)

Phase F2d of `docs/dev/PLAN.md` (D.2, step F2d; A.8, B.8, C.7, 0.1). Nothing was committed and no git command
that changes state was run (the orchestrator commits; `git add -A addons docs Makefile README.md tests` takes
everything of this phase, including the three deleted route documents). `G` = `addons/FastesBoooy_Guides`.

State: 11 routes (six Undead, five Skyborne), `make validate` is `--strict --end-level` plus the 120 / 200 grind
budget up to the end of `h-18`, the base-profile command of the plan exits 0, the layout spec holds the anchor
tables of both start zones and the faction-word check, the user documentation describes two folders and the new
structure.

## 1. What changed

| File | Change |
|---|---|
| `G/Classes/Druid.lua` | the level-40 block is two inserts now: `dru-40-fly-tb`, `dru-40-train` after `h-40-org-arrive`; `dru-40-fly-taurajo` as an insert of its own `before = "h-38-orgrimmar-flight-master"` (deviation 1). Header table and comments. The three ids are unchanged |
| `G/Races/Skyborne.lua` | the druid riding insert (`sky-40d-*`) is anchored `after = "h-40-org-arrive"` instead of `after = "dru-40-train"` (deviation 1); comments |
| `G/Segments/Shared/50_Hinterlands_Searing_Steppes.lua` | the Honey Ripples step (`complete = 77`) has the explicit id `h50-honey-ripples` (it was `h-50-hinterlands-searing-steppes:21`; allow-list of the faction-word check); a header comment names `docs/routes/shared-path.md` |
| `G/Segments/Shared/56_Felwood_Winterspring_Plaguelands.lua` | a header comment names `docs/routes/shared-path.md` |
| `Makefile` | `VALIDATE_FLAGS = --strict --end-level --max-grind-until h-18-stonetalon-ashenvale=120/200`, its comment and the `make validate` line of the header; `make help` prints lines 4-38 (the header grew by one line) |
| `tests/spec/guides_layout_spec.lua` | 23 -> 32 cases (section 3) |
| `README.md` | two folders, the list of guides (11 available, 17 in progress), installation, "Обновление с 0.3", links to the new route documents; no faction word in a guide name |
| `docs/routes/shared-path.md` | new (from `horde-22-60.md`, extended by 12-22): 917 lines |
| `docs/routes/race-undead.md`, `race-skyborne.md` | new: start zone, anchors, gates, race steps on the shared path, riding, the full step list of the zone with levels |
| `docs/routes/class-paladin.md`, `class-druid.md` | new: training, every insert with anchor and level, talents, class quests, weapons / rewards |
| `docs/routes/horde-22-60.md`, `horde-undead-paladin.md`, `horde-skyborne-druid.md` | deleted |
| `docs/VALIDATION.md` | regenerated (`make report`) |
| `G/Data.lua` | regenerated (`make routedata`); the content did not change |

Not changed although owned: `tools/gen_route_data.lua` (`make routedata` reports no place without a ruRU name),
`tools/overrides/shared.lua` (nothing to add), `Route.lua`, the TOC, the Tirisfal and Zephras segments, the other
class and race files.

## 2. Acceptance: commands run and results

All on the final tree.

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons/FastesBoooy_Guides` | 0 warnings / 0 errors in 42 files |
| `busted tests/spec/guides_layout_spec.lua tests/spec/core_sync_spec.lua` | 69 successes / 0 failures / 0 errors (32 + 37) |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --max-grind-until h-18-stonetalon-ashenvale=120/200 $G` | exit 0: 11 routes, "1 module(s), 0 error(s), 0 warning(s), 188 accepted (strict)"; end level 60.00 / 60.00 for every route; summary lines below |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --route 'undead-*,skyborne-*' --skip 'Classes/*' $G` | **exit 0** (it was exit 1 with `ERROR insert-anchor-unknown` since F2b): shared content 0 ERROR / 0 WARN, 11 base routes 0 ERROR / 0 WARN, 186 accepted; Undead 4,982 / 6,217, Skyborne 4,914 / 6,129 |
| `lua5.1 tools/simulate_routes.lua --route 'undead-paladin,skyborne-druid,undead-warrior,skyborne-shaman' $G` | 4 of 4 `OK` (1 min 41 s): 1,754 / 1,784 / 1,696 / 1,721 steps, level 60; warnings: only the two known ones of the Skyborne routes (`sd02-hearth` bind point, optional `sky-1061` at level 12 in the simulator's quest-XP-only model) |
| the five harness proofs of F2b (cases of the layout spec) | pass: Orc WARRIOR and Troll PRIEST 72 / 174, the three Tauren runs 38 / 138 kills up to the end of `h-18` (unchanged) |
| `make routedata-check`; report freshness (`--markdown` output equals `docs/VALIDATION.md`) | exit 0; equal |
| `make check` | see the end of this section |

Limits of the acceptance, read from `--summary`: `undead-paladin` 4,902 / 6,173 (limit 4,972 / 6,179),
`skyborne-druid` 4,852 / 6,052 (limit 4,878 / 6,082). Budget up to the end of `h-18` (120 / 200): the largest
value is the base Undead with 47 / 147.

### summary lines (route, profile, errors, warnings, accepted, foreign, end level, worst, grind, worst, up to `h-18`, worst)

```
undead-mage	Scourge MAGE Horde	0	0	16	0	60.00	60.00	4982	6217	47	147
undead-paladin	Scourge PALADIN Horde	0	0	17	0	60.00	60.00	4902	6173	5	103
undead-priest	Scourge PRIEST Horde	0	0	16	0	60.00	60.00	4982	6217	47	147
undead-rogue	Scourge ROGUE Horde	0	0	16	0	60.00	60.00	4982	6217	47	147
undead-warlock	Scourge WARLOCK Horde	0	0	16	0	60.00	60.00	4982	6217	47	147
undead-warrior	Scourge WARRIOR Horde	0	0	16	0	60.00	60.00	4982	6217	47	147
skyborne-druid	Skyborne DRUID Horde	0	0	19	0	60.00	60.00	4852	6052	0	24
skyborne-hunter	Skyborne HUNTER Horde	0	0	18	0	60.00	60.00	4914	6129	0	59
skyborne-rogue	Skyborne ROGUE Horde	0	0	18	0	60.00	60.00	4914	6129	0	59
skyborne-shaman	Skyborne SHAMAN Horde	0	0	18	0	60.00	60.00	4914	6129	0	59
skyborne-warrior	Skyborne WARRIOR Horde	0	0	18	0	60.00	60.00	4914	6129	0	59
```

No number of a route moved in this phase: the composed routes are the same step for step (`--levels` of all
eleven routes compared before and after the level-40 change: the only difference is the anchor column of the six
steps `sky-40d-*` and `dru-40-fly-taurajo`). The per-segment tables and the gate tables are in
`docs/VALIDATION.md` and, with the base profile next to the class route, in `docs/routes/shared-path.md` (sections
2, 3.6, 6), `race-undead.md`, `race-skyborne.md`, `class-paladin.md`, `class-druid.md`.

### `make check`

Exit 0, 8 min 31 s wall on 4 CPUs (other runs were going on beside it), on the final tree of `addons/`, `tools/`,
`tests/` and `Makefile` (only `docs/routes/shared-path.md` and this file were edited afterwards; no check reads them):

* luacheck: 0 warnings / 0 errors in 176 files;
* busted: **704 successes** / 0 failures / 0 errors (695 after F2b; + 9 cases of the layout spec);
* `make validate` (with the new `VALIDATE_FLAGS`): 0 ERROR, 0 WARN, 188 accepted (strict);
* `make simulate`: 11 of 11 routes passed; `make simulate-sync`: 16 of 16 runs passed (`undead-paladin`,
  `skyborne-druid`); fixture simulations 5 of 5; the harness fixture runs pass; `validate-fixtures` as before
  (0 errors);
* simulator warnings: only the three known ones (`sd02-hearth` bind point, the optional `sky-1061` at level 12,
  `h-53-azshara-ungoro-silithus:41` in the two `--level-plus 4` runs).

## 3. The layout spec (`tests/spec/guides_layout_spec.lua`)

New or changed cases:

* **Anchor tables of Tirisfal and Zephras** (`ANCHORS`): the lists of the two F2c hand-overs (C.2 anchors and the
  further steps the paladin and druid files are anchored on), plus `h-40-org-arrive`,
  `h-38-orgrimmar-flight-master`, `h-41-uc-arrive` (level-40 anchors). All must exist and be unfiltered.
* **Explicit ids**: `ud-01`, `ud-02`, `sd-01`, `sd-02` joined `EXPLICIT_IDS`; in addition every registered segment
  except `h-24` .. `h-56` is held to the rule, so the Durotar and Mulgore segments are covered as soon as they
  register (a P1 agent sees it for its own files).
* **No `only`**: the case that compares the registered routes with the announcements fails on an `only` key and
  when Tirisfal or Zephras has not announced itself. The exemption of the `reward` case is gone. The 28-route
  case replaces only the zones that are still placeholders by fixture files (Durotar, Mulgore): Tirisfal and
  Zephras are taken as they are.
* **Class-neutral start zones** (new): no step of the Tirisfal and Zephras segments carries a class or race
  filter, a `train` action or a `reward`. Durotar is not in that list on purpose (the 792 class branch, R4).
* **98389** (new, E.6; asked for by the Tirisfal hand-over): the three steps that name the quest are `optional`
  and share a step with no action of another quest.
* **Start-zone gates** (`START_GATES`): plain, mandatory, unfiltered `level` steps, like the gates of 12-22.
* **The faction word** (new block, 5 cases; 0.1 item 2): none in the `##` lines of the TOC, in route titles and
  descriptions, in segment titles; in step notes (also `spells` texts) only for something of the game world:
  the ids of `FACTION_WORD_STEPS` (`h44-deadwind-road`, `h48-whitereach`, `h50-honey-ripples`,
  `h-51-swamp-of-sorrows`, `h-53-azshara-arrive`: the five uses the plan names) or a step whose English note names
  a quest / NPC / object / item of the DB snapshot with "Horde" in its name (deviation 2). One case pins the
  matcher (Russian case forms; "Ордена", "Гордан", "Лордерона" do not match), one that every listed step exists and
  still carries the word. A further case forbids "shared" / "общий путь" / "общий маршрут" in a note (A.1).
* **Level 40** (rewritten): the druid file has `dru-40-fly-tb`, `dru-40-train` after `h-40-org-arrive` and
  `dru-40-fly-taurajo` before `h-38-orgrimmar-flight-master`; the riding insert of a race file for druids is
  `after = "h-40-org-arrive"`, class DRUID, optional steps `<race>-40d-...`; the composed order in every druid
  route with such an insert is arrive, fly, train, riding steps, fly on, next shared step. New case: no insert of
  a segment or race file is anchored on a step of a class file.
* **Base profiles** (tightened, as its comment asked): the validator with `--skip 'Classes/*'` exits 0, prints no
  ERROR and no note, every base route ends at 60.00 / 60.00.

Mutation-tested on the real files (each restored afterwards): a faction word in a note of `h-13`; `only` in the
Zephras announcement; the race insert anchored on `dru-40-train`; 98389 mandatory; a positional id in `ud-01`; a
`train` step in `ud-01`. Each fails the case that is meant to catch it. The spec passes with the F2c and the P1
environment lines (`GUIDES_SKIP` / `GUIDES_OWN`): 19 successes each.

## 4. Deviations from the plan, and why

1. **C.7: the druid riding insert of a race file is anchored on the shared step, not on `dru-40-train`.** This
   resolves open issue 5 of the F2b hand-over (the plan contradicts itself: C.7 fixes the anchor
   `after = "dru-40-train"`, A.6.2 counts every loaded file as own without `--own`, and the base-profile commands
   of F2d / P2 / appendix 2 skip the class files, so the anchor is the id of no loaded step: `ERROR
   insert-anchor-unknown`, exit 1). The tool is not mine and the acceptance of F2d wants the literal command to
   exit 0, so the contradiction is removed on the side I own: the insert of `Races/Skyborne.lua` is
   `after = "h-40-org-arrive"` (class DRUID), and the druid's third step `dru-40-fly-taurajo` is an insert of its
   own `before = "h-38-orgrimmar-flight-master"` (the step right behind `h-40-org-arrive`). At one anchor the order
   is class file, then race file (A.2, C.3 rule 6), so the composed route is unchanged: `h-40-org-arrive`,
   `dru-40-fly-tb`, `dru-40-train`, `sky-40d-*` (5), `dru-40-fly-taurajo`, `h-38-orgrimmar-flight-master`. It also
   removes the one planned use of "an insert anchored on the last step of another file's insert" and the ordering
   quirk of `Compose.lua` that goes with it. Consequences:
   * **PLAN.md C.7 should be aligned** (two lines: the druid inserts of Tauren and Skyborne are
     `after = "h-40-org-arrive"`, `class = "DRUID"`; the druid file keeps `dru-40-fly-taurajo` as a separate
     `before` insert). P2 writes the Tauren insert that way; with `after = "dru-40-train"` the layout spec and the
     base-profile command fail.
   * The druid's class agent (phase C) must keep the two inserts apart and must not register another druid insert
     `before = "h-38-orgrimmar-flight-master"` in front of `dru-40-fly-taurajo`.
   * In a base-profile run (`--skip 'Classes/*'`) the route `skyborne-druid` shows the five optional riding steps
     right after `h-40-org-arrive`, without the flight to Thunder Bluff of the skipped druid file. That is an
     artefact of the run (the class file is always loaded in the game); the validator reports nothing for it.
   * The patch for the tool that the F2b hand-over holds (option A) is not needed any more; it would not conflict.
2. **The faction-word check allows more than the id list of the plan.** D.2 says "in step notes only on the step
   ids of an allow-list table". The spec has that table, and in addition accepts a step whose English note names
   a quest, NPC, object or item of the DB snapshot with "Horde" in its name (the Russian note of the same step may
   then translate it). Reason: the path agents of P1 and the class agents may not edit the spec, and 0.1 item 2
   keeps such names ("Conscript of the Horde", "The New Horde"). A use for a place ("the Horde camp") still needs
   an entry in `FACTION_WORD_STEPS`: the failure message says so and tells the agent to report the step id.
3. **One step of `h-50` got an explicit id in this phase** (`h50-honey-ripples`). B.7 leaves new ids in 24-60 to
   P2. The allow-list of the faction-word check is keyed by step id, and a positional id in it would rot with the
   first reorder. No other positional id shifts (positional ids are positions in the segment). A saved mark on
   `h-50-hinterlands-searing-steppes:21` becomes a dead entry (the safe direction, A.8).
4. **The two fixture replacements of the 28-route case are no longer used**, but the files stay:
   `tests/fixtures/guides/FastesBoooy_StartZones/Segments/Tirisfal/02_Tirisfal.lua` and
   `.../Zephras/03_ThunderBluff.lua` are not files of F2d. They are unused now and can be deleted by the
   orchestrator (nothing reads them: checked with grep on `tests/` and `tools/`).
5. **The base-profile case of the spec runs without `--strict`** (as before). The strict gate for base profiles is
   the F2d / P2 command; the case is about ERRORs and template findings and would otherwise fail on the first
   unaccepted WARN of a base route in a checkpoint commit of a parallel phase.
6. **The engine scenario for 98389 is not a spec case.** The Tirisfal hand-over offered it ("F2d can turn this
   into a case of a spec it owns"). The layout spec loads the module through the loader, not the mock client; the
   structural case of section 3 pins what the scenario depends on (three optional steps, no shared action). An
   engine case belongs in `tests/spec/core_sync_spec.lua` or a new spec (phase R).
7. **Route documents: restructured, not rewritten from zero.** Tables with levels, kills, gates, anchors, inserts
   and step lists are generated from the validator (`--json`, `--levels`) and the loader on the final tree. The
   hub narratives of 1-22 are new (written from the segment headers; every quest id in them was checked against
   the steps of the segment by script). Sections that are still true are carried over from the three old documents
   with the old step ids mapped to the new ones (22-60 hub order, travel, dungeons, Forever notes, talents,
   training "what and why", riding, weapons, decisions); every backticked step id in the five documents was checked
   against the module (the only unknown ones are the two removed gates named in the history section). The history
   of versions 0.2-0.3 is kept in `shared-path.md`, section 11, marked as such. The scripts that built the
   documents are scratch files, not part of the repository: the numbers in `docs/routes/*.md` do not follow later
   changes by themselves (`docs/VALIDATION.md` does); every document says so in its first paragraph.
8. **`ok = "segment-level"` on `h-22-hillsbrad` is unchanged.** The F2a hand-over asks to review it when the base
   routes exist: both class routes end the segment above 25 (25.10, 25.12), the base routes at 24.82 / 24.98. The
   key is used, so it is not `ok-unused`; P2 decides with all five races (F2b hand-over, P2 list).
9. **`SYNC_ROUTES` is unchanged** (`undead-paladin skyborne-druid`): A.7 gives the final list to P2, and the base
   routes fail the `--ahead 48` run (section 6, item 2).

## 5. Foreign warnings, overrides, `-- CONFIRM`, place names

* Foreign warnings of the two F2c hand-overs: **none** existed (both columns report 0); `make validate` was
  already clean. What F2c left open and what happened to it:
  * base-profile `insert-anchor-unknown` (`sky-40d-path`): solved (deviation 1);
  * the `--ahead 48` failure of every base route: still open, not a file of this phase (section 6, item 2);
  * 98389 offered to every class? Still `-- CONFIRM` (`ud01-aramis`); the spec pins the safe shape;
  * the two trainer-hub questions of Zephras (a gate at 6 in Shen'dar, a level-10 gate before the first Valanaar
    visit) and `h13-lvl-14` for the Undead (19 / 20 kills): left to P2 as the hand-overs say; no route needs them;
  * 94489 for a class without a heal: `-- CONFIRM` (`sd02-wounded`), the note names the way out.
* DB overrides: none added. XP values for quests I may not override: none. New place names: none.
* `-- CONFIRM` list: unchanged from F2b / F2c (`h15-xr-arrive`, `sd03-fly-org`, `pal-train-14/18/20/22`,
  `ud01-aramis`, `sd02-wounded`, `sky-40-riding` / `sky-40d-riding`, the reward indexes of the paladin).
* Facts that fit no step and were kept for the atlas (`docs/dev/ATLAS.md`): the trainer positions of Deathknell,
  Brill, Thendal Grove, Shen'dar, Valanaar and Skywatcher Plateau are in `race-undead.md` section 3 and
  `race-skyborne.md` section 3; the riding evidence (Genn Fairweather, price, skycutter) in `race-skyborne.md`
  section 6; the dungeon quest blocks in `shared-path.md` section 7.

## 6. Open issues for the orchestrator

1. **PLAN.md C.7** differs from the tree (deviation 1). P2 and the druid's class agent need the new wording; the
   layout spec enforces it either way.
2. **`--ahead 48` fails for every base route** (F2c hand-overs; core `Engine:ComputeSyncSuggestion` or the
   cold-start check of the simulator; D.0 rule 6). Reproduced on the final tree: `lua5.1 tools/simulate_routes.lua
   --route undead-warrior --ahead 48 $G` -> `FAIL ... cold start with empty SavedVariables: cursor on step 1028
   h-44-swamp-stranglethorn:19 [accept 1424], but step 1696 h-60-end is already done`. `make check` is not
   affected (`SYNC_ROUTES` holds the two class routes, which have steps behind `h-60-end`); `make
   simulate-sync-full` (nightly) fails for the nine base routes until the core is fixed or each class has a step
   behind `h-60-end`.
3. **Two unused fixture files** (deviation 4) can be deleted.
4. **Stale documentation outside this phase** (phase R, as the F2a hand-over lists): `docs/ARCHITECTURE.md`,
   `docs/ROUTE_FORMAT.md`, `tools/README.md` still name the three old modules and route ids in examples; the usage
   text of `tools/lib/validator.lua` too. None of them links to the deleted route documents (checked).
5. **README** says honestly that nine of the eleven guides have no class steps yet and that Orc, Troll and Tauren
   get no guide yet. It needs a line per phase when that changes (P1 / P2: the 17 routes; C: class steps).

## 7. Notes for the next phases

### P1 (Durotar, Mulgore)

* The layout spec checks your segments as soon as they register: every step needs an explicit id; a note may not
  contain "Horde" / "Орда" unless it names a quest / NPC / object of the DB (English note) or the step id is in
  `FACTION_WORD_STEPS`; the insert rules are as before. The line of D.3 (`GUIDES_SKIP` / `GUIDES_OWN`) passes on
  the placeholders (19 cases).
* The 28-route case switches from the fixture zone to your real zone as soon as your last file announces it.

### P2

* `Races/Tauren.lua`: the druid riding insert is `after = "h-40-org-arrive"`, `class = "DRUID"`, ids
  `tau-40d-...`, all optional (deviation 1). The case "keeps the level-40 contract" then checks the composed order
  for `tauren-druid` too.
* `h15-xr-arrive` needs `ok = "db-override-unverified"` with the first Tauren route (F2b hand-over; the spec
  demands it).
* `VALIDATE_FLAGS` already carries the 120 / 200 budget; the Orc / Troll proofs are at 72 / 174.
* `docs/routes/shared-path.md` has rows "в работе" for Durotar and Mulgore (section 1) and a sentence about the
  `fp` filters of `h15-fp-xroads` / `h15-fp-taurajo` (section 3.5): update them with the zones.

### Phase C

* `docs/routes/class-<class>.md` is the shape for a class document: training table, every insert with anchor and
  level (`--levels`), talents, class quests. `class-paladin.md` and `class-druid.md` are the two examples.
* A class file may not anchor on a positional id and a race file may not anchor on a class step (spec).
* The druid's level-40 inserts: section 4, deviation 1.

### Phase R

* Regenerate the tables of `docs/routes/*.md` or cut them down to what `docs/VALIDATION.md` does not have; the
  generated numbers are those of this phase.
* The engine scenario of 98389 (deviation 6) and the unused fixtures (deviation 4).
