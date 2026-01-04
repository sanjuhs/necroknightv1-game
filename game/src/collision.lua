-- Collision resolution between units and obstacles
local Config = require("src.config")

local Collision = {}

-- Resolve collisions between all units
function Collision.resolveAll(allUnits)
    for i = 1, #allUnits do
        local unitA = allUnits[i]
        if not unitA.isDead then
            for j = i + 1, #allUnits do
                local unitB = allUnits[j]
                if not unitB.isDead then
                    local dx = unitB.x - unitA.x
                    local dy = unitB.y - unitA.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    local minDist = unitA.collisionRadius + unitB.collisionRadius
                    
                    if dist < minDist and dist > 0 then
                        local overlap = (minDist - dist) / 2
                        local nx = dx / dist
                        local ny = dy / dist
                        
                        local pushA = 0.5
                        local pushB = 0.5
                        
                        if unitA.isPlayer then
                            pushA = 0.2
                            pushB = 0.8
                        elseif unitB.isPlayer then
                            pushA = 0.8
                            pushB = 0.2
                        end
                        
                        unitA.x = unitA.x - nx * overlap * pushA
                        unitA.y = unitA.y - ny * overlap * pushA
                        unitB.x = unitB.x + nx * overlap * pushB
                        unitB.y = unitB.y + ny * overlap * pushB
                    elseif dist == 0 then
                        local angle = math.random() * math.pi * 2
                        local push = minDist / 2
                        unitA.x = unitA.x - math.cos(angle) * push
                        unitA.y = unitA.y - math.sin(angle) * push
                        unitB.x = unitB.x + math.cos(angle) * push
                        unitB.y = unitB.y + math.sin(angle) * push
                    end
                end
            end
            
            -- Keep units in world bounds
            local margin = 96
            unitA.x = math.max(margin, math.min(unitA.x, Config.WORLD_WIDTH * Config.TILE_SIZE - margin))
            unitA.y = math.max(margin, math.min(unitA.y, Config.WORLD_HEIGHT * Config.TILE_SIZE - margin))
        end
    end
end

-- Resolve collisions between units and static obstacles (buildings, trees)
function Collision.resolveWithObstacles(allUnits, obstacles)
    for _, unit in ipairs(allUnits) do
        if not unit.isDead then
            for _, obstacle in ipairs(obstacles) do
                local ox = obstacle.x
                local oy = obstacle.y
                local oRadius = obstacle.collisionRadius or 40
                
                local dx = unit.x - ox
                local dy = unit.y - oy
                local dist = math.sqrt(dx * dx + dy * dy)
                local minDist = unit.collisionRadius + oRadius
                
                if dist < minDist and dist > 0 then
                    -- Push unit away from obstacle (obstacles don't move)
                    local overlap = minDist - dist
                    local nx = dx / dist
                    local ny = dy / dist
                    
                    unit.x = unit.x + nx * overlap
                    unit.y = unit.y + ny * overlap
                elseif dist == 0 then
                    -- Random push if exactly on obstacle
                    local angle = math.random() * math.pi * 2
                    unit.x = unit.x + math.cos(angle) * minDist
                    unit.y = unit.y + math.sin(angle) * minDist
                end
            end
        end
    end
end

-- Resolve collisions with rectangular obstacles (buildings)
function Collision.resolveWithBuildings(allUnits, buildings)
    for _, unit in ipairs(allUnits) do
        if not unit.isDead then
            for _, building in ipairs(buildings) do
                local bx = building.x
                local by = building.y
                local bw = (building.config and building.config.width or 100) * 0.4
                local bh = (building.config and building.config.height or 120) * 0.3
                
                -- Simple circle-rectangle collision
                local closestX = math.max(bx - bw/2, math.min(unit.x, bx + bw/2))
                local closestY = math.max(by - bh/2, math.min(unit.y, by + bh/2))
                
                local dx = unit.x - closestX
                local dy = unit.y - closestY
                local dist = math.sqrt(dx * dx + dy * dy)
                
                if dist < unit.collisionRadius and dist > 0 then
                    local overlap = unit.collisionRadius - dist
                    local nx = dx / dist
                    local ny = dy / dist
                    
                    unit.x = unit.x + nx * overlap
                    unit.y = unit.y + ny * overlap
                elseif dist == 0 then
                    -- Push unit out of building
                    unit.y = unit.y + unit.collisionRadius + bh/2 + 10
                end
            end
        end
    end
end

return Collision
