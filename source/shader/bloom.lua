local constant = require 'constant'
local Object = require 'lib.classic'

local Bloom = Object:extend()

Bloom.blurCanvasDownsampleFactor = 20

function Bloom:new()
	self.mainCanvas = love.graphics.newCanvas()
	self.mainCanvas:setFilter('linear', 'linear', 16)
	self.blurCanvas = love.graphics.newCanvas(
		constant.screenWidth / self.blurCanvasDownsampleFactor,
		constant.screenHeight / self.blurCanvasDownsampleFactor
	)
	self.blurCanvas:setFilter('linear', 'linear', 16)
	self.mainCanvasOptions = {self.mainCanvas, stencil = true}
	self.blurCanvasOptions = {self.blurCanvas, stencil = true}
end

function Bloom:resize()
	self.mainCanvas = love.graphics.newCanvas()
	self.mainCanvas:setFilter('linear', 'linear', 16)
	self.mainCanvasOptions = {self.mainCanvas, stencil = true}
end

function Bloom:start()
	love.graphics.push 'all'
	love.graphics.setCanvas(self.mainCanvasOptions)
	love.graphics.clear()
end

function Bloom:finish()
	love.graphics.pop()
	love.graphics.push 'all'
	love.graphics.setCanvas(self.blurCanvasOptions)
	love.graphics.clear()
	love.graphics.draw(self.mainCanvas, 0, 0, 0, 1 / self.blurCanvasDownsampleFactor)
	love.graphics.pop()

	love.graphics.push 'all'
	love.graphics.draw(self.mainCanvas)
	love.graphics.setColor(1, 1, 1, 1/4)
	love.graphics.setBlendMode 'add'
	love.graphics.draw(self.blurCanvas, 0, 0, 0, self.blurCanvasDownsampleFactor)
	love.graphics.pop()
end

return Bloom
