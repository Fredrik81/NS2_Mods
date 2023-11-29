local kVersion = "1.3"
local kName = "Devnull - Quality Of NS2 Life"

if Client then
    HPrint(kName .. ", version " .. kVersion)
end

--Hooks
--ModLoader.SetupFileHook("lua/Gorge.lua", "lua/Devnull_QOL/Gorge.lua", "post") -- Gorge Tweaks
ModLoader.SetupFileHook("lua/Babbler.lua", "lua/Devnull_QOL/Babbler.lua", "replace") -- Gorge Tweaks
ModLoader.SetupFileHook("lua/Weapons/Alien/BabblerPheromone.lua", "lua/Devnull_QOL/BabblerPheromone.lua", "replace") -- Gorge Tweaks
ModLoader.SetupFileHook("lua/Weapons/Marine/ClipWeapon.lua", "lua/Devnull_QOL/ClipWeapon.lua", "post") -- Marine Tweaks
ModLoader.SetupFileHook("lua/Weapons/Alien/BoneShield.lua", "lua/Devnull_QOL/BoneShield.lua", "post")
