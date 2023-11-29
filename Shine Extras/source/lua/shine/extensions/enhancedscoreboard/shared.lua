local Plugin = Shine.Plugin(...)

Plugin.PrintName = "Devnull - [Shine] Enhanced Scoreboard"
Plugin.PrintVersion = "1.2"
Plugin.Version = "1.0"
Plugin.DefaultState = true

Plugin.Conflicts = {
	-- Which plugins should we force to be disabled if they're enabled and we are?
	DisableThem = {
		"tier_info",
		"tierinfoplus"
	}
}

Plugin.PlayerData = {}

local Max = math.max

function Plugin.Dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			--if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '"' .. k .. '": ' .. Plugin.Dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

function Plugin.Split(str, sep)
	local array = {}
	local reg = string.format("([^%s]+)", sep)
	for mem in string.gmatch(str, reg) do
		table.insert(array, mem)
	end
	return array
end

function Plugin.GetTeamsAvgSkill(skill, skillOffset)
	return Max(0, skill + skillOffset), Max(0, skill - skillOffset) -- Marine, Alien
end

-- Fix base ns2 bug
function BindingsUI_GetInputValue(controlId)
	if (not controlId) then
		return ""
	end

	local value = Client.GetOptionString("input/" .. controlId, "")

	local rc = ""

	if (value ~= "") then
		rc = value
	else
		rc = GetDefaultInputValue(controlId)
		if (rc ~= nil) then
			Client.SetOptionString("input/" .. controlId, rc)
		end
	end

	return rc
end

--This will setup a datatable for the plugin, which is a table of networked values.
--local MAX_SMURF_LENGTH = 450
local MAX_PLAYER_LENGTH = 1800
function Plugin:SetupDataTable()
	self:AddDTVar("boolean", "EnableTeamAvgSkill", false)
	self:AddDTVar("boolean", "EnableTeamAvgSkillPregame", true)
	self:AddDTVar("boolean", "EnableTeamTotalSkill", true)
	self:AddDTVar("boolean", "EnableTeamAvgSph", true)
	self:AddDTVar("boolean", "EnableTierSkill", true)
	self:AddDTVar("boolean", "EnableQueueInfo", true)
	self:AddDTVar("integer (0 to 2147483647)", "QueueIndexId", 0)
	self:AddDTVar(string.format("string (%d)", 254), "QueueIndex", "{}")
	self:AddDTVar("integer (0 to 65535)", "marine_avg_skill", 0)
	self:AddDTVar("integer (0 to 65535)", "alien_avg_skill", 0)
	self:AddDTVar("integer (0 to 65535)", "marine_total_skill", 0)
	self:AddDTVar("integer (0 to 65535)", "alien_total_skill", 0)
	self:AddDTVar("integer (0 to 65535)", "marine_avg_sph", 0)
	self:AddDTVar("integer (0 to 65535)", "alien_avg_sph", 0)
end

--This is called when any datatable variable changes.
--function Plugin:NetworkUpdate( Key, Old, New )
--	if Server then return end

--Key is the variable name, Old and New are the old and new values of the variable.
--Print( "%s has changed from %s to %s.", Key, tostring( Old ), tostring( New ) )
--end

---- Start Message Register ----

Plugin.kMsgDataName = "ESB_PlayerData"
Plugin.kMsgDataInfo = {p = string.format("string (%d)", MAX_PLAYER_LENGTH)}

Plugin.kMsgPermName = "ESB_Perm"
Plugin.kMsgPermInfo = {perm = string.format("string (%d)", 20)} -- Admin on ns2panel, etc

Plugin.kMsgLastRoundName = "ESB_RoundInfo"
Plugin.kMsgLastRoundInfo = {round_id = "integer (0 to 2147483647)"} -- Supplies round for commands: !lastround, sh_lastround
--

Shared.RegisterNetworkMessage(Plugin.kMsgDataName, Plugin.kMsgDataInfo)
Shared.RegisterNetworkMessage(Plugin.kMsgPermName, Plugin.kMsgPermInfo)
Shared.RegisterNetworkMessage(Plugin.kMsgLastRoundName, Plugin.kMsgLastRoundInfo)
---- End Message Register ----

return Plugin
