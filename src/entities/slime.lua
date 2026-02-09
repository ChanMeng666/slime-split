local Colors = require("src.lib.colors")
local Utils = require("src.lib.utils")

local Slime = {}
Slime.__index = Slime

local BASE_RADIUS = 16
local MOVE_FORCE = 800
local JUMP_IMPULSE = 280
local MAX_HSPEED = 180
local VERTEX_COUNT = 24

function Slime.new(world, x, y, mass)
    local self = setmetatable({}, Slime)
    self.mass = mass
    self.radius = BASE_RADIUS * math.sqrt(mass)
    self.alive = true

    -- Physics body
    self.body = love.physics.newBody(world, x, y, "dynamic")
    self.body:setFixedRotation(true)
    self.body:setLinearDamping(2.5)

    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1)
    self.fixture:setFriction(0.6)
    self.fixture:setRestitution(0.1)
    self.fixture:setUserData({type = "slime", slime = self})
    -- Set mass explicitly
    self.body:setMass(mass)

    -- Foot sensor for ground detection
    self.foot_shape = love.physics.newCircleShape(0, self.radius * 0.7, self.radius * 0.4)
    self.foot_fixture = love.physics.newFixture(self.body, self.foot_shape, 0)
    self.foot_fixture:setSensor(true)
    self.foot_fixture:setUserData({type = "slime_foot", slime = self})

    self.ground_contacts = 0

    -- Visual squash/stretch spring
    self.squash = 1.0
    self.squash_vel = 0
    self.prev_vy = 0

    -- Vertex deformation for wobbly look
    self.vert_offsets = {}
    self.vert_velocities = {}
    for i = 1, VERTEX_COUNT do
        self.vert_offsets[i] = 0
        self.vert_velocities[i] = 0
    end

    -- Selection & error flash
    self.is_selected = false
    self.select_pulse = 0
    self.error_timer = 0

    return self
end

function Slime:isGrounded()
    return self.ground_contacts > 0
end

function Slime:update(dt)
    if not self.alive then return end

    -- Squash/stretch spring
    local vy = self.body:getLinearVelocity()
    local target = 1.0

    -- Landing detection: was falling fast, now grounded
    if self:isGrounded() and self.prev_vy > 100 then
        self.squash = Utils.clamp(1 - self.prev_vy / 800, 0.5, 0.9)
        self.squash_vel = 0
    end
    self.prev_vy = select(2, self.body:getLinearVelocity())

    -- Spring back to 1.0
    local spring_k = 120
    local damping = 8
    local force = -spring_k * (self.squash - target) - damping * self.squash_vel
    self.squash_vel = self.squash_vel + force * dt
    self.squash = self.squash + self.squash_vel * dt

    -- Vertex wobble
    for i = 1, VERTEX_COUNT do
        local spring_f = -60 * self.vert_offsets[i] - 5 * self.vert_velocities[i]
        self.vert_velocities[i] = self.vert_velocities[i] + spring_f * dt
        self.vert_offsets[i] = self.vert_offsets[i] + self.vert_velocities[i] * dt
    end

    -- Selection pulse
    self.select_pulse = self.select_pulse + dt * 4
    if self.select_pulse > math.pi * 2 then
        self.select_pulse = self.select_pulse - math.pi * 2
    end

    -- Error flash decay
    if self.error_timer > 0 then
        self.error_timer = self.error_timer - dt
    end
end

function Slime:moveLeft()
    if not self.alive then return end
    local vx = self.body:getLinearVelocity()
    if vx > -MAX_HSPEED then
        self.body:applyForce(-MOVE_FORCE * self.mass, 0)
    end
end

function Slime:moveRight()
    if not self.alive then return end
    local vx = self.body:getLinearVelocity()
    if vx < MAX_HSPEED then
        self.body:applyForce(MOVE_FORCE * self.mass, 0)
    end
end

function Slime:jump()
    if not self.alive or not self:isGrounded() then return end
    local vx, _ = self.body:getLinearVelocity()
    self.body:setLinearVelocity(vx, 0)
    self.body:applyLinearImpulse(0, -JUMP_IMPULSE * math.sqrt(self.mass))
    self.squash = 1.3 -- stretch on jump
    -- Disturb vertices
    for i = 1, VERTEX_COUNT do
        self.vert_velocities[i] = self.vert_velocities[i] + (math.random() - 0.5) * 3
    end
end

function Slime:flashError()
    self.error_timer = 0.3
end

function Slime:getPosition()
    if self.body:isDestroyed() then return 0, 0 end
    return self.body:getPosition()
end

function Slime:draw()
    if not self.alive then return end
    local x, y = self:getPosition()
    local r = self.radius

    local sx = 1 / self.squash
    local sy = self.squash

    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(sx, sy)

    -- Build deformed polygon
    local verts = {}
    for i = 1, VERTEX_COUNT do
        local angle = (i - 1) / VERTEX_COUNT * math.pi * 2
        local offset = self.vert_offsets[i]
        local cr = r + offset
        verts[#verts + 1] = math.cos(angle) * cr
        verts[#verts + 1] = math.sin(angle) * cr
    end

    -- Body fill
    if self.error_timer > 0 then
        local flash = math.sin(self.error_timer * 30) * 0.5 + 0.5
        love.graphics.setColor(
            Utils.lerp(Colors.slime[1], Colors.error_flash[1], flash),
            Utils.lerp(Colors.slime[2], Colors.error_flash[2], flash),
            Utils.lerp(Colors.slime[3], Colors.error_flash[3], flash),
            1
        )
    else
        love.graphics.setColor(Colors.slime)
    end
    love.graphics.polygon("fill", verts)

    -- Darker bottom half overlay
    love.graphics.setColor(Colors.slime_dark[1], Colors.slime_dark[2], Colors.slime_dark[3], 0.3)
    love.graphics.arc("fill", 0, 0, r, 0.2, math.pi - 0.2)

    -- Highlight
    love.graphics.setColor(Colors.slime_light)
    love.graphics.ellipse("fill", -r * 0.25, -r * 0.35, r * 0.35, r * 0.2)

    -- Eyes
    local eye_y = -r * 0.15
    local eye_sep = r * 0.35
    local eye_r = r * 0.2
    local pupil_r = eye_r * 0.55

    love.graphics.setColor(Colors.slime_eye)
    love.graphics.circle("fill", -eye_sep, eye_y, eye_r)
    love.graphics.circle("fill", eye_sep, eye_y, eye_r)

    love.graphics.setColor(Colors.slime_pupil)
    love.graphics.circle("fill", -eye_sep + 1.5, eye_y + 1, pupil_r)
    love.graphics.circle("fill", eye_sep + 1.5, eye_y + 1, pupil_r)

    love.graphics.pop()

    -- Selection indicator
    if self.is_selected then
        local pulse = 0.5 + 0.5 * math.sin(self.select_pulse)
        love.graphics.setColor(Colors.selected[1], Colors.selected[2], Colors.selected[3], 0.3 + 0.4 * pulse)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", x, y, r + 4 + pulse * 2)
        love.graphics.setLineWidth(1)
    end
end

function Slime:destroy()
    self.alive = false
    if not self.body:isDestroyed() then
        self.body:destroy()
    end
end

return Slime
