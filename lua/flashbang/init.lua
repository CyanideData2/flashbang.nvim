local config = require("flashbang.config")
local sound = require("flashbang.sound")
local network = require("flashbang.network")
local api = require("flashbang.api")
local grenade = require("flashbang.m84")

local Flashbang = {}

function Flashbang.setup(opts)
    config.setup(opts)
    sound.detect_provider()
    network.register()
    api.setup()
    grenade.pullPin()
end

return Flashbang
