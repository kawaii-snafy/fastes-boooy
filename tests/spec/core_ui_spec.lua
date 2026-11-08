-- UI tests on the strict widget mock: step window (layout invariants: top anchor, fixed
-- button row; Back / Forward / Settings; upcoming list; level-sync banner + Undo link), arrow,
-- item button, settings panel (incl. level sync) and the slash commands (/fb ... incl. status,
-- xp, sync), in enUS and ruRU.

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

local BACK, FORWARD = "\194\171 Back", "Forward \194\187"

-- Problems of the button row's anchor chain: every point of a button must lead to the
-- window's TOP edge through the row itself, never through a content region (rows, banner).
local function anchorChainProblems(f)
    local inRow = {}
    for _, b in ipairs(f.buttons) do inRow[b] = true end
    local problems = {}
    local function check(region, depth)
        assert(depth < 10, "anchor cycle")
        local n = region:GetNumPoints()
        if n == 0 then problems[#problems + 1] = "a button without anchor" end
        for i = 1, n do
            local point, rel, relPoint = region:GetPoint(i)
            if rel == f then
                if relPoint:sub(1, 3) ~= "TOP" then
                    problems[#problems + 1] = point .. " -> window " .. relPoint .. " (not its top edge)"
                end
            elseif inRow[rel] then
                check(rel, depth + 1)
            else
                problems[#problems + 1] = point .. " -> a region outside the button row"
            end
        end
    end
    for _, b in ipairs(f.buttons) do check(b, 0) end
    return problems
end

local function pointsOf(region)
    local out = {}
    for i = 1, region:GetNumPoints() do out[i] = { region:GetPoint(i) } end
    return out
end

local function rowPoints(f)
    local out = { window = pointsOf(f) }
    for i, b in ipairs(f.buttons) do out[i] = pointsOf(b) end
    return out
end

-- visible "done" check marks in the step window
local function checkMarks(f)
    return m:FindWidgets(function(w, st)
        if st.type ~= "Texture" or st.atlas ~= "UI-QuestTracker-Tracker-Check" or not m:IsWidgetVisible(w) then
            return false
        end
        local p = st.parent
        while p do
            if p == f then return true end
            p = m._W[p] and m._W[p].parent
        end
        return false
    end)
end

-- Level sync on the test route (margin 2): at level 6 "1-4 Deathknell" (levels 1-4) is
-- outleveled and "4-5 Brill" is the first segment that fits; its first step is tr-go-brill.
local BANNER = 'You are level 6: you have outleveled "1-4 Deathknell". Jump to "4-5 Brill"?'
local JUMPED = 'Jumped to "4-5 Brill" to fit your level.'
local APPLIED = 'Level sync: you are level 6 -- continuing at "4-5 Brill" ("1-4 Deathknell" is below your level). '
    .. "Undo: /fb sync undo"
local UNDONE = "Level sync undone: the route continues where it was before."

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
            BACK, FORWARD, "Settings" }) do
            assert.is_true(has(t, want), "missing text: " .. want .. " in " .. table.concat(t, " | "))
        end
        assert.is_false(f.prevButton:IsEnabled(), "nothing before step 1")
        assert.is_true(f.forwardButton:IsEnabled())
        assert.is_false(m:IsWidgetVisible(f.banner), "no level-sync banner at level 1")
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

    it("has three buttons: \194\171 Back, Forward \194\187 and Settings, each with an explaining tooltip", function()
        m, ns = H.boot()
        local f = frame()
        assert.same({ f.prevButton, f.forwardButton, f.settingsButton }, f.buttons)
        assert.is_nil(f.skipButton, "no separate Skip button any more")
        assert.equal(f.forwardButton, f.nextButton, "older name kept for tools/simulate_routes.lua")
        assert.same({ BACK, FORWARD, "Settings" },
            { f.prevButton:GetText(), f.forwardButton:GetText(), f.settingsButton:GetText() })
        m:Enter(f.prevButton)
        assert.same({ "Back", "Show the previous step. If it was skipped or marked done by hand, that mark is undone." },
            m:TooltipLines())
        m:Leave(f.prevButton)
        m:Enter(f.forwardButton)
        assert.same({ "Forward", "The step is done, or you don't want to do it: go to the next one.",
            "While you look at an earlier step (after Back): go forward again, nothing is marked.",
            "Steps also complete by themselves as soon as the game reports the progress." }, m:TooltipLines())
        m:Leave(f.forwardButton)
        m:Enter(f.settingsButton)
        assert.same({ "Settings", "Open the settings (/fb config)." }, m:TooltipLines())
        m:Leave(f.settingsButton)
    end)

    it("Forward skips the step or brings a step shown with Back forward again; Back undoes a skip", function()
        m, ns = H.boot()
        local f = frame()
        local cdb = m.env.FastesBoooyCharDB
        m:Click(f.forwardButton)
        refresh()
        assert.is_true(cdb.skipped["tr-accept-363"])
        assert.is_nil(cdb.manual["tr-accept-363"])
        assert.equal("tr-363-364", H.cur(ns))
        assert.is_true(f.prevButton:IsEnabled())
        m:Click(f.prevButton)
        refresh()
        assert.is_nil(cdb.skipped["tr-accept-363"], "Back undoes the skip")
        assert.equal("tr-accept-363", H.cur(ns))
        assert.is_false(f.prevButton:IsEnabled())
        -- done in the game: Back only shows the step again, Forward returns without marking it
        m:AddQuestToLog(363)
        H.settle(m)
        assert.equal("tr-363-364", H.cur(ns))
        m:Click(f.prevButton)
        refresh()
        assert.equal("tr-accept-363", H.cur(ns))
        assert.is_true(ns.Engine:IsPinned())
        m:Click(f.forwardButton)
        refresh()
        assert.equal("tr-363-364", H.cur(ns))
        assert.is_false(ns.Engine:IsPinned())
        assert.is_nil(next(cdb.skipped))
        assert.is_nil(next(cdb.manual))
        m:Click(f.settingsButton)
        assert.equal(UI().Options:GetCategory():GetID(), m.settingsOpened)
    end)

    it("keeps the buttons at fixed offsets from its top edge whatever the content height", function()
        m, ns = H.boot()
        local f = frame()
        assert.equal(1, f:GetNumPoints())
        assert.equal("TOP", (f:GetPoint(1)):sub(1, 3), "anchored by its top edge")
        assert.same({}, anchorChainProblems(f))
        local before = rowPoints(f)
        local heights = { f:GetHeight() }
        UI().SetSetting("shownNext", 10)
        refresh()
        heights[#heights + 1] = f:GetHeight()
        UI().SetSetting("shownNext", 0)
        refresh()
        heights[#heights + 1] = f:GetHeight()
        UI().SetSetting("shownNext", 4)
        H.playTo(m, ns, "tr-collect-376") -- other step text, background goals
        refresh()
        heights[#heights + 1] = f:GetHeight()
        m:SetLevel(6) -- the level-sync banner goes below the buttons
        H.settle(m)
        assert.is_true(m:IsWidgetVisible(f.banner))
        heights[#heights + 1] = f:GetHeight()
        assert.is_true(heights[2] > heights[1] and heights[3] < heights[1], table.concat(heights, ", "))
        assert.is_true(heights[5] > heights[4], "the banner adds height below")
        assert.same(before, rowPoints(f), "buttons and window anchor unchanged")
        assert.same({}, anchorChainProblems(f))
        -- the banner and the content start below the button row
        local _, rel, relPoint, _, y = f.banner:GetPoint(1)
        assert.equal(f, rel)
        assert.equal("TOPLEFT", relPoint)
        assert.is_true(-y >= UI().StepFrame.TOP_BLOCK)
        -- only the header + buttons must stay on screen: a tall window hangs down instead of moving up
        assert.same({ 0, 0, 0, f:GetHeight() - UI().StepFrame.TOP_BLOCK }, { f:GetClampRectInsets() })
    end)

    it("is anchored by its top edge: the default position is converted once, a drag is saved by the top", function()
        m, ns = H.boot()
        local f = frame()
        local UIParent = m.env.UIParent
        local p, rel, rp, x, y = f:GetPoint(1)
        assert.same({ "TOPRIGHT", UIParent, "RIGHT", -80 }, { p, rel, rp, x })
        assert.is_true(y > 120, "the top edge of the window that was centered at y = 120")
        local saved = ns.db.frames.steps
        assert.same({ "TOPRIGHT", "RIGHT", -80, y }, { saved.point, saved.relativePoint, saved.x, saved.y })
        -- the client re-anchors a moved frame to its nearest point (here BOTTOMRIGHT)
        f:GetScript("OnDragStart")(f)
        f:ClearAllPoints()
        f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -50, 40)
        f:GetScript("OnDragStop")(f)
        local h = f:GetHeight()
        assert.same({ "TOPRIGHT", UIParent, "BOTTOMRIGHT", -50, 40 + h }, { f:GetPoint(1) })
        assert.same({ "TOPRIGHT", "BOTTOMRIGHT", -50, 40 + h }, { saved.point, saved.relativePoint, saved.x, saved.y })
        -- a taller window keeps that top edge
        UI().SetSetting("shownNext", 10)
        refresh()
        assert.is_true(f:GetHeight() > h)
        assert.same({ "TOPRIGHT", UIParent, "BOTTOMRIGHT", -50, 40 + h }, { f:GetPoint(1) })
        -- locked: no drag
        UI().SetSetting("locked", true)
        f:GetScript("OnDragStart")(f)
        assert.is_falsy(f.isMoving)
        -- /reload: the saved top anchor is used as is
        m, ns = H.reload(m)
        assert.same({ "TOPRIGHT", m.env.UIParent, "BOTTOMRIGHT", -50, 40 + h }, { frame():GetPoint(1) })
    end)

    it("converts an old middle / bottom anchor with the window's real height (after login)", function()
        for _, old in ipairs({
            { point = "RIGHT", y = 120, v = 0.5 },
            { point = "BOTTOMRIGHT", y = 300, v = 1 },
        }) do
            m, ns = H.boot({ savedVariables = { FastesBoooyDB = { frames = { steps = {
                point = old.point, relativePoint = old.point, x = -80, y = old.y } } } } })
            local f = frame()
            local h = f:GetHeight()
            assert.is_true(h > 150, "the route's step is laid out: " .. h)
            local saved = ns.db.frames.steps
            assert.equal("TOPRIGHT", saved.point)
            -- the top edge where the old anchor put it with this height (not the "no route" height of
            -- ADDON_LOADED)
            assert.equal(math.floor(old.y + old.v * h + 0.5), saved.y, old.point)
            assert.same({ "TOPRIGHT", m.env.UIParent, old.point, -80, saved.y }, { f:GetPoint(1) })
            m:AssertClean()
        end
    end)

    it("lists only what is left of the next steps: no done step, no done line", function()
        m, ns = H.boot()
        UI().SetSetting("shownNext", 10)
        m:AddQuestToLog(376)  -- tr-accept-376 done ahead of time
        m:AddQuestToLog(3901) -- tr-turnin-364 = turn in 364 + accept 3901: half done
        H.settle(m)
        assert.equal("tr-accept-363", H.cur(ns))
        local f = frame()
        local t = texts(f)
        assert.is_true(has(t, "Next"))
        assert.is_true(has(t, "Turn in: The Mindless Ones"), "the part of tr-turnin-364 that is left")
        assert.is_false(has(t, "Accept: Rattling the Rattlecages"), "its done accept line is not repeated")
        assert.is_false(has(t, "Accept: The Damned"), "the done step is not listed")
        assert.same({}, checkMarks(f), "no check mark in the list")
        for _, s in ipairs(ns.Engine:GetUpcoming(10)) do
            assert.is_false(ns.Engine:IsDone(s), s.id)
        end
        -- the current step still shows its done lines
        m:AddQuestToLog(363)
        m:TurnInQuest(363)
        ns.Engine:Prev()
        H.settle(m)
        assert.equal("tr-363-364", H.cur(ns))
        assert.is_true(#checkMarks(f) > 0)
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
        m:SetLevel(6)
        H.settle(m)
        assert.is_true(m:IsWidgetVisible(frame().banner))
        n = #m.widgets
        for _ = 1, 3 do UI().StepFrame:Refresh() end
        assert.equal(n, #m.widgets, "the banner is created once with the window")
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
        local f = frame()
        local t = texts(f)
        for _, want in ipairs({ "Тестовый маршрут", "1-4 Мертвый Звон", "Взять: Rude Awakening",
            "Поговорите с Гробовщиком Мордо", "Далее", "« Назад", "Вперёд »", "Настройки" }) do
            assert.is_true(has(t, want), "missing text: " .. want .. " in " .. table.concat(t, " | "))
        end
        m:Enter(f.prevButton)
        assert.same({ "Назад", "Показать предыдущий шаг. Если он был пропущен или отмечен вручную, отметка снимается." },
            m:TooltipLines())
        m:Leave(f.prevButton)
        m:Enter(f.forwardButton)
        assert.same({ "Вперёд", "Шаг выполнен или вы не хотите его делать: перейти к следующему.",
            "Если вы смотрите прошлый шаг (после «Назад»): вернуться вперёд, ничего не отмечая.",
            "Шаги и так закрываются сами, как только игра сообщает о выполнении." }, m:TooltipLines())
        m:Leave(f.forwardButton)
        m:SetLevel(6)
        H.settle(m)
        assert.is_true(has(texts(f), "Вы 6 ур. — участок «1-4 Мертвый Звон» пройден по уровню. Перейти к «4-5 Брилл»?"))
        assert.same({ "Перейти", "Остаться" }, { f.banner.goButton:GetText(), f.banner.stayButton:GetText() })
        m:Click(f.banner.goButton)
        H.settle(m)
        assert.is_true(has(texts(f), "Переход к «4-5 Брилл» по уровню."))
        assert.equal("Вернуть", f.banner.undoButton:GetText())
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

describe("level sync in the step window", function()
    after_each(function() m:AssertClean() end)

    it("offers the jump in a banner under the buttons: Stay keeps the segment", function()
        m, ns = H.boot()
        local f = frame()
        local before = rowPoints(f)
        local h0 = f:GetHeight()
        m:SetLevel(6)
        H.settle(m)
        local cur = H.cur(ns)
        assert.is_true(m:IsWidgetVisible(f.banner))
        assert.is_true(has(texts(f), BANNER))
        assert.is_true(m:IsWidgetVisible(f.banner.goButton))
        assert.is_false(m:IsWidgetVisible(f.banner.undoButton))
        assert.same(before, rowPoints(f), "the banner does not move the buttons")
        m:Enter(f.banner.goButton)
        assert.same({ "Jump", "The steps before it count as done. To go back: the Undo link right after the jump, "
            .. "or /fb sync undo." }, m:TooltipLines())
        m:Leave(f.banner.goButton)
        m:Enter(f.banner.stayButton)
        assert.same({ "Stay", "Keep doing this segment. The offer comes back at your next level-up." }, m:TooltipLines())
        m:Leave(f.banner.stayButton)
        local h1 = f:GetHeight()
        m:Click(f.banner.stayButton)
        H.settle(m)
        assert.is_nil(ns.Engine:GetSyncSuggestion())
        assert.is_false(m:IsWidgetVisible(f.banner))
        assert.equal(cur, H.cur(ns), "Stay: the cursor does not move")
        assert.is_true(f:GetHeight() < h1)
        assert.is_true(h0 > 0)
        assert.same(before, rowPoints(f))
    end)

    it("Jump goes to the segment that fits the level; the Undo link goes back", function()
        m, ns = H.boot()
        local f = frame()
        m:SetLevel(6)
        H.settle(m)
        local cur = H.cur(ns)
        local mark = #m.chat
        m:Click(f.banner.goButton)
        H.settle(m)
        assert.equal("tr-go-brill", H.cur(ns))
        assert.same({ APPLIED }, H.chat(m, mark + 1))
        assert.is_true(has(texts(f), "4-5 Brill"))
        -- after the jump: a one-line note with the Undo link instead of the question
        assert.is_true(m:IsWidgetVisible(f.banner.undoButton))
        assert.is_false(m:IsWidgetVisible(f.banner.goButton))
        assert.is_true(has(texts(f), JUMPED))
        assert.equal("Undo", f.banner.undoButton:GetText())
        m:Enter(f.banner.undoButton)
        assert.same({ "Undo", "Go back to where you were: the jumped-over steps count as not done again." },
            m:TooltipLines())
        m:Leave(f.banner.undoButton)
        mark = #m.chat
        m:Click(f.banner.undoButton)
        H.settle(m)
        assert.equal(cur, H.cur(ns))
        assert.same({ UNDONE }, H.chat(m, mark + 1))
        assert.is_nil(ns.cdb.syncFloor)
        assert.is_false(m:IsWidgetVisible(f.banner), "no offer again for that segment before the next level-up")
    end)

    it("shows the Undo link for 30 s or until the step changes", function()
        m, ns = H.boot()
        local f = frame()
        m:SetLevel(6)
        H.settle(m)
        m:Click(f.banner.goButton)
        H.settle(m)
        assert.is_true(m:IsWidgetVisible(f.banner.undoButton))
        m:Advance(UI().StepFrame.UNDO_SECONDS - 2)
        assert.is_true(m:IsWidgetVisible(f.banner.undoButton))
        m:Advance(3) -- the window refreshes about once a second
        assert.is_false(m:IsWidgetVisible(f.banner), "expired")
        assert.equal("tr-go-brill", H.cur(ns), "the jump stays")
        assert.same({ "Usage: /fb sync [undo]" }, slash("/fb sync now"))
        assert.same({ UNDONE }, slash("/fb sync undo"))
        -- jump again with the command, then do the step: the link closes
        m:SetLevel(7) -- the next level-up lifts "Stay" / the undo's silence; Brill is outleveled at 7
        UI().SetSetting("levelSyncMargin", 3)
        H.settle(m)
        assert.is_true(m:IsWidgetVisible(f.banner.goButton))
        assert.same({ 'Level sync: you are level 7 -- continuing at "4-5 Brill" ("1-4 Deathknell" is below your '
            .. 'level). Undo: /fb sync undo' }, slash("/fb sync"))
        H.settle(m)
        assert.is_true(m:IsWidgetVisible(f.banner.undoButton))
        m:MoveTo(1420, 60.5, 52.5) -- tr-go-brill done
        H.settle(m)
        assert.equal("tr-sethearth", H.cur(ns))
        assert.is_false(m:IsWidgetVisible(f.banner), "closed by the step change")
        assert.is_table(ns.cdb.syncFloor)
    end)

    it("auto mode: the engine jumps by itself, the window offers Undo", function()
        m, ns = H.boot()
        local f = frame()
        UI().SetSetting("levelSync", "auto")
        local mark = #m.chat
        m:SetLevel(6)
        H.settle(m)
        assert.equal("tr-go-brill", H.cur(ns))
        assert.is_true(H.chatHas(m, "Level sync (automatic): level 6", mark + 1))
        assert.is_true(m:IsWidgetVisible(f.banner.undoButton))
        assert.is_false(m:IsWidgetVisible(f.banner.goButton), "no question in auto mode")
        assert.is_true(has(texts(f), JUMPED))
        m:Click(f.banner.undoButton)
        H.settle(m)
        assert.is_nil(ns.cdb.syncFloor)
        assert.is_false(m:IsWidgetVisible(f.banner))
    end)

    it("off mode: no banner; a jump saved by an earlier session offers no Undo link", function()
        m, ns = H.boot()
        UI().SetSetting("levelSync", "off")
        m:SetLevel(6)
        H.settle(m)
        assert.is_false(m:IsWidgetVisible(frame().banner))
        assert.same({ APPLIED }, slash("/fb sync"), "the command jumps on request")
        H.settle(m)
        assert.is_true(m:IsWidgetVisible(frame().banner.undoButton))
        m, ns = H.reload(m)
        assert.equal("tr-go-brill", H.cur(ns), "the jump is saved per character")
        assert.is_false(m:IsWidgetVisible(frame().banner))
    end)

    it("works with a core without level sync: no banner, /fb sync says so", function()
        m, ns = H.boot()
        local E = ns.Engine
        -- the UI's view of an older engine: the level-sync methods missing, the rest as is
        ns.Engine = setmetatable({ GetSyncSuggestion = false, ApplySync = false, DismissSync = false,
            UndoSync = false, GetLastSync = false }, { __index = E })
        m:SetLevel(6)
        H.settle(m)
        assert.is_false(m:IsWidgetVisible(frame().banner))
        assert.same({ "Level sync is not available in this core version." }, slash("/fb sync"))
        assert.same({ "Level sync is not available in this core version." }, slash("/fb sync undo"))
        ns.Engine = E
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

    it("edits the level sync settings: mode, level margin, gray quests", function()
        m, ns = H.boot()
        UI().Options:Open()
        local panel = UI().Options:GetPanel()
        local s = ns.db.settings
        local function radio(mode) return widget(function(w) return w.mode == mode end) end
        local function checked()
            return { radio("ask"):GetChecked(), radio("auto"):GetChecked(), radio("off"):GetChecked() }
        end
        assert.is_true(has(texts(panel), "Level sync"))
        assert.equal("Offer to jump ahead", radio("ask").label:GetText())
        assert.equal("Jump ahead automatically", radio("auto").label:GetText())
        assert.equal("Off", radio("off").label:GetText())
        assert.same({ true, false, false }, checked())
        m:Click(radio("auto"))
        assert.equal("auto", s.levelSync)
        assert.same({ false, true, false }, checked())
        m:Click(radio("auto")) -- a click on the checked radio keeps it
        assert.equal("auto", s.levelSync)
        assert.same({ false, true, false }, checked())
        m:Enter(radio("auto"))
        assert.same({ "Jump ahead automatically", "Jump to the first segment that fits your level at once and say "
            .. "so in the chat. Undo: the link in the guide window or /fb sync undo." }, m:TooltipLines())
        m:Leave(radio("auto"))
        local margin = widget(function(w) return w.def and w.def.key == "levelSyncMargin" end)
        assert.same({ 0, 5 }, { margin:GetMinMaxValues() })
        assert.equal(1, margin:GetValueStep())
        assert.equal(2, margin:GetValue())
        assert.equal("Level margin: 2", margin.label:GetText())
        m:DragSlider(margin, 3.6)
        assert.equal(4, s.levelSyncMargin)
        assert.equal("Level margin: 4", margin.label:GetText())
        assert.is_true(margin:IsEnabled())
        m:Click(radio("off"))
        assert.equal("off", s.levelSync)
        assert.same({ false, false, true }, checked())
        assert.is_false(margin:IsEnabled(), "no margin while level sync is off")
        local gray = widget(function(w) return w.key == "skipGray" end)
        assert.equal("Skip gray quests", gray.label:GetText())
        assert.is_true(gray:GetChecked())
        m:Click(gray)
        assert.is_false(s.skipGray)
        m:Enter(gray)
        assert.equal("Skip gray quests", m:TooltipLines()[1])
        m:Leave(gray)
        panel.OnDefault()
        assert.same({ "ask", 2, true }, { s.levelSync, s.levelSyncMargin, s.skipGray })
        assert.same({ true, false, false }, checked())
        assert.equal(2, margin:GetValue())
        assert.is_true(margin:IsEnabled())
        assert.is_true(gray:GetChecked())
        assert.equal("ask", m.env.FastesBoooyDB.settings.levelSync, "saved account-wide")
    end)

    it("shows the automation delay sliders in ruRU", function()
        m, ns = H.boot({ locale = "ruRU" })
        UI().Options:Open()
        local delay = widget(function(w) return w.def and w.def.key == "autoDelay" end)
        local jitter = widget(function(w) return w.def and w.def.key == "autoDelayJitter" end)
        assert.equal("Задержка автоматики: 0.5 с", delay.label:GetText())
        assert.equal("Случайная добавка: до 0.3 с", jitter.label:GetText())
        assert.is_true(has(texts(UI().Options:GetPanel()), "Синхронизация по уровню"))
        for mode, label in pairs({ ask = "Предлагать переход", auto = "Переходить автоматически", off = "Выключено" }) do
            assert.equal(label, widget(function(w) return w.mode == mode end).label:GetText())
        end
        assert.equal("Запас уровней: 2", widget(function(w) return w.def and w.def.key == "levelSyncMargin" end)
            .label:GetText())
        assert.equal("Пропускать серые квесты", widget(function(w) return w.key == "skipGray" end).label:GetText())
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
        slash("/fb forward") -- the Forward button: skips
        assert.is_true(cdb.skipped["tr-accept-363"])
        slash("/fb back") -- the Back button: undoes the skip
        assert.is_nil(cdb.skipped["tr-accept-363"])
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

    it("sync: jumps to the segment that fits the level, says when the route fits, undo", function()
        m, ns = H.boot()
        assert.is_true(has(slash("/fb help"),
            "/fb sync [undo] - jump to the part of the route that fits your level (undo: go back)"))
        assert.is_true(has(slash("/fb help"), "/fb back | forward - like the Back / Forward buttons; /fb next | skip - "
            .. "mark the step done / skipped"))
        assert.same({ "The route fits your level (1): nothing to jump over." }, slash("/fb sync"))
        assert.same({ "No level sync to undo." }, slash("/fb sync undo"))
        assert.same({ "Usage: /fb sync [undo]" }, slash("/fb sync later"))
        m:SetLevel(6)
        H.settle(m)
        local cur = H.cur(ns)
        assert.same({ APPLIED }, slash("/fb sync"))
        assert.equal("tr-go-brill", H.cur(ns))
        assert.same({ "The route fits your level (6): nothing to jump over." }, slash("/fb sync"))
        assert.same({ UNDONE }, slash("/fb sync UNDO"))
        assert.equal(cur, H.cur(ns))
        assert.same({ "No level sync to undo." }, slash("/fb sync undo"))
        m, ns = H.boot({ fixture = false })
        assert.same({ "No route selected for this character. Type /fb routes." }, slash("/fb sync"))
    end)

    it("sync undo leaves the floor of another route alone", function()
        local mods = { { H.FIXTURE_TOC, H.FIXTURE_NAME }, { H.LIB_TOC, H.LIB_NAME }, { H.COMPOSED_TOC, H.COMPOSED_NAME } }
        m, ns = H.boot({ modules = mods })
        m:SetLevel(6)
        H.settle(m)
        local route1 = ns.Engine:GetRoute().id
        slash("/fb sync")
        H.settle(m)
        local floorRec = ns.cdb.syncFloor
        assert.is_table(floorRec)
        slash("/fb route " .. H.COMPOSED_ID)
        H.settle(m)
        assert.is_nil(UI().SyncFloor())
        assert.same({ "No level sync to undo." }, slash("/fb sync undo"))
        assert.equal(floorRec, ns.cdb.syncFloor, "still there for " .. route1)
        slash("/fb route " .. route1)
        H.settle(m)
        assert.equal(floorRec, UI().SyncFloor())
        assert.equal("tr-go-brill", H.cur(ns))
        m:AssertClean()
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
        assert.is_true(has(slash("/fb help"), "/fb sync [undo] - перейти к участку маршрута по вашему уровню (undo - вернуть)"))
        assert.same({ "Маршрут соответствует вашему уровню (1): пропускать нечего." }, slash("/fb sync"))
        assert.same({ "Нечего возвращать: перехода по уровню не было." }, slash("/fb sync undo"))
        m:SetLevel(6)
        H.settle(m)
        assert.same({ "Синхронизация по уровню: у вас 6 ур. — продолжаем с «4-5 Брилл» («1-4 Мертвый Звон» пройден по "
            .. "уровню). Вернуть: /fb sync undo" }, slash("/fb sync"))
        assert.same({ "Синхронизация по уровню отменена: маршрут продолжается с прежнего места." }, slash("/fb sync undo"))
    end)
end)
