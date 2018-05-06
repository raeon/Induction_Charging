
local function makeImmutable(tbl)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function()
            error('Cannot change config')
        end,
        __metatable = true,
    })
end

local config = { -- global
    excessFactor = 0.05,
}

require('tiers')(config, makeImmutable)
require('colors')(config, makeImmutable)

return makeImmutable(config)