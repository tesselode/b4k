local constant = require 'constant'
local SquareHighlight = require 'scene.game.entity.square-highlight'

local squareHighlights = {}

function squareHighlights:init(groupName, board)
	for x = 0, constant.boardWidth - 2 do
		for y = 0, constant.boardHeight - 2 do
			self.pool:queue(SquareHighlight(self.pool, x, y))
		end
	end
end

return squareHighlights
