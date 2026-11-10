-- Layout of the guides module addons/FastesBoooy_Guides (docs/dev/PLAN.md A.1-A.4, C.1, C.2, D.2): the real
-- module is loaded through tools/lib/route_loader.lua and its registered content is checked against the
-- contracts the phases rely on:
--   * no load error; the routes are exactly the race x class combos of the start zones that have announced
--     themselves, restricted by `only`;
--   * Route.lua for all five races (the Durotar and Mulgore files replaced by the fixture start zones of
--     tests/fixtures/guides/FastesBoooy_StartZones): 28 routes with the ids, titles, races, classes, aliases and
--     segment chains of A.4;
--   * explicit step ids in the new and rewritten segments (a positional id can never be an anchor);
--   * the shared anchors of C.2: they exist, the race-filtered alternatives (F) are filtered with the planned
--     races, every other anchor is unfiltered (class and race files anchor on them);
--   * scope and id prefix of every shared insert: class files, race files, start-zone files;
--   * no `reward` on a shared base step (class reward choices live in the class reward table);
--   * the level gates of 12-22 point at mobs of the player's level and stand where those mobs are; the races that
--     walk into Thunder Bluff pass the flight master once; the Russian notes of 12-22 use Russian names;
--   * the proofs for the races whose start zone is not written yet (D.2, F2b step 6): the shared path from
--     h-12-orgrimmar-tirisfal to level 60 from synthetic hand-over states, in the validator harness;
--   * the base profiles (the validator on the module with --skip 'Classes/*', not the harness): no route has an
--     ERROR, and the template checks report nothing but the race inserts whose anchor is a class step (C.7).
--
-- A parallel agent runs the spec on its own files (D.0 rule 9):
--   GUIDES_SKIP / GUIDES_KEEP  comma lists of globs (the logic of --skip / --keep): files that are not loaded
--   GUIDES_OWN                 globs: the per-file assertions run only for matching files
-- With any of them the assertions about the whole module (route list, Route.lua, harness proofs, base profiles)
-- are skipped.

local Loader = require("lib.route_loader")
local Glob = require("lib.glob")
local DB = require("lib.fbdb")

local GUIDES = "addons/FastesBoooy_Guides"
local FIXTURE_ZONES = "tests/fixtures/guides/FastesBoooy_StartZones"
local STATES = "tests/fixtures/validator"

local SKIP = Glob.Split(os.getenv("GUIDES_SKIP"))
local KEEP = Glob.Split(os.getenv("GUIDES_KEEP"))
local OWN = Glob.Split(os.getenv("GUIDES_OWN"))
local PARTIAL = #SKIP > 0 or #OWN > 0

local function own(file)
    return #OWN == 0 or Glob.Any(OWN, file)
end

local Schema = Loader.LoadSchema(".")

local function run(cmd)
    local p = assert(io.popen(cmd .. " 2>&1; echo \"__EXIT=$?\""))
    local out = p:read("*a")
    p:close()
    local code = tonumber(out:match("__EXIT=(%d+)%s*$"))
    return code, (out:gsub("__EXIT=%d+%s*$", ""))
end

local function sortedKeys(set)
    local out = {}
    for k in pairs(set or {}) do out[#out + 1] = k end
    table.sort(out)
    return out
end

local function ids(list)
    local out = {}
    for i, x in ipairs(list) do out[i] = x.id end
    return out
end

local function errorLines(mod, onlyOwn)
    local out = {}
    for _, e in ipairs(mod.errors) do
        if not onlyOwn or not e.file or own(e.file) then out[#out + 1] = tostring(e.file) .. ": " .. tostring(e.msg) end
    end
    return out
end

---------------------------------------------------------------------------------------------------------------
-- the plan's tables
---------------------------------------------------------------------------------------------------------------

local CLASSES = {
    WARRIOR = { slug = "warrior", ru = "воин", en = "Warrior", file = "Warrior", prefix = "war-" },
    HUNTER = { slug = "hunter", ru = "охотник", en = "Hunter", file = "Hunter", prefix = "hun-" },
    ROGUE = { slug = "rogue", ru = "разбойник", en = "Rogue", file = "Rogue", prefix = "rog-" },
    SHAMAN = { slug = "shaman", ru = "шаман", en = "Shaman", file = "Shaman", prefix = "sha-" },
    WARLOCK = { slug = "warlock", ru = "чернокнижник", en = "Warlock", file = "Warlock", prefix = "wlk-" },
    MAGE = { slug = "mage", ru = "маг", en = "Mage", file = "Mage", prefix = "mag-" },
    PRIEST = { slug = "priest", ru = "жрец", en = "Priest", file = "Priest", prefix = "pri-" },
    DRUID = { slug = "druid", ru = "друид", en = "Druid", file = "Druid", prefix = "dru-" },
    PALADIN = { slug = "paladin", ru = "паладин", en = "Paladin", file = "Paladin", prefix = "pal-" },
}

local SHARED_22_60 = {
    "h-22-hillsbrad", "h-24-barrens-stonetalon", "h-27-ashenvale-needles", "h-31-hillsbrad-arathi",
    "h-34-stranglethorn", "h-37-desolace-dustwallow", "h-41-arathi-badlands", "h-44-swamp-stranglethorn",
    "h-46-tanaris-feralas", "h-50-hinterlands-searing-steppes", "h-53-azshara-ungoro-silithus",
    "h-56-felwood-winterspring-plaguelands",
}
local SILVERPINE_ON = { "h-13-silverpine", "h-15-barrens", "h-18-stonetalon-ashenvale" }
for _, id in ipairs(SHARED_22_60) do SILVERPINE_ON[#SILVERPINE_ON + 1] = id end
local VISIT = "h-12-orgrimmar-tirisfal"

-- registration order of Route.lua; `start` = the segments the zone announces
local RACES = {
    { race = "Orc", slug = "orc", ru = "Орк", en = "Orc", zone = "Durotar", visit = true, prefix = "orc-",
      classes = { "HUNTER", "MAGE", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" } },
    { race = "Troll", slug = "troll", ru = "Тролль", en = "Troll", zone = "Durotar", visit = true, prefix = "tro-",
      classes = { "HUNTER", "MAGE", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" } },
    { race = "Tauren", slug = "tauren", ru = "Таурен", en = "Tauren", zone = "Mulgore", visit = true, prefix = "tau-",
      classes = { "DRUID", "HUNTER", "SHAMAN", "WARRIOR" } },
    { race = "Scourge", slug = "undead", ru = "Нежить", en = "Undead", zone = "Tirisfal", visit = false, prefix = "und-",
      classes = { "MAGE", "PALADIN", "PRIEST", "ROGUE", "WARLOCK", "WARRIOR" },
      aliases = { PALADIN = "horde-undead-paladin" } },
    { race = "Skyborne", slug = "skyborne", ru = "Скайборн", en = "Skyborne", zone = "Zephras", visit = true,
      prefix = "sky-", classes = { "DRUID", "HUNTER", "ROGUE", "SHAMAN", "WARRIOR" },
      aliases = { DRUID = "horde-skyborne-druid" } },
}

local ZONES = {
    Tirisfal = { segments = { "ud-01-deathknell", "ud-02-tirisfal" }, races = { Scourge = true },
                 prefixes = { "ud01-", "ud02-" } },
    Zephras = { segments = { "sd-01-zephras", "sd-02-zephras", "sd-03-thunder-bluff" }, races = { Skyborne = true },
                prefixes = { "sd01-", "sd02-", "sd03-" } },
    Durotar = { segments = { "dur-01-valley-of-trials", "dur-02-durotar" }, races = { Orc = true, Troll = true },
                prefixes = { "dur01-", "dur02-" } },
    Mulgore = { segments = { "mul-01-camp-narache", "mul-02-mulgore", "mul-03-barrens-crossing" },
                races = { Tauren = true }, prefixes = { "mul01-", "mul02-", "mul03-" } },
}

local function chainOf(r, start)
    local list = {}
    for _, id in ipairs(start) do list[#list + 1] = id end
    if r.visit then list[#list + 1] = VISIT end
    for _, id in ipairs(SILVERPINE_ON) do list[#list + 1] = id end
    return list
end

-- Race-filtered alternatives of the shared path (the (F) anchors of C.2 and the other steps of their pairs).
local NOT_UNDEAD = { "Orc", "Skyborne", "Tauren", "Troll" }
local FILTERED = {
    ["h13-hadrec-440"] = { "Scourge" }, ["h13-hearth-brill"] = { "Scourge" }, ["h13-sevren"] = { "Scourge" },
    ["h13-raleigh"] = { "Scourge" }, ["h13-uc-lift"] = { "Scourge" }, ["h13-zeppelin"] = { "Scourge" },
    ["h13-durotar"] = { "Scourge" },
    ["h13-fly-uc"] = NOT_UNDEAD, ["h13-hearth-org"] = NOT_UNDEAD,
    ["h15-org-gate"] = { "Scourge" }, ["h15-org-fp"] = { "Scourge" },
    ["h18-fly-tb-1"] = { "Skyborne", "Tauren" },
    ["h18-go-mulgore"] = { "Orc", "Scourge", "Troll" }, ["h18-go-tb-lift"] = { "Orc", "Scourge", "Troll" },
    ["h18-fp-tb"] = { "Orc", "Scourge", "Troll" },
}

-- The anchors class and race files may rely on (C.2; B.7 for 22-60), by segment. Those listed in FILTERED are
-- the (F) anchors; every other one must be unfiltered.
local ANCHORS = {
    ["sd-03-thunder-bluff"] = { "sd03-spirit", "sd03-fp-tb", "sd03-fly-org" },
    ["h-12-orgrimmar-tirisfal"] = {
        "h12-fp-org", "h12-sethearth-org", "h12-borstan", "h12-wisdom", "h12-org-end", "h12-zeppelin", "h12-brill",
        "h12-fp-uc", "h12-end",
    },
    ["h-13-silverpine"] = {
        "h13-erland", "h13-lvl-12", "h13-fp-sepulcher", "h13-sepulcher-5", "h13-lvl-14", "h13-hearth-brill",
        "h13-fly-uc", "h13-uc-arrive", "h13-uc-end", "h13-zeppelin", "h13-hearth-org",
    },
    ["h-15-barrens"] = {
        "h15-org-gate", "h15-org-fp", "h15-org", "h15-start", "h15-razor-hill", "h15-far-watch", "h15-xr-arrive",
        "h15-xr-thork", "h15-fp-xroads", "h15-sethearth-xroads", "h15-xr-2", "h15-fp-ratchet", "h15-ratchet-2",
        "h15-fly-xroads", "h15-xr-3", "h15-hearth-xroads", "h15-xr-4", "h15-fly-ratchet", "h15-ratchet-3",
        "h15-fp-taurajo", "h15-sethearth-taurajo", "h15-fly-xroads-2", "h15-xr-5", "h15-end",
    },
    ["h-18-stonetalon-ashenvale"] = {
        "h18-fly-taurajo", "h18-lvl-18", "h18-fly-tb-1", "h18-fp-tb", "h18-tb-zamah", "h18-tb-1", "h18-fly-ratchet",
        "h18-ratchet", "h18-hearth-taurajo", "h18-taurajo-end", "h18-fly-xroads", "h18-xr", "h18-border",
        "h18-lvl-20", "h18-fp-sunrock", "h18-fly-tb", "h18-sethearth-tb", "h18-tb-2", "h18-fly-ratchet-2",
        "h18-fly-xroads-2", "h18-fp-zoram", "h18-lvl-21", "h18-lvl-22", "h18-hearth-tb", "h18-tb-3", "h18-end",
    },
    ["h-22-hillsbrad"] = {
        "h-22-tb-start", "h-22-tb-fly", "h-22-tb-fly-org", "h-22-org-fp", "h-22-uc-arrive", "h-22-uc-fly",
        "h-22-the-sepulcher-apothecary", "h-24-tarrenmill-end", "h-24-tb-hearth",
    },
    ["h-24-barrens-stonetalon"] = { "h-25-sun-rock-retreat", "h25-rebirth-seeds", "h25-rebirth-turnin" },
    ["h-50-hinterlands-searing-steppes"] = { "h50-owen-thadd" },
}

-- Segments in which every step has an explicit id (A.3: the new and the rewritten ones; h-22-hillsbrad: B.7).
-- The Tirisfal and Zephras start segments join the list when they are rewritten class-neutral (F2c / F2d).
local EXPLICIT_IDS = {
    "sd-03-thunder-bluff", "h-12-orgrimmar-tirisfal", "h-13-silverpine", "h-15-barrens", "h-18-stonetalon-ashenvale",
    "h-22-hillsbrad",
}

-- Level gates of the shared path 12-22 (B.8): plain `level` steps.
local GATES = { "h13-lvl-12", "h13-lvl-14", "h18-lvl-18", "h18-lvl-20", "h18-lvl-21", "h18-lvl-22" }

-- The segments of 12-22 and the Latin-letter names their Russian notes may keep (no Russian form is known for
-- them; everything else, NPC and mob names first of all, is written in Russian).
local SEGMENTS_12_22 = { "h-12-orgrimmar-tirisfal", "h-13-silverpine", "h-15-barrens", "h-18-stonetalon-ashenvale" }
local LATIN_ALLOWED = { "Talondeep Path", "XT:4", "XT:9" }

-- the acknowledgement of the unverified override of 861 / 854 (docs/dev/PLAN.md E.21) on the accept of 844
local OVERRIDE_STEP, OVERRIDE_CODE = "h15-xr-arrive", "db-override-unverified"

local function acknowledges(step, code)
    local ok = step and step.ok
    if type(ok) == "string" then return ok == code end
    if type(ok) ~= "table" then return false end
    if ok[code] then return true end
    for _, c in ipairs(ok) do
        if c == code then return true end
    end
    return false
end

---------------------------------------------------------------------------------------------------------------
-- the start-zone announcements, read from the source of the module (the loader keeps `ns` private)
---------------------------------------------------------------------------------------------------------------

--- { [zone] = { segments = { ... }, only = { CLASS = true } | nil, file = "Segments/..." } } of the TOC files
-- that are loaded; `replace` as for Loader.LoadModule. Comment lines are ignored (placeholders show the
-- announcement they will make in their header).
local function announcements(tocFiles, skipped, replace)
    local out = {}
    for _, rel in ipairs(tocFiles) do
        if rel:find("^Segments/") and not skipped[rel] then
            local text = Loader.readFile((replace and replace[rel]) or (GUIDES .. "/" .. rel)) or ""
            for line in text:gmatch("[^\n]+") do
                if not line:find("^%s*%-%-") then
                    local zone, body = line:match("ns%.startZones%.(%w+)%s*=%s*(%b{})")
                    if zone then
                        local a = { segments = {}, file = rel }
                        local onlyBody = body:match("only%s*=%s*(%b{})")
                        if onlyBody then
                            a.only = {}
                            for c in onlyBody:gmatch('"([^"]+)"') do a.only[c] = true end
                        end
                        local list = body:gsub("only%s*=%s*%b{}", "")
                        for s in list:gmatch('"([^"]+)"') do a.segments[#a.segments + 1] = s end
                        out[zone] = a
                    end
                end
            end
        end
    end
    return out
end

--- The routes Route.lua has to register for these announcements: { { id, title, race, class, chain, alias } }.
local function expectedRoutes(ann)
    local out = {}
    for _, r in ipairs(RACES) do
        local a = ann[r.zone]
        if a then
            for _, class in ipairs(r.classes) do
                if not a.only or a.only[class] then
                    local c = CLASSES[class]
                    out[#out + 1] = {
                        id = r.slug .. "-" .. c.slug,
                        title = { ru = r.ru .. "-" .. c.ru .. " 1-60", en = r.en .. " " .. c.en .. " 1-60" },
                        race = r.race, class = class, chain = chainOf(r, a.segments),
                        alias = r.aliases and r.aliases[class] or nil,
                    }
                end
            end
        end
    end
    return out
end

local function assertRoutes(mod, expected)
    assert.same(ids(expected), ids(mod.routes))
    for i, want in ipairs(expected) do
        local r = mod.routes[i]
        assert.same(want.title, r.title, want.id)
        assert.same({ want.race }, sortedKeys(r.races), want.id)
        assert.same({ want.class }, sortedKeys(r.classes), want.id)
        assert.equal("Horde", r.faction, want.id)
        assert.same({ 1, 60 }, r.levels, want.id)
        assert.is_true(r.default, want.id)
        assert.equal("0.4.0", r.version, want.id)
        assert.same(want.chain, ids(r.uses), want.id .. ": segment chain")
        assert.same(want.chain, ids(r.segments), want.id .. ": composed segments")
        assert.equal(0, #r.own, want.id .. ": a route owns nothing")
        if want.alias then
            assert.equal(r, mod.aliases[want.alias], want.id .. ": alias " .. want.alias)
        end
        for _, word in ipairs({ "Horde", "Орд", "library", "shared" }) do
            for _, text in ipairs({ r.title.ru, r.title.en, r.description.ru, r.description.en }) do
                assert.is_nil(text:find(word, 1, true), want.id .. ": '" .. word .. "' in a title or description")
            end
        end
    end
end

---------------------------------------------------------------------------------------------------------------

describe("addons/FastesBoooy_Guides", function()
    local mod, segments, stepById, skipped

    setup(function()
        mod = Loader.LoadModule(GUIDES, { schema = Schema, skipGlobs = SKIP, keepGlobs = KEEP })
        segments, stepById, skipped = {}, {}, {}
        for _, seg in ipairs(mod.librarySegments) do
            segments[seg.id] = seg
            for _, step in ipairs(seg.steps) do stepById[step.id] = step end
        end
        for _, rel in ipairs(mod.skipped or {}) do skipped[rel] = true end
    end)

    it("loads without an error", function()
        assert.same({}, errorLines(mod, PARTIAL))
        assert.is_nil(mod.declaredLibrary)
        if not PARTIAL then
            assert.equal(42, #mod.tocFiles, "TOC: Data.lua, 26 segment files, 9 class files, 5 race files, Route.lua")
            assert.equal("Data.lua", mod.tocFiles[1])
            assert.equal("Route.lua", mod.tocFiles[#mod.tocFiles])
        end
    end)

    it("lists Segments, then Classes, then Races, then Route.lua in the TOC", function()
        local rank = { Segments = 1, Classes = 2, Races = 3 }
        local last = 0
        for i = 2, #mod.tocFiles - 1 do
            local dir = mod.tocFiles[i]:match("^(%w+)/")
            assert.is_truthy(rank[dir], mod.tocFiles[i])
            assert.is_true(rank[dir] >= last, mod.tocFiles[i] .. " is out of order")
            last = rank[dir]
            assert.is_nil(mod.tocFiles[i]:find("Legacy", 1, true), "the legacy segments are gone")
        end
    end)

    if not PARTIAL then
        it("registers exactly the race x class combos of the announced start zones, restricted by `only`", function()
            local ann = announcements(mod.tocFiles, skipped)
            for zone, a in pairs(ann) do
                assert.is_truthy(ZONES[zone], "unknown start zone " .. zone)
                assert.same(ZONES[zone].segments, a.segments, zone .. " announces its segments in order")
            end
            local expected = expectedRoutes(ann)
            assert.is_true(#expected > 0)
            assertRoutes(mod, expected)
        end)

        it("Route.lua builds all 28 routes once every start zone has announced itself (fixture zones)", function()
            local replace = {}
            for _, rel in ipairs({
                "Segments/Durotar/01_ValleyOfTrials.lua", "Segments/Durotar/02_Durotar.lua",
                "Segments/Mulgore/01_CampNarache.lua", "Segments/Mulgore/02_Mulgore.lua",
                "Segments/Mulgore/03_BarrensCrossing.lua",
                -- the two announcements without `only` (the real ones carry it until phase F2c is done)
                "Segments/Tirisfal/02_Tirisfal.lua", "Segments/Zephras/03_ThunderBluff.lua",
            }) do
                replace[rel] = FIXTURE_ZONES .. "/" .. rel
                assert.is_true(Loader.fileExists(replace[rel]), replace[rel])
            end
            local full = Loader.LoadModule(GUIDES, { schema = Schema, replace = replace })
            assert.same({}, errorLines(full))
            local ann = announcements(full.tocFiles, {}, replace)
            assert.same({ "Durotar", "Mulgore", "Tirisfal", "Zephras" }, sortedKeys(ann))
            for zone, a in pairs(ann) do
                assert.is_nil(a.only, zone)
                assert.same(ZONES[zone].segments, a.segments, zone)
            end
            local expected = expectedRoutes(ann)
            assert.equal(28, #expected)
            assertRoutes(full, expected)
            assert.same({ "horde-skyborne-druid", "horde-undead-paladin" }, sortedKeys(full.aliases))
            -- the chains of A.4, spelled out once
            local byId = {}
            for _, r in ipairs(full.routes) do byId[r.id] = ids(r.uses) end
            assert.same({ "ud-01-deathknell", "ud-02-tirisfal", "h-13-silverpine", "h-15-barrens",
                "h-18-stonetalon-ashenvale", unpack(SHARED_22_60) }, byId["undead-warrior"])
            assert.same({ "sd-01-zephras", "sd-02-zephras", "sd-03-thunder-bluff", "h-12-orgrimmar-tirisfal",
                "h-13-silverpine", "h-15-barrens", "h-18-stonetalon-ashenvale", unpack(SHARED_22_60) },
                byId["skyborne-shaman"])
            assert.same({ "dur-01-valley-of-trials", "dur-02-durotar", "h-12-orgrimmar-tirisfal", "h-13-silverpine",
                "h-15-barrens", "h-18-stonetalon-ashenvale", unpack(SHARED_22_60) }, byId["orc-warrior"])
            assert.same(byId["orc-warrior"], byId["troll-priest"])
            assert.same({ "mul-01-camp-narache", "mul-02-mulgore", "mul-03-barrens-crossing",
                "h-12-orgrimmar-tirisfal", "h-13-silverpine", "h-15-barrens", "h-18-stonetalon-ashenvale",
                unpack(SHARED_22_60) }, byId["tauren-druid"])
        end)

        it("uses every shared segment in a route and registers no segment twice", function()
            local used, seen = {}, {}
            for _, r in ipairs(mod.routes) do
                for _, u in ipairs(r.uses) do used[u.id] = true end
            end
            for _, seg in ipairs(mod.librarySegments) do
                assert.is_nil(seen[seg.id], seg.id)
                seen[seg.id] = true
                -- h-12 is used by every race but the Undead: before the Durotar and Mulgore zones exist only by the
                -- Skyborne
                assert.is_true(used[seg.id], seg.id .. " is used by no route")
            end
        end)
    end

    it("gives every step of the new and rewritten segments an explicit id", function()
        for _, id in ipairs(EXPLICIT_IDS) do
            local seg = segments[id]
            if seg and own(seg.file) then
                assert.is_true(#seg.steps > 0, id)
                for _, step in ipairs(seg.steps) do
                    assert.is_nil(step.autoId, ("%s: step %d has the positional id %s"):format(id, step.segIndex, step.id))
                end
            else
                assert.is_true(seg ~= nil or PARTIAL, "segment " .. id .. " is not registered")
            end
        end
    end)

    it("has the shared anchors of the plan; only the race-filtered alternatives carry a filter", function()
        for segId, list in pairs(ANCHORS) do
            local seg = segments[segId]
            assert.is_true(seg ~= nil or PARTIAL, "segment " .. segId .. " is not registered")
            if seg and own(seg.file) then
                for _, id in ipairs(list) do
                    local step = stepById[id]
                    assert.is_truthy(step, "anchor " .. id .. " is missing")
                    assert.equal(segId, step.segment, id)
                    assert.is_nil(step.autoId, id)
                    if FILTERED[id] then
                        assert.is_truthy(step.filters, id .. " is a race-filtered alternative")
                        assert.same(FILTERED[id], sortedKeys(step.filters.race), id)
                        assert.is_nil(step.filters.class, id)
                    else
                        assert.is_nil(step.filters, id .. " must be unfiltered: class and race files anchor on it")
                    end
                end
            end
        end
        -- the other steps of the alternative pairs, and nothing else in 12-60 is filtered
        for _, seg in ipairs(mod.librarySegments) do
            if seg.id:find("^h%-") and own(seg.file) then
                for _, step in ipairs(seg.steps) do
                    if FILTERED[step.id] then
                        assert.same(FILTERED[step.id], sortedKeys(step.filters and step.filters.race), step.id)
                    else
                        assert.is_nil(step.filters, step.id .. " (" .. seg.id .. ") carries an unplanned filter")
                    end
                end
            end
        end
    end)

    it("keeps the level gates of 12-22 plain `level` steps", function()
        for _, id in ipairs(GATES) do
            local step = stepById[id]
            assert.is_true(step ~= nil or PARTIAL, "gate " .. id .. " is missing")
            if step and own(step.file) then
                assert.equal(1, #step.actions, id)
                assert.equal("level", step.actions[1].type, id)
                assert.is_nil(step.optional, id)
                assert.is_nil(step.filters, id)
            end
        end
    end)

    it("points every level gate of 12-22 at mobs of the player's level", function()
        -- The validator counts same-level kills (45 + 5 x level XP each). A gate whose waypoint sends the player to
        -- lower mobs costs more kills than the report says: h13-lvl-14 once pointed at the Moonrage Whitescalps
        -- (10-11) for a level-13 character, 60-75 XP a kill against 110. Rule: within 200 yd of `at` the DB
        -- snapshot has at least 10 spawns of hostile mobs whose top level reaches the player's level, and more of
        -- those than of lower ones. The player's level at `level = N` is N - 1, at `level = { L, fraction }` it is L.
        local db = DB.Load("tools/data/forever_db.lua")
        local checked = 0
        for _, id in ipairs(GATES) do
            local step = stepById[id]
            if step and own(step.file) then
                checked = checked + 1
                local a = step.actions[1]
                local player = (a.frac or 0) > 0 and a.level or a.level - 1
                local size = db.zones[step.at.map] and db.zones[step.at.map].size
                assert.is_truthy(size, id .. ": no zone size for map " .. tostring(step.at.map))
                local same, lower = 0, 0
                for _, npc in pairs(db.npcs) do
                    local spawns = npc.spawns and npc.spawns[step.at.map]
                    if spawns and npc.minLevel and npc.faction == "" and not (npc.flags and npc.flags.questgiver) then
                        for _, sp in ipairs(spawns) do
                            local dx, dy = (sp[1] - step.at.x) / 100 * size[1], (sp[2] - step.at.y) / 100 * size[2]
                            if dx * dx + dy * dy <= 200 * 200 then
                                if npc.maxLevel >= player then same = same + 1 else lower = lower + 1 end
                            end
                        end
                    end
                end
                local what = ("%s (player level %d): %d spawns of that level or higher, %d lower within 200 yd")
                    :format(id, player, same, lower)
                assert.is_true(same >= 10, what)
                assert.is_true(same > lower, what)
            end
        end
        assert.is_true(checked > 0 or PARTIAL)
    end)

    it("places the gate h18-lvl-20 at Windshear Crag, before the step that walks back to Ziz", function()
        -- The gate after h18-venomspitters sent a character that is short from Ziz back to the Crag and to Ziz
        -- again (430 + 543 yd); around Ziz there are only the venomspitters of 17-18.
        local seg = segments["h-18-stonetalon-ashenvale"]
        assert.is_true(seg ~= nil or PARTIAL)
        if seg and own(seg.file) then
            local crag, gate, back, ziz = stepById["h18-windshear"], stepById["h18-lvl-20"],
                stepById["h18-venomspitters"], stepById["h18-ziz-2"]
            assert.is_truthy(crag and gate and back and ziz)
            assert.equal(crag.segIndex + 1, gate.segIndex, "the gate follows the Crag step")
            assert.equal(gate.segIndex + 1, back.segIndex, "the way back to Ziz follows the gate")
            assert.equal(back.segIndex + 1, ziz.segIndex)
            assert.same(crag.at, gate.at)
        end
    end)

    it("lets the races that walk into Thunder Bluff pass the flight master once, after Zamah", function()
        -- lift > Tal > Pools > Zamah > Tal is 840 yd of straight legs and two climbs of the tower, with the timer
        -- of 853 running; lift > Pools > Zamah > Tal is 664 yd. The filtered `fp` step stands right before the
        -- flight out.
        local seg = segments["h-18-stonetalon-ashenvale"]
        assert.is_true(seg ~= nil or PARTIAL)
        if seg and own(seg.file) then
            local lift, zamah, exit, fp, fly = stepById["h18-go-tb-lift"], stepById["h18-tb-zamah"],
                stepById["h18-tb-1"], stepById["h18-fp-tb"], stepById["h18-fly-ratchet"]
            assert.is_truthy(lift and zamah and exit and fp and fly)
            assert.is_true(lift.segIndex < zamah.segIndex and zamah.segIndex < exit.segIndex)
            assert.equal(exit.segIndex + 1, fp.segIndex, "h18-fp-tb follows the training anchor h18-tb-1")
            assert.equal(fp.segIndex + 1, fly.segIndex, "h18-fly-ratchet follows h18-fp-tb")
            assert.equal("fp", fp.actions[1].type)
            for i = lift.segIndex, zamah.segIndex do
                for _, a in ipairs(seg.steps[i].actions) do
                    assert.is_true(a.type ~= "fp", seg.steps[i].id .. ": no flight master on the way to Zamah")
                end
            end
        end
    end)

    it("writes the Russian notes of 12-22 with Russian names", function()
        -- One convention: NPC, mob and place names of the ru text are Russian (the same NPC was once named in
        -- English in the steps taken from one legacy segment and in Russian in those from the other).
        local checked = 0
        for _, segId in ipairs(SEGMENTS_12_22) do
            local seg = segments[segId]
            assert.is_true(seg ~= nil or PARTIAL, "segment " .. segId .. " is not registered")
            if seg and own(seg.file) then
                for _, step in ipairs(seg.steps) do
                    local ru = type(step.note) == "table" and step.note.ru or nil
                    if ru then
                        checked = checked + 1
                        local text = ru
                        for _, name in ipairs(LATIN_ALLOWED) do
                            text = text:gsub(name:gsub("%p", "%%%0"), "")
                        end
                        local word = text:match("[A-Za-z][A-Za-z']+[A-Za-z]")
                        assert.is_nil(word, ("%s: '%s' in the Russian note: %s"):format(step.id, tostring(word), ru))
                    end
                end
            end
        end
        assert.is_true(checked > 0 or PARTIAL)
    end)

    if not PARTIAL then
        it("acknowledges the unverified override of 861 / 854 exactly when a Tauren route exists", function()
            -- docs/dev/PLAN.md E.21 wants `ok = "db-override-unverified"` on the accept of 844. The WARN fires only
            -- for a Tauren (861 / 854 turned in): without a Tauren route in the full run the key is `ok-unused`
            -- and fails --strict; with one, the missing key fails --strict. So the key arrives with the first
            -- Tauren route (the Mulgore start zone, phase P1; its owner is phase P2), and the proofs below drop
            -- their --ignore by themselves.
            local tauren = false
            for _, r in ipairs(mod.routes) do
                if r.races.Tauren then tauren = true end
            end
            local step = stepById[OVERRIDE_STEP]
            assert.is_truthy(step)
            if tauren then
                assert.is_true(acknowledges(step, OVERRIDE_CODE), ("a Tauren route is registered: add ok = \"%s\" (with "
                    .. "the -- CONFIRM comment) to %s"):format(OVERRIDE_CODE, OVERRIDE_STEP))
            else
                assert.is_false(acknowledges(step, OVERRIDE_CODE), ("no Tauren route is registered: ok = \"%s\" on %s "
                    .. "is ok-unused in the full run"):format(OVERRIDE_CODE, OVERRIDE_STEP))
            end
        end)
    end

    it("scopes every shared insert to the class, race or start zone of its file, with the id prefix", function()
        local byClassFile, byRaceFile = {}, {}
        for token, c in pairs(CLASSES) do byClassFile["Classes/" .. c.file .. ".lua"] = { token = token, prefix = c.prefix } end
        for _, r in ipairs(RACES) do byRaceFile["Races/" .. r.race .. ".lua"] = r end
        local function prefixed(id, prefixes)
            for _, p in ipairs(prefixes) do
                if id:sub(1, #p) == p then return true end
            end
            return false
        end
        local checked = 0
        for _, ins in ipairs(mod.libraryInserts) do
            if own(ins.file) then
                checked = checked + 1
                local where = ("%s (%s %s)"):format(ins.file, ins.side, ins.anchor)
                local scope = ins.scope or {}
                local cf, rf = byClassFile[ins.file], byRaceFile[ins.file]
                local zone = ins.file:match("^Segments/(%w+)/")
                if cf then
                    assert.same({ cf.token }, sortedKeys(scope.class), where)
                    for _, step in ipairs(ins.steps) do
                        assert.is_true(prefixed(step.id, { cf.prefix }), where .. ": step id " .. step.id)
                        assert.same({ cf.token }, sortedKeys(step.filters and step.filters.class), step.id)
                    end
                elseif rf then
                    assert.same({ rf.race }, sortedKeys(scope.race), where)
                    for _, step in ipairs(ins.steps) do
                        assert.is_true(prefixed(step.id, { rf.prefix }), where .. ": step id " .. step.id)
                        assert.same({ rf.race }, sortedKeys(step.filters and step.filters.race), step.id)
                    end
                elseif zone and ZONES[zone] then
                    local z = ZONES[zone]
                    assert.is_true(#sortedKeys(scope.race) > 0, where .. ": no race scope")
                    for race in pairs(scope.race) do assert.is_true(z.races[race], where .. ": race " .. race) end
                    for _, step in ipairs(ins.steps) do
                        assert.is_true(prefixed(step.id, z.prefixes), where .. ": step id " .. step.id)
                        for race in pairs(step.filters and step.filters.race or {}) do
                            assert.is_true(z.races[race], step.id .. ": race " .. race)
                        end
                    end
                else
                    error(where .. ": shared inserts belong to Classes/, Races/ or a start-zone file")
                end
            end
        end
        assert.is_true(checked > 0 or PARTIAL)
    end)

    it("keeps the level-40 contract ids of the druid file and the riding steps of the race file", function()
        local dru, sky = {}, {}
        for _, ins in ipairs(mod.libraryInserts) do
            if ins.file == "Classes/Druid.lua" and ins.anchor == "h-40-org-arrive" then dru = ids(ins.steps) end
            if ins.file == "Races/Skyborne.lua" and ins.anchor == "dru-40-train" then
                sky = ids(ins.steps)
                assert.equal("after", ins.side)
                assert.same({ "DRUID" }, sortedKeys(ins.scope.class))
                for _, step in ipairs(ins.steps) do
                    assert.is_true(step.optional, step.id .. " is optional (riding)")
                    assert.equal("sky-40d-", step.id:sub(1, 8))
                end
            end
        end
        if own("Classes/Druid.lua") and not skipped["Classes/Druid.lua"] then
            assert.same({ "dru-40-fly-tb", "dru-40-train", "dru-40-fly-taurajo" }, dru)
        end
        if own("Races/Skyborne.lua") and not skipped["Races/Skyborne.lua"] and not skipped["Classes/Druid.lua"] then
            assert.is_true(#sky > 0, "the Skyborne druid riding steps follow dru-40-train")
        end
    end)

    it("carries no `reward` on a shared base step", function()
        -- A start zone whose announcement still has `only` is not class-neutral yet (its segments hold the class
        -- steps of one class until phase F2c): its files are exempt until the key is gone.
        local exempt = {}
        for zone, a in pairs(announcements(mod.tocFiles, skipped)) do
            if a.only then exempt["Segments/" .. zone .. "/"] = true end
        end
        local checked = 0
        for _, seg in ipairs(mod.librarySegments) do
            local dir = seg.file:match("^(Segments/%w+/)")
            if own(seg.file) and not exempt[dir] then
                checked = checked + 1
                for _, step in ipairs(seg.steps) do
                    assert.is_nil(step.reward, step.id .. " (" .. seg.file .. ")")
                end
            end
        end
        assert.is_true(checked > 0 or PARTIAL)
    end)
end)

---------------------------------------------------------------------------------------------------------------
-- Proofs for the races whose start zone does not exist yet (docs/dev/PLAN.md D.2, F2b step 6): the shared path
-- from the hand-over of the start zone to level 60, from synthetic hand-over states with the real history of
-- B.2, under the gate of every phase (--strict --end-level) and the grind budget of the base profiles (B.8).
---------------------------------------------------------------------------------------------------------------

if not PARTIAL then
    describe("the shared path from the hand-over states of Durotar and Mulgore (validator harness)", function()
        local SEGMENTS = table.concat({ VISIT, unpack(SILVERPINE_ON) }, ",")
        -- The real override layer on purpose (tools/overrides/shared.lua is part of what is proven here), named
        -- explicitly: no spec may read that directory by default (validator_overrides_spec.lua).
        local BASE = ("lua5.1 tools/validate_routes.lua --overrides tools/overrides --harness %s --segments %s "
            .. "--strict --end-level --max-grind-until h-18-stonetalon-ashenvale=120/200 --summary "
            .. "--grind-until h-18-stonetalon-ashenvale"):format(GUIDES, SEGMENTS)

        -- one TSV line of --summary: route, profile, errors, warnings, accepted, foreign, end level, worst end
        -- level, grind kills, worst, grind kills up to --grind-until, worst
        local function summary(out)
            local line = ("\n" .. out):match("\n(harness%-[^\n\t]*\t[^\n]*)")
            assert.is_truthy(line, out)
            local f = {}
            for field in (line .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = field end
            return { errors = tonumber(f[3]), warnings = tonumber(f[4]), endLevel = f[7], worstEndLevel = f[8],
                     kills = tonumber(f[11]), worst = tonumber(f[12]) }
        end

        local function proof(profile, state, extra)
            local code, out = run(("%s --profile %s --state %s/%s %s"):format(BASE, profile, STATES, state, extra or ""))
            return code, out, summary(out)
        end

        local function assertPasses(code, out, s)
            assert.equal(0, code, out)
            assert.equal(0, s.errors, out)
            assert.equal(0, s.warnings, out)
            assert.equal("60.00", s.endLevel, out)
            assert.equal("60.00", s.worstEndLevel, out)
            assert.is_true(s.kills <= 120 and s.worst <= 200, out)
        end

        for _, case in ipairs({
            { "Orc WARRIOR", "race=Orc,class=WARRIOR,faction=Horde" },
            { "Troll PRIEST", "race=Troll,class=PRIEST,faction=Horde" },
        }) do
            it(case[1] .. " from the Durotar hand-over (level 11.2 at Rhinag)", function()
                assertPasses(proof(case[2], "guides_state_orc_11.json"))
            end)
        end

        -- The Tauren reach the shared accept of 844 with its two breadcrumbs 861 and 854 turned in: the snapshot
        -- calls that exclusive, tools/overrides/shared.lua removes it (unverified). Until a Tauren route exists
        -- the step cannot acknowledge the resulting WARN (an `ok` no validated route uses is ok-unused), so the
        -- proofs name it with --ignore; the last case pins that this WARN, and nothing else, is what is ignored.
        -- Once the step carries the key (the case "acknowledges the unverified override ..." above demands it with
        -- the first Tauren route) the proofs run with the literal command of the plan, without --ignore.
        local acknowledged = false
        do
            local real = Loader.LoadModule(GUIDES, { schema = Schema })
            for _, seg in ipairs(real.librarySegments) do
                for _, step in ipairs(seg.steps) do
                    if step.id == OVERRIDE_STEP then acknowledged = acknowledges(step, OVERRIDE_CODE) end
                end
            end
        end
        local IGNORE = acknowledged and "" or ("--ignore " .. OVERRIDE_CODE)
        for _, case in ipairs({
            { "Tauren WARRIOR, base profile, walk variant of mul-03", "race=Tauren,class=WARRIOR,faction=Horde",
              "guides_state_tauren_11.json", "--skip 'Classes/*'" },
            { "Tauren DRUID with the class files, walk variant", "race=Tauren,class=DRUID,faction=Horde",
              "guides_state_tauren_11.json", "" },
            { "Tauren WARRIOR, base profile, flight variant (only Thunder Bluff known)",
              "race=Tauren,class=WARRIOR,faction=Horde", "guides_state_tauren_11_fly.json", "--skip 'Classes/*'" },
        }) do
            it(case[1] .. " from the Mulgore hand-over (level 11.8)", function()
                assertPasses(proof(case[2], case[3], case[4] .. " " .. IGNORE))
            end)
        end

        it("the Tauren accept 844 after 861 and 854 only through the unverified DB override", function()
            local profile, state = "race=Tauren,class=WARRIOR,faction=Horde", "guides_state_tauren_11.json"
            local code, out, s = proof(profile, state, "--skip 'Classes/*'")
            assert.equal(0, s.errors, out)
            if acknowledged then
                -- the step acknowledges both: the literal command of the plan passes
                assert.equal(0, code, out)
                assert.equal(0, s.warnings, out)
            else
                assert.equal(1, code, out)
                assert.equal(2, s.warnings, "one WARN per breadcrumb (861, 854) and no other:\n" .. out)
                local n = 0
                for line in out:gmatch("[^\n]+") do
                    if line:find("^%s*WARN") then
                        n = n + 1
                        assert.is_truthy(line:find("id=" .. OVERRIDE_STEP, 1, true), line)
                        assert.is_truthy(line:find("[" .. OVERRIDE_CODE .. "]", 1, true), line)
                    end
                end
                assert.equal(2, n, out)
            end
            -- without the override the validator refuses the accept
            code, out, s = proof(profile, state, "--skip 'Classes/*' --no-overrides")
            assert.equal(1, code, out)
            assert.is_true(s.errors >= 1, out)
            assert.is_truthy(out:find("[accept-exclusive]", 1, true), out)
            assert.is_truthy(out:find("id=h15-xr-arrive", 1, true), out)
        end)
    end)
end

---------------------------------------------------------------------------------------------------------------
-- The base profiles: every route with the class files left out, as the base-profile commands of the plan run
-- them (D.2 F2d, D.4 P2, appendix 2: `--skip 'Classes/*'`). Unlike a harness run this one includes the template
-- checks of tools/lib/module_checks.lua.
--
-- Known conflict (docs/dev/handover/F2b-shared-path.md, section 6, item 5): C.7 anchors the druid riding steps
-- of a race file on a step of the class file (`after = "dru-40-train"`, class = "DRUID"). With the class files
-- skipped that anchor is the id of no loaded step, and without --own the race file is own, so the validator
-- reports ERROR insert-anchor-unknown and the literal command exits 1. The decision is the orchestrator's (the
-- tool or the command line). This case holds in both outcomes: such an insert is reported exactly once, as an
-- ERROR or as a note, and NOTHING ELSE is: no other template check and no ERROR in any base route. When the
-- literal command is clean, tighten the middle assertion to "no ERROR".
-- --strict is left out on purpose: the WARNs of the base profiles belong to the phases that own the files.
---------------------------------------------------------------------------------------------------------------

if not PARTIAL then
    describe("the base profiles (validator, class files skipped)", function()
        it("have no ERROR; the template checks name only the race inserts anchored on a class step (C.7)", function()
            -- the inserts a base run cannot apply: registered outside Classes/, anchored on a step of a class file
            local full = Loader.LoadModule(GUIDES, { schema = Schema })
            local classStep, expected = {}, {}
            for _, ins in ipairs(full.libraryInserts) do
                if ins.file:find("^Classes/") then
                    for _, step in ipairs(ins.steps) do classStep[step.id] = ins.file end
                end
            end
            for _, ins in ipairs(full.libraryInserts) do
                if not ins.file:find("^Classes/") and classStep[ins.anchor] then
                    local where = ins.file .. ": insert " .. ins.side .. " '" .. ins.anchor .. "'"
                    assert.is_truthy(ins.file:find("^Races/"), where .. ": only a race file anchors on a class step")
                    assert.is_truthy(ins.scope and ins.scope.class, where .. " needs a class scope")
                    expected[#expected + 1] = ("%s %s %s"):format(ins.file, ins.steps[1].id, ins.anchor)
                end
            end
            table.sort(expected)

            local code, out = run(("lua5.1 tools/validate_routes.lua --overrides tools/overrides --end-level --summary "
                .. "--skip 'Classes/*' %s"):format(GUIDES))
            local reported, errors, routes = {}, 0, 0
            for line in out:gmatch("[^\n]+") do
                local kind = line:match("^%s+(ERROR)%s") or line:match("^%s+(note)%s")
                if kind then
                    assert.is_truthy(line:find("[insert-anchor-unknown]", 1, true), line)
                    local id, file = line:match("id=(%S+) %(([^)]+)%)")
                    local anchor = line:match("shared insert %a+ '([^']+)'")
                    assert.is_truthy(id and anchor, line)
                    reported[#reported + 1] = ("%s %s %s"):format(file, id, anchor)
                    if kind == "ERROR" then errors = errors + 1 end
                else
                    -- --summary: route, profile, errors, warnings, accepted, foreign, end level, worst end level, ...
                    local route, n, level, worst = line:match("^([%w-]+)\t[^\t]+\t(%d+)\t%d+\t%d+\t%d+\t([%d.]+)\t([%d.]+)\t")
                    if route then
                        routes = routes + 1
                        assert.equal("0", n, route .. ": ERROR in the base profile\n" .. out)
                        assert.equal("60.00", level, route)
                        assert.equal("60.00", worst, route .. " (worst case)")
                    end
                end
            end
            table.sort(reported)
            assert.same(expected, reported, out)
            assert.equal(#full.routes, routes, "one summary line per route\n" .. out)
            assert.equal(errors > 0 and 1 or 0, code, out)
        end)
    end)
end
