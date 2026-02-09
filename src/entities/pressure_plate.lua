local Colors = require("src.lib.colors")

local PressurePlate = {}
PressurePlate.__index = PressurePlate

function PressurePlate.new(world, x, y, w, threshold, door)
    local self = setmetatable({}, PressurePlate)
    self.x = x
    self.y = y
    self.w = w
    self.h = 8
    self.threshold = threshold
    self.door = door
    self.activated = false

    -- Sensor to detect objects on the plate
    self.body = love.physics.newBody(world, x + w / 2, y + 4, "static")
    self.shape = love.physics.newRectangleShape(w, 16)
    self.fixture = love.physics.newFixture(self.body, self.shape, 0)
    self.fixture:setSensor(true)
    self.fixture:setUserData({type = "pressure_plate", plate = self})

    self.slime_contacts = {} -- slimes currently on the plate
    self.block_contacts = {} -- blocks currently on the plate

    return self
end

function PressurePlate:addContact(slime)
    self.slime_contacts[slime] = true
end

function PressurePlate:removeContact(slime)
    self.slime_contacts[slime] = nil
end

function PressurePlate:addBlockContact(block)
    self.block_contacts[block] = true
end

function PressurePlate:removeBlockContact(block)
    self.block_contacts[block] = nil
end

function PressurePlate:getTotalMass()
    local total = 0
    for slime, _ in pairs(self.slime_contacts) do
        if slime.alive then
            total = total + slime.mass
        end
    end
    for block, _ in pairs(self.block_contacts) do
        if not block.body:isDestroyed() then
            total = total + block.body:getMass()
        end
    end
    return total
end

function PressurePlate:update(dt)
    local was_activated = self.activated
    local mass = self:getTotalMass()
    self.activated = mass >= self.threshold

    if self.door then
        self.door:setOpen(self.activated)
    end
end

function PressurePlate:draw()
    local depression = self.activated and 3 or 0

    -- Base plate
    if self.activated then
        love.graphics.setColor(Colors.plate_on)
    else
        love.graphics.setColor(Colors.plate)
    end
    love.graphics.rectangle("fill", self.x, self.y + depression, self.w, self.h - depression)

    -- Top highlight
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("fill", self.x + 2, self.y + depression, self.w - 4, 2)

    -- Threshold indicator text
    love.graphics.setColor(Colors.text_dim)
    local font = love.graphics.getFont()
    local label = string.format("%.0f", self.threshold)
    local tw = font:getWidth(label)
    love.graphics.print(label, self.x + self.w / 2 - tw / 2, self.y - 14)
end

function PressurePlate:destroy()
    if not self.body:isDestroyed() then
        self.body:destroy()
    end
end

return PressurePlate
