local fuel_stations = require 'data.fuel_stations'
local fueling_config = require 'data.fueling'
fueling = {}


function fueling.selectScenario()
    local index = math.random(1, #fueling_config.scenarios)
    return fueling_config.scenarios[index]
end

function fueling.checkTime()
    local countingUp = 0
    local waited = 0
    while fueling.isFueling do
        Wait(0)
        waited = waited + 1
        if waited == 60 * 1000 then
            countingUp = countingUp + 1
            waited = 0
        end
        if countingUp >= 15 or fueling.hasToStop then
            fueling.isFueling = false
            fueling.hasToStop = false
            if fueling.currentCar ~= nil then
                DeleteEntity(NetworkGetEntityFromNetworkId(fueling.currentCar))
            end
            if fueling.currentTrailer ~= nil then
                DeleteEntity(NetworkGetEntityFromNetworkId(fueling.currentTrailer))
            end
            if fueling.currentPed ~= nil then
                DeleteEntity(NetworkGetEntityFromNetworkId(fueling.currentPed))
            end
            notify.send('Tanklieferung', 'info', locales['livery_finished'], 5000)

            fueling.currentPed = nil
            fueling.currentCar = nil
            fueling.currentTrailer = nil
            lib.hideTextUI()
            break
        end
    end
end

function fueling.startProcess(id, name, car, trailer, customFueling)
    if fueling.isFueling then return end
    local currentStation
    for _, fuelStation in pairs(fuel_stations) do
        if fuelStation.id == id then currentStation = fuelStation break end
    end
    if currentStation then
        fueling.isFueling = true
        fueling.station = id
        local playerPed = PlayerPedId()
        ESX.Game.SpawnVehicle(car, vector3(currentStation.fueling.carSpawn.x,currentStation.fueling.carSpawn.y,currentStation.fueling.carSpawn.z ), currentStation.fueling.carSpawn.w, function (vehicle)
            notify.send(name, 'success', locales['livery_waypoint'], 5000)
            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

            local scenario = fueling.selectScenario()
            fueling.currentScenario = scenario
            fueling.currentCar = NetworkGetNetworkIdFromEntity(vehicle)
            RequestModel(scenario.pedHash)
            while not HasModelLoaded(scenario.pedHash) do
                Wait(500)
            end
            local ped = CreatePed(4, scenario.pedHash, scenario.pedPos.x, scenario.pedPos.y, scenario.pedPos.z, scenario.pedPos.w, true, true)
            fueling.currentPed = NetworkGetNetworkIdFromEntity(ped)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            TaskStartScenarioInPlace(ped, scenario.pedScenario, -1, true)
            SetNewWaypoint(scenario.pedPos.x, scenario.pedPos.y)
            local point = lib.points.new({
                coords = vector3(scenario.pedPos.x, scenario.pedPos.y, scenario.pedPos.z),
                distance = 1.5,
                nearby = function (self)
                    if IsControlJustReleased(0, 38) then
                        local retval = lib.alertDialog({
                            header = name,
                            content = locales['livery_confirm']:format(scenario.price),
                            cancel = true,
                            centered = true
                        })
                        if retval ~= 'confirm' then
                            fueling.hasToStop = true
                            notify.send(locales['livery_title'], 'error', locales['livery_fail'], 5000)
                            return
                        end
                        local hasMoney = lib.callback.await('fuel:server:checkMoney', false, scenario.price, true)
                        if not hasMoney then
                            fueling.hasToStop = true
                            notify.send(locales['livery_title'], 'error', locales['livery_fail'], 5000)
                            return
                        end
                        ESX.Game.SpawnVehicle(trailer, vector3(scenario.tankerPos.x, scenario.tankerPos.y, scenario.tankerPos.z), scenario.tankerPos.w, function (trailerVeh)
                            notify.send(locales['livery_title'], 'info', locales['livery_success'], 5000)
                            fueling.currentTrailer = NetworkGetNetworkIdFromEntity(trailerVeh)
                            FreezeEntityPosition(NetworkGetEntityFromNetworkId(fueling.currentPed), false)
                            SetNewWaypoint(customFueling.give.x, customFueling.give.y)
                        end, true)

                    end
                end,
                onEnter = function (self)
                    lib.showTextUI(locales['livery_interact'])
                end,
                onExit = function (self)
                    lib.hideTextUI()
                end
            })
            fueling.checkTime()
            point:remove()
        end, true)
    end
end


return fueling