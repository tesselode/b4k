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

-- tables
function util.clear(t)
	for k in pairs(t) do t[k] = nil end
end

-- functions
function util.bind(f, argument)
	return function(...) f(argument, ...) end
end

-- async
function util.async(f)
	local co
	local function await(promise)
		promise:after(function() coroutine.resume(co) end)
		coroutine.yield()
	end
	co = coroutine.create(function() f(await) end)
	coroutine.resume(co)
	return co
end

return util
