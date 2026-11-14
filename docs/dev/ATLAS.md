# Adventure Atlas: product vision (recorded 2026-11-10)

The owner's goal for the addon, stated while the race + class guides were being planned. This file records the
decisions so that the guide work (docs/dev/PLAN.md) does not close doors; the atlas itself is the **next stage,
after the 28 guides**.

## What the addon becomes

An "adventure atlas" for players of World of Warcraft: Forever: everything useful in one place, for players
who do not live in the game and would otherwise miss much of it (the game is large and explains itself poorly).

Two big blocks:

1. **Knowledge base** — a growing collection of what there is in the game and how it works. Sections named so
   far: dungeons and raids; classes; world and services; what is new in Forever. It must be easy to add entries
   over time ("пополняемая").
2. **The adventure** — an algorithm of character development, a flow: leveling, gearing, professions, skills
   and so on. A helper that leads the player through the adventure and **always tells where to go right now**.
   The 28 leveling guides (race + class, 1-60) are the first track of this block.

## Look

Inspired by the retail Adventure Guide (Encounter Journal): one window with tabs. The **first tab is "what is
relevant for you now"** (suggestions for this character), the others are Dungeons, Raids and so on. Plus a
**minimap button** that opens the window, "like every addon has". The compact step window and the arrow of the
leveling guide stay.

## Order (decided)

1. The 28 race + class guides, levels 1-60 (docs/dev/PLAN.md). Done.
2. Then the atlas: the window, the knowledge base sections, the adventure flow beyond leveling. Started
   2026-11-14.

## Atlas stage: decisions of 2026-11-14

* **Name.** The addon is renamed from FastesBoooy to **Adventure Atlas** (core 0.5.0): folders `AdventureAtlas` and
  `AdventureAtlas_Guides`, global API table `AdventureAtlas`, SavedVariables `AdventureAtlasDB` /
  `AdventureAtlasCharDB`, slash commands `/aa` and `/atlas`. SavedVariables of FastesBoooy are not migrated (the
  engine recovers the route position from the game state; settings return to defaults). The core warns once per
  session about loaded folders of the old name. The repository is `adventure-atlas`.
* **History.** `docs/dev/PLAN.md`, `docs/dev/handover/` and `docs/dev/research/` are records of the guide stage and
  keep the old name and the paths of that time (`addons/FastesBoooy/...` is `addons/AdventureAtlas/...` now).
* **Window.** Opened by a minimap button (own code, no LibDBIcon). Two tabs for now:
  1. **"Твоё приключение"** (your adventure): the character's development path; for now leveling 1-60 plus the
     useful finds of the Forever community for fast leveling. Two modes: **calm** (play and level along the story)
     and **speedrun** (the existing race + class routes). Proposed for the calm mode: a zone and story-chain guide
     built from the DB chains (where to go at this level, which story chains are there, how far the character got),
     not a second set of hand-written step routes.
  2. **"База знаний"** (knowledge base): for now a quest list with search and filters (level, zone, class/race,
     done or not, "new in Forever"), with a quest card (start/end NPC, places, chain) and "lead me with the arrow".
* **Data.** Knowledge base quests are generated from `tools/data/forever_db.lua` into a load-on-demand data addon
  (proposed name `AdventureAtlas_Knowledge`). The DB snapshot is Horde-focused (few Alliance-only quests): the
  knowledge base is Horde-only for now. Community finds are sourced data entries (what, where, from which level,
  why useful, source); nothing unverified is shown as fact.
* **Order.** Rename -> window + minimap button -> knowledge base -> your adventure (speedrun overview, calm mode,
  finds).

## Status

* 2026-11-14, core 0.5.0: renamed. The window (UI/Atlas.lua, BasicFrameTemplateWithInset, own tab buttons) and the
  minimap button (UI/MinimapButton.lua) exist. "Your adventure" shows the active route, its progress and its
  chapters (Engine:GetChapters: segment runs, steps that are not background goals); "Knowledge base" is a
  placeholder. Escape closes the window (`UISpecialFrames`: missing from the generated API dump, confirmed in game
  and listed in tools/data/forever_api_confirmed.lua).

## What this meant for the guide work

* Packaging stays: `AdventureAtlas` (core) + `AdventureAtlas_Guides` (data). Atlas data will be further data files or
  one more data addon; the window lives in the core. Nothing in the guide phases should assume that routes are
  the only kind of content a data module registers.
* Class files (`Classes/<Class>.lua`), race files and the hand-over notes are also the raw material of the
  "Classes" and "World and services" sections: keep facts structured and sourced (trainer ids and places, class
  quest chains and what they reward, riding, weapon masters, transports), and record facts that do not fit a
  route step in `docs/dev/handover/*.md` instead of dropping them.
* Optional content the leveling path skips (dungeon quest blocks, profession quests, elite chains) is material
  for the adventure flow: note it in the hand-over rather than deleting knowledge about it.
* User-visible names carry no faction ("Орк-воин 1-60"); the same rule will hold for atlas sections.
* Everything the atlas shows must come from data that is true for Forever (DB snapshot, in-game recordings,
  cited sources). Unknown or unverified facts are marked as such, as in the guides.

## Open (to design when the atlas stage starts)

* The "relevant for you" tab: which signals (level, class, professions, quest log, gear) and which suggestions.
* Data sources for bosses, loot and professions (the DB snapshot has quests, NPCs, zones and items referenced by
  quests; not loot tables or recipes).
* How the knowledge base is replenished (data files in the repository; maybe an in-game notes layer).
