local Colors = require("src.lib.colors")

local Particles = {}
Particles.__index = Particles

function Particles.new()
    local self = setmetatable({}, Particles)

    -- Create 4x4 pixel particle image
    local imgdata = love.image.newImageData(4, 4)
    for px = 0, 3 do
        for py = 0, 3 do
            imgdata:setPixel(px, py, 1, 1, 1, 1)
        end
    end
    self.pixel = love.graphics.newImage(imgdata)
    self.pixel:setFilter("nearest", "nearest")

    -- Split burst particles
    self.split_ps = love.graphics.newParticleSystem(self.pixel, 100)
    self.split_ps:setParticleLifetime(0.3, 0.7)
    self.split_ps:setSpeed(80, 200)
    self.split_ps:setSpread(math.pi * 2)
    self.split_ps:setSizes(1.0, 0.3)
    self.split_ps:setColors(
        Colors.particle_split[1], Colors.particle_split[2], Colors.particle_split[3], 1,
        Colors.slime[1], Colors.slime[2], Colors.slime[3], 0
    )
    self.split_ps:setLinearDamping(3)

    -- Merge gather particles
    self.merge_ps = love.graphics.newParticleSystem(self.pixel, 100)
    self.merge_ps:setParticleLifetime(0.3, 0.6)
    self.merge_ps:setSpeed(50, 120)
    self.merge_ps:setSpread(math.pi * 2)
    self.merge_ps:setSizes(0.5, 1.2, 0)
    self.merge_ps:setColors(
        Colors.particle_merge[1], Colors.particle_merge[2], Colors.particle_merge[3], 1,
        Colors.slime_light[1], Colors.slime_light[2], Colors.slime_light[3], 0
    )
    self.merge_ps:setLinearAcceleration(-50, -50, 50, 50)

    -- Landing dust particles
    self.land_ps = love.graphics.newParticleSystem(self.pixel, 50)
    self.land_ps:setParticleLifetime(0.2, 0.5)
    self.land_ps:setSpeed(20, 60)
    self.land_ps:setSpread(math.pi * 0.6)
    self.land_ps:setDirection(-math.pi / 2)
    self.land_ps:setSizes(0.8, 0.2)
    self.land_ps:setColors(
        Colors.particle_land[1], Colors.particle_land[2], Colors.particle_land[3], 0.7,
        Colors.particle_land[1], Colors.particle_land[2], Colors.particle_land[3], 0
    )
    self.land_ps:setLinearDamping(4)

    return self
end

function Particles:emitSplit(x, y)
    self.split_ps:setPosition(x, y)
    self.split_ps:emit(30)
end

function Particles:emitMerge(x, y)
    self.merge_ps:setPosition(x, y)
    self.merge_ps:emit(25)
end

function Particles:emitLand(x, y)
    self.land_ps:setPosition(x, y)
    self.land_ps:emit(8)
end

function Particles:update(dt)
    self.split_ps:update(dt)
    self.merge_ps:update(dt)
    self.land_ps:update(dt)
end

function Particles:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.split_ps)
    love.graphics.draw(self.merge_ps)
    love.graphics.draw(self.land_ps)
end

return Particles
