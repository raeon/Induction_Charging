
local csv = {}

function csv:New()
    self.columns = {}
    self.lines = {}
    self.line = {}
    self.lineCount = 0
end

function csv:Column(name)
    if not self.columns[name] then
        if self.lineCount > 0 then
            error('Cannot create new columns after creating new line')
        end
        self.columns[name] = name
    end
end

function csv:Value(name, value)
    self:Column(name)
    if self.line[name] then
        error('csv duplicate value: ' .. name)
    end
    self.line[name] = value
end

function csv:Next()
    local line = table.join(self.line, ',', self.columns)
    table.insert(self.lines, line)
    self.line = {}
end

function csv:Write(name)

    -- Build string
    local header = 'sep=,\n' .. table.join(self.columns, ',') .. '\n'
    game.write_file('csv/' .. name .. '.csv', header .. table.join(self.lines, '\n'))
end

-- Make global table immutable
return classify(csv)