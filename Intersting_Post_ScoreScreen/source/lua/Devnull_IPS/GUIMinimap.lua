local mapCheckStart = 0
local mapCheckFlag = false

function MapCheckStartStopTimer(mode, comment)
	if mode == 1 and mapCheckFlag == false then
		mapCheckStart  = Shared.GetTime()
		mapCheckFlag = true
		--print("Start timer " .. tostring(comment))
	end
	if mode == 2 and mapCheckFlag == true then
		mapCheckTime = Shared.GetTime() - mapCheckStart
		mapCheckFlag = false
		--print("Showed map for " .. tostring(mapCheckTime) .. " " .. tostring(comment))
		if mapCheckTime > 0 and (Client.GetLocalPlayer():GetTeamNumber() == 1 or Client.GetLocalPlayer():GetTeamNumber() == 2) then
			--print("Sending mapcheck message ".. tostring(mapCheckTime))
			Client.SendNetworkMessage( "mapCheckTime", { mapCheckTime = mapCheckTime, teamNumber = Client.GetLocalPlayer():GetTeamNumber()}, true)
		end
	end

end

local oldShowMap = GUIMinimap.ShowMap

-- Shows or hides the big map.
function GUIMinimap:ShowMap(showMap)

	if showMap then MapCheckStartStopTimer(1, 'minimap:showmap true') end
	if not showMap then MapCheckStartStopTimer(2, 'minimap:showmap false') end

    oldShowMap(self, showMap)
	
end
