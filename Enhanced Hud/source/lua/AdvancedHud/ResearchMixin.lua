local function GetIsAlienResearchTarget(self)
    return Server and self and self.GetTeamType and self:GetTeamType() == kAlienTeamType
end

local oldResearchMixinSetResearching = ResearchMixin.SetResearching
function ResearchMixin:SetResearching(techNode, player)
    oldResearchMixinSetResearching(self, techNode, player)

    if GetIsAlienResearchTarget(self) then
        local locationName = self.GetLocationName and self:GetLocationName() or ""
        local techId = techNode and techNode.techId or kTechId.None
        Server.SendNetworkMessage("BiomassNotificationLocation", { entityId = self:GetId(), techId = techId, locationName = locationName }, true)
    end
end

local oldResearchMixinClearResearch = ResearchMixin.ClearResearch
function ResearchMixin:ClearResearch()
    oldResearchMixinClearResearch(self)
end
