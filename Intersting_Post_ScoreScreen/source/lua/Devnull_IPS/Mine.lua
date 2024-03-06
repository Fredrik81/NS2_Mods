local orgMineDestroy = Mine.OnDestroy
function Mine:OnDestroy()
    StatsUI_RegisterLost(kTechId.LayMines)
    orgMineDestroy(self)
end

local orgMineOnKill = Mine.OnKill
function Mine:OnKill(attacker, doer, point, direction)
    orgMineOnKill(self, attacker, doer, point, direction)
    if attacker and attacker:isa("Player") then
        local msg = {}
        msg.steamId = attacker:GetSteamId()
        msg.Value = 1
        StatsUI_RegisterTSS("MineKills", msg)
    end
end

function Mine:OnTriggerEntered(entity)
    if self:CheckEntityExplodesMine(entity) then
        if entity:isa("Player") then
            local msg = {}
            msg.steamId = entity:GetSteamId()
            msg.Value = 1
            StatsUI_RegisterTSS("MineKills", msg)
        end
    end
end
