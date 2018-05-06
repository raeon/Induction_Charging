return function(config, makeImmutable)
    config.tiers = {}
    config.tiers[0] = {
        throughput = 0,
        efficiency = 0,
    }
    config.tiers[1] = {
        throughput = 15000,
        efficiency = 0.10,
        cost_multiplier = 100,
        cost = {
            {"science-pack-1", 1},
            {"science-pack-2", 1},
        },
        prerequisites = {"battery-equipment"},
        effects = {
            {
                type = "unlock-recipe",
                recipe = "induction-coil",
            },
        },
    }
    config.tiers[2] = {
        throughput = 30000,
        efficiency = 0.20,
        cost_multiplier = 200,
        cost = {
            {"science-pack-1", 1},
            {"science-pack-2", 1},
            {"science-pack-3", 1},
        },
        prerequisites = {"battery-mk2-equipment"},
        effects = {},
    }
    config.tiers[3] = {
        throughput = 60000,
        efficiency = 0.30,
        cost_multiplier = 300,
        cost = {
            {"science-pack-1", 1},
            {"science-pack-2", 1},
            {"science-pack-3", 1},
            {"production-science-pack", 1},
        },
        prerequisites = {},
        effects = {},
    }
    config.tiers[4] = {
        throughput = 120000,
        efficiency = 0.40,
        cost_multiplier = 1000,
        cost = {
            {"science-pack-1", 1},
            {"science-pack-2", 1},
            {"science-pack-3", 1},
            {"production-science-pack", 1},
            {"high-tech-science-pack", 1},
        },
        prerequisites = {},
        effects = {},
    }
    config.tiers[5] = {
        throughput = 240000,
        efficiency = 0.50,
        cost_multiplier = 2000,
        cost = {
            {"science-pack-1", 1},
            {"science-pack-2", 1},
            {"science-pack-3", 1},
            {"production-science-pack", 1},
            {"high-tech-science-pack", 1},
            {"space-science-pack", 1},
        },
        prerequisites = {},
        effects = {},
    }

    -- Add tiers to table by string whilst also making them immutable
    config.technologies = {}
    for num, tier in pairs(config.tiers) do
        local new = makeImmutable(tier)
        config.tiers[num] = new
        config.technologies['induction' .. tostring(num)] = new
    end
end