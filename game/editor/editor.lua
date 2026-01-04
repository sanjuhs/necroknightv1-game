-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║          LEVEL EDITOR                                                      ║
-- ║          Create and edit maps for Legend of the Necro-Knight              ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

local Editor = {}

-- Editor state
Editor.active = false
Editor.camera = { x = 0, y = 0 }
Editor.zoom = 1
Editor.gridSize = 64
Editor.showGrid = true
Editor.currentLayer = 1
Editor.selectedTile = nil
Editor.selectedAsset = nil
Editor.brushSize = 1

-- Layers
Editor.layers = {
    { name = "Ground", visible = true, tiles = {} },
    { name = "Elevation", visible = true, tiles = {} },
    { name = "Water", visible = true, tiles = {} },
    { name = "Deco", visible = true, objects = {} },
    { name = "Resources", visible = true, objects = {} },
    { name = "Spawns", visible = true, objects = {} }
}

-- Map dimensions
Editor.mapWidth = 50
Editor.mapHeight = 50

-- Asset palette categories
Editor.categories = {
    "Ground",
    "Elevation", 
    "Water",
    "Deco",
    "Resources",
    "Trees",
    "Buildings",
    "Spawns"
}
Editor.currentCategory = 1

-- Loaded assets
Editor.assets = {}
Editor.assetQuads = {}

-- UI state
Editor.paletteScroll = 0
Editor.showPalette = true
Editor.showLayers = true
Editor.isDragging = false
Editor.lastMouseX = 0
Editor.lastMouseY = 0

-- Tool modes
Editor.TOOL_PAINT = 1
Editor.TOOL_ERASE = 2
Editor.TOOL_SELECT = 3
Editor.TOOL_FILL = 4
Editor.currentTool = Editor.TOOL_PAINT

local function loadAssets()
    local assetsPath = "assets/Tiny_Swords_update_010/"
    
    -- Ground tileset
    local groundPath = assetsPath .. "Terrain/Ground/Tilemap_Flat.png"
    if love.filesystem.getInfo(groundPath) then
        Editor.assets.ground = love.graphics.newImage(groundPath)
        Editor.assets.ground:setFilter("nearest", "nearest")
        
        -- Create quads for ground tiles (64x64 tiles)
        Editor.assetQuads.ground = {}
        local imgW, imgH = Editor.assets.ground:getDimensions()
        local tileSize = 64
        local cols = math.floor(imgW / tileSize)
        local rows = math.floor(imgH / tileSize)
        
        for row = 0, rows - 1 do
            for col = 0, cols - 1 do
                table.insert(Editor.assetQuads.ground, {
                    quad = love.graphics.newQuad(col * tileSize, row * tileSize, tileSize, tileSize, imgW, imgH),
                    name = string.format("Ground_%d", #Editor.assetQuads.ground + 1)
                })
            end
        end
    end
    
    -- Elevation tileset
    local elevPath = assetsPath .. "Terrain/Ground/Tilemap_Elevation.png"
    if love.filesystem.getInfo(elevPath) then
        Editor.assets.elevation = love.graphics.newImage(elevPath)
        Editor.assets.elevation:setFilter("nearest", "nearest")
        
        Editor.assetQuads.elevation = {}
        local imgW, imgH = Editor.assets.elevation:getDimensions()
        local tileSize = 64
        local cols = math.floor(imgW / tileSize)
        local rows = math.floor(imgH / tileSize)
        
        for row = 0, rows - 1 do
            for col = 0, cols - 1 do
                table.insert(Editor.assetQuads.elevation, {
                    quad = love.graphics.newQuad(col * tileSize, row * tileSize, tileSize, tileSize, imgW, imgH),
                    name = string.format("Elevation_%d", #Editor.assetQuads.elevation + 1)
                })
            end
        end
    end
    
    -- Water tileset
    local waterPath = assetsPath .. "Terrain/Water/Water.png"
    if love.filesystem.getInfo(waterPath) then
        Editor.assets.water = love.graphics.newImage(waterPath)
        Editor.assets.water:setFilter("nearest", "nearest")
        
        Editor.assetQuads.water = {}
        local imgW, imgH = Editor.assets.water:getDimensions()
        local tileSize = 64
        local cols = math.floor(imgW / tileSize)
        local rows = math.floor(imgH / tileSize)
        
        for row = 0, rows - 1 do
            for col = 0, cols - 1 do
                table.insert(Editor.assetQuads.water, {
                    quad = love.graphics.newQuad(col * tileSize, row * tileSize, tileSize, tileSize, imgW, imgH),
                    name = string.format("Water_%d", #Editor.assetQuads.water + 1)
                })
            end
        end
    end
    
    -- Water Foam (animated - load first frame)
    local foamPath = assetsPath .. "Terrain/Water/Foam/Foam.png"
    if love.filesystem.getInfo(foamPath) then
        local foamImg = love.graphics.newImage(foamPath)
        foamImg:setFilter("nearest", "nearest")
        local imgW, imgH = foamImg:getDimensions()
        -- Foam is a sprite sheet, extract tiles
        local tileSize = 64
        local cols = math.floor(imgW / tileSize)
        local rows = math.floor(imgH / tileSize)
        
        for row = 0, math.min(rows - 1, 2) do  -- Just first few rows
            for col = 0, cols - 1 do
                table.insert(Editor.assetQuads.water, {
                    quad = love.graphics.newQuad(col * tileSize, row * tileSize, tileSize, tileSize, imgW, imgH),
                    name = string.format("Foam_%d", #Editor.assetQuads.water + 1),
                    sourceImage = foamImg
                })
            end
        end
        Editor.assets.foam = foamImg
    end
    
    -- Water Rocks
    for i = 1, 4 do
        local rockPath = assetsPath .. string.format("Terrain/Water/Rocks/Rocks_%02d.png", i)
        if love.filesystem.getInfo(rockPath) then
            local img = love.graphics.newImage(rockPath)
            img:setFilter("nearest", "nearest")
            table.insert(Editor.assetQuads.water, {
                image = img,
                name = string.format("Rock_%d", i)
            })
        end
    end
    
    -- Bridge
    local bridgePath = assetsPath .. "Terrain/Bridge/Bridge_All.png"
    if love.filesystem.getInfo(bridgePath) then
        local bridgeImg = love.graphics.newImage(bridgePath)
        bridgeImg:setFilter("nearest", "nearest")
        local imgW, imgH = bridgeImg:getDimensions()
        -- Bridge is a sprite sheet with 64x64 tiles
        local tileSize = 64
        local cols = math.floor(imgW / tileSize)
        local rows = math.floor(imgH / tileSize)
        
        Editor.assets.bridge = bridgeImg
        for row = 0, rows - 1 do
            for col = 0, cols - 1 do
                table.insert(Editor.assetQuads.ground, {
                    quad = love.graphics.newQuad(col * tileSize, row * tileSize, tileSize, tileSize, imgW, imgH),
                    name = string.format("Bridge_%d", col + row * cols + 1),
                    sourceImage = bridgeImg
                })
            end
        end
    end
    
    -- Deco objects (load as full images)
    Editor.assetQuads.deco = {}
    for i = 1, 18 do
        local decoPath = assetsPath .. string.format("Deco/%02d.png", i)
        if love.filesystem.getInfo(decoPath) then
            local img = love.graphics.newImage(decoPath)
            img:setFilter("nearest", "nearest")
            table.insert(Editor.assetQuads.deco, {
                image = img,
                name = string.format("Deco_%02d", i)
            })
        end
    end
    
    -- Trees (animated sprite sheet - extract first frame for tree, and stump)
    Editor.assetQuads.trees = {}
    local treePath = assetsPath .. "Resources/Trees/Tree.png"
    if love.filesystem.getInfo(treePath) then
        local treeImg = love.graphics.newImage(treePath)
        treeImg:setFilter("nearest", "nearest")
        local imgW, imgH = treeImg:getDimensions()
        
        -- Tree sprite sheet: multiple frames horizontally, stump might be last
        -- Assuming 192x192 per frame based on typical Tiny Swords assets
        local frameW = 192
        local frameH = 192
        local numFrames = math.floor(imgW / frameW)
        
        -- First frame is the full tree
        if numFrames > 0 then
            table.insert(Editor.assetQuads.trees, {
                quad = love.graphics.newQuad(0, 0, frameW, frameH, imgW, imgH),
                name = "Tree",
                sourceImage = treeImg
            })
        end
        
        -- Last frame might be the stump (or a different state)
        if numFrames > 1 then
            -- Add a few different tree frames
            for i = 1, math.min(numFrames, 4) do
                table.insert(Editor.assetQuads.trees, {
                    quad = love.graphics.newQuad((i-1) * frameW, 0, frameW, frameH, imgW, imgH),
                    name = string.format("Tree_Frame%d", i),
                    sourceImage = treeImg
                })
            end
        end
        
        Editor.assets.tree = treeImg
    end
    
    -- Resources
    Editor.assetQuads.resources = {}
    local resourceFiles = {
        {path = "Resources/Resources/G_Idle.png", name = "Gold"},
        {path = "Resources/Resources/M_Idle.png", name = "Meat"},
        {path = "Resources/Resources/W_Idle.png", name = "Wood"},
        {path = "Resources/Gold Mine/GoldMine_Active.png", name = "GoldMine Active"},
        {path = "Resources/Gold Mine/GoldMine_Inactive.png", name = "GoldMine Inactive"},
        {path = "Resources/Gold Mine/GoldMine_Destroyed.png", name = "GoldMine Destroyed"},
        {path = "Resources/Sheep/HappySheep_Idle.png", name = "Sheep"}
    }
    for _, res in ipairs(resourceFiles) do
        local fullPath = assetsPath .. res.path
        if love.filesystem.getInfo(fullPath) then
            local img = love.graphics.newImage(fullPath)
            img:setFilter("nearest", "nearest")
            -- For sprite sheets, just use first frame
            local iw, ih = img:getDimensions()
            if iw > ih * 2 then  -- Likely a sprite sheet
                -- Create quad for first frame
                local frameW = ih  -- Assume square frames
                table.insert(Editor.assetQuads.resources, {
                    quad = love.graphics.newQuad(0, 0, frameW, ih, iw, ih),
                    name = res.name,
                    sourceImage = img
                })
            else
                table.insert(Editor.assetQuads.resources, {
                    image = img,
                    name = res.name
                })
            end
        end
    end
    
    -- Spawn markers (clearer labels)
    Editor.assetQuads.spawns = {
        { name = "Player", label = "P", color = {0.2, 0.6, 1}, desc = "Player Start" },
        { name = "Enemy", label = "E", color = {1, 0.3, 0.3}, desc = "Enemy Spawn" },
        { name = "Ally", label = "A", color = {0.3, 1, 0.3}, desc = "Ally Spawn" },
        { name = "Boss", label = "B", color = {0.8, 0.2, 0.8}, desc = "Boss Spawn" }
    }
end

function Editor.init()
    loadAssets()
    
    -- Initialize empty layers
    for i = 1, 3 do  -- Ground, Elevation, Water
        Editor.layers[i].tiles = {}
        for y = 1, Editor.mapHeight do
            Editor.layers[i].tiles[y] = {}
            for x = 1, Editor.mapWidth do
                Editor.layers[i].tiles[y][x] = nil
            end
        end
    end
    
    -- Center camera
    Editor.camera.x = -love.graphics.getWidth() / 2 + (Editor.mapWidth * Editor.gridSize) / 2
    Editor.camera.y = -love.graphics.getHeight() / 2 + (Editor.mapHeight * Editor.gridSize) / 2
    
    Editor.active = true
end

function Editor.update(dt)
    if not Editor.active then return end
    
    -- Camera pan with middle mouse or right mouse
    if Editor.isDragging then
        local mx, my = love.mouse.getPosition()
        local dx = mx - Editor.lastMouseX
        local dy = my - Editor.lastMouseY
        Editor.camera.x = Editor.camera.x - dx / Editor.zoom
        Editor.camera.y = Editor.camera.y - dy / Editor.zoom
        Editor.lastMouseX = mx
        Editor.lastMouseY = my
    end
    
    -- Paint while holding left mouse
    if love.mouse.isDown(1) and not Editor.isOverUI() then
        Editor.paint()
    end
end

function Editor.isOverUI()
    local mx, my = love.mouse.getPosition()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Palette panel (right side)
    if Editor.showPalette and mx > screenW - 220 then
        return true
    end
    
    -- Layer panel (left side)
    if Editor.showLayers and mx < 180 then
        return true
    end
    
    -- Top toolbar
    if my < 50 then
        return true
    end
    
    return false
end

function Editor.screenToWorld(sx, sy)
    local wx = (sx / Editor.zoom) + Editor.camera.x
    local wy = (sy / Editor.zoom) + Editor.camera.y
    return wx, wy
end

function Editor.worldToGrid(wx, wy)
    local gx = math.floor(wx / Editor.gridSize) + 1
    local gy = math.floor(wy / Editor.gridSize) + 1
    return gx, gy
end

function Editor.paint()
    local mx, my = love.mouse.getPosition()
    local wx, wy = Editor.screenToWorld(mx, my)
    local gx, gy = Editor.worldToGrid(wx, wy)
    
    -- Check bounds
    if gx < 1 or gx > Editor.mapWidth or gy < 1 or gy > Editor.mapHeight then
        return
    end
    
    local layer = Editor.layers[Editor.currentLayer]
    
    if Editor.currentTool == Editor.TOOL_PAINT then
        if Editor.selectedTile and layer.tiles then
            -- Tile layers (Ground, Elevation, Water)
            layer.tiles[gy][gx] = Editor.selectedTile
        elseif Editor.selectedAsset and layer.objects then
            -- Object layers (Deco, Resources, Spawns)
            -- Check if object already exists at this position
            local exists = false
            for _, obj in ipairs(layer.objects) do
                if obj.gx == gx and obj.gy == gy then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(layer.objects, {
                    gx = gx,
                    gy = gy,
                    asset = Editor.selectedAsset
                })
            end
        end
    elseif Editor.currentTool == Editor.TOOL_ERASE then
        if layer.tiles then
            layer.tiles[gy][gx] = nil
        elseif layer.objects then
            for i = #layer.objects, 1, -1 do
                if layer.objects[i].gx == gx and layer.objects[i].gy == gy then
                    table.remove(layer.objects, i)
                end
            end
        end
    end
end

function Editor.draw()
    if not Editor.active then return end
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Apply camera transform
    love.graphics.push()
    love.graphics.scale(Editor.zoom, Editor.zoom)
    love.graphics.translate(-Editor.camera.x, -Editor.camera.y)
    
    -- Draw background
    love.graphics.setColor(0.15, 0.18, 0.22, 1)
    love.graphics.rectangle("fill", 0, 0, Editor.mapWidth * Editor.gridSize, Editor.mapHeight * Editor.gridSize)
    
    -- Draw layers
    for i, layer in ipairs(Editor.layers) do
        if layer.visible then
            if layer.tiles then
                Editor.drawTileLayer(layer, i)
            elseif layer.objects then
                Editor.drawObjectLayer(layer, i)
            end
        end
    end
    
    -- Draw grid
    if Editor.showGrid then
        love.graphics.setColor(0.4, 0.4, 0.4, 0.3)
        for x = 0, Editor.mapWidth do
            love.graphics.line(x * Editor.gridSize, 0, x * Editor.gridSize, Editor.mapHeight * Editor.gridSize)
        end
        for y = 0, Editor.mapHeight do
            love.graphics.line(0, y * Editor.gridSize, Editor.mapWidth * Editor.gridSize, y * Editor.gridSize)
        end
    end
    
    -- Draw cursor preview
    if not Editor.isOverUI() then
        local mx, my = love.mouse.getPosition()
        local wx, wy = Editor.screenToWorld(mx, my)
        local gx, gy = Editor.worldToGrid(wx, wy)
        
        if gx >= 1 and gx <= Editor.mapWidth and gy >= 1 and gy <= Editor.mapHeight then
            love.graphics.setColor(1, 1, 0, 0.4)
            love.graphics.rectangle("fill", (gx - 1) * Editor.gridSize, (gy - 1) * Editor.gridSize, 
                                   Editor.gridSize, Editor.gridSize)
            love.graphics.setColor(1, 1, 0, 0.8)
            love.graphics.rectangle("line", (gx - 1) * Editor.gridSize, (gy - 1) * Editor.gridSize, 
                                   Editor.gridSize, Editor.gridSize)
        end
    end
    
    love.graphics.pop()
    
    -- Draw UI
    Editor.drawToolbar()
    Editor.drawPalette()
    Editor.drawLayerPanel()
    Editor.drawStatusBar()
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Editor.drawTileLayer(layer, layerIndex)
    local assetKey = nil
    if layerIndex == 1 then assetKey = "ground"
    elseif layerIndex == 2 then assetKey = "elevation"
    elseif layerIndex == 3 then assetKey = "water"
    end
    
    if not assetKey then return end
    
    love.graphics.setColor(1, 1, 1, 1)
    for y = 1, Editor.mapHeight do
        for x = 1, Editor.mapWidth do
            local tileId = layer.tiles[y][x]
            if tileId and Editor.assetQuads[assetKey] and Editor.assetQuads[assetKey][tileId] then
                local tileData = Editor.assetQuads[assetKey][tileId]
                if tileData.quad then
                    -- Get the source image (either specific or default)
                    local sourceImg = tileData.sourceImage or Editor.assets[assetKey]
                    if sourceImg then
                        love.graphics.draw(sourceImg, tileData.quad,
                            (x - 1) * Editor.gridSize, (y - 1) * Editor.gridSize)
                    end
                elseif tileData.image then
                    -- Full image tile (like rocks)
                    local iw, ih = tileData.image:getDimensions()
                    local scale = Editor.gridSize / math.max(iw, ih)
                    love.graphics.draw(tileData.image, 
                        (x - 1) * Editor.gridSize + Editor.gridSize/2, 
                        (y - 1) * Editor.gridSize + Editor.gridSize/2,
                        0, scale, scale, iw/2, ih/2)
                end
            end
        end
    end
end

function Editor.drawObjectLayer(layer, layerIndex)
    for _, obj in ipairs(layer.objects) do
        local x = (obj.gx - 1) * Editor.gridSize + Editor.gridSize / 2
        local y = (obj.gy - 1) * Editor.gridSize + Editor.gridSize / 2
        
        if obj.asset.quad then
            -- Draw quad-based asset (sprite sheet frame)
            local sourceImg = obj.asset.sourceImage
            if sourceImg then
                local qx, qy, qw, qh = obj.asset.quad:getViewport()
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(sourceImg, obj.asset.quad, x, y, 0, 1, 1, qw/2, qh/2)
            end
        elseif obj.asset.image then
            -- Draw image asset
            local img = obj.asset.image
            local iw, ih = img:getDimensions()
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, x, y, 0, 1, 1, iw/2, ih/2)
        elseif obj.asset.color then
            -- Draw spawn marker with clear label
            love.graphics.setColor(obj.asset.color[1], obj.asset.color[2], obj.asset.color[3], 0.7)
            love.graphics.circle("fill", x, y, 28)
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", x, y, 28)
            love.graphics.setLineWidth(1)
            
            -- Draw clear label
            love.graphics.setColor(1, 1, 1, 1)
            local font = love.graphics.getFont()
            local label = obj.asset.label or obj.asset.name:sub(1, 1)
            love.graphics.print(label, x - font:getWidth(label)/2, y - font:getHeight()/2)
            
            -- Draw name below
            love.graphics.setColor(1, 1, 1, 0.8)
            local name = obj.asset.name
            love.graphics.print(name, x - font:getWidth(name)/2, y + 32)
        end
    end
end

function Editor.drawToolbar()
    local screenW = love.graphics.getWidth()
    
    -- Background
    love.graphics.setColor(0.12, 0.12, 0.15, 0.95)
    love.graphics.rectangle("fill", 0, 0, screenW, 50)
    
    -- Title
    love.graphics.setColor(0.9, 0.8, 0.5, 1)
    love.graphics.print("LEVEL EDITOR", 15, 15)
    
    -- Tools
    local tools = {"Paint", "Erase", "Select", "Fill"}
    local toolX = 150
    for i, toolName in ipairs(tools) do
        local isSelected = (i == Editor.currentTool)
        
        if isSelected then
            love.graphics.setColor(0.3, 0.5, 0.8, 1)
        else
            love.graphics.setColor(0.25, 0.25, 0.3, 1)
        end
        love.graphics.rectangle("fill", toolX, 10, 60, 30, 4, 4)
        
        love.graphics.setColor(1, 1, 1, isSelected and 1 or 0.6)
        love.graphics.print(toolName, toolX + 8, 17)
        
        toolX = toolX + 70
    end
    
    -- Grid toggle
    love.graphics.setColor(Editor.showGrid and {0.3, 0.6, 0.3, 1} or {0.3, 0.3, 0.3, 1})
    love.graphics.rectangle("fill", toolX + 20, 10, 60, 30, 4, 4)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("Grid", toolX + 35, 17)
    
    -- Save/Load buttons
    local saveX = screenW - 180
    love.graphics.setColor(0.3, 0.6, 0.3, 1)
    love.graphics.rectangle("fill", saveX, 10, 60, 30, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Save", saveX + 12, 17)
    
    love.graphics.setColor(0.3, 0.5, 0.7, 1)
    love.graphics.rectangle("fill", saveX + 70, 10, 60, 30, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Load", saveX + 82, 17)
    
    -- Exit button
    love.graphics.setColor(0.7, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", screenW - 45, 10, 35, 30, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("X", screenW - 33, 17)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Editor.drawPalette()
    if not Editor.showPalette then return end
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local panelW = 220
    local panelX = screenW - panelW
    
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.12, 0.95)
    love.graphics.rectangle("fill", panelX, 50, panelW, screenH - 80)
    
    -- Title
    love.graphics.setColor(0.9, 0.8, 0.5, 1)
    love.graphics.print("ASSETS", panelX + 10, 60)
    
    -- Category tabs
    local tabY = 85
    for i, cat in ipairs(Editor.categories) do
        local isSelected = (i == Editor.currentCategory)
        
        if isSelected then
            love.graphics.setColor(0.3, 0.5, 0.7, 1)
        else
            love.graphics.setColor(0.2, 0.2, 0.25, 1)
        end
        
        local tabW = panelW / 4 - 4
        local tabX = panelX + ((i - 1) % 4) * (tabW + 2) + 4
        local row = math.floor((i - 1) / 4)
        love.graphics.rectangle("fill", tabX, tabY + row * 28, tabW, 24, 3, 3)
        
        love.graphics.setColor(1, 1, 1, isSelected and 1 or 0.5)
        local shortName = cat:sub(1, 4)
        love.graphics.print(shortName, tabX + 4, tabY + row * 28 + 5)
    end
    
    -- Asset grid with scissor clipping to prevent overflow
    local assetAreaTop = 150
    local assetAreaBottom = screenH - 35
    local assetSize = 48
    local padding = 6
    local cols = 3
    
    -- Set scissor to clip assets to panel area
    love.graphics.setScissor(panelX, assetAreaTop, panelW, assetAreaBottom - assetAreaTop)
    
    local assetList = Editor.getAssetListForCategory(Editor.currentCategory)
    
    for i, asset in ipairs(assetList) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local ax = panelX + 10 + col * (assetSize + padding)
        local ay = assetAreaTop + row * (assetSize + padding + 2) - Editor.paletteScroll
        
        -- Selection highlight
        local isSelected = (Editor.selectedAsset == asset) or 
                          (Editor.selectedTile and Editor.selectedTile == i)
        
        if isSelected then
            love.graphics.setColor(0.9, 0.7, 0.2, 1)
            love.graphics.rectangle("fill", ax - 2, ay - 2, assetSize + 4, assetSize + 4, 4, 4)
        end
        
        -- Background
        love.graphics.setColor(0.2, 0.2, 0.25, 1)
        love.graphics.rectangle("fill", ax, ay, assetSize, assetSize, 3, 3)
        
        -- Draw asset preview based on type
        if asset.quad then
            -- Asset with quad (tileset or sprite sheet frame)
            local sourceImg = asset.sourceImage or Editor.assets[Editor.getCategoryAssetKey()]
            if sourceImg then
                love.graphics.setColor(1, 1, 1, 1)
                -- Get quad dimensions
                local qx, qy, qw, qh = asset.quad:getViewport()
                local scale = math.min(assetSize / qw, assetSize / qh)
                love.graphics.draw(sourceImg, asset.quad, ax + assetSize/2, ay + assetSize/2, 0, scale, scale, qw/2, qh/2)
            end
        elseif asset.image then
            -- Full image asset
            love.graphics.setColor(1, 1, 1, 1)
            local iw, ih = asset.image:getDimensions()
            local scale = math.min(assetSize / iw, assetSize / ih) * 0.9
            love.graphics.draw(asset.image, ax + assetSize/2, ay + assetSize/2, 0, scale, scale, iw/2, ih/2)
        elseif asset.color then
            -- Spawn marker
            love.graphics.setColor(asset.color[1], asset.color[2], asset.color[3], 0.9)
            love.graphics.circle("fill", ax + assetSize/2, ay + assetSize/2, assetSize/3)
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.circle("line", ax + assetSize/2, ay + assetSize/2, assetSize/3)
            -- Draw label
            love.graphics.setColor(1, 1, 1, 1)
            local font = love.graphics.getFont()
            local label = asset.label or asset.name:sub(1, 1)
            love.graphics.print(label, ax + assetSize/2 - font:getWidth(label)/2, ay + assetSize/2 - font:getHeight()/2)
        end
        
        -- Show asset name on hover (tooltip)
        local mx, my = love.mouse.getPosition()
        if mx >= ax and mx <= ax + assetSize and my >= ay and my <= ay + assetSize then
            -- Store for tooltip drawing later (after scissor)
            Editor.hoveredAsset = { name = asset.name, x = ax, y = ay + assetSize + 4, desc = asset.desc }
        end
    end
    
    -- Reset scissor
    love.graphics.setScissor()
    
    -- Draw tooltip for hovered asset (outside scissor)
    if Editor.hoveredAsset then
        local tip = Editor.hoveredAsset
        local font = love.graphics.getFont()
        local tipText = tip.desc or tip.name
        local tipW = font:getWidth(tipText) + 10
        local tipH = font:getHeight() + 6
        local tipX = math.min(tip.x, screenW - tipW - 10)
        local tipY = tip.y
        
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", tipX, tipY, tipW, tipH, 3, 3)
        love.graphics.setColor(0.9, 0.8, 0.5, 1)
        love.graphics.print(tipText, tipX + 5, tipY + 3)
        
        Editor.hoveredAsset = nil
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Editor.getCategoryAssetKey()
    local keys = {"ground", "elevation", "water", "deco", "resources", "trees", "buildings", "spawns"}
    return keys[Editor.currentCategory]
end

function Editor.getAssetListForCategory(category)
    local keys = {"ground", "elevation", "water", "deco", "resources", "trees", "buildings", "spawns"}
    local key = keys[category]
    return Editor.assetQuads[key] or {}
end

function Editor.drawLayerPanel()
    if not Editor.showLayers then return end
    
    local screenH = love.graphics.getHeight()
    local panelW = 180
    
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.12, 0.95)
    love.graphics.rectangle("fill", 0, 50, panelW, screenH - 80)
    
    -- Title
    love.graphics.setColor(0.9, 0.8, 0.5, 1)
    love.graphics.print("LAYERS", 10, 60)
    
    -- Layer list
    local layerY = 90
    for i, layer in ipairs(Editor.layers) do
        local isSelected = (i == Editor.currentLayer)
        
        -- Background
        if isSelected then
            love.graphics.setColor(0.3, 0.5, 0.7, 1)
        else
            love.graphics.setColor(0.2, 0.2, 0.25, 1)
        end
        love.graphics.rectangle("fill", 10, layerY, panelW - 20, 28, 4, 4)
        
        -- Visibility toggle
        love.graphics.setColor(layer.visible and {0.3, 0.8, 0.3, 1} or {0.5, 0.3, 0.3, 1})
        love.graphics.rectangle("fill", 15, layerY + 4, 20, 20, 3, 3)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(layer.visible and "V" or "-", 20, layerY + 6)
        
        -- Layer name
        love.graphics.setColor(1, 1, 1, isSelected and 1 or 0.6)
        love.graphics.print(layer.name, 42, layerY + 6)
        
        layerY = layerY + 34
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Editor.drawStatusBar()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Background
    love.graphics.setColor(0.12, 0.12, 0.15, 0.95)
    love.graphics.rectangle("fill", 0, screenH - 30, screenW, 30)
    
    -- Mouse position
    local mx, my = love.mouse.getPosition()
    local wx, wy = Editor.screenToWorld(mx, my)
    local gx, gy = Editor.worldToGrid(wx, wy)
    
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print(string.format("Grid: %d, %d  |  World: %.0f, %.0f  |  Zoom: %.0f%%", 
        gx, gy, wx, wy, Editor.zoom * 100), 10, screenH - 22)
    
    -- Help text
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.print("Middle-click drag: Pan  |  Scroll: Zoom  |  Left-click: Paint  |  ESC: Exit", 
        screenW - 450, screenH - 22)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Editor.mousepressed(x, y, button)
    if not Editor.active then return end
    
    -- Middle mouse or right mouse for panning
    if button == 2 or button == 3 then
        Editor.isDragging = true
        Editor.lastMouseX = x
        Editor.lastMouseY = y
        return
    end
    
    if button == 1 then
        -- Check toolbar clicks
        if y < 50 then
            Editor.handleToolbarClick(x, y)
            return
        end
        
        -- Check palette clicks
        if Editor.showPalette and x > love.graphics.getWidth() - 220 then
            Editor.handlePaletteClick(x, y)
            return
        end
        
        -- Check layer panel clicks
        if Editor.showLayers and x < 180 then
            Editor.handleLayerClick(x, y)
            return
        end
        
        -- Canvas painting handled in update
    end
end

function Editor.mousereleased(x, y, button)
    if button == 2 or button == 3 then
        Editor.isDragging = false
    end
end

function Editor.wheelmoved(x, y)
    if not Editor.active then return end
    
    -- Check if over palette for scrolling
    local mx, my = love.mouse.getPosition()
    if Editor.showPalette and mx > love.graphics.getWidth() - 220 then
        Editor.paletteScroll = math.max(0, Editor.paletteScroll - y * 30)
        return
    end
    
    -- Zoom
    local oldZoom = Editor.zoom
    Editor.zoom = math.max(0.25, math.min(4, Editor.zoom + y * 0.1))
    
    -- Zoom toward mouse position
    if Editor.zoom ~= oldZoom then
        local wx, wy = Editor.screenToWorld(mx, my)
        Editor.camera.x = wx - mx / Editor.zoom
        Editor.camera.y = wy - my / Editor.zoom
    end
end

function Editor.handleToolbarClick(x, y)
    -- Tool buttons (starting at x=150)
    local toolX = 150
    for i = 1, 4 do
        if x >= toolX and x <= toolX + 60 then
            Editor.currentTool = i
            return
        end
        toolX = toolX + 70
    end
    
    -- Grid toggle
    if x >= toolX + 20 and x <= toolX + 80 then
        Editor.showGrid = not Editor.showGrid
        return
    end
    
    -- Save button
    local screenW = love.graphics.getWidth()
    local saveX = screenW - 180
    if x >= saveX and x <= saveX + 60 then
        Editor.saveMap()
        return
    end
    
    -- Load button
    if x >= saveX + 70 and x <= saveX + 130 then
        Editor.loadMap()
        return
    end
    
    -- Exit button
    if x >= screenW - 45 then
        Editor.active = false
        return
    end
end

function Editor.handlePaletteClick(x, y)
    local screenW = love.graphics.getWidth()
    local panelX = screenW - 220
    
    -- Category tabs
    if y >= 85 and y < 145 then
        local tabW = 220 / 4 - 4
        for i = 1, #Editor.categories do
            local col = (i - 1) % 4
            local row = math.floor((i - 1) / 4)
            local tabX = panelX + col * (tabW + 2) + 4
            local tabY = 85 + row * 28
            
            if x >= tabX and x <= tabX + tabW and y >= tabY and y <= tabY + 24 then
                Editor.currentCategory = i
                Editor.selectedTile = nil
                Editor.selectedAsset = nil
                Editor.paletteScroll = 0
                return
            end
        end
    end
    
    -- Asset selection
    if y >= 150 then
        local assetSize = 48
        local padding = 6
        local cols = 3
        local assetList = Editor.getAssetListForCategory(Editor.currentCategory)
        
        for i, asset in ipairs(assetList) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local ax = panelX + 10 + col * (assetSize + padding)
            local ay = 150 + row * (assetSize + padding) - Editor.paletteScroll
            
            if x >= ax and x <= ax + assetSize and y >= ay and y <= ay + assetSize then
                -- Set selection based on layer type
                if Editor.currentCategory <= 3 then
                    Editor.selectedTile = i
                    Editor.selectedAsset = nil
                    Editor.currentLayer = Editor.currentCategory
                else
                    Editor.selectedTile = nil
                    Editor.selectedAsset = asset
                    -- Map category to layer
                    if Editor.currentCategory == 4 then Editor.currentLayer = 4  -- Deco
                    elseif Editor.currentCategory == 5 or Editor.currentCategory == 6 then Editor.currentLayer = 5  -- Resources
                    elseif Editor.currentCategory == 8 then Editor.currentLayer = 6  -- Spawns
                    end
                end
                return
            end
        end
    end
end

function Editor.handleLayerClick(x, y)
    local layerY = 90
    for i, layer in ipairs(Editor.layers) do
        if y >= layerY and y <= layerY + 28 then
            -- Check visibility toggle
            if x >= 15 and x <= 35 then
                layer.visible = not layer.visible
            else
                Editor.currentLayer = i
            end
            return
        end
        layerY = layerY + 34
    end
end

function Editor.keypressed(key)
    if not Editor.active then return end
    
    if key == "escape" then
        Editor.active = false
    elseif key == "g" then
        Editor.showGrid = not Editor.showGrid
    elseif key == "1" then
        Editor.currentTool = Editor.TOOL_PAINT
    elseif key == "2" then
        Editor.currentTool = Editor.TOOL_ERASE
    elseif key == "3" then
        Editor.currentTool = Editor.TOOL_SELECT
    elseif key == "4" then
        Editor.currentTool = Editor.TOOL_FILL
    elseif key == "s" and love.keyboard.isDown("lctrl", "rctrl") then
        Editor.saveMap()
    elseif key == "o" and love.keyboard.isDown("lctrl", "rctrl") then
        Editor.loadMap()
    end
end

function Editor.saveMap()
    local mapData = {
        width = Editor.mapWidth,
        height = Editor.mapHeight,
        layers = {}
    }
    
    for i, layer in ipairs(Editor.layers) do
        local layerData = {
            name = layer.name,
            visible = layer.visible
        }
        
        if layer.tiles then
            layerData.tiles = layer.tiles
        elseif layer.objects then
            layerData.objects = {}
            for _, obj in ipairs(layer.objects) do
                table.insert(layerData.objects, {
                    gx = obj.gx,
                    gy = obj.gy,
                    assetName = obj.asset.name
                })
            end
        end
        
        mapData.layers[i] = layerData
    end
    
    -- Serialize to string
    local function serialize(t, indent)
        indent = indent or ""
        local result = "{\n"
        for k, v in pairs(t) do
            local key = type(k) == "number" and "[" .. k .. "]" or '["' .. tostring(k) .. '"]'
            if type(v) == "table" then
                result = result .. indent .. "  " .. key .. " = " .. serialize(v, indent .. "  ") .. ",\n"
            elseif type(v) == "string" then
                result = result .. indent .. "  " .. key .. ' = "' .. v .. '",\n'
            elseif type(v) == "boolean" then
                result = result .. indent .. "  " .. key .. " = " .. tostring(v) .. ",\n"
            else
                result = result .. indent .. "  " .. key .. " = " .. tostring(v) .. ",\n"
            end
        end
        return result .. indent .. "}"
    end
    
    local content = "return " .. serialize(mapData)
    
    -- Save to file
    local success, err = love.filesystem.write("maps/custom_map.lua", content)
    if success then
        print("Map saved!")
    else
        print("Error saving map: " .. tostring(err))
        -- Try creating maps directory
        love.filesystem.createDirectory("maps")
        love.filesystem.write("maps/custom_map.lua", content)
    end
end

function Editor.loadMap()
    -- Try to load map file
    love.filesystem.createDirectory("maps")
    local chunk, err = love.filesystem.load("maps/custom_map.lua")
    if chunk then
        local mapData = chunk()
        if mapData then
            Editor.mapWidth = mapData.width or 50
            Editor.mapHeight = mapData.height or 50
            
            for i, layerData in ipairs(mapData.layers or {}) do
                if Editor.layers[i] then
                    Editor.layers[i].visible = layerData.visible
                    
                    if layerData.tiles then
                        Editor.layers[i].tiles = layerData.tiles
                    elseif layerData.objects then
                        Editor.layers[i].objects = {}
                        for _, objData in ipairs(layerData.objects) do
                            -- Find asset by name
                            local asset = Editor.findAssetByName(objData.assetName)
                            if asset then
                                table.insert(Editor.layers[i].objects, {
                                    gx = objData.gx,
                                    gy = objData.gy,
                                    asset = asset
                                })
                            end
                        end
                    end
                end
            end
            
            print("Map loaded!")
        end
    else
        print("No saved map found or error: " .. tostring(err))
    end
end

function Editor.findAssetByName(name)
    for _, category in pairs(Editor.assetQuads) do
        if type(category) == "table" then
            for _, asset in ipairs(category) do
                if asset.name == name then
                    return asset
                end
            end
        end
    end
    return nil
end

return Editor

