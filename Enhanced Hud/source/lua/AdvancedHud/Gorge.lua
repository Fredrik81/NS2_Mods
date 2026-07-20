-- Keep gorge structure counters fresh even when build weapon is not active.
if Server then
    local kDropStructureAbilityMapName = "drop_structure_ability"
    local kBabblerBombAbilityMapName = "babbler_bomb_ability"
    local kUpdateDelta = 0.5
    local kLastUpdateTime = 0

    local function RefreshDropStructureCounts(gorge)
        if not gorge or not gorge.GetTeam then
            return
        end

        local team = gorge:GetTeam()
        if not team or not team.GetNumDroppedGorgeStructures then
            return
        end

        local dropStructure = gorge:GetWeapon(kDropStructureAbilityMapName)
        if not dropStructure then
            return
        end

        local numAllowedHydras = LookupTechData(kTechId.Hydra, kTechDataMaxAmount, -1)
        local numAllowedClogs = LookupTechData(kTechId.Clog, kTechDataMaxAmount, -1)
        local numAllowedWebs = LookupTechData(kTechId.Web, kTechDataMaxAmount, -1)

        if numAllowedHydras >= 0 then
            dropStructure.numHydrasLeft = team:GetNumDroppedGorgeStructures(gorge, kTechId.Hydra)
        end

        if numAllowedClogs >= 0 then
            dropStructure.numClogsLeft = team:GetNumDroppedGorgeStructures(gorge, kTechId.Clog)
        end

        if numAllowedWebs >= 0 then
            dropStructure.numWebsLeft = team:GetNumDroppedGorgeStructures(gorge, kTechId.Web)
        end
    end

    local oldGorgeOnProcessMove = Gorge.OnProcessMove
    function Gorge:OnProcessMove(input)
        oldGorgeOnProcessMove(self, input)
        if Shared.GetTime() - kLastUpdateTime >= kUpdateDelta then
            RefreshDropStructureCounts(self)
            kLastUpdateTime = Shared.GetTime()
        end
        RefreshDropStructureCounts(self)
    end

    local oldGorgeOnUpdate = Gorge.OnUpdate
    function Gorge:OnUpdate(deltaTime)
        oldGorgeOnUpdate(self, deltaTime)
        if Shared.GetTime() - kLastUpdateTime >= kUpdateDelta then
            RefreshDropStructureCounts(self)
            kLastUpdateTime = Shared.GetTime()
        end
    end
end
