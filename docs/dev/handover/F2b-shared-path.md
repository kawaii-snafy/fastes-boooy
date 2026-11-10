# Hand-over F2b: the shared path 12-22

Phase F2b of `docs/dev/PLAN.md` (D.2, step F2b; B.3-B.9, C.2, C.6, C.7). Nothing was committed (the orchestrator
commits). The six legacy segments are gone; the Undead paladin and the Skyborne druid now walk 12-22 on the four
shared segments `h-12-orgrimmar-tirisfal`, `h-13-silverpine`, `h-15-barrens`, `h-18-stonetalon-ashenvale`, which
are written for all five races. `G` = `addons/FastesBoooy_Guides`.

**For the commit:** `git add -A addons docs Makefile tests tools` takes everything of this phase. One thing to know:
I ran `git rm -r --cached G/Segments/Legacy` by mistake (an index operation that D.0 rule 1 does not allow me). The
six deletions are therefore already staged; the working tree agrees with them (the directory is deleted), so the
result is what `git add -A` stages anyway. I did not touch the index again to undo it (that would have needed
`git reset` / `git restore --staged`). No other git command that changes state was run.

## 1. What changed

| File | Change |
|---|---|
| `G/Segments/Shared/12_Orgrimmar_Tirisfal.lua` | new: `h-12-orgrimmar-tirisfal`, 24 steps (the former `sd-03` steps 10-34 without the Skyborne and druid steps) |
| `G/Segments/Shared/13_Silverpine.lua` | new: `h-13-silverpine`, 53 steps (order of the former `ud-03`) |
| `G/Segments/Shared/15_Barrens.lua` | new: `h-15-barrens`, 103 steps (order of `ud-04` + 875, optional 883, Verog as its own step, 1483 / 1069 / 878 accepted on the way, Regthar 851 -> 852 before the timed 853) |
| `G/Segments/Shared/18_Stonetalon_Ashenvale.lua` | new: `h-18-stonetalon-ashenvale`, 98 steps (order of `ud-05` + 875, optional 884 / 6641, Piznik optional, 1489 -> 1490 at Thunder Bluff 2) |
| `G/Segments/Legacy/*` (6 files) | deleted |
| `G/Segments/Zephras/03_ThunderBluff.lua` | segment `sd-03-thunder-bluff` (4 steps: `sd03-cliff`, `sd03-spirit`, `sd03-fp-tb`, `sd03-fly-org`); the announcement now lists it (still `only = { "DRUID" }`) |
| `G/Segments/Shared/22_Hillsbrad.lua` | B.7: no race filter on `h-22-tb-start` and `h-22-tb-fly-org`; `h-22-tb-fly-xroads` and the two `go` steps deleted; **every step has an explicit id** (`h-22-uc-arrive` + 41 `h22-*`); header and the `segment-level` comment reworded |
| `G/Segments/Shared/24_Barrens_Stonetalon.lua` | B.7: no race filter on the three 6301 steps; new ids `h25-rebirth-seeds`, `h25-rebirth-turnin` |
| `G/Segments/Shared/50_Hinterlands_Searing_Steppes.lua` | B.7: `h50-owen-thadd` |
| `G/Segments/Shared/27_Ashenvale_Needles.lua` | ceiling of `h-27-ashenvale-needles-level-gate` 110 -> 130 (a base profile needs 122, see F2a hand-over) |
| `G/Segments/Shared/24_*.lua` .. `56_*.lua` (11 files) | comments only: the first header line and the "Hub plan" line no longer name the two old profiles |
| `G/Route.lua` | the `LEGACY` table and its branch are gone: final chains of A.4 |
| `G/FastesBoooy_Guides.toc` | the six `Segments\Legacy\...` lines removed (42 Lua files) |
| `G/Classes/Paladin.lua` | + 4 inserts for 12-22 (`pal-train-14`, `pal-train-18`, `pal-20-pools` + `pal-train-20`, `pal-train-22`); header |
| `G/Classes/Druid.lua` | + 8 inserts for 13-22 (ids below); the bridge insert `sd-bridge-fly-tb` is gone; level 40: `dru-40-fly-tb`, `dru-40-train`, `dru-40-fly-taurajo` (C.7), the five riding steps moved to the race file; header |
| `G/Races/Scourge.lua` | new: 4 inserts, 17 steps (`und-*`) |
| `G/Races/Skyborne.lua` | new: 4 inserts, 9 steps (`sky-*`) |
| `tools/overrides/shared.lua` | new: 861 and 854 lose 844 from `exclusive` (`verified = false`) |
| `tests/spec/guides_layout_spec.lua` | new, 23 cases (17 of the first round, 5 added in verification round 1, 1 in round 2) |
| `tests/fixtures/guides/FastesBoooy_StartZones/Segments/**` (7 files) | new: fixture start zones |
| `tests/fixtures/validator/guides_state_orc_11.json`, `guides_state_tauren_11.json`, `guides_state_tauren_11_fly.json` | new: synthetic hand-over states |
| `Makefile` | `SYNC_MID = 21/h-15-barrens 29/h-24-barrens-stonetalon` (and its comment) |
| `G/Data.lua`, `docs/VALIDATION.md` | regenerated |

Not changed although owned: `tests/spec/core_sync_spec.lua` (it names no legacy id; it passes as it is),
`tools/gen_route_data.lua` (`make routedata` reports no place without a ruRU name: no new `fp` / `fly` /
`sethearth` / `hearth` place).

### The four segments in one view

| Segment | Start | Race-filtered steps (F) | Join steps | Gates |
|---|---|---|---|---|
| `h-12` (all but Scourge) | Doras in Orgrimmar (`h12-fp-org`) | none | - | none (P2 decides for `h12-org-end` / `h12-fp-uc`, B.9) |
| `h-13` | Deathstalker Erland (`h13-erland`) | Scourge: `h13-hadrec-440`, `h13-hearth-brill`, `h13-sevren`, `h13-raleigh`, `h13-uc-lift`, `h13-zeppelin`, `h13-durotar`; the other four: `h13-fly-uc`, `h13-hearth-org` | `h13-uc-arrive`; `h15-org` | `h13-lvl-12` (421), `h13-lvl-14` (13 + 92 %) |
| `h-15` | Orgrimmar | Scourge: `h15-org-gate`, `h15-org-fp` | `h15-org` | none (`h15-lvl-16` is not needed: no kept quest needs it) |
| `h-18` | Devrak at the Crossroads, 853 running | Skyborne + Tauren: `h18-fly-tb-1`; Orc + Scourge + Troll: `h18-go-mulgore`, `h18-go-tb-lift`, and after the join `h18-fp-tb` (right before `h18-fly-ratchet`, deviation 15) | `h18-tb-zamah` | `h18-lvl-18`, `h18-lvl-20` (19 + 88 %), `h18-lvl-21` (216), `h18-lvl-22` (21 + 85 %) |

Every anchor of C.2 exists with the planned id; the layout spec pins the list and which of them are filtered.
What the anchors that the plan left open are:

| Anchor | Step |
|---|---|
| `h12-borstan` | 97246 -> 97249 at Borstan (the Drag) |
| `h12-wisdom` | turn-in of 97249 at Migi (Valley of Wisdom); the optional 97326 trio follows it |
| `h12-org-end` | `go`, radius 25, at Zor Lonetree's spot on the way out of the Valley of Wisdom: after every city quest step |
| `h13-sepulcher-5` | turn-in of 439 at Hadrec (the last generic step of the visit) |
| `h13-uc-arrive` | `go`, radius 30, at Michael Garrett (Trade Quarter): done on landing for the flyers |
| `h13-uc-end` | 1359 -> 1358 at Zinge |
| `h15-org` | `go`, radius 80, at the midpoint of the inn and Doras (133 yd apart) |
| `h15-xr-2`, `h15-xr-3`, `h15-xr-4`, `h15-xr-5` | the last generic quest step of that Crossroads visit (Thork 871 -> 872; Sergra 845 -> 903; Mankrik 4921 + 95774 + 899; Gazrog 3281) |
| `h15-ratchet-2`, `h15-ratchet-3` | Gazlowe 892 -> 888; Mebok (accept 865 + 1069); the optional 896 / keg steps follow |
| `h15-end` | Helbrim 848 -> 853 |
| `h18-tb-1` | `go`, radius 15, the exit of the Pools of Vision on Spirit Rise (after Zamah, before the way to Tal; for the races that walked in, `h18-fp-tb` follows it) |
| `h18-ratchet` | Gazlowe, turn-in of 888 |
| `h18-taurajo-end` | Jorn, turn-in of 913 |
| `h18-xr` | Mankrik + Tonga: 899 + 880 -> 1489 |
| `h18-border` | Seereth + Makaba: accept 1062 + 6548 |
| `h18-tb-2` | Nara Wildmane, turn-in of 1490 (Elder Rise) |
| `h18-tb-3` | Magatha 1063 -> 1064 (Elder Rise) |
| `h18-end` | Zamah, turn-in of 1064; the next step, `h-22-tb-start`, accepts 1065 from her |
| `h-22-uc-arrive` | the arrival `go` step at the Tirisfal zeppelin tower (the same kind of step as `h-41-uc-arrive`) |

New ids (all explicit; nothing positional is left in `h-12` .. `h-22`):

* `h-12`: h12-fp-org h12-sethearth-org h12-thatog h12-borstan h12-korgeld h12-cattails h12-korgeld-2 h12-yelmak
  h12-whuut h12-wisdom h12-boulders-accept h12-boulders h12-boulders-turnin h12-org-end h12-zeppelin h12-tirisfal
  h12-brill h12-johaan h12-hadric h12-cult-camp h12-hadric-2 h12-fp-uc h12-sewers h12-end
* `h-13`, `h-15`, `h-18`: 53 + 103 + 98 ids, see the files (the ids not named in C.2 are free to change until the
  anchor freeze, the C.2 ones are not).
* `Races/Scourge.lua`: und-uc-exit und-silverpine-road (interim, see section 5) und-6321-podrig und-6321-karos
  und-6323-wendham und-6322-garrett und-org-thatog und-org-borstan und-org-korgeld und-org-cattails
  und-org-korgeld-2 und-org-yelmak und-org-whuut und-org-migi und-org-boulders-accept und-org-boulders
  und-org-boulders-turnin
* `Races/Skyborne.lua`: sky-thrall sky-1061 (before `h12-org-end`) sky-98024-thork (before `h15-xr-thork`)
  sky-1061-turnin (before `h18-border`) sky-40d-path sky-40d-skycutter sky-40d-riding sky-40d-back sky-40d-tb
  (after `dru-40-train`, `class = "DRUID"`)
* `Classes/Druid.lua`: dru-zep-tb-bridge dru-zep-tb-elder-rise dru-zep-tb-train dru-zep-child dru-zep-tb-back
  (after `sd03-spirit`, Skyborne) dru-moonglade-94913 (Skyborne) dru-train-14 (before `h13-hearth-org`)
  dru-train-16 (before `h15-hearth-xroads`) dru-train-18 (before `h18-hearth-taurajo`) dru-cat-start
  dru-cat-dendrite dru-cat-avatar dru-cat-dens dru-cat-relics dru-cat-avatar-2 dru-cat-dendrite-2
  dru-cat-hearth-tb dru-cat-form (after `h18-tb-2`, Skyborne) dru-train-20 (after `h18-tb-2`) dru-train-22
  (before `h18-hearth-tb`); renamed: dru-40-fly-tb dru-40-train dru-40-fly-taurajo
* `Classes/Paladin.lua`: pal-train-14 (after `h13-uc-end`) pal-train-18 (after `h18-tb-zamah`) pal-20-pools
  pal-train-20 (after `h18-tb-2`) pal-train-22 (after `h-22-tb-start`)
* `h-22-hillsbrad`: h-22-uc-arrive h22-rol-morbin h22-rol-griffs h22-rol-dungeon h22-rol-items
  h22-rol-apothecarium h22-rol-morbin-2 h22-rol-oran h22-book-of-ur h22-uc-garrett h22-sfk-accept
  h22-sfk-vincent h22-sfk-book h22-sfk-arugal h22-sfk-dalar h22-go-ambermill h22-tortured-soul
  h22-offering-stone-2 h22-offering-stone-3 h22-go-hillsbrad h22-lydon h22-darthalia h22-posters h22-krusk
  h22-bears-bg h22-lions-bg h22-dangerous-bg h22-darthalia-2 h22-samsa h22-skulls-bg h22-durnholde h22-togthar
  h22-drull h22-go-fields h22-peasants h22-lydon-2 h22-umpi h22-darthalia-3 h22-scout-support h22-krusk-2
  h22-smithy h22-samsa-2; `h-24`: h25-rebirth-seeds h25-rebirth-turnin; `h-50`: h50-owen-thadd

Race scope of the druid file (D.2, F2b step 2): the Tauren druid harness run passes with the training inserts
and the Torwa chain unscoped, so they carry no race. Skyborne-scoped: the Thunder Bluff visit at 13 (94911 /
94913), `dru-moonglade-94913` and the whole Cat Form chain. `dru-train-14` sits on a filtered anchor
(`h13-hearth-org`) and therefore has `race = { "Skyborne", "Tauren" }` (A.5.1 rule 10).

## 2. Acceptance: commands run and results

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 176 files |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --grind-until h-18-stonetalon-ashenvale $G` | exit 0: "1 module(s), 0 error(s), 0 warning(s), 36 accepted (strict)"; shared part 21 segments, 47 inserts, 1,990 steps |
| `... --route undead-paladin --max-grind-until h-56-felwood-winterspring-plaguelands=4972/6179` | exit 0: **4,901 / 6,172** (baseline 4,972 / 6,179); 0 ERROR, 0 WARN, 17 accepted; end level 60.00 / 60.00; 1,745 composed steps |
| `... --route skyborne-druid --max-grind-until h-56-felwood-winterspring-plaguelands=4878/6082` | exit 0: **4,852 / 6,052** (baseline 4,878 / 6,082); 0 ERROR, 0 WARN, 19 accepted; end level 60.00 / 60.00; 1,781 composed steps |
| `lua5.1 tools/simulate_routes.lua --route undead-paladin $G` | `OK`: 1,745 steps, 721 accepted, 721 turned in, level 60, no warning |
| `lua5.1 tools/simulate_routes.lua --route skyborne-druid $G` | `OK`: 1,781 steps, 728 accepted, 727 turned in, 13 reward choices checked; the two warnings of the baseline (`sd02-hearth` bind point; the optional accept of 1061 at level 12, now on `sky-1061`) |
| five harness proofs (below) | all exit 0, 0 ERROR; Orc WARRIOR and Troll PRIEST **72 / 174**, the three Tauren runs **38 / 138** kills up to the end of `h-18` (budget 120 / 200); end level 60.00 / 60.00 |
| `busted tests/spec/guides_layout_spec.lua` | 23 successes, 2.8 s (17 before verification round 1, 22 before round 2) |
| `GUIDES_SKIP=... GUIDES_OWN=... busted tests/spec/guides_layout_spec.lua` (the two F2c command lines) | 12 successes each (8 before verification round 1) |
| `make routedata-check` | exit 0 |
| `make check` | exit 0, 4 min 35 s on the final tree (after verification round 2; 3 min 40 s after round 1): luacheck 0 / 0 in 176 files; busted **695 successes / 0 failures / 0 errors** (689 before round 1, 694 before round 2); `make validate` 0 ERROR, 0 WARN, 36 accepted; simulate 2 of 2 `OK`; simulate-sync 16 of 16 (with `--ahead 21 --ahead-at h-15-barrens`); fixture simulations 5 of 5; harness fixture 4 runs. Simulator warnings: only the three known ones (`sd02-hearth` bind point, the optional `sky-1061` at level 12, `h-53-azshara-ungoro-silithus:41` in the `--level-plus 4` runs) |
| report freshness, `make package` | `lua5.1 tools/validate_routes.lua -q --markdown <tmp>` equals `docs/VALIDATION.md`; `make package` exit 0 |

The harness proofs (`SEGS` = `h-12-orgrimmar-tirisfal,h-13-silverpine,...,h-56-felwood-winterspring-plaguelands`,
`V` = `lua5.1 tools/validate_routes.lua --harness $G --segments $SEGS --strict --end-level --max-grind-until
h-18-stonetalon-ashenvale=120/200`, `F` = `tests/fixtures/validator`):

```
$V --profile race=Orc,class=WARRIOR,faction=Horde   --state $F/guides_state_orc_11.json
$V --profile race=Troll,class=PRIEST,faction=Horde  --state $F/guides_state_orc_11.json
$V --profile race=Tauren,class=WARRIOR,faction=Horde --skip 'Classes/*' --state $F/guides_state_tauren_11.json     --ignore db-override-unverified
$V --profile race=Tauren,class=DRUID,faction=Horde                      --state $F/guides_state_tauren_11.json     --ignore db-override-unverified
$V --profile race=Tauren,class=WARRIOR,faction=Horde --skip 'Classes/*' --state $F/guides_state_tauren_11_fly.json --ignore db-override-unverified
```

They are the describe block "the shared path from the hand-over states of Durotar and Mulgore" of the layout
spec, with one more case that pins what `--ignore` hides (deviation 1). The simulator harness
(`tools/simulate_routes.lua --harness`, same segments, states and profiles; not part of the acceptance) also
prints `OK` for Orc WARRIOR, Troll PRIEST, Tauren DRUID and the Tauren flight state, with no warning.

### summary lines

```
undead-paladin	Scourge PALADIN Horde	0	0	17	0	60.00	60.00	4901	6172	4	102    # undead-paladin
skyborne-druid	Skyborne DRUID Horde	0	0	19	0	60.00	60.00	4852	6052	0	24    # skyborne-druid
harness-Guides	Orc WARRIOR Horde	0	0	17	0	60.00	60.00	5007	6244	72	174    # Orc WARRIOR (state orc_11)
harness-Guides	Troll PRIEST Horde	0	0	17	0	60.00	60.00	5007	6244	72	174    # Troll PRIEST (state orc_11)
harness-Guides	Tauren WARRIOR Horde	0	2	17	0	60.00	60.00	4973	6208	38	138    # Tauren WARRIOR base (tauren_11)
harness-Guides	Tauren DRUID Horde	0	2	17	0	60.00	60.00	4930	6165	38	138    # Tauren DRUID (tauren_11)
harness-Guides	Tauren WARRIOR Horde	0	2	17	0	60.00	60.00	4973	6208	38	138    # Tauren WARRIOR base (tauren_11_fly)
harness-Guides	Scourge WARRIOR Horde	0	0	16	0	60.00	60.00	4979	6208	44	138    # Scourge WARRIOR base, preview from 12.09
```

### per segment: level in -> out, grind kills normal / worst

| Segment | undead-paladin | skyborne-druid | Orc WARRIOR (state orc_11) | Troll PRIEST (state orc_11) | Tauren WARRIOR base (tauren_11) | Tauren DRUID (tauren_11) | Tauren WARRIOR base (tauren_11_fly) | Scourge WARRIOR base, preview from 12.09 |
|---|---|---|---|---|---|---|---|---|
| `ud-01-deathknell` | 1.00 -> 5.88, 1 / 1 | - | - | - | - | - | - | - |
| `ud-02-tirisfal` | 5.88 -> 12.78, 0 / 0 | - | - | - | - | - | - | - |
| `sd-01-zephras` | - | 1.00 -> 9.95, 0 / 0 | - | - | - | - | - | - |
| `sd-02-zephras` | - | 9.95 -> 13.32, 0 / 0 | - | - | - | - | - | - |
| `sd-03-thunder-bluff` | - | 13.32 -> 13.35, 0 / 0 | - | - | - | - | - | - |
| `h-12-orgrimmar-tirisfal` | - | 13.35 -> 14.17, 0 / 0 | 11.20 -> 12.27, 0 / 0 | 11.20 -> 12.27, 0 / 0 | 11.80 -> 12.78, 0 / 0 | 11.80 -> 12.78, 0 / 0 | 11.80 -> 12.78, 0 / 0 | - |
| `h-13-silverpine` | 12.78 -> 14.56, 0 / 0 | 14.17 -> 15.55, 0 / 0 | 12.27 -> 14.08, 6 / 14 | 12.27 -> 14.08, 6 / 14 | 12.78 -> 14.40, 0 / 0 | 12.78 -> 14.40, 0 / 0 | 12.78 -> 14.40, 0 / 0 | 12.09 -> 14.22, 20 / 20 |
| `h-15-barrens` | 14.56 -> 18.32, 0 / 0 | 15.55 -> 18.75, 0 / 0 | 14.08 -> 17.80, 0 / 0 | 14.08 -> 17.80, 0 / 0 | 14.40 -> 18.01, 0 / 0 | 14.40 -> 18.01, 0 / 0 | 14.40 -> 18.01, 0 / 0 | 14.22 -> 18.14, 0 / 0 |
| `h-18-stonetalon-ashenvale` | 18.32 -> 22.04, 3 / 101 | 18.75 -> 22.44, 0 / 24 | 17.80 -> 22.04, 66 / 160 | 17.80 -> 22.04, 66 / 160 | 18.01 -> 22.04, 38 / 138 | 18.01 -> 22.04, 38 / 138 | 18.01 -> 22.04, 38 / 138 | 18.14 -> 22.05, 24 / 118 |
| `h-22-hillsbrad` | 22.04 -> 25.10, 0 / 51 | 22.44 -> 25.12, 0 / 52 | 22.04 -> 24.82, 0 / 51 | 22.04 -> 24.82, 0 / 51 | 22.04 -> 24.82, 0 / 51 | 22.04 -> 24.82, 0 / 51 | 22.04 -> 24.82, 0 / 51 | 22.05 -> 24.82, 0 / 51 |
| `h-24-barrens-stonetalon` | 25.10 -> 27.51, 0 / 220 | 25.12 -> 27.52, 0 / 220 | 24.82 -> 27.30, 0 / 220 | 24.82 -> 27.30, 0 / 220 | 24.82 -> 27.30, 0 / 220 | 24.82 -> 27.30, 0 / 220 | 24.82 -> 27.30, 0 / 220 | 24.82 -> 27.31, 0 / 220 |
| `h-27-ashenvale-needles` | 27.51 -> 31.01, 84 / 313 | 27.52 -> 31.01, 82 / 313 | 27.30 -> 31.01, 122 / 313 | 27.30 -> 31.01, 122 / 313 | 27.30 -> 31.01, 122 / 313 | 27.30 -> 31.01, 122 / 313 | 27.30 -> 31.01, 122 / 313 | 27.31 -> 31.01, 122 / 314 |
| `h-31-hillsbrad-arathi` | 31.01 -> 34.06, 274 / 327 | 31.01 -> 34.06, 274 / 326 | 31.01 -> 34.06, 274 / 327 | 31.01 -> 34.06, 274 / 327 | 31.01 -> 34.06, 274 / 327 | 31.01 -> 34.06, 274 / 327 | 31.01 -> 34.06, 274 / 327 | 31.01 -> 34.06, 274 / 326 |
| `h-34-stranglethorn` | 34.06 -> 36.06, 151 / 151 | 34.06 -> 36.06, 151 / 152 | 34.06 -> 36.06, 151 / 151 | 34.06 -> 36.06, 151 / 151 | 34.06 -> 36.06, 152 / 151 | 34.06 -> 36.06, 152 / 151 | 34.06 -> 36.06, 152 / 151 | 34.06 -> 36.06, 151 / 152 |
| `h-37-desolace-dustwallow` | 36.06 -> 41.02, 1009 / 1029 | 36.06 -> 41.02, 1009 / 1029 | 36.06 -> 41.02, 1009 / 1029 | 36.06 -> 41.02, 1009 / 1029 | 36.06 -> 41.02, 1008 / 1029 | 36.06 -> 41.02, 1008 / 1029 | 36.06 -> 41.02, 1008 / 1029 | 36.06 -> 41.02, 1009 / 1029 |
| `h-41-arathi-badlands` | 41.02 -> 44.02, 764 / 919 | 41.02 -> 44.02, 764 / 918 | 41.02 -> 44.02, 764 / 919 | 41.02 -> 44.02, 764 / 919 | 41.02 -> 44.02, 765 / 919 | 41.02 -> 44.02, 765 / 919 | 41.02 -> 44.02, 765 / 919 | 41.02 -> 44.02, 764 / 918 |
| `h-44-swamp-stranglethorn` | 44.02 -> 46.01, 178 / 184 | 44.02 -> 46.01, 178 / 185 | 44.02 -> 46.01, 178 / 184 | 44.02 -> 46.01, 178 / 184 | 44.02 -> 46.01, 177 / 184 | 44.02 -> 46.01, 177 / 184 | 44.02 -> 46.01, 177 / 184 | 44.02 -> 46.01, 178 / 185 |
| `h-46-tanaris-feralas` | 46.01 -> 49.40, 617 / 715 | 46.01 -> 49.40, 617 / 715 | 46.01 -> 49.40, 617 / 715 | 46.01 -> 49.40, 617 / 715 | 46.01 -> 49.40, 617 / 715 | 46.01 -> 49.40, 617 / 715 | 46.01 -> 49.40, 617 / 715 | 46.01 -> 49.40, 617 / 715 |
| `h-50-hinterlands-searing-steppes` | 49.40 -> 52.57, 154 / 308 | 49.40 -> 52.57, 154 / 308 | 49.40 -> 52.57, 154 / 308 | 49.40 -> 52.57, 154 / 308 | 49.40 -> 52.57, 154 / 308 | 49.40 -> 52.57, 154 / 308 | 49.40 -> 52.57, 154 / 308 | 49.40 -> 52.57, 154 / 307 |
| `h-53-azshara-ungoro-silithus` | 52.57 -> 55.04, 362 / 392 | 52.57 -> 55.05, 319 / 349 | 52.57 -> 55.04, 362 / 392 | 52.57 -> 55.04, 362 / 392 | 52.57 -> 55.04, 362 / 392 | 52.57 -> 55.05, 319 / 350 | 52.57 -> 55.04, 362 / 392 | 52.57 -> 55.04, 362 / 392 |
| `h-56-felwood-winterspring-plaguelands` | 55.04 -> 60.00, 1304 / 1461 | 55.05 -> 60.00, 1304 / 1461 | 55.04 -> 60.00, 1304 / 1461 | 55.04 -> 60.00, 1304 / 1461 | 55.04 -> 60.00, 1304 / 1461 | 55.05 -> 60.00, 1304 / 1460 | 55.04 -> 60.00, 1304 / 1461 | 55.04 -> 60.00, 1304 / 1461 |

### gates of 12-22: kills normal / worst

| Gate | undead-paladin | skyborne-druid | Orc WARRIOR (state orc_11) | Troll PRIEST (state orc_11) | Tauren WARRIOR base (tauren_11) | Tauren DRUID (tauren_11) | Tauren WARRIOR base (tauren_11_fly) | Scourge WARRIOR base, preview from 12.09 |
|---|---|---|---|---|---|---|---|---|
| `h13-lvl-12` | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| `h13-lvl-14` | 0 / 0 | 0 / 0 | 6 / 14 | 6 / 14 | 0 / 0 | 0 / 0 | 0 / 0 | 20 / 20 |
| `h18-lvl-18` | 0 / 1 | 0 / 0 | 27 / 60 | 27 / 60 | 0 / 38 | 0 / 38 | 0 / 38 | 0 / 18 |
| `h18-lvl-20` | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| `h18-lvl-21` | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| `h18-lvl-22` | 3 / 100 | 0 / 24 | 39 / 100 | 39 / 100 | 38 / 100 | 38 / 100 | 38 / 100 | 24 / 100 |
| `h-22-hillsbrad-level-gate` | 0 / 51 | 0 / 52 | 0 / 51 | 0 / 51 | 0 / 51 | 0 / 51 | 0 / 51 | 0 / 51 |
| `h-24-barrens-stonetalon-level-gate` | 0 / 220 | 0 / 220 | 0 / 220 | 0 / 220 | 0 / 220 | 0 / 220 | 0 / 220 | 0 / 220 |
| `h-27-ashenvale-needles-level-gate` | 84 / 313 | 82 / 313 | 122 / 313 | 122 / 313 | 122 / 313 | 122 / 313 | 122 / 313 | 122 / 314 |

The last column is not an acceptance run: it is a preview of the base Undead (the paladin's state before
`h-13`, the twelve paladin quests removed from `done`, level set to the 12.09 of appendix 1). It replaces the
108 / 147 kills of 1-22 of the old path by 44 / 138. A base Skyborne from level 13.0 (the druid's state before
`h-12` without 94913): 0 / 68, 0 WARN.

### Levels at the anchors (before the step; normal, or normal / worst case)

| Anchor | Orc / Troll base | Tauren base | Undead base (preview) | undead-paladin | skyborne-druid |
|---|---|---|---|---|---|
| `h12-fp-org` | 11.20 | 11.80 | - | - | 13.35 / 13.29 |
| `h12-org-end` | 11.80 / 11.68 | 12.35 / 12.24 | - | - | 13.87 / 13.72 |
| `h12-fp-uc` | 12.27 / 12.18 | 12.78 / 12.67 | - | - | 14.17 / 14.06 |
| `h12-end` | 12.27 / 12.18 | 12.78 / 12.67 | - | - | 14.17 / 14.06 |
| `h13-erland` | 12.27 / 12.18 | 12.78 / 12.67 | 12.09 | 12.78 / 12.65 | 14.17 / 14.06 |
| `h13-lvl-12` | 12.39 / 12.30 | 12.90 / 12.80 | 12.21 | 12.91 / 12.78 | 14.26 / 14.15 |
| `h13-sepulcher-5` | 13.84 / 13.77 | 14.24 / 14.16 | 13.71 | 14.26 / 14.16 | 15.37 / 15.27 |
| `h13-lvl-14` | 13.87 / 13.79 | 14.26 / 14.18 | 13.73 | 14.28 / 14.18 | 15.39 / 15.29 |
| `h13-uc-arrive` | 13.93 | 14.26 / 14.18 | 13.98 | 14.32 / 14.23 | 15.39 / 15.29 |
| `h13-uc-end` | 14.07 | 14.40 / 14.32 | 14.21 | 14.55 / 14.46 | 15.51 / 15.41 |
| `h15-org` | 14.08 | 14.40 / 14.33 | 14.62 / 14.54 | 14.97 / 14.79 | 15.55 / 15.45 |
| `h15-razor-hill` | 14.08 | 14.40 / 14.33 | 14.62 / 14.54 | 14.97 / 14.79 | 15.55 / 15.45 |
| `h15-far-watch` | 14.08 | 14.40 / 14.33 | 14.62 / 14.54 | 14.97 / 14.79 | 15.55 / 15.45 |
| `h15-xr-arrive` | 14.12 | 14.44 / 14.36 | 14.66 / 14.58 | 15.00 / 14.83 | 15.58 / 15.48 |
| `h15-sethearth-xroads` | 14.27 | 14.59 / 14.52 | 14.81 / 14.73 | 15.14 / 14.98 | 15.76 / 15.66 |
| `h15-fp-ratchet` | 14.84 | 15.13 / 15.07 | 15.31 / 15.25 | 15.59 / 15.44 | 16.18 / 16.09 |
| `h15-hearth-xroads` | 16.63 / 16.61 | 16.85 / 16.79 | 17.01 / 16.95 | 17.22 / 17.08 | 17.70 / 17.60 |
| `h15-xr-4` | 16.84 / 16.82 | 17.06 / 17.00 | 17.21 / 17.15 | 17.41 / 17.28 | 17.89 / 17.80 |
| `h15-ratchet-3` | 17.02 / 17.00 | 17.22 / 17.16 | 17.37 / 17.31 | 17.57 / 17.44 | 18.04 / 17.96 |
| `h15-fp-taurajo` | 17.29 / 17.12 | 17.50 / 17.28 | 17.64 / 17.43 | 17.84 / 17.55 | 18.28 / 18.06 |
| `h15-xr-5` | 17.61 / 17.37 | 17.81 / 17.53 | 17.96 / 17.67 | 18.15 / 17.80 | 18.57 / 18.29 |
| `h15-end` | 17.74 / 17.50 | 17.95 / 17.66 | 18.08 / 17.80 | 18.27 / 17.93 | 18.69 / 18.41 |
| `h18-lvl-18` | 17.81 / 17.57 | 18.01 / 17.73 | 18.15 / 17.87 | 18.33 / 18.00 | 18.76 / 18.47 |
| `h18-tb-zamah` | 18.01 | 18.01 | 18.15 / 18.00 | 18.33 / 18.01 | 18.76 / 18.47 |
| `h18-tb-1` | 18.05 | 18.05 | 18.19 / 18.04 | 18.37 / 18.05 | 18.80 / 18.51 |
| `h18-hearth-taurajo` | 18.29 / 18.24 | 18.30 / 18.24 | 18.43 / 18.24 | 18.61 / 18.24 | 19.03 / 18.70 |
| `h18-taurajo-end` | 19.44 / 19.33 | 19.44 / 19.33 | 19.55 / 19.33 | 19.69 / 19.33 | 20.05 / 19.70 |
| `h18-xr` | 19.53 / 19.42 | 19.53 / 19.42 | 19.64 / 19.42 | 19.78 / 19.42 | 20.13 / 19.79 |
| `h18-border` | 19.83 / 19.72 | 19.84 / 19.72 | 19.94 / 19.72 | 20.08 / 19.72 | 20.41 / 20.08 |
| `h18-lvl-20` | 20.23 / 20.13 | 20.24 / 20.13 | 20.33 / 20.13 | 20.47 / 20.13 | 20.80 / 20.47 |
| `h18-tb-2` | 20.36 / 20.26 | 20.36 / 20.26 | 20.46 / 20.26 | 20.59 / 20.26 | 20.92 / 20.60 |
| `h18-fp-zoram` | 21.16 / 20.87 | 21.16 / 20.87 | 21.25 / 20.86 | 21.37 / 20.87 | 21.82 / 21.34 |
| `h18-lvl-21` | 21.31 / 21.04 | 21.32 / 21.04 | 21.40 / 21.04 | 21.53 / 21.05 | 21.98 / 21.49 |
| `h18-lvl-22` | 21.62 / 21.26 | 21.62 / 21.26 | 21.71 / 21.26 | 21.83 / 21.26 | 22.26 / 21.71 |
| `h18-hearth-tb` | 22.01 | 22.00 / 22.01 | 22.01 | 22.01 | 22.40 / 22.00 |
| `h18-tb-3` | 22.01 | 22.00 / 22.01 | 22.01 | 22.01 | 22.40 / 22.00 |
| `h18-end` | 22.03 | 22.03 | 22.03 | 22.03 | 22.43 / 22.03 |
| `h-22-tb-start` | 22.04 / 22.05 | 22.04 / 22.05 | 22.05 / 22.04 | 22.04 / 22.05 | 22.44 / 22.04 |
| `h-22-org-fp` | 22.04 / 22.05 | 22.04 / 22.05 | 22.05 / 22.04 | 22.04 / 22.05 | 22.44 / 22.04 |
| `h-22-uc-arrive` | 22.04 / 22.05 | 22.04 / 22.05 | 22.05 / 22.04 | 22.04 / 22.05 | 22.44 / 22.04 |

B.2, "common rule": `h13-lvl-12` needs 0 kills (worst 0) for every profile above.

End state of `h-18` (B.6), read from `--write-state ... --until h-22-hillsbrad` for the two routes and from the
end state of a harness run over `h-12` .. `h-18` for the Orc state and the Tauren flight state: in all four the
hearth is Thunder Bluff, the flight points are Camp Taurajo, Orgrimmar, Ratchet, Sun Rock Retreat, The
Crossroads, The Sepulcher, Thunder Bluff, Undercity, Zoram'gar Outpost, 1064 / 5052 / 913 / 1095 / 6562 are
turned in, 1065 is not in the log, 6301 is not done; the log is empty (the Orc state still carries 806, 837,
99051, which the Durotar insert `dur02-rh-return` will hand in). Level 22.04 (the druid 22.44).

## 3. Deviations from the plan, and why

1. **No `ok` for `db-override-unverified` on `h15-xr-arrive`; the Tauren proofs name it with `--ignore`.**
   E.21 wants the WARN acknowledged on the step. The WARN fires only for a Tauren (861 / 854 turned in), and no
   Tauren route exists before P1: on the full run of `make validate` an `ok` that no validated route uses is
   `WARN ok-unused`, which fails `--strict`. Without the `ok` the three Tauren harness runs report two unaccepted
   WARNs (one per breadcrumb) and would fail `--strict`. So the step carries a `-- CONFIRM` comment instead, the
   three Tauren proofs run with `--ignore db-override-unverified`, and one more spec case asserts, without
   `--ignore`, that these two WARNs on `h15-xr-arrive` are the only ones, and that with `--no-overrides` the
   accept is `ERROR accept-exclusive`. **P2** (first phase with a Tauren route in the full run) adds
   `ok = "db-override-unverified"`. Since verification round 1 the spec enforces this by itself: the case
   "acknowledges the unverified override of 861 / 854 exactly when a Tauren route exists" fails as soon as a
   Tauren route is registered and the key is missing (and while none is registered and the key is there), and
   the three proofs drop `--ignore` on their own once the step carries the key.
2. **`h13-lvl-14` is `{ 13, 0.92 }`, not `14`.** The plan placed a plain trainer-hub gate before the way back
   and expected "base Undead 14.0" there. That number is the level at the end of the Undercity visit; at the
   Sepulcher the base Undead is at 13.73 and a plain 14 costs 28 kills there, 14 for an Orc. The Undercity
   turn-ins every race makes after the gate are 447 (900 XP) and 1359 (110 XP), both known values: 8.9 % of
   level 13. With 13 + 92 % the level is 14.0 at `h13-uc-end`, which is the training anchor, and the gate costs
   6 kills for the Orc and 20 for the base Undead (the estimated 97891 and the Undead-only 440 / 441 / 6321-6323
   are not counted on purpose).
3. **`h18-lvl-22` is `{ 21, 0.85 }` at Thistlefur Village; there is no second gate at the last turn-in.** The
   old Undead segment had the grind gate 21 + 85 % at the furbolgs and a `level = 22` on the last Zoram'gar
   turn-in. The plan lists one id; the one gate stands where the mobs are and guarantees 22.0 after 216 + 6462
   (3,900 XP >= 15 % of 25,200). `ok = { ["level-grind"] = 45 }` (the B.8 limit of a trainer-hub gate; the
   proofs need 38-39, the paladin 3).
4. **`h-12` carries `ok = "segment-level"`.** The four races enter it between 11.2 and 13.3 and leave it between
   12.3 and 14.2; no planned end level is within one level of all of them. `levels = { 12, 13 }` fits Orc, Troll,
   Tauren and a base Skyborne (13.86); the druid route ends it at 14.17.
5. **Interim steps in `Races/Scourge.lua`.** B.2 lets `ud-02` end on the Silverpine road, but `ud-02` is not
   mine and still ends in the Undercity. The two `go` steps (lift, road) are `und-uc-exit` and
   `und-silverpine-road`, `before = "h13-erland"`. The Tirisfal agent of F2c moves them into `ud-02`
   (`ud02-silverpine-road`) and deletes the insert (the header of the file says so).
6. **`FastesBoooy_Guides.toc` was edited** (not in the F2b ownership list): the six Legacy lines had to go with
   the directory (F2a hand-over, open issue 1).
7. **The Cat Form chain uses the hearthstone inside a class insert** (`dru-cat-hearth-tb`, C.3 rule 3 allows
   that only right before a shared hearth step). It is the old route's behaviour: the stone is bound to Thunder
   Bluff one shared step earlier (`h18-sethearth-tb`) and the shared path uses it again more than an hour later,
   from Zoram'gar. The alternative is Bunthen's druid-only flight from Nighthaven (minutes in the air); the note
   names it as the fallback. Phase C may decide otherwise.
8. **`pal-train-22` is anchored `after = "h-22-tb-start"`, not on `h18-tb-3` / `h18-end`.** Zamah offers 1065
   in the dialog that turns in 1064, so a transient step between the two would be fast-forwarded by the
   automation. For the same reason `h18-tb-3` is the Magatha step and `h18-end` the Zamah turn-in: classes with
   a trainer on another rise train after `h18-tb-3`, a class whose trainer stands in the Pools of Vision after
   `h-22-tb-start`.
9. **`dru-train-14` is mandatory** (the old step was optional): the gate guarantees the level.
10. **The fixture start zones live in `tests/fixtures/guides/FastesBoooy_StartZones/Segments/...`**, mirroring
    the TOC paths: `.luacheckrc` (not mine) gives the route std only to `tests/fixtures/*/FastesBoooy_*/**`.
    Seven files, not five: the fixture also replaces `Tirisfal/02_Tirisfal.lua` and `Zephras/03_ThunderBluff.lua`
    (one-step segments and announcements without `only`), because 28 routes cannot be registered while the
    real announcements carry `only`. After F2c the two extra replacements are harmless and F2d may drop them.
11. **The layout spec exempts a zone that still has `only` from the "no `reward` on a shared base step" case**
    (`sd-01` / `sd-02` hold 13 `reward` fields until F2c). It reads the announcements from the source text, so
    the exemption and the expected route list follow the files without an edit of the spec.
12. **The harness proofs name the override directory** (`--overrides tools/overrides`):
    `validator_overrides_spec.lua` forbids a spec command line that reads it by default. The dependency is
    intended: the proofs are about the real module with its real override.
13. **`guides_state_tauren_11_fly.json` keeps 854 / 860 / 886 in `done`** as D.2 says ("the same `done`"),
    although E.1 says that in the flight variant they are turned in later by `mul03-xr-turnins`. The state
    proves what it is for: the shared path with only the Thunder Bluff flight point known.
14. **Small content decisions inside the plan's outline**: the turn-in of 875 is the first step of the second
    Crossroads visit of `h-18` (`h18-xr-darsok`, after `h18-fly-xroads-2`): the Slayers are killed after
    `h18-xr`; 896 and 97326 are optional from the accept on (the old segments accepted them unconditionally and
    left them in the log in the worst case); 1061 stays a Skyborne step although every race now passes Zor
    Lonetree (it needs level 13, the others are at 11.7-12.3 there); the wrong "blue thunderhawk" remark about
    Owatanka is gone (the bg step for 884 describes him).

15. **`h18-fp-tb` stands after the join, right before `h18-fly-ratchet`** (verification round 1). B.6 lists it
    inside the alternative pair, before `h18-tb-zamah`: lift -> Tal -> Pools of Vision -> Zamah -> Tal, 840 yd of
    straight legs, two climbs of the wind rider tower, the 45-minute timer of 853 running on the first visit. The
    legacy order and `routes.md` 4.4 (the outline of `h-18`, item 1) have Zamah first: lift -> Pools -> Zamah -> Tal, 664 yd, one
    visit. The step keeps its id and its race filter (C.2, the layout spec); `h18-tb-zamah` and `h18-tb-1` stay
    unfiltered anchors. An insert `before = "h18-fly-ratchet"` lands between the two Tal steps.

Not a deviation, but measured as B.8 asks: the Undead city loop (gate - Doras - Thatog - Borstan - Kor'geld -
Valley of Honor - Kor'geld - Migi - gate against gate - Doras - gate) adds 1,528 yd of straight legs, 3.6 min
at 420 yd per minute, for about 4,200 XP.

## 4. Notes for the next phases

### F2c (Tirisfal, Zephras)

* Tirisfal: end `ud-02` on the Silverpine road and delete the first insert of `Races/Scourge.lua` (deviation
  5). The riding insert of the non-paladin Undead classes (after `h-41-uc-arrive`) is yours.
* Zephras: the druid's Thunder Bluff steps are already in `Classes/Druid.lua` (`dru-zep-*`, after
  `sd03-spirit`). The riding insert of the non-druid Skyborne classes (after `h-40-org-arrive`, with its own
  `sky-40-fly-tb` / `sky-40-fly-taurajo`) is yours; the druid variant exists (`sky-40d-*`).
* The header table "22-60" of `Classes/Druid.lua` still shows the levels of the old route; they moved by up to
  0.2 (the druid now enters `h-22` at 22.44).
* Expect these numbers for the base profiles: table above (last column and the sentence under it). Both
  previews are **harness** runs from a state behind the start zone: they show no WARN on a shared file, and
  nothing more. A harness run skips the template checks (A.6.2) and holds no start-zone segment. The validator
  on the module with the class files skipped (`--skip 'Classes/*'`, the base-profile command of F2d and P2) is
  **not** clean on this tree (corrected in verification round 2; section 6, item 5):
  * ERROR `insert-anchor-unknown` for the Skyborne druid riding insert of `Races/Skyborne.lua`
    (`after = "dru-40-train"`, C.7): its anchor is a step of the skipped `Classes/Druid.lua`. It is reported for
    every `--route`, also for `undead-*` alone. Zephras agent: a preview of yours that skips `Classes/Druid.lua`
    reports it too, because `Races/Skyborne.lua` is own in your commands; your acceptance commands load the
    druid file and are not affected (checked: both `<F>` command lines of D.2 exit 0).
  * `skyborne-druid`: WARN `quest-carried` 94911 on `sd-02-zephras#70`. The accept is a druid step that still
    stands in the start zone, the turn-in (`dru-zep-child`) is in the skipped class file. It goes away when the
    Zephras agent moves the accept into `Classes/Druid.lua`.
  * Numbers of that run (`--summary`): `undead-paladin` without the class files 4,939 / 6,172 grind kills,
    `skyborne-druid` without them 4,911 / 6,124, end level 60.00 / 60.00, 0 ERROR in both routes. The start
    zones still hold their class steps, so these are not the base routes of F2c yet.

### P1 (Durotar, Mulgore)

* The anchors for the Durotar inserts exist: `h12-borstan`, `h12-wisdom`, `h12-zeppelin`, `h15-razor-hill`.
  `h-12` starts with `h12-fp-org` and `h12-sethearth-org`, as the contract says.
* The Mulgore agent will see two foreign WARNs `db-override-unverified` on `h15-xr-arrive` (deviation 1).
* With the synthetic states the Orc is at 11.80 at `h12-org-end`, 12.27 at `h13-erland`, 14.08 at `h15-org`,
  17.81 before `h18-lvl-18` (27 kills there, worst 60: the largest gate of the Orc; above 30 it becomes a WARN
  that needs a ceiling, which P2 can give once a base route fires it); the Tauren 12.35, 12.78, 14.40, 18.01.

### P2

* `h15-xr-arrive`: add `ok = "db-override-unverified"` (deviation 1). The layout spec fails without it as soon
  as a Tauren route is registered, and its three Tauren proofs then run without `--ignore` by themselves.
* `h13-lvl-14` (13 + 92 %, after the last Sepulcher turn-in) is open for tuning in two ways the round-1 review
  named: (a) move it before `h13-allister-2` with the fraction lowered by the known turn-ins of the last visit
  (478, 481, 424, 482, 439 = 2,290 XP, 20.1 % of level 13: `{ 13, 0.72 }`), so that a short character grinds on
  the way in and does not walk out and back (about 255 yd each way to the gluttons for the four races that fly
  from Karos; the Undead hearth from the field); (b) a lower fraction for the Undead, whose own turn-ins after
  the gate (440, 441, 6323, 6322 = 1,780 XP known) are not counted: about 16 of the base Undead's 20 kills are
  not needed for 14.0 at `h13-uc-end`. (b) needs a race-filtered pair of gates, which C.2 does not have today.
* The gate spec ("points every level gate of 12-22 at mobs of the player's level") reads `at` of the six gates:
  a gate that is moved needs a point with at least 10 same-level spawns within 200 yd.
* `h15-fp-xroads`, `h15-fp-taurajo` are unfiltered. In the Tauren walk state both `fp` steps validate without a
  message for a known point; the filter of B.5 is still to be set from the variant in force.
* `h-22-hillsbrad` keeps `ok = "segment-level"`: both class routes end it above 25 (25.10, 25.12), every base
  profile at 24.82. Decide when all routes exist (the comment above the key says the same).
* The ceilings: `h18-lvl-22` 45, `h-27-ashenvale-needles-level-gate` 130. No other gate of 12-22 has an `ok`:
  none needs more than 30 kills in the normal run of any profile measured here.
* The harness proofs lose their purpose once the real Orc, Troll and Tauren routes validate; they then only
  pin the synthetic states.

### Phase C

* Trainer anchors and their levels: the table above. Orgrimmar at 14 is `h15-org` (not `h15-start`); Thunder
  Bluff 1 is `h18-tb-zamah` (in the cave) or `h18-tb-1` (cave exit); Thunder Bluff 3 is `h18-tb-3` (Elder Rise)
  or `h-22-tb-start` (in the cave, deviation 8).
* A Tauren druid needs its own Cat Form chain (the insert after `h18-tb-2` is Skyborne-only) and registers it
  before `dru-train-20` if the training has to follow the turn-in at Turak.

### For the atlas (`docs/dev/ATLAS.md`)

* The alternative pairs (same place, different way there per race) and the per-race bridge segments are the
  two shapes in which "who walks where" is now data: a race filter on a base step, or another `UseSegments`
  list. An atlas page per zone can list both without knowing classes.

## 5. DB overrides, `-- CONFIRM`, foreign warnings

* `tools/overrides/shared.lua`: 861 and 854, `exclusive = { remove = { 844 } }`, `verified = false`.
* `-- CONFIRM`: `h15-xr-arrive` (E.21: is 844 offered to a Tauren after 861 / 854?); `sd03-fly-org` (E.2);
  `pal-train-14`, `pal-train-18`, `pal-train-20`, `pal-train-22` (E.3: paladin trainers in the Undercity and
  Thunder Bluff; the notes name Brill as the fallback); the 853 timer against the gate `h18-lvl-18` (45 minutes;
  the note keeps 15 for the way to Zamah: an Orc needs 27 kills, about 14 minutes, there).
* Foreign warnings: none. XP values for quests I may not override: none. New place names: none.

## 6. Open issues for the orchestrator

1. The staged deletions (top of this file).
2. Deviation 1 needs a decision only if `--ignore` in a proof is not acceptable; the alternative is to give
   `h15-xr-arrive` the `ok` now and let `make validate` run with `--ignore ok-unused` until P1, which needs a
   `Makefile` change outside `SYNC_MID`.
3. `tests/spec/validator_overrides_spec.lua` says in a comment that later phases "may not touch tests/**" and
   that no spec may depend on `tools/overrides`. The layout spec does, on purpose and explicitly (deviation
   12). If a class override file later changes the numbers of the Tauren DRUID proof, the proof fails in a file
   the class agent cannot edit; P2 may retire the proofs before phase C (section 4).
4. Stale documentation outside my files, unchanged from the F2a list: `README.md`, `docs/routes/*.md` (F2d),
   `docs/ARCHITECTURE.md`, `docs/ROUTE_FORMAT.md`, `tools/README.md` (phase R). The three files of
   `docs/routes/` also name the three deleted steps of `h-22-hillsbrad`, the old race filters and the positional
   ids `h-24-barrens-stonetalon:64` / `:76`, which are now `h25-rebirth-seeds` / `h25-rebirth-turnin`.
5. **The base-profile command of the plan exits 1 with an ERROR since this phase** (found in verification
   round 2; decision needed before F2d, D.0 rule 6). `lua5.1 tools/validate_routes.lua -q --strict --end-level
   --route 'undead-*,skyborne-*' --skip 'Classes/*' $G` reports `ERROR insert-anchor-unknown` for `sky-40d-path`
   (`Races/Skyborne.lua`): C.7 anchors the druid riding steps of a race file on `dru-40-train`, a step of
   `Classes/Druid.lua`; with the class files skipped the anchor is the id of no loaded step, and without `--own`
   every loaded file is own (A.6.2), so the check counts. The plan contradicts itself here (C.7 against A.6.2
   and the command lines); neither side is a file of F2b. Affected: the 4th validation command of F2d
   (`PLAN.md:1445`), the baseline run and the "28 base routes" command of P2 (`:1535`, `:1543`), appendix 2
   (`:1755`, `:1758`: P2 / P3 / R). `--write-baseline` still writes its file but exits 1. Not affected: every F2b
   acceptance command, `make check`, the F2c command lines (they load the class file of the race), the P1 and
   phase C command lines (they pass `--own`, the race files are not own there: a note). P2 adds the same insert
   to `Races/Tauren.lua`: then two ERRORs. Details, the options and a tested patch: section 8.

## 7. Verification round 1

Seven findings of the independent verification, all minor. Each was checked against the code and the DB snapshot
before anything was changed. The numbers of sections 2 and "summary lines" did not move (the tables above are
still what the tools print); section 1 and the deviations were updated where a fact changed.

| # | Finding | Verdict | Change |
|---|---|---|---|
| 1 | The three Tauren proofs do not pass with the literal command of D.2 step 6 (2 unaccepted `db-override-unverified` on `h15-xr-arrive`); the spec passes them with `--ignore` | Real, and it is the contradiction of deviation 1: with the `ok` on the step the full run fails `--strict` with `ok-unused` (re-checked: the three proofs then pass without `--ignore`, 0 WARN, and `make validate` would report `ok-unused` for the 2 routes). Not repairable in F2b without a Tauren route | The route files are unchanged (no `ok`). The spec no longer relies on someone remembering: new case "acknowledges the unverified override of 861 / 854 exactly when a Tauren route exists" (fails when a Tauren route is registered and the key is missing, and when the key is there without one); the three proofs and the pin case read the key from the step and drop `--ignore` by themselves. Mutation-tested with the key added. The comment on `h15-xr-arrive` names the spec; P2 list updated |
| 2 | B.7: four comments in 22-60 still point at deleted legacy segments / the old profile | Real | Reworded: `24_Barrens_Stonetalon.lua` (the ramp is the point of `h18-go-sunrock`), `34_Stranglethorn.lua` (the lift exit of `h13-uc-lift`), `37_Desolace_Dustwallow.lua` and `41_Arathi_Badlands.lua` ("a route that enters at 36.06 / 40.85"). The remaining mentions of paladin / druid in 22-60 name class inserts or the measured numbers of the two existing routes |
| 3 | `git rm -r --cached` on `Segments/Legacy` (D.0 rule 1), six staged deletions | Real, self-reported; nothing to repair | None. The index was not touched in this round either (it still holds exactly the six deletions) |
| 4 | `h13-lvl-14` points at the Moonrage Whitescalps (10-11) for a character of 13.7-13.9 | Real. DB: Whitescalp 10-11 gives 60 / 75 XP at 13 against 110; within 200 yd of the old point 8 spawns reach level 13 and 22 do not | `at` is now { 1421, 43.3, 30.8 }: the centroid of the 8 Moonrage Glutton (12-13) and 7 Darksoul (13-14) spawns within 350 yd of Dalar, 255 yd north-west of him (21 same-level spawns within 200 yd, 7 lower). The note names them and tells the player to leave the Whitescalps. Gate position and fraction are unchanged (B.4 item 4; kills 6 / 14 Orc, 0 Tauren, as before). New spec case "points every level gate of 12-22 at mobs of the player's level" (all six gates; fails on the old point). The two further options of the finding (gate before the last Sepulcher visit, a lower fraction for the Undead) are in the P2 list |
| 5 | `h18-lvl-20` came after `h18-venomspitters`, which walks back to Ziz, with `at` at the Crag | Real: 430 yd back to the Crag and 543 yd to Ziz again for a short character. DB: the Crag has 70 Venture Co. spawns of 18-20 within 300 yd; around Ziz there are 11 venomspitters of 17-18 (100-119 XP at 19 against 140) | The gate now stands between `h18-windshear` and `h18-venomspitters` (first option of the finding; the second, `at` at Ziz, would point at lower mobs and fail the new gate spec). Fraction unchanged; the validator credits no XP in the venomspitter step, so the levels at the gate are the same (Orc 20.23 / 20.13, 0 kills for every profile). Note and header reworded. New spec case "places the gate h18-lvl-20 at Windshear Crag, before the step that walks back to Ziz" |
| 6 | Orc, Scourge and Troll visit Tal twice at Thunder Bluff 1 (plan order of B.6) | Real: 840 yd against 664 yd of straight legs, a second climb of the tower, the timer of 853 running on the first visit; `routes.md` 4.4 and the legacy segment have Zamah first | `h18-fp-tb` moved behind the join, right before `h18-fly-ratchet` (same id, same race filter; deviation 15). `h18-go-tb-lift` says "Zamah first". New spec case "lets the races that walk into Thunder Bluff pass the flight master once, after Zamah". Levels, kills and both simulations unchanged |
| 7 | Russian notes name the same NPC two ways; Zapetta has two spellings | Real: 34 Russian notes of the four segments held English names (all of `h-12`, the steps taken from the Skyborne segments in `h-15` / `h-18`) | One convention: the ru text names NPCs, mobs and places in Russian, with the forms the module already uses (Tirisfal: стражник смерти Терренс, аптекарь Йохан, Хадрик Харлсон, тёмные неофиты и силовики; `h-24`: Утёс Ветрорезов; `h-15`: Дарсок Быстрый Кинжал, истребительницы Ведьмокрылых, Лакота'мани, Омуса Громовой Рог). Changed: 16 notes of `h-12`, 1 of `h-13`, 2 of `h-15`, 15 of `h-18`; the same NPCs in `Races/Scourge.lua` (7 notes) and `Races/Skyborne.lua` (3); "Запетта" and "Майкл Гаррет" everywhere (`h-13`, `h-34`, `h-41`, `h-50`, `h-53`, `h-56`). One name stays English because I know no Russian form: "Talondeep Path" (`h18-talondeep`). New spec case "writes the Russian notes of 12-22 with Russian names" (allow-list: Talondeep Path, XT:4, XT:9) |

Names I translated without a form in the repository (to be checked against the ruRU client; all `-- CONFIRM` level,
none affects a tool): Татог, Борстан, Кор'гелд, Йелмак, Вхуут, Миги, Тра (Orgrimmar city quests), Зор Одинокое
Древо, Фрезза, Верог Дервиш, Оватанка, Цветущий оазис (Lushwater Oasis), рудник Ветрорезов, Муглаш, Ворша, наги
Гневного Хвоста (Wrathtail), гонец Песни Войны (Warsong Runner), деревня Чертополоха (Thistlefur Village; the
segment already used the form in `h18-lvl-21`). `Classes/Druid.lua` and `Classes/Paladin.lua` still carry English
names in some ru notes (Bunthen Plainswind, Loganaar, ...): they are rewritten by F2c / phase C and are outside the
finding; the new spec case covers the four segments only.

Files changed in this round: `G/Segments/Shared/12_Orgrimmar_Tirisfal.lua`, `13_Silverpine.lua`, `15_Barrens.lua`,
`18_Stonetalon_Ashenvale.lua` (two steps moved, notes, header), `24_*`, `34_*`, `37_*`, `41_*`, `50_*`, `53_*`,
`56_*` (comments and the two spellings only), `G/Races/Scourge.lua`, `G/Races/Skyborne.lua` (ru notes),
`tests/spec/guides_layout_spec.lua` (+ 5 cases), `G/Data.lua` and `docs/VALIDATION.md` (regenerated), this file.
No step was added or removed, no id changed, no quest moved.

Acceptance after the round (all on the final tree):

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 176 files |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --grind-until h-18-stonetalon-ashenvale $G` | exit 0: 0 ERROR, 0 WARN, 36 accepted; `undead-paladin` 4,901 / 6,172 (4 / 102 up to `h-18`), `skyborne-druid` 4,852 / 6,052 (0 / 24); end level 60.00 / 60.00 |
| `... --route undead-paladin --max-grind-until h-56-felwood-winterspring-plaguelands=4972/6179` | exit 0 (4,901 / 6,172) |
| `... --route skyborne-druid --max-grind-until h-56-felwood-winterspring-plaguelands=4878/6082` | exit 0 (4,852 / 6,052) |
| five harness proofs (command lines of section 2) | all exit 0, 0 ERROR, 0 WARN: Orc WARRIOR and Troll PRIEST 72 / 174, the three Tauren runs 38 / 138 (with `--ignore db-override-unverified`; without it exit 1 with exactly the 2 WARN of finding 1), end level 60.00 / 60.00 |
| `busted tests/spec/guides_layout_spec.lua` | 22 successes; the two F2c command lines 12 successes each |
| `make routedata-check`, report freshness (`--markdown` equals `docs/VALIDATION.md`), `make package` | exit 0, equal, exit 0 |
| `make check` | exit 0, 3 min 40 s: luacheck 0 / 0; busted 694 successes / 0 failures / 0 errors; `make validate` 0 ERROR, 0 WARN, 36 accepted; simulate 2 of 2 `OK` (1,745 and 1,781 steps); simulate-sync 16 of 16; fixture simulations 5 of 5; harness fixture 4 runs. Simulator warnings: the three known ones only |

Still open for the orchestrator: finding 1 (accept the deviation until P2; the spec now forces the `ok` with the
first Tauren route) and finding 3 (the index holds the six staged deletions; `git add -A` gives the same result).

## 8. Verification round 2

One finding (major), about a command that is not an F2b acceptance command but is the gate of later phases.

| # | Finding | Verdict | Change |
|---|---|---|---|
| 1 | The base-profile command of the plan (`--skip 'Classes/*'` without `--own`) exits 1 for every route with ERROR `insert-anchor-unknown`: the Skyborne druid riding insert (`Races/Skyborne.lua`, `after = "dru-40-train"`, as C.7 prescribes) is anchored on a step of the skipped `Classes/Druid.lua`. The hand-over did not report it and called the base previews clean | **Real**, every statement reproduced (below). The cause is a contradiction inside the plan: C.7 fixes the anchor, A.6.2 counts every loaded file as own without `--own`, and the base-profile commands pass no `--own`. Both ends are outside F2b (`tools/lib/module_checks.lua`, `docs/dev/PLAN.md`), and D.0 rule 6 forbids a work-around in my files, so the route files are **unchanged**: the insert stays where C.7 puts it | (1) Section 6, item 5: the defect, what it blocks and what it does not. (2) Section 4 (F2c): the sentence about clean base previews is corrected; it now says what the two previews were (harness runs, no template checks, no start zone) and what the real command prints. (3) New spec case in `tests/spec/guides_layout_spec.lua`, "the base profiles (validator, class files skipped)": it runs the validator on the module (not the harness) with `--skip 'Classes/*'` and fails on any ERROR in a base route, on an end level below 60.00, and on any template finding other than exactly one `insert-anchor-unknown` (ERROR or note) per race insert with a class scope whose anchor is a step of a class file. The base-profile run was covered by no spec before; the case holds under either decision below and tells F2d where to tighten it. (4) A tested patch for the tool (option A below) is ready, **not applied**. |

What was reproduced (working tree, `G` as above):

| Command | Result |
|---|---|
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --route 'undead-*,skyborne-*' --skip 'Classes/*' $G` | exit 1: `(shared FastesBoooy_Guides) [shared: 21 segment(s), 8 insert(s), 1919 step(s)]: 1 error(s)`: `ERROR ... id=sky-40d-path (Races/Skyborne.lua) [insert-anchor-unknown] shared insert after 'dru-40-train' (5 step(s), first 'sky-40d-path'): the anchor is the id of no loaded step (files are skipped: the anchor may live in one of them)`; both routes 0 ERROR; `skyborne-druid` 1 WARN (`quest-carried` 94911, transitional, section 4) |
| the same with `--route 'undead-*'` | exit 1, the same ERROR, 0 WARN |
| the same with `--keep 'Classes/Druid.lua'` | exit 0, 0 ERROR, 0 WARN |
| the same with `--own 'Segments/*'` | the ERROR is a note; exit 1 only because of the transitional WARN on `sd-02-zephras#70` (an own file under that glob) |
| the same with `--write-baseline <file>` | the file is written (Scourge 4,939 / 6,172, Skyborne 4,911 / 6,124), exit 1 |
| the same command on `git archive HEAD` (state of F2a) | 0 ERROR (the riding steps were part of the druid file); it exits 1 there as well, for another reason: WARN `level-grind` on `h-27-ashenvale-needles-level-gate`, 121 kills above the ceiling of 110, which this phase raised to 130 |
| the two `<F>` command lines of F2c (D.2) on this tree | exit 0 both (`undead-*`: 0 / 0, 17 accepted; `skyborne-*`: 0 / 0, 19 accepted) |

Rule in the code: `tools/lib/module_checks.lua:210-215` (the check), `:101-104` (a note only when `--own` is given
and the file is not own). `PLAN.md:447-449` says the same.

### The decision for the orchestrator (before F2d)

* **A. The tool looks for the anchor in the skipped files (recommended; patch below).** On a partial load,
  `insert-anchor-unknown` becomes a note, in any file, when the source of a skipped TOC file names a step with
  the anchor's id (`id = "<anchor>"`; the file is read, not run). A misspelled anchor is in no skipped file and
  stays an ERROR in every filtered command, so the purpose of the check (review finding PE-3) is kept in full.
  No command line of the plan changes; the Tauren insert of P2 needs nothing. Three files, one new spec case.
* **A'. The variant named in the finding**: a note when the insert has a class scope and every class file of
  that scope is skipped. It needs a class -> file mapping in the check, and a misspelled anchor of such an
  insert passes as a note in every base-profile run. A is stricter and smaller.
* **B. Change the command lines** (`--own 'Segments/*'` in `PLAN.md:1445`, `:1535`, `:1543`, `:1755`, `:1758`).
  No tool change, but `--strict` then ignores every WARN of a race file in the base runs (they become "foreign
  warnings"), and each later phase has to remember the extra option.

Under A the literal command for `undead-*` exits 0 today, and the one for `undead-*,skyborne-*` exits 0 as soon
as the Zephras agent has moved the accept of 94911 (F2c).

The patch for A is `r2-anchor-in-skipped-file.patch` in the session scratch directory (139 lines; `patch -p0`
from the repository root; the full text is at the end of this section). Tested on a copy of this tree, never in
the repository: `luacheck --config .luacheckrc tools tests` 0 / 0; `busted` 696 successes / 0 failures / 0
errors (695 of this tree + the new case of `validator_module_spec.lua`); the base-profile command for
`undead-*` exits 0 with the note

```
  note  [library FastesBoooy_Guides] id=sky-40d-path (Races/Skyborne.lua) [insert-anchor-unknown] shared insert after 'dru-40-train' (5 step(s), first 'sky-40d-path'): the anchor is the id of no loaded step; the skipped file Classes/Druid.lua has a step with this id -- not counted: partial load (--skip / --keep): the anchor is a step of a skipped file, the insert is applied to no route of this run
```

`make validate` and the two F2c command lines are unchanged by it (0 ERROR, 0 WARN). The new layout case passes
with and without the patch. Mutation-tested on copies: a misspelled anchor in `Races/Skyborne.lua` fails the
case with and without the patch; the insert without its class scope fails it (tested without the patch).
`tools/README.md` (the paragraph on partial loads and the row of `insert-anchor-unknown`) would need one
sentence; that file belongs to phase R.

### Files changed in this round

`tests/spec/guides_layout_spec.lua` (+ 1 case, header), this file. No route file, no tool, no generated file
(`Data.lua` and `docs/VALIDATION.md` are untouched: `make routedata-check` and the report comparison pass).

### Acceptance after the round (all on the final tree)

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc addons tools tests` | 0 warnings / 0 errors in 176 files |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --grind-until h-18-stonetalon-ashenvale $G` | exit 0: 0 ERROR, 0 WARN, 36 accepted; `undead-paladin` 4,901 / 6,172 (4 / 102 up to `h-18`), `skyborne-druid` 4,852 / 6,052 (0 / 24); end level 60.00 / 60.00 |
| `... --route undead-paladin --max-grind-until h-56-felwood-winterspring-plaguelands=4972/6179` | exit 0 (4,901 / 6,172) |
| `... --route skyborne-druid --max-grind-until h-56-felwood-winterspring-plaguelands=4878/6082` | exit 0 (4,852 / 6,052) |
| five harness proofs (command lines of section 2) | all exit 0, 0 ERROR, 0 WARN: Orc WARRIOR and Troll PRIEST 72 / 174, the three Tauren runs 38 / 138, end level 60.00 / 60.00 |
| `busted tests/spec/guides_layout_spec.lua` | 23 successes; the two F2c command lines (`GUIDES_SKIP` / `GUIDES_OWN`) 12 successes each (the new case is a whole-module case and is skipped there) |
| `make routedata-check`, report freshness (`--markdown` equals `docs/VALIDATION.md`), `make package` | exit 0, equal, exit 0 |
| `make check` | exit 0, 4 min 35 s: luacheck 0 / 0; busted 695 successes / 0 failures / 0 errors; `make validate` 0 ERROR, 0 WARN, 36 accepted; simulate 2 of 2 `OK` (1,745 and 1,781 steps); simulate-sync 16 of 16; fixture simulations 5 of 5; harness fixture 4 runs. Simulator warnings: the three known ones only |

Not an acceptance command of F2b, and still failing until the orchestrator has decided item 5 of section 6: the
base-profile command (`--skip 'Classes/*'` without `--own`), exit 1 with the one ERROR described above.

### The patch for option A (not applied)

```diff
--- tools/lib/module_checks.lua
+++ tools/lib/module_checks.lua
@@ -26,6 +26,11 @@
 -- file. The five checks that depend on other files (unknown-race-token .. insert-scope-wider-than-
 -- anchor) still count for the caller's own files (opts.isOwn; every loaded file without --own); for
 -- a loaded file that is not own they are returned as NOTES, which never change the exit status.
+-- One case is a note in any file: insert-anchor-unknown when a skipped file names a step with the
+-- anchor's id (the source text is searched for `id = "<anchor>"`; the file is not run). Nothing is
+-- wrong with such an insert: a race file anchors its druid riding steps on a step of
+-- Classes/Druid.lua (docs/dev/PLAN.md C.7), and a base-profile run (--skip 'Classes/*') leaves that
+-- file out. A misspelled anchor is in no skipped file either and stays an ERROR.
 -- ok-needs-ceiling reads one step / segment only: it is an ERROR in any file, on any load.
 -- shared-unused is not checked on a partial load.
 
@@ -98,6 +103,11 @@
         else
             m.file = where.file
         end
+        if where.note then
+            m.note = where.note
+            notes[#notes + 1] = m
+            return m
+        end
         if sev == "ERROR" and not LOCAL_CHECK[code] and mod.filtered and isOwn and not isOwn(m.file) then
             notes[#notes + 1] = m
             return m
@@ -123,6 +133,28 @@
         return false
     end
 
+    -- partial load: the skipped TOC file whose source names a step with this id (`id = "<id>"`), or nil.
+    -- The file is read, not run: it may be another agent's half-written file.
+    local skippedText
+    local function skippedHome(id)
+        if not mod.filtered then return nil end
+        if not skippedText then
+            skippedText = {}
+            for _, rel in ipairs(mod.skipped or {}) do
+                local fh = io.open(tostring(mod.dir) .. "/" .. rel, "rb")
+                if fh then
+                    skippedText[#skippedText + 1] = { rel, fh:read("*a") }
+                    fh:close()
+                end
+            end
+        end
+        local pat = "id%s*=%s*[\"']" .. tostring(id):gsub("%p", "%%%0") .. "[\"']"
+        for _, f in ipairs(skippedText) do
+            if f[2]:find(pat) then return f[1] end
+        end
+        return nil
+    end
+
     local CEILING = "ok lists level-grind without a ceiling: write ok = { [\"level-grind\"] = N } (accepted only "
         .. "while the gate needs at most N kills)"
     local function plainCeiling(step, where)
@@ -209,9 +241,17 @@
         local anchorOk = true
         if not anchorKnown(ins.anchor) then
             anchorOk = false
-            add("ERROR", "insert-anchor-unknown", whereIns, "%s (%d step(s), first '%s'): the anchor is the id of no "
-                .. "loaded step%s", label, #ins.steps, tostring(first and first.id),
-                mod.filtered and " (files are skipped: the anchor may live in one of them)" or "")
+            local home = skippedHome(ins.anchor)
+            if home then
+                add("ERROR", "insert-anchor-unknown", { step = first, file = ins.file, note = "partial load (--skip / "
+                    .. "--keep): the anchor is a step of a skipped file, the insert is applied to no route of this run" },
+                    "%s (%d step(s), first '%s'): the anchor is the id of no loaded step; the skipped file %s has a "
+                    .. "step with this id", label, #ins.steps, tostring(first and first.id), home)
+            else
+                add("ERROR", "insert-anchor-unknown", whereIns, "%s (%d step(s), first '%s'): the anchor is the id of "
+                    .. "no loaded step%s", label, #ins.steps, tostring(first and first.id),
+                    mod.filtered and " (files are skipped: the anchor may live in one of them)" or "")
+            end
         else
             local scoped, withAnchor = 0, 0
             for _, route in ipairs(mod.routes) do
--- tools/lib/validator.lua
+++ tools/lib/validator.lua
@@ -2403,8 +2403,8 @@
         local msgs, notes = ModuleChecks.Run(opts.db, opts.schema, mod, { isOwn = opts.isOwn, acknowledge = acknowledge })
         prependMessages(res, msgs, opts.ignore)
         for _, m in ipairs(notes) do
-            m.note = "partial load (--skip / --keep): the file is not own, the anchor or the route may live in a "
-                .. "skipped file"
+            m.note = m.note or "partial load (--skip / --keep): the file is not own, the anchor or the route may "
+                .. "live in a skipped file"
             out.notes[#out.notes + 1] = m
         end
         moduleChecked = mod.name
--- tests/spec/validator_module_spec.lua
+++ tests/spec/validator_module_spec.lua
@@ -319,6 +319,47 @@
             assert.equal(1, code)
         end)
 
+        it("insert-anchor-unknown under --skip: a note in any file when a skipped file has the anchor step", function()
+            -- docs/dev/PLAN.md C.7: a race file anchors its druid riding steps on a step of the class file;
+            -- the base-profile commands (--skip 'Classes/*') leave the class file out
+            local changes = { ["Races/Orc.lua"] = { append = [[
+FastesBoooy.AddLibraryInsert({ after = "mx-war-train", race = "Orc", class = "WARRIOR", steps = {
+    { id = "mx-orc-riding", go = true, at = { 1411, 42.9, 69.4 } },
+} })
+]] } }
+            local dir = module(changes)
+            -- full load: the insert is applied, nothing is reported
+            local res = validate(dir)
+            assert.same({}, listed(res.results[1]))
+            assert.same({}, res.notes)
+            assert.is_truthy(res.mod.routeById["mx-orc-warrior"].stepById["mx-orc-riding"])
+            -- class files skipped, no --own (every loaded file is own): a note, not an error
+            res = validate(dir, { skipGlobs = { "Classes/*" } })
+            assert.same({}, listed(res.results[1]))
+            assert.equal(1, #res.notes)
+            assert.equal("insert-anchor-unknown", res.notes[1].code)
+            assert.equal("Races/Orc.lua", res.notes[1].file)
+            assert.equal("mx-orc-riding", res.notes[1].stepId)
+            assert.matches("the anchor is the id of no loaded step; the skipped file Classes/Warrior.lua has a step with "
+                .. "this id$", res.notes[1].msg)
+            assert.matches("^partial load .-: the anchor is a step of a skipped file", res.notes[1].note)
+            assert.is_nil(res.mod.routeById["mx-orc-warrior"].stepById["mx-orc-riding"])
+            -- the same when the race file is named with --own
+            res = validate(dir, { skipGlobs = { "Classes/*" }, isOwn = own("Races/Orc.lua"), ownGiven = true })
+            assert.same({}, listed(res.results[1]))
+            assert.equal(1, #res.notes)
+            -- a misspelled anchor is in no skipped file: still an error under the same filter
+            changes["Races/Orc.lua"].append = changes["Races/Orc.lua"].append:gsub("mx%-war%-train", "mx-war-trian")
+            res = validate(module(changes), { skipGlobs = { "Classes/*" } })
+            assert.same({ "insert-anchor-unknown Races/Orc.lua mx-orc-riding" }, listed(res.results[1]))
+            assert.same({}, res.notes)
+
+            local code, out = run(VALIDATE .. "-q --strict --skip 'Classes/*' " .. dir)
+            assert.equal(0, code, out)
+            assert.matches("  note  %[library FastesBoooy_Mx%d+%] id=mx%-orc%-riding %(Races/Orc.lua%) %[insert%-anchor%-unknown%] "
+                .. "shared insert after 'mx%-war%-train'.-skipped file Classes/Warrior.lua.- %-%- not counted: partial load", out)
+        end)
+
         it("insert-unapplied: the anchor exists, routes match the scope, none of them has the anchor", function()
             local dir = module({ ["Races/Orc.lua"] = { append = [[
 -- an anchor of the other start zone
```
