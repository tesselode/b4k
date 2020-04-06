local charm = require 'lib.charm'

local Rotation = charm.extend('Rotation', 'element')

Rotation.clearMode._transform = 'none'

function Rotation:new(angle)
	self._angle = angle
	self._transform = self._transform or love.math.newTransform()
end

function Rotation:draw(...)
	if not self:hasChildren() then return end
	local x, y, width, height = self:get 'childrenRectangle'
	local originX = x + width * self._originX
	local originY = y + height * self._originY
	love.graphics.push 'all'
	love.graphics.translate(originX, originY)
	love.graphics.rotate(self._angle)
	love.graphics.translate(-originX, -originY)
	for _, child in ipairs(self._children) do
		child:draw(...)
	end
	love.graphics.pop()
end

return Rotation
