# Hand-over F2c, Zephras agent: the Skyborne start zone is class-neutral

Phase F2c of `docs/dev/PLAN.md` (D.2, step F2c, right column; B.1, B.2, B.8, C). Nothing was committed (the
orchestrator commits). `G` = `addons/FastesBoooy_Guides`. The three Zephras segments hold no class step, no
`reward` and no positional id any more; the druid's steps of levels 1-13 are shared inserts in `Classes/Druid.lua`;
the announcement has no `only`, so five Skyborne routes are registered: `skyborne-druid` and the four base routes
`skyborne-hunter`, `skyborne-rogue`, `skyborne-shaman`, `skyborne-warrior` (their class files are placeholders).

Files I changed (all of them owned by this column): `G/Segments/Zephras/01_Zephras_1_9.lua`,
`02_Zephras_9_13.lua`, `03_ThunderBluff.lua`, `G/Classes/Druid.lua`, `G/Races/Skyborne.lua`, this file. Not
created: `tools/overrides/zephras.lua`, `tools/overrides/druid.lua` (nothing to override). No git command that
changes state was run. No `make` target was run.

## 1. What changed

| File | Change |
|---|---|
| `Segments/Zephras/01_Zephras_1_9.lua` (`sd-01-zephras`) | 91 -> 85 steps. Every step has an explicit id (76 new `sd01-*` ids; the 9 existing ids of steps that stay are unchanged). The mixed Rorian step is split: `sd01-rorian` keeps 92461 + 92474 -> 92464, the accept of 92485 went to the druid file. Removed (moved to the druid file): the turn-in of 92485, training 1 / 4 / 6 / 8, the Walking Stick vendor. The 9 `reward` fields and their "picked automatically" notes are gone. Reworded: the first-kills note (no "Wrath, then melee"), the Vulgara note (no druid spells, no "mana": "start at full health"), the High Order Apprentices note ("casters", without the melee advice; both after verification round 1), the Skysight note (no faction word: "Racial quest: Skysight"), the hearth note (no segment id in the text). Header rewritten |
| `Segments/Zephras/02_Zephras_9_13.lua` (`sd-02-zephras`) | 71 -> 58 steps. Every step has an explicit id (49 new `sd02-*` ids + 2 new steps). Removed (moved to the druid file): the Greatstaff vendor, the whole Bear Form block (accept, training 10, five `go` steps, Urs'endris twice, the kill of Ur'endra), training 12, the plateau trainer, the accept of 94911. The gate is a plain step now: `sd02-aamelia-3` (turn-in of 92685) + `sd02-level-10` (`level = 10`, class-neutral note, `at` at the galestriders and vuldren between the orchard and Valanaar). New anchor step `sd02-valanaar-10` (`go`, the second Valanaar visit). The 4 `reward` fields are gone. Reworded: the segment title (no "Bear Form"), the notes of `sd02-nyalah`, `sd02-parts-lightning`, `sd02-parts-gyrozephyr`, `sd02-wounded` (94489, see `-- CONFIRM`), `sd02-end`. Header rewritten |
| `Segments/Zephras/03_ThunderBluff.lua` (`sd-03-thunder-bluff`) | the announcement is `{ "sd-01-zephras", "sd-02-zephras", "sd-03-thunder-bluff" }` (no `only`); header comment. The four steps are unchanged |
| `Classes/Druid.lua` | + the class reward table (`FastesBoooy.AddLibraryData({ rewards = { DRUID = { 13 quests } } })`); + 9 inserts, 23 steps, `class = "DRUID"`, `race = "Skyborne"`, ids `dru-zep-*` (table below). Header: the Zephras table with levels, the 22-60 levels re-measured. Two user-visible notes no longer say "shared path" (`dru-cat-hearth-tb`, a text of F2b) |
| `Races/Skyborne.lua` | + the riding trip of the four non-druid classes: one insert `after = "h-40-org-arrive"`, `race = "Skyborne"`, `class = { "HUNTER", "ROGUE", "SHAMAN", "WARRIOR" }`, 7 steps, all `optional`: `sky-40-fly-tb`, `sky-40-path`, `sky-40-skycutter`, `sky-40-riding`, `sky-40-back`, `sky-40-tb`, `sky-40-fly-taurajo` (C.7). Header |

### Where the druid's steps went (old id -> new id, anchor)

| Old step (`sd-01` / `sd-02`) | New step(s) in `Classes/Druid.lua` | Anchor |
|---|---|---|
| accept of 92485 inside the Rorian step | `dru-zep-letter` | after `sd01-rorian` |
| `sd01-92485`, `sd01-train-1` | `dru-zep-xyton`, `dru-zep-train-1` | after `sd01-rorian` |
| `sd01-train-4` (optional) | `dru-zep-train-4` (optional) | after `sd01-rorian-4` |
| `sd01-train-6` | `dru-zep-train-6` (its note also carries the druid's advice for the High Order Apprentices and for the elite Vulgara, which the old route had on the generic steps: it is the druid step in front of both fights, and Thorns is learned here) | after `sd01-raan-2` |
| `sd01-train-8` (optional), the Walking Stick vendor (optional) | `dru-zep-train-8`, `dru-zep-staff-1` (both optional) | after `sd01-danarii-2` |
| the Greatstaff vendor (optional) | `dru-zep-staff-2` (optional) | after `sd02-endaria` |
| `sd02-bear-accept`, `sd02-train-10`, two `go`, `sd02-bear-quest`, `go`, the kill of Ur'endra | `dru-zep-bear-accept`, `dru-zep-train-10`, `dru-zep-bear-north`, `dru-zep-bear-cliff`, `dru-zep-bear-spirit`, `dru-zep-bear-exit`, `dru-zep-bear-kill` | after `sd02-valanaar-10` |
| `go` (ridge), `sd02-bearform`, two `go` (basin exit, north) | `dru-zep-bear-ridge`, `dru-zep-bear-form`, `dru-zep-bear-exit-2`, `dru-zep-bear-lake` | after `sd02-fendaal-2` |
| `sd02-train-12` | `dru-zep-train-12` | after `sd02-lotheluum-2` |
| `sd02-train-12-plateau` (optional), the accept of 94911 | `dru-zep-train-12-plateau` (optional), `dru-zep-child-accept` | after `sd02-plateau` |
| 13 `reward` fields | class reward table: 92461 = 1, 92463 = 3, 92469 = 1, 92470 = 2, 92473 = 1, 92517 = 3, 92528 = 1, 93318 = 1, 92550 = 3, 92579 = 3, 92684 = 3, 93165 = 1, 93172 = 1 | - |

The old ids are not reused. The druid route is the same walk as before, step for step: the composed route has
1,784 steps (1,781 before: + `dru-zep-letter`, + the split gate, + `sd02-valanaar-10`), and the level before every
step id that exists in both versions is identical (746 common ids compared with `--levels`; the one difference is
`sd02-level-10`, 11.13 -> 11.21, because the turn-in of 92685 now stands in front of the gate).

## 2. Acceptance: commands run and results

`F` = `--skip 'Segments/Tirisfal/*' --skip 'Classes/Paladin.lua' --skip 'Races/Scourge.lua' --own
'Segments/Zephras/*' --own 'Classes/Druid.lua' --own 'Races/Skyborne.lua'` (the mirror image of the Tirisfal
column). All runs on the final state of my files.

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Segments/Zephras $G/Classes/Druid.lua $G/Races/Skyborne.lua` | 0 warnings / 0 errors in 5 files |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --route 'skyborne-*' <F> $G` | exit 0: shared part 0 ERROR / 0 WARN; five routes 0 ERROR, 0 WARN, 0 foreign warnings; 19 accepted (druid), 18 accepted (each base route); end level 60.00 / 60.00; "1 module(s), 0 error(s), 0 warning(s), 91 accepted (strict)". The 12 notes are `shared-step-unused` for the Scourge-filtered steps of `h-13` .. `h-18` (their routes are in the skipped Tirisfal files) |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --route skyborne-druid --max-grind-until h-56-felwood-winterspring-plaguelands=4878/6082 <F> $G` | exit 0: **4,852 / 6,052** (limit 4,878 / 6,082; unchanged from F2b) |
| `lua5.1 tools/validate_routes.lua --route skyborne-shaman --levels <F> $G` | exit 0, 832 lines (section 4) |
| `lua5.1 tools/simulate_routes.lua --route skyborne-druid <the --skip part of F> $G` | `OK`: 1,784 steps, 728 accepted, 727 turned in, level 60, **13 reward choice(s) checked** (now read from the class reward table), 2 warnings (below) |
| `lua5.1 tools/simulate_routes.lua --route skyborne-shaman <the --skip part of F> $G` | `OK`: 1,721 steps, 715 accepted, 715 turned in, level 60, the same 2 warnings |
| `GUIDES_SKIP='Segments/Tirisfal/*,Classes/Paladin.lua,Races/Scourge.lua' GUIDES_OWN='Segments/Zephras/*,Classes/Druid.lua,Races/Skyborne.lua' busted tests/spec/guides_layout_spec.lua` | 12 successes / 0 failures / 0 errors (the case "carries no `reward` on a shared base step" now checks the Zephras files: the exemption ends with `only`) |

The two simulator warnings are the known ones of the baseline, both explained:

* `sd02-hearth`: "the hearthstone bind point (Valanaar) is not at the step location; teleporting" (the simulator's
  position model; in F2a and F2b too).
* `sky-1061`: "quest 1061 would not be offered yet: requires level 13 (player is 12)". The simulator credits quest
  XP only (`tools/simulate_routes.lua:83`), so its character is at 12 in Orgrimmar; the validator (quest XP +
  objective kills) has 13.76 there for the base profile, 13.61 in the worst case. The step is `optional` and its
  note says to skip it below 13.

Not acceptance commands, run for information (read-only, no file written):

| Command | Result |
|---|---|
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --grind-until h-18-stonetalon-ashenvale $G` (the whole module with the Tirisfal agent's files as they were at that moment) | exit 0: 11 routes, 0 ERROR, 0 WARN, 188 accepted |
| `busted tests/spec/guides_layout_spec.lua` (unfiltered, same moment) | 23 successes |
| `lua5.1 tools/gen_route_data.lua --stdout $G` compared with `G/Data.lua` | no difference, no note about a place name |
| `... --route 'skyborne-*' --skip 'Classes/*' --skip 'Segments/Tirisfal/*' --skip 'Races/Scourge.lua'` (no `--own`) | the five routes: 0 ERROR, 0 WARN, 4,914 / 6,129. The transitional `quest-carried` 94911 of the F2b hand-over is gone. The run still exits 1 on the template checks: the known `insert-anchor-unknown` of `sky-40d-path` (C.7, open issue 5 of the F2b hand-over, not mine to solve) and 12 `shared-step-unused` that exist only because this command leaves the Scourge routes out |

### `--summary` lines (with `--grind-until h-18-stonetalon-ashenvale`)

```
skyborne-druid	Skyborne DRUID Horde	0	0	19	0	60.00	60.00	4852	6052	0	24
skyborne-hunter	Skyborne HUNTER Horde	0	0	18	0	60.00	60.00	4914	6129	0	59
skyborne-rogue	Skyborne ROGUE Horde	0	0	18	0	60.00	60.00	4914	6129	0	59
skyborne-shaman	Skyborne SHAMAN Horde	0	0	18	0	60.00	60.00	4914	6129	0	59
skyborne-warrior	Skyborne WARRIOR Horde	0	0	18	0	60.00	60.00	4914	6129	0	59
```

The base Skyborne needs 0 / 59 grind kills up to the end of `h-18` (target of B.8: 120 / 200).

### Per segment: level in -> out, grind kills normal / worst

The four base routes print the same table (compared line by line).

| Segment | base (`skyborne-shaman`) | `skyborne-druid` |
|---|---|---|
| `sd-01-zephras` | 1.00 -> 9.93, 0 / 0 | 1.00 -> 9.95, 0 / 0 |
| `sd-02-zephras` | 9.93 -> 13.24, 0 / 0 | 9.95 -> 13.32, 0 / 0 |
| `sd-03-thunder-bluff` | 13.24 -> 13.24, 0 / 0 | 13.32 -> 13.35, 0 / 0 |
| `h-12-orgrimmar-tirisfal` | 13.24 -> 14.09, 0 / 0 | 13.35 -> 14.17, 0 / 0 |
| `h-13-silverpine` | 14.09 -> 15.44, 0 / 0 | 14.17 -> 15.55, 0 / 0 |
| `h-15-barrens` | 15.44 -> 18.67, 0 / 0 | 15.55 -> 18.75, 0 / 0 |
| `h-18-stonetalon-ashenvale` | 18.67 -> 22.26, 0 / 59 | 18.75 -> 22.44, 0 / 24 |
| `h-22-hillsbrad` | 22.26 -> 24.98, 0 / 51 | 22.44 -> 25.12, 0 / 52 |
| `h-24-barrens-stonetalon` | 24.98 -> 27.42, 0 / 220 | 25.12 -> 27.52, 0 / 220 |
| `h-27-ashenvale-needles` | 27.42 -> 31.01, 101 / 313 | 27.52 -> 31.01, 82 / 313 |
| `h-31-hillsbrad-arathi` | 31.01 -> 34.05, 273 / 327 | 31.01 -> 34.06, 274 / 326 |
| `h-34-stranglethorn` | 34.05 -> 36.06, 152 / 151 | 34.06 -> 36.06, 151 / 152 |
| `h-37-desolace-dustwallow` | 36.06 -> 41.01, 1,008 / 1,029 | 36.06 -> 41.02, 1,009 / 1,029 |
| `h-41-arathi-badlands` | 41.01 -> 44.02, 765 / 919 | 41.02 -> 44.02, 764 / 918 |
| `h-44-swamp-stranglethorn` | 44.02 -> 46.01, 177 / 184 | 44.02 -> 46.01, 178 / 185 |
| `h-46-tanaris-feralas` | 46.01 -> 49.40, 618 / 715 | 46.01 -> 49.40, 617 / 715 |
| `h-50-hinterlands-searing-steppes` | 49.40 -> 52.57, 154 / 308 | 49.40 -> 52.57, 154 / 308 |
| `h-53-azshara-ungoro-silithus` | 52.57 -> 55.05, 362 / 392 | 52.57 -> 55.05, 319 / 349 |
| `h-56-felwood-winterspring-plaguelands` | 55.05 -> 60.00, 1,304 / 1,461 | 55.05 -> 60.00, 1,304 / 1,461 |
| total | 4,914 / 6,129 | 4,852 / 6,052 |

### Gates of 1-22 for the base profile (kills normal / worst)

| Gate | Step | Kills | Worst |
|---|---|---:|---:|
| 2 | `sd01-level-2` | 0 | 0 |
| 3 | `sd01-level-3` | 0 | 0 |
| 4 | `sd01-level-4` | 0 | 0 |
| 10 | `sd02-level-10` | 0 | 0 |
| 12 | `h13-lvl-12` (the row B.2 asks for; limit 10 / 25) | 0 | 0 |
| 13 + 92 % | `h13-lvl-14` | 0 | 0 |
| 18 | `h18-lvl-18` | 0 | 0 |
| 19 + 88 % | `h18-lvl-20` | 0 | 0 |
| 21 | `h18-lvl-21` | 0 | 0 |
| 21 + 85 % | `h18-lvl-22` | 0 | 59 |

### Hand-over contract of B.2 (Zephras, `sd-03` end)

Read from `--route skyborne-shaman --write-state F --until h-12-orgrimmar-tirisfal` (the state before `h12-fp-org`):

| Contract | Base profile | Druid |
|---|---|---|
| in Orgrimmar at Doras, arrived by flight | `at` = { 1454, 45.12, 63.89 } (the landing of `sd03-fly-org`) | the same |
| level >= 13.0 | **13.24** (worst case 13.18) | 13.35 (13.29) |
| 95350 in the log | log = { 95350 } | log = { 94913, 95350 } |
| hearth anywhere | Valanaar | Valanaar |
| flight point Thunder Bluff | flightPaths = { "Thunder Bluff" } | the same |

## 3. The class-neutral path, in one view

`sd-01`: Thendal Grove (letter anchor `sd01-rorian` at 2.8, gates 2 / 3 / 4, hearth to the camp at 3) -> ursera
den -> Al'Aketh camp -> Shen'dar (three visits and the final turn-ins). `sd-02`: Valanaar 1 (bind, 92579 / 93948,
the Skydocks) -> Windfield orchard and the bandit hill -> `sd02-aamelia-3` -> gate `sd02-level-10` ->
**`sd02-valanaar-10`** (class trainers; the level-10 class quests start here) -> Construct Parts at 52,66 -> Fendaal
(98512) -> the lake -> Shadowwind Forest -> `sd02-hearth` -> Valanaar turn-ins -> skycutter -> `sd02-plateau` ->
`sd02-end` (95350). `sd-03`: deathskip, `sd03-spirit`, `sd03-fp-tb`, `sd03-fly-org`.

What a non-druid no longer walks: the falls basin of Urs'endris (twice) and the way around it. What a non-druid
walks in addition to the shortest line: orchard -> Valanaar -> Construct Parts instead of orchard -> Construct
Parts, about 11 map units more (16.8 + 10.6 against 16.4; uiMap 2521 has no world size in the DB, so no yards).
That is the price of the second Valanaar visit, which C.2 fixes as the level-10 anchor of every class (hunter pet
chain, warrior 94003, shaman 97243, the druid's 94006 all start at trainers in Valanaar).

## 4. Anchors and levels

Level before the step, normal run, or normal / worst case where they differ. Base = `skyborne-shaman` (the other
three base routes are identical). Complete list: `lua5.1 tools/validate_routes.lua --route skyborne-<class>
--levels <F> $G`.

### The anchors of C.2 and the further ids the druid file uses

| Anchor | Step | Base | Druid | Use |
|---|---|---|---|---|
| `sd01-rorian` | Rorian: 92461 + 92474 in, 92464 out | 2.80 | 2.80 | class letter (92482 hunter, 92483 rogue, 92484 shaman, 92485 druid, 92532 warrior: all given by Rorian after 92461), first training. Gate `sd01-level-2` stands in front |
| `sd01-rorian-4` | Rorian: 92469 -> 92471 (behind the gate `sd01-level-4`) | 4.35 | 4.44 | the druid's training 4 (Xyton stands next to Rorian) |
| `sd01-thendal-4` | Valreaa: accept 92473, the last generic step of the level-4 visit | 4.69 | 4.77 | training at 4 |
| `sd01-innkeeper` | Shen'dar inn, talk objective of 92514 | 6.01 | 6.05 | training at 6 (see the note under the table) |
| `sd01-raan-2` | Raan: 96101 -> 96646, the last step at the campfire | 6.17 | 6.20 | the druid's training 6 (the trainers stand between the campfire and Aonda) |
| `sd01-danarii-2` | Danarii: accept 92551 (third Shen'dar visit) | 8.88 | 8.91 | the druid's training 8, weapon vendor Tephri |
| `sd01-shendar-8` | Teeri: turn-in of 92516, the last generic step of the level-8 visit | 9.08 | 9.10 | training at 8 |
| `sd02-endaria` | Endaria: accept 93736 (Skydocks, first Valanaar visit) | 10.32 | 10.33 | the druid's staff vendor on the way to Riaani |
| `sd02-level-10` | generic trainer-hub gate `level = 10` | 11.20 | 11.21 | - |
| `sd02-valanaar-10` | `go`, radius 40, at the west entrance of Valanaar (Nyalah's spot) | 11.20 | 11.21 | training at 10, level-10 class quests |
| `sd02-fendaal-2` | Fendaal: turn-in of 98512 | 11.27 | 11.35 | the druid's way back to Urs'endris |
| `sd02-hearth` | hearth to Valanaar | 12.74 / 12.67 | 12.83 / 12.76 | training at 12 |
| `sd02-lotheluum-2` | Lotheluum (the druid trainer): turn-in of 94491 | 12.87 / 12.80 | 12.96 / 12.89 | the druid's training 12 (must follow this turn-in: look-ahead rule) |
| `sd02-plateau` | `go`, arrival on Skywatcher Plateau | 13.24 / 13.18 | 13.32 / 13.26 | plateau trainers (druid, shaman), the druid's 94911 |
| `sd02-end` | Alaana: accept 95350, the last step of `sd-02` | 13.24 / 13.18 | 13.32 / 13.26 | - |
| `sd03-spirit` | Thunder Bluff spirit healer (`optional` `go`) | 13.24 / 13.18 | 13.32 / 13.26 | Thunder Bluff trainers, the druid's 94911 -> 94913 |
| `sd03-fp-tb` | `fp` Thunder Bluff | 13.24 / 13.18 | 13.35 / 13.29 | - |
| `sd03-fly-org` | flight to Orgrimmar, the last step of `sd-03` | 13.24 / 13.18 | 13.35 / 13.29 | - |

Against the table of C.2: `sd01-rorian` 2.8 (plan 3.0), `sd01-thendal-4` 4.7 (4.6), `sd01-innkeeper` 6.0 (6.3),
`sd01-shendar-8` 9.1 (8.9), `sd02-valanaar-10` 11.2 (11.2), `sd02-hearth` 12.7 (12.9), `sd02-plateau` 13.2 (13.2),
`sd03-*` 13.2 (13.3). The plan's numbers were the druid's.

Two places where the base profile is close to an even level (all quest XP of the isle is estimated, so real
levels can be lower):

* **Shen'dar at 6.** The base profile enters the village at 5.70 (`sd01-aonda`), is at 6.01 at the inn and at 6.17
  when it passes the trainers (`sd01-raan-2`). There is no gate (the old route had none and C.2 lists none). A
  class file that trains there should anchor after `sd01-raan-2`, not after `sd01-innkeeper`; if the level is
  missed, the second visit (7.76, `sd01-aonda-3`) and the third (8.88) pass the same trainers. P2 decides whether a
  trainer-hub gate `level = 6` belongs in front of `sd01-raan-2` (cost in the estimate: 0 kills).
* **Valanaar, first visit, at 10.** The base profile arrives at 9.93 (`sd02-nyalah`) and is at 10.02 at the inn.
  The level-10 anchor is the second visit (11.20, behind the gate), as C.2 says. A trainer-hub gate `level = 10` in
  front of the first visit would cost about 6 kills in the estimate and would let the class files accept the
  level-10 class quests one loop earlier (the hunter's taming targets and the shaman's Olariaan are on the orchard
  loop). Not done: it changes the plan's anchor table; a decision for P2 / phase C.

### Skyborne base levels at the trainer anchors of the shared path

| Anchor | Base | Druid |
|---|---|---|
| `h12-fp-org` | 13.24 / 13.18 | 13.35 / 13.29 |
| `h12-org-end` | 13.76 / 13.61 | 13.87 / 13.72 |
| `h12-fp-uc` | 14.09 / 13.95 | 14.17 / 14.06 |
| `h13-uc-end` | 15.44 / 15.32 | 15.51 / 15.41 |
| `h15-org` | 15.44 / 15.33 | 15.55 / 15.45 |
| `h15-hearth-xroads` | 17.61 / 17.52 | 17.70 / 17.60 |
| `h18-tb-1` | 18.72 / 18.44 | 18.80 / 18.51 |
| `h18-hearth-taurajo` | 18.96 / 18.63 | 19.03 / 18.70 |
| `h18-tb-2` | 20.87 / 20.54 | 20.92 / 20.60 |
| `h18-hearth-tb` | 22.22 / 22.01 | 22.40 / 22.00 |
| `h18-tb-3` | 22.22 / 22.01 | 22.40 / 22.00 |
| `h-22-tb-start` | 22.26 / 22.05 | 22.44 / 22.04 |
| `h-40-org-arrive` | 40.04 / 39.98 | 40.04 / 39.98 |

### Every step id of the three Zephras segments (base profile: level normal, worst case, actions)

```
sd01-start              1.00  1.00  accept 92460
sd01-rorian-1           1.00  1.00  turnin 92460, accept 92461
sd01-elatrell           1.10  1.10  accept 92462
sd01-first-kills        1.10  1.10  complete 92461, complete 92462
sd01-level-2            2.42  2.42  level 2
sd01-elatrell-2         2.42  2.42  turnin 92462, accept 92463
sd01-halaan             2.61  2.61  turnin 94414, accept 94414, complete 94414
sd01-myriaal            2.80  2.80  accept 92474
sd01-glide              2.80  2.80  complete 92474
sd01-rorian             2.80  2.80  turnin 92461, turnin 92474, accept 92464
sd01-skysight-accept    3.02  3.02  accept 92598
sd01-dalia              3.02  3.02  accept 93552
sd01-windstones-bg      3.02  3.02  complete 93552
sd01-queen              3.02  3.02  complete 92463
sd01-yala               3.06  3.06  turnin 92464, accept 92465
sd01-skysight           3.24  3.24  complete 92598
sd01-agitators          3.24  3.24  complete 92465, complete 93552
sd01-level-3            3.67  3.67  level 3
sd01-yala-2             3.67  3.67  turnin 92465, accept 92469
sd01-hearth-3           3.85  3.85  hearth Thendal Village
sd01-dalia-2            3.85  3.85  turnin 93552
sd01-elatrell-3         4.07  4.07  turnin 92463
sd01-skysight-turnin    4.19  4.19  turnin 92598
sd01-level-4            4.35  4.35  level 4
sd01-rorian-4           4.35  4.35  turnin 92469, accept 92471
sd01-aetheen            4.52  4.52  turnin 92471, accept 92470
sd01-thendal-4          4.69  4.69  accept 92473
sd01-claws-bg           4.69  4.69  complete 92473
sd01-den                4.90  4.90  complete 92470
sd01-claws              5.15  5.15  complete 92473
sd01-aetheen-2          5.15  5.15  turnin 92470, accept 92472, accept 96638
sd01-valreaa-2          5.26  5.26  turnin 92473
sd01-hanaa              5.39  5.39  accept 92544
sd01-thugs              5.39  5.39  complete 92544
sd01-hanaa-2            5.58  5.58  turnin 92544
sd01-larder-bg          5.70  5.70  collect 5469, collect 6889
sd01-aonda              5.70  5.70  turnin 92472, accept 92514
sd01-illaya             5.82  5.82  turnin 92595, accept 92595, complete 92595, complete 92514
sd01-illaya-2           6.01  6.01  accept 94411
sd01-innkeeper          6.01  6.01  complete 92514
sd01-raan               6.01  6.01  turnin 96638, accept 96101
sd01-campfire           6.17  6.17  complete 96101
sd01-raan-2             6.17  6.17  turnin 96101, accept 96646
sd01-aonda-2            6.32  6.32  turnin 92514, accept 92517
sd01-teeri              6.47  6.47  accept 93319, accept 92516
sd01-indari             6.47  6.47  accept 92515
sd01-taleen             6.47  6.47  accept 93951
sd01-zerril             6.47  6.47  turnin 96646, accept 92553, complete 96646
sd01-pelts-bg           6.62  6.62  complete 92515
sd01-larder-bg-2        6.86  6.86  complete 92553
sd01-apprentices        7.24  7.24  complete 94411
sd01-pilfered-bg        7.30  7.30  complete 93319
sd01-bennic             7.57  7.57  complete 92517
sd01-bandits            7.59  7.59  complete 92517, complete 93319
sd01-aonda-3            7.76  7.76  turnin 92517, accept 93036
sd01-sania              7.90  7.90  turnin 93036, accept 92529
sd01-mark               8.05  8.05  manual
sd01-teeri-2            8.05  8.05  turnin 93319
sd01-illaya-3           8.17  8.17  turnin 94411
sd01-wanted             8.27  8.27  accept 93318
sd01-vale-cliff         8.27  8.27  go
sd01-down-bg            8.27  8.27  complete 93951
sd01-hippogryphs        8.27  8.27  complete 92516
sd01-down               8.41  8.41  complete 93951
sd01-vulgara            8.41  8.41  complete 93318
sd01-falaath-cliff      8.48  8.48  go
sd01-jasaan             8.48  8.48  turnin 92529, accept 92528
sd01-wardrobe           8.61  8.61  complete 92528
sd01-ramp-1             8.61  8.61  go
sd01-aonda-4            8.61  8.61  turnin 92528, accept 92550, accept 93926
sd01-danarii            8.74  8.74  turnin 93318
sd01-danarii-2          8.88  8.88  accept 92551
sd01-taleen-2           8.88  8.88  turnin 93951
sd01-zerril-2           9.00  9.00  turnin 92553
sd01-shendar-8          9.08  9.08  turnin 92516
sd01-south-cliff        9.18  9.18  go
sd01-vaaniel            9.18  9.18  turnin 93926, accept 93927, complete 93926
sd01-last-request       9.29  9.29  complete 93927
sd01-caches-bg          9.29  9.29  complete 92551
sd01-falaath            9.41  9.41  complete 92550
sd01-caches             9.52  9.52  complete 92551
sd01-ramp               9.52  9.52  go
sd01-indari-2           9.52  9.52  turnin 92515, complete 92515
sd01-danarii-3          9.60  9.60  turnin 92551
sd01-end                9.71  9.71  turnin 92550, turnin 93927, accept 92579, accept 93948
sd02-start              9.93  9.93  go
sd02-nyalah             9.93  9.93  accept 93317
sd02-crabs-bg           9.93  9.93  complete 93317
sd02-sethearth         10.02 10.02  sethearth Valanaar
sd02-alvarion          10.02 10.02  accept 92679
sd02-lotheluum         10.02 10.02  accept 94484
sd02-ealaane           10.02 10.02  accept 94896, accept 94897
sd02-talaanis          10.02 10.02  turnin 93948
sd02-valennia          10.12 10.12  turnin 92579, accept 92700
sd02-tower-glide       10.21 10.21  go
sd02-ayessa            10.21 10.21  turnin 92700, accept 93735
sd02-endaria           10.32 10.32  accept 93736
sd02-riaani            10.32 10.32  turnin 93735, accept 93737, complete 93737
sd02-aamelia           10.42 10.42  turnin 92679, accept 92682, accept 92684, accept 92683, complete 92679
sd02-tenderloins-bg    10.52 10.52  complete 92684
sd02-dust-bg           10.61 10.61  complete 92683
sd02-orchard           10.61 10.61  complete 92682
sd02-construct         10.65 10.65  accept 92698
sd02-dust              10.65 10.65  complete 92683, complete 92684
sd02-aamelia-2         10.65 10.65  turnin 92682, turnin 92684, turnin 92698, turnin 92683, accept 92685
sd02-bandit-hill       11.05 11.05  complete 92685, complete 93737
sd02-aamelia-3         11.11 11.11  turnin 92685
sd02-level-10          11.20 11.20  level 10
sd02-valanaar-10       11.20 11.20  go
sd02-parts-lightning   11.20 11.20  complete 93737
sd02-fendaal           11.20 11.20  accept 98512
sd02-assassins         11.20 11.20  complete 98512, complete 93317
sd02-fendaal-2         11.27 11.27  turnin 98512
sd02-parts-gyrozephyr  11.35 11.35  complete 93737
sd02-hermit            11.35 11.35  turnin 93159, accept 93159, complete 93159
sd02-hermit-2          11.43 11.43  accept 93160, accept 93172
sd02-cones-bg          11.43 11.43  complete 93160
sd02-hollows-bg        11.43 11.43  complete 93172, complete 93736, complete 94896
sd02-resaan            11.66 11.66  complete 94897
sd02-hollows           11.68 11.68  complete 93172, complete 93736, complete 94896
sd02-elegael           11.68 11.68  turnin 94484, accept 94485, accept 94486, accept 94487
sd02-vayn              11.75 11.75  accept 93165
sd02-ears-bg           11.75 11.75  complete 93165
sd02-den-items         11.83 11.83  complete 94485, complete 94486, complete 94487
sd02-elegael-2         12.19 12.19  turnin 94485, turnin 94486, turnin 94487, accept 94488, accept 94489
sd02-haalien           12.37 12.37  complete 94488
sd02-missive           12.38 12.38  accept 94490
sd02-wounded           12.38 12.38  complete 94489
sd02-ears              12.38 12.38  complete 93165
sd02-vayn-2            12.38 12.38  turnin 93165
sd02-elegael-3         12.45 12.38  turnin 94489, turnin 94490, turnin 94488, accept 94491
sd02-hermit-3          12.60 12.54  turnin 93160, turnin 93172, complete 93160
sd02-hearth            12.74 12.67  hearth Valanaar
sd02-ealaane-2         12.74 12.67  turnin 94896, turnin 94897
sd02-lotheluum-2       12.87 12.80  turnin 94491
sd02-nyalah-2          12.91 12.85  turnin 93317
sd02-riaani-2          12.99 12.92  turnin 93737, accept 93738
sd02-endaria-2         13.06 13.00  turnin 93736
sd02-ayessa-2          13.13 13.07  turnin 93738, accept 92708
sd02-speech            13.20 13.14  turnin 92708, complete 92708
sd02-skycutter         13.24 13.18  go
sd02-plateau           13.24 13.18  go
sd02-end               13.24 13.18  accept 95350
sd03-cliff             13.24 13.18  go
sd03-spirit            13.24 13.18  go
sd03-fp-tb             13.24 13.18  fp Thunder Bluff
sd03-fly-org           13.24 13.18  fly Orgrimmar
```

## 5. Deviations from the plan, and why

1. **`sd02-valanaar-10` is a `go` step.** C.2 calls it "the first generic Valanaar step after the gate", but the
   generic path has no quest step in Valanaar between the gate and the hearth: the second visit existed only for
   the druid's 94006 and training. The anchor is therefore an arrival step of its own (the same kind as
   `h12-org-end`, `h13-uc-arrive`, `h15-org`), with a note that names where the class trainers stand. A class
   insert after it should start with a stateful step (the druid's starts with the accept of 94006).
2. **The gate `sd02-level-10` is a plain `level = 10` step** (B.8: "gates are plain steps with a class-neutral
   note"); it was merged with the turn-in of 92685, which is now `sd02-aamelia-3`. The gate keeps its id.
3. **Six anchors beyond the C.2 table** (`sd01-rorian-4`, `sd01-raan-2`, `sd01-danarii-2`, `sd02-endaria`,
   `sd02-fendaal-2`, `sd02-lotheluum-2`). They keep the druid's walk exactly as it was (the C.2 anchors
   `sd01-thendal-4`, `sd01-innkeeper`, `sd01-shendar-8`, `sd02-hearth` would move a trainer visit behind steps at
   other NPCs or in front of a turn-in at the trainer). Every step has an explicit id, so this needs nothing new in
   the segments; F2d may add them to the anchor table of the layout spec.
4. **One generic `go` step became a druid step.** "North (the Al'Aketh camp is to the east)" at 58.9, 55.0 was the
   way from the falls basin to the lake. From Fendaal the lake shore is straight north-north-west, so the step is
   `dru-zep-bear-lake` and the generic step `sd02-parts-gyrozephyr` carries the hint about the camp in its note.
5. **The two weapon vendor steps are druid steps** (`dru-zep-staff-1`, `dru-zep-staff-2`), not generic "weapon
   vendor" steps: they name a staff (routes.md 3.7 / 3.8 class them as class gear). The four other classes have no
   vendor step until phase C.
6. **`optional` flags of the druid's training steps are unchanged** (4 and 8 optional, 1 / 6 / 10 / 12 mandatory).
   C.4 would make all of them mandatory; this phase moves the steps, the druid's class agent (phase C) owns the
   decision.
7. **No override file.** `tools/overrides/zephras.lua` and `druid.lua` were not created: there is no XP value or
   mask correction with a source.
8. **Texts outside the strict scope, changed because the files are mine:** the faction word in the Skysight note
   (F2d step 2 lists it as a fall-back task: done here), "shared path" in the two notes of `dru-cat-hearth-tb`
   (A.1: user-visible text never says it), the segment id "sd-02" in the note of `sd01-hearth-3`, and the
   Russian notes of the druid's 13-22 steps now use the forms the module already has (Тюрак Рунический Тотем,
   Логанаар, Бунтен Ветер Равнин; the F2b hand-over left them to F2c). Dendrite Starblaze and every NPC of
   Zephras Isle keep their English names in Russian notes: no Russian form is known for them (the convention of
   the Zephras files since the old route).
9. **94489 "The Wounds of Betrayal".** The old note told a druid to heal the seven injured druids. The DB has an
   interact objective and no class limit; the new note says "walk up and interact with each; with a healing spell,
   heal them" and the step has `-- CONFIRM`. If a class without a heal cannot complete it, the quest can be
   abandoned without breaking the path: in the DB 94491 needs 94490 only, and the turn-in step `sd02-elegael-3`
   (94489 + 94490 + 94488 -> 94491) then waits for the other two (an abandoned quest counts as done in a mixed
   step, `docs/ROUTE_FORMAT.md`). The note of `sd02-wounded` says so ("your class cannot help them - abandon the
   quest"); the validator counts the quest's estimated XP in both runs.

## 6. Notes for the next phases

### F2d

* No foreign warning to resolve from this column (0 in every run).
* Layout spec: `EXPLICIT_IDS` can take `sd-01-zephras` and `sd-02-zephras` (0 positional ids; checked through the
  loader). Anchor table for Zephras: the 18 rows of section 4; all are unfiltered. No announcement of this zone
  carries `only`. The fixture replacement of `Zephras/03_ThunderBluff.lua` in the 28-route case is no longer needed
  (F2b hand-over, deviation 10).
* The faction word: none in the notes of `Segments/Zephras/*`, `Classes/Druid.lua`, `Races/Skyborne.lua` (a few
  header comments say "Windshaper side"; the Skysight note is reworded).
* `docs/routes/horde-skyborne-druid.md` names the removed ids (`sd01-train-*`, `sd02-bear-*`, `sd02-train-*`); the
  mapping is in section 1.
* The base-profile command (`--skip 'Classes/*'` without `--own`) still reports `insert-anchor-unknown` for
  `sky-40d-path`: open issue 5 of the F2b hand-over, unchanged. Nothing else of the Skyborne routes fails there.

### P1 / P2

* The Skyborne numbers for the path comparison: section 2. No gate of 1-22 costs a kill in the normal run; the
  worst case is 59 kills at `h18-lvl-22`.
* The two trainer-hub questions of section 4 (Shen'dar at 6, the first Valanaar visit at 10).
* `h-40-org-arrive` is at 39.98 in the worst case: every riding step is optional, so nothing breaks, but a
  class file that trains "at 40" there should know it.

### Phase C (hunter, rogue, shaman, warrior, druid)

* Letters: after `sd01-rorian`, one step `accept` at Rorian (251361) and one `turnin` at the trainer; the shared
  step already hands in 92461. Trainers of the start camp: Tai'ree Farsight 251376 (42.49, 23.79), Akeri Duskblade
  251389 (43.74, 24.36), Windshaper Boro 251374 (42.79, 23.58), Blademaster Ren 251964 (43.65, 24.11), Xyton
  Silverwind 251373 (41.66, 23.33).
* Shen'dar: Elayaa Easewind 254084 (hunter, 45.26, 44.24), Miriaan Mistblade 254087 (rogue, 43.15, 43.26: next to
  the inn, so `sd01-innkeeper` is the right anchor for the rogue), Aarnor Galestrike 254082 (shaman, 43.45, 44.87:
  next to Illaya, anchor `sd01-illaya-2`), Corsan Earthrazer 254088 (warrior, 44.95, 45.10), Naeluna Swiftmend
  254081 (druid, 45.16, 44.22).
* Valanaar: Quel'ana Quickgale 252389 (hunter, 59.56, 72.63), Quel'dora Quickgale 254411 (pet trainer),
  Eltheen Nightbreeze 252379 (rogue, 59.90, 72.48), Seena Skybreaker 252377 (warrior, 59.89, 72.87), Sessaria
  Skystride 252382 (shaman, the Skydocks, 58.31, 78.51), Lotheluum Starbreeze 252359 (druid, 63.99, 75.08).
  Lotheluum also gives 94484 (`sd02-lotheluum`) and takes 94491 (`sd02-lotheluum-2`): no other class is sent to
  "train" at him, and the druid's training steps stand behind those two steps.
* Skywatcher Plateau: Hana Lighthoof 262560 (druid), Palah Thunderhoof 262558 (shaman, 33.59, 22.40).
* A class insert may not use the hearthstone on the isle: it is used at `sd01-hearth-3` and `sd02-hearth` only.
* Rewards: `FastesBoooy.AddLibraryData({ rewards = { <CLASS> = { ... } } })`, one call per class file. The 13
  quests with a choice on the isle are listed in section 1 (the druid's indexes). Without an entry the automation
  stops at the reward window and asks the player.
* Riding: the race file has both variants (`sky-40-*` for hunter, rogue, shaman, warrior after `h-40-org-arrive`;
  `sky-40d-*` for the druid after `dru-40-train`). A class file that adds steps after `h-40-org-arrive` lands in
  front of the riding detour (class file before race file); the detour leaves the city by flight, so city steps
  must not come after it.
* Druid (Tauren): the `dru-zep-*` group is `race = "Skyborne"`; a Mulgore group is still to be written.

### For the atlas (`docs/dev/ATLAS.md`)

* A start zone is now pure "place" data: 147 steps with stable ids, NPC ids and coordinates, no class in them.
  The class view of the same zone (which trainer where, which class quest starts at which hub) is the list of
  inserts that name the zone's anchors; an atlas page of Zephras can be built from the two without reading notes.

## 7. Foreign warnings, overrides, place names, `-- CONFIRM`

* Foreign warnings: none. ERRORs or WARNs in files of others: none seen in any run.
* DB overrides added: none. XP values or mask corrections for quests I may not override: none.
* New place names that need a Russian fall-back in `PLACE_NAMES_RU`: none (`gen_route_data.lua --stdout` prints no
  note; the new `fly` steps use Thunder Bluff and Camp Taurajo).
* Ids added: 125 step ids in the segments (76 `sd01-*`, 49 `sd02-*` on existing steps), 2 new segment steps
  (`sd02-aamelia-3`, `sd02-valanaar-10`), 23 `dru-zep-*`, 7 `sky-40-*`. Ids removed: `sd01-92485`, `sd01-train-1`,
  `sd01-train-4`, `sd01-train-6`, `sd01-train-8`, `sd02-bear-accept`, `sd02-train-10`, `sd02-bear-quest`,
  `sd02-bearform`, `sd02-train-12`, `sd02-train-12-plateau`.
* `-- CONFIRM`:
  * `sd02-wounded` (new): how a class without a healing spell completes "Injured Druids healed" of 94489.
  * `sd03-fly-org` (E.2, unchanged): the flight Thunder Bluff -> Orgrimmar at 13 without the Orgrimmar point.
  * `sky-40-riding` / `sky-40d-riding` (E.9, notes): whether the mount comes with the skill; the skycutter from
    Skywatcher Plateau back to the isle at 40.
  * the trainer positions above are DB spawns; that the Shen'dar and Valanaar trainers teach beyond level 6 is
    taken from the old route (it trained there at 6, 8, 10, 12).

## 8. Open issues for the orchestrator

1. **The C.7 anchor in base-profile runs** (F2b hand-over, section 6, item 5) is still open and now shows for the
   five Skyborne routes as well: `insert-anchor-unknown` for `sky-40d-path` whenever `Classes/Druid.lua` is
   skipped and `Races/Skyborne.lua` is own. Not touched (D.0 rule 6).
2. **Closing step.** `make routedata report` is still to run (`docs/VALIDATION.md` is stale: 2 routes there, 11
   now). `G/Data.lua` was equal to the generator's output when I checked.
3. **Two decisions that are not mine** (section 4): a trainer-hub gate at 6 in Shen'dar, and a level-10 gate in
   front of the first Valanaar visit. The route validates without either.
4. **94489 for non-healers** (deviation 9): needs one look in game; until then the note covers both readings and
   names the way out (abandon the quest).
5. Nothing blocks F2d from this column.
6. **A defect outside my files (D.0 rule 6), found by the verification: the level-sync run `--ahead 48` fails for
   the four Skyborne base routes** (and for the five Undead ones; `f2c-tirisfal.md`, section 7 item 2, has the
   analysis). `lua5.1 tools/simulate_routes.lua --route skyborne-shaman --ahead 48 $G`: `FAIL ... cold start with
   empty SavedVariables: cursor on step 1053 h-44-swamp-stranglethorn:19 [accept 1424], but step 1721 h-60-end
   is already done`. `skyborne-druid --ahead 48` passes, only because the druid has class steps behind
   `h-60-end`. `make check` is not affected (`SYNC_ROUTES = undead-paladin skyborne-druid`); `make
   simulate-sync-full` (nightly CI, phase R) fails for the 9 base routes. Owner: the core
   (`Engine:ComputeSyncSuggestion`) or the cold-start check of `tools/simulate_routes.lua`, a single-owner phase.
   Nothing to change in the Zephras files.

## 9. Verification round 1

Findings of the independent verification that concern this column, with the verdict and the change. Finding
numbers are those of the review list (1-8); 1, 4, 6 and 8 belong to the Tirisfal column (`f2c-tirisfal.md`).

| # | Finding | Verdict | Change |
|---|---|---|---|
| 3 | two generic notes of `sd-01` still carried druid advice: `sd01-apprentices` "casters - fight them up close" (wrong for a hunter), `sd01-vulgara` "full health and mana" (rogue and warrior have no mana) | real | `sd01-apprentices`: "(casters)" / "(маги)", no melee advice. `sd01-vulgara`: "Start at full health, use every defensive ability and potion" / "Начинайте с полным здоровьем ...". The melee advice is not lost for the druid: it is in the note of `dru-zep-train-6` |
| 7 | the same "mana" wording of `sd01-vulgara` | real, the same note as in 3 | fixed with 3. One more "mana" stays in `sd01-larder-bg` ("windstone crystals restore health and mana"): it says what the object does, not what the player should do |
| 5 | the druid's advice for the elite Vulgara stood in the note of `dru-zep-train-8`, which the route reaches after the fight and after the turn-in of 93318 | real (composed order: `sd01-vulgara` at step 70, `dru-zep-train-8` at step 78) | the sentence (ru and en) moved to the note of `dru-zep-train-6`, the druid step before the fight, where Thorns is trained; `dru-zep-train-8` keeps its training text only |
| 2 | `--ahead 48` fails for every base route (core / simulator, outside F2c); this hand-over did not mention it | real, not mine to fix | no change in my files; reproduced for `skyborne-shaman`; open issue 6 of section 8 added |

Only notes changed in this column: the composed routes, every level of `--levels` (compared line by line for
`skyborne-druid` and `skyborne-shaman`) and every number of section 2 are the same as before.

Acceptance after round 1 (all on the final tree, `F` as in section 2):

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Segments/Zephras $G/Classes/Druid.lua $G/Races/Skyborne.lua` | 0 warnings / 0 errors in 5 files |
| `validate_routes.lua -q --strict --end-level --summary --route 'skyborne-*' <F> $G` | exit 0: 5 routes, 0 ERROR, 0 WARN, 91 accepted, 60.00 / 60.00; druid 4,852 / 6,052, base 4,914 / 6,129 |
| `... --route skyborne-druid --max-grind-until h-56-felwood-winterspring-plaguelands=4878/6082 <F> $G` | exit 0: 4,852 / 6,052 |
| `validate_routes.lua --route skyborne-shaman --levels <F> $G` | exit 0, identical to the list of section 4 |
| `simulate_routes.lua --route skyborne-druid <the --skip part of F> $G` | `OK`: 1,784 steps, 728 accepted, 727 turned in, level 60, 13 reward choice(s) checked, the 2 known warnings (`sd02-hearth`, `sky-1061`) |
| `simulate_routes.lua --route skyborne-shaman <the --skip part of F> $G` | `OK`: 1,721 steps, 715 accepted, 715 turned in, level 60, the same 2 warnings |
| `GUIDES_SKIP=... GUIDES_OWN=... busted tests/spec/guides_layout_spec.lua` | 12 successes / 0 failures |
| in addition: `busted tests/spec/guides_layout_spec.lua` (whole module); `validate_routes.lua -q --strict --end-level --summary $G` | 23 successes; exit 0, 11 routes, 0 ERROR, 0 WARN, 188 accepted |
| the hand-over contract of B.2 (`--write-state ... --until h-12-orgrimmar-tirisfal`) | unchanged: level 13.24, log = { 95350 }, hearth Valanaar, flight point Thunder Bluff, at Doras |
