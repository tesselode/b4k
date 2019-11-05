local Object = require 'lib.classic'

local Tile = Object:extend()

Tile.colors = {
	{1, 1/3, 1/3},
	{1/3, 1, 1/3},
	{1/3, 1/3, 1},
	{1, 1, 1/3},
}
Tile.rotationAnimationDuration = 1/3
Tile.clearAnimationDuration = 1/2

function Tile:new(board, x, y)
	self.board = board
	self.x = x
	self.y = y
	self.color = love.math.random(1, #self.colors)
	self.cleared = false
	self.scale = 1
	self.rotationAnimation = {
		playing = false,
		centerX = nil,
		centerY = nil,
		angle = nil,
		tween = nil,
		flip = nil,
	}
	self.playingClearAnimation = false
end

function Tile:isFree()
	if self.rotationAnimation.playing then return false end
	if self.playingClearAnimation then return false end
	return true
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
	self.rotationAnimation.tween = self.board.timers:tween(
		self.rotationAnimationDuration,
		self.rotationAnimation,
		{angle = angle + angleIncrement})
		:ease('back', 'out', 1.5)
	self.rotationAnimation.flip = self.board.timers:flip(
		self.rotationAnimationDuration,
		self.rotationAnimation,
		'playing')
	-- change the tile's actual position
	self.x = self.x + deltaX
	self.y = self.y + deltaY
end

function Tile:finishClearAnimation()
	self.playingClearAnimation = false
end

function Tile:clear()
	self.cleared = true
	self.playingClearAnimation = true
	self.board.timers:tween(self.clearAnimationDuration, self, {scale = 0})
		:ease('back', 'in')
		:after(0, self.finishClearAnimation, self)
end

function Tile:getDisplayPosition()
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
	local x, y = self:getDisplayPosition()
	love.graphics.rectangle(
		'fill',
		x + .5 - .5 * self.scale, y + .5 - .5 * self.scale,
		self.scale, self.scale
	)
	love.graphics.pop()
end

return Tile
