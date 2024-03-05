if Server then
    function ClusterGrenade:OnDestroy()
        StatsUI_RegisterLost(kTechId.ClusterGrenade)
    end
end
