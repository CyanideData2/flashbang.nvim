local config = require("flashbang.config")

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

return function(message, shouldPrint)
    if config.options.debug and (shouldPrint == true or shouldPrint ~= nil) then
        print(dump(message))
    end
end
