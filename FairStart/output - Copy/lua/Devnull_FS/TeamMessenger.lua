-- ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
--
-- lua\TeamMessenger.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

kTeamMessageTypes = enum({ 
    'GameStarted', 'PowerLost', 'PowerRestored', 'Eject', 'CannotSpawn',
    'SpawningWait', 'Spawning', 'ResearchComplete', 'ResearchLost',
    'HiveConstructed', 'HiveLowHealth', 'HiveKilled',
    'CommandStationUnderAttack', 'IPUnderAttack', 'HiveUnderAttack',
    'PowerPointUnderAttack', 'Beacon', 'NoCommander', 'TeamsUnbalanced',
    'TeamsBalanced', 'GameStartCommanders', 'WarmUpActive', 'ReturnToBase', 
    'TD_RoundWaitingPlayers' 
})

local kTeamMessages = { }

-- This function will generate the string to display based on a location Id.
local locationStringGen = function(locationId, messageString) return string.format(Locale.ResolveString(messageString), Shared.GetString(locationId)) end

-- Thos function will generate the string to display based on a research Id.
local researchStringGen = function(researchId, messageString) return string.format(Locale.ResolveString(messageString), GetDisplayNameForTechId(researchId)) end

-- Special freetext location id
local locationSpecialStringGen = function(locationId, messageString) return string.format(messageString, Shared.GetString(locationId)) end

kTeamMessages[kTeamMessageTypes.GameStarted] = { text = { [kMarineTeamType] = function(data) return locationSpecialStringGen(data, "Alien infestation detected at %s") end, [kAlienTeamType] = function(data) return locationSpecialStringGen(data, "Intruders detected at %s") end } }

kTeamMessages[kTeamMessageTypes.PowerLost] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "POWER_LOST") end } }

kTeamMessages[kTeamMessageTypes.PowerRestored] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "POWER_RESTORED") end } }

kTeamMessages[kTeamMessageTypes.Eject] = { text = { [kMarineTeamType] = "COMM_EJECT", [kAlienTeamType] = "COMM_EJECT" } }

kTeamMessages[kTeamMessageTypes.CannotSpawn] = { text = { [kMarineTeamType] = "NO_IPS" } }

kTeamMessages[kTeamMessageTypes.SpawningWait] = { text = { [kAlienTeamType] = "WAITING_TO_SPAWN" } }

kTeamMessages[kTeamMessageTypes.Spawning] = { text = { [kMarineTeamType] = "SPAWNING", [kAlienTeamType] = "SPAWNING" } }

kTeamMessages[kTeamMessageTypes.ResearchComplete] = { text = { [kAlienTeamType] = function(data) return researchStringGen(data, "EVOLUTION_AVAILABLE") end } }

kTeamMessages[kTeamMessageTypes.ResearchLost] = { text = { [kAlienTeamType] = function(data) return researchStringGen(data, "EVOLUTION_LOST") end } }

kTeamMessages[kTeamMessageTypes.HiveConstructed] = { text = { [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_CONSTRUCTED") end } }

kTeamMessages[kTeamMessageTypes.HiveLowHealth] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "HIVE_LOW_HEALTH") end,
                                                            [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_LOW_HEALTH") end } }

kTeamMessages[kTeamMessageTypes.HiveKilled] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "HIVE_KILLED") end,
                                                         [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_KILLED") end } }

kTeamMessages[kTeamMessageTypes.CommandStationUnderAttack] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "COMM_STATION_UNDER_ATTACK") end } }

kTeamMessages[kTeamMessageTypes.IPUnderAttack] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "IP_UNDER_ATTACK") end } }

kTeamMessages[kTeamMessageTypes.HiveUnderAttack] = { text = { [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_UNDER_ATTACK") end } }

kTeamMessages[kTeamMessageTypes.PowerPointUnderAttack] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "POWER_POINT_UNDER_ATTACK") end } }

kTeamMessages[kTeamMessageTypes.Beacon] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "BEACON_TO") end } }

kTeamMessages[kTeamMessageTypes.NoCommander] = { text = { [kMarineTeamType] = "NO_COMM", [kAlienTeamType] = "NO_COMM" } }

kTeamMessages[kTeamMessageTypes.TeamsUnbalanced] = { text = { [kMarineTeamType] = "TEAMS_UNBALANCED", [kAlienTeamType] = "TEAMS_UNBALANCED" } }

kTeamMessages[kTeamMessageTypes.TeamsBalanced] = { text = { [kMarineTeamType] = "TEAMS_BALANCED", [kAlienTeamType] = "TEAMS_BALANCED" } }

kTeamMessages[kTeamMessageTypes.GameStartCommanders] = { text = { [kMarineTeamType] = "GAME_START_COMMANDERS", [kAlienTeamType] = "GAME_START_COMMANDERS" } }

local genericStringGen = function(param, messageString) return string.format(Locale.ResolveString(messageString), param) end
kTeamMessages[kTeamMessageTypes.WarmUpActive] = { text = { [kMarineTeamType] = function(data) return genericStringGen(data, "WARMUP_ACTIVE") end ,
                                                            [kAlienTeamType] = function(data) return genericStringGen(data, "WARMUP_ACTIVE") end  } }

kTeamMessages[kTeamMessageTypes.ReturnToBase] = { text = { [kMarineTeamType] = "RETURN_TO_BASE", [kAlienTeamType] = "RETURN_TO_BASE" } }

--Unique to Thunderdome Mode only, simple banner to inform clients round will start once all clients connected
kTeamMessages[kTeamMessageTypes.TD_RoundWaitingPlayers] = { text = { [kMarineTeamType] = "THUNDERDOME_ROUND_AWAITING_ALL_CLIENTS", [kAlienTeamType] = "THUNDERDOME_ROUND_AWAITING_ALL_CLIENTS" } }


-- Silly name but it fits the convention.
local kTeamMessageMessage =
{
    type = "enum kTeamMessageTypes",
    data = "integer"
}

Shared.RegisterNetworkMessage("TeamMessage", kTeamMessageMessage)

if Server then

    local function IgnoreMessageBeforeStart(messageType)
        if not GetGamerules():GetGameStarted() then
            if messageType == kTeamMessageTypes.PowerLost or
            messageType == kTeamMessageTypes.PowerRestored or
            messageType == kTeamMessageTypes.PowerPointUnderAttack or
            messageType == kTeamMessageTypes.HiveConstructed or
            messageType == kTeamMessageTypes.HiveLowHealth or
            messageType == kTeamMessageTypes.HiveKilled or
            messageType == kTeamMessageTypes.HiveUnderAttack or
            messageType == kTeamMessageTypes.ResearchComplete or
            messageType == kTeamMessageTypes.ResearchLost or
            messageType == kTeamMessageTypes.CommandStationUnderAttack or
            messageType == kTeamMessageTypes.IPUnderAttack then
                return true
            end
        end
        return false
    end

    --
    -- Sends every team the passed in message for display.
    --
    function SendGlobalMessage(messageType, optionalData)

        if GetGamerules():GetGameStarted() then
        
            local teams = GetGamerules():GetTeams()
            for t = 1, #teams do
                SendTeamMessage(teams[t], messageType, optionalData)
            end
            
        end
        
    end
    
    --
    -- Sends every player on the passed in team the passed in message for display.
    --
    function SendTeamMessage(team, messageType, optionalData)

        if IgnoreMessageBeforeStart(messageType) then
            return
        end

        local SendToPlayer = Closure [=[
            self messageType optionalData
            args player
            Server.SendNetworkMessage(player, "TeamMessage", { type = messageType, data = optionalData }, true)
        ]=]{messageType, optionalData or 0}
        
        team:ForEachPlayer(SendToPlayer)
        
    end
    
    --
    -- Sends the passed in message to the players passed in.
    --
    function SendPlayersMessage(playerList, messageType, optionalData)
        if GetGamerules():GetGameStarted() then
            for p = 1, #playerList do
                Server.SendNetworkMessage(playerList[p], "TeamMessage", { type = messageType, data = optionalData or 0 }, true)
            end
        end
    end

    local function TestTeamMessage(client)
        local player = client:GetControllingPlayer()
        if player then
            SendPlayersMessage({ player }, kTeamMessageTypes.NoCommander)
        end
    end

    Event.Hook("Console_ttm", TestTeamMessage)
end

if Client then
    local function CommanderTeamMessageWhitelist(messageType)
        if messageType == kTeamMessageTypes.GameStarted or
        messageType == kTeamMessageTypes.GameStartCommanders or
        messageType == kTeamMessageTypes.HiveConstructed or
        messageType == kTeamMessageTypes.HiveLowHealth or
        messageType == kTeamMessageTypes.HiveKilled or
        messageType == kTeamMessageTypes.HiveUnderAttack or
        messageType == kTeamMessageTypes.ResearchComplete or
        messageType == kTeamMessageTypes.ResearchLost or
        messageType == kTeamMessageTypes.CommandStationUnderAttack or
        messageType == kTeamMessageTypes.IPUnderAttack then
            return true
        end

        return false
    end

    local function SetTeamMessage(messageType, messageData)
        local player = Client.GetLocalPlayer()
        --print("MessageType '" .. tostring(messageType) .. "' active = " .. tostring(CommanderTeamMessageWhitelist(messageType)))

        if player and player:isa("Commander") then
            if not CommanderTeamMessageWhitelist(messageType) then return end

            if not HasMixin(player, "TeamMessage") then
                Script.Load("lua/TeamMessageMixin.lua")
                if player:GetTeamNumber() == 1 then
                    InitMixin(player, TeamMessageMixin, { kGUIScriptName = "GUIMarineTeamMessage" })
                elseif player:GetTeamNumber() == 2 then
                    InitMixin(player, TeamMessageMixin, { kGUIScriptName = "GUIAlienTeamMessage" })
                end
            end
        end

        if player and HasMixin(player, "TeamMessage") then
            local displayText = kTeamMessages[messageType].text[player:GetTeamType()]

            if displayText then
                if type(displayText) == "function" then
                    displayText = displayText(messageData)
                else
                    displayText = Locale.ResolveString(displayText)
                end

                assert(type(displayText) == "string")
                player:SetTeamMessage(string.UTF8Upper(displayText))
            end
        end
    end

    function OnCommandTeamMessage(message)
        SetTeamMessage(message.type, message.data)
    end

    Client.HookNetworkMessage("TeamMessage", OnCommandTeamMessage)
end