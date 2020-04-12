local Board = require 'scene.game.entity.board'
local nata = require 'lib.nata'
local Object = require 'lib.classic'

local function shouldRemove(e) return e.removeFromPool end

local Game = Object:extend()

function Game:getRulesSystem(mode)
	if mode == 'timeAttack' then
		return require 'scene.game.system.rules.time-attack'
	elseif mode == 'puzzle' then
		return require 'scene.game.system.rules.puzzle'
	else
		error('no mode called "' .. mode .. '"')
	end
end

function Game:enter(previous, mode, ...)
	assert(mode, 'no game mode argument provided')
	self.pool = nata.new({
		groups = {
			board = {filter = function(e) return e:is(Board) end}
		},
		systems = {
			require 'scene.game.system.timer',
			self:getRulesSystem(mode),
			require 'scene.game.system.background',
			nata.oop(),
			require 'scene.game.system.ui',
		},
	}, ...)
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
