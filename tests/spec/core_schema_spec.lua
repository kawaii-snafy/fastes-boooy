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

describe("Schema: core 0.4.0 additions", function()
    it("`ok` (acknowledged validator warnings): a code, a list of codes, codes with a ceiling", function()
        local s, errors = step({ accept = 1, ok = "at-far-from-giver" })
        assert.same({}, errors)
        assert.same({ ["at-far-from-giver"] = true }, s.ok)

        s, errors = step({ accept = 1, ok = { "at-far-from-giver", "quest-out-of-scope" } })
        assert.same({}, errors)
        assert.same({ ["at-far-from-giver"] = true, ["quest-out-of-scope"] = true }, s.ok)

        s, errors = step({ level = 30, ok = { ["level-grind"] = 700 } })
        assert.same({}, errors)
        assert.same({ ["level-grind"] = 700 }, s.ok)

        s, errors = step({ level = 30, ok = { "skip-ahead", ["level-grind"] = 90 } })
        assert.same({}, errors)
        assert.same({ ["skip-ahead"] = true, ["level-grind"] = 90 }, s.ok)

        -- absent: no key at all; the engine never reads it
        s, errors = step({ accept = 1 })
        assert.same({}, errors)
        assert.is_nil(s.ok)
    end)

    it("`ok`: only the shape is checked (codes are [a-z-]+, a ceiling is a number >= 0)", function()
        local function okErrors(v)
            local s, errors = step({ accept = 1, ok = v })
            return errors, s
        end
        assert.is_true(hasError(okErrors(5), "t: ok must be a message code"))
        assert.is_true(hasError(okErrors(true), "t: ok must be a message code"))
        assert.is_true(hasError(okErrors(""), "t: ok must be a message code"))
        assert.is_true(hasError(okErrors("Level_Grind"), "t: ok must be a message code"))
        assert.is_true(hasError(okErrors({}), "t: ok is empty"))
        assert.is_true(hasError(okErrors({ "ok-code", "BAD" }), "t: ok%[2%] is not a message code"))
        assert.is_true(hasError(okErrors({ ["level-grind"] = "many" }), "t: ok%['level%-grind'%] must be a number >= 0"))
        assert.is_true(hasError(okErrors({ ["level-grind"] = -1 }), "t: ok%['level%-grind'%] must be a number >= 0"))
        assert.is_true(hasError(okErrors({ ["level-grind"] = true }), "t: ok%['level%-grind'%] must be a number >= 0"))
        assert.is_true(hasError(okErrors({ [7.5] = 1 }), "t: ok has an invalid key 7.5"))
        assert.is_true(hasError(okErrors({ Bad = 1 }), "t: ok has an invalid key Bad"))
        -- the valid part of a partly wrong value is kept
        local errors, s = okErrors({ "skip-ahead", "BAD", ["level-grind"] = 0 })
        assert.equal(1, #errors)
        assert.same({ ["skip-ahead"] = true, ["level-grind"] = 0 }, s.ok)
        -- any code that looks like one is accepted here: the validator knows the codes
        errors, s = okErrors("no-such-code")
        assert.same({}, errors)
        assert.same({ ["no-such-code"] = true }, s.ok)
    end)

    it("`ok` on a segment (segment-level)", function()
        local r = Schema.NormalizeRoute({ api = 1, id = "r", title = "R" })
        local seg, errors = Schema.AddSegment(r, { id = "s", title = "S", levels = { 1, 2 }, ok = "segment-level",
            steps = { { accept = 1 } } })
        assert.same({}, errors)
        assert.same({ ["segment-level"] = true }, seg.ok)
        local _, errors2 = Schema.AddSegment(r, { id = "s2", title = "S", ok = 5, steps = { { accept = 2 } } })
        assert.is_true(hasError(errors2, "segment s2: ok must be a message code"))
        -- `ok` is not a route key
        local _, rerrors = Schema.NormalizeRoute({ api = 1, id = "r2", title = "R", ok = "x" })
        assert.is_true(hasError(rerrors, "route r2: unknown key 'ok'"))
    end)

    it("route `aliases`: one former id or a list", function()
        local r, errors = Schema.NormalizeRoute({ api = 1, id = "new", title = "N", aliases = "old" })
        assert.same({}, errors)
        assert.same({ "old" }, r.aliases)
        r, errors = Schema.NormalizeRoute({ api = 1, id = "new", title = "N", aliases = { "old-1", "old_2", "old-1" } })
        assert.same({}, errors)
        assert.same({ "old-1", "old_2" }, r.aliases)
        r, errors = Schema.NormalizeRoute({ api = 1, id = "new", title = "N" })
        assert.same({}, errors)
        assert.is_nil(r.aliases)
        r, errors = Schema.NormalizeRoute({ api = 1, id = "new", title = "N", aliases = { "has space", 7, "", "new", "fine" } })
        assert.equal(4, #errors)
        assert.is_true(hasError(errors, "route new: aliases%[1%] must be a route id"))
        assert.is_true(hasError(errors, "route new: aliases%[2%] must be a route id"))
        assert.is_true(hasError(errors, "route new: aliases%[3%] must be a route id"))
        assert.is_true(hasError(errors, "route new: alias 'new' is the id of the route itself"))
        assert.same({ "fine" }, r.aliases)
    end)

    it("marks positional step ids (`autoId`): they are no insert anchors", function()
        local r = Schema.NormalizeRoute({ api = 1, id = "r", title = "R" })
        local seg = Schema.AddSegment(r, { id = "s", title = "S", steps = { { accept = 1 }, { id = "named", turnin = 1 } } })
        assert.equal("s:1", seg.steps[1].id)
        assert.is_true(seg.steps[1].autoId)
        assert.equal("named", seg.steps[2].id)
        assert.is_nil(seg.steps[2].autoId)
    end)

    it("Schema.NormalizeFilters: the class / race / faction keys of a step or of an insert scope", function()
        local errors = {}
        assert.is_nil(Schema.NormalizeFilters({ accept = 1 }, "w", errors))
        assert.same({ class = { PALADIN = true } }, Schema.NormalizeFilters({ class = "PALADIN" }, "w", errors))
        assert.same({ class = { PALADIN = true, DRUID = true }, race = { Orc = true, Troll = true }, faction = "Horde" },
            Schema.NormalizeFilters({ class = { "PALADIN", "DRUID" }, race = { "Orc", "Troll" }, faction = "Horde" },
                "w", errors))
        assert.same({}, errors)
        -- the same code path as a step's own filters
        local s = step({ accept = 1, class = "MAGE", race = "Troll" })
        assert.same({ class = { MAGE = true }, race = { Troll = true } }, s.filters)
        -- errors: unknown class token, bad faction, a race token that is not a string (the race NAMES are
        -- client data: only the offline tools know them)
        Schema.NormalizeFilters({ class = "PALADN", race = { 5 }, faction = "Neutral" }, "w", errors)
        assert.same({
            "w: unknown class token 'PALADN'",
            "w: race tokens must be strings (UnitRace raceFile)",
            "w: faction must be Horde or Alliance",
        }, errors)
        errors = {}
        assert.same({ race = { Undead = true } }, Schema.NormalizeFilters({ race = "Undead" }, "w", errors))
        assert.same({}, errors)
    end)

    it("an empty class / race list is an error, not 'no filter' (a step and a shared insert)", function()
        local errors = {}
        -- the dimension stays unfiltered (the key says nothing usable), the error names it
        assert.same({}, Schema.NormalizeFilters({ class = {} }, "w", errors))
        assert.same({ faction = "Horde" }, Schema.NormalizeFilters({ race = {}, faction = "Horde" }, "w", errors))
        assert.same({
            "w: class is an empty list: name at least one class token, or leave the key out",
            "w: race is an empty list: name at least one race token, or leave the key out",
        }, errors)
        -- a list without array part counts as empty too
        errors = {}
        Schema.NormalizeFilters({ class = { [2] = "MAGE" } }, "w", errors)
        assert.equal(1, #errors)
        -- a step: reported (the tools turn it into an ERROR of the file)
        local _, serrors = step({ accept = 1, class = {} })
        assert.is_true(hasError(serrors, "class is an empty list"))
        -- a shared insert with an empty scope list is rejected as a whole: unscoped it would land in
        -- every route (every class), the opposite of what the author wrote
        local _, C = Loader.LoadSchema(".")
        local lib = C.NewLibrary()
        C.AddLibrarySegment(lib, { id = "lib", title = "L", steps = { { id = "lib-a", accept = 2 } } })
        for _, def in ipairs({
            { after = "lib-a", class = {}, steps = { { id = "e-1", manual = true } } },
            { after = "lib-a", class = "MAGE", race = {}, steps = { { id = "e-2", manual = true } } },
        }) do
            local ins, ierrors = C.AddLibraryInsert(lib, def)
            assert.is_nil(ins)
            assert.is_true(hasError(ierrors, "is an empty list"))
            assert.is_true(hasError(ierrors, "^insert after 'lib%-a': the insert is rejected: an empty scope list"))
        end
        assert.same({}, lib.inserts)
        assert.is_nil(lib.scratch.stepById["e-1"], "the ids of a rejected insert stay free")
        -- the same insert with a real scope is accepted
        local ins, ierrors = C.AddLibraryInsert(lib, { after = "lib-a", class = "MAGE",
            steps = { { id = "e-1", manual = true } } })
        assert.same({}, ierrors)
        assert.is_table(ins)
    end)

    it("Schema.CheckData: the shape of the class reward table", function()
        local errors = {}
        assert.equal(0, Schema.CheckData({ quests = { [1] = "x" } }, "d", errors))
        assert.equal(0, Schema.CheckData({ rewards = { DRUID = { [92461] = 1, [92463] = 3 }, MAGE = {} } }, "d", errors))
        assert.equal(0, Schema.CheckData(nil, "d", errors))
        assert.same({}, errors)
        assert.equal(1, Schema.CheckData({ rewards = 5 }, "d", errors))
        assert.equal("d: rewards must be a table { CLASS = { [questID] = index } }", errors[1])
        errors = {}
        Schema.CheckData({ rewards = {
            Druid = { [1] = 1 },               -- a class name, not the token
            WARRIOR = 2,                       -- not a table
            PALADIN = { [0] = 1, x = 1 },      -- keys that are no quest ids
            MAGE = { [789] = 0 },              -- index 0
            ROGUE = { [790] = 1.5 },           -- not an integer
            SHAMAN = { [791] = "two" },        -- not a number
        } }, "d", errors)
        table.sort(errors)
        assert.same({
            "d: rewards.Druid: unknown class token 'Druid'",
            "d: rewards.MAGE[789]: the choice must be a positive integer (got 0)",
            "d: rewards.PALADIN: the key 0 is not a quest id",
            "d: rewards.PALADIN: the key x is not a quest id",
            "d: rewards.ROGUE[790]: the choice must be a positive integer (got 1.5)",
            "d: rewards.SHAMAN[791]: the choice must be a positive integer (got two)",
            "d: rewards.WARRIOR must be a table { [questID] = index }",
        }, errors)
    end)
end)

describe("Compose (Core/Compose.lua) loaded with the Schema", function()
    it("is pure and shares the tools' Schema", function()
        local S, C = Loader.LoadSchema(".")
        assert.is_table(C)
        assert.equal(C, S.Compose)
        assert.is_function(C.Build)
        -- a route without UseSegments / AddInsert is not composed
        local r = S.NormalizeRoute({ api = 1, id = "plain", title = "P" })
        S.AddSegment(C.OwnTarget(r), { id = "s", title = "S", steps = { { accept = 1 } } })
        assert.is_false(C.IsComposed(r))
        assert.same({}, C.Build(r, nil))
        assert.same({ "s:1" }, H.ids(r.steps))
        -- library + uses + insert (pure, without the addon)
        local lib = C.NewLibrary()
        local seg, errors = C.AddLibrarySegment(lib, { id = "lib", title = "L", steps = { { accept = 2 }, { turnin = 2 } } },
            { module = "Lib", file = "Lib/x.lua" })
        assert.same({}, errors)
        assert.equal("Lib", seg.library)
        assert.equal("Lib/x.lua", seg.steps[1].file)
        assert.equal(1, (C.AddUses(r, { "lib" })))
        assert.is_table((C.AddInsert(r, { before = "lib:2", steps = { { manual = true } } })))
        assert.is_true(C.IsComposed(r))
        assert.same({}, C.Build(r, lib))
        assert.same({ "s:1", "lib:1", "lib:2+1", "lib:2" }, H.ids(r.steps))
        assert.same({ "s", "lib" }, H.ids(r.segments))
        assert.equal(3, r.stepById["lib:2+1"].index)
        assert.same({ "s:1" }, H.ids(r.own.steps))
        -- idempotent
        assert.same({}, C.Build(r, lib))
        assert.same({ "s:1", "lib:1", "lib:2+1", "lib:2" }, H.ids(r.steps))
        -- a shared insert with a source (the offline loader): tags, scope, per-route copies
        local ins, ierrors = C.AddLibraryInsert(lib, { after = "lib:1", class = "PALADIN",
            steps = { { id = "shared-1", manual = true } } }, { module = "Lib", file = "Lib/y.lua" })
        assert.same({}, ierrors)
        assert.equal(1, #lib.inserts)
        assert.equal(ins, lib.inserts[1])
        assert.same({ class = { PALADIN = true } }, ins.scope)
        assert.equal("Lib", ins.steps[1].library)
        assert.equal("Lib/y.lua", ins.steps[1].file)
        local berrors = C.Build(r, lib)
        assert.same({ "s:1", "lib:1", "shared-1", "lib:2+1", "lib:2" }, H.ids(r.steps))
        -- the positional anchor is reported with the insert's source
        assert.equal(1, #berrors)
        assert.matches("anchor 'lib:1' is a positional step id", berrors[1].msg)
        assert.same({ module = "Lib", file = "Lib/y.lua" }, berrors[1].source)
        assert.same({ plain = true }, ins.applied)
        -- MergeData: fillOnly keeps existing values
        local d = C.MergeData({ quests = { [1] = "own" } }, { quests = { [1] = "lib", [2] = "lib2" }, x = 1 }, true)
        assert.same({ quests = { [1] = "own", [2] = "lib2" }, x = 1 }, d)
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
