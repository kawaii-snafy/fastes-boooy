-- luacheck: std lua51+busted
-- tests/fixtures/core/helpers.lua -- shared setup for the tests/spec/core_*_spec.lua specs.
--
--   local H = require("fixtures.core.helpers")      -- busted lpath has ./tests/?.lua
--   local m, ns = H.boot()                           -- mock + core addon + test route, logged in
--   H.settle(m)                                      -- run the throttled refresh / tickers
--   H.cur(ns)                                        -- id of the displayed step
--
-- Not a route module (the FastesBoooy_* directories next to this file are).

local Mock = require("mocks.wow")

local H = {}

H.CORE_TOC = "addons/FastesBoooy/FastesBoooy.toc"
H.FIXTURE_DIR = "tests/fixtures/core/FastesBoooy_TestRoute"
H.FIXTURE_TOC = H.FIXTURE_DIR .. "/FastesBoooy_TestRoute.toc"
H.FIXTURE_NAME = "FastesBoooy_TestRoute"
H.ROUTE_ID = "test-route"
H.DB_FILE = "tools/data/forever_db.lua"

H.Mock = Mock

-- Filtered step ids of the test route for Scourge / PALADIN / Horde, in order.
H.STEP_IDS = {
    "tr-accept-363", "tr-363-364", "tr-bg-364", "tr-train-1", "tr-complete-364", "tr-turnin-364",
    "tr-level-2", "tr-accept-376", "tr-bg-collect", "tr-collect-376", "tr-complete-3901",
    "tr-turnin-3901-376", "tr-optional", "tr-abandon-3902", "tr-complete-380", "tr-turnin-380",
    "tr-level-4", "tr-go-brill", "tr-sethearth", "tr-vendor", "tr-train-2", "tr-go-uc", "tr-fp-uc",
    "tr-fly", "tr-hearth", "tr-manual",
}
H.INDEX = {}
for i, id in ipairs(H.STEP_IDS) do H.INDEX[id] = i end

-- Composed fixture: route "test-composed" (FastesBoooy_TestComposed) = own segments +
-- library segments of FastesBoooy_TestLib (UseSegments) + class inserts (AddInsert).
H.LIB_DIR = "tests/fixtures/core/FastesBoooy_TestLib"
H.LIB_NAME = "FastesBoooy_TestLib"
H.LIB_TOC = H.LIB_DIR .. "/" .. H.LIB_NAME .. ".toc"
H.COMPOSED_DIR = "tests/fixtures/core/FastesBoooy_TestComposed"
H.COMPOSED_NAME = "FastesBoooy_TestComposed"
H.COMPOSED_TOC = H.COMPOSED_DIR .. "/" .. H.COMPOSED_NAME .. ".toc"
H.COMPOSED_ID = "test-composed"
-- every composed step id in route order (route.steps), with its segment
H.COMPOSED_ALL = {
    { "tc-welcome", "tc-intro" }, { "tc-intro-go", "tc-intro" },
    { "tl-accept-363", "tl-deathknell" }, { "tl-363-364", "tl-deathknell" },
    { "tc-train-1", "tl-deathknell" }, { "tc-vendor-1", "tl-deathknell" },
    { "tl-complete-364", "tl-deathknell" }, { "tl-turnin-364", "tl-deathknell" },
    { "tc-level-2", "tl-deathknell" }, { "tl-accept-376", "tl-deathknell" }, { "tl-bg-376", "tl-deathknell" },
    { "tl-complete-3901", "tl-deathknell" }, { "tl-turnin-3901+1", "tl-deathknell" },
    { "tl-turnin-3901", "tl-deathknell" }, { "tl-turnin-376", "tl-deathknell" },
    { "tc-train-4", "tc-class" }, { "tc-vendor-4", "tc-class" },
    { "tl-complete-3902", "tl-brill" }, { "tl-complete-380", "tl-brill" }, { "tl-turnin-3902", "tl-brill" },
    { "tl-turnin-380", "tl-brill" }, { "tl-complete-381", "tl-brill" }, { "tl-turnin-381", "tl-brill" },
    { "tl-optional", "tl-brill" }, { "tl-go-brill", "tl-brill" }, { "tl-sethearth", "tl-brill" },
    { "tc-warrior-only", "tl-brill" },
}
-- filtered step ids for Scourge / PALADIN / Horde (tc-warrior-only is a WARRIOR insert)
H.COMPOSED_IDS = {}
for _, e in ipairs(H.COMPOSED_ALL) do
    if e[1] ~= "tc-warrior-only" then H.COMPOSED_IDS[#H.COMPOSED_IDS + 1] = e[1] end
end

local dbCache
--- tools/data/forever_db.lua (loaded once per process).
function H.db()
    if not dbCache then
        local FBDB = require("lib.fbdb")
        dbCache = FBDB.Load(H.DB_FILE)
    end
    return dbCache
end

--- Quest data of the test route with known objectives (independent of the DB snapshot).
function H.defineQuests(m)
    m:DefineQuest(363, { title = "Rude Awakening", level = 1, xp = 40 })
    m:DefineQuest(364, { title = "The Mindless Ones", level = 2, xp = 170,
        objectives = { { text = "Mindless Zombie slain", required = 5 }, { text = "Wretched Zombie slain", required = 5 } } })
    m:DefineQuest(3901, { title = "Rattling the Rattlecages", level = 3, xp = 250,
        objectives = { { text = "Rattlecage Skeleton slain", required = 8 } } })
    m:DefineQuest(376, { title = "The Damned", level = 2, xp = 170,
        objectives = { { text = "Scavenger Paw", required = 6, itemID = 3265 },
                       { text = "Duskbat Wing", required = 6, itemID = 3264 } } })
    m:DefineQuest(380, { title = "Night Web's Hollow", level = 4, xp = 360,
        objectives = { { text = "Young Night Web Spider slain", required = 8 },
                       { text = "Night Web Spider slain", required = 5 } } })
    m:DefineQuest(3902, { title = "Scavenging Deathknell", level = 3, xp = 320,
        objectives = { { text = "Scavenged Goods", required = 6, itemID = 11127 } } })
    m:DefineItem(3264, { name = "Duskbat Wing" })
    m:DefineItem(3265, { name = "Scavenger Paw" })
    m:DefineItem(2876, { name = "Duskbat Pelt" })
    m:DefineItem(11127, { name = "Scavenged Goods" })
end

--- Route / library modules a helper boot loads after the core: { { toc, name }, ... }.
-- opts.modules overrides; opts.composed = the library + the composed route; opts.fixture ==
-- false = none; default = the test route.
function H.modules(opts)
    opts = opts or {}
    if opts.modules then return opts.modules end
    if opts.fixture == false then return {} end
    if opts.composed then
        return { { H.LIB_TOC, H.LIB_NAME }, { H.COMPOSED_TOC, H.COMPOSED_NAME } }
    end
    return { { H.FIXTURE_TOC, H.FIXTURE_NAME } }
end

local function bootList(opts)
    local addons = { "FastesBoooy" }
    for _, mod in ipairs(H.modules(opts)) do addons[#addons + 1] = mod[2] end
    return addons
end

--- Create a mock with the core addon (and the test route unless opts.fixture == false) loaded.
-- opts: locale, player = {...}, savedVariables, db (use the Forever DB snapshot), quests
-- (define the test route quests, default true), fixture, composed (load the library +
-- composed route instead), modules (see H.modules), mock = { extra Mock.new options },
-- register = function(api, m) -- registers routes through the public FastesBoooy API after the
-- modules are loaded (before ADDON_LOADED / PLAYER_LOGIN), like a route module would.
function H.new(opts)
    opts = opts or {}
    local player = { race = "Scourge", class = "PALADIN", faction = "Horde", mapID = 1420, x = 30.2, y = 71.7 }
    for k, v in pairs(opts.player or {}) do player[k] = v end
    local mo = { locale = opts.locale or "enUS", player = player, savedVariables = opts.savedVariables }
    for k, v in pairs(opts.mock or {}) do mo[k] = v end
    local m = Mock.new(mo)
    if opts.db then m:UseForeverDB(H.db()) end
    if opts.quests ~= false then H.defineQuests(m) end
    if opts.setup then opts.setup(m) end
    local ns = Mock.loadAddon(m, H.CORE_TOC)
    for _, mod in ipairs(H.modules(opts)) do Mock.loadAddon(m, mod[1], mod[2]) end
    if opts.register then
        m:_top(function() opts.register(rawget(m.env, "FastesBoooy"), m) end)
    end
    return m, ns
end

--- H.new + boot (ADDON_LOADED, PLAYER_LOGIN, PLAYER_ENTERING_WORLD) + settle.
function H.boot(opts)
    opts = opts or {}
    local m, ns = H.new(opts)
    Mock.boot(m, bootList(opts), { reload = opts.reload })
    H.settle(m)
    return m, ns
end

--- /reload: a new client with the SavedVariables and the game state of `m`.
function H.reload(m, opts)
    opts = opts or {}
    local sv = (opts.coldStart and {}) or m:ExportSavedVariables()
    local U = Mock.util
    local m2, ns2 = H.new({
        locale = opts.locale, savedVariables = sv, quests = false, fixture = opts.fixture,
        composed = opts.composed, modules = opts.modules, register = opts.register,
        player = { level = m.player.level, xp = m.player.xp, mapID = m.player.mapID, x = m.player.x, y = m.player.y,
            inCombat = m.player.inCombat },
        setup = function(n)
            n.questDB = U.deepcopy(m.questDB)
            n.questCache = U.deepcopy(m.questCache)
            n.questLog = U.deepcopy(m.questLog)
            n.completed = U.deepcopy(m.completed)
            n.items = U.deepcopy(m.items)
            n.bags = U.deepcopy(m.bags)
            n._bagOrder = U.deepcopy(m._bagOrder)
            n._bagSeq = m._bagSeq
            n.bind = U.deepcopy(m.bind)
        end,
    })
    Mock.boot(m2, bootList(opts), { reload = not opts.coldStart })
    H.settle(m2)
    return m2, ns2
end

function H.settle(m, seconds)
    m:Advance(seconds or 0.5)
end

--- Longest wait of one delayed automation action with the current settings:
-- autoDelay + autoDelayJitter + one mock frame (0 when the automation acts at once).
function H.autoWait(ns)
    local s = ns.db.settings
    if (s.autoDelay or 0) <= 0 then return 0 end
    return s.autoDelay + (s.autoDelayJitter or 0) + 0.05
end

--- Let the delayed quest automation act (Core/Automation.lua): advance the mock clock by
-- H.autoWait while an action is scheduled (one dialog may chain several: gossip -> quest
-- window -> reward -> gossip again ...). Returns the number of waits.
function H.waitAuto(m, ns, max)
    local n = 0
    while ns.Automation:GetPending() do
        n = n + 1
        assert(n <= (max or 20), "the automation keeps scheduling actions")
        m:Advance(H.autoWait(ns))
    end
    return n
end

--- Id of the displayed step (or "<end>").
function H.cur(ns)
    local s = ns.Engine:GetCurrentStep()
    return s and s.id or "<end>"
end

--- Ids of an array of steps.
function H.ids(steps)
    local out = {}
    for i, s in ipairs(steps or {}) do out[i] = s.id end
    return out
end

--- Chat lines (prefix stripped) printed since index `from` (default 1).
function H.chat(m, from)
    local out = {}
    for i = from or 1, #m.chat do
        out[#out + 1] = (m.chat[i]:gsub("^|cff33ff99Fastes|r|cffffd100Boooy|r: ", ""))
    end
    return out
end

--- Does any chat line since `from` contain `text` (plain find)?
function H.chatHas(m, text, from)
    for _, l in ipairs(H.chat(m, from)) do
        if l:find(text, 1, true) then return true end
    end
    return false
end

--- Player-intent API calls recorded by the mock since `mark` (index into m.actions).
function H.actionsSince(m, mark, name)
    local out = {}
    for i = (mark or 0) + 1, #m.actions do
        local a = m.actions[i]
        if name == nil or a[1] == name then out[#out + 1] = a end
    end
    return out
end

--- Collect internal messages fired through ns:Fire (ns:Listen) into a list.
function H.record(ns, msg)
    local list = {}
    ns:Listen(msg, function(_, ...)
        list[#list + 1] = { n = select("#", ...), ... }
    end)
    return list
end

--- Play the test route up to (not including) step `id` with the quest flow of the mock.
-- Uses the mock directly (server side) so engine specs start from a known state. Any
-- active route: the index comes from the engine (H.INDEX for the test route).
function H.playTo(m, ns, id)
    local stop = H.INDEX[id]
    local active = ns.Engine:GetRoute()
    if not stop or (active and active.id ~= H.ROUTE_ID) then stop = ns.Engine:IndexOf(id) end
    assert(stop, "unknown step id " .. tostring(id))
    for _ = 1, 60 do
        local cur = ns.Engine:GetCursor()
        if not cur or cur >= stop then break end
        local step = ns.Engine:GetCurrentStep()
        H.perform(m, ns, step)
        H.settle(m)
    end
    assert(ns.Engine:GetCursor() == stop, ("playTo %s: cursor on %s"):format(id, H.cur(ns)))
end

--- Do what one step of the test route asks for (server side; no automation involved).
function H.perform(m, ns, step)
    for _, a in ipairs(step.actions) do
        local t = a.type
        if t == "accept" then
            if not m:IsOnQuest(a.quest) and not m:IsQuestCompleted(a.quest) then m:AddQuestToLog(a.quest) end
        elseif t == "turnin" then
            if m:IsOnQuest(a.quest) then m:CompleteObjectives(a.quest); m:TurnInQuest(a.quest) end
        elseif t == "complete" then
            if a.objectives then
                for _, i in ipairs(a.objectives) do m:ProgressObjective(a.quest, i, 99) end
            else
                m:CompleteObjectives(a.quest)
            end
        elseif t == "abandon" then
            if m:IsOnQuest(a.quest) then m:AbandonQuest(a.quest) end
        elseif t == "collect" then
            local need = a.count - m:GetItemCount(a.item)
            if need > 0 then m:AddItem(a.item, need) end
        elseif t == "level" then
            local want = math.ceil((a.frac or 0) * m:XPMax(a.level))
            if m.player.level < a.level then m:SetLevel(a.level, want)
            elseif m.player.level == a.level and m.player.xp < want then m:GiveXP(want - m.player.xp) end
        elseif t == "go" or t == "hearth" then
            m:MoveTo(step.at.map, step.at.x, step.at.y)
        elseif t == "fly" then
            m:MoveTo(step.at.map, step.at.x, step.at.y)
        elseif t == "train" then
            m:OpenTrainer({}, step.npc and step.npc[1]); m:CloseTrainer()
        elseif t == "fp" then
            m:OpenTaxi({ { name = a.place, state = "CURRENT" } }, step.npc and step.npc[1]); m:CloseTaxi()
        elseif t == "vendor" then
            m:OpenMerchant({}, step.npc and step.npc[1]); m:CloseMerchant()
        elseif t == "sethearth" then
            m:SetBindLocation(a.place, step.at and step.at.map, step.at and step.at.x, step.at and step.at.y)
        elseif t == "manual" then
            ns.Engine:Next()
        end
    end
end

return H
