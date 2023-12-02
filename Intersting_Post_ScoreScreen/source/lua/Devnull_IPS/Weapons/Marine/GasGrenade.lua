if Server then
    function GasGrenade:OnDestroy()
        StatsUI_RegisterLost(kTechId.GasGrenade, 1)
    end
end
