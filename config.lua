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

local config = {}

local tiers = {
    [0] = {
        throughput = 0,
        efficiency = 0,
    },

    [1] = {
        throughput = 15000,
        efficiency = 0.10,

        count = 100,
        time = 30,
        ingredients = {
            {'automation-science-pack', 1},
            {'logistic-science-pack', 1},
        },

        prerequisites = {'battery-equipment'},
        effects = {
            {
                type = 'unlock-recipe',
                recipe = 'induction-coil',
            },
        },
    },
    [2] = {
        throughput = 30000,
        efficiency = 0.20,

        count = 200,
        time = 30,
        ingredients = {
            {'automation-science-pack', 1},
            {'logistic-science-pack', 1},
            {'chemical-science-pack', 1},
        },

        prerequisites = {'battery-mk2-equipment'},
        effects = {},
    },
    [3] = {
        throughput = 60000,
        efficiency = 0.30,

        count = 300,
        time = 30,
        ingredients = {
            {'automation-science-pack', 1},
            {'logistic-science-pack', 1},
            {'chemical-science-pack', 1},
            {'production-science-pack', 1},
        },

        prerequisites = {},
        effects = {},
    },
    [4] = {
        throughput = 120000,
        efficiency = 0.40,

        count = 1000,
        time = 30,
        ingredients = {
            {'automation-science-pack', 1},
            {'logistic-science-pack', 1},
            {'chemical-science-pack', 1},
            {'production-science-pack', 1},
            {'utility-science-pack', 1},
        },

        prerequisites = {},
        effects = {},
    },
    [5] = {
        throughput = 240000,
        efficiency = 0.50,

        count = 2000,
        time = 30,
        ingredients = {
            {'automation-science-pack', 1},
            {'logistic-science-pack', 1},
            {'chemical-science-pack', 1},
            {'production-science-pack', 1},
            {'utility-science-pack', 1},
            {'space-science-pack', 1},
        },

        prerequisites = {},
        effects = {},
    }
}
for id, tier in pairs(tiers) do
    tier.id = id
end
config.tiers = tiers

return config