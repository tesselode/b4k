local color = require 'color'
local Object = require 'lib.classic'
local Promise = require 'util.promise'

local Tile = Object:extend()

Tile.colors = {
	color.green,
	color.blue,
	color.yellow,
	color.red,
}
Tile.spawnAnimationDuration = 1/2
Tile.spawnAnimationStaggerAmount = .05
Tile.rotationAnimationDuration = 1/3
Tile.clearAnimationDuration = .4
Tile.gravity = 50

function Tile:new(pool, x, y, tileColor)
	self.pool = pool
	self.x = x
	self.y = y
	self.color = tileColor or love.math.random(1, #self.colors)
	self.scale = 1
	self.rotationAnimation = {
		playing = false,
		centerX = nil,
		centerY = nil,
		angle = nil,
		tween = nil,
		flip = nil,
	}
	self.fallAnimation = {
		playing = false,
		y = nil,
		targetY = nil,
		velocity = nil,
	}
end

function Tile:rotate(corner, counterClockwise)
	-- get the center of rotation, and while we're at it,
	-- get the amount to change the tile's actual position
	local centerX, centerY, deltaX, deltaY
	if corner == 'topLeft' then
		centerX, centerY = self.x + 1, self.y + 1
		if counterClockwise then
			deltaX, deltaY = 0, 1
		else
			deltaX, deltaY = 1, 0
		end
	elseif corner == 'topRight' then
		centerX, centerY = self.x, self.y + 1
		if counterClockwise then
			deltaX, deltaY = -1, 0
		else
			deltaX, deltaY = 0, 1
		end
	elseif corner == 'bottomRight' then
		centerX, centerY = self.x, self.y
		if counterClockwise then
			deltaX, deltaY = 0, -1
		else
			deltaX, deltaY = -1, 0
		end
	elseif corner == 'bottomLeft' then
		centerX, centerY = self.x + 1, self.y
		if counterClockwise then
			deltaX, deltaY = 1, 0
		else
			deltaX, deltaY = 0, -1
		end
	end
	-- cancel any running rotation animation
	if self.rotationAnimation.tween then
		self.rotationAnimation.tween:stop()
	end
	-- play the rotation animation
	local promise = Promise(function(finish)
		local angle = math.atan2(self.y + .5 - centerY, self.x + .5 - centerX)
		self.rotationAnimation.playing = true
		self.rotationAnimation.centerX = centerX
		self.rotationAnimation.centerY = centerY
		self.rotationAnimation.angle = angle
		local angleIncrement = counterClockwise and -math.pi/2 or math.pi/2
		self.rotationAnimation.tween = self.pool.data.tweens:to(
			self.rotationAnimation,
			self.rotationAnimationDuration,
			{angle = angle + angleIncrement}
		)
			:ease 'backout'
			:oncomplete(function()
				self.rotationAnimation.playing = false
				finish()
			end)
	end)
	-- move the tile
	self.x = self.x + deltaX
	self.y = self.y + deltaY
	return promise
end

function Tile:update(dt)
end

function Tile:getDisplayPosition()
	if self.rotationAnimation.playing then
		local x = self.rotationAnimation.centerX + math.sqrt(2)/2 * math.cos(self.rotationAnimation.angle)
		local y = self.rotationAnimation.centerY + math.sqrt(2)/2 * math.sin(self.rotationAnimation.angle)
		return x - .5, y - .5
	elseif self.fallAnimation.playing then
		return self.x, self.fallAnimation.y
	end
	return self.x, self.y
end

function Tile:draw()
	love.graphics.push 'all'
	love.graphics.setColor(self.colors[self.color])
	local x, y = self:getDisplayPosition()
	love.graphics.rectangle(
		'fill',
		x + .5 - .5 * self.scale, y + .5 - .5 * self.scale,
		self.scale, self.scale
	)
	love.graphics.pop()
end

return Tile
