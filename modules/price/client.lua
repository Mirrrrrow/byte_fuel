local fuel_stations = require 'data.fuel_stations'
local notify = require 'modules.notify.client'

local settings = require 'data.settings'

if settings['useCommand']  then
    RegisterCommand(settings['commandName'], function ()
        local elements, num = {}, 0
        for _, fuelStation in pairs(fuel_stations) do
            local fuelStationData = lib.callback.await('fuel:server:requestStationData', false, fuelStation.id)
            num += 1
            elements[num] = {
                title = fuelStation.label.. ' | ' ..fuelStationData.litre_preis.. '$/L',
                description = locales['set_waypoint'],
                onSelect = function ()
                    SetNewWaypoint(fuelStation.center.x, fuelStation.center.y)
                    notify.send(fuelStation.label, 'success', locales['waypoint_set'], 5000)
                end
            }
        end
        lib.registerContext({
            id = 'waypoint_fuels',
            title = locales['waypoint_title'],
            options = elements
        })
        lib.showContext('waypoint_fuels')
    end, false)
end