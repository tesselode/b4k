local color = require 'color'
local image = require 'image'
local Object = require 'lib.classic'
local quad = require 'image.quad'
local TileClearParticles = require 'scene.game.entity.tile-clear-particles'
local WildTileVisual = require 'scene.game.entity.board.tile.wild-tile-visual'

local Tile = Object:extend()

Tile.numColors = 4
Tile.primaryColors = {
	color.red,
	color.green,
	color.lightBlue,
	color.lightOrange,
}
Tile.quads = {
	quad.tile.regular[1],
	quad.tile.regular[2],
	quad.tile.regular[3],
	quad.tile.regular[4],
	inert = quad.tile.inert,
}
Tile.rotationAnimationDuration = 1/3
Tile.clearAnimationDuration = .4
Tile.gravity = 50

function Tile:new(pool, x, y, tileColor)
	self.pool = pool
	self.x = x
	self.y = y
	self.color = tileColor or love.math.random(self.numColors)
	self.state = 'idle'
	self.rotationAnimation = {
		tween = nil,
		angle = nil,
		centerX = nil,
		centerY = nil,
	}
	self.fallAnimation = {
		y = nil,
		vy = nil,
	}
	self.scale = 1
	self.wildTileVisual = WildTileVisual(pool)
end

function Tile:isIdle()
	return self.state == 'idle' or self.state == 'cleared'
end

function Tile:rotate(centerX, centerY, orientation, counterClockwise)
	self.state = 'rotating'
	local animation = self.rotationAnimation
	if animation.tween then animation.tween:stop() end
	local dx, dy
	if counterClockwise then
		if orientation == 'topLeft' then dx, dy = 0, 1 end
		if orientation == 'topRight' then dx, dy = -1, 0 end
		if orientation == 'bottomRight' then dx, dy = 0, -1 end
		if orientation == 'bottomLeft' then dx, dy = 1, 0 end
	else
		if orientation == 'topLeft' then dx, dy = 1, 0 end
		if orientation == 'topRight' then dx, dy = 0, 1 end
		if orientation == 'bottomRight' then dx, dy = -1, 0 end
		if orientation == 'bottomLeft' then dx, dy = 0, -1 end
	end
	animation.centerX, animation.centerY = centerX, centerY
	animation.angle = math.atan2(self.y + .5 - centerY, self.x + .5 - centerX)
	local endAngle = animation.angle + (counterClockwise and -math.pi/2 or math.pi/2)
	animation.tween = self.pool.data.tweens:to(animation, self.rotationAnimationDuration, {angle = endAngle})
		:ease 'backout'
		:oncomplete(function() self.state = 'idle' end)
	self.x = self.x + dx
	self.y = self.y + dy
end

-- tells the tile to fall 1 unit. enters the falling state and
-- starts the falling animation if it isn't already running
function Tile:fall()
	local previousY = self.y
	self.y = self.y + 1
	if self.state ~= 'falling' then
		self.state = 'falling'
		self.fallAnimation.y = previousY
		self.fallAnimation.vy = 0
	end
end

function Tile:clear()
	self.state = 'clearing'
	self.pool.data.tweens:to(self, self.clearAnimationDuration, {scale = 0})
		:ease 'quartout'
		:oncomplete(function() self.state = 'cleared' end)
	self.pool:queue(TileClearParticles(self))
end

function Tile:update(dt)
	self.wildTileVisual:update(dt)
	if self.state == 'falling' then
		local animation = self.fallAnimation
		animation.vy = animation.vy + self.gravity * dt
		animation.y = animation.y + animation.vy * dt
		if animation.y >= self.y then
			self.state = 'idle'
		end
	end
end

function Tile:getDisplayPosition()
	if self.state == 'rotating' then
		local animation = self.rotationAnimation
		local distance = math.sqrt(.5)
		return animation.centerX + distance * math.cos(animation.angle) - .5,
			animation.centerY + distance * math.sin(animation.angle) - .5
	end
	if self.state == 'falling' then
		return self.x, self.fallAnimation.y
	end
	return self.x, self.y
end

function Tile:drawRegularTile()
	local q = self.quads[self.color]
	local _, _, size = q:getViewport()
	local scale = self.scale / size
	love.graphics.draw(image.tiles, q, 0, 0, 0, scale)
end

function Tile:draw()
	love.graphics.push 'all'
	local x, y = self:getDisplayPosition()
	love.graphics.translate(x + .5, y + .5)
	self.wildTileVisual:draw()
	love.graphics.pop()
end

return Tile
