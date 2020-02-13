local Promise = require 'util.promise'
local tick = require 'lib.tick'

local promiseTest = {}

function promiseTest:enter()
	local promises = {}
	for _ = 1, 5 do
		table.insert(promises, Promise(function(finish)
			local delay = love.math.random() * 3
			tick.delay(function()
				finish(delay)
			end, delay)
		end)
			:after(function(...) print(...) end)
			:after(function(...) print 'hi!' end)
		)
	end
	Promise.all(promises)
		:after(function() print 'all timers finished' end)
end

function promiseTest:update(dt)
	tick.update(dt)
end

return promiseTest
