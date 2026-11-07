-- tests/mocks/wow/widgets.lua
--
-- CreateFrame and strict widget objects. A widget only has the methods and script
-- handlers its widget type has in the Forever client (tools/data/forever_api.lua
-- widgetMethods / widgetHandlers resolved along widgetInherits). Reading an unknown
-- key returns nil like the client (so `if f.SetBackdrop then` works); calling it
-- raises "attempt to call method 'X' (a nil value)". Unknown frame types, templates,
-- events, anchor points, frame strata, draw layers, justification values and
-- script handlers raise.
--
-- Widgets are plain tables (addon code may store fields on them); mock state lives
-- in the weak side table m._W[widget].

local ctx = ...
local Mock, M, A, U = ctx.Mock, ctx.M, ctx.A, ctx.U

local floor = math.floor

local POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}
local STRATA = {
    WORLD = true, BACKGROUND = true, LOW = true, MEDIUM = true, HIGH = true, DIALOG = true,
    FULLSCREEN = true, FULLSCREEN_DIALOG = true, TOOLTIP = true, BLIZZARD = true, PARENT = true,
}
local LAYERS = { BACKGROUND = true, BORDER = true, ARTWORK = true, OVERLAY = true, HIGHLIGHT = true }
local JUSTIFY_H = { LEFT = true, CENTER = true, RIGHT = true }
local JUSTIFY_V = { TOP = true, MIDDLE = true, BOTTOM = true }
local BLEND = { DISABLE = true, BLEND = true, ALPHAKEY = true, ADD = true, MOD = true }
local ORIENT = { HORIZONTAL = true, VERTICAL = true }
local TOOLTIP_ANCHORS = {
    ANCHOR_TOP = true, ANCHOR_RIGHT = true, ANCHOR_BOTTOM = true, ANCHOR_LEFT = true,
    ANCHOR_TOPRIGHT = true, ANCHOR_BOTTOMRIGHT = true, ANCHOR_TOPLEFT = true, ANCHOR_BOTTOMLEFT = true,
    ANCHOR_CURSOR = true, ANCHOR_PRESERVE = true, ANCHOR_NONE = true, ANCHOR_CURSOR_RIGHT = true,
    ANCHOR_CURSOR_LEFT = true,
}

-- Intrinsic frame types usable as CreateFrame's frameType (BIR Templates.lua intrinsic = true).
local INTRINSIC = {
    EventFrame = true, DropdownButton = true, DropDownToggleButton = true, ItemButton = true,
    EventButton = true, EventEditBox = true, EventScrollFrame = true, ScrollingMessageFrame = true,
    ContainedAlertFrame = true, AuraButton = true, AuraContainer = true, UIThemeContainerFrame = true,
}

local function err(level, fmt, ...)
    error(string.format(fmt, ...), level + 1)
end

---------------------------------------------------------------------------
-- core helpers
---------------------------------------------------------------------------

local function isVisible(m, st)
    while st do
        if not st.shown then return false end
        if not st.parent then return true end
        st = m._W[st.parent]
    end
    return true
end

function M:_runScript(obj, handler, ...)
    local st = self._W[obj]
    if not st then return end
    local fn = st.scripts[handler]
    if fn then self:_safecall(fn, obj, ...) end
    local hooks = st.hooks[handler]
    if hooks then
        for _, h in ipairs(hooks) do self:_safecall(h, obj, ...) end
    end
end

local function fireVisibility(m, obj, handler)
    local st = m._W[obj]
    m:_runScript(obj, handler)
    for _, child in ipairs(st.children) do
        local cst = m._W[child]
        if cst and cst.shown then fireVisibility(m, child, handler) end
    end
    for _, r in ipairs(st.regions) do
        local rst = m._W[r]
        if rst and rst.shown and next(rst.scripts) then m:_runScript(r, handler) end
    end
end

local function setShown(m, obj, st, shown)
    shown = shown and true or false
    if st.shown == shown then return end
    local was = isVisible(m, st)
    st.shown = shown
    local now = isVisible(m, st)
    if st.type == "GameTooltip" and not shown then
        st.owner, st.lines = nil, {}
        m:_runScript(obj, "OnTooltipCleared")
    end
    if was ~= now then fireVisibility(m, obj, now and "OnShow" or "OnHide") end
end

local function widgetOf(m, v)
    if type(v) == "string" then v = rawget(m.env, v) end
    if type(v) == "table" and m._W[v] then return v end
    return nil
end

local function fontNameValid(m, name)
    if A.fonts[name] then return true end
    local obj = rawget(m.env, name)
    return obj ~= nil and m._W[obj] ~= nil and m._W[obj].type == "Font"
end

local function resolveFont(m, v, level)
    if v == nil then return nil end
    if type(v) == "string" then
        if not fontNameValid(m, v) then err(level + 1, "unknown font object %q (not in the Forever client)", v) end
        return m.env[v]
    end
    local st = type(v) == "table" and m._W[v]
    if st and (st.type == "Font" or st.type == "FontString") then return v end
    err(level + 1, "SetFontObject: font object or font name expected, got %s", type(v))
end

local function textOf(v, level, method)
    if v == nil then return "" end
    local tv = type(v)
    if tv == "number" then return tostring(v) end
    if tv ~= "string" then err(level + 1, "bad argument #1 to '%s' (string expected, got %s)", method, tv) end
    return v
end

local function numArg(v, i, method, level)
    if type(v) ~= "number" then
        err(level + 1, "bad argument #%d to '%s' (number expected, got %s)", i, method, type(v))
    end
    return v
end

---------------------------------------------------------------------------
-- method implementations: IMPL[name] = function(m, self, st, ...)
---------------------------------------------------------------------------

local IMPL = {}

-- identity ---------------------------------------------------------------
function IMPL.GetName(_, _, st) return st.name end
function IMPL.GetDebugName(_, _, st) return st.name or ("<" .. st.objType .. ">") end
function IMPL.GetObjectType(_, _, st) return st.objType end
function IMPL.IsObjectType(_, _, st, t)
    if type(t) ~= "string" then return false end
    for anc in pairs(A.widgetIsA[st.type] or {}) do
        if anc:lower() == t:lower() then return true end
    end
    return false
end
function IMPL.IsForbidden() return false end

-- Protected frames (minimal model): a frame created from a secure template is explicitly
-- protected; a frame is implicitly protected when a protected frame is its descendant or is
-- anchored to it (moving / hiding it would move / hide the protected frame). UIParent and
-- WorldFrame are left out (Blizzard frames). During combat lockdown (m.player.inCombat) the
-- RESTRICTED methods on a protected frame are blocked: the client fires ADDON_ACTION_BLOCKED,
-- the mock records a violation and raises.
local function protectedState(m, obj, st)
    if st.protected then return true, true end
    local list = m._protected
    if not list or #list == 0 or st.isRegion then return false, false end
    local env = m.env
    if obj == rawget(env, "UIParent") or obj == rawget(env, "WorldFrame") then return false, false end
    for _, p in ipairs(list) do
        local pst = m._W[p]
        if p ~= obj and pst then
            local a = pst.parent
            while a do
                if a == obj then return true, false end
                a = m._W[a] and m._W[a].parent
            end
            for _, pt in ipairs(pst.points) do
                if pt[2] == obj then return true, false end
            end
        end
    end
    return false, false
end
M._protectedState = protectedState

local RESTRICTED = {
    Show = true, Hide = true, SetShown = true, SetPoint = true, SetAllPoints = true, ClearAllPoints = true,
    ClearPoint = true, AdjustPointsOffset = true, SetSize = true, SetWidth = true, SetHeight = true,
    SetScale = true, SetParent = true, StartMoving = true, StartSizing = true, SetAttribute = true,
    EnableMouse = true, SetFrameStrata = true, SetFrameLevel = true, RegisterForClicks = true, SetID = true,
}
Mock.RESTRICTED_METHODS = RESTRICTED

function IMPL.IsProtected(m, self, st) return protectedState(m, self, st) end
function IMPL.CanChangeProtectedState(m, self, st)
    if m.player.inCombat ~= true then return true end
    return not protectedState(m, self, st)
end
function IMPL.HasSecretValues() return false end
function IMPL.IsPreventingSecretValues() return false end
function IMPL.GetParent(_, _, st) return st.parent end
function IMPL.SetParent(m, self, st, parent)
    local p = nil
    if parent ~= nil then
        p = widgetOf(m, parent)
        if not p then err(3, "%s:SetParent(): invalid parent", st.objType) end
        if p == self then err(3, "%s:SetParent(): cannot set a widget as its own parent", st.objType) end
    end
    local was = isVisible(m, st)
    if st.parent then
        local pst = m._W[st.parent]
        local list = st.isRegion and pst.regions or pst.children
        for i, c in ipairs(list) do if c == self then table.remove(list, i); break end end
    end
    st.parent = p
    if p then
        local pst = m._W[p]
        local list = st.isRegion and pst.regions or pst.children
        list[#list + 1] = self
    end
    local now = isVisible(m, st)
    if was ~= now and not st.isRegion then fireVisibility(m, self, now and "OnShow" or "OnHide") end
end
function IMPL.GetChildren(m, _, st)
    return unpack(st.children)
end
function IMPL.GetNumChildren(_, _, st) return #st.children end
function IMPL.GetRegions(_, _, st) return unpack(st.regions) end
function IMPL.GetNumRegions(_, _, st) return #st.regions end
function IMPL.SetParentKey(m, self, st, key)
    st.parentKey = key
    if st.parent then st.parent[key] = self end
end
function IMPL.GetParentKey(_, _, st) return st.parentKey end
function IMPL.ClearParentKey(_, _, st) st.parentKey = nil end

-- visibility -------------------------------------------------------------
function IMPL.Show(m, self, st) setShown(m, self, st, true) end
function IMPL.Hide(m, self, st) setShown(m, self, st, false) end
function IMPL.SetShown(m, self, st, shown) setShown(m, self, st, shown) end
function IMPL.IsShown(_, _, st) return st.shown end
function IMPL.IsVisible(m, _, st) return isVisible(m, st) end
function IMPL.FadeOut(m, self, st) setShown(m, self, st, false) end

-- anchors & size -----------------------------------------------------------
function IMPL.SetPoint(m, self, st, point, ...)
    if type(point) ~= "string" or not POINTS[point:upper()] then
        err(3, "%s:SetPoint(): Invalid region point %s", st.objType, tostring(point))
    end
    point = point:upper()
    local n = select("#", ...)
    local a1, a2, a3, a4, a5 = ...
    local rel, relPoint, x, y
    -- SetPoint(point) (n == 0): relative to the parent, same point
    if n > 0 and type(a1) == "number" then
        x, y = a1, a2                                     -- SetPoint(point, x, y)
    elseif n > 0 and (a1 == nil or type(a1) == "table" or (type(a1) == "string" and not POINTS[a1:upper()])) then
        if a1 ~= nil then
            rel = widgetOf(m, a1)
            if not rel then err(3, "%s:SetPoint(): Couldn't find region named '%s'", st.objType, tostring(a1)) end
        end
        if type(a2) == "string" then
            if not POINTS[a2:upper()] then err(3, "%s:SetPoint(): Invalid relative point %s", st.objType, a2) end
            relPoint, x, y = a2:upper(), a3, a4
        else
            x, y = a2, a3
        end
    elseif n > 0 then
        relPoint, x, y = a1:upper(), a2, a3                -- SetPoint(point, relativePoint, x, y)
    end
    if (x ~= nil and type(x) ~= "number") or (y ~= nil and type(y) ~= "number") then
        err(3, "%s:SetPoint(): offsets must be numbers", st.objType)
    end
    if rel == self then err(3, "%s:SetPoint(): Cannot anchor to itself", st.objType) end
    rel = rel or st.parent
    relPoint = relPoint or point
    for idx, p in ipairs(st.points) do
        if p[1] == point then table.remove(st.points, idx); break end
    end
    st.points[#st.points + 1] = { point, rel, relPoint, x or 0, y or 0 }
    local _ = a5
end
function IMPL.SetAllPoints(m, self, st, rel)
    local r = rel and widgetOf(m, rel) or st.parent
    if rel ~= nil and not r then err(3, "%s:SetAllPoints(): invalid relative region", st.objType) end
    st.points = { { "TOPLEFT", r, "TOPLEFT", 0, 0 }, { "BOTTOMRIGHT", r, "BOTTOMRIGHT", 0, 0 } }
    st.allPoints = r
end
function IMPL.ClearAllPoints(_, _, st) st.points = {}; st.allPoints = nil end
function IMPL.ClearPoint(_, _, st, point)
    for idx, p in ipairs(st.points) do
        if p[1] == point then table.remove(st.points, idx); return end
    end
end
function IMPL.GetNumPoints(_, _, st) return #st.points end
function IMPL.GetPoint(_, _, st, i)
    local p = st.points[i or 1]
    if not p then return nil end
    return p[1], p[2], p[3], p[4], p[5]
end
function IMPL.GetPointByName(_, _, st, name)
    for _, p in ipairs(st.points) do
        if p[1] == name then return p[1], p[2], p[3], p[4], p[5] end
    end
end
function IMPL.AdjustPointsOffset(_, _, st, dx, dy)
    for _, p in ipairs(st.points) do p[4], p[5] = p[4] + (dx or 0), p[5] + (dy or 0) end
end

local function width(m, st)
    if st.width then return st.width end
    if st.allPoints and m._W[st.allPoints] then return width(m, m._W[st.allPoints]) end
    if st.type == "FontString" then return IMPL.GetStringWidth(m, nil, st) end
    return 0
end
local function height(m, st)
    if st.height then return st.height end
    if st.allPoints and m._W[st.allPoints] then return height(m, m._W[st.allPoints]) end
    if st.type == "FontString" then return IMPL.GetStringHeight(m, nil, st) end
    return 0
end
function IMPL.SetWidth(_, self, st, w)
    st.width = numArg(w, 1, st.objType .. ":SetWidth", 3)
end
function IMPL.SetHeight(_, self, st, h)
    st.height = numArg(h, 1, st.objType .. ":SetHeight", 3)
end
function IMPL.SetSize(_, self, st, w, h)
    st.width = numArg(w, 1, st.objType .. ":SetSize", 3)
    st.height = numArg(h, 2, st.objType .. ":SetSize", 3)
end
function IMPL.GetWidth(m, _, st) return width(m, st) end
function IMPL.GetHeight(m, _, st) return height(m, st) end
function IMPL.GetSize(m, _, st) return width(m, st), height(m, st) end
function IMPL.GetRect(m, _, st)
    if #st.points == 0 then return nil end
    return 0, 0, width(m, st), height(m, st)
end
function IMPL.GetScaledRect(m, self, st) return IMPL.GetRect(m, self, st) end
function IMPL.GetLeft(_, _, st) if #st.points > 0 then return 0 end end
function IMPL.GetBottom(_, _, st) if #st.points > 0 then return 0 end end
function IMPL.GetRight(m, _, st) if #st.points > 0 then return width(m, st) end end
function IMPL.GetTop(m, _, st) if #st.points > 0 then return height(m, st) end end
function IMPL.GetCenter(m, _, st)
    if #st.points == 0 then return nil end
    return width(m, st) / 2, height(m, st) / 2
end
function IMPL.IsRectValid(_, _, st) return #st.points > 0 end
function IMPL.SetScale(_, _, st, s)
    numArg(s, 1, st.objType .. ":SetScale", 3)
    if s <= 0 then err(3, "%s:SetScale(): Scale must be > 0", st.objType) end
    st.scale = s
end
function IMPL.GetScale(_, _, st) return st.scale end
function IMPL.GetEffectiveScale(m, _, st)
    local s = 1
    while st do
        s = s * (st.scale or 1)
        st = st.parent and m._W[st.parent]
    end
    return s
end
function IMPL.SetAlpha(_, _, st, a)
    numArg(a, 1, st.objType .. ":SetAlpha", 3)
    st.alpha = math.max(0, math.min(1, a))
end
function IMPL.GetAlpha(_, _, st) return st.alpha end
function IMPL.GetEffectiveAlpha(m, _, st)
    local a = 1
    while st do
        a = a * (st.alpha or 1)
        st = st.parent and m._W[st.parent]
    end
    return a
end

-- scripts ------------------------------------------------------------------
local function checkHandler(st, handler, method)
    if type(handler) ~= "string" or not (A.widgetHandlers[st.type] or {})[handler] then
        err(4, "%s:%s(): %s doesn't have a \"%s\" script", st.objType, method, st.objType, tostring(handler))
    end
end
function IMPL.SetScript(m, self, st, handler, fn)
    checkHandler(st, handler, "SetScript")
    if fn ~= nil and type(fn) ~= "function" then
        err(3, "%s:SetScript(): script must be a function or nil", st.objType)
    end
    st.scripts[handler] = fn
    st.hooks[handler] = nil
    if handler == "OnUpdate" then m:_trackUpdate(self, st) end
end
function IMPL.GetScript(_, _, st, handler)
    checkHandler(st, handler, "GetScript")
    return st.scripts[handler]
end
function IMPL.HookScript(m, self, st, handler, fn)
    checkHandler(st, handler, "HookScript")
    if type(fn) ~= "function" then err(3, "%s:HookScript(): function expected", st.objType) end
    if not st.scripts[handler] then
        st.scripts[handler] = fn
    else
        st.hooks[handler] = st.hooks[handler] or {}
        table.insert(st.hooks[handler], fn)
    end
    if handler == "OnUpdate" then m:_trackUpdate(self, st) end
end
function IMPL.HasScript(_, _, st, handler)
    return type(handler) == "string" and (A.widgetHandlers[st.type] or {})[handler] == true
end
function IMPL.ClearScripts(_, _, st) st.scripts, st.hooks = {}, {} end

-- events -------------------------------------------------------------------
local function checkEvent(m, st, event, method)
    if type(event) ~= "string" or not A.events[event] then
        m:_warn(("%s:%s(%s): unknown event"):format(st.objType, method, tostring(event)))
        err(4, "%s:%s(): Attempt to register unknown event \"%s\"", st.objType, method, tostring(event))
    end
end
function IMPL.RegisterEvent(m, self, st, event)
    checkEvent(m, st, event, "RegisterEvent")
    m:_registerEvent(self, event, nil)
    return true
end
function IMPL.RegisterUnitEvent(m, self, st, event, ...)
    checkEvent(m, st, event, "RegisterUnitEvent")
    local units = {}
    for i = 1, select("#", ...) do
        local u = select(i, ...)
        if u ~= nil then units[#units + 1] = u end
    end
    m:_registerEvent(self, event, units)
    return true
end
function IMPL.UnregisterEvent(m, self, st, event)
    checkEvent(m, st, event, "UnregisterEvent")
    m:_unregisterEvent(self, event)
    return true
end
function IMPL.IsEventRegistered(m, self, _, event) return m:_isEventRegistered(self, event) end
function IMPL.RegisterAllEvents(m, self)
    if not m._allEvents[self] then
        m._allEvents[self] = true
        m._allEventsOrder[#m._allEventsOrder + 1] = self
    end
end
function IMPL.UnregisterAllEvents(m, self) m:_unregisterAll(self) end

-- child regions ------------------------------------------------------------
local function checkLayer(st, layer, method)
    if layer ~= nil and (type(layer) ~= "string" or not LAYERS[layer]) then
        err(4, "%s:%s(): Unknown draw layer %s", st.objType, method, tostring(layer))
    end
end
local function checkTemplateType(m, template, wanted, method)
    if template == nil then return end
    for name in tostring(template):gmatch("[^,%s]+") do
        if not A.templates[name] then
            m:_violation(("%s: unknown template %q (not in the Forever client)"):format(method, name), 4)
        end
        local tt = A.templateTypes[name]
        if wanted and not wanted[tt] then
            m:_violation(("%s: template %q is a %s template"):format(method, name, tostring(tt)), 4)
        end
    end
end
function IMPL.CreateTexture(m, self, st, name, layer, template, subLevel)
    checkLayer(st, layer, "CreateTexture")
    checkTemplateType(m, template, { Texture = true }, st.objType .. ":CreateTexture")
    if subLevel ~= nil and (type(subLevel) ~= "number" or subLevel < -8 or subLevel > 7) then
        err(3, "%s:CreateTexture(): subLevel must be between -8 and 7", st.objType)
    end
    local t = m:_newWidget("Texture", name, self, { layer = layer or "ARTWORK", subLevel = subLevel or 0 })
    return t
end
function IMPL.CreateMaskTexture(m, self, st, name, layer, template, subLevel)
    checkLayer(st, layer, "CreateMaskTexture")
    checkTemplateType(m, template, { Texture = true, MaskTexture = true }, st.objType .. ":CreateMaskTexture")
    return m:_newWidget("MaskTexture", name, self, { layer = layer or "ARTWORK", subLevel = subLevel or 0 })
end
function IMPL.CreateLine(m, self, st, name, layer, template, subLevel)
    checkLayer(st, layer, "CreateLine")
    checkTemplateType(m, template, { Line = true }, st.objType .. ":CreateLine")
    return m:_newWidget("Line", name, self, { layer = layer or "ARTWORK", subLevel = subLevel or 0 })
end
function IMPL.CreateFontString(m, self, st, name, layer, template)
    checkLayer(st, layer, "CreateFontString")
    local fontObj
    if template ~= nil then
        for tname in tostring(template):gmatch("[^,%s]+") do
            if not fontNameValid(m, tname) then
                checkTemplateType(m, tname, { Font = true, FontString = true, FontFamily = true },
                    st.objType .. ":CreateFontString")
            end
            fontObj = fontObj or (fontNameValid(m, tname) and m.env[tname]) or nil
        end
    end
    local fs = m:_newWidget("FontString", name, self, { layer = layer or "ARTWORK" })
    m._W[fs].fontObject = fontObj
    return fs
end
function IMPL.CreateAnimationGroup(m, self, st, name, template)
    checkTemplateType(m, template, { AnimationGroup = true }, st.objType .. ":CreateAnimationGroup")
    local ag = m:_newWidget("AnimationGroup", name, nil, {})
    m._W[ag].parent = self
    st.animGroups = st.animGroups or {}
    st.animGroups[#st.animGroups + 1] = ag
    return ag
end
function IMPL.GetAnimationGroups(_, _, st) return unpack(st.animGroups or {}) end
function IMPL.StopAnimating(m, _, st)
    for _, ag in ipairs(st.animGroups or {}) do
        local ast = m._W[ag]
        if ast.playing then ast.playing = false; m:_runScript(ag, "OnStop", false) end
    end
end

-- text (FontString / Button / EditBox / FontInstance) ----------------------
local function buttonFontString(m, self, st, create)
    if not st.fontString and create then
        st.fontString = m:_newWidget("FontString", nil, self, { layer = "ARTWORK" })
    end
    return st.fontString
end
function IMPL.SetText(m, self, st, text)
    local s = textOf(text, 3, st.objType .. ":SetText")
    if st.type == "Button" or st.type == "CheckButton" or A.widgetIsA[st.type].Button then
        local fs = buttonFontString(m, self, st, true)
        m._W[fs].text = s
        return
    end
    if st.type == "GameTooltip" then
        st.lines = { { left = s } }
        return
    end
    local old = st.text
    st.text = s
    if st.type == "EditBox" then
        st.cursor = #s
        if old ~= s then m:_runScript(self, "OnTextChanged", false) end
        m:_runScript(self, "OnTextSet")
    end
end
function IMPL.GetText(m, self, st)
    if A.widgetIsA[st.type].Button then
        local fs = st.fontString
        return fs and m._W[fs].text or nil
    end
    if st.type == "EditBox" then return st.text or "" end
    return st.text
end
function IMPL.SetFormattedText(m, self, st, fmt, ...)
    if type(fmt) ~= "string" then err(3, "%s:SetFormattedText(): format string expected", st.objType) end
    return IMPL.SetText(m, self, st, string.format(fmt, ...))
end
function IMPL.ClearText(_, _, st) st.text = "" end
local function strWidth(st)
    local text = st.text or ""
    local maxLen = 0
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        local _, n = line:gsub("[^\128-\191]", "")
        if n > maxLen then maxLen = n end
    end
    return maxLen * 6
end
function IMPL.GetStringWidth(_, _, st) return strWidth(st) end
function IMPL.GetUnboundedStringWidth(_, _, st) return strWidth(st) end
function IMPL.GetStringHeight(_, _, st)
    local text = st.text or ""
    if text == "" then return 0 end
    local _, n = text:gsub("\n", "")
    return (n + 1) * 12
end
function IMPL.GetNumLines(_, _, st)
    local text = st.text or ""
    if text == "" then return 0 end
    local _, n = text:gsub("\n", "")
    return n + 1
end
function IMPL.GetLineHeight() return 12 end
function IMPL.IsTruncated() return false end
function IMPL.GetFontString(_, _, st) return st.fontString end
function IMPL.SetFontString(m, self, st, fs)
    local f = widgetOf(m, fs)
    if not f or m._W[f].type ~= "FontString" then err(3, "%s:SetFontString(): FontString expected", st.objType) end
    st.fontString = f
end
function IMPL.GetTextWidth(m, self, st)
    local fs = st.fontString
    return fs and strWidth(m._W[fs]) or 0
end
function IMPL.GetTextHeight(m, self, st)
    local fs = st.fontString
    return fs and IMPL.GetStringHeight(m, nil, m._W[fs]) or 0
end
function IMPL.SetFont(_, _, st, file, size, flags)
    if type(file) ~= "string" and type(file) ~= "number" then
        err(3, "%s:SetFont(): font file expected", st.objType)
    end
    st.font = { file, size or 12, flags or "" }
    return true
end
function IMPL.GetFont(m, _, st)
    if st.font then return st.font[1], st.font[2], st.font[3] end
    local fo = st.fontObject and m._W[st.fontObject]
    if fo and fo.font then return fo.font[1], fo.font[2], fo.font[3] end
    return "Fonts\\FRIZQT__.TTF", 12, ""
end
function IMPL.SetFontObject(m, _, st, obj)
    st.fontObject = resolveFont(m, obj, 3)
end
function IMPL.GetFontObject(_, _, st) return st.fontObject end
function IMPL.SetTextColor(_, _, st, r, g, b, a) st.textColor = { r or 1, g or 1, b or 1, a or 1 } end
function IMPL.GetTextColor(_, _, st)
    local c = st.textColor or { 1, 1, 1, 1 }
    return c[1], c[2], c[3], c[4]
end
function IMPL.SetJustifyH(_, _, st, v)
    if type(v) ~= "string" or not JUSTIFY_H[v:upper()] then err(3, "%s:SetJustifyH(): invalid value %s", st.objType, tostring(v)) end
    st.justifyH = v:upper()
end
function IMPL.GetJustifyH(_, _, st) return st.justifyH or "CENTER" end
function IMPL.SetJustifyV(_, _, st, v)
    if type(v) ~= "string" or not JUSTIFY_V[v:upper()] then err(3, "%s:SetJustifyV(): invalid value %s", st.objType, tostring(v)) end
    st.justifyV = v:upper()
end
function IMPL.GetJustifyV(_, _, st) return st.justifyV or "MIDDLE" end
for _, kind in ipairs({ "Normal", "Highlight", "Disabled" }) do
    IMPL["Set" .. kind .. "FontObject"] = function(m, _, st, obj)
        st[kind .. "Font"] = resolveFont(m, obj, 3)
    end
    IMPL["Get" .. kind .. "FontObject"] = function(_, _, st) return st[kind .. "Font"] end
end

-- textures -----------------------------------------------------------------
function IMPL.SetTexture(_, _, st, tex)
    if tex ~= nil and type(tex) ~= "string" and type(tex) ~= "number" then
        err(3, "%s:SetTexture(): texture path or fileID expected", st.objType)
    end
    st.texture, st.atlas, st.color = tex, nil, nil
    return true
end
function IMPL.GetTexture(_, _, st) return st.texture or st.atlas end
function IMPL.GetTextureFilePath(_, _, st) return st.texture end
function IMPL.GetTextureFileID(_, _, st) return type(st.texture) == "number" and st.texture or nil end
-- Tex coords: like the client, SetAtlas sets them to the atlas member's sub-rectangle
-- and both SetAtlas and SetTexture carry the previous coords forward (Forever
-- FrameXML Blizzard_ItemButton/Mainline/ItemButtonTemplate.lua). Modelled with
-- st.atlasCoords = atlas whose sub-rectangle is in effect (nil = explicit
-- st.texCoord / full texture); a plain texture drawn with atlas coords is cropped.
function IMPL.SetAtlas(_, _, st, atlas, useAtlasSize, _, resetTexCoords) -- 6th: filterMode
    if type(atlas) ~= "string" then err(3, "%s:SetAtlas(): atlas name expected", st.objType) end
    st.atlas, st.texture, st.color = atlas, nil, nil
    st.atlasCoords = atlas
    if resetTexCoords then st.texCoord = nil end
    if useAtlasSize then st.width, st.height = st.width or 32, st.height or 32 end
    return true
end
function IMPL.GetAtlas(_, _, st) return st.atlas end
function IMPL.SetColorTexture(_, _, st, r, g, b, a)
    st.color = { r or 1, g or 1, b or 1, a or 1 }
    st.texture, st.atlas = nil, nil
end
function IMPL.SetVertexColor(_, _, st, r, g, b, a) st.vertexColor = { r or 1, g or 1, b or 1, a or 1 } end
function IMPL.GetVertexColor(_, _, st)
    local c = st.vertexColor or { 1, 1, 1, 1 }
    return c[1], c[2], c[3], c[4]
end
function IMPL.SetTexCoord(_, _, st, ...)
    st.texCoord = { ... }
    st.atlasCoords = nil
end
function IMPL.GetTexCoord(_, _, st)
    if st.atlasCoords and st.texture ~= nil then
        -- a plain texture still drawn with the sub-rectangle of a previous atlas
        return 0.25, 0.25, 0.25, 0.5, 0.5, 0.25, 0.5, 0.5
    end
    local c = st.texCoord
    if not c or #c == 0 then return 0, 0, 0, 1, 1, 0, 1, 1 end
    if #c == 4 then return c[1], c[3], c[1], c[4], c[2], c[3], c[2], c[4] end
    return unpack(c)
end
function IMPL.SetRotation(_, _, st, rad)
    numArg(rad, 1, st.objType .. ":SetRotation", 3)
    st.rotation = rad
end
function IMPL.GetRotation(_, _, st) return st.rotation or 0 end
function IMPL.SetDesaturated(_, _, st, b) st.desaturated = b and true or false end
function IMPL.IsDesaturated(_, _, st) return st.desaturated == true end
function IMPL.SetBlendMode(_, _, st, mode)
    if type(mode) ~= "string" or not BLEND[mode] then err(3, "%s:SetBlendMode(): invalid blend mode %s", st.objType, tostring(mode)) end
    st.blend = mode
end
function IMPL.GetBlendMode(_, _, st) return st.blend or "BLEND" end
function IMPL.SetDrawLayer(_, _, st, layer, sub)
    if type(layer) ~= "string" or not LAYERS[layer] then err(3, "%s:SetDrawLayer(): Unknown draw layer %s", st.objType, tostring(layer)) end
    st.layer, st.subLevel = layer, sub or 0
end
function IMPL.GetDrawLayer(_, _, st) return st.layer or "ARTWORK", st.subLevel or 0 end

-- buttons ------------------------------------------------------------------
local BUTTON_TEXTURES = { "Normal", "Highlight", "Pushed", "Disabled", "Checked", "DisabledChecked", "Thumb" }
for _, kind in ipairs(BUTTON_TEXTURES) do
    local key = kind .. "Texture"
    IMPL["Set" .. key] = function(m, self, st, asset, blend)
        if asset == nil then st[key] = nil; return end
        local w = type(asset) == "table" and widgetOf(m, asset)
        if w then st[key] = w; return end
        if type(asset) ~= "string" and type(asset) ~= "number" then
            err(3, "%s:Set%s(): texture expected", st.objType, key)
        end
        local tex = st[key] or m:_newWidget("Texture", nil, self, { layer = "ARTWORK" })
        m._W[tex].texture = asset
        if blend then m._W[tex].blend = blend end
        st[key] = tex
    end
    IMPL["Get" .. key] = function(_, _, st) return st[key] end
    IMPL["Clear" .. key] = function(_, _, st) st[key] = nil end
    IMPL["Set" .. kind .. "Atlas"] = function(m, self, st, atlas)
        if type(atlas) ~= "string" then err(3, "%s:Set%sAtlas(): atlas expected", st.objType, kind) end
        local tex = st[key] or m:_newWidget("Texture", nil, self, { layer = "ARTWORK" })
        m._W[tex].atlas = atlas
        st[key] = tex
    end
end
function IMPL.Enable(m, self, st)
    if not st.enabled then st.enabled = true; m:_runScript(self, "OnEnable") end
end
function IMPL.Disable(m, self, st)
    if st.enabled then st.enabled = false; m:_runScript(self, "OnDisable") end
end
function IMPL.SetEnabled(m, self, st, b)
    if b then IMPL.Enable(m, self, st) else IMPL.Disable(m, self, st) end
end
function IMPL.IsEnabled(_, _, st) return st.enabled end
function IMPL.RegisterForClicks(_, _, st, ...)
    local set = {}
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if type(v) ~= "string" then err(3, "%s:RegisterForClicks(): strings expected", st.objType) end
        set[v] = true
    end
    st.clicks = set
end
function IMPL.Click(m, self, st, button, down)
    if not st.enabled then return end
    button = button or "LeftButton"
    if A.widgetIsA[st.type].CheckButton then st.checked = not st.checked end
    m:_runScript(self, "PreClick", button, down or false)
    m:_runScript(self, "OnClick", button, down or false)
    m:_runScript(self, "PostClick", button, down or false)
end
function IMPL.SetChecked(_, _, st, b) st.checked = b and true or false end
function IMPL.GetChecked(_, _, st) return st.checked == true end
function IMPL.SetButtonState(_, _, st, state, lock)
    if state ~= "NORMAL" and state ~= "PUSHED" and state ~= "DISABLED" then
        err(3, "%s:SetButtonState(): invalid state %s", st.objType, tostring(state))
    end
    st.buttonState = state
end
function IMPL.GetButtonState(_, _, st) return st.buttonState or "NORMAL" end

-- sliders / status bars ----------------------------------------------------
function IMPL.SetMinMaxValues(m, self, st, lo, hi)
    numArg(lo, 1, st.objType .. ":SetMinMaxValues", 3)
    numArg(hi, 2, st.objType .. ":SetMinMaxValues", 3)
    if lo > hi then err(3, "%s:SetMinMaxValues(): min > max", st.objType) end
    st.min, st.max = lo, hi
    m:_runScript(self, "OnMinMaxChanged", lo, hi)
    local v = st.value or lo
    local clamped = math.max(lo, math.min(hi, v))
    if clamped ~= st.value then
        st.value = clamped
        m:_runScript(self, "OnValueChanged", clamped, false)
    end
end
function IMPL.GetMinMaxValues(_, _, st) return st.min or 0, st.max or 0 end
function IMPL.SetValue(m, self, st, v, treatAsMouseEvent)
    numArg(v, 1, st.objType .. ":SetValue", 3)
    local lo, hi = st.min or 0, st.max or 0
    v = math.max(lo, math.min(hi, v))
    if v ~= st.value then
        st.value = v
        m:_runScript(self, "OnValueChanged", v, treatAsMouseEvent and true or false)
    end
end
function IMPL.GetValue(_, _, st) return st.value or st.min or 0 end
function IMPL.SetValueStep(_, _, st, step) st.step = numArg(step, 1, st.objType .. ":SetValueStep", 3) end
function IMPL.GetValueStep(_, _, st) return st.step or 0 end
function IMPL.SetOrientation(_, _, st, o)
    if type(o) ~= "string" or not ORIENT[o:upper()] then err(3, "%s:SetOrientation(): invalid orientation %s", st.objType, tostring(o)) end
    st.orientation = o:upper()
end
function IMPL.GetOrientation(_, _, st) return st.orientation or "HORIZONTAL" end
function IMPL.SetStatusBarTexture(m, self, st, asset)
    local w = type(asset) == "table" and widgetOf(m, asset)
    if w then st.barTexture = w; return true end
    local tex = st.barTexture or m:_newWidget("Texture", nil, self, { layer = "ARTWORK" })
    m._W[tex].texture = asset
    st.barTexture = tex
    return true
end
function IMPL.GetStatusBarTexture(_, _, st) return st.barTexture end
function IMPL.SetStatusBarColor(_, _, st, r, g, b, a) st.barColor = { r, g, b, a or 1 } end
function IMPL.GetStatusBarColor(_, _, st)
    local c = st.barColor or { 1, 1, 1, 1 }
    return c[1], c[2], c[3], c[4]
end

-- edit boxes ---------------------------------------------------------------
function IMPL.SetFocus(m, self, st)
    if m._focus == self then return end
    if m._focus then IMPL.ClearFocus(m, m._focus, m._W[m._focus]) end
    m._focus = self
    m:_runScript(self, "OnEditFocusGained")
end
function IMPL.ClearFocus(m, self, st)
    if m._focus ~= self then return end
    m._focus = nil
    m:_runScript(self, "OnEditFocusLost")
end
function IMPL.HasFocus(m, self) return m._focus == self end
function IMPL.HighlightText(_, _, st, s, e) st.highlight = { s or 0, e or -1 } end
function IMPL.ClearHighlightText(_, _, st) st.highlight = nil end
function IMPL.Insert(m, self, st, text)
    IMPL.SetText(m, self, st, (st.text or "") .. textOf(text, 3, "EditBox:Insert"))
end
function IMPL.GetNumber(_, _, st) return tonumber(st.text) end
function IMPL.SetNumber(m, self, st, n)
    numArg(n, 1, "EditBox:SetNumber", 3)
    IMPL.SetText(m, self, st, tostring(n))
end
function IMPL.GetNumLetters(_, _, st) local _, n = (st.text or ""):gsub("[^\128-\191]", ""); return n end
function IMPL.HasText(_, _, st) return (st.text or "") ~= "" end
function IMPL.SetCursorPosition(_, _, st, pos) st.cursor = pos end
function IMPL.GetCursorPosition(_, _, st) return st.cursor or 0 end
function IMPL.IsAutoFocus(_, _, st)
    if st.props.AutoFocus then return st.props.AutoFocus[1] and true or false end
    return true
end

-- scroll frames ------------------------------------------------------------
function IMPL.SetScrollChild(m, self, st, child)
    local c = widgetOf(m, child)
    if not c then err(3, "%s:SetScrollChild(): frame expected", st.objType) end
    IMPL.SetParent(m, c, m._W[c], self)
    st.scrollChild = c
end
function IMPL.GetScrollChild(_, _, st) return st.scrollChild end
function IMPL.SetVerticalScroll(m, self, st, v)
    st.vscroll = numArg(v, 1, "ScrollFrame:SetVerticalScroll", 3)
    m:_runScript(self, "OnVerticalScroll", v)
end
function IMPL.GetVerticalScroll(_, _, st) return st.vscroll or 0 end
function IMPL.SetHorizontalScroll(_, _, st, v) st.hscroll = numArg(v, 1, "ScrollFrame:SetHorizontalScroll", 3) end
function IMPL.GetHorizontalScroll(_, _, st) return st.hscroll or 0 end
function IMPL.GetVerticalScrollRange() return 0 end
function IMPL.GetHorizontalScrollRange() return 0 end

-- tooltip --------------------------------------------------------------------
function IMPL.SetOwner(m, self, st, owner, anchor, x, y)
    local o = widgetOf(m, owner)
    if not o then err(3, "GameTooltip:SetOwner(): owner must be a region") end
    if anchor ~= nil and (type(anchor) ~= "string" or not TOOLTIP_ANCHORS[anchor]) then
        err(3, "GameTooltip:SetOwner(): invalid anchor %s", tostring(anchor))
    end
    st.owner, st.anchor, st.lines = o, anchor or "ANCHOR_LEFT", {}
end
function IMPL.GetOwner(_, _, st) return st.owner end
function IMPL.IsOwned(_, _, st, frame) return st.owner ~= nil and st.owner == frame end
function IMPL.GetAnchorType(_, _, st) return st.anchor end
function IMPL.AddLine(_, _, st, text, r, g, b, wrap)
    st.lines[#st.lines + 1] = { left = textOf(text, 3, "GameTooltip:AddLine"), r = r, g = g, b = b, wrap = wrap }
end
function IMPL.AddDoubleLine(_, _, st, left, right)
    st.lines[#st.lines + 1] = { left = textOf(left, 3, "GameTooltip:AddDoubleLine"),
        right = textOf(right, 3, "GameTooltip:AddDoubleLine") }
end
function IMPL.AppendText(_, _, st, text)
    if st.lines[1] then st.lines[1].left = st.lines[1].left .. textOf(text, 3, "GameTooltip:AppendText") end
end
function IMPL.ClearLines(_, _, st) st.lines = {} end
function IMPL.NumLines(_, _, st) return #st.lines end

-- frames -------------------------------------------------------------------
function IMPL.SetFrameStrata(_, _, st, strata)
    if type(strata) ~= "string" or not STRATA[strata] then
        err(3, "%s:SetFrameStrata(): Unknown frame strata: %s", st.objType, tostring(strata))
    end
    st.strata = strata
end
function IMPL.GetFrameStrata(m, _, st)
    if st.strata then return st.strata end
    local p = st.parent and m._W[st.parent]
    return p and IMPL.GetFrameStrata(m, nil, p) or "MEDIUM"
end
function IMPL.SetFrameLevel(_, _, st, lvl) st.level = numArg(lvl, 1, st.objType .. ":SetFrameLevel", 3) end
function IMPL.GetFrameLevel(m, _, st)
    if st.level then return st.level end
    local p = st.parent and m._W[st.parent]
    return p and (IMPL.GetFrameLevel(m, nil, p) + 1) or 0
end
function IMPL.StartMoving(_, _, st) st.moving = true end
function IMPL.StartSizing(_, _, st) st.sizing = true end
function IMPL.StopMovingOrSizing(_, _, st) st.moving, st.sizing = false, false end
function IMPL.IsDragging(_, _, st) return st.moving == true end
function IMPL.EnableMouse(_, _, st, b) st.mouse = b ~= false end
function IMPL.IsMouseEnabled(_, _, st) return st.mouse == true end
function IMPL.SetMouseClickEnabled(_, _, st, b) st.mouseClick = b ~= false end
function IMPL.IsMouseClickEnabled(_, _, st) return st.mouseClick == true or st.mouse == true end
function IMPL.SetMouseMotionEnabled(_, _, st, b) st.mouseMotion = b ~= false end
function IMPL.IsMouseMotionEnabled(_, _, st) return st.mouseMotion == true or st.mouse == true end
function IMPL.IsMouseOver(_, _, st) return st.mouseOver == true end
function IMPL.SetID(_, _, st, id) st.id = numArg(id, 1, st.objType .. ":SetID", 3) end
function IMPL.GetID(_, _, st) return st.id or 0 end
function IMPL.SetAttribute(m, self, st, k, v)
    st.attributes[k] = v
    m:_runScript(self, "OnAttributeChanged", k, v)
end
function IMPL.SetAttributeNoHandler(_, _, st, k, v) st.attributes[k] = v end
function IMPL.GetAttribute(_, _, st, k) return st.attributes[k] end

-- animation groups -----------------------------------------------------------
function IMPL.CreateAnimation(m, self, st, animType, name, template)
    local t = animType or "Animation"
    local real
    for wtype in pairs(A.widgetIsA) do
        if wtype:lower() == tostring(t):lower() and A.widgetIsA[wtype].Animation then real = wtype end
    end
    if not real then err(3, "AnimationGroup:CreateAnimation(): unknown animation type %s", tostring(animType)) end
    checkTemplateType(m, template, nil, "AnimationGroup:CreateAnimation")
    local anim = m:_newWidget(real, name, nil, {})
    m._W[anim].parent = self
    st.anims = st.anims or {}
    st.anims[#st.anims + 1] = anim
    return anim
end
function IMPL.GetAnimations(_, _, st) return unpack(st.anims or {}) end
function IMPL.Play(m, self, st, reverse)
    if st.type ~= "AnimationGroup" then st.playing = true; return end
    st.playing, st.paused, st.elapsed, st.reverse = true, false, 0, reverse and true or false
    m._anims[self] = true
    m:_runScript(self, "OnPlay")
end
function IMPL.Restart(m, self, st) IMPL.Play(m, self, st) end
function IMPL.Stop(m, self, st)
    if st.type ~= "AnimationGroup" then st.playing = false; return end
    if st.playing then
        st.playing = false
        m:_runScript(self, "OnStop", false)
    end
end
function IMPL.Finish(m, self, st)
    if st.playing then
        st.playing = false
        m:_runScript(self, "OnFinished", false)
    end
end
function IMPL.Pause(m, self, st) st.paused = true; m:_runScript(self, "OnPause") end
function IMPL.IsPlaying(_, _, st) return st.playing == true and not st.paused end
function IMPL.IsPaused(_, _, st) return st.paused == true end
function IMPL.IsDone(_, _, st) return not st.playing end
function IMPL.SetLooping(_, _, st, loop)
    if loop ~= "NONE" and loop ~= "REPEAT" and loop ~= "BOUNCE" then err(3, "SetLooping(): invalid loop type %s", tostring(loop)) end
    st.looping = loop
end
function IMPL.GetLooping(_, _, st) return st.looping or "NONE" end
function IMPL.SetDuration(_, _, st, d) st.duration = numArg(d, 1, st.objType .. ":SetDuration", 3) end
function IMPL.GetDuration(m, _, st)
    if st.type == "AnimationGroup" then
        local byOrder = {}
        for _, a in ipairs(st.anims or {}) do
            local ast = m._W[a]
            local o = ast.order or 1
            local d = (ast.startDelay or 0) + (ast.duration or 0) + (ast.endDelay or 0)
            byOrder[o] = math.max(byOrder[o] or 0, d)
        end
        local total = 0
        for _, d in pairs(byOrder) do total = total + d end
        return total
    end
    return st.duration or 0
end
function IMPL.SetStartDelay(_, _, st, d) st.startDelay = d end
function IMPL.GetStartDelay(_, _, st) return st.startDelay or 0 end
function IMPL.SetEndDelay(_, _, st, d) st.endDelay = d end
function IMPL.GetEndDelay(_, _, st) return st.endDelay or 0 end
function IMPL.SetOrder(_, _, st, o) st.order = o end
function IMPL.GetOrder(_, _, st) return st.order or 1 end
function IMPL.GetRegionParent(m, _, st)
    local g = st.parent and m._W[st.parent]
    return g and g.parent or nil
end
function IMPL.GetProgress(m, self, st)
    local d = IMPL.GetDuration(m, self, st)
    if d <= 0 then return 0 end
    return math.min(1, (st.elapsed or 0) / d)
end
function IMPL.GetElapsed(_, _, st) return st.elapsed or 0 end

---------------------------------------------------------------------------
-- generic implementations for every other client method
---------------------------------------------------------------------------

local DEFAULT_GET = {
    Alpha = 1, Scale = 1, ID = 0, FrameStrata = "MEDIUM", Spacing = 0, MaxLines = 0,
    HitRectInsets = 0, ClampRectInsets = 0, ShadowOffset = 0, DesaturationValue = 0,
}

local function generic(name)
    local verb, key = name:match("^(Set)(.+)$")
    if verb then
        return function(_, _, st, ...) st.props[key] = U.pack(...) end
    end
    key = name:match("^Get(.+)$")
    if key then
        return function(_, _, st)
            local v = st.props[key]
            if v then return unpack(v, 1, v.n) end
            return DEFAULT_GET[key]
        end
    end
    key = name:match("^Is(.+)$")
    if key then
        return function(_, _, st)
            local v = st.props[key]
                or st.props[(key:gsub("Enabled$", ""))]
                or st.props["Enabled:" .. key:gsub("Enabled$", "")]
            if v then return v[1] and true or false end
            return false
        end
    end
    key = name:match("^Enable(.+)$")
    if key then
        return function(_, _, st, flag) st.props["Enabled:" .. key] = U.pack(flag ~= false) end
    end
    key = name:match("^Disable(.+)$")
    if key then
        return function(_, _, st) st.props["Enabled:" .. key] = U.pack(false) end
    end
    if name:match("^Has") or name:match("^Can") or name:match("^Does") or name:match("^Should") then
        return function() return false end
    end
    return function() end
end

---------------------------------------------------------------------------
-- method tables & widget construction
---------------------------------------------------------------------------

function M:_methodTable(wtype)
    local mt = self._methodTables[wtype]
    if mt then return mt end
    local allowed = A.widgetMethods[wtype]
    if not allowed then error("mock: unknown widget type " .. tostring(wtype), 2) end
    local m = self
    local methods = {}
    for name in pairs(allowed) do
        local impl = IMPL[name] or generic(name)
        local restricted = RESTRICTED[name]
        methods[name] = function(obj, ...)
            local st = m._W[obj]
            if not st then
                error(("%s:%s(): Attempt to find 'this' in non-table object (used '.' instead of ':' ?)"):format(wtype, name), 2)
            end
            if restricted and m.player.inCombat == true and protectedState(m, obj, st) then
                m:_violation(("ADDON_ACTION_BLOCKED: %s:%s() on the protected frame %s during combat lockdown")
                    :format(st.objType, name, tostring(st.name or "(anonymous)")), 2)
            end
            return impl(m, obj, st, ...)
        end
    end
    mt = {
        __index = function(_, k)
            local f = methods[k]
            if f == nil and type(k) == "string" and k:match("^%u") then
                local key = wtype .. ":" .. k
                m.widgetMisses[key] = (m.widgetMisses[key] or 0) + 1
            end
            return f
        end,
        __tostring = function(obj)
            local st = m._W[obj]
            return wtype .. ": " .. tostring(st and st.name or "(anonymous)")
        end,
        methods = methods,
    }
    self._methodTables[wtype] = mt
    return mt
end

--- Create a widget object of client widget type `wtype`.
-- extra: { objType = name returned by GetObjectType, layer, subLevel, shown }
function M:_newWidget(wtype, name, parent, extra)
    extra = extra or {}
    local obj = setmetatable({}, self:_methodTable(wtype))
    local isRegion = A.widgetIsA[wtype].Region == true and not A.widgetIsA[wtype].Frame
    if type(name) == "string" and name:find("$parent", 1, true) then
        local pname = parent and self._W[parent] and self._W[parent].name
        if pname then name = name:gsub("%$parent", pname) else name = nil end
    end
    if name ~= nil and type(name) ~= "string" then
        error("mock: widget name must be a string", 3)
    end
    local st = {
        type = wtype, objType = extra.objType or wtype, name = name, parent = nil,
        children = {}, regions = {}, shown = extra.shown ~= false, points = {},
        scripts = {}, hooks = {}, props = {}, attributes = {}, lines = {}, isRegion = isRegion,
        scale = 1, alpha = 1, enabled = true, layer = extra.layer, subLevel = extra.subLevel,
        seq = self._widgetSeq + 1,
    }
    self._widgetSeq = self._widgetSeq + 1
    self._W[obj] = st
    if parent then
        st.parent = parent
        local pst = self._W[parent]
        local list = isRegion and pst.regions or pst.children
        list[#list + 1] = obj
    end
    if name and name ~= "" then
        self._namedFrames[name] = true
        rawset(self.env, name, obj)
    end
    self.widgets[#self.widgets + 1] = obj
    return obj
end

function M:_trackUpdate(obj, st)
    if not st.trackedUpdate then
        st.trackedUpdate = true
        self._updateList[#self._updateList + 1] = obj
    end
end

--- Per-frame work: OnUpdate scripts of visible frames, animation groups.
function M:_updateWidgets(dt)
    local list = {}
    for _, f in ipairs(self._updateList) do list[#list + 1] = f end
    for _, f in ipairs(list) do
        local st = self._W[f]
        if st and (st.scripts.OnUpdate or st.hooks.OnUpdate) and isVisible(self, st) then
            self:_runScript(f, "OnUpdate", dt)
        end
    end
    for ag in pairs(self._anims) do
        local st = self._W[ag]
        if st.playing and not st.paused then
            st.elapsed = (st.elapsed or 0) + dt
            self:_runScript(ag, "OnUpdate", dt)
            local d = IMPL.GetDuration(self, ag, st)
            if st.elapsed >= d then
                if st.looping == "REPEAT" or st.looping == "BOUNCE" then
                    st.elapsed = 0
                    self:_runScript(ag, "OnLoop", "FORWARD")
                else
                    st.playing = false
                    self._anims[ag] = nil
                    self:_runScript(ag, "OnFinished", false)
                end
            end
        else
            self._anims[ag] = nil
        end
    end
end

---------------------------------------------------------------------------
-- templates (a small, source-checked subset is modeled; any other template
-- that exists in the client is accepted and adds nothing)
---------------------------------------------------------------------------

local function mixinInto(object, ...)
    for i = 1, select("#", ...) do
        for k, v in pairs((select(i, ...))) do object[k] = v end
    end
    return object
end

local function backdropMixin(m)
    local mx = {}
    function mx.SetBackdrop(self, info)
        if info ~= nil and type(info) ~= "table" then error("SetBackdrop: table or nil expected", 2) end
        self.backdropInfo = info
        m._W[self].backdrop = info
    end
    function mx.GetBackdrop(self) return self.backdropInfo end
    function mx.ApplyBackdrop() end
    function mx.ClearBackdrop(self) self.backdropInfo = nil end
    function mx.HasBackdropInfo(self, info) return self.backdropInfo == info end
    function mx.SetBackdropColor(self, r, g, b, a) m._W[self].backdropColor = { r, g, b, a or 1 } end
    function mx.GetBackdropColor(self)
        local c = m._W[self].backdropColor or { 1, 1, 1, 1 }
        return c[1], c[2], c[3], c[4]
    end
    function mx.SetBackdropBorderColor(self, r, g, b, a) m._W[self].backdropBorderColor = { r, g, b, a or 1 } end
    function mx.GetBackdropBorderColor(self)
        local c = m._W[self].backdropBorderColor or { 1, 1, 1, 1 }
        return c[1], c[2], c[3], c[4]
    end
    function mx.SetBorderBlendMode() end
    function mx.GetEdgeSize(self) return self.backdropInfo and self.backdropInfo.edgeSize or 0 end
    function mx.OnBackdropLoaded() end
    function mx.OnBackdropSizeChanged() end
    function mx.SetupTextureCoordinates() end
    function mx.SetupPieceVisuals() end
    return mx
end

local function child(m, parent, wtype, key, name, layer, template)
    local obj
    if wtype == "FontString" then
        obj = parent:CreateFontString(name, layer or "ARTWORK", template)
    elseif wtype == "Texture" then
        obj = parent:CreateTexture(name, layer or "ARTWORK")
    else
        obj = m.env.CreateFrame(wtype, name, parent, template)
    end
    parent[key] = obj
    m._W[obj].parentKey = key
    return obj
end

local TEMPLATES = {}
TEMPLATES.BackdropTemplate = function(m, f) mixinInto(f, backdropMixin(m)) end
TEMPLATES.TooltipBackdropTemplate = function(m, f)
    mixinInto(f, backdropMixin(m))
    child(m, f, "Frame", "NineSlice", nil)
end
TEMPLATES.UIPanelButtonNoTooltipTemplate = function(m, f)
    child(m, f, "Texture", "Left", nil, "BACKGROUND")
    child(m, f, "Texture", "Right", nil, "BACKGROUND")
    child(m, f, "Texture", "Middle", nil, "BACKGROUND")
    local text = child(m, f, "FontString", "Text", "$parentText", "ARTWORK", "GameFontNormal")
    f:SetFontString(text)
    f:SetSize(40, 22)
end
TEMPLATES.UIPanelButtonTemplate = function(m, f)
    TEMPLATES.UIPanelButtonNoTooltipTemplate(m, f)
    -- UIPanelButtonMixin:OnEnter / OnLeave (SharedUIPanelTemplates.lua)
    f:SetScript("OnEnter", function(self)
        if self.tooltipText and not self.tooltipDisabled then
            m.env.GameTooltip:SetOwner(self, self.tooltipAnchor or "ANCHOR_RIGHT")
            m.env.GameTooltip:SetText(self.tooltipText)
            m.env.GameTooltip:Show()
        end
    end)
    f:SetScript("OnLeave", function() m.env.GameTooltip:Hide() end)
end
TEMPLATES.UIPanelCloseButtonNoScripts = function(m, f) f:SetSize(24, 24) end
TEMPLATES.UIPanelCloseButton = function(m, f)
    TEMPLATES.UIPanelCloseButtonNoScripts(m, f)
    f:SetScript("OnClick", function(self)                -- UIPanelCloseButton_OnClick: hide parent
        local p = self:GetParent()
        if p then p:Hide() end
    end)
end
TEMPLATES.UIPanelCloseButtonDefaultAnchors = TEMPLATES.UIPanelCloseButton
TEMPLATES.UICheckButtonTemplate = function(m, f)
    child(m, f, "FontString", "Text", "$parentText", "ARTWORK", "GameFontNormalSmall")
    f:SetSize(32, 32)
end
TEMPLATES.InterfaceOptionsCheckButtonTemplate = TEMPLATES.UICheckButtonTemplate
TEMPLATES.UISliderTemplate = function(m, f)
    child(m, f, "Frame", "NineSlice", nil)
    f:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    f.Thumb = f:GetThumbTexture()
    f:SetOrientation("HORIZONTAL")
end
TEMPLATES.UISliderTemplateWithLabels = function(m, f)
    TEMPLATES.UISliderTemplate(m, f)
    child(m, f, "FontString", "Text", "$parentText", "ARTWORK", "GameFontHighlight")
    child(m, f, "FontString", "Low", "$parentLow", "ARTWORK", "GameFontHighlightSmall")
    child(m, f, "FontString", "High", "$parentHigh", "ARTWORK", "GameFontHighlightSmall")
end
TEMPLATES.OptionsSliderTemplate = TEMPLATES.UISliderTemplateWithLabels
TEMPLATES.UIPanelScrollBarTemplate = function(m, f)
    child(m, f, "Button", "ScrollUpButton", "$parentScrollUpButton")
    child(m, f, "Button", "ScrollDownButton", "$parentScrollDownButton")
    f:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    f.ThumbTexture = f:GetThumbTexture()
end
TEMPLATES.UIPanelScrollFrameTemplate = function(m, f)
    local bar = m.env.CreateFrame("Slider", "$parentScrollBar", f, "UIPanelScrollBarTemplate")
    f.ScrollBar = bar
    m._W[bar].parentKey = "ScrollBar"
end
TEMPLATES.ScrollFrameTemplate = function(m, f)
    child(m, f, "Frame", "ScrollBar", nil)
end
TEMPLATES.InputBoxTemplate = function(m, f)
    child(m, f, "Texture", "Left", nil, "BACKGROUND")
    child(m, f, "Texture", "Right", nil, "BACKGROUND")
    child(m, f, "Texture", "Middle", nil, "BACKGROUND")
    f:SetFontObject("ChatFontNormal")
end
TEMPLATES.BasicFrameTemplate = function(m, f)
    child(m, f, "Texture", "Bg", nil, "BACKGROUND")
    child(m, f, "Texture", "TitleBg", nil, "BACKGROUND")
    child(m, f, "FontString", "TitleText", nil, "OVERLAY", "GameFontNormal")
    child(m, f, "Button", "CloseButton", nil, nil, "UIPanelCloseButtonDefaultAnchors")
end
TEMPLATES.BasicFrameTemplateWithInset = function(m, f)
    TEMPLATES.BasicFrameTemplate(m, f)
    child(m, f, "Texture", "InsetBg", nil, "BACKGROUND")
end
TEMPLATES.GameTooltipTemplate = function() end
-- SecureActionButtonTemplate: explicitly protected; its OnClick (SecureActionButton_OnClick) runs
-- the action of the `type` attribute (`typeN` / `itemN` for mouse button N first, like
-- SecureButton_GetModifiedAttribute) on the press OR the release, whichever the
-- ActionButtonUseKeyDown CVar selects (m.actionButtonUseKeyDown, default true as in the
-- client): a button registered only for "LeftButtonUp" (the default) never acts then -- call
-- RegisterForClicks("AnyUp", "AnyDown"). Replacing OnClick with SetScript loses the action, as in
-- the client. Recorded player-intent action: { "SecureAction", type, value, mouseButton }.
local BUTTON_SUFFIX = { LeftButton = "1", RightButton = "2", MiddleButton = "3", Button4 = "4", Button5 = "5" }
local function secureAttribute(st, name, button)
    local suffix = BUTTON_SUFFIX[button]
    local v = suffix and st.attributes[name .. suffix]
    if v == nil then v = st.attributes["*" .. name .. (suffix or "")] end
    if v == nil then v = st.attributes[name] end
    return v
end
TEMPLATES.SecureActionButtonTemplate = function(m, f)
    local st = m._W[f]
    st.protected = true
    m._protected = m._protected or {}
    m._protected[#m._protected + 1] = f
    f:SetScript("OnClick", function(self, button, down)
        local bst = m._W[self]
        local useDown = m.actionButtonUseKeyDown ~= false
        if (down and true or false) ~= useDown then return end
        local t = secureAttribute(bst, "type", button)
        if t == nil then return end
        m:_action("SecureAction", t, secureAttribute(bst, t, button), button)
    end)
end

Mock.MODELED_TEMPLATES = TEMPLATES

local function applyTemplates(m, obj, wtype, templates, method)
    if templates == nil then return end
    if type(templates) ~= "string" then
        m:_violation(method .. ": template must be a string", 4)
    end
    for name in templates:gmatch("[^,%s]+") do
        if not A.templates[name] then
            m:_violation(("%s: unknown template %q (not in the Forever client)"):format(method, name), 4)
        end
        local ttype = A.templateTypes[name]
        if ttype and A.widgetIsA[ttype] and not A.widgetIsA[wtype][ttype] then
            m:_violation(("%s: template %q (%s) cannot be used for a %s"):format(method, name, ttype, wtype), 4)
        end
        local init = TEMPLATES[name]
        if init then init(m, obj) else m.unmodeledTemplates[name] = true end
    end
end

---------------------------------------------------------------------------
-- installer
---------------------------------------------------------------------------

ctx.register(function(m)
    m._W = setmetatable({}, { __mode = "k" })
    m._methodTables = {}
    m._namedFrames = {}
    m._widgetSeq = 0
    m._updateList = {}
    m._anims = {}
    m.widgets = {}
    m.widgetMisses = {}
    m.unmodeledTemplates = {}

    local function createFrame(frameType, name, parent, template, id)
        if type(frameType) ~= "string" then
            m:_violation("CreateFrame: frameType must be a string", 3)
        end
        local wtype = A.frameTypes[frameType:lower()]
        local objType, intrinsic
        if not wtype and INTRINSIC[frameType] and A.templates[frameType] then
            wtype = A.templateTypes[frameType]
            intrinsic = frameType
        end
        if not wtype then
            m:_violation(("CreateFrame: Unknown frame type '%s'"):format(frameType), 3)
        end
        objType = wtype
        local p
        if parent ~= nil then
            p = widgetOf(m, parent)
            if not p then m:_violation("CreateFrame: parent must be a frame", 3) end
        end
        if name ~= nil and type(name) ~= "string" then
            m:_violation("CreateFrame: name must be a string or nil", 3)
        end
        local obj = m:_newWidget(wtype, name, p, { objType = objType })
        if intrinsic == "ScrollingMessageFrame" then m:_installChatMixin(obj) end
        if id ~= nil then obj:SetID(id) end
        applyTemplates(m, obj, wtype, template, "CreateFrame")
        m:_runScript(obj, "OnLoad")
        return obj
    end
    m:ProvideAPI("CreateFrame", createFrame)

    m:ProvideAPI("CreateFont", function(name)
        if type(name) ~= "string" then m:_violation("CreateFont: name expected", 3) end
        local existing = rawget(m.env, name)
        if existing and m._W[existing] then return existing end
        return m:_createFontObject(name)
    end)

    function m._createFontObject(_, name)
        local f = m:_newWidget("Font", name, nil, {})
        m._W[f].font = { "Fonts\\FRIZQT__.TTF", 12, "" }
        return f
    end

    -- global frames (every name is checked against the client's frame list by m:Provide)
    local uiParent = m:Provide("UIParent", m:_newWidget("Frame", "UIParent", nil, {}))
    m._W[uiParent].width, m._W[uiParent].height = 1920, 1080
    local worldFrame = m:Provide("WorldFrame", m:_newWidget("Frame", "WorldFrame", nil, {}))
    m._W[worldFrame].width, m._W[worldFrame].height = 1920, 1080

    local tooltip = m:Provide("GameTooltip", m:_newWidget("GameTooltip", "GameTooltip", uiParent, { shown = false }))
    m._W[tooltip].strata = "TOOLTIP"

    local chat = m:Provide("ChatFrame1", m:_newWidget("Frame", "ChatFrame1", uiParent, { objType = "Frame" }))
    m:_installChatMixin(chat)
    m:Provide("DEFAULT_CHAT_FRAME", chat)
    m:Provide("SELECTED_CHAT_FRAME", chat)

    -- Blizzard panels toggled by interactions (hidden by default)
    for _, fname in ipairs({ "QuestFrame", "GossipFrame", "TaxiFrame", "MerchantFrame", "SettingsPanel" }) do
        m:Provide(fname, m:_newWidget("Frame", fname, uiParent, { shown = false }))
    end
    m:Provide("Minimap", m:_newWidget("Minimap", "Minimap", uiParent, {}))

    m:ProvideAPI("GetCursorPosition", function() return 960, 540 end)
    m:ProvideAPI("GetScreenWidth", function() return 1920 end)
    m:ProvideAPI("GetScreenHeight", function() return 1080 end)
    m:ProvideAPI("GetMouseFoci", function() return m._mouseFocus and { m._mouseFocus } or {} end)
    m:ProvideAPI("GetCurrentKeyBoardFocus", function() return m._focus end)
end)

function M:_installChatMixin(frame)
    local m = self
    -- ScrollingMessageFrameMixin subset (Blizzard_SharedXML/ScrollingMessageFrame.lua)
    frame.AddMessage = function(_, msg, r, g, b)
        m.chat[#m.chat + 1] = tostring(msg)
        m.chatColors[#m.chatColors + 1] = { r, g, b }
    end
    frame.GetNumMessages = function() return #m.chat end
    frame.Clear = function() m.chat, m.chatColors = {}, {} end
    frame.SetMaxLines = function() end
    frame.GetMaxLines = function() return 128 end
end

---------------------------------------------------------------------------
-- spec helpers
---------------------------------------------------------------------------

--- Simulate a mouse click on a button (OnClick etc. via Button:Click).
function M:Click(button, mouseButton)
    return self:_top(function()
        local st = self._W[button]
        if not st then error("mock: Click: not a widget", 0) end
        if not A.widgetIsA[st.type].Button then error("mock: Click: not a button (" .. st.objType .. ")", 0) end
        if not isVisible(self, st) then self:_warn("Click on a hidden button " .. tostring(st.name)) end
        mouseButton = mouseButton or "LeftButton"
        local reg = st.clicks
        if reg == nil then
            button:Click(mouseButton, false) -- default registration: LeftButtonUp (any button accepted here)
            return
        end
        -- RegisterForClicks(...): the press and/or the release, as registered
        if reg.AnyDown or reg[mouseButton .. "Down"] then button:Click(mouseButton, true) end
        if reg.AnyUp or reg[mouseButton .. "Up"] then button:Click(mouseButton, false) end
    end)
end

--- Simulate the mouse entering / leaving a region (OnEnter / OnLeave).
function M:Enter(region)
    return self:_top(function()
        local st = self._W[region]
        st.mouseOver = true
        self._mouseFocus = region
        self:_runScript(region, "OnEnter", true)
    end)
end
function M:Leave(region)
    return self:_top(function()
        local st = self._W[region]
        st.mouseOver = false
        if self._mouseFocus == region then self._mouseFocus = nil end
        self:_runScript(region, "OnLeave", true)
    end)
end

--- Simulate typing into an edit box (OnTextChanged with userInput = true).
function M:TypeText(editBox, text)
    return self:_top(function()
        local st = self._W[editBox]
        st.text = (st.text or "") .. text
        self:_runScript(editBox, "OnTextChanged", true)
    end)
end

--- Simulate a user drag of a slider (OnValueChanged with userInput = true).
function M:DragSlider(slider, value)
    return self:_top(function()
        local st = self._W[slider]
        if st.step and st.step > 0 and st.props.ObeyStepOnDrag and st.props.ObeyStepOnDrag[1] then
            value = (st.min or 0) + floor((value - (st.min or 0)) / st.step + 0.5) * st.step
        end
        slider:SetValue(value, true)
    end)
end

--- Lines of GameTooltip (or another tooltip) as strings ("left" or "left | right").
function M:TooltipLines(tooltip)
    local st = self._W[tooltip or self.env.GameTooltip]
    local out = {}
    for _, l in ipairs(st.lines) do
        out[#out + 1] = l.right and (l.left .. " | " .. l.right) or l.left
    end
    return out
end

--- Internal state of a widget (for assertions): points, text, shown, scripts...
function M:WidgetState(obj)
    return self._W[obj]
end

--- Is the widget actually visible (shown and all parents shown)?
function M:IsWidgetVisible(obj)
    local st = self._W[obj]
    return st ~= nil and isVisible(self, st)
end

--- Find created widgets by predicate(obj, state).
function M:FindWidgets(pred)
    local out = {}
    for _, w in ipairs(self.widgets) do
        if pred(w, self._W[w]) then out[#out + 1] = w end
    end
    return out
end

--- Text of every visible FontString under `root` (default UIParent), in creation order.
function M:VisibleTexts(root)
    root = root or self.env.UIParent
    local out = {}
    for _, w in ipairs(self.widgets) do
        local st = self._W[w]
        if st.type == "FontString" and st.text and st.text ~= "" and isVisible(self, st) then
            local p = st.parent
            local under = false
            while p do
                if p == root then under = true; break end
                p = self._W[p] and self._W[p].parent
            end
            if under then out[#out + 1] = st.text end
        end
    end
    return out
end

--- Show / hide a Blizzard panel frame created by the mock (QuestFrame, GossipFrame...).
function M:_panel(name, shown)
    local f = rawget(self.env, name)
    if f and self._W[f] then
        if shown then f:Show() else f:Hide() end
    end
end
