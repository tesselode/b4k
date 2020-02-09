local charm = require 'lib.charm'

local layout = {}

function layout:init()
	self.pool.data.layout = charm.new()
end

function layout:drawTop()
	self.pool.data.layout:draw()
end

return layout
