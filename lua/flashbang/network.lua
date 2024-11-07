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
    vim.notify(request.body)
    return request.body
end

---@class user
---@field username string
---@field displayname string
---@field active boolean

---@return user[]
function Network.getUsers()
    local request = curl.get(config.options.endpoint .. "/get_users_active")
    -- vim.notify(request.body)
    local data = vim.json.decode(request.body)
    ---@type user[]
    return data.users
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
