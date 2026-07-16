
local kLowCountTextColorRed = HexToColor("f44848") -- red
local kLowCountTextColorOrange = HexToColor("f47b00") -- orange
local kLowCountTextColorYellow = HexToColor("f4f400") -- yellow


function GUIHudTres:UpdateTresText()
    local tres = self:GetTres()

    a_hud_enabled = Client.GetOptionBoolean("a_hud_enabled", true)

    if a_hud_enabled then 
        if tres == 0 or tres >= 50 then -- turn red 
            self:GetTextObj():SetColor(kLowCountTextColorRed)
        elseif tres >= 40 then -- turn orange
            self:GetTextObj():SetColor(kLowCountTextColorOrange)
        elseif tres >= 30 then -- turn yellow
            self:GetTextObj():SetColor(kLowCountTextColorYellow)
        else 
            self:GetTextObj():SetColor(1, 1, 1, 1)
        end
    else 
        self:GetTextObj():SetColor(1, 1, 1, 1)
    end

    self:GetTextObj():SetText(tostring(tres))
end