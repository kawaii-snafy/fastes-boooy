# Hand-over F2c, Tirisfal agent: the Undead start zone, class-neutral

Phase F2c of `docs/dev/PLAN.md` (D.2, step F2c, left column; B.1, B.2, B.8, C). Nothing was committed and no git
command that changes state was run (the orchestrator commits). `G` = `addons/FastesBoooy_Guides`.

The two Tirisfal segments are class-neutral, every step has an explicit id, `only` is gone from the announcement:
the six Undead routes exist (`undead-mage`, `-paladin`, `-priest`, `-rogue`, `-warlock`, `-warrior`). The five
routes without a class file are base routes. The paladin's class steps of 1-12 are the group `pal-tir-*` of
`Classes/Paladin.lua`; composed, the paladin route walks the same quests in the same order as before.

The text below is the state **after verification round 1** (the last section says what that round changed; the
numbers, id lists and tables above it were updated in place).

## 1. What changed

| File | Change |
|---|---|
| `G/Segments/Tirisfal/01_Deathknell.lua` | rewritten: `ud-01-deathknell`, 26 steps (31 before), all with explicit ids; no class step, no class-flavoured note; the three steps of 98389 are `optional` (E.6) |
| `G/Segments/Tirisfal/02_Tirisfal.lua` | rewritten: `ud-02-tirisfal`, 103 steps (121 before), all with explicit ids; ends with `ud02-uc-exit`, `ud02-silverpine-road`; the announcement has no `only` |
| `G/Classes/Paladin.lua` | + the Tirisfal group: 17 inserts, 34 steps `pal-tir-*`; header rewritten for 1-12; every insert now uses the local `insert` (C.1). The 15 inserts of 12-60 and their steps are unchanged |
| `G/Races/Scourge.lua` | the interim insert `und-uc-exit` / `und-silverpine-road` is deleted (the two steps are part of `ud-02` now); + the riding insert of the classes MAGE, PRIEST, ROGUE, WARRIOR after `h-41-uc-arrive` (4 optional steps `und-40-*`); header |
| `docs/dev/handover/f2c-tirisfal.md` | this file |

Not created: `tools/overrides/tirisfal.lua`, `tools/overrides/paladin.lua` (no override was needed).
Not touched: everything else (TOC, `Route.lua`, `Segments/Shared/**`, the specs, `Data.lua`, `docs/VALIDATION.md`).
`Data.lua` and `docs/VALIDATION.md` are stale until the orchestrator's closing step (`make routedata report`).

### What was done to the old steps

| Old step | Now |
|---|---|
| `ud01-364` (accept 98601 + 3901 + 376) | `ud01-364` (3901, 376) + `pal-tir-letter` (98601) |
| `ud01-98601`, `ud01-train-1`, the bg step of 90902 | `pal-tir-aramis`, `pal-tir-train-1`, `pal-tir-heal-bg` (insert after `ud01-364`) |
| `ud01-xp-4` (3 + 64 %, "for Judgement and the paladin quests") | `ud01-xp-4`, generic trainer-hub gate 3 + 70 % (deviation 2) |
| turn-in 3901 / 376 + accept 6395; `ud01-91209` (accept 91208, 91209, 98389) | `ud01-church-4` (turn-in 3901, 376; accept 6395: Sarvis, Elreth) + `ud01-aramis` (accept 98389 at Aramis, `optional`) + `pal-tir-91209` (91208, 91209) |
| `ud01-90902`, `ud01-train-4` | `pal-tir-90902`, `pal-tir-train-4` (insert after `ud01-aramis`, together with `pal-tir-91209`) |
| the cave step (`complete` 98389 + 380, second objective) | `ud01-cave` (380) + `ud01-cocoons` (`complete` 98389, `optional`) |
| `ud01-91208` | `pal-tir-frightened` (after `ud01-boxes`) |
| turn-in 91208 + 98389 | `ud01-98389` (98389, `optional`) + `pal-tir-91208` |
| `ud02-91209`, `ud02-train-6`, `ud02-mallet` | `pal-tir-shari`, `pal-tir-train-6`, `pal-tir-mallet` (after `ud02-dillinger-report`); the Linen Cloth hint moved from `ud02-sethearth` into `pal-tir-train-6` |
| `ud02-train-8` | `pal-tir-train-8` (after `ud02-shari-99144`, the generic turn-in of 99144 at Shari) |
| `ud02-91282`, `ud02-train-10` (`train` + `level = 10`) | `ud02-level-10` (generic gate) + `pal-tir-91282`, `pal-tir-train-10` |
| `ud02-91285` | `pal-tir-breton` (before `ud02-keep`) |
| the bg step of 91285, `ud02-smasher`, `ud02-91294` (talk to Hilda + accept 99152) | `pal-tir-murlocs`, `pal-tir-smasher`, `pal-tir-hilda` (after `ud02-leonid-letter`) + `ud02-hilda` (99152) |
| Ander, Jorin, `ud02-91317`, `ud02-91316` | `pal-tir-ander`, `pal-tir-jorin`, `pal-tir-danitha`, `pal-tir-91316` (after `ud02-hilda`) |
| bg 91317, bg 99152, bg 91316 + 95314, the head, `complete` of all four | `pal-tir-tarnished-bg`, `pal-tir-lumber-bg` (after `ud02-ephram`), `ud02-bones-bg`, `ud02-elixir-bg`, `pal-tir-head` (after `ud02-elixir-bg`: all bg goals, then the head, as before), `ud02-shadowvale` (99152, 95314), `pal-tir-shadowvale` (91317, 91316) |
| turn-in 91316, `ud02-95803` | `pal-tir-91316-turnin`, `pal-tir-95803` (after `ud02-hilda-2`) |
| `ud02-xp-12` (optional, paladin) | `ud02-lvl-12`: generic, mandatory (B.8) |
| `ud02-94427` | `pal-tir-94427` (optional, after `ud02-lvl-12`) |
| `ud02-train-12` | `pal-tir-train-12` (after `ud02-carolai-2`) |
| Tanis (2 optional steps), `ud02-end` (Sylvanas) | `pal-tir-tanis`, `pal-tir-tanis-2`, `pal-tir-sylvanas` (after `ud02-fp-uc`) |
| reward notes ("(mail)", two-hander, buckler), "health and mana", "keep Hammer of Justice" | reworded class-neutral in the segments ("pick the armour your class can wear", ...); the paladin's picks are named in the notes of `pal-tir-train-1` (3901 / 376), `pal-tir-91208` (3902 / 380, 381, 382), `pal-tir-train-8` (426, 398, 358), `pal-tir-train-10` (97558, 374); the Hammer of Justice hint is in `pal-tir-train-8` |
| `und-uc-exit`, `und-silverpine-road` (`Races/Scourge.lua`) | `ud02-uc-exit`, `ud02-silverpine-road` |

Kept ids (A.3): `ud01-start`, `ud01-364`, `ud01-xp-4`, `ud01-vendor`, `ud01-381`, `ud01-382`, `ud01-end`,
`ud02-365`, `ud02-zygand-1`, `ud02-sethearth`, `ud02-hearth-1`, `ud02-hearth-2`, `ud02-fp-uc`. No old id is
reused for another step.

### New ids

* `ud-01` (26): ud01-start ud01-363 ud01-zombies ud01-364 ud01-skeletons-bg ud01-damned ud01-skeletons ud01-xp-4
  ud01-vendor ud01-church-4 ud01-aramis ud01-arren-4 ud01-boxes ud01-spiders ud01-cave ud01-cocoons ud01-98389 ud01-arren-5
  ud01-scarlet-camp ud01-fipps ud01-marla-grave ud01-6395 ud01-381 ud01-korgal ud01-382 ud01-end
* `ud-02` (103): ud02-365 ud02-gordo ud02-gloom-weed-bg ud02-brill-gate ud02-branches ud02-eleanor ud02-campfire
  ud02-eleanor-2 ud02-lvl-6 ud02-zygand-1 ud02-motivator-bg ud02-johaan-1 ud02-dillinger-report ud02-sethearth
  ud02-pickman ud02-rear-guard-1 ud02-skins-bg ud02-darkhound-blood-bg ud02-putrid-claws ud02-gordo-report
  ud02-scarlet-warriors-bg ud02-pumpkins ud02-murloc-skins ud02-scarlet-warriors ud02-bareth ud02-escort
  ud02-darkhounds ud02-hearth-1 ud02-johaan-2 ud02-zygand-2 ud02-wanted ud02-shari-99144 ud02-burgess ud02-thread
  ud02-sevren-1 ud02-zealot ud02-brill-8 ud02-dillinger-2 ud02-holland-2 ud02-pelts-bg ud02-doom-weed-bg
  ud02-gnolls ud02-maggot-eye ud02-coast-murlocs ud02-doom-weed ud02-agamand-bones-bg ud02-devlin ud02-nissa
  ud02-gregor ud02-thurman ud02-agamand-bones ud02-pelts ud02-holland-3 ud02-dillinger-3 ud02-johaan-3
  ud02-zygand-3 ud02-letter ud02-yvette ud02-coleman ud02-gretchen ud02-sevren-3 ud02-perrine ud02-zygand-4
  ud02-level-10 ud02-terrence ud02-rings-bg ud02-rear-guard-2 ud02-hadric ud02-cult-camp ud02-hadric-2
  ud02-balnir ud02-vachon ud02-venomweb ud02-rings ud02-linnea ud02-johaan-5 ud02-carolai ud02-zygand-5
  ud02-burgess-5 ud02-sevren-5 ud02-mountaineer ud02-holland-5 ud02-go-simmer ud02-go-solliden ud02-keep
  ud02-leonid-talk ud02-leonid-letter ud02-hilda ud02-ephram ud02-bones-bg ud02-elixir-bg ud02-crystal
  ud02-shadowvale ud02-ephram-2 ud02-hilda-2 ud02-lvl-12 ud02-hearth-2 ud02-carolai-2 ud02-go-uc ud02-glix
  ud02-fp-uc ud02-uc-exit ud02-silverpine-road
* `Classes/Paladin.lua` (34): pal-tir-letter pal-tir-aramis pal-tir-train-1 pal-tir-heal-bg (after `ud01-364`);
  pal-tir-90902 pal-tir-91209 pal-tir-train-4 (after `ud01-aramis`); pal-tir-frightened (after `ud01-boxes`);
  pal-tir-91208 (after `ud01-98389`); pal-tir-shari pal-tir-train-6 pal-tir-mallet (after
  `ud02-dillinger-report`); pal-tir-train-8 (after `ud02-shari-99144`); pal-tir-91282 pal-tir-train-10 (after
  `ud02-level-10`); pal-tir-breton (before `ud02-keep`); pal-tir-murlocs pal-tir-smasher pal-tir-hilda (after
  `ud02-leonid-letter`); pal-tir-ander pal-tir-jorin pal-tir-danitha pal-tir-91316 (after `ud02-hilda`);
  pal-tir-tarnished-bg pal-tir-lumber-bg (after `ud02-ephram`); pal-tir-head (after `ud02-elixir-bg`);
  pal-tir-shadowvale (after
  `ud02-shadowvale`); pal-tir-91316-turnin pal-tir-95803 (after `ud02-hilda-2`); pal-tir-94427 (after
  `ud02-lvl-12`); pal-tir-train-12 (after `ud02-carolai-2`); pal-tir-tanis pal-tir-tanis-2 pal-tir-sylvanas
  (after `ud02-fp-uc`)
* `Races/Scourge.lua` (4): und-40-brill und-40-riding und-40-horse und-40-back (after `h-41-uc-arrive`,
  `class = { "MAGE", "PRIEST", "ROGUE", "WARRIOR" }`, all `optional`)

## 2. Acceptance: commands run and results

`<F>` = `--skip 'Segments/Zephras/*' --skip 'Classes/Druid.lua' --skip 'Races/Skyborne.lua' --own
'Segments/Tirisfal/*' --own 'Classes/Paladin.lua' --own 'Races/Scourge.lua'`. All on the final tree.

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Segments/Tirisfal $G/Classes/Paladin.lua $G/Races/Scourge.lua` | 0 warnings / 0 errors in 4 files |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --route 'undead-*' <F> $G` | exit 0: "1 module(s), 0 error(s), 0 warning(s), 97 accepted (strict)"; six routes, each 0 ERROR, 0 WARN, end level 60.00 / 60.00; shared part 18 segments, 35 inserts |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --route undead-paladin --max-grind-until h-56-felwood-winterspring-plaguelands=4972/6179 <F> $G` | exit 0: **4,902 / 6,173** (limit 4,972 / 6,179; 4,901 / 6,172 before this phase; unchanged by round 1) |
| `lua5.1 tools/validate_routes.lua --route undead-warrior --levels <F> $G` | exit 0; the anchor table of section 3 is read from it |
| `lua5.1 tools/simulate_routes.lua --route undead-paladin <skip part of F> $G` | `OK`: 1,754 steps, 721 accepted, 721 turned in, level 60, no warning |
| `lua5.1 tools/simulate_routes.lua --route undead-warrior <skip part of F> $G` | `OK`: 1,696 steps, 702 accepted, 702 turned in, level 60, no warning |
| `GUIDES_SKIP=... GUIDES_OWN=... busted tests/spec/guides_layout_spec.lua` (the F2c line) | 12 successes / 0 failures / 0 errors |

Run in addition (not acceptance commands; read-only):

| Command | Result |
|---|---|
| `lua5.1 tools/simulate_routes.lua --route undead-warlock <skip part of F> $G` | `OK`: 1,690 steps (no riding insert), 702 accepted, 702 turned in, no warning (run before round 1, not repeated; 1,692 steps now) |
| the eight level-sync runs of `make simulate-sync` for `undead-paladin` and for `undead-warrior` (`--ahead 10`, `23`, `35`, `48`; `--ahead 21 --ahead-at h-15-barrens`; `--ahead 29 --ahead-at h-24-barrens-stonetalon`; `--level-plus 2`, `4`), one at a time | `undead-paladin`: 8 of 8 `OK` (the `--level-plus 4` run with the known warning on `h-53-azshara-ungoro-silithus:41`). `undead-warrior`: 7 of 8 `OK` (same known warning); **`--ahead 48` fails** in the cold-start check, on the shared path, not in Tirisfal: section 7, item 2. Repeated after round 1 on the whole module: the same 8 / 8 and 7 / 8 |
| `busted tests/spec/guides_layout_spec.lua` (no environment variables, whole module, with the Zephras agent's files as they were at that moment) | 23 successes / 0 failures |
| `busted tests/spec/core_sync_spec.lua` | 37 successes / 0 failures |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary $G` (whole module, same moment) | exit 0: 11 routes, 0 ERROR, 0 WARN, 188 accepted |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --route 'undead-*' --skip 'Classes/*' $G` (the base-profile command of the plan) | the six routes 0 ERROR / 0 WARN, 4,982 / 6,217 each; exit 1 only because of the known `insert-anchor-unknown` of `sky-40d-path` (`Races/Skyborne.lua`; F2b hand-over, section 6 item 5) |

### summary lines (`--summary --grind-until h-18-stonetalon-ashenvale`)

```
undead-mage	Scourge MAGE Horde	0	0	16	0	60.00	60.00	4982	6217	47	147
undead-paladin	Scourge PALADIN Horde	0	0	17	0	60.00	60.00	4902	6173	5	103
undead-priest	Scourge PRIEST Horde	0	0	16	0	60.00	60.00	4982	6217	47	147
undead-rogue	Scourge ROGUE Horde	0	0	16	0	60.00	60.00	4982	6217	47	147
undead-warlock	Scourge WARLOCK Horde	0	0	16	0	60.00	60.00	4982	6217	47	147
undead-warrior	Scourge WARRIOR Horde	0	0	16	0	60.00	60.00	4982	6217	47	147
```

The base Undead needs 47 / 147 grind kills up to the end of `h-18` (budget of F2d: 120 / 200; before the shared
path: 108 / 147).

### per segment: level in -> out, grind kills normal / worst

| Segment | base route (`undead-warrior`; mage, priest, rogue, warlock identical) | `undead-paladin` |
|---|---|---|
| `ud-01-deathknell` | 1.00 -> 5.75, 3 / 3 | 1.00 -> 5.91, 2 / 2 |
| `ud-02-tirisfal` | 5.75 -> 12.10, 1 / 6 | 5.91 -> 12.79, 0 / 0 |
| `h-13-silverpine` | 12.10 -> 14.21, 19 / 20 | 12.79 -> 14.56, 0 / 0 |
| `h-15-barrens` | 14.21 -> 18.14, 0 / 0 | 14.56 -> 18.32, 0 / 0 |
| `h-18-stonetalon-ashenvale` | 18.14 -> 22.04, 24 / 118 | 18.32 -> 22.04, 3 / 101 |
| `h-22-hillsbrad` | 22.04 -> 24.82, 0 / 51 | 22.04 -> 25.10, 0 / 51 |
| `h-24-barrens-stonetalon` | 24.82 -> 27.31, 0 / 221 | 25.10 -> 27.51, 0 / 221 |
| `h-27-ashenvale-needles` | 27.31 -> 31.01, 122 / 313 | 27.51 -> 31.01, 84 / 313 |
| `h-31-hillsbrad-arathi` | 31.01 -> 34.06, 274 / 326 | 31.01 -> 34.06, 274 / 326 |
| `h-34-stranglethorn` | 34.06 -> 36.06, 151 / 152 | 34.06 -> 36.06, 151 / 152 |
| `h-37-desolace-dustwallow` | 36.06 -> 41.02, 1,009 / 1,029 | 36.06 -> 41.02, 1,009 / 1,029 |
| `h-41-arathi-badlands` | 41.02 -> 44.02, 764 / 918 | 41.02 -> 44.02, 764 / 918 |
| `h-44-swamp-stranglethorn` | 44.02 -> 46.01, 178 / 185 | 44.02 -> 46.01, 178 / 185 |
| `h-46-tanaris-feralas` | 46.01 -> 49.40, 617 / 715 | 46.01 -> 49.40, 617 / 715 |
| `h-50-hinterlands-searing-steppes` | 49.40 -> 52.57, 154 / 308 | 49.40 -> 52.57, 154 / 308 |
| `h-53-azshara-ungoro-silithus` | 52.57 -> 55.04, 362 / 391 | 52.57 -> 55.04, 362 / 391 |
| `h-56-felwood-winterspring-plaguelands` | 55.04 -> 60.00, 1,304 / 1,461 | 55.04 -> 60.00, 1,304 / 1,461 |
| total | 4,982 / 6,217 | 4,902 / 6,173 |

### gates of 1-22: kills normal / worst

| Gate | base route | `undead-paladin` |
|---|---|---|
| `ud01-zombies` (level 2, with `complete` 364) | 0 / 0 | 0 / 0 |
| `ud01-xp-4` (3 + 70 %) | 3 / 3 | 2 / 2 |
| `ud02-lvl-6` | 0 / 0 | 0 / 0 |
| `ud02-level-10` | 0 / 0 | 0 / 0 |
| `ud02-lvl-12` | 1 / 6 | 0 / 0 |
| `h13-lvl-12` | **0 / 0** | 0 / 0 |
| `h13-lvl-14` (13 + 92 %) | 19 / 20 | 0 / 0 |
| `h18-lvl-18` | 0 / 18 | 0 / 1 |
| `h18-lvl-20`, `h18-lvl-21` | 0 / 0 | 0 / 0 |
| `h18-lvl-22` (21 + 85 %; ceiling 45) | 24 / 100 | 3 / 100 |

The `h13-lvl-12` row is the one B.2 asks for (limit 10 / 25). The worst case no longer counts the estimated XP
of 98389 (its three steps are `optional`, E.6): that is the 2 more kills at `ud02-lvl-12`; the worst-case kills
of the later segments moved by one here and there with the rounding of the level, the total is + 2 for the base
route and unchanged for the paladin. Gates of 22-60 for the base route, all at or under
their `ok` ceilings: `h-27-...-level-gate` 122 (130), `h-31` 274 (280), `h-34` 151 (160), `h38-level-maraudine`
325 (330), `h39-level-mannoroc` 684 (690), `h-41` 764 (770), `h-44` 178 (180), `h48-tanaris-level-gate` 28 (no
key, INFO), `h-46` 589 (590), `h-50` 154 (160), `h55-silithus-field-grind` 362 (370), `h57-winterspring-grind`
584 (590), `h-56` 720 (720).

### The hand-over contract of B.2 (base profile)

Read from `--route undead-warrior --write-state <file> --until h-13-silverpine` (the state before `h13-erland`):

| Contract | State |
|---|---|
| on the Silverpine road | last step `ud02-silverpine-road` (`go`, Tirisfal 53.2, 75.8) |
| level >= 12.0, reached by the gate `ud02-lvl-12` | 12.10 (worst case 12.09); the gate stands at the keep, before `ud02-hearth-2`, 1 / 6 kills |
| 445 in the log | log = { 445 }, nothing else |
| 96895 -> 96897 / 96898 done | all three in `done` (also 96899, 96896, 98545; 98389 in the normal run only) |
| hearth Brill | `hearth = "Brill"` |
| flight point Undercity | 1 flight path: Undercity |
| `h13-lvl-12`: at most 10 / 25 kills | 0 / 0 |

## 3. The real anchor list, with the level at every anchor

Level before the step, from `--levels` (normal run / worst case where it differs). All anchors are unfiltered
steps with explicit ids.

| Anchor | Step | base route | `undead-paladin` | Use |
|---|---|---|---|---|
| `ud01-364` | turn in 364 at Sarvis, accept 3901 + 376 | 2.42 | 2.42 | class letter (Sarvis gives it), first training |
| `ud01-church-4` | turn in 3901 + 376, accept 6395 (Sarvis, Elreth) | 3.74 (4.03 after it) | 3.72 (4.01 after it) | training at 4 |
| `ud01-aramis` (not in C.2) | accept 98389 at Aramis, `optional` (E.6): the last generic step in the church | 4.03 | 4.01 | training at 4 for a class whose trainer is Aramis (the paladin: a `train` step in front of an accept at the same NPC is `lookahead-skip`); the other classes may use either anchor (see below) |
| `ud01-381` | turn in 381, accept 382 | 5.33 / 5.23 | 5.49 / 5.37 | last Deathknell trainer visit |
| `ud01-382` | turn in 382, accept 383 + 96656 | 5.51 / 5.41 | 5.67 / 5.55 | - (`ud01-end`, accept 8 on the road, is the last step: 5.75 / 5.65) |
| `ud02-sethearth` | turn in 8, bind in the Brill inn | 6.38 / 6.30 | 6.60 / 6.51 | training at 6 (the gate `ud02-lvl-6` stands in front: 6.29 / 6.21) |
| `ud02-brill-8` | accept 354 + 362 + 375 in the inn | 8.18 / 8.13 | 8.30 / 8.25 | training at 8 |
| `ud02-level-10` | gate `level = 10` in Brill | 10.16 / 10.07 | 10.25 / 10.15 | training at 10, level-10 class quests |
| `ud02-keep` | turn in 96899, accept 96896 (Leonid) | 11.69 / 11.62 | 11.83 / 11.76 | paladin chain |
| `ud02-lvl-12` | gate `level = 12` at the keep | 12.00 / 11.93 | 12.56 / 12.51 | - |
| `ud02-hearth-2` | hearth to Brill | 12.01 / 12.00 | 12.56 / 12.51 | training at 12 |
| `ud02-fp-uc` | `fp` Undercity (after Glix) | 12.10 / 12.09 | 12.65 / 12.59 | Undercity trainers, weapon master, class quests |
| `ud02-silverpine-road` | last step of `ud-02` | 12.10 / 12.09 | 12.79 / 12.64 | - |

The worst case is lower than before round 1 by up to 0.1 level between `ud01-arren-5` and `ud02-lvl-12`: it no
longer counts 98389 (355 XP estimated). No even level at a trainer anchor is lost (8.13 at `ud02-brill-8`; 10
and 12 are gates).

`ud01-church-4` or `ud01-aramis` for the level-4 training: priest, mage and warlock train in the church, so both
work (after `ud01-church-4` the optional accept at Aramis follows the training in the same room; no rule is
touched, the trainer is another NPC). Warrior and rogue train in the house across the road, on the way to
Saltain and Arren: after `ud01-aramis` they leave the church once; after `ud01-church-4` the route would send
them church -> house -> church -> Arren (about 130 yd more).

Further ids the paladin file is anchored on (not in C.2; they must not be renamed either): `ud01-aramis`,
`ud01-boxes`, `ud01-98389` (`optional`), `ud02-dillinger-report` (6.38 / 6.30), `ud02-shari-99144` (8.03 / 7.98;
paladin 8.16 / 8.11), `ud02-leonid-letter`, `ud02-hilda`, `ud02-ephram`, `ud02-elixir-bg` (a `bg` step: the
paladin's blocking `collect` of Rudolph's head stands behind it), `ud02-shadowvale`, `ud02-hilda-2`,
`ud02-carolai-2` (12.01 / 12.00).

For the layout spec (F2d):

```lua
-- ANCHORS
["ud-01-deathknell"] = { "ud01-364", "ud01-church-4", "ud01-381", "ud01-382",
    "ud01-aramis", "ud01-boxes", "ud01-98389" },
["ud-02-tirisfal"] = { "ud02-sethearth", "ud02-brill-8", "ud02-level-10", "ud02-keep", "ud02-lvl-12",
    "ud02-hearth-2", "ud02-fp-uc", "ud02-silverpine-road",
    "ud02-dillinger-report", "ud02-shari-99144", "ud02-leonid-letter", "ud02-hilda", "ud02-ephram",
    "ud02-elixir-bg", "ud02-shadowvale", "ud02-hilda-2", "ud02-carolai-2" },
-- EXPLICIT_IDS: + "ud-01-deathknell", "ud-02-tirisfal"
```

Where the trainers stand (for the class agents): Deathknell: priest, mage, warlock and paladin in the church
(with Sarvis), warrior and rogue in the house across the road (next to the vendor of `ud01-vendor`). Brill:
warrior, rogue, priest, mage and warlock **in the inn** (61.6-62.0, 52.0-52.5), the paladin trainer Shari
Stilwell outside, by the stables (60.2, 52.7). So `ud02-sethearth`, `ud02-brill-8` and `ud02-hearth-2` are steps
in the inn, and the paladin file uses the generic steps next to Shari instead.

## 4. Deviations from the plan, and why

1. **`ud02-brill-8` is the inn step of the level-8 visit, not its last generic quest step.** C.2 defines it as
   the last generic quest step. The visit ends at Junior Apothecary Holland on the north-west edge of Brill,
   215 yd from the inn where five of the six class trainers stand: an insert there costs every class about
   365 yd (the way back and the longer way north). The id is on the step in the inn (accept 354 / 362 / 375,
   base level 8.18); two generic steps follow on the way out (`ud02-dillinger-2`, `ud02-holland-2`), neither at
   a trainer, so the look-ahead rule is not touched. The turn-in of 407 (the zealot behind the inn) moved in
   front of the inn step: 26 yd shorter, and nothing that is already complete follows a training step there.
2. **`ud01-xp-4` stays, as a generic trainer-hub gate `{ 3, 0.70 }`.** B.8 does not list it; `routes.md` 10.2
   says to keep such gates generic. 3901 (250) + 376 (170), both known XP, are 30 % of level 3, so every class
   is level 4.0 at the end of `ud01-church-4` and trains at 4 on that visit (the next one is at 5.3). Cost: 3
   kills for the base route, 2 for the paladin (1 before, at 3 + 64 % with the paladin quest counted).
3. **New gate `ud02-lvl-6`** (plain `level = 6`, after the camp quests, before Brill): 367 and 97558 need 6 and
   every class trains at 6. The validator has the base profile at 6.29 there (0 kills), but about 1,700 XP of
   the way are estimated quest XP (86784, 96656, 96607), and the simulator (quest XP only) reported "quest 367
   would not be offered yet: requires level 6 (player is 5)" for the base route. With the gate the warning is
   gone. `at` points at the Rotting Dead / Ravaged Corpses 180 yd west of the camp, which drop the claws of 404.
4. **98389 "A Light in the Darkness": generic and `optional`, as E.6 decides; no deviation any more** (it was
   mandatory and merged into `ud01-church-4` and `ud01-cave` before verification round 1). The DB has no class
   or race limit, but the quest starts and ends at the paladin trainer Aramis Hammerhand (`routes.md` 3.1,
   "risk"). It has three steps of its own, all `optional`: `ud01-aramis` (accept, right after `ud01-church-4`),
   `ud01-cocoons` (`complete`, after `ud01-cave`), `ud01-98389` (turn-in). No mandatory step shares an action
   with them, so a class that is not offered the quest is never held: the cursor shows `ud01-aramis` once, and
   as soon as the next quest step is done (Saltain and Arren, `ud01-arren-4`) the engine passes it and treats
   the two later steps as steps of a quest that was never taken (checked with the real engine, see
   "Verification round 1"). The note of `ud01-aramis` says so. `-- CONFIRM` stays on `ud01-aramis`. If the other
   classes are not offered it, the three steps move into `Classes/Paladin.lua`. The worst case of the base
   route now runs without the 355 XP (estimated) of the quest: + 2 kills at `ud02-lvl-12` (1 / 6).
5. **`ud01-382` is not the last step of `ud-01`** (C.2 says so): `ud01-end` (accept 8 from Calvin Montague on the
   road out) follows, as before.
6. **The paladin's training inserts do not use the inn anchors.** `pal-tir-train-6` is anchored after
   `ud02-dillinger-report` (Shari stands between Dillinger and the inn: the old order; after `ud02-sethearth` it
   would be 130 yd of back and forth), `pal-tir-train-8` after `ud02-shari-99144`, `pal-tir-train-12` after
   `ud02-carolai-2`. `pal-tir-train-10` uses `ud02-level-10`, `pal-tir-train-4` uses `ud01-aramis` (deviation
   10).
7. **`ud02-rings-bg` (bg goal of 374) stands behind the level-10 visit of Brill**, not at Captain Perrine's
   camp. With the gate split from the training, a pure `train` step between a bg `complete` and its non-bg twin
   (`ud02-rings`) is `WARN skip-ahead`: the engine would fast-forward the training of **every** class at 10 as
   soon as the ten rings are looted. The rings of Perrine's camp are named in the note of `ud02-perrine`.
8. **Order in the Undercity: Glix, then the flight master.** `ud02-fp-uc` is the anchor for class steps in the
   city; with the turn-in of 98545 in front of it no generic quest step follows the class steps there.
9. **`ud02-hearth-2` is followed by one generic turn-in** (`ud02-carolai-2`, 95314, 100 yd west of the inn). A
   class file may train after `ud02-hearth-2` (in the inn, no detour) or after `ud02-carolai-2` (no quest step
   that is already complete behind the training, C.3 rule 2; 200 yd more). The validator accepts both.
10. **`ud01-church-4` is not the last generic step in the church** (C.2: "anchor steps are placed after the
    generic quest steps of the visit"): it holds Sarvis and Elreth, as the C.2 row says, and the optional accept
    at Aramis (`ud01-aramis`) follows it, because 98389 needs 376 turned in first and an optional action cannot
    share a step with mandatory ones. The paladin's level-4 insert (turn-in of 90902, accept of 91208 + 91209,
    training) is therefore anchored `after = "ud01-aramis"`: after `ud01-church-4` its `train` step at Aramis
    would stand in front of the accept at Aramis (`WARN lookahead-skip`, reproduced). Section 3 says which of
    the two anchors suits the other classes.
11. **The riding steps of `Races/Scourge.lua` end with their own way back** (`und-40-back`, optional `go` to
    the Undercity entrance), C.4. `und-40-riding` is `train = true` (INFO `train-service`).
12. **The paladin's reward choices are notes, not a class reward table** (C.1 rule 5 asks for the table). The
    old route named the items in notes on the generic turn-in steps and had no `reward` index; the DB has no
    reward lists. A table entry with a guessed index would make the automation take a wrong item without
    asking, so the names are kept as text in the notes of the `pal-tir-*` steps that stand in front of the
    turn-ins (`pal-tir-train-1`, `pal-tir-91208`, `pal-tir-train-8`, `pal-tir-train-10`); without a table entry
    the automation stops at the reward window and the player picks. The table is a task for phase C once the
    indexes are recorded in game (`-- CONFIRM` list).
13. **`pal-tir-head` is anchored on a `bg` step** (`after = "ud02-elixir-bg"`): the blocking `collect` must stand
    behind every along-the-way goal of Shadowvale (the engine lists only the bg steps in front of the cursor),
    and the two generic bg goals are the last steps before `ud02-crystal`. The validator accepts it; the id is
    in the list for the layout spec.

Not a deviation: the trip to Bandarion Keep and Shadowvale is kept for every class (six generic quests, 96899 >
96896 > 98545, 99152, 99153, 95314; the plan's anchors `ud02-keep` and `ud02-lvl-12` stand there).

## 5. Foreign warnings, overrides, `-- CONFIRM`, place names

* Foreign warnings (WARN on files I do not own): **none**. The filtered runs print three notes
  `shared-step-unused` (`h13-fly-uc`, `h13-hearth-org`, `h18-fly-tb-1`): steps of the other races, an effect of
  the partial load.
* DB overrides added: none. XP values or mask corrections for quests I may not override: none.
* New place names (`PLACE_NAMES_RU`): none (`sethearth` / `hearth` Brill and `fp` Undercity existed).
* `-- CONFIRM`:
  * `ud01-aramis`: is 98389 offered by Aramis Hammerhand to every class? (item 4 of section 4, E.6)
  * `Classes/Paladin.lua`, header: the positions of the paladin's picks in the reward windows of 3901, 376,
    3902, 380, 381, 382, 426, 398, 358, 97558, 374 (for the class reward table, deviation 12)
  * unchanged from F2b, in `Classes/Paladin.lua`: `pal-train-14`, `pal-train-18`, `pal-train-20`,
    `pal-train-22` (the paladin trainers of the Undercity and Thunder Bluff, E.3).
* Russian names: the notes use the forms the module already had. "Арамис" stands without a surname (no known
  Russian form of "Hammerhand").

## 6. Notes for the next phases

### F2d

* Layout spec: the anchor tables and `EXPLICIT_IDS` of section 3. Worth one more case there (I may not edit
  the spec): the three steps that name 98389 (`ud01-aramis`, `ud01-cocoons`, `ud01-98389`) are `optional` and
  no other step of `ud-01` has an action of that quest; "Verification round 1" has the engine scenario. The two fixture replacements for the Tirisfal
  and Zephras announcements (`tests/fixtures/guides/FastesBoooy_StartZones/Segments/Tirisfal/02_Tirisfal.lua`)
  are no longer needed; the spec passes with them.
* The Undead base routes need no `ok` on a shared step: no gate of theirs is above its ceiling (section 2).
  `h-22-hillsbrad` keeps its `ok = "segment-level"` because of the paladin (25.10); the base routes end it at
  24.82.
* `docs/routes/horde-undead-paladin.md` names the old step ids of 1-12 (`ud01-98601`, `ud02-train-10`,
  `ud02-xp-12`, `ud02-end`, ...): section 1 has the mapping.
* No user-visible text of the four files contains "Horde" / "Орда", "library" or "shared".

### P2

* `ud01-xp-4` (3 kills) and `ud02-lvl-12` (1 / 6 kills) are the only grind of the base Undead before
  Silverpine; `h13-lvl-14` costs it 19 / 20 kills (F2b hand-over, P2 list, option b).
* The anchors are ready to freeze; the levels are in section 3.

### Phase C

* Read section 3 for the anchors and for where the trainers stand. Do not put a pure `train` step between a bg
  `complete` and its later non-bg twin (deviation 7): the validator reports it as `skip-ahead` on your step.
* Level-10 class quests: `ud02-level-10` stands between Zygand and Terrence, 50 yd from the inn.
* The paladin agent: `pal-40-riding` is still a mandatory `manual` step (C.7 calls the paladin's own riding
  steps optional); the trainer steps of 26-60 have no `-- CONFIRM` comment yet (C.5).

### For the atlas (`docs/dev/ATLAS.md`)

* The two segment headers now carry what a zone page needs without knowing a class: the hubs in visit order,
  where the trainers of each class stand, and which steps are generic although their NPC is a class trainer.

## 7. Open issues for the orchestrator

1. Closing step of the phase: `make routedata report`, `make routedata-check` (D.0 rule 2). `Data.lua` and
   `docs/VALIDATION.md` do not know the five new routes and the new step ids yet.
2. **A defect outside my files (D.0 rule 6): the level-sync run `--ahead 48` fails for every base route.**
   `lua5.1 tools/simulate_routes.lua --route undead-warrior --ahead 48 <skip part of F> $G` ends with
   `FAIL ... cold start with empty SavedVariables: cursor on step 1026 h-44-swamp-stranglethorn:19 [accept
   1424], but step 1694 h-60-end is already done`. The same for `skyborne-warrior --ahead 48` (step 1053 /
   1721, run on the whole module), so it does not come from a start zone. `undead-paladin --ahead 48` passes.
   What happens: the run jumps from `ud-01` to `h-46-tanaris-feralas` at 48 and plays to 60; 1424 "Pool of
   Tears" (level 43, in `h-44`) is never taken. On the cold start at level 60 the natural cursor stops on that
   accept (not voided as gray; presumably the later quests of its chain protect it, `protected` in
   `Core/Engine.lua`; I did not trace that part), and `Engine:ComputeSyncSuggestion` (`Core/Engine.lua:1771-1804`) looks
   for the first later segment that is not outleveled and has a step that is not done: the paladin has two
   class steps behind `h-60-end` (`pal-60-hearth`, `pal-train-60`), so it is offered the jump and resumes at
   step 1751 of 1752; a route with nothing behind `h-60-end` gets no suggestion and the cursor stays in `h-44`,
   in front of the finished end. Not part of `make check` (`SYNC_ROUTES` = `undead-paladin skyborne-druid`);
   `make simulate-sync-full` (nightly CI) runs every route and will fail on the nine base routes that exist
   after this phase. Owner: core (a finished route should count as finished on a cold start) or the simulator's
   check; phase C hides it for every class that gets a step behind `h-60-end`. The other seven sync runs of
   `undead-warrior` pass.
3. PLAN.md C.2, Tirisfal table: five rows differ from the tree (deviations 1, 3, 5, 8, 9; the measured levels
   are in section 3). The plan can be aligned or left; the layout spec of F2d takes the list of section 3.
4. 98389 (section 4, item 4) is the one fact of this zone that decides whether a step is generic or a paladin
   step, and it can only be checked in the game. Until then its three steps are `optional` (E.6) and cannot
   hold a route.
5. Nothing blocks F2d.

## 8. Verification round 1

Findings of the independent verification that concern this column, with the verdict and the change. Finding
numbers are those of the review list (1-8); 3, 5 and 7 belong to the Zephras column (`f2c-zephras.md`).

| # | Finding | Verdict | Change |
|---|---|---|---|
| 1 | E.6 not implemented: the three actions of 98389 were mandatory and two were merged into mandatory steps (`ud01-church-4`, the C.2 anchor; `ud01-cave`) | real | `ud01-church-4` = Sarvis and Elreth only (turn in 3901, 376; accept 6395). New `ud01-aramis` (`accept = 98389`, `optional`), new `ud01-cocoons` (`complete = 98389`, `optional`), `ud01-98389` is `optional`. `ud01-cave` keeps the spiders of 380. The paladin's level-4 insert moved from `after = "ud01-church-4"` to `after = "ud01-aramis"` (on the old anchor: `WARN lookahead-skip` for `pal-tir-train-4`, reproduced). `pal-tir-91208` stays after `ud01-98389`. Hand-over: section 4 items 4 and 10, section 3, the numbers |
| 6 | the note of the accept gave no way out if Aramis does not offer 98389 | real (same cause as 1) | the notes of `ud01-aramis`, `ud01-cocoons` and `ud01-98389` say "not offered / no quest: move on"; with the split nothing mandatory waits for the quest |
| 4 | `pal-tir-head` (blocking `collect`) stood in front of the generic bg goals `ud02-bones-bg`, `ud02-elixir-bg`: they were not listed while the paladin hunts Rudolph | real | `pal-tir-head` is its own insert `after = "ud02-elixir-bg"`; the two paladin bg steps stay after `ud02-ephram`. Composed order again: four bg goals, the head, `ud02-crystal`, `ud02-shadowvale`, `pal-tir-shadowvale` |
| 8 | the paladin's reward recommendations of eight turn-ins were deleted, not moved into the class file | real | the item names are back, in the notes of `pal-tir-train-1`, `pal-tir-91208`, `pal-tir-train-8`, `pal-tir-train-10`. No class reward table: the indexes are unknown (deviation 12); `-- CONFIRM` and a note for phase C in the header of `Classes/Paladin.lua` |
| 2 | `--ahead 48` fails for every base route (core / simulator, outside F2c) | real, not mine to fix | no change in my files. Reproduced on the final tree for `undead-warrior` and `skyborne-shaman` (the same message; `undead-paladin` and `skyborne-druid` pass). Stays open issue 2 of section 7 |

What the split costs and what it changes, measured (`undead-warrior`, the other four base routes are identical):

| | before round 1 | after |
|---|---|---|
| ERROR / WARN, end level | 0 / 0, 60.00 / 60.00 | 0 / 0, 60.00 / 60.00 |
| total grind, normal / worst | 4,982 / 6,215 | 4,982 / 6,217 |
| up to the end of `h-18` | 47 / 145 | 47 / 147 |
| gate `ud02-lvl-12` | 1 / 4 | 1 / 6 |
| gate `h13-lvl-12` (B.2) | 0 / 0 | 0 / 0 |
| `undead-paladin` total (limit 4,972 / 6,179) | 4,902 / 6,173 | 4,902 / 6,173 |
| composed steps, warrior / paladin | 1,694 / 1,752 | 1,696 / 1,754 |

The behaviour E.6 is about, checked with the real engine (a scratch busted file outside the repository that
boots `addons/FastesBoooy_Guides` in the mock client; `tests/**` is not mine): an Undead warrior plays `ud-01`
step by step and never has 98389 in the log and never presses Skip. The cursor stops once on `ud01-aramis`;
the player takes the quests of Saltain and Arren (`ud01-arren-4`) instead, and from then on the cursor walks
`ud01-boxes`, `ud01-spiders`, `ud01-cave`, `ud01-arren-5`, ... `ud01-382` to `ud01-end` without ever showing
`ud01-cocoons` or `ud01-98389`; a cold start with empty SavedVariables in that state lands on `ud01-end` too.
With the quest taken, warrior and paladin walk all three steps (paladin: `ud01-church-4`, `ud01-aramis`,
`pal-tir-90902`, `pal-tir-91209`, `pal-tir-train-4`, `ud01-arren-4`). Before the fix (replayed on a scratch copy
of the module with the old layout) the same warrior's cursor stayed on `ud01-church-4` after the church, still
after the turn-ins of `ud01-arren-5`, and after a cold start. F2d can turn this into a case of a spec it owns.

Acceptance after round 1 (all on the final tree, `<F>` as in section 2):

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Segments/Tirisfal $G/Classes/Paladin.lua $G/Races/Scourge.lua` | 0 warnings / 0 errors in 4 files |
| `validate_routes.lua -q --strict --end-level --summary --route 'undead-*' <F> $G` | exit 0: 6 routes, 0 ERROR, 0 WARN, 97 accepted, 60.00 / 60.00 |
| `... --route undead-paladin --max-grind-until h-56-felwood-winterspring-plaguelands=4972/6179 <F> $G` | exit 0: 4,902 / 6,173 |
| `validate_routes.lua --route undead-warrior --levels <F> $G` | exit 0 (section 3 is read from it) |
| `simulate_routes.lua --route undead-paladin <skip part of F> $G` | `OK`: 1,754 steps, 721 accepted, 721 turned in, level 60, no warning |
| `simulate_routes.lua --route undead-warrior <skip part of F> $G` | `OK`: 1,696 steps, 702 accepted, 702 turned in, level 60, no warning |
| `GUIDES_SKIP=... GUIDES_OWN=... busted tests/spec/guides_layout_spec.lua` | 12 successes / 0 failures |
| in addition: `busted tests/spec/guides_layout_spec.lua` (whole module), `busted tests/spec/core_sync_spec.lua` | 23 successes; 37 successes |
| in addition: `validate_routes.lua -q --strict --end-level --summary $G` (whole module, both columns after round 1) | exit 0: 11 routes, 0 ERROR, 0 WARN, 188 accepted |
| in addition: the level-sync runs of `undead-paladin` and `undead-warrior` (whole module) | paladin 8 of 8 `OK`; warrior 7 of 8, `--ahead 48` fails as before (finding 2) |
