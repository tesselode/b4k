local color = require 'color'
local constant = require 'constant'
local log = require 'lib.log'
local Object = require 'lib.classic'
local Promise = require 'util.promise'
local Tile = require 'scene.game.entity.tile'
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

function Board:spawnTile(x, y, tileColor)
	table.insert(self.tiles, Tile(self.pool, x, y, tileColor))
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
		and topLeft.color ~= 'grey'
end

-- checks for new matching-color squares
function Board:checkSquares()
	local squares = {}
	local numSquares = 0
	local numNewSquares = 0
	for x = 0, constant.boardWidth - 2 do
		for y = 0, constant.boardHeight - 2 do
			local index = y * constant.boardWidth + x
			if self:squareAt(x, y) then
				squares[index] = true
				numSquares = numSquares + 1
				if not self.previousSquares[index] then
					numNewSquares = numNewSquares + 1
				end
			end
		end
	end
	self.pool:emit('onBoardCheckedSquares', self, squares, numSquares, numNewSquares)
	self.previousSquares = squares
	return squares, numSquares, numNewSquares
end

function Board:fillWithRandomTiles()
	for x = 0, constant.boardWidth - 1 do
		for y = 0, constant.boardHeight - 1 do
			self:spawnTile(x, y)
		end
	end
	-- change the colors of tiles so that there's no matching squares
	if #Tile.colors < 2 then return end
	local squares, numSquares = self:checkSquares()
	if numSquares < 1 then return end
	log.trace 'scrambling the board'
	local steps = 1
	while true do
		log.trace(('step %i: %i squares'):format(steps, numSquares))
		for square in pairs(squares) do
			local x, y = util.indexToCoordinates(constant.boardWidth, square)
			local tile = self:getTileAt(x, y)
			tile.color = tile.color + 1
			if tile.color > #tile.colors then tile.color = 1 end
		end
		squares, numSquares = self:checkSquares()
		if numSquares < 1 then
			break
		else
			steps = steps + 1
		end
		if steps > 20 then
			log.warn('exceeded 20 steps, giving up on scrambling the board')
			return
		end
	end
	log.trace(('scrambled the board in %i steps'):format(steps))
end

function Board:new(pool, options)
	self.pool = pool
	self.options = options or {}
	self.tiles = {}
	self.previousSquares = {}
	if self.options.fillWithRandomTiles ~= false then
		self:fillWithRandomTiles()
	end
	self:initTransform()
	self.mouseInBounds = false
	self.cursorX, self.cursorY = 0, 0
	self.freeToRotate = true
	self.stencil = util.bind(self.stencil, self)
end

function Board:add(e)
	if e ~= self then return end
	self:checkSquares()
end

function Board:updateTiles(dt)
	for _, tile in ipairs(self.tiles) do
		tile:update(dt)
	end
end

function Board:update(dt)
	self:updateTiles(dt)
end

function Board:getTileAt(x, y)
	for tileIndex, tile in ipairs(self.tiles) do
		if tile.x == x and tile.y == y then
			return tile, tileIndex
		end
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

-- rotates a 2x2 square of tiles with the top-left corner at (x, y)
function Board:rotate(x, y, counterClockwise)
	assert(x >= 0 and x <= constant.boardWidth - 2 and y >= 0 and y <= constant.boardHeight - 2,
		'trying to rotate tiles out of bounds')
	util.async(function(await)
		local promises = {}
		local topLeft = self:getTileAt(x, y)
		local topRight = self:getTileAt(x + 1, y)
		local bottomRight = self:getTileAt(x + 1, y + 1)
		local bottomLeft = self:getTileAt(x, y + 1)
		if topLeft then
			table.insert(promises, topLeft:rotate('topLeft', counterClockwise))
		end
		if topRight then
			table.insert(promises, topRight:rotate('topRight', counterClockwise))
		end
		if bottomRight then
			table.insert(promises, bottomRight:rotate('bottomRight', counterClockwise))
		end
		if bottomLeft then
			table.insert(promises, bottomLeft:rotate('bottomLeft', counterClockwise))
		end
		self.pool:emit('onBoardRotatingTiles', self, x, y, counterClockwise)
		local rotateTilesPromise = Promise.all(promises)
		if self:willTilesFall() then
			self.freeToRotate = false
			await(rotateTilesPromise)
			await(self:fallTiles())
			self.freeToRotate = true
		end
		local squares, numSquares, numNewSquares = self:checkSquares()
		if numSquares > 0 and numNewSquares < 1 then
			self.freeToRotate = false
			await(rotateTilesPromise)
			await(self:clearTiles(squares))
			self.freeToRotate = true
		end
	end)
end

function Board:fallTiles()
	local promises = {}
	for x = 0, constant.boardWidth - 1 do
		for y = constant.boardHeight - 1, 0, -1 do
			if self:getTileAt(x, y) then goto continue end
			for yy = -constant.boardHeight, y - 1 do
				local tile = self:getTileAt(x, yy)
				if tile then
					local promise = tile:fall()
					if promise then
						table.insert(promises, promise)
					end
				end
			end
			::continue::
		end
	end
	return Promise.all(promises)
end

-- marks tiles that are in matching-color squares as cleared
-- and plays the clear animation. also awards points for those squares
function Board:clearTiles(squares)
	return Promise(function(finish)
		util.async(function(await)
			local promises = {}
			local clearedTiles = {}
			local numClearedTiles = 0
			for i = 0, constant.boardWidth * constant.boardHeight - 1 do
				if not squares[i] then goto continue end
				local x, y = util.indexToCoordinates(constant.boardWidth, i)
				for tileX = x, x + 1 do
					for tileY = y, y + 1 do
						local tile = self:getTileAt(tileX, tileY)
						if tile and not clearedTiles[tile] then
							table.insert(promises, tile:clear())
							numClearedTiles = numClearedTiles + 1
							clearedTiles[tile] = true
						end
					end
				end
				::continue::
			end
			self.pool:emit('onBoardClearingTiles', self, clearedTiles, numClearedTiles)
			if numClearedTiles > 0 then
				await(Promise.all(promises))
				await(self:removeTiles())
			end
			finish()
		end)
	end)
end

-- actually removes tiles from the board once they've
-- finished their clear animation and spawns new ones
function Board:removeTiles()
	return Promise(function(finish)
		util.async(function(await)
			-- remove cleared tiles
			for i = #self.tiles, 1, -1 do
				local tile = self.tiles[i]
				if tile.cleared then
					table.remove(self.tiles, i)
				end
			end
			self.pool:emit('onBoardRemovedTiles', self)
			-- spawn new tiles to replace the removed ones
			if self.options.spawnNewTiles ~= false then
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
			await(self:fallTiles())
			self:checkSquares()
			finish()
		end)
	end)
end

function Board:canRotate()
	return self.freeToRotate and self.pool.data.gameInProgress
end

function Board:mousemoved(x, y, dx, dy, istouch)
	x, y = self.transform:inverseTransformPoint(x, y)
	self.mouseInBounds = not (x < 0 or x > constant.boardWidth or y < 0 or y > constant.boardHeight)
	self.cursorX, self.cursorY = math.floor(x), math.floor(y)
	self.cursorX = util.clamp(self.cursorX, 0, constant.boardWidth - 2)
	self.cursorY = util.clamp(self.cursorY, 0, constant.boardHeight - 2)
end

function Board:mousepressed(x, y, button, istouch, presses)
	if self.mouseInBounds and self:canRotate() then
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
	love.graphics.stencil(self.stencil, 'increment', 1, true)
	love.graphics.setStencilTest('greater', 0)
	for _, tile in ipairs(self.tiles) do
		tile:draw()
	end
	love.graphics.stencil(self.stencil, 'decrement', 1, true)
	love.graphics.pop()
end

function Board:drawCursor()
	if not self.mouseInBounds then return end
	love.graphics.push 'all'
	if not self:canRotate() then
		love.graphics.setColor(color.silver)
	end
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
