local Plugin = ...

local kNameplateStatusIcons = PrecacheAsset("ui/Devnull-ShineExtras/nameplate_icons.dds")
local validMarineAlerts = {kTechId.MarineAlertNeedAmmo, kTechId.MarineAlertNeedMedpack}
local playerAlerts = {}
local alertTTL = 5 -- seconds

local function dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            s = s .. "[" .. k .. "] = " .. dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

function Plugin:newAlert(retObject, text, iconXOffset, iconYOffset, entityId, mapX, mapZ)
    local player = Client.GetLocalPlayer()
    if not player or not (player and player:isa("MarineCommander")) then
        return
    end

    if not entityId then
        return
    end

    if not playerAlerts[entityId] then
        playerAlerts[entityId] = {}
    end

    if text == GetDisplayNameForAlert(kTechId.MarineAlertNeedAmmo, "") then
        playerAlerts[entityId].ammo = Shared.GetTime()
    elseif text == GetDisplayNameForAlert(kTechId.MarineAlertNeedMedpack, "") then
        playerAlerts[entityId].med = Shared.GetTime()
    end
end

function Plugin:Initialise()
    self.Enabled = true

    HPrint(Plugin.PrintName .. ", version " .. Plugin.Version .. " loaded.")
    -- Shine.Hook.SetupClassHook("GUIUnitStatus", "UpdateUnitStatusBlip", "mapBlipUpdates", "PassivePost")

    Plugin:CreateHooks()

    -- Alert hook
    Shine.Hook.SetupClassHook("GUICommanderAlerts", "AddMessage", "newAlert", "PassivePost")

    return true
end

local function AddNameplateStatusIcon(self, blipObject)
    -- Sanity check
    if not blipObject then
        return
    end

    if not blipObject.statusBg then
        return
    end

    if not blipObject.statusIcon then
        blipObject.statusIcon = GUIManager:CreateGraphicItem()
        blipObject.statusIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
        blipObject.statusIcon:SetSize(Vector(20, 20, 0) * GUIScoreboard.kScalingFactor)
        blipObject.statusIcon:SetPosition(Vector(-20, 4, 0))
        blipObject.statusIcon:SetTexture(kNameplateStatusIcons)
        blipObject.statusIcon:SetTexturePixelCoordinates({0, 0, 64, 64})
        blipObject.statusIcon:SetIsVisible(false)
        blipObject.statusBg:AddChild(blipObject.statusIcon)
    end
end

function Plugin:CreateHooks()
    local plugin = self

    local oldUpdate = GUIUnitStatus.UpdateUnitStatusBlip
    function GUIUnitStatus:UpdateUnitStatusBlip(blipIndex, localPlayerIsCommander, baseResearchRot, showHints,
        playerTeamType)
        oldUpdate(self, blipIndex, localPlayerIsCommander, baseResearchRot, showHints, playerTeamType)

        --[[ -- Check if player is spectator
        local player = Client.GetLocalPlayer()
        local isSpectator = false
        if player and player:isa("Spectator") then
            isSpectator = true
        end ]]

        local updateBlip = self.activeBlipList[blipIndex]

        if not localPlayerIsCommander then
            if updateBlip.statusIcon then
                updateBlip.statusIcon:SetIsVisible(false)
            end
            return
        end

        local blipData = self.activeStatusInfo[blipIndex]
        if blipData and not (blipData.IsPlayer or blipData.IsPlayer) then
            if updateBlip.statusIcon then
                updateBlip.statusIcon:SetIsVisible(false)
            end
            return
        end

        --[[ print("localPlayerIsCommander: " .. tostring(localPlayerIsCommander))
        print("blipIndex: " .. tostring(blipIndex))
        print("showHints: " .. tostring(showHints))
        print("playerTeamType: " .. tostring(playerTeamType))
        print("blipData: " .. dump(self.activeStatusInfo[blipIndex]))
        print("updateBlip: " .. dump(self.activeBlipList[blipIndex]))
        print("=========================") ]]

        if blipData.HealthFraction and blipData.HealthFraction < 0.8 then
            updateBlip.HealthBar:SetColor(Color(1, blipData.HealthFraction, blipData.HealthFraction, 1))
        end

        -- Check if we should display an alert icon
        if blipData.UnitId and playerAlerts[blipData.UnitId] then
            -- Add icon if missing
            AddNameplateStatusIcon(self, updateBlip)

            local alertInfo = playerAlerts[blipData.UnitId]
            -- first if both ammo and med active
            if updateBlip.statusBg:GetIsVisible() ~= true then
                updateBlip.statusIcon:SetIsVisible(false)
			elseif alertInfo.ammo and alertInfo.med and (Shared.GetTime() - alertInfo.ammo) < alertTTL and (Shared.GetTime() - alertInfo.med) < alertTTL then
				-- Show both icon
				updateBlip.statusIcon:SetTexturePixelCoordinates({0, 126, 64, 192})
				updateBlip.statusIcon:SetIsVisible(true)
			elseif (alertInfo.ammo and Shared.GetTime() - alertInfo.ammo < alertTTL) then
				-- Show ammo icon
				updateBlip.statusIcon:SetTexturePixelCoordinates({0, 64, 64, 128})
				updateBlip.statusIcon:SetIsVisible(true)
			elseif (alertInfo.med and Shared.GetTime() - alertInfo.med < alertTTL) then
				-- Show med icon
				updateBlip.statusIcon:SetTexturePixelCoordinates({0, 0, 64, 64})
				updateBlip.statusIcon:SetIsVisible(true)
			else
				updateBlip.statusIcon:SetIsVisible(false)
			end --]]
        elseif updateBlip.statusIcon then
            updateBlip.statusIcon:SetIsVisible(false)
        end
    end
end

function Plugin:Cleanup()
    self.BaseClass.Cleanup(self)

    self.Enabled = false
end
