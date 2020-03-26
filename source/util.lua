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

function util.bind(f, argument)
	return function(...) f(argument, ...) end
end

function util.getNumLinesInString(s)
	local _, newlines = s:gsub('\n', '\n')
	return newlines + 1
end

function util.getTextHeight(font, text)
	return font:getHeight() * font:getLineHeight() * util.getNumLinesInString(text)
end

return util
