local color = require 'color'
local constant = require 'constant'
local Object = require 'lib.classic'

local SquareHighlight = Object:extend()

function SquareHighlight:new(pool, x, y)
	self.pool = pool
	self.x = x
	self.y = y
	self.active = false
	self.alpha = 0
	self.scale = 1
end

function SquareHighlight:activate()
	if self.active then return end
	self.active = true
	if self.tween then self.tween:stop() end
	self.alpha = 0
	self.scale = 1.5
	self.tween = self.pool.data.tweens:to(self, .15, {
		alpha = 1,
		scale = 1,
	})
end

function SquareHighlight:deactivate()
	if not self.active then return end
	self.active = false
	if self.tween then self.tween:stop() end
	self.tween = self.pool.data.tweens:to(self, .15, {
		alpha = 0,
	})
end

function SquareHighlight:burst()
	if not self.active then return end
	self.active = false
	if self.tween then self.tween:stop() end
	self.tween = self.pool.data.tweens:to(self, 1/3, {
		alpha = 0,
		scale = 1.5,
	})
end

function SquareHighlight:onBoardCheckedSquares(board, squares, totalSquares, newSquares)
	local index = self.y * constant.boardWidth + self.x
	if squares[index] then
		self:activate()
	else
		self:deactivate()
	end
end

function SquareHighlight:onBoardClearingTiles(board, clearedTiles, numClearedTiles)
	self:burst()
end

function SquareHighlight:drawOnBoard()
	love.graphics.push 'all'
	love.graphics.setColor(color.withAlpha(color.white, self.alpha))
	love.graphics.setLineWidth(.1)
	love.graphics.rectangle('line',
		self.x + 1 - 1 * self.scale,
		self.y + 1 - 1 * self.scale,
		2 * self.scale,
		2 * self.scale)
	love.graphics.pop()
end

return SquareHighlight
