--HPrint("=========Loaded NetworkMessages.lua hook==============")

local kEalStats = {
    name = string.format("string (%d)", 20),
    buyCount = "integer",
    lostCount = "integer"
}
Shared.RegisterNetworkMessage("EalStats", kEalStats)

local kPlayerStatsMessage = {
    isMarine = "boolean",
    playerName = string.format("string (%d)", kMaxNameLength * 4),
    kills = string.format("integer (0 to %d)", kMaxKills),
    assists = string.format("integer (0 to %d)", kMaxKills),
    deaths = string.format("integer (0 to %d)", kMaxDeaths),
    score = string.format("integer (0 to %d)", kMaxScore),
    accuracy = "float (0 to 100 by 0.01)",
    accuracyOnos = "float (-1 to 100 by 0.01)",
    accuracyFiltered = "string (30)",
    pdmg = "float (0 to 524287 by 0.01)",
    sdmg = "float (0 to 524287 by 0.01)",
    minutesBuilding = "float (0 to 1023 by 0.01)",
    minutesPlaying = "float (0 to 1023 by 0.01)",
    minutesComm = "float (0 to 1023 by 0.01)",
    killstreak = "integer (0 to 254)",
    steamId = "integer",
    hiveSkill = "integer",
    isRookie = "boolean",
    hiveSkillMarine = "integer",
    hiveSkillAlien = "integer",
    commanderSkill = "integer",
    commanderSkillMarine = "integer",
    commanderSkillAlien = "integer"
}
Shared.RegisterNetworkMessage("PlayerStats", kPlayerStatsMessage)

local kTeamSpecificStats = {
    steamId = "integer",
    techName = string.format("string (%d)", 20),
    value = "float (0 to 524287 by 0.01)"
}
Shared.RegisterNetworkMessage("TeamSpecificStats", kTeamSpecificStats)

local kDeathStatsMessage = {
    lastAcc = "float (0 to 100 by 0.01)",
    lastAccOnos = "float (-1 to 100 by 0.01)",
    currentAcc = "float (0 to 100 by 0.01)",
    currentAccOnos = "float (-1 to 100 by 0.01)",
    pdmg = "float (0 to 524287 by 0.01)",
    sdmg = "float (0 to 524287 by 0.01)",
    kills = string.format("integer (0 to %d)", kMaxKills),
    parasites = "integer",
    medsReceived = "integer",
    marineRtDamage = "float (0 to 524287 by 0.01)",
    alienRtDamage = "float (0 to 524287 by 0.01)",
    aliveFor = "float (0 to 524287 by 0.01)"
}
Shared.RegisterNetworkMessage("DeathStats", kDeathStatsMessage)




--currently unused because of LessNetworkData
--[[
local kPresGraphStatsMarines = {
    presUnused = "float (0 to 3200 by 0.1)",
    rtAmount = "integer (0 to 32)",
    presEquipped = "float (0 to 3200 by 0.1)",
    gameMinute = "float (0 to 524287 by 0.01)",
    playerCount = "integer (0 to 32)"
}
Shared.RegisterNetworkMessage("PresGraphStatsMarines", kPresGraphStatsMarines)
local kPresGraphStatsAliens = {
    presUnused = "float (0 to 3200 by 0.1)",
    rtAmount = "integer (0 to 32)",
    presEquipped = "float (0 to 3200 by 0.1)",
    gameMinute = "float (0 to 524287 by 0.01)",
    playerCount = "integer (0 to 32)"
}
Shared.RegisterNetworkMessage("PresGraphStatsAliens", kPresGraphStatsAliens)

]]




