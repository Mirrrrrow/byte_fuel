local fuel_stations = require 'data.fuel_stations'
local models = {
    -2007231801, 1339433404, 1694452750, 1933174915, -462817101, -469694731, -164877493
}

local function findNearest()
    local nearestFuelstation, nearestDistance = nil, -1
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    for _, fuelStation in pairs(fuel_stations) do
        local distance = #(playerCoords - vector3(fuelStation.center.x, fuelStation.center.y, fuelStation.center.z))
        if nearestDistance == -1 or (distance < nearestDistance) then
            nearestFuelstation = fuelStation
        end
    end
    return nearestFuelstation, nearestDistance
end

local function getVehicleInFront()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
	local destination = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 2.2, -0.25)
    local handle = StartShapeTestCapsule(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, 2.2, 2, playerPed, 4)

    while true do
        Wait(0)
        local retval, _, _, _, entityHit = GetShapeTestResult(handle)

        if retval ~= 1 then
            return entityHit ~= 0 and entityHit
        end
    end
end


local isFueling = false
CreateThread(function ()
    exports.ox_target:addModel(models, {
        {
            label = 'Fahrzeug betanken',
            icon = 'fa-solid fa-gas-pump',
            onSelect = function (data)
                local nearestFuelstation, nearestDistance = findNearest()
                local nearestVehicle = getVehicleInFront()
                if nearestVehicle == false then return notify.send(nearestFuelstation?.label, 'error', locales['no_car_nearby'], 5000) end
                
                local fuel = GetVehicleFuelLevel(nearestVehicle)
                local oldFuel = fuel
                local duration = math.ceil((100 - fuel) / settings.refillValue) * settings.refillTick

                local fuelStationData = lib.callback.await('fuel:server:requestStationData', false, nearestFuelstation?.id)


                isFueling = true
                CreateThread(function ()
                    lib.progressCircle({
                        duration = duration,
                        label = locales['fueling_process']:format(fuelStationData.litre_preis),
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            move = true,
                            car = true,
                            combat = true,
                        },
                        anim = {
                            dict = 'timetable@gardener@filling_can',
                            clip = 'gar_ig_5_filling_can'
                        },
                    })
                    isFueling = false
                end)

                while isFueling do
                    fuel += settings.refillValue

                    if fuel >= 100 then
                        isFueling = false
                        fuel = 100.0
                    end
                    Wait(settings.refillTick)
                end

                local fuelGain = math.ceil(fuel - oldFuel)
                local retval = lib.alertDialog({
                    content = locales['fuel_confirm']:format(fuelGain, fuelGain * fuelStationData.litre_preis),
                    header = nearestFuelstation?.label .. ' | ' ..fuelStationData.litre_preis.. '$/L',
                    cancel = true,
                    centered = true
                })
                if retval == 'cancel' then
                    return notify.send(nearestFuelstation?.label, 'error', locales['fuel_canceled'], 5000)
                end

                local success, retval = lib.callback.await('fuel:server:buyFuel', false, nearestFuelstation?.id, (fuelGain * fuelStationData.litre_preis), fuelGain)
                if success then
                    notify.send(nearestFuelstation?.label, 'success', retval, 5000)
                    SetVehicleFuelLevel(nearestVehicle, fuel)
                    return
                end

                notify.send(nearestFuelstation?.label, 'error', retval, 5000)

            end
        }
    })
end)