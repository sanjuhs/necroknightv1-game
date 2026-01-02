-- UI drawing functions
local Config = require("src.config")

local UI = {}

function UI.draw(game)
    UI.drawHealthBar(game.player)
    UI.drawRPBar(game.player)
    UI.drawStats(game)
    UI.drawGameMessages(game)
end

function UI.drawHealthBar(player)
    -- Health bar background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 20, 20, 204, 24, 4, 4)
    
    -- Health bar fill
    local healthPercent = player.health / player.maxHealth
    love.graphics.setColor(0.2, 0.7, 0.3)
    love.graphics.rectangle("fill", 22, 22, 200 * healthPercent, 20, 3, 3)
    
    -- Border
    love.graphics.setColor(0.9, 0.8, 0.6)
    love.graphics.rectangle("line", 20, 20, 204, 24, 4, 4)
    
    -- Text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("HP: %.0f/%.0f", player.health, player.maxHealth), 26, 23)
end

function UI.drawRPBar(player)
    -- RP bar background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 20, 48, 204, 20, 4, 4)
    
    -- RP bar fill
    local rpPercent = player.rp / player.maxRP
    love.graphics.setColor(0.2, 0.5, 0.9)
    love.graphics.rectangle("fill", 22, 50, 200 * rpPercent, 16, 3, 3)
    
    -- Border
    love.graphics.setColor(0.6, 0.7, 0.9)
    love.graphics.rectangle("line", 20, 48, 204, 20, 4, 4)
    
    -- Text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("RP: %.0f/%.0f", player.rp, player.maxRP), 26, 50)
end

function UI.drawStats(game)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("WASD: Move | E: Revive | F: Upgrade", 20, 78)
    love.graphics.print(string.format("ATK: %d | SPD: %d | Allies: %d", 
        game.player.attack, game.player.speed, #game.allies), 20, 98)
    
    local aliveEnemies = 0
    for _, enemy in ipairs(game.enemies) do
        if not enemy.isDead then aliveEnemies = aliveEnemies + 1 end
    end
    love.graphics.print(string.format("Enemies: %d | Skulls: %d", aliveEnemies, #game.deadBodies), 20, 118)
    
    -- Gold display
    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.print(string.format("Gold: %d", game.player.gold), 20, 138)
    
    love.graphics.setColor(1, 1, 1)
end

function UI.drawFPS()
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 80, love.graphics.getHeight() - 25)
    love.graphics.setColor(1, 1, 1)
end

function UI.drawGameMessages(game)
    -- Game over
    if game.player.isDead then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 0.2, 0.2)
        local msg = "GAME OVER"
        love.graphics.print(msg, love.graphics.getWidth()/2 - 40, love.graphics.getHeight()/2 - 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Press R to restart", love.graphics.getWidth()/2 - 60, love.graphics.getHeight()/2 + 20)
    end
    
    -- Victory
    local aliveEnemies = 0
    for _, enemy in ipairs(game.enemies) do
        if not enemy.isDead then aliveEnemies = aliveEnemies + 1 end
    end
    
    if aliveEnemies == 0 and #game.deadBodies == 0 and not game.player.isDead then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", love.graphics.getWidth()/2 - 100, 160, 200, 40, 8, 8)
        love.graphics.setColor(0.2, 1, 0.3)
        love.graphics.print("All enemies defeated!", love.graphics.getWidth()/2 - 70, 170)
    end
    
    love.graphics.setColor(1, 1, 1)
end

return UI

