local Board = require 'scene.game.board'
local Object = require 'lib.classic'

local Game = Object:extend()

function Game:enter()
	self.board = Board()
end

function Game:draw()
	self.board:draw()
end

return Game
