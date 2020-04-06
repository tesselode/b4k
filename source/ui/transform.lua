local charm = require 'lib.charm'

local Transform = charm.extend('Transform', 'element')

Transform.clearMode._transform = 'none'

function Transform:new()
	self._originX = 0
	self._originY = 0
	self._scaleX = 1
	self._scaleY = 1
	self._angle = 0
	self._transform = self._transform or love.math.newTransform()
end

function Transform:scale(scaleX, scaleY)
	self._scaleX = scaleX
	self._scaleY = scaleY or scaleX
end

function Transform:angle(angle)
	self._angle = angle
end

function Transform:draw(...)
	if not self:hasChildren() then return end
	local x, y, width, height = self:get 'childrenRectangle'
	local originX = x + width * self._originX
	local originY = y + height * self._originY
	love.graphics.push 'all'
	love.graphics.translate(originX, originY)
	love.graphics.scale(self._scaleX, self._scaleY)
	love.graphics.rotate(self._angle)
	love.graphics.translate(-originX, -originY)
	for _, child in ipairs(self._children) do
		child:draw(...)
	end
	love.graphics.pop()
end

return Transform
