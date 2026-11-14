# Route research for the "FastesBoooy_Guides" redesign: the existing routes

Scope: `addons/FastesBoooy_UndeadPaladin` (`Route.lua`, `Segments/*.lua`, `Inserts.lua`),
`addons/FastesBoooy_SkyborneDruid` (same), `addons/FastesBoooy_Horde/Segments/*.lua`, `docs/routes/*.md`,
`tools/README.md`, the DB snapshot `tools/data/forever_db.lua`. Read-only research: nothing in the repository was
changed except this file. Line numbers refer to branch `claude/beautiful-planck-svbl19` at the time of writing.
The companion report on the core is `docs/dev/research/core.md`.

Abbreviations used for file references:

| Short | File |
|---|---|
| `UD/01` .. `UD/05` | `addons/FastesBoooy_UndeadPaladin/Segments/01_Deathknell.lua`, `02_Tirisfal.lua`, `03_Silverpine.lua`, `04_Barrens.lua`, `05_Barrens_Stonetalon_Ashenvale.lua` |
| `UD/Ins` | `addons/FastesBoooy_UndeadPaladin/Inserts.lua` |
| `SD/01` .. `SD/05` | `addons/FastesBoooy_SkyborneDruid/Segments/01_Zephras_1_9.lua`, `02_Zephras_9_12.lua`, `03_Mulgore_Silverpine.lua`, `04_Barrens.lua`, `05_Barrens_Stonetalon_Ashenvale.lua` |
| `SD/Ins` | `addons/FastesBoooy_SkyborneDruid/Inserts.lua` |
| `H/01` .. `H/12` | `addons/FastesBoooy_Horde/Segments/01_h-22-hillsbrad.lua` .. `12_h-56-felwood-winterspring-plaguelands.lua` |

A step is written `ud-04#36` (segment, position in the segment) plus its explicit id when it has one. "anon" = no
explicit `id` (the engine gives it `<segment>:<n>`).

How the numbers were produced (all reproducible, 0.5 s per run):

* `lua5.1 tools/validate_routes.lua addons/FastesBoooy_UndeadPaladin` / `..._SkyborneDruid`: segment table, gates.
* `lua5.1 tools/validate_routes.lua -q --route <id> --profile race=..,class=..,faction=Horde --write-state f.json
  --until <step or segment id> <module dir>`: character state before a step.
* `--profile race=Scourge,class=WARRIOR` (and `race=Orc`, `race=Tauren`) on the existing routes: the `quest-class` /
  `quest-race` / `train-wrong-trainer` errors are an exact list of class and race steps.
* "What if" variants (no class quests, no Silverpine, an Undead on the druid's Barrens segments): a scratch copy
  of the three modules with one extra file listed in the TOC right after `Route.lua` that wraps
  `FastesBoooy.AddSegment` and drops or edits steps before they are registered, then the normal validator with
  `--addons <scratch>/addons <scratch>/addons/<module>`. The sandbox allows this; no repository file is touched.
  The same trick works for any later "what if" question.

---------------------------------------------------------------------------------------------------------------

## 0. Summary and what contradicts the decisions

1. **The two Barrens pairs are the same quest set in a different order.** `ud-04/05` and `sd-04/05` share 75 of
   90 quests (section 4). Only 216 and 6462 (Thistlefur) are Undead-only; 875, 6301, 1061, and the optional
   883 / 884 / 6641 are Skyborne-only; the rest of the difference is the druid Cat Form chain and the racial
   breadcrumb 98024. None of the non-shared quests is used again by `h-22` .. `h-56` except 6301 (three
   race-filtered steps in `h-24`). The union can therefore be one shared pair of segments.
2. **In the Barrens segments the only class steps are training visits** (3 paladin, 4 druid) **and the Cat Form
   block** (9 steps). All class quests of the paladin are in Tirisfal; the druid's bear and Moonglade quests are
   on Zephras and in `sd-03` (Thunder Bluff at its start, Moonglade at its end).
3. **Contradiction with "one shared path from the Barrens on": Silverpine is shared content too.** `ud-03` and
   the second half of `sd-03` (46 steps) do the same Sepulcher loop (23 common quests). Removing Silverpine costs
   **+117 grind kills** by 22 for the Undead paladin (74 -> 191, worst case 107 -> 232) and **+77** for the
   Skyborne druid (0 -> 77, worst 40 -> 163), section 8. A "Barrens from 12" path loses on the validator's
   numbers. The efficient merge point is the Silverpine entry (level ~13), not the Barrens (~15), for Undead,
   Skyborne and (by geography: Orgrimmar is next to the zeppelin) Orc and Troll. Tauren need a measured decision.
4. **"Tirisfal = ud-01..03" is not accurate:** `ud-03` is Silverpine + Undercity + zeppelin. Tirisfal is
   `ud-01` + `ud-02`. Likewise Zephras is `sd-01` + `sd-02`; `sd-03` is Thunder Bluff, Orgrimmar (24 steps), then
   Tirisfal / Silverpine / Undercity (46 steps), then Moonglade (3 steps).
5. **Class steps are not pure inserts.** Eight generic steps mix class and non-class actions in one step
   (`accept = { 98601, 3901, 376 }`), three segment-end ids are class steps (`ud02-end`, `ud05-end`,
   `sd05-train-22`), four level gates are tuned to class quest XP or class training, and the druid replaces
   generic travel (Teleport: Moonglade + hearth). The start-zone segments must be rewritten step by step, not
   just filtered (section 3).
6. **Class quests are race-specific.** All 12 paladin class quests of 1-22 and the 7 of the optional 22 chain are
   `races = UNDEAD`. The druid chain is Skyborne-only in three places (bear chain 94006 / 94638; 94911 / 94913;
   the middle of the Cat Form chain 98341 / 98404 / 98738), so a Tauren druid needs other quests there. "One file per class valid for every race of that class" holds
   for training visits from 22 on; below 22 a class file is mostly per-race blocks.
7. **Riding at 40 sits in the class files today but is purely race-specific** (5 riding trainers, one per race,
   section 7). For Tauren and Skyborne the riding trip and the druid's level-40 training share one detour
   (fly to Thunder Bluff), so the race file and the druid file need a common anchor contract.
8. **Existing defect that the unification removes:** the library makes Skyborne fly to the Crossroads and run to
   Orgrimmar at 22 (`h-22-tb-fly-xroads` + 2 `go` steps, `H/01:81-90`), but the Skyborne route has known the
   Orgrimmar flight point since 13 (`sd03-fp-org`, `SD/03:97`). The druid insert note tells the player to
   ignore the library steps (`SD/Ins`, `sd-bridge-fly-tb`).
9. **Open game fact:** `sd03-fly-org` (`SD/03:92`) flies Thunder Bluff -> Orgrimmar at 13 without a known
   Orgrimmar flight point (validator WARN `fly-unknown-fp`, accepted in `docs/routes/horde-skyborne-druid.md:588`).
   Every race that reaches Thunder Bluff before Orgrimmar (Skyborne, Tauren) depends on it.
10. **Combos confirmed by the DB** (class "scroll" quests of level 1-2 per start zone, section 6.5): Orc HUNTER
    MAGE ROGUE SHAMAN WARLOCK WARRIOR; Troll HUNTER MAGE PRIEST ROGUE SHAMAN WARLOCK WARRIOR; Tauren DRUID HUNTER
    SHAMAN WARRIOR; Undead MAGE PALADIN PRIEST ROGUE WARLOCK WARRIOR; Skyborne DRUID HUNTER ROGUE SHAMAN WARRIOR.
    Total 28. (Zephras has two mage
    trainers flagged `AH`, but no mage scroll quest: not a Horde Skyborne class.)
11. **The 22-60 library validates unchanged for every tested profile** (Orc WARRIOR, Orc SHAMAN, Troll MAGE,
    Troll PRIEST, Tauren HUNTER, Scourge WARLOCK) from the Undead level-22 state: 0 errors, level 60, 4934 grind
    kills (worst 6068). No quest of `h-22` .. `h-56` is race- or class-restricted.
12. **Explicit ids:** 77 of 394 Undead steps and 71 of 423 Skyborne steps of 1-22 have ids; 54 of the 136 hub
    visits have no id at all (section 9). Every anchor a class agent needs must get an id before the class phase.

---------------------------------------------------------------------------------------------------------------

## 1. Inventory (validator numbers)

### 1.1 Segments

`steps` = steps of the segment; `id` / `anon` = with / without an explicit id; travel = `go` + `fly` + `hearth`
steps; quest XP includes the validator's estimates for Forever-new quests.

| Segment | Plan | Simulated | Steps | id | anon | Travel (go/fly/hearth) | train | Quest XP | Kill XP | Grind kills (worst) |
|---|---|---|---|---|---|---|---|---|---|---|
| `ud-01-deathknell` | 1-6 | 1.00 -> 5.88 | 31 | 13 | 18 | 0/0/0 | 2 | 3 715 | 3 502 | 1 (1) |
| `ud-02-tirisfal` | 6-13 | 5.88 -> 12.78 | 121 | 22 | 99 | 3/0/2 | 4 | 28 275 | 16 367 | 0 |
| `ud-03-silverpine` | 13-15 | 12.78 -> 14.56 | 55 | 7 | 48 | 7/0/1 | 1 | 16 145 | 4 691 | 0 |
| `ud-04-barrens` | 15-18 | 14.56 -> 17.99 | 96 | 15 | 81 | 1/3/1 | 0 | 39 145 | 14 376 | 0 |
| `ud-05-stonetalon-ashenvale` | 18-22 | 17.99 -> 22.06 | 91 | 20 | 71 | 10/6/2 | 3 | 47 810 | 31 956 | 74 (107) |
| `sd-01-zephras` | 1-9 | 1.00 -> 9.95 | 91 | 14 | 77 | 5/0/1 | 4 | 16 865 | 10 397 | 0 |
| `sd-02-zephras` | 9-13 | 9.95 -> 13.32 | 71 | 13 | 58 | 10/0/1 | 3 | 21 255 | 9 196 | 0 |
| `sd-03-mulgore-silverpine` | 13-15 | 13.32 -> 15.59 | 73 | 15 | 58 | 9/2/1 | 2 | 22 965 | 6 288 | 0 |
| `sd-04-barrens` | 15-18 | 15.59 -> 19.02 | 101 | 11 | 90 | 5/2/1 | 1 | 44 015 | 15 416 | 0 |
| `sd-05-stonetalon-ashenvale` | 18-22 | 19.02 -> 22.24 | 87 | 18 | 69 | 11/4/2 | 3 | 51 470 | 24 335 | 0 (40) |

Totals of the own parts: Undead 394 steps (77 with id, 317 anon), Skyborne 423 steps (71 with id, 352 anon).
Composed routes: `horde-undead-paladin` 1717 steps (23 inserted), `horde-skyborne-druid` 1752 (29 inserted).
Whole routes: Undead 4972 grind kills (worst 6179), Skyborne 4878 (worst 6082), both end at 60.00, 0 errors.

All Zephras quest XP is estimated (86 quests of level 1-13 on Zephras Isle have no XP in the DB), so the
Skyborne levels up to 13 are less certain than the Undead ones (19 of 61 Tirisfal quests are estimated).

### 1.2 Library (`FastesBoooy_Horde`)

| Segment | Steps | id | anon | optional | filtered |
|---|---|---|---|---|---|
| `h-22-hillsbrad` | 61 | 17 | 44 | 15 | 5 |
| `h-24-barrens-stonetalon` | 95 | 20 | 75 | 21 | 3 |
| `h-27-ashenvale-needles` | 128 | 24 | 104 | 17 | 0 |
| `h-31-hillsbrad-arathi` | 72 | 17 | 55 | 4 | 0 |
| `h-34-stranglethorn` | 60 | 21 | 39 | 0 | 0 |
| `h-37-desolace-dustwallow` | 118 | 47 | 71 | 12 | 0 |
| `h-41-arathi-badlands` | 79 | 31 | 48 | 13 | 0 |
| `h-44-swamp-stranglethorn` | 95 | 36 | 59 | 0 | 0 |
| `h-46-tanaris-feralas` | 113 | 24 | 89 | 17 | 0 |
| `h-50-hinterlands-searing-steppes` | 144 | 42 | 102 | 10 | 0 |
| `h-53-azshara-ungoro-silithus` | 128 | 37 | 91 | 3 | 0 |
| `h-56-felwood-winterspring-plaguelands` | 207 | 48 | 159 | 16 | 0 |
| total | 1300 | 364 | 936 | 128 | 8 |

No `train` step, no `reward` field and no class filter in the library. The 13 `reward` fields of the repository
are all in `SD/01` (9) and `SD/02` (4).

---------------------------------------------------------------------------------------------------------------

## 2. Where the two races go (overview)

```
Undead    ud-01 Deathknell 1-6 | ud-02 Tirisfal, Bandarion Keep, Undercity 6-13 |
          ud-03 Silverpine (on foot from Undercity), hearth Brill, Undercity, zeppelin 13-15 |
          ud-04 Orgrimmar flight point, Razor Hill, Barrens 15-18 (ends at the Crossroads with the timed 853) |
          ud-05 Thunder Bluff (18), Barrens south, Stonetalon x2, Thunder Bluff (20), Ashenvale, Thunder Bluff (22)
Skyborne  sd-01 Zephras 1-9 | sd-02 Zephras 9-13, skycutter to Skywatcher Plateau (Mulgore) |
          sd-03 deathskip to Thunder Bluff, fly Orgrimmar (bind, 5 city quests, Thrall), zeppelin, Brill,
                Silverpine, fly Undercity, Teleport: Moonglade, hearth Orgrimmar 13-15 |
          sd-04 Razor Hill, Barrens 15-18 (ends at the Stonetalon border) |
          sd-05 Stonetalon x1, Barrens south, Thunder Bluff (20, Cat Form), Sun Rock by flight, Ashenvale 18-22
```

---------------------------------------------------------------------------------------------------------------

## 3. Class-specific steps in ud-01..05 and sd-01..05

Classification: **(a)** class step, to extract into `Classes/<Class>.lua`; **(b)** generic step whose note,
reward or gate is class-flavoured and needs rewording (or a generic step that must be split because it mixes a
class action with generic ones); **(c)** XP dependency: later steps rely on XP of the class quest.

The (a) lists below are exactly the steps the validator rejects for `--profile race=Scourge,class=WARRIOR` and
`--profile race=Skyborne,class=WARRIOR` (plus bg / travel steps that only serve those quests).

### 3.1 `ud-01-deathknell` (`UD/01`)

| Step | Line | What | Class |
|---|---|---|---|
| #4 `ud01-364` | 37 | `turnin 364, accept { 98601, 3901, 376 }`: 98601 "A Difficult Path" is PALADIN + UNDEAD (given by Sarvis / Elreth, pre 364) | (b) split: 98601 -> (a) |
| #5 `ud01-98601` | 43 | turnin 98601, accept 90902 at Aramis Hammerhand (paladin trainer 244808), `use = 282423` | (a) |
| #6 `ud01-train-1` | 49 | train (Devotion Aura) | (a) |
| #7 | 57 | `complete 90902` bg (Holy Light on Injured Deathguards) | (a) |
| #11 `ud01-xp-4` | 75 | gate `level = { 3, 0.64 }`; note "needed for Judgement and the next paladin quests"; comment 73-74: the 64 % is computed from 3901 + 376 + 90902 | (b) + (c) |
| #12 `ud01-vendor` | 80 | vendor; note "level 4 training costs about 2 silver" | (b) mild |
| #13 | 85 | note "Rewards: Roamer's Leggings (mail) and Old Leather Belt" | (b) |
| #14 `ud01-90902` | 88 | turnin 90902 ("this gives level 4") | (a) + (c) |
| #15 `ud01-91209` | 92 | `accept { 91208, 91209, 98389 }` at Aramis: 91208 / 91209 PALADIN; 98389 "A Light in the Darkness" has no class or race limit in the DB but starts and ends at the paladin trainer | (b) split; see risk below |
| #16 `ud01-train-4` | 96 | train (Judgement, Blessing of Might); note about Forever Judgement | (a) |
| #19 `ud01-91208` | 115 | complete 91208 (Frightened Paladin) | (a) |
| #22 | 128 | `turnin { 91208, 98389 }` at Aramis | (b) split |
| #23 | 130 | note "Rustmetal Bracers and Rugged Mail Vest (mail)" | (b) |
| #24 | 137 | note "Cannibalize ... restores health and mana" (racial; "mana" does not fit warrior / rogue) | (b) mild |
| #28 `ud01-381` | 151 | note "Forsaken Bastard Sword (two-hander) if your skills allow it, otherwise Forsaken Maul" | (b) |
| #30 `ud01-382` | 159 | note "Reward: Deathguard Buckler" | (b) |

Risk: **98389** is `classes = 0`, `races = all Horde` in the DB, `start = finish = Aramis Hammerhand <Paladin
Trainer>`, pre 376. If other classes cannot take it from him in game, it is a paladin step. The other Deathknell
classes have the classic scroll quests (3095 warrior, 3096 rogue, 3097 priest, 3098 mage, 3099 warlock; all
`races = UNDEAD`, level 1), which play the role of 98601: the anchor for them is `ud01-364`.

### 3.2 `ud-02-tirisfal` (`UD/02`)

| Step | Line | What | Class |
|---|---|---|---|
| #13 `ud02-91209` | 79 | complete + turnin 91209 at Shari Stilwell (paladin trainer 246152, Brill) | (a) |
| #14 `ud02-train-6` | 82 | train 6 (Holy Strike) | (a) |
| #15 `ud02-mallet` | 89 | optional vendor: Wooden Mallet (two-handed mace) | (b) class gear: move or reword to "sell junk" |
| #16 `ud02-sethearth` | 94 | note "Keep Linen Cloth: you need 10 in the Undercity" (for the paladin quest 94434) | (b) |
| #34 | 166 | turnin 99144 at Shari Stilwell: generic quest (no class limit) whose ender is the paladin trainer | generic; note the NPC |
| #35 `ud02-train-8` | 167 | train 8 (Hammer of Justice) | (a) |
| #46 | 200 | Maggot Eye note "keep Hammer of Justice for emergencies" | (b) |
| #57, #59, #64, #71, #83 | 233, 236, 247, 283, 321 | reward notes "(mail)", "+1 Str" | (b) |
| #68 `ud02-91282` | 264 | accept 91282 "A Second Home" (PALADIN) at Shari | (a) |
| #69 `ud02-train-10` | 268 | `train = true, level = 10` in one step; the level gate is also needed by the generic 96895 (reqLevel 10, comment line 267); note has talents | (b) split: generic `level = 10` gate stays, train -> (a) |
| #87, #88 | 331, 333 | `go` west to Bandarion Keep | generic (the keep is also the turn-in place of 96899 / 96896 / 99152 / 99153) |
| #89 `ud02-91285` | 335 | turnin 91282, accept 91285 (Breton Samuels) | (a) |
| #93 | 343 | complete 91285 (16 murlocs: kill XP) | (a) + (c) |
| #94 `ud02-smasher` | 346 | turnin 91285, accept 91294; note: Driftwood Smasher "your main weapon until the Stonewood Hammer" | (a) |
| #95 `ud02-91294` | 351 | `complete { [91294] = { 1 } }` + `accept 99152` at Hilda the Breaker (paladin trainer NPC, generic quest 99152) | (b) split |
| #96, #97 | 354, 357 | complete 91294 objectives 3, 2 | (a) |
| #98 `ud02-91317` | 359 | complete 91294 [4], turnin 91294, accept 91317 (Danitha Morr) | (a) |
| #99 `ud02-91316` | 362 | accept 91316 (Jorin Croge) | (a) |
| #101 | 370 | bg complete 91317 (14 Tarnished: kill XP) | (a) + (c) |
| #103 | 376 | bg `complete { 91316, 95314 }` | (b) split |
| #104 | 380 | `collect 270435` Rudolph Gelhardt's head (item of the paladin chain 91317 / 95803) | (a) |
| #106 | 386 | `complete { 91317, 99152, 91316, 95314 }` | (b) split |
| #109 | 391 | turnin 91316; note "tower shield - only useful for shield play" | (a) |
| #110 `ud02-95803` | 394 | turnin 91317, accept 95803 | (a) |
| #111 `ud02-xp-12` | 401 | optional gate `level = 12` for 94427 | (a) |
| #112 `ud02-94427` | 404 | optional accept 94427 | (a) |
| #115 `ud02-train-12` | 414 | train 12 | (a) |
| #117, #118 | 424, 427 | optional 94427 -> 94434 (Tanis Alderwood, Undercity) | (a) |
| #121 `ud02-end` | 434 | turnin 95803 at Lady Sylvanas (Royal Quarter). **The segment-end id is a class step**; the whole Royal Quarter walk exists only for it | (a) |

What stays at Bandarion Keep for every Undead class: 96899 -> 96896 -> 98545 (Leonid; 98545 ends at Glix in the
Undercity), 99152 (Hilda), 99153 (Ephram Barbaro), 95314 (Shadowvale elixir, from Brill): 6 quests, all with
estimated XP (460 / 420 each). Whether the trip is still worth it without the paladin chain is a path decision;
in the "no class quests" experiment below it was kept.

### 3.3 `ud-03-silverpine` (`UD/03`)

| Step | Line | What | Class |
|---|---|---|---|
| #5 | 59 | note "Reward: Deathstalker Shortsword - keep the Driftwood Smasher" | (b) |
| #24, #31 | 128, 153 | reward notes (leather belt, boots) | (b) mild |
| #52 `ud03-train-14` | 231 | train 14 at Garen Largo (Undercity War Quarter); note names Thunder Bluff as the next trainer | (a) |

Race-specific (not class): #14, #15, #45, #47 (lines 91, 93, 213, 217): 6321 -> 6323 -> 6322, `races = UNDEAD`;
#42 `ud03-hearth` (203) hearth to Brill and #43, #46 (208, 215) 440 -> 441 depend on the Brill bind.

### 3.4 `ud-04-barrens` (`UD/04`): no class step

| Step | Line | What | Class |
|---|---|---|---|
| #11 `ud04-sethearth` | 107 | note "There is no paladin trainer in the Barrens: the next training (18) is in Thunder Bluff" | (b) |
| #8, #37, #39, #66, #74, #80, #95 | 99, 210, 217, 323, 363, 393, 461 | reward notes: cape, "(mail)" belt / boots / leggings, "Stonewood Hammer (2H mace)", "Wildgore Greatsword if you can use two-handed swords", tinker's pants | (b) |

### 3.5 `ud-05-stonetalon-ashenvale` (`UD/05`)

| Step | Line | What | Class |
|---|---|---|---|
| #7 `ud05-train-18` | 110 | train 18 at Alodan the Hopeful (Pools of Vision, same cave as Zamah) | (a) |
| #26 | 200 | note "a shield or a staff, neither is for a 2H paladin" | (b) |
| #31 | 224 | note "Stonewood Hammer (2H mace, better than the Driftwood Smasher)" | (b) |
| #44 `ud05-lvl-pre20` | 281 | gate 19 + 88 %; note "Pre-training check ... the trainer needs 20" | (b): the gate exists for the level-20 training trip |
| #48 `ud05-lvl-20` | 306 | turnin 6401 + `level = 20`; note "Training needs level 20" | (b) |
| #50 `ud05-fly-tb`, #51, #53 `ud05-sethearth-tb`, #54 `ud05-fly-ratchet-2` | 313-330 | the Thunder Bluff trip at 20: generic steps, but the trip exists for the training (and to bind the hearth) | generic, class-motivated |
| #51 | 315 | `go` to the Pools of Vision (the paladin trainer's cave) | (a) |
| #52 `ud05-train-20` | 317 | train 20 | (a) |
| #63 | 360 | Piznik note "Consecration under your feet, Lay on Hands for emergencies" | (b) |
| #82 `ud05-lvl-grind` | 434 | grind note "two at a time with Consecration" | (b) |
| #84 `ud05-lvl-22` | 445 | note "Training needs level 22" | (b) |
| #13 | 144 | "Padded Lamellar Boots (mail)" | (b) |
| #91 `ud05-end` | 465 | train 22. **The segment-end id is a class step**; its note also announces "the shared Horde route" | (a) |

### 3.6 XP dependency of the paladin steps (c), quantified

Scratch run: the Undead route with every paladin quest (98601, 90902, 91208, 91209, 91282, 91285, 91294, 91316,
91317, 95803, 94427, 94434), every `train` and `Inserts.lua` removed; 0 validator errors.

| | With class quests | Without | Difference |
|---|---|---|---|
| `ud-01` quest XP / end level | 3 715 / 5.88 | 3 150 / 5.73 | -565 XP (98601 40, 90902 170, 91208 355, all estimated) |
| `ud-02` quest XP / kill XP / end level | 28 275 / 16 367 / 12.78 | 23 440 / 14 542 / 12.09 | -4 835 quest XP (91209 355; 91282, 91285, 91294, 91316 660 each; 91317, 95803, 94427, 94434 460 each; all estimated), -1 825 kill XP (16 murlocs, 14 Tarnished) |
| arrival in the Barrens (`ud-03` end) | 14.56 | 14.05 | -0.51 level |
| `ud-04` end | 17.99 | 17.64 | -0.35 |
| `ud-05` grind kills (worst) | 74 (107) | 106 (107) | +32 kills at `ud05-lvl-grind`; `ud05-lvl-pre20` worst 0 -> 22, `ud05-lvl-21` worst 3 -> 17 |
| level at 22 | 22.06 | 22.06 | held by the gates |

So a non-paladin Undead is about 7 200 XP (0.5 to 0.7 level) behind until the gates of 18-22 absorb it. Nothing
breaks: every `reqLevel` of the later steps is still met (421 "Prove Your Worth" needs 12 at the Sepulcher and is
reached at 12.09 + the first Silverpine turn-ins). The other classes have their own class quests in the same
places (scroll quest at 1, class quests at 10), which the class agents add back; their XP is not in this number.

From 22 on: the optional paladin chain 91858 -> ... -> 95034 (`UD/Ins:55-120`) is 7 quests of estimated XP
(6 x 1300 + 1950); with it `h-22` ends at 25.11, without at 24.84 (comment `UD/Ins:58-59`).

### 3.7 `sd-01-zephras` (`SD/01`)

| Step | Line | What | Class |
|---|---|---|---|
| #4 | 39 | note "Wrath, then melee" | (b) |
| #10 | 69 | `turnin { 92461, 92474 }, accept { 92464, 92485 }` at Rorian + `reward = { [92461] = 1 }`: 92485 "A Student of Nature" is DRUID | (b) split; **anon** |
| #11 `sd01-92485` | 75 | turnin 92485 at Xyton Silverwind (druid trainer 251373), `use = 282420` | (a) |
| #12 `sd01-train-1` | 81 | train (Mark of the Wild) | (a) |
| #28 `sd01-train-4` | 167 | optional train 4 | (a) |
| #47 `sd01-train-6` | 261 | train 6 at Naeluna Swiftmend (Shen'dar, 254081) | (a) |
| #69 | 360 | Vulgara (elite) note "Thorns + Rejuvenation, keep your distance" | (b) |
| #77 `sd01-train-8` | 406 | optional train 8 | (a) |
| #78 | 416 | optional vendor: Walking Stick (staff) | (b) class gear |
| #10, #24, #27, #34, #35, #59, #74, #75, #91 | 69, 149, 161, 195, 201, 316, 391, 397, 481 | `reward = { [quest] = n }`, chosen for a druid, with the note "picked automatically: item n" | (b): per-class reward (core.md 5.7) |

The other Zephras classes have the same pattern at the same NPC: Rorian (251361) gives 92482 hunter (-> Tai'ree
Farsight 251376), 92483 rogue (-> Akeri Duskblade 251389), 92484 shaman (-> Windshaper Boro 251374), 92532 warrior
(-> Blademaster Ren 251964), all level 2, pre 92461. The anchor is step #10, which has no id.

Racial, valid for every Skyborne: 92474 "Falling With Style" (Walk on Air), 92598 "The Gift of Skysight" (Horde
Skyborne only), the many "glide with Walk on Air" notes.

### 3.8 `sd-02-zephras` (`SD/02`)

| Step | Line | What | Class |
|---|---|---|---|
| #13 | 83 | optional vendor: Zephrali Greatstaff | (b) class gear |
| #23 `sd02-level-10` | 146 | turnin 92685 + `level = 10`; note "Level 10 is needed next (Bear Form quest and training)" | (b): the gate is generic (every class trains at 10), the note is not |
| #24 `sd02-bear-accept` | 162 | accept 94006 at Lotheluum Starbreeze (druid trainer 252359, Valanaar) | (a) |
| #25 `sd02-train-10` | 169 | train 10; note has talents | (a) |
| #26, #27 | 183, 188 | `go` north out of Valanaar and to the cliff above Urs'endris | (a) travel that only serves the bear chain |
| #28 `sd02-bear-quest` | 194 | turnin 94006, accept 94638 at Urs'endris | (a) |
| #29 | 200 | `go` out of the falls basin | (a) travel |
| #30 | 205 | complete 94638: kill Ur'endra | (a) |
| #35 | 227 | `go` east, glide down to Urs'endris | (a) travel |
| #36 `sd02-bearform` | 232 | turnin 94638; note "The reward is Bear Form. Fight in it from now on" | (a) |
| #37 | 241 | `go` leave the basin again | (a) travel |
| #53 | 315 | complete 94489 "The Wounds of Betrayal"; note "heal 7 wounded druids (Rejuvenation / Healing Touch)". The quest has no class limit; the objective is an "interact" objective in the DB | (b): other classes need another instruction |
| #60 | 354 | turnin 94491 at Lotheluum (generic quest, druid trainer NPC); the accept of 94484 at #6 (line 59) is at the same NPC | generic |
| #61 `sd02-train-12` | 355 | train 12 | (a) |
| #69 `sd02-train-12-plateau` | 394 | optional train at Hana Lighthoof (Skywatcher Plateau, 262560) | (a) |
| #70 | 405 | accept 94911 "Child of Nature" (DRUID + Skyborne Horde) at Muln Earthfury | (a); **anon** |
| #9, #21, #55, #57 | 66, 130, 328, 338 | `reward` fields | (b) |

For a non-druid the route between Valanaar and the northern forest is shorter: the generic steps #31 - #34
(construct parts, 98512 at Fendaal Windstone) are near Ur'endra's area and do not need the falls basin.

### 3.9 `sd-03-mulgore-silverpine` (`SD/03`)

| Step | Line | What | Class |
|---|---|---|---|
| #1 `sd03-cliff`, #2 `sd03-spirit` | 35, 42 | deathskip from Skywatcher Plateau to the Thunder Bluff spirit healer | generic for Skyborne |
| #3, #4 | 49, 56 | `go` to the rope bridge and over to Elder Rise | (a) travel: Elder Rise is visited only for Turak |
| #5 `sd03-train-tb` | 61 | optional train at Turak Runetotem (Teleport: Moonglade if missing) | (a) |
| #6 `sd03-child` | 72 | turnin 94911, accept 94913 "Moonglade" | (a) |
| #7 | 79 | `go` back over the bridge | (a) travel |
| #9 `sd03-fly-org` | 92 | fly Thunder Bluff -> Orgrimmar, flight point not known (WARN-OK) | generic, open game fact |
| #11 `sd03-sethearth` | 107 | bind in Orgrimmar; note "you hearth back here from Moonglade" | (b) |
| #23 | 151 | turnin 95350, accept 98024 at Thrall: Skyborne Horde racial pair | race step |
| #24 | 156 | optional accept 1061 (Zor Lonetree, next to Thrall) | generic, but only Skyborne walk there |
| #71 `sd03-moonglade` | 387 | turnin 94913 at Dendrite Starblaze after Teleport: Moonglade from the Undercity | (a) |
| #72 `sd03-train-14` | 394 | optional train 14 at Loganaar | (a) |
| #73 `sd03-hearth` | 406 | hearth to Orgrimmar | generic: a non-druid uses the same hearth directly from the Undercity |

### 3.10 `sd-04-barrens` (`SD/04`)

| Step | Line | What | Class |
|---|---|---|---|
| #1 `sd04-start` | 35 | note "The hearthstone is on cooldown ... Cast Skysight while running" | (b): hearth remark is druid history, Skysight is racial |
| #4 `sd04-sethearth-xroads` | 55 | note "you hearth back from Moonglade later" | (b) |
| #8 | 69 | `turnin 98024` (Skyborne racial) merged with `accept { 871, 5041 }` at Thork | race: split |
| #61 | 321 | complete 896 + `level = 16`; note "Level 16 is needed before the teleport (training)" | (b): gate serves the class training |
| #62 `sd04-train-16` | 333 | Teleport: Moonglade from the Boulder Lode Mine, train 16 | (a) |
| #63 `sd04-hearth` | 346 | hearth to the Crossroads; note names Nighthaven as fallback | generic step, (b) note |

### 3.11 `sd-05-stonetalon-ashenvale` (`SD/05`)

| Step | Line | What | Class |
|---|---|---|---|
| #1 `sd05-start` | 39 | note "The hearthstone (Taurajo) is only needed after Moonglade" | (b) |
| #19 `sd05-train-18` | 155 | Teleport: Moonglade at the Stonetalon border, train 18 | (a) |
| #20 `sd05-hearth-taurajo` | 171 | hearth to Camp Taurajo | generic step (a non-druid hearths from the border), (b) note |
| #44 `sd05-level-20` | 305 | turnin 913 + `level = 20`; note "The Cat Form quest needs level 20" | (b) |
| #46 `sd05-sethearth-tb` | 320 | note "you hearth back here from Moonglade" | (b) |
| #50 `sd05-cat-start` | 337 | accept 98340 at Turak (DRUID; Skyborne Horde + Tauren) | (a) |
| #54 `sd05-cat-dendrite` | 365 | Teleport: Moonglade; turnin 98340, accept 98341 (Skyborne only) | (a) |
| #55, #57, #58 | 370, 380, 387 | 98341 -> 98404 -> 98738 (Skyborne only, no class limit in the DB) | (a) |
| #56 | 375 | `go` to the Stormrage Barrow Dens | (a) travel |
| #59 | 392 | turnin 98738, accept 98362 | (a) |
| #60 `sd05-hearth-tb` | 397 | hearth to Thunder Bluff **from Moonglade**: a class use of the hearthstone | (a) |
| #61 `sd05-catform` | 404 | turnin 98362 (reward: Cat Form) | (a) |
| #62 `sd05-train-20` | 410 | train 20 at Turak | (a) |
| #68 | 457 | optional Piznik note "in Bear Form with Swipe" | (b) |
| #82 | 541 | optional Vorsha note "heal him and yourself" | (b) |
| #87 `sd05-train-22` | 581 | Teleport: Moonglade, train 22. **Last step of the segment**: the route ends in Moonglade, and the druid insert `sd-bridge-fly-tb` flies back to Thunder Bluff | (a) |

### 3.12 XP dependency of the druid steps (c), quantified

Scratch run without 92485, 94006, 94638, 94911, 94913, 98340, 98341, 98404, 98738, 98362 and without `train`
steps; 0 errors.

| | With | Without | Difference |
|---|---|---|---|
| `sd-01` quest XP | 16 865 | 16 695 | -170 (92485) |
| `sd-02` | 21 255 | 20 415 | -840 (94006, 94638; 420 each, estimated) |
| `sd-03` | 22 965 | 22 125 | -840 (94911, 94913) |
| `sd-05` | 51 470 | 47 570 | -3 900 (five Cat Form quests, 780 each, estimated) |
| arrival in the Barrens / end of 04 / end of 05 | 15.59 / 19.02 / 22.24 | 15.49 / 18.96 / 22.07 | -0.1 / -0.06 / -0.17 |
| gate `sd05-level-22` (worst) | 0 (40) | 0 (74) | +34 worst-case kills |

The druid's dependency is small (5 750 estimated XP, none of it gating). What other Skyborne classes lose is
travel, not XP: the druid visits Moonglade by teleport five times (14, 16, 18, 20, 22) and returns by hearth.
At 14, 16 and 18 the generic replacement is the same hearth step without the teleport (`sd03-hearth`,
`sd04-hearth`, `sd05-hearth-taurajo`: a non-druid hearths from the Undercity, the mine and the Stonetalon
border). At 22 the generic route needs a plain hearth to Thunder Bluff from Zoram'gar instead of the teleport.
Only the level-20 hearth `sd05-hearth-tb` (back from the Cat Form chain) is a class use of the stone.

From 22 on: the Torwa chain 9063 / 9052 / 9051 (`SD/Ins`, anchors `h-53-torwa-pathfinder`, `h54-torwa-3`,
`h55-torwa-end`, `h54-hearth-org`) gives 10 700 known XP at 53: `h-53` needs 318 grind kills for the druid and
362 for the paladin.

---------------------------------------------------------------------------------------------------------------

## 4. Diff of `ud-04` vs `sd-04` and `ud-05` vs `sd-05`

### 4.1 Quest-level diff (both segments together)

90 quests appear in the four segments; 75 are in both routes (65 in the same segments, 10 not), 15 in one only.

**Identical quests, same segments in both routes (65).** Accepted and turned in in 04 (38): 840, 842, 844, 870,
871, 5041, 867, 1492, 848, 1358 (turn-in only), 869, 845, 872, 97253, 887, 895, 894, 896, 890, 892, 903, 850, 877,
881, 858, 863, 900, 901, 902, 95494, 95507, 95495, 95621, 95508, 3281, 905, 4921, 819. Accepted in 04 and turned
in in 05 (6): 888, 899, 865, 821, 880, 3261. Accepted and turned in in 05 (21): 882, 907, 5052, 913, 1489, 6629,
6523, 6401, 6461, 1093, 1094, 6562, 1095, 1063, 1090, 1092, 98251, 98252, 6442, 1064, 1490.

**Same quest, different segment (10).**

| Quest | Undead | Skyborne | Why |
|---|---|---|---|
| 855 Centaur Bracers (turn-in) | `ud-05#31` | `sd-04#97` | Skyborne finish Regthar's chain (Lushwater Oasis) at the end of 04 |
| 851 Verog (turn-in), 852 Hezrul | `ud-05#29`, `#29-#31` | `sd-04#94`, `#94-#97` | same |
| 95774 Her Name Is Olgra | accept `ud-04#72`, turn-in `ud-04#92` | accept `sd-04#93`, turn-in `sd-05#32` | Skyborne take it on the last Crossroads visit and do it with the Bristleback loop |
| 853 Apothecary Zamah (timed, 45 min) | accept `ud-04#96` (last step), turn-in `ud-05#6` | accept `sd-05#34`, turn-in `sd-05#53` | Undead have no Thunder Bluff flight point: 853 forces "Thunder Bluff first" at 18 (walk from Camp Taurajo, training 18, flight point). Skyborne know Thunder Bluff since 13 and take 853 right before flying there at 20 |
| 1483 Ziz Fizziks, 1069 Deepmoss Spider Eggs (accept) | `ud-05#10`, `#11` | `sd-04#72`, `#73` | the third Ratchet visit is in 04 for both; Undead come back to Ratchet from Thunder Bluff at 18 |
| 878 Tribes at War (accept) | `ud-05#19` | `sd-04#86` | Skyborne take it on the first Camp Taurajo visit |
| 1062 Goblin Invaders, 6548 Avenge My Village (accept) | `ud-05#32` | `sd-04#100`, `#101` | `sd-04` ends at the Stonetalon border, `ud-04` at the Crossroads |

**Only one route (15).**

| Quest | Route | Known XP | Why |
|---|---|---|---|
| 216 Between a Rock and a Thistlefur, 6462 Troll Charm | Undead (`ud-05#75-#84`) | 1950 + 1950 | the Undead route is short of 22 and adds Thistlefur Village and a grind gate there; `SD/05` skips them as "level 24, off the path" |
| 1065 Journey to Tarren Mill (accept) | Undead (`ud-05#90`) | - | carried into `h-22`; for Skyborne the library accepts it (`h-22-tb-start`) |
| 875 Harpy Lieutenants | Skyborne (`sd-04#65`, `sd-05#31`) | 1150 | Undead skip it (`UD/04` #70 note; `docs/routes/horde-undead-paladin.md` 9.1) |
| 6301 Cycle of Rebirth | Skyborne (`sd-05#64-#66`) | 1400 | Undead do it in `h-24` (the three race-filtered steps) |
| 1061 The Spirits of Stonetalon (optional) | Skyborne (`sd-03#24`, `sd-04#99`) | 320 | accepted in the Valley of Wisdom next to Thrall, where only Skyborne go |
| 883 Lakota'mani, 884 Owatanka (optional, rare drops) | Skyborne (`sd-04#82`, `#85`; `sd-05#39`, `#43`) | 1300, 1450 | bg item-start steps; the Undead notes only mention the items |
| 6641 Vorsha the Lasher (optional escort) | Skyborne (`sd-05#82-#85`) | 2300 | optional |
| 98024 Journey to the Crossroads | Skyborne (`sd-04#8`) | ? | Skyborne racial breadcrumb from Thrall |
| 98340, 98341, 98404, 98738, 98362 | Skyborne druid | ? | Cat Form chain (class) |

Also different in kind: 896 is optional for the Undead (`ud-04#49`, `#75`) and mandatory with the level-16 gate
for the Skyborne (`sd-04#61`, `#74`); 1090 / 1092 (Piznik) is mandatory for the Undead (`ud-05#62-#65`) and
optional for the Skyborne (`sd-05#68-#70`); 821 is a bg turn-in for the Undead (`ud-05#55`) and an optional
one for the Skyborne (`sd-05#29`); 819 is started at Ratchet by the Undead (`ud-04#77`, optional) and where the
keg lies by the Skyborne (`sd-04#12`, bg accept).

None of 216, 6462, 875, 876, 1060, 1061, 883, 884, 6641, 1090, 1092, 1068, 3921, 3922, 822 appears in the
library. 6301 does (`H/02:259`, `306`, `355`, race-filtered) and its follow-up 6381 (`H/02:358`).

### 4.2 Structural diff, hub by hub

**Segment 04.**

| Hub / leg | `ud-04` | `sd-04` | Reason |
|---|---|---|---|
| Start | Durotar zeppelin tower; #1 - #2 walk into Orgrimmar for the flight point (+3 min) | Orgrimmar inn (hearth), #1 leave by the main gate | Undead arrive by zeppelin from Tirisfal and never saw Orgrimmar; Skyborne flew there at 13 |
| Razor Hill, Far Watch Post | #3 - #4 | #2 - #3 | identical (840 -> 842) |
| Crossroads 1 | #5 - #11: quests, flight point, bind last | #4 - #10: bind and flight point first, then quests, plus `turnin 98024` | order only (both orders respect the look-ahead rule); 98024 is racial; 867 is taken here by the Undead and on visit 2 by the Skyborne |
| Thorn Hill 871, Crossroads 2, far camp 872 + 5041 | #12 - #21 | #11 - #18 | identical |
| Ratchet 1, pirates, Ratchet 2 | #22 - #35 | #19 - #33 | identical quests; 896 accepted on visit 1 (Undead) or 2 (Skyborne) |
| Ratchet -> Crossroads | #36 fly | #34 walk "through the zhevra herds" | Skyborne finish 845 / 869 on the walk |
| Regthar, Barak, Forgotten Pools | #39 - #45 | #37 - #41 | identical |
| North loop | #46 - #67: Crossroads (877, 881), Echeyakee, mine (optional), Sludge Fen, Samophlange, Vrang chain, harpies, then #68 hearth | #42 - #61: harpies, Vrang chain, Samophlange, lion den, Sludge Fen, mine + gate 16, then #62 Teleport: Moonglade (train 16), #63 hearth; Echeyakee is a separate trip from the Crossroads (#69 - #70) | the druid ends the loop at the mine, where the teleport costs nothing; the Undead route does Echeyakee inside the loop (one trip less) |
| Crossroads 4 | #69 - #72 (867 turned in, 875 not taken; Mankrik 899, 4921, 95774) | #64 - #68, #70 (867 -> 875; Mankrik 899, 4921) | 875 |
| Ratchet 3 | #73 - #78 | #71 - #74 (+ 1483, 1069) | see 4.1 |
| South sweep | #79 - #88: crates, silver, oasis (877, 848; Verog bg), nests, Raiders (95774), corpse | #76 - #83: crates, silver, oasis, Verog (mandatory), nests, Lakota'mani (bg), corpse | Verog bg vs mandatory; 95774 |
| Camp Taurajo | #89 - #90: flight point, bind | #84 - #87: bind, 883 (optional), 878, flight point | |
| Crossroads 5 | #91 - #96, ends with the timed 853 | #88 - #93 | 853 |
| Tail | - | #94 - #101: Regthar 851 -> 852, Lushwater (852, 880 shells bg), Regthar, harpy lieutenants 875, Stonetalon border (1061, 1062, 6548) | the Skyborne segment absorbs the start of 05 (it ends at 19.02, over plan) |

**Segment 05.**

| Block | `ud-05` | `sd-05` | Reason |
|---|---|---|---|
| Thunder Bluff at 18 | #1 - #9: fly Camp Taurajo, Jorn, walk to Thunder Bluff, 853, train 18, flight point, fly Ratchet | none | timed 853 + missing flight point + paladin training; the druid trains in Moonglade |
| Ratchet, Ishamuhale, Stagnant Oasis | #10 - #16, then #17 hearth to Camp Taurajo | #24 - #29 after the Bristleback loop, then fly | order |
| Camp Taurajo chain (882 -> 907 -> 913, 878 -> 5052) | #18 - #26 | #21 - #23 and #36 - #44 (two visits) | order |
| Crossroads, Regthar, Lushwater | #27 - #31 | in `sd-04` | |
| Stonetalon pass 1 | #32 - #49: border accepts, Aparaje, Grundig, Kaya, Xen'Zilla, Ziz, Windshear Crag, gate 19 + 88 %, Ziz, Sun Rock (6562, 6401, flight point) | #1 - #18: Aparaje, Grundig, Kaya, Xen'Zilla, Sun Rock flight point, Ziz, Windshear Crag, back south to Xen'Zilla and the border (6461, 6523 / 6629, 1062 -> 1063) | Skyborne hand in everything at the border at the end of pass 1 so that pass 2 can start by flight at Sun Rock; Undead leave from Sun Rock by flight to train |
| Class break | #50 - #54: fly Thunder Bluff, train 20, bind, fly Ratchet | #19 - #20: Teleport: Moonglade (train 18), hearth Camp Taurajo | |
| Thunder Bluff quests (1063 -> 1064, 1489 -> 1490, 1064 -> Zamah) | at the very end, #85 - #90, after the hearth | #45 - #53 at level 21, with 853 | |
| Cat Form | - | #50, #54 - #62 | class |
| Stonetalon pass 2 | #58 - #65: fly Crossroads, walk to the border (1062 -> 1063), Xen'Zilla, Piznik, Ziz | #63 - #71: fly Sun Rock, 6401 -> 6301 seeds, 6562, optional Piznik, Ziz | Undead walk in from the Crossroads a second time |
| Ashenvale | #66 - #84: Va'xug pair, Zoram'gar, naga + gate 21, Thistlefur (216, 6462) + grind gate 21 + 85 %, gate 22 | #72 - #86: Va'xug pair, Zoram'gar, optional Vorsha, naga + gate 22 | Thistlefur |
| End | #85 hearth Thunder Bluff, Elder Rise quests, accept 1065, train 22 | #87 Teleport: Moonglade, train 22 | |

Summary of the reasons: (1) flight points known on arrival (Thunder Bluff and Orgrimmar for Skyborne, neither for
Undead); (2) the timed 853; (3) the druid's free return trips; (4) different arrival level (14.56 vs 15.59), which
is why the Undead route adds Thistlefur and still grinds 74 kills while the Skyborne route does not grind;
(5) author preference (walk vs fly from Ratchet, Echeyakee inside or outside the north loop).

### 4.3 Cross-check: an Undead on the druid's Barrens segments

Scratch run: `ud-01..03` without paladin quests, then `sd-04` + `sd-05` with the class and racial steps removed
(no 98024, 1061, Cat Form, `train`, `sd05-hearth-tb`).

| | Result |
|---|---|
| arrival | 14.05 |
| `sd-04` | 14.05 -> 18.04, quest XP 43 015, 0 grind (gate 16 at the mine passes) |
| `sd-05` | 18.04 -> 22.01, quest XP 47 720, **96 grind kills at `sd05-level-22` (worst 172)** |
| warnings | `fly-unknown-fp` at `sd05-fly-tb` (no Thunder Bluff flight point), and at `h-22-tb-fly-org` (no Orgrimmar flight point) |
| library errors | 1065 never accepted (`h-22` turn-in), 6301 done twice (`h-24`) |

The same character on `ud-04` + `ud-05` needs 106 kills (worst 107). So neither order is clearly better for a
14.05 arrival; what decides the grind is the quest set and the arrival level. The union (the Skyborne set + 216 +
6462) is worth about 3 900 quest XP + the Thistlefur kills more than `sd-05` alone, roughly half of the 14 400 XP
the gate is short of.

### 4.4 Proposal: unified shared segments

Ids follow the library convention (`h-<level>-<zone>`, step ids `h<level>-...`); titles carry no faction word.
Every step gets an explicit id (core.md 0.4).

**`h-13-silverpine`** (13-15, "13-15 Silverpine Forest"), from the Tirisfal / Silverpine road to the Undercity
exit. Core = the 23 quests both routes do: 435, 429, 449, 421, 477, 437, 3221, 445 (turn-in), 430, 447, 1359, 422,
91920, 425, 423, 438, 424, 439, 478, 481, 482, 97891, 1358 (accept). Outline (order of `ud-03`, which saves the
third trip north):

1. `h13-erland` accept 435; escort; Rane Yorick 435 -> 429 + 449; hearts + 3 Murloc Eyes.
2. Sepulcher 1: 421, 477, 449 -> 437 + 3221, Renferrel (429, 445, 3221 -> 430, 447, 1359), `h13-fp-sepulcher`.
3. Whitescalps 421; Sepulcher 2: 421 -> 422.
4. North: spellbooks 422, Quinn 430 -> 91920, Rane 425, Ivar, Rane, Dead Field 437, spiders and bears 447.
5. Sepulcher 3: 422 -> 423, 437 -> 438, 91920; gluttons 423; Sepulcher 4: 423 -> 424.
6. Ferry 438 -> 439, Grimson 424, Dalaran crate 477 -> 478; Sepulcher 5: 478 -> 481 -> 482, 424, 439.
7. Undercity: 97891 (timed), 447, 1359 -> 1358; `h13-uc-end` (anchor for Undercity trainers at ~14.5).

Race-filtered steps inside it: 6321 -> 6323 at Podrig / Karos Razok and 6323 -> 6322, 6322 in the Undercity
(`Scourge`: `races = UNDEAD`); 439 -> 440, hearth Brill, 440 -> 441, 441 (`Scourge`: needs the Brill bind;
+1150 XP); "fly to the Undercity" from the Sepulcher (everyone else). Decide once for everybody: 91921 "Return
to Quinn (Again)" (Skyborne take it, Undead skip it as a third trip north).

**`h-15-barrens`** (15-18, "15-18 The Barrens") and **`h-18-stonetalon-ashenvale`** (18-22, "18-22 The Barrens,
Stonetalon Mountains, Ashenvale"). Quest set = the union of 4.1: the 77 common quests + 216, 6462, 875, 6301,
optional 883, 884, 6641, with 1090 / 1092 optional and 896 optional. Outline (the Undead order is the better
base for a class-neutral path because it has a trainer city at 18, 20 and 22; the Skyborne route has none between
Orgrimmar at 15.6 and Thunder Bluff at 21.2 because the druid trains in Moonglade):

`h-15-barrens`:

1. `h15-razor-hill` accept 840; `h15-far-watch` 840 -> 842.
2. Crossroads 1: `h15-xr-arrive` 842 -> 844; 870; 867, 871, 5041; 1358 -> 848 + 1492; 869; `h15-fp-xroads`;
   `h15-sethearth-xroads`.
3. Thorn Hill 871; Crossroads 2 (844 -> 845, 871 -> 872); keg spot (optional); far camp 872 + 5041.
4. Ratchet 1 (`h15-fp-ratchet`, 97253, 887, 895, 894, 1492 -> 896), pirates, Ratchet 2 (887 / 895 -> 890 -> 892
   -> 888, 97253); `h15-fly-xroads`.
5. Crossroads 3 (872 / 5041, 845 -> 903); Regthar 850 + 855; Barak; Forgotten Pools; Regthar 850 -> 851;
   Crossroads (870 -> 877, 903 -> 881).
6. North loop: Echeyakee, mine (896, optional), Sludge Fen (858 -> 863), Samophlange (894 -> 900 -> 901 -> 902),
   Vrang and Walton (95494, 95507 -> 95495 -> 95621 -> 95508), harpies 867; `h15-hearth-xroads`.
7. Crossroads 4: 869 -> 3281, 867 -> 875, 881 -> 905, Mankrik (899, 4921, 95774); `h15-fly-ratchet`.
8. Ratchet 3: 863 + 902, 896 (optional), 865, 1483, 1069, 819 -> 821 (optional).
9. South sweep: 888 crates, 3281 silver, Stagnant Oasis (877, 848, Verog), nests (905, 865), Raiders (95774),
   corpse (4921); Camp Taurajo: `h15-fp-taurajo`, `h15-sethearth-taurajo`, accept 878; `h15-fly-xroads-2`.
10. Crossroads 5: 4921 + 95774, 877 -> 880, 905 -> 3261, 3281, 851 -> 852 (Regthar), `h15-end` 848 -> 853 (timed).

`h-18-stonetalon-ashenvale`:

1. `h18-fly-taurajo`; Jorn 3261 -> 882; Thunder Bluff 1: walk in or fly (race-filtered, below), `h18-tb-zamah`
   853, `h18-fp-tb`; anchor `h18-tb-1` for training 18 (~18.0); `h18-fly-ratchet`.
2. Ratchet (865 -> turn-in, 888); Ishamuhale 882; Stagnant Oasis (880, Verog); `h18-hearth-taurajo`.
3. Camp Taurajo chain: 882 -> 907, Bristleback camp (878 + 899), 907, 878 -> 5052, 907 -> 913, 913; optional 884;
   `h18-fly-xroads`.
4. Crossroads (880 + 899 -> 1489, 875 turn-in if done); Regthar, Lushwater (852, 855), harpy lieutenants 875
   (where the route passes them), Stonetalon border (1062, 6548).
5. Stonetalon pass 1: Aparaje 6548 -> 6629, Grundig, Kaya 6523, Makaba (-> 6401), Xen'Zilla 6461, Ziz 1483 ->
   1093, Windshear Crag (1062, 1093, 1069, 6461), gate before 20, Ziz 1093 -> 1094, Sun Rock: 6562, 6401 (+ 6301
   seeds if 6301 stays here), `h18-fp-sunrock`.
6. `h18-fly-tb`: Thunder Bluff 2: anchor `h18-tb-2` for training 20 (~20.3), `h18-sethearth-tb`, 1489 -> 1490;
   `h18-fly-ratchet-2` (821, 1094 -> 1095, 1069); `h18-fly-xroads-2`.
7. Border 1062 -> 1063; Xen'Zilla 6461; Piznik 1090 -> 1092 (optional); Ziz (1092, 1095); Talondeep Path.
8. Ashenvale: Va'xug 98251 -> 98252; Zoram'gar (6562, 6442, 6462, `h18-fp-zoram`, optional 6641); naga + gate
   21; 216; Thistlefur (216, 6462) + grind gate; Zoram'gar turn-ins + gate 22.
9. `h18-hearth-tb`; 1063 -> 1064 (Magatha), 1064 (Zamah); anchor `h18-tb-3` for training 22; `h18-end`.
   1065 is **not** accepted here; `h-22-tb-start` accepts it for everybody.

This outline is the Undead order with the Skyborne extras. Its cost against `sd-05` is one more walk into
Stonetalon; its gain is three class-neutral trainer stops. Both variants should be run through the harness from
the two real arrival states (section 5) before the path is frozen; the gates of 18-22 must be re-tuned for the
lowest arrival (a non-paladin Undead at 14.05).

### 4.5 Exact list of race-filtered steps

| Where | Step(s) | Filter | Why |
|---|---|---|---|
| `h-13-silverpine` | accept 6321 / turnin 6321 + accept 6323 (Sepulcher); 6323 -> 6322, 6322 (Undercity) | `Scourge` | `races = UNDEAD` in the DB |
| `h-13-silverpine` | 439 -> 440 (Hadrec), hearth Brill, 440 -> 441 (Sevren), 441 (Raleigh) | `Scourge` | only the Undead are bound to Brill |
| `h-13-silverpine` | fly Sepulcher -> Undercity | all but `Scourge` | the Undead hearth instead |
| `h-13-silverpine` exit | lift + zeppelin to Durotar vs hearth to Orgrimmar | by race history | better: put the exit into the race's own bridge segment, not into a filter |
| `h-15-barrens` start | `go` to the Orgrimmar gate + `fp` Orgrimmar (2 steps, today `ud04-org-gate`, `ud04-org-fp`) | races that arrive without the Orgrimmar flight point: `Scourge` (and Tauren, if their path does not pass Orgrimmar) | Orc, Troll, Skyborne know it |
| `h-15-barrens`, Thork | `turnin 98024` | `Skyborne` (race file insert before the Thork step) | racial breadcrumb |
| `h-18`, border | optional `turnin 1061` at Seereth (and its accept at Zor Lonetree in the Skyborne bridge) | `Skyborne` (race file insert) | only they pass Zor Lonetree |
| `h-18`, Thunder Bluff 1 | `fly` Camp Taurajo -> Thunder Bluff | `Tauren`, `Skyborne` | flight point known |
| `h-18`, Thunder Bluff 1 | `go` Mulgore gate, `go` Thunder Bluff lift, `fp` Thunder Bluff | `Orc`, `Scourge`, `Troll` | flight point not known |
| `h-22-hillsbrad` | `h-22-tb-start` (accept 1065) | remove the filter | nobody accepts 1065 before |
| `h-22-hillsbrad` | `h-22-tb-fly-org` | remove the filter | everyone has the Orgrimmar flight point by 22 |
| `h-22-hillsbrad` | `h-22-tb-fly-xroads` and the two `go` steps (`H/01:81-90`) | **delete** | see summary point 8 |
| `h-24-barrens-stonetalon` | `h-25-sun-rock-retreat` (accept 6301), complete 6301, turnin 6301 (`H/02:259`, `306`, `355`) | remove the filter; keep 6301 either here or in `h-18`, for all races alike | the unified 15-22 gives one state |

If the unified path is done as above, the only race filters left in shared segments are the Undead-only quests,
the Brill hearth block and the "flight point known or not" pairs. Everything else that differs by race is a
whole block and belongs in the race's own bridge segment (a different `UseSegments` list), which needs no filter
and produces no `step-no-profile`.

### 4.6 Bridge steps each race needs before the merge

Merge point = the first step of `h-13-silverpine` (Deathstalker Erland, Silverpine 56.18, 9.18).

| Race | Bridge (own segment of the race) | State it must deliver |
|---|---|---|
| Undead | end of Tirisfal in the Undercity (flight point `ud02-fp-uc`, 98545 at Glix); `ud03-exit-uc` lift; `go` to the Silverpine road (today `ud-03#1-#2`). After Silverpine: lift, zeppelin (`ud03-zeppelin`, `ud03-end`), then the Orgrimmar flight point detour | 445 in the log (accepted at `ud-02#80`, `UD/02:315`); 96895 chain done in Tirisfal; hearth Brill |
| Skyborne | Skywatcher Plateau: deathskip (`sd03-cliff`, `sd03-spirit`), `fp` Thunder Bluff, fly Orgrimmar (open game fact), `fp` Orgrimmar, bind Orgrimmar, 5 city quests (97246 -> 97249, 97242, 97275, 97326 optional), Thrall 95350 -> 98024, optional 1061, zeppelin to Tirisfal | then the "visitor" block below; after Silverpine: hearth to Orgrimmar (druid: Moonglade first) |
| Orc, Troll | Durotar to ~12, Orgrimmar (flight point, trainers, the same 5 city quests), zeppelin to Tirisfal | then the "visitor" block; after Silverpine: zeppelin back; 840 at Razor Hill is on the way to the Barrens |
| Tauren | Mulgore to ~12, Thunder Bluff (flight point). To reach the zeppelin they must fly Thunder Bluff -> Orgrimmar (same open fact as the Skyborne) or run Camp Taurajo -> Crossroads -> Far Watch Post -> Orgrimmar | to be decided with numbers, section 8.4 |

"Visitor" block, shared by every non-Undead race (a small shared segment, e.g. `h-13-tirisfal-visit`, today
`sd-03#26-#34`): arrival at the Tirisfal tower; Brill: accept 96895 (Deathguard Terrence, reqLevel 10) and 445
(Apothecary Johaan, reqLevel 9); Hadric Harlson 96895 -> 96897 + 96898; cult camp; Hadric turn-in; `fp`
Undercity; `go` through the sewers to the Silverpine road. The Undead do these quests inside Tirisfal.

---------------------------------------------------------------------------------------------------------------

## 5. Character state at the merge candidates

From `--write-state ... --until`. "opt." = the optimistic level (unknown quest XP x 2).

| Point | | Level (opt.) | Done | Log | Hearth | Position | Flight points |
|---|---|---|---|---|---|---|---|
| End of the start zone | Undead, before `ud-03-silverpine` | 12.78 (14.01) | 66 | 445 | Brill | Undercity, Royal Quarter | Undercity |
| | Skyborne, before `sd-03-mulgore-silverpine` | 13.32 (15.80) | 69 | 94911, 95350 | Valanaar | Skywatcher Plateau | none |
| Zeppelin to Tirisfal | Skyborne, before `sd03-zeppelin` | 13.87 | 76 | 1061, 94913, 98024 | Orgrimmar | Orgrimmar | Orgrimmar, Thunder Bluff |
| **Arrival in the Barrens** | Undead, before `ud-04-barrens` | 14.56 (15.62) | 93 | 1358 | Brill | Durotar zeppelin tower | The Sepulcher, Undercity |
| | Skyborne, before `sd-04-barrens` | 15.59 (17.91) | 103 | 1061, 1358, 98024 | Orgrimmar | Orgrimmar inn | Orgrimmar, The Sepulcher, Thunder Bluff, Undercity |
| **End of 04** | Undead, before `ud-05` | 17.99 (19.07) | 132 | 821, 851 (complete), 853 (timed), 855 (complete), 865 (complete), 880, 888 (complete), 899, 3261 | Camp Taurajo | Crossroads (Helbrim) | + Camp Taurajo, Orgrimmar, Ratchet, The Crossroads |
| | Skyborne, before `sd-05` | 19.02 (20.71) | 147 | 821 (complete), 865 (complete), 875 (complete), 878, 880 (complete), 888 (complete), 899, 1062, 1069, 1483, 3261, 6548, 95774 | Camp Taurajo | Stonetalon border (Makaba) | + Camp Taurajo, Ratchet, The Crossroads |
| **End of 05 (22)** | Undead, before `h-22-hillsbrad` | 22.06 (22.47) | 170 | 1065 | Thunder Bluff | Thunder Bluff, Pools of Vision | Camp Taurajo, Orgrimmar, Ratchet, Sun Rock Retreat, The Crossroads, The Sepulcher, Thunder Bluff, Undercity, Zoram'gar Outpost |
| | Skyborne, before `h-22-hillsbrad` (before the bridge insert) | 22.24 (23.71) | 190 | empty | Thunder Bluff | Moonglade (Loganaar) | the same nine |

Differences of the turned-in sets at 22 outside the start zones: Undead only: 216, 6462, 440, 441, 6321, 6322,
6323. Skyborne only: 875, 883, 884, 1061, 6301, 6641, 91921, 97242, 97246, 97249, 97275, 97326, 95350, 98024 and
the Cat Form chain. (The Tirisfal block 96895 / 96897 / 96898 and 445 is done by both; 96899, 96896, 98545, 99152,
99153, 95314, 356, 97558 are Undead-only because they need Bandarion Keep or the Tirisfal loops.)

At 22 the two states already agree on hearth and flight points; the quest log differs only by 1065.

Levels at the 1-22 class stops (state before the step):

| Undead | Level | Skyborne | Level |
|---|---|---|---|
| `ud01-train-1` Deathknell | 2.65 | `sd01-train-1` Thendal camp | 3.14 |
| `ud01-train-4` Deathknell | 4.06 | `sd01-train-4` Thendal camp | 4.60 |
| `ud02-train-6` Brill | 6.58 | `sd01-train-6` Shen'dar | 6.36 |
| `ud02-train-8` Brill | 8.26 | `sd01-train-8` Shen'dar | 8.91 |
| `ud02-train-10` Brill | 10.31 | `sd02-train-10` Valanaar | 11.21 |
| `ud02-train-12` Brill | 12.60 | `sd02-train-12` Valanaar | 13.00 |
| `ud02-fp-uc` Undercity | 12.69 | `sd03-train-tb` Thunder Bluff / `sd03-sethearth` Orgrimmar | 13.32 / 13.35 |
| `ud03-train-14` Undercity | 14.56 | `sd03-fp-uc` Undercity / `sd03-train-14` | 14.17 / 15.59 |
| `ud04-org-fp` Orgrimmar | 14.56 | `sd04-sethearth-xroads` | 15.63 |
| `ud05-train-18` Thunder Bluff | 18.04 | `sd04-train-16` / `sd05-train-18` (Moonglade) | 17.76 / 19.67 |
| `ud05-train-20` Thunder Bluff | 20.29 | `sd05-sethearth-tb` / `sd05-train-20` Thunder Bluff | 21.22 / 21.46 |
| `ud05-end` Thunder Bluff | 22.06 | `sd05-train-22` | 22.24 |

---------------------------------------------------------------------------------------------------------------

## 6. The 22-60 library: start assumptions and race filters

### 6.1 What `h-22-hillsbrad` assumes at its first step

From the header (`H/01:13-17`, `55`) and the steps:

* the character stands in Thunder Bluff (first steps: Zamah in the Pools of Vision, then Tal);
* hearth = Thunder Bluff (used by `h-24-tb-hearth`, `H/01:328`);
* 1064 is turned in (pre of 1065); 1065 is in the log (Undead) or accepted at `h-22-tb-start` (Skyborne);
* flight points Thunder Bluff, The Crossroads, Camp Taurajo, Ratchet, Sun Rock Retreat, Zoram'gar Outpost, The
  Sepulcher, Undercity are known (the later segments fly to them without an `fp` step); Orgrimmar is learned at
  `h-22-org-fp` at the latest;
* level about 22 (`levels = { 22, 24 }`; gate `h-22-hillsbrad-level-gate` 23 + 85 %);
* five quests of 15-22 are prerequisites of library accepts (DB `preSingle`, checked for every library accept):
  1064 (for 1065, `h-22-tb-start`), 5052 (for 879, `h-24` #9), 913 (for 874, `h-24` #11), 1095 (for 1096, `h-24`
  #56), 6562 (for 6564, `h-24` #83); and 6301 for 6381 where the 6301 steps are filtered out (Skyborne). 1065 is
  the only quest the library turns in without accepting it for every race. The unified 15-22 must turn in these
  five (and so 1062 / 1063, 882 / 907, 878, 1483 / 1093 / 1094 before them).

### 6.2 Every race filter in the library (8 steps)

| Step | File:line | Filter | Meaning |
|---|---|---|---|
| `h-22-tb-start` (accept 1065) | `H/01:68-69` | `Skyborne` | Undead carry 1065 |
| `h-22-tb-fly-org` (fly Orgrimmar) | `H/01:75-76` | `Orc, Scourge, Tauren, Troll` | "Skyborne have no Orgrimmar flight point" (wrong today) |
| `h-22-tb-fly-xroads` (fly The Crossroads) | `H/01:81-82` | `Skyborne` | run to Orgrimmar |
| anon `go` Far Watch Post | `H/01:85` | `Skyborne` | |
| anon `go` Orgrimmar gate | `H/01:88` | `Skyborne` | |
| `h-25-sun-rock-retreat` (accept 6301) | `H/02:259-260` | `Orc, Scourge, Tauren, Troll` | the druid did 6301 at 20 |
| anon complete 6301 | `H/02:306-307` | same | |
| anon turnin 6301 | `H/02:355-356` | same | |

All eight carry `-- WARN-OK: step-no-profile`. `docs/routes/horde-22-60.md` section 8 documents them and ends
with "for new race routes (a Skyborne who knows Orgrimmar; a race without 1065) these filters must be revisited".
The filters already name Orc, Tauren and Troll, so those races fall on the Undead side today; that is only right
if their 15-22 path ends in the Undead state (1065 in the log, Orgrimmar known, 6301 not done).

### 6.3 What must change for Orc / Troll / Tauren and for other classes

1. Start state: with a unified 13-22 there is one state at 22 for all races; all 8 filters can go (4.5). Without
   unification each race needs its own answer to the three questions "1065?", "Orgrimmar flight point?", "6301?".
2. Quests: nothing. The harness run of all 12 segments from the Undead level-22 state gives 0 errors and the same
   numbers (level 60, quest XP 1 756 630, 4934 grind kills, worst 6068) for Orc WARRIOR, Orc SHAMAN, Troll MAGE,
   Troll PRIEST, Tauren HUNTER and Scourge WARLOCK. (Skyborne ROGUE from the Undead state fails only on the two
   filter artefacts: 1065 accepted twice, 6381 without 6301.)
3. Class steps: none in the library. Class XP that the gates implicitly absorb today: the paladin's optional
   chain at 22 and the druid's Torwa chain at 53 (3.6, 3.12).
4. Trainer coverage (6.4): the library's city stops were chosen with a paladin (Undercity, Thunder Bluff, Brill)
   and a druid (Thunder Bluff, Moonglade) in mind. Rogue and warlock have no trainer in Thunder Bluff; hunter and
   shaman have none in the Undercity.
5. Documentation and comments that name the two profiles: `H/01:3`, `13-17`, `55`, `65-67`; `H/02:306`, `355`;
   `docs/routes/horde-22-60.md` sections 1, 8, 10.

### 6.4 Class or race assumptions in library notes

Searched all 12 files for class names, class abilities, forms, mounts, mana, healing, pets, armour types, racials,
race names (EN and RU). Result: **no step note assumes a class**, and none assumes a race beyond the 8 filtered
steps. The hits are all neutral:

* `H/06:341` (gate `h39-level-mannoroc`): "the remaining turn-ins make 40 for Orgrimmar: training and riding at
  40" (class-neutral; true for classes with an Orgrimmar trainer, not for paladin and druid).
* `H/08:224`, `H/09:99`, `354`, `506`: "ride to ..." (assume a mount after 40; harmless).
* stealthed mobs, "Skip The Black Shield", NPC and quest names containing "Troll", "Scourge", "Moon".

### 6.5 Trainers by city (Horde-friendly class trainers in the DB)

| Class | Start-zone trainers | Orgrimmar | Thunder Bluff | Undercity | Elsewhere on the route |
|---|---|---|---|---|---|
| Warrior | Durotar 2 (Valley of Trials, Razor Hill), Mulgore 2, Tirisfal 2 (Deathknell, Brill), Zephras 3 | 3 | 3 | 3 | Stonard |
| Hunter | Durotar 2, Mulgore 2, Zephras 3 | 3 | 3 | - | Stonard, Grom'gol |
| Rogue | Durotar 2, Tirisfal 2, Zephras 3 | 3 | - | 3 | Booty Bay |
| Shaman | Durotar 2, Mulgore 3 (one on Skywatcher Plateau), Zephras 3 | 3 | 3 | - | Stonard |
| Mage | Durotar 2 (Valley of Trials, Sen'jin), Tirisfal 2 | 4 | 3 | 3 | - |
| Priest | Durotar 2, Tirisfal 2 | 2 | 3 | 3 | - |
| Warlock | Durotar 2, Tirisfal 2 | 3 | - | 3 | Stonard |
| Paladin | Tirisfal 3 (Deathknell, Brill, Bandarion Keep) | - | 1 (Pools of Vision) | 1 | - |
| Druid | Mulgore 3 (one on Skywatcher Plateau), Zephras 3 | - | 3 | - | Moonglade, Camp Mojache |

Zephras: one trainer per class in each of Thendal Grove, Shen'dar and Valanaar for warrior, hunter, rogue,
shaman, druid.

Class "scroll" quests of level 1-2 that confirm the combos: Durotar: orc 2383 warrior, 3087 hunter, 3088 rogue,
3089 shaman, 3090 warlock, 98576 mage (Forever-new); troll 3065 warrior, 3082 hunter, 3083 rogue, 3084 shaman,
3085 priest, 3086 mage, 98575 warlock (Forever-new). Mulgore: 3091 warrior, 3092 hunter, 3093 shaman, 3094
druid. Tirisfal: 3095 warrior, 3096 rogue, 3097 priest, 3098 mage, 3099 warlock, 98601 paladin. Zephras: 92532
warrior, 92482 hunter, 92483 rogue, 92484 shaman, 92485 druid.

### 6.6 City stops of the library and the level there

Harness, all 12 segments, Scourge WARRIOR from the Undead level-22 state, no class inserts ("before the step").
With class inserts that give XP the levels move by up to 0.2.

| City | Anchor (segment) | Level |
|---|---|---|
| Thunder Bluff | `h-22-tb-start` / `h-22-tb-fly` (`h-22`) | 22.06 |
| Orgrimmar | `h-22-org-fp` (`h-22`) | 22.06 |
| Undercity | arrival by zeppelin, `h-22-uc-fly` (`h-22`) | 22.06 |
| Thunder Bluff | `h-24-tb-hearth` (`h-22`), `h-24-tb-arrive` (`h-24`) | 24.83 |
| Thunder Bluff | `h-27-hearth-tb`, `h-27-tb-arrive` (`h-27`) | 27.31 |
| Thunder Bluff | `h-28-hearth-tb`, `h-28-tb-arrive` (`h-27`) | 28.35 |
| Thunder Bluff | `h-28-thunder-bluff` (`h-27`) | 28.75 |
| Thunder Bluff | `h-31-tb-hearth`, `h-31-tb-end` (`h-27`), `h-31-tb-fly` (`h-31`) | 30.91 - 31.01 |
| Orgrimmar | `h-31-org` (`h-31`) | 31.05 |
| Undercity | `h-31-uc-arrive` (`h-31`) | 31.16 |
| Undercity | `h34-fly-uc`, `h-34-uc-arrive`, `h34-faranell` (`h-34`) | 34.05 - 34.10 |
| Grom'gol, Booty Bay | `h-34-gromgol-arrive`, `h-34-booty-bay` (`h-34`) | 34.11 |
| Orgrimmar | `h-37-orgrimmar`, `h-37-org-arrive`, `h-37-orgrimmar-keldran` (`h-37`) | 36.06 |
| Orgrimmar | `h40-fly-org`, `h40-sethearth-org`, `h-40-org-arrive` (`h-37`) | 40.04 |
| Orgrimmar | `h41-hearth-org` (`h-41`) | 41.01 |
| Undercity | `h-41-uc-arrive`, `h41-sharlindra` (`h-41`) | 41.01 - 41.02 |
| Undercity | `h-44-uc-arrive` (`h-44`) | 44.02 |
| Stonard | `h-44-stonard-arrive`, `h-45-stonard-end` (`h-44`) | 44.03 - 44.20 |
| Camp Mojache | `h-48-mojache-arrive`, `h-50-mojache-end` (`h-46`) | 47.19 / 49.4 |
| Orgrimmar | `h50-fly-org`, `h-50-org-arrive` (`h-50`) | 49.40 |
| Undercity | `h-50-uc-arrive` (`h-50`) | 49.54 |
| Undercity | `h53-fly-uc` (`h-53`) | 52.57 |
| Orgrimmar | `h-53-org-arrive`, `h53-org-hearth` (`h-53`) | 52.70 - 52.73 |
| Orgrimmar | `h54-hearth-org` (`h-53`) | 53.05 |
| Orgrimmar | `h56-fly-org`, `h-56-org-arrive`, `h56-sethearth-org` (`h-56`) | 55.05 - 55.07 |
| Orgrimmar | `h-58-org-arrive` (`h-56`) | 57.21 |
| Undercity | `h-58-uc-arrive` (`h-56`) | 57.21 |
| Undercity | `h59-hearth-uc` (`h-56`) | 57.96 |
| end | `h-60-end` (Light's Hope Chapel; hearth = Undercity) | 60.00 |

Gaps a class agent must plan around: no Orgrimmar or Undercity stop between 22.06 and 31.05 (rogue, warlock:
Thunder Bluff has no trainer for them); no Orgrimmar or Thunder Bluff stop between 41.01 and 49.40 (hunter and
shaman: Stonard at 44; hunter also Grom'gol). `docs/routes/horde-22-60.md` section 10 lists all 364 explicit
library step ids.

---------------------------------------------------------------------------------------------------------------

## 7. The inserts

### 7.1 `FastesBoooy_UndeadPaladin/Inserts.lua` (11 `AddInsert`, 23 steps)

| Anchor | Side | Steps | What | Level |
|---|---|---|---|---|
| `h-22-uc-fly` | before | `pal-22-danitha` (optional) | start of the optional class chain at Bandarion Keep (91858) | 22.75 |
| `h-22-the-sepulcher-apothecary` | after | `pal-22-trevan`, `-baldren`, `-remains`, `-lumina-keep`, `-key`, `-escort-start`, `-escort`, `-lumina`, `-debt` (all optional) | chain 91859 -> 91860 -> 91861 -> 91862 -> 96204 -> 95034 (Sepulcher, Fenris Isle) | 22.8 |
| `h-27-tb-arrive` | after | `pal-train-26` | train at Alodan (Pools of Vision, where the anchor's NPC Zamah stands) | 27.57 |
| `h-31-tb-hearth` | after | `pal-train-30` | train 28 + 30 at Alodan | 30.91 |
| `h-34-uc-arrive` | after | `pal-train-34` | train 32 + 34 at Garen Largo (Undercity) | 34.10 |
| `h41-hearth-org` | after | `pal-axes` (optional, `manual`) | Two-Handed Axes at weapon master Hanashi (Orgrimmar, Valley of Honor) | 41.02 |
| `h-41-uc-arrive` | after | `pal-train-40`, `pal-40-riding` (`manual`), `pal-40-horse` (optional `vendor`), `pal-train-40-garen` (optional) | Brill: Shari Stilwell, riding at Velma Warnam, horse at Zachariah Post; optional Garen Largo | 41.02 |
| `h-44-uc-arrive` | after | `pal-train-44` | Garen Largo | 44.02 |
| `h53-fly-uc` | after | `pal-train-52` | Garen Largo, 46-52 | 52.57 |
| `h59-hearth-uc` | after | `pal-train-58` (optional) | Garen Largo | 57.96 |
| `h-60-end` | after | `pal-60-hearth`, `pal-train-60` | hearth to the Undercity, final training | 60 |

### 7.2 `FastesBoooy_SkyborneDruid/Inserts.lua` (17 `AddInsert`, 29 steps)

| Anchor | Side | Steps | What | Level |
|---|---|---|---|---|
| `h-22-tb-start` | before | `sd-bridge-fly-tb` | bridge: Bunthen Plainswind (druid-only flight) Moonglade -> Thunder Bluff, because the 1-22 route ends at Loganaar | 22.24 |
| `h-24-tb-arrive` | after | `dru-train-24` | Turak (Elder Rise) | 25.01 |
| `h-28-thunder-bluff` | before | `dru-train-28` | Turak, 26 + 28 | 28.81 |
| `h-31-tb-end` | after | `dru-train-30` | Turak: Travel Form | 31.01 |
| `h-33-tarrenmill-end` | after | `dru-train-32`, `dru-hearth-32` | Teleport: Moonglade from Tarren Mill, hearth back (the library binds Tarren Mill and leaves the stone unused for this) | 32.06 |
| `h38-hearth-shadowprey` | before | `dru-train-36` | Moonglade right before a library hearth | 37.69 |
| `h-40-org-arrive` | after | `dru-fly-tb-40`, `dru-train-40`, `dru-riding-path`, `dru-riding-skycutter`, `dru-riding`, `dru-riding-back`, `dru-riding-tb` (the five riding steps optional), `dru-fly-taurajo-40` | fly Thunder Bluff, Turak (Dire Bear Form), optional riding trip to Zephras Isle, fly Camp Taurajo (duplicates the library's next `fly`, which completes on the same landing) | 40.06 |
| `h44-hearth-gromgol` | before | `dru-train-44` | Moonglade before a library hearth | 44.52 |
| `h-50-mojache-end` | after | `dru-train-48` | Jannos Lighthoof, Camp Mojache | 49.40 |
| `h54-hearth-org` | before | `dru-accept-9063` (optional), `dru-train-52` | Moonglade before a library hearth; class quest 9063 | 53.06 |
| `h-53-torwa-pathfinder` | after | `dru-torwa-9063` (optional), `dru-torwa-9052`, `dru-bloodcap` (bg) | Torwa chain in Un'Goro | 53.15 |
| `h54-torwa-3` | before / after | `dru-gorishi-stings` / `dru-torwa-9051`, `dru-devilsaur` (bg) | Torwa chain | 53.43 |
| `h55-torwa-end` | after | `dru-torwa-end` | Torwa chain | 53.93 |
| `h56-hearth-gadgetzan` | before | `dru-train-54` | Moonglade before a library hearth | 55.04 |
| `h-58-org-arrive` | before | `dru-train-56` | Moonglade before a library hearth | 57.21 |
| `h-60-end` | after | `dru-train-60` | Moonglade | 60 |

All 28 anchors are explicit library ids. "Level" in both tables = the validator's level before the first
inserted step, main run of the full route (optional steps counted as done, which is why `pal-22-danitha` shows
22.75: the optional dungeon block before it is counted). `docs/routes/horde-22-60.md` section 10 has the same
table with older normal / worst-case numbers; some differ by up to 0.2 from today's run.

### 7.3 Class-generic patterns (templates for the other 7 classes)

1. **Trainer in a city the library already walks through.** `after <arrival or hearth step>`, one `train` step
   with `npc`, `at`, `spells`, a note with the walking directions and the talents. Examples: `pal-train-34`
   after `h-34-uc-arrive`, `pal-train-44` after `h-44-uc-arrive`, `dru-train-24` after `h-24-tb-arrive`,
   `dru-train-48` after `h-50-mojache-end`. Table 6.6 gives the stops and levels: Orgrimmar 22, 31, 36, 40, 41,
   49.4, 52.7, 53, 55, 57.2; Undercity 22, 31.2, 34, 41, 44, 49.5, 52.6, 57.2, 58, 60; Thunder Bluff 22, 24.8,
   27.3, 28.4, 28.8, 30.9; Stonard 44; Camp Mojache 47 / 49.4.
2. **Merge two training levels into one visit** when a stop is just short of a level (paladin 28 + 30, 32 + 34,
   46-52; druid 26 + 28, 34 + 36): the insert header tables in both files explain each choice by the validator's
   normal and worst-case level.
3. **Optional visit** when the worst-case level is below the trained level (`pal-train-58`, `optional = true`).
4. **Final visit** `after h-60-end` (both classes; the paladin adds a hearth).
5. **Weapon skill at a weapon master** (`pal-axes`, `manual`, optional): Hanashi and Sayoc in Orgrimmar (81.5,
   19.6), Ansekhwa in Thunder Bluff (40.9, 62.7), Archibald in the Undercity (57.3, 32.8).
6. **Class quest chain next to library steps**, stateful steps anchored `after` / `before` the library step at
   the same NPC or place (Torwa: four anchors; paladin chain: two anchors, all optional).
7. Class-only patterns that do not transfer: the druid's "Teleport: Moonglade right before a library hearth
   step" (6 inserts), the Bunthen flight, the bridge insert.
8. Rules both files follow (their headers, `UD/Ins:47-50`, `SD/Ins` header): no transient step in front of an
   accept at the same NPC within the look-ahead window; every insert follows a step the player has just done;
   inserts never use the hearthstone unless the library leaves it free.

### 7.4 Riding at 40

| Race | Trainer / vendor (DB) | Today | Natural anchor in the library |
|---|---|---|---|
| Undead | Velma Warnam 4773 "Undead Horse Riding Instructor" and Zachariah Post 4731, Brill (60.1, 52.6) | `pal-40-riding` (`manual`), `pal-40-horse` (optional `vendor`), after `h-41-uc-arrive` (41.0): Brill is 2 min from the zeppelin tower | same |
| Skyborne | Genn Fairweather 265756 "Stablemaster and Riding Trainer", Zephras Isle (53.8, 81.3), faction `AH` | `dru-riding-path`, `-skycutter`, `dru-riding` (`train`, validator WARN `train-not-class-trainer`), `-back`, `-tb`: all optional, after `h-40-org-arrive` (40.0), 15-20 min by skycutter from Skywatcher Plateau | same; needs "fly Thunder Bluff" first and "fly Camp Taurajo" after |
| Orc | Kildar 4752 "Wolf Riding Instructor" and Ogunaro Wolfrunner 3362, Orgrimmar (69.4, 13.1) | - | after `h-40-org-arrive` or `h41-hearth-org`, inside the city |
| Troll | Xar'Ti 7953 "Raptor Riding Trainer" and Zjolnir 7952, Sen'jin Village, Durotar (55.3, 75.5) | - | from the Orgrimmar stops at 40 / 41 (a run south through Durotar; `h41-hearth-org` is followed by the walk to the zeppelin tower) |
| Tauren | Kar Stormsinger 3690 "Kodo Riding Instructor" and Harb Clawhoof 3685, Bloodhoof Village, Mulgore (46.8, 62.0) | - | after `h-40-org-arrive`: the next library step flies to Camp Taurajo (`h-38-orgrimmar-flight-master`); Thunder Bluff is not visited after 31 |

How race-specific the existing steps are: the trainer, the place and the trip are race facts; the class leaks in
only through notes. `pal-40-riding`: "If the paladin trainer offered Summon Warhorse, you learned that and need
no riding". `dru-riding-path`: "+60 % against +40 % for Travel Form". `dru-riding-back`: fallback "cast Teleport:
Moonglade, and Bunthen Plainswind flies you to Thunder Bluff". The level-40 block of the druid interleaves class
and race: `dru-fly-tb-40` and `dru-train-40` (class), the five riding steps (race), `dru-fly-taurajo-40` (needed
by both). In `Races/Skyborne.lua` and `Races/Tauren.lua` the riding insert therefore needs its own fly steps,
and `Classes/Druid.lua` must anchor its level-40 training on a step that exists for both races whether or not
the player rides. The paladin's `pal-train-40` is at Shari Stilwell in Brill, next to the riding trainer, by
design.

---------------------------------------------------------------------------------------------------------------

## 8. Levels 12-15 and the merge level per race

### 8.1 What the two routes do

| | Undead | Skyborne |
|---|---|---|
| Path | `ud-03`: Undercity -> on foot to Ivar Patch -> Sepulcher loops -> hearth Brill (440 -> 441) -> Undercity (turn-ins, train 14) -> zeppelin | `sd-03`: plateau -> Thunder Bluff -> fly Orgrimmar (bind, city quests, Thrall) -> zeppelin -> Brill (96895 chain, 445) -> Undercity flight point -> Silverpine loops -> fly Undercity -> Teleport: Moonglade -> hearth Orgrimmar |
| Steps | 55 | 73 (24 Thunder Bluff / Orgrimmar, 46 Tirisfal / Silverpine / Undercity, 3 Moonglade) |
| Level | 12.78 -> 14.56 | 13.32 -> 15.59 (13.87 at the zeppelin) |
| Quest XP / kill XP | 16 145 / 4 691 | 22 965 / 6 288 (Orgrimmar + Thrall part: 6 770 / 0) |
| Travel steps | 7 go, 1 hearth, 1 zeppelin leg | 9 go, 2 fly, 1 hearth, 1 zeppelin leg (the way back is teleport + hearth) |
| Grind | 0 | 0 |

### 8.2 "Barrens from 12" measured

Scratch runs that remove Silverpine (Undead: all of `ud-03` except the last three steps; Skyborne: `sd-03`
steps 25-70; in both the turn-in of 1358 is removed too).

| Variant | Arrival in the Barrens | End of 04 | Grind kills to 22 (worst) | Where |
|---|---|---|---|---|
| Undead paladin, as is | 14.56 | 17.99 | **74 (107)** | `ud05-lvl-grind` |
| Undead paladin, no Silverpine | 12.78 | 16.88 | **191 (232)** | `ud05-lvl-pre20` 77 (109), `ud05-lvl-21` 8 (17), `ud05-lvl-grind` 106 (106) |
| Undead without class quests, as is | 14.05 | 17.64 | 106 (107) | |
| Skyborne druid, as is | 15.59 | 19.02 | **0 (40)** | |
| Skyborne druid, no Silverpine | 13.91 | 17.97 | **77 (163)** | `sd05-level-22` |
| Undead without class quests on `sd-04/05` | 14.05 | 18.04 | 96 (172) | `sd05-level-22` |

Silverpine is worth 20 836 XP to the Undead in 55 steps (52 of them inside the loop) and takes 117 grind kills
(16 700 XP at level 19-21) off the route; for the Skyborne it takes 77 (worst case 123) kills off. With the
validator's criteria (grind kills at the gates, worst case) the Silverpine loop wins for both races. The kills it
replaces would be done 2 to 3 levels below the Barrens quest mobs (the Crossroads quests fight level 12-16 mobs;
Baron Longshore, Barak, Kreenig are 15-16), which the validator does not even count as a cost.

### 8.3 Is there enough quest XP elsewhere to replace it?

Quest XP available by zone (DB; class quests excluded; "est." = quests without XP in the DB, estimated by the
median of their level):

| Zone, race, levels | Quests | Known XP | Unknown (est.) |
|---|---|---|---|
| Tirisfal Glades, Undead, 1-13 | 61 | 21 345 | 19 (+9 525) |
| Zephras Isle, Skyborne, 1-13 | 86 | 0 | 86 (+50 065) |
| Durotar, Orc or Troll, 1-13 | 56 | 20 195 | 19 (+10 835) |
| Mulgore, Tauren, 1-13 | 49 | 16 250 | 17 (+9 290) |
| Orgrimmar, 1-16 | 8 | 2 460 | 5 (+5 250) |
| Thunder Bluff, 1-16 | 5 | 2 720 | 1 (+420) |
| Silverpine Forest, 10-16 | 28 | 16 875 | 4 (+2 655) |
| The Barrens, 10-16 | 38 | 30 480 | 1 (+1 050) |
| The Barrens, 17-22 | 36 | 37 590 | 8 (+9 560) |
| Stonetalon Mountains, 15-24 | 16 | 17 970 | 1 (+1 950) |

The two Barrens segments already take 39-44k (04) and 48-51k (05) quest XP, that is nearly everything soloable in
the Barrens, Stonetalon up to 22 and west Ashenvale (the skipped rest: 3921 / 3922, 876 -> 1060, 868, 1068,
6421 / 6481, 822, dungeon and elite quests; `UD/04`, `UD/05`, `SD/04`, `SD/05` headers). There is no unused
20k XP block in Kalimdor at 12-15. `SD/03:8-12` states the same conclusion ("without Silverpine the route is
~18k XP short at 22").

Durotar offers about as much as Tirisfal (31k incl. estimates against 30.9k), so an Orc or Troll should leave
Durotar near 12 to 12.5, like the Undead leave Tirisfal at 12.1 (without class quests) to 12.8. Mulgore offers
about 25.5k: a Tauren leaves nearer 11.5 to 12.

### 8.4 Recommendation: merge level per race

| Race | Merge at | Level there | Evidence |
|---|---|---|---|
| Undead | first step of `h-13-silverpine` | 12.1 (no class quests) to 12.8 (paladin) | Silverpine is on foot from the Undercity; -117 grind kills |
| Skyborne | the Tirisfal "visitor" block, then `h-13-silverpine` | 13.9 at the zeppelin | -77 grind kills (worst -123); the way there (Thunder Bluff -> Orgrimmar -> zeppelin) is needed anyway to bind in Orgrimmar and reach the Barrens from the north |
| Orc, Troll | the same "visitor" block | ~12 to 12.5 expected | Orgrimmar and the zeppelin tower are at the north end of Durotar; without Silverpine they would enter the Barrens 2 to 2.5 levels under the Undead arrival, i.e. worse than the 191-kill variant above; the 5 Orgrimmar city quests (est. 5 250 XP) are on the way |
| Tauren | open: measure two variants with the harness | ~11.5 to 12 | (T1) Thunder Bluff -> Orgrimmar (flight, if offered without the flight point; otherwise a run through the whole Barrens) -> zeppelin -> Silverpine -> back, like the Skyborne; (T2) Camp Taurajo -> Crossroads and the Barrens from 12 with a grind estimated at 150+ kills by 22 (more than the Undead "no Silverpine" case, since Mulgore gives less XP than Tirisfal). (T1) depends on the open game fact of summary point 9 |

For every race the second merge (the start of `h-15-barrens`) is the Durotar side: zeppelin tower or Orgrimmar
gate -> Razor Hill (840) -> Far Watch Post (842) -> Crossroads. A direct "Barrens from 12" shared segment for all
races is not recommended: +77 to +117 grind kills on the two measured routes, more for the races with thinner
start zones, and no travel saved for Undead, Orc, Troll and Skyborne.

Target states for the path agents (so that they do not depend on each other): arrive at the "visitor" block or at
`h-13-silverpine` with level >= 12.0 (421 "Prove Your Worth" needs 12 at the first Sepulcher visit; 96895 needs
10, 445 needs 9), and at `h-15-barrens` between 14.0 and 15.6. The unified 15-22 gates must hold for 14.05.

---------------------------------------------------------------------------------------------------------------

## 9. Explicit ids: anchors that are missing in 1-22

Counts are in table 1.1. Below: every hub visit of 1-22 (consecutive steps at one hub) and whether it has an
explicit id. "train" marks ids that are class steps and will move out, so they cannot serve as anchors.

### 9.1 Hub visits without any explicit id (54 of 136)

| Segment | Hub | Steps | Level about | Note |
|---|---|---|---|---|
| `ud-01` | Deathknell | #2; #22 - #23 | 1; 4.5 | #22 is the Aramis turn-in (mixed class / generic) |
| `ud-02` | Brill entrance | #4 - #5 | 6 | |
| `ud-02` | Brill, 3rd visit | #57 - #64 | 9.5 | |
| `ud-02` | Brill, 5th visit | #80 - #85 | 11.8 | |
| `ud-03` | The Sepulcher | #19; #29 - #32; #34; #38 - #41 | 13 - 14.4 | the first visit #9 - #16 has only `ud03-fp-sepulcher` (#16) |
| `ud-04` | The Crossroads | #15 - #17; #46 - #47 | 15 - 16.5 | |
| `ud-04` | Ratchet | #32 - #35 | 15.6 | |
| `ud-04` | Regthar | #39; #45 | 16 | |
| `ud-05` | Ratchet | #13 | 18.2 | |
| `ud-05` | Camp Taurajo | #22 - #24; #26 | 19 | |
| `ud-05` | Regthar | #29; #31 | 19.5 | |
| `ud-05` | Stonetalon border | #32; #34; #38; #59 | 19.5 - 21 | |
| `ud-05` | Ziz Fizziks | #41; #45; #65 | 20 - 21 | |
| `ud-05` | Zoram'gar | #78 - #79 | 21 | |
| `sd-01` | Thendal camp | #34 - #35 | 5 | |
| `sd-01` | Shen'dar | #45 | 6 | |
| `sd-02` | Valanaar, arrival | #2 | 10 | `sd02-sethearth` (#4) is two steps later, outside the hub radius used here |
| `sd-03` | Tirisfal zeppelin tower, Brill | #26; #27 - #28 | 13.9 | |
| `sd-03` | The Sepulcher | #38 - #41; #44; #49 - #51; #53 | 14.2 - 15.3 | the last visit #61 - #65 has `sd03-fp-sepulcher` |
| `sd-04` | Razor Hill, Far Watch Post | #2; #3 | 15.6 | |
| `sd-04` | The Crossroads | #14; #35 - #36; #70 | 15.8 - 18 | |
| `sd-04` | Ratchet | #30 - #33 | 16.5 | |
| `sd-04` | Regthar | #37; #41; #94; #97 | 17 - 18.8 | |
| `sd-05` | Stonetalon border | #2; #17 - #18 | 19 - 19.6 | #18 is where the druid teleports to train |
| `sd-05` | Ziz Fizziks | #11; #14; #70 - #71 | 19.3 - 21.8 | |
| `sd-05` | Ratchet | #26 - #29 | 20.5 | |
| `sd-05` | Camp Taurajo | #41 | 21 | |
| `sd-05` | Sun Rock Retreat | #66 - #67 | 21.6 | |

### 9.2 City and trainer-hub arrivals whose first step has no id, or whose only ids are class steps

These are the places where the other classes will train, so they matter most.

| Segment | Hub | Steps | First step | Ids in the visit | Problem |
|---|---|---|---|---|---|
| `ud-01` | Deathknell church, level-4 visit | #12 - #18 | `ud01-vendor` | `ud01-vendor`, `ud01-90902`, `ud01-91209`, `ud01-train-4` | #13 (generic turn-in 3901 / 376, accept 6395) is anon; the other ids are class steps |
| `ud-01` | Deathknell, later visits | #26 - #28 | anon | `ud01-381` | |
| `ud-02` | Brill, 2nd visit (level 8) | #30 - #41 | `ud02-hearth-1` | `ud02-hearth-1`, `ud02-train-8` (train) | the 11 quest steps are anon |
| `ud-02` | Brill, 4th visit (level 10) | #67 - #70 | anon | `ud02-91282`, `ud02-train-10` (both class) | the generic `level = 10` gate has no id of its own |
| `ud-02` | Brill after Bandarion Keep (level 12) | #113 - #115 | `ud02-hearth-2` | + `ud02-train-12` (train) | fine after the split |
| `ud-02` | Bandarion Keep | #89 - #112 | `ud02-91285` | all ids are class steps (`ud02-91285`, `-smasher`, `-91294`, `-91317`, `-91316`, `-95803`, `-xp-12`, `-94427`) | no generic anchor at the keep |
| `ud-02` | Undercity | #117 - #121 | anon | `ud02-fp-uc`, `ud02-end` (class) | the end id must move to a generic step |
| `ud-03` | Undercity (level 14.5) | #45 - #52 | anon | `ud03-train-14` (train) | no generic anchor in the Undercity |
| `ud-04` | The Crossroads, arrival | #5 - #12 | anon | `ud04-xroads-fp`, `ud04-sethearth` | usable |
| `ud-04` | Ratchet, arrival | #22 - #27 | anon | `ud04-ratchet-fp` | usable |
| `ud-05` | Thunder Bluff at 18 | #4 - #8 | anon | `ud05-train-18` (train), `ud05-fp-tb` | the Zamah step #6 is anon |
| `ud-05` | Thunder Bluff at 20 | #50 - #53 | `ud05-fly-tb` | `ud05-train-20` (train), `ud05-sethearth-tb` | usable |
| `ud-05` | Thunder Bluff at 22 | #85 - #91 | `ud05-hearth-tb` | `ud05-end` (train) | the end id must move |
| `ud-05` | Sun Rock Retreat | #46 - #49 | anon | `ud05-lvl-20`, `ud05-fp-sunrock` | usable |
| `ud-05` | Zoram'gar | #74 - #76; #83 - #84 | anon | `ud05-fp-zoram`; `ud05-lvl-22` | usable |
| `sd-01` | Thendal camp, level 2-3 | #6 - #14 | anon | `sd01-92485`, `sd01-train-1` (both class) | **#10 (Rorian, where every class gets its class quest) is anon** |
| `sd-01` | Thendal camp, level 4 | #27 - #30 | anon | `sd01-train-4` (train) | |
| `sd-01` | Shen'dar, arrival (level 6) | #40 - #43, #47 - #52 | anon | `sd01-innkeeper`, `sd01-train-6` (train) | |
| `sd-01` | Shen'dar, level 8 | #74 - #81 | anon | `sd01-train-8` (train) | |
| `sd-01` | Shen'dar, 2nd visit | #59 - #64 | anon | `sd01-mark` | |
| `sd-02` | Valanaar, level 10 | #24 - #26 | `sd02-bear-accept` | class ids only | the generic gate `sd02-level-10` (#23) is at the orchard, not in Valanaar |
| `sd-02` | Valanaar, level 12 | #58 - #66 | `sd02-hearth` | + `sd02-train-12` (train) | usable |
| `sd-02` | Skywatcher Plateau | #68 - #71 | `sd02-plateau` | `sd02-train-12-plateau` (train), `sd02-end` | usable |
| `sd-03` | Thunder Bluff (13) | #2 - #8 | `sd03-spirit` | `sd03-train-tb`, `sd03-child` (class), `sd03-fp-tb` | usable |
| `sd-03` | Orgrimmar (13.4) | #9 - #24 | `sd03-fly-org` | `sd03-fp-org`, `sd03-sethearth` | usable; the Thrall step #23 is anon |
| `sd-03` | Undercity | #32 - #33; #66 - #70 | `sd03-fp-uc`; `sd03-fly-uc` | | usable |
| `sd-04` | Orgrimmar | #1 | `sd04-start` | | usable |
| `sd-04` | The Crossroads, arrival | #4 - #10 | `sd04-sethearth-xroads` | + `sd04-fp-xroads` | usable; the Thork step #8 (98024) is anon |
| `sd-05` | Thunder Bluff (21) | #45 - #53; #60 - #62 | `sd05-fly-tb`; `sd05-hearth-tb` (class) | `sd05-sethearth-tb`, `sd05-cat-start`, `sd05-catform`, `sd05-train-20` | the Zamah step #53 and the Elder Rise steps are anon |
| `sd-05` | end | #85 - #87 | anon | `sd05-level-22`, `sd05-train-22` (train) | the segment ends on a class step |

Hub visits that are fine today (first step has an id, generic): `ud-01` #4 `ud01-364` and #30 `ud01-382`;
`ud-02` #9 `ud02-zygand-1` (Brill 1); `ud-03` #42 `ud03-hearth`, #54 `ud03-zeppelin`, #55 `ud03-end`; `ud-04` #1
`ud04-org-gate`, #3 `ud04-840`, #4 `ud04-842`, #36 `ud04-fly-xroads`, #68 `ud04-hearth`, #73 `ud04-fly-ratchet`,
#89 `ud04-taurajo-fp`, #91 `ud04-fly-xroads-2`; `ud-05` #1 `ud05-fly-taurajo`, #9 `ud05-fly-ratchet`, #17
`ud05-hearth-taurajo`, #27 `ud05-fly-xr`, #54 `ud05-fly-ratchet-2`, #58 `ud05-fly-xr-2`; `sd-01` #1 `sd01-start`,
#22 `sd01-hearth-3`; `sd-03` #25 `sd03-zeppelin`, #73 `sd03-hearth`; `sd-04` #20 `sd04-fp-ratchet`, #63
`sd04-hearth`, #71 `sd04-fly-ratchet`, #84 `sd04-sethearth-taurajo`, #88 `sd04-fly-xroads`; `sd-05` #20
`sd05-hearth-taurajo`, #30 `sd05-fly-xroads`, #35 `sd05-fly-taurajo`, #63 `sd05-fly-sunrock`, #79
`sd05-fp-zoramgar`.

### 9.3 Anchor ids the class phase will need (minimum set, to be created by the path agents)

One generic step with an explicit id at each of these moments, placed after the generic quest steps of the visit
(so that a class `train` insert `after` it obeys the look-ahead rule):

* Deathknell: level 1-2 visit (today `ud01-364`), level 4 visit (#13), level 5 visit (`ud01-381` / `ud01-382`).
* Brill: visits at 6 (`ud02-sethearth`), 8, 10 (with the generic gate), 12 (`ud02-hearth-2` block); Bandarion
  Keep arrival; Undercity at 12.7 and 14.5.
* Zephras: Thendal camp at 2-3 (Rorian step), at 4; Shen'dar at 6 and 8; Valanaar at 10 and 12; Skywatcher
  Plateau; Thunder Bluff at 13; Orgrimmar at 13.4.
* Durotar and Mulgore: the same pattern (level 1-2, 4, 6, 8, 10, 12 visits; Orgrimmar / Thunder Bluff arrival).
* Shared 13-22: Undercity end of Silverpine (~14.5); Orgrimmar gate / start of the Barrens (~14-15.6); every
  Crossroads flight step (a class without a Thunder Bluff trainer needs "fly Orgrimmar and back" there);
  Thunder Bluff 1, 2, 3 (18, 20, 22); the final hearth step (the druid's "teleport before a hearth" pattern).
* 22-60: the 364 existing ids are enough for the two existing classes; table 6.6 lists the city anchors.

---------------------------------------------------------------------------------------------------------------

## 10. Notes for the plan

1. **Generic steps that need a split** (class action + generic action in one step): `ud-01` #4, #15, #22; `ud-02`
   #69, #95, #103, #106; `sd-01` #10; `sd-04` #8 (racial), #61 (gate with a class reason). After the split the
   class part is an insert `after` the generic step at the same NPC; the engine automation then takes both at
   one visit.
2. **Gates must be class-neutral.** `ud01-xp-4` (3 + 64 %), `ud02-train-10` (`level = 10` merged with `train`),
   `ud02-xp-12`, `sd02-level-10`, `sd-04` #61 (`level = 16`), `ud05-lvl-pre20`, `ud05-lvl-20`, `sd05-level-20`,
   `ud05-lvl-22`, `sd05-level-22` exist because of training or class quests at that level. Keep the generic ones
   as plain "level N before the city" gates and let the class file add its own gate when a class quest needs one.
3. **Segment-end ids** `ud02-end`, `ud05-end`, `sd05-train-22` are class steps. `--until <segment>` and the
   harness chain rely on segment boundaries, not on these ids, but docs and inserts that name them must change.
4. **Per-class rewards**: 13 `reward` fields in `SD/01` / `SD/02` and about 25 reward notes in `UD/01` .. `UD/05`
   ("(mail)", "2H mace", "if you can use two-handed swords"). See core.md 5.7 for the two mechanisms.
5. **Notes that name class abilities** on generic steps (to reword): `UD/01:99`, `137`; `UD/02:85`, `200`;
   `UD/05:200`, `360`, `434`; `SD/01:39`, `360`; `SD/02:315`; `SD/05:457`, `541`; plus the hearth / Moonglade
   remarks `SD/03:107`, `SD/04:35`, `55`, `346`, `SD/05:39`, `171`, `320`.
6. **Generic quests whose NPC is a class trainer** (the class `train` insert of that class must come after them,
   and no other class may be sent to "train" there): 98389 (Aramis Hammerhand), 99144 turn-in (Shari Stilwell),
   99152 (Hilda the Breaker), 94484 accept and 94491 turn-in (Lotheluum Starbreeze), 1489 / 1490 next to the
   druid trainers on Elder Rise.
7. **Quests with a race limit inside otherwise shared content**: 6321, 6322, 6323 (Undead); 92598, 95350, 98024,
   93739 (Skyborne Horde); 92474, 98341, 98404, 98738 (both Skyborne factions); 94911, 94913 (Skyborne Horde
   druid); 98340, 98362 (druid, Skyborne Horde + Tauren); 27 "A Lesson to Learn" (Tauren druid, Aquatic Form).
8. **A harness start state per merge point** makes the path agents independent: the files of section 5 can be
   regenerated with the commands at the top; for Orc / Troll / Tauren a synthetic state (level 12.0 to 12.5,
   empty log, hearth and flight points of the race) is enough to validate the shared 13-22 segments before
   Durotar and Mulgore exist. The harness today refuses a module that registers routes (core.md 0.1).
9. **User-visible strings with "Horde" / "Орда"** in the route modules: `Route.lua:10` of both modules (titles
   "... (Орда) 1-60" / "... (Horde) 1-60") and the descriptions (lines 12-19), the three TOC `## Title` /
   `## Notes` lines ("FastesBoooy: Horde 22-60", "Undead Paladin (Horde)", "Skyborne (Windshaper) Druid,
   Horde"), and the note of `ud05-end` (`UD/05:465`, "the shared Horde route").
