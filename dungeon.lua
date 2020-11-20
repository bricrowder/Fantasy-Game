local dungeon = {}
dungeon.__index = dungeon

function dungeon.new(w, h)
    local f = {}
    setmetatable(f, dungeon)

	-- start and end position of the maze/dungeon
	f.width = w
	f.height = h
	f.startx = 1
    f.starty = 1
    f.endx = f.width
    f.endy = f.height

	-- ?
	f.randomkey = false

    ----------------------------
    -- GENERATE THE dungeon -- 
    ----------------------------

    -- init the table
    f.dungeon = {}

    -- loop counters
    local i, j

    -- loop through the dungeon and setup the initial values
    for i=1, f.width, 1 do
        f.dungeon[i] = {}
        for j=1, f.height, 1 do
            -- setup initial values for each cell
            f.dungeon[i][j] = {
                visited = false,
                w = true,
                s = true,
                e = true,
                n = true
			}
			
            -- test and set borders
            if i == 1 then f.dungeon[i][j].wb = true end
            if i == f.width then f.dungeon[i][j].eb = true end
            if j == 1 then f.dungeon[i][j].nb = true end
            if j == f.height then f.dungeon[i][j].sb = true end
        end
    end

    -- init and setup setup cell table with a random cells
    local cells = {}
    table.insert(cells, {x=math.random(1, f.width), y=math.random(1, f.height)})
    f.dungeon[cells[1].x][cells[1].y].visited = true
    -- loop until there are no move cells in the stack
    while #cells > 0 do
        -- get a list of valid (unvisited and within bounds) surrounding cells
        local validcells = {}
        -- create locals to make it easier to type...
        local x = cells[#cells].x
        local y = cells[#cells].y
        
        -- check left, right, up & down
        if x > 1 and not(f.dungeon[x-1][y].visited) then table.insert(validcells, {x=x-1, y=y}) end
        if x < f.width and not(f.dungeon[x+1][y].visited) then table.insert(validcells, {x=x+1, y=y}) end
        if y > 1 and not(f.dungeon[x][y-1].visited) then table.insert(validcells, {x=x, y=y-1}) end
        if y < f.height and not(f.dungeon[x][y+1].visited) then table.insert(validcells, {x=x, y=y+1}) end

        -- if there are valid, continue to process; if there are NO valid, pop off the stack
        if #validcells > 0 then
            -- randomly pick a valid cell
            local nextcell = validcells[math.random(1, #validcells)]
            -- print(x .. "," .. y .. " -> " .. nextcell.x .. "," .. nextcell.y)
            -- mark it as visited
            f.dungeon[nextcell.x][nextcell.y].visited = true            
            -- remove walls between them, determine direction between cells
            if x > nextcell.x then
                -- print("<-")
                f.dungeon[x][y].w = false
                f.dungeon[nextcell.x][nextcell.y].e = false
            elseif x < nextcell.x then
                -- print("->")
                f.dungeon[x][y].e = false
                f.dungeon[nextcell.x][nextcell.y].w = false
            elseif y > nextcell.y then
                -- print("up")
                f.dungeon[x][y].n = false
                f.dungeon[nextcell.x][nextcell.y].s = false
            elseif y < nextcell.y then
                -- print("down")
                f.dungeon[x][y].s = false
                f.dungeon[nextcell.x][nextcell.y].n = false            
            end
            -- add it to the cells stack
            table.insert(cells, {x=nextcell.x, y=nextcell.y})
        else
            -- pop the current cell off the stack
            table.remove(cells)
        end
    end

    -----------------------------------------------------
    -- FIND PATHS - CORRECT (START->END) and DEAD ENDS --
    -----------------------------------------------------

    --------------------------
    -- PLACE DOORS AND KEYS --
    --------------------------

    -- done in seperate function after the object is created

    return f
end

function dungeon:getpaths()
    -- init the washere table - used in the path finding
    self.washere = {}
    for i = 1, self.height do
        self.washere[i] = {}		
        for j = 1, self.width do
            self.washere[i][j] = false
        end
    end

    -- CORRECT PATH
    self.correctpath = {}
    self:findCorrectPath(self.startx, self.starty)
    -- print(#self.correctpath)
    -- reverse the order
	local cp = {}
	for i = 1, #self.correctpath do
		cp[#self.correctpath-i+1] = self.correctpath[i]
	end
	self.correctpath = cp


    -- DEADEND PATHS
    self.deadends = {}
    self:findDeadends()

    self.deadendpaths = {}
    
    for d = 1, #self.deadends, 1 do
        -- re-init the washere table
        self.washere = {}
        for i = 1, self.height do
            self.washere[i] = {}		
            for j = 1, self.width do
                self.washere[i][j] = false
            end
        end

        -- get the path
        self.deadendpaths[d] = {}
        self:findDeadendPaths(self.deadends[d].x, self.deadends[d].y)
    end
end

function dungeon:findDeadends()
    local i, j
    -- find cells that have 3 walls
	for i = 1, self.width do
		for j = 1, self.height do
			local wallcount = 0
            if self.dungeon[i][j].n then wallcount = wallcount + 1 end
            if self.dungeon[i][j].s then wallcount = wallcount + 1 end
            if self.dungeon[i][j].e then wallcount = wallcount + 1 end
            if self.dungeon[i][j].w then wallcount = wallcount + 1 end			
            if wallcount == 3 then 
				local dt = {x = i, y = j}
				table.insert(self.deadends, dt)
			end
		end
	end
end

function dungeon:findCorrectPath(x, y)
	-- if we are at the end return true
	if x == self.endx and y == self.endy then
        local cell = {x = x, y = y, i = 0}
        -- also check for intersection (1 or 0 walls)
        local wallcount = 0
        if self.dungeon[x][y].n then wallcount = wallcount + 1 end
        if self.dungeon[x][y].s then wallcount = wallcount + 1 end
        if self.dungeon[x][y].e then wallcount = wallcount + 1 end
        if self.dungeon[x][y].w then wallcount = wallcount + 1 end
        if wallcount < 2 then cell.i = 1 end
		table.insert(self.correctpath, cell)
		return true
	end

	-- if we have already been here then return false
	if self.washere[x][y] then return false end

	-- flag that we have been here
	self.washere[x][y] = true

	-- now recursively go through the maze
	-- check left
	if not(self.dungeon[x][y].w) and self:findCorrectPath(x-1, y) then
        local cell = {x = x, y = y, i = 0}
        -- also check for intersection... 
        local wallcount = 0
        if self.dungeon[x][y].n then wallcount = wallcount + 1 end
        if self.dungeon[x][y].s then wallcount = wallcount + 1 end
        if self.dungeon[x][y].e then wallcount = wallcount + 1 end
        if self.dungeon[x][y].w then wallcount = wallcount + 1 end
        if wallcount < 2 then cell.i = true end        
		table.insert(self.correctpath, cell)
		return true
	end

	-- check right
	if not(self.dungeon[x][y].e) and self:findCorrectPath(x+1, y) then
		local cell = {x = x, y = y, i = 0}
        local wallcount = 0
        if self.dungeon[x][y].n then wallcount = wallcount + 1 end
        if self.dungeon[x][y].s then wallcount = wallcount + 1 end
        if self.dungeon[x][y].e then wallcount = wallcount + 1 end
        if self.dungeon[x][y].w then wallcount = wallcount + 1 end
        if wallcount < 2 then cell.i = true end
		table.insert(self.correctpath, cell)		
		return true
	end

	-- check up
	if not(self.dungeon[x][y].n) and self:findCorrectPath(x, y-1) then
		local cell = {x = x, y = y, i = 0}
        local wallcount = 0
        if self.dungeon[x][y].n then wallcount = wallcount + 1 end
        if self.dungeon[x][y].s then wallcount = wallcount + 1 end
        if self.dungeon[x][y].e then wallcount = wallcount + 1 end
        if self.dungeon[x][y].w then wallcount = wallcount + 1 end
        if wallcount < 2 then cell.i = true end
		table.insert(self.correctpath, cell)
		return true
	end

	-- check down
	if not(self.dungeon[x][y].s) and self:findCorrectPath(x, y+1) then
		local cell = {x = x, y = y, i = 0}
        local wallcount = 0
        if self.dungeon[x][y].n then wallcount = wallcount + 1 end
        if self.dungeon[x][y].s then wallcount = wallcount + 1 end
        if self.dungeon[x][y].e then wallcount = wallcount + 1 end
        if self.dungeon[x][y].w then wallcount = wallcount + 1 end
        if wallcount < 2 then cell.i = true end
		table.insert(self.correctpath, cell)
		return true
	end

	return false
end

function dungeon:findDeadendPaths(x, y)
	-- if we are at the end return true
	-- loop through the correct path intersecitons to see if there is a match
	local i
	for i = 1, #self.correctpath do
		if x == self.correctpath[i].x and y == self.correctpath[i].y then
			local dt = {x = x, y = y}
			table.insert(self.deadendpaths[#self.deadendpaths], dt)
			return true
		end
	end
	-- if we have already been here then return false
	if self.washere[x][y] then return false end

	-- flag that we have been here
	self.washere[x][y] = true

	-- now recursively go through the maze
	-- check left
	if not(self.dungeon[x][y].w) and self:findDeadendPaths(x-1, y) then
        local dt = {x = x, y = y}
        table.insert(self.deadendpaths[#self.deadendpaths], dt)
        return true
	end

	-- check right
	if not(self.dungeon[x][y].e) and self:findDeadendPaths(x+1, y) then
        local dt = {x = x, y = y}
        table.insert(self.deadendpaths[#self.deadendpaths], dt)
        return true
	end

	-- check up
	if not(self.dungeon[x][y].n) and self:findDeadendPaths(x, y-1) then
        local dt = {x = x, y = y}
        table.insert(self.deadendpaths[#self.deadendpaths], dt)
        return true
	end

	-- check down
	if not(self.dungeon[x][y].s) and self:findDeadendPaths(x, y+1) then
        local dt = {x = x, y = y}
        table.insert(self.deadendpaths[#self.deadendpaths], dt)
        return true
	end

	return false
end

function dungeon:setDoorsandKeys()
    -- init the door and keys!
    self.doors = {}
    self.keys = {}

	local okdoor = false

	-- find the first intersection
	self.firstintersection = 0
	local f
	for f = 1, #self.correctpath do
		if self.correctpath[f].i then
			self.firstintersection = f
			break
		end
	end

	-- put in some doors!
	for i = 1, config.dungeon.doors do
		okdoor = false
		while okdoor == false do
			-- randomly select an index (excluding first and last position)
			local selectedindex = love.math.random(2, #self.correctpath-1)
			local invaliddoor = false
			-- now see if this is a valid index to select based on space between doors
			for j = 1, #self.doors do
				if self.doors[j].i >= selectedindex then
					if self.doors[j].i - selectedindex <= config.dungeon.doorSpacing then invaliddoor = true end
				else
					if selectedindex - self.doors[j].i <= config.dungeon.doorSpacing then invaliddoor = true end
				end
			end
			if selectedindex >= self.firstintersection and invaliddoor == false then
				-- mark the door location
				okdoor = true
				self.doors[i] = {x = self.correctpath[selectedindex].x, y = self.correctpath[selectedindex].y, i = selectedindex}
				-- figure out which wall it should be by looking at direction of next correctpath cell
				if self.correctpath[selectedindex].x < self.correctpath[selectedindex+1].x then
					-- right door
					self.doors[i].wall = "e"
				elseif self.correctpath[selectedindex].x > self.correctpath[selectedindex+1].x then
					self.doors[i].wall = "w"
				elseif self.correctpath[selectedindex].y < self.correctpath[selectedindex+1].y then
					self.doors[i].wall = "s"
				elseif self.correctpath[selectedindex].y > self.correctpath[selectedindex+1].y then
					self.doors[i].wall = "n"
				end


				-- put keys in the mix

				-- Enumerate all of the deadendpaths associated with the intersections
				local founddeadendpaths = {}
				for k = 1, selectedindex do
					if self.correctpath[k].i then
						for l = 1, #self.deadendpaths do
							if self.deadendpaths[l][1].x == self.correctpath[k].x and self.deadendpaths[l][1].y == self.correctpath[k].y then
								table.insert(founddeadendpaths, l)
							end
						end
					end
                end
                -- print(#founddeadendpaths)
				-- Prioritize paths without keys
				local validdeadendpaths = {}
				for k = 1, #founddeadendpaths do
					local valid = true
					for l = 1, #self.keys do
						if self.keys[l].i == founddeadendpaths[k] then valid = false end
					end
					if valid == true then table.insert(validdeadendpaths, founddeadendpaths[k]) end
				end
				-- Randomly select from either the correctpath, prioritized or full list of deadendpaths
				if #founddeadendpaths > 0 then
					local dp
					local keyindex
					if #validdeadendpaths > 0 then
						dp = validdeadendpaths[love.math.random(1, #validdeadendpaths)]
					else
						dp = founddeadendpaths[love.math.random(1, #founddeadendpaths)]
					end
					if self.randomkey == true then
						keyindex = love.math.random(2,#self.deadendpaths[dp])
					else
						keyindex = #self.deadendpaths[dp]
					end					
					self.keys[i] = {x = self.deadendpaths[dp][keyindex].x, y = self.deadendpaths[dp][keyindex].y, i = dp}
				else
					-- randomly pick a spot on the correct path
					local keyindex = love.math.random(1,selectedindex)
					self.keys[i] = {x = self.correctpath[keyindex].x, y = self.correctpath[keyindex].y, i = 0}
				end
			end
		end
	end    

	-- assign some colours!
	for i=1, #self.doors do
		if i == 1 then 
			self.doors[i].colour = {1,0,0,1}
			self.keys[i].colour = {1,0,0,1}
		elseif i == 2 then
			self.doors[i].colour = {0,1,0,1}
			self.keys[i].colour = {0,1,0,1}
		elseif i == 3 then
			self.doors[i].colour = {0,0,1,1}
			self.keys[i].colour = {0,0,1,1}
		elseif i == 4 then
			self.doors[i].colour = {1,0,1,1}			
			self.keys[i].colour = {1,0,1,1}			
		elseif i == 5 then
			self.doors[i].colour = {0,1,1,1}		
			self.keys[i].colour = {0,1,1,1}		
		elseif i == 6 then
			self.doors[i].colour = {1,1,0,1}		
			self.keys[i].colour = {1,1,0,1}		
		end			
	end
end

function dungeon:bake()
	-- bake the dungeon into a texture for easier drawing
	-- bake the minimap of the dungeon
	local w = self.width * config.dungeon.cellSize
	local h = self.height * config.dungeon.cellSize
	self.minimap = love.graphics.newCanvas(w, h)
	love.graphics.setCanvas(self.minimap)
	self:drawLayout()
	love.graphics.setCanvas()
end

function dungeon:setCells()
-- also redo the room class???? 
    -- make it one big table, like the overworld
    -- create the rooms by setting/erasing walls, etc
        -- 1: init random
        -- 2: erase walls/doors
        -- 3: set walls
        -- 4: outer border! 
        -- 5: cellular automata!

	-- init the cells
	self.cells = {}
	for i=1, self.width * config.room.width do
		self.cells[i] = {}
		for j=1, self.height * config.room.height do
			if love.math.random(1,100) <= config.room.startFill then
				self.cells[i][j] = 1
			else 
				self.cells[i][j] = 0
			end
		end
	end

	-- set walls
	for i=1, self.width do
		for j=1, self.height do
			if self.dungeon[i][j].n then
				-- world pos
				local x = (i-1) * config.room.width
				local y = (j-1) * config.room.height + 1
				for k=1, config.room.width do
					self.cells[x+k][y] = 1
				end
			end
			if self.dungeon[i][j].e then
				-- world pos
				local x = (i-1) * config.room.width + config.room.width
				local y = (j-1) * config.room.height
				for k=1, config.room.height do
					self.cells[x][y+k] = 1
				end	
			end
			if self.dungeon[i][j].s then
				-- world pos
				local x = (i-1) * config.room.width
				local y = (j-1) * config.room.height + config.room.height
				for k=1, config.room.width do
					self.cells[x+k][y] = 1
				end
			end
			if self.dungeon[i][j].w then
				-- world pos
				local x = (i-1) * config.room.width + 1
				local y = (j-1) * config.room.height
				for k=1, config.room.height do
					self.cells[x][y+k] = 1
				end				
			end
		end
	end

	-- set border
	for i=1, #self.cells do
		self.cells[i][1] = 1
		self.cells[i][#self.cells[i]] = 1
	end

	for i=1, #self.cells[1] do
		self.cells[1][i] = 1
		self.cells[#self.cells][i] = 1
	end

	-- cellular automata!!

    -- this takes the map.cells table and checks neighbors to see if the cell should stay the same or change
	-- going to only make the insides 
	for p=1, config.room.passes do
		local temp_map = self.cells

		for i = 2, #self.cells - 1 do
			for j = 2, #self.cells[i] - 1 do
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
				local wallcounter = 0
				for k = 1, #temp_cells do
					if temp_cells[k] == 1 then 
						wallcounter = wallcounter + 1
					end
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

	-- bake it to a texture
	-- select a colour scheme
	local c = math.random(#config.room.colours)
	local c2 = {}
	self.texture = love.graphics.newCanvas(self.width * config.room.width, self.width * config.room.height)
	love.graphics.setCanvas(self.texture)
	
	for i=1, #self.cells do
		for j=1, #self.cells[i] do
			if self.cells[i][j] == 1 then
				if config.room.colours[c].wallConst then
					local r = math.random(-1,1) * config.room.colours[c].wallVar[1]
					c2 = {
						config.room.colours[c].wall[1] + r,
						config.room.colours[c].wall[2] + r,
						config.room.colours[c].wall[3] + r,
						config.room.colours[c].wall[4] + math.random(-1,1) * config.room.colours[c].wallVar[4]
					}					
				else
					c2 = {
						config.room.colours[c].wall[1] + math.random(-1,1) * config.room.colours[c].wallVar[1],
						config.room.colours[c].wall[2] + math.random(-1,1) * config.room.colours[c].wallVar[2],
						config.room.colours[c].wall[3] + math.random(-1,1) * config.room.colours[c].wallVar[3],
						config.room.colours[c].wall[4] + math.random(-1,1) * config.room.colours[c].wallVar[4]
					}
				end
			else
				if config.room.colours[c].floorConst then
					local r = math.random(-1,1) * config.room.colours[c].floorVar[1]
					c2 = {
						config.room.colours[c].wall[1] + r,
						config.room.colours[c].wall[2] + r,
						config.room.colours[c].wall[3] + r,
						config.room.colours[c].wall[4] + math.random(-1,1) * config.room.colours[c].wallVar[4]
					}	
				else				
					c2 = {
						config.room.colours[c].floor[1] + math.random(-1,1) * config.room.colours[c].floorVar[1],
						config.room.colours[c].floor[2] + math.random(-1,1) * config.room.colours[c].floorVar[2],
						config.room.colours[c].floor[3] + math.random(-1,1) * config.room.colours[c].floorVar[3],
						config.room.colours[c].floor[4] + math.random(-1,1) * config.room.colours[c].floorVar[4]
					}
				end
			end
			love.graphics.setColor(c2)
			love.graphics.rectangle("fill", i-1, j-1, 1, 1)
		end
	end

	love.graphics.setCanvas()
	love.graphics.setColor(1,1,1,1)

	self.ambient = config.room.colours[c].ambient

	self.lights = {}

	-- setup lights
	for i=1, #self.cells do
		for j=1, #self.cells[i] do
			if self.cells[i][j] == 1 and math.random() <= config.dungeon.lightRate then
				local l = math.random(#config.dungeon.lights)
				table.insert(self.lights, light_class.new(config.dungeon.lights[l], (i-1)*config.room.cellSize, (j-1)*config.room.cellSize, 0))
			end
		end
	end

	print("lights: " .. #self.lights)
	-- for i=1, self.width do
	-- 	self.rooms[i] = {}
	-- 	for j=1, self.height do
	-- 		-- create
	-- 		local fp = self.dungeon[i][j]
	-- 		self.rooms[i][j] = room_class.new(fp.n, fp.e, fp.s, fp.w, i, j)
	-- 		-- cellular automata!!
	-- 		for p=1, config.room.passes do
	-- 			self.rooms[i][j]:pass()
	-- 		end
	-- 		-- bake to texture
	-- 		self.rooms[i][j]:bake(i, j)
	-- 		-- assign any doors to the room
	-- 		for k, v in ipairs(self.doors) do
	-- 			-- this room has a door - pass the table ref.
	-- 			if v.x == i and v.y == j then
	-- 				self.rooms[i][j]:addDoor(v)
	-- 			end
	-- 		end
	-- 		-- assign any keys to the room
	-- 		for k, v in ipairs(self.keys) do
	-- 			-- this room has a key
	-- 			if v.x == i and v.y == j then
	-- 				self.rooms[i][j]:addKey(v)
	-- 			end
	-- 		end
	-- 	end
	-- end
end

function dungeon:update(dt)
	-- self.light:update(dt)
end

function dungeon:draw()
	-- love.graphics.setColor(self.ambient)
	love.graphics.draw(self.texture, 0, 0, 0, config.room.cellSize, config.room.cellSize)
	-- love.graphics.setColor(1,1,1,1)
end

function dungeon:drawLights()
	-- self.light:draw()
	for i, v in ipairs(self.lights) do
		v:draw()
	end
end

function dungeon:drawLayout()
	-- pull the config data for easier drawing...
	local cellScale = config.dungeon.cellSize


	--loop through the dungeon table
	local i, j
	for i = 1, self.width do
		for j = 1, self.height do
			love.graphics.setColor(1,1,1,1)
			--draw walls based on scale and cell position
			--draw north wall			
			if self.dungeon[i][j].n then
				love.graphics.line((i-1)*cellScale, (j-1)*cellScale, i*cellScale, (j-1)*cellScale)
			end
			--draw south wall
			if self.dungeon[i][j].s then
				love.graphics.line((i-1)*cellScale, j*cellScale, i*cellScale, j*cellScale)
			end
			--draw west wall
			if self.dungeon[i][j].w then
				love.graphics.line((i-1)*cellScale, (j-1)*cellScale, (i-1)*cellScale, j*cellScale)
			end
			--draw east wall
			if self.dungeon[i][j].e then
				love.graphics.line(i*cellScale, (j-1)*cellScale, i*cellScale, j*cellScale)
			end
		end
    end 
    
	-- draw dead end paths
	love.graphics.setColor(1,1,1,1)
	for i = 1, #self.deadendpaths do
		for j = 1, #self.deadendpaths[i] do
			love.graphics.points((self.deadendpaths[i][j].x-1) * cellScale + cellScale/2, (self.deadendpaths[i][j].y-1) * cellScale + cellScale/2 )
		end
	end

	-- draw dead ends
	love.graphics.setColor(1,0.25,0.25,1)
	for i = 1, #self.deadends do
		love.graphics.points((self.deadends[i].x-1) * cellScale + cellScale/2, (self.deadends[i].y-1) * cellScale + cellScale/2 )
	end

	-- draw correct path and intersections
	for i = 1, #self.correctpath do
		if self.correctpath[i].i == 0 then
			love.graphics.setColor(0.5,0.5,1,1)
		else
			love.graphics.setColor(0.25,1,0.25,1)
		end
		love.graphics.points((self.correctpath[i].x-1) * cellScale + cellScale/2 , (self.correctpath[i].y-1) * cellScale + cellScale/2 )
	end

	for i = 1, #self.doors do
		-- door colours
		-- if i == 1 then 
		-- 	love.graphics.setColor(1,0,0,1)
		-- elseif i == 2 then
		-- 	love.graphics.setColor(0,1,0,1)
		-- elseif i == 3 then
		-- 	love.graphics.setColor(0,0,1,1)
		-- elseif i == 4 then
		-- 	love.graphics.setColor(1,0,1,1)			
		-- elseif i == 5 then
		-- 	love.graphics.setColor(0,1,1,1)			
		-- elseif i == 6 then
		-- 	love.graphics.setColor(1,1,0,1)			
		-- end

		love.graphics.setColor(self.doors[i].colour)

		if self.doors[i].wall == "n" then
			love.graphics.line((self.doors[i].x-1)*cellScale, (self.doors[i].y-1)*cellScale, self.doors[i].x*cellScale, (self.doors[i].y-1)*cellScale)
		end
		--draw south wall
		if self.doors[i].wall == "s" then
			love.graphics.line((self.doors[i].x-1)*cellScale, self.doors[i].y*cellScale, self.doors[i].x*cellScale, self.doors[i].y*cellScale)
		end
		--draw west wall
		if self.doors[i].wall == "w" then
			love.graphics.line((self.doors[i].x-1)*cellScale, (self.doors[i].y-1)*cellScale, (self.doors[i].x-1)*cellScale, self.doors[i].y*cellScale)
		end
		--draw east wall
		if self.doors[i].wall == "e" then
			love.graphics.line(self.doors[i].x*cellScale, (self.doors[i].y-1)*cellScale, self.doors[i].x*cellScale, self.doors[i].y*cellScale)
		end

		--draw the key
		love.graphics.circle("line", (self.keys[i].x-1)*cellScale+ cellScale/2 , (self.keys[i].y-1)*cellScale+ cellScale/2, cellScale/4-i)
	end    
	love.graphics.setColor(1,1,1,1)
end

return dungeon