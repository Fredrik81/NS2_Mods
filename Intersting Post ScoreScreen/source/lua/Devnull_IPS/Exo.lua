if Server then
    function Exo:OnKill(attacker, doer, point, direction)
        self.lastExoLayout = {
            layout = self.layout
        }
        if self:GetHasMinigun() then
            StatsUI_RegisterLost(kTechId.DualMinigunExosuit, 1)
        else
            StatsUI_RegisterLost(kTechId.DualRailgunExosuit, 1)
        end

        Player.OnKill(self, attacker, doer, point, direction)

        local activeWeapon = self:GetActiveWeapon()
        if activeWeapon and activeWeapon.OnParentKilled then
            activeWeapon:OnParentKilled(attacker, doer, point, direction)
        end

        self:TriggerEffects("death", {
            classname = self:GetClassName(),
            effecthostcoords = Coords.GetTranslation(self:GetOrigin())
        })

        if self.storedWeaponsIds then
            -- MUST iterate backwards, as "DestroyEntity()" causes the ids to be removed as they're hit.
            for i = #self.storedWeaponsIds, 1, -1 do
                local weaponId = self.storedWeaponsIds[i]
                local weapon = Shared.GetEntity(weaponId)
                if weapon then
                    -- save unused grenades
                    if weapon:isa("GrenadeThrower") and weapon.grenadesLeft > 0 then
                        self.grenadesLeft = weapon.grenadesLeft
                        self.grenadeType = weapon.kMapName
                    elseif weapon:isa("LayMines") and weapon.minesLeft > 0 then
                        self.minesLeft = weapon.minesLeft
                    end

                    DestroyEntity(weapon)
                end
            end
        end
    end
end
