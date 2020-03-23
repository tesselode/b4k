local Object = require 'lib.classic'

local Game = Object:extend()

function Game:draw()
	love.graphics.print 'hi!'
end

return Game
