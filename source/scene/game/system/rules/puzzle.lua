local Board = require 'scene.game.entity.board'
local cartographer = require 'lib.cartographer'
local charm = require 'lib.charm'
local color = require 'color'
local constant = require 'constant'
local font = require 'font'
local rules = require 'scene.game.system.rules'
local Tile = require 'scene.game.entity.board.tile'

local MovesSquare = charm.extend('MovesSquare', 'element')

function MovesSquare:angle(angle)
	self._angle = angle
end

function MovesSquare:drawBottom()
	love.graphics.push 'all'
	local width, height = self:get 'size'
	love.graphics.translate(width/2, height/2)
	love.graphics.rotate(self._angle or 0)
	love.graphics.setLineWidth(8)
	love.graphics.rectangle('line', -width/2, -height/2, width, height)
	love.graphics.pop()
end

local puzzle = setmetatable({
	showScorePopups = false,
	showChainPopups = false,
}, {__index = rules})

function puzzle:initBoard(puzzleName)
	self.board = self.pool:queue(Board(self.pool, {replenishTiles = false}))
	self.map = cartographer.load('puzzle/' .. puzzleName .. '.lua')
	self.moves = self.map.properties.moves
	for _, gid, x, y in self.map.layers.tiles:getTiles() do
		self.board:spawnTile(x, y, self.map:getTileProperty(gid, 'color'))
	end
	self.board:checkSquares()
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

function puzzle:drawMovesCount()
	if not self.moves then return end
	local left, top = self.board.transform:transformPoint(0, self.board.height + 1/4)
	self.pool.data.ui
		:new(MovesSquare)
			:angle(self.movesSquareAngle)
			:beginChildren()
				:new('text', font.hud, self.moves)
					:left(left):top(top)
					:scale(1 / constant.fontScale)
					:color(color.white)
			:endChildren()
			:wrap()
			:origin(.5, .5)
			:pad(8)
			:width(self.pool.data.ui:get('@current', 'height'))
			:left(left)
			:alignChildren(.5, .5)
			:shiftChildren(12, -8)
end

function puzzle:draw()
	self:drawMovesCount()
end

return puzzle
