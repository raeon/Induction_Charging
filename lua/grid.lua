--luacheck: globals remapN mapN classifyInstance classify
local Equipment = require('equipment')

local g = {}

function g:New(tracker, grid)
    self.tracker = tracker
    self.grid = grid

    --self.batteries = nil
    self.coils = nil
    self.map = nil

    self.throughput = 0
    self.throughputPerTick = 0

    self.energy = 0
    self.capacity = 0
    self.requested = 0

    self:Update()
end

function g:Renew()
    if self.map then
        -- Set map metatable(s)
        remapN(self.map, 2)

        -- Fix all items
        for _, column in pairs(self.map) do
            for _, item in pairs(column) do

                -- Check if it has already been fixed.
                -- This happens when there are pieces of equipment
                -- larger than 1x1 and therefore are stored in the map
                -- multiple times!
                if not item.Renew then
                    classifyInstance(item, Equipment)
                    item:Renew()
                end
            end
        end
    end
end

function g:Fix()
    --self.batteries = self.batteries or {}
    self.coils = self.coils or {}
    self.map = self.map or mapN(2)

    self.throughput = self.throughput or 0
    self.throughputPerTick = self.throughput / 60

    self.energy = self.energy or 0
    self.capacity = self.capacity or 0
    self.requested = self.requested or 0

    self:Update()
end

function g:Set(grid)
    self.grid = grid
    self.coils = {}
    self.map = nil

    if grid then
        self:Update()
    end
end

function g:Distribute(received)

    -- If we're not valid, return zero
    if not self:Valid() then
        return 0
    end

    -- Check how much power all our batteries have and put it in self.energy
    self:UpdateEnergy()

    -- Calculate how much energy we've received and how much
    -- we have in total. We also account for efficiency here.
    local totalStored = math.ceil(self.energy + received)

    -- Fill as much as possible within our throughput (joules)
    -- Round up from how much space there is available and how much
    -- we can provide per [tickrate] ticks
    self.requested = math.ceil(math.min(
        math.max(0, self.capacity - totalStored), -- space available
        self.throughput * (global.tickrate / 60) -- joules we provide in [tickrate] ticks
    ))

    -- Do nothing if we received nothing
    if received <= 0 then
        return self.requested
    end

    -- Distribute power evenly
    local fraction = math.min(1, totalStored / self.capacity) -- cap at 1
    -- for _, battery in pairs(self.batteries) do
    --     -- Round the 'gainz' down in order to prevent "creating" energy by rounding errors
    --     battery.equipment.energy = math.floor(fraction * battery.equipment.max_energy)
    -- end
    for _, battery in pairs(self.batteries) do
        -- Round the 'gainz' down in order to prevent "creating" energy by rounding errors
        battery.equipment.energy = fraction * battery:MaxEnergy()
    end

    -- Request whatever amount we need for the next [global.tickrate] ticks.
    return self.requested
end

function g:UpdateEnergy()

    -- Determine energy stored in batteries
    local energy = 0
    for _, battery in pairs(self.batteries) do
        energy = energy + battery:Energy()
    end
    self.energy = energy

    return energy
end

function g:Update()
    self:UpdateEquipment()
    self:UpdateCalculation()
end

function g:UpdateEquipment()
    -- Reset internal equipment list/map
    self.batteries = {}
    self.coils = {}
    self.map = mapN(2)
    self.capacity = 0

    -- Check if we're valid
    if not self:Valid() then
        return
    end

    -- Iterate over new equipment
    for _, eq in pairs(self.grid.equipment) do

        -- Itemize it
        local item = Equipment(self.grid, eq)

        -- Store battery if applicable
        if item.isBattery then
            table.insert(self.batteries, item)
            self.capacity = self.capacity + item:MaxEnergy()
        end

        -- Store coil if applicable
        if item.isCoil then
            table.insert(self.coils, item)
        end

        -- Store in map
        for x = item.x1, item.x2, 1 do
            for y = item.y1, item.y2, 1 do
                self.map[x][y] = item
            end
        end
    end

    -- Keep list of coil to neighbours temporarily
    local coilNeighbours = {}

    -- Update the neighbour counts
    for _, coil in pairs(self.coils) do
        coilNeighbours[coil] = coil:CheckNeighbours(self.map)
    end

    -- Determine amount of neighbours with whitespace.
    -- We do this after CheckNeighbours. The alternative was to
    -- do it recursively in CheckNeighbours but I chose not to
    -- do so due to infinite looping concerns.
    for _, coil in pairs(self.coils) do
        coil:CheckBorders(coilNeighbours[coil])
    end

end

function g:UpdateCalculation()
    if not self:Valid() then
        return
    end

    -- Update our efficiency and throughput
    local throughput = 0
    local baseThroughput = self.tracker.throughput

    -- Add throughput per coil based on multiplier
    for _, coil in pairs(self.coils) do
        throughput = throughput + math.floor(baseThroughput * coil:CalculateMultiplier())
    end

    self.throughput = throughput
    self.throughputPerTick = throughput / 60
end

function g:Valid()
    return self.grid and self.grid.valid
end

return classify(g)