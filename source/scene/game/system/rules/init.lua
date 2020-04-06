local Board = require 'scene.game.entity.board'
local ChainPopup = require 'scene.game.entity.chain-popup'
local charm = require 'lib.charm'
local color = require 'color'
local constant = require 'constant'
local font = require 'font'
local ScorePopup = require 'scene.game.entity.score-popup'
local Transform = require 'ui.transform'
local util = require 'util'

local SquaresCounterDecoration = charm.extend('SquaresCounterDecoration', 'element')

function SquaresCounterDecoration:drawBottom()
	local width, height = self:get 'size'
	love.graphics.push 'all'
	love.graphics.setLineWidth(8)
	love.graphics.setColor(color.withAlpha(color.white, 1/4))
	love.graphics.line(0, height/2, width, height/2)
	love.graphics.line(width/2, 0, width/2, height)
	love.graphics.setColor(color.white)
	love.graphics.rectangle('line', 0, 0, width, height)
	love.graphics.pop()
end

local rules = {
	showScorePopups = true,
	showChainPopups = true,
}

function rules:initBoard()
	self.board = self.pool:queue(Board(self.pool))
	self.board:fillWithRandomTiles()
end

function rules:init(...)
	self:initBoard(...)
	self.numSquares = 0
	self.score = 0
	self.chain = 1
	self.justClearedTiles = false
	self.time = 0

	-- cosmetic
	self.squareCounterScale = 1
	self.chainCounterScale = 1
end

function rules:createChainPopup(squares)
	local sumX, sumY = 0, 0
	for _, x, y in squares:items() do
		sumX = sumX + x + 1
		sumY = sumY + y + 1
	end
	local chainPopupX, chainPopupY = self.board.transform:transformPoint(
		sumX / squares:count(),
		sumY / squares:count()
	)
	self.pool:queue(ChainPopup(self.pool, chainPopupX, chainPopupY))
end

function rules:onClearTiles(squares, tiles, numTiles)
	local scoreIncrement = 0
	for i = 1, squares:count() do
		scoreIncrement = scoreIncrement + i
	end
	scoreIncrement = scoreIncrement * self.chain
	self.score = self.score + scoreIncrement
	self.justClearedTiles = true

	-- spawn the score popup
	if not self.showScorePopups then return end
	local sumTilesX, sumTilesY = 0, 0
	for tile in pairs(tiles) do
		sumTilesX = sumTilesX + tile.x
		sumTilesY = sumTilesY + tile.y
	end
	local scorePopupX, scorePopupY = self.board.transform:transformPoint(
		sumTilesX / numTiles + .5,
		sumTilesY / numTiles + .5
	)
	self.pool:queue(ScorePopup(
		self.pool,
		scorePopupX,
		scorePopupY,
		squares:count(),
		scoreIncrement,
		self.chain
	))
end

function rules:onCheckSquares(squares, numNewSquares)
	self.numSquares = squares:count()
	if squares:count() > 0 then
		if self.justClearedTiles then
			self.chain = self.chain + 1
			if self.showChainPopups then
				self:createChainPopup(squares)
			end
			-- animate chain counter
			self.chainCounterScale = 1.25
			self.pool.data.tweens:to(self, .3, {chainCounterScale = 1})
		end
	else
		self.chain = 1
	end
	self.justClearedTiles = false
	-- animate square counter
	if numNewSquares > 0 then
		self.squareCounterScale = 1.1
		self.pool.data.tweens:to(self, .15, {squareCounterScale = 1})
	end
end

function rules:update(dt)
	self.time = self.time + dt
end

function rules:drawScore()
	local right, centerY = self.board.transform:transformPoint(-1/4, self.board.height/2)
	self.pool.data.ui
		:new(Transform)
			:angle(-math.pi/2)
			:origin(.5, 1)
			:beginChildren()
				:new('text', font.hud, self.score)
					:centerX(right)
					:bottom(centerY)
					:color(color.white)
					:scale(1 / constant.fontScale)
			:endChildren()
end

function rules:drawTime()
	local right, bottom = self.board.transform:transformPoint(self.board.width, -1/4)
	self.pool.data.ui
		:new('text', font.hud, util.formatTime(self.time))
		:right(right):bottom(bottom)
		:scale(1 / constant.fontScale)
		:color(color.white)
end

function rules:drawSquaresCounterDecoration(size)
	love.graphics.push 'all'
	love.graphics.setLineWidth(8)
	love.graphics.setColor(color.withAlpha(color.white, 1/4))
	love.graphics.line(-size/2, 0, size/2, 0)
	love.graphics.line(0, -size/2, 0, size/2)
	love.graphics.setColor(color.white)
	love.graphics.rectangle('line', -size/2, -size/2, size, size)
	love.graphics.pop()
end

function rules:drawSquaresCounter()
	if self.numSquares <= 0 then return end
	local left, top = self.board.transform:transformPoint(0, self.board.height + 1/4)
	self.pool.data.ui
		:new(Transform)
			:scale(self.squareCounterScale)
			:origin(.5, .5)
			:beginChildren()
				:new(SquaresCounterDecoration)
					:beginChildren()
						:new('text', font.hud, self.numSquares)
							:left(left):top(top)
							:scale(1 / constant.fontScale)
							:color(color.white)
					:endChildren()
					:wrap()
					:origin(.5, .5)
					:pad(8)
					:width(self.pool.data.ui:get('@current', 'height'))
					:alignChildren(.5, .5)
					:shiftChildren(12, -8)
					:left(left)
			:endChildren()
end

function rules:drawChainCounter()
	if self.chain <= 1 then return end
	local right, top = self.board.transform:transformPoint(self.board.width, self.board.height + 1/4)
	self.pool.data.ui
		:new('text', font.hud, self.chain .. 'x')
			:right(right):top(top)
			:scale(1 / constant.fontScale)
			:origin(.5, .5)
			:scale(self.chainCounterScale)
			:color(color.white)
end

function rules:draw()
	self:drawTime()
	self:drawScore()
	self:drawSquaresCounter()
	self:drawChainCounter()
end

return rules
