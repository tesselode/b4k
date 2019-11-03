local constant = require 'constant'
local stateManager = require 'state-manager'

love.graphics.setFont(love.graphics.newFont(64))

function love.load()
	stateManager:hook {exclude = {'draw'}}
	stateManager:enter(require 'state.game'())
end

function love.keypressed(key)
	if key == 'escape' then
		love.event.quit()
	end
end

function love.draw()
	love.graphics.push 'all'
	local scale = math.min(love.graphics.getWidth() / constant.screenWidth,
		love.graphics.getHeight() / constant.screenHeight)
	love.graphics.scale(scale)
	stateManager:emit 'draw'
	love.graphics.pop()
end
