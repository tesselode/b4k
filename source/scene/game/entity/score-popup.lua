local color = require 'color'
local font = require 'font'
local Object = require 'lib.classic'

local ScorePopup = Object:extend()

ScorePopup.floatSpeed = 100
ScorePopup.blinkSpeed = 3

function ScorePopup:new(pool, x, y, squares, score, chain)
	self.pool = pool
	self.x = x
	self.y = y
	self.squares = squares
	self.score = score
	self.chain = chain
	self.blinkPhase = 0
	self.scale = 0
	self.pool.data.tweens:to(self, .5, {scale = 1})
		:ease 'backout'
	:after(1/4, {scale = 0})
		:ease 'cubicin'
		:delay(3/4)
		:oncomplete(function() self.removeFromPool = true end)
end

function ScorePopup:update(dt)
	self.y = self.y - self.floatSpeed * dt
	self.blinkPhase = self.blinkPhase + self.blinkSpeed * dt
	while self.blinkPhase >= 1 do
		self.blinkPhase = self.blinkPhase - 1
	end
end

function ScorePopup:draw()
	local text = self.squares == 1 and '1 square'
		or string.format('%i squares', self.squares)
	if self.chain > 1 then
		text = text .. '\nchain x' .. self.chain
	end
	text = text .. '\n+' .. self.score
	self.pool.data.layout
		:new('paragraph', font.scorePopup, text, 100000, 'center')
			:centerX(self.x):centerY(self.y)
			:color(self.blinkPhase < .5 and color.orange or color.white)
			:shadowColor(color.maroon)
			:shadowOffset(4, 4)
			:scale(self.scale)
end

return ScorePopup
