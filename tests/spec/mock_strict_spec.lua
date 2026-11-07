-- Strictness of the WoW: Forever mock (tests/mocks/wow.lua): only client APIs exist,
-- widgets only have their client methods, unknown templates / events raise.

local Mock = require("mocks.wow")

describe("mock strictness", function()
    local m, env

    before_each(function()
        m = Mock.new()
        env = m.env
    end)

    describe("global environment", function()
        it("contains no host-only Lua libraries", function()
            assert.is_nil(env.io)
            assert.is_nil(env.os)
            assert.is_nil(env.require)
            assert.is_nil(env.dofile)
            assert.is_nil(env.loadfile)
            assert.is_nil(env.debug)
            assert.is_nil(env.package)
            assert.are.equal(env, env._G)
        end)

        it("provides the WoW Lua extensions", function()
            assert.are.same({ "a", "b", "c" }, { env.strsplit(",", "a,b,c") })
            assert.are.same({ "a", "b,c" }, { env.strsplit(",", "a,b,c", 2) })
            assert.are.equal("x", env.strtrim("  x \t"))
            assert.are.equal("a-b", env.strjoin("-", "a", "b"))
            local t = { 1, 2 }
            assert.are.equal(t, env.wipe(t))
            assert.is_nil(t[1])
            assert.is_true(env.tContains({ 1, 2 }, 2))
            assert.are.equal(3, env.bit.band(7, 3))
            assert.are.equal(4294967295, env.bit.bnot(0))
            assert.is_true(env.string.startswith("Forever", "For"))
            assert.are.equal(5, env.math.round(4.5))
            assert.are.equal("string", env.type(env.date("%Y")))
        end)

        it("only lets the mock install names that exist in the Forever client", function()
            assert.has_error(function() m:Provide("GetQuestLogTitle", function() end) end)
            assert.has_error(function() m:Provide("TotallyMadeUp", 1) end)
            assert.has_error(function() m:ProvideNS("C_QuestLog", { GetQuestLogTitle = function() end }) end)
            assert.has_no.errors(function() m:Provide("IsLoggedIn", function() return true end) end)
        end)

        it("installs only allowlisted globals and namespace members", function()
            local A = Mock.allowlist
            local n = 0
            for name in pairs(m.provided) do
                assert.is_true(A.isGlobal(name), name)
                n = n + 1
            end
            assert.is_true(n > 200)
            for name, v in pairs(env) do
                if type(v) == "table" and A.namespaces[name] then
                    for member in pairs(v) do assert.is_true(A.isMember(name, member), name .. "." .. member) end
                end
            end
            for member in pairs(env.string) do assert.is_true(A.isMember("string", member), "string." .. member) end
            for member in pairs(env.table) do assert.is_true(A.isMember("table", member), "table." .. member) end
        end)

        it("reads globals that do not exist in Forever as nil and records them", function()
            assert.is_nil(env.GetQuestLogTitle)
            assert.is_nil(env.IsQuestFlaggedCompleted)
            assert.is_nil(env.GetItemCount)
            assert.is_nil(env.InterfaceOptions_AddCategory)
            assert.is_nil(env.C_QuestLog.GetQuestLogTitle)
            assert.has_error(function() env.GetQuestLogTitle(1) end)        -- calling it fails like in the client
            assert.are.same({ "C_QuestLog.GetQuestLogTitle", "GetItemCount", "GetQuestLogTitle",
                "InterfaceOptions_AddCategory", "IsQuestFlaggedCompleted" }, m:AbsentGlobals())
            assert.are.equal(1, m.absent["C_QuestLog.GetQuestLogTitle"])
        end)

        it("raises on client globals the mock does not implement (opts.unmocked = 'nil' reads nil)", function()
            assert.has_error(function() return env.UnitInParty end)
            assert.are.equal(1, m.unmocked.UnitInParty)
            assert.has_error(function() return env.C_QuestLog.GetQuestsOnMap end)
            local lax = Mock.new({ unmocked = "nil" })
            assert.is_nil(lax.env.UnitInParty)
            assert.are.equal(1, lax.unmocked.UnitInParty)
        end)

        it("checks documented API arguments", function()
            assert.has_error(function() env.C_QuestLog.GetInfo("1") end,
                "mock: bad argument #1 (questLogIndex) to 'C_QuestLog.GetInfo': number expected, got string")
            assert.has_error(function() env.C_Map.GetBestMapForUnit() end)
            assert.has_error(function() env.C_Timer.After(1) end)
            assert.has_error(function() env.UnitLevel() end)
            assert.has_no.errors(function() env.C_Item.GetItemCount(6948) end)   -- defaults are optional
            assert.are.equal(4, #m.violations)
            m:ClearDiagnostics()
        end)

        it("exposes Enum values from the dump and the Forever project ids", function()
            assert.are.equal(4, env.Enum.AddOnRestrictionType.Map)
            assert.are.equal(1, env.Enum.UIMapSystem.Taxi)
            assert.are.equal(18, env.WOW_PROJECT_ID)
            assert.are.equal(env.WOW_PROJECT_CAMELOT, env.WOW_PROJECT_ID)
            assert.are.equal(16001, select(4, env.GetBuildInfo()))
            assert.are.equal(1, Mock.new({ projectID = 1 }).env.WOW_PROJECT_ID)
        end)
    end)

    describe("widgets", function()
        it("have exactly the methods of their client widget type", function()
            local f = env.CreateFrame("Frame", nil, env.UIParent)
            assert.is_function(f.SetSize)
            assert.is_function(f.RegisterEvent)
            assert.is_function(f.SetResizeBounds)
            assert.is_nil(f.SetBackdrop)        -- BackdropTemplate only
            assert.is_nil(f.SetMinResize)       -- removed from the client
            assert.is_nil(f.SetText)            -- not a Frame method
            local A = Mock.allowlist
            local count = 0
            for name in pairs(A.widgetMethods.Frame) do
                assert.is_function(f[name], name)
                count = count + 1
            end
            assert.is_true(count > 200)
        end)

        it("raise an error naming an unknown method when it is called", function()
            local f = env.CreateFrame("Frame")
            assert.has_error(function() f:SetBackdrop({}) end)
            local ok, err = pcall(function() f:SetBackdrop({}) end)
            assert.is_false(ok)
            assert.matches("SetBackdrop", err)
            assert.are.equal(2, m.widgetMisses["Frame:SetBackdrop"])
            local fs = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            assert.has_error(function() fs:SetScript("OnClick", function() end) end)   -- no OnClick on a FontString
        end)

        it("reject calls with '.' instead of ':'", function()
            local f = env.CreateFrame("Frame")
            assert.has_error(function() f.Show() end)
        end)

        it("reject unknown frame types, templates and template / type mismatches", function()
            assert.has_error(function() env.CreateFrame("Texture") end)
            assert.has_error(function() env.CreateFrame("NoSuchFrameType") end)
            assert.has_error(function() env.CreateFrame("Frame", nil, nil, "ThinBorderTemplate") end)   -- absent in Forever
            assert.has_error(function() env.CreateFrame("Frame", nil, nil, "UIPanelButtonTemplate") end) -- Button template
            assert.has_no.errors(function() env.CreateFrame("button", nil, nil, "UIPanelButtonTemplate") end)
            assert.has_no.errors(function() env.CreateFrame("EventFrame") end)                          -- intrinsic
            m:ClearDiagnostics()
        end)

        it("add template members from modeled templates", function()
            local f = env.CreateFrame("Frame", nil, env.UIParent, "BackdropTemplate")
            assert.is_function(f.SetBackdrop)
            f:SetBackdrop({ bgFile = "x" })
            f:SetBackdropColor(0, 0, 0, 1)
            local b = env.CreateFrame("Button", "MyButton", env.UIParent, "UIPanelButtonTemplate")
            assert.is_table(b.Text)
            assert.are.equal(env.MyButtonText, b.Text)
            assert.are.equal(b.Text, b:GetFontString())
            assert.is_function(b:GetScript("OnEnter"))
            b:SetText("Go")
            assert.are.equal("Go", b.Text:GetText())
            local cb = env.CreateFrame("CheckButton", nil, env.UIParent, "UICheckButtonTemplate")
            assert.is_table(cb.Text)
            local s = env.CreateFrame("ScrollFrame", nil, env.UIParent, "UIPanelScrollFrameTemplate")
            assert.is_table(s.ScrollBar)
        end)

        it("reject unknown script handlers, events, points, strata, layers and fonts", function()
            local f = env.CreateFrame("Frame")
            assert.has_error(function() f:SetScript("OnClick", function() end) end)      -- Button only
            assert.has_no.errors(function() f:SetScript("OnEvent", function() end) end)
            assert.has_error(function() f:RegisterEvent("LEARNED_SPELL_IN_TAB") end)     -- not in Forever
            assert.has_error(function() f:RegisterEvent("QUEST_QUERY_COMPLETE") end)
            assert.has_no.errors(function() f:RegisterEvent("QUEST_TURNED_IN") end)
            assert.has_error(function() f:SetPoint("MIDDLE") end)
            assert.has_error(function() f:SetPoint("TOPLEFT", f) end)                    -- anchor to itself
            assert.has_error(function() f:SetFrameStrata("SUPERHIGH") end)
            assert.has_error(function() f:CreateTexture(nil, "FOREGROUND") end)
            local fs = f:CreateFontString(nil, "OVERLAY")
            assert.has_error(function() fs:SetFontObject("NoSuchFont") end)
            assert.has_no.errors(function() fs:SetFontObject("GameFontNormalSmall") end)
            assert.has_error(function() f:CreateFontString(nil, "OVERLAY", "NoSuchFontTemplate") end)
            assert.are.equal(2, #m.warnings)            -- the two unknown event registrations
            m:ClearDiagnostics()
        end)

        it("are plain tables: addon fields can be stored and read back", function()
            local f = env.CreateFrame("Frame")
            assert.is_nil(f.rows)
            f.rows = {}
            assert.is_table(f.rows)
            assert.is_nil(f.SomeCustomField)
        end)
    end)

    describe("error handling", function()
        it("records errors reaching the error handler and fails the outermost mock call", function()
            local f = env.CreateFrame("Frame")
            f:RegisterEvent("PLAYER_LOGIN")
            f:SetScript("OnEvent", function() error("boom") end)
            assert.has_error(function() m:Fire("PLAYER_LOGIN") end)
            assert.are.equal(1, #m.errors)
            assert.matches("boom", m.errors[1].message)
            assert.has_error(function() m:AssertClean() end)
        end)

        it("keeps recording without raising when opts.raiseErrors = false", function()
            local lax = Mock.new({ raiseErrors = false })
            local f = lax.env.CreateFrame("Frame")
            f:RegisterEvent("PLAYER_LOGIN")
            f:SetScript("OnEvent", function() error("boom") end)
            assert.has_no.errors(function() lax:Fire("PLAYER_LOGIN") end)
            assert.are.equal(1, #lax.errors)
        end)

        it("surfaces violations swallowed by pcall in addon code", function()
            local f = env.CreateFrame("Frame")
            f:RegisterEvent("PLAYER_LOGIN")
            f:SetScript("OnEvent", function() pcall(env.C_QuestLog.GetInfo, "bad") end)
            assert.has_error(function() m:Fire("PLAYER_LOGIN") end)
            assert.are.equal(1, #m.violations)
        end)

        it("geterrorhandler returns a handler that records", function()
            env.geterrorhandler()("reported")
            assert.are.equal("reported", m.errors[1].message)
        end)
    end)
end)
