local kDeathStatsMessage =
{
    lastAcc = "float (0 to 100 by 0.01)",
    lastAccOnos = "float (-1 to 100 by 0.01)",
    currentAcc = "float (0 to 100 by 0.01)",
    currentAccOnos = "float (-1 to 100 by 0.01)",
    pdmg = "float (0 to 524287 by 0.01)",
    sdmg = "float (0 to 524287 by 0.01)",
    kills = string.format("integer (0 to %d)", kMaxKills),
	Healing = "integer (0 to 524287)"
}
Shared.RegisterNetworkMessage("DeathStats", kDeathStatsMessage)
