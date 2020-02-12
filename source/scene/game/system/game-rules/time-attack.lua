local basicGameRules = require 'scene.game.system.game-rules'
local color = require 'color'
local constant = require 'constant'
local font = require 'font'
local util = require 'util'

local timeAttack = setmetatable({}, {__index = basicGameRules})

function timeAttack:init()
	basicGameRules.init(self)
	self.time = 0
end

function timeAttack:update(dt)
	self.time = self.time + dt
	self.score = self.score + 1
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
	local progressBarRight, progressBarBottom = board.transform:transformPoint(-1/4, constant.boardHeight)
	local textRight, textCenterY = board.transform:transformPoint(-1/2, constant.boardHeight/2)
	layout
		:new 'rectangle'
			:right(progressBarRight):bottom(progressBarBottom)
			:size(64, constant.boardHeight * board.scale)
			:outlineColor(color.white)
			:outlineWidth(8)

end

function timeAttack:draw()
	self:drawTime()
	self:drawScore()
	self:drawSquaresCounter()
	self:drawChainCounter()
end

return timeAttack
