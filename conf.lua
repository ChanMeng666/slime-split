function love.conf(t)
    t.identity = "slime-split"
    t.title = "Slime Split"
    t.version = "11.4"
    t.window.width = 640
    t.window.height = 480
    t.window.resizable = false
    t.window.vsync = 1

    t.modules.physics = true
    t.modules.audio = true
    t.modules.sound = true
end
