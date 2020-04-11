local Bloom = require 'shader.bloom'
local constant = require 'constant'
local Game = require 'scene.game'
local sceneManager = require 'scene-manager'

local debugFont = love.graphics.newFont(48)
local mainTransform = love.math.newTransform()
local bloom = Bloom()

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

local function parseCommandLineArguments(rawArguments)
	local arguments = {[''] = {}}
	local currentFlag = ''
	for _, argument in ipairs(rawArguments) do
		if argument:sub(1, 2) == '--' then
			local flag = argument:sub(3, -1)
			currentFlag = flag
			arguments[flag] = {}
		else
			table.insert(arguments[currentFlag], argument)
		end
	end
	return arguments
end

function love.load(arguments)
	arguments = parseCommandLineArguments(arguments)
	sceneManager:hook {
		exclude = {
			'mousemoved',
			'mousepressed',
			'mousereleased',
			'draw',
		},
	}
	sceneManager:enter(Game, unpack(arguments['']))
end

function love.keypressed(key)
	if key == 'escape' then love.event.quit() end
	if key == 'r' and love.keyboard.isDown 'lctrl' then
		love.event.quit 'restart'
	end
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
	bloom:resize()
end

function love.draw()
	bloom:start()
	love.graphics.push 'all'
	love.graphics.applyTransform(mainTransform)
	love.graphics.setFont(debugFont)
	sceneManager:emit 'draw'
	love.graphics.pop()
	bloom:finish()

	love.graphics.print(('Memory usage: %ikb'):format(collectgarbage 'count'))
	love.graphics.print(('FPS: %ikb'):format(love.timer.getFPS()), 0, 16)
end
