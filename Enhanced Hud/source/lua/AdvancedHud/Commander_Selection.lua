
function Commander:SelectAllArcs()

    DeselectAllUnits(self:GetTeamNumber(), true)    
    for _, unit in ipairs(GetEntitiesWithMixinForTeam("Selectable", self:GetTeamNumber())) do
        unit:SetSelected(self:GetTeamNumber(), unit:isa("ARC"))
    end
    
end

function Commander:SelectAllMacs()

    DeselectAllUnits(self:GetTeamNumber(), true)    
    for _, unit in ipairs(GetEntitiesWithMixinForTeam("Selectable", self:GetTeamNumber())) do
        unit:SetSelected(self:GetTeamNumber(), unit:isa("MAC"))
    end
    
end

function Commander:SelectAllObservatory()

    DeselectAllUnits(self:GetTeamNumber(), true)    
    for _, unit in ipairs(GetEntitiesWithMixinForTeam("Selectable", self:GetTeamNumber())) do
        unit:SetSelected(self:GetTeamNumber(), unit:isa("Observatory"))
    end
    
end