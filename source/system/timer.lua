local keeper = require 'lib.keeper'

local timer = {}

function timer:init()
	self.pool.data.timers = keeper.new()
end

function timer:update(dt)
	self.pool.data.timers:update(dt)
end

return timer
