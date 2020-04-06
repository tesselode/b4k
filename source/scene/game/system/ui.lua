local charm = require 'lib.charm'

local ui = {}

function ui:init()
	self.pool.data.ui = charm.new()
end

function ui:update(dt)
	self.pool.data.ui:begin()
end

function ui:draw()
	self.pool.data.ui:draw()
end

return ui
