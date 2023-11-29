local orgLiveMixinAddHealth = LiveMixin.AddHealth
-- Return the amount of health we added
function LiveMixin:AddHealth(health, playSound, noArmor, hideEffect, healer, useEHP)
    local isHealed = orgLiveMixinAddHealth(self, health, playSound, noArmor, hideEffect, healer, useEHP)

    if isHealed <= 0 then
        return isHealed
    elseif not (healer and healer:isa("Gorge") and healer ~= self and healer:isa("Player")) then
        return isHealed
    end

    --Check if healed and from a gorge...
    if self:isa("Alien") then
        local msg = {}
        msg.steamId = healer:GetSteamId()
        msg.Value = isHealed
        StatsUI_RegisterTSS("GorgeHealPlayer", msg)
    elseif not (self:isa("Cyst") or self:isa("Hydra")) then
        local msg = {}
        msg.steamId = healer:GetSteamId()
        msg.Value = isHealed
        StatsUI_RegisterTSS("GorgeHealStruct", msg)
    end

    return isHealed
end

local orgLiveMixinTakeDamage = LiveMixin.TakeDamage
function LiveMixin:TakeDamage(damage, attacker, doer, point, direction, armorUsed, healthUsed, damageType, preventAlert)
    local killedFromDmg, damageTaken = orgLiveMixinTakeDamage(self, damage, attacker, doer, point, direction, armorUsed, healthUsed, damageType, preventAlert)

    --debug
    --[[
    if damageTaken and attacker then
        local attackerSteamId, attackerWeapon, attackerTeam = StatsUI_GetAttackerWeapon(attacker, doer)
        print("HasSecondary: " .. tostring(doer.secondaryAttacking))
        print("attack: " .. tostring(EnumToString(kTechId, attackerWeapon)))
        print("- SteamID: " .. tostring(attackerSteamId))
        print("Weapon: " .. tostring(attackerWeapon))
        print("DamageType: " .. tostring(damageType))
        if (doer and attackerWeapon == kTechId.Rifle and doer.secondaryAttacking) then
            print("Butt...")
        end
    end
    ]]

    if damageTaken and attacker and attacker:isa("Player") and not self:isa("Hallucination") then
        --RT tower dmg stats
        if damageTaken > 0 and self:isa("ResourceTower") then
            local msg = {}
            msg.steamId = attacker:GetSteamId()
            msg.Value = damageTaken
            if attacker:GetTeamNumber() == 1 then
                StatsUI_RegisterTSS("marineRtDamage", msg)
            elseif attacker:GetTeamNumber() == 2 then
                StatsUI_RegisterTSS("alienRtDamage", msg)
            end
        end

        --Special weapon kills
        if killedFromDmg and doer and (self:isa("Alien") or self:isa("Marine")) then
            local attackerSteamId, attackerWeapon, attackerTeam = StatsUI_GetAttackerWeapon(attacker, doer)
            if attackerWeapon == kTechId.Welder or attackerWeapon == kTechId.Axe or attackerWeapon == kTechId.ClusterGrenade or attackerWeapon == kTechId.PulseGrenade or (doer and attackerWeapon == kTechId.Rifle and doer.secondaryAttacking) then
                local msg = {}
                msg.steamId = attackerSteamId
                msg.Value = 1
                StatsUI_RegisterTSS("marineSpecialKill", msg)
            elseif attackerWeapon == kTechId.Parasite or attackerWeapon == kTechId.Babbler or attackerWeapon == kTechId.Spray then
                local msg = {}
                msg.steamId = attackerSteamId
                msg.Value = 1
                StatsUI_RegisterTSS("alienSpecialKill", msg)
            end
        end
    end

    return killedFromDmg, damageTaken
end
