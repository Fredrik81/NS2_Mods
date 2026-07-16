
local kLowCountTextColorRed = HexToColor("f44848") -- red
local kLowCountTextColorOrange = HexToColor("f47b00") -- orange
local kLowCountTextColorYellow = HexToColor("f4f400") -- yellow


function GUIHudDeadCount:UpdateDeadCountText()
    local deadCount = self:GetDeadCount()

    a_hud_enabled = Client.GetOptionBoolean("a_hud_enabled", true)

    if a_hud_enabled then 
        if deadCount > 3 then -- turn red 
            self:GetTextObj():SetColor(kLowCountTextColorRed)
        elseif deadCount > 2 then -- turn orange
            self:GetTextObj():SetColor(kLowCountTextColorOrange)
        elseif deadCount > 1 then -- turn yellow
            self:GetTextObj():SetColor(kLowCountTextColorYellow)
        else 
            self:GetTextObj():SetColor(1, 1, 1, 1)
        end
    end
    self:GetTextObj():SetText(tostring(deadCount))
end