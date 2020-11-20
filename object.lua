local object = {}
object.__index = object

function object.new(ix, iy, colour, texture)
    local o = {}
    setmetatable(o, object)

    o.x = x * config.overworld.cellSize
    o.y = y * config.overworld.cellSize

    return o
end

return object