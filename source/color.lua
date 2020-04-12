local colors = {
	coldBlack = '#262b44',
	darkBlue = '#3a4466',
	darkPurple = '#68386c',
	green = '#63c74d',
	lightBlue = '#32e8f5',
	lightOrange = '#fdae34',
	purple = '#b55088',
	red = '#fb0a44',
	slateGray = '#5a6988',
	white = '#ffffff',
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
