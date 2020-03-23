local basicGameRules = require 'scene.game.system.game-rules'
local color = require 'color'
local constant = require 'constant'
local font = require 'font'
local util = require 'util'

local timeAttack = setmetatable({
	goalScore = 100,
}, {__index = basicGameRules})

function timeAttack:init()
	basicGameRules.init(self)
	self.time = 0
	self.barAmount = 0

	-- intro animation
	self.pool.data.gameInProgress = false
	self.screenDimAlpha = .5
	self.goalTextAlpha = 1
	self.readyTextAlpha = 0
	self.readyTextScale = 1.5
	self.readyBorderSize = 0
	self.goTextAlpha = 0
	self.goTextScale = 1.5
	self.pool.data.tweens:to(self, 1/4, {
		readyTextAlpha = 1,
		readyTextScale = 1,
	})
		:delay(1)
	:after(1/4, {
		goTextAlpha = 1,
		goTextScale = 1,
	})
		:delay(1)
		:onstart(function()
			self.pool.data.gameInProgress = true
			self.readyTextAlpha = 0
			self.pool.data.tweens:to(self, 1/4, {
				goalTextAlpha = 0,
				screenDimAlpha = 0,
			})
		end)
	:after(1/4, {goTextAlpha = 0})
		:delay(3/4)

	-- results screen
	self.finishTextAlpha = 0
	self.finishTextScale = 1.5
	self.restartTextAlpha = 0
end

function timeAttack:updateProgressBar(dt)
	local barAmountIncrement = (self.score / self.goalScore - self.barAmount) * 10
	barAmountIncrement = math.min(barAmountIncrement, 1.5)
	self.barAmount = self.barAmount + barAmountIncrement * dt
	self.barAmount = util.clamp(self.barAmount, 0, 1)
end

function timeAttack:update(dt)
	if self.pool.data.gameInProgress then
		self.time = self.time + dt
	end
	self:updateProgressBar(dt)
	basicGameRules.update(self, dt)
end

function timeAttack:onBoardClearingTiles(board, clearedTiles, numClearedTiles)
	basicGameRules.onBoardClearingTiles(self, board, clearedTiles, numClearedTiles)
	if self.score >= self.goalScore then
		self.pool.data.gameInProgress = false
		self.pool.data.tweens:to(self, 1/4, {
			finishTextScale = 1,
			finishTextAlpha = 1,
			screenDimAlpha = .5,
			restartTextAlpha = 1,
		})
	end
end

function timeAttack:drawTime()
	local board = self.pool.groups.board.entities[1]
	local right, bottom = board.transform:transformPoint(constant.boardWidth, -1/4)
	self.pool.data.layout
		:new('text', font.hud, util.formatTime(self.time))
			:right(right)
			:bottom(bottom)
end

function timeAttack:drawScore()
	local layout = self.pool.data.layout
	local board = self.pool.groups.board.entities[1]
	local barRight, barBottom = board.transform:transformPoint(-1/4, constant.boardHeight)
	layout
		:new 'rectangle'
			:right(barRight):bottom(barBottom)
			:size(64, constant.boardHeight * board.scale * self.barAmount)
			:fillColor(color.lightBlue)
		:new 'rectangle'
			:name 'progressBar'
			:right(barRight):bottom(barBottom)
			:size(64, constant.boardHeight * board.scale)
			:outlineColor(color.white)
			:outlineWidth(8)
		:new 'transform'
			:beginChildren()
				:new('text', font.hud, ('%i'):format(self.rollingScore))
			:endChildren()
			:angle(-math.pi/2)
			:right(layout:get('progressBar', 'left') - 32)
			:centerY(layout:get('progressBar', 'centerY'))
end

function timeAttack:drawIntro()
	local layout = self.pool.data.layout
	layout
		:new('text', font.hud, ('score %i points!'):format(self.goalScore))
			:centerX(constant.screenWidth / 2)
			:centerY(constant.screenHeight / 4)
			:scale(2/3)
			:color(color.withAlpha(color.white, self.goalTextAlpha))
			:shadowColor(color.withAlpha(color.maroon, self.goalTextAlpha))
			:shadowOffset(4, 4)
		:new('text', font.hud, 'ready')
			:centerX(constant.screenWidth / 2)
			:centerY(constant.screenHeight / 2)
			:scale(self.readyTextScale * 1.5)
			:color(color.withAlpha(color.white, self.readyTextAlpha))
			:shadowColor(color.withAlpha(color.maroon, self.readyTextAlpha))
			:shadowOffset(4, 4)
		:new('text', font.hud, 'go!')
			:centerX(constant.screenWidth / 2)
			:centerY(constant.screenHeight / 2)
			:scale(self.goTextScale * 1.5)
			:color(color.withAlpha(color.white, self.goTextAlpha))
			:shadowColor(color.withAlpha(color.maroon, self.goTextAlpha))
			:shadowOffset(4, 4)
end

function timeAttack:drawResults()
	local layout = self.pool.data.layout
	layout
		:new('text', font.hud, 'press r to restart')
			:centerX(constant.screenWidth / 2)
			:centerY(constant.screenHeight * .75)
			:scale(2/3)
			:color(color.withAlpha(color.white, self.restartTextAlpha))
			:shadowColor(color.withAlpha(color.maroon, self.restartTextAlpha))
			:shadowOffset(4, 4)
		:new('text', font.hud, 'time!')
			:centerX(constant.screenWidth / 2)
			:centerY(constant.screenHeight / 2)
			:scale(self.finishTextScale * 1.5)
			:color(color.withAlpha(color.white, self.finishTextAlpha))
			:shadowColor(color.withAlpha(color.maroon, self.finishTextAlpha))
			:shadowOffset(4, 4)
end

function timeAttack:draw()
	self:drawScore()
	self:drawSquaresCounter()
	self:drawChainCounter()
	self.pool.data.layout
		:new('rectangle', -100000, -100000, 200000, 200000)
			:fillColor(0, 0, 0, self.screenDimAlpha)
	self:drawTime()
	self:drawIntro()
	self:drawResults()
end

return timeAttack
