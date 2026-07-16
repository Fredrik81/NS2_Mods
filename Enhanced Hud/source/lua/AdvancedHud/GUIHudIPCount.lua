

local kLowCountTextColorRed = HexToColor("f44848") -- red
local kLowCountTextColorOrange = HexToColor("f47b00") -- orange
local kLowCountTextColorYellow = HexToColor("f4f400") -- yellow



function GUIHudIPCount:UpdateInfantryPortalCountText()
    local ipCount = self:GetInfantryPortalCount()
    
    a_hud_enabled = Client.GetOptionBoolean("a_hud_enabled", true)

    if a_hud_enabled then 
        if ipCount == 0 then -- turn red 
            self:GetTextObj():SetColor(kLowCountTextColorRed)
        elseif ipCount == 1 then -- turn orange
            self:GetTextObj():SetColor(kLowCountTextColorOrange)
        elseif ipCount == 2 then -- turn yellow
            self:GetTextObj():SetColor(kLowCountTextColorYellow)
        else 
            self:GetTextObj():SetColor(1, 1, 1, 1)
        end
    end

    if ipCount >= kMarineTeamInfoMaxInfantryPortalCount then
        self:GetTextObj():SetText(string.format("%d+", kMarineTeamInfoMaxInfantryPortalCount-1))
    else
        self:GetTextObj():SetText(string.format("%d", ipCount))
    end
end
