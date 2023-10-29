local fuel_stations = require 'data.fuel_stations'
local menu = require 'modules.menu.client'
local notify = require 'modules.notify.client'
CreateThread(function ()
    for _, fuelStation in pairs(fuel_stations) do
        lib.points.new({
            coords = fuelStation.buy,
            distance = 1.5,
            onEnter = function (self)
                lib.showTextUI(locales['press_e_to_manage'])
            end,
            onExit = function (self)
                lib.hideTextUI()
            end,
            nearby = function (self)
                if IsControlJustReleased(0, 38) then
                    local canManage = lib.callback.await('fuel:server:checkOwned', false, fuelStation.id)
                    -- 2 = NO OWNER; 1 = Player is Owner; 0 = Player isn't owned
                    if canManage == 2 then
                        menu.openBuy(fuelStation.id, fuelStation.label, fuelStation.price)
                    elseif canManage == 1 then
                        menu.openManager(fuelStation.id, fuelStation.label, fuelStation.price, fuelStation.fueling)
                    else
                        notify.send(fuelStation.label, 'error', locales['not_owner'], 5000)
                    end
                end
            end
        })
        lib.points.new({
            coords = fuelStation.fueling.give,
            distance = 20.0,
            onEnter = function (self)
                if fueling.isFueling and fueling.station == fuelStation.id then
                    lib.showTextUI(locales['press_e_to_give_livery'])
                end
            end,
            onExit = function (self)
                if fueling.isFueling and fueling.station == fuelStation.id then
                    lib.hideTextUI()
                end
            end,
            nearby = function (self)
                if fueling.isFueling and fueling.station == fuelStation.id then
                    if IsControlJustReleased(0, 38) then
                        local playerPed = PlayerPedId()
                        local playerCoords = GetEntityCoords(playerPed)
                        print(#(playerCoords - GetEntityCoords(NetworkGetEntityFromNetworkId(fueling.currentTrailer))))
                        if #(playerCoords - GetEntityCoords(NetworkGetEntityFromNetworkId(fueling.currentTrailer))) < 20.0 then
                            lib.callback.await('fuel:server:addFuel', false, fuelStation.id, fueling.currentScenario.reward)
                            fueling.hasToStop = true
                        end
                    end
                end

            end
        })
    end
end)
