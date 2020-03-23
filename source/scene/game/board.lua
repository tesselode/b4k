local Object = require 'lib.classic'
local Tile = require 'scene.game.tile'

local Board = Object:extend()

Board.width = 8
Board.height = 8
Board.baseScale = 2/3

function Board:initTiles()
	self.tiles = {}
	for x = 0, self.width - 1 do
		for y = 0, self.height - 1 do
			table.insert(self.tiles, Tile(x, y))
		end
	end
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

function Board:new()
	self:initTiles()
	self:initTransform()
end

function Board:draw()
	love.graphics.push 'all'
	love.graphics.applyTransform(self.transform)
	for _, tile in ipairs(self.tiles) do
		tile:draw()
	end
	love.graphics.pop()
end

return Board
