-- luacheck: globals config CSV

--[[ Libraries ]]
require('util')
config = require('config/config')
local Migrate = require('model_migrations/_migrate')

--[[ Classes ]]
local Tracker = require('lua/tracker')
CSV = require('csv')()

--[[ Utilities ]]
function wtf(...)
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

local function getID(entity, isPlayer)
    return isPlayer and (-entity.index - 1) or entity.unit_number
end

local function getTracker(entity, isPlayer)
    local id = getID(entity, isPlayer)
    if not global.trackers[id] then
        global.trackers[id] = Tracker(entity)
    end
    return global.trackers[id]
end

local function deleteTracker(entity, isPlayer)
    local id = getID(entity, isPlayer)
    if id == nil then
        return
    end
    local tracker = global.trackers[id]
    if tracker then
        tracker.shadow:Destroy()
    end

    global.trackers[id] = nil
end

local function actuallyDeleteTracker(id, tracker)
    tracker.shadow:Destroy()
    tracker.gui:Hide()
    global.trackers[id] = nil
end

--[[ Initialization ]]
local function UpdateSettings()
    global.tickrate = settings.global['induction-charging-tickrate'].value
    global.guiTickrate = settings.global['induction-charging-gui-tickrate'].value
    global.score.base = settings.global['induction-charging-score-base'].value
    global.score.neighbour = settings.global['induction-charging-score-neighbour'].value
    global.score.neighbourWithoutWhitespace = settings.global['induction-charging-score-neighbour-without-whitespace'].value
    global.score.minimum = global.score.base
    global.score.maximum = global.score.base
        + (global.score.neighbour * 8)
        + (global.score.neighbourWithoutWhitespace * 8)
end

-- Redoes metatables
local function RenewAll()
    for _, tracker in pairs(global.trackers or {}) do
        classifyInstance(tracker, Tracker)
        tracker:Renew()
    end
end

-- Fixes data model
local function FixAll()
    for id, tracker in pairs(global.trackers) do
        if not tracker:Fix() then
            actuallyDeleteTracker(id, tracker)
        end
    end
end

-- Updates calculation
local function RecalcAll()
    for _, tracker in pairs(global.trackers) do
        tracker.grid:UpdateCalculation()
    end
end

-- First run
script.on_init(function()

    -- The configuration hasn't changed, so trigger migrations!
    local version = game.active_mods['Induction Charging']
    Migrate('0.0.0', version)

    -- And fix our settings.
    UpdateSettings()
end)

-- Every run
script.on_load(function()
    RenewAll()
end)

-- Configs changed
script.on_configuration_changed(function(event)

    -- Data model changes are handled by migrations
    local changes = event.mod_changes['Induction Charging']
    if changes and changes.old_version ~= changes.new_version then
        Migrate(changes.old_version, changes.new_version)
    end

    -- Settings have to be handled manually
    UpdateSettings()
    FixAll()
end)

--[[ Events ]]

-- Game updates
script.on_event(defines.events.on_tick, function(event)

    -- Determine if we should perform a full update this tick
    local tick = event.tick % global.tickrate
    local isUpdate = tick == 0

    -- Loop over all trackers
    for id, tracker in pairs(global.trackers) do

        -- We ALWAYS, yes EVERY TICK, increase the shadow capacity by [grid.throughputPerTick].
        if not tracker:Valid() then
            tracker.gui:Visible(false)
            actuallyDeleteTracker(id, tracker)
        else

            -- Perform full update if necessary
            if isUpdate then
                tracker:Update()
            end

            -- Update buffer size
            tracker:Tick(tick)
        end

    end
end)

-- Player equips/unequips armor
script.on_event(defines.events.on_player_armor_inventory_changed, function(event)
    local tracker = getTracker(getPlayer(event), true)
    tracker:UpdateGrid()
end)

-- Player adds equipment to equipment grid
script.on_event(defines.events.on_player_placed_equipment, function(event)
    local player = getPlayer(event)
    local entity, isPlayer = getOpenedEntity(player)
    local tracker = getTracker(entity, isPlayer)

    tracker:UpdateGrid()
end)

-- Player removes equipment from equipment grid
script.on_event(defines.events.on_player_removed_equipment, function(event)
    local player = getPlayer(event)
    local entity, isPlayer = getOpenedEntity(player)
    local tracker = getTracker(entity, isPlayer)

    tracker:UpdateGrid()
end)

-- Player joins
script.on_event(defines.events.on_player_joined_game, function(event)
    local tracker = getTracker(getPlayer(event), true)
    tracker:UpdateGrid()
end)

-- Player leaves
script.on_event(defines.events.on_player_left_game, function(event)
    deleteTracker(getPlayer(event), true)
end)

-- Player dies
script.on_event(defines.events.on_player_died, function(event)
    local tracker = getTracker(getPlayer(event), true)
    tracker:UpdateGrid()
end)

-- Research finishes
script.on_event(defines.events.on_research_finished, function(event)

    local research = event.research
    if table.contains(config.technologies, research.name, nil) then
        -- Recalculate throughput and efficiency for all grids
        for _, player in pairs(game.players) do
            local tracker = getTracker(player, true)
            tracker:UpdateTechnology()
            tracker:Recalculate()
        end
    end

end)

-- Player changes Force
script.on_event(defines.events.on_player_changed_force, function(event)
    local tracker = getTracker(getPlayer(event), true)
    tracker:UpdateTechnology()
    tracker:Recalculate()
end)

-- Player changes Surface
script.on_event(defines.events.on_player_changed_surface, function(event)
    -- Destroy and respawn entity
    local tracker = getTracker(getPlayer(event), true)
    if tracker.shadow:Exists() then
        tracker.shadow:Destroy()
        tracker.shadow:Create()
    end
end)

-- Player places Entity
script.on_event(defines.events.on_built_entity, function(event)
    -- Only track if it has an equipment grid
    if event.created_entity.grid then
        local tracker = getTracker(event.created_entity, false)
        tracker:UpdateGrid()
    end
end)

-- Robot places Entity
script.on_event(defines.events.on_robot_built_entity, function(event)
    -- Only track if it has an equipment grid
    if event.created_entity.grid then
        local tracker = getTracker(event.created_entity, false)
        tracker:UpdateGrid()
    end
end)

-- An entity dies
script.on_event(defines.events.on_entity_died, function(event)
    deleteTracker(event.entity, false)
end)

-- Player destroys Entity
script.on_event(defines.events.on_player_mined_entity, function(event)
    deleteTracker(event.entity, false)
end)

-- Robot destroys Entity
script.on_event(defines.events.on_robot_mined_entity, function(event)
    deleteTracker(event.entity, false)
end)

-- Chat for debugging
-- script.on_event(defines.events.on_console_chat, function(event)
--     CSV:Write('output')
-- end)

-- Player presses GUI hotkey
script.on_event('induction-charging-gui-toggle', function(event)
    local tracker = getTracker(getPlayer(event), true)
    tracker.gui:WantVisible()
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, UpdateSettings)
