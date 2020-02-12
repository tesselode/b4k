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
end

function timeAttack:updateProgressBar(dt)
	local barAmountIncrement = (self.score / self.goalScore - self.barAmount) * 10
	barAmountIncrement = math.min(barAmountIncrement, 1.5)
	self.barAmount = self.barAmount + barAmountIncrement * dt
	self.barAmount = util.clamp(self.barAmount, 0, 1)
end

function timeAttack:update(dt)
	self.time = self.time + dt
	self:updateProgressBar(dt)
	basicGameRules.update(self, dt)
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

function timeAttack:draw()
	self:drawTime()
	self:drawScore()
	self:drawSquaresCounter()
	self:drawChainCounter()
end

return timeAttack
