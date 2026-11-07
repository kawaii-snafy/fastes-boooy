-- TOC parsing, addon loading (setfenv + addon varargs), boot sequence, SavedVariables,
-- slash commands and C_AddOns metadata of the WoW: Forever mock, with a tiny inline addon.

local Mock = require("mocks.wow")

local FILES = {
    ["TinyAddon/TinyAddon.toc"] = table.concat({
        "## Interface: 16001",
        "## Title: Tiny",
        "## Version: 1.2.3",
        "## SavedVariables: TinyDB",
        "## SavedVariablesPerCharacter: TinyCharDB",
        "# a comment line",
        "",
        "Locales\\enUS.lua",
        "Core\\Main.lua",
        "Core\\NotForever.lua [AllowLoadGameType standard]",
        "Core\\Camelot.lua [AllowLoadGameType camelot]",
        "",
    }, "\r\n"),
    ["TinyAddon/Locales/enUS.lua"] = [[
local addonName, ns = ...
ns.L = { HELLO = "Hello" }
ns.loadOrder = { "enUS:" .. addonName }
]],
    ["TinyAddon/Core/Main.lua"] = [[
local addonName, ns = ...
ns.loadOrder[#ns.loadOrder + 1] = "Main"
ns.events = {}
ns.version = C_AddOns.GetAddOnMetadata(addonName, "version")
ns.hasLegacyApi = GetQuestLogTitle ~= nil
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(_, event, ...)
    ns.events[#ns.events + 1] = { event, ... }
    if event == "ADDON_LOADED" and ... == addonName then
        TinyDB = TinyDB or { count = 0 }
        TinyDB.count = TinyDB.count + 1
        TinyCharDB = TinyCharDB or {}
        ns.loggedInAtLoad = IsLoggedIn()
    end
end)
SLASH_TINY1 = "/tiny"
SlashCmdList.TINY = function(msg) print("tiny:", msg) end
TinyGlobal = true
]],
    ["TinyAddon/Core/NotForever.lua"] = [[error("this file is not for the camelot game type")]],
    ["TinyAddon/Core/Camelot.lua"] = [[
local _, ns = ...
ns.loadOrder[#ns.loadOrder + 1] = "Camelot"
]],
    ["Broken/Broken.toc"] = "## Interface: 16001\nBroken.lua\n",
    ["Broken/Broken.lua"] = "local x = nil\nx.y = 1\n",
    ["WithXml/WithXml.toc"] = "## Interface: 16001\nFrames.xml\n",
    ["WithXml/Frames.xml"] = "<Ui/>\n",
}

local root

local function writeFiles()
    root = os.tmpname()
    os.remove(root)
    for path, content in pairs(FILES) do
        local dir = (root .. "/" .. path):match("^(.*)/[^/]+$")
        os.execute(("mkdir -p '%s'"):format(dir))
        local fh = assert(io.open(root .. "/" .. path, "wb"))
        fh:write(content)
        fh:close()
    end
end

describe("mock addon loading", function()
    setup(writeFiles)
    teardown(function() os.execute(("rm -rf '%s'"):format(root)) end)

    local function toc() return root .. "/TinyAddon/TinyAddon.toc" end

    it("parses TOC directives, comments, CRLF, backslashes and load conditions", function()
        local t = Mock.parseToc(toc())
        assert.are.equal("16001", t.meta.Interface)
        assert.are.equal("1.2.3", t.metaLower.version)
        assert.are.same({ "Locales/enUS.lua", "Core/Main.lua", "Core/Camelot.lua" }, t.files)
    end)

    it("runs each file in the client environment with (addonName, ns)", function()
        local m = Mock.new()
        local ns = Mock.loadAddon(m, toc())
        assert.are.same({ "enUS:TinyAddon", "Main", "Camelot" }, ns.loadOrder)
        assert.are.equal("1.2.3", ns.version)
        assert.is_false(ns.hasLegacyApi)
        assert.are.same({ "GetQuestLogTitle" }, m:AbsentGlobals())
        assert.is_true(rawget(m.env, "TinyGlobal"))
        assert.is_nil(rawget(_G, "TinyGlobal"))           -- nothing leaks into the host
        assert.is_true(m.env.C_AddOns.IsAddOnLoaded("TinyAddon"))
        assert.are.equal("Tiny", select(2, m.env.C_AddOns.GetAddOnInfo("TinyAddon")))
    end)

    it("boots: ADDON_LOADED (with SavedVariables), PLAYER_LOGIN, PLAYER_ENTERING_WORLD", function()
        local m = Mock.new()
        local ns = Mock.loadAddon(m, toc())
        Mock.boot(m, { "TinyAddon" })
        assert.are.same({ "ADDON_LOADED", "TinyAddon", false }, ns.events[1])
        assert.are.same({ "PLAYER_LOGIN" }, ns.events[2])
        assert.are.same({ "PLAYER_ENTERING_WORLD", true, false }, ns.events[3])
        assert.is_false(ns.loggedInAtLoad)
        assert.is_true(m.env.IsLoggedIn())
        assert.are.equal(1, m.env.TinyDB.count)
        assert.are.same({ "SLASH_TINY1", "TinyCharDB", "TinyDB", "TinyGlobal" }, m:AddonGlobals())
        m:AssertClean()
    end)

    it("restores exported SavedVariables on a simulated /reload", function()
        local m = Mock.new()
        Mock.boot(m, { { toc = toc() } })
        local saved = m:ExportSavedVariables()
        assert.are.same({ TinyDB = { count = 1 }, TinyCharDB = {} }, saved)
        local m2 = Mock.new({ savedVariables = saved })
        local ns2 = Mock.loadAddon(m2, toc())
        Mock.boot(m2, { "TinyAddon" }, { reload = true })
        assert.are.equal(2, m2.env.TinyDB.count)
        assert.are.same({ "PLAYER_ENTERING_WORLD", false, true }, ns2.events[3])
        assert.are.equal(1, saved.TinyDB.count)            -- deep copies
    end)

    it("runs slash commands registered through SLASH_* / SlashCmdList", function()
        local m = Mock.new()
        Mock.boot(m, { { toc = toc(), name = "TinyAddon" } })
        assert.is_true(m:RunSlash("/TINY hello world"))
        assert.are.equal("tiny: hello world", m.chat[#m.chat])
        assert.is_false(m:RunSlash("/unknown"))
    end)

    it("reports load errors with the file name and refuses XML files", function()
        local m = Mock.new()
        assert.has_error(function() Mock.loadAddon(m, root .. "/Broken/Broken.toc") end)
        local ok, err = pcall(Mock.loadAddon, Mock.new(), root .. "/Broken/Broken.toc")
        assert.is_false(ok)
        assert.matches("Broken.lua", err)
        assert.has_error(function() Mock.loadAddon(Mock.new(), root .. "/WithXml/WithXml.toc") end)
    end)

    it("follows the client locale", function()
        local m = Mock.new({ locale = "ruRU" })
        assert.are.equal("ruRU", m.env.GetLocale())
        assert.are.equal("enUS", Mock.new().env.GetLocale())
    end)
end)
