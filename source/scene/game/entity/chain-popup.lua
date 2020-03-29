local color = require 'color'
local font = require 'font'
local Object = require 'lib.classic'
local util = require 'util'

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
	love.graphics.push 'all'
	love.graphics.setFont(font.scorePopup)
	love.graphics.setColor(color.withAlpha(color.maroon, self.alpha))
	util.print('chain', self.x + 4, self.y + 4, 0, self.scale, self.scale, .5, .5)
	love.graphics.setColor(color.withAlpha(color.white, self.alpha))
	util.print('chain', self.x, self.y, 0, self.scale, self.scale, .5, .5)
	love.graphics.pop()
end

return ChainPopup
