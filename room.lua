local room = {}
room.__index = room

function room.new(n,e,s,w,fi,fj)
    local r = {}
    setmetatable(r, room)

    -- holds the cells info    
    r.cells = {}
    r.walls = {n=n, e=e, w=w, s=s}
    r.doors = {}
    r.keys = {}
    r.index = {x=fi, y=fj}
    r.x = (fi-1) * config.room.width * config.room.cellSize
    r.y = (fj-1) * config.room.height * config.room.cellSize
    r.lights = {}

    -- init the cells
    for i = 1, config.room.width do
        r.cells[i] = {}
        for j = 1, config.room.height do
            -- make the border a 1
            if i == 1 or i == config.room.width or j == 1 or j == config.room.height then 
                r.cells[i][j] = 1
            else
                -- make the insides random
                if love.math.random(1,100) <= config.room.startFill then
                    r.cells[i][j] = 1
                else 
                    r.cells[i][j] = 0
                end
            end
        end
    end

    -- mark out each opening (remove columns/rows to ensure openings are open) 
    -- use this time to also assign lights if there is a wall, also doors... 

    if not(n) then
        for i = config.room.width/2-config.room.doorHalfSize, config.room.width/2+config.room.doorHalfSize do
            r.cells[i][1] = 0
            r.cells[i][2] = 0
        end
        -- -- two lights!
        -- local dx1 = r.x + (config.room.width-config.room.doorHalfSize)*config.room.cellSize/2 
        -- local dy1 = r.y
        -- table.insert(r.lights, dx, dy, "n")    
        -- -- adjust the size for the door
        -- r.lights[#r.lights].x = r.lights[#r.lights].x
    else
        if math.random() <= config.room.lightRate then
            local dx = r.x + config.room.width*config.room.cellSize/2
            local dy = r.y + config.room.cellSize
            table.insert(r.lights, light_class.new(2, dx, dy, "n"))
        end
    end
    if not(e) then
        for j = config.room.height/2-config.room.doorHalfSize, config.room.height/2+config.room.doorHalfSize do
            r.cells[config.room.width][j] = 0
            r.cells[config.room.width-1][j] = 0
        end
    else
        if math.random() <= config.room.lightRate then
            local dx = r.x + config.room.width*config.room.cellSize - config.room.cellSize
            local dy = r.y + config.room.width*config.room.cellSize/2
            table.insert(r.lights, light_class.new(2, dx, dy, "e"))           
        end
    end
    if not(s) then
        for i = config.room.width/2-config.room.doorHalfSize, config.room.width/2+config.room.doorHalfSize do
            r.cells[i][config.room.height] = 0
            r.cells[i][config.room.height-1] = 0
        end
    else
        if math.random() <= config.room.lightRate then
            local dx = r.x + config.room.width*config.room.cellSize/2
            local dy = r.y + config.room.width*config.room.cellSize + config.room.cellSize
            table.insert(r.lights, light_class.new(2, dx, dy, "s"))        
        end
    end
    if not(w) then
        for j = config.room.height/2-config.room.doorHalfSize, config.room.height/2+config.room.doorHalfSize do
            r.cells[1][j] = 0
            r.cells[2][j] = 0
        end
    else
        if math.random() <= config.room.lightRate then
            local dx = r.x + config.room.cellSize
            local dy = r.y + config.room.width*config.room.cellSize/2
            table.insert(r.lights, light_class.new(2, dx, dy, "w"))   
        end
    end

    return r
end

function room:pass()
    -- this takes the map.cells table and checks neighbors to see if the cell should stay the same or change
    -- going to only make the insides 
    local temp_map = self.cells

    i, j = 1
    for i = 2, config.room.width - 1 do
        for j = 2, config.room.height - 1 do
            --store the cells to check against
            local temp_cells = {
                self.cells[i-1][j-1],
                self.cells[i][j-1],
                self.cells[i+1][j-1],
                self.cells[i-1][j],
                self.cells[i+1][j],
                self.cells[i-1][j+1],
                self.cells[i][j+1],
                self.cells[i+1][j+1]
            }
            
            --how many walls exist around
            wallcounter = 0
            for k = 1, #temp_cells do
                if temp_cells[k] == 1 then wallcounter = wallcounter + 1 end
            end

            --now check
            if self.cells[i][j] == 1 then
                if 8-wallcounter >= config.room.deathRate then
                    temp_map[i][j] = 0
                end
            else
                if wallcounter >= config.room.birthRate then
                    temp_map[i][j] = 1
                end                
            end
        end
    end

    --pass is done, overwrite the map
    self.cells = temp_map
end

function room:update(dt)
    for i, v in ipairs(self.lights) do
        v:update(dt)
    end
end

-- bake the map into a texture
function room:bake(ix, jy)
    -- if not(self.walls.n) then
    --     -- left
    --     if math.random(1,100) <= config.room.doorClean then
    --         local x = config.room.width/2-config.room.doorHalfSize-1
    --         self.cells[x][1] = 0
    --     end 
    --     -- right
    --     if math.random(1,100) <= config.room.doorClean then
    --         local x = config.room.width/2+config.room.doorHalfSize+1
    --         self.cells[x][1] = 0
    --     end 
    -- end

    -- if not(self.walls.e) then
    --     -- left
    --     if math.random(1,100) <= config.room.doorClean then
    --         local y = config.room.height/2-config.room.doorHalfSize-1
    --         self.cells[config.room.width][y] = 0
    --     end 
    --     -- right
    --     if math.random(1,100) <= config.room.doorClean then
    --         local y = config.room.height/2-config.room.doorHalfSize+1
    --         self.cells[config.room.width][y] = 0
    --     end 
    -- end
    
    -- if not(self.walls.s) then
    --     -- left
    --     if math.random(1,100) <= config.room.doorClean then
    --         local x = config.room.width/2-config.room.doorHalfSize-1
    --         self.cells[x][config.room.height] = 0
    --     end 
    --     -- right
    --     if math.random(1,100) <= config.room.doorClean then
    --         local x = config.room.width/2+config.room.doorHalfSize+1
    --         self.cells[x][config.room.height] = 0
    --     end 
    -- end

    -- if not(self.walls.w) then
    --     -- left
    --     if math.random(1,100) <= config.room.doorClean then
    --         local y = config.room.height/2-config.room.doorHalfSize-1
    --         self.cells[1][y] = 0
    --     end 
    --     -- right
    --     if math.random(1,100) <= config.room.doorClean then
    --         local y = config.room.height/2-config.room.doorHalfSize+1
    --         self.cells[1][y] = 0
    --     end 
    -- end

    -- assign the indexes now...
    self.index.x = ix
    self.index.y = jy

    -- create the canvas
    self.texture = love.graphics.newCanvas(self:pixelwidth(), self:pixelheight())

    -- draw it
    -- love.graphics.setColor(0.25,0.25,0.25,1)

    local a = math.random(8)
    local b = math.random(8)

    love.graphics.setCanvas(self.texture)
    for i=1, config.room.width do
        for j=1, config.room.height do
            local c = 0
            if self.cells[i][j] == 1 then
                c = math.random(config.room.wallColourMin,config.room.wallColourMax) / 100
            else
                c = math.random(config.room.floorColourMin,config.room.floorColourMax) / 100
            end
            love.graphics.setColor(c,c,c,1)
            love.graphics.rectangle("fill", (i-1)*config.room.cellSize, (j-1)*config.room.cellSize, config.room.cellSize, config.room.cellSize)
            if self.cells[i][j] == 0 and math.random() <= config.room.levelRate then
                local m = love.math.noise(i/config.room.noiseDiv, j/config.room.noiseDiv, a/config.room.noiseDiv, b/config.room.noiseDiv)
                local l = math.floor(m * 10)
                
                for k, v in ipairs(config.room.levels) do
                    if l == v.level then
                        for m, o in ipairs(objects) do
                            if o.name == v.object then
                                local img = o.textures[math.random(#o.textures)]
                                love.graphics.setColor(1,1,1,1)
                                love.graphics.draw(img, (i-1)*config.room.cellSize, (j-1)*config.room.cellSize)
                            end
                        end
                    end
                end
            end
        end
    end
    love.graphics.setCanvas()
	love.graphics.setColor(1,1,1,1)

    -- calculate the x,y of the canvas for drawing later on
    self.x = (ix-1) * self.texture:getWidth()
    self.y = (jy-1) * self.texture:getHeight()

end

-- draws texture @ x, y
function room:draw()
    love.graphics.draw(self.texture, self.x, self.y)
    for i, v in ipairs(self.doors) do
        love.graphics.draw(v.texture, v.x, v.y)
    end
    for i, v in ipairs(self.keys) do
        -- love.graphics.setColor(v.colour)
        -- love.graphics.circle("fill", v.x, v.y, 32)
        -- love.graphics.setColor(1,1,1,1)
    end    
    for i, v in ipairs(self.lights) do
        v:draw()
    end
end

function room:pixelwidth()
    return config.room.width * config.room.cellSize
end

function room:pixelheight()
    return config.room.height * config.room.cellSize
end

function room:getIndex()
    return self.index.x, self.index.y
end

-- adds a door to the room: door index, texture, draw position
function room:addDoor(d)
    local dt = {
        door = d,
        x = 0,
        y = 0,
        texture = nil
    }

    local w, h = 0, 0

    -- figure out where/how to draw the door based on its position
    if dt.door.wall == "n" then
        w = config.room.cellSize * config.room.doorHalfSize*2 + config.room.cellSize
        h = config.room.cellSize
        dt.x = self.x + (config.room.width/2 - config.room.doorHalfSize) * config.room.cellSize - config.room.cellSize
        dt.y = self.y
    elseif dt.door.wall == "e" then
        w = config.room.cellSize
        h = config.room.cellSize * config.room.doorHalfSize*2 + config.room.cellSize
        dt.x = self.x + config.room.width * config.room.cellSize - config.room.cellSize
        dt.y = self.y + (config.room.height/2 - config.room.doorHalfSize) * config.room.cellSize - config.room.cellSize
    elseif dt.door.wall == "s" then
        w = config.room.cellSize * config.room.doorHalfSize*2 + config.room.cellSize
        h = config.room.cellSize
        dt.x = self.x + (config.room.width/2 - config.room.doorHalfSize) * config.room.cellSize - config.room.cellSize
        dt.y = self.y + config.room.height * config.room.cellSize - config.room.cellSize
    elseif dt.door.wall == "w" then
        w = config.room.cellSize
        h = config.room.cellSize * config.room.doorHalfSize*2 + config.room.cellSize
        dt.x = self.x
        dt.y = self.y + (config.room.height/2 - config.room.doorHalfSize) * config.room.cellSize - config.room.cellSize
    end

    dt.texture = love.graphics.newCanvas(w,h)

    love.graphics.setCanvas(dt.texture)

    -- colour the door using the door colour but also vary it a little
    local xw = w / config.room.cellSize
    local yh = h / config.room.cellSize 

    -- loop through the canvas and apply a variation of colours
    for i = 1, xw do
        for j = 1, yh do
            local c = math.random(config.room.doorColourMin, config.room.doorColourMax) / 100
            local dc = {
                dt.door.colour[1] + c,
                dt.door.colour[2] + c,
                dt.door.colour[3] + c,
                1
            }
            love.graphics.setColor(dc)
            love.graphics.rectangle("fill", (i-1) * config.room.cellSize, (j-1) * config.room.cellSize, config.room.cellSize, config.room.cellSize)
            love.graphics.setColor(1,1,1,1)
        end
    end


    love.graphics.setCanvas()

    table.insert(self.doors, dt)
end

-- adds an index to the list of key indexes
function room:addKey(k)
    table.insert(self.keys, k)
end

-- get cell from position
function room:isWall(x, y)
    -- normalize the x, y
    local rx = x - self.x
    local ry = y - self.y
    local w = config.room.width * config.room.cellSize
    local h = config.room.height * config.room.cellSize
    -- calculate!
    local px = math.floor(rx / config.room.cellSize) + 1
    local py = math.floor(ry / config.room.cellSize) + 1
    -- print(px .. "," .. py)
    if self.cells[px][py] == 1 then
        return true
    else
        return false
    end
end

-- checks if location is in a door
function room:isDoor(x, y)
    -- go through each room and see if it intersects
    for i, v in ipairs(self.doors) do
        -- in the canvas rect (world coords)
        if x >= v.x and x <= v.x + v.texture:getWidth() and y >= v.y and y <= v.y + v.texture:getHeight() then
            -- check to see if we have a key
            return true, i
        end
    end

    return false, 0
end

return room