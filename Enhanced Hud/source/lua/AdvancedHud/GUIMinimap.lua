-- Additive hive-type overlays for minimap. Does not modify base blips.

local kHiveOverlayTexture = PrecacheAsset("ui/Devnull/AlienHiveChamber.dds")
local kDebugHiveOverlay = true
local kOverlayCoordsByTechId =
{
    [kTechId.CragHive] = { 0, 0, 80, 114 },
    [kTechId.ShiftHive] = { 0, 114, 80, 228 },
    [kTechId.ShadeHive] = { 0, 228, 80, 342 },
}

local function GetOverlayCoordsForTechId(techId)
    return kOverlayCoordsByTechId[techId]
end

local function DebugHiveOverlay(self, hiveId, state, details)
    if not kDebugHiveOverlay then
        return
    end

    self.hiveTypeOverlayDebugState = self.hiveTypeOverlayDebugState or {}
    local lastState = self.hiveTypeOverlayDebugState[hiveId]
    if lastState ~= state then
        self.hiveTypeOverlayDebugState[hiveId] = state
        print(string.format("HiveOverlay: hiveId=%s state=%s %s", tostring(hiveId), tostring(state), tostring(details or "")))
    end
end

local function EnsureHiveOverlayIcon(self, hiveId)
    self.hiveTypeOverlayIcons = self.hiveTypeOverlayIcons or {}

    local icon = self.hiveTypeOverlayIcons[hiveId]
    if icon then
        return icon
    end

    icon = GetGUIManager():CreateGraphicItem()
    icon:SetTexture(kHiveOverlayTexture)
    icon:SetColor(1, 1, 1, 1)
    icon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    icon:SetIsVisible(false)
    icon:SetLayer(5)
    self.minimap:AddChild(icon)

    self.hiveTypeOverlayIcons[hiveId] = icon
    return icon
end

local function RemoveHiveOverlayIcon(self, hiveId)
    if not self.hiveTypeOverlayIcons then
        return
    end

    local icon = self.hiveTypeOverlayIcons[hiveId]
    if icon then
        GUI.DestroyItem(icon)
        self.hiveTypeOverlayIcons[hiveId] = nil
    end
end

local function RemoveAllHiveOverlayIcons(self)
    if not self.hiveTypeOverlayIcons then
        return
    end

    for hiveId, _ in pairs(self.hiveTypeOverlayIcons) do
        RemoveHiveOverlayIcon(self, hiveId)
    end
end

local function GetHiveBlipSize(self, hiveId)
    if self.iconMap then
        for mapBlipId, icon in self.iconMap:Iterate() do
            local mapBlip = Shared.GetEntity(mapBlipId)
            if mapBlip and mapBlip.GetMapBlipType and mapBlip:GetMapBlipType() == kMinimapBlipType.Hive and mapBlip.GetOwnerEntityId and mapBlip:GetOwnerEntityId() == hiveId then
                return icon:GetSize()
            end
        end
    end

    local blipScale = self.GetBlipScale and self:GetBlipScale() or 1
    return GUIScale(Vector(30, 30, 0)) * blipScale
end

local function UpdateHiveTypeOverlays(self)
    if not self.minimap or not self.visible then
        return
    end

    self.hiveTypeOverlayIcons = self.hiveTypeOverlayIcons or {}

    local player = Client.GetLocalPlayer()
    if not player then
        RemoveAllHiveOverlayIcons(self)
        return
    end

    local teamNumber = player:GetTeamNumber()
    local showAllTeams = player:GetTeamType() == kNeutralTeamType
    local used = {}
    for _, hive in ipairs(GetEntities("Hive")) do
        local hiveId = hive:GetId()
        local hiveTechId = hive.GetTechId and hive:GetTechId() or kTechId.None
        local coords = GetOverlayCoordsForTechId(hiveTechId)

        if coords and hive:GetIsAlive() and (showAllTeams or hive:GetTeamNumber() == teamNumber) then
            local icon = EnsureHiveOverlayIcon(self, hiveId)
            used[hiveId] = true
            local expectedSize = GetHiveBlipSize(self, hiveId) * 0.66

            local origin = hive:GetOrigin()
            local x, y = self:PlotToMap(origin.x, origin.z)

            icon:SetTexturePixelCoordinates(GUIUnpackCoords(coords))
            icon:SetSize(expectedSize)
            icon:SetPosition(Vector(x - expectedSize.x * 0.5, y - expectedSize.y * 0.6, 0))
            icon:SetIsVisible(true)

            DebugHiveOverlay(self, hiveId, "set", string.format("techId=%s coords={%s,%s,%s,%s}", tostring(hiveTechId), tostring(coords[1]), tostring(coords[2]), tostring(coords[3]), tostring(coords[4])))
        else
            DebugHiveOverlay(self, hiveId, "skipped", string.format("techId=%s alive=%s team=%s localTeam=%s showAll=%s", tostring(hiveTechId), tostring(hive:GetIsAlive()), tostring(hive:GetTeamNumber()), tostring(teamNumber), tostring(showAllTeams)))
        end
    end

    for hiveId, icon in pairs(self.hiveTypeOverlayIcons) do
        if not used[hiveId] then
            icon:SetIsVisible(false)
            RemoveHiveOverlayIcon(self, hiveId)
            DebugHiveOverlay(self, hiveId, "removed")
        end
    end
end

local oldInitialize = GUIMinimap.Initialize
function GUIMinimap:Initialize()
    oldInitialize(self)
    self.hiveTypeOverlayIcons = {}
end

local oldSetStencilFunc = GUIMinimap.SetStencilFunc
function GUIMinimap:SetStencilFunc(stencilFunc)
    if self.hiveTypeOverlayIcons then
        for _, icon in pairs(self.hiveTypeOverlayIcons) do
            icon:SetStencilFunc(stencilFunc)
        end
    end

    oldSetStencilFunc(self, stencilFunc)
end

local oldUpdate = GUIMinimap.Update
function GUIMinimap:Update(deltaTime)
    oldUpdate(self, deltaTime)
    UpdateHiveTypeOverlays(self)
end
