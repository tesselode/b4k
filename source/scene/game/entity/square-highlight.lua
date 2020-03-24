local color = require 'color'
local Object = require 'lib.classic'

local SquareHighlight = Object:extend()

function SquareHighlight:new(pool, x, y)
	self.pool = pool
	self.x = x
	self.y = y
	self.active = false
	self.scale = 1
	self.alpha = 0
end

function SquareHighlight:onCheckSquares(squares)
	local squareAtOwnPosition = squares:get(self.x, self.y) and true or false
	if squareAtOwnPosition and not self.active then
		self.scale = 1.5
		self.pool.data.tweens:to(self, .15, {scale = 1, alpha = 1})
	elseif self.active and not squareAtOwnPosition then
		self.pool.data.tweens:to(self, .15, {alpha = 0})
	end
	self.active = squareAtOwnPosition
end

function SquareHighlight:onClearTiles()
	if self.active then
		self.active = false
		self.pool.data.tweens:to(self, 1/3, {alpha = 0, scale = 1.5})
	end
end

function SquareHighlight:drawOnBoard()
	love.graphics.push 'all'
	love.graphics.setColor(color.withAlpha(color.white, self.alpha))
	love.graphics.setLineWidth(.1)
	love.graphics.translate(self.x + 1, self.y + 1)
	love.graphics.scale(self.scale)
	love.graphics.rectangle('line', -1, -1, 2, 2)
	love.graphics.pop()
end

return SquareHighlight
