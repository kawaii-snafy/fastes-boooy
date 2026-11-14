# Hand-over C1: hunter (`Classes/Hunter.lua`)

Phase C of `docs/dev/PLAN.md` (D.5, row Hunter), agent "hunter", FAST MODE: targeted checks only, no `make check`, no
`make routedata` / `report`. No git command that changes state was run. `G` = `addons/FastesBoooy_Guides`.

## 1. What changed

| File | Change |
|---|---|
| `G/Classes/Hunter.lua` | written (was a placeholder): 35 inserts, 65 steps (10 optional), all `class = "HUNTER"`, ids `hun-...`; header with every visit, anchor and validator level, what is skipped and why |
| `tools/overrides/hunter.lua` | new, empty (`quests = {}`): no correction is needed; it exists so that the D.5 luacheck line runs as written. Comment names the Skyborne quests whose XP is unknown |
| `docs/routes/class-hunter.md` | new (Russian; shape of `class-paladin.md`): overview with grind per race, training tables 1-22 / 22-60, every insert with anchor and level, talents, class quests, pet services, weapons, decisions, uncertainties |
| `docs/dev/handover/c-hunter.md` | this file |

Nothing else was touched (no segment, race file, other class file, spec, tool).

## 2. Acceptance: commands and results

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Classes/Hunter.lua tools/overrides/hunter.lua` | 0 warnings / 0 errors in 2 files, exit 0 |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --baseline docs/dev/handover/baseline.json --route "*-hunter" --skip 'Classes/*' --keep "Classes/Hunter.lua" --own "Classes/Hunter.lua" $G` | **exit 0**: 0 error, 0 warning, 69 accepted (strict), 0 foreign; summary below |
| `lua5.1 tools/validate_routes.lua --route "<race>-hunter" --levels <F> $G` (all four races) | exit 0 x 4; levels at every own step: `docs/routes/class-hunter.md` §3 |
| `lua5.1 tools/simulate_routes.lua --route "<race>-hunter" --skip 'Classes/*' --keep "Classes/Hunter.lua" $G` (one at a time) | **OK x 4**: orc 1,710 steps (703 accepted / turned in), troll 1,712 (703), tauren 1,713 (709), skyborne 1,757 (722), level 60 each; skyborne prints the two known warnings of P2 (`sd02-hearth` bind point, optional `sky-1061` at 12), the other three none |
| `GUIDES_SKIP='Classes/*' GUIDES_KEEP="Classes/Hunter.lua" GUIDES_OWN="Classes/Hunter.lua" busted tests/spec/guides_layout_spec.lua` | 22 successes / 0 failures / 0 errors |

`--summary` (route, profile, errors, warnings, accepted, foreign, end level, worst, grind, worst):

```
orc-hunter	Orc HUNTER Horde	0	0	16	0	60.00	60.00	4944	6207	-	-
troll-hunter	Troll HUNTER Horde	0	0	16	0	60.00	60.00	4944	6207	-	-
tauren-hunter	Tauren HUNTER Horde	0	0	18	0	60.00	60.00	4933	6180	-	-
skyborne-hunter	Skyborne HUNTER Horde	0	0	19	0	60.00	60.00	4888	6121	-	-
```

Against the baseline of the race (normal / worst): Orc and Troll 4,979 / 6,226 -> 4,944 / 6,207; Tauren 4,965 / 6,197
-> 4,933 / 6,180; Skyborne 4,914 / 6,129 -> 4,888 / 6,121. Grind up to the end of `h-18` (same command plus
`--grind-until h-18-stonetalon-ashenvale`, normal / worst): Orc / Troll 30 / 137 (base 44 / 156), Tauren 19 / 110
(base 30 / 127), Skyborne 0 / 51 (base 0 / 59): inside the `h-18` budget 120 / 200.

### Kills per segment, base -> hunter (normal run; the segments not listed are equal within 1)

| Segment | Orc / Troll | Tauren | Skyborne |
|---|---|---|---|
| start zone | `dur-02` 8 -> 7 (exit 11.10 -> 11.36) | `mul-01` 1 -> 0 (exit `mul-03` 12.00 -> 12.28) | 0 -> 0 (exit `sd-03` 13.24 -> 13.38) |
| `h-18-stonetalon-ashenvale` | 36 -> 23 | 29 -> 19 | 0 -> 0 |
| `h-27-ashenvale-needles` | 122 -> 122 | 122 -> 122 | 101 -> 96 |
| `h-53-azshara-ungoro-silithus` | 362 -> 341 | 362 -> 341 | 362 -> 341 |

## 3. Foreign warnings

None (`foreign` = 0 for all four routes with `--own Classes/Hunter.lua`).

## 4. Ids added

All in `Classes/Hunter.lua` (prefix `hun-`):
`hun-dur-letter-orc`, `hun-dur-jenshan-orc`, `hun-dur-letter-troll`, `hun-dur-jenshan-troll`, `hun-dur-train-4`,
`hun-dur-train-6`, `hun-dur-train-8`, `hun-dur-train-10`, `hun-dur-boar`, `hun-dur-6083`, `hun-dur-crawler`,
`hun-dur-6082`, `hun-dur-scorpid`, `hun-dur-6081`; `hun-mul-letter`, `hun-mul-lanka`, `hun-mul-train-4`,
`hun-mul-train-6`, `hun-mul-train-10`, `hun-mul-plainstrider`, `hun-mul-6087`, `hun-mul-stalker`, `hun-mul-6088`,
`hun-mul-swoop`, `hun-mul-6089`, `hun-mul-holt`; `hun-zep-letter`, `hun-zep-tairee`, `hun-zep-train-4`,
`hun-zep-train-6`, `hun-zep-train-8`, `hun-zep-level-10`, `hun-zep-train-10`, `hun-zep-crawler`, `hun-zep-94979`,
`hun-zep-galestrider`, `hun-zep-94013`, `hun-zep-alpha`, `hun-zep-94050`, `hun-zep-queldora`, `hun-zep-train-12`;
`hun-12-ormak`, `hun-train-12`, `hun-train-14`, `hun-train-18`, `hun-guns`, `hun-train-20`, `hun-train-26`,
`hun-train-30`, `hun-train-34`, `hun-train-36`, `hun-train-40`, `hun-train-44`, `hun-train-48`, `hun-train-52`,
`hun-8151-accept`, `hun-8151-ogtinc`, `hun-8153-coursers`, `hun-8153-ogtinc`, `hun-train-54`, `hun-train-56`,
`hun-60-hearth`, `hun-60-zeppelin`, `hun-60-durotar`, `hun-60-train`.

Anchors used (all explicit ids, all unfiltered or with the same race scope): `dur01-teeth`, `dur01-den-4`,
`dur02-garthok`, `dur02-garthok-3`, `dur02-rh-3`, `mul01-hunt`, `mul01-ravine`, `mul02-yaw`, `mul02-bh-5`,
`mul03-melor`, `sd01-rorian`, `sd01-thendal-4`, `sd01-raan-2`, `sd01-danarii-2`, `sd02-riaani`, `sd02-hearth`,
`h12-whuut`, `h15-org`, `h18-tb-1`, `h18-sethearth-tb`, `h-27-hearth-tb`, `h30-tb-1131`, `h34-sethearth-gromgol`,
`h-37-org-arrive`, `h-40-org-arrive`, `h44-sethearth-gromgol`, `h49-org-2976`, `h52-stonard-1445`, `h-53-org-arrive`,
`h-53-azshara-field-loop` (one `before`, one `after`), `h-56-org-arrive`, `h-58-org-arrive`, `h-60-end`.

## 5. Anchor wishes

None: every visit found an explicit id at the right place. (`h18-fp-tb` would have been the natural anchor of the
level-18 visit, but it is race-filtered: the insert stands after the unfiltered `h18-tb-1`, as C.3 rule 8 asks.)

## 6. XP values and mask corrections for quests I may not override

None. All hunter quests have the right race and class masks in the snapshot (letters, the three pet chains, 8151 /
8153). XP unknown (Forever-new, estimated by the validator): 92482, 94978, 94979, 94013, 94050 (Skyborne); record with
`/fb xp` and put them into `tools/overrides/hunter.lua` (the file is the owner of these quests).

## 7. New place names for `PLACE_NAMES_RU`

None: the file names no new place in a `fly` / `hearth` / `sethearth` / `fp` action (`hun-60-hearth` uses
"Undercity", which exists).

## 8. DB overrides added

None (`tools/overrides/hunter.lua` is empty).

## 9. `-- CONFIRM` list (in the file)

* `hun-dur-scorpid` (and the Tauren / Skyborne equivalents): the beast tamed with the Taming Rod stays as the pet.
* `hun-zep-crawler`: the three Zephras beasts have spawns right at Quel'ana in Valanaar (the DB has a spawn of each
  within 1 % of her; the others are spread over 43-63, 43-87). Fallback in the note: the south-west of the isle.
* `hun-train-40`: mail and Aspect of the Pack / Volley at 40 (spell levels of the original game; classes.md 5.2 says
  "40 Aspect of the Pack (and mail, C)").
* `hun-8153-coursers`: drop rate of the Perfect Courser Antler (not in the DB).
* Header: the spell lists of the `train` steps beyond the key levels of classes.md 5.2 are the original game's.

## 10. Deviations from the plan

1. **No class reward table** (D.5 "the class reward table"; A.5.4): the snapshot has no reward lists, so no index
   can be written without guessing; a wrong index makes the automation take the wrong item. Same decision as the
   paladin file. The notes of the training steps name what to look for.
2. **Skyborne pet chain at the first Valanaar visit** (`sd02-riaani`, 10.43) instead of the C.2 anchor
   `sd02-valanaar-10` (11.20): the pet comes 0.8 level earlier; a class-scoped `level = 10` step (`hun-zep-level-10`,
   C.3 rule 4) guards the reqLevel in game (the validator has 10.43 normal and worst).
3. **Orc / Troll train 12 at 14** (`h15-org`): Orgrimmar at 11.81 (`h12-whuut`) is below 12; only 6081 is turned in
   there (B.9 expected exactly this for hunter and shaman, P2 deviation 1).
4. **`tools/overrides/hunter.lua` exists but is empty**: created only so that the D.5 luacheck command line runs as
   written; it holds no correction.
5. **Weapon skill**: one optional step (`hun-guns`, Guns + Staves at Ansekhwa, Thunder Bluff, 50 yd from the inn at
   20). Without reward lists in the DB the step cannot be tied to a concrete reward; bows (Orgrimmar) and crossbows
   (Undercity) are only named in the doc.

## 11. Facts for the atlas

### Hunter trainers (DB)

| Place | Trainer (id, uiMap, x, y) | Note |
|---|---|---|
| Valley of Trials | Jen'shan 3154 (1411, 42.84, 69.33) | up to 6 |
| Razor Hill | Thotar 3171 (1411, 51.85, 43.49) | pet chain Orc / Troll (6062, 6083, 6082, 6081); 5 yd from Garthok 3139 |
| Camp Narache | Lanka Farshot 3061 (1412, 43.96, 76.35) | up to 6 |
| Bloodhoof Village | Yaw Sharpmane 3065 (1412, 46.93, 59.65) | pet chain Tauren (6061, 6087, 6088, 6089); also gives 96130 Chakuyak (all classes) |
| Thendal (Zephras) | Tai'ree Farsight 251376 (2521, 42.49, 23.79) | up to 6 |
| Shen'dar (Zephras) | Elayaa Easewind 254084 (2521, 45.26, 44.24) | gives 94007 (breadcrumb to Quel'ana) |
| Valanaar (Zephras) | Quel'ana Quickgale 252389 (2521, 59.56, 72.63) | pet chain Skyborne (94978, 94979, 94013, 94050); pet trainer Quel'dora Quickgale 254411 (59.92, 72.87) |
| Orgrimmar, Valley of Honor | Ormak Grimshot 3352 (66.05, 18.53), Xor'juul 3406 (67.24, 20.20), Sian'dur 3407 (67.96, 17.80) | Ormak: 6081 turn-in, 8151; Sian'dur: 6066 / 6068; pet trainer Xao'tsu 10088 (66.32, 14.81) |
| Thunder Bluff, Hunter Rise | Kary Thunderhorn 3038 (58.49, 88.33), Holt Thunderhorn 3039 (57.30, 89.79), Urek Thunderhorn 3040 (59.13, 86.87) | Holt: 6089 turn-in, 8151; Kary: 6065 / 6070; Melor Stonehoof 3441 (61.5, 80.9) is 80 yd away; pet trainer Hesuwa 10086 (54.09, 83.99) |
| Grom'gol | Kragg 1404 (1434, 31.23, 28.68) | pet trainer Zudd 3624 next to him |
| Stonard | Ogromm 987 (1435, 47.26, 53.43) | pet trainer Grokor 3622 next to him |
| Undercity, Brill | none | |

### Class quests (DB) and rewards

| Quest | Race | Giver -> ender | XP (DB) | Reward / effect |
|---|---|---|---|---|
| 3087 Etched Parchment / 3082 Etched Tablet | Orc / Troll | Gornek 3143 -> Jen'shan 3154 (pre 788) | 40 | letter |
| 3092 Etched Note | Tauren | Grull Hawkwind 2980 -> Lanka Farshot 3061 (pre 747) | 60 | letter |
| 92482 The Way of the Hunter | any (only on Zephras) | Rorian 251361 -> Tai'ree 251376 (pre 92461; item 282421 Scribbled Note) | ? | letter |
| 6062 / 6083 / 6082 Taming the Beast | Orc, Troll | Thotar; Dire Mottled Boar 3099 (rod 15917), Surf Crawler 3107 (15919), Armored Scorpid 3126 (15920) | 840 each | the tamed beast |
| 6081 Training the Beast | Orc, Troll | Thotar -> Ormak Grimshot 3352 | 420 | Tame Beast, pet spells |
| 6061 / 6087 / 6088 Taming the Beast | Tauren | Yaw; Adult Plainstrider 2956 (15914), Prairie Stalker 2959 (15915), Swoop 2970 (15916) | 840 each | the tamed beast |
| 6089 Training the Beast | Tauren | Yaw -> Holt Thunderhorn 3039 | 420 | Tame Beast, pet spells |
| 94978 / 94979 / 94013 Taming the Beast | Skyborne (mask incl. Alliance Skyborne) | Quel'ana; Windsong Crawler 254588 (267272), Ornery Galestrider 251707 (267298), Vuldren Alpha 250874 (264163) | ? | the tamed beast |
| 94050 Training the Beast | Skyborne | Quel'ana -> Quel'dora 254411 | ? | Tame Beast, pet spells |
| 6065-6070 The Hunter's Path | Tauren (6065-6067) / Orc, Troll (6068-6070) | city trainers / Kali Remik 11814 (Sen'jin) / Thotar -> Yaw / Thotar | 85 | breadcrumb (skipped) |
| 94007 Taming the Beast | Skyborne | Elayaa -> Quel'ana | ? | breadcrumb (skipped) |
| 8151 The Hunter's Charm | any | Holt / Ormak -> Ogtinc 8405 (Azshara 42.40, 42.62) | 510 | routed, optional |
| 8153 Courser Antlers | any | Ogtinc; 2 x Perfect Courser Antler 20017 from Mosshoof Courser 8761 (Azshara ~36, 66) | 5,100 | routed, optional |
| 8231 Wavethrashing, 8232 The Green Drake | any | Ogtinc | 5,100 / 6,350 | skipped (bays of Azshara; Sunken Temple) |

### Skipped and why

* Breadcrumbs 6065-6070 and 94007: their givers are not on the path at level 10.
* 8231 / 8232: long (bays of Azshara, then a dungeon).
* Pet trainers: Growl / pet skill ranks are a player choice; the notes name the trainer next door.
* Training at 22 / 24 (one rank each), 28 at `h-28` (worst 27.91), 14 for Tauren / Skyborne, Stonard at 44.03,
  Grom'gol at 44.5-45.3, Orgrimmar at 31.05 / 41.01 / 52.70 / 53.05: nothing new or one rank, merged into the next visit.

## 12. Minor, for phase R

* The header comment line of the level-20 visit in `Hunter.lua` is longer than 120 characters (luacheck does not check
  comment length here); cosmetic.
* The Russian notes of the class file use Latin names for Zephras NPCs (as `Druid.lua` does); NPC names of the
  mainland are in Russian, partly my own transcription (Ормак Мрачный Выстрел, Яу Острогривый, Ланка Дальний Выстрел,
  Огромм, Огтинк): check against the ruRU client when `PLACE_NAMES_RU` / names are reviewed.
* The full module check with all nine class files at once (`$(VALIDATE_FLAGS)`) was not run here (other class agents
  were writing their files): phase R.
