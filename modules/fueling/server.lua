lib.callback.register('fuel:server:checkMoney', function (source, price, remove)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer.getMoney() >= price then
        if remove then xPlayer.removeMoney(price) end
        return true
    end
    return false
end)