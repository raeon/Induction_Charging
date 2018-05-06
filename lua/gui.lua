local g = {}
local mod_gui = require('mod-gui')

local outputs = {
    -- ic_output_efficiency = function(tracker, grid)
    --     return 'Efficiency: ', tracker:GetEfficiency() * 100, '%'
    -- end,
    -- ic_output_throughput_base = function(tracker, grid)
    --     return 'Base throughput per coil: ', tracker:GetThroughput(), 'W'
    -- end,
    ic_output_throughput_current = function(tracker, grid)
        local available = (grid and grid.throughput or 1)
        local current = tracker.lastThroughput
        return 'Throughput: ', prettyWatts(current), ' (', math.round(current / available * 10000) / 100, '%)'
    end,
    ic_output_battery_charge = function(tracker, grid)
        local energy = math.max(0, grid and grid.energy or 0)
        local capacity = (grid and grid.capacity or 0)
        local percentage = (capacity > 0 and (math.round(energy / capacity * 10000) / 100) or 100)
        return 'Charge: ', prettyJoules(energy), ' (', percentage, '%)'
    end,
    ic_output_battery_full_in = function(tracker, grid)
        local remaining = (grid and (grid.capacity - grid.energy) or 0)
        local last = tracker.lastThroughput

        local seconds = (remaining > 0 and last <= 0 and -1) or
                        (remaining > 0 and last > 0 and math.ceil(remaining/last)) or 0

        -- If remaining > 0 and last == 0, seconds should be -1
        -- If remaining > 0 and last != 0, seconds should be calculated
        -- If remaining == 0, seconds should be 0

        return 'Full in: ', prettyTime(seconds)
    end,
}

function g:New(tracker)
    self.tracker = tracker
    self.canBeVisible = false
    self.wantVisible = true
    self.tick = 0
end

function g:Renew()
end

function g:Fix()
    self.tick = self.tick or 0
end

function g:Update()

    -- Increase update count
    self.tick = self.tick + 1
    if self.tick < global.guiTickrate then
        return
    end
    self.tick = 0

    -- Just kidding! Do nothing if we're not a player.
    if not self.tracker.entity.is_player() then
        return
    end

    -- Hide if we are visible but shouldn't be,
    -- or if we are not wanted visible.
    if (not self.canBeVisible) or (not self.wantVisible) then
        self:Hide()
        return
    end

    -- Show if we aren't visible but should be
    if not self:Exists() then
        self:Show()
    end

    -- Get frame
    local area = mod_gui.get_button_flow(self.tracker.entity)
    local frame = area['ic_stats']

    -- Delete no-longer existing outputs
    for name, lbl in pairs(frame.children) do
        if not outputs[name] then
            lbl.destroy()
        end
    end

    -- Update all outputs
    for name, func in pairs(outputs) do

        -- Get the label instance
        local lbl = frame[name] or frame.add({
            type = 'label',
            name = name,
            caption = 'Please wait..',
        })

        -- Invoke the updating function and capture the results
        local results = { func(self.tracker, self.tracker.grid) }
        local output = ''

        for _, result in pairs(results) do
            output = output .. tostring(result)
        end

        -- Update label caption
        lbl.caption = output
    end

end

function g:Show()
    if not self:Valid() then return end

    local area = mod_gui.get_button_flow(self.tracker.entity)

    -- Create the frame
    local frame = area.add({
        type = 'table',
        name = 'ic_stats',
        direction = 'vertical',
        style = 'ic_stats',
        column_count = 1,
    })

    -- Add output labels
    local lbl
    for name, func in pairs(outputs) do
        lbl = frame.add({
            type = 'label',
            name = name,
            caption = 'Please wait..',
            style = 'ic_label',
        })
    end
end

function g:Hide(force)
    if (not force) and (not self:Valid()) then return end
    local area = mod_gui.get_button_flow(self.tracker.entity)

    local frame = area['ic_stats']
    if frame then
        frame.destroy()
    end
end

function g:Visible(visible)
    self.canBeVisible = visible or false
end

function g:WantVisible()
    self.wantVisible = not self.wantVisible
end

function g:Exists()
    return mod_gui.get_button_flow(self.tracker.entity)['ic_stats'] ~= nil
end

function g:Valid()
    return self.tracker:Valid()
end

return classify(g)