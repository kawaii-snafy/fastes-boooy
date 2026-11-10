# Start zones research: Durotar (Orc, Troll), Mulgore (Tauren), early Barrens

Scope: the NEW start zones needed for the "FastesBoooy_Guides" redesign (28 race+class routes): Durotar 1411 /
Orgrimmar 1454 for Orc and Troll, Mulgore 1412 / Thunder Bluff 1456 for Tauren, and the level 10-16 quests of the
Barrens 1413 where these races join the shared path.

Sources and method:

* Everything in sections 1-5 comes from the DB snapshot `tools/data/forever_db.lua` (snapshot date 2026-11-07,
  client 1.60.1.70862), read with throw-away lua5.1 scripts (appendix A). Coordinates are `uiMapID: x, y` in map
  percent, Forever frame, exactly what a route step's `at = { uiMap, x, y }` takes. `(+N)` after a coordinate =
  N more spawn points.
* XP: `xp (src)` is the DB value (`wclbox` = WCLBox mirror of Wowhead, equal to Classic; `questie` = QuestieDB XP
  table). **unknown** = the DB has no XP (all Forever-new quests); `est N` is what the validator would assume
  (`DB.EstimateQuestXp`: median known XP of quests of the same quest level).
* Status: `same` = exists in Classic Era unchanged, **new** = Forever-new, **changed** = flagged as changed by the
  WCLBox data.
* Level projections (section 5) use the validator's own XP model (`tools/lib/validator.lua` defaults): quest XP
  with the level-difference rule, objective kill XP with `dropKillFactor = 1.5` kills per dropped item, no
  incidental kills, no rested XP. Real play is expected to be 0.3-0.5 level higher at 12 (the validator prints
  a "+15 %" band for the same reason).
* Web cross-checks (section 7) were used only to confirm facts; no guide text was copied.

Repository state read (not modified): `addons/FastesBoooy_UndeadPaladin` (ud-01..05), `addons/FastesBoooy_SkyborneDruid`
(sd-01..05), `addons/FastesBoooy_Horde` (h-22..h-56), `docs/VALIDATION.md`, `tools/README.md`,
`docs/dev/research/core.md`.

---------------------------------------------------------------------------------------------------------------

## 0. Summary: what matters for the design, and what contradicts the decisions

1. **The race+class combo list (decision 3) is confirmed by the DB** for Orc, Troll and Tauren: the level-1
   "letter" class quests exist for exactly Orc HUNTER / MAGE (Forever-new 98576) / ROGUE / SHAMAN / WARLOCK /
   WARRIOR, Troll HUNTER / MAGE / PRIEST / ROGUE / SHAMAN / WARLOCK (Forever-new 98575) / WARRIOR, Tauren DRUID /
   HUNTER / SHAMAN / WARRIOR, and a trainer of every one of these classes stands in the start hub of the race
   (section 2). No Tauren rogue / priest / paladin / mage letter exists. Two data gaps for the new combos:
   * **Troll Warlock has no voidwalker quest in the DB**: 1501 Creature of the Void and 1504 The Binding carry
     the race mask Orc only (the Undead pair 1473 / 1471 is Undead only). The breadcrumb 1506 is Horde-wide. Either
     Forever widened the mask and the data is stale, or there is a quest id the snapshot does not have. A step
     with 1501 in a Troll route is a validator race error today.
   * **There is no Mage trainer in Razor Hill** (same as Classic; Orc Mage is new): Orc and Troll mages train in
     the Valley of Trials (Mai'ah 5884), Sen'jin Village (Un'Thuwa 5880) or Orgrimmar.
   * 1859 Therzok (rogue level-10 breadcrumb) is Orc only; Troll rogues go straight to 1963 (Orc+Troll).
2. **Orc and Troll share one start path completely.** Both start in the Valley of Trials, and no non-class
   quest of Durotar, Orgrimmar, the Barrens, Mulgore or Thunder Bluff up to quest level 22 admits only one of the
   two races (script check: the only Orc-vs-Troll differences are class quests). One Durotar segment set serves both races; only the class
   files need race filters (the level-1 letters are 14 different quest ids: one per race x class).
3. **"One shared path for everyone from the Barrens on" (decision 4) has an entry-level gap of about three
   levels.** With every open-world quest of the zone that is on a sensible path, Durotar hands over at **11.5**
   at Far Watch Post (11.7 with the two elite-drop quests, 12.2 with the Skull Rock chain, 13.0 only if the five
   Orgrimmar city quests and the Orc/Troll flight chain are added) and Mulgore at **11.9** at the Crossroads (12.3
   with the harpy quest and the Tauren flight chain). Today's Barrens segments are entered at **14.56** (Undead,
   after Silverpine) and **15.59** (Skyborne, after Zephras + Silverpine): a gap of 30-33k XP to the Undead entry
   level. Durotar and Mulgore have no further quests to fill it. Options with numbers are in section 5.4. The
   cheapest one that keeps a single shared Barrens path is a shared "13-15 Silverpine loop" (today's sd-03
   without its Mulgore head is worth +29.3k XP: 11.6-12.3 becomes 14.3-14.8), which Orc/Troll reach by the
   Durotar zeppelin, but **Tauren have no zeppelin and no Orgrimmar flight point** (web: Thunder Bluff has no
   zeppelin in Forever; DB: no transport NPC in Mulgore / Thunder Bluff except the Skyborne landing). Entering
   today's Barrens segments unchanged at 11.6-12.3 would end them at about 20.3-20.6 instead of 21.6-22.2
   (arithmetic on the validator's segment totals), i.e. 1.2-1.7 levels short at the h-22 hand-over, and several
   of their quests would be accepted two to three levels earlier than planned (867 needs level 12; Barak Kodobane
   and Kreenig Snarlsnout are level 15-16).
4. **Arrival points differ.** Orc/Troll enter the Barrens exactly where ud-04 / sd-04 begin (Razor Hill 840 ->
   Far Watch Post 842 -> Crossroads). Tauren arrive from the south (Camp Taurajo, Tauren-only 854) and cannot take
   840 without walking to Razor Hill. The unified Barrens segment should start at the Crossroads; 840 / 842 belong
   to an "east arrival" piece (Orc, Troll, Undead, Skyborne) and 854 + 860 + 886 to the Mulgore segment.
5. **Flight points at the handover**: Orc/Troll: Orgrimmar only (no flight master in Razor Hill or Sen'jin).
   Tauren: Thunder Bluff, plus Camp Taurajo on the way (no flight master in Bloodhoof). The shared path needs
   Orgrimmar (ud-04 learns it at its first step, sd-03 learns it) and Thunder Bluff (ud-05 walks there): for a
   Tauren the Orgrimmar point is the missing one, for Orc/Troll the Thunder Bluff one is handled by the existing
   ud-05 walk.
6. **The Forever-new quests are a third of the quest XP and none has a known XP value**: Durotar draft 16 of 49
   quests / 9.9k of 27.5k quest XP estimated; Mulgore draft 16 of 53 / 9.2k of 28.2k. One web value exists
   (96821 Legging It = 410 XP where the estimate is 550: one data point, 25 % lower), so the estimated share may be
   too high.
   Every such turn-in is a `WARN xp-unknown` (needs `-- WARN-OK`).
7. **"18 new quests in Durotar, 23 new in Mulgore" is correct as a zone count, but not all of it is 1-12
   content**: Durotar 18 = 15 open to everyone + 3 profession-gated (96873 Enchanting, 96874 Blacksmithing,
   96875 Leatherworking). Mulgore 23 = 13 solid low-level quests + the 3-quest chain 76156 / 76160 / 76240 from
   "Rogue Trainer?" Boarton Shadetotem (looks like unreleased data; two of its items have no source in the DB:
   treat as not available until seen in game) + 5 level-30 quests on the new Skywatcher Plateau + 2 cloth
   donations (level 60). The camping chain (sort -666: 96652 -> 96604 -> 96655 in Durotar, 96659 -> 96605 -> 96661
   in Mulgore) comes on top and is the same mechanic ud-01/02 already uses (96656 -> 96607 -> 96658).
8. **New hubs**: none that changes the 1-12 flow. Durotar: a camp south of Razor Hill (Brakk 265809, 52.0, 47.3),
   Heglan Shadeeye on the east coast (58.6, 45.6), Pal'juh at Kolkar Crag (46.3, 78.6), "Junior" profession
   trainers in the Valley of Trials. Mulgore: Kaga Wildhoof's camp (46.2, 67.3), Perith Stormhoof (33.1, 66.0),
   Malah Longwind (57.6, 63.2), Ahab Wheathoof (47.3, 57.6), "Junior" profession trainers in Camp Narache, and
   the **Skywatcher Plateau** (33.4, 22.6; Skyborne landing, level-30 quests already used by h-27; it has a Druid
   and a Shaman trainer NPC without the usual gossip/questgiver flags).
9. **Mulgore coordinates of Classic guides are wrong in Forever** (the map bounds changed; the DB is already
   converted). Durotar, Orgrimmar, Thunder Bluff and the Barrens kept their geometry.
10. **A base step of the "class-agnostic" Durotar segment is class-filtered by the game**: 792 Vile Familiars is
    for every class but WARLOCK (warlocks get 1485 -> 1499 instead; both lead to 794). Shared segments therefore
    need `classes` filters on base steps, not only on inserts.
11. **No existing segment uses a Durotar or Mulgore zone quest**, so the new start zones cannot collide with the
    shared 15+ path, with one exception: sd-03 does the five Forever-new Orgrimmar city quests (97246, 97249,
    97242, 97275, 97326). If Orc/Troll take them during their Durotar-era Orgrimmar visit, a later shared segment
    must not accept them again (ownership must be decided once).

---------------------------------------------------------------------------------------------------------------

## 1. Quests of the start zones

Non-class quests available to the race(s), grouped by the hub of the quest giver. Left out on purpose: holiday
and event quests (sorts -22, -368 except the two Scourge-invasion leftovers listed for completeness), level-60
mount exchanges (7660-7665), battleground quests (Darkspear Islands 2524 is a battleground map, not a Troll start
zone: 0 NPC spawns, 10 PvP quests), and the 13 profession variants of "Camping 101" (one per profession, each
needs skill 1 in it; Cooking has no requirement and is the one the drafts use).

Race restrictions:

* **Durotar / Orgrimmar: none between Orc and Troll.** Every quest below is Horde-wide except 5843 (Orc+Troll)
  and the flight-path chain 6365 / 6384 / 6385 / 6386 (Orc+Troll, section 4). A Troll can take every quest an Orc
  can; the differences are class quests only (section 3).
* **Mulgore: Tauren-only** quests are the Thunderhorn chain 748 -> 754 -> 756 -> 758 -> 759 -> 760 (and through
  its prerequisite the Forever-new 98435), 854, 5844 and the flight-path chain 6361-6364. Everything else is
  Horde-wide (relevant only for other races passing through).

### 1.1 Durotar (uiMap 1411, 5287 x 3525 yd) and Orgrimmar (1454)

#### Valley of Trials (levels 1-5)

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 4641 | Your Place In The World | 1 | 1 | Horde | Kaltunk 10176 (1411: 43.3, 68.5) | Gornek 3143 (1411: 42.1, 68.3) | next 788; breadcrumb for 788 | - | 40 (wclbox) | same |
| 787 | The New Horde | 1 | 1 | Horde | Eitrigg 3144 (1454: 34.3, 39.4) | Gornek 3143 (1411: 42.1, 68.3) | next 788 | - | 40 (wclbox) | same |
| 788 | Cutting Teeth | 2 | 1 | Horde | Gornek 3143 (1411: 42.1, 68.3) | Gornek 3143 (1411: 42.1, 68.3) | - | kill 10 Mottled Boar (L1-2) | 170 (wclbox) | same |
| 97279 | Wayward Weapons | 2 | 1 | Horde | Gornek 3143 (1411: 42.1, 68.3) | Kzan Thornslash 3159 (1411: 40.5, 68.0) | - | 6 Abandoned Training Weapon [object Abandoned Training Weapon] | **unknown** (est 170) | **new** |
| 789 | Sting of the Scorpid | 3 | 1 | Horde | Gornek 3143 (1411: 42.1, 68.3) | Gornek 3143 (1411: 42.1, 68.3) | pre(any) 788 | 10 Scorpid Worker Tail [Scorpid Worker L3, Sarkoth L4] | 250 (wclbox) | same |
| 4402 | Galgar's Cactus Apple Surprise | 3 | 1 | Horde | Galgar 9796 (1411: 42.7, 67.2) | Galgar 9796 (1411: 42.7, 67.2) | pre(any) 788 | 10 Cactus Apple [object Cactus Apple] | 380 (wclbox) | same |
| 790 | Sarkoth | 5 | 1 | Horde | Hana'zua 3287 (1411: 40.6, 62.6) | Hana'zua 3287 (1411: 40.6, 62.6) | next 804 | 1 Sarkoth's Mangled Claw [Sarkoth L4] | 450 (wclbox) | same |
| 804 | Sarkoth | 5 | 1 | Horde | Hana'zua 3287 (1411: 40.6, 62.6) | Gornek 3143 (1411: 42.1, 68.3) | pre(any) 790 | - | 110 (wclbox) | same |
| 792 | Vile Familiars | 4 | 2 | Horde / all but WARLOCK | Zureetha Fargaze 3145 (1411: 42.9, 69.2) | Zureetha Fargaze 3145 (1411: 42.9, 69.2) | next 794 | kill 12 Vile Familiar (L3-4) | 450 (wclbox) | same |
| 5441 | Lazy Peons | 4 | 3 | Horde | Foreman Thazz'ril 11378 (1411: 44.6, 68.7) | Foreman Thazz'ril 11378 (1411: 44.6, 68.7) | next 6394 | use on 1 Lazy Peon (L4) | 450 (wclbox) | same |
| 6394 | Thazz'ril's Pick | 4 | 3 | Horde | Foreman Thazz'ril 11378 (1411: 44.6, 68.7) | Foreman Thazz'ril 11378 (1411: 44.6, 68.7) | pre(any) 5441 | 1 Thazz'ril's Pick [object Thazz'ril's Pick] | 450 (wclbox) | same |
| 794 | Burning Blade Medallion | 5 | 1 | Horde | Zureetha Fargaze 3145 (1411: 42.9, 69.2) | Zureetha Fargaze 3145 (1411: 42.9, 69.2) | pre(any) 792,1499; next 805 | 1 Burning Blade Medallion [Yarrog Baneshadow L5] | 675 (wclbox) | same |
| 805 | Report to Sen'jin Village | 5 | 1 | Horde | Zureetha Fargaze 3145 (1411: 42.9, 69.2) | Master Gadrin 3188 (1411: 56.0, 74.7) | pre(any) 794 | - | 230 (wclbox) | same |
| 96652 | The Adventurer | 6 | 4 | Horde | object Lost Journal 654925 (1411: 42.8, 69.1) | Brakk 265809 (1411: 52.0, 47.3) | pre(any) 794; next 96604; excl 96627,96628,96630,96638,96656,96659; breadcrumb for 96604 | - | **unknown** (est 550) | **new** |
| 5843 | Welcome! | 1 | 1 | Orc+Troll | item Valley of Trials Gift Voucher 14649 | Magga 11943 (1411: 43.0, 69.4) | - | - | **unknown** (est 40) | same |

#### Sen'jin Village and the south (levels 5-10)

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 2161 | A Peon's Burden | 5 | 1 | Horde | Ukor 6786 (1411: 52.1, 68.3) | Innkeeper Grosk 6928 (1411: 51.5, 41.6) | - | - | 110 (wclbox) | same |
| 808 | Minshina's Skull | 9 | 4 | Horde | Master Gadrin 3188 (1411: 56.0, 74.7) | Master Gadrin 3188 (1411: 56.0, 74.7) | - | 1 Minshina's Skull [object Imprisoned Darkspear] | 775 (wclbox) | same |
| 826 | Zalazane | 10 | 4 | Horde | Master Gadrin 3188 (1411: 56.0, 74.7) | Master Gadrin 3188 (1411: 56.0, 74.7) | - | kill 8 Hexed Troll (L8-9); kill 8 Voodoo Troll (L8-9); 1 Zalazane's Head [Zalazane L10] | 850 (wclbox) | same |
| 823 | Report to Orgnil | 7 | 4 | Horde | Master Gadrin 3188 (1411: 56.0, 74.7) | Orgnil Soulscar 3142 (1411: 52.2, 43.1) | next 806 | - | 320 (wclbox) | same |
| 818 | A Solvent Spirit | 7 | 5 | Horde | Master Vornal 3304 (1411: 55.9, 74.4) | Master Vornal 3304 (1411: 55.9, 74.4) | - | 4 Intact Makrura Eye [Makrura Clacker L6, Makrura Shellhide L6, Makrura Snapclaw L8]; 8 Crawler Mucus [Pygmy Surf Crawler L5, Surf Crawler L7, Encrusted Surf Crawler L9] | 625 (wclbox) | same |
| 817 | Practical Prey | 8 | 5 | Horde | Vel'rin Fang 3194 (1411: 56.0, 73.9) | Vel'rin Fang 3194 (1411: 56.0, 73.9) | - | 4 Durotar Tiger Fur [Durotar Tiger L7, Shal'ma L9 rare] | 700 (wclbox) | same |
| 786 | Thwarting Kolkar Aggression | 8 | 5 | Horde | Lar Prowltusk 3140 (1411: 54.4, 74.3) | Lar Prowltusk 3140 (1411: 54.4, 74.3) | - | use 1 Attack Plan: Valley of Trials; use 1 Attack Plan: Sen'jin Village; use 1 Attack Plan: Orgrimmar | 700 (wclbox) | same |
| 96821 | Legging It | 6 | 1 | Horde | Vel'rin Fang 3194 (1411: 56.0, 73.9) | Gar'Thok 3139 (1411: 52.0, 43.5) | - | kill 6 Ridgeshade Creeper (L5-6); kill 6 Ridgeshade Lurker (L5-6) | **unknown in DB**; 410 per warcraft.wiki.gg | **new** |
| 97225 | Forgotten Loa Idols | 9 | 4 | Horde | Master Vornal 3304 (1411: 55.9, 74.4) | Master Gadrin 3188 (1411: 56.0, 74.7) | - | 8 Forgotten Loa Idol [object Forgotten Loa Idol] | **unknown** (est 775) | **new** |
| 97223 | Bloodtalon Matriarch | 9 | 5 | Horde | Xar'Ti 7953 (1411: 55.3, 75.5) | Xar'Ti 7953 (1411: 55.3, 75.5) | - | 1 Bloodtalon Matriarch Eggs [Bloodtalon Matriarch L9] | **unknown** (est 775) | **new** |
| 99123 | Lost in the Shadows | 8 | 4 | Horde | Pal'juh 275811 (1411: 46.3, 78.6) | Master Vornal 3304 (1411: 55.9, 74.4) | - | escort; trigger 1411: 51.4, 79.3 | **unknown** (est 700) | **new** |
| 96873 | A Pain in the Neck | 8 | 5 | Horde | Pa'zula 266881 (1411: 56.7, 73.7) | Pa'zula 266881 (1411: 56.7, 73.7) | PROFESSION 333>=1 | 3 Luminous Residue [source not in DB] | **unknown** (est 700) | **new** |
| 96876 | Ukor's Lost Pack | 8 | 5 | Horde | item Ukor's Lost Pack 275722 from Ukorsbane 266851 | Ukor 6786 (1411: 52.1, 68.3) | - | - | **unknown** (est 700) | **new** |

#### Razor Hill and the east coast (levels 6-12)

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 96604 | The Great Outdoors | 6 | 4 | Horde | Brakk 265809 (1411: 52.0, 47.3) | Brakk 265809 (1411: 52.0, 47.3) | excl 95998,96101,96605,96606,96607,96608 | use 1 Basic Campfire; use 1 Basic Campfire | **unknown** (est 550) | **new** |
| 96655 | Camping 101: Cooking | 6 | 4 | Horde | Brakk 265809 (1411: 52.0, 47.3) | Cook Torka 3191 (1411: 51.1, 42.5) | pre(any) 95998,96101,96604,96605,96606,96607,96608; excl 96626,96629,96634,96646,96658,96661 | talk to 1 Cook Torka (L6) | **unknown** (est 550) | **new** |
| 784 | Vanquish the Betrayers | 7 | 3 | Horde | Gar'Thok 3139 (1411: 52.0, 43.5) | Gar'Thok 3139 (1411: 52.0, 43.5) | next 825 | kill 10 Kul Tiras Sailor (L5-6); kill 8 Kul Tiras Marine (L6-7); kill 1 Lieutenant Benedict (L8) | 625 (wclbox) | same |
| 830 | The Admiral's Orders | 7 | 1 | Horde | item Aged Envelope 4881 from object Benedict's Chest 3239 (1411: 59.3, 57.6) | Gar'Thok 3139 (1411: 52.0, 43.5) | next 831 | - | 625 (wclbox) | same |
| 831 | The Admiral's Orders | 7 | 1 | Horde | Gar'Thok 3139 (1411: 52.0, 43.5) | Nazgrel 3230 (1454: 32.3, 35.8) | pre(any) 830 | - | 625 (wclbox) | same |
| 825 | From The Wreckage.... | 8 | 3 | Horde | Gar'Thok 3139 (1411: 52.0, 43.5) | Gar'Thok 3139 (1411: 52.0, 43.5) | pre(any) 784 | 3 Gnomish Tools [object Gnomish Toolbox] | 700 (wclbox) | same |
| 791 | Carry Your Weight | 7 | 4 | Horde | Furl Scornbrow 3147 (1411: 49.9, 40.4) | Furl Scornbrow 3147 (1411: 49.9, 40.4) | - | 8 Canvas Scraps [Kolkar Drudge L6, Kolkar Outrunner L7, Kul Tiras Sailor L5] | 625 (wclbox) | same |
| 815 | Break a Few Eggs | 8 | 6 | Horde | Cook Torka 3191 (1411: 51.1, 42.5) | Cook Torka 3191 (1411: 51.1, 42.5) | - | 3 Taillasher Egg [object Taillasher Eggs] | 700 (wclbox) | same |
| 96825 | This Fruit Could Bite Back | 6 | 3 | Horde | Cook Torka 3191 (1411: 51.1, 42.5) | Cook Torka 3191 (1411: 51.1, 42.5) | - | 8 Prickly Pear Fruit [object Prickly Pear Fruit] | **unknown** (est 550) | **new** |
| 96822 | For Honor | 7 | 3 | Horde | Turroc 266940 (1411: 54.0, 42.6) | Turroc 266940 (1411: 54.0, 42.6) | - | 1 Raider's Bow [object Raider's Bow]; 1 Raider's Battleaxe [object Raider's Battleaxe]; 1 Raider's Shield [object Raider's Shield] | **unknown** (est 625) | **new** |
| 837 | Encroachment | 10 | 6 | Horde | Gar'Thok 3139 (1411: 52.0, 43.5) | Gar'Thok 3139 (1411: 52.0, 43.5) | - | kill 4 Razormane Quilboar (L6-7); kill 4 Razormane Scout (L7-8); kill 4 Razormane Dustrunner (L8-9); kill 4 Razormane Battleguard (L9-10) | 625 (wclbox) | same |
| 806 | Dark Storms | 12 | 4 | Horde | Orgnil Soulscar 3142 (1411: 52.2, 43.1) | Orgnil Soulscar 3142 (1411: 52.2, 43.1) | pre(any) 823; next 828 | 1 Fizzle's Claw [Fizzle Darkstorm L12] | 900 (wclbox) | same |
| 828 | Margoz | 12 | 4 | Horde | Orgnil Soulscar 3142 (1411: 52.2, 43.1) | Margoz 3208 (1411: 56.4, 20.0) | pre(any) 806; next 827 | - | 90 (wclbox) | same |
| 99048 | A Missing Hand | 9 | 9 | Horde | Orgnil Soulscar 3142 (1411: 52.2, 43.1) | Heglan Shadeeye 275657 (1411: 58.6, 45.6) | next 99049 | - | **unknown** (est 775) | **new** |
| 99049 | Threat from Below | 9 | 9 | Horde | Heglan Shadeeye 275657 (1411: 58.6, 45.6) | Orgnil Soulscar 3142 (1411: 52.2, 43.1) | pre(any) 99048; next 99051 | 1 Orcish Dagger [object Abandoned Dagger]; 1 Banner Scrap [object Strange Debris]; 1 Broken Bone Trident [object Weapon Piece] | **unknown** (est 775) | **new** |
| 99051 | Threat from Below | 11 | 9 | Horde | Orgnil Soulscar 3142 (1411: 52.2, 43.1) | Orgnil Soulscar 3142 (1411: 52.2, 43.1) | pre(any) 99049; next 99052 | 9 Naga Spinefin [Spitelash Scout L9, Spitelash Attendant L10] | **unknown** (est 660) | **new** |
| 99052 | Threat from Below | 11 | 10 | Horde | Orgnil Soulscar 3142 (1411: 52.2, 43.1) | Orgnil Soulscar 3142 (1411: 52.2, 43.1) | pre(any) 99051 | 1 Aggor's Belt [Aggor the Young L11 elite] | **unknown** (est 660) | **new** |
| 840 | Conscript of the Horde | 12 | 10 | Horde | Takrin Pathseeker 3336 (1411: 50.8, 43.6) | Kargal Battlescar 3337 (1413: 62.3, 19.4) | next 842 | - | 460 (wclbox) | same |

#### North Durotar field givers (levels 7-12)

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 834 | Winds in the Desert | 9 | 7 | ALL | Rezlak 3293 (1411: 46.4, 22.9) | Rezlak 3293 (1411: 46.4, 22.9) | next 835 | 5 Sack of Supplies [object Stolen Supply Sack] | 775 (wclbox) | same |
| 835 | Securing the Lines | 11 | 7 | ALL | Rezlak 3293 (1411: 46.4, 22.9) | Rezlak 3293 (1411: 46.4, 22.9) | pre(any) 834 | kill 12 Dustwind Savage (L9-10); kill 8 Dustwind Storm Witch (L10-11) | 875 (wclbox) | same |
| 97281 | A Simmering Storm | 11 | 7 | Horde | item Dull Storm Orb 277661 from Dustwind Storm Witch 3118 / Dustwind Eggtender 276194 | Rezlak 3293 (1411: 46.4, 22.9) | next 97282 | - | **unknown** (est 660) | **new** |
| 97282 | Stormy Potential | 10 | 7 | Horde | Rezlak 3293 (1411: 46.4, 22.9) | Rezlak 3293 (1411: 46.4, 22.9) | pre(any) 97281 | 5 Charged Thunder Lizard Organ [Thunder Lizard L9, Lightning Hide L10, Halikor L12 elite] | **unknown** (est 420) | **new** |
| 816 | Lost But Not Forgotten | 11 | 8 | Horde | Misha Tor'kren 3193 (1411: 43.1, 30.2) | Misha Tor'kren 3193 (1411: 43.1, 30.2) | - | 1 Kron's Amulet [Dreadmaw Crocolisk L9, Corrupted Dreadmaw Crocolisk L11] | 875 (wclbox) | same |
| 812 | Need for a Cure | 9 | 7 | Horde | Rhinag 3190 (1411: 41.5, 18.6) | Rhinag 3190 (1411: 41.5, 18.6) | - | 1 Venomtail Antidote [Kor'ghan L7] | 975 (wclbox) | same |
| 813 | Finding the Antidote | 9 | 7 | Horde | Kor'ghan 3189 (1454: 47.2, 53.6) | Kor'ghan 3189 (1454: 47.2, 53.6) | parent 812; special=1 | 4 Venomtail Poison Sac [Venomtail Scorpid L9, Corrupted Scorpid L10, Death Flayer L11 rare] | **unknown** (est 775) | same |
| 827 | Skull Rock | 12 | 4 | Horde | Margoz 3208 (1411: 56.4, 20.0) | Margoz 3208 (1411: 56.4, 20.0) | pre(any) 828; next 829 | 6 Searing Collar [Burning Blade Thug L8, Burning Blade Neophyte L9, Burning Blade Fanatic L9] | 900 (wclbox) | same |
| 829 | Neeru Fireblade | 12 | 4 | Horde | Margoz 3208 (1411: 56.4, 20.0) | Neeru Fireblade 3216 (1454: 49.5, 50.6) | pre(any) 827; next 809 | - | 460 (wclbox) | same |
| 832 | Burning Shadows | 12 | 4 | Horde | item Eye of Burning Shadow 4903 from Gazz'uz 3204 | Neeru Fireblade 3216 (1454: 49.5, 50.6) | - | - | 675 (wclbox) | same |

#### Orgrimmar (levels 9-15)

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 5726 | Hidden Enemies | 12 | 9 | Horde | Thrall 4949 (1454: 31.7, 37.8) | Thrall 4949 (1454: 31.7, 37.8) | next 5727 | 1 Lieutenant's Insignia [Burning Blade Fanatic L9, Burning Blade Apprentice L10] | 900 (wclbox) | same |
| 5727 | Hidden Enemies | 12 | 9 | Horde | Thrall 4949 (1454: 31.7, 37.8) | Thrall 4949 (1454: 31.7, 37.8) | pre(any) 5726; next 5728; special=2 | talk to 1 Neeru Fireblade (L37) | 460 (wclbox) | same |
| 809 | Ak'Zeloth | 13 | 4 | Horde | Neeru Fireblade 3216 (1454: 49.5, 50.6) | Ak'Zeloth 3521 (1413: 62.3, 20.1) | pre(any) 829; next 924 | area/script event; trigger 1413: 62.3, 20.1 | 460 (wclbox) | same |
| 96874 | This Is Spinal Axe | 10 | 6 | Horde | Ug'thok 10266 (1454: 80.8, 23.7) | Ug'thok 10266 (1454: 80.8, 23.7) | PROFESSION 164>=1 | 5 Weathered Spine [Thunder Lizard L9, Lightning Hide L10, Halikor L12 elite]; 5 Rough Grinding Stone [source not in DB] | **unknown** (est 420) | **new** |
| 96875 | Beasts of Thunder Ridge | 10 | 6 | Horde | Kamari 5811 (1454: 63.3, 44.8) | Kamari 5811 (1454: 63.3, 44.8) | PROFESSION 165>=1 | 5 Rough Lizard Hide [Thunder Lizard L9, Lightning Hide L10, Halikor L12 elite]; 2 Cured Light Hide [source not in DB] | **unknown** (est 420) | **new** |
| 96877 | Halikor's Hoof | 12 | 6 | Horde | item Halikor's Hoof 275723 from Halikor 266852 | Kamari 5811 (1454: 63.3, 44.8) | - | - | **unknown** (est 460) | **new** |
| 97246 | Meal Appeal | 15 | 5 | Horde | Thatog 268701 (1454: 55.7, 72.2) | Borstan 3368 (1454: 57.2, 53.3) | - | - | **unknown** (est 1050) | **new** |
| 97249 | Favorite Food | 15 | 5 | Horde | Borstan 3368 (1454: 57.2, 53.3) | Migi 268682 (1454: 36.5, 29.1) | - | - | **unknown** (est 1050) | **new** |
| 97242 | Yelmak's Medley | 15 | 9 | Horde | Kor'geld 3348 (1454: 56.0, 34.1) | Kor'geld 3348 (1454: 56.0, 34.1) | - | 2 Handful of Cattails [object Cattail]; 4 Speargrass Cuttings [object Speargrass] | **unknown** (est 1050) | **new** |
| 97275 | Whuut's the Rush | 15 | 9 | Horde | Yelmak 3347 (1454: 56.8, 33.0) | Whuut 11046 (1454: 55.8, 32.9) | - | - | **unknown** (est 1050) | **new** |
| 97326 | Rocks to Rests | 15 | 5 | Horde | Thra 268684 (1454: 36.8, 29.1) | Thra 268684 (1454: 36.8, 29.1) | - | 8 Smooth Boulder [object Smooth Boulder, object Smooth Boulder, object Smooth Boulder] | **unknown** (est 1050) | **new** |
| 9263 | Investigate the Scourge of Orgrimmar | 10 | 1 | Horde | Lieutenant Dagel 16493 (1454: 51.6, 82.0) | Lieutenant Dagel 16493 (1454: 51.6, 82.0) | special=2 | 3 Dim Necrotic Stone [Skeletal Soldier L6, Spectral Apparition L6, Spectral Spirit L9]; area/script event; trigger 1411: 44.6, 18.1 | 625 (wclbox) | same |

#### Far Watch Post (The Barrens side of the bridge)

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 842 | Crossroads Conscription | 12 | 10 | Horde | Kargal Battlescar 3337 (1413: 62.3, 19.4) | Sergra Darkthorn 3338 (1413: 52.2, 31.0) | pre(any) 840 | - | 900 (wclbox) | same |
| 924 | The Demon Seed | 14 | 9 | Horde | Ak'Zeloth 3521 (1413: 62.3, 20.1) | Ak'Zeloth 3521 (1413: 62.3, 20.1) | pre(any) 809; special=2 | use 1 The Altar of Fire | 1250 (wclbox) | same |
| 926 | Flawed Power Stone | 14 | 1 | Horde | object Flawed Power Stone 5619 (1413: 62.3, 20.0); object Flawed Power Stones 5620 (1413: 62.3, 20.0) | object Flawed Power Stone 5619 (1413: 62.3, 20.0); object Flawed Power Stones 5620 (1413: 62.3, 20.0) | parent 924; special=1 | - | **unknown** (est 750) | same |

Notes on Durotar:

* **Valley of Trials flow**: 4641 -> 788 (+ 97279 from the same NPC, the weapons lie among the boars) -> after the
  788 turn-in Gornek offers 789 and the level-1 class letter (section 3); 4402 and 792 open with 788 / level 2;
  5441 needs level 3 (-> 6394, the pick is in the Burning Blade Coven next to Yarrog, 794). 96652 The Adventurer
  starts from the object Lost Journal 654925 in the Den (42.8, 69.1) and needs 794 turned in, so it is the last
  pick-up of the valley; it is turned in at Brakk's camp south of Razor Hill.
* 787 The New Horde is the Orgrimmar-side breadcrumb to Gornek (not reachable for a level-1 character).
* **Elite / rare sources** (rank in the DB): 96876 needs Ukor's Lost Pack from Ukorsbane 266851 (level 8 elite,
  patrols 49-54, 46-61 between Razor Hill and Sen'jin); 99052 Aggor the Young 275666 (level 11 elite, 59.2, 17.6);
  96877 Halikor 266852 (level 12 elite, Thunder Ridge). Treat these three as `optional`.
* **Item-started quests**: 830 (Benedict's Chest 3239 in Tiragarde Keep, 59.3, 57.6), 832 (Gazz'uz 3204,
  level 14, Skull Rock), 97281 (Dull Storm Orb from Dustwind Storm Witch 3118 / rare Eggtender), 96876, 96877.
* 813 Finding the Antidote is the repeatable hand-in inside 812 (timed in Classic); 926 is the repeatable stone
  refill of 924.
* 99123 Lost in the Shadows is an escort from Pal'juh (46.3, 78.6) to the trigger at 51.4, 79.3, turned in at
  Master Vornal in Sen'jin: it pairs with 786 (Kolkar Crag, same place).
* The Orgrimmar deliveries 97246 -> 97249, 97242 -> 97275 and 97326 are quest level 15 with required level 5-9
  (full XP from level 5 on, estimate 1050 each): a pure city run. sd-03 already contains the exact steps.
* 5726 -> 5727 (Thrall) continues into Ragefire Chasm (5728); 829 -> 809 -> 924 ends at Far Watch Post and in the
  Barrens (Dreadmist Peak).

### 1.2 Mulgore (uiMap 1412, 6154 x 4102 yd) and Thunder Bluff (1456)

Mulgore's map bounds changed in Forever (`tools/README.md`: geometry changed for Mulgore 215; the DB is
already converted). Use only the coordinates below, never Classic-era guide coordinates.

#### Camp Narache / Red Cloud Mesa (levels 1-6)

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 747 | The Hunt Begins | 2 | 1 | Horde | Grull Hawkwind 2980 (1412: 44.5, 77.5) | Grull Hawkwind 2980 (1412: 44.5, 77.5) | - | 7 Plainstrider Meat [Plainstrider L1]; 7 Plainstrider Feather [Plainstrider L1] | 170 (wclbox) | same |
| 752 | A Humble Task | 2 | 1 | Horde | Chief Hawkwind 2981 (1412: 43.9, 76.7) | Greatmother Hawkwind 2991 (1412: 48.8, 80.9) | next 753; breadcrumb for 753 | - | 85 (wclbox) | same |
| 753 | A Humble Task | 3 | 1 | Horde | Greatmother Hawkwind 2991 (1412: 48.8, 80.9) | Chief Hawkwind 2981 (1412: 43.9, 76.7) | next 755 | 1 Water Pitcher [object Water Pitcher, object Water Pitcher] | 250 (wclbox) | same |
| 750 | The Hunt Continues | 3 | 1 | Horde | Grull Hawkwind 2980 (1412: 44.5, 77.5) | Grull Hawkwind 2980 (1412: 44.5, 77.5) | pre(any) 747; next 780 | 10 Mountain Cougar Pelt [Mountain Cougar L3] | 250 (wclbox) | same |
| 755 | Rites of the Earthmother | 3 | 1 | Horde | Chief Hawkwind 2981 (1412: 43.9, 76.7) | Seer Graytongue 2982 (1412: 42.5, 90.1) | pre(any) 753; next 757 | - | 250 (wclbox) | same |
| 757 | Rite of Strength | 4 | 1 | Horde | Seer Graytongue 2982 (1412: 42.5, 90.1) | Chief Hawkwind 2981 (1412: 43.9, 76.7) | pre(any) 755; next 763 | 12 Bristleback Belt [Bristleback Quilboar L3, Bristleback Shaman L3] | 450 (wclbox) | same |
| 95805 | Grace of An'she and Mu'sha | 4 | 1 | Horde | Seer Graytongue 2982 (1412: 42.5, 90.1) | object Ritual Fire 660739 (1412: 56.6, 88.7) | pre(any) 755 | - | **unknown** (est 355) | **new** |
| 780 | The Battleboars | 4 | 1 | Horde | Grull Hawkwind 2980 (1412: 44.5, 77.5) | Grull Hawkwind 2980 (1412: 44.5, 77.5) | pre(any) 750 | 8 Battleboar Snout [Bristleback Battleboar L4, Battleboar L3]; 8 Battleboar Flank [Bristleback Battleboar L4, Battleboar L3] | 450 (wclbox) | same |
| 3376 | Break Sharptusk! | 5 | 3 | Horde | Brave Windfeather 3209 (1412: 44.2, 77.0) | Brave Windfeather 3209 (1412: 44.2, 77.0) | - | 1 Chief Sharptusk Thornmantle's Head [Chief Sharptusk Thornmantle L5] | 675 (wclbox) | same |
| 781 | Attack on Camp Narache | 4 | 1 | Horde | item Dirt-stained Map 4851 from object Dirt-stained Map 3076 (1412: 59.8, 82.2) | Chief Hawkwind 2981 (1412: 43.9, 76.7) | - | - | 360 (wclbox) | same |
| 763 | Rites of the Earthmother | 5 | 1 | Horde | Chief Hawkwind 2981 (1412: 43.9, 76.7) | Baine Bloodhoof 2993 (1412: 46.7, 63.4) | pre(any) 757; next 767; breadcrumb for 767 | - | 340 (wclbox) | same |
| 1656 | A Task Unfinished | 5 | 1 | Horde | Antur Fallow 6775 (1412: 39.2, 81.2) | Innkeeper Kauth 6747 (1412: 45.9, 64.2) | - | - | 110 (wclbox) | same |
| 96659 | The Adventurer | 6 | 4 | Horde | Chief Hawkwind 2981 (1412: 43.9, 76.7) | Kaga Wildhoof 265810 (1412: 46.2, 67.3) | pre(any) 757; next 96605; excl 96627,96628,96630,96638,96652,96656; breadcrumb for 96605 | - | **unknown** (est 550) | **new** |
| 5844 | Welcome! | 1 | 1 | Tauren | item Camp Narache Gift Voucher 14650 | Vorn Skyseer 11944 (1412: 44.0, 77.4) | - | - | **unknown** (est 40) | same |

#### Bloodhoof Village (levels 5-12)

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 96605 | The Great Outdoors | 6 | 4 | Horde | Kaga Wildhoof 265810 (1412: 46.2, 67.3) | Kaga Wildhoof 265810 (1412: 46.2, 67.3) | excl 95998,96101,96604,96606,96607,96608 | use 1 Basic Campfire; use 1 Basic Campfire | **unknown** (est 550) | **new** |
| 96661 | Camping 101: Cooking | 6 | 4 | Horde | Kaga Wildhoof 265810 (1412: 46.2, 67.3) | Pyall Silentstride 3067 (1412: 44.9, 61.7) | pre(any) 95998,96101,96604,96605,96606,96607,96608; excl 96626,96629,96634,96646,96655,96658 | talk to 1 Pyall Silentstride (L12) | **unknown** (est 550) | **new** |
| 767 | Rite of Vision | 6 | 3 | Horde | Baine Bloodhoof 2993 (1412: 46.7, 63.4) | Zarlman Two-Moons 3054 (1412: 46.9, 61.2) | next 771 | - | 55 (wclbox) | same |
| 771 | Rite of Vision | 7 | 3 | Horde | Zarlman Two-Moons 3054 (1412: 46.9, 61.2) | Zarlman Two-Moons 3054 (1412: 46.9, 61.2) | pre(any) 767; next 772 | 2 Well Stone [Razorlash L48 elite, object Well Stone]; 2 Ambercorn [object Ambercorn] | 625 (wclbox) | same |
| 772 | Rite of Vision | 7 | 3 | Horde | Zarlman Two-Moons 3054 (1412: 46.9, 61.2) | Seer Wiserunner 2984 (1412: 34.3, 43.3) | pre(any) 771; next 773 | - | 480 (wclbox) | same |
| 748 | Poison Water | 5 | 4 | Tauren | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | next 754 | 6 Prairie Wolf Paw [Prairie Wolf L5, Prairie Stalker L7, Prairie Wolf Alpha L9]; 4 Plainstrider Talon [Plainstrider L1, Adult Plainstrider L6, Elder Plainstrider L8] | 450 (wclbox) | same |
| 754 | Winterhoof Cleansing | 6 | 4 | Tauren | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | pre(any) 748; next 756; special=2 | area/script event; trigger 1412: 51.8, 68.4 | 550 (wclbox) | same |
| 756 | Thunderhorn Totem | 7 | 4 | Tauren | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | pre(any) 754; next 758 | 6 Stalker Claws [Prairie Stalker L7]; 6 Cougar Claws [Flatland Cougar L7] | 625 (wclbox) | same |
| 758 | Thunderhorn Cleansing | 8 | 4 | Tauren | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | pre(any) 756; next 759; special=2 | area/script event; trigger 1412: 44.2, 51.1 | 700 (wclbox) | same |
| 759 | Wildmane Totem | 10 | 4 | Tauren | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | pre(any) 758; next 760 | 8 Prairie Alpha Tooth [Prairie Wolf Alpha L9] | 850 (wclbox) | same |
| 760 | Wildmane Cleansing | 10 | 4 | Tauren | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | pre(any) 759; next 98435; special=2 | area/script event; trigger 1412: 42.7, 25.0 | 1050 (wclbox) | same |
| 98435 | Thunderhorn's Report | 10 | 4 | Horde | Mull Thunderhorn 2948 (1412: 47.5, 63.6) | Arch Druid Hamuul Runetotem 5769 (1456: 78.6, 28.6) | pre(any) 760 | - | **unknown** (est 420) | **new** |
| 761 | Swoop Hunting | 6 | 4 | Horde | Harken Windtotem 2947 (1412: 47.7, 62.7) | Harken Windtotem 2947 (1412: 47.7, 62.7) | - | 8 Trophy Swoop Quill [Wiry Swoop L5, Swoop L7, Taloned Swoop L8] | 675 (wclbox) | same |
| 743 | Dangers of the Windfury | 8 | 5 | Horde | Ruul Eagletalon 2985 (1412: 46.5, 64.9) | Ruul Eagletalon 2985 (1412: 46.5, 64.9) | - | 8 Windfury Talon [Windfury Harpy L7, Windfury Wind Witch L8] | 700 (wclbox) | same |
| 745 | Sharing the Land | 8 | 1 | Horde | Baine Bloodhoof 2993 (1412: 46.7, 63.4) | Baine Bloodhoof 2993 (1412: 46.7, 63.4) | - | kill 10 Palemane Tanner (L5-6); kill 8 Palemane Skinner (L6-7); kill 5 Palemane Poacher (L7-8) | 550 (wclbox) | **changed** |
| 746 | Dwarven Digging | 8 | 6 | Horde | Baine Bloodhoof 2993 (1412: 46.7, 63.4) | Baine Bloodhoof 2993 (1412: 46.7, 63.4) | - | 5 Broken Tools [object Forge] | 700 (wclbox) | same |
| 766 | Mazzranache | 8 | 5 | Horde | Maur Raincaller 3055 (1412: 46.2, 60.8) | Maur Raincaller 3055 (1412: 46.2, 60.8) | - | 1 Prairie Wolf Heart [Prairie Wolf L5, Prairie Stalker L7, Prairie Wolf Alpha L9]; 1 Flatland Cougar Femur [Flatland Cougar L7]; 1 Plainstrider Scale [Adult Plainstrider L6, Elder Plainstrider L8, Mazzranache L9 rare]; 1 Swoop Gizzard [Wiry Swoop L5, Swoop L7, Taloned Swoop L8] | 700 (wclbox) | same |
| 96130 | Chakuyak | 5 | 4 | Horde | Yaw Sharpmane 3065 (1412: 46.9, 59.6) | Yaw Sharpmane 3065 (1412: 46.9, 59.6) | - | 1 Chakuyak's Pelt [Chakuyak L5] | **unknown** (est 335) | **new** |
| 99108 | Sparring Match | 6 | 4 | Horde | Krang Stonehoof 3063 (1412: 48.4, 63.7) | Krang Stonehoof 3063 (1412: 48.4, 63.7) | - | kill 1 Novice Warrior (L5) | **unknown** (est 550) | **new** |
| 99411 | Kyle's Gone Missing! | 7 | 5 | Horde | Ahab Wheathoof 277182 (1412: 47.3, 57.6) | Ahab Wheathoof 277182 (1412: 47.3, 57.6) | - | use on 1 Kyle the Frenzied (L12) | **unknown** (est 625) | **new** |
| 99079 | Longwalker Malah | 9 | 4 | Horde | Brave Wildrunner 3222 (1412: 46.7, 63.8) | Malah Longwind 275789 (1412: 57.6, 63.2) | next 99081 | - | **unknown** (est 775) | **new** |
| 99081 | Grim Tidings | 9 | 4 | Horde | Malah Longwind 275789 (1412: 57.6, 63.2) | Brave Wildrunner 3222 (1412: 46.7, 63.8) | pre(any) 99079; next 99101 | - | **unknown** (est 775) | **new** |
| 99101 | Our Ancient Enemy | 9 | 4 | Horde | Brave Wildrunner 3222 (1412: 46.7, 63.8) | Baine Bloodhoof 2993 (1412: 46.7, 63.4) | pre(any) 99081; next 99080 | - | **unknown** (est 775) | **new** |
| 99080 | Drive Them Out | 11 | 4 | Horde | Baine Bloodhoof 2993 (1412: 46.7, 63.4) | Baine Bloodhoof 2993 (1412: 46.7, 63.4) | pre(any) 99101; next 99082 | kill 6 Galak Centaur (L8-9); kill 4 Galak Outrunner (L9-10); 1 Herak's Head [Herak the Pillager L11] | **unknown** (est 660) | **new** |
| 99082 | The High Chieftain | 11 | 4 | Horde | Baine Bloodhoof 2993 (1412: 46.7, 63.4) | Cairne Bloodhoof 3057 (1456: 60.3, 51.7) | pre(any) 99080 | - | **unknown** (est 660) | **new** |
| 861 | The Hunter's Way | 10 | 10 | Horde | Skorn Whitecloud 3052 (1412: 46.0, 63.4) | Melor Stonehoof 3441 (1456: 61.5, 80.9) | next 860; excl 844 | 4 Flatland Prowler Claw [Flatland Prowler L9] | 850 (wclbox) | same |
| 770 | The Demon Scarred Cloak | 12 | 6 | Horde | item Demon Scarred Cloak 4854 from Ghost Howl 3056 | Skorn Whitecloud 3052 (1412: 46.0, 63.4) | - | - | 900 (wclbox) | same |

#### Mulgore field givers (levels 8-12)

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 749 | The Ravaged Caravan | 8 | 5 | Horde | Morin Cloudstalker 2988 (1412: 54.8, 64.3) | object Sealed Supply Crate 2908 (1412: 51.9, 53.4) | next 751 | - | 525 (wclbox) | same |
| 751 | The Ravaged Caravan | 8 | 5 | Horde | object Sealed Supply Crate 2908 (1412: 51.9, 53.4) | Morin Cloudstalker 2988 (1412: 54.8, 64.3) | pre(any) 749 | - | 525 (wclbox) | same |
| 764 | The Venture Co. | 10 | 5 | Horde | Morin Cloudstalker 2988 (1412: 54.8, 64.3) | Morin Cloudstalker 2988 (1412: 54.8, 64.3) | pre(any) 751 | kill 14 Venture Co. Worker (L8-9); kill 6 Venture Co. Supervisor (L9-10) | 625 (wclbox) | same |
| 765 | Supervisor Fizsprocket | 12 | 5 | Horde | Morin Cloudstalker 2988 (1412: 54.8, 64.3) | Morin Cloudstalker 2988 (1412: 54.8, 64.3) | pre(any) 751 | 1 Fizsprocket's Clipboard [Supervisor Fizsprocket L12] | 900 (wclbox) | same |
| 98424 | Fizsprocket's Notes | 10 | 5 | Horde | item Mulgore Expansion Plans 281031 from Supervisor Fizsprocket 3051 | Morin Cloudstalker 2988 (1412: 54.8, 64.3) | next 98427 | 1 Shredder Operation Instructions [object Shredder Operation Instructions]; 1 Barrens Operations Best Practices [object Barrens Operations Best Practices]; 1 One "Gerenzo", of Stonetalon [object One "Gerenzo", of Stonetalon] | **unknown** (est 420) | **new** |
| 98427 | Ceasing Operations | 12 | 5 | Horde | Morin Cloudstalker 2988 (1412: 54.8, 64.3) | Morin Cloudstalker 2988 (1412: 54.8, 64.3) | pre(any) 98424 | 1 Clearcutter Key [Venture Co. Clearclutter L12 elite] | **unknown** (est 460) | **new** |
| 98430 | The Longwalkers | 8 | 1 | Horde | Perith Stormhoof 272203 (1412: 33.1, 66.0) | Cairne Bloodhoof 3057 (1456: 60.3, 51.7) | - | escort; trigger 1412: 37.2, 64.6 | **unknown** (est 700) | **new** |
| 773 | Rite of Wisdom | 10 | 3 | Horde | Seer Wiserunner 2984 (1412: 34.3, 43.3) | Ancestral Spirit 2994 (1412: 58.3, 30.7) | pre(any) 772; next 775 | - | 850 (wclbox) | same |
| 775 | Journey into Thunder Bluff | 10 | 3 | Horde | Ancestral Spirit 2994 (1412: 58.3, 30.7) | Cairne Bloodhoof 3057 (1456: 60.3, 51.7) | pre(any) 773; next 776 | - | 420 (wclbox) | same |
| 833 | A Sacred Burial | 10 | 7 | Horde | Lorekeeper Raintotem 3233 (1412: 57.0, 34.5) | Lorekeeper Raintotem 3233 (1412: 57.0, 34.5) | - | kill 8 Bristleback Interloper (L9-10) | 625 (wclbox) | same |

#### Thunder Bluff (levels 8-14)

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 776 | Rites of the Earthmother | 14 | 3 | Horde | Cairne Bloodhoof 3057 (1456: 60.3, 51.7) | Cairne Bloodhoof 3057 (1456: 60.3, 51.7) | pre(any) 775 | 1 Horn of Arra'chea [Arra'chea L11] | 1250 (wclbox) | same |
| 744 | Preparation for Ceremony | 11 | 7 | Horde | Eyahn Eagletalon 2987 (1456: 37.8, 59.6) | Eyahn Eagletalon 2987 (1456: 37.8, 59.6) | - | 6 Azure Feather [Windfury Sorceress L9]; 6 Bronze Feather [Windfury Matriarch L10] | 875 (wclbox) | same |
| 860 | Sergra Darkthorn | 10 | 10 | Horde | Melor Stonehoof 3441 (1456: 61.5, 80.9) | Sergra Darkthorn 3338 (1413: 52.2, 31.0) | pre(any) 861; next 844; breadcrumb for 844 | - | 85 (wclbox) | same |
| 886 | The Barrens Oases | 10 | 10 | Horde | Arch Druid Hamuul Runetotem 5769 (1456: 78.6, 28.6) | Tonga Runetotem 3448 (1413: 52.3, 31.9) | next 870; breadcrumb for 870 | - | 85 (wclbox) | same |
| 97485 | Traditions of the Bluff | 10 | 3 | Horde | Eylah Sunhorn 269068 (1456: 38.0, 55.9) | Eylah Sunhorn 269068 (1456: 38.0, 55.9) | - | use 1 Incense Burner; 1 Prepared Incense [source not in DB] | **unknown** (est 420) | **new** |
| 76156 | Stalk With The Earthmother | 10 | 4 | Horde | Boarton Shadetotem 205729 (1456: 39.4, 65.8) | Boarton Shadetotem 205729 (1456: 39.4, 65.8) | next 76160 | 5 Seaforium Mining Charge [object Blasting Supplies] | **unknown** (est 420) | **new** |
| 76160 | Stalk With The Earthmother | 11 | 4 | Horde | Boarton Shadetotem 205729 (1456: 39.4, 65.8) | Boarton Shadetotem 205729 (1456: 39.4, 65.8) | pre(any) 76156; next 76240 | 1 Pine Salve [source not in DB] | **unknown** (est 660) | **new** |
| 76240 | Stalk With The Earthmother | 11 | 4 | Horde | Boarton Shadetotem 205729 (1456: 39.4, 65.8) | Boarton Shadetotem 205729 (1456: 39.4, 65.8) | pre(any) 76160 | 1 Fish Chunks [source not in DB] | **unknown** (est 660) | **new** |
| 768 | Gathering Leather | 8 | 4 | Horde | Veren Tallstrider 3050 (1456: 44.4, 44.7) | Veren Tallstrider 3050 (1456: 44.4, 44.7) | PROFESSION 393>=1 | 12 Light Leather [source not in DB] | 875 (wclbox) | same |
| 769 | Kodo Hide Bag | 10 | 4 | Horde | Veren Tallstrider 3050 (1456: 44.4, 44.7) | Veren Tallstrider 3050 (1456: 44.4, 44.7); Boramu 258466 (1456: 44.1, 44.9) | PROFESSION 165>=10 | 4 Light Leather [source not in DB]; 4 Coarse Thread [source not in DB] | 420 (wclbox) | same |
| 9264 | Investigate the Scourge of Thunder Bluff | 10 | 1 | Horde | Lieutenant Lisande 16490 (1456: 31.4, 70.4) | Lieutenant Lisande 16490 (1456: 31.4, 70.4) | special=2 | 3 Dim Necrotic Stone [Skeletal Soldier L6, Spectral Apparition L6, Spectral Spirit L9]; area/script event; trigger 1412: 39.5, 44.1 | 625 (wclbox) | same |

#### Skywatcher Plateau (new hub, NW Mulgore, 33.4, 22.6): not a level 1-12 hub

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 95349 | The Earthen Ring | 13 | 7 | Horde | Ayessa Dawnsinger 251968 (2521: 59.1, 79.8) | Muln Earthfury 259118 (1412: 33.4, 22.6); Alaana Stormwalker 259119 (1412: 33.4, 22.5) | pre(any) 93090 | - | **unknown** (est 680) | **new** |
| 96241 | Talkin' bout Toxins, Mon | 30 | 23 | Horde | Mazu'kon 264074 (1412: 32.5, 20.7) | Mazu'kon 264074 (1412: 32.5, 20.7) | - | 5 Gloomrise Toxin Sample [Gnawed Corpse L28] | **unknown** (est 1850) | **new** |
| 96259 | Defending the Dead | 30 | 23 | Horde | Muln Earthfury 259118 (1412: 33.4, 22.6) | Muln Earthfury 259118 (1412: 33.4, 22.6) | - | kill 10 Gloomrise Hatchling (L27-28); kill 5 Gloomrise Soldier (L28-29) | **unknown** (est 1850) | **new** |
| 96260 | Stronger than Steel | 30 | 23 | Horde | Yorn Grimtotem 264072 (1412: 32.5, 20.0) | Yorn Grimtotem 264072 (1412: 32.5, 20.0) | - | 3 Crystalline Silk [Gloomrise Spinner L28] | **unknown** (est 1850) | **new** |
| 96261 | The Broodmother | 31 | 23 | Horde | Muln Earthfury 259118 (1412: 33.4, 22.6) | Muln Earthfury 259118 (1412: 33.4, 22.6) | - | kill 1 Broodmother Valraxx (L30) | **unknown** (est 1250) | **new** |
| 96294 | A Darker Truth | 30 | 23 | Horde | item Bloody Parchment 273658 from Broodmother Valraxx 264082 | Muln Earthfury 259118 (1412: 33.4, 22.6) | - | - | **unknown** (est 1850) | **new** |
| 99196 | A Donation of Wool | 60 | 12 | Horde | Oura Stormspinner 276171 (1412: 34.2, 22.5) | Oura Stormspinner 276171 (1412: 34.2, 22.5) | - | 60 Wool Cloth [object Alterac Granite, object Tattered Chest, object Battered Chest] | **unknown** (est 6600) | **new** |
| 99197 | A Donation of Silk | 60 | 26 | Horde | Oura Stormspinner 276171 (1412: 34.2, 22.5) | - | - | 60 Silk Cloth [object Alterac Granite, object Battered Chest, object Solid Chest] | **unknown** (est 6600) | **new** |

#### Camp Taurajo / the Crossroads: Tauren-only arrival quests

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 854 | Journey to the Crossroads | 12 | 9 | Tauren | Kirge Sternhorn 3418 (1413: 44.9, 58.6) | Thork 3429 (1413: 51.5, 30.9) | excl 844 | - | 230 (wclbox) | same |
| 6361 | A Bundle of Hides | 10 | 10 | Tauren | Jahan Hawkwing 3483 (1413: 51.2, 29.1) | Devrak 3615 (1413: 51.5, 30.3) | next 6362 | - | 210 (wclbox) | same |
| 6362 | Ride to Thunder Bluff | 10 | 10 | Tauren | Devrak 3615 (1413: 51.5, 30.3) | Ahanu 8359 (1456: 45.8, 55.8) | pre(any) 6361; next 6363 | - | 420 (wclbox) | same |
| 6363 | Tal the Wind Rider Master | 10 | 10 | Tauren | Ahanu 8359 (1456: 45.8, 55.8) | Tal 2995 (1456: 47.0, 49.8) | pre(any) 6362; next 6364 | - | 210 (wclbox) | same |
| 6364 | Return to Jahan | 10 | 10 | Tauren | Tal 2995 (1456: 47.0, 49.8) | Jahan Hawkwing 3483 (1413: 51.2, 29.1) | pre(any) 6363 | - | 1050 (wclbox) | same |

Notes on Mulgore:

* **Camp Narache flow**: 747 + 752 -> (747 turn-in opens 750 and the class note; 752 -> 753 at Greatmother
  Hawkwind's well) -> 755 to Seer Graytongue (42.5, 90.1), who gives 757 and the Forever-new 95805 (turned in at the
  object Ritual Fire 660739 at 56.6, 88.7, south of the Brambleblade Ravine) -> ravine: 757 belts, 780 battleboars,
  3376 Sharptusk, 781 map (object 3076 at 59.8, 82.2) -> 763 to Baine. 96659 The Adventurer (Chief Hawkwind) needs
  757 turned in.
* **745 Sharing the Land** is the only `changed` quest: required level 1 and 550 XP where a level-8 quest normally
  gives 700; counts are 10 / 8 / 5 Palemane.
* **Rite of Vision chain** 767 -> 771 -> 772 (Seer Wiserunner, 34.3, 43.3) -> 773 (Ancestral Spirit, Red Rocks
  58.3, 30.7) -> 775 (Cairne, Thunder Bluff) -> 776 (Arra'chea 3058, level 11, 51.2, 24.8; quest level 14, 1250 XP).
* **Forever-new centaur chain** 99079 (Brave Wildrunner, Bloodhoof) -> 99081 (Malah Longwind 57.6, 63.2) -> 99101
  (Baine) -> 99080 (6 Galak Centaur + 4 Galak Outrunner at 63.8, 62.6, Herak the Pillager at 60.3, 60.5) -> 99082
  (Cairne). All required level 4, quest levels 9-11.
* **Forever-new Venture Co. chain** 98424 (item Mulgore Expansion Plans from Supervisor Fizsprocket, then three
  ground objects in the mine at 58.6-61.7, 46.4-47.3) -> 98427 (Clearcutter Key from Venture Co. Clearclutter
  272173, level 12 **elite**, 56.8, 42.8).
* 98430 The Longwalkers is an escort from Perith Stormhoof (33.1, 66.0; trigger 37.2, 64.6) turned in at Cairne.
* 770 needs a drop from the rare Ghost Howl; 768 / 769 need Skinning / Leatherworking; 97485's Prepared Incense
  has no source in the DB; the 76156 chain: see summary point 7.
* **Skywatcher Plateau** (33.4, 22.6): 95349 is the Skyborne arrival quest (sd-02 -> sd-03), the 962xx quests are
  level 30 and already part of h-27. Nothing for a level 1-12 Tauren.

---------------------------------------------------------------------------------------------------------------

## 2. Service NPCs

All from the DB (`npcs[id].flags`, `sub`, `spawns`). "none" = no such NPC with a spawn on that map in the snapshot.

### 2.1 Class trainers: Orc and Troll

| class | Valley of Trials (1411) | Sen'jin Village (1411) | Razor Hill (1411) | Orgrimmar (1454) |
|---|---|---|---|---|
| HUNTER | Jen'shan 3154 (42.8, 69.3) | none | Thotar 3171 (51.9, 43.5) | Ormak Grimshot 3352 (66.0, 18.5), Xor'juul 3406 (67.2, 20.2), Sian'dur 3407 (68.0, 17.8) |
| MAGE | Mai'ah 5884 (42.5, 69.0) | Un'Thuwa 5880 (56.3, 75.1) | **none** | Pephredo 5882 (38.4, 85.6), Enyo 5883 (38.8, 85.7), Deino 5885 (38.5, 86.1), Uthel'nay 7311 (39.2, 86.3); portals: Thuul 5958 (38.7, 85.4) |
| PRIEST (Troll) | Ken'jai 3707 (42.4, 68.8) | none | Tai'jin 3706 (54.3, 42.9) | X'yera 6014 (36.0, 87.7), Ur'kyo 6018 (35.6, 87.8), Zayus 5994 (35.7, 86.9) |
| ROGUE | Rwag 3155 (41.3, 68.0) | none | Kaplak 3170 (52.0, 43.7) | Gest 3327 (42.7, 51.5), Ormok 3328 (43.9, 54.6), Shenthul 3401 (43.0, 53.7) |
| SHAMAN | Shikrik 3157 (42.4, 69.0) | none | Swart 3173 (54.4, 42.6) | Kardris Dreamseeker 3344 (38.8, 36.4), Sian'tsu 3403 (37.8, 36.5), Sagorne Creststrider 13417 (38.7, 35.9) |
| WARLOCK | Nartok 3156 (40.6, 68.5); demon trainer Hraug 12776 (40.6, 68.4) | none | Dhugru Gorelust 3172 (54.4, 41.2); demon trainer Kitha 6027 (54.7, 41.5) | Grol'dar 3324 (48.0, 45.9), Mirket 3325 (48.6, 47.0), Zevrost 3326 (48.5, 45.4); demon trainer Kurgul 5815 (47.5, 46.7) |
| WARRIOR | Frang 3153 (42.9, 69.4) | none | Tarshaw Jaggedscar 3169 (54.2, 42.5) | Grezz Ragefist 3353 (79.8, 31.4), Sorek 3354 (80.4, 32.4), Zel'mak 3408 (80.4, 29.5) |

Cross-check against the combo list: every class of Orc (HUNTER MAGE ROGUE SHAMAN WARLOCK WARRIOR) and Troll
(+ PRIEST) has a trainer in the Valley of Trials and in Orgrimmar. Razor Hill lacks only the Mage trainer, Sen'jin
has only the Mage trainer. No Druid or Paladin trainer anywhere in Durotar / Orgrimmar (consistent).

### 2.2 Class trainers: Tauren

| class | Camp Narache (1412) | Bloodhoof Village (1412) | Thunder Bluff (1456) |
|---|---|---|---|
| DRUID | Gart Mistrunner 3060 (44.6, 76.5) | Gennia Runetotem 3064 (47.5, 63.0) | Turak Runetotem 3033 (76.5, 27.2), Sheal Runetotem 3034 (77.1, 27.0), Kym Wildmane 3036 (77.2, 29.8): Elder Rise |
| HUNTER | Lanka Farshot 3061 (44.0, 76.3) | Yaw Sharpmane 3065 (46.9, 59.6) | Kary Thunderhorn 3038 (58.5, 88.3), Holt Thunderhorn 3039 (57.3, 89.8), Urek Thunderhorn 3040 (59.1, 86.9): Hunter Rise |
| SHAMAN | Meela Dawnstrider 3062 (44.6, 76.6) | Narm Skychaser 3066 (47.4, 62.5) | Siln Skychaser 3030 (22.8, 21.1), Tigor Skychaser 3031 (23.6, 18.8), Beram Skychaser 3032 (22.0, 18.8): Spirit Rise |
| WARRIOR | Harutt Thunderhorn 3059 (43.8, 76.7) | Krang Stonehoof 3063 (48.4, 63.7) | Torm Ragetotem 3041 (57.2, 87.4), Sark Ragetotem 3042 (57.0, 89.5), Ker Ragetotem 3043 (57.6, 85.5): Hunter Rise |

Cross-check: all four Tauren classes have a trainer in each of the three hubs. Other trainers present in Thunder
Bluff (useful to other races on the shared path): Mage 3047 / 3048 / 3049 and portals 5957, Priest 3044 / 3045 /
3046, **Paladin Alodan the Hopeful 246344** (22.1, 16.9 (+13 points); the Undead paladin route trains here),
and the trainer-flagged "Rogue Trainer?" Boarton Shadetotem 205729 (39.4, 65.8; see summary point 7). Skywatcher
Plateau (1412): Druid Trainer Hana Lighthoof 262560 (33.4, 22.1), Shaman Trainer Palah Thunderhoof 262558
(33.6, 22.4): level 55 NPCs with only the `trainer` flag; whether they train non-Skyborne is not in the data.
The Barrens have no class trainer at all.

### 2.3 Innkeepers, flight masters, transport

| hub | innkeeper | flight master | stable master |
|---|---|---|---|
| Valley of Trials | none | none | none |
| Sen'jin Village | none | none | none |
| Razor Hill | Innkeeper Grosk 6928 (1411: 51.5, 41.6) | **none** | Shoja'my 9987 (52.0, 41.8) |
| Orgrimmar | Innkeeper Gryshka 6929 (1454: 54.1, 68.4) | Doras 3310 (1454: 45.1, 63.9) | Xon'cha 9988 (70.4, 15.0) |
| Camp Narache | none | none | none |
| Bloodhoof Village | Innkeeper Kauth 6747 (1412: 45.9, 64.2) | **none** | Seikwa 10050 (46.0, 63.5) |
| Thunder Bluff | Innkeeper Pala 6746 (1456: 45.8, 64.7) | Tal 2995 (1456: 47.0, 49.8) | Bulrug 10054 (45.1, 60.2) |
| The Crossroads | Innkeeper Boorand Plainswind 3934 (1413: 52.0, 29.9) | Devrak 3615 (1413: 51.5, 30.3) | Sikwa 9981 (51.7, 29.7) |
| Camp Taurajo | Innkeeper Byula 7714 (1413: 45.6, 59.0) | Omusa Thunderhorn 10378 (1413: 44.5, 59.1) | Kelsuwa 9983 (45.3, 58.7) |
| Ratchet | Innkeeper Wiley 6791 (1413: 62.0, 39.4) | Bragok 16227 (1413: 63.1, 37.2) | Reggifuz 10063 (62.2, 39.2) |
| Far Watch Post | none | none | none |

Transport:

* Durotar zeppelin tower (outside Orgrimmar): Frezza 9564 (1411: 50.8, 13.5; Undercity) and Snurk Bucksquick
  12136 (1411: 50.7, 12.9; Grom'gol). ud-03 / ud-04 and sd-03 already use the Undercity line.
* **Thunder Bluff / Mulgore: no zeppelin and no zeppelin master in the DB** (and none in Forever according to the
  web source in section 7). The only transport NPCs in Mulgore are the Skyborne skycutter landing ones on the
  Skywatcher Plateau (Galestrider Handler 264287, 33.7, 24.6).
* Ratchet: Grimble 9558 (1413: 63.5, 38.6), boat to Booty Bay.

### 2.4 Pet trainers, weapon masters, riding

| what | Orc / Troll | Tauren |
|---|---|---|
| Pet trainer | Harruk 3620 (Razor Hill, 1411: 52.0, 43.5), Xao'tsu 10088 (Orgrimmar 66.3, 14.8) | Reban Freerunner 3688 (Bloodhoof, 1412: 46.8, 59.7), Hesuwa Thunderhorn 10086 (Thunder Bluff 54.1, 84.0) |
| Weapon master | Hanashi 2704 (1454: 81.5, 19.6), Sayoc 11868 (1454: 81.7, 19.6) | Ansekhwa 11869 (1456: 40.9, 62.7) |
| Riding trainer | Orc: Kildar 4752 "Wolf Riding Instructor" (1454: 69.4, 13.1). Troll: Xar'Ti 7953 "Raptor Riding Trainer" (Sen'jin, 1411: 55.3, 75.5) | Kar Stormsinger 3690 "Kodo Riding Instructor" (Bloodhoof, 1412: 46.8, 62.0) |
| Mount vendor | Orc: Ogunaro Wolfrunner 3362 "Kennel Master" (1454: 69.4, 12.2). Troll: Zjolnir 7952 "Raptor Handler" (1411: 55.2, 75.7) | Harb Clawhoof 3685 "Kodo Mounts" (1412: 46.6, 62.1) |

Which weapon skills each weapon master teaches is not in the DB (Classic: Hanashi bows / axes / staves / thrown,
Sayoc bows / daggers / fist / axes / thrown, Ansekhwa guns / maces / staves; unverified for Forever). The riding
level and price are not in the DB either; the existing inserts place riding at 40.

Repair in the hubs: Valley of Trials Kzan Thornslash 3159 / Huklah 3160 / Rarc 3161 (40.5, 68); Sen'jin Trayexir
10369 (56.5, 73.1); Razor Hill Uhgar 3163, Ghrawt 3165, Cutac 3166, Wuark 3167 (52-53, 40.5-41); Camp Narache
Marjak Keenblade 3073, Varia Hardhide 3074, Bronk Steelrage 3075 (43.9, 77.8); Bloodhoof Mahnott Roughwound 3077,
Kennah Hawkseye 3078, Varg Windwhisper 3079, Harant Ironbrace 3080 (45.2, 62.1).

---------------------------------------------------------------------------------------------------------------

## 3. Class quests, levels 1-12 (Orc, Troll, Tauren)

Same columns as section 1. Only quests whose race mask admits Orc, Troll or Tauren. PALADIN (-141): no quest for
these races (Undead only). Quests of level 13 are listed where they finish a chain started at 10.

#### WARRIOR (sort -81): Orc, Troll, Tauren

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 2383 | Simple Parchment | 1 | 1 | Orc / WARRIOR | Gornek 3143 (1411: 42.1, 68.3) | Frang 3153 (1411: 42.9, 69.4) | pre(any) 788 | - | 40 (questie) | same |
| 3065 | Simple Tablet | 1 | 1 | Troll / WARRIOR | Gornek 3143 (1411: 42.1, 68.3) | Frang 3153 (1411: 42.9, 69.4) | pre(any) 788 | - | 40 (questie) | same |
| 3091 | Simple Note | 1 | 1 | Tauren / WARRIOR | Grull Hawkwind 2980 (1412: 44.5, 77.5) | Harutt Thunderhorn 3059 (1412: 43.8, 76.7) | pre(any) 747 | - | 40 (questie) | same |
| 1505 | Veteran Uzzek | 10 | 10 | Horde / WARRIOR | Torm Ragetotem 3041 (1456: 57.2, 87.4); Krang Stonehoof 3063 (1412: 48.4, 63.7); Tarshaw Jaggedscar 3169 (1411: 54.2, 42.5); Sorek 3354 (1454: 80.4, 32.4) | Uzzek 5810 (1413: 61.4, 21.1) | next 1498; excl 1819; breadcrumb for 1498 | - | 85 (questie) | same |
| 1498 | Path of Defense | 10 | 10 | Horde / WARRIOR | Uzzek 5810 (1413: 61.4, 21.1) | Uzzek 5810 (1413: 61.4, 21.1) | next 1502; excl 1819 | 5 Singed Scale [Thunder Lizard L9, Lightning Hide L10] | **unknown** (est 420) | same |
| 1502 | Thun'grim Firegaze | 10 | 10 | Horde / WARRIOR | Uzzek 5810 (1413: 61.4, 21.1) | Thun'grim Firegaze 5878 (1413: 57.2, 30.3) | pre(any) 1498,1819; next 1503 | - | 210 (questie) | same |
| 1503 | Forged Steel | 10 | 10 | Horde / WARRIOR | Thun'grim Firegaze 5878 (1413: 57.2, 30.3) | Thun'grim Firegaze 5878 (1413: 57.2, 30.3) | pre(any) 1502 | 1 Forged Steel Bars [object Stolen Iron Chest] | 840 (questie) | same |

#### SHAMAN (sort -82): Orc, Troll, Tauren

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 3089 | Rune-Inscribed Parchment | 1 | 1 | Orc / SHAMAN | Gornek 3143 (1411: 42.1, 68.3) | Shikrik 3157 (1411: 42.4, 69.0) | pre(any) 788 | - | 40 (questie) | same |
| 3084 | Rune-Inscribed Tablet | 1 | 1 | Troll / SHAMAN | Gornek 3143 (1411: 42.1, 68.3) | Shikrik 3157 (1411: 42.4, 69.0) | pre(any) 788 | - | 40 (questie) | same |
| 3093 | Rune-Inscribed Note | 1 | 1 | Tauren / SHAMAN | Grull Hawkwind 2980 (1412: 44.5, 77.5) | Meela Dawnstrider 3062 (1412: 44.6, 76.6) | pre(any) 747 | - | 60 (questie) | same |
| 1516 | Call of Earth | 4 | 4 | Horde / SHAMAN | Canaga Earthcaller 5887 (1411: 42.4, 69.2) | Canaga Earthcaller 5887 (1411: 42.4, 69.2) | pre(any) 1516,1519,92466; next 1517; excl 1519,92466 | 2 Felstalker Hoof [Felstalker L3] | 270 (questie) | same |
| 1517 | Call of Earth | 4 | 4 | Horde / SHAMAN | Canaga Earthcaller 5887 (1411: 42.4, 69.2) | Minor Manifestation of Earth 5891 (1411: 44.0, 76.2 (+2)) | pre(any) 1516,1519; next 1518 | - | 270 (questie) | same |
| 1518 | Call of Earth | 4 | 4 | Horde / SHAMAN | Minor Manifestation of Earth 5891 (1411: 44.0, 76.2 (+2)) | Canaga Earthcaller 5887 (1411: 42.4, 69.2) | pre(any) 1517 | - | 445 (questie) | same |
| 1463 | Earth Sapta | 4 | 4 | Horde / SHAMAN | Canaga Earthcaller 5887 (1411: 42.4, 69.2) | Canaga Earthcaller 5887 (1411: 42.4, 69.2) | pre(any) 1517; special=1 | - | **unknown** (est 355) | same |
| 1519 | Call of Earth | 4 | 4 | Horde / SHAMAN | Seer Ravenfeather 5888 (1412: 44.4, 76.8) | Seer Ravenfeather 5888 (1412: 44.4, 76.8) | pre(any) 1516,1519,92466; next 1520; excl 1516,92466 | 2 Ritual Salve [Bristleback Shaman L3] | 270 (questie) | same |
| 1520 | Call of Earth | 4 | 4 | Horde / SHAMAN | Seer Ravenfeather 5888 (1412: 44.4, 76.8) | Minor Manifestation of Earth 5891 (1411: 44.0, 76.2 (+2)) | pre(any) 1516,1519; next 1521 | - | 180 (questie) | same |
| 1521 | Call of Earth | 4 | 4 | Horde / SHAMAN | Minor Manifestation of Earth 5891 (1411: 44.0, 76.2 (+2)) | Seer Ravenfeather 5888 (1412: 44.4, 76.8) | pre(any) 1520 | - | 445 (questie) | same |
| 1462 | Earth Sapta | 4 | 4 | Horde / SHAMAN | Seer Ravenfeather 5888 (1412: 44.4, 76.8) | Seer Ravenfeather 5888 (1412: 44.4, 76.8) | pre(any) 1520; special=1 | - | **unknown** (est 355) | same |
| 2983 | Call of Fire | 10 | 10 | Horde / SHAMAN | Swart 3173 (1411: 54.4, 42.6) | Kranal Fiss 5907 (1413: 56.0, 19.9) | next 1524; excl 1522,1523,2984; breadcrumb for 1524 | - | 420 (questie) | same |
| 2984 | Call of Fire | 10 | 10 | Horde / SHAMAN | Narm Skychaser 3066 (1412: 47.4, 62.5) | Kranal Fiss 5907 (1413: 56.0, 19.9) | next 1524; excl 1522,1523,2983; breadcrumb for 1524 | - | 420 (questie) | same |
| 1522 | Call of Fire | 10 | 10 | Horde / SHAMAN | Searn Firewarder 5892 (1454: 38.0, 37.7) | Kranal Fiss 5907 (1413: 56.0, 19.9) | next 1524; excl 1523,2983,2984; breadcrumb for 1524 | - | 420 (questie) | same |
| 1523 | Call of Fire | 10 | 10 | Horde / SHAMAN | Xanis Flameweaver 5906 (1456: 25.2, 20.5) | Kranal Fiss 5907 (1413: 56.0, 19.9) | next 1524; excl 1522,2983,2984; breadcrumb for 1524 | - | 420 (questie) | same |
| 1524 | Call of Fire | 11 | 10 | Horde / SHAMAN | Kranal Fiss 5907 (1413: 56.0, 19.9) | Telf Joolam 5900 (1411: 38.5, 59.0) | next 1525 | - | 660 (questie) | same |
| 1525 | Call of Fire | 12 | 10 | Horde / SHAMAN | Telf Joolam 5900 (1411: 38.5, 59.0) | Telf Joolam 5900 (1411: 38.5, 59.0) | pre(any) 1524; next 1526 | 1 Fire Tar [Tunnel Rat Geomancer L12, Razormane Water Seeker L10, Razormane Thornweaver L10]; 1 Reagent Pouch [Stonesplinter Seer L13, Burning Blade Cultist L10] | 910 (questie) | same |
| 1526 | Call of Fire | 13 | 10 | Horde / SHAMAN | Telf Joolam 5900 (1411: 38.5, 59.0) | object Brazier of the Dormant Flame 61934 (1411: 39.0, 58.2 (+1)) | pre(any) 1525; next 1527 | 1 Glowing Ember [Minor Manifestation of Fire L12, Manifestation of Flames L12] | 1150 (questie) | same |
| 1527 | Call of Fire | 13 | 10 | Horde / SHAMAN | object Brazier of the Dormant Flame 61934 (1411: 39.0, 58.2 (+1)) | Kranal Fiss 5907 (1413: 56.0, 19.9) | pre(any) 1526 | - | 1150 (questie) | same |

#### HUNTER (sort -261): Orc, Troll, Tauren

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 3087 | Etched Parchment | 1 | 1 | Orc / HUNTER | Gornek 3143 (1411: 42.1, 68.3) | Jen'shan 3154 (1411: 42.8, 69.3) | pre(any) 788 | - | 40 (questie) | same |
| 3082 | Etched Tablet | 1 | 1 | Troll / HUNTER | Gornek 3143 (1411: 42.1, 68.3) | Jen'shan 3154 (1411: 42.8, 69.3) | pre(any) 788 | - | 40 (questie) | same |
| 3092 | Etched Note | 1 | 1 | Tauren / HUNTER | Grull Hawkwind 2980 (1412: 44.5, 77.5) | Lanka Farshot 3061 (1412: 44.0, 76.3) | pre(any) 747 | - | 60 (questie) | same |
| 6069 | The Hunter's Path | 10 | 10 | Orc+Troll / HUNTER | Kali Remik 11814 (1411: 56.1, 74.2) | Thotar 3171 (1411: 51.9, 43.5) | next 6062; excl 6068,6070; breadcrumb for 6062 | - | 85 (questie) | same |
| 6068 | The Hunter's Path | 10 | 10 | Orc+Troll / HUNTER | Sian'dur 3407 (1454: 68.0, 17.8) | Thotar 3171 (1411: 51.9, 43.5) | next 6062; excl 6069,6070; breadcrumb for 6062 | - | 85 (questie) | same |
| 6070 | The Hunter's Path | 10 | 10 | Orc+Troll / HUNTER | Kary Thunderhorn 3038 (1456: 58.5, 88.3) | Thotar 3171 (1411: 51.9, 43.5) | next 6062; excl 6068,6069; breadcrumb for 6062 | - | 85 (questie) | same |
| 6062 | Taming the Beast | 10 | 10 | Orc+Troll / HUNTER | Thotar 3171 (1411: 51.9, 43.5) | Thotar 3171 (1411: 51.9, 43.5) | next 6083 | use on 1 Dire Mottled Boar (L6-7) | 840 (questie) | same |
| 6083 | Taming the Beast | 10 | 10 | Orc+Troll / HUNTER | Thotar 3171 (1411: 51.9, 43.5) | Thotar 3171 (1411: 51.9, 43.5) | pre(any) 6062; next 6082 | use on 1 Surf Crawler (L7-8) | 840 (questie) | same |
| 6082 | Taming the Beast | 10 | 10 | Orc+Troll / HUNTER | Thotar 3171 (1411: 51.9, 43.5) | Thotar 3171 (1411: 51.9, 43.5) | pre(any) 6083; next 6081 | use on 1 Armored Scorpid (L7-8) | 840 (questie) | same |
| 6081 | Training the Beast | 10 | 10 | Orc+Troll / HUNTER | Thotar 3171 (1411: 51.9, 43.5) | Ormak Grimshot 3352 (1454: 66.0, 18.5) | pre(any) 6082 | - | 420 (questie) | same |
| 6065 | The Hunter's Path | 10 | 10 | Tauren / HUNTER | Kary Thunderhorn 3038 (1456: 58.5, 88.3) | Yaw Sharpmane 3065 (1412: 46.9, 59.6) | next 6061; excl 6066,6067; breadcrumb for 6061 | - | 85 (questie) | same |
| 6066 | The Hunter's Path | 10 | 10 | Tauren / HUNTER | Sian'dur 3407 (1454: 68.0, 17.8) | Yaw Sharpmane 3065 (1412: 46.9, 59.6) | next 6061; excl 6065,6067; breadcrumb for 6061 | - | 85 (questie) | same |
| 6067 | The Hunter's Path | 10 | 10 | Tauren / HUNTER | Thotar 3171 (1411: 51.9, 43.5) | Yaw Sharpmane 3065 (1412: 46.9, 59.6) | next 6061; excl 6065,6066; breadcrumb for 6061 | - | 85 (questie) | same |
| 6061 | Taming the Beast | 10 | 10 | Tauren / HUNTER | Yaw Sharpmane 3065 (1412: 46.9, 59.6) | Yaw Sharpmane 3065 (1412: 46.9, 59.6) | next 6087 | use on 1 Adult Plainstrider (L6-8) | 840 (questie) | same |
| 6087 | Taming the Beast | 10 | 10 | Tauren / HUNTER | Yaw Sharpmane 3065 (1412: 46.9, 59.6) | Yaw Sharpmane 3065 (1412: 46.9, 59.6) | pre(any) 6061; next 6088 | use on 1 Prairie Stalker (L7-8) | 840 (questie) | same |
| 6088 | Taming the Beast | 10 | 10 | Tauren / HUNTER | Yaw Sharpmane 3065 (1412: 46.9, 59.6) | Yaw Sharpmane 3065 (1412: 46.9, 59.6) | pre(any) 6087; next 6089 | use on 1 Swoop (L7-9) | 840 (questie) | same |
| 6089 | Training the Beast | 10 | 10 | Tauren / HUNTER | Yaw Sharpmane 3065 (1412: 46.9, 59.6) | Holt Thunderhorn 3039 (1456: 57.3, 89.8) | pre(any) 6088 | - | 420 (questie) | same |

#### PRIEST (sort -262): Troll

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 3085 | Hallowed Tablet | 1 | 1 | Troll / PRIEST | Gornek 3143 (1411: 42.1, 68.3) | Ken'jai 3707 (1411: 42.4, 68.8) | pre(any) 788 | - | 40 (questie) | same |
| 5649 | In Favor of Spirituality | 4 | 5 | Troll / PRIEST | Ken'jai 3707 (1411: 42.4, 68.8) | Tai'jin 3706 (1411: 54.3, 42.9) | next 5648; breadcrumb for 5648 | - | 90 (questie) | same |
| 5648 | Garments of Spirituality | 4 | 5 | Troll / PRIEST | Tai'jin 3706 (1411: 54.3, 42.9) | Tai'jin 3706 (1411: 54.3, 42.9) | - | use on 1 Grunt Kor'ja (L7) | 270 (questie) | same |
| 5654 | Hex of Weakness | 10 | 10 | Troll / PRIEST | Tai'jin 3706 (1411: 54.3, 42.9) | Ur'kyo 6018 (1454: 35.6, 87.8) | excl 5652,5655,5656,5657 | - | 210 (questie) | same |
| 5652 | Hex of Weakness | 10 | 10 | Troll / PRIEST | Ur'kyo 6018 (1454: 35.6, 87.8) | Ur'kyo 6018 (1454: 35.6, 87.8) | excl 5654,5655,5656,5657 | - | **unknown** (est 420) | same |
| 5655 | Hex of Weakness | 10 | 10 | Troll / PRIEST | Var'jun 11407 (1412: 46.2, 62.3) | Ur'kyo 6018 (1454: 35.6, 87.8) | excl 5652,5654,5656,5657 | - | 210 (questie) | same |
| 5656 | Hex of Weakness | 10 | 10 | Troll / PRIEST | Miles Welsh 3044 (1456: 25.3, 15.3) | Ur'kyo 6018 (1454: 35.6, 87.8) | excl 5652,5654,5655,5657 | - | 210 (questie) | same |
| 5657 | Hex of Weakness | 10 | 10 | Troll / PRIEST | Aelthalyste 4606 (1458: 49.3, 17.1) | Ur'kyo 6018 (1454: 35.6, 87.8) | excl 5652,5654,5655,5656 | - | 210 (questie) | same |

#### DRUID (sort -263): Tauren

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 3094 | Verdant Note | 1 | 1 | Tauren / DRUID | Grull Hawkwind 2980 (1412: 44.5, 77.5) | Gart Mistrunner 3060 (1412: 44.6, 76.5) | pre(any) 747 | - | 60 (wclbox) | same |
| 5928 | Heeding the Call | 10 | 10 | Tauren / DRUID | Gennia Runetotem 3064 (1412: 47.5, 63.0) | Turak Runetotem 3033 (1456: 76.5, 27.2) | next 5922; excl 5926,5927; breadcrumb for 5922 | - | 85 (wclbox) | same |
| 5926 | Heeding the Call | 10 | 10 | Tauren / DRUID | Innkeeper Pala 6746 (1456: 45.8, 64.7) | Turak Runetotem 3033 (1456: 76.5, 27.2) | next 5922; excl 5927,5928; breadcrumb for 5922 | - | 85 (wclbox) | same |
| 5927 | Heeding the Call | 10 | 10 | Tauren / DRUID | Innkeeper Gryshka 6929 (1454: 54.1, 68.4) | Turak Runetotem 3033 (1456: 76.5, 27.2) | next 5922; excl 5926,5928; breadcrumb for 5922 | - | 85 (wclbox) | same |
| 5922 | Moonglade | 10 | 10 | Tauren / DRUID | Turak Runetotem 3033 (1456: 76.5, 27.2) | Dendrite Starblaze 11802 (1450: 56.2, 30.6) | next 5930 | - | 210 (wclbox) | same |
| 5930 | Great Bear Spirit | 10 | 10 | Tauren / DRUID | Dendrite Starblaze 11802 (1450: 56.2, 30.6) | Dendrite Starblaze 11802 (1450: 56.2, 30.6) | pre(any) 5922; next 5932; special=2 | talk to 1 Great Bear Spirit (L60) | 420 (wclbox) | same |
| 5932 | Back to Thunder Bluff | 10 | 10 | Tauren / DRUID | Dendrite Starblaze 11802 (1450: 56.2, 30.6) | Turak Runetotem 3033 (1456: 76.5, 27.2) | pre(any) 5930; next 6002 | - | 85 (wclbox) | same |
| 6002 | Body and Heart | 10 | 10 | Tauren / DRUID | Turak Runetotem 3033 (1456: 76.5, 27.2) | Turak Runetotem 3033 (1456: 76.5, 27.2) | pre(any) 5932; special=2 | talk to 1 Lunaclaw Spirit (L13) | 850 (wclbox) | same |

#### ROGUE (sort -162): Orc, Troll

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 3088 | Encrypted Parchment | 1 | 1 | Orc / ROGUE | Gornek 3143 (1411: 42.1, 68.3) | Rwag 3155 (1411: 41.3, 68.0) | pre(any) 788 | - | 40 (questie) | same |
| 3083 | Encrypted Tablet | 1 | 1 | Troll / ROGUE | Gornek 3143 (1411: 42.1, 68.3) | Rwag 3155 (1411: 41.3, 68.0) | pre(any) 788 | - | 40 (questie) | same |
| 1859 | Therzok | 10 | 10 | Orc / ROGUE | Kaplak 3170 (1411: 52.0, 43.7) | Therzok 6446 (1454: 42.7, 53.5) | next 1963; excl 1885; breadcrumb for 1963 | - | 210 (questie) | same |
| 1963 | The Shattered Hand | 13 | 10 | Orc+Troll / ROGUE | Therzok 6446 (1454: 42.7, 53.5) | Therzok 6446 (1454: 42.7, 53.5) | next 1858 | 1 Tazan's Satchel [Tazan L13] | 680 (questie) | same |
| 1858 | The Shattered Hand | 13 | 10 | Orc+Troll / ROGUE | Therzok 6446 (1454: 42.7, 53.5) | Therzok 6446 (1454: 42.7, 53.5) | pre(any) 1963 | 1 Tazan's Logbook [source not in DB] | 455 (questie) | same |

#### MAGE (sort -161): Orc, Troll

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 98576 | Glyphic Parchment | 1 | 1 | Orc / MAGE | Gornek 3143 (1411: 42.1, 68.3) | Mai'ah 5884 (1411: 42.5, 69.0) | pre(any) 788 | - | **unknown** (est 40) | **new** |
| 3086 | Glyphic Tablet | 1 | 1 | Troll / MAGE | Gornek 3143 (1411: 42.1, 68.3) | Mai'ah 5884 (1411: 42.5, 69.0) | pre(any) 788 | - | 40 (questie) | same |
| 1883 | Speak with Un'thuwa | 10 | 10 | Horde / MAGE | Thurston Xane 3049 (1456: 25.2, 21.0); Uthel'nay 7311 (1454: 39.2, 86.3) | Un'Thuwa 5880 (1411: 56.3, 75.1) | next 1884; excl 1882; breadcrumb for 1884 | - | 85 (questie) | same |
| 1884 | Ju-Ju Heaps | 10 | 10 | Orc+Undead+Troll / MAGE | Un'Thuwa 5880 (1411: 56.3, 75.1) | Un'Thuwa 5880 (1411: 56.3, 75.1) | excl 1882 | use 4 Ju-Ju Heap | 840 (questie) | same |
| 1881 | Speak with Anastasia | 10 | 10 | Undead+Troll / MAGE | Cain Firesong 2128 (1420: 62.0, 52.5) | Anastasia Hartwell 4568 (1458: 85.1, 10.0) | next 1882; excl 1884; breadcrumb for 1882 | - | 85 (questie) | same |
| 1882 | The Balnir Farmstead | 10 | 10 | Undead+Troll / MAGE | Anastasia Hartwell 4568 (1458: 85.1, 10.0) | Anastasia Hartwell 4568 (1458: 85.1, 10.0) | excl 1884 | 1 Balnir Snapdragons [object Balnir Snapdragons] | 840 (questie) | same |

#### WARLOCK (sort -61): Orc, Troll

| id | quest | L | req | races / classes | giver | turn-in | pre / next | objectives | xp (src) | status |
|---|---|---|---|---|---|---|---|---|---|---|
| 3090 | Tainted Parchment | 1 | 1 | Orc / WARLOCK | Gornek 3143 (1411: 42.1, 68.3) | Nartok 3156 (1411: 40.6, 68.5) | pre(any) 788 | - | 40 (questie) | same |
| 98575 | Tainted Tablet | 1 | 1 | Troll / WARLOCK | Gornek 3143 (1411: 42.1, 68.3) | Nartok 3156 (1411: 40.6, 68.5) | pre(any) 788 | - | **unknown** (est 40) | **new** |
| 1485 | Vile Familiars | 4 | 1 | Horde / WARLOCK | Ruzan 5765 (1411: 42.6, 69.0) | Ruzan 5765 (1411: 42.6, 69.0) | next 1499; excl 1470 | 6 Vile Familiar Head [Vile Familiar L3] | 355 (questie) | same |
| 1499 | Vile Familiars | 4 | 1 | Horde / WARLOCK | Ruzan 5765 (1411: 42.6, 69.0) | Zureetha Fargaze 3145 (1411: 42.9, 69.2) | pre(any) 1470,1485; next 794 | - | 35 (questie) | same |
| 1506 | Gan'rul's Summons | 10 | 10 | Horde / WARLOCK | Ophek 3294 (1411: 54.4, 41.3) | Gan'rul Bloodeye 5875 (1454: 48.2, 45.3) | next 1501; breadcrumb for 1501 | - | 210 (questie) | same |
| 1501 | Creature of the Void | 11 | 10 | Orc / WARLOCK | Gan'rul Bloodeye 5875 (1454: 48.2, 45.3) | Gan'rul Bloodeye 5875 (1454: 48.2, 45.3) | next 1504 | 1 Tablet of Verga [object Burning Blade Stash] | 880 (questie) | same |
| 1504 | The Binding | 11 | 10 | Orc / WARLOCK | Gan'rul Bloodeye 5875 (1454: 48.2, 45.3) | Gan'rul Bloodeye 5875 (1454: 48.2, 45.3) | pre(any) 1501 | kill 1 Summoned Voidwalker (L10) | 660 (questie) | same |

What the class agents must know:

* **Level-1 letters**: one quest id per race x class, all given by the first NPC after the first kill quest
  (Gornek after 788 for Orc/Troll, Grull Hawkwind after 747 for Tauren) and turned in at the class trainer of the
  start camp. Orc: WARRIOR 2383, HUNTER 3087, ROGUE 3088, SHAMAN 3089, WARLOCK 3090, MAGE 98576 (new, XP unknown).
  Troll: WARRIOR 3065, HUNTER 3082, ROGUE 3083, SHAMAN 3084, PRIEST 3085, MAGE 3086, WARLOCK 98575 (new, XP
  unknown). Tauren: WARRIOR 3091, HUNTER 3092, SHAMAN 3093, DRUID 3094. A class insert needs a race filter per id.
* **WARRIOR 10**: 1505 (breadcrumb from Tarshaw in Razor Hill, Krang in Bloodhoof, Sorek in Orgrimmar or Torm in
  Thunder Bluff) -> 1498 Path of Defense at Uzzek, **Far Watch Post** (1413: 61.4, 21.1): 5 Singed Scales from
  Thunder Lizard 3130 / Lightning Hide 3131 in Thunder Ridge, Durotar (39-44, 24-31) -> 1502 -> 1503 at Thun'grim
  Firegaze (1413: 57.2, 30.3). Natural for Orc/Troll (Thunder Ridge is on the Durotar north loop and shares mobs
  with 97282); a detour of two zones for a Tauren. 1498 has no XP in the DB.
* **SHAMAN**: Call of Earth at 4 in the start camp: Orc/Troll 1516 (2 Felstalker Hoof) -> 1517 -> 1518 at Canaga
  Earthcaller (1411: 42.4, 69.2; the Minor Manifestation of Earth 5891 is at 1411: 44.0, 76.2); Tauren 1519
  (2 Ritual Salve from Bristleback Shaman, same mobs as 757) -> 1520 -> 1521 at Seer Ravenfeather (1412: 44.4, 76.8;
  manifestation at 1412: 52.0, 80.4). 1516 and 1519 are mutually exclusive. Call of Fire at 10: breadcrumb 2983
  (Swart, Razor Hill) / 2984 (Narm, Bloodhoof) / 1522 (Orgrimmar) / 1523 (Thunder Bluff) -> Kranal Fiss (1413: 56.0,
  19.9, north-east Barrens) -> 1524 -> Telf Joolam (1411: 38.5, 59.0, the peak west of the Valley of Trials) ->
  1525 (Fire Tar from the Razormane of 871 / 872 in the Barrens, Reagent Pouch from Burning Blade Cultists at
  Drygulch 52.4, 25.5) -> 1526 -> 1527 (level 13, 1150 XP each). All in Durotar and the Barrens: on the path for
  Orc/Troll, a Durotar detour for a Tauren (the Skyborne route has its own 97243-97257 / 98517).
* **HUNTER 10**: Orc/Troll: breadcrumb 6069 (Kali Remik, Sen'jin) or 6068 / 6070 -> 6062 -> 6083 -> 6082 at Thotar,
  Razor Hill (tame Dire Mottled Boar 3099, Surf Crawler 3107, Armored Scorpid 3126) -> 6081 to Ormak Grimshot,
  Orgrimmar. Tauren: breadcrumb 6065 / 6066 / 6067 -> 6061 -> 6087 -> 6088 at Yaw Sharpmane, Bloodhoof (Adult
  Plainstrider 2956, Prairie Stalker 2959, Swoop 2970) -> 6089 to Holt Thunderhorn, Thunder Bluff. 840 XP per
  taming step: 3.0k XP for the chain with its breadcrumb.
* **PRIEST (Troll)**: 5649 (Ken'jai, Valley of Trials, required level 5) -> 5648 at Tai'jin, Razor Hill (heal
  Grunt Kor'ja 12430 at 53.1, 46.5); 5654 Hex of Weakness at 10 (Tai'jin -> Ur'kyo, Orgrimmar).
* **DRUID (Tauren)**: 5928 (Gennia, Bloodhoof) or 5926 / 5927 -> 5922 at Turak Runetotem (Thunder Bluff) ->
  Moonglade 5930 -> 5932 -> 6002 Body and Heart (Lunaclaw Spirit at 1413: 42.0, 60.8, next to Camp Taurajo: on the
  Tauren way out of Mulgore). The Skyborne druid uses different ids (94911 / 94913): race filter needed.
* **ROGUE**: 1859 Therzok is Orc only; 1963 -> 1858 (level 13, required 10) are Orc+Troll at Therzok (1454: 42.7,
  53.5). 1858's item has no source in the DB.
* **MAGE 10**: 1883 (breadcrumb from Orgrimmar / Thunder Bluff) -> 1884 Ju-Ju Heaps at Un'Thuwa, Sen'jin (4 heaps
  on the Echo Isles, 67-69, 82-88: same trip as 826 / 808). 1884's mask is Orc+Undead+Troll: the new Orc mage is
  covered. 1881 / 1882 (Tirisfal) are the Undead+Troll alternative and exclusive with 1884.
* **WARLOCK**: 1485 Vile Familiars (6 heads) -> 1499 -> 794 replaces 792 in the Valley of Trials. At 10: 1506
  (Ophek, Razor Hill 54.4, 41.3) -> Gan'rul Bloodeye (1454: 48.2, 45.3) -> 1501 (Tablet of Verga from the Burning
  Blade Stash, Skull Rock) -> 1504. **1501 and 1504 are Orc only in the DB: the Troll warlock gap of the summary.**

---------------------------------------------------------------------------------------------------------------

## 4. Early Barrens (uiMap 1413), quest levels 10-16, and what the existing routes do

All non-class quests of quest level 10-16 that a Horde character can take and whose zone, giver or turn-in is in
the Barrens. `A` = the segment accepts it, `T` = turns it in; `-` in all three columns = **skipped by every
existing route**.

| id | quest | L | req | races | giver (hub) | xp | status | Undead route | Skyborne route | 22-60 path |
|---|---|---|---|---|---|---|---|---|---|---|
| 860 | Sergra Darkthorn | 10 | 10 | Horde | Melor Stonehoof (Thunder Bluff 61.5, 80.9) | 85 | same | - | - | - |
| 886 | The Barrens Oases | 10 | 10 | Horde | Arch Druid Hamuul Runetotem (Thunder Bluff 78.6, 28.6) | 85 | same | - | - | - |
| 6361 | A Bundle of Hides | 10 | 10 | Tauren | Jahan Hawkwing (Crossroads) | 210 | same | - | - | - |
| 6362 | Ride to Thunder Bluff | 10 | 10 | Tauren | Devrak (Crossroads) | 420 | same | - | - | - |
| 6363 | Tal the Wind Rider Master | 10 | 10 | Tauren | Ahanu (Thunder Bluff 45.8, 55.8) | 210 | same | - | - | - |
| 6364 | Return to Jahan | 10 | 10 | Tauren | Tal (Thunder Bluff 47.0, 49.8) | 1050 | same | - | - | - |
| 6365 | Meats to Orgrimmar | 10 | 10 | Orc+Troll | Zargh (Crossroads) | 210 | same | - | - | - |
| 6384 | Ride to Orgrimmar | 10 | 10 | Orc+Troll | Devrak (Crossroads) | 420 | same | - | - | - |
| 6385 | Doras the Wind Rider Master | 10 | 10 | Orc+Troll | Innkeeper Gryshka (Orgrimmar 54.1, 68.4) | 210 | same | - | - | - |
| 6386 | Return to the Crossroads. | 10 | 10 | Orc+Troll | Doras (Orgrimmar 45.1, 63.9) | 1050 | same | - | - | - |
| 1492 | Wharfmaster Dizzywig | 11 | 9 | Horde | Apothecary Helbrim (Crossroads) | 440 | same | ud-04 AT | sd-04 AT | - |
| 840 | Conscript of the Horde | 12 | 10 | Horde | Takrin Pathseeker (Durotar 50.8, 43.6) | 460 | same | ud-04 AT | sd-04 AT | - |
| 842 | Crossroads Conscription | 12 | 10 | Horde | Kargal Battlescar (Far Watch Post) | 900 | same | ud-04 AT | sd-04 AT | - |
| 844 | Plainstrider Menace | 12 | 10 | Horde | Sergra Darkthorn (Crossroads) | 900 | same | ud-04 AT | sd-04 AT | - |
| 854 | Journey to the Crossroads | 12 | 9 | Tauren | Kirge Sternhorn (Camp Taurajo) | 230 | same | - | - | - |
| 871 | Disrupt the Attacks | 12 | 9 | Horde | Thork (Crossroads) | 900 | same | ud-04 AT | sd-04 AT | - |
| 809 | Ak'Zeloth | 13 | 4 | Horde | Neeru Fireblade (Orgrimmar 49.5, 50.6) | 460 | same | - | - | - |
| 845 | The Zhevra | 13 | 10 | Horde | Sergra Darkthorn (Crossroads) | 900 | same | ud-04 AT | sd-04 AT | - |
| 869 | Raptor Thieves | 13 | 9 | Horde | Gazrog (Crossroads) | 900 | same | ud-04 AT | sd-04 AT | - |
| 870 | The Forgotten Pools | 13 | 10 | Horde | Tonga Runetotem (Crossroads) | 675 | same | ud-04 AT | sd-04 AT | - |
| 98024 | Journey to the Crossroads | 13 | 7 | SkyH | Thrall (Orgrimmar 31.7, 37.8) | unknown | new | - | sd-03 A, sd-04 T | - |
| 855 | Centaur Bracers | 14 | 9 | Horde | Regthar Deathgate (field 45.3, 28.4) | 1250 | same | ud-04 A, ud-05 T | sd-04 AT | - |
| 887 | Southsea Freebooters | 14 | 9 | ALL | Gazlowe (Ratchet) | 750 | same | ud-04 AT | sd-04 AT | - |
| 890 | The Missing Shipment | 14 | 9 | ALL | Gazlowe (Ratchet) | 100 | same | ud-04 AT | sd-04 AT | - |
| 892 | The Missing Shipment | 14 | 9 | ALL | Wharfmaster Dizzywig (Ratchet) | 100 | same | ud-04 AT | sd-04 AT | - |
| 894 | Samophlange | 14 | 10 | ALL | Sputtervalve (Ratchet) | 750 | same | ud-04 AT | sd-04 AT | - |
| 900 | Samophlange | 14 | 10 | ALL | Control Console (field 52.4, 11.7) | 490 | same | ud-04 AT | sd-04 AT | - |
| 901 | Samophlange | 14 | 10 | ALL | Control Console (field 52.4, 11.7) | 750 | same | ud-04 AT | sd-04 AT | - |
| 924 | The Demon Seed | 14 | 9 | Horde | Ak'Zeloth (Far Watch Post) | 1250 | same | - | - | - |
| 926 | Flawed Power Stone | 14 | 1 | Horde | Flawed Power Stone (Far Watch Post) | unknown | same | - | - | - |
| 3921 | Wenikee Boltbucket | 14 | 10 | Horde | Sputtervalve (Ratchet) | 490 | same | - | - | - |
| 5041 | Supplies for the Crossroads | 14 | 9 | Horde | Thork (Crossroads) | 975 | same | ud-04 AT | sd-04 AT | - |
| 819 | Chen's Empty Keg | 15 | 11 | Horde | item drop | 1050 | same | ud-04 AT | sd-04 AT | - |
| 821 | Chen's Empty Keg | 15 | 11 | Horde | Brewmaster Drohn (Ratchet) | 1350 | same | ud-04 A, ud-05 T | sd-04 A, sd-05 T | - |
| 848 | Fungal Spores | 15 | 10 | Horde | Apothecary Helbrim (Crossroads) | 1050 | same | ud-04 AT | sd-04 AT | - |
| 853 | Apothecary Zamah | 15 | 10 | Horde | Apothecary Helbrim (Crossroads) | 800 | same | ud-04 A, ud-05 T | sd-05 AT | - |
| 867 | Harpy Raiders | 15 | 12 | Horde | Darsok Swiftdagger (Crossroads) | 1050 | same | ud-04 AT | sd-04 AT | - |
| 872 | The Disruption Ends | 15 | 9 | Horde | Thork (Crossroads) | 1050 | same | ud-04 AT | sd-04 AT | - |
| 903 | Prowlers of the Barrens | 15 | 10 | Horde | Sergra Darkthorn (Crossroads) | 1050 | same | ud-04 AT | sd-04 AT | - |
| 1358 | Sample for Helbrim | 15 | 10 | Horde | Apothecary Zinge (Undercity 50.1, 68.0) | 1050 | same | ud-03 A, ud-04 T | sd-03 A, sd-04 T | - |
| 3301 | Mura Runetotem | 15 | 10 | Horde | Tonga Runetotem (Crossroads) | 1050 | same | - | - | - |
| 3922 | Nugget Slugs | 15 | 10 | Horde | Wenikee Boltbucket (field 49.0, 11.2) | 1050 | same | - | - | - |
| 97253 | Parts and Pieces | 15 | 9 | Horde | Wrenix the Wretched (Ratchet) | unknown | new | ud-04 AT | sd-04 AT | - |
| 850 | Kolkar Leaders | 16 | 11 | Horde | Regthar Deathgate (field 45.3, 28.4) | 875 | same | ud-04 AT | sd-04 AT | - |
| 866 | Root Samples | 16 | 9 | ALL | Mebok Mizzyrix (Ratchet) | 1150 | same | - | - | - |
| 875 | Harpy Lieutenants | 16 | 12 | Horde | Darsok Swiftdagger (Crossroads) | 1150 | same | - | sd-04 A, sd-05 T | - |
| 877 | The Stagnant Oasis | 16 | 10 | Horde | Tonga Runetotem (Crossroads) | 1150 | same | ud-04 AT | sd-04 AT | - |
| 880 | Altered Beings | 16 | 10 | Horde | Tonga Runetotem (Crossroads) | 1150 | same | ud-04 A, ud-05 T | sd-04 A, sd-05 T | - |
| 881 | Echeyakee | 16 | 10 | Horde | Sergra Darkthorn (Crossroads) | 1450 | same | ud-04 AT | sd-04 AT | - |
| 888 | Stolen Booty | 16 | 9 | ALL | Gazlowe (Ratchet) | 1150 | same | ud-04 A, ud-05 T | sd-04 A, sd-05 T | - |
| 895 | WANTED: Baron Longshore | 16 | 11 | ALL | WANTED (Ratchet) | 1150 | same | ud-04 AT | sd-04 AT | - |
| 902 | Samophlange | 16 | 10 | ALL | Control Console (field 52.4, 11.7) | 1150 | same | ud-04 AT | sd-04 AT | - |
| 1489 | Hamuul Runetotem | 16 | 12 | Horde | Tonga Runetotem (Crossroads) | 290 | same | ud-05 AT | sd-05 AT | - |

Reading the table:

* **Done by both existing routes** (the common core of a unified Barrens segment): 840 -> 842, 844 -> 845 -> 903 ->
  881, 871 -> 872, 5041, 869, 870 -> 877 -> 880, 848 -> 853, 867, 1492, 850, 855, 887 -> 890 -> 892 -> 888, 895,
  894 -> 900 -> 901 -> 902, 819 -> 821, 97253 (Forever-new, Ratchet), 1489.
* **Differences between ud-04/05 and sd-04/05** in this range: 875 Harpy Lieutenants (Skyborne only), 98024
  (Skyborne-only breadcrumb from Thrall, turned in at the Crossroads), 1358 Sample for Helbrim (taken in the
  Undercity by both: ud-03 and sd-03; **an Orc, Troll or Tauren that has not been to the Undercity does not have
  it**: its turn-in step must be optional or tied to the Silverpine bridge).
* **Skipped by every existing route and open to the new races**:
  * **Race-locked flight-path chains** (never usable by Undead / Skyborne, so nobody looked at them):
    Orc+Troll 6365 Meats to Orgrimmar (Zargh, Crossroads 52.6, 29.8) -> 6384 (Devrak -> Innkeeper Gryshka,
    Orgrimmar) -> 6385 (-> Doras) -> 6386 (-> Zargh): 210 + 420 + 210 + 1050 = **1890 XP** for one round flight
    Crossroads - Orgrimmar - Crossroads. Tauren 6361 A Bundle of Hides (Jahan Hawkwing, Crossroads 51.2, 29.1) ->
    6362 (Devrak -> Ahanu, Thunder Bluff 45.8, 55.8) -> 6363 (-> Tal) -> 6364 (-> Jahan): the same **1890 XP** for
    Crossroads - Thunder Bluff - Crossroads. Both need the capital's flight point already known to fly back
    (Orc/Troll have Orgrimmar, Tauren have Thunder Bluff).
  * Tauren-only 854 Journey to the Crossroads (Kirge Sternhorn, Camp Taurajo 44.9, 58.6 -> Thork; 230 XP; no
    longer offered once 844 is done).
  * Breadcrumbs from Thunder Bluff: 860 Sergra Darkthorn (after 861 The Hunter's Way; leads into 844) and 886
    The Barrens Oases (Hamuul Runetotem -> Tonga; leads into 870), 85 XP each: free for a Tauren who passes
    Thunder Bluff, both must be turned in before 844 / 870 are accepted.
  * Durotar tail at Far Watch Post: 809 Ak'Zeloth (needs 829) -> 924 The Demon Seed (1250 XP, altar on Dreadmist
    Peak).
  * 3921 Wenikee Boltbucket -> 3922 Nugget Slugs (490 + 1050 XP, north Barrens; then 3923 -> 3924 at 18-19).
  * 3301 Mura Runetotem (1050 XP, a delivery to Silverpine after 880: free if a Silverpine trip follows).
  * 866 Root Samples (Herbalism).
* Hubs at this level: **the Crossroads** (Sergra, Thork, Tonga, Gazrog, Darsok, Helbrim, Zargh, Jahan, Devrak),
  **Far Watch Post** (Kargal 842, Uzzek warrior 1498, Ak'Zeloth 809 / 924), **Ratchet** (Gazlowe 887 / 890 / 888 /
  895, Sputtervalve 894, Wrenix 97253, Dizzywig 1492, Mebok 865 / 866, Drohn 819 / 821), **field camps** (Regthar
  Deathgate 45.3, 28.4: 850 / 855; Samophlange console 52.4, 11.7), **Camp Taurajo** (only 854 below level 17;
  flight point, inn; Lunaclaw for the Tauren druid at 42.0, 60.8). The Stagnant Oasis has no NPC: it is the
  objective area of 877 (Bubbling Fissure 3737) and 880.
* Quest levels and required levels of the Barrens quests are unchanged from Classic (`status = same` for all but
  97253 and 98024).

---------------------------------------------------------------------------------------------------------------

## 5. Draft hub orders and the hand-over to the Barrens

Levels are simulated with the validator's model (see the header). "est" = share of estimated quest XP.
Travel distances are straight lines from the DB map sizes (run speed 7 yd/s: 420 yd per minute).

### 5.1 Durotar 1-12 (Orc and Troll, class-agnostic)

| # | hub / leg | quests (turn-ins unless noted) | level in -> out |
|---|---|---|---|
| 1 | **Valley of Trials** | 4641; 788 + 97279; class letter; 789, 4402, 790 -> 804; 792 (warlock: 1485 -> 1499), 5441 -> 6394; 794; accept 805 and 96652 | 1.00 -> 5.36 |
| 2 | **Sen'jin Village #1** (720 yd from the Den) | accept 2161 at Ukor on the way; turn in 805; accept 808, 826, 823, 818, 817, 786, 96821, 97225, 97223; mage trainer | 5.36 -> 5.44 |
| 3 | road north -> **Razor Hill #1** (1130 yd) | 96821 kills on the road (Ridgeshade spiders 50-55, 47-67); turn in 2161, 823 (-> 806), 96821; camp: 96652 -> 96604 (campfire) -> 96655 (Cook Torka); accept 784, 791, 96825, 96822, 815 and 837 (need level 6); bind hearthstone | 5.44 -> 6.49 |
| 4 | west field, **Tiragarde Keep** (610 yd) -> **Razor Hill #2** | 96825 pears + 837 Quilboar / Scouts (43-51, 47-51); 784, 791, 96822 (three ground objects), 830 (chest); turn in 96825, 784 (-> 825), 791, 96822, 830 (-> 831) | 6.49 -> 7.83 |
| 5 | east coast south -> Kolkar Crag -> **Sen'jin #2** | 825 toolboxes (61-65, 42-61), 818 crawlers / makrura along the coast; 786 three attack plans + 99123 escort (46-51, 77-81); turn in 786, 99123 | 7.83 -> 8.28 |
| 6 | **Echo Isles** -> **Sen'jin #3** | 808, 826 (8 + 8 trolls, Zalazane), 817, 815 eggs, 97225 idols, 97223 matriarch (68.8, 71.8), rest of 818 (mage: 1884); turn in 808, 826, 817, 818, 97225, 97223 | 8.28 -> 9.42 |
| 7 | hearth **Razor Hill #3** + Heglan Shadeeye (340 yd) | turn in 815, 825; 99048 (needs level 9) -> 99049 (three objects at 59-60, 42-45) -> accept 99051; level 10 training and the level-10 class quests start here | 9.42 -> 9.88 |
| 8 | **north loop** | 99051 naga (54-61, 18-35); Rezlak (46.4, 22.9): 834 sacks -> 835 harpies + orb 97281 -> 97282 thunder lizards; Thunder Ridge: 806 Fizzle (level 12), 837 Dustrunners / Battleguards on the way (38-45, 36-55); 816 crocolisks (Misha 43.1, 30.2); venomtail sacs for 812 / 813 | 9.88 -> 10.96 |
| 9 | **Orgrimmar #1** (Rhinag 3190 stands outside the city at 41.5, 18.6) | 812 (Kor'ghan, Cleft of Shadow), 831 (Nazgrel); accept 5726 (Thrall, needs level 9); flight point Doras; trainers, weapon master | 10.96 -> 11.20 |
| 10 | **Razor Hill #4** (1050 yd from the zeppelin tower) | turn in 837, 806 (-> 828), 99051 (-> 99052); accept 840 (needs level 10) | 11.20 -> 11.44 |
| 11 | **Far Watch Post** (860 yd to the border, bridge) | turn in 840, accept 842 (warrior: Uzzek 1498; shaman: Kranal Fiss is 640 yd west) | 11.44 -> 11.50 |
| 12 | **the Crossroads** (1290 yd) | turn in 842 | 11.50 -> 11.60 |

Totals of the base draft: 47 quests (14 with estimated XP), quest XP 26 965 (8 535 estimated), objective kill XP
13 509 (~196 kills), no grind steps.

Optional blocks (each measured on top of the previous one):

| block | content | cost | level at the Crossroads |
|---|---|---|---|
| base | table above | - | 11.60 |
| + elites | 96876 Ukor's Lost Pack (Ukorsbane, level 8 elite), 99052 (Aggor the Young, level 11 elite, 900 yd north of Razor Hill and back) | two elite fights, one extra round trip | 11.80 |
| + Skull Rock | 828 Margoz -> 827 (6 Searing Collars) + 5726 insignia + 832 (Gazz'uz, level 14) -> Orgrimmar #2: 829, 5726 -> 5727, 832 -> Far Watch: 809 | a second north trip and a second Orgrimmar visit | 12.28 |
| + Orgrimmar city quests | 97246 -> 97249, 97242 -> 97275, 97326 (five Forever-new deliveries, all XP estimated at 1050) | ~10 min of city running; conflicts with sd-03 (summary point 11) | 12.80 |
| + flight chain | 6365 -> 6384 -> 6385 -> 6386 (Crossroads - Orgrimmar - Crossroads, combine with a training visit) | two flights | 12.99 |

Not in any block: 924 The Demon Seed (+1250, after 809), profession quests 96873 / 96874 / 96875, 96877 (elite
drop), 787, 5843, 9263. Class quests add on top (hunter +3.0k, warlock +1.75k for an Orc, shaman Call of Earth
+1.0k and Call of Fire +2.0k up to 1525 (+2.3k more for 1526 / 1527 at 13), warrior +1.1k plus the unknown XP of
1498, mage +0.9k, priest +0.6k, rogue +0.2k).

Dependency traps for the path agent:

* 815 and 837 need level 6: the draft reaches Razor Hill at ~6.0 only after the Legging It kills and turn-ins;
  put the two accepts after the camp turn-ins (or add a `level = 6` gate: about 6 kills short in the worst case).
* 835 needs 834 turned in, 97282 needs the 97281 orb (a drop from the harpies of 835): Rezlak is visited three
  times within 300-400 yd.
* 828 Margoz needs 806 turned in at Razor Hill, 99052 needs 99051 turned in at Razor Hill: both tails point back
  north (Margoz 56.4, 20.0; Aggor 59.2, 17.6). That is why they sit in optional blocks.
* 812 is the timed quest of Classic (Rhinag -> Kor'ghan -> Rhinag); collect the 4 sacs before talking to Kor'ghan.
* 99048 needs level 9 and 99052 level 10: the Echo Isles must be finished before the hearth of step 7.
* The hearthstone is used once (Sen'jin #3 -> Razor Hill #3); the next use is free for the shared path.

### 5.2 Mulgore 1-12 (Tauren, class-agnostic)

| # | hub / leg | quests (turn-ins unless noted) | level in -> out |
|---|---|---|---|
| 1 | **Camp Narache / Red Cloud Mesa** | 747, 752 -> 753, class note, 750, 755 (Seer Graytongue) -> 757 + 95805 (Ritual Fire 56.6, 88.7), 780, 3376, 781; accept 763, 96659, 1656 | 1.00 -> 6.02 |
| 2 | **Bloodhoof Village #1** (580 yd) | 1656, 763 -> 767 (-> 771); camp south of the village: 96659 -> 96605 (campfire) -> 96661 (Pyall); 99108 (duel a Novice Warrior on the spot); accept everything; bind hearthstone | 6.02 -> 6.77 |
| 3 | south-west loop -> **Bloodhoof #2** | 745 Palemane (33-54, 63-75), 748 paws + talons, 761 swoops, 96130 Chakuyak (39.5, 66.2), 771 well stones + ambercorn, 99411 Kyle; (98430 escort starts here at 33.1, 66.0: turned in in Thunder Bluff) | 6.77 -> 8.12 |
| 4 | east of the village -> **Bloodhoof #3** | 754 Winterhoof well (51.8, 68.4); 99079 -> Malah Longwind (57.6, 63.2) -> 99081 -> 99101; 743 harpies (east ridge) | 8.12 -> 8.94 |
| 5 | north plains + east -> **Bloodhoof #4** | 756 claws, 766 Mazzranache parts, 749 -> 751 caravan crate (51.9, 53.4; Morin Cloudstalker patrols the east road), 99080 Galak camp (63.8, 62.6) | 8.94 -> 9.78 |
| 6 | west loop + Venture Co. -> **Bloodhoof #5** | 746 dig site (33.1, 54.8), 772 Seer Wiserunner (34.3, 43.3), 758 Thunderhorn well (44.2, 51.1); 764, 765, 98424, 98427 (elite) in and around the mine (56-62, 42-50) | 9.78 -> 10.64 |
| 7 | **north Mulgore** | 759 alpha teeth, 833 Red Rocks (Lorekeeper Raintotem 57.0, 34.5), 773 Ancestral Spirit (58.3, 30.7), 861 prowler claws (needs level 10), 760 Wildmane well (42.7, 25.0) | 10.64 -> 11.29 |
| 8 | **Thunder Bluff** | 775, 98430, 99082 (Cairne) -> 776 (Arra'chea at 51.2, 24.8 on the plain north-east of the bluff: down, kill, back up); 98435 (Hamuul, accept 886); 861 (Melor, accept 860); flight point Tal; trainers, weapon master | 11.29 -> 11.80 |
| 9 | **Camp Taurajo -> the Crossroads** (1380 yd to the zone exit, 2080 yd Taurajo - Crossroads) | flight point Camp Taurajo; 854 (Kirge -> Thork), 860, 886 | 11.80 -> 11.85 |

Totals: 53 quests (16 estimated), quest XP 28 230 (9 160 estimated), kill XP 14 438 (~235 kills), no grind steps.
Options: 744 Preparation for Ceremony (Thunder Bluff quest, harpies in the north-west, 875 XP) and the Tauren
flight chain 6361-6364 (+1890) bring the Crossroads level to **12.27**. Without the elite key quest 98427 the base
is about 0.1 lower. Without 776 (a round trip Thunder Bluff - plain - Thunder Bluff, see below) about 0.15 lower. Class quests
on top: hunter +3.0k, druid +1.65k (Moonglade chain), shaman Call of Earth +0.9k (Call of Fire is a Durotar
trip), warrior only the 1505 breadcrumb unless he walks to Far Watch Post.

Dependency traps:

* 760 (and 98435) are at the end of the six-step Thunderhorn chain: each step returns to Mull Thunderhorn in
  Bloodhoof, which is what fixes the number of village visits at five.
* 99080 needs 99079 -> 99081 -> 99101 (three talk steps: Bloodhoof - Malah - Bloodhoof).
* 98424 starts from a drop of Supervisor Fizsprocket (the 765 target, level 12): do 765 first, then the notes,
  then return to Morin for 98427. Morin Cloudstalker patrols; his DB spawn is 54.8, 64.3.
* 861 needs level 10. 776 is given by Cairne only after 775 and its target is back down on the plain: it costs
  a Thunder Bluff round trip for 1250 XP (quest level 14, Arra'chea is level 11): make it `optional`.
* 854 / 860 / 886 must be turned in before 844 / 870 are accepted at the Crossroads.
* Thunder Bluff holds five turn-ins of the draft (775, 98430, 99082, 98435, 861: about 3.0k XP, 1.8k of it
  estimated) plus the flight point the shared path needs: the Mulgore path has to include one visit.

### 5.3 State at the hand-over

| | Orc / Troll | Tauren | Undead (today) | Skyborne (today) |
|---|---|---|---|---|
| arrival point | Razor Hill -> Far Watch Post -> Crossroads (840 -> 842 in the log) | Camp Taurajo -> Crossroads from the south (854, 860, 886) | Durotar zeppelin tower -> Orgrimmar flight point -> Razor Hill (840) | Orgrimmar gate -> Razor Hill (840) |
| level | 11.5-11.8 (12.3 with Skull Rock; 13.0 with every option) | 11.9 (12.3 with options) | 14.56 | 15.59 |
| flight points | Orgrimmar | Thunder Bluff, Camp Taurajo | Undercity, The Sepulcher; Orgrimmar is the first step of ud-04 | Thunder Bluff, Orgrimmar, Undercity, The Sepulcher (all in sd-03) |
| hearthstone | Razor Hill (cooldown running only if used after step 7) | Bloodhoof Village (unused since binding) | Brill, rebound at the Crossroads | Orgrimmar, on cooldown |
| quests carried | 842; 5726 if taken; class quests | 860, 886, 854; druid 6002 at Camp Taurajo | 1358 | 1358, 98024, 1061 |

What each side lacks for today's Barrens / 22-60 steps: Orc/Troll: nothing at the start (Thunder Bluff's flight
point is learned by the walk in ud-05, the same for them); the 1358 turn-in. Tauren: **the Orgrimmar flight
point** (first needed when the shared path flies to Orgrimmar; the walk Crossroads -> Far Watch -> Razor Hill ->
Orgrimmar is about 3100 yd, 7-8 minutes), 840 / 842 (1360 XP, not reachable without that walk), 1358.

### 5.4 Closing the level gap: options with numbers

Gap to the Undead entry level 14.56: from 11.60 it is 32.2k XP, from 11.85 30.0k, from 12.28 25.9k, from 12.99
18.7k. Segment totals from `docs/VALIDATION.md` (quest + objective kill XP): ud-03 Silverpine 20.8k, sd-03 29.3k
(of which about 5.3k are the five Orgrimmar city quests at their estimates), ud-04 53.5k, ud-05 79.8k (+11.1k
grind), sd-04 59.4k, sd-05 75.8k.

| option | what | result (validator arithmetic) | cost / risk |
|---|---|---|---|
| A. Barrens at 12, nothing else | Orc/Troll/Tauren run the unified Barrens segments from 11.6-12.3 | end of the ud-04 equivalent 16.1-16.5 (Undead 17.99), end of the ud-05 equivalent 20.3-20.6 (Undead 21.62 before its 74-kill grind gate, 22.06 after) | 1.2-1.7 levels short at h-22; level-12 characters at quests planned for 15+ (867 needs 12, 850 Barak is 16, harpies 14-17); the shortfall must be ground or filled later: at level 21 it is ~30k XP = ~200 same-level kills |
| B. Shared Silverpine loop 12-15 | after the start zone: Orgrimmar -> zeppelin -> Brill -> Undercity -> Silverpine -> Undercity -> hearth Orgrimmar (the Orgrimmar-to-Orgrimmar part of sd-03) | 11.60 -> 14.33, 11.85 -> 14.50, 12.28 -> 14.82 with the full +29.3k; 13.9-14.4 if the Orgrimmar city quests were already used in Durotar | natural for Orc/Troll (the Durotar draft ends its north loop next to the zeppelin tower: the loop can start there instead of walking to the Barrens first); gives 1358 Sample for Helbrim and the Undercity flight point like the two existing routes; Tauren must first walk Crossroads -> Orgrimmar (learns Orgrimmar's flight point, can take 840 / 842 on the way back) |
| C. Every local option | Durotar + elites + Skull Rock + city quests + flight chain | 12.99 (Orc/Troll); Tauren 12.27 | still 18.7k (Orc/Troll) / 26k (Tauren) short of 14.56; the city quests collide with sd-03 |
| D. Tauren into Durotar's tail | Tauren walk to Orgrimmar and do the Durotar north loop quests (level 9-12, all Horde-wide: 834 / 835 / 97281 / 97282 / 816 / 812 / 806 / 837 / 99048-99051, Skull Rock) | about +8.3k quest XP (+3.5k with Skull Rock) plus kill XP, all still full XP at 12 | long walk; makes the Tauren path depend on the Durotar segment's step ids |
| E. Symmetric: Orc/Troll into Mulgore's tail | not sensible: no flight point, 2000+ yd beyond Camp Taurajo | - | - |

Observations for the architect:

* Option B is the only one that brings all three Kalimdor races to the existing entry level without grinding, and
  it turns "Silverpine 12/13-15" into a second shared segment (Undead on foot from Tirisfal, everyone else by
  zeppelin). ud-03 (20.8k) and the Silverpine part of sd-03 are two different orders of the same zone and would
  have to be unified like ud-04 / sd-04.
* For Orc/Troll the Durotar draft can end at step 9 (Orgrimmar, 11.2) and go straight to the zeppelin; steps 10-12
  (837 / 806 / 99051 turn-ins, 840) can be done when the route comes back to Orgrimmar and walks to Razor Hill
  exactly as ud-04 / sd-04 begin today. That removes one Razor Hill round trip from Durotar. 837 / 806 / 99051
  are quest level 10-12: still full XP at 15.
* For Tauren the decision is between a 7-8 minute walk to Orgrimmar (then option B) and option A with a later
  fill. Whatever is chosen, the Tauren must touch Orgrimmar's flight master before the 22-60 path.
* The flight-path chains (1890 XP each, section 4) fit the first flight the shared path makes to the race's own
  capital; they are race-filtered steps on a shared segment.

---------------------------------------------------------------------------------------------------------------

## 6. Proposed anchors and file ownership (draft for the architect)

`docs/dev/research/core.md` (5.9) asks for explicit step ids on every anchor, published per zone before the class
phase. Proposal: two segments per start zone with their own id prefixes, and the following anchor steps. Each is
a real step of the path (a turn-in or an arrival), so class inserts can use `after = "<id>"`.

Durotar (path agent "Durotar"; segments `dur-01-valley-of-trials` 1-6 and `dur-02-durotar` 6-12; step id prefixes
`dur01-` / `dur02-`):

| anchor id | step | level | what class files hang on it |
|---|---|---|---|
| `dur01-teeth` | turn in 788 at Gornek | 2.5 | level-1 letter (race x class id) + first training |
| `dur01-familiars` | accept 792 at Zureetha (base step with `classes` = all but WARLOCK) | 4 | warlock 1485 -> 1499 before it; shaman 1516 (needs 4) |
| `dur01-den-4` | turn in 792 / 5441 in the Den | 4.7 | training at 4; shaman 1517 -> 1518 |
| `dur01-leave` | turn in 794, accept 805 + 96652 | 5.4 | last Valley of Trials trainer visit; priest 5649 (needs 5: only if 5 is reached, else at Razor Hill via 5648) |
| `dur02-senjin-1` | turn in 805 at Master Gadrin | 5.4 | mage training (the only mage trainer outside the valley and Orgrimmar) |
| `dur02-rh-1` | first Razor Hill turn-ins | 6.0-6.5 | training at 6; priest 5648 |
| `dur02-rh-2` | Razor Hill after Tiragarde | 7.8 | training (8 is reached on the coast: next chance is `dur02-rh-3`) |
| `dur02-senjin-3` | Sen'jin after the Echo Isles | 9.4 | mage training at 8; hunter breadcrumb 6069 needs 10 (not yet) |
| `dur02-rh-3` | Razor Hill after the hearth | 9.9-10 | training at 10; 2983 shaman, 6062 hunter chain, 1505 warrior, 5654 priest, 1859 rogue, 1506 warlock |
| `dur02-thunder-ridge` | Thunder Ridge kills (97282 / 806) | 10.5 | warrior Singed Scales for 1498 (same lizards) |
| `dur02-org-1` | Orgrimmar arrival (812 turn-in) | 11 | training, weapon master, 6081 hunter, 5654 priest, 1859 -> 1963 rogue, 1506 -> 1501 warlock, 1883 mage breadcrumb |
| `dur02-farwatch` | turn in 840 at Kargal | 11.5 | warrior 1505 -> 1498 at Uzzek; shaman 2983 -> 1524 at Kranal Fiss |

Mulgore (path agent "Mulgore"; segments `mul-01-camp-narache` 1-6 and `mul-02-mulgore` 6-12; prefixes `mul01-` /
`mul02-`):

| anchor id | step | level | what class files hang on it |
|---|---|---|---|
| `mul01-hunt` | turn in 747 at Grull Hawkwind | 2.9 | level-1 note + first training |
| `mul01-ravine` | accept 757 / before the Brambleblade Ravine | 4 | training at 4; shaman 1519 (Ritual Salve drops from the 757 mobs) |
| `mul01-leave` | turn in 757 / 780 / 3376 at Camp Narache | 6.0 | training at 6 (6 is reached here); shaman 1520 -> 1521 |
| `mul02-bh-1` | first Bloodhoof turn-ins | 6.8 | training |
| `mul02-bh-2` | Bloodhoof after the south-west loop | 8.1 | training at 8 |
| `mul02-bh-5` | Bloodhoof after the west loop / Venture Co. | 10.6 | training at 10; hunter 6061 -> 6087 -> 6088 at Yaw; shaman 2984; warrior 1505; druid 5928 |
| `mul02-tb` | Thunder Bluff arrival (775 turn-in) | 11.3 | training, weapon master, druid 5922 (Moonglade), hunter 6089 |
| `mul02-taurajo` | Camp Taurajo flight point | 11.8 | druid 6002 Lunaclaw (42.0, 60.8) |
| `mul02-end` | turn in 854 at Thork | 11.9 | - |

File ownership consequences:

* Each class file needs one group of inserts per start zone (Durotar, Mulgore, Tirisfal, Zephras) because the
  anchors, trainers and several quest ids differ per zone; within Durotar, Orc and Troll differ only by the
  level-1 letter id and by the race-locked quests named in section 3 (race filter on the insert step).
* The path agents own the base steps including the warlock exception on 792 (a `classes` filter on a base step).
* The five Orgrimmar city quests, the flight-path chains and 1358 are shared-path material: assign them to the
  agent that owns the unified Barrens / Silverpine segments, not to the Durotar agent.
* Per-agent validation that does not depend on others: a path agent can validate with any one profile of the
  race (e.g. Orc WARRIOR and Troll PRIEST for Durotar, Tauren WARRIOR for Mulgore); the class letters and class
  quests are inserts, so the base path must reach its planned levels without them (the numbers in 5.1 / 5.2 are
  class-free).

---------------------------------------------------------------------------------------------------------------

## 7. Web cross-check (November 2026)

Used only to confirm facts; nothing was copied.

| fact | source | agrees with the DB? |
|---|---|---|
| Tauren classes in Forever: Druid, Hunter, Shaman, Warrior ("unchanged from Classic"); Mulgore is the Tauren start and lasts to about level 10; then the Barrens | https://www.warcrafttavern.com/forever/guides/tauren/ | yes (letters 3091-3094, trainers) |
| "Thunder Bluff has no zeppelin to Orgrimmar in WoW Forever": the two capitals are connected on foot | https://www.warcrafttavern.com/forever/guides/tauren/ | yes (no transport NPC in Thunder Bluff / Mulgore) |
| Orc Mage and Troll Warlock are new launch combos; Orc: Hunter, Mage, Rogue, Shaman, Warlock, Warrior; Troll: Warrior, Hunter, Mage, Rogue, Priest, Warlock, Shaman | search summary of https://www.icy-veins.com/wow-forever/news/all-new-race-and-class-combos-and-racial-abilities-in-wow-forever-official/ (page itself returned 403), https://www.method.gg/wow-forever/all-class-and-race-combinations-in-world-of-warcraft-forever | yes (Forever-new letters 98576 Orc mage, 98575 Troll warlock) |
| 96821 Legging It: Forever-only, Vel'rin Fang -> Gar'Thok, level 6, required level 1, 6 Ridgeshade Creepers + 6 Ridgeshade Lurkers, **410 XP** | https://warcraft.wiki.gg/wiki/Legging_It | yes for everything the DB has; the XP is new information (estimate 550) |
| 97279 Wayward Weapons: Forever-only, level 2, from Gornek | https://warcraft.wiki.gg/wiki/Durotar_quests | yes |
| Arrive in the Barrens at 10-12; Orc/Troll over the bridge at Far Watch Post, Tauren on foot from Mulgore; Crossroads is the hub; Camp Taurajo matters from about 18; no level scaling; no Barrens quest level changes | https://games.gg/world-of-warcraft/guides/wow-forever-barrens-leveling-guide/ | yes (Barrens quests all `same`) |
| "Mulgore Expansion Plans" is a Forever-new quest item | https://metaforge.app/wow-forever/database/quest-items/mulgore-expansion-plans-281039 | yes in substance (starts 98424; the DB has item id 281031) |
| A RestedXP Forever speedrun guide exists, with a separate Horde route for 1-12 | https://kami-labs.fr/en/wow-forever/restedxp-wow-forever-guide-leveling/ (affiliate blog; the page gives no route order) | no route facts available: nothing to compare |
| Generic guides: Durotar 1-10 -> Barrens 10-25; Mulgore 1-10 -> Barrens 10-25 | https://www.warcrafttavern.com/forever/guides/leveling/, https://rankedboost.com/world-of-warcraft/forever/leveling/ | consistent with a hand-over at 11.5-12 |

Not found on the web: any list of the Forever-new Durotar / Mulgore quests beyond the two above, any XP values
for them, any statement on a Troll voidwalker quest, any RestedXP hub order. No web source contradicts the DB.

---------------------------------------------------------------------------------------------------------------

## Appendix A. How the numbers were produced

Scratch scripts (lua5.1, run from the repository root, not part of the repository) loaded the snapshot through
`tools/lib/fbdb.lua` (`DB.Load`, `DB.HasBit`, `DB.QuestXp`, `DB.MobXp`, `DB.EstimateQuestXp`, `DB.AddXp`):

* quest selection: `quests[id]` whose `uiMap`, giver spawn or turn-in spawn is on 1411 / 1454 / 1412 / 1456 /
  1413, race test `floor(mask / bit) % 2` with Orc 2, Troll 128, Tauren 32 (mask 0 = everyone);
* new-quest counts: `status ~= "same"` with `zone == 14` (Durotar: 18) and `zone == 215` (Mulgore: 23);
* combo check: single-class quests with a race-specific mask, in `quests` and in `questIndex`;
* route usage: `accept` / `turnin` ids parsed as text from `addons/FastesBoooy_*/Segments/*.lua`;
* level projection: an ordered list of "complete objectives" and "turn in" events per draft; kill XP per
  objective = count x `DB.MobXp` (creature objectives) or `ceil(count x 1.5)` x `DB.MobXp` of the first killable
  drop source (item objectives), mob level = floor of the mean of min / max level, quest XP = `DB.QuestXp(base or
  estimate, questLevel, playerLevel)`; 96821 uses the web value 410.

Model limits: no travel time, no rested XP, no incidental kills, drop rates unknown (1.5 kills per item), the
14-16 estimated quest XP values per zone, and the object / talk quests give no kill XP although their areas
are full of mobs. The validator will reproduce these numbers once the segments exist; expect differences of
a few tenths of a level from step order.
