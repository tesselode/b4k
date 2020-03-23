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

function Tile:rotate(orientation, counterClockwise)
	local dx, dy
	if counterClockwise then
		if orientation == 'topLeft' then dx, dy = 0, 1 end
		if orientation == 'topRight' then dx, dy = -1, 0 end
		if orientation == 'bottomRight' then dx, dy = 0, -1 end
		if orientation == 'bottomLeft' then dx, dy = 1, 0 end
	else
		if orientation == 'topLeft' then dx, dy = 1, 0 end
		if orientation == 'topRight' then dx, dy = 0, 1 end
		if orientation == 'bottomRight' then dx, dy = -1, 0 end
		if orientation == 'bottomLeft' then dx, dy = 0, -1 end
	end
	self.x = self.x + dx
	self.y = self.y + dy
end

function Tile:draw()
	love.graphics.push 'all'
	love.graphics.setColor(self.colors[self.color])
	love.graphics.rectangle('fill', self.x, self.y, 1, 1)
	love.graphics.pop()
end

return Tile
