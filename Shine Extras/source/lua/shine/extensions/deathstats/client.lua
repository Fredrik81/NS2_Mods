local Plugin = ...


local function dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            s = s .. "[" .. k .. "] = " .. dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

function Plugin:Initialise()
    self.Enabled = true

    HPrint(Plugin.PrintName .. ", version " .. Plugin.Version .. " loaded.")
    -- Shine.Hook.SetupClassHook("GUIUnitStatus", "UpdateUnitStatusBlip", "mapBlipUpdates", "PassivePost")

    -- Alert hook
    Shine.Hook.SetupClassHook("GUICommanderAlerts", "AddMessage", "newAlert", "PassivePost")

    return true
end



function Plugin:Cleanup()
    self.BaseClass.Cleanup(self)

    self.Enabled = false
end
