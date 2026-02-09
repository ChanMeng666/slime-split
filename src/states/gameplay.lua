local Physics = require("src.systems.physics")
local Camera = require("src.systems.camera")
local Particles = require("src.systems.particles")
local Input = require("src.systems.input")
local SlimeManager = require("src.entities.slime_manager")
local LevelLoader = require("src.levels.level_loader")
local LevelDefs = require("src.levels.level_defs")
local HUD = require("src.ui.hud")
local Transition = require("src.ui.transition")
local Colors = require("src.lib.colors")

local Gameplay = {}
Gameplay.__index = Gameplay

function Gameplay.new(state_manager)
    local self = setmetatable({}, Gameplay)
    self.sm = state_manager
    self.physics = nil
    self.camera = Camera.new()
    self.particles = nil
    self.slime_mgr = nil
    self.level_loader = nil
    self.hud = HUD.new()
    self.transition = Transition.new()
    self.current_level = 1
    self.level_name = ""
    self.paused = false
    self.level_complete = false
    return self
end

function Gameplay:enter(level_num)
    self.current_level = level_num or 1
    self.level_complete = false
    self.paused = false

    -- Clean up previous level if any
    self:cleanup()

    -- Initialize systems
    self.physics = Physics.new()
    self.particles = Particles.new()
    self.slime_mgr = SlimeManager.new(self.physics.world, self.particles)
    self.level_loader = LevelLoader.new()

    -- Load level
    local def = LevelDefs[self.current_level]
    if not def then
        self.sm:switch("menu")
        return
    end

    self.level_name = def.name
    local bounds = self.level_loader:load(self.physics.world, def, self.slime_mgr)

    -- Set camera bounds
    if bounds then
        self.camera:setBounds(bounds[1], bounds[2], bounds[3], bounds[4])
    end

    -- Snap camera to starting slime position
    local selected = self.slime_mgr:getSelected()
    if selected then
        local sx, sy = selected:getPosition()
        self.camera:snapTo(sx, sy)
    end

    -- Fade in
    self.transition:fadeIn()
end

function Gameplay:leave()
    -- Don't cleanup here, in case pause state needs to draw us
end

function Gameplay:cleanup()
    if self.slime_mgr then
        self.slime_mgr:destroy()
        self.slime_mgr = nil
    end
    if self.level_loader then
        self.level_loader:clear()
        self.level_loader = nil
    end
    if self.physics then
        self.physics:destroy()
        self.physics = nil
    end
    self.particles = nil
end

function Gameplay:update(dt)
    if self.paused or self.level_complete then return end
    if self.transition:isActive() then
        self.transition:update(dt)
        return
    end

    -- Input handling for selected slime
    local selected = self.slime_mgr:getSelected()
    if selected then
        if Input.isLeft() then selected:moveLeft() end
        if Input.isRight() then selected:moveRight() end
    end

    -- Physics step
    self.physics:update(dt)

    -- Process deferred split/merge actions (after physics step)
    self.slime_mgr:processQueue()

    -- Update entities
    self.slime_mgr:update(dt)
    self.level_loader:update(dt)
    self.particles:update(dt)

    -- Camera follow selected slime
    selected = self.slime_mgr:getSelected()
    if selected then
        local sx, sy = selected:getPosition()
        self.camera:follow(sx, sy)
    end
    self.camera:update(dt)

    -- Check exit
    if self.level_loader:isExitTriggered() and not self.level_complete then
        self.level_complete = true
        self.transition:fadeOut(function()
            self:cleanup()
            self.sm:switch("level_complete", self.current_level)
        end)
    end
end

function Gameplay:draw()
    love.graphics.clear(Colors.bg)

    -- World drawing (camera transformed)
    self.camera:attach()

    -- Level elements
    self.level_loader:draw()

    -- Slimes
    self.slime_mgr:draw()

    -- Particles
    self.particles:draw()

    self.camera:detach()

    -- HUD (screen space)
    self.hud:draw(
        self.level_name,
        self.slime_mgr:getSlimeCount(),
        self.slime_mgr:getSelectedMass(),
        self.slime_mgr.total_mass
    )

    -- Transition overlay
    self.transition:draw()
end

function Gameplay:keypressed(key)
    if self.transition:isActive() then return end

    if key == "escape" then
        self.sm:switch("pause", self)
    elseif key == "r" then
        self:enter(self.current_level)
    elseif key == "space" then
        local selected = self.slime_mgr:getSelected()
        if selected then selected:jump() end
    elseif key == "lshift" or key == "rshift" then
        self.slime_mgr:queueSplit()
    elseif key == "m" then
        self.slime_mgr:queueMerge()
    elseif key == "tab" then
        self.slime_mgr:cycleSelection()
    end
end

return Gameplay
