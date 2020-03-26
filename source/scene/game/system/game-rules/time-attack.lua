local timeAttack = {}

function timeAttack:init()
	self.score = 0
	self.chain = 1
	self.justClearedTiles = false
	self.time = 0
end

function timeAttack:onClearTiles(squares, tiles)
	local scoreIncrement = 0
	for i = 1, squares:count() do
		scoreIncrement = scoreIncrement + i
	end
	scoreIncrement = scoreIncrement * self.chain
	self.score = self.score + scoreIncrement
	self.justClearedTiles = true
end

function timeAttack:onCheckSquares(squares)
	if squares:count() > 0 then
		if self.justClearedTiles then
			self.chain = self.chain + 1
		end
	else
		self.chain = 1
	end
	self.justClearedTiles = false
end

function timeAttack:update(dt)
	self.time = self.time + dt
end

function timeAttack:draw()
	love.graphics.print(self.score .. '\n' .. self.chain .. '\n' .. self.time, 0, 16)
end

return timeAttack
