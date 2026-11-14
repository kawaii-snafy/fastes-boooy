# Hand-over C1: rogue (`Classes/Rogue.lua`)

Phase C of `docs/dev/PLAN.md` (D.5, row Rogue), agent "rogue", FAST MODE: targeted checks only, no `make check`, no
`make routedata` / `report`. No git command that changes state was run. `G` = `addons/FastesBoooy_Guides`.

## 1. What changed

| File | Change |
|---|---|
| `G/Classes/Rogue.lua` | written (was a placeholder): 36 inserts, 62 steps (11 optional), all `class = "ROGUE"`, ids `rog-...`; header with every visit, anchor and validator level, what is skipped and why |
| `tools/overrides/rogue.lua` | new, empty (`quests = {}`): no correction is needed; it exists so that the D.5 luacheck line runs as written |
| `docs/routes/class-rogue.md` | new (Russian; shape of `class-paladin.md`): overview with grind per race, trainers, training tables 1-22 / 22-60, every insert with anchor and level, talents, class quests (Poisons, Deathstalkers, skipped), weapons, decisions, uncertainties |
| `docs/dev/handover/c-rogue.md` | this file |

Nothing else was touched (no segment, race file, other class file, spec, tool). Scratch files only under
`$SCRATCH/rogue/`.

## 2. Acceptance: commands and results

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Classes/Rogue.lua tools/overrides/rogue.lua` | 0 warnings / 0 errors in 2 files |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --baseline docs/dev/handover/baseline.json --route "*-rogue" --skip 'Classes/*' --keep "Classes/Rogue.lua" --own "Classes/Rogue.lua" $G` | **exit 0**: 0 error, 0 warning, 72 accepted (strict), 0 foreign; summary below |
| `lua5.1 tools/validate_routes.lua --route "<race>-rogue" --levels <F> $G` (all four races) | exit 0 x 4; levels of every own step: `docs/routes/class-rogue.md` §3 |
| `lua5.1 tools/simulate_routes.lua --route "<race>-rogue" --skip 'Classes/*' --keep "Classes/Rogue.lua" $G` (one at a time) | **OK x 4**: orc 1,712 steps (702 accepted / turned in), troll 1,714 (702), undead 1,740 (713), skyborne 1,758 (721), level 60 each; skyborne prints the two known warnings of P2 (`sd02-hearth` bind point, optional `sky-1061` at 12), the other three none |
| `GUIDES_SKIP='Classes/*' GUIDES_KEEP="Classes/Rogue.lua" GUIDES_OWN="Classes/Rogue.lua" busted tests/spec/guides_layout_spec.lua` | 22 successes / 0 failures / 0 errors |

`--summary` (route, profile, errors, warnings, accepted, foreign, end level, worst, grind, worst):

```
orc-rogue	Orc ROGUE Horde	0	0	18	0	60.00	60.00	4954	6187	-	-
troll-rogue	Troll ROGUE Horde	0	0	18	0	60.00	60.00	4954	6187	-	-
undead-rogue	Scourge ROGUE Horde	0	0	17	0	60.00	60.00	4948	6165	-	-
skyborne-rogue	Skyborne ROGUE Horde	0	0	19	0	60.00	60.00	4889	6090	-	-
```

Against the base route of the race (normal / worst): Orc and Troll 4,979 / 6,226 -> 4,954 / 6,187; Undead 4,982 / 6,217
-> 4,948 / 6,165; Skyborne 4,914 / 6,129 -> 4,889 / 6,090 (baseline file: Orc / Troll 4,980 / 6,227, Scourge 4,982 /
6,217, Skyborne 4,914 / 6,129). Grind up to the end of `h-18` (`--grind-until h-18-stonetalon-ashenvale`, normal / worst):
Orc / Troll 43 / 155 (base 44 / 156), Undead 37 / 134 (base 47 / 147), Skyborne 0 / 58 (base 0 / 59): inside the `h-18`
budget 120 / 200.

### Kills per segment, base -> rogue (the segments not listed are equal within 1)

| Segment | Orc / Troll | Undead | Skyborne |
|---|---|---|---|
| start zone | `dur-02` 8 -> 7 | `ud-01` 3 -> 2 | 0 -> 0 |
| `h-13-silverpine` | 0 / 3 -> 0 / 3 | 19 / 20 -> 18 / 18 | 0 -> 0 |
| `h-18-stonetalon-ashenvale` | 36 / 145 -> 36 / 145 | 24 / 118 -> 16 / 107 | 0 / 59 -> 0 / 58 |
| `h-22-hillsbrad` (worst) | 51 -> 13 | 51 -> 13 | 51 -> 13 |
| `h-27-ashenvale-needles` | 122 -> 98 | 122 -> 98 | 101 -> 76 |

`h-22-hillsbrad` ends at 25.00 (Skyborne 25.16) instead of 24.82: covered by the existing `ok = "segment-level"` of that
segment (P2 deviation 7); no warning.

## 3. Foreign warnings

None (`foreign` = 0 for all four routes with `--own Classes/Rogue.lua`).

## 4. Ids added

All in `Classes/Rogue.lua` (prefix `rog-`):
`rog-dur-letter-orc`, `rog-dur-rwag-orc`, `rog-dur-letter-troll`, `rog-dur-rwag-troll`, `rog-dur-train-4`,
`rog-dur-train-6`, `rog-dur-train-8`, `rog-dur-train-10`; `rog-tir-letter`, `rog-tir-trias`, `rog-tir-train-4`,
`rog-tir-train-6`, `rog-tir-train-8`, `rog-tir-train-10`, `rog-tir-mennet`, `rog-tir-train-12`, `rog-tir-astor`,
`rog-tir-mennet-2`, `rog-tir-train-14`, `rog-tir-andron`, `rog-tir-ledger`, `rog-tir-mennet-3`, `rog-tir-varimathras`,
`rog-tir-swords`; `rog-zep-letter`, `rog-zep-akeri`, `rog-zep-train-4`, `rog-zep-train-6`, `rog-zep-train-8`,
`rog-zep-train-10`, `rog-zep-train-12`; `rog-train-12`, `rog-train-14`, `rog-swords`, `rog-16-fly-org`, `rog-train-16`,
`rog-16-fly-taurajo`, `rog-train-22`, `rog-22-salute`, `rog-22-2458`, `rog-22-gate`, `rog-22-fizzule`, `rog-22-tower`,
`rog-22-shenthul`, `rog-22-hinott`, `rog-22-antidote`, `rog-22-poisons`, `rog-24-fly-uc`, `rog-24-poisons`,
`rog-train-24`, `rog-train-30`, `rog-31-poisons`, `rog-train-34`, `rog-train-36`, `rog-train-40`, `rog-train-44`,
`rog-train-48`, `rog-train-52`, `rog-train-54`, `rog-train-56`, `rog-60-hearth`, `rog-train-60`.

Anchors used (all explicit ids, all unfiltered): `dur01-teeth`, `dur01-den-4`, `dur02-garthok`, `dur02-garthok-3`,
`dur02-rh-3`, `ud01-364`, `ud01-arren-5`, `ud02-sethearth`, `ud02-brill-8`, `ud02-terrence`, `ud02-fp-uc`,
`sd01-rorian`, `sd01-thendal-4`, `sd01-innkeeper`, `sd01-illaya-3`, `sd02-valanaar-10`, `sd02-hearth`, `h12-fp-uc`,
`h13-go-sepulcher`, `h13-uc-end` (two inserts with disjoint race scopes), `h15-end`, `h-22-org-fp`, `h22-lydon`,
`h-24-tarrenmill-end`, `h-31-org`, `h-34-booty-bay`, `h-37-bootybay-end`, `h41-hearth-org`, `h-44-booty-bay`,
`h-50-org-arrive`, `h53-org-hearth`, `h56-sethearth-org`, `h-58-org-arrive`, `h-60-end`.

Deviations from the C.2 anchor table (levels from `--levels`, not the draft): the Tirisfal level-4 training stands after
`ud01-arren-5` (4.86) because `ud01-church-4` is at 3.74 (< 4); the level-10 training after `ud02-terrence` (the first
step in Brill after the gate `ud02-level-10`, Marion Call 25 yd away); the level-12 training of the Undead in the
Rogues' Quarter after `ud02-fp-uc` (Mennet Carkad stands there, so one visit instead of Brill at `ud02-hearth-2`). The
Zephras 6 / 8 visits use `sd01-innkeeper` (6.05, the trainer stands next to the innkeeper) and `sd01-illaya-3` (8.29).

## 5. Anchor wishes

None: every visit found an explicit id at the right place.

## 6. XP values and mask corrections for quests I may not override

None. All rogue quests have the right race and class masks in the snapshot (letters, 1885-1978 Undead, the Poisons
chain 2460 / 2458 / 2478 / 2479 / 2480 for every Horde race including the Skyborne). XP unknown (Forever-new): 92483
(Skyborne letter, estimated 170); record with `/fb xp` and put it into `tools/overrides/rogue.lua`.

## 7. New place names for `PLACE_NAMES_RU`

None: the `fly` / `hearth` actions name Orgrimmar, Camp Taurajo and Undercity, which exist.

## 8. DB overrides added

None (`tools/overrides/rogue.lua` is empty).

## 9. `-- CONFIRM` list (in the file)

* `rog-dur-train-10`, `rog-tir-train-10`, `rog-zep-train-10`: Dual Wield is a trainer spell at 10.
* `rog-22-fizzule`: the Flare Gun summons Fizzule and `/salute` makes him talk (original game).
* `rog-22-tower`: Gallywix's Lockbox needs Pick Lock with a skill of about 80 (web, "advised"; the snapshot has no lock
  data). If it does, the optional level-16 visit is the only way to learn Pick Lock before 22 on this path.
* `rog-train-24`: Shank (Forever-new) at 24; `rog-train-44`: Shank rank 2 at 44. No Russian name known: "«Shank»".
* Header: the spell lists of the `train` steps beyond the key levels of classes.md 5.3 are the original game's.
* Russian NPC names in the notes (Рваг, Каплак, Марион Колл, Дэвид Триас, Меннет Каркад, Андрон Гант, Астор Хадрен,
  Вариматрас, Шентул, Физзул, Силиксиз, Галливикс, Серж Хинотт, Ян Стром, Реккул, Иезекииль Грейвс, Арчибальд) against
  the ruRU client. Zephras NPCs stay in Latin script (as in `Classes/Hunter.lua`).

## 10. Deviations from the plan

1. **No class reward table** (D.5, A.5.4): the snapshot has no reward lists; same decision as the paladin and hunter
   files.
2. **Poisons at 22, not "20 or 22"** (classes.md 5.3): the shared path has no Orgrimmar stop between 14.13 and 22.04;
   the first one at level 20+ is `h-22-org-fp`. The tower is on the path at 16 (`h15-sludge-fen`), too early (req. 20,
   and the chain starts at Shenthul). The detour returns to Shenthul (2478 > 2479) so that 2479 / 2480 land on the
   path's Tarren Mill visit at 23.6; without the return Poisons would wait for Orgrimmar at 31.
3. **16-18 by an optional flight** (not in the plan's lists): Crossroads > Orgrimmar > Camp Taurajo after `h15-end`, the
   shared `fly Camp Taurajo` completes on the landing (the druid pattern of C.7). Optional by C.4 (training detour to
   another city).
4. **Shattered Hand chain not routed** (a "candidate" of classes.md 5.10): the turn-in is possible only at 22 in this
   path, where the level-13 quests give 10-20 % of their XP.
5. **Lockpicking chain not routed** (candidate): no Orgrimmar stop at 16-20, and the E.C.A.C. vendor (7166) required by
   2381 is not in the snapshot.
6. **`tools/overrides/rogue.lua` exists but is empty** (only so that the D.5 luacheck line runs as written).

## 11. Facts for the atlas

### Rogue trainers (DB; Horde-friendly)

| Place | Trainer (id, uiMap, x, y) | Note |
|---|---|---|
| Valley of Trials | Rwag 3155 (1411, 41.28, 68.00) | up to 6; letter 3088 / 3083 |
| Razor Hill | Kaplak 3170 (1411, 51.98, 43.69) | gives 1859 Therzok (Orc), 2380 To Orgrimmar! (16) |
| Deathknell | David Trias 2122 (1420, 32.53, 65.65) | up to 6; letter 3096 |
| Brill | Marion Call 2130 (1420, 61.75, 52.00) | gives 1885 (Undead) |
| Thendal (Zephras) | Akeri Duskblade 251389 (2521, 43.74, 24.36) | up to 6; letter 92483 |
| Shen'dar (Zephras) | Miriaan Mistblade 254087 (2521, 43.15, 43.26) | next to the innkeeper |
| Valanaar (Zephras) | Eltheen Nightbreeze 252379 (2521, 59.90, 72.48) | |
| Orgrimmar, Cleft of Shadow | Gest 3327 (42.69, 51.48), Shenthul 3401 (43.05, 53.74), Ormok 3328 (43.90, 54.63) | Shenthul: 2460 / 2458 / 2478 / 2479, 2379; Ormok: 8233; Therzok 6446 (42.73, 53.55) and Zando'zan 3402 (42.73, 52.95) next to them; poison vendor Rekkul 3334 (42.09, 49.48) |
| Undercity, Rogues' Quarter | Carolyn Ward 4582 (83.86, 72.07), Miles Dexter 4583 (85.21, 71.57), Gregory Charles 4584 (84.88, 73.53) | Mennet Carkad 6467 (83.51, 69.11) next to them; poison vendor Ezekiel Graves 4585 (75.20, 51.18) |
| Booty Bay | Ian Strom 1411 (1434, 26.82, 77.15) | faction AH |
| Ravenholdt Manor | Fahrad 6707 (1416, 84.45, 80.32) | "Grand Master Rogue" |
| Thunder Bluff | none (Boarton Shadetotem 205729 "Rogue Trainer?" 39.44, 65.82: unconfirmed, not used) | |

### Class quests (DB) and rewards (rewards are not in the DB)

| Quest | Race | Giver -> ender | XP (DB) | Note |
|---|---|---|---|---|
| 3088 Encrypted Parchment / 3083 Encrypted Tablet | Orc / Troll | Gornek 3143 -> Rwag 3155 (pre 788) | 40 | letter |
| 3096 Encrypted Scroll | Undead | Shadow Priest Sarvis 1569 -> David Trias 2122 (pre 364) | 40 | letter |
| 92483 At Home in the Shadows | any (only on Zephras) | Rorian 251361 -> Akeri Duskblade 251389 (pre 92461; item 282422) | ? | letter |
| 1885 Mennet Carkad | Undead | Marion Call -> Mennet Carkad 6467 | 210 | breadcrumb, excl. 1859 |
| 1886 / 1898 / 1899 / 1978 The Deathstalkers | Undead | Mennet; Astor Hadren 6497 (1421 49.71, 32.22, L13) letter; Andron Gant 6522 (1458 54.81, 76.33), his bookshelf 103600 (55.4, 77.0); Varimathras 2425 (56.25, 92.2) | 680 + 230 + 230 + 910 | routed |
| 1859 Therzok / 1963 / 1858 The Shattered Hand | Orc (1859) / Orc, Troll | Kaplak -> Therzok 6446; Tazan 6494 (1413 63.11, 44.29, L13) satchel 7209; key 7208 from Gamon 6466 (Orgrimmar inn 54.0, 68.0) | 210 + 680 + 455 | skipped (turn-in only at 22) |
| 2378 / 2380 > 2379 > 2382 > 2381 | all | Mennet / Kaplak -> Shenthul > Zando'zan > Wrenix 7161 (Ratchet 63.07, 36.32); Polly 7168 (1413 64.78, 45.5) Southsea Treasure; needs E.C.A.C. (vendor 7166, not in DB) and Thieves' Tools | 115 + ? + 115 + 1,350 | skipped |
| 2460 > 2458 > 2478 > 2479 > 2480 | all Horde (incl. Skyborne) | Shenthul; Taskmaster Fizzule 7233 (1413 55.44, 5.56, L30 elite, Flare Gun 8051); tower: drones 7310, lookouts 7307, patrollers 7308, Foreman Silixiz 7287 (key 8072), Grand Foreman Puzik Gallywix 7288 (L23 elite, head 8074), Gallywix's Lockbox 129127; Serge Hinott 2391 (1424 61.63, 19.19) | 155 + 1,150 + 1,950 + 1,050 + 155 | routed: Poisons |
| 1998 / 1999 | Undead | Mennet; Fenwick Thatros 6570 (1421 59.6, 33.9); Ambermill Strongbox 103815 | 880 + 1,550 | skipped |
| 6681 The Manor, Ravenholdt | any | Elegant Letter 17126 (random) -> Fahrad | 1,950 | skipped |
| 8233-8236 | any | Ormok / Miles Dexter -> Lord Jorach Ravenholdt 6768; Archmage Xylem 8379 (Azshara); Morphaz (Sunken Temple) | 510 + 5,100 + 5,100 + 6,350 | skipped (req 50, path at Ravenholdt only at 49.6) |
| 78676 / 78699, 96779-96786 | any / 96784 Horde | Dead Drop 410369 (Pyrewood) / index only | ? | skipped |

### Weapon masters for a rogue

Archibald 11870 (Undercity War Quarter, 57.31, 32.77): swords, daggers, crossbows; Sayoc 11868 / Hanashi 2704
(Orgrimmar, Valley of Honor 81.6, 19.6): fist, one-handed axes, daggers, bows, thrown; Ansekhwa 11869 (Thunder Bluff
40.93, 62.73): maces, guns.

## 12. Open issues for the orchestrator

None blocking.

## Minor, for phase R

* The `--levels` worst-case column of an optional step shows the level of the worst run at that point (e.g.
  `rog-train-16` 17.66), although the step is not done in that run: cosmetic, as in every class file.
* Russian NPC names and "«Shank»" (section 9) need the ruRU client.
* `docs/routes/class-rogue.md` numbers are a snapshot of phase C.
