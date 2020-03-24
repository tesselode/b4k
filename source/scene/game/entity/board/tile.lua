local color = require 'color'
local flux = require 'lib.flux'
local Object = require 'lib.classic'

local Tile = Object:extend()

Tile.colors = {
	color.green,
	color.red,
	color.blue,
	color.yellow,
}
Tile.rotationAnimationDuration = 1/3

function Tile:new(x, y, tileColor)
	self.x = x
	self.y = y
	self.color = tileColor or love.math.random(#self.colors)
	self.state = 'idle'
	self.tweens = flux.group()
	self.rotationAnimation = {
		tween = nil,
		angle = nil,
		centerX = nil,
		centerY = nil,
	}
end

function Tile:update(dt)
	self.tweens:update(dt)
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
	animation.tween = self.tweens:to(animation, self.rotationAnimationDuration, {angle = endAngle})
		:ease 'backout'
		:oncomplete(function() self.state = 'idle' end)
	self.x = self.x + dx
	self.y = self.y + dy
end

function Tile:getDisplayPosition()
	if self.state == 'rotating' then
		local animation = self.rotationAnimation
		local distance = math.sqrt(.5)
		return animation.centerX + distance * math.cos(animation.angle) - .5,
			animation.centerY + distance * math.sin(animation.angle) - .5
	end
	return self.x, self.y
end

function Tile:draw()
	love.graphics.push 'all'
	love.graphics.setColor(self.colors[self.color])
	local x, y = self:getDisplayPosition()
	love.graphics.rectangle('fill', x, y, 1, 1)
	love.graphics.pop()
end

return Tile