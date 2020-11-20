local enemy = {}
enemy.__index = enemy

function enemy.new(index, r)
    local e = {}
    setmetatable(e, enemy)

    -- textures
    e.standing = love.graphics.newImage(config.enemies[index].textures.standing)
    e.walking = {}
    for i, v in ipairs(config.enemies[index].textures.walking) do
        table.insert(e.walking, love.graphics.newImage(v))
    end
    -- index in config
    e.index = index
    -- position, initialized to the centre of the room it is created in 
    e.x = r.x + config.room.width * config.room.cellSize / 2
    e.y = r.y + config.room.height * config.room.cellSize / 2
    
    -- angle, initialized to a random angle
    e.angle = math.random() * math.pi/2

    -- setup animation
    e.animation = "walking"

    -- frame tracker
    e.frametimer = 0
    e.frame = 1

    return e
end

function enemy:update(dt)
    -- update the movement
    if config.enemies[self.index].movement == "backandforth" then
        -- next pos
        local x = self.x + dt * config.enemies[self.index].speed * math.cos(self.angle)
        local y = self.y + dt * config.enemies[self.index].speed * math.sin(self.angle)

        -- get room where that new position is from 
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
                -- update the direction to opposite
                self.angle = self.angle + math.pi
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
                -- update the values to opposite
                self.angle = self.angle + math.pi
            else
                self.x = x
                self.y = y
            end
        end        
    end

    -- update the walking animation if necessary
    if self.animation == "walking" then
        self.frametimer = self.frametimer + dt
        if self.frametimer >= config.enemies[self.index].animation.walking then
            self.frametimer = self.frametimer - config.enemies[self.index].animation.walking
            self.frame = self.frame + 1
            if self.frame > #config.enemies[self.index].textures.walking then
                self.frame = 1
            end
        end
    end
end

function enemy:draw()
    -- determine image/frame then draw it
    local img = self.standing
    if self.animation == "walking" then
        img = self.walking[self.frame]
    end
    love.graphics.draw(img, self.x, self.y, self.angle, 1, 1, self.standing:getWidth()/2, self.standing:getHeight()/2)
end

return enemy