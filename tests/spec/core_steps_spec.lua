-- Completion semantics of every action type (ns.Steps:IsActionDone / IsStepDone) and
-- the step descriptions for the UI (ns.Steps:Describe), on the strict mock.

local H = require("fixtures.core.helpers")

local m, ns

local function S() return ns.Steps end
local function done(action, ctx) return S():IsActionDone(action, nil, ctx or { cache = {}, items = {} }) end
local function stepById(id) return ns.Registry:Get("test-route").stepById[id] end

local function kinds(lines)
    local out = {}
    for i, l in ipairs(lines) do out[i] = l.kind end
    return out
end

local function texts(lines)
    local out = {}
    for i, l in ipairs(lines) do out[i] = l.text end
    return out
end

describe("action completion", function()
    before_each(function() m, ns = H.boot() end)
    after_each(function() m:AssertClean() end)

    it("accept: in the log or turned in", function()
        local a = { type = "accept", quest = 363 }
        assert.is_false(done(a))
        m:AddQuestToLog(363)
        assert.is_true(done(a))
        m:TurnInQuest(363)
        assert.is_false(m:IsOnQuest(363))
        assert.is_true(done(a))
    end)

    it("accept: an abandoned quest counts only behind the forward limit when a later step abandons it", function()
        local a = { type = "accept", quest = 3902 }
        m:AddQuestToLog(3902)
        m:AbandonQuest(3902)
        assert.is_false(done(a))
        assert.is_false(done(a, { forwarded = true }))
        assert.is_false(done(a, { abandonedLater = { [3902] = true } }))
        assert.is_true(done(a, { forwarded = true, abandonedLater = { [3902] = true } }))
    end)

    it("accept: a quest given up by a LATER marked complete/turnin step counts as taken", function()
        local a = { type = "accept", quest = 364 }
        assert.is_false(done(a, { index = 2 }))
        assert.is_true(done(a, { index = 2, givenUp = { [364] = 5 } }), "never taken, its later step skipped")
        m:AddQuestToLog(364)
        m:AbandonQuest(364)
        assert.is_true(done(a, { index = 2, givenUp = { [364] = 5 } }))
        assert.is_false(done(a, { index = 6, givenUp = { [364] = 5 } }), "an accept after the given-up step")
        assert.is_false(done(a, { index = 5, givenUp = { [364] = 5 } }))
        assert.is_false(done(a, { givenUp = { [364] = 5 } }), "no index: not comparable")
        assert.is_false(done(a, { index = 2, givenUp = { [363] = 5 } }))
    end)

    it("complete / turnin: a given-up quest out of the log counts before the given-up index (non-bg steps)", function()
        local c = { type = "complete", quest = 364 }
        local t = { type = "turnin", quest = 364 }
        local gu = { [364] = 5 }
        assert.is_false(done(c, { index = 3 }))
        assert.is_true(done(c, { index = 3, givenUp = gu }))
        assert.is_true(done(t, { index = 4, givenUp = gu }))
        assert.is_false(done(t, { index = 5, givenUp = gu }), "at / after the given-up index")
        assert.is_false(done(c, { givenUp = gu }), "no index: not comparable")
        assert.is_false(S():IsActionDone(c, { bg = true }, { index = 3, givenUp = gu }), "bg step")
        m:AddQuestToLog(364)
        assert.is_false(done(c, { index = 3, givenUp = gu }), "back in the log: its objectives count")
        assert.is_false(done(t, { index = 3, givenUp = gu }), "back in the log: not turned in")
        m:CompleteObjectives(364)
        assert.is_true(done(c, { index = 3, givenUp = gu }))
    end)

    it("turnin: quest flagged completed (or QUEST_TURNED_IN seen this session)", function()
        local a = { type = "turnin", quest = 363 }
        m:AddQuestToLog(363)
        assert.is_false(done(a))
        m:TurnInQuest(363)
        assert.is_true(done(a))
        -- the server event alone (history flag not updated yet)
        local b = { type = "turnin", quest = 4242 }
        assert.is_false(done(b))
        m:Fire("QUEST_TURNED_IN", 4242, 0, 0)
        assert.is_true(done(b))
    end)

    it("complete: listed objectives, all objectives, turned in", function()
        local all = { type = "complete", quest = 364 }
        local first = { type = "complete", quest = 364, objectives = { 1 } }
        local second = { type = "complete", quest = 364, objectives = { 2 } }
        assert.is_false(done(all))
        assert.is_false(done(first))
        m:AddQuestToLog(364)
        assert.is_false(done(all))
        m:ProgressObjective(364, 1, 4)
        assert.is_false(done(first))
        m:ProgressObjective(364, 1, 1)
        assert.is_true(done(first))
        assert.is_false(done(second))
        assert.is_false(done(all))
        m:ProgressObjective(364, 2, 5)
        assert.is_true(done(all))
        m:FailQuest(364)
        assert.is_false(done(all), "failed quests are not complete")
        m:SetQuestComplete(364, true)
        m:TurnInQuest(364)
        assert.is_true(done(all))
        assert.is_true(done(second))
        -- a quest without objectives is complete as soon as it is in the log
        m:AddQuestToLog(363)
        assert.is_true(done({ type = "complete", quest = 363 }))
    end)

    it("abandon: quest not in the log", function()
        local a = { type = "abandon", quest = 3902 }
        assert.is_true(done(a))
        m:AddQuestToLog(3902)
        assert.is_false(done(a))
        assert.is_false(done(a, { forwarded = true }), "not forwarded")
        m:AbandonQuest(3902)
        assert.is_true(done(a))
    end)

    it("collect: item count in the bags (forwarded collect stays done)", function()
        local a = { type = "collect", item = 3264, count = 6 }
        assert.is_false(done(a))
        m:AddItem(3264, 5)
        assert.is_false(done(a))
        m:AddItem(3264, 1)
        assert.is_true(done(a))
        m:RemoveItem(3264, 6)
        assert.is_false(done(a))
        assert.is_true(done(a, { forwarded = true }))
    end)

    it("level: level above, or the same level with the bar fraction", function()
        local lvl2 = { type = "level", level = 2, frac = 0 }
        local frac = { type = "level", level = 2, frac = 0.5 }
        assert.is_false(done(lvl2))
        m:SetLevel(2, 0)
        assert.is_true(done(lvl2))
        assert.is_false(done(frac))
        m:GiveXP(449)
        assert.is_false(done(frac))
        m:GiveXP(1)
        assert.is_true(done(frac))
        m:SetLevel(3, 0)
        assert.is_true(done(frac))
        -- explicit facts in the context win
        assert.is_false(done(lvl2, { level = 1, xp = 0, xpMax = 400 }))
    end)

    it("transient actions: observed flags or forwarded", function()
        for _, t in ipairs({ "go", "train", "fp", "fly", "sethearth", "hearth", "vendor", "manual" }) do
            local a = { type = t }
            assert.is_false(done(a), t)
            assert.is_true(done(a, { flags = { [t] = true } }), t)
            assert.is_true(done(a, { forwarded = true }), t)
            assert.is_false(done(a, { flags = { other = true } }), t)
        end
    end)

    it("steps: AND of the actions, manual marks, forwarded optional steps", function()
        local multi = stepById("tr-363-364")      -- turnin 363 + accept 364
        local ctx = function() return { cache = {}, items = {} } end
        assert.is_false(S():IsStepDone(multi, ctx()))
        m:AddQuestToLog(363)
        m:TurnInQuest(363)
        assert.is_false(S():IsStepDone(multi, ctx()), "turn-in alone is not enough")
        m:AddQuestToLog(364)
        assert.is_true(S():IsStepDone(multi, ctx()))
        local opt = stepById("tr-optional")
        assert.is_false(S():IsStepDone(opt, ctx()))
        assert.is_true(S():IsStepDone(opt, { forwarded = true }))
        local train = stepById("tr-train-1")
        assert.is_true(S():IsStepDone(train, { manual = true }))
        assert.is_true(S():IsStatefulDone(train, ctx()), "no stateful action")
        assert.is_false(S():IsAnchorStep(train))
        assert.is_true(S():IsAnchorStep(multi))
        assert.is_false(S():IsAnchorStep(stepById("tr-bg-364")), "bg steps never anchor")
        assert.is_false(S():IsAnchorStep(stepById("tr-abandon-3902")))
        assert.is_false(S():IsAnchorStep(stepById("tr-level-2")), "a level is no evidence of progress")
        assert.is_false(S():IsAnchorStep(stepById("tr-optional")), "optional level step")
        assert.is_false(S():IsAnchorStep(stepById("tr-collect-376")), "items may be in the bags by accident")
    end)
end)

describe("step descriptions", function()
    after_each(function() m:AssertClean() end)

    it("describes quest steps with titles, atlases, objectives and notes", function()
        m, ns = H.boot()
        local lines = S():Describe(stepById("tr-363-364"))
        assert.same({ "turnin", "accept" }, kinds(lines))
        assert.same({ "Turn in: Rude Awakening", "Accept: The Mindless Ones" }, texts(lines))
        assert.equal("QuestTurnin", lines[1].icon)
        assert.is_true(lines[1].isAtlas)
        assert.equal(363, lines[1].questID)
        assert.is_false(lines[1].done)

        m:AddQuestToLog(364)
        m:ProgressObjective(364, 1, 2)
        lines = S():Describe(stepById("tr-bg-364"))
        assert.same({ "complete", "objective", "note" }, kinds(lines))
        assert.equal("Complete: The Mindless Ones (objectives 1)", lines[1].text)
        assert.equal("2/5 Mindless Zombie slain", lines[2].text)
        assert.equal(1, lines[2].index)
        assert.is_false(lines[2].done)
        assert.equal("Kill Mindless Zombies on the way", lines[3].text)
        m:ProgressObjective(364, 1, 3)
        lines = S():Describe(stepById("tr-bg-364"))
        assert.is_true(lines[1].done)
        assert.is_true(lines[2].done)
        lines = S():Describe(stepById("tr-complete-364"))
        assert.same({ "complete", "objective", "objective" }, kinds(lines))
        assert.equal("Complete: The Mindless Ones", lines[1].text)
        assert.equal("SmallQuestBang", lines[1].icon)
    end)

    it("describes the other action types", function()
        m, ns = H.boot()
        local function first(id) return S():Describe(stepById(id))[1] end
        local c = first("tr-collect-376")
        assert.equal("collect", c.kind)
        assert.equal("Collect Duskbat Wing: 0/6", c.text)
        assert.equal(134400, c.icon)
        assert.is_false(c.isAtlas)
        assert.equal(3264, c.itemID)
        m:AddItem(3264, 9)
        assert.equal("Collect Duskbat Wing: 6/6", first("tr-collect-376").text)
        assert.equal("Reach level 2", first("tr-level-2").text)
        assert.equal("Reach level 4 and 30% of the bar", first("tr-level-4").text)
        assert.equal("Go to Tirisfal Glades 60.5, 52.5", first("tr-go-brill").text)
        assert.equal("Navigation-Tracked-Icon", first("tr-go-brill").icon)
        assert.equal("Set your hearthstone: Brill", first("tr-sethearth").text)
        assert.equal("Visit a vendor (sell / restock)", first("tr-vendor").text)
        assert.equal("Get the flight path: Undercity", first("tr-fp-uc").text)
        assert.equal("Fly to The Sepulcher", first("tr-fly").text)
        assert.equal("Hearth to Brill", first("tr-hearth").text)
        assert.equal("Abandon: Scavenging Deathknell", first("tr-abandon-3902").text)
        local train = S():Describe(stepById("tr-train-1"))
        assert.same({ "train", "spells" }, kinds(train))
        assert.equal("Learn: Seal of Righteousness", train[2].text)
        local manual = S():Describe(stepById("tr-manual"))
        assert.same({ "manual", "note" }, kinds(manual))
        assert.equal("Press \"Forward\" when done", manual[1].text)
        assert.equal("Accept: Rude Awakening", S():Label(stepById("tr-accept-363")))
    end)

    it("uses ruRU texts, localized place names and route data titles", function()
        m, ns = H.boot({ locale = "ruRU" })
        local function first(id) return S():Describe(stepById(id))[1] end
        assert.equal("Привязать камень возвращения: Брилл", first("tr-sethearth").text)
        assert.equal("Лететь: Гробница", first("tr-fly").text)
        local train = S():Describe(stepById("tr-train-1"))
        assert.equal("Выучить: Печать праведности", train[2].text)
        assert.equal("Поговорите с Гробовщиком Мордо", S():Describe(stepById("tr-accept-363"))[2].text)
    end)

    it("falls back to route data, then to 'Quest #id', while the client has no title", function()
        m, ns = H.new({ locale = "ruRU", setup = function(mm)
            mm:DefineQuest(363, { title = "Грубое пробуждение (клиент)", uncached = true })
            mm.questCache[363] = nil
            mm:DefineQuest(999, { title = "Late Title", uncached = true })
        end })
        H.Mock.boot(m, { "AdventureAtlas", H.FIXTURE_NAME })  -- no frame has run yet: nothing loaded
        assert.equal("Грубое пробуждение", S():QuestTitle(363), "route data title")
        assert.equal("Задание №999", S():QuestTitle(999))
        local loaded = H.record(ns, "QUEST_DATA_LOADED")
        m:Advance(0.2)
        assert.equal("Late Title", S():QuestTitle(999))
        assert.equal("Грубое пробуждение (клиент)", S():QuestTitle(363))
        assert.is_true(#loaded >= 1)
        assert.equal("Предмет №424242", S():ItemName(424242))
    end)
end)
