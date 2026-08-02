-- Keep these lists in the same order as the active PlayerInfoEntity source.
-- Bit positions depend on order/content, so even one extra entry shifts decode.
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

local techUpgradesTable = {}
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

EnsureTechUpgradeTablesCurrent()
local oldPlayerInfoEntityUpdateScore = PlayerInfoEntity.UpdateScore

function GetTechIdsFromBitMask(techTable, sort)

    PROFILE("GetTechIdsFromBitMask")

    EnsureTechUpgradeTablesCurrent()

    local techIds = { }
    if sort == nil then
        sort = true
    end
    if techTable and techTable > 0 then
        for _, techId in ipairs(techUpgradesTable) do
            local bitmask = techUpgradesBitmask[techId]
            if bit.band(techTable, bitmask) > 0 then
                table.insert(techIds, techId)
            end
        end
    end

    if sort then
        --Sort the table by bitmask value so it keeps the order established in the original table
        table.sort(techIds, function(a, b) return techUpgradesBitmask[a] < techUpgradesBitmask[b] end)
    end

    return techIds
end

function PlayerInfoEntity:UpdateScore()
    EnsureTechUpgradeTablesCurrent()

    local ret = oldPlayerInfoEntityUpdateScore(self)
    if Server then
        local scorePlayer = Shared.GetEntity(self.playerId)
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
    return ret
end
