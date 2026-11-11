-- Layout of the guides module addons/FastesBoooy_Guides (docs/dev/PLAN.md A.1-A.4, C.1, C.2, D.2): the real
-- module is loaded through tools/lib/route_loader.lua and its registered content is checked against the
-- contracts the phases rely on:
--   * no load error; the routes are exactly the race x class combos of the start zones that have announced
--     themselves, restricted by `only`;
--   * Route.lua for all five races (the Durotar and Mulgore files replaced by the fixture start zones of
--     tests/fixtures/guides/FastesBoooy_StartZones): 28 routes with the ids, titles, races, classes, aliases and
--     segment chains of A.4;
--   * explicit step ids in the start zones and in the new and rewritten shared segments (a positional id can
--     never be an anchor); the Tirisfal and Zephras segments are class-neutral and no announcement carries `only`;
--   * the shared anchors of C.2 and the start-zone anchors of the F2c hand-overs: they exist, the race-filtered
--     alternatives (F) are filtered with the planned races, every other anchor is unfiltered (class and race files
--     anchor on them);
--   * scope and id prefix of every shared insert: class files, race files, start-zone files;
--   * no `reward` on a shared base step (class reward choices live in the class reward table);
--   * the faction word (docs/dev/PLAN.md 0.1 item 2): none in the TOC texts, route titles and descriptions and
--     segment titles; in step notes only where it names something of the game world;
--   * the level gates of 12-22 point at mobs of the player's level and stand where those mobs are; the races that
--     walk into Thunder Bluff pass the flight master once; the Russian notes of 12-22 use Russian names;
--   * the proofs for the races whose start zone is not written yet (D.2, F2b step 6): the shared path from
--     h-12-orgrimmar-tirisfal to level 60 from synthetic hand-over states, in the validator harness;
--   * the base profiles (the validator on the module with --skip 'Classes/*', not the harness): no route has an
--     ERROR and the template checks report nothing; no insert outside Classes/ is anchored on a step of a class file.
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
    -- Tirisfal (docs/dev/handover/f2c-tirisfal.md, section 3): the C.2 anchors, then the further steps the
    -- paladin file is anchored on
    ["ud-01-deathknell"] = {
        "ud01-364", "ud01-church-4", "ud01-381", "ud01-382",
        "ud01-aramis", "ud01-boxes", "ud01-98389",
    },
    ["ud-02-tirisfal"] = {
        "ud02-sethearth", "ud02-brill-8", "ud02-level-10", "ud02-keep", "ud02-lvl-12", "ud02-hearth-2", "ud02-fp-uc",
        "ud02-silverpine-road",
        "ud02-dillinger-report", "ud02-shari-99144", "ud02-leonid-letter", "ud02-hilda", "ud02-ephram",
        "ud02-elixir-bg", "ud02-shadowvale", "ud02-hilda-2", "ud02-carolai-2",
    },
    -- Zephras (docs/dev/handover/f2c-zephras.md, section 4): the C.2 anchors and the six the druid file adds
    ["sd-01-zephras"] = {
        "sd01-rorian", "sd01-thendal-4", "sd01-innkeeper", "sd01-shendar-8",
        "sd01-rorian-4", "sd01-raan-2", "sd01-danarii-2",
    },
    ["sd-02-zephras"] = {
        "sd02-level-10", "sd02-valanaar-10", "sd02-hearth", "sd02-plateau", "sd02-end",
        "sd02-endaria", "sd02-fendaal-2", "sd02-lotheluum-2",
    },
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
    ["h-37-desolace-dustwallow"] = { "h-40-org-arrive", "h-38-orgrimmar-flight-master" },
    ["h-41-arathi-badlands"] = { "h-41-uc-arrive" },
    ["h-50-hinterlands-searing-steppes"] = { "h50-owen-thadd" },
}

-- Segments in which every step has an explicit id (A.3: the start zones and the new and rewritten shared
-- segments; h-22-hillsbrad: B.7). These must exist; a segment that is registered later (Durotar, Mulgore) is held
-- to the same rule by POSITIONAL_ALLOWED: only the eleven segments below may still hold positional ids.
local EXPLICIT_IDS = {
    "ud-01-deathknell", "ud-02-tirisfal", "sd-01-zephras", "sd-02-zephras", "sd-03-thunder-bluff",
    "h-12-orgrimmar-tirisfal", "h-13-silverpine", "h-15-barrens", "h-18-stonetalon-ashenvale", "h-22-hillsbrad",
}
local POSITIONAL_ALLOWED = {}
for i = 2, #SHARED_22_60 do POSITIONAL_ALLOWED[SHARED_22_60[i]] = true end -- h-24 .. h-56

-- Level gates of the shared path 12-22 (B.8): plain `level` steps.
local GATES = { "h13-lvl-12", "h13-lvl-14", "h18-lvl-18", "h18-lvl-20", "h18-lvl-21", "h18-lvl-22" }
-- Level gates of the class-neutral start zones (B.8; the F2c hand-overs): plain, mandatory, unfiltered too.
local START_GATES = {
    "ud01-xp-4", "ud02-lvl-6", "ud02-level-10", "ud02-lvl-12",
    "sd01-level-2", "sd01-level-3", "sd01-level-4", "sd02-level-10",
}

-- The start zones that are class-neutral (rewritten in F2c): no step of their segments carries a class or race
-- filter, a `train` action or a `reward`. Durotar is not in the list on purpose: the game itself branches by
-- class there (792 against the warlock's 1485 -> 1499: a pair of class-filtered base steps, R4).
local CLASS_NEUTRAL_ZONES = { "Tirisfal", "Zephras" }

-- 98389 "A Light in the Darkness" starts and ends at the paladin trainer of Deathknell; the DB gives it no class.
-- Until it is confirmed in game (docs/dev/PLAN.md E.6) its three steps are optional and share no step with a
-- mandatory action, so a class that is not offered the quest is never held.
local OPTIONAL_QUEST = { quest = 98389, segment = "ud-01-deathknell", steps = { "ud01-aramis", "ud01-cocoons", "ud01-98389" } }

---------------------------------------------------------------------------------------------------------------
-- the faction word (docs/dev/PLAN.md 0.1 item 2, D.2 F2d step 2)
---------------------------------------------------------------------------------------------------------------

-- Steps whose note may say "Horde" / "Орда": the word names a place or a thing of the game world there, not the
-- guide. A note that names a quest, an NPC or an object of the DB snapshot with "Horde" in its name ("Conscript
-- of the Horde", "Horde Supply Crate", "Fallen Hero of the Horde") needs no entry: the name is recognized in the
-- English note, and the Russian note of the same step may then translate it.
local FACTION_WORD_STEPS = {
    ["h44-deadwind-road"] = "the Horde camp of Apothecary Faustin at the Deadwind Pass road",
    ["h48-whitereach"] = "Whitereach Post (Horde): the Alliance has its own post in Thousand Needles",
    ["h50-honey-ripples"] = "Horde Supply Crates (object name)",
    ["h-51-swamp-of-sorrows"] = "Fallen Hero of the Horde (NPC name)",
    ["h-53-azshara-arrive"] = "Valormok, the Horde camp of Azshara",
}

local CYRILLIC_LEAD = { ["\208"] = true, ["\209"] = true }

--- Lower case of a UTF-8 text: ASCII and the Russian alphabet. Every letter keeps its two bytes, so a position
-- in the result is the same position in the text.
local function lowerRu(text)
    return (text:lower():gsub("\208([\129\144-\175])", function(c)
        local b = c:byte()
        if b == 129 then return "\209\145" end                      -- Ё
        if b <= 159 then return "\208" .. string.char(b + 32) end   -- А .. П
        return "\209" .. string.char(b - 32)                        -- Р .. Я
    end))
end

-- the case endings of "орда" (singular, then plural), the longer ones first; "" is the genitive plural "орд"
local FACTION_ENDINGS = { "ами", "ой", "ою", "ам", "ах", "а", "ы", "е", "у", "" }

--- The faction word in a text, in any letter case: "Horde" (also inside "Hordes"); a case form of "Орда" as a
-- word of its own ("Ордена", "рекорды", "лорда", "мордой" are not one); the adjective and the noun made from it
-- ("ордынский", "ордынцы"). Returns the form as the text spells it. The common noun is the same word and is
-- found too ("a horde of ghouls", "орды нежити"): a note says "a pack", "толпы" instead.
local function factionWord(text)
    if type(text) ~= "string" then return nil end
    local low = lowerRu(text)
    local a, b = low:find("horde", 1, true)
    if a then return text:sub(a, b) end
    local from = 1
    while true do
        a, b = low:find("орд", from, true)
        if not a then return nil end
        -- a word of its own: no Cyrillic letter in front of it (a letter is a lead byte and one more byte)
        if a < 3 or not CYRILLIC_LEAD[low:sub(a - 2, a - 2)] then
            if low:sub(b + 1, b + 4) == "ын" then return text:sub(a, b + 4) end
            for _, ending in ipairs(FACTION_ENDINGS) do
                local last = b + #ending
                if low:sub(b + 1, last) == ending and not CYRILLIC_LEAD[low:sub(last + 1, last + 1)] then
                    return text:sub(a, last)
                end
            end
        end
        from = b + 1
    end
end

--- Words with which a note would describe the module instead of the game (A.1: user-visible text never calls
-- the common path "shared" or a "library").
local function moduleWord(text)
    if type(text) ~= "string" then return nil end
    for _, word in ipairs({ "shared", "Shared", "общий путь", "общего пути", "общем пути", "общий маршрут",
        "общего маршрута", "общем маршруте" }) do
        if text:find(word, 1, true) then return word end
    end
    return nil
end

--- { ru = , en = } of a localized field (a plain string counts for both languages).
local function texts(value)
    if type(value) == "table" then return value end
    if type(value) == "string" then return { ru = value, en = value } end
    return {}
end

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
        it("registers exactly the race x class combos of the announced start zones; no zone carries `only`", function()
            local ann = announcements(mod.tocFiles, skipped)
            for zone, a in pairs(ann) do
                assert.is_truthy(ZONES[zone], "unknown start zone " .. zone)
                assert.same(ZONES[zone].segments, a.segments, zone .. " announces its segments in order")
                -- `only` was the switch of the migration (one class per zone until the zone was class-neutral);
                -- a zone announces itself when all classes of its races can walk it
                assert.is_nil(a.only, zone .. ": the announcement still restricts the classes with `only`")
            end
            assert.is_truthy(ann.Tirisfal, "Tirisfal has not announced itself")
            assert.is_truthy(ann.Zephras, "Zephras has not announced itself")
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
            }) do
                -- a zone that is written is taken as it is: only the placeholders are replaced by the fixture
                if not announcements(mod.tocFiles, skipped)[rel:match("^Segments/(%w+)/")] then
                    replace[rel] = FIXTURE_ZONES .. "/" .. rel
                    assert.is_true(Loader.fileExists(replace[rel]), replace[rel])
                end
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

    it("gives every step of the start zones and of the new and rewritten segments an explicit id", function()
        for _, id in ipairs(EXPLICIT_IDS) do
            assert.is_true(segments[id] ~= nil or PARTIAL, "segment " .. id .. " is not registered")
            assert.is_nil(POSITIONAL_ALLOWED[id], id)
        end
        -- every registered segment but h-24 .. h-56: the listed ones, and the start zones that are written later
        local checked = 0
        for _, seg in ipairs(mod.librarySegments) do
            if own(seg.file) and not POSITIONAL_ALLOWED[seg.id] then
                checked = checked + 1
                assert.is_true(#seg.steps > 0, seg.id)
                for _, step in ipairs(seg.steps) do
                    assert.is_nil(step.autoId,
                        ("%s: step %d has the positional id %s"):format(seg.id, step.segIndex, step.id))
                end
            end
        end
        assert.is_true(checked > 0 or PARTIAL)
    end)

    it("keeps the Tirisfal and Zephras segments class-neutral", function()
        -- every class step lives in Classes/<Class>.lua (C.1); the race walks its start zone alone, so a race
        -- filter has no use there either
        local checked = 0
        for _, zone in ipairs(CLASS_NEUTRAL_ZONES) do
            for _, segId in ipairs(ZONES[zone].segments) do
                local seg = segments[segId]
                assert.is_true(seg ~= nil or PARTIAL, "segment " .. segId .. " is not registered")
                if seg and own(seg.file) then
                    checked = checked + 1
                    for _, step in ipairs(seg.steps) do
                        assert.is_nil(step.filters, step.id .. " carries a class or race filter")
                        assert.is_nil(step.reward, step.id .. " carries a reward choice")
                        for _, a in ipairs(step.actions) do
                            assert.is_true(a.type ~= "train", step.id .. ": training is a class step")
                        end
                    end
                end
            end
        end
        assert.is_true(checked > 0 or PARTIAL)
    end)

    it("keeps the three steps of 98389 optional and apart from every mandatory action (E.6)", function()
        local seg = segments[OPTIONAL_QUEST.segment]
        assert.is_true(seg ~= nil or PARTIAL)
        if seg and own(seg.file) then
            local found = {}
            for _, step in ipairs(seg.steps) do
                for _, a in ipairs(step.actions) do
                    if a.quest == OPTIONAL_QUEST.quest then
                        found[#found + 1] = step.id
                        assert.is_true(step.optional, step.id .. " names 98389 and must be optional")
                        for _, other in ipairs(step.actions) do
                            assert.equal(OPTIONAL_QUEST.quest, other.quest,
                                step.id .. ": an action of another quest shares the step with 98389")
                        end
                        break
                    end
                end
            end
            assert.same(OPTIONAL_QUEST.steps, found)
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

    it("keeps the level gates of the start zones and of 12-22 plain `level` steps", function()
        for _, list in ipairs({ START_GATES, GATES }) do
            for _, id in ipairs(list) do
                local step = stepById[id]
                assert.is_true(step ~= nil or PARTIAL, "gate " .. id .. " is missing")
                if step and own(step.file) then
                    assert.equal(1, #step.actions, id)
                    assert.equal("level", step.actions[1].type, id)
                    assert.is_nil(step.optional, id)
                    assert.is_nil(step.filters, id)
                end
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

    it("keeps the level-40 contract of the druid file and the riding steps of the race files (C.7)", function()
        -- The druid's level-40 block is three steps with fixed ids: fly to Thunder Bluff and train (an insert
        -- after h-40-org-arrive), then the flight on (an insert of its own before the next shared step). The
        -- riding steps of a druid's race are an insert after h-40-org-arrive too, registered by the race file,
        -- which the TOC lists after the class files: so they land between dru-40-train and dru-40-fly-taurajo.
        -- Their anchor is the shared step and not dru-40-train: an anchor inside a class file is the id of no
        -- loaded step when the class files are skipped (the base profiles, last block of this file).
        local ARRIVE, NEXT = "h-40-org-arrive", "h-38-orgrimmar-flight-master"
        local dru, druNext, riding = {}, {}, {}
        for _, ins in ipairs(mod.libraryInserts) do
            if ins.file == "Classes/Druid.lua" then
                if ins.anchor == ARRIVE and ins.side == "after" then
                    for _, id in ipairs(ids(ins.steps)) do dru[#dru + 1] = id end
                elseif ins.anchor == NEXT and ins.side == "before" then
                    for _, id in ipairs(ids(ins.steps)) do druNext[#druNext + 1] = id end
                end
            elseif ins.file:find("^Races/") and ins.anchor == ARRIVE and ins.scope and ins.scope.class
                and ins.scope.class.DRUID then
                assert.equal("after", ins.side, ins.file)
                assert.same({ "DRUID" }, sortedKeys(ins.scope.class), ins.file)
                riding[ins.file] = ids(ins.steps)
                for _, step in ipairs(ins.steps) do
                    assert.is_true(step.optional, step.id .. " is optional (riding)")
                    assert.is_truthy(step.id:find("^%l+%-40d%-"), step.id .. ": <race prefix>-40d-...")
                end
            end
        end
        local segFile = segments["h-37-desolace-dustwallow"]
        if segFile and own(segFile.file) then
            assert.equal(stepById[ARRIVE].segIndex + 1, stepById[NEXT].segIndex, NEXT .. " follows " .. ARRIVE)
        end
        if own("Classes/Druid.lua") and not skipped["Classes/Druid.lua"] then
            assert.same({ "dru-40-fly-tb", "dru-40-train" }, dru)
            assert.same({ "dru-40-fly-taurajo" }, druNext)
        end
        if own("Races/Skyborne.lua") and not skipped["Races/Skyborne.lua"] then
            assert.is_truthy(riding["Races/Skyborne.lua"], "the Skyborne druid riding insert after " .. ARRIVE)
        end
        -- the composed order, in every druid route of a race with such an insert
        if not PARTIAL then
            local seen = 0
            for _, r in ipairs(mod.routes) do
                local raceFile = "Races/" .. sortedKeys(r.races)[1] .. ".lua"
                if r.classes.DRUID and riding[raceFile] then
                    seen = seen + 1
                    local want = { ARRIVE, "dru-40-fly-tb", "dru-40-train" }
                    for _, id in ipairs(riding[raceFile]) do want[#want + 1] = id end
                    want[#want + 1] = "dru-40-fly-taurajo"
                    want[#want + 1] = NEXT
                    local at
                    for i, step in ipairs(r.steps) do
                        if step.id == ARRIVE then at = i break end
                    end
                    assert.is_truthy(at, r.id)
                    local got = {}
                    for i = at, at + #want - 1 do got[#got + 1] = r.steps[i] and r.steps[i].id end
                    assert.same(want, got, r.id)
                end
            end
            assert.is_true(seen > 0, "no druid route with riding steps of its race")
        end
    end)

    it("anchors no insert of a segment or race file on a step of a class file", function()
        -- such an anchor does not exist in a base-profile run (--skip 'Classes/*'): ERROR insert-anchor-unknown.
        -- Needs the class files: checked on the whole module only.
        if PARTIAL then return end
        local classStep = {}
        for _, ins in ipairs(mod.libraryInserts) do
            if ins.file:find("^Classes/") then
                for _, step in ipairs(ins.steps) do classStep[step.id] = ins.file end
            end
        end
        for _, ins in ipairs(mod.libraryInserts) do
            if not ins.file:find("^Classes/") then
                assert.is_nil(classStep[ins.anchor], ("%s: insert %s '%s' is anchored on a step of %s"):format(
                    ins.file, ins.side, ins.anchor, tostring(classStep[ins.anchor])))
            end
        end
    end)

    it("carries no `reward` on a shared base step", function()
        local checked = 0
        for _, seg in ipairs(mod.librarySegments) do
            if own(seg.file) then
                checked = checked + 1
                for _, step in ipairs(seg.steps) do
                    assert.is_nil(step.reward, step.id .. " (" .. seg.file .. ")")
                end
            end
        end
        assert.is_true(checked > 0 or PARTIAL)
    end)

    describe("the faction word", function()
        -- docs/dev/PLAN.md 0.1 item 2: no "Horde" / "Орда" in addon names, TOC texts, route titles and
        -- descriptions, segment titles, and in notes that describe the guide, the route or the module. Uses for
        -- the game world stay: FACTION_WORD_STEPS, and names of the DB snapshot.
        local inWorldNames

        -- the note of a step may carry the word: listed by id, or its English text names a quest, an NPC or an
        -- object of the snapshot with "Horde" in its name
        local function inWorld(step)
            if FACTION_WORD_STEPS[step.id] then return true end
            if not inWorldNames then
                inWorldNames = {}
                local db = DB.Load("tools/data/forever_db.lua")
                for _, kind in ipairs({ "quests", "npcs", "objects", "items" }) do
                    for _, rec in pairs(db[kind] or {}) do
                        if type(rec) == "table" and type(rec.name) == "string" and rec.name:find("Horde", 1, true)
                            and not rec.name:find("^%[") then
                            inWorldNames[#inWorldNames + 1] = rec.name
                        end
                    end
                end
            end
            local en = texts(step.note).en
            if type(en) ~= "string" then return false end
            for _, name in ipairs(inWorldNames) do
                if en:find(name, 1, true) then return true end
            end
            return false
        end

        local function stepTexts(step)
            local out = {}
            for _, value in ipairs({ step.note, step.title }) do
                local t = texts(value)
                out[#out + 1] = t.ru
                out[#out + 1] = t.en
            end
            for _, spell in ipairs(step.spells or {}) do
                local t = texts(spell)
                out[#out + 1] = t.ru
                out[#out + 1] = t.en
            end
            return out
        end

        local function eachStep(fn)
            local n = 0
            for _, seg in ipairs(mod.librarySegments) do
                if own(seg.file) then
                    for _, step in ipairs(seg.steps) do
                        n = n + 1
                        fn(step, seg.file)
                    end
                end
            end
            for _, ins in ipairs(mod.libraryInserts) do
                if own(ins.file) then
                    for _, step in ipairs(ins.steps) do
                        n = n + 1
                        fn(step, ins.file)
                    end
                end
            end
            return n
        end

        it("recognizes the word and its Russian case forms, and nothing else", function()
            assert.equal("Horde", factionWord("the shared Horde route"))
            assert.equal("Орды", factionWord("общий маршрут Орды."))
            assert.equal("Орда", factionWord("Орда"))
            assert.equal("Орде", factionWord("по всей Орде, и дальше"))
            assert.equal("Ордой", factionWord("за Ордой"))
            assert.is_nil(factionWord("Лагерь Алого ордена, Орден Серебряного Рассвета, Ордена"))
            assert.is_nil(factionWord("хранитель Гордан, Руины Лордерона, Гордунни"))
            assert.is_nil(factionWord(nil))
        end)

        it("recognizes the word in any letter case, in the plural and as an adjective", function()
            -- the four forms a guard for capitalised words only would let through
            assert.equal("орды", factionWord("Маршрут орды."))
            assert.equal("ОРДЫ", factionWord("МАРШРУТ ОРДЫ."))
            assert.equal("Ордын", factionWord("Ордынский маршрут."))
            assert.equal("horde", factionWord("The horde route:"))
            assert.equal("HORDE", factionWord("THE HORDE ROUTE"))
            assert.equal("Horde", factionWord("both Hordes"))
            assert.equal("ордын", factionWord("лагерь ордынцев"))
            assert.equal("ОРДЫН", factionWord("ОРДЫНСКИЙ лагерь"))
            assert.equal("орда", factionWord("орда"))
            assert.equal("ордою", factionWord("за ордою"))
            assert.equal("Ордам", factionWord("Ордам"))
            assert.equal("ордами", factionWord("между ордами"))
            assert.equal("ордах", factionWord("(в ордах)"))
            assert.equal("орд", factionWord("войска двух орд."))
            assert.equal("Орде", factionWord("Лорд верен Орде"))
            -- other words with the same letters, in any case
            assert.is_nil(factionWord("рекорды, аккорд, лорда, Лорда, мордой, бордовый, гордый, координаты"))
            assert.is_nil(factionWord("ордена, орден, ордер, ОРДЕНА, ГОРДАН, РУИНЫ ЛОРДЕРОНА"))
            assert.is_nil(factionWord("Ордос, ордината"))
            assert.is_nil(factionWord("chord, order, hoard, border, Horadric"))
            assert.is_nil(factionWord(""))
        end)

        it("lowers Russian text letter by letter and keeps the byte positions", function()
            assert.equal("абвгдеёжзийклмнопрстуфхцчшщъыьэюя", lowerRu("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"))
            assert.equal("абвгдеёжзийклмнопрстуфхцчшщъыьэюя", lowerRu("абвгдеёжзийклмнопрстуфхцчшщъыьэюя"))
            assert.equal("ok — 12 «орда», thunder bluff", lowerRu("OK — 12 «Орда», Thunder Bluff"))
            assert.equal(#"Маршрут ОРДЫ — Horde", #lowerRu("Маршрут ОРДЫ — Horde"))
        end)

        if not PARTIAL then
            it("is not in the TOC texts", function()
                local toc = assert(Loader.readFile(GUIDES .. "/FastesBoooy_Guides.toc"))
                local lines = 0
                for line in toc:gmatch("[^\r\n]+") do
                    if line:find("^##") then
                        lines = lines + 1
                        assert.is_nil(factionWord(line), line)
                        for _, word in ipairs({ "library", "Library", "shared", "Shared", "библиотек", "общий" }) do
                            assert.is_nil(line:find(word, 1, true), line)
                        end
                    end
                end
                assert.is_true(lines >= 4, "## Title, ## Notes, ## Notes-ruRU, ...")
                for _, r in ipairs(mod.routes) do
                    for _, text in ipairs({ r.title.ru, r.title.en, r.description.ru, r.description.en }) do
                        assert.is_nil(factionWord(text), r.id .. ": " .. text)
                    end
                end
            end)

            it("lists only steps that exist and still carry the word", function()
                for id, why in pairs(FACTION_WORD_STEPS) do
                    local step = stepById[id]
                    assert.is_truthy(step, "FACTION_WORD_STEPS: no step " .. id .. " (" .. why .. ")")
                    local word
                    for _, text in ipairs(stepTexts(step)) do word = word or factionWord(text) end
                    assert.is_truthy(word, "FACTION_WORD_STEPS: the note of " .. id .. " no longer has the word: drop the entry")
                end
            end)
        end

        it("is in no segment title", function()
            local checked = 0
            for _, seg in ipairs(mod.librarySegments) do
                if own(seg.file) then
                    checked = checked + 1
                    local t = texts(seg.title)
                    for _, text in ipairs({ t.ru, t.en }) do
                        assert.is_nil(factionWord(text), seg.id .. ": " .. tostring(text))
                        assert.is_nil(moduleWord(text), seg.id .. ": " .. tostring(text))
                        for _, word in ipairs({ "library", "Library", "библиотек" }) do
                            assert.is_nil(text:find(word, 1, true), seg.id .. ": " .. text)
                        end
                    end
                end
            end
            assert.is_true(checked > 0 or PARTIAL)
        end)

        it("is in a step note only for something of the game world", function()
            local n = eachStep(function(step, file)
                for _, text in ipairs(stepTexts(step)) do
                    local word = factionWord(text)
                    if word and not inWorld(step) then
                        error(("%s (%s): '%s' in a note. If the note describes the guide or the route, reword it (no "
                            .. "faction word: docs/dev/PLAN.md 0.1). If it names a place or a thing of the game world, the "
                            .. "step id belongs in FACTION_WORD_STEPS of this spec (report it to the owner of the spec). "
                            .. "The check ignores the letter case: the common noun ('a horde of ghouls') takes another "
                            .. "word ('a pack'). Text: %s"):format(step.id, file, word, text))
                    end
                end
            end)
            assert.is_true(n > 0 or PARTIAL)
        end)

        it("does not let a note call the common path 'shared'", function()
            eachStep(function(step, file)
                for _, text in ipairs(stepTexts(step)) do
                    local word = moduleWord(text)
                    assert.is_nil(word, ("%s (%s): '%s' describes the module, not the game: %s"):format(
                        step.id, file, tostring(word), text))
                end
            end)
        end)
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
-- History (docs/dev/handover/F2b-shared-path.md, section 6, item 5; F2d hand-over): C.7 anchored the druid
-- riding steps of a race file on a step of the class file (`after = "dru-40-train"`). With the class files
-- skipped that anchor is the id of no loaded step and the literal command exited 1 with ERROR
-- insert-anchor-unknown. Since F2d the race insert is anchored on the shared step h-40-org-arrive (the case "keeps
-- the level-40 contract ..." above pins the order), so the run must be clean: no ERROR in the shared content or
-- in a base route, no note, exit status 0.
-- --strict is left out on purpose: an unaccepted WARN of a base profile fails `make validate` and the phase gates
-- (they name the step); this case is about ERRORs and the template checks.
---------------------------------------------------------------------------------------------------------------

if not PARTIAL then
    describe("the base profiles (validator, class files skipped)", function()
        it("have no ERROR and no template finding; every base route reaches level 60", function()
            local full = Loader.LoadModule(GUIDES, { schema = Schema })
            local code, out = run(("lua5.1 tools/validate_routes.lua --overrides tools/overrides --end-level --summary "
                .. "--skip 'Classes/*' %s"):format(GUIDES))
            local routes = 0
            for line in out:gmatch("[^\n]+") do
                assert.is_nil(line:match("^%s+ERROR%s"), line)
                assert.is_nil(line:match("^%s+note%s"), line)
                -- --summary: route, profile, errors, warnings, accepted, foreign, end level, worst end level, ...
                local route, n, level, worst = line:match("^([%w-]+)\t[^\t]+\t(%d+)\t%d+\t%d+\t%d+\t([%d.]+)\t([%d.]+)\t")
                if route then
                    routes = routes + 1
                    assert.equal("0", n, route .. ": ERROR in the base profile\n" .. out)
                    assert.equal("60.00", level, route)
                    assert.equal("60.00", worst, route .. " (worst case)")
                end
            end
            assert.equal(#full.routes, routes, "one summary line per route\n" .. out)
            assert.equal(0, code, out)
        end)
    end)
end
