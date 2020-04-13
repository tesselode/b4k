local color = require 'color'
local image = require 'image'
local Object = require 'lib.classic'

local WildTileVisual = Object:extend()

WildTileVisual.colors = {
	color.red,
	color.green,
	color.lightBlue,
	color.lightOrange,
}

function WildTileVisual:new(pool)
	self.particleSystem = love.graphics.newParticleSystem(image.particle.circle)
	self.particleSystem:setEmissionRate(4)
	self.particleSystem:setParticleLifetime(1, 2)
	self.particleSystem:setSizes(0, 1 / image.particle.circle:getWidth(), .5 / image.particle.circle:getWidth(), 0)
	self.particleSystem:setSpread(2 * math.pi)
	self.particleSystem:setSpeed(.1, .2)
	self.particleSystem:setColors(
		self.colors[1][1], self.colors[1][2], self.colors[1][3], 1,
		self.colors[2][1], self.colors[2][2], self.colors[2][3], 1,
		self.colors[3][1], self.colors[3][2], self.colors[3][3], 1,
		self.colors[4][1], self.colors[4][2], self.colors[4][3], 1
	)
end

function WildTileVisual:update(dt)
	self.particleSystem:update(dt)
end

function WildTileVisual:draw()
	love.graphics.draw(self.particleSystem)
end

return WildTileVisual
