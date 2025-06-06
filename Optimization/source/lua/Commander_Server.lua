-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Commander_Server.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--    Optimized by: Devnull
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================
-- At the top of the file
local GetTime = Shared.GetTime
local ipairs = ipairs
local table_insert = table.insert
local table_find = table.find

Script.Load("lua/Globals.lua")

local function SortByEnergy(ent1, ent2)
    return ent1:GetEnergy() > ent2:GetEnergy()
end

function Commander:GetClassHasEnergy(className, energyAmount)

    local foundEntity

    local entities = GetEntitiesForTeam(className, self:GetTeamNumber())
    table.sort(entities, SortByEnergy)

    for _, entity in ipairs(entities) do

        if entity:GetEnergy() >= energyAmount and (not entity.GetIsBuilt or entity:GetIsBuilt()) then
            foundEntity = entity
            break
        end

    end

    return foundEntity

end

function Commander:CheckStructureEnergy()
end

function Commander:OnDestroy()

    Player.OnDestroy(self)
    DeselectAllUnits(self:GetTeamNumber())

end

function Commander:CopyPlayerDataFrom(player) -- TODO segregate out specific Alien & Marine data into their respective classes

    Player.CopyPlayerDataFrom(self, player)
    self:SetIsAlive(player:GetIsAlive())

    self:SetHealth(player.health)
    self:SetMaxHealth(player.maxHealth)
    self:SetMaxArmor(player.maxArmor)

    local commanderStartOrigin = Vector(player:GetOrigin())
    commanderStartOrigin = commanderStartOrigin + player:GetViewOffset()
    self:SetOrigin(commanderStartOrigin)

    self:SetVelocity(Vector(0, 0, 0))

    -- For knowing how to create the player class when leaving commander mode
    self.previousMapName = player:GetMapName()

    -- Save previous weapon name so we can switch back to it when we logout
    self.previousWeaponMapName = ""
    local activeWeapon = player:GetActiveWeapon()
    if (activeWeapon ~= nil) then
        self.previousWeaponMapName = activeWeapon:GetMapName()
    end

    self.previousHealth = player:GetHealth()
    self.previousArmor = player:GetArmor()

    -- Save off alien values
    if player.GetEnergy then
        self.previousAlienEnergy = player:GetEnergy()
    end
    self.timeStartedCommanderMode = GetTime()

    self.oneHive = player.oneHive
    self.twoHives = player.twoHives
    self.threeHives = player.threeHives

    if player:isa("Alien") then
        self.tierOneTechId = player:GetTierOneTechId()
        self.tierTwoTechId = player:GetTierTwoTechId()
        self.tierThreeTechId = player:GetTierThreeTechId()
    end

end

--
-- Commanders cannot take damage.
--
function Commander:GetCanTakeDamageOverride()
    return false
end

function Commander:GetCanDieOverride()
    return false
end

function Commander:AttemptToResearchOrUpgrade(techNode, entity)

    -- research is only allowed for single selection
    if techNode:GetIsResearch() and not self.isBotRequestedAction then

        local selection = self:GetSelection()

        if #selection == 1 then
            entity = selection[1]
        else
            return false
        end

    end

    -- Don't allow it to be researched while researching.
    if entity and HasMixin(entity, "Research") then

        if (techNode:GetCanResearch() or techNode:GetIsManufacture()) and entity:GetCanResearch(techNode:GetTechId()) then

            if self:GetTechTree():GetNumberOfQueuedResearch() == 0 then

                entity:SetResearching(techNode, self)

                if not techNode:GetIsEnergyManufacture() and not techNode:GetIsPlasmaManufacture() then
                    techNode:SetResearching()
                end

                self:GetTechTree():SetTechNodeChanged(techNode, "researching")

                return true

            end

        end

    end

    return false

end

-- TODO: Add parameters for energy or resources
function Commander:TriggerNotEnoughResourcesAlert()

    local team = self:GetTeam()
    local alertType = ConditionalValue(team:GetTeamType() == kMarineTeamType, kTechId.MarineAlertNotEnoughResources,
        kTechId.AlienAlertNotEnoughResources)
    local commandStructure = Shared.GetEntity(self.commandStationId)
    team:TriggerAlert(alertType, commandStructure)

end

function Commander:GetSpendResourcesSoundName()
    return Commander.kSpendResourcesSoundName
end

function Commander:GetSpendTeamResourcesSoundName()
    return Commander.kSpendTeamResourcesSoundName
end

-- Return whether action should continue to be processed for the next selected unit. Position will be nil
-- for non-targeted actions and will be the world position target for the action for targeted actions.
-- targetId is the entityId which was hit by the client side trace
function Commander:ProcessTechTreeActionForEntity(techNode, position, normal, isCommanderPicked, orientation, entity,
    trace)

    local success = false
    local keepProcessing = true

    -- First make sure tech is allowed for entity
    local techId = techNode:GetTechId()

    if not self.currentMenu then
        self.currentMenu = kCommanderDefaultMenu
    end

    local techButtons = self:GetCurrentTechButtons(self.currentMenu, entity)

    -- For bots, do not worry about which menu is active
    if not self.isBotRequestedAction then
        if techButtons == nil or table_find(techButtons, techId) == nil then
            return success, keepProcessing
        end
    end

    -- TODO: check if this really works fine. the entity should check here if something is allowed / can be afforded.
    -- if no entity is selected this check is not necessary, the commander already performed the check
    if entity then
        local allowed, canAfford = entity:GetTechAllowed(techId, techNode, self)

        if not allowed or not canAfford then
            -- no succes, but continue (can afford revers maybe to a unit specific resource type which is maybe affordable at another selected unit)
            return false, true
        end
    end

    -- Cost is in team resources, energy or individual resources, depending on tech node type
    local cost = GetCostForTech(techId)
    local team = self:GetTeam()
    local teamResources = team:GetTeamResources()

    -- Let entities override actions themselves (eg, so buildbots can execute a move-build order instead of building structure immediately)
    if entity then
        success, keepProcessing = entity:OverrideTechTreeAction(techNode, position, orientation, self, trace)
    end

    if success then
        return success, keepProcessing
    end

    -- Handle tech tree actions that cost team resources
    if techNode:GetIsResearch() or techNode:GetIsUpgrade() or techNode:GetIsBuild() or techNode:GetIsEnergyBuild() or
        techNode:GetIsEnergyManufacture() or techNode:GetIsManufacture() then

        local costsEnergy = techNode:GetIsEnergyBuild() or techNode:GetIsEnergyManufacture()

        local energy = 0
        if entity and HasMixin(entity, "Energy") then
            energy = entity:GetEnergy()
        end

        local resourcesValid = (not costsEnergy and cost <= teamResources) or (costsEnergy and cost <= energy)
        local researchAllowed = true
        local researchErrorMessage
        local method = LookupTechData(techNode:GetTechId(), kTechDataResearchAllowedMethod)
        if method then
            researchAllowed, researchErrorMessage = method(techNode:GetTechId(), entity and entity:GetOrigin())
        end

        if resourcesValid and researchAllowed then

            if techNode:GetIsResearch() or techNode:GetIsUpgrade() or techNode:GetIsEnergyManufacture() or
                techNode:GetIsManufacture() then

                success = self:AttemptToResearchOrUpgrade(techNode, entity)
                if success and techNode:GetIsResearch() then
                    keepProcessing = false
                end

            elseif techNode:GetIsBuild() or techNode:GetIsEnergyBuild() then

                success = self:AttemptToBuild(techId, position, normal, orientation, isCommanderPicked, false, entity)
                if success then
                    keepProcessing = false
                end

            end

            if success then

                if costsEnergy and entity and HasMixin(entity, "Energy") then
                    entity:SetEnergy(entity:GetEnergy() - cost)
                else
                    team:AddTeamResources(-cost)
                end

                position = entity and entity:GetOrigin() or position

            end

        else

            if not resourcesValid then
                self:TriggerNotEnoughResourcesAlert()

            elseif not researchAllowed then
                local message = BuildCommanderErrorMessage(researchErrorMessage,
                    entity and entity:GetOrigin() or position)
                Server.SendNetworkMessage(self, "CommanderError", message, true)
            end

        end

        -- Handle resources-based abilities
    elseif techNode:GetIsAction() or techNode:GetIsBuy() or techNode:GetIsPlasmaManufacture() then

        local playerResources = self:GetResources()
        if (cost == nil or cost <= playerResources) then

            if (techNode:GetIsAction()) then
                success = entity:PerformAction(techNode, position)
            elseif (techNode:GetIsBuy()) then
                success = self:AttemptToBuild(techId, position, normal, orientation, isCommanderPicked, false)
            elseif (techNode:GetIsPlasmaManufacture()) then
                success = self:AttemptToResearchOrUpgrade(techNode, entity)
            end

            if (success and cost ~= nil) then

                self:AddResources(-cost)
                Shared.PlayPrivateSound(self, self:GetSpendResourcesSoundName(), nil, 1.0, self:GetOrigin())

            end

        else
            self:TriggerNotEnoughResourcesAlert()
        end

    elseif techNode:GetIsActivation() then

        -- Deduct energy cost if any
        if cost == 0 or cost <= teamResources then

            success, keepProcessing = entity:PerformActivation(techId, position, normal, self)

            if success and cost ~= 0 then
                team:AddTeamResources(-cost)
            end

        else

            self:TriggerNotEnoughResourcesAlert()

        end

    end

    if techNode:GetResourceType() == kResourceType.Team then
        Shared.PlayPrivateSound(self, self:GetSpendTeamResourcesSoundName(), nil, 1.0, self:GetOrigin())
    end

    return success, keepProcessing

end

-- @return a list of at most @number Vector(x,y,z) spreading around a given @orig point
-- If it can't find any placement, the list still contains at least the original given point
local function Commander_PrePlaceBuildings(orig, number)
    local extents = Vector(0.2, 0.2, 0.2)
    local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
    local prePlaceOrig = {orig + Vector(0, 1, 0)} -- Pre-calculate this
    number = number or 1

    -- Pre-calculate constants
    local minRange = 0.75
    local maxRangeMultiplier = 1.10
    local maxRange = 1.5

    for i = 1, number do
        for index = 1, 5 do
            local usedOrig = prePlaceOrig[math.random(1, #prePlaceOrig)]
            local position = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, usedOrig, minRange, maxRange,
                EntityFilterAll())

            if position then
                local success = true
                local locationOrig = GetLocationForPoint(orig)

                -- Use break condition instead of success flag
                for _, existingPos in ipairs(prePlaceOrig) do
                    if position:GetDistanceTo(existingPos) < minRange and locationOrig and locationOrig ==
                        GetLocationForPoint(position) then
                        success = false
                        break
                    end
                end

                if success then
                    table_insert(prePlaceOrig, position)
                    break
                end
            end

            maxRange = maxRange * maxRangeMultiplier
        end
    end

    return prePlaceOrig
end

-- Send techId of action and normalized pick vector. Issues order to selected units to the world position represented by
-- the pick vector, or to the entity that it hits.
function Commander:OrderEntities(orderTechId, trace, orientation, targetId, shiftDown)

    local invalid = false

    if not targetId then
        targetId = Entity.invalidId
    end

    if targetId == Entity.invalidId and trace.entity then
        targetId = trace.entity:GetId()
    end

    if trace.fraction < 1 then

        -- Give order to selection
        local orderEntities = self:GetSelection()
        local orderTechIdGiven = orderTechId
        local origPlaces = #orderEntities > 1 and
                               Commander_PrePlaceBuildings(trace.endPoint, math.min(15, #orderEntities)) or
                               {trace.endPoint}

        for tableIndex, entity in ipairs(orderEntities) do

            if HasMixin(entity, "Orders") then

                local orig = (origPlaces and #origPlaces > 0) and origPlaces[(tableIndex % #origPlaces) + 1] or
                                 trace.endPoint
                local type = entity:GiveOrder(orderTechId, targetId, orig, orientation, not shiftDown, false)

                if type == kTechId.None then
                    invalid = true
                end

            else
                invalid = true
            end

        end

        self:OnOrderEntities(orderTechIdGiven, orderEntities)

    end

    if invalid then
        self:TriggerInvalidSound()
    end

end

function Commander:OnOrderEntities(orderTechId, orderEntities)
end

local function HasEnemiesSelected(self)

    for _, unit in ipairs(self:GetSelection()) do
        if unit:GetTeamNumber() ~= self:GetTeamNumber() then
            return true
        end
    end

    return false

end

-- Takes a techId as the action type and normalized screen coords for the position. normPickVec will be nil
-- for non-targeted actions.
function Commander:ProcessTechTreeAction(techId, pickVec, orientation, worldCoordsSpecified, targetId, shiftDown)
    -- Early returns for common failure cases
    if HasEnemiesSelected(self) then
        return false
    end

    local techNode = self:GetTechTree():GetTechNode(techId)
    if not techNode then
        return false
    end

    if self:GetIsTechOnCooldown(techId) then
        self:TriggerInvalidSound()
        return false
    end

    -- Cache commonly accessed values
    local team = self:GetTeam()
    local cost = techNode:GetCost()
    local resourceType = techNode:GetResourceType()

    -- Resource validation
    if resourceType == kResourceType.Team then
        if team:GetTeamResources() < cost then
            self:TriggerInvalidSound()
            return false
        end
    elseif resourceType == kResourceType.Personal and self:GetResources() < cost then
        self:TriggerInvalidSound()
        return false
    end

    self.shiftDown = shiftDown

    local success = false
    local techNode = self:GetTechTree():GetTechNode(techId)
    local techNodeIsAvailable = techNode ~= nil and techNode.available;
    local techNodeIsMenu = techNodeIsAvailable and techNode:GetIsMenu()

    if techNodeIsMenu then
        self.currentMenu = techId
    end

    local techNode = self:GetTechTree():GetTechNode(techId)

    -- check supply
    local requiredSupply = LookupTechData(techId, kTechDataSupply, 0)
    local teamNumber = self:GetTeamNumber()
    if requiredSupply > 0 and GetSupplyUsedByTeam(teamNumber) + requiredSupply > GetMaxSupplyForTeam(teamNumber) then
        self:TriggerInvalidSound()
        return false
    end

    local techNodeIsAction = techNodeIsAvailable and not techNode:GetIsMenu()
    if techNodeIsAction then

        -- Trace along pick vector to find world position of action
        local targetPosition = Vector(0, 0, 0)
        local targetNormal = Vector(0, 1, 0)
        local trace
        if pickVec ~= nil then

            trace = GetCommanderPickTarget(self, pickVec, worldCoordsSpecified, techNode:GetIsBuild(),
                LookupTechData(techNode.techId, kTechDataCollideWithWorldOnly, false))
            if trace ~= nil and trace.fraction < 1 then

                VectorCopy(trace.endPoint, targetPosition)
                VectorCopy(trace.normal, targetNormal)

            end

        end

        -- If techNode is a menu, remember it so we can validate actions
        if techNode:GetIsOrder() then
            self:OrderEntities(techId, trace, orientation, targetId, shiftDown)
        else

            local sortedList = {}
            for index, entity in ipairs(self:GetSelection()) do
                table_insert(sortedList, entity)
            end

            if pickVec == nil then

                -- If there is no valid target position to sort by, instead sort based on how close
                -- to the center of the screen each entity appears.
                SortEntitiesBasedOn2DXYDistance(self:GetViewCoords(), sortedList)

            else

                -- Sort the selected group based on distance to the target position.
                -- This means the closest entity to the target position will be given
                -- the order first and in some cases this will be the only entity to be
                -- given the order.

                Shared.SortEntitiesByDistance(targetPosition, sortedList)

            end

            if #sortedList > 0 then

                -- For every selected entity, process this desired action. For some actions (research), only
                -- process once, not on every entity.
                for index, selectedEntity in ipairs(sortedList) do

                    local actionSuccess = false
                    local keepProcessing = false
                    actionSuccess, keepProcessing = self:ProcessTechTreeActionForEntity(techNode, targetPosition,
                        targetNormal, pickVec ~= nil, orientation, selectedEntity, trace, targetId)

                    -- Successful if just one of our entities handled action
                    if actionSuccess then
                        success = true

                        -- Stop processing if the tech should only ever be processed one-at-a-time.
                        if LookupTechData(techNode.techId, kTechDataOneAtATime, false) then
                            keepProcessing = false
                        end
                    end

                    if not keepProcessing then
                        break
                    end

                end

            else
                success = self:ProcessTechTreeActionForEntity(techNode, targetPosition, targetNormal, pickVec ~= nil,
                    orientation, nil, trace, targetId)
            end

        end

    end

    if success then

        local cooldown = LookupTechData(techId, kTechDataCooldown, 0)
        if cooldown ~= 0 then
            self:SetTechCooldown(techId, cooldown, GetTime())
        end

        -- inform the team
        self:GetTeam():OnCommanderAction(techId)
    end

    -- Tell client result of cast
    local msg = BuildAbilityResultMessage(techId, success, GetTime())
    Server.SendNetworkMessage(self, "AbilityResult", msg, false)

    return success

end

function Commander:GetSelectionHasOrder(orderEntity)

    for _, entity in ipairs(self:GetSelection()) do

        if entity and entity.GetHasSpecifiedOrder and entity:GetHasSpecifiedOrder(orderEntity) then
            return true
        end

    end

    return false

end

function Commander:GiveOrderToSelection(orderType, targetId)
end

function Commander:SetEntitiesHotkeyState(group, state)

    if Server then

        for index, entity in ipairs(group) do

            if entity ~= nil then
                entity:SetIsHotgrouped(state)
            end

        end

    end

end

-- Send data to client because it changed
function Commander:SendHotkeyGroup(number)

    local hotgroupCommand = string.format("hotgroup %d ", number)

    for j = 1, table.count(self.hotkeyGroups[number]) do

        -- Need underscore between numbers so all ids are sent in one string
        hotgroupCommand = hotgroupCommand .. self.hotkeyGroups[number][j] .. "_"

    end

    Server.SendCommand(self, hotgroupCommand)

    return hotgroupCommand

end

function Commander:GetIsEntityIdleWorker(entity)
    local className = ConditionalValue(self:isa("AlienCommander"), "Drifter", "MAC")
    return entity:isa(className) and not entity:GetHasOrder()
end

function Commander:GetIdleWorkers()
    local className = self:isa("AlienCommander") and "Drifter" or "MAC"
    local workers = GetEntitiesForTeam(className, self:GetTeamNumber())
    local idleWorkers = {}

    -- Pre-allocate approximate size
    local size = #workers
    for i = 1, size do
        local worker = workers[i]
        if not worker:GetHasOrder() then
            idleWorkers[#idleWorkers + 1] = worker
        end
    end

    return idleWorkers
end

function Commander:UpdateNumIdleWorkers()
    if self.lastTimeUpdatedIdleWorkers == nil or (GetTime() > self.lastTimeUpdatedIdleWorkers + 1) then
        self.numIdleWorkers = Clamp(table.icount(self:GetIdleWorkers()), 0, kMaxIdleWorkers)
        self.lastTimeUpdatedIdleWorkers = GetTime()
    end
end

function Commander:GetIsInterestedInAlert(techId)
    return true
end

function Commander:GotoIdleWorker()
    local success = false

    local workers = self:GetIdleWorkers()
    local numWorkers = table.icount(workers)

    if numWorkers > 0 then

        if numWorkers == 1 or self.lastGotoIdleWorker == nil then

            self.lastGotoIdleWorker = workers[1]

            success = true

        else

            local index = table_find(workers, self.lastGotoIdleWorker)

            if index ~= nil then

                local newIndex = ConditionalValue(index == table.count(workers), 1, index + 1)

                if newIndex ~= index then

                    self.lastGotoIdleWorker = workers[newIndex]
                    success = true

                else

                    -- reset to the first idle worker since lastGotoIdleWorker is no longer idle or no longer exists
                    self.lastGotoIdleWorker = workers[1]
                    success = true

                end

            end

        end

    end

    if success then

        -- Select and goto self.lastGotoIdleWorker
        DeselectAllUnits(self:GetTeamNumber())
        self.lastGotoIdleWorker:SetSelected(self:GetTeamNumber(), true)
        Server.SendNetworkMessage(self, "SelectAndGoto", BuildSelectAndGotoMessage(self.lastGotoIdleWorker:GetId()),
            true)

    end

end

function Commander:GotoPlayerAlert()

    for index, triple in ipairs(self.alerts) do

        local alertType = LookupTechData(triple[1], kTechDataAlertType, nil)

        if alertType == kAlertType.Request then

            self.lastTimeUpdatedPlayerAlerts = nil

            local playerAlertId = triple[2]
            local player = Shared.GetEntity(playerAlertId)

            if player then

                table.remove(self.alerts, index)

                DeselectAllUnits(self:GetTeamNumber())
                player:SetSelected(self:GetTeamNumber(), true, true)
                Server.SendNetworkMessage(self, "SelectAndGoto", BuildSelectAndGotoMessage(playerAlertId), true)

                return true

            end

        end

    end

    return false

end

function Commander:Logout()

    local commandStructure = Shared.GetEntity(self.commandStationId)
    return commandStructure.Logout and commandStructure:Logout()

end

--
-- Force player out of command station or hive.
--
function Commander:Eject()

    -- Get data before we create new player.
    local teamNumber = self:GetTeamNumber()
    local userId = Server.GetOwner(self):GetUserId()

    self:Logout()

    if self:GetIsVirtual() then
        -- remove commander bot when ejected from the chair
        GetGamerules().botTeamController:RemoveCommanderBot(teamNumber)
    end

    -- Tell all players on team about this.
    local team = GetGamerules():GetTeam(teamNumber)
    if team:GetTeamType() == kMarineTeamType then
        team:TriggerAlert(kTechId.MarineCommanderEjected, self)
    else
        team:TriggerAlert(kTechId.AlienCommanderEjected, self)
    end

    -- Add player to list of players that can no longer command on this server (until brought down).
    GetGamerules():BanPlayerFromCommand(userId)

    -- Notify the team.
    SendTeamMessage(team, kTeamMessageTypes.Eject)

end

function Commander:SetCommandStructure(commandStructure)
    assert(commandStructure:isa("CommandStructure"))

    self.commandStationId = commandStructure:GetId()
end

