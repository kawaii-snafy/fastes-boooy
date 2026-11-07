-- FastesBoooy / Locales / ruRU.lua -- core strings (UI strings: Locales/UI_ruRU.lua)
local _, ns = ...
ns.Locales = ns.Locales or {}
ns.Locales.ruRU = ns.Locales.ruRU or {}
local L = ns.Locales.ruRU

-- строки шагов (Core/Steps.lua: Steps:Describe)
L.STEP_ACCEPT = "Взять: %s"
L.STEP_TURNIN = "Сдать: %s"
L.STEP_COMPLETE = "Выполнить: %s"
L.STEP_COMPLETE_OBJECTIVES = "Выполнить: %s (цели %s)"
L.STEP_ABANDON = "Отменить: %s"
L.STEP_COLLECT = "Собрать %s: %d/%d"
L.STEP_LEVEL = "Достичь %d уровня"
L.STEP_LEVEL_FRAC = "Достичь %d уровня и %d%% полосы опыта"
L.STEP_GO = "Идти: %s %.1f, %.1f"
L.STEP_GO_NOZONE = "Идти: %.1f, %.1f"
L.STEP_TRAIN = "Посетить классового наставника"
L.STEP_FP = "Открыть точку полётов: %s"
L.STEP_FLY = "Лететь: %s"
L.STEP_SETHEARTH = "Привязать камень возвращения: %s"
L.STEP_HEARTH = "Камень возвращения: %s"
L.STEP_VENDOR = "Посетить торговца (продать / докупить)"
L.STEP_MANUAL = "Нажмите «Дальше», когда закончите"
L.STEP_SPELLS = "Выучить: %s"
L.STEP_OBJECTIVE = "%s"
L.STEP_OBJECTIVE_PENDING = "Цель %d"
L.QUEST_FALLBACK = "Задание №%d"
L.ITEM_FALLBACK = "Предмет №%d"
L.UNKNOWN_PLACE = "?"

-- сообщения в чат
L.MSG_LOADED = "v%s загружен."
L.MSG_ROUTE_ERRORS = "Ошибок формата маршрутов: %d. Первая: %s"
L.MSG_NO_ROUTE = "Нет маршрута для этого персонажа."
L.MSG_ROUTE_SELECTED = "Маршрут: %s"
L.MSG_ROUTE_FINISHED = "Маршрут пройден. Отлично!"
L.MSG_UNKNOWN_ROUTE = "Неизвестный маршрут: %s"
L.MSG_CHOOSE_REWARD = "Выберите награду за «%s» сами."
L.MSG_QUEST_LOG_FULL = "Журнал заданий заполнен (%d/%d): «%s» не взято."
L.MSG_PVP_QUEST = "«%s» включает режим PvP: возьмите задание вручную."
L.MSG_QUEST_COSTS_MONEY = "«%s» требует денег: сдайте задание вручную."
L.MSG_XP_RECORDED = "Задание %d: записано %d опыта."
L.MSG_RESET = "Прогресс маршрута сброшен (состояние игры сохраняется)."
