--[[
    ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======

    lua\PlayerInfoEntity.lua

    Created by:   Andreas Urwalek(andi@unknownworlds.com)

     Stores information of connected players.

     ========= For more information, visit us at http://www.unknownworlds.com =====================
]]

local clientIndexToSteamId = {}

-- Should be reduced to one TrackedUpgrade once we know what is in new build
local kTrackedTechUpgradeNamesVanilla = {
    "Jetpack",
    "Welder",
    "ClusterGrenade",
    "PulseGrenade",
    "GasGrenade",
    "Mine",
    "Vampirism",
    "Carapace",
    "Regeneration",
    "Aura",
    "Focus",
    "Camouflage",
    "Celerity",
    "Adrenaline",
    "Crush",
    "Parasite",
    "DualMinigunExosuit",
    "DualRailgunExosuit"
}

local kTrackedTechUpgradeNamesCBM = {
    "Jetpack",
    "Welder",
    "ClusterGrenade",
    "PulseGrenade",
    "GasGrenade",
    "ScanGrenade",
    "Mine",
    "Vampirism",
    "__SHELL__",
    "Regeneration",
    "Aura",
    "Focus",
    "Camouflage",
    "Celerity",
    "Adrenaline",
    "Crush",
    "Parasite",
    "DualMinigunExosuit",
    "DualRailgunExosuit"
}

local techUpgradesTable = {} -- will be populated in OnCreate() with the techIds from the tracked tech upgrades
local techUpgradesBitmask = {}
local techUpgradeSignature = ""

local function GetTrackedTechUpgradeNames()
    if kCBMaddon then
        return kTrackedTechUpgradeNamesCBM
    end

    return kTrackedTechUpgradeNamesVanilla
end

local function ResolveTrackedTechName(techName)
    if techName == "__SHELL__" then
        if kTechId.Resilience ~= nil then
            return "Resilience"
        end
        return "Carapace"
    end

    return techName
end

local function RebuildTechUpgradeTables()
    local resolvedTechIds = {}

    for _, trackedTechName in ipairs(GetTrackedTechUpgradeNames()) do
        local techName = ResolveTrackedTechName(trackedTechName)
        local techId = kTechId[techName]
        if techId ~= nil and techId ~= kTechId.None then
            table.insert(resolvedTechIds, techId)
        end
    end

    techUpgradesTable = resolvedTechIds
    techUpgradesBitmask = CreateBitMask(techUpgradesTable)
end

local function BuildTechUpgradeSignature()
    local parts = {}

    for _, trackedTechName in ipairs(GetTrackedTechUpgradeNames()) do
        local techName = ResolveTrackedTechName(trackedTechName)
        table.insert(parts, tostring(kTechId[techName] or -1))
    end

    return table.concat(parts, ":")
end

local function EnsureTechUpgradeTablesCurrent()
    local newSignature = BuildTechUpgradeSignature()
    if techUpgradeSignature ~= newSignature then
        techUpgradeSignature = newSignature
        RebuildTechUpgradeTables()
    end
end

function GetSteamIdForClientIndex(clientIndex)
    return clientIndexToSteamId[clientIndex]
end

class 'PlayerInfoEntity' (Entity)

PlayerInfoEntity.kMapName = "playerinfo"

local networkVars =
{
    -- those are not necessary for this entity
    m_angles = "angles (by 10 [], by 10 [], by 10 [])",
    m_origin = "position (by 2000 [], by 2000 [], by 2000 [])",

    clientId = "entityid",
    steamId = "integer",
    playerId = "entityid",
    playerName = string.format("string (%d)", kMaxNameLength * 4 ),
    teamNumber = string.format("integer (-1 to %d)", kRandomTeamType),
    score = string.format("integer (0 to %d)", kMaxScore),
    kills = string.format("integer (0 to %d)", kMaxKills),
    assists = string.format("integer (0 to %d)", kMaxKills),
    deaths = string.format("integer (0 to %d)", kMaxDeaths),
    resources = string.format("integer (0 to %d)", kMaxPersonalResources),
    isCommander = "boolean",
    isRookie = "boolean",
    status = "enum kPlayerStatus",
    isSpectator = "boolean",
    playerSkill = "integer",
    playerSkillOffset = "integer",
    playerCommSkill = "integer",
    playerCommSkillOffset = "integer",
    adagradSum = "float",
    commAdagradSum = "float",
    playerTDSkill = "integer",
    playerTDSkillOffset = "integer",
    playerTDCommSkill = "integer",
    playerTDCommSkillOffset = "integer",
    playerTDAdagrad = "float",
    playerTDCommAdagrad = "float",
    currentTech = "integer",
    callingCard = "enum kCallingCards",
}

function PlayerInfoEntity:OnCreate()

    Entity.OnCreate(self)

    self:SetUpdates(true, kDefaultUpdateRate)
    self:SetPropagate(Entity.Propagate_Always)

    if Server then

        self.clientId = -1
        self.playerId = Entity.invalidId
        self.status = kPlayerStatus.Void

    end

    self:AddTimedCallback(PlayerInfoEntity.UpdateScore, 0.3)

end

EnsureTechUpgradeTablesCurrent()

function PlayerInfoEntity:UpdateScore()

    if Server then

        local scorePlayer = Shared.GetEntity(self.playerId)

        if scorePlayer then

            self.clientId = scorePlayer:GetClientIndex()
            self.steamId = scorePlayer:GetSteamId()
            self.entityId = scorePlayer:GetId()
            self.playerName = string.UTF8Sub(scorePlayer:GetName(), 0, kMaxNameLength)
            self.teamNumber = scorePlayer:GetTeamNumber()
            self.callingCard = scorePlayer:GetCallingCard()

            local playerSkillOffset, commanderSkill, commanderSkillOffset

            if HasMixin(scorePlayer, "Scoring") then

                self.score = scorePlayer:GetScore()
                self.kills = scorePlayer:GetKills()
                self.assists = scorePlayer:GetAssistKills()
                self.deaths = scorePlayer:GetDeaths()
                self.playerSkill = scorePlayer:GetPlayerSkill()
                self.adagradSum = scorePlayer:GetAdagradSum()
                self.playerSkillOffset = scorePlayer:GetPlayerSkillOffset()
                self.playerCommSkill = scorePlayer:GetCommanderSkill()
                self.playerCommSkillOffset = scorePlayer:GetCommanderSkillOffset()
                self.commAdagradSum = scorePlayer:GetCommanderAdagradSum()

                self.playerTDSkill = scorePlayer:GetTDPlayerSkill()
                self.playerTDSkillOffset = scorePlayer:GetTDPlayerSkillOffset()
                self.playerTDCommSkill = scorePlayer:GetTDPlayerCommanderSkill()
                self.playerTDCommSkillOffset = scorePlayer:GetTDPlayerCommanderSkillOffset()
                self.playerTDAdagrad = scorePlayer:GetTDAdagradSum()
                self.playerTDCommAdagrad = scorePlayer:GetTDCommanderAdagradSum()

                local scoreClient = scorePlayer:GetClient()
                Server.UpdatePlayerInfo( scoreClient, self.playerName, self.score )

            end

            -- Handle Stats
            if self.steamId and self.steamId > 0 then

                StatsUI_MaybeInitClientStats(self.steamId, nil, self.teamNumber)

                if Shared.GetThunderdomeEnabled() then
                    StatsUI_SetBaseClientStatsInfo(self.steamId, self.playerName, self.playerTDSkill, self.playerTDSkillOffset, self.playerTDCommSkill, self.playerTDCommSkillOffset, self.playerTDAdagrad, self.playerTDCommAdagrad, self.isRookie)
                else
                    StatsUI_SetBaseClientStatsInfo(self.steamId, self.playerName, self.playerSkill, self.playerSkillOffset, self.playerCommSkill, self.playerCommSkillOffset, self.adagradSum, self.commAdagradSum, self.isRookie)
                end

            end

            self.resources = scorePlayer:GetResources()
            self.isCommander = scorePlayer:isa("Commander")
            self.isRookie = scorePlayer:GetIsRookie()
            self.status = scorePlayer:GetPlayerStatusDesc()
            self.isSpectator = scorePlayer:isa("Spectator")

            self.reinforcedTierNum = scorePlayer.reinforcedTierNum

            --Always reset this value so we don't have to check for previous tech to remove it, etc
            self.currentTech = 0

            if scorePlayer:isa("Alien") then
                for _, upgrade in ipairs(scorePlayer:GetUpgrades()) do
                    if techUpgradesBitmask[upgrade] then
                        self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[upgrade])
                    end
                end
            elseif scorePlayer:isa("Marine") then
                if scorePlayer:GetIsParasited() then
                    self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[kTechId.Parasite])
                end

                if scorePlayer:isa("JetpackMarine") then
                    self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[kTechId.Jetpack])
                end

                --Mapname to TechId list of displayed weapons
                local displayWeapons = { { Welder.kMapName, kTechId.Welder },
                    { ClusterGrenadeThrower.kMapName, kTechId.ClusterGrenade },
                    { PulseGrenadeThrower.kMapName, kTechId.PulseGrenade },
                    { GasGrenadeThrower.kMapName, kTechId.GasGrenade },
                    { LayMines.kMapName, kTechId.Mine} }

                for _, weapon in ipairs(displayWeapons) do
                    if scorePlayer:GetWeapon(weapon[1]) ~= nil then
                        self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[weapon[2]])
                    end
                end
            end

        else
            DestroyEntity(self)
        end

        if scorePlayer and self.currentTech then
            if scorePlayer:isa("Exo") then
                if scorePlayer:GetHasMinigun() and techUpgradesBitmask[kTechId.DualMinigunExosuit] then
                    self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[kTechId.DualMinigunExosuit])
                elseif scorePlayer:GetHasRailgun() and techUpgradesBitmask[kTechId.DualRailgunExosuit] then
                    self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[kTechId.DualRailgunExosuit])
                end
            end
        end
    end

    clientIndexToSteamId[self.clientId] = self.steamId

    return true

end

if Server then

    function PlayerInfoEntity:SetScorePlayer(player)

        self.playerId = player:GetId()
        self:UpdateScore()

    end

end

function GetTechIdsFromBitMask(techTable)
    EnsureTechUpgradeTablesCurrent()

    local techIds = { }

    if techTable and techTable > 0 then
        for _, techId in ipairs(techUpgradesTable) do
            local bitmask = techUpgradesBitmask[techId]
            if bit.band(techTable, bitmask) > 0 then
                table.insert(techIds, techId)
            end
        end
    end

    --Sort the table by bitmask value so it keeps the order established in the original table
    table.sort(techIds, function(a, b) return techUpgradesBitmask[a] < techUpgradesBitmask[b] end)

    return techIds
end

Shared.LinkClassToMap("PlayerInfoEntity", PlayerInfoEntity.kMapName, networkVars)