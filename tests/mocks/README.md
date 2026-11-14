# Strict WoW: Forever client mock

`tests/mocks/wow.lua` emulates the World of Warcraft: Forever client (1.60.1.70862,
`## Interface: 16001`, game type `camelot`) for the busted specs and for
`tools/simulate_routes.lua`. Pure Lua 5.1; no network, no game files, no third-party addon code.

```lua
local Mock = require("mocks.wow")          -- busted: .busted lpath has ./tests/?.lua
-- tools: package.path = "./tests/?.lua;" .. package.path

local m = Mock.new({ locale = "ruRU", player = { race = "Scourge", class = "PALADIN", mapID = 1420, x = 30, y = 71 } })
local ns = Mock.loadAddon(m, "addons/AdventureAtlas/AdventureAtlas.toc")  -- runs the files, returns the addon ns
Mock.boot(m, { "AdventureAtlas" })         -- ADDON_LOADED, PLAYER_LOGIN, PLAYER_ENTERING_WORLD(true, false)
m:DefineQuest(363, { title = "Rude Awakening", level = 1, xp = 80 })
m:DefineNPC(1568, { name = "Undertaker Mordo", starts = { 363 } })
m:TalkTo(1568)                             -- QUEST_DETAIL; the addon's automation may call AcceptQuest()
m:Advance(1)                               -- timers, tickers, OnUpdate
m:AssertClean()                            -- no script errors, no contract violations
```

## Files

| File | Content |
|---|---|
| `wow.lua` | `Mock.new`, global environment, strictness, diagnostics, `Provide*` |
| `wow/allowlist.lua` | loads `tools/data/forever_api.lua`; widget method / handler sets (with inheritance) |
| `wow/signatures.lua` | GENERATED argument / event payload specs (`gen_signatures.py` from `research/apidocs.json`) |
| `wow/luaenv.lua` | Lua 5.1 base + `string/table/math/bit/coroutine` restricted to client members + WoW extensions |
| `wow/system.lua` | clock, `C_Timer`, events, error handler, TOC / SavedVariables, slash, popups, `Settings`, `C_AddOns` |
| `wow/widgets.lua` | `CreateFrame`, widgets, templates, `UIParent`, `GameTooltip`, chat frame, fonts, UI helpers |
| `wow/world.lua` | player / units / XP, maps & world transform, waypoints, bags, spells, trainer / vendor / taxi / binder |
| `wow/quests.lua` | quest DB, `C_QuestLog`, quest dialogs, greeting, `C_GossipInfo`, NPC talk, Forever DB fallback |

## Strictness

* `m.env` (the `setfenv` environment of loaded files) contains **only** names that exist in the
  Forever client (`tools/data/forever_api.lua`). `m:Provide` / `m:ProvideAPI` / `m:ProvideNS` raise if
  a name or namespace member is not in the list. No `io`, `os`, `debug`, `require`, `dofile`,
  `loadfile`, `package`; `date` / `time` / `difftime` are globals (deterministic mock clock).
* Global **absent from Forever** (`GetQuestLogTitle`, `GetItemCount`, `IsQuestFlaggedCompleted`,
  `InterfaceOptions_AddCategory`...): reads `nil` like the client, recorded in `m.absent`
  (`m:AbsentGlobals()`); same for `C_X.Missing` (`"C_X.Missing"` key).
* Global that **exists in Forever but is not implemented** by the mock: raises and is recorded in
  `m.violations` / `m.unmocked` (`Mock.new{ unmocked = "nil" }` reads nil instead). Extend the mock
  (or `m:ProvideAPI(name, fn)` in a spec) when this happens.
* Documented API functions check their arguments against the API documentation
  (number / string / unit token / table / function, required vs nilable); misuse raises and is
  recorded in `m.violations` even when the caller wraps it in `pcall`.
* Widgets have exactly the methods of their widget type (`widgetMethods` along `widgetInherits`).
  Unknown keys read `nil` (so `if f.SetBackdrop then` works) and calling one raises
  `attempt to call method 'X' (a nil value)` (recorded in `m.widgetMisses`). `f.Show()` raises.
  Raise as well: unknown frame type, unknown template or template of another widget type,
  `SetScript` with a handler the type does not have, `RegisterEvent` of an unknown event
  (also a warning), invalid anchor point / relative region / self anchor, frame strata, draw layer,
  justification, blend mode, orientation, tooltip anchor, unknown font object.
* `m:Fire` validates the event name and documented payload types.
* **Protected frames** (minimal model): a frame created from `SecureActionButtonTemplate` is
  explicitly protected; a frame that has a protected descendant, or that a protected frame is
  anchored to, is implicitly protected (`IsProtected()` → `true, explicit`; `UIParent` /
  `WorldFrame` left out). While `m.player.inCombat` (`EnterCombat`; `PLAYER_REGEN_DISABLED` fires
  before the lockdown starts), `Show/Hide/SetShown`, anchors, size, scale, `SetParent`,
  `StartMoving`, `SetAttribute`, `EnableMouse`, strata / level, `RegisterForClicks` on a protected
  frame record an `ADDON_ACTION_BLOCKED` violation and raise (`Mock.RESTRICTED_METHODS`).
  The template's `OnClick` runs the secure action of the `type` / `typeN` attribute on the
  press or the release (`m.actionButtonUseKeyDown`, default `true` like the client CVar) and
  records `{ "SecureAction", type, value, mouseButton }` in `m.actions`; `m:Click(button)` sends
  the press and/or the release registered with `RegisterForClicks` (one release without it).
* Errors that reach the error handler (script errors, `C_Timer` callbacks, `geterrorhandler()(...)`)
  are recorded in `m.errors`; the outermost mock call (`m:Fire`, `m:Advance`, helpers, `Mock.boot`)
  then raises with all new errors and violations (`Mock.new{ raiseErrors = false }` to only record).
* Diagnostics: `m.errors`, `m.violations`, `m.warnings`, `m.unmocked`, `m.absent`, `m.widgetMisses`,
  `m.unmodeledTemplates`, `m:Diagnostics()` (summary), `m:AssertClean()`, `m:ClearDiagnostics()`,
  `m:AddonGlobals()` (globals written by loaded code), `m.eventLog` / `m:Events(name)`,
  `m.actions` / `m:Actions(name)` (player-intent calls: `AcceptQuest`, `GetQuestReward`,
  `C_GossipInfo.Select*`, `TakeTaxiNode`, `BuyTrainerService`, `SetUserWaypoint`, `Slash`...).

## `Mock.new(opts)`

`locale` (`"enUS"`), `player` = { `name, realm, race` (raceFile), `raceID, class` (classFile), `classID,
faction, sex, level, xp, rested, money, mapID, x, y` (0-100), `facing` (rad), `onTaxi, inCombat,
shift, ctrl, alt, guid` } (raceID / classID / faction derived; Skyborne = 95 Alliance / 96 Horde),
`unmocked`, `raiseErrors`, `frameTime` (0.05 s), `time` (initial `GetTime()`, 1000), `epoch`,
`projectID` (`WOW_PROJECT_ID`, 18 = `WOW_PROJECT_CAMELOT`), `build`, `maxLevel` (60), `levelLag` (true),
`maxQuests` (40), `questLogHeaders` (true), `maps`, `bags` ({[itemID]=n}), `spells`, `bind`,
`completedQuests`, `savedVariables`, `serverDelay` (0), `secretUnits`, `restrictions`, `areaNames`,
`backpackSlots` (16).

## Addons

* `Mock.parseToc(path)` → `{ meta, metaLower, files, dir }` (`##` directives, comments, CRLF,
  backslashes, `[AllowLoadGameType ...]` / `[ExcludeLoadGameType ...]`, `[Family]`/`[Game]`).
* `Mock.loadAddon(m, tocPath [, addonName [, opts]])` runs every file with `loadfile` + `setfenv(m.env)` and
  `(addonName, ns)` varargs; returns `ns`. XML files raise. `## LoadSavedVariablesFirst: 1` honoured.
  `opts.skip = { ["Classes/Mage.lua"] = true }` leaves TOC files out (the file filter of the offline tools,
  `--skip` / `--keep`); `m.addons[name].skipped` lists them.
* `Mock.boot(m, addons [, { reload = true }])`: per addon (name of a loaded addon, or
  `{ toc = path, name = ... }` to load now) apply SavedVariables + `ADDON_LOADED(name, false)`; then
  `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD(not reload, reload)`, `QUEST_LOG_UPDATE`, `BAG_UPDATE_DELAYED`.
* `m:ExportSavedVariables()` → pass as `Mock.new{ savedVariables = ... }` to simulate `/reload`
  (a cold restart on Forever may lose SavedVariables: test with no `savedVariables`).
* `m:RunSlash("/aa xp")`, `m:RegisterAddOn(name, meta)`, `C_AddOns.GetAddOnMetadata/IsAddOnLoaded/...`.

## Simulation helpers (methods of `m`)

* **Time / events**: `Advance(seconds)` (frames of `frameTime`; `Advance(0)` = one frame),
  `Now()`, `Fire(event, ...)`, `Events(name)`.
* **Player**: `MoveTo([mapID,] x, y)`, `WalkTo(x, y [, yardsPerSec, maxSeconds])`, `SetFacing(rad)`,
  `FaceTowards(x, y)`, `SetSubZone`, `EnterInstance` / `LeaveInstance`, `GiveXP(n [, {kill=true}])`,
  `SetLevel(n)`, `SetRested`, `SetMoney`, `EnterCombat` / `LeaveCombat`, `SetModifier(key, down)` /
  `SetShift(down)`, `SetTarget(npcID|nil)`, `LearnSpell(id)`, `SetSecretUnits(on)`, `MakeSecret()`,
  `SetRestriction(type, on)`.
* **Maps**: built-in Forever uiMapIDs (Tirisfal 1420, Undercity 1458, Silverpine 1421, Durotar 1411,
  Barrens 1413, Mulgore 1412, Orgrimmar 1454, Zephras Isle 2521 (no world position), ...).
  `DefineMap(id, { name, mapType, parent, continent, width, height, top, left, noWorld,
  canWaypoint })`, `WorldPos(mapID, x, y)`, `Distance(...)`. Default geometry is **synthetic**:
  1 map unit (1 %) = 10 yards, zones laid out on a grid per continent.
  World axes follow the client: worldX = north, worldY = west; facing 0 = north, counter-clockwise.
* **Items**: `DefineItem(id, { name, icon, quality, cached })`, `AddItem(id, n)`, `RemoveItem`,
  `GetItemCount`. Uncached items load one frame after `C_Item.RequestLoadItemDataByID`.
* **Quests**: `DefineQuest(id, { title, level, reqLevel, xp, money, zone, objectives = { { text,
  required, type, itemID } }, choices, rewards, pre, preAny, exclusive, races, classes, autoAccept,
  areaTrigger, pvp, moneyRequired, uncached })` (unknown ids get generic data); `AddQuestToLog`,
  `ProgressObjective(id, i, n)`, `CompleteObjectives`, `SetObjective(id, i, { fulfilled, finished })`,
  `SetQuestComplete`, `FailQuest`, `TurnInQuest(id, choice)`, `AbandonQuest`, `SetCompletedQuests`,
  `IsOnQuest`, `IsQuestCompleted`, `QuestLogIDs`, `CanTakeQuest`, `QuestRewardXP`; `Mock.QuestXP`
  (Classic grey penalty + rounding), `Mock.XP_TO_LEVEL`. Gray (trivial) quests: one green range
  `m:TrivialRange([level])` (Classic gray-level rule, = `tools/lib/fbdb.lua` `DB.GreyLevel`) behind
  `C_QuestLog.GetTrivialRange`, `UnitQuestTrivialLevelRange`, `C_QuestLog.IsQuestTrivial` and the
  gossip / greeting `isTrivial` flags: trivial when `playerLevel - questLevel > range` (level <= 0
  never). `HaveQuestData(id)` is true for defined, cached quests only.
* **Dialogs / NPCs**: `OpenQuestDetail(id, { npcID, startItem })`, `OpenQuestProgress(id)`,
  `OpenQuestComplete(id, numChoices)`, `OpenGossip({ available, active, options, text }, npcID)`,
  `OpenGreeting({ available, active }, npcID)`, `DefineNPC(id, { name, level, starts, ends, options,
  greeting })`, `TalkTo(npcID)`, `TalkToObject(objectID)`, `OfferSharedQuest(id)`,
  `CloseInteraction()`. Gossip options: `{ name, type = "taxi"|"trainer"|"vendor"|"binder"|"close",
  onSelect = fn(m) }`.
* **Services**: `OpenTrainer({ services = { { name, rank, category, spellID, cost } } }, npcID)` /
  `CloseTrainer`, `OpenMerchant` / `CloseMerchant`, `OpenTaxi(nodes, npcID)` (nodes: `name, x, y`
  (0-1), `state`, `mapID, destX, destY, flightTime`) / `CloseTaxi` / `Land`,
  `OpenBinder(name, npcID, mapID, x, y)` / `ConfirmBinder`, `SetBindLocation`, `UseHearthstone`.
* **Forever DB**: `m:UseForeverDB(dofile("tools/data/forever_db.lua")[, { routeCompletes = {[id] = true} }])`
  makes undefined quests, NPCs, objects and items come from the snapshot (objectives,
  prerequisites, race/class masks). `objectives.event` (exploration / escort) becomes an `"event"`
  objective that stays incomplete until fulfilled (`CompleteObjectives` / `ProgressObjective`);
  a quest listed in `routeCompletes` (the route has a `complete` step for it) without any DB
  objective gets one placeholder `"event"` objective; other objective-less quests are complete
  on accept (deliveries). `tools/simulate_routes.lua` passes the route's `complete` quests.
* **UI**: `Click(button)`, `Enter(region)` / `Leave`, `TypeText(editBox, s)`, `DragSlider(s, v)`,
  `TooltipLines()`, `VisibleTexts([root])`, `FindWidgets(pred)`, `WidgetState(w)`,
  `IsWidgetVisible(w)`, `PopupClick(which, "button1")`, `PopupVisible(which)`, `m.chat`,
  `m.settingsOpened`, `m.userWaypoint`.

## Event order (deterministic)

* Accept: `QUEST_ACCEPTED(id)`, `QUEST_LOG_UPDATE`, `UNIT_QUEST_LOG_CHANGED("player")`,
  `QUEST_WATCH_LIST_CHANGED(id, true)`, `QUEST_FINISHED`, then back to the NPC if it still offers
  something (`TalkTo` NPCs recompute their offers).
* Turn in: `QUEST_TURNED_IN(id, xp, money)`, `QUEST_REMOVED(id, false)`, `QUEST_LOG_UPDATE`,
  `UNIT_QUEST_LOG_CHANGED`, bag / money / XP events, `QUEST_FINISHED`, back to the NPC.
  `opts.serverDelay > 0`: the dialog closes first, server events follow after the delay.
* Level up: `PLAYER_LEVEL_UP(new, ...)` (with `UnitLevel("player")` still returning the old level,
  like the client), `PLAYER_LEVEL_CHANGED(old, new, true)`, then `PLAYER_XP_UPDATE("player")`.
* Interactions: `PLAYER_INTERACTION_MANAGER_FRAME_SHOW(type)` before `GOSSIP_SHOW` / `QUEST_*` /
  `TRAINER_SHOW` / `MERCHANT_SHOW` / `TAXIMAP_OPENED(1)` / `CONFIRM_BINDER`; `..._HIDE` after the close event.
  Switching gossip → quest frame fires `GOSSIP_CLOSED(true)`.
* Starting an interaction with another NPC closes the open one first (its close events fire).
* `PLAYER_REGEN_DISABLED` fires before `InCombatLockdown()` becomes true.

## Modelling assumptions (not verifiable offline)

* NPC with one offer and no gossip options opens the quest dialog directly (cmangos rule); an active
  quest that is complete and has no item / money requirement goes straight to `QUEST_COMPLETE`.
* Quest log headers come first per zone (`GetInfo(i).isHeader`, header `questID` = 0, also for
  `GetQuestIDForLogIndex`); `GetQuestObjectives` returns `nil` for quests not in the log; objective
  text is `"n/r text"`; quests without objectives are complete.
* Gossip option `orderIndex` is 0-based. `GetQuestReward` with a missing choice is ignored (warning).
* Modeled templates (children / scripts): `BackdropTemplate`, `TooltipBackdropTemplate`,
  `UIPanelButtonTemplate` (+`NoTooltip`; `Text`, OnEnter tooltip), `UIPanelCloseButton*`,
  `UICheckButtonTemplate`, `InterfaceOptionsCheckButtonTemplate`, `UISliderTemplate(WithLabels)`,
  `OptionsSliderTemplate`, `UIPanelScrollFrameTemplate`, `UIPanelScrollBarTemplate`,
  `ScrollFrameTemplate`, `InputBoxTemplate`, `BasicFrameTemplate(WithInset)`. Other existing
  templates are accepted and add nothing (`m.unmodeledTemplates`).
* Widget methods without a specific implementation are generic: `SetX(...)` stores, `GetX()` /
  `IsX()` return it, `EnableX` / `DisableX` toggle `IsXEnabled`, `Has*/Can*` return false.
* The KethoDoc dump lists `Region` as inheriting itself; `tools/gen_forever_api.py` writes `ScriptRegion`
  (client reality) and the mock keeps the same replacement as a safety net.
* Secret values only appear through `SetSecretUnits(true)` (non-player unit GUID / name / level) or
  `MakeSecret()`; `issecretvalue` is true for them and any operation on them raises.

## Extending / regenerating

* Missing client API: implement it in the matching `wow/*.lua` part with `m:ProvideAPI` /
  `m:ProvideNS` (the allowlist assertion keeps it honest), or provide it ad hoc in a spec.
* `python3 -I tests/mocks/gen_signatures.py --apidocs research/apidocs.json` regenerates
  `wow/signatures.lua` (the API documentation dump is read as data only).
