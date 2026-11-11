# Hand-over C: warrior (phase C, agent "warrior")

Phase C of `docs/dev/PLAN.md` (D.5, row Warrior; C.1-C.5). FAST MODE: targeted checks of the five warrior routes only;
`make check` is the orchestrator's closing step. No git command that changes state was run. `G` =
`addons/FastesBoooy_Guides`.

## 1. What changed

| File | Change |
|---|---|
| `G/Classes/Warrior.lua` | written (was a placeholder): 48 inserts, 86 steps (9 optional), ids `war-dur-*`, `war-mul-*`, `war-tir-*`, `war-zep-*`, `war-*`; header with every visit, anchor and level; 6 `-- CONFIRM` comments |
| `tools/overrides/warrior.lua` | new, empty (`quests = {}`): no DB correction needed; it exists so that the D.5 luacheck command runs as written |
| `docs/routes/class-warrior.md` | new (Russian): overview, training tables, every insert with anchor and level, class quests, talents, weapons, decisions, what to confirm |
| `docs/dev/handover/c-warrior.md` | this file |

No segment, race file, other class file, tool or spec was touched. No `ok` key was needed in the class file (0 own
warnings).

## 2. Acceptance: commands and results

`C=Warrior`, `c=warrior`, `<F>` = `--skip 'Classes/*' --keep "Classes/Warrior.lua" --own "Classes/Warrior.lua"`.

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Classes/Warrior.lua tools/overrides/warrior.lua` | 0 warnings / 0 errors in 2 files |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --baseline docs/dev/handover/baseline.json --route "*-warrior" <F> $G` | **exit 0**: 1 module, 0 error, 0 warning, 84 accepted (strict); every route 60.00 / 60.00; summary below. Also with `--max-grind-until h-18-stonetalon-ashenvale=120/200` (the `VALIDATE_FLAGS` budget): exit 0 |
| `lua5.1 tools/validate_routes.lua --route "<race>-warrior" --levels <F> $G` (five races) | exit 0 each; levels in section 4 and in `docs/routes/class-warrior.md` §3 |
| `lua5.1 tools/simulate_routes.lua --route "<race>-warrior" --skip 'Classes/*' --keep "Classes/Warrior.lua" $G` (one at a time, ~26 s each) | **OK x 5**, level 60: orc 1,720 steps, troll 1,722, tauren 1,725, undead 1,748, skyborne 1,763; no "would not be offered" warning of a warrior step. Skyborne: the two known base warnings only (`sd02-hearth` bind point, optional `sky-1061` at 12; P2 hand-over section 2). "cold start resumes at step N-1/N": the last two steps are the optional hearth + training after `h-60-end` (transient, as the paladin's final visit) |
| `GUIDES_SKIP='Classes/*' GUIDES_KEEP="Classes/Warrior.lua" GUIDES_OWN="Classes/Warrior.lua" busted tests/spec/guides_layout_spec.lua` | 22 successes / 0 failures / 0 errors |

`--summary` (route, profile, errors, warnings, accepted, foreign, end, worst, grind, worst, grind to the end of `h-18`, worst):

```
orc-warrior	Orc WARRIOR Horde	0	0	16	0	60.00	60.00	4915	6160	31	140
troll-warrior	Troll WARRIOR Horde	0	0	16	0	60.00	60.00	4915	6160	31	140
tauren-warrior	Tauren WARRIOR Horde	0	0	18	0	60.00	60.00	4906	6133	22	113
undead-warrior	Scourge WARRIOR Horde	0	0	16	0	60.00	60.00	4905	6149	21	129
skyborne-warrior	Skyborne WARRIOR Horde	0	0	18	0	60.00	60.00	4862	6075	0	55
```

Against the baseline (P2, base profile normal / worst): Orc and Troll 4,979 / 6,226 -> 4,915 / 6,160; Tauren 4,965 / 6,197
-> 4,906 / 6,133; Scourge 4,982 / 6,217 -> 4,905 / 6,149; Skyborne 4,914 / 6,129 -> 4,862 / 6,075. Up to the end of
`h-18`: Orc 44 / 156 -> 31 / 140, Tauren 30 / 127 -> 22 / 113, Undead 47 / 147 -> 21 / 129, Skyborne 0 / 59 -> 0 / 55.

Accepted count: Orc / Troll 17 -> 16 because the `level-grind` of `h18-lvl-22` falls to 24 kills in the warrior routes
(INFO instead of an accepted WARN); its `ok` is still used by the other 23 routes (not an `ok-unused`).

## 3. Grind kills per segment (normal / worst)

| Segment | Orc / Troll | Tauren | Undead | Skyborne |
|---|---|---|---|---|
| start zone 1 | `dur-01` 0 / 0 | `mul-01` 1 / 1 | `ud-01` 2 / 2 | `sd-01` 0 / 0 |
| start zone 2 | `dur-02` 7 / 7 | `mul-02` 0 / 0 | `ud-02` 0 / 0 | `sd-02` 0 / 0 |
| start zone 3 | - | `mul-03` 0 / 0 | - | `sd-03` 0 / 0 |
| `h-12` | 0 / 0 | 0 / 0 | - | 0 / 0 |
| `h-13` | 0 / 0 | 0 / 0 | 0 / 16 | 0 / 0 |
| `h-15` | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| `h-18` | 24 / 133 | 21 / 112 | 19 / 111 | 0 / 55 |
| `h-22` | 0 / 51 | 0 / 51 | 0 / 51 | 0 / 52 |
| `h-24` | 0 / 206 | 0 / 206 | 0 / 206 | 0 / 206 |
| `h-27` | 109 / 313 | 108 / 313 | 108 / 313 | 87 / 313 |
| `h-31` | 258 / 312 | 259 / 312 | 259 / 312 | 258 / 311 |
| `h-34` | 152 / 152 | 152 / 151 | 152 / 152 | 152 / 152 |
| `h-37` | 1,008 / 1,028 | 1,008 / 1,029 | 1,008 / 1,029 | 1,008 / 1,029 |
| `h-41` | 765 / 919 | 765 / 919 | 765 / 918 | 765 / 918 |
| `h-44` | 178 / 184 | 177 / 184 | 177 / 185 | 178 / 185 |
| `h-46` | 617 / 715 | 617 / 715 | 618 / 714 | 617 / 715 |
| `h-50` | 148 / 301 | 148 / 301 | 147 / 301 | 148 / 300 |
| `h-53` | 345 / 378 | 346 / 378 | 346 / 378 | 345 / 378 |
| `h-56` | 1,304 / 1,461 | 1,304 / 1,461 | 1,304 / 1,461 | 1,304 / 1,461 |
| route | **4,915 / 6,160** | **4,906 / 6,133** | **4,905 / 6,149** | **4,862 / 6,075** |

## 4. What the file does (summary; full tables in `docs/routes/class-warrior.md`)

* Letters: 2383 (Orc), 3065 (Troll) at `dur01-teeth`; 3091 at `mul01-hunt`; 3095 at `ud01-364`; 92532 at `sd01-rorian`
  (with `use = 282419`, the druid's pattern for the Skyborne letters).
* Start-zone training at 1, 4, 6, 8, 10, 12 (Durotar 8 + 10 together at `dur02-rh-3`: Razor Hill-2 is at 7.73).
* Defensive Stance: Orc / Troll 1505 at `dur02-rh-3`, Uzzek detour after `dur02-crocs`, scales after
  `dur02-thunder-ridge`, turn-in at `h15-far-watch`; Tauren 1505 at `mul02-bh-4`, 1498 + scales after `mul03-far-watch`;
  Undead 1818 > 1819 > 1820 (mandatory) > 1821 > 1822 (optional) after `ud02-level-10`; Skyborne 94003 (Seena, Zaal at
  `sd02-parts-gyrozephyr`, turn-in after `sd02-nyalah-2`).
* 1502 > 1503 after `h15-far-watch` (all but Skyborne); 1823 at `h18-sethearth-tb`, 1824 after `h-24-camp-taurajo`
  (antennae as a bg goal), 1825 before `h-25-fly-ratchet` / turned in before `h-25-the-crossroads-flight` (optional);
  1718 at `h30-tb-1131`, Fray Island before `h-31-org`; 8423 after `h-51-swamp-of-sorrows-3`, turn-in after
  `h-53-blastedlands-end`.
* Shared-path training: 12 `h12-fp-uc` (Orc, Troll, Tauren), 14 `h13-uc-end`, 18 `h18-tb-1`, 20 `h18-sethearth-tb`,
  22 + 24 `h-24-tb-hearth`, 26 + 28 `h-28-hearth-tb`, 30 `h30-tb-1131`, 32 + 34 `h-34-uc-arrive`, 36 `h-37-org-arrive`,
  38 + 40 `h-40-org-arrive`, 42 + 44 `h-44-stonard-arrive`, 46 + 48 `h49-org-2976`, 50 `h51-stonard-2622`, 52
  `h53-org-3507`, 54 + 56 `h-58-uc-arrive`, 58 + 60 after `h-60-end` (optional, hearth to the Undercity).
* Weapon skills (optional, `manual`): Two-Handed Maces at Ansekhwa after `h-24-tb-hearth` (893 Demolition Hammer),
  Two-Handed Axes at Hanashi after `h-40-org-arrive` (1427 Chopper, 4301 Beastslayer).

## 5. Deviations from the plan

1. **Defensive Stance of Orc / Troll at 10.8 instead of the C.2 default (chain from `h15-far-watch`).** C.2 allows it
   if the Thunder Ridge > Uzzek > Thunder Ridge detour is under three minutes. Measured on the real hub order: the
   crocolisks of 816 (`dur02-crocs`, 35.7, 25.6) are at the river opposite Far Watch Post; crocs > Uzzek 763 yd, Uzzek >
   Thunder Ridge 868 yd, against 282 yd straight: +1,349 yd (~3.2 min at 7 yd/s), and the Singed Scales drop from the
   lizards the shared step `dur02-thunder-ridge` kills anyway. The default costs Uzzek > Thunder Ridge > back (1,736 yd)
   plus dedicated kills at 14. World coordinates: map percent with the Classic WorldMapArea rectangles of Durotar and
   the Barrens (their sizes equal the DB `zones[].size`). The turn-in stays at `h15-far-watch`.
2. **The Whirlwind weapon chain (classes.md 5.10 "ROUTE") is not routed.** C.4 names only the stances at 10 and 30 as
   the warrior's key abilities. The chain needs 8 Liferoot (herb: Herbalism, or one of five vendors), 30 Bloodscalp
   Tusks, 8 + 8 + 8 charms of Drywhisker kobolds through 1714 Essence of the Exile (a `special = 1` child quest of
   Bath'rah's cauldron: classes.md section 1 says never route those), an elite level-40 summon (Cyclonian) and two
   detours to Bath'rah in the Alterac Mountains (31 and 41). 8.8k XP and the weapon, but in fast mode the drop counts
   and the cauldron quest are unknowable here. Candidate for phase R / the atlas: the path kills Drywhisker kobolds
   (`h-31-hillsbrad-arathi:58`) and Bloodscalps (`h-34-stranglethorn:22`, `:32`, `:49`) anyway, so the charms and tusks
   would be bg goals; the open points are 1714 and Liferoot. Instead the file recommends Two-Handed Axes at 40.
3. **1825 turn-in is optional and stands after the Crossroads turn-ins** (anchor wish 1 below).
4. **No class reward table** (C.1 shows one, A.5.4): the DB has no reward lists, so no index is known; the notes name the
   item to take. As for the paladin.
5. **Talents in `docs/routes/class-warrior.md` §4 are the Classic two-handed Arms skeleton**, marked as unverified for
   Forever (no talent data in the snapshot or in the research files for the warrior).
6. **Spell lists of the `train` steps**: the key spells per level are those of `classes.md` 5.1 (Warcraft Tavern for
   Forever); the other ranks are the Classic progression. They are display only (`spells`).

## 6. Foreign warnings, anchor wishes, XP, overrides, place names

* Foreign warnings: none (column "foreign" = 0 on all five routes).
* **Anchor wishes** (phase R adds the id and moves the insert):
  1. `h-24-barrens-stonetalon:44` (complete 97003, Chol'aruk's hill at 58.0, 26.8) should be an anchor: the 1825 turn-in
     at Thun'grim Firegaze (57.23, 30.34, ~300 yd south-west) belongs right after it; then `war-1825` can be mandatory
     (780 XP for ~1 minute). Today it stands before `h-25-the-crossroads-flight` (optional, ~1,200 yd round trip).
* Ids added to shared files: none.
* XP values for shared quests: none. Unknown XP of warrior quests (estimated by the validator): 92532, 94003, 1498.
* DB overrides: none (`tools/overrides/warrior.lua` is empty).
* Place names for `PLACE_NAMES_RU`: none new (the file's `fly` / `hearth` places are Ratchet and Undercity).
* `-- CONFIRM` in `Classes/Warrior.lua`: the river crossing at `war-dur-uzzek`; the mausoleum trigger for Ulag
  (`war-tir-ulag`, object index 706178 is outside the snapshot); 94003 teaches Defensive Stance (`war-zep-94003-turnin`);
  8423 offered without 8417 (`war-8423`); the 1719 event and Intercept (`war-30-affray`); the reward lists of 1503 /
  1822 (`war-1503`).

## 7. Facts for the atlas

**Warrior trainers (DB, Horde-friendly):** Valley of Trials Frang 3153 (1411 42.89, 69.44; <= 6); Razor Hill Tarshaw
Jaggedscar 3169 (1411 54.19, 42.47); Camp Narache Harutt Thunderhorn 3059 (1412 43.75, 76.72; <= 6); Bloodhoof Krang
Stonehoof 3063 (1412 48.35, 63.74; also gives 99108 Sparring Match); Deathknell Dannal Stern 2119 (1420 32.69, 65.56;
<= 6); Brill Austil de Mon 2131 (1420 61.85, 52.54, in the inn; gives 1818); Thendal Blademaster Ren 251964 (2521 43.65,
24.11; <= 6); Shen'dar Corsan Earthrazer 254088 (2521 44.95, 45.10); Valanaar Seena Skybreaker 252377 (2521 59.89,
72.87; gives 94003); Orgrimmar, Valley of Honor: Grezz Ragefist 3353 (79.79, 31.42), Sorek 3354 (80.39, 32.38; gives
1505, 1823, 1718, 8417), Zel'mak 3408 (80.38, 29.50); Thunder Bluff, Hunter Rise: Torm Ragetotem 3041 (57.24, 87.37;
gives 1505, 1823, 1718, 8417), Sark Ragetotem 3042 (56.99, 89.51), Ker Ragetotem 3043 (57.58, 85.50); Undercity, War
Quarter: Christoph Walker 4593 (46.93, 15.23; gives 8417), Angela Curthas 4594 (48.32, 15.96), Baltus Fowler 4595
(47.40, 17.29; gives 1818, 1823, 1718); Stonard Malosh 985 (1435 44.89, 57.62). Weapon masters: Hanashi 2704 and Sayoc
11868 (Orgrimmar), Ansekhwa 11869 (Thunder Bluff), Archibald 11870 (Undercity).

**Class quests (DB) and what they give:**

| Quests | Level | Giver > turn-in | XP (DB) | Reward | Routed |
|---|---|---|---|---|---|
| 2383 / 3065 / 3091 / 3095 / 92532 | 1-2 | Gornek / Grull / Sarvis / Rorian > start-camp trainer | 40 (92532 unknown) | first training | yes |
| 1505 > 1498 | 10 | trainers > Uzzek 5810 (1413 61.38, 21.12); 5 Singed Scales (Thunder Lizard 3130, Lightning Hide 3131) | 85 + unknown | Defensive Stance | Orc, Troll, Tauren |
| 1818 > 1819 > 1820 > 1821 > 1822 | 10-11 | Austil / Baltus > Dillinger 1496 > Ulag 6390 > Coleman 1500; racks 105169-105172 | 85 + 840 + 210 + 660 + 880 | Defensive Stance (1819), weapon (1822) | Undead (1821-1822 optional) |
| 94003 | 10 | Seena > Zaal Stormshield 257196 (2521 56.63, 50.37) | unknown | Defensive Stance (W) | Skyborne |
| 1502 > 1503 | 10 | Uzzek > Thun'grim Firegaze 5878 (1413 57.23, 30.34); Stolen Iron Chest 58369 (55.05, 26.65) | 210 + 840 | weapon | all but Skyborne |
| 1823 > 1824 > 1825 | 20 | trainers > Ruga Ragetotem 6394 (1413 44.67, 59.42), 5 Twitching Antennae (silithids, Field of Giants) > Thun'grim | 155 + 1,550 + 780 | leads to Brutal Armor | yes (1825 optional) |
| 1838 ... 1848 | 20-30 | Thun'grim, Ula'elek, Orm Stonehoof, Velora Nitely | 3,650 + ... | Brutal mail set | no (Razorfen Kraul drop) |
| 1718 > 1719 | 30 | trainers > Klannoc Macleod 6236 (1413 68.62, 49.16), Big Will 6238 (L33) | 610 + 2,450 | Berserker Stance, Intercept (W) | yes |
| 1791 > 1712 (+1714) > 1713 > 1792 | 30-40 | Klannoc > Bath'rah the Windwatcher 6176 (1416 80.50, 66.92); Cyclonian 6239 (L40) | 245 + 2,350 + 2,350 + 3,900 | Whirlwind Axe / Sword / Warhammer | no (deviation 2) |
| 8417 > 8423 > 8424 > 8425 | 50-52 | trainers > Fallen Hero of the Horde 7572 (1435 34.29, 66.14); Helboar 5993 x7 | 470 + 5,100 + 5,100 + 6,350 | class item (8425) | 8423 only |
| 8920, 8944, 9013, 9022 | 58+ | | | Mokvar set chain | no |

## 8. Minor, for phase R

* The Russian NPC names in the notes are a mix of client names where they are well known (Таршо Зубчатый Шрам, Грезз
  Яростный Кулак, Уззек, Тун'грим Огнегляд, Руга Рваный Тотем, Кланнок Маклауд, Малош) and Latin names (Frang, Harutt
  Thunderhorn, Krang Stonehoof, Dannal Stern, Austil de Mon, Christoph Walker, Torm Ragetotem, the Skyborne NPCs):
  check against the ruRU client.
* `docs/routes/class-warrior.md` §4 talents: replace by the Forever tree once someone reads it in game.
* The train step at Torm after `h18-tb-1` makes the player walk Spirit Rise > Hunter Rise > Tal (~1.3 min); if the 16
  / 18 ranks prove unimportant, the visit can be merged into 20 (`h18-sethearth-tb`).
* The optional final visit after `h-60-end` (hearth + train) leaves the cold start "resuming at step N-1/N" (two
  transient steps at the end); harmless, but phase R may drop it if that line should read "finished".
