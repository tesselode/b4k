local ChainPopup = require 'scene.game.entity.chain-popup'
local color = require 'color'
local font = require 'font'
local ScorePopup = require 'scene.game.entity.score-popup'
local util = require 'util'

local timeAttack = {}

function timeAttack:init()
	self.numSquares = 0
	self.score = 0
	self.chain = 1
	self.justClearedTiles = false
	self.time = 0

	-- cosmetic
	self.squareCounterScale = 1
	self.chainCounterScale = 1
end

function timeAttack:createChainPopup(board, squares)
	local sumX, sumY = 0, 0
	for _, x, y in squares:items() do
		sumX = sumX + x + 1
		sumY = sumY + y + 1
	end
	local chainPopupX, chainPopupY = board.transform:transformPoint(
		sumX / squares:count(),
		sumY / squares:count()
	)
	self.pool:queue(ChainPopup(self.pool, chainPopupX, chainPopupY))
end

function timeAttack:onClearTiles(board, squares, tiles, numTiles)
	local scoreIncrement = 0
	for i = 1, squares:count() do
		scoreIncrement = scoreIncrement + i
	end
	scoreIncrement = scoreIncrement * self.chain
	self.score = self.score + scoreIncrement
	self.justClearedTiles = true

	-- spawn the score popup
	local sumTilesX, sumTilesY = 0, 0
	for tile in pairs(tiles) do
		sumTilesX = sumTilesX + tile.x
		sumTilesY = sumTilesY + tile.y
	end
	local scorePopupX, scorePopupY = board.transform:transformPoint(
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

function timeAttack:onCheckSquares(board, squares, numNewSquares)
	self.numSquares = squares:count()
	if squares:count() > 0 then
		if self.justClearedTiles then
			self.chain = self.chain + 1
			self:createChainPopup(board, squares)
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

function timeAttack:update(dt)
	self.time = self.time + dt
end

function timeAttack:drawScore()
	local board = self.pool.groups.board.entities[1]
	if not board then return end
	local text = tostring(self.score)
	local left, middle = board.transform:transformPoint(-1/4, board.height/2)
	love.graphics.push 'all'
	love.graphics.setFont(font.hud)
	love.graphics.setColor(color.white)
	util.printf(text, left, middle, 100000, 'center', 'bottom', -math.pi/2, .5, .5)
	love.graphics.pop()
end

function timeAttack:drawTime()
	local board = self.pool.groups.board.entities[1]
	if not board then return end
	local text = util.formatTime(self.time)
	local right, bottom = board.transform:transformPoint(board.width, -1/4)
	love.graphics.push 'all'
	love.graphics.setFont(font.hud)
	love.graphics.setColor(color.white)
	util.printf(text, right, bottom, 100000, 'right', 'bottom', 0, .5, .5)
	love.graphics.pop()
end

function timeAttack:drawSquaresCounterDecoration(size)
	love.graphics.push 'all'
	love.graphics.setLineWidth(8)
	love.graphics.setColor(color.withAlpha(color.white, 1/4))
	love.graphics.line(-size/2, 0, size/2, 0)
	love.graphics.line(0, -size/2, 0, size/2)
	love.graphics.setColor(color.white)
	love.graphics.rectangle('line', -size/2, -size/2, size, size)
	love.graphics.pop()
end

function timeAttack:drawSquaresCounter()
	if self.numSquares <= 0 then return end
	local board = self.pool.groups.board.entities[1]
	if not board then return end
	local text = tostring(self.numSquares)
	local left, top = board.transform:transformPoint(0, board.height + 1/4)
	local width, height = util.getTextSize(font.hud, text)
	local squareSize = height/2 + 16
	love.graphics.push 'all'
	love.graphics.translate(left + squareSize/2, top + height/4)
	love.graphics.scale(self.squareCounterScale)
	self:drawSquaresCounterDecoration(squareSize)
	love.graphics.setFont(font.hud)
	love.graphics.setColor(color.white)
	love.graphics.print(text, 12, -8, 0, .5, .5, width/2, height/2)
	love.graphics.pop()
end

function timeAttack:drawChainCounter()
	if self.chain <= 1 then return end
	local board = self.pool.groups.board.entities[1]
	if not board then return end
	local right, top = board.transform:transformPoint(board.width, board.height + 1/4)
	local text = self.chain .. 'x'
	local width, height = util.getTextSize(font.hud, text)
	love.graphics.push 'all'
	love.graphics.setColor(color.white)
	love.graphics.setFont(font.hud)
	love.graphics.print(
		text,
		right - width/4, top + width/4,
		0,
		self.chainCounterScale / 2, self.chainCounterScale / 2,
		width/2, height/2
	)
	love.graphics.pop()
end

function timeAttack:draw()
	self:drawTime()
	self:drawScore()
	self:drawSquaresCounter()
	self:drawChainCounter()
end

return timeAttack
