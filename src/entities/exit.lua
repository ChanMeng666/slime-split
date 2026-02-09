local Colors = require("src.lib.colors")

local Exit = {}
Exit.__index = Exit

function Exit.new(world, x, y, w, h)
    local self = setmetatable({}, Exit)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.triggered = false
    self.time = 0

    -- Sensor body
    self.body = love.physics.newBody(world, x + w / 2, y + h / 2, "static")
    self.shape = love.physics.newRectangleShape(w, h)
    self.fixture = love.physics.newFixture(self.body, self.shape, 0)
    self.fixture:setSensor(true)
    self.fixture:setUserData({type = "exit", exit = self})

    return self
end

function Exit:update(dt)
    self.time = self.time + dt
end

function Exit:draw()
    local cx = self.x + self.w / 2
    local cy = self.y + self.h / 2
    local pulse = 0.5 + 0.5 * math.sin(self.time * 3)

    -- Glow background
    love.graphics.setColor(Colors.exit_glow[1], Colors.exit_glow[2], Colors.exit_glow[3], 0.15 + 0.1 * pulse)
    love.graphics.rectangle("fill", self.x - 4, self.y - 4, self.w + 8, self.h + 8, 4, 4)

    -- Border
    love.graphics.setColor(Colors.exit_gold[1], Colors.exit_gold[2], Colors.exit_gold[3], 0.6 + 0.4 * pulse)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 2, 2)
    love.graphics.setLineWidth(1)

    -- Star / arrow icon
    love.graphics.setColor(Colors.exit_gold)
    local star_size = 6 + pulse * 2
    self:drawStar(cx, cy, star_size, 5)

    -- Label
    love.graphics.setColor(Colors.exit_gold[1], Colors.exit_gold[2], Colors.exit_gold[3], 0.8)
    local font = love.graphics.getFont()
    local label = "EXIT"
    local tw = font:getWidth(label)
    love.graphics.print(label, cx - tw / 2, self.y - 16)
end

function Exit:drawStar(x, y, r, points)
    local verts = {}
    for i = 0, points * 2 - 1 do
        local angle = (i / (points * 2)) * math.pi * 2 - math.pi / 2
        local cr = (i % 2 == 0) and r or (r * 0.4)
        verts[#verts + 1] = x + math.cos(angle) * cr
        verts[#verts + 1] = y + math.sin(angle) * cr
    end
    love.graphics.polygon("fill", verts)
end

function Exit:destroy()
    if not self.body:isDestroyed() then
        self.body:destroy()
    end
end

return Exit
