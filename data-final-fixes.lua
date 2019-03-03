local config = require('config/config')

-- Fetch all equipment categories
local equipmentCategories = {}
for _, category in pairs(data.raw['equipment-category']) do
    table.insert(equipmentCategories, category.name)
end

-- Update default equipment categories
data.raw['generator-equipment']['induction-coil'].categories = equipmentCategories

-- Update equipment categories for every color
for i = 0, config.colors.count - 1, 1 do
    local j = tostring(i)

    -- Update equipment categories
    data.raw['generator-equipment']['induction-coil-' .. j].categories = equipmentCategories

end
