local oldGetTechIdIsInstanced = GetTechIdIsInstanced
local kBiomassResearchInstancedTechIds = {
    [kTechId.ResearchBioMassOne] = true,
    [kTechId.ResearchBioMassTwo] = true,
    [kTechId.ResearchBioMassThree] = true,
}

function GetTechIdIsInstanced(techId)
    if kBiomassResearchInstancedTechIds[techId] then
        return true
    end

    return oldGetTechIdIsInstanced(techId)
end
