local kVersion = "2.0"
local kName = "Devnull - Enhanced Scoreboard"

if Client then
    HPrint(kName .. ", version " .. kVersion)
end

--Hooks
ModLoader.SetupFileHook("lua/GUIScoreboard.lua", "lua/Devnull_ESB/GUIScoreboard.lua", "replace")
ModLoader.SetupFileHook("lua/PlayerInfoEntity.lua", "lua/Devnull_ESB/PlayerInfoEntity.lua", "post")
ModLoader.SetupFileHook("lua/Scoreboard.lua", "lua/Devnull_ESB/Scoreboard.lua", "replace")
