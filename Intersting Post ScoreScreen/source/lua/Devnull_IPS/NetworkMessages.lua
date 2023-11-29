--HPrint("=========Loaded NetworkMessages.lua hook==============")

local kEquipmentAndLifeforms = {
    teamNumber = "integer (1 to 2)",
    techId = "enum kTechId",
    destroyed = "boolean"
}
Shared.RegisterNetworkMessage("EquipmentAndLifeforms", kEquipmentAndLifeforms)

local kPlayerStatsMessage = {
    isMarine = "boolean",
    playerName = string.format("string (%d)", kMaxNameLength * 4),
    kills = string.format("integer (0 to %d)", kMaxKills),
    assists = string.format("integer (0 to %d)", kMaxKills),
    deaths = string.format("integer (0 to %d)", kMaxDeaths),
    score = string.format("integer (0 to %d)", kMaxScore),
    accuracy = "float (0 to 100 by 0.01)",
    accuracyOnos = "float (-1 to 100 by 0.01)",
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
