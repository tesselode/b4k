local Object = require 'lib.classic'
local Tile = require 'class.game.tile'

local Board = Object:extend()

Board.width = 8
Board.height = 8

function Board:initTransform()
	self.transform = love.math.newTransform(0, 0, 0, 64, 64)
end

function Board:initTiles()
	self.tiles = {}
	for x = 0, self.width - 1 do
		for y = 0, self.height - 1 do
			table.insert(self.tiles, self.pool:queue(Tile(x, y)))
		end
	end
end

function Board:new(pool)
	self.pool = pool
	self:initTiles()
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
