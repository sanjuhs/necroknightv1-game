-- World elements: Tilemap, Tree, DeadBody, UpgradeStation
local Config = require("src.config")
local Animation = require("src.animation")

-- ============================================================================
-- DEAD BODY CLASS
-- ============================================================================
local DeadBody = {}
DeadBody.__index = DeadBody

function DeadBody.new(x, y, spriteSheet, goldValue)
    local self = setmetatable({}, DeadBody)
    self.x = x
    self.y = y
    self.canRevive = true
    self.reviveTimer = 30
    self.goldValue = goldValue or 10
    
    self.deathAnimation = Animation.new(spriteSheet, 128, 128, 1, 6)
    self.deathAnimation.loop = false
    
    local sheetW = spriteSheet:getWidth()
    local sheetH = spriteSheet:getHeight()
    self.skullQuad = love.graphics.newQuad(5 * 128, 0, 128, 128, sheetW, sheetH)
    self.spriteSheet = spriteSheet
    
    self.state = "dying"
    self.highlightTimer = 0
    
    return self
end

function DeadBody:update(dt)
    if self.state == "dying" then
        self.deathAnimation:update(dt)
        if self.deathAnimation.finished then
            self.state = "skull"
        end
    else
        self.reviveTimer = self.reviveTimer - dt
        if self.reviveTimer <= 0 then
            self.canRevive = false
        end
        self.highlightTimer = self.highlightTimer + dt * 3
    end
end

function DeadBody:draw()
    if self.state == "dying" then
        self.deathAnimation:draw(self.x, self.y, 1, 1, 64, 100)
    else
        if self.canRevive then
            local pulse = 0.5 + 0.5 * math.sin(self.highlightTimer)
            love.graphics.setColor(1, 1, 0.5 + pulse * 0.5, 0.3 + pulse * 0.3)
            love.graphics.circle("fill", self.x, self.y - 20, 30 + pulse * 5)
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.draw(self.spriteSheet, self.skullQuad, self.x, self.y, 0, 1, 1, 64, 100)
    end
end

-- ============================================================================
-- TILEMAP CLASS
-- ============================================================================
local Tilemap = {}
Tilemap.__index = Tilemap

function Tilemap.new(tilesetImage, tileSize)
    local self = setmetatable({}, Tilemap)
    self.tileset = tilesetImage
    self.tileSize = tileSize
    self.tiles = {}
    
    local tsW = tilesetImage:getWidth()
    local tsH = tilesetImage:getHeight()
    
    self.grassQuad = love.graphics.newQuad(64, 64, 64, 64, tsW, tsH)
    
    for y = 1, Config.WORLD_HEIGHT do
        self.tiles[y] = {}
        for x = 1, Config.WORLD_WIDTH do
            self.tiles[y][x] = 1
        end
    end
    
    return self
end

function Tilemap:draw(cameraX, cameraY, screenW, screenH)
    local startX = math.max(1, math.floor(cameraX / self.tileSize))
    local startY = math.max(1, math.floor(cameraY / self.tileSize))
    local endX = math.min(Config.WORLD_WIDTH, math.ceil((cameraX + screenW) / self.tileSize) + 1)
    local endY = math.min(Config.WORLD_HEIGHT, math.ceil((cameraY + screenH) / self.tileSize) + 1)
    
    for y = startY, endY do
        for x = startX, endX do
            local drawX = (x - 1) * self.tileSize
            local drawY = (y - 1) * self.tileSize
            love.graphics.draw(self.tileset, self.grassQuad, drawX, drawY)
        end
    end
end

-- ============================================================================
-- TREE CLASS
-- ============================================================================
local Tree = {}
Tree.__index = Tree

function Tree.new(spriteSheet, x, y, variant)
    local self = setmetatable({}, Tree)
    self.x = x
    self.y = y
    self.variant = variant or 1
    
    local frameW = 192
    local frameH = 192
    local tsW = spriteSheet:getWidth()
    local tsH = spriteSheet:getHeight()
    
    local col = ((variant - 1) % 4)
    local row = math.floor((variant - 1) / 4)
    
    self.quad = love.graphics.newQuad(col * frameW, row * frameH, frameW, frameH, tsW, tsH)
    self.spriteSheet = spriteSheet
    
    return self
end

function Tree:draw()
    love.graphics.draw(self.spriteSheet, self.quad, self.x - 96, self.y - 160)
end

-- ============================================================================
-- UPGRADE STATION CLASS
-- ============================================================================
local UpgradeStation = {}
UpgradeStation.__index = UpgradeStation

function UpgradeStation.new(x, y, upgradeType)
    local self = setmetatable({}, UpgradeStation)
    self.x = x
    self.y = y
    self.upgradeType = upgradeType
    self.config = Config.UPGRADE_TYPES[upgradeType]
    self.radius = 40
    self.pulseTimer = 0
    self.used = false
    return self
end

function UpgradeStation:update(dt)
    self.pulseTimer = self.pulseTimer + dt * 2
end

function UpgradeStation:draw()
    local pulse = 0.7 + 0.3 * math.sin(self.pulseTimer)
    local color = self.config.color
    
    -- Outer glow
    love.graphics.setColor(color[1], color[2], color[3], 0.2 * pulse)
    love.graphics.circle("fill", self.x, self.y, self.radius + 20 * pulse)
    
    -- Inner circle
    love.graphics.setColor(color[1], color[2], color[3], 0.6)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    
    -- Border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("line", self.x, self.y, self.radius)
    
    -- Icon (simple symbol based on type)
    love.graphics.setColor(1, 1, 1)
    local symbol = "?"
    if self.upgradeType == "health" then symbol = "+"
    elseif self.upgradeType == "attack" then symbol = "⚔"
    elseif self.upgradeType == "speed" then symbol = "»"
    elseif self.upgradeType == "rp" then symbol = "♦"
    end
    
    local font = love.graphics.getFont()
    love.graphics.print(symbol, self.x - font:getWidth(symbol)/2, self.y - font:getHeight()/2)
    
    love.graphics.setColor(1, 1, 1)
end

function UpgradeStation:drawPrompt(player)
    local dx = player.x - self.x
    local dy = player.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if dist < 80 then
        love.graphics.setColor(1, 1, 0.8)
        local text = string.format("[F] %s (+%d %s)", 
            self.config.name, 
            self.config.increase, 
            self.config.stat)
        love.graphics.print(text, self.x - 60, self.y - 70)
        love.graphics.setColor(1, 1, 1)
    end
end

function UpgradeStation:tryUpgrade(player)
    local dx = player.x - self.x
    local dy = player.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if dist < 80 then
        -- Apply upgrade based on type
        local stat = self.config.stat
        local increase = self.config.increase
        
        if stat == "maxHealth" then
            player.maxHealth = player.maxHealth + increase
            player.health = player.health + increase
        elseif stat == "attack" then
            player.attack = player.attack + increase
        elseif stat == "speed" then
            player.speed = player.speed + increase
        elseif stat == "maxRP" then
            player.maxRP = player.maxRP + increase
            player.rp = math.min(player.rp + increase, player.maxRP)
        end
        
        return true
    end
    return false
end

return {
    DeadBody = DeadBody,
    Tilemap = Tilemap,
    Tree = Tree,
    UpgradeStation = UpgradeStation
}

