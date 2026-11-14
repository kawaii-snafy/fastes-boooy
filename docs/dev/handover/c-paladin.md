# Hand-over C3: paladin (`Classes/Paladin.lua`)

Phase C3 (class steps: Priest, Druid, Paladin), agent "paladin". Owned and touched:
`addons/FastesBoooy_Guides/Classes/Paladin.lua`, `docs/routes/class-paladin.md`, this file.
`tools/overrides/paladin.lua` was not needed (no DB override, no XP value) and does not exist.

The paladin is Undead only (DB race mask 16 = Scourge on every paladin quest but 95042, an all-Horde side quest; `classes.md` section 2), so the class
has one route, `undead-paladin`. The file existed (migrated in F2a/F2d from the old UndeadPaladin module); this phase
reviewed it against PLAN.md section C and the trainer question E.3 and changed only what was wrong.

## 1. What changed

* **E.3 / C.5, trainers in Thunder Bluff and the Undercity.** Before: only `pal-train-14/18/20/22` carried `-- CONFIRM`
  and a Brill fallback in the note. Now every step at Alodan the Hopeful (246344) or Garen Largo (260093) does:
  `pal-train-26`, `pal-train-30` (Thunder Bluff) and `pal-train-34`, `pal-train-40-garen`, `pal-train-44`,
  `pal-train-52`, `pal-train-58`, `pal-train-60` (Undercity) got a `-- CONFIRM` line; their notes name Shari Stilwell
  in Brill (bilingual), except `pal-train-40-garen`, which is itself the Undercity fallback of the Brill visit.
  Distances (DB, Tirisfal 4,519 x 3,013 yd): zeppelin tower 60.74, 58.87 -> Shari 60.22, 52.66 is ~190 yd; the
  route lands there at 22.04, 31.06 and 40.88 (worst); the Undercity entrance is ~400 yd south of Brill.
* **C.6, riding optional.** `pal-40-riding` (manual at Velma Warnam) got `optional = true` (100 gold may be
  missing; the note already said "press Forward").
* **C.7, Warhorse.** `pal-train-40` lists "Summon Warhorse (if listed)" among its spells (web: the class trainer
  teaches it at 40; the DB has no source).
* **Header**: E.3 paragraph rewritten for 12-60; the Redemption skip and the reward-table decision explained with a
  `CONFIRM` line; Hilda the Breaker noted.
* `docs/routes/class-paladin.md`: optional count 18 -> 19, E.3 paragraph in §2.1, `pal-40-riding` optional in §3,
  Warhorse in §6, Redemption reasoning in §9, §11 updated.
* File totals: 32 inserts, 62 steps, 19 optional (`optional = true` count), 12 trainer steps with `-- CONFIRM`.

Nothing was slow to fix: every training visit already sits on a stop the path makes (levels below), the class chains
that are routed are on the way, and the optional ones are optional.

## 2. Acceptance: commands and results

`G=addons/FastesBoooy_Guides`, `<F>` = `--skip 'Classes/*' --keep Classes/Paladin.lua --own Classes/Paladin.lua`.

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Classes/Paladin.lua tools/overrides/paladin.lua` | `Paladin.lua`: 0 warnings / 0 errors; the override file does not exist ("couldn't read", exit 3, as for the druid) |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --baseline docs/dev/handover/baseline.json --route "*-paladin" <F> $G` | **exit 0**: 0 error, 0 warning, 17 accepted (strict), 465 info |
| ... `--summary` line | `undead-paladin  Scourge PALADIN Horde  0 0 17 0 60.00 60.00 4902 6173` (Undead base profile 4,982 / 6,217) |
| `lua5.1 tools/validate_routes.lua --route undead-paladin --levels <F> $G` | exit 0 (levels in section 3) |
| `lua5.1 tools/simulate_routes.lua --route undead-paladin --skip 'Classes/*' --keep Classes/Paladin.lua $G` | `OK`: 1,754 steps, 1,608 iterations, 721 accepted, 721 turned in, 90 bg, level 60, 82 quest XP estimated; no warning (25 s) |
| `GUIDES_SKIP='Classes/*' GUIDES_KEEP=Classes/Paladin.lua GUIDES_OWN=Classes/Paladin.lua busted tests/spec/guides_layout_spec.lua` | 22 successes / 0 failures / 0 errors |

### Kills per segment, Undead base -> Undead paladin (normal / worst; segments not listed are equal)

| Segment | Base | Paladin |
|---|---|---|
| `ud-01-deathknell` | 3 / 3 | 2 / 2 |
| `ud-02-tirisfal` | 1 / 6 | 0 / 0 |
| `h-13-silverpine` | 19 / 20 | 0 / 0 |
| `h-18-stonetalon-ashenvale` | 24 / 118 | 3 / 101 |
| `h-27-ashenvale-needles` | 122 / 313 | 84 / 313 |
| total | **4,982 / 6,217** | **4,902 / 6,173** |

The paladin leaves Tirisfal at 12.79 (base 12.10): the class chain 98601 ... 95803 (estimated XP).

## 3. Training visits (anchor, `--levels` normal / worst)

| Level | Trainer | Step | Anchor | Level at step |
|---|---|---|---|---|
| 1 | Aramis Hammerhand 244808, Deathknell | `pal-tir-train-1` | `ud01-364` | 2.65 |
| 4 | Aramis | `pal-tir-train-4` | `ud01-aramis` | 4.09 |
| 6 | Shari Stilwell 246152, Brill | `pal-tir-train-6` | `ud02-dillinger-report` | 6.60 / 6.51 |
| 8 | Shari | `pal-tir-train-8` | `ud02-shari-99144` | 8.27 / 8.22 |
| 10 | Shari | `pal-tir-train-10` | `ud02-level-10` | 10.25 / 10.15 |
| 12 | Shari | `pal-tir-train-12` | `ud02-carolai-2` | 12.61 / 12.55 |
| 14 | Garen Largo 260093, Undercity (CONFIRM) | `pal-train-14` | `h13-uc-end` | 14.56 / 14.46 |
| 18 | Alodan the Hopeful 246344, Thunder Bluff (CONFIRM) | `pal-train-18` | `h18-tb-zamah` | 18.37 / 18.04 |
| 20 | Alodan (CONFIRM) | `pal-train-20` | `h18-tb-2` | 20.60 / 20.26 |
| 22 | Alodan (CONFIRM) | `pal-train-22` | `h-22-tb-start` | 22.04 |
| 26 | Alodan (CONFIRM) | `pal-train-26` | `h-27-tb-arrive` | 27.57 / 27.12 |
| 28 + 30 | Alodan (CONFIRM) | `pal-train-30` | `h-31-tb-hearth` | 30.91 |
| 32 + 34 | Garen (CONFIRM) | `pal-train-34` | `h-34-uc-arrive` | 34.10 |
| 36-40 | Shari, Brill (+ riding, horse, optional Garen) | `pal-train-40` | `h-41-uc-arrive` | 41.02 / 40.88 |
| 42 + 44 | Garen (CONFIRM) | `pal-train-44` | `h-44-uc-arrive` | 44.02 / 44.00 |
| 46-52 | Garen (CONFIRM) | `pal-train-52` | `h53-fly-uc` | 52.57 / 52.54 |
| 54 + 58 | Garen (CONFIRM), optional | `pal-train-58` | `h59-hearth-uc` | 57.96 / 57.92 |
| 58 + 60 | Garen (CONFIRM) after the hearth | `pal-train-60` | `h-60-end` | 60.00 |

Weapon skill: Two-Handed Axes at Hanashi 2704 (Orgrimmar 81.53, 19.63), `pal-axes`, optional, after `h41-hearth-org`
(41.02 / 40.88), for Tok'kar's Murloc Chopper (1427, 44) and Beastslayer (4301, 54).

## 4. Foreign warnings

None (0 WARN with `--own Classes/Paladin.lua`; the 17 accepted are `ok` acknowledgements on shared steps, unchanged).

## 5. Ids added / anchors / wishes

No ids added or removed this phase (all 62 `pal-*` ids exist since F2d). Anchors used (all frozen): `ud01-364`,
`ud01-aramis`, `ud01-boxes`, `ud01-98389`, `ud02-dillinger-report`, `ud02-shari-99144`, `ud02-level-10`, `ud02-keep`
(before), `ud02-leonid-letter`, `ud02-hilda`, `ud02-ephram`, `ud02-elixir-bg`, `ud02-shadowvale`, `ud02-hilda-2`,
`ud02-lvl-12`, `ud02-carolai-2`, `ud02-fp-uc`, `h13-uc-end`, `h18-tb-zamah`, `h18-tb-2`, `h-22-tb-start`, `h-22-uc-fly`
(before), `h-22-the-sepulcher-apothecary`, `h-27-tb-arrive`, `h-31-tb-hearth`, `h-34-uc-arrive`, `h41-hearth-org`,
`h-41-uc-arrive`, `h-44-uc-arrive`, `h53-fly-uc`, `h59-hearth-uc`, `h-60-end`. Anchor wishes: none.

## 6. XP values, mask corrections, place names, DB overrides

None. All 30 paladin quests are Forever-new without XP in the snapshot (estimated by the validator; record with
`/fb xp`). No new place names for `PLACE_NAMES_RU`. No DB override.

## 7. `-- CONFIRM` list (in the file)

* The 12 steps at Garen Largo (Undercity) and Alodan the Hopeful (Thunder Bluff), E.3: `pal-train-14`, `-18`, `-20`,
  `-22`, `-26`, `-30`, `-34`, `-40-garen`, `-44`, `-52`, `-58`, `-60`. Fallback named in the notes: Shari Stilwell, Brill.
* Reward indexes of the generic Tirisfal quests 3901, 376, 3902, 380, 381, 382, 426, 398, 358, 97558, 374 (header):
  the snapshot has no reward lists; the paladin's choices are named in notes; then a `rewards = { PALADIN = ... }`
  table can be added.
* Not in the file as CONFIRM but open in game: Summon Warhorse at 40 from the trainer; whether Shari sells ranks 40+;
  whether the riding skill comes with a mount (E.9).

## 8. Deviations from the plan

1. **Redemption chain not routed** (C.4 lists "paladin Redemption" as a mandatory key ability; `classes.md` 5.10 says
   "Redemption chain at 12 (exists)", but only its first two quests 94427 / 94434 existed, optional). The rest,
   94435 > 94436 > 94438 > 94440 > 94441, runs Tanis (Undercity) > Danitha / Billmuth (Bandarion Keep, Tirisfal 22, 44.6)
   > Deathguard Falgan (86.7, 47.7) > Scarlet Crusade Attack Plans (Scarlet Zealot / Friar drop, 48.8, 66.2 or 76.1,
   57.2) > Billmuth > Danitha: about 2 x 2,900 yd on foot at level 12 (~25 min) for five quests of estimated XP and a
   resurrection spell that gives nothing for solo leveling. The user's rule ("only the class quests worth it for
   leveling speed") wins; kept as it was (skipped, header and route doc say why).
2. **No class reward table** (C.1 rule 5 / A.5.4 / D.5 work list): no reward data in the snapshot and no indexes in the
   old route; a guessed index would make the automation take the wrong item silently. Same choice as the other
   class agents for start-zone rewards.

## 9. Facts for the atlas

### Paladin trainers (DB, Horde)

| Place | Trainer (id, map, coords) | Note |
|---|---|---|
| Deathknell, Tirisfal | Aramis Hammerhand 244808 (1420: 31.10, 66.41) | start camp (teaches to 6); letter 98601 ends here; gives 90902, 91208, 91209, 98389 |
| Brill, Tirisfal | Shari Stilwell 246152 (1420: 60.22, 52.66) | by the stables; gives 91282; takes 91209, 99144 |
| Bandarion Keep, Tirisfal | Hilda the Breaker 246389 (1420: 21.96, 47.25) | "Paladin Trainer" in the DB; objective of 91294 |
| Undercity, War Quarter | Garen Largo 260093 (1458: 47.53, 15.04; 7 spawns 45.97-54.94, 13.90-22.66) | DB yes, web no (E.3) |
| Thunder Bluff, Pools of Vision | Alodan the Hopeful 246344 (1456: 25.81, 19.03; 14 spawns 22.1-29.4, 14.6-23.8, wanders) | DB yes, web no (E.3) |
| - | Sevren Callahan 246611 | "Paladin Trainer", no spawn, no faction in the DB |
| Orgrimmar, hubs 22-60 | none | |

Services: Velma Warnam 4773 (Undead Horse Riding Instructor, Brill 60.08, 52.57), Zachariah Post 4731 (Undead Horse
Merchant, Brill 59.87, 52.68), Hanashi 2704 (Weapon Master, Orgrimmar 81.53, 19.63: axes), Oliver Dwor 2136 (Brill
60.12, 53.39: Wooden Mallet).

### Class quests (DB; Undead-only except 95042, all XP unknown) and rewards

| Chain | Quests | Reward | Routed |
|---|---|---|---|
| Letter | 98601 (Sarvis 1569 / Elreth 1661 -> Aramis) | - | yes, 2.6 |
| Deathknell | 90902 -> 91208; 91209 (-> Shari, Brill) | - | yes, 2.6-6.5 |
| Bandarion Keep | 91282 -> 91285 -> 91294 -> 91316 / 91317 -> 95803 (Sylvanas) | Driftwood Smasher (91285), Salvaged Wooden Tower Shield (91316) | yes, 10.2-12.7 |
| A Lesson in Divinity | 94427 -> 94434 (10 Linen Cloth) -> 94435 -> 94436 -> 94438 -> 94440 -> 94441 | Redemption (web) | 94427 / 94434 optional; rest skipped (section 8) |
| Windshaper part 1 | 91858 -> 91859 -> 91860 -> 91861 -> 91862 -> 96204 (escort) -> 95034 | none of its own | optional, 22.7-23.0 (normal) |
| Wolfsbane part 2 | 95036 (+95042 Kor Gem) -> 95111 -> 95125 -> 95126 -> 95140 | Wolfsbane (2H sword) | no: Deadmines, Shadowfang Keep, Blackfathom entrance, elite |

### Skipped and why

Redemption chain (section 8); Wolfsbane part 2 (dungeons); training at 16, 24, 38, 46-48, 54-56 as separate visits
(minor ranks only, merged into the next stop on the path); the Thunder Bluff stops at 24.8 / 28.4 and the Undercity
stops at 31.2 / 49.5 (one rank short or nothing new); 2H swords (Orcish War Sword of 1153 is no upgrade).

## 10. Minor, for phase R

* `tools/overrides/paladin.lua` does not exist, so the D.5 luacheck command (with the override path) exits 3 on the
  missing file; `Paladin.lua` alone is clean. Same for the druid.
* Hilda the Breaker (Bandarion Keep) is a paladin trainer in the DB: if E.3 turns out "no trainer in Thunder Bluff /
  Undercity", the optional chain visit to the keep at 22 (`pal-22-danitha`) could also train there.
* `docs/routes/class-paladin.md` §1 table and §3 levels were written in F2d; the numbers still match the validator
  (only the optional count changed).
