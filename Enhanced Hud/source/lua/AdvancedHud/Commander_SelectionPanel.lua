



function CommanderUI_ClickedSelectAllArcs()
    
    local player = Client.GetLocalPlayer()
    if player and player.SelectAllArcs then
    
        player:SelectAllArcs()   
        Shared.ConsoleCommand("selectallarcs")     
    end
        
end


function CommanderUI_ClickedSelectAllMacs()
    
    local player = Client.GetLocalPlayer()
    if player and player.SelectAllMacs then
    
        player:SelectAllMacs()   
        Shared.ConsoleCommand("selectallmacs")       
    end
        
end


function CommanderUI_ClickedSelectAllObservatory()
    
    local player = Client.GetLocalPlayer()
    if player and player.SelectAllObservatory then
    
        player:SelectAllObservatory()    
        Shared.ConsoleCommand("selectallobservatory")     
    end
        
end