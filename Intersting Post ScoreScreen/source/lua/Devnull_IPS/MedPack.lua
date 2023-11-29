local orgMedPackOnTouch = MedPack.OnTouch
function MedPack:OnTouch(recipient)
    orgMedPackOnTouch(self, recipient)
    if recipient:isa("Player") then
        local msg = {}
        msg.steamId = recipient:GetSteamId()
        msg.Value = 1
        StatsUI_RegisterTSS("MarineMedsReceived", msg)
    end
end
