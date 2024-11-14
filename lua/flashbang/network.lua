local config = require("flashbang.config")
local debugPrint = require("flashbang.debug")

local Network = {}

local counter = 0
function Network.getFlash()
    counter = counter + 1
    local betterRequest = vim.system({
        "curl",
        config.options.endpoint .. "/get_unread?username=" .. config.options.username,
    }):wait()
    debugPrint(betterRequest.stdout .. counter, false)
    local data = vim.json.decode(betterRequest.stdout)
    return data.messages
end

function Network.sendFlash(receiver, message)
    local function urlEncode(str)
        str = string.gsub(str, "([^%w%.%- ])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
        str = string.gsub(str, " ", "+")
        return str
    end
    local betterRequest = vim.system({
        "curl",
        config.options.endpoint
            .. "/send?sender="
            .. config.options.username
            .. "&receiver="
            .. receiver
            .. "&message="
            .. urlEncode(message),
    }, {}, function(obj)
        print(obj.stdout)
    end)
end

---@class user
---@field username string
---@field displayname string
---@field active boolean

---@return user[]
function Network.getUsers()
    local betterRequest = vim.system({ "curl", config.options.endpoint .. "/get_users_active" })
        :wait()
    local data = vim.json.decode(betterRequest.stdout)
    return data.users
end

function Network.register()
    local betterRequest = vim.system({
        "curl",
        config.options.endpoint
            .. "/register?username="
            .. config.options.username
            .. "&displayname="
            .. config.options.displayname,
    })
end

return Network
