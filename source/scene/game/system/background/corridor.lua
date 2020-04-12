local color = require 'color'
local constant = require 'constant'
local util = require 'util'

local function transformPoint(x, y, z)
	if z <= 0 then z = .0001 end
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

local corridor = {}

corridor.numRectangles = 100
corridor.colors = {
	color.darkBlue,
	color.darkPurple,
	color.purple,
}
corridor.minX = 10000
corridor.maxX = 20000
corridor.minY = -10000
corridor.maxY = 10000
corridor.minWidth = 1
corridor.maxWidth = 5
corridor.minHeight = 500
corridor.maxHeight = 5000
corridor.minZ = .0001
corridor.maxZ = 100
corridor.minSpeed = 5
corridor.maxSpeed = 20

function corridor:init()
	self.rectangles = {}
	for _ = 1, self.numRectangles do
		table.insert(self.rectangles, {
			x = util.lerp(self.minX, self.maxX, love.math.random()) * (love.math.random() < .5 and -1 or 1),
			y = util.lerp(self.minY, self.maxY, love.math.random()),
			z = util.lerp(self.minZ, self.maxZ, love.math.random()),
			width = util.lerp(self.minWidth, self.maxWidth, love.math.random()),
			height = util.lerp(self.minHeight, self.maxHeight, love.math.random()),
			speed = util.lerp(self.minSpeed, self.maxSpeed, love.math.random()),
			color = self.colors[love.math.random(#self.colors)],
		})
	end
end

function corridor:update(dt)
	for _, rectangle in ipairs(self.rectangles) do
		rectangle.z = rectangle.z - rectangle.speed * dt
		if rectangle.z < self.minZ then
			rectangle.z = self.maxZ
			rectangle.x = util.lerp(self.minX, self.maxX, love.math.random()) * (love.math.random() < .5 and -1 or 1)
			rectangle.y = util.lerp(self.minY, self.maxY, love.math.random())
			rectangle.width = util.lerp(self.minWidth, self.maxWidth, love.math.random())
			rectangle.height = util.lerp(self.minHeight, self.maxHeight, love.math.random())
			rectangle.speed = util.lerp(self.minSpeed, self.maxSpeed, love.math.random())
			rectangle.color = self.colors[love.math.random(#self.colors)]
		end
	end
end

function corridor:draw()
	love.graphics.push 'all'
	love.graphics.translate(constant.screenWidth/2, constant.screenHeight/2)
	for _, r in ipairs(self.rectangles) do
		love.graphics.setColor(color.withAlpha(r.color, 1/4))
		love.graphics.polygon('fill', transformRectangle(r.x, r.y, r.z, r.width, r.height))
		love.graphics.setColor(r.color)
		love.graphics.polygon('line', transformRectangle(r.x, r.y, r.z, r.width, r.height))
	end
	love.graphics.pop()
end

return corridor
