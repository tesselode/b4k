local colors = {
	coldBlack = '#262B44',
	green = '#63C74D',
	red = '#FB0A44',
	lightBlue = '#32E8F5',
	lightOrange = '#FDAE34',
	slateGray = '#5A6988',
	white = '#FFFFFF',
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
