local Corridor = require 'background.corridor'

local background = {}

function background:init()
	self.background = Corridor()
end

function background:update(dt)
	self.background:update(dt)
end

function background:draw()
	self.background:draw()
end

return background
