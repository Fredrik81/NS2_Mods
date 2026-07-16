

local kLowCountTextColorRed = HexToColor("f44848") -- red
local kLowCountTextColorOrange = HexToColor("f47b00") -- orange
local kLowCountTextColorYellow = HexToColor("f4f400") -- yellow





function GUIHudEggCount:UpdateEggCountText()
    local eggCount = self:GetEggCount()
    
    a_hud_enabled = Client.GetOptionBoolean("a_hud_enabled", true)

    if a_hud_enabled then 
        if eggCount == 0 then -- turn red 
            self:GetTextObj():SetColor(kLowCountTextColorRed)
        elseif eggCount == 1 then -- turn orange
            self:GetTextObj():SetColor(kLowCountTextColorOrange)
        elseif eggCount == 2 then -- turn yellow
            self:GetTextObj():SetColor(kLowCountTextColorYellow)
        else 
            self:GetTextObj():SetColor(1, 1, 1, 1)
        end
    end

    
    self:GetTextObj():SetText(tostring(eggCount))
end

