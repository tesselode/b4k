local charm = require 'lib.charm'

local ui = {}

function ui:init()
	self.pool.data.ui = charm.new()
end

function ui:beforeDraw()
	self.pool.data.ui:start()
end

function ui:afterDraw()
	self.pool.data.ui:draw()
end

return ui
