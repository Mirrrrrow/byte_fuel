mysql = {}

function mysql.getFuelStation(id)
    local results = MySQL.query.await('SELECT * FROM fuel_stations WHERE id = ? LIMIT 1', {id})
    return results[1] and results[1] or false
end

function mysql.setOwner(identifier, id)
    MySQL.update.await('UPDATE fuel_stations SET owner = ? WHERE id = ?', {
        identifier, id
    })
end

function mysql.changeValue(id, key, val)
    MySQL.update.await('UPDATE fuel_stations SET ' ..key.. ' = ? WHERE id = ?', {
        val, id
    })
end

function mysql.addValue(id, key, val)
    MySQL.update.await('UPDATE fuel_stations SET ' ..key.. ' = '..key..' + ? WHERE id = ?', {
        val, id
    })
end

return mysql