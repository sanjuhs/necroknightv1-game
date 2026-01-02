-- Menu System for Legend of the Necro-Knight
local Config = require("src.config")

local Menu = {}
Menu.__index = Menu

-- Menu states
Menu.STATE = {
    MAIN = "main",
    PLAYING = "playing",
    PAUSED = "paused",
    SETTINGS = "settings"
}

function Menu.new()
    local self = setmetatable({}, Menu)
    
    self.state = Menu.STATE.MAIN
    self.previousState = nil
    
    -- Animation timers
    self.titleTimer = 0
    self.menuTimer = 0
    self.selectedIndex = 1
    
    -- Main menu options
    self.mainMenuOptions = {
        { text = "Start Game", action = "start" },
        { text = "Continue", action = "continue", disabled = true },
        { text = "Settings", action = "settings" },
        { text = "Level Editor", action = "editor", disabled = true },
        { text = "Quit", action = "quit" }
    }
    
    -- Pause menu options
    self.pauseMenuOptions = {
        { text = "Resume", action = "resume" },
        { text = "Save Game", action = "save" },
        { text = "Settings", action = "settings" },
        { text = "Quit to Menu", action = "quit_menu" }
    }
    
    -- Settings options
    self.settingsOptions = {
        { text = "Music Volume", type = "slider", value = 80, min = 0, max = 100 },
        { text = "SFX Volume", type = "slider", value = 80, min = 0, max = 100 },
        { text = "Show FPS", type = "toggle", value = true },
        { text = "Show Minimap", type = "toggle", value = true },
        { text = "Back", action = "back" }
    }
    
    self.currentOptions = self.mainMenuOptions
    
    -- Check for save file
    self:checkSaveFile()
    
    return self
end

function Menu:checkSaveFile()
    local info = love.filesystem.getInfo("savegame.dat")
    if info then
        self.mainMenuOptions[2].disabled = false
    else
        self.mainMenuOptions[2].disabled = true
    end
end

function Menu:update(dt)
    self.titleTimer = self.titleTimer + dt
    self.menuTimer = self.menuTimer + dt
end

function Menu:draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    if self.state == Menu.STATE.MAIN then
        self:drawMainMenu(screenW, screenH)
    elseif self.state == Menu.STATE.PAUSED then
        self:drawPauseMenu(screenW, screenH)
    elseif self.state == Menu.STATE.SETTINGS then
        self:drawSettings(screenW, screenH)
    end
end

function Menu:drawMainMenu(screenW, screenH)
    -- Dark background with gradient feel
    love.graphics.setColor(0.05, 0.08, 0.12, 1)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    
    -- Animated background particles (simple dots)
    love.graphics.setColor(0.2, 0.3, 0.4, 0.3)
    for i = 1, 50 do
        local x = (i * 73 + self.titleTimer * 20) % screenW
        local y = (i * 47 + math.sin(self.titleTimer + i) * 30) % screenH
        love.graphics.circle("fill", x, y, 2)
    end
    
    -- Title glow effect
    local pulse = 0.7 + 0.3 * math.sin(self.titleTimer * 2)
    
    -- Title shadow/glow
    love.graphics.setColor(0.8, 0.6, 0.2, 0.3 * pulse)
    for i = 1, 3 do
        self:drawTitle(screenW / 2 + i, 120 + i, pulse)
    end
    
    -- Main title
    love.graphics.setColor(1, 0.85, 0.3, 1)
    self:drawTitle(screenW / 2, 120, pulse)
    
    -- Subtitle
    love.graphics.setColor(0.7, 0.7, 0.8, 0.8)
    local subtitle = "~ Rise. Command. Conquer. ~"
    local subWidth = love.graphics.getFont():getWidth(subtitle)
    love.graphics.print(subtitle, screenW / 2 - subWidth / 2, 185)
    
    -- Menu options
    self:drawMenuOptions(self.mainMenuOptions, screenW / 2, 280)
    
    -- Footer
    love.graphics.setColor(0.5, 0.5, 0.6, 0.5)
    love.graphics.print("v0.1 - Made with Love2D", 20, screenH - 30)
    love.graphics.print("Arrow Keys / WASD to navigate, Enter to select", screenW - 320, screenH - 30)
end

function Menu:drawTitle(x, y, pulse)
    -- Draw "LEGEND OF THE" smaller
    local font = love.graphics.getFont()
    local preTitle = "LEGEND OF THE"
    local preTitleWidth = font:getWidth(preTitle)
    love.graphics.print(preTitle, x - preTitleWidth / 2, y - 35)
    
    -- Draw "NECRO-KNIGHT" larger (we'll fake it with multiple prints)
    local mainTitle = "NECRO-KNIGHT"
    local mainTitleWidth = font:getWidth(mainTitle) * 2
    
    -- Scale up the main title
    love.graphics.push()
    love.graphics.translate(x, y + 10)
    love.graphics.scale(2.5, 2.5)
    love.graphics.print(mainTitle, -font:getWidth(mainTitle) / 2, 0)
    love.graphics.pop()
end

function Menu:drawPauseMenu(screenW, screenH)
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    
    -- Pause title
    love.graphics.setColor(1, 0.85, 0.3, 1)
    local title = "PAUSED"
    local font = love.graphics.getFont()
    
    love.graphics.push()
    love.graphics.translate(screenW / 2, 150)
    love.graphics.scale(2, 2)
    love.graphics.print(title, -font:getWidth(title) / 2, 0)
    love.graphics.pop()
    
    -- Menu options
    self:drawMenuOptions(self.pauseMenuOptions, screenW / 2, 250)
end

function Menu:drawSettings(screenW, screenH)
    -- Background
    if self.previousState == Menu.STATE.MAIN then
        love.graphics.setColor(0.05, 0.08, 0.12, 1)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    else
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    end
    
    -- Title
    love.graphics.setColor(1, 0.85, 0.3, 1)
    local title = "SETTINGS"
    local font = love.graphics.getFont()
    
    love.graphics.push()
    love.graphics.translate(screenW / 2, 100)
    love.graphics.scale(2, 2)
    love.graphics.print(title, -font:getWidth(title) / 2, 0)
    love.graphics.pop()
    
    -- Settings options
    self:drawSettingsOptions(screenW / 2, 200)
end

function Menu:drawMenuOptions(options, centerX, startY)
    local font = love.graphics.getFont()
    local spacing = 50
    
    for i, option in ipairs(options) do
        local y = startY + (i - 1) * spacing
        local isSelected = (i == self.selectedIndex)
        local isDisabled = option.disabled
        
        -- Selection indicator
        if isSelected then
            local pulse = 0.8 + 0.2 * math.sin(self.menuTimer * 5)
            
            -- Glowing background
            love.graphics.setColor(1, 0.85, 0.3, 0.2 * pulse)
            love.graphics.rectangle("fill", centerX - 150, y - 5, 300, 35, 5, 5)
            
            -- Border
            love.graphics.setColor(1, 0.85, 0.3, 0.8)
            love.graphics.rectangle("line", centerX - 150, y - 5, 300, 35, 5, 5)
            
            -- Arrow indicators
            love.graphics.print("►", centerX - 140, y)
            love.graphics.print("◄", centerX + 125, y)
        end
        
        -- Text
        if isDisabled then
            love.graphics.setColor(0.4, 0.4, 0.4, 0.6)
        elseif isSelected then
            love.graphics.setColor(1, 0.95, 0.7, 1)
        else
            love.graphics.setColor(0.8, 0.8, 0.85, 0.9)
        end
        
        local textWidth = font:getWidth(option.text)
        love.graphics.print(option.text, centerX - textWidth / 2, y)
    end
end

function Menu:drawSettingsOptions(centerX, startY)
    local font = love.graphics.getFont()
    local spacing = 55
    
    for i, option in ipairs(self.settingsOptions) do
        local y = startY + (i - 1) * spacing
        local isSelected = (i == self.selectedIndex)
        
        -- Selection indicator
        if isSelected then
            local pulse = 0.8 + 0.2 * math.sin(self.menuTimer * 5)
            love.graphics.setColor(1, 0.85, 0.3, 0.2 * pulse)
            love.graphics.rectangle("fill", centerX - 200, y - 5, 400, 40, 5, 5)
            love.graphics.setColor(1, 0.85, 0.3, 0.8)
            love.graphics.rectangle("line", centerX - 200, y - 5, 400, 40, 5, 5)
        end
        
        -- Label
        if isSelected then
            love.graphics.setColor(1, 0.95, 0.7, 1)
        else
            love.graphics.setColor(0.8, 0.8, 0.85, 0.9)
        end
        
        love.graphics.print(option.text, centerX - 180, y)
        
        -- Value display
        if option.type == "slider" then
            -- Slider bar
            local barX = centerX + 50
            local barW = 120
            love.graphics.setColor(0.3, 0.3, 0.35, 0.8)
            love.graphics.rectangle("fill", barX, y + 5, barW, 15, 3, 3)
            
            -- Slider fill
            love.graphics.setColor(1, 0.85, 0.3, 0.9)
            local fillW = (option.value / option.max) * barW
            love.graphics.rectangle("fill", barX, y + 5, fillW, 15, 3, 3)
            
            -- Value text
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.print(tostring(option.value) .. "%", barX + barW + 10, y)
            
        elseif option.type == "toggle" then
            local toggleX = centerX + 100
            if option.value then
                love.graphics.setColor(0.3, 0.8, 0.3, 0.9)
                love.graphics.print("ON", toggleX, y)
            else
                love.graphics.setColor(0.8, 0.3, 0.3, 0.9)
                love.graphics.print("OFF", toggleX, y)
            end
        end
    end
    
    -- Instructions
    love.graphics.setColor(0.6, 0.6, 0.65, 0.7)
    love.graphics.print("Left/Right to adjust, Enter to confirm", centerX - 120, startY + #self.settingsOptions * spacing + 20)
end

function Menu:keypressed(key, game)
    if self.state == Menu.STATE.MAIN then
        return self:handleMainMenuInput(key, game)
    elseif self.state == Menu.STATE.PAUSED then
        return self:handlePauseMenuInput(key, game)
    elseif self.state == Menu.STATE.SETTINGS then
        return self:handleSettingsInput(key, game)
    end
    return nil
end

function Menu:handleMainMenuInput(key, game)
    if key == "up" or key == "w" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.mainMenuOptions
        end
        -- Skip disabled options
        while self.mainMenuOptions[self.selectedIndex].disabled do
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then
                self.selectedIndex = #self.mainMenuOptions
            end
        end
    elseif key == "down" or key == "s" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.mainMenuOptions then
            self.selectedIndex = 1
        end
        -- Skip disabled options
        while self.mainMenuOptions[self.selectedIndex].disabled do
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > #self.mainMenuOptions then
                self.selectedIndex = 1
            end
        end
    elseif key == "return" or key == "space" then
        local option = self.mainMenuOptions[self.selectedIndex]
        if not option.disabled then
            if option.action == "start" then
                self.state = Menu.STATE.PLAYING
                return "start_new_game"
            elseif option.action == "continue" then
                self.state = Menu.STATE.PLAYING
                return "load_game"
            elseif option.action == "settings" then
                self.previousState = Menu.STATE.MAIN
                self.state = Menu.STATE.SETTINGS
                self.selectedIndex = 1
            elseif option.action == "quit" then
                love.event.quit()
            end
        end
    end
    return nil
end

function Menu:handlePauseMenuInput(key, game)
    if key == "escape" then
        self.state = Menu.STATE.PLAYING
        return "resume"
    elseif key == "up" or key == "w" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.pauseMenuOptions
        end
    elseif key == "down" or key == "s" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.pauseMenuOptions then
            self.selectedIndex = 1
        end
    elseif key == "return" or key == "space" then
        local option = self.pauseMenuOptions[self.selectedIndex]
        if option.action == "resume" then
            self.state = Menu.STATE.PLAYING
            return "resume"
        elseif option.action == "save" then
            return "save_game"
        elseif option.action == "settings" then
            self.previousState = Menu.STATE.PAUSED
            self.state = Menu.STATE.SETTINGS
            self.selectedIndex = 1
        elseif option.action == "quit_menu" then
            self.state = Menu.STATE.MAIN
            self.selectedIndex = 1
            return "quit_to_menu"
        end
    end
    return nil
end

function Menu:handleSettingsInput(key, game)
    local option = self.settingsOptions[self.selectedIndex]
    
    if key == "escape" then
        self.state = self.previousState
        self.selectedIndex = 1
    elseif key == "up" or key == "w" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.settingsOptions
        end
    elseif key == "down" or key == "s" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.settingsOptions then
            self.selectedIndex = 1
        end
    elseif key == "left" or key == "a" then
        if option.type == "slider" then
            option.value = math.max(option.min, option.value - 10)
        elseif option.type == "toggle" then
            option.value = not option.value
        end
    elseif key == "right" or key == "d" then
        if option.type == "slider" then
            option.value = math.min(option.max, option.value + 10)
        elseif option.type == "toggle" then
            option.value = not option.value
        end
    elseif key == "return" or key == "space" then
        if option.action == "back" then
            self.state = self.previousState
            self.selectedIndex = 1
        elseif option.type == "toggle" then
            option.value = not option.value
        end
    end
    return nil
end

function Menu:pause()
    if self.state == Menu.STATE.PLAYING then
        self.state = Menu.STATE.PAUSED
        self.selectedIndex = 1
    end
end

function Menu:isPlaying()
    return self.state == Menu.STATE.PLAYING
end

function Menu:getSettings()
    return {
        musicVolume = self.settingsOptions[1].value / 100,
        sfxVolume = self.settingsOptions[2].value / 100,
        showFPS = self.settingsOptions[3].value,
        showMinimap = self.settingsOptions[4].value
    }
end

return Menu

