if Server then
    function NS2Gamerules:SetGameState(state)
        if state ~= self.gameState then
            self.gameState = state
            self.gameInfo:SetState(state)
            self.timeGameStateChanged = Shared.GetTime()
            self.timeSinceGameStateChanged = 0

            if self.gameState == kGameState.Started then
                self.gameStartTime = Shared.GetTime()

                self.gameInfo:SetStartTime(self.gameStartTime)

                local MarineTechPoint = self.team1:GetInitialTechPoint()
                local AlienTechPoint = self.team2:GetInitialTechPoint()
                local MarineLocation = MarineTechPoint:GetOrigin()
                local AlienLocation = AlienTechPoint:GetOrigin()
                local MarineTeam = GetGamerules():GetTeam(1)
                local AlienTeam = GetGamerules():GetTeam(2)

                -- Ping
                -- MarineTeam:SetCommanderPing(AlienLocation)
                -- AlienTeam:SetCommanderPing(MarineLocation)

                -- Team Message
                SendTeamMessage(self.team1, kTeamMessageTypes.GameStarted, AlienTechPoint:GetLocationId())
                SendTeamMessage(self.team2, kTeamMessageTypes.GameStarted, MarineTechPoint:GetLocationId())
            elseif self.gameState == kGameState.Countdown then
                local MarineTechPoint = self.team1:GetInitialTechPoint()
                local AlienTechPoint = self.team2:GetInitialTechPoint()
                local MarineLocation = MarineTechPoint:GetOrigin()
                local AlienLocation = AlienTechPoint:GetOrigin()
                local MarineTeam = GetGamerules():GetTeam(1)
                local AlienTeam = GetGamerules():GetTeam(2)

                -- Ping
                MarineTeam:SetCommanderPing(AlienLocation)
                AlienTeam:SetCommanderPing(MarineLocation)
                Server.SendNetworkMessage("FairStartPing", {Alien = AlienLocation, Marine = MarineLocation})

                -- Team Message
                SendTeamMessage(self.team1, kTeamMessageTypes.GameStarted, AlienTechPoint:GetLocationId())
                SendTeamMessage(self.team2, kTeamMessageTypes.GameStarted, MarineTechPoint:GetLocationId())
            end
            -- On end game, check for map switch conditions
            if state == kGameState.Team1Won or state == kGameState.Team2Won then
                if MapCycle_TestCycleMap() then
                    self.timeToCycleMap = Shared.GetTime() + kPauseToSocializeBeforeMapcycle
                else
                    self.timeToCycleMap = nil
                end
            end
        end
    end
end
