local kVersion = "1.3"
local kName = "Devnull - Enhanced Hud"

Script.Load("lua/AdvancedHud/BiomassNotificationLocation.lua")

if Client then
    HPrint(kName .. ", version " .. kVersion)
end

ModLoader.SetupFileHook( "lua/Hud2/topBar/GUIHudDeadCount.lua", "lua/AdvancedHud/GUIHudDeadCount.lua", "post")
ModLoader.SetupFileHook( "lua/Hud2/topBar/GUIHudSupply.lua", "lua/AdvancedHud/GUIHudSupply.lua", "post")
ModLoader.SetupFileHook( "lua/Hud2/topBar/GUIHudTres.lua", "lua/AdvancedHud/GUIHudTres.lua", "post")

ModLoader.SetupFileHook( "lua/Hud2/topBar/GUIHudEggCount.lua", "lua/AdvancedHud/GUIHudEggCount.lua", "post")
ModLoader.SetupFileHook( "lua/Hud2/topBar/GUIHudIPCount.lua", "lua/AdvancedHud/GUIHudIPCount.lua", "post")
ModLoader.SetupFileHook( "lua/Hud2/topBar/GUIHudRTCount.lua", "lua/AdvancedHud/GUIHudRTCount.lua", "post")
--ModLoader.SetupFileHook( "lua/GUIMinimap.lua", "lua/AdvancedHud/GUIMinimap.lua", "post")


ModLoader.SetupFileHook( "lua/GUICommanderButtons.lua", "lua/AdvancedHud/GUICommanderButtons.lua", "post")
ModLoader.SetupFileHook( "lua/Commander_SelectionPanel.lua", "lua/AdvancedHud/Commander_SelectionPanel.lua", "post")
ModLoader.SetupFileHook( "lua/Commander_Selection.lua", "lua/AdvancedHud/Commander_Selection.lua", "post")
ModLoader.SetupFileHook( "lua/GUIAlienHUD.lua", "lua/AdvancedHud/GUIAlienHUD.lua", "post")
ModLoader.SetupFileHook( "lua/Gorge.lua", "lua/AdvancedHud/Gorge.lua", "post")

-- has to use "cheats" since clients are unable to select units out of their view
ModLoader.SetupFileHook( "lua/NS2ConsoleCommands_Server.lua", "lua/AdvancedHud/NS2ConsoleCommands_Server.lua", "post")
ModLoader.SetupFileHook( "lua/ResearchMixin.lua", "lua/AdvancedHud/ResearchMixin.lua", "post")

-- noted "For WeaponDisplay" behind changes
ModLoader.SetupFileHook( "lua/GUIUnitStatus.lua", "lua/AdvancedHud/GUIUnitStatus.lua", "replace")
ModLoader.SetupFileHook( "lua/Player_Client.lua", "lua/AdvancedHud/Player_Client.lua", "post")
ModLoader.SetupFileHook( "lua/UnitStatusMixin.lua", "lua/AdvancedHud/UnitStatusMixin.lua", "post")
ModLoader.SetupFileHook( "lua/TechTree.lua", "lua/AdvancedHud/TechTree.lua", "post")

-- Research display
ModLoader.SetupFileHook( "lua/Hud/GUINotificationItem.lua", "lua/AdvancedHud/GUINotificationItem.lua", "post")

ModLoader.SetupFileHook("lua/menu2/NavBar/Screens/Options/Mods/ModsMenuData.lua", "lua/AdvancedHud/ModsMenuData.lua", "post")