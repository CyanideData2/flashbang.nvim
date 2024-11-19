local config = require("flashbang.config")
local sound = require("flashbang.sound")
local network = require("flashbang.network")
local debugPrint = require("flashbang.debug")

local grenade = {}
function grenade.pullPin()
    local duration = config.options.duration * 1000
    local checkGap = 4000

    local deployTimer = vim.loop.new_timer()
    ---@param artifacts flashbang
    local function deploy(artifacts)
        if deployTimer ~= nil then
            sound.play("flashbang")
            local current = vim.g.colors_name
            print(artifacts.displayname .. ": " .. artifacts.message)
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
    end
    -- deploy()

    local function bridge(resolve, reject) end
    local deployIfFlashed = coroutine.create(function()
        while true do
            coroutine.yield()
            network.getFlash(function(messages, err)
                if err then
                    debugPrint(err)
                else
                    for _, v in pairs(messages) do
                        deploy(v)
                    end
                end
            end)
        end
    end)

    local function restartCoroutine()
        if coroutine.status(deployIfFlashed) ~= "running" then
            coroutine.resume(deployIfFlashed)
        end
    end

    local peakingTimer = vim.loop.new_timer()
    if peakingTimer ~= nil then
        peakingTimer:start(0, checkGap, restartCoroutine)
    end

    vim.api.nvim_create_autocmd("FocusLost", {
        desc = "Disable https requests in the background",
        group = vim.api.nvim_create_augroup("flashbang.nvim", { clear = true }),
        callback = function()
            if peakingTimer ~= nil then
                debugPrint("Not checking anymore")
                peakingTimer:stop()
            end
        end,
    })
    vim.api.nvim_create_autocmd("FocusGained", {
        desc = "Re-enable https requests on focus",
        group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
        callback = function()
            if peakingTimer ~= nil then
                debugPrint("checking again")
                peakingTimer:start(0, checkGap, restartCoroutine)
            end
        end,
    })
end

return grenade
