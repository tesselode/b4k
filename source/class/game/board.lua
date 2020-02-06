local charm = require 'lib.charm'
local color = require 'color'
local constant = require 'constant'
local font = require 'font'
local Object = require 'lib.classic'
local ScorePopup = require 'class.game.score-popup'
local Tile = require 'class.game.tile'
local util = require 'util'

local Board = Object:extend()

Board.size = 8
Board.sizeOnScreen = .6
Board.cursorLineWidth = .1
Board.rollingScoreSpeed = 10
Board.rollingScoreRoundUpThreshold = .4

function Board:initTransform()
	self.scale = constant.screenHeight * self.sizeOnScreen / self.size
	self.transform = love.math.newTransform()
	self.transform:translate(constant.screenWidth / 2, constant.screenHeight / 2)
	self.transform:scale(self.scale)
	self.transform:translate(-self.size / 2, -self.size / 2)
end

function Board:spawnTile(x, y, options)
	table.insert(self.tiles, self.pool:queue(Tile(self.pool, x, y, options)))
end

function Board:initTiles()
	local tileOptions = {skipSpawnAnimation = true}
	self.tiles = {}
	for x = 0, self.size - 1 do
		for y = 0, self.size - 1 do
			self:spawnTile(x, y, tileOptions)
		end
	end
end

function Board:new(pool)
	self.pool = pool
	self:initTiles()
	self:initTransform()
	self.previousSquares = {}
	self.squares = {}
	self.totalSquares = 0
	self.clearedTiles = {}
	self.removedTiles = {}
	self.queue = {}
	self.mouseInBounds = false
	self.cursorX, self.cursorY = 0, 0
	self.score = 0
	self:detectSquares()

	-- cosmetic
	self.hudSquaresTextScale = 1
	self.rollingScore = 0
end

function Board:isFree(toRotate)
	for _, tile in ipairs(self.tiles) do
		if not tile:isFree(toRotate) then return false end
	end
	if toRotate and #self.queue > 0 then return false end
	return true
end

function Board:update(dt)
	while self:isFree() and #self.queue > 0 do
		self.queue[1](self)
		table.remove(self.queue, 1)
	end
	self.rollingScore = util.lerp(self.rollingScore, self.score, self.rollingScoreSpeed * dt)
	if self.rollingScore > self.score - self.rollingScoreRoundUpThreshold then
		self.rollingScore = self.score
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
	local previousTotalSquares = self.totalSquares
	self.totalSquares = 0
	local newSquares = 0
	for x = 0, self.size - 2 do
		for y = 0, self.size - 2 do
			local index = y * self.size + x
			if self:squareAt(x, y) then
				self.squares[index] = true
				self.totalSquares = self.totalSquares + 1
				if not self.previousSquares[index] then
					newSquares = newSquares + 1
				end
			end
		end
	end
	if self.totalSquares > previousTotalSquares then
		if self.hudSquaresTextScaleTween then
			self.hudSquaresTextScaleTween:stop()
		end
		self.hudSquaresTextScale = 1.1
		self.hudSquaresTextScaleTween = self.pool.data.tweens:to(self, .15, {hudSquaresTextScale = 1})
	end
	return newSquares
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
	local numNewSquares = self:detectSquares()
	if self.totalSquares > 0 and numNewSquares == 0 then
		table.insert(self.queue, self.clearTiles)
	end
end

function Board:clearTiles()
	local sumTilesX, sumTilesY = 0, 0
	local numClearedTiles = 0
	for i = 0, self.size ^ 2 - 1 do
		if self.squares[i] then
			local x, y = util.indexToCoordinates(self.size, i)
			for tileX = x, x + 1 do
				for tileY = y, y + 1 do
					local tile = self:getTileAt(tileX, tileY)
					if tile and not self.clearedTiles[tile] then
						tile:clear()
						sumTilesX = sumTilesX + tile.x
						sumTilesY = sumTilesY + tile.y
						numClearedTiles = numClearedTiles + 1
						self.clearedTiles[tile] = true
					end
				end
			end
		end
	end

	-- award points
	local scoreIncrement = 0
	for i = 1, self.totalSquares do
		scoreIncrement = scoreIncrement + i
	end
	self.score = self.score + scoreIncrement

	-- spawn the score popup
	local scorePopupX, scorePopupY = self.transform:transformPoint(
		sumTilesX / numClearedTiles + .5,
		sumTilesY / numClearedTiles + .5
	)
	self.pool:queue(ScorePopup(
		self.pool,
		scorePopupX,
		scorePopupY,
		self.totalSquares,
		scoreIncrement
	))

	-- reset some data
	util.clear(self.clearedTiles)
	util.clear(self.squares)

	-- queue up a tile removal pass if needed
	if numClearedTiles > 0 then
		table.insert(self.queue, self.removeTiles)
	end
end

function Board:removeTiles()
	util.clear(self.removedTiles)
	--[[
		minX and minY are the minimum tile x and y values
		out of all the tiles removed in this sweep. These
		values are used to make the tile spawning animation
		a little tighter - see the Tile class for the juicy
		details.
	]]
	local minX, minY
	for i = #self.tiles, 1, -1 do
		local tile = self.tiles[i]
		if tile.cleared then
			table.remove(self.tiles, i)
			local index = util.coordinatesToIndex(self.size, tile.x, tile.y)
			table.insert(self.removedTiles, index)
			minX = minX and math.min(minX, tile.x) or tile.x
			minY = minY and math.min(minY, tile.y) or tile.y
		end
	end
	local tileOptions = {
		spawnAnimationMinX = minX,
		spawnAnimationMinY = minY,
	}
	for _, index in ipairs(self.removedTiles) do
		local x, y = util.indexToCoordinates(self.size, index)
		self:spawnTile(x, y, tileOptions)
	end
	self:detectSquares()
end

function Board:mousemoved(x, y, dx, dy, istouch)
	x, y = self.transform:inverseTransformPoint(x, y)
	self.mouseInBounds = not (x < 0 or x > self.size or y < 0 or y > self.size)
	self.cursorX, self.cursorY = math.floor(x), math.floor(y)
	self.cursorX = util.clamp(self.cursorX, 0, self.size - 2)
	self.cursorY = util.clamp(self.cursorY, 0, self.size - 2)
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

function Board:drawTiles()
	for _, tile in ipairs(self.tiles) do
		tile:_draw()
	end
end

function Board:drawCursor()
	if not self.mouseInBounds then return end
	love.graphics.push 'all'
	love.graphics.setLineWidth(self.cursorLineWidth)
	love.graphics.rectangle('line', self.cursorX, self.cursorY, 2, 2)
	love.graphics.pop()
end

function Board:drawSquareHighlights()
	love.graphics.push 'all'
	love.graphics.setColor(color.white)
	love.graphics.setLineWidth(.05)
	for i = 0, self.size ^ 2 - 1 do
		if self.squares[i] then
			local x, y = util.indexToCoordinates(self.size, i)
			love.graphics.rectangle('line', x, y, 2, 2)
		end
	end
	love.graphics.pop()
end

function Board:drawHud()
	if self.totalSquares > 0 then
		local text = self.totalSquares == 1 and '1 square' or self.totalSquares .. ' squares'
		local centerX, top = self.transform:transformPoint(self.size/2, self.size + 1/4)
		self.pool.data.layout
			:new('text', font.hud, text)
				:centerX(centerX)
				:top(top)
				:scale(self.hudSquaresTextScale)
	end
	local centerX, bottom = self.transform:transformPoint(self.size/2, -1/4)
	self.pool.data.layout
		:new('text', font.hud, util.pad(math.floor(self.rollingScore), 0, 8))
			:centerX(centerX)
			:bottom(bottom)
end

function Board:draw()
	love.graphics.push 'all'
	love.graphics.applyTransform(self.transform)
	self:drawTiles()
	self:drawSquareHighlights()
	self:drawCursor()
	self:drawHud()
	love.graphics.pop()
end

return Board
