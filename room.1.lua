local room = {}
room.__index = room

function room.new()
    local r = {}
    setmetatable(r, room)

    -- create tiles table
    r.tiles = {}
    r.tiles2 = {}
    -- redeeisgn the levels...  


    r.img = love.graphics.newImage("assets/grass.png")
    r.img1 = love.graphics.newImage("assets/grass1.png")
    r.img2 = love.graphics.newImage("assets/grass2.png")

    -- this is the hieght unit
    
    r.height = 16
    r.width = 32

    -- this is just temp stuff to figure it out
    for i=1, 8, 1 do
        r.tiles[i] = {}
        r.tiles2[i] = {}
        for j=1, 8, 1 do
            if j == 1  or j == 8 or i == 1 or i == 8 then
                r.tiles[i][j] = {
                    texture = r.img2,
                    height = (r.img2:getHeight() - 32) / r.height       -- this is how you auto-calc the height
                }
                r.tiles2[i][j] = {
                    texture = r.img2,
                    height = 2
                }
            else
                r.tiles[i][j] = {
                    texture = r.img1,
                    height = 0
                }
                r.tiles2[i][j] = {
                    texture = nil,
                    height = 0
                }
            end
        end
    end

    -- we should also auto-calc the height 

    -- set a couple up... 
    r.tiles[4][4].height = 2
    r.tiles[4][4].texture = r.img2
    r.tiles[5][4].height = 1
    r.tiles[5][4].texture = r.img1
    r.tiles[4][5].height = 1
    r.tiles[4][5].texture = r.img1



    -- ambient colour
    -- objects (eg. block that you can move)
    -- tiles
        -- background tiles texture
        -- collider - true/false
        -- door
        -- light
        -- action
            -- switch
            -- pressure plate
            -- 
    return r
end

function room:draw()
    -- determine the drawing order of the player relative to the blocks around it
    local px, py = player:getCell()
    local pflags = {x=px, y=py}

    -- need to really figure out depth sorting as it applies to everything, should be based on movement of stuff - player, enemies, etc. -> maybe that can be done in that objects respective update insetad of the room draw 

    -- this is also causing the semi-transparent thing to work wierd... 
    -- do it in this order because of how the drawing loops are run
    -- x, y+1
    if py < 8 and self.tiles[px][py].height == self.tiles[px][py+1].height then
        pflags.x = px
        pflags.y = py+1
    end
    -- x+1, y
    if px < 8 and self.tiles[px][py].height == self.tiles[px+1][py].height then
        pflags.x = px+1
        pflags.y = py
    end
    -- x+1, y+1
    if px < 8 and py < 8 and self.tiles[px][py].height == self.tiles[px+1][py+1].height then
        pflags.x = px+1
        pflags.y = py+1
    end

    -- draw the room tiles as well as the various other things like player, enemies, etc.
    for i=1, 8, 1 do
        for j=1, 8, 1 do
            -- calc iso x/y
            local cx = i-1
            local cy = j-1
            local ix = (cx - cy) * self.width
            local iy = (cx + cy) * self.height
            local iy2 = (cx + cy) * self.height - self.height * self.tiles2[i][j].height*2
            -- adjust y height
            local yo = self.height * self.tiles[i][j].height 
            iy = iy - yo

            -- reset colour
            love.graphics.setColor(1,1,1,1)
            
            -- this is tile based, could this be more exact?

            -- this should be based on tile heights, not just +1-1, etc... which assumes a 1 or 2 height - do I just max it out at 4 or something??
            -- this should use the tile levels... 

            -- checks if px+1, py would block
            if i <= 8 and px+1 == i and py == j and self.tiles[i][j].height > self.tiles[px][j].height then
                love.graphics.setColor(1,1,1,0.25)
            end
            -- -- checks if px-1, py+1 would block - may not need this one
            -- if i > 1 and px-1 == i and j <= 8 and py+1 == j and self.tiles[i][j].height > self.tiles[px][py].height then
            --     love.graphics.setColor(1,1,1,0.5)
            -- end
            -- checks if px, py+1 would block
            if px == i and j <= 8 and py+1 == j and self.tiles[i][j].height > self.tiles[px][py].height then
                love.graphics.setColor(1,1,1,0.25)
            end
            -- checks if px+1, py+1 would block
            if i <= 8 and px+1 == i and j <= 8 and py+1 == j and self.tiles[i][j].height > self.tiles[px][py].height then
                love.graphics.setColor(1,1,1,0.25)
            end

            -- draw room tile
            if self.tiles[i][j].texture then
                love.graphics.draw(self.tiles[i][j].texture, ix, iy)
            end
            if self.tiles2[i][j].texture then
                love.graphics.draw(self.tiles2[i][j].texture, ix, iy2)
            end


            -- reset colour
            --love.graphics.setColor(1,1,1,1)
            -- draw player (if they are on the tile)
            if i == pflags.x and j == pflags.y then
                player:draw(yo)
            end

            -- draw other stuff (if they are on the tile)

        end
    end

end

return room