local DFS_Name = "Devnull - Fair Start"
local DFS_Version = "1.2"
if Server or Client then
    HPrint(DFS_Name .. ", version " .. DFS_Version)
end

ModLoader.SetupFileHook("lua/NS2Gamerules.lua", "lua/Devnull_FS/NS2Gamerules.lua", "post")
ModLoader.SetupFileHook("lua/TeamMessenger.lua", "lua/Devnull_FS/TeamMessenger.lua", "replace")
ModLoader.SetupFileHook("lua/NetworkMessages.lua", "lua/Devnull_FS/NetworkMessages.lua", "post")
--ModLoader.SetupFileHook("lua/PlayingTeam.lua", "lua/Devnull_FS/PlayingTeam.lua", "post")
ModLoader.SetupFileHook("lua/GUIMinimap.lua", "lua/Devnull_FS/GUIMinimap.lua", "post")
--ModLoader.SetupFileHook("lua/GUIUtility.lua", "lua/Devnull_FS/GUIUtility.lua", "post")
