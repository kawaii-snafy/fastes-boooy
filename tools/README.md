# Офлайн-инструменты FastesBoooy

Всё, что проверяет аддон и маршруты **без запуска игры**: генераторы данных о клиенте
World of Warcraft: Forever (билд 1.60.1.70862, `## Interface: 16001`), снимок базы
квестов/NPC, валидатор маршрутов, генератор `Data.lua`, упаковка.

Требования: `lua5.1`, `luacheck` 1.1.x, `busted` 2.x, `python3` (только для
перегенерации данных и упаковки), `make`.

| Файл | Что делает |
|---|---|
| `gen_forever_api.py` | разбирает дамп API клиента Forever → `data/forever_api.lua` |
| `data/forever_api.lua` | (генерируется, коммитится) функции/неймспейсы/события/FrameXML/шаблоны/миксины/методы виджетов/Enum клиента Forever |
| `build_db_snapshot.py` | снимок БД Forever из research-JSON → `data/forever_db.lua` |
| `data/forever_db.lua` | (генерируется, коммитится) квесты, NPC, объекты, предметы, зоны, правила опыта |
| `validate_routes.lua` | **валидатор маршрутов** (CLI; логика в `lib/validator.lua`) |
| `gen_route_data.lua` | генерирует `<модуль>/Data.lua` (enUS-имена квестов/NPC маршрута, `places` — id зон и ruRU-имена мест; у модуля-библиотеки — `AddLibraryData`) |
| `package_addons.py` | `dist/<Аддон>-<версия>.zip` для каждого каталога `addons/*` |
| `simulate_routes.lua` | прогон маршрутов через настоящий движок на моке (принадлежит ядру; цели-события exploration/escort и квесты с шагом `complete` без целей в БД не выполнены при взятии — их выполняет шаг `complete`; библиотеки-зависимости грузятся в мок раньше модуля, сами отдельно не прогоняются) |
| `lib/route_loader.lua` | загрузка модуля маршрута в песочнице (сначала его зависимости `FastesBoooy_*` из `## Dependencies`) + нормализация через `Core/Schema.lua` и сборка маршрута через `Core/Compose.lua` (общие сегменты, вставки) |
| `lib/fbdb.lua` | доступ к снимку БД: маски рас/классов, поиск, расстояния, формулы опыта |
| `lib/json.lua` | детерминированный JSON-энкодер |

Все Lua-инструменты — Lua 5.1, запускаются из корня репозитория. Сторонний код
(Questie, QuestieDB, RXPGuides, BlizzardInterfaceResources, FrameXML) никогда не
исполняется: исходные файлы читаются только как текст/JSON.

## Цели make

| Цель | Команда |
|---|---|
| `make check` | `lint` + `test` + `validate` + `validate-fixtures` + `simulate` + `simulate-fixtures` (то же, что CI) |
| `make lint` | `luacheck --config .luacheckrc addons tools tests` |
| `make test` | `busted` (все `tests/spec/*_spec.lua`) |
| `make validate` | `lua5.1 tools/validate_routes.lua` (флаги: `make validate VALIDATE_FLAGS=--strict`) |
| `make simulate` | `lua5.1 tools/simulate_routes.lua` |
| `make validate-fixtures` / `make simulate-fixtures` | валидатор (0 ERROR) / симулятор на заведомо хороших фикстурах (`FxClean`, `FxNs`, `TestRoute`, библиотека `TestLib` + составной маршрут `TestComposed`; симулятор — `TestRoute`, `TestComposed`) — стадии проверяют что-то и до появления первого модуля маршрута |
| `make report` | пишет `docs/VALIDATION.md` (Markdown-отчёт валидатора; ошибки маршрутов не роняют цель) |
| `make routedata` / `make routedata-check` | перегенерировать / проверить актуальность `Data.lua` всех модулей маршрутов и библиотек (check — и фикстуры `FxClean`, `TestLib`, `TestComposed`) |
| `make api BIR=… WOWUI=…` | перегенерировать `data/forever_api.lua` (оба пути обязательны; `WOWUI=none` — без глобалов FrameXML) |
| `make db RESEARCH=… CONVERSION=…` | перегенерировать `data/forever_db.lua` (`CONVERSION` = `QuestieDB/data/Forever/conversion.json` или `none`) |
| `make package` | архивы аддонов в `dist/` (воспроизводимые: фиксированные даты, сортировка) |

## 1. API клиента: `gen_forever_api.py` → `data/forever_api.lua`

```
python3 -I tools/gen_forever_api.py --bir <BlizzardInterfaceResources>/Resources \
        --wowui <Forever FrameXML>/Interface/AddOns|none [--out tools/data/forever_api.lua]
```

`--bir` и `--wowui` обязательны (никаких путей по умолчанию, привязанных к машине).

* Вход: Ketho/BlizzardInterfaceResources, ветка `forever` (in-game дамп KethoDoc),
  `Resources/*.lua` разбираются регулярными выражениями **как текст**; билд берётся из
  `README.md` дампа (`GetBuildInfo()`), коммит — из `.git` (тоже как текст).
* `--wowui`: исходники FrameXML Forever (`none` — пропустить сознательно). TOC
  разрешаются для типа игры `camelot`, из загружаемых файлов собираются глобальные
  присваивания в колонке 0 (`Settings`, `SlashCmdList`, `RAID_CLASS_COLORS`, …) →
  `frameXMLExtraGlobals`, и `*_COLOR`-глобалы из `C_UIColor` → `uiColorGlobals`.
  Для «библиотечных» таблиц среди них (инициализированы конструктором таблицы в колонке 0,
  есть хотя бы одна `function Name.Field(`, не расширяются через `Mixin`) — `Settings`,
  `UiMapPoint`, … — записывается список членов → `frameXMLExtraTables` (ключи конструктора +
  `Name.Field =` / `function Name.Field(` / `function Name:Field(` в колонке 0).
* Причуда дампа: `Region` наследует сам себя; генератор пишет `ScriptRegion` (как в клиенте)
  и проверяет, что граф наследования виджетов ацикличен.
* Выход (отсортирован, детерминирован, без меток времени):
  `build`, `meta`, `globals`, `namespaces = { C_QuestLog = {...} }`, `luaGlobals`,
  `luaNamespaces`, `events`, `frameXMLGlobals`, `frameXMLTables`, `frameXMLExtraGlobals`,
  `frameXMLExtraTables`, `uiColorGlobals`, `frames`, `templates`, `templateTypes`, `fonts`, `mixins`,
  `widgetMethods` (собственные методы типа) + `widgetInherits` (родители; полный набор —
  рекурсивно), `widgetHandlers`, `scriptObjectMethods`, `leGlobals`/`leValues`,
  `enumNames`/`enums`, `constantNames`/`constants`, `counts`.
* Формат стабилен: его читает мок WoW API (`tests/mocks/**`).

## 2. luacheck: стандарт `forever` (`.luacheckrc`)

`.luacheckrc` при загрузке читает `tools/data/forever_api.lua` (`dofile` доступен в
конфиге luacheck 1.1.2; путь относительно корня репозитория) и строит std `forever`:

* `read_globals` = функции C API + Lua-помощники WoW + функции FrameXML + `LE_*`;
* `C_*`-неймспейсы, `Enum.X.Y`, `Constants.X.Y`, `string/table/math/bit`, таблицы
  `frameXMLExtraTables` (`Settings`, `UiMapPoint`, …) — с **закрытым** набором полей:
  опечатка или несуществующая функция (`C_QuestLog.GetQuestLogTitle`,
  `Settings.RegisterBogusCategory`) → `W143`, несуществующий глобал (`GetQuestLogTitle`,
  `GetItemCount`, `GetSpellInfo`) → `W113`;
* фреймы (`UIParent`, …), шрифты (`GameFontNormal`), миксины, прочие глобалы FrameXML
  (`SlashCmdList`, `RAID_CLASS_COLORS`, …) — с открытыми полями; `io`/`os`/`require`/`dofile`
  недоступны (как в клиенте).

| Файлы | std |
|---|---|
| `addons/FastesBoooy/**` | `forever+fastesboooy` (писать можно только `FastesBoooy`, `FastesBoooyDB`, `FastesBoooyCharDB`, `SLASH_FASTESBOOOY1/2`, `SlashCmdList.FASTESBOOOY`) |
| `addons/FastesBoooy_*/**`, `tests/fixtures/FastesBoooy_*/**`, `tests/fixtures/*/FastesBoooy_*/**` | `fastesboooy_route` (модули маршрутов **и модули-библиотеки**): только чтение `FastesBoooy.RegisterRoute/AddSegment/AddRouteData/UseSegments/AddInsert/AddLibrarySegment/AddLibraryData`, без исключений |
| `tools/**` | `lua51` |
| `tests/spec/**`, `tests/mocks/**`, `tests/fixtures/core/helpers.lua` | `lua51+busted` (мок ставит глобалы WoW; ослабленные правила только здесь) |

Длина строки — 140. Доказательство, что std работает: `tests/spec/validator_lint_spec.lua`
(неверное имя API даёт предупреждение, верное — нет).

## 3. Снимок БД: `build_db_snapshot.py` → `data/forever_db.lua`

```
python3 -I tools/build_db_snapshot.py --research <research> \
        --conversion <QuestieDB>/data/Forever/conversion.json|none [--out tools/data/forever_db.lua] [--date 2026-11-07]
```

`--research` и `--conversion` обязательны.

* Вход: `<research>/db/{quests,npcs,objects,items,zones,enums,wclbox_quests}.json` и
  `<research>/xp_table.json` (см. `research/db/README.md`); необязательный
  `<research>/db/wclbox_quests_60.json` (тот же формат; списки WCLBox зон/подземелий 20-60 и детали
  квестов Орды/обеих сторон уровня ≥ 20) дополняет `wclbox_quests.json` квестами, которых там нет
  (количество целей, статус, опыт). Данные: QuestieDB Forever (GPL-3.0; статические слои
  коррекций воспроизведены research-шагом) + зеркало WCLBox данных Wowhead Forever. Хэши входов
  записываются в `meta.sources`.
* **Охват (прокачка Орды 1-60)**:
  * **ядро 1-22** (`coreAreas`): все квесты, доступные Орде (маска рас содержит любую расу Орды,
    включая Skyborne-Орду 2^33, или 0), чья зона (через цепочку родительских AreaID) или спавн
    выдающего/принимающего NPC/объекта лежит в Tirisfal Glades, Undercity, Silverpine Forest,
    Durotar, Orgrimmar, The Barrens, Stonetalon Mountains, Ashenvale, Mulgore, Thunder Bluff,
    Hillsbrad Foothills, Zephras Isle (2521 со всеми подзонами), Moonglade, Riverglades, Ragefire
    Chasm, Wailing Caverns, Ruins of Lordaeron, Hall of Thanes — любого уровня и класса (как в
    снимке 1-22: новый снимок — его надмножество; у 318 старых квестов из `wclbox_quests_60.json`
    уточнены количества целей и источник опыта, 5 старым NPC добавлены флаги из `subName`, вывод
    валидатора для маршрутов 1-22 не изменился);
  * **мир**: все квесты Орды с `questLevel ≤ 62` (`MAX_QUEST_LEVEL`) в любой зоне Восточных
    королевств и Калимдора, включая столицы и новые зоны Forever (= каждая «родная» uiMap из
    `zones.json`, кроме карт мира/континентов и полей боя; AreaID 25 Blackrock Mountain, которого
    нет в `zones.json`, — тоже мир), не закрытые для паладина и друида (`requiredClasses` без этих
    классов — мимо) и не из исключённых QuestSort (`EXCLUDED_SORTS`: праздники, Ярмарка Новолуния,
    война за Ан'Киадж, легендарные/эпические цепочки, поля боя, другие классы);
  * **подземелья**: квесты 5-местных подземелий (`zoneOrSort` = подземелье из `zones.json`, в т.ч.
    через `alternativeAreaIds`: 1417 Sunken Temple → 1477) с `questLevel ≤ 60`
    (`MAX_DUNGEON_QUEST_LEVEL`). Многие квесты подземелий QuestieDB хранит под «уличной»
    подзоной входа (1717 Razorfen Kraul в Степях, 1517 Uldaman, 978 Zul'Farrak, 133 Gnomeregan) —
    они попадают по правилу «мир». Рейды (`RAID_AREAS`: MC, Onyxia, BWL, ZG, AQ20, AQ40, Naxx) и
    поля боя (`BATTLEGROUND_AREAS`) — вне охвата;
  * квесты без зоны и профессиональные/репутационные/«вторжение» — если выдающий или принимающий
    спавнится в мире;
  * все классовые квесты PALADIN и DRUID (любой стороны — чтобы валидатор мог сообщить «не та
    фракция»); плюс транзитивно (глубина 3) всё, на что они ссылаются:
    pre/next/breadcrumb/exclusive/parent/child.

  NPC: выдающие/принимающие, цели (creature/killCredit), источники выпадения предметов целей
  (больше 40 спавнов на карту → **прореживание по сетке** 2×2 единицы карты: в каждой клетке
  остаётся спавн, ближайший к её центру, так что каждый кластер сохраняет представителя — любой
  настоящий спавн не дальше 2·√2 единиц от оставленного; такие записи помечены `spawnsGrid = 2`).
  Сборщик сам проверяет худший случай и пишет его в `meta.counts`: `spawnsThinned.maps`
  (прорежено списков «NPC/объект × карта»), `spawnsThinned.worstMapUnits` (худшее расстояние от
  выброшенного спавна до ближайшего оставленного, единицы карты) и `spawnsThinned.worstYards` /
  `worstYardsMap` (то же в ярдах; сейчас 452 списка, 2,41 единицы карты, 174 ярда в The Barrens
  1413 — в пределах 2·√2 = 2,83 единицы, которые валидатор вычитает как запас).
  **Сервисные NPC** (тренеры/полётчики/трактирщики/торговцы/ремонт/банкиры/стойла/духи): в
  ядре — любой фракции; во всех остальных зонах и подземельях — дружественные Орде, нейтральные или
  с неизвестной фракцией (`friendlyToFaction` H / AH / нет), без чисто альянсовых; плюс все
  тренеры паладинов и друидов. Новые NPC Forever часто без `npcFlags` (сгенерированные строки
  QuestieDB): для NPC без флагов с уличным спавном флаги выводятся из `subName` (`SUBNAME_FLAGS`:
  Wind Rider/Gryphon/Hippogryph/Bat Master, Flight Master → `flightmaster`; Innkeeper; Stable
  Master; …Trainer; Armorer/Weaponsmith → vendor+repair; Vendor/Merchant/Quartermaster/Supplies/
  Goods/Food/Drink → vendor; NYI/PH/DEBUG/PTR пропускаются), такие записи помечены
  `flagsSrc = "subName"` — например, полётчик Riverglades Grakna 255993 (Wind Rider Master,
  59.58,45.13), стойла Grik 256673.
  **Транспорт** (`transport = "zeppelin" | "boat" | "skycutter" | "landing"`): NPC
  дирижаблей/кораблей/небесного корабля по `subName` (Zeppelin Master/Operator, Shipmaster,
  Boat Operator, Dockmaster, Captain of the Skycutter) или id (`TRANSPORT_IDS`: 275270
  Windshapers Dockmaster и 275269 High Order Dockmaster, Валанаар) — на любой карте со
  спавном (Zapetta 9566 и Hin Denburg 3150 в Тирисфале, Frezza 9564 и Snurk 12136 в
  Дуротаре, Nez'raz 3149 и Squibby 12137 в Гром'голе, Grimble 9558 в Кабестане, …), плюс все
  дружелюбные NPC места посадки без NPC причала (`TRANSPORT_LANDINGS`: плато Skywatcher в
  Мулгоре, куда прилетает корабль из Валанаара: Galestrider Handler 264287, Alaana
  Stormwalker 259119, Muln Earthfury 259118, …).
  Вне охвата — компактные индексы `questIndex`/`npcIndex`/`objectIndex`, чтобы отличать
  «не существует в Forever» от «вне снимка» (рейдовые, праздничные квесты, квесты других классов
  вне ядра, альянсовые сервисные NPC вне ядра).
* Overlay Horde Dynamic (QuestieDB dynamic corrections для Орды) применён; различия
  PALADIN/DRUID — в `byClass`.
* **Количество целей** — из WCLBox (данные Wowhead Forever: например, 364 — 5+5 зомби, а
  не 8+8 как в тексте Classic), иначе из текста цели.
* **Иконка цели** (`icon`) — у целей creature/killCredit хранится иконка QuestieDB, если это не
  «убить» (0/1 не пишутся): `enums.iconTypes` — 3 EVENT («освободить», кредит-болванка),
  5 TALK («поговорить»), 17 INTERACT («вылечить», «применить предмет на»). Цель-существо
  записывается как `{id, count?, icon = N}`. `objectives.event = true` — квест завершается
  триггером области / скриптом (исследование, сопровождение).
* **Опыт квеста** (`xp`, `xpSrc`): опыт данжевых квестов Forever (`forever-dungeon`),
  иначе WCLBox (`wclbox-classic`, равен Classic), иначе QuestieDB XP (`questie-classic`);
  для 974 квестов опыт неизвестен (`xp = nil`): 537 новых квестов Forever и 437 «same», у которых
  WCLBox даёт `xp = 0`, а строки в QuestieDB XP нет (вероятно, квесты без опыта; не проверено) —
  валидатор оценивает его, а аддон записывает реальные значения в игре (`/fb xp`).
* **Координаты.** QuestieDB хранит спавны по AreaID в процентах карты этой зоны. Данные
  QuestieDB Forever **уже в системе координат Forever**: сырые файлы получены
  `QuestieDB convert-forever` (границы карт Era 1.15.9 → Forever 1.60.1.69893; геометрия
  изменилась только у Mulgore 215, Eastern Plaguelands 139, Redridge 44, Stormwind 1519, и
  они уже пересчитаны), слои traces/generated — нативные координаты Forever
  (`research/db/crosscheck.md`: медиана расхождения с WCLBox 0.04 по 1 628 точкам,
  включая Mulgore; `research/db/crosscheck_60.md` — то же для зон 20-60). Поэтому преобразуется
  только AreaID → uiMapID (`zones.json`), что даёт ровно систему маршрутов `at = {uiMapID, x, y}`.
  Спавны `[-1, -1]` («внутри инстанса») попадают в `instance = {AreaID}`. uiMap 2665 («вторая
  карта» Zephras Isle) известен, но спавнов на нём нет.
* **Размеры карт в ярдах**: `zones[uiMap].size = {ширина, высота}` из границ карт Forever
  (`geometry.transforms[].target_bounds` в `QuestieDB/data/Forever/conversion.json`:
  ширина = |left − right|, высота = |top − bottom|) — 49 карт: все зоны и столицы Восточных
  королевств и Калимдора и три поля боя. Например, The Barrens 10 133 × 6 756 ярдов, Stranglethorn
  Vale 6 381 × 4 254, Undercity 959 × 640, Tirisfal 4 519 × 3 013. Новых карт Forever
  (`geometry.added_maps`) в `conversion.json` нет; их размер — из зеркала карт WCLBox
  (`https://wowforever.wclbox.com/shuju/en/maps.json`, `paint[].bounds` файла `<uiMap>.webp`, в
  пикселях карты при 512 px на тайл ADT 533⅓ ярда; пиксели × 533,333/512 совпадают с
  `conversion.json` до 0,1 ярда на всех 49 картах, где есть оба источника; уверенность «вероятно»),
  такие записи помечены `sizeSrc = "wclbox-map"`: Riverglades 2548 — 4 850 × 3 233,3, Mount Hyjal
  2482 — 3 472,9 × 2 314,6, Darkspear Islands 2524 — 1 925 × 1 283,3, Shen'dralas 2652 —
  2 050 × 1 366,7. Итого 53 карты с размером. **Zephras Isle 2521 пока без размера** (по тем же
  данным было бы 5 562,5 × 3 708,3: 5 340 × 3 560 px на карте `zephras-isle`): фикстуры валидатора
  (`FastesBoooy_FxNpcFar` в `tests/spec/validator_fixtures_spec.lua`) используют её как пример
  запасного режима «проценты карты»; размер включается добавлением строки в `WCLBOX_MAP_PIXELS`
  (проверено: маршруты 1-22 с ним не получают новых замечаний — все `at` на острове ближе 40 ярдов).
  Остальные карты без размера — данжевые карты-псевдонимы QuestieDB и 2665.
* Размер ≈ 3,26 МБ (3 415 449 байт; было 2,6 МБ при охвате 1-22), загрузка ≈ 0,1 с. Счётчики
  (снимок 2026-11-07): квестов 3 095 (+2 138 в индексе): ядро 1 470, мир 997, подземелья 114, по
  спавну выдающего 82, классовые 233, по ссылкам 199; NPC 5 922 (+7 495; сервисных 1 077 — H 651, AH 273,
  неизвестная фракция 57, альянсовых в ядре 96; 22 с флагами из `subName`; 28 транспортных;
  3 949 целей/источников выпадения), объектов 775 (+6 268), предметов 2 270, карт 98 (53 с
  размером), подземелий 129. Опыт известен у 2 121 квеста. Сводка по зонам и сверка с WCLBox —
  `research/db/crosscheck_60.md` (медиана расхождения координат 0,04 по 2 749 точкам; 16 точек
  дальше 2 единиц — движущийся караван Гизельтона в Desolace, новый NPC Forever Lumina Windsinger
  248755 в Silverpine, альянсовые «Salve via …» в Felwood).

Структура (подробно — в шапке файла):

```lua
return {
  meta = { build = {"1.60.1", "70862"}, interface = 16001, generated = "2026-11-07", sources = {...}, counts = {...} },
  questLogSize = 40, levelCap = 60,
  enums = { races = {UNDEAD = 16, SKYBORNE_HORDE = 8589934592, ...}, classes = {PALADIN = 2, DRUID = 1024, ...},
            raceFileToBit = { Scourge = 16, ..., Skyborne = { Horde = 2^33, Alliance = 2^32 } },
            factionMasks = { Horde = 8589934770, Alliance = 4294967373 }, npcFlags = {...}, ... },
  coreAreas = { [85] = "Tirisfal Glades", ... },            -- ядро 1-22
  scopeAreas = { [400] = "Thousand Needles", [1337] = "Uldaman", ... }, -- все зоны и 5-местные подземелья
  zones = { [1420] = {name = "Tirisfal Glades", areaId = 85, scope = true, size = {4518.7, 3012.5}},
            [2548] = {name = "Riverglades", areaId = 16591, scope = true, size = {4850, 3233.3}, sizeSrc = "wclbox-map"}, ... },
  areaToUiMap = { [154] = 1420, ... }, areaNames = { [484] = "Freewind Post", ... },
  dungeons = { [16611] = {name, entrances = {{1458, 72.48, 11.33}}} },
  xp = { levels = {[1] = 400, ...}, questRule = {...}, mobRule = {...}, typicalQuestXpByLevel = {...} },
  quests = { [364] = { name, level, reqLevel, races, classes, side = "H", start = {npcs = {1569}},
                       finish = {npcs = {1569}}, breadcrumbs = {363}, objectives = {creatures = {{1501, 5}, {1502, 5}}},
                       zone = 154, uiMap = 1420, xp = 170, xpSrc = "wclbox-classic", status = "same" },
             [92514] = { ..., objectives = {creatures = {{251902, icon = 5}, {254089, icon = 5}}} } },  -- talk
  npcs = { [1569] = { name, sub, minLevel, maxLevel, rank, faction = "H", flags = {questgiver = true},
                      spawns = { [1420] = { {30.84, 66.2} } } },    -- spawns[uiMapID] = {{x, y}, ...}
                                                                   -- (+ spawnsGrid = 2 when thinned)
           [9566] = { name = "Zapetta", sub = "Zeppelin Master", ..., transport = "zeppelin" },
           [255993] = { name = "Grakna", sub = "Wind Rider Master", faction = "H", flags = {flightmaster = true},
                        flagsSrc = "subName", spawns = { [2548] = { {59.58, 45.13} } } } },
  objects = {...}, items = {...}, questIndex = {...}, npcIndex = {...}, objectIndex = {...},
}
```

Маски рас больше 32 бит: проверять только арифметикой `floor(mask / bit) % 2`
(`DB.HasBit`), никогда `bit.band`.

## 4. `gen_route_data.lua` → `<модуль>/Data.lua`

```
lua5.1 tools/gen_route_data.lua <каталог-модуля> [...]   # записать
lua5.1 tools/gen_route_data.lua --all                     # все addons/FastesBoooy_*/ (маршруты и библиотеки)
lua5.1 tools/gen_route_data.lua --all --check             # CI: код 1, если Data.lua устарел
lua5.1 tools/gen_route_data.lua --stdout <каталог>        # напечатать
```

Загружает `Route.lua` и сегменты (порядок TOC, сам `Data.lua` пропускается; модули-зависимости
`FastesBoooy_*` — раньше, как клиент) в песочнице (все файлы модуля получают одну общую
приватную таблицу `local _, ns = ...`, как в клиенте), собирает маршрут (`Core/Compose.lua`),
собирает id квестов (`accept/turnin/complete/abandon`, ключи `reward`), NPC (`npc`),
объектов (`object`), предметов (`collect`, `use`) и пишет для каждого маршрута
`FastesBoooy.AddRouteData("<id>", { quests = {[id] = "enUS"}, npcs = {...}, objects = ..., items = ..., places = ... })`.

**Общие сегменты** (`docs/ROUTE_FORMAT.md`, «Общие сегменты и вставки»). Модуль маршрута с
`UseSegments` перечисляет только то, на что ссылаются его **собственные сегменты и вставки**
(шаги библиотеки — не его). Модуль-библиотека (`AddLibrarySegment`, без маршрута) получает
`FastesBoooy.AddLibraryData({ quests = ..., npcs = ..., objects = ..., items = ..., places = ... })`
со всем, на что ссылаются **его** сегменты; в игре эти имена подмешиваются в данные каждого
маршрута, использующего библиотеку. Ошибки загрузки зависимости (файл `<Библиотека>/<файл>`)
тоже останавливают генерацию.

`places` — места действий `fp`/`fly`/`sethearth`/`hearth`:
`["Brill"] = { area = 159, en = "Brill", ru = "Брилл" }`. `area` — id зоны (AreaTable) с этим
enUS-именем из `areaNames` снимка БД: в игре аддон берёт локализованное имя у клиента
(`C_Map.GetAreaInfo`) — так `sethearth` узнаёт точку привязки по имени
(`GetBindLocation()`) на любом языке клиента, в том числе для мест Forever. `ru` — из таблицы
`PLACE_NAMES_RU` в начале `gen_route_data.lua` (запасной вариант, если клиент имени не дал);
новое место маршрута добавляйте туда. Место без `area` и без `ru` не пишется (показывается
по-английски), генератор сообщает о нём в stderr (`note:`).

Вывод детерминирован (сортировка по id / имени). Если у модуля есть ошибки загрузки/схемы,
`Data.lua` не пишется (и не печатается) и код выхода — 1.

## 5. Валидатор: `validate_routes.lua`

```
lua5.1 tools/validate_routes.lua [опции] [каталог-модуля ...]
```

Без каталогов проверяет все `addons/FastesBoooy_*/` с TOC (модули маршрутов — собранными вместе с их
библиотеками-зависимостями, и сами модули-библиотеки). Опции:

| Опция | Смысл |
|---|---|
| `--route ID` | только этот маршрут |
| `--profile race=Scourge,class=PALADIN[,faction=Horde]` | переопределить профиль игрока |
| `--strict` | WARN тоже даёт код выхода 1 |
| `--json FILE` | полный отчёт (включая INFO) в JSON |
| `--markdown FILE` | Markdown-отчёт (`make report` → `docs/VALIDATION.md`) |
| `--db FILE` | другой снимок БД |
| `--addons DIR` | где искать модули |
| `--tolerance-yards N` / `--hard-tolerance-yards N` | пороги расстояния `at` → спавн в ярдах (по умолчанию 40 / 120) |
| `--tolerance N` / `--hard-tolerance N` | те же пороги в единицах карты (%) для карт без известного размера (по умолчанию 3.0 / 8.0; помечается «approximate») |
| `--ignore код,код` | подавить коды сообщений (например `xp-unknown`) |
| `--xp-optimism N` | множитель оценённого опыта для «оптимистичной» симуляции (по умолчанию 2.0) |
| `-v` / `-q` | показать INFO / только итоговые строки |

Код выхода: 0 — нет ошибок; 1 — есть ERROR (или WARN при `--strict`); 2 — ошибка запуска
или `--route` не совпал ни с одним маршрутом.

### Как работает

1. Модуль грузится в песочнице (`lib/route_loader.lua`): только чистые библиотеки Lua и
   заглушка `FastesBoooy`, которая нормализует `RegisterRoute/AddSegment/AddRouteData`
   **настоящим** `addons/FastesBoooy/Core/Schema.lua` (как `Core/Registry.lua`) и собирает
   маршрут из своих сегментов, сегментов библиотеки и вставок (`UseSegments`/`AddInsert`,
   **настоящий** `Core/Compose.lua`). Сначала грузятся модули `FastesBoooy_*` из `## Dependencies`/
   `## RequiredDeps` TOC (рекурсивно, из того же каталога `addons`, каждый со своей таблицей
   `ns`); их файлы называются `<Модуль>/<файл>`. Ошибки схемы, загрузки, объявление глобалов,
   ошибки сборки (неизвестный сегмент библиотеки / якорь вставки, id шагов, совпавшие после
   сборки), ненайденная зависимость или цикл зависимостей → `schema` (ERROR) с именем файла.
   **Библиотеки:** сообщения о шагах и сегментах библиотеки помечены `library = "<модуль>"`
   (в тексте и Markdown — префикс `[library FastesBoooy_Horde]`, в JSON — поле `library`) и
   выводятся **один раз на маршрут** (одинаковые сообщения следующих профилей маршрута
   отбрасываются, счётчик — `libraryRepeats`). Модуль-библиотека — не маршрут: в отчёте у него
   своя запись `== library module …` (число сегментов и шагов) только с его ошибками загрузки/
   схемы; если библиотека входит в запуск, модули маршрутов эти ошибки не повторяют, иначе они
   выводятся в маршруте, который её использует.
2. Профили: каждая пара (раса × класс) из метаданных маршрута; фракция — из маршрута.
   `raceFile` → бит расы через `enums.raceFileToBit` (Нежить = `Scourge`; `Skyborne` —
   по фракции: Орда 2^33, Альянс 2^32; Skyborne-маршрут без `faction` проверяется за обе
   стороны). Один раз на маршрут: токены рас маршрута и фильтров шагов сверяются с
   `raceFileToBit` (`unknown-race-token`), шаг, который не видит ни один профиль, — WARN
   `step-no-profile`.
3. Шаги проходят по порядку; шаги, не подходящие по `class/race/faction`, пропускаются
   (INFO). Внутри шага действия выполняются в порядке игрока у одного NPC: abandon →
   цели/предметы квестов, уже бывших в журнале → turnin → accept → цели и сдача квестов,
   взятых этим же шагом → остальное в порядке `Schema.ACTION_ORDER`. Так работают «сдать и
   сразу взять», `{accept=Q, turnin=Q}`, `{accept=Q, complete=Q}`, `{complete=Q, turnin=Q}`.
4. Симуляция: журнал квестов, сданные/брошенные, опыт и уровень.
   * старт: уровень 1, 0 опыта; таблица опыта = Classic Era (`xp.levels`);
   * `turnin`: опыт квеста × штраф за разницу уровней Classic (`mult = clamp(2*(qL-pL)+20, 1, 10)/10`,
     округление клиента); неизвестный опыт → медиана известных квестов того же уровня (WARN `xp-unknown`);
   * `complete`: убийства **враждебных** целей-существ (`count` × опыт моба) и добыча предметов
     целей (≈1.5 убийства источника на предмет); опыт моба — формула Classic
     (`(5·pL+45)`, +5%/уровень выше, серые = 0, элита ×2) со штрафом Forever за «зелёных»
     мобов (−4% за уровень разницы, максимум −20%) — это **оценка** (INFO `complete-kill-xp`).
     Цель — **не** убийство (опыта нет, INFO `complete-no-kill` с причиной), если: иконка цели
     в БД — talk / interact / event (поговорить, вылечить, освободить, применить предмет;
     killCredit-«события» с болванкой-кредитом тоже); NPC нет в снимке; у NPC есть любой
     флаг (questgiver, trainer, vendor, innkeeper, gossip, …) или он выдаёт/принимает квест
     снимка; NPC дружелюбен стороне маршрута (`faction` содержит букву стороны, в т. ч. `AH`)
     — кроме целей с известным количеством ≥ 2 (у ряда семейств мобов Forever в БД неверная
     или «нейтральная» фракция: 1501 Mindless Zombie `AH`, 259434 Tarnished Drudge `H`).
     killCredit: засчитывается первый враждебный NPC со спавнами из `base, ids…`.
     Неизвестное количество: 1 убийство для именного/уникального NPC (`rank` > 0 или не
     больше 5 точек спавна без прореживания), иначе 4 (`defaultKillCount`, осторожно; в
     оптимистичной симуляции ×1.5). Источник предмета — первый NPC из `npcDrops` со спавнами,
     без флагов, не выдающий квесты и не дружелюбный только стороне маршрута (`H` для Орды;
     нейтральные звери `AH` — годятся);
   * `level`: если опыта не хватает — гринд мобами своего уровня, число убийств (INFO,
     WARN если > 30);
   * параллельно идёт **оптимистичная** симуляция: неизвестный опыт квестов × `--xp-optimism`
     (2.0), предполагаемое число убийств × 1.5. Требование уровня — ERROR `level-too-low`,
     только если не выполняется даже в оптимистичной симуляции, иначе WARN
     `level-too-low-estimated` (недобор может быть артефактом оценки). Совет для маршрутов:
     перед квестом с порогом уровня поставить шаг `level` — в игре он выполняется сразу,
     если уровень уже набран;
   * rested-бонус, еда, лагерь и групповой опыт не моделируются.

### Проверки и коды сообщений

| Код | Уровень | Что значит |
|---|---|---|
| `schema` | ERROR | ошибка формата (Schema.lua), загрузки файла, глобал в модуле, сегмент без маршрута |
| `quest-unknown` | ERROR | квеста нет в БД Forever |
| `quest-out-of-scope` | WARN | квест есть в Forever, но вне снимка (проверки NPC/цепочек пропущены) |
| `quest-side` | ERROR | квест другой фракции |
| `quest-race` / `quest-class` | ERROR | недоступен расе / классу профиля (`requiredRaces/Classes`) |
| `level-too-low` / `level-too-high` | ERROR | симулированный уровень ниже `reqLevel` (даже оптимистично) / выше `maxLevel` при принятии |
| `level-too-low-estimated` | WARN | уровень ниже `reqLevel` по оценке, но достижим в оптимистичной симуляции |
| `accept-prereq` | ERROR | не сданы все `preGroup` или ни один из `preSingle` |
| `accept-exclusive` | ERROR | взят/сдан взаимоисключающий квест (в обе стороны: в БД группа часто указана только у одного квеста) |
| `accept-unavailable` | ERROR | квест больше не выдаётся: сдан его `availableUntilCompleted` (`untilCompleted`) |
| `accept-disabled` | ERROR | квест не выдаётся, пока в журнале его `disabledByQuest` (`disabledBy`) |
| `accept-parent` | ERROR | родительский квест не в журнале |
| `accept-duplicate` / `accept-done` | ERROR | квест уже в журнале / уже сдан (кроме повторяемых) |
| `questlog-full` | ERROR | в журнале больше `questLogSize` (40) квестов |
| `breadcrumb-late` / `breadcrumb-open` | WARN | «хлебная крошка» берётся после цели / цель берётся при открытой крошке |
| `accept-wrong-npc` / `accept-wrong-object` | ERROR | NPC/объект шага не выдаёт квест |
| `turnin-wrong-npc` / `turnin-wrong-object` | ERROR | NPC/объект шага не принимает квест |
| `turnin-not-accepted` / `turnin-twice` / `turnin-abandoned` | ERROR | сдача невзятого / повторная / брошенного квеста |
| `turnin-no-complete` | WARN | у квеста есть цели, но не было шага `complete` |
| `turnin-partial` | WARN | шаги `complete = { [id] = {…} }` покрыли не все цели квеста |
| `turnin-items` | INFO | предметы целей не собраны шагами `complete`/`collect` |
| `complete-not-active` | ERROR | `complete` для квеста не в журнале |
| `complete-bad-index` | WARN | номер цели больше числа целей в БД |
| `abandon-not-active` | ERROR | бросается квест не из журнала |
| `quest-carried` | WARN | квест не сдан и не брошен к концу маршрута |
| `npc-unknown` / `object-unknown` | ERROR | NPC/объекта нет в БД Forever |
| `npc-out-of-scope` / `object-out-of-scope` | WARN | существует, но вне снимка (позиция не проверена) |
| `at-map-unknown` | ERROR | неизвестный uiMapID |
| `at-far` | WARN / ERROR | ближайший спавн NPC/объекта шага дальше 40 / 120 ярдов (карты без размера: 3 / 8 единиц карты, «approximate»; у прореженных спавнов вычитается 2·√2 единицы) |
| `at-no-spawn` | ERROR | у NPC/объекта нет спавна на карте `at` |
| `at-far-from-giver` | WARN | шаг accept/turnin без `npc`: `at` дальше порога от выдающих/принимающих (ярды; без размера карты — единицы) |
| `at-instance` | INFO | NPC внутри инстанса — позицию не проверить |
| `train-wrong-trainer` | ERROR | NPC не тренер класса маршрута (`subName` «<Class> Trainer») |
| `train-not-class-trainer` | WARN | тренер профессии/верховой езды, а не класса |
| `train-no-npc` | WARN | шаг `train` без NPC |
| `not-flightmaster` | ERROR | `fp`/`fly` у NPC без флага полётчика |
| `not-innkeeper` | ERROR | `sethearth` не у трактирщика |
| `not-vendor` | WARN | `vendor` у NPC без флага торговца/ремонта |
| `npc-hostile` | ERROR | NPC тренера/полётов/таверны/торговли не дружелюбен фракции (`A`/`H`/`AH`) |
| `hearth-mismatch` / `hearth-unbound` | WARN / INFO | камень привязан к другому месту / не было `sethearth` |
| `xp-unknown` | WARN | опыт квеста неизвестен — использована оценка |
| `complete-kill-xp` | INFO | оценка убийств и опыта за цели |
| `complete-no-kill` | INFO | цели, за которые опыт убийств не начисляется (поговорить/вылечить/событие, дружелюбный или служебный NPC, выдающий квест), с причиной |
| `level-grind` | INFO / WARN | сколько убийств нужно до уровня шага `level` (WARN если > 30) |
| `segment-level` / `route-level` | WARN | симулированный уровень в конце сегмента / маршрута отличается от плана больше чем на 1 |
| `step-skipped` | INFO | шаг отфильтрован по классу/расе/фракции |
| `unknown-race-token` | ERROR | токен расы маршрута или фильтра шага — не `raceFile` из `UnitRace()` (например `Undead` вместо `Scourge`): шаг молча пропал бы у всех |
| `step-no-profile` | WARN | шаг не подходит ни одному профилю маршрута — его никто не увидит |
| `profile-race` / `profile-class` / `profile-faction` | ERROR / WARN | неизвестный профиль (в т. ч. `raceFile` обеих фракций без `faction`) |
| `route-empty` | ERROR | у маршрута нет шагов |

### Вывод

* stdout: ERROR/WARN (с `-v` и INFO) в виде `SEVERITY [library модуль] сегмент#шаг id=… (файл) [код] сообщение`
  (`[library …]` — только у шагов библиотеки; вставленный шаг показывается номером якоря и своим id),
  таблица сегментов (план уровней, симулированный уровень начала → конца, опыт квестов/мобов/
  гринда, журнал), итог маршрута;
* `--json`: `{ db, totals, routes = [{ route, module, profile, counts, summary, segments, messages }] }`;
* `--markdown`: отчёт на русском для `docs/VALIDATION.md`. Оба файла детерминированы.

## 6. Тесты и фикстуры

* `tests/spec/validator_fixtures_spec.lua` — модули-фикстуры `tests/fixtures/validator/`
  на реальных данных Forever (Мертвый Звон): чистый маршрут `FastesBoooy_FxClean` (0 ERROR,
  0 WARN), `FastesBoooy_FxNs` (файлы модуля делят таблицу `ns`) и по модулю на каждую ошибку:
  неверный id квеста, квест другой расы/фракции/класса, нет предквеста, NPC далеко от `at`
  (ярды; Zephras Isle — приблизительно), не тот NPC выдачи/сдачи, переполнение журнала,
  низкий уровень, не тот тренер/полётчик/трактирщик, учёт журнала (exclusive, дубли,
  сдача невзятого), ошибки схемы, фильтры шагов (`FastesBoooy_FxFilters`); плюс маршруты в
  памяти: порядок действий в шаге, exclusive в обе стороны, `untilCompleted`/`disabledBy`,
  частичный `complete`, Skyborne без фракции, ярды на разных картах, прореженные спавны.
* `tests/spec/validator_lib_spec.lua` — маски > 32 бит, формулы опыта, структура снимка,
  загрузчик модулей, профили, JSON.
* `tests/spec/validator_cli_spec.lua` — коды выхода CLI, `--json/--markdown`, детерминизм,
  `gen_route_data.lua --check/--stdout`.
* `tests/spec/validator_compose_spec.lua` — составные маршруты в инструментах: загрузчик
  (зависимости, имена файлов, ненайденная зависимость, цикл, ошибки сборки), валидатор (0 ERROR
  на `FastesBoooy_TestComposed`, метка `library`, «один раз на маршрут» при двух профилях,
  ошибки библиотеки один раз за запуск, неизвестный сегмент/якорь), `gen_route_data`
  (`AddLibraryData` библиотеки, данные маршрута — только свои сегменты и вставки), симулятор
  (библиотека грузится как зависимость и пропускается, два профиля с классовой вставкой,
  неизвестный сегмент → FAIL). Фикстуры: `tests/fixtures/core/FastesBoooy_TestLib` (библиотека)
  и `FastesBoooy_TestComposed` (свои сегменты + `UseSegments` + вставки до/после шагов
  библиотеки и своих); в аддоне их проверяет `tests/spec/core_compose_spec.lua`.
* `tests/spec/validator_lint_spec.lua` — std `forever` ловит несуществующие API.

```
busted tests/spec/validator_*_spec.lua
lua5.1 tools/validate_routes.lua tests/fixtures/validator/FastesBoooy_FxClean
```

## Ограничения

* Опыт ~720 новых квестов Forever неизвестен офлайн — уровни в симуляции приблизительны,
  пока не собраны реальные значения (`/fb xp` в аддоне → обновить данные).
* Опыт за мобов — формула Classic + приблизительный штраф Forever; вероятности выпадения
  предметов в снимке нет.
* Расстояние считается в ярдах по размерам карт из `conversion.json`; у карт без известных
  границ (Zephras Isle 2521, данжевые карты) — в процентах карты (приблизительно).
* uiMap 2665 (вторая карта Zephras Isle) не разрешён в данных QuestieDB.
