local constant = require 'constant'
local Object = require 'lib.classic'
local Tile = require 'class.game.tile'

local Board = Object:extend()

Board.size = 8
Board.sizeOnScreen = .6

function Board:initTransform()
	self.transform = self.transform or love.math.newTransform()
	self.transform:reset()
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
end

function Board:resize(w, h)
	self:initTransform()
end

function Board:draw()
	love.graphics.push 'all'
	love.graphics.applyTransform(self.transform)
	for _, tile in ipairs(self.tiles) do
		tile:_draw()
	end
	love.graphics.pop()
end

return Board
