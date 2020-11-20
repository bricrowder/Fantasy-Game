local bullet = {}
bullet.__index = bullet

function bullet.new(x, y, a, i)
    local b = {}
    setmetatable(b, bullet)

    b.x = x
    b.y = y
    b.angle = a
    b.speed = config.bullets[i].speed
    b.pattern = config.bullets[i].pattern
    b.textures = {}
    
    for i, v in ipairs(bullets) do
        if v.name == config.bullets[i].name then
            table.insert(b.textures, v.texture)
        end
    end
    b.animation = "flying"
    b.destroy = false
    return b
end

function bullet:update(dt)
    -- move
    if self.pattern == "linear" then
        self.x = self.x + self.speed * math.cos(self.angle) * dt
        self.y = self.y + self.speed * math.sin(self.angle) * dt
    end

    -- wall collision check
    local rx, ry = getRoom(x, y)
    local r = nil
    if rx and ry then
        r = rooms[rx][ry]

        -- get wall/door info            
        local iswall = r:isWall(x, y)
        local isdoor, di = r:isDoor(x, y)
        -- check if the future position would collide with a wall
        if iswall then
            local cx, cy, cw, ch = getCell(x, y)

            --adjust the values based on the side
            if self.x < cx then
                self.x = cx
            elseif self.x > cx+cw then
                self.x = cx+cw
            end
            if self.y < cy then
                self.y = cy
            elseif self.y > cy+ch then
                self.y = cy+ch
            end
        elseif isdoor then
            local d = r.doors[di]
            --adjust the values based on the side
            if self.x < d.x then
                self.x = d.x
            elseif self.x > d.x+d.texture:getWidth() then
                self.x = d.x+d.texture:getWidth()
            end
            if self.y < d.y then
                self.y = d.y
            elseif self.y > d.y+d.texture:getHeight() then
                self.y = d.y+d.texture:getHeight()
            end   
        else
            self.x = x
            self.y = y
        end
    else
        destroy = true
    end    
end

function bullet:draw()
    love.graphics.draw(self.texture, self.x, self.y, self.angle, 1, 1, self.texture:getWidth()/2, self.texture:getHeight()/2)
end

return bullet