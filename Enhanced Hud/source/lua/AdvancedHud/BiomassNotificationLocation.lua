local kBiomassNotificationLocationMessage =
{
    entityId = "entityid",
    techId = "integer",
    locationName = "string (64)"
}
Shared.RegisterNetworkMessage("BiomassNotificationLocation", kBiomassNotificationLocationMessage)

gBiomassNotificationLocationCache = gBiomassNotificationLocationCache or {}
gBiomassNotificationLocationByTechIdCache = gBiomassNotificationLocationByTechIdCache or {}

function SetBiomassNotificationLocation(entityId, techId, locationName)
    if entityId and entityId ~= Entity.invalidId then
        gBiomassNotificationLocationCache[entityId] = locationName or ""
    end

    if techId and techId > 0 then
        gBiomassNotificationLocationByTechIdCache[techId] = locationName or ""
    end
end

function GetBiomassNotificationLocation(entityId)
    if not entityId or entityId == Entity.invalidId then
        return ""
    end

    return gBiomassNotificationLocationCache[entityId] or ""
end

function GetBiomassNotificationLocationForTech(techId)
    if not techId or techId <= 0 then
        return ""
    end

    return gBiomassNotificationLocationByTechIdCache[techId] or ""
end

if Client then
    local function OnBiomassNotificationLocation(message)
        SetBiomassNotificationLocation(message.entityId, message.techId, message.locationName)
    end

    Client.HookNetworkMessage("BiomassNotificationLocation", OnBiomassNotificationLocation)
end
