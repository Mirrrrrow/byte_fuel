local fuel_stations = require 'data.fuel_stations'
local mysql = require 'modules.mysql.server'

require 'modules.managing.server'
require 'modules.fueling.server'
require 'modules.main.server'

Citizen.CreateThreadNow(function ()
    local success, _ = pcall(MySQL.scalar.await, 'SELECT 1 FROM fuel_stations')
    if not success then
        MySQL.update.await([[
            CREATE TABLE fuel_stations (
                `id` int(32) NOT NULL AUTO_INCREMENT,
                `owner` VARCHAR(255) NOT NULL DEFAULT 'NONE',
                `litre_preis` INT(32) NOT NULL DEFAULT 15,
                `litre_remaining` INT(32) NOT NULL DEFAULT 5000
                PRIMARY KEY (`id`)
            )
        ]])
    end
    
    Wait(0)

    for _, fuelStation in pairs(fuel_stations) do
        local results = mysql.getFuelStation(fuelStation.id)
        if results == false then
            MySQL.insert.await('INSERT INTO fuel_stations (id, owner, litre_preis, litre_remaining) VALUES (?, ?, ?, ?)', {
                fuelStation.id,
                'NONE',
                13,
                5000
            })
        end
    end
end)