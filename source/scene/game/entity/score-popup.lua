local color = require 'color'
local constant = require 'constant'
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
	local text = ''
	if self.chain > 1 then
		text = text .. 'chain x' .. self.chain .. '\n'
	end
	text = text .. '+' .. self.score
	self.pool.data.ui
		:new('text', font.scorePopup, text, 'center')
			:centerX(self.x):centerY(self.y)
			:scale(self.scale / constant.fontScale)
			:color(self.blinkPhase < .5 and color.lightOrange or color.white)
			:shadowColor(color.coldBlack)
			:shadowOffset(4)
end

return ScorePopup
