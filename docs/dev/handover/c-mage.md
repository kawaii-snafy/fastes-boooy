# Hand-over C2: mage (`Classes/Mage.lua`)

Phase C of `docs/dev/PLAN.md` (D.5, row Mage), agent "mage", FAST MODE: targeted checks only, no `make check`, no
`make routedata` / `report`. No git command that changes state was run. `G` = `addons/FastesBoooy_Guides`.

## 1. What changed

| File | Change |
|---|---|
| `G/Classes/Mage.lua` | written (was a placeholder): 30 inserts, 37 steps (5 optional), all `class = "MAGE"`, ids `mag-...`; header with every visit, anchor and validator level, what is skipped and why |
| `docs/routes/class-mage.md` | new (Russian; shape of `class-paladin.md` / `class-warlock.md`): overview with grind per race, trainers, training tables 1-22 / 22-60, every insert with anchor and level, talents, class quests, weapons, decisions, uncertainties |
| `docs/dev/handover/c-mage.md` | this file |

`tools/overrides/mage.lua` was not created: no mask, XP or exclusivity correction is needed for what is routed.
Nothing else was touched (no segment, race file, other class file, spec, tool). Scratch files only under
`$SCRATCH/mag/`.

## 2. Acceptance: commands and results

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Classes/Mage.lua` | 0 warnings / 0 errors in 1 file, exit 0 |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --baseline docs/dev/handover/baseline.json --route "*-mage" --skip 'Classes/*' --keep "Classes/Mage.lua" --own "Classes/Mage.lua" $G` | **exit 0**: 0 error, 0 warning, 50 accepted (strict; all on shared steps, none in the mage file), 0 foreign; summary below |
| `lua5.1 tools/validate_routes.lua --route "<race>-mage" --levels <F> $G` (orc, troll, undead) | exit 0 x 3; levels of every own step: `docs/routes/class-mage.md` section 3 |
| `lua5.1 tools/simulate_routes.lua --route "<race>-mage" --skip 'Classes/*' --keep "Classes/Mage.lua" $G` (one at a time) | **OK x 3**, no other output line: orc 1,699 steps (698 accepted / turned in), troll 1,701 (698), undead 1,725 (706), level 60 each |
| `GUIDES_SKIP='Classes/*' GUIDES_KEEP="Classes/Mage.lua" GUIDES_OWN="Classes/Mage.lua" busted tests/spec/guides_layout_spec.lua` | 22 successes / 0 failures / 0 errors |

`--summary` (route, profile, errors, warnings, accepted, foreign, end level, worst, grind, worst):

```
orc-mage	Orc MAGE Horde	0	0	17	0	60.00	60.00	4978	6225	-	-
troll-mage	Troll MAGE Horde	0	0	17	0	60.00	60.00	4978	6225	-	-
undead-mage	Scourge MAGE Horde	0	0	16	0	60.00	60.00	4973	6208	-	-
```

Against the base route of the race (`--skip 'Classes/*'`, normal / worst, measured with the override files present at
the time: shared, hunter, rogue, shaman, warlock, warrior): Orc / Troll 4,979 / 6,226 -> 4,978 / 6,225; Undead
4,982 / 6,217 -> 4,973 / 6,208 (baseline file: Orc / Troll 4,980 / 6,227, Scourge 4,982 / 6,217). Grind up to the end
of `h-18` (`--grind-until h-18-stonetalon-ashenvale`, normal / worst): Orc / Troll 44 / 156 -> 43 / 155, Undead
47 / 147 -> 38 / 138: inside the `h-18` budget 120 / 200.

### Kills per segment, base -> mage (normal run; segments not listed are equal within 1)

| Segment | Orc / Troll | Undead |
|---|---|---|
| start zone | `dur-02` 8 -> 7 | `ud-01` 3 -> 2, `ud-02` 1 -> 0 |
| `h-13-silverpine` | 0 -> 0 | 19 -> 12 |

No segment-level or level-grind ceiling moved into a warning.

## 3. Foreign warnings

None (`foreign` = 0 for all three routes with `--own Classes/Mage.lua`).

## 4. Ids added

All in `Classes/Mage.lua` (prefix `mag-`):
`mag-dur-letter-orc`, `mag-dur-maiah-orc`, `mag-dur-letter-troll`, `mag-dur-maiah-troll`, `mag-dur-train-4`,
`mag-dur-train-8`, `mag-train-10`, `mag-train-12`; `mag-tir-letter`, `mag-tir-isabella`, `mag-tir-train-4`,
`mag-tir-train-6`, `mag-tir-train-8`, `mag-tir-train-10`, `mag-tir-uc-go`, `mag-tir-anastasia`, `mag-tir-uc-exit`,
`mag-tir-snapdragons`, `mag-tir-train-12`; `mag-train-14`, `mag-train-18`, `mag-train-20`, `mag-train-22`,
`mag-train-24`, `mag-train-26`, `mag-train-30`, `mag-train-34`, `mag-train-36`, `mag-train-40`, `mag-train-44`,
`mag-train-48`, `mag-research`, `mag-train-52`, `mag-train-54`, `mag-train-56`, `mag-60-hearth`, `mag-train-60`.

Anchors used (all explicit ids, all unfiltered; inserts on start-zone anchors carry the race scope of the zone, the two
`h12-*` inserts carry Orc / Troll for clarity): `dur01-teeth` (two inserts, Orc / Troll), `dur01-den-4`, `dur02-xarti`,
`h12-fp-org`, `h12-fp-uc`, `ud01-364`, `ud01-arren-4`, `ud02-sethearth`, `ud02-brill-8`, `ud02-terrence`,
`ud02-balnir`, `ud02-fp-uc`, `h15-org`, `h18-tb-zamah`, `h18-sethearth-tb`, `h-22-tb-start`, `h-24-tb-arrive`,
`h-27-tb-arrive`, `h-31-org`, `h-34-uc-arrive`, `h-37-orgrimmar`, `h-40-org-arrive`, `h-44-uc-arrive`,
`h-50-org-arrive`, `h50-owen-thadd`, `h52-uc-81954`, `h56-sethearth-org`, `h-58-org-arrive`, `h-60-end`.

Notes on the C.2 draft: the Durotar mage trainer visits are `dur01-den-4` (4) and `dur02-xarti` (Sen'jin, 6 + 8 at
8.17; `dur02-senjin-1` is at 5.4 and `dur02-senjin-3` at 9.3, where 8 is already trained and 10 not reached); the
Undead level-4 training stands after `ud01-arren-4` (4.01), because `ud01-church-4` is at 3.74 for a mage (no 1470 as
for the warlock). The level-10 Durotar visit moves to Orgrimmar (11.1): Sen'jin is behind the path by then and Razor
Hill has no mage trainer.

## 5. Anchor wishes

None: every visit found an explicit id at the right place.

## 6. XP values and mask corrections for quests I may not override

None: all routed quests are mage-only and appear in no other file. XP unknown (Forever-new, estimated by the validator):
98576 Glyphic Parchment (Orc letter), 97286 Research Access; record with `/fb xp` and put them into
`tools/overrides/mage.lua`. Mask: 1959 / 1960 / 1962 and 1943-1946 exclude the Orc in the DB (C.5); not routed for any
race, so no override was needed.

## 7. New place names for `PLACE_NAMES_RU`

None: the only `hearth` action names the Undercity, which the shared path already uses.

## 8. DB overrides added

None.

## 9. `-- CONFIRM` list (in the file)

* `mag-research`: 97286 has no objective (accept and turn in at once) and what it gives a mage.
* Header: the spell lists of the `train` steps beyond the key levels of classes.md 5.6 are the original game's.
* Russian NPC and place names in the notes (Май'а, Ун'Тува, Ксар'Ти, Горнек, Сарвис, Изабелла, Каин Огненная Песнь,
  Анастасия Хартвелл, Утел'най, Зама, Тёрстон Ксейн, Архимаг Шимм, Пирс Шеклтон, Оуэн Тадд; Аллея Духов, Пруды
  Видений, Вершина Духов, Квартал Магов, Логово, Руины Лордерона, лагерь Арьергарда) and quest names («Пергамент с
  глифами», «Табличка с глифами», «Свиток с глифами», «Поговорите с Анастасией», «Усадьба Бальнира», «Доступ к
  исследованиям») against the ruRU client.

## 10. Deviations from the plan

1. **No class reward table** (D.5, A.5.4): the snapshot has no reward lists; same decision as the warlock, paladin,
   hunter and rogue files.
2. **1959-1962 not routed** although classes.md 5.10 lists it under "ROUTE: XP at no or little detour": the research
   assumed full XP, but the path reaches the Undercity at 15+ only at 22.7, where the quests are 6-16 levels below the
   player (DB.QuestXp: 1960 925, 1961 160 at 24, 1962 110 at 31; 1959 65). 1960 needs the Rift Spawns in the
   Apothecarium (the far side of the city from the Magic Quarter) and 1961 10 Linen Cloth + 6 Dalaran Mana Gems:
   ~1,260 XP for 6+ minutes. The Orc could not take it anyway (DB masks).
3. **1881 > 1882 routed for the Undead only, and mandatory** (~3 min for 925 XP + a caster item at 10-12, C.4 limit
   "about 3 minutes"): the Undercity is fetched from Brill at 10.16 before the path turns east (the farm is on the path
   at 10.97, the turn-in is merged with the level-12 training at Anastasia, a mage trainer). The Troll passes Brill and
   the Undercity at 12 in the wrong order for it.
4. **8250 Magecraft not routed** (a "ROUTE the delivery" in classes.md 5.6): 510 XP at 53 (~1.7 kills) for ~700 yd to
   Sanath Lim-yo and back from Xylem's tower; the follow-ups are index-only and end in the Sunken Temple.
5. **97286 Research Access routed optional** (classes.md: ROUTE, same NPC): grey at 49 and the reward is unknown, so it
   must not count in the worst case.
6. **No weapon-skill steps and no teleport steps** (D.5 "weapon skills where they matter"): staves are known, the wand
   needs no skill; the teleports are named in the note of `mag-train-22` as a spare way back.
7. **Two training visits optional** (12 for Orc / Troll in the Undercity, ~80 s; 20 at the Pools of Vision from the
   Thunder Bluff inn, ~90 s): both levels are trained at the next stop that is on the way (14 at 14.13, 22 at 22.04).

## 11. Facts for the atlas

### Mage trainers and services (DB; Horde-friendly)

| Place | Class trainer (id, uiMap, x, y) | Others |
|---|---|---|
| Valley of Trials, the Den | Mai'ah 5884 (1411, 42.51, 69.04), up to 6; letters 98576 (Orc) / 3086 (Troll) | |
| Sen'jin Village | Un'Thuwa 5880 (1411, 56.31, 75.11); 1884, 1959 | Razor Hill has none |
| Deathknell | Isabella 2124 (1420, 30.93, 66.06), up to 6; letter 3098 | |
| Brill, Gallows' End Tavern | Cain Firesong 2128 (1420, 61.97, 52.47); 1881, 1959 | |
| Orgrimmar, Valley of Spirits | Uthel'nay 7311 (39.16, 86.27), Pephredo 5882 (38.35, 85.56), Enyo 5883 (38.78, 85.67), Deino 5885 (38.45, 86.13); 1883, 1959, 8250 (Uthel'nay), 1944-1945, 1947, 1953 (Deino) | portal trainer Thuul 5958 (38.68, 85.41); wand merchant Katis 5816 (44.18, 48.44) |
| Thunder Bluff, Pools of Vision | Thurston Xane 3049 (25.18, 20.96), Archmage Shymm 3047 (22.76, 14.53), Ursyn Ghull 3048 (25.70, 14.19); 1883, 1959 (Xane), 8250 (Shymm), 1947, 1953 (Ghull) | portal trainer Birgitte Cranston 5957 (22.50, 16.91); Zamah (path quests) in the same cave |
| Undercity, Magic Quarter | Pierce Shackleton 4567 (85.45, 13.51), Kaelystia Hatebringer 4566 (85.02, 14.02), Anastasia Hartwell 4568 (85.14, 10.03); 1881 > 1882, 1959 > 1960 > 1961, 1943, 1947, 1953 (Anastasia), 8250 (Pierce) | portal trainer Lexington Mortaim 2492 (84.19, 15.58); wand vendor Zane Bradford 5754 (69.56, 26.94); librarian Owen Thadd 211022 (73.40, 33.00): 97286 |
| Zephras Isle | Dorii Brightwhisper 251379, Shenaan Spellwind 254086, Anathamaas Aetherwind 252373 (faction A only: no Horde Skyborne mage) | |
| hubs (Stonard, Grom'gol, Booty Bay, the Crossroads, ...) | none | |

### Class quests (DB) and verdicts (rewards are not in the DB)

| Quest | Race | Giver -> ender | XP (DB) | Verdict |
|---|---|---|---|---|
| 98576 / 3086 / 3098 Glyphic Parchment / Tablet / Scroll | Orc / Troll / Undead | Gornek 3143 / Sarvis 1569 -> Mai'ah / Isabella (pre 788 / 364) | ? / 40 / 40 | letter, routed |
| 1881 > 1882 The Balnir Farmstead | Undead / Troll (excl. 1884) | Cain Firesong -> Anastasia; Balnir Snapdragons 102985 (1420 77.4-77.6, 61.8-62.0) | 85 + 840 | routed (Undead), caster item |
| 1883 > 1884 Ju-Ju Heaps | 1883 all Horde, 1884 Orc / Undead / Troll (excl. 1882) | Uthel'nay / Thurston Xane -> Un'Thuwa; Ju-Ju Heap 102986 (1411 67.0, 87.8) | 85 + 840 | skipped (level 10, the path leaves Sen'jin at 9.3) |
| 1959 > 1960 > 1961 > 1962 | 1959 / 1960 / 1962 Undead / Troll, 1961 + Orc | trainers -> Anastasia; Containment Coffers (Undercity 52.0, 76.0; chest and Cantation next to Anastasia); 10 Linen Cloth + 6 Dalaran Mana Gems (Dalaran mobs, Silverpine) -> Josef Gregorian 4576 (Undercity 70.8, 30.7, tailors) | 105 + 1,150 + 800 + 1,050 (65 + 925 + 160 + 110 at the path's levels) | skipped (deviation 2), Spellfire Robes |
| 1943 > 1944 > 1945 > 1946 | Undead / Troll | Anastasia -> Deino; Xavian Waterfall 174797 (Ashenvale 76.3, 41.5); 12 Laughing Sister's Hair (Ashenvale 58, 58) -> Kil'hala 3484 (the Crossroads) | 210 + 2,100 + 1,600 + 2,100 | skipped (Orgrimmar - Ashenvale order) |
| 1947 > 1948-1952 (wand) | any | trainers -> Tabetha 6546 (Dustwallow 46.1, 57.1) | 285 + ? | skipped (index only, dungeon book) |
| 1953 > 1954 > 1955 > 1956 > 1957 / 1958 | any | trainers -> Tabetha; Infernal Orb (Burning Blade Summoners, Desolace); Demon of the Orb (L40 elite); Uldaman | 315 + 2,350 + 2,350 + 3,900 + ? | skipped |
| 97286 Research Access (Forever-new) | any, class MAGE | Owen Thadd 211022 (pre-any of 40 library book quests) | ? | routed optional |
| 8250 Magecraft > 8251-8253 | any | Uthel'nay / Pierce / Shymm -> Sanath Lim-yo 8395 (Azshara 28.1, 50.1) | 510 + ? | skipped (deviation 4) |
| 7500 The Arcanist's Cookbook | any | Dire Maul | | skipped |

### Weapon masters for a mage

Staves known from level 1; daggers (Sayoc 11868, Orgrimmar 81.70, 19.55; Archibald 11870, Undercity 57.31, 32.77) and
one-handed swords (Archibald) are learnable; not routed.

## 12. Open issues for the orchestrator

None blocking.

## Minor, for phase R

* `docs/routes/class-mage.md` numbers are a snapshot of phase C (overrides of six classes present at the time).
* The `--levels` worst-case column of an optional step shows the level of the worst run at that point (cosmetic, as in
  every class file).
* Russian names (section 9) need the ruRU client.
* The talent table of `class-mage.md` section 4 is the original game's; Forever may differ.
