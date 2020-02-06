local charm = require 'lib.charm'

local layout = {}

function layout:init()
	self.pool.data.layout = charm.new()
end

function layout:afterDraw()
	self.pool.data.layout:draw()
end

return layout
