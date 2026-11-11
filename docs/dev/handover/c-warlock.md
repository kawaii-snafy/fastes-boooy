# Hand-over C2: warlock (`Classes/Warlock.lua`)

Phase C of `docs/dev/PLAN.md` (D.5, row Warlock), agent "warlock", FAST MODE: targeted checks only, no `make check`, no
`make routedata` / `report`. No git command that changes state was run. `G` = `addons/FastesBoooy_Guides`.

## 1. What changed

| File | Change |
|---|---|
| `G/Classes/Warlock.lua` | written (was a placeholder): 37 inserts, 73 steps (21 optional), all `class = "WARLOCK"`, ids `wlk-...`; header with every visit, anchor and validator level, what is skipped and why |
| `tools/overrides/warlock.lua` | new: Troll added to the race masks of 1501 / 1504 (C.5); the shard -> orb pairing of 4975 / 4964 swapped (section 8) |
| `docs/routes/class-warlock.md` | new (Russian; shape of `class-paladin.md` / `class-rogue.md`): overview with grind per race, demons, trainers, training tables 1-22 / 22-60, every insert with anchor and level, talents, class quests, weapons, decisions, uncertainties |
| `docs/dev/handover/c-warlock.md` | this file |

Nothing else was touched (no segment, race file, other class file, spec, tool). Scratch files only under
`$SCRATCH/wlk/`.

## 2. Acceptance: commands and results

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Classes/Warlock.lua tools/overrides/warlock.lua` | 0 warnings / 0 errors in 2 files, exit 0 |
| `lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --baseline docs/dev/handover/baseline.json --route "*-warlock" --skip 'Classes/*' --keep "Classes/Warlock.lua" --own "Classes/Warlock.lua" $G` | **exit 0**: 0 error, 0 warning, 53 accepted (strict), 0 foreign; summary below |
| `lua5.1 tools/validate_routes.lua --route "<race>-warlock" --levels <F> $G` (orc, troll, undead) | exit 0 x 3; levels of every own step: `docs/routes/class-warlock.md` section 3 |
| `lua5.1 tools/simulate_routes.lua --route "<race>-warlock" --skip 'Classes/*' --keep "Classes/Warlock.lua" $G` (one at a time) | **OK x 3**, no other output line: orc 1,728 steps (712 accepted / turned in), troll 1,728 (712), undead 1,749 (718), level 60 each |
| `GUIDES_SKIP='Classes/*' GUIDES_KEEP="Classes/Warlock.lua" GUIDES_OWN="Classes/Warlock.lua" busted tests/spec/guides_layout_spec.lua` | 22 successes / 0 failures / 0 errors |

`--summary` (route, profile, errors, warnings, accepted, foreign, end level, worst, grind, worst):

```
orc-warlock	Orc WARLOCK Horde	0	0	17	0	60.00	60.00	4897	6199	-	-
troll-warlock	Troll WARLOCK Horde	0	0	19	0	60.00	60.00	4897	6199	-	-
undead-warlock	Scourge WARLOCK Horde	0	0	17	0	60.00	60.00	4898	6187	-	-
```

Against the base route of the race (`--skip 'Classes/*'`, normal / worst): Orc and Troll 4,980 / 6,227 -> 4,897 / 6,199;
Undead 4,982 / 6,217 -> 4,898 / 6,187 (baseline file: Orc / Troll 4,980 / 6,227, Scourge 4,982 / 6,217). Grind up to the
end of `h-18` (`--grind-until h-18-stonetalon-ashenvale`, normal / worst): Orc / Troll 45 / 157 -> 35 / 145, Undead
47 / 147 -> 36 / 133: inside the `h-18` budget 120 / 200. The run was made with the override files present at the time
(`shared`, `hunter`, `rogue`, `shaman`, `warlock`, `warrior`).

### Kills per segment, base -> warlock (normal / worst; segments not listed are equal within 1)

| Segment | Orc / Troll | Undead |
|---|---|---|
| start zone | `dur-02` 9 / 9 -> 9 / 9 | `ud-01` 3 / 3 -> 0 / 0, `ud-02` 1 / 6 -> 0 / 5 |
| `h-13-silverpine` | 0 / 3 -> 0 / 0 | 19 / 20 -> 17 / 18 |
| `h-18-stonetalon-ashenvale` | 36 / 145 -> 26 / 136 | 24 / 118 -> 19 / 110 |
| `h-22-hillsbrad` | 0 / 51 -> 0 / 48 | 0 / 51 -> 0 / 49 |
| `h-37-desolace-dustwallow` | 1,009 / 1,029 -> 999 / 1,029 | 1,009 / 1,029 -> 998 / 1,029 |
| `h-41-arathi-badlands` | 764 / 918 -> 720 / 907 | 764 / 918 -> 721 / 907 |
| `h-46-tanaris-feralas` | 617 / 714 -> 601 / 715 | 617 / 715 -> 601 / 715 |

No segment-level or level-grind ceiling moved into a warning (`h39-level-mannoroc` keeps its `level-grind = 690`: the Orb
XP lowers it).

## 3. Foreign warnings

None (`foreign` = 0 for all three routes with `--own Classes/Warlock.lua`).

## 4. Ids added

All in `Classes/Warlock.lua` (prefix `wlk-`):
`wlk-dur-letter-orc`, `wlk-dur-nartok-orc`, `wlk-dur-letter-troll`, `wlk-dur-nartok-troll`, `wlk-dur-train-4`,
`wlk-dur-train-6`, `wlk-dur-train-10`, `wlk-dur-1506`, `wlk-ganrul`, `wlk-staves`, `wlk-tablet`, `wlk-ganrul-2`,
`wlk-binding`, `wlk-ganrul-3`, `wlk-train-12`, `wlk-train-14`; `wlk-tir-letter`, `wlk-tir-maximillion`,
`wlk-tir-1470`, `wlk-tir-skulls`, `wlk-tir-venya`, `wlk-tir-train-4`, `wlk-tir-train-6`, `wlk-tir-train-8`,
`wlk-tir-train-10`, `wlk-tir-1478`, `wlk-tir-carendin`, `wlk-tir-train-12`, `wlk-tir-grimoire`, `wlk-tir-carendin-2`,
`wlk-tir-binding`, `wlk-tir-carendin-3`, `wlk-tir-train-14`; `wlk-16-fly-org`, `wlk-train-18`, `wlk-16-fly-taurajo`,
`wlk-train-22`, `wlk-22-1472`, `wlk-22-godrick`, `wlk-avelina`, `wlk-24-fly-uc`, `wlk-train-24`, `wlk-isaac`,
`wlk-31-carendin`, `wlk-31-binding`, `wlk-31-incubus`, `wlk-train-30`, `wlk-train-34`, `wlk-36-4967`, `wlk-train-36`,
`wlk-36-fly-ratchet`, `wlk-36-menara`, `wlk-36-wytula`, `wlk-38-orb`, `wlk-38-spirit`, `wlk-train-40`,
`wlk-40-fly-ratchet`, `wlk-40-strahad`, `wlk-40-felsteed`, `wlk-40-menara`, `wlk-41-tabetha`, `wlk-41-demon`,
`wlk-41-tabetha-2`, `wlk-train-44`, `wlk-46-menara`, `wlk-46-orb`, `wlk-46-orb-done`, `wlk-train-48`, `wlk-train-52`,
`wlk-train-54`, `wlk-train-56`, `wlk-60-hearth`, `wlk-train-60`.

Anchors used (all explicit ids, all unfiltered; inserts on start-zone anchors carry the race scope of the zone):
`dur01-teeth` (two inserts, Orc / Troll), `dur01-den-4`, `dur02-garthok`, `dur02-rh-3`, `h12-borstan`, `h12-cattails`,
`h12-zeppelin` (before), `h15-org` (Orc / Troll), `ud01-364`, `ud01-skeletons`, `ud01-church-4`, `ud02-sethearth`,
`ud02-brill-8`, `ud02-terrence`, `ud02-fp-uc`, `ud02-uc-exit`, `h13-uc-arrive` (Scourge), `h15-end`, `h22-rol-oran`,
`h22-offering-stone-3`, `h-24-tarrenmill-end`, `h-24-ratchet-arrive`, `h-31-uc-arrive`, `h-34-uc-arrive`,
`h-37-org-arrive`, `h-37-orgrimmar-keldran`, `h39-level-mannoroc` (before), `h-40-org-arrive`,
`h-38-dustwallow-marsh-field`, `h-44-stonard-arrive`, `h46-ratchet-fm`, `h-50-org-arrive`, `h53-org-hearth`,
`h56-sethearth-org`, `h-58-org-arrive`, `h-60-end`.

Notes on the C.2 draft: the Durotar level-8 training is merged into the level-10 visit at `dur02-rh-3` (the path is in
Razor Hill only at 9.5-10 after 7.7); the Orgrimmar Voidwalker uses `h12-borstan` (Gan'rul stands 80 yd from Kor'ghan,
whose insert sits on the same anchor) and `before = "h12-zeppelin"` (after the Durotar insert `dur02-rhinag`, Skull Rock
is 150 yd from the tower). `ud01-church-4` is at 3.74 before its own turn-ins; with 1470 the level is 4.16 at the
training step.

## 5. Anchor wishes

None: every visit found an explicit id at the right place.

## 6. XP values and mask corrections for quests I may not override

None: all quests of this file are warlock-only and appear in no other file. XP unknown (Forever-new, estimated by the
validator): 98575 (Troll letter), 65593 Hearts of the Lovers, 65597 The Binding (Incubus), 3631 Summon Felsteed; record
with `/fb xp` and put them into `tools/overrides/warlock.lua`.

## 7. New place names for `PLACE_NAMES_RU`

None: the `fly` / `hearth` actions name Orgrimmar, Camp Taurajo, Undercity and Ratchet, which the shared path already
uses.

## 8. DB overrides added (`tools/overrides/warlock.lua`, all `verified = false`)

| Quest | Change | Source | Steps acknowledged (`ok = "db-override-unverified"` + `-- CONFIRM`) |
|---|---|---|---|
| 1501 Creature of the Void | `races.add Troll` | warcrafttavern warlock-leveling (classes.md 7) | `wlk-ganrul`, `wlk-tablet`, `wlk-ganrul-2` |
| 1504 The Binding | `races.add Troll` | same | `wlk-binding`, `wlk-ganrul-3` |
| 4975 The Completed Orb of Noh'Orahil | `exclusive` remove 4962, add 4963 | original game (felhound spirit -> Noh'Orahil) | `wlk-46-menara`, `wlk-46-orb`, `wlk-46-orb-done` |
| 4964 The Completed Orb of Dar'Orahil | `exclusive` remove 4963, add 4962 | original game (infernal spirit -> Dar'Orahil) | none (not routed) |

The `ok` on the 1501 / 1504 steps is used only by the Troll route (19 accepted vs 17 for the Orc); the validator does not
report it as unused for the Orc.

## 9. `-- CONFIRM` list (in the file)

* `wlk-ganrul`, `wlk-tablet` ff.: the Troll can do 1501 / 1504.
* `wlk-38-spirit`: the Felhas Ruby (12647) is used on a slain Mana Eater.
* `wlk-avelina`: Avelina Lilly (L22, no faction in the DB) can be attacked and drops the heart; XP of 65593 / 65597.
* `wlk-isaac`: Isaac Pearson (faction A in the DB) can be attacked inside Ratchet without the goblin guards joining.
* `wlk-train-40`: Incinerate (Forever-new) at 40; 4490 needs no item.
* `wlk-41-demon`: Tabetha summons the Demon of the Orb when 4961 is accepted.
* `wlk-46-menara`: Noh'Orahil follows the felhound spirit (override above).
* Header: the spell lists of the `train` steps beyond the key levels of classes.md 5.5 are the original game's.
* Russian NPC and place names in the notes (Нарток, Дхугру Кровожад, Офек, Кита, Ган'рул Кровавый Глаз, Зеврост,
  Максимилиан, Веня Мартанд, Руперт Бох, Агерон Каргал, Джина Ланг, Карендин Халгар, Годрик Фарсан, Авелина Лилли,
  Айзек Пирсон, Страхад Фарсан, Менара Воидрендер, Витула, Табета, Картош, Грешка, Ханаши; Череп-Скала, Поле Маннорок)
  and quest names («Осквернённый пергамент», «Создание Бездны», «Сердца влюблённых», ...) against the ruRU client.

## 10. Deviations from the plan

1. **No class reward table** (D.5, A.5.4): the snapshot has no reward lists; same decision as the paladin, hunter and
   rogue files.
2. **Voidwalker of the Undead at 14, not 10-12**: 1473 is given in the Undercity, which the Undead path reaches at 12.1;
   the chest lies on the way out to Silverpine, the Binding waits for the path's Undercity visit at 14 (an immediate
   return would cost ~4 min). Orc / Troll get it at 12 (a second pass through the Orgrimmar gate, ~4 min).
3. **Durotar 8 + 10 merged** at `dur02-rh-3` (C.4 allows merging; the Razor Hill stop at 9.56 is 0.45 levels earlier).
4. **Succubus / Orgrimmar branches, Felhunter, robe chain, Soran'ruk, the level-50 Felwood chain not routed** (reasons
   in the file header and `class-warlock.md` section 5); the Felwood chain (a "candidate" of classes.md 5.10) fails on
   order: the Rotting Wood of 8421 lies in the Irontree Woods the path passes before 8420 (random Felcloth) can be
   turned in.
5. **Demon trainers not as `vendor` steps**: the notes name the demon trainer next to each class trainer (grimoires
   are a choice, not a speed item).
6. **4964 / 4975 exclusivity overridden** (section 8): without it the validator would reject the felhound branch's
   real final quest.

## 11. Facts for the atlas

### Warlock trainers and demon trainers (DB; Horde-friendly)

| Place | Class trainer (id, uiMap, x, y) | Demon trainer / others |
|---|---|---|
| Valley of Trials | Nartok 3156 (1411, 40.65, 68.52), up to 6; letters 3090 / 98575 | Hraug 12776 (40.56, 68.44); Ruzan 5765 (42.59, 69.00): 1485 / 1499 |
| Razor Hill | Dhugru Gorelust 3172 (1411, 54.38, 41.20) | Kitha 6027 (54.71, 41.50); Ophek 3294 (54.37, 41.29): 1506 |
| Deathknell | Maximillion 2126 (1420, 30.91, 66.34), up to 6; letter 3099 | Kayla Smithe 5749 (30.81, 66.41); Venya Marthand 5667 (30.98, 66.41): 1470 |
| Brill, Gallows' End Tavern | Rupert Boch 2127 (1420, 61.59, 52.40) | Gina Lang 5750 (61.55, 52.61); Ageron Kargal 5724 (61.62, 52.68): 1478 |
| Orgrimmar, Cleft of Shadow | Zevrost 3326 (48.47, 45.43), Grol'dar 3324 (47.98, 45.93), Mirket 3325 (48.62, 46.95) | Kurgul 5815 (47.52, 46.72); Gan'rul Bloodeye 5875 (48.25, 45.28); Cazul 5909 (47.06, 46.43); circle (49.43, 50.04); Magar 3363 (63.65, 49.93, tailor, 65601) |
| Undercity, Magic Quarter | Kaal Soulreaper 4563 (86.21, 15.93), Luther Pickman 4564 (86.43, 15.25), Richard Kerwin 4565 (88.91, 15.86) | Martha Strain 5753 (85.70, 16.08); Carendin Halgar 5675 (85.06, 25.99); Godrick Farsan 5693 (84.81, 14.83); circle (86.62, 27.05) |
| Stonard | Kartosh 988 (1435, 48.65, 55.64) | Greshka 12807 "Demon Master" (48.58, 55.27, vendor) |
| Ratchet | none | Strahad Farsan 6251 (62.63, 35.50), Menara Voidrender 6266 (62.51, 35.45), Acolytes Wytula 6254 / Magaz 6252 |
| Thunder Bluff | none | |

### Class quests (DB) and rewards (rewards are not in the DB)

| Quest | Race | Giver -> ender | XP (DB) | Note |
|---|---|---|---|---|
| 3090 / 98575 / 3099 Tainted Parchment / Tablet / Scroll | Orc / Troll / Undead | Gornek 3143 / Sarvis 1569 -> Nartok / Maximillion (pre 788 / 364) | 40 / ? / 40 | letter, routed |
| 1485 > 1499 Vile Familiars | all Horde (excl. 1470) | Ruzan 5765 -> Zureetha 3145 | 355 + 35 | Imp; in the Durotar segment |
| 1470 Piercing the Veil | all Horde (excl. 1485) | Venya Marthand; 3 Rattlecage Skulls 6281 from 1890 | 190 | Imp; routed (Undead) |
| 1506 > 1501 > 1504 | 1506 all Horde, 1501 / 1504 Orc in the DB (+Troll override) | Ophek -> Gan'rul; Burning Blade Stash 58595 (1411 51.62, 9.76); Glyphs of Summoning 7464, Summoned Voidwalker 5676 | 210 + 880 + 660 | Voidwalker; routed |
| 1478 > 1473 > 1471 | 1478 all Horde, 1473 / 1471 Undead | Ageron -> Carendin; Perrine's Chest 37098 (1420 51.06, 67.57); Runes of Summoning 6284 | 210 + 630 + 630 | Voidwalker; routed |
| 1472 > 65593 > 65597 | all Horde (excl. 1507) | Carendin -> Godrick -> Carendin; Avelina Lilly 185333 (1421 63.0, 63.9), Isaac Pearson 185334 (1413 61.9, 38.5); Lovers' Hearts 190181; Summoned Incubus 185335 | 155 + ? + ? | Incubus; routed |
| 1507 > 65601 > 65610 > 65604 | all Horde (excl. 1472) | Gan'rul -> Cazul -> Magar -> Gan'rul; Withered Scarf 190232 from Shadethicket mobs (Ashenvale 59, 79) | 155 + ? | Incubus, Orgrimmar branch; skipped |
| 1507 > 1508 > 1509 > 1510 > 1511 > 1515 > 1512 > 1513 | all Horde | Gan'rul, Cazul, Zankaja / Gazrog, Ken'zigla, Grunt Logmar / Dogran | 5,955 | Succubus; skipped |
| 3631 / 4489 > 4490 | all Horde | Zevrost / Kaal Soulreaper -> Strahad Farsan | ? + 315 | Felsteed; routed (3631) |
| 4967 / 4969 > 1799 + 4962 / 4963 > 4961 > 4976 > 4975 / 4964 | all | Zevrost / Kaal -> Menara; Infernal Orb 7291 (Burning Blade Summoners 4668, Mannoroc Coven), Felhound spirit 12648 (Mana Eaters 4678; Felhas Ruby 12647); Tabetha 6546 (1445 46.06, 57.09), Demon of the Orb 6549 (L40 elite) | 1,350 + 3,150 + 2,350 + 2,350 + 1,550 + 3,900 | Orb of Orahil (off-hand); routed optional |
| 2996 / 3001 > 1801 > 1803 > 1805 > 1795 | all Horde | Gan'rul / Carendin -> Strahad -> Jorah Annison ... | 610 x 2 + 2,450 x 3 | Felhunter; skipped |
| 8419 / 8420 > 8421 > 8422 | any | Zevrost / Kaal or Impsy 14470 (1448 41.36, 45.02); Felcloth 14256; Rotting Wood 20613 (Irontree 1448 ~49.8, 23.2), Bloodvenom Essence 20614 (Tainted Ooze, ~40.5, 51.7) | 3,800 + 5,100 + 6,350 | skipped |

### Weapon masters for a warlock

Hanashi 2704 (Orgrimmar, Valley of Honor 81.53, 19.63): staves; Archibald 11870 (Undercity War Quarter 57.31, 32.77):
swords, daggers.

## 12. Open issues for the orchestrator

None blocking.

## Minor, for phase R

* The `--levels` worst-case column of an optional step shows the level of the worst run at that point (e.g.
  `wlk-train-18` 17.73), although the step is not done in that run: cosmetic, as in every class file.
* Russian NPC / place / quest names (section 9) need the ruRU client; the Durotar segment calls the Cleft of Shadow
  "Расселина Тьмы" (`dur02-korghan`), the class files "Расселина Теней": one of them should be unified.
* `docs/routes/class-warlock.md` numbers are a snapshot of phase C.
