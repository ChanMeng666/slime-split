local Colors = require("src.lib.colors")

local Pause = {}
Pause.__index = Pause

function Pause.new(state_manager)
    local self = setmetatable({}, Pause)
    self.sm = state_manager
    self.selected = 1
    self.options = {"Resume", "Restart", "Quit to Menu"}
    return self
end

function Pause:enter(gameplay_state)
    self.gameplay = gameplay_state
    self.selected = 1
end

function Pause:update(dt)
    -- Paused, nothing to update
end

function Pause:draw()
    -- Draw the gameplay underneath
    if self.gameplay and self.gameplay.draw then
        self.gameplay:draw()
    end

    -- Overlay
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    -- Pause title
    love.graphics.setColor(Colors.text_title)
    love.graphics.printf("PAUSED", 0, 140, 640, "center")

    -- Options
    for i, opt in ipairs(self.options) do
        local y = 210 + (i - 1) * 40
        if i == self.selected then
            love.graphics.setColor(Colors.selected)
            love.graphics.printf("> " .. opt .. " <", 0, y, 640, "center")
        else
            love.graphics.setColor(Colors.text)
            love.graphics.printf(opt, 0, y, 640, "center")
        end
    end
end

function Pause:keypressed(key)
    if key == "up" then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #self.options end
    elseif key == "down" then
        self.selected = self.selected + 1
        if self.selected > #self.options then self.selected = 1 end
    elseif key == "return" or key == "space" then
        if self.selected == 1 then
            -- Resume
            self.sm:switch("gameplay_resume")
        elseif self.selected == 2 then
            -- Restart
            if self.gameplay then
                self.sm:switch("gameplay", self.gameplay.current_level)
            end
        elseif self.selected == 3 then
            -- Quit to menu
            self.sm:switch("menu")
        end
    elseif key == "escape" then
        self.sm:switch("gameplay_resume")
    end
end

return Pause
