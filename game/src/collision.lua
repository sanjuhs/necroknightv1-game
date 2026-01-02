-- Collision resolution between units
local Config = require("src.config")

local Collision = {}

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

return Collision

