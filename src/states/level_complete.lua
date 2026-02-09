local Colors = require("src.lib.colors")

local LevelComplete = {}
LevelComplete.__index = LevelComplete

function LevelComplete.new(state_manager)
    local self = setmetatable({}, LevelComplete)
    self.sm = state_manager
    self.selected = 1
    self.level = 1
    self.max_level = 5
    self.time = 0
    return self
end

function LevelComplete:enter(level_num)
    self.level = level_num
    self.selected = 1
    self.time = 0
end

function LevelComplete:update(dt)
    self.time = self.time + dt
end

function LevelComplete:draw()
    love.graphics.clear(Colors.bg)

    -- Celebration
    local bounce = math.sin(self.time * 4) * 5
    love.graphics.setColor(Colors.exit_gold)
    love.graphics.printf("LEVEL COMPLETE!", 0, 120 + bounce, 640, "center")

    love.graphics.setColor(Colors.text)
    love.graphics.printf("Level " .. self.level .. " cleared!", 0, 170, 640, "center")

    -- Star decoration
    local cx = 320
    local cy = 220
    for i = 0, 4 do
        local angle = (i / 5) * math.pi * 2 + self.time * 0.5
        local sr = 40 + math.sin(self.time * 2 + i) * 5
        local sx = cx + math.cos(angle) * sr
        local sy = cy + math.sin(angle) * sr
        love.graphics.setColor(Colors.exit_gold[1], Colors.exit_gold[2], Colors.exit_gold[3], 0.6)
        self:drawStar(sx, sy, 5, 5)
    end

    -- Options
    local has_next = self.level < self.max_level
    local options = has_next and {"Next Level", "Replay", "Menu"} or {"Replay", "Menu"}

    for i, opt in ipairs(options) do
        local y = 280 + (i - 1) * 40
        if i == self.selected then
            love.graphics.setColor(Colors.selected)
            love.graphics.printf("> " .. opt .. " <", 0, y, 640, "center")
        else
            love.graphics.setColor(Colors.text)
            love.graphics.printf(opt, 0, y, 640, "center")
        end
    end

    self._options = options
end

function LevelComplete:drawStar(x, y, r, points)
    local verts = {}
    for i = 0, points * 2 - 1 do
        local angle = (i / (points * 2)) * math.pi * 2 - math.pi / 2
        local cr = (i % 2 == 0) and r or (r * 0.4)
        verts[#verts + 1] = x + math.cos(angle) * cr
        verts[#verts + 1] = y + math.sin(angle) * cr
    end
    love.graphics.polygon("fill", verts)
end

function LevelComplete:keypressed(key)
    local has_next = self.level < self.max_level
    local options = has_next and {"next", "replay", "menu"} or {"replay", "menu"}

    if key == "up" then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #options end
    elseif key == "down" then
        self.selected = self.selected + 1
        if self.selected > #options then self.selected = 1 end
    elseif key == "return" or key == "space" then
        local choice = options[self.selected]
        if choice == "next" then
            self.sm:switch("gameplay", self.level + 1)
        elseif choice == "replay" then
            self.sm:switch("gameplay", self.level)
        elseif choice == "menu" then
            self.sm:switch("menu")
        end
    end
end

return LevelComplete
