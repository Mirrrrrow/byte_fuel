local menu = {}
local notify = require 'modules.notify.client'
local fueling = require 'data.fueling'
local fueling_process = require 'modules.fueling.client'

function menu.openBuy(id, name, price)
    local retval = lib.alertDialog({
        header = name,
        content = locales['buy_fuel_station']:format(price),
        centered = true,
        cancel = true
    })
    if retval ~= 'confirm' then return end
    local success, msg = lib.callback.await('fuel:server:requestBuy', false, id, price, name)
    notify.send(name, success and 'success' or 'error', msg, 5000)
end

function menu.openManager(id, name, price, customFueling)
    local data = lib.callback.await('fuel:server:requestStationData', false, id)
    if data == false then return notify.send(name, 'error',locales['not_owner'], 5000) end
    lib.registerContext({
        id = 'fuel_manager_' .. id,
        title = name,
        options = {
            {
                title = locales['change_litre_price']:format(data.litre_preis),
                description = locales['change_litre_price_desc'],
                icon = 'gas-pump',
                onSelect = function()
                    local retval = lib.inputDialog(name, {
                        {
                            label = locales['change_litre_price_input'],
                            type = 'number',
                            default = data.litre_preis,
                            required = true
                        }
                    })
                    if not retval or not retval[1] then return notify.send(name, 'error', locales['change_canceled'], 5000) end
                    local success, msg = lib.callback.await('fuel:server:tryChange', false, 'litre_preis', id, retval[1])
                    notify.send(name, success and 'success' or 'error', msg, 5000)
                end
            },
            {
                title = locales['pay_out']:format(data.money),
                description = locales['pay_out_desc'],
                icon = 'bag-shopping',
                onSelect = function ()
                    local success, msg = lib.callback.await('fuel:server:tryGetMoney', false, id)
                    notify.send(name, success and 'success' or 'error', msg, 5000)
                end
            },
            {
                title = locales['sell_fuel_station']:format(math.floor(price - ((price / 100) * 15))),
                description = locales['sell_fuel_station_desc'],
                icon = 'money-bill',
                onSelect = function()
                    local sell_price = math.floor(price - ((price / 100) * 15))
                    local retval = lib.alertDialog({
                        content = locales['sell_fuel_station_confirm']:format(name, sell_price),
                        header = name,
                        cancel = true,
                        centered = true
                    })
                    if retval ~= 'confirm' then
                        return notify.send(name, 'error', locales['sell_canceled'], 5000)
                    end
                    local success, msg = lib.callback.await('fuel:server:tryChange', false, 'owner', id, 'NONE', sell_price, 'Verkauf von ' ..name)
                    notify.send(name, success and 'success' or 'error', msg, 5000)
                    lib.callback.await('fuel:server:resetFuel', false, id)
                end
            },
            {
                title = locales['refill']:format(data.litre_remaining),
                description = locales['refill_desc'],
                icon = 'truck-fast',
                onSelect = function ()
                    local canManage = lib.callback.await('fuel:server:checkOwned', false, id)
                    if canManage ~= 1 then
                        return notify.send(name, 'error', locales['not_owner'], 5000)
                    end
                    fueling_process.startProcess(id, name, fueling.car, fueling.trailer, customFueling)

                end
            }
        }
    })
    lib.showContext('fuel_manager_' .. id)
end

return menu
