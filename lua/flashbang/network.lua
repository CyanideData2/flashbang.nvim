local config = require("flashbang.config")
local debugPrint = require("flashbang.debug")

local Network = {}

---@class flashbang
---@field message string
---@field username string
---@field displayname string

---@param callback fun(messages: flashbang[], err: string | nil): any
function Network.getFlash(callback)
    vim.system({
        "curl",
        config.options.endpoint .. "/get_unread?username=" .. config.options.username,
    }, {}, function(result)
        if result.code ~= 0 then
            callback({}, "Error: Failed to fetch messages")
            return
        end

        ---@type boolean, {messages: flashbang[]}
        local success, data = pcall(vim.json.decode, result.stdout)
        if not success then
            callback({}, "Error: Failed to parse JSON")
            return
        end

        callback(data.messages, nil)
    end)
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
    }, {}, function(result)
        if result.code ~= 0 then
            print("Error: Couldn't send a flashbang -> " .. result.stderr)
            return
        end
        print(result.stdout)
    end)
end

---@class user
---@field username string
---@field displayname string
---@field active boolean

---@param callback fun(messages: user[], err: string | nil): any
function Network.getUsers(callback)
    vim.system({ "curl", config.options.endpoint .. "/get_users_active" }, {}, function(result)
        if result.code ~= 0 then
            callback({}, "Error: Failed to fetch messages")
            return
        end

        ---@type boolean, {users: user[]}
        local success, data = pcall(vim.json.decode, result.stdout)
        if not success then
            callback({}, "Error: Failed to parse JSON")
            return
        end

        ---@type user[]
        local users = data.users
        callback(users, nil)
    end)
end

function Network.register()
    vim.system({
        "curl",
        config.options.endpoint
            .. "/register?username="
            .. config.options.username
            .. "&displayname="
            .. config.options.displayname,
    }, {}, function(result)
        if result.code ~= 0 then
            debugPrint("Error: Failed to log in", true)
            return
        end
        debugPrint("Logged into Flashbang.nvim", true)
    end)
end

return Network
