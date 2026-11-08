-- Validator checks added with the 22-60 review, on in-memory routes over real Forever data:
--   * WARN lookahead-skip: a trainer / merchant / innkeeper / flight-master visit followed, within
--     the automation's lookahead, by a step that only accepts / turns in quests at the same NPC
--     (the gossip auto-accept finishes that step first and fast-forwards the visit);
--   * WARN quest-profession: accepting a quest that needs a profession (DB reqSkill) in a required
--     step, or completing / turning in such a quest in a required step after an optional accept;
--   * WARN complete-far-from-trigger: the `complete` step of an area-trigger quest (exploration) does
--     not lead to the trigger (escorts and an earlier step at the trigger are fine);
--   * the snapshot data they use: Wowhead Forever objective counts, triggers, escorts, professions.

local DB = require("lib.fbdb")
local Loader = require("lib.route_loader")
local V = require("lib.validator")

local db, schema

local UNDEAD_PALADIN = { api = 1, id = "mem", title = "mem", faction = "Horde", races = { "Scourge" },
    classes = { "PALADIN" }, levels = { 1, 30 } }

local function run(steps, state)
    local r = assert(schema.NormalizeRoute(UNDEAD_PALADIN))
    local _, errs = schema.AddSegment(r, { id = "s", title = "s", levels = { 1, 30 }, steps = steps })
    assert.are.same({}, errs)
    return V.NewRun(db, schema, r, V.Profiles(r)[1], { startState = state }):execute()
end

local function codeSteps(result, code, severity)
    local out = {}
    for _, m in ipairs(result.messages) do
        if m.code == code and (not severity or m.severity == severity) then out[#out + 1] = m.step end
    end
    return out
end

local function firstMsg(result, code)
    for _, m in ipairs(result.messages) do
        if m.code == code then return m end
    end
    return nil
end

-- Deathknell: Aramis Hammerhand 244808 (Paladin Trainer) also starts 90902 (preSingle 364)
local AT_ARAMIS = { 1420, 31.1, 66.4 }
local DEATHKNELL = { level = 3, xpFrac = 0, done = { 363, 364 }, log = {}, flightPaths = {} }
-- Crossroads: Grub 3443 (vendor) starts 862 Dig Rat Stew (Cooking 15)
local AT_GRUB = { 1413, 55.3, 31.8 }
local CROSSROADS = { level = 16, xpFrac = 0, done = {}, log = {}, flightPaths = {} }

describe("validator checks", function()
    setup(function()
        db = DB.Load("tools/data/forever_db.lua")
        schema = Loader.LoadSchema(".")
    end)

    describe("lookahead-skip", function()
        local function gos(n)
            local out = {}
            for k = 1, n do out[k] = { go = true, at = { 1420, 31.0 + k * 0.1, 65.0 } } end
            return out
        end

        it("warns at a train step followed by an accept at the same NPC within the lookahead", function()
            local r = run({
                { train = true, npc = 244808, at = AT_ARAMIS },
                { go = true, at = { 1420, 31.5, 65.0 } },
                { accept = 90902, npc = 244808, at = AT_ARAMIS },
            }, DEATHKNELL)
            assert.are.same({ 1 }, codeSteps(r, "lookahead-skip", "WARN"))
            local m = firstMsg(r, "lookahead-skip")
            assert.matches("train step [train] at NPC 244808 \"Aramis Hammerhand\" can be fast-forwarded", m.msg, 1,
                true)
            assert.matches("accepts 90902 \"Rediscovering the Light\" there (step s#3 [accept 90902], 2 step(s) later",
                m.msg, 1, true)
        end)

        it("vendor visits count too (merchant + quest giver)", function()
            local r = run({
                { vendor = true, npc = 3443, at = AT_GRUB },
                { accept = 862, npc = 3443, at = AT_GRUB, optional = true },
            }, CROSSROADS)
            assert.are.same({ 1 }, codeSteps(r, "lookahead-skip", "WARN"))
        end)

        it("no warning when merged, beyond the lookahead, at another NPC, or the later step does more", function()
            -- merged into one step: the step itself is the anchor, its train action is still observed
            assert.are.same({}, codeSteps(run({
                { train = true, accept = 90902, npc = 244808, at = AT_ARAMIS },
            }, DEATHKNELL), "lookahead-skip"))
            -- 7 steps later: outside the auto-accept window (cursor + 6)
            local far = { { train = true, npc = 244808, at = AT_ARAMIS } }
            for _, s in ipairs(gos(6)) do far[#far + 1] = s end
            far[#far + 1] = { accept = 90902, npc = 244808, at = AT_ARAMIS }
            assert.are.same({}, codeSteps(run(far, DEATHKNELL), "lookahead-skip"))
            -- the later step also needs an action the NPC cannot finish (an objective)
            assert.are.same({}, codeSteps(run({
                { train = true, npc = 244808, at = AT_ARAMIS },
                { accept = 90902, complete = 90902, npc = 244808, at = AT_ARAMIS },
            }, DEATHKNELL), "lookahead-skip"))
            -- an optional visit is fast-forwarded by design
            assert.are.same({}, codeSteps(run({
                { train = true, npc = 244808, at = AT_ARAMIS, optional = true },
                { accept = 90902, npc = 244808, at = AT_ARAMIS },
            }, DEATHKNELL), "lookahead-skip"))
        end)

        it("a turn-in counts only when the quest is complete at the visit", function()
            local state = { level = 3, xpFrac = 0, done = { 363, 364 }, log = { 90902 }, complete = { 90902 },
                flightPaths = {} }
            assert.are.same({ 1 }, codeSteps(run({
                { train = true, npc = 244808, at = AT_ARAMIS },
                { turnin = 90902, npc = 244808, at = AT_ARAMIS },
            }, state), "lookahead-skip"))
            local open = { level = 3, xpFrac = 0, done = { 363, 364 }, log = { 90902 }, flightPaths = {} }
            assert.are.same({}, codeSteps(run({
                { train = true, npc = 244808, at = AT_ARAMIS },
                { complete = 90902, at = { 1420, 32.0, 65.0 } },
                { turnin = 90902, npc = 244808, at = AT_ARAMIS },
            }, open), "lookahead-skip"))
        end)

        it("an accept counts only when the quest is offered at the visit (prerequisite not turned in between)", function()
            -- 90902 needs 364: turned in between the visit and the accept
            local state = { level = 3, xpFrac = 0, done = { 363 }, log = { 364 }, complete = { 364 }, flightPaths = {} }
            assert.are.same({}, codeSteps(run({
                { train = true, npc = 244808, at = AT_ARAMIS },
                { turnin = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
                { accept = 90902, npc = 244808, at = AT_ARAMIS },
            }, state), "lookahead-skip"))
        end)
    end)

    describe("quest-profession", function()
        it("warns when a required step accepts a quest that needs a profession", function()
            local r = run({ { accept = 862, npc = 3443, at = AT_GRUB } }, CROSSROADS)
            assert.are.same({ 1 }, codeSteps(r, "quest-profession", "WARN"))
            assert.matches("accept 862 \"Dig Rat Stew\": requires Cooking 15 (profession)",
                firstMsg(r, "quest-profession").msg, 1, true)
        end)

        it("an optional accept is INFO; its required complete / turnin steps are WARN", function()
            local r = run({
                { accept = 862, npc = 3443, at = AT_GRUB, optional = true },
                { complete = 862, at = { 1413, 50.0, 40.0 } },
                { turnin = 862, npc = 3443, at = AT_GRUB, optional = true },
            }, CROSSROADS)
            assert.are.same({ 1 }, codeSteps(r, "quest-profession", "INFO"))
            assert.are.same({ 2 }, codeSteps(r, "quest-profession", "WARN"))
        end)
    end)

    describe("complete-far-from-trigger", function()
        local BARRENS = { level = 12, xpFrac = 0, done = {}, log = {}, flightPaths = {} }
        local AT_TONGA = { 1413, 52.26, 31.93 }

        it("warns when the complete step of an exploration quest is far from its area trigger", function()
            local r = run({
                { accept = 870, npc = 3448, at = AT_TONGA },
                { complete = 870, at = { 1413, 50.0, 30.0 } },
                { turnin = 870, npc = 3448, at = AT_TONGA },
            }, BARRENS)
            assert.are.same({ 2 }, codeSteps(r, "complete-far-from-trigger", "WARN"))
            assert.matches("area trigger {1413, 45.06, 22.53}", firstMsg(r, "complete-far-from-trigger").msg, 1, true)
        end)

        it("no warning at the trigger, after a step to the trigger, or for an escort", function()
            assert.are.same({}, codeSteps(run({
                { accept = 870, npc = 3448, at = AT_TONGA },
                { complete = 870, at = { 1413, 45.1, 22.6 } },
                { turnin = 870, npc = 3448, at = AT_TONGA },
            }, BARRENS), "complete-far-from-trigger"))
            assert.are.same({}, codeSteps(run({
                { accept = 870, npc = 3448, at = AT_TONGA },
                { go = true, at = { 1413, 45.0, 22.5 } },
                { complete = 870, turnin = 870, npc = 3448, at = AT_TONGA },
            }, BARRENS), "complete-far-from-trigger"))
            -- 6523 Protect Kaya: an escort (starts at Kaya, ends at the trigger)
            assert.are.same({}, codeSteps(run({
                { accept = 6523, npc = 11856, at = { 1442, 73.48, 85.59 } },
                { complete = 6523, at = { 1442, 73.5, 85.6 } },
            }, { level = 16, xpFrac = 0, done = {}, log = {}, flightPaths = {} }), "complete-far-from-trigger"))
        end)
    end)

    describe("snapshot data", function()
        it("objective counts come from the Wowhead Forever requirements", function()
            local c = db.meta.counts
            assert.is_true(c["objectiveCounts.wowhead"] > 2000)
            assert.is_true(c["objectiveCounts.wowheadChanged"] > 0)
            assert.are.same({ { 2335, 1 }, { 2387, 5 } }, db.quests[532].objectives.creatures)  -- Classic-era 4
            assert.are.same({ { 2358, 6 }, { 2359, 8 } }, db.quests[545].objectives.creatures)  -- Classic-era 12
            assert.are.same({ { 273181, 3 } }, db.quests[96260].objectives.items)              -- Forever-new
            assert.are.same({ { 268622, 2 }, { 268623, 1 } }, db.quests[97250].objectives.creatures)
            assert.are.same({ { 4100, 5 }, { 4101, 5 }, { 4104, 5 } }, db.quests[98070].objectives.creatures)
        end)

        it("area triggers, escorts and profession names", function()
            assert.are.same({ [1441] = { { 26.43, 32.93 } } }, db.quests[1149].objectives.trigger)
            assert.is_nil(db.quests[1149].objectives.escort)
            assert.is_true(db.quests[6523].objectives.escort)
            assert.are.same({ 185, 15 }, db.quests[862].reqSkill)
            assert.are.equal("Cooking", DB.SkillName(db, 185))
            assert.are.equal("First Aid", DB.SkillName(db, 129))
        end)
    end)
end)
