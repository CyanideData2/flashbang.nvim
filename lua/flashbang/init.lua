local config = require("flashbang.config")
local sound = require("flashbang.sound")

local Flashbang = {}

function Flashbang.setup(opts)
    Flashbang.config = config.setup(opts)

    sound.detect_provider()

    local min_interval = Flashbang.config.min_interval * 1000 * 60
    local max_interval = Flashbang.config.max_interval * 1000 * 60
    local duration = Flashbang.config.duration * 1000

    local function deploy()
        sound.play("flashbang")
        local deployTimer = vim.loop.new_timer()
        local current = vim.g.colors_name
        deployTimer:start(
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
    -- deploy()

    local timer = vim.loop.new_timer()
    local function recurring_deploy()
        if timer == nil then
            return
        end
        timer:start(
            math.random(min_interval, max_interval),
            0,
            vim.schedule_wrap(function()
                deploy()
                recurring_deploy()
            end)
        )
    end

    -- vim.api.nvim_create_autocmd("VimLeavePre", {
    --     desc = "Close sound timers on exit",
    --     callback = function()
    --         if timer ~= nil then
    --             timer:stop()
    --         end
    --     end,
    -- })
    recurring_deploy()
end

Flashbang = Flashbang

return Flashbang
