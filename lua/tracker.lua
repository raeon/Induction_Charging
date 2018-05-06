
-- luacheck: globals classifyInstance
local Grid = require('grid')
local Gui = require('gui')
local Shadow = require('shadow')

local t = {}

function t:New(entity)
    self.entity = entity
    self.grid = Grid(self, nil) -- throughput
    self.shadow = Shadow(self) -- efficiency
    self.gui = Gui(self)

    -- Stat for GUI
    self.lastThroughput = 0

    -- Technology tiers (not related to coils!)
    self.throughput = 0
    self.efficiency = 0

    -- Actually set technology tiers
    self:UpdateTechnology()
    self:Recalculate()
end

-- Set metatables
function t:Renew()
    if self.grid then
        classifyInstance(self.grid, Grid)
        self.grid:Renew()
    end

    if self.gui then
        classifyInstance(self.gui, Gui)
        self.gui:Renew()
    end

    if self.shadow then
        classifyInstance(self.shadow, Shadow)
        self.shadow:Renew()
    end
end

-- Correct datamodel
function t:Fix()

    if not self:Valid() then
        return false
    end

    -- Fix own variables
    self.lastThroughput = self.lastThroughput or 0
    self.throughput = self.throughput or 0
    self.efficiency = self.efficiency or 0

    -- Update base throughput and efficiency
    self:UpdateTechnology()

    -- If we already have a Grid instance we will set its metatable.
    -- Otherwise, we create a new instance.
    if self.grid then
        self.grid:Fix()
    else
        self.grid = Grid(self, nil)
    end

    if not self.shadow then
        self.shadow = Shadow(self)
    end
    self.shadow:Fix()

    -- Fix gui instance; it is always present.
    if not self.gui then
        self.gui = Gui(self)
    end
    self.gui:Fix()

    return true
end

function t:Tick(tick)
    if self.shadow:Exists() then
        local buffer = (tick + 1) * (self.grid.throughputPerTick / self.efficiency)
        self.shadow.entity.electric_buffer_size = buffer
    end
end

function t:Update()
    --wtf('update tick ' .. (game.tick % global.tickrate) .. ', stored = ' .. self.shadow.entity.energy)

    -- Amount of energy our shadow received
    local received = self.shadow:Receive()
    -- CSV:Value('tick', game.tick)
    -- CSV:Value('player', self.entity.name)

    -- Scale the received energy back to watts
    self.lastThroughput = (received / global.tickrate) * 60

    -- Move shadow entity to correct position if it exists
    self.shadow:Move()

    -- Distribute the received energy to the grid,
    -- which in turn tells us how much more we need to request.
    -- Returns zero if grid is invalid.
    local requested = self.grid:Distribute(received)
    self.shadow:Request(requested, self:ShouldHide())

    -- Update the GUI
    -- local a = self.grid:Valid()
    -- local b = table.any(self.grid.coils) -- TODO: Continue figuring out why GUI remains visible
    -- wtf('a', a, 'b', b, 'c', table.count(self.grid.coils))
    self.gui:Visible(self.grid:Valid() and table.any(self.grid.coils))
    self.gui:Update()

    -- CSV:Next()
end

function t:UpdateGrid()

    -- Stop if we are invalid

    -- If we're not a player, try .grid or fail
    if not self.entity.is_player() then
        -- Check if .grid is set
        local grid = self.entity.grid
        if grid then
            self.grid:Set(grid)
        end
        return
    end

    -- Try to get player armor inventory
    local inv = self.entity.get_inventory(defines.inventory.player_armor)
    if inv == nil then
        self.grid:Set(nil)
        self.gui:Hide(true)
        return
    end

    -- Get the grid for said armor
    local armor = inv[1]
    if armor and armor.valid and armor.valid_for_read and armor.grid then
        self.grid:Set(armor.grid)
    else
        self.grid:Set(nil)
        self.gui:Hide(true)
    end
end

function t:UpdateTechnology()
    local tier = self:GetTier()
    self.efficiency = config.tiers[tier].efficiency
    self.throughput = config.tiers[tier].throughput
end

function t:Recalculate()
    self.grid:UpdateCalculation()
end

function t:GetTier()
    local highest = 0
    local techs = self.entity.force.technologies

    for num, tier in pairs(config.tiers) do
        if num > 0 then
            if techs["induction" .. tostring(num)].researched then
                highest = num
            end
        end
    end
    return highest
end

function t:IsPlayer()
    return self.entity.get_quickbar()
end

function t:ShouldHide()

    -- Entity non-existant? Not relevant then
    if not (self.entity and self.entity.valid) then
        return false
    end

    -- Get our own entity if we're a player,
    -- or choose the driver if we're a vehicle.
    local player = nil
    if self.entity.is_player() then
        player = self.entity
    else
        player = self.entity.get_driver()
    end

    -- Don't necessarily hide if we don't have a player. (e.g.: empty vehicle)
    if player == nil then
        return false
    end

    -- Get the stack of items the player is holding
    local stack = player.cursor_stack

    -- No item stack selected? Nevermind then
    if not stack.valid_for_read then
        return false
    end

    local itemProto = stack.prototype
    local entityProto = itemProto.place_result

    -- Check if there is a place result
    if not entityProto then
        return false
    end

    -- Return if the place result is a power pole or not
    return entityProto.type == 'electric-pole'
end

function t:GetID()
    return self:IsPlayer() and (-self.entity.index - 1) or self.entity.unit_number
end

function t:Valid()
    return self.entity and self.entity.valid and self.grid:Valid()
end

return classify(t)