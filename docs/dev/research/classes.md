# Class research for the "FastesBoooy_Guides" redesign: class quests, trainers, training stops, services

Scope: CLASS content for all nine Horde classes (WARRIOR, HUNTER, ROGUE, SHAMAN, WARLOCK, MAGE, PRIEST, DRUID,
PALADIN), levels 1-60, for the 28 race + class routes. Read-only research; nothing in the repository was changed
except this file.

Sources and how to read the confidence marks:

* **DB** = `tools/data/forever_db.lua` (snapshot 2026-11-07, client 1.60.1.70862), read with lua5.1 scratch
  scripts (Appendix C). Everything with an id, a coordinate, an XP value or a status comes from it.
* **route** = the two existing routes, traced step by step through the real validator (level before every step;
  Appendix C). Levels of 22-60 anchors are the harness numbers of `docs/dev/research/routes.md` 6.6 (no class
  inserts) cross-checked against my trace of `horde-undead-paladin` (with its inserts: up to +0.2).
* **C** = Classic-era knowledge (what a quest rewards, what a weapon master teaches). The DB has no reward or
  spell data, so every "rewards X" in this report is C unless marked W. Treat C as "likely", not "verified".
* **W** = web check of November 2026 (section 7, URLs there). Fan guides, several written during the beta.

Sibling reports: `routes.md` (existing routes, anchors, 22-60 city stops), `startzones.md` (Durotar / Mulgore
quests and the level 1-12 class quests of Orc / Troll / Tauren with full tables, section 3), `core.md`,
`tools.md`. This report does not repeat their tables where they are complete; it is the class-centric 1-60 view.

Conventions: coordinates are `uiMapID x, y` in map percent as in the DB (1411 Durotar, 1412 Mulgore, 1413 The
Barrens, 1420 Tirisfal Glades, 1421 Silverpine Forest, 1424 Hillsbrad Foothills, 1416 Alterac Mountains, 1454
Orgrimmar, 1456 Thunder Bluff, 1458 Undercity, 2521 Zephras Isle, 1450 Moonglade, 1434 Stranglethorn Vale, 1435
Swamp of Sorrows, 1441 Thousand Needles, 1445 Dustwallow Marsh, 1447 Azshara, 1448 Felwood). "all Horde" = race
mask with Orc, Undead, Tauren, Troll and Horde Skyborne; "any" = mask 0. XP is the DB value (`xpSrc` in the
appendix tables; "unknown" = no XP in the DB, the validator estimates it).

---------------------------------------------------------------------------------------------------------------

## 0. Summary and what contradicts the decisions

### 0.1 The facts that matter most for the design

1. **The 28 combos are confirmed by the DB.** Each has its own level-1 "letter" quest (section 2). Zephras Isle
   has mage trainers flagged `AH`, but there is no Horde Skyborne mage letter and the start-camp mage trainer is
   Alliance-only: no 29th combo.
2. **Trainer coverage of the shared 22-60 path is uneven** (section 4). Warrior, mage and priest can train at
   every city stop. Rogue and warlock have **no trainer between 22.06 (Orgrimmar / Undercity) and 31.05
   (Orgrimmar)**: all five city stops in between are Thunder Bluff. Hunter and shaman have none in the Undercity
   (stops at 31.2, 34, 41, 44, 49.5, 52.6, 57.2, 58 and the final hearth at 60) but get Stonard (44.0 and 51.8),
   hunter also Grom'gol (34-36, 44-45), shaman also Skywatcher Plateau (28.6). Rogue gets Booty Bay (34.1, 36.0,
   44.6-46.0). No class trainer exists in the Barrens, Stonetalon, Ashenvale, Hillsbrad (Horde), Arathi, Desolace,
   Dustwallow, Badlands, Thousand Needles, Tanaris, Hinterlands, Un'Goro, Silithus, Felwood, Winterspring or the
   Plaguelands.
3. **Key-ability class quests that must be routed** (the class is crippled or much slower without them):
   warrior Berserker Stance at 30 (Fray Island off Ratchet) and, with it, the Whirlwind weapon; hunter pet chain
   at 10; rogue Poisons at 20 (Venture Co. tower in the north Barrens, turned in in Orgrimmar); shaman Earth
   (4), Fire (10) totems, Water (20) and Air (30) by judgement; warlock Imp (1), Voidwalker (10), Felsteed (40,
   free mount, Ratchet); druid Bear Form (10) and Cat Form (20, Forever-new Moonglade chain); priest and mage
   have none that is essential. Details and XP per chain: section 5; one-page verdict table: 5.10.
4. **Cheap class XP exists next to the shared path** and the path still grinds about 5 200 kills (1.44 M XP,
   `docs/routes/horde-22-60.md`), so every 1 000 XP of class quest removes 3 to 7 kills. Best ratios: warrior
   1824 / 1825 at Camp Taurajo (25.2, 2 330 XP, zero detour); warlock Incubus chain (Undercity branch: Ambermill
   and Ratchet are on the path at 23.6 and 25.9) and the Orb of Orahil chain (14.6 k XP, Mannoroc Coven is the
   path's level gate at 37.8); warlock 8419 / 8421 in Felwood (8.9 k at 55); rogue 2479 / 2480 at Tarren Mill;
   mage 1959 - 1962 (Undercity + Ambermill, 3.1 k); undead warrior 1819 - 1822 around Brill (2.7 k at 10).
5. **Riding at 40 is not purely a race matter.** Warlocks of every race get a free Felsteed from a class quest
   (Ratchet), paladins get Summon Warhorse from the class trainer (W), druids have Travel Form at 30. A per-race
   riding insert therefore needs a class filter (not WARLOCK, not PALADIN), or the class files must be able to
   suppress it. Orc riding is inside Orgrimmar (zero detour at the 40.04 stop); Undead in Brill (2 min from the
   zeppelin tower, 41.0); **Troll in Sen'jin Village and Tauren in Bloodhoof Village: 7 to 10 minutes of detour
   each from the Orgrimmar stop at 40**; Skyborne on Zephras Isle (15-20 min by skycutter, as today).
6. **Weapon masters, riding instructors, pet / portal / demon trainers are not class trainers for the
   validator**: a `train` step on them is an ERROR (`train-wrong-trainer`: Weapon Master, Wolf / Kodo / Undead
   Horse Riding Instructor, Demon Trainer) or a WARN (`train-not-class-trainer`: Pet Trainer, Portal Trainer,
   Raptor Riding Trainer, Genn Fairweather). Today's inserts use `manual` for them. With 28 routes this pattern
   repeats in every class file: either keep `manual` as the convention or teach the validator a service kind.

### 0.2 What contradicts or complicates the decisions

1. **"Class steps valid for every race of that class" holds only with race filters and four sets of anchors.**
   Level-1 letters are one quest id per race + class (28 ids). The level-10 chains differ by race for warrior
   (3 variants), hunter (3), rogue (2, none for Skyborne), shaman (3 Earth, 2 Fire), warlock (2), mage (2
   alternatives), priest (2), druid (2). Each `Classes/<Class>.lua` therefore needs one insert group per start
   zone (Durotar, Mulgore, Tirisfal, Zephras) anchored on that zone's step ids, plus the shared-path group.
2. **One start-zone base step is class-dependent:** Durotar's 792 Vile Familiars excludes warlocks (class mask =
   all but WARLOCK); warlocks do 1485 -> 1499 instead and both lead to 794. The Durotar path agent must put a
   `classes` filter on a base step (startzones.md already plans it); "class-agnostic start zones" is not 100 %.
3. **The DB snapshot was scoped for paladin and druid.** `tools/build_db_snapshot.py` has `SCOPE_CLASSES =
   ("PALADIN", "DRUID")` and lists the seven other class sorts in `EXCLUDED_SORTS`. Their class quests are in
   the full tables only when a giver / turn-in spawns in a core 1-22 zone or within 3 links of such a quest
   (most are); the rest is `questIndex` only (name, levels, masks): mage wand chain 1948 - 1952 and 1957 / 1958 /
   8251 - 8253, warlock 4785 and 7601 - 7603, the Forever-new shaman chain 79358 - 79442 and the Skyborne Call
   of Air 96136, the Forever-new rogue chain 96779 - 96786. Routing them gives WARN `quest-out-of-scope` and no
   NPC / objective checks. **The snapshot cannot be regenerated in this checkout** (the research JSON inputs of
   `make db` are not in the repository), so "extend the scope to nine classes" is not an option for the
   implementation agents unless the user supplies the inputs.
4. **Some DB race masks look stale for the new Forever combos**, and the validator reports a race mismatch as
   an ERROR (`quest-race`): Troll warlock Voidwalker (1501 / 1504 are Orc-only in the DB; W says "Orc / Troll");
   Orc mage 1959 / 1960 / 1962 and 1943 - 1946 (Undead / Troll only; 1884 and 1961 already include Orc);
   Skyborne druid Cure Poison and Aquatic Form (6126 - 6130, 27 - 31 Tauren-only; W lists them for Skyborne).
   Without a snapshot supplement those steps cannot be routed for the affected race without failing validation.
   The existing druid route already works around this by a note instead of steps.
5. **Paladin trainers: web vs DB.** The DB (and today's paladin inserts) use Alodan the Hopeful 246344 in
   Thunder Bluff and Garen Largo 260093 in the Undercity (both `Paladin Trainer`, faction H, several spawn points
   = they walk). The Warcraft Tavern trainer list (W) names only Deathknell, Brill and Bandarion Keep and states
   Thunder Bluff and the Undercity have no paladin trainer. Unverified in game; if the guide is right the
   paladin's training stops move to Brill (next to every Undercity arrival by zeppelin).
6. **Thunder Bluff "rogue trainer".** The DB has Boarton Shadetotem 205729, sub-name `Rogue Trainer?` (with the
   question mark), trainer flag, Thunder Bluff 39.4, 65.8. W says Thunder Bluff has no rogue trainer. The
   validator would accept a rogue `train` step there (the sub-name contains "rogue trainer"). Do not use it.
7. **Start-camp trainers teach only up to level 6 (W).** Valley of Trials, Red Cloud Mesa, Deathknell and Thendal
   trainers are marked that way; from 8 on the second hub or a capital is needed. Razor Hill has no mage trainer
   (mage: Sen'jin Village or Orgrimmar); Sen'jin has only the mage trainer.

---------------------------------------------------------------------------------------------------------------

## 1. Data quality notes for the class agents

* Quest XP: `questie-classic` / `wclbox-classic` values are Classic numbers; `unknown` for every Forever-new
  class quest (all Skyborne class quests, the Cat Form chain, the Incubus chain, all paladin quests, the new
  Orc mage / Troll warlock letters) and for a few old ones (1498 Path of Defense, 2379, 3631 / 4489, the "no
  breadcrumb" variants 5652 / 5658 / 5679 / 5680, the Sapta quests). The validator estimates unknown XP by the
  median of the quest level and flags `xp-unknown` (WARN): a class file full of new quests needs the
  `-- WARN-OK: xp-unknown` convention.
* Objectives: item sources in the DB are drop / object / vendor lists without drop rates; `1858` Tazan's Logbook
  has no source at all (C: it is inside Tazan's Satchel loot / pickpocket at Northwatch). `30` Trial of the Sea
  Lion carries a broken objective (object id reused as item id).
* `special = 1` = repeatable (Sapta refills 1462 / 1463 / 1464 / 972 / 1103, 1714, 6701): never route.
* Exclusive groups are real mutual exclusions (breadcrumb variants, city branches). A class insert that offers
  breadcrumb A from hub X to races that may already hold breadcrumb B needs the same care as today's 1065.
* `quests[id].classes = 0` with a class sort happens (98341 / 98404 / 98738 Skyborne Cat Form, 98517 Skyborne
  Call of Fire, 96136): a class filter on the step is needed even though the quest has none.
* Validator behaviour that class files will meet: `quest-race` / `quest-class` ERROR for mask mismatches;
  `quest-out-of-scope` WARN for index-only quests; `train-wrong-trainer` ERROR / `train-not-class-trainer` WARN
  (0.1 item 6); `xp-unknown` WARN; `step-no-profile` WARN for a filtered step no profile of the route shows
  (tools.md covers the planned change).

---------------------------------------------------------------------------------------------------------------

## 2. Race x class matrix (cross-check of decision 3)

Level-1 class letter per combo (giver -> the class trainer of the start camp; prerequisite = the first kill
quest of the zone). 28 ids, all in the DB:

| Class | Orc (Gornek 3143, after 788) | Troll (Gornek, after 788) | Tauren (Grull Hawkwind 2980, after 747) | Undead (Shadow Priest Sarvis 1569, after 364) | Skyborne (Rorian the Dayseeker 251361, after 92461) |
|---|---|---|---|---|---|
| WARRIOR | 2383 -> Frang 3153 | 3065 -> Frang | 3091 -> Harutt Thunderhorn 3059 | 3095 -> Dannal Stern 2119 | 92532 -> Blademaster Ren 251964 |
| HUNTER | 3087 -> Jen'shan 3154 | 3082 -> Jen'shan | 3092 -> Lanka Farshot 3061 | - | 92482 -> Tai'ree Farsight 251376 |
| ROGUE | 3088 -> Rwag 3155 | 3083 -> Rwag | - | 3096 -> David Trias 2122 | 92483 -> Akeri Duskblade 251389 |
| SHAMAN | 3089 -> Shikrik 3157 | 3084 -> Shikrik | 3093 -> Meela Dawnstrider 3062 | - | 92484 -> Windshaper Boro 251374 |
| WARLOCK | 3090 -> Nartok 3156 | **98575** (new) -> Nartok | - | 3099 -> Maximillion 2126 | - |
| MAGE | **98576** (new) -> Mai'ah 5884 | 3086 -> Mai'ah | - | 3098 -> Isabella 2124 | - (Alliance only) |
| PRIEST | - | 3085 -> Ken'jai 3707 | - | 3097 -> Dark Cleric Duesten 2123 | - |
| DRUID | - | - | 3094 -> Gart Mistrunner 3060 | - | 92485 -> Xyton Silverwind 251373 |
| PALADIN | - | - | - | **98601** (new) -> Aramis Hammerhand 244808 | - |

6 + 7 + 4 + 6 + 5 = 28, exactly the combos of decision 3. Notes:

* 92484 (Skyborne shaman) has the race mask "all Horde" and 92482 / 92483 / 92485 / 92532 the mask "any": the
  giver exists only on Zephras, so only Skyborne see them; a `races = Skyborne` filter is still required on the
  insert step because the validator would otherwise show it to every race of the class.
* Zephras mage trainers: Dorii Brightwhisper 251379 (Thendal, faction A), Shenaan Spellwind 254086 and
  Anathamaas Aetherwind 252373 (faction AH). The Thendal shaman trainer Windshaper Boro is faction H. So the
  fifth class is mage for Alliance Skyborne and shaman for Horde Skyborne (W agrees).
* XP of the letters: 40 (Orc / Troll / Undead), 60 (Tauren hunter / shaman / druid; 40 warrior), unknown for the
  five Skyborne ones and the three new ones.

---------------------------------------------------------------------------------------------------------------

## 3. Class trainers for the Horde, by location

All NPCs with a class-trainer sub-name that are friendly to the Horde (faction H or AH) in the DB. Coordinates
are the first spawn; "(walks)" = several spawn points.

### 3.1 Start zones

| Place | Warrior | Hunter | Rogue | Shaman | Warlock | Mage | Priest | Druid | Paladin |
|---|---|---|---|---|---|---|---|---|---|
| Valley of Trials (1411), level <= 6 (W) | Frang 3153 (42.89, 69.44) | Jen'shan 3154 (42.84, 69.33) | Rwag 3155 (41.28, 68.00) | Shikrik 3157 (42.39, 69.00) | Nartok 3156 (40.65, 68.52) | Mai'ah 5884 (42.51, 69.04) | Ken'jai 3707 (42.36, 68.81) | - | - |
| Razor Hill (1411) | Tarshaw Jaggedscar 3169 (54.19, 42.47) | Thotar 3171 (51.85, 43.49) | Kaplak 3170 (51.98, 43.69) | Swart 3173 (54.42, 42.59) | Dhugru Gorelust 3172 (54.38, 41.20) | **none** | Tai'jin 3706 (54.26, 42.93) | - | - |
| Sen'jin Village (1411) | - | - | - | - | - | Un'Thuwa 5880 (56.31, 75.11) | - | - | - |
| Camp Narache / Red Cloud Mesa (1412), level <= 6 (W) | Harutt Thunderhorn 3059 (43.75, 76.72) | Lanka Farshot 3061 (43.96, 76.35) | - | Meela Dawnstrider 3062 (44.58, 76.56) | - | - | - | Gart Mistrunner 3060 (44.65, 76.55) | - |
| Bloodhoof Village (1412) | Krang Stonehoof 3063 (48.35, 63.74) | Yaw Sharpmane 3065 (46.93, 59.65) | - | Narm Skychaser 3066 (47.40, 62.54) | - | - | - | Gennia Runetotem 3064 (47.48, 62.95) | - |
| Skywatcher Plateau (1412, "Camp Gev'rek" in W) | - | - | - | Palah Thunderhoof 262558 (33.59, 22.40) | - | - | - | Hana Lighthoof 262560 (33.42, 22.13) | - |
| Deathknell (1420), level <= 6 (W) | Dannal Stern 2119 (32.69, 65.56) | - | David Trias 2122 (32.53, 65.65) | - | Maximillion 2126 (30.91, 66.34) | Isabella 2124 (30.93, 66.06) | Dark Cleric Duesten 2123 (31.11, 66.03) | - | Aramis Hammerhand 244808 (31.10, 66.41) |
| Brill (1420) | Austil de Mon 2131 (61.85, 52.54) | - | Marion Call 2130 (61.75, 52.00) | - | Rupert Boch 2127 (61.59, 52.40) | Cain Firesong 2128 (61.97, 52.47) | Dark Cleric Beryl 2129 (61.57, 52.19) | - | Shari Stilwell 246152 (60.22, 52.66) |
| Bandarion Keep (1420) | - | - | - | - | - | - | - | - | Hilda the Breaker 246389 (21.96, 47.25) |
| Thendal (2521), level <= 6 (W) | Blademaster Ren 251964 (43.65, 24.11) | Tai'ree Farsight 251376 (42.49, 23.79) | Akeri Duskblade 251389 (43.74, 24.36) | Windshaper Boro 251374 (42.79, 23.58) | - | (Alliance only) | - | Xyton Silverwind 251373 (41.66, 23.33) | - |
| Shen'dar (2521) | Corsan Earthrazer 254088 (44.95, 45.10) | Elayaa Easewind 254084 (45.26, 44.24) | Miriaan Mistblade 254087 (43.15, 43.26) | Aarnor Galestrike 254082 (43.45, 44.87) | - | (Shenaan Spellwind 254086) | - | Naeluna Swiftmend 254081 (45.16, 44.22) | - |
| Valanaar (2521) | Seena Skybreaker 252377 (59.89, 72.87) | Quel'ana Quickgale 252389 (59.56, 72.63) | Eltheen Nightbreeze 252379 (59.90, 72.48) | Sessaria Skystride 252382 (58.31, 78.51) | - | (Anathamaas Aetherwind 252373) | - | Lotheluum Starbreeze 252359 (63.99, 75.08) | - |

### 3.2 Capitals

| City | Warrior | Hunter | Rogue | Shaman | Warlock | Mage | Priest | Druid | Paladin |
|---|---|---|---|---|---|---|---|---|---|
| Orgrimmar (1454) | Valley of Honor: Grezz Ragefist 3353 (79.79, 31.42), Sorek 3354 (80.39, 32.38), Zel'mak 3408 (80.38, 29.50) | Valley of Honor: Ormak Grimshot 3352 (66.05, 18.53), Xor'juul 3406 (67.24, 20.20), Sian'dur 3407 (67.96, 17.80) | Cleft of Shadow: Gest 3327 (42.69, 51.48), Ormok 3328 (43.90, 54.63), Shenthul 3401 (43.05, 53.74) | Valley of Wisdom: Kardris Dreamseeker 3344 (38.80, 36.37), Sian'tsu 3403 (37.84, 36.45), Sagorne Creststrider 13417 (38.66, 35.92) | Cleft of Shadow: Grol'dar 3324 (47.98, 45.93), Mirket 3325 (48.62, 46.95), Zevrost 3326 (48.47, 45.43) | Valley of Spirits: Pephredo 5882 (38.35, 85.56), Enyo 5883 (38.78, 85.67), Deino 5885 (38.45, 86.13), Uthel'nay 7311 (39.16, 86.27) | Valley of Spirits: X'yera 6014 (36.01, 87.73), Ur'kyo 6018 (35.59, 87.82), Zayus 5994 "High Priest" (35.72, 86.90) | **none** | **none** |
| Thunder Bluff (1456) | Hunter Rise: Torm Ragetotem 3041 (57.24, 87.37), Sark 3042 (56.99, 89.51), Ker 3043 (57.58, 85.50) | Hunter Rise: Kary Thunderhorn 3038 (58.49, 88.33), Holt 3039 (57.30, 89.79), Urek 3040 (59.13, 86.87) | **none** (Boarton Shadetotem 205729 "Rogue Trainer?" 39.44, 65.82: do not use, 0.2 item 6) | Spirit Rise: Siln Skychaser 3030 (22.82, 21.11), Tigor 3031 (23.64, 18.79), Beram 3032 (21.99, 18.80) | **none** | Spirit Rise, Pools of Vision: Archmage Shymm 3047 (22.76, 14.53), Ursyn Ghull 3048 (25.70, 14.19), Thurston Xane 3049 (25.18, 20.96) | Spirit Rise: Miles Welsh 3044 (25.32, 15.27), Malakai Cross 3045 (24.56, 22.57), Father Cobb 3046 (25.64, 20.70) | Elder Rise: Turak Runetotem 3033 (76.48, 27.22), Sheal 3034 (77.14, 27.02), Kym Wildmane 3036 (77.15, 29.82) | Alodan the Hopeful 246344 (Pools of Vision, 22.13, 16.91, walks; W disputes, 0.2 item 5) |
| Undercity (1458) | War Quarter: Christoph Walker 4593 (46.93, 15.23), Angela Curthas 4594 (48.32, 15.96), Baltus Fowler 4595 (47.40, 17.29) | **none** | Rogues' Quarter: Carolyn Ward 4582 (83.86, 72.07), Miles Dexter 4583 (85.21, 71.57), Gregory Charles 4584 (84.88, 73.53) | **none** | Magic Quarter: Kaal Soulreaper 4563 (86.21, 15.93), Luther Pickman 4564 (86.43, 15.25), Richard Kerwin 4565 (88.91, 15.86) | Magic Quarter: Kaelystia Hatebringer 4566 (85.02, 14.02), Pierce Shackleton 4567 (85.45, 13.51), Anastasia Hartwell 4568 (85.14, 10.03) | War Quarter: Aelthalyste 4606 (49.26, 17.12), Father Lankester 4607 (49.14, 14.61), Father Lazarus 4608 (47.57, 18.90) | **none** | Garen Largo 260093 (War Quarter, 45.97, 19.79, walks; W disputes) |

Cities without a trainer for the class: **Orgrimmar**: druid, paladin. **Thunder Bluff**: rogue, warlock (and
paladin if W is right). **Undercity**: hunter, shaman, druid (and paladin if W is right).

### 3.3 Questing hubs and elsewhere

| Place | Trainers (id, coords) |
|---|---|
| Stonard, Swamp of Sorrows (1435) | warrior Malosh 985 (44.89, 57.62); hunter Ogromm 987 (47.26, 53.43); shaman Haromm 986 (48.19, 57.94); warlock Kartosh 988 (48.65, 55.64); pet trainer Grokor 3622 (47.35, 52.89); "Demon Master" Greshka 12807 (48.58, 55.27, vendor) |
| Grom'gol Base Camp, Stranglethorn (1434) | hunter Kragg 1404 (31.23, 28.68); pet trainer Zudd 3624 (31.11, 28.94) |
| Booty Bay (1434) | rogue Ian Strom 1411 (26.82, 77.15), faction AH |
| Ravenholdt Manor, Alterac Mountains (1416) | "Grand Master Rogue" Fahrad 6707 (84.45, 80.32), faction AH, trainer flag |
| Camp Mojache, Feralas (1444) | druid Jannos Lighthoof 8142 (75.99, 42.28) |
| Nighthaven, Moonglade (1450) | druid Loganaar 12042 (52.53, 40.57), faction AH |
| Kargath, Tarren Mill, Hammerfall, the Sepulcher, the Crossroads, Camp Taurajo, Ratchet, Sun Rock Retreat, Splintertree Post, Zoram'gar, Freewind Post, Shadowprey Village, Brackenwall, Gadgetzan, Revantusk Village, Everlook, Cenarion Hold, Light's Hope | **no class trainer** (checked: no Horde-friendly class trainer on these maps in the DB) |

---------------------------------------------------------------------------------------------------------------

## 4. Training stops on the shared path (22-60) for all nine classes

### 4.1 How the two existing insert files place training

Read from the headers and bodies of `addons/FastesBoooy_UndeadPaladin/Inserts.lua` and
`addons/FastesBoooy_SkyborneDruid/Inserts.lua` (full step tables: routes.md 7.1 / 7.2). Level = validator level
before the inserted step, normal / worst case as the headers give it.

| Class | Visit | Anchor (side) | Where | Level |
|---|---|---|---|---|
| Paladin | 26 | `h-27-tb-arrive` (after) | Alodan, Thunder Bluff Pools of Vision (the anchor's NPC stands in the same cave) | 27.58 / 27.12 |
| Paladin | 28 + 30 | `h-31-tb-hearth` (after) | Alodan | 30.91 |
| Paladin | 32 + 34 | `h-34-uc-arrive` (after) | Garen Largo, Undercity War Quarter | 34.10 |
| Paladin | 2H axes (optional, `manual`) | `h41-hearth-org` (after) | weapon master Hanashi, Orgrimmar | 41.0 |
| Paladin | 36-40 + riding + horse (+ optional Garen) | `h-41-uc-arrive` (after) | Shari Stilwell, Velma Warnam, Zachariah Post in Brill; Garen Largo | 40.88 / 40.75 |
| Paladin | 42 + 44 | `h-44-uc-arrive` (after) | Garen Largo | 44.02 |
| Paladin | 46-52 | `h53-fly-uc` (after) | Garen Largo | 52.57 |
| Paladin | 54 + 58 (optional) | `h59-hearth-uc` (after) | Garen Largo | 57.95 |
| Paladin | 58 + 60 | `h-60-end` (after) | hearth to Undercity, Garen Largo | 60 |
| Druid | bridge | `h-22-tb-start` (before) | Bunthen Plainswind flight Moonglade -> Thunder Bluff | 22.14 |
| Druid | 24 | `h-24-tb-arrive` (after) | Turak, Thunder Bluff Elder Rise | 24.95 / 24.05 |
| Druid | 26 + 28 | `h-28-thunder-bluff` (before) | Turak | 28.76 / 28.22 |
| Druid | 30 (Travel Form) | `h-31-tb-end` (after) | Turak | 31.01 |
| Druid | 32 | `h-33-tarrenmill-end` (after) | Teleport: Moonglade, hearth back to Tarren Mill | 32.07 / 31.86 |
| Druid | 34 + 36 | `h38-hearth-shadowprey` (before) | Teleport: Moonglade right before a library hearth | 37.69 |
| Druid | 38 + 40 (+ optional riding trip) | `h-40-org-arrive` (after) | fly Thunder Bluff, Turak; Zephras Isle by skycutter | 40.06 / 40.01 |
| Druid | 42 + 44 | `h44-hearth-gromgol` (before) | Moonglade before a library hearth | 44.52 |
| Druid | 46 + 48 | `h-50-mojache-end` (after) | Jannos Lighthoof, Camp Mojache | 49.40 |
| Druid | 50 + 52 (+ accept 9063) | `h54-hearth-org` (before) | Moonglade before a library hearth | 53.05 |
| Druid | 54 | `h56-hearth-gadgetzan` (before) | Moonglade before a library hearth | 55.04 |
| Druid | 56 | `h-58-org-arrive` (before) | Moonglade before a library hearth | 57.21 |
| Druid | 58 + 60 | `h-60-end` (after) | Moonglade | 60 |

Patterns worth copying: one `train` step `after` an arrival / hearth step the player has just done; merge two
training levels when a stop is just short of a level; make a visit `optional` when the worst-case level is below
the trained level; a final visit after `h-60-end`; never put a transient step in front of an accept at the same
NPC; do not spend the hearthstone unless the library leaves it free.

### 4.2 City and hub stops of the shared path, and which classes can train there

All anchors below exist as explicit ids in `addons/FastesBoooy_Horde/Segments` (checked by grep). Level = harness
value without class inserts (routes.md 6.6); my trace of the paladin route gives the same within 0.2. Columns:
W warrior, H hunter, R rogue, S shaman, Wl warlock, M mage, P priest, D druid, Pa paladin. `x` = a trainer of the
class stands in that city / hub; `(x)` = paladin trainer disputed by W.

| # | Anchor ids | Stop | Level | W | H | R | S | Wl | M | P | D | Pa |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `h-22-tb-start`, `h-22-tb-fly` | Thunder Bluff | 22.06 | x | x | | x | | x | x | x | (x) |
| 2 | `h-22-tb-fly-org`, `h-22-org-fp` | Orgrimmar | 22.06 | x | x | x | x | x | x | x | | |
| 3 | (anonymous Undercity steps; next id `h-22-uc-fly`) | Undercity | 22.06 | x | | x | | x | x | x | | (x) |
| 4 | `h-24-tb-hearth` (seg 1), `h-24-tb-arrive` (seg 2) | Thunder Bluff | 24.83 | x | x | | x | | x | x | x | (x) |
| 5 | `h-27-hearth-tb`, `h-27-tb-arrive` | Thunder Bluff | 27.31 | x | x | | x | | x | x | x | (x) |
| 6 | `h-28-hearth-tb`, `h-28-tb-arrive` | Thunder Bluff | 28.35 | x | x | | x | | x | x | x | (x) |
| 7 | `h-28-skywatcher` | Skywatcher Plateau, Mulgore | 28.4 - 28.7 | | | | x | | | | x | |
| 8 | `h-28-thunder-bluff` | Thunder Bluff | 28.75 | x | x | | x | | x | x | x | (x) |
| 9 | `h-31-tb-hearth`, `h-31-tb-end`, `h-31-tb-fly` | Thunder Bluff | 30.91 - 31.01 | x | x | | x | | x | x | x | (x) |
| 10 | `h-31-org` | Orgrimmar | 31.05 | x | x | x | x | x | x | x | | |
| 11 | `h-31-uc-arrive` | Undercity | 31.16 | x | | x | | x | x | x | | (x) |
| 12 | `h34-fly-uc`, `h-34-uc-arrive`, `h34-faranell` | Undercity | 34.05 - 34.10 | x | | x | | x | x | x | | (x) |
| 13 | `h-34-gromgol-arrive`, `h34-sethearth-gromgol` | Grom'gol | 34.11 | | x | | | | | | | |
| 14 | `h-34-booty-bay`, `h34-fp-bootybay` | Booty Bay | 34.11 | | | x | | | | | | |
| 15 | `h34-hearth-gromgol-2` ... `h36-gromgol-end` | Grom'gol | 34.9 - 35.9 | | x | | | | | | | |
| 16 | `h34-fly-bootybay`, `h-37-bootybay-end` | Booty Bay | 35.9 - 36.0 | | | x | | | | | | |
| 17 | `h-37-orgrimmar`, `h-37-org-arrive`, `h-37-orgrimmar-keldran` | Orgrimmar | 36.06 | x | x | x | x | x | x | x | | |
| 18 | `h40-fly-org`, `h40-sethearth-org`, `h-40-org-arrive` | Orgrimmar | 40.04 | x | x | x | x | x | x | x | | |
| 19 | `h41-hearth-org` | Orgrimmar (hearth) | 41.01 | x | x | x | x | x | x | x | | |
| 20 | `h-41-uc-arrive`, `h41-sharlindra` | Undercity (zeppelin lands at Brill's doorstep: all six Brill trainers) | 41.01 | x | | x | | x | x | x | | x |
| 21 | `h-44-uc-arrive` | Undercity | 44.02 | x | | x | | x | x | x | | (x) |
| 22 | `h-44-gromgol-arrive`, `h44-sethearth-gromgol` | Grom'gol | 44.02 | | x | | | | | | | |
| 23 | `h-44-stonard-arrive`, `h-45-stonard-end` | Stonard | 44.03 - 44.20 | x | x | | x | x | | | | |
| 24 | `h44-hearth-gromgol`, `h-45-gromgol`; `h45-gromgol-2` | Grom'gol | 44.5; 45.1 - 45.3 | | x | | | | | | | |
| 25 | `h44-fly-bootybay`, `h44-sethearth-bootybay`, `h-44-booty-bay`, `h45-bootybay-2`, `h46-bootybay-3` | Booty Bay | 44.6 - 46.0 | | | x | | | | | | |
| 26 | `h-48-mojache-arrive`; `h-50-mojache-end` | Camp Mojache | 47.19; 49.4 | | | | | | | | x | |
| 27 | `h50-fly-org`, `h-50-org-arrive` | Orgrimmar | 49.40 | x | x | x | x | x | x | x | | |
| 28 | `h-50-uc-arrive` | Undercity | 49.54 | x | | x | | x | x | x | | (x) |
| 29 | `h52-fly-stonard`, `h-51-stonard` (and an anonymous Stonard step at 52.5) | Stonard | 51.8 | x | x | | x | x | | | | |
| 30 | `h53-fly-uc` | Undercity | 52.57 | x | | x | | x | x | x | | (x) |
| 31 | `h-53-org-arrive`, `h53-org-hearth` | Orgrimmar | 52.70 | x | x | x | x | x | x | x | | |
| 32 | `h54-hearth-org` | Orgrimmar (hearth) | 53.05 | x | x | x | x | x | x | x | | |
| 33 | `h56-fly-org`, `h-56-org-arrive`, `h56-sethearth-org` | Orgrimmar | 55.05 | x | x | x | x | x | x | x | | |
| 34 | `h-58-org-arrive` | Orgrimmar | 57.21 | x | x | x | x | x | x | x | | |
| 35 | `h-58-uc-arrive` | Undercity | 57.21 | x | | x | | x | x | x | | (x) |
| 36 | `h59-hearth-uc` | Undercity (hearth) | 57.96 | x | | x | | x | x | x | | (x) |
| 37 | `h-60-end` | Light's Hope Chapel; hearthstone = Undercity | 60.00 | x | | x | | x | x | x | | (x) |

Stop 29 is missing in routes.md 6.6 (Stonard is visited a second time at 51.8 for the Fallen Hero chain).
Druids add Moonglade by Teleport at any step; mages add any capital by Teleport (section 5.6).

### 4.3 Trainable levels per class (read off 4.2) and the gaps

| Class | Stops with a trainer (level) | Gaps a class agent must plan around |
|---|---|---|
| Warrior | 22.06, 24.8, 27.3, 28.4, 28.75, 30.9, 31.05, 31.2, 34.1, 36.06, 40.04, 41.0, 44.0 (UC and Stonard), 49.4, 49.5, 51.8, 52.6, 52.7, 53.05, 55.05, 57.2, 57.96, 60 | none |
| Mage, Priest | as warrior without Stonard (44.03, 51.8) | none |
| Hunter | 22.06 (TB, Org), 24.8, 27.3, 28.4, 28.75, 30.9, 31.05, 34.1 / 34.9 - 35.9 (Grom'gol), 36.06, 40.04, 41.0, 44.02 (Grom'gol), 44.03 (Stonard), 44.5, 45.1 - 45.3 (Grom'gol), 49.4, 51.8 (Stonard), 52.7, 53.05, 55.05, 57.2 | 45.3 -> 49.4; the last trainer is Orgrimmar at 57.2: the 58 and 60 ranks need Orgrimmar after `h-60-end` (the stone is bound in the Undercity: zeppelin) |
| Shaman | 22.06 (TB, Org), 24.8, 27.3, 28.4, 28.6 (Skywatcher), 28.75, 30.9, 31.05, 36.06, 40.04, 41.0, 44.03 (Stonard), 49.4, 51.8 (Stonard), 52.7, 53.05, 55.05, 57.2 | **31.05 -> 36.06** (the 32 and 34 ranks wait for 36); 44.2 -> 49.4; 58 / 60 as hunter |
| Rogue | 22.06 (Org, UC), 31.05, 31.2, 34.1 (UC), 34.1 (Booty Bay), 35.9 - 36.0 (Booty Bay), 36.06, 40.04, 41.0, 44.0, 44.6 - 46.0 (Booty Bay), 49.4, 49.5, 52.6, 52.7, 53.05, 55.05, 57.2, 57.96, 60 | **22.06 -> 31.05: nine levels, five Thunder Bluff stops, no trainer.** Cheapest fix: from Tarren Mill at the end of `h-22-hillsbrad` (`h-24-tarrenmill-end`, 24.8) fly to the Undercity (about 3 min), train 24, then use the library's Tarren Mill -> Thunder Bluff hearth from there (`h-24-tb-hearth`); 26 - 30 wait for Orgrimmar at 31.05 |
| Warlock | 22.06 (Org, UC), 31.05, 31.2, 34.1, 36.06, 40.04, 41.0, 44.0 (UC and Stonard), 49.4, 49.5, 51.8, 52.6, 52.7, 53.05, 55.05, 57.2, 57.96, 60 | the same 22.06 -> 31.05 gap and the same fix as the rogue |
| Druid | 22.06, 24.8, 27.3, 28.4, 28.6 (Skywatcher), 28.75, 30.9 (TB), 47.2 / 49.4 (Mojache) + Moonglade by Teleport | no Thunder Bluff stop after 31: Moonglade pattern of 4.1 |
| Paladin | Thunder Bluff and Undercity stops if the DB is right; Brill at 41.0 | Orgrimmar never; 0.2 item 5 |

Levels 12-22 (the unified Barrens path, not written yet): there is no trainer in the Barrens, Stonetalon or
Ashenvale. Every class needs city visits there: Orgrimmar (all but druid / paladin), Thunder Bluff (all but
rogue / warlock / paladin?), Undercity (all but hunter / shaman / druid). The path agents must give every city
arrival between 12 and 22 an explicit id (routes.md 9.3) and should say in their hand-over which of the three
capitals each race passes at about 12-14, 16, 18, 20 and 22. A class without a trainer in the capital the
unified path uses at that level (rogue / warlock when it is Thunder Bluff; hunter / shaman when it is the
Undercity) needs its own "fly to Orgrimmar and back" insert there.

---------------------------------------------------------------------------------------------------------------

## 5. Class quests per class: chains, rewards, routing verdicts

How to read the chain tables. "XP" = sum of the DB values of the listed quests ("+?" = a quest with unknown XP).
"Path" = where today's routes pass the chain's places (level from the validator trace; the 1-22 part will be
rewritten, so those levels are indicative; 22-60 levels are stable). Verdict: **ROUTE** = key ability or XP at
(almost) no extra travel; **candidate** = worth it only if the class agent's validator numbers confirm it (make
the steps `optional` when a random drop or an elite decides); **skip** = dungeon, long travel or no value for
leveling speed. Rule of thumb used: one same-level kill is worth 95 XP at 10, 145 at 20, 195 at 30, 245 at 40,
295 at 50 (DB `xp.mobRule`) and takes about half a minute, so a detour of N minutes must bring about
2 x N kills of XP to break even. Running speed 7 yd/s on foot, 11.2 yd/s mounted; zone sizes from `zones[].size`.

Full per-quest tables (giver, turn-in, coordinates, links, objectives, XP source, status): Appendix A.

### 5.1 WARRIOR (Orc, Troll, Tauren, Undead, Skyborne)

| Chain | Races (DB mask) | Req | Quests | XP | Reward | Path | Verdict |
|---|---|---|---|---|---|---|---|
| Letter | per race | 1 | 2383 / 3065 / 3091 / 3095 / 92532 | 40 (92532 ?) | first training | start camp | ROUTE |
| Defensive Stance, Barrens variant | all Horde; exclusive with the Brill variant | 10 | 1505 (breadcrumb: Tarshaw at Razor Hill, Krang at Bloodhoof, Sorek in Orgrimmar, Torm in Thunder Bluff) -> **1498** Path of Defense at Uzzek, Far Watch Post (1413 61.4, 21.1): 5 Singed Scales from Thunder Lizard / Lightning Hide, Thunder Ridge in Durotar (39, 25-30) | 85 + ? | Defensive Stance (C); Taunt and Sunder Armor (W) | Orc / Troll: Thunder Ridge is on the Durotar loop, Far Watch on the way into the Barrens. Tauren: Far Watch is about 1 100 yd from the Crossroads and Thunder Ridge another 650 yd beyond: about 12 min round trip | ROUTE for Orc / Troll; candidate for Tauren (the stance is not needed to level; 1718 at 30 has no prerequisite) |
| Forged Steel | all Horde; needs 1498 or 1819 | 10 | 1502 (Uzzek -> Thun'grim Firegaze, 1413 57.2, 30.3) -> 1503 (Stolen Iron Chest, 1413 55.0, 26.6) | 1 050 | weapon (C) | Thun'grim stands between Far Watch and the Crossroads; today's Undead route passes within 4 units at 14.9, 18.2, 25.2, 26.1 | ROUTE with the stance chain. **Undead too**: 1502 accepts 1819 as prerequisite, so the Undead warrior takes it at Uzzek when he enters the Barrens |
| Defensive Stance, Brill variant | all Horde; exclusive with 1498 | 10 | 1818 (Austil de Mon in Brill or Baltus Fowler in the Undercity -> Deathguard Dillinger, Brill) -> **1819** kill Ulag the Cleaver (L11, mausoleum 1420 59.5, 48.3) -> 1820 (-> Coleman Farthing, Brill) -> 1821 Agamand Heirlooms (four weapon racks at Agamand Mills, 1420 52-53, 26-27) -> 1822 | 2 675 | Defensive Stance (C) + weapon | all within Brill / Agamand Mills; the Tirisfal path is at Brill 8.3 - 11.7 | ROUTE for Undead (0.35 level at 10) |
| Skybreaker Bulwark | Skyborne (both factions) | 10 | 94003 at Seena Skybreaker, Valanaar: item from Zaal Stormshield (L10, 2521 56.6, 50.4) | ? | W lists it among the level-10 Defensive Stance quests | today's Skyborne route passes Zaal's place at 11.5 | ROUTE (one kill) |
| Trial at the Field of Giants | all Horde | 20 | 1823 (breadcrumb from trainers in Orgrimmar / Thunder Bluff / Undercity) -> 1824 at Ruga Ragetotem, Camp Taurajo (1413 44.7, 59.4): 5 Twitching Antennae from silithids at the Field of Giants (1413 42, 69, L20-21) -> 1825 (-> Thun'grim Firegaze) | 155 + 1 550 + 780 | leads to the Brutal armour | `h-24-camp-taurajo` (25.15), the Field of Giants loop of `h-24-barrens-stonetalon` (25.2 - 25.7), then the walk Ratchet -> Crossroads passes Thun'grim (26.1) | **ROUTE: 2 330 XP (without the breadcrumb) for a handful of extra kills and no detour** |
| Brutal armour | all Horde | 20 (quest level 30) | 1838 (15 Smoky Iron Ingots from Windshear Crag, 10 Powdered Azurite from Hillsbrad miners, 10 Iron Bars, Vial of Phlogiston from Roogug in Razorfen Kraul) -> 1848 -> 1839 / 1840 / 1841 -> 1842 - 1847 | 3 650 + 3 050 + 3 x (1 200 + 1 200 + 1 850) | mail set (C) | a dungeon drop gates everything | skip (accept nothing after 1825) |
| Berserker Stance | any | 30 | 1718 The Islander (trainers in Orgrimmar / Thunder Bluff / Undercity -> Klannoc Macleod, Fray Island, 1413 68.6, 49.2) -> **1719** The Affray (waves, then Big Will L33) | 610 + 2 450 | **Berserker Stance** (C, W), Intercept (W) | Fray Island is 600 yd of swimming from Ratchet. At 30.9 - 31.05 the path does Thunder Bluff -> fly Camp Taurajo (`h-31-tb-fly`) -> fly Orgrimmar (`h-31-org`) -> zeppelin: accept 1718 at Torm (Thunder Bluff, 30.9), add a Ratchet stop on the way to Orgrimmar | **ROUTE (key ability)**; about 8 min including the fight |
| Whirlwind weapon | any | 30 (quest level 40) | 1791 (Klannoc -> Bath'rah the Windwatcher, 1416 80.5, 66.9) -> 1712 Cyclonian (8 Liferoot, 30 Bloodscalp Tusks, Essence of the Exile = child 1714: 8 + 8 + 8 charms from Drywhisker kobolds, Arathi) -> 1713 (Cyclonian, L40 elite, 1416 80.3, 62.1) -> 1792 | 245 + 2 350 + 2 350 + 3 900 | Whirlwind Axe / Sword / Warhammer (C, W) | Bath'rah is east of Tarren Mill across the river (the path is in Tarren Mill at 31.2 - 32.0 and 41.1). Drywhisker Gorge: `h-31-hillsbrad-arathi` kills kobolds there (32.2 - 34.0). Bloodscalps: `h-34-stranglethorn` (34.1 - 35.8). Liferoot: herb or vendor stock, not guaranteed. Return to Bath'rah: Tarren Mill at 41.1 (`h-41-undercity-flight-master`) | **ROUTE as a long background chain** (accept at 31, finish at 41; 8.8 k XP and the best weapon until the 50s); make the last two steps `optional` (elite, Liferoot) |
| Level 50 | any | 50 | 8417 (trainers -> Fallen Hero of the Horde, 1435 34.3, 66.1) -> 8423 (7 Helboars, Blasted Lands) -> 8424 (50 Shadowsworn, Blasted Lands 62, 41) -> 8425 (Sunken Temple) | 470 + 5 100 + 5 100 + 6 350 | class item (C) | the path talks to the Fallen Hero at 51.79 and 51.88 (`h-51-swamp-of-sorrows`, `-3`), then goes to the Blasted Lands (gate at 52 + 30 %) and hearths to Kargath | candidate: 8417 + 8423 only (5 570 XP; needs one walk back to the Fallen Hero, about 8 min); skip 8424 / 8425 |
| 58+ (Mokvar set, Quel'Serrar, Icebane) | | 58-60 | 8920 ... | | | | skip |

Training (W for Forever levels): 4 Charge / Rend, 6 Thunder Clap, 8 Hamstring, 10 Bloodrage, 12 Overpower, 14
Revenge / Demoralizing Shout, 20 Cleave (W also lists Victory Rush, Retaliation, Slam at 20), 24 Execute, 30
Berserker Rage, 36 Whirlwind, 40 plate (C) and the 31-point talent, 50 Recklessness. All three capitals and
Stonard have trainers: no gap. Weapon skills: section 6.1 (warriors can learn everything).

### 5.2 HUNTER (Orc, Troll, Tauren, Skyborne)

| Chain | Races | Req | Quests | XP | Reward | Path | Verdict |
|---|---|---|---|---|---|---|---|
| Letter | per race | 1 | 3087 / 3082 / 3092 / 92482 | 40 / 40 / 60 / ? | | start camp | ROUTE |
| Pet, Durotar | Orc, Troll | 10 | breadcrumb 6069 (Kali Remik, Sen'jin) / 6068 (Sian'dur, Orgrimmar) / 6070 (Thunder Bluff) -> 6062 (tame Dire Mottled Boar) -> 6083 (Surf Crawler) -> 6082 (Armored Scorpid), all at Thotar, Razor Hill (1411 51.9, 43.5) -> 6081 Training the Beast (-> Ormak Grimshot, Orgrimmar 66.0, 18.5) | 85 + 3 x 840 + 420 = 3 025 | **Tame Beast** (C), then Beast Training (C) | Razor Hill at 10 and Orgrimmar right after (startzones.md anchors `dur02-rh-3`, `dur02-org-1`) | **ROUTE (key)** |
| Pet, Mulgore | Tauren | 10 | breadcrumb 6065 / 6066 / 6067 -> 6061 (Adult Plainstrider) -> 6087 (Prairie Stalker) -> 6088 (Swoop) at Yaw Sharpmane, Bloodhoof (1412 46.9, 59.6) -> 6089 (-> Holt Thunderhorn, Thunder Bluff 57.3, 89.8) | 3 025 | same | `mul02-bh-5`, `mul02-tb` | **ROUTE (key)** |
| Pet, Zephras | Skyborne (both factions) | 10 | 94007 (breadcrumb: Elayaa Easewind, Shen'dar -> Quel'ana Quickgale, Valanaar 59.6, 72.6) -> 94978 (Windsong Crawler, 43.1, 65.7) -> 94979 (Ornery Galestrider, 45.7, 81.0) -> 94013 (Vuldren Alpha, 44.1, 65.6) -> 94050 (-> pet trainer Quel'dora Quickgale 254411, Valanaar 59.9, 72.9) | ? x 5 | same (W: "Taming the Beast" on Zephras Isle) | Valanaar at 10 - 11.2 in today's Skyborne route; the three beasts are in the south-west of the isle (the route is near 45.7, 81 at 10.4 - 11.1) | **ROUTE (key)** |
| Level 50 | any | 50 | 8151 (Holt in Thunder Bluff or Ormak in Orgrimmar -> Ogtinc, Azshara 42.4, 42.6) -> 8153 (2 Perfect Courser Antlers, Mosshoof Coursers, Azshara 35, 66) -> 8231 (6 Wavethrasher Scales, north-east bays) -> 8232 (Sunken Temple) | 510 + 5 100 + 5 100 + 6 350 | class item (C) | Azshara part of `h-53-azshara-ungoro-silithus` at 52.7 - 53.0 (Xylem 29.2, 40.2 is the nearest step; nothing within 8 units of Ogtinc) | candidate: 8151 + 8153 (5 610 XP) if the antlers can be had on the way; skip 8231 / 8232 |

Everything else a hunter needs is service: ammunition, pet trainers (pet skill ranks), stables (section 6.3).
Training (W): 4 Aspect of the Monkey / Serpent Sting, 6 Hunter's Mark / Arcane Shot, 8 Concussive Shot, 10
Aspect of the Hawk + the pet, 12 Wing Clip (and Mend Pet, C), 16 Mongoose Bite / Immolation Trap, 20 Aspect of
the Cheetah / Freezing Trap, 26 Rapid Fire, 30 Feign Death, 40 Aspect of the Pack (and mail, C). No trainer in
the Undercity. W: Auto Shot needs 0.5 s of standing still; ammunition is still required; all traps share one
cooldown.

### 5.3 ROGUE (Orc, Troll, Undead, Skyborne)

| Chain | Races | Req | Quests | XP | Reward | Path | Verdict |
|---|---|---|---|---|---|---|---|
| Letter | per race | 1 | 3088 / 3083 / 3096 / 92483 | 40 (92483 ?) | | start camp | ROUTE |
| Shattered Hand | 1859 Orc only; 1963 / 1858 Orc + Troll | 10 (quest level 13) | 1859 (breadcrumb: Kaplak, Razor Hill -> Therzok, Orgrimmar Cleft of Shadow 42.7, 53.5) -> 1963 (Tazan's Satchel: Tazan, L13, 1413 63.1, 44.3 south of Ratchet) -> 1858 (Tazan's Logbook) | 210 + 680 + 455 | item (not verified) | needs Orgrimmar - Ratchet coast - Orgrimmar; today's Barrens segment is at the Ratchet coast at 15.3 | candidate (1 135 XP if both Orgrimmar visits are training visits anyway) |
| Deathstalkers | Undead | 10 (13) | 1885 (breadcrumb: Marion Call, Brill -> Mennet Carkad, Undercity 83.5, 69.1) -> 1886 (Astor Hadren, L13, walks the Silverpine road near 1421 49.7, 32.2) -> 1898 -> 1899 (Andron's Bookshelf, Undercity 55.4, 77.0) -> 1978 (-> Varimathras) | 210 + 680 + 230 + 230 + 910 = 2 260 | item (not verified) | Undercity + the Silverpine road the Undead path walks at 12.9 - 13.3 | ROUTE for Undead (cheap XP, all inside the Undercity except one kill) |
| Lockpicking practice | all Horde | 16 | 2378 (Mennet Carkad, Undercity) or 2380 (Kaplak, Razor Hill) -> Shenthul, Orgrimmar (43.0, 53.7) -> 2379 (-> Zando'zan, same room) -> 2382 (-> Wrenix the Wretched, Ratchet 63.1, 36.3) -> 2381 Plundering the Plunderers (Southsea Treasure: Polly, L18, pirate ship 1413 64.8, 45.5) | 115 + ? + 115 + 1 350 | lockpicking practice on the ship (C); Pick Lock itself is a trainer spell at 16 (W) | Ratchet at 17.2, 18.0, 20.3 in today's route | candidate; it matters because the Poisons quest needs lockpicking (W: "at least 80") |
| Undead 16 | Undead | 16 | 1998 (Fenwick Thatros, L16, 1421 59.6, 33.9) -> 1999 Tools of the Trade (Ambermill Strongbox, 1421 63.7, 65.2) | 880 + 1 550 | lockpicking (C) | Undercity at 22.06, Ambermill at 23.6 (`h-22-offering-stone`), next Undercity at 31.2 | skip (two Undercity round trips) |
| **Poisons** | all Horde | 20 | 2460 The Shattered Salute (Shenthul, Orgrimmar) -> 2458 Deep Cover (-> Taskmaster Fizzule, Venture Co. tower, 1413 55.4, 5.6) -> **2478** Mission: Possible But Not Probable (2 + 2 + 2 kills, tower key from Foreman Silixiz, Gallywix L23 elite, Gallywix's Lockbox; turn in at Shenthul) -> 2479 Hinott's Assistance (-> Serge Hinott, Tarren Mill 61.6, 19.2) -> 2480 | 155 + 1 150 + 1 950 + 1 050 + 155 = 4 460 | **Poisons** (C, W); 2479 / 2480 cure the tower's debuff | the tower is about 1 200 yd north-west of Far Watch Post, 6 min on foot from Orgrimmar's gate. Orgrimmar stop at 22.06 (`h-22-org-fp`), then the path takes the zeppelin and reaches Tarren Mill at 23.7 (`h-22-tarrenmill-arrive`): 2479 / 2480 cost nothing | **ROUTE (key)**: accept at the level-20 or 22 Orgrimmar visit, about 20 min for tower and return, then Tarren Mill on the path. If the unified 18-22 path touches the north Barrens at 20+, do the tower there |
| Ravenholdt | any | 24 | 6681 The Manor, Ravenholdt (starts from the item Elegant Letter, a pickpocket drop (C); -> Fahrad, 1416 84.5, 80.3) | 1 950 | Ravenholdt reputation | Durnholde Keep at about 24 in `h-22-hillsbrad`; the manor path starts behind it (about 7 min round trip) | candidate / optional (the letter is random) |
| Forever-new | 78676 / 78699 any; 96779 - 96786 any (96784 Horde) | 25 / 24 | The Eye of Bhossca (Dead Drop, Pyrewood Village 1421 47.1, 71.0); Syndicate Sabotage -> ... -> The Syndicate Sting (index only, levels 24-36) | ? | ? | not on the path / unknown | skip until someone records them in game |
| Level 50 | any | 50 | 8233 (Ormok in Orgrimmar or Miles Dexter in the Undercity -> Lord Jorach Ravenholdt, 1416 86.0, 78.9) -> 8234 (Sealed Azure Bag, Timbermaw Shamans, Azshara 38, 32 -> Archmage Xylem, Azshara 29.2, 40.2) -> 8235 (10 Encoded Fragments, Forest Oozes, Azshara 36, 68) -> 8236 (Sunken Temple) | 510 + 5 100 + 5 100 + 6 350 | class item (C) | Tarren Mill at 49.6 (`h50-fly-tarrenmill`) for the manor; Xylem is a path step at 52.98 (`h-53-archmage-xylem`) | candidate: 8233 - 8235 = 10.7 k XP for the manor detour at 49.6 plus kills in Azshara |

Training (W): 6 Gouge, 8 Evasion, 10 Sprint / Sap / Slice and Dice (dual wield, C), 12 Kick, 14 Expose Armor,
16 Pick Lock / Feint, 18 Poised (new passive), 22 Vanish / Distract, 24 Shank (new), 26 Cheap Shot, 30 Kidney
Shot, 34 Blind, 44 Shank 2. Poison ranks are crafted from vendor materials (section 6.4); W: Instant from the
quest, Crippling 20, Mind-numbing 24, Deadly 30, Wound 32. **No trainer between 22.06 and 31.05** (4.3).

### 5.4 SHAMAN (Orc, Troll, Tauren, Skyborne)

Totems are still bag items from the four quests (W). 

| Chain | Races | Req | Quests | XP | Reward | Path | Verdict |
|---|---|---|---|---|---|---|---|
| Letter | per race | 1 | 3089 / 3084 / 3093 / 92484 | 40 / 40 / 60 / ? | | start camp | ROUTE |
| Earth, Durotar | all Horde (exclusive with the other two) | 4 | 1516 (2 Felstalker Hooves) -> 1517 (-> Minor Manifestation of Earth, 1411 44.0, 76.2) -> 1518, Canaga Earthcaller in the Valley of Trials (42.4, 69.2) | 270 + 270 + 445 | **Earth Totem** (C) | in the valley | **ROUTE (key)** |
| Earth, Mulgore | all Horde | 4 | 1519 (2 Ritual Salves, Bristleback Shamans) -> 1520 (-> manifestation, 1412 52.0, 80.4) -> 1521, Seer Ravenfeather at Camp Narache (44.4, 76.8) | 270 + 180 + 445 | same | at the camp | **ROUTE (key)** |
| Earth, Zephras | all Horde in the mask; Zephras givers | 3 | 92466 (Signet of Akir, Al'Aketh mobs) -> 92467 (-> Minor Manifestation of Earth 251166, 2521 49.7, 23.8) -> 92468, Windshaper Boro at Thendal | ? x 3 | same (W) | at Thendal | **ROUTE (key)** |
| Fire, mainland | all Horde | 10 | breadcrumb 2983 (Swart, Razor Hill) / 2984 (Narm, Bloodhoof) / 1522 (Searn Firewarder, Orgrimmar 38.0, 37.7) / 1523 (Xanis Flameweaver, Thunder Bluff 25.2, 20.5) -> Kranal Fiss (1413 56.0, 19.9) -> 1524 (-> Telf Joolam, Shrine of the Dormant Flame, 1411 38.5, 59.0) -> 1525 (Fire Tar from Barrens Razormanes; Reagent Pouch from Burning Blade Cultists, Durotar 52, 26) -> 1526 (kill the Minor Manifestation of Fire at the brazier 39.0, 58.2) -> 1527 (-> Kranal Fiss) | 420 + 660 + 910 + 1 150 + 1 150 = 4 290 | **Fire Totem** (C): Searing Totem at 10 | Kranal is 550 yd west of Far Watch; Telf is on the peak above the Valley of Trials, about 1 400 yd from Kranal; the chain needs Kranal -> Telf -> (Barrens + Skull Rock items) -> Telf -> Kranal: two Barrens <-> south-west Durotar round trips, about 25 min with the items | **ROUTE (key; the XP roughly pays the time at 12)**. Orc / Troll: around the move into the Barrens. Tauren: both trips start from the Crossroads side (about 6 min more each): still required |
| Fire, Zephras | Skyborne | 10 | 97243 (Sessaria Skystride, Valanaar, or Aarnor Galestrike, Shen'dar -> Olariaan Swiftburn, 2521 51.2, 86.2) -> 97244 (Skypriest Faladiel, L10, 64.4, 63.7) -> 97245 (Kuramaa, L10, 42.4, 68.8) -> 97257 (two braziers, 51.2, 85.9 and 58.4, 78.8 -> Sessaria). 98517 is a Skyborne breadcrumb from Swart in Razor Hill to Sessaria (for a Skyborne already on the mainland) | ? x 4 | same (W: Earth and Fire totems on Zephras) | all on the isle; today's Skyborne route is at Olariaan's place at 10.4 - 11.1 and at Faladiel's at 11.2 - 11.4 | **ROUTE (key)** |
| Water | all Horde | 20 (quest level 22-23) | breadcrumb 1528 (Orgrimmar) / 1529 (Thunder Bluff) / 2985 (Razor Hill) / 2986 (Bloodhoof) -> Islen Waterseer (1413 65.8, 43.8, coast south of Ratchet) -> 1530 (-> Brine, 1413 43.4, 77.4) -> 1535 (Quilboar Watering Hole next to Brine) -> 1536 (**Spring Well in Tarren Mill**, 1424 62.2, 20.8) -> 1534 (Ruins of Stardust fountain, Ashenvale 33.5, 67.5) -> 220 (Brine -> Islen) -> 63 (Brazier of Everfount, Silverpine 38.3, 44.6: kill a L22 manifestation) -> 100 -> 96 (-> Islen) | 780 + 435 + 870 + 1 300 + 1 400 + 460 + 1 400 + 1 400 + 2 750 = 10 795 | **Water Totem** (C): Healing Stream, Mana Spring at 26 | Path order: Sepulcher 22.75, Tarren Mill 23.7 - 25.0, Brine's corner 25.15 - 25.67 (`h-24-gann-stonespire`), Ratchet / Islen 25.9, Ruins of Stardust 28.1, Camp Taurajo 28.9. The chain order is Islen, Brine, Tarren Mill, Brine, Ashenvale, Brine, Islen, Silverpine, Islen: it never lines up completely | candidate, in two halves. First half (to 1534, 4 785 XP with the breadcrumb): start at the Ratchet stop at 20 with one trip to Brine, Tarren Mill well at 23.7, Brine at 25.2, Ashenvale at 28.1, Brine again from Camp Taurajo at 28.9 (+6 min). Second half (220, 63, 100, 96: 6 010 XP and the totem) needs an Islen stop (Ratchet, +4 min at 31.0), a Sepulcher trip from the Undercity at 31.2 (+5 min) and Islen again (Ratchet, 46.0). Decide by the validator's kill numbers; a late Water Totem costs Mana Spring from 26 |
| Air | all Horde (1531 / 1532); 96136 Skyborne, required 30, index only | 30 | 1531 (Searn Firewarder, Orgrimmar) or 1532 (Xanis Flameweaver, Thunder Bluff) -> Prate Cloudseer, Thousand Needles 53.5, 42.6 | 2 450 | **Air Totem** (C): Windfury Totem 32, Grounding, Grace of Air | Xanis stands on Spirit Rise where the path is at 30.9 (`h-31-tb-hearth`). Prate stands next to Dorn Plainstalker (`h-28-dorn-plainstalker`, 1441 54.0, 41.5), whom the path visits at 29.2 and 30.0: just before the quest can be accepted (required level 30, givers only in the two capitals). The path only flies through Freewind Post again at 46.0 (`h46-fly-freewind`) and 47.2 | ROUTE the accept at 30.9; turn-in either at 46.0 (free) or by a Freewind round trip from Camp Taurajo at 31.0 (about 8 min for the totem at 31 and 2 450 XP: break-even, candidate) |
| Forever-new | Orc / Tauren / Troll or all Horde; index only | 18 / 30 | 79362 Grant's Shield, 79363 Silvia's Sword (level 25-26, Duskwood sort), 79360 Elemental Aid, 79364 Eyes on the Sky, 79358 / 79361 Storm, Earth, and Fire, 79366 Heed My Call, 79442 The Tempest's Weapons | ? | W: "Call of Air also gives your spec's weapon"; nothing more is known | not in the snapshot | skip / open question |
| Level 50 | all Horde | 50 | 8410 (trainers in Thunder Bluff / Orgrimmar) or 8411 -> Bath'rah (1416 80.5, 66.9) with one Elemental Air, Fire, Earth, Water -> 8412 (vulture parts, Plaguelands) -> 8413 (Sunken Temple) | 3 550 + 5 100 + 6 350 | class item (C) | Tarren Mill at 49.6 | skip (or 8410 alone if the four elemental items are in the bags) |

Training (W): Rockbiter 1, Flametongue Weapon 10, Ghost Wolf 20, Frostbrand 20, Totemic Recall / Call of the
Elements 20 (new), Totemic Projection 22 (renamed Totemic Call), Windfury Weapon 30, Call of the Ancestors 30
(new), Windfury Totem 32, mail at 40 (C). No trainer in the Undercity; **nothing between 31.05 and 36.06**.

### 5.5 WARLOCK (Orc, Troll, Undead)

| Chain | Races | Req | Quests | XP | Reward | Path | Verdict |
|---|---|---|---|---|---|---|---|
| Letter | per race | 1 | 3090 / 98575 / 3099 | 40 / ? / 40 | | start camp | ROUTE |
| Imp, Durotar | all Horde (exclusive with 1470) | 1 | 1485 Vile Familiars (6 heads; Ruzan, Valley of Trials 42.6, 69.0) -> 1499 (-> Zureetha Fargaze) -> the common 794. **Replaces 792**, whose class mask excludes warlocks | 355 + 35 | **Summon Imp** (C) | same mobs as 792 | **ROUTE (key)**; the base step for 792 needs `classes` = all but WARLOCK |
| Imp, Tirisfal | all Horde | 1 | 1470 Piercing the Veil (3 Rattlecage Skulls; Venya Marthand, Deathknell 31.0, 66.4) | 190 | same | same mobs as the Deathknell quests | **ROUTE (key)** |
| Voidwalker, Orgrimmar | 1506 all Horde; **1501 / 1504 Orc only in the DB** (W: Orc / Troll) | 10 | 1506 (breadcrumb: Ophek, Razor Hill 54.4, 41.3 -> Gan'rul Bloodeye, Cleft of Shadow 48.2, 45.3) -> 1501 (Tablet of Verga: Burning Blade Stash in Skull Rock, 1411 51.6, 9.8) -> 1504 The Binding (summoning circle) | 210 + 880 + 660 | **Summon Voidwalker** (C) | Skull Rock is a cave about 300 yd east of Orgrimmar's gate; first Orgrimmar visit (`dur02-org-1`) | **ROUTE (key)**; Troll: validator `quest-race` ERROR until the DB mask is fixed (0.2 item 4) |
| Voidwalker, Undercity | 1478 all Horde; 1473 / 1471 Undead | 10 | 1478 (breadcrumb: Ageron Kargal, Brill -> Carendin Halgar, Magic Quarter 85.1, 26.0) -> 1473 (Egalin's Grimoire: Perrine's Chest, 1420 51.1, 67.6) -> 1471 | 210 + 630 + 630 | same | the Undead path is at the chest's place at 10.1 | **ROUTE (key)** |
| Succubus, Orgrimmar branch | all Horde (exclusive with the Undercity branch) | 20 | 1507 (Gan'rul -> Cazul) -> 1508 (-> Zankaja, Orgrimmar) -> 1509 (-> Gazrog, the Crossroads) -> 1510 (-> Ken'zigla, Malaka'jin, Stonetalon 73.2, 95.1) -> 1511 (-> Grunt Logmar, Camp Taurajo) -> 1515 (-> Grunt Dogran, 1413 43.3, 47.9) -> 1512 (-> Gan'rul) -> 1513 The Binding | 155 + 390 + 390 + 780 + 1 550 + 1 150 + 390 + 1 150 = 5 955 | Summon Succubus (C) | Crossroads, Malaka'jin and Camp Taurajo are all on the 18-22 loop, but the chain starts and ends in Orgrimmar (22.06, 31.05) | candidate if the unified path passes Orgrimmar at 20; otherwise prefer the Incubus |
| Succubus, Undercity branch | all Horde | 20 | 1472 (Carendin Halgar -> Godrick Farsan) -> 1476 Hearts of the Pure (Dalin Forgewright at Pyrewood, Silverpine 47.6, 85.7; Comar Villard at Dun Modr, Wetlands 49.9, 12.6) -> 1474 | 155 + 1 550 + 1 550 | Summon Succubus (C) | Wetlands | skip |
| **Incubus, Undercity branch** (Forever-new) | all Horde | 20 | 1472 -> 65593 Hearts of the Lovers (Avelina Lilly, L22, **Ambermill** 1421 63.0, 63.9; Isaac Pearson, L22, **Ratchet** 1413 61.9, 38.5) -> 65597 The Binding | 155 + ? + ? | Summon Incubus (W; the Succubus's twin) | Undercity 22.06, Ambermill 23.6 (`h-22-offering-stone`), Ratchet 25.9 (`h-24-ratchet-arrive`), Undercity 31.2 (`h-31-uc-arrive`) | **ROUTE: zero detour**; the demon arrives at 31 |
| Incubus, Orgrimmar branch (Forever-new) | all Horde | 20 (65610 is level 27) | 1507 -> 65601 Love Hurts (Cazul -> Magar, Orgrimmar 63.6, 49.9) -> 65610 Wish You Were Here (Withered Scarf: Shadethicket mobs, Ashenvale 59, 79) -> 65604 The Binding | 155 + ? x 3 | Summon Incubus | Orgrimmar 22.06, Raynewood at 27.8 - 28.1, Orgrimmar 31.05 | alternative with the same zero detour; pick one branch (they are exclusive) |
| Orb of Soran'ruk | any | 20 | 1740 (Doan Karhan, 1413 49.3, 57.2): fragments from Blackfathom Deeps and Shadowfang Keep | 2 550 | staff or orb (C) | dungeons | skip (optional with the dungeon blocks) |
| Felhunter | all Horde | 30 | 2996 (Gan'rul) / 3001 (Carendin Halgar) -> Strahad Farsan, Ratchet (62.6, 35.5) -> 1801 (-> Jorah Annison, Undercity 75.9, 37.9) -> 1803 (Tome of the Cabal on Purgation Isle, Hillsbrad 27.8, 72.8; Damaged Chest, Thousand Needles 43.4, 32.7) -> 1805 (3 Rods of Channeling, Dragonmaw casters, Wetlands) -> 1795 The Binding | 610 + 610 + 2 450 + 2 450 + 2 450 | Summon Felhunter (C) | Purgation Isle, Thousand Needles north and the Wetlands are all off the path after 31 | skip (not needed to level) |
| Enchanted Gold Bloodrobe | 4737 / 4739 all Horde, rest any | 31 | breadcrumb 4737 (Zevrost, Orgrimmar) / 4739 (Kaal Soulreaper, Undercity) -> Menara Voidrender, Ratchet -> 1796 (Robes of Arcana, a tailored item) -> 4781 -> 4782 -> 4783 -> 4784 -> 4786 | 630 + 2 500 + 2 000 + 1 350 + 2 850 + 2 100 + 3 550 | robe (C) | needs a crafted robe, a gold bar, Booty Bay, Desolace, Arathi | skip |
| **Orb of Orahil** | 4967 / 4969 all Horde, rest any | 35 | breadcrumb 4967 (Zevrost) / 4969 (Kaal Soulreaper) -> Menara Voidrender, Ratchet (62.5, 35.5) -> 1799 (Infernal Orb: Burning Blade Summoners, **Mannoroc Coven**, Desolace 49.6, 77.2; -> Tabetha, Dustwallow 46.1, 57.1) + 4962 (Felhound spirit, Mana Eaters, Mannoroc Coven) or 4963 -> 4961 (Demon of the Orb, L40 elite, at Tabetha) -> 4976 (-> Menara) -> 4964 or 4975 | 1 350 + 3 150 + 2 350 + 2 350 + 1 550 + 3 900 = 14 650 | off-hand orb (C) | Orgrimmar 36.06 (`h-37-org-arrive`), then the path flies to Sun Rock: add a Ratchet stop (+3 min; accept 1799 and 4962). Mannoroc Coven is the path's level gate at 37.8 (`h39-level-mannoroc`): orb and spirit drop there. DB: 4961 needs 1799 **and 4962 turned in**, and 4962 is turned in at Menara: the Ratchet stop at 40.04 that the Felsteed quest needs anyway serves both. Dustwallow at 40.1 - 40.9 (Tabetha is about 1 000 yd from Brackenwall, not on the path: +5 min and an elite). Ratchet again at 46.0 (`h46-ratchet-fm`) for 4976 and the final quest | **candidate with the best XP of all class chains** (about 15 min of detours for 14.6 k XP); the elite step `optional` |
| **Felsteed** | 3631 / 4489 all Horde, 4490 any | 40 | 3631 (Zevrost, Orgrimmar 48.5, 45.4) or 4489 (Kaal Soulreaper, Undercity) -> Strahad Farsan, Ratchet -> 4490 Summon Felsteed | ? + 315 | **free level-40 mount** (C, W) | Orgrimmar at 40.04 (`h-40-org-arrive`); the next library step flies to Camp Taurajo: fly to Ratchet first (+3 min) | **ROUTE (key)**; replaces the race riding insert for every warlock |
| Level 50 | any | 50 | 8419 (Zevrost or Kaal Soulreaper -> Impsy, Felwood 41.4, 45.0; 1 Felcloth) or 8420 -> 8421 (10 Rotting Wood, Irontrees 46, 24; 4 Bloodvenom Essence, Tainted Oozes 34, 48) -> 8422 (Sunken Temple) | 3 800 + 5 100 + 6 350 | class item (C) | Felwood at 55.07 - 55.41 (`h-56-remains-of-trey`, `h-57-bloodvenom-end`: eleven steps within 8 units of Impsy) and 57.15 | **candidate: 8 900 XP on the path**; `optional` because of the Felcloth drop |

Training (W): 4 Corruption, 6 Life Tap, 8 Fear (W also: Bane of Agony), 10 Drain Soul / Create Healthstone, 14
Drain Life, 18 Searing Pain, 20 Shadowburn (talent) / Rain of Fire, 30 Hellfire, 40 Incinerate (new), 42 Death
Coil, 48 Soul Fire. Pet spells are grimoires sold by demon trainers (section 6.5). **No trainer between 22.06
and 31.05** (4.3). W: training costs are lower than other classes' to pay for grimoires.

### 5.6 MAGE (Orc, Troll, Undead)

| Chain | Races | Req | Quests | XP | Reward | Path | Verdict |
|---|---|---|---|---|---|---|---|
| Letter | per race | 1 | 98576 / 3086 / 3098 | ? / 40 / 40 | | start camp | ROUTE |
| Level 10, Durotar | 1883 all Horde; 1884 Orc / Undead / Troll | 10 | 1883 (breadcrumb: Uthel'nay in Orgrimmar or Thurston Xane in Thunder Bluff) -> 1884 Ju-Ju Heaps at Un'Thuwa, Sen'jin (56.3, 75.1): 4 heaps on the Echo Isles (67, 88) | 85 + 840 | caster item (W: staves, off-hands, robes, wands; exact item not verified) | Sen'jin and the isles are visited before 10 in the Durotar draft (`dur02-senjin-3` at 9.4) | candidate: only if the path is at Sen'jin at 10+ |
| Level 10, Tirisfal | Undead / Troll | 10 | 1881 (breadcrumb: Cain Firesong, Brill -> Anastasia Hartwell, Undercity 85.1, 10.0) -> 1882 The Balnir Farmstead (Balnir Snapdragons, 1420 77.4, 61.8) | 85 + 840 | same | the Tirisfal path is at the farmstead at 11.0 - 11.2 and in the Undercity at 12.7 | ROUTE for Undead if the order allows (accept in the Undercity before the farm) |
| Level 15 | 1959 / 1960 / 1962 Undead / Troll; 1961 Orc / Undead / Troll (stale mask? 0.2 item 4) | 15 | 1959 (breadcrumb from any mage trainer) -> 1960 Investigate the Alchemist Shop (inside the Undercity) -> 1961 Gathering Materials (10 Linen Cloth; 6 Dalaran Mana Gems, Dalaran mobs at Ambermill L13-19) -> 1962 Spellfire Robes (tailors, Undercity 70, 30) | 105 + 1 150 + 800 + 1 050 = 3 105 | robe (C) | Undercity 22.06 (1959 + 1960 on the spot), Ambermill 23.6 (`h-22-offering-stone`), Undercity 31.2 | **ROUTE for Undead / Troll: zero detour**; Orc blocked by the DB masks |
| Level 26 | Undead / Troll | 26 | 1943 (Anastasia -> Deino, Orgrimmar) -> 1944 (Xavian Waterfall, Ashenvale 76.3, 41.5) -> 1945 (12 Laughing Sister's Hair, Ashenvale 58, 58 -> Kil'hala, the Crossroads) -> 1946 | 210 + 2 100 + 1 600 + 2 100 | robe (C) | needs Orgrimmar - Ashenvale - Orgrimmar - Ashenvale - Crossroads; the path's only Ashenvale visit after 26 is at 27.8 - 28.9 and Orgrimmar is not visited between 22.06 and 31.05 | skip |
| Level 30 wand | any | 30 | 1947 Journey to the Marsh (trainers -> Tabetha, Dustwallow 46.1, 57.1) -> 1948 - 1952 (index only) | 285 + ? | Mage's Wand (C) | out of the snapshot; C: includes a dungeon book | skip |
| Level 35 | any | 35 | 1953 (breadcrumb -> Tabetha) -> 1954 (Infernal Orb, Mannoroc Coven) -> 1955 (Demon of the Orb, L40 elite) -> 1956 (Uldaman) -> 1957 / 1958 (index only) | 315 + 2 350 + 2 350 + 3 900 | caster item (C) | Tabetha gives 1954, but the path reaches Dustwallow (40.1) after Desolace (36 - 40): wrong order | skip |
| Research Access (Forever-new) | any; class mask MAGE | 1 (quest level 20) | 97286 at Owen Thadd 211022 (Undercity 73.4, 33.0); prerequisite: any one of the library book quests (the list includes 81947, 81949, 81951 - 81956 of the shared path) | ? | unknown | the path turns in its first book at Owen Thadd at 49.53 (an anonymous step after `h-50-uc-arrive`), five more at 52.63 and one at 57.21 | **ROUTE: same NPC, zero detour**; the Owen Thadd step of `h-50-hinterlands-searing-steppes` needs an explicit id to anchor on |
| Level 50 | any | 50 | 8250 Magecraft (Uthel'nay in Orgrimmar, Pierce Shackleton in the Undercity or Archmage Shymm in Thunder Bluff -> Sanath Lim-yo, Azshara 28.1, 50.1) -> 8251 - 8253 (index only) | 510 + ? | class item (C) | Sanath stands near Xylem's tower: `h-53-archmage-xylem` at 52.98 | ROUTE the delivery (510 XP, accept at Orgrimmar 49.4 or the Undercity 49.5); the rest is unknown |

Mage-specific levers: Teleport to a capital from 20 and portals from 40 (W; C: Orgrimmar and Undercity at 20,
Thunder Bluff at 30), learned from the portal trainers Thuul 5958 (Orgrimmar 38.68, 85.41), Birgitte Cranston
5957 (Thunder Bluff 22.50, 16.91), Lexington Mortaim 2492 (Undercity 84.19, 15.58); reagent Rune of
Teleportation from reagent vendors (W: still required). A mage can replace "fly / hearth to a capital" steps
and can train anywhere; the class agent should check how the engine treats a library `fly` step when the player
arrives by other means before planning on it. Training (W): 4 Frostbolt, 6 Fire Blast, 8 Arcane Missiles, 10
Frost Nova / Polymorph, 14 Arcane Explosion, 20 Blizzard (and Blink, C), 30 Ice Armor, 34 Mage Armor. Wands:
0.5 s of standing still before shooting (W). All three capitals have trainers.

### 5.7 PRIEST (Troll, Undead)

| Chain | Races | Req | Quests | XP | Reward | Path | Verdict |
|---|---|---|---|---|---|---|---|
| Letter | per race | 1 | 3085 / 3097 | 40 | | start camp | ROUTE |
| Garments | Troll | 5 | 5649 (breadcrumb: Ken'jai, Valley of Trials -> Tai'jin, Razor Hill) -> 5648 (heal and buff Grunt Kor'ja, 1411 53.1, 46.5) | 90 + 270 | robe (C) | Razor Hill | ROUTE |
| Garments | Undead | 5 | 5651 (Dark Cleric Duesten, Deathknell -> Dark Cleric Beryl, Brill) -> 5650 (Deathguard Kel, 1420 59.2, 46.5) | 90 + 270 | robe (C) | Brill | ROUTE |
| Level 10 racial | Troll | 10 | 5652 (at Ur'kyo, Orgrimmar 35.6, 87.8) or a breadcrumb to him: 5654 (Tai'jin, Razor Hill), 5655 (Var'jun, Bloodhoof), 5656 (Miles Welsh, Thunder Bluff), 5657 (Aelthalyste, Undercity) | 210 (5652: ?) | Hex of Weakness (C, W) | first Orgrimmar visit | ROUTE (take the Razor Hill breadcrumb: it is the same visit plus 210 XP) |
| Level 10 racial | Undead | 10 | 5658 (at Aelthalyste, Undercity 49.3, 17.1) or a breadcrumb: 5660 - 5663 | 210 (5658: ?) | Touch of Weakness (C, W) | first Undercity visit | ROUTE |
| Level 20 racial | Troll | 20 | 5680 (Ur'kyo) or 5642 (from Miles Welsh, Thunder Bluff) / 5643 (from Aelthalyste) | 390 | Shadowguard (C, W) | Thunder Bluff then Orgrimmar at 22.06 | ROUTE (accept 5642 in Thunder Bluff at `h-22-tb-start`, turn in at `h-22-org-fp`) |
| Level 20 racial | Undead | 20 | 5679 (Aelthalyste) or 5644 (from Miles Welsh) / 5646 (from Ur'kyo) | 390 | C: Devouring Plague. **W: in Forever Devouring Plague is a trainer spell at 20 for every priest and the Undead racial pair is Touch of Weakness + Dark Sacrifice**: what 5679 teaches now is unknown | Thunder Bluff / Orgrimmar 22.06, Undercity 22.06 | ROUTE (390 XP on the way: accept 5644 or 5646 at 22.06 on the way to the Undercity) |
| Level 50 | any | 50 | 8254 (Malakai Cross in Thunder Bluff or Ur'kyo in Orgrimmar -> Ogtinc, Azshara 42.4, 42.6) -> 8255 (4 Healthy Courser Glands) -> 8256 (Ichor of Undeath) -> 8257 (Sunken Temple; -> Greta Mosshoof, Felwood) | 510 + 5 100 + 5 100 + 6 350 | class item (C) | Azshara at 52.7 - 53.0 | candidate: 8254 + 8255 (5 610 XP), as the hunter |

The priest has the least class travel of all nine. Training (W): 4 Shadow Word: Pain, 10 Mind Blast, 20
Devouring Plague (trainer), 32 Shadow Word: Death (new), talents Mind Flay 20, Penance 30, Shadowform 40. A wand
matters early (W: Lesser Magic Wand at 5, Greater Magic Wand at 13, both crafted by enchanters); wand vendors:
section 6.6. All three capitals have trainers.

### 5.8 DRUID (Tauren, Skyborne)

| Chain | Races | Req | Quests | XP | Reward | Path | Verdict |
|---|---|---|---|---|---|---|---|
| Letter | per race | 1 | 3094 / 92485 | 60 / ? | | start camp | ROUTE |
| Bear Form, Tauren | Tauren | 10 | breadcrumb 5928 (Gennia Runetotem, Bloodhoof) / 5926 (Innkeeper Pala, Thunder Bluff) / 5927 (Innkeeper Gryshka, Orgrimmar) -> Turak Runetotem (Thunder Bluff 76.5, 27.2) -> 5922 Moonglade (-> Dendrite Starblaze, 1450 56.2, 30.6) -> 5930 (Great Bear Spirit, 1450 39.1, 27.5) -> 5932 (-> Turak) -> 6002 Body and Heart (Lunaclaw Spirit at the Moonkin Stone, 1413 42.0, 60.8 west of Camp Taurajo; -> Turak) | 85 + 210 + 420 + 85 + 850 = 1 650 | Teleport: Moonglade (at 5922, C), **Bear Form** (C, W) | Thunder Bluff at 11.3 and Camp Taurajo at 11.8 in the Mulgore draft (`mul02-tb`, `mul02-taurajo`); the chain needs Turak three times (start, 5932 / 6002, final turn-in) | **ROUTE (key)**: the Tauren druid's start differs from the other Tauren around Thunder Bluff |
| Bear Form, Skyborne | Skyborne (both factions) | 10 | 94006 (Lotheluum Starbreeze, Valanaar -> Urs'endris, 2521 69.8, 61.7) -> 94638 (kill Ur'endra, cave at about 54, 65) | ? + ? | **Bear Form**, Growl, Maul (W) | as today in `sd-02` (`sd02-bear-accept`, `sd02-bearform`) | **ROUTE (key)**, exists |
| Moonglade, Skyborne | Horde Skyborne | 10 | 94911 Child of Nature (Muln Earthfury or Alaana Stormwalker, Skywatcher Plateau -> Turak) -> 94913 Moonglade (-> Dendrite) | ? + ? | Teleport: Moonglade (W) | as today (`sd03-child`, `sd03-moonglade`) | **ROUTE (key)**, exists |
| Cure Poison | Tauren (W lists it for Skyborne too) | 14 | 6126 (Turak, or Hana Lighthoof on Skywatcher Plateau -> Dendrite) -> 6127 (Dreadmist Peak pool, 1413 48.4, 18.9 -> Tonga Runetotem, the Crossroads) -> 6128 (5 Earthroot, 5 Kodo Horns) -> 6129 (cure 10 Sickly Gazelles -> Dendrite) -> 6130 (-> Turak) | 100 + 750 + 750 + 750 + 975 = 3 325 | Cure Poison (C) | everything but the two Moonglade visits is around the Crossroads | candidate for Tauren (3.3 k XP at 14-16, Moonglade by Teleport, back by Bunthen's flight or the hearthstone); blocked for Skyborne by the DB mask |
| Aquatic Form | Tauren (W lists it for Skyborne too) | 16 | 27 (Turak -> Dendrite) -> 28 (Shrine of Remulos) -> 30 (two pendant halves; C: Silverpine coast and the Barrens coast) -> 31 (-> Turak) | 120 + 875 + 875 + 1 150 | Aquatic Form (C) | long | skip |
| **Cat Form**, Tauren (Forever-new) | 98340 / 98362 Tauren + Skyborne; 98405 / 98342 / 98739 Tauren | 20 | 98340 (Turak -> Dendrite) -> 98405 (-> Great Cat Spirit, 1450 58.4, 73.5) -> 98342 (Relic of the Fang 72.4, 66.0, of the Claw 75.2, 67.2, of the Silent Shadow 74.4, 65.4: Stormrage Barrow Dens) -> 98739 (-> Dendrite) -> 98362 To Thunder Bluff (-> Turak) | ? x 5 (estimated 780 each) | **Cat Form**, Claw, Prowl, Rip (W) | Thunder Bluff at 20-22 | **ROUTE (key)** |
| **Cat Form**, Skyborne | 98341 / 98404 / 98738: both Skyborne factions, no class mask | 20 | 98340 -> 98341 (Dendrite -> Avatar of Saeyleenan, 1450 43.9, 73.4) -> 98404 (the same three relics) -> 98738 -> 98362 | ? x 5 | same | as today (`sd05-cat-start` ... `sd05-catform`, 21.2 - 21.5) | **ROUTE (key)**, exists |
| Level 50 | any | 50 | 9063 (Turak or Loganaar -> Torwa Pathfinder, Un'Goro 71.6, 76.0) -> 9052 -> 9051 -> 9053 (Sunken Temple) | 500 + 5 100 + 5 100 + 6 350 | class item (C) | as today (`dru-torwa-...`, 53.1 - 53.9) | ROUTE to 9051, exists |

Consequences for `Classes/Druid.lua`: two Bear chains, two Cat middles (race filter on three steps), the
Skyborne-only 94911 / 94913, the Tauren-only 6126 chain. Training (W): Shred at 20 (was 22), Ferocious Bite
rank 1 at 24, Rake 24, Travel Form 30 (trainer), Poised 32 (new passive), Dire Bear 40 (trainer); polearms
are new for druids (20, Archibald). Trainers: Thunder Bluff, Skywatcher Plateau, Camp Mojache, Moonglade.

### 5.9 PALADIN (Undead)

All paladin quests are Forever-new with unknown XP; the existing route already handles them (ud-01 .. ud-03 and
`Inserts.lua`). Chains in the DB:

| Chain | Req | Quests | Reward | Today |
|---|---|---|---|---|
| Letter | 1 | 98601 A Difficult Path (Sarvis or Novice Elreth -> Aramis Hammerhand, Deathknell) | | routed |
| Deathknell | 2 / 4 | 90902 Rediscovering the Light -> 91208 Coming to Terms; 91209 Continue Your Training (-> Shari Stilwell, Brill) | | routed |
| Bandarion Keep | 7 - 9 | 91282 A Second Home (Shari -> Breton Samuels, 1420 21.9, 45.2), 91285 Murlocs at the Gates -> 91294 Touring the Grounds -> 91316 Making Repairs, 91317 The Tarnished -> 95803 A Token of Good Faith (-> Sylvanas) | | routed |
| A Lesson in Divinity | 12 | 94427 -> 94434 (10 Linen Cloth) -> 94435 -> 94436 -> 94438 -> 94440 (Scarlet attack plans) -> 94441 | **Redemption** (W) | routed |
| Windshaper chain, part 1 | 18 (level 22) | 91858 -> 91859 -> 91860 -> 91861 -> 91862 -> 96204 (escort) -> 95034 | none of its own | optional inserts at 22.75 |
| Wolfsbane, part 2 | 20 (level 25) | 95036 A Moon-Kissed Blade (Deadmines lumber, Shadowfang Keep ingot, 95042 Kor Gem at Blackfathom) -> 95111 -> 95125 -> 95126 -> 95140 Old Fire-Eye | Wolfsbane, 2H sword (route header) | not routed |

W: Summon Warhorse at 40 comes from the class trainer (the route's `pal-40-riding` note already says so); the
level-60 mount quest is unknown; Righteous Fury is trainable at 10 (was 16); Seal of Fury rank 3 at 26. Trainer
dispute: 0.2 item 5.

### 5.10 One-page verdict table

| Class | ROUTE: key ability | ROUTE: XP at no or little detour | Candidates (validator decides) | Skip |
|---|---|---|---|---|
| Warrior | Defensive Stance at 10 where on the path (1498 Orc / Troll, 1819 Undead, 94003 Skyborne); **Berserker Stance at 30 (1718 -> 1719)**; Whirlwind weapon 31 -> 41 (1791 -> 1792) | 1502 / 1503 (all, also Undead); 1819 - 1822 (Undead, 2.7 k); **1824 / 1825 (2.3 k at 25)** | Tauren 1498; 8417 + 8423 at 52 | Brutal armour (1838+), 8424 / 8425, 58+ |
| Hunter | **pet chain at 10** (three race variants) | - | 8151 + 8153 at 53 | 8231 / 8232 |
| Rogue | **Poisons at 20 - 22 (2460 -> 2458 -> 2478)** | 2479 / 2480 (Tarren Mill, 1.2 k); Deathstalkers 1885 - 1978 (Undead, 2.3 k) | 1963 / 1858 (Orc / Troll); 2379 -> 2381 (lockpicking for the tower); 6681 at 24; 8233 - 8235 at 50 - 53 | 1998 / 1999, the Forever-new chains (unknown), 8236 |
| Shaman | **Earth at 3 - 4, Fire at 10** (mainland 1524 - 1527 or Zephras 97243 - 97257); Air (1532 accept at 30.9) | - | Water (two halves, 10.8 k XP in total); Air turn-in at 31 instead of 46 | 79358+ (unknown), 8410 - 8413 |
| Warlock | **Imp at 1, Voidwalker at 10, Felsteed at 40** | **Incubus (1472 -> 65593 -> 65597 or the Orgrimmar branch)** | **Orb of Orahil at 36 - 46 (14.6 k)**; 8419 / 8421 at 55 (8.9 k); Succubus Orgrimmar branch | Felhunter, robe chain, Soran'ruk, Undercity Succubus |
| Mage | - | 1959 - 1962 (Undead / Troll, 3.1 k); 97286 at Owen Thadd (49.5); 8250 (510); 1881 / 1882 (Undead) | 1883 / 1884 at Sen'jin | 1943 - 1946, wand chain, 1953 - 1956 |
| Priest | - | Garments at 5; racial quests at 10 and 20 (breadcrumb variants) | 8254 + 8255 at 53 | 8256 / 8257 |
| Druid | **Bear Form at 10, Cat Form at 20**, Teleport: Moonglade | 9063 -> 9052 -> 9051 (exists) | Cure Poison chain (Tauren, 3.3 k) | Aquatic Form, 9053 |
| Paladin | Redemption chain at 12 (exists) | start-zone chains (exist) | Windshaper chain part 1 (exists, optional) | Wolfsbane part 2 |

---------------------------------------------------------------------------------------------------------------

## 6. Cross-class services

### 6.1 Weapon masters and weapon skills

DB (id, place); what each teaches is not in the DB: C, confirmed by W for Forever.

| Weapon master | Where | Teaches (C + W) |
|---|---|---|
| Hanashi 2704 | Orgrimmar, Valley of Honor, 81.53, 19.63 | Bows, One-Handed Axes, Two-Handed Axes, Staves, Thrown |
| Sayoc 11868 | Orgrimmar, Valley of Honor, 81.70, 19.55 | Bows, Daggers, Fist Weapons, One-Handed Axes, Two-Handed Axes, Thrown (W adds Staves) |
| Ansekhwa 11869 | Thunder Bluff, lower rise, 40.93, 62.73 | Guns, One-Handed Maces, Two-Handed Maces, Staves |
| Archibald 11870 | Undercity, War Quarter, 57.31, 32.77 | Crossbows, Daggers, One-Handed Swords, Two-Handed Swords, Polearms |

* No weapon master on Zephras Isle or in any questing hub in the DB (Ember Bladewhisper 260080 "Weapons
  Trainer" in Riverglades is Alliance). Skyborne learn weapon skills in the three capitals.
* W (Forever): most skills cost 10 silver and have no level requirement; **Polearms need level 20 and cost 1
  gold**; rogues can use one-handed axes; druids can learn polearms; wands are not taught (mage, priest, warlock
  have them); weapon-specialisation racials were removed (no race prefers a weapon type any more).
* Which class can learn what (C, with the two W changes; verify per class before writing a step): warrior
  everything; hunter axes, two-handed axes, swords, two-handed swords, daggers, fist, staves, polearms, bows,
  guns, crossbows, thrown; rogue daggers, swords, maces, fist, one-handed axes (W), bows, guns, crossbows,
  thrown; shaman maces, staves, daggers, fist, axes, two-handed axes and maces (a talent in Classic; W lists
  them as trainable); paladin maces, swords, axes (one- and two-handed), polearms; druid staves, maces,
  two-handed maces, daggers, fist, polearms (W); mage staves, daggers, swords; priest maces, daggers, staves;
  warlock daggers, staves, swords. Starting skills of the Skyborne are unknown.
* Validator: a `train` step on a weapon master is an ERROR (`train-wrong-trainer`, the sub-name "Weapon Master"
  has no "trainer"); the paladin file uses `manual = true` with the NPC and a note (`pal-axes`). Stops with a
  weapon master on the path: every Orgrimmar, Thunder Bluff and Undercity stop of table 4.2 (the masters are 2 to
  3 minutes from the flight master or the bank in each city).

### 6.2 Riding and mounts

| Race | Riding trainer (DB) | Mount vendor (DB) | Path at 40 |
|---|---|---|---|
| Orc | Kildar 4752 "Wolf Riding Instructor", Orgrimmar 69.41, 13.10 | Ogunaro Wolfrunner 3362 "Kennel Master", Orgrimmar 69.38, 12.24 | `h-40-org-arrive` (40.04): inside the city, next to the hunter trainers |
| Troll | Xar'Ti 7953 "Raptor Riding Trainer", Sen'jin Village, Durotar 55.28, 75.49 | Zjolnir 7952 "Raptor Handler", 55.23, 75.65 | from Orgrimmar at 40.04 or 41.01: about 2 300 yd on foot to Sen'jin (5.5 min), back mounted (3.5 min) |
| Tauren | Kar Stormsinger 3690 "Kodo Riding Instructor", Bloodhoof Village, Mulgore 46.79, 61.97 | Harb Clawhoof 3685 "Kodo Mounts", 46.65, 62.08 | the library flies Orgrimmar -> Camp Taurajo after 40.04 (`h-38-orgrimmar-flight-master`): fly to Thunder Bluff instead, run to Bloodhoof (about 1 500 yd), ride on to Camp Taurajo (about 2 400 yd): about 7 min more than the direct flight |
| Undead | Velma Warnam 4773 "Undead Horse Riding Instructor", Brill 60.08, 52.57 | Zachariah Post 4731 "Undead Horse Merchant", Brill 59.87, 52.68 | `h-41-uc-arrive` (41.0): Brill is 2 min from the zeppelin tower (today's paladin insert) |
| Skyborne | Genn Fairweather 265756 "Stablemaster and Riding Trainer", Zephras Isle 53.83, 81.33 (faction AH; flags trainer, vendor, repair) | the same NPC (W: Umber, Stormy, Empyrean Galestrider) | today's optional trip after `h-40-org-arrive`: fly Thunder Bluff, Skywatcher Plateau, skycutter (Windshapers Dockmaster 275270, Valanaar 58.05, 80.39), 15-20 min |

* The DB has nothing else on Skyborne mounts: no separate vendor, no mount items (items are quest-related only),
  no quest. "Galestrider Handler" 264287 and the Galestriders 262523 on Skywatcher Plateau are transport
  landing NPCs, not vendors. Okamache 256400 "Kodo Handler" (vendor flag, walks near the Crossroads, 1413 48.8,
  28.3, Forever-new) is of unknown purpose.
* W: riding is one universal skill, learned from the own race's trainer at 40 for 100 gold (60 %), 1 000 gold at
  60 (100 %); another race's trainer / vendor needs Exalted with that race; discounts by home reputation. Method
  says the first mount is included in the 100 gold, Warcraft Tavern lists 20 gold per mount: unresolved.
* Class mounts: warlock Felsteed by quest at Ratchet (5.5); paladin Summon Warhorse from the class trainer at
  40 (W; Method could not test the Horde side in the beta); druid Travel Form at 30 from the trainer.
* Validator: `train` on Kildar, Kar Stormsinger or Velma Warnam is an ERROR ("Instructor" has no "trainer"), on
  Xar'Ti and Genn Fairweather a WARN (`train-not-class-trainer`). Use `manual` (paladin file) or accept the WARN
  with a `-- WARN-OK` (druid file).

### 6.3 Hunter: pet trainers, stable masters, ammunition

Pet trainers (teach pet skill ranks; sub-name "Pet Trainer": `train` gives WARN `train-not-class-trainer`):

| Pet trainer | Where |
|---|---|
| Harruk 3620 | Razor Hill, Durotar 52.03, 43.55 |
| Reban Freerunner 3688 | Bloodhoof Village, Mulgore 46.84, 59.69 |
| Quel'dora Quickgale 254411 | Valanaar, Zephras Isle 59.92, 72.87 (flags inferred from the sub-name) |
| Xao'tsu 10088 | Orgrimmar 66.32, 14.81 |
| Hesuwa Thunderhorn 10086 | Thunder Bluff 54.09, 83.99 |
| Zudd 3624 | Grom'gol 31.11, 28.94 |
| Grokor 3622 | Stonard 47.35, 52.89 |

No pet trainer (and no hunter trainer) in the Undercity. Stable masters (Horde or neutral) in the DB:

| Zone | Stable master |
|---|---|
| Durotar | Shoja'my 9987, Razor Hill 51.99, 41.84 |
| Mulgore | Seikwa 10050, Bloodhoof 46.04, 63.55 |
| Tirisfal | Morganus 10055, Brill 60.03, 52.16; Ephram Barbaro 259190, Bandarion Keep 20.17, 46.49 |
| Zephras Isle | Genn Fairweather 265756, 53.83, 81.33 (the riding trainer; no other stable master on the isle in the DB) |
| Orgrimmar / Thunder Bluff / Undercity | Xon'cha 9988 (70.36, 15.01) / Bulrug 10054 (45.09, 60.23) / Anya Maulray 10053 (67.42, 37.59) |
| The Barrens | Sikwa 9981, the Crossroads 51.74, 29.66; Kelsuwa 9983, Camp Taurajo 45.30, 58.66; Reggifuz 10063, Ratchet 62.18, 39.21 |
| Stonetalon / Ashenvale / Silverpine / Hillsbrad | Gereck 10048, Sun Rock 47.93, 61.39 / Qeeju 15131, Splintertree 73.38, 61.02 / Sarah Goode 9979, the Sepulcher 43.45, 41.18 / Theodore Mont Claire 10057, Tarren Mill 62.31, 19.70 |
| Arathi / Badlands / Swamp / Stranglethorn | Tharlidun 9976, Hammerfall 73.93, 33.13 / Greth 10058, Kargath 3.66, 47.58 / Hekkru 10049, Stonard 45.56, 55.15 / Durik 16094, Grom'gol 31.87, 29.50; Grimestack 10060, Booty Bay 27.29, 77.22 |
| Thousand Needles / Desolace / Feralas / Tanaris | Awenasa 11117, Freewind Post 45.77, 51.07 / Aboda 11105, Shadowprey 24.90, 68.67 / Shyrka Wolfrunner 9986, Camp Mojache 74.49, 43.27 / Laziphus 9985, Gadgetzan 52.25, 28.00 |
| Hinterlands / Winterspring / Silithus / Riverglades | Huntsman Markhor 14741, Revantusk 79.16, 79.53 / Azzleby 11119, Everlook 60.39, 37.92 / Squire Leoren Mal'derath 15722, Cenarion Hold 49.30, 36.45 / Grik 256673 (58.16, 44.94), Tallow Sparksocket 260525 (78.40, 54.20) |

Ammunition (bowyers / gunsmiths with a Horde or neutral faction): Ghrawt 3165 (Razor Hill 52.98, 41.03),
Kennah Hawkseye 3078 (Bloodhoof 44.98, 61.97), Kaja 3322 (Orgrimmar 52.15, 62.13), Kuna Thunderhorn 3015
(Thunder Bluff 47.00, 45.70), Uthrok 3488 (the Crossroads 51.11, 29.06), Borand 9549 (Sun Rock 45.36, 59.10),
Nadia Vernon 9553 (the Sepulcher 45.01, 39.30), Starn 9551 (Freewind Post 44.89, 50.68), Mu'uta 9555
(Hammerfall 72.52, 33.35), Zanara 9552 (Brackenwall 35.50, 30.09), Cawind Trueaim 9548 (Camp Mojache 74.94,
45.71), Blizrik Buckshot 8131 (Gadgetzan 50.74, 27.53), Haren Kanmae 2839 (Booty Bay 28.31, 74.56), Narianna
12029 (Moonglade), Wixxrak 11184 (Everlook). General goods vendors also sell arrows and bullets (C). Zephras
Isle: only weapon merchants and general goods in the DB (no bowyer sub-name). W: ammunition is still required.

### 6.4 Rogue: poison and reagent vendors

| Vendor | Where |
|---|---|
| Rekkul 3334 "Poison Vendor" | Orgrimmar, Cleft of Shadow 42.09, 49.48 (next to the rogue trainers) |
| Ezekiel Graves 4585 "Poison Vendor" | Undercity 75.20, 51.18 |
| Patrice Dwyer 3551 "Poison Supplies" | the Sepulcher, Silverpine 42.91, 41.81 |
| Smudge Thunderwood 6779 "Poison Vendor" | Ravenholdt Manor, Alterac 86.12, 79.58 |
| Sly Garrett 2622 "Shady Goods" | Booty Bay 28.41, 76.83 |
| Krikshank 260560 "Poison Vendor" | Riverglades 76.81, 51.17 (Forever-new, faction AH) |
| reagent vendors (flash powder etc., C) | Orgrimmar: Horthus 3323 (45.43, 56.55), Hagrus 3335 (45.99, 45.68), Magenius 3351 (45.74, 40.94); Thunder Bluff: Chepi 8361 (36.38, 54.85); Undercity: Hannah Akeley 4575 (82.78, 15.83), Thomas Mordan 4562 (69.69, 39.05); the Crossroads: Hula'mahi 3490 "Reagents and Herbs" (51.39, 30.20); Brackenwall: Balai Lok'Wein 13476; Camp Mojache: Tarhus 3500; Revantusk: Mystic Yayo'jin 14739; Cenarion Hold: Khur Hornstriker 15175 |

Vendor inventories are not in the DB. W: poisons are crafted by the rogue from vendor materials ("Shady
Dealers"); the skill is capped at 5 x level. No poison vendor in Thunder Bluff or on Zephras Isle in the DB.

### 6.5 Warlock: demon trainers

Sub-name "Demon Trainer" (vendor flag, no trainer flag: they sell grimoires, W): Hraug 12776 (Valley of Trials
40.56, 68.44), Kitha 6027 (Razor Hill 54.71, 41.50), Kurgul 5815 (Orgrimmar 47.52, 46.72), Kayla Smithe 5749
(Deathknell 30.81, 66.41), Gina Lang 5750 (Brill 61.55, 52.61), Martha Strain 5753 (Undercity 85.70, 16.08);
Greshka 12807 "Demon Master" (Stonard 48.58, 55.27). W: the start-camp ones sell only Imp and Voidwalker
grimoires. Use `vendor` steps (a `train` step is an ERROR). Summoning circles of the Binding quests: Orgrimmar
Cleft of Shadow (1454 49.4, 50.0) and the Undercity Magic Quarter.

### 6.6 Shaman totem quest givers, mage and priest services

* Totem quest NPCs (all in Appendix A): Canaga Earthcaller 5887 (Valley of Trials 42.4, 69.2), Seer Ravenfeather
  5888 (Camp Narache 44.4, 76.8), Windshaper Boro 251374 and Aetheen of the Gales 251366 (Thendal 42.8, 23.6),
  Kranal Fiss 5907 (1413 56.0, 19.9), Telf Joolam 5900 (1411 38.5, 59.0), Olariaan Swiftburn 268592 (2521 51.2,
  86.2), Sessaria Skystride 252382 (Valanaar 58.3, 78.5), Islen Waterseer 5901 (1413 65.8, 43.8; sells Water
  Sapta), Brine 5899 (1413 43.4, 77.4), Tiev Mordune 7007 (Silverpine 37.3, 44.1, Sapta refill), Prate
  Cloudseer 5905 (1441 53.5, 42.6); city breadcrumb givers Searn Firewarder 5892 (Orgrimmar 38.0, 37.7) and
  Xanis Flameweaver 5906 (Thunder Bluff 25.2, 20.5), hub givers Swart 3173 (Razor Hill) and Narm Skychaser 3066
  (Bloodhoof). Reincarnation needs an Ankh from reagent vendors (C).
* Portal trainers: 5.6. Wand vendors: Katis 5816 "Wand Merchant" (Orgrimmar 44.18, 48.44), Zane Bradford 5754
  "Wand Vendor" (Undercity 69.56, 26.94); none in Thunder Bluff in the DB.

---------------------------------------------------------------------------------------------------------------

## 7. Web check (November 2026): Forever class changes that touch a leveling route

Searches and page reads on 2026-11-10. Facts only, nothing copied; every item is a fan-site statement unless it
matches the DB. Icy Veins' Forever class-quest pages exist but returned HTTP 403 to the fetcher (not read).

| Topic | Finding | Source | Confidence |
|---|---|---|---|
| Launch | Forever went live on 4 November 2026; level cap 60 | [massivelyop.com](https://massivelyop.com/2026/11/04/world-of-warcraft-forever-launches-today-heres-an-overview-some-guidance-and-release-times/) | high |
| Skyborne factions and classes | High Order = Alliance (druid, hunter, mage, rogue, warrior); Windshaper = Horde (druid, hunter, rogue, shaman, warrior); start at Thendal, hub Valanaar, Horde skycutter to Thunder Bluff; Zephras leveling ends at about 12-14 | [warcrafttavern.com/forever/guides/skyborne](https://www.warcrafttavern.com/forever/guides/skyborne/) | matches the DB |
| Cat Form | quest chain at 20 through Moonglade, turned in at the druid trainer in Thunder Bluff (Horde); rewards Cat Form, Claw, Prowl, Rip. Skyborne middle part at the Avatar of Saeyleenan and the Stormrage Barrow Dens | [skyborne-druid-quests](https://www.warcrafttavern.com/forever/guides/skyborne-druid-quests/), [druid-leveling](https://www.warcrafttavern.com/forever/guides/druid-leveling/) | matches the DB (98340 ... 98362). A [Method guide](https://www.method.gg/wow-forever/wow-forever-druid-leveling-guide-and-talents) is reported (search summary only, page not read) to start the Skyborne chain on Zephras Isle: the DB says Turak in Thunder Bluff |
| Druid forms | Bear 10 (quest; Skyborne on Zephras), Teleport: Moonglade 10 (quest), Cure Poison 14 (quest), Aquatic 16 (quest), Cat 20 (quest), Travel 30 and Dire Bear 40 (trainer) | druid-leveling (above) | likely; Cure Poison / Aquatic for Skyborne contradict the DB masks |
| Druid spell levels | Shred rank 1 at 20 (was 22); Ferocious Bite gets a rank 1 at 24; Poised (passive) at 32; Lacerate is a talent; polearms learnable | [beta changes](https://www.warcrafttavern.com/forever/news/racial-class-ability-changes-in-the-wow-forever-beta/), [pre-launch changes](https://www.warcrafttavern.com/forever/news/wow-forever-pre-launch-class-changes-bug-fixes/) | likely |
| Warrior stances | Defensive Stance at 10 and Berserker Stance at 30 still come from class quests (level-10 quest names include Path of Defense, Ulag the Cleaver, The Skybreaker Bulwark; 30: The Affray; Whirlwind Weapon) | [warrior-leveling](https://www.warcrafttavern.com/forever/guides/warrior-leveling/) | matches the DB quests |
| Hunter pet | "Taming the Beast" at 10 per start zone (Durotar, Mulgore, Zephras Isle); ammunition still required; Auto Shot needs 0.5 s standing still; all traps share a 30 s cooldown | [hunter-leveling](https://www.warcrafttavern.com/forever/guides/hunter-leveling/), beta and pre-launch pages | matches the DB quests |
| Rogue | Poisons from the level-20 quest line (Horde: Shattered Salute -> Fizzule -> Hinott's Assistance; lockpicking of about 80 advised); Pick Lock from the trainer at 16; new: Shank at 24 (rank 2 at 44), Poised at 18; one-handed axes usable | [poisons](https://www.warcrafttavern.com/forever/guides/poisons/), [rogue-leveling](https://www.warcrafttavern.com/forever/guides/rogue-leveling/), pre-launch page | likely |
| Shaman totems | totems are still bag items from quests: Earth 3 (Skyborne) / 4, Fire 10, Water 20, Air 30; Skyborne get Earth and Fire on Zephras Isle; "Call of Air also gives the spec's weapon" (new chain); new spells Totemic Recall 20, Call of the Elements 20, Totemic Projection / Call 22, Call of the Ancestors 30 | [shaman-leveling](https://www.warcrafttavern.com/forever/guides/shaman-leveling/), skyborne page | matches the DB for Earth / Fire; the Air weapon chain is index-only in the DB (79358 - 79442): uncertain |
| Warlock demons | Imp 1, Voidwalker 10 (Orc / Troll: Gan'rul's Summons; Undead: Halgar's Summons), Succubus or Incubus 20 (Love Hurts in Orgrimmar, Hearts of the Lovers in the Undercity), Felhunter 30, Felsteed 40 by a short quest; demon trainers sell grimoires; Drain Soul can give a shard per tick (later reduced) | [warlock-leveling](https://www.warcrafttavern.com/forever/guides/warlock-leveling/), pre-launch page | matches the DB quests; confirms Troll use of the Orgrimmar chain against the DB mask |
| Priest racials | Troll: Hex of Weakness, Shadowguard; Undead: Touch of Weakness, Dark Sacrifice; taught by class quests at 10 and 20; Devouring Plague is a trainer spell at 20 | [priest-leveling](https://www.warcrafttavern.com/forever/guides/priest-leveling/) | uncertain (the DB still names the Undead level-20 quest "Devouring Plague") |
| Mage | class quests at 10 / 15 / 26 as in Classic; Teleport at 20, portals at 40, runes still needed; Frost Blast (24) added in the beta and removed before launch; wands need 0.5 s standing still | [mage-leveling](https://www.warcrafttavern.com/forever/guides/mage-leveling/), beta and pre-launch pages | likely |
| Paladin | Horde trainers named only in Deathknell, Brill, Bandarion Keep; Redemption from "A Lesson in Divinity" at 12; Summon Warhorse at 40 from class trainers; Righteous Fury at 10 | [paladin-leveling](https://www.warcrafttavern.com/forever/guides/paladin-leveling/), [class-trainers](https://www.warcrafttavern.com/forever/guides/class-trainers/), pre-launch page | trainer list contradicts the DB (0.2 item 5) |
| Class trainers | Orgrimmar: no druid, paladin; Thunder Bluff: no paladin, rogue, warlock; Undercity: no druid, hunter, paladin, shaman; hubs: Stonard (hunter, shaman, warlock, warrior), Grom'gol (hunter), Booty Bay (rogue), Camp Mojache and Moonglade (druid); start-camp trainers teach only up to level 6 | class-trainers (above) | matches the DB except paladin |
| Weapon skills | table 6.1; polearms at 20 for 1 gold; other skills 10 silver; weapon-specialisation racials removed | [weapon-trainers](https://www.warcrafttavern.com/forever/guides/weapon-trainers/), beta page | likely |
| Riding | level 40, 100 gold, universal skill from the own race's trainer; 60: 1 000 gold; Skyborne: Genn Fairweather on Zephras Isle; paladin and warlock by class quest / trainer | [riding](https://www.warcrafttavern.com/forever/guides/riding/), [method.gg mount guide](https://www.method.gg/wow-forever/how-to-get-a-mount-in-wow-forever-cost-requirement-and-mount-options) (21 October 2026) | likely; first-mount price unresolved |
| Costs | class training 1-60 totals about 206 gold (warlock less); learned spells are not placed on the bars automatically | pre-launch page | likely |
| Other systems | "Legacy" talents / perks are mentioned (free Righteous Fury, reagent economy, bartering discounts, talents up to 5 levels earlier in the beta); dual specialisation at 40 | pre-launch page, shaman-leveling, hunter-leveling | uncertain: account-wide perks could change costs and talent levels |

Not found on the web: anything about Skyborne Call of Water / Call of Air, the Tauren Cat Form middle part, the
new rogue chain (Syndicate Sabotage), The Eye of Bhossca, Okamache, or XP values of the new class quests.

---------------------------------------------------------------------------------------------------------------

## 8. Consequences for the plan (class phase)

### 8.1 Anchors the class files need

Start zones: startzones.md section 6 (Durotar, Mulgore) and routes.md 9.3 (Tirisfal, Zephras) list them. From
the class side the minimum per start path is: the turn-in that unlocks the letter (788 / 747 / 364 / 92461); a
visit of the start-camp trainers at 4 and at the last pass (level <= 6 only); every arrival at the second hub
(6, 8, 10, 12); the first capital arrival; and for Durotar the Far Watch Post step. Class-specific extras that
need a nearby base step with an id:

| Class | Needs an anchor at |
|---|---|
| Warrior | Thunder Ridge and Far Watch Post (Orc / Troll), Brill at 10 and Agamand Mills (Undead), Valanaar at 10 and Zaal Stormshield's camp (Skyborne) |
| Hunter | Razor Hill / Bloodhoof / Valanaar at 10 and the next capital arrival (Orgrimmar / Thunder Bluff); on Zephras the south-west loop (taming targets) |
| Rogue | first Orgrimmar arrival (Therzok) or first Undercity arrival (Mennet Carkad); the Silverpine road (Astor Hadren) |
| Shaman | start camp at 4 (3 on Zephras); Razor Hill / Bloodhoof at 10; Far Watch Post (Kranal Fiss is 550 yd west); Valanaar at 10 and the south coast of Zephras |
| Warlock | the 792 step of the Valley of Trials (class-filtered base step); Razor Hill at 10 and Orgrimmar (Skull Rock); Brill at 10 and the Undercity |
| Mage | Sen'jin at 10 (Durotar) or the Undercity before the Balnir Farmstead (Tirisfal) |
| Priest | Razor Hill / Brill at 5-6 and at 10; first capital arrival |
| Druid | Bloodhoof at 10, Thunder Bluff, Camp Taurajo (Tauren); as today for Skyborne |

Unified 12-22 path: explicit ids on every arrival at Orgrimmar, Thunder Bluff, the Undercity, Ratchet (Wrenix,
Islen Waterseer, Strahad, Fray Island), Camp Taurajo (Ruga at 20+, Brine trip, Lunaclaw), the Crossroads, Far
Watch Post, the Sludge Fen / Venture Co. tower if the path goes there, Malaka'jin and the Sepulcher.

22-60: the existing ids are enough with one exception (the Owen Thadd step of
`h-50-hinterlands-searing-steppes`, step 12 of the segment, has no id: the mage's 97286 needs it). The class
anchors named in section 5, all verified to exist:
`h-22-tb-start`, `h-22-org-fp`, `h-22-uc-fly`, `h-22-the-sepulcher-apothecary`, `h-22-offering-stone`,
`h-22-tarrenmill-arrive`, `h-24-tarrenmill-end`, `h-24-tb-hearth`, `h-24-tb-arrive`, `h-24-camp-taurajo`,
`h-24-gann-stonespire`, `h-25-fly-ratchet`, `h-24-ratchet-arrive`, `h-27-tb-arrive`, `h-28-skywatcher`,
`h-28-thunder-bluff`, `h-28-thunder-bluff-flight`, `h-28-dorn-plainstalker`, `h-31-tb-hearth`, `h-31-tb-fly`,
`h-31-org`, `h-31-uc-arrive`, `h-31-tarrenmill-arrive`, `h-33-tarrenmill-end`, `h-33-hammerfall-arrive`,
`h-34-uc-arrive`, `h-34-gromgol-arrive`, `h-34-booty-bay`, `h-37-org-arrive`, `h39-level-mannoroc`,
`h-40-org-arrive`, `h-38-orgrimmar-flight-master`, `h41-hearth-org`, `h-41-uc-arrive`,
`h-41-undercity-flight-master`, `h-44-uc-arrive`, `h-44-gromgol-arrive`, `h-44-stonard-arrive`,
`h-44-booty-bay`, `h46-ratchet-fm`, `h46-fly-freewind`, `h-50-org-arrive`, `h-50-uc-arrive`,
`h50-fly-tarrenmill`, `h52-fly-stonard`, `h-51-swamp-of-sorrows`, `h-51-stonard`, `h53-fly-uc`,
`h-53-org-arrive`, `h-53-archmage-xylem`, `h54-hearth-org`, `h-56-org-arrive`, `h-56-remains-of-trey`,
`h-57-bloodvenom-end`, `h-58-org-arrive`, `h-58-uc-arrive`, `h59-hearth-uc`, `h-60-end`.
If the shared ids are renamed when the segments move into `FastesBoooy_Guides`, freeze the new names before
the class agents start: an insert on a missing anchor is a load error.

### 8.2 Ownership boundaries seen from the class data

* `Classes/<Class>.lua` owns: the letter (one step per race, race filter), class quest chains, class training,
  weapon-skill steps (class-specific choices), class mounts (warlock Felsteed, paladin Warhorse), pet / demon /
  portal / poison service steps.
* `Races/<Race>.lua` owns riding at 40 and must carry `classes` = everything except WARLOCK (all three warlock
  races) and PALADIN (Undead). The Tauren and Troll riding trips change the flight out of Orgrimmar at 40.04:
  they collide with class inserts on `h-40-org-arrive` (druid training trip to Thunder Bluff, warlock Ratchet
  stop). Decide the order of several inserts on one anchor (class before race or the reverse) centrally.
* Path agents own: the class filter on 792 (Durotar), and they must keep gates class-neutral (routes.md 10.2).
* Two class inserts never share a step, but two classes use the same NPCs as anchors (Turak, Zamah's cave,
  Gan'rul): the "no transient step before an accept at the same NPC" rule applies per composed route.
* Several chains span the unified 12-22 path and the 22-60 path (rogue Poisons, shaman Water, warlock Incubus,
  mage 1959-1962). The class agent needs the 12-22 anchors and the composed-route validation, not only a
  harness on one segment.

### 8.3 Validation from a class agent's seat

* One class file touches as many routes as the class has races (warrior 5; hunter, rogue, shaman 4; warlock,
  mage 3; priest, druid 2; paladin 1). Validation is cheap (`lua5.1 tools/validate_routes.lua -q --route
  <race>-<class> ...`, about 0.5 s per route); the simulator costs about 24 s per route, so 2 minutes for the
  warrior agent. Nothing in a class file affects other classes' routes as long as every inserted step carries
  `classes = { "<CLASS>" }`.
* Expected message noise per class file: `xp-unknown` for every Forever-new class quest (all Skyborne chains,
  Cat Form, Incubus, paladin), `quest-out-of-scope` for index-only quests, `train-not-class-trainer` for pet /
  portal / riding steps written as `train`. Agree on `manual` vs `train` and on the `-- WARN-OK` wording once.
* Hard blockers (ERROR) until the DB is supplemented: Troll warlock 1501 / 1504, Orc mage 1959 / 1960 / 1962,
  Skyborne druid 6126 - 6130 and 27 - 31. Options: (a) leave them out and describe them in a note (today's
  druid approach), (b) add a snapshot supplement mechanism that can be applied without the research inputs.

### 8.4 Open questions (cannot be settled from the DB or the web)

1. Do Alodan the Hopeful (Thunder Bluff) and Garen Largo (Undercity) really train paladins? (DB yes, W no.)
2. Can a Troll warlock take 1501 / 1504, an Orc mage 1959 - 1962 and 1943 - 1946, a Skyborne druid 6126 and 27?
3. What does the Undead priest's level-20 quest (5679 / 5644 / 5646) teach in Forever?
4. Where are the givers of the new shaman chain (79358 - 79442), the Skyborne Call of Air 96136 and the new
   rogue chain (96779 - 96786), and what do they reward?
5. Is there a Skyborne version of Call of Water? (DB: no; the Horde chain 1530 ... 96 has the mask "all Horde".)
6. Does a Skyborne warrior get Defensive Stance from 94003, and can he also do 1498 for XP?
7. XP of every Forever-new class quest (record with `/fb xp`).
8. Is the first mount included in the 100 gold of Apprentice Riding?
9. Which weapon skills do Skyborne characters start with?
10. Do the "Legacy" perks change training levels or costs enough to matter for the notes?

---------------------------------------------------------------------------------------------------------------

## Appendix A. Every Horde-available class quest below required level 58, per class

Generated from the DB (Appendix C). Included: quests whose class mask contains the class or whose sort is the
class sort (also with an empty class mask), available to at least one Horde race, required level below 58, not
raid-flagged, not seasonal, not the Dire Maul class books. Excluded on purpose: 792 Vile Familiars (class mask =
all but WARLOCK, a normal Durotar quest) and 5126 Lorax's Tale. Order: required level, then id. "Lvl (req)" =
quest level (required level); level -1 = scales. Races: "all Horde" = the five Horde races; "any" = mask 0;
"(+Alliance Skyborne)" = both Skyborne factions. Coordinates: first spawn, map percent. Objectives list up to two
drop sources per item with the mob level. XP: DB value and source; "unknown" = estimated by the validator.
Status: same / new / changed against Classic.

### A.WARRIOR (40 quests)

| ID | Quest | Lvl (req) | Races | Giver | Turn-in | Links | Objectives | XP | Status |
|---|---|---|---|---|---|---|---|---|---|
| 2383 | Simple Parchment | 1 (1) | Orc | Gornek (3143) Durotar 42.1, 68.3 | Frang (3153) Durotar 42.9, 69.4 | pre-any 788 | - | 40 (questie-classic) | same |
| 3065 | Simple Tablet | 1 (1) | Troll | Gornek (3143) Durotar 42.1, 68.3 | Frang (3153) Durotar 42.9, 69.4 | pre-any 788 | - | 40 (questie-classic) | same |
| 3091 | Simple Note | 1 (1) | Tauren | Grull Hawkwind (2980) Mulgore 44.5, 77.5 | Harutt Thunderhorn (3059) Mulgore 43.8, 76.7 | pre-any 747 | - | 40 (questie-classic) | same |
| 3095 | Simple Scroll | 1 (1) | Undead | Shadow Priest Sarvis (1569) Tirisfal Glades 30.8, 66.2 | Dannal Stern (2119) Tirisfal Glades 32.7, 65.6 | pre-any 364 | - | 40 (questie-classic) | same |
| 92532 | The Warrior's Path | 2 (2) | any | Rorian the Dayseeker (251361) Zephras Isle 42.0, 23.5 | Blademaster Ren (251964) Zephras Isle 43.6, 24.1 | pre-any 92461 | - | unknown | new |
| 1498 | Path of Defense | 10 (10) | all Horde | Uzzek (5810) The Barrens 61.4, 21.1 | Uzzek (5810) The Barrens 61.4, 21.1 | next 1502; excl 1819; breadcrumbs 1505 | item Singed Scale x5 [Thunder Lizard 3130 L9-10; Durotar 39.1, 30.1, Lightning Hide 3131 L10-11; Durotar 38.9, 25.3] | unknown | same |
| 1502 | Thun'grim Firegaze | 10 (10) | all Horde | Uzzek (5810) The Barrens 61.4, 21.1 | Thun'grim Firegaze (5878) The Barrens 57.2, 30.3 | pre-any 1498, 1819; next 1503 | - | 210 (questie-classic) | same |
| 1503 | Forged Steel | 10 (10) | all Horde | Thun'grim Firegaze (5878) The Barrens 57.2, 30.3 | Thun'grim Firegaze (5878) The Barrens 57.2, 30.3 | pre-any 1502 | item Forged Steel Bars x1 [object Stolen Iron Chest 58369; The Barrens 55.0, 26.6] | 840 (questie-classic) | same |
| 1505 | Veteran Uzzek | 10 (10) | all Horde | Torm Ragetotem (3041) Thunder Bluff 57.2, 87.4<br>Krang Stonehoof (3063) Mulgore 48.4, 63.7<br>Tarshaw Jaggedscar (3169) Durotar 54.2, 42.5<br>Sorek (3354) Orgrimmar 80.4, 32.4 | Uzzek (5810) The Barrens 61.4, 21.1 | next 1498; excl 1819; breadcrumb for 1498 | - | 85 (questie-classic) | same |
| 1818 | Speak with Dillinger | 10 (10) | all Horde | Austil de Mon (2131) Tirisfal Glades 61.9, 52.5<br>Baltus Fowler (4595) Undercity 47.4, 17.3 | Deathguard Dillinger (1496) Tirisfal Glades 58.2, 51.5 | next 1819; excl 1498; breadcrumb for 1819 | - | 85 (questie-classic) | same |
| 1819 | Ulag the Cleaver | 10 (10) | all Horde | Deathguard Dillinger (1496) Tirisfal Glades 58.2, 51.5 | Deathguard Dillinger (1496) Tirisfal Glades 58.2, 51.5 | next 1820; excl 1498; breadcrumbs 1818 | kill Ulag the Cleaver x1 (6390 L11; Tirisfal Glades 59.5, 48.3) | 840 (questie-classic) | same |
| 1820 | Speak with Coleman | 10 (10) | all Horde | Deathguard Dillinger (1496) Tirisfal Glades 58.2, 51.5 | Coleman Farthing (1500) Tirisfal Glades 61.7, 52.3 | pre-any 1498, 1819; next 1821; breadcrumb for 1821 | - | 210 (questie-classic) | same |
| 1821 | Agamand Heirlooms | 11 (10) | all Horde | Coleman Farthing (1500) Tirisfal Glades 61.7, 52.3 | Coleman Farthing (1500) Tirisfal Glades 61.7, 52.3 | pre-any 1498, 1819; next 1822; breadcrumbs 1820 | item Agamand Family Axe x1 [object Agamand Weapon Rack 105170; Tirisfal Glades 51.7, 25.7]; item Agamand Family Dagger x1 [object Agamand Weapon Rack 105171; Tirisfal Glades 51.9, 27.1]; item Agamand Family Mace x1 [object Agamand Weapon Rack 105172; Tirisfal Glades 52.7, 27.0]; item Agamand Family Sword x1 [object Agamand Weapon Rack 105169; Tirisfal Glades 52.7, 25.9] | 660 (questie-classic) | same |
| 1822 | Heirloom Weapon | 11 (10) | all Horde | Coleman Farthing (1500) Tirisfal Glades 61.7, 52.3 | Coleman Farthing (1500) Tirisfal Glades 61.7, 52.3 | pre-any 1821 | - | 880 (questie-classic) | same |
| 94003 | The Skybreaker Bulwark | 10 (10) | Skyborne (+Alliance Skyborne) | Seena Skybreaker (252377) Zephras Isle 59.9, 72.9 | Seena Skybreaker (252377) Zephras Isle 59.9, 72.9 | - | item Skybreaker Bulwark x1 [Zaal Stormshield 257196 L10; Zephras Isle 56.6, 50.4] | unknown | new |
| 1823 | Speak with Ruga | 20 (20) | all Horde | Torm Ragetotem (3041) Thunder Bluff 57.2, 87.4<br>Sorek (3354) Orgrimmar 80.4, 32.4<br>Baltus Fowler (4595) Undercity 47.4, 17.3 | Ruga Ragetotem (6394) The Barrens 44.7, 59.4 | next 1824; breadcrumb for 1824 | - | 155 (questie-classic) | same |
| 1824 | Trial at the Field of Giants | 20 (20) | all Horde | Ruga Ragetotem (6394) The Barrens 44.7, 59.4 | Ruga Ragetotem (6394) The Barrens 44.7, 59.4 | next 1825; breadcrumbs 1823 | item Twitching Antenna x5 [Silithid Creeper 3250 L20-21; The Barrens 42.1, 69.4, Silithid Grub 3251 L20; The Barrens 42.5, 69.6, +4 more] | 1550 (questie-classic) | same |
| 1825 | Speak with Thun'grim | 20 (20) | all Horde | Ruga Ragetotem (6394) The Barrens 44.7, 59.4 | Thun'grim Firegaze (5878) The Barrens 57.2, 30.3 | pre-any 1824; next 1838; breadcrumb for 1838 | - | 780 (questie-classic) | same |
| 1838 | Brutal Armor | 30 (20) | all Horde | Thun'grim Firegaze (5878) The Barrens 57.2, 30.3 | Thun'grim Firegaze (5878) The Barrens 57.2, 30.3 | pre-any 1824; next 1848; breadcrumbs 1825 | item Smoky Iron Ingot x15 [Windshear Vermin 3998 L20-21; Stonetalon Mountains 71.8, 60.3, Windshear Digger 3999 L21-22; Stonetalon Mountains 71.7, 60.8, +4 more]; item Powdered Azurite x10 [Hillsbrad Miner 2269 L26-27; Hillsbrad Foothills 27.0, 58.0]; item Iron Bar x10; item Vial of Phlogiston x1 [Roogug 6168 L28 1; instance] | 3650 (questie-classic) | same |
| 1839 | Ula'elek and the Brutal Gauntlets | 30 (20) | all Horde | Thun'grim Firegaze (5878) The Barrens 57.2, 30.3 | Ula'elek (6408) Durotar 56.3, 74.3 | pre-any 1848; next 1842; breadcrumb for 1842 | - | 1200 (questie-classic) | same |
| 1840 | Orm Stonehoof and the Brutal Helm | 30 (20) | all Horde | Thun'grim Firegaze (5878) The Barrens 57.2, 30.3 | Orm Stonehoof (6410) Thunder Bluff 39.0, 56.0 | pre-any 1848; next 1844; breadcrumb for 1844 | - | 1200 (questie-classic) | same |
| 1841 | Velora Nitely and the Brutal Legguards | 30 (20) | all Horde | Thun'grim Firegaze (5878) The Barrens 57.2, 30.3 | Velora Nitely (6411) Undercity 62.1, 39.1 | pre-any 1848; next 1846; breadcrumb for 1846 | - | 1200 (questie-classic) | same |
| 1842 | Satyr Hooves | 30 (20) | all Horde | Ula'elek (6408) Durotar 56.3, 74.3 | Ula'elek (6408) Durotar 56.3, 74.3 | pre-any 1848; next 1843; breadcrumbs 1839 | item Uncloven Satyr Hoof x7 [Xavian Rogue 3752 L29-30; Ashenvale 77.6, 46.2, Xavian Betrayer 3754 L28-29; Ashenvale 78.3, 45.6, +11 more] | 1200 (questie-classic) | same |
| 1843 | Brutal Gauntlets | 30 (20) | all Horde | Ula'elek (6408) Durotar 56.3, 74.3 | Ula'elek (6408) Durotar 56.3, 74.3 | pre-any 1842 | - | 1850 (questie-classic) | same |
| 1844 | Chimaeric Horn | 30 (20) | all Horde | Orm Stonehoof (6410) Thunder Bluff 39.0, 56.0 | Orm Stonehoof (6410) Thunder Bluff 39.0, 56.0 | pre-any 1848; next 1845; breadcrumbs 1840 | item Galvanized Horn x1 [Chimaera Matriarch 6167 L28; Stonetalon Mountains 33.6, 74.7] | 1200 (questie-classic) | same |
| 1845 | Brutal Helm | 30 (20) | all Horde | Orm Stonehoof (6410) Thunder Bluff 39.0, 56.0 | Orm Stonehoof (6410) Thunder Bluff 39.0, 56.0 | pre-any 1844 | - | 1850 (questie-classic) | same |
| 1846 | Dragonmaw Shinbones | 30 (20) | all Horde | Velora Nitely (6411) Undercity 62.1, 39.1 | Velora Nitely (6411) Undercity 62.1, 39.1 | pre-any 1848; next 1847; breadcrumbs 1841 | item Sturdy Dragonmaw Shinbone x8 [Dragonmaw Raider 1034 L26-27; Wetlands 39.5, 47.0, Dragonmaw Swamprunner 1035 L27-28; Wetlands 38.2, 45.9, +3 more] | 1200 (questie-classic) | same |
| 1847 | Brutal Legguards | 30 (20) | all Horde | Velora Nitely (6411) Undercity 62.1, 39.1 | Velora Nitely (6411) Undercity 62.1, 39.1 | pre-any 1846 | - | 1850 (questie-classic) | same |
| 1848 | Brutal Hauberk | 30 (20) | all Horde | Thun'grim Firegaze (5878) The Barrens 57.2, 30.3 | Thun'grim Firegaze (5878) The Barrens 57.2, 30.3 | pre-any 1838 | - | 3050 (questie-classic) | same |
| 1712 | Cyclonian | 40 (30) | any | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | pre-any 1791; next 1713; children 1714 | item Liferoot x8 [object Liferoot 2041; Alterac Mountains 9.0, 55.4; +11 maps, vendor Antonio Perelli 844, +4 vendors]; item Bloodscalp Tusk x30 [Bloodscalp Warrior 587 L33-34; Stranglethorn Vale 29.8, 21.6, Bloodscalp Scout 588 L34-35; Stranglethorn Vale 22.3, 13.1, +9 more]; item Essence of the Exile x1 | 2350 (questie-classic) | same |
| 1713 | The Summoning | 40 (30) | any | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | pre-any 1712; next 1792 | item Whirlwind Heart x1 [Cyclonian 6239 L40 1; Alterac Mountains 80.3, 62.1] | 2350 (questie-classic) | same |
| 1714 | Essence of the Exile | 37 (30) | any | object Bath'rah's Cauldron (89931) Alterac Mountains 79.3, 66.8 | object Bath'rah's Cauldron (89931) Alterac Mountains 79.3, 66.8 | parent 1712; special 1 | item Thundering Charm x8 [Drywhisker Kobold 2572 L35-36; Arathi Highlands 76.0, 44.4, Drywhisker Surveyor 2573 L37-38; Arathi Highlands 83.1, 33.0, +2 more]; item Burning Charm x8 [Drywhisker Kobold 2572 L35-36; Arathi Highlands 76.0, 44.4, Drywhisker Surveyor 2573 L37-38; Arathi Highlands 83.1, 33.0, +2 more]; item Cresting Charm x8 [Drywhisker Kobold 2572 L35-36; Arathi Highlands 76.0, 44.4, Drywhisker Surveyor 2573 L37-38; Arathi Highlands 83.1, 33.0, +2 more] | unknown | same |
| 1718 | The Islander | 30 (30) | any | Torm Ragetotem (3041) Thunder Bluff 57.2, 87.4<br>Sorek (3354) Orgrimmar 80.4, 32.4<br>Baltus Fowler (4595) Undercity 47.4, 17.3 | Klannoc Macleod (6236) The Barrens 68.6, 49.2 | next 1719 | - | 610 (questie-classic) | same |
| 1719 | The Affray | 30 (30) | any | Klannoc Macleod (6236) The Barrens 68.6, 49.2 | Klannoc Macleod (6236) The Barrens 68.6, 49.2 | pre-any 1718; next 1791; special 2 | kill Big Will x1 (6238 L33; The Barrens 68.6, 48.7); scripted event; area trigger The Barrens 68.6, 48.7 | 2450 (questie-classic) | same |
| 1791 | The Windwatcher | 30 (30) | any | Klannoc Macleod (6236) The Barrens 68.6, 49.2 | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | pre-any 1719; next 1712 | - | 245 (questie-classic) | same |
| 1792 | Whirlwind Weapon | 40 (30) | any | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | pre-any 1713 | - | 3900 (questie-classic) | same |
| 8417 | A Troubled Spirit | 50 (50) | any | Torm Ragetotem (3041) Thunder Bluff 57.2, 87.4<br>Sorek (3354) Orgrimmar 80.4, 32.4<br>Christoph Walker (4593) Undercity 46.9, 15.2 | Fallen Hero of the Horde (7572) Swamp of Sorrows 34.3, 66.1 | next 8423; breadcrumb for 8423 | - | 470 (questie-classic) | same |
| 8423 | Warrior Kinship | 52 (50) | any | Fallen Hero of the Horde (7572) Swamp of Sorrows 34.3, 66.1 | Fallen Hero of the Horde (7572) Swamp of Sorrows 34.3, 66.1 | next 8424; breadcrumbs 8417 | kill Helboar x7 (5993 L52-53; Blasted Lands 44.6, 33.4) | 5100 (questie-classic) | same |
| 8424 | War on the Shadowsworn | 52 (50) | any | Fallen Hero of the Horde (7572) Swamp of Sorrows 34.3, 66.1 | Fallen Hero of the Horde (7572) Swamp of Sorrows 34.3, 66.1 | pre-any 8423; next 8425 | kill Shadowsworn Adept x20 (6006 L52-53; Blasted Lands 61.8, 41.1); kill Shadowsworn Cultist x10 (6004 L51-52; Blasted Lands 61.8, 42.1); kill Shadowsworn Thug x20 (6005 L52-53; Blasted Lands 62.6, 40.8) | 5100 (questie-classic) | same |
| 8425 | Voodoo Feathers | 52 (50) | any | Fallen Hero of the Horde (7572) Swamp of Sorrows 34.3, 66.1 | Fallen Hero of the Horde (7572) Swamp of Sorrows 34.3, 66.1 | pre-any 8424 | item Amber Voodoo Feather x2 [Gasher 5713 L51 1; instance, Zul'Lor 5716 L52 1; instance, +3 more]; item Blue Voodoo Feather x2 [Hukku 5715 L52 1; instance, Mijan 5717 L52 1; instance, +4 more]; item Green Voodoo Feather x2 [Zolo 5712 L51 1; instance, Loro 5714 L51 1; instance, +2 more] | 6350 (questie-classic) | same |

### A.HUNTER (27 quests)

| ID | Quest | Lvl (req) | Races | Giver | Turn-in | Links | Objectives | XP | Status |
|---|---|---|---|---|---|---|---|---|---|
| 3082 | Etched Tablet | 1 (1) | Troll | Gornek (3143) Durotar 42.1, 68.3 | Jen'shan (3154) Durotar 42.8, 69.3 | pre-any 788 | - | 40 (questie-classic) | same |
| 3087 | Etched Parchment | 1 (1) | Orc | Gornek (3143) Durotar 42.1, 68.3 | Jen'shan (3154) Durotar 42.8, 69.3 | pre-any 788 | - | 40 (questie-classic) | same |
| 3092 | Etched Note | 1 (1) | Tauren | Grull Hawkwind (2980) Mulgore 44.5, 77.5 | Lanka Farshot (3061) Mulgore 44.0, 76.3 | pre-any 747 | - | 60 (questie-classic) | same |
| 92482 | The Way of the Hunter | 2 (2) | any | Rorian the Dayseeker (251361) Zephras Isle 42.0, 23.5 | Tai'ree Farsight (251376) Zephras Isle 42.5, 23.8 | pre-any 92461 | - | unknown | new |
| 6061 | Taming the Beast | 10 (10) | Tauren | Yaw Sharpmane (3065) Mulgore 46.9, 59.6 | Yaw Sharpmane (3065) Mulgore 46.9, 59.6 | next 6087; breadcrumbs 6065, 6066, 6067 | use on Adult Plainstrider x1 (2956 L6-8; Mulgore 34.8, 39.1) | 840 (questie-classic) | same |
| 6062 | Taming the Beast | 10 (10) | Orc/Troll | Thotar (3171) Durotar 51.9, 43.5 | Thotar (3171) Durotar 51.9, 43.5 | next 6083; breadcrumbs 6068, 6069, 6070 | use on Dire Mottled Boar x1 (3099 L6-7; Durotar 38.1, 35.9) | 840 (questie-classic) | same |
| 6065 | The Hunter's Path | 10 (10) | Tauren | Kary Thunderhorn (3038) Thunder Bluff 58.5, 88.3 | Yaw Sharpmane (3065) Mulgore 46.9, 59.6 | next 6061; excl 6066, 6067; breadcrumb for 6061 | - | 85 (questie-classic) | same |
| 6066 | The Hunter's Path | 10 (10) | Tauren | Sian'dur (3407) Orgrimmar 68.0, 17.8 | Yaw Sharpmane (3065) Mulgore 46.9, 59.6 | next 6061; excl 6065, 6067; breadcrumb for 6061 | - | 85 (questie-classic) | same |
| 6067 | The Hunter's Path | 10 (10) | Tauren | Thotar (3171) Durotar 51.9, 43.5 | Yaw Sharpmane (3065) Mulgore 46.9, 59.6 | next 6061; excl 6065, 6066; breadcrumb for 6061 | - | 85 (questie-classic) | same |
| 6068 | The Hunter's Path | 10 (10) | Orc/Troll | Sian'dur (3407) Orgrimmar 68.0, 17.8 | Thotar (3171) Durotar 51.9, 43.5 | next 6062; excl 6069, 6070; breadcrumb for 6062 | - | 85 (questie-classic) | same |
| 6069 | The Hunter's Path | 10 (10) | Orc/Troll | Kali Remik (11814) Durotar 56.1, 74.2 | Thotar (3171) Durotar 51.9, 43.5 | next 6062; excl 6068, 6070; breadcrumb for 6062 | - | 85 (questie-classic) | same |
| 6070 | The Hunter's Path | 10 (10) | Orc/Troll | Kary Thunderhorn (3038) Thunder Bluff 58.5, 88.3 | Thotar (3171) Durotar 51.9, 43.5 | next 6062; excl 6068, 6069; breadcrumb for 6062 | - | 85 (questie-classic) | same |
| 6081 | Training the Beast | 10 (10) | Orc/Troll | Thotar (3171) Durotar 51.9, 43.5 | Ormak Grimshot (3352) Orgrimmar 66.0, 18.5 | pre-any 6082 | - | 420 (questie-classic) | same |
| 6082 | Taming the Beast | 10 (10) | Orc/Troll | Thotar (3171) Durotar 51.9, 43.5 | Thotar (3171) Durotar 51.9, 43.5 | pre-any 6083; next 6081 | use on Armored Scorpid x1 (3126 L7-8; Durotar 35.7, 36.9) | 840 (questie-classic) | same |
| 6083 | Taming the Beast | 10 (10) | Orc/Troll | Thotar (3171) Durotar 51.9, 43.5 | Thotar (3171) Durotar 51.9, 43.5 | pre-any 6062; next 6082 | use on Surf Crawler x1 (3107 L7-8; Durotar 58.3, 83.5) | 840 (questie-classic) | same |
| 6087 | Taming the Beast | 10 (10) | Tauren | Yaw Sharpmane (3065) Mulgore 46.9, 59.6 | Yaw Sharpmane (3065) Mulgore 46.9, 59.6 | pre-any 6061; next 6088 | use on Prairie Stalker x1 (2959 L7-8; Mulgore 35.2, 37.1; +1 maps) | 840 (questie-classic) | same |
| 6088 | Taming the Beast | 10 (10) | Tauren | Yaw Sharpmane (3065) Mulgore 46.9, 59.6 | Yaw Sharpmane (3065) Mulgore 46.9, 59.6 | pre-any 6087; next 6089 | use on Swoop x1 (2970 L7-9; Mulgore 36.1, 48.9) | 840 (questie-classic) | same |
| 6089 | Training the Beast | 10 (10) | Tauren | Yaw Sharpmane (3065) Mulgore 46.9, 59.6 | Holt Thunderhorn (3039) Thunder Bluff 57.3, 89.8 | pre-any 6088 | - | 420 (questie-classic) | same |
| 94007 | Taming the Beast | 10 (10) | Skyborne (+Alliance Skyborne) | Elayaa Easewind (254084) Zephras Isle 45.3, 44.2 | Quel'ana Quickgale (252389) Zephras Isle 59.6, 72.6 | - | - | unknown | new |
| 94013 | Taming the Beast | 10 (10) | Skyborne (+Alliance Skyborne) | Quel'ana Quickgale (252389) Zephras Isle 59.6, 72.6 | Quel'ana Quickgale (252389) Zephras Isle 59.6, 72.6 | pre-any 94979; next 94050 | use on Vuldren Alpha x1 (250874 L10; Zephras Isle 44.1, 65.6) | unknown | new |
| 94050 | Training the Beast | 10 (10) | Skyborne (+Alliance Skyborne) | Quel'ana Quickgale (252389) Zephras Isle 59.6, 72.6 | Quel'dora Quickgale (254411) Zephras Isle 59.9, 72.9 | pre-any 94013 | - | unknown | new |
| 94978 | Taming the Beast | 10 (10) | Skyborne (+Alliance Skyborne) | Quel'ana Quickgale (252389) Zephras Isle 59.6, 72.6 | Quel'ana Quickgale (252389) Zephras Isle 59.6, 72.6 | next 94979 | use on Windsong Crawler x1 (254588 L8-9; Zephras Isle 43.1, 65.7) | unknown | new |
| 94979 | Taming the Beast | 10 (10) | Skyborne (+Alliance Skyborne) | Quel'ana Quickgale (252389) Zephras Isle 59.6, 72.6 | Quel'ana Quickgale (252389) Zephras Isle 59.6, 72.6 | pre-any 94978; next 94013 | use on Ornery Galestrider x1 (251707 L8-9; Zephras Isle 45.7, 81.0) | unknown | new |
| 8151 | The Hunter's Charm | 52 (50) | any | Holt Thunderhorn (3039) Thunder Bluff 57.3, 89.8<br>Ormak Grimshot (3352) Orgrimmar 66.0, 18.5 | Ogtinc (8405) Azshara 42.4, 42.6 | next 8153 | - | 510 (questie-classic) | same |
| 8153 | Courser Antlers | 52 (50) | any | Ogtinc (8405) Azshara 42.4, 42.6 | Ogtinc (8405) Azshara 42.4, 42.6 | pre-any 8151; next 8231 | item Perfect Courser Antler x2 [Mosshoof Courser 8761 L52-53; Azshara 35.1, 65.9] | 5100 (questie-classic) | same |
| 8231 | Wavethrashing | 52 (50) | any | Ogtinc (8405) Azshara 42.4, 42.6 | Ogtinc (8405) Azshara 42.4, 42.6 | pre-any 8153; next 8232 | item Wavethrasher Scales x6 [Young Wavethrasher 6347 L51; Azshara 58.0, 9.9, Wavethrasher 6348 L52-53; Azshara 52.5, 42.0, +1 more] | 5100 (questie-classic) | same |
| 8232 | The Green Drake | 52 (50) | any | Ogtinc (8405) Azshara 42.4, 42.6 | Ogtinc (8405) Azshara 42.4, 42.6 | pre-any 8231 | item Tooth of Morphaz x1 [Morphaz 5719 L52 1; instance] | 6350 (questie-classic) | same |

### A.ROGUE (32 quests)

| ID | Quest | Lvl (req) | Races | Giver | Turn-in | Links | Objectives | XP | Status |
|---|---|---|---|---|---|---|---|---|---|
| 3083 | Encrypted Tablet | 1 (1) | Troll | Gornek (3143) Durotar 42.1, 68.3 | Rwag (3155) Durotar 41.3, 68.0 | pre-any 788 | - | 40 (questie-classic) | same |
| 3088 | Encrypted Parchment | 1 (1) | Orc | Gornek (3143) Durotar 42.1, 68.3 | Rwag (3155) Durotar 41.3, 68.0 | pre-any 788 | - | 40 (questie-classic) | same |
| 3096 | Encrypted Scroll | 1 (1) | Undead | Shadow Priest Sarvis (1569) Tirisfal Glades 30.8, 66.2 | David Trias (2122) Tirisfal Glades 32.5, 65.7 | pre-any 364 | - | 40 (questie-classic) | same |
| 92483 | At Home in the Shadows | 2 (2) | any | Rorian the Dayseeker (251361) Zephras Isle 42.0, 23.5 | Akeri Duskblade (251389) Zephras Isle 43.7, 24.4 | pre-any 92461 | - | unknown | new |
| 1858 | The Shattered Hand | 13 (10) | Orc/Troll | Therzok (6446) Orgrimmar 42.7, 53.5 | Therzok (6446) Orgrimmar 42.7, 53.5 | pre-any 1963 | item Tazan's Logbook x1 | 455 (questie-classic) | same |
| 1859 | Therzok | 10 (10) | Orc | Kaplak (3170) Durotar 52.0, 43.7 | Therzok (6446) Orgrimmar 42.7, 53.5 | next 1963; excl 1885; breadcrumb for 1963 | - | 210 (questie-classic) | same |
| 1885 | Mennet Carkad | 10 (10) | Undead | Marion Call (2130) Tirisfal Glades 61.8, 52.0 | Mennet Carkad (6467) Undercity 83.5, 69.1 | next 1886; excl 1859; breadcrumb for 1886 | - | 210 (questie-classic) | same |
| 1886 | The Deathstalkers | 13 (10) | Undead | Mennet Carkad (6467) Undercity 83.5, 69.1 | Mennet Carkad (6467) Undercity 83.5, 69.1 | next 1898; breadcrumbs 1885 | item Astor's Letter of Introduction x1 [Astor Hadren 6497 L13; Silverpine Forest 49.7, 32.2] | 680 (questie-classic) | same |
| 1898 | The Deathstalkers | 13 (10) | Undead | Mennet Carkad (6467) Undercity 83.5, 69.1 | Andron Gant (6522) Undercity 54.8, 76.3 | pre-any 1886; next 1899 | - | 230 (questie-classic) | same |
| 1899 | The Deathstalkers | 13 (10) | Undead | Andron Gant (6522) Undercity 54.8, 76.3 | Mennet Carkad (6467) Undercity 83.5, 69.1 | pre-any 1898; next 1978 | item Andron's Ledger x1 [object Andron's Bookshelf 103600; Undercity 55.4, 77.0] | 230 (questie-classic) | same |
| 1963 | The Shattered Hand | 13 (10) | Orc/Troll | Therzok (6446) Orgrimmar 42.7, 53.5 | Therzok (6446) Orgrimmar 42.7, 53.5 | next 1858; breadcrumbs 1859 | item Tazan's Satchel x1 [Tazan 6494 L13; The Barrens 63.1, 44.3] | 680 (questie-classic) | same |
| 1978 | The Deathstalkers | 13 (10) | Undead | Mennet Carkad (6467) Undercity 83.5, 69.1 | Varimathras (2425) Undercity 56.2, 92.2 | pre-any 1899 | - | 910 (questie-classic) | same |
| 1998 | Fenwick Thatros | 16 (16) | Undead | Mennet Carkad (6467) Undercity 83.5, 69.1 | Mennet Carkad (6467) Undercity 83.5, 69.1 | next 1999 | item Fenwick's Head x1 [Fenwick Thatros 6570 L16; Silverpine Forest 59.6, 33.9] | 880 (questie-classic) | same |
| 1999 | Tools of the Trade | 20 (16) | Undead | Mennet Carkad (6467) Undercity 83.5, 69.1 | Mennet Carkad (6467) Undercity 83.5, 69.1 | pre-any 1998 | item Dalaran Status Report x1 [object Ambermill Strongbox 103815; Silverpine Forest 63.7, 65.2] | 1550 (questie-classic) | same |
| 2378 | Find the Shattered Hand | 16 (16) | all Horde | Mennet Carkad (6467) Undercity 83.5, 69.1 | Shenthul (3401) Orgrimmar 43.0, 53.7 | excl 2380 | - | 115 (questie-classic) | same |
| 2379 | Zando'zan | 16 (16) | all Horde | Shenthul (3401) Orgrimmar 43.0, 53.7 | Zando'zan (3402) Orgrimmar 42.7, 53.0 | next 2382 | - | unknown | same |
| 2380 | To Orgrimmar! | 16 (16) | all Horde | Kaplak (3170) Durotar 52.0, 43.7 | Shenthul (3401) Orgrimmar 43.0, 53.7 | excl 2378 | - | 115 (questie-classic) | same |
| 2381 | Plundering the Plunderers | 18 (16) | all Horde | Wrenix the Wretched (7161) The Barrens 63.1, 36.3 | Wrenix the Wretched (7161) The Barrens 63.1, 36.3 | pre-any 2382 | item Southsea Treasure x1 [Polly 7168 L18; The Barrens 64.8, 45.5] | 1350 (questie-classic) | same |
| 2382 | Wrenix of Ratchet | 16 (16) | all Horde | Zando'zan (3402) Orgrimmar 42.7, 53.0 | Wrenix the Wretched (7161) The Barrens 63.1, 36.3 | pre-any 2379; next 2381 | - | 115 (questie-classic) | same |
| 2458 | Deep Cover | 20 (20) | all Horde | Shenthul (3401) Orgrimmar 43.0, 53.7 | Taskmaster Fizzule (7233) The Barrens 55.4, 5.6 | pre-any 2460; next 2478 | - | 1150 (questie-classic) | same |
| 2460 | The Shattered Salute | 20 (20) | all Horde | Shenthul (3401) Orgrimmar 43.0, 53.7 | Shenthul (3401) Orgrimmar 43.0, 53.7 | next 2458; special 2 | use on Shenthul x1 (3401 L60; Orgrimmar 43.0, 53.7) | 155 (questie-classic) | same |
| 2478 | Mission: Possible But Not Probable | 24 (20) | all Horde | Taskmaster Fizzule (7233) The Barrens 55.4, 5.6 | Shenthul (3401) Orgrimmar 43.0, 53.7 | pre-any 2458; next 2479 | kill Mutated Venture Co. Drone x2 (7310 L25; The Barrens 54.7, 5.7); kill Venture Co. Lookout x2 (7307 L23; The Barrens 54.6, 5.8); kill Venture Co. Patroller x2 (7308 L22; The Barrens 54.7, 5.7); item Gallywix's Head x1 [Grand Foreman Puzik Gallywix 7288 L23 1; The Barrens 54.8, 5.6]; item Silixiz's Tower Key x1 [Foreman Silixiz 7287 L22; The Barrens 54.8, 6.0]; item Cache of Zanzil's Altered Mixture x1 [object Gallywix's Lockbox 129127; The Barrens 54.8, 5.6] | 1950 (questie-classic) | same |
| 2479 | Hinott's Assistance | 26 (20) | all Horde | Shenthul (3401) Orgrimmar 43.0, 53.7 | Serge Hinott (2391) Hillsbrad Foothills 61.6, 19.2 | pre-any 2478; next 2480 | - | 1050 (questie-classic) | same |
| 2480 | Hinott's Assistance | 20 (20) | all Horde | Serge Hinott (2391) Hillsbrad Foothills 61.6, 19.2 | Serge Hinott (2391) Hillsbrad Foothills 61.6, 19.2 | pre-any 2479; special 2 | scripted event; area trigger Hillsbrad Foothills 61.6, 19.2 | 155 (questie-classic) | same |
| 6681 | The Manor, Ravenholdt | 24 (24) | any | item Elegant Letter (17126) | Fahrad (6707) Alterac Mountains 84.5, 80.3 | next 6701 | kill Ravenholdt x1 (13936 L1; Hillsbrad Foothills 78.6, 17.8) | 1950 (questie-classic) | same |
| 6701 | Syndicate Emblems | 60 (24) | any | Ravenholdt Guard (6766) Alterac Mountains 81.5, 76.9; Hillsbrad Foothills 77.2, 20.1 | Ravenholdt Guard (6766) Alterac Mountains 81.5, 76.9; Hillsbrad Foothills 77.2, 20.1 | pre-any 6681; special 1 | item Syndicate Emblem x1 [Syndicate Footpad 2240 L32-33; Alterac Mountains 47.7, 81.9, Syndicate Thief 2241 L33-34; Alterac Mountains 46.6, 81.5, +11 more] | unknown | same |
| 78676 | The Eye of Bhossca | 35 (25) | any | object Dead Drop (410369) Silverpine Forest 47.1, 71.0 | object Dead Drop (410369) Silverpine Forest 47.1, 71.0 | - | - | unknown | new |
| 78699 | The Eye of Bhossca | 35 (25) | any | - | object Dead Drop (410369) Silverpine Forest 47.1, 71.0 | - | - | unknown | new |
| 8233 | A Simple Request | 52 (50) | any | Ormok (3328) Orgrimmar 43.9, 54.6<br>Miles Dexter (4583) Undercity 85.2, 71.6 | Lord Jorach Ravenholdt (6768) Alterac Mountains 86.0, 78.9 | next 8234; breadcrumb for 8234 | - | 510 (questie-classic) | same |
| 8234 | Sealed Azure Bag | 52 (50) | any | Lord Jorach Ravenholdt (6768) Alterac Mountains 86.0, 78.9 | Archmage Xylem (8379) Azshara 29.2, 40.2 | next 8235; breadcrumbs 8233 | item Sealed Azure Bag x1 [Timbermaw Shaman 6188 L50-51; Azshara 38.4, 32.4, Blackmaw Shaman 237736 L0; no spawn] | 5100 (questie-classic) | same |
| 8235 | Encoded Fragments | 52 (50) | any | Archmage Xylem (8379) Azshara 29.2, 40.2 | Archmage Xylem (8379) Azshara 29.2, 40.2 | pre-any 8234; next 8236 | item Encoded Fragment x10 [Forest Ooze 8766 L52-53; Azshara 36.2, 67.9] | 5100 (questie-classic) | same |
| 8236 | The Azure Key | 52 (50) | any | Archmage Xylem (8379) Azshara 29.2, 40.2 | Lord Jorach Ravenholdt (6768) Alterac Mountains 86.0, 78.9 | pre-any 8235 | item Azure Key x1 [Morphaz 5719 L52 1; instance] | 6350 (questie-classic) | same |

### A.SHAMAN (49 quests)

| ID | Quest | Lvl (req) | Races | Giver | Turn-in | Links | Objectives | XP | Status |
|---|---|---|---|---|---|---|---|---|---|
| 3084 | Rune-Inscribed Tablet | 1 (1) | Troll | Gornek (3143) Durotar 42.1, 68.3 | Shikrik (3157) Durotar 42.4, 69.0 | pre-any 788 | - | 40 (questie-classic) | same |
| 3089 | Rune-Inscribed Parchment | 1 (1) | Orc | Gornek (3143) Durotar 42.1, 68.3 | Shikrik (3157) Durotar 42.4, 69.0 | pre-any 788 | - | 40 (questie-classic) | same |
| 3093 | Rune-Inscribed Note | 1 (1) | Tauren | Grull Hawkwind (2980) Mulgore 44.5, 77.5 | Meela Dawnstrider (3062) Mulgore 44.6, 76.6 | pre-any 747 | - | 60 (questie-classic) | same |
| 92484 | Embracing the Elements | 2 (2) | all Horde | Rorian the Dayseeker (251361) Zephras Isle 42.0, 23.5 | Windshaper Boro (251374) Zephras Isle 42.8, 23.6 | pre-any 92461 | - | unknown | new |
| 92466 | Call of Earth | 4 (3) | all Horde | Windshaper Boro (251374) Zephras Isle 42.8, 23.6 | Windshaper Boro (251374) Zephras Isle 42.8, 23.6 | next 92467; excl 1516, 1519 | item Signet of Akir x1 [Al'Aketh Brute 251145 L4; Zephras Isle 35.5, 33.4, Al'Aketh Convert 251160 L2-3; Zephras Isle 43.8, 24.1, +6 more] | unknown | new |
| 92467 | Call of Earth | 4 (3) | all Horde | Aetheen of the Gales (251366) Zephras Isle 42.8, 23.7<br>Windshaper Boro (251374) Zephras Isle 42.8, 23.6 | Minor Manifestation of Earth (251166) Zephras Isle 49.7, 23.8 | pre-any 1516, 1519, 92466; next 92468 | - | unknown | new |
| 92468 | Call of Earth | 4 (3) | all Horde | Minor Manifestation of Earth (251166) Zephras Isle 49.7, 23.8 | Windshaper Boro (251374) Zephras Isle 42.8, 23.6 | pre-any 92467 | - | unknown | new |
| 1462 | Earth Sapta | 4 (4) | all Horde | Seer Ravenfeather (5888) Mulgore 44.4, 76.8 | Seer Ravenfeather (5888) Mulgore 44.4, 76.8 | pre-any 1520; special 1 | - | unknown | same |
| 1463 | Earth Sapta | 4 (4) | all Horde | Canaga Earthcaller (5887) Durotar 42.4, 69.2 | Canaga Earthcaller (5887) Durotar 42.4, 69.2 | pre-any 1517; special 1 | - | unknown | same |
| 1516 | Call of Earth | 4 (4) | all Horde | Canaga Earthcaller (5887) Durotar 42.4, 69.2 | Canaga Earthcaller (5887) Durotar 42.4, 69.2 | pre-any 1516, 1519, 92466; next 1517; excl 1519, 92466 | item Felstalker Hoof x2 [Felstalker 3102 L3-4; Durotar 42.4, 54.2] | 270 (questie-classic) | same |
| 1517 | Call of Earth | 4 (4) | all Horde | Canaga Earthcaller (5887) Durotar 42.4, 69.2 | Minor Manifestation of Earth (5891) Durotar 44.0, 76.2; Mulgore 52.0, 80.4; +1 maps | pre-any 1516, 1519; next 1518 | - | 270 (questie-classic) | same |
| 1518 | Call of Earth | 4 (4) | all Horde | Minor Manifestation of Earth (5891) Durotar 44.0, 76.2; Mulgore 52.0, 80.4; +1 maps | Canaga Earthcaller (5887) Durotar 42.4, 69.2 | pre-any 1517 | - | 445 (questie-classic) | same |
| 1519 | Call of Earth | 4 (4) | all Horde | Seer Ravenfeather (5888) Mulgore 44.4, 76.8 | Seer Ravenfeather (5888) Mulgore 44.4, 76.8 | pre-any 1516, 1519, 92466; next 1520; excl 1516, 92466 | item Ritual Salve x2 [Bristleback Shaman 2953 L3-4; Mulgore 56.6, 78.3] | 270 (questie-classic) | same |
| 1520 | Call of Earth | 4 (4) | all Horde | Seer Ravenfeather (5888) Mulgore 44.4, 76.8 | Minor Manifestation of Earth (5891) Durotar 44.0, 76.2; Mulgore 52.0, 80.4; +1 maps | pre-any 1516, 1519; next 1521 | - | 180 (questie-classic) | same |
| 1521 | Call of Earth | 4 (4) | all Horde | Minor Manifestation of Earth (5891) Durotar 44.0, 76.2; Mulgore 52.0, 80.4; +1 maps | Seer Ravenfeather (5888) Mulgore 44.4, 76.8 | pre-any 1520; children 1462 | - | 445 (questie-classic) | same |
| 1464 | Fire Sapta | 13 (10) | all Horde | Telf Joolam (5900) Durotar 38.5, 59.0 | Telf Joolam (5900) Durotar 38.5, 59.0 | pre-any 1525; special 1 | - | unknown | same |
| 1522 | Call of Fire | 10 (10) | all Horde | Searn Firewarder (5892) Orgrimmar 38.0, 37.7 | Kranal Fiss (5907) The Barrens 56.0, 19.9 | next 1524; excl 1523, 2983, 2984; breadcrumb for 1524 | - | 420 (questie-classic) | same |
| 1523 | Call of Fire | 10 (10) | all Horde | Xanis Flameweaver (5906) Thunder Bluff 25.2, 20.5 | Kranal Fiss (5907) The Barrens 56.0, 19.9 | next 1524; excl 1522, 2983, 2984; breadcrumb for 1524 | - | 420 (questie-classic) | same |
| 1524 | Call of Fire | 11 (10) | all Horde | Kranal Fiss (5907) The Barrens 56.0, 19.9 | Telf Joolam (5900) Durotar 38.5, 59.0 | next 1525; breadcrumbs 1522, 1523, 2983, 2984 | - | 660 (questie-classic) | same |
| 1525 | Call of Fire | 12 (10) | all Horde | Telf Joolam (5900) Durotar 38.5, 59.0 | Telf Joolam (5900) Durotar 38.5, 59.0 | pre-any 1524; next 1526 | item Fire Tar x1 [Tunnel Rat Geomancer 1174 L12-13; Loch Modan 35.1, 23.9, Razormane Water Seeker 3267 L10-11; The Barrens 53.0, 25.1, +4 more]; item Reagent Pouch x1 [Stonesplinter Seer 1166 L13-14; Loch Modan 27.4, 85.5, Burning Blade Cultist 3199 L10-11; Durotar 51.9, 25.7] | 910 (questie-classic) | same |
| 1526 | Call of Fire | 13 (10) | all Horde | Telf Joolam (5900) Durotar 38.5, 59.0 | object Brazier of the Dormant Flame (61934) Durotar 39.0, 58.2; Loch Modan 31.8, 64.5 | pre-any 1525; next 1527 | item Glowing Ember x1 [Minor Manifestation of Fire 5893 L12; Durotar 38.7, 58.3; +1 maps, Manifestation of Flames 268763 L12; Zephras Isle 50.0, 85.0] | 1150 (questie-classic) | same |
| 1527 | Call of Fire | 13 (10) | all Horde | object Brazier of the Dormant Flame (61934) Durotar 39.0, 58.2; Loch Modan 31.8, 64.5 | Kranal Fiss (5907) The Barrens 56.0, 19.9 | pre-any 1526 | - | 1150 (questie-classic) | same |
| 2983 | Call of Fire | 10 (10) | all Horde | Swart (3173) Durotar 54.4, 42.6 | Kranal Fiss (5907) The Barrens 56.0, 19.9 | next 1524; excl 1522, 1523, 2984; breadcrumb for 1524 | - | 420 (questie-classic) | same |
| 2984 | Call of Fire | 10 (10) | all Horde | Narm Skychaser (3066) Mulgore 47.4, 62.5 | Kranal Fiss (5907) The Barrens 56.0, 19.9 | next 1524; excl 1522, 1523, 2983; breadcrumb for 1524 | - | 420 (questie-classic) | same |
| 97243 | Call of Fire | 10 (10) | Skyborne | Sessaria Skystride (252382) Zephras Isle 58.3, 78.5<br>Aarnor Galestrike (254082) Zephras Isle 43.5, 44.9 | Olariaan Swiftburn (268592) Zephras Isle 51.2, 86.2 | next 97244 | - | unknown | new |
| 97244 | Call of Fire | 10 (10) | Skyborne | Olariaan Swiftburn (268592) Zephras Isle 51.2, 86.2 | Olariaan Swiftburn (268592) Zephras Isle 51.2, 86.2 | pre-any 97243; next 97245 | item Faladiel's Heart x1 [Skypriest Faladiel 268602 L10; Zephras Isle 64.4, 63.7] | unknown | new |
| 97245 | Call of Fire | 10 (10) | Skyborne | Olariaan Swiftburn (268592) Zephras Isle 51.2, 86.2 | Olariaan Swiftburn (268592) Zephras Isle 51.2, 86.2 | pre-any 97244; next 97257 | item Kuramaa's Mask x1 [Kuramaa 268605 L10; Zephras Isle 42.4, 68.8] | unknown | new |
| 97257 | Call of Fire | 10 (10) | Skyborne | Olariaan Swiftburn (268592) Zephras Isle 51.2, 86.2 | Sessaria Skystride (252382) Zephras Isle 58.3, 78.5 | pre-any 97245 | event Brazier of Offering x1 (268762 L1; Zephras Isle 51.2, 85.9); event Brazier of Eternal Flame x1 (268679 L1; Zephras Isle 58.4, 78.8) | unknown | new |
| 98517 | Call of Fire | 10 (10) | Skyborne; no class mask | Swart (3173) Durotar 54.4, 42.6 | Sessaria Skystride (252382) Zephras Isle 58.3, 78.5 | - | item Torch of the Dormant Flame x1 | unknown | new |
| 63 | Call of Water | 23 (20) | all Horde | Islen Waterseer (5901) The Barrens 65.8, 43.8 | object Brazier of Everfount (113791) Silverpine Forest 38.3, 44.6 | pre-any 220; next 100 | item Corrupt Manifestation's Bracers x1 [Corrupt Minor Manifestation of Water 5894 L22; Silverpine Forest 38.8, 44.3] | 1400 (questie-classic) | same |
| 96 | Call of Water | 23 (20) | all Horde | Minor Manifestation of Water (5895) Silverpine Forest 38.6, 44.6 | Islen Waterseer (5901) The Barrens 65.8, 43.8 | pre-any 100 | - | 2750 (questie-classic) | same |
| 100 | Call of Water | 23 (20) | all Horde | object Brazier of Everfount (113791) Silverpine Forest 38.3, 44.6 | Minor Manifestation of Water (5895) Silverpine Forest 38.6, 44.6 | pre-any 63; next 96 | - | 1400 (questie-classic) | same |
| 220 | Call of Water | 23 (20) | all Horde | Brine (5899) The Barrens 43.4, 77.4 | Islen Waterseer (5901) The Barrens 65.8, 43.8 | pre-any 1534 | - | 460 (questie-classic) | same |
| 972 | Water Sapta | 20 (20) | all Horde | Islen Waterseer (5901) The Barrens 65.8, 43.8 | Islen Waterseer (5901) The Barrens 65.8, 43.8 | pre-any 220; special 1 | - | unknown | same |
| 1103 | Call of Water | 23 (20) | all Horde | Tiev Mordune (7007) Silverpine Forest 37.3, 44.1 | Tiev Mordune (7007) Silverpine Forest 37.3, 44.1 | pre-any 63; special 1 | item Water Sapta x1 [vendor Islen Waterseer 5901] | unknown | same |
| 1528 | Call of Water | 20 (20) | all Horde | Searn Firewarder (5892) Orgrimmar 38.0, 37.7 | Islen Waterseer (5901) The Barrens 65.8, 43.8 | next 1530; excl 1529, 2985, 2986; breadcrumb for 1530 | - | 780 (questie-classic) | same |
| 1529 | Call of Water | 20 (20) | all Horde | Xanis Flameweaver (5906) Thunder Bluff 25.2, 20.5 | Islen Waterseer (5901) The Barrens 65.8, 43.8 | next 1530; excl 1528, 2985, 2986; breadcrumb for 1530 | - | 780 (questie-classic) | same |
| 1530 | Call of Water | 22 (20) | all Horde | Islen Waterseer (5901) The Barrens 65.8, 43.8 | Brine (5899) The Barrens 43.4, 77.4 | next 1535; breadcrumbs 1528, 1529, 2985, 2986 | - | 435 (questie-classic) | same |
| 1534 | Call of Water | 23 (20) | all Horde | Brine (5899) The Barrens 43.4, 77.4 | Brine (5899) The Barrens 43.4, 77.4 | pre-any 1536; next 220 | item Filled Blue Waterskin x1 [object Ruins of Stardust Fountain 107047; Ashenvale 33.5, 67.5] | 1400 (questie-classic) | same |
| 1535 | Call of Water | 22 (20) | all Horde | Brine (5899) The Barrens 43.4, 77.4 | Brine (5899) The Barrens 43.4, 77.4 | pre-any 1530; next 1536 | item Filled Brown Waterskin x1 [object Quilboar Watering Hole 107046; The Barrens 44.3, 76.8] | 870 (questie-classic) | same |
| 1536 | Call of Water | 22 (20) | all Horde | Brine (5899) The Barrens 43.4, 77.4 | Brine (5899) The Barrens 43.4, 77.4 | pre-any 1535; next 1534 | item Filled Red Waterskin x1 [object Spring Well 107045; Hillsbrad Foothills 62.2, 20.8] | 1300 (questie-classic) | same |
| 2985 | Call of Water | 20 (20) | all Horde | Swart (3173) Durotar 54.4, 42.6 | Islen Waterseer (5901) The Barrens 65.8, 43.8 | next 1530; excl 1528, 1529, 2986; breadcrumb for 1530 | - | 780 (questie-classic) | same |
| 2986 | Call of Water | 20 (20) | all Horde | Narm Skychaser (3066) Mulgore 47.4, 62.5 | Islen Waterseer (5901) The Barrens 65.8, 43.8 | next 1530; excl 1528, 1529, 2985; breadcrumb for 1530 | - | 780 (questie-classic) | same |
| 1531 | Call of Air | 30 (30) | all Horde | Searn Firewarder (5892) Orgrimmar 38.0, 37.7 | Prate Cloudseer (5905) Thousand Needles 53.5, 42.6 | excl 1532 | - | 2450 (questie-classic) | same |
| 1532 | Call of Air | 30 (30) | all Horde | Xanis Flameweaver (5906) Thunder Bluff 25.2, 20.5 | Prate Cloudseer (5905) Thousand Needles 53.5, 42.6 | excl 1531 | - | 2450 (questie-classic) | same |
| 8410 | Elemental Mastery | 50 (50) | all Horde | Beram Skychaser (3032) Thunder Bluff 22.0, 18.8<br>Sagorne Creststrider (13417) Orgrimmar 38.7, 35.9 | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | next 8412; excl 8411 | item Elemental Air x1 [Dust Devil 832 L18-19; Westfall 33.3, 49.3, Thundering Exile 2762 L38-39; Arathi Highlands 50.4, 50.8, +16 more]; item Elemental Fire x1 [Ambassador Infernus 2745 L42 1; Badlands 42.1, 28.9, Burning Exile 2760 L38-39; Arathi Highlands 24.4, 29.5, +40 more]; item Elemental Earth x1 [Rock Elemental 92 L39-40; Badlands 12.0, 34.3, Stone Fury 2258 L37 4; Alterac Mountains 64.7, 44.8, +41 more]; item Elemental Water x1 [Lesser Water Elemental 691 L36-37; Stranglethorn Vale 19.4, 22.3, Cresting Exile 2761 L38-39; Arathi Highlands 65.0, 29.8, +31 more] | 3550 (questie-classic) | same |
| 8411 | Mastering the Elements | 50 (50) | all Horde | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | next 8412; excl 8410 | item Elemental Air x1 [Dust Devil 832 L18-19; Westfall 33.3, 49.3, Thundering Exile 2762 L38-39; Arathi Highlands 50.4, 50.8, +16 more]; item Elemental Earth x1 [Rock Elemental 92 L39-40; Badlands 12.0, 34.3, Stone Fury 2258 L37 4; Alterac Mountains 64.7, 44.8, +41 more]; item Elemental Fire x1 [Ambassador Infernus 2745 L42 1; Badlands 42.1, 28.9, Burning Exile 2760 L38-39; Arathi Highlands 24.4, 29.5, +40 more]; item Elemental Water x1 [Lesser Water Elemental 691 L36-37; Stranglethorn Vale 19.4, 22.3, Cresting Exile 2761 L38-39; Arathi Highlands 65.0, 29.8, +31 more] | 3550 (questie-classic) | same |
| 8412 | Spirit Totem | 52 (50) | all Horde | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | pre-any 8410, 8411; next 8413 | item Bloodshot Spider Eye x8 [Carrion Vulture 1809 L50-52; Western Plaguelands 29.9, 54.7, Rotting Condor 1810 L53-55; no spawn, +5 more]; item Thick Black Claw x8 [Carrion Vulture 1809 L50-52; Western Plaguelands 29.9, 54.7, Rotting Condor 1810 L53-55; no spawn, +3 more] | 5100 (questie-classic) | same |
| 8413 | Da Voodoo | 52 (50) | all Horde | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | Bath'rah the Windwatcher (6176) Alterac Mountains 80.5, 66.9 | pre-any 8412 | item Amber Voodoo Feather x2 [Gasher 5713 L51 1; instance, Zul'Lor 5716 L52 1; instance, +3 more]; item Blue Voodoo Feather x2 [Hukku 5715 L52 1; instance, Mijan 5717 L52 1; instance, +4 more]; item Green Voodoo Feather x2 [Zolo 5712 L51 1; instance, Loro 5714 L51 1; instance, +2 more] | 6350 (questie-classic) | same |

### A.WARLOCK (59 quests)

| ID | Quest | Lvl (req) | Races | Giver | Turn-in | Links | Objectives | XP | Status |
|---|---|---|---|---|---|---|---|---|---|
| 1470 | Piercing the Veil | 3 (1) | all Horde | Venya Marthand (5667) Tirisfal Glades 31.0, 66.4 | Venya Marthand (5667) Tirisfal Glades 31.0, 66.4 | excl 1485 | item Rattlecage Skull x3 [Rattlecage Skeleton 1890 L2-3; Tirisfal Glades 31.0, 60.8] | 190 (questie-classic) | same |
| 1485 | Vile Familiars | 4 (1) | all Horde | Ruzan (5765) Durotar 42.6, 69.0 | Ruzan (5765) Durotar 42.6, 69.0 | next 1499; excl 1470 | item Vile Familiar Head x6 [Vile Familiar 3101 L3-4; Durotar 42.6, 54.6] | 355 (questie-classic) | same |
| 1499 | Vile Familiars | 4 (1) | all Horde | Ruzan (5765) Durotar 42.6, 69.0 | Zureetha Fargaze (3145) Durotar 42.9, 69.2 | pre-any 1470, 1485; next 794 | - | 35 (questie-classic) | same |
| 3090 | Tainted Parchment | 1 (1) | Orc | Gornek (3143) Durotar 42.1, 68.3 | Nartok (3156) Durotar 40.6, 68.5 | pre-any 788 | - | 40 (questie-classic) | same |
| 3099 | Tainted Scroll | 1 (1) | Undead | Shadow Priest Sarvis (1569) Tirisfal Glades 30.8, 66.2 | Maximillion (2126) Tirisfal Glades 30.9, 66.3 | pre-any 364 | - | 40 (questie-classic) | same |
| 98575 | Tainted Tablet | 1 (1) | Troll | Gornek (3143) Durotar 42.1, 68.3 | Nartok (3156) Durotar 40.6, 68.5 | pre-any 788 | - | unknown | new |
| 1471 | The Binding | 10 (10) | Undead | Carendin Halgar (5675) Undercity 85.1, 26.0 | Carendin Halgar (5675) Undercity 85.1, 26.0 | pre-any 1473 | kill Summoned Voidwalker x1 (5676 L10; Orgrimmar 49.4, 50.0; +1 maps) | 630 (questie-classic) | same |
| 1473 | Creature of the Void | 10 (10) | Undead | Carendin Halgar (5675) Undercity 85.1, 26.0 | Carendin Halgar (5675) Undercity 85.1, 26.0 | next 1471; breadcrumbs 1478 | item Egalin's Grimoire x1 [object Perrine's Chest 37098; Tirisfal Glades 51.1, 67.6] | 630 (questie-classic) | same |
| 1478 | Halgar's Summons | 10 (10) | all Horde | Ageron Kargal (5724) Tirisfal Glades 61.6, 52.7 | Carendin Halgar (5675) Undercity 85.1, 26.0 | next 1473; breadcrumb for 1473 | - | 210 (questie-classic) | same |
| 1501 | Creature of the Void | 11 (10) | Orc | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | next 1504; breadcrumbs 1506 | item Tablet of Verga x1 [object Burning Blade Stash 58595; Durotar 51.6, 9.8] | 880 (questie-classic) | same |
| 1504 | The Binding | 11 (10) | Orc | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | pre-any 1501 | kill Summoned Voidwalker x1 (5676 L10; Orgrimmar 49.4, 50.0; +1 maps) | 660 (questie-classic) | same |
| 1506 | Gan'rul's Summons | 10 (10) | all Horde | Ophek (3294) Durotar 54.4, 41.3 | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | next 1501; breadcrumb for 1501 | - | 210 (questie-classic) | same |
| 1472 | Devourer of Souls | -1 (20) | all Horde | Carendin Halgar (5675) Undercity 85.1, 26.0 | Godrick Farsan (5693) Undercity 84.8, 14.8 | next 1476; excl 1507 | - | 155 (questie-classic) | same |
| 1474 | The Binding | 20 (20) | all Horde | Carendin Halgar (5675) Undercity 85.1, 26.0 | Carendin Halgar (5675) Undercity 85.1, 26.0 | pre-any 1476; excl 1507 | kill Summoned Succubus x1 (5677 L20; Orgrimmar 49.4, 50.0; +1 maps) | 1550 (questie-classic) | same |
| 1476 | Hearts of the Pure | -1 (20) | all Horde | Godrick Farsan (5693) Undercity 84.8, 14.8 | Carendin Halgar (5675) Undercity 85.1, 26.0 | pre-any 1472; next 1474; excl 1507 | item Dalin's Heart x1 [Dalin Forgewright 5682 L20; Silverpine Forest 47.6, 85.7]; item Comar's Heart x1 [Comar Villard 5683 L22; Wetlands 49.9, 12.6] | 1550 (questie-classic) | same |
| 1507 | Devourer of Souls | -1 (20) | all Horde | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | Cazul (5909) Orgrimmar 47.1, 46.4 | next 1508; excl 1472 | - | 155 (questie-classic) | same |
| 1508 | Blind Cazul | -1 (20) | all Horde | Cazul (5909) Orgrimmar 47.1, 46.4 | Zankaja (5910) Orgrimmar 37.0, 59.5 | pre-any 1507; next 1509; excl 1472 | - | 390 (questie-classic) | same |
| 1509 | News of Dogran | 20 (20) | all Horde | Zankaja (5910) Orgrimmar 37.0, 59.5 | Gazrog (3464) The Barrens 51.9, 30.3 | pre-any 1508; next 1510; excl 1472 | - | 390 (questie-classic) | same |
| 1510 | News of Dogran | 20 (20) | all Horde | Gazrog (3464) The Barrens 51.9, 30.3 | Ken'zigla (4197) Stonetalon Mountains 73.2, 95.1 | pre-any 1509; next 1511; excl 1472 | - | 780 (questie-classic) | same |
| 1511 | Ken'zigla's Draught | 20 (20) | all Horde | Ken'zigla (4197) Stonetalon Mountains 73.2, 95.1 | Grunt Logmar (5911) The Barrens 44.6, 59.3 | pre-any 1510; next 1515; excl 1472 | - | 1550 (questie-classic) | same |
| 1512 | Love's Gift | 20 (20) | all Horde | Grunt Dogran (5908) The Barrens 43.3, 47.9 | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | pre-any 1515; next 1513; excl 1472 | - | 390 (questie-classic) | same |
| 1513 | The Binding | 20 (20) | all Horde | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | pre-any 1512; excl 1472 | kill Summoned Succubus x1 (5677 L20; Orgrimmar 49.4, 50.0; +1 maps) | 1150 (questie-classic) | same |
| 1515 | Dogran's Captivity | 20 (20) | all Horde | Grunt Logmar (5911) The Barrens 44.6, 59.3 | Grunt Dogran (5908) The Barrens 43.3, 47.9 | pre-any 1511; next 1512; excl 1472 | - | 1150 (questie-classic) | same |
| 1740 | The Orb of Soran'ruk | 25 (20) | any | Doan Karhan (6247) The Barrens 49.3, 57.2 | Doan Karhan (6247) The Barrens 49.3, 57.2 | - | item Soran'ruk Fragment x3 [Twilight Acolyte 4809 L24-25 1; instance]; item Large Soran'ruk Fragment x1 [Shadowfang Darksoul 3855 L21 1; instance] | 2550 (questie-classic) | same |
| 65593 | Hearts of the Lovers | 20 (20) | all Horde | Godrick Farsan (5693) Undercity 84.8, 14.8 | Carendin Halgar (5675) Undercity 85.1, 26.0 | pre-any 1472; next 65597; excl 1507 | item Avelina's Heart x1 [Avelina Lilly 185333 L22; Silverpine Forest 63.0, 63.9]; item Isaac's Heart x1 [Isaac Pearson 185334 L22; The Barrens 61.9, 38.5] | unknown | new |
| 65597 | The Binding | 20 (20) | all Horde | Carendin Halgar (5675) Undercity 85.1, 26.0 | Carendin Halgar (5675) Undercity 85.1, 26.0 | pre-any 65593; excl 1507 | kill Summoned Incubus x1 (185335 L20; Orgrimmar 49.4, 50.0; +1 maps) | unknown | same |
| 65601 | Love Hurts | 20 (20) | all Horde | Cazul (5909) Orgrimmar 47.1, 46.4 | Magar (3363) Orgrimmar 63.6, 49.9 | pre-any 1507; next 65610; excl 1472 | - | unknown | new |
| 65604 | The Binding | 20 (20) | all Horde | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | pre-any 65610; excl 1472 | kill Summoned Incubus x1 (185335 L20; Orgrimmar 49.4, 50.0; +1 maps) | unknown | same |
| 65610 | Wish You Were Here | 27 (20) | all Horde | Magar (3363) Orgrimmar 63.6, 49.9 | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | pre-any 65601; next 65604; excl 1472 | item Withered Scarf x1 [Shadethicket Stone Mover 3782 L25-26; Ashenvale 59.0, 78.9, Shadethicket Bark Ripper 3784 L26-27; Ashenvale 58.9, 79.2, +1 more] | unknown | new |
| 1795 | The Binding | 30 (30) | any | Strahad Farsan (6251) The Barrens 62.6, 35.5 | Strahad Farsan (6251) The Barrens 62.6, 35.5 | pre-any 1805, 1804 | kill Summoned Felhunter x1 (6268 L30; The Barrens 62.6, 35.3) | 2450 (questie-classic) | same |
| 1801 | Tome of the Cabal | 30 (30) | all Horde | Strahad Farsan (6251) The Barrens 62.6, 35.5 | Jorah Annison (6293) Undercity 75.9, 37.9 | next 1803; breadcrumbs 2996, 3001 | - | 610 (questie-classic) | same |
| 1803 | Tome of the Cabal | 30 (30) | all Horde | Jorah Annison (6293) Undercity 75.9, 37.9 | Jorah Annison (6293) Undercity 75.9, 37.9 | pre-any 1801; next 1805 | item Moldy Tome x1 [object Tome of the Cabal 92013; Hillsbrad Foothills 27.8, 72.8]; item Tattered Manuscript x1 [object Damaged Chest 92423; Thousand Needles 43.4, 32.7] | 2450 (questie-classic) | same |
| 1805 | Tome of the Cabal | 30 (30) | all Horde | Jorah Annison (6293) Undercity 75.9, 37.9 | Strahad Farsan (6251) The Barrens 62.6, 35.5 | pre-any 1803; next 1795 | item Rod of Channeling x3 [Dragonmaw Shadowwarder 1038 L28-29; Wetlands 49.6, 46.4, Dragonmaw Bonewarder 1057 L27; Wetlands 45.5, 45.4, +1 more] | 2450 (questie-classic) | same |
| 2996 | Seeking Strahad | 30 (30) | all Horde | Gan'rul Bloodeye (5875) Orgrimmar 48.2, 45.3 | Strahad Farsan (6251) The Barrens 62.6, 35.5 | next 1801; breadcrumb for 1801 | - | 610 (questie-classic) | same |
| 3001 | Seeking Strahad | 30 (30) | all Horde | Carendin Halgar (5675) Undercity 85.1, 26.0 | Strahad Farsan (6251) The Barrens 62.6, 35.5 | next 1801; breadcrumb for 1801 | - | 610 (questie-classic) | same |
| 1796 | Components for the Enchanted Gold Bloodrobe | 31 (31) | any | Menara Voidrender (6266) The Barrens 62.5, 35.5 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | next 4781; breadcrumbs 4736, 4737, 4738, 4739 | item Robes of Arcana x1 | 2500 (questie-classic) | same |
| 4737 | In Search of Menara Voidrender | 31 (31) | all Horde | Zevrost (3326) Orgrimmar 48.5, 45.4 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | next 1796; excl 4736, 4738, 4739; breadcrumb for 1796 | - | 630 (questie-classic) | same |
| 4739 | In Search of Menara Voidrender | 31 (31) | all Horde | Kaal Soulreaper (4563) Undercity 86.2, 15.9 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | next 1796; excl 4736, 4737, 4738; breadcrumb for 1796 | - | 630 (questie-classic) | same |
| 4781 | Components for the Enchanted Gold Bloodrobe | 34 (31) | any | Menara Voidrender (6266) The Barrens 62.5, 35.5 | Xizk Goodstitch (2670) Stranglethorn Vale 28.7, 76.9 | pre-any 1796; next 4782 | item Gold Bar x1 [object Battered Chest 2849; The Barrens 39.2, 11.8; +7 maps, +14 objects] | 2000 (questie-classic) | same |
| 4782 | Components for the Enchanted Gold Bloodrobe | 34 (31) | any | Xizk Goodstitch (2670) Stranglethorn Vale 28.7, 76.9 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | pre-any 4781; next 4783 | - | 1350 (questie-classic) | same |
| 4783 | Components for the Enchanted Gold Bloodrobe | 37 (31) | any | Menara Voidrender (6266) The Barrens 62.5, 35.5 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | pre-any 4782; next 4784 | item Vial of Hatefury Blood x10 [Hatefury Rogue 4670 L31-32; Desolace 70.9, 16.6, Hatefury Trickster 4671 L31-32; Desolace 71.5, 17.9, +5 more]; item Lesser Infernal Stone x1 [Lesser Infernal 4676 L36-37; Desolace 48.9, 77.0, Demon Portal Guardian 11937 L38-39; Desolace 49.4, 76.0] | 2850 (questie-classic) | same |
| 4784 | Components for the Enchanted Gold Bloodrobe | 37 (31) | any | Menara Voidrender (6266) The Barrens 62.5, 35.5 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | pre-any 4783; next 4786 | item Fine Gold Thread x1 [Xizk Goodstitch 2670 L43; Stranglethorn Vale 28.7, 76.9]; item Smoldering Coal x2 [Burning Exile 2760 L38-39; Arathi Highlands 24.4, 29.5]; item Soul Shard x1 | 2100 (questie-classic) | same |
| 4786 | The Completed Robe | 38 (31) | any | Menara Voidrender (6266) The Barrens 62.5, 35.5 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | pre-any 4784 | event Menara Voidrender x1 (6266 L50; The Barrens 62.5, 35.5) | 3550 (questie-classic) | same |
| 1799 | Fragments of the Orb of Orahil | 40 (35) | any | Menara Voidrender (6266) The Barrens 62.5, 35.5 | Tabetha (6546) Dustwallow Marsh 46.1, 57.1 | next 4961; breadcrumbs 4965, 4967, 4968, 4969; children 4962, 4963 | item Infernal Orb x1 [Burning Blade Summoner 4668 L38-39; Desolace 49.6, 77.2] | 3150 (questie-classic) | same |
| 4961 | Cleansing of the Orb of Orahil | 40 (35) | any | Tabetha (6546) Dustwallow Marsh 46.1, 57.1 | Tabetha (6546) Dustwallow Marsh 46.1, 57.1 | pre-all 1799, 4962; next 4976 | kill Demon of the Orb x1 (6549 L40 1; Dustwallow Marsh 45.8, 57.0) | 2350 (questie-classic) | same |
| 4962 | Shard of a Felhound | 40 (35) | any | Acolyte Wytula (6254) The Barrens 62.6, 35.3 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | excl 4963 | item Imprisoned Felhound Spirit x1 [Mana Eater 4678 L37-38; Desolace 51.4, 68.0] | 2350 (questie-classic) | same |
| 4963 | Shard of an Infernal | 40 (35) | any | Acolyte Magaz (6252) The Barrens 62.6, 35.2 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | excl 4962 | item Imprisoned Infernal Spirit x1 [Lesser Infernal 4676 L36-37; Desolace 48.9, 77.0] | 2350 (questie-classic) | same |
| 4964 | The Completed Orb of Dar'Orahil | 40 (35) | any | Menara Voidrender (6266) The Barrens 62.5, 35.5 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | pre-all 4976; excl 4963 | event Menara Voidrender x1 (6266 L50; The Barrens 62.5, 35.5) | 3900 (questie-classic) | same |
| 4967 | Knowledge of the Orb of Orahil | 35 (35) | all Horde | Zevrost (3326) Orgrimmar 48.5, 45.4 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | next 1799; excl 4965, 4968, 4969; breadcrumb for 1799 | - | 1350 (questie-classic) | same |
| 4969 | Knowledge of the Orb of Orahil | 35 (35) | all Horde | Kaal Soulreaper (4563) Undercity 86.2, 15.9 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | next 1799; excl 4965, 4967, 4968; breadcrumb for 1799 | - | 1350 (questie-classic) | same |
| 4975 | The Completed Orb of Noh'Orahil | 40 (35) | any | Menara Voidrender (6266) The Barrens 62.5, 35.5 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | pre-all 4976; excl 4962 | event Menara Voidrender x1 (6266 L50; The Barrens 62.5, 35.5) | 3900 (questie-classic) | same |
| 4976 | Returning the Cleansed Orb | 40 (35) | any | Tabetha (6546) Dustwallow Marsh 46.1, 57.1 | Menara Voidrender (6266) The Barrens 62.5, 35.5 | pre-any 4961 | - | 1550 (questie-classic) | same |
| 3631 | Summon Felsteed | 40 (40) | all Horde | Zevrost (3326) Orgrimmar 48.5, 45.4 | Strahad Farsan (6251) The Barrens 62.6, 35.5 | next 4490; excl 4487, 4488, 4489 | - | unknown | same |
| 4489 | Summon Felsteed | 40 (40) | all Horde | Kaal Soulreaper (4563) Undercity 86.2, 15.9 | Strahad Farsan (6251) The Barrens 62.6, 35.5 | next 4490; excl 3631, 4487, 4488 | - | unknown | same |
| 4490 | Summon Felsteed | 40 (40) | any | Strahad Farsan (6251) The Barrens 62.6, 35.5 | Strahad Farsan (6251) The Barrens 62.6, 35.5 | pre-any 3631, 4487, 4488, 4489 | - | 315 (questie-classic) | same |
| 8419 | An Imp's Request | 52 (50) | any | Zevrost (3326) Orgrimmar 48.5, 45.4<br>Kaal Soulreaper (4563) Undercity 86.2, 15.9 | Impsy (14470) Felwood 41.4, 45.0 | next 8421; excl 8420 | item Felcloth x1 [Felhunter 417 L60; no spawn, Felguard Sentry 6011 L54-55; Blasted Lands 54.9, 51.5, +41 more, vendor Vi'el 16015] | 3800 (questie-classic) | same |
| 8420 | Hot and Itchy | 52 (50) | any | Impsy (14470) Felwood 41.4, 45.0 | Impsy (14470) Felwood 41.4, 45.0 | next 8421; excl 8419 | item Felcloth x1 [Felhunter 417 L60; no spawn, Felguard Sentry 6011 L54-55; Blasted Lands 54.9, 51.5, +41 more, vendor Vi'el 16015] | 3800 (questie-classic) | same |
| 8421 | The Wrong Stuff | 52 (50) | any | Impsy (14470) Felwood 41.4, 45.0 | Impsy (14470) Felwood 41.4, 45.0 | pre-any 8419, 8420; next 8422 | item Rotting Wood x10 [Irontree Wanderer 7138 L52-53; Felwood 46.6, 23.8, Irontree Stomper 7139 L52-53; Felwood 46.0, 24.1, +1 more]; item Bloodvenom Essence x4 [Tainted Ooze 7092 L51-52; Felwood 34.2, 48.5, Vile Moonwell Ooze 260975 L0; no spawn] | 5100 (questie-classic) | same |
| 8422 | Trolls of a Feather | 52 (50) | any | Impsy (14470) Felwood 41.4, 45.0 | Impsy (14470) Felwood 41.4, 45.0 | pre-any 8421 | item Amber Voodoo Feather x2 [Gasher 5713 L51 1; instance, Zul'Lor 5716 L52 1; instance, +3 more]; item Blue Voodoo Feather x2 [Hukku 5715 L52 1; instance, Mijan 5717 L52 1; instance, +4 more]; item Green Voodoo Feather x2 [Zolo 5712 L51 1; instance, Loro 5714 L51 1; instance, +2 more] | 6350 (questie-classic) | same |

### A.MAGE (22 quests)

| ID | Quest | Lvl (req) | Races | Giver | Turn-in | Links | Objectives | XP | Status |
|---|---|---|---|---|---|---|---|---|---|
| 3086 | Glyphic Tablet | 1 (1) | Troll | Gornek (3143) Durotar 42.1, 68.3 | Mai'ah (5884) Durotar 42.5, 69.0 | pre-any 788 | - | 40 (questie-classic) | same |
| 3098 | Glyphic Scroll | 1 (1) | Undead | Shadow Priest Sarvis (1569) Tirisfal Glades 30.8, 66.2 | Isabella (2124) Tirisfal Glades 30.9, 66.1 | pre-any 364 | - | 40 (questie-classic) | same |
| 97286 | Research Access | 20 (1) | any | Owen Thadd (211022) Undercity 73.4, 33.0 | Owen Thadd (211022) Undercity 73.4, 33.0 | pre-any 78124, 78127, 78142, 78143, 78145, 78146, 78147, 78148, 78149, 79091, 79092, 79093, 79094, 79095, 79096, 79097, 79535, 79947, 79948, 79949, 79950, 79951, 79952, 79953, 81947, 81949, 81951, 81952, 81953, 81954, 81955, 81956, 84395, 84396, 84397, 84398, 84399, 84400, 84401, 84402 | - | unknown | new |
| 98576 | Glyphic Parchment | 1 (1) | Orc | Gornek (3143) Durotar 42.1, 68.3 | Mai'ah (5884) Durotar 42.5, 69.0 | pre-any 788 | - | unknown | new |
| 1881 | Speak with Anastasia | 10 (10) | Undead/Troll | Cain Firesong (2128) Tirisfal Glades 62.0, 52.5 | Anastasia Hartwell (4568) Undercity 85.1, 10.0 | next 1882; excl 1884; breadcrumb for 1882 | - | 85 (questie-classic) | same |
| 1882 | The Balnir Farmstead | 10 (10) | Undead/Troll | Anastasia Hartwell (4568) Undercity 85.1, 10.0 | Anastasia Hartwell (4568) Undercity 85.1, 10.0 | excl 1884; breadcrumbs 1881 | item Balnir Snapdragons x1 [object Balnir Snapdragons 102985; Tirisfal Glades 77.4, 61.8] | 840 (questie-classic) | same |
| 1883 | Speak with Un'thuwa | 10 (10) | all Horde | Thurston Xane (3049) Thunder Bluff 25.2, 21.0<br>Uthel'nay (7311) Orgrimmar 39.2, 86.3 | Un'Thuwa (5880) Durotar 56.3, 75.1 | next 1884; excl 1882; breadcrumb for 1884 | - | 85 (questie-classic) | same |
| 1884 | Ju-Ju Heaps | 10 (10) | Orc/Undead/Troll | Un'Thuwa (5880) Durotar 56.3, 75.1 | Un'Thuwa (5880) Durotar 56.3, 75.1 | excl 1882; breadcrumbs 1883 | object Ju-Ju Heap x4 (102986; Durotar 67.0, 87.8) | 840 (questie-classic) | same |
| 1959 | Report to Anastasia | 15 (15) | Undead/Troll | Cain Firesong (2128) Tirisfal Glades 62.0, 52.5<br>Thurston Xane (3049) Thunder Bluff 25.2, 21.0<br>Un'Thuwa (5880) Durotar 56.3, 75.1<br>Uthel'nay (7311) Orgrimmar 39.2, 86.3 | Anastasia Hartwell (4568) Undercity 85.1, 10.0 | next 1960; breadcrumb for 1960 | - | 105 (questie-classic) | same |
| 1960 | Investigate the Alchemist Shop | 16 (15) | Undead/Troll | Anastasia Hartwell (4568) Undercity 85.1, 10.0 | Anastasia Hartwell (4568) Undercity 85.1, 10.0 | next 1961; breadcrumbs 1959 | item Filled Containment Coffer x3 [object Filled Containment Coffer 103574; Undercity 52.0, 76.0]; item Chest of Containment Coffers x1 [object Chest of Containment Coffers 105174; Undercity 85.5, 9.9]; item Cantation of Manifestation x1 [object Cantation of Manifestation 105175; Undercity 85.7, 10.2] | 1150 (questie-classic) | same |
| 1961 | Gathering Materials | 15 (15) | Orc/Undead/Troll | Anastasia Hartwell (4568) Undercity 85.1, 10.0 | Josef Gregorian (4576) Undercity 70.8, 30.7 | pre-any 1960; next 1962 | item Linen Cloth x10 [object Hidden Strongbox 2039; Alterac Mountains 10.7, 77.5, +7 objects]; item Dalaran Mana Gem x6 [Dalaran Apprentice 1867 L13-14; Silverpine Forest 49.3, 67.1, Dalaran Watcher 1888 L18-19; Silverpine Forest 56.0, 78.0, +80 more] | 800 (questie-classic) | same |
| 1962 | Spellfire Robes | 15 (15) | Undead/Troll | Josef Gregorian (4576) Undercity 70.8, 30.7<br>Victor Ward (11048) Undercity 70.1, 29.8<br>Rhiannon Davis (11049) Undercity 70.0, 30.6 | Josef Gregorian (4576) Undercity 70.8, 30.7<br>Victor Ward (11048) Undercity 70.1, 29.8<br>Rhiannon Davis (11049) Undercity 70.0, 30.6 | pre-any 1961 | - | 1050 (questie-classic) | same |
| 1943 | Speak with Deino | 26 (26) | Undead/Troll | Anastasia Hartwell (4568) Undercity 85.1, 10.0 | Deino (5885) Orgrimmar 38.5, 86.1 | next 1944; breadcrumb for 1944 | - | 210 (questie-classic) | same |
| 1944 | Waters of Xavian | 26 (26) | Undead/Troll | Deino (5885) Orgrimmar 38.5, 86.1 | Deino (5885) Orgrimmar 38.5, 86.1 | next 1945; breadcrumbs 1943 | item Xavian Water Sample x1 [object Xavian Waterfall 174797; Ashenvale 76.3, 41.5] | 2100 (questie-classic) | same |
| 1945 | Laughing Sisters | 26 (26) | Undead/Troll | Deino (5885) Orgrimmar 38.5, 86.1 | Kil'hala (3484) The Barrens 52.2, 31.7 | pre-any 1944; next 1946 | item Laughing Sister's Hair x12 [Laughing Sister 4054 L24-25; Ashenvale 58.0, 58.4] | 1600 (questie-classic) | same |
| 1946 | Nether-lace Garment | 26 (26) | Undead/Troll | Kil'hala (3484) The Barrens 52.2, 31.7 | Kil'hala (3484) The Barrens 52.2, 31.7 | pre-any 1945 | - | 2100 (questie-classic) | same |
| 1947 | Journey to the Marsh | 38 (30) | any | Ursyn Ghull (3048) Thunder Bluff 25.7, 14.2<br>Anastasia Hartwell (4568) Undercity 85.1, 10.0<br>Deino (5885) Orgrimmar 38.5, 86.1 | Tabetha (6546) Dustwallow Marsh 46.1, 57.1 | - | - | 285 (questie-classic) | same |
| 1953 | Return to the Marsh | 40 (35) | any | Ursyn Ghull (3048) Thunder Bluff 25.7, 14.2<br>Anastasia Hartwell (4568) Undercity 85.1, 10.0<br>Deino (5885) Orgrimmar 38.5, 86.1 | Tabetha (6546) Dustwallow Marsh 46.1, 57.1 | next 1954; breadcrumb for 1954 | - | 315 (questie-classic) | same |
| 1954 | The Infernal Orb | 40 (35) | any | Tabetha (6546) Dustwallow Marsh 46.1, 57.1 | Tabetha (6546) Dustwallow Marsh 46.1, 57.1 | next 1955; breadcrumbs 1953 | item Infernal Orb x1 [Burning Blade Summoner 4668 L38-39; Desolace 49.6, 77.2] | 2350 (questie-classic) | same |
| 1955 | The Exorcism | 40 (35) | any | Tabetha (6546) Dustwallow Marsh 46.1, 57.1 | Tabetha (6546) Dustwallow Marsh 46.1, 57.1 | pre-any 1954; next 1956 | kill Demon of the Orb x1 (6549 L40 1; Dustwallow Marsh 45.8, 57.0); scripted event; area trigger Dustwallow Marsh 45.6, 57.2 | 2350 (questie-classic) | same |
| 1956 | Power in Uldaman | 40 (35) | any | Tabetha (6546) Dustwallow Marsh 46.1, 57.1 | Tabetha (6546) Dustwallow Marsh 46.1, 57.1 | pre-any 1955; next 1957 | item Obsidian Power Source x1 [Obsidian Sentinel 7023 L42 1; instance] | 3900 (questie-classic) | same |
| 8250 | Magecraft | 52 (50) | any | Archmage Shymm (3047) Thunder Bluff 22.8, 14.5<br>Pierce Shackleton (4567) Undercity 85.5, 13.5<br>Uthel'nay (7311) Orgrimmar 39.2, 86.3 | Sanath Lim-yo (8395) Azshara 28.1, 50.1 | - | - | 510 (questie-classic) | same |

### A.PRIEST (26 quests)

| ID | Quest | Lvl (req) | Races | Giver | Turn-in | Links | Objectives | XP | Status |
|---|---|---|---|---|---|---|---|---|---|
| 3085 | Hallowed Tablet | 1 (1) | Troll | Gornek (3143) Durotar 42.1, 68.3 | Ken'jai (3707) Durotar 42.4, 68.8 | pre-any 788 | - | 40 (questie-classic) | same |
| 3097 | Hallowed Scroll | 1 (1) | Undead | Shadow Priest Sarvis (1569) Tirisfal Glades 30.8, 66.2 | Dark Cleric Duesten (2123) Tirisfal Glades 31.1, 66.0 | pre-any 364 | - | 40 (questie-classic) | same |
| 5648 | Garments of Spirituality | 4 (5) | Troll | Tai'jin (3706) Durotar 54.3, 42.9 | Tai'jin (3706) Durotar 54.3, 42.9 | breadcrumbs 5649 | use on Grunt Kor'ja x1 (12430 L7; Durotar 53.1, 46.5) | 270 (questie-classic) | same |
| 5649 | In Favor of Spirituality | 4 (5) | Troll | Ken'jai (3707) Durotar 42.4, 68.8 | Tai'jin (3706) Durotar 54.3, 42.9 | next 5648; breadcrumb for 5648 | - | 90 (questie-classic) | same |
| 5650 | Garments of Darkness | 4 (5) | Undead | Dark Cleric Beryl (2129) Tirisfal Glades 61.6, 52.2 | Dark Cleric Beryl (2129) Tirisfal Glades 61.6, 52.2 | breadcrumbs 5651 | use on Deathguard Kel x1 (12428 L7; Tirisfal Glades 59.2, 46.5) | 270 (questie-classic) | same |
| 5651 | In Favor of Darkness | 4 (5) | Undead | Dark Cleric Duesten (2123) Tirisfal Glades 31.1, 66.0 | Dark Cleric Beryl (2129) Tirisfal Glades 61.6, 52.2 | next 5650; breadcrumb for 5650 | - | 90 (questie-classic) | same |
| 5652 | Hex of Weakness | 10 (10) | Troll | Ur'kyo (6018) Orgrimmar 35.6, 87.8 | Ur'kyo (6018) Orgrimmar 35.6, 87.8 | excl 5654, 5655, 5656, 5657 | - | unknown | same |
| 5654 | Hex of Weakness | 10 (10) | Troll | Tai'jin (3706) Durotar 54.3, 42.9 | Ur'kyo (6018) Orgrimmar 35.6, 87.8 | excl 5652, 5655, 5656, 5657 | - | 210 (questie-classic) | same |
| 5655 | Hex of Weakness | 10 (10) | Troll | Var'jun (11407) Mulgore 46.2, 62.3 | Ur'kyo (6018) Orgrimmar 35.6, 87.8 | excl 5652, 5654, 5656, 5657 | - | 210 (questie-classic) | same |
| 5656 | Hex of Weakness | 10 (10) | Troll | Miles Welsh (3044) Thunder Bluff 25.3, 15.3 | Ur'kyo (6018) Orgrimmar 35.6, 87.8 | excl 5652, 5654, 5655, 5657 | - | 210 (questie-classic) | same |
| 5657 | Hex of Weakness | 10 (10) | Troll | Aelthalyste (4606) Undercity 49.3, 17.1 | Ur'kyo (6018) Orgrimmar 35.6, 87.8 | excl 5652, 5654, 5655, 5656 | - | 210 (questie-classic) | same |
| 5658 | Touch of Weakness | 10 (10) | Undead | Aelthalyste (4606) Undercity 49.3, 17.1 | Aelthalyste (4606) Undercity 49.3, 17.1 | excl 5660, 5661, 5662, 5663 | - | unknown | same |
| 5660 | Touch of Weakness | 10 (10) | Undead | Tai'jin (3706) Durotar 54.3, 42.9 | Aelthalyste (4606) Undercity 49.3, 17.1 | excl 5658, 5661, 5662, 5663 | - | 210 (questie-classic) | same |
| 5661 | Touch of Weakness | 10 (10) | Undead | Var'jun (11407) Mulgore 46.2, 62.3 | Aelthalyste (4606) Undercity 49.3, 17.1 | excl 5658, 5660, 5662, 5663 | - | 210 (questie-classic) | same |
| 5662 | Touch of Weakness | 10 (10) | Undead | Ur'kyo (6018) Orgrimmar 35.6, 87.8 | Aelthalyste (4606) Undercity 49.3, 17.1 | excl 5658, 5660, 5661, 5663 | - | 210 (questie-classic) | same |
| 5663 | Touch of Weakness | 10 (10) | Undead | Miles Welsh (3044) Thunder Bluff 25.3, 15.3 | Aelthalyste (4606) Undercity 49.3, 17.1 | excl 5658, 5660, 5661, 5662 | - | 210 (questie-classic) | same |
| 5642 | Shadowguard | 20 (20) | Troll | Miles Welsh (3044) Thunder Bluff 25.3, 15.3 | Ur'kyo (6018) Orgrimmar 35.6, 87.8 | excl 5643, 5680 | - | 390 (questie-classic) | same |
| 5643 | Shadowguard | 20 (20) | Troll | Aelthalyste (4606) Undercity 49.3, 17.1 | Ur'kyo (6018) Orgrimmar 35.6, 87.8 | excl 5642, 5680 | - | 390 (questie-classic) | same |
| 5644 | Devouring Plague | 20 (20) | Undead | Miles Welsh (3044) Thunder Bluff 25.3, 15.3 | Aelthalyste (4606) Undercity 49.3, 17.1 | excl 5646, 5679 | - | 390 (questie-classic) | same |
| 5646 | Devouring Plague | 20 (20) | Undead | Ur'kyo (6018) Orgrimmar 35.6, 87.8 | Aelthalyste (4606) Undercity 49.3, 17.1 | excl 5644, 5679 | - | 390 (questie-classic) | same |
| 5679 | Devouring Plague | 20 (20) | Undead | Aelthalyste (4606) Undercity 49.3, 17.1 | Aelthalyste (4606) Undercity 49.3, 17.1 | excl 5644, 5646 | - | unknown | same |
| 5680 | Shadowguard | 20 (20) | Troll | Ur'kyo (6018) Orgrimmar 35.6, 87.8 | Ur'kyo (6018) Orgrimmar 35.6, 87.8 | excl 5642, 5643 | - | unknown | same |
| 8254 | Cenarion Aid | 52 (50) | any | Malakai Cross (3045) Thunder Bluff 24.6, 22.6<br>Ur'kyo (6018) Orgrimmar 35.6, 87.8 | Ogtinc (8405) Azshara 42.4, 42.6 | next 8255 | - | 510 (questie-classic) | same |
| 8255 | Of Coursers We Know | 52 (50) | any | Ogtinc (8405) Azshara 42.4, 42.6 | Ogtinc (8405) Azshara 42.4, 42.6 | pre-any 8254; next 8256 | item Healthy Courser Gland x4 [Mosshoof Courser 8761 L52-53; Azshara 35.1, 65.9] | 5100 (questie-classic) | same |
| 8256 | The Ichor of Undeath | 52 (50) | any | Ogtinc (8405) Azshara 42.4, 42.6 | Ogtinc (8405) Azshara 42.4, 42.6 | pre-any 8255; next 8257 | item Ichor of Undeath x1 [Zanzil Zombie 1488 L43-44; Stranglethorn Vale 34.5, 51.0, Zanzil Hunter 1489 L43-44; Stranglethorn Vale 34.4, 52.2, +51 more] | 5100 (questie-classic) | same |
| 8257 | Blood of Morphaz | 52 (50) | any | Ogtinc (8405) Azshara 42.4, 42.6 | Greta Mosshoof (10922) Felwood 51.2, 82.1 | pre-any 8256 | item Blood of Morphaz x1 [Morphaz 5719 L52 1; instance] | 6350 (questie-classic) | same |

### A.DRUID (34 quests)

| ID | Quest | Lvl (req) | Races | Giver | Turn-in | Links | Objectives | XP | Status |
|---|---|---|---|---|---|---|---|---|---|
| 3094 | Verdant Note | 1 (1) | Tauren | Grull Hawkwind (2980) Mulgore 44.5, 77.5 | Gart Mistrunner (3060) Mulgore 44.6, 76.5 | pre-any 747 | - | 60 (wclbox-classic) | same |
| 92485 | A Student of Nature | 2 (2) | any | Rorian the Dayseeker (251361) Zephras Isle 42.0, 23.5 | Xyton Silverwind (251373) Zephras Isle 41.7, 23.3 | pre-any 92461 | - | unknown | new |
| 5922 | Moonglade | 10 (10) | Tauren | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | next 5930; breadcrumbs 5926, 5927, 5928 | - | 210 (wclbox-classic) | same |
| 5926 | Heeding the Call | 10 (10) | Tauren | Innkeeper Pala (6746) Thunder Bluff 45.8, 64.7 | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | next 5922; excl 5927, 5928; breadcrumb for 5922 | - | 85 (wclbox-classic) | same |
| 5927 | Heeding the Call | 10 (10) | Tauren | Innkeeper Gryshka (6929) Orgrimmar 54.1, 68.4 | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | next 5922; excl 5926, 5928; breadcrumb for 5922 | - | 85 (wclbox-classic) | same |
| 5928 | Heeding the Call | 10 (10) | Tauren | Gennia Runetotem (3064) Mulgore 47.5, 63.0 | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | next 5922; excl 5926, 5927; breadcrumb for 5922 | - | 85 (wclbox-classic) | same |
| 5930 | Great Bear Spirit | 10 (10) | Tauren | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | pre-any 5922; next 5932; special 2 | talk to Great Bear Spirit x1 (11956 L60; Moonglade 39.1, 27.5) | 420 (wclbox-classic) | same |
| 5932 | Back to Thunder Bluff | 10 (10) | Tauren | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | pre-any 5930; next 6002 | - | 85 (wclbox-classic) | same |
| 6002 | Body and Heart | 10 (10) | Tauren | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | pre-any 5932; special 2 | talk to Lunaclaw Spirit x1 (12144 L13; The Barrens 42.0, 60.8) | 850 (wclbox-classic) | same |
| 94006 | The Great Ursera Spirit | 10 (10) | Skyborne (+Alliance Skyborne) | Lotheluum Starbreeze (252359) Zephras Isle 64.0, 75.1 | Urs'endris (255853) Zephras Isle 69.8, 61.7 | next 94638 | - | unknown | new |
| 94638 | Strength and Mercy | 10 (10) | Skyborne (+Alliance Skyborne) | Urs'endris (255853) Zephras Isle 69.8, 61.7 | Urs'endris (255853) Zephras Isle 69.8, 61.7 | pre-any 94006 | kill Ur'endra x1 (258443 L10; Zephras Isle 53.8, 65.2) | unknown | new |
| 94911 | Child of Nature | 10 (10) | Skyborne | Muln Earthfury (259118) Mulgore 33.4, 22.6<br>Alaana Stormwalker (259119) Mulgore 33.4, 22.5 | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | - | - | unknown | new |
| 94913 | Moonglade | 10 (10) | Skyborne | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | - | - | unknown | new |
| 6126 | Lessons Anew | 14 (14) | Tauren | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2<br>Hana Lighthoof (262560) Mulgore 33.4, 22.1 | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | next 6127 | - | 100 (wclbox-classic) | same |
| 6127 | The Principal Source | 14 (14) | Tauren | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | Tonga Runetotem (3448) The Barrens 52.3, 31.9 | pre-any 6126; next 6128 | item Filled Dreadmist Peak Sampler x1 [object Dreadmist Peak Pool 19464; The Barrens 48.4, 18.9] | 750 (wclbox-classic) | same |
| 6128 | Gathering the Cure | 14 (14) | Tauren | Tonga Runetotem (3448) The Barrens 52.3, 31.9 | Tonga Runetotem (3448) The Barrens 52.3, 31.9 | pre-any 6127; next 6129 | item Earthroot x5 [Lasher Sproutling 275703 L6-7; Teldrassil 48.6, 72.6, Wrathvine 276099 L8 4; Teldrassil 53.0, 67.0, object Earthroot 1619; Durotar 36.1, 29.6; +11 maps, +1 objects, vendor Antonio Perelli 844, +5 vendors]; item Kodo Horn x5 [Lost Barrens Kodo 3234 L14-15; The Barrens 40.1, 24.2, Barrens Kodo 3236 L19-20; The Barrens 45.7, 68.0] | 750 (wclbox-classic) | same |
| 6129 | Curing the Sick | 14 (14) | Tauren | Tonga Runetotem (3448) The Barrens 52.3, 31.9 | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | pre-any 6128; next 6130 | use on Sickly Gazelle x10 (12296 L3; The Barrens 40.8, 20.7) | 750 (wclbox-classic) | same |
| 6130 | Power over Poison | 14 (14) | Tauren | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | pre-any 6129 | - | 975 (wclbox-classic) | same |
| 27 | A Lesson to Learn | 16 (16) | Tauren | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | next 28 | - | 120 (wclbox-classic) | same |
| 28 | Trial of the Lake | 16 (16) | Tauren | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | Tajarri (11799) Moonglade 36.5, 40.1 | pre-any 27; next 30; special 2 | object Shrine Of Remulos x1 (15885; Moonglade 36.0, 41.4) | 875 (wclbox-classic) | same |
| 30 | Trial of the Sea Lion | 16 (16) | Tauren | Tajarri (11799) Moonglade 36.5, 40.1 | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | pre-any 28; next 31 | item Pendant of the Sea Lion x1 [object Shrine Of Remulos 15885; Moonglade 36.0, 41.4] | 875 (wclbox-classic) | same |
| 31 | Aquatic Form | 16 (16) | Tauren | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | pre-any 30 | - | 1150 (wclbox-classic) | same |
| 98340 | The Great Cat Spirit | 20 (20) | Tauren/Skyborne | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | - | - | unknown | new |
| 98341 | The Great Windborne Cat Spirit | 20 (20) | Skyborne (+Alliance Skyborne); no class mask | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | Avatar of Saeyleenan (272054) Moonglade 43.9, 73.4 | - | - | unknown | new |
| 98342 | The Great Cat Spirit | 20 (20) | Tauren | Great Cat Spirit (11957) Moonglade 58.4, 73.5 | Great Cat Spirit (11957) Moonglade 58.4, 73.5 | - | item Relic of the Fang x1 [object Relic of the Fang 672821; Moonglade 72.4, 66.0]; item Relic of the Claw x1 [object Relic of the Claw 673093; Moonglade 75.2, 67.2]; item Relic of the Silent Shadow x1 [object Relic of the Silent Shadow 673094; Moonglade 74.4, 65.4] | unknown | new |
| 98362 | To Thunder Bluff | 20 (20) | Tauren/Skyborne | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2 | - | - | unknown | new |
| 98404 | The Great Windborne Cat Spirit | 20 (20) | Skyborne (+Alliance Skyborne); no class mask | Avatar of Saeyleenan (272054) Moonglade 43.9, 73.4 | Avatar of Saeyleenan (272054) Moonglade 43.9, 73.4 | - | item Relic of the Fang x1 [object Relic of the Fang 672821; Moonglade 72.4, 66.0]; item Relic of the Claw x1 [object Relic of the Claw 673093; Moonglade 75.2, 67.2]; item Relic of the Silent Shadow x1 [object Relic of the Silent Shadow 673094; Moonglade 74.4, 65.4] | unknown | new |
| 98405 | The Great Cat Spirit | 20 (20) | Tauren | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | Great Cat Spirit (11957) Moonglade 58.4, 73.5 | - | - | unknown | new |
| 98738 | Blessings of the Great Windborne Cat Spirit | 20 (20) | Skyborne (+Alliance Skyborne); no class mask | Avatar of Saeyleenan (272054) Moonglade 43.9, 73.4 | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | - | - | unknown | new |
| 98739 | Blessings of the Great Cat Spirit | 20 (20) | Tauren | Great Cat Spirit (11957) Moonglade 58.4, 73.5 | Dendrite Starblaze (11802) Moonglade 56.2, 30.6 | - | - | unknown | new |
| 9051 | Toxic Test | 52 (50) | any | Torwa Pathfinder (9619) Un'Goro Crater 71.6, 76.0 | Torwa Pathfinder (9619) Un'Goro Crater 71.6, 76.0 | pre-any 9052; next 9053; special 2 | kill credit 6498 x1 | 5100 (wclbox-classic) | same |
| 9052 | Bloodpetal Poison | 52 (50) | any | Torwa Pathfinder (9619) Un'Goro Crater 71.6, 76.0 | Torwa Pathfinder (9619) Un'Goro Crater 71.6, 76.0 | next 9051; breadcrumbs 9063 | item Gorishi Sting x8 [Gorishi Wasp 6551 L51-52; Un'Goro Crater 43.3, 76.4, Gorishi Stinger 6554 L52-53; Un'Goro Crater 44.0, 80.8]; item Bloodcap x8 [object Bloodpetal Sprout 164958; Un'Goro Crater 24.1, 53.8] | 5100 (wclbox-classic) | same |
| 9053 | A Better Ingredient | 52 (50) | any | Torwa Pathfinder (9619) Un'Goro Crater 71.6, 76.0 | Torwa Pathfinder (9619) Un'Goro Crater 71.6, 76.0 | pre-any 9051 | item Putrid Vine x1 [Atal'alarion 8580 L50 1; instance] | 6350 (wclbox-classic) | same |
| 9063 | Torwa Pathfinder | 52 (50) | any | Turak Runetotem (3033) Thunder Bluff 76.5, 27.2<br>Loganaar (12042) Moonglade 52.5, 40.6 | Torwa Pathfinder (9619) Un'Goro Crater 71.6, 76.0 | next 9052; breadcrumb for 9052 | - | 500 (wclbox-classic) | same |

### A.PALADIN (30 quests)

| ID | Quest | Lvl (req) | Races | Giver | Turn-in | Links | Objectives | XP | Status |
|---|---|---|---|---|---|---|---|---|---|
| 98601 | A Difficult Path | 1 (1) | Undead | Shadow Priest Sarvis (1569) Tirisfal Glades 30.8, 66.2<br>Novice Elreth (1661) Tirisfal Glades 30.9, 66.0 | Aramis Hammerhand (244808) Tirisfal Glades 31.1, 66.4 | pre-any 364 | - | unknown | new |
| 90902 | Rediscovering the Light | 2 (2) | Undead | Aramis Hammerhand (244808) Tirisfal Glades 31.1, 66.4 | Aramis Hammerhand (244808) Tirisfal Glades 31.1, 66.4 | pre-any 364 | use on Injured Deathguard x5 (259377 L1; Tirisfal Glades 28.8, 65.4) | unknown | new |
| 91208 | Coming to Terms | 4 (4) | Undead | Aramis Hammerhand (244808) Tirisfal Glades 31.1, 66.4 | Aramis Hammerhand (244808) Tirisfal Glades 31.1, 66.4 | pre-any 90902 | kill Frightened Paladin x1 (246143 L3; Tirisfal Glades 27.7, 63.8) | unknown | new |
| 91209 | Continue Your Training | 4 (4) | Undead | Aramis Hammerhand (244808) Tirisfal Glades 31.1, 66.4 | Shari Stilwell (246152) Tirisfal Glades 60.2, 52.7 | - | use on Shari Stilwell x1 (246152 L16; Tirisfal Glades 60.2, 52.7) | unknown | new |
| 91285 | Murlocs at the Gates | 11 (7) | Undead | Breton Samuels (246349) Tirisfal Glades 21.9, 45.2 | Breton Samuels (246349) Tirisfal Glades 21.9, 45.2 | - | kill Vile Fin Attacker x8 (250283 L9-11; Tirisfal Glades 12.8, 59.1); kill Vile Fin Seer x8 (250282 L9-10; Tirisfal Glades 10.9, 58.9) | unknown | new |
| 91282 | A Second Home | 11 (8) | Undead | Shari Stilwell (246152) Tirisfal Glades 60.2, 52.7 | Breton Samuels (246349) Tirisfal Glades 21.9, 45.2 | - | - | unknown | new |
| 91294 | Touring the Grounds | 11 (8) | Undead | Breton Samuels (246349) Tirisfal Glades 21.9, 45.2 | Danitha Morr (246378) Tirisfal Glades 22.1, 44.7 | pre-any 91285 | talk to Hilda the Breaker x1 (246389 L55; Tirisfal Glades 22.0, 47.2); talk to Jorin Croge x1 (246393 L55; Tirisfal Glades 22.7, 44.7); talk to Ander Solliden x1 (246394 L20; Tirisfal Glades 25.4, 50.4); talk to Danitha Morr x1 (246378 L61 1; Tirisfal Glades 22.1, 44.7) | unknown | new |
| 91316 | Making Repairs | 11 (8) | Undead | Jorin Croge (246393) Tirisfal Glades 22.7, 44.7 | Jorin Croge (246393) Tirisfal Glades 22.7, 44.7 | pre-any 91294 | item Sturdy Lumber x12 [object Lumber Pile 554626; Tirisfal Glades 8.5, 67.1] | unknown | new |
| 91317 | The Tarnished | 12 (9) | Undead | Danitha Morr (246378) Tirisfal Glades 22.1, 44.7 | Danitha Morr (246378) Tirisfal Glades 22.1, 44.7 | pre-any 91294 | kill Tarnished Drudge x8 (259434 L10-11; Tirisfal Glades 10.8, 59.4); kill Tarnished Zealot x6 (259433 L10-11; Tirisfal Glades 11.0, 58.8); item Rudolph Gelhardt's Head x1 [Rudolph Gelhardt 259431 L12; Tirisfal Glades 11.5, 64.2] | unknown | new |
| 95803 | A Token of Good Faith | 12 (9) | Undead | Danitha Morr (246378) Tirisfal Glades 22.1, 44.7 | Lady Sylvanas Windrunner (10181) Undercity 58.0, 91.8 | pre-any 91317 | - | unknown | new |
| 94427 | A Lesson in Divinity | 12 (12) | Undead | Danitha Morr (246378) Tirisfal Glades 22.1, 44.7 | Tanis Alderwood (257648) Undercity 65.5, 37.5 | next 94434 | - | unknown | new |
| 94434 | A Lesson in Divinity | 12 (12) | Undead | Tanis Alderwood (257648) Undercity 65.5, 37.5 | Tanis Alderwood (257648) Undercity 65.5, 37.5 | pre-any 94427; next 94435 | item Linen Cloth x10 [object Hidden Strongbox 2039; Alterac Mountains 10.7, 77.5, +7 objects] | unknown | new |
| 94435 | A Lesson in Divinity | 12 (12) | Undead | Tanis Alderwood (257648) Undercity 65.5, 37.5 | Danitha Morr (246378) Tirisfal Glades 22.1, 44.7 | pre-any 94434; next 94436 | - | unknown | new |
| 94436 | A Lesson in Divinity | 12 (12) | Undead | Danitha Morr (246378) Tirisfal Glades 22.1, 44.7 | Deathguard Billmuth (257655) Tirisfal Glades 21.9, 44.5 | pre-any 94435; next 94438 | - | unknown | new |
| 94438 | A Lesson in Divinity | 12 (12) | Undead | Deathguard Billmuth (257655) Tirisfal Glades 21.9, 44.5 | Deathguard Falgan (257663) Tirisfal Glades 86.7, 47.7 | pre-any 94436; next 94440 | - | unknown | new |
| 94440 | A Lesson in Divinity | 12 (12) | Undead | Deathguard Falgan (257663) Tirisfal Glades 86.7, 47.7 | Deathguard Billmuth (257655) Tirisfal Glades 21.9, 44.5 | pre-any 94438; next 94441 | item Scarlet Crusade Attack Plans x1 [Scarlet Zealot 1537 L8-9; Tirisfal Glades 48.8, 66.2, Scarlet Friar 1538 L9-10; Tirisfal Glades 76.1, 57.2, +2 more] | unknown | new |
| 94441 | A Lesson in Divinity | 12 (12) | Undead | Deathguard Billmuth (257655) Tirisfal Glades 21.9, 44.5 | Danitha Morr (246378) Tirisfal Glades 22.1, 44.7 | pre-any 94440 | - | unknown | new |
| 91858 | Diplomatic Incident | 22 (18) | Undead | Danitha Morr (246378) Tirisfal Glades 22.1, 44.7 | Trevan Rol (248840) Silverpine Forest 43.4, 41.1 | - | - | unknown | new |
| 91859 | A Curious Pair | 22 (18) | Undead | Trevan Rol (248840) Silverpine Forest 43.4, 41.1 | Deathguard Baldren (259611) Silverpine Forest 45.8, 41.9 | - | - | unknown | new |
| 91860 | A Grim Fate | 22 (18) | Undead | Deathguard Baldren (259611) Silverpine Forest 45.8, 41.9 | object Charred Remains (566037) Silverpine Forest 65.0, 34.1 | - | - | unknown | new |
| 91861 | Into Fenris Keep | 22 (18) | Undead | object Charred Remains (566037) Silverpine Forest 65.0, 34.1 | Lumina Windsinger (248755) Silverpine Forest 65.5, 23.3 | - | - | unknown | new |
| 91862 | Lumina Windsinger | 22 (18) | Undead | Lumina Windsinger (248755) Silverpine Forest 65.5, 23.3 | Lumina Windsinger (248755) Silverpine Forest 65.5, 23.3 | - | item Fenris Isle Key x1 [Rot Hide Savage 1942 L18-19; Silverpine Forest 65.1, 25.1, Raging Rot Hide 1943 L18-19; Silverpine Forest 65.2, 23.2, +2 more] | unknown | new |
| 95034 | The Debt | 24 (18) | Undead | Lumina Windsinger (259620) Silverpine Forest 43.4, 41.0 | Lumina Windsinger (259620) Silverpine Forest 43.4, 41.0 | - | - | unknown | new |
| 96204 | The Windshaper's Wrath | 22 (18) | Undead | Lumina Windsinger (248755) Silverpine Forest 65.5, 23.3 | Lumina Windsinger (259620) Silverpine Forest 43.4, 41.0 | - | - | unknown | new |
| 95036 | A Moon-Kissed Blade | 25 (20) | Undead | Lumina Windsinger (259620) Silverpine Forest 43.4, 41.0 | Trevan Rol (248840) Silverpine Forest 43.4, 41.1 | - | item Trevan's Weapon Notes x1; item Whitestone Oak Lumber x1 [Goblin Woodcarver 641 L18-19 1; instance]; item Enchanted Silver Ingot x1 [object ? 629065; no spawn]; item Purified Kor Gem x1 | unknown | new |
| 95042 | Seeking the Kor Gem | 25 (20) | all Horde | Ulric Frostveil (259649) Ashenvale 11.8, 34.5 | Ulric Frostveil (259649) Ashenvale 11.8, 34.5 | - | item Corrupted Kor Gem x1 [Blackfathom Tide Priestess 4802 L20-21 1; Ashenvale 13.6, 12.1, Blackfathom Oracle 4803 L21-22 1; Darkshore 30.0, 92.6, +2 more] | unknown | new |
| 95111 | An Underrated Talent | 25 (20) | Undead | Trevan Rol (248840) Silverpine Forest 43.4, 41.1 | Ott (3539) Hillsbrad Foothills 60.4, 26.2 | - | - | unknown | new |
| 95125 | Ott's Masterwork | 25 (20) | Undead | Ott (3539) Hillsbrad Foothills 60.4, 26.2 | Ott (3539) Hillsbrad Foothills 60.4, 26.2 | - | - | unknown | new |
| 95126 | The Moonsilver Blade | 25 (20) | Undead | Ott (3539) Hillsbrad Foothills 60.4, 26.2 | Trevan Rol (248840) Silverpine Forest 43.4, 41.1 | - | - | unknown | new |
| 95140 | Old Fire-Eye | 26 (20) | Undead | Lumina Windsinger (259620) Silverpine Forest 43.4, 41.0 | Lumina Windsinger (259620) Silverpine Forest 43.4, 41.0 | - | kill Old Fire-Eye x1 (259897 L25 1; Silverpine Forest 47.6, 86.1); item Moonsilver Blade x1 | unknown | new |

---------------------------------------------------------------------------------------------------------------

## Appendix B. Class quests that exist in Forever but are outside the snapshot (`questIndex` only)

Name, quest level, required level, race mask, class mask and sort are all the DB knows. A step on one of these
gives WARN `quest-out-of-scope`; givers and objectives cannot be checked. Level 58+ raid / set quests omitted.

| Class | ID | Quest | Lvl (req) | Races | Note |
|---|---|---|---|---|---|
| Rogue | 96779 | Syndicate Sabotage | 24 (24) | any | Forever-new chain |
| Rogue | 96783 | A Way In | 34 (24) | any | |
| Rogue | 96784 | Master of Disguise | 34 (24) | all Horde | |
| Rogue | 96785 | Ain't No Telling | 34 (24) | any | |
| Rogue | 96786 | The Syndicate Sting | 34 (24) | any | |
| Rogue | 96781 | What's the Big Idea? | 36 (24) | any | |
| Rogue | 96782 | Covert Extraction | 36 (24) | any | |
| Rogue | 8249 | Junkboxes Needed | 60 (50) | any | repeatable (C) |
| Rogue | 7498 | Garona: A Study on Stealth and Treachery | 60 (54) | any | Dire Maul book |
| Shaman | 79362 | Grant's Shield | 25 (18) | Orc / Tauren / Troll | sort 10 (Duskwood) |
| Shaman | 79363 | Silvia's Sword | 26 (18) | Orc / Tauren / Troll | sort 10 (Duskwood) |
| Shaman | 79360 | Elemental Aid | 33 (30) | all Horde | |
| Shaman | 79364 | Eyes on the Sky | 33 (30) | all Horde | |
| Shaman | 96136 | Call of Air | 35 (30) | Skyborne | no class mask, shaman sort |
| Shaman | 79358 | Storm, Earth, and Fire | 38 (30) | any | |
| Shaman | 79361 | Storm, Earth, and Fire | 38 (30) | Orc / Tauren / Troll | |
| Shaman | 79366 | Heed My Call | 40 (30) | all Horde | |
| Shaman | 79442 | The Tempest's Weapons | 40 (30) | Orc / Tauren / Troll | |
| Shaman | 7505 | Frost Shock and You | 60 (54) | any | Dire Maul book |
| Warlock | 4785 | Fine Gold Thread | 37 (31) | any | robe chain side quest |
| Warlock | 7601 | What Niby Commands | 50 (50) | any | Infernal chain (C) |
| Warlock | 7602 | Flawless Fel Essence | 55 (50) | any | |
| Warlock | 7603 | Kroshius' Infernal Core | 55 (50) | any | |
| Warlock | 7502 | Harnessing Shadows | 60 (54) | any | Dire Maul book |
| Mage | 1950 | Get the Scoop | 30 (30) | any | wand chain after 1947 |
| Mage | 1949 | Hidden Secrets | 38 (30) | any | |
| Mage | 1948 | Items of Power | 40 (30) | any | |
| Mage | 1951 | Rituals of Power | 40 (30) | any | |
| Mage | 1952 | Mage's Wand | 40 (30) | any | |
| Mage | 1957 | Mana Surges | 40 (35) | any | after 1956 |
| Mage | 1958 | Celestial Power | 40 (35) | any | |
| Mage | 8251 | Magic Dust | 52 (50) | any | after 8250 |
| Mage | 8252 | The Siren's Coral | 52 (50) | any | |
| Mage | 8253 | Destroy Morphaz | 52 (50) | any | Sunken Temple |
| Mage | 7500 | The Arcanist's Cookbook | 60 (54) | any | Dire Maul book |
| Priest | 5691 - 5693, 5704 - 5706 | `<NYI>` Undead priest quests | 15 / 25 | Undead | not implemented placeholders |
| Priest | 7504 | Holy Bologna: What the Light Won't Tell You | 60 (54) | any | Dire Maul book |
| Hunter | 7503 | The Greatest Race of Hunters | 60 (54) | any | Dire Maul book |
| Warrior | 7499 | Codex of Defense | 60 (54) | any | Dire Maul book |

Druid and paladin: none (their class quests are fully in the snapshot).

---------------------------------------------------------------------------------------------------------------

## Appendix C. How the numbers were produced

Scratch scripts (lua5.1 and python3, outside the repository; not kept). To reproduce:

* Class quests: `dofile("tools/data/forever_db.lua")`; a quest belongs to class C when
  `floor(q.classes / bit) % 2 == 1` or `q.zone == enums.classSorts[C]`; Horde-available when the race mask is 0
  or has one of the bits 2 (Orc), 16 (Undead), 32 (Tauren), 128 (Troll), 2^33 (Horde Skyborne), tested with
  `floor(mask / bit) % 2`. `questIndex[id]` is positional: `{name, level, reqLevel, races, classes, zoneOrSort}`.
* Trainers and services: `npcs[id].sub` (sub-name) and `npcs[id].flags`; Horde-friendly = `faction` H, AH or
  empty; first spawn of `spawns[uiMap]`.
* Level before every step of a composed route: a wrapper around `tools/lib/validator.lua` that replaces
  `processStep` of the main run (`getmetatable(V.NewRun(...)).__index.processStep`) and writes
  `ordinal, segment, id, DB.LevelValue(db, run.st), at, npc, actions` per step, then calls `V.Main({ "-q",
  "addons/FastesBoooy_UndeadPaladin" }, ".")` (and the same for `FastesBoooy_SkyborneDruid`). "The path is at X
  at level L" = steps whose `at` lies within a few map units of X. The trace includes the two routes' class
  inserts (the optional paladin chain adds about 0.2 level between 22.7 and 27).
* XP rules: `tools/lib/fbdb.lua` (`DB.XpToLevel`, `DB.MobXp`): a same-level kill is 45 + 5 x level XP.
* Distances: straight lines from map percent and `zones[uiMap].size` (yards); walking times at 7 yd/s. They
  ignore terrain and are meant for ranking, not for step notes.
* Web: WebSearch / WebFetch on 2026-11-10; URLs in section 7.
