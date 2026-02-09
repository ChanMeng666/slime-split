local Slime = require("src.entities.slime")
local Utils = require("src.lib.utils")

local SlimeManager = {}
SlimeManager.__index = SlimeManager

local BASE_RADIUS = 16
local MIN_MASS = 0.5  -- minimum mass before refusing to split

function SlimeManager.new(world, particles)
    local self = setmetatable({}, SlimeManager)
    self.world = world
    self.particles = particles
    self.slimes = {}
    self.selected_index = 1
    self.total_mass = 0
    self.action_queue = {} -- deferred split/merge actions
    return self
end

function SlimeManager:spawn(x, y, mass)
    local slime = Slime.new(self.world, x, y, mass)
    table.insert(self.slimes, slime)
    if #self.slimes == 1 then
        slime.is_selected = true
        self.selected_index = 1
    end
    self.total_mass = self.total_mass + mass
    return slime
end

function SlimeManager:getSelected()
    if #self.slimes == 0 then return nil end
    return self.slimes[self.selected_index]
end

function SlimeManager:cycleSelection()
    if #self.slimes <= 1 then return end
    local old = self.slimes[self.selected_index]
    if old then old.is_selected = false end

    self.selected_index = self.selected_index + 1
    if self.selected_index > #self.slimes then
        self.selected_index = 1
    end

    local new = self.slimes[self.selected_index]
    if new then new.is_selected = true end
end

function SlimeManager:queueSplit()
    table.insert(self.action_queue, {action = "split"})
end

function SlimeManager:queueMerge()
    table.insert(self.action_queue, {action = "merge"})
end

function SlimeManager:processQueue()
    for _, cmd in ipairs(self.action_queue) do
        if cmd.action == "split" then
            self:doSplit()
        elseif cmd.action == "merge" then
            self:doMerge()
        end
    end
    self.action_queue = {}
end

function SlimeManager:doSplit()
    local slime = self:getSelected()
    if not slime or not slime.alive then return end
    if slime.mass < MIN_MASS * 2 then
        slime:flashError()
        return
    end

    local x, y = slime:getPosition()
    local vx, vy = slime.body:getLinearVelocity()
    local old_mass = slime.mass
    local new_mass = old_mass / 2
    local new_radius = BASE_RADIUS * math.sqrt(new_mass)
    local offset = new_radius + 2

    -- Check if there's room to split (simple raycast approach)
    -- We'll try to place them, and if overlapping walls, push them out
    local x1, y1 = x - offset, y
    local x2, y2 = x + offset, y

    -- Remove old slime
    local idx = self:indexOf(slime)
    slime:destroy()
    table.remove(self.slimes, idx)

    -- Create two new slimes
    local s1 = Slime.new(self.world, x1, y1, new_mass)
    local s2 = Slime.new(self.world, x2, y2, new_mass)

    -- Preserve velocity + separation impulse
    s1.body:setLinearVelocity(vx, vy)
    s2.body:setLinearVelocity(vx, vy)
    s1.body:applyLinearImpulse(-40 * math.sqrt(new_mass), -20)
    s2.body:applyLinearImpulse(40 * math.sqrt(new_mass), -20)

    -- Squash effect
    s1.squash = 0.7
    s2.squash = 0.7

    table.insert(self.slimes, s1)
    table.insert(self.slimes, s2)

    -- Select the first new one
    self.selected_index = #self.slimes - 1
    s1.is_selected = true

    -- Particles
    if self.particles then
        self.particles:emitSplit(x, y)
    end

    -- Disturb vertices on both
    for i = 1, 24 do
        s1.vert_velocities[i] = (math.random() - 0.5) * 5
        s2.vert_velocities[i] = (math.random() - 0.5) * 5
    end
end

function SlimeManager:doMerge()
    if #self.slimes < 2 then return end

    local selected = self:getSelected()
    if not selected or not selected.alive then return end

    -- Find nearest other slime
    local sx, sy = selected:getPosition()
    local nearest = nil
    local nearest_dist = math.huge
    local nearest_idx = nil

    for i, s in ipairs(self.slimes) do
        if s ~= selected and s.alive then
            local ox, oy = s:getPosition()
            local d = Utils.distance(sx, sy, ox, oy)
            -- Must be close enough to merge (within 3x combined radius)
            local merge_range = (selected.radius + s.radius) * 3
            if d < merge_range and d < nearest_dist then
                nearest = s
                nearest_dist = d
                nearest_idx = i
            end
        end
    end

    if not nearest then
        selected:flashError()
        return
    end

    local ox, oy = nearest:getPosition()
    local mx, my = (sx + ox) / 2, (sy + oy) / 2
    local new_mass = selected.mass + nearest.mass
    local vx1, vy1 = selected.body:getLinearVelocity()
    local vx2, vy2 = nearest.body:getLinearVelocity()

    -- Remove both
    local idx1 = self:indexOf(selected)
    local idx2 = self:indexOf(nearest)
    selected:destroy()
    nearest:destroy()

    -- Remove from list (higher index first to avoid shift issues)
    if idx1 > idx2 then
        table.remove(self.slimes, idx1)
        table.remove(self.slimes, idx2)
    else
        table.remove(self.slimes, idx2)
        table.remove(self.slimes, idx1)
    end

    -- Create merged slime
    local merged = Slime.new(self.world, mx, my, new_mass)
    merged.body:setLinearVelocity((vx1 + vx2) / 2, (vy1 + vy2) / 2)
    merged.squash = 1.4 -- expand effect
    merged.is_selected = true

    table.insert(self.slimes, merged)
    self.selected_index = #self.slimes

    -- Particles
    if self.particles then
        self.particles:emitMerge(mx, my)
    end

    -- Disturb vertices
    for i = 1, 24 do
        merged.vert_velocities[i] = (math.random() - 0.5) * 6
    end
end

function SlimeManager:indexOf(slime)
    for i, s in ipairs(self.slimes) do
        if s == slime then return i end
    end
    return nil
end

function SlimeManager:update(dt)
    -- Clean up dead slimes
    for i = #self.slimes, 1, -1 do
        if not self.slimes[i].alive then
            table.remove(self.slimes, i)
            if self.selected_index > #self.slimes then
                self.selected_index = math.max(1, #self.slimes)
            end
        end
    end

    -- Ensure selection is valid
    if self.selected_index > #self.slimes then
        self.selected_index = math.max(1, #self.slimes)
    end
    for i, s in ipairs(self.slimes) do
        s.is_selected = (i == self.selected_index)
    end

    -- Update all slimes
    for _, s in ipairs(self.slimes) do
        s:update(dt)
    end
end

function SlimeManager:draw()
    for _, s in ipairs(self.slimes) do
        s:draw()
    end
end

function SlimeManager:destroy()
    for _, s in ipairs(self.slimes) do
        s:destroy()
    end
    self.slimes = {}
end

function SlimeManager:getSlimeCount()
    return #self.slimes
end

function SlimeManager:getSelectedMass()
    local s = self:getSelected()
    return s and s.mass or 0
end

return SlimeManager
