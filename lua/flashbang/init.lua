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

local function setupApi()
    vim.api.nvim_create_user_command(
        "Flash", -- string
        function(args)
            network.sendFlash(args.args, config.options.defaultMessage)
        end, -- string or Lua function
        { nargs = 1 }
    )
    vim.api.nvim_create_user_command(
        "FlashMessage", -- string
        function(args)
            vim.ui.input({}, function(message)
                network.sendFlash(args.args, message)
            end)
        end, -- string or Lua function
        { nargs = 1 }
    )
end

local function pullPin()
    local duration = config.options.duration * 1000
    local checkGap = 2000
    local function deploy(grenade)
        sound.play("flashbang")
        local deployTimer = vim.loop.new_timer()
        local current = vim.g.colors_name
        vim.notify(grenade.message)
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
        for i in pairs(flashList) do
            deploy(i)
        end
    end

    local timer = vim.loop.new_timer()

    local function recurring_deploy()
        if timer ~= nil then
            timer:start(
                checkGap,
                0,
                vim.schedule_wrap(function()
                    deployIfFlashed()
                    recurring_deploy()
                end)
            )
        end
    end
    recurring_deploy()
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
