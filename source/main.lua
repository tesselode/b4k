local Game = require 'scene.game'
local sceneManager = require 'scene-manager'

function love.load()
	sceneManager:hook()
	sceneManager:enter(Game)
end

function love.keypressed(key)
	if key == 'escape' then love.event.quit() end
end

function love.draw()
	love.graphics.print(('Memory usage: %ikb'):format(collectgarbage 'count'))
end
