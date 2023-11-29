local StringFormat = string.format
local IsType = Shine.IsType

local Plugin = ...

Plugin.HasConfig = false

function Plugin:Initialise()
	self.Enabled = true

	--create Commands
	self:CreateCommands()

	--create hooks
	--self:CreateHooks()

	return true
end
function Plugin:ClientConnect(Client)
	if Client and Shine:IsValidClient(Client) then
		Shine.Timer.Simple(
			7,
			function(Timer)
				self:PlaySoundForPlayer(Client, "Connected")
			end
		)
	end
end

function Plugin:PostJoinTeam(Gamerules, Player, OldTeam, NewTeam, Force, ShineForce)
	local Client = Player:GetClient()
	if not Client then
		return
	end

	if OldTeam == 3 and NewTeam == 0 then
		self:PlaySoundForPlayer(Client, "QueueDone")
	end
end

function Plugin:PlaySoundForPlayer(Player, SoundName)
	self:SendNetworkMessage(Player, "PlaySound", {soundName = SoundName}, true)
end

function Plugin:CreateCommands()
	local CSound =
		self:BindCommand(
		"sh_dfn",
		"sounds",
		function(Client, Value)
			-- 0 = nil, 1 = false, 2 = true
			if Value == nil then
				Value = 0
			elseif Value then
				--noinspection UnusedDef
				Value = 2
			else
				Value = 1
			end

			self:SendNetworkMessage(Client, "Command", {Name = "Sounds", Value = Value}, true)
		end,
		true,
		true
	)
	CSound:AddParam {Type = "boolean", Optional = true}
	CSound:Help("<boolean> Allows you to set if killstreak sounds should be played for you or not.")

	local CVolume =
		self:BindCommand(
		"sh_dfnvolume",
		"soundvolume",
		function(Client, Value)
			self:SendNetworkMessage(Client, "Command", {Name = "SoundVolume", Value = Value}, true)
		end,
		true,
		true
	)
	CVolume:AddParam {Type = "number", Min = 0, Max = 200, Round = true, Error = "Please set a value between 0 and 200. Any value outside this limit is not allowed"}
	CVolume:Help("<volume in percent> Set the killstreak's sound volume to whatever you like between 0 and 200%")
end

function Plugin:SetGameState(Gamerules, NewState, OldState)
	if NewState == kGameState.Countdown then
		self:SendNetworkMessage(nil, "PlaySound", {soundName = "RoundStarting"}, true)
	end
end

function Plugin:CreateHooks()
	Shine.Hook.Add(
		"ClientConfirmConnect",
		"DFN_ClientConfirmConnect",
		function(client)
			if (Shine:IsValidClient(client)) then
				--print("============== Client connected...")
				--self:SendNetworkMessage(nil, "PlaySound", {soundName = "Connected"}, true)
			end
		end
	)
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup(self)

	self.Enabled = false
end
