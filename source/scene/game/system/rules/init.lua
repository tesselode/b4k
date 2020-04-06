local Board = require 'scene.game.entity.board'
local ChainPopup = require 'scene.game.entity.chain-popup'
local color = require 'color'
local constant = require 'constant'
local font = require 'font'
local Rotation = require 'ui.rotation'
local ScorePopup = require 'scene.game.entity.score-popup'
local util = require 'util'

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
		:new(Rotation, -math.pi/2)
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
	local text = tostring(self.numSquares)
	local left, top = self.board.transform:transformPoint(0, self.board.height + 1/4)
	local _, height = util.getTextSize(font.hud, text)
	local squareSize = height + 16
	love.graphics.push 'all'
	love.graphics.translate(left + squareSize/2, top + height/2)
	love.graphics.scale(self.squareCounterScale)
	self:drawSquaresCounterDecoration(squareSize)
	love.graphics.setFont(font.hud)
	love.graphics.setColor(color.white)
	util.print(text, 12, -8, 0, 1, 1, .5, .5)
	love.graphics.pop()
end

function rules:drawChainCounter()
	if self.chain <= 1 then return end
	local right, top = self.board.transform:transformPoint(self.board.width, self.board.height + 1/4)
	local text = self.chain .. 'x'
	local width, height = util.getTextSize(font.hud, text)
	love.graphics.push 'all'
	love.graphics.setColor(color.white)
	love.graphics.setFont(font.hud)
	util.print(
		text,
		right - width/2, top + height/2,
		0,
		self.chainCounterScale, self.chainCounterScale,
		.5, .5
	)
	love.graphics.pop()
end

function rules:draw()
	self:drawTime()
	self:drawScore()
	self:drawSquaresCounter()
	self:drawChainCounter()
end

return rules
