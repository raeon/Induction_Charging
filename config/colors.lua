return function(config, makeImmutable)
    -- very complicated config file!
    config.colors = {}
    config.colors.count = 10
    config.colors.get = function(cur, min, max)
        -- Scale to effective range [min, max]
        local range = max - min
        cur = cur - min

        -- Determine how big one color range is
        local part = range / config.colors.count

        -- Determine what color range cur belongs to
        local index = math.min(math.floor(cur / part), config.colors.count - 1)
        return index
    end
    makeImmutable(config.colors)
end