local Game = require 'scene.game'
local Grid = require 'grid'
local sceneManager = require 'scene-manager'

local grid = Grid(4, 4)
grid:set(3, 1, "hi!")
grid:set(2, 3, "hello!")
for i, x, y, item in grid:items() do
	print(i, x, y, item)
end

function love.load()
	sceneManager:hook()
	sceneManager:enter(Game)
end

function love.keypressed(key)
	if key == 'escape' then love.event.quit() end
end
