local Colors = require("src.lib.colors")
local Utils = require("src.lib.utils")

local Door = {}
Door.__index = Door

function Door.new(world, x, y, w, h)
    local self = setmetatable({}, Door)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.open = false
    self.open_amount = 0 -- 0=closed, 1=fully open

    -- Kinematic body for the door panel
    self.body = love.physics.newBody(world, x + w / 2, y + h / 2, "kinematic")
    self.shape = love.physics.newRectangleShape(w, h)
    self.fixture = love.physics.newFixture(self.body, self.shape, 0)
    self.fixture:setFriction(0.3)
    self.fixture:setUserData({type = "door"})

    self.closed_y = y + h / 2
    self.open_y = y + h / 2 - h -- slides up

    return self
end

function Door:setOpen(open)
    self.open = open
end

function Door:update(dt)
    local target = self.open and 1 or 0
    self.open_amount = Utils.lerp(self.open_amount, target, 4 * dt)

    -- Clamp near target
    if math.abs(self.open_amount - target) < 0.01 then
        self.open_amount = target
    end

    local cy = Utils.lerp(self.closed_y, self.open_y, self.open_amount)
    local cur_x, _ = self.body:getPosition()
    self.body:setPosition(cur_x, cy)
end

function Door:draw()
    local bx, by = self.body:getPosition()
    local hw, hh = self.w / 2, self.h / 2

    -- Door frame (always visible)
    love.graphics.setColor(Colors.door_frame)
    love.graphics.rectangle("line", self.x - 2, self.y - 2, self.w + 4, self.h + 4)

    -- Door panel
    love.graphics.setColor(Colors.door)
    love.graphics.rectangle("fill", bx - hw, by - hh, self.w, self.h)

    -- Horizontal bars
    love.graphics.setColor(Colors.door_frame)
    local bar_count = math.max(2, math.floor(self.h / 16))
    for i = 1, bar_count do
        local ly = by - hh + (self.h / (bar_count + 1)) * i
        love.graphics.line(bx - hw + 2, ly, bx + hw - 2, ly)
    end
end

function Door:destroy()
    if not self.body:isDestroyed() then
        self.body:destroy()
    end
end

return Door
