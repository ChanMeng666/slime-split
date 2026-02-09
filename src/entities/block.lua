local Colors = require("src.lib.colors")

local Block = {}
Block.__index = Block

function Block.new(world, x, y, w, h)
    local self = setmetatable({}, Block)
    self.w = w
    self.h = h

    self.body = love.physics.newBody(world, x + w / 2, y + h / 2, "dynamic")
    self.body:setFixedRotation(true)
    self.body:setLinearDamping(1.5)

    self.shape = love.physics.newRectangleShape(w, h)
    self.fixture = love.physics.newFixture(self.body, self.shape, 5)
    self.fixture:setFriction(0.8)
    self.fixture:setRestitution(0.05)
    self.fixture:setUserData({type = "block", block = self})

    -- Heavier than slimes so only big slimes can push
    self.body:setMass(8)

    return self
end

function Block:draw()
    local x, y = self.body:getPosition()
    local hw, hh = self.w / 2, self.h / 2

    -- Main body
    love.graphics.setColor(Colors.block)
    love.graphics.rectangle("fill", x - hw, y - hh, self.w, self.h)

    -- Dark edges
    love.graphics.setColor(Colors.block_dark)
    love.graphics.rectangle("fill", x - hw, y + hh - 4, self.w, 4) -- bottom
    love.graphics.rectangle("fill", x + hw - 3, y - hh, 3, self.h) -- right

    -- Light top edge
    love.graphics.setColor(Colors.block[1] + 0.1, Colors.block[2] + 0.1, Colors.block[3] + 0.1, 1)
    love.graphics.rectangle("fill", x - hw, y - hh, self.w, 3)

    -- Cross pattern (crate look)
    love.graphics.setColor(Colors.block_dark[1], Colors.block_dark[2], Colors.block_dark[3], 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.line(x - hw, y - hh, x + hw, y + hh)
    love.graphics.line(x + hw, y - hh, x - hw, y + hh)
end

function Block:destroy()
    if not self.body:isDestroyed() then
        self.body:destroy()
    end
end

return Block
