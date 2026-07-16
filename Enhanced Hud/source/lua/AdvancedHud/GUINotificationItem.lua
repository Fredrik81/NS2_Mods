-- Post-hook customization for alien research notifications.

local kBiomassIconSizeOffset = Vector(20, 20, 0)
local kBiomassIconPosOffset = Vector(-2, -2, 0)
local kUnknownLocationText = "UNKNOWN"

local function GetIsBiomassRelatedTech(techId)
    local techName = EnumToString(kTechId, techId) or ""
    return string.find(techName, "BioMass", 1, true) ~= nil
end

local function GetIsBiomassResearchTech(techId)
    local techName = EnumToString(kTechId, techId) or ""
    return string.find(techName, "ResearchBioMass", 1, true) == 1
end

local function ResolveAlienResearchLocationText(entityId, techId, useMarineStyle)
    if useMarineStyle then
        return ""
    end

    local cachedTechLocation = GetBiomassNotificationLocationForTech and GetBiomassNotificationLocationForTech(techId) or ""

    if not entityId or entityId == Entity.invalidId then
        if cachedTechLocation ~= "" then
            return string.UTF8Upper(cachedTechLocation)
        end

        return kUnknownLocationText
    end

    local cachedEntityLocation = GetBiomassNotificationLocation and GetBiomassNotificationLocation(entityId) or ""
    local entity = Shared.GetEntity(entityId)
    if not entity then
        if cachedEntityLocation ~= "" then
            return string.UTF8Upper(cachedEntityLocation)
        end

        if cachedTechLocation ~= "" then
            return string.UTF8Upper(cachedTechLocation)
        end

        return kUnknownLocationText
    end

    local locationName = entity.GetLocationName and entity:GetLocationName() or nil

    if (not locationName or locationName == "") and entity.GetAttached then
        local attached = entity:GetAttached()
        if attached and attached.GetLocationName then
            locationName = attached:GetLocationName()
        end
    end

    if locationName and locationName ~= "" then
        return string.UTF8Upper(locationName)
    end

    if cachedEntityLocation ~= "" then
        return string.UTF8Upper(cachedEntityLocation)
    end

    if cachedTechLocation ~= "" then
        return string.UTF8Upper(cachedTechLocation)
    end

    return kUnknownLocationText
end

local function ApplyBiomassIconAdjustment(self)
    if not self.icon then
        return
    end

    local iconScale = self.iconSize / 80
    local iconSizeOffset = kBiomassIconSizeOffset * iconScale
    local iconPosOffset = kBiomassIconPosOffset * iconScale

    self.icon:SetSize(self.iconSize + iconSizeOffset)
    self.icon:SetPosition(self.guiOffsets.IconPos - (iconSizeOffset / 2) + iconPosOffset)
end

local function CreateOrUpdateLocationText(self)
    if self.useMarineStyle then
        if self.techExtraText then
            self.techExtraText:SetIsVisible(false)
        end
        return
    end

    local locationText = ResolveAlienResearchLocationText(self.entityId, self.techId, self.useMarineStyle)

    if not self.techExtraText then
        self.techExtraText = self.script:CreateAnimatedTextItem()
        self.techExtraText:SetFontName(GUINotificationItem.kTitleFontName)
        self.techExtraText:SetAnchor(GUIItem.Left, GUIItem.Center)
        self.techExtraText:SetPosition(self.guiOffsets.ExtraTextPos)
        self.techExtraText:SetLayer(1)
        self.techExtraText:SetScale(GetScaledVector() * 0.6)
        self.techExtraText:SetFontIsBold(false)
        self.techExtraText.originalColor = Color(1, 1, 1, 1)
        self.techExtraText:AddAsChildTo(self.background)
        GUIMakeFontScale(self.techExtraText)
    end

    self.techExtraText:SetText(locationText)
    self.techExtraText:SetIsVisible(locationText ~= "")
end

local originalInitialize = GUINotificationItem.Initialize
function GUINotificationItem:Initialize()
    local isBiomassResearch = GetIsBiomassResearchTech(self.techId)
    if isBiomassResearch then
        local originalLookupTechData = LookupTechData
        LookupTechData = function(techId, dataType, defaultValue)
            if techId == self.techId and dataType == kTechDataResearchName then
                return "BIOMASS"
            end

            return originalLookupTechData(techId, dataType, defaultValue)
        end

        local ok, err = pcall(function()
            originalInitialize(self)
        end)

        LookupTechData = originalLookupTechData

        if not ok then
            error(err)
        end
    else
        originalInitialize(self)
    end

    if not self.useMarineStyle then
        self.guiOffsets.ExtraTextPos = self.guiOffsets.ExtraTextPos or Vector(67, 7, 0)
    end

    if GetIsBiomassRelatedTech(self.techId) then
        ApplyBiomassIconAdjustment(self)
    end

    if isBiomassResearch and self.techTitle then
        self.techTitle:SetText(string.UTF8Upper(Locale.ResolveString("BIOMASS")))
    end

    CreateOrUpdateLocationText(self)
end

local originalUpdateItem = GUINotificationItem.UpdateItem
function GUINotificationItem:UpdateItem()
    originalUpdateItem(self)
    CreateOrUpdateLocationText(self)
end

local originalSetCompleted = GUINotificationItem.SetCompleted
function GUINotificationItem:SetCompleted()
    originalSetCompleted(self)

    if self.techExtraText then
        self.techExtraText:SetColor(self.techExtraText.originalColor)
    end
end

local originalSetCancelled = GUINotificationItem.SetCancelled
function GUINotificationItem:SetCancelled()
    originalSetCancelled(self)

    if self.techExtraText then
        self.techExtraText:SetColor(self.techExtraText.originalColor)
    end
end

local originalSetLayer = GUINotificationItem.SetLayer
function GUINotificationItem:SetLayer(layer)
    originalSetLayer(self, layer)

    if self.techExtraText then
        self.techExtraText:SetLayer(layer)
    end
end

local originalFadeIn = GUINotificationItem.FadeIn
function GUINotificationItem:FadeIn(animDuration)
    originalFadeIn(self, animDuration)

    if self.techExtraText then
        local locationTextColor = Color(self.techExtraText.originalColor)
        locationTextColor.a = 0
        self.techExtraText:SetColor(locationTextColor)
        self.techExtraText:FadeIn(animDuration, nil, AnimateLinear)
    end
end

local originalFadeOut = GUINotificationItem.FadeOut
function GUINotificationItem:FadeOut(animDuration)
    originalFadeOut(self, animDuration)

    if self.techExtraText then
        self.techExtraText:FadeOut(animDuration, nil, AnimateLinear)
    end
end

local originalDestroy = GUINotificationItem.Destroy
function GUINotificationItem:Destroy()
    if self.techExtraText then
        self.techExtraText:Destroy()
        self.techExtraText = nil
    end

    originalDestroy(self)
end
