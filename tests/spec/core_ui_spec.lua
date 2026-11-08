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

describe("item button", function()
    after_each(function() m:AssertClean() end)

    local function ib() return UI().ItemButton:GetFrame() end

    it("is a top-level secure button that shows the step's `use` item while it is in the bags", function()
        m, ns = H.boot()
        local b = ib()
        assert.equal(m.env.FastesBoooyItemButton, b, "named for /click macros")
        assert.equal(m.env.UIParent, b:GetParent())
        assert.equal(m.env.UIParent, select(2, b:GetPoint(1)), "anchored to UIParent, not to the step window")
        assert.is_true((b:IsProtected()))
        assert.is_false((frame():IsProtected()), "the step window stays unprotected")
        assert.is_false(m:IsWidgetVisible(b), "step 1 has no item")
        H.playTo(m, ns, "tr-collect-376") -- use = 3264 (Duskbat Wing)
        refresh()
        assert.is_false(m:IsWidgetVisible(b), "the item is not in the bags yet")
        m:AddItem(3264, 2)
        H.settle(m)
        assert.is_true(m:IsWidgetVisible(b))
        assert.equal(3264, UI().ItemButton:GetItem())
        assert.equal("item", b:GetAttribute("type1"))
        assert.equal("item:3264", b:GetAttribute("item1"))
        assert.is_true(has(texts(b), "2"), "stack count")
        m:Enter(b)
        local tt = m:TooltipLines()
        assert.equal("Duskbat Wing", tt[1])
        assert.is_true(has(tt, "Click to use (macro: /click FastesBoooyItemButton)."))
        m:Leave(b)
        m:Click(b)
        assert.same({ { "SecureAction", "item", "item:3264", "LeftButton" } }, m:Actions("SecureAction"))
        -- the step is done: the next step has no item
        m:AddItem(3264, 4)
        m:AddItem(3265, 6)
        H.settle(m)
        assert.equal("tr-complete-3901", H.cur(ns))
        assert.is_false(m:IsWidgetVisible(b))
        assert.is_nil(b:GetAttribute("type1"))
        assert.is_nil(UI().ItemButton:GetItem())
        -- /fb hide hides it too
        assert.same({ "Guide hidden. Type /fb show to bring it back." }, slash("/fb hide"))
        ns.Engine:Prev()
        H.settle(m)
        assert.equal("tr-collect-376", H.cur(ns))
        assert.is_false(m:IsWidgetVisible(b))
        slash("/fb show")
        assert.is_true(m:IsWidgetVisible(b))
    end)

    it("defers attribute and visibility changes during combat lockdown", function()
        m, ns = H.boot()
        local b = ib()
        H.playTo(m, ns, "tr-collect-376")
        m:AddItem(3264, 1)
        H.settle(m)
        assert.is_true(m:IsWidgetVisible(b))
        m:EnterCombat()
        -- the step completes in combat: the step window refreshes, the button must wait
        m:AddItem(3264, 5)
        m:AddItem(3265, 6)
        H.settle(m)
        assert.equal("tr-complete-3901", H.cur(ns))
        assert.is_true(UI().ItemButton:IsPending())
        assert.is_true(m:IsWidgetVisible(b), "unchanged during the lockdown")
        assert.equal("item:3264", b:GetAttribute("item1"))
        assert.is_true(has(texts(b), "6"), "the count (a plain region) follows the bags")
        UI().SetSetting("frameScale", 1.2) -- settings during combat: deferred too
        m:LeaveCombat()
        assert.is_false(UI().ItemButton:IsPending())
        assert.is_false(m:IsWidgetVisible(b))
        assert.is_nil(b:GetAttribute("item1"))
        assert.equal(1.2, b:GetScale())
        -- an item that appears during combat shows after it
        ns.Engine:Prev()
        H.settle(m)
        assert.equal("tr-collect-376", H.cur(ns))
        m:RemoveItem(3264, 6)
        H.settle(m)
        assert.is_false(m:IsWidgetVisible(b))
        m:EnterCombat()
        m:AddItem(3264, 1)
        H.settle(m)
        assert.is_false(m:IsWidgetVisible(b))
        m:LeaveCombat()
        assert.is_true(m:IsWidgetVisible(b))
        assert.equal("item:3264", b:GetAttribute("item1"))
    end)

    it("hides before the lockdown with hideInCombat and is created after combat on a /reload in combat", function()
        m, ns = H.boot()
        local b = ib()
        H.playTo(m, ns, "tr-collect-376")
        m:AddItem(3264, 1)
        H.settle(m)
        UI().SetSetting("hideInCombat", true)
        m:EnterCombat()
        assert.is_false(m:IsWidgetVisible(b), "hidden on PLAYER_REGEN_DISABLED, before the lockdown")
        assert.is_false(m:IsWidgetVisible(frame()))
        m:LeaveCombat()
        assert.is_true(m:IsWidgetVisible(b))
        -- /reload while in combat: the secure button is created once the lockdown ends
        m.player.inCombat = true
        local m2, ns2 = H.reload(m)
        m, ns = m2, ns2
        assert.is_nil(ib())
        assert.is_true(UI().ItemButton:IsPending())
        m:LeaveCombat()
        assert.is_table(ib())
        assert.is_true(m:IsWidgetVisible(ib()))
    end)

    it("offers the item of an active background step when the displayed step has none", function()
        m, ns = H.new({ fixture = false })
        local FB = m.env.FastesBoooy
        FB.RegisterRoute({ api = 1, id = "ib", title = "Item", faction = "Horde", default = true })
        FB.AddSegment("ib", { id = "s", title = "S", steps = {
            { id = "a363", accept = 363 },
            { id = "bg", complete = 364, bg = true, use = 2876 },
            { id = "a364", accept = 364, use = 3264 },
            { id = "m1", manual = true },
        } })
        H.Mock.boot(m, { "FastesBoooy" })
        H.settle(m)
        m:AddItem(2876, 1)
        m:AddItem(3264, 1)
        m:AddQuestToLog(363)
        H.settle(m)
        assert.equal("a364", H.cur(ns))
        assert.equal(3264, UI().ItemButton:GetItem(), "the displayed step first")
        m:AddQuestToLog(364)
        H.settle(m)
        assert.equal("m1", H.cur(ns))
        assert.same({ "bg" }, H.ids(ns.Engine:GetBackground()))
        assert.equal(2876, UI().ItemButton:GetItem(), "then the background steps")
        assert.equal("item:2876", ib():GetAttribute("item1"))
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

    it("has the automation delay sliders (0-3 s, random extra 0-1 s, step 0.1)", function()
        m, ns = H.boot()
        UI().Options:Open()
        local s = ns.db.settings
        local delay = widget(function(w) return w.def and w.def.key == "autoDelay" end)
        local jitter = widget(function(w) return w.def and w.def.key == "autoDelayJitter" end)
        assert.is_table(delay)
        assert.is_table(jitter)
        assert.same({ 0, 3 }, { delay:GetMinMaxValues() })
        assert.same({ 0, 1 }, { jitter:GetMinMaxValues() })
        assert.equal(0.1, delay:GetValueStep())
        assert.equal(0.5, delay:GetValue())
        assert.equal(0.3, jitter:GetValue())
        assert.equal("Automation delay: 0.5 s", delay.label:GetText())
        assert.equal("Random extra delay: up to 0.3 s", jitter.label:GetText())
        m:Enter(delay)
        assert.is_true(has(m:TooltipLines(), "Automation delay: 0.5 s"))
        m:Leave(delay)
        m:DragSlider(delay, 1.23)
        assert.equal(1.2, s.autoDelay)
        assert.equal("Automation delay: 1.2 s", delay.label:GetText())
        m:DragSlider(jitter, 0.66)
        assert.equal(0.7, s.autoDelayJitter)
        assert.is_true(jitter:IsEnabled())
        m:DragSlider(delay, 0)
        assert.equal(0, s.autoDelay)
        assert.is_false(jitter:IsEnabled(), "no random extra without a delay")
        assert.equal(0, ns.Automation:GetDelay())
        m:DragSlider(delay, 0.8)
        assert.is_true(jitter:IsEnabled())
        m:Click(widget(function(w) return w.key == "automation" end))
        assert.is_false(delay:IsEnabled(), "greyed out without automation")
        assert.is_false(jitter:IsEnabled())
        UI().Options:GetPanel().OnDefault()
        assert.equal(0.5, s.autoDelay)
        assert.equal(0.3, s.autoDelayJitter)
        assert.is_true(delay:IsEnabled())
        assert.equal(0.5, delay:GetValue())
        assert.equal(0.5, m.env.FastesBoooyDB.settings.autoDelay, "saved account-wide")
    end)

    it("shows the automation delay sliders in ruRU", function()
        m, ns = H.boot({ locale = "ruRU" })
        UI().Options:Open()
        local delay = widget(function(w) return w.def and w.def.key == "autoDelay" end)
        local jitter = widget(function(w) return w.def and w.def.key == "autoDelayJitter" end)
        assert.equal("Задержка автоматики: 0.5 с", delay.label:GetText())
        assert.equal("Случайная добавка: до 0.3 с", jitter.label:GetText())
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
            "FastesBoooy 0.2.0 (route API 1.1)",
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

    it("delay: prints and sets the automation delay", function()
        m, ns = H.boot()
        local s = ns.db.settings
        local usage = "Usage: /fb delay <seconds 0-3> [random extra 0-1], e.g. /fb delay 0.5 0.3 (0 = instant)"
        assert.is_true(has(slash("/fb help"),
            "/fb delay [seconds [random]] - pause before automatic quest actions (0-3 s, + random 0-1 s)"))
        assert.same({ "Automation delay: 0.5 s + random up to 0.3 s.", usage }, slash("/fb delay"))
        assert.same({ "Automation delay: 1.2 s + random up to 0.3 s." }, slash("/fb delay 1.2"))
        assert.equal(1.2, s.autoDelay)
        assert.equal(0.3, s.autoDelayJitter, "jitter unchanged")
        assert.same({ "Automation delay: 0.8 s." }, slash("/fb delay 0,8 0"))
        assert.equal(0.8, s.autoDelay)
        assert.equal(0, s.autoDelayJitter)
        assert.same({ "Automation delay: 3.0 s + random up to 1.0 s." }, slash("/fb delay 10 5"), "clamped")
        assert.same({ "Automation delay: 0.3 s + random up to 0.2 s." }, slash("/fb delay 0.26 0.17"), "step 0.1")
        assert.same({ "Automation delay: none, actions are instant." }, slash("/fb delay 0"))
        assert.equal(0, s.autoDelay)
        assert.equal(0.2, s.autoDelayJitter)
        for _, bad in ipairs({ "/fb delay soon", "/fb delay 1 x", "/fb delay 1 2 3" }) do
            assert.same({ usage }, slash(bad), bad)
        end
        assert.equal(0, s.autoDelay, "unchanged by invalid input")
        assert.equal(0.2, s.autoDelayJitter)
        -- the panel follows the command
        UI().Options:Open()
        slash("/fb delay 2 0.4")
        local delay = widget(function(w) return w.def and w.def.key == "autoDelay" end)
        assert.equal(2, delay:GetValue())
        assert.equal("Automation delay: 2.0 s", delay.label:GetText())
        -- and the automation uses it
        local mark = #m.actions
        m:OpenQuestDetail(363, { npcID = 1568 })
        m:Advance(1.9)
        assert.equal(0, #H.actionsSince(m, mark, "AcceptQuest"))
        m:Advance(0.55)
        assert.equal(1, #H.actionsSince(m, mark, "AcceptQuest"))
        m:CloseInteraction()
    end)

    it("delay works in ruRU", function()
        m, ns = H.boot({ locale = "ruRU" })
        local out = slash("/fb delay")
        assert.equal("Задержка автоматики: 0.5 с + случайно до 0.3 с.", out[1])
        assert.same({ "Задержка автоматики: нет, действия мгновенные." }, slash("/fb delay 0"))
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
        H.waitAuto(m, ns)
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
