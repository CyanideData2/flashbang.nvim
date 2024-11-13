local network = require("flashbang.network")
local config = require("flashbang.config")
local Job = require("plenary.job")

local api = {}

---@type string[]
local autocompletion = {
    config.options.username,
}

local function filterCompletion(ArgLead, _, _)
    ---@type string[]
    local completion = {}
    for _, v in pairs(autocompletion) do
        if v:find(ArgLead) then
            table.insert(completion, v)
        end
    end
    return completion
end

local function completionWatcher()
    local userGap = 10000

    local userTimer = vim.loop.new_timer()
    local function checkCompletion()
        if userTimer ~= nil then
            userTimer:start(
                userGap,
                0,
                vim.schedule_wrap(function()
                    userTimer:stop()
                    Job
                        :new({
                            command = "curl",
                            args = { config.options.endpoint .. "/get_users_active" },
                            on_exit = function(job_self, return_val)
                                ---@type string[]
                                -- debugPrint(type(job_self:result()[1]), true)
                                autocompletion = {}
                                local data = vim.json.decode(job_self:result()[1])
                                for _, v in pairs(data.users) do
                                    table.insert(autocompletion, v.username)
                                end
                                checkCompletion()
                                -- debugPrint("autocompletion updated", false)
                            end,
                        })
                        :start()
                end)
            )
        end
    end

    Job:new({
        command = "curl",
        args = { config.options.endpoint .. "/get_users_active" },
        on_exit = function(job_self, return_val)
            ---@type string[]
            -- debugPrint(type(job_self:result()[1]), true)
            autocompletion = {}
            local data = vim.json.decode(job_self:result()[1])
            for _, v in pairs(data.users) do
                table.insert(autocompletion, v.username)
            end
            checkCompletion()
            -- debugPrint("autocompletion updated", false)
        end,
    }):start()
end

function api.setup()
    vim.api.nvim_create_user_command(
        "Flash", -- string
        function(opts)
            network.sendFlash(opts.args, config.options.defaultMessage)
        end, -- string or Lua function
        {
            nargs = 1,
            complete = filterCompletion,
        }
    )
    vim.api.nvim_create_user_command(
        "FlashMessage", -- string
        function(args)
            vim.ui.input({ prompt = "Message to Target: " }, function(message)
                network.sendFlash(args.args, message)
            end)
        end, -- string or Lua function
        {
            nargs = 1,
            complete = filterCompletion,
        }
    )
    completionWatcher()
end
return api
