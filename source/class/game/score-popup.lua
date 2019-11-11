local color = require 'color'
local font = require 'font'
local Object = require 'lib.classic'

local ScorePopup = Object:extend()

ScorePopup.floatSpeed = 100
ScorePopup.blinkSpeed = 3

function ScorePopup:onFinishAnimation()
	self.removeFromPool = true
end

function ScorePopup:new(pool, x, y, squares, score)
	self.pool = pool
	self.x = x
	self.y = y
	self.squares = squares
	self.score = score
	self.blinkPhase = 0
	self.scale = 0
	self.pool.data.timers
		:tween(.5, self, {scale = 1})
			:ease('back', 'out')
		:after(3/4)
		:tween(1/4, self, {scale = 0})
			:ease('power', 'in', 3)
		:after(0, self.onFinishAnimation, self)
end

function ScorePopup:update(dt)
	self.y = self.y - self.floatSpeed * dt
	self.blinkPhase = self.blinkPhase + self.blinkSpeed * dt
	while self.blinkPhase >= 1 do
		self.blinkPhase = self.blinkPhase - 1
	end
end

function ScorePopup:draw()
	local squaresText = self.squares == 1 and '1 square'
		or string.format('%i squares', self.squares)
	local text = squaresText .. '\n+' .. self.score
	self.pool.data.ui
		:new('paragraph', font.scorePopup, text, 100000, 'center')
			:center(self.x):middle(self.y)
			:color(self.blinkPhase < .5 and color.orange or color.white)
			:shadowColor(color.maroon)
			:shadowOffset(4, 4)
			:scale(self.scale)
end

return ScorePopup
