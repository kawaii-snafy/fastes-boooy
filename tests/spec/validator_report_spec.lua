-- The Markdown report of the validator (docs/VALIDATION.md, `make report`): tools/lib/report.lua,
-- the layout of docs/dev/PLAN.md A.6.4:
--   totals; module entries; a route summary table; the path comparison (start chains and segments
--   with ranges over the routes); the messages on steps of shared SEGMENTS once for all routes, with
--   a "routes" column and ranges for the numbers that depend on the run; the gate matrix with the
--   `ok` ceilings; one section per route with only its own messages (its own steps and the steps of
--   class / race inserts); INFO only as counts; the "only in game" list with the accepted
--   db-override-unverified warnings.
-- The text and JSON outputs keep the complete per-route view.
-- Cases: the helpers, hand-made results (every aggregation rule), a temporary module of the Guides
-- shape through the real validator and the command line, the fixtures.

local DB = require("lib.fbdb")
local Loader = require("lib.route_loader")
local V = require("lib.validator")
local Report = require("lib.report")
local json = require("lib.json")
local H = require("fixtures.core.helpers")

local db, schema, root

local function run(cmd)
    local p = assert(io.popen(cmd .. " 2>&1; echo \"__EXIT=$?\""))
    local out = p:read("*a")
    p:close()
    local code = tonumber(out:match("__EXIT=(%d+)%s*$"))
    return code, (out:gsub("__EXIT=%d+%s*$", ""))
end

local function write(path, content)
    os.execute(("mkdir -p '%s'"):format((root .. "/" .. path):match("^(.*)/[^/]+$")))
    local fh = assert(io.open(root .. "/" .. path, "wb"))
    fh:write(content)
    fh:close()
    return root .. "/" .. path
end

local function readAll(path)
    local fh = assert(io.open(path, "r"))
    local s = fh:read("*a")
    fh:close()
    return s
end

local function markdown(all)
    return table.concat(V.FormatMarkdown(all, db), "\n") .. "\n"
end

-- the text of one "## " section (up to the next "## " heading)
local function section(md, title)
    local s = md:find("\n## " .. title .. "\n", 1, true)
    if not s then return nil end
    local e = md:find("\n## ", s + 4, true)
    return md:sub(s + 1, e or #md)
end

-- the text of one "### <route>" section
local function routeSection(md, id)
    local s = md:find("\n### " .. id .. " ", 1, true)
    assert.is_truthy(s, "no section of route " .. id)
    local e = md:find("\n##", s + 5, true)
    return md:sub(s + 1, e or #md)
end

local function has(text, plain, msg)
    assert.is_truthy(text and text:find(plain, 1, true), (msg or "") .. " expected to find: " .. plain
        .. "\nin:\n" .. tostring(text))
end

local function hasNot(text, plain)
    assert.is_nil(text:find(plain, 1, true), "expected NOT to find: " .. plain)
end

---------------------------------------------------------------------------
-- hand-made results
---------------------------------------------------------------------------

local function seg(id, from, to, kills, worst, library)
    return { id = id, title = { en = "T " .. id }, levels = { math.floor(from), math.floor(to) }, startLevel = from,
             endLevel = to, xpQuest = 100, xpKill = 50, grindKills = kills, grindKillsWorst = worst, questLog = 3,
             library = library and "M" or nil }
end

local function gate(stepId, kills, worst, extra)
    local g = { segment = "tail", step = 5, stepId = stepId, level = 20, frac = 0.5, kills = kills, killsWorst = worst,
                library = "M",
                band = { ["0"] = { kills = kills, worst = worst }, ["15"] = { kills = kills - 1, worst = worst - 1 } } }
    for k, v in pairs(extra or {}) do g[k] = v end
    return g
end

-- a run result (what V.RunProfile returns) with given segments, gates and messages
local function result(id, o)
    local r = {
        route = id, title = { en = "Title of " .. id }, profile = o.profile or { race = "Orc", class = "WARRIOR" },
        profileLabel = o.profileLabel or "Orc WARRIOR Horde", messages = o.messages or {},
        counts = { ERROR = 0, WARN = 0, INFO = 0 }, acceptedWarn = 0, suppressed = 0, segments = o.segments or {},
        endState = {},
        summary = {
            endLevel = o.endLevel or 60, endLevelWorst = o.endLevelWorst or 59.5, endLevelOptimistic = 60,
            plannedLevels = { 1, 60 }, grindKills = o.kills or 100, grindKillsWorst = o.worst or 150, xpQuest = 1000,
            xpQuestEstimated = 100, xpKill = 500, xpGrind = 200, unknownXpQuests = 7, xpQuestEstimatedPct = 10,
            maxQuestLog = 21, steps = 300, optionalSkipped = 12, optionalAccepts = 5, accepts = 40, turnins = 39,
            carried = {}, incidentalPct = 0, gates = o.gates or {},
            band = { ["0"] = { grindKills = o.kills or 100, grindKillsWorst = o.worst or 150 },
                     ["15"] = { grindKills = 80, grindKillsWorst = 120 } },
        },
    }
    for _, m in ipairs(r.messages) do V.CountMessage(r, m, 1) end
    return r
end

-- a message on a base step of a shared segment
local function shared(sev, code, stepId, msg, extra)
    local m = { severity = sev, code = code, segment = "tail", step = 3, stepId = stepId, file = "Segments/Tail.lua",
                msg = msg, library = "M", shared = true }
    for k, v in pairs(extra or {}) do m[k] = v end
    return m
end

describe("validator Markdown report (tools/lib/report.lua)", function()
    setup(function()
        db = DB.Load("tools/data/forever_db.lua")
        schema = Loader.LoadSchema(".")
        root = os.tmpname()
        os.remove(root)
        os.execute(("mkdir -p '%s'"):format(root))
    end)
    teardown(function() os.execute(("rm -rf '%s'"):format(root)) end)

    describe("helpers", function()
        it("MergeTexts: identical texts stay; numbers that differ become ranges; other differences do not merge", function()
            assert.same({ "same", 1, true }, { Report.MergeTexts({ "same", "same", "same" }) })
            local text, variants, merged = Report.MergeTexts({
                "level 30 +67%: simulated level 30.22 is short by 21255 XP; ~109 same-level kills needed",
                "level 30 +67%: simulated level 30.33 is short by 16380 XP; ~84 same-level kills needed",
                "level 30 +67%: simulated level 30.30 is short by 17000 XP; ~90 same-level kills needed",
            })
            assert.equal("level 30 +67%: simulated level 30.22–30.33 is short by 16380–21255 XP; ~84–109 same-level "
                .. "kills needed", text)
            assert.equal(3, variants)
            assert.is_true(merged)
            -- a number at the end of a sentence keeps its full stop; ids that are equal stay single
            text = Report.MergeTexts({ "quest 364 ends at level 5.", "quest 364 ends at level 12." })
            assert.equal("quest 364 ends at level 5–12.", text)
            -- another wording (not only numbers): the first text, and the caller says so
            text, variants, merged = Report.MergeTexts({ "npc 12 is far", "npc 12 is hostile", "npc 12 is far" })
            assert.equal("npc 12 is far", text)
            assert.equal(2, variants)
            assert.is_false(merged)
            -- a different number of numbers does not merge either
            assert.is_false(select(3, Report.MergeTexts({ "a 1 b", "a 1 b 2" })))
        end)

        it("RouteSet: all, whole race / class groups, else up to three ids and a count", function()
            local universe = {}
            for _, race in ipairs({ "orc", "troll", "undead" }) do
                for _, class in ipairs({ "mage", "rogue", "warrior" }) do universe[#universe + 1] = race .. "-" .. class end
            end
            local function set(...)
                local t = {}
                for _, id in ipairs({ ... }) do t[id] = true end
                return t
            end
            local all = set(unpack(universe))
            assert.equal("все 9", Report.RouteSet(all, universe))
            assert.equal("все 3 `troll-*`", Report.RouteSet(set("troll-mage", "troll-rogue", "troll-warrior"), universe))
            assert.equal("все 3 `orc-*`, все 3 `undead-*`", Report.RouteSet(set("orc-mage", "orc-rogue", "orc-warrior",
                "undead-mage", "undead-rogue", "undead-warrior"), universe))
            assert.equal("все 3 `*-warrior`", Report.RouteSet(set("orc-warrior", "troll-warrior", "undead-warrior"),
                universe))
            assert.equal("`orc-mage`, `troll-rogue`", Report.RouteSet(set("troll-rogue", "orc-mage"), universe),
                "run order, not the order of the set")
            assert.equal("`orc-mage`, `orc-rogue`, `troll-mage` и ещё 2", Report.RouteSet(set("orc-mage", "orc-rogue",
                "troll-mage", "troll-rogue", "undead-mage"), universe))
            assert.equal("`solo`", Report.RouteSet({ solo = true }, { "solo" }))
            assert.equal("—", Report.RouteSet({}, universe))
            -- a group of one route is named, not "все 1"
            assert.equal("`a-x`", Report.RouteSet({ ["a-x"] = true }, { "a-x", "b-y" }))
            -- labels of a route with several profiles
            assert.equal("`r [Orc WARRIOR Horde]`", Report.RouteSet({ ["r [Orc WARRIOR Horde]"] = true },
                { "r [Orc WARRIOR Horde]", "r [Troll WARRIOR Horde]" }))
        end)

        it("Range: one value or min–max, in the given format", function()
            assert.equal("12.50", Report.Range({ min = 12.5, max = 12.5 }, "%.2f"))
            assert.equal("12.50–13.00", Report.Range({ min = 12.5, max = 13 }, "%.2f"))
            assert.equal("0–40", Report.Range({ min = 0, max = 40 }, "%d"))
            assert.equal("—", Report.Range({}, "%d"))
        end)
    end)

    describe("hand-made results", function()
        -- three routes: two start chains, a common tail of two segments; messages of every kind
        local function sample()
            local gateText = "level 20 +50%%: simulated level %s is short by %d XP; ~%d same-level kills needed (estimate)"
            local function msgs(level, xp, kills, own)
                local list = {
                    shared("WARN", "at-far", "t-far", "npc 1 is 50 yards from `at`", { npc = 1 }),
                    shared("WARN", "at-far", "t-far", "npc 2 is 60 yards from `at`", { npc = 2 }),
                    shared("WARN", "level-grind", "t-gate", gateText:format(level, xp, kills), { kills = kills }),
                    shared("WARN", "quest-carried", "t-carry", "quest 9 is carried", { quest = 9, accepted = true }),
                    shared("INFO", "complete-kill-xp", "t-kill", "INFO-TEXT-NEVER-SHOWN"),
                    shared("INFO", "xp-unknown", "t-xp", "INFO-TEXT-NEVER-SHOWN"),
                    { severity = "WARN", code = "segment-level", segment = "tail", file = "Segments/Tail.lua", library = "M",
                      shared = true, msg = ("segment tail ends at simulated level %s; planned end level 21"):format(level) },
                }
                for _, m in ipairs(own or {}) do list[#list + 1] = m end
                return list
            end
            local classStep = { severity = "WARN", code = "train-no-npc", segment = "tail", step = 4, stepId = "war-train",
                file = "Classes/Warrior.lua", library = "M", shared = true, inserted = true, msg = "train step without npc" }
            local classOk = { severity = "WARN", code = "at-far", segment = "tail", step = 6, stepId = "war-far",
                file = "Classes/Warrior.lua", library = "M", shared = true, inserted = true, accepted = true,
                msg = "npc 3 is 70 yards from `at`" }
            local override = shared("WARN", "db-override-unverified", "t-ov", "accept 4641 passes only with an unverified "
                .. "override (races)", { quest = 4641, accepted = true })
            local a = result("orc-warrior", {
                kills = 100, worst = 150,
                segments = { seg("dur-01", 1, 12.5, 10, 20, true), seg("tail", 12.5, 21.1, 90, 130, true),
                             seg("end", 21.1, 60, 0, 0, true) },
                gates = { gate("t-gate", 109, 140, { okCeiling = 90 }), gate("t-opt", 5, 0, { optional = true }),
                          gate("war-gate", 3, 4, { inserted = true }),
                          { segment = "dur-01", step = 2, stepId = "own-gate", level = 3, frac = 0, kills = 1, killsWorst = 2,
                            band = { ["0"] = { kills = 1, worst = 2 }, ["15"] = { kills = 0, worst = 1 } } } },
                messages = msgs("19.10", 21255, 109, { classStep, classOk, override,
                    { severity = "ERROR", code = "end-level", msg = "the route ends at simulated level 59.50" } }),
            })
            local b = result("troll-warrior", {
                profileLabel = "Troll WARRIOR Horde", kills = 80, worst = 151,
                segments = { seg("dur-01", 1, 12.9, 12, 25, true), seg("tail", 12.9, 21.4, 68, 126, true),
                             seg("end", 21.4, 60, 0, 0, true) },
                gates = { gate("t-gate", 84, 141, { okCeiling = 90 }), gate("t-opt", 7, 0, { optional = true }),
                          gate("war-gate", 3, 4, { inserted = true }) },
                messages = msgs("19.40", 16380, 84, { classStep, override }),
            })
            -- the gate is under its ceiling in this route: the same WARN is ACCEPTED here
            local cm = msgs("19.60", 15000, 80)
            cm[3].accepted, cm[3].okCeiling = true, 90
            local c = result("undead-mage", {
                profileLabel = "Scourge MAGE Horde", kills = 70, worst = 99,
                segments = { seg("ud-01", 1, 6, 0, 0, true), seg("ud-02", 6, 13.3, 2, 2, true),
                             seg("tail", 13.3, 21.9, 68, 97, true), seg("end", 21.9, 60, 0, 0, true) },
                gates = { gate("t-gate", 80, 97, { okCeiling = 90 }) },
                messages = cm,
            })
            local entry = { route = "(shared M)", shared = "M", module = "M",
                profileLabel = "shared: 4 segment(s), 2 insert(s), 9 step(s)", segments = {}, summary = {},
                counts = { ERROR = 1, WARN = 0, INFO = 0 }, acceptedWarn = 0,
                messages = { { severity = "ERROR", code = "insert-anchor-unknown", stepId = "war-x",
                               file = "Classes/Warrior.lua", msg = "anchor 'nope' is the id of no loaded step" } } }
            return { { module = "M", dir = "addons/M", results = { entry, a, b, c },
                       notes = { { severity = "ERROR", code = "schema", file = "Classes/Mage.lua", msg = "a note text",
                                   note = "a reason" } } } }
        end

        it("the sections, in the order of the layout", function()
            local md = markdown(sample())
            local order = { "# Отчёт валидатора маршрутов", "\n**Итого: ", "\n## Модули и общие проверки\n",
                "\n## Сводка по маршрутам\n", "\n## Сравнение путей\n", "\n## Общие шаги\n",
                "\n## Пороги уровня на общих шагах\n", "\n## Маршруты\n", "\n### orc-warrior — Title of orc-warrior\n",
                "\n### troll-warrior — ", "\n### undead-mage — ", "\n## INFO по кодам\n",
                "\n## Что подтверждается только в игре\n", "\n### Принятые непроверенные поправки к БД\n" }
            local pos = 0
            for _, head in ipairs(order) do
                local s = md:find(head, pos + 1, true)
                assert.is_truthy(s, "missing or out of order: " .. head)
                pos = s
            end
        end)

        it("totals: every message counted; rows left once the shared path is shown once", function()
            local md = markdown(sample())
            -- ERROR: the entry 1 + end-level 1; WARN: a 5 + b 5 + c 3 (its gate is accepted); accepted: 3 + 2 + 2
            has(md, "**Итого: 2 ERROR, 13 WARN, 6 INFO; принято предупреждений (`ok`): 7.**")
            -- on the shared path, unaccepted: a 4, b 4, c 3 = 11, in 4 rows (two at-far, the gate, segment-level)
            has(md, "Прогонов (маршрут × профиль): 3. ERROR и WARN без повторов: 8 из 15 (сообщений о шагах общих "
                .. "сегментов: 11, строк в разделе «Общие шаги»: 4).")
        end)

        it("module entries: the template checks of the shared content, and the notes", function()
            local s = section(markdown(sample()), "Модули и общие проверки")
            has(s, "### Общая часть модуля M")
            has(s, "(shared: 4 segment(s), 2 insert(s), 9 step(s))")
            has(s, "| ERROR | id=war-x (Classes/Warrior.lua) | `insert-anchor-unknown` | anchor 'nope' is the id of no "
                .. "loaded step |")
            has(s, "### Заметки (не входят в итог)")
            has(s, "- note  (Classes/Mage.lua) [schema] a note text -- not counted: a reason")
        end)

        it("route summary: one row per route with the numbers of both runs and the band", function()
            local s = section(markdown(sample()), "Сводка по маршрутам")
            has(s, "| `orc-warrior` | Orc WARRIOR Horde | 1 | 5 | 3 | 60.00 | 59.50 | 100 | 150 | 80 | 120 | 7 (10.0 %) | "
                .. "21 | 300 | 12 |")
            has(s, "| `troll-warrior` | Troll WARRIOR Horde | 0 | 5 | 2 | ")
            has(s, "| `undead-mage` | Scourge MAGE Horde | 0 | 3 | 2 | ")
            local _, rows = s:gsub("\n| `", "")
            assert.equal(3, rows)
        end)

        it("path comparison: start chains before the common tail, and every segment with its ranges", function()
            local s = section(markdown(sample()), "Сравнение путей")
            has(s, "Общий хвост всех маршрутов — 2 сегм., начиная с `tail` (точка слияния).")
            -- the Durotar pair enters the tail at 12.5 and 12.9 with 10 / 12 kills (worst 20 / 25)
            has(s, "| `dur-01` | все 2 `*-warrior` | 12.50–12.90 | 10–12 | 20–25 |")
            has(s, "| `ud-01`, `ud-02` | `undead-mage` | 13.30 | 2 | 2 |")
            -- segments: the start segments first, then the tail; "все 3" for the shared ones
            has(s, "| `dur-01` T dur-01 | 1–12 | все 2 `*-warrior` | 1.00 | 12.50–12.90 | 10–12 | 20–25 |")
            has(s, "| `ud-02` T ud-02 | 6–13 | `undead-mage` | 6.00 | 13.30 | 2 | 2 |")
            has(s, "| `tail` T tail | 12–21 | все 3 | 12.50–13.30 | 21.10–21.90 | 68–90 | 97–130 |")
            assert.is_true(s:find("| `ud-02` ", 1, true) < s:find("| `tail` ", 1, true))
            assert.is_true(s:find("| `tail` ", 1, true) < s:find("| `end` ", 1, true))
        end)

        it("shared steps: one row per (severity, code, step, quest), routes, ranges; accepted ones apart", function()
            local md = markdown(sample())
            local s = section(md, "Общие шаги")
            -- two messages with the same key in one run stay two rows (the n-th of each run together)
            has(s, "| WARN | tail#3 id=t-far (Segments/Tail.lua) | `at-far` | все 3 | npc 1 is 50 yards from `at` |")
            has(s, "| WARN | tail#3 id=t-far (Segments/Tail.lua) | `at-far` | все 3 | npc 2 is 60 yards from `at` |")
            -- the gate: unaccepted in the two warrior routes (range), accepted in the third
            has(s, "| WARN | tail#3 id=t-gate (Segments/Tail.lua) | `level-grind` | все 2 `*-warrior` | level 20 +50%: "
                .. "simulated level 19.10–19.40 is short by 16380–21255 XP; ~84–109 same-level kills needed (estimate) |")
            has(s, "| WARN | tail (Segments/Tail.lua) | `segment-level` | все 3 | segment tail ends at simulated level "
                .. "19.10–19.60; planned end level 21 |")
            local open = s:sub(1, (s:find("<details>", 1, true)))
            local _, rows = open:gsub("\n| WARN ", "")
            assert.equal(4, rows)
            has(s, "<details><summary>Принятые предупреждения на общих шагах, `ok` (3)</summary>")
            local acc = s:sub((s:find("<details>", 1, true)))
            has(acc, "| tail#3 id=t-carry (Segments/Tail.lua) | `quest-carried` | все 3 | quest 9 is carried |")
            has(acc, "| tail#3 id=t-gate (Segments/Tail.lua) | `level-grind` | `undead-mage` | level 20 +50%: simulated "
                .. "level 19.60 is short by 15000 XP; ~80 same-level kills needed (estimate) |")
            has(acc, "| tail#3 id=t-ov (Segments/Tail.lua) | `db-override-unverified` | все 2 `*-warrior` | ")
            -- no class step, no route-level message, no INFO text here
            hasNot(s, "war-train")
            hasNot(s, "end-level")
            hasNot(md, "INFO-TEXT-NEVER-SHOWN")
        end)

        it("shared steps: texts that differ in more than numbers are not merged", function()
            local all = sample()
            all[1].results[3].messages[1].msg = "npc 1 has no spawn on the map"
            local s = section(markdown(all), "Общие шаги")
            has(s, "| `at-far` | все 3 | npc 1 is 50 yards from `at` _(текст различается по маршрутам: вариантов 2, "
                .. "показан первый)_ |")
        end)

        it("gate matrix: the gates on shared steps, min / max / worst over the routes, the `ok` ceiling", function()
            local s = section(markdown(sample()), "Пороги уровня на общих шагах")
            has(s, "| 20 +50% | tail#5 id=t-gate | все 3 | 80 | 109 | 141 | 90 |")
            has(s, "| 20 +50% (необязательный) | tail#5 id=t-opt | все 2 `*-warrior` | 5 | 7 | — | — |")
            -- a gate of a shared insert (a class file) is a shared gate too
            has(s, "| 20 +50% | tail#5 id=war-gate | все 2 `*-warrior` | 3 | 3 | 4 | — |")
            -- the route's own gate is in its section
            hasNot(s, "own-gate")
        end)

        it("route sections: the route's own messages only (own steps, class / race inserts, the route itself)", function()
            local md = markdown(sample())
            local a = routeSection(md, "orc-warrior")
            has(a, "Результат: **1 ERROR, 5 WARN, 2 INFO**; принято предупреждений (`ok`): 3; из них на общих шагах: "
                .. "0 ERROR, 4 WARN, принято 2.")
            has(a, "Симуляция: конец маршрута на уровне **60.00**")
            has(a, "Гринд до порогов уровня (шаги `level`): ~100 убийств мобов своего уровня")
            has(a, "| 3 | dur-01#2 id=own-gate | 1 | 2 | 0 | 1 |")
            hasNot(a, "t-gate")
            has(a, "| `tail` | 12–21 | 12.50 → 21.10 | 100 | 50 | 90 (130) | 3 |")
            has(a, "| WARN | [library M] tail#4 id=war-train (Classes/Warrior.lua) | `train-no-npc` | train step without npc |")
            has(a, "| ERROR | route | `end-level` | the route ends at simulated level 59.50 |")
            hasNot(a, "id=t-far")
            has(a, "<details><summary>Принятые предупреждения, `ok` (1)</summary>")
            has(a, "- [library M] tail#6 id=war-far (Classes/Warrior.lua) `at-far` npc 3 is 70 yards from `at`")
            has(a, "INFO (2): `complete-kill-xp` 1, `xp-unknown` 1.")
            local c = routeSection(md, "undead-mage")
            has(c, "Собственных ошибок и предупреждений нет.")
            hasNot(c, "<details>")
            hasNot(c, "| порог уровня |")
        end)

        it("INFO: counts per code over the routes, never the texts", function()
            local md = markdown(sample())
            local s = section(md, "INFO по кодам")
            has(s, "| `complete-kill-xp` | 3 | 3 | 1 |")
            has(s, "| `xp-unknown` | 3 | 3 | 1 |")
            hasNot(md, "<summary>INFO")
        end)

        it("only in game: the static list and the accepted db-override-unverified warnings, once each", function()
            local md = markdown(sample())
            local s = section(md, "Что подтверждается только в игре")
            has(s, "Автоматизация без аппаратного события")
            has(s, "приняты ключом `ok` (1)")
            has(s, "| tail#3 id=t-ov (Segments/Tail.lua) | все 2 `*-warrior` | accept 4641 passes only with an unverified "
                .. "override (races) |")
            -- none: the sentence says so
            local all = sample()
            for _, r in ipairs(all[1].results) do
                for i = #r.messages, 1, -1 do
                    if r.messages[i].code == "db-override-unverified" then table.remove(r.messages, i) end
                end
            end
            s = section(markdown(all), "Что подтверждается только в игре")
            has(s, "`verified = false`) и приняты ключом `ok = \"db-override-unverified\"`, нет.")
        end)

        it("a route with two profiles: one row and one section per profile, labelled", function()
            local a = result("r", { profileLabel = "Orc WARRIOR Horde", segments = { seg("x", 1, 5, 0, 0) },
                messages = { shared("WARN", "at-far", "s", "far") } })
            local b = result("r", { profileLabel = "Troll WARRIOR Horde", segments = { seg("x", 1, 5, 0, 0) } })
            local md = markdown({ { module = "M", results = { a, b } } })
            has(md, "\n### r [Orc WARRIOR Horde] — ")
            has(md, "\n### r [Troll WARRIOR Horde] — ")
            has(section(md, "Общие шаги"), "| `at-far` | `r [Orc WARRIOR Horde]` | far |")
            has(section(md, "Сравнение путей"), "Общий хвост всех маршрутов — 1 сегм., начиная с `x`")
            has(section(md, "Сравнение путей"), "| (сразу общий хвост) | все 2 | 1.00 | 0 | 0 |")
        end)

        it("routes without a common tail; a single route; no module at all", function()
            local a = result("a", { segments = { seg("a1", 1, 5, 1, 2) }, endLevel = 5 })
            local b = result("b", { segments = { seg("b1", 1, 7, 3, 4) }, endLevel = 7 })
            local s = section(markdown({ { module = "M", results = { a, b } } }), "Сравнение путей")
            has(s, "Общего хвоста у маршрутов нет")
            has(s, "| `a1` | `a` | 5.00 | 1 | 2 |")
            has(s, "| `b1` | `b` | 7.00 | 3 | 4 |")
            -- one route: no start-chain table, the segment table only; no gate matrix without shared gates
            local md = markdown({ { module = "M", results = { a } } })
            s = section(md, "Сравнение путей")
            hasNot(s, "стартовый участок")
            has(s, "| `a1` T a1 | 1–5 | `a` | 1.00 | 5.00 | 1 | 2 |")
            assert.is_nil(section(md, "Пороги уровня на общих шагах"))
            has(section(md, "Общие шаги"), "Ошибок и предупреждений на общих шагах нет.")
            md = markdown({})
            has(md, "_Модули маршрутов не найдены._")
            assert.is_nil(section(md, "Сводка по маршрутам"))
            has(md, "## Что подтверждается только в игре")
        end)
    end)

    describe("a module of the Guides shape through the real validator", function()
        local dir

        local AT_MORDO, AT_SARVIS = "{ 1420, 30.2, 71.7 }", "{ 1420, 30.8, 66.2 }"

        setup(function()
            dir = root .. "/FastesBoooy_RpGuides"
            write("FastesBoooy_RpGuides/FastesBoooy_RpGuides.toc", "## Interface: 16001\n## Dependencies: FastesBoooy\n"
                .. "Segments/A.lua\nSegments/B.lua\nSegments/Tail.lua\nClasses/Paladin.lua\nClasses/Warrior.lua\nRoute.lua\n")
            -- two start chains (both take 363 from Mordo; B also has a level gate that needs kills) ...
            write("FastesBoooy_RpGuides/Segments/A.lua", ([[
FastesBoooy.AddLibrarySegment({ id = "rp-start-a", title = "A", levels = { 1, 1 }, steps = {
    { id = "rp-a-363", accept = 363, npc = 1568, at = %s },
} })
]]):format(AT_MORDO))
            write("FastesBoooy_RpGuides/Segments/B.lua", ([[
FastesBoooy.AddLibrarySegment({ id = "rp-start-b", title = "B", levels = { 1, 2 }, steps = {
    { id = "rp-b-363", accept = 363, npc = 1568, at = %s },
    { id = "rp-b-gate", level = { 1, 0.5 } },
} })
]]):format(AT_MORDO))
            -- ... and the common tail: a turn-in without a complete step (WARN turnin-no-complete on the
            -- shared path) and a gate acknowledged with a ceiling (WARN level-grind, accepted)
            write("FastesBoooy_RpGuides/Segments/Tail.lua", ([[
FastesBoooy.AddLibrarySegment({ id = "rp-tail", title = { en = "Tail" }, levels = { 1, 5 }, steps = {
    { id = "rp-364", turnin = 363, accept = 364, npc = 1569, at = %s },
    { id = "rp-364-in", turnin = 364, npc = 1569, at = %s },
    { id = "rp-gate", level = { 4, 0.5 }, ok = { ["level-grind"] = 9000 } }, -- the fixture has no quests left
} })
]]):format(AT_SARVIS, AT_SARVIS))
            -- class files: a train step without an NPC (WARN train-no-npc), a class gate
            write("FastesBoooy_RpGuides/Classes/Paladin.lua", [[
FastesBoooy.AddLibraryInsert({ after = "rp-364", class = "PALADIN", steps = {
    { id = "rp-pal-train", train = true },
} })
]])
            write("FastesBoooy_RpGuides/Classes/Warrior.lua", [[
FastesBoooy.AddLibraryInsert({ after = "rp-364-in", class = "WARRIOR", steps = {
    { id = "rp-war-gate", level = 2 },
} })
]])
            write("FastesBoooy_RpGuides/Route.lua", [[
local CHAINS = {
    { "rp-undead-paladin", "PALADIN", { "rp-start-a", "rp-tail" } },
    { "rp-undead-warrior", "WARRIOR", { "rp-start-b", "rp-tail" } },
    { "rp-undead-mage", "MAGE", { "rp-start-b", "rp-tail" } },
}
for i = 1, #CHAINS do
    local c = CHAINS[i]
    FastesBoooy.RegisterRoute({ api = 1, id = c[1], title = { en = "Report " .. c[2] }, faction = "Horde",
        races = { "Scourge" }, classes = { c[2] }, levels = { 1, 5 } })
    FastesBoooy.UseSegments(c[1], c[3])
end
]])
        end)

        it("the results carry what the report needs: inserted, the gate fields, the segment's library", function()
            local res = V.ValidateModule(dir, { db = db, schema = schema })
            assert.same({}, res.loadErrors)
            assert.equal("(shared FastesBoooy_RpGuides)", res.results[1].route)
            local pal, war = res.results[2], res.results[3]
            assert.equal("rp-undead-paladin", pal.route)
            local function find(r, code, stepId)
                for _, m in ipairs(r.messages) do
                    if m.code == code and m.stepId == stepId then return m end
                end
            end
            -- a step of a shared segment: shared, not inserted; a step of a shared insert: both
            local base = find(pal, "turnin-no-complete", "rp-364-in")
            assert.is_true(base.shared)
            assert.is_nil(base.inserted)
            assert.is_true(Report.OnSharedPath(base))
            local class = find(pal, "train-no-npc", "rp-pal-train")
            assert.is_true(class.shared)
            assert.is_true(class.inserted)
            assert.is_false(Report.OnSharedPath(class))
            -- gates: the ceiling of the step's `ok`; inserted on a class gate
            local gates = {}
            for _, g in ipairs(war.summary.gates) do gates[g.stepId] = g end
            assert.equal(9000, gates["rp-gate"].okCeiling)
            assert.is_nil(gates["rp-gate"].inserted)
            assert.equal("FastesBoooy_RpGuides", gates["rp-gate"].library)
            assert.is_true(gates["rp-war-gate"].inserted)
            assert.is_nil(gates["rp-war-gate"].okCeiling)
            assert.equal("FastesBoooy_RpGuides", war.segments[1].library)
            assert.is_true(find(war, "level-grind", "rp-gate").accepted)
        end)

        it("--markdown: the aggregated report; --json and the text output stay complete per route", function()
            local md, js = root .. "/rp.md", root .. "/rp.json"
            local code, out = run(("lua5.1 tools/validate_routes.lua --no-overrides --markdown '%s' --json '%s' '%s'")
                :format(md, js, dir))
            assert.equal(0, code, out)
            local m = readAll(md)
            -- summary: three routes
            local s = section(m, "Сводка по маршрутам")
            has(s, "| `rp-undead-paladin` | Scourge PALADIN Horde | 0 | ")
            has(s, "| `rp-undead-warrior` | Scourge WARRIOR Horde | 0 | ")
            has(s, "| `rp-undead-mage` | Scourge MAGE Horde | 0 | ")
            -- paths: the tail is the merge point; chain A is the paladin's, chain B the other two
            s = section(m, "Сравнение путей")
            has(s, "Общий хвост всех маршрутов — 1 сегм., начиная с `rp-tail` (точка слияния).")
            has(s, "| `rp-start-a` | `rp-undead-paladin` | 1.00 | 0 | 0 |")
            assert.matches("\n| `rp%-start%-b` | `rp%-undead%-warrior`, `rp%-undead%-mage` | 1%.50 | %d+ | %d+ |\n", s)
            assert.matches("\n| `rp%-tail` Tail | 1–5 | все 3 | 1%.00–1%.50 | [%d%.–]+ | %d+–%d+ | %d+–%d+ |\n", s)
            -- shared path: the turn-in without a complete step once, for all three routes
            s = section(m, "Общие шаги")
            local _, rows = s:gsub("`turnin%-no%-complete`", "")
            assert.equal(1, rows)
            has(s, "| WARN | rp-tail#2 id=rp-364-in (Segments/Tail.lua) | `turnin-no-complete` | все 3 | ")
            -- the acknowledged gate: accepted, one row, the kills as a range over the three routes
            has(s, "<details><summary>Принятые предупреждения на общих шагах, `ok` (1)</summary>")
            assert.matches("| rp%-tail#%d+ id=rp%-gate %(Segments/Tail%.lua%) | `level%-grind` | все 3 | level 4 %+50%%: "
                .. "simulated level [%d%.]+–[%d%.]+ is short by %d+–%d+ XP; ~%d+–%d+ same%-level kills", s)
            hasNot(s, "rp-pal-train")
            -- gate matrix: the shared gates with their routes and the ceiling
            s = section(m, "Пороги уровня на общих шагах")
            assert.matches("\n| 4 %+50%% | rp%-tail#%d+ id=rp%-gate | все 3 | %d+ | %d+ | %d+ | 9000 |\n", s)
            assert.matches("\n| 1 %+50%% | rp%-start%-b#2 id=rp%-b%-gate | `rp%-undead%-warrior`, `rp%-undead%-mage` | ", s)
            assert.matches("\n| 2 | rp%-tail#%d+ id=rp%-war%-gate | `rp%-undead%-warrior` | ", s)
            -- route sections: the class step's warning only in the paladin's section
            local pal = routeSection(m, "rp-undead-paladin")
            assert.matches("\n| WARN | %[library FastesBoooy_RpGuides%] rp%-tail#%d+ id=rp%-pal%-train "
                .. "%(Classes/Paladin%.lua%) | `train%-no%-npc` | ", pal)
            hasNot(pal, "turnin-no-complete")
            has(routeSection(m, "rp-undead-mage"), "Собственных ошибок и предупреждений нет.")
            hasNot(m, "<summary>INFO")
            -- JSON: complete per route (the shared message in each of the three routes, INFO included)
            local rep = json.decode(readAll(js))
            local onPath, info, inserted = 0, 0, 0
            for _, r in ipairs(rep.routes) do
                for _, msg in ipairs(r.messages) do
                    if msg.code == "turnin-no-complete" then onPath = onPath + 1 end
                    if msg.severity == "INFO" then info = info + 1 end
                    if msg.inserted then inserted = inserted + 1 end
                end
            end
            assert.equal(3, onPath)
            assert.is_true(info > 0)
            assert.is_true(inserted > 0)
            -- text: the route's complete list
            local _, n = out:gsub("%[turnin%-no%-complete%]", "")
            assert.equal(3, n)
            -- deterministic
            local md2 = root .. "/rp2.md"
            run(("lua5.1 tools/validate_routes.lua --no-overrides -q --markdown '%s' '%s'"):format(md2, dir))
            assert.equal(m, readAll(md2))
        end)
    end)

    describe("the fixtures", function()
        it("a library module and the route that uses it: library steps are the shared path", function()
            local lib = Loader.LoadModule(H.LIB_DIR, { schema = schema })
            local all = { V.ValidateModule(H.LIB_DIR, { db = db, schema = schema, module = lib }),
                          V.ValidateModule(H.COMPOSED_DIR, { db = db, schema = schema }) }
            local md = markdown(all)
            has(section(md, "Модули и общие проверки"), "### Библиотека FastesBoooy_TestLib")
            local s = section(md, "Сравнение путей")
            has(s, "| `tl-deathknell` ")
            has(md, "\n### test-composed — ")
            -- the per-route insert that matches no profile is the route's own message
            assert.matches("`step%-no%-profile`", md:sub((md:find("\n## Маршруты\n", 1, true))))
            hasNot(section(md, "Общие шаги"), "step-no-profile")
        end)

        it("the Guides fixture: three clean routes, two start chains without a common tail", function()
            local md = markdown({ V.ValidateModule(H.GUIDES_DIR, { db = db, schema = schema }) })
            has(md, "**Итого: 0 ERROR, 0 WARN, ")
            has(section(md, "Модули и общие проверки"), "### Общая часть модуля FastesBoooy_TestGuides")
            local s = section(md, "Сравнение путей")
            has(s, "Общего хвоста у маршрутов нет")
            has(s, "| `tg-ud-01-deathknell` | `tg-undead-paladin` | ")
            has(s, "| `tg-dur-01-valley-of-trials` | `tg-orc-warrior`, `tg-troll-mage` | ")
            has(section(md, "Общие шаги"), "Ошибок и предупреждений на общих шагах нет.")
            for _, id in ipairs(H.GUIDES_ROUTES) do
                has(routeSection(md, id), "Собственных ошибок и предупреждений нет.")
            end
        end)
    end)
end)
