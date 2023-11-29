local gabm_patched = false
local dqb_enabled = false
local textureEmpty = PrecacheAsset("ui/Devnull/QuickBuy/empty.dds")

--[[
 * This function duplicated from GUIAlienBuyMenu.lua verbatim
 --]]
local function enumContainElement(enum, element)
    for _, v in pairs(enum) do
        if _ == element then
            return true
        end
    end
    return false
end

local techCarapaceWorkaround = enumContainElement(kTechId, "Resilience") and kTechId.Resilience or kTechId.Carapace

local function GetUpgradeCostForLifeForm(player, alienType, upgradeId)
    if player then
        local alienTechNode = GetAlienTechNode(alienType, true)
        if alienTechNode then
            if player:GetTechId() == alienTechNode:GetTechId() and player:GetHasUpgrade(upgradeId) then
                return 0
            end

            return LookupTechData(alienTechNode:GetTechId(), kTechDataUpgradeCost, 0)
        end
    end

    return 0
end

--[[
 * This function duplicated from GUIAlienBuyMenu.lua verbatim
 --]]
local function MarkAlreadyPurchased(self)
    local isAlreadySelectedAlien = not self:GetNewLifeFormSelected()
    for i, currentButton in ipairs(self.upgradeButtons) do
        currentButton.Purchased = isAlreadySelectedAlien and AlienBuy_GetUpgradePurchased(currentButton.TechId)
    end
end

-- TODO: This function probably needs some refactoring...
local function DQB_Check_Keybinds(self, key, down)
    local crushbutton = nil
    local carabutton = nil
    local regenbutton = nil
    --local phantombutton = nil
    local focusbutton = nil
    local vampbutton = nil
    local aurabutton = nil
    local adrenbutton = nil
    local celeritybutton = nil
    local camouflagebutton = nil
    local prevselection = nil
    local retval = false
    local combat_mode_not_active = true
    --print("Caraworkaround: " .. tostring(techCarapaceWorkaround))

    -- check whether Combat Mode is active
    if (kCombatModActive ~= nil) and (kCombatModActive == true) then
        combat_mode_not_active = false
    end

    -- get current lifeform status
    if (self.selectedAlienType) then
        prevselection = self.selectedAlienType
    end

    -- get current upgrade status
    for _, currentButton in ipairs(self.upgradeButtons) do
        if currentButton.TechId == kTechId.Vampirism then
            vampbutton = currentButton
        elseif currentButton.TechId == techCarapaceWorkaround then
            carabutton = currentButton
        elseif currentButton.TechId == kTechId.Regeneration then
            regenbutton = currentButton
        elseif currentButton.TechId == kTechId.Focus then
            focusbutton = currentButton
        elseif currentButton.TechId == kTechId.Camouflage then
            camouflagebutton = currentButton
        elseif currentButton.TechId == kTechId.Aura then
            aurabutton = currentButton
        elseif currentButton.TechId == kTechId.Adrenaline then
            adrenbutton = currentButton
        elseif currentButton.TechId == kTechId.Celerity then
            celeritybutton = currentButton
        elseif currentButton.TechId == kTechId.Crush then
            crushbutton = currentButton
        end -- currentButton.TechId...
    end -- for upgradeButtons

    -- check upgrade keys
    if GetIsBinding(key, kDQBCrushKey) then
        if not down then
            --Print("--Toggle Crush")
            if crushbutton and not crushbutton.Selected and AlienBuy_GetTechAvailable(kTechId.Crush) then
                if combat_mode_not_active then
                    if adrenbutton and adrenbutton.Selected then
                        adrenbutton.Selected = false
                        adrenbutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Adrenaline)
                        AlienBuy_OnUpgradeDeselected()
                    end
                    if celeritybutton and celeritybutton.Selected then
                        celeritybutton.Selected = false
                        celeritybutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Celerity)
                        AlienBuy_OnUpgradeDeselected()
                    end
                end
                crushbutton.Selected = true
                crushbutton.Purchased = false
                table.insertunique(self.upgradeList, kTechId.Crush)
                AlienBuy_OnUpgradeSelected()
            elseif crushbutton and crushbutton.Selected then
                crushbutton.Selected = false
                crushbutton.Purchased = false
                table.removevalue(self.upgradeList, kTechId.Crush)
                AlienBuy_OnUpgradeDeselected()
            end -- if crushbutton...
        end -- if not down
        retval = true
    end -- if key == dqb_crush

    if GetIsBinding(key, kDQBCarapaceKey) then
        if not down then
            --Print("--Toggle Carapace")
            if carabutton and not carabutton.Selected and AlienBuy_GetTechAvailable(techCarapaceWorkaround) then
                if combat_mode_not_active then
                    if regenbutton and regenbutton.Selected then
                        regenbutton.Selected = false
                        regenbutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Regeneration)
                        AlienBuy_OnUpgradeDeselected()
                    end
                    if vampbutton and vampbutton.Selected then
                        vampbutton.Selected = false
                        vampbutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Vampirism)
                        AlienBuy_OnUpgradeDeselected()
                    end
                end
                carabutton.Selected = true
                carabutton.Purchased = false
                table.insertunique(self.upgradeList, techCarapaceWorkaround)
                AlienBuy_OnUpgradeSelected()
            elseif carabutton and carabutton.Selected then
                carabutton.Selected = false
                carabutton.Purchased = false
                table.removevalue(self.upgradeList, techCarapaceWorkaround)
                AlienBuy_OnUpgradeDeselected()
            end -- if carabutton...
        end -- if not down
        retval = true
    end -- if key == dqb_carapace

    if GetIsBinding(key, kDQBRegenerationKey) then
        if not down then
            --Print("--Toggle Regeneration")
            if regenbutton and not regenbutton.Selected and AlienBuy_GetTechAvailable(kTechId.Regeneration) then
                if combat_mode_not_active then
                    if carabutton and carabutton.Selected then
                        carabutton.Selected = false
                        carabutton.Purchased = false
                        table.removevalue(self.upgradeList, techCarapaceWorkaround)
                        AlienBuy_OnUpgradeDeselected()
                    end
                    if vampbutton and vampbutton.Selected then
                        vampbutton.Selected = false
                        vampbutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Vampirism)
                        AlienBuy_OnUpgradeDeselected()
                    end
                end
                regenbutton.Selected = true
                regenbutton.Purchased = false
                table.insertunique(self.upgradeList, kTechId.Regeneration)
                AlienBuy_OnUpgradeSelected()
            elseif regenbutton and regenbutton.Selected then
                regenbutton.Selected = false
                regenbutton.Purchased = false
                table.removevalue(self.upgradeList, kTechId.Regeneration)
                AlienBuy_OnUpgradeDeselected()
            end -- if regenbutton...
        end -- if not down
        retval = true
    end

    if GetIsBinding(key, kDQBFocusKey) then
        if not down then
            if focusbutton and not focusbutton.Selected and AlienBuy_GetTechAvailable(kTechId.Focus) then
                if combat_mode_not_active then
                    if camouflagebutton and camouflagebutton.Selected then
                        camouflagebutton.Selected = false
                        camouflagebutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Camouflage)
                        AlienBuy_OnUpgradeDeselected()
                    end
                    if aurabutton and aurabutton.Selected then
                        aurabutton.Selected = false
                        aurabutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Aura)
                        AlienBuy_OnUpgradeDeselected()
                    end
                end
                focusbutton.Selected = true
                focusbutton.Purchased = false
                table.insertunique(self.upgradeList, kTechId.Focus)
                AlienBuy_OnUpgradeSelected()
            elseif focusbutton and focusbutton.Selected then
                focusbutton.Selected = false
                focusbutton.Purchased = false
                table.removevalue(self.upgradeList, kTechId.Focus)
                AlienBuy_OnUpgradeDeselected()
            end -- if focusbutton...
        end -- if not down
        retval = true
    end -- if key == dqb_focus

    if GetIsBinding(key, kDQBVampirismKey) then
        if not down then
            --Print("--Toggle Vampirism")
            if vampbutton and not vampbutton.Selected and AlienBuy_GetTechAvailable(kTechId.Vampirism) then
                if combat_mode_not_active then
                    if regenbutton and regenbutton.Selected then
                        regenbutton.Selected = false
                        regenbutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Regeneration)
                        AlienBuy_OnUpgradeDeselected()
                    end
                    if carabutton and carabutton.Selected then
                        carabutton.Selected = false
                        carabutton.Purchased = false
                        table.removevalue(self.upgradeList, techCarapaceWorkaround)
                        AlienBuy_OnUpgradeDeselected()
                    end
                end
                vampbutton.Selected = true
                vampbutton.Purchased = false
                table.insertunique(self.upgradeList, kTechId.Vampirism)
                AlienBuy_OnUpgradeSelected()
            elseif vampbutton and vampbutton.Selected then
                vampbutton.Selected = false
                vampbutton.Purchased = false
                table.removevalue(self.upgradeList, kTechId.Vampirism)
                AlienBuy_OnUpgradeDeselected()
            end -- if vampbutton...
        end -- if not down
        retval = true
    end -- if key == dqb_vampirism

    if GetIsBinding(key, kDQBAuraKey) then
        if not down then
            --Print("--Toggle Aura")
            if aurabutton and not aurabutton.Selected and AlienBuy_GetTechAvailable(kTechId.Aura) then
                if combat_mode_not_active then
                    if camouflagebutton and camouflagebutton.Selected then
                        camouflagebutton.Selected = false
                        camouflagebutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Camouflage)
                        AlienBuy_OnUpgradeDeselected()
                    end
                    if focusbutton and focusbutton.Selected then
                        focusbutton.Selected = false
                        focusbutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Focus)
                        AlienBuy_OnUpgradeDeselected()
                    end
                end
                aurabutton.Selected = true
                aurabutton.Purchased = false
                table.insertunique(self.upgradeList, kTechId.Aura)
                AlienBuy_OnUpgradeSelected()
            elseif aurabutton and aurabutton.Selected then
                aurabutton.Selected = false
                aurabutton.Purchased = false
                table.removevalue(self.upgradeList, kTechId.Aura)
                AlienBuy_OnUpgradeDeselected()
            end -- if aurabutton...
        end -- if not down
        retval = true
    end -- if key == dqb_aura

    if GetIsBinding(key, kDQBAdrenalineKey) then
        if not down then
            --Print("--Toggle Adrenaline")
            if adrenbutton and not adrenbutton.Selected and AlienBuy_GetTechAvailable(kTechId.Adrenaline) then
                if combat_mode_not_active then
                    if celeritybutton and celeritybutton.Selected then
                        celeritybutton.Selected = false
                        celeritybutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Celerity)
                        AlienBuy_OnUpgradeDeselected()
                    end
                    if crushbutton and crushbutton.Selected then
                        crushbutton.Selected = false
                        crushbutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Crush)
                        AlienBuy_OnUpgradeDeselected()
                    end
                end
                adrenbutton.Selected = true
                adrenbutton.Purchased = false
                table.insertunique(self.upgradeList, kTechId.Adrenaline)
                AlienBuy_OnUpgradeSelected()
            elseif adrenbutton and adrenbutton.Selected then
                adrenbutton.Selected = false
                adrenbutton.Purchased = false
                table.removevalue(self.upgradeList, kTechId.Adrenaline)
                AlienBuy_OnUpgradeDeselected()
            end -- if adrenbutton...
        end -- if not down
        retval = true
    end -- if key == dqb_adrenaline

    if GetIsBinding(key, kDQBCelerityKey) then
        if not down then
            --Print("--Toggle Celerity")
            if celeritybutton and not celeritybutton.Selected and AlienBuy_GetTechAvailable(kTechId.Celerity) then
                if combat_mode_not_active then
                    if adrenbutton and adrenbutton.Selected then
                        adrenbutton.Selected = false
                        adrenbutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Adrenaline)
                        AlienBuy_OnUpgradeDeselected()
                    end
                    if crushbutton and crushbutton.Selected then
                        crushbutton.Selected = false
                        crushbutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Crush)
                        AlienBuy_OnUpgradeDeselected()
                    end
                end
                celeritybutton.Selected = true
                celeritybutton.Purchased = false
                table.insertunique(self.upgradeList, kTechId.Celerity)
                AlienBuy_OnUpgradeSelected()
            elseif celeritybutton and celeritybutton.Selected then
                celeritybutton.Selected = false
                celeritybutton.Purchased = false
                table.removevalue(self.upgradeList, kTechId.Celerity)
                AlienBuy_OnUpgradeDeselected()
            end -- if celeritybutton...
        end -- if not down
        retval = true
    end -- if key == dqb_celerity

    if GetIsBinding(key, kDQBCamouflageKey) then
        if not down then
            --Print("--Toggle Camouflage")
            if camouflagebutton and not camouflagebutton.Selected and AlienBuy_GetTechAvailable(kTechId.Camouflage) then
                if combat_mode_not_active then
                    if aurabutton and aurabutton.Selected then
                        aurabutton.Selected = false
                        aurabutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Aura)
                        AlienBuy_OnUpgradeDeselected()
                    end
                    if focusbutton and focusbutton.Selected then
                        focusbutton.Selected = false
                        focusbutton.Purchased = false
                        table.removevalue(self.upgradeList, kTechId.Focus)
                        AlienBuy_OnUpgradeDeselected()
                    end
                end
                camouflagebutton.Selected = true
                camouflagebutton.Purchased = false
                table.insertunique(self.upgradeList, kTechId.Camouflage)
                AlienBuy_OnUpgradeSelected()
            elseif camouflagebutton and camouflagebutton.Selected then
                camouflagebutton.Selected = false
                camouflagebutton.Purchased = false
                table.removevalue(self.upgradeList, kTechId.Camouflage)
                AlienBuy_OnUpgradeDeselected()
            end -- if camouflagebutton...
        end -- if not down
        retval = true
    end -- if key == dqb_camouflage

    -- check lifeform keys
    if GetIsBinding(key, kDQBSkulkKey) then
        if not down then
            self.selectedAlienType = AlienTechIdToIndex(kTechId.Skulk)
            if self.selectedAlienType ~= prevselection then
                AlienBuy_OnSelectAlien("Skulk")
                if combat_mode_not_active then
                    MarkAlreadyPurchased(self)
                    self:SetPurchasedSelected()
                end
            --Print("--Selected Skulk")
            end
        end
        retval = true
    end -- if key == dqb_skulk

    if GetIsBinding(key, kDQBGorgeKey) then
        if not down then
            self.selectedAlienType = AlienTechIdToIndex(kTechId.Gorge)
            if self.selectedAlienType ~= prevselection then
                AlienBuy_OnSelectAlien("Gorge")
                if combat_mode_not_active then
                    MarkAlreadyPurchased(self)
                    self:SetPurchasedSelected()
                end
            --Print("--Selected Gorge")
            end
        end
        retval = true
    end -- if key == dqb_gorge

    if GetIsBinding(key, kDQBLerkKey) then
        if not down then
            self.selectedAlienType = AlienTechIdToIndex(kTechId.Lerk)
            if self.selectedAlienType ~= prevselection then
                AlienBuy_OnSelectAlien("Lerk")
                if combat_mode_not_active then
                    MarkAlreadyPurchased(self)
                    self:SetPurchasedSelected()
                end
            --Print("--Selected Lerk")
            end
        end
        retval = true
    end -- if key == dqb_lerk

    if GetIsBinding(key, kDQBFadeKey) then
        if not down then
            self.selectedAlienType = AlienTechIdToIndex(kTechId.Fade)
            if self.selectedAlienType ~= prevselection then
                AlienBuy_OnSelectAlien("Fade")
                if combat_mode_not_active then
                    MarkAlreadyPurchased(self)
                    self:SetPurchasedSelected()
                end
            --Print("--Selected Fade")
            end
        end
        retval = true
    end -- if key == dqb_fade

    if GetIsBinding(key, kDQBOnosKey) then
        if not down then
            self.selectedAlienType = AlienTechIdToIndex(kTechId.Onos)
            if self.selectedAlienType ~= prevselection then
                AlienBuy_OnSelectAlien("Onos")
                if combat_mode_not_active then
                    MarkAlreadyPurchased(self)
                    self:SetPurchasedSelected()
                end
            --Print("--Selected Onos")
            end
        end
        retval = true
    end -- if key == dqb_onos

    -- last, check evolve key
    if GetIsBinding(key, kDQBEvolveKey) then
        if not down then
            if PlayerUI_GetHasGameStarted() then
                local purchases = {}
                local upgradeCost = 0
                local newUpgrades = 0
                local player = Client.GetLocalPlayer()

                -- Add the selected lifeform
                if self.selectedAlienType ~= AlienBuy_GetCurrentAlien() then
                    upgradeCost = AlienBuy_GetAlienCost(self.selectedAlienType, false)
                    --Print("--Alien %s selected", EnumToString(kTechId, IndexToAlienTechId(self.selectedAlienType)))
                    if (combat_mode_not_active) then
                        table.insert(purchases, {Type = "Alien", Alien = self.selectedAlienType})
                        newUpgrades = newUpgrades + 1
                    else
                        -- in combat mode, only buy another class when you're a skulk
                        if AlienBuy_GetCurrentAlien() == AlienTechIdToIndex(kTechId.Skulk) then
                            table.insert(purchases, AlienBuy_GetTechIdForAlien(self.selectedAlienType))
                            newUpgrades = newUpgrades + 1
                        end
                    end
                end

                -- Add all selected upgrades
                for _, currentButton in ipairs(self.upgradeButtons) do
                    if currentButton.Selected then
                        upgradeCost = upgradeCost + GetUpgradeCostForLifeForm(player, self.selectedAlienType, currentButton.TechId)
                        if not player:GetHasUpgrade(currentButton.TechId) then
                            newUpgrades = newUpgrades + 1
                        end
                        if (combat_mode_not_active) then
                            table.insert(purchases, {Type = "Upgrade", Alien = self.selectedAlienType, UpgradeIndex = currentButton.Index, TechId = currentButton.TechId})
                        else
                            table.insert(purchases, currentButton.TechId)
                        end
                    end
                end

                -- Check purchases against available PRes
                if (newUpgrades > 0) and (PlayerUI_GetPlayerResources() >= upgradeCost) then
                    --Print("--purchasing upgrades for %d", upgradeCost)
                    AlienBuy_Purchase(purchases)
                    AlienBuy_OnPurchase()
                end
            end -- if PlayerUI_GetHasGameStarted
            self.closingMenu = true
            AlienBuy_Close()
        end -- if not down
        retval = true
    end -- if key == dqb_evolve

    return retval
end -- DQB_Check_Keybinds

-- Helper function to create hotkey labels for each button based on TechId
local function DQB_Create_Button_Label(TechId)
    local hotkey_graphic = nil
    local hotkey_text = nil

    -- Lifeform Tech IDs
    if (TechId == kTechId.Skulk) and ("None" ~= BindingsUI_GetInputValue(kDQBSkulkKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBSkulkKey, true)
    elseif (TechId == kTechId.Gorge) and ("None" ~= BindingsUI_GetInputValue(kDQBGorgeKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBGorgeKey, true)
    elseif (TechId == kTechId.Lerk) and ("None" ~= BindingsUI_GetInputValue(kDQBLerkKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBLerkKey, true)
    elseif (TechId == kTechId.Fade) and ("None" ~= BindingsUI_GetInputValue(kDQBFadeKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBFadeKey, true)
    elseif (TechId == kTechId.Onos) and ("None" ~= BindingsUI_GetInputValue(kDQBOnosKey)) then
        -- Upgrade Tech IDs
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBOnosKey, true)
    elseif (TechId == kTechId.Regeneration) and ("None" ~= BindingsUI_GetInputValue(kDQBRegenerationKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBRegenerationKey, true)
        hotkey_graphic:SetAnchor(GUIItem.Right, GUIItem.Center)
    elseif (TechId == techCarapaceWorkaround) and ("None" ~= BindingsUI_GetInputValue(kDQBCarapaceKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBCarapaceKey, true)
        hotkey_graphic:SetAnchor(GUIItem.Right, GUIItem.Center)
    elseif (TechId == kTechId.Vampirism) and ("None" ~= BindingsUI_GetInputValue(kDQBVampirismKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBVampirismKey, true)
        hotkey_graphic:SetAnchor(GUIItem.Right, GUIItem.Center)
    elseif (TechId == kTechId.Adrenaline) and ("None" ~= BindingsUI_GetInputValue(kDQBAdrenalineKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBAdrenalineKey, true)
        hotkey_graphic:SetAnchor(GUIItem.Left, GUIItem.Center)
    elseif (TechId == kTechId.Celerity) and ("None" ~= BindingsUI_GetInputValue(kDQBCelerityKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBCelerityKey, true)
        hotkey_graphic:SetAnchor(GUIItem.Left, GUIItem.Center)
    elseif (TechId == kTechId.Crush) and ("None" ~= BindingsUI_GetInputValue(kDQBCrushKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBCrushKey, true)
        hotkey_graphic:SetAnchor(GUIItem.Left, GUIItem.Center)
    elseif (TechId == kTechId.Camouflage) and ("None" ~= BindingsUI_GetInputValue(kDQBCamouflageKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBCamouflageKey, true)
        hotkey_graphic:SetAnchor(GUIItem.Left, GUIItem.Center)
    elseif (TechId == kTechId.Focus) and ("None" ~= BindingsUI_GetInputValue(kDQBFocusKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBFocusKey, true)
        hotkey_graphic:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    elseif (TechId == kTechId.Aura) and ("None" ~= BindingsUI_GetInputValue(kDQBAuraKey)) then
        --[[elseif (TechId == kTechId.Phantom) and ("None" ~= BindingsUI_GetInputValue(kDQBPhantomKey)) then
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBPhantomKey, true)
        hotkey_graphic:SetAnchor(GUIItem.Left, GUIItem.Middle)--]]
        -- Else, return nil
        hotkey_graphic, hotkey_text = GUICreateButtonIcon(kDQBAuraKey, true)
        hotkey_graphic:SetAnchor(GUIItem.Right, GUIItem.Center)
    else
        Print("DQB: TechId %d [%s] unrecognized or unbound", TechId, Locale.ResolveString(LookupTechData(TechId, kTechDataDisplayName, "")))
    end -- TechId...

    if string.match(hotkey_text:GetText(), "Num Pad") then
        hotkey_text:SetText(hotkey_text:GetText():gsub("Num Pad", "Num"))
        hotkey_graphic:SetSize(Vector(hotkey_text:GetTextWidth(hotkey_text:GetText()) + 22, 32, 0))
    end

    return hotkey_graphic, hotkey_text
end -- DQB_Create_Button_Label

-- Helper function to adjust the hotkey label position for each button based on TechId
local function DQB_Set_Label_Position(label, TechId, xcorr, ycorr)
    -- quick sanity check
    if label and (label ~= 1) then
        local size = label:GetSize()
        local newpos = nil

        -- Lifeform Tech IDs
        if TechId == kTechId.Skulk then
            newpos = Vector(-(size.x / 2), 0, 0)
        elseif TechId == kTechId.Gorge then
            newpos = Vector(-(size.x / 2), 0, 0)
        elseif TechId == kTechId.Lerk then
            newpos = Vector(-(size.x / 2), -(size.y / 2) - GUIScale(16), 0)
        elseif TechId == kTechId.Fade then
            newpos = Vector(-(size.x / 2), 0, 0)
        elseif TechId == kTechId.Onos then
            -- Upgrade Tech IDs
            --[[elseif TechId == kTechId.Phantom then
            label:SetPosition(Vector(-size.x,0,0))--]]
            newpos = Vector(-(size.x / 2), 0, 0)
        elseif TechId == kTechId.Regeneration then
            newpos = Vector(-xcorr, 0, 0)
        elseif enumContainElement(kTechId, "Carapace") and TechId == techCarapaceWorkaround then
            newpos = Vector(-xcorr, 0, 0)
        elseif enumContainElement(kTechId, "Resilience") and TechId == kTechId.Resilience then
            newpos = Vector(-xcorr, 0, 0)
        elseif TechId == kTechId.Vampirism then
            --  newpos = Vector(-size.x/2,-(size.y/2)-ycorr,0)
            newpos = Vector(-xcorr, 0, 0)
        elseif TechId == kTechId.Adrenaline then
            newpos = Vector(-size.x + xcorr, 0, 0)
        elseif TechId == kTechId.Celerity then
            newpos = Vector(-size.x + xcorr, 0, 0)
        elseif TechId == kTechId.Crush then
            -- newpos = Vector(-xcorr,0,0)
            newpos = Vector(-size.x + xcorr, 0, 0)
        elseif TechId == kTechId.Camouflage then
            newpos = Vector(-size.x + xcorr, 0, 0)
        elseif TechId == kTechId.Focus then
            -- newpos = Vector(xcorr,-ycorr,0)
            --newpos = Vector(0,0,0)
            --newpos = Vector(size.x+xcorr,-ycorr,0)
            newpos = Vector(((math.floor((size.x) / 2)) * -1) + xcorr + 8, -ycorr * 2, 0)
        elseif TechId == kTechId.Aura then
            newpos = Vector(-8 - xcorr, -ycorr, 0)
        end -- TechId...

        if newpos then
            label:SetPosition(newpos)
        end
    end -- if label valid
end -- DQB_Set_Label_Position

local function DQB_Update_Button_Labels(self)
    local HudFull = Client.GetOptionInteger("hudmode", kHUDMode.Full) == kHUDMode.Full
    local HudLow = Client.GetOptionInteger("hudmode", kHUDMode.Low) == kHUDMode.Low
    local uiscale = Client.GetOptionFloat("dqb_ui_scale", kDQBDefaultUIScale)
    local vuiscale = Vector(uiscale, uiscale, 0)
    local uishow = Client.GetOptionBoolean("dqb_showlabels", true)
    dqb_enabled = Client.GetOptionBoolean("dqb_enabled", false)
    -- Iterate the Lifeform buttons and add hotkey icons
    for _, alienButton in ipairs(self.alienButtons) do
        if alienButton.Button:GetIsVisible() then
            local techId = IndexToAlienTechId(alienButton.TypeData.Index)
            if not alienButton.dqb_alien_hotkey_graphic then
                -- create a new button
                alienButton.dqb_alien_hotkey_graphic, alienButton.dqb_alien_hotkey_text = DQB_Create_Button_Label(techId)
                if string.match(alienButton.dqb_alien_hotkey_text:GetText(), "Num Pad") then
                    alienButton.dqb_alien_hotkey_text:SetText(alienButton.dqb_alien_hotkey_text:GetText():gsub("Num Pad", "Num"))
                    alienButton.dqb_alien_hotkey_graphic:SetSize(Vector(alienButton.dqb_alien_hotkey_text:GetTextWidth(alienButton.dqb_alien_hotkey_text:GetText()) + 22, 32, 0))
                end

                if not alienButton.dqb_alien_hotkey_graphic then
                    -- don't process this button in the future
                    alienButton.dqb_alien_hotkey_graphic = 1
                else
                    alienButton.dqb_alien_hotkey_text:SetColor(1, 1, 0.8)
                    -- apply generic settings to the button
                    DQB_Set_Label_Position(alienButton.dqb_alien_hotkey_graphic, techId)
                     --]]
                    alienButton.dqb_alien_hotkey_graphic:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
                    alienButton.dqb_alien_hotkey_graphic:SetLayer(kGUILayerPlayerHUDForeground4)
                    alienButton.Button:AddChild(alienButton.dqb_alien_hotkey_graphic)
                end
            end -- alienButton.dqb_alien_hotkey_graphic...

            if (alienButton.dqb_alien_hotkey_graphic ~= 1) then
                -- disable the button graphic if HUD is set below full
                if (HudFull or HudLow) and uishow and dqb_enabled then
                    --if fullhud and (uiscale ~= 0) then
                    -- scale the button and text label
                    alienButton.dqb_alien_hotkey_text:SetScale(vuiscale)
                    alienButton.dqb_alien_hotkey_graphic:SetScale(vuiscale)
                    local size = alienButton.dqb_alien_hotkey_graphic:GetSize()
                    local scaledsize = alienButton.dqb_alien_hotkey_graphic:GetScaledSize()
                    local xcorr = (size.x - scaledsize.x) * .5
                    local ycorr = (size.y - scaledsize.y) * .5
                    alienButton.dqb_alien_hotkey_text:SetPosition(Vector(xcorr, ycorr, 0))

                    -- update the position
                    DQB_Set_Label_Position(alienButton.dqb_alien_hotkey_graphic, techId, xcorr, ycorr)

                    -- set visible
                    alienButton.dqb_alien_hotkey_graphic:SetIsVisible(true)
                else
                    alienButton.dqb_alien_hotkey_graphic:SetIsVisible(false)
                end -- if fullhud/scale
            end -- if currentButton.dqb_upgrade_hotkey_graphic valid
        end -- if alienButton visible
    end -- for alienButton

    -- Iterate the Upgrade buttons and add hotkey icons
    for _, currentButton in ipairs(self.upgradeButtons) do
        if currentButton.Icon:GetIsVisible() then
            if not currentButton.dqb_upgrade_hotkey_graphic then
                -- create a new button
                currentButton.dqb_upgrade_hotkey_graphic, currentButton.dqb_upgrade_hotkey_text = DQB_Create_Button_Label(currentButton.TechId)

                if not currentButton.dqb_upgrade_hotkey_graphic then
                    -- don't process this button in the future
                    currentButton.dqb_upgrade_hotkey_graphic = 1
                else
                    currentButton.dqb_upgrade_hotkey_text:SetColor(1, 1, 0.8)
                    currentButton.dqb_upgrade_hotkey_graphic:SetLayer(kGUILayerPlayerHUDForeground4)
                    currentButton.Icon:AddChild(currentButton.dqb_upgrade_hotkey_graphic)
                end
            end -- currentButton.dqb_upgrade_hotkey_graphic...

            if (currentButton.dqb_upgrade_hotkey_graphic ~= 1) then
                -- disable the button graphic if HUD is set below full
                if (HudFull or HudLow) and uishow and dqb_enabled then
                    --if fullhud and (uiscale ~= 0) then
                    -- scale the button and text label
                    currentButton.dqb_upgrade_hotkey_text:SetScale(vuiscale)
                    currentButton.dqb_upgrade_hotkey_graphic:SetScale(vuiscale)
                    local size = currentButton.dqb_upgrade_hotkey_graphic:GetSize()
                    local scaledsize = currentButton.dqb_upgrade_hotkey_graphic:GetScaledSize()
                    local xcorr = (size.x - scaledsize.x) * .5
                    local ycorr = (size.y - scaledsize.y) * .5
                    currentButton.dqb_upgrade_hotkey_text:SetPosition(Vector(xcorr, ycorr, 0))

                    -- update the position
                    DQB_Set_Label_Position(currentButton.dqb_upgrade_hotkey_graphic, currentButton.TechId, xcorr, ycorr)

                    -- set visible
                    currentButton.dqb_upgrade_hotkey_graphic:SetIsVisible(true)
                else
                    currentButton.dqb_upgrade_hotkey_graphic:SetIsVisible(false)
                end -- if fullhud/scale
            end -- if currentButton.dqb_upgrade_hotkey_graphic valid
        end -- if currentButton.Icon visible
    end -- for upgradeButtons

    -- Add hotkey icon to the Evolve button
    if self.evolveButtonBackground:GetIsVisible() then
        if not self.dqb_evolve_hotkey_graphic then
            if "None" == BindingsUI_GetInputValue(kDQBEvolveKey) then
                self.dqb_evolve_hotkey_graphic = 1
            else
                -- create a new button
                self.dqb_evolve_hotkey_graphic, self.dqb_evolve_hotkey_text = GUICreateButtonIcon(kDQBEvolveKey, true)
                self.dqb_evolve_hotkey_text:SetColor(1, 1, 0.8)
                if string.match(self.dqb_evolve_hotkey_text:GetText(), "Num Pad") then
                    self.dqb_evolve_hotkey_text:SetText(self.dqb_evolve_hotkey_text:GetText():gsub("Num Pad", "Num"))
                    self.dqb_evolve_hotkey_graphic:SetSize(Vector(self.dqb_evolve_hotkey_text:GetTextWidth(self.dqb_evolve_hotkey_text:GetText()) + 22, 32, 0))
                end
                self.dqb_evolve_hotkey_text_org = self.dqb_evolve_hotkey_text:GetText()
                self.dqb_evolve_hotkey_graphic_org = self.dqb_evolve_hotkey_graphic:GetTexture()
                self.dqb_evolve_hotkey_graphic:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
                self.dqb_evolve_hotkey_graphic:SetLayer(kGUILayerPlayerHUDForeground4)

                self.evolveButtonBackground:AddChild(self.dqb_evolve_hotkey_graphic)
                self.dqb_evolve_hotkey_graphic:SetIsVisible(true)
            end
        end -- self.dqb_evolve_hotkey_graphic...

        if (self.dqb_evolve_hotkey_graphic ~= 1) then
            -- disable the button graphic if HUD is set below full
            if (HudFull or HudLow) and uishow then
                if dqb_enabled then
                    self.dqb_evolve_hotkey_text:SetText(self.dqb_evolve_hotkey_text_org)
                    self.dqb_evolve_hotkey_graphic:SetTexture(self.dqb_evolve_hotkey_graphic_org)
                else
                    self.dqb_evolve_hotkey_text:SetText("QuickBuy not enabled!\nEnable from Options -> Mods menu")
                    self.dqb_evolve_hotkey_text:SetTextAlignmentX(GUIItem.Middle)
                    self.dqb_evolve_hotkey_text:SetTextAlignmentY(GUIItem.Middle)
                end

                -- scale the button and text label
                self.dqb_evolve_hotkey_text:SetScale(vuiscale)
                self.dqb_evolve_hotkey_graphic:SetScale(vuiscale)
                local size = self.dqb_evolve_hotkey_graphic:GetSize()
                local scaledsize = self.dqb_evolve_hotkey_graphic:GetScaledSize()
                local xcorr = (size.x - scaledsize.x) * .5
                local ycorr = (size.y - scaledsize.y) * .5
                self.dqb_evolve_hotkey_text:SetPosition(Vector(xcorr, ycorr, 0))

                -- update the position
                local size = self.dqb_evolve_hotkey_graphic:GetSize()
                self.dqb_evolve_hotkey_graphic:SetPosition(Vector(-(size.x / 2), 1 - ycorr, 0))

                -- set visible
                self.dqb_evolve_hotkey_graphic:SetIsVisible(true)

                -- Change textture if disabled
                if not dqb_enabled then
                    self.dqb_evolve_hotkey_graphic:SetTexture(textureEmpty)
                end
            else
                self.dqb_evolve_hotkey_graphic:SetIsVisible(false)
            end -- if fullhud/scale
        end -- if self.dqb_evolve_hotkey_graphic valid
    end -- if evolveButtonBackground visible
end -- DQB_Update_Button_Labels

-- We will extend AlienBuy_OnOpen in order to patch GUIAlienBuyMenu
local originalABOnOpen = AlienBuy_OnOpen
function AlienBuy_OnOpen()
    -- GUIAlienBuyMenu should now be loaded -- commence patching functions
    if (not gabm_patched) and GUIAlienBuyMenu then
        --Print("Patching GUIAlienBuyMenu")
        -- We will extend GUIAlienBuyMenu:SendKeyEvent
        local originalGABMSendKeyEvent = GUIAlienBuyMenu.SendKeyEvent
        function GUIAlienBuyMenu:SendKeyEvent(key, down)
            local stop = false
            if dqb_enabled then
                stop = DQB_Check_Keybinds(self, key, down)
            end

            if not stop then
                stop = originalGABMSendKeyEvent(self, key, down)
            end
            return stop
        end -- GUIAlienBuyMenu:SendKeyEvent

        -- We will extend GUIAlienBuyMenu:_UpdateUpgrades
        local originalGABM_UpdateUpgrades = GUIAlienBuyMenu._UpdateUpgrades
        function GUIAlienBuyMenu:_UpdateUpgrades(deltaTime)
            originalGABM_UpdateUpgrades(self, deltaTime)
            DQB_Update_Button_Labels(self)
        end

        gabm_patched = true
    end -- if not gabm_patched

    originalABOnOpen()
end
