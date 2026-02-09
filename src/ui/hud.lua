local Colors = require("src.lib.colors")

local HUD = {}
HUD.__index = HUD

function HUD.new()
    local self = setmetatable({}, HUD)
    return self
end

function HUD:draw(level_name, slime_count, selected_mass, total_mass)
    -- Semi-transparent top bar
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 640, 28)

    -- Level name (left)
    love.graphics.setColor(Colors.text)
    love.graphics.print(level_name, 8, 6)

    -- Slime info (right)
    love.graphics.setColor(Colors.slime)
    local info = string.format("Slimes: %d  Mass: %.1f / %.1f", slime_count, selected_mass, total_mass)
    local font = love.graphics.getFont()
    local tw = font:getWidth(info)
    love.graphics.print(info, 632 - tw, 6)

    -- Controls hint at bottom
    love.graphics.setColor(Colors.text_dim[1], Colors.text_dim[2], Colors.text_dim[3], 0.6)
    love.graphics.printf("Shift=Split  M=Merge  Tab=Switch  R=Restart  Esc=Pause", 0, 464, 640, "center")
end

return HUD
