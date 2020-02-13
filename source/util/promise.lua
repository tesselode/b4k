local Object = require 'lib.classic'

local Promise = Object:extend()

function Promise:new(f)
	self._onFinish = {}
	f(function(...) self:_finish(...) end)
end

function Promise:_finish(...)
	for _, f in ipairs(self._onFinish) do
		f(...)
	end
end

function Promise:after(f)
	table.insert(self._onFinish, f)
	return self
end

function Promise.all(promises)
	return Promise(function(finish)
		local finished = {}
		for _, promise in ipairs(promises) do
			finished[promise] = false
			promise:after(function()
				-- mark this child promise as finished
				finished[promise] = true
				-- if all child promises are finished...
				for _, v in pairs(finished) do
					if v == false then return end
				end
				-- finish the parent promise
				finish()
			end)
		end
	end)
end

return Promise