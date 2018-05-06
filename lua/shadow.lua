
local s = {}

function s:New(tracker)
    self.tracker = tracker
    self.entity = nil

    self.requested = 0
end

function s:Renew()
end

function s:Fix()

    -- If requested was not set, we'd set it to 0.
    -- However, if we do that, then it would account
    -- all received energy as excess. We do this to
    -- prevent that from happening:
    if (not self.requested) and self.entity then
        self.entity.power_usage = 0
        self.entity.energy = 0
    end

    -- Init missing fields
    self.requested = self.requested or 0
end

function s:Move()
    -- Do nothing if we didn't exist in the first place
    if not (self.entity and self.entity.valid) then
        return
    end

    -- Teleport lazily
    self.entity.teleport(self.tracker.entity.position)
end

function s:Receive()
    if not self:Exists() then
        return 0
    end

    -- Check how much we have actually received
    local received = (self.entity and self.entity.energy * self.tracker.efficiency) or 0
    --wtf('received', received)
    -- CSV:Value('requested', self.requested)
    -- CSV:Value('rawReceived', received)

    -- Return the amount we determined we've received
    --CSV:Value('received', received)
    return received
end

function s:Request(energy, shouldHide)
    energy = math.max(0, energy)

    -- Destroy entity if zero or if user has selected a power pole
    if energy <= 0 or shouldHide then
        self.requested = 0
        self:Destroy()
        return
    end

    -- Create if not already created
    self:Create()

    -- Determine how much excess we use
    --CSV:Value('rawRequested', energy)

    -- Request what we wanted to request minus the portion
    -- of our excess energy storage we will consume next Receive
    self.requested = energy
    --CSV:Value('requested', energy)

    -- Take into account energy loss from inefficiency
    local eff = self.tracker.efficiency

    -- No dividing by zero pls k thx
    if eff > 0 then
        energy = energy / eff
    else
        energy = 0
    end

    -- Determine how much energy that is per tick
    local perTick = math.ceil(energy / global.tickrate)

    -- Set corresponding fields in the shadow entity
    self.entity.energy = 0
    --self.entity.electric_buffer_size = energy * 1000
    --wtf('energy', energy, 'perTick', perTick)
    --self.entity.power_usage = perTick
end

function s:Create()
    self.entity = self.entity or self.tracker.entity.surface.create_entity({
        name = "induction-shadow",
        force = self.tracker.entity.force,
        position = self.tracker.entity.position,
    })
    self.entity.destructible = false
end

function s:Destroy()
    if self:Exists() then
        self.entity.destroy()
        self.entity = nil
    end
end

function s:Exists()
    return self.entity ~= nil and self.entity.valid
end

return classify(s)