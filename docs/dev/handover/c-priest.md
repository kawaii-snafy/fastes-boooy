# Hand-over C3: priest (`Classes/Priest.lua`)

Phase C of `docs/dev/PLAN.md` (D.5, row Priest), agent "priest", FAST MODE: targeted checks only, no `make check`, no
`make routedata` / `report`. No git command that changes state was run. `G` = `addons/FastesBoooy_Guides`.

## 1. What changed

| File | Change |
|---|---|
| `G/Classes/Priest.lua` | written (was a placeholder): 36 inserts, 42 steps (9 optional), all `class = "PRIEST"`, ids `pri-...`; header with every visit, anchor and validator level, what is skipped and why |
| `docs/routes/class-priest.md` | new (Russian; shape of `class-mage.md` / `class-paladin.md`): overview with grind per race, trainers, training tables 1-22 / 22-60, every insert with anchor and level, talents, class quests, weapons, decisions, uncertainties |
| `docs/dev/handover/c-priest.md` | this file |

`tools/overrides/priest.lua` was not created: no mask, XP or exclusivity correction is needed for what is routed.
Nothing else was touched (no segment, race file, other class file, spec, tool). Scratch files only under
`$SCRATCH/pri/`.

## 2. Acceptance: commands and results

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Classes/Priest.lua` | 0 warnings / 0 errors in 1 file, exit 0 |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --baseline docs/dev/handover/baseline.json --route "*-priest" --skip 'Classes/*' --keep "Classes/Priest.lua" --own "Classes/Priest.lua" $G` | **exit 0**: 0 error, 0 warning, 33 accepted (strict; all on shared steps, none in the priest file), 0 foreign; summary below |
| `lua5.1 tools/validate_routes.lua --route "<race>-priest" --levels <F> $G` (troll, undead) | exit 0 x 2; levels of every own step: `docs/routes/class-priest.md` section 3 |
| `lua5.1 tools/simulate_routes.lua --route "<race>-priest" --skip 'Classes/*' --keep "Classes/Priest.lua" $G` (one at a time) | **OK x 2**, no warning line: troll 1,708 steps (702 accepted / turned in), undead 1,727 (708), level 60 each |
| `GUIDES_SKIP='Classes/*' GUIDES_KEEP="Classes/Priest.lua" GUIDES_OWN="Classes/Priest.lua" busted tests/spec/guides_layout_spec.lua` | 22 successes / 0 failures / 0 errors |

`--summary` (route, profile, errors, warnings, accepted, foreign, end level, worst, grind, worst):

```
troll-priest	Troll PRIEST Horde	0	0	17	0	60.00	60.00	4950	6219	-	-
undead-priest	Scourge PRIEST Horde	0	0	16	0	60.00	60.00	4951	6209	-	-
```

Against the base route of the race (`--skip 'Classes/*'`, normal / worst, with the override files present at the
time: shared, hunter, rogue, shaman, warlock, warrior): Troll 4,979 / 6,226 -> 4,950 / 6,219; Undead 4,982 / 6,217 ->
4,951 / 6,209 (baseline file: Troll 4,980, Scourge 4,982). Grind up to the end of `h-18` (`--grind-until
h-18-stonetalon-ashenvale`, normal / worst): Troll 44 / 156 -> 40 / 151, Undead 47 / 147 -> 41 / 141: inside the
`h-18` budget 120 / 200.

### Kills per segment, base -> priest (normal run; segments not listed are equal within 2)

| Segment | Troll | Undead |
|---|---|---|
| start zone | `dur-02` 8 -> 5 | `ud-01` 3 -> 2, `ud-02` 1 -> 0 |
| `h-13-silverpine` | 0 -> 0 | 19 -> 15 |
| `h-53-azshara-ungoro-silithus` | 362 -> 338 (optional 8254 / 8255) | 362 -> 338 (same) |

No segment-level or level-grind ceiling moved into a warning.

## 3. Foreign warnings

None (`foreign` = 0 for both routes with `--own Classes/Priest.lua`).

## 4. Ids added

All in `Classes/Priest.lua` (prefix `pri-`):
`pri-dur-letter`, `pri-dur-kenjai`, `pri-dur-train-4`, `pri-dur-train-6`, `pri-dur-korja`, `pri-dur-5648`,
`pri-dur-train-10`, `pri-train-12`; `pri-tir-letter`, `pri-tir-duesten`, `pri-tir-train-4`, `pri-tir-train-6`,
`pri-tir-train-8`, `pri-tir-kel`, `pri-tir-train-10`, `pri-tir-train-12`; `pri-train-14-troll`, `pri-train-14-undead`,
`pri-train-18`, `pri-staves`, `pri-train-20`, `pri-train-22-troll`, `pri-train-22-undead`, `pri-5642`, `pri-5644`,
`pri-train-24`, `pri-train-26`, `pri-train-30`, `pri-train-34`, `pri-train-36`, `pri-train-40`, `pri-train-44`,
`pri-train-48`, `pri-train-52`, `pri-8254-accept`, `pri-8254-ogtinc`, `pri-8255-coursers`, `pri-8255-ogtinc`,
`pri-train-54`, `pri-train-56`, `pri-60-hearth`, `pri-train-60`.

Anchors used (all explicit ids, all unfiltered; inserts on start-zone anchors carry the race scope of the zone, the
`h12-fp-uc`, `h15-org`, `h-22-*` inserts carry the race they are for): `dur01-teeth`, `dur01-den-4`, `dur02-rh-1`,
`dur02-rh-2`, `dur02-rh-3`, `h12-fp-uc`, `ud01-364`, `ud01-arren-4`, `ud02-sethearth`, `ud02-brill-8`,
`ud02-holland-2`, `ud02-terrence`, `ud02-fp-uc`, `h15-org` (two inserts), `h18-tb-zamah`, `h18-sethearth-tb`,
`h-22-tb-start` (two inserts), `h-22-org-fp`, `h22-uc-garrett`, `h-24-tb-arrive`, `h-27-tb-arrive`, `h-31-org`,
`h-34-uc-arrive`, `h-37-orgrimmar`, `h-40-org-arrive`, `h-44-uc-arrive`, `h-50-org-arrive`, `h52-uc-81954`,
`h-53-org-arrive`, `h-53-azshara-field-loop` (one `before`, one `after`), `h56-sethearth-org`, `h-58-org-arrive`,
`h-60-end`.

Notes on the C.2 draft: the priest training of Durotar is `dur01-den-4` (4), `dur02-rh-1` (6), `dur02-rh-3` (8 + 10:
the Razor Hill stop at 9.45 is merged, `dur02-rh-2` at 7.88 is below 8 and only turns in 5648). The draft "priest 5648
at `dur02-rh-1`" holds. The Undead level-4 training stands after `ud01-arren-4` (4.01), because `ud01-church-4` is at
3.74. The Orgrimmar class stop of the Troll at 11 (`h12-*`, "priest 5654" in C.2) is not used: 5654 is turned in at
14 on the training step after `h15-org`, which the path passes anyway.

## 5. Anchor wishes

None: every visit found an explicit id at the right place.

## 6. Deviations from the plan / classes.md

1. **The breadcrumbs 5649 (Ken'jai > Tai'jin) and 5651 (Duesten > Beryl), 90 XP each, are not routed**, although
   classes.md 5.7 lists them as ROUTE. Both need level 5. The validator reaches the last start-camp stop at 5.12
   (`dur01-leave`) and 5.33 / 5.23 (`ud01-381`), but the simulator is there at level 4 and printed "quest 5649 / 5651
   would not be offered yet: requires level 5 (player is 4)". A class `level = 5` step there would make a player who
   is short grind in the start camp; the Durotar level-5 gate stands at the familiars north of the Den, not at
   Ken'jai. 5648 / 5650 are offered without the breadcrumb (DB: `breadcrumbs`, no `preSingle`), so only 90 XP each is
   lost. Both simulations are now free of warnings.
2. **Troll level-10 racial (5654) turned in at 14**, not at the first Orgrimmar visit (11.1): the Valley of Spirits is
   ~50 s off the path at 11.1 and on the way at 14 (the training step after `h15-org` takes the turn-in).
3. **Level-20 racial quests**: classes.md says "accept 5642 in Thunder Bluff at `h-22-tb-start`, turn in at
   `h-22-org-fp`" for the Troll (done) and "accept 5644 or 5646 at 22.06 on the way to the Undercity" for the Undead:
   5644 is taken from Miles Welsh at `h-22-tb-start` (merged with the training step at the same NPC) and turned in to
   Aelthalyste after `h22-uc-garrett` (22.74 / 22.05; ~70 s there and back from the flight master).
4. **8254 + 8255 (Cenarion Aid)** routed as optional, the same pattern and anchors as the hunter's 8151 / 8153.

## 7. XP values and mask corrections for quests I may not override

None needed. Unknown XP in the DB (INFO `xp-unknown`, estimated by the validator): 5658 Touch of Weakness (estimated
420, the median of level-10 quests; the breadcrumb variants give 210 in Classic, so the direct variant is probably
210 or less; record with `/fb xp`). 5642 / 5644 / 8254 / 8255 have Classic values in the DB.

## 8. Place names for `PLACE_NAMES_RU`

None new (the notes name the War Quarter / Военный квартал, the Valley of Spirits / Аллея Духов, the Pools of Vision /
Пруды Видений, Razor Hill, Brill, Deathknell, the Den: all already used by other files).

## 9. DB overrides added

None.

## 10. `-- CONFIRM` list

* `pri-tir-train-12`: what 5658 Touch of Weakness teaches in Forever (web: the Undead racial pair is Touch of Weakness
  + Dark Sacrifice).
* `pri-5642`: what 5642 Shadowguard teaches in Forever (web: the Troll racial pair is Hex of Weakness + Shadowguard).
* `pri-5644`: what 5644 Devouring Plague teaches in Forever (web: Devouring Plague is a trainer spell at 20 for every
  priest).
* `pri-staves`: whether a Forever priest already knows Staves (the step is optional and says "if the skill window does
  not list it").
* `pri-8255-coursers`: drop rate of the Healthy Courser Gland (not in the DB).
* Header: the `spells` lists of the `train` steps are the trainer lists of the original game, except the key levels
  of classes.md 5.7 (4 Shadow Word: Pain, 10 Mind Blast, 20 Devouring Plague, 32 Shadow Word: Death).
* Russian NPC and quest names in the notes (see `class-priest.md` section 8).

## 11. Facts for the future atlas

Priest trainers (DB, Horde-friendly, uiMap x, y):

| Place | Trainers |
|---|---|
| Valley of Trials, the Den (teaches to 6) | Ken'jai 3707 (1411, 42.36, 68.81) |
| Razor Hill | Tai'jin 3706 (1411, 54.26, 42.93) |
| Deathknell chapel (teaches to 6) | Dark Cleric Duesten 2123 (1420, 31.11, 66.03) |
| Brill, Gallows' End Tavern | Dark Cleric Beryl 2129 (1420, 61.57, 52.19) |
| Orgrimmar, Valley of Spirits | Ur'kyo 6018 (35.59, 87.82), X'yera 6014 (36.01, 87.73); Zayus 5994 "High Priest" (35.72, 86.90) has the trainer flag in the DB too |
| Thunder Bluff, Pools of Vision (Zamah's cave under Spirit Rise) | Miles Welsh 3044 (25.32, 15.27), Malakai Cross 3045 (24.56, 22.57), Father Cobb 3046 (25.64, 20.70) |
| Undercity, War Quarter | Aelthalyste 4606 (49.26, 17.12), Father Lankester 4607 (49.14, 14.61), Father Lazarus 4608 (47.57, 18.90) |

No priest trainer in Sen'jin, Mulgore, on Zephras Isle or in any questing hub. Wand vendors: Katis 5816 (Orgrimmar
44.18, 48.44), Zane Bradford 5754 (Undercity 69.56, 26.94), no item list in the DB. Weapon master for Staves next to a
path stop: Ansekhwa 11869 (Thunder Bluff 40.93, 62.73, by the inn).

Class quests (DB; XP = DB value, Classic source unless noted):

| Quest | Races | Giver -> turn-in | Objective | XP | Reward | Routed |
|---|---|---|---|---|---|---|
| 3085 Hallowed Tablet | Troll | Gornek 3143 -> Ken'jai 3707 | - | 40 | - | yes |
| 3097 Hallowed Scroll | Undead | Sarvis 1569 -> Duesten 2123 | - | 40 | - | yes |
| 5649 In Favor of Spirituality | Troll, req 5 | Ken'jai -> Tai'jin | breadcrumb | 90 | - | no (level, section 6) |
| 5648 Garments of Spirituality | Troll, req 5 | Tai'jin 3706 | heal + buff Grunt Kor'ja 12430 (1411, 53.10, 46.46) | 270 | robe | yes |
| 5651 In Favor of Darkness | Undead, req 5 | Duesten -> Beryl | breadcrumb | 90 | - | no (level) |
| 5650 Garments of Darkness | Undead, req 5 | Beryl 2129 | heal + buff Deathguard Kel 12428 (1420, 59.18, 46.50) | 270 | robe | yes |
| 5654 Hex of Weakness | Troll, req 10 | Tai'jin -> Ur'kyo | - | 210 | racial spell | yes |
| 5652 / 5655 / 5656 / 5657 | Troll | Ur'kyo / Var'jun (Bloodhoof) / Miles Welsh / Aelthalyste -> Ur'kyo | exclusive with 5654 | ? / 210 | same | no |
| 5658 Touch of Weakness | Undead, req 10 | Aelthalyste 4606 | - | unknown | racial spell | yes |
| 5660-5663 | Undead | Tai'jin / Var'jun / Ur'kyo / Miles Welsh -> Aelthalyste | exclusive with 5658 | 210 | same | no |
| 5642 Shadowguard | Troll, req 20 | Miles Welsh 3044 -> Ur'kyo | - | 390 | racial (CONFIRM) | yes |
| 5643 / 5680 | Troll | Aelthalyste / Ur'kyo -> Ur'kyo | exclusive with 5642 | 390 / ? | same | no |
| 5644 Devouring Plague | Undead, req 20 | Miles Welsh -> Aelthalyste | - | 390 | (CONFIRM) | yes |
| 5646 / 5679 | Undead | Ur'kyo / Aelthalyste -> Aelthalyste | exclusive with 5644 | 390 / ? | same | no |
| 8254 Cenarion Aid | any, req 50 | Malakai Cross 3045 or Ur'kyo -> Ogtinc 8405 (Azshara 42.40, 42.62) | - | 510 | - | optional |
| 8255 Of Coursers We Know | any, req 50 | Ogtinc | 4 Healthy Courser Gland 20027 (Mosshoof Courser 8761, Azshara ~36, 66) | 5,100 | - | optional |
| 8256 The Ichor of Undeath | any | Ogtinc | Ichor of Undeath (Zanzil trolls, Stranglethorn 43-44) | 5,100 | - | no |
| 8257 Blood of Morphaz | any | Ogtinc -> Greta Mosshoof (Felwood) | Morphaz, Sunken Temple | 6,350 | class item | no |

Not in the snapshot: 5691-5693, 5704-5706 (`<NYI>` Undead priest quests), 7504 (Dire Maul book).

## 12. Minor, for phase R

* The DB gives Zayus 5994 ("High Priest", Valley of Spirits) the trainer flag; he is not in the `npc` lists of the
  Orgrimmar training steps (Ur'kyo, X'yera). Check in game whether he trains.
* The notes say Thunder Bluff priest trainers stand in the Pools of Vision (from the coordinates: 30-60 yd from Zamah;
  classes.md 3.2 says "Spirit Rise"). The same cave in both readings; confirm in game.
* The valley/quarter detours (~20-90 s) are map estimates (7 yd/s on foot), not validator output.
