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

--[[
    In this file all prototypes created by Induction Charging are specified.
]]
data:extend({

    -- Item
    {
        type = 'item',
        name = 'induction-coil',
        icon = '__Induction Charging__/graphics/coil.png',
        icon_size = 64, icon_mipmaps = 4,
        placed_as_equipment_result = 'induction-coil',
        subgroup = 'equipment',
        order = 'f[induction-coil]',
        stack_size = 40,
    },

    -- Equipment
    {
        type = 'battery-equipment',
        name = 'induction-coil',
        sprite = {
            filename = '__Induction Charging__/graphics/coil.png',
            width = 64,
            height = 64,
            mipmap_count = 4,
            priority = 'medium',
        },
        shape = {
            width = 1,
            height = 1,
            type = 'full',
        },
        energy_source = {
            type = 'electric',
            usage_priority = 'primary-output',
            buffer_capacity = '500kJ',
            input_flow_limit = '0W',
        },
        categories = {'armor'}, -- overridden in data-final-fixes!
    },

    -- Recipe
    {
        type = 'recipe',
        name = 'induction-coil',
        enabled = 'false',
        energy_required = 2,
        ingredients = {
            {'battery', 1},
            {'advanced-circuit', 1},
            {'copper-cable', 5},
        },
        results = {
            {
                type = 'item',
                name = 'induction-coil',
                amount = 1,
            },
        },
        categories = {'armor'},
    },

    -- Entity
    {
        type = 'electric-energy-interface',
        name = 'induction-shadow',
        icon = '__Induction Charging__/graphics/coil.png',
        icon_size = 64, icon_mipmaps = 4,
        flags = {
            'hidden',
            'hide-alt-info',
            'not-selectable-in-game',
            'not-upgradable',
            'not-in-kill-statistics',
            'not-blueprintable',
            'not-deconstructable',
            'not-on-map',
            'placeable-off-grid'
        },
        max_health = 1,
        selectable = false,
        destructible = false,
        enable_gui = false,
        gui_mode = 'none',
        allow_copy_paste = false,
        alert_when_damaged = false,
        collision_box = {
            {0, 0},
            {0, 0},
        },
        collision_mask = {},
        energy_source = {
            type = 'electric',
            buffer_capacity = '1000J',
            usage_priority = 'secondary-input',
            input_flow_limit = '100MW',
            output_flow_limit = '0W',
            render_no_power_icon = false,
            render_no_network_icon = false,
        },
        energy_production = '0W',
        energy_usage = '0W',
    },
})

-- Add all tiers from the config.
require('util')
local config = require('config')
local list = {}

for i, tier in pairs(config.tiers) do
    if i > 0 then

        -- Set up the technology based on the tier settings.
        local technology = {
            type = 'technology',
            name = 'induction-technology' .. i,
            icon = '__Induction Charging__/graphics/coil.png',
            icon_size = 64, icon_mipmaps = 4,
            unit = {
                count = tier.count,
                time = tier.time,
                ingredients = tier.ingredients,
            },
            prerequisites = tier.prerequisites,
            effects = tier.effects
        }

        -- Add prerequisite to previous technology.
        if i > 1 then
            table.insert(technology.prerequisites, 'induction-technology' .. (i-1))
        end

        -- Add effects for throughput and efficiency
        table.insert(technology.effects, {
            type = 'nothing',
            effect_description = {'effect-description.induction-throughput' .. i},
        })
        table.insert(technology.effects, {
            type = 'nothing',
            effect_description = {'effect-description.induction-efficiency' .. i},
        })
        table.insert(list, technology)
    end
end

data:extend(list)