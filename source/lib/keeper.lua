local keeper = {}

-- for lua 5.2+ compatibility
local unpack = unpack or table.unpack -- luacheck: ignore

local function clamp(x, min, max)
	return x < min and min or x > max and max or x
end

local function lerp(a, b, amount)
	return a + (b - a) * amount
end

keeper.ease = {}

function keeper.ease.linear(p) return p end

function keeper.ease.power(p, power)
	power = power or 2
	return p ^ power
end

-- the following easing functions comes from vrld's hump-timer
-- https://github.com/vrld/hump/blob/master/timer.lua#L123
function keeper.ease.back(p, bounciness)
	bounciness = bounciness or 1.70158
	return p*p*((bounciness+1)*p - bounciness)
end

function keeper.ease.bounce(p)
	local a, b = 7.5625, 1/2.75
	return math.min(a*p^2, a*(p-1.5*b)^2 + .75, a*(p-2.25*b)^2 + .9375, a*(p-2.625*b)^2 + .984375)
end

function keeper.ease.elastic(p, amp, period)
	amp, period = amp and math.max(1, amp) or 1, period or .3
	return (-amp * math.sin(2*math.pi/period * (p-1) - math.asin(1/amp))) * 2^(10*(p-1))
end

local Timer, FlipTimer, RepeatingTimer, Tween
local newTimer, newFlipTimer, newRepeatingTimer, newTween

Timer = {}

function newTimer(time, f, ...)
	return setmetatable({
		_time = time,
		speed = 1,
		_f = f,
		_arguments = {...},
		_after = {},
		_status = 'idle',
	}, Timer)
end

function Timer:__index(k)
	if k == 'time' then
		return self._time
	end
	return Timer[k]
end

function Timer:__newindex(k, v)
	if k == 'time' then
		self:setTime(v)
	end
	rawset(self, k, v)
end

function Timer:_onComplete()
	if self._f then
		self._f(unpack(self._arguments))
	end
end

function Timer:setTime(time)
	self._time = time
	if self._time <= 0 then
		self:_onComplete()
		--[[
			Add the current time (a negative number) to the time
			of any chained timers. This is important because timers
			will always end a little bit late - the frame after
			the exact point in time they're supposed to end.
			The next timer should run a little faster to compensate.
			Adding this timer's time to the next one accounts
			for the extra time this one took.
		]]
		for _, timer in ipairs(self._after) do
			timer._time = timer._time + self._time
		end
		self._status = 'completed'
	end
	return self
end

function Timer:_update(dt)
	if self:isFinished() then return end
	self:setTime(self._time - self.speed * dt)
end

function Timer:getStatus()
	return self._status
end

function Timer:isFinished()
	local status = self:getStatus()
	return status == 'completed' or status == 'cancelled'
end

function Timer:cancel()
	self._status = 'cancelled'
end

function Timer:after(...)
	local timer = newTimer(...)
	table.insert(self._after, timer)
	return timer
end

function Timer:flip(...)
	local timer = newFlipTimer(...)
	table.insert(self._after, timer)
	return timer
end

function Timer:every(...)
	local timer = newRepeatingTimer(...)
	table.insert(self._after, timer)
	return timer
end

function Timer:tween(...)
	local timer = newTween(...)
	table.insert(self._after, timer)
	return timer
end

FlipTimer = setmetatable({}, Timer)

function newFlipTimer(time, object, key, value)
	local timer = newTimer(time)
	timer.object = object
	timer.key = key
	timer.value = value
	timer._started = false
	setmetatable(timer, FlipTimer)
	return timer
end

function FlipTimer:__index(k)
	if FlipTimer[k] then return FlipTimer[k] end
	return Timer.__index(self, k)
end

FlipTimer.__newindex = Timer.__newindex

function FlipTimer:_onComplete()
	self.object[self.key] = self._previousValue
end

function FlipTimer:_update(dt)
	if not self._started then
		self._started = true
		self._previousValue = self.object[self.key]
		if self.value == nil then
			self.object[self.key] = not self.object[self.key]
		else
			self.object[self.key] = self.value
		end
	end
	Timer._update(self, dt)
end

RepeatingTimer = setmetatable({}, Timer)

function newRepeatingTimer(interval, f, ...)
	local timer = newTimer(interval, f, ...)
	timer._interval = interval
	setmetatable(timer, RepeatingTimer)
	return timer
end

function RepeatingTimer:__index(k)
	if k == 'count' then
		return self._count
	end
	if RepeatingTimer[k] then return RepeatingTimer[k] end
	return Timer.__index(self, k)
end

function RepeatingTimer:__newindex(k, v)
	if k == 'count' then
		self:setCount(v)
	else
		Timer.__newindex(self, k, v)
	end
end

function RepeatingTimer:setCount(count)
	self._count = count
	if self._count <= 0 then
		self._status = 'completed'
	end
	return self
end

function RepeatingTimer:_update(dt)
	if self:isFinished() then return end
	self._time = self._time - dt
	while self._time <= 0 do
		if self._f then
			if self._f(unpack(self._arguments)) then
				self._status = 'completed'
			end
		end
		--[[
			Similarly to chained timers, a repeating timer should
			account for its error when starting the next cycle.
			That's why I'm adding the interval to the current time
			instead of just setting the time to the interval.
		]]
		self._time = self._time + self._interval
		if self._count then
			self:setCount(self._count - 1)
		end
	end
end

function RepeatingTimer:after()
	error('cannot chain a timer to a repeating timer', 2)
end

RepeatingTimer.every = RepeatingTimer.after
RepeatingTimer.tween = RepeatingTimer.after

Tween = setmetatable({}, Timer)

function newTween(time, object, targets)
	local tween = newTimer(time)
	tween._duration = time
	tween._object = object
	tween._targets = targets
	tween._easingFunction = keeper.ease.linear
	tween._easingMode = 'in'
	setmetatable(tween, Tween)
	return tween
end

function Tween:__index(k)
	if Tween[k] then return Tween[k] end
	return Timer.__index(self, k)
end

Tween.__newindex = Timer.__newindex

function Tween:_setStartPoints()
	self._startPoints = {}
	for k in pairs(self._targets) do
		self._startPoints[k] = self._object[k]
	end
end

function Tween:_getLerpAmount(position, mode)
	mode = mode or self._easingMode
	local f = self._easingFunction
	if mode == 'in' then
		if self._easingFunctionArguments then
			return f(position, unpack(self._easingFunctionArguments))
		else
			return f(position)
		end
	elseif mode == 'out' then
		return 1 - self:_getLerpAmount(1 - position, 'in')
	elseif mode == 'inOut' then
		-- this logic comes from rxi's tick
		-- https://github.com/rxi/flux/blob/master/flux.lua#L40
		position = position * 2
		if position < 1 then
			return .5 * self:_getLerpAmount(position, 'in')
		else
			position = 2 - position
			return .5 * (1 - self:_getLerpAmount(position, 'in')) + .5
		end
	elseif mode == 'smooth' then
		return lerp(
			self:_getLerpAmount(position, 'in'),
			self:_getLerpAmount(position, 'out'),
			position
		)
	end
end

function Tween:_update(dt)
	if self:isFinished() then return end
	--[[
		We don't want to set the start points until the first frame
		the tween updates. If the tween is chained to another
		timer, then it won't start running immediately. If we set
		the start points as soon as the tween is created, by the
		time the tween actually runs, the values may have changed.
	]]
	if not self._startPoints then self:_setStartPoints() end
	Timer._update(self, dt)
	local position = (self._duration - self._time) / self._duration
	position = clamp(position, 0, 1)
	for k, target in pairs(self._targets) do
		self._object[k] = lerp(self._startPoints[k], target, self:_getLerpAmount(position))
	end
end

function Tween:ease(f, mode, ...)
	if type(f) == 'string' then f = keeper.ease[f] end
	self._easingFunction = f
	self._easingMode = mode
	self._easingFunctionArguments = {...}
	return self
end

local Manager = {}
Manager.__index = Manager

function Manager:_addTimer(timer)
	timer._status = 'running'
	table.insert(self._timers, timer)
	return timer
end

function Manager:after(...)
	return self:_addTimer(newTimer(...))
end

function Manager:flip(...)
	return self:_addTimer(newFlipTimer(...))
end

function Manager:every(...)
	return self:_addTimer(newRepeatingTimer(...))
end

function Manager:tween(...)
	return self:_addTimer(newTween(...))
end

function Manager:update(dt)
	--[[
		Important note:

		Let's say you set a timer for one instant of time.
		When that timer finishes, it creates another timer
		for one instant of time. You'd expect the second timer
		to finish *after* the first one, i.e. in the next
		instant of time. Therefore, if one timer creates
		another one, the second one should not be updated
		until the next instant of time.

		That's why I'm using a numerical for loop here instead
		of ipairs. A numerical for loop will continue until
		it reaches the original length of the table (when the for
		loop started) and then stop. ipairs will keep iterating
		over all the elements, including ones that were created
		while the loop was running. I want the first behavior.
	]]
	for i = 1, #self._timers do
		local timer = self._timers[i]
		timer:_update(dt)
		if timer:getStatus() == 'completed' then
			for _, chainedTimer in ipairs(timer._after) do
				if not chainedTimer:isFinished() then
					self:_addTimer(chainedTimer)
				end
			end
		end
	end
	-- remove finished timers
	for i = #self._timers, 1, -1 do
		local timer = self._timers[i]
		if timer:isFinished() then
			table.remove(self._timers, i)
		end
	end
end

function keeper.new()
	return setmetatable({
		_timers = {},
	}, Manager)
end

return keeper
