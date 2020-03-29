local log = require 'lib.log'

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

-- drawing
function util.printf(text, x, y, limit, halign, valign, r, sx, sy, kx, ky)
	sx = sx or 1
	sy = sy or sx
	if sx > 1 or sy > 1 then
		log.warn(debug.traceback(('Drawing text with a scale of (%f, %f), which is greater than 1. '
			.. 'This can lead to blurry fonts at higher screen resolutions.'):format(sx, sy), 2))
	end
	local font = love.graphics.getFont()
	local _, lines = font:getWrap(text, limit)
	local height = font:getHeight() * font:getLineHeight() * #lines
	local ox = halign == 'left' and 0
		or halign == 'center' and limit/2
		or halign == 'right' and limit
	local oy = valign == 'top' and 0
		or valign == 'middle' and height/2
		or valign == 'bottom' and height
	love.graphics.printf(text, x, y, limit, halign, r, sx, sy, ox, oy, kx, ky)
end

return util
