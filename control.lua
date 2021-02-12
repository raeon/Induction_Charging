--[[
    Induction Charging
    Copyright (C) 2021  Joris Klein Tijssink

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

require('util')
local config = require('config')

--[[
    Mapping from an entity ID to a tracker.

    See the createTracker function for an idea what a tracker contains.
]]
local trackers = {}
local updateRate = 60
local shadowRate = 30

local function debug(...)
    local args = {...}
    for k,v in pairs(args) do
        if type(v) ~= 'string' or v == nil then
            args[k] = stringify(v)
        end
    end
    for k,v in pairs(game.players) do
        v.print(table.concat(args, ', '))
    end
end

local function getID(entity)
    return entity.is_player() and (-entity.index - 1) or entity.unit_number
end

local function getPlayer(event)
    return game.players[event.player_index]
end

local function getOpenedEntity(player)
    if player.opened
    and (player.opened_gui_type == defines.gui_type.equipment
        or player.opened_gui_type == defines.gui_type.entity) then
        return player.opened, false
    end
    return player, true
end

local function getTier(entity)
    local highest = config.tiers[0]
    local techs = entity.force.technologies
    for num, tier in pairs(config.tiers) do
        if num > 0 then
            if techs['induction-technology' .. num].researched then
                highest = tier
            end
        end
    end
    return highest
end

local function getTracker(entity)
    local id = getID(entity)
    return trackers[id]
end

local function deleteTracker(entity)
    local id = getID(entity)
    local tracker = trackers[id]
    if not tracker then return end

    -- Delete the shadow if it exists.
    if tracker.shadow and tracker.shadow.valid then
        tracker.shadow.destroy()
    end

    trackers[id] = nil
end

local function getGrid(entity)
    -- Entities may have an immediate .grid field.
    if not entity.is_player() then
        local grid = entity.grid
        return (grid and grid.valid) and grid or nil
    end

    -- Players can have power armor. Find it.
    local inventory = entity.get_inventory(defines.inventory.character_armor)
    if not (inventory and inventory.valid) then return nil end
    if inventory.index ~= defines.inventory.character_armor then
        -- No armor inventory found.
        return nil
    end

    local stack = inventory[1]

    -- No stack in armor inventory.
    if not (stack and stack.valid_for_read) then return end

    -- Item in armor inventory has no equipment grid.
    if not stack.grid then return end

    -- We found a valid grid!
    return stack.grid
end

local function isGridRelevant(grid)
    if not (grid and grid.valid) then return false end
    local contents = grid.get_contents()
    local count = contents['induction-coil'] or 0
    return count > 0
end

local function setGrid(tracker, grid)
    tracker.grid = grid
end

local function createTracker(entity, grid)
    local id = getID(entity)
    local tracker = {
        id = id,
        entity = entity,
        grid = grid or nil,
        shadow = nil,
        tier = getTier(entity),
        stored = 0,
    }
    trackers[id] = tracker
    if grid then
        setGrid(tracker, grid)
    end
    return tracker
end

local function createShadow(tracker)
    local shadow = tracker.shadow
    if shadow and shadow.valid then return shadow end

    -- Create a new shadow entity.
    shadow = tracker.entity.surface.create_entity({
        name = 'induction-shadow',
        position = tracker.entity.position,
    })
    shadow.destructible = false
    shadow.minable = false
    tracker.shadow = shadow
    return shadow
end

local function updateShadow(tracker)
    local shadow = tracker.shadow
    if shadow and shadow.valid then
        shadow.teleport(tracker.entity.position)
    end
end

local function deleteShadow(tracker)
    local shadow = tracker.shadow
    if shadow and shadow.valid then
        shadow.destroy()
        tracker.shadow = nil
    end
end

local function tickTracker(tracker)
    local shadow = tracker.shadow
    if not (shadow and shadow.valid) then return end

    -- Draw the power from the shadow, apply the efficiency, and store it.
    tracker.stored = tracker.stored + shadow.energy * tracker.tier.efficiency
    shadow.energy = 0
end

local function receiveEnergy(tracker)
    local received = math.floor(tracker.stored)
    tracker.stored = tracker.stored - received
    return received
end

local function requestEnergy(tracker, amount)
    if amount <= 0 then
        deleteShadow(tracker)
        return
    end

    createShadow(tracker)
    tracker.shadow.electric_buffer_size = math.ceil(amount / tracker.tier.efficiency / updateRate)
end

local function updateTracker(tracker)
    if not tracker.entity.valid then
        deleteTracker(tracker.entity)
        return
    end
    local grid = tracker.grid

    -- Grab the energy from the shadow.
    local remaining = receiveEnergy(tracker)
    tracker.stored = 0

    -- Get the technology level for this tracker. We maintain the tier stored
    -- in tracker.state until after we received energy, but before we request
    -- more. This prevents us from getting incorrect readings when a new
    -- technology level is achieved.
    local tier = getTier(tracker.entity)
    tracker.tier = tier

    -- Find all coils in the grid and calculate the amount of space available.
    local request = 0
    local throughput = 0

    for _, coil in pairs(grid.equipment) do
        if coil and coil.valid and coil.name == 'induction-coil' then
            local space = math.ceil(coil.max_energy - coil.energy)

            -- Calculate how much energy can fit in this coil, and insert it.
            local use = math.min(space, remaining)
            coil.energy = coil.energy + use
            remaining = remaining - use

            -- If there is space left, add it to the request.
            request = request + (space - use)
            throughput = throughput + tier.throughput * (updateRate / 60)
        end
    end
    request = math.min(math.max(0, request - remaining), throughput)

    -- Any excess energy is stored, and subtracted from our request.
    tracker.stored = remaining
    requestEnergy(tracker, request)
end

--[[
    Events
]]

local function loadSettings()
    updateRate = settings.global['induction-charging-update-rate'].value
    shadowRate = settings.global['induction-charging-shadow-rate'].value
end

-- Called once for new save files.
script.on_init(function()
    -- Set up our global tables.
    global.trackers = trackers
    loadSettings()
end)

-- Called every time the mod loads, *except* the initial time.
script.on_load(function()
    -- Copy the globals to the locals.
    trackers = global.trackers
    loadSettings()
end)

script.on_configuration_changed(loadSettings)
script.on_event(defines.events.on_runtime_mod_setting_changed, loadSettings)

--[[ Events ]]

script.on_event(defines.events.on_tick, function(event)
    local tick = event.tick
    for id, tracker in pairs(trackers) do
        -- Perform a minor update.
        -- All we do is draw power from the shadow.
        tickTracker(tracker)

        if id % shadowRate == tick % shadowRate then
            updateShadow(tracker)
        end
        
        -- Perform a full update based on the ID of the tracker.
        -- We do this instead of 'on_nth_tick(60, ...)' because this way we
        -- spread out the updates much better.
        if id % updateRate == tick % updateRate then
            updateTracker(tracker)
        end

    end
end)

-- Player equips/unequips armor
script.on_event(defines.events.on_player_armor_inventory_changed, function(event)
    local player = getPlayer(event)
    local grid = getGrid(player)

    -- Delete any trackers if this grid is irrelevant.
    if not isGridRelevant(grid) then
        deleteTracker(player)
        return
    end

    -- Otherwise, get or create the tracker and update it.
    local tracker = getTracker(player) or createTracker(player)
    setGrid(tracker, grid)
end)

-- Player adds equipment to equipment grid
script.on_event(defines.events.on_player_placed_equipment, function(event)
    local entity = getOpenedEntity(getPlayer(event))
    local tracker = getTracker(entity) or createTracker(entity)

    setGrid(tracker, event.grid)
end)

-- Player removes equipment from equipment grid
script.on_event(defines.events.on_player_removed_equipment, function(event)
    local entity = getOpenedEntity(getPlayer(event))
    local tracker = getTracker(entity)
    if not tracker then return end
    
    if not isGridRelevant(tracker.grid) then
        deleteTracker(entity)
    end
end)

-- Player joins
script.on_event(defines.events.on_player_joined_game, function(event)
    local player = getPlayer(event)
    local grid = getGrid(player)
    if isGridRelevant(grid) then
        createTracker(player, grid)
    end
end)

-- Player leaves
script.on_event(defines.events.on_player_left_game, function(event)
    deleteTracker(getPlayer(event))
end)

-- Player dies
script.on_event(defines.events.on_player_died, function(event)
    local player = getPlayer(event)
    local tracker = getTracker(player)
    if tracker then
        deleteTracker(player)
    end
end)

-- Research finishes
-- -- Do nothing. updateTracker() takes care of this for us.
-- script.on_event(defines.events.on_research_finished, function(event)
-- end)

-- Player changes Force
-- -- Do nothing. updateTracker() takes care of this for us.
-- script.on_event(defines.events.on_player_changed_force, function(event)
-- end)

-- Player changes Surface
script.on_event(defines.events.on_player_changed_surface, function(event)
    local tracker = getTracker(getPlayer(event))
    if not tracker then return end
    local shadow = tracker.shadow

    if shadow and shadow.valid then

        -- Store the current state exactly.
        local energy = shadow.energy
        local buffer = shadow.electric_buffer_size

        -- Move between surfaces.
        deleteShadow(tracker)
        createShadow(tracker)

        -- Restore the state.
        shadow = tracker.shadow
        shadow.energy = energy
        shadow.electric_buffer_size = buffer
    end
end)

-- Player places Entity
script.on_event(defines.events.on_built_entity, function(event)
    -- Only track if it has an equipment grid
    local entity = event.created_entity
    local grid = getGrid(entity)
    if isGridRelevant(grid) then
        createTracker(entity, grid)
    end
end)

-- Robot places Entity
script.on_event(defines.events.on_robot_built_entity, function(event)
    -- -- Only track if it has an equipment grid.
    local entity = event.created_entity
    local grid = getGrid(entity)
    if isGridRelevant(grid) then
        createTracker(entity, grid)
    end
end)

-- An entity dies
script.on_event(defines.events.on_entity_died, function(event)
    deleteTracker(event.entity)
end)

-- Player destroys Entity
script.on_event(defines.events.on_player_mined_entity, function(event)
    deleteTracker(event.entity)
end)

-- Robot destroys Entity
script.on_event(defines.events.on_robot_mined_entity, function(event)
    deleteTracker(event.entity)
end)

-- An entity is cloned
script.on_event(defines.events.on_entity_cloned, function(event)
    -- If the source entity is a shadow entity, destroy the destination.
    -- We don't want orpahed shadow entities to spawn.
    if event.source.name == 'induction-shadow' then
        event.destination.destroy()
        return
    end

    -- Check if this entity is tracked. If it is, we want to also track the
    -- destination entity.
    local tracker = getTracker(event.source)
    if not tracker then return end

    -- Create a new tracker for the destination entity.
    createTracker(event.destination, getGrid(event.destination))
end)

-- A mod destroys an entity
script.on_event(defines.events.script_raised_destroy, function(event)
    deleteTracker(event.entity)
end)

-- A mod creates an entity
script.on_event(defines.events.script_raised_built, function(event)
    local entity = event.entity
    local grid = getGrid(entity)
    if isGridRelevant(grid) then
        createTracker(entity, grid)
    end
end)
