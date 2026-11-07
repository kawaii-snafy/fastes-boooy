-- Route format contract (addons/FastesBoooy/Core/Schema.lua): normalization and errors.
-- Schema.lua is pure Lua; it is loaded here the way the offline tools load it.

local Loader = require("lib.route_loader")
local H = require("fixtures.core.helpers")

local Schema = Loader.LoadSchema(".")

local function step(def)
    local errors = {}
    local s = Schema.NormalizeStep(def, "t", errors)
    return s, errors
end

local function types(s)
    local out = {}
    for i, a in ipairs(s.actions) do out[i] = a.type end
    return out
end

local function hasError(errors, pattern)
    for _, e in ipairs(errors) do
        if e:find(pattern) then return true end
    end
    return false
end

describe("Schema.NormalizeStep", function()
    it("normalizes quest actions: id, list and objective map", function()
        local s, errors = step({ accept = 363 })
        assert.same({}, errors)
        assert.same({ { type = "accept", quest = 363 } }, s.actions)

        s, errors = step({ turnin = { 363, 364 } })
        assert.same({}, errors)
        assert.same({ { type = "turnin", quest = 363 }, { type = "turnin", quest = 364 } }, s.actions)

        s, errors = step({ complete = { [364] = { 1, 2 } } })
        assert.same({}, errors)
        assert.same({ { type = "complete", quest = 364, objectives = { 1, 2 } } }, s.actions)

        s, errors = step({ complete = { 380, [364] = { 2 } } })
        assert.same({}, errors)
        assert.same({ { type = "complete", quest = 380 }, { type = "complete", quest = 364, objectives = { 2 } } },
            s.actions)
    end)

    it("orders the actions of a multi-action step by Schema.ACTION_ORDER", function()
        local s, errors = step({ accept = 364, turnin = 363, abandon = 9, go = true, at = { 1420, 1, 2 } })
        assert.same({}, errors)
        assert.same({ "abandon", "turnin", "accept", "go" }, types(s))
        assert.is_true(s.stateful)
        assert.is_false(s.transient)
    end)

    it("normalizes collect / level / place / flag actions", function()
        local s, errors = step({ collect = { [3265] = 6, [3264] = 2 } })
        assert.same({}, errors)
        assert.same({ { type = "collect", item = 3264, count = 2 }, { type = "collect", item = 3265, count = 6 } },
            s.actions)

        s = step({ level = 4 })
        assert.same({ { type = "level", level = 4, frac = 0 } }, s.actions)
        s = step({ level = { 4, 0.3 } })
        assert.same({ { type = "level", level = 4, frac = 0.3 } }, s.actions)

        for _, kind in ipairs({ "fp", "fly", "sethearth", "hearth" }) do
            local def = { [kind] = "Brill" }
            if kind == "fly" or kind == "hearth" then def.at = { 1420, 61.7, 52 } end
            local st, errs = step(def)
            assert.same({}, errs, kind)
            assert.same({ { type = kind, place = "Brill" } }, st.actions, kind)
            assert.is_true(st.transient, kind)
        end
        for _, kind in ipairs({ "train", "vendor", "manual" }) do
            local st, errs = step({ [kind] = true })
            assert.same({}, errs, kind)
            assert.same({ { type = kind } }, st.actions, kind)
        end
    end)

    it("derives arrival radii (go 12, fly 60, hearth 80, explicit radius wins)", function()
        assert.equal(12, (step({ go = true, at = { 1420, 1, 1 } })).radius)
        assert.equal(60, (step({ fly = "X", at = { 1420, 1, 1 } })).radius)
        assert.equal(80, (step({ hearth = "X", at = { 1420, 1, 1 } })).radius)
        assert.equal(80, (step({ go = true, hearth = "X", at = { 1420, 1, 1 } })).radius)
        assert.equal(5, (step({ go = true, radius = 5, at = { 1420, 1, 1 } })).radius)
        assert.equal(12, (step({ accept = 1 })).radius)
    end)

    it("normalizes fields: at, npc, object, filters, reward, gossip, use, bg, optional, spells, note", function()
        local s, errors = step({
            id = "a.b:c-1", accept = 1, at = { 1420, 30.2, 71.7 }, npc = 1568, object = { 5, 6 },
            class = "PALADIN", race = { "Scourge", "Orc" }, faction = "Horde", reward = { [1] = 2 },
            gossip = 2, use = 3264, bg = true, optional = false, spells = "Seal",
            note = { ru = "Заметка", en = "Note" },
        })
        assert.same({}, errors)
        assert.equal("a.b:c-1", s.id)
        assert.same({ map = 1420, x = 30.2, y = 71.7 }, s.at)
        assert.same({ 1568 }, s.npc)
        assert.same({ 5, 6 }, s.object)
        assert.same({ PALADIN = true }, s.filters.class)
        assert.same({ Scourge = true, Orc = true }, s.filters.race)
        assert.equal("Horde", s.filters.faction)
        assert.same({ [1] = 2 }, s.reward)
        assert.equal(2, s.gossip)
        assert.equal(3264, s.use)
        assert.is_true(s.bg)
        assert.is_false(s.optional)
        assert.same({ "Seal" }, s.spells)
        assert.same({ ru = "Заметка", en = "Note" }, s.note)
        -- {map=, x=, y=} form
        s = step({ go = true, at = { map = 1420, x = 1, y = 2 } })
        assert.same({ map = 1420, x = 1, y = 2 }, s.at)
        assert.is_nil(s.filters)
    end)

    it("reports errors without raising", function()
        local cases = {
            { {}, "step has no action" },
            { { accept = 0 }, "accept must be a quest id" },
            { { accept = { 1, "x" } }, "accept%[2%] is not a valid quest id" },
            { { turnin = { [5] = { 1 } } }, "turnin has unexpected key" },
            { { complete = { [5] = {} } }, "non%-empty list of objective indexes" },
            { { collect = 5 }, "collect must be" },
            { { collect = { [1] = 0 } }, "collect entry" },
            { { level = 0 }, "level must be" },
            { { level = { 4, 1.5 } }, "level fraction" },
            { { fp = "" }, "fp must be a non%-empty place name" },
            { { go = 1, at = { 1420, 1, 1 } }, "go must be true" },
            { { go = true }, "go/fly/hearth steps require 'at'" },
            { { accept = 1, at = { 1420, 101, 1 } }, "x/y must be numbers in 0..100" },
            { { accept = 1, at = { 0, 1, 1 } }, "uiMapID must be a positive integer" },
            { { accept = 1, at = "x" }, "at must be" },
            { { accept = 1, radius = -1 }, "radius must be a positive number" },
            { { accept = 1, npc = "x" }, "npc%[1%] is not a valid id" },
            { { accept = 1, note = 5 }, "note must be" },
            { { accept = 1, reward = { [1] = 0 } }, "reward entry" },
            { { accept = 1, gossip = 0 }, "gossip must be" },
            { { accept = 1, use = "x" }, "use must be an item id" },
            { { accept = 1, bg = 1 }, "bg must be boolean" },
            { { accept = 1, optional = "yes" }, "optional must be boolean" },
            { { accept = 1, class = "DEATHKNIGHT" }, "unknown class token" },
            { { accept = 1, race = { 5 } }, "race tokens must be strings" },
            { { accept = 1, faction = "Neutral" }, "faction must be Horde or Alliance" },
            { { accept = 1, id = "bad id!" }, "id must be a string" },
            { { accept = 1, spells = { 5 } }, "spells%[1%] must be text" },
            { { accept = 1, foo = true }, "unknown step key 'foo'" },
        }
        for _, c in ipairs(cases) do
            local ok, s, errors = pcall(function() return step(c[1]) end)
            assert.is_true(ok, c[2])
            assert.is_table(s)
            assert.is_true(hasError(errors, c[2]), ("expected error %q, got: %s"):format(c[2], table.concat(errors, " | ")))
            assert.is_truthy(errors[1]:find("^t: "), "errors are prefixed with the location")
        end
        local s, errors = step("nope")
        assert.same({}, s.actions)
        assert.is_true(hasError(errors, "step must be a table"))
    end)
end)

describe("Schema routes and segments", function()
    local function route(over)
        local def = { api = 1, id = "r1", title = "R", faction = "Horde", races = { "Scourge" },
            classes = { "PALADIN" }, levels = { 1, 10 } }
        for k, v in pairs(over or {}) do def[k] = v end
        return Schema.NormalizeRoute(def)
    end

    it("normalizes a route definition", function()
        local r, errors = route({ default = true, description = { en = "d" } })
        assert.same({}, errors)
        assert.equal("r1", r.id)
        assert.same({ Scourge = true }, r.races)
        assert.same({ PALADIN = true }, r.classes)
        assert.same({ 1, 10 }, r.levels)
        assert.is_true(r.default)
        assert.same({}, r.steps)
        assert.same({}, r.segments)
    end)

    it("reports route errors", function()
        local function errs(over)
            local _, e = route(over)
            return table.concat(e, " | ")
        end
        assert.matches("api must be 1", errs({ api = 2 }))
        assert.matches("id must be a string", errs({ id = "a b" }))
        assert.matches("title is required", errs({ title = "" }))
        assert.matches("faction must be Horde or Alliance", errs({ faction = "x" }))
        assert.matches("unknown class token", errs({ classes = { "MONK" } }))
        assert.matches("levels must be", errs({ levels = { 5, 1 } }))
        assert.matches("unknown key 'foo'", errs({ foo = 1 }))
        local r, e = Schema.NormalizeRoute(nil)
        assert.is_nil(r)
        assert.matches("must be a table", e[1])
    end)

    it("appends segments: generated step ids, indexes, duplicates", function()
        local r = route()
        local seg, errors = Schema.AddSegment(r, { id = "s1", title = "S1", steps = {
            { accept = 1 }, { id = "custom", turnin = 1 }, { accept = 2 },
        } })
        assert.same({}, errors)
        assert.equal(1, seg.first)
        assert.equal(3, seg.last)
        assert.same({ "s1:1", "custom", "s1:3" }, H.ids(r.steps))
        assert.equal(r.steps[2], r.stepById.custom)
        assert.equal(2, r.steps[2].index)
        assert.equal("s1", r.steps[2].segment)
        assert.equal(2, r.steps[2].segIndex)

        local seg2, errors2 = Schema.AddSegment(r, { id = "s2", title = "S2", steps = { { id = "custom", accept = 3 } } })
        assert.equal(4, seg2.first)
        assert.is_true(hasError(errors2, "duplicate step id 'custom'"))

        local _, errors3 = Schema.AddSegment(r, { id = "s1", title = "again", steps = { { accept = 4 } } })
        assert.is_true(hasError(errors3, "duplicate segment id"))

        local _, errors4 = Schema.AddSegment(r, { id = "s3", title = "S3", steps = {} })
        assert.is_true(hasError(errors4, "steps must be a non%-empty list"))
    end)

    it("records an error (does not raise) for a segment without id", function()
        local r = route()
        local ok, seg, errors = pcall(Schema.AddSegment, r, { title = "no id", steps = { { accept = 1 } } })
        assert.is_true(ok)
        assert.is_table(seg)
        assert.is_true(hasError(errors, "id must be a string"))
        assert.is_nil(next(r.segmentById))
    end)

    it("matches filters and routes against player facts", function()
        local player = { class = "PALADIN", race = "Scourge", faction = "Horde" }
        assert.is_true(Schema.FiltersMatch(nil, player))
        assert.is_true(Schema.FiltersMatch({ class = { PALADIN = true } }, player))
        assert.is_false(Schema.FiltersMatch({ class = { WARRIOR = true } }, player))
        assert.is_false(Schema.FiltersMatch({ race = { Troll = true } }, player))
        assert.is_false(Schema.FiltersMatch({ faction = "Alliance" }, player))
        local r = route()
        assert.is_true(Schema.RouteMatches(r, player))
        assert.is_false(Schema.RouteMatches(r, { class = "PALADIN", race = "Orc", faction = "Horde" }))
        assert.is_false(Schema.RouteMatches(r, { class = "PALADIN", race = "Scourge", faction = "Alliance" }))
        local any = Schema.NormalizeRoute({ api = 1, id = "any", title = "Any" })
        assert.is_true(Schema.RouteMatches(any, { class = "DRUID", race = "Skyborne", faction = "Horde" }))
    end)

    it("picks localized text", function()
        assert.equal("x", Schema.Text("x", "ruRU"))
        assert.equal("ру", Schema.Text({ ru = "ру", en = "en" }, "ruRU"))
        assert.equal("en", Schema.Text({ ru = "ру", en = "en" }, "enUS"))
        assert.equal("en", Schema.Text({ ru = "ру", en = "en" }, "deDE"))
        assert.equal("ру", Schema.Text({ ru = "ру" }, "enUS"))
        assert.equal("full", Schema.Text({ ruRU = "full", ru = "short" }, "ruRU"))
        assert.is_nil(Schema.Text(nil, "enUS"))
    end)
end)

describe("the core test fixture module", function()
    it("loads without schema errors and covers every action type and step field", function()
        local mod = Loader.LoadModule(H.FIXTURE_DIR, { schema = Schema })
        assert.same({}, mod.errors)
        assert.equal(1, #mod.routes)
        local r = mod.routes[1]
        assert.equal("test-route", r.id)
        assert.equal("Horde", r.faction)
        assert.same({ Scourge = true }, r.races)
        assert.same({ PALADIN = true }, r.classes)
        local seenActions, seenFields = {}, {}
        for _, s in ipairs(r.steps) do
            for _, a in ipairs(s.actions) do seenActions[a.type] = true end
            for k in pairs(s.def) do seenFields[k] = true end
        end
        for _, a in ipairs(Schema.ACTION_ORDER) do
            assert.is_true(seenActions[a] == true, "action " .. a)
        end
        for _, f in ipairs({ "id", "at", "radius", "npc", "note", "reward", "gossip", "use", "bg", "optional",
            "class", "race", "faction", "spells" }) do
            assert.is_true(seenFields[f] == true, "field " .. f)
        end
        assert.equal(29, #r.steps) -- 26 for Scourge PALADIN Horde + 3 filtered out
    end)
end)
