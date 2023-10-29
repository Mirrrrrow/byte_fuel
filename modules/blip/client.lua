local fuel_stations = require 'data.fuel_stations'

CreateThread(function ()
    for _, fuelStation in pairs(fuel_stations) do
        local blip = AddBlipForCoord(fuelStation.center.x, fuelStation.center.y, fuelStation.center.z)
        SetBlipSprite(blip, fuelStation.blip.sprite)
        SetBlipColour(blip, fuelStation.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(fuelStation.blip.name)
        EndTextCommandSetBlipName(blip)
    end
end)