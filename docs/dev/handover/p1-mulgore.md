# Hand-over P1, Mulgore agent: the Tauren start zone

Phase P1 of `docs/dev/PLAN.md` (D.3, right column; B.1, B.2, B.8, C.2, C.3). Nothing was committed (the
orchestrator commits). `G` = `addons/FastesBoooy_Guides`. FAST MODE: only the acceptance commands of D.3 were
run; `make` targets were not run.

Files changed (all owned by this column): `G/Segments/Mulgore/01_CampNarache.lua`, `02_Mulgore.lua`,
`03_BarrensCrossing.lua`, this file. Not created: `tools/overrides/mulgore.lua` (nothing to override). The last
file announces `ns.startZones.Mulgore = { "mul-01-camp-narache", "mul-02-mulgore", "mul-03-barrens-crossing" }`
(no `only`): the four routes `tauren-druid`, `tauren-hunter`, `tauren-shaman`, `tauren-warrior` are registered.

## 1. The zone

| Segment | Steps | Levels (base) | Content |
|---|---|---|---|
| `mul-01-camp-narache` | 21 | 1.00 -> 6.03 | Camp Narache, Red Cloud Mesa: 747, 752 > 753 > 755 > 757, 750 > 780, 3376, 781, 95805, 1656; out: 763, 96659 |
| `mul-02-mulgore` | 74 | 6.03 -> 11.46 | Kaga's camp (96659 > 96605 > 96661); Bloodhoof Village seven times (the Thunderhorn chain 748 > 754 > 756 > 758 > 759 > 760 returns to Mull every time) with loops west, south-east, centre/east (Venture Co. mine, Galak), north-west, north (Red Rocks, hearth back); Thunder Bluff (775, 98430, 99082 > 776, flight point); Wildmane well and Arra'chea; Mull (760 > 98435) on the way out |
| `mul-03-barrens-crossing` | 17 | 11.46 -> 12.00 | Camp Taurajo (flight point, 854) > Crossroads (854; flight chain 6361 > 6364 with a flight to Thunder Bluff and back: 776, 861 > 860, 98435 > 886 turned in there; flight point) > 860, 886 > Far Watch Post > Orgrimmar gate |

All coordinates come from the DB snapshot (own lua5.1 scripts: NPC / object spawns, quest triggers, 5 % grid
clusters of the objective mobs); the Thunder Bluff lift (`1456: 31.78, 65.92`), the Mulgore road exit
(`1412: 64.34, 63.53`) and the Orgrimmar gate (`1454: 48.97, 92.84`) are the points the shared path already uses.

## 2. Acceptance (D.3) — commands and results

`<F>` = `--skip 'Segments/Durotar/*' --skip 'Classes/*' --own 'Segments/Mulgore/*'`.

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Segments/Mulgore` | 0 warnings / 0 errors in 3 files |
| `validate_routes.lua --harness $G --segments mul-01-camp-narache,mul-02-mulgore,mul-03-barrens-crossing --profile race=Tauren,class=WARRIOR,faction=Horde <F> --write-state $SCRATCH/tauren.json` | exit 0; 0 ERROR, 0 WARN, 39 INFO; end 12.00 (optimistic 12.77); quest XP 29,660 (15 quests estimated, 29.3 %); kill XP 14,313; grind 1 kill (worst 1) |
| `simulate_routes.lua --harness ... (same segments and profile) --skip 'Segments/Durotar/*' --skip 'Classes/*'` | `OK`, 112 steps, 56 accepted / 56 turned in, **no warning** |
| `validate_routes.lua -q --strict --end-level --summary --grind-until h-18-stonetalon-ashenvale --route 'tauren-*' <F> $G` | **exit 0**; 0 ERROR; 0 own WARN; 8 foreign WARN (section 5); 64 accepted |
| `validate_routes.lua --route tauren-warrior --levels <F> $G` | exit 0 (table in section 3) |
| `simulate_routes.lua --route tauren-warrior --skip 'Segments/Durotar/*' --skip 'Classes/*' $G` | `OK`, 1675 steps, 702 / 702, level 60, cold start finished, no warning |
| `simulate_routes.lua --route tauren-hunter ...` (same) | `OK`, same numbers, no warning |
| `GUIDES_SKIP='Segments/Durotar/*,Classes/*' GUIDES_OWN='Segments/Mulgore/*' busted tests/spec/guides_layout_spec.lua` | 22 successes / 0 failures / 0 errors |

`--summary` lines (route, profile, errors, warnings, accepted, foreign, end normal, end worst, grind kills
normal / worst, grind kills up to the end of `h-18` normal / worst):

```
tauren-druid	Tauren DRUID Horde	0	0	16	2	60.00	60.00	4965	6197	30	127
tauren-hunter	Tauren HUNTER Horde	0	0	16	2	60.00	60.00	4965	6197	30	127
tauren-shaman	Tauren SHAMAN Horde	0	0	16	2	60.00	60.00	4965	6197	30	127
tauren-warrior	Tauren WARRIOR Horde	0	0	16	2	60.00	60.00	4965	6197	30	127
```

(The F2b synthetic Tauren state gave 38 / 138 up to the end of `h-18`; the real zone hands over at 12.00 instead
of 11.80.)

### Hand-over contract (B.2)

| Contract item | State written by the harness run |
|---|---|
| at the Orgrimmar gate | `at = { 1454, 48.97, 92.84 }` |
| level >= 11.8 base | **12.00** (normal = worst: the zone has no optional step) |
| flight points Thunder Bluff, Camp Taurajo, The Crossroads | exactly these three |
| 854 / 860 / 886 turned in at the Crossroads, 861 before them in Thunder Bluff | yes (854 at Thork on arrival, 861 > 860 at Melor during the flight chain, 860 + 886 at `mul03-xroads`) |
| hearth Bloodhoof Village | yes (used once, at Red Rocks; `hearthAt 1412: 45.93, 64.16`) |
| quest log | empty |
| `done` vs `tests/fixtures/validator/guides_state_tauren_11.json` | + 6361, 6362, 6363, 6364 (flight chain); - 98427 (elite key, skipped) |

`h13-lvl-12` row of the gate table (normal / worst / +15 % / worst +15 %): **0 / 0 / 0 / 0** (limit 10 / 25).

### Per-segment table of the base route (`tauren-warrior --levels <F>`; all four Tauren routes are identical without class files)

| Segment | Levels | quest XP | kill XP | grind XP | grind kills (normal / worst) |
|---|---|---|---|---|---|
| `mul-01-camp-narache` | 1.00 -> 6.03 | 3,295 | 4,338 | 60 | 1 / 1 |
| `mul-02-mulgore` | 6.03 -> 11.46 | 21,555 | 9,975 | 0 | 0 / 0 |
| `mul-03-barrens-crossing` | 11.46 -> 12.00 | 4,810 | 0 | 0 | 0 / 0 |
| `h-12-orgrimmar-tirisfal` | 12.00 -> 12.96 | 6,630 | 2,992 | 0 | 0 / 0 |
| `h-13-silverpine` | 12.96 -> 14.54 | 14,155 | 4,631 | 0 | 0 / 0 |
| `h-15-barrens` | 14.54 -> 18.09 | 41,445 | 14,376 | 0 | 0 / 0 |
| `h-18-stonetalon-ashenvale` | 18.09 -> 22.04 | 51,790 | 32,394 | 4,350 | 29 / 126 |
| `h-22-hillsbrad` | 22.04 -> 24.82 | 61,855 | 19,595 | 0 | 0 / 51 |

Gates of 12-22 for the Tauren base: `h13-lvl-12` 0 / 0, `h13-lvl-14` 0 / 0, `h18-lvl-18` 0 / 26,
`h18-lvl-20` 0 / 0, `h18-lvl-21` 0 / 0, `h18-lvl-22` 29 / 100.

## 3. Anchors and levels (base profile, level before the step; `--levels`)

| Anchor | Step | Level | Use (C.2) |
|---|---|---|---|
| `mul01-hunt` | turn in 747 at Grull Hawkwind, accept 750 (last step of the first camp visit) | 3.02 | class letter (3091-3094), first training |
| `mul01-lvl-4` | gate `level = 4` (new, see deviation 5) | 3.96 | - |
| `mul01-ravine` | camp visit 2: turn in 750, accept 780 + 3376 (Grull, Brave Windfeather), right before the ravine | 4.00 | training at 4; shaman 1519 |
| `mul01-leave` | last step of `mul-01`: 757 + 781 in, 763 + 96659 out at Chief Hawkwind | 5.74 (6.03 after it) | training at 6; shaman 1520 > 1521 |
| `mul02-lvl-6` | gate `level = 6` at Kaga's camp, before the village | 6.33 | - |
| `mul02-bh-1` | Bloodhoof visit 1: accept 761 at Harken (next to the druid / shaman trainers and Mull; Krang 70 yd) | 6.61 | training at 6 |
| `mul02-bh-2` | visit 2: turn in 761 at Harken | 7.94 (8.07 after it) | training at 8 |
| `mul02-bh-3` | visit 3: 754 > 756 at Mull | 8.79 | training |
| `mul02-lvl-10` | gate `level = 10` east of the village, after Morin | 10.05 | - |
| `mul02-bh-4` | visit 4: 756 > 758 at Mull | 10.14 | training at 10; level-10 class quests (hunter 6061 > 6087 > 6088, shaman 2984, warrior 1505, druid 5928) |
| `mul02-bh-5` | visit 5: accept 861 at Skorn Whitecloud | 10.56 | training |
| `mul02-bh-6` | visit 6 (after the hearth): 759 > 760 at Mull | 11.02 | training |
| `mul02-tb` | Thunder Bluff 1: Cairne, 775 / 98430 / 99082 in, 776 out | 11.11 | city trainers, weapon master, druid 5922, hunter 6089 |
| `mul02-end` | last step of `mul-02`: Mull, 760 > 98435 (Bloodhoof visit 7, on the way out) | 11.34 | - |
| `mul03-taurajo` | `fp` Camp Taurajo | 11.46 | druid 6002 (Lunaclaw) |
| `mul03-cairne` | Thunder Bluff 2 (flight chain): turn in 776 at Cairne | 11.55 | city trainers (level 12 is not reached there: 11.69 after it) |
| `mul03-xroads` | the last Crossroads turn-ins: 860 (Sergra) + 886 (Tonga) | 11.98 | - |
| `mul03-far-watch` | `go` Far Watch Post | 12.00 | warrior 1498 (Uzzek), shaman (Kranal Fiss 640 yd west) |
| `mul03-org-gate` | last step of `mul-03` | 12.00 | - |

Other ids a class agent may want (all explicit): `mul02-inn` (sethearth, 6.33), `mul02-fp-tb` (11.31),
`mul03-fp-xroads` (fp + 6361 > 6362 at Devrak, 11.48), `mul03-fly-tb`, `mul03-ahanu`, `mul03-melor` (Hunter Rise,
11.69: hunter / warrior trainers), `mul03-hamuul` (Elder Rise, 11.79: druid trainers), `mul03-tal` (11.84),
`mul03-fly-xroads`, `mul03-jahan-2`. Every step of the three segments has an explicit id (`mul01-` / `mul02-` /
`mul03-`); all 112 ids are new.

Training at 12 for Tauren: the first visit at level 12 or more is Orgrimmar (`h12-org-end`, 12.52 base).

## 4. Deviations from the plan

1. **Thunder Bluff is visited twice, the Tauren flight chain 6361-6364 is mandatory and not `optional`.** B.2
   names it an optional fall-back at `mul03-xroads`. Without it the zone handed over at 11.37 (contract 11.8).
   The chain's flight to Thunder Bluff also carries the turn-ins of 776 (1,250 XP; Arra'chea lies on the way
   from Thunder Bluff to the Wildmane well), 98435 and 861 > 860 / 886: about 3,600 XP for two flights and
   three short walks in the city, under the cost rule (B.8). It is mandatory because the Crossroads flight point
   is merged into its Devrak step (look-ahead rule: `fp` and the 6361 / 6362 quests at the same NPC). The first
   Thunder Bluff visit is short (lift, Cairne, Tal). Flight chain cross-checked: the Crossroads flight point must
   be known before the return flight ([warcraft.wiki.gg: Return to Jahan](https://warcraft.wiki.gg/wiki/Return_to_Jahan),
   [classicdb 6364](https://classicdb.ch/?quest=6364)) — it is learned at `mul03-fp-xroads` before the flight.
2. **Hub order differs from the draft** (`startzones.md` 5.2): seven Bloodhoof visits instead of five (the
   Thunderhorn chain forces a Mull visit after each of its six steps), `mul02-end` is in Bloodhoof (visit 7, on
   the road from Thunder Bluff to the Barrens), not in Thunder Bluff; the anchors are `mul02-bh-1 .. 6` with the
   levels of section 3. `mul02-taurajo` of the draft is `mul03-taurajo` (as in C.2).
3. **The walk from Far Watch Post does not pass Razor Hill** (B.1 / B.2 name it): from the bridge the way north
   along the river past Thunder Ridge is about 800 yd shorter, and nothing at Razor Hill is open to a Tauren
   there. The step is a single `go` to the gate; `-- CONFIRM` the terrain.
4. **Skipped** (draft content): 98427 (level-12 elite, second Morin trip), 744 (not needed: `h13-lvl-12` 0
   kills). 98435 is done (via the flight chain), 776 too.
5. **Gates**: `mul01-lvl-4` (trainer-hub gate, 3.96 base, 1 kill), `mul02-lvl-6` (746 needs 6; 0 kills),
   `mul02-lvl-10` (861 needs 10, training at 10; 0 kills). The two low ones also remove the simulator's "would not
   be offered" warnings (the simulator credits quest XP only: 3376 needs 3, 96659 needs 4, 743 needs 5, 746
   needs 6). No gate at `mul03-cairne` (11.55, more than 0.4 under 12).

## 5. Foreign warnings, overrides, `-- CONFIRM`, place names

* **Foreign WARN** (8 = 2 per Tauren route): `h15-xr-arrive` (`Segments/Shared/15_Barrens.lua`)
  `db-override-unverified`, accept 844 after 854 / 861 (E.21). Needs `ok = "db-override-unverified"` with its
  `-- CONFIRM` on that step now that a Tauren route exists; **without it the full `--strict` run and the layout
  spec case "acknowledges the unverified override of 861 / 854 exactly when a Tauren route exists" fail** (the
  orchestrator's closing `make check` of P1, or P2). One-line change in a file I may not edit.
* DB overrides added: none. XP / mask corrections: none.
* New place name for `PLACE_NAMES_RU` (`tools/gen_route_data.lua`): **"Bloodhoof Village" = "Деревня Кровавого
  Копыта"** (`sethearth` / `hearth` of `mul02-inn`, `mul02-hearth`).
* `-- CONFIRM` in the files: `mul02-campfire` (96605's campfire works as in Tirisfal), `mul02-kyle` (Tender
  Strider Meat from Adult Plainstriders), `mul02-arrachea` (spawn; 776 offered right after 775), `mul03-org-gate`
  (the river way past Thunder Ridge). E.1 (Tauren flight Thunder Bluff -> Orgrimmar) is unchanged: walk.

## 6. Atlas facts (Mulgore, Forever DB)

* Map: Mulgore 1412 is 6,154 x 4,102 yd (61.5 yd per x %, 41 yd per y %); Forever coordinates are roughly
  Classic `(0.80 x + 8.7, 0.83 y + 13.2)` (fitted on Baine, Grull, Raintotem, Wiserunner; for orientation only).
* Hubs: Camp Narache (44, 77; trainers of all four classes, teach to 6), Bloodhoof Village (47, 63; inn Kauth
  6747 45.93, 64.16; trainers Gennia 3064, Narm 3066, Krang 3063, Yaw 3065; no flight master), Kaga Wildhoof's
  camping camp (46.2, 67.3), Thunder Bluff (lift `1456: 31.78, 65.92`; Tal 2995, Cairne 3057, Hamuul 5769 on Elder
  Rise, Melor 3441 on Hunter Rise, Ahanu 8359), Red Rocks (Raintotem 3233, Ancestral Spirit 2994), Morin
  Cloudstalker 2988 (east road, 54.8, 64.3), Malah Longwind 275789 (57.6, 63.2).
* The three wells (quest triggers): Winterhoof 51.76, 68.43 (also 12 Well Stones), Thunderhorn 44.2, 51.1 (11
  Well Stones), Wildmane 42.7, 25.0.
* Mob clusters: Windfury harpies in two camps, south-east (62, 72) and west (34, 48); Sorceresses / Matriarchs
  north-west below Thunder Bluff (32-33, 33-36) and north (37-41, 18-22; 50-54, 18-27); Palemane in two camps,
  west (33-37, 64-66) and south (47-52, 73-75); Venture Co. mine 56-62, 43-53 and a second camp at 41, 26;
  Bristleback Interlopers only on Red Rocks (58, 31); Galak centaurs 63.8, 62.6, Herak 60.3, 60.5 (11 spawns).
* Forever-new quests used (XP estimated): 95805, 96659, 96605, 96661, 96130, 99108, 99411 (needs Tender
  Strider Meat 287505 from Adult / Elder Plainstriders), 99079 > 99081 > 99101 > 99080 > 99082, 98424 (started by
  item 281031 from Fizsprocket; three ground documents 673494 / 673496 / 673497 in the mine), 98430 (escort,
  trigger 37.19, 64.62), 98435.
* Not used, for the adventure atlas: 98427 Ceasing Operations (elite Venture Co. Clearclutter 272173 at 56.8,
  42.8), 744 Preparation for Ceremony, 770 (rare Ghost Howl), 768 / 769 (Skinning / Leatherworking), 97485
  (item without a DB source), 76156 chain ("Rogue Trainer?" Boarton Shadetotem, E.10), 9264 (Scourge event),
  5844 (gift voucher), Skywatcher Plateau level-30 quests (used by `h-27`).

## 7. Minor, for phase R

* The druid's Moonglade / Elder Rise steps can use `mul03-hamuul` (Elder Rise) instead of a separate walk.
* `mul02-bh-1` is Harken's step; the hunter trainer Yaw stands at the north end (`mul02-yaw`, 6.77).
* Notes use English NPC names in the Russian text (as Zephras); the place words are Russian.
