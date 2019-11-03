local constant = require 'constant'
local stateManager = require 'state-manager'

love.graphics.setFont(love.graphics.newFont(64))

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
	stateManager:hook {exclude = {'draw'}}
	stateManager:enter(require 'state.game'())
end

function love.keypressed(key)
	if key == 'escape' then
		love.event.quit()
	end
end

function love.resize(w, h)
	initMainTransform()
end

function love.draw()
	love.graphics.push 'all'
	love.graphics.applyTransform(mainTransform)
	stateManager:emit 'draw'
	love.graphics.pop()
end
