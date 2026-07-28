-- Hydra placement indicator for Gorge HUD (drawn above babbler indicators).
local kBuildMenuTexture = PrecacheAsset("ui/buildmenu.dds")
local kDropStructureAbilityMapName = "drop_structure_ability"
local kBabblerBombAbilityMapName = "babbler_bomb_ability"
local kHydraSlotSize = GUIScale(50)
local kHydraSlotSpacing = GUIScale(5)
local kHydraIndicatorOffset = Vector(GUIScale(25) + kHydraSlotSpacing, -(kHydraSlotSize), 0)
local kStructureSummaryIndicatorOffset = kHydraIndicatorOffset + Vector(0, -(kHydraSlotSize + GUIScale(-10)), 0)
local kStructureSummaryIconSize = GUIScale(48)
local kStructureSummaryIconSpacing = GUIScale(8)
local kStructureSummaryTextOffset = Vector(GUIScale(1), GUIScale(8), 0)

local kHydraActiveColor = Color(1, 0.741, 0.309, 1)
local kHydraInactiveColor = Color(0.2, 0.2, 0.2, 0.9)
local kStructureSummaryTextColor = Color(1, 1, 1, 1)

local gorgeHudDelta = 0.5
local lastGorgeHudUpdateTime = 0

local function GetHasBabblerBombTechId()
    return kTechId and rawget(kTechId, "BabblerBombAbility") ~= nil
end

local function EnsureHydraIndicatorFrame(self)
    if self.hydraIndicationFrame then
        return
    end

    self.hydraHydraIcons = {}

    self.hydraIndicationFrame = GetGUIManager():CreateGraphicItem()
    self.hydraIndicationFrame:SetColor(Color(0, 0, 0, 0))
    self.hydraIndicationFrame:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.hydraIndicationFrame:SetIsVisible(false)

    if self.babblerIndicationFrame then
        self.babblerIndicationFrame:AddChild(self.hydraIndicationFrame)
        -- Adjust the position of babbler frame to make room for hydra indicators above it
        self.babblerIndicationFrame:SetPosition(self.babblerIndicationFrame:GetPosition() + Vector(0, kHydraSlotSize + GUIScale(-10), 0))
        self.hydraIndicationFrame:SetPosition(kHydraIndicatorOffset)
    end
end

local function SetHydraIconCount(self, maxHydras)
    local icons = self.hydraHydraIcons
    local current = #icons

    if current < maxHydras then
        for i = 1, maxHydras - current do
            local icon = GetGUIManager():CreateGraphicItem()
            icon:SetTexture(kBuildMenuTexture)
            icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.Hydra)))
            icon:SetSize(Vector(kHydraSlotSize, kHydraSlotSize, 0))
            icon:SetPosition(Vector((#icons) * (kHydraSlotSize + kHydraSlotSpacing), 0, 0))
            self.hydraIndicationFrame:AddChild(icon)
            table.insert(icons, icon)
        end
    elseif maxHydras < current then
        for i = 1, current - maxHydras do
            local icon = icons[#icons]
            GUI.DestroyItem(icon)
            table.remove(icons, #icons)
        end
    end

    local width = (kHydraSlotSize + kHydraSlotSpacing) * #icons
    self.hydraIndicationFrame:SetSize(Vector(width, kHydraSlotSize, 0))
end

local function CreateStructureSummaryItem(parent, techId)
    local item = {}

    item.icon = GetGUIManager():CreateGraphicItem()
    item.icon:SetTexture(kBuildMenuTexture)
    item.icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(techId)))
    item.icon:SetSize(Vector(kStructureSummaryIconSize, kStructureSummaryIconSize, 0))
    item.icon:SetColor(kHydraInactiveColor)
    parent:AddChild(item.icon)

    item.text = GetGUIManager():CreateTextItem()
    item.text:SetFontName(Fonts.kStamp_Large)
    item.text:SetScale(GetScaledVector() * 0.5)
    item.text:SetAnchor(GUIItem.Middle, GUIItem.Center)
    item.text:SetTextAlignmentX(GUIItem.Align_Center)
    item.text:SetTextAlignmentY(GUIItem.Align_Center)
    item.text:SetPosition(kStructureSummaryTextOffset)
    item.text:SetColor(kStructureSummaryTextColor)
    item.text:SetText("0/0")
    item.icon:AddChild(item.text)

    return item
end

local function EnsureStructureSummaryFrame(self)
    if self.structureSummaryFrame then
        return
    end

    self.structureSummaryFrame = GetGUIManager():CreateGraphicItem()
    self.structureSummaryFrame:SetColor(Color(0, 0, 0, 0))
    self.structureSummaryFrame:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.structureSummaryFrame:SetIsVisible(false)

    self.clogSummaryItem = CreateStructureSummaryItem(self.structureSummaryFrame, kTechId.Clog)
    self.clogSummaryItem.icon:SetPosition(Vector(0, 0, 0))

    self.webSummaryItem = CreateStructureSummaryItem(self.structureSummaryFrame, kTechId.Web)
    self.webSummaryItem.icon:SetPosition(Vector(kStructureSummaryIconSize + kStructureSummaryIconSpacing, 0, 0))

    if GetHasBabblerBombTechId() then
        self.babblerBombSummaryItem = CreateStructureSummaryItem(self.structureSummaryFrame, kTechId.BabblerBombAbility)
        self.babblerBombSummaryItem.icon:SetPosition(Vector((kStructureSummaryIconSize + kStructureSummaryIconSpacing) * 2, 0, 0))
    else
        self.babblerBombSummaryItem = nil
    end

    local itemCount = self.babblerBombSummaryItem and 2 or 1
    local width = (itemCount * kStructureSummaryIconSize) + ((itemCount - 1) * kStructureSummaryIconSpacing)
    self.structureSummaryFrame:SetSize(Vector(width, kStructureSummaryIconSize, 0))

    if self.babblerIndicationFrame then
        self.babblerIndicationFrame:AddChild(self.structureSummaryFrame)
        self.structureSummaryFrame:SetPosition(kStructureSummaryIndicatorOffset)
    end
end

local function UpdateStructureSummaryIndication(self)
    EnsureStructureSummaryFrame(self)

    local player = Client.GetLocalPlayer()
    if not player or not player:isa("Gorge") then
        self.structureSummaryFrame:SetIsVisible(false)
        return
    end

    local dropStructure = player:GetWeapon(kDropStructureAbilityMapName)

    local maxClogs = LookupTechData(kTechId.Clog, kTechDataMaxAmount, 0)
    local maxWebs = LookupTechData(kTechId.Web, kTechDataMaxAmount, 0)
    local placedClogs = 0
    local placedWebs = 0
    if dropStructure and dropStructure.GetNumStructuresBuilt then
        placedClogs = dropStructure:GetNumStructuresBuilt(kTechId.Clog) or 0
        placedWebs = dropStructure:GetNumStructuresBuilt(kTechId.Web) or 0
    end

    -- Web debugging output
    placedClogs = Clamp(placedClogs, 0, maxClogs)
    placedWebs = Clamp(placedWebs, 0, maxWebs)

    self.clogSummaryItem.text:SetText(string.format("%d/%d", placedClogs, maxClogs))
    self.clogSummaryItem.icon:SetColor(placedClogs > 0 and kHydraActiveColor or kHydraInactiveColor)

    self.webSummaryItem.text:SetText(string.format("%d/%d", placedWebs, maxWebs))
    self.webSummaryItem.icon:SetColor(placedWebs > 0 and kHydraActiveColor or kHydraInactiveColor)

    if self.babblerBombSummaryItem then
        if not player:GetWeapon(BabblerBombAbility.kMapName) then
            if self.babblerBombSummaryItem.icon:GetIsVisible() or self.babblerBombSummaryItem.text:GetIsVisible() then
                self.babblerBombSummaryItem.icon:SetIsVisible(false)
                self.babblerBombSummaryItem.text:SetIsVisible(false)
            end
        else
            if not self.babblerBombSummaryItem.icon:GetIsVisible() or not self.babblerBombSummaryItem.text:GetIsVisible() then
                self.babblerBombSummaryItem.icon:SetIsVisible(true)
                self.babblerBombSummaryItem.text:SetIsVisible(true)
            end
            local currentCharges = 0
            local maxCharges = 2
            --print("BabblerBomb Max Charges: " .. tostring(LookupTechData(kTechId.BabblerBombAbility, kTechDataMaxAmount, 0)))

            local bombAbility = player:GetWeapon(kBabblerBombAbilityMapName)
            if bombAbility then
                if bombAbility.GetCurrentCharges then
                    bombAbility:RechargeCharges() -- Ensure charges are up to date
                    currentCharges = bombAbility:GetCurrentCharges() or 0
                end

                if bombAbility.GetMaxCharges then
                    maxCharges = bombAbility:GetMaxCharges() or maxCharges
                end
            end

            currentCharges = Clamp(currentCharges, 0, maxCharges)
            self.babblerBombSummaryItem.text:SetText(string.format("%d/%d", currentCharges, maxCharges))
            self.babblerBombSummaryItem.icon:SetColor(currentCharges > 0 and kHydraActiveColor or kHydraInactiveColor)
        end
    end

    self.structureSummaryFrame:SetIsVisible(true)
end

local function UpdateHydraIndication(self)
    EnsureHydraIndicatorFrame(self)

    local player = Client.GetLocalPlayer()
    if not player or not player:isa("Gorge") then
        self.hydraIndicationFrame:SetIsVisible(false)
        return
    end

    local maxHydras = LookupTechData(kTechId.Hydra, kTechDataMaxAmount, 0)
    if maxHydras <= 0 then
        self.hydraIndicationFrame:SetIsVisible(false)
        return
    end

    local placedHydras = 0
    local dropStructure = player:GetWeapon(kDropStructureAbilityMapName)
    if dropStructure and dropStructure.GetNumStructuresBuilt then
        placedHydras = dropStructure:GetNumStructuresBuilt(kTechId.Hydra) or 0
    end

    placedHydras = Clamp(placedHydras, 0, maxHydras)

    SetHydraIconCount(self, maxHydras)
    for i = 1, #self.hydraHydraIcons do
        self.hydraHydraIcons[i]:SetColor(i <= placedHydras and kHydraActiveColor or kHydraInactiveColor)
    end

    self.hydraIndicationFrame:SetIsVisible(true)
end

local oldInitialize = GUIAlienHUD.Initialize
function GUIAlienHUD:Initialize()
    oldInitialize(self)

    if Shared.GetTime() - lastGorgeHudUpdateTime >= gorgeHudDelta then
        UpdateHydraIndication(self)
        UpdateStructureSummaryIndication(self)
        lastGorgeHudUpdateTime = Shared.GetTime()
    end
end

local oldUpdate = GUIAlienHUD.Update
function GUIAlienHUD:Update(deltaTime)
    oldUpdate(self, deltaTime)

    if Shared.GetTime() - lastGorgeHudUpdateTime >= gorgeHudDelta then
        UpdateHydraIndication(self)
        UpdateStructureSummaryIndication(self)
        lastGorgeHudUpdateTime = Shared.GetTime()
    end
end
