
local e = {}

function e:New(grid, eq)
    -- Information about this piece of equipment itself
    self.grid = grid
    self.equipment = eq
    self.isBattery = eq.type == 'battery-equipment'
    self.isCoil = string.startsWith(eq.name, 'induction-coil')

    -- Position on grid map
    local pos = eq.position
    local shape = eq.shape
    self.x1 = pos.x
    self.y1 = pos.y
    self.x2 = pos.x + shape.width - 1
    self.y2 = pos.y + shape.height - 1

    -- Keep track of our neighbouring equpiment
    self.checkedNeighbours = false
    self.neighbours = {}

    -- Calculated values or values for use in calculations
    self.neighboursNotBorderingWhitespace = 0
    self.neighbouringCoilCount = 0
    self.neighbouringWhitespaceCount = 0
    self.multiplier = 1.00
end

function e:Renew()
end

function e:Fix()
    -- Not much to do here
end

function e:CheckNeighbours(map)

    local neighbours = {}

    -- Set our 'bordersWhitespace' to false.
    -- This will be set to true if we encounter any in the
    -- neighbour scanning process.
    self.bordersWhitespace = false
    self.neighbouringCoilCount = 0
    self.neighbouringWhitespaceCount = 0

    -- Populate a list of neighbours using the given map,
    -- whilst at the same time also determining if we are adjacent
    -- to a whitespace tile or not (or bordering the edge of the grid)
    for x = self.x1 - 1, self.x2 + 1, 1 do
        for y = self.y1 - 1, self.y2 + 1, 1 do
            if not (x == self.x1 and y == self.y1) then

                -- Get neighbour
                local neighbour = map[x][y]

                -- Check what this neighbour is
                if neighbour then

                    -- Keep track of the number of coil neighbours we have
                    if neighbour.isCoil then
                        self.neighbouringCoilCount = self.neighbouringCoilCount + 1
                        table.insert(neighbours, neighbour)
                    else
                        self.neighbouringWhitespaceCount = self.neighbouringWhitespaceCount + 1
                    end
                else
                    -- No neighbour? It's whitespace.
                    self.neighbouringWhitespaceCount = self.neighbouringWhitespaceCount + 1
                end

            end
        end
    end

    -- Return newly filled list of neighbours
    return neighbours
end

function e:CheckBorders(neighbours)

    -- Determine how many neighbours do NOT border whitespace
    local count = 0
    for _, neighbour in pairs(neighbours) do
        if neighbour.neighbouringWhitespaceCount == 0 then
            count = count + 1
        end
    end
    self.neighboursNotBorderingWhitespace = count

end

function e:CalculateMultiplier()
    -- Calculate multiplier from current config
    local mult = global.score.base
        + (global.score.neighbour * self.neighbouringCoilCount)
        + (global.score.neighbourWithoutWhitespace * self.neighboursNotBorderingWhitespace)

    local position = self.equipment.position
    local energy = self.equipment.energy or 0

    -- Remove old item
    self.grid.take({position = position})

    -- Determine color
    local color = config.colors.get(mult, global.score.minimum, global.score.maximum)

    -- Add new item
    self.equipment = self.grid.put({
        name = 'induction-coil-' .. tostring(color),
        position = position,
    })
    self.equipment.energy = energy

    return mult
end

function e:Energy()
    --return self.equipment.energy
    return self.isBattery and self.equipment.energy or 0
end

function e:MaxEnergy()
    --return self.equipment.max_energy
    return self.isBattery and self.equipment.max_energy or 0
end

return classify(e)