---@class Final : Modifier
local Final = {}
Final.__index = Final

---@return Final, string? error
---@diagnostic disable-next-line:unused-local
function Final.parse(parser)
  return setmetatable({}, Final), nil
end

function Final.name()
  return "Final"
end

function Final.description()
  return "Stops the swap chain after the swap this modifier is on."
end

function Final:enable()
  self._enabled = true
end

function Final:disable()
  self._enabled = false
end
