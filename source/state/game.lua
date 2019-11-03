local Board = require 'class.game.board'
local constant = require 'constant'
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
	}
	self.pool:queue(Board(self.pool))
end

function Game:update(dt)
	self.pool:flush()
	self.pool:emit('update', dt)
	self.pool:remove(shouldRemove)
end

function Game:resize(w, h)
	self.pool:emit('resize', w, h)
end

function Game:draw()
	self.pool:emit 'draw'
	love.graphics.push 'all'
	love.graphics.setLineWidth(64)
	love.graphics.rectangle('line', 0, 0, constant.screenWidth, constant.screenHeight)
	love.graphics.pop()
end

return Game
