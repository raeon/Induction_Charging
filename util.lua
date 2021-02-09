--[[
    Induction Charging
    Copyright (C) 2021  Joris Klein Tijssink

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

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

function table.count(tbl)
    local i = 0
    for k,v in pairs(tbl) do
        i = i + 1
    end
    return i
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