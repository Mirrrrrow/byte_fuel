Shared = {}
locales = require 'data.locales'

if IsDuplicityVersion() then
    Server = {}
else
    Client = {}
end

if lib.context == 'server' then
    local resource = GetCurrentResourceName()

    local currentVersion = GetResourceMetadata(resource, 'version', 0)
    if currentVersion == 'Development Build' then
        warn('You are running a development build of the Fuel System. Please do not use this in production.')
    end
    return require 'server'
end


require 'client'
