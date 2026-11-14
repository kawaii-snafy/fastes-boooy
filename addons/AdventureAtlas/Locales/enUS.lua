-- AdventureAtlas / Locales / enUS.lua -- core strings (UI strings: Locales/UI_enUS.lua)
local _, ns = ...
ns.Locales = ns.Locales or {}
ns.Locales.enUS = ns.Locales.enUS or {}
local L = ns.Locales.enUS

-- step lines (Core/Steps.lua: Steps:Describe)
L.STEP_ACCEPT = "Accept: %s"
L.STEP_TURNIN = "Turn in: %s"
L.STEP_COMPLETE = "Complete: %s"
L.STEP_COMPLETE_OBJECTIVES = "Complete: %s (objectives %s)"
L.STEP_ABANDON = "Abandon: %s"
L.STEP_COLLECT = "Collect %s: %d/%d"
L.STEP_LEVEL = "Reach level %d"
L.STEP_LEVEL_FRAC = "Reach level %d and %d%% of the bar"
L.STEP_GO = "Go to %s %.1f, %.1f"
L.STEP_GO_NOZONE = "Go to %.1f, %.1f"
L.STEP_TRAIN = "Visit your class trainer"
L.STEP_FP = "Get the flight path: %s"
L.STEP_FLY = "Fly to %s"
L.STEP_SETHEARTH = "Set your hearthstone: %s"
L.STEP_HEARTH = "Hearth to %s"
-- hints after a level sync (Engine:FlightPathPending / Engine:HearthBindMismatch)
L.STEP_FLY_NO_FP = "The flight path %s was skipped by the level sync: travel there yourself "
    .. "(talk to its flight master on arrival)"
L.STEP_HEARTH_BIND = "Your hearthstone is set to %s, not %s: travel there yourself"
L.STEP_VENDOR = "Visit a vendor (sell / restock)"
L.STEP_MANUAL = "Press \"Forward\" when done"
L.STEP_SPELLS = "Learn: %s"
L.STEP_OBJECTIVE = "%s"
L.STEP_OBJECTIVE_PENDING = "Objective %d"
L.QUEST_FALLBACK = "Quest #%d"
L.ITEM_FALLBACK = "Item #%d"
L.UNKNOWN_PLACE = "?"

-- chat messages
L.MSG_LOADED = "v%s loaded."
L.MSG_ROUTE_ERRORS = "%d route format error(s). First: %s"
L.MSG_NO_ROUTE = "No route matches this character."
L.MSG_ROUTE_SELECTED = "Route: %s"
L.MSG_ROUTE_FINISHED = "Route finished. Well done!"
L.MSG_UNKNOWN_ROUTE = "Unknown route: %s"
L.MSG_CHOOSE_REWARD = "Choose a reward for \"%s\" yourself."
L.MSG_QUEST_LOG_FULL = "Quest log is full (%d/%d): \"%s\" was not accepted."
L.MSG_PVP_QUEST = "\"%s\" flags you for PvP: accept it manually."
L.MSG_QUEST_COSTS_MONEY = "\"%s\" requires money: complete it manually."
L.MSG_XP_RECORDED = "Quest %d: %d XP recorded."
L.MSG_RESET = "Route progress reset (game state is kept)."
L.MSG_QUEST_GIVEN_UP = "Quest \"%s\" abandoned: its steps are skipped (/aa prev to go back)."
-- level sync (Core/Engine.lua: ApplySync / UndoSync); %d = player level, then the segment titles
L.MSG_SYNC_APPLIED = "Level sync: you are level %d -- continuing at \"%s\" (\"%s\" is below your level). Undo: /aa sync undo"
L.MSG_SYNC_AUTO = "Level sync (automatic): level %d -- continuing at \"%s\" (\"%s\" is below your level). Undo: /aa sync undo"
L.MSG_SYNC_UNDONE = "Level sync undone: the route continues where it was before."
-- %d = number of quests, %s = their titles
L.MSG_SYNC_DROPPED = "%d quest(s) of the skipped part stay in your log (%s): the guide no longer leads to them "
    .. "-- finish them on your own or abandon them."
