local color = require 'color'
local constant = require 'constant'
local Grid = require 'grid'
local log = require 'lib.log'
local Object = require 'lib.classic'
local SquareHighlight = require 'scene.game.entity.board.square-highlight'
local Tile = require 'scene.game.entity.board.tile'
local util = require 'util'

local Board = Object:extend()

Board.width = 8
Board.height = 8
Board.baseScale = 2/3

function Board:spawnTile(x, y, tileColor)
	table.insert(self.tiles, Tile(self.pool, x, y, tileColor))
end

-- creates the data structures for tiles and squares
-- and fills the board with random tiles
function Board:initTiles()
	self.tiles = {}
	self.squares = Grid(self.width, self.height)
end

function Board:initSquareHighlights()
	self.squareHighlights = Grid(self.width - 1, self.height - 1)
	for x = 0, self.width - 2 do
		for y = 0, self.height - 2 do
			self.squareHighlights:set(x, y, SquareHighlight(self.pool, x, y))
		end
	end
end

-- inits the transform object used for drawing and
-- converting mouse coordinates from screen space to grid space
function Board:initTransform()
	local scale = math.min(constant.screenWidth / self.width,
		constant.screenHeight / self.height) * self.baseScale
	self.transform = love.math.newTransform(
		constant.screenWidth / 2, constant.screenHeight / 2,
		0,
		scale, scale,
		self.width / 2, self.height / 2
	)
end

function Board:initCursor()
	self.cursorX, self.cursorY = 0, 0
	self.mouseInBounds = false
end

function Board:new(pool, options)
	self.pool = pool
	self.options = options or {}
	self:initTiles()
	self:initSquareHighlights()
	self:initTransform()
	self:initCursor()
	self.queue = {}
	self.stencil = util.bind(self.stencil, self)
	self:checkSquares()
	self.acceptInput = true
end

-- Changes the colors of tiles until there are no matching squares
function Board:scramble()
	-- if there's only one color (probably would only happen for testing purposes),
	-- then it'll be impossible to prevent matching squares, so we'll just stop now
	if #Tile.colors < 2 then return end
	self:checkSquares(true)
	if self.squares:count() < 1 then return end
	log.trace 'scrambling the board'
	local steps = 0
	while self.squares:count() > 0 do
		steps = steps + 1
		if steps > 20 then
			log.warn('exceeded 20 steps, giving up on scrambling the board')
			return
		end
		log.trace(('step %i: %i squares'):format(steps, self.squares:count()))
		for _, x, y in self.squares:items() do
			local tile = self:getTileAt(x, y)
			tile.color = tile.color + 1
			if tile.color > #tile.colors then tile.color = 1 end
		end
		self:checkSquares(true)
	end
	log.trace(('scrambled the board in %i steps'):format(steps))
end

function Board:fillWithRandomTiles()
	for x = 0, constant.boardWidth - 1 do
		for y = 0, constant.boardHeight - 1 do
			self:spawnTile(x, y)
		end
	end
	self:scramble()
end

-- returns true if there are no blocking animations playing
-- (like tiles falling, rotating, etc.)
function Board:isIdle()
	for _, tile in ipairs(self.tiles) do
		if not tile:isIdle() then return false end
	end
	return true
end

function Board:getTileAt(x, y)
	for _, tile in ipairs(self.tiles) do
		if tile.x == x and tile.y == y then
			return tile
		end
	end
end

-- returns info about a matching color square with the top-left
-- at (x, y), or nil if there's no square there
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

-- checks for matching color squares anywhere on the board
function Board:checkSquares(silent)
	local previousSquares = self.squares
	self.squares = Grid(self.width, self.height)
	local numNewSquares = 0
	for x = 0, self.width - 2 do
		for y = 0, self.height - 2 do
			local square = self:getSquareAt(x, y)
			if square then
				self.squares:set(x, y, square)
				if not previousSquares:get(x, y) then
					numNewSquares = numNewSquares + 1
				end
			end
			if not silent then
				self.squareHighlights:get(x, y):setActive(square and true or false)
			end
		end
	end
	self.pool:emit('onCheckSquares', self.squares, numNewSquares)
	return numNewSquares
end

-- checks for matching color squares. if there aren't any new
-- ones compared to the last check, clears the tiles in the
-- current squares
function Board:checkNewSquares()
	local numNewSquares = self:checkSquares()
	if self.squares:count() > 0 and numNewSquares < 1 then
		table.insert(self.queue, self.clearTiles)
	end
end

function Board:willTilesFall()
	for x = 0, self.width - 1 do
		for y = -self.height, self.height - 1 do
			if not self:getTileAt(x, y) then
				for yy = y - 1, -self.height, -1 do
					local tile = self:getTileAt(x, yy)
					if tile then return true end
				end
			end
		end
	end
	return false
end

function Board:fallTiles()
	for x = 0, self.width - 1 do
		for y = -self.height, self.height - 1 do
			if not self:getTileAt(x, y) then
				for yy = y - 1, -self.height, -1 do
					local tile = self:getTileAt(x, yy)
					if tile then tile:fall() end
				end
			end
		end
	end
end

-- plays the clear animation on any tiles that are in a
-- matching color square
function Board:clearTiles()
	local tiles = {}
	local numTiles = 0
	for _, x, y in self.squares:items() do
		tiles[self:getTileAt(x, y)] = true
		tiles[self:getTileAt(x + 1, y)] = true
		tiles[self:getTileAt(x + 1, y + 1)] = true
		tiles[self:getTileAt(x, y + 1)] = true
	end
	for tile in pairs(tiles) do
		numTiles = numTiles + 1
		tile:clear()
	end
	for _, _, _, squareHighlight in self.squareHighlights:items() do
		squareHighlight:onClearTiles()
	end
	self.pool:emit('onClearTiles', self.squares, tiles, numTiles)
	table.insert(self.queue, self.removeTiles)
end

-- spawns new tiles to fill the holes left by previously
-- removed tiles
function Board:replenishTiles()
	for x = 0, self.width - 1 do
		local holes = 0
		for y = 0, self.height - 1 do
			if not self:getTileAt(x, y) then
				holes = holes + 1
			end
		end
		for i = 1, holes do
			self:spawnTile(x, -i)
		end
	end
end

-- removes cleared tiles from the tiles list
function Board:removeTiles()
	for i = #self.tiles, 1, -1 do
		local tile = self.tiles[i]
		if tile.state == 'cleared' then
			table.remove(self.tiles, i)
		end
	end
	if self.options.replenishTiles ~= false then
		self:replenishTiles()
	end
	self:fallTiles()
	table.insert(self.queue, self.checkSquares)
end

-- rotates a 2x2 square of tiles
function Board:rotate(x, y, counterClockwise)
	if #self.queue > 0 then return end
	local topLeft = self:getTileAt(x, y)
	local topRight = self:getTileAt(x + 1, y)
	local bottomRight = self:getTileAt(x + 1, y + 1)
	local bottomLeft = self:getTileAt(x, y + 1)
	if topLeft then topLeft:rotate(x + 1, y + 1, 'topLeft', counterClockwise) end
	if topRight then topRight:rotate(x + 1, y + 1, 'topRight', counterClockwise) end
	if bottomRight then bottomRight:rotate(x + 1, y + 1, 'bottomRight', counterClockwise) end
	if bottomLeft then bottomLeft:rotate(x + 1, y + 1, 'bottomLeft', counterClockwise) end
	if self:willTilesFall() then
		table.insert(self.queue, self.fallTiles)
		table.insert(self.queue, self.checkNewSquares)
	else
		self:checkNewSquares()
	end
	self.pool:emit('onRotate', counterClockwise)
end

function Board:updateTiles(dt)
	for _, tile in ipairs(self.tiles) do
		tile:update(dt)
	end
end

function Board:flushActions()
	while #self.queue > 0 and self:isIdle() do
		self.queue[1](self)
		table.remove(self.queue, 1)
	end
end

function Board:update(dt)
	self:updateTiles(dt)
	self:flushActions()
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
	if not self.acceptInput then return end
	if not self.mouseInBounds then return end
	if button == 1 then self:rotate(self.cursorX, self.cursorY, true) end
	if button == 2 then self:rotate(self.cursorX, self.cursorY) end
end

function Board:stencil()
	love.graphics.rectangle('fill', 0, 0, self.width, self.height)
end

function Board:drawBackground()
	love.graphics.push 'all'
	for x = 0, self.width - 1 do
		for y = 0, self.height - 1 do
			local index = x + y * (self.width - 1)
			if index % 2 == 0 then
				love.graphics.setColor(.5, .5, .5, .25)
			else
				love.graphics.setColor(.25, .25, .25, .25)
			end
			love.graphics.rectangle('fill', x, y, 1, 1)
		end
	end
	love.graphics.pop()
end

function Board:drawTiles()
	love.graphics.push 'all'
	love.graphics.setStencilTest('gequal', 1)
	love.graphics.stencil(self.stencil, 'increment', 1, true)
	for _, tile in ipairs(self.tiles) do
		tile:draw()
	end
	love.graphics.pop()
end

function Board:drawSquareHighlights()
	for _, _, _, squareHighlight in self.squareHighlights:items() do
		squareHighlight:draw()
	end
end

function Board:drawCursor()
	if not self.acceptInput then return end
	if not self.mouseInBounds then return end
	love.graphics.push 'all'
	love.graphics.setColor(color.white)
	love.graphics.setLineWidth(.1)
	love.graphics.rectangle('line', self.cursorX, self.cursorY, 2, 2)
	love.graphics.pop()
end

function Board:drawOutline()
	love.graphics.push 'all'
	love.graphics.setColor(color.white)
	love.graphics.setLineWidth(.05)
	love.graphics.rectangle('line', 0, 0, self.width, self.height)
	love.graphics.pop()
end

function Board:draw()
	love.graphics.push 'all'
	love.graphics.applyTransform(self.transform)
	self:drawBackground()
	self:drawTiles()
	self:drawSquareHighlights()
	self.pool:emit 'drawOnBoard'
	self:drawCursor()
	self:drawOutline()
	love.graphics.pop()
end

return Board
