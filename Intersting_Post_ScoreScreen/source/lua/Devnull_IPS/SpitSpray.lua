-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\SpitSpray.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- Spit attack on primary.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Spit.lua")
Script.Load("lua/Weapons/Alien/HealSprayMixin.lua")

class 'SpitSpray' (Ability)

SpitSpray.kMapName = "spitspray"

SpitSpray.kSpitSpeed = kSpitSpeed

local kAnimationGraph = PrecacheAsset("models/alien/gorge/gorge_view.animation_graph")

local kSpitViewEffect = PrecacheAsset("cinematics/alien/gorge/spit_1p.cinematic")
--local kSpitProjectileEffect = PrecacheAsset("cinematics/alien/gorge/spit_1p_projectile.cinematic")
local kViewSpitMaterial = PrecacheAsset("materials/effects/mesh_effects/view_spit.material")
local attackEffectMaterial
local kAttackDuration = Shared.GetAnimationLength("models/alien/gorge/gorge_view.model", "spit_attack")

if Client then

    attackEffectMaterial = Client.CreateRenderMaterial()
    attackEffectMaterial:SetMaterial(kViewSpitMaterial)
    
end

local networkVars =
{
}

AddMixinNetworkVars(HealSprayMixin, networkVars)

function SpitSpray:OnCreate()

    Ability.OnCreate(self)
    
    self.primaryAttacking = false
    
    InitMixin(self, HealSprayMixin)
    
end

function SpitSpray:GetAnimationGraphName()
    return kAnimationGraph
end

function SpitSpray:GetEnergyCost()
    return kSpitEnergyCost
end

function SpitSpray:GetHUDSlot()
    return 1
end

function SpitSpray:GetSecondaryTechId()
    return kTechId.Spray
end

function SpitSpray:GetPrimaryEnergyCost()
    return kSpitEnergyCost
end

function SpitSpray:CreateSpitProjectile(player)

    if not Predict then

        local eyePos = player:GetEyePos()
        local viewCoords = player:GetViewCoords()

        local startPointTrace = Shared.TraceCapsule(eyePos, eyePos + viewCoords.zAxis * 1.5, Spit.kRadius, 0, CollisionRep.Damage, PhysicsMask.PredictedProjectileGroup, EntityFilterOneAndIsa(player, "Babbler"))
        local startPoint = startPointTrace.endPoint

        player:CreatePredictedProjectile("Spit", startPoint, viewCoords.zAxis * self.kSpitSpeed, 0, 0, 0 )

    end

end

function SpitSpray:OnPrimaryAttack(player)
    local hasEnergy = player:GetEnergy() >= self:GetEnergyCost()
    local cooledDown = (not self.nextAttackTime) or (Shared.GetTime() >= self.nextAttackTime)
    if hasEnergy and cooledDown then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function SpitSpray:OnPrimaryAttackEnd(player)

    Ability.OnPrimaryAttackEnd(self, player)
    
    self.primaryAttacking = false
    
end

function SpitSpray:GetIsAffectedByFocus()
    return self.primaryAttacking
end

function SpitSpray:GetFocusAttackCooldown()
    return kSpitFocusAttackSlowAtMax
end

function SpitSpray:GetMaxFocusBonusDamage()
    return kSpitFocusDamageBonusAtMax
end

function SpitSpray:GetAttackAnimationDuration()
    return kAttackDuration
end

function SpitSpray:OnTag(tagName)

    PROFILE("SpitSpray:OnTag")

    if self.primaryAttacking and tagName == "shoot" then

        local player = self:GetParent()

        if player then

            if Server or (Client and Client.GetIsControllingPlayer()) then
                self:CreateSpitProjectile(player)
            end

            self:TriggerEffects("spitspray_attack")
            self:OnAttack(player)

            if Client then

                local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
                cinematic:SetCinematic(kSpitViewEffect)

                local model = player:GetViewModelEntity():GetRenderModel()

                model:RemoveMaterial(attackEffectMaterial)
                model:AddMaterial(attackEffectMaterial)
                attackEffectMaterial:SetParameter("attackTime", Shared.GetTime())

            end

        end

    end

end

function SpitSpray:OnUpdateAnimationInput(modelMixin)

    PROFILE("SpitSpray:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("ability", "spit")
    
    local activityString = "none"
    if self.primaryAttacking then
        activityString = "primary"
    end
    modelMixin:SetAnimationInput("activity", activityString)
    
end

function SpitSpray:GetDeathIconIndex()
    return ConditionalValue(self.spitted, kDeathMessageIcon.Spit, kDeathMessageIcon.Spray)
end

function SpitSpray:GetVampiricLeechScalar()
    return ConditionalValue(self.spitted, kSpitVampirismScalar, kHealSprayVampirismScalar)
end

Shared.LinkClassToMap("SpitSpray", SpitSpray.kMapName, networkVars)