local basicGameRules = {}

function basicGameRules:onBoardBecameFree(...)
	print('onBoardBecameFree', ...)
end

function basicGameRules:onBoardCheckedSquares(...)
	print('onBoardCheckedSquares', ...)
end

function basicGameRules:onBoardRotatingTiles(...)
	print('onBoardRotatingTiles', ...)
end

function basicGameRules:onBoardClearingTiles(...)
	print('onBoardClearingTiles', ...)
end

function basicGameRules:onBoardRemovedTiles(...)
	print('onBoardRemovedTiles', ...)
end

return basicGameRules
