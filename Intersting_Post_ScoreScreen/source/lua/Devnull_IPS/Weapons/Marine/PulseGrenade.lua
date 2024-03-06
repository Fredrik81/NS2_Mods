if Server then
    function PulseGrenade:OnDestroy()
        StatsUI_RegisterLost(kTechId.PulseGrenade)
    end
end