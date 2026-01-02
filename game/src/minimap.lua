-- Minimap with fog of war
local Config = require("src.config")

local Minimap = {}
Minimap.__index = Minimap

function Minimap.new()
    local self = setmetatable({}, Minimap)
    local cfg = Config.MINIMAP
    
    self.width = cfg.width
    self.height = cfg.height
    self.margin = cfg.margin
    
    -- Fog of war - track which tiles have been revealed
    self.revealed = {}
    for y = 1, Config.WORLD_HEIGHT do
        self.revealed[y] = {}
        for x = 1, Config.WORLD_WIDTH do
            self.revealed[y][x] = false
        end
    end
    
    self.fogRadius = 8  -- Tiles revealed around player
    
    return self
end

function Minimap:update(playerX, playerY)
    -- Convert player position to tile coordinates
    local tileX = math.floor(playerX / Config.TILE_SIZE) + 1
    local tileY = math.floor(playerY / Config.TILE_SIZE) + 1
    
    -- Reveal tiles around player
    for dy = -self.fogRadius, self.fogRadius do
        for dx = -self.fogRadius, self.fogRadius do
            local x = tileX + dx
            local y = tileY + dy
            
            -- Check if within fog radius (circular)
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist <= self.fogRadius then
                if x >= 1 and x <= Config.WORLD_WIDTH and y >= 1 and y <= Config.WORLD_HEIGHT then
                    self.revealed[y][x] = true
                end
            end
        end
    end
end

function Minimap:draw(player, enemies, allies, trees, upgradeStations)
    local cfg = Config.MINIMAP
    local screenW = love.graphics.getWidth()
    
    -- Position in top-right corner
    local mapX = screenW - self.width - self.margin
    local mapY = self.margin
    
    -- Scale factors
    local scaleX = self.width / (Config.WORLD_WIDTH * Config.TILE_SIZE)
    local scaleY = self.height / (Config.WORLD_HEIGHT * Config.TILE_SIZE)
    
    -- Background
    love.graphics.setColor(cfg.backgroundColor)
    love.graphics.rectangle("fill", mapX, mapY, self.width, self.height, 4, 4)
    
    -- Draw revealed terrain (simple green for grass)
    love.graphics.setColor(0.15, 0.3, 0.15, 1)
    for y = 1, Config.WORLD_HEIGHT do
        for x = 1, Config.WORLD_WIDTH do
            if self.revealed[y][x] then
                local px = mapX + (x - 1) * (self.width / Config.WORLD_WIDTH)
                local py = mapY + (y - 1) * (self.height / Config.WORLD_HEIGHT)
                local pw = self.width / Config.WORLD_WIDTH
                local ph = self.height / Config.WORLD_HEIGHT
                love.graphics.rectangle("fill", px, py, pw, ph)
            end
        end
    end
    
    -- Draw trees (only in revealed areas)
    love.graphics.setColor(cfg.treeColor)
    for _, tree in ipairs(trees) do
        local tx = math.floor(tree.x / Config.TILE_SIZE) + 1
        local ty = math.floor(tree.y / Config.TILE_SIZE) + 1
        if tx >= 1 and tx <= Config.WORLD_WIDTH and ty >= 1 and ty <= Config.WORLD_HEIGHT then
            if self.revealed[ty][tx] then
                local px = mapX + tree.x * scaleX
                local py = mapY + tree.y * scaleY
                love.graphics.circle("fill", px, py, 2)
            end
        end
    end
    
    -- Draw upgrade stations (only in revealed areas)
    love.graphics.setColor(cfg.upgradeColor)
    for _, station in ipairs(upgradeStations) do
        local tx = math.floor(station.x / Config.TILE_SIZE) + 1
        local ty = math.floor(station.y / Config.TILE_SIZE) + 1
        if tx >= 1 and tx <= Config.WORLD_WIDTH and ty >= 1 and ty <= Config.WORLD_HEIGHT then
            if self.revealed[ty][tx] then
                local px = mapX + station.x * scaleX
                local py = mapY + station.y * scaleY
                love.graphics.rectangle("fill", px - 3, py - 3, 6, 6)
            end
        end
    end
    
    -- Draw enemies (only in revealed areas)
    love.graphics.setColor(cfg.enemyColor)
    for _, enemy in ipairs(enemies) do
        if not enemy.isDead then
            local tx = math.floor(enemy.x / Config.TILE_SIZE) + 1
            local ty = math.floor(enemy.y / Config.TILE_SIZE) + 1
            if tx >= 1 and tx <= Config.WORLD_WIDTH and ty >= 1 and ty <= Config.WORLD_HEIGHT then
                if self.revealed[ty][tx] then
                    local px = mapX + enemy.x * scaleX
                    local py = mapY + enemy.y * scaleY
                    love.graphics.circle("fill", px, py, 3)
                end
            end
        end
    end
    
    -- Draw allies
    love.graphics.setColor(cfg.allyColor)
    for _, ally in ipairs(allies) do
        if not ally.isDead then
            local px = mapX + ally.x * scaleX
            local py = mapY + ally.y * scaleY
            love.graphics.circle("fill", px, py, 3)
        end
    end
    
    -- Draw player (always visible)
    love.graphics.setColor(cfg.playerColor)
    local playerPx = mapX + player.x * scaleX
    local playerPy = mapY + player.y * scaleY
    love.graphics.circle("fill", playerPx, playerPy, 4)
    
    -- Player direction indicator
    local dirX = player.facingRight and 6 or -6
    love.graphics.line(playerPx, playerPy, playerPx + dirX, playerPy)
    
    -- Border
    love.graphics.setColor(cfg.borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", mapX, mapY, self.width, self.height, 4, 4)
    love.graphics.setLineWidth(1)
    
    -- Label
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("Map", mapX + 4, mapY + 2)
    
    love.graphics.setColor(1, 1, 1)
end

return Minimap

