-- World elements: Tilemap, Tree, DeadBody, UpgradeStation
local Config = require("src.config")
local Animation = require("src.animation")

-- ============================================================================
-- DEAD BODY CLASS
-- ============================================================================
local DeadBody = {}
DeadBody.__index = DeadBody

function DeadBody.new(x, y, deadAnimation, goldValue, enemyType)
    local self = setmetatable({}, DeadBody)
    self.x = x
    self.y = y
    self.canRevive = true
    self.reviveTimer = 30
    self.goldValue = goldValue or 10
    self.enemyType = enemyType or "normal"  -- Store enemy type for revival
    
    -- Use the provided dead animation
    self.deadAnimation = deadAnimation
    self.hasAnimation = deadAnimation ~= nil
    
    self.state = "dying"
    self.highlightTimer = 0
    self.dyingTimer = 0
    self.dyingDuration = 1.0  -- 1 second death animation
    
    -- Get outline color from enemy type for visual indication
    if enemyType and Config.ENEMY_TYPES[enemyType] and Config.ENEMY_TYPES[enemyType].outline then
        self.outlineColor = Config.ENEMY_TYPES[enemyType].outline
    else
        self.outlineColor = nil
    end
    
    return self
end

function DeadBody:update(dt)
    if self.state == "dying" then
        self.dyingTimer = self.dyingTimer + dt
        if self.hasAnimation then
            self.deadAnimation:update(dt)
            if self.deadAnimation.finished then
                self.state = "skull"
            end
        elseif self.dyingTimer >= self.dyingDuration then
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
        -- Fade out effect during death
        local alpha = 1.0 - (self.dyingTimer / self.dyingDuration)
        love.graphics.setColor(1, 1, 1, alpha)
        
        -- Draw a simple death effect (falling down)
        local offsetY = self.dyingTimer * 20
        love.graphics.circle("fill", self.x, self.y + offsetY, 20)
        love.graphics.setColor(1, 1, 1, 1)
    else
        if self.canRevive then
            local pulse = 0.5 + 0.5 * math.sin(self.highlightTimer)
            
            -- Use enemy type color if special, otherwise golden
            local glowColor
            if self.outlineColor then
                glowColor = self.outlineColor
            else
                glowColor = {1, 1, 0.5}
            end
            
            -- Outer glow
            love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], 0.2 + pulse * 0.2)
            love.graphics.circle("fill", self.x, self.y - 20, 35 + pulse * 8)
            
            -- Inner glow
            love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], 0.4 + pulse * 0.3)
            love.graphics.circle("fill", self.x, self.y - 20, 25 + pulse * 5)
            
            -- Ring
            love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], 0.8)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", self.x, self.y - 20, 30 + pulse * 5)
            love.graphics.setLineWidth(1)
            
            -- Draw skull symbol
            love.graphics.setColor(1, 1, 1, 0.9)
            local skullSize = 15 + pulse * 3
            -- Simple skull shape
            love.graphics.circle("fill", self.x, self.y - 25, skullSize)
            love.graphics.setColor(0.2, 0.2, 0.2)
            -- Eyes
            love.graphics.circle("fill", self.x - 5, self.y - 28, 3)
            love.graphics.circle("fill", self.x + 5, self.y - 28, 3)
            -- Nose
            love.graphics.polygon("fill", self.x, self.y - 22, self.x - 2, self.y - 18, self.x + 2, self.y - 18)
            
            love.graphics.setColor(1, 1, 1)
        else
            -- Faded skull when can't revive
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
            love.graphics.circle("fill", self.x, self.y - 25, 12)
            love.graphics.setColor(1, 1, 1)
        end
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
    
    -- Tilemap is 9x6 grid of 64x64 tiles (576x384 total)
    -- Use the center grass tile (column 1, row 1) for flat grass without edges
    -- This gives a nice middle green color
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
-- TREE CLASS (Updated for Free Pack trees - individual sprite sheets)
-- ============================================================================
local Tree = {}
Tree.__index = Tree

-- Trees in Free Pack are individual animated sprite strips
-- treeSheets: table of loaded tree images { tree1, tree2, tree3, tree4 }
function Tree.new(treeSheets, x, y, variant)
    local self = setmetatable({}, Tree)
    self.x = x
    self.y = y
    self.variant = variant or 1
    
    -- Select tree sprite based on variant (1-4)
    local variantIndex = ((variant - 1) % 4) + 1
    local treeSheet = treeSheets[variantIndex] or treeSheets[1]
    
    -- Trees are animated sprite strips with 8 frames
    local sheetW = treeSheet:getWidth()
    local sheetH = treeSheet:getHeight()
    local frameW = sheetW / 8  -- 8 frames per tree
    local frameH = sheetH
    
    -- Create animation for swaying tree
    self.animation = Animation.new(treeSheet, frameW, frameH, 8, 0.15)
    self.spriteSheet = treeSheet
    self.frameWidth = frameW
    self.frameHeight = frameH
    
    -- Randomize starting frame for variety
    self.animation.currentFrame = math.random(1, 8)
    self.animation.timer = math.random() * 0.15
    
    return self
end

function Tree:update(dt)
    self.animation:update(dt)
end

function Tree:draw()
    -- Center the tree at its position
    self.animation:draw(self.x - self.frameWidth/2, self.y - self.frameHeight + 20)
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

-- ============================================================================
-- BUILDING CLASS (Capturable buildings that spawn units)
-- ============================================================================
local Building = {}
Building.__index = Building

-- owner: "neutral", "player", "enemy"
function Building.new(x, y, buildingType, owner, blueImage, redImage)
    local self = setmetatable({}, Building)
    self.x = x
    self.y = y
    self.buildingType = buildingType
    self.config = Config.BUILDING_TYPES[buildingType]
    self.owner = owner or "neutral"
    
    -- Images for different ownership states
    self.blueImage = blueImage
    self.redImage = redImage
    self.currentImage = (owner == "player") and blueImage or redImage
    
    -- Capture progress
    self.captureProgress = 0
    self.captureTimer = 0
    self.isBeingCaptured = false
    
    -- Unit spawning
    self.spawnTimer = 0
    self.unitsSpawned = 0
    
    -- Visual effects
    self.pulseTimer = 0
    
    return self
end

function Building:update(dt, player, allies)
    self.pulseTimer = self.pulseTimer + dt * 2
    
    -- Check if player is capturing (only neutral/enemy buildings)
    if self.owner ~= "player" then
        local dx = player.x - self.x
        local dy = player.y - self.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist < self.config.captureRadius then
            self.isBeingCaptured = true
            self.captureProgress = self.captureProgress + dt / self.config.captureTime
            
            if self.captureProgress >= 1.0 then
                self:capture("player")
            end
        else
            self.isBeingCaptured = false
            -- Slowly lose capture progress when not being captured
            self.captureProgress = math.max(0, self.captureProgress - dt * 0.5)
        end
    end
    
    -- Spawn units if owned by player
    if self.owner == "player" and self.unitsSpawned < self.config.maxUnits then
        self.spawnTimer = self.spawnTimer + dt
        if self.spawnTimer >= self.config.spawnCooldown then
            self.spawnTimer = 0
            self.unitsSpawned = self.unitsSpawned + 1
            return true  -- Signal to spawn a unit
        end
    end
    
    return false
end

function Building:capture(newOwner)
    self.owner = newOwner
    self.captureProgress = 0
    self.isBeingCaptured = false
    self.spawnTimer = self.config.spawnCooldown * 0.5  -- Spawn first unit faster
    self.currentImage = (newOwner == "player") and self.blueImage or self.redImage
end

function Building:draw()
    local pulse = 0.8 + 0.2 * math.sin(self.pulseTimer)
    
    -- Draw building shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", self.x, self.y + 20, self.config.width * 0.4, 15)
    
    -- Draw ownership indicator glow
    if self.owner == "player" then
        love.graphics.setColor(0.2, 0.6, 1, 0.3 * pulse)
        love.graphics.circle("fill", self.x, self.y, self.config.captureRadius * 0.8)
    elseif self.owner == "enemy" then
        love.graphics.setColor(1, 0.2, 0.2, 0.2 * pulse)
        love.graphics.circle("fill", self.x, self.y, self.config.captureRadius * 0.8)
    end
    
    -- Draw building
    love.graphics.setColor(1, 1, 1, 1)
    local imgW = self.currentImage:getWidth()
    local imgH = self.currentImage:getHeight()
    love.graphics.draw(self.currentImage, self.x - imgW/2, self.y - imgH + 30)
    
    -- Draw capture progress bar if being captured
    if self.isBeingCaptured and self.owner ~= "player" then
        local barWidth = 80
        local barHeight = 8
        local barY = self.y - imgH - 10
        
        -- Background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", self.x - barWidth/2, barY, barWidth, barHeight)
        
        -- Progress
        love.graphics.setColor(0.2, 0.8, 0.2, 1)
        love.graphics.rectangle("fill", self.x - barWidth/2, barY, barWidth * self.captureProgress, barHeight)
        
        -- Border
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("line", self.x - barWidth/2, barY, barWidth, barHeight)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Building:drawPrompt(player)
    if self.owner ~= "player" then
        local dx = player.x - self.x
        local dy = player.y - self.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist < self.config.captureRadius * 1.5 then
            love.graphics.setColor(1, 1, 0.8, 0.9)
            local text = string.format("Capturing %s... (Spawns %s)", 
                self.config.name, 
                Config.UNIT_CLASSES[self.config.unitType].name)
            local font = love.graphics.getFont()
            love.graphics.print(text, self.x - font:getWidth(text)/2, self.y - self.config.height - 30)
            love.graphics.setColor(1, 1, 1, 1)
        end
    elseif self.unitsSpawned < self.config.maxUnits then
        -- Show spawn progress for owned buildings
        local dx = player.x - self.x
        local dy = player.y - self.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist < 200 then
            love.graphics.setColor(0.8, 0.9, 1, 0.8)
            local timeLeft = math.ceil(self.config.spawnCooldown - self.spawnTimer)
            local text = string.format("%s - Next %s in %ds (%d/%d)", 
                self.config.name,
                Config.UNIT_CLASSES[self.config.unitType].name,
                timeLeft,
                self.unitsSpawned,
                self.config.maxUnits)
            local font = love.graphics.getFont()
            love.graphics.print(text, self.x - font:getWidth(text)/2, self.y - self.config.height - 30)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

-- ============================================================================
-- GOLD RESOURCE CLASS
-- ============================================================================
local GoldResource = {}
GoldResource.__index = GoldResource

function GoldResource.new(x, y, goldImage)
    local self = setmetatable({}, GoldResource)
    self.x = x
    self.y = y
    self.image = goldImage
    self.amount = 100  -- Total gold available
    self.pulseTimer = math.random() * math.pi * 2
    return self
end

function GoldResource:update(dt)
    self.pulseTimer = self.pulseTimer + dt * 2
end

function GoldResource:gather(amount)
    local gathered = math.min(amount, self.amount)
    self.amount = self.amount - gathered
    return gathered
end

function GoldResource:isDepleted()
    return self.amount <= 0
end

function GoldResource:draw()
    local pulse = 0.9 + 0.1 * math.sin(self.pulseTimer)
    
    -- Draw glow
    love.graphics.setColor(1, 0.85, 0.2, 0.2 * pulse)
    love.graphics.circle("fill", self.x, self.y, 30)
    
    -- Draw gold
    love.graphics.setColor(1, 1, 1, 1)
    local imgW = self.image:getWidth()
    local imgH = self.image:getHeight()
    love.graphics.draw(self.image, self.x - imgW/2, self.y - imgH/2)
    
    -- Draw amount indicator
    if self.amount < 100 then
        love.graphics.setColor(1, 0.9, 0.3, 0.9)
        local font = love.graphics.getFont()
        local text = tostring(self.amount)
        love.graphics.print(text, self.x - font:getWidth(text)/2, self.y + 20)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- ============================================================================
-- PROJECTILE CLASS (Arrows and other projectiles)
-- ============================================================================
local Projectile = {}
Projectile.__index = Projectile

function Projectile.new(x, y, targetX, targetY, damage, speed, owner, arrowImage)
    local self = setmetatable({}, Projectile)
    self.x = x
    self.y = y
    self.startX = x
    self.startY = y
    self.damage = damage
    self.speed = speed or 500
    self.owner = owner  -- Who shot this (to avoid self-damage)
    self.image = arrowImage
    self.isDead = false
    self.maxDistance = 400  -- Max travel distance
    
    -- Calculate direction to target
    local dx = targetX - x
    local dy = targetY - y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if dist > 0 then
        self.dirX = dx / dist
        self.dirY = dy / dist
    else
        self.dirX = 1
        self.dirY = 0
    end
    
    -- Calculate rotation angle for arrow sprite
    self.rotation = math.atan2(dy, dx)
    
    return self
end

function Projectile:update(dt, enemies, player, allies)
    -- Move projectile
    self.x = self.x + self.dirX * self.speed * dt
    self.y = self.y + self.dirY * self.speed * dt
    
    -- Check if traveled too far
    local traveled = math.sqrt((self.x - self.startX)^2 + (self.y - self.startY)^2)
    if traveled > self.maxDistance then
        self.isDead = true
        return
    end
    
    -- Check collision with targets
    local targets = {}
    
    -- If owner is player/ally, target enemies
    if self.owner and (self.owner.isPlayer or self.owner.isAlly) then
        targets = enemies
    else
        -- If owner is enemy, target player and allies
        if not player.isDead then
            table.insert(targets, player)
        end
        for _, ally in ipairs(allies) do
            if not ally.isDead then
                table.insert(targets, ally)
            end
        end
    end
    
    -- Check collision with targets
    for _, target in ipairs(targets) do
        if not target.isDead then
            local dx = target.x - self.x
            local dy = target.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist < (target.collisionRadius or 30) + 10 then
                -- Hit!
                target:takeDamage(self.damage)
                self.isDead = true
                return
            end
        end
    end
end

function Projectile:draw()
    if self.isDead then return end
    
    if self.image then
        -- Draw arrow sprite rotated in direction of travel
        love.graphics.setColor(1, 1, 1, 1)
        local imgW = self.image:getWidth()
        local imgH = self.image:getHeight()
        love.graphics.draw(self.image, self.x, self.y, self.rotation, 1, 1, imgW/2, imgH/2)
    else
        -- Draw simple arrow shape if no image
        love.graphics.setColor(0.8, 0.6, 0.2, 1)
        local arrowLen = 20
        local endX = self.x + self.dirX * arrowLen
        local endY = self.y + self.dirY * arrowLen
        love.graphics.setLineWidth(3)
        love.graphics.line(self.x, self.y, endX, endY)
        
        -- Arrow head
        local headSize = 6
        local perpX = -self.dirY * headSize
        local perpY = self.dirX * headSize
        love.graphics.polygon("fill", 
            endX, endY,
            endX - self.dirX * headSize + perpX, endY - self.dirY * headSize + perpY,
            endX - self.dirX * headSize - perpX, endY - self.dirY * headSize - perpY
        )
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- ============================================================================
-- HEAL EFFECT CLASS (Visual effect for monk healing)
-- ============================================================================
local HealEffect = {}
HealEffect.__index = HealEffect

function HealEffect.new(x, y)
    local self = setmetatable({}, HealEffect)
    self.x = x
    self.y = y
    self.timer = 0
    self.duration = 0.8
    self.isDead = false
    return self
end

function HealEffect:update(dt)
    self.timer = self.timer + dt
    if self.timer >= self.duration then
        self.isDead = true
    end
end

function HealEffect:draw()
    if self.isDead then return end
    
    local progress = self.timer / self.duration
    local alpha = 1.0 - progress
    local scale = 1.0 + progress * 0.5
    
    -- Draw healing glow
    love.graphics.setColor(0.2, 1, 0.4, alpha * 0.4)
    love.graphics.circle("fill", self.x, self.y - 60, 40 * scale)
    
    -- Draw healing ring
    love.graphics.setColor(0.4, 1, 0.5, alpha * 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", self.x, self.y - 60, 30 * scale)
    love.graphics.setLineWidth(1)
    
    -- Draw plus symbol
    love.graphics.setColor(0.4, 1, 0.5, alpha)
    local size = 15 * (1 + progress * 0.3)
    love.graphics.rectangle("fill", self.x - size/6, self.y - 60 - size/2, size/3, size)
    love.graphics.rectangle("fill", self.x - size/2, self.y - 60 - size/6, size, size/3)
    
    love.graphics.setColor(1, 1, 1, 1)
end

return {
    DeadBody = DeadBody,
    Tilemap = Tilemap,
    Tree = Tree,
    UpgradeStation = UpgradeStation,
    Building = Building,
    GoldResource = GoldResource,
    Projectile = Projectile,
    HealEffect = HealEffect
}
