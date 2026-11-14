-- UI tests on the strict widget mock: step window (layout invariants: top anchor, fixed
-- button row; Back / Forward / Settings; upcoming list; level-sync banner + Undo link), arrow,
-- settings panel (incl. level sync) and the slash commands (/aa ... incl. status,
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

local BACK, FORWARD = "Back", "Forward"

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
    .. "Undo: /aa sync undo"
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

    it("has three buttons: Back, Forward and Settings (plain labels, no arrow symbols), each with an explaining tooltip", function()
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
        assert.same({ "Settings", "Open the settings (/aa config)." }, m:TooltipLines())
        m:Leave(f.settingsButton)
    end)

    it("Forward skips the step or brings a step shown with Back forward again; Back undoes a skip", function()
        m, ns = H.boot()
        local f = frame()
        local cdb = m.env.AdventureAtlasCharDB
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
            m, ns = H.boot({ savedVariables = { AdventureAtlasDB = { frames = { steps = {
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
            "Поговорите с Гробовщиком Мордо", "Далее", "Назад", "Вперёд", "Настройки" }) do
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

    it("hides with /aa hide, in combat with hideInCombat, and shows again", function()
        m, ns = H.boot()
        assert.same({ "Guide hidden. Type /aa show to bring it back." }, slash("/aa hide"))
        assert.is_false(m:IsWidgetVisible(frame()))
        assert.is_false(m:IsWidgetVisible(arrow()))
        slash("/aa show")
        refresh()
        assert.is_true(m:IsWidgetVisible(frame()))
        assert.is_true(m:IsWidgetVisible(arrow()))
        UI().SetSetting("hideInCombat", true)
        m:EnterCombat()
        assert.is_false(m:IsWidgetVisible(frame()))
        m:LeaveCombat()
        assert.is_true(m:IsWidgetVisible(frame()))
    end)

    it("keeps the position of a window that is hidden while being dragged", function()
        m, ns = H.boot()
        local f = frame()
        local UIParent = m.env.UIParent
        UI().SetSetting("hideInCombat", true)
        f:GetScript("OnDragStart")(f)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 30, -40)
        m:EnterCombat() -- hidden: the client sends no OnDragStop
        assert.is_false(m:IsWidgetVisible(f))
        assert.is_falsy(f.isMoving)
        local saved = ns.db.frames.steps
        assert.same({ "TOPLEFT", "TOPLEFT", 30, -40 }, { saved.point, saved.relativePoint, saved.x, saved.y })
        m:LeaveCombat()
        UI().SetSetting("shownNext", 2) -- any setting re-applies the saved position
        assert.same({ "TOPLEFT", UIParent, "TOPLEFT", 30, -40 }, { f:GetPoint(1) })
    end)

    it("says at login that the guide is hidden (the flag is account-wide)", function()
        m, ns = H.boot()
        assert.is_false(H.chatHas(m, "Guide hidden."), "nothing to say while the guide is shown")
        slash("/aa hide")
        m, ns = H.reload(m) -- a new client: a new chat log
        assert.is_false(m:IsWidgetVisible(frame()))
        assert.is_true(H.chatHas(m, "Guide hidden. Type /aa show to bring it back."))
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
            .. "or /aa sync undo." }, m:TooltipLines())
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
        assert.same({ "Usage: /aa sync [undo]" }, slash("/aa sync now"))
        assert.same({ UNDONE }, slash("/aa sync undo"))
        -- jump again with the command, then do the step: the link closes
        m:SetLevel(7) -- the next level-up lifts "Stay" / the undo's silence; Brill is outleveled at 7
        UI().SetSetting("levelSyncMargin", 3)
        H.settle(m)
        assert.is_true(m:IsWidgetVisible(f.banner.goButton))
        assert.same({ 'Level sync: you are level 7 -- continuing at "4-5 Brill" ("1-4 Deathknell" is below your '
            .. 'level). Undo: /aa sync undo' }, slash("/aa sync"))
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
        assert.same({ APPLIED }, slash("/aa sync"), "the command jumps on request")
        H.settle(m)
        assert.is_true(m:IsWidgetVisible(frame().banner.undoButton))
        m, ns = H.reload(m)
        assert.equal("tr-go-brill", H.cur(ns), "the jump is saved per character")
        assert.is_false(m:IsWidgetVisible(frame().banner))
    end)

    it("works with a core without level sync: no banner, /aa sync says so", function()
        m, ns = H.boot()
        local E = ns.Engine
        -- the UI's view of an older engine: the level-sync methods missing, the rest as is
        ns.Engine = setmetatable({ GetSyncSuggestion = false, ApplySync = false, DismissSync = false,
            UndoSync = false, GetLastSync = false }, { __index = E })
        m:SetLevel(6)
        H.settle(m)
        assert.is_false(m:IsWidgetVisible(frame().banner))
        assert.same({ "Level sync is not available in this core version." }, slash("/aa sync"))
        assert.same({ "Level sync is not available in this core version." }, slash("/aa sync undo"))
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
        -- between the waypoint ticks the arrow turns with the player every frame
        m:SetFacing(math.pi)
        m:Advance(0.01)
        assert.is_true(math.abs(tex:GetRotation() - (-math.pi)) < 1e-9 or math.abs(tex:GetRotation() - math.pi) < 1e-9)
        -- the texts below / beside the frame are clamped to the screen too
        assert.same({ -65, 65, 0, -40 }, { f:GetClampRectInsets() })
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
        assert.equal("Adventure Atlas", cat:GetName())
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
        assert.equal(1, m.env.AdventureAtlasDB.settings.frameScale, "saved account-wide")
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
        assert.equal(0.5, m.env.AdventureAtlasDB.settings.autoDelay, "saved account-wide")
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
            .. "so in the chat. Undo: the link in the guide window or /aa sync undo." }, m:TooltipLines())
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
        assert.equal("ask", m.env.AdventureAtlasDB.settings.levelSync, "saved account-wide")
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
        local out = slash("/aa")
        assert.equal("Commands:", out[1])
        assert.is_true(#out > 5)
        assert.same({ "Unknown command 'bogus'. Type /aa help." }, slash("/aa bogus"))
        assert.same({ "Installed routes:", "* test-route - Test route" }, slash("/aa routes"))
        assert.same({ "Route: Test route" }, slash("/aa route test-route"))
        assert.same({ "Unknown route 'nope'. Type /aa routes." }, slash("/aa route nope"))
        out = slash("/atlas status")
        assert.same({
            "Adventure Atlas 0.5.0 (route API 1.2)",
            "Route: Test route (test-route)",
            "Step 1/26: Accept: Rude Awakening",
            "Automation: on",
            "Waypoint: Accept: Rude Awakening, 0 yd",
            "Recorded quest XP rewards: 0",
        }, out)
        m:SetShift(true)
        assert.is_true(has(slash("/aa status"), "Automation: paused"))
        m:SetShift(false)
    end)

    it("next / prev / skip / reset", function()
        m, ns = H.boot()
        local cdb = m.env.AdventureAtlasCharDB
        slash("/aa next")
        assert.equal("tr-363-364", H.cur(ns))
        slash("/aa prev")
        assert.equal("tr-accept-363", H.cur(ns))
        slash("/aa forward") -- the Forward button: skips
        assert.is_true(cdb.skipped["tr-accept-363"])
        slash("/aa back") -- the Back button: undoes the skip
        assert.is_nil(cdb.skipped["tr-accept-363"])
        assert.equal("tr-accept-363", H.cur(ns))
        slash("/aa skip")
        assert.is_true(cdb.skipped["tr-accept-363"])
        slash("/aa reset")
        assert.is_true(m:PopupVisible("ADVENTUREATLAS_RESET"))
        local mark = #m.chat
        m:PopupClick("ADVENTUREATLAS_RESET", "button1")
        assert.is_nil(cdb.skipped["tr-accept-363"])
        assert.is_true(H.chatHas(m, "Route progress reset", mark + 1))
        assert.equal("tr-accept-363", H.cur(ns))
    end)

    it("delay: prints and sets the automation delay", function()
        m, ns = H.boot()
        local s = ns.db.settings
        local usage = "Usage: /aa delay <seconds 0-3> [random extra 0-1], e.g. /aa delay 0.5 0.3 (0 = instant)"
        assert.is_true(has(slash("/aa help"),
            "/aa delay [seconds [random]] - pause before automatic quest actions (0-3 s, + random 0-1 s)"))
        assert.same({ "Automation delay: 0.5 s + random up to 0.3 s.", usage }, slash("/aa delay"))
        assert.same({ "Automation delay: 1.2 s + random up to 0.3 s." }, slash("/aa delay 1.2"))
        assert.equal(1.2, s.autoDelay)
        assert.equal(0.3, s.autoDelayJitter, "jitter unchanged")
        assert.same({ "Automation delay: 0.8 s." }, slash("/aa delay 0,8 0"))
        assert.equal(0.8, s.autoDelay)
        assert.equal(0, s.autoDelayJitter)
        assert.same({ "Automation delay: 3.0 s + random up to 1.0 s." }, slash("/aa delay 10 5"), "clamped")
        assert.same({ "Automation delay: 0.3 s + random up to 0.2 s." }, slash("/aa delay 0.26 0.17"), "step 0.1")
        assert.same({ "Automation delay: none, actions are instant." }, slash("/aa delay 0"))
        assert.equal(0, s.autoDelay)
        assert.equal(0.2, s.autoDelayJitter)
        for _, bad in ipairs({ "/aa delay soon", "/aa delay 1 x", "/aa delay 1 2 3" }) do
            assert.same({ usage }, slash(bad), bad)
        end
        assert.equal(0, s.autoDelay, "unchanged by invalid input")
        assert.equal(0.2, s.autoDelayJitter)
        -- the panel follows the command
        UI().Options:Open()
        slash("/aa delay 2 0.4")
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
        assert.is_true(has(slash("/aa help"),
            "/aa sync [undo] - jump to the part of the route that fits your level (undo: go back)"))
        assert.is_true(has(slash("/aa help"), "/aa back | forward - like the Back / Forward buttons; /aa next | skip - "
            .. "mark the step done / skipped"))
        assert.same({ "The route fits your level (1): nothing to jump over." }, slash("/aa sync"))
        assert.same({ "No level sync to undo." }, slash("/aa sync undo"))
        assert.same({ "Usage: /aa sync [undo]" }, slash("/aa sync later"))
        m:SetLevel(6)
        H.settle(m)
        local cur = H.cur(ns)
        assert.same({ APPLIED }, slash("/aa sync"))
        assert.equal("tr-go-brill", H.cur(ns))
        assert.same({ "The route fits your level (6): nothing to jump over." }, slash("/aa sync"))
        assert.same({ UNDONE }, slash("/aa sync UNDO"))
        assert.equal(cur, H.cur(ns))
        assert.same({ "No level sync to undo." }, slash("/aa sync undo"))
        m, ns = H.boot({ fixture = false })
        assert.same({ "No route selected for this character. Type /aa routes." }, slash("/aa sync"))
    end)

    it("sync undo leaves the floor of another route alone", function()
        local mods = { { H.FIXTURE_TOC, H.FIXTURE_NAME }, { H.LIB_TOC, H.LIB_NAME }, { H.COMPOSED_TOC, H.COMPOSED_NAME } }
        m, ns = H.boot({ modules = mods })
        m:SetLevel(6)
        H.settle(m)
        local route1 = ns.Engine:GetRoute().id
        slash("/aa sync")
        H.settle(m)
        local floorRec = ns.cdb.syncFloor
        assert.is_table(floorRec)
        slash("/aa route " .. H.COMPOSED_ID)
        H.settle(m)
        assert.is_nil(UI().SyncFloor())
        assert.same({ "No level sync to undo." }, slash("/aa sync undo"))
        assert.equal(floorRec, ns.cdb.syncFloor, "still there for " .. route1)
        slash("/aa route " .. route1)
        H.settle(m)
        assert.equal(floorRec, UI().SyncFloor())
        assert.equal("tr-go-brill", H.cur(ns))
        m:AssertClean()
    end)

    it("delay works in ruRU", function()
        m, ns = H.boot({ locale = "ruRU" })
        local out = slash("/aa delay")
        assert.equal("Задержка автоматики: 0.5 с + случайно до 0.3 с.", out[1])
        assert.same({ "Задержка автоматики: нет, действия мгновенные." }, slash("/aa delay 0"))
    end)

    it("lock / unlock / debug / config", function()
        m, ns = H.boot()
        assert.same({ "Frames locked." }, slash("/aa lock"))
        assert.is_true(ns.db.settings.locked)
        slash("/aa unlock")
        assert.is_false(ns.db.settings.locked)
        -- resetpos: the default places again, the hidden flag untouched
        local a = arrow()
        a:GetScript("OnDragStart")(a)
        a:ClearAllPoints()
        a:SetPoint("BOTTOMLEFT", m.env.UIParent, "BOTTOMLEFT", 5, 5)
        a:GetScript("OnDragStop")(a)
        assert.equal("BOTTOMLEFT", ns.db.frames.arrow.point)
        assert.same({ "The guide window and the arrow are back at their default places." }, slash("/aa resetpos"))
        assert.same({ "TOP", m.env.UIParent, "TOP", 0, -140 }, { a:GetPoint(1) })
        assert.equal("TOPRIGHT", ns.db.frames.steps.point)
        assert.same({ "Debug output: on" }, slash("/aa debug"))
        assert.is_true(ns.IsDebug())
        slash("/aa debug")
        assert.is_false(ns.IsDebug())
        slash("/aa config")
        assert.equal(UI().Options:GetCategory():GetID(), m.settingsOpened)
        m.settingsOpened = nil
        m:EnterCombat()
        assert.same({ "Can't open the settings in combat." }, slash("/aa config"))
        assert.is_nil(m.settingsOpened)
        m:LeaveCombat()
    end)

    it("xp: export window with a loadable Lua table, chat listing and clearing", function()
        m, ns = H.boot()
        assert.same({ "No quest XP rewards recorded yet. They are recorded when you turn in quests." }, slash("/aa xp"))
        m:AddQuestToLog(363)
        m:OpenQuestComplete(363) -- turned in by the automation: 40 XP at level 1
        H.waitAuto(m, ns)
        m:SetLevel(3)
        m:AddQuestToLog(3901)
        m:CompleteObjectives(3901)
        m:TurnInQuest(3901)
        assert.same({ "2 quest XP reward(s) recorded, 290 XP in total." }, slash("/aa xp"))
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
            "  quest 3901: 250 XP (level 3)" }, slash("/aa xp chat"))
        assert.is_true(has(slash("/aa status"), "Recorded quest XP rewards: 2"))
        slash("/aa xp clear")
        assert.is_true(m:PopupVisible("ADVENTUREATLAS_XP_CLEAR"))
        local mark = #m.chat
        m:PopupClick("ADVENTUREATLAS_XP_CLEAR", "button1")
        assert.same({ "XP log cleared." }, H.chat(m, mark + 1))
        assert.is_nil(next(ns.db.xpLog))
        assert.is_nil(next(ns.db.xpLogLevel))
    end)

    it("work in ruRU", function()
        m, ns = H.boot({ locale = "ruRU" })
        local out = slash("/aa status")
        assert.is_truthy(out[2]:find("Тестовый маршрут", 1, true))
        assert.is_truthy(out[3]:find("Взять: Rude Awakening", 1, true))
        assert.is_true(has(slash("/aa help"), "/aa sync [undo] - перейти к участку маршрута по вашему уровню (undo - вернуть)"))
        assert.same({ "Маршрут соответствует вашему уровню (1): пропускать нечего." }, slash("/aa sync"))
        assert.same({ "Нечего возвращать: перехода по уровню не было." }, slash("/aa sync undo"))
        m:SetLevel(6)
        H.settle(m)
        assert.same({ "Синхронизация по уровню: у вас 6 ур. — продолжаем с «4-5 Брилл» («1-4 Мертвый Звон» пройден по "
            .. "уровню). Вернуть: /aa sync undo" }, slash("/aa sync"))
        assert.same({ "Синхронизация по уровню отменена: маршрут продолжается с прежнего места." }, slash("/aa sync undo"))
    end)
end)

-- One module with many routes (AdventureAtlas_Guides; here the fixture AdventureAtlas_TestGuides with three):
-- the settings panel and /aa routes show the routes of the character and only COUNT the others.
-- Composing a route of another class costs about 1.2 MB, so listing must never do it.
describe("route list with many routes (mixed module)", function()
    after_each(function() m:AssertClean() end)

    local function composed()
        local out = {}
        for _, r in ipairs(ns.Registry.order) do
            if ns.Registry:IsComposed(r) then out[#out + 1] = r.id end
        end
        return out
    end

    local function routeButtons()
        local list = m:FindWidgets(function(w) return type(w) == "table" and w.route ~= nil end)
        table.sort(list, function(a, b) return a:GetText() < b:GetText() end)
        return list
    end

    it("the settings panel and /aa routes leave the routes of other characters uncomposed", function()
        m, ns = H.boot({ guides = true, db = true, player = H.GUIDES_PLAYER["tg-orc-warrior"] })
        assert.same({ "tg-orc-warrior" }, composed())
        UI().Options:Open()
        local panel = UI().Options:GetPanel()
        local buttons = routeButtons()
        assert.equal(1, #buttons, "one button: the route of this character")
        assert.equal("tg-orc-warrior", buttons[1].route.id)
        assert.equal("|cff40ff40Orc Warrior 1-3 (test)|r (active)", buttons[1]:GetText())
        assert.is_true(has(texts(panel), "...and 2 more. Type /aa routes."))
        m:Enter(buttons[1])
        assert.same({ "Orc Warrior 1-3 (test)", "ID: tg-orc-warrior", "Levels 1-3", "Version: 0.0.1", "Steps: 9",
            "Test route: the start zone of the race.", "Click to make this route active for this character." },
            m:TooltipLines())
        m:Leave(buttons[1])

        assert.same({
            "Installed routes:",
            "* tg-orc-warrior - Orc Warrior 1-3 (test)",
            "Other routes (other races and classes): 2. Type /aa routes all.",
        }, slash("/aa routes"))
        assert.same({
            "Installed routes:",
            "- tg-undead-paladin - Undead Paladin 1-3 (test)",
            "* tg-orc-warrior - Orc Warrior 1-3 (test)",
            "- tg-troll-mage - Troll Mage 1-3 (test)",
        }, slash("/aa routes all"))
        assert.same({ "tg-orc-warrior" }, composed(), "neither the panel nor the listings composed a route")
        assert.equal(0, #ns.Registry.routes["tg-troll-mage"].steps)

        -- a route chosen by hand for another race / class is shown too (first), with the character's own
        assert.same({ "Route: Troll Mage 1-3 (test)" }, slash("/aa route tg-troll-mage"))
        assert.same({ "tg-orc-warrior", "tg-troll-mage" }, composed(), "choosing a route composes it")
        buttons = routeButtons()
        assert.equal(2, #buttons)
        assert.same({ "Orc Warrior 1-3 (test)", "|cff40ff40Troll Mage 1-3 (test)|r (active)" },
            { buttons[1]:GetText(), buttons[2]:GetText() })
        assert.is_true(has(texts(panel), "...and 1 more. Type /aa routes."))
        assert.same({
            "Installed routes:",
            "* tg-troll-mage - Troll Mage 1-3 (test)",
            "- tg-orc-warrior - Orc Warrior 1-3 (test)",
            "Other routes (other races and classes): 1. Type /aa routes all.",
        }, slash("/aa routes"))
        assert.is_false(ns.Registry:IsComposed(ns.Registry.routes["tg-undead-paladin"]))
        assert.same({}, ns.Registry.errors)
    end)

    it("the tooltip shows 'Steps: N' only for a composed route", function()
        m, ns = H.boot({ guides = true, db = true, player = H.GUIDES_PLAYER["tg-troll-mage"] })
        UI().Options:Open()
        local b = routeButtons()[1]
        m:Enter(b)
        assert.is_true(has(m:TooltipLines(), "Steps: 10"))
        m:Leave(b)
        -- the same button on a route that is registered but not composed (it cannot happen through
        -- the panel, which lists composed routes; the tooltip must not compose or count anyway)
        local other = ns.Registry.routes["tg-undead-paladin"]
        b.route = other
        m:Enter(b)
        local lines = m:TooltipLines()
        m:Leave(b)
        assert.equal("Undead Paladin 1-3 (test)", lines[1])
        for _, l in ipairs(lines) do assert.is_nil(l:find("^Steps:"), l) end
        assert.is_false(ns.Registry:IsComposed(other))
    end)

    it("a character no route matches: the panel and /aa routes say so and count the routes", function()
        m, ns = H.boot({ guides = true, db = true, player = { race = "Tauren", class = "DRUID", mapID = 1412, x = 44, y = 77 } })
        assert.is_nil(ns.Engine:GetRoute())
        UI().Options:Open()
        assert.equal(0, #routeButtons())
        assert.is_true(has(texts(UI().Options:GetPanel()), "No route for this character (3 installed). Type /aa routes all."))
        assert.same({
            "No route for this character.",
            "Other routes (other races and classes): 3. Type /aa routes all.",
        }, slash("/aa routes"))
        assert.equal(4, #slash("/aa routes all"))
        for _, r in ipairs(ns.Registry.order) do assert.is_false(ns.Registry:IsComposed(r), r.id) end
    end)

    it("no route module at all: the hint names AdventureAtlas_Guides (enUS, ruRU)", function()
        m, ns = H.boot({ fixture = false })
        UI().Options:Open()
        assert.is_true(has(texts(UI().Options:GetPanel()),
            "No routes installed. Enable the guides module (AdventureAtlas_Guides) in the AddOns list."))
        assert.same({ "No routes installed." }, slash("/aa routes"))
        assert.same({ "No routes installed." }, slash("/aa routes all"))
        m:AssertClean()
        m, ns = H.boot({ fixture = false, locale = "ruRU" })
        UI().Options:Open()
        assert.is_true(has(texts(UI().Options:GetPanel()),
            "Маршруты не установлены. Включите модуль гайдов (AdventureAtlas_Guides) в списке модификаций."))
    end)

    it("ruRU: the listing of the character's routes and the count of the others", function()
        m, ns = H.boot({ guides = true, db = true, locale = "ruRU", player = H.GUIDES_PLAYER["tg-orc-warrior"] })
        assert.same({
            "Установленные маршруты:",
            "* tg-orc-warrior - Орк-воин 1-3 (тест)",
            "Другие маршруты (других рас и классов): 2. Введите /aa routes all.",
        }, slash("/aa routes"))
        UI().Options:Open()
        assert.is_true(has(texts(UI().Options:GetPanel()), "...и ещё 2. Введите /aa routes."))
    end)
end)

-- Folders of the addon before the rename (FastesBoooy, its guides, the guide modules of core 0.3):
-- Adventure Atlas replaces them, so a loaded one gets a hint to delete it.
describe("obsolete addon folders", function()
    after_each(function() m:AssertClean() end)

    local function count(text)
        local n = 0
        for _, l in ipairs(H.chat(m)) do
            if l:find(text, 1, true) then n = n + 1 end
        end
        return n
    end

    it("warns once at login about every loaded old folder (enUS, ruRU)", function()
        m, ns = H.boot({ setup = function(mm)
            mm:RegisterAddOn("AdventureAtlas_Guides", { Title = "new" })
            mm:RegisterAddOn("FastesBoooy", { Title = "old core" })
            mm:RegisterAddOn("FastesBoooy_Horde", { Title = "old" })
            mm:RegisterAddOn("FastesBoooy_Guides", { Title = "old, not loaded" }, false)
        end })
        assert.same({ "FastesBoooy", "FastesBoooy_Horde" }, UI().Options:ObsoleteModules())
        local line = "Delete the old folders FastesBoooy, FastesBoooy_Horde from Interface\\AddOns: "
            .. "Adventure Atlas replaces them (AdventureAtlas and AdventureAtlas_Guides)."
        assert.equal(1, count(line))
        -- once per session: another PLAYER_LOGIN delivery does not repeat it
        ns:DispatchEvent("PLAYER_LOGIN")
        assert.equal(1, count(line))
        m:AssertClean()

        -- also without AdventureAtlas_Guides: the old folders never belong to this installation
        m, ns = H.boot({ locale = "ruRU", setup = function(mm)
            mm:RegisterAddOn("FastesBoooy_Guides", {})
        end })
        assert.equal(1, count("Удалите старые папки FastesBoooy_Guides из Interface\\AddOns: их заменил "
            .. "Adventure Atlas (AdventureAtlas и AdventureAtlas_Guides)."))
    end)

    it("says nothing without them", function()
        m, ns = H.boot({ setup = function(mm) mm:RegisterAddOn("AdventureAtlas_Guides", {}) end })
        assert.same({}, UI().Options:ObsoleteModules())
        assert.equal(0, count("Delete the old folders"))
        assert.is_false(ns.Compat.IsAddOnLoaded("FastesBoooy"))
        assert.is_true(ns.Compat.IsAddOnLoaded("AdventureAtlas_Guides"))
        assert.is_true(ns.Compat.IsAddOnLoaded("AdventureAtlas"))
    end)
end)
