local charm = require 'lib.charm'

local vectors = {
	['1'] = {{.5,0, .5,1}},
	['2'] = {{0,0, 1,0, 1,.5, 0,.5, 0,1, 1,1}},
	['3'] = {{0,0, 1,0, 1,1, 0,1}, {0,.5, 1,.5}},
	['4'] = {{0,0, 0,.5, 1,.5}, {1,0, 1,1}},
	['5'] = {{1,0, 0,0, 0,.5, 1,.5, 1,1, 0,1}},
	['6'] = {{1,0, 0,0, 0,1, 1,1, 1,.5, 0,.5}},
	['7'] = {{0,0, 1,0, 1,1}},
	['8'] = {{0,0, 1,0, 1,1, 0,1, 0,0}, {0,.5, 1,.5}},
	['9'] = {{0,1, 1,1, 1,0, 0,0, 0,.5, 1,.5}},
	['0'] = {{0,0, 1,0, 1,1, 0,1, 0,0}},
}

local VectorText = charm.extend('VectorText', 'element')

function VectorText:getNaturalWidth()
	return #self.text + (#self.text - 1) * self.spacing
end

function VectorText:new(text)
	self.text = tostring(text)
	self.spacing = .25
	self.lineWidth = .05
	self:width(self:getNaturalWidth())
	self:height(1)
end

function VectorText:color(r, g, b, a)
	self:setColor('_color', r, g, b, a)
	return self
end

function VectorText:spacing(spacing)
	self.spacing = spacing
end

function VectorText:lineWidth(lineWidth)
	self.lineWidth = lineWidth
end

function VectorText:drawCharacter(character)
	if not vectors[character] then return end
	for _, line in ipairs(vectors[character]) do
		love.graphics.line(line)
	end
end

function VectorText:drawBottom()
	love.graphics.push 'all'
		love.graphics.scale(self:get 'width' / self:getNaturalWidth(), self:get 'height')
		love.graphics.setLineWidth(self.lineWidth)
		if self:isColorSet(self._color) then
			love.graphics.setColor(self._color)
		else
			love.graphics.setColor(1, 1, 1)
		end
		for i = 1, #self.text do
			local character = self.text:sub(i, i)
			love.graphics.push()
				love.graphics.translate((i - 1) * (1 + self.spacing), 0)
				self:drawCharacter(character)
			love.graphics.pop()
		end
	love.graphics.pop()
end

return VectorText
