# Hand-over P1 / Durotar (Orc, Troll)

Phase P1 of `docs/dev/PLAN.md` (D.3, left column), agent "durotar". Fast mode: targeted checks only; the full
`make check` is the orchestrator's closing step. Nothing committed (D.0 rule 1).

## 1. What was done

Files (all owned by this agent; nothing else touched):

* `addons/FastesBoooy_Guides/Segments/Durotar/01_ValleyOfTrials.lua`: segment `dur-01-valley-of-trials`
  (levels 1-5, 30 steps), the Valley of Trials, class-neutral, with the game's class branch 792 (every class but
  WARLOCK) / 1485 -> 1499 (WARLOCK) as class-filtered base steps.
* `addons/FastesBoooy_Guides/Segments/Durotar/02_Durotar.lua`: segment `dur-02-durotar` (levels 5-11, 71 steps),
  four race-scoped shared inserts of one step each (`race = { "Orc", "Troll" }`) on shared anchors, and the start-zone announcement
  `ns.startZones.Durotar = { "dur-01-valley-of-trials", "dur-02-durotar" }` (13 routes `orc-*`, `troll-*`
  register).
* `docs/dev/handover/p1-durotar.md` (this file).
* `tools/overrides/durotar.lua`: not created (no DB correction was needed).

Hub order (all facts from `tools/data/forever_db.lua` via scratch lua5.1 scripts): Valley of Trials (4641, 788 +
97279, 789, 4402, 790 -> 804, 792 or 1485 -> 1499, 5441 -> 6394, 794, 805, 96652) -> Sen'jin 1 (805; 823, 818,
96821, 786) -> road spiders 96821 -> Brakk's camp (96652 -> 96604 -> 96655) -> Razor Hill 1 (bind; 2161, 96655,
96825 + 815, 791, 784 + 837, 823, 96822) -> west field (96825, 837 quilboar / scouts) -> Tiragarde Keep (784, 791,
96822, chest 830) -> Razor Hill 2 (784 -> 825, 830 -> 831, 791, 96822, 96825) -> east coast (825, 818) -> Sen'jin
2 (818; 97225, 808, 826, 817, 97223) -> Kolkar Crag (786, 99123 escort) -> Sen'jin 3 (99123, 786) -> Echo Isles
(97223, 808, 826, 97225, 817, 815) -> Sen'jin 4 -> hearth -> Razor Hill 3 (815, 825, 99048 -> Heglan -> 99049 ->
gate 10 -> 99051 + 806) -> north (837 dustrunners / battleguards, Misha 816, Rezlak 834 -> 835 + orb 97281 ->
97282, Spitelash naga 99051, crocolisks 816, Thunder Ridge 97282 + Fizzle 806, Misha, Rezlak) -> Rhinag 812 ->
Kor'ghan 813 -> venomtail scorpids outside the gate.

Forever-new quests used (15): 97279, 96652, 96604, 96655, 96821, 96825, 96822, 97225, 97223, 99123, 99048,
99049, 99051, 97281, 97282. Not used: 96876 (drop of the elite Ukorsbane), 99052 (elite Aggor the Young), 96877
(drop of the elite Halikor), 96873 / 96874 / 96875 (need a profession), 98517 (Call of Fire, race mask only of a
race outside this zone's routes). Skipped Classic quests: 5843 (gift voucher), 787, the Skull Rock block 828 ->
827 -> 829 / 832 / 5726 (a second trip north and a second Orgrimmar visit), 9263. Quest log maximum 11.

## 2. Acceptance commands and results

`$G = addons/FastesBoooy_Guides`, `<F> = --skip 'Segments/Mulgore/*' --skip 'Classes/*' --own 'Segments/Durotar/*'`.

| Command | Result |
|---|---|
| `luacheck --config .luacheckrc $G/Segments/Durotar` | 0 warnings / 0 errors in 2 files |
| `validate_routes.lua --harness $G --segments dur-01-valley-of-trials,dur-02-durotar --profile race=Orc,class=WARRIOR,faction=Horde <F> --write-state $SCRATCH/orc.json` | 0 error, 0 warning; end 11.10 (optimistic 11.84); 8 grind kills (all at `dur02-lvl-10`); state: level 11 + 0.10, 40 done, 6 in the log (4 complete), hearth Razor Hill |
| same, `race=Troll,class=PRIEST` / `race=Orc,class=WARLOCK` | 0 / 0; 11.10, 8 kills / 11.09, 9 kills |
| `simulate_routes.lua --harness ... --segments dur-01-valley-of-trials,dur-02-durotar` (the three profiles) | `OK` each, no warning ("level 10 (47%)": the simulator credits quest XP only) |
| `validate_routes.lua -q --strict --end-level --summary --grind-until h-18-stonetalon-ashenvale --route 'orc-*,troll-*' <F> $G` | **exit 0**; 0 error, 0 warning, 221 accepted (17 per route, all on shared steps), 0 foreign |
| `validate_routes.lua --route orc-warrior --levels <F> $G` | anchor table in section 4 |
| `simulate_routes.lua --route orc-warrior` / `troll-priest` / `orc-warlock` (`--skip 'Segments/Mulgore/*' --skip 'Classes/*'`) | `OK` x 3, level 60, "cold start: finished", **no warning** (1666 / 1666 / 1667 steps) |
| `GUIDES_SKIP='Segments/Mulgore/*,Classes/*' GUIDES_OWN='Segments/Durotar/*' busted tests/spec/guides_layout_spec.lua` | 22 successes / 0 failures / 0 errors |

`--summary` lines (route, profile, errors, warnings, accepted, foreign, end level, worst, grind, worst, grind to the
end of `h-18`, worst):

```
orc-hunter	Orc HUNTER Horde	0	0	17	0	60.00	60.00	4990	6226	55	156
orc-mage	Orc MAGE Horde	0	0	17	0	60.00	60.00	4990	6226	55	156
orc-rogue	Orc ROGUE Horde	0	0	17	0	60.00	60.00	4990	6226	55	156
orc-shaman	Orc SHAMAN Horde	0	0	17	0	60.00	60.00	4990	6226	55	156
orc-warlock	Orc WARLOCK Horde	0	0	17	0	60.00	60.00	4991	6227	56	157
orc-warrior	Orc WARRIOR Horde	0	0	17	0	60.00	60.00	4990	6226	55	156
troll-hunter	Troll HUNTER Horde	0	0	17	0	60.00	60.00	4990	6226	55	156
troll-mage	Troll MAGE Horde	0	0	17	0	60.00	60.00	4990	6226	55	156
troll-priest	Troll PRIEST Horde	0	0	17	0	60.00	60.00	4990	6226	55	156
troll-rogue	Troll ROGUE Horde	0	0	17	0	60.00	60.00	4990	6226	55	156
troll-shaman	Troll SHAMAN Horde	0	0	17	0	60.00	60.00	4990	6226	55	156
troll-warlock	Troll WARLOCK Horde	0	0	17	0	60.00	60.00	4991	6227	56	157
troll-warrior	Troll WARRIOR Horde	0	0	17	0	60.00	60.00	4990	6226	55	156
```

Grind to the end of `h-18`: 55 normal / 156 worst (warlock 56 / 157): inside the 120 / 200 budget of B.8 (a number
to report here, not a P1 criterion).

Per-segment table of the base route `orc-warrior` (validator; every Orc / Troll route but the warlock is identical):

| segment | planned | simulated | quest XP | kill XP | grind kills (normal / worst) |
|---|---|---|---:|---:|---|
| `dur-01-valley-of-trials` | 1-5 | 1.00 -> 5.36 | 3,595 | 2,210 | 0 / 0 |
| `dur-02-durotar` | 5-11 | 5.36 -> 11.10 | 18,365 | 11,153 | 8 / 8 |
| `h-12-orgrimmar-tirisfal` | 12-13 | 11.10 -> 12.40 | 9,005 | 2,992 | 0 / 0 |
| `h-13-silverpine` | 13-15 | 12.40 -> 14.13 | 14,155 | 4,987 | 0 / 3 |
| `h-15-barrens` | 15-18 | 14.13 -> 17.94 | 43,630 | 14,687 | 0 / 0 |
| `h-18-stonetalon-ashenvale` | 18-22 | 17.94 -> 22.05 | 51,790 | 32,679 | 47 / 145 |

Gates of 1-22 (`orc-warrior`, kills normal / worst): `dur01-boars` (2) 0 / 0, `dur01-lvl-5` 0 / 0, `dur02-lvl-6`
0 / 0, `dur02-lvl-9` 0 / 0, `dur02-lvl-10` 8 / 8 (warlock 9 / 9), **`h13-lvl-12` 0 / 0** (the B.2 row, columns
"kills" and "worst": `12  0  0  0  0  h-13-silverpine#6 id=h13-lvl-12`, same for `troll-priest`), `h13-lvl-14`
0 / 3, `h18-lvl-18` 7 / 45, `h18-lvl-20` 0 / 0, `h18-lvl-21` 0 / 0, `h18-lvl-22` 40 / 100.

Hand-over contract of B.2: end of `dur-02` at 11.05 before the last step / 11.10 after it (>= 10.9); after the
three city turn-ins 11.96 at `h12-zeppelin` (>= 11.2, target 11.5; 11.84 worst); 10.0 reached at `dur02-rh-3`
through `dur02-lvl-10`; hearth Razor Hill; 837, 806, 99051 carried and turned in at `dur02-rh-return` (14.13);
no `fp` / `sethearth` in Orgrimmar. State difference: see deviation 1.

## 3. Deviations from the plan

1. **812 / 813 (B.2, E.20).** The plan assumes the 4 Venomtail Poison Sacs can be looted before 813 is taken, so
   `dur-02` would end at Rhinag with the sacs in the bags. 813 is a child of the timed 812 (Kor'ghan offers it only
   while 812 runs: DB `parent = 812`, warcraft.wiki.gg: "must be currently on the 45 minute timer"), and the sac
   (item 4886) is a class-12 quest item; Classic quest items of this kind drop only with the quest in the log
   (not confirmed either way by the sources below). A route that relies on pre-looted sacs stalls at Kor'ghan, so
   `dur-02` now ends: `dur02-rhinag-accept` (812) -> `dur02-korghan-accept` (813, Cleft of Shadow) -> `dur02-end`
   (`complete = 813`, the scorpids between the gate and Rhinag). The city loop then turns in 813 at Kor'ghan
   (`dur02-korghan`, after `h12-borstan`; it also completes 812 with the antidote) and 812 at Rhinag
   (`dur02-rhinag`, before `h12-zeppelin`), as planned. Cost: one extra gate -> Cleft of Shadow -> gate walk,
   about 900 yd (2 min), against 1,750 XP (975 + 813's estimate 775). The hand-over state is therefore "outside
   the gate, 812 and 813 in the log, 813 complete". `dur02-end` is the scorpid step, not "accept 812 at Rhinag".
   The 812 timer now also covers the Kor'ghan trip and the scorpids (estimate: 30 of 45 minutes up to the Rhinag
   turn-in); the notes give the way out (bring the antidote right after Kor'ghan). If the sacs do drop without
   813, `dur02-korghan-accept` / `dur02-end` can be folded into the plan's version (one own-file edit for P2).
2. **Requirement gates added (B.8)**: `level = 2` on `dur01-boars` (792 needs 2), `dur01-lvl-5` (818 / 786 in
   Sen'jin need 5), `dur02-lvl-6` (815 / 837 need 6; every class trains at 6 in Razor Hill), `dur02-lvl-9` (99048
   needs 9). All cost 0 kills for every base profile; without them the simulator (quest XP only) warned "would not
   be offered yet" on these accepts. The same fix F2c used for `ud02-lvl-6`.
3. **`dur02-lvl-10` stands after the 99049 turn-in** (`dur02-orgnil-3`), right before `dur02-rh-3` (accept 99051 +
   806 at the same Orgnil). In front of the Razor Hill visit it cost 16 kills; after the turn-in 8 (warlock 9).
   The automation takes the `dur02-rh-3` quests at the turn-in; the level step still holds the guide until 10,
   so class training after `dur02-rh-3` happens at 10.
4. **Anchors that differ from the C.2 draft**: `dur02-senjin-1` is the last step of the first Sen'jin visit (accept
   786 at Lar Prowltusk), not the 805 turn-in; `dur02-rh-1` / `dur02-rh-2` are the Turroc steps next to the
   trainers; `dur02-senjin-3` is Xar'Ti after the Echo Isles; `dur02-rh-3` accepts 99051 + 806 (806 is accepted
   here, not on the first visit: fewer quests in the log). `dur01-leave` turns in 794 and accepts 805; 96652 is the
   next step (`dur01-journal`, object), and `dur01-lvl-5` is the last step of `dur-01`. The Echo Isles quests are
   accepted on the second Sen'jin visit, not the first. Insert ids follow B.2 (`dur02-korghan`, `dur02-nazgrel`,
   `dur02-rhinag`, `dur02-rh-return`); the in-segment accepts are `dur02-rhinag-accept`, `dur02-korghan-accept`.
5. `dur02-korghan` carries `complete = 812` next to `turnin = 813` (the antidote is the reward of 813): without it
   the validator warns `turnin-no-complete` on `dur02-rhinag`.

## 4. Anchor list with levels (`--levels`, `orc-warrior`; worst case equal unless noted)

| Anchor | Step | Level before |
|---|---|---|
| `dur01-teeth` | turn in 788, accept 789 (Gornek; the class letter is offered after 788) | 2.14 |
| `dur01-familiars` | accept 792, `class` = HUNTER MAGE PRIEST ROGUE SHAMAN WARRIOR | 2.52 |
| `dur01-warlock-1485` | accept 1485 at Ruzan, `class = "WARLOCK"` | 2.52 (warlock route) |
| `dur01-den-4` | accept 794 at Zureetha (join step of the branch) | 4.66 (warlock 4.57) |
| `dur01-leave` | turn in 794, accept 805 (Zureetha) | 5.12 (warlock 5.04) |
| `dur02-senjin-1` | accept 786 (Lar Prowltusk), end of Sen'jin 1 | 5.44 |
| `dur02-rh-1` | accept 96822 (Turroc), end of Razor Hill 1 | 6.53 |
| `dur02-rh-2` | turn in 96822 (Turroc), end of Razor Hill 2 | 7.73 |
| `dur02-senjin-3` | turn in 97223 (Xar'Ti), end of Sen'jin 4, before the hearth | 9.33 |
| `dur02-lvl-10` | gate `level = 10` (after the 99049 turn-in) | 9.90 |
| `dur02-rh-3` | accept 99051 + 806 (Orgnil) | 10.01 |
| `dur02-thunder-ridge` | complete 97282 + 806 (Thunder Ridge) | 10.78 |
| `dur02-end` | complete 813 (scorpids outside the gate) | 11.05 |
| (`h12-borstan` -> `dur02-korghan`) | turn in 813 | 11.10 -> 11.22 |
| (`h12-wisdom` -> `dur02-nazgrel`) | turn in 831 | 11.54 -> 11.66 |
| `h12-org-end` | | 11.85 (worst 11.73) |
| (`dur02-rhinag`, before `h12-zeppelin`) | turn in 812 | 11.85 (worst 11.73) |
| (`h15-razor-hill` -> `dur02-rh-return`) | turn in 837, 806, 99051 | 14.13 (worst 14.08) |

Other step ids with levels: `tools/validate_routes.lua --route orc-warrior --levels <F> $G`.

Anchors wished for (phase C): none beyond the list. Warrior 1498: Thunder Ridge is visited at 10.78
(`dur02-thunder-ridge`) after Rezlak, Far Watch Post is about 1,000 yd east of Razor Hill; C.2's default
(breadcrumb 1505 at `dur02-rh-3`, chain from `h15-far-watch`) holds.

## 5. Foreign warnings, overrides, XP, place names, CONFIRM

* Foreign warnings: none (the `--own` run reports 0 foreign).
* DB overrides added: none. XP values / mask corrections for quests this agent may not override: none.
* Quests with estimated XP in the zone (14; real values to record with `/fb xp`): 97279, 96652, 96604, 96655,
  96821 (warcraft.wiki.gg: 410, estimate 550), 96825, 96822, 97225, 97223, 99123, 99048, 99049, 99051, 97281,
  97282 (and 813 in the city loop).
* New place names for `PLACE_NAMES_RU`: `sethearth = "Razor Hill"` / `hearth = "Razor Hill"` (Колючий Холм) if the
  table does not have it yet.
* `-- CONFIRM`: the 812 timer (E.20) and whether the venomtail sacs drop without 813 (`dur02-rhinag-accept`,
  `dur02-rhinag`); the campfire mechanic of 96604 (the same note as the Tirisfal `ud02-campfire`).

## 6. Atlas facts (Durotar, from the DB snapshot)

* **Class trainers.** Valley of Trials: warrior Frang 3153 (42.9, 69.4), hunter Jen'shan 3154 (42.8, 69.3),
  mage Mai'ah 5884 (42.5, 69.0), priest Ken'jai 3707 (42.4, 68.8), shaman Shikrik 3157 (42.4, 69.0), rogue Rwag
  3155 (41.3, 68.0), warlock Nartok 3156 (40.6, 68.5), demon trainer Hraug 12776 (40.6, 68.4). Razor Hill: warrior
  Tarshaw Jaggedscar 3169 (54.2, 42.5), shaman Swart 3173 (54.4, 42.6), priest Tai'jin 3706 (54.3, 42.9), warlock
  Dhugru Gorelust 3172 (54.4, 41.2), demon trainer Kitha 6027 (54.7, 41.5), hunter Thotar 3171 (51.9, 43.5), pet
  trainer Harruk 3620 (52.0, 43.5), rogue Kaplak 3170 (52.0, 43.7). Sen'jin Village: mage Un'Thuwa 5880 (56.3,
  75.1) only. No mage trainer in Razor Hill; no druid or paladin trainer in Durotar.
* **Services.** Innkeeper Grosk 6928 (Razor Hill 51.5, 41.6; no inn in the valley or Sen'jin); stable master
  Shoja'my 9987 (52.0, 41.8); first aid Rawrk 5943 (54.2, 41.9); profession trainers in Razor Hill (blacksmith
  Dwukk 3174, miner Krunn 3175, engineer Mukdrak 11025), Sen'jin (alchemist Miao'zan 3184, herbalist Mishiki 3185,
  enchanter Pa'zula 266881), fishing Lau'Tiki 5941 (53.2, 81.6), "Junior" trainers in the valley (skinning Kagil
  267327, mining Norzsh 267328, herbalism Zor'la 267329). Repair: valley Kzan Thornslash 3159 / Huklah 3160 / Rarc
  3161 (40.5, 68); Razor Hill Uhgar 3163, Ghrawt 3165, Cutac 3166, Wuark 3167; Sen'jin Trayexir 10369. Rune Broker
  233428 in the valley (42.8, 68.0). Troll raptor riding: Xar'Ti 7953 and raptor vendor Zjolnir 7952 in Sen'jin
  (55.3, 75.5 / 55.2, 75.7).
* **Transport.** No flight master in Durotar (Orgrimmar: Doras 3310). Zeppelin tower north-east of the Orgrimmar
  gate: Frezza 9564 (50.8, 13.5; to Tirisfal / Undercity), Snurk Bucksquick 12136 (50.7, 12.9; to Grom'gol).
* **Elites / rares on the path** (not routed): Ukorsbane 266851 (elite, 96876), Aggor the Young 275666 (elite,
  99052, 59.2, 17.6), Halikor 266852 (elite, Thunder Ridge), Death Flayer 5823 (rare scorpid, 36.5, 49.7), Shal'ma
  276198 (rare tiger), Warlord Kolkanis 5808 / Watch Commander Zalaphil 5809 (rares).

## 7. Open issues for the orchestrator

1. The orchestrator's closing step (`make routedata report`, `make routedata-check`, `make check`) was not run here
   (D.0 rule 2).
2. `README.md` names the routes that exist (F2d note: "a line per phase"): the 13 Orc and Troll routes now
   register; the file is not this agent's.
3. P2: decide the trainer-hub gate at `h12-org-end` (base Orc / Troll 11.85, worst 11.73: 0.15-0.27 under 12, i.e.
   within the 0.4 of B.9); `docs/routes/shared-path.md` rows "в работе" for Durotar.
4. Deviation 1 needs the in-game answer (sacs before 813?) to choose between the safe version here and the
   plan's version.

## Minor, for phase R

* The notes name in-world places by their English names in the English text and by translated names in the Russian
  text (Колючий Холм, Расселина Тьмы, Громовой хребет); check them against the ruRU client when the place-name
  table is next touched.

Sources of the web cross-check (facts only, no text copied): https://warcraft.wiki.gg/wiki/Finding_the_Antidote
(813 needs the running 812 timer, 45 minutes), https://classicdb.ch/?quest=813 (813 objectives, prerequisite 812).
