local Utils = require("src.lib.utils")

local Transition = {}
Transition.__index = Transition

function Transition.new()
    local self = setmetatable({}, Transition)
    self.alpha = 0
    self.target = 0
    self.speed = 3
    self.callback = nil
    self.active = false
    return self
end

function Transition:fadeIn(callback)
    self.alpha = 1
    self.target = 0
    self.speed = 3
    self.callback = callback
    self.active = true
end

function Transition:fadeOut(callback)
    self.alpha = 0
    self.target = 1
    self.speed = 3
    self.callback = callback
    self.active = true
end

function Transition:update(dt)
    if not self.active then return end

    self.alpha = Utils.lerp(self.alpha, self.target, self.speed * dt)

    if math.abs(self.alpha - self.target) < 0.01 then
        self.alpha = self.target
        self.active = false
        if self.callback then
            self.callback()
            self.callback = nil
        end
    end
end

function Transition:draw()
    if self.alpha > 0.01 then
        love.graphics.setColor(0, 0, 0, self.alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end

function Transition:isActive()
    return self.active
end

return Transition
