local Object = require 'lib.classic'

local Bloom = Object:extend()

Bloom.iterations = 10
Bloom.curve = 16
Bloom.mainOpacity = .95
Bloom.blurOpacity = .25

function Bloom:createCanvases()
	self.mainCanvas = love.graphics.newCanvas()
	self.curveCanvas = love.graphics.newCanvas()
	self.blurCanvas1 = love.graphics.newCanvas()
	self.blurCanvas2 = love.graphics.newCanvas()
	self.canvasOptions = {self.mainCanvas, stencil = true}
end

function Bloom:createShaders()
	self.curveShader = love.graphics.newShader 'shader/curve.glsl'
	self.curveShader:send('curve', self.curve)
	self.blurShader1 = love.graphics.newShader 'shader/blur.glsl'
	self.blurShader2 = love.graphics.newShader 'shader/blur.glsl'
	self.blurShader2:send('vertical', true)
end

function Bloom:new()
	self:createCanvases()
	self:createShaders()
end

function Bloom:resize()
	self:createCanvases()
end

function Bloom:push()
	love.graphics.push 'all'
	love.graphics.setCanvas(self.canvasOptions)
	love.graphics.clear()
end

function Bloom:pop()
	love.graphics.pop()

	-- curve
	love.graphics.push 'all'
	love.graphics.setCanvas(self.curveCanvas)
	love.graphics.clear()
	love.graphics.setShader(self.curveShader)
	love.graphics.draw(self.mainCanvas)
	love.graphics.pop()

	-- blur pass 1
	love.graphics.push 'all'
	love.graphics.setCanvas(self.blurCanvas1)
	love.graphics.clear()
	love.graphics.setShader(self.blurShader1)
	love.graphics.draw(self.curveCanvas)
	love.graphics.pop()

	-- blur pass 2
	love.graphics.push 'all'
	love.graphics.setCanvas(self.blurCanvas2)
	love.graphics.clear()
	love.graphics.setShader(self.blurShader2)
	love.graphics.draw(self.blurCanvas1)
	love.graphics.pop()

	-- additional blur passes
	for _ = 1, self.iterations - 1 do
		love.graphics.push 'all'
		love.graphics.setCanvas(self.blurCanvas1)
		love.graphics.clear()
		love.graphics.setShader(self.blurShader1)
		love.graphics.draw(self.blurCanvas2)
		love.graphics.pop()

		love.graphics.push 'all'
		love.graphics.setCanvas(self.blurCanvas2)
		love.graphics.clear()
		love.graphics.setShader(self.blurShader2)
		love.graphics.draw(self.blurCanvas1)
		love.graphics.pop()
	end

	-- draw everything blended
	love.graphics.push 'all'
	love.graphics.setColor(1, 1, 1, self.mainOpacity)
	love.graphics.draw(self.mainCanvas)
	love.graphics.setColor(1, 1, 1, self.blurOpacity)
	love.graphics.setBlendMode 'add'
	love.graphics.draw(self.blurCanvas2)
	love.graphics.pop()
end

return Bloom
