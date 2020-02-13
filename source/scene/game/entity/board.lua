local constant = require 'constant'
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

function Board:spawnTile(x, y, color)
	table.insert(self.tiles, Tile(self.pool, x, y, color))
end

function Board:initTiles()
	self.tiles = {}
	for x = 0, constant.boardWidth - 1 do
		for y = 0, constant.boardHeight - 1 do
			self:spawnTile(x, y)
		end
	end
end

function Board:new(pool)
	self.pool = pool
	self:initTiles()
	self:initTransform()
	self.mouseInBounds = false
	self.cursorX, self.cursorY = 0, 0
	self.canRotate = true
	self.stencil = util.bind(self.stencil, self)
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
		await(Promise.all(promises))
		print 'finished rotating tiles'
	end)
end

function Board:mousemoved(x, y, dx, dy, istouch)
	x, y = self.transform:inverseTransformPoint(x, y)
	self.mouseInBounds = not (x < 0 or x > constant.boardWidth or y < 0 or y > constant.boardHeight)
	self.cursorX, self.cursorY = math.floor(x), math.floor(y)
	self.cursorX = util.clamp(self.cursorX, 0, constant.boardWidth - 2)
	self.cursorY = util.clamp(self.cursorY, 0, constant.boardHeight - 2)
end

function Board:mousepressed(x, y, button, istouch, presses)
	if self.mouseInBounds and self.canRotate then
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
