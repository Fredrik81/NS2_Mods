-- My stuff
if Client then
    Script.Load("lua/Devnull_QOL/GUIGorgeQoL.lua")
end

function Gorge:OnInitialized()
    Alien.OnInitialized(self)

    self:SetModel(Gorge.kModelName, kGorgeAnimationGraph)

    if Server then
        self.slideLoopSound = Server.CreateEntity(SoundEffect.kMapName)
        self.slideLoopSound:SetAsset(Gorge.kSlideLoopSound)
        self.slideLoopSound:SetParent(self)
    elseif Client then
        self:AddHelpWidget("GUIGorgeHealHelp", 2)
        self:AddHelpWidget("GUIGorgeBellySlideHelp", 2)
        self:AddHelpWidget("GUITunnelEntranceHelp", 1)
    end

    InitMixin(self, IdleMixin)
    if Client then
        self.guiObj = CreateGUIObject("gorgeqol_ui", GUIGorgeQoL)
        self.guiObj:AlignBottomRight()
        self.guiObj:SetY(-10)
        self.guiObj:SetX(-320)
    end
end

function Gorge:OnDestroy()
    if Client then
        if self.guiObj then
            self.guiObj:Destroy()
        end
    end
end

if Client then
    --[[
    function Gorge:OnUpdateRender()
        if not self.guiObj then
            return
        end
        local player = Client.GetLocalPlayer()
        if player and player:isa("Gorge") then
            if not self.guiObj:GetVisible() then
                self.guiObj:SetVisible(true)
                --print("Is Gorge...")
            end
            self.guiObj.Update()
        else
            self.guiObj:Reset()
            self.guiObj:SetVisible(false)
        end
    end
]]
end

--[[
if Server then
    function Gorge:OnProcessMove(input)

        Alien.OnProcessMove(self, input)
        self.hasBellySlide = GetIsTechAvailable(self:GetTeamNumber(), kTechId.BellySlide) == true or GetGamerules():GetAllTech()

    end
end
]]
function Gorge:OnUpdatePlayer(deltaTime)
    if Client then
        if not self.guiObj then
            return
        end
        local player = Client.GetLocalPlayer()
        if player and player:isa("Gorge") then
            if not self.guiObj:GetVisible() then
                self.guiObj:SetVisible(true)
                -- print("Is Gorge...")
            end
            self.guiObj.Update()
        else
            self.guiObj:Reset()
            self.guiObj:SetVisible(false)
        end
    end

    if Server then
        if self.guiObj and self.guiObj:GetVisible() then
            local buildAbility = self:GetWeapon(DropStructureAbility.kMapName)
            if buildAbility then
                input = buildAbility:ProcessMoveOnWeapon(nil)
            end
        end
    end
    -- Alien.OnUpdate(self, dt)
    if Server then
        print("Gorge UPDATE..........Server" .. tostring(deltaTime))
    end
    -- if Predict then print("Gorge UPDATE..........Predict" .. tostring(deltaTime)) end
    -- if Client then print("Gorge UPDATE..........Client" .. tostring(deltaTime)) end
    -- Alien.OnUpdate(self, deltaTime)
end
