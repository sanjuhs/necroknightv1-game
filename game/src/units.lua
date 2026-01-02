-- Unit classes: Player, Enemy, Ally
local Config = require("src.config")
local Animation = require("src.animation")

-- Forward declaration
local Ally

-- ============================================================================
-- UNIT CLASS (Base class)
-- ============================================================================
local Unit = {}
Unit.__index = Unit

function Unit.new(spriteSheet, x, y, config)
    local self = setmetatable({}, Unit)
    self.x = x
    self.y = y
    self.speed = config.speed or 150
    self.direction = "down"
    self.state = "idle"
    self.facingRight = true
    
    -- Combat stats
    self.maxHealth = config.maxHealth or 100
    self.health = self.maxHealth
    self.attack = config.attack or 10
    self.attackRange = config.attackRange or 80
    self.attackCooldown = config.attackCooldown or 1.0
    self.attackTimer = 0
    self.target = nil
    self.isPlayer = config.isPlayer or false
    self.isAlly = config.isAlly or false
    self.isDead = false
    
    -- Damage flag
    self.damageDealtThisAttack = false
    
    -- Collision
    self.collisionRadius = config.collisionRadius or 32
    
    -- Outline color (RGBA table or nil)
    self.outlineColor = config.outlineColor or nil
    
    -- Enemy type name (for display)
    self.typeName = config.typeName or "Unit"
    
    -- Frame dimensions for warrior (192x192 per frame, 6 columns)
    local frameW = 192
    local frameH = 192
    
    self.animations = {
        idle = Animation.new(spriteSheet, frameW, frameH, 1, 6),
        walk = Animation.new(spriteSheet, frameW, frameH, 2, 6),
        attack_down = Animation.new(spriteSheet, frameW, frameH, 3, 6),
        attack_down_back = Animation.new(spriteSheet, frameW, frameH, 4, 6),
        attack_down_heavy = Animation.new(spriteSheet, frameW, frameH, 5, 6),
        attack_down_heavy_back = Animation.new(spriteSheet, frameW, frameH, 6, 6),
        attack_up = Animation.new(spriteSheet, frameW, frameH, 7, 6),
        attack_up_back = Animation.new(spriteSheet, frameW, frameH, 8, 6),
    }
    
    for name, anim in pairs(self.animations) do
        if name:find("attack") then
            anim.loop = false
        end
    end
    
    self.currentAnimation = self.animations.idle
    self.spriteSheet = spriteSheet
    
    return self
end

function Unit:getDistance(other)
    local dx = other.x - self.x
    local dy = other.y - self.y
    return math.sqrt(dx * dx + dy * dy)
end

function Unit:moveTo(targetX, targetY, dt)
    local dx = targetX - self.x
    local dy = targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if dist > 5 then
        dx = dx / dist
        dy = dy / dist
        
        self.x = self.x + dx * self.speed * dt
        self.y = self.y + dy * self.speed * dt
        
        self.facingRight = dx >= 0
        self.direction = dy < 0 and "up" or "down"
        
        return true
    end
    return false
end

function Unit:startAttack(target)
    self.state = "attack"
    self.target = target
    self.damageDealtThisAttack = false
    
    local dy = target.y - self.y
    if dy < 0 then
        self.currentAnimation = self.animations.attack_up
    else
        self.currentAnimation = self.animations.attack_down
    end
    self.currentAnimation:reset()
    
    self.facingRight = target.x >= self.x
end

function Unit:update(dt)
    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end
    
    if self.state == "attack" then
        self.currentAnimation:update(dt)
        
        -- Deal damage at the LAST frame (frame 6), ONLY ONCE
        if self.currentAnimation.currentFrame == 6 and not self.damageDealtThisAttack then
            if self.target and not self.target.isDead then
                if self:getDistance(self.target) <= self.attackRange * 1.5 then
                    self.target:takeDamage(self.attack)
                    self.damageDealtThisAttack = true
                end
            end
        end
        
        if self.currentAnimation.finished then
            self.state = "idle"
            self.attackTimer = self.attackCooldown
            self.currentAnimation = self.animations.idle
            self.currentAnimation:reset()
            self.damageDealtThisAttack = false
        end
        return
    end
    
    self.currentAnimation:update(dt)
end

function Unit:takeDamage(amount)
    self.health = self.health - amount
    if self.health <= 0 then
        self.health = 0
        self.isDead = true
    end
end

function Unit:draw()
    if self.isDead then return end
    
    local scaleX = self.facingRight and 1 or -1
    local offsetX = 96
    local offsetY = 144
    
    -- Draw glow effect if unit has an outline color
    if self.outlineColor then
        self:drawGlow(self.outlineColor)
    end
    
    -- Draw the sprite
    love.graphics.setColor(1, 1, 1, 1)
    self.currentAnimation:draw(self.x, self.y, scaleX, 1, offsetX, offsetY)
    
    -- Draw health bar
    self:drawHealthBar()
end

function Unit:drawGlow(color)
    -- Draw a glowing ellipse under the character's feet
    local glowX = self.x
    local glowY = self.y - 10  -- Slightly above feet position
    
    -- Pulsing effect
    local pulse = 0.8 + 0.2 * math.sin(love.timer.getTime() * 4)
    
    -- Outer glow (larger, more transparent)
    love.graphics.setColor(color[1], color[2], color[3], 0.15 * pulse)
    love.graphics.ellipse("fill", glowX, glowY, 50 * pulse, 25 * pulse)
    
    -- Middle glow
    love.graphics.setColor(color[1], color[2], color[3], 0.3 * pulse)
    love.graphics.ellipse("fill", glowX, glowY, 35 * pulse, 18 * pulse)
    
    -- Inner glow (brighter)
    love.graphics.setColor(color[1], color[2], color[3], 0.5 * pulse)
    love.graphics.ellipse("fill", glowX, glowY, 25, 12)
    
    -- Bright core
    love.graphics.setColor(color[1], color[2], color[3], 0.7)
    love.graphics.ellipse("fill", glowX, glowY, 15, 8)
    
    -- Ring outline
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.ellipse("line", glowX, glowY, 30, 15)
    love.graphics.setLineWidth(1)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Unit:drawHealthBar()
    local barWidth = 60
    local barHeight = 6
    local barY = self.y - 160
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", self.x - barWidth/2, barY, barWidth, barHeight)
    
    local healthPercent = self.health / self.maxHealth
    if self.isPlayer then
        love.graphics.setColor(0.2, 0.8, 0.3)
    elseif self.isAlly then
        love.graphics.setColor(0.2, 0.6, 1)
    else
        love.graphics.setColor(0.8, 0.2, 0.2)
    end
    love.graphics.rectangle("fill", self.x - barWidth/2, barY, barWidth * healthPercent, barHeight)
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.x - barWidth/2, barY, barWidth, barHeight)
    
    love.graphics.setColor(1, 1, 1)
end

-- ============================================================================
-- PLAYER CLASS
-- ============================================================================
local Player = {}
Player.__index = Player
setmetatable(Player, { __index = Unit })

function Player.new(spriteSheet, x, y)
    local stats = Config.PLAYER_STATS
    local self = Unit.new(spriteSheet, x, y, {
        maxHealth = stats.maxHealth,
        attack = stats.attack,
        speed = stats.speed,
        attackRange = stats.attackRange,
        attackCooldown = stats.attackCooldown,
        collisionRadius = stats.collisionRadius,
        isPlayer = true,
        outlineColor = Config.PLAYER_OUTLINE,
        typeName = "Hero"
    })
    setmetatable(self, Player)
    
    -- Revival Points
    self.maxRP = stats.maxRP
    self.rp = self.maxRP
    self.reviveCost = stats.reviveCost
    
    -- Upgrade points/gold
    self.gold = 0
    
    -- Track base stats for upgrades
    self.baseMaxHealth = stats.maxHealth
    self.baseAttack = stats.attack
    self.baseSpeed = stats.speed
    self.baseMaxRP = stats.maxRP
    
    return self
end

function Player:update(dt, enemies, allies)
    if self.isDead then return end
    
    -- Regenerate health and RP
    if self.health < self.maxHealth then
        self.health = math.min(self.maxHealth, self.health + Config.HEALTH_REGEN_RATE * dt)
    end
    if self.rp < self.maxRP then
        self.rp = math.min(self.maxRP, self.rp + Config.RP_REGEN_RATE * dt)
    end
    
    if self.state == "attack" then
        Unit.update(self, dt)
        return
    end
    
    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end
    
    local dx, dy = 0, 0
    local moving = false
    
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        dy = -1
        self.direction = "up"
        moving = true
    elseif love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        dy = 1
        self.direction = "down"
        moving = true
    end
    
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        dx = -1
        self.facingRight = false
        moving = true
    elseif love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        dx = 1
        self.facingRight = true
        moving = true
    end
    
    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx = dx / len
        dy = dy / len
    end
    
    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt
    
    local margin = 96
    self.x = math.max(margin, math.min(self.x, Config.WORLD_WIDTH * Config.TILE_SIZE - margin))
    self.y = math.max(margin, math.min(self.y, Config.WORLD_HEIGHT * Config.TILE_SIZE - margin))
    
    if moving then
        self.state = "walk"
        self.currentAnimation = self.animations.walk
    else
        self.state = "idle"
        self.currentAnimation = self.animations.idle
    end
    
    -- Auto-attack nearby enemies
    if self.attackTimer <= 0 then
        local closestEnemy = nil
        local closestDist = self.attackRange
        
        for _, enemy in ipairs(enemies) do
            if not enemy.isDead then
                local dist = self:getDistance(enemy)
                if dist < closestDist then
                    closestDist = dist
                    closestEnemy = enemy
                end
            end
        end
        
        if closestEnemy then
            self:startAttack(closestEnemy)
        end
    end
    
    self.currentAnimation:update(dt)
end

function Player:tryRevive(deadBodies, allies, blueSheet)
    local nearestBody = nil
    local nearestDist = 100
    
    for i, body in ipairs(deadBodies) do
        if body.canRevive and body.state == "skull" then
            local dx = body.x - self.x
            local dy = body.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < nearestDist then
                nearestDist = dist
                nearestBody = { body = body, index = i }
            end
        end
    end
    
    if nearestBody and self.rp >= self.reviveCost then
        self.rp = self.rp - self.reviveCost
        
        local ally = Ally.new(blueSheet, nearestBody.body.x, nearestBody.body.y)
        table.insert(allies, ally)
        
        table.remove(deadBodies, nearestBody.index)
        
        return true
    end
    
    return false
end

function Player:addGold(amount)
    self.gold = self.gold + amount
end

-- ============================================================================
-- ALLY CLASS
-- ============================================================================
Ally = {}
Ally.__index = Ally
setmetatable(Ally, { __index = Unit })

function Ally.new(spriteSheet, x, y)
    local stats = Config.ALLY_STATS
    local self = Unit.new(spriteSheet, x, y, {
        maxHealth = stats.maxHealth,
        attack = stats.attack,
        speed = stats.speed,
        attackRange = stats.attackRange,
        attackCooldown = stats.attackCooldown,
        collisionRadius = stats.collisionRadius,
        isPlayer = false,
        isAlly = true,
        outlineColor = Config.ALLY_OUTLINE,
        typeName = "Ally"
    })
    setmetatable(self, Ally)
    self.followDistance = stats.followDistance
    return self
end

function Ally:update(dt, player, enemies)
    if self.isDead then return end
    
    if self.state == "attack" then
        Unit.update(self, dt)
        return
    end
    
    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end
    
    local closestEnemy = nil
    local closestEnemyDist = 200
    
    for _, enemy in ipairs(enemies) do
        if not enemy.isDead then
            local dist = self:getDistance(enemy)
            if dist < closestEnemyDist then
                closestEnemyDist = dist
                closestEnemy = enemy
            end
        end
    end
    
    if closestEnemy and closestEnemyDist <= self.attackRange then
        if self.attackTimer <= 0 then
            self:startAttack(closestEnemy)
        else
            self.state = "idle"
            self.currentAnimation = self.animations.idle
        end
    elseif closestEnemy and closestEnemyDist < 200 then
        self.state = "walk"
        self.currentAnimation = self.animations.walk
        self:moveTo(closestEnemy.x, closestEnemy.y, dt)
    else
        local distToPlayer = self:getDistance(player)
        if distToPlayer > self.followDistance then
            self.state = "walk"
            self.currentAnimation = self.animations.walk
            self:moveTo(player.x, player.y, dt)
        else
            self.state = "idle"
            self.currentAnimation = self.animations.idle
        end
    end
    
    self.currentAnimation:update(dt)
end

-- ============================================================================
-- ENEMY CLASS
-- ============================================================================
local Enemy = {}
Enemy.__index = Enemy
setmetatable(Enemy, { __index = Unit })

function Enemy.new(spriteSheet, x, y, enemyType)
    enemyType = enemyType or "normal"
    local typeConfig = Config.ENEMY_TYPES[enemyType] or Config.ENEMY_TYPES.normal
    
    local self = Unit.new(spriteSheet, x, y, {
        maxHealth = typeConfig.maxHealth,
        attack = typeConfig.attack,
        speed = typeConfig.speed,
        attackRange = typeConfig.attackRange,
        attackCooldown = typeConfig.attackCooldown,
        collisionRadius = typeConfig.collisionRadius,
        isPlayer = false,
        outlineColor = typeConfig.outline,
        typeName = typeConfig.name
    })
    setmetatable(self, Enemy)
    self.aggroRange = typeConfig.aggroRange
    self.enemyType = enemyType
    
    -- Gold dropped on death
    if enemyType == "normal" then
        self.goldValue = 10
    elseif enemyType == "berserker" or enemyType == "speedster" then
        self.goldValue = 25
    elseif enemyType == "tank" then
        self.goldValue = 30
    elseif enemyType == "elite" then
        self.goldValue = 50
    else
        self.goldValue = 10
    end
    
    return self
end

function Enemy:update(dt, player, allies)
    if self.isDead then return end
    
    if self.state == "attack" then
        Unit.update(self, dt)
        return
    end
    
    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end
    
    local nearestTarget = nil
    local nearestDist = self.aggroRange
    
    if not player.isDead then
        local dist = self:getDistance(player)
        if dist < nearestDist then
            nearestDist = dist
            nearestTarget = player
        end
    end
    
    for _, ally in ipairs(allies) do
        if not ally.isDead then
            local dist = self:getDistance(ally)
            if dist < nearestDist then
                nearestDist = dist
                nearestTarget = ally
            end
        end
    end
    
    if nearestTarget then
        if nearestDist <= self.attackRange then
            if self.attackTimer <= 0 then
                self:startAttack(nearestTarget)
            else
                self.state = "idle"
                self.currentAnimation = self.animations.idle
            end
        else
            self.state = "walk"
            self.currentAnimation = self.animations.walk
            self:moveTo(nearestTarget.x, nearestTarget.y, dt)
        end
    else
        self.state = "idle"
        self.currentAnimation = self.animations.idle
    end
    
    self.currentAnimation:update(dt)
end

-- Helper to pick random enemy type based on weights
function Enemy.getRandomType()
    local totalWeight = 0
    for _, typeConfig in pairs(Config.ENEMY_TYPES) do
        totalWeight = totalWeight + typeConfig.spawnWeight
    end
    
    local roll = math.random() * totalWeight
    local cumulative = 0
    
    for typeName, typeConfig in pairs(Config.ENEMY_TYPES) do
        cumulative = cumulative + typeConfig.spawnWeight
        if roll <= cumulative then
            return typeName
        end
    end
    
    return "normal"
end

return {
    Unit = Unit,
    Player = Player,
    Ally = Ally,
    Enemy = Enemy
}

