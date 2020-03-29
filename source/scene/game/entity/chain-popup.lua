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
	local scale = self.scale / 2
	love.graphics.push 'all'
	love.graphics.setFont(font.scorePopup)
	love.graphics.setColor(color.withAlpha(color.maroon, self.alpha))
	util.printf('chain', self.x + 4, self.y + 4, 100000, 'center', 'middle', 0, scale)
	love.graphics.setColor(color.withAlpha(color.white, self.alpha))
	util.printf('chain', self.x, self.y, 100000, 'center', 'middle', 0, scale)
	love.graphics.pop()
end

return ChainPopup
