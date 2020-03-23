local color = require 'color'
local Object = require 'lib.classic'

local Tile = Object:extend()

Tile.colors = {
	color.green,
	color.red,
	color.blue,
	color.yellow,
}

function Tile:new(x, y, tileColor)
	self.x = x
	self.y = y
	self.color = tileColor or love.math.random(#self.colors)
end

function Tile:draw()
	love.graphics.push 'all'
	love.graphics.setColor(self.colors[self.color])
	love.graphics.rectangle('fill', self.x, self.y, 1, 1)
	love.graphics.pop()
end

return Tile
