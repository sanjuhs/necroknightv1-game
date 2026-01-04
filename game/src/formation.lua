-- Formation system inspired by Age of Empires 2
local Formation = {}

-- Formation types
Formation.LINE = 1
Formation.BOX = 2
Formation.STAGGERED = 3
Formation.FLANK = 4

-- Get formation positions for allies around the player
-- Returns a table of {x, y} positions for each ally
function Formation.getPositions(formationType, playerX, playerY, playerFacingRight, numAllies, spacing)
    spacing = spacing or 80
    
    if formationType == Formation.LINE then
        return Formation.getLinePositions(playerX, playerY, playerFacingRight, numAllies, spacing)
    elseif formationType == Formation.BOX then
        return Formation.getBoxPositions(playerX, playerY, playerFacingRight, numAllies, spacing)
    elseif formationType == Formation.STAGGERED then
        return Formation.getStaggeredPositions(playerX, playerY, playerFacingRight, numAllies, spacing)
    elseif formationType == Formation.FLANK then
        return Formation.getFlankPositions(playerX, playerY, playerFacingRight, numAllies, spacing)
    end
    
    return Formation.getLinePositions(playerX, playerY, playerFacingRight, numAllies, spacing)
end

-- LINE FORMATION: Standard horizontal line behind the player
-- Melee units in front, ranged behind (we'll treat all as melee for now)
function Formation.getLinePositions(playerX, playerY, playerFacingRight, numAllies, spacing)
    local positions = {}
    local behindOffset = playerFacingRight and -100 or 100  -- Behind the player
    
    -- Calculate how many per row
    local maxPerRow = 6
    local rows = math.ceil(numAllies / maxPerRow)
    
    local allyIndex = 1
    for row = 1, rows do
        local alliesInThisRow = math.min(maxPerRow, numAllies - (row - 1) * maxPerRow)
        local rowWidth = (alliesInThisRow - 1) * spacing
        local startX = playerX - rowWidth / 2
        local rowY = playerY + (row * spacing * 0.7)  -- Rows behind player
        
        for col = 1, alliesInThisRow do
            if allyIndex <= numAllies then
                positions[allyIndex] = {
                    x = startX + (col - 1) * spacing,
                    y = rowY
                }
                allyIndex = allyIndex + 1
            end
        end
    end
    
    return positions
end

-- BOX FORMATION: Protective square/rectangle, weaker units in center
function Formation.getBoxPositions(playerX, playerY, playerFacingRight, numAllies, spacing)
    local positions = {}
    
    if numAllies == 0 then return positions end
    
    -- Calculate box dimensions
    local side = math.ceil(math.sqrt(numAllies))
    local boxWidth = (side - 1) * spacing
    local boxHeight = (side - 1) * spacing
    
    -- Center the box behind the player
    local centerX = playerX
    local centerY = playerY + spacing * 1.5
    
    -- Create positions in a box pattern
    local allyIndex = 1
    
    -- First, create outer ring
    local outerPositions = {}
    local innerPositions = {}
    
    for row = 1, side do
        for col = 1, side do
            if allyIndex <= numAllies then
                local x = centerX - boxWidth/2 + (col - 1) * spacing
                local y = centerY - boxHeight/2 + (row - 1) * spacing
                
                -- Check if this is an edge position
                local isEdge = row == 1 or row == side or col == 1 or col == side
                
                if isEdge then
                    table.insert(outerPositions, {x = x, y = y})
                else
                    table.insert(innerPositions, {x = x, y = y})
                end
            end
        end
    end
    
    -- Assign outer positions first (stronger units), then inner
    allyIndex = 1
    for _, pos in ipairs(outerPositions) do
        if allyIndex <= numAllies then
            positions[allyIndex] = pos
            allyIndex = allyIndex + 1
        end
    end
    for _, pos in ipairs(innerPositions) do
        if allyIndex <= numAllies then
            positions[allyIndex] = pos
            allyIndex = allyIndex + 1
        end
    end
    
    return positions
end

-- STAGGERED FORMATION: Spread out to reduce area damage
function Formation.getStaggeredPositions(playerX, playerY, playerFacingRight, numAllies, spacing)
    local positions = {}
    local wideSpacing = spacing * 1.8  -- Much wider spacing
    
    local maxPerRow = 5
    local rows = math.ceil(numAllies / maxPerRow)
    
    local allyIndex = 1
    for row = 1, rows do
        local alliesInThisRow = math.min(maxPerRow, numAllies - (row - 1) * maxPerRow)
        local rowWidth = (alliesInThisRow - 1) * wideSpacing
        
        -- Stagger odd rows
        local staggerOffset = (row % 2 == 0) and (wideSpacing / 2) or 0
        local startX = playerX - rowWidth / 2 + staggerOffset
        local rowY = playerY + (row * spacing)
        
        for col = 1, alliesInThisRow do
            if allyIndex <= numAllies then
                positions[allyIndex] = {
                    x = startX + (col - 1) * wideSpacing,
                    y = rowY
                }
                allyIndex = allyIndex + 1
            end
        end
    end
    
    return positions
end

-- FLANK FORMATION: Two groups that try to surround enemies
function Formation.getFlankPositions(playerX, playerY, playerFacingRight, numAllies, spacing)
    local positions = {}
    
    if numAllies == 0 then return positions end
    
    -- Split into two groups
    local leftGroup = math.ceil(numAllies / 2)
    local rightGroup = numAllies - leftGroup
    
    local flankDistance = 200  -- How far to the sides
    local behindDistance = 80  -- How far behind player
    
    -- Left flank
    local allyIndex = 1
    for i = 1, leftGroup do
        local row = math.ceil(i / 2)
        local col = (i % 2 == 1) and 1 or 2
        
        positions[allyIndex] = {
            x = playerX - flankDistance - (col - 1) * spacing * 0.7,
            y = playerY + behindDistance + (row - 1) * spacing * 0.8
        }
        allyIndex = allyIndex + 1
    end
    
    -- Right flank
    for i = 1, rightGroup do
        local row = math.ceil(i / 2)
        local col = (i % 2 == 1) and 1 or 2
        
        positions[allyIndex] = {
            x = playerX + flankDistance + (col - 1) * spacing * 0.7,
            y = playerY + behindDistance + (row - 1) * spacing * 0.8
        }
        allyIndex = allyIndex + 1
    end
    
    return positions
end

-- Get the name of a formation
function Formation.getName(formationType)
    local names = {
        [Formation.LINE] = "Line",
        [Formation.BOX] = "Box",
        [Formation.STAGGERED] = "Staggered",
        [Formation.FLANK] = "Flank"
    }
    return names[formationType] or "Unknown"
end

return Formation


