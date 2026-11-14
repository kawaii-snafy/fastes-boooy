# Core research for the "FastesBoooy_Guides" redesign

Scope: `addons/FastesBoooy/Core/*.lua`, `addons/FastesBoooy/UI/*.lua`, `addons/FastesBoooy/Locales/*.lua`,
`tests/spec/core_*_spec.lua`, `docs/ARCHITECTURE.md`, `docs/ROUTE_FORMAT.md`, plus the parts of `tools/` that
mirror the core registry (`tools/lib/route_loader.lua`). Read-only research; nothing in the repository was changed
except this file. All line numbers refer to the checkout of branch `claude/beautiful-planck-svbl19` at the time
of writing (core 0.3.1, `API_MINOR = 1`).

Numbers in section 6 were measured with scratch scripts on the WoW mock (`tests/mocks`, PUC Lua 5.1, x86-64).
A prototype of the shared-insert change (appendix B) was run against the existing specs in a scratch copy of the
repository: `core_compose_spec`, `core_schema_spec`, `core_registry_spec`, `validator_compose_spec` = 49
successes, luacheck clean, validator output of `FastesBoooy_UndeadPaladin` identical (0 errors, 99 warnings).

---------------------------------------------------------------------------------------------------------------

## 0. Summary: what matters for the design, and what contradicts the decisions

1. **A module that holds shared segments and many routes already works in the core and in most tools.** The core
   has no notion of "module" at all: one global library store plus a flat route list (`Registry.lua:31-37`,
   `148-155`). "A route in a declared library module is a load error" is true only for a module whose TOC
   says `## X-FastesBoooy-Module: library` (`tools/lib/route_loader.lua:407-414`, `464-468`). A module without
   that TOC line may register library segments and any number of routes today. Verified: a scratch module with
   one `AddLibrarySegment` and three `RegisterRoute` + `UseSegments` validates (3 routes x profiles, 0 errors)
   and `gen_route_data` writes `AddLibraryData` + one `AddRouteData` per route. The only refusal is the
   harness: `tools/lib/harness.lua:386-390` ("registers route(s) ...: --harness takes a library module").
2. **Shared inserts need a small core change** (about 120 lines in `Compose.lua`, 20 in `Schema.lua`, 10 in
   `Registry.lua` / `Init.lua`). Design in section 5, working prototype in appendix B.
3. **`Registry:List()` composes every route** (`Registry.lua:286-291`). It is called by the settings panel and by
   `/fb routes` (`UI/Options.lua:466-470`, `754-774`). With 28 routes that is **+32 MB and ~120 ms** (measured,
   section 6). The settings panel also shows only the first `MAX_ROUTE_BUTTONS = 3` routes in registration order
   (`Options.lua:96`, `477-508`), so an undead paladin would see three orc routes and "...and 25 more". Both
   must change; this UI work is not in the decisions list.
4. **Positional step ids are everywhere.** 936 of 1300 library steps, 317 of 394 own steps of the paladin route
   and 352 of 423 of the druid route have no explicit id and get `<segment>:<n>` (`Schema.lua:473`). Saved
   progress is keyed by step id (section 3). Making the start zones class-agnostic (moving class steps out) and
   unifying `ud-04/05` with `sd-04/05` renumbers those ids. Insert anchors must be explicit ids (all 28
   existing anchors already are); the plan must give every anchor step an explicit id before the class agents
   start, and path agents must not rely on positional ids.
5. **"The race implies the faction" is false for Skyborne.** The raceFile `Skyborne` exists on both factions
   (`tools/lib/validator.lua:75-76`, `README.md:151`). Routes must keep `faction = "Horde"` (decision 2 does);
   the faction just must not appear in titles.
6. **Per-class reward choices cannot be put on a shared step.** `reward = { [quest] = index }` is one value per
   step (`Schema.lua:302-318`, `Engine.lua:1974-1986`). The Zephras segments carry 13 `reward` entries chosen
   for a druid. Class-agnostic Zephras needs either a class-keyed reward (small Schema + Engine change) or a
   class-filtered duplicate turn-in step from the class file (works today, see 5.7).
7. **On-demand loading of per-race files is not possible inside one addon folder.** `C_AddOns.LoadAddOn` exists
   in the client (`tools/data/forever_api.lua:583-591`) but loads whole addons with `## LoadOnDemand: 1`; that
   needs extra folders and contradicts decision 1. It is not needed: loading all races costs about 3 MB extra
   (section 6).
8. **Users who keep the old folders** (`FastesBoooy_Horde`, `FastesBoooy_UndeadPaladin`,
   `FastesBoooy_SkyborneDruid`) next to `FastesBoooy_Guides` get duplicate library segment ids ("registered
   twice (second definition ignored)", `Compose.lua:105-107`) and two matching `default` routes. The core should
   warn at login (section 3.4).
9. **luacheck forbids `ipairs` / `pairs` in route modules** (`.luacheckrc:129-140`, std `fastesboooy_route`;
   verified: W113 on `ipairs`). "Route.lua registers the 28 routes from a table" must use numeric `for` loops
   (they need no globals) or the std must be extended.
10. Renaming route ids is harmless but loses the saved high-water mark and level-sync floor of existing
    characters (section 3.3). An optional `aliases` field would keep them.

---------------------------------------------------------------------------------------------------------------

## 1. Registration API

Public wrappers: `Core/Init.lua:55-83` (`FastesBoooy.RegisterRoute / AddSegment / AddRouteData /
AddLibrarySegment / AddLibraryData / UseSegments / AddInsert`), all forwarding to `ns.Registry`. Feature level:
`public = { API_VERSION = 1, API_MINOR = 1 }` (`Init.lua:34`).

| API | Registry | Pure code | What it does |
|---|---|---|---|
| `RegisterRoute(def)` | `Registry.lua:63-102` | `Schema.NormalizeRoute`, `Schema.lua:409-440` | Normalizes metadata (`ROUTE_FIELDS`, `Schema.lua:51-56`). Refuses `api ~= 1` (`71-75`) and a second route with the same id (`76-79`). Stores the route in `routes[id]` and `order`. Replays calls that were queued before the route existed (`85-99`). Fires `ROUTES_CHANGED`. |
| `AddSegment(routeId, def)` | `Registry.lua:119-142` | `Schema.AddSegment`, `Schema.lua:444-487` | Normalizes the segment and appends its steps to the route, or to `route.own` when the route is composed (`Compose.OwnTarget`, `Compose.lua:157-159`). Before `RegisterRoute`: error + queue (`121-132`). |
| `AddLibrarySegment(def)` | `Registry.lua:172-177` | `Compose.AddLibrarySegment`, `Compose.lua:100-123` | Normalizes the segment once into the library scratch (`lib.scratch`), so segment ids and step ids are unique across the whole library. Tags segment and steps `library = <module> or true` (`112-118`). Marks every route with `UseSegments` dirty (`libraryChanged`, `Registry.lua:158-166`). |
| `AddLibraryData(data)` | `Registry.lua:183-191` | `Compose.AddLibraryData`, `Compose.lua:127-132` | Merges into `lib.data` key by key (later call wins). |
| `UseSegments(routeId, ids)` | `Registry.lua:198-210` | `Compose.AddUses`, `Compose.lua:165-189` | Makes the route "composed" (`Compose.Enable`, `145-154`: the current segments move to `route.own`) and records the ids in `route.uses`. Nothing is resolved yet. Before `RegisterRoute`: error + queue (`Registry.lua:105-114`). |
| `AddInsert(routeId, def)` | `Registry.lua:216-228` | `Compose.AddInsert`, `Compose.lua:194-239` | Normalizes the steps now (format errors once), marks them `inserted`, `anchor`, `explicitId`, records `{ side, anchor, steps }` in `route.inserts`. The anchor is resolved at composition. |
| `AddRouteData(routeId, data)` | `Registry.lua:260-273` | `Compose.MergeData`, `Compose.lua:62-78` | Merges into `route.data` key by key (later call wins). |

Errors never raise; they are appended to `Registry.errors` (cap 500, `Registry.lua:40-47`) and shown as a count plus
the first message at login (`Engine.lua:2019-2022`) and by `/fb routes` (`Options.lua:766-773`).

### Where "library module" is enforced

* **Core: nowhere.** The registry does not know which addon made a call. `AddLibrarySegment` and `RegisterRoute`
  from the same addon are indistinguishable from calls of two addons.
* **Tools only:**
  * `tools/lib/route_loader.lua:407-414`: the TOC key `X-FastesBoooy-Module` must be `library` if present.
  * `route_loader.lua:464`: `mod.isLibrary = #mod.routes == 0 and (library segments or library data or declared)`.
  * `route_loader.lua:465-468`: declared library + a registered route = load error.
  * `tools/lib/harness.lua:386-390`: `--harness` refuses a module that registers routes.
  * `tools/simulate_routes.lua:1554`, `tools/lib/validator.lua:1945-1952`, `2554-2557`,
    `tools/gen_route_data.lua:284`, `362`: branches on `mod.isLibrary` (skip simulation, list as library, write
    `AddLibraryData`).
* The loader has its own registry stub (`route_loader.lua:190-327`); it does not load `Core/Registry.lua`. Every
  new public function needs a stub there (and in `.luacheckrc:132-138`).

### One module with many routes and shared segments

Works in game today. Evidence: `tests/spec/core_compose_spec.lua:272-302` registers a library segment, library
data and three routes through the same API table and checks per-route copies; the measurement script of section 6
registered the Horde library plus 28 routes in one session and logged in with one route composed.
Works in the loader, validator and `gen_route_data` when the TOC does not declare `library` (verified, see 0.1).
`gen_route_data` then writes one `AddRouteData("<id>", { quests = {}, npcs = {} })` block per route even when
the route has no own steps (28 empty blocks; harmless, could be suppressed).

---------------------------------------------------------------------------------------------------------------

## 2. Composition

### Lazy, per route

* `UseSegments` / `AddInsert` / `AddSegment` on a composed route / any library change only set `route.dirty`
  (`Compose.lua:152`, `187`, `237`; `Registry.lua:137`, `158-166`).
* `Registry:Finalize(route)` runs `Compose.Build` for a dirty route and records each composition error once per
  route (`Registry.lua:232-251`).
* Readers that trigger it: `Registry:Get` (`279-284`), `Registry:List` (`286-291`, **all routes**),
  `Registry:Matching` (`296-305`, only routes whose faction / race / class match), `Engine:BuildSteps`
  (`Engine.lua:358`).
* Login: `Engine:Start` (`Engine.lua:2011-2031`) -> `SelectRoute` (`503-510`) -> saved id through `Get`, else
  `Select` -> `Matching`. Spec: `core_compose_spec.lua:167-186`. Measured with 28 routes: 1 composed, 27 not.

### `Compose.Build` (`Compose.lua:282-416`)

1. **Segment order** (`291-326`): the route's own segments not named in a `UseSegments` list, in `AddSegment`
   order; then the `UseSegments` entries in call order. An entry is a library segment or one of the route's own
   segments (moved to that position). Errors: listed twice (`306-307`), id is both own and library (own wins,
   `311-318`), unknown library segment (`321-324`).
2. **Inserts** (`328-374`): `home[stepId]` = entry holding the step. Inserts are processed in call order in a
   fixpoint loop, so an anchor may be a step of another insert registered later. `after`: position right after
   the anchor, or after the last step of an earlier insert at the same anchor (`tail`, `353-355`, `366`).
   `before`: right before the anchor, so earlier `before` inserts stay in front. Inserted steps take the
   anchor's `segment` and `segIndex` (`359-360`). Unresolved anchors after the loop: error "unknown anchor step"
   (`371-374`).
   Quirk to know: an insert anchored *after the last step of an earlier insert at anchor X* is pushed behind
   later inserts at X, because `tail[X]` is that last step (seen in the prototype test, appendix A.3).
3. **Flatten** (`376-407`): new `segments`, `steps`, `stepById`, `segmentById`; `step.index` = position.
   Duplicate step ids that only appear after composition are errors (`385-394`), duplicate library segment ids too
   (`399-404`).
4. **Data** (`409-413`): when the route has at least one `UseSegments` entry, `lib.data` is merged *under*
   `route.data` (fill-only).

### Copied or shared

* **Library steps: one shallow copy per route**, cached in `route.libCopies` so a rebuild keeps object identity
  (`Compose.lua:259-275`). Scalars (`id`, `segment`, `segIndex`, `index`, `bg`, `optional`, `library`, `file`)
  are per route. Sub-tables are shared by reference between all routes and the library template: `actions`,
  `filters`, `at`, `npc`, `object`, `note`, `reward`, `spells`, `def`. Spec: `core_compose_spec.lua:290-291`.
* The engine never writes into steps (checked: no assignment to step or action fields in `Engine.lua`,
  `Steps.lua`, `Automation.lua`, `Waypoint.lua`, `UI/*`). `Engine.void` is keyed by the shared action tables
  (`Engine.lua:163`, `Steps.lua:171`); that is safe because one client has one active route.
* **Own steps** are not copied: the same tables are in `route.own.steps` and `route.steps`; `index` is rewritten.
* **Insert steps** belong to one route and are mutated by `Build` (`s.id`, `s.segment`, `s.segIndex`,
  `s.insertSide`, `357-361`). A shared insert therefore needs per-route copies (section 5).
* **Segments**: a fresh shallow copy per build with the per-route `steps`, `first`, `last` (`379-381`, `397`).

### Step id uniqueness

* Explicit `id`: `[A-Za-z0-9-_.:]` (`Schema.lua:281-287`). Default: `<segmentId>:<position in the definition>`
  (`Schema.lua:473`). The position counts every step of the definition, including steps of other classes.
* Duplicates inside one target are reported by `Schema.AddSegment` (`474-478`); the target is the route (own
  segments) or the single library scratch (`Compose.lua:86-92`, `108`), so library ids are unique across all
  library modules.
* Insert steps: `explicitId` or `<anchorId>+<n>`, n = running number of inserted steps at that anchor in that
  route (`Compose.lua:357-358`).
* Own vs library vs insert collisions: composition error (`385-394`).

### Data merge (names, places, questMeta)

`Compose.MergeData(dst, data, fillOnly)` (`Compose.lua:62-78`) merges per kind (`quests`, `npcs`, `objects`,
`items`, `places`, `questMeta`, ...) and per key.

* `AddRouteData`: into `route.data`, later call overwrites the key.
* `AddLibraryData`: into `lib.data`, later call overwrites the key.
* At composition the library data fills only the keys the route does not have, so **the route's value wins**;
  `questMeta` is merged per quest id (the whole entry of the route wins). Spec: `core_compose_spec.lua:283-295`.
* Only routes with `#route.uses > 0` get library data; a plain route gets none (`core_compose_spec.lua:295`).
* The merge copies the key index of the whole library into each composed route's `data` tables (values are
  shared). With all races in one library that is roughly 100-150 KB per composed route.
* Consumers: `Registry:Lookup` / `PlaceArea` (`Registry.lua:332-352`), `Engine:BuildDependents`
  (`Engine.lua:457-499`, `questMeta` for gray / unreachable / item rules).

---------------------------------------------------------------------------------------------------------------

## 3. Route selection and saved progress

### 3.1 Selection at login

`Engine:SelectRoute` (`Engine.lua:503-510`):

```lua
local id = ns.cdb.route
local route = id and ns.Registry:Get(id) or nil
if not route then route = ns.Registry:Select(facts) end
```

* `cdb.route` is written **only** by a manual choice (`Engine:SetRoute`, `537-555`; settings click or
  `/fb route <id>`). An automatically selected route is not saved (`Init.lua:320`: "nil = automatic selection").
* `Registry:Select` (`Registry.lua:319-328`): among `Matching(facts)` (faction, races, classes via
  `Schema.RouteMatches`, `Schema.lua:501-506`; routes with zero steps are skipped, `Registry.lua:301`) the best
  score wins: `default` = 10, plus 2 when the level is inside `levels` (`level >= from and level < to`), 1 when
  below, 0 when past it (`307-313`). Ties: registration order (strict `>`). Spec: `core_registry_spec.lua:77-94`.
* 28 routes with one race and one class each: exactly one route matches a character, so `default = true` on all
  28 is unambiguous.
* A route registered after login is picked up: `ROUTES_CHANGED` -> `RequestRefresh(true)` -> `Refresh` retries
  `SelectRoute` while there is no route (`Engine.lua:2055-2060`, `1180-1187`).
* Facts come from `Compat.PlayerFacts` (`Compat.lua:297-317`): `race` = raceFile of `UnitRace` (`Scourge`,
  `Orc`, `Troll`, `Tauren`, `Skyborne`), `class` = classFile, `faction` = `UnitFactionGroup`. Cached once all
  three are known.

### 3.2 How progress is keyed (`FastesBoooyCharDB`, defaults `Init.lua:319-335`)

| Field | Key | Written at | Validated |
|---|---|---|---|
| `route` | route id | `Engine.lua:543-545` | `SelectRoute`: unknown id falls back to automatic selection; the stale value stays |
| `cursorHint`, `cursorHintId`, `cursorHintRoute` | index, **step id**, **route id** | `SaveHint`, `585-593` | `ValidHint`, `567-583`: another route id -> 0; unknown step id -> 0; a bare index without id is trusted when in range |
| `manual[stepId]`, `skipped[stepId]` | **step id only** (no route) | `1263`, `1313`, `1348`, `1508` | none: a mark applies to any route that has a step with that id |
| `bgDone[stepId]` | step id only | `1037` | none |
| `gaveUp[questID] = { accept = stepId, steps = { stepId, ... } }` | quest id + step ids | `1505-1511` | a record whose accept step is unknown is ignored (`950-956`), replaced when stale (`1489-1492`) |
| `syncFloor = { route, stepId, from, to, keep = { { id, type } }, hint, prev }` | route id + step ids + segment ids | `1838-1845` | `GetSyncFloor`, `601-607`: other route id or unknown step -> no floor |
| `syncDismissed = { route, segment, level }` | route id + segment id | `1893`, `1914` | compared in `ComputeSyncSuggestion`, `1757-1760` |

### 3.3 Renames

**Route id `horde-undead-paladin` -> `undead-paladin`:**

1. `cdb.route == nil` (the normal case): automatic selection picks `undead-paladin`. Chat line "Route: ...".
2. `cdb.route == "horde-undead-paladin"` (the player once picked it by hand): `Registry:Get` returns nil,
   automatic selection picks `undead-paladin`, no message about the stale id. `cdb.route` keeps the dead string;
   it has no effect until a route with that id exists again.
3. `cursorHintRoute` differs -> the high-water mark is 0. The cursor is rebuilt like a cold start: the forward
   limit is the last non-bg step with an accept / turnin / complete whose stateful actions are done
   (`Engine.lua:926-935`); stateful steps are read from the game. Only transient steps (go, train, fp, fly,
   sethearth, vendor, manual) after that last anchor step are shown again. Then the hint is saved under the new id.
4. `syncFloor.route` differs -> the floor is ignored (not deleted). A character that jumped ahead with level
   sync gets the suggestion again (mode `ask`) or the jump is re-applied (mode `auto`).
5. `syncDismissed.route` differs -> the dismissal is forgotten; the banner may reappear once.
6. `manual` / `skipped` / `bgDone` / `gaveUp` survive as long as the **step ids** are unchanged.

**Step id rename** (explicit rename, or a positional `<segment>:<n>` that shifts because a step was added,
removed or moved to a class file):

* The marks under the old id become dead entries; the step counts as not marked. A step the player skipped
  with "Forward" is asked again if it is a stateful step that is not done in the game (an accept of a quest never
  taken, for example); the cursor can jump back to it. Gray quests of an outgrown segment are skipped anyway
  (`skipGray`), and for the rest the level-sync suggestion offers the jump forward.
* If the old positional id now names a *different* step, the mark silently applies to that other step.
* `cursorHintId` unknown -> hint 0 (as in 3 above). `syncFloor.stepId` unknown -> floor ignored.
  `gaveUp[q].accept` unknown -> the record is ignored, its skip marks are dead entries.
* Nothing crashes and nothing is cleaned up; `/fb reset` clears everything.

**Segment id rename**: only `syncFloor.from/to` (informational) and `syncDismissed.segment`.

**Optional migration (cheap):** add `aliases = "token-list"` to `Schema.ROUTE_FIELDS`, keep
`Registry.aliases[oldId] = route`, let `Registry:Get` resolve it, and in `Engine:ActivateRoute` rewrite
`cdb.route`, `cdb.cursorHintRoute`, `cdb.syncFloor.route`, `cdb.syncDismissed.route` when they hold an alias
of the activated route. About 25 lines. It only helps where step ids stay (`h-*` ids of 22-60 do; start-zone
ids will mostly change). Without it the behavior is the graceful one described above.

### 3.4 Old module folders left installed

The repository deletes the three old folders, but a user who unpacks the new release over the old one keeps
them. Then:

* both `FastesBoooy_Guides` and `FastesBoooy_Horde` register `h-22-hillsbrad` ...; the second registration
  is refused with an error per segment (`Compose.lua:105-107`), library data is merged from both;
* `horde-undead-paladin` and `undead-paladin` both match with `default = true`; the first registered wins
  (addons normally load in alphabetical folder order, so `FastesBoooy_Guides` comes first, but do not rely on it);
* the old route's inserts and own segments still work against whichever library copy was registered first.

Recommendation: the core warns once at login when `C_AddOns.IsAddOnLoaded` (exists: `forever_api.lua:589`; the
mock has it, `tests/mocks/wow/system.lua:613`) reports one of the three obsolete names, through a `Compat`
wrapper; and the release notes say "delete the old folders".

---------------------------------------------------------------------------------------------------------------

## 4. Class / race / faction step filters in the engine

* Normalized at `Schema.lua:342-364` into `step.filters = { class = set, race = set, faction = string }`.
  Match: `Schema.FiltersMatch` (`492-498`); a missing player fact never matches a filter.
* **The only place where filtering happens is `Engine:BuildSteps`** (`Engine.lua:354-371`): `self.steps` = the
  route's steps whose filters match the player (and that have at least one valid action). It runs at
  `ActivateRoute` and after `ROUTES_CHANGED` for the active route.
* Everything else works on that filtered list, so a filtered-out step does not exist for the engine:

| Mechanism | Code | Filtered-out steps |
|---|---|---|
| forward anchor, forward limit | `Engine.lua:926-935` | not anchors, not counted |
| natural cursor, done flags | `972-991` | absent |
| void pass (gray / unreachable / orphan) | `641-870` | absent; `acceptAt` / `turninAt` built from filtered steps (`403-424`) |
| level sync (segment runs, suggestion, kept services) | `440-453`, `1746-1779`, `1570-1690` | absent; a segment with no step for the player has no run and is never a jump target |
| accept window / lookahead | `1945-1965` | the window counts the player's own steps |
| auto turn-in set | `365-367`, `1968-1970` | a quest turned in only by a filtered-out step is not auto-turned in |
| reward choice | `1974-1986` | only filtered steps are searched |
| "next steps" (`GetUpcoming`) | `293-306` | absent |
| header "n/total", `/fb status` "Step n/total" | `StepFrame.lua:630-632`, `Options.lua:798-802` | counts the player's steps |
| `IndexOf`, `SetCursor` | `309-313`, `1334-1353` | nil / filtered indices |

* Unfiltered consumers: `Registry:Matching` (`#r.steps > 0`, `Registry.lua:301`), the settings tooltip
  "Steps: N" (`Options.lua:439`, counts all classes' steps), route data lookups.

### Risks with hundreds of filtered-out steps in a route

1. **Performance at login: none.** `BuildSteps` is one pass with one `FiltersMatch` per route step; measured
   4.5 ms for 1717 steps. Evaluation cost depends on the filtered list only (4.7 ms per refresh for 1713 steps).
2. **Cursor math: safe.** Indices are positions in the filtered list; persistence is by step id.
3. **Step numbering: correct per character** ("n/total" of the player's own steps). Only the tooltip
   "Steps: N" would be wrong.
4. **Positional ids: the real risk.** A step added for another class inside a shared segment shifts
   `<segment>:<n>` of every later id-less step for all classes, which moves saved marks and hints (3.3). Shared
   content needs explicit ids at least on anchors and on every step a player can mark (in practice: on all steps
   of new segments).
5. **Memory per composed route**: each foreign step costs a ~0.9 KB copy. With shared inserts pruned by scope
   (section 5) foreign class steps are not composed at all, so this risk disappears for class files.
6. **Validator noise**: `step-no-profile` is exactly "the filter matches none of the route's profiles"
   (`tools/lib/validator.lua:1891-1906`). With one profile per route every foreign-class step would warn in
   every route. Scope pruning removes that for shared inserts; race-filtered steps inside shared *segments*
   (8 today in `h-22` / `h-24`) still need the cross-route check in the validator.
7. An insert anchored on a step that is filtered out for the player is still shown at that position (the anchor
   exists in `route.steps`). That is the current behavior and stays.

---------------------------------------------------------------------------------------------------------------

## 5. Design: shared inserts, and one module with shared segments and many routes

### 5.1 API

```lua
FastesBoooy.AddLibraryInsert({
    after = "h-27-tb-arrive",          -- or before = "<stepId>"
    class = "PALADIN",                 -- optional scope: token or list
    race = { "Scourge" },              -- optional scope
    faction = "Horde",                 -- optional scope
    steps = {
        { id = "pal-26-train", train = true, npc = 3352, at = { 1454, 45.1, 76.9 } },
    },
})
```

Rules:

1. **Where it applies.** To every route that uses library segments (`#route.uses > 0`, the same condition as the
   library data merge and `libraryChanged`) and whose composed steps contain the anchor. A route without the
   anchor is not an error: a Tirisfal anchor restricts an insert to the undead routes by itself. Plain routes
   (no `UseSegments`) are never touched, as today.
2. **Scope.** `class` / `race` / `faction` on the insert are the default filters of its steps (a step may
   carry its own narrower filter; a step's own key replaces the insert's key). A step whose filters can never
   match a route (`route.classes` / `route.races` / `route.faction` disjoint) is **not composed into that
   route**. So `Classes/Paladin.lua` never shows up in `orc-warrior`: no memory, no "Steps: N" error, no
   `step-no-profile`. A route without `classes` keeps the steps and the engine filters them by player, so the
   meaning is the same everywhere; pruning is only static evaluation of the same filter.
3. **Ids.** Every step of a shared insert needs an explicit id (no `<anchor>+<n>`: n would differ per route).
   The id must be unique in the library namespace: the insert registers its ids in `lib.scratch.stepById`, the
   table `Schema.AddSegment` already checks, so collisions are caught in both directions (insert vs segment
   registered earlier or later) with the existing "duplicate step id" message. A shared insert with an id error
   is rejected as a whole. Collisions with a route's own steps or per-route inserts are found at composition by
   the existing check (`Compose.lua:385-394`).
4. **Order.** In each route: shared inserts first, in registration (TOC) order, then the route's own `AddInsert`
   calls in call order. At one anchor that gives `anchor, shared..., own...` for `after` and
   `shared..., own..., anchor` for `before`. Shared steps do not advance the `<anchor>+<n>` counter, so the
   default ids of existing per-route inserts do not change when a class file adds a shared insert at the same
   anchor. Between class files and race files at a common anchor the TOC order decides: list `Classes/*.lua`
   before `Races/*.lua` (training, then riding) and state it in the plan.
5. **Anchors.** A library step, a step of another shared insert, or (per route) an own / per-route insert
   step. An anchor with a positional id is a composition error ("give the anchor step an explicit id"); this needs
   `step.autoId = true` in `Schema.AddSegment`.
6. **Copies.** Each route gets its own shallow copies of the insert steps, cached in `route.libCopies` (same
   cache and same identity guarantee as library segment steps). Templates are never mutated.
7. **Tags.** Steps carry `inserted = true`, `shared = true`, `library = <module>`, `file`, `anchor`,
   `insertSide`. `library` makes the tools treat them as library content (data in `AddLibraryData`, messages
   labelled and de-duplicated).

### 5.2 Error reporting

| Situation | When | Where reported |
|---|---|---|
| not a table, both / neither of `after` / `before`, unknown key, empty `steps`, step format errors, bad scope token | call time, once | `Registry.errors` with prefix `library:`; tools: `mod.errors` with the file |
| step without id, duplicate id (library step or other shared insert) | call time, once; the insert is rejected | same |
| a library segment registered later reuses a shared-insert step id | at that `AddLibrarySegment` | existing "duplicate step id" |
| anchor not in this route | never an error | - |
| **anchor in no route at all** (typo) | cannot be known in game (only matching routes are composed) | tools: after composing all routes of a full module load, an insert with empty `applied` is an error with its file. Not in harness runs (they compose a part on purpose). |
| positional anchor | composition | per composed route, once (`Registry:Finalize` de-duplicates per route) |
| duplicate id against a route's own / per-route insert step | composition | existing message, per route |

### 5.3 Files and functions that change (core)

* `Core/Schema.lua`
  * `Schema.AddSegment`: set `step.autoId = true` when the id is defaulted (`473`).
  * new `Schema.FiltersCanMatchRoute(filters, route)`.
  * recommended refactor: move the filter block of `NormalizeStep` (`342-364`) into
    `Schema.NormalizeFilters(def, where, errors)` and use it for the insert scope (the prototype normalizes the
    scope through a dummy step instead).
* `Core/Compose.lua`
  * `NewLibrary`: `inserts = {}`.
  * `AddInsert`: definition parsing factored into a local `parseInsert(def, keys, errors)`; behavior unchanged.
  * new `Compose.AddLibraryInsert(lib, def, source)`.
  * `Build`: build the pending list from the library's shared inserts (pruned, copied) plus `route.inserts`;
    no "unknown anchor" error for shared inserts; `applied[route.id] = true` bookkeeping; positional-anchor
    error; shared steps skip the default-id counter; `kindOf` says "shared insert".
  * header comment.
* `Core/Registry.lua`: `Registry:AddLibraryInsert(def)` (`addErrors(errors, "library")`, `libraryChanged`),
  header comment.
* `Core/Init.lua`: `public.AddLibraryInsert`; `API_MINOR = 2` with a comment line "2  core 0.4.0:
  + AddLibraryInsert (shared inserts)"; `DEFAULT_VERSION = "0.4.0"`; header comment (`8-9`).
* `FastesBoooy.toc`: `## Version: 0.4.0`.
* `.luacheckrc:132-138`: add `AddLibraryInsert = {}` to `stds.fastesboooy_route`.

Outside the core (for the tools plan; listed so nothing is missed):

* `tools/lib/route_loader.lua`: stub `api.AddLibraryInsert` (`Compose.AddLibraryInsert(lib, def, { module, file })`),
  `mod.libraryInserts`, the "applied to no route" check after the compose loop (`457-463`).
* `tools/gen_route_data.lua:119-125`: `CollectLibraryIds` must include the steps of the module's shared inserts.
  `CollectIds` (`109-115`) already skips steps with `library`, so shared steps do not land in 28 route blocks.
* `tools/lib/harness.lua:386-390`: accept a module that also registers routes (use its library part). Shared
  inserts then apply to the synthetic harness route automatically, pruned by the harness profile.
* `tools/lib/validator.lua:1912-1930`: library messages are de-duplicated per route only; with 28 routes each
  library-step message repeats 28 times. `step-no-profile` for library segment steps needs the cross-route form.
* Tests / Makefile: `tests/spec/core_sync_spec.lua:634-650` loads the real `FastesBoooy_Horde` +
  `FastesBoooy_UndeadPaladin` and expects segment `ud-01-deathknell`; `Makefile:61` `LIB = addons/FastesBoooy_Horde`.

### 5.4 Version guard in the module

`API_MINOR` goes to 2. The first file of `FastesBoooy_Guides` prints a message when
`(FastesBoooy.API_MINOR or 0) < 2`. `return` only stops that file (`docs/ROUTE_FORMAT.md:351-353`), so every
file that calls the new function should start with `if not FastesBoooy.AddLibraryInsert then return end` (one
line in the template header for `Classes/*.lua` and `Races/*.lua`). `/fb status` then prints "route API 1.2"
without further change (`Options.lua:789-791`).

### 5.5 Specs to add or change

New `tests/spec/core_shared_insert_spec.lua` (or a block in `core_compose_spec.lua`), on the strict mock through
the public API:

1. applies to every route that contains the anchor; a route without the anchor gets nothing and no error; a
   plain route is untouched;
2. scope: default filters of the steps; pruned from routes that cannot match; kept in a route without
   `classes` and filtered by the engine for the player; a step filter narrower than the scope is pruned per step;
3. order at one anchor: shared (registration order) before per-route, for `after` and `before`; the per-route
   default id `<anchor>+1` is unchanged by shared inserts at that anchor;
4. chains: shared insert at a step of another shared insert; per-route insert at a shared-insert step;
5. registration errors, each once, insert rejected: missing id, duplicate with a library step, duplicate with a
   shared-insert step, library segment registered later with the same step id, unknown key, bad class token,
   `after` + `before`, empty steps;
6. positional anchor: composition error once per route;
7. per-route copies with shared `actions`, stable identity across a recomposition (`route.dirty = true`,
   `Registry:Get`), different `index` per route;
8. `AddLibraryInsert` after login recomposes the active route (`ROUTES_CHANGED`), the cursor stays by id;
9. engine: play across shared-insert steps, `/reload` restores `cursorHintId` on a shared-insert step, cold
   start forwards transient shared-insert steps before the last done anchor;
10. login with a mixed fixture module (library segments + several routes + shared inserts): exactly one route is
    composed.

Changes to existing specs: `core_registry_spec.lua:50-51` (`API_MINOR`, version), `core_ui_spec.lua:757`
("route API 1.1"), `core_sync_spec.lua:634-650` (module paths and ids), the UI specs for the routes list if the
listing changes (5.6).

Fixture: `tests/fixtures/core/FastesBoooy_TestGuides` (TOC without the `library` declaration; library segments
for two "races", two or three routes registered from a table with a numeric `for`, shared inserts with class
and race scope). Use it in the compose spec, in `validator_compose_spec`, and in `make simulate-fixtures` /
`validate-fixtures`.

### 5.6 A module with shared segments and many routes

No core change is required for the module shape itself. What the core should still get:

* **Routes list.** `Options.refreshRoutes` and `/fb routes` must not call the composing `Registry:List()`.
  Suggested: `Registry:List(true)` returns the routes without composing; the settings panel shows
  `Registry:Matching(facts)` (normally one route) and `/fb routes` prints the matching routes first, then the
  count of the others; the tooltip line "Steps: N" only for a composed route (`not r.dirty`). A spec should assert
  that opening the panel and `/fb routes` leave the non-matching routes uncomposed.
* **Unknown library segment message** (`Compose.lua:322-323`) talks about "the library module" and
  `## Dependencies`; reword for a single module.
* **TOC order of `FastesBoooy_Guides`:** `Data.lua`, `Segments/...`, `Classes/*.lua`, `Races/*.lua`, `Route.lua`
  last. Composition is lazy, so any order is correct; with `Route.lua` last no route exists while the library is
  registered and the per-call `libraryChanged` loop is empty (it is cheap anyway: 300 library calls with 28
  routes registered = 12 ms).
* **`Route.lua` from a table:** numeric `for i = 1, #t do` loops pass the route-module luacheck std; `ipairs`
  does not (W113). The loader sandbox allows both (`route_loader.lua:53-71`). Files of one module share the
  private table `local _, ns = ...` (`route_loader.lua:331-333`, same in the client), so tables can be passed
  between files without globals.
* **Class segments between shared segments** (a whole class trip) need nothing new: register them as library
  segments and name them in the `UseSegments` list of the routes of that class.

### 5.7 Per-class reward on a shared turn-in

Two ways:

* No core change: the class file adds, `before` the shared turn-in step, a class-scoped step with the same
  `turnin = Q` and `reward = { [Q] = n }`. `GetRewardChoice` prefers a step that turns the quest in and finds the
  class step first; both steps complete together. Cost: two lines for one turn-in in the step window.
* Core change (about 15 lines): allow `reward = { [Q] = { DRUID = 2, WARRIOR = 1 } }` in `Schema.lua:302-318`
  and resolve by `self.facts.class` in `Engine:GetRewardChoice`.

Without either the automation stops at the reward window and prints "Choose a reward ... yourself"
(`Automation.lua:258-267`); nothing breaks.

### 5.8 Fallback without a core change

Class files could loop over route ids and call `AddInsert(routeId, def)` with one shared `def` table (each call
normalizes its own steps). It works today but an anchor missing in a route is an error, the steps are not tagged
as library (data and validator messages repeat per route), and every class file must know the route ids. The
shared insert is the cleaner contract for parallel class agents.

### 5.9 Notes for the parallel-agent plan (from the core's point of view)

* Step id prefixes keep files disjoint in the one library namespace: existing `h-` / `hNN-` (22-60), `ud..-`,
  `sd..-`, `pal-`, `dru-`; new ones per start zone and per class file. A collision is a load error naming both.
* A class agent's insert never enters routes of other classes (scope pruning), so validating
  `--route troll-mage` composes only the mage inserts. Format errors in another agent's half-written file are
  still load errors of the module; the loader can already skip files (`opts.skip`, `route_loader.lua:158`,
  `335`), the CLIs need an option for it.
* Anchors: explicit ids only, published per zone before the class phase.

---------------------------------------------------------------------------------------------------------------

## 6. Memory and performance

Measured on the mock (Lua 5.1 heap after a full collection; WoW's Lua 5.1 uses the same table layout, expect
+-20 %):

| Step | Heap | Time |
|---|---|---|
| core loaded | +0.56 MB | |
| `FastesBoooy_Horde`: 12 library segments, 1300 steps, data | +3.19 MB (data 0.30, raw definitions kept through `step.def` 0.55, normalized steps 2.34; ru+en notes are 0.5 of that) | 24 ms |
| `FastesBoooy_UndeadPaladin` registered, not composed: 394 own + 23 insert steps, data | +1.04 MB | 12 ms |
| `FastesBoooy_SkyborneDruid` registered, not composed: 423 + 29 steps | +1.10 MB | |
| 26 more routes registered (`RegisterRoute` + `UseSegments` only) | +0.11 MB | |
| login: select, compose the one matching route (1717 steps), `BuildSteps`, first refresh | +3.0 MB (composition about 1.2 MB of it) | 25 ms |
| composing one more route (1752 steps) | +1.23 MB | 4.7 ms |
| `Registry:List()`: composes the other 26 routes | **+32 MB** | **118 ms** |
| `BuildSteps` (1717 route steps -> 1713) | | 4.5 ms |
| `Refresh` (one evaluation, 1713 steps) | | 4.7 ms |

So: about 2.45 KB per registered library step all-in, about 0.9 KB per step copy in a composed route.

* **Only matching routes compose at login: confirmed** (1 composed, 27 dirty). It stays true as long as nothing
  calls `Registry:List()`; today the settings panel and `/fb routes` do (section 5.6).
* **Estimate for `FastesBoooy_Guides`:**
  * 22-60: 1300 steps = 3.2 MB (as today);
  * unified 15-22: ~190 steps = 0.5 MB (today 187 / 188 per route);
  * four start zones 1-15: Tirisfal 207 and Zephras 235 steps today, Durotar and Mulgore assumed ~200 each
    = ~840 steps = 2.1 MB, of which one zone (~0.5 MB) is the player's;
  * class and race files: ~600 steps = 1.5 MB, of which ~60 steps are the player's;
  * static total about 7.3 MB, about 3 MB of it for other races and classes; plus the composed route 1.3 MB,
    its data index 0.15 MB, core and engine state 1 MB: **about 10 MB**, against about 6.5 MB today with the
    library and one route module. Load time grows from ~36 ms to roughly 60-80 ms of parsing at the loading
    screen.
* **Verdict: acceptable.** 3 MB of unused tables are never touched after load (no per-frame cost; the engine
  walks only the filtered list).
* **Load on demand:** `C_AddOns.LoadAddOn`, `IsAddOnLoadOnDemand`, `IsAddOnLoadable`, `IsAddOnLoaded` exist
  (`tools/data/forever_api.lua:583-591`; there is no bare `LoadAddOn` global). The core already activates a
  module that loads after login (`core_registry_spec.lua:96-106`, `core_compose_spec.lua:304-316`). But
  load-on-demand works per addon folder (`## LoadOnDemand: 1`), and a client addon cannot load single files
  (no `loadfile` / `require`; TOC conditions are per game type, not per race). Per-race loading would mean extra
  folders, against decision 1.
* **If memory ever matters, cheaper levers inside two folders:**
  1. do not keep `step.def` in game (`Schema.lua:215`; only `core_schema_spec.lua:310` reads it): about
     -0.4 KB per step, ~1 MB;
  2. after login, drop library segments and shared inserts that no route matching the character's race /
     class can use (they cannot be used on this character): ~3 MB. Needs care with routes chosen by hand.
  Neither is needed for the first version.

---------------------------------------------------------------------------------------------------------------

## 7. What a rename touches in the core

### User-visible strings

* **Locales: no "Horde" / "Орда", no module name, no route id.** The only module-shaped text is the generic
  hint `UI_OPT_NO_ROUTES`: "Enable a route module (FastesBoooy_...) in the AddOns list"
  (`Locales/UI_enUS.lua:121`, `Locales/UI_ruRU.lua:122-123`). It can name `FastesBoooy_Guides`.
* **Route ids are shown to the player**: tooltip "ID: %s" (`Options.lua:434`, `UI_OPT_ROUTE_ID_FMT`),
  `/fb routes` lines (`Options.lua:762-763`), `/fb status` "Route: title (id)" (`Options.lua:797`),
  `/fb route <id>` argument, "Unknown route" messages. The new ids without "horde-" appear there.
* **Route titles and descriptions** come from the modules (`Route.lua` of both route modules contain "(Орда)" /
  "(Horde)" and "общий маршрут Орды" / "shared Horde route"); shown in the step-window header
  (`StepFrame.lua:619-620`), settings buttons and tooltips (`Options.lua:440-443`, `485-489`), chat
  "Route: %s" (`Engine.lua:527`).
* **Composition error text** shown by `/fb routes`: "unknown library segment '%s' (is the library module loaded
  first? list it in the TOC: ## Dependencies: FastesBoooy, <library module>)" (`Compose.lua:322-323`).
* Core TOC `## Notes` / `## Title`: generic, no change (`FastesBoooy.toc:2-4`).

### Comments only (core)

* `Core/Registry.lua:168-169` ("e.g. FastesBoooy_Horde").
* `Core/Init.lua:8-9`, `Core/Compose.lua:1-14` ("library module" / "route module" wording).
* `Core/Schema.lua:491`, `Core/Compat.lua:295-296` (example facts with "Horde").

### Outside the core (count of lines naming an old module or route id)

`README.md` 8, `docs/ARCHITECTURE.md` 5, `docs/ROUTE_FORMAT.md` 12, `docs/VALIDATION.md` 689 (generated),
`docs/routes/horde-22-60.md` 11, `docs/routes/horde-skyborne-druid.md` 11, `docs/routes/horde-undead-paladin.md`
13, `tools/README.md` 6, `tools/lib/harness.lua` 2, `tools/lib/route_loader.lua` 1, `tools/lib/validator.lua` 2,
`tools/simulate_routes.lua` 1, `Makefile` 3 (`LIB = addons/FastesBoooy_Horde`, line 61), `.luacheckrc` 1
(comment), `tests/spec/core_sync_spec.lua` 3 (loads the real modules, lines 636-638, and expects
`ud-01-deathknell`, line 642), and the three module folders themselves.

---------------------------------------------------------------------------------------------------------------

## Appendix A. Measurements and checks

### A.1 Real modules today (loader)

```
FastesBoooy_Horde          library segments   steps 1300  auto-id  936  filtered   8  bg  60  optional 128
FastesBoooy_UndeadPaladin  own segments       steps  394  auto-id  317  filtered   0  bg  29  optional  14
                           inserts            steps   23  auto-id    0                        optional  14
                           composed           steps 1717  (11 inserts, all anchored on library steps)
FastesBoooy_SkyborneDruid  own segments       steps  423  auto-id  352  filtered   0  bg  26  optional  26
                           inserts            steps   29  auto-id    0
                           composed           steps 1752  (17 inserts, all anchored on library steps)
```

Own segments: `ud-01-deathknell` 31 (1-6), `ud-02-tirisfal` 121 (6-13), `ud-03-silverpine` 55 (13-15),
`ud-04-barrens` 96 (15-18), `ud-05-stonetalon-ashenvale` 91 (18-22); `sd-01-zephras` 91 (1-9),
`sd-02-zephras` 71 (9-13), `sd-03-mulgore-silverpine` 73 (13-15), `sd-04-barrens` 101 (15-18),
`sd-05-stonetalon-ashenvale` 87 (18-22). Class steps inside own segments (to move into class files): paladin
10 `train` steps, druid 13; Zephras has 13 `reward` entries.

### A.2 Mixed module check

A scratch module (TOC without the `library` declaration; one `AddLibrarySegment`; `Route.lua` registering
`undead-warrior`, `undead-mage`, `undead-paladin` in a loop with `UseSegments`):
`lua5.1 tools/validate_routes.lua -q <dir>` -> three routes, 0 errors; `tools/gen_route_data.lua --stdout <dir>`
-> `AddLibraryData({...})` plus three empty `AddRouteData`; luacheck with std `fastesboooy_route` -> W113 on
`ipairs`.

### A.3 Prototype test output (shared inserts, appendix B)

Library segments `tf` (tf-1, tf-2, one id-less step), `du`, `sh` (sh-1, sh-org, sh-2). Shared inserts: paladin
after `tf-1` and after `sh-org`; warrior after `sh-org` (two steps, the second `race = "Orc"`); warrior after
`war-org-train`; `race = "Scourge"` before `sh-2`; warrior after `du-1`. Per-route insert of `undead-warrior`
after `sh-org` (one id-less step, `uw-own`). `*` = shared-insert step.

```
undead-paladin  tf-1 pal-tf-train* tf-2 tf:3 x3* sh-1 sh-org pal-org-train* ud-riding* sh-2
undead-warrior  tf-1 tf-2 tf:3 x3* sh-1 sh-org war-org-train* sh-org+1 uw-own war-org-quest* ud-riding* sh-2
orc-warrior     du-1 war-du-train* du-2 sh-1 sh-org war-org-train* war-org-quest* war-org-axe* sh-2
any-undead      tf-1 pal-tf-train* x1* tf-2 tf:3 x3* sh-1 sh-org pal-org-train* war-org-train* war-org-quest* ud-riding* sh-2
```

(`x3` is the deliberate positional-anchor case and reports "anchor 'tf:3' is a positional step id" in each
route; `x1` has a misspelled class token and is reported at registration; `any-undead` has no `classes`, so it
keeps all class steps for the engine to filter. In `undead-warrior` the nested `war-org-quest` lands behind the
per-route steps: the quirk described in section 2.)

Registration errors of the test:

```
library: insert after 'tf-1' step 1: an explicit id is required in a shared insert
library: insert after 'tf-1' step 1: duplicate step id 'tf-2'
library: insert after 'tf-1' step 1: duplicate step id 'pal-tf-train'
library: insert after 'tf-1': unknown class token 'PALADN'
library: segment late step 1: duplicate step id 'pal-org-train'
never applied: insert after 'nowhere' (x2)
```

---------------------------------------------------------------------------------------------------------------

## Appendix B. Prototype diff (not applied to the repository)

Tested as described at the top. It is a sketch: the scope is normalized through a dummy step (use
`Schema.NormalizeFilters` in the real change), and `Registry.lua` / `Init.lua` / loader stubs are not included.

```diff
--- addons/FastesBoooy/Core/Schema.lua
+++ addons/FastesBoooy/Core/Schema.lua
@@ -470,7 +470,10 @@
         local step = Schema.NormalizeStep(sdef, swhere, errors)
         step.segment = def.id
         step.segIndex = i
-        if not step.id then step.id = format("%s:%d", tostring(def.id), i) end
+        if not step.id then
+            step.id = format("%s:%d", tostring(def.id), i)
+            step.autoId = true -- positional id: not a stable anchor (Compose: shared inserts)
+        end
         if route.stepById[step.id] then
             addErr(errors, swhere, "duplicate step id '%s'", step.id)
         else
@@ -497,6 +500,23 @@
     return true
 end
 
+--- Can a step filter match ANY player of the route (route.classes / races / faction)?
+-- false = the step can never be shown on that route (Compose: shared inserts are not composed into it)
+function Schema.FiltersCanMatchRoute(filters, route)
+    if not filters then return true end
+    local function meets(set, allowed)
+        if not set or not allowed then return true end
+        for tok in pairs(set) do
+            if allowed[tok] then return true end
+        end
+        return false
+    end
+    if not meets(filters.class, route.classes) then return false end
+    if not meets(filters.race, route.races) then return false end
+    if filters.faction and route.faction and filters.faction ~= route.faction then return false end
+    return true
+end
+
 --- Does a route apply to the given player?
 function Schema.RouteMatches(route, player)
     if route.faction and route.faction ~= player.faction then return false end
```

```diff
--- addons/FastesBoooy/Core/Compose.lua
+++ addons/FastesBoooy/Core/Compose.lua
@@ -41,6 +41,7 @@
 local format, tinsert = string.format, table.insert
 
 local INSERT_KEYS = { after = true, before = true, steps = true }
+local SHARED_INSERT_KEYS = { after = true, before = true, steps = true, class = true, race = true, faction = true }
 
 local function addErr(errors, where, msg, ...)
     errors[#errors + 1] = where .. ": " .. format(msg, ...)
@@ -88,6 +89,7 @@
 function Compose.NewLibrary()
     return {
         segments = {}, order = {}, data = {}, revision = 0,
+        inserts = {}, -- shared inserts (AddLibraryInsert), registration order
         scratch = { segments = {}, steps = {}, stepById = {}, segmentById = {} },
     }
 end
@@ -188,40 +190,47 @@
     return n, errors
 end
 
---- Record an insert: { after = "<stepId>" | before = "<stepId>", steps = { ... } }.
--- The steps are normalized now (format errors are reported here, once).
--- @return insert record or nil, errors (strings "insert after 'x' step 2: ...")
-function Compose.AddInsert(route, def, source)
-    local Schema = ns.Schema
-    local errors = {}
+-- Parse the common part of an insert definition. @return side, anchor, where (nil + errors added on failure)
+local function parseInsert(def, keys, errors)
     if type(def) ~= "table" then
         addErr(errors, "insert", "insert definition must be a table")
-        return nil, errors
+        return nil
     end
     local side, anchor
     if def.after ~= nil and def.before ~= nil then
         addErr(errors, "insert", "give either `after` or `before`, not both")
-        return nil, errors
+        return nil
     elseif def.after ~= nil then
         side, anchor = "after", def.after
     elseif def.before ~= nil then
         side, anchor = "before", def.before
     else
         addErr(errors, "insert", "`after = \"<stepId>\"` or `before = \"<stepId>\"` is required")
-        return nil, errors
+        return nil
     end
     local where = format("insert %s '%s'", side, tostring(anchor))
     if type(anchor) ~= "string" or anchor == "" then
         addErr(errors, where, "the anchor must be a step id (string)")
-        return nil, errors
+        return nil
     end
     for k in pairs(def) do
-        if not INSERT_KEYS[k] then addErr(errors, where, "unknown key '%s'", tostring(k)) end
+        if not keys[k] then addErr(errors, where, "unknown key '%s'", tostring(k)) end
     end
     if type(def.steps) ~= "table" or #def.steps == 0 then
         addErr(errors, where, "steps must be a non-empty list")
-        return nil, errors
+        return nil
     end
+    return side, anchor, where
+end
+
+--- Record an insert: { after = "<stepId>" | before = "<stepId>", steps = { ... } }.
+-- The steps are normalized now (format errors are reported here, once).
+-- @return insert record or nil, errors (strings "insert after 'x' step 2: ...")
+function Compose.AddInsert(route, def, source)
+    local Schema = ns.Schema
+    local errors = {}
+    local side, anchor, where = parseInsert(def, INSERT_KEYS, errors)
+    if not side then return nil, errors end
     local steps = {}
     for i, sdef in ipairs(def.steps) do
         local step = Schema.NormalizeStep(sdef, format("%s step %d", where, i), errors)
@@ -238,6 +247,60 @@
     return ins, errors
 end
 
+--- Register a SHARED insert (library): { after | before = "<stepId>", class =, race =, faction =, steps = {...} }.
+-- It is applied to every route that uses library segments and whose composed steps contain the
+-- anchor. class / race / faction of the insert are the default filters of its steps; a step whose
+-- filters can never match a route (Schema.FiltersCanMatchRoute) is not composed into that route.
+-- Every step needs an explicit id, unique across the library (segments and shared inserts).
+-- The insert is all-or-nothing: with an id error nothing is recorded.
+-- @return insert record or nil, errors
+function Compose.AddLibraryInsert(lib, def, source)
+    local Schema = ns.Schema
+    local errors = {}
+    local side, anchor, where = parseInsert(def, SHARED_INSERT_KEYS, errors)
+    if not side then return nil, errors end
+    -- the insert's scope, normalized like step filters (token checks included)
+    local scope = Schema.NormalizeStep({ manual = true, class = def.class, race = def.race, faction = def.faction },
+        where, errors).filters
+    local tag = (source and source.module) or true
+    local steps, ok, seen = {}, true, {}
+    for i, sdef in ipairs(def.steps) do
+        local swhere = format("%s step %d", where, i)
+        local step = Schema.NormalizeStep(sdef, swhere, errors)
+        if not step.id then
+            addErr(errors, swhere, "an explicit id is required in a shared insert")
+            ok = false
+        elseif lib.scratch.stepById[step.id] or seen[step.id] then
+            addErr(errors, swhere, "duplicate step id '%s'", step.id)
+            ok = false
+        else
+            seen[step.id] = true
+        end
+        if scope then
+            local f = step.filters or {}
+            if f.class == nil then f.class = scope.class end
+            if f.race == nil then f.race = scope.race end
+            if f.faction == nil then f.faction = scope.faction end
+            step.filters = f
+        end
+        step.explicitId = step.id
+        step.inserted, step.shared = true, true
+        step.anchor, step.insertSide = anchor, side
+        step.insertSource = source
+        step.library = tag
+        step.file = source and source.file or nil
+        steps[#steps + 1] = step
+    end
+    if not ok then return nil, errors end
+    -- one id namespace with the library segments (Schema.AddSegment checks lib.scratch.stepById)
+    for _, step in ipairs(steps) do lib.scratch.stepById[step.id] = step end
+    local ins = { side = side, anchor = anchor, steps = steps, n = #lib.inserts + 1, source = source, shared = true,
+        scope = scope, applied = {} }
+    lib.inserts[#lib.inserts + 1] = ins
+    lib.revision = lib.revision + 1
+    return ins, errors
+end
+
 ---------------------------------------------------------------------------
 -- composition
 ---------------------------------------------------------------------------
@@ -250,7 +313,9 @@
 end
 
 local function kindOf(step)
-    if step.inserted then return format("insert %s '%s'", tostring(step.insertSide), tostring(step.anchor)) end
+    if step.inserted then
+        return format("%sinsert %s '%s'", step.shared and "shared " or "", tostring(step.insertSide), tostring(step.anchor))
+    end
     if step.library then return format("library segment %s", tostring(step.segment)) end
     return format("segment %s", tostring(step.segment))
 end
@@ -332,8 +397,36 @@
             if s.id ~= nil and home[s.id] == nil then home[s.id] = e end
         end
     end
+    -- shared inserts first (library registration order), then the route's own (call order);
+    -- only for routes that use the library, only the steps that can match the route
     local pending = {}
-    for i, ins in ipairs(route.inserts) do pending[i] = ins end
+    if lib and #route.uses > 0 then
+        local Schema = ns.Schema
+        local cache = route.libCopies
+        if not cache then
+            cache = {}
+            route.libCopies = cache
+        end
+        for _, tmpl in ipairs(lib.inserts) do
+            local steps
+            for _, t in ipairs(tmpl.steps) do
+                if Schema.FiltersCanMatchRoute(t.filters, route) then
+                    local c = cache[t]
+                    if not c then
+                        c = shallowCopy(t)
+                        cache[t] = c
+                    end
+                    steps = steps or {}
+                    steps[#steps + 1] = c
+                end
+            end
+            if steps then
+                pending[#pending + 1] = { side = tmpl.side, anchor = tmpl.anchor, steps = steps, source = tmpl.source,
+                    shared = tmpl }
+            end
+        end
+    end
+    for _, ins in ipairs(route.inserts) do pending[#pending + 1] = ins end
     local tail, count = {}, {}
     local progress = true
     while progress and #pending > 0 do
@@ -353,8 +446,17 @@
                 if ins.side == "after" then
                     pos = indexOf(e.steps, tail[ins.anchor] or anchorStep) + 1
                 end
+                if ins.shared then
+                    ins.shared.applied[route.id] = true -- (tools: an insert applied to no route is an error)
+                    if anchorStep.autoId then
+                        err(ins.source, "AddLibraryInsert: anchor '%s' is a positional step id: give the anchor step an "
+                            .. "explicit id", ins.anchor)
+                    end
+                end
                 for _, s in ipairs(ins.steps) do
-                    count[ins.anchor] = (count[ins.anchor] or 0) + 1
+                    if not ins.shared then -- shared steps have explicit ids and do not shift "<anchor>+<n>"
+                        count[ins.anchor] = (count[ins.anchor] or 0) + 1
+                    end
                     s.id = s.explicitId or format("%s+%d", ins.anchor, count[ins.anchor])
                     s.segment = anchorStep.segment
                     s.segIndex = anchorStep.segIndex
@@ -369,8 +471,11 @@
         pending = rest
     end
     for _, ins in ipairs(pending) do
-        err(ins.source, "AddInsert: unknown anchor step '%s' (insert %s '%s' ignored)", ins.anchor, ins.side,
-            ins.anchor)
+        -- a shared insert whose anchor is not in this route simply does not apply to it
+        if not ins.shared then
+            err(ins.source, "AddInsert: unknown anchor step '%s' (insert %s '%s' ignored)", ins.anchor, ins.side,
+                ins.anchor)
+        end
     end
 
     -- 3. flatten, index, ids
```
