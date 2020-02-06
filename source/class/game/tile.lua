local color = require 'color'
local Object = require 'lib.classic'

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
Tile.clearAnimationDuration = 1/2

--[[
	The spawn animation is delayed based on the x and y position
	of the tile. This way, new tiles spawn in with a diagonal
	sweeping motion across the board. However, if there are
	only new tiles spawning towards the bottom-right corner
	of the board, for example, there will be a noticeable delay
	before any tiles spawn in at all, which looks awkward. The
	minX and minY values are used to offset this delay - these
	are the minimum x and minimum y values out of all the tiles
	that are spawning at the same time. The animation is
	delayed with respect to these values, not the top-left
	corner of the board.
]]
function Tile:playSpawnAnimation(minX, minY)
	self.scale = 0
	local relativeX = self.x - minX
	local relativeY = self.y - minY
	self.pool.data.tweens:to(self, self.spawnAnimationDuration, {scale = 1})
		:ease 'backout'
		:delay((relativeX + relativeY) * self.spawnAnimationStaggerAmount)
end

function Tile:new(pool, x, y, options)
	options = options or {}
	options.spawnAnimationMinX = options.spawnAnimationMinX or 0
	options.spawnAnimationMinY = options.spawnAnimationMinY or 0
	self.pool = pool
	self.x = x
	self.y = y
	self.color = love.math.random(1, #self.colors)
	self.cleared = false
	if options.skipSpawnAnimation then
		self.scale = 1
	else
		self:playSpawnAnimation(options.spawnAnimationMinX, options.spawnAnimationMinY)
	end
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

function Tile:isFree(toRotate)
	if self.rotationAnimation.playing and not toRotate then return false end
	if self.playingClearAnimation then return false end
	return true
end

function Tile:rotate(corner, counterClockwise)
	-- cancel any running rotation animation
	if self.rotationAnimation.tween then
		self.rotationAnimation.tween:stop()
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
		:oncomplete(function() self.rotationAnimation.playing = false end)
	-- change the tile's actual position
	self.x = self.x + deltaX
	self.y = self.y + deltaY
end

function Tile:clear()
	self.cleared = true
	self.playingClearAnimation = true
	self.pool.data.tweens:to(self, self.clearAnimationDuration, {scale = 0})
		:ease 'backin'
		:oncomplete(function() self.playingClearAnimation = false end)
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
