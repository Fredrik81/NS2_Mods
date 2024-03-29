local oldClipWeaponOnDestroy = ClipWeapon.OnDestroy

function ClipWeapon:OnDestroy()
    if Server then
        if self:GetTechId() ~= kTechId.Rifle and self:GetTechId() ~= kTechId.Pistol then
            StatsUI_RegisterLost(self:GetTechId())
        end
    end
    oldClipWeaponOnDestroy(self)
end