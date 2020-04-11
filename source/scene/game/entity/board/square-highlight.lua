local color = require 'color'
local Object = require 'lib.classic'
local Tile = require 'scene.game.entity.board.tile'

local SquareHighlight = Object:extend()

function SquareHighlight:new(pool, x, y)
	self.pool = pool
	self.x = x
	self.y = y
	self.color = color.white
	self.active = false
	self.scale = 1
	self.alpha = 0
end

function SquareHighlight:setColor(c)
	self.color = Tile.primaryColors[c]
end

function SquareHighlight:setActive(active)
	if active and not self.active then
		self.scale = 1.5
		self.pool.data.tweens:to(self, .15, {scale = 1, alpha = 1})
	elseif self.active and not active then
		self.pool.data.tweens:to(self, .15, {alpha = 0})
	end
	self.active = active
end

function SquareHighlight:onClearTiles()
	if self.active then
		self.active = false
		self.pool.data.tweens:to(self, 1/3, {alpha = 0, scale = 1.5})
	end
end

function SquareHighlight:drawBackground()
	love.graphics.push 'all'
	love.graphics.setColor(color.withAlpha(self.color, self.alpha / 6))
	love.graphics.rectangle('fill', self.x, self.y, 2, 2)
	love.graphics.pop()
end

function SquareHighlight:draw()
	love.graphics.push 'all'
	love.graphics.setLineWidth(.1)
	love.graphics.translate(self.x + 1, self.y + 1)
	love.graphics.scale(self.scale)
	love.graphics.setColor(color.withAlpha(color.white, self.alpha))
	love.graphics.rectangle('line', -1, -1, 2, 2)
	love.graphics.setColor(color.withAlpha(self.color, self.alpha / 4))
	love.graphics.rectangle('line', -1, -1, 2, 2)
	love.graphics.pop()
end

return SquareHighlight
