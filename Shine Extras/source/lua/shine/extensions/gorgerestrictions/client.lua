local Plugin = ...

local timeRestriction = 15 -- seconds
local lifeformRestriction = 2 -- number of gorges

local function GetCountByStatus(team, status, partof)
	local count = 0
	for index, item in ipairs(team) do
		if partof and string.find(item["Status"], status) then
			count = count + 1
            --print("Found partial match: " .. item["Status"])
		elseif status == item["Status"] then
			count = count + 1
            --print("Found exact match: " .. item["Status"])
		end
	end
	return count
end

function Plugin:GorgeRestrict(purchaseTable)
    -- If gametime is beyond 30seconds, do not restrict
    local gameTime, state = PlayerUI_GetGameLengthTime()

    -- Return is not an active game
    if state ~= kGameState.Started then
        return
    end

    -- Return after restricted time
    if gameTime > timeRestriction then
        return
    end

    local isGorgePurchase = false

    for _, purchase in ipairs(purchaseTable) do
        if purchase.Type == "Alien" then
            if IndexToAlienTechId(purchase.Alien) == kTechId.Gorge then
                isGorgePurchase = true
            end
        end
    end

    if not isGorgePurchase then
        return
    end

    -- Get current lifeform
    local player = Client.GetLocalPlayer()
    if player and player:isa("Gorge") then
        return
    end

    -- Force reload of scoreboard data
    --print("Reloading scoreboard data for gorge restriction check.")
    Scoreboard_ReloadPlayerData()

    -- Check how many gorges or gorge eggs we already have
    local teamScores = ScoreboardUI_GetRedScores()
    lifeformCount = GetCountByStatus(teamScores, Locale.ResolveString("STATUS_GORGE"), true)
    --print("Current gorge count: " .. tostring(lifeformCount))
    if lifeformCount < lifeformRestriction then
        return
    end

    if isGorgePurchase then
        self:Notify("Maximum Gorges reached (" .. tostring(lifeformRestriction) .. ") for first " .. tostring(timeRestriction) .. "sec.")
        StartSoundEffect("sound/NS2.fev/common/button_click")
        return true
    end
end

function Plugin:Initialise()
    self.Enabled = true

    -- Only load on gamemode ns2
    if GetGamemode() and GetGamemode() == "ns2" then
        --Shared.Message("Loading " .. tostring(Plugin.PrintName) .. ", v" .. tostring(Plugin.Version))
        HPrint(Plugin.PrintName .. ", version " .. tostring(Plugin.Version))
    else
        Shared.Message(tostring(Plugin.PrintName) .. ", v" .. tostring(Plugin.Version) .. ", Disabled because non-standard game mode.")
        self.Enabled = false
        return
    end

    --HPrint(Plugin.PrintName .. ", version " .. tostring(Plugin.Version))

    Shine.Hook.SetupGlobalHook("AlienBuy_Purchase", "GorgeRestrict", "Halt")

    return true
end

function Plugin:Cleanup()
    self.BaseClass.Cleanup(self)
    self.Enabled = false
end
