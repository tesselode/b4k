local Board = require 'scene.game.entity.board'
local cartographer = require 'lib.cartographer'
local color = require 'color'
local font = require 'font'
local rules = require 'scene.game.system.rules'
local Tile = require 'scene.game.entity.board.tile'
local util = require 'util'

local puzzle = setmetatable({
	showScorePopups = false,
	showChainPopups = false,
}, {__index = rules})

function puzzle:initBoard(puzzleName)
	self.board = self.pool:queue(Board(self.pool, {replenishTiles = false}))
	self.puzzle = cartographer.load('puzzle/' .. puzzleName .. '.lua')
	self.moves = self.puzzle.properties.moves
	for _, gid, x, y in self.puzzle.layers.tiles:getTiles() do
		self.board:spawnTile(x, y, gid)
	end
end

function puzzle:init(...)
	rules.init(self, ...)

	-- cosmetic
	self.movesSquareAngle = 0
	self.movesSquareRotationTween = nil
end

function puzzle:onRotate(counterClockwise)
	if not self.moves then return end
	self.moves = self.moves - 1
	if self.moves < 1 then
		self.board.acceptInput = false
	end

	-- play moves square animation
	if self.movesSquareRotationTween then
		self.movesSquareRotationTween:stop()
	end
	self.movesSquareAngle = 0
	self.pool.data.tweens:to(self, Tile.rotationAnimationDuration, {
		movesSquareAngle = counterClockwise and -math.pi/2 or math.pi/2,
	})
		:ease 'backout'
end

function puzzle:drawMovesSquare(size)
	love.graphics.push 'all'
	love.graphics.rotate(self.movesSquareAngle)
	love.graphics.setLineWidth(8)
	love.graphics.rectangle('line', -size/2, -size/2, size, size)
	love.graphics.pop()
end

function puzzle:drawMovesCount()
	if not self.moves then return end
	local left, top = self.board.transform:transformPoint(0, self.board.height + 1/4)
	local text = tostring(self.moves)
	local _, height = util.getTextSize(font.hud, text)
	local squareSize = height + 16
	love.graphics.push 'all'
	love.graphics.translate(left + squareSize/2, top + height/2)
	love.graphics.setColor(color.white)
	self:drawMovesSquare(squareSize)
	love.graphics.setFont(font.hud)
	util.print(text, 12, -8, 0, 1, 1, .5, .5)
	love.graphics.pop()
end

function puzzle:draw()
	self:drawMovesCount()
end

return puzzle
