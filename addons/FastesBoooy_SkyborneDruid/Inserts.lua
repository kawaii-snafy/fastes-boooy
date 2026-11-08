-- FastesBoooy_SkyborneDruid / Inserts.lua
-- Druid class steps for the shared Horde 22-60 path (FastesBoooy_Horde, UseSegments in Route.lua):
-- the Moonglade -> Thunder Bluff bridge, class training 24-60 (Travel Form at 30, Dire Bear Form at 40), the
-- optional Zephras Isle riding trip at 40 and the Torwa Pathfinder chain in Un'Goro (9063 -> 9052 -> 9051).
-- Sources: research druid60.md / druid60.json (trainers, spells by level, training plan, talents, mount, class
-- quests), plan60.json bridges + classInserts.DRUID, docs/routes/horde-22-60.md section 10 (anchor levels);
-- NPCs / objects / quests: tools/data/forever_db.lua; ruRU names: Wowhead Forever ru tooltips.
--
-- Where the visits go (validator level at the insert, normal / worst case = no optional step done):
--   bridge  before h-22-tb-start          22.14        Bunthen Plainswind (druid-only flight) Moonglade -> Thunder
--                                                      Bluff: the 1-22 route ends at Loganaar; the hearthstone
--                                                      (Thunder Bluff) is kept for the end of h-22.
--   24      after  h-24-tb-arrive         24.95/24.05  Turak (Elder Rise); next library step is Tah (other NPC).
--   26+28   before h-28-thunder-bluff     28.76/28.22  Turak, on the way back from Skywatcher Plateau (the plan's
--                                                      anchor h-28-tb-arrive is only 27.97 in the worst case).
--   30      after  h-31-tb-end            31.01        Turak next to Magatha: TRAVEL FORM. 30 comes in the
--                                                      Shimmering Flats (h-27 #115), but the hearthstone is
--                                                      reserved for the Flats -> Thunder Bluff hearth there.
--   32      after  h-33-tarrenmill-end    32.07/31.86  Teleport: Moonglade + hearth to Tarren Mill (the library
--                                                      binds it there and keeps it for this visit).
--   34+36   before h38-hearth-shadowprey  37.69/37.70  Moonglade right before the library's own hearth (no extra
--                                                      hearth use: Teleport, train, then the library hearth).
--   38+40   after  h-40-org-arrive        40.06/40.01  fly Thunder Bluff, Turak: DIRE BEAR FORM; optional riding
--                                                      trip (Skywatcher Plateau skycutter -> Zephras Isle, Genn
--                                                      Fairweather, Apprentice Riding 100 g) and back to Tal, then
--                                                      the library flight to Camp Taurajo.
--   42+44   before h44-hearth-gromgol     44.52/44.51  Moonglade before the library hearth (instead of the plan's
--                                                      Kargath hearth at 44.02: that would put the h44-hearth-gromgol
--                                                      hearth half a level later on cooldown).
--   46+48   after  h-50-mojache-end       49.40/49.36  Jannos Lighthoof in Camp Mojache (h-48-mojache-arrive is
--                                                      only 47.19).
--   50+52   before h54-hearth-org         53.05/53.03  Moonglade before the library hearth (Azshara -> Orgrimmar):
--                                                      also accept 9063 Torwa Pathfinder there (optional: a
--                                                      breadcrumb of 9052, not its prerequisite).
--   Torwa   after  h-53-torwa-pathfinder  53.15        9063 > 9052 (Bloodcaps on the loop, Gorishi Stings at the
--                                                      edge of the hive before h54-torwa-3), 9052 > 9051 at
--                                                      h54-torwa-3, Devilsaur stab in loop 2 (bg), 9051 at
--                                                      h55-torwa-end. 9053 (Sunken Temple) is not taken: the route's
--                                                      optional Sunken Temple run is in h-50, before 9051.
--   54      before h56-hearth-gadgetzan   55.04        Moonglade before the library hearth (the plan's slot before
--                                                      h-55-cenarionhold-arrive would need a second Gadgetzan hearth
--                                                      0.1 level after h55-hearth-gadgetzan).
--   56      before h-58-org-arrive        57.21/57.17  Moonglade before the library hearth (Felwood -> Orgrimmar).
--   58+60   after  h-60-end               60.00        Moonglade: the route ends there.
-- Not visited: 26, 34, 38, 42, 46, 50, 58 on their own (merged into the next visit: medium-priority sets).
-- Automation: no inserted transient step (train, fly, go, hearth) is followed by an accept at the same NPC within
-- 6 steps (the 9063 accept comes before the level 52 training, not after it); the Torwa steps are stateful.
-- Hearthstone: only the level 32 visit uses it beyond the library (Tarren Mill, bound at h-31-tarrenmill-arrive,
-- otherwise unused); every other Moonglade visit sits right before a library hearth step, and the bridge and the
-- level 40 trip use flights / the skycutter.

local R = "horde-skyborne-druid"
local TURAK = { 1456, 76.48, 27.22 }
local LOGANAAR = { 1450, 52.53, 40.57 }

------------------------------------------------------------------------------
-- Bridge: Moonglade (end of the 1-22 route) -> Thunder Bluff (start of h-22)
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    before = "h-22-tb-start",
    steps = {
        { id = "sd-bridge-fly-tb", fly = "Thunder Bluff", npc = 2995, at = { 1456, 47.00, 49.83 },
          note = {
              ru = "Лунная поляна: Бунтен Ветер Равнин (44.3, 45.9; летает только с друидами) - полёт в Громовой "
                  .. "Утёс. Камень возвращения (Громовой Утёс) не тратьте: он нужен в конце Хилсбрада (Мельница Таррен "
                  .. "-> Громовой Утёс). Если Оргриммар уже есть на карте полётов, дальше летите от Тала прямо туда и "
                  .. "пропустите шаги через Перекрёсток.",
              en = "Moonglade: Bunthen Plainswind (44.3, 45.9; flies druids only) - fly to Thunder Bluff. Keep the "
                  .. "hearthstone (Thunder Bluff): it is used at the end of Hillsbrad (Tarren Mill -> Thunder Bluff). "
                  .. "If Orgrimmar is already on your flight map, fly from Tal straight there later and skip the "
                  .. "Crossroads steps.",
          } },
    },
})

------------------------------------------------------------------------------
-- 24: Thunder Bluff (Turak)
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    after = "h-24-tb-arrive",
    steps = {
        { id = "dru-train-24", train = true, npc = 3033, at = TURAK,
          spells = {
              { ru = "Свирепый укус", en = "Ferocious Bite" },
              { ru = "Глубокая рана", en = "Rake" },
              { ru = "Размах (2), Восстановление (3), Шипы (3) - по желанию", en = "Swipe (2), Regrowth (3), Thorns (3) - optional" },
          },
          note = {
              ru = "Через мосты на Вершину Старейшин: Тюрак Рунический Тотем - обучение 24-го уровня (главное - "
                  .. "«Свирепый укус» и «Глубокая рана»). Таланты 23-24: Острые когти (Sharpened Claws) 2/2.",
              en = "Over the bridges to Elder Rise: Turak Runetotem - level 24 training (Ferocious Bite and Rake matter "
                  .. "most). Talents 23-24: Sharpened Claws 2/2.",
          } },
    },
})

------------------------------------------------------------------------------
-- 26 + 28: Thunder Bluff (Turak), back from Skywatcher Plateau
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    before = "h-28-thunder-bluff",
    steps = {
        { id = "dru-train-28", train = true, npc = 3033, at = TURAK,
          spells = {
              { ru = "Когти (2)", en = "Claw (Rank 2)" },
              { ru = "Разорвать (2)", en = "Rip (Rank 2)" },
              { ru = "Порыв", en = "Dash" },
              { ru = "Трепка (3)", en = "Maul (Rank 3)" },
              { ru = "Омоложение (5)", en = "Rejuvenation (Rank 5)" },
          },
          note = {
              ru = "Наверху - сначала на Вершину Старейшин: Тюрак, обучение 26-го и 28-го уровней (главное - «Когти» "
                  .. "и «Разорвать»). Ещё нет 28-го - выучите 26-й, остальное на 30-м. Таланты 25-28: Удары хищника "
                  .. "(Predatory Strikes) 3/3, Blood Frenzy 1/2.",
              en = "At the top go to Elder Rise first: Turak, level 26 and 28 training (Claw and Rip matter most). Not "
                  .. "28 yet: learn the 26 spells, the rest at 30. Talents 25-28: Predatory Strikes 3/3, Blood Frenzy "
                  .. "1/2.",
          } },
    },
})

------------------------------------------------------------------------------
-- 30: Thunder Bluff (Turak, next to Magatha): Travel Form
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    after = "h-31-tb-end",
    steps = {
        { id = "dru-train-30", train = true, npc = 3033, at = TURAK,
          spells = {
              { ru = "Походный облик", en = "Travel Form" },
              { ru = "Полоснуть (2)", en = "Shred (Rank 2)" },
              { ru = "Знак дикой природы (4)", en = "Mark of the Wild (Rank 4)" },
              { ru = "Восстановление (4)", en = "Regrowth (Rank 4)" },
              { ru = "Оглушить (2), Волшебный огонь (2) - по желанию", en = "Bash (2), Faerie Fire (2) - optional" },
          },
          note = {
              ru = "Рядом с Магатой: Тюрак - обучение 30-го уровня, ПОХОДНЫЙ ОБЛИК (+40% к скорости на открытой "
                  .. "местности: дальше передвигайтесь в нём). Таланты 29-31: Blood Frenzy 2/2, Вожак стаи (Leader of "
                  .. "the Pack), Natural Instinct 1/2.",
              en = "Next to Magatha: Turak - level 30 training, TRAVEL FORM (+40% speed outdoors: travel in it from now "
                  .. "on). Talents 29-31: Blood Frenzy 2/2, Leader of the Pack, Natural Instinct 1/2.",
          } },
    },
})

------------------------------------------------------------------------------
-- 32: Teleport: Moonglade from Tarren Mill, hearth back
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    after = "h-33-tarrenmill-end",
    steps = {
        { id = "dru-train-32", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Свирепый укус (2)", en = "Ferocious Bite (Rank 2)" },
              { ru = "Собранность", en = "Poised" },
              { ru = "Накинуться, Деморализующий рёв (3) - по желанию", en = "Ravage, Demoralizing Roar (3) - optional" },
          },
          note = {
              ru = "«Телепортация: Лунная поляна» прямо в Мельнице Таррен. Логанаар: обучение 32-го уровня (главное - "
                  .. "«Свирепый укус» 2 и «Собранность»). Ещё нет 32-го - выучите, что есть, остальное на 36-м. "
                  .. "Таланты 32: Natural Instinct 2/2.",
              en = "Cast Teleport: Moonglade right in Tarren Mill. Loganaar: level 32 training (Ferocious Bite 2 and "
                  .. "Poised matter most). Not 32 yet: learn what is offered, the rest at 36. Talents 32: Natural "
                  .. "Instinct 2/2.",
          } },
        { id = "dru-hearth-32", hearth = "Tarren Mill", at = { 1424, 62.78, 19.03 },
          note = {
              ru = "Камень возвращения в Мельницу Таррен (привязан на 31-м и с тех пор не использовался). Дальше - на "
                  .. "юго-восток к Стене Торадина.",
              en = "Hearth to Tarren Mill (bound at 31 and unused since). Then south-east to Thoradin's Wall.",
          } },
    },
})

------------------------------------------------------------------------------
-- 34 + 36: Moonglade right before the library hearth to Shadowprey Village
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    before = "h38-hearth-shadowprey",
    steps = {
        { id = "dru-train-36", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Разорвать (3)", en = "Rip (Rank 3)" },
              { ru = "Глубокая рана (2)", en = "Rake (Rank 2)" },
              { ru = "Неистовое восстановление", en = "Frenzied Regeneration" },
              { ru = "Трепка (4), Размах (3)", en = "Maul (Rank 4), Swipe (Rank 3)" },
              { ru = "Восстановление (5), Омоложение (6)", en = "Regrowth (Rank 5), Rejuvenation (Rank 6)" },
          },
          note = {
              ru = "Следующий шаг - камень. Камень готов: «Телепортация: Лунная поляна», Логанаар - обучение 34-го и "
                  .. "36-го уровней (главное - «Разорвать» 3 и «Глубокая рана» 2; пропущенное на 32-м - тоже). Камень "
                  .. "на откате - пропустите (выучите на 40-м). Таланты 33-37: Predatory Discipline, Гнев (Furor) 1/5, "
                  .. "Rend and Tear 3/5.",
              en = "The next step is the hearthstone. If it is ready: cast Teleport: Moonglade, Loganaar - level 34 and "
                  .. "36 training (Rip 3 and Rake 2 matter most; anything missed at 32 too). Hearthstone on cooldown: "
                  .. "skip (learn it at 40). Talents 33-37: Predatory Discipline, Furor 1/5, Rend and Tear 3/5.",
          } },
    },
})

------------------------------------------------------------------------------
-- 38 + 40: fly Thunder Bluff (Turak): Dire Bear Form; optional riding trip to Zephras Isle
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    after = "h-40-org-arrive",
    steps = {
        { id = "dru-fly-tb-40", fly = "Thunder Bluff", npc = 2995, at = { 1456, 47.00, 49.83 },
          note = {
              ru = "Дорас на башне в Долине Силы: летите в Громовой Утёс (обучение 40-го и поездка за верховой "
                  .. "ездой). В Лагерь Таурахо полетите уже оттуда.",
              en = "Doras on the tower in the Valley of Strength: fly to Thunder Bluff (level 40 training and the "
                  .. "riding trip). You fly on to Camp Taurajo from there.",
          } },
        { id = "dru-train-40", train = true, npc = 3033, at = TURAK,
          spells = {
              { ru = "Облик лютого медведя", en = "Dire Bear Form" },
              { ru = "Свирепый укус (3)", en = "Ferocious Bite (Rank 3)" },
              { ru = "Когти (3), Полоснуть (3)", en = "Claw (Rank 3), Shred (Rank 3)" },
              { ru = "Крадущийся зверь (2), Кошачья грация", en = "Prowl (Rank 2), Feline Grace" },
              { ru = "Знак дикой природы (5), Озарение", en = "Mark of the Wild (Rank 5), Innervate" },
          },
          note = {
              ru = "Через мосты на Вершину Старейшин: Тюрак - обучение 38-го и 40-го уровней: ОБЛИК ЛЮТОГО МЕДВЕДЯ, "
                  .. "«Свирепый укус» 3, «Когти» 3, «Полоснуть» 3. Таланты 38-40: Rend and Tear 5/5, Переходящая сила "
                  .. "(Shifting Power).",
              en = "Over the bridges to Elder Rise: Turak - level 38 and 40 training: DIRE BEAR FORM, Ferocious Bite 3, "
                  .. "Claw 3, Shred 3. Talents 38-40: Rend and Tear 5/5, Shifting Power.",
          } },
        { id = "dru-riding-path", go = true, optional = true, radius = 25, at = { 1412, 40.30, 17.60 },
          note = {
              ru = "По желанию, если есть 100 з.: верховая езда на острове Зефрас (~15-20 мин; ездовое животное даёт "
                  .. "+60% против +40% у походного облика). На лифте вниз, на север вдоль утёса к горной тропе и по "
                  .. "ней на Небесное плато. Нет денег - пропустите этот и 4 следующих шага (поездку можно сделать "
                  .. "позже из Громового Утёса).",
              en = "Optional, if you have 100 g: riding on Zephras Isle (~15-20 min; a mount is +60% against +40% for "
                  .. "Travel Form). Take the lift down, run north along the bluff to the mountain path and up to "
                  .. "Skywatcher Plateau. No gold: skip this and the next 4 steps (you can make the trip later from "
                  .. "Thunder Bluff).",
          } },
        { id = "dru-riding-skycutter", go = true, optional = true, radius = 40, npc = 259119,
          at = { 1412, 33.40, 22.55 },
          note = {
              ru = "Небесное плато, причал Ваятелей ветра (Алаана Штормовой Полет): небесный корабль до острова "
                  .. "Зефрас (Небесные доки Валанаара).",
              en = "Skywatcher Plateau, the Windshaper dock (Alaana Stormwalker): the skycutter to Zephras Isle "
                  .. "(Valanaar Skydocks).",
          } },
        -- Genn Fairweather is the Skyborne riding trainer, not a druid trainer.
        { id = "dru-riding", train = true, optional = true, npc = 265756, -- WARN-OK: train-not-class-trainer
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
        { id = "dru-riding-back", go = true, optional = true, radius = 15, npc = 275270, at = { 2521, 57.92, 80.78 },
          note = {
              ru = "Обратно к Небесным докам (начальник порта Ваятелей ветра): небесный корабль до Мулгора. Корабля "
                  .. "обратно нет - камень в Оргриммар и полёт в Лагерь Таурахо (следующий шаг пропустите; в конце "
                  .. "Пылевых топей камень может быть ещё на откате - тогда летите из Деревни Гиблотопь).",
              en = "Back to the Valanaar Skydocks (Windshapers Dockmaster): the skycutter to Mulgore. No ship back: "
                  .. "hearth to Orgrimmar and fly to Camp Taurajo (skip the next step; at the end of Dustwallow the "
                  .. "hearthstone may still be on cooldown - then fly from Brackenwall Village).",
          } },
        { id = "dru-riding-tb", go = true, optional = true, radius = 15, npc = 2995, at = { 1456, 47.00, 49.83 },
          note = {
              ru = "С плато спланируйте «Шагом по воздуху» с восточного края (или спуститесь горной тропой), верхом к "
                  .. "лифту Громового Утёса и наверх к Талу: полёт в Лагерь Таурахо.",
              en = "From the plateau glide down the east edge with Walk on Air (or take the mountain path), ride to the "
                  .. "Thunder Bluff lift and up to Tal: fly to Camp Taurajo.",
          } },
    },
})

------------------------------------------------------------------------------
-- 42 + 44: Moonglade right before the library hearth to Grom'gol (Swamp of Sorrows)
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    before = "h44-hearth-gromgol",
    steps = {
        { id = "dru-train-44", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Глубокая рана (3)", en = "Rake (Rank 3)" },
              { ru = "Разорвать (4)", en = "Rip (Rank 4)" },
              { ru = "Дубовая кожа", en = "Barkskin" },
              { ru = "Трепка (5), Размах (4)", en = "Maul (Rank 5), Swipe (Rank 4)" },
              { ru = "Восстановление (6)", en = "Regrowth (Rank 6)" },
          },
          note = {
              ru = "Следующий шаг - камень. Камень готов: «Телепортация: Лунная поляна», Логанаар - обучение 42-го и "
                  .. "44-го уровней (главное - «Глубокая рана» 3 и «Разорвать» 4). Камень на откате - пропустите "
                  .. "(выучите на 48-м). Таланты 41-44: Сердце дикой природы (Heart of the Wild) 4/5.",
              en = "The next step is the hearthstone. If it is ready: cast Teleport: Moonglade, Loganaar - level 42 and "
                  .. "44 training (Rake 3 and Rip 4 matter most). Hearthstone on cooldown: skip (learn it at 48). "
                  .. "Talents 41-44: Heart of the Wild 4/5.",
          } },
    },
})

------------------------------------------------------------------------------
-- 46 + 48: Camp Mojache (Jannos Lighthoof)
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    after = "h-50-mojache-end",
    steps = {
        { id = "dru-train-48", train = true, npc = 8142, at = { 1444, 75.99, 42.28 },
          spells = {
              { ru = "Когти (4)", en = "Claw (Rank 4)" },
              { ru = "Свирепый укус (4)", en = "Ferocious Bite (Rank 4)" },
              { ru = "Полоснуть (4), Порыв (2)", en = "Shred (Rank 4), Dash (Rank 2)" },
              { ru = "Оглушить (3)", en = "Bash (Rank 3)" },
              { ru = "Восстановление (7), Омоложение (8)", en = "Regrowth (Rank 7), Rejuvenation (Rank 8)" },
          },
          note = {
              ru = "В лагере: Джаннос Легкое Копыто - обучение 46-го и 48-го уровней (главное - «Когти» 4 и "
                  .. "«Свирепый укус» 4). Таланты 45-49: Сердце дикой природы (Heart of the Wild) 5/5, Натуралист "
                  .. "(Naturalist) 4/5.",
              en = "In the camp: Jannos Lighthoof - level 46 and 48 training (Claw 4 and Ferocious Bite 4 matter most). "
                  .. "Talents 45-49: Heart of the Wild 5/5, Naturalist 4/5.",
          } },
    },
})

------------------------------------------------------------------------------
-- 50 + 52: Moonglade right before the library hearth to Orgrimmar (Azshara); accept 9063
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    before = "h54-hearth-org",
    steps = {
        -- 9063 is only a breadcrumb of 9052 (DB: breadcrumbFor = 9052, 9052 has no prerequisite): optional here and
        -- at Torwa, so a skipped visit does not block the chain. The accept comes before the training step: an accept
        -- after it at the same NPC would make the engine forward the training before the trainer window opens.
        { id = "dru-accept-9063", accept = 9063, optional = true, npc = 12042, at = LOGANAAR,
          note = {
              ru = "Следующие шаги - обучение и камень. Камень готов: «Телепортация: Лунная поляна», Логанаар - задание "
                  .. "друидов «Землепроходец Торва» (к нему в кратер Ун'Горо). Камень на откате - пропустите этот и "
                  .. "следующий шаг (обучение на 54-м; Торва даст своё задание и без этого).",
              en = "Next: the training and the hearthstone. If it is ready: cast Teleport: Moonglade, Loganaar - the "
                  .. "druid quest Torwa Pathfinder (to him in Un'Goro Crater). Hearthstone on cooldown: skip this and the "
                  .. "next step (train at 54; Torwa gives his quest without it too).",
          } },
        { id = "dru-train-52", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Разорвать (5)", en = "Rip (Rank 5)" },
              { ru = "Трепка (6)", en = "Maul (Rank 6)" },
              { ru = "Знак дикой природы (6)", en = "Mark of the Wild (Rank 6)" },
              { ru = "Омоложение (9)", en = "Rejuvenation (Rank 9)" },
          },
          note = {
              ru = "Логанаар: обучение 50-го и 52-го уровней (главное - «Разорвать» 5). Таланты 50-53: Натуралист "
                  .. "(Naturalist) 5/5, Genesis 3/5.",
              en = "Loganaar: level 50 and 52 training (Rip 5 matters most). Talents 50-53: Naturalist 5/5, Genesis "
                  .. "3/5.",
          } },
    },
})

------------------------------------------------------------------------------
-- Torwa Pathfinder (Un'Goro): 9063 > 9052 Bloodpetal Poison > 9051 Toxic Test
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    after = "h-53-torwa-pathfinder",
    steps = {
        { id = "dru-torwa-9063", turnin = 9063, optional = true, npc = 9619, at = { 1449, 71.64, 75.96 },
          note = {
              ru = "Если брали в Лунной поляне: сдайте ему «Землепроходца Торву».",
              en = "If you took it in Moonglade: turn in Torwa Pathfinder to him.",
          } },
        { id = "dru-torwa-9052", accept = 9052, npc = 9619, at = { 1449, 71.64, 75.96 },
          note = {
              ru = "У него же задание друидов «Яд кровоцвета»: 8 кровошляпочников и 8 жал Гориши.",
              en = "From him too, the druid quest Bloodpetal Poison: 8 Bloodcaps and 8 Gorishi Stings.",
          } },
        { id = "dru-bloodcap", complete = { [9052] = { 2 } }, bg = true, object = 164958, at = { 1449, 66.43, 32.87 },
          note = {
              ru = "Попутно по всему кратеру: 8 кровошляпочников с побегов кровоцвета (маленькие красные растения).",
              en = "On the way all over the crater: 8 Bloodcaps from Bloodpetal Sprouts (small red plants).",
          } },
    },
})
FastesBoooy.AddInsert(R, {
    before = "h54-torwa-3",
    steps = {
        { id = "dru-gorishi-stings", complete = 9052, at = { 1449, 53.68, 76.31 },
          note = {
              ru = "От плота на запад к краю улья Гориши: осы и рабочие из улья (51-52) - 8 жал Гориши. Доберите "
                  .. "кровошляпочники, затем на восток к Торве.",
              en = "From the raft west to the edge of the Gorishi hive: Gorishi Wasps and Workers (51-52) - 8 Gorishi "
                  .. "Stings. Finish the Bloodcaps, then east to Torwa.",
          } },
    },
})
FastesBoooy.AddInsert(R, {
    after = "h54-torwa-3",
    steps = {
        { id = "dru-torwa-9051", turnin = 9052, accept = 9051, npc = 9619, at = { 1449, 71.64, 75.96 },
          note = {
              ru = "Торва: «Яд кровоцвета», возьмите «Испытание яда» (шип девизавра - в сумке).",
              en = "Torwa: Bloodpetal Poison; take Toxic Test (the Devilsaur Barb goes into your bags).",
          } },
        { id = "dru-devilsaur", complete = 9051, bg = true, use = 22432, at = { 1449, 31.19, 36.42 },
          note = {
              ru = "Попутно во 2-й петле: девизавры (элита 54-56) бродят на западе (31, 36; к северу от горячих "
                  .. "источников) и в центре (50, 61). Подкрадитесь, уколите шипом девизавра и уходите (Порыв, "
                  .. "походный облик) - убивать не нужно.",
              en = "On the way in loop 2: Devilsaurs (elite 54-56) roam the west (31, 36; north of the hot springs) and "
                  .. "the centre (50, 61). Sneak up, stab one with the Devilsaur Barb and get away (Dash, Travel Form) - "
                  .. "no kill needed.",
          } },
    },
})
FastesBoooy.AddInsert(R, {
    after = "h55-torwa-end",
    steps = {
        { id = "dru-torwa-end", turnin = 9051, npc = 9619, at = { 1449, 71.64, 75.96 },
          note = {
              ru = "Торва: «Испытание яда». «Лучший ингредиент» (Затонувший храм) не берите.",
              en = "Torwa: Toxic Test. Skip A Better Ingredient (Sunken Temple).",
          } },
    },
})

------------------------------------------------------------------------------
-- 54: Moonglade right before the library hearth to Gadgetzan (start of h-56)
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    before = "h56-hearth-gadgetzan",
    steps = {
        { id = "dru-train-54", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Глубокая рана (4)", en = "Rake (Rank 4)" },
              { ru = "Полоснуть (5)", en = "Shred (Rank 5)" },
              { ru = "Восстановление (8)", en = "Regrowth (Rank 8)" },
              { ru = "Размах (5)", en = "Swipe (Rank 5)" },
          },
          note = {
              ru = "Следующий шаг - камень. Камень готов: «Телепортация: Лунная поляна», Логанаар - обучение 54-го "
                  .. "уровня (и 50-52-го, если пропустили). Камень на откате - пропустите (выучите на 56-м). Таланты "
                  .. "54-55: Genesis 5/5.",
              en = "The next step is the hearthstone. If it is ready: cast Teleport: Moonglade, Loganaar - level 54 "
                  .. "training (and 50-52 if you missed it). Hearthstone on cooldown: skip (learn it at 56). Talents "
                  .. "54-55: Genesis 5/5.",
          } },
    },
})

------------------------------------------------------------------------------
-- 56: Moonglade right before the library hearth to Orgrimmar (Felwood)
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    before = "h-58-org-arrive",
    steps = {
        { id = "dru-train-56", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Свирепый укус (5)", en = "Ferocious Bite (Rank 5)" },
              { ru = "Наскок (3), Целительное прикосновение (10) - по желанию",
                en = "Pounce (3), Healing Touch (10) - optional" },
          },
          note = {
              ru = "Следующий шаг - камень. Камень готов: «Телепортация: Лунная поляна», Логанаар - обучение 56-го "
                  .. "уровня («Свирепый укус» 5; и 54-го, если пропустили). Камень на откате - пропустите (выучите на "
                  .. "60-м). Таланты 56-57: Прирожденный оборотень (Natural Shapeshifter) 2/3.",
              en = "The next step is the hearthstone. If it is ready: cast Teleport: Moonglade, Loganaar - level 56 "
                  .. "training (Ferocious Bite 5; and 54 if you missed it). Hearthstone on cooldown: skip (learn it at "
                  .. "60). Talents 56-57: Natural Shapeshifter 2/3.",
          } },
    },
})

------------------------------------------------------------------------------
-- 58 + 60: Moonglade at the end of the route
------------------------------------------------------------------------------
FastesBoooy.AddInsert(R, {
    after = "h-60-end",
    steps = {
        { id = "dru-train-60", train = true, npc = 12042, at = LOGANAAR,
          spells = {
              { ru = "Когти (5), Трепка (7)", en = "Claw (Rank 5), Maul (Rank 7)" },
              { ru = "Разорвать (6), Свирепый укус (6)", en = "Rip (Rank 6), Ferocious Bite (Rank 6)" },
              { ru = "Крадущийся зверь (3)", en = "Prowl (Rank 3)" },
              { ru = "Знак дикой природы (7), Восстановление (9)", en = "Mark of the Wild (Rank 7), Regrowth (Rank 9)" },
          },
          note = {
              ru = "«Телепортация: Лунная поляна», Логанаар: обучение 58-го и 60-го уровней. Таланты 58-60: "
                  .. "Прирожденный оборотень (Natural Shapeshifter) 3/3, Nature's Majesty 2/2. Конец маршрута 1-60.",
              en = "Cast Teleport: Moonglade, Loganaar: level 58 and 60 training. Talents 58-60: Natural Shapeshifter "
                  .. "3/3, Nature's Majesty 2/2. End of the 1-60 route.",
          } },
    },
})
