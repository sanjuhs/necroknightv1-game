-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║          LEGEND OF THE NECRO-KNIGHT                                       ║
-- ║          A 2D Top-Down Auto Battler                                       ║
-- ║          Made with Love2D                                                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- Load modules
local Config = require("src.config")
local Units = require("src.units")
local World = require("src.world")
local Collision = require("src.collision")
local Minimap = require("src.minimap")
local UI = require("src.ui")
local Menu = require("src.menu")
local SaveGame = require("src.savegame")
local Formation = require("src.formation")
local Editor = require("editor.editor")

-- Shortcuts
local Player = Units.Player
local Enemy = Units.Enemy
local Ally = Units.Ally
local DeadBody = World.DeadBody
local Tilemap = World.Tilemap
local Tree = World.Tree
local UpgradeStation = World.UpgradeStation
local Building = World.Building
local GoldResource = World.GoldResource
local Projectile = World.Projectile
local HealEffect = World.HealEffect

-- Game state
local game = {
    camera = { x = 0, y = 0 },
    player = nil,
    enemies = {},
    allies = {},
    deadBodies = {},
    tilemap = nil,
    trees = {},
    upgradeStations = {},
    buildings = {},      -- Capturable buildings
    goldResources = {},  -- Gold for pawns to collect
    projectiles = {},    -- Active projectiles (arrows)
    healEffects = {},    -- Visual heal effects
    minimap = nil,
    menu = nil,
    assets = {},  -- All loaded assets
    initialized = false,
    formation = Formation.LINE,  -- Current formation (1=Line, 2=Box, 3=Staggered, 4=Flank)
    formationPositions = {}      -- Calculated positions for each ally
}

-- ============================================================================
-- CAMERA
-- ============================================================================
local function updateCamera(targetX, targetY, screenW, screenH)
    local smoothing = 0.1
    game.camera.x = game.camera.x + (targetX - screenW / 2 - game.camera.x) * smoothing
    game.camera.y = game.camera.y + (targetY - screenH / 2 - game.camera.y) * smoothing
    
    game.camera.x = math.max(0, math.min(game.camera.x, Config.WORLD_WIDTH * Config.TILE_SIZE - screenW))
    game.camera.y = math.max(0, math.min(game.camera.y, Config.WORLD_HEIGHT * Config.TILE_SIZE - screenH))
end

-- ============================================================================
-- ASSET LOADING
-- ============================================================================
local function loadAssets()
    game.assets = {}
    
    -- Load Blue Warrior animations (for player and allies)
    game.assets.warriorBlue = {
        idle = love.graphics.newImage(Config.WARRIOR_BLUE_PATH .. "Warrior_Idle.png"),
        run = love.graphics.newImage(Config.WARRIOR_BLUE_PATH .. "Warrior_Run.png"),
        attack1 = love.graphics.newImage(Config.WARRIOR_BLUE_PATH .. "Warrior_Attack1.png"),
        attack2 = love.graphics.newImage(Config.WARRIOR_BLUE_PATH .. "Warrior_Attack2.png"),
        guard = love.graphics.newImage(Config.WARRIOR_BLUE_PATH .. "Warrior_Guard.png")
    }
    
    -- Load Red Warrior animations (for enemies)
    game.assets.warriorRed = {
        idle = love.graphics.newImage(Config.WARRIOR_RED_PATH .. "Warrior_Idle.png"),
        run = love.graphics.newImage(Config.WARRIOR_RED_PATH .. "Warrior_Run.png"),
        attack1 = love.graphics.newImage(Config.WARRIOR_RED_PATH .. "Warrior_Attack1.png"),
        attack2 = love.graphics.newImage(Config.WARRIOR_RED_PATH .. "Warrior_Attack2.png"),
        guard = love.graphics.newImage(Config.WARRIOR_RED_PATH .. "Warrior_Guard.png")
    }
    
    -- Load Blue Archer animations
    game.assets.archerBlue = {
        idle = love.graphics.newImage(Config.ARCHER_BLUE_PATH .. "Archer_Idle.png"),
        run = love.graphics.newImage(Config.ARCHER_BLUE_PATH .. "Archer_Run.png"),
        attack1 = love.graphics.newImage(Config.ARCHER_BLUE_PATH .. "Archer_Shoot.png")
    }
    
    -- Load Red Archer animations
    game.assets.archerRed = {
        idle = love.graphics.newImage(Config.ARCHER_RED_PATH .. "Archer_Idle.png"),
        run = love.graphics.newImage(Config.ARCHER_RED_PATH .. "Archer_Run.png"),
        attack1 = love.graphics.newImage(Config.ARCHER_RED_PATH .. "Archer_Shoot.png")
    }
    
    -- Load Blue Monk animations
    game.assets.monkBlue = {
        idle = love.graphics.newImage(Config.MONK_BLUE_PATH .. "Idle.png"),
        run = love.graphics.newImage(Config.MONK_BLUE_PATH .. "Run.png"),
        attack1 = love.graphics.newImage(Config.MONK_BLUE_PATH .. "Heal.png")
    }
    
    -- Load Red Monk animations
    game.assets.monkRed = {
        idle = love.graphics.newImage(Config.MONK_RED_PATH .. "Idle.png"),
        run = love.graphics.newImage(Config.MONK_RED_PATH .. "Run.png"),
        attack1 = love.graphics.newImage(Config.MONK_RED_PATH .. "Heal.png")
    }
    
    -- Load Blue Pawn animations
    game.assets.pawnBlue = {
        idle = love.graphics.newImage(Config.PAWN_BLUE_PATH .. "Pawn_Idle.png"),
        run = love.graphics.newImage(Config.PAWN_BLUE_PATH .. "Pawn_Run.png"),
        attack1 = love.graphics.newImage(Config.PAWN_BLUE_PATH .. "Pawn_Interact Pickaxe.png")
    }
    
    -- Load Red Pawn animations
    game.assets.pawnRed = {
        idle = love.graphics.newImage(Config.PAWN_RED_PATH .. "Pawn_Idle.png"),
        run = love.graphics.newImage(Config.PAWN_RED_PATH .. "Pawn_Run.png"),
        attack1 = love.graphics.newImage(Config.PAWN_RED_PATH .. "Pawn_Interact Pickaxe.png")
    }
    
    -- Load Building assets
    game.assets.buildings = {
        blue = {
            barracks = love.graphics.newImage(Config.BUILDINGS_BLUE_PATH .. "Barracks.png"),
            archery = love.graphics.newImage(Config.BUILDINGS_BLUE_PATH .. "Archery.png"),
            monastery = love.graphics.newImage(Config.BUILDINGS_BLUE_PATH .. "Monastery.png"),
            house = love.graphics.newImage(Config.BUILDINGS_BLUE_PATH .. "House1.png")
        },
        red = {
            barracks = love.graphics.newImage(Config.BUILDINGS_RED_PATH .. "Barracks.png"),
            archery = love.graphics.newImage(Config.BUILDINGS_RED_PATH .. "Archery.png"),
            monastery = love.graphics.newImage(Config.BUILDINGS_RED_PATH .. "Monastery.png"),
            house = love.graphics.newImage(Config.BUILDINGS_RED_PATH .. "House1.png")
        }
    }
    
    -- Load terrain assets (Tilemap_color2 has nicer grass coloring)
    game.assets.tileset = love.graphics.newImage(Config.TILESET_PATH .. "Tilemap_color2.png")
    
    -- Load tree assets (4 variants)
    game.assets.trees = {
        love.graphics.newImage(Config.TREES_PATH .. "Tree1.png"),
        love.graphics.newImage(Config.TREES_PATH .. "Tree2.png"),
        love.graphics.newImage(Config.TREES_PATH .. "Tree3.png"),
        love.graphics.newImage(Config.TREES_PATH .. "Tree4.png")
    }
    
    -- Load gold resource
    game.assets.gold = love.graphics.newImage(Config.GOLD_PATH .. "Gold Stone 1.png")
    
    -- Load projectile assets
    game.assets.arrow = love.graphics.newImage(Config.ARCHER_BLUE_PATH .. "Arrow.png")
    
    print("Assets loaded from Tiny_Swords_Free_Pack!")
end

-- Helper to get unit assets by class type
local function getUnitAssets(unitClass, team)
    team = team or "blue"
    if unitClass == "warrior" then
        return team == "blue" and game.assets.warriorBlue or game.assets.warriorRed
    elseif unitClass == "archer" then
        return team == "blue" and game.assets.archerBlue or game.assets.archerRed
    elseif unitClass == "monk" then
        return team == "blue" and game.assets.monkBlue or game.assets.monkRed
    elseif unitClass == "pawn" then
        return team == "blue" and game.assets.pawnBlue or game.assets.pawnRed
    end
    return team == "blue" and game.assets.warriorBlue or game.assets.warriorRed
end

-- ============================================================================
-- GAME INITIALIZATION
-- ============================================================================
local function initNewGame()
    -- Create tilemap
    game.tilemap = Tilemap.new(game.assets.tileset, Config.TILE_SIZE)
    
    -- Create player at center
    local startX = Config.WORLD_WIDTH * Config.TILE_SIZE / 2
    local startY = Config.WORLD_HEIGHT * Config.TILE_SIZE / 2
    game.player = Player.new(game.assets.warriorBlue, startX, startY)
    
    -- Clear state
    game.enemies = {}
    game.allies = {}
    game.deadBodies = {}
    game.trees = {}
    game.upgradeStations = {}
    game.buildings = {}
    game.goldResources = {}
    game.projectiles = {}
    game.healEffects = {}
    
    -- Create minimap
    game.minimap = Minimap.new()
    
    -- Scatter trees
    math.randomseed(42)
    for i = 1, 60 do  -- Reduced trees to make room for buildings
        local tx = math.random(2, Config.WORLD_WIDTH - 2) * Config.TILE_SIZE + Config.TILE_SIZE / 2
        local ty = math.random(2, Config.WORLD_HEIGHT - 2) * Config.TILE_SIZE + Config.TILE_SIZE / 2
        local variant = math.random(1, 4)
        local tree = Tree.new(game.assets.trees, tx, ty, variant)
        tree.collisionRadius = 25  -- Add collision radius for trees
        table.insert(game.trees, tree)
    end
    
    -- Create buildings around the map
    local buildingPositions = {
        { type = "barracks", x = startX + 600, y = startY - 400 },
        { type = "barracks", x = startX - 600, y = startY + 400 },
        { type = "archery", x = startX + 500, y = startY + 500 },
        { type = "archery", x = startX - 500, y = startY - 500 },
        { type = "monastery", x = startX + 700, y = startY },
        { type = "house", x = startX - 400, y = startY - 300 },
        { type = "house", x = startX + 400, y = startY + 300 },
        { type = "house", x = startX, y = startY + 600 }
    }
    
    for _, pos in ipairs(buildingPositions) do
        local bx = math.max(150, math.min(pos.x, Config.WORLD_WIDTH * Config.TILE_SIZE - 150))
        local by = math.max(150, math.min(pos.y, Config.WORLD_HEIGHT * Config.TILE_SIZE - 150))
        
        local building = Building.new(
            bx, by, pos.type, "neutral",
            game.assets.buildings.blue[pos.type],
            game.assets.buildings.red[pos.type]
        )
        table.insert(game.buildings, building)
    end
    
    -- Create gold resources
    math.randomseed(77)
    for i = 1, 8 do
        local gx = math.random(3, Config.WORLD_WIDTH - 3) * Config.TILE_SIZE
        local gy = math.random(3, Config.WORLD_HEIGHT - 3) * Config.TILE_SIZE
        table.insert(game.goldResources, GoldResource.new(gx, gy, game.assets.gold))
    end
    
    -- Create enemies
    math.randomseed(123)
    
    -- Spawn normal warrior enemies
    for i = 1, 8 do
        local ex, ey
        repeat
            ex = math.random(3, Config.WORLD_WIDTH - 3) * Config.TILE_SIZE
            ey = math.random(3, Config.WORLD_HEIGHT - 3) * Config.TILE_SIZE
        until math.sqrt((ex - startX)^2 + (ey - startY)^2) > 400
        
        table.insert(game.enemies, Enemy.new(game.assets.warriorRed, ex, ey, "normal"))
    end
    
    -- Spawn archer enemies
    for i = 1, 4 do
        local ex, ey
        repeat
            ex = math.random(3, Config.WORLD_WIDTH - 3) * Config.TILE_SIZE
            ey = math.random(3, Config.WORLD_HEIGHT - 3) * Config.TILE_SIZE
        until math.sqrt((ex - startX)^2 + (ey - startY)^2) > 450
        
        local enemy = Enemy.new(game.assets.archerRed, ex, ey, "normal")
        enemy.unitClass = "archer"
        table.insert(game.enemies, enemy)
    end
    
    -- Spawn special enemies
    local specialTypes = {"berserker", "tank", "speedster", "elite"}
    for _, enemyType in ipairs(specialTypes) do
        local count = (enemyType == "elite") and 1 or 2
        for i = 1, count do
            local ex, ey
            repeat
                ex = math.random(3, Config.WORLD_WIDTH - 3) * Config.TILE_SIZE
                ey = math.random(3, Config.WORLD_HEIGHT - 3) * Config.TILE_SIZE
            until math.sqrt((ex - startX)^2 + (ey - startY)^2) > 500
            
            table.insert(game.enemies, Enemy.new(game.assets.warriorRed, ex, ey, enemyType))
        end
    end
    
    -- TEST: Spawn some enemies nearby for quick testing
    table.insert(game.enemies, Enemy.new(game.assets.warriorRed, startX + 150, startY + 100, "berserker"))
    table.insert(game.enemies, Enemy.new(game.assets.warriorRed, startX - 150, startY + 100, "tank"))
    
    -- Create upgrade stations
    local upgradeTypes = {"health", "attack", "speed", "rp"}
    for i, upgradeType in ipairs(upgradeTypes) do
        local angle = (i - 1) * math.pi / 2 + math.pi / 4
        local dist = 900
        local ux = startX + math.cos(angle) * dist
        local uy = startY + math.sin(angle) * dist
        
        ux = math.max(200, math.min(ux, Config.WORLD_WIDTH * Config.TILE_SIZE - 200))
        uy = math.max(200, math.min(uy, Config.WORLD_HEIGHT * Config.TILE_SIZE - 200))
        
        table.insert(game.upgradeStations, UpgradeStation.new(ux, uy, upgradeType))
    end
    
    -- Initialize camera
    game.camera.x = startX - love.graphics.getWidth() / 2
    game.camera.y = startY - love.graphics.getHeight() / 2
    
    game.initialized = true
end

-- Spawn a unit from a building
local function spawnUnitFromBuilding(building)
    local unitClass = building.config.unitType
    local assets = getUnitAssets(unitClass, "blue")
    
    -- Create ally with appropriate class
    local ally = Ally.new(assets, building.x, building.y + 50, nil)
    ally.unitClass = unitClass
    
    -- Apply class-specific stats
    local classConfig = Config.UNIT_CLASSES[unitClass]
    if classConfig then
        ally.maxHealth = classConfig.maxHealth
        ally.health = classConfig.maxHealth
        ally.attack = classConfig.attack
        ally.speed = classConfig.speed
        ally.attackRange = classConfig.attackRange
        ally.attackCooldown = classConfig.attackCooldown
        ally.offsetX = classConfig.offsetX
        ally.offsetY = classConfig.offsetY
        ally.collisionRadius = classConfig.collisionRadius or 28
        
        -- Set attack type for special abilities
        ally.attackType = classConfig.attackType
        
        -- Archer-specific: projectile speed
        if classConfig.attackType == "ranged" then
            ally.projectileSpeed = classConfig.projectileSpeed or 500
        end
        
        -- Monk-specific: healing properties
        if classConfig.attackType == "heal" then
            ally.healAmount = classConfig.healAmount or 30
            ally.healRange = classConfig.healRange or 180
            ally.healCooldown = classConfig.healCooldown or 4.0
            ally.healTimer = 0
        end
    end
    
    -- Set class label and outline color
    if unitClass == "archer" then
        ally.typeLabel = "A"
        ally.outlineColor = {0.2, 0.8, 0.2, 0.8}  -- Green for archers
        ally.scale = 0.8  -- Archers are smaller sprites
    elseif unitClass == "monk" then
        ally.typeLabel = "M"
        ally.outlineColor = {0.9, 0.9, 0.3, 0.8}  -- Yellow for monks
        ally.scale = 0.85  -- Monks are smaller sprites
    elseif unitClass == "pawn" then
        ally.typeLabel = "P"
        ally.outlineColor = {0.6, 0.4, 0.2, 0.8}  -- Brown for pawns
        ally.scale = 0.75  -- Pawns are smaller sprites
    else
        ally.typeLabel = "W"
        ally.outlineColor = Config.ALLY_OUTLINE
    end
    
    table.insert(game.allies, ally)
end

local function loadSavedGame()
    local data, err = SaveGame.load()
    if not data then
        print("Failed to load game: " .. (err or "unknown error"))
        initNewGame()
        return
    end
    
    -- Initialize basic structures first
    game.tilemap = Tilemap.new(game.assets.tileset, Config.TILE_SIZE)
    game.minimap = Minimap.new()
    game.enemies = {}
    game.allies = {}
    game.deadBodies = {}
    game.trees = {}
    game.upgradeStations = {}
    game.buildings = {}
    game.goldResources = {}
    
    -- Recreate trees (same seed)
    math.randomseed(42)
    for i = 1, 60 do
        local tx = math.random(2, Config.WORLD_WIDTH - 2) * Config.TILE_SIZE + Config.TILE_SIZE / 2
        local ty = math.random(2, Config.WORLD_HEIGHT - 2) * Config.TILE_SIZE + Config.TILE_SIZE / 2
        local variant = math.random(1, 4)
        table.insert(game.trees, Tree.new(game.assets.trees, tx, ty, variant))
    end
    
    -- Load player
    game.player = Player.new(game.assets.warriorBlue, data.player.x, data.player.y)
    game.player.health = data.player.health
    game.player.maxHealth = data.player.maxHealth
    game.player.attack = data.player.attack
    game.player.speed = data.player.speed
    game.player.rp = data.player.rp
    game.player.maxRP = data.player.maxRP
    game.player.gold = data.player.gold
    
    -- Load enemies
    for _, enemyData in ipairs(data.enemies) do
        local enemy = Enemy.new(game.assets.warriorRed, enemyData.x, enemyData.y, enemyData.enemyType)
        enemy.health = enemyData.health
        table.insert(game.enemies, enemy)
    end
    
    -- Load allies
    for _, allyData in ipairs(data.allies) do
        local ally = Ally.new(game.assets.warriorBlue, allyData.x, allyData.y)
        ally.health = allyData.health
        table.insert(game.allies, ally)
    end
    
    -- Load dead bodies
    for _, bodyData in ipairs(data.deadBodies) do
        local body = DeadBody.new(bodyData.x, bodyData.y, nil)
        body.reviveTimer = bodyData.reviveTimer
        body.state = "skull"
        table.insert(game.deadBodies, body)
    end
    
    -- Load upgrade stations
    for _, stationData in ipairs(data.upgradeStations) do
        table.insert(game.upgradeStations, UpgradeStation.new(stationData.x, stationData.y, stationData.upgradeType))
    end
    
    -- Load revealed tiles
    if data.revealedTiles then
        for y, row in pairs(data.revealedTiles) do
            for x, revealed in pairs(row) do
                if game.minimap.revealed[tonumber(y)] then
                    game.minimap.revealed[tonumber(y)][tonumber(x)] = revealed
                end
            end
        end
    end
    
    -- Initialize camera
    game.camera.x = data.player.x - love.graphics.getWidth() / 2
    game.camera.y = data.player.y - love.graphics.getHeight() / 2
    
    game.initialized = true
    print("Game loaded successfully!")
end

local function saveCurrentGame()
    local success, err = SaveGame.save(game)
    if success then
        print("Game saved successfully!")
        game.menu:checkSaveFile()
    else
        print("Failed to save game: " .. (err or "unknown error"))
    end
end

-- ============================================================================
-- LOVE2D CALLBACKS
-- ============================================================================
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setBackgroundColor(0.05, 0.08, 0.12)
    
    -- Load assets
    loadAssets()
    
    -- Create menu
    game.menu = Menu.new()
end

function love.update(dt)
    -- Update editor if active
    if Editor.active then
        Editor.update(dt)
        return
    end
    
    -- Update menu
    game.menu:update(dt)
    
    -- Only update game if playing
    if not game.menu:isPlaying() or not game.initialized then
        return
    end
    
    -- Update player
    game.player:update(dt, game.enemies, game.allies)
    
    -- Calculate formation positions for allies
    local aliveAllies = {}
    for _, ally in ipairs(game.allies) do
        if not ally.isDead then
            table.insert(aliveAllies, ally)
        end
    end
    
    game.formationPositions = Formation.getPositions(
        game.formation,
        game.player.x,
        game.player.y,
        game.player.facingRight,
        #aliveAllies,
        80  -- spacing
    )
    
    -- Update allies with their formation positions
    local aliveIndex = 1
    for _, ally in ipairs(game.allies) do
        if not ally.isDead then
            local formationPos = game.formationPositions[aliveIndex]
            ally:update(dt, game.player, game.enemies, formationPos, game.allies)
            
            -- Check if ally needs to spawn a projectile (archers)
            if ally.needsProjectile then
                local projectile = Projectile.new(
                    ally.x, ally.y - 60,
                    ally.projectileTargetX, ally.projectileTargetY,
                    ally.attack,
                    ally.projectileSpeed or 500,
                    ally,
                    game.assets.arrow
                )
                table.insert(game.projectiles, projectile)
                ally.needsProjectile = false
            end
            
            -- Check if ally needs to spawn a heal effect (monks)
            if ally.needsHealEffect then
                local effect = HealEffect.new(ally.healEffectX, ally.healEffectY)
                table.insert(game.healEffects, effect)
                ally.needsHealEffect = false
            end
            
            aliveIndex = aliveIndex + 1
        end
    end
    
    -- Update enemies
    for i = #game.enemies, 1, -1 do
        local enemy = game.enemies[i]
        enemy:update(dt, game.player, game.allies)
        
        -- Check if enemy archer needs to spawn a projectile
        if enemy.needsProjectile then
            local projectile = Projectile.new(
                enemy.x, enemy.y - 60,
                enemy.projectileTargetX, enemy.projectileTargetY,
                enemy.attack,
                enemy.projectileSpeed or 400,
                enemy,
                game.assets.arrow
            )
            table.insert(game.projectiles, projectile)
            enemy.needsProjectile = false
        end
        
        if enemy.isDead then
            game.player:addGold(enemy.goldValue or 10)
            table.insert(game.deadBodies, DeadBody.new(enemy.x, enemy.y, nil, enemy.goldValue, enemy.enemyType))
            table.remove(game.enemies, i)
        end
    end
    
    -- Update projectiles
    for i = #game.projectiles, 1, -1 do
        local proj = game.projectiles[i]
        proj:update(dt, game.enemies, game.player, game.allies)
        if proj.isDead then
            table.remove(game.projectiles, i)
        end
    end
    
    -- Update heal effects
    for i = #game.healEffects, 1, -1 do
        local effect = game.healEffects[i]
        effect:update(dt)
        if effect.isDead then
            table.remove(game.healEffects, i)
        end
    end
    
    -- Update dead bodies
    for i = #game.deadBodies, 1, -1 do
        local body = game.deadBodies[i]
        body:update(dt)
        
        if not body.canRevive and body.state == "skull" then
            table.remove(game.deadBodies, i)
        end
    end
    
    -- Check for dead allies
    for i = #game.allies, 1, -1 do
        if game.allies[i].isDead then
            table.remove(game.allies, i)
        end
    end
    
    -- Update buildings and spawn units
    for _, building in ipairs(game.buildings) do
        local shouldSpawn = building:update(dt, game.player, game.allies)
        if shouldSpawn then
            spawnUnitFromBuilding(building)
        end
    end
    
    -- Update gold resources
    for _, gold in ipairs(game.goldResources) do
        gold:update(dt)
    end
    
    -- Update upgrade stations
    for _, station in ipairs(game.upgradeStations) do
        station:update(dt)
    end
    
    -- Update trees (for animation)
    for _, tree in ipairs(game.trees) do
        tree:update(dt)
    end
    
    -- Resolve collisions between units
    local allUnits = { game.player }
    for _, enemy in ipairs(game.enemies) do
        table.insert(allUnits, enemy)
    end
    for _, ally in ipairs(game.allies) do
        table.insert(allUnits, ally)
    end
    Collision.resolveAll(allUnits)
    
    -- Resolve collisions with obstacles (trees)
    Collision.resolveWithObstacles(allUnits, game.trees)
    
    -- Resolve collisions with buildings
    Collision.resolveWithBuildings(allUnits, game.buildings)
    
    -- Update camera
    updateCamera(game.player.x, game.player.y, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Update minimap
    game.minimap:update(game.player.x, game.player.y)
end

function love.draw()
    -- Draw editor if active
    if Editor.active then
        Editor.draw()
        return
    end
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Draw game world if playing and initialized
    if game.menu:isPlaying() and game.initialized then
        love.graphics.push()
        love.graphics.translate(-math.floor(game.camera.x), -math.floor(game.camera.y))
        
        -- Draw tilemap
        game.tilemap:draw(game.camera.x, game.camera.y, screenW, screenH)
        
        -- Draw gold resources
        for _, gold in ipairs(game.goldResources) do
            gold:draw()
        end
        
        -- Draw upgrade stations
        for _, station in ipairs(game.upgradeStations) do
            station:draw()
        end
        
        -- Draw dead bodies
        for _, body in ipairs(game.deadBodies) do
            body:draw()
        end
        
        -- Collect and sort entities (buildings, trees, units)
        local entities = {}
        
        -- Add buildings
        for _, building in ipairs(game.buildings) do
            table.insert(entities, { obj = building, y = building.y })
        end
        
        -- Add trees
        for _, tree in ipairs(game.trees) do
            table.insert(entities, { obj = tree, y = tree.y })
        end
        
        -- Add player
        if not game.player.isDead then
            table.insert(entities, { obj = game.player, y = game.player.y })
        end
        
        -- Add enemies
        for _, enemy in ipairs(game.enemies) do
            if not enemy.isDead then
                table.insert(entities, { obj = enemy, y = enemy.y })
            end
        end
        
        -- Add allies
        for _, ally in ipairs(game.allies) do
            if not ally.isDead then
                table.insert(entities, { obj = ally, y = ally.y })
            end
        end
        
        -- Sort by Y position for proper depth
        table.sort(entities, function(a, b) return a.y < b.y end)
        
        -- Draw all entities
        for _, entity in ipairs(entities) do
            entity.obj:draw()
        end
        
        -- Draw projectiles (arrows)
        for _, proj in ipairs(game.projectiles) do
            proj:draw()
        end
        
        -- Draw heal effects
        for _, effect in ipairs(game.healEffects) do
            effect:draw()
        end
        
        -- Draw prompts
        for _, body in ipairs(game.deadBodies) do
            if body.canRevive and body.state == "skull" then
                local dx = body.x - game.player.x
                local dy = body.y - game.player.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist < 100 and game.player.rp >= game.player.reviveCost then
                    love.graphics.setColor(1, 1, 0.5)
                    love.graphics.print("[E] Revive", body.x - 30, body.y - 140)
                    love.graphics.setColor(1, 1, 1)
                end
            end
        end
        
        -- Draw building prompts
        for _, building in ipairs(game.buildings) do
            building:drawPrompt(game.player)
        end
        
        for _, station in ipairs(game.upgradeStations) do
            station:drawPrompt(game.player)
        end
        
        love.graphics.pop()
        
        -- Draw UI
        UI.draw(game)
        
        -- Draw minimap if enabled
        local settings = game.menu:getSettings()
        if settings.showMinimap then
            game.minimap:draw(game.player, game.enemies, game.allies, game.trees, game.upgradeStations)
        end
        
        -- Draw FPS if enabled
        if settings.showFPS then
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.print("FPS: " .. love.timer.getFPS(), screenW - 80, screenH - 25)
            love.graphics.setColor(1, 1, 1)
        end
        
        -- Draw ally count
        love.graphics.setColor(0.8, 0.9, 1, 0.9)
        love.graphics.print("Allies: " .. #game.allies, 10, screenH - 50)
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Draw menu on top
    if not game.menu:isPlaying() then
        game.menu:draw()
    end
end

function love.keypressed(key)
    -- Handle menu input
    local action = game.menu:keypressed(key, game)
    
    if action == "start_new_game" then
        initNewGame()
    elseif action == "load_game" then
        loadSavedGame()
    elseif action == "save_game" then
        saveCurrentGame()
    elseif action == "quit_to_menu" then
        game.initialized = false
    elseif action == "open_editor" then
        Editor.init()
    end
    
    -- Editor keypresses
    if Editor.active then
        Editor.keypressed(key)
        return
    end
    
    -- Game input (only when playing)
    if game.menu:isPlaying() and game.initialized then
        if key == "escape" then
            game.menu:pause()
        elseif key == "e" and not game.player.isDead then
            game.player:tryRevive(game.deadBodies, game.allies, game.assets.warriorBlue)
        elseif key == "f" and not game.player.isDead then
            for i, station in ipairs(game.upgradeStations) do
                if station:tryUpgrade(game.player) then
                    table.remove(game.upgradeStations, i)
                    break
                end
            end
        elseif key == "r" and game.player.isDead then
            initNewGame()
        -- Formation keybindings
        elseif key == "1" then
            game.formation = Formation.LINE
        elseif key == "2" then
            game.formation = Formation.BOX
        elseif key == "3" then
            game.formation = Formation.STAGGERED
        elseif key == "4" then
            game.formation = Formation.FLANK
        end
    end
end

function love.mousepressed(x, y, button)
    if Editor.active then
        Editor.mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if Editor.active then
        Editor.mousereleased(x, y, button)
    end
end

function love.wheelmoved(x, y)
    if Editor.active then
        Editor.wheelmoved(x, y)
    end
end
