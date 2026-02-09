local Physics = {}
Physics.__index = Physics

-- Collision categories
Physics.CAT_WALL   = 1
Physics.CAT_SLIME  = 2
Physics.CAT_BLOCK  = 3
Physics.CAT_SENSOR = 4

function Physics.new()
    local self = setmetatable({}, Physics)
    self.world = love.physics.newWorld(0, 600, true) -- gravity 600 px/s²
    self.contacts = {} -- for pressure plate tracking
    self.beginCallbacks = {}
    self.endCallbacks = {}

    self.world:setCallbacks(
        function(a, b, contact) self:beginContact(a, b, contact) end,
        function(a, b, contact) self:endContact(a, b, contact) end,
        nil, nil
    )
    return self
end

function Physics:beginContact(a, b, contact)
    local ud_a = a:getUserData()
    local ud_b = b:getUserData()

    -- Ground detection for slimes
    if ud_a and ud_a.type == "slime_foot" and ud_b and ud_b.type ~= "slime_foot" then
        ud_a.slime.ground_contacts = ud_a.slime.ground_contacts + 1
    end
    if ud_b and ud_b.type == "slime_foot" and ud_a and ud_a.type ~= "slime_foot" then
        ud_b.slime.ground_contacts = ud_b.slime.ground_contacts + 1
    end

    -- Pressure plate detection
    if ud_a and ud_a.type == "pressure_plate" and ud_b and ud_b.type == "slime" then
        ud_a.plate:addContact(ud_b.slime)
    end
    if ud_b and ud_b.type == "pressure_plate" and ud_a and ud_a.type == "slime" then
        ud_b.plate:addContact(ud_a.slime)
    end
    -- Blocks on pressure plates
    if ud_a and ud_a.type == "pressure_plate" and ud_b and ud_b.type == "block" then
        ud_a.plate:addBlockContact(ud_b.block)
    end
    if ud_b and ud_b.type == "pressure_plate" and ud_a and ud_a.type == "block" then
        ud_b.plate:addBlockContact(ud_a.block)
    end

    -- Exit detection
    if ud_a and ud_a.type == "exit" and ud_b and ud_b.type == "slime" then
        ud_a.exit.triggered = true
    end
    if ud_b and ud_b.type == "exit" and ud_a and ud_a.type == "slime" then
        ud_b.exit.triggered = true
    end

    for _, cb in ipairs(self.beginCallbacks) do
        cb(a, b, contact)
    end
end

function Physics:endContact(a, b, contact)
    local ud_a = a:getUserData()
    local ud_b = b:getUserData()

    -- Ground detection
    if ud_a and ud_a.type == "slime_foot" and ud_b and ud_b.type ~= "slime_foot" then
        ud_a.slime.ground_contacts = math.max(0, ud_a.slime.ground_contacts - 1)
    end
    if ud_b and ud_b.type == "slime_foot" and ud_a and ud_a.type ~= "slime_foot" then
        ud_b.slime.ground_contacts = math.max(0, ud_b.slime.ground_contacts - 1)
    end

    -- Pressure plate
    if ud_a and ud_a.type == "pressure_plate" and ud_b and ud_b.type == "slime" then
        ud_a.plate:removeContact(ud_b.slime)
    end
    if ud_b and ud_b.type == "pressure_plate" and ud_a and ud_a.type == "slime" then
        ud_b.plate:removeContact(ud_a.slime)
    end
    if ud_a and ud_a.type == "pressure_plate" and ud_b and ud_b.type == "block" then
        ud_a.plate:removeBlockContact(ud_b.block)
    end
    if ud_b and ud_b.type == "pressure_plate" and ud_a and ud_a.type == "block" then
        ud_b.plate:removeBlockContact(ud_a.block)
    end

    for _, cb in ipairs(self.endCallbacks) do
        cb(a, b, contact)
    end
end

function Physics:update(dt)
    self.world:update(dt)
end

function Physics:destroy()
    self.world:destroy()
end

return Physics
