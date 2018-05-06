return function()

    -- At this point I had a few savefiles that would be broken due to some
    -- changes I made during development. I'm here to take care of those errors!
    for _, tracker in pairs(global.trackers) do
        -- If the shadow is an entity, we delete it.
        if tracker.shadow and tracker.shadow.valid then
            tracker.shadow = nil
        end

        -- If the trackers owner has a GUI visible, delete it
        local gui = tracker.entity.gui.left['ic_stats']
        if gui then
            gui.destroy()
        end
    end
end