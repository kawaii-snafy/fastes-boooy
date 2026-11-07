-- UI smoke tests on the strict widget mock: step window, arrow, settings panel and the
-- slash commands (/fb ... incl. status and xp), in enUS and ruRU.

local H = require("fixtures.core.helpers")

local m, ns

local function UI() return ns.UI end
local function frame() return UI().StepFrame:GetFrame() end
local function arrow() return UI().Arrow:GetFrame() end
local function refresh() m:Advance(0) end

local function has(list, text)
    for _, v in ipairs(list) do
        if v == text then return true end
    end
    return false
end

local function texts(root) return m:VisibleTexts(root) end

local function slash(text)
    local mark = #m.chat
    assert.is_true(m:RunSlash(text), text)
    return H.chat(m, mark + 1)
end

local function widget(pred)
    local list = m:FindWidgets(pred)
    return list[1]
end

local function arrowTexture()
    local f = arrow()
    return widget(function(_, st) return st.type == "Texture" and st.parent == f end)
end

describe("step window", function()
    after_each(function() m:AssertClean() end)

    it("is created on DB_READY and shows the current step, the header and the next steps", function()
        m, ns = H.boot()
        local f = frame()
        assert.is_table(f)
        assert.is_true(m:IsWidgetVisible(f))
        local t = texts(f)
        for _, want in ipairs({ "Test route", "1-4 Deathknell", "1/26", "Lv 1 (0%)", "Accept: Rude Awakening",
            "Talk to Undertaker Mordo", "Next", "Turn in: Rude Awakening", "Complete: The Mindless Ones (objectives 1)",
            "Back", "Skip", "Settings" }) do
            assert.is_true(has(t, want), "missing text: " .. want .. " in " .. table.concat(t, " | "))
        end
        assert.is_false(f.prevButton:IsEnabled(), "nothing before step 1")
        assert.is_true(f.nextButton:IsEnabled())
        assert.is_true(f.skipButton:IsEnabled())
    end)

    it("lists background goals and follows the engine", function()
        m, ns = H.boot()
        m:AddQuestToLog(363)
        m:TurnInQuest(363)
        m:AddQuestToLog(364)
        m:ProgressObjective(364, 1, 2)
        H.settle(m)
        local t = texts(frame())
        assert.is_true(has(t, "Visit your class trainer"))
        assert.is_true(has(t, "Along the way"))
        assert.is_true(has(t, "Complete: The Mindless Ones (objectives 1)"))
        assert.is_true(has(t, "2/5 Mindless Zombie slain"))
        assert.is_true(has(t, "Learn: Seal of Righteousness"))
        assert.is_true(has(t, "4/26"))
    end)

    it("drives the engine with its buttons", function()
        m, ns = H.boot()
        local f = frame()
        local cdb = m.env.FastesBoooyCharDB
        m:Click(f.nextButton)
        refresh()
        assert.is_true(cdb.manual["tr-accept-363"])
        assert.equal("tr-363-364", H.cur(ns))
        assert.is_true(f.prevButton:IsEnabled())
        m:Click(f.prevButton)
        refresh()
        assert.is_nil(cdb.manual["tr-accept-363"])
        assert.equal("tr-accept-363", H.cur(ns))
        m:Click(f.skipButton)
        refresh()
        assert.is_true(cdb.skipped["tr-accept-363"])
        assert.is_true(has(texts(f), "Turn in: Rude Awakening"))
        m:Click(f.settingsButton)
        assert.equal(UI().Options:GetCategory():GetID(), m.settingsOpened)
    end)

    it("pools its rows: refreshing creates no frames", function()
        m, ns = H.boot()
        refresh()
        local n = #m.widgets
        for _ = 1, 5 do UI().StepFrame:Refresh() end
        m:AddQuestToLog(363)
        H.settle(m)
        UI().StepFrame:Refresh()
        local after = #m.widgets
        assert.is_true(after - n <= 20, "rows are only created when more lines are needed")
        n = #m.widgets
        for _ = 1, 10 do UI().StepFrame:Refresh() end
        assert.equal(n, #m.widgets)
    end)

    it("resets the tex coords of pooled row icons that switch from an atlas to an item icon", function()
        m, ns = H.boot()
        refresh()
        -- every pooled row icon held a quest atlas at least once
        H.playTo(m, ns, "tr-collect-376")
        UI().StepFrame:Refresh()
        local f = frame()
        local items = m:FindWidgets(function(w, st)
            if st.type ~= "Texture" or st.texture == nil or not m:IsWidgetVisible(w) then return false end
            local p = st.parent
            while p do
                if p == f then return true end
                p = m._W[p] and m._W[p].parent
            end
            return false
        end)
        assert.is_true(#items >= 2, "the two collect lines show item icons")
        for _, tex in ipairs(items) do
            assert.same({ 0, 0, 0, 1, 1, 0, 1, 1 }, { tex:GetTexCoord() }, "full texture, no atlas crop")
        end
    end)

    it("renders in ruRU", function()
        m, ns = H.boot({ locale = "ruRU" })
        local t = texts(frame())
        assert.is_true(has(t, "Тестовый маршрут"))
        assert.is_true(has(t, "1-4 Мертвый Звон"))
        assert.is_true(has(t, "Взять: Rude Awakening"))
        assert.is_true(has(t, "Поговорите с Гробовщиком Мордо"))
    end)

    it("hides with /fb hide, in combat with hideInCombat, and shows again", function()
        m, ns = H.boot()
        assert.same({ "Guide hidden. Type /fb show to bring it back." }, slash("/fb hide"))
        assert.is_false(m:IsWidgetVisible(frame()))
        assert.is_false(m:IsWidgetVisible(arrow()))
        slash("/fb show")
        refresh()
        assert.is_true(m:IsWidgetVisible(frame()))
        assert.is_true(m:IsWidgetVisible(arrow()))
        UI().SetSetting("hideInCombat", true)
        m:EnterCombat()
        assert.is_false(m:IsWidgetVisible(frame()))
        m:LeaveCombat()
        assert.is_true(m:IsWidgetVisible(frame()))
    end)
end)

describe("arrow", function()
    after_each(function() m:AssertClean() end)

    it("points at the target relative to the facing and shows the distance", function()
        m, ns = H.boot({ player = { mapID = 1420, x = 30.2, y = 81.7, facing = 0 } })
        local f = arrow()
        assert.is_true(m:IsWidgetVisible(f))
        local tex = arrowTexture()
        assert.equal(0, tex:GetRotation())
        assert.is_true(has(texts(f), "100 yd"))
        assert.is_true(has(texts(f), "Accept: Rude Awakening"))
        m:SetFacing(3 * math.pi / 2) -- facing east: the NPC (north) is to the left
        m:Advance(0.15)
        assert.is_true(math.abs(tex:GetRotation() - math.pi / 2) < 1e-9)
        UI().SetSetting("arrow", false)
        assert.is_false(m:IsWidgetVisible(f))
        UI().SetSetting("arrow", true)
        assert.is_true(m:IsWidgetVisible(f))
        m:MoveTo(1411, 50, 50) -- another continent: no direction
        m:Advance(0.15)
        assert.is_false(m:IsWidgetVisible(f))
    end)
end)

describe("settings panel", function()
    after_each(function() m:AssertClean() end)

    it("is registered in the Settings API and edits the account settings", function()
        m, ns = H.boot()
        local cat = UI().Options:GetCategory()
        assert.is_table(cat)
        assert.is_true(cat.registered)
        assert.equal("FastesBoooy", cat:GetName())
        local panel = UI().Options:GetPanel()
        assert.equal(panel, cat.frame)
        UI().Options:Open() -- Settings.OpenToCategory shows the canvas: OnShow syncs the controls
        assert.is_true(m:IsWidgetVisible(panel) or panel:IsShown())
        local s = ns.db.settings
        local auto = widget(function(w) return w.key == "automation" end)
        local accept = widget(function(w) return w.key == "autoAccept" end)
        assert.is_true(auto:GetChecked())
        m:Click(accept)
        assert.is_false(s.autoAccept)
        m:Click(accept)
        assert.is_true(s.autoAccept)
        m:Click(auto)
        assert.is_false(s.automation)
        assert.is_false(accept:IsEnabled(), "auto-* options greyed out without automation")
        assert.is_true(ns.Automation:IsSuspended())
        local look = widget(function(w) return w.def and w.def.key == "lookahead" end)
        m:DragSlider(look, 3)
        assert.equal(3, s.lookahead)
        local scale = widget(function(w) return w.def and w.def.key == "frameScale" end)
        m:DragSlider(scale, 1.26)
        assert.equal(1.25, s.frameScale)
        assert.equal(1.25, frame():GetScale())
        panel.OnDefault()
        assert.is_true(s.automation)
        assert.equal(6, s.lookahead)
        assert.equal(1, s.frameScale)
        assert.equal(1, m.env.FastesBoooyDB.settings.frameScale, "saved account-wide")
    end)
end)

describe("slash commands", function()
    after_each(function() m:AssertClean() end)

    it("help, unknown commands, routes, route, status", function()
        m, ns = H.boot()
        local out = slash("/fb")
        assert.equal("Commands:", out[1])
        assert.is_true(#out > 5)
        assert.same({ "Unknown command 'bogus'. Type /fb help." }, slash("/fb bogus"))
        assert.same({ "Installed routes:", "* test-route - Test route" }, slash("/fb routes"))
        assert.same({ "Route: Test route" }, slash("/fb route test-route"))
        assert.same({ "Unknown route 'nope'. Type /fb routes." }, slash("/fb route nope"))
        out = slash("/fastesboooy status")
        assert.same({
            "FastesBoooy 0.1.0 (route API 1)",
            "Route: Test route (test-route)",
            "Step 1/26: Accept: Rude Awakening",
            "Automation: on",
            "Waypoint: Accept: Rude Awakening, 0 yd",
            "Recorded quest XP rewards: 0",
        }, out)
        m:SetShift(true)
        assert.is_true(has(slash("/fb status"), "Automation: paused"))
        m:SetShift(false)
    end)

    it("next / prev / skip / reset", function()
        m, ns = H.boot()
        local cdb = m.env.FastesBoooyCharDB
        slash("/fb next")
        assert.equal("tr-363-364", H.cur(ns))
        slash("/fb prev")
        assert.equal("tr-accept-363", H.cur(ns))
        slash("/fb skip")
        assert.is_true(cdb.skipped["tr-accept-363"])
        slash("/fb reset")
        assert.is_true(m:PopupVisible("FASTESBOOOY_RESET"))
        local mark = #m.chat
        m:PopupClick("FASTESBOOOY_RESET", "button1")
        assert.is_nil(cdb.skipped["tr-accept-363"])
        assert.is_true(H.chatHas(m, "Route progress reset", mark + 1))
        assert.equal("tr-accept-363", H.cur(ns))
    end)

    it("lock / unlock / debug / config", function()
        m, ns = H.boot()
        assert.same({ "Frames locked." }, slash("/fb lock"))
        assert.is_true(ns.db.settings.locked)
        slash("/fb unlock")
        assert.is_false(ns.db.settings.locked)
        assert.same({ "Debug output: on" }, slash("/fb debug"))
        assert.is_true(ns.IsDebug())
        slash("/fb debug")
        assert.is_false(ns.IsDebug())
        slash("/fb config")
        assert.equal(UI().Options:GetCategory():GetID(), m.settingsOpened)
        m.settingsOpened = nil
        m:EnterCombat()
        assert.same({ "Can't open the settings in combat." }, slash("/fb config"))
        assert.is_nil(m.settingsOpened)
        m:LeaveCombat()
    end)

    it("xp: export window with a loadable Lua table, chat listing and clearing", function()
        m, ns = H.boot()
        assert.same({ "No quest XP rewards recorded yet. They are recorded when you turn in quests." }, slash("/fb xp"))
        m:AddQuestToLog(363)
        m:OpenQuestComplete(363) -- turned in by the automation: 40 XP at level 1
        m:SetLevel(3)
        m:AddQuestToLog(3901)
        m:CompleteObjectives(3901)
        m:TurnInQuest(3901)
        assert.same({ "2 quest XP reward(s) recorded, 290 XP in total." }, slash("/fb xp"))
        local ef = UI().Options:GetExportFrame()
        assert.is_true(m:IsWidgetVisible(ef))
        local text = ef.edit:GetText()
        assert.is_truthy(text:find("[363] = { xp = 40, level = 1 },", 1, true))
        assert.is_truthy(text:find("[3901] = { xp = 250, level = 3 },", 1, true))
        local chunk = assert(loadstring(text))
        local t = chunk()
        assert.same({ xp = 40, level = 1 }, t[363])
        assert.same({ xp = 250, level = 3 }, t[3901])
        -- typing does not change the export (read-only)
        m:TypeText(ef.edit, "garbage")
        assert.equal(text, ef.edit:GetText())
        assert.same({ "2 quest XP reward(s) recorded, 290 XP in total.", "  quest 363: 40 XP (level 1)",
            "  quest 3901: 250 XP (level 3)" }, slash("/fb xp chat"))
        assert.is_true(has(slash("/fb status"), "Recorded quest XP rewards: 2"))
        slash("/fb xp clear")
        assert.is_true(m:PopupVisible("FASTESBOOOY_XP_CLEAR"))
        local mark = #m.chat
        m:PopupClick("FASTESBOOOY_XP_CLEAR", "button1")
        assert.same({ "XP log cleared." }, H.chat(m, mark + 1))
        assert.is_nil(next(ns.db.xpLog))
        assert.is_nil(next(ns.db.xpLogLevel))
    end)

    it("work in ruRU", function()
        m, ns = H.boot({ locale = "ruRU" })
        local out = slash("/fb status")
        assert.is_truthy(out[2]:find("Тестовый маршрут", 1, true))
        assert.is_truthy(out[3]:find("Взять: Rude Awakening", 1, true))
    end)
end)
