local color = require 'color'
local font = require 'font'
local Object = require 'lib.classic'
local util = require 'util'

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
	love.graphics.push 'all'
	love.graphics.setFont(font.scorePopup)
	love.graphics.setColor(color.maroon)
	util.printf(text, self.x + 4, self.y + 4, 100000, 'center', 0, self.scale, self.scale, .5, .5)
	love.graphics.setColor(self.blinkPhase < .5 and color.orange or color.white)
	util.printf(text, self.x, self.y, 100000, 'center', 0, self.scale, self.scale, .5, .5)
	love.graphics.pop()
end

return ScorePopup
