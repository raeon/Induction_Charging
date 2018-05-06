
function classify(class)
    setmetatable(class, {
        __call = function(class, ...)
            -- Create instance table
            local inst = {}

            -- Set metatable *before* constructor so they can invoke
            -- other functions during construction
            classifyInstance(inst, class)

            -- Invoke constructor
            class.New(inst, ...)

            return inst
        end,
        __newindex = function(index)
            error('Cannot modify class: ' .. index)
        end,
        __metatable = true,
    })
    return class
end

function classifyInstance(inst, class)
    setmetatable(inst, {
        __index = class,
        -- Newindex not implemented because we use nil as a correct value
        -- __newindex = function(tbl, key)
        --     error('Cannot change instance at runtime: ' .. key)
        -- end,
        __metatable = true,
    })
end

function makeImmutable(tbl)
    setmetatable(tbl, {
        __index = tbl,
        __newindex = true,
        __metatable = true,
    })
end

function math.round(num)
    return num >= 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)
end

function table.any(tbl)
    for k,v in pairs(tbl) do
        return true
    end
    return false
end

function table.shift(tbl, n)
    for k,v in pairs(tbl) do
        if type(k) == 'number' then
            tbl[k+n] = tbl[k]
            tbl[k] = nil
        end
    end
    return tbl
end

function table.keys(tbl)
    local keys = {}
    for k,v in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

function table.contains(tbl, key, val)
    for k,v in pairs(tbl) do
        if key ~= nil and k == key then return true end
        if val ~= nil and v == val then return true end
    end
end

function table.copy(tbl)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = v
    end
    return t
end

function table.with(tbl, k, v)
    local t = table.copy(tbl)
    if k == nil then
        table.insert(t, v)
    else
        t[k] = v
    end
    return t
end

function table.without(tbl, k, v)
    local t = table.copy(tbl)
    if k then
        t[k] = nil
    else
        for a, b in pairs(t) do
            if b == v then
                t[a] = nil
                break
            end
        end
    end
    return t
end

function table.count(tbl)
    local i = 0
    for k,v in pairs(tbl) do
        i = i + 1
    end
    return i
end

function table.offset(tbl, n)
    local meta = {
        __index = function(t, key)
            if type(key) == 'number' then key = key + n end
            --write('__index: ' .. key-n .. ' => ' .. key)
            return tbl[key]
        end,
        __newindex = function(t, key)
            if type(key) == 'number' then key = key + n end
            --write('__newindex: ' .. key-n .. ' => ' .. key)
            tbl[key] = value
        end,
        __metatable = false
    }
    return setmetatable({}, meta)
end

function table.fill(target, origin)
    if not target then target = {} end
    for k,v in pairs(origin) do
        if target[k] == nil then
            target[k] = v
        end
    end
    return target
end

local function getKeys(tbl)
    local keys, count = {}, 0
    for k in pairs(tbl) do
        table.insert(keys, k)
        count = count + 1
    end
    table.sort(keys)
    return keys, count
end

function spairs(tbl)
    local keys, count = getKeys(tbl)
    local index = 1
    return function()
        if index > count then
            return
        end

        local k = keys[index]
        local v = tbl[k]
        index = index + 1
        return k, v
    end
end

function ctable(name, ...)
    local args = {...}
    if #args == 1 and type(args[1]) == 'table' then
        args = args[1]
    end

    local meta = {
        __index = function(tbl, key)
            if type(key) == 'number' then key = key + 1 end
            --write(name, '__index: ' .. key-1 .. ' => ' .. key)
            return args[key] -- +1 because arrays start at 1 in Lua
        end,
        __newindex = function(tbl, key, value)
            if type(key) == 'number' then key = key + 1 end
            --write(name, '__newindex: ' .. key-1 .. ' => ' .. key)
            args[key] = value
        end
    }
    return setmetatable({}, meta)
end

function rerange(num, scope, target)
    -- Ensure num conforms to scope
    num = math.max(num, scope[1]) -- lower bound
    num = math.min(num, scope[2]) -- higher bound

    -- scope range => [0.0, 1.0]
    num = num - scope[1]
    num = num / (scope[2] - scope[1])

    -- [0.0, 1.0] => target range
    num = num * (target[2] - target[1])
    num = num + target[1]

    return num
end

function stringify(obj, stack)
    stack = stack or {}
    local t = type(obj)
    if t == 'nil' then
        return 'NIL'
    elseif t == 'boolean' then
        if obj then return 'TRUE' else return 'FALSE' end
    elseif t == 'number' then
        return '' .. obj
    elseif t == 'string' then
        return '"' .. obj .. '"'
    elseif t == 'userdata' then
        return '[userdata]'
    elseif t == 'function' then
        return '[function]'
    elseif t == 'thread' then
        return '[thread]'
    elseif t == 'table' then

        -- Get stack size & create padding for it
        local stacksize = table.count(stack)
        local padding = string.rep('  ', stacksize)

        -- Open table withOUT current padding: if we are already in a table,
        -- we already on a line containing "somekey = ".
        local result = '{\n'

        -- Include current table in stack, obviously
        stack = table.with(stack, nil, obj)

        local any = false
        local pad = padding .. '  '
        for k,v in pairs(obj) do
            any = true

            -- Table key
            if table.contains(stack, nil, k) then
                result = result .. pad .. '[recursion] = '
            else
                -- After a new line, add padding, "key" = "..."
                result = result .. pad .. stringify(k, stack) .. ' = '
            end

            -- Table value
            if table.contains(stack, nil, v) then
                result = result .. '[recursion]' .. ',\n'
            else
                -- After a key and equals, we add the value, comma and newline
                result = result .. stringify(v, stack) .. ',\n'
            end
        end

        -- Cut off last \n and comma
        if any then
            result = string.sub(result, 1, string.len(result) - 2)
        end

        -- Newline, less padding, close bracket, and NO newline
        result = result .. '\n' .. padding .. '}'

        return result
    end

end

function distance(x, y)
    return math.sqrt(math.pow(x, 2) + math.pow(y, 2))
end

function prettyTime(seconds)

    if seconds < 0 then
        return 'Never'
    end

    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60

    local hours = math.floor(minutes / 60)
    minutes = minutes % 60

    local days = math.floor(hours / 24)
    hours = hours % 24

    local weeks = math.floor(days / 7)
    days = days % 7

    local years = math.floor(weeks / 52)
    weeks = weeks % 52

    local result = ''
    local before = false
    if years > 0 then
        result = result .. stringify(years) .. 'y '
    end
    if weeks > 0 then
        result = result .. stringify(weeks) .. 'w '
    end
    if days > 0 then
        result = result .. stringify(days) .. 'd '
    end
    if hours > 0 then
        result = result .. stringify(hours) .. 'h '
    end
    if minutes > 0 then
        result = result .. stringify(minutes) .. 'm '
    end
    if seconds > 0 then
        result = result .. stringify(seconds) .. 's'
    end
    if result == '' then
        result = 'Now'
    end

    return result
end

function prettyNumber(num, scales, decimals)
    scales = scales or {
        k = 1000,
        M = 1000000,
        G = 1000000000,
    }
    decimals = decimals or 2
    if num ~= num then num = 0 end -- nan

    local highest = nil
    local absNum = math.abs(num)
    for suffix, scale in pairs(scales) do
        if (highest and (scale > highest.scale) and (absNum > scale))
        or ((highest == nil) and (absNum >= scale)) then
            highest = {suffix = suffix, scale = scale}
        end
    end

    if highest == nil then
        return tostring(num)
    end

    local decimalMult = math.pow(10, decimals)
    local number = math.round(num / highest.scale * decimalMult) / decimalMult
    local decs = tostring(number % 1)

    local result = tostring(number)
    local pointIndex = string.find(result, '%.') or -1
    local foundDecimals = string.len(string.sub(result, pointIndex + 1))
    if pointIndex < 0 then
        result = result .. '.'
        foundDecimals = 0
    end

    while foundDecimals < decimals do
        result = result .. '0'
        foundDecimals = foundDecimals + 1
    end
    return result .. highest.suffix
end

function prettyJoules(num)
    return prettyNumber(num, {
        J = 1,
        kJ = 1000,
        MJ = 1000000,
        GJ = 1000000000,
        TJ = 1000000000000,
    }, 2)
end

function prettyWatts(num)
    return prettyNumber(num, {
        W = 1,
        kW = 1000,
        MW = 1000000,
        GW = 1000000000,
        TW = 1000000000000,
    }, 2)
end

function lazyInit(initFunc)
    local cur = nil
    return setmetatable({}, {
        __index = function(tbl, key)
            -- Initialize if necessary
            cur = cur or initFunc()
            return cur[key]
        end,
        __newindex = function(tbl, key, val)
            -- Initialize if necessary
            cur = cur or initFunc()
            cur[key] = val
        end
    })
end

local function map(table, maxN, curN)
    return setmetatable(table, {
        __index = function(tbl, key)
            if not rawget(tbl, key) and curN ~= maxN then
                -- If it doesn't exist yet, new table
                rawset(tbl, key, mapN(maxN, curN + 1))
            end
            return rawget(tbl, key)
        end,
    })
end

function mapN(maxN, curN)
    maxN = maxN or -1
    curN = curN or 1
    return map({}, maxN, curN)
end

function remapN(tbl, maxN, curN)
    maxN = maxN or -1
    curN = curN or 1

    -- Remap every child table
    if curN ~= maxN then
        for k, v in pairs(tbl) do
            remapN(v, maxN, curN + 1)
        end
    end

    -- Remap current table
    return map(tbl, maxN, curN)
end

function string.startsWith(str, sub)
    return string.sub(str, 1, string.len(sub)) == sub
end

function string.endsWith(str, sub)
    return sub == '' or string.sub(str, -string.len(sub)) == sub
end

function table.join(arr, sep, sorting)
    local result = ''
    local first = true
    for k, v in pairs(sorting or arr) do
        local value = sorting and arr[k] or v
        if not first then
            result = result .. sep
        end
        first = false
        result = result .. tostring(value)
    end
    return result
end