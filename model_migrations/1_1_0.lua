return function()
    -- Create global shadows table (did not exist previously)
    global.shadows = {}

    -- Delete all shadow entities
    for _, surface in pairs(game.surfaces) do
        for _, ent in pairs(surface.find_entities_filtered({ type = 'induction-shadow' })) do
            ent.destroy()
        end
    end
end