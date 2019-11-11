local colors = {
	peach = '#e4a672',
	lightBrown = '#b86f50',
	brown = '#743f39',
	maroon = '#3f2832',
	darkRed = '#9e2835',
	red = '#e53b44',
	orange = '#fb922b',
	yellow = '#ffe762',
	green = '#63c64d',
	darkGreen = '#327345',
	darkCyan = '#193d3f',
	slate = '#4f6781',
	silver = '#afbfd2',
	white = '#ffffff',
	lightBlue = '#2ce8f4',
	blue = '#0484d1',
}

for colorName, color in pairs(colors) do
	colors[colorName] = {
		tonumber('0x' .. color:sub(2, 3)) / 255,
		tonumber('0x' .. color:sub(4, 5)) / 255,
		tonumber('0x' .. color:sub(6, 7)) / 255,
	}
end

function colors.withAlpha(color, alpha)
	return color[1], color[2], color[3], alpha
end

return colors
