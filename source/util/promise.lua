local Object = require 'lib.classic'

local Promise = Object:extend()

function Promise:new(f)
	self._onFinish = {}
	self._finished = false
	if f then
		f(function(...) self:finish(...) end)
	end
end

function Promise:isFinished()
	return self._finished
end

function Promise:finish(...)
	for _, f in ipairs(self._onFinish) do
		f(...)
	end
	self._finished = true
end

function Promise:after(f)
	table.insert(self._onFinish, f)
	return self
end

function Promise.all(promises)
	return Promise(function(finish)
		if #promises < 1 then
			finish()
			return
		end
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
