-- tools/lib/report.lua -- the Markdown report of the route validator (docs/VALIDATION.md, make report).
--
-- Input: the module results of a validator run (lib/validator.lua: V.ValidateModule /
-- V.ValidateHarness / V.OverrideChecks). The text and JSON outputs keep the complete view of every
-- route; this report aggregates, so that 28 routes over one shared path stay readable:
--
--   1. header and totals (messages, and how many rows are left once the shared path is shown once)
--   2. module entries: load errors, the template checks of a module's shared content, DB overrides
--   3. route summary: one row per route x profile
--   4. path comparison: the start chains (the segments before the common tail of all routes) with the
--      level at the merge point and the grind kills up to it, then every segment with the range of
--      its entry level, end level and grind kills over the routes that use it
--   5. shared path: every ERROR / WARN on a step of a shared SEGMENT once, key (severity, code, step
--      id or segment, quest id), with a "routes" column; numbers that depend on the run are shown as
--      a range (the texts are merged number by number)
--   6. gate matrix: the `level` gates on shared steps x kills (min / max over the routes, the worst
--      case) and the ceiling of their `ok`
--   7. one section per route: its simulation line, its own gates, a compact segment table and the
--      messages that are NOT on the shared path -- the route's own steps and inserts and the steps of
--      shared inserts (the class and race files) -- plus the INFO count per code
--   8. INFO per code over all routes (the INFO texts are in --json and -v only)
--   9. the static "only in game" list and the generated list of the accepted (`ok`)
--      db-override-unverified warnings
--
-- "Shared path" = a message with m.shared and without m.inserted (lib/validator.lua, Run:addx).
-- Everything is deterministic: routes in run order, keys in order of first appearance.

local Report = {}

local format = string.format

local DASH = "–" -- en dash, for ranges
local NONE = "—" -- em dash, for "no value"

local function mdEscape(s)
    return (tostring(s):gsub("|", "\\|"):gsub("\n", " "))
end
Report.Escape = mdEscape

local function textOf(t)
    if type(t) == "table" then return t.en or t.ru or "" end
    return t and tostring(t) or ""
end

---------------------------------------------------------------------------
-- small helpers
---------------------------------------------------------------------------

-- min / max accumulator
local function newAcc() return { n = 0 } end
local function accAdd(a, v)
    if v == nil then return end
    a.n = a.n + 1
    if a.min == nil or v < a.min then a.min = v end
    if a.max == nil or v > a.max then a.max = v end
end

--- "12.34" when both ends print the same, else "12.34–13.01"; "—" without a value.
local function range(a, fmt)
    if not a or a.min == nil then return NONE end
    local lo, hi = format(fmt, a.min), format(fmt, a.max)
    if lo == hi then return lo end
    return lo .. DASH .. hi
end
Report.Range = range

-- split a text into the parts between its numbers and the numbers ("12", "30.21")
local function splitNumbers(text)
    local parts, nums = {}, {}
    local pos = 1
    while true do
        local s, e = text:find("%d+", pos)
        if not s then break end
        if text:sub(e + 1, e + 1) == "." and text:sub(e + 2, e + 2):match("%d") then
            local _, e2 = text:find("^%d+", e + 2)
            e = e2
        end
        parts[#parts + 1] = text:sub(pos, s - 1)
        nums[#nums + 1] = text:sub(s, e)
        pos = e + 1
    end
    parts[#parts + 1] = text:sub(pos)
    return parts, nums
end

--- One text for the same message reported by several routes. Identical texts: that text. Texts that
-- differ only in numbers (the simulated level, the XP shortfall, the kill count): the text with every
-- differing number as a range "109–131". Otherwise the first text and the number of variants.
-- @return text, number of distinct texts, merged (false when the texts differ in more than numbers)
function Report.MergeTexts(texts)
    local first = texts[1] or ""
    local seen, variants = {}, 0
    for _, t in ipairs(texts) do
        if not seen[t] then
            seen[t] = true
            variants = variants + 1
        end
    end
    if variants <= 1 then return first, variants, true end
    local parts, nums = splitNumbers(first)
    local lo, hi = {}, {}
    for i, n in ipairs(nums) do lo[i], hi[i] = n, n end
    for i = 2, #texts do
        local p, n = splitNumbers(texts[i])
        if #p ~= #parts then return first, variants, false end
        for j = 1, #p do
            if p[j] ~= parts[j] then return first, variants, false end
        end
        for j, v in ipairs(n) do
            if tonumber(v) < tonumber(lo[j]) then lo[j] = v end
            if tonumber(v) > tonumber(hi[j]) then hi[j] = v end
        end
    end
    local out = {}
    for i, part in ipairs(parts) do
        out[#out + 1] = part
        if nums[i] then
            out[#out + 1] = lo[i] == hi[i] and lo[i] or (lo[i] .. DASH .. hi[i])
        end
    end
    return table.concat(out), variants, true
end

--- The "routes" column: which of the runs of the report a row is about.
--   every run            "все 28" (a single run: its id)
--   whole groups         "все 7 `troll-*`", "все 5 `*-warrior`" (ids grouped by the part before the
--                        first / after the last "-"; at most three groups of at least two routes)
--   otherwise            up to three ids and the number of the others
-- @param set { [label] = true }; @param universe array of all run labels, in run order
function Report.RouteSet(set, universe)
    local n = 0
    for _, label in ipairs(universe) do
        if set[label] then n = n + 1 end
    end
    if n == 0 then return NONE end
    if n == #universe then
        if n == 1 then return "`" .. universe[1] .. "`" end
        return format("все %d", n)
    end
    for _, how in ipairs({ "prefix", "suffix" }) do
        local groups, order, ok = {}, {}, true
        for _, label in ipairs(universe) do
            local id = label:match("^[^ ]+") or label -- a label may end in " [profile]"
            local key
            if how == "prefix" then key = id:match("^([^-]+)%-") else key = id:match("%-([^-]+)$") end
            if key then
                local g = groups[key]
                if not g then
                    g = { all = 0, hit = 0 }
                    groups[key] = g
                    order[#order + 1] = key
                end
                g.all = g.all + 1
                if set[label] then g.hit = g.hit + 1 end
            elseif set[label] then
                ok = false
            end
        end
        local parts = {}
        for _, key in ipairs(order) do
            local g = groups[key]
            if g.hit > 0 then
                if g.hit ~= g.all or g.all < 2 then
                    ok = false
                    break
                end
                parts[#parts + 1] = format("все %d `%s`", g.all, how == "prefix" and (key .. "-*") or ("*-" .. key))
            end
        end
        if ok and #parts > 0 and #parts <= 3 then return table.concat(parts, ", ") end
    end
    local names = {}
    for _, label in ipairs(universe) do
        if set[label] then names[#names + 1] = label end
    end
    local shown = {}
    for i = 1, math.min(3, #names) do shown[i] = "`" .. names[i] .. "`" end
    local s = table.concat(shown, ", ")
    if #names > 3 then s = s .. format(" и ещё %d", #names - 3) end
    return s
end

-- "segment#step id=x (file)" without the library tag (the tables say which part they are about)
local function locOf(V, m)
    return V.LocStr({ segment = m.segment, step = m.step, stepId = m.stepId, file = m.file })
end

-- is the message about a step of the shared path (a base step of a shared segment, or the segment)?
local function onSharedPath(m)
    return m.shared == true and not m.inserted
end
Report.OnSharedPath = onSharedPath

---------------------------------------------------------------------------
-- collecting
---------------------------------------------------------------------------

-- runs = results of real runs (route x profile); entries = everything else (library / shared /
-- overrides / load-error entries)
local function collect(all)
    local runs, entries, count = {}, {}, {}
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results or {}) do
            if r.summary and r.summary.endLevel then
                runs[#runs + 1] = { r = r, mres = mres }
                local id = tostring(r.route)
                count[id] = (count[id] or 0) + 1
            else
                entries[#entries + 1] = { r = r, mres = mres }
            end
        end
    end
    local labels = {}
    for i, run in ipairs(runs) do
        local id = tostring(run.r.route)
        run.label = count[id] > 1 and (id .. " [" .. tostring(run.r.profileLabel) .. "]") or id
        labels[i] = run.label
    end
    return runs, entries, labels
end

-- the segments of all runs: the common tail (the longest common suffix of the segment chains) and
-- the start chains in front of it
local function paths(runs)
    local chains = {}
    for i, run in ipairs(runs) do
        local c = {}
        for j, s in ipairs(run.r.segments or {}) do c[j] = tostring(s.id) end
        chains[i] = c
    end
    local tail = 0
    if #runs >= 2 then
        while true do
            local id
            local same = true
            for _, c in ipairs(chains) do
                local v = c[#c - tail]
                if v == nil or (id ~= nil and v ~= id) then
                    same = false
                    break
                end
                id = v
            end
            if not same then break end
            tail = tail + 1
        end
    end
    return chains, tail
end

-- grouped ERROR / WARN of the shared path. @return unaccepted groups, accepted groups (arrays in
-- order of first appearance; a group: { m = first message, set = { [label] = true }, texts = {...} })
local function sharedGroups(runs)
    local lists = { [false] = {}, [true] = {} }
    local index = { [false] = {}, [true] = {} }
    for _, run in ipairs(runs) do
        local nth = {}
        for _, m in ipairs(run.r.messages or {}) do
            if m.severity ~= "INFO" and onSharedPath(m) then
                local accepted = m.accepted == true
                local base = table.concat({ m.severity, tostring(m.code),
                    tostring(m.stepId or (m.segment and ("segment " .. tostring(m.segment))) or "-"),
                    tostring(m.quest or "") }, "\0")
                -- the same key twice in one run (two NPCs of one step): the n-th of each run together
                nth[base] = (nth[base] or 0) + 1
                local key = base .. "\0" .. nth[base]
                local g = index[accepted][key]
                if not g then
                    g = { m = m, set = {}, texts = {} }
                    index[accepted][key] = g
                    lists[accepted][#lists[accepted] + 1] = g
                end
                if not g.set[run.label] then
                    g.set[run.label] = true
                    g.texts[#g.texts + 1] = m.msg
                end
            end
        end
    end
    return lists[false], lists[true]
end

local function groupText(g)
    local text, variants, merged = Report.MergeTexts(g.texts)
    if not merged then
        text = text .. format(" _(текст различается по маршрутам: вариантов %d, показан первый)_", variants)
    end
    return text
end

---------------------------------------------------------------------------
-- sections
---------------------------------------------------------------------------

local function sectionEntries(V, w, entries, all)
    local shown = false
    local function head()
        if not shown then
            w("## Модули и общие проверки")
            w("")
            shown = true
        end
    end
    for _, e in ipairs(entries) do
        local r, mres = e.r, e.mres
        head()
        if r.library then
            w(format("### Библиотека %s", mdEscape(mres.module)))
            w("")
            w(format("Модуль общих сегментов (%s): шаги проверяются в маршрутах, которые их используют "
                .. "(`UseSegments`). Результат: **%d ERROR, %d WARN, %d INFO**.", mdEscape(r.profileLabel),
                r.counts.ERROR, r.counts.WARN, r.counts.INFO))
        elseif r.shared then
            w(format("### Общая часть модуля %s", mdEscape(mres.module)))
            w("")
            w(format("Проверки шаблонов (%s): общие сегменты и общие вставки (`AddLibraryInsert`) проверяются "
                .. "один раз для всех маршрутов. Результат: **%d ERROR, %d WARN, %d INFO**.",
                mdEscape(r.profileLabel), r.counts.ERROR, r.counts.WARN, r.counts.INFO))
        elseif r.overrides then
            w("### Поправки к БД (`tools/overrides`)")
            w("")
            w(format("Результат: **%d ERROR, %d WARN, %d INFO**.", r.counts.ERROR, r.counts.WARN, r.counts.INFO))
        else
            w(format("### %s", mdEscape(r.route)))
            w("")
            w(format("Модуль `%s`. Результат: **%d ERROR, %d WARN, %d INFO**.", tostring(mres.module), r.counts.ERROR,
                r.counts.WARN, r.counts.INFO))
        end
        w("")
        local n = 0
        for _, m in ipairs(r.messages) do
            if m.severity ~= "INFO" and not m.accepted then
                if n == 0 then
                    w("| уровень | где | код | сообщение |")
                    w("|---|---|---|---|")
                end
                n = n + 1
                w(format("| %s | %s | `%s` | %s |", m.severity, mdEscape(V.LocStr(m)), m.code, mdEscape(m.msg)))
            end
        end
        if n == 0 then w("Ошибок и предупреждений нет.") end
        w("")
        if (r.acceptedWarn or 0) > 0 then
            w(format("<details><summary>Принятые предупреждения, `ok` (%d)</summary>", r.acceptedWarn))
            w("")
            for _, m in ipairs(r.messages) do
                if m.accepted then w(format("- %s `%s` %s", mdEscape(V.LocStr(m)), m.code, mdEscape(m.msg))) end
            end
            w("")
            w("</details>")
            w("")
        end
    end
    -- messages that do not count (partial loads, --route)
    local notes = {}
    for _, mres in ipairs(all) do
        for _, line in ipairs(V.NoteLines(mres)) do notes[#notes + 1] = line end
    end
    if #notes > 0 then
        head()
        w("### Заметки (не входят в итог)")
        w("")
        for _, line in ipairs(notes) do w("- " .. mdEscape((line:gsub("^%s+", "")))) end
        w("")
    end
end

local function sectionSummary(V, w, runs)
    local bp = V.DEFAULTS.incidentalBandPct
    local bh = tostring(bp)
    w("## Сводка по маршрутам")
    w("")
    w(format("Строка на маршрут × профиль. «Худший» — прогон, в котором шаги `optional = true` и их квесты не "
        .. "выполнены. Гринд — убийства мобов своего уровня до порогов `level`; «+%d %%» — то же с попутными "
        .. "убийствами в пути на %d %% опыта квестов. «Оценён опыт» — квесты, опыт которых в БД неизвестен "
        .. "(медиана по уровню), и их доля в опыте квестов.", bp, bp))
    w("")
    w(format("| маршрут | профиль | ERROR | WARN | принято | конец | худший конец | гринд | худший гринд | гринд +%d %% | "
        .. "худший +%d %% | оценён опыт | журнал | шагов | необязательных |", bp, bp))
    w("|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
    for _, run in ipairs(runs) do
        local r = run.r
        local sm = r.summary
        local band = sm.band and sm.band[bh] or {}
        w(format("| `%s` | %s | %d | %d | %d | %.2f | %.2f | %d | %d | %d | %d | %d (%.1f %%) | %d | %d | %d |",
            mdEscape(r.route), mdEscape(r.profileLabel), r.counts.ERROR, r.counts.WARN, r.acceptedWarn or 0,
            sm.endLevel, sm.endLevelWorst or sm.endLevel, sm.grindKills or 0, sm.grindKillsWorst or sm.grindKills or 0,
            band.grindKills or 0, band.grindKillsWorst or 0, sm.unknownXpQuests or 0, sm.xpQuestEstimatedPct or 0,
            sm.maxQuestLog or 0, sm.steps or 0, sm.optionalSkipped or 0))
    end
    w("")
end

local function sectionPaths(w, runs, labels)
    local chains, tail = paths(runs)
    w("## Сравнение путей")
    w("")
    -- start chains: the segments in front of the common tail
    if #runs >= 2 then
        local groups, order = {}, {}
        for i, run in ipairs(runs) do
            local c = chains[i]
            local n = #c - tail
            local ids = {}
            for j = 1, n do ids[j] = c[j] end
            local key = table.concat(ids, "\0")
            local g = groups[key]
            if not g then
                g = { ids = ids, set = {}, level = newAcc(), kills = newAcc(), worst = newAcc() }
                groups[key] = g
                order[#order + 1] = g
            end
            g.set[run.label] = true
            local segs = run.r.segments
            local k, kw = 0, 0
            for j = 1, n do
                k = k + (segs[j].grindKills or 0)
                kw = kw + (segs[j].grindKillsWorst or segs[j].grindKills or 0)
            end
            local merge = segs[n + 1]
            accAdd(g.level, merge and merge.startLevel or run.r.summary.endLevel)
            accAdd(g.kills, k)
            accAdd(g.worst, kw)
        end
        local mergeId = tail > 0 and chains[1][#chains[1] - tail + 1] or nil
        if mergeId then
            w(format("Общий хвост всех маршрутов — %d сегм., начиная с `%s` (точка слияния). Стартовый участок — "
                .. "сегменты маршрута до неё: уровень на входе в `%s` и гринд до этого места (мин–макс по маршрутам "
                .. "участка).", tail, mdEscape(mergeId), mdEscape(mergeId)))
        else
            w("Общего хвоста у маршрутов нет: каждый стартовый участок — весь маршрут (уровень — в конце маршрута).")
        end
        w("")
        w("| стартовый участок | маршруты | уровень в точке слияния | гринд до неё | худший случай |")
        w("|---|---|---:|---:|---:|")
        for _, g in ipairs(order) do
            local ids = {}
            for j, id in ipairs(g.ids) do ids[j] = "`" .. mdEscape(id) .. "`" end
            w(format("| %s | %s | %s | %s | %s |", #ids > 0 and table.concat(ids, ", ") or "(сразу общий хвост)",
                Report.RouteSet(g.set, labels), range(g.level, "%.2f"), range(g.kills, "%d"), range(g.worst, "%d")))
        end
        w("")
    end
    -- every segment: ranges over the routes that use it (start segments first, then the common tail)
    local segs, order = {}, {}
    local function visit(run, s, isTail)
        local id = tostring(s.id)
        local e = segs[id]
        if not e then
            e = { s = s, set = {}, entry = newAcc(), exit = newAcc(), kills = newAcc(), worst = newAcc(), tail = isTail }
            segs[id] = e
            order[#order + 1] = e
        end
        e.set[run.label] = true
        accAdd(e.entry, s.startLevel)
        accAdd(e.exit, s.endLevel)
        accAdd(e.kills, s.grindKills or 0)
        accAdd(e.worst, s.grindKillsWorst or s.grindKills or 0)
    end
    for pass = 1, 2 do
        for _, run in ipairs(runs) do
            local list = run.r.segments or {}
            local first = #list - tail + 1
            for j, s in ipairs(list) do
                if (pass == 1) == (j < first) then visit(run, s, j >= first) end
            end
        end
    end
    w("Сегменты: уровень на входе и в конце и гринд (убийств) — мин–макс по маршрутам, которые проходят сегмент.")
    w("")
    w("| сегмент | план | маршруты | уровень на входе | уровень в конце | гринд | худший случай |")
    w("|---|---|---|---:|---:|---:|---:|")
    for _, e in ipairs(order) do
        local s = e.s
        w(format("| `%s` %s | %s | %s | %s | %s | %s | %s |", mdEscape(s.id), mdEscape(textOf(s.title)),
            s.levels and format("%d%s%d", s.levels[1], DASH, s.levels[2]) or NONE, Report.RouteSet(e.set, labels),
            range(e.entry, "%.2f"), range(e.exit, "%.2f"), range(e.kills, "%d"), range(e.worst, "%d")))
    end
    w("")
end

local function sectionShared(V, w, runs, labels, open, accepted)
    w("## Общие шаги")
    w("")
    w("ERROR и WARN на шагах общих сегментов — по одной строке на (уровень, код, шаг или сегмент, квест) со списком "
        .. "маршрутов. Числа, которые зависят от прогона (симулированный уровень, недобор опыта, число убийств), "
        .. "показаны диапазоном по маршрутам.")
    w("")
    if #open == 0 then
        w(#runs > 0 and "Ошибок и предупреждений на общих шагах нет." or "Маршрутов нет.")
        w("")
    else
        w("| уровень | где | код | маршруты | сообщение |")
        w("|---|---|---|---|---|")
        for _, g in ipairs(open) do
            w(format("| %s | %s | `%s` | %s | %s |", g.m.severity, mdEscape(locOf(V, g.m)), g.m.code,
                Report.RouteSet(g.set, labels), mdEscape(groupText(g))))
        end
        w("")
    end
    if #accepted > 0 then
        w(format("<details><summary>Принятые предупреждения на общих шагах, `ok` (%d)</summary>", #accepted))
        w("")
        w("| где | код | маршруты | сообщение |")
        w("|---|---|---|---|")
        for _, g in ipairs(accepted) do
            w(format("| %s | `%s` | %s | %s |", mdEscape(locOf(V, g.m)), g.m.code, Report.RouteSet(g.set, labels),
                mdEscape(groupText(g))))
        end
        w("")
        w("</details>")
        w("")
    end
end

local function sectionGates(V, w, runs, labels)
    local gates, order = {}, {}
    for _, run in ipairs(runs) do
        for _, g in ipairs(run.r.summary.gates or {}) do
            if g.library then
                local key = tostring(g.stepId or (tostring(g.segment) .. "#" .. tostring(g.step)))
                local e = gates[key]
                if not e then
                    e = { g = g, set = {}, kills = newAcc(), worst = newAcc(), n = #order + 1 }
                    gates[key] = e
                    order[#order + 1] = e
                end
                e.set[run.label] = true
                accAdd(e.kills, g.kills or 0)
                if not g.optional then accAdd(e.worst, g.killsWorst or 0) end
                if g.okCeiling and (not e.ceiling or g.okCeiling > e.ceiling) then e.ceiling = g.okCeiling end
            end
        end
    end
    if #order == 0 then return end
    table.sort(order, function(a, b)
        local la, lb = a.g.level + (a.g.frac or 0), b.g.level + (b.g.frac or 0)
        if la ~= lb then return la < lb end
        return a.n < b.n
    end)
    w("## Пороги уровня на общих шагах")
    w("")
    w(format("Шаги `level` общих сегментов и общих вставок: сколько убийств мобов своего уровня нужно до порога — "
        .. "минимум и максимум по маршрутам в обычном прогоне и максимум в худшем случае (шаги `optional` не "
        .. "выполнены; у необязательного порога «%s»). Потолок — число из `ok = { [\"level-grind\"] = N }` шага: "
        .. "предупреждение `level-grind` (больше %d убийств) принято, пока убийств не больше N.", NONE,
        V.DEFAULTS.grindWarnKills))
    w("")
    w("| порог | шаг | маршруты | мин | макс | худший случай | потолок `ok` |")
    w("|---|---|---|---:|---:|---:|---:|")
    for _, e in ipairs(order) do
        local g = e.g
        w(format("| %s%s | %s | %s | %d | %d | %s | %s |", V.GateLevel(g), g.optional and " (необязательный)" or "",
            mdEscape(V.LocStr({ segment = g.segment, step = g.step, stepId = g.stepId })), Report.RouteSet(e.set, labels),
            e.kills.min or 0, e.kills.max or 0, e.worst.max and tostring(e.worst.max) or NONE,
            e.ceiling and tostring(e.ceiling) or NONE))
    end
    w("")
end

-- "`code` 12, `other` 3" (sorted by code)
local function codeCounts(counts)
    local codes = {}
    for code in pairs(counts) do codes[#codes + 1] = code end
    table.sort(codes)
    local parts = {}
    for i, code in ipairs(codes) do parts[i] = format("`%s` %d", code, counts[code]) end
    return table.concat(parts, ", ")
end

local function sectionRoutes(V, w, runs, db)
    if #runs == 0 then return end
    local bp = V.DEFAULTS.incidentalBandPct
    local b0, bh = tostring(0), tostring(bp)
    local function band(b, key, field) return (b and b[key] and b[key][field]) or 0 end
    w("## Маршруты")
    w("")
    w("В разделе маршрута — только его собственные сообщения: шаги самого маршрута и вставок класса и расы "
        .. "(`AddInsert`, `AddLibraryInsert`). Сообщения о шагах общих сегментов — в разделе «Общие шаги».")
    w("")
    for _, run in ipairs(runs) do
        local r, mres = run.r, run.mres
        local sm = r.summary
        w(format("### %s — %s", mdEscape(run.label), mdEscape(textOf(r.title))))
        w("")
        local pathE, pathW, pathA = 0, 0, 0
        local info = {}
        for _, m in ipairs(r.messages) do
            if m.severity == "INFO" then
                info[m.code] = (info[m.code] or 0) + 1
            elseif onSharedPath(m) then
                if m.accepted then
                    pathA = pathA + 1
                elseif m.severity == "ERROR" then
                    pathE = pathE + 1
                else
                    pathW = pathW + 1
                end
            end
        end
        w(format("Модуль `%s`, профиль: %s. Результат: **%d ERROR, %d WARN, %d INFO**%s%s.", tostring(mres.module),
            r.profileLabel, r.counts.ERROR, r.counts.WARN, r.counts.INFO,
            (r.acceptedWarn or 0) > 0 and format("; принято предупреждений (`ok`): %d", r.acceptedWarn) or "",
            (pathE + pathW + pathA) > 0 and format("; из них на общих шагах: %d ERROR, %d WARN, принято %d", pathE,
                pathW, pathA) or ""))
        w("")
        w(format("Симуляция: конец маршрута на уровне **%.2f** (оптимистично %.2f; план %s); опыт квестов %d "
            .. "(из них оценено %d; "
            .. "квестов с оценённым опытом: %d, %.1f %% опыта квестов), за убийства по целям %d, гринд %d "
            .. "(~%d убийств); максимум квестов в журнале %d из %d; принято %d, сдано %d, не сдано к концу %d.",
            sm.endLevel, sm.endLevelOptimistic or sm.endLevel,
            sm.plannedLevels and tostring(sm.plannedLevels[2]) or NONE, sm.xpQuest or 0,
            sm.xpQuestEstimated or 0, sm.unknownXpQuests or 0, sm.xpQuestEstimatedPct or 0, sm.xpKill or 0,
            sm.xpGrind or 0, sm.grindKills or 0, sm.maxQuestLog or 0,
            db.questLogSize or 40, sm.accepts or 0, sm.turnins or 0, #(sm.carried or {})))
        w("")
        if sm.band then
            w(format("Гринд до порогов уровня (шаги `level`): ~%d убийств мобов своего уровня%s; худший случай "
                .. "(не выполнены шаги `optional = true` — %d — и их квесты): ~%d. С попутными убийствами в пути на %d %% "
                .. "опыта квестов: ~%d (худший случай ~%d).", sm.grindKills or 0,
                (sm.incidentalPct or 0) > 0 and format(" (попутные убийства %g %% опыта квестов)", sm.incidentalPct) or "",
                sm.optionalSkipped or 0, sm.grindKillsWorst or 0, bp, band(sm.band, bh, "grindKills"),
                band(sm.band, bh, "grindKillsWorst")))
            w("")
            -- the route's own gates (the gates on shared steps are in the gate matrix)
            local n = 0
            for _, g in ipairs(sm.gates or {}) do
                if not g.library then
                    if n == 0 then
                        w(format("| порог уровня | шаг | убийств | худший случай | +%d %% | худший +%d %% |", bp, bp))
                        w("|---|---|---:|---:|---:|---:|")
                    end
                    n = n + 1
                    local function worst(key) return g.optional and NONE or tostring(band(g.band, key, "worst")) end
                    w(format("| %s%s | %s | %d | %s | %d | %s |", V.GateLevel(g), g.optional and " (необязательный)" or "",
                        mdEscape(V.LocStr({ segment = g.segment, step = g.step, stepId = g.stepId })),
                        band(g.band, b0, "kills"), worst(b0), band(g.band, bh, "kills"), worst(bh)))
                end
            end
            if n > 0 then w("") end
        end
        if #(r.segments or {}) > 0 then
            w("| сегмент | план | уровень (симуляция) | опыт квестов | опыт мобов | гринд (худший) | журнал |")
            w("|---|---|---|---:|---:|---:|---:|")
            for _, s in ipairs(r.segments) do
                w(format("| `%s` | %s | %.2f → %.2f | %d | %d | %d (%d) | %d |", mdEscape(s.id),
                    s.levels and format("%d%s%d", s.levels[1], DASH, s.levels[2]) or NONE, s.startLevel or 0,
                    s.endLevel or 0, s.xpQuest or 0, s.xpKill or 0, s.grindKills or 0,
                    s.grindKillsWorst or s.grindKills or 0, s.questLog or 0))
            end
            w("")
        end
        local shown, ownAccepted = 0, 0
        for _, m in ipairs(r.messages) do
            if m.severity ~= "INFO" and not onSharedPath(m) then
                if m.accepted then
                    ownAccepted = ownAccepted + 1
                else
                    if shown == 0 then
                        w("| уровень | где | код | сообщение |")
                        w("|---|---|---|---|")
                    end
                    shown = shown + 1
                    w(format("| %s | %s | `%s` | %s |", m.severity, mdEscape(V.LocStr(m)), m.code, mdEscape(m.msg)))
                end
            end
        end
        if shown == 0 then w("Собственных ошибок и предупреждений нет.") end
        w("")
        if ownAccepted > 0 then
            w(format("<details><summary>Принятые предупреждения, `ok` (%d)</summary>", ownAccepted))
            w("")
            for _, m in ipairs(r.messages) do
                if m.accepted and not onSharedPath(m) then
                    w(format("- %s `%s` %s", mdEscape(V.LocStr(m)), m.code, mdEscape(m.msg)))
                end
            end
            w("")
            w("</details>")
            w("")
        end
        if next(info) ~= nil then
            w(format("INFO (%d): %s.", r.counts.INFO, codeCounts(info)))
            w("")
        end
    end
end

local function sectionInfo(w, runs)
    local codes, order = {}, {}
    for i, run in ipairs(runs) do
        for _, m in ipairs(run.r.messages or {}) do
            if m.severity == "INFO" then
                local e = codes[m.code]
                if not e then
                    e = { code = m.code, total = 0, per = {} }
                    codes[m.code] = e
                    order[#order + 1] = e
                end
                e.total = e.total + 1
                e.per[i] = (e.per[i] or 0) + 1
            end
        end
    end
    if #order == 0 then return end
    table.sort(order, function(a, b) return a.code < b.code end)
    w("## INFO по кодам")
    w("")
    w("Справочные сообщения в отчёт не выводятся — только их число. Тексты: `lua5.1 tools/validate_routes.lua -v` или "
        .. "`--json FILE`.")
    w("")
    w("| код | всего | маршрутов | на маршрут (мин–макс) |")
    w("|---|---:|---:|---:|")
    for _, e in ipairs(order) do
        local a, n = newAcc(), 0
        for i = 1, #runs do
            if e.per[i] then
                n = n + 1
                accAdd(a, e.per[i])
            end
        end
        w(format("| `%s` | %d | %d | %s |", e.code, e.total, n, range(a, "%d")))
    end
    w("")
end

local function sectionInGame(V, w, runs, labels)
    w("## Что подтверждается только в игре")
    w("")
    w("Офлайн-проверки (luacheck по списку API Forever, строгий мок клиента, валидатор по снимку БД, "
        .. "симуляция маршрутов) этого не покрывают:")
    w("")
    for _, item in ipairs(V.IN_GAME_ONLY) do w("* " .. item) end
    w("")
    -- accepted db-override-unverified: a step passes a check only because of an unverified DB override
    local groups, order = {}, {}
    for _, run in ipairs(runs) do
        for _, m in ipairs(run.r.messages or {}) do
            if m.code == "db-override-unverified" and m.accepted then
                local key = table.concat({ tostring(m.stepId or m.segment or "-"), tostring(m.quest or ""),
                    tostring(m.npc or ""), tostring(m.msg) }, "\0")
                local g = groups[key]
                if not g then
                    g = { m = m, set = {} }
                    groups[key] = g
                    order[#order + 1] = g
                end
                g.set[run.label] = true
            end
        end
    end
    w("### Принятые непроверенные поправки к БД")
    w("")
    if #order == 0 then
        w("Шагов, которые проходят проверку только благодаря непроверенной поправке к БД (`tools/overrides`, "
            .. "`verified = false`) и приняты ключом `ok = \"db-override-unverified\"`, нет.")
    else
        w(format("Шаги, которые проходят проверку только благодаря поправке к БД с `verified = false` "
            .. "(`tools/overrides`) и приняты ключом `ok` (%d). Каждую нужно подтвердить в клиенте Forever "
            .. "(комментарий `-- CONFIRM:` на шаге) и после этого поставить поправке `verified = true`:", #order))
        w("")
        w("| где | маршруты | сообщение |")
        w("|---|---|---|")
        for _, g in ipairs(order) do
            w(format("| %s | %s | %s |", mdEscape(locOf(V, g.m)), Report.RouteSet(g.set, labels), mdEscape(g.m.msg)))
        end
    end
    w("")
end

---------------------------------------------------------------------------
-- the report
---------------------------------------------------------------------------

--- Markdown lines of the report.
-- @param V lib.validator (LocStr, GateLevel, NoteLines, DEFAULTS, IN_GAME_ONLY)
-- @param all module results; @param db the DB snapshot (meta, questLogSize)
function Report.Markdown(V, all, db)
    local L = {}
    local function w(s) L[#L + 1] = s end
    local meta = db.meta or {}
    local runs, entries, labels = collect(all)
    local open, accepted = sharedGroups(runs)

    w("# Отчёт валидатора маршрутов")
    w("")
    w("<!-- GENERATED by tools/validate_routes.lua --markdown docs/VALIDATION.md (make report). DO NOT EDIT. -->")
    w("")
    w(format("Снимок БД: World of Warcraft: Forever %s.%s (Interface %s), дата снимка %s, `%s`.",
        tostring(meta.build and meta.build[1]), tostring(meta.build and meta.build[2]), tostring(meta.interface),
        tostring(meta.generated), "tools/data/forever_db.lua"))
    w("")
    w("Как читать: **ERROR** — маршрут сломан (квест недоступен, не тот NPC, нарушена цепочка, переполнен журнал, "
        .. "уровень ниже требуемого); **WARN** — вероятная проблема (NPC далеко от точки `at`, большой гринд до порога "
        .. "уровня, квест не сдан к концу маршрута); предупреждение, принятое автором ключом `ok` на шаге или "
        .. "сегменте, считается отдельно («принято»); **INFO** — справка (оценки опыта, квесты с неизвестным опытом), "
        .. "в отчёте только числом по кодам. Симуляция опыта — оценка: опыт квестов из БД (для новых квестов Forever — "
        .. "медиана по уровню), опыт за мобов — формула Classic со штрафом Forever за «зелёных» мобов, без "
        .. "rested-бонуса.")
    w("")
    w("Отчёт сводный: сообщения о шагах общих сегментов показаны один раз для всех маршрутов (раздел «Общие шаги»), "
        .. "в разделе маршрута — только его собственные. Полный список по каждому маршруту: "
        .. "`lua5.1 tools/validate_routes.lua --route <id>` (с `-v` — и INFO) или `--json FILE`.")
    w("")
    w("Перегенерировать: `make report` (или `lua5.1 tools/validate_routes.lua --markdown docs/VALIDATION.md`).")
    w("")
    local te, tw, ti, ta = 0, 0, 0, 0
    for _, mres in ipairs(all) do
        for _, r in ipairs(mres.results or {}) do
            te, tw, ti = te + r.counts.ERROR, tw + r.counts.WARN, ti + r.counts.INFO
            ta = ta + (r.acceptedWarn or 0)
        end
    end
    w(format("**Итого: %d ERROR, %d WARN, %d INFO%s.**", te, tw, ti,
        ta > 0 and format("; принято предупреждений (`ok`): %d", ta) or ""))
    w("")
    if #all == 0 then
        w("_Модули маршрутов не найдены._")
        w("")
    end
    if #runs > 0 then
        -- rows of this report: the shared path once, everything else per route / entry
        local onPath = 0
        for _, run in ipairs(runs) do
            for _, m in ipairs(run.r.messages or {}) do
                if m.severity ~= "INFO" and not m.accepted and onSharedPath(m) then onPath = onPath + 1 end
            end
        end
        w(format("Прогонов (маршрут × профиль): %d. ERROR и WARN без повторов: %d из %d (сообщений о шагах общих "
            .. "сегментов: %d, строк в разделе «Общие шаги»: %d).", #runs, te + tw - onPath + #open, te + tw, onPath,
            #open))
        w("")
    end
    sectionEntries(V, w, entries, all)
    if #runs > 0 then
        sectionSummary(V, w, runs)
        sectionPaths(w, runs, labels)
        sectionShared(V, w, runs, labels, open, accepted)
        sectionGates(V, w, runs, labels)
        sectionRoutes(V, w, runs, db)
        sectionInfo(w, runs)
    end
    sectionInGame(V, w, runs, labels)
    return L
end

return Report
