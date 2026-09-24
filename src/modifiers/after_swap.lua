local utils = require("utils.parsing")
local parse_args, ArgType = utils.parse_args, utils.ArgType

---@class AfterSwap : Check
---@field id integer
local AfterSwap = {}
AfterSwap.__index = AfterSwap

---@return AfterSwap?, string? error
function AfterSwap.parse(parser)
  ---@type AfterSwap
  local res = setmetatable({
    enabled = true,
    id = -1
  } --[[@as AfterSwap]], AfterSwap)

  local error = parse_args(parser, {
    { type = ArgType.INTEGER, target = { res, "id" } }
  })

  if error then return nil, error end

  return res, nil
end

function AfterSwap:name()
  return "AfterSwap"
end

function AfterSwap:description()
  return "Only perform the swap this modifier is applied to after another swap."
end

function AfterSwap:enable()
  self.enabled = true
end

function AfterSwap:disable()
  self.enabled = false
end

function AfterSwap:check(state)
  return state.prev_swap and state.prev_swap.id == self.id
end

function AfterSwap:__tostring()
  return string.format("AfterSwap(%d)", self.id)
end

return AfterSwap
