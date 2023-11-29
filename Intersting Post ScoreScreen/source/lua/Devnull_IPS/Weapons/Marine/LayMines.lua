local orgLayMinesPerformPrimaryAttack = LayMines.PerformPrimaryAttack
function LayMines:PerformPrimaryAttack(player)
    local success = orgLayMinesPerformPrimaryAttack(self, player)
    if success then
        if player:isa("Player") then
            local msg = {}
            msg.steamId = player:GetSteamId()
            msg.Value = 1
            StatsUI_RegisterTSS("MineDrops", msg)
        end
    end
    return success
end
