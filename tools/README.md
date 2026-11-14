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
| `fetch_wowhead_requirements.py` | списки «Requirements:» подсказок Wowhead Forever для квестов снимка → `data/wowhead_requirements.json` (количества целей Forever; вход `build_db_snapshot.py`) |
| `data/wowhead_requirements.json` | (генерируется, коммитится) `{"<questID>": [[имя, N или null], ...]}` — 1 958 квестов, у 1 842 есть список (снимок 2026-11-08) |
| `validate_routes.lua` | **валидатор маршрутов** (CLI; логика в `lib/validator.lua`; раздел 5; `--state`/`--write-state`/`--harness` — раздел 7) |
| `gen_route_data.lua` | генерирует `<модуль>/Data.lua` (enUS-имена квестов/NPC маршрута, `places` — id зон и ruRU-имена мест, `questMeta` — уровни и предпосылки квестов; у модуля-библиотеки и у модуля с общим содержимым и маршрутами — `AddLibraryData`) |
| `package_addons.py` | `dist/<Аддон>-<версия>.zip` для каждого каталога `addons/*` |
| `gen_confirm_list.py` | список «что подтвердить в игре» из комментариев `-- CONFIRM` модуля гайдов: `python3 -I tools/gen_confirm_list.py > docs/routes/confirm-in-game.md` (вручную, после правок с `CONFIRM`; CI его свежесть не проверяет) |
| `simulate_routes.lua` | прогон маршрутов через настоящий движок на моке (принадлежит ядру; цели-события exploration/escort и квесты с шагом `complete` без целей в БД не выполнены при взятии — их выполняет шаг `complete`; визит `train`/`vendor`/`fp`/`sethearth` к NPC, который выдаёт квест маршрута или принимает выполненный, начинается с его диалога (`m:TalkTo`), как в игре, — если автоматика при этом перемотала обязательный визит, это предупреждение (валидатор: `lookahead-skip`); библиотеки-зависимости грузятся в мок раньше модуля, сами отдельно не прогоняются; часть библиотеки из стартового состояния — `--harness`, раздел 7; «игрок обогнал маршрут» — `--ahead L`, раздел 8; список маршрутов `--list-routes`, выбор маршрутов, фильтр файлов, проверка наград — раздел 9) |
| `lib/route_loader.lua` | загрузка модуля маршрута в песочнице (сначала его зависимости `FastesBoooy_*` из `## Dependencies`) + нормализация через `Core/Schema.lua` и сборка маршрута через `Core/Compose.lua` (общие сегменты, общие вставки, вставки маршрута). Результат: `mod.routes`, `mod.librarySegments`, `mod.libraryInserts` (шаблоны общих вставок с файлом, областью и списком маршрутов, куда они попали), `mod.aliases`, `mod.errors` (у ошибки — файл, `route` — маршрут, к которому она относится, `load` — файл не загрузился). Опции: `skipGlobs` / `keepGlobs` (фильтр файлов TOC), `replace = { [путь TOC] = другой файл }` (подмена файла — для спеков) |
| `lib/fbdb.lua` | доступ к снимку БД: маски рас/классов, поиск, расстояния, формулы опыта; слой поправок `DB.ApplyOverrides` |
| `overrides/*.lua` | поправки к снимку БД: значение для одного квеста или NPC с источником и отметкой «проверено в игре» (формат и правила — `overrides/README.md`) |
| `lib/validator.lua` | валидатор: прогон маршрута по профилю, проверки, отчёт о гринде, принятые предупреждения (`ok`), числовые критерии, текстовый и JSON-отчёты |
| `lib/module_checks.lua` | проверки **шаблонов** модуля с общим содержимым и маршрутами: общие сегменты и общие вставки, которые не попали ни в один маршрут, неизвестный якорь, неизвестный токен расы |
| `lib/report.lua` | сводный Markdown-отчёт (`docs/VALIDATION.md`): раздел 5, «Отчёт `docs/VALIDATION.md`» |
| `lib/glob.lua` | шаблоны с `*` для `--route`, `--skip`, `--keep`, `--own` |
| `lib/json.lua` | детерминированный JSON-энкодер и строгий декодер (файлы состояния) |
| `lib/harness.lua` | **harness** — часть общих сегментов модуля из стартового состояния: формат файла состояния (чтение, проверка, детерминированная запись), синтетический маршрут «профиль + `UseSegments` выбранных сегментов» (раздел 7) |

Все Lua-инструменты — Lua 5.1, запускаются из корня репозитория. Сторонний код
(Questie, QuestieDB, RXPGuides, BlizzardInterfaceResources, FrameXML) никогда не
исполняется: исходные файлы читаются только как текст/JSON.

## Цели make

| Цель | Команда |
|---|---|
| `make check` | `lint` + `test` + `validate` + `validate-fixtures` + `simulate` + `simulate-sync` + `simulate-fixtures` + `harness-fixtures` (то же, что CI, раздел 10). На 4 ядрах с 11 маршрутами `FastesBoooy_Guides` ≈ 4 мин (F2e: 246 с, из них `busted` 71 с; было ≈ 3,7 мин с двумя маршрутами в F1). `make simulate-sync-full` (88 прогонов) ≈ 7 мин |
| `make check-fast` | быстрый круг: `lint` + `validate` + фикстуры + симуляция маршрута `ROUTE` (по умолчанию `*undead-paladin`) — около полминуты, без busted и без sync-прогонов |
| `make route ROUTE=<id>` | валидатор с `VALIDATE_FLAGS` и симулятор для одного маршрута (`ROUTE` — то же, что принимает `--route`: список через запятую, `*`) |
| `make lint` | `luacheck --config .luacheckrc addons tools tests` |
| `make test` | `busted` (все `tests/spec/*_spec.lua`) |
| `make validate` | `lua5.1 tools/validate_routes.lua $(VALIDATE_FLAGS)`. `VALIDATE_FLAGS` — ворота маршрутов: сейчас `--strict --end-level --max-grind-until h-18-stonetalon-ashenvale=120/200 --baseline docs/dev/handover/baseline.json` (строгий режим, уровень 60 в конце, бюджет гринда до конца `h-18`, базовая линия гринда базовых профилей рас, замороженная в фазе P2; раздел 5, «Ворота») |
| `make simulate` | каждый маршрут — отдельный процесс симулятора, `JOBS` процессов одновременно (`xargs -P`). Список маршрутов — `lua5.1 tools/simulate_routes.lua --list-routes`; если он не получен (модуль не загрузился) или пуст, цель падает и ничего не симулирует; упавшая симуляция роняет цель, остальные доходят до конца. Вывод каждого процесса печатается одним куском, когда процесс закончился: он собирается во временный файл и выводится под блокировкой (каталог-замок во временном каталоге, `mkdir`), поэтому строки разных процессов не перемешиваются при любом объёме вывода |
| `make simulate-sync` | «игрок обогнал маршрут» (раздел 8) для маршрутов `SYNC_ROUTES` (сейчас `orc-warrior troll-shaman tauren-hunter undead-paladin skyborne-druid`: по маршруту на расу, пять разных классов), так же параллельно: `--route R --ahead L` для `L` из `SYNC_LEVELS` (`10 23 35 48`), прыжок посреди участка с квестами в журнале `--ahead L --ahead-at SEG` для `SYNC_MID` (`21/h-15-barrens 29/h-24-barrens-stonetalon`) и игра с опережением `--level-plus N` для `SYNC_PLUS` (`2 4`): 8 прогонов на маршрут. Пустой `SYNC_ROUTES` — ошибка |
| `make simulate-sync-full` | то же для **всех** маршрутов (`--list-routes`): ночной запуск CI |
| `JOBS=N` | число параллельных симуляций `simulate` / `simulate-sync` (по умолчанию — число процессоров, `nproc`) |
| `make validate-fixtures` / `make simulate-fixtures` | валидатор (0 ERROR) / симулятор на заведомо хороших фикстурах (`FxClean`, `FxNs`, `TestRoute`, библиотека `TestLib` + составной маршрут `TestComposed`, `FxHarnessLib`, модуль с общим содержимым и тремя маршрутами `TestGuides`; симулятор — `TestRoute`, `TestComposed`, `TestGuides`) — стадии проверяют что-то и до появления первого модуля маршрута. Все цели фикстур передают `--no-overrides`: фикстуры используют настоящие id квестов и не должны меняться вместе с `tools/overrides` |
| `make harness-fixtures` | harness на фикстуре-библиотеке `FastesBoooy_FxHarnessLib` из её состояния `tests/fixtures/validator/harness_state_6.json`: валидатор (`--strict`) и симулятор, оба профиля 22-60 |
| `make harness PROFILE=… [LIB=…] [SEGMENTS=…] [STATE=…] [OUT=…]` | часть общих сегментов модуля из стартового состояния (раздел 7): валидатор (с `--write-state OUT`), затем симулятор; `LIB` по умолчанию `addons/FastesBoooy_Guides`, пустой `SEGMENTS` — все сегменты |
| `make report` | пишет `docs/VALIDATION.md` (сводный Markdown-отчёт валидатора, раздел 5). Ошибки маршрутов не роняют цель; цель падает, если валидатор не записал отчёт (ошибка Lua в генераторе, неверные аргументы): отчёт сначала пишется во временный файл, так что `docs/VALIDATION.md` либо новый, либо не тронут. `REPORT=файл` — писать в другой файл |
| `make routedata` / `make routedata-check` | перегенерировать / проверить актуальность `Data.lua` всех модулей маршрутов и библиотек (check — и фикстуры `FxClean`, `TestLib`, `TestComposed`, `FxHarnessLib`, `TestGuides`, без поправок) |
| `make api BIR=… WOWUI=…` | перегенерировать `data/forever_api.lua` (оба пути обязательны; `WOWUI=none` — без глобалов FrameXML) |
| `make db RESEARCH=… CONVERSION=…` | перегенерировать `data/forever_db.lua` (`CONVERSION` = `QuestieDB/data/Forever/conversion.json` или `none`; количества целей — из `data/wowhead_requirements.json`) |
| `make requirements` | заново скачать `data/wowhead_requirements.json` (сеть; потом `make db`) |
| `make package` | архивы аддонов в `dist/` (воспроизводимые: фиксированные даты, сортировка) |

Измеренное время на 4 ядрах (F1, два маршрута прежних модулей): валидатор 0,5 с на весь запуск
(≈ 0,2 с на маршрут), одна симуляция маршрута ≈ 26 с, восемь sync-прогонов маршрута ≈ 150 с
процессорного времени, `busted` ≈ 100 с, `lint` 3–6 с. Симуляции независимы и масштабируются по
ядрам линейно: `make simulate` для двух маршрутов — 29 с вместо 52 с подряд, `make simulate-sync`
(16 прогонов, 302 с процессорного времени) — 82 с. Время `make check` и `make simulate-sync-full`
на нынешних маршрутах — в последнем hand-over (`docs/dev/handover/`).

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
| `addons/FastesBoooy_*/**`, `tests/fixtures/FastesBoooy_*/**`, `tests/fixtures/*/FastesBoooy_*/**` | `fastesboooy_route` (модули маршрутов **и модули-библиотеки**): только чтение `FastesBoooy.RegisterRoute/AddSegment/AddRouteData/UseSegments/AddInsert/AddLibrarySegment/AddLibraryInsert/AddLibraryData` и базовый Lua, который даёт песочница инструментов (`ipairs pairs next select type tostring tonumber unpack string table math`). `C_*`, SavedVariables, `io` / `os` / `print` и запись в глобальные имена остаются ошибками |
| `tools/overrides/*.lua` | `none`: никаких глобальных имён (файл — одно `return { ... }`) |
| `tools/**` | `lua51` |
| `tests/spec/**`, `tests/mocks/**`, `tests/fixtures/core/helpers.lua` | `lua51+busted` (мок ставит глобалы WoW; ослабленные правила только здесь) |

Длина строки — 140. Доказательство, что std работает: `tests/spec/validator_lint_spec.lua`
(неверное имя API даёт предупреждение, верное — нет).

## 3. Снимок БД: `build_db_snapshot.py` → `data/forever_db.lua`

```
python3 -I tools/build_db_snapshot.py --research <research> \
        --conversion <QuestieDB>/data/Forever/conversion.json|none [--out tools/data/forever_db.lua] [--date 2026-11-07] \
        [--requirements tools/data/wowhead_requirements.json|none]
python3 -I tools/fetch_wowhead_requirements.py [--db tools/data/forever_db.lua | --ids FILE] [--cache DIR] \
        [--out tools/data/wowhead_requirements.json] [--date 2026-11-08]
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
* **Количество целей** — по порядку: список «Requirements:» подсказки Wowhead Forever
  (`--requirements`, по умолчанию `data/wowhead_requirements.json`: строка `Имя x N`, без `x N` —
  1; сопоставляется с целью creature / killCredit / item / object по имени без учёта регистра),
  иначе WCLBox `goals` / `need`, иначе число перед именем цели в тексте QuestieDB. Числа research-
  входов — эпохи Classic и местами противоречивы: 545 Dalaran Patrols — 12 Elemental Slaves в
  тексте QuestieDB и в WCLBox, в Forever 8 (и текст, и требования подсказки Wowhead Forever);
  532 Battle of Hillsbrad — WCLBox 4 Hillsbrad Councilmen, Forever 5; у WCLBox 364 `goals` 5+5 при
  собственном тексте 8+8, Wowhead Forever — 8+8; у новых квестов Forever количеств там нет вовсе
  (96260 Crystalline Silk x3, 97250 Encroaching Soldier x2, 98070 по 5 гарпий каждого вида). Из
  Wowhead взято 2 666 количеств, 747 из них отличаются от прежних (`meta.counts.objectiveCounts.*`:
  `wowhead`, `wowheadChanged`, `research` — сколько осталось из research-входов: у 116 квестов
  подсказка без списка, у части целей имя в подсказке другое — «поговорить», «сопроводить»).
  Подсказки — данные клиента Forever по Wowhead; в игре не сверялись. Обновить:
  `make requirements`, затем `make db`.
* **Иконка цели** (`icon`) — у целей creature/killCredit хранится иконка QuestieDB, если это не
  «убить» (0/1 не пишутся): `enums.iconTypes` — 3 EVENT («освободить», кредит-болванка),
  5 TALK («поговорить»), 17 INTERACT («вылечить», «применить предмет на»). Цель-существо
  записывается как `{id, count?, icon = N}`. `objectives.event = true` — квест завершается
  триггером области / скриптом (исследование, сопровождение); где триггер, если QuestieDB его знает
  (`triggerEnd`, 138 квестов) — `objectives.trigger = {[uiMapID] = {{x, y}, ...}}`, а
  `objectives.escort = true`, когда текст триггера — «Escort …» (сопровождение: начинается у
  выдающего, триггер — где оно кончается). Валидатор: `complete-far-from-trigger`.
* **Требование профессии** — `reqSkill = {skillLine, значение}` (184 квеста; например 862 Dig Rat
  Stew — Cooking 15), имена — `enums.professions` (`COOKING = 185`, …). Валидатор: `quest-profession`.
* **Опыт квеста** (`xp`, `xpSrc`): опыт данжевых квестов Forever (`forever-dungeon`),
  иначе WCLBox (`wclbox-classic`, равен Classic), иначе QuestieDB XP (`questie-classic`);
  для 974 квестов опыт неизвестен (`xp = nil`): 537 новых квестов Forever и 437 «same», у которых
  WCLBox даёт `xp = 0`, а строки в QuestieDB XP нет (вероятно, квесты без опыта; не проверено) —
  валидатор оценивает его, а аддон записывает реальные значения в игре (`/fb xp`).
* **Дополнения** (`SUPPLEMENT_*` в начале скрипта): пробелы research-данных, найденные при работе
  над маршрутами, закрываются явно и детерминированно — только там, где во входе данных нет, до
  любой другой обработки, с источником у каждой записи и счётчиками `meta.counts.supplements.*`:
  принимающий у трёх новых квестов Forever без него, когда текст цели называет выдающего
  получателем (97539 Silky Sutures → Doctor Gregory Victor 12920, 96222 → Umarak 253066, 97265 →
  Aka'rai 268705; текст цели — трейс QuestieDB и подсказка Wowhead Forever); снятый флаг
  QUEST_GIVER у враждебного зверя 11741 Dredge Crusher (из-за него валидатор не считал опыт за 20
  убийств 8281); спавн Sulhasa 14242 (выдаёт/принимает 98093; подсказка Wowhead Forever: The
  Barrens 47.9, 77.6); объект 670338 Stolen Freewind Supplies (источник предмета 279383 квеста
  98069; 16 точек в Thousand Needles из подсказки Wowhead Forever).
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
* Размер ≈ 3,26 МБ (3 415 912 байт; было 2,6 МБ при охвате 1-22), загрузка ≈ 0,1 с. Счётчики
  (снимок 2026-11-07): квестов 3 095 (+2 138 в индексе): ядро 1 470, мир 997, подземелья 114, по
  спавну выдающего 82, классовые 233, по ссылкам 199; NPC 5 922 (+7 495; сервисных 1 077 — H 651, AH 273,
  неизвестная фракция 57, альянсовых в ядре 96; 22 с флагами из `subName`; 28 транспортных;
  3 949 целей/источников выпадения), объектов 776 (+6 268), предметов 2 270, карт 98 (53 с
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
            factionMasks = { Horde = 8589934770, Alliance = 4294967373 }, npcFlags = {...},
            professions = { COOKING = 185, FIRST_AID = 129, ... }, ... },
  coreAreas = { [85] = "Tirisfal Glades", ... },            -- ядро 1-22
  scopeAreas = { [400] = "Thousand Needles", [1337] = "Uldaman", ... }, -- все зоны и 5-местные подземелья
  zones = { [1420] = {name = "Tirisfal Glades", areaId = 85, scope = true, size = {4518.7, 3012.5}},
            [2548] = {name = "Riverglades", areaId = 16591, scope = true, size = {4850, 3233.3}, sizeSrc = "wclbox-map"}, ... },
  areaToUiMap = { [154] = 1420, ... }, areaNames = { [484] = "Freewind Post", ... },
  dungeons = { [16611] = {name, entrances = {{1458, 72.48, 11.33}}} },
  xp = { levels = {[1] = 400, ...}, questRule = {...}, mobRule = {...}, typicalQuestXpByLevel = {...} },
  quests = { [364] = { name, level, reqLevel, races, classes, side = "H", start = {npcs = {1569}},
                       finish = {npcs = {1569}}, breadcrumbs = {363}, objectives = {creatures = {{1501, 8}, {1502, 8}}},
                       zone = 154, uiMap = 1420, xp = 170, xpSrc = "wclbox-classic", status = "same" },
             [1149] = { ..., objectives = {event = true, trigger = {[1441] = {{26.43, 32.93}}}} },  -- area trigger
             [862] = { ..., reqSkill = {185, 15} },                                                 -- Cooking 15
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
lua5.1 tools/gen_route_data.lua --stdout --skip 'Classes/*' --keep Classes/Warrior.lua <каталог>
```

`--skip GLOB` / `--keep GLOB` (фильтр файлов TOC, как у валидатора) — только с `--stdout`: неполный
модуль в `Data.lua` не пишется. `--no-overrides` / `--overrides DIR` — как у валидатора (генератор
берёт из БД имена и `questMeta`; поправка предпосылок квеста меняет его `questMeta`).

Загружает `Route.lua` и сегменты (порядок TOC, сам `Data.lua` пропускается; модули-зависимости
`FastesBoooy_*` — раньше, как клиент) в песочнице (все файлы модуля получают одну общую
приватную таблицу `local _, ns = ...`, как в клиенте), собирает маршрут (`Core/Compose.lua`),
собирает id квестов (`accept/turnin/complete/abandon`, ключи `reward`), NPC (`npc`),
объектов (`object`), предметов (`collect`, `use`) и пишет для каждого маршрута
`FastesBoooy.AddRouteData("<id>", { quests = {[id] = "enUS"}, npcs = {...}, objects = ..., items = ..., places = ...,
questMeta = ... })`.

`questMeta` — для каждого квеста из `quests`, который знает снимок БД:
`[380] = { level = 4, reqLevel = 2, preAny = { 376 } }` (`level` = уровень квеста, `-1` —
масштабируется; `reqLevel`; `preAll` = `preQuestGroup`, `preAny` = `preQuestSingle` — только
непустые, отсортированы; у квестов вне полного снимка — только `level`/`reqLevel` из индекса).
Движок по ним пропускает серые и недоступные квесты (синхронизация по уровню,
`docs/ARCHITECTURE.md`); библиотечные `questMeta` подмешиваются под данные маршрута по квесту.
Пустая таблица не пишется.

**Модуль с общим содержимым и маршрутами** (форма `FastesBoooy_Guides`, фикстура `TestGuides`)
получает один вызов `FastesBoooy.AddLibraryData({...})` со всем, на что ссылаются его общие
сегменты **и общие вставки** (`AddLibraryInsert`). Маршрут, который ничем не владеет (нет своих
сегментов и вставок `AddInsert`), блока `AddRouteData` не получает: пустой блок был бы ошибкой
загрузки, когда `Data.lua` стоит в TOC раньше `Route.lua`. Квесты таблицы наград (`rewards`) —
квесты `turnin` шагов, отдельно их собирать не нужно.

**Общие сегменты** (`docs/ROUTE_FORMAT.md`, «Общие сегменты и вставки»). Модуль маршрута с
`UseSegments` перечисляет только то, на что ссылаются его **собственные сегменты и вставки**
(шаги библиотеки — не его). Модуль-библиотека (`AddLibrarySegment`, без маршрута) получает
`FastesBoooy.AddLibraryData({ quests = ..., npcs = ..., objects = ..., items = ..., places = ... })`
со всем, на что ссылаются **его** сегменты; в игре эти имена подмешиваются в данные каждого
маршрута, использующего библиотеку. Ошибки загрузки зависимости (файл `<Библиотека>/<файл>`)
тоже останавливают генерацию. Библиотека, объявленная в TOC (`## X-FastesBoooy-Module: library`),
у которой ещё нет сегментов (заготовка: файлы сегментов — только комментарии), получает пустой `AddLibraryData({ quests = {}, npcs = {} })`; модуль без маршрута,
без сегментов и без этого объявления — по-прежнему ошибка («no routes (and no library segments)»).

`places` — места действий `fp`/`fly`/`sethearth`/`hearth`:
`["Brill"] = { area = 159, en = "Brill", ru = "Брилл" }`. `area` — id зоны (AreaTable) с этим
enUS-именем из `areaNames` снимка БД: в игре аддон берёт локализованное имя у клиента
(`C_Map.GetAreaInfo`) — так `sethearth` узнаёт точку привязки по имени
(`GetBindLocation()`) на любом языке клиента, в том числе для мест Forever. `ru` — из таблицы
`PLACE_NAMES_RU` в начале `gen_route_data.lua` (запасной вариант, если клиент имени не дал);
новое место маршрута добавляйте туда (таблица одна на все зоны: при параллельной работе её
правит один владелец, остальные сообщают новые места). Место без `area` и без `ru` не пишется (показывается
по-английски), генератор сообщает о нём в stderr (`note:`).

Вывод детерминирован (сортировка по id / имени). Если у модуля есть ошибки загрузки/схемы,
`Data.lua` не пишется (и не печатается) и код выхода — 1.

## 5. Валидатор: `validate_routes.lua`

```
lua5.1 tools/validate_routes.lua [опции] [каталог-модуля ...]
```

Без каталогов проверяет все `addons/FastesBoooy_*/` с TOC (модули маршрутов — собранными вместе с их
библиотеками-зависимостями, и сами модули-библиотеки). `--help` печатает опции теми же группами.

**Выбор**

| Опция | Смысл |
|---|---|
| `--route ID[,ID...]` | только эти маршруты; `*` — подстановка (`'orc-*,troll-*'`, `'*-warrior'`). Можно повторять (списки складываются). Каждый элемент должен совпасть хотя бы с одним маршрутом (иначе код 2). Так выбирают расу / класс |
| `--profile race=Scourge,class=PALADIN[,faction=Horde]` | **переопределить** профиль игрока у выбранных маршрутов. Это не фильтр: маршруты выбирает `--route` |
| `--skip GLOB` | не загружать файлы TOC, подходящие под шаблон (можно повторять; `*` — подстановка, путь TOC с прямыми косыми чертами: `'Classes/*'`). Чужой недописанный файл не останавливает остальных |
| `--keep GLOB` | …кроме этих (можно повторять): файл пропускается, если подходит под `--skip` и ни под один `--keep` |
| `--own GLOB` | файлы, за которые отвечает вызывающий (можно повторять; по умолчанию — все загруженные). С `--strict` запуск роняют только предупреждения в своих файлах, остальные печатаются блоком «foreign warnings»; при неполной загрузке проверки шаблонов чужих файлов — заметки. Ошибки считаются всегда, в любом файле |
| `--db FILE` | другой снимок БД |
| `--no-overrides` / `--overrides DIR` | не применять поправки `tools/overrides/*.lua` / взять их из другого каталога |
| `--addons DIR` | где искать модули |

Шаблон `--skip` / `--keep`, который не совпал ни с одним файлом TOC, и `--own`, который не совпал ни
с одним загруженным файлом, — ошибка запуска (код 2): опечатка иначе молча оставила бы свой файл
незагруженным или сделала бы чужими все предупреждения. Регистр учитывается.

**Ворота**

| Опция | Смысл |
|---|---|
| `--strict` | непринятое предупреждение тоже даёт код выхода 1. Принято — значит код указан в `ok` шага (для `segment-level` — сегмента): `ok = "код"`, `{ "код", ... }` или `{ ["level-grind"] = N }` (потолок убийств) |
| `--end-level` | ERROR `end-level`, если обычный прогон или худший случай заканчивается ниже планового уровня маршрута (`levels[2]`; в harness — последнего сегмента). Без опции `route-level` — WARN и терпит один уровень |
| `--grind-until SEG` | считать гринд от начала маршрута до конца сегмента `SEG` (для `--summary` и `--write-baseline`). Сегмент, которого нет ни в одном проверенном маршруте, — код 2 |
| `--max-grind-until SEG=N/W` | ERROR `grind-budget`, если эти убийства больше `N` (обычный прогон) или `W` (худший случай); маршрут без сегмента `SEG` — тоже ERROR |
| `--write-baseline FILE` | записать JSON: по каждой расе (`raceFile`) максимум по проверенным маршрутам — гринд всего (обычный / худший) и пара `--grind-until` |
| `--baseline FILE` | ERROR `grind-baseline`, если маршруту нужно больше убийств (обычный или худший), чем записано для его расы; нет записи расы — тоже ERROR |

**Вывод**

| Опция | Смысл |
|---|---|
| `--summary` | после обычного вывода — строка TSV на маршрут: маршрут, профиль, ошибки, предупреждения (непринятые, в своих файлах), принято, чужие, уровень в конце, то же в худшем случае, гринд, гринд в худшем случае, гринд до `--grind-until`, то же в худшем случае (`-` без `--grind-until`). Числа критериев читают отсюда, а не складывают вручную |
| `--levels` | ровно для одного «маршрут × профиль»: после обычного вывода — строка TSV на каждый шаг с явным id: id, сегмент, уровень перед шагом, то же в худшем случае, якорь вставки или `-`, файл, действия. Так автор класса видит, куда встали его шаги и на каком уровне |
| `--json FILE` | полный отчёт (включая INFO) в JSON |
| `--markdown FILE` | сводный Markdown-отчёт (`make report` → `docs/VALIDATION.md`), см. «Отчёт `docs/VALIDATION.md`» |
| `-v` / `-q` | показать INFO и принятые предупреждения / только итоговые строки |

**Проверки**

| Опция | Смысл |
|---|---|
| `--tolerance-yards N` / `--hard-tolerance-yards N` | пороги расстояния `at` → спавн в ярдах (по умолчанию 40 / 120) |
| `--tolerance N` / `--hard-tolerance N` | те же пороги в единицах карты (%) для карт без известного размера (по умолчанию 3.0 / 8.0; помечается «approximate») |
| `--ignore код,код` | подавить коды сообщений (например `quest-carried`) |
| `--xp-optimism N` | множитель оценённого опыта для «оптимистичной» симуляции (по умолчанию 2.0) |
| `--incidental-pct P` | **попутные убийства** в пути: каждая сдача квеста даёт ещё P % его опыта как опыт за мобов (0..100; по умолчанию 0 — выключено). Меняет основную симуляцию (уровни, проверки уровня, `--write-state`); полоса 0 % / 15 % в отчёте о гринде печатается всегда |

**Состояния и harness** (раздел 7)

| Опция | Смысл |
|---|---|
| `--state FILE` | начать симуляцию не с нового персонажа 1 уровня, а из состояния |
| `--write-state FILE` | записать состояние в конце прогона (тот же формат); нужен ровно один «маршрут × профиль» (`--route`, `--profile`) |
| `--until ID` | с `--write-state`: записать состояние **перед** шагом `ID` или первым шагом сегмента `ID` (например `--until h-22-hillsbrad` — конец собственной части 1-22 маршрута = старт первого сегмента библиотеки); id, которого нет в маршруте, — код 2 |
| `--harness DIR` | проверить часть общих сегментов модуля `DIR` (модуль-библиотека или модуль, который регистрирует и маршруты): синтетический маршрут одного `--profile` (раса и класс обязательны) из сегментов `--segments`; общие вставки модуля применяются, шаги других рас / классов не собираются |
| `--segments ID,…` | сегменты для `--harness`, в этом порядке (по умолчанию — все общие сегменты модуля в порядке TOC) |

Пустое значение `--state` / `--write-state` / `--segments` равно отсутствию опции (так их
передаёт `make harness`).

Код выхода: 0 — нет ошибок (и harness на модуле без общих сегментов — «nothing to validate»);
1 — есть ERROR (или непринятый WARN в своих файлах при `--strict`); 2 — ошибка запуска: неверные
опции, файл состояния, `--harness` без расы/класса или на модуле маршрута без общих сегментов,
элемент `--route`, не совпавший ни с одним маршрутом, шаблон `--skip` / `--keep` / `--own`, не
совпавший ни с одним файлом, сегмент `--grind-until`, которого нет в проверенных маршрутах,
`--write-state` или `--levels` при числе прогонов, отличном от одного, `--until` без
`--write-state` или с id, которого нет в маршруте.

### Команды для параллельной работы над одним модулем

```
# автор класса: свой файл, остальные файлы классов не загружаются
lua5.1 tools/validate_routes.lua -q --strict --end-level --summary --route '*-warrior' \
    --skip 'Classes/*' --keep Classes/Warrior.lua --own Classes/Warrior.lua
# куда встали мои шаги и на каком уровне
lua5.1 tools/validate_routes.lua -q --levels --route orc-warrior --skip 'Classes/*' --keep Classes/Warrior.lua
# автор стартовой зоны: свои сегменты с нового персонажа, без шагов классов
lua5.1 tools/validate_routes.lua --harness addons/FastesBoooy_Guides --segments <id,...> \
    --profile race=Orc,class=WARRIOR --skip 'Classes/*' --end-level --write-state orc.json
```

* `--own` сравнивается с файлом сообщения (`Classes/Warrior.lua`). Сообщение без файла
  (`route-level`) относится к файлу, который зарегистрировал маршрут (`Route.lua`).
* `--route` не прячет сломанный файл: файл, который не загрузился или не дошёл до конца, роняет
  любой запуск, который его загружает, — что он дал бы выбранным маршрутам, неизвестно. Чужой
  сломанный файл исключают через `--skip`. С `--route` заметкой (не ошибкой) становится только то,
  что доказуемо относится к невыбранному маршруту: ошибка регистрации или сборки другого маршрута,
  ошибка схемы в файле, содержимое которого ушло только в невыбранные маршруты. Свои файлы
  (`--own`) считаются всегда.
* С `--skip` не оцениваются `ok-unused` и `shared-unused` (их видит только полный запуск), а
  `override-load` становится заметкой.

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
   (в тексте — префикс `[library <модуль>]`, в JSON — поля `library` и `shared`) и
   выводятся **один раз на маршрут** (одинаковые сообщения следующих профилей маршрута
   отбрасываются, счётчик — `libraryRepeats`). Модуль-библиотека — не маршрут: в отчёте у него
   своя запись `== library module …` (число сегментов и шагов) только с его ошибками загрузки/
   схемы; если библиотека входит в запуск, модули маршрутов эти ошибки не повторяют, иначе они
   выводятся в маршруте, который её использует.
   **Модуль с общим содержимым и маршрутами** (общие сегменты, общие вставки `AddLibraryInsert`
   и маршруты в одном аддоне) получает перед своими маршрутами ещё одну запись `(shared <Модуль>)`
   — проверки **шаблонов** (`lib/module_checks.lua`), один раз, что бы ни выбрал `--route`.
   Шаблон с опечаткой в расе или вставка с неверным якорем не попадают ни в один маршрут и в
   собранных маршрутах не видны, поэтому проверяются сами шаблоны: `unknown-race-token`,
   `insert-anchor-unknown`, `insert-unapplied`, `shared-step-unused`,
   `insert-scope-wider-than-anchor`, `ok-needs-ceiling`, `shared-unused` (таблица кодов ниже).
   Чистая библиотека и модуль маршрута без общего содержимого этих проверок не получают; модуль
   маршрута не проверяет шаблоны своих зависимостей; harness их пропускает. При неполной
   загрузке (`--skip` / `--keep`) первые пять проверок для файлов, которые не свои (`--own`),
   печатаются **заметками** и не меняют код выхода: якорь или маршрут может жить в пропущенном
   файле. `ok-needs-ceiling` заметкой не бывает (зависит только от самого шага);
   `shared-unused` проверяется только на полной загрузке.
   **Поправки к БД** (`tools/overrides/*.lua`, `DB.ApplyOverrides`, формат —
   `overrides/README.md`): сначала `DB.Prepare` считает медианы опыта по снимку, потом
   применяются поправки (сначала `shared.lua`, затем остальные по алфавиту, каждый файл под
   `pcall`). Сломанный файл пропускается целиком: ERROR `override-load` в записи `(overrides)`
   (заметка при `--skip`). ERROR `override-foreign-quest` — поправка не из `shared.lua` называет
   квест, который использует загруженный шаг вне файлов её владельца. `DB.Load` поправок не
   применяет, а все спеки и цели фикстур передают `--no-overrides`: числа в тестах от каталога
   не зависят.
2. Профили: каждая пара (раса × класс) из метаданных маршрута; фракция — из маршрута.
   `raceFile` → бит расы через `enums.raceFileToBit` (Нежить = `Scourge`; `Skyborne` —
   по фракции: Орда 2^33, Альянс 2^32; Skyborne-маршрут без `faction` проверяется за обе
   стороны). Один раз на маршрут: токены рас маршрута и фильтров шагов сверяются с
   `raceFileToBit` (`unknown-race-token`), собственный шаг маршрута (свой сегмент, вставка
   `AddInsert`), который не видит ни один профиль, — WARN `step-no-profile`. Общий шаг, который
   не подходит маршруту, в него не собирается вовсе (`docs/ROUTE_FORMAT.md`, «Фильтры в общих
   шагах»), поэтому для общих шагов это предупреждение заменено проверкой шаблонов
   `shared-step-unused`.
3. Шаги проходят по порядку; шаги, не подходящие по `class/race/faction`, пропускаются
   (INFO). Внутри шага действия выполняются в порядке игрока у одного NPC: abandon →
   цели/предметы квестов, уже бывших в журнале → turnin → accept → цели и сдача квестов,
   взятых этим же шагом → остальное в порядке `Schema.ACTION_ORDER`. Так работают «сдать и
   сразу взять», `{accept=Q, turnin=Q}`, `{accept=Q, complete=Q}`, `{complete=Q, turnin=Q}`.
4. Симуляция: журнал квестов, сданные/брошенные, опыт и уровень.
   * старт: уровень 1, 0 опыта; таблица опыта = Classic Era (`xp.levels`);
   * `turnin`: опыт квеста × штраф за разницу уровней Classic (`mult = clamp(2*(qL-pL)+20, 1, 10)/10`,
     округление клиента); неизвестный опыт → медиана известных квестов того же уровня (INFO `xp-unknown`;
     в строке итога — «N quests with estimated XP (P% of quest XP)»);
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
   * rested-бонус, еда, лагерь и групповой опыт не моделируются;
   * `--incidental-pct P` (по умолчанию 0): мобы, убитые по дороге между шагами, — P % опыта
     каждого сданного квеста (с тем же штрафом за уровень, что и квест) добавляются как опыт за
     мобов (`summary.xpIncidental`). Реалистичная доля неизвестна (зависит от игрока и класса),
     поэтому опция явная и по умолчанию выключена.
5. **Отчёт о гринде** (`V.RunProfile`): кроме основного прогона (его сообщения, уровни и конечное
   состояние — это отчёт) для каждого профиля идут теневые прогоны, которые только симулируют:
   * **худший случай** — шаги `optional = true` **не выполняются**: их опыт не считается, квесты,
     которые они берут, не взяты (последующие `complete`/`turnin` этих квестов пропускаются, опыта
     нет), квесты, которые они сдают, остаются несданными. Обязательный (не `optional`) шаг, которому
     нужен такой квест, — **ERROR `optional-dependency`** («required step depends on optional
     quest»): не-`bg` шаг с `complete`/`turnin` квеста, взятого только необязательным шагом (курсор
     остановился бы на нём до «Пропустить»), или `accept`, предквест которого (`preGroup`/`preSingle`) сдаётся
     только необязательным шагом (NPC не выдаст квест). `bg`-шаги и `abandon` таких квестов просто
     пропускаются. Необязательный шаг `level` в худшем случае тоже не выполняется — его гринд
     переходит к следующему порогу;
   * **полоса попутных убийств**: 0 % и 15 % (`V.DEFAULTS.incidentalBandPct`), каждый — в обычном и
     в худшем случае (совпадающие прогоны не повторяются; маршрут без `optional`-шагов — худший
     случай = обычный).

   По каждому шагу `level` (порогу) печатается число убийств мобов своего уровня до порога в обоих
   режимах (и с 15 %), по сегментам — суммы, в конце — строки `grind kills: N (worst case M)` (при
   `--incidental-pct` — с этим процентом) и `grind kills band: incidental kills 0% -> … , 15% of
   quest XP -> …`. Сценарий, где игрок пропускает все необязательные квесты и не убивает ничего по
   дороге, — верхняя граница; 15 % — ориентир «реалистичной» полосы.

   Худший случай следит и за сервисными шагами: обязательный `fly X`, точку полёта которого
   изучает только необязательный шаг `fp X`, и обязательный `hearth X`, единственная привязка
   которого — необязательный `sethearth X`, — тоже ERROR `optional-dependency` (обязательный
   `sethearth` после необязательного зависимость снимает).
6. **Принятые предупреждения** (ключ `ok` шага / сегмента, `docs/ROUTE_FORMAT.md`). WARN, код
   которого указан в `ok` его шага (сегмента — для `segment-level`), **принят**: не печатается без
   `-v` (с `-v` — строкой `ok`), считается отдельно («W warning(s), A accepted»), `--strict` его
   не считает. `ok = { ["level-grind"] = N }` принимает, только пока порогу нужно не больше `N`
   убийств в обычном прогоне; выше — снова WARN с пометкой «above the acknowledged ceiling».
   `level-grind` без потолка — ERROR `ok-needs-ceiling`. Устаревшая запись — WARN `ok-unused`:
   код из `ok`, о котором на этом шаге не сообщает ни один проверенный маршрут с этим шагом
   (только полный запуск: без `--route`, `--skip`, `--profile`, `--state`, `--harness`).
   «Сообщает» — с любым уровнем: порог с `ok = { ["level-grind"] = 90 }`, которому нужно 20 убийств
   (INFO), не устарел. ERROR принять нельзя.
7. **Числовые критерии** (`--end-level`, `--max-grind-until`, `--baseline`) дают ERROR на маршруте
   (без шага): `-q` печатает только счётчики сообщений, `route-level` терпит один уровень, а
   `level-grind` предупреждает лишь о пороге больше 30 убийств — без этих опций числа приёмки
   никто не проверяет. Все они работают и в harness-прогонах.

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
| `questlog-full` | ERROR | в журнале больше `questLogSize` (40) квестов (считая `log` стартового состояния; переполненное состояние — ошибка на шаге `start-state`) |
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
| `quest-carried` | WARN / INFO | квест не сдан и не брошен к концу маршрута (в harness — INFO: квест переходит в следующий сегмент, `log` конечного состояния) |
| `npc-unknown` / `object-unknown` | ERROR | NPC/объекта нет в БД Forever |
| `npc-out-of-scope` / `object-out-of-scope` | WARN | существует, но вне снимка (позиция не проверена) |
| `at-map-unknown` | ERROR | неизвестный uiMapID |
| `at-far` | WARN / ERROR | ближайший спавн NPC/объекта шага дальше 40 / 120 ярдов (карты без размера: 3 / 8 единиц карты, «approximate»; у прореженных спавнов вычитается 2·√2 единицы) |
| `at-no-spawn` | ERROR | у NPC/объекта нет спавна на карте `at` |
| `at-far-from-giver` | WARN | шаг accept/turnin без `npc`: `at` дальше порога от выдающих/принимающих (ярды; без размера карты — единицы) |
| `at-instance` | INFO | NPC внутри инстанса — позицию не проверить |
| `train-wrong-trainer` | ERROR | NPC не тренер класса маршрута (`subName` «<Class> Trainer») |
| `train-not-class-trainer` | WARN | тренер профессии, а не класса |
| `train-service` | INFO | принят как сервисный тренер: у NPC флаг тренера и подпись содержит «weapon master» или «riding» (любой класс), «pet trainer» (только HUNTER), «portal trainer» (только MAGE). Тренеры демонов — торговцы: шаг `vendor` |
| `train-no-npc` | WARN | шаг `train` без NPC |
| `not-flightmaster` | ERROR | `fp`/`fly` у NPC без флага полётчика |
| `fly-unknown-fp` | WARN | `fly X`, но точка полёта X не изучена раньше (нет шага `fp X`, нет в `flightPaths` стартового состояния): такого полёта на карте нет |
| `not-innkeeper` | ERROR | `sethearth` не у трактирщика |
| `not-vendor` | WARN | `vendor` у NPC без флага торговца/ремонта |
| `npc-hostile` | ERROR | NPC тренера/полётов/таверны/торговли не дружелюбен фракции (`A`/`H`/`AH`) |
| `hearth-mismatch` / `hearth-unbound` | WARN / INFO | камень привязан к другому месту / не было `sethearth` |
| `xp-unknown` | INFO | опыт квеста неизвестен — использована оценка (медиана по уровню квеста) |
| `complete-kill-xp` | INFO | оценка убийств и опыта за цели |
| `complete-no-kill` | INFO | цели, за которые опыт убийств не начисляется (поговорить/вылечить/событие, дружелюбный или служебный NPC, выдающий квест), с причиной |
| `level-grind` | INFO / WARN | сколько убийств нужно до уровня шага `level` (WARN если > 30). Принимается только с потолком: `ok = { ["level-grind"] = N }` |
| `optional-dependency` | ERROR | худший случай (необязательные шаги не выполнены): обязательный шаг зависит от необязательного квеста — не-`bg` `complete`/`turnin` квеста, взятого только шагом `optional`, или `accept`, предквест которого сдаётся только шагом `optional` («required step depends on optional quest»); обязательный `fly X` / `hearth X`, для которого точку полёта / привязку даёт только необязательный `fp X` / `sethearth X`. Исправление: сделать и этот шаг `optional` или взятие/сдачу/визит обязательными |
| `skip-ahead` | WARN | шаг-переход / transient / `optional`, который перемотка движка может пропустить: более поздний не-`bg` шаг, все действия `accept`/`complete` которого может выполнить **раньше** `bg`-цель (`bg`-шаг с `complete` тех же целей или `accept`/`turnin` того же квеста), более ранний шаг с `complete` тех же целей или стартовое состояние (квест в `complete`), становится опорным, как только эта цель выполнена, — и все transient-действия и `optional`-шаги до него считаются выполненными. Сообщение — на пропускаемом шаге (туда и `ok = "skip-ahead"` с причиной в комментарии); шаг с `turnin`/`abandon` раньше не выполняется и не опорный |
| `lookahead-skip` | WARN | шаг-визит (`train` / `vendor` / `fp` / `sethearth`, не `bg`, не `optional`, с `npc`) у NPC X, за которым в пределах `lookahead` (6) шагов идёт шаг только из `accept` квестов X и `turnin` уже выполненных квестов X: разговор с X открывает сначала диалог, автоматика берёт / сдаёт квесты, тот шаг становится опорным и визит перематывается до открытия окна. Исправление: объединить действия в один шаг или поставить визит после (docs/ROUTE_FORMAT.md, «Шаг-визит перед квестом того же NPC»). Сообщение — на шаге-визите |
| `quest-profession` | WARN / INFO | `accept` квеста с требованием профессии (`reqSkill`) в обязательном шаге — WARN (персонаж без профессии квест не возьмёт, гайд встанет); в `optional`-шаге — INFO; обязательный не-`bg` шаг `complete`/`turnin` такого квеста после `optional`-взятия — WARN |
| `complete-far-from-trigger` | WARN | `complete` квеста с триггером области (`objectives.trigger`: исследование, «прыгните с досок»), а ни `at` шага, ни `at` одного из шагов после взятия квеста не ближе жёсткого порога (120 ярдов / 8 единиц карты) к триггеру — стрелка ведёт не туда. Сопровождения (`objectives.escort`) не проверяются; шаг с `complete = { [id] = {…} }` (выбранные цели) тоже |
| `segment-level` / `route-level` | WARN | симулированный уровень в конце сегмента / маршрута отличается от плана больше чем на 1 |
| `step-skipped` | INFO | шаг отфильтрован по классу/расе/фракции |
| `unknown-race-token` | ERROR | токен расы маршрута, фильтра шага или области общей вставки — не `raceFile` из `UnitRace()` (например `Undead` вместо `Scourge`): шаг молча пропал бы у всех. Для общих шагов проверяются шаблоны (такой шаг не собран ни в один маршрут) |
| `step-no-profile` | WARN | собственный шаг маршрута (свой сегмент, вставка `AddInsert`) не подходит ни одному профилю маршрута — его никто не увидит. Для общих шагов — `shared-step-unused` |
| `insert-anchor-unknown` | ERROR | шаблоны: якорь общей вставки — id, которого нет ни у одного загруженного шага (общего сегмента или общей вставки) |
| `insert-unapplied` | ERROR | шаблоны: якорь существует и хотя бы один загруженный маршрут подходит под область вставки, но ни в одном из них якоря нет (якорь из чужой зоны: `race = "Orc"` после шага Мулгора) |
| `shared-step-unused` | ERROR | шаблоны: шаг общего сегмента или общей вставки не собран ни в один загруженный маршрут (фильтр, который не подходит ни одному маршруту). Для вставки, ни один шаг которой не собран, — одно сообщение; не повторяется для вставки, о которой уже сообщили `insert-anchor-unknown` / `insert-unapplied` / `unknown-race-token`, и для шагов сегмента из `shared-unused` |
| `insert-scope-wider-than-anchor` | ERROR | шаблоны: у якоря есть фильтр, а область шага вставки (своя или вставки) не является его подмножеством в каком-то отфильтрованном измерении |
| `shared-unused` | WARN | шаблоны: общий сегмент не использует ни один маршрут (только полная загрузка) |
| `ok-needs-ceiling` | ERROR | `ok` называет `level-grind` без потолка (на шаге или на сегменте): нужно `ok = { ["level-grind"] = N }`. Никогда не заметка |
| `ok-unused` | WARN | код в `ok` шага / сегмента, о котором там не сообщает ни один проверенный маршрут с этим шагом (только полный запуск; общий шаг — один раз, в записи модуля) |
| `db-override-unverified` | WARN | шаг проходит проверку (раса, класс, взаимоисключение, предусловие, тренер) только благодаря поправке к БД с `verified = false`. Проверить в игре или принять: `ok = "db-override-unverified"` и комментарий `-- CONFIRM:` |
| `override-load` | ERROR | файл поправок не загрузился или записан с ошибкой формата и пропущен целиком (запись `(overrides)`; заметка при `--skip`) |
| `override-foreign-quest` | ERROR | поправка не из `shared.lua` называет квест, который использует загруженный шаг вне файлов её владельца: значение принадлежит `shared.lua` |
| `end-level` | ERROR | `--end-level`: обычный прогон или худший случай заканчивается ниже планового уровня |
| `grind-budget` | ERROR | `--max-grind-until SEG=N/W`: гринд до конца `SEG` больше бюджета (или у маршрута нет такого сегмента) |
| `grind-baseline` | ERROR | `--baseline FILE`: маршруту нужно больше убийств, чем записано для его расы (или записи расы нет) |
| `profile-race` / `profile-class` / `profile-faction` | ERROR / WARN | неизвестный профиль (в т. ч. `raceFile` обеих фракций без `faction`) |
| `route-empty` | ERROR | у маршрута нет шагов |

### Вывод

* stdout: ERROR/WARN (с `-v` и INFO, и принятые предупреждения строкой `ok`) в виде
  `SEVERITY [library модуль] сегмент#шаг id=… (файл) [код] сообщение`
  (`[library …]` — у шагов общих сегментов и общих вставок; вставленный шаг показывается номером якоря и своим id),
  таблица сегментов (план уровней, симулированный уровень начала → конца, опыт квестов/мобов/
  гринда, журнал), строка итога симуляции (`end level …; N quests with estimated XP (P% of quest XP)`),
  затем **отчёт о гринде** (раздел
  «Как работает», п. 5): таблица порогов `level gates` (порог, убийств, в худшем случае, с 15 %,
  худший с 15 %, шаг; у необязательного порога в худших столбцах «-»), таблица `grind kills per
  segment` (те же суммы по сегментам и число невыполненных в худшем случае `optional`-шагов),
  строки `grind kills: N (worst case M); worst case = K optional step(s) not done (Q quest
  accept(s)), end level L` и `grind kills band: …`; с `--grind-until` — `grind kills up to the end of
  SEG: N (worst case W)`; затем итог маршрута (`result: E error(s), W warning(s)[, A accepted], I
  info`). `-q` печатает только строки итога;
* запись модуля: `== shared content of module <Модуль> […]` (проверки шаблонов), `== library module
  …`, `== DB overrides <каталог>`; у `-q` — строка `(shared <Модуль>) [shared: N segment(s), M
  insert(s), K step(s)]: …`;
* **заметки** — сообщения, которые не меняют код выхода (неполная загрузка, `--route`):
  `  note  <где> [код] текст -- not counted: <причина>`, блоком `== notes for module …`; в JSON — `notes`;
* с `--own`: блок `foreign warnings: N (report them in the hand-over)` — по строке на место и код
  (сообщение самого маршрута, без шага, — по строке на маршрут); в строке `-q` — `(N of the warnings
  foreign)`;
* если применены поправки: `validate_routes: DB overrides from <каталог>: N file(s) (…), Q quest(s),
  P npc(s)`; последняя строка — `validate_routes: M module(s), E error(s), W warning(s)[, A accepted]
  [(N of them foreign)] [(strict)]`;
* `--summary`, `--levels` — строки TSV после всего остального (см. опции);
* `--json`: `{ db, totals, routes = [{ route, module, profile, counts, summary, segments, messages,
  accepted, foreign, shared }], notes }` — полный вид каждого маршрута, включая INFO. У сообщения
  рядом с текстом стабильные поля: `quest`, `npc`, `object`, `kills`, `level`, `file`, `shared` (шаг
  общего сегмента или общей вставки), `inserted` (шаг вставки `AddInsert` / `AddLibraryInsert`),
  `accepted`, `okCeiling`, `foreign`, `override`;
  отчёт о гринде — `summary.grindKillsWorst`, `xpGrindWorst`, `endLevelWorst`, `optionalSkipped`,
  `optionalAccepts`, `incidentalPct`, `xpIncidental`, `xpQuestEstimatedPct`, `grindUntil`, `band`
  (`"0"`/`"15"`: `grindKills`, `grindKillsWorst`, `endLevel`, `endLevelWorst`), `gates` (`segment`,
  `step`, `stepId`, `level`, `frac`, `from`, `kills`, `xp`, `killsWorst`, `optional`, `library`,
  `inserted`, `okCeiling`, `band`: `kills`/`worst`); у сегментов — `grindKillsWorst`,
  `optionalSkipped`, `band`, `library`;
* `--markdown`: сводный отчёт на русском для `docs/VALIDATION.md` (ниже). JSON и Markdown детерминированы;
* `--write-state`: конечное состояние (раздел 7), строка `end state of <маршрут> [<профиль>] written to …`
  (с `--until ID` — `state before ID of …`; в `meta.untilStep` — id шага, перед которым снято состояние).

### Отчёт `docs/VALIDATION.md`

`make report` = `lua5.1 tools/validate_routes.lua -q --markdown ФАЙЛ` (`lib/report.lua`) во
временный файл, который затем заменяет `docs/VALIDATION.md`; код выхода 1 (ошибки маршрутов)
допустим, отсутствие или пустота отчёта и любой другой код — ошибка цели. Текстовый вывод и JSON показывают каждый маршрут целиком; Markdown-отчёт
**сводный**: у 28 маршрутов общий путь один, и его сообщения показаны один раз. Разделы:

1. **Шапка и итог**: счётчики ERROR / WARN / INFO и принятых предупреждений по всему запуску;
   сколько строк ERROR и WARN остаётся без повторов.
2. **Модули и общие проверки**: записи, которые не являются прогонами, — модуль-библиотека,
   проверки шаблонов модуля (`(shared <Модуль>)`), поправки к БД, ошибки загрузки, заметки.
3. **Сводка по маршрутам**: строка на «маршрут × профиль» — ERROR, WARN, принято, уровень в конце
   (обычный прогон и худший случай), гринд (обычный / худший), гринд с попутными убийствами 15 %
   (обычный / худший), квесты с оценённым опытом и их доля, максимум журнала, число шагов и
   необязательных шагов.
4. **Сравнение путей**: *общий хвост* — самый длинный общий конец цепочек сегментов всех
   маршрутов, его первый сегмент — точка слияния. По каждому **стартовому участку** (сегменты до
   хвоста; маршруты с одинаковым участком — одна строка): уровень на входе в точку слияния и
   гринд до неё (мин–макс по маршрутам). Затем **каждый сегмент**: какие маршруты его проходят,
   уровень на входе и в конце, гринд в обычном и худшем случае (мин–макс). «Сливаться раньше или
   позже» читается из одной таблицы.
5. **Общие шаги**: каждое ERROR / WARN на шаге общего **сегмента** — одна строка на ключ (уровень,
   код, id шага или сегмент, id квеста) с колонкой «маршруты»: `все 28`, `все 7 troll-*`, `все 5
   *-warrior` (целые группы по расе или классу) или до трёх id и число остальных. Числа, которые
   зависят от прогона (симулированный уровень, недобор опыта, убийства), показаны диапазоном:
   тексты маршрутов сливаются число за числом (`~84–109 same-level kills`); если тексты
   различаются не только числами, показан первый и число вариантов. Принятые предупреждения — так
   же, свёрнутым списком; порог, принятый в одних маршрутах и превысивший потолок в других, виден
   в обеих таблицах со своими маршрутами.
6. **Пороги уровня на общих шагах**: шаги `level` общих сегментов и общих вставок — порог, шаг,
   маршруты, убийств минимум и максимум по маршрутам, максимум в худшем случае, потолок из
   `ok = { ["level-grind"] = N }`.
7. **Маршруты**: раздел на прогон — результат (и сколько из него на общих шагах), строка
   симуляции, абзац о гринде и собственные пороги маршрута, компактная таблица сегментов и
   **только собственные сообщения**: шаги своих сегментов, вставок `AddInsert` и общих вставок
   (шаги класса и расы), сообщения самого маршрута (`end-level`, `grind-budget`). Принятые —
   свёрнутым списком. INFO — одной строкой с числом по кодам.
8. **INFO по кодам**: число по коду за весь запуск и на маршрут (мин–макс). Тексты INFO в отчёт
   не выводятся (`-v`, `--json`).
9. **Что подтверждается только в игре**: постоянный список (`V.IN_GAME_ONLY`) и сгенерированный
   список принятых `db-override-unverified` — шагов, которые держатся на непроверенной поправке
   к БД.

Отчёт коммитится, CI проверяет его актуальность (`make report` + `git diff --exit-code`; упавший
генератор роняет `make report`, поэтому устаревший файл не сойдёт за свежий). Его
меняет любое изменение маршрутов, поэтому при параллельной работе его перегенерирует один
владелец в конце этапа.

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
* `tests/spec/validator_harness_spec.lua` — harness (раздел 7): декодер JSON, файл состояния
  (чтение, все ошибки списком, детерминированная запись, точность `xpFrac`), `Harness.Build`
  (порядок сегментов, все сегменты по умолчанию, неизвестный сегмент со списком известных,
  модуль маршрута / нет каталога, профиль), валидатор из состояния (чисто для обоих профилей;
  без состояния — `turnin-not-accepted`, `level-too-low`, `accept-prereq`, `fly-unknown-fp`; лог без
  `complete`; `accept-done` «at the start state»; ёмкость журнала с `log`; неизвестные квесты
  состояния; конечное состояние; **цепочка двух прогонов = один прогон**; конечное состояние
  полного маршрута; harness не сообщает `step-no-profile`), CLI обоих инструментов
  (`--harness/--state/--write-state`, коды выхода, пустая объявленная библиотека — понятное
  сообщение и пустой `AddLibraryData`), `## X-FastesBoooy-Module`. Фикстура:
  `tests/fixtures/validator/FastesBoooy_FxHarnessLib` (два сегмента, Мертвый Звон / Брилл,
  проходит только из состояния `tests/fixtures/validator/harness_state_6.json`).
* `tests/spec/validator_checks_spec.lua` — проверки `lookahead-skip` (визит к тренеру / торговцу перед
  квестом того же NPC в пределах `lookahead`; объединённый шаг, шаг дальше окна, `optional`-визит, сдача
  невыполненного квеста — без предупреждения), `quest-profession` (обязательное / `optional`-взятие,
  обязательная сдача после `optional`-взятия), `complete-far-from-trigger` (у триггера, `go`-шаг к
  триггеру, сопровождение — без предупреждения) и данные снимка, на которых они стоят (количества
  целей Wowhead Forever, `trigger`, `escort`, `reqSkill`, `enums.professions`).
* `tests/spec/validator_grind_spec.lua` — отчёт о гринде и `skip-ahead` на маршрутах в памяти
  (Мертвый Звон): худший случай (пропуск `optional`-шагов и их опыта, больше гринда на пороге,
  маршрут без `optional` — худший = обычный), `optional-dependency` (обязательные `complete`/`turnin`
  необязательного квеста, `accept` с предквестом, сданным только необязательным шагом, `bg`-шаг —
  без ошибки, полностью необязательная цепочка — без ошибки, `--ignore`), `--incidental-pct`
  (по умолчанию 0 — симуляция прежняя, 15 % — точная сумма, полоса не зависит от выбранного
  процента), вывод (старые строки текста не изменились, блок перед `result:`, «-» у
  необязательного порога, Markdown, JSON, чистая фикстура), `skip-ahead` (`bg`-цель → переход,
  `optional` и transient между ними; не при `turnin` в позднем шаге и не при неполном покрытии
  целей; более ранний шаг с теми же целями; стартовое состояние; шаги другого класса; один раз
  при теневых прогонах). CLI (`validator_cli_spec.lua`): строки отчёта, `--incidental-pct`
  (неверные значения — код 2), `-q` без отчёта.
* `tests/spec/validator_lint_spec.lua` — std `forever` ловит несуществующие API; модулям маршрутов
  известны `AddLibraryInsert` и базовый Lua, файлам поправок — ничего.
* `tests/spec/validator_guides_spec.lua` — инструменты на модуле с общим содержимым и маршрутами
  (фикстура `tests/fixtures/core/FastesBoooy_TestGuides`: общие сегменты двух стартовых зон, общие
  вставки с областью класса и расы, таблица наград, три маршрута из таблицы): загрузчик
  (`mod.libraryInserts`, алиасы, `opts.replace`, `opts.skip`, файлы ошибок), генератор, командные
  строки валидатора и симулятора; **награды в симуляторе** (выбор из таблицы класса, `reward` шага
  важнее; копия ядра, которая таблицу не читает или читает неверно, — симуляция падает) и
  `simulate_routes.lua --list-routes` (порядок регистрации, `--route`, фильтр файлов, модуль с
  ошибками — код 1 и пустой stdout).
* `tests/spec/validator_module_spec.lua` — шаблоны `*`, каждая проверка шаблонов (в том числе шаг с
  `race = "Undead"` и вставка с опечаткой в якоре при `--skip`: свой файл, чужой, без `--own`),
  фильтр файлов в загрузчике и трёх инструментах, шаблоны, не совпавшие ни с одним файлом, списки
  `--route`, какие ошибки считаются с `--route`, harness на модуле с маршрутами.
* `tests/spec/validator_gates_spec.lua` — `ok` в трёх формах и на сегменте, потолок,
  `ok-needs-ceiling`, `ok-unused`, `--strict` с `--own` и блок чужих предупреждений, `--end-level`,
  `--grind-until`, `--max-grind-until`, `--summary`, `--write-baseline` / `--baseline`, `--levels`,
  худший случай для `fly` и `hearth`, виды тренеров, стабильные поля сообщений.
* `tests/spec/validator_overrides_spec.lua` — слой поправок: каждое поле, сломанный файл под
  `pcall`, медиана остаётся медианой снимка, повтор id, файлы владельца, `override-load`,
  `override-foreign-quest`, три командные строки; **спеки не зависят от `tools/overrides`**: каждая
  командная строка инструмента в `tests/spec` передаёт `--no-overrides` (или `--overrides DIR`) —
  спек падает на строке без опции; новый спек, который запускает `validate_routes.lua`,
  `simulate_routes.lua` или `gen_route_data.lua`, обязан делать так же.
* `tests/spec/validator_report_spec.lua` — сводный отчёт (`lib/report.lua`): слияние текстов по
  числам, колонка «маршруты», все разделы на результатах, собранных вручную (ключ общих сообщений,
  два одинаковых ключа в одном прогоне, принятые отдельно, пороги, собственные сообщения маршрута,
  INFO только числом, принятые `db-override-unverified`), временный модуль формы Guides через
  настоящий валидатор и командную строку (JSON и текст остаются полными), фикстуры.
* `tests/spec/build_spec.lua` — сборка: `make simulate` / `simulate-sync` / `simulate-sync-full` с
  подставным симулятором (`SIM=…`: параллельность, упавший `--list-routes`, пустой список, упавший
  прогон, вывод прогона одним куском при большом объёме), `make route`, `make check-fast`,
  `make report` с подставным валидатором (`LUA=…`, `REPORT=…`: отчёт заменяется только новым,
  цель падает, когда отчёт не записан), значения `SYNC_ROUTES` / `SYNC_MID` / `ROUTE` называют
  существующие маршруты и сегменты, CI запускает каждую стадию `make check`. Свои `make` спека
  запускает с чистым окружением (без `MAKEFLAGS` внешнего `make`), поэтому проходит и под
  `make -jN check`, и с переменными в командной строке (`make check ROUTE=…`); значения
  `VALIDATE_FLAGS` она не закрепляет.
* `tests/spec/core_sync_spec.lua` — синхронизация по уровню и правила «пустых» квестов на
  маршруте в памяти (`register`-хук `tests/fixtures/core/helpers.lua`: маршрут через публичный
  API до входа в игру; четыре сегмента с уровнями, синтетические квесты с предпосылками и их
  `questMeta`): перерос сегмент с запасом, содержание предложения, `ask`/`auto`/`off`,
  применение / отказ (до следующего уровня) / отмена, сохранение через `/reload` и холодный
  старт, серые квесты и защита цепочек, недоступные и не взятые квесты (цепочки, `preAny`,
  Skip на `accept`), `Forward()`, `GetUpcoming()`, `questMeta` в `gen_route_data` и в составном
  маршруте, миграция настроек, производительность (`Refresh` маршрута на 1 713 шагов < 60 мс).
  `tests/spec/core_simulate_spec.lua` — `--ahead` симулятора (синхронизация на
  `FastesBoooy_TestComposed`, пропуск недоступного `accept` движком, отказ симулятора без
  `questMeta`, проверка аргумента), `--ahead-at` (прыжок посреди сегмента с квестом в журнале,
  брошенный квест отменён) и `--level-plus` (опережение без прыжков).
  `tests/spec/core_sync_keep_spec.lua` — синхронизация с журналом: цели «Попутно» ниже порога
  (выполнение квеста, который сдаётся после порога, его предметы по `questMeta` `items`, сдача
  готового квеста, последний тренер с `/reload`, точка полёта и привязка камня, подсказки шагов
  `fly`/`hearth`), брошенные квесты и строка в чат, когда прыжок не предлагается (только квесты
  журнала, тренер и сдачи), режим `auto` в конце сегмента, «пустые» `collect` не взятых квестов,
  `UndoSync` чужого маршрута, окно шагов прячет строки `floor`.

```
busted tests/spec/validator_*_spec.lua
lua5.1 tools/validate_routes.lua tests/fixtures/validator/FastesBoooy_FxClean
```

## 7. Harness: часть библиотеки из стартового состояния

Общие сегменты (модуль-библиотека или общая часть `addons/FastesBoooy_Guides`) проверяются и по
отдельности, без полного маршрута класса. Чтобы проверить **один сегмент** (или несколько
подряд), валидатор и симулятор умеют стартовать из явного состояния персонажа. То же работает
на модуле, который регистрирует и общее содержимое, и маршруты (`FastesBoooy_Guides`): берётся его
общая часть, синтетический маршрут `harness-<Имя>` выбирается явно, общие вставки модуля
применяются к нему автоматически, а шаги других рас и классов (общих сегментов и вставок) в него
не собираются. Чтобы проверить зону без шагов классов — `--skip 'Classes/*'`.

```
lua5.1 tools/validate_routes.lua --harness <каталог библиотеки> [--segments h-a,h-b,...] \
       --profile race=<raceFile>,class=<CLASS>[,faction=Horde|Alliance] \
       [--state start.json] [--write-state end.json] [--strict] [-v]
lua5.1 tools/simulate_routes.lua --harness <каталог библиотеки> [--segments ...] --profile ... \
       [--state start.json] [--write-state end.json] [--no-reload] [-v]
make harness PROFILE=race=Scourge,class=PALADIN,faction=Horde SEGMENTS=h-22-hillsbrad \
       STATE=state_ud_22.json OUT=end.json            # оба инструмента подряд
```

**Синтетический маршрут** (`lib/harness.lua`, `Harness.Build`): модуль-библиотека грузится как
обычно (со своими зависимостями), затем регистрируется маршрут `harness-<Имя>` (`harness-Guides`)
ровно для одного профиля — `RegisterRoute{ api = 1, faction, races = { race }, classes = { class } }`
+ `UseSegments` перечисленных сегментов в этом порядке, **больше ничего** (нет своих сегментов,
нет классовых вставок). Сборка — настоящим `Core/Compose.lua`; в симуляторе маршрут
регистрируется через публичный API аддона в моке сразу после загрузки библиотеки, как модуль
маршрута с `## Dependencies` на неё. Профиль: раса и класс обязательны; фракция берётся из расы,
у `Skyborne` (обе стороны) — обязательна. Шаги с фильтром другого класса/расы пропускаются
(INFO `step-skipped`); `step-no-profile` в harness не сообщается (профиль один намеренно).
Без `--segments` — все сегменты модуля в порядке TOC. Неизвестный сегмент — ERROR `schema` со
списком сегментов библиотеки (у заготовки — «registers no library segments yet: its segment files
are placeholders»). Библиотека без единого сегмента и без `--segments` — сообщение «registers no
library segments yet … nothing to validate / simulate», код 0. `--harness` на модуле маршрута без
общих сегментов или на каталоге без TOC — код 2. `--skip` / `--keep` действуют и здесь; в
harness-прогонах работают `--end-level`, `--max-grind-until`, `--summary` и `--levels`.

**Файл состояния** (JSON; его же пишет `--write-state`, так что прогоны сцепляются):

```json
{
  "level": 34,                      // уровень 1..60
  "xpFrac": 0.2,                    // доля текущего уровня, 0 <= xpFrac < 1
  "done": [1064, 1065],             // сданные раньше квесты (предквесты, «уже сдан»)
  "log": [532, 1067],               // квесты в журнале; элемент может быть {"id": 532, "complete": true}
  "complete": [1067],               // квесты из "log", цели которых уже выполнены
  "hearth": "Thunder Bluff",        // точка привязки камня (enUS, как в sethearth/hearth)
  "hearthAt": [1456, 45.81, 64.71], // где она (трактирщик; симулятор телепортирует туда)
  "at": [1456, 25.81, 19.03],       // позиция персонажа {uiMapID, x, y}
  "flightPaths": ["Thunder Bluff"], // изученные точки полёта (enUS, как в fp/fly)
  "meta": { ... }                   // свободное поле: откуда состояние (маршрут, профиль, сегменты, уровень)
}
```

(Комментарии `//` здесь только для пояснения — в файле их быть не должно: декодер строгий.)
Все ключи необязательны (по умолчанию — новый персонаж 1 уровня); неизвестный ключ, квест
одновременно в `done` и `log`, `complete` вне `log`, повторы, уровень/доля вне диапазона —
ошибки чтения (все списком, код 2).

**Что значит состояние для валидатора:** симуляция опыта (обычная и оптимистичная) начинается с
`level` + `xpFrac`; `done` — сданы (предквесты выполнены, повторное взятие — `accept-done` «at the
start state»); `log` — в журнале (сдача без взятия не нужна, ёмкость журнала считает их —
`questlog-full`), `complete` — цели выполнены (сдача без шага `complete` без
`turnin-no-complete`); `hearth` — к нему проверяется `hearth` (`hearth-mismatch`); `flightPaths` —
для `fly-unknown-fp`. Квесты состояния, которых нет в БД, — ERROR `quest-unknown` на
псевдошаге `start-state`. Квесты, оставшиеся в журнале в конце harness-прогона, — INFO
`quest-carried` (они уходят в `log` конечного состояния). Для симулятора: мок получает уровень и
опыт, `done` как выполненные квесты, `log` в журнале (`complete` — с выполненными целями и
предметами в сумках), привязку камня (`hearth` + `hearthAt`), позицию `at`; `flightPaths`
переносятся в конечное состояние.

**Конечное состояние** (`--write-state`): уровень и доля по симуляции, `done` = `done` старта +
сданное в прогоне, `log` = журнал в конце, `complete` = квесты журнала, все цели которых
выполнены шагами `complete` (у валидатора) / по журналу мока (у симулятора; там и квесты без
целей), `hearth`/`hearthAt` — последний `sethearth` (или из старта), `at` — `at` последнего
пройденного шага, `flightPaths` — старт + шаги `fp`, `meta` — источник, маршрут, профиль,
сегменты, `levelValue`/`levelOptimistic`, файл старта. Запись детерминирована (порядок ключей,
сортированные списки), `xpFrac` — 6 знаков: опыт при чтении восстанавливается точно, поэтому
цепочка «сегмент A → файл → сегмент B» даёт то же конечное состояние, что прогон A,B сразу
(проверяется в `validator_harness_spec.lua`).

**Состояние полного маршрута:** маршруты идут до 60, поэтому старт первого сегмента
библиотеки (конец собственной части 1-22 маршрута) снимается с `--until`:

```
lua5.1 tools/validate_routes.lua -q --route undead-paladin --write-state state_ud_22.json --until h-22-hillsbrad
lua5.1 tools/validate_routes.lua -q --route skyborne-druid --write-state state_sd_22.json --until h-22-hillsbrad
```

(сейчас: нежить-паладин — уровень 22 + 0,04, 179 выполненных квестов, камень в Thunder Bluff;
скайборн-друид — 22 + 0,44, 190 выполненных, камень в Thunder Bluff. У маршрута с одной расой и
одним классом `--profile` не нужен.) Тем же способом снимается старт любого сегмента
библиотеки (`--until h-34-stranglethorn` …) или любого шага. Без `--until` пишется состояние в
конце маршрута (уровень 60). `--write-state` требует ровно один прогон «маршрут × профиль»
(иначе код 2: выберите `--route` и `--profile`). Симулятор тоже пишет состояние
(`simulate_routes.lua --route ID --write-state f.json`, один прогон, конец маршрута).

**Оговорки.** (1) Валидатор считает выполненными **все** шаги, в том числе `optional = true`:
состояние конца 1-22 включает то, что дают необязательные шаги; для строгой проверки уберите
такие записи из копии файла.
Худший случай отчёта о гринде (раздел 5, п. 5) пропускает `optional`-шаги **внутри** прогона, но
стартовое состояние и `--write-state` остаются состояниями основного прогона. `optional-dependency`
сообщает о квестах и о `fly X` / `hearth X`, которым нужен необязательный `fp X` / `sethearth X`
**внутри** прогона; точку полёта из стартового состояния, полученную необязательным шагом раньше,
худший случай не видит.
(2) Опыт за убийства есть только у валидатора (оценка); мок симулятора даёт только опыт
квестов и шаги `level`, поэтому уровень в конечном состоянии симулятора ниже. Сцепляйте
сегменты по состояниям **валидатора**; состояние симулятора — для проверки игрового состояния
(журнал, сданные квесты, камень, позиция). (3) Валидатор не моделирует позицию — `at` старта
лишь переносится в конец, если в прогоне не было шагов с `at`.

## 8. «Игрок обогнал маршрут»: `simulate_routes.lua --ahead L`, `--ahead-at`, `--level-plus`

```
lua5.1 tools/simulate_routes.lua --ahead 23 [--route ID] [модуль ...]
lua5.1 tools/simulate_routes.lua --ahead 21 --ahead-at h-15-barrens
lua5.1 tools/simulate_routes.lua --level-plus 2
make simulate-sync                      # SYNC_ROUTES x (SYNC_LEVELS + SYNC_MID + SYNC_PLUS), параллельно
make simulate-sync-full                 # то же для всех маршрутов (--list-routes)
```

Свежий персонаж уровня `L` (опыт 0, ничего не сдано) стоит в начале маршрута с настройками по
умолчанию (`levelSync = "ask"`, `skipGray`). Если движок предлагает синхронизацию
(`Engine:GetSyncSuggestion()`) — в начале или позже, когда игрок снова перерос сегмент, —
симулятор «нажимает» кнопку баннера (`Engine:ApplySync()`) и проверяет, что курсор встал на
предложенный шаг; дальше маршрут проходится до конца как обычно. Во время прохождения симулятор
**отказывается** брать квест, чьи предпосылки-квесты маршрута (`preQuestGroup` БД — все,
`preQuestSingle` — любой; предпосылки, которых маршрут не берёт, считаются выполненными) не сданы:
`FAIL … unreachable accept: step … accepts Q but its route prerequisite(s) … are not turned in` —
движок должен был пропустить такой `accept` (правило недоступных квестов). Холодный старт в
конце снова принимает предложения синхронизации (порог был в потерянных SavedVariables);
пройденный маршрут и тогда должен остаться пройденным (`cold start: finished`) — курсор не
вернётся к `accept` серой цепочки, которую прыжок пропустил (правило «защищённых» серых квестов
не держит цепочку, ведущую к необязательному квесту, мимо которого игрок прошёл: ARCHITECTURE.md,
«Синхронизация по уровню»). Строка `OK` дополняется `ahead: level L`, вторая строка —
синхронизации (`level 23: ud-01-deathknell -> h-18-stonetalon-ashenvale; …`) и число «пустых» действий в конце (серые /
недоступные `accept`, не взятые `complete`/`turnin`/`collect`).

`--ahead L --ahead-at SEG[,SEG…]`: персонаж уровня маршрута проходит маршрут **как обычно** до
середины первого из перечисленных сегментов, который есть в маршруте (квесты этой части в
журнале), затем получает уровень `L` и принимает предложения дальше — прыжок с журналом
(`sync: at step N (SEG) with K quest(s) in the log: …`). `--level-plus N`: весь маршрут игрок на
`N` уровней выше плана (линейно внутри `levels` каждого сегмента), `levelSync = "auto"` — движок
прыгает сам, только если прыжок что-то экономит.

Во всех этих прогонах («sync») симулятор дополнительно:

* **отказывается** брать недоступный `accept` (см. выше) и собирать `collect`, чьи предметы
  (`questMeta` `items`) нужны только квестам, которых нет в журнале, которые не сданы и которые
  маршрут уже не берёт (`accept` только до натурального курсора) — движок должен был сделать его
  «пустым»;
* после каждого прыжка **отменяет** квесты, которые движок назвал брошенными
  (`Engine:GetDroppedQuests()` — то, что строка в чате просит сделать игрока);
* после прыжка шаг `fly` к точке, чей шаг `fp` прыжок пропустил (и прогон его не выполнил),
  должен показывать подсказку движка (`Engine:FlightPathPending`) — тогда игрок добирается туда
  сам; шаг `hearth`, когда камень привязан к другому месту (имя привязки не совпадает с местом
  шага), — подсказку о привязке (`Steps:Describe`, строка `hint`); без подсказки — `FAIL`;
  такие шаги считаются (`N fly/hearth step(s) travelled`);
* **проваливает** прогон, если в конце маршрута в журнале остался **выполненный** квест
  (потерянная сдача); невыполненные остатки считаются (`incomplete left in the log`).

Во всех прогонах цели «Попутно» берутся из списка движка на начало итерации, но шаг, которого в списке
уже нет (его сделал ненужным предыдущий шаг той же итерации: например, визит к тренеру, оставленный
прыжком, когда курсор дошёл до следующего визита маршрута к тренеру), не выполняется (`-v`: `no longer
a background goal`; фаза R — до этого `simulate-sync-full` падал на `orc-rogue` / `troll-rogue
--ahead 35`, шаг `rog-train-22`).

Без этих опций ничего из этого не происходит: обычные прогоны не изменились.

**Почему для CI достаточно подмножества маршрутов.** Sync-прогоны проверяют логику синхронизации
движка на границах сегментов, журнале и `questMeta`. С точки слияния все маршруты модуля гайдов
идут по одним и тем же сегментам и различаются стартовой зоной и вставками класса; `SYNC_ROUTES` —
по маршруту на расу с разными классами. Остальные маршруты проходят те же прогоны ночью
(`make simulate-sync-full`, раздел 10). `--ahead-at` берёт список и использует первый сегмент,
который есть в маршруте, поэтому один элемент `SYNC_MID` может назвать общий сегмент.

Итоги `--ahead L` двух маршрутов, с которых начинался `SYNC_ROUTES` (фаза F1; сейчас в нём пять маршрутов, 40
прогонов, ≈ 3 мин на 4 ядрах; время всех 28 маршрутов — раздел 10):

| L | Нежить-паладин | Скайборн-друид |
|---|---|---|
| 10 | 1-6 → 6-13 | на 11-м: 1-9 → 9-13 |
| 23 | 1-6 → 18-22, затем на 24-м → h-22 | 1-9 → 18-22 |
| 35 | 1-6 → h-31 | 1-9 → h-31 |
| 48 | 1-6 → h-46 | 1-9 → h-46 |

`SYNC_MID`: на 21-м посреди 15-18 Barrens (паладин: шаг 255, 10 квестов в журнале; друид: шаг 286,
12 квестов) → 18-22, брошенные 4 / 3 квеста отменены, выполнение квестов, которые сдаются в 18-22,
и сдачи готовых — «Попутно»; на 29-м посреди h-24 → h-27. `SYNC_PLUS`: +2 — ни одного прыжка, все
квесты сданы (712/712 → 710/710 у паладина: 2 серых квеста перерощенного сегмента); +4 — прыжок на
каждом сегменте, пропущенные тренер / точки полёта / привязка — «Попутно», брошенные 34 / 31 квеста
(паладин / друид) отменены, журнал в конце пуст; единственное предупреждение — 4496 в h-53 (его
`preAny` 4493 — альянсовый вариант, не квест маршрута; по правилу недоступных квестов такие
предпосылки считаются выполненными, docs/ARCHITECTURE.md).

## 9. Симулятор: список маршрутов, выбор, фильтр файлов, награды

```
lua5.1 tools/simulate_routes.lua --list-routes [--fixtures] [--route ...] [--skip GLOB] [--keep GLOB] [модуль ...]
lua5.1 tools/simulate_routes.lua --route 'orc-*,troll-mage' [--route ...]
lua5.1 tools/simulate_routes.lua --skip 'Classes/*' --keep Classes/Warrior.lua --route '*-warrior'
```

* **`--list-routes`** ничего не симулирует: печатает id маршрутов, по одному в строке, в порядке
  модулей (каталог `addons` по алфавиту или порядок аргументов) и порядке регистрации маршрутов;
  код 0. Модуль-библиотека маршрутов не имеет и ничего не печатает. Если хотя бы один модуль не
  загрузился чисто (ошибки загрузки или схемы, нет TOC), **не печатается ни один id**, ошибки
  идут в stderr, код 1: `make simulate` строит по этому выводу список работ, и сломанный модуль
  должен остановить цель, а не укоротить список. Учитывает `--fixtures`, `--route` (элемент, не
  совпавший ни с одним маршрутом, — код 1) и `--skip` / `--keep`; с опциями симуляции
  (`--ahead`, `--level-plus`, `--profile`, `--state`, `--harness`) — код 2.
* **`--route ID[,ID...]`** — список с `*`, можно повторять; каждый элемент должен совпасть с
  маршрутом (иначе код 1). Модуль с ошибками загрузки роняет запуск и с `--route`.
* **`--skip` / `--keep`** оставляют файлы TOC модуля за бортом и в офлайн-загрузке, и в моке
  клиента (`Mock.loadAddon` получает тот же набор). Шаблон, не совпавший ни с одним файлом TOC, —
  код 2. `--no-overrides` / `--overrides DIR` — как у валидатора; сломанный файл поправок —
  строка `ERROR override-load` и код 1 (с `--skip` — заметка).
* **Награды.** Для каждого `turnin` симулятор определяет ожидаемый выбор по офлайн-маршруту так
  же, как движок (`Engine:GetRewardChoice`): `reward` шага среди шагов профиля (шаг, который сдаёт
  квест, иначе первый шаг, назвавший квест), иначе таблица наград класса
  `route.data.rewards[<класс>][<квест>]` (`AddLibraryData{ rewards = … }`). Квест мока получает
  столько вариантов награды, и после сдачи проверяется индекс, с которым автоматика вызвала
  `GetQuestReward`: `FAIL … quest Q turned in with reward choice X, the route wants Y (class table
  MAGE)`; если движок выбора не нашёл, окно награды остаётся открытым — `the automation did not
  turn in quest Q`. С `-v` печатается `reward choice N of quest Q (class table CLASS | step ID)`,
  в строке `OK` — `N reward choice(s) checked`.
* Harness (`--harness DIR`, раздел 7) принимает и модуль с маршрутами.

## 10. CI

`.github/workflows/ci.yml` — одна задача с пределом 25 минут. Стадии `make check` запускаются по
одной, чтобы в журнале было видно время каждой (`tests/spec/build_spec.lua` следит, что ни одна
не пропущена):

| Шаг | Что запускает |
|---|---|
| установка | `lua5.1`, `luarocks`, `luacheck` 1.1.2, `busted` 2.2.0 |
| lint | `make lint` |
| валидатор | `make validate validate-fixtures harness-fixtures` |
| спеки | `make test` |
| симуляция | `make simulate simulate-fixtures` (каждый маршрут, параллельно) |
| sync-прогоны | `make simulate-sync` (`SYNC_ROUTES`, параллельно) |
| свежесть данных | `make routedata-check` |
| свежесть отчёта | `make report` и `git diff --exit-code -- docs/VALIDATION.md` |
| упаковка | `make package`, артефакт `dist/*.zip` + `docs/VALIDATION.md` |

Ожидаемое время на 4 vCPU с 28 маршрутами: установка 1,5 мин, lint и валидатор 0,3 мин, busted
1,7 мин, симуляция 3,0 мин (28 × 26 с процессорного времени), sync-прогоны 3,2 мин (5 маршрутов × 8
прогонов), остальное 0,1 мин — около 10 минут. Если раннер медленнее: сначала запускать файлы
спеков busted параллельно, затем убрать `--ahead 10` и `--level-plus 2` у всех маршрутов
`SYNC_ROUTES`, кроме одного (самые долгие прогоны).

`.github/workflows/nightly.yml` — по расписанию и вручную (`workflow_dispatch`):
`make simulate-sync-full`, sync-прогоны **каждого** маршрута (28 × 8 прогонов ≈ 18 минут на
4 vCPU).

`Data.lua` и `docs/VALIDATION.md` — сгенерированные файлы, и CI проверяет оба. При параллельной
работе нескольких авторов над одним модулем их перегенерирует один владелец в конце этапа
(`make routedata report`), поэтому посреди такого этапа дерево может не проходить шаги свежести.

## Ограничения

* Опыт ~720 новых квестов Forever неизвестен офлайн — уровни в симуляции приблизительны,
  пока не собраны реальные значения (`/fb xp` в аддоне → обновить данные).
* Опыт за мобов — формула Classic + приблизительный штраф Forever; вероятности выпадения
  предметов в снимке нет.
* Расстояние считается в ярдах по размерам карт из `conversion.json`; у карт без известных
  границ (Zephras Isle 2521, данжевые карты) — в процентах карты (приблизительно).
* uiMap 2665 (вторая карта Zephras Isle) не разрешён в данных QuestieDB.
* Симулятор: встроенные карты мока (`tests/mocks/wow/world.lua`, `BUILTIN_MAPS`) — зоны 1-22. Остальные
  зоны снимка с известным размером (`zones[uiMap].size`) симулятор определяет в моке сам (`opts.maps`):
  размер в ярдах настоящий, у каждой зоны своя система координат (continent = uiMapID). Поэтому внутри
  такой зоны радиусы прибытия и проверка «камень возвращения приземлил на `at` шага» настоящие, а
  расстояние между двумя такими зонами по-прежнему неизвестно; с `--no-db` этих карт нет.
