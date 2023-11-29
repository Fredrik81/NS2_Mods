local FairStartMarineLoc = false
local FairStartAlienLoc = false

local kFairStartAlienTexture = PrecacheAsset("ui/FairStartAlien.dds")
local kFairStartMarineTexture = PrecacheAsset("ui/FairStartMarine.dds")
local function GUICreateFairStartPing(team)
    local kFairStartTexture = kFairStartAlienTexture
    if team == 1 then
        kFairStartTexture = kFairStartMarineTexture
    end

    local mark = GetGUIManager():CreateGraphicItem()
    mark:SetTexture(kFairStartTexture)
    mark:SetTextureCoordinates(1,1,1,1) -- invisible
    --mark:SetInheritsParentAlpha(true)
    mark:SetSize(Vector(1,1,0))
    --mark:SetIsVisible(true)

    local image = GetGUIManager():CreateGraphicItem()
    image:SetTexture(kFairStartTexture)
    image:SetInheritsParentAlpha(true)
    image:SetSize(GUILinearScale(Vector(60,60,0)))
    image:SetAnchor(GUIItem.Middle, GUIItem.Center)
    image:SetPosition(GUILinearScale(Vector(-30,-30,0)))
    --image:SetIsVisible(true)
    mark:AddChild(image)

    return {mark = mark, image = image}
end

local oldGUIMinimapInitialize = GUIMinimap.Initialize
function GUIMinimap:Initialize()
    oldGUIMinimapInitialize(self)

    FairStartAlienLoc = false
    FairStartMarineLoc = false

    --Add Fairstart thingy
    self.FairStartMarine = GUICreateFairStartPing(1)
    self.FairStartMarine.mark:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.FairStartMarine.mark:SetLayer(5)
    --self.FairStartMarine:SetStencilFunc(self.stencilFunc)
    self.minimap:AddChild(self.FairStartMarine.mark)

    self.FairStartAlien = GUICreateFairStartPing(2)
    self.FairStartAlien.mark:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.FairStartAlien.mark:SetLayer(5)
    --self.FairStartMarine:SetStencilFunc(self.stencilFunc)
    self.minimap:AddChild(self.FairStartAlien.mark)
end

local oldGUIMinimapUpdateMapClick = GUIMinimap.UpdateMapClick
function GUIMinimap:UpdateMapClick()
    oldGUIMinimapUpdateMapClick(self)

    local player = Client.GetLocalPlayer()
    local playerTeamNr = player:GetTeamNumber()
    if (playerTeamNr == 1 or playerTeamNr == 2) then
        local gameTime, state = PlayerUI_GetGameLengthTime()
        if state == 4 or (state == 5 and gameTime < 15) then
            if FairStartAlienLoc and FairStartMarineLoc then
                self.FairStartMarine.mark:SetPosition(Vector(self:PlotToMap(FairStartMarineLoc.x, FairStartMarineLoc.z)))
                self.FairStartMarine.image:SetIsVisible(true)
                self.FairStartAlien.mark:SetPosition(Vector(self:PlotToMap(FairStartAlienLoc.x, FairStartAlienLoc.z)))
                self.FairStartAlien.image:SetIsVisible(true)
            end
        else
            if self.FairStartAlien.image:GetIsVisible() or self.FairStartMarine.image:GetIsVisible() then
                self.FairStartAlien.image:SetIsVisible(false)
                self.FairStartMarine.image:SetIsVisible(false)
            end
        end
    end
end

local function SetFairStartLocations(message)
    if message and message.Alien and message.Marine then
        FairStartAlienLoc = message.Alien
        FairStartMarineLoc = message.Marine
    end
end

function GUIMinimap:SetStencilFunc(stencilFunc)
    self.stencilFunc = stencilFunc

    self.minimap:SetStencilFunc(stencilFunc)
    self.commanderPing.Mark:SetStencilFunc(stencilFunc)
    self.commanderPing.Border:SetStencilFunc(stencilFunc)
    self.FairStartAlien.mark:SetStencilFunc(stencilFunc)
    self.FairStartAlien.image:SetStencilFunc(stencilFunc)
    self.FairStartMarine.mark:SetStencilFunc(stencilFunc)
    self.FairStartMarine.image:SetStencilFunc(stencilFunc)

    for blip in self.inuseDynamicBlips:Iterate() do
        blip.Item:SetStencilFunc(stencilFunc)
    end

    for _, icon in self.iconMap:Iterate() do
        icon:SetStencilFunc(stencilFunc)
    end

    for _, connectionLine in ipairs(self.minimapConnections) do
        connectionLine:SetStencilFunc(stencilFunc)
    end
end

Client.HookNetworkMessage("FairStartPing", SetFairStartLocations)
