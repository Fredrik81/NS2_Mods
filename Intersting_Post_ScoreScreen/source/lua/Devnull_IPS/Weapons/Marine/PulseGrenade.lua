if Server then
    function PulseGrenade:OnDestroy()
        StatsUI_RegisterLost(kTechId.PulseGrenade, 1)
    end
end