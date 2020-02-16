local basicGameRules = require 'scene.game.system.game-rules'
local Board = require 'scene.game.entity.board'
local cartographer = require 'lib.cartographer'

local puzzle = setmetatable({}, {__index = basicGameRules})

function puzzle:createBoard(puzzleName)
	local map = cartographer.load('puzzle/' .. puzzleName .. '.lua')
	local board = self.pool:queue(Board(self.pool, {
		fillWithRandomTiles = false,
		spawnNewTiles = false,
	}))
	for _, gid, x, y in map.layers.tiles:getTiles() do
		board:spawnTile(x, y, map:getTileProperty(gid, 'color'))
	end
end

-- don't track score or show score popups
function puzzle:onBoardClearingTiles() end

function puzzle:draw() end

return puzzle
