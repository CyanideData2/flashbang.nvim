local config = require("flashbang.config")
local sound = require("flashbang.sound")
local network = require("flashbang.network")
local Job = require("plenary.job")
local debugPrint = require("flashbang.debug")

---@type string[]
local autocompletion = {
    config.options.username,
}

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
                    local updateCompletion = Job
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
                                debugPrint("autocompletion updated", false)
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
            debugPrint("autocompletion updated", false)
        end,
    }):start()
end
local function filterCompletion(ArgLead, CmdLine, CursorPos)
    ---@type string[]
    local completion = {}
    for k, v in pairs(autocompletion) do
        if v:find(ArgLead) then
            table.insert(completion, v)
        end
    end
    return completion
end

local function setupApi()
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
                local function urlEncode(str)
                    str = string.gsub(str, "([^%w%.%- ])", function(c)
                        return string.format("%%%02X", string.byte(c))
                    end)
                    str = string.gsub(str, " ", "+")
                    return str
                end

                network.sendFlash(args.args, urlEncode(message))
            end)
        end, -- string or Lua function
        {
            nargs = 1,
            complete = filterCompletion,
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
        print(grenade.displayname .. ": " .. grenade.message)
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
                    debugPrint("Just checked for flashes", false)
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

local Flashbang = {}

function Flashbang.setup(opts)
    config.setup(opts)
    sound.detect_provider()
    network.register()
    setupApi()
    completionWatcher()
    pullPin()
end

return Flashbang
