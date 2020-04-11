-- https://chrismdp.com/2015/06/how-to-quickly-add-bloom-to-your-engine/

local Object = require 'lib.classic'

local Bloom = Object:extend()

Bloom.stages = 8

function Bloom:createCanvases()
	self.mainCanvas = {love.graphics.newCanvas(), stencil = true}
	self.dimCanvas = {love.graphics.newCanvas(), stencil = true}
	self.blurCanvases = {}
	for i = 1, self.stages do
		-- scale is halved each time: 1, 1/2, 1/4, 1/8, etc.
		local scale = 1 / (2 ^ (i - 1))
		table.insert(self.blurCanvases, {
			-- pass 1: horizontal blur
			{
				love.graphics.newCanvas(
					love.graphics.getWidth() * scale,
					love.graphics.getHeight() * scale
				),
				stencil = true,
			},
			-- pass 2: vertical blur
			{
				love.graphics.newCanvas(
					love.graphics.getWidth() * scale,
					love.graphics.getHeight() * scale
				),
				stencil = true,
			},
		})
	end
end

function Bloom:new()
	self.horizontalBlurShader = love.graphics.newShader 'shader/blur.glsl'
	self.horizontalBlurShader:send('offset', {.00125, 0});
	self.verticalBlurShader = love.graphics.newShader 'shader/blur.glsl'
	self.verticalBlurShader:send('offset', {0, .00125});
	self:createCanvases()
end

function Bloom:resize()
	self:createCanvases()
end

function Bloom:start()
	love.graphics.push 'all'
	love.graphics.setCanvas(self.mainCanvas)
	love.graphics.clear()
end

function Bloom:finish()
	love.graphics.pop()

	love.graphics.draw(self.mainCanvas[1])

	-- render to the dim canvas
	love.graphics.push 'all'
	love.graphics.setCanvas(self.dimCanvas)
	love.graphics.clear()
	love.graphics.setColor(1/8, 1/8, 1/8)
	love.graphics.draw(self.mainCanvas[1])
	love.graphics.pop()

	-- render to the blur canvases
	for i = 1, self.stages do
		local scale = 1 / (2 ^ (i - 1))
		love.graphics.push 'all'
		love.graphics.setCanvas(self.blurCanvases[i][1])
		love.graphics.setShader(self.horizontalBlurShader)
		love.graphics.clear()
		love.graphics.draw(self.dimCanvas[1], 0, 0, 0, scale)
		love.graphics.pop()

		love.graphics.push 'all'
		love.graphics.setCanvas(self.blurCanvases[i][2])
		love.graphics.setShader(self.verticalBlurShader)
		love.graphics.clear()
		love.graphics.draw(self.blurCanvases[i][1][1])
		love.graphics.pop()

		love.graphics.push 'all'
		love.graphics.setBlendMode 'add'
		love.graphics.draw(self.blurCanvases[i][2][1], 0, 0, 0, 1 / scale)
		love.graphics.pop()
	end
end

return Bloom
