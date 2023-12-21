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
    mark:SetTextureCoordinates(1, 1, 1, 1) -- invisible
    mark:SetInheritsParentAlpha(true)
    mark:SetSize(Vector(1, 1, 0))
    mark:SetIsVisible(false)

    local image = GetGUIManager():CreateGraphicItem()
    image:SetTexture(kFairStartTexture)
    --image:SetInheritsParentAlpha(true)
    image:SetColor(Color(1, 1, 1, 0.8))
    image:SetSize(GUILinearScale(Vector(50, 50, 0)))
    image:SetAnchor(GUIItem.Middle, GUIItem.Center)
    image:SetPosition(GUILinearScale(Vector(-25, -25, 0)))
    image:SetIsVisible(true)
    mark:AddChild(image)

    return {mark = mark, image = image}
end

local oldGUIMinimapInitialize = GUIMinimap.Initialize
function GUIMinimap:Initialize()
    oldGUIMinimapInitialize(self)

    --Add Fairstart thingy
    self.FairStartMarine = GUICreateFairStartPing(1)
    self.FairStartMarine.mark:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.FairStartMarine.mark:SetLayer(5)
    self.minimap:AddChild(self.FairStartMarine.mark)

    self.FairStartAlien = GUICreateFairStartPing(2)
    self.FairStartAlien.mark:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.FairStartAlien.mark:SetLayer(5)
    self.minimap:AddChild(self.FairStartAlien.mark)
end

local oldGUIMinimapUpdateMapClick = GUIMinimap.UpdateMapClick
function GUIMinimap:UpdateMapClick()
    oldGUIMinimapUpdateMapClick(self)

    local player = Client.GetLocalPlayer()
    local playerTeamNr = player:GetTeamNumber()
    if (playerTeamNr == 1 or playerTeamNr == 2 or playerTeamNr == 3) then
        local gameTime, state = PlayerUI_GetGameLengthTime()
        if state == 4 or (state == 5 and gameTime < 15) then
            if FairStartAlienLoc and FairStartMarineLoc then
                self.FairStartMarine.mark:SetPosition(Vector(self:PlotToMap(FairStartMarineLoc.x, FairStartMarineLoc.z)))
                self.FairStartMarine.mark:SetIsVisible(true)
                self.FairStartAlien.mark:SetPosition(Vector(self:PlotToMap(FairStartAlienLoc.x, FairStartAlienLoc.z)))
                self.FairStartAlien.mark:SetIsVisible(true)
            end
        else
            if self.FairStartAlien.mark:GetIsVisible() or self.FairStartMarine.mark:GetIsVisible() then
                self.FairStartAlien.mark:SetIsVisible(false)
                self.FairStartMarine.mark:SetIsVisible(false)
            end
        end
    else
        if self.FairStartAlien.mark:GetIsVisible() or self.FairStartMarine.mark:GetIsVisible() then
            self.FairStartAlien.mark:SetIsVisible(false)
            self.FairStartMarine.mark:SetIsVisible(false)
        end
    end
end

local function SetFairStartLocations(message)
    if message and message.Alien and message.Marine then
        FairStartAlienLoc = message.Alien
        FairStartMarineLoc = message.Marine
    end
end

local orgGUIMinimapSetStencilFunc = GUIMinimap.SetStencilFunc

function GUIMinimap:SetStencilFunc(stencilFunc)
    self.FairStartAlien.mark:SetStencilFunc(stencilFunc)
    self.FairStartAlien.image:SetStencilFunc(stencilFunc)
    self.FairStartMarine.mark:SetStencilFunc(stencilFunc)
    self.FairStartMarine.image:SetStencilFunc(stencilFunc)
    orgGUIMinimapSetStencilFunc(self, stencilFunc)
end

Client.HookNetworkMessage("FairStartPing", SetFairStartLocations)

local orgGUIMinimapUpdate = GUIMinimap.Update
local shouldClose = nil

function GUIMinimap:Update(deltaTime)
    -- if game is in countdown mode
    if Client then
        local Player = Client.GetLocalPlayer()
        if GetGameInfoEntity():GetState() == kGameState.Countdown and Player:GetIsOnPlayingTeam() then
            local CurrentCountDown = Player:GetCountDownTime()
            if (CurrentCountDown < (kCountDownLength - 0.5) and CurrentCountDown > 1.5) or Player:isa("Commander") then
                local minimapFrameScript = ClientUI.GetScript("GUIMinimapFrame")
                if minimapFrameScript and minimapFrameScript:LargeMapIsVisible() == false then
                    shouldClose = true
                    if minimapFrameScript then
                        minimapFrameScript:ShowMap(true)
                        minimapFrameScript:SetBackgroundMode((true and GUIMinimapFrame.kModeBig) or GUIMinimapFrame.kModeMini, nil)
                    end
                end
            elseif shouldClose then
                local minimapFrameScript = ClientUI.GetScript("GUIMinimapFrame")
                if minimapFrameScript then
                    minimapFrameScript:ShowMap(false)
                    minimapFrameScript:SetBackgroundMode((true and GUIMinimapFrame.kModeBig) or GUIMinimapFrame.kModeMini, nil)
                end
                shouldClose = nil
            end
        elseif shouldClose and GetGameInfoEntity():GetState() ~= kGameState.Countdown then
            local minimapFrameScript = ClientUI.GetScript("GUIMinimapFrame")
            if minimapFrameScript and minimapFrameScript:LargeMapIsVisible() then
                if minimapFrameScript then
                    minimapFrameScript:ShowMap(false)
                    minimapFrameScript:SetBackgroundMode((true and GUIMinimapFrame.kModeBig) or GUIMinimapFrame.kModeMini, nil)
                end
            end
            shouldClose = nil
        end
    end

    orgGUIMinimapUpdate(self, deltaTime)
end
