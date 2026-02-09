local Block = require("src.entities.block")
local PressurePlate = require("src.entities.pressure_plate")
local Door = require("src.entities.door")
local Exit = require("src.entities.exit")
local Colors = require("src.lib.colors")

local LevelLoader = {}
LevelLoader.__index = LevelLoader

function LevelLoader.new()
    local self = setmetatable({}, LevelLoader)
    self.walls = {}       -- {body, shape, fixture, x, y, w, h}
    self.blocks = {}
    self.plates = {}
    self.doors = {}
    self.exit = nil
    return self
end

function LevelLoader:load(world, level_def, slime_manager)
    self:clear()

    -- Create walls
    for _, w in ipairs(level_def.walls) do
        local wall = self:createWall(world, w[1], w[2], w[3], w[4])
        table.insert(self.walls, wall)
    end

    -- Create doors first (plates reference them)
    local door_map = {}
    for _, d in ipairs(level_def.doors or {}) do
        local door = Door.new(world, d[1], d[2], d[3], d[4])
        door_map[d[5]] = door
        table.insert(self.doors, door)
    end

    -- Create pressure plates
    for _, p in ipairs(level_def.plates or {}) do
        local linked_door = door_map[p[5]]
        local plate = PressurePlate.new(world, p[1], p[2], p[3], p[4], linked_door)
        table.insert(self.plates, plate)
    end

    -- Create blocks
    for _, b in ipairs(level_def.blocks or {}) do
        local block = Block.new(world, b[1], b[2], b[3], b[4])
        table.insert(self.blocks, block)
    end

    -- Create exit
    if level_def.exit then
        local e = level_def.exit
        self.exit = Exit.new(world, e[1], e[2], e[3], e[4])
    end

    -- Spawn slimes
    for _, s in ipairs(level_def.slimes) do
        slime_manager:spawn(s[1], s[2], s[3])
    end

    return level_def.bounds
end

function LevelLoader:createWall(world, x, y, w, h)
    local body = love.physics.newBody(world, x + w / 2, y + h / 2, "static")
    local shape = love.physics.newRectangleShape(w, h)
    local fixture = love.physics.newFixture(body, shape, 0)
    fixture:setFriction(0.5)
    fixture:setUserData({type = "wall"})
    return {body = body, x = x, y = y, w = w, h = h}
end

function LevelLoader:update(dt)
    for _, plate in ipairs(self.plates) do
        plate:update(dt)
    end
    for _, door in ipairs(self.doors) do
        door:update(dt)
    end
    if self.exit then
        self.exit:update(dt)
    end
end

function LevelLoader:draw()
    -- Walls
    for _, wall in ipairs(self.walls) do
        -- Main fill
        love.graphics.setColor(Colors.wall)
        love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h)
        -- Top edge highlight
        love.graphics.setColor(Colors.wall_light)
        if wall.h > 4 then
            love.graphics.rectangle("fill", wall.x, wall.y, wall.w, 2)
        end
        -- Pixel grid pattern
        love.graphics.setColor(Colors.wall_light[1], Colors.wall_light[2], Colors.wall_light[3], 0.08)
        for gx = wall.x, wall.x + wall.w - 1, 16 do
            love.graphics.line(gx, wall.y, gx, wall.y + wall.h)
        end
        for gy = wall.y, wall.y + wall.h - 1, 16 do
            love.graphics.line(wall.x, gy, wall.x + wall.w, gy)
        end
    end

    -- Doors
    for _, door in ipairs(self.doors) do
        door:draw()
    end

    -- Pressure plates
    for _, plate in ipairs(self.plates) do
        plate:draw()
    end

    -- Blocks
    for _, block in ipairs(self.blocks) do
        block:draw()
    end

    -- Exit
    if self.exit then
        self.exit:draw()
    end
end

function LevelLoader:isExitTriggered()
    return self.exit and self.exit.triggered
end

function LevelLoader:clear()
    -- Destroy physics bodies
    for _, wall in ipairs(self.walls) do
        if not wall.body:isDestroyed() then
            wall.body:destroy()
        end
    end
    for _, block in ipairs(self.blocks) do
        block:destroy()
    end
    for _, plate in ipairs(self.plates) do
        plate:destroy()
    end
    for _, door in ipairs(self.doors) do
        door:destroy()
    end
    if self.exit then
        self.exit:destroy()
    end

    self.walls = {}
    self.blocks = {}
    self.plates = {}
    self.doors = {}
    self.exit = nil
end

return LevelLoader
