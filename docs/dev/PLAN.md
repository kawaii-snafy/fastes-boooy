# Implementation plan: FastesBoooy_Guides (28 race + class routes, levels 1-60)

Status: in execution. Done: F1a, F1b, F1c, F2a, F2b, F2c, F2d and the orchestrator fixes F2e (hand-overs in
`docs/dev/handover/`); next: P1. Where a phase deviated from this text and later phases depend on it, the text
below was aligned in F2e (marked "as executed"). Branch `claude/beautiful-planck-svbl19`. Revision 2: revised after three
adversarial reviews (engine and tools, route speed, parallel execution); every finding and what was changed for
it is in the "Review log" at the end.
Inputs: the five research reports in `docs/dev/research/` (`core.md`, `tools.md`, `routes.md`, `startzones.md`,
`classes.md`). This plan is binding where it decides something; the reports are the evidence and the detail.
An agent needs this file plus the reports named in its phase (section D).

Language: this plan is English. The user documentation of the repository (`README.md`, `docs/*.md`,
`docs/routes/*.md`) is Russian; keep the language of each existing file. Step notes and titles are always
bilingual `{ ru = ..., en = ... }`.

Scratch files (states, what-if copies, logs) go to a directory outside the repository (`$SCRATCH` below, for
example the session scratchpad). Never commit them.

Contents: 0 decisions and deviations; A architecture; B route design; C class and race step conventions;
D execution phases; E open questions and risks; appendix (baseline numbers, command reference); review log.

---------------------------------------------------------------------------------------------------------------

## 0. Decisions

### 0.1 Binding decisions of the user (unchanged)

1. Exactly two addon folders: `addons/FastesBoooy` (core) and `addons/FastesBoooy_Guides` (all guides).
   `FastesBoooy_Horde`, `FastesBoooy_UndeadPaladin`, `FastesBoooy_SkyborneDruid` are deleted.
2. 28 routes, id `<race>-<class>`, one race and one class each, `faction = "Horde"`, `default = true`. No
   "Horde" / "Орда" in addon names, TOC texts, route titles and descriptions, segment titles, and in notes that
   describe the guide, the route or the module ("the shared Horde route", "Horde racial quest"). In-world uses
   inside notes stay (quest and NPC names such as "Conscript of the Horde", "the Horde camp", "Fallen Hero of
   the Horde"). The check is defined in D.2 (F2d).
3. Combos (confirmed by the DB: one level-1 class letter per combo, `classes.md` section 2):
   Orc HUNTER MAGE ROGUE SHAMAN WARLOCK WARRIOR; Scourge MAGE PALADIN PRIEST ROGUE WARLOCK WARRIOR;
   Troll HUNTER MAGE PRIEST ROGUE SHAMAN WARLOCK WARRIOR; Tauren DRUID HUNTER SHAMAN WARRIOR;
   Skyborne DRUID HUNTER ROGUE SHAMAN WARRIOR. There is no Horde Skyborne mage.
4. Speed principle: fewest grind kills and least travel; decisions are judged by the validator's numbers.

### 0.2 Refinements and deviations decided by this plan (with the evidence)

| # | Decision in the request | What this plan does | Why |
|---|---|---|---|
| R1 | "one shared path for everyone from the Barrens on" | The shared path starts at **Orgrimmar at about level 12** (`h-12-orgrimmar-tirisfal`), then Silverpine 13-15 (`h-13-silverpine`), then the Barrens 15-22. Undead join at `h-13-silverpine` on foot. | Without Silverpine: +117 grind kills for the Undead (74 -> 191), +77 for the Skyborne (0 -> 77) (`routes.md` 8.2). Durotar and Mulgore hand over at 11.2-11.9, three levels under today's Barrens entry, and have no local XP to close a 30k XP gap (`startzones.md` 5.4, option B). |
| R2 | "Tirisfal = ud-01..03, Zephras = sd-01..03" | Tirisfal = `ud-01`, `ud-02`. Zephras = `sd-01`, `sd-02` plus a short Skyborne bridge `sd-03-thunder-bluff`. `ud-03`, `sd-03` (rest), `ud-04/05`, `sd-04/05` become the shared `h-12`, `h-13`, `h-15`, `h-18` segments. | `ud-03` is Silverpine; `sd-03` is Thunder Bluff + Orgrimmar + Tirisfal + Silverpine (`routes.md` 0.4). |
| R3 | "class steps valid for every race of that class" | One file per class, but below level 12 it holds one insert group per start zone (anchors, trainers and quest ids differ per zone); from 12 on the groups are race-neutral. | `classes.md` 0.2.1. |
| R4 | "start zones class-agnostic" | Class-agnostic except where the game itself branches by class: such a branch is a pair of class-filtered **base** steps owned by the path agent (Durotar 792 vs the warlock's 1485 -> 1499). | `startzones.md` 0.10. |
| R5 | "`WARN-OK`" | Today a comment nobody parses. It becomes a real step / segment key `ok = "<code>"` (for `level-grind` with a kill ceiling); `--strict` then means "no unacknowledged WARN" and is the gate of every phase. Parallel agents run it with `--own <their files>`. The numeric criteria (end level, grind budgets) are separate validator options that produce ERRORs (A.6.3). `xp-unknown` becomes INFO. | `tools.md` section 6; `validator.lua:2567-2573`, `:1705-1709`, `:45`. |
| R6 | "Route.lua registers the 28 routes" | It registers the routes of every race whose start zone has announced itself (A.4). All 28 exist once Durotar and Mulgore are written; before that no broken route is visible. | Lets every phase end green; path agents never edit `Route.lua`. |
| R7 | riding "in per-race files" | Yes, with class filters (not WARLOCK, not Scourge PALADIN) and a fixed contract with the druid file for the level-40 Thunder Bluff detour (C.7). | `classes.md` 0.1.5, `routes.md` 7.4. |
| R8 | - | New small core / tools features that the scale needs: route `aliases`, a non-composing route list, a class reward table, a DB override layer, `--skip` / `--keep` / `--own` file filters, `--list-routes`, `--levels`, `--summary` and the budget options. | `core.md` 0.3, 3.3, 5.7; `tools.md` 9.5, 11.2. |
| R9 | "fewest grind kills", judged by the validator | Applied in full to levels 1-22 (new and rewritten content). For 22-60 this project keeps the path that was compacted in November 2026 (6,362 -> 4,972 grind kills for the Undead paladin, `docs/routes/horde-22-60.md`) and guards it with machine budgets: no route may need more kills than the base profile of its race. A further reduction of 22-60 is the optional phase P3 (D.4a); it needs the user's go (E.19). | 4,897 of the 4,972 grind kills of the baseline are in `h-22` .. `h-56` (appendix 1). At 40+ one same-level kill gives 245+ XP, so only quests with little travel beat the grind (B.8, cost rule). |
| R10 | "shared segments reusable by many routes" | A shared base step whose `class` / `race` / `faction` filter cannot match a route is not composed into that route (the same pruning as for shared-insert steps, A.5.1 rule 9). | Otherwise a class insert anchored on a race-filtered step lands in every route of the class: reproduced by the engine reviewer (`Compose.lua:256-271`, `:329-334`; `Engine.lua:361-363`). |
| R11 | "class-agnostic" paths | The shared path and the start zones may hold class-neutral **trainer-hub gates** (`level = N`, N even, right before a hub with class trainers) under the limits of B.8. | Base profiles reach several trainer hubs 0.0-0.4 level under the even level (Undead 11.9-12.0 at Brill, 17.64 at Thunder Bluff; Orc 9.88 at Razor Hill): B.9. |

---------------------------------------------------------------------------------------------------------------

## A. Architecture

### A.1 Directory layout of `addons/FastesBoooy_Guides`

```
FastesBoooy_Guides/
  FastesBoooy_Guides.toc
  Data.lua                               generated (make routedata): one AddLibraryData call
  Segments/
    Tirisfal/01_Deathknell.lua           ud-01-deathknell          1-6    Scourge
    Tirisfal/02_Tirisfal.lua             ud-02-tirisfal            6-13   Scourge (ends on the Silverpine road)
    Zephras/01_Zephras_1_9.lua           sd-01-zephras             1-9    Skyborne
    Zephras/02_Zephras_9_13.lua          sd-02-zephras             9-13   Skyborne
    Zephras/03_ThunderBluff.lua          sd-03-thunder-bluff       13     Skyborne (plateau -> Thunder Bluff -> Orgrimmar)
    Durotar/01_ValleyOfTrials.lua        dur-01-valley-of-trials   1-6    Orc, Troll
    Durotar/02_Durotar.lua               dur-02-durotar            6-12   Orc, Troll (ends at Rhinag, outside the Orgrimmar gate)
    Mulgore/01_CampNarache.lua           mul-01-camp-narache       1-6    Tauren
    Mulgore/02_Mulgore.lua               mul-02-mulgore            6-12   Tauren (ends in Thunder Bluff)
    Mulgore/03_BarrensCrossing.lua       mul-03-barrens-crossing   12     Tauren (Thunder Bluff -> Orgrimmar on foot)
    Shared/12_Orgrimmar_Tirisfal.lua     h-12-orgrimmar-tirisfal   12-13  all but Scourge
    Shared/13_Silverpine.lua             h-13-silverpine           13-15  all
    Shared/15_Barrens.lua                h-15-barrens              15-18  all
    Shared/18_Stonetalon_Ashenvale.lua   h-18-stonetalon-ashenvale 18-22  all
    Shared/22_Hillsbrad.lua ... Shared/56_Felwood_Winterspring_Plaguelands.lua   the 12 existing h-22 .. h-56 segments
  Classes/
    Druid.lua Hunter.lua Mage.lua Paladin.lua Priest.lua Rogue.lua Shaman.lua Warlock.lua Warrior.lua
  Races/
    Orc.lua Scourge.lua Skyborne.lua Tauren.lua Troll.lua
  Route.lua                              the route table, RegisterRoute + UseSegments (last file of the TOC)
```

Every segment is a **shared segment** (`FastesBoooy.AddLibrarySegment`). Routes own nothing: no `AddSegment`, no
`AddInsert`, no `AddRouteData`. Class and race steps are **shared inserts** (`FastesBoooy.AddLibraryInsert`,
A.5.1). The words "library" and "shared" mean the same thing; user-visible text never says either.

Files that do not exist yet in a phase are still listed in the TOC and exist as **placeholders**: a file that
contains only its header comment and the guard line. A placeholder loads cleanly and registers nothing.

### A.2 TOC

```
## Interface: 16001
## Title: FastesBoooy: Guides
## Notes: Speed leveling guides 1-60 for FastesBoooy: one guide per race and class, picked automatically for your character.
## Notes-ruRU: Скоростные гайды прокачки 1-60 для FastesBoooy: по одному на каждую расу и класс, выбирается автоматически под персонажа.
## Dependencies: FastesBoooy
## Version: 0.4.0

Data.lua
Segments\Tirisfal\01_Deathknell.lua
... (all Segments files: Tirisfal, Zephras, Durotar, Mulgore, then Shared in level order)
Classes\Druid.lua
... (alphabetical)
Races\Orc.lua
... (alphabetical)
Route.lua
```

* No `## X-FastesBoooy-Module` line (a declared library may not register routes).
* The order is a contract: **Segments, then Classes, then Races, then Route.lua**. Shared inserts at one anchor
  are applied in registration order, so at a common anchor the player sees: inserts registered from a segment
  file, then the class file's steps, then the race file's steps (training, then riding).
* `Data.lua` holds only `AddLibraryData`, so its position does not matter; it stays first.
* Every file except `Data.lua` starts with the guard line `if not FastesBoooy.AddLibraryInsert then return end`
  (an old core then loads nothing from the module and shows its "no routes" hint; no Lua error).
* All files of the module share the private table `local _, ns = ...` (client and loader sandbox alike).

### A.3 Naming

**Route ids**: `<race>-<class>`, race slugs `orc`, `troll`, `tauren`, `undead`, `skyborne` (the raceFile of the
Undead is `Scourge`; the slug and the title say "undead"), class slugs `warrior`, `hunter`, `rogue`, `shaman`,
`warlock`, `mage`, `priest`, `druid`, `paladin`.

**Segment ids**: the existing ids are kept wherever the content stays the same thing:

| Id | Status |
|---|---|
| `h-22-hillsbrad` .. `h-56-felwood-winterspring-plaguelands` (12) | kept unchanged. 364 explicit step ids, all insert anchors and saved progress of 22-60 depend on them. `h` no longer means "Horde": it is an internal prefix of the shared path and is never shown. |
| `ud-01-deathknell`, `ud-02-tirisfal` | kept (content: Tirisfal, now class-neutral) |
| `sd-01-zephras`, `sd-02-zephras` | kept (content: Zephras, now class-neutral) |
| `sd-03-mulgore-silverpine` | **replaced** by `sd-03-thunder-bluff` (its first 9 steps); the rest moves into `h-12` and `h-13`. Strong reason: the segment is split in three. |
| `ud-03-silverpine`, `ud-04-barrens`, `ud-05-stonetalon-ashenvale`, `sd-04-barrens`, `sd-05-stonetalon-ashenvale` | **removed**, replaced by `h-13-silverpine`, `h-15-barrens`, `h-18-stonetalon-ashenvale` |
| `dur-01-valley-of-trials`, `dur-02-durotar`, `mul-01-camp-narache`, `mul-02-mulgore`, `mul-03-barrens-crossing`, `h-12-orgrimmar-tirisfal` | new |

**Step ids** (charset `[A-Za-z0-9-_.:]`). One id namespace for all segments and all shared inserts of the
module; a duplicate is a load error. Prefixes keep the files of different agents disjoint:

| Where | Prefix | Example |
|---|---|---|
| `ud-01`, `ud-02` | `ud01-`, `ud02-` | `ud02-sethearth` |
| `sd-01`, `sd-02`, `sd-03` | `sd01-`, `sd02-`, `sd03-` | `sd01-rorian` |
| `dur-01`, `dur-02` | `dur01-`, `dur02-` | `dur02-rh-3` |
| `mul-01`, `mul-02`, `mul-03` | `mul01-`, `mul02-`, `mul03-` | `mul02-tb` |
| `h-12`, `h-13`, `h-15`, `h-18` | `h12-`, `h13-`, `h15-`, `h18-` | `h15-fp-xroads` |
| `h-22` .. `h-56` | existing `h-NN-...` / `hNN-...`; new ids in these files use `hNN-` with the level of the step | `h50-owen-thadd` |
| class files | `war-`, `hun-`, `rog-`, `sha-`, `wlk-`, `mag-`, `pri-`, `dru-`, `pal-` | `war-dur-letter-orc`, `war-train-24` |
| race files | `orc-`, `tro-`, `tau-`, `und-`, `sky-` | `tau-40-riding` |

Rules:

* In every new or rewritten segment (`ud-*`, `sd-*`, `dur-*`, `mul-*`, `h-12` .. `h-18`) **every step has an
  explicit id**. Positional ids (`<segment>:<n>`) shift when a step is added and can never be anchors.
* In `h-22` .. `h-56` existing explicit ids are never renamed. Steps without an id keep their positional id,
  with two exceptions, both made by a single owner of the file: (1) `h-22-hillsbrad` gets an explicit id on
  every step in F2b, because three of its steps are deleted there (B.7); (2) P2 gives an explicit id to every
  hub step of `h-24` .. `h-56` that a class or race file may need as an anchor (D.4 step 5). Adding an id
  renames the step from `<segment>:<n>`; that is allowed until the anchor freeze at the end of P2 (P3 if it
  runs) and forbidden afterwards. **Phase C edits no segment file.**
* The existing explicit ids of steps that stay in `ud-01`, `ud-02`, `sd-01`, `sd-02` are kept. Class steps that
  move into a class file get new ids with the class prefix (`ud01-train-1` -> `pal-tir-train-1`). The old id is
  not reused for another step.

### A.4 `Route.lua`

One table, numeric `for` loops (no globals needed), the last file of the TOC.

```lua
-- FastesBoooy_Guides / Route.lua
if not FastesBoooy.AddLibraryInsert then return end
local _, ns = ...

-- shared path from the merge on; order is the route order
local SILVERPINE_ON = {
    "h-13-silverpine", "h-15-barrens", "h-18-stonetalon-ashenvale",
    "h-22-hillsbrad", "h-24-barrens-stonetalon", "h-27-ashenvale-needles", "h-31-hillsbrad-arathi",
    "h-34-stranglethorn", "h-37-desolace-dustwallow", "h-41-arathi-badlands", "h-44-swamp-stranglethorn",
    "h-46-tanaris-feralas", "h-50-hinterlands-searing-steppes", "h-53-azshara-ungoro-silithus",
    "h-56-felwood-winterspring-plaguelands",
}
local VISIT = "h-12-orgrimmar-tirisfal"  -- Orgrimmar + the trip to Tirisfal; every race but the Undead

local CLASSES = {
    WARRIOR = { slug = "warrior", ru = "воин", en = "Warrior" },
    -- ... HUNTER охотник, ROGUE разбойник, SHAMAN шаман, WARLOCK чернокнижник, MAGE маг, PRIEST жрец,
    --     DRUID друид, PALADIN паладин
}
local RACES = {
    { race = "Orc", slug = "orc", ru = "Орк", en = "Orc", zone = "Durotar", visit = true,
      classes = { "HUNTER", "MAGE", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" } },
    { race = "Troll", slug = "troll", ru = "Тролль", en = "Troll", zone = "Durotar", visit = true,
      classes = { "HUNTER", "MAGE", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" } },
    { race = "Tauren", slug = "tauren", ru = "Таурен", en = "Tauren", zone = "Mulgore", visit = true,
      classes = { "DRUID", "HUNTER", "SHAMAN", "WARRIOR" } },
    { race = "Scourge", slug = "undead", ru = "Нежить", en = "Undead", zone = "Tirisfal", visit = false,
      classes = { "MAGE", "PALADIN", "PRIEST", "ROGUE", "WARLOCK", "WARRIOR" },
      aliases = { PALADIN = "horde-undead-paladin" } },
    { race = "Skyborne", slug = "skyborne", ru = "Скайборн", en = "Skyborne", zone = "Zephras", visit = true,
      classes = { "DRUID", "HUNTER", "ROGUE", "SHAMAN", "WARRIOR" },
      aliases = { DRUID = "horde-skyborne-druid" } },
}

for i = 1, #RACES do
    local r = RACES[i]
    local start = ns.startZones and ns.startZones[r.zone]   -- announced by the zone's last segment file
    if start then
        -- build list = start segments (the array part of `start`), VISIT when r.visit, SILVERPINE_ON
        -- classes = r.classes, restricted to start.only when the announcement has it
        -- for every class: RegisterRoute{ api = 1, id = r.slug .. "-" .. c.slug,
        --     title = { ru = r.ru .. "-" .. c.ru .. " 1-60", en = r.en .. " " .. c.en .. " 1-60" },
        --     description = { ru = ..., en = ... },          -- zones of the race, no faction word
        --     faction = "Horde", races = { r.race }, classes = { CLASS }, levels = { 1, 60 },
        --     version = "0.4.0", author = "FastesBoooy", default = true, aliases = ... }
        -- then UseSegments(id, list)
    end
end
```

**Start-zone announcement.** The last segment file of a start zone ends with

```lua
ns.startZones = ns.startZones or {}
ns.startZones.Durotar = { "dur-01-valley-of-trials", "dur-02-durotar" }
```

A zone whose files are placeholders announces nothing, so the routes of its races are not registered and no
tool sees them. The announcement is the path agent's statement "this zone is complete enough to validate".
Keys: `Tirisfal`, `Zephras`, `Durotar`, `Mulgore`. The Tauren list includes `mul-03-barrens-crossing`, the
Skyborne list `sd-03-thunder-bluff`.

An announcement may carry `only = { "PALADIN" }`: while the key is present, only these classes of the zone's
races are registered. Tirisfal (`only = { "PALADIN" }`) and Zephras (`only = { "DRUID" }`) use it from F2a
until their start zone is class-neutral (F2c); the zone's agent removes the key in its own file. No `only` is
left after F2d (layout spec).

`Route.lua` is written once, in F2a, with the **complete five-race table**; only its chains change in F2b
(legacy chains -> the chains below). The Orc, Troll and Tauren rows are executed for the first time in P1, by
agents who may not edit the file, so F2b proves them beforehand: a case of the layout spec loads the module
with the Durotar and Mulgore placeholders replaced by fixture files (loader option `replace`, A.6.1; one-step
segments plus the announcement) and asserts 28 routes, their ids, titles, `races` / `classes` and the exact
chains of the table below, with no load error.

Resulting segment chains:

| Race | Chain |
|---|---|
| Scourge | `ud-01-deathknell`, `ud-02-tirisfal`, `h-13-silverpine`, `h-15-barrens`, `h-18-stonetalon-ashenvale`, `h-22` .. `h-56` |
| Skyborne | `sd-01-zephras`, `sd-02-zephras`, `sd-03-thunder-bluff`, `h-12-orgrimmar-tirisfal`, `h-13` .. `h-56` |
| Orc, Troll | `dur-01-valley-of-trials`, `dur-02-durotar`, `h-12-orgrimmar-tirisfal`, `h-13` .. `h-56` |
| Tauren | `mul-01-camp-narache`, `mul-02-mulgore`, `mul-03-barrens-crossing`, `h-12-orgrimmar-tirisfal`, `h-13` .. `h-56` |

`faction = "Horde"` stays on every route: the raceFile `Skyborne` exists on both factions (`core.md` 0.5).

### A.5 Core changes (`addons/FastesBoooy`, phase F1)

Core version `0.4.0`, `API_MINOR = 2` (`Init.lua`: comment line "2  core 0.4.0: + AddLibraryInsert, route
aliases, class reward table"), `/fb status` prints "route API 1.2". Route format stays `api = 1`.

#### A.5.1 `FastesBoooy.AddLibraryInsert(def)`

```lua
FastesBoooy.AddLibraryInsert({
    after = "<stepId>",            -- or: before = "<stepId>"   (exactly one of the two)
    class = "WARRIOR",             -- optional scope: token or list of class tokens
    race = { "Orc", "Troll" },     -- optional scope: raceFile token or list
    faction = "Horde",             -- optional scope
    steps = { { id = "war-train-24", train = true, npc = 3354, at = { 1454, 79.9, 31.4 } }, ... },  -- non-empty
})
```

(The ids and coordinates in the examples of this plan are illustrations; real values come from the DB.)

Semantics (prototype and line references: `core.md` section 5 and appendix B):

1. **Where it applies.** To every route that uses shared segments (`#route.uses > 0`) and whose composed steps
   contain the anchor. A route without the anchor is not an error for the core (the tools check mistakes,
   A.6.2). Routes without `UseSegments` are never touched. Because of rule 9 a filtered anchor exists only in
   the routes its filter can match, so an insert anchored on it lands only in those routes.
2. **Scope.** `class` / `race` / `faction` of the insert are the default filters of its steps; a step's own key
   replaces the insert's key for that step. A step whose filters cannot match the route
   (`Schema.FiltersCanMatchRoute(step.filters, route)`: disjoint with `route.classes`, `route.races` or
   `route.faction`) is **not composed into that route**. A route without `classes` / `races` keeps the step and
   the engine filters by player as today.
3. **Ids.** Every step needs an explicit `id`, unique in the shared namespace (`lib.scratch.stepById`, the table
   shared segments already use). An insert with a missing or duplicate id is rejected as a whole.
4. **Order.** Per route: shared inserts first, in registration order, then the route's own `AddInsert` calls.
   Shared steps do not advance the `<anchor>+<n>` counter of per-route inserts. (As executed, F1a: this also
   holds with a forward reference: an insert registered before the insert that supplies its anchor is applied
   as soon as the anchor exists, before every later insert.)
5. **Anchors.** A step of a shared segment or of another shared insert (or, per route, an own step). The anchor
   must have an explicit id: `Schema.AddSegment` sets `step.autoId = true` on positional ids and composition
   reports "anchor '<id>' is a positional step id: give the anchor step an explicit id".
6. **Copies.** Each route gets its own shallow copies of the insert steps, cached in `route.libCopies` (identity
   is stable across recomposition). Templates are never mutated.
7. **Tags** on the copies: `inserted = true`, `shared = true`, `library = <module>`, `file`, `anchor`,
   `insertSide`.
8. Known ordering quirk (keep, document): an insert anchored on the *last step of an earlier insert at anchor
   X* lands behind later inserts at X. Convention C.3 rule 6 avoids relying on it.
9. **Shared base steps are pruned by route scope too.** `Compose.libraryEntry` leaves out a shared segment step
   whose filters cannot match the route (`Schema.FiltersCanMatchRoute`, the test of rule 2). Step ids are
   assigned at `AddLibrarySegment`, so the positional ids of the other steps do not change. A route without
   `classes` / `races` keeps every step. Every Guides route has one race and one class, so for them "can match"
   is exactly "is shown". Consequences: a race-filtered alternative step (B.4-B.6) is an anchor only for its
   races; a per-route `AddInsert` anchored on a pruned step gets the existing "unknown anchor step" error; the
   per-route WARN `step-no-profile` can no longer fire for a shared step (A.6.2 replaces it). For the two old
   modules in F1: each route loses the 4 steps it never showed (1,713 and 1,748 composed steps instead of 1,717
   and 1,752) and its 4 `step-no-profile` WARNs; levels and grind numbers do not change.
10. **An insert is never wider than a filtered anchor.** When the anchor step itself carries a filter, every
    step of the insert must carry a scope (its own or the insert's) that is a subset of the anchor's filter in
    each filtered dimension (`race = "Scourge"` on an insert after `h15-org-fp`). The core does not need this
    (rule 9 already keeps the insert out of the other routes); the tools enforce it as ERROR
    `insert-scope-wider-than-anchor` (A.6.2) so that the author states the intent.

Errors (all go to `Registry.errors` with the prefix `library:`; the tools attach the file):

| Situation | When |
|---|---|
| not a table; both or neither of `after` / `before`; anchor not a non-empty string; unknown key; empty `steps`; step format error; unknown class token; bad faction | call time, once |
| step without `id`; duplicate id against a shared segment step or another shared insert; an empty scope list (`class = {}`, `race = {}`: F2e) | call time, once; the whole insert is rejected |
| a shared segment registered later reuses a shared-insert step id | at that `AddLibrarySegment` (existing "duplicate step id") |
| anchor not in this route | never an error in the core |
| positional anchor | composition, once per composed route |
| duplicate id against a route's own / per-route insert step | composition (existing message) |
| unknown anchor id; anchor in no route of the insert's scope; a step composed into no route; unknown race token; insert wider than its filtered anchor | tools only (A.6.2: `insert-anchor-unknown`, `insert-unapplied`, `shared-step-unused`, `unknown-race-token`, `insert-scope-wider-than-anchor`); they also run with `--skip` / `--keep` |

The core cannot know the race tokens (`Schema.lua:351-355` only checks that they are strings), and a step
pruned from every route is invisible in every composed route, so these mistakes are caught by walking the
**templates** in the tools, not the composed steps.

Files: `Core/Schema.lua` (`autoId`, new `Schema.NormalizeFilters(def, where, errors)` factored out of
`NormalizeStep`, new `Schema.FiltersCanMatchRoute`), `Core/Compose.lua` (`NewLibrary().inserts`, `parseInsert`,
`Compose.AddLibraryInsert(lib, def, source)`, `libraryEntry` (rule 9), `Build`), `Core/Registry.lua`
(`Registry:AddLibraryInsert`), `Core/Init.lua` (`public.AddLibraryInsert`).

#### A.5.2 Route aliases

`RegisterRoute{ ..., aliases = "old-id" | { "old-id", ... } }` (`Schema.ROUTE_FIELDS.aliases = "token-list"`).
`Registry.aliases[oldId] = route`; `Registry:Get(id)` resolves an alias when no route has that id.
`Engine:ActivateRoute` rewrites `cdb.route`, `cdb.cursorHintRoute`, `cdb.syncFloor.route`,
`cdb.syncDismissed.route` when they hold an alias of the activated route. Errors at registration: an alias that
equals a registered route id or an alias already taken ("alias '<x>' is already used", the alias is ignored).

#### A.5.3 Route list without composing; settings panel

`Registry:List(noCompose)`: with `true` it returns the routes in registration order without calling `Finalize`.
`UI/Options.lua`: the settings panel shows `Registry:Matching(facts)` (normally one route) in its route buttons,
then a line "and N more: /fb routes"; `/fb routes` prints the matching routes, then the number of the others;
`/fb routes all` prints every id and title from `List(true)`. The tooltip line "Steps: N" is shown only for a
composed route. A spec asserts that opening the panel and `/fb routes` leave non-matching routes uncomposed
(28 routes composed = +32 MB, `core.md` section 6).

#### A.5.4 Class reward table

Reward choices of quests turned in on shared steps differ per class, and class agents must not edit segment
files. New data kind, merged by the existing `AddLibraryData`:

```lua
FastesBoooy.AddLibraryData({ rewards = { DRUID = { [92461] = 1, [92463] = 3 } } })   -- once per class file
```

`Engine:GetRewardChoice(questID)`: a step-level `reward` wins (unchanged); otherwise
`route.data.rewards[facts.class][questID]`. `Compose.MergeData` merges per kind and per key, so each class file
owns its own key and nothing collides (one call per class: a second call with the same class key replaces the
first). Step-level `reward` remains valid only on class-scoped steps; shared base steps carry no `reward`.
(F2e: `Schema.CheckData` checks the shape at registration, in the game and in the tools: unknown class token,
a value that is not a table, a key that is not a quest id, an index that is not a positive integer are
registration errors; the engine still ignores such an entry.)

#### A.5.5 Acknowledged warnings: key `ok`

`Schema.STEP_FIELDS.ok` and `Schema.SEGMENT_FIELDS.ok`: a validator message code, a list of codes, or a table
that also maps a code to a number, the ceiling of the acknowledgement (`ok = "at-far-from-giver"`,
`ok = { "at-far-from-giver", "quest-out-of-scope" }`, `ok = { ["level-grind"] = 700 }`,
`ok = { "skip-ahead", ["level-grind"] = 90 }`), tokens `[a-z-]+`. The schema checks the shape only. The engine
ignores the key. The reason is written as a Lua comment on the same line. Meaning: A.6.3.

#### A.5.6 Obsolete modules warning, texts

* At login, once per session: if `C_AddOns.IsAddOnLoaded` (through a `Compat` wrapper) reports
  `FastesBoooy_Horde`, `FastesBoooy_UndeadPaladin` or `FastesBoooy_SkyborneDruid`, print a localized chat line:
  "delete the old folders ...: their guides are now part of FastesBoooy_Guides" (new strings in
  `Locales/UI_enUS.lua`, `UI_ruRU.lua`). As executed (F1a): only when `FastesBoooy_Guides` is loaded as well
  (without it the old modules are the guides of the installation).
* `UI_OPT_NO_ROUTES` names `FastesBoooy_Guides`.
* `Compose.lua` "unknown library segment" message: reword for one module ("unknown shared segment '%s' (is its
  file listed in the TOC before Route.lua?)").

#### A.5.7 Specs (F1)

New `tests/spec/core_shared_insert_spec.lua` with the ten cases of `core.md` 5.5 plus the cases of rule 9: a
segment with a race-filtered alternative pair, two routes of different races, class-only inserts after both
alternatives: each route contains only its own alternative and only the insert behind it; positional ids of
the unfiltered steps are the same in both routes; a route without `races` keeps both. Additions to
`core_registry_spec.lua` (aliases, `List(true)`, `API_MINOR`), `core_ui_spec.lua` (panel and `/fb routes` do
not compose, "route API 1.2"), `core_engine_spec.lua` or `core_automation_spec.lua` (reward from the class
table; step-level reward wins), `core_schema_spec.lua` (`ok` in its three forms, `aliases`, `autoId`). New
fixture `tests/fixtures/core/FastesBoooy_TestGuides`: TOC without the library declaration; shared segments for
two "zones" in subdirectories, one of them with a race-filtered alternative pair; three routes registered from
a table with a numeric `for` and the `ns.startZones` announcement (one zone with `only`); shared inserts with
class scope, race scope, a nested anchor, an insert on a filtered anchor, and a class reward table for a quest
turned in on a shared step. It is added to `FIXTURE_VALIDATE`, `FIXTURE_SIMULATE`, `FIXTURE_ROUTEDATA`.

### A.6 Tools changes (phase F1)

#### A.6.1 Loader, lint, harness, file filters

* `tools/lib/route_loader.lua`: stub `api.AddLibraryInsert` (calls `Compose.AddLibraryInsert(lib, def,
  { module, file })`), `mod.libraryInserts` (the templates, with file and scope). The
  `X-FastesBoooy-Module: library` rule is unchanged; the Guides module simply does not declare it.
* Loader option `opts.replace = { ["<TOC path>"] = "<other file>" }`: the named TOC file is read from the
  other path (used by the layout spec to load fixture start zones in place of placeholders, A.4).
* File filter: `opts.skip` exists in the loader; expose it as `--skip GLOB` and `--keep GLOB` (both repeatable,
  `*` wildcard, matched against the TOC path with forward slashes; a file is skipped when it matches a `--skip`
  and no `--keep`) in `validate_routes.lua`, `simulate_routes.lua` and `gen_route_data.lua --stdout`.
  `Mock.loadAddon` (`tests/mocks/wow/system.lua`) gets the same skip set for the simulator.
* **Own files: `--own GLOB`** (repeatable, same matching; validator only). It names the files the caller is
  responsible for. Without it every loaded file is own. Its effects are listed in A.6.2 (module checks) and
  A.6.3 (`--strict`). Parallel agents always pass it.
* `.luacheckrc`, std `fastesboooy_route`: add the field `AddLibraryInsert`, and as read-only globals the pure
  Lua base the sandbox already offers: `ipairs pairs next select type tostring tonumber unpack string table
  math`. `validator_lint_spec.lua` keeps pinning that `C_*`, `FastesBoooyDB` and writes to globals stay errors.
  New `files["tools/overrides/*.lua"]` rule: no globals at all (the file is one `return { ... }`).
* `tools/lib/harness.lua`: `--harness` accepts a module that registers routes (uses its shared part; the
  synthetic route `harness-<Name>` is selected explicitly). Shared inserts apply to the harness route
  automatically, and shared base steps and insert steps are pruned by the harness profile.
  `validator_harness_spec.lua:195-200` changes accordingly.

#### A.6.2 Validator: selection, module checks, data

* `--route` accepts a comma list and `*` wildcards (`--route 'orc-*,troll-*'`, `--route '*-warrior'`); same in
  the simulator. `--profile` stays an override (use `--route`; say so in the usage text).
* **Module checks on the templates.** They run after all routes of the module are composed, need no
  simulation, and run with `--route` as well. They walk every shared segment step and every shared insert
  **registered by the module's own files**, not the composed routes. Scope: only a module that registers at
  least one route. A pure library module (`FastesBoooy_Horde`, the fixtures `TestLib`, `FxHarnessLib`) gets
  none of them, and a route module does not check the templates of its dependencies; so in F1 the old layout
  reports nothing new. Harness runs skip them.

  | Code | Severity | Fires when |
  |---|---|---|
  | `unknown-race-token` | ERROR | a race token of a template step or of an insert scope is not in `db.enums.raceFileToBit` (the classic mistake `race = "Undead"`; today's check only sees composed steps, `validator.lua:1876-1890`) |
  | `insert-anchor-unknown` | ERROR | the anchor id of a shared insert is the id of no loaded step (shared segment step or shared-insert step) |
  | `insert-unapplied` | ERROR | the anchor exists and at least one loaded route can match the insert's scope, but none of those routes contains the anchor (wrong-zone anchor: `race = "Orc"` after `mul02-bh-5`) |
  | `shared-step-unused` | ERROR | a template step is composed into no loaded route (a filter that matches no route; replaces the per-route `step-no-profile` for shared steps) |
  | `insert-scope-wider-than-anchor` | ERROR | A.5.1 rule 10 |
  | `shared-unused` | WARN | a shared segment is used by no route |

  With a file filter (`--skip` / `--keep`) the first five still run for the **own** files (`--own`; all loaded
  files when it is absent); for a loaded file that is not own they are printed as notes and do not change the
  exit code (the anchor may live in a skipped file). `shared-unused` runs only on a full load. "Applied" means
  "at least one step composed into at least one route".
* `RouteChecks` keeps `step-no-profile` only for a route's own steps and per-route inserts.
* **Trainer kinds** (`H.train`): accepted with INFO `train-service` when the NPC has the trainer flag and its
  sub-name contains "weapon master" (any class), "riding" (any class), "pet trainer" (HUNTER only), "portal
  trainer" (MAGE only). Other cases as today. Demon trainers are vendors: use `vendor`.
* **DB override layer.** Directory `tools/overrides/` (not under `tools/data/`, which luacheck excludes).
  `DB.Load(path)` stays as it is and applies **no** overrides, so every spec keeps its pinned numbers. New
  `DB.ApplyOverrides(db, dir)`; the three CLIs call it by default and take `--no-overrides` (the Makefile's
  fixture targets pass it). Rules:
  * Order: `DB.Prepare` first (the XP median per quest level, `fbdb.lua:36-49`, is computed from the
    **snapshot**), then the overrides. An XP value for one quest therefore never moves the estimate of another
    quest. Spec.
  * Each file (`shared.lua` first, then alphabetical: as executed, F1b) is loaded in an empty environment under
    `pcall`. A file that does not load or has a
    format error is ignored for that run and reported as one line naming the file: ERROR `override-load` on a
    full run, a note when a file filter is active (one agent's half-written file never stops another agent).
  * A file returns `{ quests = { [id] = { ... , source = "<url or 'in game YYYY-MM-DD'>", verified = false } },
    npcs = { [id] = { sub = "...", source = ..., verified = ... } } }`. Quest fields: `xp = 410`;
    `races = { add = { "Troll" } }`, `classes = { add = { ... } }`; `exclusive`, `preSingle`, `preGroup` as
    `{ add = { ids }, remove = { ids } }`; `breadcrumbFor = <id> | false`. An entry without `source` is an
    error of that file.
  * One file per owner; a quest or NPC id may appear in one file only (the second is an error of the second
    file). The owner files of `tools/overrides/<name>.lua` are the TOC files whose base name or directory equals
    `<name>` without regard to case (`warrior` -> `Classes/Warrior.lua`, `durotar` -> `Segments/Durotar/*`,
    `orc` -> `Races/Orc.lua`); `shared` owns everything. ERROR `override-foreign-quest` when an override of a
    non-shared file names a quest that a loaded step outside its owner files uses: an XP or mask value for a
    quest of the shared path goes to `shared.lua`, which only the single-owner phases edit.
  * A step that passes a check (race, class, exclusivity, prerequisite) only because of an override with
    `verified = false` gets `WARN db-override-unverified` (to be acknowledged with `ok` and a `-- CONFIRM:`
    comment). XP overrides are used silently.
* Messages carry stable fields (`quest`, `npc`, `kills`, `level`, `file`) next to the text; `m.shared` marks
  messages on shared steps.
* `--levels`: with exactly one route, print one line per step with an explicit id:
  `id <TAB> segment <TAB> level before the step (normal) <TAB> level (worst case) <TAB> anchor of the insert
  or "-" <TAB> file <TAB> actions`. Class agents read the level at every anchor from it and see which of their
  insert steps landed where.
* Load errors with `--route` (as executed, F1b): a file that does not load always counts; an error about a route
  outside the selection is a note; a schema error of a loaded file is a note only when the file's content goes
  to unselected routes alone.

#### A.6.3 Validator: acknowledged warnings, `--strict`, numeric budgets

* A WARN whose code is listed in `ok` of its step (or of its segment for `segment-level`) is **accepted**: not
  printed without `-v`, counted separately ("W warning(s), A accepted"), not counted by `--strict`.
* **Ceiling.** `ok = { ["level-grind"] = N }` accepts the WARN only while the gate needs at most N kills in the
  normal run; above N it is a WARN again. `level-grind` can only be acknowledged with a ceiling (a plain
  `ok = "level-grind"` is ERROR `ok-needs-ceiling`), so a shared gate that is acknowledged once does not pass
  any number of kills for all 28 routes (today the 39 + 78 % gate needs 684 kills and the limit is 30).
* `WARN ok-unused`: a listed code that fired in none of the validated routes containing the step (evaluated
  only on a full run without `--route` / `--skip`).
* `xp-unknown` becomes INFO; the route summary gets "N quests with estimated XP (P % of quest XP)".
* `--strict`: exit 1 on any unaccepted WARN. With `--own`, only the unaccepted WARNs whose step (or segment)
  file is own count; the others are printed in a block "foreign warnings: N (report them in the hand-over)" and
  do not change the exit code. ERRORs always count, in any file. The single-owner phases (F2d, P2, R) resolve
  the reported foreign warnings (fix or `ok`) and run plain `--strict`.
* **Worst case.** The shadow run today keeps only `optional-dependency` for quests (`validator.lua:1748`,
  `:1360-1375`). It also records the `fp` and `sethearth` actions of skipped optional steps and reports ERROR
  `optional-dependency` for a required `fly X` whose flight point is learned only on optional steps and for a
  required `hearth X` whose only binding is an optional `sethearth X`. Fixture cases for both.
* **Numeric criteria as machine checks** (`-q` prints only message counts, `route-level` tolerates one level,
  `level-grind` warns above 30 kills; none of the acceptance numbers of section D was enforced before):

  | Option | Effect |
  |---|---|
  | `--end-level` | ERROR `end-level` when the end level of the normal or of the worst-case run is below `route.levels[2]` (harness run: below the planned end level of its last segment) |
  | `--summary` | after the normal output, one TSV line per route: `route, profile, errors, warnings, accepted, foreign, end level, worst end level, grind kills, worst grind kills, grind kills up to --grind-until, the same worst` |
  | `--grind-until SEG` | the segment up to whose end the last two columns count |
  | `--max-grind-until SEG=N/W` | ERROR `grind-budget` when the kills up to the end of SEG exceed N (normal) or W (worst case) |
  | `--write-baseline FILE` | writes per raceFile the maximum over the validated routes of that race: total grind kills normal / worst, and the `--grind-until` pair (JSON). P2 runs it on the base routes (`--skip 'Classes/*'`) |
  | `--baseline FILE` | ERROR `grind-baseline` when a route needs more total grind kills (normal or worst) than its race's entry |

  All of them work in harness runs too.
* `VALIDATE_FLAGS = --strict --end-level` is the gate of `make validate` from F2a on (after the `-- WARN-OK`
  comments are converted); from P2 on it also carries `--max-grind-until h-18-stonetalon-ashenvale=120/200`,
  and from phase C on `--baseline docs/dev/handover/baseline.json`.

#### A.6.4 Report (`make report`, `docs/VALIDATION.md`)

New Markdown layout (`tools.md` 4.3): (1) header and totals; (2) route summary table, one row per route: id,
profile, ERROR / WARN / accepted, end level, worst end level, grind kills normal / worst, with 15 % incidental,
estimated-XP quests, max quest log, steps; (3) path comparison: per start zone and per shared segment the
entry level (min-max over routes) and grind kills; (4) shared steps: every ERROR / WARN on a shared step once,
key `(severity, code, step id or segment, quest id)`, with a "routes" column and ranges for run-dependent
numbers; (5) gate matrix: shared `level` gates x kills (min / max / worst over routes) and the ceiling of their
`ok`; (6) per-route sections with only the route's own (class / race) messages; (7) INFO only as counts per
code; (8) the static "only in game" section plus a generated list of every `ok`-accepted
`db-override-unverified`. Text and JSON output keep the complete per-route view.

#### A.6.5 Simulator and `gen_route_data`

* `simulate_routes.lua --list-routes [dirs]`: one route id per line, registration order, exit 0; exit 1 with a
  message when a module has load errors.
* Harness on a mixed module; `--skip` / `--keep`; `--no-overrides`; exit code non-zero when `--route` matches
  nothing (already).
* **Reward choices.** The simulator resolves the expected choice the way the engine does: the step's `reward`
  first, then `route.data.rewards[profile.class][quest]` (today only `step.reward`,
  `simulate_routes.lua:413-421`, `:452-456`). It defines the mock choices from that and asserts the chosen
  index, so the class reward table is exercised end to end (the `TestGuides` fixture has such a quest).
* `gen_route_data.lua`: `CollectLibraryIds` also walks the module's shared inserts; no `AddRouteData` block for
  a route that owns nothing; `rewards` quest ids need nothing (they are turn-in quests of steps).
  `PLACE_NAMES_RU` gets the new places (single owner per phase, D).

### A.7 Makefile and CI

Measured on 4 CPUs (`tools.md` section 3): validate 0.27 s per route (28 routes about 5 s in one process);
simulate 25.8 s per route; the eight sync runs 151 s per route; busted 78 s; lint 3-6 s. `xargs -P 4` scales
linearly.

```make
JOBS ?= $(shell nproc 2>/dev/null || echo 4)
GUIDES = addons/FastesBoooy_Guides
SIM = $(LUA) tools/simulate_routes.lua
# -r: no run on empty input (GNU xargs would otherwise start one simulator without --route = all routes)
RUN_JOBS = xargs -r -P $(JOBS) -L 1 sh -c 'out=`$(SIM) "$$@" 2>&1`; rc=$$?; printf "%s\n" "$$out"; exit $$rc' sim

simulate:            # every route, JOBS in parallel; a failing --list-routes fails the target
	@routes=`$(SIM) --list-routes` || exit 1; \
	[ -n "$$routes" ] || { echo "simulate: no routes"; exit 1; }; \
	printf '%s\n' $$routes | sed 's/^/--route /' | $(RUN_JOBS)

SYNC_ROUTES = orc-warrior troll-shaman tauren-hunter undead-paladin skyborne-druid
SYNC_LEVELS = 10 23 35 48
SYNC_MID = 21/h-15-barrens 29/h-24-barrens-stonetalon
SYNC_PLUS = 2 4
simulate-sync:       # SYNC_ROUTES x (4 + 2 + 2) runs, JOBS in parallel; same guard: the list of argument
                     # lines is built first, an empty list or a failed command is an error, then $(RUN_JOBS)
simulate-sync-full:  # routes=`$(SIM) --list-routes` || exit 1; $(MAKE) simulate-sync SYNC_ROUTES="$$routes"
check-fast:          # lint + validate + fixtures + simulate of ROUTE (default undead-paladin): about 1 min
route:               # make route ROUTE=<id>: validate $(VALIDATE_FLAGS) + simulate that route
```

* `validate`: `VALIDATE_FLAGS` as defined in A.6.3 (`--strict --end-level` from F2a on, the grind budget from
  P2 on, the baseline from phase C on).
* The fixture targets (`validate-fixtures`, `simulate-fixtures`, `harness-fixtures`, the fixture part of
  `routedata-check`) pass `--no-overrides`: the fixtures use real quest ids (Durotar 786-816, Mulgore 743-770,
  3095, 92598) and must not move when an override file changes.
* `LIB` (default of `make harness`) = `addons/FastesBoooy_Guides`.
* Phase F1 keeps the old modules, so it sets `SYNC_ROUTES = horde-undead-paladin horde-skyborne-druid` and the
  old `SYNC_MID`; phase F2 switches to the values above (for the routes that exist), phase P2 to the final list.

CI (`.github/workflows/ci.yml`, one job, `timeout-minutes: 25`), expected wall time on 4 vCPUs:

| Step | Wall |
|---|---|
| checkout, apt, luarocks | 1.5 min |
| lint + validate (28 routes, strict, budgets) + fixtures + harness fixture | 0.3 min |
| busted | 1.3 min |
| simulate, 28 routes (728 CPU-seconds) | 3.0 min |
| simulate-sync, 5 routes x 8 runs (757 CPU-seconds) | 3.2 min |
| routedata-check, report freshness, package | 0.1 min |
| total | about 9.5 min |

(The reviewer's own measurement on 4 CPUs agrees: one simulation 25.4 s, four in parallel 25.9 s wall, the
eight sync runs of one route 145 CPU-seconds, busted 77 s, validator 0.3 s per route.)

CI checks `make routedata-check` and the freshness of `docs/VALIDATION.md`. Parallel agents may not regenerate
either file, so the tree is not CI-clean in the middle of a parallel phase; D.0 rule 2 says who regenerates
them and which commits may be pushed.

A second workflow `nightly.yml` (`schedule` + `workflow_dispatch`) runs `make simulate-sync-full` (about 18 min
on 4 vCPUs). If the hosted runner is slower than measured: first lever, run busted spec files in parallel;
second, drop `--ahead 10` and `--level-plus 2` for all but one route of `SYNC_ROUTES`.

Why a subset is sound for the sync runs: from `h-12` / `h-13` on all routes share the same segments; the subset
has one route per race (Durotar twice) and five different classes; the nightly run covers the rest.

### A.8 Migration and versions

* Versions: core `0.4.0` (TOC, `DEFAULT_VERSION`), `FastesBoooy_Guides` `0.4.0`, every route `version = "0.4.0"`.
* Users delete `FastesBoooy_Horde`, `FastesBoooy_UndeadPaladin`, `FastesBoooy_SkyborneDruid` and install
  `FastesBoooy` + `FastesBoooy_Guides`. If the old folders stay, the core prints the warning of A.5.6; duplicate
  segment registrations are refused with errors and two default routes match (the first registered wins).
  README gets an "Updating from 0.3" paragraph.
* Saved progress: `horde-undead-paladin` -> `undead-paladin` and `horde-skyborne-druid` -> `skyborne-druid`
  through `aliases` (a manually chosen route, the high-water mark and the level-sync floor survive where the step
  id still exists). Marks keyed by step id survive for unchanged explicit ids (all of 22-60). Steps of 1-22 are
  restructured: marks on their old ids become dead entries and the engine rebuilds the position from the quest
  log (`core.md` 3.3). Deleting the three Skyborne-only steps of `h-22-hillsbrad` would shift the positional
  ids of its 42 remaining id-less steps by 3, and a saved mark `h-22-hillsbrad:N` would then mark another step
  as done (marks, the cursor hint and the sync floor are keyed by step id only, `Engine.lua:198-208`,
  `:567-583`, `:601-607`). Therefore F2b gives **every** step of `h-22-hillsbrad` an explicit id in the same
  edit (B.7): old positional marks become dead entries, which is the safe direction. The hub ids P2 adds in
  `h-24` .. `h-56` only turn single positional ids into dead entries; nothing shifts. No data migration code
  beyond `aliases`. `/fb reset` remains the clean start.
* Memory: about 10 MB with all zones and classes loaded against 6.5 MB today (`core.md` section 6): accepted.
  Per-race load on demand is impossible inside two folders.

---------------------------------------------------------------------------------------------------------------

## B. Route design for speed

All levels below are validator levels (quest XP + objective kill XP, no rested XP, no incidental kills).
"Base profile" = a route validated without any class file (`--skip 'Classes/*'`). Levels are **base-profile**
levels unless a class is named; the paladin and druid numbers of the two existing routes are 0.3-0.7 level
higher than the base before level 18 (appendix 1) and must not be used for trainer stops.

### B.1 Start segments and merge point per race

| Race | Own segments | Leaves the start zone at | Joins the shared path at | Evidence |
|---|---|---|---|---|
| Undead | `ud-01`, `ud-02` | 12.1 base (12.8 paladin), in the Undercity; level 12.0 is reached at Brill through the gate `ud02-lvl-12` (B.8) | `h-13-silverpine`, first step (Deathstalker Erland), on foot | `routes.md` 3.6, 8.4; scratch run of the review (appendix 1) |
| Skyborne | `sd-01`, `sd-02`, `sd-03-thunder-bluff` | 13.2-13.3, Skywatcher Plateau -> Thunder Bluff -> flight to Orgrimmar | `h-12-orgrimmar-tirisfal`, first step (Doras) | `routes.md` 8.1, 8.4; the flight is today's `sd03-fly-org` |
| Orc, Troll | `dur-01`, `dur-02` | about 10.96 at Rhinag, outside the Orgrimmar gate, with 812 accepted (north loop done); about 11.2 after 813 / 831 / 812, which are turned in during the city loop of `h-12` (B.2, B.3) | `h-12-orgrimmar-tirisfal`, first step | `startzones.md` 5.1 (steps 1-9), 5.4 option B; DB: 812 starts and ends at Rhinag 3190 (Durotar 41.5, 18.6) |
| Tauren | `mul-01`, `mul-02`, `mul-03-barrens-crossing` | about 11.8 in Thunder Bluff, 11.9 at the Crossroads | `h-12-orgrimmar-tirisfal`, first step, after walking Thunder Bluff -> Camp Taurajo -> Crossroads -> Far Watch Post -> Razor Hill -> Orgrimmar | `startzones.md` 5.2, 5.3; Thunder Bluff has no zeppelin and Tauren do not know the Orgrimmar flight point |

Why everybody goes through Silverpine: it is worth 20.8k XP (Undead order) to 29.3k XP (with the Orgrimmar city
quests and the Tirisfal visitor block), there is no unused 20k XP block in Kalimdor at 12-15 (`routes.md` 8.3),
and the Barrens quests are then met at their planned levels. Projected entry into `h-15-barrens`: Undead 14.05
(base) to 14.56 (paladin), Orc / Troll about 14.0-14.3, Tauren about 14.5, Skyborne about 15.5. Entry into
`h-18`: base Undead 17.64 (paladin 17.99), an Orc from 11.2 about 17.67.

Why the Tauren walk (decision, E.1): the walk Crossroads -> Orgrimmar is about 3100 yd (7-8 min) on top of the
way to the Crossroads that every Tauren path needs. The alternative "Barrens from 12 without Silverpine" ends
the Barrens 1.2-1.7 levels short (about 200 same-level kills at 21, `startzones.md` 5.4 option A). A flight
Thunder Bluff -> Orgrimmar without the flight point is unverified and is not used for the Tauren by default;
E.1 defines the flight variant completely, as a switch P2 can make.

After `h-13` every race is in the Undercity and returns to Durotar: the Undead by zeppelin (their hearthstone
is in Brill), the others by hearthstone (bound in Orgrimmar in `h-12`). From the Orgrimmar gate / the zeppelin
tower the path is identical for all 28 routes: Razor Hill (840) -> Far Watch Post (842) -> the Crossroads.

### B.2 Hand-over contracts of the start zones

A path agent is done when the base profiles of its races meet these numbers; the shared segments then need no
change for that race. These contracts (plus 0 ERROR and the simulations) are the **whole** acceptance of a
start zone: the kill limits of the shared path (B.8) are measured and tuned by the single-owner phases, because
a path agent cannot influence them.

| Zone | State at the last own step | Required by |
|---|---|---|
| Tirisfal (`ud-02` end) | on the Silverpine road north of the Sepulcher; level >= 12.0 base, reached at Brill by the gate `ud02-lvl-12` (B.8); 445 in the log; 96895 -> 96897 / 96898 done; hearth Brill; flight point Undercity | `h-13` (421 needs 12; 445 turn-in at Renferrel) |
| Zephras (`sd-03` end) | in Orgrimmar at Doras (arrived by flight); level >= 13.0 base; 95350 in the log; hearth anywhere; flight point Thunder Bluff | `h-12` |
| Durotar (`dur-02` end) | at Rhinag (Durotar 41.5, 18.6, about 310 yd from the Orgrimmar gate) with 812 just accepted and the 4 venomtail sacs for 813 in the bags; 831 in the log; level >= 10.9 base (>= 11.2 after the three city turn-ins; target 11.5); level 10.0 reached at `dur02-rh-3` (gate `dur02-lvl-10`, B.8); hearth Razor Hill; 837, 806, 99051 may stay in the log (turned in at Razor Hill when the shared path passes it at 14, see below); no `fp` or `sethearth` step in Orgrimmar (`h-12` starts with both) | `h-12` |
| Mulgore (`mul-03` end) | at the Orgrimmar gate; level >= 11.8 base; flight points Thunder Bluff, Camp Taurajo, The Crossroads; 854 / 860 / 886 turned in at the Crossroads (861 before them in Thunder Bluff); hearth Bloodhoof Village | `h-12` |

Common rule for all four: gate `h13-lvl-12` (B.4) must need **at most 10 grind kills in the normal run and at
most 25 in the worst case** for the base profile of the race. If it needs more, the path agent adds content of
its own zone (Durotar: the "elites" block, then the Skull Rock block of `startzones.md` 5.1; Mulgore: 744, then
the Tauren flight chain 6361-6364 as an `optional` block at `mul03-xroads`), not a grind step. The two numbers
are the `h13-lvl-12` row of the validator's gate table (columns "kills" and "worst"); the agent copies that
row into the hand-over.

**Durotar and Orgrimmar (one city loop, not two).** 812 "Need for a Cure" starts and ends at Rhinag, who stands
outside the gate; only Kor'ghan (813, its child, Cleft of Shadow, Orgrimmar 47.2, 53.6) and Nazgrel (831,
Valley of Wisdom, 32.3, 35.8) are inside. A hand-over "inside Orgrimmar after 812" would make 13 routes enter
the city twice (about 1,050 yd, 2.5 min). So `dur-02` ends at Rhinag, and the Durotar file registers three
shared inserts, `race = { "Orc", "Troll" }`, on `h-12` anchors (ids with the zone prefix; the mechanism of
"postponed turn-ins" below):

| Insert | Anchor | Step |
|---|---|---|
| `dur02-korghan` | `after = "h12-borstan"` (Borstan is 140 yd from the Cleft of Shadow) | 813 at Kor'ghan: accept, hand in the 4 sacs |
| `dur02-nazgrel` | `after = "h12-wisdom"` (the city-quest stop in the Valley of Wisdom, 85 yd away) | turn in 831 |
| `dur02-rhinag` | `before = "h12-zeppelin"` | turn in 812 at Rhinag on the way from the gate to the zeppelin tower |

812 is timed in Classic; the DB has no timer length. The note of `dur02-end` and of `dur02-rhinag` names the
timer and says: if it runs short, hand 812 in right after Kor'ghan and come back (the engine accepts the early
turn-in). `-- CONFIRM: timer of 812` (E.20).

**Postponed turn-ins.** A start-zone file may register a shared insert, race-scoped, on a shared-path anchor
for quests of its zone that are cheaper to hand in later. Durotar: `after = "h15-razor-hill"`, `race = { "Orc",
"Troll" }`, step `dur02-rh-return` (turn in 837, 806, 99051). The insert lives in the zone's own file and uses
the zone's id prefix.

Durotar outline: `startzones.md` 5.1 steps 1-8, then Rhinag (the draft's step 9 moves into the city loop of
`h-12`, its steps 10-12 are replaced by the postponed turn-ins and by `h-15`). The class branch 792 (every
class but WARLOCK) vs 1485 -> 1499 (WARLOCK) is written as class-filtered base steps in `dur-01`; both lead to
794. Mulgore outline: `startzones.md` 5.2 steps 1-8, then `mul-03`: Camp Taurajo (`mul03-taurajo`, `fp`), the
Crossroads (`mul03-xroads`: `fp`, turn in 854, 860, 886; optional flight chain), Far Watch Post, Razor Hill,
`mul03-org-gate`. 840 is **not** accepted on the way north (its turn-in lies behind). Mulgore coordinates come
from the DB only (Classic guide coordinates are invalid there).

**The Tauren breadcrumbs and 844.** The DB lists 844 "Plainstrider Menace" in the `exclusive` field of 861 and
of 854, and the validator treats exclusivity as symmetric (`validator.lua:942-955`): once 861 or 854 is turned
in, the shared step `h15-xr-arrive` (accept 844) is ERROR `accept-exclusive` for every Tauren. In the game this
is the normal breadcrumb chain (861 -> 860 -> 844; 860 has `breadcrumbFor = 844`), so the error is false.
`tools/overrides/shared.lua` (F2b) therefore removes 844 from `exclusive` of 861 and of 854 (`verified =
false`, source: the DB chain itself and Classic; `-- CONFIRM`). A scan of every accept of the shared path 12-60
against the Durotar and Mulgore drafts found no other such pair. F2b proves it with a spec that replays 861 and
854 before the 844 accept and with the synthetic Tauren state of D.2, which carries the real hand-over history.

### B.3 `h-12-orgrimmar-tirisfal` (12-13, every race but the Undead)

Source: today's `sd-03` steps 10-34 (`routes.md` 3.9, 4.6). Outline and ids:

1. `h12-fp-org`: `fp` Orgrimmar at Doras. `h12-sethearth-org`: bind at Innkeeper Gryshka.
2. City quests (Forever-new, XP estimated): 97246 -> 97249, 97242 -> 97275, 97326 (`optional`). They belong to
   this segment and to no start zone. Two of their stops have fixed ids because other files anchor on them:
   `h12-borstan` (97246 -> 97249 at Borstan, the Drag) and `h12-wisdom` (the stop in the Valley of Wisdom:
   97249 turn-in, 97326). `h12-org-end`: the last generic city step (training anchor).
3. `h12-zeppelin`: leave by the main gate, zeppelin tower in Durotar -> Tirisfal.
4. `h12-brill`: accept 96895 (Deathguard Terrence) and 445 (Apothecary Johaan); Hadric Harlson 96895 -> 96897 +
   96898; cult camp; turn-ins.
5. `h12-fp-uc`: `fp` Undercity (training anchor, about 12.0-12.5; P2 measures it per race). `h12-end`: through
   the sewers to the Silverpine road.

Additions by other files: Skyborne (`Races/Skyborne.lua`): Thrall 95350 -> 98024 and the optional 1061 at Zor
Lonetree, inserted at a city anchor; their turn-ins at `h15-xr-thork` and `h18-border`. Orc and Troll (the
Durotar file): the three inserts of B.2.

### B.4 `h-13-silverpine` (13-15, all races)

Source: `ud-03` order (it saves the third trip north), `routes.md` 4.4. The 23 common quests: 435, 429, 449,
421, 477, 437, 3221, 445 (turn-in), 430, 447, 1359, 422, 91920, 425, 423, 438, 424, 439, 478, 481, 482, 97891,
1358 (accept). 91921 is not done.

1. `h13-erland`: accept 435; escort; Rane Yorick 435 -> 429 + 449.
2. Sepulcher 1: `h13-lvl-12` (**gate `level = 12`, before the accept of 421**), 421, 477, 449 -> 437 + 3221,
   Renferrel (429, 445, 3221 -> 430, 447, 1359), `h13-fp-sepulcher`.
3. Whitescalps; Sepulcher 2 (421 -> 422); north: spellbooks, Quinn 430 -> 91920, Rane 425, Ivar, Dead Field,
   spiders and bears; Sepulcher 3 (422 -> 423, 437 -> 438, 91920); gluttons; Sepulcher 4 (423 -> 424).
4. Ferry 438 -> 439, Grimson 424, Dalaran crate 477 -> 478; Sepulcher 5 (`h13-sepulcher-5`: 478 -> 481 -> 482,
   424, 439); `h13-lvl-14` (trainer-hub gate, B.8: the Undercity and Orgrimmar follow and the next trainer
   after them is at 18).
5. Way back, an alternative pair: `h13-hearth-brill` + 439 -> 440 -> 441 (`race = "Scourge"`, bound in Brill)
   vs `h13-fly-uc` (`race = { "Orc", "Skyborne", "Tauren", "Troll" }`). Join: `h13-uc-arrive`.
6. Undercity: `h13-uc-arrive`, 97891 (timed), 447, 1359 -> 1358, `h13-uc-end` (training anchor; base Undead
   14.0, paladin 14.5).
7. Exit, an alternative pair: `h13-zeppelin` (`race = "Scourge"`: lift, zeppelin to Durotar) vs
   `h13-hearth-org` (the other four races: hearthstone to Orgrimmar). Join: `h15-org` (B.5).

Undead-only additions (`Races/Scourge.lua`): 6321 -> 6323 -> 6322 (race-locked in the DB).

**Alternative pairs** (here and in B.5, B.6): each alternative carries a race filter, so by A.5.1 rule 9 it
exists only in the routes of its races. Every pair ends on an **unfiltered join step**, and the join step is
the anchor for class and race files. A class insert is anchored on a filtered alternative only when the step
is meant for those races alone, and then it carries the same race scope (A.5.1 rule 10).

### B.5 `h-15-barrens` (15-18, all races)

Source: the union of `ud-04` and `sd-04`, Undead order (`routes.md` 4.1-4.4). Quest set: the 44 quests both
routes do in segment 04, plus 875 and the optional 883; 896 and 819 -> 821 optional.

0. Start. Undead only (`race = "Scourge"`): `h15-org-gate` (from the zeppelin tower into Orgrimmar) and
   `h15-org-fp` (`fp` at Doras). The other races arrive by hearthstone at the inn, 130 yd from Doras. Then for
   all races the join step `h15-org` (a `go` step in the Valley of Strength whose radius covers the inn and
   Doras; **the training anchor "Orgrimmar at 14"**, base 14.0-14.3, paladin 14.6), then `h15-start` (all
   races: leave Orgrimmar by the main gate). Class steps go `after = "h15-org"`, never after `h15-start`.
1. `h15-razor-hill` accept 840; `h15-far-watch` 840 -> 842.
2. Crossroads 1: `h15-xr-arrive` 842 -> 844; 870; `h15-xr-thork` 867, 871, 5041; 1358 -> 848 + 1492; 869;
   `h15-fp-xroads`; `h15-sethearth-xroads`.
3. Thorn Hill 871; Crossroads 2 (`h15-xr-2`: 844 -> 845, 871 -> 872); far camp 872 + 5041.
4. Ratchet 1 (`h15-fp-ratchet`, 97253, 887, 895, 894, 1492 -> 896), pirates, Ratchet 2 (`h15-ratchet-2`: 887 /
   895 -> 890 -> 892 -> 888, 97253); `h15-fly-xroads`.
5. Crossroads 3 (`h15-xr-3`: 872 / 5041, 845 -> 903); Regthar 850 + 855; Barak; Forgotten Pools; Regthar 850 ->
   851; Crossroads (870 -> 877, 903 -> 881).
6. North loop: Echeyakee, mine (896, optional), Sludge Fen (858 -> 863), Samophlange (894 -> 900 -> 901 -> 902),
   Vrang and Walton (95494, 95507 -> 95495 -> 95621 -> 95508), harpies 867; `h15-hearth-xroads`.
7. Crossroads 4 (`h15-xr-4`): 869 -> 3281, 867 -> 875, 881 -> 905, Mankrik (899, 4921, 95774); `h15-fly-ratchet`.
8. Ratchet 3 (`h15-ratchet-3`): 863 + 902, 896 (optional), 865, 1483, 1069, 819 -> 821 (optional).
9. South sweep: crates 888, silver 3281, Stagnant Oasis (877, 848, Verog), nests (905, 865), Raiders (95774),
   corpse (4921); Camp Taurajo: `h15-fp-taurajo`, `h15-sethearth-taurajo`, accept 878; `h15-fly-xroads-2`.
10. Crossroads 5 (`h15-xr-5`): 4921 + 95774, 877 -> 880, 905 -> 3261, 3281, 851 -> 852 (Regthar),
    `h15-end` 848 -> 853 (timed, 45 min).

Race-specific: Orc + Troll flight chain 6365 -> 6384 -> 6385 -> 6386 (1890 XP, full XP up to level 15) as an
`optional` block in `Races/Orc.lua` and `Races/Troll.lua` after `h15-sethearth-xroads` (Crossroads -> Orgrimmar
-> Crossroads by flight). The Undead do the four fixed Orgrimmar city quests here (`Races/Scourge.lua`, after
`h15-org-fp`, B.8). `h15-fp-xroads` and `h15-fp-taurajo` carry a race filter that excludes exactly the races
whose own bridge segment already learns the point: the Tauren in the walk variant of `mul-03`, nobody in the
flight variant (E.1), and also the Skyborne if `sd-03` falls back to the walk (E.2). P2 sets the filter from
the variant that is in force; it is not hard-coded to "Tauren".

### B.6 `h-18-stonetalon-ashenvale` (18-22, all races)

Source: `ud-05` order with the Skyborne extras (`routes.md` 4.4): three Thunder Bluff stops at 18, 20 and 22
give every class with a Thunder Bluff trainer a class-neutral training stop. Quest set: the 27 common quests of
segment 05 plus 216, 6462, optional 884, 6641, 1090 / 1092 optional. 6301 is **not** done here (B.7).

1. `h18-fly-taurajo`; Jorn 3261 -> 882; `h18-lvl-18` (trainer-hub gate at Camp Taurajo, B.8). Thunder Bluff 1,
   an alternative pair: `h18-fly-tb-1` (`race = { "Skyborne", "Tauren" }`, flight point known) vs
   `h18-go-mulgore`, `h18-go-tb-lift`, `h18-fp-tb` (`race = { "Orc", "Scourge", "Troll" }`). Join:
   `h18-tb-zamah` 853; `h18-tb-1` (training anchor: 18.0 through the gate; without it the base Undead is at
   17.7 and an Orc at about 17.7); `h18-fly-ratchet`.
2. Ratchet (`h18-ratchet`: 865, 888); Ishamuhale 882; Stagnant Oasis (880, Verog); `h18-hearth-taurajo`.
3. Camp Taurajo chain: 882 -> 907, Bristleback camp (878 + 899), 907, 878 -> 5052, 907 -> 913, 913; optional 884;
   `h18-taurajo-end`; `h18-fly-xroads`.
4. Crossroads (`h18-xr`: 880 + 899 -> 1489, 875); Regthar, Lushwater (852, 855), harpy lieutenants 875;
   `h18-border` (1062, 6548).
5. Stonetalon pass 1: Aparaje 6548 -> 6629, Grundig, Kaya 6523, Makaba, Xen'Zilla 6461, Ziz 1483 -> 1093,
   Windshear Crag, `h18-lvl-20` (gate before the level-20 stop), Ziz 1093 -> 1094, Sun Rock: 6562, 6401,
   `h18-fp-sunrock`.
6. `h18-fly-tb`: Thunder Bluff 2: `h18-sethearth-tb`, 1489 -> 1490, `h18-tb-2` (training anchor, about 20.3);
   `h18-fly-ratchet-2` (821, 1094 -> 1095, 1069); `h18-fly-xroads-2`.
7. Border 1062 -> 1063; Xen'Zilla 6461; Piznik 1090 -> 1092 (optional); Ziz (1092, 1095); Talondeep Path.
8. Ashenvale: Va'xug 98251 -> 98252; Zoram'gar (6562, 6442, 6462, `h18-fp-zoram`, optional 6641); naga + gate
   `h18-lvl-21`; 216; Thistlefur (216, 6462); Zoram'gar turn-ins + gate `h18-lvl-22`.
9. `h18-hearth-tb`; 1063 -> 1064 (Magatha), 1064 (Zamah); `h18-tb-3` (training anchor, 22.0); `h18-end`.
   1065 is not accepted here.

End state (what `h-22-hillsbrad` assumes, `routes.md` 6.1): in Thunder Bluff, hearth Thunder Bluff, level
about 22, flight points Thunder Bluff, The Crossroads, Camp Taurajo, Ratchet, Sun Rock Retreat, Zoram'gar
Outpost, The Sepulcher, Undercity, Orgrimmar; 1064, 5052, 913, 1095, 6562 turned in; 1065 not in the log;
6301 not done.

### B.7 Changes in `h-22` .. `h-56`

No quest changes in the mandatory phases (the 22-60 path validates with 0 errors for six other race + class
profiles, `routes.md` 6.3; scope decision R9; the optional phase P3 is the only one that may change quests
there). Only:

* `h-22-hillsbrad` (F2b): remove the race filter of `h-22-tb-start` (everyone accepts 1065 there) and of
  `h-22-tb-fly-org`; delete `h-22-tb-fly-xroads` and the two `go` steps after it (the Skyborne detour is wrong);
  give the first Undercity step the id `h-22-uc-arrive`; and, in the same edit, **give every other id-less step
  of this segment an explicit id** (`h22-<what>`, 41 more steps), so that no positional id shifts onto another
  step (A.8).
* `h-24-barrens-stonetalon` (F2b): remove the race filter of the three 6301 steps (`h-25-sun-rock-retreat` and
  the two anonymous steps; the latter get ids `h25-rebirth-seeds`, `h25-rebirth-turnin`). 6301 is done here by
  every race.
* `h-50-hinterlands-searing-steppes` (F2b): the Owen Thadd step (step 12) gets the id `h50-owen-thadd`.
* `h-24` .. `h-56` (P2): explicit ids on the hub steps class files need (D.4 step 5). No step is added, removed
  or reordered.
* Comments that name the two old profiles are reworded. No filtered step is left in 22-60.

### B.8 Level gates and the cost rule: the base profile must pass everything

Rule: **every accept in a shared or start-zone segment must meet its `reqLevel` for the base profile of every
race, in the worst case (optional steps skipped), with zero class-quest XP.** Class quests are a bonus that
only lowers the kill counts at the gates.

* Gates are plain `level = N` (or `{ N, fraction }`) steps with explicit ids and a class-neutral note. Two kinds
  are allowed:
  1. **Requirement gates**, right before an accept whose `reqLevel` the base profile could miss.
  2. **Trainer-hub gates**: `level = N` with N even, right before the path enters a hub with class trainers (or
     before the hearth / flight that leads there). Every class trains at even levels, so the gate is
     class-neutral; its note says "level N: new ranks at the trainers in <city>". It is placed where the base
     profile of at least one race arrives less than 0.4 level short of N. Limit: **at most 45 kills in the
     normal run for the base profile of any race**. If a race needs more, P2 lowers the gate to `{ N-1,
     fraction }` or removes it, and the class files mark the training at N in that hub `optional`. XP ground
     here is not lost: the same XP is missing at a later gate otherwise (a kill at 17 gives 130 XP, at 21 150:
     the shift costs about one extra kill in seven).

  A gate is never tuned to a class quest. A class file adds its own class-scoped gate when a class quest needs
  a level.
* Gates of the shared 12-22 path (created in F2b with these ids, tuned by P2): `h13-lvl-12` (421),
  `h13-lvl-14` (trainer-hub gate before the way back to the Undercity: base Undead 14.0, Orc / Troll projected
  13.9-14.2; the next trainer after the Undercity and Orgrimmar is at 18), `h15-lvl-16` (only if a kept quest
  needs it; the old druid gate at the mine is dropped), `h18-lvl-18` (trainer-hub gate before Thunder Bluff 1:
  base Undead 17.64-17.70, an Orc from 11.2 17.67; about 5,300 XP = 41 kills at 17, of which about 35 come off
  `h18-lvl-22`), `h18-lvl-20` (before Thunder Bluff 2), `h18-lvl-21`, `h18-lvl-22` (hand-over to `h-22`).
* Gates of the start zones: `ud02-level-10`; `ud02-lvl-12` (trainer-hub gate before `ud02-hearth-2`: the base
  Undead is at 11.9-12.0 there, 1-9 kills; it is today's paladin-only optional `ud02-xp-12`, made generic and
  mandatory; `h13-lvl-12` then needs 0 kills for the Undead); `sd02-level-10`; `dur02-lvl-10` (at
  `dur02-rh-3`: the draft arrives at 9.88, about 9 kills; this is the only Razor Hill visit before level 14, and
  level-10 training and the level-10 class quests of hunter 6062 and warrior 1505 start there); and whatever
  the validator demands (`level-too-low`) in Durotar and Mulgore (815 and 837 need 6, 861 needs 10, 99048
  needs 9). A path agent first tries to reach the level with quest order; the gate stays as the guarantee.
* **Targets for the base profiles** (a criterion of the single-owner phases F2b / F2d / P2, enforced by
  `--max-grind-until h-18-stonetalon-ashenvale=120/200`): grind kills from level 1 to the end of `h-18`: at
  most 120 in the normal run and at most 200 in the worst case, per race. For comparison: today's Undead
  without class quests needs about 110 normal and about 150 worst (two scratch runs that strip the mixed steps
  differently: 108 / 147 and 116 / 152; the one gate `ud05-lvl-grind` alone is 106 / 107, the worst-case rest
  sits at `ud05-lvl-pre20` and `ud05-lvl-21`); today's Skyborne druid 0 (worst 40).
* **Cost rule: no grind while cheaper quest XP is unused on the path.** The validator has no time model, so
  the author compares by hand (E.15): a same-level kill gives `45 + 5 x level` XP and is counted as 30 s, so
  1,000 XP of grind cost about 4.8 min at 12, 3.3 min at 21, 2.0 min at 40 and 1.5 min at 57. A quest block is
  added when its extra time (travel at 420 yd per minute on foot, 10 s per dialog, its own kills) per 1,000 XP
  is below that, measured at the gate where the XP would otherwise be ground. Order of content to add when a
  race is above the target: its own start-zone options (B.2); for the Undead the Orgrimmar city quests; the
  Orc / Troll or Tauren flight chain.
* **Undead: the Orgrimmar city quests are the default, not a fall-back.** The four fixed quests 97246 ->
  97249 and 97242 -> 97275 (reqLevel 5 / 9, quest level 15, about 4,200 XP at the estimate of 1,050 each) are
  a non-optional insert in `Races/Scourge.lua` after `h15-org-fp`; 97326 is `optional` as in `h-12`. The Undead
  walk to Doras anyway; the extra running is about 1,550-1,750 yd (4 min) plus dialogs, against 28 kills
  (14 min) at the 21.85 gate, where the base Undead grinds 106 kills today. F2b measures the real loop.
* 22-60: the gates exist and stay. The grind there (4,934 kills, worst 6,068, for a base profile; 4,897 of the
  paladin's 4,972) is the same for every route; class quest XP lowers it per class. Their `ok` ceilings and the
  baseline budget (A.6.3) keep any route from exceeding it. Reducing it is phase P3 (optional, R9).

### B.9 Trainer cities on the shared path, 12-22

There is no class trainer in the Barrens, Stonetalon, Ashenvale or Silverpine. The shared path passes (levels
of the base profiles; "gate" = guaranteed by a trainer-hub gate of B.8):

| Level (base) | City | Anchor | Trainers there |
|---|---|---|---|
| 11.2-13.4 | Orgrimmar | `h12-org-end` (Orc, Troll, Tauren, Skyborne) | all but druid, paladin |
| 12.0 (gate) | Brill | `ud02-hearth-2` (Undead) | the Brill trainers |
| 12.0-13.9 | Undercity | `ud02-fp-uc` (Undead, 12.0-12.1), `h12-fp-uc` (others, about 12.0-12.5) | all but hunter, shaman, druid |
| 14.0 (gate) - 15.3 | Undercity | `h13-uc-end` | same |
| 14.0-15.5 | Orgrimmar | `h15-org` (all races) | all but druid, paladin |
| 18.0 (gate) - 19.0 | Thunder Bluff | `h18-tb-1` | all but rogue, warlock |
| 20.0 (gate) - 20.3 | Thunder Bluff | `h18-tb-2` | same |
| 22.0 (gate) | Thunder Bluff | `h18-tb-3` | same |
| 22.06 | Orgrimmar, Undercity | `h-22-org-fp`, `h-22-uc-arrive` | (22-60 table: `classes.md` 4.2) |

P2 applies the trainer-hub rule to `h12-org-end` and `h12-fp-uc` with the measured levels of the four races
(a gate there only if a race is within 0.4 level under 12 and the limit of 45 kills holds).

Level 16 has no city: a class that needs its level-16 ranks adds an optional "fly to Orgrimmar and back" insert
at a Crossroads flight step (`h15-hearth-xroads` or `h15-fly-ratchet`). Rogue and warlock have no trainer in
Thunder Bluff: their 18-20 ranks come from an optional Orgrimmar round trip at `h18-fly-ratchet-2` or wait for
22.06. The druid trains in Moonglade (Teleport) right before a hearth step: `h13-hearth-org` (a filtered step
of the four non-Undead races, which is right: an Undead is never a druid), `h15-hearth-xroads`,
`h18-hearth-taurajo`, `h18-hearth-tb`.

---------------------------------------------------------------------------------------------------------------

## C. Class and race step conventions

### C.1 Files and shape

`Classes/<Class>.lua` holds every step that exists because of the class, for all races of that class:
level-1 letter, class quest chains, training visits, weapon skills, class mounts (Felsteed, Warhorse), pet /
portal / poison / demon services, class reward choices. `Races/<Race>.lua` holds every step that exists because
of the race on the shared path: riding and the mount at 40, racial quests (Skyborne 95350 / 98024 / 1061,
Undead 6321-6323), race-locked flight chains.

```lua
-- FastesBoooy_Guides / Classes / Warrior.lua
-- (header: sources, per-zone table of visits with the validator level, what is skipped and why)
if not FastesBoooy.AddLibraryInsert then return end
local insert = FastesBoooy.AddLibraryInsert

FastesBoooy.AddLibraryData({ rewards = { WARRIOR = { [92461] = 3 } } })       -- at most one call per file

-- Durotar (Orc, Troll) --------------------------------------------------------
insert({ after = "dur01-teeth", class = "WARRIOR", race = "Orc", steps = {
    { id = "war-dur-letter-orc", accept = 2383, npc = 3143, at = { 1411, 42.1, 68.3 },
      note = { ru = "...", en = "..." } },
} })
```

Hard rules (checked by `tests/spec/guides_layout_spec.lua`, D.2, and by the module checks of A.6.2):

1. Every insert of `Classes/<Class>.lua` has `class = "<CLASS>"` at insert level (exactly that one class).
   Every insert of `Races/<Race>.lua` has `race = "<raceFile>"` at insert level. So a file can never change a
   route of another class / race, and scope pruning keeps its steps out of those routes.
2. Step ids: `<prefix>-<zone>-<what>` below level 12 with zone tags `dur`, `mul`, `tir`, `zep`
   (`war-dur-letter-orc`, `sha-mul-earth-1`), `<prefix>-<what>` on the shared path (`war-train-24`,
   `war-30-berserker-2`, `wlk-40-felsteed-1`).
3. A step that is only right for some races of the class carries `race = ...` on the step or the insert (the 28
   letters are 28 different quest ids; level-10 chains differ per race, `classes.md` section 5). Quests with a
   class sort but no class mask in the DB still sit in class-scoped inserts.
4. Notes are bilingual and name the place and the NPC; a `train` step lists the important `spells`.
5. No `reward` on shared base steps; class reward choices go into the class reward table (A.5.4).

### C.2 Anchors

An anchor is a generic step with an explicit id. Levels are approximate base levels before the step. Anchor
steps are placed **after** the generic quest steps of the visit at that hub. Anchors are unfiltered steps (join
steps of alternative pairs included); the few filtered ones are marked.

How binding the tables are:

* Tirisfal, Zephras: the ids are fixed (F2c creates them; several exist today). As executed, the binding lists
  are those of the F2c hand-overs (`f2c-tirisfal.md` section 3, `f2c-zephras.md` section 4, with the measured
  levels) and the `ANCHORS` table of `tests/spec/guides_layout_spec.lua`; five Tirisfal rows below differ from
  the tree (F2c deviations 1, 3, 5, 8, 9; for example the paladin's level-4 insert stands after `ud01-aramis`,
  the optional accept of 98389, not after `ud01-church-4`). Read levels from `--levels`, never from these tables.
* Shared path 12-22: the ids are fixed (F2b creates them).
* Durotar, Mulgore: the tables are the **draft** of `startzones.md` section 6. Hard contract are only the
  hand-over ids (`dur02-end`, `mul03-org-gate`), the letter anchors (`dur01-teeth`, `mul01-hunt`), the class
  branch (`dur01-familiars`, `dur01-warlock-1485`) and the rule "one anchor per visit of a hub with trainers or
  class quest givers, on the last generic step of the visit". A path agent that finds a faster hub order with
  other visits uses its own `dur02-*` / `mul02-*` ids and publishes the real list with levels in its hand-over.
  P2 writes that list into the layout spec and freezes it; class agents start after the freeze and read
  `levels-<race>.tsv`, so nothing depends on the draft names.
* After the freeze (end of P2, or of P3 if it runs) nobody renames or removes an anchor.

Tirisfal (Undead; created in F2c):

| Anchor | Step | Level | Typical use |
|---|---|---|---|
| `ud01-364` | turn in 364 at Sarvis, accept 3901 + 376 | 1.5 | class letter (3095-3099, 98601), first training |
| `ud01-church-4` | generic turn-ins of the level-4 visit (3901, 376; accept 6395) | 4.0 | training at 4 |
| `ud01-381` | turn in 381 | 5.3 | last Deathknell trainer visit (start-camp trainers teach to 6) |
| `ud01-382` | last step of `ud-01` | 5.7 | - |
| `ud02-sethearth` | bind in Brill | 6.5 | training at 6 |
| `ud02-brill-8` | last generic quest step of the level-8 Brill visit | 8.3 | training at 8 |
| `ud02-level-10` | generic gate `level = 10` in Brill (96895 needs 10) | 10.0 | training at 10, level-10 class quests |
| `ud02-keep` | first generic step at Bandarion Keep | 11.3 | paladin chain |
| `ud02-lvl-12` | generic trainer-hub gate `level = 12` at the keep, before the hearth (B.8) | 11.9-12.0 | - |
| `ud02-hearth-2` | hearth to Brill after the keep | 12.0 (gate) | training at 12 |
| `ud02-fp-uc` | `fp` Undercity | 12.0-12.1 | Undercity trainers, weapon master, class quests |
| `ud02-silverpine-road` | last step of `ud-02` | 12.1 | - |

Zephras (Skyborne; created in F2c; `sd03-*` in F2b):

| Anchor | Step | Level | Typical use |
|---|---|---|---|
| `sd01-rorian` | turn in 92461 + 92474, accept 92464 at Rorian (the generic half of today's step 10) | 3.0 | class letter (92482-92485, 92532), first training |
| `sd01-thendal-4` | last generic step of the level-4 Thendal visit | 4.6 | training at 4 |
| `sd01-innkeeper` | Shen'dar inn | 6.3 | training at 6 |
| `sd01-shendar-8` | last generic step of the level-8 Shen'dar visit | 8.9 | training at 8 |
| `sd02-level-10` | generic gate `level = 10` | 10.0 | - |
| `sd02-valanaar-10` | first generic Valanaar step after the gate | 11.2 | training at 10, level-10 class quests (bear chain) |
| `sd02-hearth` | hearth to Valanaar | 12.9 | training at 12 |
| `sd02-plateau` | arrival on Skywatcher Plateau | 13.2 | plateau trainers (druid, shaman) |
| `sd03-spirit` | Thunder Bluff spirit healer | 13.3 | Thunder Bluff trainers, druid 94911 -> 94913 |
| `sd03-fp-tb` | `fp` Thunder Bluff | 13.3 | - |
| `sd03-fly-org` | last step of `sd-03` (flight to Orgrimmar) | 13.3 | - |

Durotar (Orc, Troll; created in P1; draft, see above; details `startzones.md` section 6):

| Anchor | Step | Level | Typical use |
|---|---|---|---|
| `dur01-teeth` | turn in 788 at Gornek | 2.5 | class letter (race x class id), first training |
| `dur01-familiars` | accept 792 at Zureetha (`class` = all but WARLOCK) | 4.0 | shaman 1516 |
| `dur01-warlock-1485` | accept 1485 (`class = "WARLOCK"`, the base-step alternative) | 4.0 | warlock imp chain |
| `dur01-den-4` | turn in 792 / 5441 in the Den | 4.7 | training at 4; shaman 1517 -> 1518 |
| `dur01-leave` | turn in 794, accept 805 + 96652 | 5.4 | last Valley of Trials trainer visit |
| `dur02-senjin-1` | turn in 805 at Master Gadrin | 5.4 | mage trainer (none in Razor Hill) |
| `dur02-rh-1` | first Razor Hill turn-ins | 6.0-6.5 | training at 6; priest 5648 |
| `dur02-rh-2` | Razor Hill after Tiragarde | 7.8 | training |
| `dur02-senjin-3` | Sen'jin after the Echo Isles | 9.4 | mage training at 8 |
| `dur02-lvl-10` | generic trainer-hub gate `level = 10` at Razor Hill (B.8) | 9.9 | - |
| `dur02-rh-3` | Razor Hill after the hearth, after the gate | 10.0 (gate) | training at 10; level-10 class quests and breadcrumbs (hunter 6062, warrior 1505, shaman 2983) |
| `dur02-thunder-ridge` | generic Thunder Ridge kills (97282 / 806) | 10.5 | only for a warrior who already holds 1498 (see below) |
| `dur02-end` | last step of `dur-02`: accept 812 at Rhinag, outside the Orgrimmar gate | 10.9-11.0 | - |

Orgrimmar class steps of Orc and Troll at 11 (hunter 6081, rogue 1963, warlock 1501, priest 5654, training,
weapon master) use the `h-12` anchors (`h12-fp-org`, `h12-borstan`, `h12-wisdom`, `h12-org-end`), which the
Tauren and Skyborne of the class share; a step that is right for Orc and Troll only carries their race scope.

**Chains whose giver stands at Far Watch Post** (decision). Warrior 1498 "Path of Defense" is given and taken
back by Uzzek at Far Watch Post (Barrens 61.4, 21.1); the shaman's 2983 goes to Kranal Fiss (640 yd west of the
post). The Durotar path does not reach Far Watch Post; the shared path passes it at `h15-far-watch` (about
14.3). Approximate distances (map coordinates; the path agent publishes exact ones): Razor Hill -> Far Watch
Post 1,000 yd, Far Watch Post <-> Thunder Ridge 750 yd, Razor Hill <-> Thunder Ridge 780 yd. The reward of
1498 is handed out at Uzzek, so the stance cannot arrive before the path is at Far Watch Post again, whatever
is done at 10. Therefore, for Orc and Troll: the breadcrumbs (1505 at Tarshaw, 2983 at Swart) are accepted at
`dur02-rh-3` with no detour and carried; the chains start at `h15-far-watch` with a class-scoped detour from
there (warrior: Thunder Ridge and back, about 1,500 yd; shaman: Kranal Fiss, then the chain). A warrior agent
may instead fetch 1498 at 10 from `dur02-thunder-ridge` (Thunder Ridge -> Uzzek -> Thunder Ridge, about
1,500 yd, the scales then drop from the generic kills) if the real hub order of the Durotar hand-over makes
that detour shorter than three minutes; the turn-in stays at `h15-far-watch`. The Tauren pass Uzzek at
`mul03-far-watch` (11.9) and start there.

Mulgore (Tauren; created in P1; draft, see above):

| Anchor | Step | Level | Typical use |
|---|---|---|---|
| `mul01-hunt` | turn in 747 at Grull Hawkwind | 2.9 | class letter (3091-3094), first training |
| `mul01-ravine` | accept 757 | 4.0 | training at 4; shaman 1519 |
| `mul01-leave` | turn in 757 / 780 / 3376 at Camp Narache | 6.0 | training at 6; shaman 1520 -> 1521 |
| `mul02-bh-1` | first Bloodhoof turn-ins | 6.8 | training |
| `mul02-bh-2` | Bloodhoof after the south-west loop | 8.1 | training at 8 |
| `mul02-bh-5` | Bloodhoof after the west loop / Venture Co. | 10.6 | training at 10; hunter 6061 -> 6087 -> 6088, shaman 2984, warrior 1505, druid 5928 |
| `mul02-tb` | Thunder Bluff arrival (775 turn-in) | 11.3 | training, weapon master, druid 5922, hunter 6089 |
| `mul02-end` | last step of `mul-02`, in Thunder Bluff | 11.8 | - |
| `mul03-taurajo` | `fp` Camp Taurajo | 11.8 | druid 6002 (Lunaclaw) |
| `mul03-xroads` | the Crossroads: turn in 854, 860, 886 | 11.9 | - |
| `mul03-far-watch` | passing Far Watch Post | 11.9 | warrior 1498 (Uzzek), shaman (Kranal Fiss is 640 yd west) |
| `mul03-org-gate` | last step of `mul-03` | 11.9 | - |

Shared path 12-22 (created in F2b): every step of `h-12` .. `h-18` has an explicit id; the anchors that class
and race files may rely on are those named in B.3-B.6 and B.9:
`h12-fp-org`, `h12-sethearth-org`, `h12-borstan`, `h12-wisdom`, `h12-org-end`, `h12-zeppelin`, `h12-brill`,
`h12-fp-uc`, `h12-end`;
`h13-erland`, `h13-lvl-12`, `h13-fp-sepulcher`, `h13-sepulcher-5`, `h13-lvl-14`, `h13-hearth-brill` (F),
`h13-fly-uc` (F), `h13-uc-arrive`, `h13-uc-end`, `h13-zeppelin` (F), `h13-hearth-org` (F);
`h15-org-gate` (F), `h15-org-fp` (F), `h15-org`, `h15-start`, `h15-razor-hill`, `h15-far-watch`,
`h15-xr-arrive`, `h15-xr-thork`,
`h15-fp-xroads`, `h15-sethearth-xroads`, `h15-xr-2`, `h15-fp-ratchet`, `h15-ratchet-2`, `h15-fly-xroads`,
`h15-xr-3`, `h15-hearth-xroads`, `h15-xr-4`, `h15-fly-ratchet`, `h15-ratchet-3`, `h15-fp-taurajo`,
`h15-sethearth-taurajo`, `h15-fly-xroads-2`, `h15-xr-5`, `h15-end`;
`h18-fly-taurajo`, `h18-lvl-18`, `h18-fly-tb-1` (F), `h18-fp-tb` (F), `h18-tb-zamah`, `h18-tb-1`,
`h18-fly-ratchet`, `h18-ratchet`,
`h18-hearth-taurajo`, `h18-taurajo-end`, `h18-fly-xroads`, `h18-xr`, `h18-border`, `h18-lvl-20`,
`h18-fp-sunrock`, `h18-fly-tb`, `h18-sethearth-tb`, `h18-tb-2`, `h18-fly-ratchet-2`, `h18-fly-xroads-2`,
`h18-fp-zoram`, `h18-lvl-21`, `h18-lvl-22`, `h18-hearth-tb`, `h18-tb-3`, `h18-end`.
(F) = race-filtered alternative: it exists only in the routes of its races (A.5.1 rule 9); an insert on it needs
the same race scope (rule 10). `h15-fp-xroads` and `h15-fp-taurajo` may become filtered in P2 (B.5).

Shared path 22-60: the existing explicit ids (364), every step of `h-22-hillsbrad` (F2b), and the hub ids P2
adds before the freeze (D.4 step 5: every arrival, hearth, fly, fp, sethearth and turn-in step in a city or
hub of the 37 stops of `classes.md` 4.2 and of the list in 8.1). City and hub stops with levels and which class
has a trainer there: `classes.md` 4.2 and 8.1. New in F2b: `h-22-uc-arrive`, `h25-rebirth-seeds`,
`h25-rebirth-turnin`, `h50-owen-thadd`. Known trainer gaps a class file must solve itself (`classes.md` 4.3):
rogue and warlock 22.06 -> 31.05 (fix: from `h-24-tarrenmill-end` fly to the Undercity, train, then the path's
hearth `h-24-tb-hearth`); shaman 31.05 -> 36.06; hunter and shaman after 57.2 (Orgrimmar after `h-60-end`).

### C.3 Rules every insert must respect (from `docs/ROUTE_FORMAT.md`)

1. **Look-ahead rule.** No `train` / `vendor` / `fp` / `sethearth` step at NPC X when, within the next 6 steps
   of the composed route, a step only accepts quests of X or turns in completed quests of X: the automation
   takes the quest first and fast-forwards the visit. Merge them into one step (`{ train = true, turnin = A,
   accept = B, npc = X }`) or put the visit after the quest step. Class trainers that also give the class quest
   are the usual case. Validator: `WARN lookahead-skip`.
2. **Transient steps follow something the player has just done.** `go`, `train`, `fp`, `fly`, `sethearth`,
   `vendor`, `manual` are skipped when a later stateful step is already done. Anchor a transient insert `after`
   the step the player completes at that place, never in front of a quest step that can already be complete.
   Validator: `WARN skip-ahead`.
3. **Leave the path where it was.** After an insert the next shared step must still work: the player is at the
   same place, or the next shared step is a `fly` / `hearth` that works from the new place. A detour brings its
   own travel there and back. An insert never uses the hearthstone, except right before a shared `hearth` step
   (the druid's Moonglade pattern).
4. **No quest of the shared path** is accepted, completed or turned in by a class or race file, and no shared
   gate is changed. A class quest that needs a level gets a class-scoped `level` step in the class file.
5. **Service steps.** Class trainer: `train = true` with `npc`. Weapon master, riding trainer, pet trainer,
   portal trainer: `train = true` with `npc` (validator INFO `train-service`). Demon trainer, poison / reagent /
   ammunition vendor, mount vendor: `vendor = true` with `npc`. Never use the Thunder Bluff "Rogue Trainer?"
   205729. Start-camp trainers (Valley of Trials, Camp Narache, Deathknell, Thendal) teach only to level 6.
6. **Ordering at a shared anchor** is: segment-file inserts, class file, race file. Do not anchor on a step of
   another file's insert (as executed, C.7 needs no such anchor any more; the layout spec forbids a race file
   anchored on a class step).
7. **Acknowledging a WARN**: fix it if possible; otherwise `ok = "<code>"` on the step with the reason as a
   comment on that line (`level-grind` only with a ceiling, A.6.3). Anything that must be confirmed in game
   also gets a comment `-- CONFIRM: <what>`. A WARN on a step in a file you do not own is not yours to
   acknowledge: it shows up as a "foreign warning" (`--own`), goes into the hand-over and is resolved by the
   next single-owner phase.
8. **Filtered anchors.** Anchor race-neutral steps on unfiltered steps (the join steps `h13-uc-arrive`,
   `h15-org`, `h18-tb-zamah` / `h18-tb-1`). An insert on a race-filtered base step lands only in the routes of
   those races and must carry the same race scope (ERROR `insert-scope-wider-than-anchor` otherwise). A wrong
   or misspelled anchor, a scope that matches no route and a misspelled race token are ERRORs of the module
   checks (A.6.2), which also run in the filtered commands of the parallel phases.

### C.4 Mandatory and optional

| Kind | Step flag |
|---|---|
| Class letter at level 1 (zero detour) | mandatory |
| Training at a trainer of the class inside a city / hub the path is in | mandatory; merge two training levels into one visit when a stop is just short of a level; `optional = true` when the worst-case level at the stop is below the trained level |
| Key-ability chains (`classes.md` 5.10, column "ROUTE: key ability": warrior stances at 10 and 30, hunter pet at 10, rogue Poisons at 20-22, shaman Earth and Fire totems, warlock Imp / Voidwalker / Felsteed, druid Bear and Cat Form, paladin Redemption) | mandatory, with their own travel; the worst case must still pass (they are not `optional`, so they count in both runs) |
| Class XP with no or little detour (column "ROUTE: XP") | mandatory when the detour is under about 3 minutes, else `optional` |
| "Candidates" of 5.10, weapon skills, class gear vendors, riding and mounts, training detours to another city | `optional = true` |
| "Skip" column | not routed; one line in the file header says why |

The worst case (optional steps skipped) must validate with 0 errors (`optional-dependency`): a mandatory step
never needs a quest that only an optional step accepts, never flies to a flight point that only an optional
step learns, and never uses a hearthstone binding that only an optional step sets (A.6.3). An optional detour
therefore brings its own travel there **and back** as optional steps and leaves the hearthstone alone.

### C.5 Class data limits and the defaults for them

* Index-only quests (outside the snapshot: mage wand chain, shaman 79358-79442, rogue 96779-96786, warlock
  4785, 7601-7603): not routed, except where `classes.md` 5.10 lists them as key; then `ok = "quest-out-of-scope"`
  plus `-- CONFIRM`.
* Stale race masks (`quest-race` ERROR): Troll warlock 1501 / 1504 is a key ability: add an override in
  `tools/overrides/warlock.lua` (`races = { add = { "Troll" } }`, `verified = false`, source = the web
  page of `classes.md` section 7), route it, acknowledge `db-override-unverified`. Orc mage 1959 / 1960 / 1962
  and 1943-1946: not routed for the Orc. Skyborne druid 6126-6130 and 27-31: not routed (a note on the nearest
  training step, as today).
* Paladin trainers in Thunder Bluff and the Undercity: keep today's steps (the DB has both NPCs); every such
  step gets `-- CONFIRM`, and its note names Brill as the fallback.
* Unknown XP (every Forever-new class quest): nothing to do (`xp-unknown` is INFO); a known web value may go
  into the class's override file with its source. A class override file may only name quests that no step
  outside `Classes/<Class>.lua` uses (ERROR `override-foreign-quest`); a value for a quest of the shared path
  or of a start zone goes into the hand-over, and the next single-owner phase puts it into `shared.lua` and
  writes the baseline again. An XP override never changes the estimate of other quests (A.6.2).

### C.6 Race files

| File | Content | Anchors |
|---|---|---|
| `Races/Scourge.lua` | 6321 -> 6323 -> 6322; the Orgrimmar city quests 97246 -> 97249, 97242 -> 97275 (mandatory) and 97326 (`optional`), B.8; riding at Velma Warnam + mount at Zachariah Post, Brill, `class` = MAGE, PRIEST, ROGUE, WARRIOR (not WARLOCK, not PALADIN) | `h13-*` (Sepulcher, Undercity); `h15-org-fp`; `h-41-uc-arrive` |
| `Races/Skyborne.lua` | Thrall 95350 -> 98024, optional 1061 and their turn-ins; riding on Zephras Isle (Genn Fairweather), the whole trip `optional` | `h12-*`, `h15-xr-thork`, `h18-border`; level 40: C.7 |
| `Races/Orc.lua` | flight chain 6365-6386 (`optional`); riding at Kildar + mount at Ogunaro, inside Orgrimmar, `class` = all Orc classes but WARLOCK | `h15-sethearth-xroads`; `h-40-org-arrive` |
| `Races/Troll.lua` | flight chain 6365-6386 (`optional`); riding at Xar'Ti + mount at Zjolnir in Sen'jin (`optional` detour: Orgrimmar gate -> Sen'jin 2,280 yd on foot, then ride back to Doras, about 9 min), not WARLOCK | `h15-sethearth-xroads`; `h-40-org-arrive` (C.7) |
| `Races/Tauren.lua` | riding at Kar Stormsinger + mount at Harb Clawhoof, Bloodhoof (`optional` detour); the flight chain 6361-6364 (`optional`) after `h15-sethearth-xroads`, unless the Mulgore file already holds it at `mul03-xroads` (B.2; the P1 hand-over says which) | `h15-sethearth-xroads`; level 40: C.7 |

The Orc and Troll flight chain is the same quest list in two files with different step ids (`orc-`, `tro-`).
Riding steps are `optional` everywhere (100 gold may be missing); their notes say so.

### C.7 The level-40 contract (riding, druid training, Thunder Bluff)

At `h-40-org-arrive` (40.04) the path is in Orgrimmar and next flies to Camp Taurajo
(`h-38-orgrimmar-flight-master`). Order at the anchor: class steps, then race steps.

* Classes with an Orgrimmar trainer train at `h-40-org-arrive` in the city (class file).
* Orc riding: after `h-40-org-arrive`, inside the city. Troll: also after `h-40-org-arrive` (40.04, guaranteed
  by the gate `h39-level-mannoroc`): gate -> Sen'jin -> ride back to Doras, about 9 min, `optional`. One level
  later (`h41-hearth-org`) the detour would cost about the same (8 min), but the 42 steps between the two
  anchors are the whole Dustwallow part: 17,370 yd of straight legs, about 41 min on foot against 26 min
  mounted. Undead: after `h-41-uc-arrive` (Brill): Brill cannot be reached from the level-40 stop without a
  zeppelin round trip.
* **Druid** (`Classes/Druid.lua`, both races): exactly three steps with these ids, in two inserts (as executed,
  F2d): `dru-40-fly-tb` (fly Thunder Bluff) and `dru-40-train` (Turak Runetotem, Elder Rise) as one insert
  `after = "h-40-org-arrive"`; `dru-40-fly-taurajo` (fly Camp Taurajo; the next shared `fly` completes on the
  same landing) as an insert of its own `before = "h-38-orgrimmar-flight-master"` (the shared step right
  behind `h-40-org-arrive`). No other druid insert may stand `before = "h-38-orgrimmar-flight-master"` in front
  of it.
* **Tauren and Skyborne riding** (race files), two inserts each:
  * non-druids: `after = "h-40-org-arrive"`, `class` = the race's classes without DRUID: a self-contained
    `optional` detour `<r>-40-fly-tb`, the riding steps, `<r>-40-fly-taurajo`;
  * druids: `after = "h-40-org-arrive"`, `class = "DRUID"`: only the riding steps (ids `<r>-40d-...`,
    `optional`). At one anchor the class file comes before the race file (C.3 rule 6), so the composed druid
    route reads: `h-40-org-arrive`, `dru-40-fly-tb`, `dru-40-train`, `<r>-40d-...`, `dru-40-fly-taurajo`,
    `h-38-orgrimmar-flight-master`. The layout spec checks this order for every druid route that has such an
    insert, and that no race file is anchored on a step of a class file.
  * Why not `after = "dru-40-train"` (revision 2 of this plan): the base-profile commands (`--skip 'Classes/*'`
    without `--own`) then find the anchor in no loaded step and fail with ERROR `insert-anchor-unknown` (F2b
    hand-over, section 8). With the shared anchor the base profile shows the five optional riding steps right
    after `h-40-org-arrive`, without the druid's flights; that is an artefact of the run (the class file is
    always loaded in the game) and the validator reports nothing for it.
* Warlock (Felsteed, Ratchet) and paladin (Warhorse from the trainer) are class-file steps; the race riding
  inserts exclude these classes by their `class` list. The paladin file keeps its own optional riding steps in
  Brill (today's `pal-40-riding`, `pal-40-horse`) as the fallback when the trainer does not offer the Warhorse.

---------------------------------------------------------------------------------------------------------------

## D. Execution phases

Order:

**F1a -> F1b -> F1c -> F2a -> F2b -> F2c (Tirisfal and Zephras in parallel) -> F2d -> P1 (Durotar and Mulgore
in parallel) -> P2 -> [P3, optional] -> C (nine class agents in parallel) -> R.**

Each phase starts only when the previous one met its acceptance criteria. Single-owner phases are one agent
each. F1 and F2 are split because one agent cannot hold them (measured: `validator.lua` 2,619 lines,
`simulate_routes.lua` 1,593; the four start-zone segments have 314 steps of which 252 need new ids; the six
legacy segments that become `h-12` .. `h-18` have 503 steps; 196 `WARN-OK` comments; 1,874 lines of route
documents).

### D.0 Rules for every agent

1. **One checkout, one branch, one committer.** Agents never run `git stash`, `git checkout`, `git reset`,
   `git add`, `git commit` or `git push`; the only exception is `git mv` in F2a (a single agent, nothing else
   running). The orchestrator commits at every phase boundary. An agent that wants its own file back uses
   `git show HEAD:<path> > <path>`, for files it owns only. Touch only the files your phase owns; files owned
   by nobody in a parallel phase are read-only.
2. **Generated files** (`Data.lua`, `docs/VALIDATION.md`) are regenerated by single-owner phases only (F1c, F2a,
   F2b, F2d, P2, P3, R). Parallel agents never run `make routedata`, `make report` or `make check`. After each
   parallel phase (F2c, P1, C) the orchestrator runs the closing step `make routedata report` and
   `make routedata-check`, then commits. The commits at the end of F2c, P1 and C are checkpoints: plain
   `--strict` can still fail there on foreign warnings, so they are **not pushed**. Pushed states are the ends
   of F1c, F2a, F2b, F2d, P2, P3 and R, where `make check` and both CI freshness steps pass.
3. **Loadable state.** Save a Lua file only in a loadable state: run `luacheck --config .luacheckrc <file>`
   before any tool run, for module files and for the own override file. A load error in a module file breaks
   every other agent's run unless they skip that file; a broken override file is ignored and reported (A.6.2).
4. CPU: a parallel agent runs at most one simulation at a time (26 s, one core). Validation is free (0.3 s).
5. **Acceptance for routes, everywhere**: the validator with `--strict --end-level` reports 0 ERROR and exits 0
   (every WARN fixed or acknowledged with `ok` and a reason; end level 60.00 in the normal and the worst-case
   run are ERRORs otherwise); the simulator prints `OK` with no unexplained "would not be offered" warning.
   Parallel agents add `--own <their files>`: WARNs on other files do not fail their run but are listed in the
   hand-over. Numbers are read from `--summary`, never summed by hand.
6. **A defect outside your files** (a wrong chain in `Route.lua`, a shared step, a tool, the core, the layout
   spec) is reported to the orchestrator, who fixes it or assigns it; all other agents keep working. Never work
   around it in your own file and never edit the foreign file.
7. Every agent writes `docs/dev/handover/<phase>-<name>.md`: its `--summary` lines; the per-segment kill table
   of its base routes; the foreign warnings; ids it added; anchors it wishes for (phase C); XP values and mask
   corrections for quests it may not override; new place names that need a Russian fallback in
   `PLACE_NAMES_RU`; DB overrides it added; its `-- CONFIRM` list.
8. `G` below is `addons/FastesBoooy_Guides`. `$SCRATCH` is a directory outside the repository.
9. The layout spec reads three environment variables so that a parallel agent can run it on its own files:
   `GUIDES_SKIP` and `GUIDES_KEEP` (comma lists of globs, the logic of `--skip` / `--keep`) and `GUIDES_OWN`
   (globs; the per-file assertions run only for matching files, and the assertions about the whole module,
   such as the route count, are skipped). Without them it checks everything.

### D.1 Phase F1: core and tools (three agents, one after the other)

Inputs: `core.md` (all), `tools.md` (all), sections A.5, A.6, A.7 of this plan.

Owned (all three parts): `addons/FastesBoooy/**`, `tools/**` (not `tools/data/forever_db.lua`,
`forever_api.lua`), new `tools/overrides/` (a README only), `tests/**`, `.luacheckrc`, `Makefile`,
`.github/workflows/*`, `docs/ARCHITECTURE.md`, `docs/ROUTE_FORMAT.md`, `tools/README.md`, `docs/VALIDATION.md`
(regenerated).

Forbidden: `addons/FastesBoooy_Horde`, `addons/FastesBoooy_UndeadPaladin`, `addons/FastesBoooy_SkyborneDruid`
(they stay byte-identical: `git status --short addons/FastesBoooy_*` prints nothing; the one allowed exception
is a regenerated `Data.lua` if `make routedata-check` reports a difference caused by A.5.1 rule 9),
`docs/routes/**`, `docs/dev/**` except the hand-over file, `README.md`.

| Part | Work | Acceptance (besides `luacheck --config .luacheckrc addons tools tests` and `busted` green) |
|---|---|---|
| **F1a core** | A.5.1-A.5.6 with the specs of A.5.7; loader stub `AddLibraryInsert`, `mod.libraryInserts`, `opts.replace`; `.luacheckrc` field; fixture `FastesBoooy_TestGuides` | `make validate validate-fixtures simulate-fixtures harness-fixtures routedata-check` green. Old routes: 0 ERROR, end level 60.00, grind 4,972 / 6,179 and 4,878 / 6,082 (appendix 1), 1,713 and 1,748 composed steps, 95 and 145 WARN (the 4 `step-no-profile` per route are gone) |
| **F1b validator** | A.6.1 (filters, `--own`, lint rule for overrides, harness on mixed modules), A.6.2, A.6.3, with one spec per behaviour: each module check (among them a template step with `race = "Undead"`, an insert with a misspelled anchor under `--skip`, own and foreign), `ok` in three forms and `ok-needs-ceiling`, `--strict` with `--own`, `--end-level`, `--summary`, `--max-grind-until`, `--write-baseline` / `--baseline`, worst-case `fly` and `hearth`, trainer kinds, `--route` lists, `--levels`; overrides: `pcall` on a broken file, the median stays that of the snapshot, duplicate id, `override-foreign-quest`, `exclusive = { remove }` with a replay of 861 + 854 before the accept of 844 | old routes: 18 and 18 WARN (`xp-unknown` is INFO; as executed: the trainer-kind rule turns the nineteenth into INFO `train-service`); `lua5.1 tools/validate_routes.lua -q --strict --end-level tests/fixtures/core/FastesBoooy_TestGuides` exits 0; the pinned numbers of the existing validator specs are unchanged |
| **F1c report, simulator, build** | A.6.4, A.6.5, A.7 (with the F1 values of `SYNC_ROUTES` / `SYNC_MID`), `nightly.yml`; documentation: `docs/ROUTE_FORMAT.md` (shared inserts and rules 9-10, `ok`, aliases, class reward table, the guard line, version table), `docs/ARCHITECTURE.md`, `tools/README.md` (options, overrides, report layout) | `lua5.1 tools/simulate_routes.lua --list-routes` lists the two routes; `make simulate` runs them in parallel and fails when `--list-routes` fails; `make check` green, its wall time in the hand-over; report regenerated |

Every new behaviour of A.5 and A.6 has a spec. `core_sync_spec.lua:634-650` still loads the old modules (it
changes in F2a).

### D.2 Phase F2: create the module, migrate, unify 12-22 (four steps)

Inputs: `routes.md` (all), `core.md` 5.6-5.9, `tools.md` 5 and 11, sections A.1-A.4, B, C of this plan.
In all four steps: `addons/FastesBoooy/**`, `tools/**` (except the files named) and the other `tests/**` are
forbidden; a defect there goes to the orchestrator (D.0 rule 6).

#### F2a: mechanical migration, numbers identical (one agent)

Owned: `addons/FastesBoooy_Guides/**` (created), the three old module folders (deleted), `Makefile` (`SYNC_*`,
`LIB`, `VALIDATE_FLAGS`), `.github/workflows/ci.yml` if needed, `tests/spec/core_sync_spec.lua` (paths and
ids), `Data.lua`, `docs/VALIDATION.md`.

1. Create the module (TOC of A.2 with every planned file; placeholders for all files not written yet).
2. `git mv` the 12 files of `FastesBoooy_Horde/Segments` to `Segments/Shared/`; the 10 own segment files to
   `Segments/Tirisfal/`, `Segments/Zephras/` and, for `ud-03..05` / `sd-03..05`, a temporary
   `Segments/Legacy/` directory. Replace `AddSegment("<route>", {...})` by `AddLibrarySegment({...})`.
3. `Route.lua` in its final form (A.4: the complete five-race table, `only`, `aliases`), except that the chains
   of Scourge and Skyborne are the legacy ones (`ud-01` .. `ud-05`, `sd-01` .. `sd-05`, then `h-22` ..
   `h-56`). The announcements carry `only = { "PALADIN" }` and `only = { "DRUID" }`.
4. `Classes/Paladin.lua`, `Classes/Druid.lua`: today's `Inserts.lua` as shared inserts (`AddLibraryInsert`,
   class scope). Explicit ids stay; an insert step without an explicit id gets one with the class prefix.
5. Convert every `-- WARN-OK: <code>` comment into the key `ok` (the reason stays as the comment). The 151
   `xp-unknown` and the 8 `step-no-profile` comments are dropped (INFO now; pruned now). The 17 `level-grind`
   gates get a ceiling: the larger of the two routes' normal kills at that gate, rounded up to the next 10 (as
   executed: 13 of them; three gates need kills in the worst case only and the optional `h48-tanaris-level-gate`
   stays under the WARN threshold, so an `ok` there would be `ok-unused`).
   The paladin's acknowledgement of `segment-level` for `h-22-hillsbrad` moves onto that segment.
   Set `VALIDATE_FLAGS = --strict --end-level`.
6. Delete the three old folders. Update `Makefile` (`LIB`, `SYNC_ROUTES = undead-paladin skyborne-druid`,
   `SYNC_MID = 21/ud-04-barrens,sd-04-barrens 29/h-24-barrens-stonetalon`), `core_sync_spec.lua`, regenerate
   `Data.lua` and the report.

Acceptance F2a: `undead-paladin` and `skyborne-druid` validate with 0 ERROR and **exactly** the baseline
numbers (end level 60.00; grind 4,972 / 6,179 and 4,878 / 6,082; 1,713 and 1,748 steps); `make validate` passes
with `--strict --end-level`; both simulate `OK`; `make check` green; exactly two folders under `addons/`.

#### F2b: the shared path 12-22 (one agent)

Owned: `G/Segments/Shared/**`, `G/Segments/Legacy/**` (deleted at the end), `G/Segments/Zephras/03_ThunderBluff.lua`
(the first 9 steps of the old `sd-03`), `G/Route.lua` (chains), `G/Classes/Paladin.lua`, `G/Classes/Druid.lua`,
`G/Races/Scourge.lua`, `G/Races/Skyborne.lua`, `tools/overrides/shared.lua`, new
`tests/spec/guides_layout_spec.lua`, new `tests/fixtures/guides/**` (fixture start zones) and
`tests/fixtures/validator/guides_state_*.json`, `tests/spec/core_sync_spec.lua`, `Makefile` (`SYNC_MID`),
`tools/gen_route_data.lua` (`PLACE_NAMES_RU` only), `Data.lua`, `docs/VALIDATION.md`.
Not touched: `G/Segments/Tirisfal/*`, `G/Segments/Zephras/01_*`, `02_*` (they keep their class steps; `only`
keeps the other classes unregistered).

1. Write `h-12-orgrimmar-tirisfal`, `h-13-silverpine`, `h-15-barrens`, `h-18-stonetalon-ashenvale` (B.3-B.6)
   from the legacy segments: every step with an explicit id, the anchors of C.2, the gates of B.8, the
   alternative pairs with their join steps. Delete `Segments/Legacy/`. Apply B.7 to `h-22`, `h-24`, `h-50`.
2. Class steps of 12-22 move out of the segments into the class files as inserts on the new anchors (paladin
   training in the Undercity and Thunder Bluff; druid: Moonglade before hearth steps, Thunder Bluff quests,
   Cat Form chain, `dru-40-fly-tb` / `dru-40-train` / `dru-40-fly-taurajo` of C.7). **Race scope of the druid
   file:** every insert carries `race = "Skyborne"` unless the Tauren druid harness run of step 6 passes with
   that insert unscoped. Skyborne-only quests (94006 / 94638, 94911 / 94913, 98341 / 98404 / 98738) are always
   scoped.
3. `Races/Scourge.lua`, `Races/Skyborne.lua`: the steps of 12-60 (C.6, C.7; the Undead city quests of B.8),
   but only those that apply to a route that exists now (`undead-paladin`, `skyborne-druid`). The riding
   inserts of the other classes would be composed into no route and fail `shared-step-unused`; the F2c agent
   of the race writes them after it has removed `only`.
4. `Route.lua`: the final chains of A.4. `tools/overrides/shared.lua`: 861 and 854 (B.2).
5. `tests/spec/guides_layout_spec.lua`, first version (loads the real module through
   `tools/lib/route_loader.lua`; about 1 s; environment variables of D.0 rule 9):
   * no load error; the registered routes are exactly the combos of the announced zones, restricted by `only`;
   * with the fixture start zones for Durotar and Mulgore: 28 routes with the ids, titles, `races`, `classes`
     and chains of A.4;
   * no step of `h-12` .. `h-18` and of `h-22-hillsbrad` has a positional id;
   * every shared anchor of C.2 exists, and the steps marked (F) are filtered and all others are not;
   * every shared insert from `Classes/<Class>.lua` is scoped to exactly that class and its step ids have the
     class prefix; the same for `Races/<Race>.lua` with race scope and race prefix; an insert registered from
     a start-zone file is scoped to races of that zone and its step ids have the zone prefix;
   * no shared base step carries `reward`.
6. **Proof for the new races before they exist.** Synthetic start states with the real hand-over history of
   B.2 (`done`, `log`, flight points, hearth), run through the harness from `h-12` to `h-56`:
   * `guides_state_orc_11.json`: level 11.2; `done` = the quests of `startzones.md` 5.1 steps 1-9 with 812,
     813 and 831; `log` = 837, 806, 99051; hearth Razor Hill; no flight points. Profiles Orc WARRIOR and Troll
     PRIEST.
   * `guides_state_tauren_11.json` (walk variant): level 11.8; `done` = the quests of `startzones.md` 5.2 with
     861, 860, 854, 886; hearth Bloodhoof Village; flight points Thunder Bluff, Camp Taurajo, The Crossroads.
     Profiles Tauren WARRIOR (`--skip 'Classes/*'`) and Tauren DRUID (class files loaded).
   * `guides_state_tauren_11_fly.json` (flight variant, E.1): the same `done`, flight point Thunder Bluff only.
   Each run with `--strict --end-level --max-grind-until h-18-stonetalon-ashenvale=120/200`.
7. `SYNC_MID = 21/h-15-barrens 29/h-24-barrens-stonetalon`; regenerate `Data.lua` and the report.

Acceptance F2b: `undead-paladin` and `skyborne-druid`: 0 ERROR, `--strict --end-level`, total grind within
`--max-grind-until h-56-felwood-winterspring-plaguelands=4972/6179` and `=4878/6082`; both simulate `OK`; the
five harness proofs of step 6 pass (if the 120 / 200 budget fails after the cost rule of B.8 was applied: stop
and report the numbers; the orchestrator decides before P1 starts); the layout spec passes; `make check` green.

#### F2c: class-neutral start zones (two agents in parallel)

| | Tirisfal agent | Zephras agent |
|---|---|---|
| Owns | `G/Segments/Tirisfal/*`, `G/Classes/Paladin.lua`, `G/Races/Scourge.lua`, `tools/overrides/tirisfal.lua`, `paladin.lua`, `docs/dev/handover/f2c-tirisfal.md` | `G/Segments/Zephras/*`, `G/Classes/Druid.lua`, `G/Races/Skyborne.lua`, `tools/overrides/zephras.lua`, `druid.lua`, `docs/dev/handover/f2c-zephras.md` |
| Routes | `undead-*` (6) | `skyborne-*` (5) |
| `<F>` | `--skip 'Segments/Zephras/*' --skip 'Classes/Druid.lua' --skip 'Races/Skyborne.lua' --own 'Segments/Tirisfal/*' --own 'Classes/Paladin.lua' --own 'Races/Scourge.lua'` | the mirror image |
| Simulations | `undead-paladin`, `undead-warrior` | `skyborne-druid`, `skyborne-shaman` |
| Total grind limit | `undead-paladin` 4,972 / 6,179 | `skyborne-druid` 4,878 / 6,082 |

Forbidden for both: everything else (TOC, `Route.lua`, `Segments/Shared/**`, the layout spec, `Data.lua`, ...).

Work: rewrite the start zone class-neutral following `routes.md` sections 3 and 10: split the mixed steps, move
every class step into the class file (groups `tir` / `zep`, new ids), make gates class-neutral (`ud02-lvl-12`),
reword class-flavoured notes, (Zephras) move the 13 `reward` fields into the druid's class reward table, give
**every** step an explicit id, create the anchors of C.2. `ud-02` ends with `ud02-silverpine-road`. When the
zone is class-neutral, remove `only` from the announcement: the other classes of the race appear as base
routes.

```
luacheck --config .luacheckrc $G/Segments/Tirisfal $G/Classes/Paladin.lua $G/Races/Scourge.lua
lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --route 'undead-*' <F> $G
lua5.1 tools/validate_routes.lua -q --strict --end-level --route undead-paladin \
    --max-grind-until h-56-felwood-winterspring-plaguelands=4972/6179 <F> $G
lua5.1 tools/validate_routes.lua --route undead-warrior --levels <F> $G
lua5.1 tools/simulate_routes.lua --route undead-paladin <the --skip part of F> $G      # then undead-warrior
GUIDES_SKIP='Segments/Zephras/*,Classes/Druid.lua,Races/Skyborne.lua' \
GUIDES_OWN='Segments/Tirisfal/*,Classes/Paladin.lua,Races/Scourge.lua' busted tests/spec/guides_layout_spec.lua
```

Acceptance F2c (per agent): all routes of the race: 0 ERROR, the commands above exit 0; the hand-over contract
of B.2 for the base profile (the non-paladin / non-druid routes are base routes: their class files are
placeholders); the two simulations `OK`; hand-over with the real anchor list and the level at every anchor
(`--levels`).

#### F2d: finish the migration (one agent)

Owned: all of `G/**`, `tests/spec/guides_layout_spec.lua`, `Makefile`, `tools/gen_route_data.lua`
(`PLACE_NAMES_RU`), `tools/overrides/shared.lua`, `README.md`, `docs/routes/**`, `Data.lua`,
`docs/VALIDATION.md`.

1. Resolve the foreign warnings of the two F2c hand-overs (fix or `ok`); `make validate` is plain
   `--strict --end-level` again.
2. Layout spec: add the Tirisfal and Zephras anchor tables from the hand-overs; no step of `ud-*`, `sd-*` has a
   positional id; no announcement carries `only`; and the **faction-word check** of 0.1: no "Horde" / "Орда" in
   the TOC, in route titles and descriptions and in segment titles; in step notes only on the step ids of an
   allow-list table in the spec (in-world uses; today: the Horde camp of `h-44`, Whitereach Post of `h-46`, the
   supply crates and the Fallen Hero of `h-50`, the Horde camp of `h-53`). The two notes that describe the
   guide are reworded here if F2b / F2c did not do it: the last step of the old `ud-05` ("общий маршрут Орды")
   and the Skysight step of `sd-01` ("Расовое задание Орды").
3. Docs: `README.md` (two folders, the list of guides, "Updating from 0.3"), `docs/routes/shared-path.md` (from
   `horde-22-60.md`, extended by 12-22), `docs/routes/race-undead.md`, `race-skyborne.md`, `class-paladin.md`,
   `class-druid.md` (from the two old route documents, which are deleted).
4. `VALIDATE_FLAGS` gets `--max-grind-until h-18-stonetalon-ashenvale=120/200`. Regenerate `Data.lua` and
   `docs/VALIDATION.md`.

Validation:

```
luacheck --config .luacheckrc addons/FastesBoooy_Guides
busted tests/spec/guides_layout_spec.lua tests/spec/core_sync_spec.lua
lua5.1 tools/validate_routes.lua -q --strict --end-level --summary \
    --max-grind-until h-18-stonetalon-ashenvale=120/200 $G                         # 11 routes
lua5.1 tools/validate_routes.lua -q --strict --end-level --route 'undead-*,skyborne-*' --skip 'Classes/*' $G
lua5.1 tools/simulate_routes.lua --route 'undead-paladin,skyborne-druid,undead-warrior,skyborne-shaman' $G
make check                                                                       # once, at the end
```

Acceptance F2d: 11 routes: all commands exit 0; `undead-paladin` total grind <= 4,972 (worst <= 6,179),
`skyborne-druid` <= 4,878 (worst <= 6,082), read from `--summary`; if a limit cannot be met after the cost rule
of B.8, stop and report the numbers, do not relax the limit; the harness proofs of F2b still pass; the four
simulations `OK`; `make check` green.

#### F2e: orchestrator fixes (one agent; added during execution)

Not in revision 2. Resolves what the F1a .. F2d hand-overs passed to the orchestrator before P1 starts: the
level-sync run `--ahead 48` of every base route (a finished route must stay finished on a cold start: core
`Engine:ComputeVoid`, the "protected" rule of gray quests), the engine scenario of 98389 as a spec
(`tests/spec/guides_engine_spec.lua`), the module checks the core still lacked (an empty scope list of a shared
insert, the shape of the class reward table), the faction-word matchers of the layout spec, unused fixtures,
stale documentation (`docs/ARCHITECTURE.md`, `docs/ROUTE_FORMAT.md`, `tools/README.md`, tool usage texts,
`docs/routes/*.md`, `README.md`) and this plan (C.2, C.3, C.7, D.4, D.5, D.6 and the "as executed" notes).
Hand-over: `docs/dev/handover/F2e-orchestrator-fixes.md`. Acceptance: luacheck, busted, `make check`,
`make routedata-check`, a fresh report and `make simulate-sync-full` for all 11 routes.

### D.3 Phase P1: Durotar and Mulgore (two agents in parallel)

Inputs: `startzones.md` (all), sections B.1, B.2, B.8, C.2, C.3 of this plan, `docs/ROUTE_FORMAT.md`.

| | Durotar agent | Mulgore agent |
|---|---|---|
| Owns | `G/Segments/Durotar/*.lua`, `tools/overrides/durotar.lua`, `docs/dev/handover/p1-durotar.md` | `G/Segments/Mulgore/*.lua`, `tools/overrides/mulgore.lua`, `docs/dev/handover/p1-mulgore.md` |
| Routes | `orc-*`, `troll-*` (13) | `tauren-*` (4) |
| `<F>` | `--skip 'Segments/Mulgore/*' --skip 'Classes/*' --own 'Segments/Durotar/*'` | `--skip 'Segments/Durotar/*' --skip 'Classes/*' --own 'Segments/Mulgore/*'` |
| Harness profiles | Orc WARRIOR, Troll PRIEST, Orc WARLOCK (the 792 branch) | Tauren WARRIOR |
| Simulations | `orc-warrior`, `troll-priest`, `orc-warlock` | `tauren-warrior`, `tauren-hunter` |

Forbidden for both: the TOC, `Route.lua`, `Segments/Shared/**`, the other zones, `Classes/**`, `Races/**`,
`Data.lua`, `docs/VALIDATION.md`, `Makefile`, `tools/**` except the own override file, the core, the tests.
The rows of `Route.lua` for the three races were proven in F2b with fixture zones; if one is wrong all the
same, D.0 rule 6 applies.

Work: write the segments (B.2), every step with an explicit id, the hard-contract anchors and one anchor per
hub visit (C.2), class-neutral notes and gates (B.8), the class branch of 792 (Durotar). Announce the zone
(`ns.startZones`, A.4) as soon as the segments load. Durotar: the three city inserts on `h-12` anchors and the
postponed turn-ins, as race-scoped inserts in the own file (B.2). A wish for a change in a shared segment (an
anchor in another place, a gate) goes into the hand-over for P2.

Validation (Durotar shown; Mulgore analogous):

```
luacheck --config .luacheckrc $G/Segments/Durotar
# the zone alone, from a fresh character; writes the hand-over state
lua5.1 tools/validate_routes.lua --harness $G --segments dur-01-valley-of-trials,dur-02-durotar \
    --profile race=Orc,class=WARRIOR,faction=Horde <F> --write-state $SCRATCH/orc.json
lua5.1 tools/simulate_routes.lua --harness $G --segments dur-01-valley-of-trials,dur-02-durotar \
    --profile race=Orc,class=WARRIOR,faction=Horde <the --skip part of F>
# the full base routes
lua5.1 tools/validate_routes.lua -q --strict --end-level --summary \
    --grind-until h-18-stonetalon-ashenvale --route 'orc-*,troll-*' <F> $G
lua5.1 tools/validate_routes.lua --route orc-warrior --levels <F> $G
lua5.1 tools/simulate_routes.lua --route orc-warrior <the --skip part of F> $G   # then troll-priest, orc-warlock
GUIDES_SKIP='Segments/Mulgore/*,Classes/*' GUIDES_OWN='Segments/Durotar/*' busted tests/spec/guides_layout_spec.lua
```

Acceptance: all routes of the zone: the validation commands exit 0 (0 ERROR, own-file strict, end level 60.00
normal and worst); the hand-over contract of B.2 (state, level, the `h13-lvl-12` row); three (Mulgore: two)
simulations `OK`; the layout spec passes with the variables above; hand-over file with the real anchor list
and the level at every anchor (`--levels`), the `--summary` lines (they contain the grind up to the end of
`h-18`: a number to report, not a criterion of this phase) and the foreign warnings.

### D.4 Phase P2: merge and tuning (one agent)

Inputs: the two P1 hand-overs, sections B and C.6-C.7, `classes.md` 4.2, 6.2 and 8.1.

Owned: all of `G/Segments/**` (ownership of the start zones passes to P2), `G/Races/*.lua`, `G/Route.lua`,
`Makefile` (`SYNC_*`, `VALIDATE_FLAGS`), `tools/gen_route_data.lua` (`PLACE_NAMES_RU`),
`tools/overrides/shared.lua` and the race override files, `tests/spec/guides_layout_spec.lua`, `Data.lua`,
`docs/VALIDATION.md`, `docs/routes/race-orc.md`, `race-troll.md`, `race-tauren.md`,
`docs/dev/handover/p2.md`, `levels-<race>.tsv`, `baseline.json`. In `G/Classes/Druid.lua` and
`G/Classes/Paladin.lua` P2 may add or change **only `race = ...` scope lines** (to keep a step that is wrong
for a Tauren out of the Tauren routes); every such line is listed in the hand-over for the druid agent.
Forbidden: the rest of `G/Classes/**`, the core, the rest of the tools and tests.

Work:

1. Validate all 28 routes (`--summary`); table "entry level per segment and race" and "grind kills per gate and
   race" (the report has both).
2. Resolve the foreign warnings and the wishes of the P1 hand-overs. Tune the shared 12-22 segments by B.8:
   the cost rule, the trainer-hub gates with the measured levels (B.9), the race filters on duplicate `fp`
   steps by the variant in force (B.5, E.1, E.2), quest-log size, the timed 853 for races that walk to Thunder
   Bluff.
3. `Races/Orc.lua`, `Races/Troll.lua`, `Races/Tauren.lua` (C.6, C.7); review `Races/Scourge.lua` and
   `Races/Skyborne.lua`. The Tauren druid riding insert is `after = "h-40-org-arrive"`, `class = "DRUID"`, ids
   `tau-40d-...`, all `optional` (C.7 as executed; with `after = "dru-40-train"` the layout spec and the
   base-profile command fail). `h15-xr-arrive` gets `ok = "db-override-unverified"` with the first Tauren route
   (the layout spec demands it).
4. Ceilings: every `ok = { ["level-grind"] = N }` of a shared gate is set to the largest normal-run kill count
   over the 28 base routes, rounded up to the next 10.
5. **Hub ids in `h-24` .. `h-56`.** Give an explicit id (`hNN-<place>-<what>`, `NN` = level of the step) to
   every step that is an arrival, a hearth, a `fly`, an `fp`, a `sethearth` or a turn-in inside a city or hub
   with a trainer, for the 37 stops of `classes.md` 4.2 and the list of 8.1, where the step has none yet. Only
   the field `id` is added. This is the single place where these files get new ids before phase R.
6. `Makefile`: `SYNC_ROUTES` of A.7. `PLACE_NAMES_RU` for the places the hand-overs list. Layout spec: 28
   routes expected, the Durotar and Mulgore anchor tables from the hand-overs, no positional id in `dur-*`,
   `mul-*`. Regenerate `Data.lua` and `docs/VALIDATION.md`.
7. **Freeze** (skipped here if P3 runs; P3 then does it): write `docs/dev/handover/levels-<race>.tsv`
   (`--levels` of one base route per race) and `docs/dev/handover/baseline.json`
   (`--skip 'Classes/*' --grind-until h-18-stonetalon-ashenvale --write-baseline ...`); add
   `--baseline docs/dev/handover/baseline.json` to `VALIDATE_FLAGS`. From here on no step of `G/Segments/**`
   is added, removed, moved or renamed, and no gate changes.

Validation:

```
lua5.1 tools/validate_routes.lua -q --strict --end-level --summary \
    --max-grind-until h-18-stonetalon-ashenvale=120/200 --skip 'Classes/*' $G     # the 28 base routes
lua5.1 tools/validate_routes.lua -q $(VALIDATE_FLAGS) --summary $G                # the 28 routes as shipped
make check
```

Acceptance: the 28 base routes: 0 ERROR, strict, end level 60.00 normal and worst, grind up to the end of
`h-18` <= 120 (worst <= 200) for every race. The 28 routes with the class files as they are (only paladin and
druid have content): 0 ERROR and strict; a problem that `Classes/Druid.lua` causes on a Tauren is solved by a
`race = "Skyborne"` scope line, not by waiting for phase C. `undead-paladin` and `skyborne-druid` still within
the limits of F2d. `make check` green (28 simulations, 5 x 8 sync runs); its wall time reported.

### D.4a Phase P3 (optional): grind review of 22-60 (one agent)

Runs only if the user wants it (R9, E.19). It is placed before the freeze because it changes levels at the
anchors the class agents read.

Owned: `G/Segments/Shared/22_*` .. `56_*`, `tools/overrides/shared.lua`, `tools/gen_route_data.lua`
(`PLACE_NAMES_RU`), `Data.lua`, `docs/VALIDATION.md`, `docs/routes/shared-path.md`, the freeze files of P2
step 7, `docs/dev/handover/p3.md`.

Rules: no step with an explicit id is removed or renamed (the paladin, druid and race files anchor on them);
all 28 routes stay at 0 ERROR and strict after every change.

Method, gate by gate, largest first (baseline, normal run: `h-56` 1,304 kills, `h-37` 1,009, `h-41` 764, `h-46`
617, `h-53` 362, `h-31` 274): scan the DB for Horde quests of the zones the path visits before the gate that
the route does not do and whose `reqLevel` is met; drop those `docs/routes/horde-22-60.md` already rejected
unless its reason is gone; apply the cost rule of B.8 at the level of the gate (2.0 min per 1,000 XP at 40,
1.5 min at 57); add what passes, as mandatory steps or, for elites and dungeons, as `optional` blocks; lower
the gate by the XP that now arrives by quests.

Target: total grind of every base profile below the P2 value, goal 10 % lower (about 4,440 kills in the normal
run). Hard limits: no base profile above its P2 value in the normal or the worst-case run; end level 60.00.
Stop rule: when no remaining candidate passes the cost rule; the hand-over then lists the rejected candidates
with their cost. The phase ends with the freeze of P2 step 7 and `make check`.

### D.5 Phase C: classes (nine agents in parallel)

Inputs: `classes.md` (0, 1, 3, 4, the own class in 5, 6, 7, 8, appendix A for the class), `startzones.md` 2 and
3 (trainers and class quests 1-12 for Orc, Troll, Tauren), `routes.md` 3 and 7 (what the paladin and druid
files do), sections B.9 and C of this plan, the `levels-<race>.tsv` files and the anchor lists of the
hand-overs.

| Agent | Owns | Routes |
|---|---|---|
| Warrior | `Classes/Warrior.lua`, `tools/overrides/warrior.lua` | `orc-`, `troll-`, `tauren-`, `undead-`, `skyborne-warrior` |
| Hunter | `Classes/Hunter.lua`, `overrides/hunter.lua` | `orc-`, `troll-`, `tauren-`, `skyborne-hunter` |
| Rogue | `Classes/Rogue.lua`, `overrides/rogue.lua` | `orc-`, `troll-`, `undead-`, `skyborne-rogue` |
| Shaman | `Classes/Shaman.lua`, `overrides/shaman.lua` | `orc-`, `troll-`, `tauren-`, `skyborne-shaman` |
| Warlock | `Classes/Warlock.lua`, `overrides/warlock.lua` | `orc-`, `troll-`, `undead-warlock` |
| Mage | `Classes/Mage.lua`, `overrides/mage.lua` | `orc-`, `troll-`, `undead-mage` |
| Priest | `Classes/Priest.lua`, `overrides/priest.lua` | `troll-`, `undead-priest` |
| Druid | `Classes/Druid.lua` (exists: add the Tauren groups, review the race scopes P2 set; keep the two level-40 inserts of C.7 apart), `overrides/druid.lua` | `tauren-`, `skyborne-druid` |
| Paladin | `Classes/Paladin.lua` (exists: review against C, the trainer question E.3), `overrides/paladin.lua` | `undead-paladin` |

Each agent also owns `docs/dev/handover/c-<class>.md` and `docs/routes/class-<class>.md`. Forbidden:
everything else, **without exception: no class agent edits a segment file**.

**Rule for a missing anchor.** Every step of the start zones, of `h-12` .. `h-18` and of `h-22-hillsbrad` has
an explicit id, and P2 gave ids to the hub steps of `h-24` .. `h-56`. If a class step still needs a step
without an id, anchor on the nearest step with an explicit id (`after` an earlier one or `before` a later one)
so that C.3 rules 1-3 still hold, and write the wish into the hand-over ("`h-31-hillsbrad-arathi` step 57
should be an anchor: reason"). Phase R adds the id and moves the insert. (Nine agents adding ids to the same
twelve files would collide: a duplicate step id in a shared segment is a load error that nobody can skip.)

Work per class: the level-1 letters (one per race), training visits at the anchors of C.2 (levels from the
`levels-<race>.tsv` files and `--levels`), the chains of `classes.md` 5.10 by the rules of C.4, the class
reward table, the file header (per zone: visit, anchor, validator level; what is skipped and why).

Validation (`C=Warrior`, `c=warrior`):

```
luacheck --config .luacheckrc $G/Classes/$C.lua tools/overrides/$c.lua
# <F> below stands for:  --skip 'Classes/*' --keep "Classes/$C.lua" --own "Classes/$C.lua"   (type the quotes)
lua5.1 tools/validate_routes.lua -q --strict --end-level --summary \
    --baseline docs/dev/handover/baseline.json --route "*-$c" <F> $G
lua5.1 tools/validate_routes.lua --route "orc-$c" --levels <F> $G
lua5.1 tools/simulate_routes.lua --route "orc-$c" --skip 'Classes/*' --keep "Classes/$C.lua" $G   # every race, one at a time
GUIDES_SKIP='Classes/*' GUIDES_KEEP="Classes/$C.lua" GUIDES_OWN="Classes/$C.lua" \
    busted tests/spec/guides_layout_spec.lua
```

The first command is the whole numeric gate: 0 ERROR (among them the module checks: a misspelled anchor, an
anchor of the wrong zone, a scope or race token that matches no route are ERRORs here, not silently dropped
steps), strict for the own file, end level 60.00 normal and worst, and total grind not above the base profile
of the race (`grind-baseline`). `--levels` shows for every own step the anchor it landed on.

Acceptance per class: the commands above exit 0 for every route of the class; every route of the class
simulates `OK`; hand-over file complete.

### D.6 Phase R: integration (one agent)

Owned: everything.

1. `luacheck`, the layout spec without variables (now also: no class or race file is a placeholder), `lua5.1
   tools/validate_routes.lua -q $(VALIDATE_FLAGS) --summary $G` for all 28 routes with all class files.
2. Resolve what the hand-overs list: foreign warnings on shared steps (fix or `ok`; `segment-level` and
   `level-grind` ceilings that a class moved), anchor wishes (add the id, move the insert), `ok-unused`,
   `shared-unused`, the module checks across files (no race file is anchored on a class step any more: C.7 as
   executed; the layout spec forbids it).
3. XP values and mask corrections for shared quests from the hand-overs go into `tools/overrides/shared.lua`;
   then write `baseline.json` again from the base routes and check all 28 routes against it.
4. `PLACE_NAMES_RU` from the hand-overs; `make routedata`; `make report`.
5. Docs: `README.md` (table of the 28 guides, install, update note), `docs/routes/`: `shared-path.md`, one
   `race-<race>.md` per race (the Durotar path is described in `race-orc.md`; `race-troll.md` lists the
   differences), one `class-<class>.md` per class; the generated "confirm in game" list from the `-- CONFIRM`
   comments goes into `docs/routes/confirm-in-game.md`. `docs/ARCHITECTURE.md`, `docs/ROUTE_FORMAT.md`,
   `tools/README.md`: final pass (module layout, conventions of section C).
6. `make check`, `make routedata-check`, `make package` (exactly two zips), `make simulate-sync-full` once.

Acceptance: 28 routes with class steps: `$(VALIDATE_FLAGS)` exits 0 (0 ERROR, plain strict, end level 60.00
normal and worst, the `h-18` budget, the baseline), 28 simulations `OK`; `make check` green in about 10 minutes
on 4 CPUs; the full sync matrix green; the faction-word check of the layout spec passes; `docs/VALIDATION.md`
and `Data.lua` fresh; two addon folders.

---------------------------------------------------------------------------------------------------------------

## E. Open questions and risks, with the default taken

| # | Question / risk | Default in this plan | Confirm in game |
|---|---|---|---|
| E.1 | Can a Tauren fly Thunder Bluff -> Orgrimmar at 12 without the Orgrimmar flight point? | No: the Tauren walk (`mul-03`, walk variant). The flight variant is specified below the table; P2 switches to it only on an in-game confirmation. | yes |
| E.2 | The Skyborne flight Thunder Bluff -> Orgrimmar at 13 (`sd03-fly-org`) assumes the point is known from the start. Evidence: the RestedXP Skyborne guide flies there (comment at today's `sd03-fly-org`); Skyborne start flight points are not in the DB. There is no such evidence for the Tauren, which is why E.1 and E.2 have different defaults. | Kept as today (`ok = "fly-unknown-fp"`, the note names the walk as fallback). If false, the fall-back is specified below the table. | yes |
| E.3 | Paladin trainers in Thunder Bluff and the Undercity (DB yes, web no). | Keep today's steps, notes name Brill as fallback, `-- CONFIRM`. | yes |
| E.4 | Troll warlock Voidwalker quests 1501 / 1504 (Orc-only in the DB). | Routed for the Troll through an unverified DB override (C.5). | yes |
| E.5 | Orc mage 1959-1962, 1943-1946; Skyborne druid Cure Poison / Aquatic Form. | Not routed for these combos. | optional |
| E.6 | 98389 "A Light in the Darkness" (no class mask, but given by the paladin trainer in Deathknell). | Stays a generic step of `ud-01`, `optional = true`, `-- CONFIRM`. Its three steps (`ud01-aramis`, `ud01-cocoons`, `ud01-98389`) are optional and carry no action of another quest (layout spec); `tests/spec/guides_engine_spec.lua` plays `ud-01` in the real engine for a character the quest is not offered to (shown once, never again, also after `/reload` and a cold start) and with the quest taken (F2e). | yes |
| E.7 | Every Forever-new quest has estimated XP (a third of the start-zone quest XP; the one web value is 25 % below its estimate). | Estimates are used; every `reqLevel`-critical accept has a gate and every trainer hub that the base profile reaches within 0.4 level of an even level has a trainer-hub gate (B.8), so a lower real XP costs kills, not a broken route or a missed training. Real values go into the override files as they are recorded (`/fb xp`); an XP override never moves the estimate of other quests. | record XP |
| E.8 | Index-only class quests (snapshot scoped to paladin and druid; `make db` inputs are not in the repository). | Not routed unless key (C.5); no snapshot rebuild in this project. | - |
| E.9 | Is the first mount included in the 100 gold; riding prices. | Riding and mount steps are `optional`, notes give both readings. | yes |
| E.10 | The Mulgore chain 76156 / 76160 / 76240 ("Rogue Trainer?" Boarton Shadetotem) looks unreleased. | Not routed; 205729 is never used as a trainer. | - |
| E.11 | One load error in any file fails every route. | `--skip` / `--keep` / `--own`, rule D.0.3, start-zone announcement (A.4), no segment edits in the parallel class phase (D.5), override files loaded under `pcall` (A.6.2). | - |
| E.12 | Step ids of 1-22 change, and so do the positional ids of `h-22-hillsbrad` and of the hub steps of 22-60 that get an id; saved marks of existing characters on those steps are lost. | Accepted (the engine rebuilds from the quest log; a lost mark is a dead entry, never a mark on another step, A.8); route ids migrate through `aliases`. | - |
| E.13 | CI runner slower than the 4-CPU measurement. | `JOBS = nproc`, 25-minute timeout, two levers in A.7. | - |
| E.14 | Memory about 10 MB. | Accepted; levers in `core.md` section 6 if ever needed. | - |
| E.15 | The simulator cannot check trainers, pets, transport or travel time; the validator has no travel model. | "Least travel" is judged by the author from DB distances (`startzones.md` 5) with the cost rule of B.8 (30 s per same-level kill, 420 yd per minute); grind kills and levels by the validator. Detours over about 3 minutes are `optional` unless they give a key ability. | - |
| E.16 | F2b / F2d might not reach the baseline grind numbers with the class-neutral order of 18-22 and the trainer-hub gates. | Cost rule of B.8, then stop and report (D.2). The order of `h-18` may be changed in F2b as long as the anchors of C.2 and the end state of B.6 hold; a trainer-hub gate that costs more than it gives is lowered or removed by the rule of B.8. | - |
| E.17 | The Tauren walk twice between the Crossroads and Orgrimmar (north at 12, south at 14 with 840 / 842). | Kept: one identical path for all races from `h-12` on. P2 may let the Tauren fly Orgrimmar -> Crossroads at `h15-org` (race-filtered alternative, losing 840 / 842) if the numbers stay within B.8. | - |
| E.18 | Start-camp trainers teach only to level 6 (web). | C.3 rule 5. | yes |
| E.19 | **Scope: is reducing the grind of 22-60 part of this project?** 98 % of the grind kills of every route are there (4,897 of 4,972), and the user's first criterion is the fastest leveling. | Default: no. The 22-60 path was compacted in November 2026 and is kept, guarded by ceilings and the baseline budget; phase P3 (D.4a) is fully specified and runs between P2 and C if the user says so. It costs one more agent phase and delays the class phase; its yield is uncertain (goal 10 %). | **ask the user** |
| E.20 | 812 "Need for a Cure" is timed; the DB has no timer length. The city loop of `h-12` (flight point, inn, city quests, Kor'ghan, Nazgrel, class training) runs between its accept and its turn-in. | Integrated loop (B.2), saving about 2.5 min for 13 routes; the notes name the timer and the early turn-in as the way out. If the timer proves shorter than the loop, the Durotar file moves `dur02-rhinag` right after `dur02-korghan` (one own-file edit). | yes |
| E.21 | The DB marks 844 as exclusive with the Tauren breadcrumbs 861 and 854; this plan treats that as one-way (breadcrumbs) and removes it by an unverified override. | Override in `tools/overrides/shared.lua`, WARN `db-override-unverified` acknowledged on `h15-xr-arrive` with `-- CONFIRM` (B.2). If 844 really is refused after 854, the Tauren skip 854 (230 XP). | yes |
| E.22 | Base-profile levels at trainer stops rest on estimates and on two scratch runs that differ by 0.1 level (11.90 vs 11.99 at the level-12 gate of Tirisfal). | The plan no longer relies on such margins: trainer-hub gates guarantee the even level (B.8, B.9); P2 re-measures every hub for all five races. | - |

**E.1, flight variant for the Tauren (what changes if the flight works).** It is not "one `fly` step and
nothing else":

1. `mul-03` becomes `mul03-fly-org` (fly Thunder Bluff -> Orgrimmar) plus `mul03-org-gate`; `mul03-taurajo`,
   `mul03-xroads`, `mul03-far-watch` disappear. The Tauren then know neither Camp Taurajo nor The Crossroads.
2. The race filters of `h15-fp-xroads` and `h15-fp-taurajo` no longer exclude the Tauren (B.5).
3. 854, 860 and 886 are still accepted in Mulgore and Thunder Bluff and are turned in by a Tauren-scoped insert
   of the Mulgore file `before = "h15-xr-arrive"` (step `mul03-xr-turnins`; it must stand before the accept of
   844 and 870, whose breadcrumbs they are). They arrive about 400 XP later; `h13-lvl-12` must still hold.
4. The Tauren flight chain 6361-6364 exists only with a Crossroads visit: it is anchored on
   `h15-sethearth-xroads` in `Races/Tauren.lua` (C.6), never on `mul03-xroads`.
5. Class files: the anchors `mul03-taurajo` and `mul03-far-watch` are gone; druid 6002 (Lunaclaw) moves to
   `h15-fp-taurajo`, the Far Watch Post chains to `h15-far-watch` as for Orc and Troll (C.2).
6. `guides_state_tauren_11_fly.json` is the proof state (D.2, F2b step 6); the walk state stays the default.

P2 makes the switch (it owns all of these files); after the freeze the variant is fixed.

**E.2, fall-back for the Skyborne (if the flight does not work).** `sd-03` gets the walk of `mul-03` as its own
steps (`sd03-taurajo` with `fp`, `sd03-xroads` with `fp`, Far Watch Post, Razor Hill, the Orgrimmar gate), and
the filters of `h15-fp-xroads` and `h15-fp-taurajo` then exclude the Skyborne as well (B.5).

---------------------------------------------------------------------------------------------------------------

## Appendix 1. Baseline (measured on this branch before any change)

`lua5.1 tools/validate_routes.lua -q addons/FastesBoooy_UndeadPaladin` (and `..._SkyborneDruid`); both routes
also simulate `OK` to level 60 (`lua5.1 tools/simulate_routes.lua <module dir>`, about 26 s each).

| | `horde-undead-paladin` | `horde-skyborne-druid` |
|---|---|---|
| ERROR / WARN / INFO | 0 / 99 / 385 | 0 / 149 / 390 |
| WARN by code | 77 `xp-unknown`, 13 `level-grind`, 4 `step-no-profile`, 4 `at-far-from-giver`, 1 `segment-level` | 126 `xp-unknown`, 12 `level-grind`, 4 `step-no-profile`, 4 `at-far-from-giver`, 1 `segment-level`, 1 `fly-unknown-fp`, 1 `train-not-class-trainer` |
| End level (normal / worst case) | 60.00 / 60.00 | 60.00 / 60.00 |
| Grind kills (normal / worst) | 4,972 / 6,179 | 4,878 / 6,082 |
| With 15 % incidental (normal / worst) | 3,954 / 5,271 | 3,883 / 5,172 |
| Grind kills in 1-22 (normal / worst) | 75 / 108 | 0 / 40 |
| Grind kills in 22-60 (normal) | 4,897 | 4,878 |
| Quests with estimated XP | 77 | 126 |
| Steps (composed) | 1,717 (1,713 after A.5.1 rule 9) | 1,752 (1,748) |
| Max quest log | 23 | 23 |
| Level entering 13-15 / 15-18 / 18-22 / 22 | 12.78 / 14.56 / 17.99 / 22.06 | 13.32 / 15.59 / 19.02 / 22.24 |

Largest gates of the paladin route (normal-run kills): `h-56` segment 1,304 (`h57-winterspring-grind` 584, end
gate 720), `h-37` 1,009 (`h38-level-maraudine` 325, `h39-level-mannoroc` 684), `h-41` 764, `h-46` 617, `h-53`
362, `h-31` 274, `h-44` 178, `h-50` 154, `h-34` 151, `h-27` 84, `ud-05` 74.

**Base profile of the Undead** (a scratch run of this review: today's route with every class-masked quest,
every `train` step and every insert hidden, profile Scourge WARRIOR, 0 errors; `routes.md` 3.6 has the same
figures):

| | Value |
|---|---|
| End of `ud-01` / `ud-02` / `ud-03` / `ud-04` | 5.73 / 12.09 / 14.05 / 17.64 |
| End of `ud-02` without the paladin's gate `ud02-xp-12` | 12.08 (the gate itself: 1 kill in this run; 9 kills and 11.90 before it in the reviewer's run, which strips the mixed steps differently) |
| Grind kills in `ud-05` (normal / worst) | 106 / 146 (`ud05-lvl-grind` 106 / 107, `ud05-lvl-pre20` 0 / 22, `ud05-lvl-21` 0 / 17) |
| Grind kills 1-22 (normal / worst) | 108 / 147 (reviewer: 116 / 152) |
| Whole route (normal / worst) | 5,042 / 6,215 |

So the base Undead is at 11.9-12.0 where the paladin is at 12.6, at 14.05 instead of 14.56 when it reaches the
Barrens, and at 17.64 instead of 17.99 at the first Thunder Bluff stop. The 22-60 path alone: 4,934 grind kills
(worst 6,068) for any other race + class profile (`routes.md` 6.3).

## Appendix 2. Command reference (after F1)

```
G=addons/FastesBoooy_Guides
V="--strict --end-level"                                              # plus the budgets of A.6.3 from P2 on
lua5.1 tools/validate_routes.lua -q $V --summary $G                   # all routes, about 5 s; one TSV line per route
lua5.1 tools/validate_routes.lua -q $V --route '<id|list|glob>' $G
lua5.1 tools/validate_routes.lua --route <id> --levels $G             # level, anchor and file at every explicit step id
lua5.1 tools/validate_routes.lua ... --skip 'Classes/*' [--keep 'Classes/X.lua']   # base profile / one class file
lua5.1 tools/validate_routes.lua ... --own 'Classes/X.lua'            # strict and module checks for own files only
lua5.1 tools/validate_routes.lua ... --grind-until SEG --max-grind-until SEG=N/W   # budget up to the end of SEG
lua5.1 tools/validate_routes.lua ... --skip 'Classes/*' --write-baseline f.json    # P2 / P3 / R
lua5.1 tools/validate_routes.lua ... --baseline docs/dev/handover/baseline.json    # class total <= base of the race
lua5.1 tools/validate_routes.lua ... --no-overrides                   # ignore tools/overrides/*.lua
lua5.1 tools/validate_routes.lua --route <id> --write-state f.json --until <step or segment id> $G
lua5.1 tools/validate_routes.lua --harness $G --segments a,b --profile race=..,class=..,faction=Horde [--state f.json]
lua5.1 tools/simulate_routes.lua --route <id> $G                      # about 26 s
lua5.1 tools/simulate_routes.lua --list-routes
GUIDES_SKIP=.. GUIDES_KEEP=.. GUIDES_OWN=.. busted tests/spec/guides_layout_spec.lua
make route ROUTE=<id>        make check-fast        make check        make simulate-sync-full
make routedata               make report            (single-owner phases and the orchestrator's closing step only)
```

---------------------------------------------------------------------------------------------------------------

## Review log

Three adversarial reviews of revision 1 (lenses: engine and tools "ET", route speed "RS", parallel execution
"PE"). Each finding was checked again against the code and the DB snapshot before the plan was changed.
"Checked" names what was looked at for that. Verdicts: accepted, accepted in part (the rejected part is named),
rejected.

| # | Sev. | Finding | Checked | Verdict | Change in this plan |
|---|---|---|---|---|---|
| ET-1 | major | A shared insert anchored on a race-filtered step of a shared segment is composed into every route of the class (both alternatives shown). | `Compose.lua:256-271` copies every step, `:327-349` resolves anchors over all steps, `Engine.lua:361-363` filters per step only. | accepted (fix a) | R10; A.5.1 rules 9 and 10; spec cases and fixture in A.5.7; ERROR `insert-scope-wider-than-anchor` in A.6.2; join steps in B.4-B.6; (F) marks in C.2; C.3 rule 8; step baseline 1,713 / 1,748 in D.1, D.2, appendix 1. The alternative (b), intersecting filters at composition, was not taken: pruning is simpler and also removes the per-route `step-no-profile` flood. |
| ET-2 | major | Scope pruning hides `race =` typos: a step that matches no route is composed nowhere and no check walks it. | `Schema.lua:351-355` (strings only), `validator.lua:1876-1890` (composed steps only). | accepted | A.5.1 error table; A.6.2 module checks on the templates (`unknown-race-token`, `shared-step-unused`, definition of "applied"); specs in D.1 F1b; fixture. |
| ET-3 | major | The numeric acceptance criteria are not checked by the listed commands; `ok` would remove the only grind guard. | `validator.lua:2567-2573`, `:1705-1709`, `:1748`, `:45`; 17 `WARN-OK: level-grind`; gate 39 + 78 % = 684 kills. | accepted | A.5.5 and A.6.3: ceilings, `--end-level`, `--summary`, `--grind-until`, `--max-grind-until`, `--write-baseline` / `--baseline`; `VALIDATE_FLAGS`; all validation blocks of D; appendix 2. |
| ET-4 | major | The override files are a single point of failure and a hidden coupling (loaded by everyone, not linted, change pinned spec numbers, silent XP changes on shared quests). | `.luacheckrc` excludes `tools/data/**`; `validator.lua:2518`; five specs call `DB.Load` on the snapshot. | accepted | A.6.2 override layer rewritten: `tools/overrides/`, `pcall` per file, `DB.Load` applies none, CLIs opt out with `--no-overrides`, lint rule, `override-foreign-quest`; A.7 fixture targets; C.5; D.0 rule 3. |
| ET-5 | major | Nine agents may add ids to the same 12 shared files: duplicate ids break everyone. | Loader dump: 936 of 1,300 steps of `h-22` .. `h-56` are positional; `Schema.lua:473-476`. | accepted, in the form of PE-4 | A.3; B.7; D.4 step 5 (P2 assigns hub ids); D.5 "no class agent edits a segment file", wishes go to R. Not taken: deterministic ids `h31-s57` edited in phase C (no id collisions, but still concurrent writes to one file and renames after the freeze). |
| ET-6 | minor | Deleting steps 4-6 of `h-22-hillsbrad` shifts 42 positional ids; saved marks then mark other steps. | Loader dump (steps 4-6 are the Skyborne-only ones); `Engine.lua:198-208`. | accepted | A.3, A.8, B.7: every step of `h-22-hillsbrad` gets an explicit id in the same edit; E.12. |
| ET-7 | minor | The worst-case run ignores `fp` and `sethearth` learned only on optional steps. | `validator.lua:1748`, `:1360-1375`, `:1244-1251`. | accepted | A.6.3 "Worst case"; C.4; spec in D.1 F1b. |
| ET-8 | minor | The `simulate` recipe ignores a failing `--list-routes` and then runs every route in one process. | Not re-run; follows from the pipeline status and from GNU xargs running once on empty input. | accepted | A.7 recipe (`|| exit 1`, empty check, `xargs -r`), same rule for the sync targets; A.6.5 exit code of `--list-routes`. |
| ET-9 | minor | The simulator takes reward choices only from `step.reward`; the class reward table would be tested by unit specs only. | `simulate_routes.lua:413-421`, `:452-456`; 13 `reward` steps in the druid route. | accepted | A.6.5 "Reward choices"; fixture quest in A.5.7. |
| ET-10 | minor | The new module checks would flag the old library module and fixtures in F1; the expected F1 warning counts were wrong. | Today's output: the library reports 0 / 0; 4 `step-no-profile` per route. | accepted | A.6.2 (checks only for a module that registers routes, over its own templates); D.1: 95 / 145 WARN after F1a, 18 / 19 after F1b (as executed: 18 / 18, the nineteenth is INFO `train-service`; D.1 row F1b). |
| ET-11 | minor | `--strict` counts WARNs on files the agent may not edit: the phase gate can deadlock. | `validator.lua:2615`. | accepted | `--own` (A.6.1, A.6.3), used in F2c, P1, C; foreign warnings go to the hand-over (D.0 rules 5 and 7; C.3 rule 7). |
| ET-12 | minor | After P1 and C the tree fails the CI freshness steps; nothing says so. | `.github/workflows/ci.yml`. | accepted | D.0 rule 2 (closing step by the orchestrator; which commits are pushed); A.7. |
| RS-1 | major | Every Tauren gets `accept-exclusive` on the shared accept of 844 after 861 / 854. | DB: 861 and 854 have `exclusive = {844}`, 860 has `breadcrumbFor = 844`, `preSingle = {861}`; `validator.lua:942-955`. | accepted | B.2 "The Tauren breadcrumbs and 844"; override fields `exclusive` etc. in A.6.2; `tools/overrides/shared.lua` and the replay spec in D.2 F2b; synthetic Tauren state with its real `done` list; E.21. Not taken: making the validator skip the reverse index along `next` / `breadcrumbFor` chains (854 has no such link to 844, so it would cure only 861). |
| RS-2 | major | Levels at trainer stops were paladin numbers; base profiles arrive just under 12, 18 and (Durotar) 10. | Own scratch run: base Undead 12.09 at the end of `ud-02` (12.08 without the paladin gate), 14.05, 17.64; `ud-05` 106 / 146 kills. It gives 11.99 instead of the reviewer's 11.90 before the gate and 108 / 147 instead of 116 / 152 for 1-22: the two runs strip the mixed steps differently; the conclusion is the same. `startzones.md` 5.1 step 7: 9.42 -> 9.88. | accepted | R11; B intro; B.1; B.2; B.4 (`h13-lvl-14`); B.6 (`h18-lvl-18`); B.8 (trainer-hub gates, corrected numbers); B.9 table; C.2 (`ud02-lvl-12`, `dur02-lvl-10`); E.7, E.22; appendix 1. |
| RS-3 | minor | The Durotar hand-over "inside Orgrimmar after 812 / 831" contradicts the DB and costs a second city entry. | DB: 812 starts and ends at Rhinag 3190 (Durotar 41.54, 18.6), child 813 at Kor'ghan, 831 ends at Nazgrel. | accepted | A.1; B.1; B.2 "Durotar and Orgrimmar"; B.3 (`h12-borstan`, `h12-wisdom`); C.2; E.20 (timer). |
| RS-4 | minor | Troll riding anchored a level later than necessary. | Ids at `06_h-37-...lua:389-391` and `07_h-41-...lua:92`; NPCs 7953 / 7952 in Sen'jin. The 17,370 yd were not recomputed. | accepted | C.6, C.7. |
| RS-5 | minor | The cheapest unused quest XP of the Undead (Orgrimmar city quests) was last in the fall-back order. | DB records of 97246, 97249, 97242, 97275, 97326; base run: `ud05-lvl-grind` 106 kills. | accepted in part | B.5, B.8, C.6: the four fixed quests are a default insert, 97326 optional. Rejected: the wording "under about 5 minutes per 1,000 XP" as the general criterion; at 30 s per kill the grind itself yields 1,000 XP in 3.3 min at 21 and in 2.0 min at 40, so B.8 has a cost rule tied to the level, and the 120 / 200 ceiling stays. |
| RS-6 | minor | The contingency of the Tauren flight (E.1) was understated; same fact treated two ways in E.1 and E.2. | Plan text; DB: 6361-6364 start at the Crossroads; comment at today's `sd03-fly-org` (RestedXP guide). | accepted in part | Both branches written out under the E table; `fp` filters derived from the variant (B.5); second synthetic state (D.2). Rejected: moving the turn-ins of 854 / 860 / 886 to `h15-xr-arrive` in the walk variant too (the Tauren stand next to the NPCs at 12 and the 400 XP count for `h13-lvl-12`); and "the same fact": the Skyborne flight has outside evidence, the Tauren one has none (E.2). |
| PE-1 | blocker | Same as RS-1; the override layer could not express it; the synthetic state had no `done`. | as RS-1 | accepted | as RS-1; the override layer also takes `preSingle`, `preGroup`, `breadcrumbFor`. |
| PE-2 | major | `--strict` as the gate of parallel phases cannot be met for WARNs on shared files. | `validator.lua:1318-1323`, `:45`; `FastesBoooy_UndeadPaladin/Inserts.lua:57-58`. | accepted | as ET-11; D.4 step 2 and D.6 step 2 resolve the reported warnings. |
| PE-3 | major | A mistyped or wrong-zone anchor is silently dropped in every filtered command. | Revision 1, A.5.1 and A.6.1 ("not with `--skip`"). | accepted | A.6.2: `insert-anchor-unknown`, `insert-unapplied`, `shared-step-unused` run for own files under a filter; `--levels` prints anchor and file; D.5. |
| PE-4 | major | Concurrent edits of the twelve 22-60 files; contradiction with the freeze. | as ET-5 | accepted | as ET-5. |
| PE-5 | major | Override files couple all agents; an XP override moves the median estimate of other quests. | `fbdb.lua:36-49`. | accepted | A.6.2 (median from the snapshot, `pcall`, one id in one file, owner rule); C.5; D.6 step 3. |
| PE-6 | major | Contract anchors were race-filtered alternatives; `h15-start` meant "after leaving the city". | as ET-1 | accepted | as ET-1; B.5 step 0 (`h15-org`); B.9 table; layout spec case in D.2 F2b. |
| PE-7 | major | P2 can be blocked by `Classes/Druid.lua`, which it may not edit and which no Tauren run had tested. | Revision 1, D.2 / D.3 / D.4. | accepted | D.2 F2b step 2 (race scope rule) and step 6 (Tauren DRUID proof with class files); D.4 (P2 may set `race =` scope lines; acceptance split). |
| PE-8 | major | The Orc / Troll / Tauren rows of `Route.lua` first run in P1, where nobody may fix them. | Revision 1, D.2 step 5, D.3. | accepted | A.4 (complete table in F2a, `only`, fixture-zone proof); A.6.1 `opts.replace`; D.0 rule 6; D.3. |
| PE-9 | major | F2b and F1 are too large for one agent. | Loader dump: 314 start-zone steps (62 with ids), 503 legacy steps; 196 `WARN-OK`; file sizes. | accepted | D: F1a / F1b / F1c and F2a / F2b / F2c (two parallel agents) / F2d. One deviation from the proposed cut: the `ok` conversion and `--strict` are in F2a (mechanical), so F2b and F2c already work under the strict gate. |
| PE-10 | major | The layout spec cannot serve parallel agents; draft anchor tables were frozen too early. | Revision 1, D.2 step 7; `startzones.md` section 6 ("draft"). | accepted | D.0 rule 9 (`GUIDES_SKIP` / `GUIDES_KEEP` / `GUIDES_OWN`); C.2 "How binding the tables are"; anchor lists come from the hand-overs (F2d, P2). |
| PE-11 | minor | P1 acceptance held path agents to numbers of the shared path. | Revision 1, D.3. | accepted | B.2 (the contract is the whole acceptance); D.3; the 120 / 200 budget is a criterion of F2b (synthetic states), F2d and P2. |
| PE-12 | minor | No commit, revert or CI policy for the shared checkout. | Revision 1, D.0. | accepted | D.0 rules 1 and 2. |
| PE-13 | minor | `dur02-thunder-ridge` promised warrior 1498, which is given at Far Watch Post. | DB: 1498 starts and ends at Uzzek 5810 (Barrens 61.38, 21.12); 1505 is its breadcrumb; 2983 ends at Kranal Fiss 5907. | accepted | C.2 "Chains whose giver stands at Far Watch Post" (decision, distances). |
| PE-14 | minor | The faction-word rule was wider than its check and would fail on in-world uses. | Notes at `UndeadPaladin/Segments/05_...lua:474`, `SkyborneDruid/Segments/01_...lua:92`; in-world uses in `h-44`, `h-46`, `h-50`, `h-53`. | accepted | 0.1 item 2; D.2 F2d step 2 (allow-list, the two notes to reword). |
| PE-15 | major | Speed first is pursued only for 1-22; 98 % of the grind is in 22-60 and no phase owns it. | Validator: 4,897 of 4,972 kills in `h-22` .. `h-56`; `docs/routes/horde-22-60.md` (compaction of November 2026: 6,362 -> 4,972). | accepted in part | R9 (explicit scope decision with evidence), budgets that keep every route at or below the base (A.6.3), the fully specified optional phase P3 (D.4a), question E.19 for the user. Rejected: making the 22-60 review a mandatory phase now. That path already had a dedicated compaction, the cost rule leaves few candidates at 40+ (one kill is worth 245+ XP), the yield is uncertain and the phase delays nine class agents; the user decides. |
