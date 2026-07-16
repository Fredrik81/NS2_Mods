


function UnitStatusMixin:GetAbilityClipFraction(forEntity)

    if HasMixin(self, "WeaponOwner") then

        if GetAreEnemies(forEntity, self) then
            return 0
        end

        local primaryWeapon = self:GetWeaponInHUDSlot(1)
        if primaryWeapon and primaryWeapon:isa("ClipWeapon") then
            -- always show at least 1% so commander would see a black bar
            return math.max(0.01, primaryWeapon:GetClipFraction())
        end

        if self:isa("Exo") then 
            local activeWeapon = self:GetActiveWeapon()
            local exoWeaponFraction = 0

            if activeWeapon and activeWeapon:isa("ExoWeaponHolder") then
                local leftWeapon = Shared.GetEntity(activeWeapon.leftWeaponId)
                local rightWeapon = Shared.GetEntity(activeWeapon.rightWeaponId)

                if rightWeapon:isa("Railgun") then
                    exoWeaponFraction = rightWeapon:GetChargeAmount()
                    if leftWeapon:isa("Railgun") then
                        exoWeaponFraction = (exoWeaponFraction + leftWeapon:GetChargeAmount()) / 2.0
                    end
                elseif rightWeapon:isa("Minigun") then
                    exoWeaponFraction = rightWeapon.heatAmount
                    if leftWeapon:isa("Minigun") then
                        exoWeaponFraction = (exoWeaponFraction + leftWeapon.heatAmount) / 2.0
                    end
                    exoWeaponFraction = 1 - exoWeaponFraction
                end
                return exoWeaponFraction
            end
        end


    end

    return 0    
end

