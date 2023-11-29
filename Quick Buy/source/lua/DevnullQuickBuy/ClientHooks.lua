if Client then
    local function DQB_Process_Hooks()
        --HPrint("Buy Menu Hotkeys mod -- processing file hooks")
        local ret,err = ModLoader.SetupFileHook("lua/menu/main_menu.css", "lua/DevnullQuickBuy/Client.lua", "post")
        ModLoader.SetupFileHook("lua/menu2/NavBar/Screens/Options/Mods/ModsMenuData.lua", "lua/DevnullQuickBuy/ModsMenuData.lua", "post")
        if not ret then
            HPrint("Devnull Quick Buy mod -- failed: %s", err)
        end
    end

    DQB_Process_Hooks()
end
