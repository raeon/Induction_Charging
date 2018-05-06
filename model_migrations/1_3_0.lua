return function()
    -- Fix global tracker keys to go from player_index to -player_index!
    -- We now use positive ints for regular entities and negative ints for players.
    for playerIndex, tracker in pairs(global.trackers) do
        if playerIndex >= 0 then
            log('Migrating tracker from ' .. tostring(playerIndex) .. ' to ' .. tostring(-playerIndex - 1))
            global.trackers[playerIndex] = nil
            global.trackers[-playerIndex - 1] = tracker

            -- Delete unused variables
            tracker.grid.width = nil
            tracker.grid.height = nil
        end
    end
end