-- Every Blizzard global, namespace member (C_X.Fn, string.x, ...) and Enum value the core
-- addon touches exists in the Forever client (tools/data/forever_api.lua): a static scan
-- of the compiled addon files (luac5.1 -l), plus run-time strictness checks of a full
-- scenario on the mock (no absent / unmocked API, no missing widget method, no errors).

local H = require("fixtures.core.helpers")
local A = H.Mock.allowlist

local ADDON_DIR = "addons/FastesBoooy/"

-- globals the core addon may create (docs/ARCHITECTURE.md + UI/Options.lua)
local OWN_GLOBALS = {
    FastesBoooy = true, FastesBoooyDB = true, FastesBoooyCharDB = true,
    SLASH_FASTESBOOOY1 = true, SLASH_FASTESBOOOY2 = true,
    FastesBoooyItemButton = true, -- UI/ItemButton.lua (named for /click macros)
}
-- fields the addon may add to Blizzard tables
local OWN_FIELDS = {
    ["SlashCmdList.FASTESBOOOY"] = true,
    ["StaticPopupDialogs.FASTESBOOOY_RESET"] = true,
    ["StaticPopupDialogs.FASTESBOOOY_XP_CLEAR"] = true,
}

-- non-function members of the Lua libraries (not in the API dump; same as .luacheckrc)
local LUA_CONSTANTS = { ["math.pi"] = true, ["math.huge"] = true }

local WRITES_A = {
    MOVE = true, LOADK = true, LOADBOOL = true, LOADNIL = true, GETUPVAL = true, NEWTABLE = true,
    ADD = true, SUB = true, MUL = true, DIV = true, MOD = true, POW = true, UNM = true, NOT = true,
    LEN = true, CONCAT = true, CLOSURE = true, FORPREP = true, FORLOOP = true,
}

local function constString(comment, which)
    -- comment holds the constants of the B / C operands in order: ; "x" "y" / ; "x" -
    local list = {}
    for tok in comment:gmatch('%S+') do list[#list + 1] = tok end
    local tok = list[which or 1]
    if tok and tok:match('^".*"$') then return tok:sub(2, -2) end
    return nil
end

--- Scan one Lua file: global reads / writes and dotted accesses rooted at a global.
local function scan(path)
    local p = assert(io.popen("luac5.1 -l -p '" .. path .. "' 2>&1"))
    local out = { reads = {}, writes = {}, fields = {}, sets = {} }
    local reg = {}
    for line in p:lines() do
        if line:match("^main <") or line:match("^function <") then reg = {} end
        local op, args, comment = line:match("^%s*%d+%s+%[%d+%]%s+(%u+)%s+([%-%d ]-)%s*;%s*(.*)$")
        if not op then
            op, args = line:match("^%s*%d+%s+%[%d+%]%s+(%u+)%s+([%-%d ]+)%s*$")
            comment = ""
        end
        if op then
            local a, b, c = args:match("^(%-?%d+)%s*(%-?%d*)%s*(%-?%d*)")
            a, b, c = tonumber(a), tonumber(b), tonumber(c)
            if op == "GETGLOBAL" then
                out.reads[comment] = true
                reg[a] = { comment }
            elseif op == "SETGLOBAL" then
                out.writes[comment] = true
            elseif (op == "GETTABLE" or op == "SELF") and b and reg[b] and c and c < 0 then
                local key = constString(comment, 1)
                local base = reg[b]
                if key then
                    local np = {}
                    for i, v in ipairs(base) do np[i] = v end
                    np[#np + 1] = key
                    out.fields[table.concat(np, ".")] = np
                    reg[a] = np
                else
                    reg[a] = nil
                end
                if op == "SELF" then reg[a + 1] = base end
            elseif op == "SETTABLE" and reg[a] and b and b < 0 then
                local key = constString(comment, 1)
                if key then out.sets[table.concat(reg[a], ".") .. "." .. key] = true end
            elseif op == "MOVE" then
                reg[a] = reg[b]
            elseif op == "CALL" or op == "TAILCALL" or op == "VARARG" or op == "TFORLOOP" then
                for r = a, a + 30 do reg[r] = nil end
            elseif WRITES_A[op] or op == "GETTABLE" or op == "SELF" then
                reg[a] = nil
            end
        end
    end
    p:close()
    return out
end

local function addonFiles()
    local toc = H.Mock.parseToc(ADDON_DIR .. "FastesBoooy.toc")
    local out = {}
    for _, f in ipairs(toc.files) do out[#out + 1] = ADDON_DIR .. f end
    return out
end

local function fieldProblem(parts)
    local owner = parts[1]
    if owner == "Enum" then
        local e = parts[2] and A.enums[parts[2]]
        if parts[2] and not e then return "unknown enum Enum." .. parts[2] end
        if parts[3] and e and e[parts[3]] == nil then return "unknown value Enum." .. parts[2] .. "." .. parts[3] end
        return nil
    end
    if owner == "Constants" then
        local c = parts[2] and A.constants[parts[2]]
        if parts[2] and not c then return "unknown Constants." .. parts[2] end
        return nil
    end
    if A.namespaces[owner] or A.luaNamespaces[owner] or A.frameXMLTables[owner] then
        if parts[2] and not A.isMember(owner, parts[2]) and not LUA_CONSTANTS[owner .. "." .. parts[2]] then
            return owner .. "." .. parts[2] .. " does not exist in the Forever client"
        end
    end
    return nil
end

describe("static API scan of the core addon", function()
    local files = addonFiles()
    local results = {}
    for _, f in ipairs(files) do results[f] = scan(f) end

    it("compiles every file listed in the TOC (Lua 5.1)", function()
        assert.equal(17, #files) -- 16 + Core/Compose.lua
        for _, f in ipairs(files) do
            local chunk, err = loadfile(f)
            assert.is_function(chunk, err)
            if not f:find("/Locales/") then assert.is_truthy(next(results[f].reads), f) end
        end
    end)

    it("reads only globals that exist in the Forever client (or its own globals)", function()
        local bad = {}
        for _, f in ipairs(files) do
            for name in pairs(results[f].reads) do
                if not A.isGlobal(name) and not OWN_GLOBALS[name] then bad[#bad + 1] = f .. ": " .. name end
            end
        end
        table.sort(bad)
        assert.same({}, bad)
    end)

    it("writes only its documented globals and Blizzard table fields", function()
        local bad = {}
        for _, f in ipairs(files) do
            for name in pairs(results[f].writes) do
                if not OWN_GLOBALS[name] then bad[#bad + 1] = f .. ": global " .. name end
            end
            for name in pairs(results[f].sets) do
                local root = name:match("^([^.]+)")
                if A.isGlobal(root) and not OWN_FIELDS[name] then bad[#bad + 1] = f .. ": field " .. name end
            end
        end
        table.sort(bad)
        assert.same({}, bad)
    end)

    it("uses only namespace members and Enum values that exist in the Forever client", function()
        local bad, seen = {}, 0
        for _, f in ipairs(files) do
            for name, parts in pairs(results[f].fields) do
                seen = seen + 1
                local problem = fieldProblem(parts)
                if problem then bad[#bad + 1] = f .. ": " .. name .. " (" .. problem .. ")" end
            end
        end
        table.sort(bad)
        assert.same({}, bad)
        assert.is_true(seen > 50, "the scan found the dotted accesses")
    end)

    it("detects APIs that do not exist in Forever (scanner self-test)", function()
        local tmp = os.tmpname()
        local fh = assert(io.open(tmp, "w"))
        fh:write("local x = GetQuestLogTitle(1)\nlocal y = C_QuestLog.GetQuestLogTitle(1)\n",
            "local z = Enum.PlayerInteractionType.NoSuchType\nlocal w = C_QuestLog.IsOnQuest(1)\n",
            "GetItemCount(5)\nSomeNewGlobal = 1\nSlashCmdList.OTHER = 1\n")
        fh:close()
        local r = scan(tmp)
        os.remove(tmp)
        assert.is_true(r.reads.GetQuestLogTitle)
        assert.is_false(A.isGlobal("GetQuestLogTitle"))
        assert.is_false(A.isGlobal("GetItemCount"))
        assert.is_true(r.writes.SomeNewGlobal)
        assert.is_true(r.sets["SlashCmdList.OTHER"])
        assert.matches("does not exist", fieldProblem(r.fields["C_QuestLog.GetQuestLogTitle"]))
        assert.is_nil(fieldProblem(r.fields["C_QuestLog.IsOnQuest"]))
        assert.matches("unknown value", fieldProblem(r.fields["Enum.PlayerInteractionType.NoSuchType"]))
    end)
end)

describe("run-time strictness of a full scenario", function()
    it("plays the test route with UI, slash commands and automation without errors, absent or unmocked APIs", function()
        local m, ns = H.boot({ locale = "ruRU", db = true })
        -- automation flows
        m:OpenQuestDetail(363, { npcID = 1568 })
        m:CloseInteraction()
        m:OpenGossip({ active = { 363 }, available = { 364 } }, 1569)
        m:CloseInteraction()
        H.settle(m)
        assert.equal("tr-train-1", H.cur(ns))
        -- the rest of the route, server side
        H.playTo(m, ns, "tr-manual")
        local f = ns.UI.StepFrame:GetFrame()
        m:Click(f.nextButton)
        H.settle(m)
        assert.is_nil(ns.Engine:GetCursor())
        for _, cmd in ipairs({ "/fb", "/fb status", "/fb routes", "/fb xp", "/fb xp chat", "/fb hide", "/fb show",
            "/fb lock", "/fb unlock", "/fb debug", "/fb debug", "/fb config", "/fb route test-route" }) do
            assert.is_true(m:RunSlash(cmd), cmd)
        end
        for _, b in ipairs({ f.prevButton, f.settingsButton }) do m:Enter(b); m:Leave(b) end
        m:Enter(ns.UI.Arrow:GetFrame())
        m:Advance(2)
        m:AssertClean()
        assert.same({}, m.errors)
        assert.same({}, m:AbsentGlobals(), "no read of a global that Forever does not have")
        assert.same({}, (function()
            local t = {}
            for k in pairs(m.unmocked) do t[#t + 1] = k end
            table.sort(t)
            return t
        end)(), "no unmocked client API")
        assert.is_nil(next(m.widgetMisses or {}), "no widget method missing in Forever")
        assert.same({}, m.warnings)
    end)
end)
