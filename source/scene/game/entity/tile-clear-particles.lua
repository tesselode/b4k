local color = require 'color'
local image = require 'image'
local Object = require 'lib.classic'

local TileClearParticles = Object:extend()

TileClearParticles.colors = {
	color.red,
	color.green,
	color.lightBlue,
	color.orange,
	inert = color.maroon,
}

function TileClearParticles:new(tile)
	self.particleSystem = love.graphics.newParticleSystem(image.particle.line)
	self.particleSystem:setPosition(tile.x + .5, tile.y + .5)
	self.particleSystem:setEmissionArea('borderrectangle', .5, .5, 0, true)
	self.particleSystem:setParticleLifetime(.5, 1.25)
	self.particleSystem:setRelativeRotation(true)
	self.particleSystem:setSpeed(10, 20)
	self.particleSystem:setTangentialAcceleration(-5, 5)
	self.particleSystem:setLinearDamping(3, 6)
	self.particleSystem:setSizes(.1, 0)
	self.particleSystem:setColors(color.withAlpha(self.colors[tile.color], 1))
	self.particleSystem:emit(8)
end

function TileClearParticles:update(dt)
	self.particleSystem:update(dt)
	if self.particleSystem:getCount() == 0 then
		self.removeFromPool = true
	end
end

function TileClearParticles:drawOnBoard()
	love.graphics.draw(self.particleSystem)
end

return TileClearParticles
