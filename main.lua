-- Slime Split - A physics puzzle game
-- Control a slime that splits and merges to solve puzzles

local StateManager = require("src.states.state_manager")
local Menu = require("src.states.menu")
local Gameplay = require("src.states.gameplay")
local Pause = require("src.states.pause")
local LevelComplete = require("src.states.level_complete")

local sm

function love.load()
    -- Pixel-perfect rendering
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")

    -- State manager setup
    sm = StateManager.new()

    local menu = Menu.new(sm)
    local gameplay = Gameplay.new(sm)
    local pause = Pause.new(sm)
    local level_complete = LevelComplete.new(sm)

    sm:register("menu", menu)
    sm:register("gameplay", gameplay)
    sm:register("pause", pause)
    sm:register("level_complete", level_complete)

    -- Special pseudo-state for resuming gameplay from pause
    sm:register("gameplay_resume", {
        enter = function()
            -- Switch back to gameplay without re-entering
            sm.current = gameplay
            sm.current_name = "gameplay"
            gameplay.paused = false
        end
    })

    sm:switch("menu")
end

function love.update(dt)
    -- Cap delta time to prevent physics explosions
    dt = math.min(dt, 1 / 30)
    sm:update(dt)
end

function love.draw()
    sm:draw()
end

function love.keypressed(key)
    if key == "f12" then
        love.graphics.captureScreenshot(function(imageData)
            local fileData = imageData:encode("png")
            love.filesystem.write("screenshot.png", fileData)
        end)
        return
    end
    sm:keypressed(key)
end

function love.keyreleased(key)
    sm:keyreleased(key)
end
