local constant = require 'constant'
local log = require 'lib.log'
local Object = require 'lib.classic'
local Tile = require 'scene.game.entity.tile'
local TileClearParticles = require 'scene.game.entity.tile-clear-particles'
local util = require 'util'

local Board = Object:extend()

Board.sizeOnScreen = .6
Board.cursorLineWidth = .1

--[[
	initializes the transform used for drawing and converting
	mouse coordinates to board coordinates. in the board
	coordinate system, each tile is 1 unit square
]]
function Board:initTransform()
	self.scale = constant.screenHeight * self.sizeOnScreen / constant.boardHeight
	self.transform = love.math.newTransform()
	self.transform:translate(constant.screenWidth / 2, constant.screenHeight / 2)
	self.transform:scale(self.scale)
	self.transform:translate(-constant.boardWidth / 2, -constant.boardHeight / 2)
end

function Board:spawnTile(x, y, color)
	table.insert(self.tiles, Tile(self.pool, x, y, color))
end

function Board:initTiles()
	self.tiles = {}
	if not self.puzzleMode then
		for x = 0, constant.boardWidth - 1 do
			for y = 0, constant.boardHeight - 1 do
				self:spawnTile(x, y)
			end
		end
		self:scramble()
	end
	self:checkSquares()
end

function Board:new(pool, puzzleMode)
	self.pool = pool
	self.puzzleMode = puzzleMode
	self:initTransform()
	self.squares = {}
	self.totalSquares = 0
	self:initTiles()
	self.wasFree = true
	self.queue = {}
	self.mouseInBounds = false
	self.cursorX, self.cursorY = 0, 0
	self.stencil = util.bind(self.stencil, self)
end

function Board:add(e)
	if e ~= self then return end
	self:checkSquares()
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
	assert(x >= 0 and x <= constant.boardWidth - 2 and y >= 0 and y <= constant.boardHeight - 2,
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
function Board:checkSquares(emitEvent)
	local previousSquares = self.squares
	self.squares = {}
	self.totalSquares = 0
	local newSquares = 0
	for x = 0, constant.boardWidth - 2 do
		for y = 0, constant.boardHeight - 2 do
			local index = y * constant.boardWidth + x
			if self:squareAt(x, y) then
				self.squares[index] = true
				self.totalSquares = self.totalSquares + 1
				if not previousSquares[index] then
					newSquares = newSquares + 1
				end
			end
		end
	end
	if emitEvent ~= false then
		self.pool:emit('onBoardCheckedSquares', self, self.squares, self.totalSquares, newSquares)
	end
	return newSquares
end

-- checks for squares and clears them if there aren't any new ones
function Board:checkAndClearSquares()
	local numNewSquares = self:checkSquares()
	if self.totalSquares > 0 then
		if numNewSquares == 0 then
			table.insert(self.queue, self.clearTiles)
		end
	end
end

-- changes the colors of tiles so that there's no matching squares
function Board:scramble()
	if #Tile.colors < 2 then return end
	self:checkSquares(false)
	if self.totalSquares < 1 then return end
	log.trace 'scrambling the board'
	local steps = 1
	while true do
		log.trace(('step %i: %i squares'):format(steps, self.totalSquares))
		for square in pairs(self.squares) do
			local x, y = util.indexToCoordinates(constant.boardWidth, square)
			local tile = self:getTileAt(x, y)
			tile.color = tile.color + 1
			if tile.color > #tile.colors then tile.color = 1 end
		end
		self:checkSquares(false)
		if self.totalSquares < 1 then
			break
		else
			steps = steps + 1
		end
	end
	log.trace(('scrambled the board in %i steps'):format(steps))
end

-- rotates a 2x2 square of tiles with the top-left corner at (x, y)
function Board:rotate(x, y, counterClockwise)
	assert(x >= 0 and x <= constant.boardWidth - 2 and y >= 0 and y <= constant.boardHeight - 2,
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
	if self:willTilesFall() then
		table.insert(self.queue, self.fallTiles)
		table.insert(self.queue, self.checkAndClearSquares)
	else
		self:checkAndClearSquares()
	end
end

function Board:willTilesFall()
	for x = 0, constant.boardWidth - 1 do
		for y = constant.boardHeight - 1, 0, -1 do
			if not self:getTileAt(x, y) then
				for yy = -constant.boardHeight, y - 1 do
					local tile = self:getTileAt(x, yy)
					if tile then return true end
				end
			end
		end
	end
	return false
end

function Board:fallTiles()
	for x = 0, constant.boardWidth - 1 do
		for y = constant.boardHeight - 1, 0, -1 do
			if not self:getTileAt(x, y) then
				for yy = -constant.boardHeight, y - 1 do
					local tile = self:getTileAt(x, yy)
					if tile then tile:fall() end
				end
			end
		end
	end
end

-- marks tiles that are in matching-color squares as cleared
-- and plays the clear animation. also awards points for those squares
function Board:clearTiles()
	local clearedTiles = {}
	local numClearedTiles = 0
	for i = 0, constant.boardWidth * constant.boardHeight - 1 do
		if self.squares[i] then
			local x, y = util.indexToCoordinates(constant.boardWidth, i)
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
	-- spawn new tiles to replace the removed ones
	if not self.puzzleMode then
		for x = 0, constant.boardWidth - 1 do
			local holesInColumn = 0
			for y = constant.boardHeight - 1, 0, -1 do
				if not self:getTileAt(x, y) then
					holesInColumn = holesInColumn + 1
					self:spawnTile(x, -holesInColumn)
				end
			end
		end
	end
	self:fallTiles()
	table.insert(self.queue, self.checkSquares)
end

function Board:mousemoved(x, y, dx, dy, istouch)
	x, y = self.transform:inverseTransformPoint(x, y)
	self.mouseInBounds = not (x < 0 or x > constant.boardWidth or y < 0 or y > constant.boardHeight)
	self.cursorX, self.cursorY = math.floor(x), math.floor(y)
	self.cursorX = util.clamp(self.cursorX, 0, constant.boardWidth - 2)
	self.cursorY = util.clamp(self.cursorY, 0, constant.boardHeight - 2)
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
	love.graphics.rectangle('fill', 0, 0, constant.boardWidth, constant.boardHeight)
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

function Board:draw()
	love.graphics.push 'all'
	love.graphics.applyTransform(self.transform)
	self:drawTiles()
	self.pool:emit 'drawOnBoard'
	self:drawCursor()
	love.graphics.pop()
end

return Board