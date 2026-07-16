


-- copied to use as local 
local function SendButtonTargetedAction(index, x, y)

    local techId = GetTechIdFromButtonIndex(index)
    local player = Client.GetLocalPlayer()
    local normalizedPickRay = CreatePickRay(player, x, y)
    
    -- Don't execute targeted action if we're still on top of the UI
    if not CommanderUI_GetMouseIsOverUI() then
        
        player:SendTargetedAction(techId, normalizedPickRay)
        return true
        
    end
    
    return false
    
end



local oldGUICommanderButtonsInitialize = GUICommanderButtons.Initialize
function GUICommanderButtons:Initialize()
    oldGUICommanderButtonsInitialize(self)

    a_hud_selectall = Client.GetOptionBoolean("a_hud_selectall", true)
    self:InitializeSelectAllArcsIcon()
    self:InitializeSelectAllMacsIcon()
    self:InitializeSelectAllObservatoryIcon()
end


function GUICommanderButtons:InitializeSelectAllArcsIcon()
    if PlayerUI_GetTeamType() == kMarineTeamType then

        GUICommanderButtons.kSelectAllArcsX = GUIScale(10)
        GUICommanderButtons.kSelectAllArcsY = GUIScale(90)
        GUICommanderButtons.kSelectAllArcsSize = GUIScale(48 + 8)


        self.selectAllArcs = GUIManager:CreateGraphicItem()
        self.selectAllArcs:SetSize(Vector(GUICommanderButtons.kSelectAllArcsSize, GUICommanderButtons.kSelectAllArcsSize, 0))
        self.selectAllArcs:SetAnchor(GUIItem.Left, GUIItem.Top)
        self.selectAllArcs:SetPosition(Vector(GUICommanderButtons.kSelectAllArcsX, GUICommanderButtons.kSelectAllArcsY + 100, 0))
        self.selectAllArcs:SetTexture("ui/buildmenu.dds")
        
        local coordinates = GetTextureCoordinatesForIcon(kTechId.ARC)
        self.selectAllArcs:SetTexturePixelCoordinates(GUIUnpackCoords(coordinates))
        self.selectAllArcs:SetVisible(false)
    
    end
end


function GUICommanderButtons:InitializeSelectAllMacsIcon()
    if PlayerUI_GetTeamType() == kMarineTeamType then

        GUICommanderButtons.kSelectAllMacsX = GUIScale(10)
        GUICommanderButtons.kSelectAllMacsY = GUIScale(90)
        GUICommanderButtons.kSelectAllMacsSize = GUIScale(48 + 8)


        self.selectAllMacs = GUIManager:CreateGraphicItem()
        self.selectAllMacs:SetSize(Vector(GUICommanderButtons.kSelectAllMacsSize, GUICommanderButtons.kSelectAllMacsSize, 0))
        self.selectAllMacs:SetAnchor(GUIItem.Left, GUIItem.Top)
        self.selectAllMacs:SetPosition(Vector(GUICommanderButtons.kSelectAllMacsX, GUICommanderButtons.kSelectAllMacsY + 150, 0))
        self.selectAllMacs:SetTexture("ui/buildmenu.dds")
        
        local coordinates = GetTextureCoordinatesForIcon(kTechId.MAC)
        self.selectAllMacs:SetTexturePixelCoordinates(GUIUnpackCoords(coordinates))
        self.selectAllMacs:SetVisible(false)
    
    end
end


function GUICommanderButtons:InitializeSelectAllObservatoryIcon()
    if PlayerUI_GetTeamType() == kMarineTeamType then

        GUICommanderButtons.kSelectAllObservatoryX = GUIScale(10)
        GUICommanderButtons.kSelectAllObservatoryY = GUIScale(90)
        GUICommanderButtons.kSelectAllObservatorySize = GUIScale(48 + 6)


        self.selectAllObservatory = GUIManager:CreateGraphicItem()
        self.selectAllObservatory:SetSize(Vector(GUICommanderButtons.kSelectAllObservatorySize, GUICommanderButtons.kSelectAllObservatorySize, 0))
        self.selectAllObservatory:SetAnchor(GUIItem.Left, GUIItem.Top)
        self.selectAllObservatory:SetPosition(Vector(GUICommanderButtons.kSelectAllObservatoryX, GUICommanderButtons.kSelectAllObservatoryY + 50, 0))
        self.selectAllObservatory:SetTexture("ui/buildmenu.dds")
        
        local coordinates = GetTextureCoordinatesForIcon(kTechId.Observatory)
        self.selectAllObservatory:SetTexturePixelCoordinates(GUIUnpackCoords(coordinates))
        self.selectAllObservatory:SetVisible(false)
    
    end
end


local oldGUICommanderButtonsUninitialize = GUICommanderButtons.Uninitialize
function GUICommanderButtons:Uninitialize()
    oldGUICommanderButtonsUninitialize(self)

    if self.selectAllArcs then
        GUI.DestroyItem(self.selectAllArcs)
        self.selectAllArcs = nil
    end
    if self.selectAllMacs then
        GUI.DestroyItem(self.selectAllMacs)
        self.selectAllMacs = nil
    end
    if self.selectAllObservatory then
        GUI.DestroyItem(self.selectAllObservatory)
        self.selectAllObservatory = nil
    end
end



local function ButtonPressed(self, index)

    a_hud_selectall = Client.GetOptionBoolean("a_hud_selectall", true)

    if CommanderUI_MenuButtonRequiresTarget(index) then
        self:SetTargetedButton(index)
    end
    
    CommanderUI_MenuButtonAction(index)
    
    self:SelectTab(index)
    
end

function GUICommanderButtons:MousePressed(key, mouseX, mouseY)

    if CommanderUI_GetUIClickable() then
    
        if key == InputKey.MouseButton1 then
        
            -- Cancel targeted button upon right mouse press.
            if self.targetedButton ~= nil then
                self:SetTargetedButton(nil)
            end
            
        elseif key == InputKey.MouseButton0 then
        
            local success = false
        
            if self.idleWorkers:GetIsVisible() and GUIItemContainsPoint(self.idleWorkers, mouseX, mouseY) then
                CommanderUI_ClickedIdleWorker()
                success = true
            elseif self.playerAlerts:GetIsVisible() and GUIItemContainsPoint(self.playerAlerts, mouseX, mouseY) then
                CommanderUI_ClickedPlayerAlert()
                success = true
            elseif self.selectAllPlayers and GUIItemContainsPoint(self.selectAllPlayers, mouseX, mouseY) then
                CommanderUI_ClickedSelectAllPlayers()
                success = true
            elseif self.selectAllArcs and GUIItemContainsPoint(self.selectAllArcs, mouseX, mouseY) then
                CommanderUI_ClickedSelectAllArcs()
                success = true
            elseif self.selectAllMacs and GUIItemContainsPoint(self.selectAllMacs, mouseX, mouseY) then
                CommanderUI_ClickedSelectAllMacs()
                success = true
            elseif self.selectAllObservatory and GUIItemContainsPoint(self.selectAllObservatory, mouseX, mouseY) then
                CommanderUI_ClickedSelectAllObservatory()
                success = true
            elseif self.targetedButton ~= nil then
            
                -- Commander_GhostStructure handles ghost structures. This code path handles tech that doesn't
                -- have a ghost model like Scan and Nano Shield.
                if not GetCommanderGhostStructureEnabled() then
                
                    if SendButtonTargetedAction(self.targetedButton, mouseX, mouseY) then
                        self:SetTargetedButton(nil)
                    end
                    
                end
                
            else
            
                for i = 1, #self.buttons do
                
                    local buttonItem = self.buttons[i]
                    local buttonStatus = CommanderUI_MenuButtonStatus(i)
                    if buttonItem:GetIsVisible() and buttonStatus == GUICommanderButtons.kButtonStatusEnabled.Id and
                       GUIItemContainsPoint(buttonItem, mouseX, mouseY) then
                       
                        ButtonPressed(self, i)
                        success = true
                        break
                        
                    end
                    
                end
                
            end
            
            if success then
                CommanderUI_OnButtonClicked()
            end
            
        end
        
    end
    
end


function GUICommanderButtons:ContainsPoint(pointX, pointY)

    -- Check if the point is over any of the UI managed by the GUICommanderButtons.
    local containsPoint = self.idleWorkers:GetIsVisible() and GUIItemContainsPoint(self.idleWorkers, pointX, pointY)
    containsPoint = containsPoint or (self.playerAlerts:GetIsVisible() and GUIItemContainsPoint(self.playerAlerts, pointX, pointY))
    containsPoint = containsPoint or (self.selectAllPlayers ~= nil and GUIItemContainsPoint(self.selectAllPlayers, pointX, pointY))
    containsPoint = containsPoint or (self.selectAllArcs ~= nil and GUIItemContainsPoint(self.selectAllArcs, pointX, pointY))
    containsPoint = containsPoint or (self.selectAllMacs ~= nil and GUIItemContainsPoint(self.selectAllMacs, pointX, pointY))
    containsPoint = containsPoint or (self.selectAllObservatory ~= nil and GUIItemContainsPoint(self.selectAllObservatory, pointX, pointY))
    return containsPoint or GUIItemContainsPoint(self.background, pointX, pointY)
    
end


local oldGUICommanderButtonsUpdate = GUICommanderButtons.Update
function GUICommanderButtons:Update(deltaTime)

    oldGUICommanderButtonsUpdate(self, deltaTime)
    
    if GetHasTech(self, kTechId.ARC) and a_hud_selectall then
        if not self.selectAllArcs:GetVisible() then 
            self.selectAllArcs:SetVisible(true)
        end
    else
        if self.selectAllArcs and self.selectAllArcs:GetVisible() then 
            self.selectAllArcs:SetVisible(false) 
        end
    end
    if GetHasTech(self, kTechId.MAC) and a_hud_selectall then
        if not self.selectAllMacs:GetVisible() then 
            self.selectAllMacs:SetVisible(true)
        end
    else
        if  self.selectAllMacs and self.selectAllMacs:GetVisible() then 
            self.selectAllMacs:SetVisible(false) 
        end
    end
    if GetHasTech(self, kTechId.Observatory) and a_hud_selectall then
        if not self.selectAllObservatory:GetVisible() then 
            self.selectAllObservatory:SetVisible(true)
        end
    else
        if  self.selectAllObservatory and self.selectAllObservatory:GetVisible() then 
            self.selectAllObservatory:SetVisible(false) 
        end
    end
end
