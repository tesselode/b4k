local constant = require 'constant'
local Game = require 'scene.game'
local sceneManager = require 'scene-manager'

local debugFont = love.graphics.newFont(48)
local mainTransform = love.math.newTransform()

local function initMainTransform()
	mainTransform:reset()
	local scale = math.min(love.graphics.getWidth() / constant.screenWidth,
		love.graphics.getHeight() / constant.screenHeight)
	mainTransform:setTransformation(
		love.graphics.getWidth() / 2, love.graphics.getHeight() / 2,
		0,
		scale, scale,
		constant.screenWidth / 2, constant.screenHeight / 2
	)
end

initMainTransform()

function love.load()
	sceneManager:hook {
		exclude = {
			'mousemoved',
			'mousepressed',
			'mousereleased',
			'draw',
		},
	}
	sceneManager:enter(Game, {mode = 'timeAttack'})
end

function love.keypressed(key)
	if key == 'escape' then love.event.quit() end
end

function love.mousemoved(x, y, dx, dy, istouch)
	x, y = mainTransform:inverseTransformPoint(x, y)
	sceneManager:emit('mousemoved', x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch, presses)
	x, y = mainTransform:inverseTransformPoint(x, y)
	sceneManager:emit('mousepressed', x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	x, y = mainTransform:inverseTransformPoint(x, y)
	sceneManager:emit('mousereleased', x, y, button, istouch, presses)
end

function love.resize(w, h)
	initMainTransform()
end

function love.draw()
	love.graphics.push 'all'
	love.graphics.applyTransform(mainTransform)
	love.graphics.setFont(debugFont)
	sceneManager:emit 'draw'
	love.graphics.pop()

	love.graphics.print(('Memory usage: %ikb'):format(collectgarbage 'count'))
end
