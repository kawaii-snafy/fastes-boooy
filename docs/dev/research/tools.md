# Offline tools: map for the "all Horde race+class guides" redesign

Research report (read-only phase). Branch `claude/beautiful-planck-svbl19`, DB snapshot
`tools/data/forever_db.lua` of 2026-11-07. Everything below was read from the code or measured /
reproduced on this checkout; statements that are estimates or proposals are marked as such.
Scratch material (timing scripts, a prototype module, probes) lives outside the repository.

Contents

1. Module discovery and loading; what one `FastesBoooy_Guides` module needs
2. Validator: profiles, checks, shadow runs, XP model, states / harness, all message codes
3. Scaling to 28 routes: measured runtimes, what dominates, Makefile + CI proposal
4. `docs/VALIDATION.md`: size today, deduplication, proposal for 28 routes
5. `gen_route_data` / `Data.lua`
6. `-- WARN-OK` and `--strict`
7. Limits of the mock client / simulator for new races and classes
8. Every hard-coded profile / module / route / segment name
9. Findings that contradict or qualify the binding decisions
10. Change list per tool file
11. Parallel agents: ownership rules and per-agent commands that follow from the tools

---

## 0. Key facts in one screen

* A module that holds **shared segments and routes together already loads, validates, simulates,
  generates `Data.lua` and packages today**, as long as its TOC does *not* say
  `## X-FastesBoooy-Module: library` (verified with a prototype: 2 library segments in
  `Segments\Tirisfal\*.lua`, 2 routes registered in a loop, class files `Classes\*.lua`). The
  "route in a library module is a load error" rule is only the TOC-declaration check in
  `tools/lib/route_loader.lua:465-468`. The real blockers are elsewhere (next bullets).
* `--harness` refuses any module that registers a route (`tools/lib/harness.lua:386-390`), in both
  tools. With one Guides module the harness (the only cheap per-segment check) stops working until
  that is lifted.
* `.luacheckrc` gives route modules **no Lua base library** (`std = "fastesboooy_route"` only,
  `.luacheckrc:129-142,161-163`): `pairs` / `ipairs` in a table-driven `Route.lua` are `W113` and
  `make lint` fails. The sandbox and the client do provide them.
* **`-- WARN-OK` is not parsed by any tool.** It is a comment convention (184 comments, 151 of them
  `xp-unknown`). `--strict` therefore fails on every real route (248 WARN today) and is used only on
  the harness fixture.
* Validator `--profile` is an **override**, not a filter (`validator.lua:122-143,1958`): on a
  28-route module `--profile race=Orc,class=WARRIOR` would run all 28 routes as an Orc Warrior.
  Use `--route`. In the simulator `--profile` is a filter (`simulate_routes.lua:1441-1445,1569`).
* One load / composition error anywhere in the module fails **every** simulation
  (`simulate_routes.lua:1557-1564`), blocks `Data.lua` generation (`gen_route_data.lua:357-361`)
  and is attached to the first validated route (`validator.lua:1984-2005`). Parallel agents in one
  module block each other unless the tools get a file filter or the agents keep files loadable.
* Class trainers are recognised by the NPC sub name `"<Class> Trainer"` (`validator.lua:1212-1242`).
  The DB has them for all nine classes in every Horde start zone. But `train = true` at a **Weapon
  Master** or a **"… Riding Instructor"** is `ERROR train-wrong-trainer` (reproduced), at a "Pet
  Trainer" / "Portal Trainer" / "… Riding Trainer" it is `WARN train-not-class-trainer`.
* The DB snapshot was built for PALADIN and DRUID (`tools/build_db_snapshot.py:134-135`
  `CLASS_SORTS`, `SCOPE_CLASSES`). Class quests of the other classes are complete only where they
  fall into the "core 1-22" areas; 29 Horde class quests below level 54 (Rogue 7, Shaman 8, Mage 10,
  Warlock 4) are index-only and give `WARN quest-out-of-scope` (NPC / chain checks skipped). The
  research inputs of `make db` are not in the repository.
* Runtimes on this 4-CPU machine: validate 0.27 s per route (0.11 s of it DB load), simulate
  **25.8 s per route**, the full `simulate-sync` matrix **151 s per route**, busted 78 s, lint 3 s.
  Parallel scaling with `xargs -P 4` is linear (8 simulations in 51.6 s). 28 routes: full simulate
  about 3.0 min wall on 4 CPUs; the full sync matrix for all 28 would be about 17.6 min, so it
  needs a subset.
* About 80 % of simulator time is the real engine (`Core/Engine.lua` `ComputeVoid` / `Evaluate`,
  `Core/Steps.lua`), whose per-refresh cost grows with the route length; the mock is about 18 %.

---

## 1. Module discovery and loading

### 1.1 Discovery

* `Loader.DiscoverModules(addonsDir)` (`tools/lib/route_loader.lua:473-486`): `ls -1`, keeps
  directories named `FastesBoooy_*` that have a TOC, sorted. The core `FastesBoooy` never matches.
* `Loader.FindToc(dir)` (`route_loader.lua:127-135`): `<Dir>.toc`, `<Dir>_Camelot.toc`,
  `<Dir>_Mainline.toc`.
* Callers: validator without directories (`validator.lua:2548`), simulator without directories
  (`simulate_routes.lua:1534`, plus `tests/fixtures/core` with `--fixtures`, `:1535-1537`),
  `gen_route_data.lua --all` (`:333-335`). After the restructure all three discover exactly
  `addons/FastesBoooy_Guides`.

### 1.2 TOC parsing

`Loader.ParseToc` (`route_loader.lua:103-119`):

* `## Key: value` goes to `toc.meta[Key]`; other `#` lines are comments.
* File lines: load conditions `[...]` are stripped and **backslashes become slashes**
  (`:114`). So `Segments\Durotar\01.lua` and `Classes\Warrior.lua` are plain relative paths; the
  file is opened as `mdir .. "/" .. rel` (`:338`). Only `.lua` files are accepted (`:339-340`).
* Checks in `readToc` (`:366-396`): `## Interface` must match `^16%d%d%d` (`:382-385`);
  `## Dependencies` / `## RequiredDeps` must include `FastesBoooy` (`:386-393`).
* `## X-FastesBoooy-Module` (`:407-414`): only the value `library` is legal; it sets
  `mod.declaredLibrary`. Any other value is a load error.

The mock's own TOC parser (`Mock.parseToc`, used by the simulator through `Mock.loadAddon`,
`tests/mocks/wow/system.lua:318-352`) handles the same syntax, including backslash paths and
`[AllowLoadGameType …]` (`tests/spec/mock_toc_spec.lua:80-85`).

### 1.3 Dependencies

* `Loader.Dependencies(toc)` (`:138-149`): names in `## Dependencies` / `## RequiredDeps` that
  start with `FastesBoooy_`.
* `LoadModule` loads them first, depth first, from the parent directory of the module (or
  `opts.addons`) (`:418-444`); a missing dependency or a cycle is a load error (`:423-430`).
  Dependency files are reported as `<Dep>/<file>` and their registrations carry
  `library = "<Dep>"` (`:179-183`, `:310`).
* With a single Guides module there are no `FastesBoooy_*` dependencies left; this code path stays
  only for the fixtures (`FastesBoooy_TestComposed` → `FastesBoooy_TestLib`).

### 1.4 Sandbox

`baseEnv()` (`route_loader.lua:53-71`): `assert error ipairs next pairs pcall select tonumber
tostring type unpack xpcall rawget rawset rawequal setmetatable getmetatable _VERSION`, copies of
`string`, `table`, `math`, and `_G`. No `io`, `os`, `require`, `load*`, `print`.

`runFiles` (`:330-363`):

* every file of a module gets the varargs `(moduleName, private)`, where `private` is **one table
  shared by all files of the module** (`:333`, `:349`), like the client's `local _, ns = ...`;
* each file gets a fresh environment whose only extra global is the stub `FastesBoooy` (`:346-348`);
* any global the file defines is a load error "defines global 'x'" (`:351-357`).

The stub API (`:236-327`): `RegisterRoute`, `AddSegment`, `AddRouteData`, `UseSegments`,
`AddInsert`, `AddLibrarySegment`, `AddLibraryData`. It normalizes with the real
`Core/Schema.lua` and composes with the real `Core/Compose.lua` (`Loader.LoadSchema`, `:78-100`).
Registrations for a route that is not registered yet are an error and are queued (`:225-234`,
`:264-307`). After all files ran, each route is composed with `Compose.Build` (`:457-463`).

`.luacheckrc` is stricter than the sandbox: files under `addons/FastesBoooy_*/**` and the fixtures
get `std = "fastesboooy_route"` (`.luacheckrc:129-142`, `:161-163`, `:195-200`), which defines only
`FastesBoooy.{RegisterRoute, AddSegment, AddRouteData, UseSegments, AddInsert, AddLibrarySegment,
AddLibraryData}`. Reproduced on the prototype:

```
addons/FastesBoooy_Guides/Route.lua:4:22: (W113) accessing undefined variable pairs
addons/FastesBoooy_Guides/Route.lua:5:19: (W113) accessing undefined variable ipairs
```

`local _, ns = ...` is accepted. The spec `tests/spec/validator_lint_spec.lua:85-92` pins "route
modules may only read FastesBoooy" (it checks `C_QuestLog` and `FastesBoooyDB`, not `pairs`).

### 1.5 Where "a route in a declared library module is a load error" lives

`route_loader.lua:464-468`:

```lua
mod.isLibrary = #mod.routes == 0 and (#mod.librarySegments > 0 or mod.libraryData or mod.declaredLibrary or false)
if mod.declaredLibrary and #mod.routes > 0 then
    addError("## X-FastesBoooy-Module: library, but the module registers route(s): ...", mod.tocFile)
end
```

Pinned by `tests/spec/validator_harness_spec.lua:507-525`. The in-game `Core/Registry.lua` has no
such rule at all (the TOC field is never read by the client).

What "library module" changes in each tool:

| Tool | `mod.isLibrary` true | module with routes **and** library segments (not declared) |
|---|---|---|
| validator `ValidateModule` (`validator.lua:1941-2007`) | one entry "library module X [library: N segment(s), M step(s)]" with only its load errors (`:1945-1954`) | no library entry; every route is validated; library-step messages are tagged `[library FastesBoooy_Guides]` |
| validator `Main` (`:2551-2560`) | its load errors are reported once; skipped when `--route` is given | not special |
| simulator (`simulate_routes.lua:1554-1556`) | "skip …: library module" | every route is simulated |
| `gen_route_data.Render` (`:273-301`) | `AddLibraryData({...})` | `AddLibraryData({...})` **and** one `AddRouteData` per route (`:284-299`) |
| harness (`harness.lua:386-390`) | works | **fatal**: "registers route(s) (…): --harness takes a library module", exit 2 |

### 1.6 Prototype: one module with shared segments, routes and class files

Built in the scratch area as `addons/FastesBoooy_Guides` (TOC with `Route.lua`, `Data.lua`,
`Segments\Tirisfal\01_Deathknell.lua`, `Segments\Tirisfal\02_Brill.lua`, `Classes\Paladin.lua`,
`Classes\Warrior.lua`; two routes `undead-paladin`, `undead-warrior` registered in a loop, the
route id list passed between files through `ns`). Results:

| Check | Result |
|---|---|
| `validate_routes.lua <dir>` | both routes validated, 0 errors |
| `simulate_routes.lua <dir>` and `--route undead-warrior` | both `OK` |
| `gen_route_data.lua` / `--check` | writes `AddLibraryData` + two `AddRouteData`; up to date |
| `validate --route … --write-state … --until tl-brill` | state written |
| `package_addons.py --addons …` | zip holds `Classes/…`, `Segments/Tirisfal/…` |
| `--harness <dir>` (both tools) | exit 2, "registers route(s)" |
| TOC with `## X-FastesBoooy-Module: library` | 1 load error |
| `Data.lua` listed before `Route.lua` in the TOC | `ERROR … AddRouteData: route … is not registered yet` (`route_loader.lua:285-288`) |
| luacheck | `W113` for `pairs` / `ipairs` |

Subdirectories in TOC paths are therefore supported by the loader, the validator, the simulator
(mock), `gen_route_data` (`DataPath`, `:304-309`, accepts `Data.lua` in a subdirectory too), the
packager (`os.walk`, `tools/package_addons.py:38-46`) and the luacheck globs
(`addons/FastesBoooy_*/**/*.lua`). Nothing has to change for them.

### 1.7 What must change so one module holds shared segments, shared inserts and 28 routes

Required:

1. **TOC**: do not declare `library`. Order: `Route.lua` (all `RegisterRoute`) before any file that
   calls `AddRouteData` / `UseSegments` / `AddInsert`; `AddLibrarySegment` / `AddLibraryData` may
   come in any order because composition is lazy (`Compose.Build` at the end of the load,
   `route_loader.lua:457-463`; in game `Registry:Finalize`).
2. **Harness** must accept a module with routes: drop the `#mod.routes > 0` fatal
   (`harness.lua:386-390`) and build the synthetic route from `mod.lib` as today. The harness route
   id `harness-<Name>` (`harness.lua:352-354`) does not collide with `<race>-<class>` ids. In the
   simulator the whole module is loaded into the mock and the harness route is then selected with
   `Engine:SetRoute` (`simulate_routes.lua:1003-1018`), which already works when other routes
   match the player. The spec `validator_harness_spec.lua:195-200` ("refuses route modules") pins
   the old behaviour.
3. **Shared inserts** (new API, e.g. `FastesBoooy.AddLibraryInsert{ after | before, steps }`):
   * core: `Compose` (library store gets an insert list; `Build` applies it), `Registry`, `Init`
     (public API table);
   * loader stub next to `api.AddLibrarySegment` (`route_loader.lua:309-317`), tagging the steps
     with `file` and a "shared" marker;
   * `.luacheckrc:135-139` (field list) and its header comment;
   * `gen_route_data.CollectLibraryIds` (`:119-125`) walks only `mod.librarySegments`; it must also
     collect the shared inserts, otherwise their quests / NPCs are in nobody's data (see 5.3);
   * validator: see 2.9 for `step-no-profile` and message tagging.
4. **`.luacheckrc`**: add the pure Lua base the sandbox already offers to `fastesboooy_route`
   (`ipairs pairs type tostring tonumber select unpack next string table math`), or write the 28
   `RegisterRoute` calls out by hand. Without one of the two, a table-driven `Route.lua` cannot
   pass `make lint`.
5. **Validator presentation**: with everything in one module every shared-step message would read
   `[library FastesBoooy_Guides] …` and the Markdown header would have no library section. Rename
   the tag to something like `[shared]` and add a module-level "shared steps" entry (see 4.3).
6. **Error isolation** for parallel work (see 11.2).

Not required (already works): subdirectories, `ns` sharing between files, `--route`, `--until`,
`--write-state`, packaging, `routedata-check`.

Composition facts that matter for the design of shared inserts (`Core/Compose.lua`):

* Library segment steps are shallow-copied **per route** and cached (`libraryEntry`, `:259-275`),
  so per-route mutation is safe. Steps of an `AddInsert` are *not* copied: `Build` writes
  `s.id`, `s.segment`, `s.segIndex`, `s.insertSide` into the insert's own step tables (`:356-362`).
  A shared insert applied to several routes must copy its steps per route.
* An insert whose anchor is missing is an error per route ("unknown anchor step", `:371-374`).
  Reproduced: one bad anchor in `Classes/Warrior.lua` produced one error **per route** and failed
  the simulation of the paladin route as well. A shared insert needs the opposite rule: "applied
  where the anchor exists", plus one error when the anchor exists in no route at all.
* Inserted steps belong to the anchor's segment (`:359-360`); several inserts at one anchor keep
  call order (`:335-368`). With nine class files loaded in TOC order, the TOC order of
  `Classes\*.lua` becomes the order of class steps at a shared anchor. That is harmless as long as
  each step is class-filtered, but it is the reason anchors should be stable ids.
* Library step ids are unique across the whole library (`lib.scratch`, `:86-91`, `:108`), and
  duplicates between own / library / inserted steps are composition errors (`:385-394`).

---

## 2. Validator

Entry: `tools/validate_routes.lua` (17 lines) → `V.Main` (`tools/lib/validator.lua:2479-2617`).

### 2.1 How profiles are enumerated

`V.Profiles(route, override)` (`validator.lua:122-143`): the cross product of `route.races` ×
`route.classes` (sorted keys). Faction: `override.faction`, else `route.faction`, else
`RACE_FACTION[race]` (`:71-74`); a `Skyborne` route without a faction gets both sides
(`BOTH_SIDES`, `:76`, `:132-136`). `--profile k=v` **replaces** the race / class / faction of every
route (`:124-125`, call at `:1958`).

For the new layout (28 routes, each `races = { one }`, `classes = { one }`, `faction = "Horde"`)
this gives exactly one profile per route, 28 runs in total.

Per route (`ValidateModule`, `:1955-1983`): `V.RunProfile` for every profile, then
`dedupeLibraryMessages` over the profiles of that route (`:1914-1930`, `:1967`), then
`V.RouteChecks` once per route, attached to the first profile (`:1969-1981`).

### 2.2 One run (`V.NewRun`, `:158-207`; `Run:execute`, `:1676-1711`)

* State: `st = {level = 1, xp = 0}`, the optimistic twin `opt`, quest log (`active`), `accepted`,
  `turnedIn`, `abandoned`, `completed`, `credited` objectives, `collected` items, hearth, flight
  paths (`:160-181`).
* Masks: `raceMask` from `enums.raceFileToBit` (Skyborne by faction), `classMask`, side letter
  `H` / `A` (`:182-204`).
* Walk: for every segment `beginSegment`, every step `processStep`, `endSegment` (`:1681-1687`).
* `processStep` (`:1439-1469`):
  1. `--until` snapshot (`:1441-1446`);
  2. filter: `Schema.FiltersMatch(step.filters, facts)`; a filtered step is `INFO step-skipped`
     and counted in the segment (`:1447-1455`);
  3. worst case: an `optional` step is skipped (`:1456-1459`);
  4. `checkEntities` (positions; not in shadow runs, `:1463`);
  5. actions in player order (`V.OrderedActions`, `:1328-1354`): abandon → complete / collect of
     quests already in the log → turn-ins → accepts → complete / collect of quests accepted by this
     step → their turn-in → the rest.
* After the walk: `checkSkipAhead`, `checkLookaheadSkip` (`:1689-1694`), `quest-carried` for every
  quest left in the log (`:1695-1704`), `route-level` (`:1705-1709`).

### 2.3 Per-profile checks by action

| Action | Checks | Code lines |
|---|---|---|
| any step | uiMap known; each `npc` / `object` exists, nearest spawn on `at.map` within 40 / 120 yards (or 3 / 8 map units on maps without size); accept / turnin without `npc`: `at` near a giver / ender | `:602-674`, distances `:527-600` |
| `accept` | quest exists (`:387-399`); side, race mask, class mask (`:840-859`); profession (`:864-885`); `reqLevel` against the nominal and the optimistic level (`:893-907`); `maxLevel` (`:908-911`); duplicate / already done (`:912-922`); `preGroup` all, `preSingle` one (`:923-941`); exclusive both ways (`:942-955`); `untilCompleted`, `disabledBy` (`:957-968`); parent (`:969-972`); breadcrumbs (`:973-983`); giver NPC / object (`:984-1009`); log capacity (`:1019-1024`) | `H.accept` `:887-1025` |
| `turnin` | accepted / twice / abandoned; `complete` step seen; partial objectives; objective items; ender NPC / object; quest XP | `H.turnin` `:754-838` |
| `complete` | quest in the log; area trigger position; objective indices; kill and drop XP | `H.complete` `:1067-1148`, trigger `:1033-1065` |
| `abandon` | quest in the log | `:743-752` |
| `collect` | marks the item collected | `:1150-1156` |
| `level` | grind to the threshold, gate record | `:1158-1195` |
| `train` | trainer of the profile's class | `:1212-1242` |
| `fp` / `fly` | flight path learned before a `fly`; NPC is a flight master | `:1244-1266` |
| `sethearth` / `hearth` | NPC is an innkeeper; bind place matches | `:1268-1289` |
| `vendor` | NPC sells / repairs | `:1291-1298` |
| service NPCs | friendly to the route side | `serviceNpcs` `:1197-1210` |

### 2.4 Trainers: how the validator knows which NPC trains which class

`H.train` (`:1212-1242`), with `CLASS_NAMES` (`:65-69`):

```lua
local cls = self.profile.class and CLASS_NAMES[self.profile.class]   -- "Warrior"
local sub = (n.sub or ""):lower()
local ok = sub:find(c .. " trainer", 1, true) or (flags.trainer and sub:find(c, 1, true))
```

* OK when the NPC sub name contains `"<class> trainer"`, or the NPC has the trainer flag and the
  sub name contains the class name (so "Grand Master Rogue" Fahrad 6707 is fine for a ROGUE, "High
  Priest" Zayus 5994 for a PRIEST).
* Not OK and (trainer flag **and** sub contains "trainer" **and** sub names no class) →
  `WARN train-not-class-trainer`.
* Otherwise `ERROR train-wrong-trainer`.
* No `npc` on the step → `WARN train-no-npc`.

There is no spell list, no trainer level, no "which ranks at which level" model. The step key
`spells` is only shown in game and fed to the mock trainer window.

DB coverage (probe over `db.npcs`, sub name `"<Class> Trainer"`, usable by the Horde):

| uiMap | Classes with a trainer |
|---|---|
| 1411 Durotar | Warrior, Hunter, Rogue, Priest, Shaman, Mage, Warlock |
| 1412 Mulgore | Warrior, Hunter, Shaman, Druid |
| 1420 Tirisfal Glades | Warrior, Paladin, Rogue, Priest, Mage, Warlock |
| 2521 Zephras Isle | Warrior, Hunter, Rogue, Shaman, Druid, **Mage** (2 with faction `AH`, 1 `A`) |
| 1454 Orgrimmar | Warrior, Hunter, Rogue, Priest, Shaman, Mage, Warlock |
| 1456 Thunder Bluff | Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Mage, Druid |
| 1458 Undercity | Warrior, Paladin, Rogue, Priest, Mage, Warlock |

This matches the decided combos for Orc + Troll (Durotar), Tauren (Mulgore) and Undead (Tirisfal).
On Zephras the Shaman trainers are `H`-only and the Mage trainers are `AH`; whether a Horde
Skyborne Mage exists is not decidable from the trainer data (see 9.6).

Verdicts for non-class trainers, reproduced with a WARRIOR profile:

| NPC (sub name) | Verdict of `train = true` |
|---|---|
| 2704 Hanashi, 11868 Sayoc, 11869 Ansekhwa, 11870 Archibald ("Weapon Master") | **ERROR** `train-wrong-trainer` |
| 4752 Kildar ("Wolf Riding Instructor"), 3690 Kar Stormsinger ("Kodo Riding Instructor"), 4773 Velma Warnam ("Undead Horse Riding Instructor") | **ERROR** `train-wrong-trainer` |
| 7953 Xar'Ti ("Raptor Riding Trainer"), 265756 Genn Fairweather ("Stablemaster and Riding Trainer") | WARN `train-not-class-trainer` |
| "Pet Trainer" (3620, 3688, 10086, 10088, 254411 …), "Portal Trainer" (5958 Thuul …) | WARN `train-not-class-trainer` |
| profession trainers without "trainer" in the sub name ("Expert Blacksmith" …) | ERROR |

So weapon-skill steps and the level-40 riding steps of Orc / Tauren / Undead cannot be written as
`train` steps today without validator errors. Either the validator learns these categories (sub
name contains "weapon master" / "riding" / "pet trainer" / "portal trainer" with the trainer flag →
accepted, INFO) or such steps use another action.

### 2.5 Flight masters, innkeepers, vendors

* `fp X` records `flightPaths[X]`; `fly X` without it → `WARN fly-unknown-fp` (`:1244-1251`).
  With an `npc`: must have `flags.flightmaster`, else `ERROR not-flightmaster` (`:1258-1263`);
  `fp` without `npc` → `INFO fp-no-npc`.
* `sethearth X`: NPC must have `flags.innkeeper` (`ERROR not-innkeeper`), no NPC →
  `WARN sethearth-no-npc`; the place is remembered (`:1268-1279`). `hearth X` compares with the last
  `sethearth` (`WARN hearth-mismatch`, `INFO hearth-unbound`) (`:1281-1289`).
* Every service NPC must be friendly to the route side (`ERROR npc-hostile`, `:1197-1210`).
* Place names are free strings; nothing checks that a flight master actually serves place `X`.

Start-zone service NPCs present in the DB: innkeepers Grosk 6928 (Durotar), Kauth 6747 (Mulgore),
Renee 5688 (Tirisfal), Coriella Calmbreeze 254089 / Donaal Downbreeze 255940 (Zephras); flight
masters Doras 3310 (Orgrimmar), Tal 2995 (Thunder Bluff), Michael Garrett 4551 (Undercity),
Devrak 3615 / Omusa Thunderhorn 10378 / Bragok 16227 (Barrens). The start zones themselves have no
flight master.

### 2.6 Quest-log cap

`questlog-full` (`:1019-1023`): after each accept, `activeCount > db.questLogSize` (40) is an
ERROR. A start state that already overflows is an ERROR on the pseudo step `start-state`
(`:238-242`). `summary.maxQuestLog` is reported (23 for both routes today).

### 2.7 Level simulation and XP estimation

All formulas are in `tools/lib/fbdb.lua`:

* XP table `db.xp.levels`; `DB.AddXp` (`:328-342`), `DB.LevelValue` (`:345-349`), cap 60.
* Quest XP: `DB.QuestXp(base, questLevel, playerLevel)` (`:262-270`), multiplier
  `clamp(2*(qL-pL)+20, 1, 10)/10`, client rounding (`:253-258`).
* Unknown quest XP (974 of 3,095 snapshot quests): `DB.EstimateQuestXp` = median known XP of the
  same quest level, nearest level within ±10 (`:274-282`, medians built at `:38-51`) →
  `WARN xp-unknown` (`validator.lua:693-702`).
* Mob XP: `DB.MobXp` (`:293-315`): `5*pL+45`, +5 % per level above (max 4), grey = 0, Forever green
  penalty 4 % per level (max 20 %), elite ×2.
* Kills in `complete` (`validator.lua:1107-1139`): a creature / killCredit objective counts as a
  kill only when `nonKillReason` finds no reason (`:446-470`: icon talk / interact / event, NPC not
  in the snapshot, any NPC flag, quest giver, friendly faction unless a known count ≥ 2). Unknown
  count: 1 for a unique NPC, else 4 (`assumedKills`, `:496-505`). Item objectives: 1.5 kills of the
  first killable drop source per item (`:1124-1136`, `dropSource` `:509-518`).
* `level` step: grind with same-level normal mobs until the threshold (`:1158-1195`); the number of
  kills is the gate's `kills`; `WARN level-grind` above 30 kills, else INFO.
* Optimistic twin (`opt`): unknown quest XP × 2.0, assumed kills × 1.5, and a `level` step lifts it
  to the threshold (`:1161-1162`). `accept` below `reqLevel`: ERROR `level-too-low` only when even
  the optimistic level is too low, else WARN `level-too-low-estimated` (`:893-907`).
* `--incidental-pct P`: every turn-in also gives P % of its quest XP as kill XP (`:708-712`).
* Not modelled: rested XP, group XP, drop rates, travel time, deaths, gold.
* Segment plan: `segment-level` when the simulated end level differs from `levels[2]` by more than
  1 (`:1313-1326`); `route-level` likewise for the route (`:1705-1709`).

Numbers today (the scale the design is judged by):

| Route | End level | Worst-case end | Grind kills | Worst case | With 15 % incidental | Unknown-XP quests | Steps |
|---|---:|---:|---:|---:|---:|---:|---:|
| horde-undead-paladin | 60.00 | 60.00 | 4,972 | 6,179 | 3,954 (worst 5,271) | 77 | 1,717 |
| horde-skyborne-druid | 60.00 | 60.00 | 4,878 | 6,082 | 3,883 (worst 5,172) | 126 | 1,752 |

Almost all grind is in the shared 22-60 segments (h-37 1,008, h-41 765, h-46 618, h-56 1,304 kills);
the two 1-22 parts need 75 and 0 kills.

### 2.8 Shadow runs: worst case and incidental band

`V.RunProfile` (`:1791-1850`):

* main run with the options as given;
* `get(pct, worst)` creates shadow runs with `shadow = true` (no position checks) and `keepCodes`
  so they add no messages, except the worst case at the main percentage, which keeps
  `optional-dependency` (`KEEP_WORST`, `:1748`, `:1805`); those messages are merged into the main
  list at the right step (`mergeShadowMessages`, `:1758-1777`);
* runs: `mainPct:normal` (= main), `mainPct:worst`, `0` and `15` (`incidentalBandPct`) each normal
  and worst; identical keys are reused and a route without `optional` steps has no worst run
  (`:1796-1811`). With the default `--incidental-pct 0` that is **4 simulations per route×profile**
  (2 without optional steps).
* Worst case (`:1356-1426`): `optional` steps are not executed (`skipOptional`); later
  `complete` / `turnin` / `abandon` of quests accepted only there are skipped; on a non-`bg`
  required step that is `ERROR optional-dependency`, likewise an `accept` whose prerequisite is
  turned in only by an optional step (`worstSkip`). An optional `level` step is not done, its
  grind moves to the next gate.
* Results added to the summary (`:1814-1848`): `grindKillsWorst`, `xpGrindWorst`, `endLevelWorst`,
  `optionalSkipped`, `optionalAccepts`, `band["0"|"15"]`, per segment `grindKillsWorst`,
  `optionalSkipped`, `band`, per gate `killsWorst`, `band`.

### 2.9 Route-level checks: `unknown-race-token`, `step-no-profile`

`V.RouteChecks(db, route, profiles)` (`:1860-1910`), once per route:

* every race token of the route and of every step filter must be a key of `enums.raceFileToBit`
  (`Dwarf Gnome Goblin Human NightElf Orc Scourge Skyborne Tauren Troll`), else
  `ERROR unknown-race-token` (hint for `Undead` → `Scourge`);
* every filtered step must match at least one of **this route's** profiles, else
  `WARN step-no-profile` (`:1891-1907`). Skipped for harness routes (`route.harness`).

With 28 single-profile routes this check is wrong by construction: every class-filtered shared
step is "never shown" in 27 of 28 routes (or in all routes of other classes). The prototype shows
it already with two routes: each route warns about the other class's trainer step. Today's library
has 8 such steps (race filters in `h-22-hillsbrad` and `h-24-barrens-stonetalon`), each commented
`-- WARN-OK: step-no-profile`.

Proposal (validator only):

* in `RouteChecks`, skip steps that are shared (library segment step or shared-insert step);
* add one run-level pass over all validated routes: for each shared step id collect the profiles
  of every route whose composed steps contain it; `WARN step-no-profile` once (in the shared
  entry, see 4.3) when no route's profile matches it. Add `WARN shared-unused` when a shared
  segment or shared insert is used by no route at all (today a library may hold unused segments
  silently, fixture `tl-unused`);
* the pass needs all routes of the module, so with `--route X` it must be skipped or still run over
  the whole loaded module (the module is always loaded completely).

A cleaner fix at the source is to make shared inserts drop, at composition time, steps whose
filters can never match the route's `races` × `classes`. Then a warrior route does not carry the
steps of eight other classes at all (less memory in game, no `step-skipped` INFO noise, correct
step counts), and `step-no-profile` only has to cover "matches no route".

### 2.10 `--state`, `--write-state`, `--until`, `--harness`

* State format and parsing: `tools/lib/harness.lua:44-230` (`level`, `xpFrac`, `done`, `log`,
  `complete`, `hearth`, `hearthAt`, `at`, `flightPaths`, `meta`); unknown keys and inconsistencies
  are errors, all listed.
* `--state FILE` → `opts.startState` → `Run:applyState` (`validator.lua:212-257`): level / XP for
  both simulations, `done` → `turnedIn`, `log` → `active` (counts against the log), `complete` →
  all objectives credited, hearth, flight paths. Unknown quests → `ERROR quest-unknown` on the
  pseudo step `start-state`.
* `--write-state FILE`: `Run:EndState` (`:277-303`), written by `Main` (`:2591-2614`); needs exactly
  one route × profile (exit 2 otherwise).
* `--until ID` (only with `--write-state`): the state **before** step `ID` or the first step of
  segment `ID` (`:1441-1446`, result `:1739-1740`); unmatched id → exit 2 (`:2602-2606`).
* `--harness DIR [--segments a,b]` with a mandatory `--profile` (race and class; faction derived,
  required for Skyborne; `Harness.Profile`, `harness.lua:330-343`): `Harness.Build`
  (`harness.lua:375-424`) loads the module, registers `harness-<Name>` for the one profile and
  `UseSegments` of the listed library segments, **nothing else** (no own segments, no inserts);
  `V.ValidateHarness` (`validator.lua:2012-2049`). In a harness run `quest-carried` is INFO and
  `step-no-profile` is not reported.
* Caveat documented in `tools/README.md:725-736`: a written state includes what optional steps
  gave; simulator states have lower levels (no kill XP), so chains should use validator states.

For the redesign the harness is the natural per-agent tool ("my start-zone segments from level 1",
"the shared Barrens segment from the end state of my start zone"). It needs two extensions:
accept a module with routes (1.7), and optionally apply the shared inserts whose anchors fall
into the selected segments (otherwise class steps can only be checked in full routes).

### 2.11 Other cross-step checks

* `skip-ahead` (`:1504-1602`): a transient or optional non-`bg` step that the engine's fast-forward
  would pass over because a later step can be completed early. Reported once at the skipped step.
* `lookahead-skip` (`:1613-1674`): a visit step (`train` / `vendor` / `fp` / `sethearth`, not `bg`,
  not `optional`, with `npc`) at NPC X followed within `lookahead` = 6 walked steps by a step that
  only accepts quests of X or turns in already complete quests of X. Reported at the visit step.
  This one is directly relevant for class files: a class trainer who also gives the class quest
  (very common at levels 1-10) must have `train` merged into the quest step or placed after it.
  Note that "walked steps" are the profile's steps, so the result of this check depends on the
  class inserts present in the route.

### 2.12 Every message code

Severity as emitted; line = `tools/lib/validator.lua`. "×28" notes what happens when 28 routes
share the step.

| Code | Sev. | Line | Meaning |
|---|---|---:|---|
| `schema` | ERROR | 1999, 2038, 2042 | load / format / composition error of a file (Schema.lua, runtime error, global defined, unknown segment / anchor, duplicate ids, TOC problems). Carries the file, not a step |
| `route-empty` | ERROR | 1679 | route has no steps |
| `profile-race` / `profile-class` | ERROR | 188, 191 / 199 | unknown raceFile (or one that exists on both sides without `faction`) / class token |
| `profile-faction` | WARN | 203 | route without faction: side checks skipped |
| `unknown-race-token` | ERROR | 1878, 1887 | race token of the route or of a step filter is not a raceFile (`Undead` instead of `Scourge`) |
| `step-no-profile` | WARN | 1904 | filtered step matches none of the route's profiles (per route; see 2.9) |
| `step-skipped` | INFO | 1448 | step filtered out for this profile. ×28: one INFO per foreign class step per route unless inserts are pruned at composition |
| `quest-unknown` | ERROR | 224, 397 | quest id does not exist in Forever |
| `quest-out-of-scope` | WARN | 392 | quest exists but is outside the snapshot; NPC / prerequisite checks skipped |
| `quest-side` / `quest-race` / `quest-class` | ERROR | 845 / 852 / 856 | quest of the other faction / not for this race / not for this class |
| `quest-profession` | WARN / INFO | 873, 880 / 870 | required step accepts (or completes / turns in after an optional accept) a quest that needs a profession; INFO on an optional accept |
| `level-too-low` | ERROR | 900 | `reqLevel` above even the optimistic simulated level |
| `level-too-low-estimated` | WARN | 903 | `reqLevel` above the nominal level but reachable optimistically |
| `level-too-high` | ERROR | 909 | above the quest's `maxLevel` |
| `accept-duplicate` / `accept-done` | ERROR | 913 / 919 | already in the log / already turned in (not repeatable) |
| `accept-prereq` | ERROR | 929, 938 | `preGroup` (all) or `preSingle` (one) not turned in |
| `accept-exclusive` | ERROR | 952 | an exclusive quest is taken or done (checked both ways) |
| `accept-unavailable` / `accept-disabled` | ERROR | 959 / 965 | `untilCompleted` quest already done / `disabledBy` quest in the log |
| `accept-parent` | ERROR | 970 | parent quest not in the log |
| `breadcrumb-late` / `breadcrumb-open` | WARN | 974 / 980 | breadcrumb taken after its target / target taken with the breadcrumb open |
| `accept-wrong-npc` / `accept-wrong-object` | ERROR | 988, 992 / 1002, 1006 | step NPC / object does not start the quest |
| `accept-no-starter-data` | INFO | 996 | DB has no starter |
| `questlog-full` | ERROR | 1021, 240 | more than 40 quests in the log |
| `turnin-twice` / `turnin-abandoned` / `turnin-not-accepted` | ERROR | 760 / 765 / 768 | bookkeeping |
| `turnin-no-complete` | WARN | 771 | quest has objectives but no earlier `complete` step |
| `turnin-partial` | WARN | 785 | `complete = {[id] = {…}}` steps did not cover every objective |
| `turnin-items` | INFO | 796 | objective item not collected by a `complete` / `collect` step |
| `turnin-wrong-npc` / `turnin-wrong-object` | ERROR | 805, 809 / 818, 822 | step NPC / object does not end the quest |
| `turnin-no-ender-data` | INFO | 812 | DB has no ender |
| `complete-not-active` | ERROR | 1073, 1076 | quest not in the log |
| `complete-bad-index` | WARN | 1092 | objective index beyond the DB list |
| `complete-no-objectives` | INFO | 1099 | DB lists no objectives |
| `complete-far-from-trigger` | WARN | 1054, 1060 | exploration quest completed away from its area trigger |
| `complete-kill-xp` | INFO | 1145 | estimated kills and kill XP, **with the simulated level in the text** |
| `complete-no-kill` | INFO | 1141 | objectives that give no kill XP, with the reason |
| `collect-unknown-item` | INFO | 1152 | item not in the snapshot |
| `abandon-not-active` | ERROR | 746 | abandon of a quest not in the log |
| `quest-carried` | WARN / INFO | 1701 / 1698 | quest still in the log at the end (INFO in a harness run) |
| `optional-dependency` | ERROR | 1388, 1407, 1419 | worst case: a required step needs a quest only optional steps take / turn in |
| `skip-ahead` | WARN | 1573 | transient / optional step the engine's fast-forward can pass over |
| `lookahead-skip` | WARN | 1659 | visit step that the automation fast-forwards because a quest step at the same NPC follows within 6 steps |
| `npc-unknown` / `object-unknown` | ERROR | 620 / 634 | id does not exist |
| `npc-out-of-scope` / `object-out-of-scope` | WARN | 617 / 631 | exists, outside the snapshot |
| `at-map-unknown` | ERROR | 609 | unknown uiMapID |
| `at-no-spawn` | ERROR | 590 | NPC / object has no spawn on the `at` map |
| `at-far` | WARN / ERROR | 597 | nearest spawn farther than 40 / 120 yards (3 / 8 map units without map size; thinned spawn lists get 2·√2 units of slack) |
| `at-far-from-giver` | WARN | 660, 666 | accept / turnin step **without `npc`/`object`**: `at` is farther than the WARN threshold from every giver / ender spawn on that map, or there is none on that map. Never more than a WARN because the giver is a guess (`:665`). Typical for dungeon-entrance steps |
| `at-instance` | INFO | 582 | NPC inside an instance |
| `train-no-npc` | WARN | 1214 | `train` without NPC |
| `train-not-class-trainer` | WARN | 1231 | trainer flag and "trainer" in the sub name, but no class name (profession, riding, pet, portal) |
| `train-wrong-trainer` | ERROR | 1234, 1239 | not a trainer of the profile's class (see 2.4) |
| `fly-unknown-fp` | WARN | 1248 | `fly X` without an earlier `fp X` (or state) |
| `fp-no-npc` | INFO | 1254 | `fp` without NPC |
| `not-flightmaster` | ERROR | 1260 | `fp` / `fly` NPC has no flight-master flag |
| `sethearth-no-npc` | WARN | 1270 | `sethearth` without NPC |
| `not-innkeeper` | ERROR | 1274 | `sethearth` NPC is no innkeeper |
| `hearth-mismatch` / `hearth-unbound` | WARN / INFO | 1286 / 1283 | bound elsewhere / never bound |
| `not-vendor` | WARN | 1295 | `vendor` NPC neither sells nor repairs |
| `npc-hostile` | ERROR | 1203 | service NPC not friendly to the route side |
| `xp-unknown` | WARN | 699 | quest XP unknown, median estimate used. ×28: one WARN per turn-in per route (77 and 126 today) |
| `level-grind` | INFO / WARN | 1192 | kills needed at a `level` step (WARN above 30). **Text contains the simulated level, XP shortfall and kill count**, so it differs per route |
| `segment-level` | WARN | 1321 | simulated end level of a segment differs from `levels[2]` by more than 1. No step; attached to the segment. ×28: shared segments are entered at slightly different levels per race / class, so the text differs per route |
| `route-level` | WARN | 1707 | same for the whole route |

---

## 3. Scaling to 28 routes × 1 profile

### 3.1 Measured runtimes

Machine: 4 CPUs, Lua 5.1. One process at a time unless stated. Both current routes have about
1,715-1,750 steps.

| Command | Wall time |
|---|---:|
| `dofile` of the DB snapshot only | 0.11 s |
| `validate_routes.lua` (2 routes + library, text output) | 0.85 s |
| `validate_routes.lua -q addons/FastesBoooy_UndeadPaladin` | 0.27 s |
| `validate_routes.lua -q addons/FastesBoooy_SkyborneDruid` | 0.29 s |
| `validate_routes.lua -q --markdown …` (all) | 0.43 s |
| `validate_routes.lua -q --json …` (all) | 0.55 s |
| `validate_routes.lua -q` on the 6 fixture modules | 0.12 s |
| `gen_route_data.lua --all --check` | 0.27 s |
| `luacheck` (addons, tools, tests) | 3.1 s |
| `busted` (476 specs) | 78.3 s |
| `simulate_routes.lua addons/FastesBoooy_UndeadPaladin` | 25.8 s |
| `simulate_routes.lua addons/FastesBoooy_SkyborneDruid` | 26.0 s |
| same with `--no-reload` (UD) | 24.9 s |
| `--ahead 10` / `23` / `35` / `48` (UD) | 24.9 / 19.6 / 13.5 / 8.6 s |
| `--ahead 23` (SD) | 21.0 s |
| `--ahead 21 --ahead-at ud-04-barrens,sd-04-barrens` (UD) | 23.7 s |
| `--ahead 29 --ahead-at h-24-barrens-stonetalon` (UD) | 23.5 s |
| `--level-plus 2` / `4` (UD) | 26.3 / 11.2 s |
| `--level-plus 4` (SD) | 12.9 s |
| `simulate_routes.lua` on the 2 fixture routes | 0.38 s |
| harness simulate, 1 library segment (`h-22-hillsbrad`, 62 steps) | 0.57 s |
| harness simulate, all 12 library segments as one route (about 1,300 steps) | 15.3 s |
| harness chain, 12 segments one by one (validate + write state + simulate each) | 11.2 s (simulate part about 9.0 s) |
| `package_addons.py` | 0.09 s |
| 4 simulations with `xargs -P 4` | 27.9 s |
| 8 simulations, 4 workers | 51.6 s |
| 8 sync jobs (`--ahead 35`, `48`, `--level-plus 4`, mid-jump; both routes), `xargs -P 4 -L 1` | 49.9 s |

Peak memory: simulate 137 MB, validate 85 MB per process.

Per route today: plain simulate 25.8 s; the eight sync runs of `make simulate-sync` add up to
**151 s** (24.9 + 19.6 + 13.5 + 8.6 + 23.7 + 23.5 + 26.3 + 11.2). That matches the documented
"simulate-sync ≈ 5 min, make check ≈ 7 min" for two routes.

### 3.2 What dominates

* **Validator**: the DB load (0.11 s) plus about 0.15 s per route × profile (four passes over
  about 1,750 steps). 28 routes in one process: about 4-5 s. Nothing to optimise; no parallelism
  needed.
* **Simulator**: a sampling profile of one full run (hook every 1,000 VM instructions):

  | File | Share |
  |---|---:|
  | `addons/FastesBoooy/Core/Engine.lua` | 45.7 % |
  | `addons/FastesBoooy/Core/Steps.lua` | 27.3 % |
  | `addons/FastesBoooy/Core/Compat.lua` | 7.0 % |
  | mock (`tests/mocks/**`) | about 18 % |

  Top functions: `Engine ComputeVoid` 15.3 %, `Engine Evaluate` 14.3 %, `isMarked` 10.3 %,
  `Steps IsActionDone` 9.0 %, `questState` 6.8 %, `IsStepDone` 5.8 %. These are whole-route passes
  that run on every refresh, so the cost per played step grows with the route length: about
  2 ms per step in a 62-step harness route and 3.5 ms at 210 steps (after subtracting about 0.4 s
  of process start), 11.8 ms at 1,300 steps, 15 ms at 1,717 steps. The restart checks cost about 1 s (`--no-reload`). The DB load and the module load
  are negligible.
* Consequences: (a) simulation time is CPU-bound and parallelises perfectly across processes;
  (b) each of the 28 routes will cost about the same 26 s as today, slightly more with longer
  class files; (c) a harness run of a few segments costs about a second, which is the right
  feedback loop for agents; (d) any engine-side speed-up of `ComputeVoid` / `Evaluate` would cut
  CI time proportionally, but that is a core change, not a tools change.

### 3.3 Projection for 28 routes

| Stage | CPU time | Wall on 4 CPUs |
|---|---:|---:|
| lint (module about twice as large) | about 6 s | 6 s |
| busted, unchanged | 78 s | 78 s (about 25 s if run per spec file with `xargs -P 4`) |
| validate, 28 routes, one process | about 5 s | 5 s |
| simulate, 28 routes | 28 × 26 = 728 s | about 3.0 min |
| simulate-sync, **all 28** × 8 runs | 28 × 151 = 4,228 s | about 17.6 min |
| simulate-sync, 5 routes × 8 runs | 757 s | about 3.2 min |
| fixtures, harness fixture, routedata-check, report, package | under 5 s | 5 s |

Sequential (today's Makefile) the 28-route `make check` would take about 12 min for simulate and
70 min for simulate-sync.

### 3.4 Proposal

1. **A route list option.** Neither tool can list route ids. Add `--list-routes` (one id per line,
   discovery order) to `simulate_routes.lua` (or a tiny `tools/list_routes.lua`). Zero-change
   fallback that works today:
   `lua5.1 tools/validate_routes.lua -q | sed -n 's/^\([A-Za-z0-9_-]*\) \[.*/\1/p'`.
2. **Parallel simulate with `xargs -P`.** The pattern below was tested here on the two current
   routes (failures propagate: `xargs` exits 123 when a job fails; each job prints its output in one
   piece when it ends):

   ```make
   JOBS = 4
   SIM = $(LUA) tools/simulate_routes.lua
   # one line of simulator arguments per job
   RUN_JOBS = xargs -P $(JOBS) -L 1 sh -c 'out=`$(SIM) "$$@" 2>&1`; rc=$$?; printf "%s\n" "$$out"; exit $$rc' sim

   simulate:
   	@$(SIM) --list-routes | sed 's/^/--route /' | $(RUN_JOBS)

   # one class per race, five different classes (ids of the new layout)
   SYNC_ROUTES = orc-warrior troll-shaman tauren-hunter undead-paladin skyborne-druid
   SYNC_LEVELS = 10 23 35 48
   SYNC_MID = 21/<barrens 15-18 segment id> 29/h-24-barrens-stonetalon
   SYNC_PLUS = 2 4

   simulate-sync:
   	@{ for r in $(SYNC_ROUTES); do \
   	    for l in $(SYNC_LEVELS); do echo "--route $$r --ahead $$l"; done; \
   	    for s in $(SYNC_MID); do echo "--route $$r --ahead $${s%%/*} --ahead-at $${s#*/}"; done; \
   	    for p in $(SYNC_PLUS); do echo "--route $$r --level-plus $$p"; done; \
   	  done; } | $(RUN_JOBS)

   simulate-sync-full:            # nightly / manual: every route
   	@$(MAKE) simulate-sync SYNC_ROUTES="`$(SIM) --list-routes`"
   ```

   `make -j` with pattern rules (`sim-%`) is the alternative, but the route list comes from the tool
   and `xargs` keeps it to one recipe. The simulator must print a non-zero exit when `--route`
   matches nothing; it already does (`simulate_routes.lua:1581-1584`).
3. **Why a subset is sound for the sync runs.** The sync runs test the engine's level-sync logic
   against segment boundaries, quest logs and `questMeta`. From the Barrens on, all 28 routes share
   the same segments; they differ in the four start zones and in class inserts. One route per race
   covers every start zone (Durotar twice), and choosing five different classes covers five class
   files. `--ahead-at` takes a list and uses the first listed segment the route has
   (`simulate_routes.lua:1172-1180`), so one `SYNC_MID` entry can name a shared segment.
   A second "rotation" (the other classes) can run in the nightly job.
4. **CI budget** (single job, 4 CPUs, numbers from this machine):

   | Step | Wall |
   |---|---:|
   | checkout, apt, luarocks | about 1.5 min |
   | lint + validate + fixtures | about 0.3 min |
   | busted | 1.3 min |
   | simulate, 28 routes | about 3.0 min |
   | simulate-sync, 5 routes | about 3.2 min |
   | routedata-check, report freshness, package | about 0.1 min |
   | **total** | **about 9.5 min** |

   That leaves about 50 % headroom for a slower runner. If the hosted runner turns out slower, the
   first lever is to run the busted spec files in parallel, the second to drop `--ahead 10` and
   `--level-plus 2` for all but one route (they cost the most: 25 s and 26 s).
   Alternative with full coverage: a GitHub matrix by race (5 jobs, each simulating and sync-testing
   its own routes); every shard stays under about 8 min but setup is paid five times.
5. **`make check` for humans**: keep `check` = CI. Add `make check-fast` = lint + validate +
   fixtures + `simulate` of one route, for a one-minute loop.
6. **`make report` and `make routedata`** stay single-process (under a second each).

Pitfall: GitHub-hosted `ubuntu-latest` has 4 vCPUs only for public repositories; `JOBS` should
default to `nproc`.

---

## 4. `docs/VALIDATION.md` (`make report`)

### 4.1 Today

* `make report` = `lua5.1 tools/validate_routes.lua -q --markdown docs/VALIDATION.md`
  (`Makefile:138-139`), errors do not fail the target; CI regenerates it and fails on a diff
  (`.github/workflows/ci.yml:34-39`).
* Writer: `V.FormatMarkdown` (`validator.lua:2233-2339`). Per result: header, summary sentence,
  grind paragraph and gate table (`V.GrindMarkdown`, `:2204-2230`), segment table, a table of every
  ERROR / WARN, then **every INFO** inside `<details>` (`:2317-2328`), and a static "only in game"
  section (`V.IN_GAME_ONLY`, `:2169-2201`).
* Size: **1,188 lines, 252,485 bytes** for two routes: druid section 604 lines / 130 KB, paladin
  551 lines / 116 KB, library entry 6 lines, static part 27 lines.
* Messages: 248 WARN, 775 INFO. Per route: druid 149 WARN (48 on library steps) + 390 INFO (293
  library); paladin 99 WARN (49 library) + 385 INFO (293 library).

Naive scaling to 28 routes: about 28 × 123 KB ≈ **3.4 MB, 16,000 lines**, most of it repeated.

### 4.2 How library messages are deduplicated today

`dedupeLibraryMessages(results)` (`validator.lua:1914-1930`), called per route over its profiles
(`:1967`): a message with `m.library` whose key
`severity \0 code \0 (stepId or segment) \0 msg` was already seen in an earlier **profile of the
same route** is dropped; the count is `libraryRepeats` (JSON only). Pinned by
`tests/spec/validator_compose_spec.lua:212-234`.

It does nothing across routes, and with one profile per route it does nothing at all.

Measured cross-route overlap of the two current routes (same key): only **35 of 49** library WARN
and **207 of 293** library INFO of the second route are textually identical to the first. The
rest differ because the text embeds run state: `complete-kill-xp` ends with "level now 23.45",
`level-grind` contains the simulated level, the XP shortfall and the kill count, `segment-level`
the simulated end level. A text-keyed dedupe across 28 routes would therefore leave a large
remainder.

### 4.3 Proposal

Structure of the generated file:

1. Header and totals (as today), plus counts of unique versus total messages.
2. **Route summary table**, one row per route: route id, profile, ERROR / WARN, end level, worst
   end level, grind kills (normal / worst), with 15 % incidental (normal / worst), unknown-XP
   quests, max quest log, steps, number of optional steps. This is the table the speed principle
   needs; 28 rows.
3. **Path comparison**: per start zone (4 rows) and for the shared path: level at the merge point
   (min-max over the routes using it) and grind kills up to the merge, so "merge earlier or later"
   can be read from one table.
4. **Shared steps**: all ERROR / WARN on shared steps, deduplicated across routes with the key
   `(severity, code, stepId or segment, quest id if any)` instead of the full text. One row per
   key with a "routes" column ("all 28", "all 7 troll-*", or up to three ids + count). For the
   run-dependent codes (`level-grind`, `segment-level`, `level-too-low-estimated`) show the range
   over the routes (kills 109-131, end level 30.9-31.2) instead of one number.
5. **Gate matrix**: one table "gate × route kills" for the shared gates (gates are shared steps),
   or min / max / worst over routes, instead of 28 copies of a 26-row gate table.
6. **Per-route sections**: only what is specific to the route (class and race steps): its
   non-shared ERROR / WARN and a compact segment table. Expected to be short.
7. **INFO**: not written to the Markdown at all, only a count per code per route. The full list
   stays in `--json` and `-v`. Today INFO is two thirds of the file.
8. Static "only in game" section.

Estimated size: summary 30 lines + path comparison 10 + shared WARN (28 library `xp-unknown`, 12
gates, start zones: about 50 for Tirisfal, about 100 for Zephras, similar for Durotar and Mulgore)
about 350 rows + gate matrix 30 + 28 route sections of about 25 lines each ≈ 1,100-1,300 lines,
roughly the size of today's two-route file.

Implementation notes:

* The dedupe needs each message to carry stable keys: add `quest`, `npc` and numeric fields
  (`kills`, `level`) to the message record in `Run:add` callers, so the report does not parse
  text. `m.library` (or a new `m.shared`) is already set from `step.library` (`:315-325`).
* Text and JSON output can keep the per-route lists (a route's own view must stay complete for
  `--route X`); only the Markdown and an optional `--summary` text mode aggregate.
* The report is committed and checked for freshness in CI. Every content change by any agent
  changes it, so it must be regenerated by one owner at integration time (see 11).
* A design measure that makes the shared part exact: if every route enters the shared path at the
  same level (a `level` gate at the merge point), all downstream numbers are identical for routes
  of the same class, and differ between classes only by class-quest XP.

---

## 5. `gen_route_data.lua` and `Data.lua`

### 5.1 What `Data.lua` contains

One generated file per module (`M.Render`, `gen_route_data.lua:273-301`), body by `renderBody`
(`:217-268`):

| Key | Content | Source |
|---|---|---|
| `quests` | `[id] = "enUS name"` for every quest in `accept` / `turnin` / `complete` / `abandon` and `reward` keys | `DB.QuestBrief` (snapshot or index) |
| `npcs` | `[id] = "enUS name"` for every `npc` of a step | `DB.NpcBrief` |
| `objects` | every `object` of a step | `DB.ObjectBrief` |
| `items` | `collect` items and `use` | `db.items` (missing items are silently left out, `:232`) |
| `places` | `["Brill"] = { area = 159, en = "Brill", ru = "Брилл" }` for `fp` / `fly` / `sethearth` / `hearth` places | `area` = smallest AreaTable id with that enUS name (`M.AreaIds`, `:128-134`); `ru` from `M.PLACE_NAMES_RU` (`:60-72`) |
| `questMeta` | `[id] = { level, reqLevel, preAll, preAny, items }` | snapshot record (`M.QuestMeta`, `:182-199`); index-only quests get level / reqLevel only |

`quests` and `npcs` are always written, even empty (`:236-243`). Ids not found in the DB are
reported on stderr (`:367-369`). A module with any load error gets no output and exit 1
(`:357-361`). Output is sorted and deterministic; `--check` compares byte for byte (`:376-382`).

### 5.2 Libraries versus routes today

* The generator loads the module with its own `Data.lua` skipped (`:349-353`).
* Library part: `AddLibraryData({...})` when the module registered library segments or is a
  (declared) library (`:284-290`); ids from `M.CollectLibraryIds` = steps of `mod.librarySegments`
  (`:119-125`).
* Route part: one `AddRouteData("<id>", {...})` per route registered by the module, sorted by id
  (`:291-299`); ids from `M.CollectIds` = the composed route's steps **without** `step.library`
  (`:110-116`), i.e. own segments and `AddInsert` steps.
* In game, library data is merged under route data, route values win, `questMeta` per quest
  (`Compose.Build` step 4, `Core/Compose.lua:409-413`; `MergeData`, `:62-79`).

Sizes today:

| File | Lines | Bytes | quests | npcs | objects | items | places |
|---|---:|---:|---:|---:|---:|---:|---:|
| `FastesBoooy_Horde/Data.lua` (22-60) | 1,627 | 77,377 | 535 | 336 | 108 | 65 | 30 |
| `FastesBoooy_UndeadPaladin/Data.lua` (1-22 + inserts) | 562 | 26,129 | 178 | 144 | 24 | 10 | 10 |
| `FastesBoooy_SkyborneDruid/Data.lua` (1-22 + inserts) | 612 | 29,090 | 193 | 148 | 35 | 13 | 12 |
| union of the three | about 2,410 | about 115 KB | 804 | 521 | 149 | 84 | 33 |

(about 47.5 bytes per line; `questMeta` has one line per quest.)

### 5.3 What changes when every segment is shared and routes own nothing

Observed on the prototype (shared segments + per-route `AddInsert` of class steps): the generator
writes the shared data once, and then **every route block repeats the ids of all class inserts**
that were added to it, including those filtered out for the route:

```lua
FastesBoooy.AddRouteData("undead-paladin", { quests = {}, npcs = { [2119] = …, [244808] = … } })
FastesBoooy.AddRouteData("undead-warrior", { quests = {}, npcs = { [2119] = …, [244808] = … } })
```

With 28 routes and nine class files that would be 28 copies of all class data. Required changes:

1. Shared inserts must count as library content: `CollectLibraryIds` has to walk the library's
   shared inserts as well as its segments. (If shared-insert steps are tagged `step.library`,
   `CollectIds` already excludes them from the route part, and without change 1 they would be in
   **nobody's** data.)
2. Do not write an `AddRouteData` block for a route that owns nothing (today it would be 28 blocks
   of `quests = {}, npcs = {},`). Then `Data.lua` holds only `AddLibraryData` and its position in
   the TOC no longer matters (see the ordering error in 1.6).
3. `Compose.Build` merges library data into a route only when `#route.uses > 0` (`:410`); routes of
   the new layout always use shared segments, so that holds.
4. `README` / help texts and the spec `validator_compose_spec.lua:262-304` describe the two-module
   split.

Everything else (`questMeta`, places, `--check`, `DataPath`) is unaffected.

### 5.4 Size estimate for one module with all zones

Estimate, not a measurement: today's union is about 2,400 entries (115 KB). Additions:

* Durotar and Mulgore start zones, 1-12: comparable to the first two undead / skyborne segments,
  about 70-90 quests + 60-80 NPCs each, with `questMeta` about 250 entries each;
* seven more classes (class quests, trainers in several cities, weapon masters): about 60-100
  entries per class, about 700 in total;
* minus the overlap of the two current 15-22 Barrens / Stonetalon / Ashenvale parts once unified.

Total about 3,500-3,800 entries, **about 165-180 KB, 3,600-3,900 lines**, one `AddLibraryData` call.
That is far below Lua 5.1's limits (about 262,144 constants per function; the file has roughly two
constants per line). In game the table is built once at load; names are only fallbacks (5.5).

### 5.5 Locale data: where ruRU names come from

* `Data.lua` holds **enUS names only**, taken from the DB snapshot. There are no ruRU quest, NPC,
  object or item names anywhere in the generated data.
* In game the localized quest title comes from the client first
  (`Compat.GetQuestTitle` → `C_QuestLog.GetTitleForQuestID`), then route data, then "Quest #id"
  (`addons/FastesBoooy/Core/Steps.lua:309-316`); items likewise. So on a ruRU client the enUS
  names show only when the client has no data for the id.
* Places: `area` lets the addon ask the client for the localized area name
  (`Compat.AreaName` → `C_Map.GetAreaInfo`, `Core/Compat.lua:488-494`); `ru` is a fallback from the
  hand-maintained table `M.PLACE_NAMES_RU` in `gen_route_data.lua:60-72` (11 entries: Brill, Camp
  Taurajo, Orgrimmar, Ratchet, Sun Rock Retreat, The Crossroads, The Sepulcher, Thunder Bluff,
  Undercity, Valanaar, Zoram'gar Outpost). Of the 30 library places only 9 have `ru`. A place with
  neither `area` nor `ru` is left out and noted on stderr (`:258-261`).
* New places of the Durotar / Mulgore zones (Razor Hill, Sen'jin Village, Bloodhoof Village, …)
  get `area` automatically when the name is in `db.areaNames`; a `ru` fallback needs a new line in
  `PLACE_NAMES_RU`, which is a single shared table in a tool file (ownership matters, see 11).
* Hand-written data in any locale remains possible through `AddRouteData` / `AddLibraryData` with
  `{ ru = …, en = … }` values (fixture `tests/fixtures/core/FastesBoooy_TestRoute/Locale.lua`).
* Route titles, segment titles and step notes are bilingual tables in the route files themselves.

---

## 6. `-- WARN-OK` and `--strict`

### 6.1 `-- WARN-OK` is a convention, not a mechanism

No tool reads these comments. The only occurrences of the string in `tools/` are two code comments
(`validator.lua:1503`, `:1612`) and the README row for `skip-ahead` (`tools/README.md:520`), which
say where the comment "goes". `docs/ROUTE_FORMAT.md:123` and the three `docs/routes/*.md` files
describe the convention: every WARN that was reviewed gets `-- WARN-OK: <code> (reason)` on the
step's first line (or `-- WARN-OK (<code>, next step): …` on the line above, or above `levels` for
`segment-level`).

Counts in `addons/`: 184 comments: `xp-unknown` 151, `level-grind` 17, `step-no-profile` 8,
`at-far-from-giver` 4, `segment-level` 2, `train-not-class-trainer` 1, `fly-unknown-fp` 1.

There is no per-step and no per-file suppression. The only suppression is global by code:
`--ignore code,code` (`validator.lua:2448-2449`; applied in `Run:add`, `:307-311`, and for the
route-level checks at `:1972-1973`); suppressed messages are counted (`, N suppressed`).

### 6.2 `--strict`

`--strict` makes any WARN fail the run: `if te > 0 or (o.strict and tw > 0) then return 1`
(`validator.lua:2615`). Since acknowledged warnings are still warnings, `--strict` cannot pass on
the real routes (248 WARN). It is used only for the harness fixture
(`Makefile:117-121`) and offered as `make validate VALIDATE_FLAGS=--strict` (`Makefile:35,90-91`).

### 6.3 Consequence and proposal

With 28 routes and many authors, "0 ERROR" is the only automated gate and the WARN count is
unbounded. Proposal: make acknowledgement real.

* A step key (for example `ok = "xp-unknown"` or `ok = { "level-grind", "at-far-from-giver" }`)
  and the same key on a segment (for `segment-level`). `Schema.lua` must accept it (unknown step
  keys are errors, `Core/Schema.lua:223`; segment fields at `:58-61`); the engine ignores it.
* Validator: a WARN whose code is listed on its step (or segment) is counted as "accepted", not
  printed without `-v`, not counted by `--strict`. A listed code that did not fire is
  `WARN ok-unused`, so stale acknowledgements cannot pile up.
* `xp-unknown` is 82 % of the comments and says nothing about the route (974 of 3,095 snapshot
  quests have no XP value). Treat it as INFO in route sections and report it once per quest in the
  shared section, instead of asking authors to acknowledge each turn-in.
* Then `make validate VALIDATE_FLAGS=--strict` can be the CI gate: no unacknowledged warning.

A parser for the existing comments is the alternative, but the sandbox gives no line numbers for
step tables and most steps have no explicit id, so mapping a comment line to a step needs a Lua
parser or strict formatting rules. The step key is the robust variant; the existing comments can be
converted mechanically where they sit on the step's first line.

---

## 7. Limits of the mock client and the simulator

Files: `tests/mocks/wow.lua`, `tests/mocks/wow/{world,quests,system,widgets}.lua`,
`tools/simulate_routes.lua`. What a simulation proves: the engine can walk the composed route for
that player (cursor, automation, background steps, reload, cold start). It is not a game model.

| Topic | Modelled | Not modelled |
|---|---|---|
| Player race / class | `player.race` (raceFile), `class`, derived `raceID` / `classID` / faction (`wow.lua:144-158`); ids for all nine classes and Human, Orc, Dwarf, NightElf, Scourge, Tauren, Gnome, Troll (`:174-184`); Skyborne = raceID 96 Horde / 95 Alliance. `UnitRace`, `UnitClass`, `C_CreatureInfo.GetRaceInfo/GetClassInfo` (`world.lua:787-797,1136-1148`) | Goblin has a race bit but no raceID |
| Quest availability | level, `pre`, `preAny`, exclusive, **race mask and class mask** from the DB (`quests.lua:609-630`, race bits `:588-600`) | profession requirements (`reqSkill`), reputation, quest items needed to start |
| Simulator reaction to "not offered" | only a **warning** ("quest N would not be offered yet: …", `simulate_routes.lua:491-494`); the run stays `OK` and the accept is forced through the dialog. In sync runs an unreachable accept fails | no strict mode for warnings |
| Trainers | a trainer window opened with the step's `spells` as service names and closed again (`simulate_routes.lua:556-563,586`); via gossip when the step has `gossip` | which class the NPC trains, ranks, costs, money, learning spells, talents, weapon skills, riding skill. `m:LearnSpell` exists but the simulator never uses it |
| Pets | nothing | taming, pet trainer, stable, pet abilities, hunter quests' "tame" mechanics (the tame quests are ordinary quests with objectives) |
| Class mechanics | nothing beyond the class token | shapeshift forms, totems, soul shards, poisons, lockpicking, ammo |
| Race-specific NPCs | nothing: every NPC of the DB is talkable by everyone | hostility, phasing, race-only gossip |
| Movement | `go` and every step with `at` **teleport** the player to `at` (`moveTo`, `simulate_routes.lua:712-714,822`) | paths, travel time, distance between zones, drowning, walls |
| Flights | taxi map with the target node, `TakeTaxiNode`, 30 s flight, landing at `at` (`:739-762`) | which nodes a flight master really offers, node discovery rules, cost |
| Hearthstone | bind via innkeeper, `UseHearthstone`, landing check against `at` (`:764-787`); a mismatch is a warning | cooldown |
| **Zeppelins, boats, Skyborne skycutter** | **nothing.** The DB tags 28 transport NPCs (`transport = "zeppelin" \| "boat" \| "skycutter" \| "landing"`), but no tool reads that field (no occurrence in `tools/lib`, `tools/simulate_routes.lua`, `tests/mocks`). A zeppelin ride is a `go` step = teleport | boarding, arrival, waiting time, the Zephras → Mulgore landing |
| Maps | built-in synthetic geometry for the 1-22 zones (`world.lua:56-85`): Tirisfal, Silverpine, Hillsbrad, Alterac, WPL, Undercity, Durotar, Barrens, Mulgore, Stonetalon, Ashenvale, Orgrimmar, Thunder Bluff, Zephras (no world position), Darkspear Islands, Riverglades. Other zones with a known size are added from the DB with their own coordinate frame (`simulate_routes.lua:949-968`) | real zone adjacency; distances between two DB-defined zones |
| XP | quest XP (DB or median), `level` steps set the level (`:789-798`) | kill XP, rested, so simulator levels lag behind the validator's |
| Money, bags | items for `collect` and objectives are added to the bags | gold, bag space, vendor purchases |

For the new start zones: Durotar 1411, Mulgore 1412, Orgrimmar and Thunder Bluff are built-in
maps; Darkspear Islands 2524 exists as a map without world position. Echo Isles / Sen'jin content
on map 1411 needs nothing new. Zephras has no world size in the DB (`zones[2521].size` missing), so
validator distances there are in approximate map units.

What this means for the plan: the simulator cannot tell whether a class step is right (trainer of
the right class, spell available at that level, pet tamed, transport taken). Those are covered
only by the validator's DB checks (quest masks, trainer sub names, flags, positions) and by
in-game testing.

---

## 8. Hard-coded profiles, module names, route ids and segment ids

### 8.1 Build and CI

| Place | What |
|---|---|
| `Makefile:18` | help text `make harness PROFILE=race=Scourge,class=PALADIN,faction=Horde [LIB=addons/FastesBoooy_Horde]` |
| `Makefile:48` | `SYNC_MID = 21/ud-04-barrens,sd-04-barrens 29/h-24-barrens-stonetalon` |
| `Makefile:57-58` | `PROFILE_UD = race=Scourge,class=PALADIN,faction=Horde`, `PROFILE_SD = race=Skyborne,class=DRUID,faction=Horde` (used only by `harness-fixtures`, `:117-125`, on the fixture library) |
| `Makefile:61` | `LIB = addons/FastesBoooy_Horde` (default of `make harness`) |
| `Makefile:129` | usage text of `make harness` |
| `Makefile:9-14,44-48` | comments "every route module", "both routes have a 15-18 Barrens segment" |
| `.github/workflows/ci.yml` | no names; runs `make check`, `routedata-check`, report freshness, package |
| `.luacheckrc:129` | comment "e.g. FastesBoooy_Horde" |
| `tools/package_addons.py` | none (every directory under `addons/`) |

### 8.2 Tools (code)

| Place | What |
|---|---|
| `tools/lib/validator.lua:65-69` | `CLASS_NAMES` (all nine classes; used by the trainer check) |
| `tools/lib/validator.lua:71-74` | `RACE_FACTION` (Orc, Scourge, Tauren, Troll, Goblin → Horde) |
| `tools/lib/validator.lua:76` | `BOTH_SIDES = { Skyborne = … }` |
| `tools/lib/validator.lua:191-192` | message "expected e.g. Scourge, Orc, Tauren, Troll, Skyborne" |
| `tools/lib/validator.lua:1873` | hint `Undead` → `Scourge` |
| `tools/lib/validator.lua:2368,2389-2403` | usage text: `horde-undead-paladin`, `h-22-hillsbrad`, `addons/FastesBoooy_Horde`, `state_ud_22.json` |
| `tools/lib/validator.lua:1475` | comment with `h-22-hillsbrad#45` |
| `tools/lib/validator.lua:2177-2181` | `IN_GAME_ONLY` text about Zephras and Mulgore (goes into the report) |
| `tools/lib/harness.lua:7-8,333,367` | comments / error text with `addons/FastesBoooy_Horde`, `race=Scourge,class=PALADIN`, `race=Skyborne,class=DRUID` |
| `tools/lib/harness.lua:51-54` | `RACE_FACTION` |
| `tools/lib/route_loader.lua:14` | comment "e.g. the shared library FastesBoooy_Horde" |
| `tools/simulate_routes.lua:14` | comment, same |
| `tools/simulate_routes.lua:108-112` | `RACE_FACTION`, `DEFAULT_RACE = { Horde = "Scourge", … }` (only for routes without `races`); default class `WARRIOR` (`:891`) |
| `tools/simulate_routes.lua:137` | usage text `race=Scourge,class=PALADIN` |
| `tools/gen_route_data.lua:60-72` | `PLACE_NAMES_RU` (place names of the two current routes) |
| `tools/build_db_snapshot.py:134-135` | `CLASS_SORTS = {-141: "PALADIN", -263: "DRUID"}`, `SCOPE_CLASSES = ("PALADIN", "DRUID")`; used at `:645,683,688,721,799,1205,1326` |
| `tools/lib/fbdb.lua:6-7,131` | comments only |

### 8.3 Tests and fixtures

| Place | What |
|---|---|
| `tests/spec/core_sync_spec.lua:633-650` | **the only spec that loads real route modules**: `addons/FastesBoooy_Horde/…toc`, `addons/FastesBoooy_UndeadPaladin/…toc`, asserts more than 1,500 steps and `GetSyncSuggestion().from.id == "ud-01-deathknell"` (performance test) |
| `tests/spec/validator_harness_spec.lua:18-20` | `PALADIN`, `DRUID`, `CLI_PALADIN` profiles for the fixture library; `:195-200` "refuses route modules"; `:507-525` routes in a declared library are an error |
| `tests/spec/validator_lint_spec.lua:33` | probe path `addons/FastesBoooy_Probe/Segments/01.lua` (not a real module) |
| `tests/spec/validator_compose_spec.lua:198,212-234` | `step-no-profile` of a WARRIOR insert; "once per route" dedupe |
| `tests/spec/validator_fixtures_spec.lua:268-269` | `step-no-profile` on `FastesBoooy_FxFilters` |
| other specs | use `Scourge` / `PALADIN` / `Skyborne` / `DRUID` only as profiles of fixtures or in-memory routes (counts: validator_fixtures 36, validator_harness 34, validator_lib 16, core_schema 15, core_simulate 15, validator_compose 12, mock_world 7, …). They do not depend on the real modules |
| `tests/fixtures/**/Route.lua` | every fixture route is `Horde` / `Scourge` / `PALADIN` (plus `FxFilters`, `FxWrongRace`, `TestComposed` with a WARRIOR-filtered insert) |
| `tests/fixtures/validator/harness_state_6.json` | no names (meta note only) |
| `Makefile:40-56` | fixture module lists (`FIXTURE_VALIDATE`, `FIXTURE_SIMULATE`, `FIXTURE_ROUTEDATA`, `FIXTURE_HARNESS_*`); they stay valid |

The fixtures `FastesBoooy_TestLib` (library) + `FastesBoooy_TestComposed` (route module depending
on it) keep the two-module shape. A new fixture with the one-module shape (shared segments, shared
inserts and at least two routes of different classes in one module) is needed to pin the new
behaviour.

### 8.4 Documentation and metadata

| Place | References |
|---|---|
| `README.md:11-28` | module table and install text: three parts, `## Dependencies: FastesBoooy, FastesBoooy_Horde` |
| `docs/ARCHITECTURE.md:10-14,45,50` | module list, library / route module description |
| `docs/ROUTE_FORMAT.md:22,30,44-45,213-217,230-236,257-275,346,391` | examples with `horde-undead-paladin`, `ud-01-deathknell`, `FastesBoooy_Horde`, `h-22-…` |
| `tools/README.md:40,43,331,372,398,635,645,650,712-715,742,758,786-803` | make targets, harness examples, sync results table for the two routes |
| `docs/routes/horde-22-60.md`, `horde-undead-paladin.md`, `horde-skyborne-druid.md` | route documents named after today's modules (635 / 598 / 641 lines) |
| `docs/VALIDATION.md` | generated; 689 lines mention the old names |
| `addons/*/…toc` | `## Title` / `## Notes` ("FastesBoooy: Horde 22-60", "Undead Paladin 1-60", …) and `## Dependencies: FastesBoooy, FastesBoooy_Horde` |
| `addons/FastesBoooy/Core/Registry.lua:169` | comment "e.g. FastesBoooy_Horde" |
| route files | route ids `horde-undead-paladin`, `horde-skyborne-druid`; segment ids `ud-01…05`, `sd-01…05`, `h-22…h-56`; step id prefixes `ud0N-`, `sd0N-`, `h-NN-`, `pal-`, `dru-` |

Saved-variable note (outside the tools, but a consequence of renaming): the engine stores progress
by route id and step id (`cursorHint`), so renaming route ids and step ids resets saved progress of
existing characters; the engine recovers from the game state (quest log, completed quests).

---

## 9. Findings that contradict or qualify the binding decisions

1. **"Today a route in a declared library module is a load error"** is true but narrower than
   it sounds: only the TOC declaration triggers it. A module without the declaration can hold both
   today in every tool except the harness (1.5, 1.6). The work is in the harness, luacheck, the
   validator's per-route checks and report, `gen_route_data` for shared inserts, and error
   isolation, not in the loader.
2. **"Route.lua registers the 28 routes from a table"** fails `make lint` as long as
   `fastesboooy_route` has no Lua base (1.4). `.luacheckrc` must change (and
   `validator_lint_spec.lua` should then pin that `C_*` and writes stay forbidden).
3. **`-- WARN-OK`** is assumed as a mechanism in the task description; it does not exist (6).
   Anything like "all WARN reviewed" is currently unverifiable by tools.
4. **Class steps as `train`**: weapon masters and the Orc / Tauren / Undead riding instructors are
   validator errors (2.4). "Weapon skills in class files" and "riding at 40 in per-race files" need
   a validator extension first, otherwise nine class agents and the race files produce errors by
   design.
5. **DB scope**: the snapshot is PALADIN / DRUID-centric (`SCOPE_CLASSES`). Checked against the
   snapshot:
   * class trainers: present for all nine classes (2.4), fine;
   * class quests in the snapshot per class (Horde-available, by required level ≤10 / 11-22 /
     23-40 / 41-60): Warrior 17/14/7/15, Hunter 25/0/0/8, Rogue 14/12/4/11, Priest 18/6/0/11,
     Shaman 30/14/2/13, Mage 10/4/9/8, Warlock 13/17/26/15 (Paladin 12/20/0/19, Druid 15/14/0/40);
   * index-only (outside the snapshot, `quest-out-of-scope`) Horde class quests below level 54:
     Rogue 96779, 96781-96786 (required level 24); Shaman 79362, 79363 (18), 79358, 79360, 79361,
     79364, 79366, 79442 (30); Mage 1948-1952 (30), 1957, 1958 (35), 8251-8253 (50); Warlock 4785
     (31), 7601-7603 (50). Warrior, Hunter and Priest have none below 54;
   * `byClass` overlays exist for 4 quests and only for PALADIN / DRUID;
   * `make db` needs `RESEARCH=…` and `CONVERSION=…` inputs that are not in this repository, so the
     snapshot cannot be extended in this checkout. Routes that use the index-only quests validate
     with warnings and without NPC / chain checks.
6. **Combos**: the trainer data agrees with the decided list for Orc, Troll, Tauren and Undead.
   For Skyborne, Zephras has two Mage trainers with faction `AH` (254086 Shenaan Spellwind, 252373
   Anathamaas Aetherwind) while its Shaman trainers are `H`-only. That does not prove a Horde
   Skyborne Mage (the `AH` tag may only say the NPC is neutral), but it is the one place where the
   DB does not plainly confirm the list; it should be checked against class-quest race masks or in
   game before the route table is frozen.
7. **"simulate-sync runs each route 8 more times"**: confirmed, and measured as 151 s per route on
   top of 25.8 s. All 28 routes do not fit a 15-minute CI on 4 CPUs (17.6 min for the sync runs
   alone); the subset proposal in 3.4 is necessary, not optional.
8. **Per-agent validation "independent of other agents' unfinished work"** is not possible with
   today's tools inside one module: any load error or failed insert of another file fails the
   module (reproduced, 11.2). It needs a tool change or strict working rules.
9. **Class steps valid "for every race of that class"**: an insert anchored on a start-zone step
   exists only in the routes of that race. With today's `AddInsert` that is an "unknown anchor"
   error for every other route. Shared inserts must treat a missing anchor as "not applicable to
   this route" (1.7), and class agents need per-race anchors in the start zones plus common
   anchors on the shared path.
10. **Grind scale**: both current routes need about 4,900 same-level kills by the validator's
    estimate (about 6,100 in the worst case), almost all in the shared 22-60 path (2.7). The
    "fastest leveling" judgement will be dominated by the shared path, not by the start zones or
    class steps.

---

## 10. Change list per tool file

`tools/lib/route_loader.lua`
* stub for the shared-insert API next to `AddLibrarySegment` (`:309-317`), with file tagging;
* optional file filter for parallel work (`opts.skip` exists, `:158`, `:335`; expose it);
* decide what `X-FastesBoooy-Module` means now (keep for fixtures / pure libraries, or add a value
  for the mixed module); the error at `:465-468` and `isLibrary` at `:464`.

`tools/lib/harness.lua`
* `Build`: accept modules with routes (`:386-390`); optionally apply shared inserts whose anchors
  are in the selected segments; help texts (`:7-8`, `:333`).

`tools/lib/validator.lua`
* `RouteChecks` (`:1860-1910`): skip shared steps in the per-route `step-no-profile`; new
  cross-route pass (2.9);
* `--profile` as a filter when the route declares races / classes, or separate `--race` /
  `--class` filters (`:122-143`, `:1958`);
* trainer categories (`:1212-1242`): weapon master, riding, pet, portal;
* message records with stable keys for cross-route dedupe (`Run:add`, `:305-330`); new Markdown
  layout (`FormatMarkdown`, `:2233-2339`); rename the `[library X]` tag (`locStr`, `:2051-2063`);
* acknowledged warnings and `--strict` (6.3);
* load-error attribution when `--route` is used (`:1984-2005`);
* usage text (`:2360-2407`).

`tools/simulate_routes.lua`
* `--list-routes`;
* harness on a mixed module (`mainHarness`, `:1448-1486`);
* module load errors currently fail every route (`:1557-1564`): honour the same file filter;
  `Mock.loadAddon` (`tests/mocks/wow/system.lua:343-348`) needs a way to skip files;
* header and usage text (`:1-140`).

`tools/gen_route_data.lua`
* shared inserts in `CollectLibraryIds` (`:119-125`); no empty `AddRouteData` blocks (`:291-299`);
* `PLACE_NAMES_RU` for the new zones (`:60-72`); header and usage text.

`Makefile`, `.github/workflows/ci.yml`
* parallel `simulate` / `simulate-sync`, `SYNC_ROUTES`, `SYNC_MID` with the new segment ids,
  `LIB`, help text (3.4, 8.1); optional nightly full sync.

`.luacheckrc`
* Lua base for route modules; new API field (`:129-142`).

Specs to adapt: `core_sync_spec.lua:633-650` (real module paths and ids),
`validator_harness_spec.lua:195-200,507-525`, `validator_compose_spec.lua:198,212-234,262-304`,
`validator_lint_spec.lua:85-92`, plus new specs and a one-module fixture for shared inserts,
cross-route `step-no-profile`, the report layout and acknowledged warnings.

Docs: `tools/README.md` (sections 4, 5, 7, 8 and the make table), `docs/ROUTE_FORMAT.md`,
`docs/ARCHITECTURE.md`, `README.md`, `docs/routes/*`.

---

## 11. Parallel agents in one checkout: what the tools imply

### 11.1 Files that cannot be shared between agents

| File | Why | Rule that follows |
|---|---|---|
| `FastesBoooy_Guides.toc` | every new file needs a line; order defines load and insert order | create the complete TOC with all planned files up front (placeholder files that contain only comments load cleanly); agents never edit it |
| `Data.lua` | generated from the whole module; refused while any file has an error | agents never regenerate or commit it; validate and simulate do not need it for normal runs (names are display fallbacks; `questMeta` matters for the sync runs only). One owner runs `make routedata` at integration |
| `docs/VALIDATION.md` | generated from all routes; CI checks freshness | same: one owner, at integration |
| `Route.lua` (route table, `UseSegments` lists) | names every segment id | frozen before the content phase: segment ids and their order are part of the plan |
| `tools/gen_route_data.lua` `PLACE_NAMES_RU` | one table for all zones | path agents report new places; one owner edits |
| `Makefile` `SYNC_*` | names routes and segments | one owner |
| shared anchors | class files anchor on step ids of path files | anchor ids are a contract: defined in the plan, never renamed by path agents |

### 11.2 Error coupling, reproduced on the prototype

* A syntax error in `Classes/Warrior.lua`: `validate --route undead-paladin` reports
  `ERROR (Classes/Warrior.lua) [schema] load error …` on the paladin route;
  `simulate --route undead-paladin` prints `FAIL FastesBoooy_Guides: 1 load/schema error(s)`;
  `gen_route_data` writes nothing.
* A wrong anchor in `Classes/Warrior.lua` (per-route `AddInsert` in a loop): one error per route,
  the paladin simulation fails as well.

Options, in order of preference:

1. tool support: a file filter on all three tools (for example `--skip 'Classes/*' --keep
   Classes/Warrior.lua`), built on the loader's existing `opts.skip`, plus the same in
   `Mock.loadAddon`; and with `--route X`, errors of files that contributed no step to X reported
   as notes instead of failing X;
2. shared-insert semantics that make a missing anchor "not applicable" (removes the per-route
   anchor errors entirely);
3. working rule: a file is only ever saved in a loadable state (run `luacheck` and
   `lua5.1 -e 'assert(loadfile(...))'` on the own file before every tool run of anyone).

### 11.3 Commands per agent type (with the extensions of 1.7 / 2.10 in place)

Path agent (Durotar, Mulgore), independent of class files and of the other path agent:

```
# own segments from a fresh character, one profile per race that starts there
lua5.1 tools/validate_routes.lua --harness addons/FastesBoooy_Guides \
    --segments <own segment ids> --profile race=Orc,class=WARRIOR,faction=Horde --write-state /tmp/orc12.json
lua5.1 tools/simulate_routes.lua --harness addons/FastesBoooy_Guides \
    --segments <own segment ids> --profile race=Orc,class=WARRIOR,faction=Horde
# junction into the shared path: the first shared segment from the written state
lua5.1 tools/validate_routes.lua --harness addons/FastesBoooy_Guides \
    --segments <first shared segment> --profile race=Orc,class=WARRIOR,faction=Horde --state /tmp/orc12.json
```

A harness run of a start zone costs about a second in both tools (3.1). Durotar needs two profiles
(Orc, Troll); a harness run has no class inserts, so it is class-independent by construction.
Position checks on Durotar and Mulgore are in yards (both maps have a size).

Class agent (one `Classes/<Class>.lua`), independent of unfinished path work: every class has at
least one race whose start zone already exists (Tirisfal or Zephras), so the full route of that
race can be validated and simulated from day one:

| Class | Route(s) on existing start zones | Routes that wait for the path agents |
|---|---|---|
| Warrior | undead-warrior, skyborne-warrior | orc, troll, tauren |
| Paladin | undead-paladin | none |
| Hunter | skyborne-hunter | orc, troll, tauren |
| Rogue | undead-rogue, skyborne-rogue | orc, troll |
| Priest | undead-priest | troll |
| Shaman | skyborne-shaman | orc, troll, tauren |
| Mage | undead-mage | orc, troll |
| Warlock | undead-warlock | orc, troll |
| Druid | skyborne-druid | tauren |

```
lua5.1 tools/validate_routes.lua --route undead-warrior          # 0.3 s
lua5.1 tools/simulate_routes.lua --route undead-warrior          # about 26 s
# shared path only, with the class steps, from the state at the merge point
lua5.1 tools/validate_routes.lua -q --route undead-warrior --write-state /tmp/uw.json --until <first shared segment>
```

Do not use `--profile` to pick a class in the validator (it overrides every route, 2.1).
Class-specific things the tools will flag for a class agent: `lookahead-skip` when a trainer visit
precedes the trainer's own class quest (2.11), `train-wrong-trainer` / `train-not-class-trainer`
(2.4), `quest-class` / `quest-race` for class quests with race masks, `quest-out-of-scope` for the
quests listed in 9.5, `segment-level` when class-quest XP moves a shared segment's end level by
more than one level.

Integration (one owner, after the agents): `make routedata`, `make report`, `make lint`,
`make validate`, `make simulate` (parallel), `make simulate-sync`.
