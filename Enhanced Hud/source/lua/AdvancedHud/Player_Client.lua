

function PlayerUI_GetStatusInfoForUnit(player, unit)

    PROFILE("PlayerUI_GetStatusInfoForUnit")

    -- checks here if the model was rendered previous frame as well
    if unit:GetShowUnitStatusFor(player) then

        -- Get direction to blip. If off-screen, don't render. Bad values are generated if
        -- Client.WorldToScreen is called on a point behind the camera.
        local dotProduct, origin, worldOrigin, distance, healthBarOrigin = PlayerUI_GetPositionalInfo(player, unit)

        if dotProduct > 0 then

            local unitState = unit:GetUnitState(player)

            -- we always want to update the most important unit status informations (hp)
            local health = 0
            local armor = 0
            local regen = 0
            local healthArmorString
            local percentageString

            if HasMixin(unit, "Live") and (not unit.GetShowHealthFor or unit:GetShowHealthFor(player)) then

                health = unit:GetHealthFraction()
                armor = unit:GetArmorScalar()

                if HasMixin(unit, "Regeneration") then
                    regen = unit:GetRegenerationFraction()
                end

                if unit:isa("Exo") or unit:isa("Exosuit") then
                    healthArmorString = string.format("%d",math.max(1, math.ceil(unit:GetArmor())))
                else
                    healthArmorString = string.format("%d/%d", math.max(1, math.ceil(unit:GetHealth())), math.ceil(unit:GetArmor()))
                end

                if (unit:GetMapName() ~= TechPoint.kMapName and unit:GetMapName() ~= ResourcePoint.kPointMapName) then

                    if not unit:isa("Player") or (unit:isa("Embryo") and GetAreEnemies(player, unit)) then

                        percentageString = string.format("%d%%", math.max(1, math.ceil(unit:GetHealthScalar()*100)))
                    end
                end

            end

            local losSighted = true
            if HasMixin(unit, "LOS") then
                losSighted = unit:GetIsSighted()
            end

            -- use cached unit state
            if unitState then

                -- update position
                unitState.Position = origin
                unitState.WorldOrigin = worldOrigin
                unitState.HealthBarPosition = healthBarOrigin

                --update most important information
                unitState.HealthFraction = health
                unitState.RegenFraction = regen
                unitState.ArmorFraction = armor
                unitState.HealthAndArmorFraction = healthArmorString
                unitState.HealthAndArmorPercentage = percentageString
                unitState.LOSSighted = losSighted or unitState.IsFriend

                return unitState
            end

            

            local statusFraction = unit:GetUnitStatusFraction(player)
            local description = unit:GetUnitName(player)
            local action = unit:GetActionName(player)
            local hint = unit:GetUnitHint2(player)

            local visibleToPlayer = true
            local isPlayer = unit:isa("Player") and not unit:isa("Embryo")
            local areEnemies = GetAreEnemies(player, unit)
        
            if HasMixin(unit, "Cloakable") and areEnemies then

                if unit:GetIsCloaked() or (isPlayer and unit:GetCloakFraction() > 0.2) then
                    visibleToPlayer = false
                end

            end

            local showsUnitStatusInfo = PlayerUI_ShowsUnitStatusInfo(player, unit)
            if not showsUnitStatusInfo then
                description = ""
                action = ""
                hint = ""
            end

            -- Don't show tech points or nozzles if they are attached
            if visibleToPlayer and (unit:GetMapName() == TechPoint.kMapName or unit:GetMapName() == ResourcePoint.kPointMapName) and unit.GetAttached and (unit:GetAttached() ~= nil) then
                visibleToPlayer = false
            end

            local badgeTextures = {}

            if isPlayer then
                if not unit.GetShowBadgeOverride or unit:GetShowBadgeOverride() then
                    badgeTextures = Badges_GetBadgeTextures(unit:GetClientIndex(), "unitstatus") or {}
                end
            end

            local hasWelder = false
            if distance < 10 then
                hasWelder = unit:GetHasWelder(player)
            end

            local abilityFraction = 0
            
            if player:isa("Commander") then
                abilityFraction = unit:GetAbilityFraction(player)


            end
            
            local maturityFraction = -1
            if HasMixin(unit, "Maturity") and not areEnemies then
                maturityFraction = unit:GetMaturityFraction()
            end

            local crossHairTarget = visibleToPlayer and showsUnitStatusInfo

            local status = unit:GetUnitStatus(player)


            local WeaponColor, clipFractionInWeapon = getWeaponInfo(unit, player) --For WeaponDisplay


            unitState =
            {
                UnitId = unit:GetId(),
                Position = origin,
                WorldOrigin = worldOrigin,
                HealthBarPosition = healthBarOrigin,
                Status = status,
                Name = description,
                Action = action,
                Hint = hint,
                StatusFraction = statusFraction,
                HealthFraction = health,
                RegenFraction = regen,
                ArmorFraction = armor,
                HealthAndArmorFraction = healthArmorString,
                HealthAndArmorPercentage = percentageString,
                IsCrossHairTarget = crossHairTarget,
                TeamType = kNeutralTeamType,
                ForceName = isPlayer and not areEnemies,
                BadgeTextures = badgeTextures,
                HasWelder = hasWelder,
                IsPlayer = isPlayer,
                IsSteamFriend = isPlayer and unit:GetIsSteamFriend() or false,
                AbilityFraction = abilityFraction, -- has total ammo
                IsParasited = HasMixin(unit, "ParasiteAble") and unit:GetIsParasited(),
                CommHealthBarsToggle = visibleToPlayer and player:GetCommHealthBarsShown() and not areEnemies and not unit:isa("Weapon"),
                MaturityFraction = maturityFraction,
                WeaponColor = WeaponColor, -- For WeaponDisplay,  contains a color for the fitting clip weapon, or the string welder
                ClipFractionInWeapon = clipFractionInWeapon, --For WeaponDisplay 
            }

            if unit.GetTeamNumber then
                unitState.IsFriend = (unit:GetTeamNumber() == player:GetTeamNumber())
                unitState.LOSSighted = losSighted or unitState.IsFriend
            else
                unitState.LOSSighted = true
            end

            if unit.GetTeamType then
                unitState.TeamType = unit:GetTeamType()
            end

            

            if isPlayer and unit:isa("Marine") and HasMixin(unit, "WeaponOwner") and not areEnemies then
                local primaryWeapon = unit:GetWeaponInHUDSlot(1)
                if primaryWeapon and primaryWeapon:isa("ClipWeapon") then
                    unitState.PrimaryWeapon = primaryWeapon:GetTechId()
                end
            end

            if unit:isa("InfantryPortal") and unit.timeSpinStarted then
                if unit.queuedPlayerId ~= Entity.invalidId then
                    local playerName = ""
                    for _, playerInfo in ientitylist(Shared.GetEntitiesWithClassname("PlayerInfoEntity")) do
                        if playerInfo.playerId == unit.queuedPlayerId then
                            playerName = playerInfo.playerName
                            break
                        end
                    end

                    unitState.SpawnerName = playerName
                    unitState.SpawnFraction = Clamp((Shared.GetTime() - unit.timeSpinStarted) / kMarineRespawnTime, 0, 1)
                end
            elseif unit:isa("Embryo") then
                unitState.EvolvePercentage = unit.evolvePercentage / 100
                unitState.EvolveClass = unit:GetEggTypeDisplayName()
            elseif unit:isa("Egg") and unit.researchProgress > 0 and unit.researchProgress < 1 then
                unitState.EvolvePercentage = unit.researchProgress
            elseif unit.GetDestinationLocationName then
                unitState.Destination = unit:GetDestinationLocationName()
            elseif unit:isa("Weapon") then
                -- Make super sure that we're hiding this
                unitState.IsCrossHairTarget = false
                unitState.Name = ""
                unitState.HealthFraction = 0
                unitState.ArmorFraction = 0
                unitState.Hint = ""
                -- Only show the AbilityFraction for Marine Commanders
                if player:isa("MarineCommander") and unit.weaponWorldState == true and unit.GetExpireTimeFraction and not unit:isa("Rifle") and not unit:isa("Pistol") then
                    unitState.IsCrossHairTarget = true
                    unitState.AbilityFraction = unit:GetExpireTimeFraction()
                    unitState.IsWorldWeapon = true
                end
               
                    
                    --For WeaponDisplay
                    --Allows Marines to see weapons on the ground
                    if wd_enabled and player:isa("Marine") and unit.weaponWorldState == true and unit.GetExpireTimeFraction and not unit:isa("Rifle") and not unit:isa("Pistol") then
                        unitState.IsCrossHairTarget = true
                        unitState.AbilityFraction = unit:GetExpireTimeFraction()
                        unitState.IsWorldWeapon = true
                    end
                
            end

            if unit.ShowDestinationOverride then
                unitState.ShowDestination = unit:ShowDestinationOverride()
            end

            unit:SetUnitState(player, unitState)

            return unitState
        end
    end

    return nil
end



--For WeaponDisplay

-- case 1: Player is a marine, should be able to see weapons on the ground with fitting colors

-- case 2: Player is the comm, should be able to equipped weapons, doesnt require colors and also see weapons on thte ground with colors

function getWeaponInfo(unit, player)

    local clipFractionInWeapon = false 
    local WeaponColor = false

    -- for weapons on ground
    if (player:isa("Marine") or player:isa("MarineCommander") ) and unit.weaponWorldState == true then 
        WeaponColor = getColorForWeapon(unit)

        if unit:isa("ClipWeapon") then 
            clipFractionInWeapon = unit:GetClipFraction() -- doesnt work for welders
        end
    end

    -- for weapons on marines
    if player:isa("MarineCommander") and (unit:isa("Marine") or unit:isa("Exo")) then
        clipFractionInWeapon = unit:GetAbilityClipFraction(player) -- returns 0 for invalid ones
    end


    return WeaponColor, clipFractionInWeapon
end


function getColorForWeapon(unit)
    local WeaponColor = false
    if unit:isa("ClipWeapon") then 
        if unit:isa("Shotgun") then 
            WeaponColor = Color(0,1,0,1) -- green
        elseif unit:isa("Flamethrower") then 
            WeaponColor = Color(1,1,0,1)  -- yellow
        elseif unit:isa("GrenadeLauncher") then 
            WeaponColor = Color(1,0,1,1) -- magenta
        elseif unit:isa("HeavyMachineGun") then 
            WeaponColor = Color(0.9,0,0,1) -- red
        else
            WeaponColor = Color(0,1,1,1) -- teal
        end 
    elseif unit:isa("Welder") then 
            WeaponColor = Color(1,1,1,1)  -- White, special case later on
            -- we want to show the lifespan bar, but not the clipsize of welders
    end
    return WeaponColor
end