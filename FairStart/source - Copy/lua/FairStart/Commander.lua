if Client then
    Script.Load("lua/TeamMessageMixin.lua")
    local player = Client.GetLocalPlayer()
    print("===== loaded TeamMessageMixin")
    if player then
        print("=== Got player...")
        if player:GetTeamNumber() == 1 then
            print("===== loaded Marine Layout")
            InitMixin(player, TeamMessageMixin, { kGUIScriptName = "GUIMarineTeamMessage" })
        elseif player:GetTeamNumber() == 2 then
            print("===== loaded Alien Layout")
            InitMixin(player, TeamMessageMixin, { kGUIScriptName = "GUIAlienTeamMessage" })
        end
    else
        print("==== No player...")
    end
end
