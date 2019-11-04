local keeper = require 'lib.keeper'
local Object = require 'lib.classic'

local Tile = Object:extend()

Tile.colors = {
	{1, 1/3, 1/3},
	{1/3, 1, 1/3},
	{1/3, 1/3, 1},
}
Tile.rotationAnimationDuration = 1/3

function Tile:new(x, y)
	self.timers = keeper.new()
	self.x = x
	self.y = y
	self.color = love.math.random(1, #self.colors)
	self.rotationAnimation = {
		playing = false,
		centerX = nil,
		centerY = nil,
		angle = nil,
		tween = nil,
		flip = nil,
	}
end

function Tile:update(dt)
	self.timers:update(dt)
end

function Tile:rotate(corner, counterClockwise)
	-- cancel any running rotation animation
	if self.rotationAnimation.tween then
		self.rotationAnimation.tween:cancel()
	end
	if self.rotationAnimation.flip then
		self.rotationAnimation.flip.time = 0
	end
	-- get the center of rotation (and while we're at it),
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
	-- play the rotation animation
	local angle = math.atan2(self.y + .5 - centerY, self.x + .5 - centerX)
	self.rotationAnimation.centerX = centerX
	self.rotationAnimation.centerY = centerY
	self.rotationAnimation.angle = angle
	local angleIncrement = counterClockwise and -math.pi/2 or math.pi/2
	self.rotationAnimation.tween = self.timers:tween(
		self.rotationAnimationDuration,
		self.rotationAnimation,
		{angle = angle + angleIncrement})
		:ease('back', 'out', 1.5)
	self.rotationAnimation.flip = self.timers:flip(
		self.rotationAnimationDuration,
		self.rotationAnimation,
		'playing')
	-- change the tile's actual position
	self.x = self.x + deltaX
	self.y = self.y + deltaY
end

function Tile:_getDisplayPosition()
	if self.rotationAnimation.playing then
		local x = self.rotationAnimation.centerX + math.sqrt(2)/2 * math.cos(self.rotationAnimation.angle)
		local y = self.rotationAnimation.centerY + math.sqrt(2)/2 * math.sin(self.rotationAnimation.angle)
		return x - .5, y - .5
	end
	return self.x, self.y
end

function Tile:_draw()
	love.graphics.push 'all'
	love.graphics.setColor(self.colors[self.color])
	local x, y = self:_getDisplayPosition()
	love.graphics.rectangle('fill', x, y, 1, 1)
	love.graphics.pop()
end

return Tile
