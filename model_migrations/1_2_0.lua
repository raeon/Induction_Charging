return function()

    -- Delete old global variables
    global.shadows = nil
    global.efficiency = nil
    global.transferRate = nil

    -- Create new tables: One for trackers and one for settings.
    global.trackers = {}
    global.score = {}
end