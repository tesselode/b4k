local Board = require 'scene.game.entity.board'
local ChainPopup = require 'scene.game.entity.chain-popup'
local constant = require 'constant'
local font = require 'font'
local ScorePopup = require 'scene.game.entity.score-popup'
local util = require 'util'

local basicGameRules = {
	rollingScoreSpeed = 10,
	rollingScoreRoundUpThreshold = .4,
}

function basicGameRules:createBoard(...)
	self.pool:queue(Board(self.pool))
end

function basicGameRules:init(...)
	self:createBoard(...)

	-- global state
	self.pool.data.gameInProgress = true

	-- internal state
	self.numSquares = 0
	self.justRemovedTiles = false

	-- scoring
	self.chain = 1
	self.score = 0

	-- cosmetic
	self.hudSquaresTextScale = 1
	self.hudChainTextScale = 1
	self.rollingScore = 0
end

function basicGameRules:onBoardRemovedTiles(board)
	self.justRemovedTiles = true
end

function basicGameRules:onBoardCheckedSquares(board, squares, numSquares, numNewSquares)
	if not self.pool.data.gameInProgress then return end
	self.numSquares = numSquares
	if numSquares < 1 then
		self.chain = 1
	elseif self.justRemovedTiles then
		self.chain = self.chain + 1
		self:playChainTextPulseAnimation()
		self:createChainPopup(board, squares, numSquares)
	end
	self.justRemovedTiles = false
	if numNewSquares > 0 then
		self:playSquaresTextPulseAnimation()
	end
end

function basicGameRules:onBoardClearingTiles(board, clearedTiles, numClearedTiles)
	local scoreIncrement = 0
	for i = 1, self.numSquares do
		scoreIncrement = scoreIncrement + i
	end
	scoreIncrement = scoreIncrement * self.chain
	self.score = self.score + scoreIncrement

	-- spawn the score popup
	local sumTilesX, sumTilesY = 0, 0
	for tile in pairs(clearedTiles) do
		sumTilesX = sumTilesX + tile.x
		sumTilesY = sumTilesY + tile.y
	end
	local scorePopupX, scorePopupY = board.transform:transformPoint(
		sumTilesX / numClearedTiles + .5,
		sumTilesY / numClearedTiles + .5
	)
	self.pool:queue(ScorePopup(
		self.pool,
		scorePopupX,
		scorePopupY,
		self.numSquares,
		scoreIncrement,
		self.chain
	))
end

function basicGameRules:playSquaresTextPulseAnimation()
	if self.hudSquaresTextScaleTween then
		self.hudSquaresTextScaleTween:stop()
	end
	self.hudSquaresTextScale = 1.1
	self.hudSquaresTextScaleTween = self.pool.data.tweens:to(self, .15, {hudSquaresTextScale = 1})
end

function basicGameRules:playChainTextPulseAnimation()
	if self.hudChainTextScaleTween then
		self.hudChainTextScaleTween:stop()
	end
	self.hudChainTextScale = 1.25
	self.hudChainTextScaleTween = self.pool.data.tweens:to(self, .3, {hudChainTextScale = 1})
end

function basicGameRules:createChainPopup(board, squares, numSquares)
	local sumX, sumY = 0, 0
	for square in pairs(squares) do
		local x, y = util.indexToCoordinates(constant.boardWidth, square)
		sumX = sumX + x + 1
		sumY = sumY + y + 1
	end
	local chainPopupX, chainPopupY = board.transform:transformPoint(
		sumX / numSquares,
		sumY / numSquares
	)
	self.pool:queue(ChainPopup(self.pool, chainPopupX, chainPopupY))
end

function basicGameRules:updateRollingScore(dt)
	self.rollingScore = util.lerp(self.rollingScore, self.score, self.rollingScoreSpeed * dt)
	if self.rollingScore > self.score - self.rollingScoreRoundUpThreshold then
		self.rollingScore = self.score
	end
end

function basicGameRules:update(dt)
	self:updateRollingScore(dt)
end

function basicGameRules:drawScore()
	local board = self.pool.groups.board.entities[1]
	local centerX, bottom = board.transform:transformPoint(constant.boardWidth/2, -1/4)
	self.pool.data.layout
		:new('text', font.hud, util.pad(math.floor(self.rollingScore), 0, 8))
			:centerX(centerX)
			:bottom(bottom)
end

function basicGameRules:drawSquaresCounter()
	local board = self.pool.groups.board.entities[1]
	if self.numSquares == 0 then return end
	local left, top = board.transform:transformPoint(0, constant.boardHeight + 1/4)
	local layout = self.pool.data.layout
	layout
		:new 'rectangle'
			:beginChildren()
				:new 'transform'
					:beginChildren()
						:new 'rectangle'
							:size(board.scale * 1.5, board.scale * 1.5)
							:outlineColor(1, 1, 1)
							:outlineWidth(8)
							:beginChildren()
								:new('line',
									0, layout:get('@parent', 'height') / 2,
									layout:get('@parent', 'width'), layout:get('@parent', 'height') / 2
								)
									:color(.25, .25, .25)
									:lineWidth(8)
								:new('line',
									layout:get('@parent', 'width') / 2, 0,
									layout:get('@parent', 'width') / 2, layout:get('@parent', 'height')
								)
									:color(.25, .25, .25)
									:lineWidth(8)
								:new('text', font.hud, self.numSquares)
									:centerX(layout:get('@parent', 'width') * .55)
									:centerY(layout:get('@parent', 'height') * .45)
							:endChildren()
					:endChildren()
					:origin(.5)
					:scale(self.hudSquaresTextScale)
			:endChildren()
			:left(left):top(top)
end

function basicGameRules:drawChainCounter()
	if self.chain < 2 then return end
	local board = self.pool.groups.board.entities[1]
	local right, top = board.transform:transformPoint(constant.boardWidth, constant.boardHeight + 1/4)
	local layout = self.pool.data.layout
	layout
		:new 'rectangle'
			:beginChildren()
				:new 'transform'
					:beginChildren()
						:new('text', font.hud, self.chain .. 'x')
						local chainText = layout:getElement()
					layout:endChildren()
					:origin(.5)
					:scale(self.hudChainTextScale)
			:endChildren()
			:width(layout:get(chainText, 'width'))
			:right(right)
			:top(top)
end

function basicGameRules:draw()
	self:drawScore()
	self:drawSquaresCounter()
	self:drawChainCounter()
end

return basicGameRules
