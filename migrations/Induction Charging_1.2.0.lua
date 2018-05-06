-- Unlock new technologies if old ones were researched
for _, force in pairs(game.forces) do

    local progress = force.get_saved_technology_progress('induction2')
    log('progress ' .. tostring(progress))
    log('researched ' .. tostring(force.technologies['induction2'].researched))

    -- Unlock induction1 if they have finished the old research
    -- or have partial progress towards unlocking it
    if force.technologies['induction2'].researched
    or (progress and progress > 0) then
        force.technologies['induction1'].researched = true
        force.recipes['induction-coil'].enabled = true
    end
end

-- Delete all shadows
for _, surface in pairs(game.surfaces) do
    for _, ent in pairs(surface.find_entities_filtered({ name = 'induction-shadow' })) do
        ent.destroy()
    end
end