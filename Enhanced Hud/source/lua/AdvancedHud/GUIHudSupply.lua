
local kLowCountTextColorRed = HexToColor("f44848") -- red
local kLowCountTextColorOrange = HexToColor("f47b00") -- orange
local kLowCountTextColorYellow = HexToColor("f4f400") -- yellow


function GUIHudSupply:UpdateSupplyText()
    local supply = self:GetSupply()
    local supplyMax = self:GetSupplyMax()
   
    a_hud_enabled = Client.GetOptionBoolean("a_hud_enabled", true)

    if a_hud_enabled then 
        if supply + 25 >= supplyMax then -- turn red 
            self:GetTextObj():SetColor(kLowCountTextColorRed)
        elseif supply + 40 >= supplyMax then -- turn orange
            self:GetTextObj():SetColor(kLowCountTextColorOrange)
        elseif supply + 65 >= supplyMax then -- turn yellow
            self:GetTextObj():SetColor(kLowCountTextColorYellow)
        else 
            self:GetTextObj():SetColor(1, 1, 1, 1)
        end
    else 
        self:GetTextObj():SetColor(1, 1, 1, 1)
    end

    self:GetTextObj():SetText(string.format("%d / %d", supply, supplyMax))
end