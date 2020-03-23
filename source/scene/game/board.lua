local color = require 'color'
local Grid = require 'grid'
local Object = require 'lib.classic'
local Tile = require 'scene.game.tile'
local util = require 'util'

local Board = Object:extend()

Board.width = 8
Board.height = 8
Board.baseScale = 2/3

function Board:initTiles()
	self.tiles = {}
	for x = 0, self.width - 1 do
		for y = 0, self.height - 1 do
			table.insert(self.tiles, Tile(x, y))
		end
	end
	self.previousSquares = Grid(self.width, self.height)
	self.squares = Grid(self.width, self.height)
end

function Board:initTransform()
	local scale = math.min(love.graphics.getWidth() / self.width,
		love.graphics.getHeight() / self.height) * self.baseScale
	self.transform = love.math.newTransform(
		love.graphics.getWidth() / 2, love.graphics.getHeight() / 2,
		0,
		scale, scale,
		self.width / 2, self.height / 2
	)
end

function Board:initCursor()
	self.cursorX, self.cursorY = 0, 0
	self.mouseInBounds = false
end

function Board:new()
	self:initTiles()
	self:initTransform()
	self:initCursor()
end

function Board:getTileAt(x, y)
	for _, tile in ipairs(self.tiles) do
		if tile.x == x and tile.y == y then
			return tile
		end
	end
end

function Board:getSquareAt(x, y)
	local topLeft = self:getTileAt(x, y)
	local topRight = self:getTileAt(x + 1, y)
	local bottomRight = self:getTileAt(x + 1, y + 1)
	local bottomLeft = self:getTileAt(x, y + 1)
	if not (topLeft and topRight and bottomRight and bottomLeft) then
		return
	end
	local sameColor = topLeft.color == topRight.color
		and topRight.color == bottomRight.color
		and bottomRight.color == bottomLeft.color
	if sameColor then
		return {
			color = topLeft.color,
		}
	end
end

function Board:checkSquares()
	self.previousSquares = self.squares
	self.squares = Grid(self.width, self.height)
	for x = 0, self.width - 2 do
		for y = 0, self.height - 2 do
			local square = self:getSquareAt(x, y)
			if square then
				self.squares:set(x, y, square)
			end
		end
	end
end

function Board:rotate(x, y, counterClockwise)
	local topLeft = self:getTileAt(x, y)
	local topRight = self:getTileAt(x + 1, y)
	local bottomRight = self:getTileAt(x + 1, y + 1)
	local bottomLeft = self:getTileAt(x, y + 1)
	if topLeft then topLeft:rotate(x + 1, y + 1, 'topLeft', counterClockwise) end
	if topRight then topRight:rotate(x + 1, y + 1, 'topRight', counterClockwise) end
	if bottomRight then bottomRight:rotate(x + 1, y + 1, 'bottomRight', counterClockwise) end
	if bottomLeft then bottomLeft:rotate(x + 1, y + 1, 'bottomLeft', counterClockwise) end
	self:checkSquares()
end

function Board:update(dt)
	for _, tile in ipairs(self.tiles) do
		tile:update(dt)
	end
end

function Board:mousemoved(x, y, dx, dy, isTouch)
	self.cursorX, self.cursorY = self.transform:inverseTransformPoint(x, y)
	self.mouseInBounds = self.cursorX >= 0 and self.cursorX < self.width
		and self.cursorY >= 0 and self.cursorY < self.width
	self.cursorX, self.cursorY = math.floor(self.cursorX), math.floor(self.cursorY)
	self.cursorX = util.clamp(self.cursorX, 0, self.width - 2)
	self.cursorY = util.clamp(self.cursorY, 0, self.height - 2)
end

function Board:mousepressed(x, y, button, isTouch, presses)
	if not self.mouseInBounds then return end
	if button == 1 then self:rotate(self.cursorX, self.cursorY, true) end
	if button == 2 then self:rotate(self.cursorX, self.cursorY) end
end

function Board:drawTiles()
	for _, tile in ipairs(self.tiles) do
		tile:draw()
	end
end

function Board:drawSquareHighlights()
	love.graphics.push 'all'
	love.graphics.setColor(color.white)
	love.graphics.setLineWidth(1/8)
	for _, x, y in self.squares:items() do
		love.graphics.rectangle('line', x, y, 2, 2)
	end
	love.graphics.pop()
end

function Board:drawCursor()
	if not self.mouseInBounds then return end
	love.graphics.push 'all'
	love.graphics.setColor(color.white)
	love.graphics.setLineWidth(1/8)
	love.graphics.rectangle('line', self.cursorX, self.cursorY, 2, 2)
	love.graphics.pop()
end

function Board:draw()
	love.graphics.push 'all'
	love.graphics.applyTransform(self.transform)
	self:drawTiles()
	self:drawSquareHighlights()
	self:drawCursor()
	love.graphics.pop()
end

return Board
