local flux = require 'lib.flux'

local timer = {}

function timer:init()
	self.pool.data.tweens = flux.group()
end

function timer:update(dt)
	self.pool.data.tweens:update(dt)
end

return timer
