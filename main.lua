-- load requires
dungeon_class = require "dungeon"
local room_class = require "room"
local player_class = require "player"
local enemy_class = require "enemy"
local overworld_class = require "overworld"
object_class = require "object"
light_class = require "light"
bullet_class = require "bullet"
json = require "dkjson"

-- objects/data/lists
config = json.opendecode("config/config.json")
overworld = nil
player = nil
enemies = {}
bullets = {}

-- textures with meta info (name, etc)
objects = {}
lights = {}

-- variables
state = "game"      -- game, menu, etc...
mode = "overworld"  -- overworld, dungeon, etc
pause = false
enemycounter = 0

view = nil


function love.load()
    local seed = os.time()
    math.randomseed(seed)
    math.random()
    math.random()
    math.random()

    love.graphics.setDefaultFilter("nearest", "nearest")

    -- load objects: texture and info; create quads, calculate cell size of the quad
    objects.info = json.opendecode("assets/objects.json").objects
    objects.texture = love.graphics.newImage("assets/objects.png")
    for i, v in ipairs(objects.info) do
        v.quad = love.graphics.newQuad(v.quadinfo.x, v.quadinfo.y, v.quadinfo.w, v.quadinfo.h, objects.texture:getWidth(), objects.texture:getHeight())
        v.cellSize = v.quadinfo.w / config.overworld.cellSize
    end    

    -- light textures - to change!!
    for i, l in ipairs(config.lights) do
        table.insert(lights, {
            name = l.name,
            texture = love.graphics.newImage(l.texture)
        })
    end

    -- load up bullet textures
    -- for i, b in ipairs(config.bullets) do
    --     table.insert(bullets, {name=b.name, textures={}})
    --     for j, t in ipairs(b.textures.flying) do
    --         bullets[#bullets].animation = "flying"
    --         table.insert(bullets[#bullets].textures, love.graphics.newImage(t))
    --     end
    -- end
    love.mouse.setVisible(false)

    -- create world and dungeons
    overworld = overworld_class.new()

    -- player
    player = player_class.new()

    -- camera position
    cx = 0
    cy = 0

    -- view canvas
    view = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
end

function love.update(dt)
    -- get mouse input for angle
    local mx, my = love.mouse.getPosition()

    -- get angle difference, use for a mouse speed relative rotation speed
    local dx = (mx - love.graphics.getWidth()/2) / 100
    -- update angle
    local angle = dx * config.player.rotation * dt
    -- additional angle used for asd movement
    local mangle = 0

    -- get input
    local move = false
    if love.keyboard.isDown("w") then
        move = true
        mangle = math.pi*3/2   
    end
    if love.keyboard.isDown("s") then
        move = true
        mangle = math.pi/2
    end
    if love.keyboard.isDown("a") then
        move = true
        mangle = math.pi
    end
    if love.keyboard.isDown("d") then
        move = true
        mangle = 0
    end

    -- update world/dungeon
    overworld:update(dt)

    -- update player, enemies
    player:update(dt, move, angle, mangle)

    -- reset mouse
    love.mouse.setPosition(love.graphics.getWidth()/2,love.graphics.getHeight()/2)

    -- update the camera position, bound to world/dungeon
    local ow, oh = overworld:getDimensions()
    cx = player.x - love.graphics.getWidth()/2
    cy = player.y - love.graphics.getHeight()/2
    
    if cx < 0 then
        cx = 0
    elseif cx > ow - love.graphics.getWidth() then
        cx = ow - love.graphics.getWidth()
    end
    if cy < 0 then
        cy = 0
    elseif cy > oh - love.graphics.getHeight() then
        cy = oh - love.graphics.getHeight()
    end

    -- reverse it for the translation
    cx = -cx
    cy = -cy
end

function love.draw()
    -- translate the coords based on the camera/player/view position calculated in the update function
    love.graphics.push()
    local transform = love.math.newTransform(cx, cy)
    love.graphics.applyTransform(transform)

    -- draw the main scene to gthe view canvas: world/dungeon, player, enemies, etc.
    love.graphics.setCanvas(view)
    overworld:draw()
    overworld:drawObjects(1)
    player:draw()
    overworld:drawObjects(2)
    overworld:drawObjects(3)
    love.graphics.setCanvas()

    -- draw lighting: ambient
    love.graphics.setColor(overworld:getAmbientColour())
    love.graphics.rectangle("fill",-cx,-cy,love.graphics.getWidth(),love.graphics.getHeight())

    -- draw lighting: point, directional
    love.graphics.setColor(1,1,1,1)
    overworld:drawLights()
    player:drawLights()
    love.graphics.setColor(1,1,1,1)

    -- draw the view of the scene from above, multiplied by the lighting
    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.draw(view,-cx,-cy)
  
    -- reset origin/translation and draw mode
    love.graphics.pop()
    love.graphics.setBlendMode("alpha")

    -- draw ui - minimap
    local t = overworld.minimap
    if mode == "dungeon" then
        t = overworld.dungeons[overworld.currentDungeon].minimap
    end
    love.graphics.draw(t, love.graphics.getWidth() - t:getWidth(), 0)

    -- debug
    local p = string.format("position: %.2f, %.2f", player.x, player.y)
    love.graphics.print(p, 10, 10)
    local a = string.format("angle: %.2f", player.angle)
    love.graphics.print(a, 10, 25)
    local cx, cy = overworld:getCell(player.x, player.y)
    love.graphics.print("Cell: " .. cx .. "," .. cy, 10, 40)
    local stats = love.graphics.getStats()
    love.graphics.print("fps: " .. love.timer.getFPS(), 10, 545)
    love.graphics.print("draws: " .. stats.drawcalls, 10, 560)
    local m = string.format("memory: %.2f", stats.texturememory/1024/1024)
    love.graphics.print(m, 10, 575)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function love.keyreleased(key)
    if key == "w" or key == "a" or key == "s" or key == "d" then
        player:setAnimation("standing")
    end
    -- temp
    if key == "space" then
        overworld.currentDungeon = overworld.currentDungeon + 1
        if overworld.currentDungeon > #overworld.dungeons then
            overworld.currentDungeon = 1
        end
    end
end