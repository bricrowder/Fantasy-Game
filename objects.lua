local objects = {}
objects.__index = objects

function objecta.new(type, cells)
    local o = {}
    setmetatable(o, objects)

    -- init the type/cells
    o.type = type
    o.cells = cells

    -- based on type, get values that will be needed
    if o.type == "overworld" then
        
    elseif o.type == "dungeon" then

    end

    return o
end

return objects