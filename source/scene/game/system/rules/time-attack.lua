local color = require 'color'
local font = require 'font'
local ScorePopup = require 'scene.game.entity.score-popup'
local util = require 'util'

local timeAttack = {}

function timeAttack:init()
	self.score = 0
	self.chain = 1
	self.justClearedTiles = false
	self.time = 0
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

function timeAttack:onCheckSquares(board, squares)
	if squares:count() > 0 then
		if self.justClearedTiles then
			self.chain = self.chain + 1
		end
	else
		self.chain = 1
	end
	self.justClearedTiles = false
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

function timeAttack:draw()
	self:drawTime()
	self:drawScore()
end

return timeAttack
