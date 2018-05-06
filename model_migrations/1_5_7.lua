local mod_gui = require('mod-gui')

return function()
    log('Deleting hasReceived and excess from shadows, adding throughputPerTick, and removing the old GUI.')
    for _, tracker in pairs(global.trackers) do
        tracker.shadow.hasReceived = nil
        tracker.shadow.excess = nil
        tracker.grid.throughputPerTick = tracker.grid.throughput / 60

        if tracker.entity.valid
        and tracker.entity.gui
        and tracker.entity.gui.top then
            local oldGUI = tracker.entity.gui.top['ic_stats']
            if oldGUI then
                oldGUI.destroy()
            end
        end
    end
end