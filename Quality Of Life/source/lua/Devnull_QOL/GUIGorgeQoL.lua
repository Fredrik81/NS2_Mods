-- ======= Copyright (c) 2003-2021, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/GUIGorgeQoL.lua
--
-- Created by: Darrell Gentry (darrell@naturalselection2.com)
--
-- Displays a bar for the onos BoneShield ability.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIText.lua")
Script.Load("lua/Weapons/Alien/DropStructureAbility.lua")
Script.Load("lua/GUIGorgeBuildMenu.lua")

local kMockupHeight = 1620

local kFlashTransitionRate = 2 -- 2hz, in end-to-end color transitions per second
local kNumFlashLoops = 1 -- Number of times to transition from kHurtColor1 -> kHurtColor2 - > kHurtColor1
local kTextLowAmount = 350 -- Text changes color when <= this amount

local baseClass = GUIObject
class "GUIGorgeQoL"(baseClass)

GUIGorgeQoL.kBackgroundTexture = PrecacheAsset("ui/Devnull_QOL/AlienCircle.dds")
GUIGorgeQoL.kItemTexture = PrecacheAsset("ui/Devnull_QOL/gorge_items.dds")

GUIGorgeQoL.kTextureNoDrop = {128 * 2, 128 * 3}
GUIGorgeQoL.kTextureDropped = {128 * 0, 128 * 1}
GUIGorgeQoL.kTextureAlarm = {128 * 1, 128 * 2}

GUIGorgeQoL.kDeployedColor = ColorFrom255(255, 216, 74)
GUIGorgeQoL.kNormalColor = ColorFrom255(255, 255, 255)
GUIGorgeQoL.kHurtColor1 = ColorFrom255(255, 43, 36)
GUIGorgeQoL.kHurtColor2 = ColorFrom255(255, 255, 255)

GUIGorgeQoL.kNormalTextColor = HexToColor("F4BE50")
GUIGorgeQoL.kLowTextColor = HexToColor("F53E2A")

--GUIGorgeQoL.oldHydraCount = 0
--GUIGorgeQoL.oldClogCount = 0
--GUIGorgeQoL.oldBileMineCount = 0
--GUIGorgeQoL.oldWebMineCount = 0

-- GUIGorgeQoL:AddClassProperty("CurrentHP", 0)
-- GUIGorgeQoL:AddClassProperty("MaxHP", kBoneShieldHitpoints)
-- GUIGorgeQoL:AddClassProperty("Broken", false) -- TODO(Salads): Broken bar look when no hitpoints left

local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function GUIGorgeQoL:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:SetTexture(self.kBackgroundTexture)
    self:SetSizeFromTexture()
    self:SetColor(1, 1, 1)
    self:SetSize(GUILinearScale(Vector(380, 380, 0)))
    self:SetVisible(false)
    self.scale = Client.GetScreenHeight() / kMockupHeight
    self:SetScale(self.scale, self.scale)

    GUIGorgeQoL.clog = CreateGUIObject("clog", GUIObject, self)
    GUIGorgeQoL.clog:AlignBottom()
    GUIGorgeQoL.clog:SetTexture(self.kItemTexture)
    GUIGorgeQoL.clog:SetTexturePixelCoordinates(GUIUnpackCoords({self.kTextureNoDrop[1], 128 * 2, self.kTextureNoDrop[2],
                                                          128 * 3}))
    -- self.clog:SetSizeFromTexture()
    GUIGorgeQoL.clog:SetSize(GUILinearScale(Vector(130, 130, 0)))
    GUIGorgeQoL.clog:SetColor(self.kNormalColor)
    GUIGorgeQoL.clog:SetY(-10)

    GUIGorgeQoL.clogText = CreateGUIObject("clogText", GUIText, self.clog)
    GUIGorgeQoL.clogText:AlignCenter()
    GUIGorgeQoL.clogText:SetFont("Stamp", 41)
    GUIGorgeQoL.clogText:SetColor(self.kNormalTextColor)
    GUIGorgeQoL.clogText:SetText("0/0")
    --self.clogText:SetPosition(self.hpText2:GetSize().x / 4, self.hpText2:GetSize().y)

    GUIGorgeQoL.bileMine = CreateGUIObject("bileMine", GUIObject, self)
    GUIGorgeQoL.bileMine:AlignTop()
    GUIGorgeQoL.bileMine:SetTexture(self.kItemTexture)
    GUIGorgeQoL.bileMine:SetTexturePixelCoordinates(GUIUnpackCoords({self.kTextureNoDrop[1], 128 * 1, self.kTextureNoDrop[2], 128 * 2}))
    GUIGorgeQoL.bileMine:SetSize(GUILinearScale(Vector(130, 130, 0)))
    GUIGorgeQoL.bileMine:SetColor(self.kNormalColor)
    GUIGorgeQoL.bileMine:SetY(30)

    GUIGorgeQoL.hydra1 = CreateGUIObject("hydra1", GUIObject, self)
    GUIGorgeQoL.hydra1:AlignLeft()
    GUIGorgeQoL.hydra1:SetTexture(self.kItemTexture)
    GUIGorgeQoL.hydra1:SetTexturePixelCoordinates(GUIUnpackCoords({self.kTextureNoDrop[1], 0, self.kTextureNoDrop[2], 128}))
    GUIGorgeQoL.hydra1:SetSize(GUILinearScale(Vector(100, 100, 0)))
    GUIGorgeQoL.hydra1:SetColor(self.kNormalColor)
    GUIGorgeQoL.hydra1:SetX(35)
    GUIGorgeQoL.hydra1:SetY(30)

    GUIGorgeQoL.hydra2 = CreateGUIObject("hydra2", GUIObject, self)
    GUIGorgeQoL.hydra2:AlignCenter()
    GUIGorgeQoL.hydra2:SetTexture(self.kItemTexture)
    GUIGorgeQoL.hydra2:SetTexturePixelCoordinates(GUIUnpackCoords({self.kTextureNoDrop[1], 0, self.kTextureNoDrop[2], 128}))
    GUIGorgeQoL.hydra2:SetSize(GUILinearScale(Vector(100, 100, 0)))
    GUIGorgeQoL.hydra2:SetColor(self.kNormalColor)
    GUIGorgeQoL.hydra2:SetY(30)

    GUIGorgeQoL.hydra3 = CreateGUIObject("hydra3", GUIObject, self)
    GUIGorgeQoL.hydra3:AlignRight()
    GUIGorgeQoL.hydra3:SetTexture(self.kItemTexture)
    GUIGorgeQoL.hydra3:SetTexturePixelCoordinates(GUIUnpackCoords({self.kTextureNoDrop[1], 0, self.kTextureNoDrop[2], 128}))
    GUIGorgeQoL.hydra3:SetSize(GUILinearScale(Vector(100, 100, 0)))
    GUIGorgeQoL.hydra3:SetColor(self.kNormalColor)
    GUIGorgeQoL.hydra3:SetX(-35)
    GUIGorgeQoL.hydra3:SetY(30)

    GUIGorgeQoL.web1 = CreateGUIObject("web1", GUIObject, self)
    GUIGorgeQoL.web1:AlignLeft()
    GUIGorgeQoL.web1:SetTexture(self.kItemTexture)
    GUIGorgeQoL.web1:SetTexturePixelCoordinates(GUIUnpackCoords({self.kTextureNoDrop[1], 128 * 4, self.kTextureNoDrop[2],
                                                          128 * 5}))
    GUIGorgeQoL.web1:SetSize(GUILinearScale(Vector(100, 100, 0)))
    GUIGorgeQoL.web1:SetColor(self.kNormalColor)
    GUIGorgeQoL.web1:SetX(35)
    GUIGorgeQoL.web1:SetY(-30)

    GUIGorgeQoL.web2 = CreateGUIObject("web2", GUIObject, self)
    GUIGorgeQoL.web2:AlignCenter()
    GUIGorgeQoL.web2:SetTexture(self.kItemTexture)
    GUIGorgeQoL.web2:SetTexturePixelCoordinates(GUIUnpackCoords({self.kTextureNoDrop[1], 128 * 4, self.kTextureNoDrop[2],
                                                          128 * 5}))
    GUIGorgeQoL.web2:SetSize(GUILinearScale(Vector(100, 100, 0)))
    GUIGorgeQoL.web2:SetColor(self.kNormalColor)
    GUIGorgeQoL.web2:SetY(-30)

    GUIGorgeQoL.web3 = CreateGUIObject("web3", GUIObject, self)
    GUIGorgeQoL.web3:AlignRight()
    GUIGorgeQoL.web3:SetTexture(self.kItemTexture)
    GUIGorgeQoL.web3:SetTexturePixelCoordinates(GUIUnpackCoords({self.kTextureNoDrop[1], 128 * 4, self.kTextureNoDrop[2],
                                                          128 * 5}))
    GUIGorgeQoL.web3:SetSize(GUILinearScale(Vector(100, 100, 0)))
    GUIGorgeQoL.web3:SetColor(self.kNormalColor)
    GUIGorgeQoL.web3:SetX(-35)
    GUIGorgeQoL.web3:SetY(-30)

    --[[
    self.hpText2 = CreateGUIObject("hpText", GUIText, self.bar)
    self.hpText2:AlignBottom()
    self.hpText2:SetFont("Stamp", 41)
    self.hpText2:SetColor(self.kNormalTextColor)
    self.hpText2:SetText(string.format(" / %d", self:GetMaxHP()))
    self.hpText2:SetPosition(self.hpText2:GetSize().x / 4, self.hpText2:GetSize().y)


    self.hpText = CreateGUIObject("hpText", GUIText, self.hpText2)
    self.hpText:AlignLeft()
    self.hpText:SetFont("Stamp", 41)
    self.hpText:SetX(-self.hpText:GetSize().x)
    self.hpText:SetColor(self.kNormalTextColor)

    self:HookEvent(self, "OnCurrentHPChanged", self.OnCurrentHPChanged)
    self:OnCurrentHPChanged(self:GetCurrentHP())

    self:HookEvent(self, "OnBrokenChanged", self.OnBrokenChanged)
    self:OnBrokenChanged(self:GetBroken())
    ]]
end

function GUIGorgeQoL:Reset()
    GUIGorgeQoL.oldclogCount = 0
    GUIGorgeQoL.oldBileMineCount = 0
    GUIGorgeQoL.oldHydraCount = 0
    GUIGorgeQoL.oldwebCount = 0
end

--local function GorgeBuild_GetMaxNumStructure(techId)
--    return LookupTechData(techId, kTechDataMaxAmount, -1)
--end

local function GUIGorgeQoL_GetNumStructureBuilt(techId, buildAbility)
    if buildAbility and buildAbility:isa("DropStructureAbility") then
        return buildAbility:GetNumStructuresBuilt(techId)
    end

    return -1
end

function GUIGorgeQoL:Update()
    local player = Client.GetLocalPlayer()
    if player and player:isa("Gorge") then
        --print("ish gorge..")
        local buildAbility = player:GetWeapon(DropStructureAbility.kMapName)
        --buildAbility.menuActive = true
        --GorgeBuild_GetCanAffordAbility(kTechId.Hydra)
        --GorgeBuild_GetCanAffordAbility(kTechId.BabblerEgg)
        --GorgeBuild_GetCanAffordAbility(kTechId.Clog)
        --GorgeBuild_GetCanAffordAbility(kTechId.Web)
        --print("GetShowGhostModel() " .. tostring(buildAbility:GetShowGhostModel()))
        --print("buildAbility:GetActiveStructure() " .. tostring(buildAbility:GetActiveStructure()))
        --local hydraMax = GorgeBuild_GetMaxNumStructure(kTechId.Hydra)
        local hydraCurrent = GUIGorgeQoL_GetNumStructureBuilt(kTechId.Hydra, buildAbility)
        --if 1 == 1 then return end
        --local bileMineMax = GorgeBuild_GetMaxNumStructure(kTechId.BabblerEgg)
        local bileMineCurrent = GUIGorgeQoL_GetNumStructureBuilt(kTechId.BabblerEgg, buildAbility)
        local clogMax = GorgeBuild_GetMaxNumStructure(kTechId.Clog)
        local clogCurrent = GUIGorgeQoL_GetNumStructureBuilt(kTechId.Clog, buildAbility)
        --local webMax = GorgeBuild_GetMaxNumStructure(kTechId.Web)
        local webCurrent = GUIGorgeQoL_GetNumStructureBuilt(kTechId.Web, buildAbility)

        --[[
        print("Hydra old  (" .. hydraCurrent .. "): " .. tostring(GUIGorgeQoL.oldHydraCount))
        print("Web old     (" .. webCurrent .. "): " .. tostring(GUIGorgeQoL.oldwebCount))
        print("BileMine old(" .. bileMineCurrent .. "): " .. tostring(GUIGorgeQoL.oldBileMineCount))
        print("Clog old    (" .. clogCurrent .. "): " .. tostring(GUIGorgeQoL.oldclogCount))
        print("=====================")
        ]]

        -- Hydra
        if hydraCurrent < 1 and GUIGorgeQoL.oldHydraCount ~= 0 then
            GUIGorgeQoL.oldHydraCount = 0
            GUIGorgeQoL.hydra1:SetColor(GUIGorgeQoL.kNormalColor)
            GUIGorgeQoL.hydra2:SetColor(GUIGorgeQoL.kNormalColor)
            GUIGorgeQoL.hydra3:SetColor(GUIGorgeQoL.kNormalColor)
        elseif hydraCurrent == 1 and GUIGorgeQoL.oldHydraCount ~= 1 then
            GUIGorgeQoL.oldHydraCount = 1
            GUIGorgeQoL.hydra1:SetColor(GUIGorgeQoL.kDeployedColor)
            GUIGorgeQoL.hydra2:SetColor(GUIGorgeQoL.kNormalColor)
            GUIGorgeQoL.hydra3:SetColor(GUIGorgeQoL.kNormalColor)
        elseif hydraCurrent == 2 and GUIGorgeQoL.oldHydraCount ~= 2 then
            GUIGorgeQoL.oldHydraCount = 2
            GUIGorgeQoL.hydra1:SetColor(GUIGorgeQoL.kDeployedColor)
            GUIGorgeQoL.hydra2:SetColor(GUIGorgeQoL.kDeployedColor)
            GUIGorgeQoL.hydra3:SetColor(GUIGorgeQoL.kNormalColor)
        elseif hydraCurrent > 2 and GUIGorgeQoL.oldHydraCount ~= 3 then
            GUIGorgeQoL.oldHydraCount = 3
            GUIGorgeQoL.hydra1:SetColor(GUIGorgeQoL.kDeployedColor)
            GUIGorgeQoL.hydra2:SetColor(GUIGorgeQoL.kDeployedColor)
            GUIGorgeQoL.hydra3:SetColor(GUIGorgeQoL.kDeployedColor)
        end

        -- Web
        if webCurrent < 1 and GUIGorgeQoL.oldwebCount ~= 0 then
            GUIGorgeQoL.oldwebCount = 0
            GUIGorgeQoL.web1:SetColor(GUIGorgeQoL.kNormalColor)
            GUIGorgeQoL.web2:SetColor(GUIGorgeQoL.kNormalColor)
            GUIGorgeQoL.web3:SetColor(GUIGorgeQoL.kNormalColor)
        elseif webCurrent == 1 and GUIGorgeQoL.oldwebCount ~= 1 then
            GUIGorgeQoL.oldwebCount = 1
            GUIGorgeQoL.web1:SetColor(GUIGorgeQoL.kDeployedColor)
            GUIGorgeQoL.web2:SetColor(GUIGorgeQoL.kNormalColor)
            GUIGorgeQoL.web3:SetColor(GUIGorgeQoL.kNormalColor)
        elseif webCurrent == 2 and GUIGorgeQoL.oldwebCount ~= 2 then
            GUIGorgeQoL.oldwebCount = 2
            GUIGorgeQoL.web1:SetColor(GUIGorgeQoL.kDeployedColor)
            GUIGorgeQoL.web2:SetColor(GUIGorgeQoL.kDeployedColor)
            GUIGorgeQoL.web3:SetColor(GUIGorgeQoL.kNormalColor)
        elseif webCurrent > 2 and GUIGorgeQoL.oldwebCount ~= 3 then
            GUIGorgeQoL.oldwebCount = 3
            GUIGorgeQoL.web1:SetColor(GUIGorgeQoL.kDeployedColor)
            GUIGorgeQoL.web2:SetColor(GUIGorgeQoL.kDeployedColor)
            GUIGorgeQoL.web3:SetColor(GUIGorgeQoL.kDeployedColor)
        end

        -- BileMine
        if bileMineCurrent < 1 and GUIGorgeQoL.oldBileMineCount ~= 0 then
            GUIGorgeQoL.oldBileMineCount = 0
            GUIGorgeQoL.bileMine:SetColor(GUIGorgeQoL.kNormalColor)
        elseif bileMineCurrent >= 1 and GUIGorgeQoL.oldBileMineCount ~= 1 then
            GUIGorgeQoL.oldBileMineCount = 1
            GUIGorgeQoL.bileMine:SetColor(GUIGorgeQoL.kDeployedColor)
        end

        -- Clogs
        if clogCurrent < 1 and GUIGorgeQoL.oldclogCount ~= 0 then
            GUIGorgeQoL.oldclogCount = 0
            GUIGorgeQoL.clog:SetColor(GUIGorgeQoL.kNormalColor)
            GUIGorgeQoL.clogText:SetText("0")
        elseif clogCurrent > 0 and clogCurrent < clogMax and GUIGorgeQoL.oldclogCount ~= clogCurrent then
            GUIGorgeQoL.oldclogCount = clogCurrent
            GUIGorgeQoL.clog:SetColor(GUIGorgeQoL.kDeployedColor)
            GUIGorgeQoL.clogText:SetText(tostring(clogCurrent))
        elseif clogCurrent >= clogMax and GUIGorgeQoL.oldclogCount ~= clogMax then
            GUIGorgeQoL.oldclogCount = clogMax
            GUIGorgeQoL.clog:SetColor(GUIGorgeQoL.kHurtColor1)
            GUIGorgeQoL.clogText:SetText(tostring(clogCurrent))
        end

        --print("Hydra: " .. tostring(hydraCurrent))
--        print("HydraMax: " .. tostring(hydraMax))
        --print("bilemine: " .. tostring(bileMineCurrent))
--        print("bilemineMax: " .. tostring(bileMineMax))
        --print("clog: " .. tostring(clogCurrent))
--        print("clogMax: " .. tostring(clogMax))
        --print("web: " .. tostring(webCurrent))
--        print("webMax: " .. tostring(webMax))
    end
end

function Gorge:OnUpdatePlayer(deltaTime)
    if Server then print("QoL UPDATE..........Server" .. tostring(deltaTime)) end
    if Predict then print("QoL UPDATE..........Predict" .. tostring(deltaTime)) end
    if Client then print("QoL UPDATE..........Client" .. tostring(deltaTime)) end
    --Alien.OnUpdate(self, deltaTime)
end
