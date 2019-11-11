local Board = require 'class.game.board'
local Object = require 'lib.classic'
local nata = require 'lib.nata'
local Tile = require 'class.game.tile'

local function shouldRemove(e) return e.removeFromPool end

local Game = Object:extend()

function Game:enter()
	self.pool = nata.new {
		groups = {
			tile = {filter = function(e) return e:is(Tile) end},
		},
		systems = {
			require 'system.timer',
			require 'system.ui',
			nata.oop(),
		},
	}
	self.pool:queue(Board(self.pool))
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
	self.pool:emit 'beforeDraw'
	self.pool:emit 'draw'
	self.pool:emit 'afterDraw'
end

return Game
