-- Source the constants used in the key mapping table below
Script.Load("lua/TechTreeConstants.lua")

local gmbm_patched = false
local dqb_enabled = false

-- This list maps keybind names to TechId values
local techid_to_keybind =
{
    [kTechId.LayMines]             = kDQBMinesKey,
    [kTechId.Shotgun]              = kDQBShotgunKey,
    [kTechId.Welder]               = kDQBWelderKey,
    [kTechId.ClusterGrenade]       = kDQBClusterKey,
    [kTechId.GasGrenade]           = kDQBNervegasKey,
    [kTechId.PulseGrenade]         = kDQBPulseKey,
    [kTechId.GrenadeLauncher]      = kDQBGLKey,
    [kTechId.Flamethrower]         = kDQBFlamethrowerKey,
    [kTechId.HeavyMachineGun]      = kDQBHMGKey,

    [kTechId.Jetpack]              = kDQBJetpackKey,
    [kTechId.Exosuit]              = kDQBExominiKey,
    [kTechId.ClawRailgunExosuit]   = kDQBExorailKey,
    [kTechId.DualMinigunExosuit]   = kDQBExominiKey,
    [kTechId.DualRailgunExosuit]   = kDQBExorailKey,

    -- if they ever add this feature back in it should "just work"
    [kTechId.UpgradeToDualMinigun] = kDQBExodualKey,
    [kTechId.UpgradeToDualRailgun] = kDQBExodualKey,
}

local function DQB_Check_Keybinds(self, key, down)
    local retval = false

    -- Iterate through available purchases
    for _, item in ipairs(self.buyButtons) do
        if techid_to_keybind[item.TechID] and GetIsBinding(key, techid_to_keybind[item.TechID]) then
            retval = true

            -- Attempt Purchase
            if not down then
                local researched = MarineBuy_IsResearched(item.TechID)
                local itemCost = MarineBuy_GetCosts(item.TechID)
                local canAfford = PlayerUI_GetPlayerResources() >= itemCost
                local hasItem = PlayerUI_GetHasItem(item.TechID)
                if researched and canAfford and not hasItem then
                    --Print("Purchasing %s", EnumToString(kTechId, item.TechID))
                    MarineBuy_PurchaseItem(item.TechID)
                    if Client.GetOptionBoolean("dqb_closeonbuy", true) then
                        MarineBuy_OnClose()
                        self.closingMenu = true
                        MarineBuy_Close()
                    end
                end
            end -- if not down
            
            break
        end -- if key matches itemButton binding
    end -- for each itemButton

    return retval
end -- DQB_Check_Keybinds

local function DQB_Update_Button_Labels(self)
    local HudFull = Client.GetOptionInteger("hudmode", kHUDMode.Full) == kHUDMode.Full
    local HudLow = Client.GetOptionInteger("hudmode", kHUDMode.Low) == kHUDMode.Low
    local uiscale = Client.GetOptionFloat("dqb_ui_scale", kDQBMarineTextUIScale)
    local vuiscale = Vector(uiscale, uiscale, 0)
	local uishow = Client.GetOptionBoolean("dqb_showlabels", true)
    dqb_enabled = Client.GetOptionBoolean("dqb_enabled", false)
    --local kBackgroundSmallCoords = { 8, 1, 37, 29 }
    --local kBackgroundBigCoords = { 54, 1, 115, 30 }

    --Not enabled buttons
    if not self.dqb_marine_notenabled_text then
        self.dqb_marine_notenabled_text = GetGUIManager():CreateTextItem()
        self.dqb_marine_notenabled_text:SetText("QuickBuy not enabled, Enable from Options -> Mods menu")
        self.dqb_marine_notenabled_text:SetIsVisible(false)
        --self.dqb_marine_notenabled_text:SetIsScaling(false)
        self.dqb_marine_notenabled_text:SetPosition(Vector(100, -14, 0))
        self.dqb_marine_notenabled_text:SetAnchor(GUIItem.Left, GUIItem.Top)
        self.dqb_marine_notenabled_text:SetTextAlignmentX(GUIItem.Align_Min)
        self.dqb_marine_notenabled_text:SetTextAlignmentY(GUIItem.Align_Min)
        self.dqb_marine_notenabled_text:SetOptionFlag(GUIItem.CorrectScaling)
        GUIMakeFontScale(self.dqb_marine_notenabled_text, "kAgencyFB", 24)
        self.background:AddChild(self.dqb_marine_notenabled_text)
    else
        if dqb_enabled then
            self.dqb_marine_notenabled_text:SetIsVisible(false)
        else
            self.dqb_marine_notenabled_text:SetIsVisible(true)
        end
    end

    -- Iterate through available purchase buttons
    for i, item in ipairs(self.buyButtons) do
        if not item.dqb_hotkey_graphic then
            local keybind_name = techid_to_keybind[item.TechID]
            if (nil == keybind_name) then
                --print("DQB: TechID %d [%s] not matched in keybinds list", item.TechID, Locale.ResolveString(LookupTechData(item.TechID, kTechDataDisplayName, "")))
                item.dqb_hotkey_graphic = 1
            elseif "None" == BindingsUI_GetInputValue(keybind_name) then
                --print("DQB: TechId %d [%s] is not bound", item.TechID, Locale.ResolveString(LookupTechData(item.TechID, kTechDataDisplayName, "")))
                item.dqb_hotkey_graphic = 1
            else
                --print("Creating icon for : " .. Locale.ResolveString(LookupTechData(item.TechID, kTechDataDisplayName, "")))
                -- create a new button
                item.dqb_hotkey_graphic, item.dqb_hotkey_text = GUICreateButtonIcon(keybind_name, false)
                if string.match(item.dqb_hotkey_text:GetText(), "Num Pad") then
                    item.dqb_hotkey_text:SetText(item.dqb_hotkey_text:GetText():gsub("Num Pad", "Num"))
                    item.dqb_hotkey_graphic:SetSize(Vector(item.dqb_hotkey_text:GetTextWidth(item.dqb_hotkey_text:GetText()) + 22, 32, 0))
                end

                local buttonsize = item.Button:GetSize()
                local size = item.dqb_hotkey_graphic:GetSize()
                local scaledsize = item.dqb_hotkey_graphic:GetScaledSize()
                item.dqb_hotkey_text:SetScale(Vector(1,1,0))
                item.dqb_hotkey_graphic:SetScale(Vector(1,1,0))
                item.dqb_hotkey_graphic:SetAnchor(GUIItem.Middle, GUIItem.Top)
                item.dqb_hotkey_graphic:SetPosition(Vector(-(size.x/2),-5,0))
                item.dqb_hotkey_text:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
                item.dqb_hotkey_text:SetTextAlignmentX(GUIItem.Left)
                item.dqb_hotkey_text:SetTextAlignmentY(GUIItem.Align_Center)
                item.dqb_hotkey_text:SetPosition(Vector(0, -10, 0))
                item.Button:AddChild(item.dqb_hotkey_graphic)
            end -- keybind_name...
        else
            -- item.dqb_hotkey_graphic not nil
            if (item.dqb_hotkey_graphic ~= 1) then
                -- disable the button graphic if HUD is set below full
                if (HudFull or HudLow) and uishow and dqb_enabled then
                    -- update the position
                    local buttonsize = item.Button:GetSize()
                    local size = item.dqb_hotkey_graphic:GetSize()
                    local scaledsize = item.dqb_hotkey_graphic:GetScaledSize()
                    local xcorr = (size.x-scaledsize.x)*.5
                    local ycorr = (size.y-scaledsize.y)*.5

                    -- set visible
                    item.dqb_hotkey_graphic:SetIsVisible(true)
                else
                    item.dqb_hotkey_graphic:SetIsVisible(false)
                end
            end -- item.dqb_hotkey_graphic valid
        end -- item.dqb_hotkey_graphic...
    end -- for item
end -- DQB_Update_Button_Labels

-- We will extend MarineBuy_OnOpen in order to patch GUIMarineBuyMenu
local originalMBOnOpen = MarineBuy_OnOpen
function MarineBuy_OnOpen()
    -- GUIMarineBuyMenu should now be loaded -- commence patching functions
    if (not gmbm_patched) and GUIMarineBuyMenu then
        -- We will extend GUIMarineBuyMenu:SendKeyEvent
        local originalGMBMSendKeyEvent = GUIMarineBuyMenu.SendKeyEvent
        function GUIMarineBuyMenu:SendKeyEvent(key, down)
            local stop = false
            if dqb_enabled then
                stop = DQB_Check_Keybinds(self, key, down)
            end

            if not stop then
                stop = originalGMBMSendKeyEvent(self, key, down)
            end
            return stop
        end -- GUIMarineBuyMenu:SendKeyEvent

        -- We will extend GUIMarineBuyMenu:_UpdateItemButtons
        local originalGMBM_Update = GUIMarineBuyMenu.Update
        function GUIMarineBuyMenu:Update(deltaTime)
            originalGMBM_Update(self, deltaTime)
            DQB_Update_Button_Labels(self)
        end

        gmbm_patched = true
    end -- if not gmbm_patched

    originalMBOnOpen()
end
