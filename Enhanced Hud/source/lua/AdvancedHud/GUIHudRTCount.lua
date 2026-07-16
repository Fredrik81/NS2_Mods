local kLowCountTextColorRed = HexToColor("f44848") -- red
local kLowCountTextColorOrange = HexToColor("f47b00") -- orange
local kLowCountTextColorYellow = HexToColor("f4f400") -- yellow

local function GetTotalRTCount()
    local resourcePoints = Shared.GetEntitiesWithClassname("ResourcePoint")
    if resourcePoints and resourcePoints.GetSize then
        return resourcePoints:GetSize()
    end

    if GetEntities then
        local entitiesTable = GetEntities("ResourcePoint")
        if entitiesTable then
            return #entitiesTable
        end
    end

    return 0
end

function GUIHudRTCount:GetMaxWidthText()
    return "00 / 00"
end

function GUIHudRTCount:UpdateRTCountText()
    local rtCount = self:GetRTCount()
    local totalRTCount = GetTotalRTCount()

    local textObj = self:GetTextObj()

    if not self.totalRTText then
        self.totalRTText = CreateGUIObject("totalRTText", GUIText, self.textHolder)
        self.totalRTText:SetFontSize(18)
        self.totalRTText:SetFontFamily("AgencyBold")
        self.totalRTText:SetDropShadowEnabled(true)
        self.totalRTText:AlignLeft()
        self.totalRTText:SetColor(1, 1, 1, 1)
    end

    local ahudEnabled = Client.GetOptionBoolean("a_hud_enabled", true)

    if ahudEnabled then
        if rtCount == 0 then -- turn red
            textObj:SetColor(kLowCountTextColorRed)
        elseif rtCount == 1 then -- turn orange
            textObj:SetColor(kLowCountTextColorOrange)
        elseif rtCount == 2 then -- turn yellow
            textObj:SetColor(kLowCountTextColorYellow)
        else
            textObj:SetColor(1, 1, 1, 1)
        end
    else
        textObj:SetColor(1, 1, 1, 1)
    end

    textObj:SetText(tostring(rtCount))

    self.totalRTText:SetText(" / " .. tostring(totalRTCount))
    self.totalRTText:SetPosition(textObj:GetSize().x, 0)
end
