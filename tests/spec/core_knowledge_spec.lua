-- The knowledge base: Core/Knowledge.lua (data of the load-on-demand addon AdventureAtlas_Knowledge,
-- search and filters), the "Knowledge base" tab (UI/AtlasKnowledge.lua) and the arrow to a chosen
-- quest (Waypoint:SetCustom), on the strict mock with the real generated data. The player is the
-- Scourge paladin of tests/fixtures/core (Deathknell, Tirisfal Glades).

local H = require("fixtures.core.helpers")

local KB_TOC = "addons/AdventureAtlas_Knowledge/AdventureAtlas_Knowledge.toc"

local m, ns

local function boot(opts)
    opts = opts or {}
    local setup = opts.setup
    opts.setup = function(mm)
        if opts.data ~= false then H.Mock.loadAddon(mm, KB_TOC, nil, { deferred = true }) end
        if setup then setup(mm) end
    end
    m, ns = H.boot(opts)
end

local function K() return ns.Knowledge end
local function page() return ns.Atlas:GetFrame().pages.knowledge end
local function texts() return m:VisibleTexts(ns.Atlas:GetFrame()) end

local function has(list, text)
    for _, v in ipairs(list) do
        if v == text then return true end
    end
    return false
end

local function contains(list, value)
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end

local function openTab()
    ns.Atlas:Open("knowledge")
    return page()
end

local function rowOf(id)
    for _, row in ipairs(page().rows) do
        if row.questID == id and row:IsShown() then return row end
    end
    return nil
end

describe("knowledge base data", function()
    after_each(function() m:AssertClean() end)

    it("is loaded on demand, the first time the tab opens", function()
        boot()
        assert.is_false(K():IsLoaded())
        assert.is_false(ns.Compat.IsAddOnLoaded("AdventureAtlas_Knowledge"))
        openTab()
        assert.is_true(K():IsLoaded())
        assert.is_true(ns.Compat.IsAddOnLoaded("AdventureAtlas_Knowledge"))
        assert.is_true(#K().ids > 2000)
        local q = K():Get(363)
        assert.equal("Rude Awakening", q.n)
        assert.equal("Tirisfal Glades", K():ZoneName(q.z))
    end)

    it("filters by race, class, level, text, zone, done and new", function()
        boot()
        K():Load()
        local mine = K():Search({ mine = true })
        assert.is_true(contains(mine, 363))        -- Scourge only
        assert.is_false(contains(mine, 5843))      -- Orc and Troll only
        assert.is_false(contains(mine, 1498))      -- warriors only
        local all = K():Search({})
        assert.is_true(contains(all, 5843) and contains(all, 1498))
        assert.equal(#K().ids, #all)

        local lv = K():Search({ minLevel = 10, maxLevel = 12 })
        assert.is_true(#lv > 0)
        for _, id in ipairs(lv) do
            local l = K():Get(id).l
            assert.is_true(l <= 0 or (l >= 10 and l <= 12), tostring(id))
        end

        assert.same({ 363 }, K():Search({ text = "RUDE awak" }))
        local tirisfal = K():Search({ text = "tirisfal" })
        assert.is_true(#tirisfal > 10)
        for _, id in ipairs(tirisfal) do
            local q = K():Get(id)
            local hit = q.n:lower():find("tirisfal", 1, true) or K():ZoneName(q.z) == "Tirisfal Glades"
            assert.is_truthy(hit, tostring(id))
        end

        m:SetCompletedQuests({ 363 })
        assert.is_false(contains(K():Search({ mine = true, hideDone = true }), 363))
        assert.equal("done", K():Status(363))

        local new = K():Search({ onlyNew = true })
        assert.is_true(#new > 100)
        for _, id in ipairs(new) do assert.is_true(K():Get(id).new, tostring(id)) end
    end)

    it("checks the Skyborne race bit by faction, the faction of the data and class zone names", function()
        boot()
        K():Load()
        local q = K():Get(92598) -- The Gift of Skysight: Skyborne of the Horde only (bit 2^33)
        assert.equal(2 ^ 33, q.ra)
        assert.is_true(K():IsFor(q, { race = "Skyborne", class = "DRUID", faction = "Horde" }))
        assert.is_false(K():IsFor(q, { race = "Skyborne", class = "DRUID", faction = "Alliance" }))
        assert.is_false(K():IsFor(K():Get(363), { race = "Human", class = "PALADIN", faction = "Alliance" }))
        assert.equal("Warrior", K():ZoneName(K():Get(1498).z)) -- a class quest sort: the client's class name
    end)

    it("passes the client's reason when the data addon cannot be loaded", function()
        boot({ data = false })
        local ok, why = K():Load()
        assert.is_false(ok)
        assert.equal("MISSING", why)
    end)

    it("lowers Cyrillic text for the search", function()
        boot({ data = false })
        assert.equal("долина ёжиков abc", K().LowerText("ДОЛИНА Ёжиков ABC"))
    end)

    it("rejects data without quests", function()
        boot({ data = false })
        assert.is_false(ns.public.AddKnowledge({}))
        assert.is_false(K():IsLoaded())
        m:ClearDiagnostics()
    end)
end)

describe("knowledge base tab", function()
    after_each(function() m:AssertClean() end)

    it("lists the quests for the character in level order, with the count", function()
        boot()
        local p = openTab()
        local expected = K():Search({ mine = true })
        assert.is_true(has(texts(), ("Found: %d"):format(#expected)))
        assert.equal(expected[1], p.rows[1].questID)
        assert.is_true(p.checks.mine:GetChecked())
        assert.is_true(p.slider:IsShown())
        local levels = {}
        for i = 1, 10 do levels[i] = K():Get(p.rows[i].questID).l end
        for i = 2, 10 do assert.is_true(levels[i - 1] <= levels[i]) end
    end)

    it("searches as the player types and filters with the check boxes", function()
        boot()
        local p = openTab()
        m:TypeText(p.search, "rude")
        assert.is_true(has(texts(), "Found: 1"))
        assert.equal(363, p.rows[1].questID)
        assert.is_false(p.rows[2]:IsShown())
        assert.is_false(p.searchHint:IsShown())

        p.search:SetText("")
        m:TypeText(p.search, "")
        m:TypeText(p.minBox, "58")
        assert.is_true(has(texts(), ("Found: %d"):format(#K():Search({ mine = true, minLevel = 58 }))))

        m:Click(p.checks.onlyNew)
        assert.is_true(ns.db.knowledge.onlyNew)
        for _, row in ipairs(p.rows) do
            if row:IsShown() then
                assert.is_true(K():Get(row.questID).new)
                assert.equal("NEW", row.tag:GetText())
            end
        end
    end)

    it("scrolls with the slider, filters by the highest level and brings the search hint back", function()
        boot()
        local p = openTab()
        local all = K():Search({ mine = true })
        m:DragSlider(p.slider, 50)
        assert.equal(50, p.offset)
        assert.equal(all[51], p.rows[1].questID)
        m:TypeText(p.maxBox, "5")
        assert.is_true(has(texts(), ("Found: %d"):format(#K():Search({ mine = true, maxLevel = 5 }))))
        for _, row in ipairs(p.rows) do
            if row:IsShown() then assert.is_true(K():Get(row.questID).l <= 5) end
        end
        m:TypeText(p.search, "x")
        assert.is_false(p.searchHint:IsShown())
        p.search:SetText("")
        m:TypeText(p.search, "")
        assert.is_true(p.searchHint:IsShown())
    end)

    it("shows an item-started quest of another race on the card, without a place to lead to", function()
        boot()
        local p = openTab()
        m:Click(p.checks.mine)
        assert.is_false(ns.db.knowledge.mine)
        m:TypeText(p.search, "Welcome!")
        m:Click(rowOf(5843))
        local t = texts()
        assert.is_true(has(t, "Start: item Valley of Trials Gift Voucher"))
        assert.is_true(has(t, "Not taken  -  not available to your character"))
        assert.is_false(p.leadButton:IsEnabled())
    end)

    it("refreshes once for a burst of quest titles arriving", function()
        boot()
        openTab()
        m:Advance(1) -- the titles the first drawing asked for
        local calls = 0
        local orig = K().Search
        K().Search = function(...) calls = calls + 1; return orig(...) end
        for _, id in ipairs({ 5843, 1498, 92598, 7501, 1501, 1519 }) do -- quests outside the test route
            ns:Fire("QUEST_DATA_LOADED", id, true)
        end
        assert.equal(0, calls)
        m:Advance(0.25) -- one batch (0.2 s); titles the redraw asks for come in a later batch
        assert.equal(1, calls)
        K().Search = orig
    end)

    it("scrolls the virtual list with the mouse wheel", function()
        boot()
        local p = openTab()
        local first = p.rows[1].questID
        p.list:GetScript("OnMouseWheel")(p.list, -1)
        assert.equal(3, p.offset)
        assert.equal(K():Search({ mine = true })[4], p.rows[1].questID)
        p.list:GetScript("OnMouseWheel")(p.list, 5)
        assert.equal(0, p.offset)
        assert.equal(first, p.rows[1].questID)
    end)

    it("shows the quest card and leads the arrow to the start, then away when arrived", function()
        boot()
        local p = openTab()
        m:TypeText(p.search, "rude")
        m:Click(rowOf(363))
        local t = texts()
        assert.is_true(has(t, "Rude Awakening [1]"))
        assert.is_true(has(t, "Start: Undertaker Mordo (Tirisfal Glades 30.2, 71.7)"))
        assert.is_true(has(t, "Turn in: Shadow Priest Sarvis (Tirisfal Glades 30.8, 66.2)"))
        assert.is_true(has(t, "Not taken"))
        assert.is_true(has(t, "next: The Mindless Ones"))

        m:MoveTo(1420, 50, 50)
        m:Click(p.leadButton)
        local custom = ns.Waypoint:GetCustom()
        assert.equal(363, custom.ref)
        assert.same({ map = 1420, x = 30.22, y = 71.65 }, custom.at)
        assert.equal(custom, ns.Waypoint:GetTarget().step)
        assert.equal("Stop leading", p.leadButton:GetText())

        m:MoveTo(1420, 30.22, 71.65)
        m:Advance(0.3)
        assert.is_nil(ns.Waypoint:GetCustom())
        assert.is_true(H.chatHas(m, "You have arrived: Rude Awakening: Undertaker Mordo"))
        assert.equal("Lead me there", p.leadButton:GetText())
        local target = ns.Waypoint:GetTarget()
        assert.equal(ns.Engine:GetCurrentStep(), target and target.step) -- the arrow follows the route again
    end)

    it("leads to the end of a quest in the log and can stop leading", function()
        boot()
        m:AddQuestToLog(363)
        H.settle(m)
        local p = openTab()
        m:TypeText(p.search, "rude")
        m:Click(rowOf(363))
        assert.equal(">", rowOf(363).mark:GetText())
        assert.is_true(has(texts(), "In your quest log"))
        m:Click(p.leadButton)
        assert.same({ map = 1420, x = 30.84, y = 66.2 }, ns.Waypoint:GetCustom().at)
        m:Click(p.leadButton)
        assert.is_nil(ns.Waypoint:GetCustom())
    end)

    it("does not lead to a place on another continent", function()
        boot()
        local p = openTab()
        m:TypeText(p.search, "rude")
        m:Click(rowOf(363))
        assert.is_true(p.leadButton:IsEnabled())
        m:MoveTo(1411, 50, 50) -- Durotar (Kalimdor); the quest giver is in Tirisfal Glades
        m:Fire("ZONE_CHANGED_NEW_AREA")
        assert.is_false(p.leadButton:IsEnabled())
    end)

    it("says when the data addon is missing (ruRU)", function()
        boot({ data = false, locale = "ruRU" })
        openTab()
        local t = texts()
        assert.is_true(has(t, ns.L.UI_KB_NOT_INSTALLED))
        assert.is_true(has(t, "Для моего персонажа"))
        assert.is_true(has(t, "Поиск: квест или зона"))
    end)
end)
