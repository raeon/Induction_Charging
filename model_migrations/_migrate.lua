
local migrations = {
    '1_1_0',
    '1_2_0',
    '1_2_2',
    '1_3_0',
    '1_3_7',
    '1_4_0',
    '1_5_0',
    '1_5_2',
    '1_5_7',
}

local function getNumbers(str)
    local strings = { string.match(str, '([0-9]+).([0-9]+).([0-9]+)') }
    local numbers = {}
    for k, v in pairs(strings) do
        numbers[k] = tonumber(v)
    end
    return numbers
end

local function getVersion(str)
    str = str or '0.0.0'
    local nums = getNumbers(str)
    return setmetatable({
        string = str,
        numbers = nums,
    }, {
        __eq = function(left, right)
            return left.string == right.string
        end,
        __lt = function(left, right)
            for i=1,3,1 do
                if left.numbers[i] < right.numbers[i] then
                    return true
                elseif left.numbers[i] > right.numbers[i] then
                    return false
                end
            end
            return false
        end,
    })
end

-- Require BEFOREHAND! Does NOT work during on_configuration_changed!
for k, version in pairs(migrations) do
    migrations[k] = {
        version = getVersion(version),
        func = require('model_migrations/' .. version),
    }
end

-- Return a function that will invoke all correct migrations
return function(previousVersion, currentVersion)
    -- Convert version string to version object
    previousVersion = getVersion(previousVersion)
    currentVersion = getVersion(currentVersion)

    -- Run all migrations that are necessary!
    for _, migration in pairs(migrations) do
        if migration.version > previousVersion
        and migration.version <= currentVersion then
            migration.func()
        end
    end
end