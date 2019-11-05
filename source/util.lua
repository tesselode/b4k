local util = {}

function util.clamp(x, min, max)
	return x < min and min or x > max and max or x
end

function util.clear(t)
	for k in pairs(t) do t[k] = nil end
end

function util.copy(t1, t2)
	for k, v in pairs(t1) do t2[k] = v end
end

function util.coordinatesToIndex(width, x, y)
	return y * width + x
end

function util.indexToCoordinates(width, index)
	return index % width, math.floor(index / width)
end

return util
