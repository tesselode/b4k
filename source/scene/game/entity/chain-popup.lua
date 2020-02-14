local color = require 'color'
local font = require 'font'
local Object = require 'lib.classic'

local ChainPopup = Object:extend()

ChainPopup.floatSpeed = 100
ChainPopup.blinkSpeed = 3

function ChainPopup:new(pool, x, y)
	self.pool = pool
	self.x = x
	self.y = y
	self.scale = .5
	self.alpha = 1
	self.pool.data.tweens:to(self, 3/4, {scale = 1, alpha = 0})
		:ease 'linear'
		:oncomplete(function() self.removeFromPool = true end)
end

function ChainPopup:draw()
	self.pool.data.layout
		:new('text', font.scorePopup, 'chain')
			:centerX(self.x):centerY(self.y)
			:color(color.withAlpha(color.white, self.alpha))
			:shadowColor(color.withAlpha(color.maroon, self.alpha))
			:shadowOffset(4, 4)
			:scale(self.scale)
end

return ChainPopup
