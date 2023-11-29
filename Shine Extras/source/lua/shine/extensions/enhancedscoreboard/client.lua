local Shine = Shine
local Plugin = Plugin

--Script.Load("lua/shine/extensions/ESBplus/client_utils.lua")
--Script.Load("lua/shine/extensions/ESBplus/shared_net.lua")
--Script.Load("lua/shine/extensions/ESBplus/client_net.lua")

local hideTextShadowIds = {19849485, 68118554}

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

-- Tier skill lookup
Plugin.Skill = {
	-- New
	[1] = 300,
	[2] = 750,
	[3] = 1400,
	[4] = 2100,
	[5] = 2900,
	[6] = 4100
}

---- Client Start ----
function Plugin.RecESB_Perm(m)
	Plugin.perm = m["perm"]
end
Client.HookNetworkMessage(Plugin.kMsgPermName, Plugin.RecESB_Perm)

function Plugin.RecESB_Data(message)
	local values = Plugin.Split(message.p, ",")
	if (#values == 5) then -- Sanity check
		local data = {}
		data.steamId = tonumber(values[1])
		data.playedTime = tonumber(values[2])
		data.commanderTime = tonumber(values[3])
		data.country = values[4]
		data.region = values[5]

		--Validate steamId
		if data.steamId and data.steamId > 0 then
			Plugin.PlayerData[data.steamId] = data
		end
	end
end
Client.HookNetworkMessage(Plugin.kMsgDataName, Plugin.RecESB_Data)

--function Plugin.RecESB_LastRound(message)
--	Shared.ConsoleCommand("cl_lastround " .. message.round_id)
--end
--Client.HookNetworkMessage(Plugin.kMsgLastRoundName, Plugin.RecESB_LastRound)

-- Defines
function Plugin.CalcPlayerSkill(skill, adagradSum)
	if not skill or skill <= 0 then
		return 0
	end

	if adagradSum then
		-- capping the skill values using sum of squared adagrad gradients
		-- This should stop the skill tier from changing too often for some players due to short term trends
		-- The used factor may need some further adjustments
		if adagradSum <= 0 then
			skill = 0
		else
			skill = math.max(skill - 25 / math.sqrt(adagradSum), 0)
		end
	end

	return skill
end

function Plugin.GetPlayerSkillNextSkill(skill)
	if not skill or skill < 1 then
		return Plugin.Skill[1]
	end

	if skill > Plugin.Skill[table.count(Plugin.Skill)] then
		return 0
	end

	local lastValue = 0
	for i, value in ipairs(Plugin.Skill) do
		if skill > lastValue and skill <= value then
			return value
		end

		lastValue = value
	end
end

local admins = {19849485, 89160056, 77470693} -- Test
function Plugin.isAdmin()
	local playerData = Plugin.PlayerData[tostring(Client.GetLocalClientIndex())]
	local isAdmin = playerData and playerData.isAdmin or 0

	return (isAdmin > 0) or table.contains(admins, Client.GetSteamId()) -- Whether to display tier info stats -- string.find(Plugin.perm, "sh_tierinfo")
end

function Plugin:Initialise()
	self.QueueIndexIdLast = 0
	self.QueueIndex = {}
	self:InitReplace()
	self:CreateCommands()

	self.hideTextShadow = table.contains(hideTextShadowIds, Client.GetSteamId())

	HPrint(Plugin.PrintName .. ", v" .. Plugin.PrintVersion)

	self.Enabled = true
	return true
end

-- Open webpage with steam overlay fallback
local function openUrl(url, title)
	if (not Shine.Config.DisableWebWindows) then
		Shine:OpenWebpage(url, title)
	else
		Client.ShowWebpage(url)
	end
end

local function openUrlNs2PanelRound(round_id)
	openUrl(string.format("https://ns2panel.com/round/%s", round_id), "Tier Info - NS2 Panel")
end

function Plugin:CreateCommands()
	local function fLastRound(round_id)
		openUrlNs2PanelRound(round_id)
	end
	local cLastRound = self:BindCommand("cl_lastround", fLastRound)
	cLastRound:AddParam {Type = "string", Help = "round_id"}

	-- Hitreg test
	local function GetPing()
		local record = Scoreboard_GetPlayerRecord(Client.localClientIndex or 0)
		if (record) then
			return record.Ping
		end

		return -1
	end

	self:BindCommand(
		"sh_debug",
		function()
			Print(tostring(Plugin.HitsServer) .. " " .. tostring(Plugin.HitsClient) .. " " .. tostring(GetPing()) .. " " .. Client.GetConnectedServerAddress())
		end
	)
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup(self)
end

function Plugin:InitReplace()
	Plugin._GUIScoreboardUpdateTeam = Shine.ReplaceClassMethod("GUIScoreboard", "UpdateTeam", self.GUIScoreboardUpdateTeam)

	if table.contains(hideTextShadowIds, Client.GetSteamId()) then
		-- Fix linux performance - test
		Plugin._GUIItemSetDropShadowEnabled =
			Shine.ReplaceClassMethod(
			"GUIItem",
			"SetDropShadowEnabled",
			function(self, value)
			end
		)
		Plugin._FireMixinUpdateFireMaterial =
			Shine.ReplaceClassMethod(
			"FireMixin",
			"UpdateFireMaterial",
			function()
			end
		)
	end

	--Plugin.oldGUIScoreboardSendKeyEvent = Shine.ReplaceClassMethod("GUIScoreboard", "SendKeyEvent", Plugin.GUIScoreboardSendKeyEvent)
end

Plugin.GUIScoreboardUpdateTeam = function(scoreboard, updateTeam)
	Plugin._GUIScoreboardUpdateTeam(scoreboard, updateTeam)

	if (Plugin.QueueIndexIdLast ~= Plugin.dt.QueueIndexId) then
		Plugin.QueueIndex = json.decode(Plugin.dt.QueueIndex)
		Plugin.QueueIndexIdLast = Plugin.dt.QueueIndexId
	end

	local playerList = updateTeam["PlayerList"]
	local teamNameGUIItem = updateTeam["GUIs"]["TeamName"]
	--local teamSkillGUIItem = updateTeam["GUIs"]["TeamSkill"]
	local teamScores = updateTeam["GetScores"]()
	--local numPlayers = 0--table.icount(teamScores)
	local currentPlayerIndex = 1

	--local totalSkill = 0
	local isSpectator, isMarine, isAlien = updateTeam.TeamNumber == 0, updateTeam.TeamNumber == 1, updateTeam.TeamNumber == 2

	-- Update team rows
	for index, player in ipairs(playerList) do
		local playerRecord = teamScores[currentPlayerIndex]
		if playerRecord == nil then
			return
		end

		--local playerName = playerRecord.Name
		--local adagradSum = playerRecord.AdagradSum
		local baseSkill = playerRecord.Skill
		--local playerTierSkill = Plugin.CalcPlayerSkill(baseSkill, adagradSum)
		local clientIndex = playerRecord.ClientIndex
		local steamId = GetSteamIdForClientIndex(clientIndex)

		local playerData = Plugin.PlayerData[tostring(clientIndex)]
		local marineSkill, alienSkill = Plugin.GetTeamsAvgSkill(baseSkill, playerData and playerData.skill_offset or 0)
		--local playerSkill = (isMarine and marineSkill) or (isAlien and alienSkill) or 0
		--local isCommander = playerData and playerData.IsCommander or false

		--[[if (baseSkill ~= -1) then -- Only count actual players, not bots
      numPlayers = numPlayers + 1;
      totalSkill = totalSkill + playerSkill;
    end--]]
		-- Insert into the badge hover action
		if not scoreboard.hoverMenu.background:GetIsVisible() and not MainMenu_GetIsOpened() then
			if MouseTracker_GetIsVisible() then
				local mouseX, mouseY = Client.GetCursorPosScreen()
				local skillIcon = player.SkillIcon
				if skillIcon:GetIsVisible() and GUIItemContainsPoint(skillIcon, mouseX, mouseY) then
					--local nextSkill = Plugin.GetPlayerSkillNextSkill(playerTierSkill)

					if skillIcon.tooltipText == "Skill Tier: Bot (-1)" then
						scoreboard.badgeNameTooltip:SetText("Bot")
					elseif string.match(skillIcon.tooltipText, "KDR:") then
						local description = skillIcon.tooltipText

						--Add extended info if exist..
						if Plugin.PlayerData[steamId] then
							--description = description .. string.format("\n\nGametime: %s hours", Plugin.PlayerData[steamId].playedTime)
							--description = description .. string.format("\nCommanding: %s hours", Plugin.PlayerData[steamId].commanderTime)
							description = description .. string.format("\n\nCountry: %s", Plugin.PlayerData[steamId].country)
							--description = description .. string.format("\nRegion: %s", Plugin.PlayerData[steamId].region)
						end

						if isSpectator then
							local queueIndex = Plugin.QueueIndex[tostring(clientIndex)]
							if (queueIndex) then
								description = description .. string.format("\nQueue: %i", queueIndex)
							end
						end
						skillIcon.tooltipText = description
						scoreboard.badgeNameTooltip:SetText(description)
					end
				end
			end
		end
		if isSpectator and Plugin.dt.EnableQueueInfo then
				local queueIndex = Plugin.QueueIndex[tostring(clientIndex)]
				if (queueIndex) then
					player.Status:SetText(string.format("Queue: %i", queueIndex))
				end
		end
		currentPlayerIndex = currentPlayerIndex + 1
	end

	-- Update team skill header
	if (Plugin.dt.EnableTeamAvgSkill or (Plugin.dt.EnableTeamAvgSkillPregame and (not GetGameInfoEntity():GetGameStarted()))) and (not Plugin.dt.EnableNsl) then -- Display when enabled in pregame or during if configured as such
		if updateTeam.TeamNumber >= 1 and updateTeam.TeamNumber <= 2 then --and numPlayers > 0 then -- Display for only aliens or marines
			local avgSkill = (updateTeam.TeamNumber == 1) and Plugin.dt.marine_avg_skill or Plugin.dt.alien_avg_skill
			local totalSkill = (updateTeam.TeamNumber == 1) and Plugin.dt.marine_total_skill or Plugin.dt.alien_total_skill

			--
			--local teamAvgSkill = totalSkill / numPlayers
			local teamHeaderText = teamNameGUIItem:GetText()
			teamHeaderText = string.sub(teamHeaderText, 1, string.len(teamHeaderText) - 1) -- Original header

			teamHeaderText = teamHeaderText .. string.format(", %i Avg Skill", avgSkill) -- Skill Average

			--if (Plugin:isAdmin()) then
				if (Plugin.dt.EnableTeamTotalSkill) then
					teamHeaderText = teamHeaderText .. string.format(", %s Total Skill", humanNumber(totalSkill)) -- SPH Average
				end
			--end

			teamHeaderText = teamHeaderText .. ")"
			--

			teamNameGUIItem:SetText(teamHeaderText)

		--teamSkillGUIItem:SetPosition(Vector(teamNameGUIItem:GetTextWidth(teamNameGUIItem:GetText()) + 20, 5, 0) * GUIScoreboard.kScalingFactor)
		end
	end
end

-- Add mute all button
function Plugin.GUIScoreboardSendKeyEvent(self, key, down)
	Plugin._GUIScoreboard = self
	local _backgroundGetIsVisible = self.hoverMenu.background:GetIsVisible()
	local result = Plugin.oldGUIScoreboardSendKeyEvent(self, key, down)
	do
		return result
	end

	if ChatUI_EnteringChatMessage() then
		return false
	end

	if not self.visible then
		return false
	end

	if key == InputKey.MouseButton0 then -- and self.mousePressed["LMB"]["Down"] ~= down and down and not MainMenu_GetIsOpened()
		--local steamId = GetSteamIdForClientIndex(self.hoverPlayerClientIndex)
		if _backgroundGetIsVisible then
			return false
		elseif true then --steamId ~= 0 or self.hoverPlayerClientIndex ~= 0 and Shared.GetDevMode()
			-- local isVoiceMuted = ChatUI_GetClientMuted(self.hoverPlayerClientIndex)

			local teamColorBg
			local teamColorHighlight
			-- local playerName = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "Name")
			local teamNumber = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "EntityTeamNumber")
			local isCommander = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "IsCommander")
			-- and GetIsVisibleTeam(teamNumber)

			local textColor = Color(1, 1, 1, 1)

			if isCommander then
				teamColorBg = GUIScoreboard.kCommanderFontColor
			elseif teamNumber == 1 then
				teamColorBg = GUIScoreboard.kBlueColor
			elseif teamNumber == 2 then
				teamColorBg = GUIScoreboard.kRedColor
			else
				teamColorBg = GUIScoreboard.kSpectatorColor
			end

			teamColorHighlight = teamColorBg * 0.75
			teamColorBg = teamColorBg * 0.5

			local steamId = GetSteamIdForClientIndex(self.hoverPlayerClientIndex)

			self.hoverMenu:AddButton(
				"NS2 Panel profile",
				teamColorBg,
				teamColorHighlight,
				textColor,
				function()
					openUrlNs2Panel(steamId)
				end
			)
		end
	end

	return false
end
