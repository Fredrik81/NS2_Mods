-- ======= Copyright (c) 2015, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Hitreg.lua
--
--    Created by: Mats Olsson (mats.olsson@matsotech.se)
--
-- Handle hitreg verification. Requires cheats/tests to be on.
-- When turned on, the client and the server collects hit-reg data and the server sends its copy
-- to the client for comparision. The precision for numbers can be adjusted.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/UtilityShared.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/String.lua")

-- At the top of the file
local Math = math
local Shared = Shared
local StringFormat = string.format
local TableConcat = table.concat
local MathRound = math.round
local MathPow = math.pow
local MathPi = math.pi
local MathFloor = math.floor
local MathLog10 = math.log10
local MathAbs = math.abs
local JsonEncode = json.encode
local JsonDecode = json.decode

-- Server side hitreg enabling; set (=map with bool value) of clients
-- which have hitreg enabled or nil when noone is tracked
Hitreg_enabledClientSet = nil

-- client side map of collected hitreg data. nil if not enabled
Hitreg_dataMap = nil

local function GetHitregKey(data)
    return StringFormat("%d-%d", data.moveSerial, data.hitSerial)
end

local kMaxEnemyRange = 15
local kMaxEnemySqRange = 100000
local kMaxEntityDataLength = 500
local kMaxEntityAnimLength = 500

-- how many decimals to round off by default
-- this value works together with the various Encodings to remove insignificant differences
-- can lower it just to see what shows up
local gHitregPrec = 2

local kHitregMessageName = "hitreg"

local hitregNetworkVars = {
    -- the move serial executed
    moveSerial = "integer",
    -- the time when the hit was made. Note: do not use "time" type, as that adds a compression
    time = "float",
    -- if multiple hits on the same time (shotgun), the serial number
    hitSerial = "integer (0 to 255)",
    -- if a hit was detected
    hit = "boolean",

    -- the presumed target entity (if a miss, any close player in a narrow cone in front of the shooter)
    entity = "entityid",
    -- data about the entity (json)
    entity_data = "string (" .. kMaxEntityDataLength .. ")",
    -- data about the entity animation (json)
    entity_anim = "string (" .. kMaxEntityAnimLength .. ")",

    -- the trace data
    trace_start = "vector",
    trace_end = "vector",
    trace_fraction = "float"
}

-- encode the number using the given number of significant digits (not decimals!)
local function EncodeNum(num, dig)
    dig = Clamp(dig or 6, 0, 10) -- Clamp precision between 0 and 10
    if num < 0.0001 and num > -0.0001 then
        return "0"
    end

    local log10 = num == 0 and 0 or MathFloor(MathLog10(MathAbs(num)))
    local decimals = math.max(0, dig - log10)
    local precFactor = MathPow(10, decimals)
    local finalValue = MathRound(num * precFactor) / precFactor

    return StringFormat("%.%df", decimals, finalValue)
end

-- encode the number using the given number of decimals (useful for position data, accuracy lost beyond mm)
local function EncodeFixedNum(num, dig)
    dig = dig or 4
    num = (num < 0.0001 and num > -0.0001) and 0 or num
    local format = StringFormat("%%.%df", dig)
    -- round off the value to the required precision (StringFormat truncates)
    local precFactor = math.pow(10, dig)
    num = math.round(num * precFactor) / precFactor
    return StringFormat(format, num)
end

local function EncodeAngle(angle, dig)
    dig = dig or 4
    angle = angle < 0 and (angle + 2 * MathPi) or angle
    local degrees = 180 * angle / MathPi
    return EncodeNum(degrees, dig)
end

local function EncodeVector(point, dig)
    local result = {x = 0, y = 0, z = 0}
    result.x = EncodeNum(point.x, dig)
    result.y = EncodeNum(point.y, dig)
    result.z = EncodeNum(point.z, dig)
    return result
end

local function EncodePosition(point, dig)
    local result = {x = 0, y = 0, z = 0}
    result.x = EncodeFixedNum(point.x, dig)
    result.y = EncodeFixedNum(point.y, dig)
    result.z = EncodeFixedNum(point.z, dig)
    return result
end

local function EncodeAngles(angles, dig)
    local result = {}
    result.yaw = EncodeAngle(angles.yaw, dig)
    result.pitch = EncodeAngle(angles.pitch, dig)
    result.roll = EncodeAngle(angles.roll, dig)
    return result
end

local function Encode(value)
    if type(value) == "number" then
        return EncodeNum(value)
    end
    return value
end

local hitregSerial = 0
local lastHitregSerialTime = 0
local function GetHitregSerial()
    local time = Shared.GetTime()
    if lastHitregSerialTime ~= time then
        lastHitregSerialTime = time
        hitregSerial = 0
    end
    hitregSerial = hitregSerial + 1
    return hitregSerial
end

-- set the move first in OnProcessMove so we have a move for any analysis
local latestHitregMove
function SetMoveForHitregAnalysis(move)
    latestHitregMove = move
end

local function CollectEntityData(entity)
    local data = {}
    local anim = {}

    if entity then

        data.alive = entity.GetIsAlive and entity:GetIsAlive()
        data.angles = EncodeAngles(entity:GetAngles())
        data.origin = EncodePosition(entity:GetOrigin())
        data.modelOrigin = entity.GetModelOrigin and EncodePosition(entity:GetModelOrigin())

        data.physTime = EncodeNum(entity.lastPhysicsUpdateTime or 0)

        if entity.moveYaw then
            data.moveYaw = entity.moveYaw
        end
        if entity.moveSpeed then
            data.moveSpeed = entity.moveSpeed
        end
        if entity.GetViewAngles then
            data.viewAngles = EncodeAngles(entity:GetViewAngles())
        end
        if entity.GetHeadAngles then
            data.headAngles = EncodeAngles(entity:GetHeadAngles())
        end
        if entity.wallWalking ~= nil then
            data.wallWalking = entity.wallWalking
        end

        if HasMixin(entity, "Model") then

            local model = Shared.GetModel(entity.modelIndex)

            anim.pose = {}
            anim.modelIndex = entity.modelIndex

            if model then

                local maxPoseParams = model:GetNumPoseParameters()
                for i = 0, maxPoseParams - 1 do
                    anim.pose[model:GetPoseParamName(i)] = Encode(entity.poseParams:Get(i))
                end

                anim.sequence = entity.animationSequence
                anim.start = EncodeNum(entity.animationStart)
                anim.speed = EncodeNum(entity.animationSpeed)
                anim.blend = EncodeNum(entity.animationBlend)

                anim.sequence2 = entity.animationSequence2
                anim.start2 = EncodeNum(entity.animationStart2)
                anim.speed2 = EncodeNum(entity.animationSpeed2)

                anim.l1Sequence = entity.layer1AnimationSequence
                anim.l1Start = EncodeNum(entity.layer1AnimationStart)
                anim.l1Speed = EncodeNum(entity.layer1AnimationSpeed)
                anim.l1Blend = EncodeNum(entity.layer1AnimationBlend)

                anim.l1Sequence2 = entity.layer1AnimationSequence2
                anim.l1Start2 = EncodeNum(entity.layer1AnimationStart2)
                anim.l1Speed2 = EncodeNum(entity.layer1AnimationSpeed2)

            else

                anim.model = "None"

            end

        end

    end

    return data, anim
end

local function CollectHitregData(shooter, startPoint, endPoint, trace)
    local maxTargets = 80 -- Limit the number of targets processed
    local entity = trace.entity

    local hit = true

    if not entity then
        hit = false
        local targetVec = endPoint - startPoint
        targetVec:Normalize()
        local smallestAngle

        local closestEnemy
        local closestEnemySqRange = kMaxEnemySqRange

        -- look for potential targets, players inside 15.
        -- Choose those the closest to the targetVec, if they are close enough
        local targets = Shared.GetEntitiesWithTagInRange("class:Player", startPoint, kMaxEnemyRange)
        for i = 1, math.min(#targets, maxTargets) do
            local target = targets[i]
            if GetAreEnemies(shooter, target) then
                if not target:isa("Spectator") then
                    local targetOrigin = target:GetOrigin()
                    local v = targetOrigin - startPoint
                    local sqRange = v:GetLengthSquared()
                    v:Normalize()
                    local angle = Math.DotProduct(targetVec, v)
                    if angle > 0.8 and (not smallestAngle or angle > smallestAngle) then
                        smallestAngle = angle
                        entity = target
                    end
                    if sqRange < closestEnemySqRange then
                        closestEnemy = target
                        closestEnemySqRange = sqRange
                    end
                end
            end
        end

        -- if we can't find any enemy close to where we aimed, it might be that we are so
        -- close to the target it is outside the cone.
        -- So the backup plan is to just choose the closest enemy.
        if not entity then
            print("-- FIND CLOSEST --")
            entity = closestEnemy
        end

        if entity and entity.GetOrigin then
            Shared.TraceRay(entity:GetOrigin() + Vector(0, 0.01, 0), entity:GetOrigin(), CollisionRep.Damage, PhysicsMask.Bullets)
        end
    end

    local data, anim = CollectEntityData(entity)

    local values = {}

    ASSERT(latestHitregMove)
    values.moveSerial = Shared.GetMoveSerial(latestHitregMove)
    if values.moveSerial == 0 then
        -- artificial/injected move
        return nil
    end

    values.time = Shared.GetTime()
    values.hitSerial = GetHitregSerial()
    values.hit = hit
    values.entity = entity and entity:GetId() or Entity.invalidId
    if entity then
        values.entity_data = JsonEncode(data)
        ASSERT(values.entity_data:len() <= kMaxEntityDataLength)
        values.entity_anim = JsonEncode(anim)
        ASSERT(values.entity_anim:len() <= kMaxEntityAnimLength)
    end

    values.trace_fraction = trace.fraction
    values.trace_start = startPoint
    values.trace_end = endPoint

    return values

end

-- return number of decimals in number
local function GetPrecision(num)
    local index = string.find(num, '.', 1, true)
    local len = string.len(num)
    return index and (len - index - 1) or 0
end

-- compare two values using rounding if numbers
function HitregValuesDiffer(v1, v2, precision)
    local n1 = tonumber(v1)
    local n2 = tonumber(v2)
    if not n1 or not n2 then
        return v1 ~= v2
    end
    local prec = math.max(0, GetPrecision(v1) - precision)
    local precFactor = math.pow(10, prec)
    local rounded1 = math.round(n1 * precFactor)
    local rounded2 = math.round(n2 * precFactor)
    -- Log("prec(%s) = %s, f %s, v1 %s, v2 %s, r1 %s, r2 %s", v1, prec, precFactor, v1, v2, rounded1, rounded2)
    return rounded1 ~= rounded2
end

function AnalyzeHitRegData(path, server, client, result, prec)
    for k, serverV in pairs(server) do
        local clientV = client[k]
        if not clientV then
            table.insert(result, StringFormat("    srv%s.%s: %20s", path, k, serverV))
            table.insert(result, StringFormat("    cli%s.%s: %20s", path, k, "-"))
        else
            if type(serverV) == "table" then
                AnalyzeHitRegData(path .. "." .. k, serverV, clientV, result, prec)
            else
                if HitregValuesDiffer(serverV, clientV, prec) then
                    table.insert(result, StringFormat("   srv%s.%s: %20s", path, k, serverV))
                    table.insert(result, StringFormat("   cli%s.%s: %20s", path, k, clientV))
                end
            end
        end
    end
end

local function ProcessMessageData(data)
    local result = table.copyDict(data)
    local success, decodedData = pcall(JsonDecode, data.entity_data)
    if success then
        result.entity_data = decodedData
    else
        Log("Failed to decode entity_data: %s", data.entity_data)
    end
    result.entity_anim = JsonDecode(data.entity_anim)
    result.trace_start = EncodePosition(data.trace_start)
    result.trace_end = EncodePosition(data.trace_end)
    result.trace_fraction = EncodeNum(data.trace_fraction, 4)
    result.trace_range = EncodeNum(data.trace_start:GetDistanceTo(data.trace_end), 3)
    return result
end

local lastEntityIdTargeted
local noDiffsCount = 0
local function CompareHitregData(serverData, clientData)
    -- unpack the json formated data
    serverData = ProcessMessageData(serverData)
    clientData = ProcessMessageData(clientData)

    local entity = Shared.GetEntity(serverData.entity)

    if entity and serverData.entity ~= lastEntityIdTargeted and entity:isa("Player") then
        Log("Hitreg: targeting %s", entity)
        lastEntityIdTargeted = serverData.entity
    end

    local key = GetHitregKey(serverData)

    if serverData.entity ~= Entity.invalidId or clientData.entity ~= Entity.invalidId then
        local physTime = -2

        if entity ~= nil and entity:isa("Player") then

            if serverData.entity_data then
                physTime = serverData.entity_data.physTime or -1
            end

            if entity and not serverData.entity_data.alive and clientData.entity_data.alive then
                Log("%s: Accepted diff found, target %s is dead on server", key, entity)
            elseif serverData.entity ~= clientData.entity then
                Log("%s: Diff in targeted entity (server %s vs client %s) (original target dead?)", key,
                    serverData.entity, clientData.entity)
            else
                local diff = {}
                -- if hit differs between server and client, do a full precision dump
                local precision = serverData.hit ~= clientData.hit and 0 or gHitregPrec
                AnalyzeHitRegData("", serverData, clientData, diff, precision)
                if #diff > 0 then
                    Log("%s: Diff found for attack on %s (physTime %s): \n%s", key, entity, physTime,
                        table.concat(diff, "\n"))
                    noDiffsCount = 0
                else
                    if Client.GetLocalPlayer().hitregDebugAlways then
                        noDiffsCount = noDiffsCount + 1
                        if noDiffsCount % 100 == 0 then
                            Log("Hitreg_always: %s noDiffsFound since last diff", noDiffsCount)
                        end
                    else
                        Log("%s: no diffs found for attack on %s (hit=%s)", key, entity, serverData.hit)
                    end
                end
            end
        end
    end
end

local register = (Server or Client) and not Hitreg_OnConsoleHitreg

if Predict then
    function HandleHitregAnalysis(shooter, startPoint, endPoint, trace)
    end
end

if Server then
    function Hitreg_OnConsoleHitreg(client, prec)
        if not (Shared.GetTestsEnabled() or Shared.GetCheatsEnabled()) then
            Log("hitreg requires cheats or tests")
            return
        end

        if not client or type(client) == "number" then
            Log("hitreg has no effect when used on local server console")
            return
        end

        if not Hitreg_enabledClientSet then
            Hitreg_enabledClientSet = {}
        end

        local player = client:GetPlayer()

        local turnOn = Hitreg_enabledClientSet[client:GetId()] ~= true or prec ~= "off"

        Hitreg_enabledClientSet[client:GetId()] = turnOn and true or nil

        local size = table.countkeys(Hitreg_enabledClientSet)

        Log("hitreg for %s = %s (tracking %s players)", player:GetName(), turnOn, size)

        if size == 0 then
            Hitreg_enabledClientSet = nil
        end
    end

    function HandleHitregAnalysis(shooter, startPoint, endPoint, trace)
        if Hitreg_enabledClientSet then
            if Shared.GetTestsEnabled() or Shared.GetCheatsEnabled() then
                local client = shooter:isa("Player") and Server.GetClientById(shooter:GetClientIndex()) or nil
                if client and Hitreg_enabledClientSet[client:GetId()] == true then
                    local data = CollectHitregData(shooter, startPoint, endPoint, trace)
                    if data then
                        local key = GetHitregKey(data)
                        -- Log("Hitreg '%s' = %s", key, data)
                        Server.SendNetworkMessage(client, kHitregMessageName, data, true)
                    end
                end
            else
                Hitreg_enabledClientSet = nil
            end
        end
    end
end

if Client then
    function Hitreg_OnConsoleHitregAlways()
        if not (Shared.GetTestsEnabled() or Shared.GetCheatsEnabled()) then
            Log("hitreg_debug requires cheats or tests")
            return
        end

        local player = Client.GetLocalPlayer()

        player.hitregDebugEnabled = not player.hitregDebugEnabled

        Log("%s: hitregDebugEnabled = %s", player, player.hitregDebugEnabled)
    end

    function Hitreg_OnConsoleHitreg(prec)
        if not (Shared.GetTestsEnabled() or Shared.GetCheatsEnabled()) then
            Log("hitreg requires cheats or tests")
            return
        end

        local player = Client.GetLocalPlayer()

        local turnOn = Hitreg_dataMap == nil
        if prec then
            if prec == "off" then
                turnOn = false
            else
                gHitregPrec = Clamp(tonumber(prec) or 1, 0, 5)
                turnOn = true
            end
        end

        Hitreg_dataMap = turnOn and {} or nil
        Log("hitreg checking %s, prec %s", turnOn and "on" or "off", gHitregPrec)
    end

    function HandleHitregAnalysis(shooter, startPoint, endPoint, trace)
        if Hitreg_dataMap then
            if Shared.GetTestsEnabled() or Shared.GetCheatsEnabled() then
                local data = CollectHitregData(shooter, startPoint, endPoint, trace)
                local key = GetHitregKey(data)
                Hitreg_dataMap[key] = data
                -- Log("Hitreg '%s' = %s", key, data)
            else
                Hitreg_dataMap = nil
            end
        end
    end

    function OnHitregMessage(serverData)
        if Hitreg_dataMap then

            local key = GetHitregKey(serverData)
            local clientData = Hitreg_dataMap[key]
            if clientData then
                if serverData.time ~= clientData.time then
                    Log("WTF? server time %s, client time %s", serverData.time, clientData.time)
                end
                CompareHitregData(serverData, clientData)
            else
                Log("Hitreg: No data for key '%s' found", key)
                Log("Server data %s", serverTraceRange, serverData)

            end
            Hitreg_dataMap[key] = nil

        end
    end
end

function Hitreg_OnConsoleHitregAlways(client)
    if not (Shared.GetTestsEnabled() or Shared.GetCheatsEnabled()) then
        Log("hitreg_debug requires cheats or tests")
        return
    end

    local player = Client and Client.GetLocalPlayer() or client:GetPlayer()

    player.hitregDebugAlways = not player.hitregDebugAlways

    Log("%s: hitregDebugAlwaysEnabled = %s", player, player.hitregDebugAlways)
end

if register then
    Event.Hook("Console_hitreg", Hitreg_OnConsoleHitreg)
    Event.Hook("Console_hitreg_always", Hitreg_OnConsoleHitregAlways)
    Shared.RegisterNetworkMessage(kHitregMessageName, hitregNetworkVars)
    if Client then
        Client.HookNetworkMessage(kHitregMessageName, OnHitregMessage)
    end
end

