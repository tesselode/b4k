local image = require 'image'

local tileSize = 500

return {
	tile = {
		regular = {
			love.graphics.newQuad(0, 0, tileSize, tileSize, image.tiles:getDimensions()),
			love.graphics.newQuad(tileSize, 0, tileSize, tileSize, image.tiles:getDimensions()),
			love.graphics.newQuad(tileSize * 2, 0, tileSize, tileSize, image.tiles:getDimensions()),
			love.graphics.newQuad(tileSize * 3, 0, tileSize, tileSize, image.tiles:getDimensions()),
		},
		inert = love.graphics.newQuad(tileSize * 4, 0, tileSize, tileSize, image.tiles:getDimensions()),
	}
}
