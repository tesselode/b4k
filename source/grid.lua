local Object = require 'lib.classic'
local util = require 'util'

local Grid = Object:extend()

function Grid:new(width, height)
	self._width = width
	self._height = height
	self._items = {}
	for x = 0, width - 1 do
		self._items[x] = {}
	end
end

function Grid:get(x, y)
	if not self._items[x] then return end
	return self._items[x][y]
end

function Grid:set(x, y, item)
	if x < 0 or x >= self._width or y < 0 or y >= self._height then
		error(('Cannot set an item out of bounds (setting at position (%i, %i), grid size is (%i, %i), grids are 0-indexed)')
			:format(x, y, self._width, self._height))
	end
	self._items[x][y] = item
end

function Grid:_iter(index)
	while true do
		index = index + 1
		if index > self._width * self._height - 1 then
			return
		end
		local x, y = util.indexToCoordinates(index, self._width)
		local item = self:get(x, y)
		if item then return index, x, y, item end
	end
end

function Grid:items()
	return self._iter, self, -1
end

return Grid
