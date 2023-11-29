local function OnFairStartPing(client, message)
    if Server then
        local player = client:GetControllingPlayer()
        if player then
            local team = player:GetTeam()
            team:SetCommanderPing(message.position)
        end
    end
end

Server.HookNetworkMessage("FairStartPing", OnFairStartPing)
