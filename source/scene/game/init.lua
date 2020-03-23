local Board = require 'scene.game.board'
local Object = require 'lib.classic'

local Game = Object:extend()

function Game:enter()
	self.board = Board()
end

function Game:mousemoved(x, y, dx, dy, isTouch)
	self.board:mousemoved(x, y, dx, dy, isTouch)
end

function Game:mousepressed(x, y, button, isTouch, presses)
	self.board:mousepressed(x, y, button, isTouch, presses)
end

function Game:draw()
	self.board:draw()
end

return Game
