local config = require("flashbang.config")
local sound = require("flashbang.sound")
local network = require("flashbang.network")
local debugPrint = require("flashbang.debug")

local grenade = {}
function grenade.pullPin()
    local duration = config.options.duration * 1000
    local checkGap = 4000

    local function deploy(artifacts)
        sound.play("flashbang")
        local deployTimer = vim.loop.new_timer()
        local current = vim.g.colors_name
        print(artifacts.displayname .. ": " .. artifacts.message)
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

    local counter = 0
    local deployIfFlashed = coroutine.create(function()
        while true do
            coroutine.yield()
            counter = counter + 1
            local flashList = network.getFlash()
            for _, j in pairs(flashList) do
                deploy(j)
            end
        end
    end)
    local function check_grenades()
        local timer = vim.loop.new_timer()
        if timer ~= nil then
            timer:start(
                checkGap,
                0,
                vim.schedule_wrap(function()
                    timer:stop()
                    if coroutine.status(deployIfFlashed) ~= "running" then
                        debugPrint(counter, false)
                        coroutine.resume(deployIfFlashed)
                    end
                    check_grenades()
                end)
            )
        end
    end
    coroutine.resume(deployIfFlashed)
    check_grenades()
end

return grenade
