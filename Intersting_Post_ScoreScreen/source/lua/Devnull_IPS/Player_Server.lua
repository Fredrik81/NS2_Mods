--
-- Repalced and additional functions
--

function Player:ProcessBuyAction(techIds)
    ASSERT(type(techIds) == "table")
    ASSERT(table.icount(techIds) > 0)

    local techTree = self:GetTechTree()
    local totalCost = 0
    local validBuyIds = {}

    for i, techId in ipairs(techIds) do
        local techNode = techTree:GetTechNode(techId)
        if (techNode ~= nil and techNode.available) and not self:GetHasUpgrade(techId) then
            local cost = GetCostForTech(techId)
            if cost ~= nil then
                totalCost = totalCost + cost
                table.insert(validBuyIds, techId)
            end
        else
            break
        end
    end
    if totalCost <= self:GetResources() then
        for i, techId in ipairs(validBuyIds) do
            --print("Bought (" .. tostring(techId) .. "):" .. EnumToString(kTechId, techId))
            StatsUI_RegisterPurchase(techId)
        end

        if self:AttemptToBuy(validBuyIds) then
            self:AddResources(-totalCost)

            return true
        end
    else
        Print("not enough resources sound server")
        Server.PlayPrivateSound(self, self:GetNotEnoughResourcesSound(), self, 1.0, Vector(0, 0, 0))
    end

    return false
end
