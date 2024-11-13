local config = require("flashbang.config")
local Job = require("plenary.job")
local curl = require("plenary.curl")

local Network = {}

function Network.getFlash()
    local request =
        curl.get(config.options.endpoint .. "/get_unread?username=" .. config.options.username)
    local data = vim.json.decode(request.body)
    return data
end

function Network.sendFlash(receiver, message)
    local updateCompletion = Job:new({
        command = "curl",
        args = {
            config.options.endpoint
                .. "/send?sender="
                .. config.options.username
                .. "&receiver="
                .. receiver
                .. "&message="
                .. message,
        },
        on_exit = function(job_self, return_val)
            print(job_self:result()[1])
        end,
    }):start()
end

---@class user
---@field username string
---@field displayname string
---@field active boolean

---@return user[]
function Network.getUsers() end

function Network.register()
    local updateCompletion = Job:new({
        command = "curl",
        args = {
            config.options.endpoint
                .. "/register?username="
                .. config.options.username
                .. "&displayname="
                .. config.options.displayname,
        },
        on_exit = function(job_self, return_val)
            print("Flashbang Ready")
        end,
    }):start()
end

return Network
