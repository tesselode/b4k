local color = require 'color'
local Grid = require 'grid'
local Object = require 'lib.classic'
local Tile = require 'scene.game.entity.board.tile'
local util = require 'util'

local Board = Object:extend()

Board.width = 8
Board.height = 8
Board.baseScale = 2/3

function Board:spawnTile(x, y, tileColor)
	table.insert(self.tiles, Tile(self.pool, x, y, tileColor))
end

function Board:initTiles()
	self.tiles = {}
	for x = 0, self.width - 1 do
		for y = 0, self.height - 1 do
			self:spawnTile(x, y)
		end
	end
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

function Board:new(pool)
	self.pool = pool
	self:initTiles()
	self:initTransform()
	self:initCursor()
	self.queue = {}
	self.stencil = util.bind(self.stencil, self)
end

function Board:add(e)
	if e ~= self then return end
	self:checkSquares()
end

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
		end
	end
	self.pool:emit('onCheckSquares', self.squares)
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

function Board:clearTiles()
	local tiles = {}
	for _, x, y in self.squares:items() do
		tiles[self:getTileAt(x, y)] = true
		tiles[self:getTileAt(x + 1, y)] = true
		tiles[self:getTileAt(x + 1, y + 1)] = true
		tiles[self:getTileAt(x, y + 1)] = true
	end
	for tile in pairs(tiles) do
		tile:clear()
	end
	table.insert(self.queue, self.removeTiles)
end

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

function Board:removeTiles()
	for i = #self.tiles, 1, -1 do
		local tile = self.tiles[i]
		if tile.state == 'cleared' then
			table.remove(self.tiles, i)
		end
	end
	self:replenishTiles()
	self:fallTiles()
	table.insert(self.queue, self.checkSquares)
end

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
		table.insert(self.queue, self.checkSquares)
	else
		self:checkSquares()
	end
end

function Board:update(dt)
	for _, tile in ipairs(self.tiles) do
		tile:update(dt)
	end
	while #self.queue > 0 and self:isIdle() do
		self.queue[1](self)
		table.remove(self.queue, 1)
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

function Board:stencil()
	love.graphics.rectangle('fill', 0, 0, self.width, self.height)
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
	self.pool:emit 'drawOnBoard'
	self:drawCursor()
	love.graphics.pop()
end

return Board
