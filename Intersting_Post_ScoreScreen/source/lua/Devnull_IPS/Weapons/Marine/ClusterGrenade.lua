if Server then
    function ClusterGrenade:OnDestroy()
        StatsUI_RegisterLost(kTechId.ClusterGrenade, 1)
    end
end
