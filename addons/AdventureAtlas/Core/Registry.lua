-- AdventureAtlas / Core / Registry.lua
--
-- Route storage: AdventureAtlas.RegisterRoute / AddSegment / AddRouteData, the shared
-- library (AddLibrarySegment / AddLibraryData / AddLibraryInsert) and its use by routes
-- (UseSegments / AddInsert) -- public API, see docs/ROUTE_FORMAT.md -- and route selection.
--
--   ns.Registry:Get(id)            -> route | nil (id = a route id or one of its `aliases`)
--   ns.Registry:List([noCompose])  -> array of routes (registration order); noCompose = true:
--                                     without composing them (titles / ids only: a composed
--                                     route of another class costs memory, Registry:Matching)
--   ns.Registry:Matching(facts)    -> the routes of this character (composed)
--   ns.Registry:Select(facts)      -> best matching route | nil
--   ns.Registry:Finalize([route])  -> compose the routes whose UseSegments / AddInsert /
--                                     segments / library changed (Core/Compose.lua)
--   ns.Registry.errors             -> array of "where: message" strings
--   ns.Registry.library            -> library store (Compose.NewLibrary)
--   ns.Registry.aliases            -> [former route id] = route (RegisterRoute{ aliases = ... })
--   ns.Registry:Lookup(route, kind, id) -> localized name from route data | nil
--
-- Composition is lazy: UseSegments / AddInsert only record what to do, and a composed
-- route is (re)built by Finalize the first time it is read after a change (Get / List /
-- Matching / Select, Engine:BuildSteps, Engine:Start at PLAYER_LOGIN). So inserts may be
-- registered before or after UseSegments and anchors may be library steps, as long as
-- everything is registered during load. Each composition error is recorded once.
--
-- Fires ns:Fire("ROUTES_CHANGED", routeId) after every successful
-- registration / segment / data / UseSegments / insert addition (and for every composed
-- route when the library changes).

local _, ns = ...
-- luacheck: ignore 212/self

local type, ipairs, tostring = type, ipairs, tostring

local Registry = {
    routes = {},     -- [id] = route
    order = {},      -- array of routes
    errors = {},
    pending = {},    -- [routeId] = { {kind="segment"|"data"|"uses"|"insert", def=...}, ... } added before RegisterRoute
    library = nil,   -- shared library segments / data / inserts (Compose.NewLibrary), created on first use
    aliases = {},    -- [former route id] = route (RegisterRoute{ aliases = "old-id" | { ... } })
}
ns.Registry = Registry

local MAX_ERRORS = 500

local function addErrors(list, prefix)
    for _, e in ipairs(list or {}) do
        if #Registry.errors >= MAX_ERRORS then return end
        Registry.errors[#Registry.errors + 1] = prefix and (prefix .. ": " .. e) or e
    end
end

local function addError(msg)
    addErrors({ msg })
end

local function changed(routeId)
    ns:Fire("ROUTES_CHANGED", routeId)
end

---------------------------------------------------------------------------
-- registration
---------------------------------------------------------------------------

--- AdventureAtlas.RegisterRoute(def)
-- @return route table or nil (errors are recorded in Registry.errors)
function Registry:RegisterRoute(def)
    local Schema = ns.Schema
    local route, errors = Schema.NormalizeRoute(def)
    local id = type(def) == "table" and def.id or nil
    addErrors(errors)
    if not route or type(id) ~= "string" or id == "" then
        return nil
    end
    if def.api ~= Schema.API_VERSION then
        -- written for another format version: refuse it instead of misreading it
        -- with v1 semantics (Schema already recorded "api must be N")
        return nil
    end
    if self.routes[id] then
        addError(("route %s: registered twice (second definition ignored)"):format(tostring(id)))
        return nil
    end
    if self.aliases[id] then
        -- a route id always wins over an alias (e.g. an old guide module is still installed)
        addError(("route %s: its id is an alias of route %s (alias ignored)"):format(id, tostring(self.aliases[id].id)))
        self.aliases[id] = nil
    end
    route.data = route.data or {}
    route.registeredAt = #self.order + 1
    self.routes[id] = route
    self.order[#self.order + 1] = route
    -- former ids: Registry:Get resolves them, Engine:ActivateRoute moves the saved progress over.
    -- A route id always wins over an alias (Get looks at the ids first).
    for _, alias in ipairs(route.aliases or {}) do
        if self.routes[alias] then
            addError(("route %s: alias '%s' is the id of a registered route (alias ignored)"):format(id, alias))
        elseif self.aliases[alias] then
            addError(("route %s: alias '%s' is already used by route %s (alias ignored)"):format(id, alias,
                tostring(self.aliases[alias].id)))
        else
            self.aliases[alias] = route
        end
    end

    local pending = self.pending[id]
    self.pending[id] = nil
    if pending then
        for _, p in ipairs(pending) do
            if p.kind == "segment" then
                self:AddSegment(id, p.def)
            elseif p.kind == "uses" then
                self:UseSegments(id, p.def)
            elseif p.kind == "insert" then
                self:AddInsert(id, p.def)
            else
                -- AddRouteData checked the shape before it queued the data: merge directly,
                -- so a bad entry is reported once (as the tools' loader does)
                ns.Compose.MergeData(route.data, p.def)
            end
        end
    end
    changed(id)
    return route
end

-- queue a registration for a route that is not registered yet (an error is recorded)
local function queue(self, routeId, kind, def, what)
    if type(routeId) ~= "string" then
        addError(("%s: invalid route id %s"):format(what, tostring(routeId)))
        return
    end
    addError(("%s: route %s is not registered yet (RegisterRoute must come first)"):format(what, routeId))
    local q = self.pending[routeId] or {}
    q[#q + 1] = { kind = kind, def = def }
    self.pending[routeId] = q
end

--- AdventureAtlas.AddSegment(routeId, def)
-- Segments may arrive before their route (queued, with an error recorded).
-- @return segment or nil
function Registry:AddSegment(routeId, def)
    local route = self.routes[routeId]
    if not route then
        if type(routeId) ~= "string" then
            addError(("AddSegment: invalid route id %s"):format(tostring(routeId)))
            return nil
        end
        addError(("AddSegment %s: route %s is not registered yet (RegisterRoute must come first)")
            :format(tostring(type(def) == "table" and def.id), routeId))
        local q = self.pending[routeId] or {}
        q[#q + 1] = { kind = "segment", def = def }
        self.pending[routeId] = q
        return nil
    end
    -- a composed route keeps its own segments in route.own (Compose.OwnTarget)
    local seg, errors = ns.Schema.AddSegment(ns.Compose.OwnTarget(route), def)
    addErrors(errors, "route " .. tostring(routeId))
    if seg then
        if route.own then route.dirty = true end
        route.revision = (route.revision or 0) + 1
        changed(routeId)
    end
    return seg
end

---------------------------------------------------------------------------
-- shared library segments and class inserts (Core/Compose.lua)
---------------------------------------------------------------------------

local function library(self)
    local lib = self.library
    if not lib then
        lib = ns.Compose.NewLibrary()
        self.library = lib
    end
    return lib
end

-- the library changed: every route that uses it is rebuilt on its next read
local function libraryChanged(self)
    for _, r in ipairs(self.order) do
        if r.own and #r.uses > 0 then
            r.dirty = true
            r.revision = (r.revision or 0) + 1
            changed(r.id)
        end
    end
end

--- AdventureAtlas.AddLibrarySegment(def): a shared segment (same definition as AddSegment),
-- used by routes through UseSegments. Library segment ids and step ids are unique across
-- the whole library. A step whose class / race / faction filter cannot match a route is
-- not composed into that route (Core/Compose.lua).
-- @return segment or nil
function Registry:AddLibrarySegment(def)
    local seg, errors = ns.Compose.AddLibrarySegment(library(self), def)
    addErrors(errors, "library")
    if seg then libraryChanged(self) end
    return seg
end

--- AdventureAtlas.AddLibraryData(data): names of the library's quests / NPCs / places
-- (generated Data.lua of a library module). Merged under the data of every route that
-- uses library segments (the route's own values win).
-- @return true on success
function Registry:AddLibraryData(data)
    local ok, err = ns.Compose.AddLibraryData(library(self), data)
    if not ok then
        addError("AddLibraryData: " .. tostring(err))
        return false
    end
    local errs = {}
    ns.Schema.CheckData(data, "AddLibraryData", errs) -- (merged as given; the engine skips a bad entry)
    addErrors(errs)
    libraryChanged(self)
    return true
end

--- AdventureAtlas.AddLibraryInsert({ after = "<stepId>" | before = "<stepId>", class = , race = ,
-- faction = , steps = {...} }): shared steps (class training, class and race quests, riding)
-- next to a step of a shared segment or of another shared insert. Applied to every route
-- with a UseSegments list that contains the anchor; class / race / faction are the default
-- filters of the steps, and a step that cannot match a route is not composed into it. Every
-- step needs an explicit id, unique in the library (Core/Compose.lua: AddLibraryInsert).
-- @return insert record or nil
function Registry:AddLibraryInsert(def)
    local ins, errors = ns.Compose.AddLibraryInsert(library(self), def)
    addErrors(errors, "library")
    if ins then libraryChanged(self) end
    return ins
end

--- AdventureAtlas.UseSegments(routeId, { "h-...", ... }): append library segments to the
-- route (after its own segments, in order). Must come after RegisterRoute (otherwise an
-- error is recorded and the call is queued). Unknown ids are reported when the route
-- is composed.
-- @return true when at least one id was recorded
function Registry:UseSegments(routeId, ids)
    local route = self.routes[routeId]
    if not route then
        queue(self, routeId, "uses", ids, "UseSegments")
        return false
    end
    local n, errors = ns.Compose.AddUses(route, ids)
    addErrors(errors, "route " .. tostring(routeId))
    if n == 0 then return false end
    route.revision = (route.revision or 0) + 1
    changed(routeId)
    return true
end

--- AdventureAtlas.AddInsert(routeId, { after = "<stepId>" | before = "<stepId>", steps = {...} }):
-- route-specific steps (class training, class quests) next to a step of the route (own
-- or library). An unknown anchor is reported when the route is composed.
-- @return insert record or nil
function Registry:AddInsert(routeId, def)
    local route = self.routes[routeId]
    if not route then
        queue(self, routeId, "insert", def, "AddInsert")
        return nil
    end
    local ins, errors = ns.Compose.AddInsert(route, def)
    addErrors(errors, "route " .. tostring(routeId))
    if not ins then return nil end
    route.revision = (route.revision or 0) + 1
    changed(routeId)
    return ins
end

--- Compose a dirty route (or every dirty route when `route` is nil). Composition
-- errors are recorded once per route.
function Registry:Finalize(route)
    if route ~= nil then
        if route.own and route.dirty then
            local errors = ns.Compose.Build(route, self.library)
            local seen = route.composeErrors or {}
            route.composeErrors = seen
            for _, e in ipairs(errors) do
                local msg = ("route %s: %s"):format(tostring(route.id), e.msg)
                if not seen[msg] then
                    seen[msg] = true
                    addError(msg)
                end
            end
        end
        return route
    end
    for _, r in ipairs(self.order) do
        if r.own and r.dirty then self:Finalize(r) end
    end
end

--- AdventureAtlas.AddRouteData(routeId, data)
-- data = { quests = { [id] = name | {ru=, en=} | { name = ... } }, npcs = {...}, items = {...},
--          places = { ["Brill"] = { area = 159, en = "Brill", ru = "Брилл" } }, ... }
-- Data.lua of a route module is generated by tools/gen_route_data.lua (enUS names of quests /
-- NPCs / objects / items, and `places` for the fp / fly / sethearth / hearth names: AreaTable
-- id + ruRU name); a module may add hand-written data in another file (any locale).
-- Tables are merged key by key into route.data.
function Registry:AddRouteData(routeId, data)
    if type(data) ~= "table" then
        addError(("AddRouteData %s: data must be a table"):format(tostring(routeId)))
        return false
    end
    local errs = {}
    ns.Schema.CheckData(data, "AddRouteData " .. tostring(routeId), errs)
    addErrors(errs)
    local route = self.routes[routeId]
    if not route then
        queue(self, routeId, "data", data, "AddRouteData")
        return false
    end
    ns.Compose.MergeData(route.data, data)
    changed(routeId)
    return true
end

---------------------------------------------------------------------------
-- queries
---------------------------------------------------------------------------

--- Route by id, or by one of its former ids (`aliases`) when no route has that id.
function Registry:Get(id)
    if id == nil then return nil end
    local route = self.routes[id] or self.aliases[id]
    if route and route.dirty then self:Finalize(route) end
    return route
end

--- Every route in registration order.
-- @param noCompose true: do not compose them (ids, titles, levels...; route.steps of a route
--        that was never read is then empty). Composing every route costs about 1.2 MB each:
--        the UI lists with noCompose and shows Registry:Matching.
function Registry:List(noCompose)
    if not noCompose then self:Finalize() end
    local out = {}
    for i, r in ipairs(self.order) do out[i] = r end
    return out
end

--- Is the route composed and up to date (its steps can be counted without composing it)?
-- A plain route (no UseSegments / AddInsert) always is.
function Registry:IsComposed(route)
    return route ~= nil and not (route.own and route.dirty)
end

--- Routes applicable to the player (faction / race / class), in registration order.
-- Only these are composed (Core/Compose.lua) -- a composed route of another class or race
-- is built when it is chosen (Registry:Get) or when everything is listed (Registry:List()).
function Registry:Matching(facts)
    local out = {}
    for _, r in ipairs(self.order) do
        if ns.Schema.RouteMatches(r, facts or {}) then
            if r.dirty then self:Finalize(r) end
            if #r.steps > 0 then out[#out + 1] = r end
        end
    end
    return out
end

local function levelScore(route, level)
    local lv = route.levels
    if not lv or not level then return 1 end
    if level >= lv[1] and level < lv[2] then return 2 end -- inside the range (not yet at the end)
    if level < lv[1] then return 1 end
    return 0                                               -- already past the route
end

--- Best route for the player: matching faction/race/class with steps; prefer
-- `default = true`, then a level range that contains the player's level, then
-- registration order.
-- @param facts { race, class, faction, level } (ns.Compat.PlayerFacts())
function Registry:Select(facts)
    local best, bestScore
    for _, r in ipairs(self:Matching(facts)) do
        local score = (r.default and 10 or 0) + levelScore(r, facts and facts.level)
        if not best or score > bestScore then
            best, bestScore = r, score
        end
    end
    return best
end

--- Localized name of a quest / npc / item / place from the route's data tables.
-- Entries may be a string, a {ru=, en=} text, or a table with a `name` / `title` field.
function Registry:Lookup(route, kind, id)
    local data = route and route.data
    local t = data and data[kind]
    local v = type(t) == "table" and t[id] or nil
    if v == nil then return nil end
    if type(v) == "table" and (v.name ~= nil or v.title ~= nil) then
        v = v.name or v.title
    end
    local s = ns.Schema.Text(v, ns.locale)
    if type(s) == "string" and s ~= "" then return s end
    return nil
end

--- AreaTable id of a place name (route data `places[name].area`), nil when unknown.
function Registry:PlaceArea(route, place)
    local data = route and route.data
    local t = data and data.places
    local v = type(t) == "table" and t[place] or nil
    local area = type(v) == "table" and v.area or nil
    return type(area) == "number" and area or nil
end

--- Test helper: forget every route and error.
function Registry:Wipe()
    self.routes, self.order, self.errors, self.pending, self.library = {}, {}, {}, {}, nil
    self.aliases = {}
    Registry.errors = self.errors
end
