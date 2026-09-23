---@class Final : Special
local Final = {}
Final.__index = Final

---@return Final?, string? error
---@diagnostic disable-next-line:unused-local
function Final.parse(parser)
  return setmetatable({ is_special = true } --[[@as Final]], Final), nil
end

function Final:name()
  return "Final"
end

function Final:description()
  return "Stops the swap chain after the swap this modifier is applied to."
end

function Final:enable()
  self.enabled = true
end

function Final:disable()
  self.enabled = false
end

function Final:__tostring()
  return "Final"
end

return Final
