local light = {}
light.__index = light

function light.new(name, x, y, a)
    local l = {}
    setmetatable(l, light)

    -- initialize
    l.index = 1
    l.texture = nil

    -- assign for easy referencing later
    for i, v in ipairs(lights) do
        if v.name == name then
            l.index = i
            l.texture = v.texture
        end
    end

    -- initialize
    l.x = x
    l.y = y
    l.angle = a

    return l
end

function light:update(dt)

end

function light:draw()
    if self.texture then
        love.graphics.setColor(config.lights[self.index].colour)
        love.graphics.draw(self.texture, self.x, self.y, self.angle, 1, 1, config.lights[self.index].offset.x * self.texture:getWidth(), config.lights[self.index].offset.y * self.texture:getHeight())
        love.graphics.setColor(1,1,1,1)
    end
end

return light