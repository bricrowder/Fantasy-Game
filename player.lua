local player = {}
player.__index = player

function player.new()
    local p = {}
    setmetatable(p, player)

    -- starting position - just centre of first room
    p.x = config.room.width/2 * config.room.cellSize
    p.y = config.room.height/2 * config.room.cellSize
    -- current angle
    p.angle = 0
    -- table of keys that the player has
    p.keys = {}

    -- collision radius for walls
    p.wallRad = 16
    -- collision radius for objects
    p.objectRad = 32
    -- collision radius for enemies/bullet
    p.enemyRad = 16

    -- load player textures
    p.standing = love.graphics.newImage(config.player.textures.standing)
    p.walking = {}
    for i, v in ipairs(config.player.textures.walking) do
        table.insert(p.walking, love.graphics.newImage(v))
    end

    -- setup animation
    p.animation = "standing"

    -- frame tracker
    p.frametimer = 0
    p.frame = 1

    -- bullets and stuff
    p.bullets = {}
    p.bullettimer = 0

    p.light = light_class.new(config.player.light, p.x, p.y, p.angle)

    return p
end

function player:update(dt, move, angle, mangle)
    -- update the angle
    self.angle = self.angle + angle

    -- move the player
    if move then
        if not(self.animation == "walking") then
            self:setAnimation("walking")
        end

        -- next pos
        local x = self.x + dt * config.player.speed * math.cos(self.angle + mangle)
        local y = self.y + dt * config.player.speed * math.sin(self.angle + mangle)

        -- make sure we are in bounds
        local ow, oh = overworld:getDimensions()
        if x <= 0 then
            self.x = 0
        elseif x > ow then
            self.x = ow
        end
        if y <= 0 then
            self.y = 0
        elseif y > oh then
            self.y = oh
        end

        -- see if the player is colliding with anything
        if x >=0 and x <= ow and y >= 0 and y <= oh then
            local collide, cell = overworld:isCollide(overworld:getCell(x,y))

            if collide then
                -- see where we are colliding
                if self.x < cell.x1 then
                    self.x = cell.x1
                elseif self.x > cell.x2 then
                    self.x = cell.x2
                end
                if self.y < cell.y1 then
                    self.y = cell.y1
                elseif self.y > cell.y2 then
                    self.y = cell.y2
                end
            else
                self.x = x
                self.y = y
            end
        end
    end

    -- update the player light
    self.light.x = self.x
    self.light.y = self.y
    self.light.angle = self.angle - math.pi/2

    -- update the walking animation if necessary
    if self.animation == "walking" then
        self.frametimer = self.frametimer + dt
        if self.frametimer >= config.player.animation.walking then
            self.frametimer = self.frametimer - config.player.animation.walking
            self.frame = self.frame + 1
            if self.frame > #config.player.textures.walking then
                self.frame = 1
            end
        end
    end
end

function player:draw()
    -- determine imag/framee then drawing it
    local img = self.standing
    if self.animation == "walking" then
        img = self.walking[self.frame]
    end
    love.graphics.draw(img, self.x, self.y, self.angle - math.pi/2, 1, 1, self.standing:getWidth()/2, self.standing:getHeight()/2)
end

function player:drawLights()
    self.light:draw()
end

function player:shoot()
    if self.bullettimer == 0 then
        self.bullettimer = config.player.fireRate
        table.insert(self.x, self.y, self.angle, 1)
    end
end

function player:setAnimation(a)
    self.animation = a
    self.frame = 1
    self.frametimer = 0
end

return player
