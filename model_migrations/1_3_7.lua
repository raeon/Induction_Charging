return function()
    log('Removing \'neighbours\' field from all equipment references')
    for _, tracker in pairs(global.trackers) do
        for _, row in pairs(tracker.grid.map) do
            for _, equipment in pairs(row) do
                equipment.neighbours = nil
            end
        end
    end
end