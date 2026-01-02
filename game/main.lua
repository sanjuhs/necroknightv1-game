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

-- Shortcuts
local Player = Units.Player
local Enemy = Units.Enemy
local Ally = Units.Ally
local DeadBody = World.DeadBody
local Tilemap = World.Tilemap
local Tree = World.Tree
local UpgradeStation = World.UpgradeStation

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
    minimap = nil,
    menu = nil,
    spriteSheets = {},
    initialized = false
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
-- GAME INITIALIZATION
-- ============================================================================
local function loadAssets()
    game.spriteSheets.warriorBlue = love.graphics.newImage(Config.ASSETS_PATH .. "Factions/Knights/Troops/Warrior/Blue/Warrior_Blue.png")
    game.spriteSheets.warriorRed = love.graphics.newImage(Config.ASSETS_PATH .. "Factions/Knights/Troops/Warrior/Red/Warrior_Red.png")
    game.spriteSheets.dead = love.graphics.newImage(Config.ASSETS_PATH .. "Factions/Knights/Troops/Dead/Dead.png")
    game.spriteSheets.tileset = love.graphics.newImage(Config.ASSETS_PATH .. "Terrain/Ground/Tilemap_Flat.png")
    game.spriteSheets.trees = love.graphics.newImage(Config.ASSETS_PATH .. "Resources/Trees/Tree.png")
end

local function initNewGame()
    -- Create tilemap
    game.tilemap = Tilemap.new(game.spriteSheets.tileset, Config.TILE_SIZE)
    
    -- Create player at center
    local startX = Config.WORLD_WIDTH * Config.TILE_SIZE / 2
    local startY = Config.WORLD_HEIGHT * Config.TILE_SIZE / 2
    game.player = Player.new(game.spriteSheets.warriorBlue, startX, startY)
    
    -- Clear state
    game.enemies = {}
    game.allies = {}
    game.deadBodies = {}
    game.trees = {}
    game.upgradeStations = {}
    
    -- Create minimap
    game.minimap = Minimap.new()
    
    -- Scatter trees
    math.randomseed(42)
    for i = 1, 80 do
        local tx = math.random(2, Config.WORLD_WIDTH - 2) * Config.TILE_SIZE + Config.TILE_SIZE / 2
        local ty = math.random(2, Config.WORLD_HEIGHT - 2) * Config.TILE_SIZE + Config.TILE_SIZE / 2
        local variant = math.random(1, 6)
        table.insert(game.trees, Tree.new(game.spriteSheets.trees, tx, ty, variant))
    end
    
    -- Create enemies
    math.randomseed(123)
    
    -- Spawn normal enemies
    for i = 1, 12 do
        local ex, ey
        repeat
            ex = math.random(3, Config.WORLD_WIDTH - 3) * Config.TILE_SIZE
            ey = math.random(3, Config.WORLD_HEIGHT - 3) * Config.TILE_SIZE
        until math.sqrt((ex - startX)^2 + (ey - startY)^2) > 400
        
        table.insert(game.enemies, Enemy.new(game.spriteSheets.warriorRed, ex, ey, "normal"))
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
            
            table.insert(game.enemies, Enemy.new(game.spriteSheets.warriorRed, ex, ey, enemyType))
        end
    end
    
    -- Create upgrade stations
    local upgradeTypes = {"health", "attack", "speed", "rp"}
    for i, upgradeType in ipairs(upgradeTypes) do
        local angle = (i - 1) * math.pi / 2 + math.pi / 4
        local dist = 800
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

local function loadSavedGame()
    local data, err = SaveGame.load()
    if not data then
        print("Failed to load game: " .. (err or "unknown error"))
        initNewGame()
        return
    end
    
    -- Initialize basic structures first
    game.tilemap = Tilemap.new(game.spriteSheets.tileset, Config.TILE_SIZE)
    game.minimap = Minimap.new()
    game.enemies = {}
    game.allies = {}
    game.deadBodies = {}
    game.trees = {}
    game.upgradeStations = {}
    
    -- Recreate trees (same seed)
    math.randomseed(42)
    for i = 1, 80 do
        local tx = math.random(2, Config.WORLD_WIDTH - 2) * Config.TILE_SIZE + Config.TILE_SIZE / 2
        local ty = math.random(2, Config.WORLD_HEIGHT - 2) * Config.TILE_SIZE + Config.TILE_SIZE / 2
        local variant = math.random(1, 6)
        table.insert(game.trees, Tree.new(game.spriteSheets.trees, tx, ty, variant))
    end
    
    -- Load player
    game.player = Player.new(game.spriteSheets.warriorBlue, data.player.x, data.player.y)
    game.player.health = data.player.health
    game.player.maxHealth = data.player.maxHealth
    game.player.attack = data.player.attack
    game.player.speed = data.player.speed
    game.player.rp = data.player.rp
    game.player.maxRP = data.player.maxRP
    game.player.gold = data.player.gold
    
    -- Load enemies
    for _, enemyData in ipairs(data.enemies) do
        local enemy = Enemy.new(game.spriteSheets.warriorRed, enemyData.x, enemyData.y, enemyData.enemyType)
        enemy.health = enemyData.health
        table.insert(game.enemies, enemy)
    end
    
    -- Load allies
    for _, allyData in ipairs(data.allies) do
        local ally = Ally.new(game.spriteSheets.warriorBlue, allyData.x, allyData.y)
        ally.health = allyData.health
        table.insert(game.allies, ally)
    end
    
    -- Load dead bodies
    for _, bodyData in ipairs(data.deadBodies) do
        local body = DeadBody.new(bodyData.x, bodyData.y, game.spriteSheets.dead)
        body.reviveTimer = bodyData.reviveTimer
        body.state = "skull"  -- Skip death animation for loaded bodies
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
    -- Update menu
    game.menu:update(dt)
    
    -- Only update game if playing
    if not game.menu:isPlaying() or not game.initialized then
        return
    end
    
    -- Update player
    game.player:update(dt, game.enemies, game.allies)
    
    -- Update allies
    for _, ally in ipairs(game.allies) do
        ally:update(dt, game.player, game.enemies)
    end
    
    -- Update enemies
    for i = #game.enemies, 1, -1 do
        local enemy = game.enemies[i]
        enemy:update(dt, game.player, game.allies)
        
        if enemy.isDead then
            game.player:addGold(enemy.goldValue or 10)
            table.insert(game.deadBodies, DeadBody.new(enemy.x, enemy.y, game.spriteSheets.dead, enemy.goldValue))
            table.remove(game.enemies, i)
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
    
    -- Update upgrade stations
    for _, station in ipairs(game.upgradeStations) do
        station:update(dt)
    end
    
    -- Resolve collisions
    local allUnits = { game.player }
    for _, enemy in ipairs(game.enemies) do
        table.insert(allUnits, enemy)
    end
    for _, ally in ipairs(game.allies) do
        table.insert(allUnits, ally)
    end
    Collision.resolveAll(allUnits)
    
    -- Update camera
    updateCamera(game.player.x, game.player.y, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Update minimap
    game.minimap:update(game.player.x, game.player.y)
end

function love.draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Draw game world if playing and initialized
    if game.menu:isPlaying() and game.initialized then
        love.graphics.push()
        love.graphics.translate(-math.floor(game.camera.x), -math.floor(game.camera.y))
        
        -- Draw tilemap
        game.tilemap:draw(game.camera.x, game.camera.y, screenW, screenH)
        
        -- Draw upgrade stations
        for _, station in ipairs(game.upgradeStations) do
            station:draw()
        end
        
        -- Draw dead bodies
        for _, body in ipairs(game.deadBodies) do
            body:draw()
        end
        
        -- Collect and sort entities
        local entities = {}
        
        for _, tree in ipairs(game.trees) do
            table.insert(entities, { obj = tree, y = tree.y })
        end
        
        if not game.player.isDead then
            table.insert(entities, { obj = game.player, y = game.player.y })
        end
        
        for _, enemy in ipairs(game.enemies) do
            if not enemy.isDead then
                table.insert(entities, { obj = enemy, y = enemy.y })
            end
        end
        
        for _, ally in ipairs(game.allies) do
            if not ally.isDead then
                table.insert(entities, { obj = ally, y = ally.y })
            end
        end
        
        table.sort(entities, function(a, b) return a.y < b.y end)
        
        for _, entity in ipairs(entities) do
            entity.obj:draw()
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
    end
    
    -- Game input (only when playing)
    if game.menu:isPlaying() and game.initialized then
        if key == "escape" then
            game.menu:pause()
        elseif key == "e" and not game.player.isDead then
            game.player:tryRevive(game.deadBodies, game.allies, game.spriteSheets.warriorBlue)
        elseif key == "f" and not game.player.isDead then
            for i, station in ipairs(game.upgradeStations) do
                if station:tryUpgrade(game.player) then
                    table.remove(game.upgradeStations, i)
                    break
                end
            end
        elseif key == "r" and game.player.isDead then
            initNewGame()
        end
    end
end
