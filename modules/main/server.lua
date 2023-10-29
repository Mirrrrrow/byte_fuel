local mysql = require 'modules.mysql.server'
lib.callback.register('fuel:server:buyFuel', function (source, id, price, litre)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer.getMoney() <= price then return false, locales['not_enough_money'] end
    local fuelStation = mysql.getFuelStation(id)
    if fuelStation.owner == 'NONE' then return true, locales['filling_successfull'] end
    if fuelStation.litre_remaining - litre < 0 then return false, locales['not_enough_gas'] end
    xPlayer.removeMoney(price)
    mysql.addValue(id, 'litre_remaining', -litre)
    mysql.addValue(id, 'money', price)
    return true, locales['filling_successfull']
end)