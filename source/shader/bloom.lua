local Object = require 'lib.classic'

local Bloom = Object:extend()

Bloom.stages = 10

function Bloom:createCanvases()
	self.canvases = {}
	for i = 1, self.stages do
		local scale = 1 / (2 ^ (i - 1))
		table.insert(self.canvases, {
			love.graphics.newCanvas(
				love.graphics.getWidth() * scale,
				love.graphics.getHeight() * scale
			),
			stencil = true,
		})
	end
end

function Bloom:new()
	self:createCanvases()
end

function Bloom:resize()
	self:createCanvases()
end

function Bloom:start()
	love.graphics.push 'all'
	love.graphics.setCanvas(self.canvases[1])
	love.graphics.clear()
end

function Bloom:finish()
	love.graphics.pop()

	love.graphics.draw(self.canvases[1][1])

	for i = 2, self.stages do
		love.graphics.push 'all'
		love.graphics.setCanvas(self.canvases[i])
		love.graphics.clear()
		love.graphics.draw(self.canvases[i - 1][1], 0, 0, 0, .5)
		love.graphics.pop()

		love.graphics.push 'all'
		love.graphics.setBlendMode 'add'
		love.graphics.setColor(1, 1, 1, 1/8)
		love.graphics.draw(self.canvases[i][1], 0, 0, 0, 2 ^ (i - 1))
		love.graphics.pop()
	end
end

return Bloom
