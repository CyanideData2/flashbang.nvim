local api = vim.api
local fn = vim.fn
local config = require("flashbang.config")

local M = {}

local PROVIDERS = {
    {
        exe = "ffplay",
        cmd = "ffplay",
        arguments = {
            "-nodisp",
            "-autoexit",
            -- "-loglevel quiet",
        },
        ext = ".mp3",
    },
    { exe = "afplay", cmd = { "afplay" }, ext = ".mp3" },
    { exe = "paplay", cmd = { "paplay" }, ext = ".ogg" },
    { exe = "cvlc", cmd = { "cvlc", "--play-and-exit" }, ext = ".ogg" },
}

local sound_provider = nil
function M.detect_provider()
    for _, provider in ipairs(PROVIDERS) do
        if fn.executable(provider.exe) == 1 then
            api.nvim_echo({ { "Providing sound with " .. provider.exe .. "." } }, true, {})
            sound_provider = provider
            return
        end
    end

    local provider_names = {}
    for _, provider in ipairs(PROVIDERS) do
        provider_names[#provider_names + 1] = provider.exe
    end
    if #provider_names > 0 then
        api.nvim_echo({
            { "No sound provider found; you're missing out! Supported are: " },
            { table.concat(provider_names, ", ") .. "." },
        }, true, {})
    end
end

local music_job
function M.stop_music()
    if music_job then
        fn.jobstop(music_job)
        music_job = nil
    end
end

function M.play(name)
    if not sound_provider then
        return nil
    else
        local DIR = fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
        local soundFile = ("%s/%s%s"):format(DIR .. "/sound", name, sound_provider.ext)

        local request_command = {}

        table.insert(request_command, sound_provider.cmd)
        for key, value in pairs(sound_provider.arguments) do
            table.insert(request_command, value)
        end
        table.insert(request_command, soundFile)

        local betterRequest = vim.system(request_command)
    end
end

return M
