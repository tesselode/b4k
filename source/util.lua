local constant = require 'constant'
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

--[[
	text drawing
	------------
	the global font scale (constant.fontScale) gives some wiggle room for scaling
	fonts above 1.0x without causing blurriness at the target 4k resolution

	getTextSize gets the width and height of a piece of text printed with
	a certain font, keeping in mind the global font scale

	util.print and util.printf are the same as the love.graphics counterparts,
	except for the following changes:
	- text is automatically scaled according to the global font scale
	- logs a warning if the final scale exceeds 1.0x
	- ox and oy are in terms of the width and height of the text,
	  rather than pixels
]]
function util.getTextSize(font, text, limit)
	if limit then
		local _, lines = font:getWrap(text, limit)
		return limit / constant.fontScale, font:getHeight() * font:getLineHeight() * #lines / constant.fontScale
	end
	return font:getWidth(text) / constant.fontScale,
		font:getHeight() * font:getLineHeight() * util.getNumLinesInString(text) / constant.fontScale
end

function util.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
	text = tostring(text)
	sx = (sx or 1) / constant.fontScale
	sy = (sy or sx) / constant.fontScale
	if sx > 1 or sy > 1 then
		log.warn(debug.traceback(('Drawing text with a scale of (%f, %f), which is greater than 1. '
			.. 'This can lead to blurry fonts at higher screen resolutions.'):format(sx, sy), 2))
	end
	local font = love.graphics.getFont()
	local width, height = util.getTextSize(font, text)
	love.graphics.print(text, x, y, r, sx, sy, ox * width * constant.fontScale, oy * height * constant.fontScale, kx, ky)
end

function util.printf(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
	text = tostring(text)
	sx = (sx or 1) / constant.fontScale
	sy = (sy or sx) / constant.fontScale
	if sx > 1 or sy > 1 then
		log.warn(debug.traceback(('Drawing text with a scale of (%f, %f), which is greater than 1. '
			.. 'This can lead to blurry fonts at higher screen resolutions.'):format(sx, sy), 2))
	end
	local font = love.graphics.getFont()
	local width, height = util.getTextSize(font, text, limit)
	love.graphics.printf(text, x, y, limit, align, r, sx, sy, ox * width * constant.fontScale,
		oy * height * constant.fontScale, kx, ky)
end

return util
