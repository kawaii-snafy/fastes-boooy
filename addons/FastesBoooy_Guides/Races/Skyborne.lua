-- FastesBoooy_Guides / Races / Skyborne.lua
-- The steps that exist because of the race (Skyborne) on the shared path, as shared inserts with race scope; step
-- ids "sky-...".
--   Orgrimmar     Thrall 95350 > 98024 (the racial pair of the Skyborne who joined the Horde) and the optional 1061
--                 at Zor Lonetree next to him (needs level 13: the other races pass him at 11-12), before
--                 h12-org-end; 98024 is turned in at Thork (before h15-xr-thork), 1061 at Seereth on the Stonetalon
--                 border (before h18-border; it is the breadcrumb of 1062).
--   Riding at 40  Genn Fairweather on Zephras Isle (stablemaster and riding trainer), reached by skycutter from
--                 Skywatcher Plateau: the whole trip is optional (100 gold, 15-20 min). docs/dev/PLAN.md C.7: the
--                 druid's level-40 block already flies to Thunder Bluff and on to Camp Taurajo, so for druids the
--                 riding steps sit between dru-40-train and dru-40-fly-taurajo (Classes/Druid.lua): both inserts
--                 are `after = "h-40-org-arrive"` and the class file is registered first.
--                 The other classes (hunter, rogue, shaman, warrior) get the same trip as a self-contained
--                 optional detour after h-40-org-arrive: sky-40-fly-tb, the riding steps, sky-40-fly-taurajo (the
--                 next shared step is the flight Orgrimmar -> Camp Taurajo: it completes on the same landing; with
--                 the detour skipped it is flown from Orgrimmar as written).
-- The racial quests of the start zone itself (92474 Walk on Air, 92598 Skysight, 95350 at its end) are steps of
-- the Zephras segments: only Skyborne walk them.
if not FastesBoooy.AddLibraryInsert then return end

------------------------------------------------------------------------------
-- Orgrimmar: Thrall, Zor Lonetree
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h12-org-end",
    race = "Skyborne",
    steps = {
        { id = "sky-thrall", turnin = 95350, accept = 98024, npc = 4949, at = { 1454, 31.73, 37.82 },
          note = { ru = "Тралл в крепости Громмаш (Аллея Мудрости): сдайте «Добро пожаловать в Азерот» и возьмите «Путь на "
                       .. "Перекрёсток» (сдадите Торку на Перекрёстке).",
                   en = "Thrall in Grommash Hold (the Valley of Wisdom): hand in Welcome to Azeroth and take Journey to the "
                       .. "Crossroads (handed in to Thork at the Crossroads)." } },
        { id = "sky-1061", accept = 1061, optional = true, npc = 4047, at = { 1454, 38.93, 38.40 },
          note = { ru = "Зор Одинокое Древо по пути из Аллеи Мудрости к воротам: «Духи Когтистых гор» (сдадите Сирет на границе "
                       .. "Когтистых гор на 19-м). Нужен 13-й уровень: ниже 13-го Зор задание не предлагает - пропустите шаг.",
                   en = "Zor Lonetree on the way out of the Valley of Wisdom: The Spirits of Stonetalon (handed in at Seereth on the "
                       .. "Stonetalon border at 19). Needs level 13: below 13 Zor does not offer it - skip the step." } },
    },
})

------------------------------------------------------------------------------
-- The Crossroads: 98024
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h15-xr-thork",
    race = "Skyborne",
    steps = {
        { id = "sky-98024-thork", turnin = 98024, npc = 3429, at = { 1413, 51.50, 30.87 },
          note = { ru = "Торк у западного дома: «Путь на Перекрёсток» (задание Тралла).",
                   en = "Thork at the west building: Journey to the Crossroads (Thrall's quest)." } },
    },
})

------------------------------------------------------------------------------
-- Stonetalon border: 1061
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    before = "h18-border",
    race = "Skyborne",
    steps = {
        { id = "sky-1061-turnin", turnin = 1061, optional = true, npc = 4049, at = { 1413, 35.26, 27.88 },
          note = { ru = "Сирет Камнелом на границе Когтистых гор: сдайте «Духов Когтистых гор», если взяли их в Оргриммаре; нет - "
                       .. "пропустите шаг.",
                   en = "Seereth Stonebreak on the Stonetalon border: hand in The Spirits of Stonetalon if you took it in Orgrimmar; "
                       .. "otherwise skip the step." } },
    },
})

------------------------------------------------------------------------------
-- 40, druids: the optional riding trip to Zephras Isle, between the druid's training and its flight on.
-- The anchor is the shared step, not dru-40-train: the class file is registered first, so at h-40-org-arrive
-- its two steps (dru-40-fly-tb, dru-40-train) come first and these follow; dru-40-fly-taurajo is an insert of
-- its own in front of the next shared step. An anchor inside Classes/Druid.lua would be the id of no loaded
-- step in a base-profile run (--skip 'Classes/*': ERROR insert-anchor-unknown).
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h-40-org-arrive",
    race = "Skyborne",
    class = "DRUID",
    steps = {
        { id = "sky-40d-path", go = true, optional = true, radius = 25, at = { 1412, 40.30, 17.60 },
          note = {
              ru = "По желанию, на 40-м и со 100 з.: верховая езда на острове Зефрас (~15-20 мин; ездовое животное "
                  .. "даёт +60% против +40% у походного облика). На лифте вниз, на север вдоль утёса к горной тропе и "
                  .. "по ней на Небесное плато. Нет денег или 40-го - пропустите этот и 4 следующих шага, к Талу "
                  .. "(поездку можно сделать позже из Громового Утёса).",
              en = "Optional, at 40 with 100 g: riding on Zephras Isle (~15-20 min; a mount is +60% against +40% for "
                  .. "Travel Form). Take the lift down, run north along the bluff to the mountain path and up to "
                  .. "Skywatcher Plateau. No gold or not 40: skip this and the next 4 steps, on to Tal (you can make "
                  .. "the trip later from Thunder Bluff).",
          } },
        { id = "sky-40d-skycutter", go = true, optional = true, radius = 40, npc = 259119,
          at = { 1412, 33.40, 22.55 },
          note = {
              ru = "Небесное плато, причал Ваятелей ветра (Алаана Штормовой Полет): небесный корабль до острова "
                  .. "Зефрас (Небесные доки Валанаара; по веб-гайдам корабль стоит чуть ниже плато, 34.3, 25.8). "
                  .. "Корабля на Зефрас нет - пропустите 2 следующих шага и возвращайтесь к Талу (езда - позже).",
              en = "Skywatcher Plateau, the Windshaper dock (Alaana Stormwalker): the skycutter to Zephras Isle "
                  .. "(Valanaar Skydocks; web guides put the boat just below the plateau, 34.3, 25.8). No skycutter "
                  .. "to Zephras: skip the next 2 steps and go back to Tal (riding later).",
          } },
        -- Genn Fairweather is the Skyborne riding trainer (validator: INFO train-service).
        { id = "sky-40d-riding", train = true, optional = true, npc = 265756,
          at = { 2521, 53.83, 81.33 },
          spells = {
              { ru = "Верховая езда (ученик)", en = "Apprentice Riding" },
          },
          note = {
              ru = "С причала на запад к конюшням у Валанаара: Генн Чистое Небо - «Верховая езда (ученик)» (100 з.; "
                  .. "навык включает езду на галстрайдерах). В Forever ездовое животное выдаётся вместе с навыком; не "
                  .. "выдали - купите галстрайдера у него же.",
              en = "From the dock west to the stables by Valanaar: Genn Fairweather - Apprentice Riding (100 g; the "
                  .. "skill includes Galestrider Riding). Forever grants a mount with the skill; if it does not, buy a "
                  .. "Galestrider from him.",
          } },
        { id = "sky-40d-back", go = true, optional = true, radius = 15, npc = 275270, at = { 2521, 57.92, 80.78 },
          note = {
              ru = "Обратно к Небесным докам (начальник порта Ваятелей ветра): небесный корабль до Мулгора. Корабль "
                  .. "не ходит - пропустите этот шаг: «Телепортация: Лунная поляна», Бунтен Ветер Равнин (44.3, 45.9) "
                  .. "- полёт в Громовой Утёс, к Талу (следующий шаг). Камень не используйте: он на откате после "
                  .. "Деревни Ночных Охотников и привязан к Оргриммару для следующего сегмента.",
              en = "Back to the Valanaar Skydocks (Windshapers Dockmaster): the skycutter to Mulgore. Ship not "
                  .. "running: skip this step, cast Teleport: Moonglade, and Bunthen Plainswind (44.3, 45.9) flies you "
                  .. "to Thunder Bluff, to Tal (the next step). Do not hearth: it is on cooldown since Shadowprey and "
                  .. "stays bound to Orgrimmar for the next segment.",
          } },
        { id = "sky-40d-tb", go = true, optional = true, radius = 15, npc = 2995, at = { 1456, 47.00, 49.83 },
          note = {
              ru = "С плато спланируйте «Шагом по воздуху» с восточного края (или спуститесь горной тропой), верхом к "
                  .. "лифту Громового Утёса и наверх к Талу.",
              en = "From the plateau glide down the east edge with Walk on Air (or take the mountain path), ride to the "
                  .. "Thunder Bluff lift and up to Tal.",
          } },
    },
})

------------------------------------------------------------------------------
-- 40, the other classes: the same optional riding trip as a detour of its own (docs/dev/PLAN.md C.7)
------------------------------------------------------------------------------
FastesBoooy.AddLibraryInsert({
    after = "h-40-org-arrive",
    race = "Skyborne",
    class = { "HUNTER", "ROGUE", "SHAMAN", "WARRIOR" },
    steps = {
        { id = "sky-40-fly-tb", fly = "Thunder Bluff", optional = true, npc = 2995, at = { 1456, 47.00, 49.83 },
          note = {
              ru = "По желанию, на 40-м и со 100 з.: верховая езда на острове Зефрас (~20 мин туда и обратно; "
                  .. "ездовое животное даёт +60% к скорости). Дорас на башне в Долине Силы: летите в Громовой Утёс. "
                  .. "Нет денег или 40-го - пропустите этот и 6 следующих шагов и летите от Дораса сразу в Лагерь "
                  .. "Таурахо.",
              en = "Optional, at 40 with 100 g: riding on Zephras Isle (~20 min there and back; a mount is +60% "
                  .. "speed). Doras on the tower in the Valley of Strength: fly to Thunder Bluff. No gold or not 40: "
                  .. "skip this and the next 6 steps and fly from Doras straight to Camp Taurajo.",
          } },
        { id = "sky-40-path", go = true, optional = true, radius = 25, at = { 1412, 40.30, 17.60 },
          note = {
              ru = "На лифте вниз, на север вдоль утёса к горной тропе и по ней на Небесное плато.",
              en = "Take the lift down, run north along the bluff to the mountain path and up to Skywatcher "
                  .. "Plateau.",
          } },
        { id = "sky-40-skycutter", go = true, optional = true, radius = 40, npc = 259119,
          at = { 1412, 33.40, 22.55 },
          note = {
              ru = "Небесное плато, причал Ваятелей ветра (Алаана Штормовой Полет): небесный корабль до острова "
                  .. "Зефрас (Небесные доки Валанаара; по веб-гайдам корабль стоит чуть ниже плато, 34.3, 25.8). "
                  .. "Корабля на Зефрас нет - пропустите 2 следующих шага и возвращайтесь к Талу (езда - позже).",
              en = "Skywatcher Plateau, the Windshaper dock (Alaana Stormwalker): the skycutter to Zephras Isle "
                  .. "(Valanaar Skydocks; web guides put the boat just below the plateau, 34.3, 25.8). No skycutter "
                  .. "to Zephras: skip the next 2 steps and go back to Tal (riding later).",
          } },
        -- Genn Fairweather is the Skyborne riding trainer (validator: INFO train-service).
        { id = "sky-40-riding", train = true, optional = true, npc = 265756,
          at = { 2521, 53.83, 81.33 },
          spells = {
              { ru = "Верховая езда (ученик)", en = "Apprentice Riding" },
          },
          note = {
              ru = "С причала на запад к конюшням у Валанаара: Генн Чистое Небо - «Верховая езда (ученик)» (100 з.; "
                  .. "навык включает езду на галстрайдерах). В Forever ездовое животное выдаётся вместе с навыком; не "
                  .. "выдали - купите галстрайдера у него же.",
              en = "From the dock west to the stables by Valanaar: Genn Fairweather - Apprentice Riding (100 g; the "
                  .. "skill includes Galestrider Riding). Forever grants a mount with the skill; if it does not, buy a "
                  .. "Galestrider from him.",
          } },
        { id = "sky-40-back", go = true, optional = true, radius = 15, npc = 275270, at = { 2521, 57.92, 80.78 },
          note = {
              ru = "Обратно к Небесным докам (начальник порта Ваятелей ветра): небесный корабль до Мулгора. Камень "
                  .. "не используйте: он привязан к Оргриммару для следующего сегмента.",
              en = "Back to the Valanaar Skydocks (Windshapers Dockmaster): the skycutter to Mulgore. Do not hearth: "
                  .. "the stone stays bound to Orgrimmar for the next segment.",
          } },
        { id = "sky-40-tb", go = true, optional = true, radius = 15, npc = 2995, at = { 1456, 47.00, 49.83 },
          note = {
              ru = "С плато спланируйте «Шагом по воздуху» с восточного края (или спуститесь горной тропой), верхом к "
                  .. "лифту Громового Утёса и наверх к Талу.",
              en = "From the plateau glide down the east edge with Walk on Air (or take the mountain path), ride to the "
                  .. "Thunder Bluff lift and up to Tal.",
          } },
        -- The next shared step (h-38-orgrimmar-flight-master) is the same flight, written for Orgrimmar ("Doras"):
        -- it completes on the same landing (fly = arrival at `at`).
        { id = "sky-40-fly-taurajo", fly = "Camp Taurajo", optional = true, npc = 10378, at = { 1413, 44.45, 59.15 },
          note = {
              ru = "Тал на центральной вершине Громового Утёса (не Дорас: вы не в Оргриммаре): летите в Лагерь "
                  .. "Таурахо.",
              en = "Tal on the central mesa of Thunder Bluff (not Doras: you are not in Orgrimmar): fly to Camp "
                  .. "Taurajo.",
          } },
    },
})
