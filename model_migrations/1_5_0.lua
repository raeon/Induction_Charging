return function()
    log('Updating all trackers')
    for _, tracker in pairs(global.trackers) do
        tracker:Fix()
        tracker.grid:Update()
    end
end