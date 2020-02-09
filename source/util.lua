local util = {}

-- math
function util.clamp(x, min, max)
	return x < min and min or x > max and max or x
end

function util.lerp(a, b, amount)
	return a + (b - a) * amount
end

function util.coordinatesToIndex(width, x, y)
	return y * width + x
end

function util.indexToCoordinates(width, index)
	return index % width, math.floor(index / width)
end

-- strings
function util.pad(text, padCharacter, numberOfCharacters)
	text = tostring(text)
	return string.rep(padCharacter, numberOfCharacters - #text) .. text
end

-- tables
function util.clear(t)
	for k in pairs(t) do t[k] = nil end
end

-- functions
function util.bind(f, argument)
	return function(...) f(argument, ...) end
end

return util
