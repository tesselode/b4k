local SquareHighlight = require 'scene.game.entity.square-highlight'

local squareHighlights = {}

function squareHighlights:addToGroup(groupName, board)
	if groupName ~= 'board' then return end
	for x = 0, board.width - 2 do
		for y = 0, board.height - 2 do
			self.pool:queue(SquareHighlight(self.pool, x, y))
		end
	end
end

return squareHighlights
