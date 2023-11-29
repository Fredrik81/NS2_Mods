local Notify = Shared.Message
local StringFormat = string.format

local Plugin = ...

Plugin.HasConfig = true
Plugin.ConfigName = "ForcedNotifications.json"

Plugin.DefaultConfig = {
	PlaySounds = false,
	SoundVolume = 100
}
Plugin.CheckConfig = true
Plugin.SilentConfigSave = true

function Plugin:Initialise()
	self.Enabled = true

	HPrint(Plugin.PrintName .. ", version " .. Plugin.PrintVersion)

	--Sounds
	self.Sounds = {
		["Connected"] = "sound/NS2.fev/skulk_challenge/go",
		["QueueDone"] = "sound/NS2.fev/marine/voiceovers/complete", --sound/NS2.fev/marine/voiceovers/complete
		["RoundStarting"] = "sound/NS2.fev/marine/voiceovers/game_start",
		["AFK"] = "sound/NS2.fev/skulk_challenge/go"
	}

	for _, Sound in pairs(self.Sounds) do
		--print("Precache: " .. Sound)
		Sound = Client.PrecacheLocalSound(Sound)
	end


	if Shine.AddStartupMessage then
		Shine.AddStartupMessage(StringFormat("Shine is set to %s forced notifications. You can change this with sh_dfn", self.Config.PlaySounds and "play" or "mute"))

		if self.Config.SoundVolume < 0 or self.Config.SoundVolume > 200 or self.Config.SoundVolume % 1 ~= 0 then
			Shine.AddStartupMessage("Warning: The set Sound Volume was outside the limit of 0 to 200")
			self.Config.SoundVolume = 100
		end

		if self.Config.PlaySounds then
			Shine.AddStartupMessage(StringFormat("Shine is set to play forced notifications sounds with a volume of %s . You can change this with sh_dfnvolume.", self.Config.SoundVolume))
		end
	end

	self:CreateHooks()

	return true
end

function Plugin:CreateHooks()
	local plugin = self
	local AFKKICK = Shine.Plugins.afkkick
	if AFKKICK then
		if (AFKKICK.ReceiveAFKNotify) then
			function AFKKICK:ReceiveAFKNotify(Data)
				-- Flash the taskbar icon and play a sound. Can't say we didn't warn you.
				Client.WindowNeedsAttention()
				if plugin.Config and plugin.Config.PlaySounds then
					local muteWhenMinized = Client.GetOptionBoolean(kSoundMuteWhenMinized, true)
					if muteWhenMinized then
						--Client.SetOptionBoolean(kSoundMuteWhenMinized, false)
					end
					StartSoundEffect(plugin.Sounds["AFK"], plugin.Config.SoundVolume / 100)
					HPrint("Playing [Shine] Forced Notification sound!")
					if muteWhenMinized then
						Shine.Timer.Simple(
							3,
							function(Timer)
								Client.SetOptionBoolean(kSoundMuteWhenMinized, true)
							end
						)
					end
				end
			end
		end
	end
end

function Plugin:ReceivePlaySound(Message)
	if not Message.soundName then
		return
	end

	if self.Config and self.Config.PlaySounds then
		local muteWhenMinized = Client.GetOptionBoolean(kSoundMuteWhenMinized, true)
		if muteWhenMinized then
			Client.SetOptionBoolean(kSoundMuteWhenMinized, false)
		end

		StartSoundEffect(self.Sounds[Message.soundName], self.Config.SoundVolume / 100)
		--Shared.PlaySound(self.Sounds[Message.soundName], self.Config.SoundVolume / 100)
		HPrint("Playing [Shine] Forced Notification sound!")
		--HPrint("- Sound: " .. self.Sounds[Message.soundName])
		--HPrint("- Volume: " .. tostring(self.Config.SoundVolume / 100))

		if muteWhenMinized then
			Shine.Timer.Simple(
				3,
				function(Timer)
					Client.SetOptionBoolean(kSoundMuteWhenMinized, true)
				end
			)
		end
	end
end

function Plugin:ReceiveCommand(Message)
	local Commands = {
		["Sounds"] = function(Value)
			if Value == 0 then
				Value = not self.Config.PlaySounds
			else
				Value = Value == 2
			end

			self.Config.PlaySounds = Value
			self:SaveConfig()

			Notify(StringFormat("[Shine] Forced Notification Sounds has been %s.", Value and "enabled" or "disabled"))
		end,
		["SoundVolume"] = function(Volume)
			self.Config.SoundVolume = Volume
			self:SaveConfig()

			Notify(StringFormat("[Shine] Forced Notification Sounds Volume has been set to %s.", Volume))
		end
	}

	if Commands[Message.Name] and Message.Value then
		Commands[Message.Name](Message.Value)
	end
end

function Plugin:Cleanup()
	self.Sounds = nil

	self.BaseClass.Cleanup(self)

	self.Enabled = false
end
