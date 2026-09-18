---@class ChildOf<T>
---@field super fun(): T

---@generic T
---@param parent T The extended parent class
---@return ChildOf<T> child The new child class
local function inherit(parent)
  local child = {}
  child.__index = function(tbl, key)
    local own = rawget(tbl, key) or getmetatable(tbl)[key]
    if own ~= nil then return own end
    return parent[key]
  end

  function child.super()
    return parent
  end

  return child
end

return { inherit = inherit }
