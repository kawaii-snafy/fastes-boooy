-- Hand-written route data (localized place names + a quest title fallback).
AdventureAtlas.AddRouteData("test-route", {
    places = {
        ["Brill"] = { ru = "Брилл", en = "Brill" },
        ["Undercity"] = { ru = "Подгород", en = "Undercity" },
        ["The Sepulcher"] = { ru = "Гробница", en = "The Sepulcher" },
    },
    quests = {
        [363] = { ru = "Грубое пробуждение", en = "Rude Awakening" },
    },
    items = {
        [3264] = { ru = "Крыло сумеречной мыши", en = "Duskbat Wing" },
    },
})
