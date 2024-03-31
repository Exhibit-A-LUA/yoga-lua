local Class = require("lib.Class")

local CC = Class:derive("CircleCollider")

function CC:new(radius, display, adjX, adjY)
    self.r = radius
    self.display = not(display == nil or display == false)
    self.adjX = adjX or 0
    self.adjY = adjY or 0
end

function CC:on_start()
    assert(self.entity.Transform ~=nil, "CircleCollider component requires a Transform component to exist in the attached entity!")
    self.tr = self.entity.Transform
end

-- function CC:update(dt)
-- end

function CC:draw()
    if self.display then
        love.graphics.circle("line", self.tr.x + self.adjX, self.tr.y + self.adjY, self.r)
    end
end

return CC