-- https://chrismdp.com/2015/06/how-to-quickly-add-bloom-to-your-engine/

local Object = require 'lib.classic'

local Bloom = Object:extend()

Bloom.spread = 1/512
Bloom.stages = 8
Bloom.opacity = 1/16
Bloom.minCanvasSize = 10

function Bloom:createCanvases()
	self.mainCanvas = {love.graphics.newCanvas(), stencil = true}
	self.blurCanvases = {}
	for i = 1, self.stages do
		-- scale is halved each time: 1, 1/2, 1/4, 1/8, etc.
		local scale = 1 / (2 ^ (i - 1))
		local width = math.max(love.graphics.getWidth() * scale, 1)
		local height = math.max(love.graphics.getWidth() * scale, 1)
		if width < self.minCanvasSize or height < self.minCanvasSize then
			break
		end
		table.insert(self.blurCanvases, {
			-- pass 1: horizontal blur
			{love.graphics.newCanvas(width, height), stencil = true},
			-- pass 2: vertical blur
			{love.graphics.newCanvas(width, height), stencil = true},
		})
	end
end

function Bloom:updateShaderOffsets()
	local aspectRatio = love.graphics.getWidth() / love.graphics.getHeight()
	self.horizontalBlurShader:send('offset', {self.spread, 0})
	self.verticalBlurShader:send('offset', {0, self.spread * aspectRatio})
end

function Bloom:createShaders()
	self.horizontalBlurShader = love.graphics.newShader 'shader/blur.glsl'
	self.verticalBlurShader = love.graphics.newShader 'shader/blur.glsl'
	self:updateShaderOffsets()
end

function Bloom:new()
	self:createCanvases()
	self:createShaders()
end

function Bloom:resize()
	self:createCanvases()
	self:updateShaderOffsets()
end

function Bloom:start()
	love.graphics.push 'all'
	love.graphics.setCanvas(self.mainCanvas)
	love.graphics.clear()
end

function Bloom:finish()
	love.graphics.pop()

	love.graphics.draw(self.mainCanvas[1])

	-- render to the blur canvases
	for i in ipairs(self.blurCanvases) do
		local scale = 1 / (2 ^ (i - 1))
		-- horizontal blur
		love.graphics.push 'all'
		love.graphics.setCanvas(self.blurCanvases[i][1])
		love.graphics.setShader(self.horizontalBlurShader)
		love.graphics.clear()
		love.graphics.draw(self.mainCanvas[1], 0, 0, 0, scale)
		love.graphics.pop()
		-- vertical blur
		love.graphics.push 'all'
		love.graphics.setCanvas(self.blurCanvases[i][2])
		love.graphics.setShader(self.verticalBlurShader)
		love.graphics.clear()
		love.graphics.draw(self.blurCanvases[i][1][1])
		love.graphics.pop()
		-- blend the blurred canvas with the main canvas
		love.graphics.push 'all'
		love.graphics.setBlendMode 'add'
		love.graphics.setColor(1, 1, 1, self.opacity)
		love.graphics.draw(self.blurCanvases[i][2][1], 0, 0, 0, 1 / scale)
		love.graphics.pop()
	end

	love.graphics.print(('Shader stages: %i'):format(#self.blurCanvases), 0, 32)
end

return Bloom
