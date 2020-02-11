local SquareHighlight = require 'scene.game.entity.square-highlight'

local squareHighlights = {}

function squareHighlights:addToGroup(groupName, board)
	if groupName ~= 'board' then return end
	self.highlights = {}
	for x = 0, board.width - 2 do
		self.highlights[x] = {}
		for y = 0, board.height - 2 do
			self.highlights[x][y] = SquareHighlight(self.pool, x, y)
		end
	end
end

function squareHighlights:onBoardCheckedSquares(board, squares, totalSquares, newSquares)
	if not self.highlights then return end
	for x = 0, board.width - 2 do
		for y = 0, board.height - 2 do
			local index = y * board.width + x
			if squares[index] then
				self.highlights[x][y]:activate()
			else
				self.highlights[x][y]:deactivate()
			end
		end
	end
end

function squareHighlights:onBoardClearingTiles(board, clearedTiles, numClearedTiles)
	if not self.highlights then return end
	for x = 0, board.width - 2 do
		for y = 0, board.height - 2 do
			self.highlights[x][y]:burst()
		end
	end
end

function squareHighlights:drawOnBoard()
	if not self.highlights then return end
	local board = self.pool.groups.board.entities[1]
	for x = 0, board.width - 2 do
		for y = 0, board.height - 2 do
			self.highlights[x][y]:draw()
		end
	end
end

return squareHighlights
