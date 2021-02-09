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

data:extend({
    {
        type = 'int-setting',
        name = 'induction-charging-update-rate',
        setting_type = 'runtime-global',
        default_value = 60,
        order = 'a'
    },
    {
        type = 'int-setting',
        name = 'induction-charging-shadow-rate',
        setting_type = 'runtime-global',
        default_value = 30,
        order = 'b',
    }
})