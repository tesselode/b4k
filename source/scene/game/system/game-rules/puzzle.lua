local basicGameRules = require 'scene.game.system.game-rules'
local Board = require 'scene.game.entity.board'
local cartographer = require 'lib.cartographer'

local puzzle = setmetatable({}, {__index = basicGameRules})

function puzzle:init(puzzleName)
	local map = cartographer.load('puzzle/' .. puzzleName .. '.lua')
	local board = self.pool:queue(Board(self.pool, true))
	for _, color, x, y in map.layers.tiles:getTiles() do
		board:spawnTile(x, y, color)
	end

	self.justRemovedTiles = false

	-- scoring
	self.chain = 1
	self.score = 0

	-- cosmetic
	self.hudSquaresTextScale = 1
	self.hudChainTextScale = 1
	self.rollingScore = 0
end

return puzzle
