--=== This file modifies Natural Selection 2, Copyright Unknown Worlds Entertainment. ============
--
-- BuyMenuHotKeys\dqb_Client.lua
--
--    Original by:  Chris Baker (chris.l.baker@gmail.com)
--    This mod by:  Fredrik Rydin
--    License:      Public Domain
--
-- Public Domain license of this file does not supercede any Copyrights or Trademarks of Unknown
-- Worlds Entertainment, Inc. Natural Selection 2, its Assets, Source Code, Documentation, and
-- Utilities are Copyright Unknown Worlds Entertainment, Inc. All rights reserved.
-- ========= For more information, visit http:--www.unknownworlds.com ============================

local DQB_Version = "1.6"
local DQB_Name = "Devnull - Quick Buy Mod"
--print("GameMode: " .. tostring(GetGamemode()))
if GetGamemode() and GetGamemode() == "ns2" then
    HPrint(DQB_Name .. ", version " .. DQB_Version)
    -- Source the common mod code
    Script.Load("lua/DevnullQuickBuy/common.lua")

    -- Source the Alien Buy Menu code
    Script.Load("lua/DevnullQuickBuy/alien.lua")

    -- Source the Marine Buy Menu code
    Script.Load("lua/DevnullQuickBuy/marine.lua")
else
    HPrint(DQB_Name .. ", version " .. DQB_Version .. ", Disabled because non-standard game mode.")
end
