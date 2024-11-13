local config = require("flashbang.config")
local sound = require("flashbang.sound")
local network = require("flashbang.network")

local Job = require("plenary.job")

local grenade = {}
function grenade.pullPin()
    local duration = config.options.duration * 1000
    local checkGap = 2000

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

    local function deployIfFlashed()
        Job
            :new({
                command = "curl",
                args = {
                    config.options.endpoint .. "/get_unread?username=" .. config.options.username,
                },
                on_exit = function(job_self, return_val)
                    -- debugPrint(job_self:result())
                    local isFlashed = vim.json.decode(job_self:result()[1])
                    local flashList = isFlashed.messages
                    for _, j in pairs(flashList) do
                        deploy(j)
                    end
                    -- debugPrint("Just checked for flashes", false)
                end,
            })
            :start()
    end

    local function check_grenades()
        local timer = vim.loop.new_timer()
        if timer ~= nil then
            timer:start(
                checkGap,
                0,
                vim.schedule_wrap(function()
                    timer:stop()
                    deployIfFlashed()
                    check_grenades()
                end)
            )
        end
    end
    check_grenades()
end

return grenade
