local curl = require("plenary.curl")
local config = require("flashbang.config")

local Network = {}

function Network.getFlash()
    local request =
        curl.get(config.options.endpoint .. "/get_unread?username=" .. config.options.username)
    local data = vim.json.decode(request.body)
    return data
end

function Network.sendFlash(receiver, message)
    local request = curl.get(
        config.options.endpoint
            .. "/send?sender="
            .. config.options.username
            .. "&receiver="
            .. receiver
            .. "&message="
            .. message
    )
    return request.body
end

function Network.register()
    local request = curl.get(
        config.options.endpoint
            .. "/register?username="
            .. config.options.username
            .. "&displayname="
            .. config.options.displayname
    )
    return request.body
end

return Network
