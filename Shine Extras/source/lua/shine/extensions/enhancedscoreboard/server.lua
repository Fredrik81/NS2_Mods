local Plugin = Plugin
local Shine = Shine
local AdvancedServerOptions = AdvancedServerOptions

--Script.Load("lua/shine/extensions/ESBplus/crypt/salsa20.lua")

Plugin.HasConfig = true
Plugin.ConfigName = "EnhancedScoreboard.json"

Plugin.DefaultConfig = {
	EnableTeamAvgSkill = false,
	EnableTeamAvgSkillPregame = false,
	EnableTeamTotalSkill = false,
	EnableLocationInfo = true,
	EnableQueueInfo = true,
	EnableShowAdmin = false
}

Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

local fetchIpData = "http://ip-api.com/json/%s?fields=status,proxy,country"
--http://www.geoplugin.net/json.gp?ip=%s --all fields

-- Round function implementation with round up and decimal
local function round(number, decimals)
	if number and IsNumber(number) then
		if decimals > 0 then
			decimals = 10 ^ decimals
			number = number * decimals
			number = number % 1 >= 0.5 and math.ceil(number) or math.floor(number)
			number = number / decimals
		else
			number = number % 1 >= 0.5 and math.ceil(number) or math.floor(number)
		end

		return tostring(number)
	else
		return "NaN"
	end
end

local function roundNumber(number, decimals)
	if number and IsNumber(number) then
		if decimals > 0 then
			decimals = 10 ^ decimals
			number = number * decimals
			number = number % 1 >= 0.5 and math.ceil(number) or math.floor(number)
			number = number / decimals
		else
			number = number % 1 >= 0.5 and math.ceil(number) or math.floor(number)
		end

		return number
	else
		return 0
	end
end

local function ahumanNumber(i)
	return tostring(i):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local function humanNumber(number)
	if number and IsNumber(number) then
		if number > 1000000 then
			number = number / 10000
			number = number % 1 >= 0.5 and math.ceil(number) or math.floor(number)
			number = number / 100
			number = tostring(number) .. "m"
		elseif number > 1000 then
			number = number / 100
			number = number % 1 >= 0.5 and math.ceil(number) or math.floor(number)
			number = number / 10
			number = tostring(number) .. "k"
		end

		return tostring(number)
	else
		return "NaN"
	end
end

local function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

function Plugin.Gen_playerData_Client(steamId)
	local result = nil

	-- Client data
	if Plugin.PlayerTable[steamId] and Plugin.PlayerTable[steamId].location and Plugin.PlayerTable[steamId].hive then -- Has data
		local pData = Plugin.PlayerTable[steamId]
		result = string.format("%i,%s,%s,%s", steamId, pData.adminData or false, pData.location.country or "Unknown", pData.location.proxy or "Unknown")
	end
	-- hive.com_time_played hive.time_played location.country location.proxy
	return result
end

local function isIpAddress(ip)
	if not ip then
		return false
	end
	local a, b, c, d = ip:match("^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$")
	a = tonumber(a)
	b = tonumber(b)
	c = tonumber(c)
	d = tonumber(d)
	if not a or not b or not c or not d then
		return false
	end
	if a < 0 or 255 < a then
		return false
	end
	if b < 0 or 255 < b then
		return false
	end
	if c < 0 or 255 < c then
		return false
	end
	if d < 0 or 255 < d then
		return false
	end
	return true
end

function Plugin.SendPlayerData(to, steamId)
	local message = {p = ""}

	if steamId and steamId == 0 then
		return
	elseif steamId and steamId ~= 0 then
		message.p = Plugin.Gen_playerData_Client(steamId)
		if message.p then
			if (to) then
				Server.SendNetworkMessage(to, Plugin.kMsgDataName, message, true)
			else
				Server.SendNetworkMessage(Plugin.kMsgDataName, message, true)
			end
		else
			return --Data not existing so exit..
		end
	elseif not steamId then
		for client in Shine.IterateClients() do
			local sid = client:GetUserId() -- Steamid

			if sid ~= 0 then
				message.p = Plugin.Gen_playerData_Client(sid)
				if message.p then -- data not existing for player
					if (to) then
						Server.SendNetworkMessage(to, Plugin.kMsgDataName, message, true)
					else
						Server.SendNetworkMessage(Plugin.kMsgDataName, message, true)
					end
				end
			end
		end
	end
end

local function getClientLocationData(client)
	local ip = IPAddressToString(Server.GetClientAddress(client))
	local steamId = client:GetUserId()
	if not isIpAddress(ip) then
		return
	end
	if ip == "127.0.0.1" then
		ip = "104.200.132.180"
		ip = "1.1.1.1"
	end
	Shared.SendHTTPRequest(
		string.format(fetchIpData, ip),
		"GET",
		{},
		function(data)
			if not data then
				return
			end
			local tdata = json.decode(data)
			--print("DumpLocationFeatch: " .. dump(tdata))
			if tdata and tdata.status and tdata.status == "success" and tdata.country then
				local sid = steamId
				local temp = {}
				temp.country = tdata.country
				temp.proxy = tostring(tdata.proxy)
				Plugin.PlayerTable[steamId].location = temp
				--print("Sending data: " .. dump(Plugin.PlayerTable[steamId]))
				Plugin.SendPlayerData(nil, steamId)
			end
		end
	)
end

-- Compares whether keys exist in one table from the other
function Plugin.TableKeyDiff(table1, table2)
	for k, v in pairs(table1) do
		if k ~= "__Version" and table2[k] == nil then
			return true
		end
	end
	for k, v in pairs(table2) do
		if k ~= "__Version" and table1[k] == nil then
			return true
		end
	end

	return false
end

-- Merges another table, while removing keys which no longer exist. Enabling config file updates.
function Plugin.TableBaseCopy(base, migrate)
	local new = table.Copy(base)

	for k, v in pairs(migrate) do
		if base[k] ~= nil then
			new[k] = migrate[k]
		end
	end

	return new
end

function Plugin.Encrypt(str)
	return string.ToBase64(Plugin.salsa20.encrypt({112, 41, 138, 59, 2, 227, 189, 32, 17, 136, 229, 28, 98, 193, 240, 112, 243, 164, 70, 170, 2, 89, 118, 140, 158, 108, 73, 201, 83, 73, 143, 245}, {214, 99, 234, 53, 159, 86, 232, 213}, str, 20))
end

-- Defines
function Plugin:Initialise()
	-- Update changed config fields (add & remove fields)
	if self.TableKeyDiff(Plugin.DefaultConfig, self.Config) then -- Change to default config
		self.Config = self.TableBaseCopy(Plugin.DefaultConfig, self.Config)
		self:SaveConfig()
	end

	AdvancedServerOptions["savestats"].currentValue = true -- Force enable stats saving

	self:CreateHooks()

	self.dt.EnableTeamAvgSkill = self.Config.EnableTeamAvgSkill -- or Plugin.DefaultConfig.EnableTeamAvgSkill
	self.dt.EnableTeamAvgSkillPregame = self.Config.EnableTeamAvgSkillPregame -- or Plugin.DefaultConfig.EnableTeamAvgSkillPregame
	self.dt.EnableTeamTotalSkill = self.Config.EnableTeamTotalSkill -- or Plugin.DefaultConfig.EnableTeamTotalSkill
	self.dt.EnableQueueInfo = self.Config.EnableQueueInfo
	self.dt.EnableShowAdmin = self.Config.EnableShowAdmin

	self.QueueIndex = {}
	self.PlayerTable = {}

	self.lastBanCount = 0
	self.lastServerName = ""

	if not GetHiveDataBySteamId then
		self.Enabled = false
		return false, "You need [Shine] Epsilon enabled!"
	end

	self.Enabled = true
	return true
end

function Plugin:ClientConnect(client)
	if (Shine:IsValidClient(client) and client:GetUserId() ~= 0) then
		Plugin.SendPlayerData(client, nil)
	end
end

function Plugin:adminDataPermission(client, steamId)
	if Shine:HasAccess(client, "sh_esbinfo") then
		print("Have: sh_esbinfo")
		return true
	end

	if Shine:GetUserImmunity(client) > 0 then
		print("Immunity...")
		return true
	end

	return false
end

function Plugin:RecHiveData(client, data)
	if (Shine:IsValidClient(client) and client:GetUserId() ~= 0) then
		local steamId = client:GetUserId()
		if not self.PlayerTable[steamId] then
			self.PlayerTable[steamId] = {}
		end
		if data then
			self.PlayerTable[steamId].hive = data
			self.PlayerTable[steamId].adminData = Plugin:adminDataPermission(client, steamId)
			--print("HiveDump: " .. dump(data))
			if self.Config.EnableLocationInfo and (not self.PlayerTable[steamId].location) then
				--HPrint("Featch player location!")
				getClientLocationData(client)
				--HPrint("Got location: " .. dump(self.PlayerTable[steamId].location))
			elseif self.Config.EnableLocationInfo then
				Plugin.SendPlayerData(nil, steamId)
			end
		end
	end
end

function Plugin:CreateHooks()
	Shine.Hook.Add(
		"PostJoinTeam",
		"ESB_PostJoinTeam",
		function(Gamerules, Player, NewTeam, Force)
			Plugin.SendESB_TeamAverages()
		end
	)

	-- Update tier info server and retrieve updated data (hive often fails to respond)
	Shine.Hook.Add(
		"OnReceiveHiveData",
		"TierInfo_OnReceiveHiveData",
		function(client, data)
			if (not data) or (not Shine:IsValidClient(client)) then
				return
			end

			self:RecHiveData(client, data)
		end
	)

	local plugin = self
	local RRQ = Shine.Plugins.readyroomqueue
	if RRQ then
		local RRQDequeue = RRQ.Dequeue
		function RRQ:Dequeue(client)
			if (RRQDequeue(self, client)) then
				if plugin.Config.EnableQueueInfo then
					for sid, index in self.PlayerQueue:Iterate() do
						local tempClient = Shine.GetClientByNS2ID(sid)
						if (tempClient) then
							plugin.QueueIndex[tostring(tempClient:GetId())] = index
						end
					end

					plugin.QueueIndex[tostring(client:GetId())] = nil

					plugin.dt.QueueIndex = json.encode(plugin.QueueIndex)
					plugin.dt.QueueIndexId = plugin.dt.QueueIndexId + 1
				end
				return true
			end

			return false
		end

		local RRQEnqueue = RRQ.Enqueue
		function RRQ:Enqueue(client)
			RRQEnqueue(self, client)
			if plugin.Config.EnableQueueInfo then
				for sid, index in self.PlayerQueue:Iterate() do
					local tempClient = Shine.GetClientByNS2ID(sid)
					if (client == tempClient) then
						plugin.QueueIndex[tostring(client:GetId())] = index
					end
				end

				plugin.dt.QueueIndex = json.encode(plugin.QueueIndex)
				plugin.dt.QueueIndexId = plugin.dt.QueueIndexId + 1
			end
		end
	end
end

function Plugin:SaveConfig()
	local Path = Server and Shine.Config.ExtensionDir .. self.ConfigName or ClientConfigPath .. self.ConfigName
	local Success, Err = Shine.SaveJSONFile(self.Config, Path)
	if not Success then
		PrintToLog("[Error] Error writing %s config file: %s", self.__Name, Err)
		return false
	end
end

function Plugin:GetTeamsAvgSkill()
	if Shine.Plugins.voterandom and Shine:IsExtensionEnabled("voterandom") then
		local voterandom = Shine.Plugins.voterandom
		local teamStats = voterandom:GetTeamStats()

		return {math.max(0, teamStats[1].Average), math.max(0, teamStats[2].Average)}
	end

	return {0, 0}
end

function Plugin:GetTeamsTotalSkill()
	if Shine.Plugins.voterandom and Shine:IsExtensionEnabled("voterandom") then
		local voterandom = Shine.Plugins.voterandom
		local teamStats = voterandom:GetTeamStats()

		return {math.max(0, teamStats[1].Total), math.max(0, teamStats[2].Total)}
	end

	return {0, 0}
end

function Plugin:SendESB_TeamAverages()
	if Plugin.dt.EnableTeamAvgSkill or Plugin.dt.EnableTeamAvgSkillPregame then
		local avgSkills = Plugin.GetTeamsAvgSkill()
		Plugin.dt.marine_avg_skill = avgSkills[1]
		Plugin.dt.alien_avg_skill = avgSkills[2]
	end

	if Plugin.dt.EnableTeamTotalSkill then
		local totalSkills = Plugin.GetTeamsTotalSkill()
		Plugin.dt.marine_total_skill = totalSkills[1]
		Plugin.dt.alien_total_skill = totalSkills[2]
	end
end
