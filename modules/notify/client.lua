notify = {}

function notify.send(title, type, message, time)
    lib.notify({
        title = title,
        type = type,
        duration = time,
        description = message
    })
end

return notify
