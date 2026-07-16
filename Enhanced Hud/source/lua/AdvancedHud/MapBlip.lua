-- Overlay hive-type chamber icon on minimap hive blips.

local kHiveOverlayTexture = PrecacheAsset("ui/Devnull/AlienHiveChamber.dds")
local kFrameWidth = 80
local kFrameByTechId =
{
    [kTechId.CragHive] = { 0, 0, 80, 38 },
    [kTechId.ShiftHive] = { 0, 38, 80, 76 },
    [kTechId.ShadeHive] = { 0, 76, 80, 114 },
}

local function GetHiveOverlayCoords(techId)
    return kFrameByTechId[techId]
end

local function EnsureHiveOverlayItem(item)
    if item.hiveOverlay then
        return item.hiveOverlay
    end

    local overlay = GUIManager:CreateGraphicItem()
    overlay:SetAnchor(GUIItem.Left, GUIItem.Top)
    overlay:SetColor(1, 1, 1, 1)
    overlay:SetTexture(kHiveOverlayTexture)
    overlay:SetBlendTechnique(GUIItem.Set)
    overlay:SetIsVisible(false)
    item:AddChild(overlay)

    item.hiveOverlay = overlay
    return overlay
end

local function DestroyHiveOverlayItem(item)
    if item.hiveOverlay then
        GUI.DestroyItem(item.hiveOverlay)
        item.hiveOverlay = nil
    end
end

function MapBlip:UpdateMinimapItemHook(minimap, item)
    if self:GetMapBlipType() ~= kMinimapBlipType.Hive then
        DestroyHiveOverlayItem(item)
        return
    end

    local owner = Shared.GetEntity(self:GetOwnerEntityId())
    if not owner or not owner.GetTechId then
        DestroyHiveOverlayItem(item)
        return
    end

    local coords = GetHiveOverlayCoords(owner:GetTechId())
    if not coords then
        DestroyHiveOverlayItem(item)
        return
    end

    local overlay = EnsureHiveOverlayItem(item)

    overlay:SetTexturePixelCoordinates(GUIUnpackCoords(coords))
    overlay:SetSize(item.blipSize)
    overlay:SetPosition(Vector(0, 0, 0))
    overlay:SetIsVisible(item:GetIsVisible())
end
