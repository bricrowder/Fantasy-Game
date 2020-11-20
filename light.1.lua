local light = {}
light.__index = light

function light.new(index, x, y, w)
    local l = {}
    setmetatable(l, light)

    l.texture = love.graphics.newImage(config.lights[index].texture)
    l.index = index

    l.x = x
    l.y = y

    if w == "n" then
        l.angle = math.pi/2        
    elseif w == "e" then
        l.angle = math.pi
    elseif w == "s" then
        l.angle = math.pi*3/2
    elseif w == "w" then
        l.angle = 0
    end
    l.alpha = math.random(config.room.lightPulseMin*100,100)/100
    l.dir = -1
    l.flickercount = 0

    return l
end

function light:update(dt)
    -- update pulse
    self.alpha = self.alpha + dt * self.dir * config.lights[self.index].pulse
    if self.alpha <= config.room.lightPulseMin then
        self.alpha = config.room.lightPulseMin
        self.dir = -self.dir
    elseif self.alpha > 1 then
        self.alpha = 1
        self.dir = -self.dir
    end

    -- update flicker
    if self.flickercount == 0 then
        if math.random() <= config.lights[self.index].flicker then
            self.flickercount = math.random(1,4) * 0.25
        end
    else
        self.flickercount = self.flickercount - dt
        if self.flickercount <= 0 then
            self.flickercount = 0
        end
    end
end

function light:draw()
    local a = self.alpha
    if not(self.flickercount == 0) then
        a = 0
    end
    local ox = self.texture:getWidth() * config.lights[self.index].offset.x
    local oy = self.texture:getHeight() * config.lights[self.index].offset.y
    love.graphics.setColor(1,1,1,a)
    love.graphics.draw(self.texture, self.x, self.y, self.angle, 1, 1, ox, oy)
    love.graphics.setColor(1,1,1,1)
end

return light