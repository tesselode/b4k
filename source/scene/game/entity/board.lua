local constant = require 'constant'
local Object = require 'lib.classic'
local SquareHighlight = require 'scene.game.entity.square-highlight'
local Tile = require 'scene.game.entity.tile'
local TileClearParticles = require 'scene.game.entity.tile-clear-particles'
local util = require 'util'

local Board = Object:extend()

Board.width = 8
Board.height = 8
Board.sizeOnScreen = .6
Board.cursorLineWidth = .1

--[[
	initializes the transform used for drawing and converting
	mouse coordinates to board coordinates. in the board
	coordinate system, each tile is 1 unit square
]]
function Board:initTransform()
	self.scale = constant.screenHeight * self.sizeOnScreen / self.height
	self.transform = love.math.newTransform()
	self.transform:translate(constant.screenWidth / 2, constant.screenHeight / 2)
	self.transform:scale(self.scale)
	self.transform:translate(-self.width / 2, -self.height / 2)
end

function Board:spawnTile(x, y)
	table.insert(self.tiles, Tile(self.pool, x, y))
end

function Board:initTiles()
	self.tiles = {}
	for x = 0, self.width - 1 do
		for y = 0, self.height - 1 do
			self:spawnTile(x, y)
		end
	end
end

function Board:initSquareHighlights()
	self.squareHighlights = {}
	for x = 0, self.width - 2 do
		self.squareHighlights[x] = {}
		for y = 0, self.height - 2 do
			self.squareHighlights[x][y] = SquareHighlight(self.pool, x, y)
		end
	end
end

function Board:new(pool)
	self.pool = pool
	self:initTiles()
	self:initSquareHighlights()
	self:initTransform()
	self.wasFree = true
	self.squares = {}
	self.totalSquares = 0
	self.queue = {}
	self.mouseInBounds = false
	self.cursorX, self.cursorY = 0, 0
	self:checkSquares()
	self.stencil = util.bind(self.stencil, self)
end

-- returns if the board is free to do the next queued action
-- (or to rotate tiles, which has slightly different conditions)
function Board:isFree(toRotate)
	for _, tile in ipairs(self.tiles) do
		if not tile:isFree(toRotate) then return false end
	end
	if toRotate and #self.queue > 0 then return false end
	return true
end

function Board:flushQueue()
	while self:isFree() and #self.queue > 0 do
		self.queue[1](self)
		table.remove(self.queue, 1)
	end
end

function Board:updateTiles(dt)
	for _, tile in ipairs(self.tiles) do
		tile:update(dt)
	end
end

function Board:checkIfNewlyFree()
	if self:isFree() and not self.wasFree then
		self.pool:emit('onBoardBecameFree', self)
	end
	self.wasFree = self:isFree()
end

function Board:update(dt)
	self:updateTiles(dt)
	self:flushQueue()
	self:checkIfNewlyFree()
end

function Board:getTileAt(x, y)
	for tileIndex, tile in ipairs(self.tiles) do
		if tile.x == x and tile.y == y then
			return tile, tileIndex
		end
	end
end

-- returns if there's a 2x2 square of same-colored tiles
-- with the top-left corner at (x, y)
function Board:squareAt(x, y)
	assert(x >= 0 and x <= self.width - 2 and y >= 0 and y <= self.height - 2,
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

-- checks for new matching-color squares
function Board:checkSquares()
	local previousSquares = self.squares
	self.squares = {}
	self.totalSquares = 0
	local newSquares = 0
	for x = 0, self.width - 2 do
		for y = 0, self.height - 2 do
			local index = y * self.width + x
			if self:squareAt(x, y) then
				self.squares[index] = true
				self.totalSquares = self.totalSquares + 1
				if not previousSquares[index] then
					newSquares = newSquares + 1
				end
				self.squareHighlights[x][y]:activate()
			else
				self.squareHighlights[x][y]:deactivate()
			end
		end
	end
	self.pool:emit('onBoardCheckedSquares', self, self.squares, self.totalSquares, newSquares)
	return newSquares
end

-- rotates a 2x2 square of tiles with the top-left corner at (x, y)
function Board:rotate(x, y, counterClockwise)
	assert(x >= 0 and x <= self.width - 2 and y >= 0 and y <= self.height - 2,
		'trying to rotate tiles out of bounds')
	local topLeft = self:getTileAt(x, y)
	local topRight = self:getTileAt(x + 1, y)
	local bottomRight = self:getTileAt(x + 1, y + 1)
	local bottomLeft = self:getTileAt(x, y + 1)
	if topLeft then topLeft:rotate('topLeft', counterClockwise) end
	if topRight then topRight:rotate('topRight', counterClockwise) end
	if bottomRight then bottomRight:rotate('bottomRight', counterClockwise) end
	if bottomLeft then bottomLeft:rotate('bottomLeft', counterClockwise) end
	self.pool:emit('onBoardRotatingTiles', self, x, y, counterClockwise)
	local numNewSquares = self:checkSquares()
	if self.totalSquares > 0 then
		if numNewSquares == 0 then
			table.insert(self.queue, self.clearTiles)
		end
	end
end

-- marks tiles that are in matching-color squares as cleared
-- and plays the clear animation. also awards points for those squares
function Board:clearTiles()
	local clearedTiles = {}
	local numClearedTiles = 0
	for i = 0, self.width * self.height - 1 do
		if self.squares[i] then
			local x, y = util.indexToCoordinates(self.width, i)
			for tileX = x, x + 1 do
				for tileY = y, y + 1 do
					local tile = self:getTileAt(tileX, tileY)
					if tile and not clearedTiles[tile] then
						tile:clear()
						numClearedTiles = numClearedTiles + 1
						clearedTiles[tile] = true
					end
				end
			end
		end
	end

	self.pool:emit('onBoardClearingTiles', self, clearedTiles, numClearedTiles)

	-- emit particles
	for tile in pairs(clearedTiles) do
		self.pool:queue(TileClearParticles(tile))
	end

	util.clear(self.squares)

	-- queue up a tile removal pass if needed
	if numClearedTiles > 0 then
		table.insert(self.queue, self.removeTiles)
	end

	-- deactivate all square highlights
	for x = 0, self.width - 2 do
		for y = 0, self.height - 2 do
			self.squareHighlights[x][y]:burst()
		end
	end
end

-- actually removes tiles from the board once they've
-- finished their clear animation and spawns new ones
function Board:removeTiles()
	-- remove cleared tiles
	for i = #self.tiles, 1, -1 do
		local tile = self.tiles[i]
		if tile.cleared then
			table.remove(self.tiles, i)
		end
	end
	self.pool:emit('onBoardRemovedTiles', self)
	-- tell tiles above holes to fall and spawn new tiles
	for x = 0, self.width - 1 do
		-- spawn new tiles
		local holesInColumn = 0
		for y = self.height - 1, 0, -1 do
			if not self:getTileAt(x, y) then
				holesInColumn = holesInColumn + 1
				self:spawnTile(x, -holesInColumn)
			end
		end
		-- make tiles fall
		for y = self.height - 1, 0, -1 do
			if not self:getTileAt(x, y) then
				for yy = -self.height, y - 1 do
					local tile = self:getTileAt(x, yy)
					if tile then tile:fall() end
				end
			end
		end
	end
	table.insert(self.queue, self.checkSquares)
end

function Board:mousemoved(x, y, dx, dy, istouch)
	x, y = self.transform:inverseTransformPoint(x, y)
	self.mouseInBounds = not (x < 0 or x > self.width or y < 0 or y > self.height)
	self.cursorX, self.cursorY = math.floor(x), math.floor(y)
	self.cursorX = util.clamp(self.cursorX, 0, self.width - 2)
	self.cursorY = util.clamp(self.cursorY, 0, self.height - 2)
end

function Board:mousepressed(x, y, button, istouch, presses)
	if self.mouseInBounds and self:isFree(true) then
		if button == 1 then
			self:rotate(self.cursorX, self.cursorY, true)
		elseif button == 2 then
			self:rotate(self.cursorX, self.cursorY)
		end
	end
end

function Board:stencil()
	love.graphics.rectangle('fill', 0, 0, self.width, self.height)
end

function Board:drawTiles()
	love.graphics.push 'all'
	love.graphics.stencil(self.stencil)
	love.graphics.setStencilTest('greater', 0)
	for _, tile in ipairs(self.tiles) do
		tile:draw()
	end
	love.graphics.pop()
end

function Board:drawCursor()
	if not self.mouseInBounds then return end
	love.graphics.push 'all'
	love.graphics.setLineWidth(self.cursorLineWidth)
	love.graphics.rectangle('line', self.cursorX, self.cursorY, 2, 2)
	love.graphics.pop()
end

function Board:drawSquareHighlights()
	for x = 0, self.width - 2 do
		for y = 0, self.height - 2 do
			self.squareHighlights[x][y]:draw()
		end
	end
end

function Board:draw()
	love.graphics.push 'all'
	love.graphics.applyTransform(self.transform)
	self:drawTiles()
	self:drawSquareHighlights()
	self.pool:emit 'drawOnBoard'
	self:drawCursor()
	love.graphics.pop()
end

return Board
