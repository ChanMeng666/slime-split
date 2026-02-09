local Utils = {}

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.distance(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Utils.clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function Utils.sign(x)
    if x > 0 then return 1
    elseif x < 0 then return -1
    else return 0 end
end

function Utils.round(x)
    return math.floor(x + 0.5)
end

return Utils
