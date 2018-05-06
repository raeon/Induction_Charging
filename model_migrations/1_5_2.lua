return function()
    log('Deleting totalCapacity and totalEnergy variables from trackers, and updating grids')
    for _, tracker in pairs(global.trackers) do
        tracker.totalCapacity = nil
        tracker.totalEnergy = nil
        tracker.grid:Update()
    end
end