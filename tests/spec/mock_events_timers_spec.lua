-- Events, frame scripts, timers and the manual clock of the WoW: Forever mock.

local Mock = require("mocks.wow")

describe("mock events", function()
    local m, env

    before_each(function()
        m = Mock.new()
        env = m.env
    end)

    after_each(function() m:AssertClean() end)

    it("dispatches to every registered frame, including hidden ones, in registration order", function()
        local order = {}
        local a = env.CreateFrame("Frame")
        local b = env.CreateFrame("Frame")
        b:Hide()
        for name, f in pairs({ a = a, b = b }) do
            f:SetScript("OnEvent", function(self, event, questID, xp, money)
                order[#order + 1] = { name, event, questID, xp, money }
            end)
        end
        b:RegisterEvent("QUEST_TURNED_IN")
        a:RegisterEvent("QUEST_TURNED_IN")
        m:Fire("QUEST_TURNED_IN", 363, 80, 0)
        assert.are.same({ { "b", "QUEST_TURNED_IN", 363, 80, 0 }, { "a", "QUEST_TURNED_IN", 363, 80, 0 } }, order)
        a:UnregisterEvent("QUEST_TURNED_IN")
        assert.is_false(a:IsEventRegistered("QUEST_TURNED_IN"))
        m:Fire("QUEST_TURNED_IN", 364, 1, 1)
        assert.are.equal(3, #order)
    end)

    it("filters RegisterUnitEvent by unit and supports RegisterAllEvents / HookScript", function()
        local got, all, hooked = {}, 0, 0
        local f = env.CreateFrame("Frame")
        f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        f:SetScript("OnEvent", function(_, _, unit) got[#got + 1] = unit end)
        f:HookScript("OnEvent", function() hooked = hooked + 1 end)
        local g = env.CreateFrame("Frame")
        g:RegisterAllEvents()
        g:SetScript("OnEvent", function() all = all + 1 end)
        m:Fire("UNIT_SPELLCAST_SUCCEEDED", "target", "Cast-1", 1)
        m:Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", 8690)
        assert.are.same({ "player" }, got)
        assert.are.equal(1, hooked)
        assert.are.equal(2, all)
    end)

    it("rejects unknown events and payloads of the wrong type", function()
        assert.has_error(function() m:Fire("QUEST_QUERY_COMPLETE") end)
        assert.has_error(function() m:Fire("QUEST_ACCEPTED", "363") end)        -- questId:number
        assert.has_no.errors(function() m:Fire("QUEST_ACCEPTED") end)           -- missing args are allowed
        m:ClearDiagnostics()
    end)

    it("fires OnShow / OnHide along the parent chain", function()
        local log = {}
        local parent = env.CreateFrame("Frame", nil, env.UIParent)
        local child = env.CreateFrame("Frame", nil, parent)
        parent:SetScript("OnShow", function() log[#log + 1] = "parent+" end)
        parent:SetScript("OnHide", function() log[#log + 1] = "parent-" end)
        child:SetScript("OnShow", function() log[#log + 1] = "child+" end)
        child:SetScript("OnHide", function() log[#log + 1] = "child-" end)
        parent:Hide()
        assert.is_true(child:IsShown())
        assert.is_false(child:IsVisible())
        parent:Show()
        child:Hide()
        child:Hide()
        assert.are.same({ "parent-", "child-", "parent+", "child+", "child-" }, log)
    end)

    it("records an event log for assertions", function()
        m:Fire("PLAYER_REGEN_DISABLED")
        assert.are.same({ { "PLAYER_REGEN_DISABLED" } }, m:Events("PLAYER_REGEN_DISABLED"))
    end)
end)

describe("mock clock and timers", function()
    local m, env

    before_each(function()
        m = Mock.new({ time = 100, frameTime = 0.05 })
        env = m.env
    end)

    after_each(function() m:AssertClean() end)

    it("drives GetTime from the manual clock", function()
        assert.are.equal(100, env.GetTime())
        m:Advance(1.5)
        assert.is_true(math.abs(env.GetTime() - 101.5) < 1e-9)
        local t0 = env.time()
        m:Advance(10)
        assert.are.equal(t0 + 10, env.time())
    end)

    it("runs C_Timer.After callbacks once, not before the next frame", function()
        local n = 0
        env.C_Timer.After(0, function(...) n = n + 1; assert.are.equal(0, select("#", ...)) end)
        assert.are.equal(0, n)
        m:Advance(0)
        assert.are.equal(1, n)
        env.C_Timer.After(0.5, function() n = n + 10 end)
        m:Advance(0.4)
        assert.are.equal(1, n)
        m:Advance(0.2)
        assert.are.equal(11, n)
        m:Advance(5)
        assert.are.equal(11, n)
    end)

    it("supports NewTicker iterations / Cancel and NewTimer", function()
        local ticks, handle = 0, nil
        handle = env.C_Timer.NewTicker(0.25, function(h)
            ticks = ticks + 1
            assert.are.equal(handle, h)
        end, 3)
        m:Advance(2)
        assert.are.equal(3, ticks)
        local endless = 0
        local t = env.C_Timer.NewTicker(0.1, function() endless = endless + 1 end)
        m:Advance(0.55)
        t:Cancel()
        assert.is_true(t:IsCancelled())
        local before = endless
        m:Advance(1)
        assert.are.equal(before, endless)
        assert.is_true(before >= 4 and before <= 6)
        local fired = false
        local timer = env.C_Timer.NewTimer(1, function() fired = true end)
        timer:Cancel()
        m:Advance(2)
        assert.is_false(fired)
    end)

    it("fires a ticker at most once per frame", function()
        local n = 0
        env.C_Timer.NewTicker(0.001, function() n = n + 1 end)
        m:Advance(0.5)                           -- 10 frames of 0.05s
        assert.are.equal(10, n)
    end)

    it("runs OnUpdate scripts of visible frames with the frame time", function()
        local elapsed, calls = 0, 0
        local f = env.CreateFrame("Frame", nil, env.UIParent)
        f:SetScript("OnUpdate", function(_, dt) elapsed = elapsed + dt; calls = calls + 1 end)
        m:Advance(1)
        assert.are.equal(20, calls)
        assert.is_true(math.abs(elapsed - 1) < 1e-9)
        f:Hide()
        m:Advance(1)
        assert.are.equal(20, calls)
        f:Show()
        f:SetScript("OnUpdate", nil)
        m:Advance(1)
        assert.are.equal(20, calls)
    end)

    it("routes timer callback errors to the error handler and fails the Advance call", function()
        env.C_Timer.After(0, function() error("timer boom") end)
        assert.has_error(function() m:Advance(0) end)
        assert.matches("timer boom", m.errors[1].message)
        m:ClearDiagnostics()
    end)

    it("plays animation groups over time", function()
        local f = env.CreateFrame("Frame", nil, env.UIParent)
        local ag = f:CreateAnimationGroup()
        local a = ag:CreateAnimation("Alpha")
        a:SetDuration(0.3)
        a:SetFromAlpha(1)
        local finished = false
        ag:SetScript("OnFinished", function() finished = true end)
        ag:Play()
        assert.is_true(ag:IsPlaying())
        m:Advance(0.2)
        assert.is_false(finished)
        m:Advance(0.2)
        assert.is_true(finished)
        assert.is_false(ag:IsPlaying())
    end)
end)
