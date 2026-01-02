-- Animation class for sprite sheet animations
local Config = require("src.config")

local Animation = {}
Animation.__index = Animation

function Animation.new(spriteSheet, frameWidth, frameHeight, row, numFrames, frameDuration)
    local self = setmetatable({}, Animation)
    self.spriteSheet = spriteSheet
    self.frameWidth = frameWidth
    self.frameHeight = frameHeight
    self.row = row
    self.numFrames = numFrames
    self.frameDuration = frameDuration or Config.ANIMATION_FRAME_TIME
    self.currentFrame = 1
    self.timer = 0
    self.quads = {}
    self.finished = false
    self.loop = true
    
    -- Create quads for each frame
    local sheetWidth = spriteSheet:getWidth()
    local sheetHeight = spriteSheet:getHeight()
    
    for i = 1, numFrames do
        local x = (i - 1) * frameWidth
        local y = (row - 1) * frameHeight
        self.quads[i] = love.graphics.newQuad(x, y, frameWidth, frameHeight, sheetWidth, sheetHeight)
    end
    
    return self
end

function Animation:update(dt)
    self.timer = self.timer + dt
    if self.timer >= self.frameDuration then
        self.timer = self.timer - self.frameDuration
        self.currentFrame = self.currentFrame + 1
        if self.currentFrame > self.numFrames then
            if self.loop then
                self.currentFrame = 1
            else
                self.currentFrame = self.numFrames
                self.finished = true
            end
        end
    end
end

function Animation:draw(x, y, scaleX, scaleY, originX, originY)
    scaleX = scaleX or 1
    scaleY = scaleY or 1
    originX = originX or 0
    originY = originY or 0
    love.graphics.draw(self.spriteSheet, self.quads[self.currentFrame], x, y, 0, scaleX, scaleY, originX, originY)
end

function Animation:reset()
    self.currentFrame = 1
    self.timer = 0
    self.finished = false
end

function Animation:clone()
    local clone = Animation.new(self.spriteSheet, self.frameWidth, self.frameHeight, self.row, self.numFrames, self.frameDuration)
    clone.loop = self.loop
    return clone
end

return Animation

