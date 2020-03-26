local TimeAttack = require 'scene.game.time-attack'
local sceneManager = require 'scene-manager'

function love.load()
	sceneManager:hook()
	sceneManager:enter(TimeAttack)
end

function love.keypressed(key)
	if key == 'escape' then love.event.quit() end
end

function love.draw()
	love.graphics.print(('Memory usage: %ikb'):format(collectgarbage 'count'))
end
