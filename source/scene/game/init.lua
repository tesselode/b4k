local Board = require 'scene.game.entity.board'
local Object = require 'lib.classic'
local nata = require 'lib.nata'

local function shouldRemove(e) return e.removeFromPool end

local Game = Object:extend()

function Game:enter()
	self.pool = nata.new({
		groups = {
			board = {filter = function(e) return e:is(Board) end},
		},
		systems = {
			require 'scene.game.system.timer',
			require 'scene.game.system.layout',
			require 'scene.game.system.square-highlights',
			require 'scene.game.system.game-rules.puzzle',
			nata.oop(),
		},
	}, '3')
end

function Game:update(dt)
	self.pool:flush()
	self.pool:emit('update', dt)
	self.pool:remove(shouldRemove)
end

function Game:mousemoved(x, y, dx, dy, istouch)
	self.pool:emit('mousemoved', x, y, dx, dy, istouch)
end

function Game:mousepressed(x, y, button, istouch, presses)
	self.pool:emit('mousepressed', x, y, button, istouch, presses)
end

function Game:draw()
	self.pool:emit 'draw'
	self.pool:emit 'drawTop'
end

return Game
