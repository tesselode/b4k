local basicGameRules = require 'scene.game.system.game-rules'
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

function timeAttack:draw()
	self:drawTime()
	self:drawSquaresCounter()
	self:drawChainCounter()
end

return timeAttack
