local constant = require 'constant'
local keeper = require 'lib.keeper'
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
			table.insert(self.tiles, self.pool:queue(Tile(self, x, y)))
		end
	end
end

function Board:new(pool)
	self.timers = keeper.new()
	self.pool = pool
	self:initTiles()
	self:initTransform()
	self.previousSquares = {}
	self.squares = {}
	self.clearedTiles = {}
	self.queue = {}
	self.showCursor = false
	self.cursorX, self.cursorY = 0, 0
	self:detectSquares()
end

function Board:isFree(toRotate)
	for _, tile in ipairs(self.tiles) do
		if not tile:isFree(toRotate) then return false end
	end
	if toRotate and #self.queue > 0 then return false end
	return true
end

function Board:update(dt)
	self.timers:update(dt)
	while self:isFree() and #self.queue > 0 do
		self.queue[1](self)
		table.remove(self.queue, 1)
	end
end

function Board:getTileAt(x, y)
	for _, tile in ipairs(self.tiles) do
		if tile.x == x and tile.y == y then
			return tile
		end
	end
end

function Board:squareAt(x, y)
	assert(x >= 0 and x <= self.size - 2 and y >= 0 and y <= self.size - 2,
		'trying to detect squares out of bounds')
	local topLeft = self:getTileAt(x, y)
	local topRight = self:getTileAt(x + 1, y)
	local bottomRight = self:getTileAt(x + 1, y + 1)
	local bottomLeft = self:getTileAt(x, y + 1)
	if not (topLeft and topRight and bottomRight and bottomLeft) then
		return false
	end
	return topLeft.color == topRight.color
		and topRight.color == bottomRight.color
		and bottomRight.color == bottomLeft.color
end

function Board:detectSquares()
	util.clear(self.previousSquares)
	util.copy(self.squares, self.previousSquares)
	util.clear(self.squares)
	local totalSquares = 0
	local newSquares = 0
	for x = 0, self.size - 2 do
		for y = 0, self.size - 2 do
			local index = y * self.size + x
			if self:squareAt(x, y) then
				self.squares[index] = true
				totalSquares = totalSquares + 1
				if not self.previousSquares[index] then
					newSquares = newSquares + 1
				end
			end
		end
	end
	return totalSquares, newSquares
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
	local totalSquares, numNewSquares = self:detectSquares()
	if totalSquares > 0 and numNewSquares == 0 then
		table.insert(self.queue, self.clearTiles)
	end
end

function Board:clearTiles()
	local numClearedTiles = 0
	for i = 0, self.size ^ 2 - 1 do
		if self.squares[i] then
			local x, y = util.indexToCoordinates(self.size, i)
			for tileX = x, x + 1 do
				for tileY = y, y + 1 do
					local tile = self:getTileAt(tileX, tileY)
					if tile and not self.clearedTiles[tile] then
						tile:clear()
						numClearedTiles = numClearedTiles + 1
						self.clearedTiles[tile] = true
					end
				end
			end
		end
	end
	util.clear(self.clearedTiles)
	util.clear(self.squares)
	if numClearedTiles > 0 then
		table.insert(self.queue, self.removeTiles)
	end
end

function Board:removeTiles()
	for i = #self.tiles, 1, -1 do
		local tile = self.tiles[i]
		if tile.cleared then
			table.remove(self.tiles, i)
		end
	end
end

function Board:mousemoved(x, y, dx, dy, istouch)
	x, y = self.transform:inverseTransformPoint(x, y)
	self.showCursor = not (x < 0 or x > self.size or y < 0 or y > self.size)
	self.cursorX, self.cursorY = math.floor(x), math.floor(y)
	self.cursorX = util.clamp(self.cursorX, 0, self.size - 2)
	self.cursorY = util.clamp(self.cursorY, 0, self.size - 2)
end

function Board:mousepressed(x, y, button, istouch, presses)
	if self:isFree(true) then
		if button == 1 then
			self:rotate(self.cursorX, self.cursorY, true)
		elseif button == 2 then
			self:rotate(self.cursorX, self.cursorY)
		end
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

function Board:drawSquareHighlights()
	love.graphics.push 'all'
	love.graphics.setColor(.1, .1, .5)
	love.graphics.setLineWidth(.05)
	for i = 0, self.size ^ 2 - 1 do
		if self.squares[i] then
			local x, y = util.indexToCoordinates(self.size, i)
			love.graphics.rectangle('line', x, y, 2, 2)
		end
	end
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
