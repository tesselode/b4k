local constant = require 'constant'
local stateManager = require 'state-manager'

local debugFont = love.graphics.newFont(64)

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
	stateManager:hook {
		exclude = {
			'mousemoved',
			'mousepressed',
			'mousereleased',
			'draw',
		},
	}
	stateManager:enter(require 'scene.promise-test')
end

function love.keypressed(key)
	if key == 'escape' then
		love.event.quit()
	elseif key == 'r' then
		love.event.quit 'restart'
	end
end

function love.mousemoved(x, y, dx, dy, istouch)
	x, y = mainTransform:inverseTransformPoint(x, y)
	stateManager:emit('mousemoved', x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch, presses)
	x, y = mainTransform:inverseTransformPoint(x, y)
	stateManager:emit('mousepressed', x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	x, y = mainTransform:inverseTransformPoint(x, y)
	stateManager:emit('mousereleased', x, y, button, istouch, presses)
end

function love.resize(w, h)
	initMainTransform()
end

function love.draw()
	love.graphics.push 'all'
	love.graphics.setFont(debugFont)
	love.graphics.applyTransform(mainTransform)
	stateManager:emit 'draw'
	love.graphics.pop()

	love.graphics.print(string.format('Memory usage: %ikb', collectgarbage 'count'))
end
