local mysql = require 'modules.mysql.server'
lib.callback.register('fuel:server:checkOwned', function (source, id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local fuel_station = mysql.getFuelStation(id)
    if fuel_station.owner == 'NONE' then return 2 end
    return fuel_station.owner == xPlayer.getIdentifier() and 1 or 0
end)

lib.callback.register('fuel:server:requestBuy', function (source, id, price, name)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local fuel_station = mysql.getFuelStation(id)
    if fuel_station.owner ~= 'NONE' then return false, locales['station_already_owned'] end
    if xPlayer.getMoney() < price then return false, locales['not_enough_money'] end
    xPlayer.removeMoney(price, 'Kauf von ' ..name)
    mysql.setOwner(xPlayer.getIdentifier(), id)
    return true, 'Kauf erfolgreich!'
end)

lib.callback.register('fuel:server:requestStationData', function (source, id)
    local fuel_station = mysql.getFuelStation(id)
    return fuel_station
end)

lib.callback.register('fuel:server:tryChange', function (source, key, id, val, money, note)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local fuel_station = mysql.getFuelStation(id)
    if fuel_station.owner ~= xPlayer.getIdentifier() then return false, locales['not_owner'] end
    mysql.changeValue(id, key, val)
    if money then xPlayer.addMoney(money, note) end
    return true, locales['change_success']
end)

lib.callback.register('fuel:server:tryGetMoney', function (source, id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local fuel_station = mysql.getFuelStation(id)
    if fuel_station.owner ~= xPlayer.getIdentifier() then return false, locales['not_owner']end
    if fuel_station.money == 0 then return false, locales['not_enough_money'] end
    xPlayer.addMoney(fuel_station.money)
    mysql.changeValue(id, 'money', 0)
    return true, locales['money_payed_out']
end)

lib.callback.register('fuel:server:addFuel', function (source, id, reward)
    mysql.addValue(id, 'litre_remaining', reward)
end)

lib.callback.register('fuel:server:resetFuel', function (source, id)
    MySQL.update.await('UPDATE fuel_stations SET litre_remaining = 5000, litre_preis = 13, money = 0 WHERE id = ?', {id})
end)