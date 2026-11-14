-- AdventureAtlas / Core / Compat.lua
--
-- The ONLY place in the addon that calls Blizzard quest / map / item / taxi /
-- unit / quest-dialog / gossip / waypoint APIs (WoW: Forever, Interface 16001,
-- modern C_QuestLog / C_GossipInfo / C_Map / C_SuperTrack API).
--
-- Rules:
--   * every function returns normalized values (booleans are real booleans,
--     missing data is nil / 0 / {}), never raises on missing data;
--   * values that may be "secret" (issecretvalue) are treated as unavailable;
--   * API globals are looked up at call time (not cached in locals) so test
--     mocks can replace them.
-- Map coordinates exchanged with the rest of the addon are uiMapID + percent
-- (0..100), like route `at = {uiMapID, x, y}`.

local _, ns = ...

local Compat = {}
ns.Compat = Compat

local type, pairs, ipairs, select, tonumber, pcall = type, pairs, ipairs, select, tonumber, pcall
local sqrt, atan2, abs, pi, floor = math.sqrt, math.atan2, math.abs, math.pi, math.floor
local sort = table.sort

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------

--- true if v is a secret value (Midnight-style restriction system).
local function isSecret(v)
    if issecretvalue then
        return issecretvalue(v) and true or false
    end
    return false
end
Compat.IsSecret = isSecret

-- v, or nil when v is secret
local function pub(v)
    if isSecret(v) then return nil end
    return v
end

local function pubNumber(v)
    v = pub(v)
    if type(v) ~= "number" then return nil end
    return v
end

local function pubBool(v)
    if isSecret(v) then return false end
    return v and true or false
end

local function tryResults(ok, ...)
    if not ok then
        ns.Debug("API error:", (...))
        return
    end
    return ...
end

-- pcall wrapper returning the function results, or nothing on error / missing API
local function try(fn, ...)
    if type(fn) ~= "function" then return end
    return tryResults(pcall(fn, ...))
end
Compat.Try = try

local function vecXY(v)
    if type(v) ~= "table" or isSecret(v) then return nil end
    local x, y = v.x, v.y
    if (x == nil or y == nil) and type(v.GetXY) == "function" then
        x, y = v:GetXY()
    end
    if isSecret(x) or isSecret(y) or type(x) ~= "number" or type(y) ~= "number" then
        return nil
    end
    return x, y
end

---------------------------------------------------------------------------
-- client detection
---------------------------------------------------------------------------

do
    local iface
    if GetBuildInfo then iface = select(4, GetBuildInfo()) end
    Compat.interface = type(iface) == "number" and iface or nil
    local camelot = WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT
    Compat.IsForever = camelot or (Compat.interface ~= nil and Compat.interface >= 16000 and Compat.interface < 17000)
end

--- Is the addon `name` loaded (C_AddOns.IsAddOnLoaded)? false when the client does not know it.
function Compat.IsAddOnLoaded(name)
    return pubBool((try(C_AddOns and C_AddOns.IsAddOnLoaded, name)))
end

---------------------------------------------------------------------------
-- session state (filled by events below)
---------------------------------------------------------------------------

local session = {
    turnedIn = {},     -- [questID] = true: QUEST_TURNED_IN seen this session
    levelHint = nil,   -- level from PLAYER_LEVEL_UP payload (UnitLevel may lag a frame)
}
Compat.session = session

---------------------------------------------------------------------------
-- quests
---------------------------------------------------------------------------

--- Is the quest in the quest log?
function Compat.IsOnQuest(questID)
    if type(questID) ~= "number" then return false end
    local v = try(C_QuestLog.IsOnQuest, questID)
    if isSecret(v) then return false end
    if v == nil then
        v = try(C_QuestLog.GetLogIndexForQuestID, questID)
        return pubNumber(v) ~= nil
    end
    return v and true or false
end

--- Has the quest been turned in (account history flag / this session)?
function Compat.IsQuestTurnedIn(questID)
    if type(questID) ~= "number" then return false end
    if session.turnedIn[questID] then return true end
    return pubBool(try(C_QuestLog.IsQuestFlaggedCompleted, questID))
end

--- In the log, objectives complete / ready for turn-in, and not failed.
function Compat.IsQuestComplete(questID)
    if not Compat.IsOnQuest(questID) then return false end
    if pubBool(try(C_QuestLog.IsFailed, questID)) then return false end
    if pubBool(try(C_QuestLog.ReadyForTurnIn, questID)) then return true end
    return pubBool(try(C_QuestLog.IsComplete, questID))
end

--- Has the quest failed (timed / escort)?
function Compat.IsQuestFailed(questID)
    if type(questID) ~= "number" then return false end
    return pubBool(try(C_QuestLog.IsFailed, questID))
end

local EMPTY_OBJ = {}

--- Objectives of a quest in the log.
-- @return array of { text, finished, numFulfilled, numRequired, type } (empty when unknown)
function Compat.GetObjectives(questID)
    local out = {}
    if type(questID) ~= "number" then return out end
    local list = try(C_QuestLog.GetQuestObjectives, questID)
    if type(list) ~= "table" or isSecret(list) then return out end
    for i, o in ipairs(list) do
        if type(o) ~= "table" then o = EMPTY_OBJ end
        local text = o.text
        if isSecret(text) or type(text) ~= "string" then text = "" end
        out[i] = {
            text = text,
            finished = pubBool(o.finished),
            numFulfilled = pubNumber(o.numFulfilled) or 0,
            numRequired = pubNumber(o.numRequired) or 0,
            type = pub(o.type),
        }
    end
    return out
end

--- Is objective #index of the quest finished? (true when the quest is turned in or complete)
function Compat.ObjectiveDone(questID, index)
    if Compat.IsQuestTurnedIn(questID) then return true end
    if not Compat.IsOnQuest(questID) then return false end
    local o = Compat.GetObjectives(questID)[index]
    if o then return o.finished end
    return Compat.IsQuestComplete(questID)
end

local titleCache, titleRequested = {}, {}

--- Localized quest title if the client has it cached, without asking for it (searches over many quests).
function Compat.GetCachedQuestTitle(questID)
    if type(questID) ~= "number" then return nil end
    local t = titleCache[questID]
    if t then return t end
    t = try(C_QuestLog.GetTitleForQuestID, questID)
    if not isSecret(t) and type(t) == "string" and t ~= "" then
        titleCache[questID] = t
        return t
    end
    return nil
end

--- Localized quest title from the client cache. Requests the data when it is
-- not cached yet; ns:Fire("QUEST_DATA_LOADED", questID, success) follows.
-- @return title or nil
function Compat.GetQuestTitle(questID)
    if type(questID) ~= "number" then return nil end
    local t = titleCache[questID]
    if t then return t end
    t = try(C_QuestLog.GetTitleForQuestID, questID)
    if not isSecret(t) and type(t) == "string" and t ~= "" then
        titleCache[questID] = t
        return t
    end
    local req = titleRequested[questID]
    local now = GetTime and GetTime() or 0
    if not req or (now - req) > 60 then
        titleRequested[questID] = now
        try(C_QuestLog.RequestLoadQuestByID, questID)
    end
    return nil
end

--- Quests currently in the log (headers/hidden entries skipped).
-- @return array of { questID, title, level, isComplete }
function Compat.GetQuestLogQuests()
    local out = {}
    local numEntries = pubNumber(try(C_QuestLog.GetNumQuestLogEntries)) or 0
    for i = 1, numEntries do
        local info = try(C_QuestLog.GetInfo, i)
        if type(info) == "table" and not info.isHeader and not info.isHidden then
            local q = pubNumber(info.questID)
            if q and q > 0 then
                local title = pub(info.title)
                if type(title) == "string" and title ~= "" then titleCache[q] = title end
                out[#out + 1] = {
                    questID = q, title = title, level = pubNumber(info.level),
                    isComplete = Compat.IsQuestComplete(q),
                }
            end
        end
    end
    return out
end

--- Number of quests in the log (headers excluded).
function Compat.GetNumQuestsInLog()
    local _, numQuests = try(C_QuestLog.GetNumQuestLogEntries)
    numQuests = pubNumber(numQuests)
    if numQuests then return numQuests end
    return #Compat.GetQuestLogQuests()
end

--- Quest log capacity (40 on Forever).
function Compat.GetMaxQuests()
    local n = pubNumber(try(C_QuestLog.GetMaxNumQuestsCanAccept))
    if n and n > 0 then return n end
    return 40
end

---------------------------------------------------------------------------
-- quest difficulty: gray (trivial) quests
---------------------------------------------------------------------------

--- Classic gray-level rule (tools/lib/fbdb.lua DB.GreyLevel): green range of a player of
-- `level`, i.e. a quest is gray when level - questLevel > range. Gray level: 0 up to 5,
-- level - floor(level / 10) - 5 up to 39, level - floor(level / 5) - 1 up to 59, 48 at 60.
function Compat.FallbackTrivialRange(level)
    level = tonumber(level) or 1
    local grey
    if level <= 5 then grey = 0
    elseif level <= 39 then grey = level - floor(level / 10) - 5
    elseif level <= 59 then grey = level - floor(level / 5) - 1
    else grey = 48 end
    return level - grey - 1
end

--- Green range of the player (quests more than `range` levels below the player are gray):
-- C_QuestLog.GetTrivialRange() (Forever: the Camelot nameplate colours use it; Questie calls it the
-- inclusive green offset), else UnitQuestTrivialLevelRange("player") (FrameXML
-- DifficultyUtil.GetRelativeDifficultyColor), else Compat.FallbackTrivialRange(level).
function Compat.TrivialRange(level)
    local r = pubNumber(try(C_QuestLog.GetTrivialRange))
    if r and r >= 0 then return r end
    r = pubNumber(try(UnitQuestTrivialLevelRange, "player"))
    if r and r >= 0 then return r end
    return Compat.FallbackTrivialRange(level or Compat.PlayerFacts().level)
end

--- Is the quest gray (trivial) for the player, like the client colours it? The client's own
-- answer C_QuestLog.IsQuestTrivial(questID) when it has the quest's data (HaveQuestData: for an
-- uncached quest the difficulty APIs may misreport -- Questie notes the same on Forever); else
-- the FrameXML rule (GetRelativeDifficultyColor: trivial when playerLevel - questLevel > green
-- range) with `questLevel` (route data questMeta) and `range` (default Compat.TrivialRange).
-- Unknown quest level, or a level <= 0 (scales with the player): not gray.
-- @param playerLevel default: Compat.PlayerFacts().level
function Compat.IsQuestGray(questID, questLevel, playerLevel, range)
    if type(questID) ~= "number" then return false end
    if pubBool(try(HaveQuestData, questID)) then
        local v = try(C_QuestLog.IsQuestTrivial, questID)
        if not isSecret(v) and type(v) == "boolean" then return v end
    end
    if type(questLevel) ~= "number" or questLevel <= 0 then return false end
    playerLevel = tonumber(playerLevel) or Compat.PlayerFacts().level
    range = tonumber(range) or Compat.TrivialRange(playerLevel)
    return playerLevel - questLevel > range
end

--- XP the quest in the log would give right now (0 when unknown).
function Compat.GetQuestLogRewardXP(questID)
    if type(questID) ~= "number" or not GetQuestLogRewardXP then return 0 end
    return pubNumber(try(GetQuestLogRewardXP, questID)) or 0
end

---------------------------------------------------------------------------
-- player
---------------------------------------------------------------------------

local identity

--- Player facts used for route selection and step evaluation.
-- @return { race (raceFile, e.g. "Scourge"/"Skyborne"), raceID, class (classFile), classID,
--           faction ("Horde"/"Alliance"), level, xp, xpMax, rested, maxLevel, name, guid }
function Compat.PlayerFacts()
    if not identity then
        local _, raceFile, raceID = try(UnitRace, "player")
        local _, classFile, classID = try(UnitClass, "player")
        local faction = try(UnitFactionGroup, "player")
        local name = try(UnitName, "player")
        local guid = try(UnitGUID, "player")
        local id = {
            race = pub(raceFile), raceID = pubNumber(raceID),
            class = pub(classFile), classID = pubNumber(classID),
            faction = pub(faction), name = pub(name), guid = pub(guid),
        }
        if not (id.race and id.class and id.faction) then
            return Compat.FillDynamicFacts(id) -- incomplete: do not cache
        end
        identity = id
    end
    local facts = {}
    for k, v in pairs(identity) do facts[k] = v end
    return Compat.FillDynamicFacts(facts)
end

function Compat.FillDynamicFacts(facts)
    local level = pubNumber(try(UnitLevel, "player")) or 1
    local hint = session.levelHint
    if hint then
        if hint > level then level = hint else session.levelHint = nil end
    end
    facts.level = level
    facts.xp = pubNumber(try(UnitXP, "player")) or 0
    facts.xpMax = pubNumber(try(UnitXPMax, "player")) or 0
    facts.rested = pubNumber(try(GetXPExhaustion)) or 0
    facts.maxLevel = pubNumber(try(GetMaxPlayerLevel)) or 60
    return facts
end

--- Forget the cached race/class/faction (tests, faction change).
function Compat.ResetIdentity()
    identity = nil
end

---------------------------------------------------------------------------
-- position / map
---------------------------------------------------------------------------

--- Player position on the best map for the player.
-- @return uiMapID, x, y (percent 0..100) or nil
function Compat.GetPlayerMapPosition()
    local mapID = pubNumber(try(C_Map.GetBestMapForUnit, "player"))
    if not mapID then return nil end
    local x, y = vecXY(try(C_Map.GetPlayerMapPosition, mapID, "player"))
    if not x then return nil end
    return mapID, x * 100, y * 100
end

local degenerate = {} -- [uiMapID] = true when the map has no world transform

local function rawWorldPos(mapID, fx, fy)
    if not CreateVector2D then return nil end
    local cont, vec = try(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(fx, fy))
    cont = pubNumber(cont)
    local wx, wy = vecXY(vec)
    if not cont or not wx then return nil end
    return cont, wx, wy
end

local function isDegenerate(mapID)
    local d = degenerate[mapID]
    if d ~= nil then return d end
    local c1, x1, y1 = rawWorldPos(mapID, 0, 0)
    local c2, x2, y2 = rawWorldPos(mapID, 0.5, 0.5)
    if not c1 or not c2 then
        d = true
    else
        d = (abs(x1 - x2) + abs(y1 - y2)) < 0.01
    end
    degenerate[mapID] = d
    return d
end

--- World position of a map point.
-- World X points north, world Y points west (yards), as UnitPosition returns.
-- @return continentID, worldX, worldY or nil (maps without world transform -> nil)
function Compat.WorldPosFromMap(mapID, x, y)
    if type(mapID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then return nil end
    if isDegenerate(mapID) then return nil end
    return rawWorldPos(mapID, x / 100, y / 100)
end

--- Player world position.
-- @return instanceID (continent), worldX (north), worldY (west) or nil
function Compat.PlayerWorldPos()
    local wx, wy, _, inst = try(UnitPosition, "player")
    wx, wy, inst = pubNumber(wx), pubNumber(wy), pubNumber(inst)
    if wx and wy and inst then
        return inst, wx, wy
    end
    local m, x, y = Compat.GetPlayerMapPosition()
    if m then
        return Compat.WorldPosFromMap(m, x, y)
    end
    return nil
end

--- Player facing in radians (0 = north, counter-clockwise), nil when unavailable.
function Compat.Facing()
    return pubNumber(try(GetPlayerFacing))
end

-- nominal zone size used when a map has neither world transform nor size
Compat.NOMINAL_MAP_SIZE = { 2000, 1333 }

local sizeCache = {}
local function mapSize(mapID)
    local s = sizeCache[mapID]
    if s == nil then
        local w, h = try(C_Map.GetMapWorldSize, mapID)
        w, h = pubNumber(w), pubNumber(h)
        if w and h and w > 0 and h > 0 then s = { w, h } else s = false end
        sizeCache[mapID] = s
    end
    if s then return s[1], s[2] end
    return nil
end

local TWO_PI = 2 * pi
local function normAngle(a)
    a = a % TWO_PI
    if a > pi then a = a - TWO_PI end
    return a
end
Compat.NormalizeAngle = normAngle

--- Distance and direction from the player to a map point.
-- @return distance (yards) or nil,
--         angle (radians relative to the player's facing, counter-clockwise,
--                in (-pi, pi]; 0 = straight ahead, >0 = to the left; nil when
--                the facing is unknown) -- usable directly with Texture:SetRotation,
--         sameContinent (bool: false when no common coordinate frame exists),
--         approx (bool: distance estimated with a nominal map size)
function Compat.DistanceTo(mapID, x, y)
    local dN, dW, approx
    local tc, tx, ty = Compat.WorldPosFromMap(mapID, x, y)
    if tc then
        local pc, px, py = Compat.PlayerWorldPos()
        if pc and pc == tc then
            dN, dW = tx - px, ty - py
        end
    end
    if not dN then
        local pm, mx, my = Compat.GetPlayerMapPosition()
        if pm and pm == mapID then
            local w, h = mapSize(mapID)
            if not w then
                w, h = Compat.NOMINAL_MAP_SIZE[1], Compat.NOMINAL_MAP_SIZE[2]
                approx = true
            end
            local dEast = (x - mx) / 100 * w
            local dSouth = (y - my) / 100 * h
            dN, dW = -dSouth, -dEast
        end
    end
    if not dN then return nil, nil, false, false end
    local dist = sqrt(dN * dN + dW * dW)
    local angle
    local facing = Compat.Facing()
    if facing then
        -- bearing measured from north, counter-clockwise (towards west)
        angle = normAngle(atan2(dW, dN) - facing)
    end
    return dist, angle, true, approx and true or false
end

local mapNames = {}
--- Localized map name (C_Map.GetMapInfo), nil when unknown.
function Compat.GetMapName(mapID)
    if type(mapID) ~= "number" then return nil end
    local n = mapNames[mapID]
    if n then return n end
    local info = try(C_Map.GetMapInfo, mapID)
    if type(info) == "table" then
        n = pub(info.name)
        if type(n) == "string" and n ~= "" then
            mapNames[mapID] = n
            return n
        end
    end
    return nil
end

local areaNames = {} -- [areaID] = localized name (static per session)
--- Localized AreaTable name (C_Map.GetAreaInfo), nil when unknown. The same names
-- GetBindLocation() returns, in the client's language.
function Compat.AreaName(areaID)
    if type(areaID) ~= "number" then return nil end
    local n = areaNames[areaID]
    if n then return n end
    n = pub(try(C_Map.GetAreaInfo, areaID))
    if type(n) == "string" and n ~= "" then
        areaNames[areaID] = n
        return n
    end
    return nil
end

--- Is the "Map" add-on restriction active (instances)? Positions may be unavailable.
function Compat.IsMapRestricted()
    if not (C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive) then return false end
    if not (Enum and Enum.AddOnRestrictionType and Enum.AddOnRestrictionType.Map) then return false end
    return pubBool(try(C_RestrictedActions.IsAddOnRestrictionActive, Enum.AddOnRestrictionType.Map))
end

---------------------------------------------------------------------------
-- items, hearth, taxi
---------------------------------------------------------------------------

--- Number of the item in the bags.
function Compat.ItemCount(itemID)
    if type(itemID) ~= "number" then return 0 end
    return pubNumber(try(C_Item.GetItemCount, itemID)) or 0
end

local itemRequested = {} -- [itemID] = GetTime() of the last load request
local ITEM_RETRY = 60    -- seconds between load requests of the same item (like quest titles)
--- Localized item name, nil when not cached. A load request is sent at most
-- once per ITEM_RETRY seconds per item; ns:Fire("ITEM_DATA_LOADED", itemID, true)
-- follows when the data arrived (a failed load fires nothing, so an item that
-- does not exist on the server cannot cause a request/refresh loop).
function Compat.ItemName(itemID)
    if type(itemID) ~= "number" then return nil end
    local n = pub(try(C_Item.GetItemNameByID, itemID))
    if type(n) == "string" and n ~= "" then return n end
    local req = itemRequested[itemID]
    local now = GetTime and GetTime() or 0
    if not req or (now - req) > ITEM_RETRY then
        itemRequested[itemID] = now
        try(C_Item.RequestLoadItemDataByID, itemID)
    end
    return nil
end

--- Item icon (fileID), nil when unknown.
function Compat.ItemIcon(itemID)
    if type(itemID) ~= "number" then return nil end
    return pubNumber(try(C_Item.GetItemIconByID, itemID))
end

--- Hearthstone bind location (localized subzone name) or nil.
function Compat.BindLocation()
    local s = pub(try(GetBindLocation))
    if type(s) == "string" and s ~= "" then return s end
    return nil
end

--- Is the player on a flight path?
function Compat.OnTaxi()
    return pubBool(try(UnitOnTaxi, "player"))
end

---------------------------------------------------------------------------
-- units
---------------------------------------------------------------------------

--- NPC / game object id of a unit ("target", "npc", "mouseover", ...).
-- Secret GUIDs (instances, restricted units) yield nil.
-- @return id, kind ("Creature" | "Vehicle" | "GameObject") or nil
function Compat.GetNpcIdFromUnit(unit)
    local guid = try(UnitGUID, unit)
    if isSecret(guid) or type(guid) ~= "string" then return nil end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    if kind == "Creature" or kind == "Vehicle" or kind == "GameObject" then
        return tonumber(id), kind
    end
    return nil
end

---------------------------------------------------------------------------
-- quest dialog (QuestFrame: QUEST_DETAIL / QUEST_PROGRESS / QUEST_COMPLETE / QUEST_GREETING)
---------------------------------------------------------------------------

--- Quest id of the open quest dialog, or nil.
function Compat.GetDialogQuestID()
    local q = pubNumber(try(GetQuestID))
    if q and q > 0 then return q end
    return nil
end

--- Title of the open quest dialog, or nil.
function Compat.GetDialogTitle()
    local t = pub(try(GetTitleText))
    if type(t) == "string" and t ~= "" then return t end
    return nil
end

--- Does accepting the offered quest flag the player for PvP (needs a confirm popup)?
function Compat.IsDialogQuestPvP()
    return pubBool(try(QuestFlagsPVP))
end

--- Area-trigger auto quest (Blizzard closes the dialog and shows a popup itself).
function Compat.IsDialogAreaTriggerAuto()
    return pubBool(try(QuestGetAutoAccept)) and pubBool(try(QuestIsFromAreaTrigger))
end

--- Accept the quest offered in the QUEST_DETAIL dialog (auto-accept quests are acknowledged).
function Compat.AcceptDialogQuest()
    if pubBool(try(QuestGetAutoAccept)) then
        try(AcknowledgeAutoAcceptQuest)
    else
        try(AcceptQuest)
    end
    return true
end

--- Confirm an escort / shared quest start (QUEST_ACCEPT_CONFIRM).
function Compat.ConfirmAcceptQuest()
    try(ConfirmAcceptQuest)
end

--- QUEST_PROGRESS: can the quest be completed now?
function Compat.IsDialogQuestCompletable()
    return pubBool(try(IsQuestCompletable))
end

--- QUEST_PROGRESS: press "Complete Quest".
function Compat.CompleteDialogQuest()
    try(CompleteQuest)
end

--- QUEST_COMPLETE: number of reward choices.
function Compat.GetNumRewardChoices()
    return pubNumber(try(GetNumQuestChoices)) or 0
end

--- QUEST_COMPLETE: money the quest takes from the player (needs Blizzard's confirm popup).
function Compat.GetDialogMoneyRequired()
    return pubNumber(try(GetQuestMoneyToGet)) or 0
end

--- QUEST_COMPLETE: XP reward shown in the dialog (nil when unknown).
function Compat.GetDialogRewardXP()
    return pubNumber(try(GetRewardXP))
end

--- QUEST_COMPLETE: item id of reward choice #index, or nil.
function Compat.GetRewardChoiceItemID(index)
    local _, _, _, _, _, itemID = try(GetQuestItemInfo, "choice", index)
    return pubNumber(itemID)
end

--- QUEST_COMPLETE: take the reward (index 0 when there is no choice).
function Compat.ChooseReward(index)
    try(GetQuestReward, index or 0)
end

--- QUEST_GREETING active quests.
-- @return array of { index, questID, title, isComplete }
function Compat.GetGreetingActiveQuests()
    local out = {}
    local n = pubNumber(try(GetNumActiveQuests)) or 0
    for i = 1, n do
        local title, isComplete = try(GetActiveTitle, i)
        out[#out + 1] = {
            index = i, questID = pubNumber(try(GetActiveQuestID, i)),
            title = pub(title), isComplete = pubBool(isComplete),
        }
    end
    return out
end

--- QUEST_GREETING available quests.
-- @return array of { index, questID, title }
function Compat.GetGreetingAvailableQuests()
    local out = {}
    local n = pubNumber(try(GetNumAvailableQuests)) or 0
    for i = 1, n do
        local questID = select(5, try(GetAvailableQuestInfo, i))
        out[#out + 1] = {
            index = i, questID = pubNumber(questID), title = pub(try(GetAvailableTitle, i)),
        }
    end
    return out
end

--- QUEST_GREETING: select by LIST INDEX (not quest id).
function Compat.SelectGreetingActive(index)
    try(SelectActiveQuest, index)
end

function Compat.SelectGreetingAvailable(index)
    try(SelectAvailableQuest, index)
end

---------------------------------------------------------------------------
-- gossip (C_GossipInfo: selectors take the QUEST ID)
---------------------------------------------------------------------------

local function gossipQuests(fn)
    local out = {}
    local list = try(fn)
    if type(list) ~= "table" then return out end
    for _, info in ipairs(list) do
        if type(info) == "table" then
            out[#out + 1] = {
                questID = pubNumber(info.questID), title = pub(info.title),
                isComplete = pubBool(info.isComplete), questLevel = pubNumber(info.questLevel),
            }
        end
    end
    return out
end

--- Gossip active quests: array of { questID, title, isComplete, questLevel }.
function Compat.GetGossipActiveQuests()
    return gossipQuests(C_GossipInfo.GetActiveQuests)
end

--- Gossip available quests: array of { questID, title, questLevel }.
function Compat.GetGossipAvailableQuests()
    return gossipQuests(C_GossipInfo.GetAvailableQuests)
end

function Compat.SelectGossipActive(questID)
    try(C_GossipInfo.SelectActiveQuest, questID)
end

function Compat.SelectGossipAvailable(questID)
    try(C_GossipInfo.SelectAvailableQuest, questID)
end

--- Gossip options sorted like Blizzard's frame (by orderIndex).
-- @return array of { gossipOptionID, orderIndex, name, status }
function Compat.GetGossipOptions()
    local out = {}
    local list = try(C_GossipInfo.GetOptions)
    if type(list) ~= "table" then return out end
    for i, o in ipairs(list) do
        if type(o) == "table" then
            out[#out + 1] = {
                gossipOptionID = pubNumber(o.gossipOptionID),
                orderIndex = pubNumber(o.orderIndex) or (i - 1),
                name = pub(o.name), status = pubNumber(o.status),
            }
        end
    end
    sort(out, function(a, b) return a.orderIndex < b.orderIndex end)
    return out
end

--- Select a gossip option returned by GetGossipOptions (same call as Blizzard's buttons).
function Compat.SelectGossipOption(option)
    if type(option) ~= "table" then return end
    if option.orderIndex then
        try(C_GossipInfo.SelectOptionByIndex, option.orderIndex)
    elseif option.gossipOptionID then
        try(C_GossipInfo.SelectOption, option.gossipOptionID)
    end
end

---------------------------------------------------------------------------
-- Blizzard user waypoint (+ super tracking => Blizzard's own on-screen arrow)
---------------------------------------------------------------------------

function Compat.CanSetBlizzWaypoint(mapID)
    if type(mapID) ~= "number" then return false end
    return pubBool(try(C_Map.CanSetUserWaypointOnMap, mapID))
end

--- Place the user waypoint at a map point (percent) and super-track it.
-- @return true when placed
function Compat.SetBlizzWaypoint(mapID, x, y)
    if not Compat.CanSetBlizzWaypoint(mapID) then return false end
    if not (UiMapPoint and UiMapPoint.CreateFromCoordinates) then return false end
    local point = UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100)
    local ok = try(C_Map.SetUserWaypoint, point)
    if ok == false then return false end
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        try(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    end
    return true
end

function Compat.ClearBlizzWaypoint()
    try(C_Map.ClearUserWaypoint)
end

function Compat.HasBlizzWaypoint()
    return pubBool(try(C_Map.HasUserWaypoint))
end

--- Current user waypoint: uiMapID, x, y (percent) or nil.
function Compat.GetBlizzWaypoint()
    local point = try(C_Map.GetUserWaypoint)
    if type(point) ~= "table" then return nil end
    local m = pubNumber(point.uiMapID)
    local x, y = vecXY(point.position)
    if not m or not x then return nil end
    return m, x * 100, y * 100
end

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------

ns:On("QUEST_TURNED_IN", function(_, questID)
    questID = pubNumber(questID)
    if questID then session.turnedIn[questID] = true end
end)

ns:On("PLAYER_LEVEL_UP", function(_, level)
    level = pubNumber(level)
    if level then session.levelHint = level end
end)

ns:On("QUEST_DATA_LOAD_RESULT", function(_, questID, success)
    questID = pubNumber(questID)
    if not questID then return end
    if success then
        local t = try(C_QuestLog.GetTitleForQuestID, questID)
        if not isSecret(t) and type(t) == "string" and t ~= "" then titleCache[questID] = t end
    end
    if titleRequested[questID] then
        ns:Fire("QUEST_DATA_LOADED", questID, success and true or false)
    end
end)

ns:On("ITEM_DATA_LOAD_RESULT", function(_, itemID, success)
    itemID = pubNumber(itemID)
    -- the request timestamp is kept (throttle); only a successful load is announced
    if itemID and itemRequested[itemID] and success and not isSecret(success) then
        ns:Fire("ITEM_DATA_LOADED", itemID, true)
    end
end)

--- Test helper: forget all caches.
function Compat.ResetCaches()
    identity = nil
    for k in pairs(titleCache) do titleCache[k] = nil end
    for k in pairs(titleRequested) do titleRequested[k] = nil end
    for k in pairs(itemRequested) do itemRequested[k] = nil end
    for k in pairs(degenerate) do degenerate[k] = nil end
    for k in pairs(sizeCache) do sizeCache[k] = nil end
    for k in pairs(mapNames) do mapNames[k] = nil end
    for k in pairs(session.turnedIn) do session.turnedIn[k] = nil end
    session.levelHint = nil
end
