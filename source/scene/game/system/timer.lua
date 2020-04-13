local flux = require 'lib.flux'
local tick = require 'lib.tick'

local timer = {}

function timer:init()
	self.pool.data.timers = tick.group()
	self.pool.data.tweens = flux.group()
end

function timer:update(dt)
	self.pool.data.timers:update(dt)
	self.pool.data.tweens:update(dt)
end

return timer
