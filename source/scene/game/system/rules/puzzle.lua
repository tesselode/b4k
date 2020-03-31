local Board = require 'scene.game.entity.board'
local cartographer = require 'lib.cartographer'
local rules = require 'scene.game.system.rules'

local puzzle = setmetatable({
	showScorePopups = false,
	showChainPopups = false,
}, {__index = rules})

function puzzle:initBoard(puzzleName)
	self.board = self.pool:queue(Board(self.pool, {replenishTiles = false}))
	self.puzzle = cartographer.load('puzzle/' .. puzzleName .. '.lua')
	self.moves = self.puzzle.properties.moves
	for _, gid, x, y in self.puzzle.layers.tiles:getTiles() do
		self.board:spawnTile(x, y, gid)
	end
end

function puzzle:draw() end

return puzzle
