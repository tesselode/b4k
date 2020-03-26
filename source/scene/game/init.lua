local Board = require 'scene.game.entity.board'
local nata = require 'lib.nata'
local Object = require 'lib.classic'
local SquareHighlight = require 'scene.game.entity.square-highlight'

local function shouldRemove(e) return e.removeFromPool end

local Game = Object:extend()

function Game:getRulesSystem(options)
	if options.mode == 'timeAttack' then
		return require 'scene.game.system.rules.time-attack'
	end
end

function Game:enter(previous, options)
	self.pool = nata.new {
		data = {options = options},
		systems = {
			require 'scene.game.system.timer',
			self:getRulesSystem(options),
			nata.oop(),
		},
	}
	local board = Board(self.pool)
	for x = 0, board.width - 2 do
		for y = 0, board.height - 2 do
			self.pool:queue(SquareHighlight(self.pool, x, y))
		end
	end
	self.pool:flush()
	self.pool:queue(board)
	self.pool:flush()
end

function Game:update(dt)
	self.pool:flush()
	self.pool:emit('update', dt)
	self.pool:remove(shouldRemove)
end

function Game:mousemoved(x, y, dx, dy, isTouch)
	self.pool:emit('mousemoved', x, y, dx, dy, isTouch)
end

function Game:mousepressed(x, y, button, isTouch, presses)
	self.pool:emit('mousepressed', x, y, button, isTouch, presses)
end

function Game:draw()
	self.pool:emit 'draw'
end

return Game
