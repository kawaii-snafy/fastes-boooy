-- tools/data/forever_api_confirmed.lua -- maintained by hand (tools/data/forever_api.lua is generated).
--
-- Client globals that the generated API dump does not list but that were confirmed in the
-- World of Warcraft: Forever client itself. Read together with forever_api.lua by the strict
-- mock (tests/mocks/wow/allowlist.lua) and luacheck (.luacheckrc). Add a name only after
-- checking it in game, with the date and how.
--
-- Layout: globals = { "Name", ... } (plain global names, same meaning as forever_api.lua globals).

return {
    globals = {
        -- frame names closed by Escape (CloseSpecialWindows); /dump UISpecialFrames in game, 2026-11-14
        "UISpecialFrames",
    },
}
