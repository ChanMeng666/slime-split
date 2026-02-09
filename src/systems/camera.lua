local Utils = require("src.lib.utils")

local Camera = {}
Camera.__index = Camera

function Camera.new()
    local self = setmetatable({}, Camera)
    self.x = 0
    self.y = 0
    self.target_x = 0
    self.target_y = 0
    self.smoothing = 5
    self.bounds = nil -- {x, y, w, h} optional level bounds
    return self
end

function Camera:setBounds(x, y, w, h)
    self.bounds = {x = x, y = y, w = w, h = h}
end

function Camera:follow(x, y)
    self.target_x = x
    self.target_y = y
end

function Camera:update(dt)
    self.x = Utils.lerp(self.x, self.target_x, self.smoothing * dt)
    self.y = Utils.lerp(self.y, self.target_y, self.smoothing * dt)

    -- Clamp to level bounds
    if self.bounds then
        local hw = love.graphics.getWidth() / 2
        local hh = love.graphics.getHeight() / 2

        local min_x = self.bounds.x + hw
        local max_x = self.bounds.x + self.bounds.w - hw
        local min_y = self.bounds.y + hh
        local max_y = self.bounds.y + self.bounds.h - hh

        if max_x > min_x then
            self.x = Utils.clamp(self.x, min_x, max_x)
        else
            self.x = self.bounds.x + self.bounds.w / 2
        end
        if max_y > min_y then
            self.y = Utils.clamp(self.y, min_y, max_y)
        else
            self.y = self.bounds.y + self.bounds.h / 2
        end
    end

    -- Round to prevent sub-pixel jitter
    self.x = Utils.round(self.x)
    self.y = Utils.round(self.y)
end

function Camera:attach()
    love.graphics.push()
    love.graphics.translate(
        Utils.round(love.graphics.getWidth() / 2 - self.x),
        Utils.round(love.graphics.getHeight() / 2 - self.y)
    )
end

function Camera:detach()
    love.graphics.pop()
end

function Camera:snapTo(x, y)
    self.x = x
    self.y = y
    self.target_x = x
    self.target_y = y
end

return Camera
