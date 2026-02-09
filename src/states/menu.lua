local Colors = require("src.lib.colors")

local Menu = {}
Menu.__index = Menu

function Menu.new(state_manager)
    local self = setmetatable({}, Menu)
    self.sm = state_manager
    self.selected = 1
    self.max_level = 5
    self.time = 0
    -- Simple slime animation on title
    self.slime_y = 200
    self.slime_vy = 0
    self.slime_squash = 1
    return self
end

function Menu:enter()
    self.time = 0
end

function Menu:update(dt)
    self.time = self.time + dt

    -- Bouncing slime decoration
    self.slime_vy = self.slime_vy + 300 * dt
    self.slime_y = self.slime_y + self.slime_vy * dt
    if self.slime_y > 200 then
        self.slime_y = 200
        self.slime_vy = -180
        self.slime_squash = 0.6
    end
    self.slime_squash = self.slime_squash + (1 - self.slime_squash) * 6 * dt
end

function Menu:draw()
    love.graphics.clear(Colors.bg)

    -- Title
    local title_scale = 1 + math.sin(self.time * 2) * 0.03
    love.graphics.push()
    love.graphics.translate(320, 80)
    love.graphics.scale(title_scale, title_scale)
    love.graphics.setColor(Colors.text_title)
    love.graphics.printf("SLIME SPLIT", -200, -20, 400, "center")
    love.graphics.setColor(Colors.text_dim)
    love.graphics.printf("Slime Split", -200, 10, 400, "center")
    love.graphics.pop()

    -- Decorative bouncing slime
    self:drawSlimeDecor(320, self.slime_y - 60)

    -- Level select
    love.graphics.setColor(Colors.text)
    love.graphics.printf("SELECT LEVEL", 0, 260, 640, "center")

    for i = 1, self.max_level do
        local x = 320 + (i - 3) * 60
        local y = 310
        if i == self.selected then
            love.graphics.setColor(Colors.selected)
            love.graphics.rectangle("line", x - 20, y - 15, 40, 30, 4, 4)
        end
        love.graphics.setColor(Colors.text)
        love.graphics.printf(tostring(i), x - 20, y - 8, 40, "center")
    end

    -- Controls hint
    love.graphics.setColor(Colors.text_dim)
    love.graphics.printf("Arrow Keys: Select    Enter: Start", 0, 400, 640, "center")
    love.graphics.printf("In Game: Arrows=Move  Space=Jump  Shift=Split  M=Merge  Tab=Switch", 0, 425, 640, "center")
end

function Menu:drawSlimeDecor(x, y)
    local r = 24
    local sx = 1 / self.slime_squash
    local sy = self.slime_squash

    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(sx, sy)

    -- Body
    love.graphics.setColor(Colors.slime)
    love.graphics.circle("fill", 0, 0, r)
    -- Highlight
    love.graphics.setColor(Colors.slime_light)
    love.graphics.ellipse("fill", -6, -8, 8, 5)
    -- Eyes
    love.graphics.setColor(Colors.slime_eye)
    love.graphics.circle("fill", -7, -4, 5)
    love.graphics.circle("fill", 7, -4, 5)
    love.graphics.setColor(Colors.slime_pupil)
    love.graphics.circle("fill", -5, -3, 2.5)
    love.graphics.circle("fill", 9, -3, 2.5)

    love.graphics.pop()
end

function Menu:keypressed(key)
    if key == "left" then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = self.max_level end
    elseif key == "right" then
        self.selected = self.selected + 1
        if self.selected > self.max_level then self.selected = 1 end
    elseif key == "return" or key == "space" then
        self.sm:switch("gameplay", self.selected)
    end
end

return Menu
