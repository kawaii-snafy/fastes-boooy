# Hand-over C3: druid (`Classes/Druid.lua`)

Phase C3 (class steps: Priest, Druid, Paladin), agent "druid". Owned and touched: `addons/FastesBoooy_Guides/Classes/Druid.lua`,
`docs/routes/class-druid.md`, this file. `tools/overrides/druid.lua` was not needed (no DB override) and does not exist.

## 1. What changed

* **Tauren group of Mulgore 1-12** (new, 22 steps, `race = "Tauren"`, ids `dru-mul-…`): the letter 3094 (Grull > Gart
  Mistrunner), training 1 / 4 at Gart (Camp Narache), 6 / 8 / 10 at Gennia Runetotem (Bloodhoof), the **Bear Form chain**
  5928 > 5922 > 5930 > 5932 > 6002 (Gennia > Turak on Thunder Bluff visit 1 > Teleport: Moonglade > Dendrite > Great Bear
  Spirit > Dendrite > Bunthen Plainswind's druid flight back to Thunder Bluff > Turak > Lunaclaw at the Moonkin Stone by
  Camp Taurajo > Turak on Thunder Bluff visit 2: Bear Form), training 12 at Turak right after the turn-in.
* **Tauren Cat Form chain at 20** (new, 9 steps, `race = "Tauren"`, ids `dru-cat-tau-…`): 98340 > 98405 > 98342 > 98739 >
  98362 (Great Cat Spirit 11957 instead of the Skyborne Avatar), after `h18-tb-2`, registered between the Skyborne chain
  and the unscoped `dru-train-20` insert (so the training follows the Cat Form turn-in at Turak for both races).
* `dru-train-14`: one more spell line ("level 12 spells if missing", the Tauren fallback).
* **Race scopes reviewed** (P2 set none): kept as they are. Unscoped from 14 on (training, the Torwa chain, the level-40
  pair): both races share the path from 12 and both know Teleport: Moonglade from 10. `dru-train-14` keeps
  `{ "Skyborne", "Tauren" }` (its anchor `h13-hearth-org` is race-filtered). Skyborne-only and Tauren-only groups as above.
* **Level 40 (C.7)**: untouched; `dru-40-fly-tb` + `dru-40-train` after `h-40-org-arrive`, `dru-40-fly-taurajo` as its own
  insert before `h-38-orgrimmar-flight-master`; no other druid insert stands before that step. Composed Tauren order
  checked by the layout spec (`tau-40d-*` between `dru-40-train` and `dru-40-fly-taurajo`).
* File header rewritten (both races, per-zone visit tables with validator levels, what is skipped and why).
* File totals: 43 inserts, 96 steps, 9 optional.

## 2. Acceptance: commands and results

`G=addons/FastesBoooy_Guides`, `<F>` = `--skip 'Classes/*' --keep Classes/Druid.lua --own Classes/Druid.lua`.

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Classes/Druid.lua` | 0 warnings / 0 errors (`tools/overrides/druid.lua` does not exist) |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --baseline docs/dev/handover/baseline.json --route "*-druid" <F> $G` | **exit 0**: 0 error, 0 warning, 37 accepted (strict) |
| ... `--summary` line `tauren-druid` | `0 0 18 0 60.00 60.00 4890 6118` (baseline Tauren 4,965 / 6,197) |
| ... `--summary` line `skyborne-druid` | `0 0 19 0 60.00 60.00 4852 6052` (unchanged; baseline Skyborne 4,914 / 6,129) |
| `lua5.1 tools/validate_routes.lua --route tauren-druid --levels <F> $G` / `skyborne-druid` | exit 0 / exit 0 (levels below) |
| `lua5.1 tools/simulate_routes.lua --route tauren-druid --skip 'Classes/*' --keep Classes/Druid.lua $G` | `OK`: 1,736 steps, 716 accepted, 715 turned in, level 60, no warning (26 s) |
| `lua5.1 tools/simulate_routes.lua --route skyborne-druid --skip 'Classes/*' --keep Classes/Druid.lua $G` | `OK`: 1,784 steps, 728 accepted, 727 turned in, 13 reward choices checked, level 60; 2 warnings, both the known baseline ones (`sd02-hearth` bind point; optional `sky-1061` at level 12, `Races/Skyborne.lua`) |
| `GUIDES_SKIP='Classes/*' GUIDES_KEEP=Classes/Druid.lua GUIDES_OWN=Classes/Druid.lua busted tests/spec/guides_layout_spec.lua` | 22 successes / 0 failures / 0 errors |

### Kills per segment, Tauren base -> Tauren druid (normal run; segments not listed are equal within 1)

| Segment | Base | Druid |
|---|---|---|
| `mul-01-camp-narache` | 1 | 0 |
| `h-18-stonetalon-ashenvale` | 29 | 0 |
| `h-27-ashenvale-needles` | 122 | 120 |
| `h-53-azshara-ungoro-silithus` | 362 | 319 |
| total (normal / worst) | 4,965 / 6,197 | 4,890 / 6,118 |

Skyborne druid: unchanged from P2 (`docs/routes/class-druid.md` §1).

### Levels of the Tauren group (`--levels`, normal = worst)

`dru-mul-letter` 3.14, `dru-mul-train-1` 3.18, `-4` 4.12, `-6` 6.61, `-8` 8.89, `-10` 10.22, Thunder Bluff 1 11.32-11.41,
`dru-mul-lunaclaw` 11.55, `dru-mul-bear-form` 11.93, `dru-mul-train-12` 12.03; Cat Form chain 20.47 / 20.26 ...
20.60 / 20.40, `dru-train-20` 20.64 / 20.43.

## 3. Foreign warnings

None (0 WARN in both druid routes with `--own Classes/Druid.lua`).

## 4. Ids added

`dru-mul-letter`, `dru-mul-gart`, `dru-mul-train-1`, `dru-mul-train-4`, `dru-mul-train-6`, `dru-mul-train-8`,
`dru-mul-train-10`, `dru-mul-tb-bridge`, `dru-mul-tb-elder-rise`, `dru-mul-tb-train` (optional), `dru-mul-5922`,
`dru-mul-dendrite`, `dru-mul-bear-spirit`, `dru-mul-dendrite-2`, `dru-mul-fly-tb`, `dru-mul-tb-bridge-2`,
`dru-mul-tb-elder-rise-2`, `dru-mul-6002`, `dru-mul-tb-back`, `dru-mul-lunaclaw`, `dru-mul-bear-form`, `dru-mul-train-12`;
`dru-cat-tau-start`, `dru-cat-tau-dendrite`, `dru-cat-tau-spirit`, `dru-cat-tau-dens`, `dru-cat-tau-relics`,
`dru-cat-tau-spirit-2`, `dru-cat-tau-dendrite-2`, `dru-cat-tau-hearth-tb`, `dru-cat-tau-form`.
Anchors used (all frozen ids): `mul01-hunt`, `mul01-ravine`, `mul02-bh-1`, `mul02-bh-3`, `mul02-bh-4`, `mul02-fp-tb`,
`mul03-taurajo`, `mul03-hamuul`, `h18-tb-2`.

## 5. Anchor wishes

None.

## 6. XP values and mask corrections for quests I may not override

None. The Tauren Cat Form quests 98340 / 98405 / 98342 / 98739 / 98362 have no XP in the DB (Forever-new; estimated by
the validator). 98405 / 98342 / 98739 carry no chain links (`preSingle`) in the DB; the validator accepts them.

## 7. New place names for `PLACE_NAMES_RU`

None (the steps use Thunder Bluff only, already known).

## 8. DB overrides added

None.

## 9. `-- CONFIRM` list (in the file)

* `dru-mul-train-10`: Gennia teaches Teleport: Moonglade at 10 (classic: any druid trainer; `dru-mul-tb-train` at Turak is
  the optional fallback).
* `dru-mul-fly-tb`: Bunthen Plainswind's druid flight (a gossip option in classic, not a taxi map) lands at Tal in Thunder
  Bluff. The step has no `npc` (the flight-master check wants a spawn on the landing map; Bunthen has none in Thunder Bluff)
  and completes on arrival at Tal (`at`).
* `dru-mul-lunaclaw`: Lunaclaw appears when the Cenarion Lunardust (item 15710, the source item of 6002) is used at the
  Moonkin Stone; the snapshot has Lunaclaw 12138 and his spirit 12144 on the same spot (Barrens 41.96, 60.79).
* Unchanged from F2c/F2d: the Skyborne items (Teleport arrival point, reward indexes, Hana Lighthoof).

## 10. Deviations from the plan

1. **Bear Form chain order differs from the C.2 draft** (`mul02-bh-5` / `mul02-tb` / `mul03-taurajo`): the frozen
   Mulgore path visits Thunder Bluff twice (11.1 and 11.5-11.8) with Camp Taurajo in between, so the Moonglade trip
   (5922 > 5930 > 5932) must be done on visit 1, after the flight point (`mul02-fp-tb`), and the way back is Bunthen's
   flight (the hearthstone was used at `mul02-hearth` minutes before). 5928 is accepted at `mul02-bh-4` (10.22) together
   with the training, not at `mul02-bh-5`. 6002 is turned in after `mul03-hamuul` (Hamuul stands next to Turak).
2. **Training 12 of the Tauren at Turak** (12.03 after the 6002 turn-in) instead of merging it into 14: the 850 XP of 6002
   make 12 on the spot in both runs; `dru-train-14` keeps a "level 12 if missing" line as fallback.
3. **Cure Poison 6126-6130 not routed** (`classes.md` 5.10 lists it as a candidate): reqLevel 14, but the Tauren meet
   Turak only at 11 and 18; then Dreadmist Peak north of the Crossroads, Earthroot (Hula'mahi, Crossroads), Kodo Horn drops
   and the gazelles west of the Crossroads off the path, two more Moonglade turn-ins: an estimated 12+ minutes for 3,325 XP
   (about 17 same-level kills at 18-20), and the Tauren druid already has 0 grind up to 22.
4. No reward-table entries for Mulgore quests (the other class agents left them out too): the player chooses.

## 11. Facts for the atlas

### Druid trainers (DB)

| Place | Trainer (id, map, coords) | Note |
|---|---|---|
| Camp Narache, Mulgore | Gart Mistrunner 3060 (1412: 44.65, 76.55) | start camp, teaches to 6; letter 3094 ends here |
| Bloodhoof Village, Mulgore | Gennia Runetotem 3064 (1412: 47.48, 62.95) | gives 5928 |
| Skywatcher Plateau, Mulgore | Hana Lighthoof 262560 (1412: 33.42, 22.13) | also gives 6126 |
| Thunder Bluff, Elder Rise | Turak Runetotem 3033 (1456: 76.48, 27.22); Sheal 3034 (77.14, 27.02); Kym Wildmane 3036 (77.15, 29.82) | Turak gives 5922, 6002, 6126, 27, 98340, 9063 |
| Moonglade, Nighthaven | Loganaar 12042 (1450: 52.53, 40.57) | faction AH; reachable by Teleport: Moonglade |
| Camp Mojache, Feralas | Jannos Lighthoof 8142 (1444: 75.99, 42.28) | |
| Zephras Isle | Xyton Silverwind 251373 (Thendal, to 6), Naeluna Swiftmend 254081 (Shen'dar), Lotheluum Starbreeze 252359 (Valanaar) | Skyborne |
| Orgrimmar, Undercity | none | |

Druid services in Moonglade: Dendrite Starblaze 11802 (56.21, 30.64, quest hub), Bunthen Plainswind 11798 (44.28, 45.87,
druid-only flight to Thunder Bluff), Great Bear Spirit 11956 (39.11, 27.50), Great Cat Spirit 11957 (58.39, 73.52), Avatar of
Saeyleenan 272054 (43.92, 73.44, Skyborne), the three cat relics in the Stormrage Barrow Dens (objects 672821 / 673094 /
673093 at 72.4, 66.0 / 74.4, 65.4 / 75.2, 67.2).

### Class quests (DB) and rewards

| Chain | Races | Quests | XP | Reward | Routed |
|---|---|---|---|---|---|
| Letter | Tauren / Skyborne | 3094 / 92485 | 60 / ? | - | yes |
| Bear Form | Tauren | 5928 (or 5926 Pala, 5927 Gryshka) > 5922 > 5930 > 5932 > 6002 (Lunaclaw, Barrens 41.96, 60.79) | 85+210+420+85+850 | Bear Form | yes, 10.2-12.0 |
| Bear Form | Skyborne | 94006 > 94638 | ? | Bear Form | yes (F2c) |
| Moonglade | Skyborne | 94911 > 94913 | ? | - | yes (F2c) |
| Cure Poison | Tauren | 6126 > 6127 > 6128 > 6129 > 6130 | 3,325 | Cure Poison | no (section 10) |
| Aquatic Form | Tauren | 27 > 28 > 30 > 31 | 3,020 | Aquatic Form | no |
| Cat Form | Tauren | 98340 > 98405 > 98342 > 98739 > 98362 | ? | Cat Form, Claw, Rip, Prowl | yes, 20.5 |
| Cat Form | Skyborne | 98340 > 98341 > 98404 > 98738 > 98362 | ? | same | yes (F2c) |
| Torwa | any | 9063 > 9052 > 9051 (> 9053 Sunken Temple) | 500+5,100+5,100 (+6,350) | class item | yes to 9051 |

### Skipped and why

Cure Poison (section 10, 3), Aquatic Form (long, no use on a land route), 9053 (Sunken Temple, the route's optional run
comes before 9051), weapon skills (forms), class gear vendors for the Tauren (the starting weapon is enough until Bear Form).

## 12. Minor, for phase R

* `docs/routes/class-druid.md` §1 keeps the Skyborne segment table of F2d (the Skyborne part of the file did not change;
  the numbers still match the validator).
* The Tauren reward choices of Mulgore are not in the reward table (none of the phase C class files has them).
* The `dru-cat-start` note (Skyborne) tells the player to take 27 (Aquatic Form) by hand if Turak offers it; a Tauren
  sees 27 offered too but the Tauren notes do not mention it (deliberately skipped).
