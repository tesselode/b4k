local color = require 'color'
local Object = require 'lib.classic'
local Promise = require 'util.promise'
local TileClearParticles = require 'scene.game.entity.tile-clear-particles'

local Tile = Object:extend()

Tile.colors = {
	color.green,
	color.blue,
	color.yellow,
	color.red,
}
Tile.rotationAnimationDuration = 1/3
Tile.clearAnimationDuration = .4
Tile.gravity = 50

function Tile:new(pool, x, y, tileColor)
	self.pool = pool
	self.x = x
	self.y = y
	self.color = tileColor or love.math.random(1, #self.colors)
	self.cleared = false
	self.scale = 1
	self.rotationAnimation = {
		playing = false,
		centerX = nil,
		centerY = nil,
		angle = nil,
		tween = nil,
		flip = nil,
		promise = nil,
	}
	self.fallAnimation = {
		playing = false,
		y = nil,
		targetY = nil,
		velocity = nil,
		promise = nil,
	}
end

function Tile:clear()
	return Promise(function(finish)
		self.pool:queue(TileClearParticles(self))
		self.cleared = true
		self.pool.data.tweens:to(self, self.clearAnimationDuration, {scale = 0})
			:ease 'quartout'
			:oncomplete(function()
				finish()
			end)
	end)
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

--[[
	Tells the tile to fall one unit downward and starts
	the falling animation if it isn't already playing.
]]
function Tile:fall()
	if self.fallAnimation.playing then
		self.fallAnimation.targetY = self.fallAnimation.targetY + 1
	else
		self.fallAnimation.playing = true
		self.fallAnimation.y = self.y
		self.fallAnimation.targetY = self.y + 1
		self.fallAnimation.velocity = 0
		self.fallAnimation.promise = Promise()
		return self.fallAnimation.promise
	end
end

function Tile:update(dt)
	if self.fallAnimation.playing then
		self.fallAnimation.velocity = self.fallAnimation.velocity + self.gravity * dt
		self.fallAnimation.y = self.fallAnimation.y + self.fallAnimation.velocity * dt
		if self.fallAnimation.y >= self.fallAnimation.targetY then
			self.y = self.fallAnimation.targetY
			self.fallAnimation.playing = false
			self.fallAnimation.y = nil
			self.fallAnimation.targetY = nil
			self.fallAnimation.velocity = nil
			self.fallAnimation.promise:finish()
		end
	end
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
	if self.color == 'grey' then
		love.graphics.setColor(color.maroon)
	else
		love.graphics.setColor(self.colors[self.color])
	end
	local x, y = self:getDisplayPosition()
	love.graphics.rectangle(
		'fill',
		x + .5 - .5 * self.scale, y + .5 - .5 * self.scale,
		self.scale, self.scale
	)
	love.graphics.pop()
end

return Tile