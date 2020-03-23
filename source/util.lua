local util = {}

function util.clamp(x, min, max)
	return x < min and min or x > max and max or x
end

function util.coordinatesToIndex(x, y, width)
	return x + width * y
end

function util.indexToCoordinates(index, width)
	return index % width, math.floor(index / width)
end

return util
