local network = require("flashbang.network")
local config = require("flashbang.config")
local debugPrint = require("flashbang.debug")

local api = {}

---@type user[]
local autocompletion = {
    config.options.username,
}

---@param ArgLead string
local function filterCompletion(ArgLead, _, _)
    ---@type string[]
    local completion = {}
    local j = string.len(ArgLead)
    if config.options.autoCompleteInactive then
        for _, v in pairs(autocompletion) do
            if string.sub(v.username, 0, j) == ArgLead then
                table.insert(completion, v.username)
            end
        end
    else
        for _, v in pairs(autocompletion) do
            if v.active and string.sub(v.username, 0, j) == ArgLead then
                table.insert(completion, v.username)
            end
        end
    end
    return completion
end

local function completionWatcher()
    local userGap = 3000

    local request = coroutine.create(function()
        while true do
            coroutine.yield()
            network.getUsers(function(messages, err)
                if err then
                    debugPrint(err)
                else
                    autocompletion = messages
                end
            end)
        end
    end)

    local userTimer = vim.loop.new_timer()
    if userTimer ~= nil then
        userTimer:start(
            0,
            userGap,
            vim.schedule_wrap(function()
                if coroutine.status(request) ~= "running" then
                    coroutine.resume(request)
                end
            end)
        )
    end
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
