local curl = require("plenary.curl")
local config = require("flashbang.config")

local Network = {}

local function dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            s = s .. "[" .. k .. "] = " .. dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

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
    -- print(dump(request.body))
    -- local data = vim.json.decode(request.body)
    -- return data
end

function Network.register()
    local request = curl.get(
        config.options.endpoint
            .. "/register?username="
            .. config.options.username
            .. "&displayname="
            .. config.options.displayname
    )
end

return Network
