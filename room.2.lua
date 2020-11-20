local room = {}
room.__index = room

function room.new()
    local r = {}
    setmetatable(r, room)

    r.width = 4
    r.height = 4

    r.walls = {
        {1,2,2,2,2,3},
        {4,0,0,0,0,5},
        {4,0,0,0,0,5},
        {4,0,0,0,0,5},
        {6,7,7,7,7,8}
    }
    r.floors = {
        {9,10,10,11},
        {12,13,13,14},
        {12,13,13,14},
        {15,16,16,17}
    }
 
    -- player/enemies can only move on floors
    -- only need to collision check against the walls from 2 to w-1
    -- check to see if there are any walls in from of player
    -- max width = 28 cells
    -- max height = 14 cells

    return r
end

function room:draw()
    for i = 1, self.width do
        for j = 1, self.height do
            local w, h = tile[self.floors[j][i]]:getDimensions()
            love.graphics.draw(tile[self.floors[j][i]], i*w, j*h)
        end
    end
    for i = 1, self.width+2 do
        for j = 1, self.height+1 do
            if self.walls[j][i] > 0 then
                local w, h = tile[self.walls[j][i]]:getDimensions()
                love.graphics.draw(tile[self.walls[j][i]], (i-1)*w, (j-1)*h)
            end
        end
    end
end

return room