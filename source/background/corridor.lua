local color = require 'color'
local constant = require 'constant'
local Object = require 'lib.classic'
local util = require 'util'

local function transformPoint(x, y, z)
	return x / z, y / z
end

local function transformRectangle(x, y, z, w, h)
	local x1, y1, z1 = x, y - h/2, z - w/2
	local x2, y2, z2 = x, y - h/2, z + w/2
	local x3, y3, z3 = x, y + h/2, z + w/2
	local x4, y4, z4 = x, y + h/2, z - w/2

	local tx1, ty1 = transformPoint(x1, y1, z1)
	local tx2, ty2 = transformPoint(x2, y2, z2)
	local tx3, ty3 = transformPoint(x3, y3, z3)
	local tx4, ty4 = transformPoint(x4, y4, z4)
	return tx1, ty1, tx2, ty2, tx3, ty3, tx4, ty4
end

local Corridor = Object:extend()

Corridor.numRectangles = 100
Corridor.colors = {
	color.darkBlue,
	color.darkPurple,
	color.purple,
}
Corridor.width = 10000
Corridor.minY = -10000
Corridor.maxY = 10000
Corridor.minWidth = 1
Corridor.maxWidth = 5
Corridor.minHeight = 500
Corridor.maxHeight = 5000
Corridor.minZ = Corridor.maxWidth / 2
Corridor.maxZ = 100
Corridor.minSpeed = 1
Corridor.maxSpeed = 10
Corridor.speed = 1

function Corridor:new()
	self.rectangles = {}
	for _ = 1, self.numRectangles do
		table.insert(self.rectangles, {
			x = love.math.random() < .5 and -self.width or self.width,
			y = util.lerp(self.minY, self.maxY, love.math.random()),
			z = util.lerp(self.minZ, self.maxZ, love.math.random()),
			width = util.lerp(self.minWidth, self.maxWidth, love.math.random()),
			height = util.lerp(self.minHeight, self.maxHeight, love.math.random()),
			speed = util.lerp(self.minSpeed, self.maxSpeed, love.math.random()),
			color = self.colors[love.math.random(#self.colors)],
		})
	end
	self.angle = 0
end

function Corridor:update(dt)
	for _, rectangle in ipairs(self.rectangles) do
		rectangle.z = rectangle.z - rectangle.speed * dt
		if rectangle.z < self.minZ then
			rectangle.z = self.maxZ
			rectangle.x = love.math.random() < .5 and -self.width or self.width
			rectangle.y = util.lerp(self.minY, self.maxY, love.math.random())
			rectangle.width = util.lerp(self.minWidth, self.maxWidth, love.math.random())
			rectangle.height = util.lerp(self.minHeight, self.maxHeight, love.math.random())
			rectangle.speed = util.lerp(self.minSpeed, self.maxSpeed, love.math.random())
			rectangle.color = self.colors[love.math.random(#self.colors)]
		end
	end
	--self.angle = self.angle + .1 * dt
end

function Corridor:draw()
	love.graphics.push 'all'
	love.graphics.translate(constant.screenWidth/2, constant.screenHeight/2)
	love.graphics.rotate(self.angle)
	for _, r in ipairs(self.rectangles) do
		love.graphics.setColor(color.withAlpha(r.color, 1/4))
		love.graphics.polygon('fill', transformRectangle(r.x, r.y, r.z, r.width, r.height))
		love.graphics.setColor(r.color)
		love.graphics.polygon('line', transformRectangle(r.x, r.y, r.z, r.width, r.height))
	end
	love.graphics.pop()
end

return Corridor
