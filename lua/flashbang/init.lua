local config = require("flashbang.config")
local sound = require("flashbang.sound")
local network = require("flashbang.network")

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

---@type string[]
local autocompletion = {
    config.options.username,
}

local function updateCompletion()
    local userGap = 10000
    ---@type string[]
    autocompletion = {}
    local users = network.getUsers()
    for _, v in pairs(users) do
        table.insert(autocompletion, v.username)
    end

    local userTimer = vim.loop.new_timer()
    local function checkCompletion()
        if userTimer ~= nil then
            userTimer:start(
                userGap,
                0,
                vim.schedule_wrap(function()
                    userTimer:stop()
                    users = network.getUsers()
                    for _, v in pairs(users) do
                        table.insert(autocompletion, v.username)
                    end
                    checkCompletion()
                end)
            )
        end
    end
end
local function setupApi()
    vim.api.nvim_create_user_command(
        "Flash", -- string
        function(opts)
            network.sendFlash(opts.args, config.options.defaultMessage)
        end, -- string or Lua function
        {
            nargs = 1,
            complete = function(ArgLead, CmdLine, CursorPos)
                return autocompletion
            end,
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
            complete = function(ArgLead, CmdLine, CursorPos)
                return autocompletion
            end,
        }
    )
end

local function pullPin()
    local duration = config.options.duration * 1000
    local checkGap = 2000
    local function deploy(grenade)
        sound.play("flashbang")
        local deployTimer = vim.loop.new_timer()
        local current = vim.g.colors_name
        vim.notify(grenade.displayname .. ": " .. grenade.message)
        if deployTimer ~= nil then
            return deployTimer:start(
                1300,
                0,
                vim.schedule_wrap(function()
                    vim.cmd("colorscheme delek")
                    vim.cmd("set background=light")
                    deployTimer:start(
                        duration,
                        0,
                        vim.schedule_wrap(function()
                            vim.cmd("colorscheme " .. current)
                            vim.cmd("set background=dark")
                        end)
                    )
                end)
            )
        end
    end
    -- deploy()

    local function deployIfFlashed()
        local isFlashed = network.getFlash()
        local flashList = isFlashed.messages
        for _, j in pairs(flashList) do
            print(dump(j))
            deploy(j)
        end
    end

    local function check_grenades()
        local timer = vim.loop.new_timer()
        if timer ~= nil then
            timer:start(
                checkGap,
                0,
                vim.schedule_wrap(function()
                    timer:stop()
                    updateCompletion()
                    deployIfFlashed()
                    check_grenades()
                end)
            )
        end
    end
    check_grenades()
end

local Flashbang = {}

function Flashbang.setup(opts)
    config.setup(opts)
    sound.detect_provider()
    network.register()
    setupApi()
    pullPin()
end

return Flashbang
