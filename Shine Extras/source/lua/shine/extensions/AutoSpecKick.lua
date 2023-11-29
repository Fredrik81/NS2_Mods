local Plugin = Shine.Plugin(...)
Plugin.NotifyPrefixColour = {255, 50, 0}
Plugin.PrintName = "Auto Spec Kick"
Plugin.Version = "1.2"
Plugin.HasConfig = true
Plugin.ConfigName = "AutoSpecKick.json"
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

Plugin.DependsOnPlugins = {
    "readyroomqueue"
}

Plugin.DefaultConfig = {
    KickMessage = "You have been kicked because specslots are over populated and you are not in queue.\nThis is so players who want to play can join.",
    RequireOpenSlots = 1
}

-- Script configs
local LoopDelay = 15
local LastRun = 90
local SlotsRequired = 0

--(x < 0) ? "negative" : "non-negative";
local MaxSpectators = Server.GetMaxSpectators()
local MaxPlayers = Server.GetMaxPlayers()

local function KickClient(Client)
    local reason = Plugin.Config.KickMessage
    Client.DisconnectReason = reason
    Server.DisconnectClient(Client, reason)
end

local function CheckSpecSlots()
    if Shared.GetTime() < (LastRun + LoopDelay) then
        return
    end

    local NumTotalClients = Server.GetNumClientsTotal()
    local NumPlayersTotal = Server.GetNumPlayersTotal()
    local SpectatorClients = Shine.GetTeamClients(3)
    local NumSpectators = #SpectatorClients

    --Debug
    --[[
    print("MaxSpectators: " .. tostring(MaxSpectators))
    print("MaxPlayers: " .. tostring(MaxPlayers))
    print("Total Clients: " .. tostring(NumTotalClients))
    print("Total Players: " .. tostring(NumPlayersTotal))
    print("Total Spectators: " .. tostring(NumSpectators))
    for i = 1, #SpectatorClients do
        local Player = SpectatorClients[i]:GetControllingPlayer()
        print("Playername: " .. Player:GetName())
        if Shine:HasAccess(SpectatorClients[i], "sh_speckickimmune") then
            print("-Immune")
        else
            print("-Not Immune")
        end
    end
    ]]
    LastRun = Shared.GetTime()
    local PlayersToKick = 0

    --If there are not enough players to full player slots then don't kick
    if MaxPlayers >= NumTotalClients then
        --print("Server seeding.. don't kick")
        return
    end

    -- Checks to see if we need to kick some or not..
    if NumSpectators > (MaxSpectators - SlotsRequired) and NumSpectators > 0 then
        --Shared.Message("We are maxed on spectators... Will try to kick kick maximum of " .. tostring(PlayersToKick) .. "players.")
        PlayersToKick = NumSpectators - (MaxSpectators - SlotsRequired)
    else
        --Shared.Message("No need to kick spectators..")
        return
    end

    -- Just extra check.. should never happen
    if PlayersToKick <= 0 then
        Shared.Message("ERROR: Auto Spectator Kick calculcated wrong.. Players to kick = " .. tostring(PlayersToKick))
        return
    end

    local RRQ = Shine.Plugins.readyroomqueue
    if not RRQ then
        Shared.Message("ERROR: Can't access readyroomqueue data")
        return
    end
    local QueueData = RRQ.PlayerQueue

    --Shared.Message("Check if we have queued people...")
    --Shared.Message("Queue: " .. tostring(QueueData["NumMembers"]))
    --PrintTable(QueueData)
    if QueueData["NumMembers"] > 0 then
        --print("We have " .. tostring(QueueData["NumMembers"]) .. " people in.")
        return
    end
    for i = 1, #SpectatorClients do
        local PlayerID = SpectatorClients[i]:GetUserId()
        local Player = SpectatorClients[i]:GetControllingPlayer()
        local PlayerName = Player:GetName()
        --print("Queue data: " .. tostring(QueueData["MemberLookup"][PlayerID]) .. ", " .. PlayerName .. " (" .. tostring(PlayerID) .. ")")
        if QueueData["MemberLookup"][PlayerID] then
            --print("We have player in queue no need to kick.")
            return
        end
    end

    -- We have work to do.. Loop all spectators
    --Shared.Message("Will try to kick " .. tostring(PlayersToKick) .. " Players.")
    local PlayersKicked = {}
    for i = 1, #SpectatorClients do
        if not Shine:IsValidClient(SpectatorClients[i]) or not SpectatorClients[i]:GetIsSpectator() then
            Shared.Message("Player is not spectator... something is wrong.. quit loop")
            return
        end
        if PlayersToKick <= 0 then
            break
        end

        local PlayerID = SpectatorClients[i]:GetUserId()
        local Player = SpectatorClients[i]:GetControllingPlayer()
        local PlayerName = Player:GetName()

        --print(PlayerName .. "Immunity status: " .. tostring(Shine:GetUserImmunity(SpectatorClients[i])))
        -- Check for immunity else kick the player
        if Shine:GetUserImmunity(SpectatorClients[i]) < 1 or Shine:HasAccess(SpectatorClients[i], "sh_speckickimmune") then
            PlayersToKick = PlayersToKick - 1

            Shared.Message("Kicking Spectator: " .. PlayerName .. " (" .. tostring(PlayerID) .. ")")
            KickClient(SpectatorClients[i])
            table.insert(PlayersKicked, PlayerName)
        end
    end

    if PlayersKicked then
        for i = 1, #PlayersKicked do
            Shine:NotifyColour(Client, 255, 255, 255, "[AutoSpecKick] Kicked Spectator: " .. PlayersKicked[i])
        end
    end
    PlayersKicked = nil
end

function Plugin:Initialise()
    if "number" == type(MaxSpectators) and MaxSpectators > 1 then
        self.Enabled = true
        Shared.Message("Loading " .. tostring(Plugin.PrintName) .. ", v" .. tostring(Plugin.Version))
    else
        Shared.Message("Current spec slots " .. tostring(MaxSpectators) .. ", You need at least 2 spectator slots for this mod to make sense...")
        self.Enabled = false
        return false, "Not enough spectator slots on server."
    end

    SlotsRequired = (Plugin.Config.RequireOpenSlots > 0) and Plugin.Config.RequireOpenSlots or 1
    SlotsRequired = (SlotsRequired < MaxSpectators) and SlotsRequired or 1

    --Make sure we do not instantly run loop
    if Shared.GetTime() > LastRun then
        LastRun = Shared.GetTime()
    end

    --  Use Think( DeltaTime )
    Shine.Hook.Add(
        "Think",
        "AutoSpecLoop",
        function(DeltaTime)
            CheckSpecSlots()
        end
    )

    return true
end

function Plugin:Cleanup()
    Shine.Hook.Remove("Think", "AutoSpecLoop")
    self.BaseClass.Cleanup(self)
    self.Enabled = false
end

return Plugin
