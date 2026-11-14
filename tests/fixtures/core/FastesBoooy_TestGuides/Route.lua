-- FastesBoooy_TestGuides / Route.lua
-- Core test fixture: the routes of the module, registered from one table (numeric `for`, no
-- globals), the last file of the TOC. A race gets its routes only when its start zone has
-- announced itself (ns.startZones, set by the zone's last segment file).
if not FastesBoooy.AddLibraryInsert then return end
local _, ns = ...

local CLASSES = {
    MAGE = { slug = "mage", ru = "маг", en = "Mage" },
    PALADIN = { slug = "paladin", ru = "паладин", en = "Paladin" },
    WARRIOR = { slug = "warrior", ru = "воин", en = "Warrior" },
    DRUID = { slug = "druid", ru = "друид", en = "Druid" },
}
local RACES = {
    { race = "Scourge", slug = "undead", ru = "Нежить", en = "Undead", zone = "Tirisfal",
      classes = { "PALADIN", "WARRIOR" }, aliases = { PALADIN = "tg-old-undead-paladin" } },
    { race = "Orc", slug = "orc", ru = "Орк", en = "Orc", zone = "Durotar", classes = { "WARRIOR" } },
    { race = "Troll", slug = "troll", ru = "Тролль", en = "Troll", zone = "Durotar", classes = { "MAGE" } },
    -- the zone file is a placeholder: no announcement, no route
    { race = "Tauren", slug = "tauren", ru = "Таурен", en = "Tauren", zone = "Mulgore", classes = { "DRUID" } },
}

for i = 1, #RACES do
    local r = RACES[i]
    local start = ns.startZones and ns.startZones[r.zone]
    if start then
        local segments = {}
        for j = 1, #start do segments[j] = start[j] end
        local only
        if start.only then
            only = {}
            for j = 1, #start.only do only[start.only[j]] = true end
        end
        for j = 1, #r.classes do
            local class = r.classes[j]
            if not only or only[class] then
                local c = CLASSES[class]
                local id = "tg-" .. r.slug .. "-" .. c.slug
                FastesBoooy.RegisterRoute({
                    api = 1,
                    id = id,
                    title = { ru = r.ru .. "-" .. c.ru .. " 1-3 (тест)", en = r.en .. " " .. c.en .. " 1-3 (test)" },
                    description = { ru = "Тестовый маршрут: стартовая зона расы.", en = "Test route: the start zone of the race." },
                    faction = "Horde",
                    races = { r.race },
                    classes = { class },
                    levels = { 1, 3 },
                    version = "0.0.1",
                    author = "FastesBoooy tests",
                    default = true,
                    aliases = r.aliases and r.aliases[class] or nil,
                })
                FastesBoooy.UseSegments(id, segments)
            end
        end
    end
end
