local Object = require 'lib.classic'

local Tile = Object:extend()

Tile.colors = {
	{1, 1/3, 1/3},
	{1/3, 1, 1/3},
	{1/3, 1/3, 1},
}

function Tile:new(x, y)
	self.x = x
	self.y = y
	self.color = love.math.random(1, #self.colors)
end

function Tile:_draw()
	love.graphics.push 'all'
	love.graphics.setColor(self.colors[self.color])
	love.graphics.rectangle('fill', self.x, self.y, 1, 1)
	love.graphics.pop()
end

return Tile
