

local function OnCommandSelectAllArcs(client)

    local player = client:GetControllingPlayer()
    if player.SelectAllArcs then
        player:SelectAllArcs()
    end
    
end

local function OnCommandSelectAllMacs(client)

    local player = client:GetControllingPlayer()
    if player.SelectAllMacs then
        player:SelectAllMacs()
    end
    
end

local function OnCommandSelectAllObservatory(client)

    local player = client:GetControllingPlayer()
    if player.SelectAllObservatory then
        player:SelectAllObservatory()
    end
    
end
Event.Hook("Console_selectallarcs", OnCommandSelectAllArcs)
Event.Hook("Console_selectallmacs", OnCommandSelectAllMacs)
Event.Hook("Console_selectallobservatory", OnCommandSelectAllObservatory)
