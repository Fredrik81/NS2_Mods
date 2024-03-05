if Server then
    function GasGrenade:OnDestroy()
        StatsUI_RegisterLost(kTechId.GasGrenade)
    end
end
