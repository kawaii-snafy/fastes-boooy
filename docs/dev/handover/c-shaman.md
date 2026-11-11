# Hand-over C2: shaman (`Classes/Shaman.lua`)

Phase C of `docs/dev/PLAN.md` (D.5, row Shaman), agent "shaman", FAST MODE: targeted checks only, no `make check`, no
`make routedata` / `report`. No git command that changes state was run. `G` = `addons/FastesBoooy_Guides`.

## 1. What changed

| File | Change |
|---|---|
| `G/Classes/Shaman.lua` | written (was a placeholder): 48 inserts, 91 steps (13 optional), all `class = "SHAMAN"`, ids `sha-...`; header with every visit, anchor and validator level, what is skipped and why. The mainland Call of Fire chain is one builder function used twice (Tauren `sha-mul-fire-*`, Orc / Troll `sha-fire-*`) |
| `tools/overrides/shaman.lua` | new: one correction, `preSingle` of 1516 and 1519 (section 8) |
| `docs/routes/class-shaman.md` | new (Russian; shape of `class-paladin.md` / `class-hunter.md`): overview with grind per race, training tables 1-22 / 22-60, every insert with anchor and level, talents, class quests, weapons, decisions, uncertainties |
| `docs/dev/handover/c-shaman.md` | this file |

Nothing else was touched (no segment, race file, other class file, spec, tool).

## 2. Acceptance: commands and results

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Classes/Shaman.lua tools/overrides/shaman.lua` | 0 warnings / 0 errors in 2 files |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --baseline docs/dev/handover/baseline.json --route "*-shaman" --skip 'Classes/*' --keep "Classes/Shaman.lua" --own "Classes/Shaman.lua" $G` | **exit 0**: 0 error, 0 own warning, 72 accepted (strict, 1 of them foreign), 1 foreign warning (section 3); summary below |
| `lua5.1 tools/validate_routes.lua --route "<race>-shaman" --levels <F> $G` (all four races) | exit 0 x 4; levels at every own step: `docs/routes/class-shaman.md` §3 |
| `lua5.1 tools/simulate_routes.lua --route "<race>-shaman" --skip 'Classes/*' --keep "Classes/Shaman.lua" $G` (one at a time) | **OK x 4**, level 60: orc 1,724 steps (709 accepted / turned in), troll 1,726 (709), tauren 1,728 (715), skyborne 1,770 (727). No warning on a shaman step; skyborne prints only the two known base warnings of P2 (`sd02-hearth` bind point, optional `sky-1061` at 12). "cold start resumes at step N-3/N": the last steps are the optional trip after `h-60-end` |
| `GUIDES_SKIP='Classes/*' GUIDES_KEEP="Classes/Shaman.lua" GUIDES_OWN="Classes/Shaman.lua" busted tests/spec/guides_layout_spec.lua` | 22 successes / 0 failures / 0 errors |

`--summary` (route, profile, errors, warnings, accepted, foreign, end level, worst, grind, worst):

```
orc-shaman	Orc SHAMAN Horde	0	0	17	0	60.00	60.00	4937	6183	-	-
troll-shaman	Troll SHAMAN Horde	0	0	17	0	60.00	60.00	4937	6183	-	-
tauren-shaman	Tauren SHAMAN Horde	0	0	19	0	60.00	60.00	4930	6167	-	-
skyborne-shaman	Skyborne SHAMAN Horde	0	0	19	1	60.00	60.00	4896	6118	-	-
```

Against the baseline of the race (normal / worst): Orc and Troll 4,979 / 6,226 -> 4,937 / 6,183; Tauren 4,965 / 6,197
-> 4,930 / 6,167; Skyborne 4,914 / 6,129 -> 4,896 / 6,118. Grind up to the end of `h-18` (same command plus
`--grind-until h-18-stonetalon-ashenvale`, normal / worst): Orc / Troll 8 / 113 (base 44 / 156), Tauren 1 / 97 (base
30 / 127), Skyborne 0 / 48 (base 0 / 59): inside the `h-18` budget 120 / 200.

### Kills per segment, base -> shaman (normal run; the segments not listed are equal within 1)

| Segment | Orc / Troll | Tauren | Skyborne |
|---|---|---|---|
| start zone | `dur-02` 8 -> 0 (exit 11.10 -> 11.10) | `mul-01` 1 -> 0 (exit `mul-03` 12.00 -> 12.57) | 0 -> 0 (exit `sd-02` 13.24 -> 13.48; `sd-01` 9.93 -> 10.08, section 3) |
| `h-18-stonetalon-ashenvale` | 36 -> 8 | 29 -> 1 | 0 -> 0 |
| `h-27-ashenvale-needles` | 122 -> 117 | 122 -> 117 | 101 -> 84 |

## 3. Foreign warnings

One, Skyborne only:

```
WARN [library FastesBoooy_Guides] sd-01-zephras (Segments/Zephras/01_Zephras_1_9.lua) [segment-level]
     segment sd-01-zephras ends at simulated level 10.08; planned end level 9
```

Cause: the shaman letter 92484 and the Earth chain 92466 - 92468 (Forever-new, XP estimated by the median) are turned
in inside `sd-01`. For phase R: raise the planned end level of `sd-01-zephras` (`levels = { 1, 9 }` -> `{ 1, 10 }`) or
acknowledge the warning on the segment; the class steps are right where they are (the Earth Totem at 4-5).

## 4. Ids added

All in `Classes/Shaman.lua` (prefix `sha-`):
`sha-dur-letter-orc`, `sha-dur-shikrik-orc`, `sha-dur-letter-troll`, `sha-dur-shikrik-troll`, `sha-dur-level-4`,
`sha-dur-1516`, `sha-dur-train-4`, `sha-dur-hooves`, `sha-dur-1517`, `sha-dur-manifestation`, `sha-dur-1518`,
`sha-dur-train-6`, `sha-dur-train-8`, `sha-dur-train-10`;
`sha-mul-letter`, `sha-mul-meela`, `sha-mul-1519`, `sha-mul-train-4`, `sha-mul-salves`, `sha-mul-1520`,
`sha-mul-manifestation`, `sha-mul-1521`, `sha-mul-train-6`, `sha-mul-train-8`, `sha-mul-train-10`;
`sha-mul-fire-kranal`, `-telf`, `-pouch`, `-tar`, `-telf-2`, `-ember`, `-brazier`, `-kranal-2` and the same eight with
the prefix `sha-fire-` (Orc / Troll);
`sha-zep-letter`, `sha-zep-boro`, `sha-zep-level-3`, `sha-zep-92466`, `sha-zep-signet`, `sha-zep-train-4`,
`sha-zep-manifestation`, `sha-zep-92468`, `sha-zep-train-6`, `sha-zep-train-8`, `sha-zep-level-10`, `sha-zep-train-10`,
`sha-zep-olariaan`, `sha-zep-faladiel`, `sha-zep-olariaan-2`, `sha-zep-kuramaa`, `sha-zep-olariaan-3`,
`sha-zep-brazier-1`, `sha-zep-brazier-2`, `sha-zep-train-12`;
`sha-12-train`, `sha-train-14`, `sha-train-18`, `sha-2h-maces`, `sha-train-20`, `sha-1529`, `sha-islen`,
`sha-train-22`, `sha-train-24`, `sha-brine`, `sha-watering-hole`, `sha-brine-2`, `sha-train-26`, `sha-train-28`,
`sha-train-30`, `sha-1532`, `sha-train-36`, `sha-train-40`, `sha-train-44`, `sha-prate`, `sha-prate-back`,
`sha-train-48`, `sha-train-50`, `sha-train-52`, `sha-train-54`, `sha-train-56`, `sha-60-hearth`, `sha-60-zeppelin`,
`sha-60-durotar`, `sha-60-train`.

Anchors used (all explicit ids, all unfiltered or with the same race scope): `dur01-teeth`, `dur01-den-4`,
`dur01-thazzril-2`, `dur01-leave`, `dur02-rh-1`, `dur02-garthok-3`, `dur02-rh-3`, `mul01-hunt`, `mul01-ravine`,
`mul01-belts`, `mul01-leave`, `mul02-bh-1`, `mul02-bh-3`, `mul02-bh-5`, `mul03-far-watch`, `sd01-rorian`,
`sd01-agitators`, `sd01-thendal-4`, `sd01-illaya-2`, `sd01-shendar-8`, `sd02-endaria`, `sd02-riaani`,
`sd02-valanaar-10`, `sd02-speech`, `h12-wisdom`, `h15-razor-hill`, `h15-far-watch`, `h18-tb-zamah`,
`h18-sethearth-tb`, `h18-tb-2`, `h18-fly-ratchet-2`, `h18-end`, `h-24-tb-arrive`, `h-24-gann-stonespire`,
`h-27-tb-arrive`, `h-28-skywatcher`, `h-31-tb-end`, `h-37-org-arrive`, `h-40-org-arrive`, `h-44-stonard-arrive`,
`h46-fly-freewind`, `h-50-org-arrive`, `h-51-stonard`, `h-53-org-arrive`, `h-56-org-arrive`, `h-58-org-arrive`,
`h-60-end`.

## 5. Anchor wishes

None: every visit found an explicit id at the right place.

## 6. XP values and mask corrections for quests I may not override

None. All shaman quests of the routes are used only by `Classes/Shaman.lua`. XP unknown (Forever-new, estimated by the
validator): 92484, 92466, 92467, 92468, 97243, 97244, 97245, 97257 (Skyborne); record with `/fb xp` and put them into
`tools/overrides/shaman.lua`.

## 7. New place names for `PLACE_NAMES_RU`

None: the only place in a `fly` / `hearth` / `sethearth` / `fp` action is "Undercity" (`sha-60-hearth`), which exists.

## 8. DB overrides added

`tools/overrides/shaman.lua`: 1516 and 1519 (Call of Earth, first quest of the Durotar / Mulgore chain):
`preSingle = { remove = { 1516, 1519, 92466 } }`, `verified = false`, source the Classic Wowhead pages. The snapshot
gives both the pre-quest list "one of 1516, 1519, 92466" - the exclusive group of the three Earth chains written as a
prerequisite, so the quest needs itself turned in and can never be accepted (validator ERROR `accept-prereq`, the
simulator would not offer it). The exclusive lists stay. The two accept steps carry `ok = "db-override-unverified"`
with a `-- CONFIRM` comment. Probably a generic conversion defect of the snapshot builder (`exclusiveTo` mapped into
`preSingle` when the quest is in its own group); worth a check in `tools/build_db_snapshot.py` (phase R or later).

## 9. `-- CONFIRM` list (in the file)

* `sha-dur-1516`, `sha-mul-1519`: no prerequisite (the override above).
* `sha-fire-telf` / `sha-mul-fire-telf`: where the trail up to Telf Joolam starts (only his position is in the DB).
* `sha-zep-signet`: the Al'Aketh Converts of the agitators' camp drop the Signet of Akir (eight drop sources in the DB,
  no rates).
* `sha-2h-maces`: shamans learn two-handed maces / axes from weapon masters in Forever (a talent in the original game).
* `sha-train-20`: Ghost Wolf, Totemic Recall and Call of the Elements at 20.
* Header: the spell lists of the `train` steps beyond the key levels of classes.md 5.4 are the original game's.

## 10. Deviations from the plan

1. **No class reward table** (D.5; A.5.4): the snapshot has no reward lists, so no index can be written without
   guessing (same decision as the paladin and hunter files).
2. **Call of Fire for Orc / Troll at 14.3** (`h15-far-watch`) as C.2 decided, not earlier: a full chain from
   `dur02-crocs` / `dur02-thunder-ridge` at 10.8 would cost about the same walking (~9,600 yd against ~6,500 + 640) and
   give the Searing Totem three levels earlier; not done because C.2 fixes the start at the post. Candidate for a later
   tuning pass.
3. **Skyborne Fire chain in three visits** (`sd02-endaria` 10.45, `sd02-riaani` 10.55, `sd02-valanaar-10` 11.36,
   `sd02-speech` 13.36): the quest order Olariaan > Faladiel (north-east) > Olariaan (south) > Kuramaa (west) >
   Olariaan > braziers does not fit the path; the last three legs are one trip before the skycutter. Zephras has no
   world size in the DB, so the detour is not measured in yards (about 60 % of the isle's width).
4. **Class-scoped level gates** `sha-dur-level-4` (before 1516), `sha-zep-level-3` (before 92466), `sha-zep-level-10`
   (before 97243): the validator is above the level there (4.68, 3.14, 10.45 normal and worst), the simulator (quest
   XP only) was at 3 and 8 and printed "would not be offered"; the gates cost no kill in the validator.
5. **Call of Water: only the first part, optional** (1529 > 1530 > 1535, 2,085 XP); the totem is not routed (classes.md
   5.10 "candidate"; the rest of the chain is gray when the path reaches its places). **Call of Air**: the accept at 31
   is mandatory (zero detour), the turn-in at 46 optional (`sha-prate`).
6. **Level 28** is optional at Palah on Skywatcher Plateau (worst 27.97); 28 is merged into the 30 visit otherwise.

## 11. Facts for the atlas

### Shaman trainers (DB)

| Place | Trainer (id, uiMap, x, y) | Note |
|---|---|---|
| Valley of Trials | Shikrik 3157 (1411, 42.39, 69.00) | up to 6; letters 3089 / 3084 end here |
| Razor Hill | Swart 3173 (1411, 54.42, 42.59) | gives 2983 (Fire), 2985 (Water), 98517 (Skyborne Fire breadcrumb) |
| Camp Narache | Meela Dawnstrider 3062 (1412, 44.58, 76.56) | up to 6; letter 3093 ends here |
| Bloodhoof Village | Narm Skychaser 3066 (1412, 47.40, 62.54) | gives 2984 (Fire), 2986 (Water) |
| Skywatcher Plateau | Palah Thunderhoof 262558 (1412, 33.59, 22.40) | at the skycutter landing; trainer level 55 |
| Thendal (Zephras) | Windshaper Boro 251374 (2521, 42.79, 23.58) | up to 6; 92484 ends here, 92466 / 92467 / 92468 |
| Shen'dar (Zephras) | Aarnor Galestrike 254082 (2521, 43.45, 44.87) | gives 97243 |
| Valanaar (Zephras) | Sessaria Skystride 252382 (2521, 58.31, 78.51) | gives 97243, takes 97257 and 98517 |
| Orgrimmar, Valley of Wisdom | Kardris Dreamseeker 3344 (38.80, 36.37), Sian'tsu 3403 (37.84, 36.45), Sagorne Creststrider 13417 (38.66, 35.92) | Searn Firewarder 5892 (37.96, 37.73) gives 1522, 1528, 1531; Sagorne gives 8410 |
| Thunder Bluff, Spirit Rise | Siln Skychaser 3030 (22.82, 21.11), Tigor 3031 (23.64, 18.79), Beram 3032 (21.99, 18.80) | Xanis Flameweaver 5906 (25.16, 20.51) gives 1523, 1529, 1532; Beram gives 8410; Zamah 3419 stands at (22.81, 20.89) |
| Stonard | Haromm 986 (1435, 48.19, 57.94) | |
| Undercity, Brill | none | |

### Class quests (DB) and rewards

| Quest | Race | Giver -> ender | XP (DB) | Reward / effect |
|---|---|---|---|---|
| 3089 / 3084 Rune-Inscribed Parchment / Tablet | Orc / Troll | Gornek 3143 -> Shikrik 3157 (pre 788) | 40 | letter |
| 3093 Rune-Inscribed Note | Tauren | Grull Hawkwind 2980 -> Meela 3062 (pre 747) | 60 | letter |
| 92484 Embracing the Elements | all Horde mask (only on Zephras) | Rorian 251361 -> Boro 251374 (pre 92461; item 282418) | ? | letter |
| 1516 > 1517 > 1518 Call of Earth | all | Canaga Earthcaller 5887 (Den, 42.40, 69.17); Felstalker Hoof x2 (Felstalkers 3102, 44.0, 53.9); Minor Manifestation of Earth 5891 (1411 44.03, 76.20) | 270 + 270 + 445 | Earth Totem |
| 1519 > 1520 > 1521 Call of Earth | all | Seer Ravenfeather 5888 (44.35, 76.77); Ritual Salve x2 (Bristleback Shamans 2953, 59.4, 78.0); manifestation 5891 (1412 51.99, 80.40) | 270 + 180 + 445 | Earth Totem |
| 92466 > 92467 > 92468 Call of Earth | all (Zephras) | Boro (92467 also Aetheen 251366); Signet of Akir (Al'Aketh Brute / Convert / Neophyte ...); Minor Manifestation of Earth 251166 (2521 49.67, 23.80) | ? | Earth Totem |
| 2983 / 2984 / 1522 / 1523 Call of Fire (breadcrumbs, exclusive) | all | Swart / Narm / Searn / Xanis -> Kranal Fiss 5907 (1413 56.03, 19.89) | 420 | - |
| 1524 > 1525 > 1526 > 1527 Call of Fire | all | Kranal -> Telf Joolam 5900 (1411 38.55, 58.96); Fire Tar (Razormanes 3267 / 3268 / 3269 / 3271, Barrens 54-59, 24-27) + Reagent Pouch (Burning Blade Cultist 3199, Skull Rock 52.4, 25.5); Minor Manifestation of Fire 5893 at the Brazier of the Dormant Flame 61934 (38.96, 58.22) -> Kranal | 660 + 910 + 1,150 + 1,150 | Fire Totem (Searing Totem) |
| 97243 > 97244 > 97245 > 97257 Call of Fire | Skyborne | Sessaria / Aarnor -> Olariaan Swiftburn 268592 (2521 51.24, 86.19); Skypriest Faladiel 268602 (64.43, 63.71); Kuramaa 268605 (42.44, 68.75); Brazier of Offering 268762 (51.2, 85.9), Brazier of Eternal Flame 268679 (58.35, 78.84) -> Sessaria | ? | Fire Totem |
| 1528 / 1529 / 2985 / 2986 Call of Water (breadcrumbs) | all | Searn / Xanis / Swart / Narm -> Islen Waterseer 5901 (1413 65.83, 43.78) | 780 | - |
| 1530 > 1535 > 1536 > 1534 > 220 > 63 > 100 > 96 Call of Water | all | Islen -> Brine 5899 (1413 43.42, 77.41); Quilboar Watering Hole 107046 (44.28, 76.75); Spring Well (Hillsbrad 62.2, 20.8); Ruins of Stardust fountain (Ashenvale 33.5, 67.5); Brine -> Islen; Brazier of Everfount 113791 (Silverpine 38.3, 44.6, Corrupt Minor Manifestation of Water 5894) -> Minor Manifestation of Water 5895 -> Islen | 435 + 870 + 1,300 + 1,400 + 460 + 1,400 + 1,400 + 2,750 | Water Totem |
| 1531 / 1532 Call of Air | all | Searn / Xanis -> Prate Cloudseer 5905 (1441 53.54, 42.65) | 2,450 | Air Totem |
| 8410 / 8411 > 8412 > 8413 | all | Beram / Sagorne / Bath'rah 6176 (Alterac 80.5, 66.9); vultures (W. Plaguelands); Sunken Temple | 3,550 + 5,100 + 6,350 | class item |

### Skipped and why

The rest of Call of Water (four zones, gray when the path is there) and so the Water Totem; the other Water and Fire
breadcrumbs (exclusive; the routed ones cost nothing); 98517 (back to Zephras); the Sapta repeat quests 1462 / 1463 /
1464 / 972 / 1103 (lost Sapta only); 8410 - 8413 (dungeon); the Forever-new chains outside the snapshot (79358 - 79442,
96136). Weapon skills: only the optional Two-Handed Maces at Ansekhwa 11869 (Thunder Bluff, 40.93, 62.73); two-handed
axes are at Hanashi 2704 / Sayoc 11868 (Orgrimmar, Valley of Honor).

## 12. Minor, for phase R

* `sd-01-zephras` planned end level (section 3).
* The snapshot builder's self-referencing `preSingle` (section 8): other class chains with an exclusive group of first
  quests may have the same defect (the warrior / hunter / rogue agents did not report one).
* The Orc / Troll Fire chain could move to 10.8 (deviation 2) if a tuning pass wants the Searing Totem earlier.
* `sha-train-14` stands after `h15-razor-hill` for all races (Swart, ~190 yd): the Skyborne at 15.6 might rather train
  14 + 16 at `h18-tb-zamah`; kept for one simple insert.
