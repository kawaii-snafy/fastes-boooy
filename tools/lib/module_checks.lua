-- tools/lib/module_checks.lua -- validator checks on the shared TEMPLATES of a module (Lua 5.1).
--
-- A module that registers routes and shared content (FastesBoooy_Guides: shared segments,
-- AddLibraryInsert) composes every route from templates, and a route only contains the template
-- steps its race / class / faction can match (Core/Compose.lua). A mistake in a template can
-- therefore be invisible in every composed route: a step with `race = "Undead"` matches no route and
-- is composed nowhere, an insert with a misspelled anchor is applied to no route. These checks walk
-- the templates the module's OWN files registered (mod.librarySegments, mod.libraryInserts), after
-- all routes of the module are composed; they need no simulation.
--
--   local ModuleChecks = require("lib.module_checks")
--   local messages, notes = ModuleChecks.Run(db, schema, mod, { isOwn = function(file) ... end })
--
-- Codes (tools/README.md):
--   unknown-race-token             ERROR  a race token of a template step or of an insert scope is no raceFile
--   insert-anchor-unknown          ERROR  the anchor of a shared insert is the id of no loaded step
--   insert-unapplied               ERROR  the anchor exists and a loaded route can match the insert's scope,
--                                         but none of those routes contains the anchor
--   shared-step-unused             ERROR  a template step is composed into no loaded route
--   insert-scope-wider-than-anchor ERROR  the anchor step is filtered and a step of the insert is not
--                                         limited to a subset of that filter
--   ok-needs-ceiling               ERROR  `ok` of a step or of a segment lists level-grind without a ceiling
--   shared-unused                  WARN   a shared segment is used by no route (only on a full load)
--
-- Partial loads (mod.filtered: --skip / --keep): the anchor or the route may live in a skipped
-- file. The five checks that depend on other files (unknown-race-token .. insert-scope-wider-than-
-- anchor) still count for the caller's own files (opts.isOwn; every loaded file without --own); for
-- a loaded file that is not own they are returned as NOTES, which never change the exit status.
-- ok-needs-ceiling reads one step / segment only: it is an ERROR in any file, on any load.
-- shared-unused is not checked on a partial load.

local ModuleChecks = {}

local format = string.format

local function sortedKeys(t)
    local out = {}
    for k in pairs(t or {}) do out[#out + 1] = k end
    table.sort(out, function(a, b) return tostring(a) < tostring(b) end)
    return out
end

local function setText(set)
    return table.concat(sortedKeys(set), ", ")
end

-- "class=WARRIOR race=Orc,Troll" (the scope of an insert / the filters of a step)
local function filterText(f)
    if not f then return "none" end
    local parts = {}
    if f.class then parts[#parts + 1] = "class=" .. setText(f.class):gsub(", ", ",") end
    if f.race then parts[#parts + 1] = "race=" .. setText(f.race):gsub(", ", ",") end
    if f.faction then parts[#parts + 1] = "faction=" .. tostring(f.faction) end
    return #parts > 0 and table.concat(parts, " ") or "none"
end
ModuleChecks.FilterText = filterText

-- checks that read nothing but the step / segment itself: no skipped file can change the verdict, so
-- they are never demoted to a note
local LOCAL_CHECK = { ["ok-needs-ceiling"] = true }

local function usesSegments(route)
    return route.uses ~= nil and #route.uses > 0
end

-- is the template step composed into the route? (Compose.Build keeps the route's copy of a template
-- in route.libCopies; the copy is in the route when its id resolves to it)
local function composedInto(route, template)
    local copy = route.libCopies and route.libCopies[template]
    return copy ~= nil and route.stepById ~= nil and route.stepById[template.id] == copy
end

--- Run the template checks of a module.
-- @param mod Loader.LoadModule result (routes composed)
-- @param opts { isOwn = function(file) -> bool | nil (nil: every file is own),
--               acknowledge = function(okTable, message) (applies a step's / segment's `ok`) }
-- @return messages (array of { severity, code, msg, file, stepId, segment, step, library, shared }),
--         notes (the same shape: ERROR checks of loaded files that are not own, on a partial load)
function ModuleChecks.Run(db, schema, mod, opts)
    opts = opts or {}
    local messages, notes = {}, {}
    local known = db.enums and db.enums.raceFileToBit or {}
    local raceNames = sortedKeys(known)
    local canMatch = schema.FiltersCanMatchRoute
    local isOwn = opts.isOwn

    local function add(sev, code, where, msg, ...)
        local m = { severity = sev, code = code, msg = format(msg, ...), library = mod.name, shared = true }
        local okT
        if where.step then
            local step = where.step
            m.stepId, m.file = step.id, step.file
            if where.segment then m.segment, m.step = where.segment.id, step.segIndex end
            okT = step.ok
        elseif where.segment then
            m.segment, m.file = where.segment.id, where.segment.file
            okT = where.segment.ok
        else
            m.file = where.file
        end
        if sev == "ERROR" and not LOCAL_CHECK[code] and mod.filtered and isOwn and not isOwn(m.file) then
            notes[#notes + 1] = m
            return m
        end
        if sev == "WARN" and okT and opts.acknowledge then opts.acknowledge(okT, m) end
        messages[#messages + 1] = m
        return m
    end

    local function raceHint(tok)
        if tok == "Undead" then return " (the raceFile of the Undead is \"Scourge\")" end
        return format(" (known: %s)", table.concat(raceNames, ", "))
    end

    -- every loaded step by id: shared segment steps and shared-insert steps (one namespace), and the
    -- steps of the routes themselves (an own step may be an anchor in its route)
    local shared = mod.lib and mod.lib.scratch and mod.lib.scratch.stepById or {}
    local function anchorKnown(id)
        if shared[id] then return true end
        for _, route in ipairs(mod.routes) do
            if route.stepById and route.stepById[id] then return true end
        end
        return false
    end

    local CEILING = "ok lists level-grind without a ceiling: write ok = { [\"level-grind\"] = N } (accepted only "
        .. "while the gate needs at most N kills)"
    local function plainCeiling(step, where)
        if step.ok and step.ok["level-grind"] == true then
            add("ERROR", "ok-needs-ceiling", where, "step '%s': %s", tostring(step.id), CEILING)
        end
    end

    ---------------------------------------------------------------------
    -- shared segments
    ---------------------------------------------------------------------
    for _, seg in ipairs(mod.librarySegments) do
        local used = false
        for _, route in ipairs(mod.routes) do
            for _, u in ipairs(route.uses or {}) do
                if u.id == seg.id then used = true break end
            end
            if used then break end
        end
        if not used and not mod.filtered then
            add("WARN", "shared-unused", { segment = seg }, "shared segment '%s' (%d step(s)) is used by no route "
                .. "(no UseSegments list names it)", tostring(seg.id), #seg.steps)
        end
        -- a segment's `ok` only ever accepts segment-level; a plain level-grind there is the same mistake
        if seg.ok and seg.ok["level-grind"] == true then
            add("ERROR", "ok-needs-ceiling", { segment = seg }, "segment '%s': %s; a level gate is acknowledged on "
                .. "its step", tostring(seg.id), CEILING)
        end
        for _, step in ipairs(seg.steps) do
            local where = { step = step, segment = seg }
            local bad = false
            for _, tok in ipairs(sortedKeys(step.filters and step.filters.race)) do
                if known[tok] == nil then
                    bad = true
                    add("ERROR", "unknown-race-token", where, "step '%s': race filter: unknown raceFile '%s'%s",
                        tostring(step.id), tostring(tok), raceHint(tok))
                end
            end
            plainCeiling(step, where)
            if used and not bad then
                local any = false
                for _, route in ipairs(mod.routes) do
                    if composedInto(route, step) then any = true break end
                end
                if not any then
                    add("ERROR", "shared-step-unused", where, "step '%s' (%s) is composed into no loaded route: its "
                        .. "filter matches none of the %d route(s)", tostring(step.id), filterText(step.filters), #mod.routes)
                end
            end
        end
    end

    ---------------------------------------------------------------------
    -- shared inserts
    ---------------------------------------------------------------------
    for _, ins in ipairs(mod.libraryInserts) do
        local first = ins.steps[1]
        local label = format("shared insert %s '%s'", tostring(ins.side), tostring(ins.anchor))
        local whereIns = first and { step = first } or { file = ins.file }
        local bad = false
        -- race tokens: the scope once, then the steps that set a race filter of their own
        local scopeRace = ins.scope and ins.scope.race
        for _, tok in ipairs(sortedKeys(scopeRace)) do
            if known[tok] == nil then
                bad = true
                add("ERROR", "unknown-race-token", whereIns, "%s: race scope: unknown raceFile '%s'%s", label,
                    tostring(tok), raceHint(tok))
            end
        end
        for _, step in ipairs(ins.steps) do
            local race = step.filters and step.filters.race
            if race and race ~= scopeRace then
                for _, tok in ipairs(sortedKeys(race)) do
                    if known[tok] == nil then
                        bad = true
                        add("ERROR", "unknown-race-token", { step = step }, "step '%s' of %s: race filter: unknown "
                            .. "raceFile '%s'%s", tostring(step.id), label, tostring(tok), raceHint(tok))
                    end
                end
            end
            plainCeiling(step, { step = step })
        end
        -- the anchor
        local anchorOk = true
        if not anchorKnown(ins.anchor) then
            anchorOk = false
            add("ERROR", "insert-anchor-unknown", whereIns, "%s (%d step(s), first '%s'): the anchor is the id of no "
                .. "loaded step%s", label, #ins.steps, tostring(first and first.id),
                mod.filtered and " (files are skipped: the anchor may live in one of them)" or "")
        else
            local scoped, withAnchor = 0, 0
            for _, route in ipairs(mod.routes) do
                if usesSegments(route) and canMatch(ins.scope, route) then
                    scoped = scoped + 1
                    if route.stepById and route.stepById[ins.anchor] then withAnchor = withAnchor + 1 end
                end
            end
            if scoped > 0 and withAnchor == 0 then
                anchorOk = false
                add("ERROR", "insert-unapplied", whereIns, "%s (%d step(s), first '%s'): the anchor exists, and %d "
                    .. "loaded route(s) can match the insert's scope (%s), but none of them contains the anchor "
                    .. "(an anchor of another start zone or of another race / class?)", label, #ins.steps,
                    tostring(first and first.id), scoped, filterText(ins.scope))
            end
        end
        -- a filtered anchor: the insert may not be wider (the author states the intent)
        local anchor = shared[ins.anchor]
        local af = anchor and anchor.filters
        if af and (af.class or af.race or af.faction) then
            local wide, dims = {}, {}
            for _, step in ipairs(ins.steps) do
                local f = step.filters or {}
                local wider = false
                for _, dim in ipairs({ "class", "race" }) do
                    if af[dim] then
                        local sub = f[dim] ~= nil
                        for tok in pairs(f[dim] or {}) do
                            if not af[dim][tok] then sub = false end
                        end
                        if not sub then
                            wider = true
                            dims[dim] = true
                        end
                    end
                end
                if af.faction and f.faction ~= af.faction then
                    wider = true
                    dims.faction = true
                end
                if wider then wide[#wide + 1] = tostring(step.id) end
            end
            if #wide > 0 then
                add("ERROR", "insert-scope-wider-than-anchor", whereIns, "%s: the anchor step is filtered (%s), but "
                    .. "%d step(s) of the insert (%s) are not limited to it in %s: give the insert (or the step) a "
                    .. "scope inside the anchor's filter", label, filterText(af), #wide, table.concat(wide, ", "),
                    table.concat(sortedKeys(dims), " / "))
            end
        end
        -- steps composed into no route (not repeated for an insert reported above)
        if anchorOk and not bad then
            local unused = {}
            for _, step in ipairs(ins.steps) do
                local any = false
                for _, route in ipairs(mod.routes) do
                    if composedInto(route, step) then any = true break end
                end
                if not any then unused[#unused + 1] = step end
            end
            if #unused > 0 and #unused == #ins.steps then
                add("ERROR", "shared-step-unused", whereIns, "%s: none of its %d step(s) (first '%s', scope %s) is "
                    .. "composed into a loaded route: the scope / the step filters match no route that contains the "
                    .. "anchor", label, #ins.steps, tostring(first.id), filterText(ins.scope))
            else
                for _, step in ipairs(unused) do
                    add("ERROR", "shared-step-unused", { step = step }, "step '%s' of %s (%s) is composed into no "
                        .. "loaded route: its filter matches no route that contains the anchor", tostring(step.id),
                        label, filterText(step.filters))
                end
            end
        end
    end
    return messages, notes
end

return ModuleChecks
