function ParasiteMixin:SetParasited(fromPlayer, durationOverride)
    if Server then
        if not self.GetCanBeParasitedOverride or self:GetCanBeParasitedOverride() then
            if not self.parasited and self.OnParasited then
                self:OnParasited()
                if fromPlayer and HasMixin(fromPlayer, "Scoring") and self:isa("Player") then
                    fromPlayer:AddScore(kParasitePlayerPointValue)
                    if fromPlayer:isa("Skulk") then
                        local msg = {}
                        msg.steamId = fromPlayer:GetSteamId()
                        msg.Value = 1
                        StatsUI_RegisterTSS("Parasite", msg)
                    end
                end

                if fromPlayer and HasMixin(fromPlayer, "Scoring") and fromPlayer:isa("Skulk") and (self:isa("Mine") or self:isa("ARC") or self:isa("PhaseGate")) then
                    local msg = {}
                    msg.steamId = fromPlayer:GetSteamId()
                    msg.Value = 1
                    StatsUI_RegisterTSS("Parasite", msg)
                end
            end

            local parasiteTimeChanged = false
            local now = Shared.GetTime()

            if type(durationOverride) == "number" then
                durationOverride = Clamp(durationOverride, 0, kParasiteDuration)

                if self.parasited and now + durationOverride > self.parasiteDuration + self.timeParasited then
                    self.parasiteDuration = durationOverride
                    parasiteTimeChanged = true
                elseif not self.parasited then
                    self.parasiteDuration = durationOverride
                    parasiteTimeChanged = true
                end
            else
                self.parasiteDuration = kParasiteDuration
                parasiteTimeChanged = true
            end

            if parasiteTimeChanged then
                self.timeParasited = now
            end

            self.parasited = true
        end
    end
end
