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

-- Create a unit with animation sheets passed as a table
-- animationSheets: { idle = image, run = image, attack1 = image, attack2 = image, guard = image }
function Unit.new(animationSheets, x, y, config)
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
    
    -- Frame dimensions for warrior (192x192 per frame)
    local frameW = config.frameWidth or 192
    local frameH = config.frameHeight or 192
    
    -- Create animations from separate sprite sheets
    -- Each sheet is a horizontal strip
    self.animations = {}
    
    -- Idle animation (8 frames)
    if animationSheets.idle then
        self.animations.idle = Animation.new(animationSheets.idle, frameW, frameH, 8)
    end
    
    -- Walk/Run animation (6 frames)
    if animationSheets.run then
        self.animations.walk = Animation.new(animationSheets.run, frameW, frameH, 6)
    end
    
    -- Attack animations (4 frames each)
    if animationSheets.attack1 then
        self.animations.attack_down = Animation.new(animationSheets.attack1, frameW, frameH, 4)
        self.animations.attack_down.loop = false
    end
    
    if animationSheets.attack2 then
        self.animations.attack_up = Animation.new(animationSheets.attack2, frameW, frameH, 4)
        self.animations.attack_up.loop = false
    else
        -- Fallback: use attack1 for both directions if attack2 not provided
        self.animations.attack_up = self.animations.attack_down
    end
    
    -- Guard animation (6 frames) - optional
    if animationSheets.guard then
        self.animations.guard = Animation.new(animationSheets.guard, frameW, frameH, 6)
    end
    
    self.currentAnimation = self.animations.idle
    self.animationSheets = animationSheets
    
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
    self.projectileSpawned = false  -- For ranged attacks
    
    local dy = target.y - self.y
    if dy < 0 and self.animations.attack_up then
        self.currentAnimation = self.animations.attack_up
    else
        self.currentAnimation = self.animations.attack_down
    end
    self.currentAnimation:reset()
    
    self.facingRight = target.x >= self.x
end

-- Start heal action for monks
function Unit:startHeal(target)
    self.state = "healing"
    self.healTarget = target
    self.healApplied = false
    self.currentAnimation = self.animations.attack_down  -- Use heal animation
    self.currentAnimation:reset()
end

function Unit:update(dt)
    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end
    if self.healTimer then
        self.healTimer = math.max(0, self.healTimer - dt)
    end
    
    -- Handle healing state
    if self.state == "healing" then
        self.currentAnimation:update(dt)
        
        -- Apply heal at middle of animation
        local healFrame = math.floor(self.currentAnimation.numFrames / 2)
        if self.currentAnimation.currentFrame >= healFrame and not self.healApplied then
            if self.healTarget and not self.healTarget.isDead then
                local healAmount = self.healAmount or 30
                self.healTarget.health = math.min(self.healTarget.maxHealth, self.healTarget.health + healAmount)
                self.healApplied = true
                self.needsHealEffect = true  -- Signal to spawn heal effect
                self.healEffectX = self.healTarget.x
                self.healEffectY = self.healTarget.y
            end
        end
        
        if self.currentAnimation.finished then
            self.state = "idle"
            self.healTimer = self.healCooldown or 4.0
            self.currentAnimation = self.animations.idle
            self.currentAnimation:reset()
        end
        return
    end
    
    if self.state == "attack" then
        self.currentAnimation:update(dt)
        
        -- For ranged attacks, spawn projectile at mid-animation
        if self.attackType == "ranged" then
            local shootFrame = math.floor(self.currentAnimation.numFrames * 0.6)
            if self.currentAnimation.currentFrame >= shootFrame and not self.projectileSpawned then
                if self.target and not self.target.isDead then
                    self.needsProjectile = true  -- Signal to spawn projectile
                    self.projectileTargetX = self.target.x
                    self.projectileTargetY = self.target.y
                    self.projectileSpawned = true
                end
            end
        else
            -- Melee: Deal damage at the LAST frame, ONLY ONCE
            if self.currentAnimation.currentFrame == self.currentAnimation.numFrames and not self.damageDealtThisAttack then
                if self.target and not self.target.isDead then
                    if self:getDistance(self.target) <= self.attackRange * 1.5 then
                        self.target:takeDamage(self.attack)
                        self.damageDealtThisAttack = true
                    end
                end
            end
        end
        
        if self.currentAnimation.finished then
            self.state = "idle"
            self.attackTimer = self.attackCooldown
            self.currentAnimation = self.animations.idle
            self.currentAnimation:reset()
            self.damageDealtThisAttack = false
            self.projectileSpawned = false
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
    local scale = self.scale or 1.0
    local offsetX = self.offsetX or 96
    local offsetY = self.offsetY or 144
    
    -- Draw black outline FIRST for player (behind everything)
    if self.isPlayer then
        self:drawSpriteOutline(scaleX, scale, offsetX, offsetY, {0, 0, 0, 1}, 8, false)
    end
    
    -- Draw colored outline around sprite if unit has an outline color
    if self.outlineColor then
        self:drawSpriteOutline(scaleX, scale, offsetX, offsetY, self.outlineColor, 5, true)
    end
    
    -- Draw the sprite with scale
    love.graphics.setColor(1, 1, 1, 1)
    self.currentAnimation:draw(self.x, self.y, scaleX * scale, scale, offsetX, offsetY)
    
    -- Draw type label for special units (enemies, allies, and player)
    if self.typeLabel then
        self:drawTypeLabel()
    end
    
    -- Draw player tag
    if self.isPlayer then
        self:drawPlayerTag()
    end
    
    -- Draw health bar
    self:drawHealthBar()
end

function Unit:drawTypeLabel()
    if not self.typeLabel then return end
    
    local labelY = self.y - 180  -- Above health bar
    local labelX = self.x
    
    -- Get color based on original enemy type
    local bgColor = self.outlineColor or {0.5, 0.5, 0.5, 1}
    
    -- Draw background circle
    local pulse = 0.8 + 0.2 * math.sin(love.timer.getTime() * 3)
    love.graphics.setColor(bgColor[1] * pulse, bgColor[2] * pulse, bgColor[3] * pulse, 0.95)
    love.graphics.circle("fill", labelX, labelY, 14)
    
    -- Draw border
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle("line", labelX, labelY, 14)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", labelX, labelY, 14)
    love.graphics.setLineWidth(1)
    
    -- Draw letter
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(self.typeLabel)
    local textHeight = font:getHeight()
    love.graphics.print(self.typeLabel, labelX - textWidth/2, labelY - textHeight/2)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Unit:drawPlayerTag()
    local tagY = self.y - 185  -- Above everything
    local tagX = self.x
    local tagText = "YOU"
    
    -- Floating animation
    local float = math.sin(love.timer.getTime() * 2) * 3
    tagY = tagY + float
    
    -- Pulsing glow
    local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 4)
    
    -- Draw glow behind
    love.graphics.setColor(1, 0.85, 0.2, 0.3 * pulse)
    love.graphics.circle("fill", tagX, tagY, 28)
    
    -- Draw background pill shape
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(tagText)
    local textHeight = font:getHeight()
    local paddingX = 12
    local paddingY = 6
    
    -- Background
    love.graphics.setColor(0.15, 0.12, 0.05, 0.9)
    love.graphics.rectangle("fill", tagX - textWidth/2 - paddingX, tagY - textHeight/2 - paddingY, 
                           textWidth + paddingX * 2, textHeight + paddingY * 2, 8, 8)
    
    -- Golden border
    love.graphics.setColor(1 * pulse, 0.85 * pulse, 0.2 * pulse, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", tagX - textWidth/2 - paddingX, tagY - textHeight/2 - paddingY, 
                           textWidth + paddingX * 2, textHeight + paddingY * 2, 8, 8)
    love.graphics.setLineWidth(1)
    
    -- Text
    love.graphics.setColor(1, 0.9, 0.4, 1)
    love.graphics.print(tagText, tagX - textWidth/2, tagY - textHeight/2)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Unit:drawSpriteOutline(scaleX, scale, offsetX, offsetY, color, outlineSize, useAdditive)
    outlineSize = outlineSize or 5
    useAdditive = useAdditive ~= false  -- Default to true
    
    local prevBlendMode = love.graphics.getBlendMode()
    if useAdditive then
        love.graphics.setBlendMode("add")
    end
    
    -- Pulsing intensity - more pronounced for colored outlines
    local pulse = useAdditive and (0.7 + 0.3 * math.sin(love.timer.getTime() * 4)) or 1.0
    
    local offsets = {
        -- Inner ring
        {-outlineSize, 0}, {outlineSize, 0}, 
        {0, -outlineSize}, {0, outlineSize},
        {-outlineSize, -outlineSize}, {outlineSize, -outlineSize},
        {-outlineSize, outlineSize}, {outlineSize, outlineSize},
        -- Outer ring for extra thickness
        {-outlineSize-1, 0}, {outlineSize+1, 0}, 
        {0, -outlineSize-1}, {0, outlineSize+1},
    }
    
    -- Draw outline copies with the color
    if useAdditive then
        love.graphics.setColor(color[1] * pulse * 1.2, color[2] * pulse * 1.2, color[3] * pulse * 1.2, 0.9)
    else
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 0.95)
    end
    
    for _, offset in ipairs(offsets) do
        self.currentAnimation:draw(
            self.x + offset[1], 
            self.y + offset[2], 
            scaleX * scale, scale, offsetX, offsetY
        )
    end
    
    -- Reset blend mode
    love.graphics.setBlendMode(prevBlendMode)
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

function Player.new(animationSheets, x, y)
    local stats = Config.PLAYER_STATS
    local self = Unit.new(animationSheets, x, y, {
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

function Player:tryRevive(deadBodies, allies, blueSheets)
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
        
        -- Create ally with the original enemy type characteristics
        local ally = Ally.new(blueSheets, nearestBody.body.x, nearestBody.body.y, nearestBody.body.enemyType)
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
-- ALLY CLASS (Revived enemies - retain original type characteristics)
-- ============================================================================
Ally = {}
Ally.__index = Ally
setmetatable(Ally, { __index = Unit })

function Ally.new(animationSheets, x, y, originalEnemyType)
    -- Get stats based on original enemy type, or use default ally stats
    local stats
    local outlineColor
    local typeName = "Ally"
    local typeLabel = nil  -- Short label like "B", "T", "S", "E"
    local scale = 1.0      -- Size scale
    
    if originalEnemyType and Config.ENEMY_TYPES[originalEnemyType] then
        -- Use the original enemy type's stats (slightly reduced for balance)
        local typeConfig = Config.ENEMY_TYPES[originalEnemyType]
        stats = {
            maxHealth = math.floor(typeConfig.maxHealth * 0.8),  -- 80% of original HP
            attack = math.floor(typeConfig.attack * 0.9),        -- 90% of original attack
            speed = typeConfig.speed,
            attackRange = typeConfig.attackRange,
            attackCooldown = typeConfig.attackCooldown,
            collisionRadius = typeConfig.collisionRadius,
            followDistance = 150
        }
        
        -- KEEP THE ORIGINAL OUTLINE COLOR (not blended)
        if typeConfig.outline then
            outlineColor = typeConfig.outline
            typeName = typeConfig.name
        else
            outlineColor = Config.ALLY_OUTLINE
            typeName = "Warrior"
        end
        
        -- Set label and scale based on type
        if originalEnemyType == "berserker" then
            typeLabel = "B"
            scale = 1.0
        elseif originalEnemyType == "tank" then
            typeLabel = "T"
            scale = 1.15  -- Bigger
        elseif originalEnemyType == "speedster" then
            typeLabel = "S"
            scale = 0.9   -- Smaller
        elseif originalEnemyType == "elite" then
            typeLabel = "E"
            scale = 1.1   -- Slightly bigger
        end
    else
        -- Default ally stats
        stats = Config.ALLY_STATS
        outlineColor = Config.ALLY_OUTLINE
        typeName = "Ally"
    end
    
    local self = Unit.new(animationSheets, x, y, {
        maxHealth = stats.maxHealth,
        attack = stats.attack,
        speed = stats.speed,
        attackRange = stats.attackRange,
        attackCooldown = stats.attackCooldown,
        collisionRadius = stats.collisionRadius,
        isPlayer = false,
        isAlly = true,
        outlineColor = outlineColor,
        typeName = typeName
    })
    setmetatable(self, Ally)
    self.followDistance = stats.followDistance or 150
    self.originalEnemyType = originalEnemyType  -- Store for save/load
    self.typeLabel = typeLabel  -- Short label like "B", "T", "S", "E"
    self.scale = scale          -- Size scale
    return self
end

function Ally:update(dt, player, enemies, formationPos, allAllies)
    if self.isDead then return end
    
    -- Handle healing and attack states through parent
    if self.state == "attack" or self.state == "healing" then
        Unit.update(self, dt)
        return
    end
    
    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end
    if self.healTimer then
        self.healTimer = math.max(0, self.healTimer - dt)
    end
    
    -- MONK BEHAVIOR: Prioritize healing wounded allies
    if self.attackType == "heal" then
        -- Find wounded ally or player to heal
        local healTarget = nil
        local lowestHealthPercent = 0.9  -- Only heal if below 90% health
        
        -- Check player first
        if not player.isDead and player.health / player.maxHealth < lowestHealthPercent then
            local dist = self:getDistance(player)
            if dist < (self.healRange or 180) then
                lowestHealthPercent = player.health / player.maxHealth
                healTarget = player
            end
        end
        
        -- Check allies
        if allAllies then
            for _, ally in ipairs(allAllies) do
                if ally ~= self and not ally.isDead then
                    local healthPercent = ally.health / ally.maxHealth
                    if healthPercent < lowestHealthPercent then
                        local dist = self:getDistance(ally)
                        if dist < (self.healRange or 180) then
                            lowestHealthPercent = healthPercent
                            healTarget = ally
                        end
                    end
                end
            end
        end
        
        -- Heal if we found a wounded target
        if healTarget and (self.healTimer or 0) <= 0 then
            self:startHeal(healTarget)
            return
        end
    end
    
    -- Find closest enemy within detection range
    local closestEnemy = nil
    local closestEnemyDist = self.attackType == "ranged" and 300 or 250
    
    for _, enemy in ipairs(enemies) do
        if not enemy.isDead then
            local dist = self:getDistance(enemy)
            if dist < closestEnemyDist then
                closestEnemyDist = dist
                closestEnemy = enemy
            end
        end
    end
    
    -- COMBAT: Attack if enemy in range
    if closestEnemy and closestEnemyDist <= self.attackRange then
        if self.attackTimer <= 0 then
            self:startAttack(closestEnemy)
        else
            self.state = "idle"
            self.currentAnimation = self.animations.idle
        end
    -- CHASE: Move toward enemy (ranged units keep distance)
    elseif closestEnemy then
        local chaseRange = self.attackType == "ranged" and 300 or 250
        if closestEnemyDist < chaseRange then
            -- Ranged units try to maintain distance
            if self.attackType == "ranged" and closestEnemyDist < self.attackRange * 0.5 then
                -- Back away from enemy
                local dx = self.x - closestEnemy.x
                local dy = self.y - closestEnemy.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist > 0 then
                    self.x = self.x + (dx / dist) * self.speed * dt
                    self.y = self.y + (dy / dist) * self.speed * dt
                end
                self.state = "walk"
                self.currentAnimation = self.animations.walk
            else
                self.state = "walk"
                self.currentAnimation = self.animations.walk
                self:moveTo(closestEnemy.x, closestEnemy.y, dt)
            end
        end
    -- FORMATION: Move to assigned formation position
    elseif formationPos then
        local distToFormation = math.sqrt((self.x - formationPos.x)^2 + (self.y - formationPos.y)^2)
        if distToFormation > 30 then
            self.state = "walk"
            self.currentAnimation = self.animations.walk
            self:moveTo(formationPos.x, formationPos.y, dt)
        else
            self.state = "idle"
            self.currentAnimation = self.animations.idle
        end
    -- FALLBACK: Follow player
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

function Enemy.new(animationSheets, x, y, enemyType)
    enemyType = enemyType or "normal"
    local typeConfig = Config.ENEMY_TYPES[enemyType] or Config.ENEMY_TYPES.normal
    
    local self = Unit.new(animationSheets, x, y, {
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
    
    -- Set label and scale based on enemy type (for visual differentiation)
    if enemyType == "berserker" then
        self.typeLabel = "B"
        self.scale = 1.0
    elseif enemyType == "tank" then
        self.typeLabel = "T"
        self.scale = 1.15  -- Bigger
    elseif enemyType == "speedster" then
        self.typeLabel = "S"
        self.scale = 0.9   -- Smaller
    elseif enemyType == "elite" then
        self.typeLabel = "E"
        self.scale = 1.1   -- Slightly bigger
    else
        self.typeLabel = nil  -- Normal enemies have no label
        self.scale = 1.0
    end
    
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
