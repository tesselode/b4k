local util = {}

-- math
function util.clamp(x, min, max)
	return x < min and min or x > max and max or x
end

function util.coordinatesToIndex(x, y, width)
	return x + width * y
end

function util.indexToCoordinates(index, width)
	return index % width, math.floor(index / width)
end

-- functions
function util.bind(f, argument)
	return function(...) f(argument, ...) end
end

-- strings
function util.pad(text, padCharacter, numberOfCharacters)
	text = tostring(text)
	return string.rep(padCharacter, numberOfCharacters - #text) .. text
end

function util.formatTime(time)
	local decimal = time % 1
	local seconds = math.floor(time % 60)
	local minutes = math.floor((time / 60) % 60)
	local hours = math.floor(time / 60 / 60)
	local decimalString = ('%.2f'):format(decimal):sub(3, -1)
	if hours > 0 then
		return hours .. ':'
			.. util.pad(minutes, 0, 2) .. ':'
			.. util.pad(seconds, 0, 2) .. '.'
			.. decimalString
	elseif minutes > 0 then
		return minutes .. ':'
			.. util.pad(seconds, 0, 2) .. '.'
			.. decimalString
	else
		return seconds .. '.' .. decimalString
	end
end

function util.getNumLinesInString(s)
	local _, newlines = s:gsub('\n', '\n')
	return newlines + 1
end

function util.getTextHeight(font, text)
	return font:getHeight() * font:getLineHeight() * util.getNumLinesInString(text)
end

return util
