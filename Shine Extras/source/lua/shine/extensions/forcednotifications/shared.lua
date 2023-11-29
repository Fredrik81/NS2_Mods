local Plugin = Shine.Plugin(...)
Plugin.Version = "1.2"
Plugin.PrintName = "[Shine] Forced Notification"
Plugin.PrintVersion = "1.4"
Plugin.DefaultState = true

function Plugin:SetupDataTable()
	local Command = {
		Name = "string(255)",
		Value = "integer (0 to 200)"
	}
	self:AddNetworkMessage("Command", Command, "Client")

	self:AddNetworkMessage("PlaySound", {soundName = "string (25)"}, "Client")
end

return Plugin
