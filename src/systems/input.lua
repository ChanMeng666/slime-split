local Input = {}

function Input.isLeft()
    return love.keyboard.isDown("left") or love.keyboard.isDown("a")
end

function Input.isRight()
    return love.keyboard.isDown("right") or love.keyboard.isDown("d")
end

function Input.isUp()
    return love.keyboard.isDown("up") or love.keyboard.isDown("w")
end

return Input
