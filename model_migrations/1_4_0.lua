return function()
    log('Adding wantVisible field to GUI instances')
    for _, tracker in pairs(global.trackers) do
        tracker.gui.canBeVisible = tracker.gui.shouldBeVisible -- renamed variable
        tracker.gui.wantVisible = true -- by default, GUI is wanted visible
    end
end