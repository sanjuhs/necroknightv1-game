-- Save/Load game system
local SaveGame = {}

function SaveGame.save(game)
    local data = {
        player = {
            x = game.player.x,
            y = game.player.y,
            health = game.player.health,
            maxHealth = game.player.maxHealth,
            attack = game.player.attack,
            speed = game.player.speed,
            rp = game.player.rp,
            maxRP = game.player.maxRP,
            gold = game.player.gold
        },
        enemies = {},
        allies = {},
        deadBodies = {},
        upgradeStations = {},
        revealedTiles = {}
    }
    
    -- Save enemies
    for _, enemy in ipairs(game.enemies) do
        if not enemy.isDead then
            table.insert(data.enemies, {
                x = enemy.x,
                y = enemy.y,
                health = enemy.health,
                enemyType = enemy.enemyType
            })
        end
    end
    
    -- Save allies
    for _, ally in ipairs(game.allies) do
        if not ally.isDead then
            table.insert(data.allies, {
                x = ally.x,
                y = ally.y,
                health = ally.health
            })
        end
    end
    
    -- Save dead bodies
    for _, body in ipairs(game.deadBodies) do
        if body.canRevive then
            table.insert(data.deadBodies, {
                x = body.x,
                y = body.y,
                reviveTimer = body.reviveTimer
            })
        end
    end
    
    -- Save remaining upgrade stations
    for _, station in ipairs(game.upgradeStations) do
        table.insert(data.upgradeStations, {
            x = station.x,
            y = station.y,
            upgradeType = station.upgradeType
        })
    end
    
    -- Save revealed minimap tiles
    if game.minimap then
        for y = 1, #game.minimap.revealed do
            data.revealedTiles[y] = {}
            for x = 1, #game.minimap.revealed[y] do
                data.revealedTiles[y][x] = game.minimap.revealed[y][x]
            end
        end
    end
    
    -- Serialize to string
    local serialized = SaveGame.serialize(data)
    
    -- Save to file
    local success, message = love.filesystem.write("savegame.dat", serialized)
    
    return success, message
end

function SaveGame.load()
    local info = love.filesystem.getInfo("savegame.dat")
    if not info then
        return nil, "No save file found"
    end
    
    local contents, size = love.filesystem.read("savegame.dat")
    if not contents then
        return nil, "Could not read save file"
    end
    
    local data = SaveGame.deserialize(contents)
    if not data then
        return nil, "Could not parse save file"
    end
    
    return data
end

function SaveGame.exists()
    local info = love.filesystem.getInfo("savegame.dat")
    return info ~= nil
end

-- Simple serialization (Lua table to string)
function SaveGame.serialize(tbl, indent)
    indent = indent or 0
    local result = "{\n"
    local spacing = string.rep("  ", indent + 1)
    
    for k, v in pairs(tbl) do
        local key
        if type(k) == "number" then
            key = "[" .. k .. "]"
        else
            key = '["' .. tostring(k) .. '"]'
        end
        
        local value
        if type(v) == "table" then
            value = SaveGame.serialize(v, indent + 1)
        elseif type(v) == "string" then
            value = '"' .. v .. '"'
        elseif type(v) == "boolean" then
            value = v and "true" or "false"
        else
            value = tostring(v)
        end
        
        result = result .. spacing .. key .. " = " .. value .. ",\n"
    end
    
    result = result .. string.rep("  ", indent) .. "}"
    return result
end

-- Simple deserialization (string to Lua table)
function SaveGame.deserialize(str)
    local func, err = loadstring("return " .. str)
    if not func then
        return nil
    end
    
    -- Run in sandbox for safety
    setfenv(func, {})
    local success, result = pcall(func)
    
    if success then
        return result
    else
        return nil
    end
end

return SaveGame

