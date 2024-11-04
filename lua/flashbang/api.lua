local network = require("flashbang.network")

return function()
    vim.api.nvim_create_user_command(
        "flash", -- string
        function(args)
            network.sendFlash(args[1])
        end, -- string or Lua function
        { nargs = 1 }
    )
    vim.api.nvim_create_user_command(
        "flashMessage", -- string
        function(args)
            network.sendFlash()
        end, -- string or Lua function
        { nargs = 1 }
    )
end
