-- AdventureAtlas / UI / AtlasKnowledge.lua
--
-- The "Knowledge base" tab of the atlas window (UI/Atlas.lua builds and refreshes it through
-- ns.AtlasKnowledge.build / .refresh). Top to bottom:
--   filters     search box (quest name or zone), level range, "for my character", "hide done",
--               "new in Forever", the number of matches
--   list        the matching quests (ns.Knowledge:Search), a virtual list: ROWS pooled rows over the
--               results, mouse wheel and a slider scroll it; a click selects a quest
--   card        the selected quest: level, zone, required level, XP, status, who starts / ends it,
--               the chain around it, and "Lead me" (the arrow to the start, or to the end while the
--               quest is in the log: ns.Waypoint:SetCustom)
-- The data addon is loaded the first time the tab is shown (ns.Knowledge:Load). The check boxes are
-- saved in ns.db.knowledge; the search text and the levels last for the session.

-- luacheck: ignore 212/self

local _, ns = ...

local UI = ns.UI
local L = UI.L

local ipairs, pairs, tonumber, format = ipairs, pairs, tonumber, string.format
local floor, max, min = math.floor, math.max, math.min

local KB = {}
ns.AtlasKnowledge = KB

local PAGE_WIDTH = 532   -- the atlas page (UI/Atlas.lua: WIDTH - 2 * PAD)
local ROWS, ROW_HEIGHT = 10, 18
local SLIDER_WIDTH = 16
local LIST_WIDTH = PAGE_WIDTH - SLIDER_WIDTH - 6
local MARK_W, LEVEL_W, ZONE_W, TAG_W = 14, 30, 140, 48
local CHECKS = { "mine", "hideDone", "onlyNew" }

local function options()
    local db = ns.db
    if type(db.knowledge) ~= "table" then db.knowledge = {} end
    return db.knowledge
end

---------------------------------------------------------------------------
-- filters
---------------------------------------------------------------------------

local function editBox(page, width, numeric)
    local e = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    e:SetSize(width, 20)
    e:SetAutoFocus(false)
    if numeric then
        e:SetNumeric(true)
        e:SetMaxLetters(2)
    end
    e:SetScript("OnTextChanged", function(_, userInput)
        if userInput then
            page.offset = 0
            KB.refresh(page)
        end
    end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return e
end

local function buildFilters(page)
    local search = editBox(page, 210)
    search:SetPoint("TOPLEFT", page, "TOPLEFT", 6, 0)
    local hint = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", search, "LEFT", 2, 0)
    hint:SetText(L.UI_KB_SEARCH_HINT)
    page.search, page.searchHint = search, hint

    local lv = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lv:SetPoint("LEFT", search, "RIGHT", 14, 0)
    lv:SetText(L.UI_KB_LEVELS)
    local minBox = editBox(page, 28, true)
    minBox:SetPoint("LEFT", lv, "RIGHT", 8, 0)
    local dash = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dash:SetPoint("LEFT", minBox, "RIGHT", 4, 0)
    dash:SetText("-")
    local maxBox = editBox(page, 28, true)
    maxBox:SetPoint("LEFT", dash, "RIGHT", 8, 0)
    page.minBox, page.maxBox = minBox, maxBox

    local count = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    count:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -4)
    count:SetJustifyH("RIGHT")
    page.count = count

    page.checks = {}
    local prev
    for _, key in ipairs(CHECKS) do
        local cb = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        if prev then
            cb:SetPoint("LEFT", prev.label, "RIGHT", 14, -1)
        else
            cb:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -24)
        end
        local label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        label:SetPoint("LEFT", cb, "RIGHT", 0, 1)
        label:SetText(L["UI_KB_" .. key])
        cb.label, cb.key = label, key
        cb:SetScript("OnClick", function(self)
            options()[self.key] = self:GetChecked() and true or false
            page.offset = 0
            KB.refresh(page)
        end)
        page.checks[key], prev = cb, cb
    end
end

local function currentFilter(page)
    local o = options()
    return {
        text = page.search:GetText(),
        minLevel = tonumber(page.minBox:GetText()),
        maxLevel = tonumber(page.maxBox:GetText()),
        mine = o.mine ~= false,
        hideDone = o.hideDone == true,
        onlyNew = o.onlyNew == true,
    }
end

---------------------------------------------------------------------------
-- list
---------------------------------------------------------------------------

local function selectQuest(page, id)
    page.selected = id
    KB.refresh(page)
end

local function buildRow(page, i)
    local row = CreateFrame("Button", nil, page.list)
    row:SetSize(LIST_WIDTH, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", page.list, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    local mark = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mark:SetPoint("LEFT", row, "LEFT", 0, 0)
    mark:SetWidth(MARK_W)
    local level = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    level:SetPoint("LEFT", row, "LEFT", MARK_W, 0)
    level:SetWidth(LEVEL_W)
    local tag = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tag:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    tag:SetWidth(TAG_W)
    tag:SetJustifyH("RIGHT")
    tag:SetTextColor(0.4, 0.8, 1)
    local zone = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    zone:SetPoint("RIGHT", row, "RIGHT", -TAG_W - 4, 0)
    zone:SetWidth(ZONE_W)
    zone:SetJustifyH("LEFT")
    zone:SetWordWrap(false)
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("LEFT", row, "LEFT", MARK_W + LEVEL_W + 4, 0)
    name:SetWidth(LIST_WIDTH - MARK_W - LEVEL_W - 4 - ZONE_W - TAG_W - 10)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    row.mark, row.level, row.tag, row.zone, row.name = mark, level, tag, zone, name
    row:SetScript("OnClick", function(self) selectQuest(page, self.questID) end)
    return row
end

local function levelText(q)
    if q.l and q.l > 0 then return tostring(q.l) end
    return "-"
end

local function maxOffset(page)
    return max(0, #page.results - ROWS)
end

local function setOffset(page, offset)
    page.offset = max(0, min(maxOffset(page), floor(offset + 0.5)))
    KB.renderList(page)
end

local function buildList(page)
    local list = CreateFrame("Frame", nil, page)
    list:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -54)
    list:SetSize(LIST_WIDTH, ROWS * ROW_HEIGHT)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta) setOffset(page, page.offset - delta * 3) end)
    local bg = list:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(list)
    bg:SetColorTexture(0, 0, 0, 0.25)
    page.list, page.rows = list, {}
    for i = 1, ROWS do page.rows[i] = buildRow(page, i) end

    local slider = CreateFrame("Slider", nil, page)
    slider:SetPoint("TOPLEFT", list, "TOPRIGHT", 4, 0)
    slider:SetSize(SLIDER_WIDTH, ROWS * ROW_HEIGHT)
    slider:SetOrientation("VERTICAL")
    slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetMinMaxValues(0, 0)
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(slider)
    track:SetColorTexture(0, 0, 0, 0.4)
    slider:SetScript("OnValueChanged", function(_, value, userInput)
        if userInput then setOffset(page, value) end
    end)
    page.slider = slider

    local empty = page:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("TOPLEFT", list, "TOPLEFT", 6, -6)
    empty:SetWidth(LIST_WIDTH - 12)
    empty:SetJustifyH("LEFT")
    page.empty = empty
end

--- Fill the pooled rows from page.results starting at page.offset.
function KB.renderList(page)
    local K = ns.Knowledge
    local results = page.results
    page.slider:SetMinMaxValues(0, maxOffset(page))
    page.slider:SetValue(page.offset)
    page.slider:SetShown(#results > ROWS)
    for i, row in ipairs(page.rows) do
        local id = results[page.offset + i]
        local q = id and K:Get(id)
        if q then
            row.questID = id
            local status = K:Status(id)
            local r, g, b, mark = 1, 1, 1, ""
            if status == "done" then
                r, g, b, mark = 0.5, 0.5, 0.5, "+"
            elseif status == "active" then
                r, g, b, mark = 1, 0.82, 0, ">"
            end
            row.mark:SetText(mark)
            row.mark:SetTextColor(r, g, b)
            row.level:SetText(levelText(q))
            row.name:SetText(K:Title(id))
            row.name:SetTextColor(r, g, b)
            row.zone:SetText(K:ZoneName(q.z))
            row.tag:SetText(q.new and L.UI_KB_TAG_NEW or "")
            if id == page.selected then row:LockHighlight() else row:UnlockHighlight() end
            row:Show()
        else
            row.questID = nil
            row:Hide()
        end
    end
end

---------------------------------------------------------------------------
-- quest card
---------------------------------------------------------------------------

local function cardLine(page, anchor, gap, font)
    local fs = page.card:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, gap)
    fs:SetWidth(PAGE_WIDTH - 12)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return fs
end

local function buildCard(page)
    local card = CreateFrame("Frame", nil, page)
    card:SetPoint("TOPLEFT", page.list, "BOTTOMLEFT", 0, -8)
    card:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
    local bg = card:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(card)
    bg:SetColorTexture(0, 0, 0, 0.25)
    page.card = card

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 6, -6)
    title:SetWidth(PAGE_WIDTH - 12 - 160)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    page.cardTitle = title
    page.cardInfo = cardLine(page, title, -4)
    page.cardStatus = cardLine(page, page.cardInfo, -3)
    page.cardStart = cardLine(page, page.cardStatus, -3)
    page.cardEnd = cardLine(page, page.cardStart, -3)
    page.cardChain = cardLine(page, page.cardEnd, -3)

    local lead = UI.CreateButton(card, L.UI_KB_LEAD, nil, function() KB.lead(page) end, 150, 22)
    lead:SetPoint("TOPRIGHT", card, "TOPRIGHT", -6, -4)
    page.leadButton = lead
end

-- "Undertaker Mordo (Tirisfal Glades 30.2, 71.7)" for the first NPC / object of a list,
-- "item: Name" for a starting item. @return text, map, x, y (map nil: no position)
local function placeText(list)
    local K = ns.Knowledge
    if not list then return nil end
    for _, kind in ipairs({ "n", "o" }) do
        for _, id in ipairs(list[kind] or {}) do
            local name, map, x, y = K:Entity(kind, id)
            if name then
                if map then
                    local zone = ns.Compat.GetMapName(map) or ""
                    return format(L.UI_KB_PLACE_FMT, name, zone, x, y), map, x, y
                end
                return name
            end
        end
    end
    for _, id in ipairs(list.i or {}) do
        local name = K:ItemName(id)
        if name then return format(L.UI_KB_ITEM_FMT, name) end
    end
    return nil
end

local function chainText(q)
    local K = ns.Knowledge
    local before = {}
    for _, id in ipairs(q.pa or {}) do before[#before + 1] = K:Title(id) end
    for _, id in ipairs(q.py or {}) do before[#before + 1] = K:Title(id) end
    local parts = {}
    if #before > 0 then parts[#parts + 1] = format(L.UI_KB_CHAIN_BEFORE_FMT, table.concat(before, ", ")) end
    if q.nx then parts[#parts + 1] = format(L.UI_KB_CHAIN_NEXT_FMT, K:Title(q.nx)) end
    if #parts == 0 then return L.UI_KB_CHAIN_NONE end
    return table.concat(parts, "; ")
end

--- Where "Lead me" goes: the end while the quest is in the log, else the start.
local function leadTarget(q, status)
    local list = status == "active" and q.e or q.s
    local text, map, x, y = placeText(list)
    return map, x, y, text
end

function KB.renderCard(page)
    local K = ns.Knowledge
    local id = page.selected
    local q = id and K:Get(id)
    if not q then
        page.card:Hide()
        return
    end
    page.card:Show()
    local status = K:Status(id)
    page.cardTitle:SetText(format("%s [%s]", K:Title(id), levelText(q)))
    local info = { K:ZoneName(q.z), format(L.UI_KB_REQ_FMT, q.r or 1) }
    if q.x then info[#info + 1] = format(L.UI_KB_XP_FMT, q.x) end
    if q.new then info[#info + 1] = L.UI_KB_NEW end
    page.cardInfo:SetText(table.concat(info, "  -  "))
    local st
    if status == "done" then
        st = L.UI_KB_STATUS_DONE
    elseif status == "active" then
        st = L.UI_KB_STATUS_ACTIVE
    else
        st = L.UI_KB_STATUS_NONE
    end
    if not K:IsFor(q, ns.Compat.PlayerFacts()) then st = st .. "  -  " .. L.UI_KB_NOT_FOR_YOU end
    page.cardStatus:SetText(st)
    page.cardStart:SetText(format(L.UI_KB_START_FMT, placeText(q.s) or L.UI_UNKNOWN))
    page.cardEnd:SetText(format(L.UI_KB_END_FMT, placeText(q.e) or L.UI_UNKNOWN))
    page.cardChain:SetText(chainText(q))

    local custom = ns.Waypoint:GetCustom()
    local leading = custom and custom.ref == id
    local map = leadTarget(q, status)
    page.leadButton:SetText(leading and L.UI_KB_LEAD_STOP or L.UI_KB_LEAD)
    page.leadButton:SetEnabled(leading or (map ~= nil and status ~= "done"))
end

--- "Lead me" / "Stop": set or clear the arrow's target for the selected quest.
function KB.lead(page)
    local K, W = ns.Knowledge, ns.Waypoint
    local id = page.selected
    local q = id and K:Get(id)
    if not q then return end
    local custom = W:GetCustom()
    if custom and custom.ref == id then
        W:ClearCustom()
    else
        local map, x, y, text = leadTarget(q, K:Status(id))
        if not map then return end
        W:SetCustom(map, x, y, format("%s: %s", K:Title(id), text), id)
    end
    KB.refresh(page)
end

---------------------------------------------------------------------------
-- tab
---------------------------------------------------------------------------

function KB.build(page)
    page.offset, page.results = 0, {}
    buildFilters(page)
    buildList(page)
    buildCard(page)
end

function KB.refresh(page)
    local K = ns.Knowledge
    page.searchHint:SetShown(page.search:GetText() == "")
    local o = options()
    for key, cb in pairs(page.checks) do
        if key == "mine" then cb:SetChecked(o.mine ~= false) else cb:SetChecked(o[key] == true) end
    end
    local ok = K:Load()
    if not ok then
        page.results = {}
        page.count:SetText("")
        page.empty:SetText(L.UI_KB_NOT_INSTALLED)
        page.empty:Show()
        KB.renderList(page)
        page.card:Hide()
        return
    end
    page.results = K:Search(currentFilter(page))
    page.offset = min(page.offset, maxOffset(page))
    page.count:SetText(format(L.UI_KB_COUNT_FMT, #page.results))
    page.empty:SetText(L.UI_KB_NOTHING)
    page.empty:SetShown(#page.results == 0)
    KB.renderList(page)
    KB.renderCard(page)
end
