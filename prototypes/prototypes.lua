data:extend({

    -- Fuel category
    -- {
    --     type = "fuel-category",
    --     name = "induction-energy",
    -- },

    -- Item
    {   -- Coil
        type = "item",
        name = "induction-coil",
        icon = "__Induction Charging__/graphics/coil.png",
        icon_size = 32,
        placed_as_equipment_result = "induction-coil",
        flags = {"goes-to-main-inventory"},
        subgroup = "equipment",
        order = "f[induction-coil]",
        stack_size = 40,
    },
    -- {   -- Energy (Fuel item)
    --     type = "item",
    --     name = "induction-energy",
    --     icon = "__Induction Charging__/graphics/energy.png",
    --     flags = {},
    --     fuel_category = "induction-energy",
    --     fuel_value = "10MJ",
    --     fuel_acceleration_multiplier = 1.0,
    --     fuel_top_speed_multiplier = 1.0,
    --     subgroup = "raw-material",
    --     order = "z[induction-energy]",
    --     stack_size = 200, -- 200 * 10MJ = 2000MJ = 2GJ
    -- },

    -- Equipment
    {
        type = "generator-equipment",
        name = "induction-coil",
        sprite = {
            filename = "__Induction Charging__/graphics/coil.png",
            width = 32,
            height = 32,
            priority = "medium",
        },
        shape = {
            width = 1,
            height = 1,
            type = "full",
        },
        energy_source = { -- NOT IMPORTANT: Scroll down to the color prototype generation for the relevant parts!
            type = "electric",
            usage_priority = "terciary",
        },
        power = "0kW",
        categories = {"armor"}, -- overridden in data-final-fixes!
    },

    -- Recipe
    {
        type = "recipe",
        name = "induction-coil",
        enabled = "false",
        energy_required = 2,
        ingredients = {
            {"advanced-circuit", 1},
            {"copper-cable", 5},
        },
        results = {
            { type="item", name="induction-coil", amount=1 }
        },
        categories = {"armor"},
    },

    -- Entity
    {
        type = "electric-energy-interface",
        name = "induction-shadow",
        icon = "__Induction Charging__/graphics/coil.png",
        icon_size = 32,
        flags = {"not-blueprintable", "not-deconstructable", "not-on-map", "placeable-off-grid"},
        max_health = 1,
        selectable = false,
        destructible = false,
        collision_box = {
            {0, 0},
            {0, 0},
        },
        collision_mask = {},
        energy_source = {
            type = "electric",
            buffer_capacity = "0J", -- set at runtime
            usage_priority = "primary-input",
            input_flow_limit = "0W", -- set at runtime
            output_flow_limit = "0W",
            render_no_power_icon = false,
            render_no_network_icon = false,
        },
        energy_production = "0W",
        energy_usage = "0W",
    },

    -- GUI toggle hotkey
    {
        type = "custom-input",
        name = "induction-charging-gui-toggle",
        key_sequence = "I",
        consuming = "script-only",
    }

})

-- Load tiers and colors
require('styles')
local config = require('../config/config')

-- Add technology for every tier
local list = {}
for num, tier in pairs(config.tiers) do
    if num > 0 then

        -- Technology template
        local tech = {
            type = "technology",
            name = "induction" .. tostring(num),
            icon = "__Induction Charging__/graphics/coil.png",
            icon_size = 32,
            unit = {
                count = tier.cost_multiplier,
                time = 30,
                ingredients = tier.cost,
            },
            prerequisites = tier.prerequisites,
            effects = tier.effects,
        }

        -- Add prerequisite for previous technology tier if applicable
        if num > 1 then
            table.insert(tech.prerequisites, "induction" .. tostring(num - 1))
        end

        -- Add effects for throughput and efficiency
        table.insert(tech.effects, {
            type = "nothing",
            effect_description = {"effect-description.induction" .. tostring(num) .. "-throughput"},
        })
        table.insert(tech.effects, {
            type = "nothing",
            effect_description = {"effect-description.induction" .. tostring(num) .. "-efficiency"},
        })

        -- Create the technology!
        table.insert(list, tech)

    end
end

-- Add item for every color
for i = 0, config.colors.count - 1, 1 do
    local j = tostring(i)

    -- Equipment template
    local equip = {
        type = "generator-equipment",
        name = "induction-coil-" .. j,
        take_result = "induction-coil",
        sprite = {
            filename = "__Induction Charging__/graphics/color" .. j .. ".png",
            width = 32,
            height = 32,
            priority = "medium",
        },
        shape = {
            width = 1,
            height = 1,
            type = "full",
        },
        energy_source = {
            type = "electric",
            usage_priority = "secondary-output",
        },
        -- burner = {
        --     fuel_category = "induction-energy",
        --     fuel_inventory_size = 0,
        --     effectivity = 1,
        --     emissions = 0,
        -- },
        power = "0W",
        categories = {"armor"}, -- overridden in data-final-fixes!
    }

    -- Create the equipment!
    table.insert(list, equip)
end

data:extend(list)
