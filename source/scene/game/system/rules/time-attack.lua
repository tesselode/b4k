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
	local left, centerY = board.transform:transformPoint(-1/4, board.height/2)
	local height = util.getTextHeight(font.hud, text)
	love.graphics.push 'all'
	love.graphics.setFont(font.hud)
	love.graphics.setColor(color.white)
	util.printf(text, left, centerY, 100000, 'center', -math.pi/2, .5, .5, 50000, height)
	love.graphics.pop()
end

function timeAttack:drawTime()
	local board = self.pool.groups.board.entities[1]
	if not board then return end
	local text = util.formatTime(self.time)
	local right, bottom = board.transform:transformPoint(board.width, -1/4)
	local height = util.getTextHeight(font.hud, text)
	love.graphics.push 'all'
	love.graphics.setFont(font.hud)
	love.graphics.setColor(color.white)
	util.printf(text, right, bottom, 100000, 'right', 0, .5, .5, 100000, height)
	love.graphics.pop()
end

function timeAttack:drawSquaresCount()
	if self.numSquares <= 0 then return end
	local board = self.pool.groups.board.entities[1]
	if not board then return end
	local squareSize = 208
	local text = tostring(self.numSquares)
	local left, top = board.transform:transformPoint(0, board.height + 1/4)
	local width = font.hud:getWidth(text)
	local height = util.getTextHeight(font.hud, text)
	love.graphics.push 'all'
	love.graphics.translate(left + squareSize/2, top + squareSize/2)
	love.graphics.scale(self.squareCounterScale)
	love.graphics.setColor(color.withAlpha(color.white, 1/4))
	love.graphics.setLineWidth(8)
	love.graphics.line(0, -squareSize/2, 0, squareSize/2)
	love.graphics.line(-squareSize/2, 0, squareSize/2, 0)
	love.graphics.setColor(color.white)
	love.graphics.rectangle('line', -squareSize/2, -squareSize/2, squareSize, squareSize)
	love.graphics.setFont(font.hud)
	util.print(self.numSquares, 12, -8, 0, .5, .5, width/2, height/2)
	love.graphics.pop()
end

function timeAttack:draw()
	self:drawTime()
	self:drawScore()
	self:drawSquaresCount()
end

return timeAttack
