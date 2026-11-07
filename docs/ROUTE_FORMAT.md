# Формат маршрутов (API v1)

Маршрут — это обычный аддон-модуль, который зависит от ядра `FastesBoooy` и
регистрирует данные через глобальную таблицу `FastesBoooy`. Контракт формата
реализован в [`addons/FastesBoooy/Core/Schema.lua`](../addons/FastesBoooy/Core/Schema.lua)
(чистый Lua 5.1, общий для аддона и офлайн-валидатора).

## Структура модуля

```
addons/FastesBoooy_<Name>/
  FastesBoooy_<Name>.toc   -- ## Interface: 16001, ## Dependencies: FastesBoooy
  Route.lua                -- FastesBoooy.RegisterRoute{...}
  Data.lua                 -- (генерируется) FastesBoooy.AddRouteData(id, {quests=..., npcs=...})
  Segments/01_*.lua        -- FastesBoooy.AddSegment(id, {...}) — по файлу на сегмент
```

Файлы грузятся в порядке TOC. `RegisterRoute` должен идти первым.

## Маршрут

```lua
FastesBoooy.RegisterRoute({
    api = 1,                                  -- версия формата (обязательно)
    id = "horde-undead-paladin",              -- [A-Za-z0-9-_]
    title = { ru = "Нежить-паладин 1-22", en = "Undead Paladin 1-22" },
    faction = "Horde",                        -- "Horde" | "Alliance"
    races = { "Scourge" },                    -- raceFile из UnitRace()
    classes = { "PALADIN" },                  -- classFile из UnitClass()
    levels = { 1, 22 },
    version = "1.0.0",
    default = true,                           -- автоматически выбирать для подходящих персонажей
})
```

## Сегмент

```lua
FastesBoooy.AddSegment("horde-undead-paladin", {
    id = "ud-01-deathknell",
    title = { ru = "1-6 Мертвый Звон", en = "1-6 Deathknell" },
    zone = "Tirisfal Glades",
    levels = { 1, 6 },
    steps = { ... },
})
```

## Шаг

Шаг описывает **одно место / одно действие игрока**. В одном шаге можно
совмещать несколько действий (например, сдать и сразу взять квесты у одного NPC) —
шаг завершён, когда выполнены **все** его действия.

### Действия

| Ключ | Значение | Когда шаг считается выполненным |
|---|---|---|
| `accept` | `id` или `{id, id}` | квест(ы) в журнале или уже сданы |
| `turnin` | `id` или `{id, id}` | квест(ы) сданы (`C_QuestLog.IsQuestFlaggedCompleted`) |
| `complete` | `id`, `{id, id}` или `{ [id] = {1, 2} }` | цели квеста (или указанные цели) выполнены, либо квест сдан |
| `abandon` | `id` или `{id}` | квеста нет в журнале |
| `collect` | `{ [itemId] = count }` | в сумках ≥ count |
| `level` | `n` или `{n, доля}` | уровень > n, или = n и доля опыта ≥ доли |
| `go` | `true` | игрок в радиусе `radius` (по умолч. 12 ярдов) от `at` |
| `train` | `true` | окно тренера было открыто и закрыто на этом шаге |
| `fp` | `"Brill"` | открыта карта полётов на этом шаге (точка изучена) |
| `fly` | `"Undercity"` | игрок прилетел (не на такси и в радиусе 60 ярдов от `at`) |
| `sethearth` | `"Brill"` | точка привязки камня изменилась на этом шаге |
| `hearth` | `"Brill"` | игрок в радиусе 80 ярдов от `at` после телепорта |
| `vendor` | `true` | окно торговца было открыто и закрыто |
| `manual` | `true` | только вручную (кнопка «дальше») |

`accept/turnin/complete/abandon/collect/level` — **stateful**: их состояние читается
из игры в любой момент. Остальные — **transient**: наблюдаемы только пока шаг
текущий. Если игрок уже ушёл дальше (выполнен любой более поздний stateful-шаг),
пропущенные transient-шаги считаются выполненными — это позволяет подхватить
маршрут на уже прокачанном персонаже.

### Поля

| Поле | Тип | Назначение |
|---|---|---|
| `id` | string | стабильный id шага (иначе `<segment>:<n>`) |
| `at` | `{uiMapID, x, y}` | точка на карте Forever (x, y в процентах 0–100) |
| `radius` | number | радиус прибытия в ярдах |
| `npc` | id / список | NPC (валидатор проверяет, что он выдаёт/принимает квест и стоит рядом с `at`) |
| `object` | id / список | игровой объект (аналогично) |
| `note` | string или `{ru=, en=}` | подсказка |
| `reward` | `{ [questId] = индекс }` | какую награду выбирать автоматически |
| `gossip` | number | номер опции диалога для автовыбора |
| `use` | itemId | предмет для кнопки использования |
| `bg` | boolean | фоновая цель: не блокирует, висит в списке «попутно», пока не выполнена |
| `optional` | boolean | можно пропустить: считается выполненным, когда выполнен более поздний stateful-шаг |
| `class` / `race` / `faction` | токен или список | фильтр: шаг показывается только подходящим персонажам |
| `spells` | список строк | что выучить у тренера (только отображение) |

### Пример

```lua
steps = {
    { accept = 363, npc = 1568, at = { 1420, 30.2, 71.7 } },
    { turnin = 363, accept = 364, npc = 1569, at = { 1420, 30.8, 66.2 } },
    { complete = 364, bg = true, note = { ru = "Бейте зомби по пути", en = "Kill zombies on the way" } },
    { level = { 4, 0.3 } },
    { train = true, class = "PALADIN", npc = 12345, at = { 1420, 31.1, 66.0 } },
    { go = true, at = { 1420, 59.4, 52.1 }, note = { ru = "Бегите в Брилл", en = "Run to Brill" } },
}
```

## Валидация

`make validate` (см. `tools/validate_routes.lua`) проверяет каждый маршрут по
снимку базы Forever (`tools/data/forever_db.lua`): существование квестов,
доступность для расы/класса/фракции, требования по уровню (симуляция опыта),
цепочки (pre-quests, exclusive), принадлежность NPC и расстояние от `at` до
спавна, ёмкость журнала, тренеров/полётчиков/трактирщиков. Подробнее —
[VALIDATION.md](VALIDATION.md).
