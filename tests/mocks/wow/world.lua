-- tests/mocks/wow/world.lua
--
-- Player state and units, XP / levels (Classic Era XP table), maps with a per-map
-- linear world transform, positions / facing, user waypoints and super tracking,
-- bags and items, spells, trainer / merchant / taxi / binder interactions, combat
-- and modifier keys.

local ctx = ...
local Mock, M, A, U = ctx.Mock, ctx.M, ctx.A, ctx.U

local floor, sqrt, atan2, pi = math.floor, math.sqrt, math.atan2, math.pi

---------------------------------------------------------------------------
-- XP (Classic Era table, identical in Forever: research/xp_table.json)
---------------------------------------------------------------------------

local XP_TO_LEVEL = {
    400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600, 8800, 10100, 11400, 12900, 14400,
    16000, 17700, 19400, 21300, 23200, 25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400,
    44300, 47400, 50800, 54500, 58600, 62800, 67100, 71600, 76100, 80800, 85700, 90700, 95800,
    101000, 106300, 111800, 117500, 123200, 129100, 135100, 141200, 147500, 153900, 160400,
    167100, 173900, 180800, 187900, 195000, 202300, 209800,
}
Mock.XP_TO_LEVEL = XP_TO_LEVEL

--- Quest XP after the Classic level-difference penalty and client rounding
-- (research/mechanics.md; 0 at the level cap).
function Mock.QuestXP(base, questLevel, playerLevel, maxLevel)
    base = base or 0
    if base <= 0 then return 0 end
    if playerLevel >= (maxLevel or 60) then return 0 end
    questLevel = questLevel or playerLevel
    local mult = math.max(1, math.min(10, 2 * (questLevel - playerLevel) + 20)) / 10
    local xp = base * mult
    if mult >= 1 then return base end
    if xp <= 100 then return 5 * floor((xp + 2) / 5)
    elseif xp <= 500 then return 10 * floor((xp + 5) / 10)
    elseif xp <= 1000 then return 25 * floor((xp + 12) / 25)
    end
    return 50 * floor((xp + 25) / 50)
end

function M:XPMax(level)
    level = level or self.player.level
    return XP_TO_LEVEL[level] or XP_TO_LEVEL[#XP_TO_LEVEL]
end

---------------------------------------------------------------------------
-- maps
---------------------------------------------------------------------------

-- Built-in maps (uiMapID: name, mapType (Enum.UIMapType), parent, continent instance ID).
-- Geometry is SYNTHETIC unless a spec defines it with m:DefineMap: 1 map unit (1% of the
-- map) = 10 yards (1000 x 1000 yards per zone) and zones of a continent are laid out on a
-- grid (col,row) so neighbours are adjacent; cities sit inside their zone.
local BUILTIN_MAPS = {
    [947] = { name = "Azeroth", mapType = 1, continent = nil },
    [1414] = { name = "Kalimdor", mapType = 2, parent = 947, continent = 1,
        width = 10000, height = 10000, top = 5000, left = 5000 },
    [1415] = { name = "Eastern Kingdoms", mapType = 2, parent = 947, continent = 0,
        width = 10000, height = 10000, top = 5000, left = 5000 },
    -- Eastern Kingdoms
    [1420] = { name = "Tirisfal Glades", mapType = 3, parent = 1415, continent = 0, col = 0, row = 0 },
    [1421] = { name = "Silverpine Forest", mapType = 3, parent = 1415, continent = 0, col = 0, row = 1 },
    [1424] = { name = "Hillsbrad Foothills", mapType = 3, parent = 1415, continent = 0, col = 1, row = 2 },
    [1416] = { name = "Alterac Mountains", mapType = 3, parent = 1415, continent = 0, col = 1, row = 1 },
    [1422] = { name = "Western Plaguelands", mapType = 3, parent = 1415, continent = 0, col = 1, row = 0 },
    [1458] = { name = "Undercity", mapType = 3, parent = 1420, continent = 0,
        inside = 1420, ix = 62, iy = 70, width = 300, height = 300 },
    -- Kalimdor
    [1411] = { name = "Durotar", mapType = 3, parent = 1414, continent = 1, col = 1, row = 0 },
    [1413] = { name = "The Barrens", mapType = 3, parent = 1414, continent = 1, col = 0, row = 0 },
    [1412] = { name = "Mulgore", mapType = 3, parent = 1414, continent = 1, col = -1, row = 0 },
    [1442] = { name = "Stonetalon Mountains", mapType = 3, parent = 1414, continent = 1, col = -1, row = -1 },
    [1440] = { name = "Ashenvale", mapType = 3, parent = 1414, continent = 1, col = 0, row = -1 },
    [1454] = { name = "Orgrimmar", mapType = 3, parent = 1411, continent = 1,
        inside = 1411, ix = 45, iy = 10, width = 400, height = 400 },
    [1456] = { name = "Thunder Bluff", mapType = 3, parent = 1412, continent = 1,
        inside = 1412, ix = 35, iy = 25, width = 300, height = 300 },
    -- Forever islands: separate instances, world rectangles are zero (no world positions)
    [2521] = { name = "Zephras Isle", mapType = 3, parent = 947, continent = 2521, noWorld = true },
    [2524] = { name = "Darkspear Islands", mapType = 3, parent = 947, continent = 2524, noWorld = true },
    [2548] = { name = "Riverglades", mapType = 3, parent = 1415, continent = 0, col = 2, row = 2 },
}
Mock.BUILTIN_MAPS = BUILTIN_MAPS

local function finishMap(m, id, def)
    def.mapID = id
    def.mapType = def.mapType or 3
    def.width = def.width or 1000
    def.height = def.height or 1000
    if def.continent == nil and def.mapType >= 3 then def.continent = id end
    if not def.noWorld and def.top == nil then
        if def.inside and m.maps[def.inside] then
            local outer = m.maps[def.inside]
            local ox, oy = (def.ix or 50) / 100, (def.iy or 50) / 100
            def.top = outer.top - oy * outer.height + def.height / 2
            def.left = outer.left - ox * outer.width + def.width / 2
        else
            def.top = -(def.row or 0) * 1000
            def.left = -(def.col or 0) * 1000
        end
    end
    m.maps[id] = def
    return def
end

--- Define (or redefine) a map: { name, mapType, parent, continent, width, height (yards),
-- top (world X of the top edge), left (world Y of the left edge), noWorld, canWaypoint, flags }.
function M:DefineMap(id, def)
    def = U.deepcopy(def or {})
    local old = self.maps[id]
    if old then
        for k, v in pairs(old) do if def[k] == nil then def[k] = v end end
    end
    return finishMap(self, id, def)
end

function M:_map(id)
    return id and self.maps[id] or nil
end

function M:_canWaypoint(mapID)
    local def = self.maps[mapID]
    if not def then return false end
    if def.canWaypoint ~= nil then return def.canWaypoint == true end
    return def.mapType >= 3 and def.mapType ~= 4
end

local function mapToWorld(def, fx, fy)
    return def.top - fy * def.height, def.left - fx * def.width
end
local function worldToMap(def, wx, wy)
    return (def.left - wy) / def.width, (def.top - wx) / def.height
end
Mock.mapToWorld, Mock.worldToMap = mapToWorld, worldToMap

--- World position (yards) of map coordinates in percent: worldX (north), worldY (west), continent.
function M:WorldPos(mapID, x, y)
    local def = self.maps[mapID]
    if not def or def.noWorld then return nil end
    local wx, wy = mapToWorld(def, x / 100, y / 100)
    return wx, wy, def.continent
end

--- Distance in yards between two map points (nil if not on the same continent / no world).
function M:Distance(mapA, xa, ya, mapB, xb, yb)
    local ax, ay, ca = self:WorldPos(mapA, xa, ya)
    local bx, by, cb = self:WorldPos(mapB, xb, yb)
    if not ax or not bx or ca ~= cb then return nil end
    return sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
end

---------------------------------------------------------------------------
-- vectors / UiMapPoint (FrameXML Vector2DMixin subset)
---------------------------------------------------------------------------

local function vector(x, y)
    local v = { x = x, y = y }
    function v.GetXY(self) return self.x, self.y end
    function v.SetXY(self, nx, ny) self.x, self.y = nx, ny end
    function v.IsEqualTo(self, o) return self.x == o.x and self.y == o.y end
    function v.Clone(self) return vector(self.x, self.y) end
    function v.IsZero(self) return self.x == 0 and self.y == 0 end
    function v.GetLength(self) return sqrt(self.x * self.x + self.y * self.y) end
    function v.GetLengthSquared(self) return self.x * self.x + self.y * self.y end
    function v.ScaleBy(self, s) self.x, self.y = self.x * s, self.y * s end
    function v.Add(self, o) self.x, self.y = self.x + o.x, self.y + o.y end
    function v.Subtract(self, o) self.x, self.y = self.x - o.x, self.y - o.y end
    function v.Dot(self, o) return self.x * o.x + self.y * o.y end
    function v.Normalize(self)
        local l = self:GetLength()
        if l > 0 then self.x, self.y = self.x / l, self.y / l end
    end
    return v
end
Mock.CreateVector2D = vector

local function vecXY(m, v, fname)
    if type(v) ~= "table" then m:_violation(fname .. ": vector2 expected", 4) end
    local x, y = v.x, v.y
    if type(x) ~= "number" or type(y) ~= "number" then m:_violation(fname .. ": vector2 with numeric x, y expected", 4) end
    return x, y
end

---------------------------------------------------------------------------
-- player helpers
---------------------------------------------------------------------------

local RACE_NAMES = {
    Scourge = "Undead", Skyborne = "Skyborne", Orc = "Orc", Tauren = "Tauren", Troll = "Troll",
    Human = "Human", Dwarf = "Dwarf", NightElf = "Night Elf", Gnome = "Gnome",
}
local CLASS_NAMES = {
    WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
    SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid",
}

local function npcGUID(m, info)
    if not info then return nil end
    if info.guid then return info.guid end
    local kind = info.kind or "Creature"
    local id = math.abs(info.dbID or info.id or 0)
    info.guid = string.format("%s-0-5000-0-1-%d-%010X", kind, id, 0x1000 + math.abs(info.spawn or id))
    return info.guid
end

--- Unit record for a token: player / npc (current interaction) / target / mouseover.
function M:_unit(token)
    if type(token) ~= "string" then return nil end
    token = token:lower()
    if token == "player" then return "player" end
    if token == "npc" or token == "questnpc" then return self.interaction and self.interaction.npc end
    if token == "target" then return self.target end
    if token == "mouseover" then return self.mouseover end
    if token == "softinteract" then return self.target end
    return nil
end

function M:_unitValue(info, v)
    if info ~= "player" and self.secretUnits and v ~= nil then return self:MakeSecret() end
    return v
end

--- Move the player (fires ZONE_CHANGED_NEW_AREA / ZONE_CHANGED when the map changes).
-- m:MoveTo(x, y) keeps the map; m:MoveTo(mapID, x, y) changes it.
function M:MoveTo(a, b, c)
    local mapID, x, y
    if c == nil then mapID, x, y = self.player.mapID, a, b else mapID, x, y = a, b, c end
    return self:_top(function()
        local old = self.player.mapID
        self.player.mapID, self.player.x, self.player.y = mapID, x, y
        if old ~= mapID then
            self:_dispatch("ZONE_CHANGED_NEW_AREA")
            self:_dispatch("ZONE_CHANGED")
        end
    end)
end

--- Set the player facing (radians, 0 = north, counter-clockwise).
function M:SetFacing(rad)
    self.player.facing = rad % (2 * pi)
end

--- Face a point on the current map (percent coordinates).
function M:FaceTowards(x, y)
    local def = self.maps[self.player.mapID]
    local w, h = def and def.width or 1000, def and def.height or 1000
    local dx = (x - self.player.x) / 100 * w                -- east
    local dy = (y - self.player.y) / 100 * h                -- south
    self:SetFacing(atan2(-dx, -dy))
end

--- Walk on the current map towards (x, y) at `speed` yards/s (default 7), advancing the
-- clock frame by frame; stops after `maxSeconds` (default: until arrival).
function M:WalkTo(x, y, speed, maxSeconds)
    speed = speed or 7
    return self:_top(function()
        local def = self.maps[self.player.mapID]
        local w, h = def and def.width or 1000, def and def.height or 1000
        local elapsed = 0
        self:FaceTowards(x, y)
        while true do
            local dx = (x - self.player.x) / 100 * w
            local dy = (y - self.player.y) / 100 * h
            local dist = sqrt(dx * dx + dy * dy)
            if dist < 0.01 then break end
            if maxSeconds and elapsed >= maxSeconds then break end
            local dt = self.frameTime
            local step = math.min(dist, speed * dt)
            self.player.x = self.player.x + dx / dist * step / w * 100
            self.player.y = self.player.y + dy / dist * step / h * 100
            self:_frame(dt)
            elapsed = elapsed + dt
        end
    end)
end

function M:SetSubZone(name)
    return self:_top(function()
        self.player.subzone = name
        self:_dispatch("ZONE_CHANGED")
    end)
end

--- Enter / leave an instance (positions become unavailable inside).
function M:EnterInstance(name, instanceType, mapID)
    return self:_top(function()
        self.player.instance = { name = name or "Instance", type = instanceType or "party" }
        self.player.mapID = mapID
        self:_dispatch("PLAYER_ENTERING_WORLD", false, false)
        self:_dispatch("ZONE_CHANGED_NEW_AREA")
    end)
end
function M:LeaveInstance(mapID, x, y)
    return self:_top(function()
        self.player.instance = nil
        self.player.mapID, self.player.x, self.player.y = mapID or self.player.mapID, x or self.player.x, y or self.player.y
        self:_dispatch("PLAYER_ENTERING_WORLD", false, false)
        self:_dispatch("ZONE_CHANGED_NEW_AREA")
    end)
end

--- Give XP; handles level-ups (PLAYER_LEVEL_UP with the client's UnitLevel lag,
-- PLAYER_LEVEL_CHANGED) and PLAYER_XP_UPDATE. opts.kill: rested bonus applies.
function M:GiveXP(amount, opts)
    opts = opts or {}
    return self:_top(function() self:_giveXP(amount, opts) end)
end

function M:_giveXP(amount, opts)
    local p = self.player
    local maxLevel = self.maxLevel
    if amount <= 0 or p.level >= maxLevel then return end
    if opts and opts.kill and (p.rested or 0) > 0 then
        local bonus = math.min(p.rested, amount)
        p.rested = p.rested - bonus
        amount = amount + bonus
        self:_dispatch("UPDATE_EXHAUSTION")
    end
    p.xp = p.xp + amount
    while p.level < maxLevel and p.xp >= (p.xpMax or self:XPMax(p.level)) do
        p.xp = p.xp - (p.xpMax or self:XPMax(p.level))
        self:_levelUp(p.level + 1)
    end
    if p.level >= maxLevel then p.xp = 0 end
    self:_dispatch("PLAYER_XP_UPDATE", "player")
end

function M:_levelUp(newLevel, oldLevel)
    local p = self.player
    local old = oldLevel or p.level
    p.level = newLevel
    p.xpMax = nil                       -- an explicit override only holds for the level it was set at
    -- the client's UnitLevel("player") still returns the old level while
    -- PLAYER_LEVEL_UP is dispatched (Core addons use the event payload instead)
    if self.levelLag then self._lagLevel = old end
    self:_dispatch("PLAYER_LEVEL_UP", newLevel, 10, 10, 0, 0, 1, 1, 1, 1, 1)
    self._lagLevel = nil
    self:_dispatch("PLAYER_LEVEL_CHANGED", old, newLevel, true)
end

--- Set the level directly (fires PLAYER_LEVEL_UP / PLAYER_LEVEL_CHANGED / PLAYER_XP_UPDATE).
function M:SetLevel(level, xp)
    return self:_top(function()
        local p = self.player
        local old = p.level
        p.xp = xp or 0
        if level ~= old then self:_levelUp(level, old) end
        self:_dispatch("PLAYER_XP_UPDATE", "player")
    end)
end

function M:SetRested(amount)
    return self:_top(function()
        self.player.rested = amount or 0
        self:_dispatch("UPDATE_EXHAUSTION")
    end)
end

function M:SetMoney(copper)
    return self:_top(function()
        self.player.money = copper
        self:_dispatch("PLAYER_MONEY")
    end)
end

function M:EnterCombat()
    return self:_top(function()
        self:_dispatch("PLAYER_REGEN_DISABLED")       -- fires before the lockdown starts
        self.player.inCombat = true
    end)
end
function M:LeaveCombat()
    return self:_top(function()
        self.player.inCombat = false
        self:_dispatch("PLAYER_REGEN_ENABLED")
    end)
end

local MOD_KEYS = { shift = "LSHIFT", ctrl = "LCTRL", alt = "LALT" }
--- Press / release a modifier ("shift" | "ctrl" | "alt"); fires MODIFIER_STATE_CHANGED.
function M:SetModifier(key, down)
    return self:_top(function()
        self.player[key] = down and true or false
        self:_dispatch("MODIFIER_STATE_CHANGED", MOD_KEYS[key] or key:upper(), down and 1 or 0)
    end)
end
function M:SetShift(down) return self:SetModifier("shift", down) end

--- Target an NPC (id, name) or clear the target with nil; fires PLAYER_TARGET_CHANGED.
function M:SetTarget(npcID, name, kind)
    return self:_top(function()
        if npcID then
            local def = self.npcs[npcID] or {}
            self.target = { id = npcID, name = name or def.name or ("NPC " .. npcID), kind = kind or def.kind,
                level = def.level }
        else
            self.target = nil
        end
        self:_dispatch("PLAYER_TARGET_CHANGED")
    end)
end

---------------------------------------------------------------------------
-- items & bags
---------------------------------------------------------------------------

--- Define an item: { name, icon (fileID), quality, cached (true) }.
function M:DefineItem(id, def)
    def = U.deepcopy(def or {})
    def.id = id
    def.name = def.name or ("Item " .. id)
    def.icon = def.icon or 134400
    def.quality = def.quality or 1
    if def.cached == nil then def.cached = true end
    self.items[id] = def
    return def
end

function M:_itemID(info)
    if type(info) == "number" then return info end
    if type(info) == "string" then
        local id = info:match("item:(%d+)")
        if id then return tonumber(id) end
        if tonumber(info) then return tonumber(info) end
        for iid, def in pairs(self.items) do
            if def.name == info then return iid end
        end
    end
    return nil
end

function M:_itemLink(id)
    local def = self.items[id]
    local name = def and def.name or ("Item " .. id)
    return string.format("|cffffffff|Hitem:%d::::::::1:::::::::|h[%s]|h|r", id, name)
end

function M:GetItemCount(id) return self.bags[id] or 0 end

--- Add items to the bags (BAG_UPDATE / BAG_UPDATE_DELAYED, quest item objectives update).
function M:AddItem(id, count)
    count = count or 1
    return self:_top(function() self:_changeItem(id, count) end)
end
function M:RemoveItem(id, count)
    count = count or 1
    return self:_top(function() self:_changeItem(id, -count) end)
end

function M:_changeItem(id, delta)
    if not self.items[id] then self:DefineItem(id, {}) end
    local n = math.max(0, (self.bags[id] or 0) + delta)
    if n == 0 then self.bags[id] = nil else self.bags[id] = n end
    if not self._bagOrder[id] and n > 0 then
        self._bagSeq = self._bagSeq + 1
        self._bagOrder[id] = self._bagSeq
    end
    self:_dispatch("BAG_UPDATE", 0)
    if delta > 0 then self:_dispatch("ITEM_PUSH", 1, self.items[id].icon) end
    if self._onItemsChanged then self:_onItemsChanged(id) end
    self:_dispatch("BAG_UPDATE_DELAYED")
end

-- backpack layout: one stack per item id, in the order items were first added
function M:_bagSlots()
    local ids = {}
    for id in pairs(self.bags) do ids[#ids + 1] = id end
    table.sort(ids, function(a, b) return (self._bagOrder[a] or 0) < (self._bagOrder[b] or 0) end)
    return ids
end

---------------------------------------------------------------------------
-- spells
---------------------------------------------------------------------------

function M:DefineSpell(id, def)
    def = U.deepcopy(def or {})
    def.id = id
    def.name = def.name or ("Spell " .. id)
    def.icon = def.icon or 136243
    self.spellDB[id] = def
    return def
end

--- Learn a spell: LEARNED_SPELL_IN_SKILL_LINE + SPELLS_CHANGED.
function M:LearnSpell(id)
    return self:_top(function()
        self.spells[id] = true
        self:_dispatch("LEARNED_SPELL_IN_SKILL_LINE", id, 1, false)
        self:_dispatch("SPELLS_CHANGED")
    end)
end

---------------------------------------------------------------------------
-- NPC interactions (trainer / merchant / taxi / binder)
---------------------------------------------------------------------------

--- Define an NPC: { name, level, kind ("Creature"|"GameObject"), starts = {questIDs},
-- ends = {questIDs}, options = {...}, greeting = bool (QUEST_GREETING instead of gossip),
-- text, trainer = {...}, merchant = {...}, taxi = {...} }.
function M:DefineNPC(id, def)
    def = U.deepcopy(def or {})
    def.id = id
    def.name = def.name or ("NPC " .. id)
    self.npcs[id] = def
    return def
end

function M:_beginInteraction(kind, npcID, extra)
    if self.interaction then self:_closeCurrentInteraction() end   -- talking to someone else closes it
    local def = npcID and self.npcs[npcID] or {}
    local npc = npcID and { id = npcID, dbID = def.dbID, name = def.name or ("NPC " .. npcID), kind = def.kind,
        level = def.level } or nil
    self.interaction = U.merge({ kind = kind, npc = npc }, extra or {})
    return self.interaction
end

function M:_endInteraction(kind)
    if self.interaction and (kind == nil or self.interaction.kind == kind) then
        self.interaction = nil
    end
end

local PIT = A.enums.PlayerInteractionType or {}

--- Open a trainer: spec = { services = { { name, rank, category ("available"|"used"|"unavailable"),
-- spellID, cost } } }. Fires PLAYER_INTERACTION_MANAGER_FRAME_SHOW(Trainer) + TRAINER_SHOW.
function M:OpenTrainer(spec, npcID)
    return self:_top(function()
        spec = spec or (npcID and self.npcs[npcID] and self.npcs[npcID].trainer) or {}
        self:_beginInteraction("trainer", npcID, { services = U.deepcopy(spec.services or {}) })
        self:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", PIT.Trainer)
        self:_dispatch("TRAINER_SHOW")
    end)
end
function M:_closeTrainer()
    if not (self.interaction and self.interaction.kind == "trainer") then return end
    self:_endInteraction("trainer")
    self:_dispatch("TRAINER_CLOSED")
    self:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", PIT.Trainer)
end
function M:CloseTrainer() return self:_top(function() self:_closeTrainer() end) end

--- Open a vendor: spec = { items = { { itemID, name, price } } }.
function M:OpenMerchant(spec, npcID)
    return self:_top(function()
        spec = spec or (npcID and self.npcs[npcID] and self.npcs[npcID].merchant) or {}
        self:_beginInteraction("merchant", npcID, { items = U.deepcopy(spec.items or {}) })
        self:_panel("MerchantFrame", true)
        self:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", PIT.Merchant)
        self:_dispatch("MERCHANT_SHOW")
    end)
end
function M:_closeMerchant()
    if not (self.interaction and self.interaction.kind == "merchant") then return end
    self:_endInteraction("merchant")
    self:_panel("MerchantFrame", false)
    self:_dispatch("MERCHANT_CLOSED")
    self:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", PIT.Merchant)
end
function M:CloseMerchant() return self:_top(function() self:_closeMerchant() end) end

--- Open the flight map: nodes = { { name, x, y (0..1 on the taxi map), state ("CURRENT" |
-- "REACHABLE" | "DISTANT" | "NONE"), nodeID, cost, mapID, destX, destY (percent landing point),
-- flightTime (seconds; auto-land after it when set) } }.
function M:OpenTaxi(nodes, npcID, taxiMapID)
    return self:_top(function()
        nodes = nodes or (npcID and self.npcs[npcID] and self.npcs[npcID].taxi) or {}
        self:_beginInteraction("taxi", npcID, { nodes = U.deepcopy(nodes), mapID = taxiMapID })
        for i, n in ipairs(self.interaction.nodes) do
            n.slotIndex = i
            n.nodeID = n.nodeID or (100 + i)
            if n.mapID then self.knownTaxiNodes[n.nodeID] = n end
        end
        self:_panel("TaxiFrame", true)
        self:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", PIT.TaxiNode)
        self:_dispatch("TAXIMAP_OPENED", (A.enums.UIMapSystem or {}).Taxi or 1)
    end)
end
function M:_closeTaxi()
    if not (self.interaction and self.interaction.kind == "taxi") then return end
    self:_endInteraction("taxi")
    self:_panel("TaxiFrame", false)
    self:_dispatch("TAXIMAP_CLOSED")
    self:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", PIT.TaxiNode)
end
function M:CloseTaxi() return self:_top(function() self:_closeTaxi() end) end

--- Land a flight (onTaxi = false, move to the destination, PLAYER_CONTROL_GAINED).
function M:Land(mapID, x, y)
    return self:_top(function() self:_land(mapID, x, y) end)
end
function M:_land(mapID, x, y)
    local f = self.flight or {}
    self.flight = nil
    self.player.onTaxi = false
    mapID = mapID or f.mapID or self.player.mapID
    local old = self.player.mapID
    self.player.mapID, self.player.x, self.player.y = mapID, x or f.x or self.player.x, y or f.y or self.player.y
    self:_dispatch("PLAYER_CONTROL_GAINED")
    if old ~= mapID then
        self:_dispatch("ZONE_CHANGED_NEW_AREA")
        self:_dispatch("ZONE_CHANGED")
    end
end

--- Talk to an innkeeper: CONFIRM_BINDER(areaName); the addon / spec confirms with
-- C_PlayerInteractionManager.ConfirmationInteraction(Enum.PlayerInteractionType.Binder)
-- or m:ConfirmBinder().
function M:OpenBinder(areaName, npcID, mapID, x, y)
    return self:_top(function()
        self:_beginInteraction("binder", npcID, { bind = { name = areaName, mapID = mapID, x = x, y = y } })
        self:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", PIT.Binder)
        self:_dispatch("CONFIRM_BINDER", areaName)
    end)
end
function M:_confirmBinder()
    if not (self.interaction and self.interaction.kind == "binder") then return false end
    local b = self.interaction.bind
    self:_endInteraction("binder")
    self.bind = U.deepcopy(b)
    self:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", PIT.Binder)
    self:_dispatch("HEARTHSTONE_BOUND")
    return true
end
function M:ConfirmBinder() return self:_top(function() return self:_confirmBinder() end) end

--- Set the hearthstone location directly (fires HEARTHSTONE_BOUND).
function M:SetBindLocation(name, mapID, x, y)
    return self:_top(function()
        self.bind = { name = name, mapID = mapID, x = x, y = y }
        self:_dispatch("HEARTHSTONE_BOUND")
    end)
end

--- Use the hearthstone: UNIT_SPELLCAST_SUCCEEDED("player", castGUID, 8690) and teleport
-- to the bind point (when it has coordinates).
function M:UseHearthstone()
    return self:_top(function()
        self:_action("Hearthstone")
        self:_dispatch("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-3-5000-0-1-8690-0000000001", 8690)
        local b = self.bind
        if b and b.mapID then
            local old = self.player.mapID
            self.player.mapID, self.player.x, self.player.y = b.mapID, b.x or 50, b.y or 50
            if old ~= b.mapID then
                self:_dispatch("ZONE_CHANGED_NEW_AREA")
                self:_dispatch("ZONE_CHANGED")
            end
        end
    end)
end

function M:_closeCurrentInteraction()
    local it = self.interaction
    if not it then return end
    if it.kind == "trainer" then self:_closeTrainer()
    elseif it.kind == "merchant" then self:_closeMerchant()
    elseif it.kind == "taxi" then self:_closeTaxi()
    elseif it.kind == "binder" then
        self:_endInteraction("binder")
        self:_dispatch("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", PIT.Binder)
    elseif self._closeQuestInteraction then
        self:_closeQuestInteraction()
    end
    self.interaction = nil
end

--- Close whatever NPC interaction is open (quest dialog, gossip, trainer, vendor, taxi).
function M:CloseInteraction()
    return self:_top(function() self:_closeCurrentInteraction() end)
end

---------------------------------------------------------------------------
-- installer
---------------------------------------------------------------------------

ctx.register(function(m)
    local opts = m.opts
    m.maxLevel = opts.maxLevel or 60
    m.levelLag = opts.levelLag ~= false
    m.maps = {}
    for id, def in pairs(BUILTIN_MAPS) do
        if def.inside == nil then finishMap(m, id, U.deepcopy(def)) end
    end
    for id, def in pairs(BUILTIN_MAPS) do
        if def.inside ~= nil then finishMap(m, id, U.deepcopy(def)) end
    end
    for id, def in pairs(opts.maps or {}) do m:DefineMap(id, def) end
    m.items, m.bags, m._bagOrder, m._bagSeq = {}, {}, {}, 0
    for id, n in pairs(opts.bags or {}) do
        m:DefineItem(id, {})
        m.bags[id] = n
        m._bagSeq = m._bagSeq + 1
        m._bagOrder[id] = m._bagSeq
    end
    m.spells, m.spellDB = {}, {}
    for _, id in ipairs(opts.spells or {}) do m.spells[id] = true end
    m.npcs = {}
    m.bind = U.deepcopy(opts.bind or { name = "Deathknell" })
    m.target, m.mouseover, m.interaction, m.flight = nil, nil, nil, nil
    m.userWaypoint = nil
    m.superTrack = { waypoint = false, questID = nil }
    m.knownTaxiNodes = {}
    m.secretUnits = opts.secretUnits == true
    m.areaNames = U.deepcopy(opts.areaNames or {})
    local p = m.player

    -- vectors / map points (FrameXML)
    m:Provide("CreateVector2D", vector)
    m:Provide("UiMapPoint", {
        CreateFromCoordinates = function(mapID, x, y, z)
            return { uiMapID = mapID, position = vector(x, y), z = z }
        end,
        CreateFromVector2D = function(mapID, position, z)
            return { uiMapID = mapID, position = position, z = z }
        end,
        CreateFromVector3D = function(mapID, position)
            return { uiMapID = mapID, position = vector(position.x, position.y), z = position.z }
        end,
    })

    -- units ---------------------------------------------------------------
    local function unitArg(fname, unit)
        if type(unit) ~= "string" then m:_violation(fname .. ": unit token expected", 4) end
        return m:_unit(unit)
    end
    m:ProvideAPI("UnitExists", function(unit)
        if unit == nil then return false end
        return unitArg("UnitExists", unit) ~= nil
    end)
    m:ProvideAPI("UnitGUID", function(unit)
        local u = unitArg("UnitGUID", unit)
        if u == "player" then return p.guid end
        if u then return m:_unitValue(u, npcGUID(m, u)) end
        return nil
    end)
    m:ProvideAPI("UnitName", function(unit)
        local u = unitArg("UnitName", unit)
        if u == "player" then return p.name, nil end
        if u then return m:_unitValue(u, u.name), nil end
        return nil
    end)
    m:ProvideAPI("UnitFullName", function(unit)
        local u = unitArg("UnitFullName", unit)
        if u == "player" then return p.name, (p.realm:gsub("[%s%-]", "")) end
        if u then return m:_unitValue(u, u.name), nil end
        return nil
    end)
    local function level(unit)
        local u = unitArg("UnitLevel", unit)
        if u == "player" then return m._lagLevel or p.level end
        if u then return m:_unitValue(u, u.level or 1) end
        return 0
    end
    m:ProvideAPI("UnitLevel", level)
    m:ProvideAPI("UnitEffectiveLevel", level)
    m:ProvideAPI("UnitXP", function(unit)
        if unitArg("UnitXP", unit) ~= "player" then return 0 end
        return p.xp
    end)
    m:ProvideAPI("UnitXPMax", function(unit)
        if unitArg("UnitXPMax", unit) ~= "player" then return 0 end
        return p.xpMax or m:XPMax(math.min(p.level, #XP_TO_LEVEL))   -- player.xpMax: explicit override
    end)
    m:ProvideAPI("GetXPExhaustion", function()
        if (p.rested or 0) > 0 then return p.rested end
        return nil
    end)
    m:ProvideAPI("GetRestState", function()
        if (p.rested or 0) > 0 then return 1, "Rested", 2 end
        return 2, "Normal", 1
    end)
    m:ProvideAPI("IsResting", function() return p.resting == true end)
    m:ProvideAPI("GetMaxPlayerLevel", function() return m.maxLevel end)
    m:ProvideAPI("IsXPUserDisabled", function() return false end)
    m:ProvideAPI("GetMoney", function() return p.money or 0 end)
    m:ProvideAPI("UnitRace", function(unit)
        local u = unitArg("UnitRace", unit)
        if u == "player" then return RACE_NAMES[p.race] or p.race, p.race, p.raceID end
        return nil
    end)
    m:ProvideAPI("UnitClass", function(unit)
        local u = unitArg("UnitClass", unit)
        if u == "player" then return CLASS_NAMES[p.class] or p.class, p.class, p.classID end
        return nil
    end)
    m:ProvideAPI("UnitClassBase", function(unit)
        local u = unitArg("UnitClassBase", unit)
        if u == "player" then return p.class, p.classID end
        return nil
    end)
    m:ProvideAPI("UnitFactionGroup", function(unit)
        local u = unitArg("UnitFactionGroup", unit)
        if u == "player" then return p.faction, p.faction end
        return nil
    end)
    m:ProvideAPI("UnitSex", function(unit)
        local u = unitArg("UnitSex", unit)
        if u == "player" then return p.sex end
        return nil
    end)
    m:ProvideAPI("UnitIsPlayer", function(unit) return unitArg("UnitIsPlayer", unit) == "player" end)
    m:ProvideAPI("UnitIsUnit", function(a, b)
        local ua, ub = m:_unit(a), m:_unit(b)
        return ua ~= nil and ua == ub
    end)
    m:ProvideAPI("UnitIsDeadOrGhost", function(unit)
        return unitArg("UnitIsDeadOrGhost", unit) == "player" and p.dead == true
    end)
    m:ProvideAPI("UnitIsDead", function(unit) return unitArg("UnitIsDead", unit) == "player" and p.dead == true end)
    m:ProvideAPI("UnitIsGhost", function(unit) return unitArg("UnitIsGhost", unit) == "player" and p.ghost == true end)
    m:ProvideAPI("UnitAffectingCombat", function(unit)
        return unitArg("UnitAffectingCombat", unit) == "player" and p.inCombat == true
    end)
    m:ProvideAPI("UnitOnTaxi", function(unit)
        return unitArg("UnitOnTaxi", unit) == "player" and p.onTaxi == true
    end)
    m:ProvideAPI("UnitIsAFK", function() return false end)

    -- position / zone ------------------------------------------------------
    m:ProvideAPI("UnitPosition", function(unit)
        if unitArg("UnitPosition", unit) ~= "player" or p.instance then return nil end
        local def = m.maps[p.mapID]
        if not def or def.noWorld then return nil end
        local wx, wy = mapToWorld(def, p.x / 100, p.y / 100)
        return wx, wy, 0, def.continent
    end)
    m:ProvideAPI("GetPlayerFacing", function()
        if p.instance and p.instance.restricted then return nil end
        return p.facing
    end)
    m:ProvideAPI("GetZoneText", function()
        local def = m.maps[p.mapID]
        return p.instance and p.instance.name or def and def.name or ""
    end)
    m:ProvideAPI("GetRealZoneText", function(mapID)
        local def = m.maps[mapID or p.mapID]
        return def and def.name or ""
    end)
    m:ProvideAPI("GetSubZoneText", function() return p.subzone or "" end)
    m:ProvideAPI("GetMinimapZoneText", function()
        if p.subzone and p.subzone ~= "" then return p.subzone end
        local def = m.maps[p.mapID]
        return def and def.name or ""
    end)
    m:ProvideAPI("IsInInstance", function()
        if p.instance then return true, p.instance.type end
        return false, "none"
    end)
    m:ProvideAPI("GetInstanceInfo", function()
        local def = m.maps[p.mapID]
        if p.instance then return p.instance.name, p.instance.type, 1, "Normal", 5, 0, false, p.mapID or 0, 5, nil end
        return def and def.name or "", "none", 0, "", 0, 0, false, def and def.continent or 0, 0, nil
    end)
    m:ProvideAPI("GetBindLocation", function() return m.bind and m.bind.name or nil end)

    -- C_Map / C_SuperTrack -------------------------------------------------
    local function mapInfo(def)
        return { mapID = def.mapID, name = def.name, mapType = def.mapType, parentMapID = def.parent or 0,
            flags = def.flags or 0 }
    end
    local function setSuperTrackWaypoint(on)
        on = on and true or false
        if on and not m.userWaypoint then on = false end
        if m.superTrack.waypoint ~= on then
            m.superTrack.waypoint = on
            m:_dispatch("SUPER_TRACKING_CHANGED")
        end
    end
    m:ProvideNS("C_Map", {
        GetBestMapForUnit = function(unit)
            if unitArg("C_Map.GetBestMapForUnit", unit) ~= "player" then return nil end
            return p.mapID
        end,
        GetPlayerMapPosition = function(mapID, unit)
            if unitArg("C_Map.GetPlayerMapPosition", unit) ~= "player" or p.instance then return nil end
            if mapID == p.mapID then return vector(p.x / 100, p.y / 100) end
            local from, to = m.maps[p.mapID], m.maps[mapID]
            if not from or not to or from.noWorld or to.noWorld or from.continent ~= to.continent then return nil end
            local wx, wy = mapToWorld(from, p.x / 100, p.y / 100)
            return vector(worldToMap(to, wx, wy))
        end,
        GetMapInfo = function(mapID)
            local def = m.maps[mapID]
            if not def then return nil end
            return mapInfo(def)
        end,
        GetMapChildrenInfo = function(mapID, mapType, allDescendants)
            local out = {}
            local function walk(parent)
                for _, id in ipairs(U.sortedKeys(m.maps)) do
                    local def = m.maps[id]
                    if def.parent == parent then
                        if mapType == nil or def.mapType == mapType then out[#out + 1] = mapInfo(def) end
                        if allDescendants then walk(id) end
                    end
                end
            end
            walk(mapID)
            return out
        end,
        GetMapWorldSize = function(mapID)
            local def = m.maps[mapID]
            if not def or def.noWorld then return 0, 0 end
            return def.width, def.height
        end,
        GetWorldPosFromMapPos = function(mapID, pos)
            local x, y = vecXY(m, pos, "C_Map.GetWorldPosFromMapPos")
            local def = m.maps[mapID]
            if not def or def.noWorld then return nil end
            local wx, wy = mapToWorld(def, x, y)
            return def.continent, vector(wx, wy)
        end,
        GetMapPosFromWorldPos = function(continentID, pos, overrideMapID)
            local wx, wy = vecXY(m, pos, "C_Map.GetMapPosFromWorldPos")
            local best, bestArea
            local candidates = overrideMapID and { overrideMapID } or U.sortedKeys(m.maps)
            for _, id in ipairs(candidates) do
                local def = m.maps[id]
                if def and not def.noWorld and def.continent == continentID and def.mapType >= 3 then
                    local fx, fy = worldToMap(def, wx, wy)
                    if overrideMapID or (fx >= 0 and fx <= 1 and fy >= 0 and fy <= 1) then
                        local area = def.width * def.height
                        if not best or area < bestArea then best, bestArea = id, area end
                    end
                end
            end
            if not best then return nil end
            return best, vector(worldToMap(m.maps[best], wx, wy))
        end,
        GetMapRectOnMap = function(mapID, topMapID)
            local a, b = m.maps[mapID], m.maps[topMapID]
            if not a or not b or a.noWorld or b.noWorld or a.continent ~= b.continent then return nil end
            local x1, y1 = worldToMap(b, a.top, a.left)
            local x2, y2 = worldToMap(b, a.top - a.height, a.left - a.width)
            return x1, x2, y1, y2
        end,
        GetAreaInfo = function(areaID) return m.areaNames[areaID] end,
        CanSetUserWaypointOnMap = function(mapID) return m:_canWaypoint(mapID) end,
        SetUserWaypoint = function(point)
            if type(point) ~= "table" or type(point.uiMapID) ~= "number" or type(point.position) ~= "table" then
                m:_violation("C_Map.SetUserWaypoint: UiMapPoint expected (UiMapPoint.CreateFromCoordinates)", 3)
            end
            local x, y = vecXY(m, point.position, "C_Map.SetUserWaypoint")
            if not m:_canWaypoint(point.uiMapID) then
                m:_violation("C_Map.SetUserWaypoint: cannot set a user waypoint on map " .. tostring(point.uiMapID)
                    .. " (check C_Map.CanSetUserWaypointOnMap first)", 3)
            end
            if x < 0 or x > 1 or y < 0 or y > 1 then
                m:_violation(("C_Map.SetUserWaypoint: position must be 0..1 map fractions, got %s, %s"):format(x, y), 3)
            end
            m.userWaypoint = { uiMapID = point.uiMapID, x = x, y = y, z = point.z }
            m:_action("SetUserWaypoint", point.uiMapID, x, y)
            m:_dispatch("USER_WAYPOINT_UPDATED")
            return true
        end,
        ClearUserWaypoint = function()
            if not m.userWaypoint then return end
            m.userWaypoint = nil
            m:_action("ClearUserWaypoint")
            m:_dispatch("USER_WAYPOINT_UPDATED")
            setSuperTrackWaypoint(false)
        end,
        HasUserWaypoint = function() return m.userWaypoint ~= nil end,
        GetUserWaypoint = function()
            local w = m.userWaypoint
            if not w then return nil end
            return { uiMapID = w.uiMapID, position = vector(w.x, w.y), z = w.z }
        end,
        GetUserWaypointPositionForMap = function(mapID)
            local w = m.userWaypoint
            if not w then return nil end
            if w.uiMapID == mapID then return vector(w.x, w.y) end
            local from, to = m.maps[w.uiMapID], m.maps[mapID]
            if not from or not to or from.noWorld or to.noWorld or from.continent ~= to.continent then return nil end
            return vector(worldToMap(to, mapToWorld(from, w.x, w.y)))
        end,
        OpenWorldMap = function(mapID) m:_action("OpenWorldMap", mapID) end,
    })
    m:ProvideNS("C_SuperTrack", {
        SetSuperTrackedUserWaypoint = function(on) setSuperTrackWaypoint(on) end,
        IsSuperTrackingUserWaypoint = function() return m.superTrack.waypoint end,
        SetSuperTrackedQuestID = function(questID)
            if m.superTrack.questID ~= questID then
                m.superTrack.questID = questID
                m:_dispatch("SUPER_TRACKING_CHANGED")
            end
        end,
        GetSuperTrackedQuestID = function() return m.superTrack.questID end,
        IsSuperTrackingQuest = function() return m.superTrack.questID ~= nil and m.superTrack.questID ~= 0 end,
        IsSuperTrackingAnything = function()
            return m.superTrack.waypoint or (m.superTrack.questID ~= nil and m.superTrack.questID ~= 0)
        end,
        ClearAllSuperTracked = function()
            local changed = m.superTrack.waypoint or m.superTrack.questID ~= nil
            m.superTrack.waypoint, m.superTrack.questID = false, nil
            if changed then m:_dispatch("SUPER_TRACKING_CHANGED") end
        end,
    })

    -- items / bags -----------------------------------------------------------
    local function cachedItem(info, fname)
        local id = m:_itemID(info)
        if not id then return nil end
        local def = m.items[id]
        if def and def.cached then return id, def end
        return id, nil
    end
    local function requestItem(id)
        if not id or m._itemLoads[id] then return end
        local def = m.items[id]
        if def and def.cached then return end
        m._itemLoads[id] = true
        m:_after(0, function()
            m._itemLoads[id] = nil
            local d = m.items[id] or m:DefineItem(id, {})
            d.cached = true
            m:_dispatch("ITEM_DATA_LOAD_RESULT", id, true)
            m:_dispatch("GET_ITEM_INFO_RECEIVED", id, true)
        end)
    end
    m._itemLoads = {}
    m:ProvideNS("C_Item", {
        GetItemCount = function(info)
            local id = m:_itemID(info)
            return id and m.bags[id] or 0
        end,
        GetItemNameByID = function(info)
            local id, def = cachedItem(info)
            if not def then requestItem(id); return nil end
            return def.name
        end,
        GetItemIconByID = function(info)
            local id = m:_itemID(info)
            local def = id and m.items[id]
            return def and def.icon or 134400
        end,
        GetItemQualityByID = function(info)
            local _, def = cachedItem(info)
            return def and def.quality or nil
        end,
        RequestLoadItemDataByID = function(info) requestItem(m:_itemID(info)) end,
        IsItemDataCachedByID = function(info)
            local _, def = cachedItem(info)
            return def ~= nil
        end,
        GetItemInfo = function(info)
            local id, def = cachedItem(info)
            if not def then requestItem(id); return nil end
            return def.name, m:_itemLink(id), def.quality, def.itemLevel or 1, def.minLevel or 0,
                def.itemType or "Quest", def.itemSubType or "Quest", def.stackCount or 20, def.equipLoc or "",
                def.icon, def.sellPrice or 0, def.classID or 12, def.subclassID or 0, def.bindType or 4, 0, nil, false,
                def.description or ""
        end,
        GetItemInfoInstant = function(info)
            local id = m:_itemID(info)
            if not id then return nil end
            local def = m.items[id] or {}
            return id, def.itemType or "Quest", def.itemSubType or "Quest", def.equipLoc or "", def.icon or 134400,
                def.classID or 12, def.subclassID or 0
        end,
    })
    local BACKPACK_SLOTS = opts.backpackSlots or 16
    m:ProvideNS("C_Container", {
        GetContainerNumSlots = function(bag)
            if bag == 0 then return BACKPACK_SLOTS end
            return 0
        end,
        GetContainerNumFreeSlots = function(bag)
            if bag == 0 then return math.max(0, BACKPACK_SLOTS - #m:_bagSlots()), 0 end
            return 0, 0
        end,
        GetContainerItemID = function(bag, slot)
            if bag ~= 0 then return nil end
            return m:_bagSlots()[slot]
        end,
        GetContainerItemLink = function(bag, slot)
            if bag ~= 0 then return nil end
            local id = m:_bagSlots()[slot]
            return id and m:_itemLink(id) or nil
        end,
        GetContainerItemInfo = function(bag, slot)
            if bag ~= 0 then return nil end
            local id = m:_bagSlots()[slot]
            if not id then return nil end
            local def = m.items[id] or {}
            return {
                iconFileID = def.icon or 134400, stackCount = m.bags[id], isLocked = false,
                quality = def.quality, isReadable = false, hasLoot = false, hyperlink = m:_itemLink(id),
                isFiltered = false, hasNoValue = false, itemID = id, isBound = false, itemName = def.name,
            }
        end,
    })

    -- spells -----------------------------------------------------------------
    local function spellDef(id)
        if type(id) == "string" then
            for _, d in pairs(m.spellDB) do if d.name == id then return d end end
            return nil
        end
        return m.spellDB[id] or (type(id) == "number" and { id = id, name = "Spell " .. id, icon = 136243 }) or nil
    end
    m:ProvideNS("C_SpellBook", {
        IsSpellKnown = function(spellID) return m.spells[spellID] == true end,
        IsSpellInSpellBook = function(spellID) return m.spells[spellID] == true end,
    })
    m:ProvideNS("C_Spell", {
        GetSpellName = function(id)
            local d = spellDef(id)
            return d and d.name or nil
        end,
        GetSpellTexture = function(id)
            local d = spellDef(id)
            if not d then return nil end
            return d.icon, d.icon
        end,
        GetSpellInfo = function(id)
            local d = spellDef(id)
            if not d then return nil end
            return { name = d.name, iconID = d.icon, originalIconID = d.icon, castTime = 0, minRange = 0,
                maxRange = 0, spellID = d.id }
        end,
        DoesSpellExist = function(id) return spellDef(id) ~= nil end,
    })

    -- creature info ----------------------------------------------------------
    m:ProvideNS("C_CreatureInfo", {
        GetRaceInfo = function(raceID)
            for file, rid in pairs(Mock.RACE_IDS) do
                if rid == raceID then return { raceName = RACE_NAMES[file], clientFileString = file, raceID = rid } end
            end
            if raceID == 95 or raceID == 96 then
                return { raceName = "Skyborne", clientFileString = "Skyborne", raceID = raceID }
            end
            return nil
        end,
        GetClassInfo = function(classID)
            for file, cid in pairs(Mock.CLASS_IDS) do
                if cid == classID then return { className = CLASS_NAMES[file], classFile = file, classID = cid } end
            end
            return nil
        end,
    })

    -- trainer ----------------------------------------------------------------
    local function trainer() return m.interaction and m.interaction.kind == "trainer" and m.interaction or nil end
    m:ProvideAPI("GetNumTrainerServices", function()
        local t = trainer()
        return t and #t.services or 0
    end)
    m:ProvideAPI("GetTrainerServiceInfo", function(i)
        local t = trainer()
        local s = t and t.services[i]
        if not s then return nil end
        return s.name, s.rank or "", s.category or "available", false
    end)
    m:ProvideAPI("GetTrainerServiceCost", function(i)
        local t = trainer()
        local s = t and t.services[i]
        return s and s.cost or 0, 0, 0
    end)
    m:ProvideAPI("SelectTrainerService", function(i)
        local t = trainer()
        if t then t.selected = i end
    end)
    m:ProvideAPI("BuyTrainerService", function(i)
        local t = trainer()
        local s = t and t.services[i]
        m:_action("BuyTrainerService", i, s and s.name)
        if not s or (s.category or "available") ~= "available" then
            m:_warn("BuyTrainerService(" .. tostring(i) .. "): service not available")
            return
        end
        if (s.cost or 0) > (p.money or 0) then
            m:_dispatch("UI_ERROR_MESSAGE", 1, "You don't have enough money.")
            return
        end
        p.money = (p.money or 0) - (s.cost or 0)
        s.category = "used"
        if s.spellID then
            m.spells[s.spellID] = true
            m:_dispatch("LEARNED_SPELL_IN_SKILL_LINE", s.spellID, 1, false)
            m:_dispatch("SPELLS_CHANGED")
        end
        if (s.cost or 0) > 0 then m:_dispatch("PLAYER_MONEY") end
        m:_dispatch("TRAINER_UPDATE")
    end)
    m:ProvideAPI("CloseTrainer", function() m:_closeTrainer() end)

    -- merchant -----------------------------------------------------------------
    local function merchant() return m.interaction and m.interaction.kind == "merchant" and m.interaction or nil end
    m:ProvideAPI("GetMerchantNumItems", function()
        local v = merchant()
        return v and #v.items or 0
    end)
    m:ProvideAPI("GetMerchantItemID", function(i)
        local v = merchant()
        return v and v.items[i] and v.items[i].itemID or nil
    end)
    m:ProvideAPI("BuyMerchantItem", function(i, quantity)
        local v = merchant()
        local it = v and v.items[i]
        m:_action("BuyMerchantItem", i, quantity)
        if not it then return end
        local cost = (it.price or 0) * (quantity or 1)
        if cost > (p.money or 0) then return end
        p.money = (p.money or 0) - cost
        m:_changeItem(it.itemID, quantity or 1)
        if cost > 0 then m:_dispatch("PLAYER_MONEY") end
    end)
    m:ProvideAPI("CloseMerchant", function() m:_closeMerchant() end)

    -- taxi -----------------------------------------------------------------------
    local function taxi() return m.interaction and m.interaction.kind == "taxi" and m.interaction or nil end
    local function node(i)
        local t = taxi()
        return t and t.nodes[i] or nil
    end
    m:ProvideAPI("NumTaxiNodes", function()
        local t = taxi()
        return t and #t.nodes or 0
    end)
    m:ProvideAPI("TaxiNodeName", function(i)
        local n = node(i)
        return n and n.name or "INVALID"
    end)
    m:ProvideAPI("TaxiNodeGetType", function(i)
        local n = node(i)
        return n and (n.state or "REACHABLE") or "NONE"
    end)
    m:ProvideAPI("TaxiNodePosition", function(i)
        local n = node(i)
        if not n then return 0, 0 end
        return n.x or 0.5, n.y or 0.5
    end)
    m:ProvideAPI("TaxiNodeCost", function(i)
        local n = node(i)
        return n and n.cost or 0
    end)
    m:ProvideAPI("TaxiIsDirectFlight", function(i) return node(i) ~= nil end)
    m:ProvideAPI("GetNumRoutes", function(i) return node(i) and 1 or 0 end)
    m:ProvideAPI("TaxiGetNodeSlot", function(i) return i end)
    m:ProvideAPI("GetTaxiMapID", function()
        local t = taxi()
        return t and (t.mapID or p.mapID) or nil
    end)
    m:ProvideAPI("TakeTaxiNode", function(i)
        local n = node(i)
        m:_action("TakeTaxiNode", i, n and n.name)
        if not n or (n.state or "REACHABLE") ~= "REACHABLE" then
            m:_warn("TakeTaxiNode(" .. tostring(i) .. "): node is not reachable")
            return
        end
        if (n.cost or 0) > (p.money or 0) then return end
        p.money = (p.money or 0) - (n.cost or 0)
        m:_closeTaxi()
        p.onTaxi = true
        m.flight = { node = n, mapID = n.mapID, x = n.destX, y = n.destY }
        m:_dispatch("PLAYER_CONTROL_LOST")
        if n.flightTime then m:_after(n.flightTime, function() if p.onTaxi then m:_land() end end) end
    end)
    m:ProvideAPI("CloseTaxiMap", function() m:_closeTaxi() end)
    m:ProvideNS("C_TaxiMap", {
        GetAllTaxiNodes = function(uiMapID)
            local t = taxi()
            local out = {}
            local STATE = { CURRENT = 0, REACHABLE = 1, DISTANT = 2, NONE = 2 }
            for i, n in ipairs(t and t.nodes or {}) do
                out[#out + 1] = {
                    nodeID = n.nodeID, position = vector(n.x or 0.5, n.y or 0.5), name = n.name,
                    state = STATE[n.state or "REACHABLE"] or 1, slotIndex = i, textureKit = "",
                    useSpecialIcon = false, isMapLayerTransition = false,
                }
            end
            return out
        end,
        GetTaxiNodesForMap = function(uiMapID)
            local out = {}
            for _, id in ipairs(U.sortedKeys(m.knownTaxiNodes)) do
                local n = m.knownTaxiNodes[id]
                if n.mapID == uiMapID then
                    out[#out + 1] = { nodeID = n.nodeID, position = vector((n.destX or 50) / 100, (n.destY or 50) / 100),
                        name = n.name, atlasName = "TaxiNode_Neutral", faction = 0, textureKit = "" }
                end
            end
            return out
        end,
    })

    -- player interaction manager -------------------------------------------------
    local KIND_TYPE = {
        trainer = PIT.Trainer, merchant = PIT.Merchant, taxi = PIT.TaxiNode, binder = PIT.Binder,
        gossip = PIT.Gossip, quest = PIT.QuestGiver, greeting = PIT.QuestGiver,
    }
    m:ProvideNS("C_PlayerInteractionManager", {
        IsInteractingWithNpcOfType = function(t)
            return m.interaction ~= nil and KIND_TYPE[m.interaction.kind] == t
        end,
        ClearInteraction = function(t)
            if m.interaction and (t == nil or KIND_TYPE[m.interaction.kind] == t) then
                local it = m.interaction
                if it.kind == "trainer" then m:_closeTrainer()
                elseif it.kind == "merchant" then m:_closeMerchant()
                elseif it.kind == "taxi" then m:_closeTaxi()
                elseif m._closeQuestInteraction then m:_closeQuestInteraction() end
            end
        end,
        ConfirmationInteraction = function(t)
            if t == PIT.Binder then
                m:_action("ConfirmBinder")
                m:_confirmBinder()
            end
        end,
        IsValidNPCInteraction = function(t) return KIND_TYPE[m.interaction and m.interaction.kind or ""] == t end,
    })

    m:ProvideNS("C_RestrictedActions", {
        IsAddOnRestrictionActive = function(t) return m.restrictions[t] == true end,
    })
    m.restrictions = U.deepcopy(opts.restrictions or {})

    m:ProvideNS("C_Secrets", {
        HasSecretRestrictions = function() return m.secretUnits end,
        ShouldUnitIdentityBeSecret = function(unit) return m.secretUnits and unit ~= "player" end,
    })
end)

--- Make non-player unit identity (GUID, name, level) secret values, like restricted
-- content in the client; issecretvalue() is true for them.
function M:SetSecretUnits(on) self.secretUnits = on and true or false end

--- Activate an addon restriction (Enum.AddOnRestrictionType: Combat 0, Encounter 1,
-- ChallengeMode 2, PvPMatch 3, Map 4, Chat 5); fires ADDON_RESTRICTION_STATE_CHANGED.
function M:SetRestriction(rtype, active)
    return self:_top(function()
        self.restrictions[rtype] = active and true or nil
        self:_dispatch("ADDON_RESTRICTION_STATE_CHANGED", rtype, active and 1 or 0)
    end)
end
