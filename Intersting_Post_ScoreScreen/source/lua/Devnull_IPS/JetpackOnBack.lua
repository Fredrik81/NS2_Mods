function JetpackOnBack:OnDestroy()
    if Server then
        StatsUI_RegisterLost(kTechId.Jetpack, 1)
    end
    if Client then
        self:DestroyTrails()
    end

    ScriptActor.OnDestroy(self)
end
