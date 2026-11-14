-- The atlas window (UI/Atlas.lua), its minimap button (UI/MinimapButton.lua) and the chapter
-- list of the engine (Engine:GetChapters) on the strict widget mock, test route of
-- tests/fixtures/core (segments tr-01 Deathknell, tr-02 Brill, tr-03 Travel).

local H = require("fixtures.core.helpers")

local m, ns

local function atlas() return ns.Atlas end
local function button() return ns.MinimapButton:GetButton() end
local function texts() return m:VisibleTexts(atlas():GetFrame()) end

local function has(list, text)
    for _, v in ipairs(list) do
        if v == text then return true end
    end
    return false
end

local function slash(text)
    local mark = #m.chat
    assert.is_true(m:RunSlash(text), text)
    return H.chat(m, mark + 1)
end

-- steps of the test route that are not background goals, and the done ones of them, per segment;
-- segment ids in route order
local function expectedTotals()
    local totals, done, order = {}, {}, {}
    for i, s in ipairs(ns.Engine:GetSteps()) do
        if not totals[s.segment] then
            totals[s.segment], done[s.segment] = 0, 0
            order[#order + 1] = s.segment
        end
        if not s.bg then
            totals[s.segment] = totals[s.segment] + 1
            if ns.Engine:IsDone(i) then done[s.segment] = done[s.segment] + 1 end
        end
    end
    return totals, order, done
end

describe("Engine:GetChapters", function()
    after_each(function() m:AssertClean() end)

    it("lists the segment runs with their progress and marks the current one", function()
        m, ns = H.boot()
        local chapters = ns.Engine:GetChapters()
        local totals, order, done = expectedTotals()
        assert.same({ "tr-01", "tr-02", "tr-03" }, order)
        assert.equal(1, done["tr-01"]) -- tr-abandon-3902: the quest is not in the log
        assert.equal(3, #chapters)
        for i, ch in ipairs(chapters) do
            assert.equal(order[i], ch.id)
            assert.equal(totals[ch.id], ch.total)
            assert.equal(done[ch.id], ch.done)
            assert.equal(i == 1, ch.current)
        end
        assert.is_true(totals["tr-01"] < #H.STEP_IDS) -- background goals are not counted
        assert.equal("1-4 Deathknell", ns.UI.Text(chapters[1].seg.title))

        H.playTo(m, ns, "tr-go-brill")
        chapters = ns.Engine:GetChapters()
        assert.equal(chapters[1].total, chapters[1].done)
        assert.is_false(chapters[1].current)
        assert.is_true(chapters[2].current)
    end)

    it("is empty without a route", function()
        m, ns = H.boot({ fixture = false })
        assert.same({}, ns.Engine:GetChapters())
    end)
end)

describe("minimap button", function()
    after_each(function() m:AssertClean() end)

    it("sits on the minimap rim and toggles the atlas; right click opens the settings", function()
        m, ns = H.boot()
        local b = button()
        assert.equal(m.env.Minimap, b:GetParent())
        assert.is_true(m:IsWidgetVisible(b))
        local point, rel = b:GetPoint(1)
        assert.equal("CENTER", point)
        assert.equal(m.env.Minimap, rel)

        assert.is_false(atlas():IsShown())
        m:Click(b, "LeftButton")
        assert.is_true(atlas():IsShown())
        m:Click(b, "LeftButton")
        assert.is_false(atlas():IsShown())

        m:Click(b, "RightButton")
        assert.is_truthy(m.settingsOpened)
        assert.is_false(atlas():IsShown())
    end)

    it("explains itself in the tooltip (ruRU)", function()
        m, ns = H.boot({ locale = "ruRU" })
        m:Enter(button())
        local lines = m:TooltipLines()
        assert.equal("Adventure Atlas", lines[1])
        assert.is_true(has(lines, "Левый клик: открыть / закрыть атлас"))
        assert.is_true(has(lines, "Правый клик: настройки"))
        assert.is_true(has(lines, "Перетаскивание: сдвинуть кнопку"))
        m:Leave(button())
        ns.UI.SetSetting("locked", true)
        m:Enter(button())
        assert.is_false(has(m:TooltipLines(), "Перетаскивание: сдвинуть кнопку"))
        m:Leave(button())
    end)

    it("is dragged along the rim and keeps its angle over a reload, unless the windows are locked", function()
        m, ns = H.boot()
        local mm = m.env.Minimap
        mm:SetSize(140, 140)
        mm:SetPoint("TOPRIGHT", m.env.UIParent, "TOPRIGHT", 0, 0)
        -- the mock puts a region's center at (width / 2, height / 2): cursor straight above it
        m:ProvideAPI("GetCursorPosition", function() return 70, 170 end)
        local b = button()
        b:GetScript("OnDragStart")(b)
        m:Advance(0)
        b:GetScript("OnDragStop")(b)
        assert.near(90, ns.MinimapButton:GetAngle(), 1e-6)
        local _, _, _, x, y = b:GetPoint(1)
        assert.near(0, x, 1e-6)
        assert.near(70 + 5, y, 1e-6) -- radius = half the minimap width + the rim offset

        local m2, ns2 = H.reload(m)
        m, ns = m2, ns2
        assert.near(90, ns.MinimapButton:GetAngle(), 1e-6)

        ns.UI.SetSetting("locked", true)
        m:ProvideAPI("GetCursorPosition", function() return 170, 70 end)
        b = button()
        b:GetScript("OnDragStart")(b)
        m:Advance(0)
        b:GetScript("OnDragStop")(b)
        assert.near(90, ns.MinimapButton:GetAngle(), 1e-6)
    end)

    it("follows the cursor under a scaled minimap and stops following when hidden mid-drag", function()
        m, ns = H.boot()
        local mm = m.env.Minimap
        mm:SetSize(140, 140)
        mm:SetPoint("TOPRIGHT", m.env.UIParent, "TOPRIGHT", 0, 0)
        mm:SetScale(2)
        -- cursor positions are screen pixels: the center (70, 70) times the effective scale 2, then
        -- straight to the left of it
        m:ProvideAPI("GetCursorPosition", function() return 40, 140 end)
        local b = button()
        b:GetScript("OnDragStart")(b)
        m:Advance(0)
        assert.near(180, ns.MinimapButton:GetAngle(), 1e-6)
        b:Hide()                                        -- no OnDragStop for a hidden frame
        b:Show()
        m:ProvideAPI("GetCursorPosition", function() return 140, 240 end)
        m:Advance(0)
        assert.near(180, ns.MinimapButton:GetAngle(), 1e-6)
        assert.is_nil(b:GetScript("OnUpdate"))
    end)

    it("is hidden and shown again by /aa minimap and the setting", function()
        m, ns = H.boot()
        assert.same({ "Minimap button hidden. Type /aa minimap to bring it back." }, slash("/aa minimap"))
        assert.is_false(ns.db.settings.minimapButton)
        assert.is_false(button():IsShown())
        assert.same({ "Minimap button shown." }, slash("/aa minimap"))
        assert.is_true(button():IsShown())
        ns.UI.SetSetting("minimapButton", false)
        assert.is_false(button():IsShown())
        m, ns = H.reload(m)
        assert.is_false(button():IsShown())
    end)
end)

describe("atlas window", function()
    after_each(function() m:AssertClean() end)

    it("opens on 'Your adventure' with the route, its progress and chapters", function()
        m, ns = H.boot()
        atlas():Open()
        local t = texts()
        assert.is_true(has(t, "Adventure Atlas"))
        assert.is_true(has(t, "Your adventure"))
        assert.is_true(has(t, "Knowledge base"))
        assert.is_true(has(t, "Test route"))
        assert.is_true(has(t, "Chapters of the route"))
        local totals = expectedTotals()
        local all = totals["tr-01"] + totals["tr-02"] + totals["tr-03"]
        assert.is_true(has(t, ("Level 1 - steps done: 1 of %d (%d%%)"):format(all, math.floor(100 / all))))
        assert.is_true(has(t, "1-4 Deathknell"))
        assert.is_true(has(t, "4-5 Brill"))
        assert.is_true(has(t, "Travel"))
        assert.is_true(has(t, ("1/%d"):format(totals["tr-01"])))
        assert.is_true(has(t, ">")) -- the current chapter
        assert.is_false(has(t, "+"))
    end)

    it("follows the progress while it is open", function()
        m, ns = H.boot()
        atlas():Open()
        H.playTo(m, ns, "tr-go-brill")
        local totals = expectedTotals()
        local t = texts()
        local n = totals["tr-01"]
        assert.is_true(has(t, ("%d/%d"):format(n, n)))
        assert.is_true(has(t, "+")) -- a finished chapter
        assert.is_true(has(t, ">"))
    end)

    it("says when the route is finished and marks no chapter current", function()
        m, ns = H.boot()
        atlas():Open()
        while ns.Engine:GetNaturalCursor() do ns.Engine:Skip() end
        H.settle(m)
        for _, ch in ipairs(ns.Engine:GetChapters()) do assert.is_false(ch.current) end
        local t = texts()
        assert.is_true(has(t, "Level 1 - route finished"))
        assert.is_false(has(t, ">"))
    end)

    it("shows the whole chapter title and its progress in the row tooltip", function()
        m, ns = H.boot()
        atlas():Open()
        local row = atlas():GetFrame().pages.adventure.rows[2]
        m:Enter(row)
        local lines = m:TooltipLines()
        assert.equal("4-5 Brill", lines[1])
        assert.is_true(has(lines, ("0/%d"):format(expectedTotals()["tr-02"])))
        m:Leave(row)
    end)

    it("switches tabs and remembers the tab over a reload", function()
        m, ns = H.boot()
        atlas():Open()
        local f = atlas():GetFrame()
        m:Click(f.tabs.knowledge)
        local t = texts()
        assert.is_true(has(t, "For my character")) -- the knowledge base page (tests/spec/core_knowledge_spec.lua)
        assert.is_false(has(t, "Chapters of the route"))
        assert.equal("knowledge", atlas():SelectedTab())

        m, ns = H.reload(m)
        atlas():Open()
        assert.equal("knowledge", atlas():SelectedTab())
        assert.is_false(has(texts(), "Chapters of the route"))
        m:Click(atlas():GetFrame().tabs.adventure)
        assert.is_true(has(texts(), "Chapters of the route"))
    end)

    it("shows and hides the guide window from the adventure tab (ruRU)", function()
        m, ns = H.boot({ locale = "ruRU" })
        atlas():Open()
        local t = texts()
        assert.is_true(has(t, "Твоё приключение"))
        assert.is_true(has(t, "База знаний"))
        assert.is_true(has(t, "Главы маршрута"))
        assert.is_true(has(t, "1-4 Мертвый Звон"))
        local toggle = atlas():GetFrame().pages.adventure.toggle
        assert.equal("Скрыть гайд", toggle:GetText())
        m:Click(toggle)
        assert.is_true(ns.UI.IsGuideHidden())
        assert.equal("Показать гайд", toggle:GetText())
        m:Click(toggle)
        assert.is_false(ns.UI.IsGuideHidden())
    end)

    it("says when the character has no route", function()
        m, ns = H.boot({ fixture = false })
        atlas():Open()
        local t = texts()
        assert.is_true(has(t, "No route for this character"))
        assert.is_true(has(t, "Level 1"))
        assert.is_true(has(t, ns.L.UI_NO_ROUTE))
    end)

    it("is closed by Escape", function()
        m, ns = H.boot()
        atlas():Open()
        assert.is_true(has(m.env.UISpecialFrames, "AdventureAtlasFrame"))
        assert.equal(atlas():GetFrame(), m.env.AdventureAtlasFrame)
        assert.is_true(m:PressEscape())
        assert.is_false(atlas():IsShown())
        assert.is_false(m:PressEscape())
    end)

    it("is toggled by /aa atlas, closed by its close button, and put back by /aa resetpos", function()
        m, ns = H.boot()
        slash("/aa atlas")
        assert.is_true(atlas():IsShown())
        local f = atlas():GetFrame()
        m:Click(f.CloseButton)
        assert.is_false(atlas():IsShown())
        slash("/aa atlas")
        assert.is_true(atlas():IsShown())
        slash("/aa atlas")
        assert.is_false(atlas():IsShown())

        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", m.env.UIParent, "TOPLEFT", 123, -50)
        ns.UI.SavePosition(f, "atlas")
        slash("/aa resetpos")
        local point, _, relPoint, x, y = f:GetPoint(1)
        assert.same({ "CENTER", "CENTER", 0, 40 }, { point, relPoint, x, y })
        local saved = ns.db.frames.atlas
        assert.same({ "CENTER", "CENTER", 0, 40 }, { saved.point, saved.relativePoint, saved.x, saved.y })
        assert.equal("adventure", saved.tab) -- the tab survives the reset
    end)

    it("keeps its dragged position over a reload, unless the windows are locked", function()
        m, ns = H.boot()
        atlas():Open()
        local f = atlas():GetFrame()
        f:GetScript("OnDragStart")(f)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", m.env.UIParent, "TOPLEFT", 100, -50)
        f:GetScript("OnDragStop")(f)

        m, ns = H.reload(m)
        atlas():Open()
        f = atlas():GetFrame()
        local point, _, relPoint, x, y = f:GetPoint(1)
        assert.same({ "TOPLEFT", "TOPLEFT", 100, -50 }, { point, relPoint, x, y })

        ns.UI.SetSetting("locked", true)
        f:GetScript("OnDragStart")(f)
        assert.is_falsy(f.isMoving)
    end)
end)
