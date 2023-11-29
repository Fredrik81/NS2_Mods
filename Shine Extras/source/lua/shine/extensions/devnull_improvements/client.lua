local Shine = Shine
local Plugin = Shine.Plugin( ... )

Plugin.HasConfig = false
Plugin.ConfigName = "ForcedNotifications.json"
Plugin.DefaultState = false
Plugin.PrintName = "Devnull - Improvements"
Plugin.PrintVersion = "1.0"

local mapIcons
local Notify = Shared.Message
local StringFormat = string.format

function Plugin:Initialise()
	self.Enabled = true

	HPrint(Plugin.PrintName .. ", version " .. Plugin.PrintVersion)

	--self:CreateHooks()

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

function Plugin:Cleanup()
	self.Sounds = nil

	self.BaseClass.Cleanup(self)

	self.Enabled = false
end
