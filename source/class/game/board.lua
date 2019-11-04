local constant = require 'constant'
local Object = require 'lib.classic'
local Tile = require 'class.game.tile'
local util = require 'util'

local Board = Object:extend()

Board.size = 8
Board.sizeOnScreen = .6
Board.cursorLineWidth = .1

function Board:initTransform()
	self.transform = love.math.newTransform()
	self.transform:translate(constant.screenWidth / 2, constant.screenHeight / 2)
	self.transform:rotate(math.pi / 4)
	self.transform:scale(constant.screenHeight * self.sizeOnScreen / self.size)
	self.transform:translate(-self.size / 2, -self.size / 2)
end

function Board:initTiles()
	self.tiles = {}
	for x = 0, self.size - 1 do
		for y = 0, self.size - 1 do
			table.insert(self.tiles, self.pool:queue(Tile(x, y)))
		end
	end
end

function Board:new(pool)
	self.pool = pool
	self:initTiles()
	self:initTransform()
	self.showCursor = false
	self.cursorX, self.cursorY = 0, 0
end

function Board:getTileAt(x, y)
	for _, tile in ipairs(self.tiles) do
		if tile.x == x and tile.y == y then
			return tile
		end
	end
end

function Board:rotate(x, y, counterClockwise)
	assert(x >= 0 and x <= self.size - 2 and y >= 0 and y <= self.size - 2,
		'trying to rotate tiles out of bounds')
	local topLeft = self:getTileAt(x, y)
	local topRight = self:getTileAt(x + 1, y)
	local bottomRight = self:getTileAt(x + 1, y + 1)
	local bottomLeft = self:getTileAt(x, y + 1)
	if topLeft then topLeft:rotate('topLeft', counterClockwise) end
	if topRight then topRight:rotate('topRight', counterClockwise) end
	if bottomRight then bottomRight:rotate('bottomRight', counterClockwise) end
	if bottomLeft then bottomLeft:rotate('bottomLeft', counterClockwise) end
end

function Board:mousemoved(x, y, dx, dy, istouch)
	x, y = self.transform:inverseTransformPoint(x, y)
	self.showCursor = not (x < 0 or x > self.size or y < 0 or y > self.size)
	self.cursorX, self.cursorY = math.floor(x), math.floor(y)
	self.cursorX = util.clamp(self.cursorX, 0, self.size - 2)
	self.cursorY = util.clamp(self.cursorY, 0, self.size - 2)
end

function Board:mousepressed(x, y, button, istouch, presses)
	if button == 1 then
		self:rotate(self.cursorX, self.cursorY, true)
	elseif button == 2 then
		self:rotate(self.cursorX, self.cursorY)
	end
end

function Board:drawTiles()
	for _, tile in ipairs(self.tiles) do
		tile:_draw()
	end
end

function Board:drawCursor()
	if not self.showCursor then return end
	love.graphics.push 'all'
	love.graphics.setLineWidth(self.cursorLineWidth)
	love.graphics.rectangle('line', self.cursorX, self.cursorY, 2, 2)
	love.graphics.pop()
end

function Board:draw()
	love.graphics.push 'all'
	love.graphics.applyTransform(self.transform)
	self:drawTiles()
	self:drawCursor()
	love.graphics.pop()
end

return Board
